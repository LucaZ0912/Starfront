extends Node2D
## Package 54 (Luz): what lies around and below a cloud city – laid under the map, which leaves the void clear. The
## sea of clouds (shaders/cloud_sea.gdshader, parallax in three layers far below), other platforms far off in the
## haze drifting past, the struts and lift tanks hanging under the deck's rim, the skyrail's beam with its masts and –
## at a station – the car hanging from it; lightning now and then deep down. In the skyrail's car `scroll` grows as it
## runs: the clouds, the platforms and the beam's masts pass by, each at its depth.

const SeaShader = preload("res://shaders/cloud_sea.gdshader")
const ParkedArtC = preload("res://scripts/ground/parked_art.gd")
const CloudGenC = preload("res://scripts/ground/cloud_gen.gd")
const FREIGHT_ART := 4.0                # art px per unit of a hull's length – a great freighter at the berth (0.7.54.2)
const SkyShader = preload("res://shaders/cloud_sky.gdshader")
const S := GroundMap.SCALE
const DEEP_P := 0.12                    # how much the deep layer follows the view (it is far down)

var look: Dictionary = {}
var map: GroundMap
var scroll := 0.0
var light := 1.0
var car_open := true                    # the station's car: doors open
var platforms: Array = []               # 0.7.54.2: aboard – the stations' platforms the car leaves and comes to {x, name}
var _rect: ColorRect
var _mat: ShaderMaterial
var _fx: Node2D
var _plats: Array = []                  # far platforms: {q (layer px), r, p, sd}
var _flash := 0.0
var _flash_t := 3.0
var _bolt: PackedVector2Array = PackedVector2Array()
var _bolt_at := Vector2.ZERO
var _vortex_set := false
var _cam := Vector2.ZERO
var _view := Vector2(533, 300)
var _rng := RandomNumberGenerator.new()


func setup(p_look: Dictionary, p_map: GroundMap, sd: int) -> void:
	look = p_look
	map = p_map
	_rng.seed = sd
	_mat = ShaderMaterial.new()
	_mat.shader = SeaShader
	var bands: Array = look["bands"]
	for i in 5:
		_mat.set_shader_parameter("band%d" % i, bands[i])
	_mat.set_shader_parameter("deep", look["deep"])
	_mat.set_shader_parameter("haze", look["haze"])
	_mat.set_shader_parameter("flash_col", look["flash"])
	_mat.set_shader_parameter("seed", float(sd % 97))
	_mat.set_shader_parameter("px_per_art", S)
	_rect = ColorRect.new()
	_rect.material = _mat
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var margin := 3000.0
	_rect.position = Vector2(-margin, -margin)
	_rect.size = map.size_px() * S + Vector2(margin, margin) * 2.0
	_mat.set_shader_parameter("origin", _rect.position / S)
	add_child(_rect)
	_fx = Node2D.new()
	_fx.draw.connect(_draw_fx)
	add_child(_fx)
	if map.has_meta("freighter"):
		_add_freighter(map.get_meta("freighter"))
	# platforms far off in the haze: at their depth (p), their size
	for i in 7:
		var p := _rng.randf_range(0.2, 0.55)
		_plats.append({"q": Vector2(_rng.randf_range(0.0, 1400.0), _rng.randf_range(-60.0, map.size_px().y + 160.0)), "r": lerpf(16.0, 70.0, p) * _rng.randf_range(0.7, 1.2),
			"p": p, "sd": _rng.randi() % 1000})
	_plats.sort_custom(func(a, b): return float(a["p"]) < float(b["p"]))


func set_light(d: float) -> void:
	light = clampf(0.25 + d * 0.85, 0.0, 1.0)


