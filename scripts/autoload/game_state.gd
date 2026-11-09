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
signal ship_lost(offer: Dictionary)   # package 31a: the active ship was destroyed – the buy-back window
signal pods_changed                   # package 31a: escape pods appeared, were picked up or faded

const FactionData = preload("res://data/factions.gd")
const COL_INFO := Color(0.8, 0.9, 1.0)
const COL_GOOD := Color(0.5, 1.0, 0.6)
const COL_WARN := Color(1.0, 0.8, 0.4)
const COL_BAD := Color(1.0, 0.45, 0.4)
const JUMP_TIME := 6.0
## Package 40b: old (and patched) gates – the jump takes longer and very rarely goes wrong.
const OLD_GATE_TIME := 1.6
const MISJUMP_OLD := 0.03
const MISJUMP_PIRATE := 0.015
const MISJUMP_DAMAGE := 0.15
var misjumps := {}                  # ship uid -> true: this jump goes wrong (rolled at the start)
var debug_misjump := false          # 40e: the next jump of the pilot's ship goes wrong (debug menu)
var pending_arrival := {}           # for the view: how the active ship arrived ({kind: "gate" / "misjump", …})
const START_CREDITS := 30000
const MAX_ACTIVE_MISSIONS := 5

var pilot_name := "Lefty"
## Package 28: the pilot – {"name", "callsign", "look" (PilotArt), "attrs" (data/pilot.gd)}; pilot_name mirrors the name
var pilot := {}
const PilotArt = preload("res://scripts/core/pilot_art.gd")
const PilotData = preload("res://data/pilot.gd")
const SkillData = preload("res://data/skills.gd")
const TreeData = preload("res://data/skilltree.gd")
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
## Package 31: crew waiting in station quarters (station_id -> [members]) and the bars' offers
## (station_id -> {"t": play time made, "offers": [{"m": member, "price": cr}]}).
var crew_quarters := {}
var bar := {}
var _crew_seq := 1
## Package 31a: where the pilot comes back ({"system", "id"} of the last station docked at), escape pods drifting
## in space ([{"id", "system", "pos", "crew": [{"m", "until"}]}]), the open buy-back offer, crew rescued from pods
## and waiting aboard for the next station.
var last_station := {}
var pods: Array = []
var loss_offer := {}
var rescued: Array = []
var _pod_seq := 1
var _pod_tick_t := 0.0
## Package 33: wingmen under contract ([{"w": wingman, "until", "stance", "minutes"}]); the wingman carries its ship
## as plain data in w["ship"]. Their ships fly as nodes only while the pilot is in space (SystemView).
var wingmen: Array = []
var _wing_tick_t := 0.0
## Package 34: the collection – crew perks the pilot has had in the crew, notorious pirates destroyed
var collection := {"perks": [], "notorious": [], "stars": [], "planets": []}     # 0.6.37.2: star classes; 0.6.38.1: planet and moon types
var _collect_t := 0.0
signal wingmen_changed
const WingData = preload("res://data/wingmen.gd")
const CrewData = preload("res://data/crew.gd")
const CrewCore = preload("res://scripts/core/crew.gd")
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

## Package 39a: the Senate of the Assembly (bills, votes, laws in force) – see scripts/core/senate.gd.
const SenateScript = preload("res://scripts/core/senate.gd")
var senate = SenateScript.new()
## Package 39b: the Curia of the Covenant (edicts, tithes, indulgences, relics) – see scripts/core/curia.gd.
const CuriaScript = preload("res://scripts/core/curia.gd")
var curia = CuriaScript.new()
## Package 39: entry permits to the capitals (faction -> true). Given from Friendly on, taken away only at Arch-enemy.
var permits := {}
var prosperity := {}
var market_stock := {}          # package 42b: station id -> {good: [stock, play time]} – only goods that were traded            # package 42: system id -> prosperity 0–100 (only systems whose value has changed / been read)
var _permit_t := 0.0
var _prosper_t := 0.0             # package 42c: prosperity drifts back to its base
## Package 39c: research data from analysed anomalies, sold at the Research Exchange (Meridian Sphere, Durchbruch).
var research_data := 0
const DATA_PRICE := 5000           # per unit of data …
const DATA_REP := 0.5              # … and standing with the Directorate
const EM_SELL := 12000             # exotic matter: what the exchange pays …
const EM_SELL_REP := 1.0
const EM_BUY := 30000              # … and what it asks (Allied only)
const PROBE_TIME := 120.0          # a measurement probe needs two minutes in the target system


func _ready() -> void:
	convoys = ConvoySimScript.new()
	convoys.name = "Convoys"
	add_child(convoys)
	convoys.convoy_delivered.connect(_on_convoy_done.bind(true))
	convoys.convoy_lost.connect(_on_convoy_done.bind(false))


## Package 42: prosperity from a save (JSON keys come back as strings).
func load_prosperity(prd: Dictionary) -> void:
	prosperity.clear()
	for pk in prd:
		prosperity[int(pk)] = float(prd[pk])


func _saved_prosperity() -> Dictionary:
	var out := {}
	for k in prosperity:
		out[str(k)] = snappedf(float(prosperity[k]), 0.01)
	return out


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
	stats = {"kills": 0, "jumps": 0, "mined": 0.0, "analysed": 0, "missions_done": 0, "refined": 0, "built": 0, "earned": 0,
		# package 30: achievements for the skill tree
		"warps": 0, "systems": [], "refined_station": 0, "markets": [], "turnover": 0, "bounty_jobs": 0, "jobs_covenant": 0,
		"jobs_assembly": 0, "passengers": 0, "exotic": 0, "scans": 0, "bounties": 0}
	if test_system:
		pilot["tree_all"] = true                 # the test system: everything open
	crew_quarters.clear()
	bar.clear()
	_crew_seq = 1
	pods.clear()
	loss_offer = {}
	rescued.clear()
	_pod_seq = 1
	prosperity.clear()                      # package 42
	market_stock.clear()
	wingmen.clear()
	collection = {"perks": [], "notorious": [], "stars": [], "planets": []}
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
	senate.reset()
	curia.reset()
	permits.clear()
	research_data = 0
	fortress_broken.clear()
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
	last_station = {"system": current_system, "id": String(home_station["id"])}
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
		crew_fill_required(bas)
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
		"level": maxi(int(data.get("level", 1)), 1), "xp": float(data.get("xp", 0.0)), "perk_points": int(data.get("perk_points", 0)),
		"tree": (data.get("tree", []) as Array).duplicate(), "perks": (data.get("perks", []) as Array).duplicate(), "tree_all": bool(data.get("tree_all", false)),
		"crew_free": bool(data.get("crew_free", false))}


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


# ---------------------------------------------------------------- Package 30: achievements, skill tree, perks

## An achievement for the skill tree (lists count their distinct entries).
func metric(m: String) -> float:
	if m == "pilot_level":
		return float(pilot_level())
	var v = stats.get(m, 0)
	if v is Array:
		return float((v as Array).size())
	return float(v)


func count_stat(m: String, n: float = 1.0) -> void:
	stats[m] = float(stats.get(m, 0)) + n
	crew_learn(m, n)                         # package 31: the crew learns from the same work


## Adds a distinct entry (a system visited, a market traded at).
func note_stat(m: String, entry) -> void:
	if not stats.get(m, null) is Array:
		stats[m] = []
	if not entry in stats[m]:
		stats[m].append(entry)


