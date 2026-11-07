extends Node
## Start menu: Continue, New Game, Load Game, Settings, Quit.
## Background: nebula shader, a slowly turning pixel planet and ships drifting past.

const TITLE := "STERNENFRONT"
const SHIPS := ["dragonfly", "hornet", "mule", "drillhead", "warden", "bastion"]

var ui: CanvasLayer
var menu_box: VBoxContainer
var overlay: CenterContainer
var scene_root: Node2D
var _flyers: Array = []
var _t := 0.0


func _ready() -> void:
	add_to_group("kbd_menu")              # 0.5.28.2: keyboard control
	GameState.running = false
	var bg := SpaceBackground.new()
	bg.setup(37.0, 0.78, 1.15)
	add_child(bg)

	scene_root = Node2D.new()
	add_child(scene_root)
	var vs := Vector2(1600, 900)
	var planet := Celestial.make_planet_sprite({"type": "toxic", "seed": 17.0, "ring": true}, 190.0, Vector2(-0.8, -0.35))
	planet.position = Vector2(vs.x * 0.75, vs.y * 0.58)
	scene_root.add_child(planet)
	var moon := Celestial.make_planet_sprite({"type": "ice", "seed": 4.0}, 38.0, Vector2(-0.8, -0.35))
	moon.position = Vector2(vs.x * 0.56, vs.y * 0.2)
	scene_root.add_child(moon)
	for i in 5:
		_spawn_flyer(randf_range(-200.0, vs.x))

	ui = CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(root)

	var left := UI.vbox(10)
	left.position = Vector2(110, 150)
	root.add_child(left)
	var logo := UI.label(TITLE, 72, UI.NEON_CYAN)
	logo.add_theme_color_override("font_shadow_color", Color(UI.NEON_PINK, 0.8))
	logo.add_theme_constant_override("shadow_offset_x", 4)
	logo.add_theme_constant_override("shadow_offset_y", 3)
	left.add_child(logo)
	left.add_child(UI.label("A corporate frontier between the stars", 18, UI.TEXT_DIM))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 40)
	left.add_child(gap)
	menu_box = UI.vbox(8)
	menu_box.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	left.add_child(menu_box)
	_build_menu()

	var ver := UI.label("alpha %s • Godot 4.3" % ProjectSettings.get_setting("application/config/version", "?"), 12, UI.TEXT_DIM)
	ver.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	ver.position = Vector2(24, 868)
	root.add_child(ver)

	overlay = CenterContainer.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	root.add_child(overlay)

	# Automated runs skip the menu
	var args := OS.get_cmdline_user_args()
	if "--smoketest" in args:
		SaveGame.start_new.call_deferred("Lefty", 4711)


func _build_menu() -> void:
	UI.clear(menu_box)
	var latest := SaveGame.latest_slot()
	var cont := UI.menu_button("Continue", func(): SaveGame.start_load(latest))
	cont.disabled = latest == ""
	if latest != "":
		cont.tooltip_text = "Load the most recent save"
	menu_box.add_child(cont)
	menu_box.add_child(UI.menu_button("New Game", _show_new_game))
	menu_box.add_child(UI.menu_button("Load Game", _show_load))
	if Commands.cheats_enabled:
		var tb := UI.menu_button("Test System (Debug)", func(): SaveGame.start_test(), UI.GOLD)
		tb.tooltip_text = "One system with every station, planet and asteroid type – no gates, no saving.\nThe normal game is not affected."
		menu_box.add_child(tb)
	menu_box.add_child(UI.menu_button("Codex", _show_codex))
	menu_box.add_child(UI.menu_button("Settings", _show_settings))
	menu_box.add_child(UI.menu_button("Quit", func(): get_tree().quit(), UI.NEON_PINK))


func _show_overlay(panel: Control) -> void:
	UI.clear(overlay)
	overlay.add_child(panel)
	overlay.visible = true
	menu_box.visible = false


func _hide_overlay() -> void:
	UI.clear(overlay)
	overlay.visible = false
	menu_box.visible = true
	_build_menu()


