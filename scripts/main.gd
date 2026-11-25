extends Node
## Entry point. One continuous SystemView per star system (fixed zoom levels).
## Galaxy map as an overlay (M). On a gate jump: hyperspace tunnel + star map, then the new system.
## Station interface (StationUI) after docking, ship menu (ShipMenu) on I.
## Started from the main menu (scenes/menu.tscn) via SaveGame.start_new / start_load.
## Player input goes through the Commands bus; this node registers the SystemView there.

var view: SystemView
var hud: HUD
var story_ui: StoryUI
var galaxy: GalaxyMap
var station_panel: StationUI
var ship_menu: ShipMenu
var pilot_window                       # package 29: skills, skill tree, the pilot (U)
const PilotWindowScript = preload("res://scripts/ui/pilot_window.gd")
## Split screen (Luz, 25 Nov 2026): while the picture is in two halves a window stands in the half of the player who
## opened it and the other goes on playing. `halves`: a place for each player's windows (scripts/ui/win_half.gd).
## The first player's windows are the ones above; the second player's own are made when first asked for.
const WinHalf = preload("res://scripts/ui/win_half.gd")
const SeatMenu = preload("res://scripts/ui/seat_menu.gd")
var halves: Array = []
var pilot_window2 = null
var ship_menu2: ShipMenu = null
var galaxy2: GalaxyMap = null
var seat_menu: Node = null
var _pause_seat := -1                   # whose windows it was before a pause (the pause is theirs who pressed it)
var loss_window                        # package 31a: the ship is lost – buy it back?
var warmup                             # package 35: pictures made ahead of time (scripts/core/warmup.gd)
var loading: CanvasLayer               # package 35: the short loading screen at the start
var _loading_bar: ProgressBar
var _loading_t := 0.0
var _loading_total := 1
const LossWindowScript = preload("res://scripts/ui/loss_window.gd")
var transit_fx: TransitOverlay
var pause_menu: PauseMenu
var debug_menu: DebugMenu
var in_hyperspace := false


func _ready() -> void:
	randomize()
	var is_new: bool = SaveGame.pending.get("mode", "new") != "load"
	SaveGame.start_pending()
	hud = HUD.new()
	add_child(hud)
	story_ui = StoryUI.new()                          # package 55: dialogues, radio calls, tips, the tracked mission
	story_ui.main = self
	add_child(story_ui)
	galaxy = GalaxyMap.new()
	add_child(galaxy)
	station_panel = StationUI.new()
	add_child(station_panel)
	ship_menu = ShipMenu.new()
	add_child(ship_menu)
	pilot_window = PilotWindowScript.new()
	add_child(pilot_window)
	var hl := CanvasLayer.new()
	hl.layer = 25
	add_child(hl)
	for hs in 2:
		var hh = WinHalf.new()
		hh.seat = hs
		hl.add_child(hh)
		halves.append(hh)
	seat_menu = SeatMenu.new()
	seat_menu.main = self
	add_child(seat_menu)
	loss_window = LossWindowScript.new()
	add_child(loss_window)
	GameState.ship_lost.connect(func(o):
		galaxy.close()
		ship_menu.close()
		pilot_window.close()
		loss_window.open(o)
		_update_input())
	GameState.pilot_fell.connect(func(o):                  # 0.7.53.14 (Luz): down on foot – the same window, for the gear
		galaxy.close()
		ship_menu.close()
		pilot_window.close()
		loss_window.open(o)
		_update_input())
	loss_window.closed.connect(_update_input)
	loss_window.closed.connect(func():                       # 0.7.53.14: the gear bought back – the pilot wears it again
		if ground != null and is_instance_valid(ground) and ground.pilot != null:
			ground.pilot.look = ground.pilot_look())
	loss_window.closed.connect(func(): _wake_after_loss.call_deferred())     # 0.7.51.4: then you wake in the clinic
	transit_fx = TransitOverlay.new()
	add_child(transit_fx)
	pause_menu = PauseMenu.new()
	add_child(pause_menu)
	debug_menu = DebugMenu.new()
	add_child(debug_menu)

	hud.galaxy_requested.connect(toggle_galaxy)
	hud.station_requested.connect(open_station)
	hud.ship_menu_requested.connect(toggle_ship_menu)
	hud.pilot_window_requested.connect(toggle_pilot_window)
	hud.pilot_tab_requested.connect(toggle_pilot_window)
	galaxy.routes_changed.connect(_on_routes_changed)
	galaxy.closed.connect(_update_input)
	station_panel.closed.connect(_update_input)
	station_panel.closed.connect(func():
		if ground != null and is_instance_valid(ground):
			ground.on_service_closed())
	station_panel.walk_requested.connect(open_deck)          # package 49
	ship_menu.closed.connect(func(): station_panel.rebuild())
	station_panel.ship_menu_requested.connect(open_ship_menu)
	ship_menu.closed.connect(_update_input)
	pilot_window.closed.connect(_update_input)
	pause_menu.closed.connect(_pause_done)
	GameState.ship_jumped_out.connect(_on_jumped_out)
	GameState.ship_arrived_system.connect(_on_arrived_system)
	GameState.active_changed.connect(_on_active_changed)
	GameState.anomaly_revealed.connect(func(_s, _a): hud.refresh_overview())

	warmup = load("res://scripts/core/warmup.gd").new()
	add_child(warmup)
	warmup.queue_system(GameState.current_system)
	warmup.queue_layouts()                          # package 42c: all systems behind the loading screen
	_show_loading()
	load_system(GameState.current_system)
	if is_new and String(GameState.story.flags.get("intro_stage", "")) == "four":
		_start_intro_four.call_deferred()                 # package 56: the story goes on – Dan's infirmary
	elif is_new:
		GameState.log_msg("Welcome to Spacefarer, %s! Press H for controls." % GameState.pilot_name, GameState.COL_GOOD)
		if Universe.test_mode:
			GameState.log_msg("TEST SYSTEM: every station, planet and asteroid type. Saving is disabled. F12 = debug menu.", GameState.COL_WARN)
		GameState.log_msg("Tip: click an object in the overview on the right to warp there.")
	else:
		GameState.log_msg("Game loaded. Welcome back, %s." % GameState.pilot_name, GameState.COL_GOOD)
		var f := GameState.active()
		if f != null and f.docked_at.begins_with("land:"):
			_resume_landed.call_deferred()                # still down on a planet: back onto the spot where you saved (Luz, 24 Nov 2026)
			if String(GameState.story.flags.get("intro_stage", "")) == "58":
				_start_dan_work.call_deferred("load")      # package 58 (Luz: Ossa was missing): the story runs down here too
		elif f != null and f.docked_at != "" and String(GameState.story.flags.get("intro_stage", "")) in ["four", "four_walk"]:
			_start_intro_four.call_deferred()             # package 56: saved in the middle of sequence 4 – it starts again
		elif String(GameState.story.flags.get("intro_stage", "")) in ["five", "five_fly"]:
			if String(GameState.story.flags["intro_stage"]) == "five_fly":
				load("res://scripts/ground/intro_five.gd").tidy()     # saved in the flight training: the drone back to Dan
			_start_intro_five.call_deferred("hangar")      # package 56: sequence 5 starts again at Betty's stairs
		elif f != null and f.docked_at != "" and String(GameState.story.flags.get("intro_stage", "")) == "five_back":
			_start_intro_five.call_deferred("back")        # Dan waits in the bar
		elif f != null and f.docked_at != "" and String(GameState.story.flags.get("intro_stage", "")) == "six":
			_start_intro_six.call_deferred("load")         # sequence 6: Dan in the bar
		elif f != null and String(GameState.story.flags.get("intro_stage", "")) == "58":
			_start_dan_work.call_deferred("load")          # package 58: working for Dan
			if f.docked_at != "" and String(GameState.story.flags.get("w58_phase", "board")) == "board":
				_start_intro_six.call_deferred("load")     # Little Darling waits in the hangar – on foot in the bar
			elif f.docked_at != "":
				open_station.call_deferred()
		elif f != null and f.docked_at != "":
			open_station.call_deferred()

	if "--smoketest" in OS.get_cmdline_user_args():
		add_child(load("res://scripts/debug/smoke_test.gd").new())


