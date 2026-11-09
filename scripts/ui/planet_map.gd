class_name PlanetMap
extends CanvasLayer
## Package 50: after the descent – the planet below, big, with its cities and places marked on it; the list beside
## it. Pick a place and land, or go back to orbit.

signal land(site: Dictionary)
signal back

const BgShader = preload("res://shaders/background.gdshader")

var system_id := -1
var body: Dictionary = {}
var sites: Array = []
var selected := -1
var _root: Control
var _planet: Node2D
var _marks: Node2D
var _info: VBoxContainer
var _list: VBoxContainer
var _land_btn: Button
var _center := Vector2.ZERO
var _r := 200.0
var _t := 0.0


func open(p_system: int, p_body: Dictionary) -> void:
	layer = 11
	system_id = p_system
	body = p_body
	sites = Universe.landing_sites(system_id, body)
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var mat := ShaderMaterial.new()
	mat.shader = BgShader
	mat.set_shader_parameter("seed", float(system_id) * 1.37 + 0.5)
	var hue := float(system_id) * 0.137
	mat.set_shader_parameter("neb_a", Color.from_hsv(fposmod(hue, 1.0), 0.7, 0.85))
	mat.set_shader_parameter("neb_b", Color.from_hsv(fposmod(hue + 0.45, 1.0), 0.6, 0.75))
	mat.set_shader_parameter("neb_strength", 0.7)
	bg.material = mat
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(bg)
	var vs := _root.get_viewport_rect().size
	_r = minf(vs.x * 0.3, vs.y * 0.4)
	_center = Vector2(vs.x * 0.34, vs.y * 0.53)
	# the planet, lit from the upper left
	_planet = Node2D.new()
	_root.add_child(_planet)
	var spr := Celestial.make_planet_sprite(body, _r, Vector2(-0.7, -0.5))
	var pm := spr.material as ShaderMaterial
	if pm != null:
		pm.set_shader_parameter("spin", 0.0)
	spr.position = _center
	_planet.add_child(spr)
	_marks = Node2D.new()
	_marks.draw.connect(_draw_marks)
	_root.add_child(_marks)
	for i in sites.size():
		var b := Button.new()
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(30, 30)
		b.position = _site_pos(sites[i]) - Vector2(15, 15)
		b.pressed.connect(func(): select(i))
		_root.add_child(b)
	# the title
	var tl := UI.label("DESCENT – %s" % String(body["name"]).to_upper(), 26, UI.NEON_CYAN)
	tl.position = Vector2(30, 22)
	_root.add_child(tl)
	var bt := Universe.body_type(String(body["type"]))
	var sub := UI.label("%s  ·  %s  ·  %s" % [String(bt.get("name", "")), String(bt.get("temp", "")),
		"atmosphere – mind the heat on the way down" if Universe.has_atmosphere(body) else "no atmosphere"], 14, UI.TEXT_DIM)
	sub.position = Vector2(32, 58)
	_root.add_child(sub)
	# the list of places
	var p := UI.neon_panel(UI.NEON_CYAN, Color(0.02, 0.04, 0.08, 0.92), 2)
	p.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	p.offset_left = -520
	p.offset_right = -30
	p.offset_top = 100
	p.custom_minimum_size = Vector2(490, 0)
	_root.add_child(p)
	var v := UI.vbox(8)
	p.add_child(v)
	v.add_child(UI.label("PLACES TO LAND", 16, UI.GOLD))
	_list = UI.vbox(4)
	v.add_child(_list)
	for i2 in sites.size():
		var s: Dictionary = sites[i2]
		var k: Dictionary = Universe.SITE_KINDS[s["kind"]]
		var b2 := UI.button("%s  %s   ·  %s" % [k["icon"], s["name"], k["name"]], func(): select(i2))
		b2.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_list.add_child(b2)
	v.add_child(UI.label("", 6))
	_info = UI.vbox(4)
	v.add_child(_info)
	var row := UI.hbox(10)
	v.add_child(row)
	_land_btn = UI.button("Land here", func():
		if selected >= 0:
			land.emit(sites[selected]))
	_land_btn.disabled = true
	row.add_child(_land_btn)
	row.add_child(UI.button("Back to orbit", func(): back.emit()))
	if not sites.is_empty():
		select(0)


## Where on the disc a place lies (its longitude and latitude on the visible face).
func _site_pos(s: Dictionary) -> Vector2:
	var lon := float(s["lon"])
	var lat := float(s["lat"])
	return _center + Vector2(sin(lon) * cos(lat), -sin(lat)) * _r * 0.86


func select(i: int) -> void:
	selected = i
	UI.clear(_info)
	var s: Dictionary = sites[i]
	var k: Dictionary = Universe.SITE_KINDS[s["kind"]]
	_info.add_child(UI.label("%s  %s" % [k["icon"], s["name"]], 18, k["col"]))
	_info.add_child(UI.wrap_label(String(k["text"]), 13, UI.TEXT_DIM, 460))
	for j in _list.get_child_count():
		(_list.get_child(j) as Button).modulate = Color(1, 1, 1) if j == i else Color(0.7, 0.72, 0.8)
	_land_btn.disabled = false
	_land_btn.text = "Land at %s" % String(s["name"])


func _process(delta: float) -> void:
	_t += delta
	if _marks != null:
		_marks.queue_redraw()


func _draw_marks() -> void:
	var font := ThemeDB.fallback_font
	for i in sites.size():
		var s: Dictionary = sites[i]
		var k: Dictionary = Universe.SITE_KINDS[s["kind"]]
		var p := _site_pos(s)
		var c: Color = k["col"]
		var sel := i == selected
		if sel:
			for r in 2:
				var ph := fposmod(_t * 0.8 + r * 0.5, 1.0)
				_marks.draw_arc(p, 12.0 + ph * 26.0, 0.0, TAU, 32, Color(c, 0.7 * (1.0 - ph)), 2.0)
		_marks.draw_circle(p, 9.0 if sel else 7.0, Color(0.02, 0.02, 0.04, 0.85))
		_marks.draw_arc(p, 9.0 if sel else 7.0, 0.0, TAU, 24, c, 2.0)
		_marks.draw_circle(p, 3.0, c)
		var txt := String(s["name"])
		var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		var lp := p + Vector2(14, 5)
		_marks.draw_rect(Rect2(lp + Vector2(-4, -15), Vector2(tw + 8, 20)), Color(0.02, 0.02, 0.05, 0.75))
		_marks.draw_string(font, lp, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, c.lerp(Color.WHITE, 0.3) if sel else c)


func close() -> void:
	queue_free()
