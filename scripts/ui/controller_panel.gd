class_name ControllerPanel
extends PanelContainer
## Package 80 (Luz): Settings → Controller – the controller on or off, its glyphs, the sensitivities (dead zones, the
## camera, flicking at a foe, the triggers' press point, the grenade's aim), vibration, and every button rebindable
## per context (flight, on foot, menus) – a button or a D-pad combination; back to the defaults. Kept in
## user://controller.cfg (Pad).

signal closed

var list: VBoxContainer
var status: Label
var tab := "space"
var _tab_btns := {}
var _dev: Label


func _ready() -> void:
	add_to_group("kbd_menu")
	var sb := UI.panel_style(UI.NEON_BG, UI.NEON_PINK)
	sb.set_border_width_all(2)
	sb.set_content_margin_all(18)
	add_theme_stylebox_override("panel", sb)
	custom_minimum_size = Vector2(1180, 700)
	var v := UI.vbox(10)
	add_child(v)
	var head := UI.hbox(10)
	v.add_child(head)
	head.add_child(UI.label("SETTINGS  ›  CONTROLLER", 22, UI.NEON_PINK))
	head.add_child(UI.spacer())
	head.add_child(UI.button("Back", func(): closed.emit()))
	_dev = UI.label("", 13, UI.GOLD)
	v.add_child(_dev)
	var body := UI.hbox(24)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(body)
	# left: general, sensitivity, vibration
	var left := UI.vbox(8)
	left.custom_minimum_size = Vector2(500, 0)
	body.add_child(left)
	left.add_child(UI.label("GENERAL", 13, UI.NEON_CYAN))
	_check(left, "Controller", "enabled", "keyboard and mouse keep working")
	var gr := UI.hbox(6)
	left.add_child(gr)
	var gl := UI.label("Button glyphs", 14)
	gl.custom_minimum_size = Vector2(200, 0)
	gr.add_child(gl)
	for g in [["auto", "Automatic"], ["ps", "PlayStation"], ["xbox", "Xbox"]]:
		var gk: String = g[0]
		var b := UI.button(String(g[1]), func():
			Pad.set_setting("glyphs", gk)
			_refresh())
		b.toggle_mode = true
		b.button_pressed = Pad.glyphs == gk
		b.set_meta("glyph", gk)
		gr.add_child(b)
	left.add_child(UI.label("", 4))
	left.add_child(UI.label("SENSITIVITY", 13, UI.NEON_CYAN))
	for s in [["Left stick – dead zone", "dead_l", 0.0, 0.5], ["Right stick – dead zone", "dead_r", 0.0, 0.5], ["Camera speed (right stick)", "cam_speed", 0.0, 1.0],
			["Flick to lock – how far", "flick", 0.3, 0.95], ["Triggers – press point (L2 / R2)", "trigger", 0.05, 0.9], ["Grenade aim speed", "aim_speed", 0.0, 1.0], ["Billiards & darts – aim speed", "mg_aim", 0.0, 1.0]]:
		_slider(left, s[0], s[1], s[2], s[3])
	_check(left, "Invert the camera (up / down)", "invert", "")
	_check(left, "Run when the stick is pushed all the way", "run_full", "")
	left.add_child(UI.label("", 4))
	left.add_child(UI.label("VIBRATION", 13, UI.NEON_CYAN))
	_check(left, "Vibration", "vibration", "hits, explosions")
	_slider(left, "Strength", "vib_strength", 0.0, 1.0)
	# right: every button
	var rp := UI.neon_panel(Color(UI.NEON_CYAN, 0.3), Color(0.03, 0.06, 0.11, 0.95), 1)
	rp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(rp)
	var rv := UI.vbox(6)
	rp.add_child(rv)
	var tabs := UI.hbox(6)
	rv.add_child(tabs)
	tabs.add_child(UI.label("BUTTONS", 13, UI.NEON_CYAN))
	for t in [["space", "Flight"], ["ground", "On foot"], ["menu", "Menus"]]:
		var tk: String = t[0]
		var tb := UI.button(String(t[1]), func():
			tab = tk
			_build())
		tb.toggle_mode = true
		tb.custom_minimum_size = Vector2(120, 28)
		tabs.add_child(tb)
		_tab_btns[tk] = tb
	tabs.add_child(UI.spacer())
	tabs.add_child(UI.button("Reset to the defaults", func():
		Pad.reset_binds()
		Pad.save()
		_build()))
	status = UI.label("Choose a row, then press the new button on the controller (hold a D-pad direction, L2, R1 or □ first for a combination).", 12, UI.TEXT_DIM)
	rv.add_child(status)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rv.add_child(scroll)
	list = UI.vbox(3)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	Pad.changed.connect(_build)
	Pad.device_changed.connect(_refresh)
	_build()
	_refresh()


