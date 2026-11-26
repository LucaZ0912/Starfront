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
# split screen (stage 0): the two halves of the start menu
var split_root: Control = null
var _sp_slot := ""                    # the game the two will play
var _sp_dev: Array = ["kbm", ""]      # the device of each player
var _sp_new := {}                     # slot -> the creator's data of a second pilot made just now
var _sp_creating := false


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
	var sp := _menu_button(4, "Split Screen", _show_split, Color(1.0, 0.45, 0.85))
	sp.disabled = latest == ""
	sp.tooltip_text = "Two players at one screen. The second half of the picture opens here." if latest != "" else "Start a game first: the second player joins a game that exists."
	menu_box.add_child(sp)
	var n := 5
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


# ---------------------------------------------------------------- Split screen (stage 0)

## "Split Screen": the picture parts in two. Left the first player (their device, the game to play), right the second
## (their device, their pilot: the one in the save, or a new one from the creator).
func _show_split() -> void:
	if _sp_slot == "":
		_sp_slot = SaveGame.latest_slot()
		_sp_dev = Players.default_devices()
	_sp_creating = false
	if not Players.changed.is_connected(_split_devices_changed):
		Players.changed.connect(_split_devices_changed)
	_build_split()


## A controller was plugged in or pulled: the lists follow (not while the creator is open).
func _split_devices_changed() -> void:
	if split_root != null and is_instance_valid(split_root) and not _sp_creating:
		if not Players.device_ok(String(_sp_dev[1])):
			_sp_dev[1] = Players.next_device("", String(_sp_dev[0]), 1) if Players.device_list().size() > 1 else ""
		_build_split()


func _hide_split() -> void:
	if split_root != null and is_instance_valid(split_root):
		split_root.queue_free()
	split_root = null
	menu_box.visible = true
	_build_menu()


func _split_half(right: bool, col: Color) -> VBoxContainer:
	var half := Control.new()
	half.anchor_left = 0.5 if right else 0.0
	half.anchor_right = 1.0 if right else 0.5
	half.anchor_bottom = 1.0
	half.mouse_filter = Control.MOUSE_FILTER_IGNORE
	split_root.add_child(half)
	if right:
		var bg := ColorRect.new()
		bg.color = Color(0.02, 0.015, 0.05, 0.93)
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		half.add_child(bg)
		var edge := ColorRect.new()                     # the line between the two halves
		edge.color = col
		edge.anchor_bottom = 1.0
		edge.offset_right = 3.0
		half.add_child(edge)
	var box := UI.vbox(10)
	if right:                                           # the second player's side: in the middle of their half
		var mid := CenterContainer.new()
		mid.set_anchors_preset(Control.PRESET_FULL_RECT)
		mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
		half.add_child(mid)
		mid.add_child(box)
	else:
		box.position = Vector2(110, 318)
		half.add_child(box)
	return box


func _split_device_row(parent: Control, player: int, col: Color) -> void:
	parent.add_child(UI.label("INPUT", 14, col))
	var row := UI.hbox(8)
	parent.add_child(row)
	var other := String(_sp_dev[1 - player])
	row.add_child(UI.button("‹", func():
		_sp_dev[player] = Players.next_device(String(_sp_dev[player]), other, -1)
		_build_split()))
	var nm := UI.label(Players.device_name(String(_sp_dev[player])), 16, Color(0.9, 0.94, 1.0) if Players.device_ok(String(_sp_dev[player])) else UI.BAD)
	nm.custom_minimum_size = Vector2(430, 0)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.clip_text = true
	row.add_child(nm)
	row.add_child(UI.button("›", func():
		_sp_dev[player] = Players.next_device(String(_sp_dev[player]), other, 1)
		_build_split()))


const SPLIT_MIN_W := 1600.0             # a picture narrower than this gets the word that split screen is made for a large screen


