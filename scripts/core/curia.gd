extends RefCounted
## The Curia of the Covenant (package 39b) – a service in the Cathedral of Return (Heimkehr). Nobody votes here:
## every 30–60 minutes the Hierarch proclaims an edict, which holds in all of the Covenant's territory until the next
## one (prices, fuel and repairs, Forge of Return ships, bounties, patrols) – every edict with its blessing and its
## burden. The faithful have their ways all the same:
##   tithe       – a gift to the Church: standing; who gives enough may petition for the next edict
##   indulgence  – the Church forgives your crimes against the Covenant (dearer than a fine, but at any level)
##   relics      – old relics of Earth, found in anomalies: standing and a blessing (cheaper prices at its stations)
## Owned by GameState (GameState.curia), saved with the pilot.

const FactionData = preload("res://data/factions.gd")

const EDICT_MIN := 1800.0         # an edict holds 30–60 minutes, until the next one
const EDICT_MAX := 3600.0
const TITHE_STEP := 10000         # one tithe …
const TITHE_REP := 1.5            # … is worth this much standing
const TITHE_REP_MAX := 6.0        # at most this much per edict
const PETITION := 50000           # tithes in one edict period that let you petition for the next edict
const INDULGENCE_MULT := 1.5      # an indulgence costs this times the fine …
const INDULGENCE_MIN := 5000      # … and at least this
const RELIC_REP := 3.0            # standing per relic handed in
const BLESSING_TIME := 1200.0     # each relic: 20 minutes of blessing …
const BLESSING_MAX := 7200.0      # … at most two hours in hand
const BLESSING_BUY := 0.9         # blessed: goods at Covenant stations −10 %, sales +5 %
const BLESSING_SELL := 1.05
const RELIC_FIND := 0.3           # chance that an analysed anomaly holds a relic of Earth

## mods while the edict holds – buy / sell (prices at its stations), service (fuel and repairs), forge (Forge of
## Return ships), bounty (pirate bounties in its systems), patrols (> 1: one more patrol group in each of its systems).
const EDICTS := {
	"pilgrimage": {"name": "Edict of Pilgrimage", "text": "The roads home must stand open to every pilgrim.",
		"pro": "fuel and repairs −25 %", "con": "what you sell earns 4 % less", "mods": {"service": 0.75, "sell": 0.96}},
	"crusade": {"name": "Edict of the Crusade", "text": "The faithful shall cleanse the void of raiders.",
		"pro": "bounties in Covenant space +35 %, an extra patrol in every system", "con": "a war tithe: goods +4 %",
		"mods": {"bounty": 1.35, "patrols": 2.0, "buy": 1.04}},
	"forge": {"name": "Edict of the Forge", "text": "Every hand to the Forge – the fleet that leads us home must grow.",
		"pro": "Forge of Return ships −15 %", "con": "fuel and repairs +12 %", "mods": {"forge": 0.85, "service": 1.12}},
	"austerity": {"name": "Edict of Humility", "text": "Let no one profit from the road home.",
		"pro": "goods −6 %", "con": "what you sell earns 6 % less", "mods": {"buy": 0.94, "sell": 0.94}},
	"plenty": {"name": "Edict of Plenty", "text": "The harvest of the faithful shall be rewarded.",
		"pro": "what you sell earns 8 % more", "con": "Forge of Return ships +10 %", "mods": {"sell": 1.08, "forge": 1.1}},
	"vigil": {"name": "Edict of the Vigil", "text": "Watch the gates; the Settled are everywhere.",
		"pro": "an extra patrol in every system, bounties +15 %", "con": "fuel and repairs +10 %",
		"mods": {"patrols": 2.0, "bounty": 1.15, "service": 1.1}},
}

var edict := {}                   # {id, until, tithed (credits this period), petition ("" or the edict asked for), offer [2 ids]}
var history: Array = []           # newest first: {id, t}
var blessing_until := 0.0


func reset() -> void:
	edict = {}
	history.clear()
	blessing_until = 0.0
	proclaim()


func to_dict() -> Dictionary:
	return {"edict": edict.duplicate(true), "history": history.duplicate(true), "blessing": blessing_until}


func from_dict(d: Dictionary) -> void:
	edict = d.get("edict", {}).duplicate(true)
	history = d.get("history", []).duplicate(true)
	blessing_until = float(d.get("blessing", 0.0))
	if edict.is_empty():
		proclaim()


## Called by GameState every frame.
func update() -> void:
	if edict.is_empty() or GameState.play_time >= float(edict["until"]):
		proclaim()


