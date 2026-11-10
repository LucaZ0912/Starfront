class_name LanderArt
extends RefCounted
## 0.7.50.15 (Luz): the landing drone every ship carries – a small dropship for four and a vehicle, seen from above,
## nose to the east like the ships: a fuselage with its cockpit canopy at the nose, four portholes (the four seats) on
## its port side, the vehicle bay aft under a roof hatch, four ducted lift fans on stub wings, two thrusters at the
## tail, a dorsal spine with a sensor housing and a mast, nav lights (red to port, green to starboard). On its
## starboard (south) side the boarding ramp – drawn apart, so it can fold down and up again.

const W := 42
const H := 30
const C := Vector2(21, 15)              # its centre (texture px)
const DOOR_X0 := -5.0                   # the side door (centre-relative texture px)
const DOOR_W := 10.0
const EDGE := 8.0                       # the hull's south edge (centre-relative)
const RAMP := 8.5                       # the ramp's length, folded down
const FANS := [Vector2(11.5, 4.5), Vector2(11.5, 25.5), Vector2(28.5, 4.5), Vector2(28.5, 25.5)]

static var _tex: Texture2D


static func texture() -> Texture2D:
	if _tex != null:
		return _tex
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var hull := Color(0.66, 0.69, 0.75)
	var hull_l := Color(0.8, 0.83, 0.88)
	var hull_d := Color(0.47, 0.5, 0.57)
	var dark := Color(0.24, 0.26, 0.31)
	var seam := Color(0.42, 0.44, 0.5)
	var glass := Color(0.25, 0.75, 0.95)
	var glass_h := Color(0.75, 0.97, 1.0)
	var glow := Color(0.35, 0.95, 1.0)
	var heat := Color(1.0, 0.58, 0.22)
	var acc := Color(0.95, 0.6, 0.15)
	# the stub wings the fans sit on (under the fuselage)
	for wx in [9, 26]:
		_rect(img, wx, 4, 6, 22, dark)
		_rect(img, wx, 4, 6, 1, hull_d)
	# the four ducted lift fans
	for f in FANS:
		var fc: Vector2 = f
		for y in H:
			for x in W:
				var d := Vector2(x + 0.5, y + 0.5).distance_to(fc)
				if d <= 3.2:
					var c := hull_d
					if d <= 2.4:
						c = Color(0.1, 0.12, 0.15)
						var ang := atan2(y + 0.5 - fc.y, x + 0.5 - fc.x)
						if int(floor((ang + PI) / (PI / 3.0))) % 2 == 0:
							c = Color(0.16, 0.42, 0.5)                # the fan's blades, lit from below
					if d <= 0.9:
						c = glow
					if d > 2.4 and y + 0.5 < fc.y:
						c = hull                                     # the duct's rim, lit from the north
					img.set_pixel(x, y, c)
	# the fuselage – rounded corners, lit from the north
	for y in range(7, 23):
		for x in range(6, 35):
			var cut := 0
			if y in [7, 22]:
				cut = 2
			elif y in [8, 21]:
				cut = 1
			if x < 6 + cut or x > 34 - cut:
				continue
			img.set_pixel(x, y, hull_l if y <= 9 else (hull_d if y >= 20 else hull))
	# the nose, tapering
	for nx in range(35, 40):
		var half := 7 - (nx - 35) * 1
		half = maxi(half - (1 if nx >= 38 else 0), 2)
		for y in range(15 - half, 15 + half):
			img.set_pixel(nx, y, hull_l if y < 11 else (hull_d if y >= 19 else hull))
	# the cockpit canopy, wrapped round the nose
	for x in range(31, 39):
		var inset := (x - 31) / 2
		for y in range(10 + inset, 20 - inset):
			if img.get_pixel(x, y).a > 0.5:
				img.set_pixel(x, y, glass.lerp(Color(0.1, 0.3, 0.45), float(y - 10) / 12.0))
	_rect(img, 34, 10, 1, 10, dark)                                  # the frame between its panes
	for hp in [Vector2i(32, 11), Vector2i(33, 11), Vector2i(32, 12), Vector2i(36, 12), Vector2i(35, 11)]:
		img.set_pixel(hp.x, hp.y, glass_h)
	# the tail: the engine block and two thrusters
	_rect(img, 3, 9, 4, 12, dark)
	_rect(img, 3, 9, 4, 1, hull_d)
	for ny in [10, 16]:
		_rect(img, 1, ny, 3, 4, Color(0.15, 0.15, 0.18))
		_rect(img, 1, ny + 1, 1, 2, heat)
		_rect(img, 2, ny + 1, 1, 2, heat.darkened(0.35))
	# the vehicle bay aft under its roof hatch
	_frame(img, 7, 10, 7, 10, seam)
	_rect(img, 8, 14, 5, 1, seam)
	for hz in range(8, 13, 2):
		img.set_pixel(hz, 11, Color(0.95, 0.8, 0.2))
	# panel seams
	for sx in [15, 22, 29]:
		for y in range(8, 22):
			if y < 13 or y > 16:
				img.set_pixel(sx, y, seam)
	# the dorsal spine with its sensor housing and mast
	_rect(img, 14, 14, 17, 2, hull_d)
	_rect(img, 14, 14, 17, 1, seam)
	_rect(img, 17, 12, 4, 6, hull_d)
	_rect(img, 17, 12, 4, 1, hull_l)
	img.set_pixel(18, 14, glow)
	img.set_pixel(19, 14, glow.darkened(0.3))
	_rect(img, 26, 12, 1, 3, dark)
	img.set_pixel(26, 11, Color(1.0, 0.3, 0.25))
	# a band in the line's colour just aft of the cockpit
	_rect(img, 28, 8, 2, 14, acc)
	_rect(img, 28, 8, 2, 1, acc.lightened(0.3))
	# four portholes along the port side – the four seats
	for wx2 in [17, 20, 23, 26]:
		img.set_pixel(wx2, 8, glass)
		img.set_pixel(wx2, 9, glass.darkened(0.3))
	# the side door to starboard: its frame, hazard stripes, door lights
	_frame(img, 16, 19, 10, 4, dark)
	for hx in range(16, 26):
		img.set_pixel(hx, 21, Color(0.95, 0.8, 0.2) if (hx / 2) % 2 == 0 else Color(0.14, 0.14, 0.16))
	img.set_pixel(15, 20, Color(0.4, 1.0, 0.55))
	img.set_pixel(26, 20, Color(0.4, 1.0, 0.55))
	# nav lights: red to port, green to starboard, white at the nose
	img.set_pixel(11, 1, Color(1.0, 0.25, 0.2))
	img.set_pixel(11, 28, Color(0.35, 1.0, 0.45))
	img.set_pixel(39, 15, Color(1, 1, 0.9))
	# its outline
	var o := Color(0.06, 0.06, 0.08)
	var src := img.duplicate()
	for y3 in H:
		for x3 in W:
			if src.get_pixel(x3, y3).a > 0.0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x3, y3) + d
				if q.x >= 0 and q.y >= 0 and q.x < W and q.y < H and src.get_pixel(q.x, q.y).a > 0.5:
					img.set_pixel(x3, y3, o)
					break
	_tex = ImageTexture.create_from_image(img)
	return _tex


