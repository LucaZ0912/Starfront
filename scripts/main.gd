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
	transit_fx = TransitOverlay.new()
	add_child(transit_fx)
	pause_menu = PauseMenu.new()
	add_child(pause_menu)
	debug_menu = DebugMenu.new()
	add_child(debug_menu)

	hud.galaxy_requested.connect(toggle_galaxy)
	hud.station_requested.connect(open_station)
	hud.ship_menu_requested.connect(toggle_ship_menu)
	galaxy.routes_changed.connect(_on_routes_changed)
	galaxy.closed.connect(_update_input)
	station_panel.closed.connect(_update_input)
	ship_menu.closed.connect(func(): station_panel.rebuild())
	station_panel.ship_menu_requested.connect(open_ship_menu)
	ship_menu.closed.connect(_update_input)
	GameState.ship_jumped_out.connect(_on_jumped_out)
	GameState.ship_arrived_system.connect(_on_arrived_system)
	GameState.active_changed.connect(_on_active_changed)
	GameState.anomaly_revealed.connect(func(_s, _a): hud.refresh_overview())

	load_system(GameState.current_system)
	if is_new:
		GameState.log_msg("Welcome to Sternenfront, %s! Press H for controls." % GameState.pilot_name, GameState.COL_GOOD)
		if Universe.test_mode:
			GameState.log_msg("TEST SYSTEM: every station, planet and asteroid type. Saving is disabled. F12 = debug menu.", GameState.COL_WARN)
		GameState.log_msg("Tip: click an object in the overview on the right to warp there.")
	else:
		GameState.log_msg("Game loaded. Welcome back, %s." % GameState.pilot_name, GameState.COL_GOOD)
		var f := GameState.active()
		if f != null and f.docked_at != "":
			open_station.call_deferred()

	if "--smoketest" in OS.get_cmdline_user_args():
		add_child(load("res://scripts/debug/smoke_test.gd").new())


func load_system(sys: int) -> void:
	if view != null and is_instance_valid(view):
		view.sync_to_fits()
		remove_child(view)
		view.queue_free()
	GameState.current_system = sys
	view = SystemView.new()
	add_child(view)
	move_child(view, 0)
	view.build(sys)
	view.station_docked.connect(_on_station_docked)
	Commands.world = view
	hud.set_view(view)
	_update_input()


func _update_input() -> void:
	if view != null and is_instance_valid(view):
		view.input_enabled = not (galaxy.visible or station_panel.visible or ship_menu.visible or in_hyperspace)


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
	view.remove_player()
	station_panel.close()
	ship_menu.close()
	transit_fx.play("jump", "Hyperspace jump → %s" % Universe.systems[int(f.transit_to)]["name"], 1.8)
	galaxy.open(true)
	_update_input()


func _on_arrived_system(f: ShipFitting) -> void:
	in_hyperspace = false
	galaxy.close()
	transit_fx.play("jump", "Arrival: %s" % Universe.systems[f.system_id]["name"], 1.0)
	load_system(f.system_id)
	SaveGame.autosave.call_deferred()


func _on_active_changed() -> void:
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
	if not event.is_pressed() or event.is_echo():
		return
	if event.is_action_pressed("galaxy_map", false, true):
		toggle_galaxy()
	elif event.is_action_pressed("ship_menu", false, true):
		toggle_ship_menu()
	elif event.is_action_pressed("station", false, true):
		if station_panel.visible:
			station_panel.close()
		else:
			open_station()
	elif event.is_action_pressed("help", false, true):
		hud.toggle_help()
	elif event.is_action_pressed("menu_back", false, true):
		if ship_menu.visible:
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
	elif event.is_action_pressed("cam_center", false, true):
		if view != null:
			view.center_on_player()
	else:
		for i in 3:
			if event.is_action_pressed(["zoom_combat", "zoom_recon", "zoom_system"][i], false, true):
				if view != null:
					view.set_level(i)
				return
		for i in 9:
			if event.is_action_pressed("module_%d" % (i + 1), false, true):
				hud.activate_index(i)
				return
		if event.is_action_pressed("drone_launch", false, true) and view != null and not in_hyperspace:
			Commands.execute({"type": "drone_launch"})
			return
		if event.is_action_pressed("drone_recall", false, true) and view != null and not in_hyperspace:
			Commands.execute({"type": "drone_recall"})
			return
		for a in HUD.HOTKEY_COMMANDS:
			if event.is_action_pressed(a, false, true):
				if view != null and not in_hyperspace:
					hud.hotkey_command(a)
				return
