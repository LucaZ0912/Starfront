extends Node
const MakerData = preload("res://data/manufacturers.gd")
## Player state: pilot, credits, ships (hangars), active ship, storage, contracts, hyperspace jumps.
## A pilot always flies exactly ONE ship (active_uid). Other ships are parked docked in
## station hangars and can only be switched there.

signal credits_changed(value: int)
signal message(text: String, color: Color)
signal fleet_changed
signal active_changed                    # a different ship is now active
signal ship_jumped_out(fit: ShipFitting) # hyperspace jump begins
signal ship_arrived_system(fit: ShipFitting)
signal anomaly_revealed(system_id: int, anomaly_id: String)
signal missions_changed
signal survey_done(result: Dictionary)     # long-range survey finished (package 7)
signal reputation_changed(faction: String, value: float, delta: float)   # package 12
signal wanted_changed(faction: String, level: int)                       # package 13
signal news_added(item: Dictionary)                                     # package 16
signal codex_unlocked(id: String)     # package 18
signal warning(text: String)          # important problem shown big in the HUD for a few seconds

const FactionData = preload("res://data/factions.gd")
const COL_INFO := Color(0.8, 0.9, 1.0)
const COL_GOOD := Color(0.5, 1.0, 0.6)
const COL_WARN := Color(1.0, 0.8, 0.4)
const COL_BAD := Color(1.0, 0.45, 0.4)
const JUMP_TIME := 6.0
const START_CREDITS := 30000
const MAX_ACTIVE_MISSIONS := 5

var pilot_name := "Lefty"
## Package 28: the pilot – {"name", "callsign", "look" (PilotArt), "attrs" (data/pilot.gd)}; pilot_name mirrors the name
var pilot := {}
const PilotArt = preload("res://scripts/core/pilot_art.gd")
const PilotData = preload("res://data/pilot.gd")
const SkillData = preload("res://data/skills.gd")
signal skills_changed
var credits := START_CREDITS
var fleet: Array = []            # all owned ships (ShipFitting)
var active_uid := -1             # the ship the pilot is flying
var current_system := 0          # displayed system (= system of the active ship)
var storage := {}                # station_id -> {module_id: count}
var missions: Array = []         # accepted contracts
var bonds: Array = []            # bounty bonds {system, target, amount, time} (phase 0.5 package 9)
var offers := {}                 # station_id -> [mission offers]
var stats := {"kills": 0, "jumps": 0, "mined": 0.0, "analysed": 0, "missions_done": 0, "refined": 0, "built": 0, "earned": 0}
var play_time := 0.0
var _next_uid := 1
var _rng := RandomNumberGenerator.new()


## true while a game session runs (false in the main menu).
var running := false
## Trade convoys of the whole cluster (phase 0.5 package 11), simulated here, shown by Traffic.
var convoys            # ConvoySim (preloaded: works even before the editor has rescanned classes)
const ConvoySimScript = preload("res://scripts/core/convoy_sim.gd")
## Standing with every faction (phase 0.5 package 12) – see scripts/core/reputation.gd.
const ReputationScript = preload("res://scripts/core/reputation.gd")
var rep = ReputationScript.new()
## Id of the convoy the pilot follows (re-attached after jumping with it; -1 = none). Not saved.
var follow_convoy := -1
## Wanted status per faction (phase 0.5 package 13) – see scripts/core/law.gd.
const LawScript = preload("res://scripts/core/law.gd")
var law = LawScript.new()
## Notorious pirates roaming the Cluster (phase 0.5 package 15) – see scripts/core/notorious.gd.
const NotoriousScript = preload("res://scripts/core/notorious.gd")
var notorious = NotoriousScript.new()
## Stations knocked out by raids (relief deliveries) – see scripts/core/station_status.gd.
const StationStatusScript = preload("res://scripts/core/station_status.gd")
var stations = StationStatusScript.new()
## News ticker and archive, bounty campaigns (phase 0.5 package 16) – see scripts/core/news.gd.
const NewsScript = preload("res://scripts/core/news.gd")
var news = NewsScript.new()
## Codex unlocks (phase 0.5 package 18) – see scripts/core/codex.gd and data/codex.gd.
const CodexStateScript = preload("res://scripts/core/codex.gd")
var codex = CodexStateScript.new()


func _ready() -> void:
	convoys = ConvoySimScript.new()
	convoys.name = "Convoys"
	add_child(convoys)
	convoys.convoy_delivered.connect(_on_convoy_done.bind(true))
	convoys.convoy_lost.connect(_on_convoy_done.bind(false))


func new_game(p_pilot: String = "Lefty", p_seed: int = -1, test_system: bool = false, p_data: Dictionary = {}) -> void:
	if convoys != null:
		convoys.reset()
	_rng.randomize()
	if p_seed < 0:
		p_seed = _rng.randi() % 1000000
	if test_system:
		Universe.generate_test()
	else:
		Universe.generate(p_seed)
	set_pilot(make_pilot(p_pilot, p_data))
	surveys.clear()
	stats = {"kills": 0, "jumps": 0, "mined": 0.0, "analysed": 0, "missions_done": 0, "refined": 0, "built": 0, "earned": 0}
	play_time = 0.0
	_next_uid = 1
	credits = START_CREDITS
	exotic_matter = 0
	fleet.clear()
	storage.clear()
	jobs.clear()
	missions.clear()
	offers.clear()
	bonds.clear()
	rep.reset()
	law.reset()
	stations.reset()
	news.reset()
	codex.reset()
	if test_system:
		notorious.reset()
	else:
		notorious.setup()
	current_system = Universe.home_system
	var home_station: Dictionary = Universe.get_layout(current_system)["stations"][0]
	var a := create_from_preset("std_dragonfly", "player")
	a.ship_name = "Dragonfly »Pathfinder«"
	a.system_id = current_system
	a.position = (home_station["pos"] as Vector2) + Vector2(400.0, 150.0)
	a.drones = [{"fuel": 1.0, "hp": 1.0, "out": false}, {"fuel": 1.0, "hp": 1.0, "out": false}]
	add_ship(a)
	active_uid = a.uid
	storage[home_station["id"]] = {}
	for old in {"t_mining_s": 2, "o_cargo_s": 2, "w_autocannon_s": 1, "t_salvage_s": 1, "t_survey_s": 1, "t_prospector_s": 1, "t_interdictor_s": 1}.keys():
		storage[home_station["id"]][GameData.legacy_id(old)] = {"t_mining_s": 2, "o_cargo_s": 2}.get(old, 1)
	if test_system:
		# test pilot: plenty of credits and a Bastion in the hangar
		credits = 10000000
		var bas := create_from_preset("std_bastion", "player")
		bas.ship_name = "Bastion »Testbed«"
		bas.system_id = current_system
		bas.docked_at = home_station["id"]
		bas.position = home_station["pos"]
		add_ship(bas)
	credits_changed.emit(credits)


