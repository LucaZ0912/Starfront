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
	_signs = Node2D.new()
	_signs.z_index = 10
	_signs.draw.connect(_draw_signs)
	_world.add_child(_signs)
	_camera()


func _process(delta: float) -> void:
	_t += delta
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


## Shop signs over the doors (crisp text in screen pixels), the bar's tall neon sign, a glow where the pilot stands.
func _draw_signs() -> void:
	var font := ThemeDB.fallback_font
	var s := GroundMap.SCALE
	for z in map.zones:
		var sp: Vector2 = z.get("sign", Vector2(-100, -100))
		if sp.x < 0.0:
			continue
		var c: Color = z.get("col", Color.WHITE)
		var glow: float = 0.8 + 0.2 * sin(_t * 2.0 + sp.x * 0.01)
		if z.get("vertical", false):
			var letters: String = String(z["title"])
			var y := sp.y * s
			_signs.draw_rect(Rect2(Vector2(sp.x * s - 18, y - 8), Vector2(36, letters.length() * 34 + 10)), Color(0.05, 0.03, 0.06, 0.9))
			_signs.draw_rect(Rect2(Vector2(sp.x * s - 18, y - 8), Vector2(36, letters.length() * 34 + 10)), Color(c, 0.8 * glow), false, 2.0)
			for i in letters.length():
				var ch := letters.substr(i, 1)
				var cw := font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
				_signs.draw_string(font, Vector2(sp.x * s - cw * 0.5, y + 26 + i * 34), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(c, glow))
			continue
		var txt: String = String(z["title"]).to_upper()
		if String(z.get("closed", "")) != "":
			txt += " · CLOSED"
			c = Color(0.55, 0.55, 0.6)
		var size := 13
		var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var p: Vector2 = sp * s - Vector2(tw * 0.5, 0)
		_signs.draw_rect(Rect2(p + Vector2(-7, -size - 1), Vector2(tw + 14, size + 8)), Color(0.04, 0.03, 0.06, 0.92))
		_signs.draw_rect(Rect2(p + Vector2(-7, -size - 1), Vector2(tw + 14, size + 8)), Color(c, 0.7 * glow), false, 2.0)
		_signs.draw_string(font, p, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(c, glow))
	if not zone.is_empty() and zone["kind"] in ["service", "exit"]:
		var r: Rect2 = zone["rect"]
		_signs.draw_rect(Rect2(r.position * s, r.size * s), Color(1.0, 0.85, 0.35, 0.07 + 0.04 * sin(_t * 4.0)))
