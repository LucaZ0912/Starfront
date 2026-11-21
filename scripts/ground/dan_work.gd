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
	if phase == "found":
		_set_phase("report")                             # (a save from before part 6)
	if phase == "brief":
		_after_briefing.call_deferred()                  # a save in the middle of the briefing: it is over
	elif phase == "gear":
		get_tree().create_timer(1.5).timeout.connect(_gear_tour)       # the gear tour from the start again
	if phase in ["report", "gear", "sim", "relay", "strike"]:
		_rook_look()
	if phase == "strike":
		if _sk() == "party":
			_strike_party.call_deferred()                # a save after the Roost: the bar
		else:
			_strike_begin.call_deferred()                # a save in the middle of the strike: from the rendezvous again
	if phase == "after58" and bool(flags().get("w58_drinks", false)):
		_p59_begin.call_deferred()                       # package 59: the morning after
	if phase == "bar59":
		_p59_radio.call_deferred()                       # (Dan's call again: come up to the bar)
	if phase in ["jumped59", "arrive59"]:
		_cit_run.call_deferred("arrive")                 # package 59, part 3: the arrival in the Cluster
	elif phase == "office59":
		_cit_run.call_deferred("office")
	elif phase == "bar59c":
		_cit_run.call_deferred("bar")
	elif phase == "wake59":
		_cit_run.call_deferred("morning")
	if phase in ["farewell", "jump59"]:
		_set_phase("imre")                               # a save in the middle of the farewell: Imre waits again
		for fl9 in ["w59_go", "start_faction"]:
			GameState.story.flags.erase(fl9)
	if phase == "relay":
		_relay_begin.call_deferred()                     # (the site on its world again; a try under way starts fresh)
		for fl7 in ["w58_relay_intro", "w58_coords", "w58_overload"]:
			GameState.story.flags.erase(fl7)
	if phase == "free":
		return                                           # package 59, part 3: the intro is over – the open game, its own rules
	GameState.story_foot_guard = _foot_rescue
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
	if _party8_free:
		_party8_step()                                     # package 58, part 8 (Luz): the party goes on until you leave the bar
	if phase in ["bar59", "imre"]:
		_p59_step()                                        # package 59: the closed bar, Imre, the Threshold outside
	if phase == "free":
		_fern_step()                                       # package 61: Rook's call, the way to Fern, Luz
	var sp = station_ui()
	if sp == null:
		return
	var f := darling()
	if f == null:
		f = GameState.active()                             # (later parts: whatever you fly)
		if f == null or not phase in ["contact", "follow", "listen", "found", "maul", "crew", "report", "brief", "gear", "sim", "relay", "strike"]:
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
		"report":
			var g6 = main.ground
			if g6 != null and is_instance_valid(g6) and not g6.story_talk.is_connected(_on_talk):
				g6.story_talk.connect(_on_talk)
			if bool(flags().get("w58_briefing", false)) and main.story_ui.dialogue == null and main.story_ui._dlg_q.is_empty():
				_briefing()
		"sim":
			var g7 = main.ground
			if g7 != null and is_instance_valid(g7) and not g7.story_talk.is_connected(_on_talk):
				g7.story_talk.connect(_on_talk)
			if bool(flags().get("w58_sim_go", false)) and main.story_ui.dialogue == null and g7 != null and is_instance_valid(g7) and String(g7.level) == "hangar":
				GameState.story.flags.erase("w58_sim_go")
				_sim_start()
			_sim_step()
		"relay":
			_relay_step()
		"strike":
			_strike_step()


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
	if _src == "pilot":
		var pw = main.pilot_window
		var c1 = pw.tour_targets.get(key, null) if pw != null and pw.visible else null
		if c1 != null and is_instance_valid(c1) and (c1 as Control).is_visible_in_tree():
			pw._sc.ensure_control_visible(c1)
			return c1
		return null
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
		"gear":
			_gear_done()
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
	if sid == String(flags().get("w58_dan_st", "")) and phase in ["bar59", "imre"]:
		return _p59_mode()
	if sid == String(flags().get("w58_dan_st", "")) and phase == "farewell":
		return _farewell_mode()
	if phase == "free" and bool(st.get("city", false)) and String(st.get("name", "")) == "Centauria" and bool(flags().get("fern_called", false)):
		# package 61 (Luz): Luz on the plaza of Centauria's Commercial District
		var CG = load("res://scripts/ground/centauria_gen.gd")
		var luz := {"who": "luz", "pos": Vector2(CG.P_CX + CG.P_CW * 0.5 + 4.0, CG.P_TOP + 18.0), "dir": 0, "talk": true}       # (61a: on the central plaza, by the way up from the station)
		if not bool(flags().get("fern_luz", false)):
			luz["marker"] = "!"
		return {"levels": {"zplaza": {"people": [luz]}}}
	if phase == "contact" and sid == String(_waystation().get("id", "-")):
		return {"levels": {"commercial": {"people": [{"who": "silas", "near_obj": "jukebox", "off": Vector2(2.5, 6.6), "spread": 1.0, "dir": 0, "marker": "!"}]}}}
	if phase == "maul" and bool(st.get("city", false)) and String(st.get("body", "")) == _brine_id():
		return {"levels": {"street": {"people": [{"who": "ossa", "near_obj": "lamp_post", "off": Vector2(1.5, 0.8), "near_spawn": Vector2(12.0, 2.0), "spread": 2.0, "dir": 0, "marker": "!"}]}}}
	if sid == String(flags().get("w58_dan_st", "")) and phase in ["rest", "part3", "brine", "convoy", "call", "back", "part4", "maul", "contact", "follow", "listen", "found", "report", "gear", "sim", "relay", "strike", "after58", "jumped59"]:
		var dan := {"who": "dan", "pos": IntroSix.WINDOW, "dir": 1, "talk": true}
		if phase in ["part3", "report"]:
			dan["marker"] = "!"
		var lv := {"commercial": {"people": [dan]}}
		if phase == "report":
			# (Luz) Ossa and Silas wait at the pool table already
			lv["commercial"]["people"] = [dan, {"who": "ossa", "near_obj": "pool_table", "off": Vector2(3.8, 1.2), "dir": 2},
				{"who": "silas", "near_obj": "pool_table", "off": Vector2(-0.8, 1.2), "dir": 3}]
		if phase == "sim":
			lv["hangar"] = {"people": [{"who": "rook", "near_lift": Vector2(2.0, 1.5), "dir": 0, "marker": "!"}]}       # (Luz) Rook and the simulation
		return {"levels": lv}
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
	if phase == "strike" and _sk() in ["rv", "fight"] and (f == darling() or f.ship_name == MAUL_NAME):
		_strike_abort("down")                            # package 58, part 8: shot down at the Roost – again from the rendezvous
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
	if phase == "strike":
		GameState.story.show.emit("dialogue", {"id": "dan_wake_strike", "mission": FIGHT})     # (Luz: the Maul, not Little Darling)
		return
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
func _cards(lines: Array = CARDS) -> void:
	var cl := CanvasLayer.new()
	cl.layer = 45
	cl.process_mode = Node.PROCESS_MODE_ALWAYS
	main.add_child(cl)
	var k := clampf(main.get_viewport().get_visible_rect().size.y / 900.0, 1.0, 2.4)
	var catcher := _CardKeys.new()
	cl.add_child(catcher)
	for i in lines.size():
		var lb := UI.wrap_label(String(lines[i]), int(round((34.0 if i == 0 else 22.0) * k)), Color(0.95, 0.9, 0.8) if i == 0 else Color(0.85, 0.85, 0.95), int(900 * k))
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
			rook["look"] = GameState.story.look_of("rook")
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
	GameState.story.show.emit("radio", {"who": "dan", "text": "Ossa says you've got the Maul, and Rook with her. Good. Now listen: these aren't scrap haulers you're going after. You come back to me in one piece, you hear? I've sent you the contact of a friend in Driftwood. Silas will be expecting you.", "mission": FIGHT})
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
			GameState.story.show.emit("radio", {"who": "dan", "text": "Silas, you old fool, you said quiet! Spacefarer, you keep that old fool breathing, you hear me?", "mission": FIGHT}))


## A light pirate for a wave: one of the small archetype ships, never a heavy Hadrian copy.
func _light_pirate() -> String:
	var A = load("res://data/pirate_archetypes.gd")
	var arch: String = String(A.pick(1.0)[0])
	var pr: Array = A.ARCHETYPES[arch]["presets"]
	return String(pr[randi() % mini(2, pr.size())])


func _listen_done() -> void:
	GameState.story.set_flag("w58_listened", true)
	_set_phase("report")
	_show_bar(false)
	if _fx != null and is_instance_valid(_fx):
		_fx.active = false
	# (Luz) Silas: got them – no, something's wrong; back to Dan, Silas calls once the data makes sense
	var lines := ["HAH! Got you!", "Wait... something's not right here.", "These readings are far too clean.",
		"I need to take a proper look at this first. You did good work out there. Dan didn't exaggerate when he told me about you. Head back to Dan for now. I'll call once I've made sense of the data."]
	for li in lines.size():
		var rd := {"who": "silas", "text": String(lines[li]), "mission": FIGHT}
		if li == 0:
			rd["now"] = true
		GameState.story.show.emit("radio", rd)
	var stf = GameState.story
	if stf.running(FIGHT):
		stf.missions[FIGHT]["target"] = String(flags().get("w58_dan_st", ""))
	var h = _hope
	get_tree().create_timer(8.0 * (0.05 if quick else 1.0)).timeout.connect(func(): _hope_leave(h))


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
			if phase == "report":
				GameState.story.show.emit("dialogue", {"id": "dan_report", "mission": FIGHT})
			elif phase == "rest":
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
		"rook":
			if phase == "sim":
				GameState.story.show.emit("dialogue", {"id": "rook_sim", "mission": FIGHT})
		"imre":
			if phase == "imre":
				GameState.story.show.emit("dialogue", {"id": "imre_talk", "mission": P59})
		"luz":
			if phase == "free":
				_luz_talk()
	if who == "dan" and phase == "bar59" and not _meet_on:
		_p59_meet()
	elif who == "dan" and phase == "imre":
		GameState.story.show.emit("dialogue", {"id": "dan_wait59", "mission": P59})


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


# ---- part 6: the preparation (Luz, 20 Nov 2026)

const PoolFx = preload("res://scripts/ground/pool_fx.gd")
## Ossa's loan for the ground (lent: it goes back after the strike, see part 8): a light combat suit, two weapons,
## the cutting torch, E-Breach spikes, medkits, grenades and a laser drone – all at quality A.
const LENT_GEAR := {"suit": "suit_mil_light:A", "weapons": ["wp_laser_rifle:A", "wp_pistol:A"],
	"belt": [{"id": "tl_cutter:A", "n": 1}, {"id": "cs_breach", "n": 5}, {"id": "cs_medkit", "n": 3}, {"id": "cs_cell", "n": 2}],
	"grenades": [{"id": "gr_frag", "n": 3}, {"id": "gr_smoke", "n": 2}], "drones": ["dr_laser:A"], "features": ["ft_shield:A", "ft_thermo:A"]}
## The simulation's rounds: the foes ("kind@tier") and whether they start unaware (round 2: sneak up on them).
const SIM_ROUNDS := [[["bandit_rifleman@green", "bandit_scrapper@green", "bandit_scrapper@green"], false],
	[["bandit_rifleman@green", "bandit_gunner@green", "bandit_scrapper@green"], true]]
var _pool = null
var _sim_round := -1
var _sim_t := 0.0
var _sim_said := {}
var _briefing_on := false


## Dan's Dusty Duty Store (the station dictionary).
func _dan_station() -> Dictionary:
	return Universe.find_station(Universe.special_system("beyond"), String(flags().get("w58_dan_st", "")))


## The bar emptied for the briefing: Dan, Ossa and Silas round the pool table, the bartender behind the bar.
func _brief_mode() -> Dictionary:
	var people := [{"who": "dan", "near_obj": "pool_table", "off": Vector2(1.0, 3.0), "dir": 1},
		{"who": "ossa", "near_obj": "pool_table", "off": Vector2(3.8, 1.2), "dir": 2},
		{"who": "silas", "near_obj": "pool_table", "off": Vector2(-0.8, 1.2), "dir": 3}]
	return {"quiet": true, "keep_bartender": true, "pool_clear": true, "levels": {"commercial": {"people": people}}}


## Back at Dan's after the Listener: Dan asked about the base – black, then the four of you round the pool table.
func _briefing() -> void:
	if phase != "report" or _briefing_on:
		return
	_briefing_on = true
	_set_phase("brief")
	main.station_panel.close()
	await main.fade(Color(0, 0, 0, 1), 0.8).finished
	if main.ground == null or not is_instance_valid(main.ground):
		main.open_deck()
	var g = main.ground
	if g == null:
		_after_briefing()
		return
	g.story_mode = _brief_mode()
	g.go_level("commercial", "story")
	g.input_enabled = false
	_brief_stage(g)
	main.fade(Color(0, 0, 0, 0), 1.0)
	await _w(1.2)
	GameState.story.show.emit("dialogue", {"id": "briefing", "mission": FIGHT, "no_dim": true})
	await get_tree().process_frame
	var seen := -1
	while main.story_ui.dialogue != null or not main.story_ui._dlg_q.is_empty():
		var ln := int(main.story_ui._dlg.get("line", -1)) if String(main.story_ui._dlg.get("id", "")) == "briefing" else -1
		if ln != seen:
			seen = ln
			_brief_action(g, ln)
		await get_tree().process_frame
	await main.fade(Color(0, 0, 0, 1), 0.8).finished
	if main.ground != null and is_instance_valid(main.ground):
		g = main.ground
		for key in g.story_people:
			var w = g.story_people[key]
			if w != null and is_instance_valid(w):
				w.process_mode = Node.PROCESS_MODE_INHERIT
		g.story_cam = Vector2.INF
		g.story_zoom = 0.0
		_set_phase("gear")
		g.story_mode = ground_mode(g.station)            # (Dan back by the window)
		g._keep_pos = g.pilot.pos
		g.go_level("commercial", "keep")
		g.input_enabled = true
	_pool = null
	_briefing_on = false
	_after_briefing()
	main.fade(Color(0, 0, 0, 0), 0.8)


## Everyone in place round the table; the camera close on it. The walkers and the balls keep moving while the
## dialogue pauses the game.
func _brief_stage(g) -> void:
	var tb := {}
	for o in g.map.objects:
		if String(o.get("kind", "")) == "pool_table":
			tb = o
			break
	if tb.is_empty():
		return
	var T := GroundMap.TILE
	var c := Vector2(float(tb["x"]) + 1.5, float(tb["y"]) + 1.0) * T
	g.pilot.pos = c + Vector2(1.0 * T, 2.4 * T)
	g.pilot.position = g.pilot.pos * GroundMap.SCALE
	g.pilot.dir = 1
	for key in g.story_people:
		var w = g.story_people[key]
		if w != null and is_instance_valid(w):
			w.process_mode = Node.PROCESS_MODE_ALWAYS
			w.stays = true
	_pool = PoolFx.new()
	_pool.setup(tb)
	g._sorted.add_child(_pool)
	g.story_cam = c + Vector2(0, T * 0.8)
	g.story_zoom = 2.3
	g._camera()


