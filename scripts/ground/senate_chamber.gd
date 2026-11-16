extends Node2D
## Package 54c (Luz): the plenary chamber of the Senate, seen slanting from the gallery high on its south wall
## (mockup_54c_senat_galerie) – the far wall upright with the great screen, the presidium before it, a hearing at the
## witness table, the hemicycle's rows coming nearer and bigger towards you, full of senators. The screen changes its
## picture every few seconds with a flash: the witness, the bill on the floor with its polls, figures, the emblem.
## Drawn in the gallery's window. No class_name: preload it.

const S := GroundMap.SCALE
var size_art := Vector2(576, 208)
var _tex: ImageTexture
var _t := 0.0
var _img: Image
var _screen := Rect2()


func setup(win_px: Vector2) -> void:
	size_art = win_px / S
	_paint()


func _process(dt: float) -> void:
	_t += dt
	queue_redraw()


func _h(x: int, y: int, s: int = 0) -> float:
	var v := sin(float(x) * 12.9898 + float(y) * 78.233 + float(s) * 3.7) * 43758.5453
	return v - floor(v)


func _R(x: int, y: int, w: int, hh: int, c: Color) -> void:
	var r := Rect2i(x, y, w, hh).intersection(Rect2i(0, 0, _img.get_width(), _img.get_height()))
	if r.size.x <= 0 or r.size.y <= 0:
		return
	if c.a >= 0.999:
		_img.fill_rect(r, c)
	else:
		for yy in range(r.position.y, r.end.y):
			for xx in range(r.position.x, r.end.x):
				_img.set_pixel(xx, yy, _img.get_pixel(xx, yy).lerp(Color(c.r, c.g, c.b), c.a))


