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
const GroundHalf = preload("res://scripts/ground/ground_half.gd")
const SeatMenu = preload("res://scripts/ui/seat_menu.gd")
var halves: Array = []
var pilot_window2 = null
var ship_menu2: ShipMenu = null
var galaxy2: GalaxyMap = null
var station_panel2: StationUI = null   # … their station window (a shop's or a service's counter on foot)
var loss_window2 = null                # … and their buy-back window after a fall
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
		if GameState.acting == 1:
			return                                         # (the second player's own fall: their window, in their half: _fall_step())
		galaxy.close()
		ship_menu.close()
		pilot_window.close()
		loss_window.open(o)
		_update_input())
	loss_window.closed.connect(_update_input)
	loss_window.closed.connect(func():                       # 0.7.53.14: the gear bought back – the pilot wears it again
		if ground != null and is_instance_valid(ground) and ground.pilot != null:
			GameState.with_seat(0, func(): ground.pilot.look = ground.pilot_look())
			ground.pilot.queue_redraw())
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
		view.eyes_off()                                    # (two looks in space: the HUDs come home before the view goes)
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
	view.eyes_hook = _on_eyes
	view.eye_scope = _eye_scope
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
##
## Split screen, apart places (rule 5: down alone is the clinic, as for a single player): `seat` is who fell. What
## was in the pockets is theirs, the buy-back window opens in their name. Where the other player ends up:
## - you are in different places of a city or station that has a clinic: only who fell wakes there (in their own
##   view), the other plays on;
## - else the ship is taken to the clinic's city, as for a single player, and with it both of you (there is one ship
##   that flies until the second player flies): the other is told.
func _fallen(reason: String = "", seat: int = 0) -> void:
	if seat == 0 and GameState.story_foot_guard.is_valid() and bool(GameState.story_foot_guard.call(reason)):
		return                                           # package 58, part 7: the story takes care of it
	var two_p: bool = Players.split and GameState.has_pilot2()
	var was_apart := apart()
	var f := GameState.active()
	var who := String(GameState.pilot_of(seat).get("name", "The other player")) if two_p else ""
	var how := "You went down in the fight." if reason == "fight" else "You collapsed outside."      # package 52
	if seat == 1:
		scope_in(1)
		GameState.gear.fall()
		scope_out()
	else:
		GameState.gear.fall()
	var fv = ground_of(seat)
	if was_apart and f != null and fv != null and fv._avail.has("clinic"):
		# a clinic in the very place you both walk in: who fell wakes there, the other plays on
		var here_name := String(fv.station.get("name", "the station"))
		if seat == 1:
			scope_in(1)
		fv._collapsed = false
		fv.input_enabled = true
		fv.wake_in_clinic()
		if seat == 1:
			scope_out()
		toast_to(1 - seat, "%s went down and was brought to the clinic here." % who)
		if seat == 1:
			scope_in(1)                                  # (their buy-back window opens in their half: _fall_step())
		GameState.log_msg(how + " They found you and brought you to the clinic of %s." % here_name, GameState.COL_BAD)
		GameState.fall_open(here_name, "Found and brought to its clinic.")
		if fv.pilot != null and is_instance_valid(fv.pilot):
			fv.pilot.look = fv.pilot_look()              # (the basic kit shows)
			fv.pilot.queue_redraw()
		if seat == 1:
			scope_out()
		return
	var sys := GameState.current_system
	var here := f.docked_at.substr(5).split("|")[0] if f != null and f.docked_at.begins_with("land:") else ""
	_fetch_quiet = true
	close_deck(false)
	_fetch_quiet = false
	_close_planet_map()
	if f == null:
		return
	var city := nearest_clinic_city(sys, here)
	if not city.is_empty():
		var cname := String(city.get("name", "the city"))
		var msg := how + " They found you and brought you to %s: your ship waits in its hangar." % cname
		var wake := "Found and brought to its clinic: your ship waits in its hangar."
		f.docked_at = String(city["id"])
		Economy.prepare_station(city, sys)
		if seat == 0:
			GameState.log_msg(msg, GameState.COL_BAD)
			GameState.fall_open(cname, wake)     # 0.7.53.14
			_wake_at(city)
			if was_apart and two_p:
				_fall2 = {"note": "%s went down and was brought to %s. The ship went there, and you with it." % [who, cname]}
		else:
			_wake_at(city)
			_fall_bed()
			GameState.log_msg("%s went down and was brought to %s. The ship went there, and you with it." % [who, cname], GameState.COL_WARN)
			_fall_open2(msg, cname, wake)
		return
	var st := GameState._respawn_station()
	f.system_id = int(GameState.last_station.get("system", Universe.home_system))
	f.docked_at = String(st["id"])
	f.position = st["pos"]
	if view != null and is_instance_valid(view) and view.player != null and is_instance_valid(view.player):
		view.player.queue_free()
		view.player = null
	var sname := String(st.get("name", "the station"))
	var msg2 := how + " There is no clinic in this system: they flew you and your ship to %s." % sname
	var wake2 := "No clinic in that system: they flew you and your ship here."
	if seat == 0:
		GameState.log_msg(msg2, GameState.COL_BAD)
		GameState.fall_open(sname, wake2)     # 0.7.53.14
		if was_apart and two_p:
			_fall2 = {"note": "%s went down and was flown to %s. The ship went there, and you with it." % [who, sname]}
	else:
		GameState.log_msg("%s went down and was flown to %s. The ship went there, and you with it." % [who, sname], GameState.COL_WARN)
		_fall_open2(msg2, sname, wake2)
	GameState.wake_pending = true
	GameState.active_changed.emit()
	_wake_after_loss.call_deferred()


var _fall_ask: Dictionary = {}        # a pilot went down while you are apart: {"seat", "reason"}, done at the start of the next frame
var _fall2: Dictionary = {}           # a word for the second player that waits until you stand in the clinic ("note")