var last_load_ms := 0.0                 # package 35: how long building the last system took (debug)


func load_system(sys: int) -> void:
	var t0 := Time.get_ticks_usec()
	if view != null and is_instance_valid(view):
		view.sync_to_fits()
		remove_child(view)
		view.queue_free()
	GameState.current_system = sys
	view = SystemView.new()
	add_child(view)
	move_child(view, 0)
	view.build(sys)
	last_load_ms = float(Time.get_ticks_usec() - t0) / 1000.0
	view.station_docked.connect(_on_station_docked)
	view.descended.connect(_on_descended)                       # package 50
	view.descent_ending.connect(_on_descent_ending)
	view.ascended.connect(_update_input)
	Commands.world = view
	hud.set_view(view)
	_update_input()


func _update_input() -> void:
	var overlay: bool = (planet_map != null and is_instance_valid(planet_map)) or (flight != null and is_instance_valid(flight)) or (hatch != null and is_instance_valid(hatch)) or galaxy.visible or station_panel.visible or ship_menu.visible or pilot_window.visible or loss_window.visible or in_hyperspace
	if view != null and is_instance_valid(view):
		view.input_enabled = not overlay and ground == null
	if ground != null and is_instance_valid(ground):
		ground.input_enabled = not overlay and not pause_menu.visible


# ---------------------------------------------------------------- Package 49: on foot

var ground: GroundView = null
var planet_map: PlanetMap = null        # package 50: the planet below, its places to land
var flight: FlightScene = null          # 0.7.50.3: the flight down through the air to the place
var hatch: CityHatch = null             # 0.7.50.5: a city's landing hatch
var _fade: ColorRect = null             # 0.7.50.3: flashes and fades over everything
var _fade_tw: Tween = null


## Fades the screen to a colour (alpha 1) or back (alpha 0) – over everything.
func fade(col: Color, secs: float) -> Tween:
	if _fade == null:
		var cl := CanvasLayer.new()
		cl.layer = 40
		add_child(cl)
		_fade = ColorRect.new()
		_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_fade.color = Color(col, 0.0)
		cl.add_child(_fade)
	if _fade_tw != null and _fade_tw.is_valid():
		_fade_tw.kill()
	_fade_tw = create_tween()
	_fade_tw.tween_property(_fade, "color", col, secs)
	return _fade_tw


## The way down ends: a white flash where there is air (the heat), then black.
func _on_descent_ending(atmo: bool) -> void:
	fade(Color(1.0, 0.95, 0.85, 1.0) if atmo else Color(0, 0, 0, 1.0), 0.55)
	_fade_tw.tween_property(_fade, "color", Color(0, 0, 0, 1.0), 0.35)


## Gets out of the ship and walks the deck of the station it is docked at.
func open_deck() -> void:
	var f := GameState.active()
	if f == null or f.docked_at == "" or view == null:
		return
	var st: Dictionary = view.stations[f.docked_at].data if view.stations.has(f.docked_at) else {}
	if st.is_empty() and not f.docked_at.begins_with("land:"):
		return
	if st.is_empty():
		st = Commands.docked_station()                 # package 58: a city – its deck again from its window
		if st.is_empty() or not bool(st.get("city", false)):
			return
	GameState.gear.aboard()
	_open_ground_at(st)


## Which of a station's (or city's, or settlement's) services there are – id -> "" or why it is closed.
func _services_for(st: Dictionary) -> Dictionary:
	var avail := {}
	station_panel.station = st
	station_panel.view = view
	for svc2 in GameData.services:
		avail[String(svc2["id"])] = station_panel.service_available(svc2)
	for k in avail.keys():
		if String(avail[k]).begins_with("Not offered") or String(avail[k]).begins_with("No ") or String(avail[k]).begins_with("Only in"):
			avail.erase(k)                         # what this station does not have at all gets no door
	station_panel.close()
	return avail


## The walkable deck of a station – or of a city (0.7.50.5): which of its services have a door.
func _open_ground_at(st: Dictionary) -> void:
	var avail := _services_for(st)
	close_deck(false)
	ground = GroundView.new()
	ground.name = "Ground"
	add_child(ground)
	var dw = get_meta("dan_work", null)
	if dw != null and is_instance_valid(dw) and dw.has_method("ground_mode"):
		ground.story_mode = dw.ground_mode(st)          # package 58: Dan in his bar, Ossa Kell at your ship on Brine
	ground.setup_station(st, avail, GameState.bar_offers(st) if avail.has("bar") else [], GameState.current_system)
	ground.used.connect(_on_deck_use)
	GameState.codex.event("on_foot")
	_update_input()


