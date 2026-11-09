class_name GroundView
extends CanvasLayer
## Package 49: on foot – a walkable place drawn over the space view (which keeps running below). The pilot walks with
## WASD (Shift runs), E uses what is in front of him: a shop door opens its window, the crew in the bar can be spoken
## to, the lift leads back to the ship. 0.7.49.2: the slanted view – furniture and people sorted by depth, space
## (the system's own star and the station's planet) beyond the window front.

signal used(zone: Dictionary)

const LAYER := 12
const BgShader = preload("res://shaders/background.gdshader")

var map: GroundMap
var station: Dictionary = {}
var pilot: Walker
var people: Array = []
var input_enabled := true
var zone: Dictionary = {}
var _space: ColorRect
var _sky: Node2D
var _world: Node2D
var _hull: TextureRect
var _window: Control                  # the window front's opening – space is only drawn inside it
var _neb: ColorRect
var _off0 = null
var _lights: Node2D
var _flicker: Array = []              # [sprite, base alpha, phase]
static var _glow_tex: Texture2D
var _sorted: Node2D
var _signs: Node2D
var _prompt: Label
var _title: Label
var _t := 0.0


func _ready() -> void:
	layer = LAYER
	_space = ColorRect.new()                        # everything that is neither deck nor window: black
	_space.color = Color(0, 0, 0)
	_space.set_anchors_preset(Control.PRESET_FULL_RECT)
	_space.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_space)
	_world = Node2D.new()
	add_child(_world)
	var ui := Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	_title = UI.label("", 18, UI.NEON_CYAN)
	_title.position = Vector2(24, 18)
	ui.add_child(_title)
	var hint := UI.label("", 12, UI.TEXT_DIM)
	hint.position = Vector2(24, 46)
	hint.text = "%s %s %s %s walk  •  %s run  •  %s use / talk  •  the lift takes you back to your ship" % [
		Keybinds.key_text("walk_up"), Keybinds.key_text("walk_left"), Keybinds.key_text("walk_down"), Keybinds.key_text("walk_right"),
		Keybinds.key_text("boost"), Keybinds.key_text("interact")]
	ui.add_child(hint)
	_prompt = UI.label("", 18, UI.GOLD)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.offset_top = -90
	_prompt.offset_bottom = -60
	_prompt.offset_left = -500
	_prompt.offset_right = 500
	ui.add_child(_prompt)


## A station's deck: available = service id -> "" or the reason it is closed; crew = the bar's offers.
func setup_station(p_station: Dictionary, available: Dictionary, crew: Array = [], sys_id: int = -1) -> void:
	station = p_station
	map = DeckGen.build(station, available, crew)
	_build()
	_space_view(sys_id)
	_title.text = "%s – Promenade" % map.title


## Beyond the glass: the system's sky – its nebula, its star, the planet the station circles.
func _space_view(sys_id: int) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = BgShader
	var seed_v := float(sys_id) * 1.37 + 0.5
	var hue := float(sys_id) * 0.137
	mat.set_shader_parameter("seed", seed_v)
	mat.set_shader_parameter("neb_a", Color.from_hsv(fposmod(hue, 1.0), 0.7, 0.85))
	mat.set_shader_parameter("neb_b", Color.from_hsv(fposmod(hue + 0.45, 1.0), 0.6, 0.75))
	mat.set_shader_parameter("neb_strength", 1.1)
	_neb.material = mat
	if sys_id < 0:
		return
	var L := Universe.get_layout(sys_id)
	var star: Dictionary = L["star"]
	# placed beyond the window front (in the window's px) – they drift a little slower than the deck: far away
	var ww := _window.size.x
	var wh := _window.size.y
	var star_at := Vector2(ww * 0.12, wh * 0.38)
	var planet_at := Vector2(ww * 0.58, wh * 0.62)
	var st_spr := Celestial.make_star_sprite(star, 46.0)
	st_spr.position = star_at
	_sky.add_child(st_spr)
	var pi := int(station.get("planet", -1))
	if pi >= 0 and pi < L["planets"].size():
		var p: Dictionary = L["planets"][pi]
		var lit := (star_at - planet_at).normalized()
		var ps := Celestial.make_planet_sprite(p, wh * 0.95, lit)
		ps.position = planet_at
		_sky.add_child(ps)