func tile_open(id: String) -> bool:
	if bool(pilot.get("tree_all", false)) or id in TreeData.free_tiles():
		return true
	return id in pilot.get("tree", [])


## [[metric, have, need], …] of a tile.
func tile_progress(id: String) -> Array:
	var out: Array = []
	for r in TreeData.TILES[id]["req"]:
		out.append([r[0], metric(String(r[0])), float(r[1])])
	return out


func tile_ready(id: String) -> bool:
	if tile_open(id):
		return false
	var t: Dictionary = TreeData.TILES[id]
	for p in t["pre"]:
		if not tile_open(String(p)):
			return false
	var met := 0
	for r in tile_progress(id):
		if float(r[1]) >= float(r[2]):
			met += 1
	return met > 0 if bool(t.get("any", false)) else met == (t["req"] as Array).size()


func tiles_ready() -> Array:
	var out: Array = []
	for id in TreeData.TILES:
		if tile_ready(id):
			out.append(id)
	return out


## Confirms a tile whose achievements are met.
func tree_unlock(id: String) -> String:
	if not TreeData.TILES.has(id):
		return "Unknown tile."
	if tile_open(id):
		return "%s is already open." % TreeData.TILES[id]["name"]
	if not tile_ready(id):
		return "%s: the achievements are not met yet." % TreeData.TILES[id]["name"]
	pilot["tree"].append(id)
	log_msg("Skill tree: %s – %s now usable." % [TreeData.TILES[id]["name"], TreeData.opens_text(id)], COL_GOOD)
	for f in fleet:
		f.mark_dirty()                               # locked modules come online
	skills_changed.emit()
	return ""


## The best value of a tile's unlocks the pilot has (weapon_size, size, fab_size; quality "B"/"A").
func _tree_best(key: String, base: int) -> int:
	var best := base
	for id in TreeData.TILES:
		var u: Dictionary = TreeData.TILES[id]["unlocks"]
		if u.has(key) and tile_open(id):
			best = maxi(best, int(u[key]))
	return best


## "" = the pilot may fly this hull (0.5.30.2: everything can be bought – a locked ship cannot undock).
func hull_tree_error(hid: String) -> String:
	var t := TreeData.tile_of_hull(hid)
	if t == "" or tile_open(t):
		return ""
	return "Skill tree: open \"%s\" first (Pilot window)." % TreeData.TILES[t]["name"]


## "" = the pilot may use this module (0.5.30.2: bought freely; locked ones stay offline, locked core modules
## cannot be fitted – fitted ones keep working). Weapons have their own sizes.
func module_tree_error(mid: String) -> String:
	var m: Dictionary = GameData.modules.get(mid, {})
	if m.is_empty():
		return ""
	var fam := String(m.get("family", ""))
	var ft := TreeData.tile_of_family(fam)
	if ft != "" and not tile_open(ft):
		return "Skill tree: open \"%s\" first." % TreeData.TILES[ft]["name"]
	var q := String(m.get("quality", "C"))
	if q == "B" and not tile_open("quality_b") or q == "A" and not tile_open("quality_a"):
		return "Skill tree: quality %s needs \"Quality %s\"." % [q, q]
	var sz := int(m.get("size", 1))
	var slot := String(m.get("slot", ""))
	if slot == "weapon" and sz > _tree_best("weapon_size", 2):
		return "Skill tree: weapons of size %d need \"%s\"." % [sz, "Heavy Weapons" if sz == 3 else "Capital Weapons"]
	if slot in ["optional", "tool", "drone"] and sz > _tree_best("size", 2):
		return "Skill tree: modules of size %d need \"%s\"." % [sz, "Larger Modules" if sz <= 4 else ("Heavy Modules" if sz <= 7 else "Capital Modules")]
	return ""


## "" = the pilot holds the blueprint to manufacture this module (size).
func fab_tree_error(mid: String) -> String:
	if mid == "drone" or not GameData.modules.has(mid):
		return ""
	# 0.6.40.9: specialised blueprints – a craft-only module needs its own tile
	if GameData.modules[mid].get("craft_only", false):
		var bt := TreeData.tile_of_blueprint(String(GameData.modules[mid]["family"]))
		if bt != "" and not tile_open(bt):
			return "Skill tree: no blueprint yet (\"%s\")." % TreeData.TILES[bt]["name"]
	var sz := int(GameData.modules[mid]["size"])
	if sz > _tree_best("fab_size", 2):
		return "Skill tree: no blueprint for size %d yet (\"%s\")." % [sz, "Station Manufacturing" if sz <= 2 else ("Blueprints II" if sz <= 5 else "Blueprints III")]
	return ""


func has_perk(id: String) -> bool:
	return id in pilot.get("perks", [])


func perk_error(id: String) -> String:
	if not TreeData.PERKS.has(id):
		return "Unknown perk."
	var p: Dictionary = TreeData.PERKS[id]
	if has_perk(id):
		return "Already taken."
	if p.has("later"):
		return "Takes effect with %s." % p["later"]
	if String(p["skill"]) != "" and skill_level(String(p["skill"])) < int(p["lvl"]):
		return "Needs %s %d." % [SkillData.info(String(p["skill"]))[1], int(p["lvl"])]
	if int(pilot.get("perk_points", 0)) <= 0:
		return "No perk point left – every pilot level brings one."
	return ""


func perk_take(id: String) -> String:
	var e := perk_error(id)
	if e != "":
		return e
	pilot["perks"].append(id)
	pilot["perk_points"] = int(pilot["perk_points"]) - 1
	for f in fleet:
		f.mark_dirty()
	log_msg("Perk taken: %s – %s." % [TreeData.PERKS[id]["name"], TreeData.PERKS[id]["effect"]], COL_GOOD)
	skills_changed.emit()
	return ""


