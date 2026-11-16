class_name WeatherFx
extends Node2D
## Package 54e (Luz): the weather over an outdoor map, in screen space above the world (mockup_54e_*): the light dimmed
## and tinted, a haze (WeatherHaze shader – fog banks, dust, blowing snow, the giant's gas in torn veils racing across a
## cloud city's deck), and what falls or flies drawn on top – rain with its splashes, snow, sand, ash and embers, acid
## rain; lightning with its flash and a roll of thunder after it. People put up their holo umbrellas when it rains
## (Walker.umbrella_on). Only to look at – nothing here changes what you see of foes or your suit.

const HazeShader = preload("res://shaders/weather_haze.gdshader")
const S := GroundMap.SCALE

var view = null                       # the GroundView (its camera, its people)
var w: Dictionary = {}                # Weather.at(…): kind, k
var look: Dictionary = {}             # over a gas giant: its colours (CloudGen.giant_look)
var place: Dictionary = {}            # where (for updating the weather now and then)
var body: Dictionary = {}
var cloud := false
var _tint: ColorRect
var _haze: ColorRect
var _parts: Node2D
var _flash_r: ColorRect
var _t := 0.0
var _flash := 0.0
var _bolt := PackedVector2Array()
var _bolt_t := 0.0
var _glow := Vector2.INF              # lightning inside the clouds (gas storm)
var _next_strike := 4.0
var _thunder: Array = []              # seconds until each roll of thunder
var _check := 0.0
var _sz := Vector2(1920, 1080)
var strikes := 0                      # how many bolts so far (the smoke test)


func _ready() -> void:
	_tint = ColorRect.new()
	var mm := CanvasItemMaterial.new()
	mm.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
	_tint.material = mm
	_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tint)
	_haze = ColorRect.new()
	var sm := ShaderMaterial.new()
	sm.shader = HazeShader
	_haze.material = sm
	_haze.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_haze)
	_parts = Node2D.new()
	_parts.draw.connect(_draw_parts)
	add_child(_parts)
	_flash_r = ColorRect.new()
	var am := CanvasItemMaterial.new()
	am.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_flash_r.material = am
	_flash_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash_r)
	_apply()


func _exit_tree() -> void:
	stop_sound()


func stop_sound() -> void:
	Audio.loop("weather_rain", "amb_rain", false)
	Audio.loop("weather_wind", "amb_wind", false)


func kind() -> String:
	return String(w.get("kind", "clear"))


func k() -> float:
	return float(w.get("k", 0.0))


