extends Node2D
## Package 54c (Luz): The Vote – the drone shaft seen from the gallery (mockup_54c_vote_galerie): a great cylinder going
## down through the station's heart – its wall darkening into the depth, the frame's ribs, the windows of its decks in
## rows; the blue beam rising out of the depth; ballot drones spiralling up to the ports, and now and then one passing
## close by the gallery's window; the tally hanging as a holo over the shaft, live. Drawn in the gallery's window (and
## under its glass floor). `event` (the sight's): "surge" – a vote closing, a swarm; "pulse" – the beam flaring.
## No class_name: preload it.

const S := GroundMap.SCALE
var size_art := Vector2(640, 208)
var event := ""
var sight: Dictionary = {}               # the gallery's sight (its event is chosen after the view is built)
var _tex: ImageTexture
var _t := 0.0
var _c := Vector2.ZERO
var _r := Vector2.ZERO


func setup(win_px: Vector2, p_event: String = "") -> void:
	size_art = win_px / S
	event = p_event
	_c = Vector2(size_art.x * 0.5, size_art.y * 0.36)
	_r = Vector2(size_art.x * 0.62, size_art.y * 0.8)
	_paint()


func _process(dt: float) -> void:
	_t += dt
	if not sight.is_empty():
		event = String(sight.get("event", ""))
	queue_redraw()


func _h(x: int, y: int, s: int = 0) -> float:
	var v := sin(float(x) * 12.9898 + float(y) * 78.233 + float(s) * 3.7) * 43758.5453
	return v - floor(v)