func _P(x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < _img.get_width() and y < _img.get_height():
		_img.set_pixel(x, y, c)


func _circ(cx: float, cy: float, r: float, c: Color) -> void:
	for y in range(int(cy - r) - 1, int(cy + r) + 2):
		for x in range(int(cx - r) - 1, int(cx + r) + 2):
			if Vector2(x + 0.5 - cx, y + 0.5 - cy).length() <= r:
				_P(x, y, c)


func _paint() -> void:
	var W := int(size_art.x)
	var H := int(size_art.y)
	_img = Image.create(W, H, false, Image.FORMAT_RGBA8)
	var cx := W / 2
	var wall_h := int(H * 0.44)
	# the far wall: white stone in panels, pilasters, the Assembly's banners
	for y in wall_h:
		for x in W:
			var c := Color(0.86, 0.87, 0.88).lerp(Color(0.78, 0.79, 0.81), _h(x / 24, 1, 995))
			if x % 24 == 23:
				c = Color(0.62, 0.63, 0.66)
			_P(x, y, c)
	_R(0, 0, W, 2, Color(0.95, 0.96, 0.97))
	for pl in [20, 80, W - 80, W - 20]:
		_R(pl - 6, 6, 12, wall_h - 10, Color(0.85, 0.84, 0.8))
		_R(pl - 6, 6, 3, wall_h - 10, Color(0.95, 0.94, 0.9))
	for fl in [40, 60, W - 60, W - 40]:
		_R(fl, 8, 10, 40, Color(0.2, 0.4, 0.8))
		_R(fl, 22, 10, 5, Color(0.95, 0.95, 0.98))
	# the great screen's frame (its picture is drawn live)
	_screen = Rect2(cx - 147, 8, 294, 70)
	_R(int(_screen.position.x), int(_screen.position.y), int(_screen.size.x), int(_screen.size.y), Color(0.03, 0.04, 0.08))
	# the presidium from the front: a long bench of dark wood, the officers behind it
	var py := wall_h
	_R(cx - 157, py, 314, 6, Color(0.82, 0.8, 0.76))
	_R(cx - 137, py - 8, 274, 14, Color(0.45, 0.3, 0.18))
	_R(cx - 137, py - 8, 274, 2, Color(0.62, 0.44, 0.27))
	for po in 7:
		var px := cx - 117 + po * 38
		_circ(px, py - 12, 3.5, Color(0.75, 0.6, 0.5))
		_R(px - 4, py - 9, 8, 3, [Color(0.2, 0.25, 0.4), Color(0.3, 0.3, 0.32), Color(0.5, 0.2, 0.2)][po % 3])
	# the floor, the hearing's table, the witness and her counsel from behind
	for y2 in range(py + 6, H):
		for x2 in W:
			_P(x2, y2, Color(0.15, 0.22, 0.4).lerp(Color(0.19, 0.28, 0.48), _h(x2 / 2, y2 / 2, 991)))
	_R(cx - 31, py + 20, 62, 10, Color(0.45, 0.3, 0.18))
	_R(cx - 31, py + 20, 62, 2, Color(0.62, 0.44, 0.27))
	for wv in [cx - 15, cx + 15]:
		_circ(wv, py + 32, 3.5, Color(0.35, 0.25, 0.2) if wv < cx else Color(0.2, 0.2, 0.22))
		_R(wv - 4, py + 34, 8, 6, Color(0.85, 0.75, 0.25) if wv < cx else Color(0.25, 0.25, 0.3))
	# the hemicycle: rows squashed by the slant, wider and deeper the nearer they come; senators behind the desks
	var cen := Vector2(cx, py + 12)
	for row in 6:
		var rx := 90.0 + row * 46.0
		var ry := 26.0 + row * 18.0
		var thick := 2 + row / 2
		for a10 in range(0, 1800):
			var a := deg_to_rad(5.0 + a10 * 0.095)
			if a > deg_to_rad(175.0):
				break
			var ad := rad_to_deg(a)
			if absf(ad - 55.0) < 2.0 or absf(ad - 90.0) < 1.6 or absf(ad - 125.0) < 2.0:
				continue
			var q := cen + Vector2(cos(a) * rx, sin(a) * ry)
			for t in thick:
				_P(int(q.x), int(q.y) + t, Color(0.65, 0.46, 0.28) if t == 0 else Color(0.45, 0.31, 0.19))
			_P(int(q.x), int(q.y) + thick, Color(0.25, 0.32, 0.55))
		var n := 14 + row * 5
		for s in n:
			var a2 := deg_to_rad(8.0 + s * (164.0 / n))
			if _h(s, row, 997) > 0.8:
				continue
			var sp := cen + Vector2(cos(a2) * (rx + 4), sin(a2) * (ry + 3))
			var hr := 1.4 + row * 0.35
			var suit: Color = [Color(0.22, 0.24, 0.3), Color(0.45, 0.18, 0.18), Color(0.18, 0.28, 0.48), Color(0.32, 0.28, 0.24)][int(_h(s, row, 993) * 4)]
			_circ(sp.x, sp.y + hr * 1.6, hr * 1.5, suit)
			_circ(sp.x, sp.y, hr, [Color(0.3, 0.2, 0.15), Color(0.75, 0.6, 0.5), Color(0.15, 0.12, 0.1), Color(0.85, 0.8, 0.7)][int(_h(s, row, 998) * 4)])
	# the shadow under the gallery's edge
	for y3 in range(H - 10, H):
		_R(0, y3, W, 1, Color(0, 0, 0, float(y3 - (H - 10)) / 10.0 * 0.5))
	_tex = ImageTexture.create_from_image(_img)


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(S, S))
	if _tex != null:
		draw_texture(_tex, Vector2.ZERO)
	# the screen: a picture every 5 s, a flash between them
	var r := _screen.grow(-4)
	var slide := int(_t / 5.0) % 4
	draw_rect(r, Color(0.08, 0.14, 0.26))
	var font := ThemeDB.fallback_font
	var sen = GameState.senate
	var bill_name := "The Assembly in session"
	var yes := 0.5
	if sen != null and not (sen.bill as Dictionary).is_empty():
		bill_name = String(preload("res://scripts/core/senate.gd").BILLS.get(String(sen.bill["id"]), {}).get("name", bill_name))
		yes = float(sen.yes_chance())
	match slide:
		0:                                                     # the witness speaking
			draw_rect(Rect2(r.position + Vector2(6, 4), Vector2(54, r.size.y - 8)), Color(0.22, 0.26, 0.34))
			draw_circle(r.position + Vector2(33, 26), 11.0, Color(0.78, 0.62, 0.5))
			draw_rect(Rect2(r.position + Vector2(21, 40), Vector2(24, r.size.y - 44)), Color(0.85, 0.75, 0.25))
			draw_string(font, r.position + Vector2(72, 20), "HEARING", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.6, 0.75, 0.95))
			draw_string(font, r.position + Vector2(72, 36), "Witness for the committee", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.9, 0.93, 1.0))
			draw_rect(Rect2(r.position + Vector2(72, 44), Vector2(120 + sin(_t * 3.0) * 20.0, 3)), Color(0.4, 0.8, 1.0))      # her voice
		1:                                                     # the bill and its polls
			draw_string(font, r.position + Vector2(8, 18), bill_name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 16, 12, Color(0.95, 0.95, 1.0))
			draw_rect(Rect2(r.position + Vector2(8, 34), Vector2((r.size.x - 16) * yes, 10)), Color(0.4, 1.0, 0.6))
			draw_rect(Rect2(r.position + Vector2(8 + (r.size.x - 16) * yes, 34), Vector2((r.size.x - 16) * (1.0 - yes), 10)), Color(1.0, 0.4, 0.4))
			draw_string(font, r.position + Vector2(8, 58), "YES %d %%" % int(round(yes * 100.0)), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.4, 1.0, 0.6))
			draw_string(font, r.position + Vector2(r.size.x - 64, 58), "NO %d %%" % int(round((1.0 - yes) * 100.0)), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.4, 0.4))
		2:                                                     # figures
			for bar in 8:
				var bh := 8.0 + _h(bar, int(_t / 5.0), 996) * (r.size.y - 18.0)
				draw_rect(Rect2(r.position.x + 12 + bar * 34, r.end.y - 6 - bh, 22, bh), Color(0.4, 0.8, 1.0) if bar % 2 == 0 else Color(1.0, 0.75, 0.3))
		3:                                                     # the Assembly's emblem
			var c := r.get_center()
			draw_circle(c, 24.0, Color(0.2, 0.4, 0.8))
			draw_circle(c, 17.0, Color(0.95, 0.95, 0.98))
			draw_circle(c, 10.0, Color(0.2, 0.4, 0.8))
			for k in 8:
				var a := k * TAU / 8.0
				draw_rect(Rect2(c + Vector2(cos(a), sin(a)) * 21.0 - Vector2(1, 1), Vector2(2, 2)), Color(0.85, 0.7, 0.35))
	var since := fposmod(_t, 5.0)
	if since < 0.18:
		draw_rect(r, Color(1, 1, 1, 0.6 * (1.0 - since / 0.18)))            # the flash between pictures
	draw_rect(r, Color(0.3, 0.55, 1.0, 0.08))
	# now and then a senator's desk light goes on – the votes coming in
	for k2 in 16:
		if sin(_t * 0.7 + k2 * 2.3) > 0.85:
			var a3 := deg_to_rad(10.0 + _h(k2, 3, 999) * 160.0)
			var row := int(_h(k2, 4, 999) * 6)
			var q := Vector2(size_art.x / 2, size_art.y * 0.44 + 12) + Vector2(cos(a3) * (90.0 + row * 46.0), sin(a3) * (26.0 + row * 18.0)) + Vector2(0, -3)
			draw_rect(Rect2(q, Vector2(2, 2)), Color(0.4, 1.0, 0.6) if k2 % 3 else Color(1.0, 0.4, 0.4))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