# ---------------------------------------------------------------- Save / load

## Complete pilot state as plain data (see SaveGame).
## A pilot from the character creator's data (missing parts get sensible defaults; invalid attributes too).
func make_pilot(p_name: String, data: Dictionary = {}) -> Dictionary:
	var attrs: Dictionary = data.get("attrs", {})
	if PilotData.attrs_error(attrs) != "":
		attrs = PilotData.default_attrs()
	var nm := String(data.get("name", p_name)).strip_edges()
	var skills: Dictionary = SkillData.new_skills(attrs)
	var old: Dictionary = data.get("skills", {})
	for id in old:                         # a loaded pilot keeps its skills
		if skills.has(id):
			skills[id] = {"lvl": int(old[id].get("lvl", 0)), "xp": float(old[id].get("xp", 0.0))}
	return {"name": nm if nm != "" else p_name, "callsign": String(data.get("callsign", "")).strip_edges().left(16),
		"look": PilotArt.clean(data.get("look", PilotArt.default_look())), "attrs": attrs.duplicate(), "skills": skills,
		"level": maxi(int(data.get("level", 1)), 1), "xp": float(data.get("xp", 0.0)), "perk_points": int(data.get("perk_points", 0))}


# ---------------------------------------------------------------- Package 29: skills

func skill_level(id: String) -> int:
	return int(pilot.get("skills", {}).get(id, {}).get("lvl", 0))


## The skill's effect as a fraction: +1 % per level.
func skill_bonus(id: String) -> float:
	return float(skill_level(id)) * SkillData.BONUS_PER_LEVEL


## Experience for a skill by doing (scaled by how fast it learns). The skill rises by itself once enough is there
## (0.5.29.2); all experience also feeds the pilot level, and every pilot level brings a perk point (perks: package 30).
func skill_xp(id: String, amount: float) -> void:
	var sk: Dictionary = pilot.get("skills", {}).get(id, {})
	if sk.is_empty() or amount <= 0.0:
		return
	var gain := amount * SkillData.learn_rate(id, pilot.get("attrs", {}))
	_pilot_xp(gain)
	if int(sk["lvl"]) >= SkillData.MAX_LEVEL:
		return
	sk["xp"] = float(sk["xp"]) + gain
	var rose := false
	while int(sk["lvl"]) < SkillData.MAX_LEVEL and float(sk["xp"]) >= SkillData.need(int(sk["lvl"])):
		sk["xp"] = float(sk["xp"]) - SkillData.need(int(sk["lvl"]))
		sk["lvl"] = int(sk["lvl"]) + 1
		rose = true
	if rose:
		for f in fleet:
			f.mark_dirty()                # the bonuses change the ships' values
		log_msg("%s rises to level %d (+%d %%)." % [SkillData.info(id)[1], int(sk["lvl"]), int(sk["lvl"])], COL_GOOD)
		Audio.play("mission_complete", "skill up")
		skills_changed.emit()


func pilot_level() -> int:
	return int(pilot.get("level", 1))


func _pilot_xp(gain: float) -> void:
	if pilot.is_empty():
		return
	pilot["xp"] = float(pilot.get("xp", 0.0)) + gain
	var rose := false
	while int(pilot["level"]) < SkillData.PILOT_MAX and float(pilot["xp"]) >= SkillData.pilot_need(int(pilot["level"])):
		pilot["xp"] = float(pilot["xp"]) - SkillData.pilot_need(int(pilot["level"]))
		pilot["level"] = int(pilot["level"]) + 1
		pilot["perk_points"] = int(pilot.get("perk_points", 0)) + 1
		rose = true
	if rose:
		log_msg("Pilot level %d! A perk point to spend (perks come with package 30)." % int(pilot["level"]), COL_GOOD)
		skills_changed.emit()


func set_pilot(p: Dictionary) -> void:
	pilot = p
	pilot_name = String(p["name"])


func pilot_attr(id: String) -> int:
	return int(pilot.get("attrs", {}).get(id, PilotData.START))


## "CMDR Name 'Callsign'" for the interface.
func pilot_title() -> String:
	var cs := String(pilot.get("callsign", ""))
	return pilot_name + (" »%s«" % cs if cs != "" else "")


func to_dict() -> Dictionary:
	var ships: Array = []
	for f in fleet:
		ships.append(f.to_dict())
	return {
		"pilot_name": pilot_name, "pilot_data": pilot.duplicate(true), "credits": credits, "fleet": ships, "active_uid": active_uid,
		"current_system": current_system, "storage": storage.duplicate(true),
		"missions": missions.duplicate(true), "offers": offers.duplicate(true),
		"stats": stats.duplicate(true), "play_time": play_time, "next_uid": _next_uid, "bonds": bonds.duplicate(true),
		"jobs": jobs.duplicate(true), "exotic_matter": exotic_matter, "mission_counter": Missions._counter, "reputation": rep.to_dict(), "wanted": law.to_dict(), "notorious": notorious.to_dict(), "stations_down": stations.to_dict(), "news": news.to_dict(), "codex": codex.to_dict(),
	}


