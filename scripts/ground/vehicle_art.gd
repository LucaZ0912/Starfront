class_name VehicleArt
extends RefCounted
## 0.7.50.13 (Luz: "the sizes are off"): the big machines of the economy areas, to scale with the people (about 15
## art px a metre; a person is ~27 px tall) – side views, facing east, built once as pixel pictures.
## 0.7.50.14 (Luz: "they look very 21st century – make them sci-fi"): no rubber tyres any more – armoured track pods
## with glowing seams, anti-grav pads, hover skirts and skids; chamfered hulls with panel lines and hazard chevrons,
## canopies with a glowing visor band, sensor masts, heat vents glowing orange, status lights:
##   haul       an ore hauler on two armoured track pods, its hopper over the canopy, a ladder up
##   haul_full  the same, loaded with ore
##   excavator  a mining platform on anti-grav pads (its arm and cutter claw are drawn alive)
##   combine    a harvester glider: a hover body, the intake rotor, a cutter bar of light
##   tanker     a hover tanker on its skids
##   apc        a hover tank with a twin-barrelled turret and its energy coil
##   boat       a hydrofoil work boat with its jets

const OUT := Color(0.08, 0.07, 0.1)
const GLOW := Color(0.35, 0.95, 1.0)
const HEAT := Color(1.0, 0.55, 0.2)
static var _cache := {}

## Which machines float (EconLife bobs them and lights the ground below).
const HOVER := ["excavator", "combine", "tanker", "apc", "boat"]


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
	var steel := Color(0.32, 0.34, 0.38)
	# two armoured track pods: rounded, plated, glowing seams between the plates
	for pod in [[6, 70], [80, 64]]:
		var px: int = pod[0]
		var w: int = pod[1]
		_rounded(img, px, 56, w, 34, 10, Color(0.16, 0.17, 0.2))
		_rounded(img, px + 3, 58, w - 6, 26, 8, steel)
		for sx in range(px + 8, px + w - 6, 9):
			_r(img, sx, 59, 1, 24, GLOW)                        # the glowing seams
			_r(img, sx + 1, 59, 1, 24, steel.darkened(0.3))
		_r(img, px + 6, 60, w - 12, 2, steel.lightened(0.25))
		for rx in range(px + 4, px + w - 4, 4):                 # the tread below
			_r(img, rx, 86, 2, 3, Color(0.25, 0.25, 0.28))
		_circ(img, px + 12, 72, 5, Color(0.22, 0.23, 0.26))
		_circ(img, px + 12, 72, 2, GLOW)
		_circ(img, px + w - 12, 72, 5, Color(0.22, 0.23, 0.26))
		_circ(img, px + w - 12, 72, 2, GLOW)
	_r(img, 12, 50, 128, 8, Color(0.2, 0.21, 0.24))            # the chassis spine
	for vx in range(30, 120, 10):
		_r(img, vx, 52, 6, 2, HEAT)                             # heat vents
	# the hopper: a chamfered, hexagonal bin reaching forward over the canopy
	var bin := PackedVector2Array([Vector2(4, 20), Vector2(14, 8), Vector2(120, 6), Vector2(128, 14), Vector2(120, 46), Vector2(14, 48)])
	_poly(img, bin, col)
	for k in 7:                                                 # panel lines, armour plates
		var px2 := 18 + k * 15
		_r(img, px2, 10, 1, 36, dark)
		_r(img, px2 + 1, 10, 1, 36, col.lightened(0.15))
	_r(img, 14, 9, 106, 2, col.lightened(0.3))
	_r(img, 14, 44, 106, 3, dark.darkened(0.2))
	for ch in 5:                                                # hazard chevrons on its side
		var cx := 26 + ch * 18
		for t in 5:
			_r(img, cx + t, 30 + t, 3, 1, Color(0.12, 0.12, 0.12))
			_r(img, cx + t, 38 - t, 3, 1, Color(0.12, 0.12, 0.12))
	_r(img, 20, 26, 90, 1, GLOW.darkened(0.2))                  # a light line along it
	if full:
		for k2 in 44:
			var x := 16 + (k2 * 37) % 100
			var hh := 4 + (k2 * 13) % 8
			_r(img, x, 9 - hh / 2, 6, hh, Color(0.5, 0.4, 0.3).lightened(((k2 * 7) % 5) * 0.03))
			if k2 % 9 == 0:
				_r(img, x + 2, 8 - hh / 2, 2, 2, Color(0.55, 0.85, 1.0))    # crystals glinting in the ore
	# the canopy: a smooth dome under the hopper's lip, its visor band glowing
	_ellipse_px(img, 132, 34, 15, 14, col.darkened(0.12))
	_ellipse_px(img, 133, 32, 11, 9, Color(0.12, 0.2, 0.28))
	_r(img, 124, 30, 20, 3, GLOW)
	_r(img, 126, 28, 6, 1, Color(0.85, 1.0, 1.0))
	_r(img, 116, 46, 32, 4, Color(0.25, 0.26, 0.3))            # the deck
	for ly in range(50, 66, 4):                                 # the ladder up
		_r(img, 138, ly, 8, 1, Color(0.75, 0.78, 0.82))
	_r(img, 137, 50, 1, 16, Color(0.55, 0.58, 0.62))
	_r(img, 120, 0, 2, 8, Color(0.4, 0.42, 0.46))               # its sensor mast
	_r(img, 118, 0, 6, 2, Color(1.0, 0.3, 0.25))
	_r(img, 146, 40, 3, 5, Color(1.0, 0.95, 0.8))               # the light bar
	return img


