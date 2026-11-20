extends Node
## Package 58, part 1 (Luz, 18 Nov 2026): working for Dan begins. Dan's deal taken, he gives you Little Darling, the
## smallest KHI ship (a Mogura) in his rust colours: every core module at quality B, the strongest shield that fits.
## Boarding her opens the station window: a guided tour of it (scripts/ui/guided_tour.gd), then of the Outfitter;
## fitting the mining laser and the pulse laser Dan left in storage; back in the station window, a drone bought with
## Dan's advance. The wreck field (part 2), the contact on Brine and the escort (part 3) come next.
## Part 2: undock and warp to the wreck field Dan marks; there he explains the drone's controls (a guided tour over the
## drone panel); twenty units of scrap cut with the mining laser and the drone; home to Dan, who pays 2,000 cr.
## Part 3: Dan in his bar has the next job (a better laser and armour plating lent); Ossa Kell of Kell Freight meets
## you at your ship in Upper Brine; her two haulers leave Dan's store for the Driftwood Waystation as a real escort
## contract, pulled out of warp once by pirates on the way (radio calls from Ossa and Dan); docked in Driftwood she
## pays 3,000 cr, then Dan calls: enough for now, come back. Home at Dan's the mission is done.
## The story flag "w58_phase" keeps where it stands: "board" → "tour1" → "tour2" → "part2" → "drones" → "mine" →
## "home" → "part3" → "brine" → "convoy" → "call" → "back" → "party" → "maul" → "contact".
## Part 4 (Luz): docked at Dan's after the escort – black, "Three months later" and the pilot's thoughts; a party in
## Dan's bar (dancing, his toast in speech bubbles, cheers), then Dan and you at the bar (the pirates, the Maul, a
## friend in Driftwood); black, you wake in your room. "Taking the Fight to Them": Ossa in Upper Brine's shopping
## street gives you her Maul, well fitted.
## Part 5 (Luz): Silas Marr in the Driftwood Waystation's diner; his Bastion, the Stubborn Hope, goes out to a quiet
## asteroid field and unfolds the Listener (an animation on the ship) – three waves of pirates come for it; the sweep
## done, their base lies in Hollow. Phases "contact" → "follow" → "listen" → "found".

const GuidedTour = preload("res://scripts/ui/guided_tour.gd")
const TreeData = preload("res://data/skilltree.gd")
const MID := "darling"
const SHIP_NAME := "Little Darling"
const SCRAP_GOAL := 20.0                     # units of scrap for the first run
const ESCORT_PAY := 3000                     # Ossa's pay for the escort
const AMBUSH_PIRATES := 2                    # the pirates that pull her haulers out of warp
const IntroSix = preload("res://scripts/ground/intro_six.gd")
const FIGHT := "fight"
const CARDS := ["Three months later",
	"And so the days drifted out into space.",
	"Slowly, I'm getting used to this new world.",
	"It has its charms, but I know almost nothing about it. And Dan never says much about what goes on in the Cluster.",
	"Dan has become a good friend. But I can't stay here forever."]

var main: Node
var phase := ""
var tour = null


static func flags() -> Dictionary:
	return GameState.story.flags


## Little Darling into Dan's hangar (the Dragonfly of the start goes: you came out of the Veil without a ship).
static func give_ship(station_id: String) -> ShipFitting:
	for f in GameState.fleet:
		if f.ship_name == SHIP_NAME:
			return f
	var p: Dictionary = GameData.presets["std_mogura"]["modules"]
	var mods := {}
	for k in p:
		if String(k) in GameData.CORE_SLOTS:
			var id := GameData.legacy_id(String(p[k]))
			var b := id.left(id.rfind(":") + 1) + "B"
			mods[k] = b if GameData.modules.has(b) else id
	if not mods.has("hangar") and GameData.modules.has("hangar:1:B"):
		mods["hangar"] = "hangar:1:B"                      # a drone hangar: she carries one drone
	var smax := int((GameData.hulls["mogura"]["slot_sizes"]["optional"] as Array).max())
	for sz in range(smax, 0, -1):
		if GameData.modules.has("o_shield:%d:A" % sz):
			mods["optional_0"] = "o_shield:%d:A" % sz        # the strongest shield that fits
			break
	var f := GameState.create_fit("mogura", mods, "player")
	_fit_drone_gear(f, mods)                                # Luz: her drone hangar comes with a laser, a mining laser, a shield
	f.ship_name = SHIP_NAME
	f.paint = "dan_rust"
	f.lent = mods.duplicate()                               # Dan's gear works on his licence while it stays in her
	var st: Dictionary = Universe.find_station(GameState.current_system, station_id)
	f.system_id = GameState.current_system
	f.docked_at = station_id
	f.position = st.get("pos", Vector2.ZERO)
	var old: Array = GameState.fleet.duplicate()
	GameState.add_ship(f)
	GameState.crew_fill_required(f)
	if not GameState.set_active(f.uid):                   # she is your ship now (the view swaps the player too)
		GameState.active_uid = f.uid
	for o in old:
		if o.hull_id == "dragonfly" and o.docked_at == station_id:
			GameState.fleet.erase(o)
	# Dan's work needs no licence: the tree's tiles for her, her lasers and the drones are open
	var tiles: Array = GameState.pilot.get("tree", [])
	var want: Array = [TreeData.tile_of_hull("mogura")]
	for m in mods.values() + ["t_mining:1:C", "w_pulse:1:C"]:
		if GameData.modules.has(m):
			want.append(TreeData.tile_of_family(String(GameData.modules[m].get("family", ""))))
	for t in want:
		if t != "" and not t in tiles:
			tiles.append(t)
	GameState.pilot["tree"] = tiles
	# what Dan leaves in your storage: a mining laser and a pulse laser
	for m2 in ["t_mining:1:C", "w_pulse:1:C"]:
		if GameData.modules.has(m2):
			GameState.storage_add(station_id, m2)
	return f


func darling() -> ShipFitting:
	for f in GameState.fleet:
		if f.ship_name == SHIP_NAME:
			return f
	return null


func station_ui():
	return main.station_panel if main != null else null


## where: "yes" (just taken the deal), "load" (a save in part 1).
func begin(where: String) -> void:
	GameState.story.set_flag("intro_stage", "58")
	_ensure_missions()
	phase = String(flags().get("w58_phase", "board"))
	if where == "yes":
		var f := GameState.active()
		GameState.story.set_flag("w58_dan_st", f.docked_at if f != null else "")
		give_ship(f.docked_at if f != null else "")
		phase = "board"
		GameState.story.set_flag("w58_phase", phase)
	GameState.story.flags.erase("w58_warp_told")             # the warp tour comes again after a load (if still due)
	if phase in ["tour1"]:
		phase = "board"                                     # a tour starts again from its beginning
	elif phase == "tour2":
		phase = "fit"
	elif phase == "drones":
		phase = "part2"
	if phase in ["part2", "mine", "home"]:
		_part2_calls.call_deferred()
	# Dan's room (Luz: it must be there): given whenever the story is past the scrap – also for a save from before the
	# quarters, or the debug menu; a save whose journal stands at "A room upstairs" sleeps there first
	if bool(flags().get("w58_lent2", false)) and darling() != null and not darling().modules.values().has("o_armor:2:A"):
		_lend_armour(darling())                          # (Luz: the better plates – also in an older save)
	if phase in ["rest", "part3", "brine", "convoy", "call", "back", "part4"]:
		if not GameState.lodging.has(String(flags().get("w58_dan_st", ""))):
			_give_room()
		if GameState.story.running(MID) and String(GameState.story.step_data(MID).get("id", "")) == "rest" and not bool(flags().get("w58_slept", false)):
			_set_phase("rest")
	if phase in ["rest", "part3", "brine", "convoy", "call", "back"]:
		_part3_calls.call_deferred()
	if phase == "party":
		_after_party()                                   # a save in the middle of the party: the morning after
	if phase == "crew":
		_crew_started = true                             # a save in the middle of Ossa's crew tour: it is over
		_crew_done.call_deferred()
	if phase == "listen":
		_set_phase("follow")                             # a save in the middle of the sweep: from the start again
	if phase == "follow":
		_follow_calls.call_deferred()
	if not GameState.slept.is_connected(_on_slept):
		GameState.slept.connect(_on_slept)
	GameState.story_guard = _story_rescue                 # (Luz) shot down while working for Dan: no game over


## The deal taken: "A Ticket to the Cluster" at "Working for Dan", and the mission "Working for Dan" running – also
## when a save or the debug menu came here another way (Luz: it must be in the journal at once).
static func _ensure_missions() -> void:
	var st = GameState.story
	if not st.running("ticket") and not st.done.has("ticket"):
		st.start("ticket")
	if st.running("ticket") and st.step_data("ticket").get("id", "") == "deal":
		st.goto_step("ticket", 1)
	if not st.running(MID) and not st.done.has(MID):
		st.start(MID)
	if st.running(MID):
		st.tracked = MID


func _set_phase(p: String) -> void:
	phase = p
	GameState.story.set_flag("w58_phase", p)