func from_dict(d: Dictionary) -> void:
	if convoys != null:
		convoys.reset()
	pilot_name = d["pilot_name"]
	var pd: Dictionary = d.get("pilot_data", {})
	set_pilot(make_pilot(pilot_name, pd))     # package 28 (older saves: default looks and attributes)
	surveys.clear()
	credits = int(d["credits"])
	fleet.clear()
	for sd in d["fleet"]:
		fleet.append(ShipFitting.from_dict(sd))
	active_uid = int(d["active_uid"])
	current_system = int(d["current_system"])
	storage = d["storage"].duplicate(true)
	missions = d["missions"].duplicate(true)
	bonds = d.get("bonds", []).duplicate(true)
	offers = d["offers"].duplicate(true)
	stats.merge(d["stats"], true)
	play_time = float(d["play_time"])
	jobs = d.get("jobs", []).duplicate(true)
	exotic_matter = int(d.get("exotic_matter", 0))
	_next_uid = int(d["next_uid"])
	Missions._counter = int(d.get("mission_counter", 1000))
	rep.from_dict(d.get("reputation", {}))   # older saves: start standings
	law.from_dict(d.get("wanted", {}))
	stations.from_dict(d.get("stations_down", {}))
	codex.from_dict(d.get("codex", {}))
	if d.has("news"):
		news.from_dict(d["news"])
	else:
		news.reset()
	if d.has("notorious"):
		notorious.from_dict(d["notorious"])
	else:
		notorious.setup()
	credits_changed.emit(credits)
	fleet_changed.emit()
	missions_changed.emit()


## Save from an older star cluster: every ship is docked at the home Trade Hub, all station
## storage is merged there, open contracts are cancelled. Credits, ships, modules, cargo and
## career stats are kept.
var load_note := ""
## Long-range survey results ("<system>:<place id>" -> result); kept for the session, not saved.
var surveys := {}


func migrate_to_current_cluster(old_version: int = 1) -> void:
	var home := Universe.home_system
	var hs: Dictionary = Universe.get_layout(home)["stations"][0]
	for f in fleet:
		f.system_id = home
		f.docked_at = hs["id"]
		f.position = hs["pos"]
		f.route.clear()
		f.transit_kind = ""
		f.transit_to = null
		f.transit_from = null
		f.transit = 0.0
	var merged := {}
	for sid in storage:
		for item in storage[sid]:
			merged[item] = int(merged.get(item, 0)) + int(storage[sid][item])
	storage = {hs["id"]: merged} if not merged.is_empty() else {}
	var lost := missions.size()
	missions.clear()
	offers.clear()
	current_system = home
	var why := "The star cluster has grown to %d systems." % Universe.systems.size()
	if old_version >= 2:
		why = "The Cluster is now divided among its factions – territories and security levels have changed."
	load_note = "%s Your ships and station storage were moved to %s%s." % [why, hs["name"], (" – %d open contract(s) were cancelled" % lost) if lost > 0 else ""]
	fleet_changed.emit()
	missions_changed.emit()


# ---------------------------------------------------------------- Bounty bonds (phase 0.5 packages 9 + 13)
# Bounties are put out by a power (Reputation.issuer) and paid as bonds by the Sable Writ Exchange:
# redeemable at the Bond Office of ANY station of the issuing faction. `redeem` holds the nearest
# such system for display. Bonds from before package 13 (no faction) are paid in the system where
# they were issued (station-less systems: the nearest system with a station). Bonds belong to the
# pilot – they survive the loss of a ship and never expire.

var _bond_counter := 0


## System where a bond issued in `sid` is paid out.
static func bond_redeem_system(sid: int) -> int:
	if Universe.has_stations(sid):
		return sid
	var best := sid
	var best_j := 999
	for s in Universe.systems:
		if not Universe.has_stations(int(s["id"])):
			continue
		var j := Universe.find_path(sid, int(s["id"]), 3).size()
		if j > 0 and j < best_j:
			best_j = j
			best = int(s["id"])
	return best


func add_bond(sid: int, target: String, amount: int, issuer: String = "-") -> Dictionary:
	_bond_counter += 1
	var f := rep.issuer(sid) if issuer == "-" else issuer
	var b := {"id": "b%d_%d" % [int(play_time), _bond_counter], "system": sid,
		"redeem": faction_office_system(f, sid) if f != "" else bond_redeem_system(sid),
		"target": target, "amount": amount, "time": play_time, "faction": f}
	bonds.append(b)
	return b


## Nearest system (from `from`) with a station of faction `f` – where its bonds are paid.
static func faction_office_system(f: String, from: int) -> int:
	var best := -1
	var best_j := 999
	for s in Universe.systems:
		var id := int(s["id"])
		var has := false
		for st in Universe.get_layout(id)["stations"]:
			has = has or String(st.get("faction", "")) == f
		if not has:
			continue
		var j := 0 if id == from else Universe.find_path(from, id, 3).size()
		if id != from and j == 0:
			continue
		if j < best_j:
			best_j = j
			best = id
	return best if best >= 0 else bond_redeem_system(from)


## Can bond `b` be redeemed at station `st`?
static func bond_redeemable_at(b: Dictionary, st: Dictionary, sid: int) -> bool:
	if st.is_empty() or String(st.get("type", "")) == "pirate_haven":
		return false
	var f := String(b.get("faction", ""))
	if f != "":
		return String(st.get("faction", "")) == f
	return int(b.get("redeem", b.get("system", -1))) == sid


func bonds_redeemable_at(st: Dictionary, sid: int) -> Array:
	var out: Array = []
	for b in bonds:
		if bond_redeemable_at(b, st, sid):
			out.append(b)
	return out