# ---------------------------------------------------------------- package 50: landing

## Down on a body: the planet map with its places to land.
func _on_descended(body_id: String) -> void:
	var f := GameState.active()
	if f == null:
		return
	var body := Universe.find_body(f.system_id, body_id)
	if body.is_empty():
		f.docked_at = ""
		return
	_close_planet_map()
	planet_map = PlanetMap.new()
	add_child(planet_map)
	planet_map.open(f.system_id, body)
	planet_map.land.connect(func(site: Dictionary): fly_down_to(body, site))
	planet_map.back.connect(func(): take_off())
	GameState.codex.event("landing")
	if _fade != null:
		fade(Color(0, 0, 0, 0), 0.9)                              # the map fades in out of the black
	_update_input()


func _close_planet_map() -> void:
	if planet_map != null and is_instance_valid(planet_map):
		planet_map.queue_free()
	planet_map = null


## The flight down through the air to the place you picked – then the touchdown.
func fly_down_to(body: Dictionary, site: Dictionary) -> void:
	_close_planet_map()
	flight = FlightScene.new()
	add_child(flight)
	flight.open(body, site)
	flight.finished.connect(func():
		var tw := fade(Color(0, 0, 0, 1), 0.35)
		tw.finished.connect(func():
			if flight != null and is_instance_valid(flight):
				flight.queue_free()
			flight = null
			if String(site.get("kind", "")) == "city":
				_city_hatch(body, site, true)             # 0.7.50.5: a city takes the ship in below the ground
			else:
				land_at(body, site, true)
			fade(Color(0, 0, 0, 0), 0.6)))
	_update_input()


## Down at a place: the landing field, your ship on the pad (touchdown: she comes down onto it first).
func land_at(body: Dictionary, site: Dictionary, touchdown: bool = false) -> void:
	_close_planet_map()
	close_deck(false)
	GameState.gear.aboard()                                  # 0.7.51.3: out of the ship charged and well
	ground = GroundView.new()
	ground.name = "Ground"
	add_child(ground)
	if String(site.get("kind", "")) in ["outpost", "mine", "research"]:
		# 0.7.50.10: a settlement – its pads, its street and shops; you are there by the landing drone
		var town := Universe.city_station(GameState.current_system, body, site)
		var f2 := GameState.active()
		if f2 != null:
			f2.docked_at = String(town["id"])
		Economy.prepare_station(town, GameState.current_system)
		var av := _services_for(town)
		ground.setup_settlement(body, site, town, av, GameState.bar_offers(town) if av.has("bar") else [], GameState.current_system, touchdown)
		ground.used.connect(_on_deck_use)
		GameState.log_msg("Down at %s on %s by the landing drone." % [String(site["name"]), String(body["name"])], GameState.COL_GOOD)
		GameState.codex.event("settlement")
		_update_input()
		return
	ground.setup_landing(body, site, GameState.current_system, touchdown, String(site.get("kind", "")) != "city")
	ground.used.connect(_on_deck_use)
	GameState.log_msg("Landed at %s on %s." % [String(site["name"]), String(body["name"])], GameState.COL_GOOD)
	_update_input()


## Package 50b (0.7.50.5): the city's landing hatch – down: the ship sinks below the ground, then you are in the
## city's hangar; up: she rises out of it and climbs away.
func _city_hatch(body: Dictionary, site: Dictionary, down: bool, dest: String = "orbit") -> void:
	if Universe.is_giant(body):
		# 0.7.54.3 (Luz): a cloud city has no hatch – the flight brought her in through the hangar's gate; out again
		# the same way, up through the cloud decks
		if down:
			enter_city(body, site)
		else:
			_cloud_climb(body, site, dest)
		return
	if hatch != null and is_instance_valid(hatch):
		hatch.queue_free()
	hatch = CityHatch.new()
	add_child(hatch)
	hatch.open(body, site, down)
	var h := hatch
	hatch.finished.connect(func():
		if down:
			var tw := fade(Color(0, 0, 0, 1), 0.4)
			tw.finished.connect(func():
				if is_instance_valid(h):
					h.queue_free()
				hatch = null
				enter_city(body, site)
				fade(Color(0, 0, 0, 0), 0.7))
		else:
			if is_instance_valid(h):
				h.queue_free()
			hatch = null
			take_off(dest))
	_update_input()


func _cloud_climb(body: Dictionary, site: Dictionary, dest: String) -> void:
	_close_planet_map()
	flight = FlightScene.new()
	add_child(flight)
	flight.open_cloud(body, site, true)
	flight.finished.connect(func():
		var tw := fade(Color(0, 0, 0, 1), 0.35)
		tw.finished.connect(func():
			if flight != null and is_instance_valid(flight):
				flight.queue_free()
			flight = null
			take_off(dest)
			fade(Color(0, 0, 0, 0), 0.5)))
	_update_input()


## Into a city: it works like a station – you are in its hangar beside your ship, the lifts take you to its
## shopping street and up to the bar high in its towers.
func enter_city(body: Dictionary, site: Dictionary) -> void:
	var f := GameState.active()
	if f == null:
		return
	_close_planet_map()
	close_deck(false)
	var city := Universe.city_station(GameState.current_system, body, site)
	f.docked_at = String(city["id"])
	Economy.prepare_station(city, GameState.current_system)
	_open_ground_at(city)
	GameState.log_msg("Landed in %s on %s: your ship is in the city's hangars." % [String(site["name"]), String(body["name"])], GameState.COL_GOOD)
	GameState.codex.event("city")


## Out of the city: the hatch opens, the ship rises and climbs away (dest: "orbit" or "map" – 0.7.50.15).
func leave_city(dest: String = "orbit") -> void:
	var f := GameState.active()
	if f == null:
		return
	var st := Commands.docked_station()
	var body := Universe.find_body(f.system_id, String(st.get("body", "")))
	var site := {"id": String(st.get("site", "")), "name": String(st.get("name", "")), "kind": "city"}
	var tw := fade(Color(0, 0, 0, 1), 0.35)
	tw.finished.connect(func():
		close_deck(false)
		_city_hatch(body, site, false, dest)
		fade(Color(0, 0, 0, 0), 0.5))


