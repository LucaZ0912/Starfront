class_name CityHatch
extends CanvasLayer
## Package 50b (0.7.50.5, after Luz's idea): most ships are far too big for a city's streets – so a city takes them
## in below the ground. Seen from above: the roofs of the city all round, in the middle a giant landing hatch. Down:
## the ship comes down over it, the hatch's two leaves slide apart, the ship sinks into the shaft below (its lights
## running down into the deep), the hatch closes over her. Up: the same the other way round, then she climbs away.

signal finished

const DOWN_TIME := 7.0
const UP_TIME := 6.4

var body: Dictionary = {}
var site: Dictionary = {}
var down := true
var _t := 0.0
var _vs := Vector2(1600, 900)
var _city: Node2D                    # the roofs, the streets, the hatch's frame and shaft (drawn)
var _doors: Node2D                   # the hatch's two leaves (drawn over the ship once she is below)
var _ship: Sprite2D
var _shadow: Sprite2D
var _fx: Node2D
var _ship_s := 1.0
var _hatch := Rect2()                # the opening (screen px)
var _roofs: Array = []               # [rect, colour, height (for the shadow), kind]
var _cars: Array = []                # [lane (0 h / 1 v), lane pos, pos, speed, colour]
var _streets_h: Array = []
var _streets_v: Array = []
var _done := false
var hatch_no := 1


func open(p_body: Dictionary, p_site: Dictionary, p_down: bool = true) -> void:
	layer = 13
	body = p_body
	site = p_site
	down = p_down
	_vs = get_viewport().get_visible_rect().size if get_viewport() != null else Vector2(1600, 900)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(site.get("id", "x"))) + 50
	hatch_no = rng.randi_range(2, 48)
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.055, 0.075)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.z_index = -3
	add_child(bg)
	var f := GameState.active()
	var tex: Texture2D = PixelArt.ship_texture(f.hull_id if f != null else "dragonfly", (f.gov if f.gov != "" else f.faction) if f != null else "player")
	_ship_s = clampf(minf(380.0 / maxf(tex.get_width(), 1.0), 260.0 / maxf(tex.get_height(), 1.0)), 2.0, 7.0)
	var ssz := Vector2(tex.get_width(), tex.get_height()) * _ship_s
	var hs := Vector2(maxf(ssz.x + 120.0, 420.0), maxf(ssz.y + 110.0, 260.0))
	_hatch = Rect2((_vs - hs) * 0.5, hs).abs()
	_hatch.position = _hatch.position.round()
	_make_city(rng)
	_city = Node2D.new()
	_city.draw.connect(_draw_city)
	_city.z_index = -2
	add_child(_city)
	_shadow = Sprite2D.new()
	_shadow.texture = tex
	_shadow.modulate = Color(0, 0, 0, 0.5)
	_shadow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_shadow)
	_ship = Sprite2D.new()
	_ship.texture = tex
	_ship.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_ship)
	_doors = Node2D.new()
	_doors.draw.connect(_draw_doors)
	add_child(_doors)
	_fx = Node2D.new()
	_fx.draw.connect(_draw_fx)
	add_child(_fx)
	var title := UI.label("%s  ·  Landing hatch %d" % [String(site.get("name", "")), hatch_no], 20, UI.NEON_CYAN)
	title.position = Vector2(30, 24)
	add_child(title)
	var sub := UI.label("Down below the city – the ship is taken into its hangars" if down else "Up out of the city", 13, UI.TEXT_DIM)
	sub.position = Vector2(32, 54)
	add_child(sub)
	Audio.play("boost", "landing hatch")
	_update(0.0)


