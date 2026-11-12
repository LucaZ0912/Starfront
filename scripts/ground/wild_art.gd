extends RefCounted
## 53f-2 (Luz): the painter of the wild – the pieces the jungle, the coast and the ice are made of, painted pixel by
## pixel into an image (the ground map's, or an object's): leaves and whole crowns of many leaves, ferns, flowers,
## rocks lit from above, rock faces in strata, palms, fallen trunks, floes of pack ice, cracks, ice blocks, the
## crashed landing drone. Everything at the ground's real scale (about 15 art px a metre). After Luz' approved
## mockups `mockup_53f2_*` (the scenes there, made into a map by scripts/ground/wild_gen.gd).
## Use: `var p := WildArt.new(img)` then its methods. No class_name: preload it.

const LanderArtW = preload("res://scripts/ground/lander_art.gd")
const SELF := "res://scripts/ground/wild_art.gd"

var img: Image
var IW := 0
var IH := 0


func _init(p_img: Image) -> void:
	img = p_img
	IW = img.get_width()
	IH = img.get_height()


static func h(x: int, y: int, s: int = 0) -> float:
	var v := sin(float(x) * 12.9898 + float(y) * 78.233 + float(s) * 3.7) * 43758.5453
	return v - floor(v)


func R(x: int, y: int, w: int, hh: int, c: Color) -> void:
	var r := Rect2i(x, y, w, hh).intersection(Rect2i(0, 0, IW, IH))
	if r.size.x <= 0 or r.size.y <= 0:
		return
	if c.a >= 0.999:
		img.fill_rect(r, c)
	else:
		for yy in range(r.position.y, r.end.y):
			for xx in range(r.position.x, r.end.x):
				var o := img.get_pixel(xx, yy)
				img.set_pixel(xx, yy, Color(o.r, o.g, o.b, maxf(o.a, c.a)).lerp(Color(c.r, c.g, c.b, maxf(o.a, c.a)), c.a))