## The second player's fall: the word for them and their own buy-back offer, in their name. Their window opens over
## their half as soon as the picture is in two (_fall_step()).
func _fall_open2(msg: String, where: String, wake: String) -> void:
	GameState.with_seat(1, func():
		GameState.log_msg(msg, GameState.COL_BAD)
		GameState.fall_open(where, wake))


## The second player fell and both of you were brought to the clinic: they are the one by the bed, you stand beside.
func _fall_bed() -> void:
	if ground == null or not is_instance_valid(ground) or ground.pilot == null or ground.map == null:
		return
	var spot: Vector2 = ground.pilot.pos
	for off in [Vector2(22, 0), Vector2(-22, 0), Vector2(0, 18), Vector2(0, -18)]:
		if ground.map.free_at(spot + off, 5.0):
			ground.two_at = spot
			ground.pilot.pos = spot + off
			ground.pilot.position = ground.pilot.pos * GroundMap.SCALE
			return


func _fall_step(delta: float) -> void:
	if not _talk.is_empty():
		return                                           # (a talk of the story is up: who fell lies there until it is over)
	if not _fall_ask.is_empty():
		var a := _fall_ask
		_fall_ask = {}
		_fallen(String(a["reason"]), int(a["seat"]))
		return
	if not Players.split or not GameState.has_pilot2():
		_fall2 = {}
		return
	# the second player's buy-back window: over their half whenever an offer of theirs is open and the picture is in two
	if halves_on() and not GameState.fall_offer_of(1).is_empty() and not (loading != null and is_instance_valid(loading)):
		var lw2 = _loss_win(1)
		if not lw2.visible:
			for o2 in _wins2():
				if o2.visible:
					o2.close()
			_halves_step()
			lw2.open(GameState.fall_offer_of(1))
			_update_input()
	if _fall2.is_empty():
		return
	if (loading != null and is_instance_valid(loading)) or GameState.acting != 0 or loss_window.visible:
		return
	_fall2["t"] = float(_fall2.get("t", 0.0)) + delta
	var up: bool = ground != null and is_instance_valid(ground) and not apart() and ground.p2_walker() != null and ground.input_enabled
	if not up and float(_fall2["t"]) < 20.0:
		return
	var o := _fall2
	_fall2 = {}
	if up:
		say_to(1, String(o["note"]), GameState.COL_WARN)


## The buy-back window of a player (the second player's is made when first asked for, in their half).
func _loss_win(seat: int):
	if seat == 0:
		return loss_window
	if loss_window2 == null:
		loss_window2 = LossWindowScript.new()
		loss_window2.seat = 1
		halves[1].take(loss_window2)
		loss_window2.closed.connect(_update_input)
		loss_window2.closed.connect(_look2)
	return loss_window2


## The station window of a player (the second player's is made when first asked for, in their half).
func _station_win(seat: int) -> StationUI:
	if seat == 0:
		return station_panel
	if station_panel2 == null:
		station_panel2 = StationUI.new()
		station_panel2.seat = 1
		halves[1].take(station_panel2)
		station_panel2.closed.connect(_update_input)
		station_panel2.closed.connect(func():
			_look2()
			if apart():
				scope_in(1)
				ground2.on_service_closed()
				scope_out())
	return station_panel2


## What the second player wears shows on their figure (after a shop, after the buy-back).
func _look2() -> void:
	if apart():
		if ground2.pilot != null and is_instance_valid(ground2.pilot):
			scope_in(1)
			ground2.pilot.look = ground2.pilot_look()
			scope_out()
			ground2.pilot.queue_redraw()
	elif ground != null and is_instance_valid(ground) and ground.p2_walker() != null:
		ground.p2_walker().look = ground._two_look()
		ground.p2_walker().queue_redraw()


## A shop's or a service's window opens for the player who stands at its counter: in their name, and in a split
## picture over their half, while the other plays on.
func _open_service(seat: int, z: Dictionary) -> void:
	GameState.ship_along()
	var st: Dictionary = GameState.with_seat(seat, func():
		var f := GameState.active()
		return Commands.docked_station() if f != null and f.docked_at != "" else {})
	if st.is_empty():
		if seat == 0:
			close_deck(false)
		else:
			toast_to(1, "Your ship does not stand here: no counter for you.")
		return
	if seat == 1 and not halves_on():
		toast_to(1, "Not just now.")
		return
	var sp := _station_win(seat)
	if seat == 1:
		if loss_window2 != null and loss_window2.visible:
			return                                       # (a decision of theirs is needed first)
		for o in _wins2():
			if o != sp and o.visible:
				o.close()
	_halves_step()                                       # (in its place before it lays itself out)
	sp.on_foot = true
	sp.open(st, view)
	sp.open_service(String(z["id"]))
	_update_input()


## One of the two views goes to another level: what the other player has done where they are (foes fallen, doors
## opened) is written to the site's maps first, which are the same for both, so the place entered knows it.
func site_sync(from) -> void:
	if not apart() or ground == null or not is_instance_valid(ground):
		return
	var o = ground2 if from == ground else ground
	if o != from and o != null and is_instance_valid(o):
		o.poi_save()


## Is a fight on where this player is?
func in_fight(seat: int) -> bool:
	var gv = ground_of(seat)
	return gv != null and gv.combat != null and bool(gv.combat.fight)


## A place stands still (or goes on again): a night's rest (see below).
var _still: Dictionary = {}           # seat -> [view, the process mode it had]


func _stand_still(seat: int, on: bool) -> void:
	if on:
		var gv = ground2 if seat == 1 else ground
		if _still.has(seat) or gv == null or not is_instance_valid(gv):
			return
		_still[seat] = [gv, gv.process_mode]
		gv.process_mode = Node.PROCESS_MODE_DISABLED
	elif _still.has(seat):
		var k: Array = _still[seat]
		_still.erase(seat)
		if is_instance_valid(k[0]):
			k[0].process_mode = k[1]


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


