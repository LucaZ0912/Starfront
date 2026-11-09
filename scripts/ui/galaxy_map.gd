class_name GalaxyMap
extends CanvasLayer
const NotoriousData = preload("res://scripts/core/notorious.gd")
## Galaxy map: systems, hyperspace routes, own ships, route planning, fleet overview.

signal view_system(id: int)
signal routes_changed
signal closed
signal focus_ship(uid: int)

var map: Control
var info: RichTextLabel
var fleet_box: VBoxContainer
var course_btn: Button
var view_btn: Button
var selected_system := -1
var hover_system := -1
var planned_path: Array = []
var _from_system := -1
var transit_mode := false
var title_label: Label
var _t := 0.0
var econ_filter := ""            # station type highlighted on the map ("" = all)
var _legend_btns := {}
var show_territory := true       # faction territories (phase 0.5 package 10), key T
var show_traffic := true         # trade convoys (phase 0.5 package 11)
var _terr_btn: Button
## Package 40: zoom and pan – view_zoom 1 shows the whole cluster; the centre of the view in map units.
var view_zoom := 1.0
var view_center := Vector2.ZERO
var _drag_from := Vector2.ZERO
var _dragging := false
var _drag_moved := false
const ZOOM_MAX := 6.0
const OPEN_ZOOM := 3.2
## Zoomed out further than this, the map is an overview: no system names, the territories always shown and named,
## the Rim and the Far Reaches written along their rings.
const OVERVIEW_ZOOM := 1.8
var _traffic_btn: Button

const FactionData = preload("res://data/factions.gd")
const TERR_CELL := 8.0           # map units per territory pixel
static var _terr_tex: Texture2D
static var _terr_key := ""
static var _centres := {}
var veil_rect: ColorRect
static var _centres_key := ""


func _ready() -> void:
	layer = 15
	visible = false
	var bg := ColorRect.new()
	bg.color = Color(0.01, 0.015, 0.04, 0.97)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	bg.add_child(margin)
	var hb := UI.hbox(12)
	margin.add_child(hb)

	map = Control.new()
	map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map.mouse_filter = Control.MOUSE_FILTER_STOP
	map.clip_contents = true
	map.draw.connect(_draw_map)
	# 0.6.40.6: the Veil – wavering black clouds with violet light, under everything the map draws
	veil_rect = ColorRect.new()
	veil_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil_rect.z_index = -1                  # map at z 1, the clouds at 0 – above the panel's background
	map.z_index = 1
	var vm := ShaderMaterial.new()
	vm.shader = preload("res://shaders/veil_clouds.gdshader")
	veil_rect.material = vm
	map.add_child(veil_rect)
	map.gui_input.connect(_on_map_input)
	hb.add_child(map)
	# overlay switches on the map itself (saved in the settings)
	show_territory = bool(SaveGame.settings.get("map_territory", true))
	show_traffic = bool(SaveGame.settings.get("map_traffic", true))
	var ob := UI.hbox(6)
	ob.position = Vector2(8, 8)
	map.add_child(ob)
	_terr_btn = _overlay_button("Territory [%s]" % Keybinds.key_text("map_territory"), show_territory,
		"Faction territories (striped = contested) and coats of arms at the capitals", func(on: bool): set_territory(on))
	ob.add_child(_terr_btn)
	_traffic_btn = _overlay_button("Convoys", show_traffic, "Trade convoys under way (coloured by faction)", func(on: bool):
		show_traffic = on
		SaveGame.settings["map_traffic"] = on
		SaveGame.save_settings()
		map.queue_redraw())
	ob.add_child(_traffic_btn)

	var side := UI.panel()
	side.custom_minimum_size = Vector2(360, 0)
	hb.add_child(side)
	var sv := UI.vbox(8)
	side.add_child(sv)
	var head := UI.hbox()
	title_label = UI.label("Galaxy Map", 20, UI.ACCENT)
	head.add_child(title_label)
	head.add_child(UI.spacer())
	head.add_child(UI.button("Close [%s]" % Keybinds.key_text("galaxy_map"), close))
	sv.add_child(head)
	info = RichTextLabel.new()
	info.bbcode_enabled = true
	info.custom_minimum_size = Vector2(0, 260)
	info.fit_content = true
	sv.add_child(info)
	course_btn = UI.button("Set course", _set_course)
	sv.add_child(course_btn)
	wormhole_btn = UI.button("Wormhole jump", _wormhole)
	wormhole_btn.visible = false
	sv.add_child(wormhole_btn)
	view_btn = UI.button("View system", _view_selected)
	view_btn.visible = false
	sv.add_child(HSeparator.new())
	# package 42: the economies of the systems (main and secondary) – click to highlight
	sv.add_child(UI.label("Economies – click to highlight", 14, UI.ACCENT))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 3)
	sv.add_child(grid)
	for et in Economy.ORDER:
		var t: String = et
		var b := Button.new()
		b.text = "■ " + Economy.name_of(t)
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 11)
		b.add_theme_color_override("font_color", Economy.color_of(t))
		b.add_theme_color_override("font_pressed_color", Color.WHITE)
		b.custom_minimum_size = Vector2(112, 0)
		b.tooltip_text = "Highlight every system with %s as its main or secondary economy
