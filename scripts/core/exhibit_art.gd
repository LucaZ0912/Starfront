extends RefCounted
## Package 53e (Luz): the pictures of the Museum's exhibits – each its own, 24 × 24 art px, drawn from its shape and
## its two colours (data/museum.gd `art`). Cached. No class_name: preload it.

const S := 24
const MuseumData = preload("res://data/museum.gd")
const OUT := Color(0.06, 0.05, 0.08)

static var _cache := {}


static func texture(id: String) -> Texture2D:
	if _cache.has(id):
		return _cache[id]
	var t := ImageTexture.create_from_image(image(id))
	_cache[id] = t
	return t


static func image(id: String) -> Image:
	var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var e: Dictionary = MuseumData.get_exhibit(id)
	if e.is_empty():
		return img
	var art: Array = e["art"]
	var a: Color = art[1]
	var b: Color = art[2]
	var v: int = int(art[3]) if art.size() > 3 else 0
	var sd := hash(id)
	match String(art[0]):
		"gem":
			_poly(img, [Vector2(6, 9), Vector2(9, 5), Vector2(15, 5), Vector2(18, 9), Vector2(12, 20)], a)
			_poly(img, [Vector2(6, 9), Vector2(18, 9), Vector2(12, 20)], a.darkened(0.2))
			_line(img, Vector2(9, 5), Vector2(12, 9), b)
			_line(img, Vector2(15, 5), Vector2(12, 9), b)
			_line(img, Vector2(6, 9), Vector2(18, 9), b)
			_r(img, 10, 6, 2, 1, Color(1, 1, 1))
		"crystal":
			for k in 4:
				var x := 6 + k * 3
				var h := 9 + (k * 5 + sd) % 6
				_r(img, x, 20 - h, 3, h, a.darkened(0.08 * k))
				_poly(img, [Vector2(x, 20 - h), Vector2(x + 1.5, 17 - h), Vector2(x + 3, 20 - h)], b)
				_r(img, x, 20 - h, 1, h, b)
			_r(img, 4, 19, 16, 2, Color(0.35, 0.32, 0.3))
		"geode":
			_ellipse(img, 12, 12, 9, 8, a)
			_ellipse(img, 12, 12, 6, 5, a.darkened(0.4))
			for k in 10:
				var ang := k * TAU / 10.0
				_r(img, int(12 + cos(ang) * 4), int(12 + sin(ang) * 3.5), 2, 2, b.lightened(0.1 * (k % 2)))
			_r(img, 11, 11, 2, 2, b.lightened(0.4))
		"fossil", "rock", "glow_rock":
			_ellipse(img, 12, 13, 9, 7, a)
			_ellipse(img, 10, 11, 5, 3, a.lightened(0.12))
			if String(art[0]) == "fossil":
				for t in 24:
					var ang2 := t * 0.45
					var rr := 1.0 + t * 0.22
					_p(img, int(12 + cos(ang2) * rr), int(13 + sin(ang2) * rr * 0.8), b)
			elif String(art[0]) == "glow_rock":
				for k2 in 8:
					_r(img, 6 + (sd + k2 * 7) % 12, 9 + (sd / 3 + k2 * 5) % 8, 2, 1, b)
			else:
				for k3 in 3:
					_line(img, Vector2(5 + k3 * 4, 9 + k3), Vector2(10 + k3 * 4, 17 - k3), b)
		"nugget":
			_ellipse(img, 12, 13, 7, 5, a)
			_ellipse(img, 9, 12, 4, 3, a.lightened(0.15))
			_ellipse(img, 15, 15, 3, 2, a.darkened(0.15))
			_r(img, 9, 11, 2, 1, b)
		"opal":
			_ellipse(img, 12, 12, 8, 6, a)
			for k4 in 6:
				_r(img, 7 + (k4 * 5 + sd) % 10, 9 + (k4 * 3) % 6, 3, 1, [b, Color(0.3, 0.9, 0.6), Color(0.4, 0.6, 1.0)][k4 % 3])
		"helix":
			for t2 in 18:
				var y := 20 - t2
				_r(img, int(12 + sin(t2 * 0.6) * 4) - 1, y, 3, 1, a if t2 % 2 == 0 else b)
		"rose":
			for k5 in 5:
				var ang3 := k5 * TAU / 5.0
				_ellipse(img, 12 + cos(ang3) * 5, 12 + sin(ang3) * 4, 4, 3, a.darkened(0.25))
				_ellipse(img, 12 + cos(ang3) * 4.5, 12 + sin(ang3) * 3.5, 3, 2.2, a.lightened(0.05 * k5))
			_ellipse(img, 12, 12, 3, 2.5, a.darkened(0.15))
			_ellipse(img, 12, 12, 2, 1.5, b)
		"pearl":
			_ellipse(img, 12, 12, 7, 7, a)
			_ellipse(img, 13, 13, 5, 5, b)
			_ellipse(img, 10, 10, 2, 2, Color(1, 1, 1))
		"agate":
			for k6 in 5:
				_ellipse(img, 12, 12, 9 - k6 * 1.6, 7 - k6 * 1.2, a if k6 % 2 == 0 else b)
		"sphere":
			_ellipse(img, 12, 12, 8, 8, a)
			_ellipse(img, 10, 10, 4, 4, b)
			_ellipse(img, 9, 9, 1.5, 1.5, Color(1, 1, 1))
		"mirror":
			_poly(img, [Vector2(5, 14), Vector2(9, 6), Vector2(18, 7), Vector2(20, 15), Vector2(13, 20)], a)
			_poly(img, [Vector2(8, 13), Vector2(10, 8), Vector2(16, 9), Vector2(17, 14), Vector2(12, 17)], b)
			_line(img, Vector2(11, 10), Vector2(14, 12), Color(1, 1, 1))
		"twin":
			_poly(img, [Vector2(6, 18), Vector2(13, 3), Vector2(16, 5), Vector2(9, 20)], a)
			_poly(img, [Vector2(5, 8), Vector2(19, 15), Vector2(17, 18), Vector2(4, 11)], b)
		"record":
			_r(img, 3, 4, 14, 16, b.darkened(0.3))                    # the torn sleeve
			_r(img, 3, 4, 14, 2, b)
			_p(img, 16, 19, Color(0, 0, 0, 0))
			_ellipse(img, 14, 12, 8, 8, a)
			for g in 3:
				_ellipse_outline(img, 14, 12, 6.5 - g * 1.6, Color(0.2, 0.2, 0.22))
			_ellipse(img, 14, 12, 2.5, 2.5, b)
			_p(img, 14, 12, a)
		"book":
			_r(img, 5, 5, 14, 15, a)
			_r(img, 6, 6, 12, 13, a.lightened(0.08))
			_r(img, 17, 6, 2, 14, b)
			_r(img, 5, 5, 2, 15, a.darkened(0.3))
			_r(img, 9, 9, 6, 1, b.darkened(0.2))
		"watch":
			_r(img, 10, 2, 4, 20, Color(0.35, 0.3, 0.25))
			_ellipse(img, 12, 12, 6, 6, a)
			_ellipse(img, 12, 12, 4.5, 4.5, b)
			_line(img, Vector2(12, 12), Vector2(12, 9), Color(0.9, 0.9, 0.9))
			_line(img, Vector2(12, 12), Vector2(14, 13), Color(0.9, 0.9, 0.9))
		"coin":
			_ellipse(img, 12, 12, 8, 8, b)
			_ellipse(img, 12, 12, 7, 7, a)
			_ellipse_outline(img, 12, 12, 5.5, b)
			_ellipse(img, 12, 11, 2, 3, b)
		"packet":
			_r(img, 6, 4, 12, 17, a)
			_r(img, 6, 4, 12, 3, a.darkened(0.2))
			_ellipse(img, 12, 13, 4, 4, b)
			_ellipse(img, 12, 13, 1.5, 1.5, a.lightened(0.3))
		"shard":
			_poly(img, [Vector2(10, 2), Vector2(16, 8), Vector2(13, 21), Vector2(7, 14)], a.lightened(0.1))
			_poly(img, [Vector2(10, 2), Vector2(16, 8), Vector2(12, 12)], a.lightened(0.25))
			_line(img, Vector2(10, 2), Vector2(13, 21), b)
			_line(img, Vector2(15, 8), Vector2(8, 14), b.darkened(0.3))
		"recorder":
			_r(img, 4, 8, 16, 11, a)
			_r(img, 6, 10, 8, 5, Color(0.1, 0.1, 0.12))
			_r(img, 16, 10, 2, 2, b)
			_line(img, Vector2(17, 8), Vector2(20, 2), a.lightened(0.2))
		"flag":
			_r(img, 4, 3, 2, 19, Color(0.5, 0.45, 0.4))
			_r(img, 6, 4, 14, 9, a)
			_ellipse(img, 12, 8, 2.5, 2.5, b)
			_poly(img, [Vector2(16, 13), Vector2(20, 9), Vector2(20, 13)], Color(0, 0, 0, 0))
			_r(img, 17, 11, 2, 1, Color(0.15, 0.1, 0.08))
		"card":
			_r(img, 5, 7, 14, 10, a)
			_r(img, 5, 7, 14, 2, b)
			for k7 in 3:
				_r(img, 7, 11 + k7 * 2, 8, 1, a.darkened(0.3))
		"logbook":
			_r(img, 5, 4, 14, 16, a)
			_r(img, 5, 11, 14, 2, b)
			_r(img, 7, 6, 10, 1, a.lightened(0.2))
		"lens":
			_ellipse(img, 12, 12, 8, 8, a)
			_ellipse(img, 12, 12, 6, 6, b)
			_ellipse(img, 10, 10, 2, 2, b.lightened(0.5))
		"rod":
			_line(img, Vector2(5, 19), Vector2(17, 5), a)
			_line(img, Vector2(6, 19), Vector2(18, 5), a.darkened(0.2))
			_poly(img, [Vector2(17, 2), Vector2(21, 5), Vector2(18, 9), Vector2(15, 6)], b)
		"core":
			_ellipse(img, 12, 12, 6, 6, b)
			_ellipse(img, 11, 11, 3, 3, b.lightened(0.4))
			for k8 in 4:
				var ang4 := k8 * PI * 0.5 + 0.4
				_line(img, Vector2(12, 12) + Vector2(cos(ang4), sin(ang4)) * 9.0, Vector2(12, 12) + Vector2(cos(ang4 + 1.2), sin(ang4 + 1.2)) * 9.0, a)
		"plate":
			_r(img, 4, 5, 16, 14, a)
			_r(img, 4, 5, 16, 1, a.lightened(0.2))
			for k9 in 9:
				_p(img, 6 + (sd + k9 * 5) % 12, 7 + (sd / 7 + k9 * 3) % 10, b)
			_line(img, Vector2(7, 9), Vector2(15, 14), b.darkened(0.3))
		"figurine":
			_ellipse(img, 12, 5, 2.5, 2.5, a)
			_r(img, 10, 7, 5, 8, a)
			_r(img, 8, 8, 2, 5, a.darkened(0.15))
			_r(img, 15, 8, 2, 5, a.darkened(0.15))
			_r(img, 10, 15, 2, 5, a)
			_r(img, 13, 15, 2, 5, a)
			_r(img, 11, 9, 3, 1, b)
			_r(img, 7, 20, 11, 2, a.darkened(0.3))
		"tablet_do":
			# glossy black, rounded at the top like their doors; what is shown, not written
			_ellipse(img, 12, 8, 8, 6, a.lightened(0.12))
			_r(img, 4, 8, 16, 14, a.lightened(0.12))
			_ellipse_outline(img, 12, 8, 7.5, b.darkened(0.35))
			_line(img, Vector2(5, 3), Vector2(5, 20), Color(0.35, 0.3, 0.45))
			match v:
				0:   # the pantheon: figures in a ring, each with its sign
					for k13 in 6:
						var ang8 := k13 * TAU / 6.0 - PI * 0.5
						var fp := Vector2(12, 13) + Vector2(cos(ang8) * 6, sin(ang8) * 5)
						_p(img, int(fp.x), int(fp.y) - 1, b.lightened(0.3))
						_r(img, int(fp.x), int(fp.y), 1, 2, b)
					_p(img, 12, 13, b.lightened(0.5))
				1:   # the bound: rows of the same figure, a chain through them
					for rw2 in 2:
						for cl2 in 4:
							_p(img, 7 + cl2 * 3, 8 + rw2 * 7, b.lightened(0.3))
							_r(img, 7 + cl2 * 3, 9 + rw2 * 7, 1, 3, b)
						_r(img, 6, 11 + rw2 * 7, 12, 1, Color(0.55, 0.5, 0.6))
				_:   # the veil: a ring of darkness round the stars, figures kneeling towards it
					_ellipse(img, 12, 10, 5, 4, b.darkened(0.2))
					_ellipse(img, 12, 10, 3.5, 2.5, Color(0.02, 0.01, 0.04))
					for st2 in 4:
						_p(img, 6 + st2 * 4, 5 + (st2 % 2) * 2, Color(0.9, 0.85, 1.0))
					for kn in 3:
						_r(img, 8 + kn * 3, 18, 2, 1, b)
						_p(img, 8 + kn * 3, 17, b.lightened(0.3))
		"tablet_pr":
			_r(img, 4, 2, 16, 20, a)
			_r(img, 4, 2, 16, 2, a.lightened(0.2))
			match v:
				0:
					for gx in 3:
						for gy in 3:
							_r(img, 6 + gx * 5, 6 + gy * 5, 3, 3, b)
				1:
					for k10 in 5:
						_ellipse(img, 7 + k10 * 2.5, 9 + (k10 % 2) * 6, 1.5, 1.5, b)
					_r(img, 6, 17, 12, 1, b)
				2:
					_ellipse_outline(img, 12, 12, 5.5, b)
					for k11 in 6:
						var ang5 := k11 * TAU / 6.0
						_p(img, int(12 + cos(ang5) * 5.5), int(12 + sin(ang5) * 5.5), b.lightened(0.4))
				3:
					for rw in 3:
						for cl in 4:
							_r(img, 6 + cl * 3, 6 + rw * 5, 2, 3, b)
				_:   # the last layer: strata, the top one broken off short
					for sl in 4:
						_r(img, 6, 17 - sl * 3, 12 if sl < 3 else 5, 2, b.darkened(0.15 * sl))
					_line(img, Vector2(11, 6), Vector2(13, 8), b.lightened(0.3))
			_p(img, 5, 3, Color(0.75, 0.45, 0.25))
		"coil":
			for t3 in 30:
				var ang6 := t3 * 0.5
				var rr2 := 1.0 + t3 * 0.27
				_r(img, int(12 + cos(ang6) * rr2), int(12 + sin(ang6) * rr2), 2, 2, a if t3 % 3 else b)
		"mask":
			_ellipse(img, 12, 12, 10, 8, b.darkened(0.45))
			_ellipse(img, 12, 12, 9, 7, a.lightened(0.1))
			_ellipse(img, 9, 8, 4, 2, a.lightened(0.25))
			_line(img, Vector2(5, 11), Vector2(10, 12), b)
			_line(img, Vector2(14, 12), Vector2(19, 11), b)
			_r(img, 11, 15, 2, 4, a.lightened(0.15))
		"collar":
			_ellipse_outline(img, 12, 12, 8, a.lightened(0.2))
			_ellipse_outline(img, 12, 12, 7, a)
			_ellipse_outline(img, 12, 12, 6, a)
			for k12 in 4:
				var ang7 := k12 * PI * 0.5
				_r(img, int(12 + cos(ang7) * 7) - 1, int(12 + sin(ang7) * 7) - 1, 2, 2, b)
		"idol":
			_poly(img, [Vector2(12, 2), Vector2(18, 10), Vector2(16, 21), Vector2(8, 21), Vector2(6, 10)], a.lightened(0.12))
			_line(img, Vector2(12, 2), Vector2(6, 10), b.darkened(0.2))
			_line(img, Vector2(12, 2), Vector2(18, 10), b.darkened(0.2))
			_line(img, Vector2(9, 9), Vector2(15, 9), b)
			_ellipse(img, 12, 13, 1.5, 1.5, b)
			_r(img, 7, 20, 10, 2, a.lightened(0.15))
	_outline(img)
	return img