## Market Insider: where an item sells best in the neighbouring systems – [price, station, system] or [].
func best_nearby_sell(cid: String) -> Array:
	var best: Array = []
	for nb in Universe.systems[current_system]["links"]:
		for st in Universe.get_layout(int(nb))["stations"]:
			if not st.has("market"):
				continue
			var sp := Market.sell_price(st, cid)                 # package 42b: from the stock
			if best.is_empty() or sp > float(best[0]):
				best = [sp, String(st["name"]), String(Universe.systems[int(nb)]["name"])]
	return best


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
		log_msg("Pilot level %d! A perk point to spend – Pilot window [%s] → Perks." % [int(pilot["level"]), Keybinds.key_text("pilot_window")], COL_GOOD)
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
		"jobs": jobs.duplicate(true), "exotic_matter": exotic_matter, "fortress_broken": fortress_broken.duplicate(), "mission_counter": Missions._counter, "reputation": rep.to_dict(), "wanted": law.to_dict(), "notorious": notorious.to_dict(), "stations_down": stations.to_dict(), "news": news.to_dict(), "codex": codex.to_dict(),
		"senate": senate.to_dict(), "curia": curia.to_dict(), "permits": permits.duplicate(), "research_data": research_data,
		"prosperity": _saved_prosperity(), "market_stock": market_stock.duplicate(true),
		"crew_quarters": _saved_quarters(), "bar": _saved_bars(), "crew_seq": _crew_seq,
		"last_station": last_station.duplicate(), "pods": pods.duplicate(true), "loss_offer": loss_offer.duplicate(true),
		"rescued": rescued.duplicate(true), "pod_seq": _pod_seq, "wingmen": wingmen.duplicate(true),
		"collection": collection.duplicate(true),
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
	fortress_broken = d.get("fortress_broken", {}).duplicate()
	_next_uid = int(d["next_uid"])
	crew_quarters = d.get("crew_quarters", {}).duplicate(true)
	bar = d.get("bar", {}).duplicate(true)
	_crew_seq = int(d.get("crew_seq", 1))
	last_station = d.get("last_station", {}).duplicate()
	pods = d.get("pods", []).duplicate(true)
	loss_offer = d.get("loss_offer", {}).duplicate(true)
	rescued = d.get("rescued", []).duplicate(true)
	_pod_seq = int(d.get("pod_seq", 1))
	wingmen = d.get("wingmen", []).duplicate(true)
	collection = d.get("collection", {"perks": [], "notorious": []}).duplicate(true)
	for ck in ["stars", "planets"]:
		if not collection.has(ck):
			collection[ck] = []
	if not loss_offer.is_empty():
		ship_lost.emit.call_deferred(loss_offer)        # saved before deciding: ask again
	Missions._counter = int(d.get("mission_counter", 1000))
	rep.from_dict(d.get("reputation", {}))   # older saves: start standings
	law.from_dict(d.get("wanted", {}))
	stations.from_dict(d.get("stations_down", {}))
	codex.from_dict(d.get("codex", {}))
	if d.has("senate"):
		senate.from_dict(d["senate"])
	else:
		senate.reset()
	if d.has("curia"):
		curia.from_dict(d["curia"])
	else:
		curia.reset()
	permits = d.get("permits", {}).duplicate()
	load_prosperity(d.get("prosperity", {}))                   # package 42
	market_stock = (d.get("market_stock", {}) as Dictionary).duplicate(true)
	research_data = int(d.get("research_data", 0))
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
		count_stat("bounties", float(by_faction.size()))
		if has_perk("bounty_hunter"):
			paid = int(round(paid * 1.15))        # package 30
		add_credits(paid)
		crew_cut(paid)                            # package 31
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
		_lose_active(f)                       # package 31a
	else:
		for m0 in f.crew_members():
			log_msg("%s went down with the %s." % [m0["name"], f.ship_name], COL_BAD)
	fleet_changed.emit()


# ---------------------------------------------------------------- Losing the ship (package 31a)

## The active ship is gone: every crew member rolls to survive (escape pod), the pilot comes back at the last
## station in a beginner ship and is offered to buy the lost ship back for 10 % of its value.
func _lose_active(f: ShipFitting) -> void:
	var members := f.crew_members()
	var medic := false
	var agent := false
	var insured := false
	for m in members:
		medic = medic or String(m.get("perk", "")) == "medic"
		agent = agent or String(m.get("perk", "")) == "insurance_agent"
		insured = insured or String(m.get("perk", "")) == "cargo_insurance"
	var alive: Array = []
	var dead: Array = []
	for m2 in members:
		var p := float(CrewData.SURVIVE.get(String(m2["quality"]), 0.4))
		if String(m2.get("perk", "")) == "lucky":
			p = CrewData.SURVIVE_LUCKY
		elif medic and String(m2.get("perk", "")) != "medic":
			p = minf(p + CrewData.MEDIC_BONUS, 0.95)
		if _rng.randf() < p:
			alive.append({"m": m2, "until": play_time + float(CrewData.POD_TIME.get(String(m2["quality"]), 300.0))})
		else:
			dead.append(m2)
	for m3 in dead:
		log_msg("%s (%s) did not make it out." % [m3["name"], CrewData.role_name(String(m3["role"]))], COL_BAD)
	if not members.is_empty():
		codex.event("pod")
	if not alive.is_empty():
		var pod := {"id": "pod%d" % _pod_seq, "system": f.system_id, "pos": f.position, "crew": alive}
		_pod_seq += 1
		pods.append(pod)
		log_msg("%d crew member%s reached an escape pod – pick them up before the signal fades (%s)." % [alive.size(), "" if alive.size() == 1 else "s", ", ".join(PackedStringArray(alive.map(func(e): return String(e["m"]["name"]))))], COL_WARN)
		pods_changed.emit()
	# the offer: buy the ship back (hull, modules, drones – the crew is handled by the pods)
	var snap := f.to_dict()
	var value := ship_value(f)
	var factor := CrewData.BUYBACK * (0.95 if agent else 1.0)
	var price := int(round(float(value) * factor))
	var hull_cost := int(round(float(f.hull()["price"]) * factor))
	var st0 := _respawn_station()
	loss_offer = {"ship": snap, "name": f.ship_name, "hull": f.hull_id, "value": value, "price": price, "agent": agent,
		"hull_cost": hull_cost, "modules_cost": price - hull_cost, "modules_n": f.modules.size(), "drones_n": f.drones.size(),
		"cargo": f.cargo.duplicate(),
		"alive_info": alive.map(func(e): return [e["m"]["name"], e["m"]["quality"], CrewData.role_name(String(e["m"]["role"])), float(e["until"]) - play_time]),
		"dead_info": dead.map(func(e): return [e["name"], e["quality"], CrewData.role_name(String(e["role"]))]),
		"station": String(st0["id"]), "station_system": int(last_station.get("system", Universe.home_system)),
		"insured": insured, "cargo_value": cargo_value(f), "alive": alive.map(func(e): return e["m"]["name"]), "dead": dead.map(func(e): return e["name"]),
		"system": f.system_id, "where": f.location_text()}
	# back at the last station, for now in a beginner ship
	var next := _beginner_ship()
	active_uid = next.uid
	log_msg("Your own escape pod reaches %s. Aegis Mutual offers to rebuild the %s for %s." % [next.location_text(), f.ship_name, GameData.fmt_credits(price)], COL_WARN)
	active_changed.emit()
	ship_lost.emit(loss_offer)


## The last station docked at (the home station if it is gone).
func _respawn_station() -> Dictionary:
	if not last_station.is_empty():
		var st := Universe.find_station(int(last_station["system"]), String(last_station["id"]))
		if not st.is_empty():
			return st
	return Universe.get_layout(Universe.home_system)["stations"][0]


func _beginner_ship() -> ShipFitting:
	var st := _respawn_station()
	var f := create_from_preset("std_dragonfly", "player")
	f.ship_name = "Dragonfly »Second Chance«"
	f.system_id = int(st.get("system", int(last_station.get("system", Universe.home_system))))
	f.docked_at = String(st["id"])
	f.position = st["pos"]
	add_ship(f)
	return f


## Decides the buy-back offer: accept = rebuild the lost ship at the last station (instead of the beginner ship).
func loss_decide(accept: bool) -> String:
	if loss_offer.is_empty():
		return "There is nothing to decide."
	var o := loss_offer
	if not accept:
		loss_offer = {}
		log_msg("You decline the offer and keep the %s." % active().ship_name, COL_INFO)
		return ""
	if not spend(int(o["price"])):
		return "Not enough credits to buy the ship back."
	var beginner := active()
	var f := ShipFitting.from_dict(o["ship"])
	f.uid = 0
	f.route = []
	f.transit = 0.0
	f.transit_kind = ""
	f.crew = []
	if not bool(o.get("insured", false)):
		f.cargo = {}
	for d in f.drones:
		d["out"] = false
		d["hp"] = 1.0
		d["fuel"] = 1.0
	f.system_id = beginner.system_id
	f.docked_at = beginner.docked_at
	f.position = beginner.position
	add_ship(f)
	crew_fill_required(f)                     # rookies until the survivors are back
	f.refill()
	active_uid = f.uid
	fleet.erase(beginner)
	loss_offer = {}
	log_msg("Aegis Mutual hands you the rebuilt %s for %s%s." % [f.ship_name, GameData.fmt_credits(int(o["price"])), " – the cargo insurance brought the whole hold back" if bool(o.get("insured", false)) else ""], COL_GOOD)
	active_changed.emit()
	fleet_changed.emit()
	return ""