func _process(_delta: float) -> void:
	if main != null and main.get_meta("dan_work", null) != self:
		queue_free()                                       # an older controller: the newest one works
		return
	var sp = station_ui()
	if sp == null:
		return
	var f := darling()
	if f == null:
		f = GameState.active()                             # (later parts: whatever you fly)
		if f == null or not phase in ["contact", "follow", "listen", "found", "maul", "crew"]:
			return
	# the fitting goals follow what is fitted (whatever the order)
	if GameState.story.running(MID):
		if not bool(flags().get("w58_mining", false)) and _has_family(f, "tool", "t_mining"):
			GameState.story.set_flag("w58_mining", true)
		if not bool(flags().get("w58_weapon", false)) and f.get_module("weapon_0") != "":
			GameState.story.set_flag("w58_weapon", true)
		if not bool(flags().get("w58_drone", false)) and f.drones.size() > 0:
			GameState.story.set_flag("w58_drone", true)
	match phase:
		"board":
			if sp.visible and sp.current_service == "" and GameState.active() == f and tour == null:
				GameState.story.set_flag("ticket_ship", true)
				_set_phase("tour1")
				_start_tour(_station_steps())
		"fit":
			if sp.visible and sp.current_service == "outfitter" and tour == null:
				_set_phase("tour2")
				_start_tour(_outfitter_steps())
		"part2":
			var v = main.view
			# out of the dock: Dan shows how to warp there (once)
			if tour == null and not bool(flags().get("w58_warp_told", false)) and v != null and is_instance_valid(v) and v.player != null \
					and is_instance_valid(v.player) and f.docked_at == "" and not v.player.in_warp() and not _field.is_empty() \
					and v.player.position.distance_to(_field["pos"]) > float(_field.get("radius", 12000.0)) * 1.15 \
					and main.hud != null and main.hud.tour_targets.has("ov_" + String(_field["id"])):
				GameState.story.set_flag("w58_warp_told", true)
				_start_tour(_warp_steps(), true)
			if tour == null and v != null and is_instance_valid(v) and v.player != null and is_instance_valid(v.player) and f.docked_at == "" \
					and not v.player.in_warp() and not _field.is_empty() \
					and v.player.position.distance_to(_field["pos"]) < float(_field.get("radius", 12000.0)) * 1.15:
				GameState.story.set_flag("w58_atfield", true)
				_set_phase("drones")
				_start_tour(_drone_steps(), true)
		"mine":
			if _units(f) - float(flags().get("w58_base", 0.0)) >= SCRAP_GOAL:
				GameState.story.set_flag("w58_mined", true)
				_set_phase("home")
				_part2_calls()
		"home":
			if f.docked_at == String(flags().get("w58_dan_st", "")) and sp.visible:
				for item in f.cargo.keys():
					if _scrap_kind(String(item)):
						f.remove_cargo(String(item), float(f.cargo[item]))
				GameState.story.set_flag("w58_delivered", true)
				_set_phase("rest")
				_give_room()
				GameState.story.show.emit("dialogue", {"id": "dan_scrap", "mission": MID})
				_part3_calls()
		"rest", "part3", "brine", "convoy", "call", "back", "maul", "crew", "contact":
			_part3_step(f, sp)
		"follow", "listen":
			_listen_step()


static func _has_family(f: ShipFitting, slot_type: String, fam: String) -> bool:
	for k in f.modules:
		if ShipFitting.slot_type(String(k)) == slot_type and GameData.modules.has(String(f.modules[k])) and String(GameData.modules[String(f.modules[k])].get("family", "")) == fam:
			return true
	return false


func _start_tour(steps: Array, flight: bool = false, src: String = "") -> void:
	for n in main.get_children():
		if n.get_script() == GuidedTour:
			n.queue_free()                                 # never two tours at once
	_flight = flight
	_src = src
	tour = GuidedTour.new()
	main.add_child(tour)
	tour.finished.connect(_tour_done)
	tour.start(steps, func(key): return _target(key), main.story_ui)


var _flight := false
var _src := ""                                         # package 58: "ship" – the tour is over the ship menu
var _crew_started := false
var _field := {}


func _target(key: String) -> Control:
	if _src == "ship":
		var sm = main.ship_menu
		var c0 = sm.tour_targets.get(key, null) if sm != null and sm.visible else null
		return c0 if c0 != null and is_instance_valid(c0) and (c0 as Control).is_visible_in_tree() else null
	if _flight:
		var hud = main.hud
		var h = hud.tour_targets.get(key, null) if hud != null else null
		return h if h != null and is_instance_valid(h) and (h as Control).is_visible_in_tree() else null
	var sp = station_ui()
	if sp == null or not sp.visible:
		return null
	if key == "body":
		return sp.body
	var c = sp.tour_targets.get(key, null)
	return c if c != null and is_instance_valid(c) else null


func _tour_done() -> void:
	tour = null
	match phase:
		"tour1":
			GameState.story.set_flag("w58_tour1", true)
			GameState.story.set_flag("w58_outfitter", true)
			_set_phase("tour2")
			_start_tour(_outfitter_steps())
		"tour2":
			GameState.story.set_flag("w58_tour2", true)
			_set_phase("part2")
			_part2_start()
		"drones":
			GameState.story.set_flag("w58_drones", true)
			GameState.story.set_flag("w58_base", _units(darling()))
			_set_phase("mine")
			_part2_calls()


# ---- part 2: the wreck field

## Units of scrap in the hold: ore, what the refinery made of it, salvage.
static func _units(f: ShipFitting) -> float:
	if f == null:
		return 0.0
	var n := 0.0
	for item in f.cargo:
		if _scrap_kind(String(item)):
			n += float(f.cargo[item])
	return n


static func _scrap_kind(item: String) -> bool:
	return String(GameData.commodities.get(item, {}).get("category", "")) in ["ore", "refined", "loot"]


## The wreck field nearest Dan's station; its marker on a colossus there (or the scrap nearest its middle).
func _pick_field() -> void:
	var L: Dictionary = Universe.get_layout(GameState.current_system)
	var dan := String(flags().get("w58_dan_st", ""))
	var from := Vector2.ZERO
	for st in L["stations"]:
		if String(st["id"]) == dan:
			from = st["pos"]
	var best := INF
	for fd in L["fields"]:
		if bool(fd.get("wreck", false)) and (fd["pos"] as Vector2).distance_to(from) < best:
			best = (fd["pos"] as Vector2).distance_to(from)
			_field = fd
	if _field.is_empty():
		return
	if GameState.story.missions.has(MID):
		GameState.story.missions[MID]["target"] = String(_field["id"])      # the field itself: gold in the overview


## Her drone hangar's gear (Luz, 18 Nov 2026): a laser, a mining laser and a shield emitter for the drones – Dan's,
## lent on his licence. `lent` (if given) gets the modules too.
static func _fit_drone_gear(f: ShipFitting, lent = null) -> void:
	for k in f.slot_keys():
		var t := ShipFitting.slot_type(String(k))
		var m: String = {"dweapon": "w_pulse:1:B", "dtool": "t_mining:1:B", "dbonus": "dr_shield:1:B"}.get(t, "")
		if m != "" and f.get_module(String(k)) == "" and GameData.modules.has(m) and f.can_fit(String(k), m) == "":
			f.modules[k] = m
			f.lent[k] = m
			if lent is Dictionary:
				lent[k] = m
	f.mark_dirty()


## Part 2 begins (after the drone): the drone gear checked (older saves), the wreck field marked.
func _part2_start() -> void:
	var f := darling()
	if f != null:
		_fit_drone_gear(f)
	_part2_calls()


## The call (and the marker) for where part 2 stands – it stays until that is done.
func _part2_calls() -> void:
	if _field.is_empty():
		_pick_field()
	var st = GameState.story
	match phase:
		"part2":
			st.show.emit("radio", {"who": "dan", "text": "Right then, time to earn that advance back. Her drone hangar fits out every drone she carries: a little gun, a mining laser and a shield, all on my licence. Now undock and warp to the wreck field I've marked: pick it in the overview on the right, or on the map.",
				"mission": MID, "until_flag": "w58_atfield", "hint": "warp to the marked wreck field"})
		"mine":
			st.show.emit("radio", {"who": "dan", "text": "Now fill her up. Lock a piece of Gold Fleet scrap, switch the mining laser on, and let the drone help. Twenty units will do. And keep an eye out: pirates like scrap too.",
				"mission": MID, "until_flag": "w58_mined", "hint": "cut 20 units of scrap"})
		"home":
			if st.missions.has(MID):
				st.missions[MID]["target"] = String(flags().get("w58_dan_st", ""))
			st.show.emit("radio", {"who": "dan", "text": "That'll do nicely. Recall the drone, {key:drone_recall}, and bring it all home to me.", "mission": MID})


## Out of the dock (Luz, 18 Nov 2026): how to warp – the field in the overview (gold), picked, then "Warp to".
func _warp_steps() -> Array:
	var v = main.view
	var fid := String(_field.get("id", ""))
	return [
		{"key": "ov_" + fid, "title": "The overview", "text": "Out we go. On the right, the overview: everything in this system you can fly to, nearest first. The field I want is the one glowing gold."},
		{"key": "ov_" + fid, "title": "Pick it", "text": "Click it. It shows up in the panel above, with what you can do there.",
			"task": func(): return v != null and is_instance_valid(v) and String(v.selected_id) == fid, "hint": "click the wreck field in the overview"},
		{"key": "warp_button", "title": "Warp", "text": "Now Warp to. The ship turns, picks up speed and jumps across the system in a few seconds. Anything further than about 40,000 km, you warp. Closer, you fly or approach.",
			"task": func(): return v != null and is_instance_valid(v) and v.player != null and is_instance_valid(v.player) and v.player.in_warp(), "hint": "warp to the wreck field", "allow": ["cmd_warp"]},
	]


