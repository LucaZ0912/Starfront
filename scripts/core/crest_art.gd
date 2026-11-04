class_name CrestArt
extends RefCounted
## Coats of arms of the factions (phase 0.5 package 10): small pixel-art shields built from a
## shape mask, a shaded field, a rim and a symbol. Used on the galaxy map, as holo banners next
## to stations, in menus and later in the codex.

const FactionData = preload("res://data/factions.gd")
const W := 34          # incl. 1 px outline margin
const H := 38

static var _cache := {}

const HAND := [
	"...#.#....",
	".#.#.#.#..",
	".#.#.#.#..",
	".#.#.#.#..",
	".#######..",
	".#######.#",
	".########.",
	".#######..",
	"..######..",
	"..#####...",
	"..#####...",
]
const CROWN := [
	"#.......#.......#",
	"##.....###.....##",
	"#.#...#...#...#.#",
	"#..#.#.....#.#..#",
	"#...#.......#...#",
	"#...............#",
	"#################",
	"#...............#",
	"#.#.#.#.#.#.#.#.#",
	"#...............#",
	"#################",
]


static func texture(fid: String) -> Texture2D:
	var key := "crest_" + fid
	if not _cache.has(key):
		_cache[key] = ImageTexture.create_from_image(image(fid))
	return _cache[key]


static func image(fid: String) -> Image:
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	if not FactionData.FACTIONS.has(fid):
		return img
	var cd: Dictionary = FactionData.FACTIONS[fid]["crest"]
	var shape: String = cd["shape"]
	var field: Color = cd["field"]
	var rim: Color = cd["rim"]
	var inside := {}
	for y in H:
		for x in W:
			if _in_shape(shape, x - 1, y - 1):
				inside[Vector2i(x, y)] = true
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for p in inside:
		var edge := false
		var edge2 := false
		for d in dirs:
			if not inside.has(p + d):
				edge = true
			if not inside.has(p + d * 2):
				edge2 = true
		var v := float(p.y) / H
		var u := float(p.x) / W
		var col := field.lightened(0.18 * (1.0 - v)).darkened(0.15 * u)
		if edge:
			col = rim
		elif edge2:
			col = field.darkened(0.45)
		img.set_pixelv(p, col)
	# dark outline around the shield
	for y in H:
		for x in W:
			var q := Vector2i(x, y)
			if inside.has(q):
				continue
			for d in dirs:
				if inside.has(q + d):
					img.set_pixelv(q, Color(0.03, 0.03, 0.05, 0.95))
					break
	_symbol(img, inside, String(cd["symbol_id"]), cd["symbol"])
	return img


## Shield silhouettes (x 0..31, y 0..35).
static func _in_shape(shape: String, x: int, y: int) -> bool:
	if x < 0 or x > 31 or y < 0 or y > 35:
		return false
	var dx := x + 0.5 - 16.0
	var dy := y + 0.5 - 18.0
	var u := dx / 16.0
	var v := (y + 0.5) / 36.0
	match shape:
		"round":
			return dx * dx + dy * dy <= 15.6 * 15.6 and absf(dy) <= 15.6
		"gothic":
			if v < 0.03 + 0.17 * pow(absf(u), 1.4):
				return false
			if absf(u) > 0.94:
				return false
			if v > 0.55:
				return absf(u) <= 0.94 * (1.0 - pow((v - 0.55) / 0.44, 1.6))
			return true
		"hex":
			var R := 17.5
			return absf(dx) <= 0.866 * R and absf(dy) <= R - absf(dx) * 0.577
		"diamond":
			return absf(dx) / 15.6 + absf(dy) / 17.6 <= 1.0
		"jagged":
			var top := 0.03 + 0.07 * absf(fposmod(float(x), 6.0) - 3.0) / 3.0
			if v < top or absf(u) > 0.94:
				return false
			if v > 0.5:
				var w := 0.94 * sqrt(maxf(0.0, 1.0 - pow((v - 0.5) / 0.48, 2.0)))
				# a notch bitten out of the right side
				if dx > 0.0 and absf(dy - 6.0) < 2.5 and dx > w * 16.0 - 4.0:
					return false
				return absf(u) <= w
			return not (dx < -11.0 and absf(dy + 4.0) < 2.0)
		"pennant":
			if absf(dx) > 15.0 or y < 2:
				return false
			if y > 24:
				return absf(dx) >= (y - 24) * 1.35
			return true
		_:
			if absf(u) > 0.94 or v < 0.03:
				return false
			if v > 0.5:
				return absf(u) <= 0.94 * sqrt(maxf(0.0, 1.0 - pow((v - 0.5) / 0.47, 2.0)))
			return true


static func _grid(img: Image, inside: Dictionary, rows: Array, origin: Vector2i, col: Color) -> void:
	var pts: Array = []
	for y in rows.size():
		var r: String = rows[y]
		for x in r.length():
			if r[x] == "#":
				pts.append(origin + Vector2i(x, y))
	_plot(img, inside, pts, col)


