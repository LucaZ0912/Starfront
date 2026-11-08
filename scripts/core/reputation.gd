extends RefCounted
## Reputation per faction (phase 0.5 package 12).
##
## Every faction keeps a standing towards the pilot from -100 to +100 in five tiers.
## Sources: redeeming bounty bonds, contracts, attacks on and kills of faction ships
## (customs violations hook in later via change()). Effects: docking permission, price
## markup / discount, patrol behaviour (ignore, scan, attack), BlackLedger contracts and
## restricted military modules. Pirate standing decides whether that faction's pirates
## leave you alone and whether its Pirate Havens let you dock.
##
## The "pull" effect (helping one faction costs standing with its enemies) only applies to
## contracts that are explicitly aimed at another faction (bounty contracts against pirates).
##
## Owned by GameState (GameState.rep); preloaded, not a class_name (see README).

const FactionData = preload("res://data/factions.gd")

const MIN_REP := -100.0
const MAX_REP := 100.0
## Tiers from the bottom: [id, name, lower bound, colour]
const TIERS := [
	{"id": "nemesis", "name": "Arch-enemy", "min": -100.0, "color": Color(1.0, 0.25, 0.25)},
	{"id": "hostile", "name": "Hostile", "min": -60.0, "color": Color(1.0, 0.55, 0.3)},
	{"id": "neutral", "name": "Neutral", "min": -20.0, "color": Color(0.82, 0.86, 0.92)},
	{"id": "friendly", "name": "Friendly", "min": 20.0, "color": Color(0.45, 0.95, 0.6)},
	{"id": "allied", "name": "Allied", "min": 60.0, "color": Color(0.4, 0.85, 1.0)},
]
const START_POWER := 0.0
const START_PIRATE := -10.0

## How much standing each event is worth (tuned in package 8).
const GAIN := {
	"bond_per_credits": 1500.0,   # +1 per 1,500 cr of a redeemed bond …
	"bond_min": 0.5, "bond_max": 4.0,
	"contract": 2.5,              # contract completed for the issuing station's faction
	"contract_against": -1.5,     # … and against the faction it was aimed at (bounty contracts)
	"attack": -4.0,               # first shot at a ship that was not hostile to you
	"kill_civilian": -10.0,
	"kill_patrol": -12.0,
	"kill_pirate": -1.5,          # per size class (S 1.5, M 3, L 4.5) with the pirate's own faction
}
## Price factors per tier: buy = what you pay, sell = what you are paid.
const PRICES := {
	"nemesis": {"buy": 1.2, "sell": 0.8}, "hostile": {"buy": 1.1, "sell": 0.9},
	"neutral": {"buy": 1.0, "sell": 1.0}, "friendly": {"buy": 0.95, "sell": 1.03},
	"allied": {"buy": 0.9, "sell": 1.06},
}
## Contract rewards and number of offers per tier (BlackLedger asks the station's faction).
const CONTRACT_BONUS := {"friendly": 0.1, "allied": 0.2}
const PROVOKE_TIME := 90.0     # after you open fire on a faction ship its comrades join in

var values := {}               # faction id -> standing
var provoked := {}             # faction id -> play time until which its ships answer fire (not saved)
var _scans := {}               # faction id -> play time of the last reported patrol scan


func _init() -> void:
	reset()


func reset() -> void:
	values.clear()
	provoked.clear()
	_scans.clear()
	for f in FactionData.FACTIONS:
		values[f] = START_PIRATE if FactionData.FACTIONS[f]["kind"] == "pirate" else START_POWER


func to_dict() -> Dictionary:
	return values.duplicate()


func from_dict(d: Dictionary) -> void:
	reset()
	for f in d:
		if values.has(f):
			values[f] = clampf(float(d[f]), MIN_REP, MAX_REP)


# ---------------------------------------------------------------- Queries

func tiers() -> Array:
	return TIERS


func get_rep(f: String) -> float:
	return float(values.get(f, 0.0))


static func tier_of_value(v: float) -> Dictionary:
	var t: Dictionary = TIERS[0]
	for e in TIERS:
		if v >= float(e["min"]):
			t = e
	return t


func tier(f: String) -> Dictionary:
	return tier_of_value(get_rep(f))


func tier_id(f: String) -> String:
	return String(tier(f)["id"]) if values.has(f) else "neutral"


func tier_name(f: String) -> String:
	return String(tier(f)["name"]) if values.has(f) else "Neutral"