## The haze and the tint for the weather now.
func _apply() -> void:
	var kd := kind()
	var kk := k()
	var tint := Color.WHITE
	var ha := 0.0
	var ca := Color(1, 1, 1)
	var cb := Color(0.85, 0.87, 0.9)
	var cc := Color(1, 1, 1)
	var drift := Vector2(0.04, 0.0)
	var stretch := Vector2(1, 1)
	var veils := 0.0
	match kd:
		"cloudy":
			tint = Color(0.84, 0.86, 0.92)
			ha = 0.12
			cb = Color(0.75, 0.78, 0.84)
		"rain":
			tint = Color(0.72, 0.76, 0.87)
			ha = 0.1
			ca = Color(0.7, 0.75, 0.85)
			cb = Color(0.6, 0.66, 0.78)
		"storm":
			tint = Color(0.52, 0.55, 0.66)
			ha = 0.18
			ca = Color(0.45, 0.5, 0.62)
			cb = Color(0.35, 0.38, 0.5)
			drift = Vector2(0.12, 0.02)
		"fog":
			tint = Color(0.9, 0.92, 0.95)
			ha = 0.62
			ca = Color(0.9, 0.92, 0.95)
			cb = Color(0.78, 0.82, 0.88)
			drift = Vector2(0.03, 0.005)
		"snow":
			tint = Color(0.92, 0.95, 1.0)
			ha = 0.14
		"blizzard":
			tint = Color(0.84, 0.88, 0.97)
			ha = 0.62
			drift = Vector2(0.55, 0.04)
			stretch = Vector2(0.45, 1.0)
		"dust":
			tint = Color(0.98, 0.88, 0.74)
			ha = 0.45
			ca = Color(0.96, 0.84, 0.64)
			cb = Color(0.7, 0.5, 0.32)
			drift = Vector2(0.12, 0.0)
		"sandstorm":
			tint = Color(0.9, 0.76, 0.64)
			ha = 0.9
			ca = Color(0.97, 0.84, 0.62)
			cb = Color(0.5, 0.28, 0.14)
			drift = Vector2(0.75, 0.03)
			stretch = Vector2(0.4, 1.0)
		"ash":
			tint = Color(0.8, 0.72, 0.68)
			ha = 0.25
			ca = Color(0.45, 0.4, 0.38)
			cb = Color(0.3, 0.26, 0.25)
			drift = Vector2(0.05, 0.03)
		"acid":
			tint = Color(0.82, 0.9, 0.7)
			ha = 0.2
			ca = Color(0.7, 0.85, 0.4)
			cb = Color(0.55, 0.7, 0.3)
		"gaswind", "gasstorm":
			var bands: Array = look.get("bands", [Color(0.93, 0.84, 0.66), Color(0.86, 0.66, 0.44), Color(0.76, 0.5, 0.32)])
			ca = bands[0]
			cb = bands[mini(2, bands.size() - 1)]
			cc = (look.get("deep", Color(0.4, 0.3, 0.2)) as Color).lightened(0.15)
			veils = 1.0
			if kd == "gaswind":
				tint = Color(0.92, 0.9, 0.88).lerp(ca, 0.12)
				ha = 0.6
				drift = Vector2(1.3, 0.0)
				stretch = Vector2(0.2, 1.0)
			else:
				tint = Color(0.55, 0.5, 0.46).lerp((look.get("deep", Color(0.4, 0.3, 0.2)) as Color), 0.25)
				ha = 0.95
				drift = Vector2(3.6, 0.0)
				stretch = Vector2(0.12, 1.0)
	_tint.color = Color.WHITE.lerp(tint, kk)
	var sm := _haze.material as ShaderMaterial
	sm.set_shader_parameter("col_a", ca)
	sm.set_shader_parameter("col_b", cb)
	sm.set_shader_parameter("col_c", cc)
	sm.set_shader_parameter("amount", ha * kk)
	sm.set_shader_parameter("drift", drift)
	sm.set_shader_parameter("stretch", stretch)
	sm.set_shader_parameter("veils", veils)
	_haze.visible = ha * kk > 0.005
	_tint.visible = kk > 0.0


func _process(dt: float) -> void:
	_t += dt
	_sz = get_viewport_rect().size
	for c in [_tint, _haze, _flash_r]:
		(c as ColorRect).size = _sz
	var sh := Vector2.ZERO
	if view != null and is_instance_valid(view) and view._world != null:
		sh = view._world.position
	var sm := _haze.material as ShaderMaterial
	sm.set_shader_parameter("res", _sz)
	sm.set_shader_parameter("shift", sh)
	sm.set_shader_parameter("t", _t)
	_check -= dt
	if _check <= 0.0:
		_check = 1.0
		if not body.is_empty() or cloud:
			var nw := Weather.at(body, place, cloud)
			if String(nw["kind"]) != kind() or absf(float(nw["k"]) - k()) > 0.01:
				w = nw
				_apply()
		_people()
		_sound()
	# lightning in a thunderstorm and a gas storm
	if kind() in ["storm", "gasstorm"] and k() > 0.5:
		_next_strike -= dt
		if _next_strike <= 0.0:
			strike()
	_flash = maxf(0.0, _flash - dt * 2.6)
	_bolt_t = maxf(0.0, _bolt_t - dt)
	var fl := _flash * (0.7 + 0.3 * sin(_t * 60.0)) if _flash > 0.4 else _flash
	var fc: Color = look.get("flash", Color(0.85, 0.9, 1.0)) if cloud else Color(0.85, 0.9, 1.0)
	_flash_r.color = Color(fc, 0.32 * fl)
	_flash_r.visible = fl > 0.0
	for i in range(_thunder.size() - 1, -1, -1):
		_thunder[i] -= dt
		if _thunder[i] <= 0.0:
			Audio.play("thunder", "weather", -4.0, 0.12)
			_thunder.remove_at(i)
	_parts.queue_redraw()