## Shadows first, then the symbol itself (so a shadow never covers symbol pixels).
static func _plot(img: Image, inside: Dictionary, pts: Array, col: Color) -> void:
	var set := {}
	for p in pts:
		set[p] = true
	for p in pts:
		var sh: Vector2i = p + Vector2i(1, 1)
		if inside.has(sh) and not set.has(sh):
			img.set_pixelv(sh, img.get_pixelv(sh).darkened(0.45))
	for p in pts:
		if inside.has(p):
			img.set_pixelv(p, col)


static func _line(pts: Array, a: Vector2, b: Vector2, thick: float) -> void:
	var n := int(a.distance_to(b) * 2.0) + 1
	for i in n + 1:
		var c := a.lerp(b, float(i) / n)
		var r := thick * 0.5
		for yy in range(int(floor(c.y - r)), int(ceil(c.y + r)) + 1):
			for xx in range(int(floor(c.x - r)), int(ceil(c.x + r)) + 1):
				if Vector2(xx + 0.5, yy + 0.5).distance_to(c) <= r + 0.25:
					pts.append(Vector2i(xx, yy))


static func _symbol(img: Image, inside: Dictionary, sid: String, col: Color) -> void:
	var pts: Array = []
	var C := Vector2(17.0, 19.0)      # centre incl. margin
	match sid:
		"hand":
			# ring of eight stars around an open hand
			for i in 8:
				var sp := C + Vector2.from_angle(-PI * 0.5 + i * TAU / 8.0) * 11.0
				var ip := Vector2i(int(sp.x), int(sp.y))
				for d in [Vector2i.ZERO, Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					pts.append(ip + d)
			_plot(img, inside, pts, col)
			_grid(img, inside, HAND, Vector2i(12, 14), col)
			return
		"sun_road":
			for yy in range(5, 18):
				for xx in range(9, 26):
					var d := Vector2(xx + 0.5, yy + 0.5).distance_to(Vector2(17.0, 12.0))
					if d <= 2.9:
						pts.append(Vector2i(xx, yy))
			for i in 8:
				var dir := Vector2.from_angle(i * TAU / 8.0)
				_line(pts, Vector2(17.0, 12.0) + dir * 4.8, Vector2(17.0, 12.0) + dir * 6.4, 0.8)
			_line(pts, Vector2(7.0, 19.5), Vector2(27.0, 19.5), 1.0)
			for yy2 in range(21, 33):
				var hw := 1.0 + (yy2 - 21) * 0.62
				for xx2 in range(int(17.0 - hw), int(17.0 + hw) + 1):
					var dash := xx2 == 17 and posmod(yy2, 3) == 0
					if not dash:
						pts.append(Vector2i(xx2, yy2))
		"compass":
			var pivot := Vector2(17.0, 8.0)
			_line(pts, pivot, Vector2(10.0, 30.0), 2.0)
			_line(pts, pivot, Vector2(24.0, 30.0), 2.0)
			for yy3 in range(4, 12):
				for xx3 in range(13, 22):
					var d3 := Vector2(xx3 + 0.5, yy3 + 0.5).distance_to(pivot)
					if d3 <= 2.6 and d3 >= 1.2:
						pts.append(Vector2i(xx3, yy3))
			var prev := Vector2.ZERO
			for i in 17:
				var a := lerpf(0.42, PI - 0.42, float(i) / 16.0)
				var ap := pivot + Vector2(cos(a), sin(a)) * 16.5
				if i > 0:
					_line(pts, prev, ap, 1.1)
				prev = ap
			pts.append(Vector2i(17, 2))
			pts.append(Vector2i(17, 1))
		"crown":
			_grid(img, inside, CROWN, Vector2i(9, 13), col)
			for jx in [9, 17, 25]:
				_plot(img, inside, [Vector2i(jx, 11)], col)
			return
		"broken_ring":
			for yy4 in range(6, 33):
				for xx4 in range(4, 31):
					var off := Vector2(xx4 + 0.5, yy4 + 0.5) - C
					var r := off.length()
					if r < 7.2 or r > 10.8:
						continue
					var ang := off.angle()
					# one wide gap at the top right; the lower half has slipped down-left
					if absf(wrapf(ang + 0.75, -PI, PI)) < 0.42:
						continue
					var p4 := Vector2i(xx4, yy4)
					if absf(wrapf(ang - 2.4, -PI, PI)) < 0.12:
						continue
					if ang > -0.75 and ang < 2.4:
						p4 += Vector2i(1, 2)
					pts.append(p4)
		"blades":
			_line(pts, Vector2(9.0, 7.0), Vector2(25.0, 27.0), 1.6)
			_line(pts, Vector2(25.0, 7.0), Vector2(9.0, 27.0), 1.6)
			_line(pts, Vector2(19.5, 25.5), Vector2(24.5, 21.5), 1.2)
			_line(pts, Vector2(14.5, 25.5), Vector2(9.5, 21.5), 1.2)
			_line(pts, Vector2(25.0, 27.0), Vector2(27.0, 29.5), 1.6)
			_line(pts, Vector2(9.0, 27.0), Vector2(7.0, 29.5), 1.6)
			for d5 in [Vector2i.ZERO, Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				pts.append(Vector2i(17, 4) + d5)
	_plot(img, inside, pts, col)