# ---- part 3: Ossa Kell and the escort to Driftwood

## The story's people on foot (main asks before it builds a deck): Dan in his bar from part 3 on, Ossa Kell beside
## your ship in Upper Brine's hangar while she waits for you.
func ground_mode(st: Dictionary) -> Dictionary:
	var sid := String(st.get("id", ""))
	if sid == String(flags().get("w58_dan_st", "")) and phase == "party":
		return _party_mode()
	if phase == "contact" and sid == String(_waystation().get("id", "-")):
		return {"levels": {"commercial": {"people": [{"who": "silas", "near_obj": "jukebox", "off": Vector2(2.5, 6.6), "spread": 1.0, "dir": 0, "marker": "!"}]}}}
	if phase == "maul" and bool(st.get("city", false)) and String(st.get("body", "")) == _brine_id():
		return {"levels": {"street": {"people": [{"who": "ossa", "near_obj": "lamp_post", "off": Vector2(1.5, 0.8), "near_spawn": Vector2(12.0, 2.0), "spread": 2.0, "dir": 0, "marker": "!"}]}}}
	if sid == String(flags().get("w58_dan_st", "")) and phase in ["rest", "part3", "brine", "convoy", "call", "back", "part4", "maul", "contact"]:
		var dan := {"who": "dan", "pos": IntroSix.WINDOW, "dir": 1, "talk": true}
		if phase == "part3":
			dan["marker"] = "!"
		return {"levels": {"commercial": {"people": [dan]}}}
	if phase == "brine" and bool(st.get("city", false)) and String(st.get("body", "")) == _brine_id():
		return {"levels": {"hangar": {"people": [{"who": "ossa", "at_ship": Vector2(2.6, 1.2), "dir": -1, "marker": "!"}]}}}
	return {}


static func _brine_id() -> String:
	for p in Universe.get_layout(Universe.special_system("beyond"))["planets"]:
		if String(p["name"]) == "Brine":
			return String(p["id"])
	return ""


static func _waystation() -> Dictionary:
	var dsid := Universe.special_system("driftwood")
	for st in Universe.get_layout(dsid)["stations"]:
		if String(st.get("type", "")) == "waystation":
			return st
	return {}


## Package 58 (Luz): shot down while working for Dan – no game over. Little Darling is towed home and patched up,
## you wake in Dan's clinic and he talks to you; an escort under way starts again once you undock.
func _story_rescue(f: ShipFitting) -> bool:
	if not (GameState.story.running(MID) or GameState.story.running(FIGHT)) or phase in ["board", "tour1", "tour2", "fit", "party"] \
			or not (f == darling() or f.ship_name == MAUL_NAME):
		return false
	var dan_st := String(flags().get("w58_dan_st", ""))
	var beyond := Universe.special_system("beyond")
	var st := Universe.find_station(beyond, dan_st)
	if st.is_empty():
		return false
	GameState.log_msg("%s was shot to pieces. Dan's salvage crew towed what was left home." % f.ship_name, GameState.COL_BAD)
	var s := f.stats()
	f.structure = float(s["structure_max"])
	f.armor = float(s["armor_max"])
	f.shield = float(s["shield_max"])
	f.system_id = beyond
	f.docked_at = dan_st
	f.position = st.get("pos", Vector2.ZERO)
	for d in f.drones:
		d["out"] = false
	if phase == "convoy":
		var m := _contract()
		if not m.is_empty():
			var c: Dictionary = GameState.convoys.find(int(m.get("convoy", -1)))
			if not c.is_empty():
				GameState.convoys.convoys.erase(c)
			GameState.missions.erase(m)
			GameState.missions_changed.emit()
		for fl in ["w58_departed", "w58_ambush", "w58_ambush_won", "w58_arrived", "w58_ambush_dan", "w58_ambush_ossa", "w58_contract"]:
			GameState.story.flags.erase(fl)
		GameState.story.set_flag("w58_retry", true)
	GameState.current_system = beyond
	_rescue_wake.call_deferred(st)
	return true


func _rescue_wake(st: Dictionary) -> void:
	if main == null:
		return
	main.load_system(Universe.special_system("beyond"))
	main.station_panel.close()
	main._wake_at(st)
	await get_tree().create_timer(2.2).timeout
	GameState.story.show.emit("dialogue", {"id": "dan_wake", "mission": MID})


# ---- part 4: three months later, the party, the Maul

const MAUL_NAME := "Maul"
var quick := false                       # (tests: the waits short)


func _w(secs: float) -> Signal:
	return get_tree().create_timer(secs * (0.05 if quick else 1.0)).timeout


## The party in Dan's bar: Dan by the window, the regulars, Ossa, the doc and a crowd – many of them dancing.
func _party_mode() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 58004
	var people: Array = [{"who": "dan", "pos": IntroSix.WINDOW, "dir": 0}]
	var floor_c := IntroSix.WINDOW + Vector2(-0.5, 4.0)
	var named := ["patron_a", "patron_b", "patron_c", "ossa", "doc"]
	for i in named.size():
		people.append({"who": named[i], "near": floor_c, "spread": 4.5, "seed": i + 1, "dir": rng.randi() % 4, "dance": i % 2 == 0})
	for k in 9:
		var lk := ChibiArt.PilotArt.random_look(rng)
		people.append({"who": "guest_%d" % k, "look": lk, "near": floor_c, "spread": 5.5, "seed": 20 + k, "dir": rng.randi() % 4, "dance": k < 6})
	return {"no_crew": true, "levels": {"commercial": {"people": people, "spawn": IntroSix.WINDOW + Vector2(0.0, 2.0)}}}


## Docked at Dan's after the escort: the three months, the party, the talk at the bar, the morning after.
func _three_months() -> void:
	if phase == "party":
		return
	_set_phase("party")
	GameState.story.set_flag("w58_back", true)            # "Working for Dan" done
	main.station_panel.close()
	await main.fade(Color(0, 0, 0, 1), 0.8).finished
	await _cards()
	# the bar, full
	if main.ground == null or not is_instance_valid(main.ground):
		main.open_deck()
	var g = main.ground
	if g == null:
		_after_party()
		return
	g.story_mode = _party_mode()
	g.go_level("commercial", "story")
	g.input_enabled = false
	if not g.story_talk.is_connected(_on_talk):
		g.story_talk.connect(_on_talk)
	_toast_stage(g)
	main.fade(Color(0, 0, 0, 0), 1.2)
	await _w(1.6)
	await _toast(g)
	await main.fade(Color(0, 0, 0, 1), 0.5).finished
	_to_counter(g)
	main.fade(Color(0, 0, 0, 0), 0.6)
	await _w(0.7)
	GameState.story.show.emit("dialogue", {"id": "dan_party", "mission": ""})
	await get_tree().process_frame
	while main.story_ui.dialogue != null or not main.story_ui._dlg_q.is_empty():
		await get_tree().process_frame
	await main.fade(Color(0, 0, 0, 1), 1.2).finished
	if main.ground != null and is_instance_valid(main.ground):
		main.ground.story_cam = Vector2.INF
		main.ground.story_zoom = 0.0
		if main.ground.is_sitting():
			main.ground._stand_up()
	_after_party()
	# the morning after: awake in your room
	g = main.ground
	if g != null and is_instance_valid(g):
		g.story_mode = {}
		g._q_room = int((GameState.lodging.get(String(flags().get("w58_dan_st", "")), {}) as Dictionary).get("room", -1))
		g._q_sleep = 2
		g.go_level("quarters", "bed")
		g.pilot.visible = false
		g.input_enabled = false
		main.fade(Color(0, 0, 0, 0), 1.4)
		await _w(2.2)
		await main.fade(Color(0, 0, 0, 1), 0.4).finished
		g._q_sleep = 0
		g.go_level("quarters", "bed")
		g.pilot.visible = true
		g.input_enabled = true
	main.fade(Color(0, 0, 0, 0), 0.6)


## The lines in the black: one after the other, each until a click, E, Space, Enter or ✕ (or a while).
func _cards() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 45
	cl.process_mode = Node.PROCESS_MODE_ALWAYS
	main.add_child(cl)
	var k := clampf(main.get_viewport().get_visible_rect().size.y / 900.0, 1.0, 2.4)
	var catcher := _CardKeys.new()
	cl.add_child(catcher)
	for i in CARDS.size():
		var lb := UI.wrap_label(String(CARDS[i]), int(round((34.0 if i == 0 else 22.0) * k)), Color(0.95, 0.9, 0.8) if i == 0 else Color(0.85, 0.85, 0.95), int(900 * k))
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lb.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		lb.grow_horizontal = Control.GROW_DIRECTION_BOTH
		lb.grow_vertical = Control.GROW_DIRECTION_BOTH
		lb.modulate.a = 0.0
		cl.add_child(lb)
		var tw := lb.create_tween()
		tw.tween_property(lb, "modulate:a", 1.0, 0.9)
		catcher.pressed = false
		var t := 0.0
		while t < 6.5 * (0.05 if quick else 1.0) and not (catcher.pressed and t > 0.6):
			await get_tree().process_frame
			t += get_process_delta_time()
		var tw2 := lb.create_tween()
		tw2.tween_property(lb, "modulate:a", 0.0, 0.6)
		await tw2.finished
		lb.queue_free()
	cl.queue_free()