## Escape pods: crew whose signal faded is lost. Called every second or so.
func pods_tick() -> void:
	var changed := false
	for pod in pods.duplicate():
		for e in (pod["crew"] as Array).duplicate():
			if play_time >= float(e["until"]):
				pod["crew"].erase(e)
				log_msg("The signal of %s's escape pod has faded – lost." % e["m"]["name"], COL_BAD)
				changed = true
		if (pod["crew"] as Array).is_empty():
			pods.erase(pod)
			changed = true
	if changed:
		pods_changed.emit()


## A ship takes a pod aboard: the survivors fill free posts of their profession, the rest ride along to the next
## station (crew quarters). Returns how many were rescued.
func pod_pickup(pod_id: String, f: ShipFitting) -> int:
	for pod in pods:
		if String(pod["id"]) != pod_id:
			continue
		var n := 0
		var sl := f.crew_slots()
		for e in pod["crew"]:
			var m: Dictionary = e["m"]
			var placed := false
			for i in sl.size():
				if f.crew_at(i).is_empty() and CrewCore.fits(m, String(sl[i][0])):
					f.set_crew(i, m)
					placed = true
					break
			if not placed:
				rescued.append(m)
			n += 1
			log_msg("%s rescued%s." % [m["name"], " – back at the post" if placed else " – rides along to the next station"], COL_GOOD)
		pods.erase(pod)
		pods_changed.emit()
		Audio.play("mission_complete", "pod rescued")
		return n
	return 0


## Docked: rescued crew without a post move into the station's crew quarters.
func note_docked(system_id: int, station_id: String) -> void:
	last_station = {"system": system_id, "id": station_id}
	if not rescued.is_empty():
		var q := quarters_of(station_id)
		for m in rescued:
			q.append(m)
		log_msg("%d rescued crew member%s moved into the crew quarters." % [rescued.size(), "" if rescued.size() == 1 else "s"], COL_GOOD)
		rescued.clear()


# ---------------------------------------------------------------- Crew (package 31)

## A new crew member with a fresh id.
func new_crew(role: String, quality: String, perk: String = "?") -> Dictionary:
	var m := CrewCore.make(_rng, _crew_seq, role, quality, perk)
	_crew_seq += 1
	return m


## A newly bought ship comes with its required posts filled by rookies (quality F, never a perk); a Citadel also with
## a rookie platform pilot (package 33).
func crew_fill_required(f: ShipFitting) -> void:
	var sl := f.crew_slots()
	if not sl.is_empty() and fleet.has(f):
		codex.event("crew")                       # package 34: the first ship with crew
	for i in sl.size():
		if bool(sl[i][1]) and f.crew_at(i).is_empty():
			f.set_crew(i, new_crew(String(sl[i][0]), "F", ""))
		elif String(sl[i][0]) == "wing_pilot" and f.crew_at(i).is_empty():
			f.set_crew(i, new_crew("copilot", "F", "wingman"))


# ---------------------------------------------------------------- The Citadel's platform ship (package 33)

## The platform pilot aboard ({} = none).
func platform_pilot(f: ShipFitting) -> Dictionary:
	var sl := f.crew_slots()
	for i in sl.size():
		if String(sl[i][0]) == "wing_pilot":
			return f.crew_at(i)
	return {}


## "" = this hull may stand on the Citadel's platform: Hadrian Dynamics ships of size S.
func platform_hull_error(hid: String) -> String:
	var h: Dictionary = GameData.hulls.get(hid, {})
	if String(h.get("maker", "")) != "hadrian" or int(h.get("size", 0)) != 1:
		return "Only Hadrian Dynamics S ships fit the Citadel's platform."
	return ""


## The platform ship was destroyed: the pilot rolls for the pod, the ship can be recalled at a station for 10 %.
func platform_lost(citadel: ShipFitting, pos: Vector2) -> void:
	if citadel.platform_ship.is_empty():
		return
	citadel.platform_lost = citadel.platform_ship.duplicate(true)
	citadel.platform_ship = {}
	citadel.platform_out = false
	var sl := citadel.crew_slots()
	for i in sl.size():
		if String(sl[i][0]) == "wing_pilot" and not citadel.crew_at(i).is_empty():
			var m: Dictionary = citadel.set_crew(i, {})
			var p := float(CrewData.SURVIVE.get(String(m["quality"]), 0.4))
			if String(m.get("perk", "")) == "lucky":
				p = CrewData.SURVIVE_LUCKY
			if _rng.randf() < p:
				pods.append({"id": "pod%d" % _pod_seq, "system": citadel.system_id, "pos": pos, "crew": [{"m": m, "until": play_time + float(CrewData.POD_TIME.get(String(m["quality"]), 300.0))}]})
				_pod_seq += 1
				log_msg("%s got out of the %s – the escape pod waits for pick-up." % [m["name"], citadel.platform_lost["ship_name"]], COL_WARN)
				pods_changed.emit()
			else:
				log_msg("%s went down with the %s." % [m["name"], citadel.platform_lost["ship_name"]], COL_BAD)
	log_msg("The platform ship %s was destroyed – at a station it can be recalled for 10 %% of its value." % citadel.platform_lost["ship_name"], COL_BAD)
	citadel.mark_dirty()


func platform_recall_price(citadel: ShipFitting) -> int:
	if citadel.platform_lost.is_empty():
		return 0
	var f := ShipFitting.from_dict(citadel.platform_lost)
	return int(round(float(ship_value(f)) * CrewData.BUYBACK))


## "" = the ship may undock as far as the crew goes.
func crew_error(f: ShipFitting) -> String:
	if f == null or bool(pilot.get("crew_free", false)):
		return ""
	var miss := f.crew_missing()
	return "" if miss == "" else "Crew missing: %s – hire at a bar (The Bar) or move crew in the ship menu (Modules → Crew)." % miss


## The crew of the active ship (or of the ship that earned it – review K3) takes its share of an income; returns
## what it took.
func crew_cut(amount: int, earner: ShipFitting = null) -> int:
	var f := earner if earner != null else active()
	if f == null or amount <= 0:
		return 0
	var cut := int(round(float(amount) * (f.crew_share() + wing_share())))
	if cut <= 0:
		return 0
	credits -= cut
	stats["crew_paid"] = int(stats.get("crew_paid", 0)) + cut
	credits_changed.emit(credits)
	log_msg("%s share: −%s." % ["Crew and wingmen" if not wingmen.is_empty() else "Crew", GameData.fmt_credits(cut)], COL_INFO)
	return cut


## Experience for the crew of the active ship from a metric (count_stat); steps up are announced.
func crew_learn(metric_id: String, n: float) -> void:
	var rates: Array = CrewData.LEARN.get(metric_id, [])
	var f := active()
	if rates.is_empty() or f == null or n <= 0.0:
		return
	var sl := f.crew_slots()
	var drones_out := false
	for d in f.drones:
		drones_out = drones_out or bool(d.get("out", false))
	for i in sl.size():
		var m: Dictionary = f.crew_at(i)
		if m.is_empty():
			continue
		var role := String(sl[i][0])
		for r in rates:
			if String(r[0]) != role or (r.size() > 2 and r[2] == "drones" and not drones_out):
				continue
			var nq := CrewCore.learn(m, n * float(r[1]), _rng)
			if nq != "":
				f.mark_dirty()
				log_msg("%s (%s) rises to quality %s – %s." % [m["name"], CrewData.role_name(role), nq, CrewCore.line(m)], COL_GOOD)
				Audio.play("mission_complete", "crew step up")


