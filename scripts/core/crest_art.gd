class_name CrestArt
extends RefCounted
## Coats of arms of the factions (phase 0.5 package 10): small pixel-art shields built from a
## shape mask, a shaded field, a rim and a symbol. Used on the galaxy map, as holo banners next
## to stations, in menus and later in the codex.

const FactionData = preload("res://data/factions.gd")
const MakerData = preload("res://data/manufacturers.gd")
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
	if not FactionData.FACTIONS.has(fid):
		var empty := Image.create(W, H, false, Image.FORMAT_RGBA8)
		empty.fill(Color(0, 0, 0, 0))
		return empty
	return image_of(FactionData.FACTIONS[fid]["crest"])


## Crest of a ship manufacturer (package 24, data/manufacturers.gd).
static func maker_texture(mid: String) -> Texture2D:
	var key := "maker_" + mid
	if not _cache.has(key):
		_cache[key] = ImageTexture.create_from_image(image_of(MakerData.MAKERS[mid]["crest"]) if MakerData.MAKERS.has(mid) else image("-"))
	return _cache[key]


## Builds a crest from its description (shape, field, rim, symbol, symbol_id, optional pattern).
static func image_of(cd: Dictionary) -> Image:
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
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
		if String(cd.get("pattern", "")) == "hazard" and p.y >= H - 11:
			# warning stripes along the foot (KHI)
			col = Color(0.1, 0.1, 0.11) if posmod(p.x + p.y, 6) < 3 else Color(0.98, 0.78, 0.1)
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
		"plate":
			# heavy industrial plate with cut corners
			if absf(dx) > 15.5 or absf(dy) > 17.5:
				return false
			return absf(dx) + absf(dy) <= 29.0
		"oval":
			return (dx * dx) / (15.0 * 15.0) + (dy * dy) / (17.6 * 17.6) <= 1.0
		"octagon":
			if absf(dx) > 15.5 or absf(dy) > 17.5:
				return false
			return absf(dx) + absf(dy) <= 25.0
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


static func _ring(pts: Array, c: Vector2, r_in: float, r_out: float) -> void:
	for yy in range(int(c.y - r_out) - 1, int(c.y + r_out) + 2):
		for xx in range(int(c.x - r_out) - 1, int(c.x + r_out) + 2):
			var d := Vector2(xx + 0.5, yy + 0.5).distance_to(c)
			if d >= r_in and d <= r_out:
				pts.append(Vector2i(xx, yy))


static func _disc(pts: Array, c: Vector2, r: float) -> void:
	_ring(pts, c, -1.0, r)