class _CardKeys extends Node:
	var pressed := false

	func _init() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS

	func _input(e: InputEvent) -> void:
		if (e is InputEventMouseButton and e.pressed) or (e is InputEventJoypadButton and e.pressed and e.button_index == JOY_BUTTON_A) 				or (e is InputEventKey and e.pressed and not e.echo and e.keycode in [KEY_E, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]):
			pressed = true
			get_viewport().set_input_as_handled()


## Luz: it must be clear the toast is for you – you stand beside Dan by the window, the crowd turned to you both;
## the camera comes close.
func _toast_stage(g) -> void:
	var dan = g.story_people.get("dan", null)
	if dan != null and is_instance_valid(dan):
		g.pilot.pos = (dan.pos as Vector2) + Vector2(GroundMap.TILE * 1.3, GroundMap.TILE * 0.5)
		g.pilot.position = g.pilot.pos * GroundMap.SCALE
		g.pilot.dir = 2                                   # looking at Dan
		dan.dir = 0
		for key in g.story_people:
			var p = g.story_people[key]
			if p != dan and is_instance_valid(p):
				p.dir = 1 if (p.pos as Vector2).y > g.pilot.pos.y else 0       # turned to you both
		g.story_cam = ((dan.pos as Vector2) + g.pilot.pos) * 0.5 + Vector2(0, GroundMap.TILE * 1.5)
		g.story_zoom = 1.45
		g._camera()


## Dan's toast in speech bubbles, the crowd cheering.
func _toast(g) -> void:
	var dan = g.story_people.get("dan", null)
	var crowd: Array = []
	for key in g.story_people:
		if String(key) != "dan":
			crowd.append(g.story_people[key])
	var say := func(w, text: String, secs: float):
		if w != null and is_instance_valid(w):
			w.bubble = text
			w.bubble_t = secs
	say.call(dan, "Everyone! Listen up! A toast!", 2.6)
	await _w(2.6)
	var nm := String(GameState.pilot_name).replace("CMDR ", "")
	say.call(dan, "To %s, my best employee!" % nm, 3.0)
	await _w(1.0)
	var cheers := ["To %s!" % nm, "Hear, hear!", "To the Spacefarer!", "Cheers!", "%s!" % nm]
	for i in crowd.size():
		if i % 3 == 0:
			say.call(crowd[i], String(cheers[(i / 3) % cheers.size()]), 2.2)
		if crowd[i] != null and is_instance_valid(crowd[i]):
			crowd[i].drink_t = 1.6
	await _w(2.4)
	say.call(g.pilot, "Thanks, everyone. Really.", 2.2)
	g.pilot.drink_t = 1.6
	await _w(2.0)
	say.call(dan, "And all drinks are on me tonight!", 2.8)
	await _w(1.0)
	var whoops := ["Woo-hoo!", "Free drinks!", "Dan!", "Yeah!"]
	for i2 in crowd.size():
		if i2 % 3 == 1:                                  # (a few voices, not every one at once)
			say.call(crowd[i2], String(whoops[(i2 / 3) % whoops.size()]), 2.4)
	Audio.play("ui_buy", "the party: cheers", -6.0)
	await _w(3.0)


## Dan and you at the bar (Luz): sitting on two stools side by side, the camera close on you both.
func _to_counter(g) -> void:
	var dan = g.story_people.get("dan", null)
	# two neighbouring stools at the counter, nearest the bartender (not the high tables in the room); whoever sits
	# there makes room
	var bt0 = g._bartender
	var ref: Vector2 = (bt0.pos as Vector2) if bt0 != null and is_instance_valid(bt0) else g.pilot.pos
	var seats: Array = []
	for o in g.map.objects:
		if String(o.get("kind", "")) == "stool":
			seats.append({"seat": DeckGen._seat_pos(o, 0), "dir": int(o.get("face", 0)), "kind": "seat", "title": "Sit at the bar"})
	seats.sort_custom(func(a, b): return (a["seat"] as Vector2).distance_to(ref) < (b["seat"] as Vector2).distance_to(ref))
	var pair: Array = []
	if seats.size() >= 2:
		var first: Dictionary = seats[0]
		var best: Dictionary = seats[1]
		for s2 in seats.slice(1):
			if (s2["seat"] as Vector2).distance_to(first["seat"]) < (best["seat"] as Vector2).distance_to(first["seat"]):
				best = s2
		pair = [first, best]
		for w9 in g.people.duplicate():
			if w9 != dan and w9 != g.pilot and is_instance_valid(w9) and ((w9.pos as Vector2).distance_to(first["seat"]) < 10.0 or (w9.pos as Vector2).distance_to(best["seat"]) < 10.0):
				g.people.erase(w9)
				w9.queue_free()
	g.pilot.bubble_t = 0.0
	if dan != null and is_instance_valid(dan):
		dan.bubble_t = 0.0
		dan.dancing = false
	if pair.is_empty():
		var bt = g._bartender
		var at: Vector2 = (bt.pos as Vector2) + Vector2(0, GroundMap.TILE * 2.3) if bt != null and is_instance_valid(bt) else g.pilot.pos
		g.pilot.pos = at + Vector2(-10, 0)
		g.pilot.position = g.pilot.pos * GroundMap.SCALE
		g.pilot.dir = 1
		if dan != null and is_instance_valid(dan):
			dan.pos = at + Vector2(14, 0)
			dan.position = dan.pos * GroundMap.SCALE
			dan.dir = 1
		g.story_cam = at
	else:
		g._sit(pair[0])
		if dan != null and is_instance_valid(dan):
			dan.pos = pair[1]["seat"]
			dan.position = dan.pos * GroundMap.SCALE
			dan.dir = int(pair[1].get("dir", 1))
			dan.sitting = true
		g.story_cam = ((pair[0]["seat"] as Vector2) + (pair[1]["seat"] as Vector2)) * 0.5 + Vector2(0, -GroundMap.TILE * 0.6)
	g.story_zoom = 2.7                                    # (Luz) close on the two of you; the station's wall stays in the picture
	g._camera()


## The party over: "Working for Dan" done, "Taking the Fight to Them" begins – to Upper Brine, to Ossa.
func _after_party() -> void:
	_set_phase("maul")
	var st = GameState.story
	if not st.running(FIGHT) and not st.done.has(FIGHT):
		st.start(FIGHT)
	if st.running(FIGHT):
		st.tracked = FIGHT
		st.missions[FIGHT]["target"] = _brine_id()
		st.changed.emit()                                # the tracker shows it at once


## Ossa's Maul: a Hadrian gunboat, patched up and very well fitted (Luz) – a strong shield, five guns, an armour
## repairer (she mends herself), a drone bay with drones; all at quality A, her gear lent (it works without the tree).
func _give_maul() -> void:
	for f0 in GameState.fleet:
		if f0.ship_name == MAUL_NAME:
			return
	var darl := darling()
	var here := darl.docked_at if darl != null else GameState.active().docked_at
	var mods := {}
	var p: Dictionary = GameData.presets["std_hdy_maul"]["modules"]
	for k in p:
		var id := GameData.legacy_id(String(p[k]))
		var a := id.left(id.rfind(":") + 1) + "A"
		mods[k] = a if GameData.modules.has(a) else id
	var want := {"weapon_0": "w_railgun:3:A", "weapon_1": "w_railgun:3:A", "weapon_2": "w_autocannon:2:A", "weapon_3": "w_autocannon:2:A",
		"weapon_4": "w_rocket:2:A", "optional_0": "o_shield:5:A", "optional_1": "o_armorrep:4:A", "optional_2": "o_armor:3:A",
		"optional_3": "o_shieldboost:3:A", "tool_0": "t_repair:1:A", "hangar": "hangar:2:A",
		"dweapon_0": "w_pulse:1:A", "dtool_0": "t_repair:1:A", "dbonus_0": "dr_shield:1:A"}
	for k2 in want:
		if GameData.modules.has(String(want[k2])):
			mods[k2] = want[k2]
	var f := GameState.create_fit("hdy_maul", mods, "player")
	for k3 in mods.keys():
		if f.get_module(String(k3)) == "" and f.can_fit(String(k3), String(mods[k3])) == "":
			f.modules[k3] = mods[k3]
	f.ship_name = MAUL_NAME
	f.paint = "ossa_rust"                                     # (Luz) run-down, in orange: rust, primer plates, scratches
	f.lent = f.modules.duplicate()
	f.system_id = GameState.current_system
	f.docked_at = here
	f.drone_role = "combat"
	f.mark_dirty()
	var s := f.stats()
	for i in int(s.get("drones_max", 1)):
		f.drones.append({"fuel": 1.0, "hp": 1.0, "out": false})
	f.structure = float(s["structure_max"])
	f.armor = float(s["armor_max"])
	f.shield = float(s["shield_max"])
	GameState.add_ship(f)
	# Rook Varga, Ossa's best gunner (Luz: a special crew member) – then the other required posts, if any
	var sl := f.crew_slots()
	for i in sl.size():
		if String(sl[i][0]) == "gunner" and f.crew_at(i).is_empty():
			var rook := GameState.new_crew("gunner", "A", "old_hand")
			rook["name"] = "Rook Varga"
			rook["story"] = true
			f.set_crew(i, rook)
			break
	GameState.crew_fill_required(f)
	var tiles: Array = GameState.pilot.get("tree", [])
	var want_t: Array = [TreeData.tile_of_hull("hdy_maul")]
	for m in f.modules.values():
		if GameData.modules.has(String(m)):
			want_t.append(TreeData.tile_of_family(String(GameData.modules[String(m)].get("family", ""))))
	for t in want_t:
		if t != "" and not t in tiles:
			tiles.append(t)
	GameState.pilot["tree"] = tiles
	if not GameState.set_active(f.uid):
		GameState.active_uid = f.uid
	# Little Darling goes home to Dan's hangar (Ossa's people fly her back)
	if darl != null:
		var dan_st := String(flags().get("w58_dan_st", ""))
		var bst := Universe.find_station(Universe.special_system("beyond"), dan_st)
		darl.system_id = Universe.special_system("beyond")
		darl.docked_at = dan_st
		darl.position = bst.get("pos", darl.position)
	GameState.fleet_changed.emit()