func _process(delta: float) -> void:
	var world := get_parent() as Node2D
	if world == null:
		return
	var z := maxf(world.scale.x, 0.01)
	_cam = -world.position / (z * S)
	_view = get_viewport().get_visible_rect().size / (z * S)
	if not _vortex_set:
		_vortex_set = true
		# the storm eddy: out in the lower right of the first view
		_mat.set_shader_parameter("vortex", _cam * 0.3 + _view * Vector2(0.78, 0.85) - Vector2(0, 0))
	_mat.set_shader_parameter("cam", _cam)
	_mat.set_shader_parameter("scroll", scroll)
	_mat.set_shader_parameter("light", light)
	# lightning deep down now and then
	_flash_t -= delta
	if _flash_t <= 0.0:
		_flash_t = _rng.randf_range(2.5, 8.0)
		_flash = 1.0
		var at := _cam + _view * Vector2(_rng.randf_range(0.1, 0.9), _rng.randf_range(0.5, 0.95))
		_bolt_at = at
		_mat.set_shader_parameter("flash_at", (at - _cam * (1.0 - DEEP_P) + Vector2(scroll * DEEP_P, 0.0)) * 1.7)
		_bolt = PackedVector2Array()
		var q := Vector2(0, -14)
		for k in 18:
			_bolt.append(q)
			q += Vector2(_rng.randf_range(-3.5, 3.5), 1.6)
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * (2.2 if _flash > 0.5 else 1.2))
		if _flash > 0.6 and _rng.randf() < 0.08:
			_flash = 1.0                                # it flickers
	_mat.set_shader_parameter("flash", _flash * 0.9)
	_fx.queue_redraw()


## 0.7.54.2 (Luz): a great gas freighter lying at the gas works' berth – the ship made plastic (ParkedArt, floating),
## at its real size from the hull's length, nose to the east; its shadow on the clouds far below; the clamps holding
## it and the loading hose from the rim.
var _freighter: Sprite2D = null
var _fr_rect := Rect2()


func _add_freighter(fr: Dictionary) -> void:
	var hull := String(fr.get("hull", "kujira"))
	var tex := PixelArt.ship_texture(hull, "trade")
	var ln := float(GameData.hulls.get(hull, {}).get("length", 116))
	var want := ln * FREIGHT_ART
	var sc := want / float(tex.get_width())
	var art: Dictionary = ParkedArtC.make(hull, "trade", sc, 40, true)
	var sh := Sprite2D.new()                    # its shadow far down on the clouds
	sh.texture = art["tex"]
	sh.centered = false
	sh.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sh.modulate = Color(look["deep"], 0.22)
	sh.scale = Vector2.ONE * S
	var tl := Vector2(float(fr["x"]) + (art["off"] as Vector2).x, float(fr["y"]) + 18.0)        # its top-left: just under the rim
	sh.position = (tl + Vector2(70, 150)) * S
	add_child(sh)
	_freighter = Sprite2D.new()
	_freighter.texture = art["tex"]
	_freighter.centered = false
	_freighter.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_freighter.scale = Vector2.ONE * S
	_freighter.position = tl * S
	add_child(_freighter)
	var tsz: Vector2 = (art["tex"] as Texture2D).get_size()
	_fr_rect = Rect2(tl, tsz)
	var arms := Node2D.new()
	arms.draw.connect(func() -> void:
		arms.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * S)
		if not map.has_meta("berth"):
			return
		var b: Dictionary = map.get_meta("berth")
		var y0 := float(b["y"])
		var top := maxf(_fr_rect.position.y + _fr_rect.size.y * 0.32, y0 + 24.0)
		for ax in [float(b["x"]) + 24.0, float(b["x"]) + float(b["w"]) - 30.0]:
			arms.draw_rect(Rect2(ax, y0, 10.0, top - y0), Color(0.45, 0.46, 0.5))
			arms.draw_rect(Rect2(ax, y0, 2.0, top - y0), Color(0.7, 0.72, 0.76))
			arms.draw_rect(Rect2(ax - 4.0, top - 4.0, 18.0, 8.0), Color(0.95, 0.75, 0.2))
		var hx := float(b["x"]) + float(b["w"]) * 0.5
		for yy in int(top - y0):
			var sw := sin(float(yy) * 0.08) * 3.0
			arms.draw_rect(Rect2(hx + sw - 4.0, y0 + yy, 8.0, 1.0), Color(0.25, 0.26, 0.28) if yy % 10 > 1 else Color(0.95, 0.7, 0.2)))
	add_child(arms)


## A layer point's place in the world (art px) at depth p (1 = with the deck).
func _at(q: Vector2, p: float) -> Vector2:
	return q - Vector2(scroll * p, 0.0) + _cam * (1.0 - p)