## Bonds that some station in system `sid` pays out.
func bonds_redeemable_in(sid: int) -> Array:
	var out: Array = []
	var L := Universe.get_layout(sid)
	for b in bonds:
		for st in L["stations"]:
			if bond_redeemable_at(b, st, sid):
				out.append(b)
				break
	return out


## Where a bond is paid, as text ("any Assembly station – nearest: Nordlicht").
func bond_where(b: Dictionary, from: int) -> String:
	var f := String(b.get("faction", ""))
	if f == "":
		return Universe.systems[int(b.get("redeem", b.get("system", 0)))]["name"]
	return "any %s station – nearest: %s" % [FactionData.short_of(f), Universe.systems[faction_office_system(f, from)]["name"]]


func bonds_total() -> int:
	var t := 0
	for b in bonds:
		t += int(b["amount"])
	return t


## Pays one bond (or all redeemable ones when id == "") at station `st` in system `sid`. Returns the payout.
func redeem_bonds(st: Dictionary, sid: int, id: String = "") -> int:
	var paid := 0
	var by_faction := {}
	for b in bonds_redeemable_at(st, sid):
		if id == "" or b["id"] == id:
			paid += int(b["amount"])
			bonds.erase(b)
			# standing with the issuing faction (bonds without one: the faction of this station)
			var f := String(b.get("faction", ""))
			if f == "":
				f = String(st.get("faction", ""))
			by_faction[f] = int(by_faction.get(f, 0)) + int(b["amount"])
	if paid > 0:
		add_credits(paid)
	for f in by_faction:
		rep.on_bond(f, int(by_faction[f]))
	return paid


# ---------------------------------------------------------------- Ships

func create_fit(hull_id: String, mods: Dictionary, faction: String) -> ShipFitting:
	var f := ShipFitting.new(hull_id, faction)
	for k in mods:
		f.modules[k] = mods[k]
	f.mark_dirty()
	f.refill()
	f.ship_name = GameData.hulls[hull_id]["name"]
	return f


func create_from_preset(preset_id: String, faction: String) -> ShipFitting:
	var p: Dictionary = GameData.presets[preset_id]
	return create_fit(p["hull"], p["modules"], faction)


func add_ship(f: ShipFitting) -> void:
	if f.uid == 0:
		f.uid = _next_uid
		_next_uid += 1
	fleet.append(f)
	f.mark_dirty()                      # package 29: the pilot's skills now count for this ship
	fleet_changed.emit()


func get_fit(uid: int) -> ShipFitting:
	for f in fleet:
		if f.uid == uid:
			return f
	return null


func active() -> ShipFitting:
	return get_fit(active_uid)


## Compatibility: the "selection" is always the active ship.
func selected_fits() -> Array:
	var a := active()
	return [a] if a != null else []


## Board a ship in the same hangar.
func set_active(uid: int) -> bool:
	var cur := active()
	var f := get_fit(uid)
	if f == null or f.docked_at == "":
		return false
	if cur != null and (cur.docked_at != f.docked_at):
		log_msg("Ships can only be swapped within the same hangar.", COL_WARN)
		return false
	active_uid = uid
	log_msg("You board the %s." % f.ship_name, COL_GOOD)
	active_changed.emit()
	return true


## Ships parked in a given hangar.
func hangar(station_id: String) -> Array:
	var out: Array = []
	for f in fleet:
		if f.docked_at == station_id:
			out.append(f)
	return out


## Value of a ship: hull + fitted modules (+ cargo at base price).
func ship_value(f: ShipFitting) -> int:
	var v := int(f.hull()["price"])
	for k in f.modules:
		if GameData.modules.has(f.modules[k]):
			v += int(GameData.modules[f.modules[k]]["price"])
	v += f.drones.size() * Commands.DRONE_PRICE        # review K5
	return v


func cargo_value(f: ShipFitting) -> int:
	var v := 0.0
	for item in f.cargo:
		v += GameData.item_value(item) * float(f.cargo[item])
	return int(v)


func storage_value() -> int:
	var v := 0
	for st in storage:
		for mid in storage[st]:
			v += int(GameData.modules[mid]["price"]) * int(storage[st][mid])
	return v


func net_worth() -> int:
	var v := credits + storage_value()
	for f in fleet:
		v += ship_value(f) + cargo_value(f)
	return v


func on_player_ship_lost(f: ShipFitting) -> void:
	fleet.erase(f)
	jobs = jobs.filter(func(j): return String(j.get("kind", "")) != "ship" or int(j.get("uid", 0)) != f.uid)   # review K4
	log_msg("%s was destroyed!" % f.ship_name, COL_BAD)
	for m in missions.duplicate():           # package 25c: passengers aboard die with the ship
		if String(m["type"]) == "passenger" and int(m.get("ship_uid", -1)) == f.uid:
			fail_mission(m, "your ship was destroyed with the passengers aboard", Missions.PASSENGER_REP)
	if f.uid == active_uid:
		# Escape pod: to the nearest owned ship, otherwise insurance
		var next: ShipFitting = null
		for o in fleet:
			if o.system_id == f.system_id:
				next = o
				break
		if next == null and not fleet.is_empty():
			next = fleet[0]
		if next == null:
			next = _insurance_ship()
		active_uid = next.uid
		log_msg("Your escape pod reaches %s. You take command of the %s." % [next.location_text(), next.ship_name], COL_WARN)
		active_changed.emit()
	fleet_changed.emit()


func _insurance_ship() -> ShipFitting:
	var home := Universe.home_system
	var st: Dictionary = Universe.get_layout(home)["stations"][0]
	var f := create_from_preset("std_dragonfly", "player")
	f.ship_name = "Dragonfly »Second Chance«"
	f.system_id = home
	f.docked_at = st["id"]
	f.position = st["pos"]
	add_ship(f)
	log_msg("Aegis Mutual provides you with a new Dragonfly in %s." % Universe.systems[home]["name"], COL_WARN)
	return f