## Ossa shows you how a crew works (Luz): the ship menu opens at Modules → Crew, a guided tour over it.
func _crew_tour() -> void:
	main.open_ship_menu()
	var sm = main.ship_menu
	sm.tab = 1                                            # Modules
	sm.mod_view = "crew"
	sm.rebuild()
	await get_tree().process_frame
	_start_tour(_crew_steps(), false, "ship")
	_crew_started = true


func _crew_steps() -> Array:
	var f := GameState.active()
	var share := ("%.1f" % (f.crew_share() * 100.0)) if f != null else "a few"
	return [
		{"key": "sm_crew_tab", "who": "ossa", "title": "The crew", "text": "Your ship menu: Modules, then Crew. Everything about the people aboard is in here."},
		{"key": "sm_posts", "who": "ossa", "title": "The posts", "text": "Every ship has its posts. Some are required: without them she won't undock. The Maul needs a gunner; a co-pilot and an engineer are welcome, not needed."},
		{"key": "sm_member", "who": "ossa", "title": "Rook Varga", "text": "That's Rook. Each crew member has a role, a quality from F to A, and a bonus to the ship in that role. Some have a trait, too: Rook's an Old Hand, half again as good as the rest."},
		{"key": "sm_share", "who": "ossa", "title": "Their share", "text": "They don't work for free. Your crew takes a share of what you earn: sales, bounties, contract pay. Here it's %s %%. Good people are worth it." % share},
		{"key": "sm_quarters", "who": "ossa", "title": "The quarters", "text": "Crew without a post wait in the quarters of a station. Pick a post on the left, then assign someone to it. New faces you'll find in the bars, once people out here know your name."},
	]


## The crew tour done: Dan's call, on to his friend in Driftwood.
func _crew_done() -> void:
	if phase != "crew":
		return
	_set_phase("contact")
	GameState.story.show.emit("radio", {"who": "dan", "text": "Ossa says you've got the Maul, and Rook with her. Good. Now listen: these aren't scrap haulers you're going after. You come back to me in one piece, you hear? I've sent you the contact of a friend in Driftwood. He'll be expecting you.", "mission": FIGHT})
	var stf = GameState.story
	if stf.running(FIGHT):
		stf.missions[FIGHT]["target"] = String(_waystation().get("id", ""))


# ---- part 5: the Listener

const ListenerFx = preload("res://scripts/world/listener_fx.gd")
const HOPE_NAME := "Stubborn Hope"
const LISTEN_TIME := 150.0                # seconds for the whole sweep
const WAVES := [[15.0, 1], [40.0, 2], [70.0, 2]]     # [at %, light pirates]; (Luz) one Maul with every wave, never two
const SETTLE_TIME := 9.0                  # (Luz) out of the warp she flies on a little before she stops
const COUNTDOWN := 5.0                    # then the Listener powers up: "starts in 5 s"
var _hope = null
var _hope_wait := 0.0                   # (Luz) she waits 10 s after undocking, unless you already follow her
var _fx = null
var _listen := 0.0
var _waves := 0
var _pirates: Array = []
var _bar_layer: CanvasLayer = null
var _bar: ProgressBar = null
var _bar_label: Label = null
var _respawn_t := 0.0
var _away_said := false
var _settle := -1.0                     # < 0: not there yet; > 0: flying on into the field; 0: counting down
var _count := 0.0
var _clear_t := 0.0


## The asteroid field Silas listens from: a quiet one in Driftwood (not a wreck belt), nearest the waystation.
func _listen_field() -> Dictionary:
	var dsid := Universe.special_system("driftwood")
	var L: Dictionary = Universe.get_layout(dsid)
	var ws := _waystation()
	var from: Vector2 = ws.get("pos", Vector2.ZERO)
	var best := {}
	var bd := INF
	for fd in L.get("fields", []):
		var d := (fd["pos"] as Vector2).distance_to(from)
		if bool(fd.get("wreck", false)):
			d += 1e9                                       # a rock field first
		if d < bd:
			bd = d
			best = fd
	return best


func _follow_calls() -> void:
	var st = GameState.story
	var fd := _listen_field()
	if st.running(FIGHT) and not fd.is_empty():
		st.missions[FIGHT]["target"] = String(fd["id"])
	st.show.emit("radio", {"who": "silas", "text": "I'm taking the Hope out. Undock, and follow me to the field I've marked. Stay close: the Bastion's slow, but she's not quiet.",
		"mission": FIGHT, "until_flag": "w58_atlisten", "hint": "follow the Stubborn Hope to the asteroid field"})


## Out in Driftwood, undocked: Silas's Bastion – spawned by the waystation, off to the field; then the sweep.
func _listen_step() -> void:
	var v = main.view
	if v == null or not is_instance_valid(v) or GameState.current_system != Universe.special_system("driftwood"):
		if phase == "listen":
			_listen_abort(false)
		return
	var pl = v.player
	if pl == null or not is_instance_valid(pl) or GameState.active().docked_at != "":
		return
	var dt := get_process_delta_time()
	if _hope == null or not is_instance_valid(_hope) or _hope.dying:
		if phase == "listen":
			_listen_abort(true)
			return
		_respawn_t -= dt
		if _respawn_t > 0.0:
			return
		_spawn_hope()
		return
	var fd := _listen_field()
	if phase == "follow":
		if _hope_wait > 0.0:
			_hope_wait -= dt
			if String(pl.order.get("type", "")) == "follow" and pl.order.get("node") == _hope:
				_hope_wait = 0.0
			if _hope_wait > 0.0:
				return
		if not _hope.in_warp() and String(_hope.order.get("type", "idle")) in ["idle", "move"] and _hope.position.distance_to(fd["pos"]) > float(fd.get("radius", 12000.0)):
			v.traffic.go(_hope, String(fd["id"]))
		_clear_t -= dt
		if _clear_t <= 0.0:
			_clear_t = 1.0
			_clear_field(fd)
		if _settle >= 0.0:
			_settle_step(dt)
			return
		if not _hope.in_warp() and _hope.position.distance_to(fd["pos"]) < float(fd.get("radius", 12000.0)) * 1.1 and pl.position.distance_to(_hope.position) < 9000.0 and not pl.in_warp():
			_settle_start(fd)
		return
	# the sweep
	var s: Dictionary = _hope.fit.stats()
	var hull := float(_hope.fit.structure) / maxf(float(s["structure_max"]), 1.0)
	if hull < 0.15:
		_listen_abort(true)
		return
	_clear_t -= dt
	if _clear_t <= 0.0:
		_clear_t = 1.0
		_clear_field(fd)
	var near: bool = pl.position.distance_to(_hope.position) < 14000.0
	if near:
		_away_said = false
		_listen = minf(_listen + dt * 100.0 / (LISTEN_TIME * (0.05 if quick else 1.0)), 100.0)
	elif not _away_said:
		_away_said = true
		GameState.story.show.emit("radio", {"who": "silas", "text": "Where are you going? I can't hold them off on my own! Get back here!", "mission": FIGHT, "now": true})
	while _waves < WAVES.size() and _listen >= float(WAVES[_waves][0]):
		_wave(_waves)
		_waves += 1
	_pirates = _pirates.filter(func(p): return p != null and is_instance_valid(p) and not p.dying)
	if _listen >= 100.0 and _waves >= WAVES.size() and _pirates.is_empty():
		_listen_done()
		return
	if _listen >= 100.0 and not _pirates.is_empty():
		_listen = 99.5                                    # the last of them first
	_update_bar(hull)


func _spawn_hope() -> void:
	var v = main.view
	var ws := _waystation()
	var at: Vector2 = (ws.get("pos", v.player.position) as Vector2) + Vector2(2400, -1600)
	_hope = v.spawn_npc("std_bastion", at, "civilian", "")
	_hope.fit.ship_name = HOPE_NAME
	# (Luz) she doesn't fight: no guns, no drones – it's on you to keep them off her
	for k in _hope.fit.modules.keys():
		var stp := ShipFitting.slot_type(String(k))
		var md: Dictionary = GameData.modules.get(String(_hope.fit.modules[k]), {})
		if stp in ["weapon", "dweapon", "dtool", "dbonus"] or String(md.get("slot", "")) == "hangar":
			_hope.fit.modules.erase(k)
	_hope.fit.drones.clear()
	_hope.fit.mark_dirty()
	_hope.escort_mark = true
	_hope.set_meta("story_hope", true)
	_waves = 0
	_listen = 0.0
	_hope.set_order({"type": "idle"})
	_hope_wait = 0.0 if quick else 10.0         # she sets off in 10 s, or as soon as you follow her
	GameState.log_msg("The Stubborn Hope undocks: follow her to the field.", GameState.COL_INFO)