## Up again: from the landing field or the planet map back to orbit – the ascent. 0.7.50.15 (Luz): or, dest "map",
## back to the planet map to pick another place.
func take_off(dest: String = "orbit") -> void:
	var f := GameState.active()
	_close_planet_map()
	close_deck(false)
	if f == null or not f.docked_at.begins_with("land:"):
		_update_input()
		return
	var body_id := f.docked_at.substr(5).split("|")[0]
	GameState.gear.aboard()                                  # 0.7.51.3: back aboard – charged, the medbay sees to you
	if dest == "map":
		f.docked_at = "land:" + body_id
		fade(Color(0, 0, 0, 1), 0.01)
		_fade.color = Color(0, 0, 0, 1)                           # from black into the map
		_on_descended(body_id)
		return
	f.docked_at = ""
	if view != null and is_instance_valid(view):
		view.start_ascent(body_id)
	fade(Color(1.0, 0.95, 0.85, 0.0), 0.01)                       # (makes sure the fade layer is there)
	_fade.color = Color(1.0, 0.95, 0.85, 1.0)                     # out of the air in a flash …
	fade(Color(1.0, 0.95, 0.85, 0.0), 1.1)                        # … that clears over the ascent
	_update_input()


## 0.7.50.15 (Luz): back up by the landing drone – it climbs off the pad and the ship catches it; then on to orbit
## or the planet map.
func drone_up(body: Dictionary, site: Dictionary, dest: String) -> void:
	close_deck(false)
	if flight != null and is_instance_valid(flight):
		flight.queue_free()
	flight = FlightScene.new()
	add_child(flight)
	flight.open_up(body, site)
	fade(Color(0, 0, 0, 0), 0.4)
	flight.finished.connect(func():
		var tw := fade(Color(0, 0, 0, 1), 0.35)
		tw.finished.connect(func():
			if flight != null and is_instance_valid(flight):
				flight.queue_free()
			flight = null
			take_off(dest)))
	_update_input()


# ---------------------------------------------------------------- 0.7.51.4: the clinic

## Wakes the pilot in the clinic of a station or city (its deck opens there).
func _wake_at(st: Dictionary) -> void:
	_open_ground_at(st)
	if ground != null and is_instance_valid(ground):
		ground.wake_in_clinic()
	fade(Color(0, 0, 0, 1), 0.01)
	_fade.color = Color(0, 0, 0, 1)
	fade(Color(0, 0, 0, 0), 1.6)


## After the ship was lost (and the buy-back window is closed): in the clinic of the station she was rebuilt at.
func _wake_after_loss() -> void:
	if not GameState.wake_pending:
		return
	GameState.wake_pending = false
	var f := GameState.active()
	if f != null and f.docked_at != "" and view != null and view.stations.has(f.docked_at):
		_wake_at(view.stations[f.docked_at].data)


## The body gave out on foot: found and brought to the nearest city with a clinic in this system – your ship is
## taken to its hangar – or, if there is none, to the last station (the ship with you). What was in the pockets is
## gone.
func _fallen(reason: String = "") -> void:
	if GameState.story_foot_guard.is_valid() and bool(GameState.story_foot_guard.call(reason)):
		return                                           # package 58, part 7: the story takes care of it
	var f := GameState.active()
	GameState.gear.fall()
	var sys := GameState.current_system
	var here := f.docked_at.substr(5).split("|")[0] if f != null and f.docked_at.begins_with("land:") else ""
	close_deck(false)
	_close_planet_map()
	if f == null:
		return
	var city := nearest_clinic_city(sys, here)
	var how := "You went down in the fight." if reason == "fight" else "You collapsed outside."      # package 52
	if not city.is_empty():
		f.docked_at = String(city["id"])
		Economy.prepare_station(city, sys)
		GameState.log_msg(how + " They found you and brought you to %s: your ship waits in its hangar." % String(city.get("name", "the city")), GameState.COL_BAD)
		GameState.fall_open(String(city.get("name", "the city")), "Found and brought to its clinic: your ship waits in its hangar.")     # 0.7.53.14
		_wake_at(city)
		return
	var st := GameState._respawn_station()
	f.system_id = int(GameState.last_station.get("system", Universe.home_system))
	f.docked_at = String(st["id"])
	f.position = st["pos"]
	if view != null and is_instance_valid(view) and view.player != null and is_instance_valid(view.player):
		view.player.queue_free()
		view.player = null
	GameState.log_msg(how + " There is no clinic in this system: they flew you and your ship to %s." % String(st.get("name", "the station")), GameState.COL_BAD)
	GameState.fall_open(String(st.get("name", "the station")), "No clinic in that system: they flew you and your ship here.")     # 0.7.53.14
	GameState.wake_pending = true
	GameState.active_changed.emit()
	_wake_after_loss.call_deferred()


## The nearest city with a clinic in a system – on the body you were on first, else any. {} if there is none.
func nearest_clinic_city(sys: int, body_id: String = "") -> Dictionary:
	var L := Universe.get_layout(sys)
	var bodies: Array = L["planets"] + L.get("moons", [])
	bodies.sort_custom(func(a, b): return String(a["id"]) == body_id and String(b["id"]) != body_id)
	for b2 in bodies:
		if not Universe.landable(b2):
			continue
		for s in Universe.landing_sites(sys, b2):
			if String(s["kind"]) == "city":
				return Universe.city_station(sys, b2, s)
	return {}


## Back into the ship (open: show the station window again).
## Package 56: sequence 4 – onto the deck of Dan's station, into the infirmary (scripts/ground/intro_four.gd).
func _start_intro_four() -> void:
	if loading != null and is_instance_valid(loading):
		get_tree().create_timer(0.3).timeout.connect(_start_intro_four)     # after the loading screen
		return
	var f := GameState.active()
	if f == null or f.docked_at == "":
		return
	open_deck()
	if ground == null:
		return
	var i4 = load("res://scripts/ground/intro_four.gd").new()
	i4.main = self
	add_child(i4)
	i4.begin()