# ---------------------------------------------------------------- split screen: apart places (Luz, 25 Nov 2026)
##
## The two of you in different places: the second player has a ground view of their own (ground2), the same class as
## the first player's, and each view stands in a half of the picture (ground_half.gd). In the same place again the
## second view goes and they are a guest in the first player's, as before. The first player always keeps `ground`.

var ground2 = null                    # the second player's own ground view while you are apart (null: together, or alone)
var ghalves: Array = []               # the two halves the views stand in while you are apart
var _ghost: CanvasLayer = null        # … and the layer they are on
var _scope: Array = []                # scope_in() / scope_out(): what to give back
var _part_ask: Dictionary = {}        # asked for, done at the start of the next frame: the second player parts


func apart() -> bool:
	return ground2 != null and is_instance_valid(ground2)


func parting() -> bool:
	return not _part_ask.is_empty()


## From here on (until scope_out()) "the pilot" is this player: GameState's pilot, gear, purse and standing are
## theirs, and the controller the game's words and menus ask about is theirs. Always in pairs, never across a frame.
func scope_in(seat: int) -> void:
	_scope.append([GameState.acting, Pad.device, Pad.using_pad])
	if GameState.has_pilot2() and GameState.acting != seat:
		GameState.act_as(seat, true)
	if seat == 1 and Players.split:
		Pad.device = Players.pad_of(1)
		Pad.using_pad = Players.pad_of(1) >= 0


func scope_out() -> void:
	if _scope.is_empty():
		return
	var k: Array = _scope.pop_back()
	if GameState.has_pilot2() and GameState.acting != int(k[0]):
		GameState.act_as(int(k[0]), true)
	Pad.device = int(k[1])
	Pad.using_pad = bool(k[2])


## The second player goes their own way from the spot they stand at (GroundView.two_spot()): a view of their own
## opens there, in their half. use_now: they press their use key there at once (the door they stand at). Done at the
## start of the next frame, when nothing of either view is in the middle of its work.
func part_two(spot: Dictionary, use_now: bool = false) -> void:
	_part_ask = {"spot": spot, "use": use_now}


func _part_now(spot: Dictionary, use_now: bool) -> void:
	if ground == null or not is_instance_valid(ground) or not Players.split or not GameState.has_pilot2() or apart():
		return
	ground.two_drop()
	if _ghost == null or not is_instance_valid(_ghost):
		_ghost = CanvasLayer.new()
		_ghost.layer = GroundView.LAYER
		add_child(_ghost)
		move_child(_ghost, ground.get_index())
		var line := ColorRect.new()
		line.color = Color(0.0, 0.0, 0.0)
		line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ghost.add_child(line)
		ghalves = []
		for s in 2:
			var gh = GroundHalf.new()
			gh.seat = s
			gh.main = self
			_ghost.add_child(gh)
			ghalves.append(gh)
	_ghalves_place()
	ground.set_meta("home_at", ground.get_index())
	_hold2 = false
	ghalves[0].take(ground)
	var n := GroundView.new()
	n.name = "Ground2"
	n.owner_seat = 1
	n.seat_now = 1
	ground2 = n
	scope_in(1)
	ghalves[1].take(n)
	n.twin(ground, spot)
	if use_now and n.map != null and n.pilot != null:
		n.zone = n.map.zone_at(n.pilot.pos)
		n.use()
	scope_out()
	n.used.connect(_on_deck_use2)
	_update_input()


func _ghalves_place() -> void:
	if ghalves.size() < 2:
		return
	var vs := get_viewport().get_visible_rect().size
	var hw := floorf((vs.x - 4.0) * 0.5)
	(ghalves[0] as Control).position = Vector2.ZERO
	(ghalves[0] as Control).size = Vector2(hw, vs.y)
	(ghalves[1] as Control).position = Vector2(vs.x - hw, 0.0)
	(ghalves[1] as Control).size = Vector2(hw, vs.y)


## You are in the same place again (or the walk on the ground is over): the second view goes, the first player's is
## the whole picture again. back: the second player stands in the first player's view where they stood in theirs.
func _apart_end(back: bool = true) -> void:
	_part_ask = {}
	_stand_still(0, false)
	_stand_still(1, false)
	var at := Vector2.INF
	if apart():
		if back and ground2.pilot != null and is_instance_valid(ground2.pilot):
			at = ground2.pilot.pos
		scope_in(1)
		ground2.leave_ground()
		scope_out()
		ground2.queue_free()
	ground2 = null
	for gh in ghalves:
		if is_instance_valid(gh):
			gh.let_go()
	if ground != null and is_instance_valid(ground) and ghalves.size() > 0 and ghalves[0].holds(ground):
		ghalves[0].vp.remove_child(ground)
		add_child(ground)
		move_child(ground, mini(int(ground.get_meta("home_at", get_child_count() - 1)), get_child_count() - 1))
		ground.two_at = at
	if _ghost != null and is_instance_valid(_ghost):
		_ghost.queue_free()
	_ghost = null
	ghalves = []
	_update_input()


## Each frame, before either view works: what was asked for; the halves at their places; together again when both
## stand in the same place with nothing going on.
func _apart_step() -> void:
	_invite_step(get_process_delta_time())
	_night_step()
	_col_back_step()
	_fall_step(get_process_delta_time())
	_resume2_step(get_process_delta_time())
	if not _part_ask.is_empty():
		var a := _part_ask
		_part_ask = {}
		_part_now(a["spot"], bool(a["use"]))
	if not apart():
		if ghalves.size() > 0:
			_apart_end(false)
		_stand_still(0, false)
		_stand_still(1, false)
		return
	if ground == null or not is_instance_valid(ground) or not Players.split:
		_apart_end(false)
		return
	_ghalves_place()
	GameState.ship_along()                               # (their ship stands where yours stands: a shop of theirs knows where they are)
	# the second player's view takes their input unless something is over the whole picture, a window of their own is
	# up over their half (their pilot's window, a shop, their buy-back), or they are being asked something
	var hold2: bool = pause_menu.visible or in_hyperspace or (halves.size() > 1 and (halves[1] as Control).visible) \
		or invited() == 1 or String(_invite.get("what", "")) == "night" or night_on() or (planet_map != null and is_instance_valid(planet_map)) or (flight != null and is_instance_valid(flight))
	if hold2:
		ground2.input_enabled = false
	elif _hold2:
		ground2.input_enabled = true                     # (given back once: what the view itself holds, a fall or a scene, stays held)
	_hold2 = hold2
	# a night's rest: the resting player's place stands still
	var night_of := int(_night.get("seat", -1))
	_stand_still(0, night_of == 1)
	_stand_still(1, night_of == 0)
	# (in a game of the Colosseum each for themselves nobody is put into the other's game: you meet in the lobby)
	if _invite.is_empty() and not night_on() and ground.place_key() == ground2.place_key() and ground.idle() and ground2.idle() \
			and not ground.in_colosseum() and not ground2.in_colosseum() and _talk.is_empty():
		_apart_end(true)