func tier_index(f: String) -> int:
	var id := tier_id(f)
	for i in TIERS.size():
		if TIERS[i]["id"] == id:
			return i
	return 2


func at_least(f: String, tier_id_: String) -> bool:
	for i in TIERS.size():
		if TIERS[i]["id"] == tier_id_:
			return tier_index(f) >= i
	return false


func is_provoked(f: String) -> bool:
	return f != "" and float(provoked.get(f, -1.0)) > GameState.play_time


## Pirates of a faction leave you alone from Friendly on (unless you shot at them).
func pirates_hostile(f: String) -> bool:
	if f == "" or not values.has(f):
		return true
	return not at_least(f, "friendly") or is_provoked(f)


## Patrols of a faction: "attack" (Hostile and worse, or provoked), "scan" (Neutral) or "ignore".
func patrol_attitude(f: String) -> String:
	if f == "" or not values.has(f):
		return "ignore"
	if is_provoked(f) or tier_index(f) <= 1 or GameState.law.hunted_by(f):
		return "attack"
	return "scan" if tier_id(f) == "neutral" else "ignore"


## Why docking at a station is refused ("" = allowed).
func dock_error(st: Dictionary) -> String:
	var f := String(st.get("faction", ""))
	if String(st.get("type", "")) == "pirate_haven":
		if f != "" and at_least(f, "friendly"):
			return ""
		return "%s refuses docking – the %s only let in pilots they trust (Friendly standing, yours: %s)." % [st.get("name", "The haven"), FactionData.name_of(f), tier_name(f)]
	if f != "" and tier_id(f) == "nemesis":
		return "%s refuses docking – you are an arch-enemy of the %s." % [st.get("name", "The station"), FactionData.name_of(f)]
	return GameState.law.dock_error(st)


func price_factor(f: String, kind: String) -> float:
	if f == "" or not values.has(f):
		return 1.0
	var k := float(PRICES[tier_id(f)][kind])
	if f == "assembly":
		k *= GameState.senate.mod(kind)              # package 39a: laws of the Assembly
	elif f == "covenant":
		k *= GameState.curia.mod(kind)               # package 39b: edicts of the Hierarch, your blessing
	return k


func buy_price(base: int, f: String) -> int:
	if base < 0:
		return base
	return int(round(float(base) * price_factor(f, "buy")))


func sell_price(base: float, f: String) -> float:
	return base * price_factor(f, "sell")


## Text for station panels: "Standing with the Cluster Assembly: Friendly – prices −5 %, sales +3 %".
func price_note(f: String) -> String:
	if f == "" or not values.has(f):
		return "Free port – prices are the same for everyone."
	var b := price_factor(f, "buy")
	var s := price_factor(f, "sell")
	var txt := "Standing with the %s: %s" % [FactionData.name_of(f), tier_name(f)]
	if is_equal_approx(b, 1.0) and is_equal_approx(s, 1.0):
		return txt + " – standard prices."
	return txt + " – purchases %+d %%, sales %+d %%." % [int(round((b - 1.0) * 100.0)), int(round((s - 1.0) * 100.0))]


## Why BlackLedger posts no contracts for you here ("" = it does).
func contracts_error(f: String) -> String:
	if f != "" and values.has(f) and tier_index(f) <= 1:
		return "BlackLedger posts no contracts for you here – the %s considers you %s." % [FactionData.name_of(f), tier_name(f).to_lower()]
	return GameState.law.contracts_error(f)


func contract_bonus(f: String) -> float:
	return float(CONTRACT_BONUS.get(tier_id(f), 0.0)) if f != "" else 0.0


## Military gear: the biggest modules (weapons 4, optional 6+, core 8+) at Military Outposts are sold
## only to Friendly pilots.
func module_error(st: Dictionary, mid: String) -> String:
	var f := String(st.get("faction", ""))
	if f == "" or String(st.get("type", "")) != "military" or not GameData.is_military_grade(mid):
		return ""
	if at_least(f, "friendly"):
		return ""
	return "Military-grade gear – the %s sells it only to Friendly pilots (yours: %s)." % [FactionData.short_of(f), tier_name(f)]