## A bolt of lightning: the flash, its jagged line for a moment (in a gas storm: the cloud lit from within), thunder.
func strike() -> void:
	strikes += 1
	_next_strike = 5.0 + randf() * 9.0
	_flash = 1.0
	_bolt_t = 0.22
	var x := randf_range(0.1, 0.9) * _sz.x
	var y0 := randf_range(0.0, 0.15) * _sz.y
	var y1 := randf_range(0.35, 0.7) * _sz.y
	_bolt = PackedVector2Array()
	var px := x
	var y := y0
	while y < y1:
		_bolt.append(Vector2(px, y))
		y += randf_range(10.0, 26.0)
		px += randf_range(-14.0, 14.0)
	_bolt.append(Vector2(px, y1))
	_glow = Vector2(x, y0 + (y1 - y0) * 0.3) if kind() == "gasstorm" else Vector2.INF
	_thunder.append(randf_range(0.4, 2.2))


## People put their holo umbrellas up when it rains, and down again after (Luz) – not the guards, not you.
func _people() -> void:
	if view == null or not is_instance_valid(view):
		return
	var on := Weather.wet(w)
	for p in view.people:
		if is_instance_valid(p) and p.npc and not p.guard and p.creature == "":
			p.umbrella_on = on


func _sound() -> void:
	var kd := kind()
	var kk := k()
	var rain := {"rain": 0.5, "storm": 0.85, "acid": 0.45}.get(kd, 0.0) as float
	var wind := {"blizzard": 0.8, "sandstorm": 0.8, "dust": 0.25, "gaswind": 0.5, "gasstorm": 0.95, "storm": 0.35, "snow": 0.15, "ash": 0.2}.get(kd, 0.0) as float
	Audio.loop("weather_rain", "amb_rain", rain * kk > 0.05, rain * kk)
	Audio.loop("weather_wind", "amb_wind", wind * kk > 0.05, wind * kk, 1.25 if kd == "gasstorm" else 1.0)


func _h(i: int, j: int) -> float:
	var v := sin(float(i) * 12.9898 + float(j) * 78.233) * 43758.5453
	return v - floor(v)


## Particles falling or flying: n of them, each with its own speed around `v` (px/s), drawn as a streak `ln` px long
## (0: a fleck `sz` big). Wrapped over the screen, moved with the camera a little so they stay with the world.
func _fall(n: int, v: Vector2, ln: float, col: Color, sz: float, seed_: int, wobble: float = 0.0) -> void:
	var sh := Vector2.ZERO
	if view != null and is_instance_valid(view) and view._world != null:
		sh = view._world.position
	var W := _sz.x + 200.0
	var H := _sz.y + 200.0
	var dirv := v.normalized()
	for i in n:
		var sp := 0.75 + 0.5 * _h(i, seed_ + 3)
		var p := Vector2(_h(i, seed_) * W, _h(i, seed_ + 1) * H) + v * sp * _t + sh
		if wobble > 0.0:
			p.x += sin(_t * 1.7 + i) * wobble
		p = Vector2(fposmod(p.x, W) - 100.0, fposmod(p.y, H) - 100.0)
		if ln > 0.0:
			_parts.draw_line(p, p + dirv * ln * sp, col, maxf(1.0, sz))
		else:
			_parts.draw_rect(Rect2(p, Vector2(sz, sz)), col)