%s" % [Economy.name_of(t), Economy.ECONOMIES[t]["text"]]
		b.pressed.connect(func(): _set_filter(t))
		grid.add_child(b)
		_legend_btns[t] = b
	sv.add_child(UI.label("Squares = stations (bigger = higher tier)  •  pips = prosperity (1 Impoverished … 5 Rich)", 11, Color(0.6, 0.7, 0.8)))
	sv.add_child(HSeparator.new())
	sv.add_child(UI.label("Factions", 14, UI.ACCENT))
	var fg := GridContainer.new()
	fg.columns = 3
	fg.add_theme_constant_override("h_separation", 6)
	fg.add_theme_constant_override("v_separation", 2)
	sv.add_child(fg)
	for fid in FactionData.FACTIONS:
		var row := UI.hbox(3)
		var tr := TextureRect.new()
		tr.texture = CrestArt.texture(fid)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(17, 19)
		row.add_child(tr)
		var fl := UI.label(FactionData.short_of(fid), 11, FactionData.color_of(fid))
		row.add_child(fl)
		var fd: Dictionary = FactionData.FACTIONS[fid]
		row.tooltip_text = "%s – %s\n\"%s\"%s" % [fd["name"], fd["gov"], fd["motto"], "" if fd["territory"] else "\nNo territory – appears as pirates anywhere"]
		row.mouse_filter = Control.MOUSE_FILTER_PASS
		fg.add_child(row)
	# 39d: independent systems
	var irow := UI.hbox(3)
	var isw := ColorRect.new()
	isw.color = INDEPENDENT_COLOR
	isw.custom_minimum_size = Vector2(12, 12)
	irow.add_child(isw)
	irow.add_child(UI.label("Independent", 11, INDEPENDENT_COLOR))
	irow.tooltip_text = "Independent systems – no power holds them (the private manufacturers' homes)"
	irow.mouse_filter = Control.MOUSE_FILTER_PASS
	fg.add_child(irow)
	sv.add_child(HSeparator.new())
	sv.add_child(UI.label("Your ships", 16, UI.ACCENT))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sv.add_child(scroll)
	fleet_box = UI.vbox(4)
	fleet_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(fleet_box)
	sv.add_child(UI.label("Lines: hyperspace routes\nClick: select system, then \"Set course\"  •  Wheel: zoom  •  Drag: move", 11, Color(0.6, 0.7, 0.8)))


func _overlay_button(text: String, on: bool, tip: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.toggle_mode = true
	b.button_pressed = on
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 12)
	b.tooltip_text = tip
	b.toggled.connect(cb)
	return b


func set_territory(on: bool) -> void:
	show_territory = on
	if _terr_btn != null:
		_terr_btn.set_pressed_no_signal(on)
	SaveGame.settings["map_territory"] = on
	SaveGame.save_settings()
	map.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("map_territory") and not event.is_echo():
		set_territory(not show_territory)
		get_viewport().set_input_as_handled()


func _set_filter(t: String) -> void:
	econ_filter = "" if econ_filter == t else t
	for k in _legend_btns:
		_legend_btns[k].set_pressed_no_signal(k == econ_filter)
	map.queue_redraw()


## Stations of a system from the cluster plan: [[type, tier], …] (+ ["pirate_haven", tier]).
static func economies(s: Dictionary) -> Array:
	var out: Array = (s.get("stations_plan", []) as Array).duplicate()
	if int(s.get("haven_tier", 0)) > 0:
		out.append(["pirate_haven", int(s["haven_tier"])])
	return out


func _view_selected() -> void:
	if selected_system >= 0:
		view_system.emit(selected_system)


func open(p_transit: bool = false) -> void:
	transit_mode = p_transit
	visible = true
	title_label.text = "Hyperspace – Star Map" if transit_mode else "Galaxy Map"
	if selected_system < 0:
		selected_system = GameState.current_system
	# package 40: open close in round the current system
	view_zoom = OPEN_ZOOM
	view_center = Universe.systems[GameState.current_system]["pos"]
	_clamp_view()
	refresh()


func close() -> void:
	if not visible:
		return
	visible = false
	transit_mode = false
	closed.emit()


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	map.queue_redraw()
	if int(_t * 2.0) != int((_t - delta) * 2.0):
		_rebuild_fleet()


func refresh() -> void:
	_plan()
	_update_info()
	_rebuild_fleet()
	map.queue_redraw()


# ---------------------------------------------------------------- Coordinates

func _fit_scale() -> float:
	var ms := Universe.MAP_SIZE
	return minf((map.size.x - 40.0) / ms.x, (map.size.y - 40.0) / ms.y)


func _scale() -> float:
	return _fit_scale() * view_zoom


func _to_screen(p: Vector2) -> Vector2:
	if view_center == Vector2.ZERO:
		view_center = Universe.MAP_SIZE * 0.5
	return map.size * 0.5 + (p - view_center) * _scale()


func _to_map(sp: Vector2) -> Vector2:
	return view_center + (sp - map.size * 0.5) / maxf(_scale(), 0.0001)


## Keeps the view on the cluster.
func _clamp_view() -> void:
	var half := map.size * 0.5 / maxf(_scale(), 0.0001) if map != null else Vector2.ZERO
	var ms := Universe.MAP_SIZE
	view_center.x = clampf(view_center.x, minf(half.x, ms.x * 0.5), maxf(ms.x - half.x, ms.x * 0.5))
	view_center.y = clampf(view_center.y, minf(half.y, ms.y * 0.5), maxf(ms.y - half.y, ms.y * 0.5))


