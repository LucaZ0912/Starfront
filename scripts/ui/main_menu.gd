extends Node
const CharacterCreatorScript = preload("res://scripts/ui/character_creator.gd")
const IntroOneScript = preload("res://scripts/ui/intro_one.gd")
const IntroTwoScript = preload("res://scripts/ui/intro_two.gd")
const IntroThreeScript = preload("res://scripts/ui/intro_three.gd")
## Start menu: Continue, New Game, Load Game, Settings, Quit.
## Background (Luz, 17 Nov 2026): one of four scenes picked at random - an Earth-like world under a G star, a red gas
## giant before a red supergiant, a Directorate ship before a neutron star, a lone black hole. Buttons in a sci-fi
## look: slanted panels, a lit edge, numbered.

const TITLE := "SPACEFARER"                  # Luz, 17 Nov 2026: the game's new name
const SHIPS := ["dragonfly", "hornet", "mule", "drillhead", "warden", "bastion"]

var ui: CanvasLayer
var menu_box: VBoxContainer
var overlay: CenterContainer
var scene_root: Node2D
var _flyers: Array = []
var _t := 0.0
static var force_backdrop := ""        # the debug renders and the smoke test pick one
const BACKDROPS := ["terran", "red_giant", "directorate", "black_hole"]
var backdrop := ""
var _drift: Array = []                # [node, base position, amplitude, speed]


func _ready() -> void:
	add_to_group("kbd_menu")              # 0.5.28.2: keyboard control
	GameState.running = false
	scene_root = Node2D.new()
	add_child(scene_root)
	backdrop = force_backdrop if force_backdrop in BACKDROPS else BACKDROPS[randi() % BACKDROPS.size()]
	_build_backdrop(backdrop, Vector2(1600, 900))

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
	left.add_child(UI.label("B E Y O N D   T H E   V E I L", 20, Color(0.8, 0.6, 1.0)))
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

	var cap := UI.label(_caption(), 12, Color(0.6, 0.68, 0.8, 0.75))
	cap.position = Vector2(1600 - 24 - cap.get_minimum_size().x, 868)
	root.add_child(cap)

	overlay = CenterContainer.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	root.add_child(overlay)

	# Automated runs skip the menu
	var args := OS.get_cmdline_user_args()
	if "--smoketest" in args:
		SaveGame.start_new.call_deferred("Lefty", 4711)


## The four scenes: real stars, planets and ships of the game, set like a cover picture.
func _build_backdrop(kind: String, vs: Vector2) -> void:
	var bg := SpaceBackground.new()
	match kind:
		"terran":
			bg.setup(37.0, 0.58, 0.55)
			var g := _star("G", 7.0, 95.0)
			g.position = Vector2(vs.x * 0.47, vs.y * 0.14)
			scene_root.add_child(g)
			var pp := Vector2(vs.x * 0.78, vs.y * 0.82)
			# an Earth-like world of its own, drawn like Earth in the intro (the planet shader bands at this size)
			var pl := Sprite2D.new()
			var to_sun := (g.position - pp).normalized()
			pl.texture = load("res://scripts/core/earth_art.gd").texture(200, 0.0, 15.0, Vector3(to_sun.x, to_sun.y, 0.45), 0.0, 4711)
			pl.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			pl.scale = Vector2.ONE * 3.4
			pl.position = pp
			scene_root.add_child(pl)
			var moon := Celestial.make_planet_sprite({"type": "moon_rock", "seed": 4.0}, 34.0, Vector2(-0.85, -0.45))
			moon.position = Vector2(vs.x * 0.55, vs.y * 0.36)
			scene_root.add_child(moon)
			_drift.append([moon, moon.position, Vector2(6.0, 3.0), 0.05])
		"red_giant":
			bg.setup(12.0, 0.02, 0.75)
			var rsg := _star("RSG", 3.0, 430.0)
			rsg.position = Vector2(vs.x * 0.1, vs.y * 0.02)
			scene_root.add_child(rsg)
			var gp := Vector2(vs.x * 0.74, vs.y * 0.64)
			var gas := Celestial.make_planet_sprite({"type": "gas", "seed": 23.0, "hue": 0.02, "ring": true}, 220.0, (rsg.position - gp).normalized())
			gas.position = gp
			_fine(gas, 300.0)
			scene_root.add_child(gas)
		"directorate":
			bg.setup(52.0, 0.48, 0.6)
			var ns := _star("NS", 5.0, 290.0)
			ns.position = Vector2(vs.x * 0.74, vs.y * 0.36)
			scene_root.add_child(ns)
			var ship := Sprite2D.new()
			ship.texture = PixelArt.ship_texture("axa_threshold", "directorate")
			ship.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			ship.scale = Vector2.ONE * 4.5
			ship.rotation = -0.42
			ship.position = Vector2(vs.x * 0.55, vs.y * 0.74)
			scene_root.add_child(ship)
			_drift.append([ship, ship.position, Vector2(10.0, 5.0), 0.07])
		"black_hole":
			bg.setup(81.0, 0.72, 0.3)
			var bh := _star("BH", 9.0, 430.0)
			bh.position = Vector2(vs.x * 0.68, vs.y * 0.5)
			bh.add_child(Celestial.make_lens_sprite())
			scene_root.add_child(bh)
	add_child(bg)
	move_child(bg, 0)


## A finer pixel grid for the big planets of the menu (the game's own grid is for the map's sizes).
func _fine(pl: Sprite2D, px: float) -> void:
	(pl.material as ShaderMaterial).set_shader_parameter("pixels", px)