func _splashes(n: int, col: Color) -> void:
	for i in n:
		var ph := fposmod(_t * 2.2 + _h(i, 7), 1.0)
		var cyc := int(_t * 2.2 + _h(i, 7))
		var p := Vector2(_h(i, 8 + cyc) * _sz.x, _h(i, 9 + cyc) * _sz.y)
		var r := 2.0 + ph * 7.0
		_parts.draw_set_transform(p, 0.0, Vector2(1.0, 0.4))
		_parts.draw_arc(Vector2.ZERO, r, 0.0, TAU, 12, Color(col, col.a * (1.0 - ph)), 1.5)
		_parts.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_parts() -> void:
	var kd := kind()
	var kk := k()
	if kk <= 0.0:
		return
	match kd:
		"rain":
			_fall(int(380 * kk), Vector2(300, 950), 22.0, Color(0.78, 0.85, 1.0, 0.42), 1.0, 11)
			_splashes(int(45 * kk), Color(0.82, 0.9, 1.0, 0.55))
		"storm":
			_fall(int(700 * kk), Vector2(620, 1300), 30.0, Color(0.8, 0.86, 1.0, 0.5), 1.0, 12)
			_splashes(int(90 * kk), Color(0.82, 0.9, 1.0, 0.6))
		"acid":
			_fall(int(360 * kk), Vector2(220, 880), 20.0, Color(0.8, 1.0, 0.45, 0.42), 1.0, 13)
			_splashes(int(40 * kk), Color(0.85, 1.0, 0.5, 0.6))
		"snow":
			_fall(int(260 * kk), Vector2(25, 75), 0.0, Color(1, 1, 1, 0.85), 3.0, 14, 10.0)
			_fall(int(90 * kk), Vector2(40, 110), 0.0, Color(1, 1, 1, 0.95), 4.0, 15, 14.0)
		"blizzard":
			_fall(int(800 * kk), Vector2(1100, 180), 14.0, Color(1, 1, 1, 0.75), 2.0, 16)
			_fall(int(200 * kk), Vector2(1500, 260), 8.0, Color(1, 1, 1, 0.95), 3.0, 17)
		"dust":
			_fall(int(120 * kk), Vector2(260, 20), 4.0, Color(0.95, 0.78, 0.55, 0.45), 2.0, 18)
		"sandstorm":
			_fall(int(1000 * kk), Vector2(1300, 90), 18.0, Color(1.0, 0.9, 0.72, 0.7), 2.0, 19)
			_fall(int(250 * kk), Vector2(1700, 120), 10.0, Color(0.7, 0.45, 0.28, 0.7), 3.0, 26)
			for dd in 2:                                                    # dust devils wandering across
				var c := Vector2(fposmod(_sz.x * (0.3 + dd * 0.45) + _t * (40.0 + dd * 25.0), _sz.x + 300.0) - 150.0, _sz.y * (0.55 + dd * 0.18))
				for t2 in 120:
					var a := t2 * 0.35 - _t * 9.0
					var r := 6.0 + t2 * 0.45
					_parts.draw_rect(Rect2(c + Vector2(cos(a) * r, sin(a) * r * 0.45 - t2 * 1.05), Vector2(3, 3)), Color(0.92, 0.7, 0.45, 0.45 * kk))
		"ash":
			_fall(int(220 * kk), Vector2(30, 55), 0.0, Color(0.5, 0.47, 0.46, 0.85), 3.0, 20, 12.0)
			for e in int(30 * kk):                                          # embers rising, glowing
				var ph := fposmod(_t * 0.18 + _h(e, 21), 1.0)
				var p := Vector2(_h(e, 22) * _sz.x + sin(_t + e) * 14.0, _sz.y * (1.05 - ph * 1.1))
				_parts.draw_rect(Rect2(p, Vector2(3, 3)), Color(1.0, 0.55 + 0.3 * _h(e, 23), 0.2, 0.9 * (1.0 - ph)))
		"gaswind":
			_fall(int(260 * kk), Vector2(1600, 40), 60.0, Color((look.get("haze", Color(0.95, 0.85, 0.65)) as Color).lightened(0.15), 0.45), 2.0, 24)
		"gasstorm":
			var bl: Array = look.get("bands", [Color(0.95, 0.85, 0.65)])
			_fall(int(500 * kk), Vector2(3400, 110), 110.0, Color((bl[0] as Color).lightened(0.2), 0.45), 2.0, 25)
			_fall(int(300 * kk), Vector2(2600, 80), 70.0, Color((bl[mini(3, bl.size() - 1)] as Color), 0.5), 3.0, 27)
	# lightning
	if _glow != Vector2.INF and _flash > 0.0:
		var fc: Color = look.get("flash", Color(0.85, 0.9, 1.0))
		for r2 in 6:
			_parts.draw_set_transform(_glow, 0.0, Vector2(2.2, 1.0))
			_parts.draw_circle(Vector2.ZERO, 120.0 - r2 * 18.0, Color(fc, 0.07 * _flash))
		_parts.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _bolt_t > 0.0 and _bolt.size() > 1:
		var bc: Color = look.get("flash", Color(0.85, 0.9, 1.0)) if cloud else Color(0.88, 0.92, 1.0)
		_parts.draw_polyline(_bolt, Color(bc, 0.35), 7.0)
		_parts.draw_polyline(_bolt, Color(1, 1, 1, 0.95), 2.5)
		for bi in range(3, _bolt.size() - 2, 5):                           # a few branches
			var b0 := _bolt[bi]
			_parts.draw_line(b0, b0 + Vector2((_h(bi, 31) - 0.5) * 70.0, 30.0 + _h(bi, 32) * 30.0), Color(1, 1, 1, 0.6), 1.5)