## What happens at a line of the briefing: Silas walks round the table, Dan's shot goes wide, Ossa pots one.
func _brief_action(g, ln: int) -> void:
	var T := GroundMap.TILE
	var sil = g.story_people.get("silas", null)
	match ln:
		0:
			if sil != null and is_instance_valid(sil) and _pool != null:
				var tb: Dictionary = _pool.table
				var tl := Vector2(float(tb["x"]), float(tb["y"])) * T
				_walk_round(sil, [tl + Vector2(-0.8 * T, -0.6 * T), tl + Vector2(2.6 * T, -0.9 * T), tl + Vector2(1.5 * T, -0.9 * T)], 0)
		2:
			_shot_first(g, "dan", "", false, 2.4)             # (Luz) Dan to the cue ball's end of the table – and misses
		3:
			_shot_first(g, "ossa", "dan", true, 1.6)          # Ossa takes the place and pots the black


## (Luz) the line about the shot comes after the shot: the dialogue box steps aside while it plays, then the line.
func _shot_first(g, who: String, before: String, sink: bool, roll: float) -> void:
	var lay = main.story_ui._dlg_layer
	if lay != null and is_instance_valid(lay):
		lay.visible = false
		lay.process_mode = Node.PROCESS_MODE_DISABLED
	await _shooter_shot(g, who, before, sink)
	await get_tree().create_timer(roll * (0.3 if quick else 1.0), true).timeout
	if lay != null and is_instance_valid(lay):
		lay.process_mode = Node.PROCESS_MODE_ALWAYS
		lay.visible = true
		var dv = main.story_ui.dialogue
		if dv != null and is_instance_valid(dv):
			dv._shown = 0.0                               # the line types out from the start


## Someone walks to the cue ball's end of the table (the west end), the one before steps back, then the shot.
func _shooter_shot(g, who: String, before: String, sink: bool) -> void:
	if _pool == null or not is_instance_valid(_pool):
		return
	var T := GroundMap.TILE
	var tb: Dictionary = _pool.table
	var tl := Vector2(float(tb["x"]), float(tb["y"])) * T
	var spot := tl + Vector2(-0.9 * T, 1.35 * T)
	var b4 = g.story_people.get(before, null)
	if b4 != null and is_instance_valid(b4):
		_walk_round(b4, [tl + Vector2(0.9 * T, 3.0 * T)])
		await _w(0.5)
	var w = g.story_people.get(who, null)
	if w != null and is_instance_valid(w):
		await _walk_round(w, [spot])
		if w != null and is_instance_valid(w):
			w.dir = 3                                     # facing along the table
	if _pool != null and is_instance_valid(_pool):
		if sink:
			_pool.shot_sink()
		else:
			_pool.shot_miss()


func _walk_round(w, pts: Array, face: int = -1) -> void:
	for p in pts:
		if w == null or not is_instance_valid(w):
			return
		w.goto_to = p
		w.goto_done = false
		var t := 0.0
		while is_instance_valid(w) and not w.goto_done and t < 6.0:
			await get_tree().process_frame
			t += 1.0 / 60.0
	if w != null and is_instance_valid(w) and face >= 0:
		w.dir = face                                    # (Silas: at the head of the table, facing the rest)


## The briefing over: Ossa's gear lent, and a look at it in the Pilot window (Gear) with Ossa on the radio.
func _after_briefing() -> void:
	_set_phase("gear")
	var st = GameState.story
	st.set_flag("w58_briefing", true)
	_lend_ground_gear()
	if st.running(FIGHT):
		st.missions[FIGHT]["target"] = ""
	GameState.story.show.emit("radio", {"who": "ossa", "text": "One more thing before you go down to the hangar. I've put some gear in your locker. Let's look it over together.", "mission": FIGHT, "now": true})
	get_tree().create_timer(2.5 * (0.05 if quick else 1.0)).timeout.connect(_gear_tour)


## Your own ground gear is kept (it comes back after the strike); Ossa's goes on.
func _lend_ground_gear() -> void:
	var st = GameState.story
	var g = GameState.gear
	if not bool(flags().get("w58_gear_lent", false)):
		var own: Dictionary = g.to_dict()
		for k in ["inv", "lockers", "health", "energy", "oxygen", "ammo", "shield", "armor", "team", "helmet"]:
			own.erase(k)
		st.set_flag("w58_gear_own", own)
		st.set_flag("w58_gear_lent", true)
	g.suit = String(LENT_GEAR["suit"])
	g._fit_slots()
	for key in ["weapons", "belt", "grenades", "drones", "features"]:
		var arr: Array = g.get(key)
		var want: Array = LENT_GEAR[key]
		for i in arr.size():
			var it = want[i] if i < want.size() else null
			if it == null:
				arr[i] = {} if key in ["belt", "grenades"] else ""
			else:
				arr[i] = (it as Dictionary).duplicate() if it is Dictionary else String(it)
	g.refill()
	# Rook's look is the story's (the portrait on the radio)
	_rook_look()


## Rook Varga aboard the Maul: the crew member's look and name as the story has them.
func _rook_look() -> void:
	for f in GameState.fleet:
		for m in f.crew_members():
			if String(m.get("name", "")) == "Rook Varga":
				m["look"] = GameState.story.look_of("rook")


func _rook() -> Dictionary:
	var f := GameState.active()
	if f == null:
		return {}
	for m in f.crew_members():
		if String(m.get("name", "")) == "Rook Varga":
			return m
	return {}


## Ossa's tour over the Gear page: the suit, its protection, the weapons, grenades, belt, the drone, the team.
func _gear_tour() -> void:
	if phase != "gear" or main == null:
		return
	main.station_panel.close()
	main.ship_menu.close()
	main.pilot_window.open(main.pilot_window.TAB_GEAR)
	await get_tree().process_frame
	_start_tour(_gear_steps(), false, "pilot")


func _gear_steps() -> Array:
	var rid := int(_rook().get("id", -1))
	return [
		{"key": "pw_suit", "who": "ossa", "title": "The suit", "text": "Your Pilot window, the Gear page. That's what I'm lending you: a Light Combat Suit, quality A. Like a ship's hull, the suit decides the rest: how many weapons, grenades, belt places and features you can carry."},
		{"key": "pw_protect", "who": "ossa", "title": "Protection", "text": "Down here, what it keeps out. The relay sits on a cold world with air you can't breathe. Where the suit can't keep up, your energy goes first, then your health. Watch these numbers before you land somewhere new."},
		{"key": "pw_weapons", "who": "ossa", "title": "Weapons", "text": "Two weapons: a laser rifle for range, a pistol for close work. Lock on to someone and the weapon in your hands fires by itself; how well it hits is your Firearms skill. {key:foot_swap} takes the other one in hand."},
		{"key": "pw_grenades", "who": "ossa", "title": "Grenades", "text": "Frag and smoke. {key:foot_grenade}: a tap picks the next one, held it throws. Smoke hides you from their sights; frag gets them out from behind cover."},
		{"key": "pw_belt", "who": "ossa", "title": "The belt", "text": "The belt, on the number keys: the cutting torch for welded hatches, E-Breach spikes for their terminals, medkits and energy cells. Each spike is used up, so don't waste them."},
		{"key": "pw_drones", "who": "ossa", "title": "The drone", "text": "And a laser drone. It rides on your back until you send it up with {key:foot_drone}. Then it flies with you and fights at your side, and on the same key it comes back."},
		{"key": "pw_team", "who": "ossa", "title": "Ground team", "text": "Up here, your ground team: the crew of the ship you fly who go along on foot. Rook's going with you."},
		{"key": "pw_member_%d" % rid, "who": "ossa", "title": "Rook", "text": "Take Rook along: click Rook's name.", "hint": "add Rook to your ground team",
			"task": func(): return GameState.gear.team.has(rid)},
		{"key": "pw_team", "who": "ossa", "title": "Orders", "text": "On the ground {key:foot_team} talks to your team: a tap picks who, held you get the orders. Follow, hold this spot, attack my target. If Rook goes down, get over there and hold E. Now off to the hangar: Rook's waiting with the simulation."},
	]


## The gear tour done: to Rook in Dan's hangar.
func _gear_done() -> void:
	GameState.story.set_flag("w58_gear", true)
	_set_phase("sim")
	var st = GameState.story
	if st.running(FIGHT):
		st.missions[FIGHT]["target"] = String(flags().get("w58_dan_st", ""))
	main.pilot_window.close()
	var g = main.ground
	if g != null and is_instance_valid(g):
		g.story_mode = ground_mode(g.station)            # Rook waits in the hangar now


## Talking to Rook in the hangar and saying go: the hangar becomes the simulation.
func _sim_start() -> void:
	var g = main.ground
	if g == null or not is_instance_valid(g):
		return
	await main.fade(Color(0, 0, 0, 1), 0.6).finished
	_sim_round = 0
	_sim_stage = "fight"
	_sim_said = {}
	_sim_t = 0.0
	g.sim_lost = false
	g.sim_foes = (SIM_ROUNDS[0][0] as Array).duplicate()
	g.go_level("sim", "sim")
	GameState.gear.refill()
	main.fade(Color(0, 0, 0, 0), 0.8)
	_rook_says("Welcome to the simulation. First things first: {key:foot_target} locks on to one of them, and your weapon fires by itself. Get behind that low cover: it takes most of what they throw at you.")


func _rook_says(text: String) -> void:
	GameState.story.show.emit("radio", {"who": "rook", "text": text, "mission": FIGHT, "now": true})


## The simulation (Luz): round 1 a fight, Rook explaining as you go; round 2 sneaking – back to the marker on the
## west side, then guards appear who do not know you are there, and you get to the east side unseen; then Rook asks
## whether you want more (three foes at a time, as often as you like). Shot down: that part starts again.
var _sim_stage := ""                    # "fight", "to_start", "sneak", "ask", "free"
var _sim_mark = null                    # the marker on the ground (where to go)
const SNEAK_GUARDS := [[Vector2(20, 8), PI * 0.5], [Vector2(27, 17), -PI * 0.5], [Vector2(34, 11), PI]]    # tile, where it looks


func _sim_step() -> void:
	var g = main.ground
	if g == null or not is_instance_valid(g) or String(g.level) != "sim" or g.combat == null:
		return
	var dt := get_process_delta_time()
	_sim_t += dt
	var q := 0.05 if quick else 1.0
	if g.sim_lost:
		g.sim_lost = false
		_rook_says("And you're dead. Well, you would be. Again, and this time keep your head down.")
		if _sim_stage == "sneak":
			_sim_to_start(g, "")
		else:
			_sim_restart(g)
		return
	if _sim_stage == "" or _sim_stage == "fight":
		_sim_stage = "fight"
		if _sim_t > 8.0 * q and not _sim_said.has("dodge"):
			_sim_said["dodge"] = true
			_rook_says("Too hot? {key:foot_dodge} throws you out of the way: no shot hits you mid-jump. And send your drone up: {key:foot_drone}.")
		if _sim_t > 18.0 * q and not _sim_said.has("team"):
			_sim_said["team"] = true
			_rook_says("I've got your back. Hold {key:foot_team} for the orders wheel: follow, hold, attack your target.")
		if g.combat.alive().is_empty() and _sim_t > 1.0 * q:
			_sim_round = 1
			_sim_to_start(g, "Not bad for three hundred years. Round two is a quiet one. Go back to the start, the marker on the west side.")
	elif _sim_stage == "to_start":
		if g.pilot.pos.distance_to(g.map.spawn) < GroundMap.TILE * 1.6:
			_sim_sneak(g)
	elif _sim_stage == "sneak":
		var seen := false
		for f in g.combat.alive():
			seen = seen or bool(f.get("aware", false))
		var east := Vector2(float(g.map.w) - 3.5, float(g.map.h) * 0.5) * GroundMap.TILE
		if seen:
			_sim_to_start(g, "They saw you. Back to the start and again: stay out of the red, move when they look away.")
		elif g.pilot.pos.x > east.x - GroundMap.TILE * 1.5 or g.combat.alive().is_empty():
			_sim_ask(g, "Clean. Not one of them knew you were there. That's how we do the relay, if we can.")
	elif _sim_stage == "free":
		if g.combat.alive().is_empty() and _sim_t > 1.0 * q:
			_sim_ask(g, "Three down. Not bad.")
	elif _sim_stage == "ask":
		var fl := flags()
		if main.story_ui.dialogue == null and main.story_ui._dlg_q.is_empty():
			if bool(fl.get("w58_sim_more", false)):
				GameState.story.flags.erase("w58_sim_more")
				_sim_stage = "free"
				_sim_t = 0.0
				GameState.gear.refill()
				_sim_clear(g)
				_sim_spawn(g, 0)
				_rook_says("Three more, coming up. Try whatever you like.")
			elif bool(fl.get("w58_sim_end", false)):
				GameState.story.flags.erase("w58_sim_end")
				_sim_mark_at(g, Vector2.INF)
				_sim_done()


## Back to the marker on the west side: the guards (if any) gone, Rook's word, the marker on.
func _sim_to_start(g, said: String) -> void:
	_sim_stage = "to_start"
	_sim_clear(g)
	GameState.gear.refill()
	if said != "":
		_rook_says(said)
	_sim_mark_at(g, g.map.spawn)


## At the start: the guards appear, unaware of you, each looking its way; the marker on the far side.
func _sim_sneak(g) -> void:
	_sim_stage = "sneak"
	_sim_t = 0.0
	# the team at your side (a member left standing out in the open would give you away at once)
	var k := 0
	for a in g.combat.allies:
		var aw: Walker = a["w"]
		if is_instance_valid(aw):
			aw.pos = g.pilot.pos + Vector2(-GroundMap.TILE * 1.2, GroundMap.TILE * (1.0 if k % 2 == 0 else -1.0))
			aw.position = aw.pos * GroundMap.SCALE
		k += 1
	if not g.combat.sneaking:
		g.combat.toggle_sneak()                          # (Luz: the round starts low, you and the team)
	var kinds: Array = SIM_ROUNDS[1][0]
	for i in SNEAK_GUARDS.size():
		var fe: Array = GroundCombat.FoeData.parse(String(kinds[i % kinds.size()]))
		var nf: Dictionary = g.combat.spawn(String(fe[0]), (SNEAK_GUARDS[i][0] as Vector2) * GroundMap.TILE, "", String(fe[1]))
		g.holo_foe(nf)
		nf["look0"] = float(SNEAK_GUARDS[i][1])
	_sim_mark_at(g, Vector2(float(g.map.w) - 3.5, float(g.map.h) * 0.5) * GroundMap.TILE)
	_rook_says("Three guards, and they don't know we're here. Get to the marker on the east side without being seen. {key:foot_sneak} to sneak: then you see where each of them is looking, the red cones. Stay out of them, move when they look away. {key:foot_tactics} still shows your own lines of sight. Hit one from behind and it counts twice.")


## The end of a round: Rook asks if you want more (three foes, as often as you like) or are done.
func _sim_ask(g, said: String) -> void:
	_sim_stage = "ask"
	_sim_mark_at(g, Vector2.INF)
	_sim_clear(g)
	GameState.story.flags.erase("w58_sim_more")
	GameState.story.flags.erase("w58_sim_end")
	if said != "":
		_rook_says(said)
	get_tree().create_timer(3.0 * (0.05 if quick else 1.0)).timeout.connect(func():
		if _sim_stage == "ask":
			GameState.story.show.emit("dialogue", {"id": "rook_more", "mission": FIGHT}))