# ---------------------------------------------------------------- The collection (package 34)

## Every perk a crew member of the pilot has (aboard any ship, in the quarters, the platform pilot) is collected.
func collect_perks() -> void:
	var have: Array = collection.get("perks", [])
	var found: Array = []
	for f in fleet:
		for m in f.crew_members():
			found.append(String(m.get("perk", "")))
	for sid in crew_quarters:
		for m2 in crew_quarters[sid]:
			found.append(String(m2.get("perk", "")))
	for p in found:
		if p != "" and not p in have:
			have.append(p)
			log_msg("Collection: crew perk \"%s\" collected." % CrewData.PERKS.get(p, {}).get("name", p), COL_GOOD)
			codex.event("collection")
	collection["perks"] = have


## 0.6.37.2: a star class goes into the collection the first time the pilot is in a system with such a star.
func collect_star(type_id: String) -> void:
	var have: Array = collection.get("stars", [])
	if type_id == "" or type_id in have:
		return
	have.append(type_id)
	collection["stars"] = have
	log_msg("Collection: star class \"%s\" recorded." % Universe.STAR_TYPES[Universe.star_index(type_id)]["name"], COL_GOOD)
	codex.event("collection")


## 0.6.38.1: planet and moon types go into the collection the first time the pilot is in a system with one.
func collect_planet(type_id: String) -> void:
	var have: Array = collection.get("planets", [])
	if type_id == "" or type_id in have:
		return
	have.append(type_id)
	collection["planets"] = have
	log_msg("Collection: %s recorded." % String(Universe.body_type(type_id)["name"]), COL_GOOD)
	codex.event("collection")


## A notorious pirate destroyed by the pilot goes into the collection – with the mugshot.
func collect_notorious(c: Dictionary) -> void:
	var NC = load("res://scripts/core/notorious.gd")
	NC.ensure_character(c)
	collection["notorious"].append({"name": c["name"], "nick": c["nick"], "stars": int(c["stars"]), "red": int(c.get("red", 0)),
		"look": (c["look"] as Dictionary).duplicate(), "hull": NC.hull_of(c), "paint": int(c["paint"]), "bounty": int(c["bounty"]),
		"trait": String(c["trait"]), "faction": String(c["faction"]), "t": play_time, "system": int(c.get("system", current_system)),
		"escorts_n": (c["escorts"] as Array).size(), "alive": false})
	codex.event("collection")


# ---------------------------------------------------------------- Wingmen (package 33)

## A wingman: name, portrait, level, Piloting and Gunnery, two traits, a ship with its standard fit.
func new_wingman(level: String = "") -> Dictionary:
	if level == "":
		level = _weighted(WingData.BAR_WEIGHTS)
	var fn: String = CrewData.FIRST_NAMES[_rng.randi() % CrewData.FIRST_NAMES.size()]
	var ln: String = CrewData.LAST_NAMES[_rng.randi() % CrewData.LAST_NAMES.size()]
	var sk: Array = WingData.SKILLS[level]
	var traits: Array = []
	var keys: Array = WingData.TRAITS.keys()
	while traits.size() < 2:
		var t: String = keys[_rng.randi() % keys.size()]
		var bad := t in traits
		for pair in WingData.TRAIT_PAIRS_FORBIDDEN:
			if t in pair and not traits.is_empty() and traits[0] in pair:
				bad = true
		if not bad:
			traits.append(t)
	var ships: Array = WingData.SHIPS[level]
	var hid: String = ships[_rng.randi() % ships.size()]
	var f := create_from_preset("std_" + hid, "player")
	f.ship_name = "%s »%s«" % [GameData.hulls[hid]["name"], ln]
	var w := {"id": _crew_seq, "name": "%s %s" % [fn, ln], "look": PilotArt.random_look(_rng), "level": level,
		"skills": {"piloting": _rng.randi_range(int(sk[0]), int(sk[1])), "gunnery": _rng.randi_range(int(sk[0]), int(sk[1]))},
		"traits": traits, "ship": f.to_dict()}
	_crew_seq += 1
	return w


func _weighted(weights: Dictionary) -> String:
	var total := 0.0
	for q in weights:
		total += float(weights[q])
	var x := _rng.randf() * total
	for q in weights:
		x -= float(weights[q])
		if x <= 0.0:
			return String(q)
	return String(weights.keys()[0])


## Leadership: a few per cent better wingmen, cheaper too.
func wing_leadership() -> float:
	return skill_bonus("leadership")


func wing_price(w: Dictionary, minutes: int) -> int:
	var f := 1.0
	for d in WingData.DURATIONS:
		if int(d[0]) == minutes:
			f = float(d[1])
	return int(round(float(WingData.PRICE[String(w["level"])]) * f * (1.0 - wing_leadership()) / 100.0)) * 100


func wing_max() -> int:
	return WingData.MAX if skill_level("leadership") >= WingData.LEADERSHIP_FOR_TWO else WingData.MAX_BASE


## The share of income all wingmen under contract take.
func wing_share() -> float:
	var s := 0.0
	for c in wingmen:
		s += float(WingData.SHARE[String(c["w"]["level"])])
	return s * (1.0 - wing_leadership())


## "" = the pilot may hire one more wingman.
func wing_hire_error() -> String:
	if not bool(pilot.get("tree_all", false)) and not tile_open("wing_command"):
		return "Skill tree: open \"Wing Command\" first (Pilot window)."
	if wingmen.size() >= wing_max():
		return "No room for another wingman (%d at once%s)." % [wing_max(), "" if wing_max() >= WingData.MAX else " – Leadership %d allows %d" % [WingData.LEADERSHIP_FOR_TWO, WingData.MAX]]
	return ""


func wing_hire(w: Dictionary, minutes: int) -> void:
	wingmen.append({"w": w, "until": play_time + float(minutes) * 60.0, "stance": "defensive", "minutes": minutes})
	codex.event("wingmen")
	skill_xp("leadership", 10.0)
	log_msg("%s (%s, %s) flies with you for %d minutes – share %d %% of the income." % [w["name"], w["level"], String(w["ship"]["ship_name"]),
		minutes, int(round(float(WingData.SHARE[String(w["level"])]) * 100.0))], COL_GOOD)
	wingmen_changed.emit()


func wing_contract(id: int) -> Dictionary:
	for c in wingmen:
		if int(c["w"]["id"]) == id:
			return c
	return {}


## Contracts run out; the wingman says goodbye.
func wing_tick() -> void:
	for c in wingmen.duplicate():
		if play_time >= float(c["until"]):
			wingmen.erase(c)
			log_msg("%s: \"Contract's up – good flying with you, CMDR.\" The %s leaves the formation." % [c["w"]["name"], c["w"]["ship"]["ship_name"]], COL_INFO)
			wingmen_changed.emit()