static func _excavator(col: Color) -> Image:
	var img := Image.create(140, 84, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var dark := col.darkened(0.35)
	# three anti-grav pads under the platform, glowing beneath
	for pxp in [16, 60, 104]:
		_rounded(img, pxp, 64, 26, 12, 5, Color(0.22, 0.23, 0.26))
		_r(img, pxp + 3, 74, 20, 3, GLOW)
		_r(img, pxp + 6, 77, 14, 2, GLOW.darkened(0.3))
		_r(img, pxp + 4, 66, 18, 2, Color(0.4, 0.42, 0.46))
	_rounded(img, 8, 52, 124, 14, 6, Color(0.25, 0.26, 0.3))   # the platform
	_r(img, 12, 54, 116, 2, Color(0.42, 0.44, 0.48))
	for hz in range(14, 126, 12):
		_r(img, hz, 60, 6, 3, Color(0.95, 0.78, 0.15))
	# the house: chamfered, panelled, a reactor glowing behind its vents
	var house := PackedVector2Array([Vector2(24, 52), Vector2(28, 22), Vector2(40, 14), Vector2(132, 14), Vector2(136, 22), Vector2(134, 52)])
	_poly(img, house, col)
	for k in 6:
		_r(img, 46 + k * 14, 16, 1, 34, dark)
	_r(img, 40, 15, 92, 2, col.lightened(0.28))
	_rounded(img, 96, 24, 32, 18, 4, Color(0.15, 0.15, 0.18))    # the reactor housing
	for rv in 5:
		_r(img, 100 + rv * 6, 27, 3, 12, HEAT)
	_r(img, 98, 40, 28, 1, GLOW)
	# the canopy at the front
	_ellipse_px(img, 38, 30, 14, 13, col.darkened(0.1))
	_ellipse_px(img, 37, 28, 10, 8, Color(0.12, 0.2, 0.28))
	_r(img, 28, 27, 18, 3, GLOW)
	_r(img, 30, 25, 5, 1, Color(0.85, 1.0, 1.0))
	_r(img, 70, 4, 2, 10, Color(0.4, 0.42, 0.46))               # a sensor mast and its light
	_r(img, 68, 2, 6, 2, Color(1.0, 0.55, 0.15))
	return img


static func _combine(col: Color) -> Image:
	var img := Image.create(150, 76, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var dark := col.darkened(0.35)
	# a hover body: skirts glowing below
	_rounded(img, 10, 52, 110, 12, 5, Color(0.2, 0.22, 0.24))
	for gx in range(14, 116, 6):
		_r(img, gx, 63, 4, 3, GLOW)
	var body := PackedVector2Array([Vector2(10, 52), Vector2(14, 26), Vector2(30, 16), Vector2(110, 16), Vector2(120, 28), Vector2(118, 52)])
	_poly(img, body, col)
	for k in 6:
		_r(img, 32 + k * 13, 18, 1, 32, dark)
	_r(img, 30, 17, 80, 2, col.lightened(0.28))
	_r(img, 22, 34, 70, 6, Color(0.15, 0.18, 0.2))             # the crop bay, its level glowing
	_r(img, 24, 36, 44, 2, Color(0.75, 0.9, 0.35))
	_rounded(img, 34, 2, 46, 15, 5, col.lightened(0.08))        # the grain pod on top
	_r(img, 40, 6, 34, 1, GLOW)
	_ellipse_px(img, 104, 18, 14, 12, col.darkened(0.08))       # the canopy
	_ellipse_px(img, 105, 16, 10, 7, Color(0.12, 0.2, 0.28))
	_r(img, 96, 15, 18, 3, GLOW)
	# the intake: a rotor drum and a cutter bar of light
	_r(img, 120, 30, 26, 30, Color(0.28, 0.3, 0.34))
	_r(img, 120, 30, 26, 2, Color(0.45, 0.48, 0.52))
	_circ(img, 133, 42, 10, Color(0.18, 0.2, 0.22))
	for a in 8:
		var ang := a * TAU / 8.0
		_r(img, 133 + int(cos(ang) * 8) - 1, 42 + int(sin(ang) * 8) - 1, 3, 3, GLOW.darkened(0.15))
	_circ(img, 133, 42, 3, GLOW)
	_r(img, 116, 60, 34, 2, Color(1.0, 0.4, 0.3))               # the cutter bar
	_r(img, 116, 62, 34, 1, Color(1.0, 0.8, 0.6))
	_r(img, 110, 8, 3, 3, Color(1.0, 0.55, 0.15))
	return img


static func _tanker(col: Color) -> Image:
	var img := Image.create(140, 54, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for sk in [[8, 56], [76, 58]]:                              # its hover skids
		_rounded(img, sk[0], 40, sk[1], 8, 4, Color(0.22, 0.23, 0.26))
		_r(img, sk[0] + 4, 47, sk[1] - 8, 3, GLOW)
	_r(img, 8, 36, 112, 4, Color(0.25, 0.26, 0.3))
	_rounded(img, 8, 8, 100, 30, 13, Color(0.78, 0.8, 0.82))    # the tank: a capsule
	_r(img, 14, 11, 88, 3, Color(0.92, 0.94, 0.95))
	for bx in [30, 56, 82]:                                     # its ring bands with ports
		_r(img, bx, 8, 3, 30, Color(0.55, 0.58, 0.6))
		_r(img, bx, 20, 3, 4, GLOW)
	_r(img, 18, 26, 70, 3, col)
	var cab := PackedVector2Array([Vector2(110, 38), Vector2(110, 14), Vector2(126, 10), Vector2(138, 22), Vector2(138, 38)])
	_poly(img, cab, col)
	_r(img, 118, 16, 16, 6, Color(0.12, 0.2, 0.28))
	_r(img, 118, 18, 16, 2, GLOW)
	_r(img, 135, 30, 3, 3, Color(1.0, 0.95, 0.8))
	return img


static func _apc(col: Color) -> Image:
	var img := Image.create(130, 58, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_rounded(img, 6, 42, 118, 8, 4, Color(0.2, 0.21, 0.23))     # the hover skirt
	for gx in range(10, 120, 5):
		_r(img, gx, 49, 3, 3, GLOW)
	var hull := PackedVector2Array([Vector2(4, 40), Vector2(10, 22), Vector2(30, 16), Vector2(104, 16), Vector2(126, 30), Vector2(120, 44), Vector2(8, 44)])
	_poly(img, hull, col)
	_r(img, 30, 17, 74, 2, col.lightened(0.2))
	for px in range(22, 112, 15):
		_r(img, px, 20, 1, 22, col.darkened(0.25))
	_r(img, 108, 30, 14, 2, Color(1.0, 0.3, 0.25))              # a sensor slit
	var tur := PackedVector2Array([Vector2(40, 16), Vector2(46, 4), Vector2(84, 4), Vector2(90, 16)])
	_poly(img, tur, col.darkened(0.1))
	_r(img, 86, 7, 40, 3, col.darkened(0.3))                    # twin barrels
	_r(img, 86, 12, 36, 2, col.darkened(0.3))
	for cl in range(92, 120, 6):                                # the energy coil round them
		_r(img, cl, 6, 2, 9, GLOW.darkened(0.2))
	_r(img, 52, 0, 2, 5, Color(0.3, 0.3, 0.3))
	_r(img, 60, 8, 14, 3, GLOW)
	return img


static func _boat(col: Color) -> Image:
	var img := Image.create(120, 46, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var hull := PackedVector2Array([Vector2(2, 24), Vector2(118, 18), Vector2(110, 34), Vector2(10, 34)])
	_poly(img, hull, Color(0.88, 0.9, 0.92))
	_r(img, 6, 24, 108, 2, col)
	_r(img, 10, 32, 96, 2, GLOW)
	for f in [20, 86]:                                          # its hydrofoils
		_r(img, f, 34, 3, 8, Color(0.4, 0.42, 0.46))
		_r(img, f - 6, 42, 16, 2, Color(0.4, 0.42, 0.46))
	_ellipse_px(img, 52, 16, 20, 10, Color(0.9, 0.92, 0.94))    # the cabin dome
	_ellipse_px(img, 54, 14, 14, 6, Color(0.12, 0.2, 0.28))
	_r(img, 42, 13, 24, 2, GLOW)
	_r(img, 4, 26, 6, 6, Color(0.25, 0.26, 0.3))                # the jets at the stern
	_r(img, 2, 28, 3, 2, HEAT)
	_r(img, 80, 14, 26, 6, Color(0.42, 0.44, 0.48))             # cargo pods
	_r(img, 84, 16, 18, 1, GLOW.darkened(0.2))
	return img


# ---------------------------------------------------------------- helpers

static func _rounded(img: Image, x: int, y: int, w: int, h: int, r: int, c: Color) -> void:
	_r(img, x + r, y, w - r * 2, h, c)
	_r(img, x, y + r, w, h - r * 2, c)
	_circ(img, x + r, y + r, r, c)
	_circ(img, x + w - r - 1, y + r, r, c)
	_circ(img, x + r, y + h - r - 1, r, c)
	_circ(img, x + w - r - 1, y + h - r - 1, r, c)


static func _ellipse_px(img: Image, cx: int, cy: int, rx: int, ry: int, c: Color) -> void:
	for y in range(-ry, ry + 1):
		for x in range(-rx, rx + 1):
			if float(x * x) / float(rx * rx) + float(y * y) / float(ry * ry) <= 1.0:
				_p(img, cx + x, cy + y, c)


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