## Package 56: sequence 5 – the flight training (scripts/ground/intro_five.gd); where: "bar", "hangar" or "back".
func _start_intro_five(where: String = "hangar") -> void:
	if loading != null and is_instance_valid(loading):
		get_tree().create_timer(0.3).timeout.connect(_start_intro_five.bind(where))
		return
	var f := GameState.active()
	if f == null or f.docked_at == "":
		return
	if ground == null or not is_instance_valid(ground):
		open_deck()
	if ground == null:
		return
	for n in get_children():
		if n.get_script() == load("res://scripts/ground/intro_five.gd"):
			n.queue_free()
	var i5 = load("res://scripts/ground/intro_five.gd").new()
	i5.main = self
	add_child(i5)
	i5.begin(where)


## Package 56: sequence 6 – Dan in the bar, his deal (scripts/ground/intro_six.gd); where: "bar", "talk" or "load".
func _start_intro_six(where: String = "load") -> void:
	if loading != null and is_instance_valid(loading):
		get_tree().create_timer(0.3).timeout.connect(_start_intro_six.bind(where))
		return
	var f := GameState.active()
	if f == null or f.docked_at == "":
		return
	if ground == null or not is_instance_valid(ground):
		open_deck()
	if ground == null:
		return
	for n in get_children():
		if n.get_script() == load("res://scripts/ground/intro_six.gd"):
			n.queue_free()
	var i6 = load("res://scripts/ground/intro_six.gd").new()
	i6.main = self
	add_child(i6)
	i6.begin(where)


## Package 58: working for Dan (scripts/ground/dan_work.gd); where: "yes" (the deal just taken) or "load".
func _start_dan_work(where: String = "load") -> void:
	for n in get_children():
		if n.get_script() == load("res://scripts/ground/dan_work.gd") or n.get_script() == load("res://scripts/ui/guided_tour.gd"):
			n.queue_free()                                # an old controller and its tour go
	var w = load("res://scripts/ground/dan_work.gd").new()
	w.main = self
	set_meta("dan_work", w)                              # only the newest controller works
	add_child(w)
	w.begin(where)


func close_deck(open_window: bool = true) -> void:
	if ground != null and is_instance_valid(ground):
		ground.leave_ground()                          # review 7 W1/K2: the site's state kept, who is down stays down
		ground.queue_free()
	ground = null
	if open_window:
		open_station()
	_update_input()


func _on_deck_use(z: Dictionary) -> void:
	match String(z.get("kind", "")):
		"collapse":
			_fallen(String(z.get("reason", "")))               # 0.7.51.4: you wake in a clinic (package 52: also shot down)
		"exit":
			var dest := String(z.get("dest", "orbit"))
			if ground != null and is_instance_valid(ground) and ground.level in ["landing", "settlement"]:
				if ground._lander and z.get("animate", false):
					drone_up(ground._body, ground._site, dest)       # 0.7.50.15: the drone climbs, the ship catches it
				else:
					take_off(dest)
			elif ground != null and is_instance_valid(ground) and ground.station.get("city", false) and z.has("dest"):
				leave_city(dest)
			else:
				close_deck(true)                         # package 58 (Luz): a city's stairs too – its window opens
		"service", "crew":
			var f := GameState.active()
			var st: Dictionary = Commands.docked_station() if f != null and f.docked_at != "" else {}
			if st.is_empty():
				close_deck(false)
				return
			station_panel.on_foot = true
			station_panel.open(st, view)
			station_panel.open_service(String(z["id"]))
			_update_input()


## The deck goes away when the ship is no longer docked where the pilot walks (undocked, lost, teleported).
func _check_deck() -> void:
	if ground == null or not is_instance_valid(ground):
		return
	var f := GameState.active()
	if ground.level in ["landing", "dungeon"]:                # 0.7.53.2: the ruin belongs to the landing site
		if f == null or not f.docked_at.begins_with("land:"):
			close_deck(false)
		return
	if f == null or f.docked_at == "" or String(ground.station.get("id", "")) != f.docked_at:
		close_deck(false)


func toggle_galaxy() -> void:
	if galaxy.visible:
		if not galaxy.transit_mode:
			galaxy.close()
	else:
		station_panel.close()
		ship_menu.close()
		galaxy.open()
	_update_input()


func toggle_ship_menu() -> void:
	if ship_menu.visible:
		ship_menu.close()
	else:
		open_ship_menu()


## Package 29: the Pilot window – also over the station. 0.5.30.5: U always opens the Pilot tab (Info);
## the HUD hint for tiles / perk points opens the tab it is about.
func toggle_pilot_window(p_tab: int = 0, seat: int = 0) -> void:
	if seat == 1:
		_toggle_two("pilot", p_tab)
		return
	if pilot_window.visible:
		pilot_window.close()
	elif not in_hyperspace:
		galaxy.close()
		ship_menu.close()
		_halves_step()                                   # (split screen: in its half before it lays itself out)
		if p_tab == 0:
			pilot_window.sub = 0
		pilot_window.open(p_tab)
	_update_input()


# ---------------------------------------------------------------- split screen: a window in its player's half

## Is the picture in two halves right now (on foot, both of you free to go)?
func halves_on() -> bool:
	return Players.split and GameState.has_pilot2() and ground != null and is_instance_valid(ground) and ground.split_open()


## The pilot window of a player (the second player's is made when first asked for, in their half).
func _pilot_win(seat: int):
	return pilot_window if seat == 0 else _win2("pilot")


## A window of the second player's own: "pilot", "ship", "galaxy". Each is the first player's window's own class,
## made when first asked for, standing in their half.
func _win2(kind: String):
	match kind:
		"pilot":
			if pilot_window2 == null:
				pilot_window2 = PilotWindowScript.new()
				pilot_window2.seat = 1
				halves[1].take(pilot_window2)
				pilot_window2.closed.connect(_update_input)
			return pilot_window2
		"ship":
			if ship_menu2 == null:
				ship_menu2 = ShipMenu.new()
				ship_menu2.seat = 1
				halves[1].take(ship_menu2)
				ship_menu2.closed.connect(_update_input)
			return ship_menu2
		"galaxy":
			if galaxy2 == null:
				galaxy2 = GalaxyMap.new()
				galaxy2.seat = 1
				halves[1].take(galaxy2)
				galaxy2.closed.connect(_update_input)
			return galaxy2
	return null


func _wins2() -> Array:
	return [pilot_window2, ship_menu2, galaxy2].filter(func(w): return w != null)