## Zoom by `k` keeping the map point under `at` (screen) in place.
func zoom_at(at: Vector2, k: float) -> void:
	var before := _to_map(at)
	view_zoom = clampf(view_zoom * k, 1.0, ZOOM_MAX)
	view_center += before - _to_map(at)
	_clamp_view()
	map.queue_redraw()


func _system_at(pos: Vector2) -> int:
	for s in Universe.systems:
		if _to_screen(s["pos"]).distance_to(pos) < 14.0:
			return s["id"]
	return -1


# ---------------------------------------------------------------- Drawing

func _sec_color(sec: float) -> Color:
	return Color.from_hsv(sec * 0.33, 0.8, 0.95)


## Territory overlay as a coarse pixel image: every cell belongs to the nearest system (up to
## ~145 map units away) and takes its owner's colour; contested systems are striped in the colours
## of their claimants; borders between owners are drawn brighter. Built once per galaxy.
static func territory_texture() -> Texture2D:
	var key := "%d_%d" % [Universe.seed_value, Universe.systems.size()]
	if _terr_tex != null and _terr_key == key:
		return _terr_tex
	var ms := Universe.MAP_SIZE
	var w := int(ms.x / TERR_CELL)
	var h := int(ms.y / TERR_CELL)
	var bucket := 150.0
	var buckets := {}
	for s in Universe.systems:
		var b := Vector2i(int((s["pos"] as Vector2).x / bucket), int((s["pos"] as Vector2).y / bucket))
		if not buckets.has(b):
			buckets[b] = []
		buckets[b].append(s)
	var owner := PackedInt32Array()
	owner.resize(w * h)
	for y in h:
		for x in w:
			var p := Vector2((x + 0.5) * TERR_CELL, (y + 0.5) * TERR_CELL)
			var bc := Vector2i(int(p.x / bucket), int(p.y / bucket))
			var best := -1
			var bd := 145.0 * 145.0
			for by in range(bc.y - 1, bc.y + 2):
				for bx in range(bc.x - 1, bc.x + 2):
					for s2 in buckets.get(Vector2i(bx, by), []):
						var d := (s2["pos"] as Vector2).distance_squared_to(p)
						if d < bd:
							bd = d
							best = int(s2["id"])
			owner[y * w + x] = best
	# region key per system: owner faction, or the claimant pair of a contested system
	var rkey := {}
	for s3 in Universe.systems:
		var f: String = s3.get("faction", "")
		rkey[int(s3["id"])] = f if f != "" else ("ind" if s3.get("independent", false) else "c:" + ",".join(PackedStringArray(s3.get("claimants", []))))
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in h:
		for x in w:
			var o := owner[y * w + x]
			if o < 0:
				continue
			var k: String = rkey[o]
			var border := false
			for d2: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx := x + d2.x
				var ny := y + d2.y
				if nx < 0 or ny < 0 or nx >= w or ny >= h:
					continue
				var o2 := owner[ny * w + nx]
				if o2 < 0 or rkey[o2] != k:
					border = true
					break
			var col := Color(0.6, 0.62, 0.66)
			var alpha := 0.13
			var sys: Dictionary = Universe.systems[o]
			if String(sys.get("faction", "")) != "":
				col = FactionData.color_of(sys["faction"])
			elif sys.get("independent", false):
				col = INDEPENDENT_COLOR                      # 39d: independent systems in yellow
				alpha = 0.16
			else:
				var cl: Array = sys.get("claimants", [])
				alpha = 0.11
				if not cl.is_empty():
					col = FactionData.color_of(cl[int(floor((x + y) / 3.0)) % cl.size()])
			if border:
				col = col.lightened(0.25)
				alpha = 0.55
			img.set_pixel(x, y, Color(col, alpha))
	_terr_tex = ImageTexture.create_from_image(img)
	_terr_key = key
	return _terr_tex


