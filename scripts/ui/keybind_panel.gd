class_name KeybindPanel
extends PanelContainer
## Settings → Controls: every action with two bindings. Click a binding, then press a key
## (or middle / side mouse button). Esc cancels, Delete/Backspace clears the binding.

signal closed

var list: VBoxContainer
var status: Label
var _capture: Array = []      # [action id, slot] while waiting for input
var _buttons := {}            # "id:slot" -> Button
var tab := "space"            # 0.7.52.9 (Luz): two tabs – "space" (the ship, windows, menus) and "ground" (on foot)
var _tab_btns := {}


func _ready() -> void:
	add_to_group("kbd_menu")              # 0.5.28.2: keyboard control
	var sb := UI.panel_style(UI.NEON_BG, UI.NEON_PINK)
	sb.set_border_width_all(2)
	sb.set_content_margin_all(18)
	add_theme_stylebox_override("panel", sb)
	custom_minimum_size = Vector2(720, 640)
	var v := UI.vbox(10)
	add_child(v)
	var head := UI.hbox(10)
	v.add_child(head)
	head.add_child(UI.label("CONTROLS", 22, UI.NEON_PINK))
	head.add_child(UI.spacer())
	head.add_child(UI.button("Reset to defaults", _reset))
	head.add_child(UI.button("Back", func(): closed.emit()))
	var tabs := UI.hbox(6)
	v.add_child(tabs)
	for t in [["space", "Space"], ["ground", "Ground"]]:
		var tk: String = t[0]
		var tb := UI.button(String(t[1]), func(): _set_tab(tk))
		tb.toggle_mode = true
		tb.custom_minimum_size = Vector2(140, 32)
		tabs.add_child(tb)
		_tab_btns[tk] = tb
	v.add_child(UI.label("Click a binding, then press a key or mouse button (middle / side buttons; hold Shift for Shift+key).  Esc: cancel  •  Delete: clear", 12, UI.TEXT_DIM))
	status = UI.label("", 13, UI.GOOD)
	v.add_child(status)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	list = UI.vbox(3)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	v.add_child(UI.label("Fixed: left click = select / fly (on foot: lock a foe) • mouse wheel = zoom (on foot: the tactical view) • drag with middle mouse = pan camera", 12, UI.TEXT_DIM))
	_build()


func _build() -> void:
	UI.clear(list)
	_buttons.clear()
	var group := ""
	for tk in _tab_btns:
		(_tab_btns[tk] as Button).set_pressed_no_signal(tk == tab)
	for a in Keybinds.ACTIONS:
		if (String(a["group"]) == "On foot") != (tab == "ground"):
			continue
		if a["group"] != group:
			group = a["group"]
			list.add_child(UI.label(group.to_upper(), 14, UI.NEON_CYAN))
		var row := UI.hbox(8)
		list.add_child(row)
		var l := UI.label(a["label"], 14)
		l.custom_minimum_size = Vector2(300, 0)
		row.add_child(l)
		for slot in Keybinds.SLOTS:
			var id: String = a["id"]
			var sl: int = slot
			var b := UI.button("", func(): _start_capture(id, sl))
			b.custom_minimum_size = Vector2(170, 28)
			row.add_child(b)
			_buttons["%s:%d" % [id, slot]] = b
	_refresh()


## 0.7.52.9: Space or Ground.
func _set_tab(t: String) -> void:
	tab = t
	_capture = []
	_build()


func _refresh() -> void:
	for a in Keybinds.ACTIONS:
		for slot in Keybinds.SLOTS:
			if not _buttons.has("%s:%d" % [a["id"], slot]):
				continue
			var b: Button = _buttons["%s:%d" % [a["id"], slot]]
			var d: Dictionary = Keybinds.binds[a["id"]][slot]
			b.text = Keybinds.desc_text(d)
			if _capture.size() == 2 and _capture[0] == a["id"] and _capture[1] == slot:
				b.text = "Press a key …"


func menu_nav_blocked() -> bool:
	return _capture.size() == 2


func _start_capture(id: String, slot: int) -> void:
	_capture = [id, slot]
	status.text = ""
	_refresh()


var _shift_pending := false     # 0.7.52.9: Shift went down – Shift alone if it comes up with no key between, else Shift+key


func _input(event: InputEvent) -> void:
	if _capture.is_empty():
		return
	if event is InputEventKey and (event as InputEventKey).keycode == KEY_SHIFT:
		get_viewport().set_input_as_handled()
		if event.is_pressed() and not event.is_echo():
			_shift_pending = true
		elif not event.is_pressed() and _shift_pending:
			_shift_pending = false
			_bind({"k": KEY_SHIFT})
		return
	if not event.is_pressed() or event.is_echo():
		return
	_shift_pending = false
	if event is InputEventMouseMotion:
		return
	get_viewport().set_input_as_handled()
	var id: String = _capture[0]
	var slot: int = _capture[1]
	if event is InputEventKey:
		var kc: int = (event as InputEventKey).keycode
		if kc == KEY_ESCAPE:
			_capture = []
			_refresh()
			return
		if kc == KEY_DELETE or kc == KEY_BACKSPACE:
			Keybinds.set_binding(id, slot, {})
			_capture = []
			_set_status("%s: binding cleared." % Keybinds.label_of(id), true)
			_refresh()
			return
	var d := Keybinds.event_to_desc(event)
	if d.is_empty():
		if event is InputEventMouseButton:
			_set_status("Left / right click and the mouse wheel cannot be bound.", false)
		return
	_bind(d)


func _bind(d: Dictionary) -> void:
	var id: String = _capture[0]
	var slot: int = _capture[1]
	var lost := Keybinds.set_binding(id, slot, d)
	_capture = []
	if lost != "":
		_set_status("%s → %s  (removed from \"%s\")" % [Keybinds.desc_text(d), Keybinds.label_of(id), lost], false)
	else:
		_set_status("%s → %s" % [Keybinds.desc_text(d), Keybinds.label_of(id)], true)
	_refresh()


func _reset() -> void:
	Keybinds.reset_to_defaults()
	_capture = []
	_set_status("All controls reset to defaults.", true)
	_refresh()


func _set_status(text: String, ok: bool) -> void:
	status.text = text
	status.add_theme_color_override("font_color", UI.GOOD if ok else UI.GOLD)
