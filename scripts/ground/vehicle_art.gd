class_name VehicleArt
extends RefCounted
## 0.7.50.13 (Luz: "the sizes are off"): the big machines of the economy areas, to scale with the people (about 15
## art px a metre; a person is ~27 px tall) – side views, facing east, built once as pixel pictures:
##   haul       a mine's haul truck: tyres taller than a person, the dump body over the cab, a ladder up to it
##   haul_full  the same, loaded with ore
##   excavator  a mining excavator's tracks and house (its boom and bucket are drawn alive)
##   combine    a combine harvester: the header with its reel, the cab, the grain tank, the auger
##   tanker     a tanker truck
##   apc        an eight-wheeled armoured vehicle with its turret
##   boat       a work boat

const OUT := Color(0.08, 0.07, 0.1)
static var _cache := {}


static func texture(kind: String, col: Color = Color(0.95, 0.75, 0.15)) -> Texture2D:
	var key := kind + col.to_html()
	if _cache.has(key):
		return _cache[key]
	var img: Image
	match kind:
		"haul", "haul_full":
			img = _haul(col, kind == "haul_full")
		"excavator":
			img = _excavator(col)
		"combine":
			img = _combine(col)
		"tanker":
			img = _tanker(col)
		"apc":
			img = _apc(col)
		_:
			img = _boat(col)
	_outline(img)
	var t := ImageTexture.create_from_image(img)
	_cache[key] = t
	return t


