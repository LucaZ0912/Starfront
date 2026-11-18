extends Node
## Package 58, part 1 (Luz, 18 Nov 2026): working for Dan begins. Dan's deal taken, he gives you Little Darling, the
## smallest KHI ship (a Mogura) in his rust colours: every core module at quality B, the strongest shield that fits.
## Boarding her opens the station window: a guided tour of it (scripts/ui/guided_tour.gd), then of the Outfitter;
## fitting the mining laser and the pulse laser Dan left in storage; back in the station window, a drone bought with
## Dan's advance. The wreck field (part 2), the contact on Brine and the escort (part 3) come next.
## The story flag "w58_phase" keeps where it stands: "board" → "tour1" → "tour2" → "part2".

const GuidedTour = preload("res://scripts/ui/guided_tour.gd")
const TreeData = preload("res://data/skilltree.gd")
const MID := "darling"
const SHIP_NAME := "Little Darling"

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
	phase = String(flags().get("w58_phase", "board"))
	if where == "yes":
		var f := GameState.active()
		give_ship(f.docked_at if f != null else "")
		phase = "board"
		GameState.story.set_flag("w58_phase", phase)
	if phase in ["tour1"]:
		phase = "board"                                     # a tour starts again from its beginning
	elif phase == "tour2":
		phase = "fit"


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


static func _has_family(f: ShipFitting, slot_type: String, fam: String) -> bool:
	for k in f.modules:
		if ShipFitting.slot_type(String(k)) == slot_type and GameData.modules.has(String(f.modules[k])) and String(GameData.modules[String(f.modules[k])].get("family", "")) == fam:
			return true
	return false


func _start_tour(steps: Array) -> void:
	for n in main.get_children():
		if n.get_script() == GuidedTour:
			n.queue_free()                                 # never two tours at once
	tour = GuidedTour.new()
	main.add_child(tour)
	tour.finished.connect(_tour_done)
	tour.start(steps, func(key): return _target(key), main.story_ui)


func _target(key: String) -> Control:
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
			GameState.log_msg("[Story] Package 58, part 2 (the wreck field and the drone controls) comes with the next part.", GameState.COL_WARN)


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
