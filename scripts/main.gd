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
	loss_window.closed.connect(_update_input)
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
		if f != null and f.docked_at != "":
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
	Commands.world = view
	hud.set_view(view)
	_update_input()


func _update_input() -> void:
	if view != null and is_instance_valid(view):
		view.input_enabled = not (galaxy.visible or station_panel.visible or ship_menu.visible or pilot_window.visible or loss_window.visible or in_hyperspace)


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
