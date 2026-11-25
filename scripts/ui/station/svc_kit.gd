extends RefCounted
## Window rework (Luz, 18 Nov 2026): the building blocks the reworked station windows share.
##  • detail(): the top – a big picture on the left, the name, values and buttons on the right;
##  • strip(): the bottom – a row of small tiles, browsed right to left (arrows, Q / E, the wheel, the stick);
##  • chips(): a row of filter buttons; stats(): a grid of values (key small above, value below), with bars.
## Sizes follow the screen, so the windows fit from 1280×720 up.


## The narrow layout (Luz, 25 Nov 2026: a half of a split picture at 1920 x 1080, a small screen): the same parts,
## the picture above its values instead of beside them, rows that wrap.
static func narrow(node: Node) -> bool:
	return UI.narrow(node)


## How tall the big picture may be on this screen.
static func pic_height(node: Control) -> float:
	if narrow(node):
		return clampf(node.get_viewport().get_visible_rect().size.y * 0.24, 150.0, 280.0)
	return clampf(node.get_viewport().get_visible_rect().size.y * 0.40, 190.0, 470.0)


## A framed picture panel with a faint grid and a glow in `col`; `tex` scaled up crisp. Corner notes top left / right.
## `max_px` > 0: a small picture (a drone) is drawn at most that big instead of filling the panel.
static func picture(tex: Texture2D, col: Color, h: float, note_l: String = "", note_r: String = "", max_px: float = 0.0) -> PanelContainer:
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
	if max_px > 0.0:
		tr.set_anchors_preset(Control.PRESET_CENTER)
		tr.custom_minimum_size = Vector2(max_px, max_px)
		tr.offset_left = -max_px * 0.5
		tr.offset_right = max_px * 0.5
		tr.offset_top = -max_px * 0.5
		tr.offset_bottom = max_px * 0.5
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
	var row: BoxContainer = UI.vbox(10) if narrow(parent) else UI.hbox(14)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(row)
	if narrow(parent):
		pic.custom_minimum_size.x = 0.0                  # (as wide as the window, above its values)
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
		var b := tile(items[i], i == sel, col, Vector2(th * 1.3, th), cb.bind(i))
		var on := i == sel
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


