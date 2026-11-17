extends RefCounted
## Package 56 (Luz): the portrait of a ship's computer – a humanoid hologram, 48 × 48 like the pilots' portraits:
## a head and shoulders of cyan light, no face but two bright eyes, scan lines, a glitch line, a faint projector glow
## at the bottom. `t` (0–1) shifts the scan lines and the glitch so it can flicker gently.

const SIZE := 48
static var _cache := {}


static func portrait(col: Color = Color(0.4, 0.9, 1.0), t: float = 0.0) -> Texture2D:
	var key := "%s_%.2f" % [col.to_html(), t]
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.01, 0.04, 0.07, 1.0))
	var glitch := 14 + int(t * 29.0) % 30
	for y in SIZE:
		for x in SIZE:
			var a := _body(x, y)
			if a <= 0.0:
				# the projector's glow, rising from below
				var g := clampf(1.0 - (SIZE - y) / 18.0, 0.0, 1.0) * clampf(1.0 - absf(x - 24.0) / 20.0, 0.0, 1.0)
				if g > 0.0:
					img.set_pixel(x, y, Color(0.01, 0.04, 0.07).lerp(col, g * 0.25))
				continue
			var edge := _edge(x, y)
			var c := Color(0.01, 0.04, 0.07).lerp(col, 0.32 + 0.18 * a)
			if edge:
				c = col.lerp(Color.WHITE, 0.35)
			if (y + int(t * 6.0)) % 3 == 0:
				c = c.darkened(0.35)                                 # scan lines
			if y == glitch:
				c = col.lerp(Color.WHITE, 0.5)
			img.set_pixel(clampi(x + (1 if y == glitch else 0), 0, SIZE - 1), y, c)
	# the eyes
	for e in [19, 28]:
		img.set_pixel(e, 19, Color(0.9, 1.0, 1.0))
		img.set_pixel(e + 1, 19, Color(0.9, 1.0, 1.0))
		img.set_pixel(e, 20, col.lerp(Color.WHITE, 0.6))
		img.set_pixel(e + 1, 20, col.lerp(Color.WHITE, 0.6))
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


## How much of the bust covers a pixel: the head, the neck, the shoulders.
static func _body(x: int, y: int) -> float:
	var hx := (x + 0.5 - 24.0) / 9.0
	var hy := (y + 0.5 - 19.0) / 11.0
	if hx * hx + hy * hy <= 1.0:
		return 1.0
	if y >= 28 and y <= 33 and absf(x + 0.5 - 24.0) <= 4.0:
		return 0.8
	if y >= 33:
		var w := 8.0 + (y - 33) * 1.8
		if absf(x + 0.5 - 24.0) <= minf(w, 21.0):
			return 0.9
	return 0.0


static func _edge(x: int, y: int) -> bool:
	if _body(x, y) <= 0.0:
		return false
	for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var q: Vector2i = Vector2i(x, y) + o
		if q.x < 0 or q.y < 0 or q.x >= SIZE or q.y >= SIZE or _body(q.x, q.y) <= 0.0:
			return true
	return false