## Which power puts the bounty on a pirate in system `sid` (package 13): the power holding the
## system, in contested systems the first claiming power, in pirate space the power whose
## territory is nearest.
static func issuer(sid: int) -> String:
	var c := Universe.controller(sid)
	if c in FactionData.POWERS:
		return c
	for cl in Universe.claimants(sid):
		if cl in FactionData.POWERS:
			return cl
	var best := ""
	var best_j := 999
	for s in Universe.systems:
		var o := Universe.controller(int(s["id"]))
		if not o in FactionData.POWERS:
			continue
		var j := 0 if int(s["id"]) == sid else Universe.find_path(sid, int(s["id"]), 3).size()
		if j > 0 and j < best_j:
			best_j = j
			best = o
	return best


# ---------------------------------------------------------------- Changes

## Changes the standing with a faction and reports it. Returns the applied delta.
func change(f: String, delta: float, why: String = "") -> float:
	if f == "" or not values.has(f) or is_zero_approx(delta):
		return 0.0
	var old := get_rep(f)
	var t0 := tier_index(f)
	values[f] = clampf(old + delta, MIN_REP, MAX_REP)
	var applied := get_rep(f) - old
	if is_zero_approx(applied):
		return 0.0
	var t1 := tier_index(f)
	var col := GameState.COL_GOOD if applied > 0.0 else GameState.COL_WARN
	GameState.log_msg("Standing with the %s %+.1f → %.0f (%s)%s" % [FactionData.name_of(f), applied, get_rep(f), tier_name(f), ("  – " + why) if why != "" else ""], col)
	if t1 != t0:
		GameState.log_msg(_tier_message(f, t1 > t0), GameState.COL_GOOD if t1 > t0 else GameState.COL_BAD)
	GameState.reputation_changed.emit(f, get_rep(f), applied)
	return applied


func _tier_message(f: String, up: bool) -> String:
	var n := FactionData.name_of(f)
	var pirate: bool = FactionData.FACTIONS[f]["kind"] == "pirate"
	match tier_id(f):
		"nemesis":
			return "You are now an ARCH-ENEMY of the %s: its stations refuse you and its patrols hunt you." % n
		"hostile":
			return ("The %s now considers you HOSTILE: its pirates and havens will attack you." if pirate else "The %s now considers you HOSTILE: its patrols attack you on sight and prices rise.") % n
		"neutral":
			return ("Your standing with the %s is NEUTRAL – its pirates still attack you." if pirate else "Your standing with the %s is NEUTRAL – its patrols may scan your ship.") % n
		"friendly":
			return ("The %s now counts you as FRIENDLY: its pirates leave you alone and its havens let you dock." if pirate else "The %s now counts you as FRIENDLY: better prices, better contracts, military gear.") % n
		"allied":
			return "You are now ALLIED with the %s – its best prices and contracts are yours." % n
	return "Standing with the %s changed." % n


## Patrol scans are reported at most every two minutes per faction.
func may_scan(f: String) -> bool:
	if float(_scans.get(f, -1e9)) + 120.0 > GameState.play_time:
		return false
	_scans[f] = GameState.play_time
	return true


func provoke(f: String) -> void:
	if f != "":
		provoked[f] = GameState.play_time + PROVOKE_TIME


## The player opened fire on a ship that was not hostile to them.
func on_attack(ship_gov: String, ship_name: String) -> void:
	if ship_gov == "":
		return
	provoke(ship_gov)
	change(ship_gov, GAIN["attack"], "you attacked the %s" % ship_name)


## The player destroyed an NPC ship. role: "pirate" | "patrol" | "civilian".
func on_kill(ship_gov: String, role: String, size: int, ship_name: String) -> void:
	if ship_gov == "":
		return
	match role:
		"pirate":
			change(ship_gov, GAIN["kill_pirate"] * float(maxi(size, 1)), "you destroyed the %s" % ship_name)
		"patrol":
			provoke(ship_gov)
			change(ship_gov, GAIN["kill_patrol"], "you destroyed the %s" % ship_name)
		_:
			provoke(ship_gov)
			change(ship_gov, GAIN["kill_civilian"], "you destroyed the civilian %s" % ship_name)


## A bounty bond was redeemed. `f` = issuing faction.
func on_bond(f: String, amount: int) -> void:
	change(f, clampf(float(amount) / float(GAIN["bond_per_credits"]), float(GAIN["bond_min"]), float(GAIN["bond_max"])), "bounty bond redeemed")


## A contract was completed: standing with its faction, and the pull effect against the
## faction it was aimed at.
func on_contract(m: Dictionary) -> void:
	change(String(m.get("faction", "")), float(m.get("rep", GAIN["contract"])), "contract completed")
	change(String(m.get("against", "")), GAIN["contract_against"], "you worked against them")