func _star(id: String, seed_v: float, r: float) -> Sprite2D:
	var sd: Dictionary = (Universe.STAR_TYPES[Universe.star_index(id)] as Dictionary).duplicate()
	sd["star_id"] = id
	sd["seed"] = seed_v
	return Celestial.make_star_sprite(sd, r)


## What the picture shows, small at the bottom right.
func _caption() -> String:
	return {"terran": "AN EARTH-LIKE WORLD  //  CLASS G YELLOW DWARF", "red_giant": "RED GAS GIANT  //  RED SUPERGIANT",
		"directorate": "MERIDIAN DIRECTORATE  ·  THRESHOLD  //  NEUTRON STAR", "black_hole": "BLACK HOLE"}.get(backdrop, "")


## A button of the start menu: a slanted panel with a lit left edge and a number; on hover it lights up and slides.
func _menu_button(idx: int, text: String, cb: Callable, col: Color = UI.NEON_CYAN) -> Button:
	var b := UI.button("%02d   %s" % [idx, text.to_upper()], cb)
	b.custom_minimum_size = Vector2(340, 44)
	b.add_theme_font_size_override("font_size", 17)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	for st in ["normal", "hover", "pressed", "disabled", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.skew = Vector2(0.28, 0.0)
		sb.bg_color = Color(0.02, 0.04, 0.09, 0.72)
		sb.border_color = Color(col, 0.32)
		sb.set_border_width_all(1)
		sb.border_width_left = 4
		sb.content_margin_left = 26
		sb.content_margin_top = 6
		sb.content_margin_bottom = 6
		match st:
			"hover", "focus":
				sb.bg_color = Color(col.darkened(0.72), 0.9)
				sb.border_color = col
				sb.border_width_left = 8
				sb.expand_margin_left = 10.0
				sb.shadow_color = Color(col, 0.35)
				sb.shadow_size = 8
			"pressed":
				sb.bg_color = Color(col.darkened(0.5), 0.95)
				sb.border_color = col
			"disabled":
				sb.border_color = Color(col, 0.12)
				sb.bg_color = Color(0.02, 0.03, 0.06, 0.5)
		b.add_theme_stylebox_override(st, sb)
	b.add_theme_color_override("font_color", Color(0.86, 0.9, 0.98))
	b.add_theme_color_override("font_hover_color", col.lightened(0.3))
	b.add_theme_color_override("font_focus_color", col.lightened(0.3))
	b.add_theme_color_override("font_disabled_color", Color(0.38, 0.4, 0.48))
	return b


func _build_menu() -> void:
	UI.clear(menu_box)
	var latest := SaveGame.latest_slot()
	var cont := _menu_button(1, "Continue", func(): SaveGame.start_load(latest))
	cont.disabled = latest == ""
	if latest != "":
		cont.tooltip_text = "Load the most recent save"
	menu_box.add_child(cont)
	menu_box.add_child(_menu_button(2, "New Game", _show_new_game))
	menu_box.add_child(_menu_button(3, "Load Game", _show_load))
	var n := 4
	if Commands.cheats_enabled:
		var tb := _menu_button(n, "Test System (Debug)", func(): SaveGame.start_test(), UI.GOLD)
		n += 1
		tb.tooltip_text = "One system with every station, planet and asteroid type: no gates, no saving.\nThe normal game is not affected."
		menu_box.add_child(tb)
	menu_box.add_child(_menu_button(n, "Codex", _show_codex))
	menu_box.add_child(_menu_button(n + 1, "Settings", _show_settings))
	menu_box.add_child(_menu_button(n + 2, "Quit", func(): get_tree().quit(), UI.NEON_PINK))


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
	s.controller_requested.connect(_show_controller)
	_show_overlay(s)


func _show_controller() -> void:
	var k := ControllerPanel.new()                   # package 80
	k.closed.connect(_show_settings)
	_show_overlay(k)


func _show_controls() -> void:
	var k := KeybindPanel.new()
	k.closed.connect(_show_settings)
	_show_overlay(k)


## Package 28: a new game starts with creating the pilot (looks, name, call sign, attributes, galaxy seed).
func _show_new_game() -> void:
	# package 56: the story starts with the pilot's memory (sequence 1); the rest of the intro follows part by part
	menu_box.visible = false
	var intro = IntroOneScript.new()
	intro.finished.connect(func():
		var two = IntroTwoScript.new()                # sequence 2: Beyond – the portal, Dan
		two.finished.connect(func():
			var three = IntroThreeScript.new()        # sequence 3: the stretcher, the medic – then the scanner
			three.finished.connect(_show_creator)
			add_child(three))
		add_child(two))
	add_child(intro)


func _show_creator() -> void:
	var cc = CharacterCreatorScript.new()
	cc.setup("new")
	cc.cancelled.connect(_hide_overlay)
	cc.done.connect(func(d: Dictionary):
		d["intro"] = true                               # package 56: the story goes on at Dan's station
		SaveGame.start_new(String(d["name"]), int(d["seed"]), d))
	_show_overlay(cc)


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
	for d in _drift:
		var nd: Node2D = d[0]
		nd.position = (d[1] as Vector2) + Vector2(sin(_t * float(d[3]) * TAU), cos(_t * float(d[3]) * TAU * 0.7)) * (d[2] as Vector2)
	for s in _flyers.duplicate():
		var spr: Sprite2D = s
		spr.position.x += float(spr.get_meta("speed")) * delta
		spr.position.y += sin(_t * 0.6 + float(spr.get_meta("bob"))) * 0.15
		if spr.position.x > 1800.0:
			_flyers.erase(spr)
			spr.queue_free()
			_spawn_flyer(-150.0)