static func _symbol(img: Image, inside: Dictionary, sid: String, col: Color) -> void:
	var pts: Array = []
	var C := Vector2(17.0, 19.0)      # centre incl. margin
	match sid:
		# ---- package 24: manufacturers
		"globe":
			# Earth (blue disc, darker meridians), an orbit in front and Luna
			var gc := Vector2(15.5, 20.0)
			_disc(pts, gc, 8.6)
			_plot(img, inside, pts, col)
			pts = []
			var dark := col.darkened(0.55)
			_line(pts, gc + Vector2(0, -8.4), gc + Vector2(0, 8.4), 0.7)
			_line(pts, gc + Vector2(-8.4, 0), gc + Vector2(8.4, 0), 0.7)
			for k in 2:
				var sx := 4.2 if k == 0 else -4.2
				var prev := Vector2.ZERO
				for i in 13:
					var a := -PI * 0.5 + i * PI / 12.0
					var mp := gc + Vector2(cos(a) * sx, sin(a) * 8.4)
					if i > 0:
						_line(pts, prev, mp, 0.7)
					prev = mp
			_plot(img, inside, pts, dark)
			pts = []
			var prev2 := Vector2.ZERO
			for i2 in 33:
				var b := i2 * TAU / 32.0
				var op := gc + Vector2(cos(b) * 13.5, sin(b) * 4.0).rotated(-0.3)
				var behind := sin(b) < 0.0 and Vector2(op - gc).length() < 9.2
				if i2 > 0 and not behind:
					_line(pts, prev2, op, 0.9)
				prev2 = op
			_plot(img, inside, pts, col.lightened(0.5))
			pts = []
			_disc(pts, gc + Vector2(9.0, -10.0), 2.2)
			_plot(img, inside, pts, Color(0.88, 0.9, 0.92))
			return
		"mountain_pick":
			# a mountain (Kanayama) above the hazard stripes, crossed by a pickaxe
			for yy in range(8, 24):
				var hw := (yy - 8) * 0.75
				for xx in range(int(17.0 - hw), int(17.0 + hw) + 1):
					pts.append(Vector2i(xx, yy))
			_plot(img, inside, pts, col)
			pts = []
			var snow := Color(0.98, 0.78, 0.1).lightened(0.35)
			for yy2 in range(8, 12):
				var hw2 := (yy2 - 8) * 0.75
				for xx2 in range(int(17.0 - hw2), int(17.0 + hw2) + 1):
					pts.append(Vector2i(xx2, yy2))
			_plot(img, inside, pts, snow)
			pts = []
			_line(pts, Vector2(7.0, 25.0), Vector2(26.0, 6.0), 1.6)
			_line(pts, Vector2(21.0, 3.5), Vector2(29.0, 10.0), 1.4)
			_plot(img, inside, pts, Color(0.55, 0.55, 0.58))
			return
		"star_a":
			# an elegant A beneath a small four-pointed star
			_line(pts, Vector2(17.0, 13.0), Vector2(9.5, 31.0), 1.6)
			_line(pts, Vector2(17.0, 13.0), Vector2(24.5, 31.0), 1.6)
			_line(pts, Vector2(11.8, 25.0), Vector2(22.2, 25.0), 1.1)
			_line(pts, Vector2(8.0, 31.0), Vector2(11.5, 31.0), 1.0)
			_line(pts, Vector2(22.5, 31.0), Vector2(26.0, 31.0), 1.0)
			var sc := Vector2(17.0, 7.0)
			for r4 in 4:
				var dir4 := Vector2.from_angle(r4 * PI * 0.5)
				for t in 5:
					var w4 := 1.4 * (1.0 - t / 5.0)
					var c4 := sc + dir4 * (t * 0.9)
					_disc(pts, c4, w4)
		"rampart":
			# a fortified wall with merlons and a gate – Hadrian's wall
			for yy3 in range(14, 30):
				for xx3 in range(6, 29):
					var gate := absf(xx3 + 0.5 - 17.0) < 3.0 and yy3 > 21
					if not gate:
						pts.append(Vector2i(xx3, yy3))
			for m in 5:
				var mx := 6 + m * 5
				for yy4 in range(10, 14):
					for xx4 in range(mx, mx + 3):
						pts.append(Vector2i(xx4, yy4))
			_plot(img, inside, pts, col)
			pts = []
			for k in 4:
				_line(pts, Vector2(6.0, 17.5 + k * 3.0), Vector2(28.5, 17.5 + k * 3.0), 0.6)
			_plot(img, inside, pts, col.darkened(0.45))
			return
		"rings":
			# two interlocked rings (concord) with three drones
			_ring(pts, C + Vector2(-4.0, 1.0), 5.2, 6.6)
			_ring(pts, C + Vector2(4.0, 1.0), 5.2, 6.6)
			for i2 in 3:
				var dp := C + Vector2.from_angle(-PI * 0.5 + (i2 - 1) * 0.75) * 13.0
				for d in [Vector2i.ZERO, Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					pts.append(Vector2i(int(dp.x), int(dp.y)) + d)
		"anvil_flame":
			# an anvil (face, horn, waist, foot) with a flame above
			for xx5 in range(10, 26):
				for yy5 in range(18, 21):
					pts.append(Vector2i(xx5, yy5))
			for hx in range(4, 10):
				var th := 1 + int((hx - 4) / 3.0)
				for hy in range(18, 18 + th + 1):
					pts.append(Vector2i(hx, hy))
			for xx6 in range(12, 24):
				pts.append(Vector2i(xx6, 21))
			for yy7 in range(22, 27):
				for xx7 in range(14, 21):
					pts.append(Vector2i(xx7, yy7))
			for yy8 in range(27, 30):
				var w8 := 4 + (yy8 - 27) * 2
				for xx8 in range(17 - w8, 18 + w8):
					pts.append(Vector2i(xx8, yy8))
			_plot(img, inside, pts, col)
			pts = []
			for yy9 in range(4, 17):
				var t9 := float(yy9 - 4) / 12.0
				var hw9 := 3.6 * sin(t9 * PI * 0.92) * (0.35 + 0.65 * t9) + 0.4
				var cx9 := 17.5 + sin(t9 * 4.5) * 1.0
				for xx9 in range(int(cx9 - hw9), int(cx9 + hw9) + 1):
					pts.append(Vector2i(xx9, yy9))
			_plot(img, inside, pts, Color(1.0, 0.55, 0.15))
			pts = []
			for yy10 in range(9, 16):
				var t10 := float(yy10 - 9) / 6.0
				var hw10 := 1.6 * sin(t10 * PI * 0.9) + 0.2
				for xx10 in range(int(17.5 - hw10), int(17.5 + hw10) + 1):
					pts.append(Vector2i(xx10, yy10))
			_plot(img, inside, pts, col.lightened(0.4))
			return
		"delta_orbit":
			# a delta with a singularity, crossed by an orbit
			_line(pts, Vector2(17.0, 6.0), Vector2(6.5, 28.0), 1.2)
			_line(pts, Vector2(17.0, 6.0), Vector2(27.5, 28.0), 1.2)
			_line(pts, Vector2(6.5, 28.0), Vector2(27.5, 28.0), 1.2)
			_disc(pts, Vector2(17.0, 20.0), 2.2)
			var prev3 := Vector2.ZERO
			for j3 in 37:
				var b3 := j3 * TAU / 36.0
				var op3 := Vector2(17.0, 20.0) + Vector2(cos(b3) * 13.5, sin(b3) * 3.4).rotated(-0.3)
				if j3 > 0:
					_line(pts, prev3, op3, 0.8)
				prev3 = op3
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