func _show_load() -> void:
	var b := SaveBrowser.new("load")
	b.closed.connect(_hide_overlay)
	b.slot_chosen.connect(func(slot): SaveGame.start_load(slot))
	_show_overlay(b)


## Codex from the main menu: everything discovered in any game so far (package 18).
func _show_codex() -> void:
	var p := UI.neon_panel(UI.NEON_CYAN, Color(0.03, 0.04, 0.08, 0.97))
	p.custom_minimum_size = Vector2(1300, 760)
	var v := UI.vbox(10)
	p.add_child(v)
	var head := UI.hbox(10)
	v.add_child(head)
	head.add_child(UI.label("CODEX", 26, UI.NEON_CYAN))
	head.add_child(UI.label("everything discovered in any of your games", 13, UI.TEXT_DIM))
	head.add_child(UI.spacer())
	head.add_child(UI.button("Close", _hide_overlay))
	var cv := preload("res://scripts/ui/codex_view.gd").new()
	v.add_child(cv)
	cv.setup(false)
	_show_overlay(p)


func _show_settings() -> void:
	var s := SettingsPanel.new()
	s.closed.connect(_hide_overlay)
	s.controls_requested.connect(_show_controls)
	_show_overlay(s)


func _show_controls() -> void:
	var k := KeybindPanel.new()
	k.closed.connect(_show_settings)
	_show_overlay(k)


func _show_new_game() -> void:
	var p := UI.neon_panel(UI.NEON_CYAN)
	p.custom_minimum_size = Vector2(560, 0)
	var v := UI.vbox(12)
	p.add_child(v)
	var head := UI.hbox(10)
	v.add_child(head)
	head.add_child(UI.label("NEW GAME", 22, UI.NEON_CYAN))
	head.add_child(UI.spacer())
	head.add_child(UI.button("Back", _hide_overlay))
	v.add_child(UI.label("Pilot name", 14))
	var name_edit := LineEdit.new()
	name_edit.text = "Lefty"
	name_edit.max_length = 24
	v.add_child(name_edit)
	v.add_child(UI.label("Galaxy seed – the same seed always creates the same galaxy", 14))
	var seed_row := UI.hbox(8)
	v.add_child(seed_row)
	var seed_edit := LineEdit.new()
	seed_edit.text = str(randi() % 1000000)
	seed_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seed_row.add_child(seed_edit)
	seed_row.add_child(UI.button("Random", func(): seed_edit.text = str(randi() % 1000000)))
	v.add_child(UI.wrap_label("You start in the core system with a Dragonfly scout, 30,000 credits and a few spare modules in station storage.", 13, UI.TEXT_DIM, 520))
	var start := func():
		var pilot := name_edit.text.strip_edges()
		SaveGame.start_new(pilot if pilot != "" else "Lefty", absi(seed_edit.text.to_int()))
	v.add_child(UI.menu_button("Launch", start, UI.GOOD, 520))
	_show_overlay(p)


# ---------------------------------------------------------------- Background animation

func _spawn_flyer(x: float) -> void:
	var s := Sprite2D.new()
	s.texture = PixelArt.ship_texture(SHIPS[randi() % SHIPS.size()], "pirate" if randf() < 0.25 else "player")
	var depth := randf_range(0.35, 1.0)
	s.scale = Vector2.ONE * depth * 2.2
	s.modulate = Color(1, 1, 1, 0.35 + 0.65 * depth)
	s.position = Vector2(x, randf_range(80.0, 860.0))
	s.rotation = 0.0
	s.set_meta("speed", 30.0 + 90.0 * depth)
	s.set_meta("bob", randf() * TAU)
	scene_root.add_child(s)
	_flyers.append(s)


func _process(delta: float) -> void:
	_t += delta
	for s in _flyers.duplicate():
		var spr: Sprite2D = s
		spr.position.x += float(spr.get_meta("speed")) * delta
		spr.position.y += sin(_t * 0.6 + float(spr.get_meta("bob"))) * 0.15
		if spr.position.x > 1800.0:
			_flyers.erase(spr)
			spr.queue_free()
			_spawn_flyer(-150.0)
