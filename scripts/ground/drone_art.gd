class_name DroneArt
extends RefCounted
## Package 52.6 (Luz, 11 Nov 2026): the ground combat drones as pixel pictures at the figures' fineness
## (ChibiArt.CHAR_SCALE screen px a pixel, ~22 px a metre) – a small quadcopter about 0.6 m across, seen from above at
## the ground's slant: a body, four arms with their rotors (drawn spinning by whoever draws the drone), a light.
##   laser    – Axiom white and cyan, a small emitter under the nose
##   kinetic  – Hadrian gunmetal and amber, a short barrel and a drum
##   kamikaze – olive with yellow-black warning stripes, a warhead, a red light
## `art(kind)` → {tex, w, h, rotors (the rotor centres, px of the picture), muzzle}.

const OUT := Color(0.04, 0.04, 0.06)
static var _cache := {}


static func art(kind: String) -> Dictionary:
	if _cache.has(kind):
		return _cache[kind]
	var w := 15
	var h := 11
	var img := Image.create(w + 2, h + 2, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var body: Color
	var trim: Color
	var light: Color
	match kind:
		"laser":
			body = Color(0.9, 0.92, 0.95)
			trim = Color(0.3, 0.85, 1.0)
			light = Color(0.5, 1.0, 1.0)
		"kinetic":
			body = Color(0.36, 0.38, 0.42)
			trim = Color(1.0, 0.72, 0.25)
			light = Color(1.0, 0.8, 0.35)
		_:
			body = Color(0.42, 0.46, 0.32)
			trim = Color(1.0, 0.82, 0.15)
			light = Color(1.0, 0.25, 0.2)
	var arm := body.darkened(0.35)
	# the arms, corner to corner
	for i in 5:
		_p(img, 2 + i, 2 + int(i * 0.6), arm)
		_p(img, 12 - i, 2 + int(i * 0.6), arm)
		_p(img, 2 + i, 8 - int(i * 0.6), arm)
		_p(img, 12 - i, 8 - int(i * 0.6), arm)
	# the rotor hubs
	for c in [Vector2i(2, 2), Vector2i(12, 2), Vector2i(2, 8), Vector2i(12, 8)]:
		_r(img, c.x - 1, c.y - 1, 3, 2, Color(0.2, 0.2, 0.22))
		_p(img, c.x, c.y - 1, Color(0.55, 0.55, 0.58))
	# the body: a top lit from above, a darker front face
	_r(img, 5, 3, 5, 4, body)
	_r(img, 5, 3, 5, 1, body.lightened(0.3))
	_r(img, 5, 7, 5, 2, body.darkened(0.3))
	match kind:
		"laser":
			_r(img, 6, 5, 3, 1, trim)                         # the power line
			_r(img, 7, 9, 1, 2, Color(0.62, 0.66, 0.72))      # the emitter under the nose
			_p(img, 7, 10, light)
		"kinetic":
			_r(img, 6, 4, 3, 2, body.darkened(0.2))           # the drum
			_p(img, 7, 4, trim)
			_r(img, 7, 9, 1, 2, Color(0.2, 0.2, 0.22))        # the barrel
			_p(img, 5, 7, trim)
			_p(img, 9, 7, trim)
		_:
			for k in 5:                                       # warning stripes across the top
				_p(img, 5 + k, 4, trim if k % 2 == 0 else Color(0.1, 0.1, 0.1))
			_r(img, 6, 8, 3, 2, Color(0.55, 0.3, 0.2))        # the warhead
			_p(img, 7, 9, Color(0.85, 0.5, 0.3))
	_p(img, 7, 3, light)                                      # the light on top
	_outline(img)
	var out := {"tex": ImageTexture.create_from_image(img), "w": img.get_width(), "h": img.get_height(),
		"rotors": [Vector2(3, 3), Vector2(13, 3), Vector2(3, 9), Vector2(13, 9)], "muzzle": Vector2(8, 12), "light": Vector2(8, 4)}
	_cache[kind] = out
	return out


static func _r(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in range(y + 1, y + h + 1):
		for xx in range(x + 1, x + w + 1):
			if xx >= 0 and yy >= 0 and xx < img.get_width() and yy < img.get_height():
				img.set_pixel(xx, yy, c)


static func _p(img: Image, x: int, y: int, c: Color) -> void:
	_r(img, x, y, 1, 1, c)


static func _outline(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var src := img.duplicate()
	for y in h:
		for x in w:
			if src.get_pixel(x, y).a > 0.1:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < w and q.y < h and src.get_pixel(q.x, q.y).a > 0.1:
					img.set_pixel(x, y, OUT)
					break


## Draws a drone on a canvas item at `at` (screen px, its centre), hovering `hover` px above its shadow, rotors
## spinning (t: seconds), its light blinking; 0.7.52.12 (Luz): turned to `heading` (the direction it flies or aims –
## its nose, the bottom of the picture, points there).
static func draw(ci: CanvasItem, kind: String, at: Vector2, hover: float, t: float, sc: float = 2.0, heading: float = PI * 0.5) -> void:
	var a := art(kind)
	var sz := Vector2(float(a["w"]), float(a["h"])) * sc
	# the shadow on the ground
	ci.draw_set_transform(at + Vector2(0, hover), 0.0, Vector2(1.0, 0.45))
	ci.draw_circle(Vector2.ZERO, sz.x * 0.4, Color(0, 0, 0, 0.3))
	# the drone itself, turned about its centre
	var rot := heading - PI * 0.5
	ci.draw_set_transform(at, rot, Vector2.ONE)
	ci.draw_texture_rect(a["tex"], Rect2(-sz * 0.5, sz), false)
	# the rotors: a spinning blur over each hub
	for r in a["rotors"]:
		var rc: Vector2 = -sz * 0.5 + (r as Vector2) * sc
		ci.draw_circle(rc, 3.2 * sc, Color(0.8, 0.85, 0.9, 0.18))
		var ang := t * 40.0 + rc.x
		ci.draw_line(rc + Vector2.from_angle(ang) * 3.2 * sc, rc - Vector2.from_angle(ang) * 3.2 * sc, Color(0.85, 0.9, 0.95, 0.55), 1.5)
	if fposmod(t * 2.0, 1.0) < 0.5:
		ci.draw_circle(-sz * 0.5 + (a["light"] as Vector2) * sc, 1.6 * sc * 0.5 + 1.0, Color(a["tex"].get_image().get_pixel(8, 4), 0.9))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## 0.7.52.12 (Luz): the drone switched off on the pilot's back, its underside against the back: from behind (dir 1)
## its top flat on the back, rotors still; from the side (dir 2/3) its edge sticking out behind; from the front hidden.
static func draw_docked(ci: CanvasItem, kind: String, back: Vector2, dir: int, sc: float = 2.0) -> void:
	var a := art(kind)
	var sz := Vector2(float(a["w"]), float(a["h"])) * sc * 0.85
	match dir:
		1:
			ci.draw_texture_rect(a["tex"], Rect2(back - sz * 0.5, sz), false, Color(0.82, 0.82, 0.84))
		2, 3:
			var sx := 1.0 if dir == 2 else -1.0                 # behind: to the right when facing left
			var img: Image = a["tex"].get_image()
			var body := img.get_pixel(8, 6)
			var edge := Rect2(back + Vector2(sx * 8.0 * sc - 1.5 * sc, -sz.y * 0.5), Vector2(3.0 * sc, sz.y))
			ci.draw_rect(edge.grow(1.0), Color(0.04, 0.04, 0.06))
			ci.draw_rect(edge, body.darkened(0.15))
			ci.draw_rect(Rect2(edge.position, Vector2(1.0 * sc, sz.y)), body.lightened(0.2))
			for yy in [edge.position.y + 1.0 * sc, edge.end.y - 2.0 * sc]:
				ci.draw_rect(Rect2(Vector2(edge.position.x + sx * 2.0 * sc, yy), Vector2(2.0 * sc, 1.0 * sc)), Color(0.2, 0.2, 0.22))   # the folded arms