func _build() -> void:
	# the window: space drawn only behind the glass
	_window = Control.new()
	_window.clip_contents = true
	_window.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var wr := map.window_rect
	_window.position = wr.position * GroundMap.TILE * GroundMap.SCALE
	_window.size = wr.size * GroundMap.TILE * GroundMap.SCALE
	_world.add_child(_window)
	_neb = ColorRect.new()
	_neb.color = Color(0, 0, 0)
	_neb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_neb.set_anchors_preset(Control.PRESET_FULL_RECT)
	_neb.size = _window.size
	_window.add_child(_neb)
	_sky = Node2D.new()
	_window.add_child(_sky)
	# the station goes on round the deck – its structure seen from above, everywhere below the window front's top
	if map.hull_top >= 0:
		_hull = TextureRect.new()
		_hull.texture = map.hull_texture()
		_hull.stretch_mode = TextureRect.STRETCH_TILE
		_hull.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_hull.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var far := 4000.0 / GroundMap.SCALE
		_hull.position = Vector2(-far, map.hull_top * GroundMap.TILE) * GroundMap.SCALE
		_hull.size = Vector2(map.w * GroundMap.TILE + far * 2.0, map.h * GroundMap.TILE + far)
		_hull.scale = Vector2.ONE * GroundMap.SCALE
		_world.add_child(_hull)
		var rim := ColorRect.new()                    # the edge where the station's structure meets space
		rim.color = Color(map.pal["wall_top"]).lightened(0.25)
		rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rim.position = _hull.position
		rim.size = Vector2(_hull.size.x * GroundMap.SCALE, GroundMap.SCALE)
		_world.add_child(rim)
	var spr := Sprite2D.new()
	spr.texture = map.texture()
	spr.centered = false
	spr.scale = Vector2.ONE * GroundMap.SCALE
	_world.add_child(spr)
	_sorted = Node2D.new()
	_sorted.y_sort_enabled = true
	_world.add_child(_sorted)
	for o in map.objects:
		var art: Dictionary = ObjArt.make(o, map.pal)
		var img: Image = art["image"]
		var os := Sprite2D.new()
		os.texture = ImageTexture.create_from_image(img)
		os.centered = false
		os.scale = Vector2.ONE * GroundMap.SCALE
		os.offset = Vector2(0, -img.get_height())
		os.position = Vector2(float(o["x"]) * GroundMap.TILE, float(int(o["y"]) + int(o.get("h", 1))) * GroundMap.TILE) * GroundMap.SCALE
		_sorted.add_child(os)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(station.get("id", ""))) + 49
	for p in map.people:
		var w := Walker.new()
		var lk: Dictionary = p.get("look", {})
		if lk.is_empty():
			lk = ChibiArt.PilotArt.random_look(rng)
		w.setup(map, lk, p["pos"], true)
		w.dir = int(p.get("dir", 0))
		w.sitting = bool(p.get("sit", false))
		if String(p.get("role", "")) in ["bartender", "keeper"]:
			w.stays = true
		if String(p.get("role", "")) == "crew":
			w.marker = "!"
		_sorted.add_child(w)
		people.append(w)
	var n := 5 + int(station.get("tier", 1)) * 2
	for i in n:
		if map.wander.is_empty():
			break
		var w2 := Walker.new()
		w2.setup(map, ChibiArt.PilotArt.random_look(rng), map.wander[i % map.wander.size()], true)
		_sorted.add_child(w2)
		people.append(w2)
	pilot = Walker.new()
	pilot.setup(map, GameState.pilot.get("look", ChibiArt.PilotArt.default_look()), map.spawn, false)
	_sorted.add_child(pilot)
	# light: lamps, neon, the window – added on top, the deck a little darker round them
	_lights = Node2D.new()
	_lights.z_index = 5
	var add_mat := CanvasItemMaterial.new()
	add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	for l in map.lights:
		_add_light(l, add_mat)
	for z in map.zones:
		var sp: Vector2 = z.get("sign", Vector2(-100, -100))
		if sp.x >= 0.0 and not z.get("vertical", false) and String(z.get("closed", "")) == "":
			_add_light({"pos": sp + Vector2(0, 6), "r": 30.0, "col": z.get("col", Color.WHITE), "a": 0.3}, add_mat)
	_world.add_child(_lights)
	_signs = Node2D.new()
	_signs.z_index = 10
	_signs.draw.connect(_draw_signs)
	_world.add_child(_signs)
	_camera()


static func glow_texture() -> Texture2D:
	if _glow_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.35, Color(1, 1, 1, 0.55))
		g.add_point(0.7, Color(1, 1, 1, 0.15))
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.5)
		gt.fill_to = Vector2(1.0, 0.5)
		gt.width = 128
		gt.height = 128
		_glow_tex = gt
	return _glow_tex


func _add_light(l: Dictionary, mat: Material) -> void:
	var sp := Sprite2D.new()
	sp.texture = glow_texture()
	sp.material = mat
	var r: float = l.get("r", 40.0)
	sp.scale = Vector2(1.0, 0.7) * r * 2.0 * GroundMap.SCALE / 128.0          # pools on the floor: a little flattened
	sp.position = Vector2(l["pos"]) * GroundMap.SCALE
	var a: float = l.get("a", 0.3)
	sp.modulate = Color(Color(l.get("col", Color.WHITE)), a)
	_lights.add_child(sp)
	if l.get("flicker", false):
		_flicker.append([sp, a, randf() * 50.0])