## The city round the hatch: blocks of towers between streets, cars on them.
func _make_city(rng: RandomNumberGenerator) -> void:
	var gx := -40.0
	while gx < _vs.x + 40.0:
		_streets_v.append(gx)
		gx += rng.randf_range(150.0, 240.0)
	var gy := -40.0
	while gy < _vs.y + 40.0:
		_streets_h.append(gy)
		gy += rng.randf_range(130.0, 200.0)
	var keep := _hatch.grow(46.0)
	for i in _streets_v.size() - 1:
		for j in _streets_h.size() - 1:
			var blk := Rect2(Vector2(_streets_v[i] + 14.0, _streets_h[j] + 14.0), Vector2(_streets_v[i + 1] - _streets_v[i] - 28.0, _streets_h[j + 1] - _streets_h[j] - 28.0))
			# a block: one to four towers
			var n := rng.randi_range(1, 4)
			for k in n:
				var rw := blk.size.x * rng.randf_range(0.35, 0.95)
				var rh := blk.size.y * rng.randf_range(0.35, 0.95)
				var r := Rect2(blk.position + Vector2(rng.randf_range(0.0, blk.size.x - rw), rng.randf_range(0.0, blk.size.y - rh)), Vector2(rw, rh))
				r.position = r.position.round()
				r.size = r.size.round()
				if r.intersects(keep):
					continue
				var shade := rng.randf_range(0.1, 0.22)
				var col := Color(shade * 0.9, shade * 0.95, shade * 1.15)
				_roofs.append([r, col, rng.randf_range(10.0, 34.0), rng.randi() % 5])
	for c in 46:
		var horiz := rng.randf() < 0.5
		var lane: float = (_streets_h[rng.randi() % _streets_h.size()] if horiz else _streets_v[rng.randi() % _streets_v.size()]) + (6.0 if rng.randf() < 0.5 else -6.0)
		var cc: Color = [Color(1.0, 0.95, 0.8), Color(1.0, 0.3, 0.25), Color(1.0, 0.85, 0.5)][rng.randi() % 3]
		_cars.append([0 if horiz else 1, lane, rng.randf_range(0.0, _vs.x if horiz else _vs.y), rng.randf_range(40.0, 110.0) * (1.0 if rng.randf() < 0.5 else -1.0), cc])


func _process(delta: float) -> void:
	_update(delta)


## The share of the doors that is open (0 shut … 1 open).
func _open_k() -> float:
	if down:
		return smoothstep(2.0, 3.2, _t) * (1.0 - smoothstep(5.4, 6.4, _t))
	return smoothstep(0.0, 1.0, _t) * (1.0 - smoothstep(3.0, 4.0, _t))


func _update(delta: float) -> void:
	_t += delta
	var c := _hatch.get_center()
	var sc := 1.0
	var dim := 1.0
	var sh_off := Vector2(14, 18)
	var sh_a := 0.5
	var below := false
	if down:
		var a := smoothstep(0.0, 2.0, _t)                     # coming down over the hatch
		var s := smoothstep(3.2, 5.4, _t)                     # sinking into the shaft
		sc = lerpf(1.7, 1.0, a) * lerpf(1.0, 0.55, s)
		sh_off = Vector2(14, 18).lerp(Vector2(90, 120), 1.0 - a) * (1.0 - s)
		sh_a = 0.5 * a * (1.0 - s)
		dim = lerpf(1.0, 0.2, s)
		below = _t > 4.4
		_ship.position = c + Vector2(0, -60.0 * (1.0 - a))
		_ship.modulate.a = smoothstep(0.0, 0.5, _t) * (1.0 - smoothstep(5.2, 5.5, _t))
		if _t >= DOWN_TIME and not _done:
			_done = true
			finished.emit()
	else:
		var r := smoothstep(1.0, 3.0, _t)                     # rising out of the shaft
		var u := smoothstep(4.0, 6.0, _t)                     # climbing away
		sc = lerpf(0.55, 1.0, r) * lerpf(1.0, 1.8, u)
		dim = lerpf(0.2, 1.0, r)
		sh_off = Vector2(14, 18).lerp(Vector2(110, 150), u) * r
		sh_a = 0.5 * r * (1.0 - u)
		below = _t < 1.6
		_ship.position = c + Vector2(0, -90.0 * u * u)
		_ship.modulate.a = 1.0 - smoothstep(5.2, 6.0, _t)
		if _t >= UP_TIME and not _done:
			_done = true
			finished.emit()
	_ship.scale = Vector2.ONE * _ship_s * sc
	_ship.modulate = Color(dim, dim, dim * 1.05, _ship.modulate.a)
	_shadow.scale = _ship.scale
	_shadow.position = _ship.position + sh_off
	_shadow.modulate.a = sh_a
	_shadow.visible = not below
	# once she is below the rim the leaves close over her: draw them above the ship then
	_doors.z_index = 1 if below else -1
	_ship.z_index = 0
	for car in _cars:
		car[2] = fposmod(float(car[2]) + float(car[3]) * delta, _vs.x if int(car[0]) == 0 else _vs.y)
	_city.queue_redraw()
	_doors.queue_redraw()
	_fx.queue_redraw()