## One tile: `it` {tex | node, name, sub, sub_col, tag, lock, note, note_col, dim}; `go` runs on a click.
static func tile(it: Dictionary, on: bool, col: Color, sz: Vector2, go: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = sz
	b.focus_mode = Control.FOCUS_ALL
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
	b.pressed.connect(go)
	UI.click_sound(b)
	var v := UI.vbox(0)
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 6
	v.offset_right = -6
	v.offset_top = 4
	v.offset_bottom = -4
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	var top := UI.hbox(4)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(top)
	var note := ("🔒 " + String(it["lock"])) if String(it.get("lock", "")) != "" else String(it.get("note", ""))
	var lk := UI.label(note, 10, it.get("note_col", UI.BAD))
	lk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lk.clip_text = true
	top.add_child(lk)
	var tg := UI.label(String(it.get("tag", "")), 10, col)
	tg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(tg)
	var ic: Control
	if it.has("node"):
		ic = it["node"]
	else:
		var tr := TextureRect.new()
		tr.texture = it.get("tex")
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic = tr
	ic.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
		b.modulate = Color(1, 1, 1, 0.5)
	return b


## Tiles in a scrolling grid `h` high (columns by the width it gets); returns the grid.
static func grid(parent: Control, items: Array, sel: int, col: Color, cb: Callable, h: float, tile_sz: Vector2 = Vector2(150, 132)) -> GridContainer:
	var box := UI.neon_panel(Color(1, 1, 1, 0.12), Color(0.02, 0.02, 0.05, 0.6), 1)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.custom_minimum_size = Vector2(0, h)
	parent.add_child(box)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER      # the grid's width must not push the window
	box.add_child(sc)
	var g := GridContainer.new()
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	sc.add_child(g)
	var fit_cols := func():
		var c := maxi(1, int((sc.size.x - 14.0 + 10.0) / (tile_sz.x + 10.0)))
		if c != g.columns:
			g.columns = c
	sc.resized.connect(fit_cols)
	var vw := parent.get_viewport().get_visible_rect().size.x
	g.columns = maxi(1, int((vw * 0.55 - 60.0) / (tile_sz.x + 10.0)))
	for i in items.size():
		g.add_child(tile(items[i], i == sel, col, tile_sz, cb.bind(i)))
	return g


## The cargo hold as a bar with its numbers.
static func cargo_bar(parent: Control, f: ShipFitting) -> void:
	var cmax := maxf(float(f.stats()["cargo_max"]), 1.0)
	parent.add_child(UI.label("Cargo hold", 12, UI.TEXT_DIM))
	var bar := UI.bar(UI.NEON_CYAN, 150)
	bar.max_value = cmax
	bar.value = f.cargo_used()
	bar.custom_minimum_size = Vector2(150, 8)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	parent.add_child(bar)
	parent.add_child(UI.label("%.0f / %.0f m³" % [f.cargo_used(), cmax], 13))


## What a station job makes, as text ("120 Titanium Ore → 50 Titanium Ingots", "4 Circuit Boards", a module).
static func job_text(j: Dictionary) -> String:
	match String(j.get("type", "module")):
		"refine":
			return "%d %s  →  %.0f %s" % [int(j.get("n", 0)), GameData.item_name(String(j["item"])), float(j["out"]), GameData.item_name(String(j["out_id"]))]
		"component":
			return "%.0f × %s" % [float(j["out"]), GameData.item_name(String(j["out_id"]))]
	return GameData.module_name(String(j["item"]))


## The "In production" tab (Luz, 18 Nov 2026): the job running now, big, with its progress; the queue behind it;
## what is ready to collect. `run(cmd)` sends a command (and refreshes the window).
static func production(parent: Control, station_id: String, lane: String, col: Color, run: Callable, h: float) -> void:
	var jobs: Array = GameState.jobs_at(station_id, lane)
	var waiting: Array = jobs.filter(func(j): return not bool(j.get("done", false)))
	var ready: Array = jobs.filter(func(j): return bool(j.get("done", false)))
	var row := UI.hbox(12)
	row.custom_minimum_size = Vector2(0, h)
	parent.add_child(row)
	# now and next
	var lbox := UI.neon_panel(Color(col, 0.6), Color(col.darkened(0.88), 0.85), 1)
	lbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbox.size_flags_stretch_ratio = 1.4
	row.add_child(lbox)
	var lsc := ScrollContainer.new()
	lsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	lbox.add_child(lsc)
	var lv := UI.vbox(10)
	lv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lsc.add_child(lv)
	lv.add_child(UI.label("NOW", 12, UI.TEXT_DIM))
	if waiting.is_empty():
		lv.add_child(UI.label("Nothing in production. Start a job in the other tab.", 15, UI.TEXT_DIM))
	else:
		var j: Dictionary = waiting[0]
		var nr := UI.hbox(14)
		lv.add_child(nr)
		nr.add_child(_job_pic(j, 64))
		var nv := UI.vbox(4)
		nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nr.add_child(nv)
		nv.add_child(UI.label(job_text(j), 20, col))
		var tot := maxf(float(j["total"]), 0.01)
		var bar := UI.bar(col, 300)
		bar.max_value = tot
		bar.value = tot - float(j["left"])
		bar.custom_minimum_size = Vector2(0, 12)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nv.add_child(bar)
		nv.add_child(UI.label("%d %%  •  %s left of %s" % [int(100.0 * (1.0 - float(j["left"]) / tot)), Industry.fmt_secs(float(j["left"])), Industry.fmt_secs(tot)], 13))
		var line := ColorRect.new()
		line.color = Color(1, 1, 1, 0.1)
		line.custom_minimum_size = Vector2(0, 1)
		lv.add_child(line)
		lv.add_child(UI.label("WAITING (%d)" % (waiting.size() - 1), 12, UI.TEXT_DIM))
		if waiting.size() == 1:
			lv.add_child(UI.label("Nothing else in the queue.", 13, UI.TEXT_DIM))
		var at := float(j["left"])
		for k in range(1, waiting.size()):
			var w: Dictionary = waiting[k]
			at += float(w["left"])
			var wr := UI.hbox(10)
			lv.add_child(wr)
			wr.add_child(UI.label("%d." % k, 13, UI.TEXT_DIM))
			wr.add_child(_job_pic(w, 26))
			var wl := UI.label(job_text(w), 13)
			wl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			wl.clip_text = true
			wr.add_child(wl)
			wr.add_child(UI.label(Industry.fmt_secs(float(w["total"])), 12, UI.TEXT_DIM))
			wr.add_child(UI.label("done in %s" % Industry.fmt_secs(at), 12, col))
	# ready to collect
	var rbox := UI.neon_panel(Color(UI.GOOD, 0.5), Color(0.02, 0.06, 0.04, 0.85), 1)
	rbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(rbox)
	var rsc := ScrollContainer.new()
	rsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rbox.add_child(rsc)
	var rv := UI.vbox(8)
	rv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rsc.add_child(rv)
	var rh := UI.hbox(8)
	rv.add_child(rh)
	var rt := UI.label("READY TO COLLECT", 12, UI.GOOD)
	rt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rh.add_child(rt)
	if not ready.is_empty():
		rh.add_child(UI.button("Collect all", func(): run.call({"type": "job_collect", "id": -1, "lane": lane})))
	if lane == "fab":
		rv.add_child(UI.label("Modules go straight into this station's storage; components wait here.", 11, UI.TEXT_DIM))
	if ready.is_empty():
		rv.add_child(UI.label("Nothing finished yet.", 13, UI.TEXT_DIM))
	for j in ready:
		var rr := UI.hbox(10)
		rv.add_child(rr)
		rr.add_child(_job_pic(j, 30))
		var nl := UI.label("%.0f %s" % [float(j["out"]), GameData.item_name(String(j["out_id"]))], 14, UI.GOOD)
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nl.clip_text = true
		rr.add_child(nl)
		rr.add_child(UI.label("%.1f m³" % (float(j["out"]) * GameData.item_volume(String(j["out_id"]))), 12, UI.TEXT_DIM))
		var jid := int(j.get("id", 0))
		rr.add_child(UI.button("Collect", func(): run.call({"type": "job_collect", "id": jid})))


static func _job_pic(j: Dictionary, sz: float) -> Control:
	if String(j.get("type", "module")) == "module":
		return UI.icon(PixelArt.module_icon(String(j["item"])), sz)
	var ing := Ingot.new(good_color(String(j["out_id"])))
	ing.custom_minimum_size = Vector2(sz * 1.3, sz)
	return ing


## A tile with bars: `bars` [[label, fraction, colour], …], `foot` a line below (with `foot_col`); `go` on a click.
static func bar_tile(title: String, bars: Array, foot: String, foot_col: Color, on: bool, col: Color, sz: Vector2, go: Callable) -> Button:
	var b := tile({"name": "", "sub": ""}, on, col, sz, go)
	var v: VBoxContainer = b.get_child(0)
	UI.clear(v)
	v.add_theme_constant_override("separation", 2)
	var t := UI.label(title, 13)
	t.clip_text = true
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(t)
	for e in bars:
		var l := UI.label(String(e[0]), 11, UI.TEXT_DIM)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(l)
		var br := UI.bar(e[2], 100)
		br.max_value = 1.0
		br.value = clampf(float(e[1]), 0.0, 1.0)
		br.custom_minimum_size = Vector2(0, 6)
		br.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(br)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(sp)
	var fl := UI.label(foot, 11, foot_col)
	fl.clip_text = true
	fl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(fl)
	return b


## A row of tiles side by side (no scrolling needed for a few); returns the row.
static func tile_row(parent: Control, tiles: Array) -> HFlowContainer:
	var r := HFlowContainer.new()
	r.add_theme_constant_override("h_separation", 8)
	r.add_theme_constant_override("v_separation", 8)
	parent.add_child(r)
	for t in tiles:
		r.add_child(t)
	return r


## A buy / sell block: a slider with a number and a max button, the total, the button. `total(n)`, `label(n)` give
## the texts, `go(n)` runs it. Returns the block.
static func amount_block(parent: Control, title: String, mx: int, n0: int, col: Color, total: Callable, label: Callable, go: Callable, max_text: String, note: String = "") -> VBoxContainer:
	var v := UI.vbox(6)
	parent.add_child(v)
	var line := ColorRect.new()
	line.color = Color(1, 1, 1, 0.1)
	line.custom_minimum_size = Vector2(0, 1)
	v.add_child(line)
	v.add_child(UI.label(title, 12, UI.TEXT_DIM))
	var sr := UI.hbox(8)
	v.add_child(sr)
	var sl := HSlider.new()
	sl.min_value = 0
	sl.max_value = maxi(mx, 1)
	sl.step = 1
	sl.value = n0
	sl.editable = mx > 0
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sr.add_child(sl)
	var sp := SpinBox.new()
	sp.max_value = maxi(mx, 0)
	sp.value = n0
	sp.editable = mx > 0
	sp.custom_minimum_size = Vector2(80, 0)
	sr.add_child(sp)
	var mxb := UI.button(max_text, func(): sl.value = mx)
	mxb.disabled = mx <= 0
	sr.add_child(mxb)
	var tr := UI.hbox(8)
	v.add_child(tr)
	var tl := UI.label(total.call(n0), 13, col)
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tl.clip_text = true
	tr.add_child(tl)
	var n_now := [n0]
	var gb := UI.button(label.call(n0), func(): go.call(n_now[0]))
	gb.disabled = mx <= 0 or n0 <= 0
	tr.add_child(gb)
	var sync := func(val: float):
		var n := int(val)
		n_now[0] = n
		if int(sl.value) != n:
			sl.set_value_no_signal(n)
		if int(sp.value) != n:
			sp.set_value_no_signal(n)
		tl.text = total.call(n)
		gb.text = label.call(n)
		gb.disabled = mx <= 0 or n <= 0
	sl.value_changed.connect(sync)
	sp.value_changed.connect(sync)
	if note != "":
		var nl := UI.label(note, 11, UI.TEXT_DIM)
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(nl)
	return v


## A mine drawn in its colour (munitions have no pictures).
class MineGlyph extends Control:
	var col := Color.WHITE

	func _init(c: Color = Color.WHITE) -> void:
		col = c
		custom_minimum_size = Vector2(40, 40)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.3
		for k in 8:
			var a := k * TAU / 8.0
			draw_line(c + Vector2.from_angle(a) * r * 0.9, c + Vector2.from_angle(a) * r * 1.35, Color(0.55, 0.5, 0.48), maxf(2.0, r * 0.14))
		draw_circle(c, r, Color(0.3, 0.26, 0.24))
		draw_circle(c, r * 0.78, Color(0.42, 0.37, 0.34))
		draw_circle(c, r * 0.3, col)
		draw_circle(c, r * 0.16, col.lightened(0.5))


## A refined good or component drawn as a bar of metal in its own colour (there are no pictures for them).
class Ingot extends Control:
	var col := Color.WHITE

	func _init(c: Color = Color.WHITE) -> void:
		col = c
		custom_minimum_size = Vector2(40, 24)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		var w := minf(size.x * 0.7, size.y * 2.4)
		var h := w * 0.42
		var c := size * 0.5
		var top := PackedVector2Array([c + Vector2(-w * 0.36, -h * 0.5), c + Vector2(w * 0.36, -h * 0.5), c + Vector2(w * 0.5, h * 0.5), c + Vector2(-w * 0.5, h * 0.5)])
		draw_colored_polygon(top, col.darkened(0.25))
		draw_colored_polygon(PackedVector2Array([top[0], top[1], c + Vector2(w * 0.42, -h * 0.1), c + Vector2(-w * 0.42, -h * 0.1)]), col.lightened(0.2))
		draw_polyline(PackedVector2Array([top[0], top[1], top[2], top[3], top[0]]), col.darkened(0.6), 2.0)


## A colour for a refined good or component (from its name; ices and water blue).
static func good_color(id: String) -> Color:
	var n := id.to_lower()
	if n.contains("water") or n.contains("ice") or n.contains("nitrogen") or n.contains("coolant") or n.contains("oxygen"):
		return Color(0.6, 0.85, 1.0)
	if n.contains("gold"):
		return Color(1.0, 0.82, 0.35)
	if n.contains("copper"):
		return Color(0.95, 0.6, 0.35)
	if n.contains("iron") or n.contains("steel"):
		return Color(0.72, 0.62, 0.58)
	var h := float(hash(id) % 1000) / 1000.0
	return Color.from_hsv(h, 0.35, 0.9)


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