func _process(delta: float) -> void:
	_t += delta
	for f in _flicker:
		var ph: float = f[2]
		var k := 1.0
		if fposmod(_t * 0.7 + ph, 9.0) < 0.18:
			k = 0.35 if fposmod(_t * 31.0, 1.0) < 0.5 else 0.8
		(f[0] as Sprite2D).modulate.a = float(f[1]) * k
	if pilot == null:
		return
	if input_enabled:
		var dir := Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
		pilot.step(dir, delta, 1.6 if Input.is_action_pressed("boost") else 1.0)
	else:
		pilot.moving = false
	zone = map.zone_at(pilot.pos)
	if zone.get("kind", "") == "label":
		zone = {}
	_prompt.text = _prompt_text(zone)
	_camera()
	_signs.queue_redraw()


func _prompt_text(z: Dictionary) -> String:
	if z.is_empty():
		return ""
	var key := Keybinds.key_text("interact")
	match String(z["kind"]):
		"exit":
			return "[%s] %s" % [key, z["title"]]
		"crew":
			return "[%s] Talk to %s – looking for a post" % [key, z["title"]]
	if String(z.get("closed", "")) != "":
		return "%s – closed: %s" % [z["title"], z["closed"]]
	return "[%s] %s%s" % [key, z["title"], ("  –  " + String(z["corp"])) if String(z.get("corp", "")) != "" else ""]


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled or pilot == null:
		return
	if event.is_action_pressed("interact", false, false):
		get_viewport().set_input_as_handled()
		use()


## Uses what the pilot stands at (also for the smoke test).
func use() -> bool:
	if zone.is_empty() or String(zone.get("closed", "")) != "":
		return false
	Audio.play("ui_open", "on foot: use")
	used.emit(zone)
	return true


## Puts the pilot at a zone (debug, smoke test).
func walk_to_zone(id: String) -> bool:
	for z in map.zones:
		if String(z.get("id", "")) == id and z["kind"] != "label":
			var r: Rect2 = z["rect"]
			for k in 60:
				var p := r.position + Vector2(randf(), randf()) * r.size
				if map.free_at(p, Walker.RADIUS):
					pilot.pos = p
					pilot.position = p * GroundMap.SCALE
					zone = map.zone_at(p)
					if zone.get("kind", "") == "label":
						zone = {}
					return true
	return false


func _camera() -> void:
	var vs := get_viewport().get_visible_rect().size
	var mp := map.size_px() * GroundMap.SCALE
	var c := pilot.position + Vector2(0, -24)
	var off := vs * 0.5 - c
	if mp.x > vs.x:
		off.x = clampf(off.x, vs.x - mp.x, 0.0)
	else:
		off.x = (vs.x - mp.x) * 0.5
	if mp.y > vs.y:
		off.y = clampf(off.y, vs.y - mp.y, 0.0)
	else:
		off.y = (vs.y - mp.y) * 0.5
	_world.position = off.round()
	# space beyond the glass moves only a little – it is far away
	if _off0 == null:
		_off0 = off
	_sky.position = (-(off - (_off0 as Vector2)) * 0.9).round()
	var m := _neb.material as ShaderMaterial
	if m != null:
		m.set_shader_parameter("offset", -off * 0.3)


const _GLOW_OFFS := [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(0, 2), Vector2(-1, -1), Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1)]


## Neon: a soft halo in the tube's colour, a bright core near white.
func _neon_text(font: Font, p: Vector2, txt: String, size: int, c: Color, k: float) -> void:
	for o in _GLOW_OFFS:
		_signs.draw_string(font, p + o * 1.5, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(c, 0.16 * k))
	for o2 in _GLOW_OFFS:
		_signs.draw_string(font, p + o2 * 0.6, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(c, 0.3 * k))
	_signs.draw_string(font, p, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(c.lerp(Color.WHITE, 0.55), 0.6 + 0.4 * k))


func _neon_rect(r: Rect2, c: Color, k: float) -> void:
	_signs.draw_rect(r.grow(2), Color(c, 0.12 * k), false, 6.0)
	_signs.draw_rect(r, Color(c, 0.45 * k), false, 3.0)
	_signs.draw_rect(r, Color(c.lerp(Color.WHITE, 0.5), 0.5 + 0.5 * k), false, 1.0)


## How lit a neon is now: mostly steady, now and then a stutter.
func _flick(seed_v: float) -> float:
	if fposmod(_t * 0.6 + seed_v, 11.0) < 0.22:
		return 0.25 if fposmod(_t * 27.0, 1.0) < 0.5 else 0.9
	return 0.92 + 0.08 * sin(_t * 3.0 + seed_v)