# ---------------------------------------------------------------- Credits & storage

func add_credits(v: int) -> void:
	credits += v
	if v > 0:
		stats["earned"] = int(stats["earned"]) + v
	credits_changed.emit(credits)


func spend(v: int) -> bool:
	if credits < v:
		log_msg("Not enough credits (need %s)." % GameData.fmt_credits(v), COL_BAD)
		return false
	credits -= v
	credits_changed.emit(credits)
	return true


## What is stored at a station (read only – an empty dictionary if nothing; review K8).
func storage_of(station_id: String) -> Dictionary:
	return storage.get(station_id, {})


func _storage_w(station_id: String) -> Dictionary:
	if not storage.has(station_id):
		storage[station_id] = {}
	return storage[station_id]


func storage_add(station_id: String, module_id: String, n: int = 1) -> void:
	var s := _storage_w(station_id)
	s[module_id] = int(s.get(module_id, 0)) + n


func storage_remove(station_id: String, module_id: String, n: int = 1) -> bool:
	var s := storage_of(station_id)
	if int(s.get(module_id, 0)) < n:
		return false
	s[module_id] = int(s[module_id]) - n
	if s[module_id] <= 0:
		s.erase(module_id)
	if s.is_empty():
		storage.erase(station_id)
	return true


# ---------------------------------------------------------------- Contracts (BlackLedger)

## Faction ships (package 25e): "" = may buy, otherwise why not (standing with the maker's faction).
func hull_standing_error(hid: String) -> String:
	var h: Dictionary = GameData.hulls.get(hid, {})
	var tier := String(h.get("min_tier", ""))
	if tier == "":
		return ""
	var mk: Dictionary = MakerData.MAKERS.get(String(h.get("maker", "")), {})
	var f := String(mk.get("faction", ""))
	if f == "" or rep.at_least(f, tier):
		return ""
	return "%s sells the %s only to %s pilots (yours: %s)." % [mk.get("name", "?"), h["name"], tier.capitalize(), rep.tier_name(f)]


## Passenger contracts of a station (package 25c) – own tab on the board.
func passenger_offers_for(system_id: int, station: Dictionary) -> Array:
	var key: String = String(station["id"]) + "#p"
	if not offers.has(key):
		offers[key] = []
	var list: Array = offers[key]
	var tries := 0
	while list.size() < Missions.PASSENGER_OFFERS and tries < 10:
		tries += 1
		var m := Missions.generate_passenger(system_id, station, _rng)
		if not m.is_empty():
			list.append(m)
	return list


## Contracts that count against MAX_ACTIVE_MISSIONS (passengers have their own limit).
func contract_count() -> int:
	var n := 0
	for m in missions:
		if String(m["type"]) != "passenger":
			n += 1
	return n


func passenger_count() -> int:
	return missions.size() - contract_count()


func offers_for(system_id: int, station: Dictionary) -> Array:
	var sid: String = station["id"]
	if not offers.has(sid):
		offers[sid] = []
	var list: Array = offers[sid]
	while list.size() < Missions.OFFERS_PER_STATION:
		list.append(Missions.generate(system_id, station, _rng))
	return list


## Faction contracts of a station (package 17) – issued by its government, tied to your standing.
func faction_offers_for(system_id: int, station: Dictionary) -> Array:
	var f := String(station.get("faction", ""))
	if not f in FactionData.POWERS:
		return []
	var key: String = String(station["id"]) + "#f"
	if not offers.has(key):
		offers[key] = []
	var list: Array = offers[key]
	while list.size() < Missions.FACTION_OFFERS:
		list.append(Missions.generate_faction(system_id, station, _rng))
	return list


## Why a faction contract cannot be taken ("" = it can).
func faction_job_error(m: Dictionary) -> String:
	if not m.get("faction_job", false):
		return ""
	var f := String(m["faction"])
	var tier := String(m.get("min_tier", "neutral"))
	if not rep.at_least(f, tier):
		return "The %s offers this only to %s pilots (yours: %s)." % [FactionData.name_of(f), Missions.TIER_NAMES.get(tier, tier), rep.tier_name(f)]
	if m["type"] == "hunt":
		var c: Dictionary = notorious.get_captain(String(m["captain"]))
		if c.is_empty() or not c["alive"]:
			return "That captain is already dead."
	return ""


func accept_mission(m: Dictionary) -> String:
	if String(m["type"]) == "passenger":
		return _accept_passengers(m)
	if contract_count() >= MAX_ACTIVE_MISSIONS:
		return "You can hold at most %d contracts." % MAX_ACTIVE_MISSIONS
	var why := faction_job_error(m)
	if why != "":
		return why
	var f := active()
	match String(m["type"]):
		"escort":
			var cv: Dictionary = convoys.make_escort(int(m["giver_system"]), String(m["giver"]), int(m["target_system"]), String(m["target_station"]), String(m.get("convoy_gov", m["faction"])), String(m["id"]), int(m.get("freighters", 2)))
			if cv.is_empty():
				return "No route for the convoy."
			m["convoy"] = int(cv["id"])
			log_msg("The convoy gathers outside %s (marked green). Select its lead ship and press Follow (or fly within 1,000 km) – it sets off once you are with it." % Universe.find_station(int(m["giver_system"]), String(m["giver"])).get("name", "the station"), COL_INFO)
		"smuggler":
			m["expires"] = play_time + Missions.SMUGGLER_TIME
		"patrol":
			log_msg("The %s patrol waits for you at %s (marked green). Select its lead ship and press Follow (or fly within 1,000 km) – it sets off once you are with it." % [FactionData.short_of(String(m["faction"])), m.get("meet", {}).get("name", "the station")], COL_INFO)
	var fkey: String = String(m["giver"]) + "#f"
	if offers.has(fkey):
		offers[fkey].erase(m)
	if m["type"] == "courier":
		if f == null or f.cargo_free() < float(m["amount"]) * GameData.item_volume("sealed_cargo"):
			return "Not enough cargo space for the sealed cargo."
		f.add_cargo("sealed_cargo", float(m["amount"]))
	if offers.has(m["giver"]):
		offers[m["giver"]].erase(m)
	# better standing, better pay (package 12) – fixed when the contract is accepted
	var bonus := rep.contract_bonus(String(m.get("faction", "")))
	if bonus > 0.0:
		m["reward"] = int(round(float(m["reward"]) * (1.0 + bonus)))
		m["bonus"] = bonus
	missions.append(m)
	log_msg("Contract accepted: %s" % m["title"], COL_GOOD)
	missions_changed.emit()
	return ""