## (Luz) the field is theirs alone: no traffic, no pirates lying in wait. Whoever is in it (and out of your sight) is
## taken away, and kept away while Silas is out there.
func _clear_field(fd: Dictionary) -> void:
	var v = main.view
	if fd.is_empty() or v == null or v.player == null:
		return
	var r := float(fd.get("radius", 12000.0)) * 1.5
	for n in get_tree().get_nodes_in_group("ships"):
		if not (n is Ship) or n == _hope or n.is_drone or n.dying or String(n.faction) == "player" or _pirates.has(n):
			continue
		if (n.position as Vector2).distance_to(fd["pos"]) < r and (n.position as Vector2).distance_to(v.player.position) > 6000.0:
			n.queue_free()


## Out of the warp: she flies on a little into the field, then stops; Silas calls, the countdown runs.
func _settle_start(fd: Dictionary) -> void:
	_settle = SETTLE_TIME * (0.05 if quick else 1.0)
	var to: Vector2 = (fd["pos"] as Vector2) - _hope.position
	var dist: float = clampf(to.length(), 1500.0, 3500.0)
	var dir: Vector2 = to.normalized() if to.length() > 1.0 else Vector2.RIGHT
	_hope.set_order({"type": "move", "pos": _hope.position + dir * dist})


func _settle_step(dt: float) -> void:
	if _settle > 0.0:
		_settle -= dt
		if _settle > 0.0:
			return
		_settle = 0.0
		_hope.set_order({"type": "idle"})
		_count = COUNTDOWN * (0.05 if quick else 1.0)
		GameState.story.show.emit("radio", {"who": "silas", "text": "This looks like a good spot. Nobody on my scope. I hope you're ready.", "mission": FIGHT, "now": true})
		_fx = ListenerFx.new()
		_fx.ship = _hope
		_hope.add_child(_fx)
		_show_bar(true)
	_count -= dt
	if _bar_label != null and is_instance_valid(_bar_label):
		_bar_label.text = "THE LISTENER · powering up   ·   starts in %d s" % int(ceil(maxf(_count, 0.0)))
	if _count <= 0.0:
		_listen_start()


func _listen_start() -> void:
	_set_phase("listen")
	_settle = -1.0
	GameState.story.set_flag("w58_atlisten", true)
	_hope.set_order({"type": "idle"})
	_listen = 0.0
	_waves = 0
	_pirates = []
	if _fx == null or not is_instance_valid(_fx):
		_fx = ListenerFx.new()
		_fx.ship = _hope
		_hope.add_child(_fx)
	var st = GameState.story
	if st.running(FIGHT):
		st.missions[FIGHT]["target"] = ""                # (no marker on the dish: the bar on top shows how it goes)
	st.show.emit("radio", {"who": "silas", "text": "The Listener is live. Every pirate in the system can hear us now, so keep your eyes open.", "mission": FIGHT, "now": true})
	_show_bar(true)


## A wave: two or three pirates from one side, out for the Bastion (the last with a heavy one).
func _wave(i: int) -> void:
	var v = main.view
	var n := int(WAVES[i][1])
	var dir := Vector2.from_angle(randf() * TAU)
	var lines := ["Contacts! Two of them, and one is a Maul, like yours. Keep them off the dish!",
		"More of them, from the other side, with another Maul. They really don't like being listened to.",
		"Here comes the next lot, Maul and all. This is their last try: hold on!"]
	for k in n + 1:
		var heavy: bool = k == n
		var p = v.spawn_npc("pirate_hdy_maul" if heavy else _light_pirate(), _hope.position + dir.rotated(randf_range(-0.5, 0.5)) * randf_range(4500.0, 6000.0))
		p.home = _hope.position
		p.set_order({"type": "attack", "target": _hope})
		v.spawn_fx(Fx.flash(p.position, Color(1.0, 0.4, 0.3), p.radius * 3.0))
		_pirates.append(p)
	GameState.story.show.emit("radio", {"who": "silas", "text": String(lines[mini(i, lines.size() - 1)]), "mission": FIGHT, "now": true})
	if i == 1:
		get_tree().create_timer(4.0 * (0.05 if quick else 1.0)).timeout.connect(func():
			GameState.story.show.emit("radio", {"who": "dan", "text": "Silas, you old fool, you said quiet! Spacefarer, you keep him breathing, you hear me?", "mission": FIGHT}))


## A light pirate for a wave: one of the small archetype ships, never a heavy Hadrian copy.
func _light_pirate() -> String:
	var A = load("res://data/pirate_archetypes.gd")
	var arch: String = String(A.pick(1.0)[0])
	var pr: Array = A.ARCHETYPES[arch]["presets"]
	return String(pr[randi() % mini(2, pr.size())])


func _listen_done() -> void:
	GameState.story.set_flag("w58_listened", true)
	_set_phase("found")
	_show_bar(false)
	if _fx != null and is_instance_valid(_fx):
		_fx.active = false
	GameState.story.show.emit("radio", {"who": "silas", "text": "Got them! All that chatter comes from one place: an old station in Hollow, right under the Hollow Crown's nose. I'm sending you the coordinates. Thank you, Spacefarer. Dan was right about you.", "mission": FIGHT, "now": true})
	var h = _hope
	get_tree().create_timer(8.0 * (0.05 if quick else 1.0)).timeout.connect(func(): _hope_leave(h))
	GameState.log_msg("[Story] Package 58 continues with the next part (the pirates' base in Hollow).", GameState.COL_WARN)


## The sweep broken off: the Bastion badly hit (or gone) – Silas pulls out; he'll wait at the waystation again.
func _listen_abort(said: bool) -> void:
	_set_phase("follow")
	_settle = -1.0
	_show_bar(false)
	_listen = 0.0
	_waves = 0
	_respawn_t = 25.0 * (0.05 if quick else 1.0)
	GameState.story.flags.erase("w58_atlisten")
	var st = GameState.story
	if st.running(FIGHT):
		for si in (st.mission_data(FIGHT)["steps"] as Array).size():
			if String(st.mission_data(FIGHT)["steps"][si]["id"]) == "follow":
				st.goto_step(FIGHT, si)
				break
	var h = _hope
	_hope = null
	if h != null and is_instance_valid(h) and not h.dying:
		if _fx != null and is_instance_valid(_fx):
			_fx.active = false
		get_tree().create_timer(2.5 * (0.05 if quick else 1.0)).timeout.connect(func(): _hope_leave(h))
	if said:
		st.show.emit("radio", {"who": "silas", "text": "I'm hit, badly! Pulling out before they finish the job. Meet me back at the waystation, we'll try again.", "mission": FIGHT, "now": true})
	_follow_calls.call_deferred()


## (Luz) the Hope doesn't just vanish: she aligns and warps off home to the waystation, and is gone once she's
## out of the warp (or out of sight).
func _hope_leave(h) -> void:
	if h == null or not is_instance_valid(h) or h.dying or main.view == null:
		return
	var ws := _waystation()
	h.set_meta("hope_leaving", true)
	if not ws.is_empty():
		main.view.traffic.go(h, String(ws.get("id", "")))
	_hope_leave_tick(h, 0)


func _hope_leave_tick(h, n: int) -> void:
	if h == null or not is_instance_valid(h) or h.dying:
		return
	var pl = main.view.player if main.view != null else null
	var far: bool = pl == null or not is_instance_valid(pl) or pl.position.distance_to(h.position) > 30000.0
	if h.in_warp():
		h.set_meta("hope_warped", true)
	var landed: bool = bool(h.get_meta("hope_warped", false)) and not h.in_warp()      # through the warp: home
	if far or landed or n > 90:
		h.queue_free()
		return
	get_tree().create_timer(1.0 * (0.05 if quick else 1.0)).timeout.connect(func(): _hope_leave_tick(h, n + 1))


func _show_bar(on: bool) -> void:
	if not on:
		if _bar_layer != null and is_instance_valid(_bar_layer):
			_bar_layer.queue_free()
		_bar_layer = null
		return
	if _bar_layer != null and is_instance_valid(_bar_layer):
		return
	_bar_layer = CanvasLayer.new()
	_bar_layer.layer = 11
	main.add_child(_bar_layer)
	var k := clampf(main.get_viewport().get_visible_rect().size.y / 900.0, 1.0, 2.4)
	var p := UI.neon_panel(Color(0.45, 0.9, 1.0, 0.8), Color(0.03, 0.05, 0.08, 0.92), 2)
	p.custom_minimum_size = Vector2(420 * k, 0)
	p.set_anchors_preset(Control.PRESET_CENTER_TOP)
	p.position = Vector2(-210 * k, 250 * k)
	_bar_layer.add_child(p)
	var vb := UI.vbox(4)
	p.add_child(vb)
	_bar_label = UI.label("THE LISTENER · signal sweep 0 %", int(14 * k), Color(0.45, 0.9, 1.0))
	vb.add_child(_bar_label)
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(0, 14 * k)
	vb.add_child(_bar)