## What the second player's own view asks of the game beyond the ground. A shop's or a service's window opens in
## their name over their half, with their credits and gear, and you play on. The way up to the ship is the first
## player's.
func _on_deck_use2(z: Dictionary) -> void:
	if not apart():
		return
	match String(z.get("kind", "")):
		"service", "crew":
			_open_service(1, z)
		"collapse":
			_fall_ask = {"seat": 1, "reason": String(z.get("reason", ""))}      # (they went down alone: the clinic, as for you)
		"exit":
			ground2._say_toast("The way up to the ship is the first player's for now.", 3.0)
		_:
			ground2._say_toast("Not while the two of you are in different places yet.", 3.0)


var _hold2 := false                   # the second player's view was held by something of the game's last frame


## A word for one of the two players where they read it: the game's log for the first, the second player's own list
## (or a line in their own view while you are apart).
func say_to(seat: int, text: String, col: Color = Color(1.0, 0.85, 0.5)) -> void:
	if seat == 0:
		GameState.log_msg(text, col)
	elif apart():
		scope_in(1)                                       # (their list takes a line only in their name)
		ground2._say_toast(text, 4.0)
		scope_out()
	elif ground != null and is_instance_valid(ground):
		ground.two_say(text, col)


## The ground view a player walks in (null: none).
func ground_of(seat: int):
	if seat == 1 and apart():
		return ground2
	return ground if (ground != null and is_instance_valid(ground)) else null


## The half of the picture that is a player's (the whole of it while there is one picture).
func half_rect(seat: int) -> Rect2:
	var vs := get_viewport().get_visible_rect().size
	if apart() and ghalves.size() > seat:
		return Rect2((ghalves[seat] as Control).position, (ghalves[seat] as Control).size)
	if ground != null and is_instance_valid(ground) and ground.split_open():
		var src: Control = ground._split["fa" if seat == 0 else "fb"]
		return Rect2(src.position, src.size)
	return Rect2(Vector2.ZERO, vs)


# ---------------------------------------------------------------- the Colosseum's split screen: the other player is asked (Luz, 25 Nov 2026)
##
## One of the two picks "Split screen" at the Colosseum's counter: the other, wherever they are, is asked whether
## they take part. Yes: they are there at once and the two of you go on to the fighters' gate. When the games are
## over and you are back in the lobby, who came on the invitation stands at their own place again.

var _invite: Dictionary = {}          # {"from", "to", "t", "box"}: the question that is up
var col_back: Dictionary = {}         # who came on an invitation, and from where: {"seat", "spot", "busy"}
const INVITE_SECS := 30.0


## Who is being asked (-1: nobody).
func invited() -> int:
	return int(_invite.get("to", -1))


func invite(from: int, what: String = "col", arg: String = "") -> void:
	if not _invite.is_empty() or not Players.split or not GameState.has_pilot2():
		return
	var to := 1 - from
	var night := what == "night"                          # (a night's sleep while you are apart, see below)
	if not night and (in_fight(to) or talk_seat() == to):      # (nobody is asked anything in the middle of a fight or a talk of the story)
		var asker0 = ground_of(from)
		if asker0 != null and asker0.minigame != null and is_instance_valid(asker0.minigame) and asker0.minigame.has_method("is_col_play"):
			asker0.minigame.waiting = false
			asker0.minigame.msg = "%s is in a %s: ask again when it is over." % [String(GameState.pilot_of(to).get("name", "The other player")), "talk" if talk_seat() == to else "fight"]
		Audio.play("ui_error", "colosseum: the other player is in a fight")
		return
	var who := String(GameState.pilot_of(from).get("name", "The other player"))
	var col := Color(0.62, 0.72, 1.0) if night else Color(1.0, 0.5, 0.8)
	var layer := CanvasLayer.new()
	layer.layer = 95
	add_child(layer)
	var panel := UI.neon_panel(Color(col, 0.9), Color(0.03, 0.02, 0.07, 0.96), 2)
	panel.custom_minimum_size = Vector2(440, 0)
	layer.add_child(panel)
	var box := UI.vbox(8)
	panel.add_child(box)
	box.add_child(UI.label("A NIGHT'S SLEEP" if night else "THE COLOSSEUM", 22, col))
	box.add_child(UI.wrap_label(("%s wants to sleep. A night passes for the whole world, so for you too: new work at the stations, new faces in the bars, the planets move on. Is that all right with you?" if night
		else "%s has picked Split screen at the Colosseum's counter. Do you want to take part?") % who, 15, Color(0.9, 0.94, 1.0), 420))
	box.add_child(UI.wrap_label("You stay where you are and rest there until it is morning." if night
		else "You are there at once. Afterwards you stand where you stand now.", 12, UI.TEXT_DIM, 420))
	box.add_child(UI.label("[%s] %s        [%s] Not now" % [Players.key_text(to, "interact"), "Let it pass" if night else "Take part", Players.key_text(to, "foot_dodge")], 15, Color(1.0, 0.85, 0.4)))
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 5)
	bar.max_value = INVITE_SECS
	box.add_child(bar)
	var wait: Control = null                              # a night: who asked sees that the other is being asked, and may take it back
	if night:
		wait = UI.neon_panel(Color(col, 0.7), Color(0.03, 0.02, 0.07, 0.94), 2)
		wait.custom_minimum_size = Vector2(400, 0)
		layer.add_child(wait)
		var wb := UI.vbox(6)
		wait.add_child(wb)
		wb.add_child(UI.wrap_label("A night passes for both of you: %s is being asked." % String(GameState.pilot_of(to).get("name", "the other player")), 15, Color(0.9, 0.94, 1.0), 380))
		wb.add_child(UI.label("[%s] Take it back" % Players.key_text(from, "foot_dodge"), 14, Color(1.0, 0.85, 0.4)))
	_invite = {"from": from, "to": to, "t": 0.0, "layer": layer, "panel": panel, "bar": bar, "armed": false, "what": what, "arg": arg, "wait": wait, "armed2": false, "back": false}
	Audio.play("lock_acquired", "a night: the other player is asked" if night else "colosseum: an invitation", -6.0)
	_update_input()