func _build_split() -> void:
	if split_root != null and is_instance_valid(split_root):
		split_root.queue_free()
	menu_box.visible = false
	split_root = Control.new()
	split_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	split_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.get_parent().add_child(split_root)
	var c1 := UI.NEON_CYAN
	var c2 := Color(1.0, 0.45, 0.85)
	# ---- the left half: the first player
	var lb := _split_half(false, c1)
	lb.add_child(UI.label("PLAYER 1", 26, c1))
	var sw: float = get_viewport().get_visible_rect().size.x
	if sw < SPLIT_MIN_W:
		# (Luz, 26 Nov 2026: split screen is not meant for the Steam Deck's own screen; it is said, not forbidden)
		lb.add_child(UI.wrap_label("Split screen is made for a large screen, a TV or a monitor. On this one each half is only %d pixels wide: texts get small and windows tight." % int(sw * 0.5), 14, UI.GOLD, 520))
	_split_device_row(lb, 0, c1)
	lb.add_child(UI.label("GAME", 14, c1))
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(520, 250)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	lb.add_child(sc)
	var list := UI.vbox(4)
	sc.add_child(list)
	for e in SaveGame.list_saves():
		if e.get("old", false):
			continue
		var slot := String(e["slot"])
		var meta: Dictionary = e["meta"]
		var two := String(meta.get("pilot2", ""))
		var b := UI.button("%s   ·   %s%s\n%s" % [String(meta.get("label", slot)), String(meta.get("pilot", "?")),
			("  +  " + two) if two != "" else "", String(meta.get("location", ""))], func():
			_sp_slot = slot
			_build_split())
		b.custom_minimum_size = Vector2(500, 50)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = true
		if slot == _sp_slot:
			b.add_theme_color_override("font_color", c1)
			var sel := UI.panel_style(Color(c1.darkened(0.78), 0.9), c1)
			sel.set_content_margin_all(6)
			b.add_theme_stylebox_override("normal", sel)
		list.add_child(b)
	lb.add_child(UI.button("Back", _hide_split))
	# ---- the right half: the second player
	var rb := _split_half(true, c2)
	if _sp_creating:
		var cc = CharacterCreatorScript.new()
		cc.setup("p2", {}, {}, "Wingmate")
		cc.cancelled.connect(func():
			_sp_creating = false
			_build_split())
		cc.done.connect(func(d: Dictionary):
			_sp_new[_sp_slot] = d
			_sp_creating = false
			_build_split())
		rb.add_child(cc)
		return
	rb.add_child(UI.label("PLAYER 2", 26, c2))
	_split_device_row(rb, 1, c2)
	rb.add_child(UI.label("PILOT", 14, c2))
	var p2: Dictionary = _sp_new.get(_sp_slot, {})
	var fresh := not p2.is_empty()
	if not fresh:
		p2 = SaveGame.pilot2_of(_sp_slot)
	var to_creator := func():
		_sp_creating = true
		_build_split()
	if p2.is_empty():
		rb.add_child(UI.wrap_label("No second pilot in this game yet. Create one: they come into the game in the first pilot's start system.", 14, UI.TEXT_DIM, 520))
		rb.add_child(UI.menu_button("Create pilot", to_creator, c2, 300))
	else:
		var card := UI.hbox(14)
		rb.add_child(card)
		var frame := UI.neon_panel(Color(c2, 0.5), Color(0.02, 0.01, 0.05, 1.0), 1)
		card.add_child(frame)
		var por := TextureRect.new()
		por.custom_minimum_size = Vector2(190, 190)
		por.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		por.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		por.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		por.texture = GameState.PilotArt.portrait(GameState.PilotArt.clean(p2.get("look", {})))
		frame.add_child(por)
		var info := UI.vbox(6)
		card.add_child(info)
		info.add_child(UI.label(String(p2.get("name", "Wingmate")), 24))
		var cs := String(p2.get("callsign", ""))
		if cs != "":
			info.add_child(UI.label("»%s«" % cs, 15, c2))
		info.add_child(UI.label("New pilot, level 1" if fresh else "Level %d" % int(p2.get("level", 1)), 14, UI.TEXT_DIM))
		info.add_child(UI.button("New pilot instead" if not fresh else "Change", to_creator, "A new pilot takes the place of this one once the game is saved." if not fresh else ""))
	var err := Players.devices_error(String(_sp_dev[0]), String(_sp_dev[1]))
	if err == "" and p2.is_empty():
		err = "Player 2 needs a pilot."
	rb.add_child(UI.label(err, 14, UI.BAD))
	var go := UI.menu_button("Start", func(): _split_start(), UI.GOOD, 300)
	go.disabled = err != ""
	rb.add_child(go)
	rb.add_child(UI.wrap_label("The picture parts in two where two play at once. In this first stage the second half opens here, in the start menu; the Colosseum is next.", 12, UI.TEXT_DIM, 520))


func _split_start() -> void:
	if Players.devices_error(String(_sp_dev[0]), String(_sp_dev[1])) != "":
		return
	SaveGame.start_split(_sp_slot, String(_sp_dev[0]), String(_sp_dev[1]), _sp_new.get(_sp_slot, {}))


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