func _update_bar(hull: float) -> void:
	if _bar == null or not is_instance_valid(_bar):
		_show_bar(true)
	if _bar == null:
		return
	_bar.value = _listen
	_bar_label.text = "THE LISTENER · signal sweep %d %%   ·   Stubborn Hope hull %d %%" % [int(_listen), int(hull * 100.0)]


## Dan's room for you: a medium one in his quarters, on the house, yours to keep.
func _give_room() -> void:
	var dan_st := String(flags().get("w58_dan_st", ""))
	var st := Universe.find_station(Universe.special_system("beyond"), dan_st)     # (wherever you are just now)
	if st.is_empty():
		return
	var QG = load("res://scripts/ground/quarters_gen.gd")
	var i: int = QG.room_for(st, "medium")
	if i < 0:
		i = QG.room_for(st, "small")
	GameState.lodging[dan_st] = {"room": i, "size": "medium", "free": true, "keep": true}


## A night slept: in Dan's quarters while he wants you rested – on to his job in the bar.
func _on_slept(station_id: String) -> void:
	if phase == "rest" and station_id == String(flags().get("w58_dan_st", "")):
		GameState.story.set_flag("w58_slept", true)
		_set_phase("part3")
		_part3_calls()
		GameState.story.show.emit("radio", {"who": "dan", "text": "Morning, sleepyhead. I'm down in the bar when you're ready. Got work for you.", "mission": MID})


## Talking to the story's people on foot.
func _on_talk(who: String) -> void:
	match who:
		"dan":
			if phase == "rest":
				GameState.story.show.emit("dialogue", {"id": "dan_rest", "mission": MID})
			elif phase == "part3":
				GameState.story.show.emit("dialogue", {"id": "dan_job", "mission": MID})
			elif phase in ["brine", "convoy"]:
				GameState.story.show.emit("dialogue", {"id": "dan_busy", "mission": MID})
		"ossa":
			if phase == "brine":
				GameState.story.show.emit("dialogue", {"id": "ossa_meet", "mission": MID})
			elif phase == "maul":
				GameState.story.show.emit("dialogue", {"id": "ossa_maul", "mission": FIGHT})
		"silas":
			if phase == "contact":
				GameState.story.show.emit("dialogue", {"id": "silas_meet", "mission": FIGHT})


## Dan's loan for the escort: a better laser (the Mogura has one weapon slot) and armour plating.
func _lend_escort_gear() -> void:
	var f := darling()
	if f == null or bool(flags().get("w58_lent2", false)):
		return
	GameState.story.set_flag("w58_lent2", true)
	var here := f.docked_at if f.docked_at != "" else String(flags().get("w58_dan_st", ""))
	var old := f.get_module("weapon_0")
	if f.can_fit("weapon_0", "w_pulse:1:A") == "" or old != "":
		if old != "" and not f.lent.has("weapon_0"):
			GameState.storage_add(here, old)                  # yours stays yours: into storage at Dan's
		f.modules["weapon_0"] = "w_pulse:1:A"
		f.lent["weapon_0"] = "w_pulse:1:A"
	_lend_armour(f)
	f.mark_dirty()


## The armour plating Dan lends (Luz: better) – plates of quality A in every free optional slot but the last:
## one big, one small. A save with his older loan gets the better plates.
static func _lend_armour(f: ShipFitting) -> void:
	for k0 in f.slot_keys():
		if f.lent.has(k0) and String(f.lent[k0]).begins_with("o_armor:"):
			f.modules.erase(k0)
			f.lent.erase(k0)
	var plates := 0
	for k in f.slot_keys():
		if plates >= 2 or ShipFitting.slot_type(String(k)) != "optional" or f.get_module(String(k)) != "":
			continue
		for arm in ["o_armor:2:A", "o_armor:1:A"]:
			if GameData.modules.has(arm) and f.can_fit(String(k), arm) == "":
				f.modules[k] = arm
				f.lent[k] = arm
				plates += 1
				break
	f.mark_dirty()
	f.armor = float(f.stats()["armor_max"])                 # fitted fresh: full


## Ossa's haulers as a real escort contract: from Dan's store to the Driftwood Waystation, 3,000 cr, one ambush.
func _make_contract() -> Dictionary:
	var src := Universe.special_system("beyond")
	var dan_st := String(flags().get("w58_dan_st", ""))
	var ws := _waystation()
	if ws.is_empty() or dan_st == "":
		return {}
	var n := int(flags().get("w58_tries", 0)) + 1
	GameState.story.set_flag("w58_tries", n)
	var m := {"id": "story_kell_%d" % n, "giver": dan_st, "giver_system": src, "client": "Kell Freight", "progress": 0,
		"item": "", "amount": 1, "target_system": src, "target_station": "", "faction": "", "against": "", "faction_job": false,
		"rep": 0.0, "story": MID}
	Missions.escort_fill(m, src, [Universe.special_system("driftwood"), ws], 2, "")
	m["reward"] = ESCORT_PAY
	m["title"] = "Escort: Kell Freight to the Driftwood Waystation"
	m["desc"] = "Ossa Kell's two haulers carry Dan's scrap from his store through the gate to the Driftwood Waystation. Stay with them: pirates pull convoys out of warp. Ossa pays %s when they dock." % GameData.fmt_credits(ESCORT_PAY)
	var e := GameState.accept_mission(m)
	if e != "" and not m in GameState.missions:
		GameState.log_msg("[Story] " + e, GameState.COL_WARN)
		return {}
	var c: Dictionary = GameState.convoys.find(int(m["convoy"]))
	c["story_ambush"] = AMBUSH_PIRATES
	c["story_flag"] = "w58_ambush"
	c["caller"] = "ossa"
	GameState.story.set_flag("w58_contract", String(m["id"]))
	for fl in ["w58_departed", "w58_ambush", "w58_ambush_won", "w58_arrived", "w58_ambush_dan", "w58_ambush_ossa"]:
		GameState.story.flags.erase(fl)
	return m


func _contract() -> Dictionary:
	var id := String(flags().get("w58_contract", ""))
	for m in GameState.missions:
		if String(m["id"]) == id:
			return m
	return {}


## The calls (and the marker) for where part 3 stands – each stays until it is done.
func _part3_calls() -> void:
	var st = GameState.story
	var mi: Dictionary = st.missions.get(MID, {})
	match phase:
		"rest":
			mi["target"] = String(flags().get("w58_dan_st", ""))
			var QG = load("res://scripts/ground/quarters_gen.gd")
			var lod: Dictionary = GameState.lodging.get(String(flags().get("w58_dan_st", "")), {})
			var no := int(QG.room(Universe.find_station(Universe.special_system("beyond"), String(flags().get("w58_dan_st", ""))), int(lod.get("room", -1))).get("no", 0))
			st.show.emit("radio", {"who": "dan", "text": "Your room's upstairs: take the lift up to the Quarters, room %d, the one with the green lamp. Sleep in the bed, then come and find me in the bar." % no,
				"mission": MID})                       # (Luz: a pointer only – said once, not held)
		"part3":
			mi["target"] = String(flags().get("w58_dan_st", ""))
		"brine":
			mi["target"] = _brine_id()
			st.show.emit("radio", {"who": "dan", "text": "Brine's the blue one. Out of the dock, pick Brine in the overview and warp there. At the planet, Descend, then pick Upper Brine on the planet map. Ossa meets you at your ship.",
				"mission": MID, "until_flag": "w58_ossa", "hint": "land in Upper Brine, meet Ossa Kell"})
		"convoy":
			var m := _contract()
			mi["target"] = String(flags().get("w58_dan_st", "")) if not bool(flags().get("w58_departed", false)) else String(m.get("target_station", ""))
			if not bool(flags().get("w58_departed", false)):
				st.show.emit("radio", {"who": "ossa", "text": "Ossa here. My haulers are outside Dan's store, marked green. Come alongside, or select my lead and Follow, and we're off.",
					"mission": MID, "until_flag": "w58_departed", "hint": "meet the haulers outside Dan's store"})
			elif bool(flags().get("w58_arrived", false)):
				st.show.emit("radio", {"who": "ossa", "text": "We're in, both of us. Dock at the waystation and the money's yours.", "mission": MID})
		"call":
			_call_dan()
		"back":
			mi["target"] = String(flags().get("w58_dan_st", ""))
			st.show.emit("radio", {"who": "dan", "text": "And bring her home in one piece, you hear? The drinks are on me. One of them.", "mission": MID})


func _call_dan() -> void:
	if main.story_ui != null and main.story_ui.dialogue == null:
		GameState.story.show.emit("dialogue", {"id": "dan_end", "mission": MID})


var _amb_t := 0.0