func _draw_fx() -> void:
	_fx.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * S)
	var hz: Color = look["haze"]
	var dp: Color = look["deep"]
	# the far platforms, wrapped round the view
	for pl in _plats:
		var p := float(pl["p"])
		var w := _at(pl["q"], p)
		var span := _view.x + 600.0
		w.x = _cam.x - 300.0 + fposmod(w.x - (_cam.x - 300.0), span)
		_far_platform(w, float(pl["r"]), int(pl["sd"]), clampf(1.0 - p * 1.4, 0.15, 0.85), hz, dp)
	# the bolt of lightning, while it is bright
	if _flash > 0.45 and _bolt.size() > 1:
		var off := _bolt_at
		var pts := PackedVector2Array()
		for b in _bolt:
			pts.append(off + b)
		_fx.draw_polyline(pts, Color(1, 1, 1, 0.85 * _flash), 1.0)
	# under the deck: struts, lift tanks, rotors going down into the haze
	if map.has_meta("spindles"):
		var sp: Dictionary = map.get_meta("spindles")
		var y0 := float(sp["y"])
		for s in sp["list"]:
			var sx := float(s[0])
			var ln := float(s[1])
			var wd := float(s[2])
			for yy in int(ln):
				var k := float(yy) / ln
				var ww := maxf(2.0, wd * (1.0 - k * 0.7))
				_fx.draw_rect(Rect2(sx - ww * 0.5, y0 + yy, ww, 1.0), Color(0.32, 0.33, 0.37).lerp(hz, k * 0.75))
			if bool(s[3]):
				_fx.draw_rect(Rect2(sx - wd * 1.2, y0 + ln * 0.35, wd * 2.4, wd * 0.9), Color(0.4, 0.42, 0.46).lerp(hz, 0.3))       # a lift tank
				_fx.draw_rect(Rect2(sx - wd * 1.2, y0 + ln * 0.35, wd * 2.4, 1.0), Color(0.6, 0.62, 0.66).lerp(hz, 0.3))
			_fx.draw_rect(Rect2(sx - 1.0, y0 + ln - 3.0, 3.0, 2.0), Color(0.5, 0.85, 1.0, 0.85))
	# 0.7.54.2: the gas works' intakes – thick hoses from the winches down into the clouds, swaying
	if map.has_meta("intakes"):
		var ik: Dictionary = map.get_meta("intakes")
		var iy := float(ik["y"])
		var tt := Time.get_ticks_msec() / 1000.0
		for it in ik["list"]:
			var ix := float(it[0])
			var iln := float(it[1])
			var iw := float(it[2])
			for yy3 in int(iln):
				var k3 := float(yy3) / iln
				var sway := sin(float(yy3) * 0.035 + ix + tt * 0.6) * 6.0 * k3
				var ww3 := maxf(2.0, iw * (1.0 - k3 * 0.55))
				var c3 := Color(0.32, 0.33, 0.35).lerp(hz, k3 * 0.8)
				if yy3 % 14 == 0:
					c3 = Color(0.95, 0.7, 0.2).lerp(hz, k3 * 0.8)
				_fx.draw_rect(Rect2(ix - ww3 * 0.5 + sway, iy + yy3, ww3, 1.0), c3)
			_fx.draw_rect(Rect2(ix - 2.0 + sin(iln * 0.035 + ix + tt * 0.6) * 6.0, iy + iln - 2.0, 4.0, 2.0), Color(0.5, 0.9, 1.0, 0.8))
	# the skyrail's beam: across the view, its joints and masts passing as the car runs
	if map.has_meta("beam_y"):
		var by := float(map.get_meta("beam_y"))
		var x0 := _cam.x - 40.0
		var x1 := _cam.x + _view.x + 40.0
		if map.has_meta("beam_x1"):
			x1 = minf(x1, float(map.get_meta("beam_x1")))            # the line ends at the gas works
		_fx.draw_rect(Rect2(x0, by + 90.0 + _cam.y * 0.0, x1 - x0, 1.0), Color(dp, 0.22))                  # its shadow far below
		_fx.draw_rect(Rect2(x0, by, x1 - x0, 6.0), Color(0.6, 0.62, 0.66))
		_fx.draw_rect(Rect2(x0, by, x1 - x0, 1.0), Color(0.86, 0.88, 0.9))
		_fx.draw_rect(Rect2(x0, by + 5.0, x1 - x0, 1.0), Color(0.38, 0.4, 0.44))
		var j0 := floorf((x0 + scroll) / 30.0) * 30.0 - scroll
		var j := j0
		while j < x1:
			_fx.draw_rect(Rect2(j, by + 1.0, 2.0, 4.0), Color(0.42, 0.44, 0.48))
			j += 30.0
		var m0 := floorf((x0 + scroll) / 520.0) * 520.0 - scroll
		var mx := m0
		while mx < x1:
			# a mast holding the beam: down into the haze to a lift tank far below
			for yy2 in 150:
				var k2 := float(yy2) / 150.0
				_fx.draw_rect(Rect2(mx + 2.0 - (1.0 - k2) * 2.0, by + 6.0 + yy2, 8.0 - k2 * 3.0, 1.0), Color(0.36, 0.37, 0.41).lerp(hz, k2 * 0.8))
			mx += 520.0
	# 0.7.54.2 (Luz): aboard – the platform you left sliding away behind, the next one coming in
	for pf in platforms:
		_draw_platform(float(pf["x"]) - scroll)
	# the car waiting at the platform: hanging from the beam, 20 m, its doors open
	if map.has_meta("car"):
		_draw_car(map.get_meta("car"))