func _draw_city() -> void:
	var cv := _city
	# streets, with the lamps along them
	for x in _streets_v:
		cv.draw_rect(Rect2(x - 14.0, 0, 28.0, _vs.y), Color(0.09, 0.095, 0.12))
		cv.draw_rect(Rect2(x - 1.0, 0, 2.0, _vs.y), Color(0.25, 0.24, 0.18, 0.5))
	for y in _streets_h:
		cv.draw_rect(Rect2(0, y - 14.0, _vs.x, 28.0), Color(0.09, 0.095, 0.12))
		cv.draw_rect(Rect2(0, y - 1.0, _vs.x, 2.0), Color(0.25, 0.24, 0.18, 0.5))
	# the street lamps' pools of light
	for x2 in _streets_v:
		for y2 in _streets_h:
			cv.draw_circle(Vector2(x2, y2) + Vector2(14, 14), 12.0, Color(1.0, 0.8, 0.45, 0.12))
			cv.draw_rect(Rect2(Vector2(x2, y2) + Vector2(12, 12), Vector2(4, 4)), Color(1.0, 0.9, 0.6))
	for car in _cars:
		var p := Vector2(float(car[2]), float(car[1])) if int(car[0]) == 0 else Vector2(float(car[1]), float(car[2]))
		cv.draw_circle(p, 5.0, Color(car[4], 0.18))
		cv.draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), car[4])
	# the towers: their shadows, then their roofs with what stands on them
	for rf in _roofs:
		var r: Rect2 = rf[0]
		cv.draw_rect(Rect2(r.position + Vector2(rf[2], rf[2] * 1.2), r.size), Color(0, 0, 0, 0.35))
	for i in _roofs.size():
		var rf2: Array = _roofs[i]
		var r2: Rect2 = rf2[0]
		var col: Color = rf2[1]
		cv.draw_rect(r2, col)
		cv.draw_rect(Rect2(r2.position, Vector2(r2.size.x, 3)), col.lightened(0.25))
		cv.draw_rect(Rect2(r2.position, Vector2(3, r2.size.y)), col.lightened(0.15))
		cv.draw_rect(Rect2(r2.position + Vector2(0, r2.size.y - 3), Vector2(r2.size.x, 3)), col.darkened(0.35))
		match int(rf2[3]):
			0:                                            # air units
				for k in int(r2.size.x / 26.0):
					cv.draw_rect(Rect2(r2.position + Vector2(8 + k * 26, 10), Vector2(16, 12)), col.lightened(0.12))
					cv.draw_circle(r2.position + Vector2(16 + k * 26, 16), 4.0, col.darkened(0.3))
			1:                                            # a roof garden
				cv.draw_rect(r2.grow(-8.0), Color(0.16, 0.3, 0.18))
				for k2 in 5:
					cv.draw_circle(r2.position + Vector2(14 + fposmod(k2 * 37.0, maxf(r2.size.x - 28.0, 1.0)), 14 + fposmod(k2 * 23.0, maxf(r2.size.y - 28.0, 1.0))), 6.0, Color(0.2, 0.42, 0.22))
			2:                                            # a pad for flyers
				var pc := r2.get_center()
				var rr := minf(r2.size.x, r2.size.y) * 0.36
				cv.draw_arc(pc, rr, 0.0, TAU, 32, Color(0.95, 0.8, 0.25, 0.7), 2.0)
				cv.draw_rect(Rect2(pc - Vector2(rr * 0.35, 2), Vector2(rr * 0.7, 4)), Color(0.95, 0.8, 0.25, 0.7))
			3:                                            # a neon edge
				var nc: Color = [Color(0.3, 0.95, 1.0), Color(1.0, 0.3, 0.75), Color(0.75, 0.45, 1.0)][i % 3]
				cv.draw_rect(r2.grow(-2.0), Color(nc, 0.15 + 0.1 * sin(_t * 2.0 + i)), false, 2.0)
			_:                                            # skylights, lit from inside
				for k3 in int(r2.size.x / 22.0):
					cv.draw_rect(Rect2(r2.position + Vector2(8 + k3 * 22, r2.size.y * 0.4), Vector2(12, 8)), Color(1.0, 0.85, 0.55, 0.75))
		# the warning light on the corner – blinking
		if fposmod(_t * 0.8 + i * 0.37, 1.6) < 0.25:
			cv.draw_circle(r2.position + Vector2(r2.size.x - 6, 6), 6.0, Color(1.0, 0.2, 0.15, 0.35))
			cv.draw_rect(Rect2(r2.position + Vector2(r2.size.x - 8, 4), Vector2(4, 4)), Color(1.0, 0.3, 0.25))
	# the hatch: a broad frame with hazard stripes, the shaft below it
	var fr := _hatch.grow(34.0)
	cv.draw_rect(Rect2(fr.position + Vector2(10, 12), fr.size), Color(0, 0, 0, 0.35))
	cv.draw_rect(fr, Color(0.3, 0.31, 0.34))
	cv.draw_rect(fr.grow(-4.0), Color(0.36, 0.37, 0.4))
	var st := 0.0
	while st < fr.size.x + fr.size.y:
		for edge in 2:
			var y0 := fr.position.y + 10.0 if edge == 0 else fr.end.y - 22.0
			var x0 := fr.position.x + 10.0 + st
			if x0 + 10.0 < fr.end.x - 10.0:
				cv.draw_colored_polygon(PackedVector2Array([Vector2(x0, y0), Vector2(x0 + 10, y0), Vector2(x0 + 18, y0 + 12), Vector2(x0 + 8, y0 + 12)]), Color(0.95, 0.78, 0.15))
		st += 20.0
	_draw_shaft(cv)
	# the hatch's lamps: amber while it moves, green when it is open
	var ok := _open_k()
	var lc := Color(0.4, 1.0, 0.55) if ok > 0.98 else Color(1.0, 0.65, 0.2)
	var blink := ok > 0.02 and ok < 0.98 and fposmod(_t * 3.0, 1.0) < 0.5
	for cp in [fr.position + Vector2(10, 10), Vector2(fr.end.x - 10, fr.position.y + 10), fr.end - Vector2(10, 10), Vector2(fr.position.x + 10, fr.end.y - 10)]:
		cv.draw_circle(cp, 14.0, Color(lc, 0.25 if not blink else 0.05))
		cv.draw_circle(cp, 5.0, lc if not blink else lc.darkened(0.6))
	# its number painted beside it
	var font := ThemeDB.fallback_font
	cv.draw_string(font, Vector2(fr.position.x + 18, fr.position.y - 8), "HATCH %02d" % hatch_no, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.95, 0.8, 0.25, 0.85))