func P(x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= IW or y >= IH:
		return
	if c.a >= 0.999:
		img.set_pixel(x, y, c)
	else:
		var o := img.get_pixel(x, y)
		img.set_pixel(x, y, Color(o.r, o.g, o.b, maxf(o.a, c.a)).lerp(Color(c.r, c.g, c.b, maxf(o.a, c.a)), c.a))


func circ(cx: float, cy: float, r: float, c: Color, ry: float = -1.0) -> void:
	if ry < 0:
		ry = r
	for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for x in range(int(cx - r) - 1, int(cx + r) + 2):
			var dx := (x + 0.5 - cx) / r
			var dy := (y + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				P(x, y, c)


func noise_fill(x0: int, y0: int, w: int, hh: int, a: Color, b: Color, sd: int, grain: int = 2) -> void:
	for yy in range(y0, y0 + hh):
		for xx in range(x0, x0 + w):
			var v := h(xx / grain, yy / grain, sd) * 0.6 + h(xx, yy, sd + 7) * 0.4
			P(xx, yy, a.lerp(b, v))


## A ground of noise tiled over a whole area quickly: a 64 px patch made once, copied across.
func tile_ground(a: Color, b: Color, sd: int, grain: int = 2) -> void:
	var pt := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var pp = load(SELF).new(pt)
	pp.noise_fill(0, 0, 64, 64, a, b, sd, grain)
	for y in range(0, IH, 64):
		for x in range(0, IW, 64):
			img.blit_rect(pt, Rect2i(0, 0, 64, 64), Vector2i(x, y))


# ------------------------------------------------------------------ plants

## A single leaf: a pointed oval along `ang`, a lighter rib.
func leaf(x: float, y: float, ang: float, ln: float, c: Color) -> void:
	var nrm := Vector2(-sin(ang), cos(ang))
	var dv := Vector2(cos(ang), sin(ang))
	for t in int(ln):
		var k := float(t) / ln
		var wdt := sin(k * PI) * ln * 0.28
		var q := Vector2(x, y) + dv * t
		for s2 in range(-int(wdt), int(wdt) + 1):
			var r := q + nrm * s2
			P(int(r.x), int(r.y), c.darkened(0.12) if s2 > 0 else c)
		P(int(q.x), int(q.y), c.lightened(0.18))


## A mass of foliage made of many leaves – darker underneath, lighter where the sun is.
func leaf_cluster(cx: float, cy: float, r: float, pal: Array, sd: int, dens: float = 1.0) -> void:
	var n := int(r * r * 0.55 * dens)
	for i in n:
		var a := h(i, 1, sd) * TAU
		var d := sqrt(h(i, 2, sd)) * r
		var px := cx + cos(a) * d
		var py := cy + sin(a) * d * 0.8
		var lit := clampf(0.5 - (py - cy) / r * 0.6 - (px - cx) / r * 0.25, 0.0, 1.0)
		var c: Color = (pal[0] as Color).lerp(pal[1], lit)
		if lit > 0.8:
			c = (pal[1] as Color).lerp(pal[2], (lit - 0.8) * 4.0)
		leaf(px, py, h(i, 3, sd) * TAU, 3.0 + h(i, 4, sd) * 3.0, c)


## A jungle giant: its shadow, buttress roots, a tall trunk with bark and moss, a crown of many leaves, vines.
func jungle_tree(x: float, base_y: float, crown_r: float, sd: int) -> void:
	circ(x + crown_r * 0.4, base_y + 2, crown_r * 1.1, Color(0, 0, 0, 0.32), crown_r * 0.45)
	for rt in 5:
		var a := PI * (0.15 + rt * 0.17)
		for t in int(crown_r * 0.5):
			var q := Vector2(x, base_y) + Vector2(cos(a) * t * (1.0 if rt % 2 == 0 else -1.0), sin(a) * t * 0.25)
			R(int(q.x) - 1, int(q.y) - 2, 3, 3, Color(0.3, 0.22, 0.14).lerp(Color(0.24, 0.17, 0.1), h(rt, t, sd)))
	var th := crown_r * 1.2
	for yy in int(th):
		var wdt := 5 + int((1.0 - float(yy) / th) * 3)
		for xx in range(-wdt, wdt + 1):
			var c := Color(0.36, 0.27, 0.18).lerp(Color(0.24, 0.18, 0.11), (float(xx + wdt) / (2 * wdt)) * 0.8)
			if (xx + int(h(yy / 3, 1, sd) * 3)) % 3 == 0:
				c = c.darkened(0.2)
			if h(xx, yy, sd + 1) < 0.06:
				c = Color(0.3, 0.48, 0.22)
			P(int(x) + xx, int(base_y - yy), c)
	var cy := base_y - th - crown_r * 0.4
	var pal := [Color(0.08, 0.2, 0.08), Color(0.2, 0.42, 0.16), Color(0.55, 0.75, 0.3)]
	leaf_cluster(x, cy + crown_r * 0.25, crown_r, [Color(0.05, 0.13, 0.05), Color(0.12, 0.28, 0.1), Color(0.3, 0.5, 0.2)], sd + 2)
	for k in 5:
		var a2 := k * TAU / 5.0 + h(sd, k, 9)
		leaf_cluster(x + cos(a2) * crown_r * 0.5, cy + sin(a2) * crown_r * 0.35, crown_r * 0.6, pal, sd + 10 + k)
	leaf_cluster(x - crown_r * 0.2, cy - crown_r * 0.2, crown_r * 0.5, pal, sd + 20)
	for v in 4:
		var vx := x - crown_r * 0.6 + v * crown_r * 0.4
		var ln := 10 + int(h(v, 1, sd) * 16)
		for t2 in ln:
			P(int(vx + sin(t2 * 0.4) * 1.2), int(cy + crown_r * 0.6 + t2), Color(0.2, 0.38, 0.16))
			if t2 % 4 == 0:
				leaf(vx, cy + crown_r * 0.6 + t2, 0.4, 3.0, Color(0.25, 0.48, 0.18))


func broadleaf(x: float, y: float, sd: int, sc: float = 1.0) -> void:
	circ(x + 2, y + 1, 10 * sc, Color(0, 0, 0, 0.25), 3 * sc)
	for l in 6:
		var a := -PI * 0.5 + (l - 2.5) * 0.45 + h(l, 1, sd) * 0.2
		leaf(x, y, a, (10.0 + h(l, 2, sd) * 6.0) * sc, Color(0.16, 0.42, 0.18).lerp(Color(0.28, 0.55, 0.22), h(l, 3, sd)))


func fern(x: float, y: float, sd: int) -> void:
	for fr in 7:
		var a := -PI * 0.5 + (fr - 3) * 0.42 + (h(fr, 1, sd) - 0.5) * 0.1
		var dv := Vector2(cos(a), sin(a))
		var nrm := Vector2(-sin(a), cos(a))
		for t in 12:
			var q := Vector2(x, y) + dv * t + Vector2(0, t * t * 0.04)
			P(int(q.x), int(q.y), Color(0.22, 0.45, 0.2))
			if t % 2 == 0:
				P(int(q.x + nrm.x * 2), int(q.y + nrm.y * 2), Color(0.3, 0.55, 0.24))
				P(int(q.x - nrm.x * 2), int(q.y - nrm.y * 2), Color(0.26, 0.5, 0.22))


func flower_bush(x: float, y: float, col: Color, sd: int) -> void:
	leaf_cluster(x, y, 7, [Color(0.1, 0.25, 0.1), Color(0.2, 0.4, 0.16), Color(0.35, 0.55, 0.25)], sd, 1.2)
	for fl in 6:
		var q := Vector2(x + (h(fl, 1, sd) - 0.5) * 12, y + (h(fl, 2, sd) - 0.5) * 9)
		R(int(q.x), int(q.y), 2, 2, col)
		P(int(q.x), int(q.y), col.lightened(0.4))


## Thorny scrub: a dense dark mass with thorns sticking out – too thick to push through.
func thorn_bush(x: float, y: float, r: float, sd: int) -> void:
	leaf_cluster(x, y, r, [Color(0.06, 0.12, 0.05), Color(0.14, 0.24, 0.1), Color(0.25, 0.35, 0.16)], sd, 1.4)
	for th4 in 5:
		var a4 := h(sd, th4, 524) * TAU
		for tt in 5:
			P(int(x + cos(a4) * (r * 0.6 + tt)), int(y + sin(a4) * (r * 0.5 + tt)), Color(0.4, 0.28, 0.2))


func grass_tuft(x: float, y: float, c: Color, sd: int) -> void:
	for gt in 3:
		P(int(x) + gt - 1, int(y) - gt % 2 - 1, c.lerp(c.lightened(0.15), h(sd, gt, 520)))
		P(int(x) + gt - 1, int(y) - gt % 2, c.darkened(0.1))


## A palm: a leaning ringed trunk, a crown of drooping fronds, nuts under it.
func palm(x: float, base_y: float, sd: int) -> void:
	circ(x + 10, base_y + 2, 12, Color(0, 0, 0, 0.25), 4)
	var lean := 0.12 + h(sd, 1, 3) * 0.2
	var tall := 30 + int(h(sd, 2, 3) * 10)
	for t5 in tall:
		R(int(x + t5 * lean), int(base_y) - t5, 3, 1, Color(0.5, 0.38, 0.24).lerp(Color(0.4, 0.3, 0.18), float(t5 % 3) / 3.0))
	var top := Vector2(x + tall * lean + 1.5, base_y - tall)
	for fr in 8:
		var a7 := fr * TAU / 8.0 + 0.3 + h(fr, 1, sd) * 0.2
		for t6 in 17:
			var q7 := top + Vector2(cos(a7) * t6, sin(a7) * t6 * 0.55 + t6 * t6 * 0.035)
			P(int(q7.x), int(q7.y), Color(0.18, 0.45, 0.2).lerp(Color(0.35, 0.6, 0.28), float(t6) / 17.0))
			if t6 % 2 == 0:
				P(int(q7.x), int(q7.y) + 1, Color(0.15, 0.38, 0.16))
				P(int(q7.x) + 1, int(q7.y) + 1, Color(0.22, 0.5, 0.22))
	circ(top.x - 1, top.y + 1, 2, Color(0.45, 0.32, 0.15))
	circ(top.x + 2, top.y + 2, 2, Color(0.4, 0.28, 0.13))


# ------------------------------------------------------------------ stone and earth

func rock(x: float, y: float, r: float, base: Color, sd: int) -> void:
	circ(x + 2, y + 2, r, Color(0, 0, 0, 0.32), r * 0.6)
	for yy in range(int(y - r * 0.7), int(y + r * 0.7)):
		for xx in range(int(x - r), int(x + r)):
			var dx := (xx - x) / r
			var dy := (yy - y) / (r * 0.7)
			var e := dx * dx + dy * dy + (h(xx / 2, yy / 2, sd) - 0.5) * 0.25
			if e <= 1.0:
				var lit := clampf(0.55 - dy * 0.5 - dx * 0.3, 0.0, 1.0)
				var c := base.darkened(0.3).lerp(base.lightened(0.2), lit)
				if h(xx, yy, sd + 3) < 0.05:
					c = c.darkened(0.25)
				P(xx, yy, c)


## A steep rock wall seen from the front: strata, cracks, moss on the ledges.
func cliff_face(x0: int, y0: int, w: int, hh: int, base: Color, sd: int, moss: Color = Color(0.3, 0.48, 0.22)) -> void:
	for yy in range(y0, y0 + hh):
		for xx in range(x0, x0 + w):
			var off := int(h(xx / 9, 1, sd) * 4)
			var stra := int((yy - y0 + off) / 6)
			var c := base.darkened(0.08 * (stra % 3)).lerp(base.darkened(0.25), h(xx / 3, yy / 4, sd) * 0.5)
			if (yy - y0 + off) % 6 == 0:
				c = c.lightened(0.12)
				if h(xx, yy, sd + 2) < 0.4:
					c = moss
			if h(xx / 2, yy, sd + 5) < 0.02:
				c = c.darkened(0.45)
			P(xx, yy, c)


## A fallen trunk lying east–west: bark, moss along its top, mushrooms, the broken end.
func log_trunk(x0: int, y0: int, ln: int, sd: int) -> void:
	R(x0 + 2, y0 + 9, ln, 3, Color(0, 0, 0, 0.3))
	for t3 in ln:
		for th2 in 10:
			var c4 := Color(0.38, 0.27, 0.16).lerp(Color(0.26, 0.18, 0.1), float(th2) / 10.0)
			if (t3 + int(h(th2, 1, sd) * 3)) % 5 == 0:
				c4 = c4.darkened(0.15)
			if th2 < 2:
				c4 = Color(0.32, 0.48, 0.2) if h(t3, th2, sd) < 0.6 else c4
			P(x0 + t3, y0 + th2, c4)
	for e in 10:
		P(x0 + ln - 1, y0 + e, Color(0.6, 0.45, 0.28))
		P(x0 + ln - 2, y0 + e, Color(0.52, 0.38, 0.22))
	for mu in 3:
		var mx := x0 + 6 + int(h(mu, 1, sd) * (ln - 12))
		R(mx, y0 - 1, 3, 2, Color(0.9, 0.82, 0.6))
		P(mx + 1, y0 + 1, Color(0.7, 0.62, 0.45))


## Driftwood: a bleached grey trunk, a stub of root.
func driftwood(x0: int, y0: int, ln: int, sd: int) -> void:
	R(x0 + 2, y0 + 6, ln, 2, Color(0, 0, 0, 0.25))
	for t in ln:
		for th in 6:
			var c := Color(0.78, 0.74, 0.66).lerp(Color(0.55, 0.5, 0.44), float(th) / 6.0)
			if (t + int(h(th, 1, sd) * 4)) % 6 == 0:
				c = c.darkened(0.12)
			P(x0 + t, y0 + th, c)
	for rt in 5:
		P(x0 - rt, y0 + 2 - rt % 3, Color(0.6, 0.56, 0.5))


# ------------------------------------------------------------------ ice

## A floe of pack ice: a jagged plate, snow on top, a lit rim, a darker side where it sits in the water.
func floe(cx: float, cy: float, r: float, sd: int) -> void:
	var pts := PackedVector2Array()
	for k in 9:
		var a := k * TAU / 9.0
		var rr := r * (0.75 + h(k, 1, sd) * 0.4)
		pts.append(Vector2(cx + cos(a) * rr, cy + sin(a) * rr * 0.6))
	for yy in range(int(cy - r), int(cy + r) + 4):
		for xx in range(int(cx - r * 1.2), int(cx + r * 1.2)):
			if Geometry2D.is_point_in_polygon(Vector2(xx, yy), pts):
				P(xx, yy, Color(0.9, 0.95, 1.0).lerp(Color(0.8, 0.88, 0.96), h(xx / 2, yy / 2, sd)))
			elif Geometry2D.is_point_in_polygon(Vector2(xx, yy - 3), pts):
				P(xx, yy, Color(0.45, 0.62, 0.8))
	for k2 in 9:
		var a2: Vector2 = pts[k2]
		var b2: Vector2 = pts[(k2 + 1) % 9]
		for t in 12:
			var q := a2.lerp(b2, t / 12.0)
			P(int(q.x), int(q.y), Color(1, 1, 1) if a2.y < cy else Color(0.6, 0.75, 0.9))


func crack(a: Vector2, b: Vector2, sd: int) -> void:
	var n := int(a.distance_to(b))
	for t in n:
		var q := a.lerp(b, float(t) / n) + Vector2(sin(t * 0.3 + sd) * 3.0, cos(t * 0.21 + sd) * 2.0)
		P(int(q.x), int(q.y), Color(0.2, 0.35, 0.5))
		P(int(q.x) + 1, int(q.y), Color(0.45, 0.65, 0.85))
		if t % 17 == 5:
			var a3 := h(t, 1, sd) * TAU
			for t2 in 8:
				P(int(q.x + cos(a3) * t2), int(q.y + sin(a3) * t2 * 0.6), Color(0.35, 0.5, 0.68))


## A block of ice standing on the snow: its lit top, its fractured blue face, a shadow.
func ice_block(x: int, y: int, w: int, top: int, face: int, sd: int) -> void:
	R(x + 4, y + top + face, w, 4, Color(0.35, 0.45, 0.6, 0.45))
	for yy in top:
		for xx in w:
			P(x + xx, y + yy, Color(0.88, 0.95, 1.0).lerp(Color(0.75, 0.86, 0.96), h(xx / 2, yy, sd)))
	for yy2 in face:
		for xx2 in w:
			var c := Color(0.45, 0.68, 0.88).lerp(Color(0.32, 0.52, 0.75), float(yy2) / face)
			if (xx2 + int(h(yy2 / 3, 1, sd) * 4)) % 7 == 0:
				c = c.lightened(0.25)
			P(x + xx2, y + top + yy2, c)
	R(x, y, w, 1, Color(1, 1, 1))
	R(x + 2, y + top + 2, 2, maxi(1, face - 4), Color(0.8, 0.92, 1.0))


## A chunk of ice standing in the snow (for an object's picture w × hh): a ragged top, snow lying on it, the lit
## top face, the blue front with its fractures, darker low down; its shadow on the snow.
func ice_chunk(w: int, hh: int, sd: int) -> void:
	var base := hh - 4
	circ(w * 0.55, base + 1, w * 0.48, Color(0.3, 0.42, 0.6, 0.35), 3.0)
	var tall := hh - 10
	for x in range(2, w - 3):
		var k := float(x - 2) / float(w - 5)
		var top := base - int(tall * (0.55 + 0.45 * sin(k * PI))) + int((h(x / 3, 1, sd) - 0.5) * 7.0)
		var face_top := top + 5 + int(h(x / 4, 2, sd) * 3.0)
		for y in range(top, base + 1):
			var c: Color
			if y < face_top:
				c = Color(0.9, 0.96, 1.0).lerp(Color(0.74, 0.86, 0.96), float(y - top) / maxf(1.0, face_top - top))
				if y == top:
					c = Color(1, 1, 1)
			else:
				var fk := float(y - face_top) / maxf(1.0, base - face_top)
				c = Color(0.52, 0.74, 0.92).lerp(Color(0.3, 0.5, 0.74), fk)
				if (x + int(h(y / 4, 3, sd) * 5.0)) % 8 == 0:
					c = c.lightened(0.28)                                      # fractures
				if h(x, y, sd + 4) < 0.04:
					c = c.darkened(0.2)
				if x < 5:
					c = c.lightened(0.12)                                      # the lit edge
			P(x, y, c)
	R(4, base - tall / 2, 2, tall / 3, Color(0.85, 0.94, 1.0))


## A slab of a pressure ridge: tilted, its top lit, its foot in shadow.
func ridge_slab(px: float, py: float, sd: int) -> void:
	var ang := (h(sd, 1, 711) - 0.5) * 1.4
	var sw := 9.0 + h(sd, 4, 711) * 6.0
	var sh := 10.0 + h(sd, 5, 711) * 9.0
	var pts := PackedVector2Array([Vector2(-sw * 0.5, 0), Vector2(sw * 0.5, 0), Vector2(sw * 0.4, -sh), Vector2(-sw * 0.6, -sh * 0.8)])
	var tp := PackedVector2Array()
	for v in pts:
		tp.append(Vector2(px, py) + v.rotated(ang))
	R(int(px) - 4, int(py), 12, 3, Color(0.4, 0.52, 0.68, 0.5))
	for yy8 in range(int(py - sh - 6), int(py + 4)):
		for xx8 in range(int(px - sw - 2), int(px + sw + 2)):
			if Geometry2D.is_point_in_polygon(Vector2(xx8, yy8), tp):
				var k8 := clampf((py - yy8) / sh, 0.0, 1.0)
				var c9 := Color(0.42, 0.62, 0.84).lerp(Color(0.85, 0.94, 1.0), k8)
				if (xx8 - int(px)) > sw * 0.25:
					c9 = c9.darkened(0.15)
				P(xx8, yy8, c9)
	for t9 in int(sw):
		var q9 := tp[3].lerp(tp[2], float(t9) / sw)
		P(int(q9.x), int(q9.y), Color(1, 1, 1))


# ------------------------------------------------------------------ the crashed landing drone

## The landing drone come down nose first, tilted, scorched and dented (its picture from LanderArt, scaled up).
func lander_wreck(c: Vector2, ang: float, sd: int) -> void:
	var lt: Texture2D = LanderArtW.texture()
	if lt == null:
		return
	var li: Image = lt.get_image().duplicate()
	if li.is_compressed():
		li.decompress()
	li.convert(Image.FORMAT_RGBA8)
	li.resize(int(li.get_width() * 1.6), int(li.get_height() * 1.6), Image.INTERPOLATE_NEAREST)
	for yy4 in li.get_height():
		for xx4 in li.get_width():
			var c6 := li.get_pixel(xx4, yy4)
			if c6.a > 0.5:
				var tilt := Vector2(xx4 - li.get_width() * 0.5, yy4 - li.get_height() * 0.5).rotated(ang)
				var q8 := c + tilt
				var dmg := 0.25 if h(xx4 / 2, yy4 / 2, sd) < 0.25 else 0.0
				R(int(q8.x), int(q8.y), 2, 2, c6.darkened(0.15 + dmg))           # (2 px: no holes from the turn)


# ------------------------------------------------------------------ objects of the wild (ObjArt hands them here)

const OBJ_KINDS := ["wild_tree", "palm", "wild_log", "driftwood", "ice_block", "lander_wreck", "wild_rock"]


## Paints an object of the wild into its picture (w × h tiles, rising `rise` above): the foot at the bottom middle.
static func paint_obj(o: Dictionary, im: Image) -> void:
	var p = load(SELF).new(im)
	var sd := int(o.get("seed", 1))
	var cx := im.get_width() * 0.5
	var base := im.get_height() - 8.0
	match String(o["kind"]):
		"wild_tree":
			p.jungle_tree(cx, base, 20.0 + float(sd % 4) * 2.5, 530 + sd * 7)
		"palm":
			p.palm(cx - 8.0, base, sd)
		"wild_log":
			p.log_trunk(2, im.get_height() - 13, im.get_width() - 4, sd)
		"driftwood":
			p.driftwood(4, im.get_height() - 10, im.get_width() - 8, sd)
		"ice_block":
			p.ice_chunk(im.get_width(), im.get_height(), sd)
		"wild_rock":
			var col: Color = o.get("col", Color(0.42, 0.42, 0.44))
			p.rock(cx, im.get_height() - 9.0, im.get_width() * 0.42, col, sd)
			if bool(o.get("weed", false)):
				for sw in 5:
					p.P(int(cx) - 8 + sw * 4, im.get_height() - 4, Color(0.25, 0.45, 0.3))
		"lander_wreck":
			p.lander_wreck(Vector2(cx, im.get_height() * 0.55), 0.45, sd)