## A station's platform seen from the car under it (over the beam, x0: where the car's west end stands when it is in):
## its pale floor, people waiting, the yellow line, the glass screens open at the doors, its rim with lights.
func _draw_platform(x0: float) -> void:
	var T := float(GroundMap.TILE)
	var by := float(map.get_meta("beam_y", 64.0))
	var rim := by - T
	var ax := x0 - 9.0 * T                     # the platform runs on both sides of the car's place
	var aw := 40.0 * T
	if ax > _cam.x + _view.x + 20.0 or ax + aw < _cam.x - 20.0:
		return
	var top := minf(_cam.y - 4.0, rim - 3.0 * T)
	for yy in range(int(top), int(rim), 4):
		var row := int(floor(float(yy) / 30.0))
		_fx.draw_rect(Rect2(ax, yy, aw, 4.0), Color(0.62, 0.64, 0.66) if row % 2 == 0 else Color(0.59, 0.61, 0.63))
	for gx in range(0, int(aw), 32):
		_fx.draw_rect(Rect2(ax + gx, top, 1.0, rim - top), Color(0.52, 0.54, 0.56))
	var rr := RandomNumberGenerator.new()
	rr.seed = int(x0) + 77
	for p in 9:                                # people waiting, seen from above
		var px := ax + rr.randf_range(10.0, aw - 10.0)
		var py := rim - rr.randf_range(26.0, 40.0)
		_fx.draw_rect(Rect2(px, py, 6.0, 9.0), Color.from_hsv(rr.randf(), 0.45, 0.55))
		_fx.draw_rect(Rect2(px + 1.0, py - 4.0, 4.0, 4.0), Color(0.62, 0.45, 0.35))
	_fx.draw_rect(Rect2(ax, rim - 21.0, aw, 5.0), Color(0.95, 0.8, 0.2))
	var doors: Array = []
	for d in CloudGenC.CAR_DOORS:
		doors.append(x0 + float(d) * T)
	var sx := ax
	while sx < ax + aw:
		var gap := false
		for dx in doors:
			if sx >= dx - 0.5 and sx < dx + 2.0 * T:
				gap = true
		if not gap:
			_fx.draw_rect(Rect2(sx, rim - 16.0, 4.0, 14.0), Color(0.75, 0.9, 1.0, 0.45))
			_fx.draw_rect(Rect2(sx, rim - 16.0, 4.0, 1.0), Color(0.92, 0.95, 1.0))
		sx += 4.0
	_fx.draw_rect(Rect2(ax, rim, aw, T), Color(0.5, 0.52, 0.56))
	_fx.draw_rect(Rect2(ax, rim, aw, 2.0), Color(0.92, 0.93, 0.94))
	_fx.draw_rect(Rect2(ax, rim + T - 1.0, aw, 1.0), Color(0.2, 0.2, 0.22))
	for lx in range(8, int(aw), 32):
		_fx.draw_rect(Rect2(ax + lx, rim + 7.0, 4.0, 2.0), Color(0.55, 0.9, 1.0))
	for dx2 in doors:
		_fx.draw_rect(Rect2(dx2, rim, 2.0 * T, T), Color(0.6, 0.62, 0.65))
		_fx.draw_rect(Rect2(dx2, rim, 2.0 * T, 2.0), Color(0.95, 0.8, 0.2))
	_fx.draw_rect(Rect2(ax, rim + T, aw, 3.0), Color(0, 0, 0, 0.25))