func _paint() -> void:
	var W := int(size_art.x)
	var H := int(size_art.y)
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	for y in H:
		for x in W:
			var e := Vector2((x - _c.x) / _r.x, (y - _c.y) / _r.y).length()
			if e > 1.0:
				img.set_pixel(x, y, Color(0.46, 0.5, 0.58))                   # the deck round the shaft's mouth
				continue
			var dk := pow(e, 1.7)
			var c := Color(0.02, 0.03, 0.07).lerp(Color(0.5, 0.56, 0.68), dk)
			var ang := atan2((y - _c.y) / _r.y, (x - _c.x) / _r.x)
			if fposmod(ang * 24.0 / TAU, 1.0) < 0.06:
				c = c.darkened(0.35)                                            # a rib of the frame
			if fposmod(e * 7.0, 1.0) < 0.05:
				c = c.lightened(0.12 * dk)                                      # where one deck meets the next
			img.set_pixel(x, y, c)
	for band in 6:                                                           # the decks' windows, lit
		var e2 := 0.92 - band * 0.14
		var n := int(80 * e2)
		for wi in n:
			var a2 := wi * TAU / n + band * 0.2
			if fposmod(a2 * 24.0 / TAU, 1.0) < 0.12:
				continue
			var q := _c + Vector2(cos(a2) * _r.x * e2, sin(a2) * _r.y * e2)
			var ws := maxi(1, int(4 * e2))
			for yy in ws:
				for xx in ws + 1:
					var px := int(q.x) + xx
					var py := int(q.y) + yy
					if px >= 0 and py >= 0 and px < W and py < H:
						img.set_pixel(px, py, img.get_pixel(px, py).lerp(Color(1.0, 0.9, 0.65), 0.35 + 0.5 * e2))
	_tex = ImageTexture.create_from_image(img)


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(S, S))
	if _tex != null:
		draw_texture(_tex, Vector2.ZERO)
	# the blue beam rising out of the depth
	var pulse := 1.0 + (0.6 * maxf(0.0, sin(_t * 2.0)) if event == "pulse" else 0.15 * sin(_t * 1.3))
	for r in 12:
		draw_circle(_c, (30.0 - r * 2.2) * pulse, Color(0.25, 0.55, 1.0, 0.05 + r * 0.025))
	draw_circle(_c, 7.0 * pulse, Color(0.85, 0.95, 1.0))
	draw_rect(Rect2(_c.x - 2.5, 0, 5, _c.y), Color(0.5, 0.8, 1.0, 0.45))
	# the ballot drones spiralling up out of the depth to the ports
	var streams := 6 if event != "surge" else 12
	for s in streams:
		var a0 := s * TAU / streams
		var n := 14 if event != "surge" else 26
		for d in n:
			var t := fposmod(float(d) / n + _t * 0.06, 1.0)
			var a1 := a0 + t * 2.2
			var q := _c + Vector2(cos(a1) * (14.0 + t * _r.x * 0.95), sin(a1) * (8.0 + t * _r.y * 0.95))
			var sz := 1.0 + t * 1.5
			draw_rect(Rect2(q, Vector2(sz, sz)), Color(0.5, 1.0, 0.7, 0.9) if (s + d) % 5 else Color(1.0, 0.45, 0.45, 0.9))
	# now and then a drone passing close by the window: a capsule with its rotor ring, lights, a streak behind it
	var period := 5.0 if event != "surge" else 2.5
	for k in 2:
		var ph := fposmod(_t + k * period * 0.5, period) / period
		if ph > 0.55:
			continue
		var dr := 1 if (int((_t + k * period * 0.5) / period) + k) % 2 == 0 else -1
		var xs := -30.0 if dr > 0 else size_art.x + 30.0
		var x := xs + dr * ph / 0.55 * (size_art.x + 60.0)
		var y := size_art.y * (0.62 + 0.18 * k) + sin(_t * 3.0 + k) * 2.0
		for st in 14:
			draw_rect(Rect2(x - dr * (16 + st * 3), y + 3, 3, 1), Color(0.5, 0.9, 1.0, 0.4 - st * 0.025))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(S, S))
		_ellipse(Vector2(x, y + 4), Vector2(18, 7), Color(0.55, 0.6, 0.68))
		_ellipse(Vector2(x, y + 4), Vector2(14, 5), Color(0.08, 0.1, 0.14))
		draw_rect(Rect2(x - 10, y - 6, 20, 13), Color(0.85, 0.88, 0.94))
		draw_rect(Rect2(x - 10, y - 6, 20, 3), Color(1, 1, 1))
		draw_rect(Rect2(x - 4, y, 8, 3), Color(0.2, 0.4, 0.8))
		if fposmod(_t * 2.0, 1.0) < 0.5:
			draw_rect(Rect2(x + dr * 12, y - 4, 3, 3), Color(0.4, 1.0, 0.6))
			draw_rect(Rect2(x - dr * 13 - 2, y - 4, 3, 3), Color(1.0, 0.4, 0.4))
	# the tally: a holo over the shaft – the bill on the floor, its yes and no, the systems reporting
	var hw := minf(240.0, size_art.x * 0.44)
	var hr := Rect2(_c.x - hw * 0.5, 6, hw, 54)
	draw_rect(hr, Color(0.08, 0.18, 0.4, 0.85))
	draw_rect(Rect2(hr.position, Vector2(hr.size.x, 2)), Color(0.5, 0.8, 1.0))
	var font := ThemeDB.fallback_font
	var sen = GameState.senate
	var bill := "The Assembly in session"
	var yes := 0.5
	if sen != null and not (sen.bill as Dictionary).is_empty():
		bill = String(preload("res://scripts/core/senate.gd").BILLS.get(String(sen.bill["id"]), {}).get("name", bill))
		yes = float(sen.yes_chance())
	draw_string(font, hr.position + Vector2(8, 16), bill.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, hr.size.x - 16, 10, Color(0.95, 0.97, 1.0))
	var bw := hr.size.x - 16
	draw_rect(Rect2(hr.position + Vector2(8, 22), Vector2(bw * yes, 8)), Color(0.4, 1.0, 0.6))
	draw_rect(Rect2(hr.position + Vector2(8 + bw * yes, 22), Vector2(bw * (1.0 - yes), 8)), Color(1.0, 0.4, 0.4))
	draw_string(font, hr.position + Vector2(8, 44), "YES %d %%" % int(round(yes * 100.0)), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.4, 1.0, 0.6))
	draw_string(font, hr.position + Vector2(hr.size.x - 50, 44), "NO %d %%" % int(round((1.0 - yes) * 100.0)), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1.0, 0.4, 0.4))
	for sy in 6:                                                             # the systems reporting, one after another
		var lit := fposmod(_t * 0.5 + sy * 0.4, 3.0) < 2.0
		draw_rect(Rect2(hr.position + Vector2(60 + sy * 18, 38), Vector2(12, 3)), Color(0.4, 1.0, 0.6) if lit else Color(0.4, 0.5, 0.7))
	draw_rect(hr, Color(0.3, 0.6, 1.0, 0.08 + 0.04 * sin(_t * 2.0)))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _ellipse(c: Vector2, r: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 20:
		var a := i * TAU / 20.0
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	draw_colored_polygon(pts, col)