## The Hierarch proclaims the next edict: the one petitioned for, `id`, or one at random (never the same twice).
func proclaim(id: String = "") -> void:
	var prev := String(edict.get("id", ""))
	if id == "":
		id = String(edict.get("petition", ""))
	if id == "":
		var pool: Array = EDICTS.keys().filter(func(k): return k != prev)
		id = pool[randi() % pool.size()]
	edict = {"id": id, "until": GameState.play_time + randf_range(EDICT_MIN, EDICT_MAX), "tithed": 0, "petition": "", "offer": _offer(id)}
	history.push_front({"id": id, "t": GameState.play_time})
	if history.size() > 10:
		history.pop_back()
	if GameState.news != null:
		var bd: Dictionary = EDICTS[id]
		GameState.news.add("The Hierarch proclaims the %s: %s – %s; %s." % [bd["name"], bd["text"], bd["pro"], bd["con"]], "world", Universe.special_system("heimkehr"))


func _offer(cur: String) -> Array:
	var pool: Array = EDICTS.keys().filter(func(k): return k != cur)
	pool.shuffle()
	return pool.slice(0, 2)


func active_id() -> String:
	return String(edict.get("id", ""))


## Multiplier of the edict in force (and the pilot's blessing on prices) for `key`.
func mod(key: String) -> float:
	var m := 1.0
	if not edict.is_empty():
		m = float(EDICTS[edict["id"]]["mods"].get(key, 1.0))
	if blessed():
		if key == "buy":
			m *= BLESSING_BUY
		elif key == "sell":
			m *= BLESSING_SELL
	return m


func blessed() -> bool:
	return GameState.play_time < blessing_until


## Price multiplier for a hull bought at a station of faction `f`.
func hull_mult(hid: String, f: String) -> float:
	if f != "covenant" or String(GameData.hulls.get(hid, {}).get("maker", "")) != "forge":
		return 1.0
	return float(EDICTS[edict["id"]]["mods"].get("forge", 1.0)) if not edict.is_empty() else 1.0


func minutes_left(t: float) -> int:
	return int(ceil(maxf(0.0, t - GameState.play_time) / 60.0))


# ---------------------------------------------------------------- the faithful's ways ("" = done, otherwise why not)

func tithe() -> String:
	if not GameState.spend(TITHE_STEP):
		return "Not enough credits."
	edict["tithed"] = int(edict.get("tithed", 0)) + TITHE_STEP
	var given := float(int(edict["tithed"]) / TITHE_STEP - 1) * TITHE_REP
	if given < TITHE_REP_MAX:
		GameState.rep.change("covenant", minf(TITHE_REP, TITHE_REP_MAX - given), "tithe")
	GameState.log_msg("Tithe of %s given to the Church of Return." % GameData.fmt_credits(TITHE_STEP), GameState.COL_INFO)
	return ""


func can_petition() -> bool:
	return int(edict.get("tithed", 0)) >= PETITION


func petition(id: String) -> String:
	if not can_petition():
		return "Only who has given %s in tithes may petition the Hierarch." % GameData.fmt_credits(PETITION)
	if not id in edict.get("offer", []):
		return "That edict is not before the Curia."
	edict["petition"] = id
	GameState.log_msg("The Curia has heard your petition: the next edict will be the %s." % EDICTS[id]["name"], GameState.COL_GOOD)
	return ""


func indulgence_cost() -> int:
	var fine: int = GameState.law.fine("covenant")
	return 0 if fine <= 0 else maxi(INDULGENCE_MIN, int(round(fine * INDULGENCE_MULT)))


func indulgence() -> String:
	var cost := indulgence_cost()
	if cost <= 0:
		return "You have nothing to be forgiven – your record with the Covenant is clean."
	if not GameState.spend(cost):
		return "Not enough credits."
	GameState.law.records.erase("covenant")
	GameState.wanted_changed.emit("covenant", 0)
	GameState.log_msg("Indulgence granted for %s – the Church forgives your crimes against the Covenant." % GameData.fmt_credits(cost), GameState.COL_GOOD)
	return ""


## Hands in every relic of Earth aboard the docked ship.
func give_relics(f: ShipFitting) -> String:
	if f == null:
		return "No ship docked."
	var n := int(floor(float(f.cargo.get("earth_relic", 0.0)) + 0.001))
	if n <= 0:
		return "You carry no relics of Earth."
	f.remove_cargo("earth_relic", float(n))
	GameState.rep.change("covenant", RELIC_REP * n, "relics")
	blessing_until = minf(maxf(blessing_until, GameState.play_time) + BLESSING_TIME * n, GameState.play_time + BLESSING_MAX)
	GameState.log_msg("%d relic%s of Earth laid in the Cathedral of Return – you are blessed: goods at Covenant stations −%d %%, sales +%d %% for %d min." % [n, "" if n == 1 else "s", int(round((1.0 - BLESSING_BUY) * 100.0)), int(round((BLESSING_SELL - 1.0) * 100.0)), minutes_left(blessing_until)], GameState.COL_GOOD)
	return ""