func _far_platform(c: Vector2, r: float, sd: int, fade: float, hz: Color, dp: Color) -> void:
	var body := Color(0.66, 0.66, 0.66).lerp(hz, fade)
	var face := Color(0.36, 0.36, 0.4).lerp(hz, fade)
	var rr := RandomNumberGenerator.new()
	rr.seed = sd
	for k in 5:
		var sx := c.x + (k - 2) * r * 0.28
		var ln := r * (0.4 + rr.randf() * 0.6)
		_fx.draw_colored_polygon(PackedVector2Array([Vector2(sx - 2.0 - r * 0.03, c.y + r * 0.2), Vector2(sx + 2.0 + r * 0.03, c.y + r * 0.2), Vector2(sx, c.y + r * 0.2 + ln)]), face.lerp(hz, 0.3))
	_ellipse(c + Vector2(0, 3), Vector2(r, r * 0.3), face)
	_ellipse(c, Vector2(r, r * 0.28), body)
	for t in 7:
		var tx := c.x + (rr.randf() - 0.5) * r * 1.4
		var th := 5.0 + rr.randf() * r * 0.55
		var tw := 3.0 + float(t % 3) * 2.0
		_fx.draw_rect(Rect2(tx, c.y - th, tw, th), body.lightened(0.06))
		_fx.draw_rect(Rect2(tx + tw - 1.0, c.y - th, 1.0, th), body.darkened(0.08))
	for l in 8:
		var a := l * PI / 7.0
		_fx.draw_rect(Rect2(c.x + cos(a) * r * 0.95, c.y + sin(a) * r * 0.27 + 2.0, 1.0, 1.0), Color(0.6, 0.9, 1.0, 0.7 * (1.0 - fade * 0.6)))


