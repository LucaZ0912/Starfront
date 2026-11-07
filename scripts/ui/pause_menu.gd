class_name PauseMenu
extends CanvasLayer
## In-game menu (Esc): Resume, Save, Load, Settings, Main Menu, Quit. Pauses the game.

signal closed

var dim: ColorRect
var center: CenterContainer
var _leave_armed := ""   # "menu" / "quit" after the first click (confirmation)


func _ready() -> void:
	add_to_group("kbd_menu")              # 0.5.28.2: keyboard control
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	dim = ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.03, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)


func open() -> void:
	visible = true
	get_tree().paused = true
	_leave_armed = ""
	_show_main()


func close() -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = false
	closed.emit()


func _show_main() -> void:
	UI.clear(center)
	var p := UI.neon_panel(UI.NEON_PINK)
	center.add_child(p)
	var v := UI.vbox(8)
	p.add_child(v)
	v.add_child(UI.label("PAUSED", 26, UI.NEON_PINK))
	v.add_child(UI.label("%s  •  %s  •  played %s" % [GameState.pilot_name, GameData.fmt_credits(GameState.credits), SaveGame.fmt_time(GameState.play_time)], 13, UI.TEXT_DIM))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 8)
	v.add_child(gap)
	v.add_child(UI.menu_button("Resume", close))
	v.add_child(UI.menu_button("Save Game", func(): _show_browser("save")))
	v.add_child(UI.menu_button("Load Game", func(): _show_browser("load")))
	v.add_child(UI.menu_button("Settings", _show_settings))
	v.add_child(UI.menu_button("Leave without saving?  Click again" if _leave_armed == "menu" else "Main Menu", func(): _leave("menu"), UI.GOLD))
	v.add_child(UI.menu_button("Quit without saving?  Click again" if _leave_armed == "quit" else "Quit to Desktop", func(): _leave("quit"), UI.NEON_PINK))
	v.add_child(UI.label("%s quicksave  •  %s quickload" % [Keybinds.key_text("quicksave"), Keybinds.key_text("quickload")], 12, UI.TEXT_DIM))


func _leave(what: String) -> void:
	if _leave_armed != what:
		_leave_armed = what
		_show_main()
		return
	if what == "menu":
		SaveGame.to_menu()
	else:
		get_tree().quit()


func _show_browser(mode: String) -> void:
	UI.clear(center)
	var b := SaveBrowser.new(mode)
	b.closed.connect(_back)
	b.slot_chosen.connect(func(slot): SaveGame.start_load(slot))
	center.add_child(b)


func _show_settings() -> void:
	UI.clear(center)
	var s := SettingsPanel.new()
	s.closed.connect(_back)
	s.controls_requested.connect(_show_controls)
	center.add_child(s)


func _show_controls() -> void:
	UI.clear(center)
	var k := KeybindPanel.new()
	k.closed.connect(_show_settings)
	center.add_child(k)


func _back() -> void:
	_leave_armed = ""
	_show_main()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("menu_back", false, true):
		close()
		get_viewport().set_input_as_handled()