func _sim_clear(g) -> void:
	for f0 in g.combat.foes:
		if is_instance_valid(f0["w"]):
			(f0["w"] as Walker).queue_free()
	g.combat.foes.clear()
	g.combat.locks.clear()
	g.combat.active = null


## The marker on the ground (INF: none): a gold ring, pulsing, with an arrow over it.
func _sim_mark_at(g, at: Vector2) -> void:
	if _sim_mark != null and is_instance_valid(_sim_mark):
		_sim_mark.queue_free()
	_sim_mark = null
	if at == Vector2.INF:
		return
	_sim_mark = _SimMark.new()
	_sim_mark.at = at
	g._world.add_child(_sim_mark)


class _SimMark extends Node2D:
	var at := Vector2.ZERO
	var _t := 0.0

	func _process(dt: float) -> void:
		_t += dt
		queue_redraw()

	func _draw() -> void:
		var p := at * GroundMap.SCALE
		var k := 0.5 + 0.5 * sin(_t * 4.0)
		var gold := Color(1.0, 0.82, 0.29)
		draw_set_transform(p, 0.0, Vector2(1.0, 0.45))
		draw_circle(Vector2.ZERO, 70.0, Color(gold, 0.12 + 0.1 * k))
		draw_arc(Vector2.ZERO, 70.0, 0.0, TAU, 48, Color(gold, 0.9), 5.0)
		draw_arc(Vector2.ZERO, 52.0 + 10.0 * k, 0.0, TAU, 48, Color(gold, 0.5), 3.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var y := p.y - 150.0 - 12.0 * k
		draw_colored_polygon(PackedVector2Array([Vector2(p.x - 18, y), Vector2(p.x + 18, y), Vector2(p.x, y + 26)]), gold)


func _sim_spawn(g, r: int) -> void:
	var kinds: Array = SIM_ROUNDS[r][0]
	for i in kinds.size():
		var fe: Array = GroundCombat.FoeData.parse(String(kinds[i]))
		var at: Vector2 = g.map.foe_spawns[(i + r * 3) % g.map.foe_spawns.size()]
		var nf: Dictionary = g.combat.spawn(String(fe[0]), at, "", String(fe[1]))
		g.holo_foe(nf)
		nf["aware"] = true


func _sim_restart(g) -> void:
	_sim_clear(g)
	GameState.gear.refill()
	g.pilot.pos = g.map.spawn
	g.pilot.position = g.pilot.pos * GroundMap.SCALE
	_sim_t = 0.0
	_sim_spawn(g, 0)


func _sim_done() -> void:
	_set_phase("relay")
	GameState.story.set_flag("w58_sim", true)
	_rook_says("That'll do. You're ready, or as ready as anyone gets.")
	var g = main.ground
	await _w(3.0)
	await main.fade(Color(0, 0, 0, 1), 0.6).finished
	if g != null and is_instance_valid(g):
		GameState.gear.refill()
		g.story_mode = ground_mode(g.station)            # (Luz) Rook comes along now: no longer waiting by the lift
		g.go_level("hangar", "stairs")
	main.fade(Color(0, 0, 0, 0), 0.8)
	_relay_begin()


# ---- part 7: the relay (Luz, 20 Nov 2026)

const RELAY_PAY := 2500
var _relay_intro_on := false
var _relay_said := {}
var _overload_t := -1.0                 # the transmitter's countdown once overloaded (s; < 0: not yet)
var _ol_layer: CanvasLayer = null
var _ol_label: Label = null
var _ol_fx = null                       # the lightning over the wall of computers while it overloads


## The world the relay stands on: a cold one in Hollow (ice first), landable, not a giant.
static func _relay_body() -> Dictionary:
	var sid := Universe.special_system("hollow")
	var L: Dictionary = Universe.get_layout(sid)
	var best := {}
	for b in L["planets"] + L.get("moons", []):
		if not Universe.landable(b) or Universe.is_giant(b):
			continue
		if String(b.get("type", "")) in ["ice", "moon_ice"]:
			return b
		if best.is_empty():
			best = b
	return best


## The relay's site on that world (a new id after each failed try: the place is fresh again).
func _relay_site() -> Dictionary:
	var b := _relay_body()
	var n := int(flags().get("w58_relay_try", 0))
	return {"id": "story_relay_%d" % n, "name": "Relay Station", "kind": "pirate", "poi": true, "theme": "relay", "seed": 58007,
		"danger": "yellow", "lon": 0.35, "lat": 0.25, "system": Universe.special_system("hollow"), "body": String(b.get("id", "")), "story": "relay"}


## On to the relay: its site on the map of its world, the marker on that world, Rook and Silas on the radio.
func _relay_begin() -> void:
	var st = GameState.story
	st.set_flag("w58_relay_site", _relay_site())
	if st.running(FIGHT):
		st.missions[FIGHT]["target"] = String(_relay_body().get("id", ""))
		st.changed.emit()
	var rk := _rook()
	if not rk.is_empty() and not GameState.gear.team.has(int(rk.get("id", -1))):
		GameState.gear.team_toggle(rk)                    # Rook goes down with you
	st.show.emit("radio", {"who": "silas", "text": "I've marked the relay for you: on %s, in Hollow. Land the drone a good way off and go in on foot. I'll be in orbit, listening." % String(_relay_body().get("name", "a cold world")),
		"mission": FIGHT})


func _relay_step() -> void:
	var g = main.ground
	var st = GameState.story
	var fl := flags()
	var on_site: bool = g != null and is_instance_valid(g) and String(g._site.get("story", "")) == "relay"
	if on_site and String(g.level) == "landing" and not bool(fl.get("w58_relay_intro", false)) and not _relay_intro_on and g.combat != null:
		_relay_intro(g)
		return
	if on_site:
		if String(g.level) == "dungeon" and int(g.depth) == 0 and _say_once("in"):
			_rook_says("Inside. Their data core should be at the bottom. Watch for cameras and tripwires: sneak over a wire ({key:foot_sneak}) or cut it ({key:interact}). One alarm and the whole place wakes up. And look for the air shafts: cut a grille open and we crawl right past them.")
		if String(g.level) == "dungeon" and int(g.depth) == 1 and _say_once("down"):
			st.show.emit("radio", {"who": "silas", "text": "The relay room's on your level, I can hear it humming. Hack their data core first, then the transmitter. Not the other way round.", "mission": FIGHT})
		if bool(g._site.get("alarmed", false)) and not bool(fl.get("w58_overload", false)) and _say_once("alarm"):
			st.show.emit("radio", {"who": "silas", "text": "They know you're in there! Move, before the whole nest comes down on you!", "mission": FIGHT, "now": true})
		if bool(fl.get("w58_coords", false)) and _say_once("coords"):
			st.show.emit("radio", {"who": "silas", "text": "That's it, that's their base! I've got the coordinates. Now overload the transmitter and get out of there.", "mission": FIGHT, "now": true})
		if bool(fl.get("w58_overload", false)) and _say_once("overload"):
			_overload_t = 45.0 * (0.1 if quick else 1.0)
			_rook_says("That's our cue. Back to the drone, now!")
			_reinforce(g, g.map.spawn, 3)
			_show_overload(true)
		if bool(fl.get("w58_overload", false)) and String(g.level) == "landing" and _say_once("out"):
			_reinforce(g, (g.map.get_meta("door_front", g.map.spawn) as Vector2) + Vector2(0, GroundMap.TILE * 3), 3)
			st.show.emit("radio", {"who": "silas", "text": "More of them coming round the compound! Run for the drone!", "mission": FIGHT, "now": true})
	if _overload_t > 0.0 and on_site and String(g.level) == "dungeon" and int(g.depth) == 1:
		_overload_fx(g)                                  # (Luz) lightning over the computers
	if _overload_t > 0.0:
		_overload_t -= get_process_delta_time()
		if _ol_label != null and is_instance_valid(_ol_label):
			_ol_label.text = "TRANSMITTER OVERLOAD  ·  %d s" % int(ceil(maxf(_overload_t, 0.0)))
		if _overload_t <= 0.0:
			_overload_t = 0.0
			_show_overload(false)
			if g != null and is_instance_valid(g):
				g._shake = maxf(g._shake, 0.6)
			Audio.play("explosion_large", "the transmitter blows", 0.0)
			st.show.emit("radio", {"who": "silas", "text": "And there goes their radio. Beautiful. Every pirate out there just went deaf.", "mission": FIGHT})
	# up and away with the coordinates: done
	var f := GameState.active()
	if bool(fl.get("w58_overload", false)) and not on_site and f != null and not f.docked_at.begins_with("land:") and (g == null or not is_instance_valid(g)):
		_relay_done()


func _say_once(key: String) -> bool:
	if _relay_said.has(key):
		return false
	_relay_said[key] = true
	return true


## Pirates who come running, aware of you, round a point.
func _reinforce(g, at: Vector2, n: int) -> void:
	if g == null or g.combat == null:
		return
	var kinds := ["pirate_raider", "pirate_gunner", "pirate_raider"]
	for i in n:
		var p: Vector2 = g.combat._free_near(at + Vector2(randf_range(-40, 40), randf_range(-20, 20)))
		if p == Vector2.INF:
			continue
		var nf: Dictionary = g.combat.spawn(String(kinds[i % kinds.size()]), p, "", "green")
		g.combat._wake(nf)


func _show_overload(on: bool) -> void:
	if not on and _ol_fx != null and is_instance_valid(_ol_fx):
		_ol_fx.queue_free()                              # (the lightning ends with the countdown)
		_ol_fx = null
	if not on:
		if _ol_layer != null and is_instance_valid(_ol_layer):
			_ol_layer.queue_free()
		_ol_layer = null
		return
	_ol_layer = CanvasLayer.new()
	_ol_layer.layer = 11
	main.add_child(_ol_layer)
	var k := clampf(main.get_viewport().get_visible_rect().size.y / 900.0, 1.0, 2.4)
	var p := UI.neon_panel(Color(1.0, 0.3, 0.25, 0.9), Color(0.08, 0.02, 0.02, 0.92), 2)
	p.set_anchors_preset(Control.PRESET_CENTER_TOP)
	p.position = Vector2(-170 * k, 200 * k)
	p.custom_minimum_size = Vector2(340 * k, 0)
	_ol_layer.add_child(p)
	_ol_label = UI.label("TRANSMITTER OVERLOAD", int(16 * k), Color(1.0, 0.45, 0.35))
	_ol_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(_ol_label)


## (Luz) the wall of computers overloading: lightning jumping across it, sparks, the screen flickering – wilder as
## the countdown runs down.
func _overload_fx(g) -> void:
	if _ol_fx != null and is_instance_valid(_ol_fx) and _ol_fx.get_parent() == g._world:
		_ol_fx.k = 1.0 - clampf(_overload_t / (45.0 * (0.1 if quick else 1.0)), 0.0, 1.0)
		return
	var cw := {}
	for o in g.map.objects:
		if String(o.get("kind", "")) == "computer_wall":
			cw = o
	if cw.is_empty():
		return
	var T := GroundMap.TILE
	_ol_fx = _OverloadFx.new()
	_ol_fx.rect = Rect2(Vector2(float(cw["x"]) * T, float(cw["y"]) * T - 40.0), Vector2(float(cw.get("w", 6)) * T, float(cw.get("h", 2)) * T + 40.0))
	_ol_fx.combat = g.combat
	_ol_fx.z_index = 30
	g._world.add_child(_ol_fx)


class _OverloadFx extends Node2D:
	var rect := Rect2()                 # art px: the wall's face, from its top to its foot
	var k := 0.0                        # 0 … 1: how far the overload has gone
	var combat = null
	var _bolts: Array = []              # {pts, t, life}
	var _next := 0.0
	var _t := 0.0
	var _flash := 0.0

	func _process(dt: float) -> void:
		_t += dt
		_next -= dt
		_flash = maxf(0.0, _flash - dt)
		if _next <= 0.0:
			_next = lerpf(0.18, 0.04, k) * randf_range(0.6, 1.4)
			for n in (2 + int(k * 4.0)):
				_bolt()
		for b in _bolts:
			b["t"] = float(b["t"]) + dt
		_bolts = _bolts.filter(func(b): return float(b["t"]) < float(b["life"]))
		queue_redraw()

	func _bolt() -> void:
		var a := rect.position + Vector2(randf() * rect.size.x, randf_range(0.05, 0.7) * rect.size.y)
		var b: Vector2
		if randf() < 0.3 + 0.3 * k:
			b = Vector2(a.x + randf_range(-30.0, 30.0), rect.end.y + randf_range(4.0, 26.0 + 30.0 * k))     # down to the floor
		else:
			b = a + Vector2(randf_range(-1.0, 1.0) * lerpf(40.0, 120.0, k), randf_range(-16.0, 26.0))
			b.x = clampf(b.x, rect.position.x, rect.end.x)
		var pts := PackedVector2Array([a])
		var n := 9
		for i in range(1, n):
			var q := a.lerp(b, float(i) / n) + (b - a).orthogonal().normalized() * randf_range(-10.0, 10.0)
			pts.append(q)
		pts.append(b)
		_bolts.append({"pts": pts, "t": 0.0, "life": randf_range(0.12, 0.3)})
		if randf() < 0.35:
			_flash = 0.07
		if combat != null and is_instance_valid(combat) and randf() < 0.6:
			for i2 in 3:
				combat.sparks.append({"pos": b, "vel": Vector2(randf_range(-70, 70), randf_range(-90, 10)), "t": 0.0, "col": Color(0.6, 0.9, 1.0)})
		if randf() < 0.25 + 0.3 * k:
			Audio.play("shield_down", "overload crackle", -16.0 + 6.0 * k)

	func _draw() -> void:
		var S := GroundMap.SCALE
		if _flash > 0.0:
			draw_rect(Rect2((rect.position - Vector2(30, 0)) * S, (rect.size + Vector2(60, 60)) * S), Color(0.75, 0.9, 1.0, 0.18))
		# the whole face pulses red as it builds up
		draw_rect(Rect2(rect.position * S, rect.size * S), Color(1.0, 0.25, 0.15, (0.05 + 0.12 * k) * (0.5 + 0.5 * sin(_t * (6.0 + 10.0 * k)))))
		for b in _bolts:
			var al := 1.0 - float(b["t"]) / float(b["life"])
			var sp := PackedVector2Array()
			for p in (b["pts"] as PackedVector2Array):
				sp.append(p * S)
			draw_polyline(sp, Color(0.35, 0.7, 1.0, 0.3 * al), 18.0)
			draw_polyline(sp, Color(0.55, 0.85, 1.0, 0.6 * al), 8.0)
			draw_polyline(sp, Color(0.95, 0.98, 1.0, al), 3.0)
			draw_circle(sp[sp.size() - 1], 10.0 * al, Color(0.8, 0.95, 1.0, 0.6 * al))


## (Luz) the landing: you stay in the drone, Rook says to wait. Two guards come round the drone to the ramp; Rook walks
## down to them, talks them into coming close and shocks them both; then you come out and go on.
func _relay_intro(g) -> void:
	_relay_intro_on = true
	GameState.story.set_flag("w58_relay_intro", true)
	g.input_enabled = false
	var T := GroundMap.TILE
	var pc: Vector2 = g.map.get_meta("pad_c", g.map.spawn)
	var foot: Vector2 = g.map.spawn                       # at the foot of the ramp
	var inside: Vector2 = foot + Vector2(0, -T * 1.6)       # up the ramp, in the drone
	await get_tree().process_frame
	# (Luz: you and Rook were out at once) the drone comes down first and opens its ramp; then the scene takes over
	# before you walk down it – and Rook, who only comes along with the fight's first step, is made now
	var tw := 0.0
	while is_instance_valid(g) and g._touch >= 0.0 and g._touch < g.TOUCH_TIME + g.HATCH_TIME and tw < 8.0:
		tw += get_process_delta_time()
		await get_tree().process_frame
	if not is_instance_valid(g):
		_relay_intro_on = false
		return
	g._touch = -1.0
	g._hatch = 1.0
	g.pilot.moving = false
	if not g.combat._team_made:
		g.combat._team_made = true
		g.combat.spawn_team()
	var rook_a: Dictionary = {}
	for a in g.combat.allies:
		rook_a = a
	var rook_w = rook_a.get("w", null)
	var order0 := String(rook_a.get("order", "follow"))
	if not rook_a.is_empty():
		rook_a["order"] = "hold"                          # (the scene moves Rook, not the orders)
		rook_a["tgt"] = null
	g.combat.frozen = true                                # (the two guards are the scene's: nobody shoots, nobody wakes)
	g.combat.active = null
	g.combat.locks.clear()
	# you and Rook in the drone: not seen yet
	g.pilot.pos = inside
	g.pilot.position = g.pilot.pos * GroundMap.SCALE
	g.pilot.dir = 1
	g.pilot.visible = false
	if rook_w != null and is_instance_valid(rook_w):
		rook_w.pos = inside
		rook_w.position = rook_w.pos * GroundMap.SCALE
		rook_w.visible = false
	g.story_cam = pc + Vector2(0, T * 1.2)               # (the drone and the ramp below it)
	g.story_zoom = 1.25
	g._camera()
	var say := func(w, text: String, secs: float):
		if w != null and is_instance_valid(w):
			w.bubble = text
			w.bubble_t = secs * (0.1 if quick else 1.0)
	GameState.story.show.emit("radio", {"who": "rook", "text": "Wait. Two of them, coming this way. Stay inside, I'll handle this.", "mission": FIGHT, "now": true})
	# two guards from the compound, round the drone, one each side, to the ramp
	var pad: Rect2 = g.map.pad_rects[0] if not g.map.pad_rects.is_empty() else Rect2(pc - Vector2(T * 6, T * 5), Vector2(T * 12, T * 10))
	var guards: Array = []
	var routes: Array = []
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		var x_side := pad.position.x + T * 0.8 if i == 0 else pad.end.x - T * 0.8
		var nf: Dictionary = g.combat.spawn("pirate_raider", pc + Vector2(side * T * 1.5, -T * 16.0), "", "green")
		nf["passive"] = true
		nf["holo"] = true                                 # (nothing to loot from these two: they only sleep)
		guards.append(nf)
		routes.append([Vector2(x_side, pad.position.y - T * 0.5), Vector2(x_side, foot.y + T * 0.8),
			foot + Vector2(side * T * 1.7, T * 0.9)])
	await _w(1.2)
	var g0 = guards[0]["w"]
	var g1 = guards[1]["w"]
	say.call(g0, "Nobody said anything about a drop today.", 3.0)
	if not await _intro_walk(g, guards.map(func(nf): return nf["w"]), routes, 55.0):
		return
	if not is_instance_valid(g0) or not is_instance_valid(g1):
		_relay_intro_on = false                           # (gone meanwhile: you go on at once)
		g.combat.frozen = false
		g.pilot.visible = true
		if rook_w != null and is_instance_valid(rook_w):
			rook_w.visible = true
		g.story_cam = Vector2.INF
		g.story_zoom = 0.0
		g.input_enabled = true
		return
	g0.dir = 1                                        # (up the ramp)
	g1.dir = 1
	say.call(g1, "Check the hold. I'll call it in.", 2.4)
	await _w(2.2)
	# Rook comes down the ramp, hands up
	if rook_w != null and is_instance_valid(rook_w):
		rook_w.visible = true
		say.call(rook_w, "Easy, easy! Don't shoot the delivery.", 2.6)
		if not await _intro_walk(g, [rook_w], [[foot + Vector2(0, T * 0.2)]], 70.0):
			return
		rook_w.dir = 0                                # (down to them)
	await _w(2.0)
	say.call(g0, "Delivery? What delivery?", 2.2)
	await _w(2.2)
	say.call(rook_w, "Power cells for your transmitter. The boss ordered them. Big, loud, bad temper?", 3.4)
	await _w(3.4)
	say.call(g1, "The boss never orders anything. The boss takes things.", 3.0)
	await _w(3.0)
	say.call(rook_w, "Well, today the boss pays. Somebody has to sign. You, right here.", 3.2)
	await _w(2.4)
	# the one by the radio steps up to sign
	if not await _intro_walk(g, [g1], [[foot + Vector2(T * 0.75, T * 0.7)]], 40.0):
		return
	say.call(g1, "Sign with wh...", 1.2)
	await _w(0.6)
	_intro_zap(g, guards[1])
	await _w(0.5)
	say.call(g0, "Hey!", 1.0)
	if not await _intro_walk(g, [rook_w], [[foot + Vector2(-T * 0.9, T * 0.8)]], 140.0):
		return
	_intro_zap(g, guards[0])
	await _w(1.0)
	say.call(rook_w, "Sleep tight.", 2.0)
	await _w(2.0)
	if rook_w != null and is_instance_valid(rook_w):
		rook_w.dir = 1                                # (up to the drone)
	say.call(rook_w, "Clear. You can come out now.", 2.4)
	await _w(1.6)
	if not is_instance_valid(g):
		_relay_intro_on = false
		return
	# you come down the ramp
	g.pilot.visible = true
	if not await _intro_walk(g, [g.pilot], [[foot + Vector2(T * 0.3, T * 0.6)]], 70.0):
		return
	g.pilot.dir = 0
	await _w(0.6)
	_relay_intro_on = false
	if not is_instance_valid(g):
		return
	if not rook_a.is_empty():
		rook_a["order"] = order0
	g.combat.frozen = false
	g.story_cam = Vector2.INF
	g.story_zoom = 0.0
	g.input_enabled = true
	_rook_says("Shock baton. They'll wake up with a headache and no idea who we were. The compound's north. Quiet is better, but it's your call.")
	GameState.story.show.emit("radio", {"who": "silas", "text": "I'm listening from orbit. The gate has a turret over it, and a terminal beside it if you've got a spike to spare. Round the east side there's a maintenance hatch, welded shut: your torch will cut it. Quieter.", "mission": FIGHT})


## The scene's walkers along their points, all at once (false: the ground closed meanwhile).
func _intro_walk(g, ws: Array, routes: Array, speed: float) -> bool:
	if is_instance_valid(g) and g.combat != null:
		g.combat.frozen = true
	var idx: Array = []
	for i in ws.size():
		idx.append(0)
	var t := 0.0
	while t < 14.0:
		if not is_instance_valid(g):
			_relay_intro_on = false
			return false
		g.combat.active = null                            # (no lock on them while the scene plays)
		var dt := get_process_delta_time()
		t += dt
		var all_there := true
		for i in ws.size():
			var w = ws[i]
			if w == null or not is_instance_valid(w):
				continue
			var pts: Array = routes[i]
			if int(idx[i]) >= pts.size():
				w.moving = false
				continue
			all_there = false
			var to: Vector2 = pts[int(idx[i])]
			var d: Vector2 = to - w.pos
			w.pos = w.pos.move_toward(to, speed * dt * (8.0 if quick else 1.0))
			w.position = w.pos * GroundMap.SCALE
			w.moving = true
			if absf(d.x) > absf(d.y):
				w.dir = 3 if d.x > 0.0 else 2             # (right, left)
			else:
				w.dir = 0 if d.y > 0.0 else 1             # (down, up)
			if w.pos.distance_to(to) < 2.0:
				idx[i] = int(idx[i]) + 1
		if all_there:
			return true
		await get_tree().process_frame
	return true


## Rook's shock baton on one of them: sparks, ZAP, down.
func _intro_zap(g, nf: Dictionary) -> void:
	var w2 = nf.get("w", null)
	if not is_instance_valid(g) or w2 == null or not is_instance_valid(w2):
		return
	for k in 10:
		g.combat.sparks.append({"pos": w2.pos + Vector2(randf_range(-8, 8), -20 + randf_range(-8, 8)), "vel": Vector2(randf_range(-60, 60), randf_range(-80, -20)), "t": 0.0, "col": Color(0.45, 0.85, 1.0)})
	g.combat.floaters.append({"pos": w2.pos + Vector2(0, -46), "text": "ZAP", "col": Color(0.45, 0.85, 1.0), "t": 0.0})
	Audio.play("shield_down", "Rook's shock baton", -4.0)
	nf["dead"] = true
	nf["state"] = "down"
	w2.down = true
	w2.moving = false
	w2.bubble_t = 0.0


## Out with the coordinates and the transmitter gone: Dan on the radio, the pay, on to the strike.
func _relay_done() -> void:
	if phase != "relay":
		return
	_set_phase("strike")
	_show_overload(false)
	var st = GameState.story
	st.set_flag("w58_relay", true)
	st.flags.erase("w58_relay_site")
	if st.running(FIGHT):
		st.missions[FIGHT]["target"] = ""
	st.show.emit("radio", {"who": "dan", "text": "Silas sent me the coordinates. You did it, you crazy... You did it.", "mission": FIGHT, "now": true})
	_strike_begin()                                      # package 58, part 8: to the rendezvous


# ---- part 8: the strike (Luz, 20 Nov 2026)

const RoostScript = preload("res://scripts/world/roost.gd")
const RV_POS := Vector2(-2200000, 1900000)        # the rendezvous in Hollow: far out west
const ROOST_POS := Vector2(5300000, 1700000)      # the Red Talon Roost: far out east
var _roost = null
var _allies := {}                       # "dan", "ossa", "silas" -> Ship
var _rv_on := false                     # the rendezvous and the warp under way (a scene)
var _strike_lock := false               # the scene has the controls
var _chat_t := 20.0
var _heal_said := -100.0
var _retreat := {}                      # ally key -> seconds left pulled back
var _said8 := {}


func _sk() -> String:
	return String(flags().get("w58_sk", "rv"))


func _goto_fight_step(id: String) -> void:
	var st = GameState.story
	if not st.running(FIGHT):
		return
	for si in (st.mission_data(FIGHT)["steps"] as Array).size():
		if String(st.mission_data(FIGHT)["steps"][si]["id"]) == id:
			st.goto_step(FIGHT, si)
			return


## On to the strike: the rendezvous marked in Hollow, Dan on the radio.
func _strike_begin() -> void:
	var st = GameState.story
	st.set_flag("w58_sk", "rv")
	st.flags.erase("w58_rv")
	_beacons(false)
	_goto_fight_step("rendezvous")
	if st.running(FIGHT):
		st.tracked = FIGHT
		st.missions[FIGHT]["target"] = "w58_rv"
		st.changed.emit()
	st.show.emit("radio", {"who": "dan", "text": "Ossa's ship is fuelled, mine's warming up, and Silas hasn't slept. I've marked a spot in Hollow, far from their station. Meet us there.",
		"mission": FIGHT, "until_flag": "w58_rv", "hint": "fly to the rendezvous in Hollow"})


## The story's waypoints in Hollow: the rendezvous; with the warp also the Roost.
func _beacons(with_roost: bool) -> void:
	var sid := Universe.special_system("hollow")
	var list: Array = [{"id": "w58_rv", "name": "Rendezvous", "pos": RV_POS, "kind": "story", "land": 3000.0}]
	if with_roost:
		list.append({"id": "w58_roost", "name": "Red Talon Roost", "pos": ROOST_POS, "kind": "story", "land": 3600.0})
	Universe.story_beacons[sid] = list
	var v = main.view if main != null else null
	if v != null and is_instance_valid(v) and int(v.system_id) == sid:
		for b in list:
			if v.find_object(String(b["id"])) == null:
				v._add_celestial("beacon", b)


func _strike_step() -> void:
	var v = main.view
	if v == null or not is_instance_valid(v):
		return
	if _strike_lock:
		v.input_enabled = false
	match _sk():
		"rv":
			if _rv_on or GameState.current_system != Universe.special_system("hollow"):
				return
			var pl = v.player
			if pl == null or not is_instance_valid(pl) or pl.is_docked():
				return
			_rv_waiting()                                # (Luz) they wait at the rendezvous already
			if pl.in_warp():
				return
			if pl.position.distance_to(RV_POS) < 30000.0:
				_rv_scene()
		"fight":
			if _rv_on:
				return
			if _roost == null or not is_instance_valid(_roost) or GameState.current_system != Universe.special_system("hollow"):
				_strike_abort("left")
				return
			if not _roost.dead:
				_allies_step(get_process_delta_time())


## An ally of the strike: a ship of the story's people (never destroyed, never a crime to graze), green in the overview.
func _ally(preset: String, at: Vector2, nm: String, paint: String, who: String, flash := true) -> Ship:
	var v = main.view
	var s: Ship = v.spawn_npc(preset, at, "civilian", "")
	s.fit.ship_name = nm
	if paint != "":
		s.fit.paint = paint
		s.paint = PixelArt.paint_key(s.fit)
	s.escort_mark = true
	s.story_spare = true
	s.set_meta("story_ally", who)
	s.fit.stance = "aggressive"
	if who == "silas":
		# (Luz) the Hope keeps her guns this time – Silas goes for the fighters, and jams the station's guns
		s.fit.drones.clear()
	else:
		# Dan's nine drones and Ossa's: a drone bay, their guns, their shields
		var want := {"hangar": "hangar:9:A", "dweapon_0": "w_pulse:1:A", "dbonus_0": "dr_shield:3:A"}
		for k2 in want:
			s.fit.modules[k2] = want[k2]
		s.fit.mark_dirty()
		s.fit.drones.clear()
		for i in int(s.fit.stats().get("drones_max", 9)):
			s.fit.drones.append({"fuel": 1.0, "hp": 1.0, "out": false})
		s.fit.drone_role = "combat"
		s.fit.drone_modes["combat"] = "fire_at_will"
		s.fit.drone_modes["repair"] = "auto"
	s.fit.mark_dirty()
	s.fit.refill()
	s.align_scale = 0.4
	if flash:
		v.spawn_fx(Fx.warp_flash(at, s.radius * 3.0))
	return s


## Where everyone stands at the rendezvous, facing the Roost: Dan and Silas on one side, Ossa on the other, you in the middle.
static func _rv_slots() -> Dictionary:
	var dir := (ROOST_POS - RV_POS).normalized()
	var side := dir.orthogonal()
	return {"you": RV_POS, "dan": RV_POS + side * 1100.0, "ossa": RV_POS - side * 1300.0, "silas": RV_POS + side * 2300.0 - dir * 300.0}


## (Luz) Dan, Ossa and Silas wait at the rendezvous: their ships there, side by side, as soon as you are in Hollow.
func _rv_waiting() -> void:
	var ok := _allies.size() == 3
	for k in _allies:
		ok = ok and _allies[k] != null and is_instance_valid(_allies[k]) and not _allies[k].dying
	if ok:
		return
	for k0 in _allies:
		if _allies[k0] != null and is_instance_valid(_allies[k0]):
			_allies[k0].queue_free()
	_allies.clear()
	var slots := _rv_slots()
	var dir := (ROOST_POS - RV_POS).normalized()
	for sp in [["dan", "std_kanayama", "Kanayama-maru", "dan_rust"], ["ossa", "std_hdy_citadel", "Citadel", "ossa_rust"], ["silas", "std_bastion", HOPE_NAME, ""]]:
		var a := _ally(String(sp[1]), slots[String(sp[0])], String(sp[2]), String(sp[3]), String(sp[0]), false)
		a.heading = dir.angle()
		a.set_order({"type": "idle"})
		_allies[String(sp[0])] = a


## The rendezvous (a scene, no controls): Dan, Ossa and Silas wait there; you fly into the line between them;
## then all of you into the warp together – the last talk on the way, the warp held till it is over – and out
## side by side before the Roost.
func _rv_scene() -> void:
	_rv_on = true
	_strike_lock = true
	var v = main.view
	var pl = v.player
	var st = GameState.story
	st.set_flag("w58_rv", true)
	pl.set_order({"type": "idle"})
	var q := 0.05 if quick else 1.0
	_rv_waiting()
	var slots := _rv_slots()
	pl.set_order({"type": "move", "pos": slots["you"]})         # into the line, between them
	var lines := {"dan": "There you are. Took your time.", "ossa": "Everyone's here. Let's not keep them waiting.",
		"silas": "Their station's still deaf. Every minute we wait, they get a little less confused."}
	for who in ["dan", "ossa", "silas"]:
		st.show.emit("radio", {"who": who, "text": String(lines[who]), "mission": FIGHT})
		var t := 0.0
		while t < 3.5 * q or (not quick and t < 15.0 and (main.story_ui._radio != null or not main.story_ui._radio_q.is_empty())):
			if not _rv_alive():
				return
			_rv_cam(pl, 0.06)
			await get_tree().process_frame
			t += get_process_delta_time()
	# you in the line
	var tw := 0.0
	while tw < 40.0 * q:
		if not _rv_alive():
			return
		_rv_cam(pl, 0.06)
		if pl.position.distance_to(slots["you"]) < 700.0:
			break
		await get_tree().process_frame
		tw += get_process_delta_time()
	pl.set_order({"type": "idle"})
	for k2 in _allies:
		if is_instance_valid(_allies[k2]):
			_allies[k2].set_order({"type": "idle"})
	st.show.emit("radio", {"who": "dan", "text": "Then we go. Line up on me. We jump together.", "mission": FIGHT})
	await _w(3.0)
	if not _rv_alive():
		return
	# into the warp together: the Roost waits at the other end
	_beacons(true)
	if _roost != null and is_instance_valid(_roost):
		_roost.queue_free()
	_roost = RoostScript.new()
	_roost.quick = quick
	_roost.setup(v, ROOST_POS)
	_roost.hope = _allies.get("silas", null)
	_roost.event.connect(_on_roost)
	for k3 in _allies:
		if is_instance_valid(_allies[k3]):
			_allies[k3].set_order({"type": "follow", "node": pl, "r": 900.0})
	pl.warp_hold = false
	var tgt: Dictionary = Universe.warp_target(Universe.special_system("hollow"), "w58_roost")
	pl.set_order({"type": "warp", "target": tgt})
	v.story_cam = Vector2.INF
	var ta := 0.0
	while not pl.in_warp() and ta < 30.0:
		if not _rv_alive():
			return
		await get_tree().process_frame
		ta += get_process_delta_time()
	for line in _warp_talk():
		st.show.emit("radio", {"who": String(line[0]), "text": String(line[1]), "mission": FIGHT})
	# (Luz) the warp is timed to the talk: its length set so that you drop out as the last call ends
	if not quick and pl.in_warp():
		var talk: float = main.story_ui.radio_left()
		pl.warp["T"] = float(pl.warp["t"]) + maxf(talk, 3.0)
	# should the talk run long after all (a pause, a frame drop), the warp slows near its end until it is over
	var tt := 0.0
	while not quick and (main.story_ui._radio != null or not main.story_ui._radio_q.is_empty()) and tt < 240.0:
		if not _rv_alive():
			return
		if pl.in_warp():
			pl.warp_hold = main.story_ui.radio_left() > float(pl.warp["T"]) - float(pl.warp["t"]) + 0.3
		await get_tree().process_frame
		tt += get_process_delta_time()
	pl.warp_hold = false
	var tx := 0.0
	while pl.in_warp() and tx < 30.0:
		if not _rv_alive():
			return
		await get_tree().process_frame
		tx += get_process_delta_time()
	_fight_start()


func _rv_alive() -> bool:
	var v = main.view
	if v == null or not is_instance_valid(v) or v.player == null or not is_instance_valid(v.player) or _sk() != "rv":
		_rv_on = false
		_strike_lock = false
		return false
	return true


## The camera over the group: between you and whoever has come.
func _rv_cam(pl, k: float) -> void:
	var v = main.view
	var c: Vector2 = pl.position
	var n := 1
	for key in _allies:
		var a = _allies[key]
		if a != null and is_instance_valid(a) and (a.position as Vector2).distance_to(pl.position) < 12000.0:
			c += a.position
			n += 1
	c /= float(n)
	v.story_cam = c if v.story_cam == Vector2.INF else (v.story_cam as Vector2).lerp(c, k)


static func _warp_talk() -> Array:
	return [
		["silas", "Right. One last time, so nobody can say I didn't tell them."],
		["silas", "The station sits on a reactor. Four gun platforms round it, and two hangars that keep spitting out fighters as long as they stand."],
		["silas", "Take out the platforms first, or they'll chew us up. Kill the hangars and the fighters stop coming. Every hit on that thing counts."],
		["silas", "The reactor's under heavy plating. Once the station is badly hurt, the plating should give. Then hit the core with everything you have."],
		["silas", "I'll be jamming their guns from the back. The Hope can't fight, but she can make them miss."],
		["dan", "Thirty years I've run my store out here, and for the last two these vultures have been picking at it. Picking at my people."],
		["dan", "Today it stops. My drones go out with you. If anyone gets hurt, they patch you up first. Don't make me regret it."],
		["ossa", "I let them be for too long. Told myself it was cheaper to pay than to fight."],
		["ossa", "It wasn't. It never is."],
		["ossa", "Rook, keep that pilot alive. Pilot, keep my Maul in one piece."],
		["rook", "No promises about the paint."],
		["dan", "And remember, if we live through this, the whiskey's open tonight."],
		["ossa", "I'm holding you to that."],
		["you", "Let's do it."],
		["silas", "Dropping out in three... two..."],
	]


## Out of the warp before the Roost: the controls are yours again, the pirates wake, the drones go out.
func _fight_start() -> void:
	_rv_on = false
	_strike_lock = false
	var v = main.view
	if v == null or not is_instance_valid(v):
		return
	v.input_enabled = true
	v.story_cam = Vector2.INF
	var st = GameState.story
	st.set_flag("w58_sk", "fight")
	_goto_fight_step("strike")
	if st.running(FIGHT):
		st.missions[FIGHT]["target"] = "w58_roost"
		st.changed.emit()
	_chat_t = 25.0
	_said8 = {}
	_retreat = {}
	if _roost != null and is_instance_valid(_roost):
		_roost.show_bar(true)                          # the boss bar from here on
	for line in [["talon", "Who's out there? Relay's dead, I can't raise anyone!"], ["talon", "Four ships on the scope! Is that a carrier?!"],
			["talon_boss", "All ships, launch! Launch everything! Nobody touches the Roost!"], ["dan", "Drones out. Go get them, my beauties."]]:
		st.show.emit("radio", {"who": String(line[0]), "text": String(line[1]), "mission": FIGHT})
	for k in _allies:
		var a = _allies[k]
		if a == null or not is_instance_valid(a):
			continue
		a.home = ROOST_POS
		if k == "silas":
			a.set_order({"type": "move", "pos": ROOST_POS + (a.position - ROOST_POS).normalized() * 12000.0})
		else:
			a.set_order({"type": "move", "pos": ROOST_POS + (a.position - ROOST_POS).normalized() * 4500.0})
			v.launch_drones(a)


## The allies in the fight: Dan's drones heal whoever is hurt (else they fight); a badly hit ship pulls back a
## while; whoever idles goes back in; now and then someone says something.
func _allies_step(dt: float) -> void:
	var v = main.view
	var pl = v.player
	var group: Array = [pl]
	for k in _allies:
		group.append(_allies[k])
	# Dan's drones: patch up first
	var dan = _allies.get("dan", null)
	if dan != null and is_instance_valid(dan):
		var hurt = null
		for s in group:
			if s != null and is_instance_valid(s) and not s.dying and _hull_share(s) < 0.8:
				hurt = s
		var want := "repair" if hurt != null else "combat"
		if String(dan.fit.drone_role) != want:
			dan.fit.drone_role = want
			if want == "repair" and _t8() - _heal_said > 30.0:
				_heal_said = _t8()
				var whom := "you" if hurt == pl else String(hurt.get_meta("story_ally", ""))
				var line := "Hold still, patching you up." if whom == "you" else ("Ossa, your hull's smoking. Drones on their way." if whom == "ossa" else "Drones on their way, hang on!")
				GameState.story.show.emit("radio", {"who": "dan", "text": line, "mission": FIGHT})
	for k2 in _allies:
		var a = _allies[k2]
		if a == null or not is_instance_valid(a) or a.dying or a.in_warp():
			continue
		if k2 != "silas" and v.drones_of(a).is_empty() and fmod(_t8(), 5.0) < dt:
			# (Luz) the drones come again: lost ones are replaced from the ship's stores
			var dmax := int(a.fit.stats().get("drones_max", 9))
			for r in a.fit.drones:
				r["out"] = false
				r["fuel"] = 1.0
				r["hp"] = 1.0
			while a.fit.drones.size() < dmax:
				a.fit.drones.append({"fuel": 1.0, "hp": 1.0, "out": false})
			v.launch_drones(a)
		# (Luz) the allies take the fighters while you take the platforms
		if _roost != null and is_instance_valid(_roost) and fmod(_t8() + float(k2.length()), 1.0) < dt:
			var fighters: Array = _roost.pirates.filter(func(p): return p != null and is_instance_valid(p) and not p.dying)
			if not fighters.is_empty() and not fighters.has(a.target):
				var best = null
				var bd := INF
				for p2 in fighters:
					var d2: float = (p2.position as Vector2).distance_to(a.position)
					if d2 < bd:
						bd = d2
						best = p2
				if best != null:
					a.set_order({"type": "attack", "target": best})
		# badly hit: pull back a while (Dan's drones come), then back in
		if float(_retreat.get(k2, 0.0)) > 0.0:
			_retreat[k2] = float(_retreat[k2]) - dt
			continue
		if k2 != "silas" and _hull_share(a) < 0.25:
			_retreat[k2] = 15.0
			a.set_order({"type": "move", "pos": ROOST_POS + (a.position - ROOST_POS).normalized() * 16000.0})
			continue
		if a.target == null and String(a.order.get("type", "idle")) == "idle":
			var r := 12000.0 if k2 == "silas" else 4500.0
			if (a.position as Vector2).distance_to(ROOST_POS) > r * 1.3:
				a.set_order({"type": "move", "pos": ROOST_POS + (a.position - ROOST_POS).normalized() * r})
	# now and then a word
	_chat_t -= dt
	if _chat_t <= 0.0:
		_chat_t = randf_range(22.0, 34.0)
		var pool := [["ossa", "Keep moving, don't give their guns a still target."], ["silas", "Their guns are wobbling. Keep at it!"],
			["rook", "Lead them in, I'll do the rest."], ["rook", "That one's ours!"], ["talon", "Get the carrier off us!"],
			["dan", "Look at them run! Keep it up!"], ["talon", "Where's our support?! Somebody answer!"]]
		var pick: Array = pool[randi() % pool.size()]
		GameState.story.show.emit("radio", {"who": String(pick[0]), "text": String(pick[1]), "mission": FIGHT})


func _t8() -> float:
	return Time.get_ticks_msec() * 0.001


static func _hull_share(s) -> float:
	var bs: Dictionary = s.fit.stats()
	var mx := float(bs["armor_max"]) + float(bs["structure_max"])
	return (s.fit.armor + maxf(s.fit.structure, 0.0)) / maxf(mx, 1.0)


func _say8(key: String, lines: Array) -> void:
	if _said8.has(key):
		return
	_said8[key] = true
	for l in lines:
		GameState.story.show.emit("radio", {"who": String(l[0]), "text": String(l[1]), "mission": FIGHT, "now": bool(l.size() > 2 and l[2])})


func _on_roost(what: String, arg) -> void:
	var st = GameState.story
	match what:
		"platform_down":
			var lines: Array = [["ossa", "Platform down. Next!" if int(arg) > 0 else "That's the last of their guns!"]]
			if int(arg) == 3:
				lines.append(["talon", "They're hitting the platforms!"])
			for l in lines:
				st.show.emit("radio", {"who": String(l[0]), "text": String(l[1]), "mission": FIGHT})
		"hangar_down":
			st.show.emit("radio", {"who": "silas", "text": "Hangar's breached! No more fighters from that side." if int(arg) > 0 else "Both hangars gone! No more fighters!", "mission": FIGHT})
			st.show.emit("radio", {"who": "talon", "text": "A hangar is gone! Somebody, anybody!" if int(arg) > 0 else "The hangars are gone! We're on our own out here!", "mission": FIGHT})
		"wave":
			if int(arg) == 2:
				_say8("hangars", [["ossa", "Fighters launching. Get those hangars!"]])
		"core_open":
			_say8("core", [["silas", "The plating's gone! The core is open!", true], ["talon_boss", "Everyone out! Every ship, everything you've got! Protect the core!"],
				["dan", "That's it, everybody on the core!"]])
		"dying":
			_say8("dying", [["silas", "Core's going critical. Get clear, get clear!", true]])
		"dead":
			_strike_won()


## The Roost gone: the cheering on the radio, the pay, home to Dan's bar.
func _strike_won() -> void:
	var st = GameState.story
	st.set_flag("w58_base_down", true)
	st.set_flag("w58_sk", "party")
	if st.running(FIGHT):
		st.missions[FIGHT]["target"] = ""
	for l in [["ossa", "...Well. That's the loudest thing I've seen in years."], ["dan", "HAH! Did you see that? Did you SEE that?!"],
			["silas", "No more pirate plague out here. I think I need to sit down."], ["dan", "Everybody home. Drinks are on me tonight. All of them."]]:
		st.show.emit("radio", {"who": String(l[0]), "text": String(l[1]), "mission": FIGHT})
	for k in _allies:
		var a = _allies[k]
		if a != null and is_instance_valid(a):
			main.view.recall_drones(a)
	await _w(14.0)
	_strike_party()


## Broken off: you were shot down (and wake at Dan's), or left the fight. Everything goes back to the rendezvous.
func _strike_abort(why: String) -> void:
	if _roost != null and is_instance_valid(_roost):
		_roost.queue_free()
	_roost = null
	for k in _allies:
		var a = _allies[k]
		if a != null and is_instance_valid(a):
			a.queue_free()
	_allies.clear()
	_rv_on = false
	_strike_lock = false
	var v = main.view if main != null else null
	if v != null and is_instance_valid(v):
		v.input_enabled = true
		v.story_cam = Vector2.INF
		if v.player != null and is_instance_valid(v.player):
			v.player.warp_hold = false
	var st = GameState.story
	st.set_flag("w58_sk", "rv")
	st.flags.erase("w58_rv")
	_beacons(false)
	_goto_fight_step("rendezvous")
	if st.running(FIGHT):
		st.missions[FIGHT]["target"] = "w58_rv"
		st.changed.emit()
	if why == "left":
		st.show.emit("radio", {"who": "dan", "text": "We pulled back to the rendezvous. Patch yourself up and meet us there when you're ready. We go again." if why == "down" else "Where did you go? We pulled back to the rendezvous. Come back when you're ready, and we go again.",
			"mission": FIGHT, "until_flag": "w58_rv", "hint": "fly to the rendezvous in Hollow"})


## The bar after the Roost (a scene): Dan, Ossa, Silas and Rook, the regulars; the whiskey from Earth, the toasts,
## Ossa's gift; the lent gear back.
func _strike_party() -> void:
	if _sk() != "party":
		return
	var st = GameState.story
	await main.fade(Color(0, 0, 0, 1), 1.0).finished
	main.story_ui._radio_q.clear()                       # (the fight's calls end with it)
	if main.story_ui._radio != null and is_instance_valid(main.story_ui._radio):
		main.story_ui._radio.queue_free()
		main.story_ui._radio = null
		main.story_ui._radio_d = {}
	for k in _allies:
		var a = _allies[k]
		if a != null and is_instance_valid(a):
			a.queue_free()
	_allies.clear()
	if _roost != null and is_instance_valid(_roost):
		_roost.queue_free()
	_roost = null
	Universe.story_beacons.erase(Universe.special_system("hollow"))
	# home: docked at Dan's
	var f := GameState.active()
	var dan_st := String(flags().get("w58_dan_st", ""))
	var beyond := Universe.special_system("beyond")
	var stn := Universe.find_station(beyond, dan_st)
	if f != null and not stn.is_empty():
		for d in f.drones:
			d["out"] = false
		f.system_id = beyond
		f.docked_at = dan_st
		f.position = stn.get("pos", Vector2.ZERO)
		GameState.current_system = beyond
		main.load_system(beyond)
		main.station_panel.close()
	# (the system may still be loading: wait for it, then into the bar)
	for wl in 600:
		if main.ground != null and is_instance_valid(main.ground):
			break
		if (main.loading == null or not is_instance_valid(main.loading)) and main.view != null and is_instance_valid(main.view) 				and main.view.stations.has(dan_st):
			main.station_panel.close()
			main.open_deck()
			if main.ground != null and is_instance_valid(main.ground):
				break
		await get_tree().process_frame
	var g = main.ground
	if g == null:
		push_warning("package 58, part 8: no deck at Dan's for the party (docked %s)" % str(f.docked_at if f != null else "-"))
		_strike_done()
		main.fade(Color(0, 0, 0, 0), 0.8)
		return
	g.story_mode = _party8_mode()
	g.go_level("commercial", "story")
	g.input_enabled = false
	_toast_stage(g)
	main.fade(Color(0, 0, 0, 0), 1.2)
	await _w(1.6)
	var say := func(w, text: String, secs: float):
		if w != null and is_instance_valid(w):
			w.bubble = text
			w.bubble_t = secs * (0.1 if quick else 1.0)
	var dan = g.story_people.get("dan", null)
	say.call(dan, "Everyone! The Roost is gone!", 2.6)
	await _w(1.2)
	var i := 0
	for key in g.story_people:
		var p = g.story_people[key]
		if String(key) != "dan" and i % 2 == 0:
			say.call(p, ["Woo-hoo!", "To the Spacefarer!", "Cheers!", "Ha! Finally!"][(i / 2) % 4], 2.2)
		if p != null and is_instance_valid(p):
			p.drink_t = 1.6
		i += 1
	Audio.play("ui_buy", "the party: cheers", -6.0)
	await _w(2.6)
	st.show.emit("dialogue", {"id": "strike_party", "mission": FIGHT, "no_dim": true})
	await get_tree().process_frame
	while main.story_ui.dialogue != null or not main.story_ui._dlg_q.is_empty():
		await get_tree().process_frame
	_strike_done()
	if main.ground != null and is_instance_valid(main.ground):
		main.ground.story_cam = Vector2.INF
		main.ground.story_zoom = 0.0
		main.ground.input_enabled = true
		_party8_free = true                               # (Luz) stay, enjoy it, play pool with Ossa or Dan
		_party8_asked = false


# ---- (Luz) the party goes on: leave the bar and it asks; yes, and you wake in your room the next day

var _party8_free := false
var _party8_asked := false


func _party8_step() -> void:
	var g = main.ground if main != null else null
	if g == null or not is_instance_valid(g) or g.map == null:
		_party8_free = false                              # (off the deck some other way: the party is over)
		_p59_begin.call_deferred()
		return
	if g.level != "commercial" or g._lift_menu != null or g.minigame != null or g.talk != null or not g.input_enabled:
		return
	var r: Rect2 = g.map.bar_rect
	if r.size == Vector2.ZERO:
		return
	var tile: Vector2 = (g.pilot.pos as Vector2) / GroundMap.TILE
	var inside := r.grow(-0.2).has_point(tile)
	if inside:
		_party8_asked = false
		return
	if _party8_asked:
		return
	_party8_asked = true
	g.pilot.moving = false
	g.ask_window("End the party?", "The bar is still loud behind you. Call it a night?",
		[["Yes, call it a night", _party8_end], ["No, back to the party", _party8_back]], _party8_back)


## "No": a step back into the bar.
func _party8_back() -> void:
	var g = main.ground
	if g == null or not is_instance_valid(g):
		return
	var r: Rect2 = g.map.bar_rect.grow(-1.0)
	var t: Vector2 = (g.pilot.pos as Vector2) / GroundMap.TILE
	t = Vector2(clampf(t.x, r.position.x, r.end.x), clampf(t.y, r.position.y, r.end.y))
	g.pilot.pos = t * GroundMap.TILE
	g.pilot.position = g.pilot.pos * GroundMap.SCALE
	_party8_asked = false


## "Yes": black, "The next day", awake in your room at Dan's.
func _party8_end() -> void:
	_party8_free = false
	var g = main.ground
	if g == null or not is_instance_valid(g):
		return
	g.input_enabled = false
	await main.fade(Color(0, 0, 0, 1), 1.2).finished
	await _cards(["The next day"])
	g = main.ground
	if g == null or not is_instance_valid(g):
		main.fade(Color(0, 0, 0, 0), 0.6)
		return
	if g.is_sitting():
		g._stand_up()
	g.story_mode = {}
	g._q_room = int((GameState.lodging.get(String(flags().get("w58_dan_st", "")), {}) as Dictionary).get("room", -1))
	g._q_sleep = 2
	g.go_level("quarters", "bed")
	g.pilot.visible = false
	main.fade(Color(0, 0, 0, 0), 1.4)
	await _w(2.2)
	await main.fade(Color(0, 0, 0, 1), 0.4).finished
	g._q_sleep = 0
	g.go_level("quarters", "bed")
	g.pilot.visible = true
	g.input_enabled = true
	main.fade(Color(0, 0, 0, 0), 0.6)
	await _w(1.2)
	_p59_begin()                                          # package 59: Dan calls you up to the bar


# ---- package 59, part 1 (Luz, 21 Nov 2026): the way to the Cluster – the morning after, the closed bar, Dr. Imre
# Halden and his Threshold outside the station; Imre waits in the bar until you are ready (part 2: the farewell)

const P59 := "ticket"
var _meet_on := false
var _threshold = null


## The morning after the party: your ticket is paid; Dan calls you up to the bar.
func _p59_begin() -> void:
	if phase != "after58":
		return
	var st = GameState.story
	_ensure_missions()
	st.set_flag("ticket_paid", true)
	if st.running(P59):
		st.tracked = P59
	_set_phase("bar59")
	_p59_radio()
	var g = main.ground if main != null else null
	if g != null and is_instance_valid(g):
		g.story_mode = ground_mode(g.station)
		if not g.story_talk.is_connected(_on_talk):
			g.story_talk.connect(_on_talk)


func _p59_radio() -> void:
	GameState.story.show.emit("radio", {"who": "dan", "text": "Morning. Come up to the bar when you've found your boots. I've got something for you.",
		"mission": P59, "tag": "w59_bar"})                # (Luz: the usual length; the journal carries the task)


## The bar before it opens: no guests, the bartender polishing glasses; Dan and Imre by the window.
func _p59_mode() -> Dictionary:
	var w: Vector2 = IntroSix.WINDOW
	var dan := {"who": "dan", "pos": w, "dir": 3, "talk": true}
	var imre := {"who": "imre", "pos": w + Vector2(1.5, 0.3), "dir": 2, "talk": true}
	if phase == "bar59":
		dan["marker"] = "!"
	else:
		imre["marker"] = "!"
	return {"quiet": true, "keep_bartender": true, "levels": {"commercial": {"people": [dan, imre]}}}


func _p59_step() -> void:
	_p59_threshold()
	if phase == "imre" and bool(flags().get("w59_go", false)) and main.story_ui.dialogue == null and main.story_ui._dlg_q.is_empty():
		_p59_farewell()                                   # part 2: "I'm ready." – the farewell in the hangar
		return
	var g = main.ground
	if g == null or not is_instance_valid(g):
		return
	if not g.story_talk.is_connected(_on_talk):
		g.story_talk.connect(_on_talk)
	# (Luz) you come in and ask what is going on: close to Dan and Imre, the talk begins
	if phase == "bar59" and not _meet_on and g.level == "commercial" and g.input_enabled and g.talk == null and g.minigame == null \
			and main.story_ui.dialogue == null:
		var dan = g.story_people.get("dan", null)
		if dan != null and is_instance_valid(dan) and (dan.pos as Vector2).distance_to(g.pilot.pos) < GroundMap.TILE * 5.0:
			_p59_meet()


## The talk in the closed bar: Dan explains, Imre introduces himself; then Imre waits for you.
func _p59_meet() -> void:
	var g = main.ground
	if g == null or not is_instance_valid(g):
		return
	_meet_on = true
	GameState.story.set_flag("w59_bar", true)             # (Dan's call is answered: off the screen)
	var sui = main.story_ui
	if sui._radio != null and is_instance_valid(sui._radio) and String(sui._radio_d.get("tag", "")) == "w59_bar":
		sui._radio.queue_free()
		sui._radio = null
		sui._radio_d = {}
	sui._radio_q = sui._radio_q.filter(func(d): return String(d.get("tag", "")) != "w59_bar")
	g.pilot.moving = false
	var dan = g.story_people.get("dan", null)
	var imre = g.story_people.get("imre", null)
	if dan != null and is_instance_valid(dan):
		dan.marker = ""
		dan.queue_redraw()                                # (the game pauses for the talk: the "!" goes now)
		dan.dir = 1 if g.pilot.pos.y > dan.pos.y else 0
		if absf(g.pilot.pos.x - dan.pos.x) > absf(g.pilot.pos.y - dan.pos.y):
			dan.dir = 3 if g.pilot.pos.x > dan.pos.x else 2
		g.story_cam = (dan.pos as Vector2 + g.pilot.pos) * 0.5 + (Vector2(GroundMap.TILE * 0.75, 0.0) if imre != null else Vector2.ZERO)
		g.story_zoom = 1.35
	if imre != null and is_instance_valid(imre):
		imre.dir = 2 if g.pilot.pos.x < imre.pos.x else 3
	g._camera()                                           # (the dialogue pauses the game: the camera there now)
	GameState.story.show.emit("dialogue", {"id": "halden_meet", "mission": P59, "no_dim": true})
	await get_tree().process_frame
	while main.story_ui.dialogue != null or not main.story_ui._dlg_q.is_empty():
		await get_tree().process_frame
	GameState.story.set_flag("w59_met", true)
	_set_phase("imre")
	_meet_on = false
	g = main.ground
	if g != null and is_instance_valid(g):
		g.story_cam = Vector2.INF
		g.story_zoom = 0.0
		g.story_mode = ground_mode(g.station)
		for key in g.story_people:
			var p = g.story_people[key]
			if p != null and is_instance_valid(p):
				p.marker = "!" if String(key) == "imre" else ""
	GameState.log_msg("Dr. Imre Halden waits in Dan's bar. Talk to Imre when you're ready to leave Beyond.", GameState.COL_GOOD)


## Imre's Threshold, parked beside Dan's station (in space, whenever Beyond is loaded).
func _p59_threshold() -> void:
	var v = main.view
	if v == null or not is_instance_valid(v) or int(v.system_id) != Universe.special_system("beyond"):
		return
	if _threshold != null and is_instance_valid(_threshold) and not _threshold.dying:
		return
	var dst := String(flags().get("w58_dan_st", ""))
	var stn = v.stations.get(dst, null)
	if stn == null or not is_instance_valid(stn):
		return
	var r := float(stn.radius)
	var s: Ship = v.spawn_npc("std_axa_threshold", stn.position + Vector2(r * 1.5 + 700.0, -r * 0.45), "civilian", "")
	s.fit.ship_name = "Threshold"
	s.anchored = true
	s.story_spare = true
	s.untargetable = false
	s.fit.stance = "passive"
	s.heading = PI
	s.set_meta("story_ally", "imre")
	_threshold = s


# ── Package 59, part 2 (Luz): the farewell in Dan's hangar, Assembly or Covenant, the Threshold's jump ──────────

const JumpFx = preload("res://scripts/world/threshold_jump_fx.gd")
## (Luz) out by the ship, before the jump: Imre explains the Threshold while you look at her
const JUMP_TALK := [
	["imre", "There she is. The Threshold. Axiom built her as a prototype, and nobody has dared to build a second one."],
	["imre", "She doesn't fly through the Veil. She carries a black hole in her core, and folds herself through it. And us with her."],
	["rook", "She does what?"],
	["imre", "Perfectly safe. Mostly. Starting the core now."],
]
var _farewell_on := false
var _jump_fx = null
var _jump_stage := ""                   # "talk", "ignite", "go" (the jump's scene)


## Waits in the jump's scene, the camera kept close on the ship.
func _jump_hold(v, secs: float) -> void:
	var t := 0.0
	var need := secs * (0.05 if quick else 1.0)
	while t < need:
		if v != null and is_instance_valid(v):
			v._set_zoom(1.5)
		await get_tree().process_frame
		t += get_process_delta_time()


## Dan's hangar for the goodbyes (placed by _farewell_stage): Dan, Ossa and Silas facing you in the walkway under the
## glass, Little Darling behind it in the bay, Rook at your side; Imre by the lifts, waiting.
func _farewell_mode() -> Dictionary:
	var people := [{"who": "dan", "dir": 3}, {"who": "ossa", "dir": 3}, {"who": "silas", "dir": 3}, {"who": "rook", "dir": 2},
		{"who": "imre", "near_lift": Vector2(1.5, 1.5), "dir": 0}]
	return {"quiet": true, "levels": {"hangar": {"people": people}}}


## The middle of the walkway right under the hangar's glass, below the ship (art px); INF: not a station hangar.
func _walkway_spot(g) -> Vector2:
	for z in g.map.zones:
		if String(z.get("id", "")) == "hangar_sign":
			var sg: Vector2 = z["sign"]
			return Vector2(sg.x, sg.y + 2.85 * GroundMap.TILE)
	return Vector2.INF


## Waits until a story dialogue (and what it queued) is over.
func _dlg_wait(id: String) -> void:
	GameState.story.show.emit("dialogue", {"id": id, "mission": P59, "no_dim": true})
	await get_tree().process_frame
	while main.story_ui.dialogue != null or not main.story_ui._dlg_q.is_empty():
		await get_tree().process_frame


## "I'm ready.": black, then the hangar – the goodbyes, Imre comes over, the choice; black again, then the jump.
func _p59_farewell() -> void:
	if _farewell_on:
		return
	_farewell_on = true
	_set_phase("farewell")
	main.station_panel.close()
	await main.fade(Color(0, 0, 0, 1), 0.9).finished
	if main.ground == null or not is_instance_valid(main.ground):
		main.open_deck()
	var g = main.ground
	if g != null and is_instance_valid(g):
		g.story_mode = _farewell_mode()
		g.go_level("hangar", "story")
		g.input_enabled = false
		_farewell_stage(g)
		main.fade(Color(0, 0, 0, 0), 1.2)
		await _w(1.4)
		await _dlg_wait("farewell59")
		# Imre comes over from the lift
		g = main.ground
		if g != null and is_instance_valid(g):
			var im = g.story_people.get("imre", null)
			if im != null and is_instance_valid(im):
				await _walk_round(im, [g.pilot.pos + Vector2(GroundMap.TILE * 1.3, -GroundMap.TILE * 0.6)], 2)
			g.pilot.dir = 3
		await _w(0.4)
	await _dlg_wait("imre_choice")
	if String(flags().get("start_faction", "")) == "":
		GameState.story.set_flag("start_faction", "assembly")       # (never: the choice has no way out)
	await main.fade(Color(0, 0, 0, 1), 1.0).finished
	_farewell_on = false
	_p59_jump()


## Everyone in place by the stairs; the camera close on the group, the walkers moving while the dialogue pauses.
func _farewell_stage(g) -> void:
	var T := GroundMap.TILE
	var c := _walkway_spot(g)
	if c == Vector2.INF:
		c = g.pilot.pos
	g.pilot.pos = c + Vector2(1.1 * T, 0.0)
	g.pilot.position = g.pilot.pos * GroundMap.SCALE
	g.pilot.dir = 2
	g.pilot.moving = false
	var spots := {"dan": Vector2(-1.0, -0.45), "ossa": Vector2(-1.9, 0.35), "silas": Vector2(-0.8, 0.95), "rook": Vector2(2.1, 0.75)}
	for key in g.story_people:
		var w = g.story_people[key]
		if w != null and is_instance_valid(w):
			w.process_mode = Node.PROCESS_MODE_ALWAYS
			w.stays = true
			if spots.has(String(key)):
				w.pos = c + (spots[String(key)] as Vector2) * T
				w.position = w.pos * GroundMap.SCALE
	var ship_at: Vector2 = g.map.ship_at if g.map.ship_at != Vector2.INF else c
	g.story_cam = Vector2(c.x + 0.4 * T, lerpf(ship_at.y, c.y, 0.62))
	g.story_zoom = 1.25
	g._camera()


## The jump (Luz): out in space by Dan's station, the Threshold swirls into the black hole in its own middle (a
## whirlpool); the hole collapses with a flash and a purple ring. Then the journal's step is done.
func _p59_jump() -> void:
	_set_phase("jump59")
	if main.ground != null and is_instance_valid(main.ground):
		main.close_deck(false)
	main.station_panel.close()
	_p59_threshold()
	var v = main.view
	var thr = _threshold
	var hud_was: bool = main.hud.visible if main.hud != null else true
	if v != null and is_instance_valid(v) and thr != null and is_instance_valid(thr):
		if main.hud != null:
			main.hud.visible = false
		thr.anchored = true
		thr.bh_t = -1.0                                   # (Luz) the core dark at first: you see it ignite
		thr.bh_out = -1.0
		thr.bh_wait = -10000.0
		thr.queue_redraw()
		v.story_cam = thr.position
		v._set_zoom(1.5)
		_jump_stage = "talk"
		main.fade(Color(0, 0, 0, 0), 1.2)
		await _jump_hold(v, 1.6)
		# Imre explains the ship while you look at it
		for ln in JUMP_TALK:
			GameState.story.show.emit("radio", {"who": String(ln[0]), "text": String(ln[1]), "mission": P59})
		if quick:
			main.story_ui._radio_q.clear()
		var tt := 0.0
		while main.story_ui.radio_left() > 0.3 and tt < 45.0 and not quick:
			v._set_zoom(1.5)
			await get_tree().process_frame
			tt += get_process_delta_time()
		# the black hole ignites: a flash, the hole grows, its disc forms
		_jump_stage = "ignite"
		if thr != null and is_instance_valid(thr):
			thr.bh_wait = thr.BH_DELAY
		await _jump_hold(v, 3.6)
		GameState.story.show.emit("radio", {"who": "imre", "text": "Hold on tight. Here we go.", "mission": P59, "now": true})
		await _jump_hold(v, 2.2)
		_jump_stage = "go"
		if thr != null and is_instance_valid(thr):
			_jump_fx = JumpFx.new()
			_jump_fx.setup(thr, "in")
			_jump_fx.speed = 4.0 if quick else 1.0
			thr.get_parent().add_child(_jump_fx)
			v.story_cam = _jump_fx.position
			while _jump_fx != null and is_instance_valid(_jump_fx):
				v._set_zoom(1.5)                              # (close on the ship, whatever the view wants)
				await get_tree().process_frame
		await _w(1.2)
		await main.fade(Color(0, 0, 0, 1), 1.0).finished
		if thr != null and is_instance_valid(thr):
			thr.queue_free()
		_threshold = null
		if v != null and is_instance_valid(v):
			v.story_cam = Vector2.INF
	_jump_fx = null
	_jump_stage = ""
	var fac := "the Assembly" if String(flags().get("start_faction", "")) == "assembly" else "the Covenant"
	await _cards(["Through the Veil", "Imre, Rook and you aboard the Threshold. Ahead: the Cluster, and %s." % fac])
	GameState.story.set_flag("w59_left", true)
	_set_phase("jumped59")
	if main.hud != null:
		main.hud.visible = hud_was
	if cit_auto:
		_cit_run("arrive")                                # part 3: the arrival, the office, the bar, the first morning
		return
	main.fade(Color(0, 0, 0, 0), 1.0)


# ── Package 61 (Luz): the way to Fern ───────────────────────────────────────────────────────────────────────────
# At pilot level 5 Rook calls: a place out in the Rim, Fern, its city Centauria, and a contact there, Luz. The journal
# gets "A Place Called Fern": fly there, land in Centauria on Pelagia, find Luz on the street.

const FERN := "fern"
const FERN_LEVEL := 5
var _fern_t := 0.0


func _fern_step() -> void:
	_fern_t -= get_process_delta_time()
	if _fern_t > 0.0:
		return
	_fern_t = 1.0
	var st = GameState.story
	var fl: Dictionary = st.flags
	if not bool(fl.get("intro_done", false)):
		return
	if not bool(fl.get("fern_called", false)):
		if GameState.pilot_level() >= FERN_LEVEL and main.story_ui.dialogue == null and Universe.special_system("fern") >= 0:
			_fern_call()
		return
	if not bool(fl.get("fern_arrived", false)) and GameState.current_system == Universe.special_system("fern"):
		st.set_flag("fern_arrived", true)
	var g = main.ground
	if g != null and is_instance_valid(g):
		if String((g.station as Dictionary).get("name", "")) == "Centauria":
			if not bool(fl.get("fern_arrived", false)):
				st.set_flag("fern_arrived", true)
			if not bool(fl.get("fern_landed", false)):
				st.set_flag("fern_landed", true)
			if not g.story_talk.is_connected(_on_talk):
				g.story_talk.connect(_on_talk)


## Rook on the radio, as promised: Fern, Centauria, and Luz.
func _fern_call() -> void:
	var st = GameState.story
	st.set_flag("fern_called", true)
	if not st.running(FERN) and not st.done.has(FERN):
		st.start(FERN)
	st.tracked = FERN
	for ln in ["Remember me? I said I'd call when I found something worth both our time.",
			"There's a place out in the Rim. Fern. A city called Centauria. More work than a pilot like you can handle, and more ways to lose the money again than you can count.",
			"I'm sending you a contact. Luz. Runs a bar down there, knows everyone, owes me a favour. Go and say hello."]:
		st.show.emit("radio", {"who": "rook", "text": ln, "mission": FERN})
	GameState.log_msg("Fern lies in the Rim: find it on the galaxy map. Journal: \"A Place Called Fern\".", GameState.COL_GOOD)


func _luz_talk() -> void:
	var st = GameState.story
	if bool(flags().get("fern_luz", false)):
		st.show.emit("dialogue", {"id": "luz_again", "mission": FERN})
		return
	st.show.emit("dialogue", {"id": "luz_meet", "mission": FERN})
	await get_tree().process_frame
	while main.story_ui.dialogue != null or not main.story_ui._dlg_q.is_empty():
		await get_tree().process_frame
	st.set_flag("fern_landed", true)
	st.set_flag("fern_luz", true)
	var g = main.ground
	if g != null and is_instance_valid(g):
		var w = g.story_people.get("luz", null)
		if w != null and is_instance_valid(w):
			w.marker = ""
			w.queue_redraw()


# ── Package 59, part 3 (Luz): the naturalisation – the last scene of the intro ──────────────────────────────────
# The Threshold turns out of its hole at your first station; the office of the power you chose (a bureaucrat, Imre's
# million, nothing carries over: the skill tree starts again), the licence stamped, a Dragonfly; a little later a
# drink with Rook (what you plan decides a module); the next day you wake in your free room and the ship computer's
# hologram hands you the open game.

const OfficeGen = preload("res://scripts/ground/office_gen.gd")
const OfficeStamp = preload("res://scripts/ui/licence_stamp.gd")
const CIT := "citizen"
const START_MODULES := {"mining": "t_mining:1:C", "pirates": "w_pulse:1:C", "science": "t_scanner:1:C"}
var cit_auto := true                    # (tests: false – the jump ends without part 3)
var _cit_on := false
var _office_on := false
var _stamp = null
var _cit_stage := ""                    # "arrive", "office", "bar", "morning" (the scene under way)


## Where you start: {"system", "station"} – the Assembly's border system the game always began in, or the Covenant's
## like it (not its capital, with a station; the one nearest the border and safest).
static func start_place(fac: String) -> Dictionary:
	var sid: int = Universe.home_system
	if fac == "covenant":
		var best := -1
		var best_h := -INF
		for s in Universe.systems:
			if String(s["faction"]) != "covenant" or bool(s.get("capital", false)) or String(s.get("special", "")) != "" \
					or (s.get("stations_plan", []) as Array).is_empty():
				continue
			var border := false
			for nb in s["links"]:
				border = border or String(Universe.systems[nb]["faction"]) != "covenant"
			var hs := float(s["security"]) + (1.0 if border else 0.0) - absf(int(s.get("core_dist", 2)) - 2) * 0.2
			if hs > best_h:
				best_h = hs
				best = int(s["id"])
		if best < 0:
			best = Universe.special_system("heimkehr")
		if best >= 0:
			sid = best
	var sts: Array = Universe.get_layout(sid)["stations"]
	return {"system": sid, "station": sts[0] if not sts.is_empty() else {}}


func _cit_station() -> Dictionary:
	return Universe.find_station(int(flags().get("cit_sys", -1)), String(flags().get("cit_st", "")))


## The whole of part 3, or from a later scene on (a save in the middle of it).
func _cit_run(from: String = "arrive") -> void:
	if _cit_on:
		return
	_cit_on = true
	var st = GameState.story
	var fac := String(flags().get("start_faction", "assembly"))
	if not fac in ["assembly", "covenant"]:
		fac = "assembly"
		st.set_flag("start_faction", fac)
	main.fade(Color(0, 0, 0, 1), 0.05)
	if main.ground != null and is_instance_valid(main.ground):
		main.close_deck(false)
	main.station_panel.close()
	if not st.running(CIT) and not st.done.has(CIT):
		st.start(CIT)
	if st.running(CIT):
		st.tracked = CIT
	var i := maxi(["arrive", "office", "bar", "morning"].find(from), 0)
	if i > 0 and not bool(flags().get("cit_moved", false)):
		i = 0
	if i <= 0:
		_set_phase("arrive59")
		_cit_transfer(fac)
		await _cit_settle()
		await _cit_arrival()
	else:
		await _cit_settle()
	if i <= 1:
		_set_phase("office59")
		await _cit_office(fac)
	if i <= 2:
		_set_phase("bar59c")
		await _cit_bar()
	_set_phase("wake59")
	await _cit_morning()
	_cit_stage = ""
	_cit_on = false


## Everything stays in Beyond (Luz): the ships (Little Darling with Dan), the money, the cargo, the gear, all but the
## suit Ossa gave you. You arrive docked at your first station with the Dragonfly the licence comes with, the skill
## tree back at its trunk, and a small room of your own there, free for good.
func _cit_transfer(fac: String) -> void:
	if bool(flags().get("cit_moved", false)):
		return
	var st = GameState.story
	var pl := start_place(fac)
	var sid := int(pl["system"])
	var stn: Dictionary = pl["station"]
	if stn.is_empty():
		return
	var stid := String(stn["id"])
	if Commands.world != null and is_instance_valid(Commands.world):
		Commands.world.remove_player()
	GameState.fleet.clear()
	GameState.wingmen.clear()
	var a := GameState.create_from_preset("std_dragonfly", "player")
	a.ship_name = "Dragonfly"
	a.system_id = sid
	a.docked_at = stid
	a.position = stn["pos"]
	a.drones = [{"fuel": 1.0, "hp": 1.0, "out": false}, {"fuel": 1.0, "hp": 1.0, "out": false}]
	GameState.add_ship(a)
	GameState.active_uid = a.uid
	GameState.last_station = {"system": sid, "id": stid}
	GameState.storage[stid] = {}                          # (nothing waits for you here: you arrive with empty hands)
	GameState.credits = GameState.START_CREDITS
	GameState.credits_changed.emit(GameState.credits)
	# the gear: a new pilot's kit, and Ossa's suit on
	var g = GameState.gear
	g.start()
	g.suit = "suit_mil_light:C"
	g._fit_slots()
	g.team = []
	g.refill()
	# the skill tree: back at its trunk (the licence)
	GameState.pilot["tree"] = []
	a.mark_dirty()
	GameState.skills_changed.emit()
	# a small room of your own at your first station, free for good
	var QG = load("res://scripts/ground/quarters_gen.gd")
	var room: int = QG.room_for(stn, "small")
	if room >= 0:
		GameState.lodging[stid] = {"room": room, "size": "small", "free": true, "keep": true}
	st.set_flag("cit_sys", sid)
	st.set_flag("cit_st", stid)
	st.set_flag("cit_moved", true)
	GameState.active_changed.emit()                       # (the new system loads)


## Waits until the system you are in now is loaded and its picture stands.
func _cit_settle() -> void:
	for i in 20:
		await get_tree().process_frame
	for wl in 900:
		if main.loading == null or not is_instance_valid(main.loading):
			break
		await get_tree().process_frame
	main.station_panel.close()


## The arrival: by your first station a flash, the hole opens, the Threshold turns out of it; Imre and Rook on the radio.
func _cit_arrival() -> void:
	_cit_stage = "arrive"
	var v = main.view
	var stn = v.stations.get(String(flags().get("cit_st", "")), null) if v != null and is_instance_valid(v) else null
	if stn == null or not is_instance_valid(stn):
		return
	var hud_was: bool = main.hud.visible if main.hud != null else true
	if main.hud != null:
		main.hud.visible = false
	var r := float(stn.radius)
	var thr: Ship = v.spawn_npc("std_axa_threshold", stn.position + Vector2(r * 1.5 + 900.0, -r * 0.45), "civilian", "")
	thr.fit.ship_name = "Threshold"
	thr.anchored = true
	thr.story_spare = true
	thr.fit.stance = "passive"
	thr.heading = PI
	_threshold = thr
	_jump_fx = JumpFx.new()
	_jump_fx.setup(thr, "out")
	_jump_fx.speed = 4.0 if quick else 1.0
	_jump_fx.process_mode = Node.PROCESS_MODE_DISABLED            # (it waits for the picture)
	thr.get_parent().add_child(_jump_fx)
	v.story_cam = _jump_fx.position
	v._set_zoom(1.5)
	main.fade(Color(0, 0, 0, 0), 1.2)
	await _jump_hold(v, 1.8)
	if _jump_fx != null and is_instance_valid(_jump_fx):
		_jump_fx.process_mode = Node.PROCESS_MODE_INHERIT
		while _jump_fx != null and is_instance_valid(_jump_fx):
			v._set_zoom(1.5)
			await get_tree().process_frame
	_jump_fx = null
	if not quick:
		GameState.story.show.emit("radio", {"who": "imre", "text": "And there we are. The Cluster. You see? Perfectly safe.", "mission": CIT})
		GameState.story.show.emit("radio", {"who": "rook", "text": "I am never doing that again.", "mission": CIT})
		var tt := 0.0
		while main.story_ui.radio_left() > 0.3 and tt < 25.0:
			v._set_zoom(1.5)
			await get_tree().process_frame
			tt += get_process_delta_time()
	await _jump_hold(v, 0.8)
	await main.fade(Color(0, 0, 0, 1), 1.0).finished
	if thr != null and is_instance_valid(thr):
		thr.queue_free()
	_threshold = null
	if v != null and is_instance_valid(v):
		v.story_cam = Vector2.INF
	if main.hud != null:
		main.hud.visible = hud_was


## The office: the official behind the desk, you and Imre before it; the Assembly's passers-by, the Covenant's guards.
func _office_mode(fac: String) -> Dictionary:
	var sp: Dictionary = OfficeGen.spots(fac)
	var people: Array = [{"who": "registrar_cov" if fac == "covenant" else "clerk_asm", "pos": sp["official"], "dir": 0},
		{"who": "imre", "pos": sp["imre"], "dir": 1}]
	if fac != "covenant":
		var rng := RandomNumberGenerator.new()
		rng.seed = 59314
		var ends: Array = OfficeGen.passage_ends()
		for k in 9:
			var lk := ChibiArt.PilotArt.random_look(rng)
			var at: Vector2 = (ends[0] as Vector2).lerp(ends[1], (k + 0.5) / 9.0) + Vector2(0.0, (k % 3 - 1) * 0.75)
			people.append({"who": "passer_%d" % k, "look": lk, "pos": at, "dir": 3 if k % 2 == 0 else 2})
	return {"quiet": true, "levels": {"office": {"people": people}}}


## (Luz) the Assembly's passage: people keep walking through the middle of the room, from one end to the other and back.
func _office_stream(g) -> void:
	var ends: Array = OfficeGen.passage_ends()
	var aim := {}
	while _office_on and g != null and is_instance_valid(g) and String(g.level) == "office":
		for key in g.story_people:
			if not String(key).begins_with("passer_"):
				continue
			var w = g.story_people[key]
			if w == null or not is_instance_valid(w):
				continue
			if not aim.has(key) or w.goto_done:
				var k := int(String(key).trim_prefix("passer_"))
				var east: bool = (k % 2 == 0) if not aim.has(key) else not bool(aim[key])
				aim[key] = east
				w.goto_to = ((ends[1] if east else ends[0]) as Vector2 + Vector2(0.0, (k % 3 - 1) * 0.75)) * GroundMap.TILE
				w.goto_done = false
		await get_tree().process_frame


func _cit_office(fac: String) -> void:
	_cit_stage = "office"
	var st = GameState.story
	if main.ground == null or not is_instance_valid(main.ground):
		main.open_deck()
	var g = main.ground
	if g == null or not is_instance_valid(g):
		st.set_flag("cit_licence", true)
		return
	g.office_faction = fac
	g.story_mode = _office_mode(fac)
	g.go_level("office", "story")
	g.input_enabled = false
	var sp: Dictionary = OfficeGen.spots(fac)
	g.pilot.pos = (sp["you"] as Vector2) * GroundMap.TILE
	g.pilot.position = g.pilot.pos * GroundMap.SCALE
	g.pilot.dir = 1
	g.pilot.moving = false
	for key in g.story_people:
		var w = g.story_people[key]
		if w != null and is_instance_valid(w):
			w.process_mode = Node.PROCESS_MODE_ALWAYS
			w.stays = true
	g.story_cam = (sp["cam"] as Vector2) * GroundMap.TILE
	g.story_zoom = 1.25
	g._camera()
	_office_on = true
	_office_stream(g)
	main.fade(Color(0, 0, 0, 0), 1.2)
	await _w(1.6)
	await _cit_dlg("citizen_" + fac)
	# the licence and the stamp
	var cl := CanvasLayer.new()
	cl.layer = 44
	cl.process_mode = Node.PROCESS_MODE_ALWAYS
	main.add_child(cl)
	_stamp = OfficeStamp.new()
	_stamp.faction = fac
	_stamp.speed = 6.0 if quick else 1.0
	cl.add_child(_stamp)
	await _stamp.finished
	_stamp = null
	cl.queue_free()
	st.set_flag("cit_licence", true)
	GameState.log_msg("Pilot licence granted. Your skill tree starts again at its trunk; your Dragonfly waits in the hangar.", GameState.COL_GOOD)
	await _cit_dlg("citizen_%s_end" % fac)
	await main.fade(Color(0, 0, 0, 1), 1.0).finished
	_office_on = false
	g = main.ground
	if g != null and is_instance_valid(g):
		g.story_cam = Vector2.INF
		g.story_zoom = 0.0


func _cit_dlg(id: String) -> void:
	GameState.story.show.emit("dialogue", {"id": id, "mission": CIT, "no_dim": true})
	await get_tree().process_frame
	while main.story_ui.dialogue != null or not main.story_ui._dlg_q.is_empty():
		await get_tree().process_frame


## "A little later": you and Rook sit in the bar of your first station; what you plan decides the module you get.
func _cit_bar() -> void:
	_cit_stage = "bar"
	var st = GameState.story
	await _cards(["A little later"])
	if main.ground == null or not is_instance_valid(main.ground):
		main.open_deck()
	var g = main.ground
	if g != null and is_instance_valid(g):
		g.story_mode = {"no_crew": true, "levels": {"commercial": {"people": [{"who": "rook", "near_spawn": Vector2(1.5, 0.0), "dir": 2}]}}}
		g.go_level("commercial", "story")
		g.input_enabled = false
		_bar_seats(g)
		main.fade(Color(0, 0, 0, 0), 1.2)
		await _w(1.6)
	await _cit_dlg("rook_plan")
	var job := String(flags().get("start_job", ""))
	if not START_MODULES.has(job):
		job = "pirates"
		st.set_flag("start_job", job)
	if not bool(flags().get("cit_module", false)):
		st.set_flag("cit_module", true)
		var mid := String(START_MODULES[job])
		GameState.storage_add(String(flags().get("cit_st", "")), mid, 1)
		GameState.log_msg("Rook's parting gift from Ossa: a %s, in your storage here." % GameData.module_name(mid), GameState.COL_GOOD)
	await main.fade(Color(0, 0, 0, 1), 1.0).finished
	g = main.ground
	if g != null and is_instance_valid(g):
		g.story_cam = Vector2.INF
		g.story_zoom = 0.0


## You and Rook on two seats side by side in the bar (the nearest pair); none there: standing where you came in.
func _bar_seats(g) -> void:
	var rook = g.story_people.get("rook", null)
	var T := GroundMap.TILE
	var br := Rect2(g.map.bar_rect.position * T, g.map.bar_rect.size * T)
	var seats: Array = []
	for z in g.map.zones:
		if String(z.get("kind", "")) == "seat" and z.has("seat") and (br.size.x <= 0.0 or br.has_point(z["seat"])):
			seats.append(z)
	var best: Array = []
	var best_d := INF
	for i in seats.size():
		for j in range(i + 1, seats.size()):
			var d: float = (seats[i]["seat"] as Vector2).distance_to(seats[j]["seat"])
			if d < best_d and d > 4.0:
				best_d = d
				best = [seats[i], seats[j]]
	if best.size() == 2 and best_d < T * 3.0:
		g._sit(best[0])
		if rook != null and is_instance_valid(rook):
			rook.pos = best[1]["seat"]
			rook.position = rook.pos * GroundMap.SCALE
			rook.dir = int(best[1].get("dir", 0))
			rook.sitting = true
			rook.stays = true
	if rook != null and is_instance_valid(rook):
		g.story_cam = ((rook.pos as Vector2) + g.pilot.pos) * 0.5
	else:
		g.story_cam = g.pilot.pos
	g.story_zoom = 1.9
	g._camera()


## "The next day": you wake in your room; the ship computer's hologram – from here on the open game.
func _cit_morning() -> void:
	_cit_stage = "morning"
	var st = GameState.story
	await _cards(["The next day"])
	if main.ground == null or not is_instance_valid(main.ground):
		main.open_deck()
	var g = main.ground
	if g != null and is_instance_valid(g):
		if g.is_sitting():
			g._stand_up()
		g.story_mode = {}
		g.input_enabled = false
		var room := int((GameState.lodging.get(String(flags().get("cit_st", "")), {}) as Dictionary).get("room", -1))
		if room >= 0:
			g._q_room = room
			g._q_sleep = 2
			g.go_level("quarters", "bed")
			g.pilot.visible = false
			main.fade(Color(0, 0, 0, 0), 1.4)
			await _w(2.2)
			await main.fade(Color(0, 0, 0, 1), 0.4).finished
			g._q_sleep = 0
			g.go_level("quarters", "bed")
			g.pilot.visible = true
		else:
			g.go_level("commercial", "lift")
		g.input_enabled = false
		main.fade(Color(0, 0, 0, 0), 0.8)
		await _w(1.4)
	GameState.story.show.emit("dialogue", {"id": "free_play", "mission": CIT})
	await get_tree().process_frame
	while main.story_ui.dialogue != null or not main.story_ui._dlg_q.is_empty():
		await get_tree().process_frame
	st.set_flag("intro_done", true)
	_set_phase("free")
	GameState.story_guard = Callable()                    # the open game: its own rules from here
	GameState.story_foot_guard = Callable()
	g = main.ground
	if g != null and is_instance_valid(g):
		g.input_enabled = true
	if main.hud != null:
		main.hud.visible = true
	GameState.log_msg("The Cluster is yours. Your Dragonfly waits in the hangar; this room is yours to keep.", GameState.COL_GOOD)


## The bar, full: Dan by the window, Ossa, Silas and Rook beside him, the regulars and a crowd, some of them dancing.
func _party8_mode() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 58008
	var w: Vector2 = IntroSix.WINDOW
	var people: Array = [{"who": "dan", "pos": w, "dir": 0},
		{"who": "ossa", "pos": w + Vector2(-1.6, 1.4), "dir": 3}, {"who": "silas", "pos": w + Vector2(2.6, 1.0), "dir": 2},
		{"who": "rook", "pos": w + Vector2(-0.4, 2.6), "dir": 1}]
	var floor_c := w + Vector2(-0.5, 5.0)
	var named := ["patron_a", "patron_b", "patron_c", "doc"]
	for i in named.size():
		people.append({"who": named[i], "near": floor_c, "spread": 4.5, "seed": i + 1, "dir": rng.randi() % 4, "dance": i % 2 == 0})
	for k in 8:
		var lk := ChibiArt.PilotArt.random_look(rng)
		people.append({"who": "guest8_%d" % k, "look": lk, "near": floor_c, "spread": 5.5, "seed": 40 + k, "dir": rng.randi() % 4, "dance": k < 5})
	return {"no_crew": true, "levels": {"commercial": {"people": people, "spawn": w + Vector2(0.0, 2.0)}}}


## The strike over: Ossa's gear back in the locker (your own on again), the gift in your bag; the mission done.
func _strike_done() -> void:
	var st = GameState.story
	_return_gear()
	st.set_flag("w58_drinks", true)
	st.set_flag("w58_sk", "done")
	_set_phase("after58")
	GameState.log_msg("[Story] Package 58 is done: the Red Talon Roost is gone. (Package 59, the way to the Cluster, comes next.)", GameState.COL_GOOD)


func _return_gear() -> void:
	var g = GameState.gear
	var st = GameState.story
	if bool(flags().get("w58_gear_lent", false)):
		var own: Dictionary = flags().get("w58_gear_own", {})
		var d: Dictionary = g.to_dict()
		for k in ["suit", "weapons", "belt", "grenades", "gr_sel", "drones", "features"]:
			if own.has(k):
				d[k] = own[k]
		g.from_dict(d)
		g.refill()
		st.flags.erase("w58_gear_lent")
	if not bool(flags().get("w58_gifted", false)):
		st.set_flag("w58_gifted", true)
		g.add_item("suit_mil_light:C", 1)
		g.add_item("dr_laser:C", 1)
		GameState.log_msg("Ossa's gift: a Light Combat Suit and a Laser Drone (in your bag). Her gear is back in her locker.", GameState.COL_GOOD)


## (Luz: no game over in the story) fallen on foot at the relay: Rook gets you back to the drone, Ossa's people fly
## you home; you wake at Dan's, the relay to try again (a fresh one). Your lent gear stays with you.
func _foot_rescue(_reason: String) -> bool:
	if phase != "relay":
		return false
	var g = main.ground
	if g == null or not is_instance_valid(g) or String(g._site.get("story", "")) != "relay":
		return false
	var st = GameState.story
	for fl in ["w58_relay_intro", "w58_coords", "w58_overload"]:
		st.flags.erase(fl)
	st.set_flag("w58_relay_try", int(flags().get("w58_relay_try", 0)) + 1)
	st.set_flag("w58_relay_site", _relay_site())
	_relay_said = {}
	_overload_t = -1.0
	_show_overload(false)
	GameState.gear.refill()
	var f := GameState.active()
	var dan_st := String(flags().get("w58_dan_st", ""))
	var beyond := Universe.special_system("beyond")
	var sd := Universe.find_station(beyond, dan_st)
	if sd.is_empty() or f == null:
		return false
	main.close_deck(false)
	main._close_planet_map()
	f.system_id = beyond
	f.docked_at = dan_st
	f.position = sd.get("pos", Vector2.ZERO)
	GameState.current_system = beyond
	GameState.log_msg("You went down at the relay. Rook dragged you back to the drone, and Ossa's people flew you home.", GameState.COL_BAD)
	_foot_wake.call_deferred(sd)
	return true


func _foot_wake(sd: Dictionary) -> void:
	if main == null:
		return
	main.load_system(Universe.special_system("beyond"))
	main.station_panel.close()
	main._wake_at(sd)
	await get_tree().create_timer(2.2 * (0.1 if quick else 1.0)).timeout
	GameState.story.show.emit("dialogue", {"id": "dan_relay_wake", "mission": FIGHT})