## Passenger contract (package 25c): the passengers board the active ship – bulk seats, or a free
## cabin of their class for the whole group; the deadline starts now.
func _accept_passengers(m: Dictionary) -> String:
	if passenger_count() >= Missions.MAX_PASSENGER_JOBS:
		return "You can carry at most %d passenger groups at once." % Missions.MAX_PASSENGER_JOBS
	var f := active()
	var why := Missions.cabin_error(f, m)
	if why != "":
		return why
	if String(m["cabin"]) != "bulk":
		m["cabin_slot"] = Missions.pick_cabin(f, String(m["cabin"]), int(m["amount"]))
	m["ship_uid"] = f.uid
	m["expires"] = play_time + float(m["time_limit"])
	var mult := Missions.pay_mult(f, m)
	var bonus := rep.contract_bonus(String(m.get("faction", "")))
	m["reward"] = int(round(float(m["reward"]) * mult * (1.0 + bonus)))
	if bonus > 0.0:
		m["bonus"] = bonus
	var key: String = String(m["giver"]) + "#p"
	if offers.has(key):
		offers[key].erase(m)
	missions.append(m)
	var note := ""
	if mult != 1.0:
		note = "  (%s: luxury pay %+d %%)" % [f.hull()["name"], int(round((mult - 1.0) * 100.0))]
	log_msg("%d passengers boarded the %s: %s%s" % [int(m["amount"]), f.ship_name, m["title"], note], COL_GOOD)
	missions_changed.emit()
	return ""


func abandon_mission(m: Dictionary) -> void:
	missions.erase(m)
	var f := active()
	if m["type"] == "courier" and f != null:
		f.remove_cargo("sealed_cargo", float(m["amount"]))
	log_msg("Contract abandoned: %s" % m["title"], COL_WARN)
	missions_changed.emit()


func turn_in_mission(m: Dictionary, station_id: String) -> String:
	var f := active()
	if f == null or not Missions.can_turn_in(m, f, station_id):
		return "Contract conditions not met yet."
	match String(m["type"]):
		"courier":
			f.remove_cargo("sealed_cargo", float(m["amount"]))
		"mining":
			f.remove_cargo(m["item"], float(m["amount"]))
	missions.erase(m)
	var pay := int(round(Missions.payout(m) * (1.0 + skill_bonus("negotiation"))))      # package 29
	add_credits(pay)
	stats["missions_done"] = int(stats["missions_done"]) + 1
	skill_xp("negotiation", 12.0)
	log_msg("Contract complete: %s  (+%s)" % [m["title"], GameData.fmt_credits(pay)], COL_GOOD)
	Audio.play("mission_complete", "contract complete")   # package 28a
	rep.on_contract(m)
	missions_changed.emit()
	return ""


## The pilot destroyed a hunted captain or an intercepted smuggler (package 17).
func notify_target(captain_id: String, smuggler_mission: String) -> void:
	for m in missions:
		if int(m["progress"]) >= 1:
			continue
		if (m["type"] == "hunt" and captain_id != "" and String(m["captain"]) == captain_id) or (m["type"] == "smuggler" and smuggler_mission != "" and String(m["id"]) == smuggler_mission):
			m["progress"] = 1
			log_msg("Contract objective complete: %s – report back to %s." % [m["title"], Universe.find_station(int(m["giver_system"]), String(m["giver"])).get("name", "the issuing station")], COL_GOOD)
			missions_changed.emit()


## A faction contract failed (convoy lost, smuggler escaped, target died elsewhere …).
func fail_mission(m: Dictionary, why: String, rep_loss: float = 2.0) -> void:
	if not m in missions:
		return
	missions.erase(m)
	log_msg("Contract failed: %s – %s" % [m["title"], why], COL_BAD)
	rep.change(String(m.get("faction", "")), -rep_loss, "contract failed")
	missions_changed.emit()


func _on_convoy_done(c: Dictionary, delivered: bool) -> void:
	for m in missions.duplicate():
		if m["type"] != "escort" or int(m.get("convoy", -1)) != int(c["id"]):
			continue
		if not delivered:
			fail_mission(m, "the convoy was lost")
		elif float(m["with_t"]) >= float(m["total_t"]) * Missions.ESCORT_SHARE:
			m["progress"] = 1
			m["arrived"] = clampi(int(c.get("freighters", 0)), 0, int(m.get("freighters", 2)))
			log_msg("Escort complete: %d of %d freighters reached %s (pay %d %%). Report at the destination station." % [int(m["arrived"]), int(m.get("freighters", 2)), Universe.systems[int(m["target_system"])]["name"], int(round(100.0 * float(Missions.payout(m)) / maxf(float(m["reward"]), 1.0)))], COL_GOOD)
			missions_changed.emit()
		else:
			fail_mission(m, "the convoy arrived without you (you were with it only %d %% of the way)" % int(100.0 * float(m["with_t"]) / maxf(float(m["total_t"]), 1.0)))