## The shaft under the hatch: frames of light running down into the deep, a glow far below.
func _draw_shaft(cv: Node2D) -> void:
	var r := _hatch
	cv.draw_rect(r, Color(0.02, 0.025, 0.035))
	var c := r.get_center()
	for k in 7:
		var d := fposmod(k / 7.0 + _t * 0.12, 1.0)          # 0 at the rim … 1 deep below
		var rr := Rect2(c - r.size * 0.5 * (1.0 - d * 0.8), r.size * (1.0 - d * 0.8))
		cv.draw_rect(rr, Color(0.35, 0.75, 1.0, 0.35 * (1.0 - d)), false, 2.0)
		for corner in [rr.position, Vector2(rr.end.x, rr.position.y), rr.end, Vector2(rr.position.x, rr.end.y)]:
			cv.draw_circle(corner, 3.0, Color(1.0, 0.8, 0.4, 0.8 * (1.0 - d)))
	cv.draw_rect(Rect2(c - r.size * 0.1, r.size * 0.2), Color(0.5, 0.8, 1.0, 0.18))


## The two leaves of the hatch: they slide apart to the sides, under the frame.
func _draw_doors() -> void:
	var k := _open_k()
	var r := _hatch
	var half := r.size.x * 0.5
	var w := half * (1.0 - k)
	if w <= 0.5:
		return
	for side in 2:
		var lr := Rect2(Vector2(r.position.x, r.position.y), Vector2(w, r.size.y)) if side == 0 else Rect2(Vector2(r.end.x - w, r.position.y), Vector2(w, r.size.y))
		_doors.draw_rect(lr, Color(0.4, 0.42, 0.46) if side == 0 else Color(0.37, 0.39, 0.43))
		var y := lr.position.y + 16.0
		while y < lr.end.y - 8.0:
			_doors.draw_rect(Rect2(lr.position.x + 6.0, y, lr.size.x - 12.0, 2.0), Color(0.3, 0.31, 0.35))
			y += 22.0
		var edge_x := lr.end.x - 8.0 if side == 0 else lr.position.x
		_doors.draw_rect(Rect2(edge_x, lr.position.y, 8.0, lr.size.y), Color(0.95, 0.78, 0.15))
		var yy := lr.position.y
		while yy < lr.end.y:
			_doors.draw_rect(Rect2(edge_x, yy, 8.0, 8.0), Color(0.12, 0.12, 0.14))
			yy += 16.0
	if k < 0.02:
		_doors.draw_rect(Rect2(r.get_center().x - 1.0, r.position.y, 2.0, r.size.y), Color(0.12, 0.12, 0.14))


## The ship's engines while she hangs over the hatch.
func _draw_fx() -> void:
	if _shadow == null or not _shadow.visible:
		return
	var p := _ship.position
	var a := _ship.modulate.a
	var gl := _ship.scale.x / _ship_s
	_fx.draw_circle(p + Vector2(0, 8), 70.0 * gl, Color(1.0, 0.75, 0.4, 0.07 * a))
	_fx.draw_circle(p + Vector2(0, 8), 40.0 * gl, Color(1.0, 0.85, 0.55, 0.08 * a))