## The second player's window of this kind opens over their half (again: it shuts). One of theirs at a time.
func _toggle_two(kind: String, p_tab: int = 0) -> void:
	if not halves_on() or in_hyperspace:
		return
	GameState.ship_along()
	var w = _win2(kind)
	var was: bool = w.visible
	for o in _wins2():
		if o.visible:
			o.close()
	if not was:
		_halves_step()                                   # (in its place before it lays itself out)
		match kind:
			"pilot":
				if p_tab == 0:
					w.sub = 0
				w.open(p_tab)
			"ship":
				w.open(view)
			"galaxy":
				w.open()
	_update_input()


## Each frame: the halves where the picture has them. The first player's windows stand in their half while the
## picture is in two and over the whole picture otherwise; the second player's are shut when it is one again.
func _halves_step() -> void:
	var on := halves_on()
	if on:
		var sp: Dictionary = ground._split
		for s in 2:
			var src: Control = sp["fa" if s == 0 else "fb"]
			(halves[s] as Control).position = src.position
			(halves[s] as Control).size = src.size
	for w in [pilot_window, ship_menu, galaxy]:
		if on and not halves[0].holds(w):
			w.set_meta("home_at", w.get_index())
			halves[0].take(w)
		elif not on and halves[0].holds(w):
			halves[0].vp.remove_child(w)
			add_child(w)
			move_child(w, mini(int(w.get_meta("home_at", get_child_count() - 1)), get_child_count() - 1))
	if not on:
		for w2 in _wins2():
			if w2.visible:
				w2.close()
	for s2 in 2:
		var any := false
		for c in halves[s2].vp.get_children():
			if (c is CanvasLayer or c is Control) and c.visible:
				any = true
		(halves[s2] as Control).visible = on and any
	if ground != null and is_instance_valid(ground):
		ground.two_busy = on and (halves[1] as Control).visible


## Something of a player's own into their half (the controller's window wheel).
func win_show(seat: int, n: Node) -> void:
	halves[seat].take(n)
	_halves_step()


func win_hide(_seat: int) -> void:
	_halves_step.call_deferred()


## The second player goes back: their window on top shuts; with none up the game pauses, for both.
func win_back(seat: int) -> void:
	if seat == 0:
		return
	var up: Array = _wins2().filter(func(w): return w.visible)
	if not up.is_empty():
		for w in up:
			w.close()
		_update_input()
	elif not in_hyperspace and not pause_menu.visible:
		pause_for(seat)


## … and what they picked on their window wheel, or with a window's key.
func win_action(seat: int, what: String) -> void:
	match what:
		"pilot_window":
			toggle_pilot_window(0, seat)
		"journal":
			open_journal(seat)
		"ship_menu":
			if seat == 1:
				_toggle_two("ship")
			else:
				toggle_ship_menu()
		"galaxy_map":
			if seat == 1:
				_toggle_two("galaxy")
			else:
				toggle_galaxy()
		_:
			if seat == 1 and ground != null and is_instance_valid(ground):
				ground.two_say("%s: not the second player's own yet." % String({"station": "The station's window", "help": "The help"}.get(what, what)))
				Audio.play("ui_error", "second player: no such window yet")


## The pause is theirs who pressed it (their device walks its menu) and holds the game for both.
func pause_for(seat: int) -> void:
	if Players.split and seat != Players.act_seat:
		_pause_seat = Players.act_seat
		Players.act_seat = seat
		Pad._pick_device()
	pause_menu.open()


func _pause_done() -> void:
	if _pause_seat >= 0:
		Players.act_seat = _pause_seat
		_pause_seat = -1
		Pad._pick_device()


## Whose key or button an event is (the second player's keyboard, or the controller Pad listens to).
func _event_seat(event: InputEvent) -> int:
	if not Players.split or not GameState.has_pilot2():
		return 0
	if event is InputEventKey or event is InputEventMouseButton:
		return 0 if Players.on_keys(0) else 1
	return Players.act_seat


func open_ship_menu() -> void:
	if in_hyperspace:
		return
	galaxy.close()
	ship_menu.open(view)
	_update_input()


func _on_routes_changed() -> void:
	if view != null:
		view.apply_route()


# ---------------------------------------------------------------- Hyperspace

func _on_jumped_out(f: ShipFitting) -> void:
	in_hyperspace = true
	if f.transit_to != null:
		warmup.queue_system(int(f.transit_to))       # package 35: the jump hides the loading of the next system
	view.remove_player()
	station_panel.close()
	ship_menu.close()
	if f.transit_kind == "wormhole":
		transit_fx.play("jump", "Wormhole → %s" % Universe.systems[int(f.transit_to)]["name"], 2.4)
	elif Universe.old_gate(int(f.transit_from)):
		transit_fx.play("jump", "Hyperspace jump (old gate) → %s" % Universe.systems[int(f.transit_to)]["name"], 2.6)      # package 40b
	else:
		transit_fx.play("jump", "Hyperspace jump → %s" % Universe.systems[int(f.transit_to)]["name"], 1.8)
	galaxy.open(true)
	_update_input()


func _on_arrived_system(f: ShipFitting) -> void:
	in_hyperspace = false
	galaxy.close()
	transit_fx.play("jump", "Arrival: %s" % Universe.systems[f.system_id]["name"], 1.0)
	load_system(f.system_id)
	if view != null and not GameState.pending_arrival.is_empty():
		view.play_arrival(GameState.pending_arrival)       # package 40b: out of the gate – or flung out
		GameState.pending_arrival = {}
	SaveGame.autosave.call_deferred()


func _on_active_changed() -> void:
	_check_deck()                                        # package 49
	var f := GameState.active()
	if f == null:
		return
	if f.system_id != GameState.current_system or view == null:
		load_system(f.system_id)
	else:
		view.sync_player()
		view.center_on_player()
	hud.rebuild_ship_panel()
	if station_panel.visible:
		station_panel.rebuild()


# ---------------------------------------------------------------- Station