func _ellipse(c: Vector2, r: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	_fx.draw_colored_polygon(pts, col)


func _draw_car(car: Dictionary) -> void:
	var cx := float(car["x"])
	var cy := float(car["y"]) + 6.0
	var ln := float(car["len"])
	var T := float(GroundMap.TILE)
	var rr := RandomNumberGenerator.new()
	rr.seed = 54
	# the roof seen from above, its vents; the car hangs from its running gear on the beam (drawn over it)
	_fx.draw_rect(Rect2(cx, cy + 3.0, ln, 28.0), Color(0.88, 0.9, 0.92))
	_fx.draw_rect(Rect2(cx, cy + 3.0, ln, 2.0), Color(1, 1, 1))
	for v in 6:
		_fx.draw_rect(Rect2(cx + 20.0 + v * (ln - 40.0) / 5.0 - 12.0, cy + 13.0, 24.0, 12.0), Color(0.7, 0.72, 0.75))
	# 0.7.54 (Luz): the doors are on the platform's side – the car's north side, under the platform's edge: seen from
	# above as openings at the roof's north edge, an orange frame, the threshold plate
	for d in car["doors"]:
		var dx := cx + float(d) * T
		_fx.draw_rect(Rect2(dx - 2.0, cy + 3.0, 2.0 * T + 4.0, 9.0), Color(0.95, 0.6, 0.2))
		if car_open:
			_fx.draw_rect(Rect2(dx, cy + 3.0, 2.0 * T, 7.0), Color(0.16, 0.18, 0.22))
			_fx.draw_rect(Rect2(dx + 2.0, cy + 3.0, 2.0 * T - 4.0, 2.0), Color(0.55, 0.57, 0.6))
		else:
			_fx.draw_rect(Rect2(dx, cy + 3.0, 2.0 * T, 7.0), Color(0.74, 0.76, 0.8))
	# its side towards you: big windows, the inside seen through them – the far wall, the seats, people
	var sy := cy + 31.0
	_fx.draw_rect(Rect2(cx, sy, ln, 40.0), Color(0.84, 0.86, 0.88))
	var wx := cx + 4.0
	while wx < cx + ln - 6.0:
		var ww := minf(42.0, cx + ln - 4.0 - wx)
		_fx.draw_rect(Rect2(wx, sy + 4.0, ww, 24.0), Color(0.93, 0.88, 0.8))                  # the far side's wall and windows
		_fx.draw_rect(Rect2(wx, sy + 6.0, ww, 8.0), Color(0.98, 0.86, 0.68))
		_fx.draw_rect(Rect2(wx, sy + 17.0, ww, 11.0), Color(0.42, 0.44, 0.48))               # the floor
		var sx := wx + 1.0
		while sx + 6.0 < wx + ww:
			_fx.draw_rect(Rect2(sx, sy + 13.0, 6.0, 6.0), Color(0.25, 0.42, 0.62))           # seats along the far side
			if rr.randf() < 0.3:
				_fx.draw_rect(Rect2(sx + 1.0, sy + 8.0, 4.0, 4.0), Color(0.62, 0.45, 0.35))     # someone sitting
				_fx.draw_rect(Rect2(sx + 1.0, sy + 12.0, 4.0, 6.0), Color.from_hsv(rr.randf(), 0.5, 0.6))
			sx += 8.0
		_fx.draw_rect(Rect2(wx, sy + 4.0, ww, 24.0), Color(0.6, 0.8, 0.95, 0.22))             # the glass
		for k in 3:
			_fx.draw_rect(Rect2(wx + 8.0 + k * 3.0, sy + 6.0, 1.0, 18.0 - k * 4.0), Color(1, 1, 1, 0.22))
		wx += 46.0
	_fx.draw_rect(Rect2(cx, sy + 30.0, ln, 2.0), Color(0.95, 0.6, 0.2))
	_fx.draw_rect(Rect2(cx, sy + 40.0, ln, 2.0), Color(0.35, 0.36, 0.4))
	_fx.draw_rect(Rect2(cx + 10.0, sy + 42.0, ln - 20.0, 4.0), Color(0, 0, 0, 0.18))
	var bt := Time.get_ticks_msec() / 1000.0
	for bx in [cx + ln * 0.2, cx + ln * 0.8]:
		CarShell.draw_bogie(_fx, bx, float(map.get_meta("beam_y")), cy + 5.0, bt)


## 0.7.54 (Luz): the skyrail's car seen from outside while you ride in it – closed: the roof over it, its side towards
## you with big windows, through which you see inside (yourself, the seats, the people). `front` draws the body in
## front of the people; the back part (z under them) opens the doors in the far wall when the car has arrived.
class CarShell extends Node2D:
	## 0.7.54.2 (Luz): the car's running gear – a maglev bogie wrapped round the beam (its clamp jaws above and below the
	## rail, field coils glowing and pulsing along it), a pylon down from it through a fairing into the roof. x: its
	## middle; beam_y: the beam's top; roof_y: the roof's top (art px).
	static func draw_bogie(ci: CanvasItem, x: float, beam_y: float, roof_y: float, t: float) -> void:
		var w := 46.0
		var dark := Color(0.26, 0.27, 0.31)
		var body := Color(0.55, 0.57, 0.62)
		var glow := Color(0.45, 0.9, 1.0)
		# the clamp round the beam: a housing over it, jaws under it
		ci.draw_rect(Rect2(x - w * 0.5, beam_y - 7.0, w, 7.0), body)
		ci.draw_rect(Rect2(x - w * 0.5, beam_y - 7.0, w, 1.0), Color(0.8, 0.82, 0.86))
		ci.draw_rect(Rect2(x - w * 0.5 + 3.0, beam_y - 9.0, w - 6.0, 2.0), dark)
		ci.draw_rect(Rect2(x - w * 0.5, beam_y + 6.0, w, 4.0), dark)
		ci.draw_rect(Rect2(x - w * 0.5, beam_y - 1.0, 3.0, 11.0), body.darkened(0.2))
		ci.draw_rect(Rect2(x + w * 0.5 - 3.0, beam_y - 1.0, 3.0, 11.0), body.darkened(0.2))
		# the field coils along the rail, pulsing one after the other
		for k in 6:
			var a := 0.45 + 0.55 * (0.5 + 0.5 * sin(t * 9.0 - k * 1.1))
			ci.draw_rect(Rect2(x - w * 0.5 + 5.0 + k * 6.5, beam_y - 5.0, 4.0, 3.0), Color(glow, a))
			ci.draw_rect(Rect2(x - w * 0.5 + 5.0 + k * 6.5, beam_y + 7.0, 4.0, 2.0), Color(glow, a * 0.8))
		ci.draw_rect(Rect2(x - w * 0.5 - 2.0, beam_y + 1.0, w + 4.0, 2.0), Color(glow, 0.18))       # the field's glow on the rail
		# the pylon down to the roof, its fairing
		var py0 := beam_y + 10.0
		if roof_y > py0:
			ci.draw_rect(Rect2(x - 4.0, py0, 8.0, roof_y - py0), dark)
			ci.draw_rect(Rect2(x - 4.0, py0, 2.0, roof_y - py0), body)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x - 14.0, roof_y + 3.0), Vector2(x + 14.0, roof_y + 3.0), Vector2(x + 8.0, roof_y - 3.0), Vector2(x - 8.0, roof_y - 3.0)]), body.lightened(0.15))
		ci.draw_rect(Rect2(x - 2.0, py0 + 1.0, 4.0, 2.0), Color(1.0, 0.45, 0.3, 0.6 + 0.4 * sin(t * 3.0)))

	var shell: Dictionary = {}
	var front := true
	var view = null

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var s := GroundMap.SCALE
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * s)
		var x0 := float(shell["x0"])
		var x1 := float(shell["x1"])
		var top := float(shell["top"])
		var y0 := float(shell["side"])
		var y1 := float(shell["bottom"])
		if not front:
			var arrived: bool = view != null and bool(view.rail.get("arrived", false))
			if arrived:
				var dr: Rect2 = shell["door"]
				draw_rect(dr, Color(0.86, 0.87, 0.88))                              # the doors open: the platform beyond
				draw_rect(Rect2(dr.position.x, dr.end.y - 6.0, dr.size.x, 6.0), Color(0.95, 0.8, 0.2))
				draw_rect(Rect2(dr.position.x - 2.0, dr.position.y, 2.0, dr.size.y), Color(0.95, 0.6, 0.2))
				draw_rect(Rect2(dr.end.x, dr.position.y, 2.0, dr.size.y), Color(0.95, 0.6, 0.2))
			return
		var body := Color(0.88, 0.9, 0.92)
		# the noses at both ends
		for ex in [[x0 - 10.0, x0 + 4.0], [x1 - 4.0, x1 + 10.0]]:
			draw_rect(Rect2(ex[0], top + 4.0, ex[1] - ex[0], y1 - top - 6.0), body.darkened(0.06))
			draw_rect(Rect2(ex[0], top + 4.0, ex[1] - ex[0], 2.0), Color(1, 1, 1))
		# the roof: plates, vents
		draw_rect(Rect2(x0, top, x1 - x0, y0 - top), body)
		draw_rect(Rect2(x0, top, x1 - x0, 2.0), Color(1, 1, 1))
		draw_rect(Rect2(x0, y0 - 2.0, x1 - x0, 2.0), body.darkened(0.2))
		var vx := x0 + 24.0
		while vx < x1 - 30.0:
			draw_rect(Rect2(vx, top + 4.0, 24.0, y0 - top - 9.0), Color(0.72, 0.74, 0.77))
			vx += 64.0
		# the side: pillars between big windows, a skirt below with the line's orange stripe
		var wt := y0 + 3.0
		var wb := y1 - 13.0
		draw_rect(Rect2(x0, y0, x1 - x0, 3.0), body)
		var px := x0
		while px < x1:
			draw_rect(Rect2(px, y0, 5.0, wb - y0), body)
			draw_rect(Rect2(px + 4.0, y0, 1.0, wb - y0), body.darkened(0.15))
			px += 48.0
		draw_rect(Rect2(x1 - 5.0, y0, 5.0, wb - y0), body)
		var gx := x0 + 5.0
		while gx < x1 - 5.0:
			var gw := minf(43.0, x1 - 5.0 - gx)
			draw_rect(Rect2(gx, wt, gw, wb - wt), Color(0.6, 0.8, 0.95, 0.12))         # the glass
			for k in 3:
				var rx := gx + 6.0 + k * 3.0
				if rx < gx + gw:
					draw_line(Vector2(rx, wt + 2.0), Vector2(rx + 10.0, wb - 2.0 - k * 6.0), Color(1, 1, 1, 0.13), 1.0)
			gx += 48.0
		draw_rect(Rect2(x0, wb, x1 - x0, y1 - wb), body.darkened(0.04))
		draw_rect(Rect2(x0, wb, x1 - x0, 1.0), Color(0.6, 0.62, 0.66))
		draw_rect(Rect2(x0, wb + 5.0, x1 - x0, 2.0), Color(0.95, 0.6, 0.2))
		draw_rect(Rect2(x0, y1 - 2.0, x1 - x0, 2.0), Color(0.35, 0.36, 0.4))
		draw_rect(Rect2(x0 + 8.0, y1, x1 - x0 - 16.0, 4.0), Color(0, 0, 0, 0.18))
		var tt := Time.get_ticks_msec() / 1000.0               # 0.7.54.2 (Luz): the running gear on the beam
		for bx in [x0 + (x1 - x0) * 0.2, x0 + (x1 - x0) * 0.8]:
			draw_bogie(self, bx, float(shell["beam"]), top, tt)