func _invite_step(delta: float) -> void:
	if _invite.is_empty():
		return
	var to := int(_invite["to"])
	var from := int(_invite["from"])
	var night := String(_invite.get("what", "")) == "night"
	if not Players.split or ground == null or not is_instance_valid(ground) or (night and not apart()):
		invite_end(false)
		return
	_invite["t"] = float(_invite["t"]) + delta
	var r := half_rect(to)
	var panel: Control = _invite["panel"]
	panel.position = r.position + (r.size - panel.size) * 0.5
	(_invite["bar"] as ProgressBar).value = INVITE_SECS - float(_invite["t"])
	var wait = _invite.get("wait")
	if wait != null:
		var rf := half_rect(from)
		(wait as Control).position = rf.position + (rf.size - (wait as Control).size) * 0.5
	if to == 0 or night:
		ground.input_enabled = false                      # (a night: who asked waits at the bed, too)
	if night:                                             # who asked may take the question back
		var back: bool = Players.pressed(from, "foot_dodge")
		if not bool(_invite["armed2"]):
			_invite["armed2"] = not back
		elif back:
			_invite["back"] = true
			invite_end(false)
			return
	# their own keys answer; a key still held from before the question does not
	var yes: bool = Players.pressed(to, "interact")
	var no: bool = Players.pressed(to, "foot_dodge")
	if not bool(_invite["armed"]):
		_invite["armed"] = not yes and not no
		return
	if yes:
		invite_end(true)
	elif no or float(_invite["t"]) >= INVITE_SECS:
		invite_end(false)


## The question is answered (or taken back): yes brings the two of you together at the counter and on to the gate.
func invite_end(yes: bool) -> void:
	if _invite.is_empty():
		return
	var from := int(_invite["from"])
	var to := int(_invite["to"])
	var what := String(_invite.get("what", "col"))
	var arg := String(_invite.get("arg", ""))
	var back := bool(_invite.get("back", false))
	(_invite["layer"] as Node).queue_free()
	_invite = {}
	if what == "night":
		_night_answer(from, to, arg, yes, back)
		return
	var asker = ground_of(from)
	if not yes:
		if asker != null and asker.minigame != null and is_instance_valid(asker.minigame) and asker.minigame.has_method("is_col_play"):
			asker.minigame.waiting = false
			asker.minigame.msg = "%s does not take part." % String(GameState.pilot_of(to).get("name", "The other player"))
		Audio.play("ui_error", "colosseum: no")
		_update_input()
		return
	col_back = {}
	if apart():
		if to == 1:                                       # the second player comes to you: their view goes, they stand beside you
			col_back = {"seat": 1, "spot": ground2.own_spot(), "busy": false}
			_apart_end(false)
		else:                                             # you come to them: your view goes to the Colosseum's hall
			col_back = {"seat": 0, "spot": ground.own_spot(), "busy": false}
			ground2._close_game()
			ground.ctr_stop = ground2.ctr_stop
			ground.go_level("zcolin", "from_reg")
			_apart_end(true)
	if ground == null or not is_instance_valid(ground):
		return
	ground._close_game()
	if not GameState.col_registered:
		Commands.execute({"type": "col_register"})          # (who takes part is in: a run for two is the first player's run)
	var e: String = Commands.execute({"type": "col_play", "seat": 0, "play": "split"})
	if e != "":
		GameState.log_msg(e, GameState.COL_WARN)
		col_back = {}
		_update_input()
		return
	GameState.log_msg("%s takes part: the Colosseum for two." % String(GameState.pilot_of(to).get("name", "The other player")), Color(0.6, 0.9, 1.0))
	Audio.play("ui_open", "colosseum: for two")
	_update_input()
	ground._col_go(true)


## Who came on an invitation goes back to their own place once the games are over and you stand in the lobby again.
func _col_back_step() -> void:
	if col_back.is_empty():
		return
	if ground == null or not is_instance_valid(ground) or not Players.split or apart():
		col_back = {}
		return
	if not ground.idle() or String(ground.level) != "zcolin":
		col_back["busy"] = true                           # (the way to the gate, the rooms, the games)
		return
	if not bool(col_back["busy"]):
		return
	var back := col_back
	col_back = {}
	var spot: Dictionary = back["spot"]
	if String(spot.get("key", "")) == ground.place_key():
		return                                            # (they were here anyway)
	if int(back["seat"]) == 1:
		if ground.two != null and is_instance_valid(ground.two):
			part_two(spot)
			say_to(1, "The games are over: you are back where you were.")
	else:
		if ground.two != null and is_instance_valid(ground.two):
			part_two(ground.two_spot())                   # (the second player stays in the lobby)
		for k in (spot.get("ctx", {}) as Dictionary):
			ground.set(k, spot["ctx"][k])
		ground.restore_spot(spot)
		GameState.log_msg("The games are over: you are back where you were.", Color(0.6, 0.9, 1.0))