static func _haul(col: Color, full: bool) -> Image:
	var img := Image.create(150, 92, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var dark := col.darkened(0.35)
	# the frame and the tyres: a pair at the back, one at the front – taller than a person
	_r(img, 10, 52, 130, 8, Color(0.2, 0.2, 0.22))
	for wx in [30, 118]:
		_wheel(img, wx, 66, 24)
	_wheel(img, 54, 66, 24)
	# the dump body: a great tray from the back up over the cab
	var body := PackedVector2Array([Vector2(2, 14), Vector2(116, 6), Vector2(122, 10), Vector2(118, 44), Vector2(12, 48)])
	_poly(img, body, col)
	for rx in range(14, 112, 14):                         # its ribs
		_r(img, rx, 9 + (rx - 14) / 20, 3, 38, dark)
		_r(img, rx, 9 + (rx - 14) / 20, 1, 38, col.lightened(0.2))
	_r(img, 4, 14, 112, 3, col.lightened(0.25))
	_r(img, 12, 44, 106, 4, dark.darkened(0.2))
	_r(img, 112, 4, 14, 6, col.lightened(0.1))           # the canopy over the cab
	if full:
		for k in 40:
			var x := 10 + (k * 37) % 100
			var hh := 4 + (k * 13) % 7
			_r(img, x, 12 - hh / 2, 6, hh, Color(0.5, 0.4, 0.3).lightened(((k * 7) % 5) * 0.03))
	# the cab under the canopy, its deck and rail, the ladder up the front
	_r(img, 116, 14, 26, 26, col.darkened(0.1))
	_r(img, 120, 17, 18, 11, Color(0.35, 0.55, 0.7))
	_r(img, 121, 18, 6, 3, Color(0.75, 0.88, 0.95))
	_r(img, 114, 38, 34, 4, Color(0.3, 0.3, 0.32))       # the deck
	_r(img, 144, 24, 2, 16, Color(0.3, 0.3, 0.32))       # its rail
	_r(img, 116, 24, 30, 1, Color(0.3, 0.3, 0.32))
	for ly in range(42, 60, 4):                          # the ladder
		_r(img, 140 - (ly - 42) / 3, ly, 8, 1, Color(0.85, 0.85, 0.8))
	_r(img, 136, 42, 1, 18, Color(0.6, 0.6, 0.6))
	_r(img, 142, 46, 6, 10, Color(0.2, 0.2, 0.22))       # the grille
	for gy in range(47, 56, 2):
		_r(img, 143, gy, 4, 1, Color(0.45, 0.45, 0.48))
	_r(img, 145, 42, 3, 3, Color(1.0, 0.95, 0.75))       # headlights
	_r(img, 145, 57, 3, 2, Color(1.0, 0.95, 0.75))
	_r(img, 120, 30, 4, 8, Color(1.0, 0.55, 0.15))       # the beacon on the cab
	return img


static func _excavator(col: Color) -> Image:
	var img := Image.create(140, 84, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var dark := col.darkened(0.35)
	# the tracks: links, rollers, sprockets
	_r(img, 4, 62, 132, 20, Color(0.16, 0.16, 0.17))
	for tx in range(6, 134, 6):
		_r(img, tx, 62, 3, 3, Color(0.3, 0.3, 0.32))
		_r(img, tx, 79, 3, 3, Color(0.3, 0.3, 0.32))
	for rx in range(14, 130, 18):
		_circ(img, rx, 72, 6, Color(0.32, 0.32, 0.35))
		_circ(img, rx, 72, 2, Color(0.5, 0.5, 0.52))
	_r(img, 30, 54, 80, 8, Color(0.22, 0.22, 0.24))      # the turntable
	# the house: counterweight at the back (east), engine, the cab at the front-left
	_r(img, 24, 18, 108, 38, col)
	_r(img, 24, 18, 108, 3, col.lightened(0.25))
	_r(img, 112, 22, 22, 32, dark)                       # the counterweight
	_r(img, 112, 22, 22, 2, col.lightened(0.1))
	for vy in range(26, 50, 4):                          # engine louvres
		_r(img, 80, vy, 26, 2, dark)
	_r(img, 22, 4, 34, 32, col.darkened(0.08))           # the cab
	_r(img, 26, 8, 26, 18, Color(0.35, 0.55, 0.7))
	_r(img, 27, 9, 8, 4, Color(0.75, 0.88, 0.95))
	_r(img, 58, 10, 4, 10, Color(0.25, 0.25, 0.27))      # the exhaust
	_r(img, 26, 36, 80, 2, dark)
	_r(img, 90, 12, 2, 6, Color(1.0, 0.55, 0.15))        # the beacon
	return img


static func _combine(col: Color) -> Image:
	var img := Image.create(150, 76, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var dark := col.darkened(0.35)
	_wheel(img, 98, 58, 17)                              # big drive wheels at the front, small ones behind
	_wheel(img, 28, 62, 12)
	_r(img, 16, 18, 104, 38, col)                        # the body
	_r(img, 16, 18, 104, 3, col.lightened(0.25))
	for vx in range(24, 70, 8):
		_r(img, vx, 30, 5, 16, dark)
	_r(img, 30, 4, 50, 16, col.lightened(0.08))          # the grain tank on top
	_r(img, 30, 4, 50, 2, col.lightened(0.3))
	_r(img, 4, 8, 34, 4, Color(0.85, 0.8, 0.3))          # the auger, folded back
	_r(img, 92, 0, 26, 22, col.darkened(0.05))           # the cab
	_r(img, 95, 3, 20, 15, Color(0.35, 0.55, 0.7))
	_r(img, 96, 4, 6, 3, Color(0.75, 0.88, 0.95))
	# the header out in front: its frame, the reel turning (drawn as bats), the cutter bar
	_r(img, 120, 30, 26, 32, Color(0.85, 0.78, 0.25))
	_r(img, 120, 30, 26, 3, Color(0.95, 0.9, 0.5))
	_circ(img, 134, 38, 11, Color(0.75, 0.25, 0.2))
	_circ(img, 134, 38, 8, Color(0, 0, 0, 0))
	for a in 6:
		var ang := a * TAU / 6.0
		_r(img, 134 + int(cos(ang) * 10) - 1, 38 + int(sin(ang) * 10) - 1, 3, 3, Color(0.9, 0.35, 0.25))
	_r(img, 118, 60, 32, 3, Color(0.3, 0.3, 0.32))       # the cutter bar
	_r(img, 112, 22, 3, 3, Color(1.0, 0.55, 0.15))       # the beacon
	return img


static func _tanker(col: Color) -> Image:
	var img := Image.create(140, 54, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for wx in [20, 34, 48, 96, 124]:
		_wheel(img, wx, 44, 9)
	_r(img, 6, 36, 110, 4, Color(0.22, 0.22, 0.24))
	_r(img, 8, 10, 98, 28, Color(0.78, 0.8, 0.8))        # the tank
	_r(img, 8, 12, 98, 4, Color(0.92, 0.94, 0.94))
	_r(img, 8, 32, 98, 4, Color(0.6, 0.62, 0.62))
	for bx in [30, 60, 86]:
		_r(img, bx, 10, 2, 28, Color(0.6, 0.62, 0.62))
	_r(img, 20, 20, 60, 6, col)                          # its band in the company's colour
	_r(img, 112, 12, 26, 28, col)                        # the cab
	_r(img, 120, 15, 15, 10, Color(0.35, 0.55, 0.7))
	_r(img, 134, 30, 4, 3, Color(1.0, 0.95, 0.75))
	return img


static func _apc(col: Color) -> Image:
	var img := Image.create(130, 58, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for wx in [18, 40, 84, 106]:
		_wheel(img, wx, 46, 10)
	var hull := PackedVector2Array([Vector2(4, 26), Vector2(14, 16), Vector2(110, 16), Vector2(126, 30), Vector2(120, 44), Vector2(8, 44)])
	_poly(img, hull, col)
	_r(img, 14, 16, 96, 2, col.lightened(0.2))
	for px in range(20, 110, 18):                        # armour panels
		_r(img, px, 20, 1, 22, col.darkened(0.25))
	_r(img, 44, 4, 40, 14, col.darkened(0.1))            # the turret
	_r(img, 44, 4, 40, 2, col.lightened(0.15))
	_r(img, 84, 9, 40, 4, col.darkened(0.3))             # its gun
	_r(img, 50, 0, 3, 5, Color(0.3, 0.3, 0.3))           # antenna base
	_r(img, 114, 28, 4, 3, Color(1.0, 0.9, 0.6))
	return img


static func _boat(col: Color) -> Image:
	var img := Image.create(120, 46, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var hull := PackedVector2Array([Vector2(2, 26), Vector2(118, 22), Vector2(106, 42), Vector2(10, 42)])
	_poly(img, hull, Color(0.9, 0.9, 0.88))
	_r(img, 4, 26, 112, 3, col)
	_r(img, 10, 38, 96, 4, Color(0.55, 0.2, 0.18))
	_r(img, 30, 6, 40, 20, Color(0.92, 0.92, 0.9))       # the wheelhouse
	_r(img, 34, 10, 32, 7, Color(0.35, 0.55, 0.7))
	_r(img, 46, 0, 2, 7, Color(0.4, 0.4, 0.42))          # its mast
	_r(img, 80, 16, 26, 8, Color(0.45, 0.4, 0.35))       # cargo on deck
	_r(img, 74, 10, 2, 14, Color(0.4, 0.4, 0.42))        # a crane arm
	_r(img, 74, 10, 20, 2, Color(0.4, 0.4, 0.42))
	return img


# ---------------------------------------------------------------- helpers

static func _wheel(img: Image, cx: int, cy: int, r: int) -> void:
	_circ(img, cx, cy, r, Color(0.12, 0.12, 0.13))
	for a in 16:                                         # the tread
		var ang := a * TAU / 16.0
		_r(img, cx + int(cos(ang) * (r - 1)) - 1, cy + int(sin(ang) * (r - 1)) - 1, 2, 2, Color(0.22, 0.22, 0.24))
	_circ(img, cx, cy, int(r * 0.55), Color(0.38, 0.38, 0.4))
	_circ(img, cx, cy, int(r * 0.3), Color(0.55, 0.55, 0.57))
	_r(img, cx - int(r * 0.3), cy - int(r * 0.4), 2, 2, Color(0.7, 0.7, 0.72))


static func _circ(img: Image, cx: int, cy: int, r: int, c: Color) -> void:
	for y in range(-r, r + 1):
		for x in range(-r, r + 1):
			if x * x + y * y <= r * r:
				_p(img, cx + x, cy + y, c)


static func _poly(img: Image, pts: PackedVector2Array, c: Color) -> void:
	var r := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		r = r.expand(p)
	for y in range(int(r.position.y), int(r.end.y) + 1):
		for x in range(int(r.position.x), int(r.end.x) + 1):
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), pts):
				_p(img, x, y, c)


static func _r(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	var rr := Rect2i(x, y, w, h).intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	if rr.size.x > 0 and rr.size.y > 0:
		img.fill_rect(rr, c)


static func _p(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)


static func _outline(img: Image) -> void:
	var src := img.duplicate()
	for y in img.get_height():
		for x in img.get_width():
			if src.get_pixel(x, y).a > 0.0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < img.get_width() and q.y < img.get_height() and src.get_pixel(q.x, q.y).a > 0.5:
					img.set_pixel(x, y, OUT)
					break