## A wingman's ship was destroyed: the wingman is dead, the contract over.
func wing_lost(id: int) -> void:
	var c := wing_contract(id)
	if c.is_empty():
		return
	wingmen.erase(c)
	log_msg("%s was killed – the %s is gone, the contract ends." % [c["w"]["name"], c["w"]["ship"]["ship_name"]], COL_BAD)
	wingmen_changed.emit()


## Bar offers of pilots (they change with the crew offers).
func bar_pilots(st: Dictionary) -> Array:
	bar_offers(st)                               # makes / refreshes the bar entry
	var e: Dictionary = bar[String(st["id"])]
	if not e.has("pilots"):
		e["pilots"] = []
		for i in _rng.randi_range(int(WingData.BAR_PILOTS[0]), int(WingData.BAR_PILOTS[1])):
			e["pilots"].append(new_wingman())
	return e["pilots"]


## The posts of a profession the pilot may fill (skill tree, 0.5.30.2 rule 10 of package 31).
func crew_role_error(role: String) -> String:
	if bool(pilot.get("tree_all", false)):
		return ""
	for id in TreeData.TILES:
		var u: Dictionary = TreeData.TILES[id]["unlocks"]
		var ok: bool = role in u.get("crew", [])
		for h in u.get("hulls", []):
			ok = ok or role in CrewData.roles_required_by(String(h))
		if ok and tile_open(id):
			return ""
	var where := TreeData.tile_of_crew(role)
	return "Skill tree: %s needs \"%s\" first." % [CrewData.role_name(role), TreeData.TILES[where]["name"] if where != "" else "?"]


## The bar of a station: offers made anew every BAR_REFRESH seconds.
func bar_offers(st: Dictionary) -> Array:
	var sid := String(st["id"])
	var e: Dictionary = bar.get(sid, {})
	if e.is_empty() or play_time - float(e.get("t", 0.0)) >= CrewData.BAR_REFRESH:
		e = {"t": play_time, "offers": []}
		var n := _rng.randi_range(int(CrewData.BAR_SIZE[0]), int(CrewData.BAR_SIZE[1]))
		var bias: Array = CrewData.BAR_BIAS.get(String(st.get("type", "")), [])
		var roles: Array = CrewData.hire_roles()
		for i in n:
			var role: String = String(bias[_rng.randi() % bias.size()]) if not bias.is_empty() and _rng.randf() < 0.5 else String(roles[_rng.randi() % roles.size()])
			var q := _weighted_quality()
			var m := new_crew(role, q, "" if q == "F" else "?")
			e["offers"].append({"m": m, "price": CrewCore.price(m, _rng)})
		bar[sid] = e
	return e["offers"]


func _weighted_quality() -> String:
	var total := 0.0
	for q in CrewData.BAR_WEIGHTS:
		total += float(CrewData.BAR_WEIGHTS[q])
	var x := _rng.randf() * total
	for q in CrewData.BAR_WEIGHTS:
		x -= float(CrewData.BAR_WEIGHTS[q])
		if x <= 0.0:
			return String(q)
	return "D"


## Review K1 / K6: only bars whose offers are still current and quarters with someone in them go into the save.
func _saved_bars() -> Dictionary:
	var out := {}
	for sid in bar:
		if play_time - float(bar[sid].get("t", 0.0)) < CrewData.BAR_REFRESH:
			out[sid] = bar[sid].duplicate(true)
	return out


func _saved_quarters() -> Dictionary:
	var out := {}
	for sid in crew_quarters:
		if not (crew_quarters[sid] as Array).is_empty():
			out[sid] = crew_quarters[sid].duplicate(true)
	return out


func quarters_of(station_id: String) -> Array:
	if not crew_quarters.has(station_id):
		crew_quarters[station_id] = []
	return crew_quarters[station_id]


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
	# package 42c: rich systems have more and better-paid work, impoverished ones less
	var lv := Economy.level(system_id)
	var want := Missions.OFFERS_PER_STATION + (1 if lv >= 3 else 0) - (1 if lv == 0 else 0)
	while list.size() < want:
		var m := Missions.generate(system_id, station, _rng)
		if m.has("reward"):
			m["reward"] = int(round(float(m["reward"]) * (0.85 + 0.075 * lv)))
		list.append(m)
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
	if m["type"] == "drone_trial" and (active() == null or active().drones.is_empty()):
		return "A field trial needs drones – fly a carrier with a drone hangar."
	if m.get("ballot", false) and not has_permit("assembly"):
		return "The ballots go to Landfall – you need the Assembly's entry permit."
	if m.get("to_capital", false) and not has_permit(String(m["faction"])):
		return "This goes to the capital – you need the %s's entry permit." % FactionData.short_of(String(m["faction"]))
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
		"courier":
			if m.get("ballot", false):
				m["expires"] = play_time + float(m.get("time_limit", 900.0))
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
		"relic":
			f.remove_cargo("earth_relic", 1.0)               # package 39b
		"exotic":
			exotic_matter -= int(m["amount"])                # package 39c
	missions.erase(m)
	var pay := int(round(Missions.payout(m) * (1.0 + skill_bonus("negotiation"))))      # package 29
	# package 30: achievements and perks
	if String(m["type"]) == "bounty":
		count_stat("bounty_jobs")
	if String(m.get("faction", "")) in ["covenant", "assembly"]:
		count_stat("jobs_" + String(m["faction"]))
	if String(m["type"]) == "passenger":
		count_stat("passengers", float(m.get("amount", 1)))
		if m.get("tourist", false):
			Economy.change(current_system, 0.6, "tourists")       # package 43b: holidaymakers bring money
	if String(m["type"]) == "escort" and has_perk("convoy_shepherd"):
		pay = int(round(pay * 1.2))
	if has_perk("diplomat"):
		m["rep"] = float(m.get("rep", rep.GAIN["contract"])) * 1.25
	add_credits(pay)
	crew_cut(pay)                                 # package 31
	Economy.change(current_system, Economy.CONTRACT_GAIN)      # package 42c: work done for the system
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
	if has_perk("fine_print"):
		rep_loss *= 0.5                          # package 30
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
			"probe":
				# package 39c: the probe measures while the pilot stays in the target system, out in space
				var pf := active()
				if int(m["progress"]) < 1 and pf != null and not pf.in_transit() and pf.system_id == int(m["target_system"]) and pf.docked_at == "":
					m["progress_t"] = float(m.get("progress_t", 0.0)) + delta
					if float(m["progress_t"]) >= PROBE_TIME:
						m["progress"] = 1
						log_msg("Measurements complete – return to the issuing station.", COL_GOOD)
						missions_changed.emit()
			"courier":
				if m.get("ballot", false) and play_time >= float(m.get("expires", INF)):     # package 39a
					var cf := active()
					if cf != null:
						cf.remove_cargo("sealed_cargo", float(m["amount"]))
					fail_mission(m, "the polls closed before the ballots arrived")
			"hunt":
				if int(m["progress"]) < 1:
					var cap: Dictionary = notorious.get_captain(String(m["captain"]))
					if cap.is_empty() or not cap["alive"]:
						fail_mission(m, "someone else got the target")


