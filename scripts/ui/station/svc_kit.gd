extends RefCounted
## Window rework (Luz, 18 Nov 2026): the building blocks the reworked station windows share.
##  • detail(): the top – a big picture on the left, the name, values and buttons on the right;
##  • strip(): the bottom – a row of small tiles, browsed right to left (arrows, Q / E, the wheel, the stick);
##  • chips(): a row of filter buttons; stats(): a grid of values (key small above, value below), with bars.
## Sizes follow the screen, so the windows fit from 1280×720 up.


## How tall the big picture may be on this screen.
static func pic_height(node: Control) -> float:
	return clampf(node.get_viewport().get_visible_rect().size.y * 0.40, 190.0, 470.0)


## A framed picture panel with a faint grid and a glow in `col`; `tex` scaled up crisp. Corner notes top left / right.
static func picture(tex: Texture2D, col: Color, h: float, note_l: String = "", note_r: String = "") -> PanelContainer:
	var box := UI.neon_panel(Color(col, 0.45), Color(0.03, 0.03, 0.07, 0.95), 1)
	box.custom_minimum_size = Vector2(h * 1.25, h)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_stretch_ratio = 0.62
	var grid := _Grid.new()
	grid.col = col
	box.add_child(grid)
	var tr := TextureRect.new()
	tr.texture = tex
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.offset_left = h * 0.14
	tr.offset_right = -h * 0.14
	tr.offset_top = h * 0.16
	tr.offset_bottom = -h * 0.12
	grid.add_child(tr)
	var notes := UI.hbox(8)
	notes.set_anchors_preset(Control.PRESET_TOP_WIDE)
	notes.offset_left = 10
	notes.offset_right = -10
	notes.offset_top = 6
	notes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.add_child(notes)
	var l := UI.label(note_l, 12, UI.TEXT_DIM)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.clip_text = true
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	notes.add_child(l)
	if note_r != "":
		var r := UI.label(" %s " % note_r, 12, col)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(col, 0.08)
		sb.border_color = col
		sb.set_border_width_all(1)
		r.add_theme_stylebox_override("normal", sb)
		notes.add_child(r)
	return box


## The top area: the picture and an info column; returns the info column.
static func detail(parent: Control, pic: Control) -> VBoxContainer:
	var row := UI.hbox(14)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(row)
	row.add_child(pic)
	var info := UI.vbox(8)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_stretch_ratio = 1.0
	row.add_child(info)
	return info


## Values in a grid: each entry [key, value text, bar fraction (or -1), bar colour]; `cols` columns.
static func stats(parent: Control, entries: Array, cols: int = 4) -> GridContainer:
	var line := ColorRect.new()
	line.color = Color(1, 1, 1, 0.1)
	line.custom_minimum_size = Vector2(0, 1)
	parent.add_child(line)
	var g := GridContainer.new()
	g.columns = cols
	g.add_theme_constant_override("h_separation", 22)
	g.add_theme_constant_override("v_separation", 8)
	parent.add_child(g)
	for e in entries:
		var cell := UI.vbox(1)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g.add_child(cell)
		cell.add_child(UI.label(String(e[0]).to_upper(), 11, UI.TEXT_DIM))
		cell.add_child(UI.label(String(e[1]), 16, e[4] if e.size() > 4 else Color(0.9, 0.92, 1.0)))
		if e.size() > 2 and float(e[2]) >= 0.0:
			var b := UI.bar(e[3], 120)
			b.max_value = 1.0
			b.value = clampf(float(e[2]), 0.0, 1.0)
			b.custom_minimum_size = Vector2(0, 5)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cell.add_child(b)
	var line2 := ColorRect.new()
	line2.color = Color(1, 1, 1, 0.1)
	line2.custom_minimum_size = Vector2(0, 1)
	parent.add_child(line2)
	return g


## Small framed notes in a flowing row (slots, fitted modules).
static func tags(parent: Control, texts: Array, col: Color = UI.TEXT_DIM) -> HFlowContainer:
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	parent.add_child(flow)
	for t in texts:
		var l := UI.label(" %s " % String(t), 12, col)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(1, 1, 1, 0.03)
		sb.border_color = Color(1, 1, 1, 0.18)
		sb.set_border_width_all(1)
		sb.content_margin_left = 4
		sb.content_margin_right = 4
		sb.content_margin_top = 2
		sb.content_margin_bottom = 2
		l.add_theme_stylebox_override("normal", sb)
		flow.add_child(l)
	return flow