# ---------------------------------------------------------------- a night's sleep while you are apart: the other player is asked (Luz, 25 Nov 2026)
##
## A night passes for the whole world (new contracts, new faces in the bars, the planets move on), so for both of you.
## Who lies down while you are in different places has the other asked first, as the Colosseum does. With their yes
## the night passes: the sleeper's scene plays in their half, the other rests where they are (their half dark, their
## place standing still) until the sleeper is up.

var _night: Dictionary = {}           # a night that is passing: {"seat": who sleeps, "layer", "veil"}


func night_on() -> bool:
	return not _night.is_empty()


## A bed asks (GroundView._no_night()): "" when the other player is being asked now, else a word why not.
func night_ask(from: int, kind: String) -> String:
	if not apart():
		return ""
	var to := 1 - from
	if not _invite.is_empty() or night_on() or not col_back.is_empty():
		return "Not just now."
	var other = ground_of(to)
	if other == null or not other.idle() or in_fight(to) or talk_seat() == to:
		return "A night passes for both of you, and %s is in the middle of something. Ask again in a moment." % String(GameState.pilot_of(to).get("name", "the other player"))
	invite(from, "night", kind)
	return ""


func _night_answer(from: int, to: int, kind: String, yes: bool, back: bool) -> void:
	_update_input()
	var v = ground_of(from)
	if v == null or not apart():
		return
	if not yes:
		if not back:
			toast_to(from, "%s would rather not let a night pass now." % String(GameState.pilot_of(to).get("name", "The other player")))
			Audio.play("ui_error", "a night: no")
		return
	var layer := CanvasLayer.new()
	layer.layer = 39                                      # (over a half and its windows, under the fade that is over everything)
	add_child(layer)
	var veil := ColorRect.new()
	veil.color = Color(0.01, 0.01, 0.04, 0.93)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.modulate.a = 0.0
	layer.add_child(veil)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.add_child(cc)
	var vb := UI.vbox(6)
	cc.add_child(vb)
	var l1 := UI.label("A night passes…", 28, Color(0.85, 0.82, 1.0))
	l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(l1)
	var l2 := UI.label("%s is asleep. You rest where you are." % String(GameState.pilot_of(from).get("name", "The other player")), 14, UI.TEXT_DIM)
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(l2)
	_night = {"seat": from, "layer": layer, "veil": veil}
	_stand_still(to, true)                               # (their place stands still while they rest: nothing there reaches them)
	create_tween().tween_property(veil, "modulate:a", 1.0, 0.7)
	_night_place()
	if from == 1:
		scope_in(1)
	v._night_ok = true
	if kind == "room":
		v._room_sleep_begin()
	else:
		v._q_sleep_begin()
	v._night_ok = false
	if from == 1:
		scope_out()
	if not v._sleeping:
		_night_end(false)                                 # (it did not begin: somebody talks to them, say)


func _night_place() -> void:
	var r := half_rect(1 - int(_night["seat"]))
	var veil: Control = _night["veil"]
	veil.position = r.position
	veil.size = r.size


func _night_step() -> void:
	if _night.is_empty():
		return
	var v = ground_of(int(_night["seat"])) if apart() else null
	if v == null or not v._sleeping:
		_night_end(v != null)
		return
	_night_place()
	if ground != null and is_instance_valid(ground):
		ground.input_enabled = false                      # (the second player's view: see _apart_step())


func _night_end(word: bool) -> void:
	if _night.is_empty():
		return
	var seat := int(_night["seat"])
	var layer = _night["layer"]
	var veil = _night["veil"]
	_night = {}
	_stand_still(1 - seat, false)
	if is_instance_valid(layer):
		var tw := create_tween()
		tw.tween_property(veil, "modulate:a", 0.0, 0.6)
		tw.tween_callback(layer.queue_free)
	_update_input()
	if word:
		toast_to(1 - seat, "Some hours later. A night has passed while %s slept: new work at the stations, new faces in the bars." % String(GameState.pilot_of(seat).get("name", "the other player")))


## A word on the ground for one of the two, in their own picture and their own list.
func toast_to(seat: int, text: String) -> void:
	var v = ground_of(seat)
	if v == null:
		return
	if seat == 1 and not apart():
		say_to(1, text)
		return
	if seat == 1:
		scope_in(1)
	v._say_toast(text, 4.0)
	if seat == 1:
		scope_out()


var _fetch_quiet := false              # (a fall: it says its own word for who is brought along)


func close_deck(open_window: bool = true) -> void:
	invite_end(false)
	_night_end(false)
	talk_end()
	col_back = {}
	if apart() and not _fetch_quiet and Players.split and GameState.has_pilot2():
		# rule 6: one ship flies until the second player flies their own: they are fetched aboard from where they are
		GameState.log_msg("%s is fetched aboard from where they were: you leave together." % String(GameState.pilot_of(1).get("name", "The second player")), GameState.COL_WARN)
	_apart_end(false)
	if Players.guest:
		Players.stop_split()                           # (a split screen for the Colosseum: it ends with the walk on the ground)
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
			if apart():                                      # (in different places: done at the start of the next frame, outside the view's own work)
				_fall_ask = {"seat": 0, "reason": String(z.get("reason", ""))}
			else:
				_fallen(String(z.get("reason", "")))           # 0.7.51.4: you wake in a clinic (package 52: also shot down)
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
			# split screen: a counter the second player uses beside you is theirs: their window, over their half
			var theirs: bool = Players.split and GameState.acting == 1 and ground != null and is_instance_valid(ground) and bool(ground.two_acting)
			if theirs:
				ground._two_done()                           # (the window is theirs by itself: you are the pilot of your place again)
			_open_service(1 if theirs else 0, z)


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