## Package 39c: the Research Exchange – sell research data and exotic matter, buy exotic matter (Allied).
func exchange(what: String, n: int = 1) -> String:
	match what:
		"data":
			if research_data <= 0:
				return "You have no research data – analyse anomalies."
			var k := research_data
			research_data = 0
			add_credits(k * DATA_PRICE)
			rep.change("directorate", minf(k * DATA_REP, 10.0), "research data")
			log_msg("Research Exchange: %d data set%s sold for %s." % [k, "" if k == 1 else "s", GameData.fmt_credits(k * DATA_PRICE)], COL_GOOD)
		"sell_em":
			if exotic_matter < n:
				return "Not enough exotic matter."
			exotic_matter -= n
			add_credits(n * EM_SELL)
			rep.change("directorate", n * EM_SELL_REP, "exotic matter")
			log_msg("Research Exchange: %d exotic matter sold for %s." % [n, GameData.fmt_credits(n * EM_SELL)], COL_GOOD)
		"buy_em":
			if not rep.at_least("directorate", "allied"):
				return "The Directorate sells exotic matter only to Allied pilots."
			if not spend(n * EM_BUY):
				return "Not enough credits."
			exotic_matter += n
			log_msg("Research Exchange: %d exotic matter bought for %s." % [n, GameData.fmt_credits(n * EM_BUY)], COL_GOOD)
	return ""


## Package 39b: an analysed anomaly may hold a relic of Earth (always, for a relic contract in its system).
func _find_relic(system_id: int) -> void:
	var f := active()
	if f == null:
		return
	var jobs: Array = missions.filter(func(m): return m.get("relic", false) and int(m["target_system"]) == system_id and int(m["progress"]) < 1)
	if jobs.is_empty() and randf() >= curia.RELIC_FIND:
		return
	if f.cargo_free() < GameData.item_volume("earth_relic"):
		log_msg("The anomaly held a relic of Earth – but your hold is full.", COL_WARN)
		return
	f.add_cargo("earth_relic", 1.0)
	for m in jobs:
		m["progress"] = 1
	if not jobs.is_empty():
		missions_changed.emit()
	log_msg("A relic of Earth recovered from the anomaly! The Church of Return pays for these in blessings (Cathedral of Return, Heimkehr).", COL_GOOD)


## Package 39a: a pirate destroyed by one of the pilot's drones – field trials of Concord Fleetworks.
func notify_drone_kill(system_id: int) -> void:
	if Universe.controller(system_id) != "assembly":
		return
	for m in missions:
		if m["type"] == "drone_trial" and int(m["progress"]) < int(m["amount"]):
			m["progress"] = int(m["progress"]) + 1
			if int(m["progress"]) >= int(m["amount"]):
				log_msg("Field trial complete – report back to the Concord Yards.", COL_GOOD)
			missions_changed.emit()


## Game events that advance contracts.
func notify(event: String, system_id: int) -> void:
	match event:
		"kill":
			stats["kills"] = int(stats["kills"]) + 1
			crew_learn("kills", 1.0)                 # package 31
			Economy.change(system_id, Economy.KILL_GAIN)      # package 42c: safer lanes
		"analyse":
			stats["analysed"] = int(stats["analysed"]) + 1
			crew_learn("analysed", 1.0)
			skill_xp("science", 20.0)
			_find_relic(system_id)                   # package 39b
			research_data += 1                        # package 39c: data for the Research Exchange
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

## 0.6.40.6: every route costs the same – no route classes any more (`_cls` kept for the callers).
func jump_fuel(f: ShipFitting, _cls: int = 1) -> float:
	return float(f.stats()["jump_fuel"])


## Empty string = jump possible, otherwise the reason.
## Axiom Threshold (package 25g): exotic matter – a pilot resource without cargo space.
var exotic_matter := 0
## Package 40d: broken pirate fortresses – system id (as text) -> play time until they are rebuilt
var fortress_broken := {}
const FORTRESS_REBUILD := 1800.0


func fortress_down(sid: int) -> bool:
	return float(fortress_broken.get(str(sid), 0.0)) > play_time


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
	if entry_error(to_id) != "":
		return entry_error(to_id)
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
	crew_learn("jumps", 1.0)
	skill_xp("navigation", 15.0)
	log_msg("%s opens a wormhole → %s (%d jump%s, %d exotic matter)." % [f.ship_name, Universe.systems[to_id]["name"], dist, "" if dist == 1 else "s", dist])
	ship_jumped_out.emit(f)
	return ""


const WORMHOLE_TIME := 3.0


## Package 39: entry permits to the capitals. Friendly standing gets one (a message), Arch-enemy loses it.
func check_permits() -> void:
	for fid in Universe.SPECIAL_CAPITALS:
		var f := String(fid)
		var sid := Universe.special_system(String(Universe.SPECIAL_CAPITALS[f]))
		if sid < 0:
			continue
		if not permits.has(f) and rep.at_least(f, "friendly"):
			permits[f] = true
			log_msg("The %s grants you an entry permit to %s – its gates will let you through." % [FactionData.name_of(f), Universe.systems[sid]["name"]], COL_GOOD)
			codex.event("permit")
		elif permits.has(f) and rep.tier_id(f) == "nemesis":
			permits.erase(f)
			log_msg("The %s has revoked your entry permit to %s." % [FactionData.name_of(f), Universe.systems[sid]["name"]], COL_BAD)


func has_permit(f: String) -> bool:
	return permits.has(f)


## Why the pilot may not enter system `sid` ("" = may). Only the capitals with a special system are closed.
func entry_error(sid: int) -> String:
	var f := Universe.special_faction(sid)
	if f == "" or has_permit(f):
		return ""
	return "%s is closed – the %s lets in only pilots with an entry permit (Friendly standing, yours: %s)." % [Universe.systems[sid]["name"], FactionData.name_of(f), rep.tier_name(f)]


func can_jump(f: ShipFitting, to_id: int) -> String:
	var sys: Dictionary = Universe.systems[f.system_id]
	if f in fleet:                               # package 39: the capitals check the pilot's ships
		var lock := entry_error(to_id)
		if lock != "":
			return lock
	if not sys["links"].has(to_id):
		return "No hyperspace route to %s" % Universe.systems[to_id]["name"]
	var s := f.stats()
	if int(s["drive_class"]) <= 0:
		return "No hyperdrive fitted"
	var need := jump_fuel(f)
	if f.fuel < need:
		return "Not enough fuel (%.0f / %.0f)" % [f.fuel, need]
	return ""


## 0.6.40.6: the grade of the jump drive (Mk I–III) – a better drive jumps faster and holds an old gate's failing
## field together (fewer misjumps).
const DRIVE_TIME := [1.0, 1.0, 0.85, 0.7]
const DRIVE_MISJUMP := [1.0, 1.0, 0.6, 0.3]


static func drive_grade(f: ShipFitting) -> int:
	return clampi(int(f.stats()["drive_class"]), 0, 3) if f != null else 1


## Package 40b: how long a jump from this system takes (old and patched gates are slower; 0.6.40.6: better drives faster).
func jump_duration(from_sid: int, f: ShipFitting = null) -> float:
	return JUMP_TIME * (OLD_GATE_TIME if Universe.old_gate(from_sid) else 1.0) * float(DRIVE_TIME[drive_grade(f)])