## Neon shop signs mounted on the wall over the doors, the bar's tall neon sign, holographic adverts over the
## corridor wall, a glow where the pilot stands.
func _draw_signs() -> void:
	var font := ThemeDB.fallback_font
	var s := GroundMap.SCALE
	for h in map.holos:
		_draw_holo(font, h)
	for z in map.zones:
		var sp: Vector2 = z.get("sign", Vector2(-100, -100))
		if sp.x < 0.0:
			continue
		var c: Color = z.get("col", Color.WHITE)
		var k := _flick(sp.x * 0.13)
		if z.get("vertical", false):
			var letters: String = String(z["title"])
			var y := sp.y * s
			var box := Rect2(Vector2(sp.x * s - 20, y - 8), Vector2(40, letters.length() * 36 + 14))
			_signs.draw_rect(box, Color(0.03, 0.02, 0.05, 0.92))
			_neon_rect(box.grow(-4), Color(0.3, 0.95, 1.0), _flick(3.3))
			for i in letters.length():
				var ch := letters.substr(i, 1)
				var cw := font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
				var lk := k if i != 1 else _flick(7.7)
				_neon_text(font, Vector2(sp.x * s - cw * 0.5, y + 30 + i * 36), ch, 30, c, lk)
			continue
		var txt: String = String(z["title"]).to_upper()
		var closed := String(z.get("closed", "")) != ""
		if closed:
			txt += " · CLOSED"
			c = Color(0.45, 0.45, 0.5)
			k = 0.15
		var size := 15
		var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var p: Vector2 = sp * s - Vector2(tw * 0.5, -2)
		var plate := Rect2(p + Vector2(-10, -size - 3), Vector2(tw + 20, size + 11))
		# two brackets into the wall, a dark backing plate, the neon tube text and frame
		_signs.draw_rect(Rect2(plate.position + Vector2(8, -6), Vector2(3, 6)), Color(0.1, 0.1, 0.12))
		_signs.draw_rect(Rect2(plate.end - Vector2(11, plate.size.y + 6), Vector2(3, 6)), Color(0.1, 0.1, 0.12))
		_signs.draw_rect(plate, Color(0.02, 0.02, 0.04, 0.9))
		_neon_rect(plate.grow(-3), c, k * 0.8)
		_neon_text(font, p, txt, size, c, k)
	if not zone.is_empty() and zone["kind"] in ["service", "exit"] and zone["rect"].size.x > 0.0:
		var r: Rect2 = zone["rect"]
		_signs.draw_rect(Rect2(r.position * s, r.size * s), Color(1.0, 0.85, 0.35, 0.07 + 0.04 * sin(_t * 4.0)))


## A holographic advert hovering over the corridor wall: see-through, scan lines, now and then a jolt.
func _draw_holo(font: Font, h: Dictionary) -> void:
	var s := GroundMap.SCALE
	var c: Color = h["col"]
	var base: Vector2 = Vector2(h["pos"]) * s
	var k := _flick(base.x * 0.07)
	var jolt := 0.0
	if fposmod(_t * 0.9 + base.x * 0.01, 7.0) < 0.12:
		jolt = 5.0 * sin(_t * 90.0)
	var t1: String = h["text"]
	var t2: String = h["sub"]
	var w1 := font.get_string_size(t1, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	var w2 := font.get_string_size(t2, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	var bw := maxf(w1, w2) + 22.0
	var r := Rect2(base + Vector2(-bw * 0.5 + jolt, -62), Vector2(bw, 46))
	# the projector on the wall and its beam
	_signs.draw_rect(Rect2(base + Vector2(-8, -6), Vector2(16, 6)), Color(0.08, 0.08, 0.1))
	_signs.draw_rect(Rect2(base + Vector2(-2, -5), Vector2(4, 2)), Color(c, 0.9))
	_signs.draw_colored_polygon(PackedVector2Array([base + Vector2(-3, -5), base + Vector2(3, -5), r.end - Vector2(0, 0), Vector2(r.position.x, r.end.y)]), Color(c, 0.07 * k))
	_signs.draw_rect(r, Color(c, 0.22 * k))
	var yy := r.position.y + fposmod(_t * 20.0, 3.0)
	while yy < r.end.y:
		_signs.draw_line(Vector2(r.position.x, yy), Vector2(r.end.x, yy), Color(c, 0.1 * k), 1.0)
		yy += 3.0
	_signs.draw_rect(r, Color(c, 0.85 * k), false, 2.0)
	_signs.draw_string(font, Vector2(r.position.x + (bw - w1) * 0.5, r.position.y + 20), t1, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(c.lerp(Color.WHITE, 0.6), k))
	_signs.draw_string(font, Vector2(r.position.x + (bw - w2) * 0.5, r.position.y + 37), t2, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(c.lerp(Color.WHITE, 0.3), 0.9 * k))
