extends Node
## Entry point. One continuous SystemView per star system (fixed zoom levels).
## Galaxy map as an overlay (M). On a gate jump: hyperspace tunnel + star map, then the new system.
## Station interface (StationUI) after docking, ship menu (ShipMenu) on I.
## Started from the main menu (scenes/menu.tscn) via SaveGame.start_new / start_load.
## Player input goes through the Commands bus; this node registers the SystemView there.

var view: SystemView
var hud: HUD
var galaxy: GalaxyMap
var station_panel: StationUI
var ship_menu: ShipMenu
var pilot_window                       # package 29: skills, skill tree, the pilot (U)
const PilotWindowScript = preload("res://scripts/ui/pilot_window.gd")
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
	galaxy = GalaxyMap.new()
	add_child(galaxy)
	station_panel = StationUI.new()
	add_child(station_panel)
	ship_menu = ShipMenu.new()
	add_child(ship_menu)
	pilot_window = PilotWindowScript.new()
	add_child(pilot_window)
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
	if is_new:
		GameState.log_msg("Welcome to Sternenfront, %s! Press H for controls." % GameState.pilot_name, GameState.COL_GOOD)
		if Universe.test_mode:
			GameState.log_msg("TEST SYSTEM: every station, planet and asteroid type. Saving is disabled. F12 = debug menu.", GameState.COL_WARN)
		GameState.log_msg("Tip: click an object in the overview on the right to warp there.")
	else:
		GameState.log_msg("Game loaded. Welcome back, %s." % GameState.pilot_name, GameState.COL_GOOD)
		var f := GameState.active()
		if f != null and f.docked_at.begins_with("land:"):
			_on_descended.call_deferred(f.docked_at.substr(5).split("|")[0])      # package 50: still down on a planet
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
	if f == null or f.docked_at == "" or view == null or not view.stations.has(f.docked_at):
		return
	GameState.gear.aboard()
	_open_ground_at(view.stations[f.docked_at].data)


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
	GameState.log_msg("Landed in %s on %s – your ship is in the city's hangars." % [String(site["name"]), String(body["name"])], GameState.COL_GOOD)
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
		GameState.log_msg(how + " They found you and brought you to %s – your ship waits in its hangar." % String(city.get("name", "the city")), GameState.COL_BAD)
		GameState.fall_open(String(city.get("name", "the city")), "Found and brought to its clinic – your ship waits in its hangar.")     # 0.7.53.14
		_wake_at(city)
		return
	var st := GameState._respawn_station()
	f.system_id = int(GameState.last_station.get("system", Universe.home_system))
	f.docked_at = String(st["id"])
	f.position = st["pos"]
	if view != null and is_instance_valid(view) and view.player != null and is_instance_valid(view.player):
		view.player.queue_free()
		view.player = null
	GameState.log_msg(how + " There is no clinic in this system – they flew you and your ship to %s." % String(st.get("name", "the station")), GameState.COL_BAD)
	GameState.fall_open(String(st.get("name", "the station")), "No clinic in that system – they flew you and your ship here.")     # 0.7.53.14
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
func close_deck(open_window: bool = true) -> void:
	if ground != null and is_instance_valid(ground):
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
			elif ground != null and is_instance_valid(ground) and ground.station.get("city", false):
				leave_city(dest)
			else:
				close_deck(true)
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
func toggle_pilot_window(p_tab: int = 0) -> void:
	if pilot_window.visible:
		pilot_window.close()
	elif not in_hyperspace:
		galaxy.close()
		ship_menu.close()
		if p_tab == 0:
			pilot_window.sub = 0
		pilot_window.open(p_tab)
	_update_input()


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
	if f == null or f.docked_at == "" or view == null or not view.stations.has(f.docked_at):
		return
	galaxy.close()
	ship_menu.close()
	station_panel.on_foot = false
	station_panel.open(view.stations[f.docked_at].data, view)
	_update_input()


func _on_station_docked(_station_id: String) -> void:
	if not station_panel.visible and not galaxy.visible:
		open_station()
	SaveGame.autosave.call_deferred()


# ---------------------------------------------------------------- Save / load

## Writes the live ship position back into its data before saving.
func prepare_save() -> void:
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


## Game hotkeys via rebindable actions (see Keybinds / Settings → Controls).
## Also called by SystemView for a clean middle-mouse click (no drag).
func handle_input(event: InputEvent) -> void:
	if loss_window != null and loss_window.visible:
		return                                            # review W3: a decision is needed first
	if not event.is_pressed() or event.is_echo():
		return
	if event.is_action_pressed("galaxy_map", false, true):
		toggle_galaxy()
	elif event.is_action_pressed("ship_menu", false, true):
		toggle_ship_menu()
	elif event.is_action_pressed("pilot_window", false, true):
		toggle_pilot_window()
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
		for i in 9:
			if event.is_action_pressed("module_%d" % (i + 1), false, true):
				hud.activate_index(i)
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
	var t := UI.label("STERNENFRONT", 40, UI.NEON_CYAN)
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