## The giant's sky through a window (the skyrail's car, the bar): drawn inside the window's opening.
class CloudSky extends Node2D:
	var scroll := 0.0
	var _mat: ShaderMaterial
	var _fx: Node2D
	var _size := Vector2.ZERO
	var _look: Dictionary = {}
	var _plats: Array = []

	func setup(look: Dictionary, size: Vector2, horizon: float, sd: int) -> void:
		_look = look
		_size = size
		_mat = ShaderMaterial.new()
		_mat.shader = SkyShader
		var bands: Array = look["bands"]
		_mat.set_shader_parameter("art_size", size / GroundMap.SCALE)
		_mat.set_shader_parameter("horizon", horizon)
		_mat.set_shader_parameter("sky_top", look["sky_top"])
		_mat.set_shader_parameter("sky_low", look["sky_low"])
		_mat.set_shader_parameter("band0", bands[0])
		_mat.set_shader_parameter("band1", bands[1])
		_mat.set_shader_parameter("band2", bands[3])
		_mat.set_shader_parameter("deep", look["deep"])
		_mat.set_shader_parameter("haze", look["haze"])
		var r := ColorRect.new()
		r.material = _mat
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.size = size
		add_child(r)
		_fx = Node2D.new()
		_fx.draw.connect(_draw_fx)
		add_child(_fx)
		var rng := RandomNumberGenerator.new()
		rng.seed = sd
		for i in 4:
			_plats.append({"x": rng.randf_range(0.0, 1.0), "r": rng.randf_range(10.0, 26.0), "p": rng.randf_range(0.15, 0.4), "sd": rng.randi() % 1000})
		_mat.set_shader_parameter("horizon", horizon)
		set_meta("horizon", horizon)

	func set_light(d: float) -> void:
		_mat.set_shader_parameter("light", clampf(0.25 + d * 0.85, 0.0, 1.0))

	func _process(_delta: float) -> void:
		_mat.set_shader_parameter("scroll", scroll)
		_fx.queue_redraw()

	func _draw_fx() -> void:
		var s := GroundMap.SCALE
		_fx.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * s)
		var a := _size / s
		var hy := a.y * float(get_meta("horizon", 0.55))
		var hz: Color = _look["haze"]
		for pl in _plats:
			var span := a.x + 160.0
			var x := fposmod(float(pl["x"]) * span - scroll * float(pl["p"]) * 0.6, span) - 80.0
			var r := float(pl["r"])
			var fade := 0.55
			var body := Color(0.66, 0.66, 0.66).lerp(hz, fade)
			var pts := PackedVector2Array()
			for i in 16:
				var an := TAU * i / 16.0
				pts.append(Vector2(x + cos(an) * r, hy + 2.0 + sin(an) * r * 0.22))
			_fx.draw_colored_polygon(pts, body)
			var rr := RandomNumberGenerator.new()
			rr.seed = int(pl["sd"])
			for t in 5:
				var tx := x + (rr.randf() - 0.5) * r * 1.3
				var th := 3.0 + rr.randf() * r * 0.6
				_fx.draw_rect(Rect2(tx, hy + 2.0 - th, 2.0 + float(t % 2) * 2.0, th), body.lightened(0.05))
			for k in 3:
				_fx.draw_rect(Rect2(x + (k - 1) * r * 0.4, hy + 3.0, 1.5, r * 0.5), body.darkened(0.1).lerp(hz, 0.3))