## Faction contracts that run over time (package 17): escort presence, smuggler deadline, hunt target.
func _update_faction_jobs(delta: float) -> void:
	for m in missions.duplicate():
		match String(m["type"]):
			"escort":
				if int(m["progress"]) >= 1:
					continue
				var c: Dictionary = convoys.find(int(m["convoy"]))
				if c.is_empty() or c.get("gathering", false):
					continue             # waiting outside the station for the pilot does not count
				m["total_t"] = float(m["total_t"]) + delta
				var f := active()
				if f != null and not f.in_transit() and f.system_id == int(c["cur"]) and f.docked_at == "":
					m["with_t"] = float(m["with_t"]) + delta
			"smuggler":
				if int(m["progress"]) < 1 and float(m["expires"]) > 0.0 and play_time >= float(m["expires"]):
					fail_mission(m, "the smuggler got through")
			"hunt":
				if int(m["progress"]) < 1:
					var cap: Dictionary = notorious.get_captain(String(m["captain"]))
					if cap.is_empty() or not cap["alive"]:
						fail_mission(m, "someone else got the target")


## Game events that advance contracts.
func notify(event: String, system_id: int) -> void:
	match event:
		"kill":
			stats["kills"] = int(stats["kills"]) + 1
		"analyse":
			stats["analysed"] = int(stats["analysed"]) + 1
			skill_xp("science", 20.0)
	var changed := false
	for m in missions:
		if (event == "kill" and m["type"] == "bounty") or (event == "analyse" and m["type"] == "survey"):
			if int(m["target_system"]) == system_id and int(m["progress"]) < int(m["amount"]):
				m["progress"] = int(m["progress"]) + 1
				changed = true
				if int(m["progress"]) >= int(m["amount"]):
					log_msg("Contract objective complete: %s – return to the issuing station." % m["title"], COL_GOOD)
	if changed:
		missions_changed.emit()


# ---------------------------------------------------------------- Hyperspace

func jump_fuel(f: ShipFitting, cls: int) -> float:
	return float(f.stats()["jump_fuel"]) * (1.0 + 0.35 * (cls - 1))


## Empty string = jump possible, otherwise the reason.
## Axiom Threshold (package 25g): exotic matter – a pilot resource without cargo space.
var exotic_matter := 0


## Why the Threshold cannot open a wormhole to `to_id` ("" = it can). Distance = normal jumps.
func wormhole_error(f: ShipFitting, to_id: int) -> String:
	if f == null:
		return "No ship."
	var wh: Dictionary = f.hull().get("wormhole", {})
	if wh.is_empty():
		return "Only Axiom's Threshold can open a wormhole."
	if to_id == f.system_id:
		return "You are already there."
	if f.docked_at != "" or f.in_transit():
		return "Undock first."
	if bool(Universe.systems[to_id].get("veil", false)):
		return "The Veil cannot be reached by wormhole – that is left to Project Bridge."
	var dist := Universe.find_path(f.system_id, to_id, 3).size()
	if dist <= 0:
		return "No way there."
	if dist > int(wh.get("max", 8)):
		return "Too far: %d jumps (at most %d)." % [dist, int(wh.get("max", 8))]
	if exotic_matter < dist:
		return "Not enough exotic matter: %d needed, %d in stock." % [dist, exotic_matter]
	if play_time < f.wormhole_ready:
		return "The core is still recovering – %d s." % int(ceil(f.wormhole_ready - play_time))
	return ""


func wormhole_distance(f: ShipFitting, to_id: int) -> int:
	return Universe.find_path(f.system_id, to_id, 3).size()


## Opens the wormhole: costs exotic matter, the ship is gone for a few seconds, then arrives – near a
## station, or (if the jump goes wrong) somewhere at random in the target system.
func begin_wormhole(f: ShipFitting, to_id: int) -> String:
	var err := wormhole_error(f, to_id)
	if err != "":
		return err
	var dist := wormhole_distance(f, to_id)
	exotic_matter -= dist
	f.transit_kind = "wormhole"
	f.transit_from = f.system_id
	f.transit_to = to_id
	f.transit_total = WORMHOLE_TIME
	f.transit = WORMHOLE_TIME
	f.route.clear()
	f.wormhole_ready = play_time + WORMHOLE_TIME + float(f.hull()["wormhole"].get("cooldown", 120.0))
	stats["jumps"] = int(stats["jumps"]) + 1
	skill_xp("navigation", 15.0)
	log_msg("%s opens a wormhole → %s (%d jump%s, %d exotic matter)." % [f.ship_name, Universe.systems[to_id]["name"], dist, "" if dist == 1 else "s", dist])
	ship_jumped_out.emit(f)
	return ""


const WORMHOLE_TIME := 3.0


func can_jump(f: ShipFitting, to_id: int) -> String:
	var sys: Dictionary = Universe.systems[f.system_id]
	if not sys["links"].has(to_id):
		return "No hyperspace route to %s" % Universe.systems[to_id]["name"]
	var cls := int(sys["links"][to_id])
	var s := f.stats()
	if int(s["drive_class"]) <= 0:
		return "No hyperdrive fitted"
	if int(s["drive_class"]) < cls:
		return "Class %d route – class %d hyperdrive is not enough" % [cls, int(s["drive_class"])]
	var need := jump_fuel(f, cls)
	if f.fuel < need:
		return "Not enough fuel (%.0f / %.0f)" % [f.fuel, need]
	return ""


func begin_jump(f: ShipFitting, to_id: int) -> bool:
	var err := can_jump(f, to_id)
	if err != "":
		log_msg("%s: %s" % [f.ship_name, err], COL_WARN)
		return false
	f.fuel -= jump_fuel(f, Universe.route_class(f.system_id, to_id))
	f.transit_kind = "jump"
	f.transit_from = f.system_id
	f.transit_to = to_id
	f.transit_total = JUMP_TIME
	f.transit = JUMP_TIME
	f.docked_at = ""
	stats["jumps"] = int(stats["jumps"]) + 1
	skill_xp("navigation", 8.0)
	codex.event("jump")
	log_msg("%s enters hyperspace → %s." % [f.ship_name, Universe.systems[to_id]["name"]])
	ship_jumped_out.emit(f)
	return true