func _draw_map() -> void:
	var font := ThemeDB.fallback_font
	var cls_cols := [Color(0.4, 0.6, 1.0, 0.6), Color(1.0, 0.75, 0.3, 0.6), Color(1.0, 0.35, 0.35, 0.6)]
	var overview := is_overview()
	if show_territory or overview:
		var tex0 := territory_texture()
		map.draw_texture_rect(tex0, Rect2(_to_screen(Vector2.ZERO), Universe.MAP_SIZE * _scale()), false)
		# coat of arms next to every capital / pirate stronghold
		for sc in Universe.systems:
			if sc.get("capital", false) and String(sc.get("faction", "")) != "":
				var cp := _to_screen(sc["pos"])
				var ct := CrestArt.texture(sc["faction"])
				var csz := Vector2(ct.get_width(), ct.get_height()) * 0.75
				map.draw_texture_rect(ct, Rect2(cp + Vector2(-csz.x - 12.0, -csz.y * 0.5 - 4.0), csz), false)
	# Routes
	for s in Universe.systems:
		for nb in s["links"]:
			if nb < s["id"]:
				continue
			map.draw_line(_to_screen(s["pos"]), _to_screen(Universe.systems[nb]["pos"]), cls_cols[0], 1.6)     # 0.6.40.6: one kind of route
	_update_veil()
	if overview:
		_draw_ring_names(font)
	_draw_anomaly_finder(font)
	# Planned route
	if not planned_path.is_empty() and _from_system >= 0:
		var prev: Vector2 = _to_screen(Universe.systems[_from_system]["pos"])
		for sid in planned_path:
			var p := _to_screen(Universe.systems[sid]["pos"])
			map.draw_line(prev, p, Color(0.3, 1.0, 0.5, 0.9), 4.0)
			prev = p
	# Routes of own ships
	for f in GameState.fleet:
		if f.route.is_empty():
			continue
		var start: int = int(f.transit_to) if f.transit_kind == "jump" else f.system_id
		var pv: Vector2 = _to_screen(Universe.systems[start]["pos"])
		for sid in f.route:
			if int(sid) == start:
				continue
			var pn := _to_screen(Universe.systems[int(sid)]["pos"])
			_dashed(pv, pn, Color(0.4, 0.9, 1.0, 0.5))
			pv = pn
	# Count ships per system
	var counts := {}
	for f in GameState.fleet:
		if f.transit_kind != "jump":
			counts[f.system_id] = int(counts.get(f.system_id, 0)) + 1
	# Systems
	for s in Universe.systems:
		var p := _to_screen(s["pos"])
		var sec: float = s["security"]
		var col := _sec_color(sec)
		var econ := economies(s)
		var dim := false
		if econ_filter != "":
			dim = not Economy.has_economy(int(s["id"]), econ_filter)      # package 42: main or secondary economy
			if not dim:
				var fc: Color = Economy.color_of(econ_filter)
				map.draw_circle(p, 15.0 + 2.0 * sin(_t * 4.0), Color(fc, 0.18))
				map.draw_arc(p, 15.0 + 2.0 * sin(_t * 4.0), 0.0, TAU, 28, fc, 2.0)
		if dim:
			col = Color(col, 0.25)
		map.draw_circle(p, 4.5 if overview else 7.0, col)
		var named: bool = not overview or s["id"] == GameState.current_system or s["id"] == selected_system or s["id"] == hover_system
		# station squares (size = tier), a red diamond for a Pirate Haven
		var ex := 11.0
		for e in (econ if not overview else []):
			var ec: Color = PixelArt.STATION_ACCENT.get(String(e[0]), Color.WHITE)
			var sz := 3.0 + float(e[1]) * 2.0
			if dim:
				ec = Color(ec, 0.25)
			if e[0] == "pirate_haven":
				map.draw_set_transform(p + Vector2(ex + sz * 0.5, 15.0), PI * 0.25, Vector2.ONE)
				map.draw_rect(Rect2(Vector2.ONE * -sz * 0.4, Vector2.ONE * sz * 0.8), ec)
				map.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			else:
				map.draw_rect(Rect2(p + Vector2(ex, 15.0 - sz * 0.5), Vector2(sz, sz)), ec)
				map.draw_rect(Rect2(p + Vector2(ex, 15.0 - sz * 0.5), Vector2(sz, sz)), Color(0, 0, 0, 0.6), false, 1.0)
			ex += sz + 3.0
		if s.get("fortress", false):                 # package 40d: a pirate fortress
			map.draw_rect(Rect2(p - Vector2(10, 10), Vector2(20, 20)), Color(1.0, 0.3, 0.25, 0.4 if GameState.fortress_down(int(s["id"])) else 0.9), false, 2.0)
		if s.get("veil", false):
			map.draw_arc(p, 9.0 if not overview else 6.5, 0.0, TAU, 16, Color(0.75, 0.45, 1.0, 0.6 + 0.3 * sin(_t * 2.0 + float(s["id"]))), 1.5)
		if s["id"] == GameState.current_system:
			map.draw_arc(p, 12.0, 0.0, TAU, 24, Color.WHITE, 2.0)
		if s["id"] == selected_system:
			map.draw_arc(p, 16.0, 0.0, TAU, 24, Color(1.0, 0.9, 0.3), 2.0)
		if s["id"] == hover_system:
			map.draw_arc(p, 10.0, 0.0, TAU, 24, Color(1, 1, 1, 0.5), 1.0)
		if s["id"] == Universe.home_system:
			map.draw_rect(Rect2(p - Vector2(11, 11), Vector2(22, 22)), Color(0.5, 0.8, 1.0, 0.6), false, 1.0)
		# notorious pirates: last sighting (package 15)
		var nc: int = GameState.notorious.alive_in(int(s["id"])).size() if GameState.notorious != null else 0
		if nc > 0:
			map.draw_string(font, p + Vector2(-30, -8), "☠" + ("×%d" % nc if nc > 1 else ""), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1.0, 0.3, 0.3, 0.55 + 0.45 * absf(sin(_t * 2.5))))
		if named:
			map.draw_string_outline(font, p + Vector2(11, -6), s["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, Color(0, 0, 0, 0.8))
			map.draw_string(font, p + Vector2(11, -6), s["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.85, 0.9, 1.0, 0.3 if dim else 1.0))
		if overview:
			pass
		else:
			map.draw_string(font, p + Vector2(11, 7), "%.1f" % sec, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, col)
		# package 42: prosperity as five pips after the security, and the main economy as a small coloured mark
		if not overview and Universe.has_stations(int(s["id"])):
			var lv := Economy.level(int(s["id"]))
			var pc: Color = Economy.LEVEL_COLORS[lv]
			for i in 5:
				var pr := Rect2(p + Vector2(31.0 + i * 4.0, 1.0), Vector2(3, 3))
				map.draw_rect(pr, Color(pc, 0.3 if dim else 1.0) if i <= lv else Color(0.3, 0.33, 0.4, 0.25 if dim else 0.6))
			var ecm: Color = Economy.color_of(String(Economy.of(int(s["id"]))["main"]))
			map.draw_rect(Rect2(p + Vector2(-4.0, -15.0), Vector2(8, 3)), Color(ecm, 0.3 if dim else 0.95))
		if counts.has(s["id"]):
			map.draw_string(font, p + Vector2(-26, 4), "▲%d" % counts[s["id"]], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.4, 0.9, 1.0))
	if overview:
		_draw_faction_names(font)
	_draw_convoys()
	# Ships in hyperspace
	for f in GameState.fleet:
		if f.transit_kind != "jump":
			continue
		var a := _to_screen(Universe.systems[int(f.transit_from)]["pos"])
		var b := _to_screen(Universe.systems[int(f.transit_to)]["pos"])
		var prog: float = 1.0 - f.transit / maxf(f.transit_total, 0.01)
		var pos := a.lerp(b, prog)
		var dir := (b - a).normalized()
		map.draw_line(a, pos, Color(0.75, 0.45, 1.0, 0.8), 3.0)
		for i in 4:
			map.draw_circle(pos - dir * (i * 6.0), 5.0 - i, Color(0.8, 0.6, 1.0, 0.8 - i * 0.18))
		var tex := PixelArt.ship_texture(f.hull_id, f.faction)
		var sz := Vector2(tex.get_width(), tex.get_height()) * 1.5
		map.draw_set_transform(pos, dir.angle(), Vector2.ONE)
		map.draw_texture_rect(tex, Rect2(-sz * 0.5, sz), false)
		map.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if f.uid == GameState.active_uid:
			map.draw_arc(pos, sz.x * 0.8 + 3.0 * sin(_t * 5.0), 0.0, TAU, 24, Color(0.3, 1.0, 0.5), 1.5)


func is_overview() -> bool:
	return view_zoom < OVERVIEW_ZOOM


## Overview: every faction's name over the middle of its territory (pirate holdings smaller).
func _draw_faction_names(font: Font) -> void:
	var placed: Array = []
	var order: Array = faction_centres().keys()
	order.sort_custom(func(x, y): return int(FactionData.FACTIONS[x]["kind"] == "pirate") < int(FactionData.FACTIONS[y]["kind"] == "pirate"))
	for f in order:
		var pirate: bool = FactionData.FACTIONS[f]["kind"] == "pirate"
		var size := 13 if pirate else 19
		var txt: String = FactionData.short_of(f).to_upper()
		var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var base := _to_screen(faction_centres()[f])
		var p := base + Vector2(-w * 0.5, size * 0.35)
		# never on top of another label: step down or up until it is free
		for off in [0.0, 1.0, -1.0, 2.0, -2.0, 3.0, -3.0]:
			var q: Vector2 = base + Vector2(-w * 0.5, size * 0.35 + off * (size + 4.0))
			var r := Rect2(q + Vector2(-4, -size), Vector2(w + 8, size + 6))
			var free := true
			for o in placed:
				free = free and not r.intersects(o)
			if free:
				p = q
				placed.append(r)
				break
		var c: Color = FactionData.color_of(f)
		map.draw_string_outline(font, p, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 6, Color(0, 0, 0, 0.85))
		map.draw_string(font, p, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size, c.lightened(0.25))


## The middle of each faction's territory (map units) – only factions that hold systems.
static func faction_centres() -> Dictionary:
	var key := "%d_%d" % [Universe.seed_value, Universe.systems.size()]
	if _centres_key == key:
		return _centres
	var sums := {}
	for s in Universe.systems:
		var f := String(s.get("faction", ""))
		if f == "" or not FactionData.FACTIONS.has(f):
			continue
		if not sums.has(f):
			sums[f] = [Vector2.ZERO, 0]
		sums[f][0] += s["pos"]
		sums[f][1] += 1
	_centres = {}
	for f2 in sums:
		var c: Vector2 = sums[f2][0] / float(sums[f2][1])
		# the label sits on the faction's system nearest that middle, so it never floats in someone else's land
		var best: Vector2 = c
		var bd := INF
		for s2 in Universe.systems:
			if String(s2.get("faction", "")) == f2 and (s2["pos"] as Vector2).distance_to(c) < bd:
				bd = (s2["pos"] as Vector2).distance_to(c)
				best = s2["pos"]
		_centres[f2] = c.lerp(best, 0.5)
	_centres_key = key
	return _centres


## Overview: "THE RIM" and "THE FAR REACHES" written along their rings, top and bottom (and the sides for the outer one).
func _draw_ring_names(font: Font) -> void:
	var rim := (Universe.BELT_RING.x + Universe.BELT_RING.y) * 0.5
	var far := (Universe.OUTER_RING.x + Universe.OUTER_RING.y) * 0.5
	var rc := Color(0.95, 0.6, 0.35, 0.7)
	var fc := Color(0.7, 0.6, 0.95, 0.62)
	for top in [true, false]:
		_arc_text(font, "T H E   R I M", rim, -PI * 0.5 if top else PI * 0.5, top, 26, rc)
		_arc_text(font, "T H E   F A R   R E A C H E S", far, -PI * 0.5 if top else PI * 0.5, top, 28, fc)
	_arc_text(font, "T H E   F A R   R E A C H E S", far, PI, true, 28, fc)
	_arc_text(font, "T H E   F A R   R E A C H E S", far, 0.0, true, 28, fc)
	for top2 in [true, false]:
		_arc_text(font, "T H E   V E I L", VEIL_F + 0.12, -PI * 0.5 if top2 else PI * 0.5, top2, 30, Color(0.85, 0.55, 1.0, 0.75))


## Package 40c: beyond the Far Reaches the Veil glows – a violet haze round the cluster.
const VEIL_F := 2.38


func _update_veil() -> void:
	if veil_rect == null:
		return
	var vm := veil_rect.material as ShaderMaterial
	vm.set_shader_parameter("centre", _to_screen(Universe.MAP_SIZE * 0.5))
	vm.set_shader_parameter("radii", Universe.CORE_R * _scale())
	vm.set_shader_parameter("rect_size", map.size)


## Text along the ellipse (CORE_R × f round the middle of the map), centred on angle `mid`; `upright` reads it
## left to right with the letters' tops outward on the upper half, inward on the lower.
func _arc_text(font: Font, txt: String, f: float, mid: float, upright: bool, size: int, col: Color) -> void:
	var c := Universe.MAP_SIZE * 0.5
	var R := Universe.CORE_R * f
	var sc := _scale()
	var total := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var dir := 1.0 if upright else -1.0
	# speed along the ellipse (screen px per radian) at the middle – good enough over the short span of a label
	var speed := Vector2(R.x * sin(mid), R.y * cos(mid)).length() * sc
	var t := mid - dir * total * 0.5 / maxf(speed, 1.0)
	for ch in txt:
		var w := font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var sp := Vector2(R.x * sin(t), R.y * cos(t)).length() * sc
		var tc := t + dir * w * 0.5 / maxf(sp, 1.0)
		var pt := _to_screen(c + Vector2(cos(tc) * R.x, sin(tc) * R.y))
		var tang := Vector2(-sin(tc) * R.x, cos(tc) * R.y).normalized() * dir
		var rot := tang.angle()
		if ch != " ":
			map.draw_set_transform(pt, rot, Vector2.ONE)
			map.draw_string_outline(font, Vector2(-w * 0.5, size * 0.35), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 5, Color(0, 0, 0, 0.6))
			map.draw_string(font, Vector2(-w * 0.5, size * 0.35), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
		t += dir * w / maxf(sp, 1.0)
	map.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_convoys() -> void:
	if not show_traffic or GameState.convoys == null:
		return
	for c in GameState.convoys.convoys:
		var p := _to_screen(GameState.convoys.map_pos(c))
		var col: Color = FactionData.color_of(String(c["gov"])) if String(c["gov"]) != "" else Color(0.85, 0.85, 0.8)
		var pts := PackedVector2Array([p + Vector2(0, -4.5), p + Vector2(4.5, 0), p + Vector2(0, 4.5), p + Vector2(-4.5, 0)])
		map.draw_colored_polygon(pts, col)
		pts.append(pts[0])
		map.draw_polyline(pts, Color(0, 0, 0, 0.7), 1.0)


## Axiom Parallax (package 25g): every system within its range that still hides undiscovered anomalies,
## with their number.
func _draw_anomaly_finder(font: Font) -> void:
	var f := GameState.active()
	if f == null or not f.hull().has("anomaly_finder"):
		return
	for sid in anomaly_targets(f):
		var p := _to_screen(Universe.systems[sid]["pos"])
		var n: int = anomaly_targets(f)[sid]
		map.draw_arc(p, 13.0, 0.0, TAU, 24, Color(0.4, 0.95, 1.0, 0.9), 2.0)
		map.draw_string(font, p + Vector2(10, -10), "%d?" % n, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.4, 0.95, 1.0))


## {system id: undiscovered anomalies} within the Parallax's range of the ship's system.
static func anomaly_targets(f: ShipFitting) -> Dictionary:
	var out := {}
	var rng := int(f.hull().get("anomaly_finder", 0))
	if rng <= 0:
		return out
	for sid in Missions._systems_within(f.system_id, rng):
		var n := 0
		for an in Universe.get_layout(sid)["anomalies"]:
			if not an.get("revealed", false) and not an.get("done", false):
				n += 1
		if n > 0:
			out[sid] = n
	return out


func _dashed(a: Vector2, b: Vector2, col: Color) -> void:
	var length := a.distance_to(b)
	var dir := (b - a) / maxf(length, 0.01)
	var d := fmod(_t * 20.0, 12.0)
	while d < length:
		map.draw_line(a + dir * d, a + dir * minf(d + 6.0, length), col, 2.0)
		d += 12.0


func _on_map_input(event: InputEvent) -> void:
	# package 40: the wheel zooms (towards the pointer), any button drags the map; a click without dragging selects
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		zoom_at(event.position, 1.2 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.2)
		return
	if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
		if event.pressed:
			_dragging = true
			_drag_moved = false
			_drag_from = event.position
		else:
			_dragging = false
			if event.button_index == MOUSE_BUTTON_LEFT and not _drag_moved:
				var sid := _system_at(event.position)
				if sid >= 0:
					selected_system = sid
					refresh()
		return
	if event is InputEventMouseMotion:
		if _dragging:
			var d: Vector2 = event.position - _drag_from
			if _drag_moved or d.length() > 5.0:
				_drag_moved = true
				view_center -= d / maxf(_scale(), 0.0001)
				_drag_from = event.position
				_clamp_view()
				map.queue_redraw()
			return
		var h := _system_at(event.position)
		if h != hover_system:
			hover_system = h
			map.queue_redraw()


# ---------------------------------------------------------------- Route planning

func _has_own_ships(sid: int) -> bool:
	for f in GameState.fleet:
		if f.system_id == sid:
			return true
	return false


func _plan() -> void:
	planned_path = []
	_from_system = -1
	var fits := GameState.selected_fits()
	if fits.is_empty() or selected_system < 0:
		return
	var f: ShipFitting = fits[0]
	_from_system = f.system_id
	planned_path = Universe.find_path(f.system_id, selected_system, int(f.stats()["drive_class"]))


func _update_info() -> void:
	var af := GameState.active()
	if wormhole_btn != null:
		wormhole_btn.visible = af != null and af.hull().has("wormhole") and selected_system >= 0
		if wormhole_btn.visible:
			var why: String = GameState.wormhole_error(af, selected_system)
			wormhole_btn.disabled = why != ""
			wormhole_btn.text = "Wormhole jump (%d exotic matter)" % GameState.wormhole_distance(af, selected_system) if why == "" else "Wormhole: %s" % why
	if selected_system < 0:
		info.text = ""
		return
	var s: Dictionary = Universe.systems[selected_system]
	var L := Universe.get_layout(selected_system)
	var t := "[b][font_size=18]%s[/font_size][/b]\n" % s["name"]
	t += "Security: [color=#%s]%.1f[/color]\n" % [_sec_color(s["security"]).to_html(false), float(s["security"])]
	t += "Control: %s\n" % territory_bbcode(selected_system)
	var cap_f := Universe.special_faction(selected_system)       # package 39: a closed capital
	if cap_f != "":
		t += "[color=#7fe0a0]Capital – your entry permit opens its gates[/color]\n" if GameState.has_permit(cap_f) else "[color=#ff7060]Capital – closed: entry permit needed (Friendly standing)[/color]\n"
	# package 42: economy and prosperity
	var eco := Economy.of(selected_system)
	var ecol := Economy.color_of(eco["main"]).to_html(false)
	t += "Economy: [color=#%s]%s[/color]" % [ecol, Economy.label(selected_system)]
	t += "  [font_size=11][color=#a0a8b8](%s)[/color][/font_size]\n" % ", ".join(PackedStringArray(Economy.reasons(selected_system, eco["main"])))
	var pdev := Economy.prosperity(selected_system) - Economy.base_prosperity(selected_system)
	var ptrend := ""
	if absf(pdev) >= 1.0:
		# 42d: how far trade, raids and contracts have moved it from where it rests
		ptrend = "  [color=#%s]%s%d from its usual %d[/color]" % ["7fe0a0" if pdev > 0.0 else "ff8060", "+" if pdev > 0.0 else "−", int(absf(pdev)), int(Economy.base_prosperity(selected_system))]
	t += "Prosperity: [color=#%s]%s[/color] [color=#a0a8b8](%d / 100)[/color]%s\n" % [Economy.level_color(selected_system).to_html(false), Economy.level_name(selected_system), int(Economy.prosperity(selected_system)), ptrend]
	var prof := Universe.system_profile(selected_system)
	var pg := int(prof["patrol_groups"])
	t += "Population: %.1f bn  •  Traffic: %s\n" % [float(prof["population"]), Universe.traffic_word(prof)]
	t += "Patrols: %s  •  Convoys here: %d\n" % [("%d group%s" % [pg, "" if pg == 1 else "s"]) if pg > 0 else "none", GameState.convoys.count_in(selected_system) if GameState.convoys != null else 0]
	t += "Star: %s\n" % L["star"]["type"]
	t += "Planets: %d   Asteroids: %d\n" % [L["planets"].size(), L["asteroids"].size()]
	# package 40c: what the Rim holds
	var notes: PackedStringArray = []
	if L.get("rich", false):
		notes.append("[color=#e0b060]rich deposits[/color]")
	for ws in L.get("sites", []):
		notes.append("[color=#b0a898]old battlefield[/color]" if ws["kind"] == "battlefield" else "[color=#d8d0c0]pre-Severance derelict[/color]")
	if Universe.is_veil(selected_system):
		notes.append("[color=#c080ff]edge of the Veil[/color]")
	for hz in L.get("hazards", []):                 # package 40d
		notes.append({"radiation": "[color=#d8f040]radiation[/color]", "ion_storm": "[color=#80b8ff]ion storm[/color]",
			"minefield": "[color=#ff7050]old minefield[/color]"}[String(hz["kind"])])
	for hv in L["havens"]:
		if hv.get("fortress", false):
			notes.append("[color=#ff5040]pirate fortress %s (bounty %s)[/color]" % ["– broken" if GameState.fortress_down(selected_system) else "", GameData.fmt_credits(int(hv.get("bounty", 0)))])
	if not notes.is_empty():
		t += " • ".join(notes) + "\n"
	if L["stations"].is_empty():
		t += "Stations: none\n"
	for st in L["stations"]:
		var hc := (PixelArt.STATION_ACCENT.get(String(st["type"]), Color.WHITE) as Color).to_html(false)
		var sf := String(st.get("faction", ""))
		var owner_txt := "[color=#%s]%s[/color]" % [FactionData.color_of(sf).to_html(false), FactionData.short_of(sf) if sf != "" else "free port"]
		t += "[color=#%s]■[/color] %s [color=#a0a8b8](tier %d)%s[/color] %s\n" % [hc, st["name"], int(st["tier"]), " – shipyard" if not st["shipyard"].is_empty() else "", owner_txt]
		if st.has("market"):
			# package 42b: what the market makes and wants (from the system's economy and the station)
			var mk_made: Array = []
			var mk_want: Array = []
			for cid in GameData.commodities:
				if GameData.is_tradeable(cid):
					var rl := Market.role(st, cid)
					if rl == "produce":
						mk_made.append(cid)
					elif rl == "consume":
						mk_want.append(cid)
			t += "[font_size=11][color=#90e0a0]  sells: %s[/color]\n[color=#e0c080]  buys: %s[/color][/font_size]\n" % [_goods(mk_made), _goods(mk_want)]
	for ph in L.get("havens", []):
		t += "[color=#ff4050]◆ %s – Pirate Haven (tier %d), hostile[/color] [color=#%s]%s[/color]\n" % [ph["name"], int(ph["tier"]), FactionData.color_of(String(ph.get("faction", ""))).to_html(false), FactionData.short_of(String(ph.get("faction", "")))]
	for c in (GameState.notorious.alive_in(selected_system) if GameState.notorious != null else []):
		var rtxt := ""
		if not (c.get("raid", {}) as Dictionary).is_empty():
			rtxt = (" – [color=#ff5050]raiding %s[/color]" if String(c["raid"]["state"]) == "active" else " – [color=#ff9050]raid on %s announced[/color]") % c["raid"]["name"]
		t += "[color=#ff5050]☠ Notorious: %s[/color] %s – %s, bounty %s%s [color=#a0a8b8](last seen %s)[/color]\n" % [NotoriousData.title(c), NotoriousData.stars_bbcode(c), NotoriousData.trait_name(c), GameData.fmt_credits(int(c["bounty"])), rtxt, SaveGame.fmt_time(float(c["seen"]))]
	t += "Routes: "
	var routes: Array = []
	for nb in s["links"]:
		routes.append(String(Universe.systems[nb]["name"]))
	t += ", ".join(PackedStringArray(routes)) + "\n\n"
	var fits := GameState.selected_fits()
	if fits.is_empty():
		t += "[color=#a0a0a0]No active ship.[/color]"
	else:
		for f in fits:
			if f.system_id == selected_system:
				t += "%s: already here\n" % f.ship_name
				continue
			var path := Universe.find_path(f.system_id, selected_system, int(f.stats()["drive_class"]))
			if path.is_empty():
				t += "[color=#ff7070]%s: no route (%s)[/color]\n" % [f.ship_name, "no jump drive" if int(f.stats()["drive_class"]) <= 0 else "unreachable"]
				continue
			var fuel := 0.0
			var prev: int = f.system_id
			for sid in path:
				fuel += GameState.jump_fuel(f, Universe.route_class(prev, sid))
				prev = sid
			var col := "#a0ffa0" if fuel <= f.fuel else "#ffb060"
			t += "[color=%s]%s: %d jumps, fuel %.0f / %.0f[/color]\n" % [col, f.ship_name, path.size(), fuel, f.fuel]
	info.text = t
	view_btn.disabled = not _has_own_ships(selected_system)


## Controlling faction(s) of a system in their colours (for RichTextLabels).
const INDEPENDENT_COLOR := Color(1.0, 0.86, 0.25)


static func territory_bbcode(sid: int) -> String:
	var f := Universe.controller(sid)
	var txt := Universe.territory_text(sid)
	if Universe.is_independent(sid):
		return "[color=#%s]Independent system[/color]" % INDEPENDENT_COLOR.to_html(false)
	if f != "":
		return "[color=#%s]%s[/color]" % [FactionData.color_of(f).to_html(false), txt]
	var cl := Universe.claimants(sid)
	if cl.is_empty():
		return "[color=#a0a8b8]%s[/color]" % txt
	var parts: PackedStringArray = []
	for c in cl:
		parts.append("[color=#%s]%s[/color]" % [FactionData.color_of(c).to_html(false), FactionData.short_of(c)])
	return "[color=#ffb060]Contested[/color] (%s)" % " / ".join(parts)


static func _goods(list: Array) -> String:
	var names: PackedStringArray = []
	for i in mini(list.size(), 4):
		names.append(GameData.item_name(list[i]))
	return ", ".join(names) + (" …" if list.size() > 4 else "")


var wormhole_btn: Button


## Axiom Threshold (package 25g): jump straight to the selected system through a wormhole.
func _wormhole() -> void:
	if selected_system < 0:
		return
	if Commands.execute({"type": "wormhole_jump", "to": selected_system}) == "":
		close()


func _set_course() -> void:
	if selected_system < 0:
		return
	if Commands.execute({"type": "course", "to": selected_system}) == "":
		routes_changed.emit()
		close()


func _rebuild_fleet() -> void:
	UI.clear(fleet_box)
	for f in GameState.fleet:
		var status := ""
		if f.docked_at != "":
			status = " (docked)"
		elif not f.route.is_empty():
			status = " ⇒ %s" % Universe.systems[int(f.route.back())]["name"]
		var mark := "▶ " if f.uid == GameState.active_uid else "   "
		var b := UI.button("%s%s – %s%s" % [mark, f.ship_name, f.location_text(), status], func(): pass)
		b.tooltip_text = "Active ship" if f.uid == GameState.active_uid else "Parked in a hangar – swap ships there"
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = true
		fleet_box.add_child(b)