func begin_jump(f: ShipFitting, to_id: int) -> bool:
	var err := can_jump(f, to_id)
	if err != "":
		log_msg("%s: %s" % [f.ship_name, err], COL_WARN)
		return false
	f.fuel -= jump_fuel(f)
	f.transit_kind = "jump"
	f.transit_from = f.system_id
	f.transit_to = to_id
	f.transit_total = JUMP_TIME
	# package 40b: an old gate – longer, and now and then its field breaks down
	var style := Universe.gate_style(f.system_id)
	misjumps.erase(f.uid)
	f.transit_total = jump_duration(f.system_id, f)
	if debug_misjump and f.uid == active_uid:
		debug_misjump = false
		misjumps[f.uid] = true
	if style in ["old", "pirate"]:
		if randf() < (MISJUMP_OLD if style == "old" else MISJUMP_PIRATE) * float(DRIVE_MISJUMP[drive_grade(f)]):
			misjumps[f.uid] = true
		log_msg("The %s here is long past its last service – the jump takes longer, and its field is not to be trusted." % ("old gate" if style == "old" else "patched pirate gate"), COL_WARN)
	f.transit = f.transit_total
	f.docked_at = ""
	stats["jumps"] = int(stats["jumps"]) + 1
	crew_learn("jumps", 1.0)
	skill_xp("navigation", 8.0)
	codex.event("jump")
	log_msg("%s enters hyperspace → %s." % [f.ship_name, Universe.systems[to_id]["name"]])
	ship_jumped_out.emit(f)
	return true


func _arrive(f: ShipFitting) -> void:
	var from_id := int(f.transit_from)
	f.system_id = int(f.transit_to)
	if _may_roll_orbits(f):
		Universe.roll_orbits(f.system_id)        # package 36: planets and moons stand elsewhere on their orbits
	note_stat("systems", f.system_id)            # package 30
	if f.transit_kind == "wormhole":
		_arrive_wormhole(f)
	elif misjumps.has(f.uid):
		_misjump(f, from_id)                    # package 40b
	else:
		var gate := Universe.get_gate_pos(f.system_id, from_id)
		f.position = gate + (-gate).normalized() * 2500.0 + Vector2(randf_range(-600, 600), randf_range(-600, 600))
		f.rotation = (-gate).angle()
		if f.uid == active_uid:
			pending_arrival = {"kind": "gate", "from": from_id}
	if not f.route.is_empty() and int(f.route[0]) == f.system_id:
		f.route.pop_front()
	f.transit_kind = ""
	f.transit_to = null
	f.transit = 0.0
	current_system = f.system_id
	if f.route.is_empty():
		log_msg("%s arrived in %s." % [f.ship_name, Universe.systems[f.system_id]["name"]], COL_GOOD)
	ship_arrived_system.emit(f)


## Package 40b: the field of an old gate broke down mid-jump – the ship is flung out somewhere in the target system and
## takes some damage (never fatal).
func _misjump(f: ShipFitting, from_id: int) -> void:
	misjumps.erase(f.uid)
	var L := Universe.get_layout(f.system_id)
	var spots: Array = [Vector2.from_angle(randf() * TAU) * randf_range(500000.0, 1500000.0) * Universe.SCALE]
	for fl in L["fields"]:
		spots.append((fl["pos"] as Vector2) + Vector2.from_angle(randf() * TAU) * float(fl.get("radius", 10000.0)) * 1.2)
	f.position = spots[randi() % spots.size()]
	f.rotation = randf() * TAU
	var s := f.stats()
	var dmg := float(s["structure_max"]) * MISJUMP_DAMAGE
	var a := minf(f.armor, dmg)
	f.armor -= a
	f.structure = maxf(f.structure - (dmg - a), float(s["structure_max"]) * 0.25)
	log_msg("The field of the gate at %s broke down mid-jump – %s is flung out somewhere in %s and took damage." % [Universe.systems[from_id]["name"], f.ship_name, Universe.systems[f.system_id]["name"]], COL_BAD)
	if f.uid == active_uid:
		pending_arrival = {"kind": "misjump", "from": from_id}
	codex.event("misjump")


## Package 36: the orbits are rolled on arrival – unless another of the pilot's ships waits out in space in that
## system (it would suddenly be somewhere else relative to the stations).
func _may_roll_orbits(f: ShipFitting) -> bool:
	for o in fleet:
		if o != f and o.system_id == f.system_id and o.transit_to == null and o.docked_at == "":
			return false
	return true


## The end of a wormhole: next to a station – or, if it goes wrong, somewhere at random (maybe right in
## an asteroid field).
func _arrive_wormhole(f: ShipFitting, force_fail: int = -1) -> void:
	var L := Universe.get_layout(f.system_id)
	var fail := randf() < float(f.hull().get("wormhole", {}).get("fail", 0.1)) if force_fail < 0 else force_fail == 1
	if fail:
		var spots: Array = []
		for fl in L["fields"]:
			spots.append(fl["pos"])
		spots.append(Vector2.from_angle(randf() * TAU) * randf_range(400000.0, 1600000.0) * Universe.SCALE)
		f.position = spots[randi() % spots.size()] + Vector2.from_angle(randf() * TAU) * randf_range(0.0, 3000.0)
		log_msg("The wormhole collapsed early – %s is thrown out somewhere in %s!" % [f.ship_name, Universe.systems[f.system_id]["name"]], COL_WARN)
	elif not L["stations"].is_empty():
		var st: Dictionary = L["stations"][randi() % L["stations"].size()]
		f.position = (st["pos"] as Vector2) + Vector2.from_angle(randf() * TAU) * 6000.0
	else:
		f.position = Vector2.from_angle(randf() * TAU) * 500000.0 * Universe.SCALE
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
	_pod_tick_t -= delta
	if _pod_tick_t <= 0.0 and not pods.is_empty():
		_pod_tick_t = 1.0
		pods_tick()                              # package 31a
	_collect_t -= delta
	if _collect_t <= 0.0:
		_collect_t = 2.0
		collect_perks()                          # package 34
	_wing_tick_t -= delta
	if _wing_tick_t <= 0.0 and not wingmen.is_empty():
		_wing_tick_t = 1.0
		wing_tick()                              # package 33
	notorious.update(current_system)
	news.update()
	senate.update()                              # package 39a
	curia.update()                               # package 39b
	_permit_t -= delta
	if _permit_t <= 0.0:
		_permit_t = 1.0
		check_permits()
	_prosper_t -= delta
	if _prosper_t <= 0.0:
		_prosper_t = 30.0
		Economy.drift(30.0)                      # package 42c
	_update_faction_jobs(delta)
	_update_passengers()
	_update_tours(delta)                         # package 43b
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
## Package 43b: round trips – near the sight, out of warp, the sightseers look (TOUR_VIEW seconds).
func _update_tours(delta: float) -> void:
	var f := active()
	if f == null or f.in_transit() or Commands.world == null or not is_instance_valid(Commands.world):
		return
	var pl = Commands.world.player
	if pl == null or not is_instance_valid(pl) or pl.in_warp() or f.docked_at != "":
		return
	for m in missions:
		if String(m["type"]) != "passenger" or not m.has("tour") or int(m.get("ship_uid", -1)) != f.uid:
			continue
		var tr: Dictionary = m["tour"]
		if bool(tr["done"]) or int(tr["system"]) != current_system:
			continue
		var place := Missions.sight_place(tr)
		if place.is_empty() or (pl.position as Vector2).distance_to(place["pos"]) > float(place["range"]):
			continue
		if float(tr["t"]) <= 0.0:
			log_msg("The sightseers crowd the windows: %s." % tr["name"], COL_GOOD)
		tr["t"] = float(tr["t"]) + delta
		if float(tr["t"]) >= Missions.TOUR_VIEW:
			tr["done"] = true
			log_msg("They have seen %s – back to %s." % [tr["name"], Universe.find_station(int(m["target_system"]), String(m["target_station"])).get("name", "?")], COL_GOOD)
			Economy.change(current_system, 0.4, "tourists")
			codex.event("tour")
			missions_changed.emit()


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