## In the Colosseum the pilot's window and the ship's menu stay shut, whatever is played there (Luz, 25 Nov 2026).
## True (and a word why) when that is so for this player.
func col_locked(seat: int = 0) -> bool:
	var gv = ground_of(seat)
	if gv == null or not gv.in_colosseum():
		return false
	var why := "The Colosseum's rules: the pilot's window and the ship's menu stay shut in here."
	if seat == 1 and not apart():
		ground.two_say(why)
	else:
		gv._say_toast(why, 3.0)
	Audio.play("ui_error", "colosseum: no windows in here")
	return true


## Package 29: the Pilot window – also over the station. 0.5.30.5: U always opens the Pilot tab (Info);
## the HUD hint for tiles / perk points opens the tab it is about.
func toggle_pilot_window(p_tab: int = 0, seat: int = 0) -> void:
	if seat == 1:
		_toggle_two("pilot", p_tab)
		return
	if pilot_window.visible:
		pilot_window.close()
	elif not in_hyperspace:
		if col_locked(0):
			return
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
	return Players.split and GameState.has_pilot2() and ground != null and is_instance_valid(ground) and (ground.split_open() or apart())


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
	return [pilot_window2, ship_menu2, galaxy2, station_panel2].filter(func(w): return w != null)


## The second player's window of this kind opens over their half (again: it shuts). One of theirs at a time.
func _toggle_two(kind: String, p_tab: int = 0) -> void:
	if not halves_on() or in_hyperspace or (loss_window2 != null and loss_window2.visible):
		return                                           # (their buy-back window: a decision is needed first)
	var w = _win2(kind)
	var was: bool = w.visible
	if not was and kind in ["pilot", "ship"] and col_locked(1):
		return
	GameState.ship_along()
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
			var src: Control = ghalves[s] if apart() else sp["fa" if s == 0 else "fb"]
			(halves[s] as Control).position = src.position
			(halves[s] as Control).size = src.size
	for w in [pilot_window, ship_menu, galaxy, station_panel, loss_window]:
		if on and not halves[0].holds(w):
			w.set_meta("home_at", w.get_index())
			halves[0].take(w)
			if w.visible and w.has_method("relayout"):
				w.relayout()                                 # (it was up while the picture went into two: laid out for the half)
		elif not on and halves[0].holds(w):
			halves[0].vp.remove_child(w)
			add_child(w)
			move_child(w, mini(int(w.get_meta("home_at", get_child_count() - 1)), get_child_count() - 1))
			if w.visible and w.has_method("relayout"):
				w.relayout()
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
	elif apart() and (ground2.talk != null or ground2.talk_menu != null or ground2._lift_menu != null or ground2.minigame != null):
		var ev := InputEventAction.new()                  # (apart places: a menu of their own view shuts by the menus' back)
		ev.action = "menu_back"
		ev.pressed = true
		ghalves[1].push(ev)
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
	if in_hyperspace or col_locked(0):
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
	_resume2 = GameState.on_foot2.duplicate()            # (… and the second player onto theirs, once they stand beside you: _resume2_step())
	_resume2_t = 0.0


var _resume2: Dictionary = {}         # where the second player stood when the game was saved, still to be gone to
var _resume2_t := 0.0
## The levels a view of the second player's own can be built at from what the save says (the others need more than it
## keeps: a site, an office's faction; and those nobody is put back into, as for you: a fight, a run, a ride, a room).
const RESUME2_NOT := ["", "quarters", "dungeon", "museum_down", "clinic", "alley", "minehead", "plaza", "office", "landing", "settlement", "sim", "zroom"]


## A game loaded that was saved with the two of you in different places: once the second player stands beside you
## in a split picture, they go to where they stood.
func _resume2_step(delta: float) -> void:
	if _resume2.is_empty():
		return
	_resume2_t += delta
	if _resume2_t > 20.0 or apart():
		_resume2 = {}                                    # (no split screen came up, or you parted already)
		return
	if not Players.split or not GameState.has_pilot2() or ground == null or not is_instance_valid(ground) or (loading != null and is_instance_valid(loading)):
		return
	if not (ground.split_open() and ground.p2_walker() != null and ground.idle()):
		return
	var sp := _resume2
	_resume2 = {}
	var lv := String(sp.get("level", ""))
	if lv in ["zcolvr", "zcolar", "zcolsv"]:
		lv = "zcolin"                                    # (out of a game: the lobby, as for you)
	elif lv in ["ztrain", "ctrain"]:
		lv = "zstation" if lv == "ztrain" else "cstation"
	if String(sp.get("station", "")) != String(ground.station.get("id", "")) or lv in RESUME2_NOT:
		say_to(1, "You stand beside %s again: the save does not keep the place you were in." % String(GameState.pilot_of(0).get("name", "the first player")))
		return
	var key := lv + ("|%d" % int(sp.get("ctr_stop", 0)) if lv.begins_with("z") else "")
	if key == ground.place_key():
		return                                           # (the same place: they are beside you anyway)
	part_two({"level": lv, "pos": sp.get("pos", Vector2.ZERO), "ctr_stop": int(sp.get("ctr_stop", 0)), "town_kind": String(sp.get("town_kind", "")), "key": key, "ctx": {}})
	say_to(1, "You are back where you stood when the game was saved.", Color(0.6, 0.9, 1.0))


## A counter's own talk while the picture is in two halves (the Marshal's; the story's talks are the first player's, over
## the whole picture, and hold both: StoryUI): its window stands over the half of who began it
## and their own device answers. The game is paused for the talk, as always; while you are in different places the
## other player's view, their half and their windows go on.
var _talk: Dictionary = {}            # {"seat", "keep": [[node, the process mode it had]]}


func talk_seat() -> int:
	return int(_talk.get("seat", -1))


func talk_begin(seat: int, layer: Node) -> void:
	talk_end()
	_halves_step()
	halves[seat].take(layer)
	(halves[seat] as Control).visible = true
	var keep: Array = []
	var on: Array = [halves[seat], seat_menu]
	if apart():
		on.append(halves[1 - seat])
		on.append(ghalves[1 - seat])
	for n in on:
		keep.append([n, n.process_mode])
		n.process_mode = Node.PROCESS_MODE_ALWAYS
	_talk = {"seat": seat, "keep": keep}