func open_station() -> void:
	var f := GameState.active()
	if f == null or f.docked_at == "" or view == null:
		return
	var st: Dictionary = view.stations[f.docked_at].data if view.stations.has(f.docked_at) else {}
	if st.is_empty() and f.docked_at.begins_with("land:"):
		var cst := Commands.docked_station()             # package 58 (Luz): a city's window, aboard in its hangar
		if bool(cst.get("city", false)):
			st = cst
	if st.is_empty():
		return
	galaxy.close()
	ship_menu.close()
	station_panel.on_foot = false
	station_panel.open(st, view)
	_update_input()


## Package 58 (Luz): undocking in a city – up to orbit, or to the planet map for another place.
var _takeoff_layer: CanvasLayer = null


func ask_city_takeoff() -> void:
	var st := Commands.docked_station()
	station_panel.close()
	if _takeoff_layer != null and is_instance_valid(_takeoff_layer):
		_takeoff_layer.queue_free()
	_takeoff_layer = CanvasLayer.new()
	_takeoff_layer.layer = 26
	add_child(_takeoff_layer)
	Audio.play("ui_open", "city: take off")
	var c := CenterContainer.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_takeoff_layer.add_child(c)
	var p := UI.neon_panel(Color(0.4, 1.0, 0.6, 0.85), Color(0.03, 0.05, 0.06, 0.96), 2)
	p.custom_minimum_size = Vector2(440, 0)
	c.add_child(p)
	p.add_to_group("kbd_menu")
	var v := UI.vbox(8)
	p.add_child(v)
	v.add_child(UI.label("TAKE OFF", 20, Color(0.4, 1.0, 0.6)))
	var bname := String(Universe.find_body(GameState.current_system, String(st.get("body", ""))).get("name", "the planet"))
	v.add_child(UI.label("Out of %s, up through the hatch. Where to?" % String(st.get("name", "the city")), 13, UI.TEXT_DIM))
	var go := func(dest: String):
		_takeoff_layer.queue_free()
		_takeoff_layer = null
		leave_city(dest)
	var b1 := UI.button("1.  Back to orbit", go.bind("orbit"))
	b1.alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(b1)
	var b2 := UI.button("2.  To the planet map: another place on %s" % bname, go.bind("map"))
	b2.alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(b2)
	v.add_child(UI.button("Stay [Esc]", func():
		_takeoff_layer.queue_free()
		_takeoff_layer = null
		open_station()))
	var esc := _EscCatcher.new()                       # Esc / ◯: stay
	esc.on_esc = func():
		if _takeoff_layer != null and is_instance_valid(_takeoff_layer):
			_takeoff_layer.queue_free()
			_takeoff_layer = null
			open_station()
	_takeoff_layer.add_child(esc)
	b1.grab_focus()
	_update_input()


func _on_station_docked(_station_id: String) -> void:
	GameState.story.event("dock", {"id": _station_id})        # package 55
	if not station_panel.visible and not galaxy.visible:
		open_station()
	SaveGame.autosave.call_deferred()


# ---------------------------------------------------------------- Save / load

## (Luz, 24 Nov 2026) A game loaded while you were down on a planet: back onto the very spot where you saved: the
## city, the settlement or the landing field, its level, the place you stood at. The planet's map only when the save
## does not say where that was (an older save, a site that is gone).
func _resume_landed() -> void:
	var f := GameState.active()
	if f == null or not f.docked_at.begins_with("land:"):
		return
	var body_id := String(f.docked_at.substr(5).split("|")[0])
	var spot: Dictionary = GameState.on_foot
	var body := Universe.find_body(f.system_id, body_id)
	var st_id := String(spot.get("station", ""))
	var want := String(st_id.split("|")[1]) if st_id.contains("|") else st_id
	var site := {}
	if not spot.is_empty() and not body.is_empty() and want != "":
		for s in Universe.landing_sites(f.system_id, body):
			if String(s.get("id", "")) == want:
				site = s
	if site.is_empty():
		_on_descended(body_id)
		return
	if String(site.get("kind", "")) == "city":
		enter_city(body, site)
	else:
		land_at(body, site, false)
	if ground != null and is_instance_valid(ground):
		ground.restore_spot(spot)


## Writes the live ship position back into its data before saving.
func prepare_save() -> void:
	GameState.on_foot = ground.save_spot() if (ground != null and is_instance_valid(ground)) else {}
	if ground != null and is_instance_valid(ground):
		ground.poi_save()                              # review 7 W1: what happened at the site goes into the save
	if view != null and is_instance_valid(view):
		view.sync_to_fits()


func quicksave() -> void:
	var err := SaveGame.save_game(SaveGame.QUICKSAVE, "Quicksave")
	GameState.log_msg("Quicksaved." if err == "" else err, GameState.COL_GOOD if err == "" else GameState.COL_WARN)


func quickload() -> void:
	if FileAccess.file_exists(SaveGame.slot_path(SaveGame.QUICKSAVE)):
		SaveGame.start_load(SaveGame.QUICKSAVE)
	else:
		GameState.log_msg("No quicksave yet (F5).", GameState.COL_WARN)


# ---------------------------------------------------------------- Keys

func _unhandled_input(event: InputEvent) -> void:
	handle_input(event)


## 0.7.53.15 (Luz): on foot, on the planet map, in the flight down or at a city's hatch the ship's keys (thrust, camera
## levels, modules, drones, wingmen, ship commands such as G = dock) are locked – a key the ground does not use does
## nothing there. The windows (map, ship menu, pilot, help), Escape, saving and the debug menu still work.
func ship_keys_locked() -> bool:
	return (ground != null and is_instance_valid(ground)) or (planet_map != null and is_instance_valid(planet_map)) \
		or (flight != null and is_instance_valid(flight)) or (hatch != null and is_instance_valid(hatch))