func menu_nav_blocked() -> bool:
	return Pad.capture != ""


func menu_tab(step: int) -> void:
	var order := ["space", "ground", "menu"]
	tab = order[(order.find(tab) + step + order.size()) % order.size()]
	_build()


func _check(p: Control, text: String, key: String, note: String) -> void:
	var cb := CheckButton.new()
	cb.text = text + ("  –  " + note if note != "" else "")
	cb.button_pressed = bool(Pad.get(key))
	cb.toggled.connect(func(on): Pad.set_setting(key, on))
	p.add_child(cb)


func _slider(p: Control, text: String, key: String, lo: float, hi: float) -> void:
	var row := UI.hbox(10)
	p.add_child(row)
	var l := UI.label(text, 14)
	l.custom_minimum_size = Vector2(240, 0)
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = 0.05
	s.value = float(Pad.get(key))
	s.custom_minimum_size = Vector2(180, 0)
	row.add_child(s)
	var pct := UI.label("%d %%" % int(round(s.value * 100.0)), 13, UI.TEXT_DIM)
	row.add_child(pct)
	s.value_changed.connect(func(x):
		pct.text = "%d %%" % int(round(x * 100.0))
		Pad.set_setting(key, x))


func _refresh() -> void:
	if _dev == null:
		return
	var dn := Pad.device_name()
	_dev.text = ("Connected: %s – the glyphs follow the controller you hold" % dn) if dn != "" else "No controller connected – plug one in (USB) or pair it (Bluetooth)."
	for c in find_children("*", "Button", true, false):
		if (c as Node).has_meta("glyph"):
			(c as Button).set_pressed_no_signal(Pad.glyphs == String(c.get_meta("glyph")))


func _build() -> void:
	if list == null:
		return
	UI.clear(list)
	for tk in _tab_btns:
		(_tab_btns[tk] as Button).set_pressed_no_signal(tk == tab)
	var head := UI.hbox(10)
	list.add_child(head)
	var h1 := UI.label("Action", 12, UI.TEXT_DIM)
	h1.custom_minimum_size = Vector2(330, 0)
	head.add_child(h1)
	var h2 := UI.label("Controller", 12, UI.TEXT_DIM)
	h2.custom_minimum_size = Vector2(150, 0)
	head.add_child(h2)
	head.add_child(UI.label("Keyboard", 12, UI.TEXT_DIM))
	for a in Pad.ACTIONS:
		if String(a[2]) != tab:
			continue
		var id: String = a[0]
		var row := UI.hbox(10)
		list.add_child(row)
		var nl := UI.label(String(a[1]), 14)
		nl.custom_minimum_size = Vector2(330, 0)
		row.add_child(nl)
		var key := "%s:%s" % [tab, id]
		var cap := Pad.capture == key
		var bt := UI.button("press a button …" if cap else Pad.binding_text(Pad.binding(tab, id)), func():
			Pad.capture = key
			status.text = "Press the new button for \"%s\" (hold a D-pad direction, L2, R1 or □ first for a combination) – %s: cancel" % [String(a[1]), Pad.glyph("options")]
			_build())
		bt.custom_minimum_size = Vector2(150, 28)
		if cap:
			bt.add_theme_color_override("font_color", UI.GOLD)
		row.add_child(bt)
		var kt := Keybinds.keys_text(id, true) if Keybinds.binds.has(id) else "–"
		row.add_child(UI.label(kt, 13, Color(0.85, 0.88, 0.95)))