func _arrive(f: ShipFitting) -> void:
	var from_id := int(f.transit_from)
	f.system_id = int(f.transit_to)
	if f.transit_kind == "wormhole":
		_arrive_wormhole(f)
	else:
		var gate := Universe.get_gate_pos(f.system_id, from_id)
		f.position = gate + (-gate).normalized() * 2500.0 + Vector2(randf_range(-600, 600), randf_range(-600, 600))
		f.rotation = (-gate).angle()
	if not f.route.is_empty() and int(f.route[0]) == f.system_id:
		f.route.pop_front()
	f.transit_kind = ""
	f.transit_to = null
	f.transit = 0.0
	current_system = f.system_id
	if f.route.is_empty():
		log_msg("%s arrived in %s." % [f.ship_name, Universe.systems[f.system_id]["name"]], COL_GOOD)
	ship_arrived_system.emit(f)


## The end of a wormhole: next to a station – or, if it goes wrong, somewhere at random (maybe right in
## an asteroid field).
func _arrive_wormhole(f: ShipFitting, force_fail: int = -1) -> void:
	var L := Universe.get_layout(f.system_id)
	var fail := randf() < float(f.hull().get("wormhole", {}).get("fail", 0.1)) if force_fail < 0 else force_fail == 1
	if fail:
		var spots: Array = []
		for fl in L["fields"]:
			spots.append(fl["pos"])
		spots.append(Vector2.from_angle(randf() * TAU) * randf_range(400000.0, 1600000.0))
		f.position = spots[randi() % spots.size()] + Vector2.from_angle(randf() * TAU) * randf_range(0.0, 3000.0)
		log_msg("The wormhole collapsed early – %s is thrown out somewhere in %s!" % [f.ship_name, Universe.systems[f.system_id]["name"]], COL_WARN)
	elif not L["stations"].is_empty():
		var st: Dictionary = L["stations"][randi() % L["stations"].size()]
		f.position = (st["pos"] as Vector2) + Vector2.from_angle(randf() * TAU) * 6000.0
	else:
		f.position = Vector2.from_angle(randf() * TAU) * 500000.0
	f.rotation = randf() * TAU


## Manufacturing jobs (package 25b): {kind "station"|"ship", station | uid, item, total, left}.
## Station jobs run all the time; ship jobs only while the ship's factory runs (Ship._run_active).
var jobs: Array = []


func _advance_station_jobs(delta: float) -> void:
	for j in jobs.duplicate():
		if j["kind"] != "station":
			continue
		j["left"] = float(j["left"]) - delta
		if float(j["left"]) <= 0.0:
			jobs.erase(j)
			storage_add(String(j["station"]), String(j["item"]))
			stats["built"] = int(stats.get("built", 0)) + 1
			skill_xp("engineering", 10.0)
			log_msg("Manufacturing finished: %s – in storage at %s." % [GameData.module_name(String(j["item"])), String(j.get("station_name", "the station"))], COL_GOOD)


## Station jobs at `station_id` (for the manufacturing panel).
func jobs_at(station_id: String) -> Array:
	return jobs.filter(func(j): return j["kind"] == "station" and String(j["station"]) == station_id)


## Factory jobs of ship `uid`, in order.
func ship_jobs(uid: int) -> Array:
	return jobs.filter(func(j): return j["kind"] == "ship" and int(j["uid"]) == uid)


func _process(delta: float) -> void:
	if not running:
		return
	play_time += delta
	_advance_station_jobs(delta)
	notorious.update(current_system)
	news.update()
	_update_faction_jobs(delta)
	_update_passengers()
	var f := active()
	if f == null:
		return
	if f.in_transit():
		f.transit -= delta
		if f.transit <= 0.0:
			_arrive(f)
		return
	_scan_system(f, delta)


## Scanners sweep the whole system: hidden anomalies are revealed over time.
## Passenger deadlines (package 25c).
func _update_passengers() -> void:
	for m in missions.duplicate():
		if String(m["type"]) == "passenger" and float(m.get("expires", -1.0)) > 0.0 and play_time > float(m["expires"]):
			fail_mission(m, "the passengers did not arrive in time", Missions.PASSENGER_REP)


func _scan_system(f: ShipFitting, delta: float) -> void:
	var tool := f.get_tool("scanner")
	if tool.is_empty():
		return
	for an in Universe.get_layout(f.system_id)["anomalies"]:
		if an["revealed"]:
			continue
		an["scan"] = float(an["scan"]) + float(tool["strength"]) * float(f.stats()["scan_strength"]) * delta * 0.5
		if float(an["scan"]) >= float(an["difficulty"]):
			an["revealed"] = true
			log_msg("Scanner: anomaly detected – %s" % an["name"], COL_GOOD)
			anomaly_revealed.emit(f.system_id, an["id"])


func scan_progress(system_id: int) -> float:
	var total := 0.0
	var done := 0.0
	for an in Universe.get_layout(system_id)["anomalies"]:
		total += 1.0
		done += clampf(float(an["scan"]) / float(an["difficulty"]), 0.0, 1.0)
	return done / maxf(total, 1.0)


## Shows a problem prominently (HUD banner) and in the log.
func warn(text: String) -> void:
	log_msg(text, COL_BAD)
	warning.emit(text)


var _msg_sound_t := -10.0


func log_msg(text: String, color: Color = COL_INFO) -> void:
	message.emit(text, color)
	# package 28a: a soft chime for good news, a sharper one for warnings – at most one per second
	var now := Time.get_ticks_msec() / 1000.0
	if (color == COL_WARN or color == COL_BAD or color == COL_GOOD) and now - _msg_sound_t > 1.0:
		_msg_sound_t = now
		Audio.play("notify" if color == COL_GOOD else "warn", "message", -6.0, 0.0)