## Game hotkeys via rebindable actions (see Keybinds / Settings → Controls).
## Also called by SystemView for a clean middle-mouse click (no drag).
func handle_input(event: InputEvent) -> void:
	if loss_window != null and loss_window.visible:
		return                                            # review W3: a decision is needed first
	if not event.is_pressed() or event.is_echo():
		return
	var seat := _event_seat(event)                       # (split screen: a window is theirs whose key it was)
	if seat == 1 and halves_on():
		for wa in ["galaxy_map", "ship_menu", "pilot_window", "journal"]:
			if event.is_action_pressed(wa, false, true):
				win_action(1, wa)
				return
		if event.is_action_pressed("menu_back", false, true):
			win_back(1)
			return
	if event.is_action_pressed("galaxy_map", false, true):
		toggle_galaxy()
	elif event.is_action_pressed("ship_menu", false, true):
		toggle_ship_menu()
	elif event.is_action_pressed("pilot_window", false, true):
		toggle_pilot_window()
	elif event.is_action_pressed("journal", false, true):
		open_journal()
	elif event.is_action_pressed("station", false, true):
		if ground != null and is_instance_valid(ground):
			return                                         # 0.7.49.13: on foot, the station is around you
		if station_panel.visible:
			station_panel.close()
		else:
			open_station()
	elif event.is_action_pressed("help", false, true):
		hud.toggle_help()
	elif event.is_action_pressed("menu_back", false, true):
		if pilot_window.visible:
			pilot_window.close()
		elif ship_menu.visible:
			ship_menu.close()
		elif station_panel.visible:
			station_panel.close()
		elif galaxy.visible and not galaxy.transit_mode:
			galaxy.close()
		elif hud.help_panel.visible:
			hud.toggle_help()
		elif hud.selected_id != "":
			hud.show_selected("")
		elif not in_hyperspace:
			pause_menu.open()
	elif event.is_action_pressed("quicksave", false, true):
		quicksave()
	elif event.is_action_pressed("quickload", false, true):
		quickload()
	elif event.is_action_pressed("debug_menu", false, true):
		if Commands.cheats_enabled:
			debug_menu.toggle()
	elif ship_keys_locked():
		return                                            # 0.7.53.15 (Luz): on the ground the ship's keys do nothing
	elif event.is_action_pressed("boost", false, false) and view != null and view.player != null and is_instance_valid(view.player):
		var be: String = view.player.boost_error()            # 0.6.75.2: the thrust burst (Shift – modifiers ignored)
		if be == "":
			view.player.boost()
		elif not be.begins_with("Docked") and not be.begins_with("Thrust already"):
			GameState.log_msg(be, GameState.COL_WARN)
	elif event.is_action_pressed("cam_center", false, true):
		if view != null:
			view.center_on_player()
	else:
		for i in 4:
			if event.is_action_pressed(["zoom_combat", "zoom_recon", "zoom_orbit", "zoom_system"][i], false, true):
				if view != null:
					if i == 2 and view.player != null and is_instance_valid(view.player) and view.player.in_warp():
						GameState.log_msg("The Orbit view is not available during a warp.", GameState.COL_WARN)
					else:
						view.set_level(i)
				return
		for i in ShipFitting.FIRE_GROUPS:
			if event.is_action_pressed("module_%d" % (i + 1), false, true):
				hud.activate_index(i)                     # package 79: keys 1–8 – the fire groups
				return
		if event.is_action_pressed("drone_launch", false, true) and view != null and not in_hyperspace:
			Commands.execute({"type": "drone_launch", "count": 1})
			return
		if event.is_action_pressed("drone_launch_all", false, true) and view != null and not in_hyperspace:
			Commands.execute({"type": "drone_launch"})
			return
		if event.is_action_pressed("drone_recall", false, true) and view != null and not in_hyperspace:
			Commands.execute({"type": "drone_recall"})
			return
		# package 33: wingmen
		if event.is_action_pressed("wing_attack", false, true) and view != null and not in_hyperspace:
			Commands.execute({"type": "wing_attack"})
			return
		for ws in ["passive", "defensive", "aggressive"]:
			if event.is_action_pressed("wing_" + ws, false, true) and view != null:
				Commands.execute({"type": "wing_stance", "id": -1, "stance": ws})
				return
		for a in HUD.HOTKEY_COMMANDS:
			if event.is_action_pressed(a, false, true):
				if view != null and not in_hyperspace:
					hud.hotkey_command(a)
				return


# ---------------------------------------------------------------- Loading screen (package 35)

## A short loading screen when the game starts: the system's pictures are made behind it (at most a few seconds).
func _show_loading() -> void:
	loading = CanvasLayer.new()
	loading.layer = 120
	add_child(loading)
	var bg := ColorRect.new()
	bg.color = Color(0.015, 0.01, 0.03)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	loading.add_child(bg)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.add_child(c)
	var v := UI.vbox(14)
	c.add_child(v)
	var t := UI.label("SPACEFARER", 40, UI.NEON_CYAN)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var s2 := UI.label("Entering %s …" % Universe.systems[GameState.current_system]["name"], 16, UI.TEXT_DIM)
	s2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(s2)
	_loading_bar = UI.bar(UI.NEON_CYAN, 420)
	_loading_bar.custom_minimum_size = Vector2(420, 6)
	v.add_child(_loading_bar)
	_loading_total = maxi(warmup.pending(), 1)
	warmup.budget_ms = 24.0                        # behind the loading screen: as fast as it goes
	_loading_t = 0.0


func _process(delta: float) -> void:
	_check_deck()                                        # package 49: undocked, lost or moved – back from the deck
	_halves_step()                                       # split screen: each player's windows over their half
	if loading == null:
		return
	_loading_t += delta
	_loading_bar.max_value = float(_loading_total)
	_loading_bar.value = float(_loading_total - warmup.pending())
	if (warmup.done() and _loading_t > 0.4) or _loading_t > 8.0:
		warmup.budget_ms = 4.0
		var lay := loading
		loading = null
		var tw := create_tween()
		tw.tween_property(lay.get_child(0), "modulate:a", 0.0, 0.35)
		tw.tween_callback(lay.queue_free)


## Package 55: the journal – the pilot window on its Journal tab (again: closed).
func open_journal(seat: int = 0) -> void:
	var w = _pilot_win(seat)
	if w.visible and w.tab == w.TAB_JOURNAL:
		w.close()
		return
	if not w.visible:
		toggle_pilot_window(0, seat)
	if w.visible:
		w._set_tab(w.TAB_JOURNAL)


## Package 58: Esc (or ◯ in a menu) closes a small window – the city's take-off question.
class _EscCatcher extends Node:
	var on_esc: Callable

	func _input(e: InputEvent) -> void:
		if e.is_action_pressed("menu_back") or e.is_action_pressed("ui_cancel") or (e is InputEventKey and e.pressed and not e.echo and (e as InputEventKey).keycode == KEY_ESCAPE):
			get_viewport().set_input_as_handled()
			if on_esc.is_valid():
				on_esc.call()
