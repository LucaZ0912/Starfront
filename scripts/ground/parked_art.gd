extends RefCounted
## 0.7.53.11 (Luz): a ship of the game standing on the ground, plastic – its own outline and paint given volume: a
## height from how far each point lies inside its outline (rounded towards the middle), lit like a solid from the upper
## left with a sheen, panel seams; its side as a wall below its south edge (it stands on its gear), the gear, its shadow.
## `make(hull, faction, sc, lift)` → {tex, off}: the picture and where its top-left lies from the ship's centre (art px).
## No class_name: preload it.

static var _cache := {}


static func _bil(src: Image, q: Vector2) -> Color:
	var x0 := int(floor(q.x - 0.5))
	var y0 := int(floor(q.y - 0.5))
	var fx := q.x - 0.5 - x0
	var fy := q.y - 0.5 - y0
	var acc := Color(0, 0, 0, 0)
	var aw := 0.0
	for dy in 2:
		for dx in 2:
			var sx := x0 + dx
			var sy := y0 + dy
			var w := (fx if dx == 1 else 1.0 - fx) * (fy if dy == 1 else 1.0 - fy)
			var cc := Color(0, 0, 0, 0)
			if sx >= 0 and sy >= 0 and sx < src.get_width() and sy < src.get_height():
				cc = src.get_pixel(sx, sy)
			acc.r += cc.r * cc.a * w
			acc.g += cc.g * cc.a * w
			acc.b += cc.b * cc.a * w
			aw += cc.a * w
	if aw > 0.001:
		return Color(acc.r / aw, acc.g / aw, acc.b / aw, aw)
	return Color(0, 0, 0, 0)


static func make(hull: String, faction: String, sc: float, lift: int) -> Dictionary:
	var key := "%s_%s_%.2f_%d" % [hull, faction, sc, lift]
	if _cache.has(key):
		return _cache[key]
	var src: Image = PixelArt.ship_texture(hull, faction).get_image()
	if src.is_compressed():
		src.decompress()
	var sw := src.get_width()
	var sh := src.get_height()
	var W2 := int(sw * sc) + 2
	var H2 := int(sh * sc) + 2
	var pad := 14
	var img := Image.create(W2 + pad, H2 + lift + pad, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var inside := PackedByteArray()
	inside.resize(W2 * H2)
	var cols: Array = []
	cols.resize(W2 * H2)
	for y in H2:
		for x in W2:
			var q := Vector2(x, y) / sc
			var cb := _bil(src, q)
			inside[y * W2 + x] = 1 if cb.a > 0.5 else 0
			var cn := src.get_pixel(clampi(int(q.x), 0, sw - 1), clampi(int(q.y), 0, sh - 1))
			cols[y * W2 + x] = cn if cn.a > 0.5 else cb
	# the distance to its outline (chamfer, two passes)
	var dist := PackedFloat32Array()
	dist.resize(W2 * H2)
	for i in W2 * H2:
		dist[i] = 0.0 if inside[i] == 0 else 9999.0
	for y in H2:
		for x in W2:
			var i := y * W2 + x
			if dist[i] == 0.0:
				continue
			var best := dist[i]
			if x > 0: best = minf(best, dist[i - 1] + 1.0)
			if y > 0: best = minf(best, dist[i - W2] + 1.0)
			if x > 0 and y > 0: best = minf(best, dist[i - W2 - 1] + 1.414)
			if x < W2 - 1 and y > 0: best = minf(best, dist[i - W2 + 1] + 1.414)
			if x == 0 or y == 0 or x == W2 - 1 or y == H2 - 1: best = minf(best, 1.0)
			dist[i] = best
	for y in range(H2 - 1, -1, -1):
		for x in range(W2 - 1, -1, -1):
			var i := y * W2 + x
			if dist[i] == 0.0:
				continue
			var best := dist[i]
			if x < W2 - 1: best = minf(best, dist[i + 1] + 1.0)
			if y < H2 - 1: best = minf(best, dist[i + W2] + 1.0)
			if x < W2 - 1 and y < H2 - 1: best = minf(best, dist[i + W2 + 1] + 1.414)
			if x > 0 and y < H2 - 1: best = minf(best, dist[i + W2 - 1] + 1.414)
			dist[i] = best
	var RR := 22.0
	var hgt := func(x: int, y: int) -> float:
		if x < 0 or y < 0 or x >= W2 or y >= H2:
			return 0.0
		var d := minf(dist[y * W2 + x], RR) / RR
		return sqrt(maxf(0.0, 1.0 - (1.0 - d) * (1.0 - d))) * RR
	# its shadow on the floor
	for y in H2:
		for x in W2:
			if inside[y * W2 + x] == 1:
				img.set_pixel(x + 12, y + lift + 12, Color(0, 0, 0, 0.45))
	# the gear
	for sp in [Vector2(0.3, 0.3), Vector2(0.3, 0.7), Vector2(0.75, 0.5)]:
		var gx := int(sp.x * W2)
		var gy := int(sp.y * H2)
		img.fill_rect(Rect2i(gx, gy, 4, lift + 4), Color(0.25, 0.25, 0.27))
		img.fill_rect(Rect2i(gx, gy, 1, lift + 4), Color(0.45, 0.45, 0.48))
		img.fill_rect(Rect2i(gx - 3, gy + lift + 2, 10, 4), Color(0.12, 0.12, 0.13))
	# its side below its south edge
	for x in W2:
		var bottom := -1
		for y in range(H2 - 1, -1, -1):
			if inside[y * W2 + x] == 1:
				bottom = y
				break
		if bottom < 0:
			continue
		var base: Color = cols[bottom * W2 + x]
		for k in lift:
			var cc := Color(base.r, base.g, base.b).darkened(0.45 + 0.3 * float(k) / lift)
			if (x / 18) % 2 == 0 and k == lift / 2:
				cc = cc.lightened(0.1)
			img.set_pixel(x, bottom + 1 + k, cc)
	# the top, lit as a solid
	var LV := Vector3(-0.55, -0.65, 0.55).normalized()
	var HV := (LV + Vector3(0, 0, 1)).normalized()
	for y in H2:
		for x in W2:
			if inside[y * W2 + x] == 0:
				continue
			var hx: float = hgt.call(x + 1, y) - hgt.call(x - 1, y)
			var hy: float = hgt.call(x, y + 1) - hgt.call(x, y - 1)
			var n := Vector3(-hx, -hy, 2.0).normalized()
			var lit := clampf(n.dot(LV), 0.0, 1.0)
			var spec := pow(clampf(n.dot(HV), 0.0, 1.0), 24.0)
			var b2: Color = cols[y * W2 + x]
			var col := Color(b2.r, b2.g, b2.b)
			col = col.darkened(0.35 - lit * 0.35).lightened(lit * 0.12) if lit > 0.0 else col.darkened(0.5)
			col = col.lerp(Color(1, 1, 1), spec * 0.5)
			var dd: float = dist[y * W2 + x]
			if fposmod(float(x), 16.0) < 1.0 and dd > 3.0:
				col = col.darkened(0.18)
			if fposmod(float(y + (x / 16) * 5), 11.0) < 1.0 and dd > 3.0:
				col = col.darkened(0.12)
			if dd < 1.5:
				col = col.darkened(0.45)
			img.set_pixel(x, y, col)
	var out := {"tex": ImageTexture.create_from_image(img), "off": -Vector2(W2, H2) * 0.5 - Vector2(0, lift)}
	_cache[key] = out
	return out