## Each frame of the talk (the story's window calls it: the game is paused): what main does first every frame.
func talk_tick() -> void:
	if _talk.is_empty():
		return
	_apart_step()
	_halves_step()


func talk_end() -> void:
	if _talk.is_empty():
		return
	for k in _talk["keep"]:
		if is_instance_valid(k[0]):
			k[0].process_mode = k[1]
	_talk = {}
	_halves_step.call_deferred()
	_update_input()


## Writes the live ship position back into its data before saving.
func prepare_save() -> void:
	GameState.on_foot = ground.save_spot() if (ground != null and is_instance_valid(ground)) else {}
	GameState.on_foot2 = ground2.save_spot() if apart() else {}      # (rule 8: in different places the save keeps both)
	if ground != null and is_instance_valid(ground):
		ground.poi_save()                              # review 7 W1: what happened at the site goes into the save
	if apart():
		ground2.poi_save()
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
	if not event.is_pressed() or event.is_echo():
		return
	var seat := _event_seat(event)                       # (split screen: a window is theirs whose key it was)
	if loss_window != null and loss_window.visible and (seat == 0 or not halves_on()):
		return                                            # review W3: a decision is needed first
	if seat == 1 and loss_window2 != null and loss_window2.visible:
		return
	if seat == 1 and halves_on():
		for wa in ["galaxy_map", "ship_menu", "pilot_window", "journal"]:
			if event.is_action_pressed(wa, false, true):
				win_action(1, wa)
				return
		if event.is_action_pressed("menu_back", false, true):
			win_back(1)
			return
	if seat == 1 and view != null and is_instance_valid(view) and view.eyes_two:
		# (two looks in space: the keyboard is the second player's; what it does for their ship so far)
		if bool(view.eye_get(1, "input_enabled")):
			view.in_eye(1, seat_event.bind(event))
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
	else:
		_ship_keys(event)


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
	_apart_step()                                        # split screen: the two of you in different places
	_halves_step()                                       # split screen: each player's windows over their half
	_space_step()                                        # split screen: two looks at the one space
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


## Split screen in space, stage 4 (Luz: each player flies their own ship, each half shows its player's ship with the
## whole HUD): while nothing is up that is one scene for both (the ground, a jump, the way down to a planet), the
## space view shows the one world in two halves, each with its player's camera, zoom, sky, labels and overlay
## (SystemView, EYE_VARS), and each with a HUD of its player's own (stage 4B): the one there always was moves into the
## first player's half, a second one of the same class stands in the second player's.
##
## `hud` is the HUD of the player whose turn it is: the first player's, except inside SystemView.in_eye(1, …), where
## it is the second player's (_eye_scope). So the code that says `hud` (the keys below, the controller code) serves
## either player unchanged.
var huds: Array = []                  # two looks: [the first player's HUD, the second player's]; one look: empty


func _space_step() -> void:
	if view == null or not is_instance_valid(view):
		return
	view.two_wanted = Players.split and GameState.has_pilot2() and (ground == null or not is_instance_valid(ground)) and not in_hyperspace \
		and not (planet_map != null and is_instance_valid(planet_map)) and not (flight != null and is_instance_valid(flight)) \
		and not (hatch != null and is_instance_valid(hatch))
	# the second player's controller: the controller code once more, for them (Pad.as_seat)
	if view.eyes_two and huds.size() == 2 and not Players.on_keys(1) and not get_tree().paused and bool(view.eye_get(1, "input_enabled")):
		view.in_eye(1, Pad.seat_step.bind(get_process_delta_time()))


## Two looks are there (on) or about to go: each player's HUD into their half, and home again.
func _on_eyes(on: bool) -> void:
	if not is_inside_tree() or view == null or not is_instance_valid(view):
		return
	if on:
		if huds.size() == 2:
			return
		var theirs := HUD.new()
		theirs.seat = 1
		huds = [hud, theirs]
		view.eye_half(0).take(hud)
		view.eye_half(1).take(theirs)
		view.in_eye(1, theirs.set_view.bind(view))
		return
	if huds.size() == 2:
		hud = huds[0]
		if is_instance_valid(huds[1]):
			huds[1].queue_free()
	huds = []
	if hud.get_parent() != self:
		if hud.get_parent() != null:
			hud.get_parent().remove_child(hud)
		add_child(hud)
	hud.set_overview(false)
	Pad.as_seat(0)
	Pad.seat_forget()


## The look changed (SystemView.eye_as): `hud` and the controller code are that player's from here on.
func _eye_scope(seat: int) -> void:
	if huds.size() == 2 and is_instance_valid(huds[seat]):
		hud = huds[seat]
	Pad.as_seat(seat)


## An action of the game from the second player's controller in space (Pad, while it is their turn): what a key
## press of theirs does.
func seat_event(ev: InputEvent) -> void:
	if not ev.is_pressed():
		return
	if ev.is_action_pressed("menu_back", false, true):
		if not in_hyperspace:
			pause_menu.open()                             # (pause holds both)
		return
	for wa in ["galaxy_map", "ship_menu", "pilot_window", "journal", "station", "help"]:
		if ev.is_action_pressed(wa, false, true):
			GameState.log_msg("Windows of your own are not there in space yet.", GameState.COL_WARN)
			return
	_ship_keys(ev)


## The ship's keys: thrust burst, camera, the view's level, fire groups, drones, wingmen, the ship's commands, and in
## a split screen the overview. For the player whose turn it is (their look as the view's, their HUD as `hud`).
func _ship_keys(event: InputEvent) -> void:
	if event.is_action_pressed("overview", false, true):
		if view != null and is_instance_valid(view) and view.eyes_two:
			hud.toggle_overview()                         # (Luz: in a split screen the list only when you open it)
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