static func _p(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < S and y < S:
		img.set_pixel(x, y, c)


static func _r(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			_p(img, xx, yy, c)


static func _ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for yy in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for xx in range(int(cx - rx) - 1, int(cx + rx) + 2):
			var dx := (xx + 0.5 - cx) / rx
			var dy := (yy + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				_p(img, xx, yy, c)


static func _ellipse_outline(img: Image, cx: float, cy: float, r: float, c: Color) -> void:
	for k in 64:
		var a := k * TAU / 64.0
		_p(img, int(cx + cos(a) * r), int(cy + sin(a) * r), c)


static func _line(img: Image, a: Vector2, b: Vector2, c: Color) -> void:
	var n := int(maxf(absf(b.x - a.x), absf(b.y - a.y))) + 1
	for i in n + 1:
		var q := a.lerp(b, float(i) / n)
		_p(img, int(q.x), int(q.y), c)


static func _poly(img: Image, pts: Array, c: Color) -> void:
	var pv := PackedVector2Array(pts)
	for yy in S:
		for xx in S:
			if Geometry2D.is_point_in_polygon(Vector2(xx + 0.5, yy + 0.5), pv):
				_p(img, xx, yy, c)


## A dark outline round everything drawn – so it reads on any background.
static func _outline(img: Image) -> void:
	var src := img.duplicate() as Image
	for y in S:
		for x in S:
			if src.get_pixel(x, y).a > 0.0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < S and q.y < S and src.get_pixel(q.x, q.y).a > 0.0:
					img.set_pixel(x, y, OUT)
					break