## A row of filter buttons; `opts` [[id, label], …]; the one equal to `cur` is lit. `cb(id)`.
static func chips(parent: Control, opts: Array, cur: String, col: Color, cb: Callable, note: String = "") -> HBoxContainer:
	var row := UI.hbox(6)
	parent.add_child(row)
	for o in opts:
		var id := String(o[0])
		var b := UI.button(String(o[1]), func(): cb.call(id))
		b.add_theme_font_size_override("font_size", 13)
		if id == cur:
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(col, 0.35)
			sb.border_color = col
			sb.set_border_width_all(1)
			sb.content_margin_left = 9
			sb.content_margin_right = 9
			for st in ["normal", "hover", "focus"]:
				b.add_theme_stylebox_override(st, sb)
		row.add_child(b)
	if note != "":
		row.add_child(UI.spacer())
		row.add_child(UI.label(note, 12, UI.TEXT_DIM))
	return row


## The tile strip: `items` [{tex, name, sub, sub_col, tag, lock, dim}]; `sel` the picked index; `cb(i)` on a click.
## The strip scrolls sideways; the arrows step the pick one tile.
static func strip(parent: Control, items: Array, sel: int, col: Color, cb: Callable) -> HBoxContainer:
	var th := clampf(parent.get_viewport().get_visible_rect().size.y * 0.15, 96.0, 132.0)
	var row := UI.hbox(6)
	parent.add_child(row)
	var left := UI.button("‹", func(): cb.call(maxi(sel - 1, 0)))
	left.custom_minimum_size = Vector2(30, th)
	left.disabled = sel <= 0
	row.add_child(left)
	var sc := ScrollContainer.new()
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.custom_minimum_size = Vector2(0, th + 14)
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	row.add_child(sc)
	var tiles := UI.hbox(8)
	sc.add_child(tiles)
	var picked: Control = null
	for i in items.size():
		var it: Dictionary = items[i]
		var b := Button.new()
		b.custom_minimum_size = Vector2(th * 1.3, th)
		b.focus_mode = Control.FOCUS_ALL
		var on := i == sel
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(col, 0.16) if on else Color(1, 1, 1, 0.035)
		sb.border_color = col if on else Color(1, 1, 1, 0.16)
		sb.set_border_width_all(2 if on else 1)
		var hv := sb.duplicate()
		hv.bg_color = Color(col, 0.22)
		hv.border_color = Color(col, 0.8)
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", hv)
		b.add_theme_stylebox_override("focus", hv)
		b.add_theme_stylebox_override("pressed", hv)
		var idx := i
		b.pressed.connect(func(): cb.call(idx))
		UI.click_sound(b)
		var v := UI.vbox(0)
		v.set_anchors_preset(Control.PRESET_FULL_RECT)
		v.offset_left = 6
		v.offset_right = -6
		v.offset_top = 4
		v.offset_bottom = -4
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(v)
		var ic := TextureRect.new()
		ic.texture = it.get("tex")
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.size_flags_vertical = Control.SIZE_EXPAND_FILL
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var top := UI.hbox(4)
		top.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(top)
		var lk := UI.label(("🔒 " + String(it["lock"])) if String(it.get("lock", "")) != "" else "", 10, UI.BAD)
		lk.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(lk)
		var tg := UI.label(String(it.get("tag", "")), 10, col)
		tg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top.add_child(tg)
		v.add_child(ic)
		var nm := UI.label(String(it.get("name", "")), 12)
		nm.clip_text = true
		nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(nm)
		var su := UI.label(String(it.get("sub", "")), 11, it.get("sub_col", UI.GOLD))
		su.clip_text = true
		su.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(su)
		if bool(it.get("dim", false)):
			b.modulate = Color(1, 1, 1, 0.55)
		tiles.add_child(b)
		if on:
			picked = b
	var right := UI.button("›", func(): cb.call(mini(sel + 1, items.size() - 1)))
	right.custom_minimum_size = Vector2(30, th)
	right.disabled = sel >= items.size() - 1
	row.add_child(right)
	if picked != null:
		# keep the pick in view (once the strip has its size)
		sc.ready.connect(func(): sc.ensure_control_visible.call_deferred(picked), CONNECT_ONE_SHOT)
	return row


## The faint grid with a glow behind a picture.
class _Grid extends Control:
	var col := Color.WHITE

	func _init() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var c := r.get_center() + Vector2(0, size.y * 0.06)
		for k in 6:
			draw_circle(c, size.y * (0.5 - k * 0.07), Color(col, 0.025))
		var step := 32.0
		var x := fmod(size.x * 0.5, step)
		while x < size.x:
			draw_line(Vector2(x, 0), Vector2(x, size.y), Color(1, 1, 1, 0.04), 1.0)
			x += step
		var y := fmod(size.y * 0.5, step)
		while y < size.y:
			draw_line(Vector2(0, y), Vector2(size.x, y), Color(1, 1, 1, 0.04), 1.0)
			y += step
		# a floor ring under the picture (as in the gear shop)
		var fc := Vector2(size.x * 0.5, size.y * 0.86)
		draw_set_transform(fc, 0.0, Vector2(1.0, 0.16))
		draw_circle(Vector2.ZERO, size.x * 0.34, Color(col, 0.07))
		draw_arc(Vector2.ZERO, size.x * 0.34, 0.0, TAU, 64, Color(col, 0.45), 2.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