static func _rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	var r := Rect2i(x, y, w, h).intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	if r.size.x > 0 and r.size.y > 0:
		img.fill_rect(r, c)


static func _frame(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	_rect(img, x, y, w, 1, c)
	_rect(img, x, y + h - 1, w, 1, c)
	_rect(img, x, y, 1, h, c)
	_rect(img, x + w - 1, y, 1, h, c)


## The boarding ramp on the drone's starboard side: open 0 (shut) … 1 (down on the ground). c: the drone's centre on
## screen, sc: screen px per texture px. The door slides up into the hull and shows the lit cabin – two of the seats,
## the vehicle bay's rover behind – the ramp folds down on its struts, its rails lit, hazard stripes at its foot.
static func draw_ramp(ci: CanvasItem, c: Vector2, sc: float, open: float, t: float, a: float = 1.0) -> void:
	if open <= 0.001:
		return
	var o := c + Vector2(DOOR_X0, EDGE) * sc
	var w := DOOR_W * sc
	# the opening: the cabin inside, lit warm
	var slot := 2.6 * minf(open * 2.0, 1.0) * sc
	ci.draw_rect(Rect2(o + Vector2(0, -slot), Vector2(w, slot)), Color(0.07, 0.06, 0.08, a))
	ci.draw_rect(Rect2(o + Vector2(0, -slot), Vector2(w, 0.5 * sc)), Color(1.0, 0.85, 0.55, 0.9 * a))
	if open > 0.5:
		var ia := a * clampf((open - 0.5) * 3.0, 0.0, 1.0)
		for sx in [1.2, 3.4]:                                      # two seat backs
			ci.draw_rect(Rect2(o + Vector2(sx * sc, -slot + 0.8 * sc), Vector2(1.4 * sc, slot - 1.0 * sc)), Color(0.55, 0.3, 0.2, ia))
		ci.draw_rect(Rect2(o + Vector2(6.2 * sc, -slot + 0.9 * sc), Vector2(2.8 * sc, slot - 1.3 * sc)), Color(0.3, 0.33, 0.38, ia))   # the rover's flank
		ci.draw_circle(o + Vector2(7.6 * sc, -0.5 * sc), 0.7 * sc, Color(0.12, 0.12, 0.14, ia))
	# the ramp, folding down
	var L := RAMP * open
	if L < 0.3:
		return
	var top := o + Vector2(0.4 * sc, 0)
	var pw := w - 0.8 * sc
	# its shadow on the ground, its light spilling down it
	ci.draw_rect(Rect2(top + Vector2(0.6 * sc, L * sc), Vector2(pw, 0.8 * sc)), Color(0, 0, 0, 0.3 * a * open))
	ci.draw_rect(Rect2(top, Vector2(pw, L * sc)), Color(0.46, 0.48, 0.53, a))
	var k := 0.0
	while k < L - 0.6:
		ci.draw_rect(Rect2(top + Vector2(0.6 * sc, (k + 0.8) * sc), Vector2(pw - 1.2 * sc, 0.35 * sc)), Color(0.34, 0.36, 0.4, a))
		k += 1.3
	ci.draw_colored_polygon(PackedVector2Array([top + Vector2(1.0 * sc, 0), top + Vector2(pw - 1.0 * sc, 0), top + Vector2(pw - 0.2 * sc, L * sc), top + Vector2(0.2 * sc, L * sc)]),
		Color(1.0, 0.85, 0.55, 0.13 * a * open))
	for side in [0.0, pw - 0.6 * sc]:                               # the rails, their lights running down
		ci.draw_rect(Rect2(top + Vector2(side, 0), Vector2(0.6 * sc, L * sc)), Color(0.26, 0.28, 0.32, a))
		var j := 0
		var y := 1.0
		while y < L - 0.5:
			var on := fposmod(t * 3.0 - j * 0.35, 1.0) < 0.5
			ci.draw_rect(Rect2(top + Vector2(side + 0.15 * sc, y * sc), Vector2(0.3 * sc, 0.3 * sc)), Color(0.35, 0.95, 1.0, a * (1.0 if on else 0.35)))
			y += 1.6
			j += 1
	# hazard stripes at its foot
	if open > 0.85:
		var n := 6
		for s in n:
			ci.draw_rect(Rect2(top + Vector2(pw * s / n, (L - 0.7) * sc), Vector2(pw / n, 0.7 * sc)),
				Color(0.95, 0.8, 0.2, a) if s % 2 == 0 else Color(0.14, 0.14, 0.16, a))
	# the struts it hangs on
	ci.draw_line(o + Vector2(-0.4 * sc, -0.6 * sc), top + Vector2(0.3 * sc, L * 0.55 * sc), Color(0.2, 0.21, 0.24, a), maxf(1.0, 0.45 * sc))
	ci.draw_line(o + Vector2(w + 0.4 * sc, -0.6 * sc), top + Vector2(pw - 0.3 * sc, L * 0.55 * sc), Color(0.2, 0.21, 0.24, a), maxf(1.0, 0.45 * sc))


## The ramp's top and foot (centre-relative texture px) – where the pilot walks in and out.
static func ramp_top() -> Vector2:
	return Vector2(DOOR_X0 + DOOR_W * 0.5, EDGE + 0.5)


static func ramp_foot() -> Vector2:
	return Vector2(DOOR_X0 + DOOR_W * 0.5, EDGE + RAMP + 1.5)
