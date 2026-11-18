extends Node
## Package 58, part 1 (Luz, 18 Nov 2026): working for Dan begins. Dan's deal taken, he gives you Little Darling, the
## smallest KHI ship (a Mogura) in his rust colours: every core module at quality B, the strongest shield that fits.
## Boarding her opens the station window: a guided tour of it (scripts/ui/guided_tour.gd), then of the Outfitter;
## fitting the mining laser and the pulse laser Dan left in storage; back in the station window, a drone bought with
## Dan's advance. The wreck field (part 2), the contact on Brine and the escort (part 3) come next.
## Part 2: undock and warp to the wreck field Dan marks; there he explains the drone's controls (a guided tour over the
## drone panel); twenty units of scrap cut with the mining laser and the drone; home to Dan, who pays 2,000 cr.
## The story flag "w58_phase" keeps where it stands: "board" → "tour1" → "tour2" → "part2" → "drones" → "mine" →
## "home" → "part3".

const GuidedTour = preload("res://scripts/ui/guided_tour.gd")
const TreeData = preload("res://data/skilltree.gd")
const MID := "darling"
const SHIP_NAME := "Little Darling"
const SCRAP_GOAL := 20.0                     # units of scrap for the first run

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
				_set_phase("part3")
				GameState.story.show.emit("dialogue", {"id": "dan_scrap", "mission": MID})
				GameState.log_msg("[Story] Package 58, part 3 (the contact on Brine and the escort) comes with the next part.", GameState.COL_WARN)


static func _has_family(f: ShipFitting, slot_type: String, fam: String) -> bool:
	for k in f.modules:
		if ShipFitting.slot_type(String(k)) == slot_type and GameData.modules.has(String(f.modules[k])) and String(GameData.modules[String(f.modules[k])].get("family", "")) == fam:
			return true
	return false


func _start_tour(steps: Array, flight: bool = false) -> void:
	for n in main.get_children():
		if n.get_script() == GuidedTour:
			n.queue_free()                                 # never two tours at once
	_flight = flight
	tour = GuidedTour.new()
	main.add_child(tour)
	tour.finished.connect(_tour_done)
	tour.start(steps, func(key): return _target(key), main.story_ui)


var _flight := false
var _field := {}


func _target(key: String) -> Control:
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
			st.show.emit("radio", {"who": "dan", "text": "That'll do nicely. Recall the drone, {key:drone_recall}, and bring it all home to me.",
				"mission": MID, "until_flag": "w58_delivered", "hint": "bring the scrap to Dan's Dusty Duty Store"})


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