func _part3_step(f: ShipFitting, sp) -> void:
	var g = main.ground
	if g != null and is_instance_valid(g) and not g.story_talk.is_connected(_on_talk):
		g.story_talk.connect(_on_talk)
	var fl := flags()
	match phase:
		"part3":
			if bool(fl.get("w58_job", false)):
				_lend_escort_gear()
				_set_phase("brine")
				_part3_calls()
		"brine":
			if bool(fl.get("w58_ossa", false)):
				_set_phase("convoy")
				if _contract().is_empty():
					_make_contract()
				_part3_calls()
		"convoy":
			var m := _contract()
			if bool(fl.get("w58_retry", false)):
				# shot down: the escort starts again the moment you undock from Dan's store
				if f.docked_at == "" and GameState.active() == f:
					GameState.story.flags.erase("w58_retry")
					_make_contract()
					GameState.story.show.emit("radio", {"who": "ossa", "text": "There you are. Same as before: come alongside, or select my lead and follow, and we go. And this time we all get there.", "mission": MID, "now": true})
					_part3_calls()
				return
			if m.is_empty():
				if not bool(fl.get("w58_escorted", false)):
					# the haulers were lost (or left behind): Ossa tries again from Dan's store
					GameState.story.show.emit("radio", {"who": "ossa", "text": "That's it, they got us. I've got one more old tub at Dan's and I'm loading it now. We go again, and this time you stay close.", "mission": MID, "now": true})
					_make_contract()
					_part3_calls()
				return
			var c: Dictionary = GameState.convoys.find(int(m.get("convoy", -1)))
			if not bool(fl.get("w58_departed", false)) and not c.is_empty() and not bool(c.get("gathering", false)):
				GameState.story.set_flag("w58_departed", true)
				GameState.story.show.emit("radio", {"who": "ossa", "text": "That's all of us. Next stop the gate to Driftwood. Stay close in warp, escort.", "mission": MID, "now": true})
				_part3_calls()
			if bool(fl.get("w58_ambush", false)) and not bool(fl.get("w58_ambush_won", false)):
				_amb_t += get_process_delta_time()
				if _amb_t > 3.0 and not bool(fl.get("w58_ambush_dan", false)):
					GameState.story.set_flag("w58_ambush_dan", true)
					GameState.story.show.emit("radio", {"who": "dan", "text": "Pirates on Ossa's run again? Darling, give them what for! That laser's not for show.", "mission": MID})
				if _amb_t > 22.0 and not bool(fl.get("w58_ambush_ossa", false)):
					GameState.story.set_flag("w58_ambush_ossa", true)
					GameState.story.show.emit("radio", {"who": "ossa", "text": "My shields are going! I can't outrun them in this old tub. Get them off me!", "mission": MID})
				if _amb_t > 2.0 and _ambushers_gone(m):
					GameState.story.set_flag("w58_ambush_won", true)
					GameState.story.show.emit("radio", {"who": "ossa", "text": "That's the last of them. Nice flying, escort. Let's move before their friends show up.", "mission": MID, "now": true})
			if int(m.get("progress", 0)) >= 1 and not bool(fl.get("w58_arrived", false)):
				GameState.story.set_flag("w58_arrived", true)
				_part3_calls()
			if int(m.get("progress", 0)) >= 1 and f.docked_at == String(m["target_station"]) and sp.visible:
				var cr0 := GameState.credits
				var e := GameState.turn_in_mission(m, String(m["target_station"]))
				if e != "":
					return
				GameState.story.set_flag("w58_escorted", true)
				GameState.story.set_flag("w58_paid", GameState.credits - cr0)
				_set_phase("call")
				GameState.story.show.emit("radio", {"who": "ossa", "text": "%s, as promised. Tell Dan the next run's on me. Oh, and your radio's ringing." % GameData.fmt_credits(GameState.credits - cr0), "mission": MID, "now": true})
				get_tree().create_timer(4.0).timeout.connect(_call_dan)
		"call":
			if bool(fl.get("w58_called", false)):
				_set_phase("back")
				_part3_calls()
		"back":
			if f.docked_at == String(fl.get("w58_dan_st", "")) and sp.visible:
				_three_months()
		"maul":
			if bool(fl.get("w58_maul", false)) and main.story_ui.dialogue == null:
				_give_maul()
				_set_phase("crew")
				_crew_tour()
		"crew":
			if tour == null and _crew_started:
				_crew_done()
		"contact":
			if bool(fl.get("w58_contact", false)) and main.story_ui.dialogue == null:
				_set_phase("follow")
				_follow_calls()


## The pirates of the story's ambush: none left (dead or gone).
func _ambushers_gone(m: Dictionary) -> bool:
	var v = main.view
	if v == null or not is_instance_valid(v) or v.traffic == null:
		return false
	var e: Dictionary = v.traffic.convoys.get(int(m.get("convoy", -1)), {})
	if not e.has("ambushers"):
		return false
	for p in e["ambushers"]:
		if v.traffic._alive(p) and not p.is_queued_for_deletion():
			return false
	return true


## Dan explains the drone's controls over its panel (top left) – in the wreck field.
func _drone_steps() -> Array:
	var f := darling()
	var pad: bool = Pad.enabled and Pad.using_pad          # the controller: the drone wheel (◯ held)
	var v = main.view
	return [
		{"key": "drone_panel", "title": "Your drone", "text": "Here we are. Before you start cutting: your drone. Top left, its panel. Launch it: the button, or {key:drone_launch}." if not pad
			else "Here we are. Before you start cutting: your drone. Top left, its panel. On the controller it's all in the drone wheel: hold %s, push the stick to Launch and let go." % Pad.glyph("circle"),
			"task": func(): return v != null and is_instance_valid(v) and v.player != null and not v.drones_of(v.player).is_empty(), "hint": "launch your drone", "allow": ["drone_launch"]},
		{"key": "drone_roles", "title": "Its jobs", "text": "Those are its jobs: combat, mining, repair. It does one at a time, and it does it on its own."},
		{"key": "drone_roles", "title": "Mining", "text": "Mining, of course. Set it to mining." if not pad else "Mining, of course. Set it to mining: the same wheel, %s held, Mining." % Pad.glyph("circle"),
			"task": func(): return f != null and f.drone_role == "mining", "hint": "set the drone to mining"},
		{"key": "drone_modes", "title": "How it works", "text": "And how it goes about it: on Auto it picks rock near you by itself, on Target it cuts what you've locked, and Rest brings it back to your side."},
		{"key": "drone_panel", "title": "Fuel and recall", "text": "Below, its fuel and hull. The fuel cell is sealed: when it's empty the drone comes home, and an empty one's worth less. Recall it before you warp, {key:drone_recall}, or it stays behind."},
	]


func _station_steps() -> Array:
	var sp = station_ui()
	return [
		{"key": "cmdr", "title": "You", "text": "Right, let me show you around. Up there on the left, that's you: your name, your level, what you've got running. Skills and the skill tree live in the Pilot window."},
		{"key": "news", "title": "The news", "text": "Below it the news. Prices, pirates, politics. Worth a glance now and then, even out here."},
		{"key": "ship", "title": "Your ship", "text": "In the middle: your ship. Hull, armour, fuel, cargo and drones at a glance. That's Little Darling, by the way. Be nice to her."},
		{"key": "ship_services", "title": "Ship services", "text": "Under her, everything for the ship herself: fuel, repairs, drones, munitions and the Outfitter. Mine's the only shop in Beyond, so get used to my prices."},
		{"key": "station", "title": "The station", "text": "On the right, the station: who runs it, what it makes, what it wants, and how much money you've got. Right now that's nothing. We'll fix that."},
		{"key": "station_services", "title": "Station services", "text": "Below that, the station's own services: the market, the bar and so on. Not every station has all of them."},
		{"key": "tile_outfitter", "title": "The Outfitter", "text": "Now, let's give her some teeth. Open the Outfitter, there under the ship services.",
			"task": func(): return sp.current_service == "outfitter", "hint": "open the Outfitter"},
	]


func _outfitter_steps() -> Array:
	var sp = station_ui()
	var f := darling()
	return [
		{"key": "of_rail", "title": "Kinds of slots", "text": "On the left, what kind of slot you're looking at: weapons, tools, the core, optional modules, the drone hangar. And your storage here at the station."},
		{"key": "of_slots", "title": "Her slots", "text": "Next to it, her slots of that kind and what's in them. Little Darling has one weapon slot and three tool slots. Small, but honest."},
		{"key": "of_choice", "title": "What fits", "text": "Pick a slot and this big panel shows what fits it: first the kinds of module, then size and quality. Below what you can buy, in green, what's lying in your storage here. That's free."},
		{"key": "of_specs", "title": "Her values", "text": "Down here, her values. Pick something and you see what it changes before you fit it. Saves you a lot of credits, that does."},
		{"key": "of_main", "title": "A mining laser", "text": "I left a mining laser and a pulse laser in your storage. The mining laser first: open the tools, pick a free slot, and take the one from your storage, down in green.",
			"task": func(): return _has_family(f, "tool", "t_mining"), "hint": "fit the mining laser into a tool slot"},
		{"key": "of_main", "title": "A weapon", "text": "Good. Now the pulse laser, into the weapon slot. Out here you want something that bites back.",
			"task": func(): return f.get_module("weapon_0") != "", "hint": "fit the pulse laser into the weapon slot"},
		{"key": "back", "title": "Back", "text": "That's her kitted out. Back to the station window: the Concourse button up there.",
			"task": func(): return sp.current_service == "", "hint": "back to the station window"},
		{"key": "tile_drones", "title": "The Drone Bay", "text": "One more thing: a drone. I've put 2,500 credits in your account. An advance, mind you. Open the Drone Bay.",
			"task": func(): return sp.current_service == "drones", "hint": "open the Drone Bay"},
		{"key": "body", "title": "A drone", "text": "Buy one. She only takes one out at a time, but trust me, it earns its keep. It mines, it fights, it patches you up.",
			"task": func(): return f.drones.size() > 0, "hint": "buy a drone"},
	]
