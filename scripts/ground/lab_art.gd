extends RefCounted
## Package 62a, part 11a (Luz, 24 Nov 2026): what the Alien Laboratory is drawn with.
##   The map's own tiles (GroundMap calls these for style "lab"): the halls' dark slabs with seams of light, the
##   corridors' plates, a wall's face of pale panels with a strip of light, the solid mass between the halls, and what
##   is painted into the floor (decals whose kind begins with "lab_": guide lines, a hall's letters, landing rings,
##   cables, frost, the stripes of a doorway).
##   The furniture (ObjArt calls paint_obj for OBJ_KINDS): specimen tanks, the great tank of the Core Hall, operating
##   tables under their lamps, instrument carts, a parked saucer, cryo pods, holding cells behind a field of force,
##   and what they took, held in stasis: a tractor, a cow, a road sign.
## One scale with all ground art: a tile is 16 px, somebody standing about 27 px.
## No class_name: load("res://scripts/ground/lab_art.gd").

const OBJ_KINDS := ["spec_tank", "big_tank", "op_table", "instr_cart", "saucer", "cryo_pod", "pen_cell", "stasis"]
const TL := 16
const T_VOID := 0
const T_FLOOR := 1
const T_CAP := 2
const T_FACE := 3
const T_DOOR := 5
const T_BLOCK := 6
const GLOW := Color(0.25, 0.85, 0.8)
const FLUID := Color(0.3, 0.9, 0.45)
const STEEL := Color(0.24, 0.27, 0.32)
const PALE := Color(0.66, 0.72, 0.78)
const STASIS := Color(0.72, 0.45, 1.0)

## Big letters for the floor, five by seven.
const FONT := {
	"A": ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
	"B": ["11110", "10001", "10001", "11110", "10001", "10001", "11110"],
	"C": ["01111", "10000", "10000", "10000", "10000", "10000", "01111"],
	"1": ["00100", "01100", "00100", "00100", "00100", "00100", "01110"],
	"2": ["01110", "10001", "00001", "00110", "01000", "10000", "11111"],
	"3": ["11110", "00001", "00001", "01110", "00001", "00001", "11110"],
}


static func _h2(x: int, y: int, s: int = 0) -> float:
	var v := sin(float(x) * 12.9898 + float(y) * 78.233 + float(s) * 3.7) * 43758.5453
	return v - floorf(v)


# ---------------------------------------------------------------- the map's tiles

static func floor_tile(m, x: int, y: int, px: int, py: int, fk: int) -> void:
	var f: Color = m.pal["floor"]
	var f2: Color = m.pal["floor2"]
	if fk == 52:                                            # a corridor: plates with a tread
		var c: Color = f2.lightened(0.06) if (x + y) % 2 == 0 else f2
		m._rect(px, py, TL, TL, c)
		m._rect(px, py + TL - 1, TL, 1, c.darkened(0.22))
		m._rect(px + TL - 1, py, 1, TL, c.darkened(0.18))
		for k in 3:
			m._px(px + 3 + k * 5, py + 4 + (k % 2) * 6, c.lightened(0.14))
		return
	var base: Color = f.lerp(f2, _h2(x / 2, y / 2, 51) * 0.8)   # a hall: slabs of two tiles by two, a seam of light every eight
	m._rect(px, py, TL, TL, base)
	if x % 2 == 0:
		m._rect(px, py, 1, TL, base.darkened(0.28))
	if y % 2 == 0:
		m._rect(px, py, TL, 1, base.darkened(0.28))
	if x % 8 == 0:
		m._rect(px, py, 1, TL, GLOW.darkened(0.35))
		m._rect(px + 1, py, 1, TL, base.lerp(GLOW, 0.16))
	if y % 8 == 0:
		m._rect(px, py, TL, 1, GLOW.darkened(0.35))
		m._rect(px, py + 1, TL, 1, base.lerp(GLOW, 0.16))
	if _h2(x, y, 52) > 0.9:
		m._rect(px + 3 + int(_h2(x, y, 53) * 8.0), py + 4 + int(_h2(y, x, 54) * 8.0), 3, 1, base.darkened(0.2))


static func face_tile(m, x: int, y: int, px: int, py: int) -> void:
	var wl: Color = m.pal["wall"]
	var ac: Color = m.pal["accent"]
	var top: bool = int(m.t_at(x, y - 1)) != T_FACE
	var bot: bool = int(m.t_at(x, y + 1)) != T_FACE
	var c: Color = wl if top else wl.darkened(0.14)
	m._rect(px, py, TL, TL, c)
	if x % 2 == 0:
		m._rect(px, py, 1, TL, c.darkened(0.22))            # the panels' seams
	if top:
		m._rect(px, py, TL, 2, wl.lightened(0.22))
		m._rect(px, py + 5, TL, 2, ac)                       # a strip of light along the wall
		m._rect(px, py + 7, TL, 1, ac.darkened(0.5))
		if x % 6 == 3:                                       # a vent
			m._rect(px + 3, py + 10, 10, 5, wl.darkened(0.5))
			m._rect(px + 4, py + 11, 8, 1, wl.darkened(0.2))
			m._rect(px + 4, py + 13, 8, 1, wl.darkened(0.2))
	if bot:
		m._rect(px, py + 10, TL, 6, wl.darkened(0.48))       # its dark base
		m._rect(px, py + 10, TL, 1, wl.darkened(0.28))
		if x % 4 == 1:
			m._px(px + 8, py + 13, Color(0.45, 1.0, 0.55) if x % 12 != 5 else Color(1.0, 0.7, 0.25))


static func cap_tile(m, x: int, y: int, px: int, py: int) -> void:
	var top: Color = m.pal["wall_top"]
	var c: Color = top.darkened(0.3 * _h2(x / 2, y / 2, 61))
	m._rect(px, py, TL, TL, c)
	if x % 2 == 0:
		m._rect(px, py, 1, TL, c.darkened(0.3))
	if y % 2 == 0:
		m._rect(px, py, TL, 1, c.darkened(0.3))
	var rim: Color = Color(m.pal["wall"]).darkened(0.3)
	var up := int(m.t_at(x, y - 1))
	var left := int(m.t_at(x - 1, y))
	var right := int(m.t_at(x + 1, y))
	var below := int(m.t_at(x, y + 1))
	if up != T_CAP and up != T_VOID:
		m._rect(px, py, TL, 3, rim)
	if left != T_CAP and left != T_VOID and left != T_FACE:
		m._rect(px, py, 3, TL, rim)
	if right != T_CAP and right != T_VOID and right != T_FACE:
		m._rect(px + TL - 3, py, 3, TL, rim.darkened(0.2))
	if below == T_FACE:
		m._rect(px, py + TL - 3, TL, 3, rim.lightened(0.2))
	elif below == T_FLOOR or below == T_DOOR or below == T_BLOCK:
		m._rect(px, py + TL - 4, TL, 4, Color(m.pal["wall"]).darkened(0.35))
	elif up == T_CAP and left == T_CAP and right == T_CAP and _h2(x, y, 62) > 0.95:
		m._rect(px + 4, py + 4, 8, 8, c.darkened(0.4))        # deep in the mass: a hatch, a light on it
		m._px(px + 10, py + 5, GLOW.darkened(0.2))


## Laid over the floor: `k` of the colour, the rest what is there.
static func _t(m, x: int, y: int, w: int, h: int, c: Color, k: float) -> void:
	m._mix(x, y, w, h, Color(c.r, c.g, c.b, k))


## What is painted into the floor.
static func decal(m, d: Dictionary) -> void:
	var col: Color = d.get("col", GLOW)
	match String(d["kind"]):
		"lab_line":                                         # a guide line: {x, y, w, h} px
			var r: Rect2i = d["rect"]
			_t(m,r.position.x, r.position.y, r.size.x, r.size.y, col, 0.7)
			if r.size.x > r.size.y:
				_t(m,r.position.x, r.position.y + r.size.y, r.size.x, 1, Color(0, 0, 0), 0.25)
			else:
				_t(m,r.position.x + r.size.x, r.position.y, 1, r.size.y, Color(0, 0, 0), 0.25)
		"lab_sign":                                         # a hall's letters, large: {x, y} px its middle, txt, k: px a square
			var k := int(d.get("k", 5))
			var txt := String(d["txt"])
			var x0 := int(d["x"]) - (txt.length() * 6 - 1) * k / 2
			var y0 := int(d["y"]) - 7 * k / 2
			for ci in txt.length():
				var g: Array = FONT.get(txt[ci], FONT["A"])
				for gy in 7:
					for gx in 5:
						if String(g[gy])[gx] == "1":
							_t(m,x0 + (ci * 6 + gx) * k, y0 + gy * k, k, k, col, 0.5)
							_t(m,x0 + (ci * 6 + gx) * k, y0 + gy * k + k - 1, k, 1, Color(0, 0, 0), 0.2)
		"lab_ring":                                         # a landing ring: {x, y} px its middle, r
			var cx := float(d["x"])
			var cy := float(d["y"])
			var rr := float(d["r"])
			var steps := int(rr * 7.0)
			for q in steps:
				var a := TAU * float(q) / float(steps)
				var e := Vector2(cos(a), sin(a) * 0.62)
				_t(m,int(cx + e.x * rr), int(cy + e.y * rr), 2, 2, col, 0.75)
				if (q * 16 / steps) % 2 == 0:
					_t(m,int(cx + e.x * rr * 0.72), int(cy + e.y * rr * 0.72), 2, 1, col, 0.5)
			_t(m,int(cx) - 8, int(cy), 17, 1, col, 0.6)
			_t(m,int(cx), int(cy) - 5, 1, 11, col, 0.6)
		"lab_cable":                                        # a cable on the floor: pts (px)
			var pts: PackedVector2Array = d["pts"]
			for q2 in pts.size() - 1:
				var a2: Vector2 = pts[q2]
				var b2: Vector2 = pts[q2 + 1]
				var n := int(maxf(absf(b2.x - a2.x), absf(b2.y - a2.y)))
				for s in n + 1:
					var p: Vector2 = a2.lerp(b2, float(s) / float(maxi(1, n)))
					m._rect(int(p.x) - 1, int(p.y) - 1, 3, 3, Color(0.09, 0.1, 0.12))
					m._px(int(p.x), int(p.y) - 1, Color(0.24, 0.26, 0.3) if (s / 6) % 4 != 0 else col.darkened(0.2))
		"lab_frost":                                        # frost on the floor round {x, y} px, as far as r
			var fx := int(d["x"])
			var fy := int(d["y"])
			var fr := int(d["r"])
			for q3 in fr * fr / 3:
				var a3 := _h2(q3, fx, 71) * TAU
				var l3 := pow(_h2(q3, fy, 72), 0.7) * float(fr)
				_t(m,fx + int(cos(a3) * l3), fy + int(sin(a3) * l3 * 0.6), 2, 1, Color(0.85, 0.95, 1.0), 0.55 * (1.0 - l3 / float(fr)))
		"lab_emitter":                                      # the post of a laser grid at a doorway's end: {x, y} px
			var ex := int(d["x"])
			var ey := int(d["y"])
			m._rect(ex - 5, ey - 5, 10, 10, Color(0.08, 0.09, 0.11))
			m._rect(ex - 5, ey - 5, 10, 1, Color(0.3, 0.33, 0.38))
			m._rect(ex - 2, ey - 2, 4, 4, Color(0.95, 0.2, 0.15))
			m._px(ex - 1, ey - 2, Color(1.0, 0.8, 0.7))
		"lab_door":                                         # the stripes of a doorway: {rect} px
			var dr: Rect2i = d["rect"]
			for yy in dr.size.y:
				for xx in range(0, dr.size.x, 2):
					if ((xx + yy) / 4) % 2 == 0:
						_t(m,dr.position.x + xx, dr.position.y + yy, 2, 1, Color(1.0, 0.82, 0.2), 0.55)


# ---------------------------------------------------------------- the furniture

static func _r(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	var r := Rect2i(x, y, w, h).intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	if r.size.x > 0 and r.size.y > 0:
		img.fill_rect(r, c)


static func _p(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)


## Laid over what is there (c's alpha says how much of it shows).
static func _a(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in range(maxi(0, y), mini(img.get_height(), y + h)):
		for xx in range(maxi(0, x), mini(img.get_width(), x + w)):
			var o := img.get_pixel(xx, yy)
			if o.a < 0.05:
				img.set_pixel(xx, yy, c)
			else:
				img.set_pixel(xx, yy, Color(lerpf(o.r, c.r, c.a), lerpf(o.g, c.g, c.a), lerpf(o.b, c.b, c.a), maxf(o.a, c.a)))


static func _ell(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for yy in range(int(floorf(cy - ry)), int(ceilf(cy + ry)) + 1):
		for xx in range(int(floorf(cx - rx)), int(ceilf(cx + rx)) + 1):
			var dx := (float(xx) + 0.5 - cx) / rx
			var dy := (float(yy) + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				_p(img, xx, yy, c)


static func _line(img: Image, a: Vector2, b: Vector2, w: int, c: Color) -> void:
	var n := int(maxf(absf(b.x - a.x), absf(b.y - a.y)))
	for s in n + 1:
		var p := a.lerp(b, float(s) / float(maxi(1, n)))
		_r(img, int(round(p.x)) - w / 2, int(round(p.y)) - w / 2, w, w, c)


static func paint_obj(o: Dictionary, img: Image) -> void:
	var pw := img.get_width()
	var base := img.get_height()
	var sd := int(o.get("seed", 0))
	match String(o["kind"]):
		"spec_tank":
			_spec_tank(img, pw, base, sd)
		"big_tank":
			_big_tank(img, pw, base, sd)
		"op_table":
			_op_table(img, pw, base, sd)
		"instr_cart":
			_r(img, 2, base - 16, 12, 3, PALE)                  # the tray
			_r(img, 2, base - 13, 12, 1, PALE.darkened(0.3))
			_r(img, 3, base - 12, 1, 10, STEEL.lightened(0.2))
			_r(img, 12, base - 12, 1, 10, STEEL.lightened(0.2))
			_r(img, 3, base - 7, 10, 2, PALE.darkened(0.2))
			_r(img, 2, base - 2, 3, 2, Color(0.08, 0.08, 0.1))
			_r(img, 11, base - 2, 3, 2, Color(0.08, 0.08, 0.1))
			_r(img, 4, base - 17, 5, 1, Color(0.92, 0.96, 1.0)) # what lies on it
			_r(img, 10, base - 18, 1, 2, Color(0.92, 0.96, 1.0))
			_p(img, 7, base - 8, Color(0.9, 0.3, 0.3))
		"saucer":
			_saucer(img, pw, base)
		"cryo_pod":
			_cryo_pod(img, pw, base, sd)
		"pen_cell":
			_pen_cell(img, pw, base, sd)
		"stasis":
			_stasis(img, pw, base, String(o.get("species", "empty")))


## A specimen tank: a glass cylinder of green fluid on a plinth, something in it (seed: what; 9: broken, run dry).
static func _spec_tank(img: Image, pw: int, base: int, sd: int) -> void:
	var dark := FLUID.darkened(0.55)
	_r(img, 2, base - 7, pw - 4, 7, STEEL)                    # the plinth
	_r(img, 2, base - 7, pw - 4, 1, STEEL.lightened(0.3))
	_r(img, 2, base - 1, pw - 4, 1, STEEL.darkened(0.4))
	_p(img, pw - 6, base - 4, FLUID if sd != 9 else Color(1.0, 0.3, 0.25))
	_r(img, 5, base - 4, 6, 1, STEEL.darkened(0.4))
	var gx := 4
	var gw := pw - 8
	var gtop := base - 38
	_r(img, 3, gtop - 4, pw - 6, 5, STEEL.lightened(0.08))      # the cap, a pipe out of it
	_r(img, 3, gtop - 4, pw - 6, 1, STEEL.lightened(0.4))
	_r(img, pw / 2 - 1, gtop - 6, 3, 2, STEEL.darkened(0.2))
	if sd == 9:                                               # broken: jagged glass, a little left at the bottom
		for x in gw:
			var jh := 4 + int(_h2(x, 3, 81) * 9.0) + (5 if x < 3 or x > gw - 4 else 0)
			_r(img, gx + x, base - 7 - jh, 1, jh, Color(0.62, 0.86, 0.8, 0.75))
		_r(img, gx + 1, base - 10, gw - 2, 3, dark)
		_r(img, gx, gtop + 1, 1, 12, Color(0.62, 0.86, 0.8, 0.75))
		_r(img, gx + gw - 1, gtop + 1, 1, 8, Color(0.62, 0.86, 0.8, 0.75))
		return
	_r(img, gx, gtop, gw, 31, dark)                           # the fluid
	_r(img, gx, gtop, gw, 2, FLUID.darkened(0.2))               # (its surface)
	var shape := dark.darkened(0.6)
	var mx := pw / 2
	match sd % 5:
		0:                                                    # curled up, a large head
			_ell(img, mx - 1.0, gtop + 11.0, 5.0, 5.0, shape)
			_ell(img, mx + 1.0, gtop + 19.0, 4.0, 6.0, shape)
			_r(img, mx - 4, gtop + 23, 6, 2, shape)
		1:                                                    # a bell with arms trailing down
			_ell(img, float(mx), gtop + 10.0, 6.0, 4.5, shape)
			for q in 4:
				for s in 12:
					_p(img, mx - 5 + q * 3 + int(sin(float(s) * 0.7 + float(q)) * 1.4), gtop + 14 + s, shape)
		2:                                                    # one of them: a large head, thin limbs
			_ell(img, float(mx), gtop + 9.0, 4.5, 5.0, shape)
			_r(img, mx - 2, gtop + 14, 4, 8, shape)
			_r(img, mx - 4, gtop + 15, 1, 8, shape)
			_r(img, mx + 3, gtop + 15, 1, 8, shape)
			_r(img, mx - 2, gtop + 22, 1, 6, shape)
			_r(img, mx + 1, gtop + 22, 1, 6, shape)
			_p(img, mx - 2, gtop + 9, FLUID.lightened(0.2))
			_p(img, mx + 1, gtop + 9, FLUID.lightened(0.2))
		3:                                                    # an eye on a stalk
			_ell(img, float(mx), gtop + 9.0, 5.0, 5.0, shape)
			_ell(img, float(mx), gtop + 9.0, 2.0, 2.0, FLUID.lightened(0.1))
			_p(img, mx, gtop + 9, shape)
			for s2 in 16:
				_r(img, mx - 1 + int(sin(float(s2) * 0.5) * 2.0), gtop + 14 + s2, 2, 1, shape)
		_:                                                    # nothing but fluid
			pass
	for b in 5:                                               # bubbles rising
		_p(img, gx + 2 + int(_h2(b, sd, 82) * float(gw - 4)), gtop + 3 + int(_h2(sd, b, 83) * 26.0), FLUID.lightened(0.35))
	_r(img, gx, gtop, 1, 31, Color(0.75, 1.0, 0.9))           # the glass: a light edge, a glint, a dark edge
	_r(img, gx + 2, gtop + 3, 1, 18, FLUID.lightened(0.15))
	_r(img, gx + gw - 1, gtop, 1, 31, dark.darkened(0.3))


## The great tank of the Core Hall: something very large sleeps in it. (seed 9, part 11c: burst, and empty: what
## slept in it is out.)
static func _big_tank(img: Image, pw: int, base: int, sd: int = 0) -> void:
	var mx := pw / 2
	var murk := Color(0.08, 0.27, 0.2)
	_ell(img, float(mx), base - 12.0, pw * 0.5 - 1.0, 12.0, STEEL.darkened(0.2))      # the plinth, round
	_r(img, 1, base - 30, pw - 2, 18, STEEL)
	_ell(img, float(mx), base - 30.0, pw * 0.5 - 1.0, 10.0, STEEL.lightened(0.15))
	for q in 12:                                              # lights round it, stripes of warning
		var lx := 6 + q * (pw - 12) / 11
		_r(img, lx, base - 20, 2, 2, (FLUID if q % 3 != 1 else Color(1.0, 0.75, 0.25)) if sd != 9 else Color(1.0, 0.3, 0.25))
		if q % 2 == 0:
			_r(img, lx - 2, base - 12, 5, 3, Color(0.95, 0.78, 0.2))
	var gx := 10
	var gw := pw - 20
	var gtop := base - 112
	if sd == 9:                                               # burst: jagged glass round the plinth, what is left of its fluid, the struts that held its collar
		_ell(img, float(mx), base - 30.0, gw * 0.5, 8.0, murk)
		for x in gw:
			var jh := 5 + int(_h2(x, 7, 91) * 20.0) + (10 if (x < 5 or x > gw - 6) else 0)
			if _h2(x / 3, 2, 92) > 0.3:
				_r(img, gx + x, base - 30 - jh, 1, jh, Color(0.62, 0.9, 0.82, 0.7))
		for st in 4:
			var sx := gx + 4 + st * (gw - 10) / 3
			var sh := 40 + int(_h2(st, 3, 93) * 34.0)
			_r(img, sx, base - 30 - sh, 2, sh, STEEL.darkened(0.3))
			_r(img, sx - 1, base - 31 - sh, 4, 2, STEEL.lightened(0.2))
		for c in 5:
			var cx := gx + 10 + c * (gw - 20) / 4
			for s in 14 + c * 3:
				_p(img, cx + int(sin(float(s) * 0.5 + float(c)) * 3.0), base - 34 - s, Color(0.05, 0.1, 0.09))
		return
	_r(img, gx, gtop, gw, 84, murk)                           # the fluid, murky
	_ell(img, float(mx), base - 30.0, gw * 0.5, 8.0, murk.darkened(0.25))
	_r(img, gx, gtop, gw, 3, FLUID.darkened(0.35))
	var mass := Color(0.2, 0.44, 0.32)                        # what is in it: a brain as large as a rover, its stem running down
	_ell(img, float(mx), gtop + 38.0, 36.0, 25.0, mass)
	_ell(img, mx - 15.0, gtop + 30.0, 17.0, 14.0, mass.lightened(0.07))
	_ell(img, mx + 16.0, gtop + 32.0, 16.0, 14.0, mass.darkened(0.06))
	for f in 9:                                               # its folds
		var fa := -1.3 + float(f) * 0.32
		for s in 22:
			var fp := Vector2(mx + sin(fa) * (8.0 + float(s) * 1.25), gtop + 38.0 - cos(fa) * (4.0 + float(s) * 0.9) + sin(float(s) * 0.8 + float(f)) * 1.6)
			if absf(fp.x - float(mx)) < 34.0 and fp.y > gtop + 15.0 and fp.y < gtop + 61.0:
				_p(img, int(fp.x), int(fp.y), mass.darkened(0.3))
	_r(img, mx - 1, gtop + 14, 1, 48, mass.darkened(0.35))      # (the cleft between its halves)
	for s2 in 26:                                             # the stem
		var sw := 9 - s2 / 4
		_r(img, mx - sw / 2 + int(sin(float(s2) * 0.3) * 2.0), gtop + 58 + s2, maxi(2, sw), 1, mass.darkened(0.12))
	for t in 6:                                               # lines into it
		var tx := gx + 8 + t * (gw - 16) / 5
		for s3 in 16 + (t % 3) * 6:
			_p(img, tx + int(sin(float(s3) * 0.4 + float(t)) * 2.0), gtop + 3 + s3, Color(0.05, 0.1, 0.09))
	for b in 22:
		_p(img, gx + 3 + int(_h2(b, 4, 84) * float(gw - 6)), gtop + 5 + int(_h2(5, b, 85) * 76.0), FLUID.darkened(0.1))
	_r(img, gx, gtop, 2, 84, Color(0.6, 0.95, 0.85))          # the glass
	_r(img, gx + 5, gtop + 6, 2, 50, murk.lightened(0.25))
	_r(img, gx + 9, gtop + 10, 1, 30, murk.lightened(0.15))
	_r(img, gx + gw - 3, gtop, 3, 84, murk.darkened(0.45))
	_r(img, gx - 4, gtop - 12, gw + 8, 13, STEEL.lightened(0.06))  # its collar, clamps, what runs up out of it
	_r(img, gx - 4, gtop - 12, gw + 8, 2, STEEL.lightened(0.45))
	_r(img, gx - 4, gtop - 1, gw + 8, 2, STEEL.darkened(0.45))
	for c in 7:
		_r(img, gx + c * (gw - 4) / 6, gtop - 9, 4, 8, STEEL.darkened(0.3))
		_p(img, gx + 1 + c * (gw - 4) / 6, gtop - 6, FLUID)
	_r(img, mx - 14, gtop - 16, 8, 4, STEEL.darkened(0.25))
	_r(img, mx + 6, gtop - 16, 8, 4, STEEL.darkened(0.25))


## An operating table under its lamp; on some of them something lies under a sheet (seed).
static func _op_table(img: Image, pw: int, base: int, sd: int) -> void:
	_r(img, pw / 2 - 5, base - 12, 10, 10, STEEL)             # its foot
	_r(img, pw / 2 - 8, base - 3, 16, 3, STEEL.darkened(0.3))
	_r(img, 4, base - 24, pw - 8, 10, PALE)                   # the slab, its edge
	_r(img, 4, base - 24, pw - 8, 1, PALE.lightened(0.25))
	_r(img, 4, base - 15, pw - 8, 3, PALE.darkened(0.4))
	if sd % 3 == 0:                                           # under a sheet
		_ell(img, pw * 0.5 + 2.0, base - 20.0, pw * 0.5 - 12.0, 3.5, Color(0.78, 0.86, 0.8))
		_ell(img, 13.0, base - 20.5, 4.0, 3.0, Color(0.82, 0.9, 0.84))
	else:
		_r(img, 14, base - 23, 2, 8, STEEL.lightened(0.1))      # the straps, open
		_r(img, pw - 16, base - 23, 2, 8, STEEL.lightened(0.1))
		if sd % 3 == 1:
			_r(img, 20, base - 21, 7, 3, Color(0.25, 0.75, 0.35))   # (a stain)
	_r(img, 5, base - 46, 2, 23, STEEL.lightened(0.2))          # the lamp's arm, its disc over the table
	_r(img, 5, base - 47, pw / 2 - 2, 2, STEEL.lightened(0.2))
	_ell(img, pw * 0.5 + 1.0, base - 43.0, 9.0, 3.5, STEEL.lightened(0.3))
	_ell(img, pw * 0.5 + 1.0, base - 41.5, 8.0, 2.5, Color(1.0, 0.98, 0.82))
	_p(img, pw / 2 - 3, base - 42, Color(1, 1, 1))


## A saucer parked on three legs, its ramp down.
static func _saucer(img: Image, pw: int, base: int) -> void:
	var mx := pw / 2
	var hull := Color(0.6, 0.65, 0.71)
	var under := Color(0.33, 0.37, 0.43)
	var cy := base - 56.0
	for lx in [mx - 62, mx, mx + 62]:                          # the legs, their pads
		_line(img, Vector2(lx, cy + 14.0), Vector2(lx + (lx - mx) * 0.12, base - 5.0), 3, under.darkened(0.25))
		_r(img, int(lx + (lx - mx) * 0.12) - 5, base - 5, 11, 3, STEEL)
	for s in 30:                                              # the ramp
		_r(img, mx + 22 + s, int(cy) + 16 + s * (base - 4 - int(cy) - 16) / 30, 16, 2, under.lightened(0.12) if s % 4 != 0 else under.darkened(0.3))
	_ell(img, float(mx), cy + 6.0, pw * 0.5 - 4.0, 24.0, under)        # the hull: its underside …
	_ell(img, float(mx), cy + 18.0, 26.0, 8.0, under.darkened(0.4))    # (the emitter under it)
	_ell(img, float(mx), cy + 19.0, 18.0, 5.0, FLUID.darkened(0.3))
	_ell(img, float(mx), cy - 22.0, 36.0, 26.0, Color(0.42, 0.82, 0.78))     # the dome
	_ell(img, mx - 9.0, cy - 30.0, 14.0, 10.0, Color(0.62, 0.95, 0.9))
	_ell(img, mx - 13.0, cy - 34.0, 5.0, 3.0, Color(0.92, 1.0, 0.98))
	_ell(img, float(mx), cy - 2.0, pw * 0.5 - 4.0, 20.0, hull)         # … and its top
	_ell(img, float(mx), cy - 8.0, pw * 0.5 - 30.0, 13.0, hull.lightened(0.14))
	_ell(img, float(mx), cy - 13.0, 44.0, 9.0, hull.darkened(0.18))         # (the collar the dome sits in)
	for q in 18:                                              # plates, and the lights round its rim
		var a := PI + PI * (float(q) + 0.5) / 18.0
		var e := Vector2(cos(a), sin(a))
		var rim := Vector2(mx + cos(a) * (pw * 0.5 - 8.0), cy - 2.0 + absf(sin(a)) * 17.0)
		_r(img, int(rim.x) - 1, int(rim.y), 3, 3, FLUID.lightened(0.2) if q % 2 == 0 else Color(1.0, 0.78, 0.3))
		_line(img, Vector2(mx + e.x * 46.0, cy - 9.0 + absf(e.y) * 6.0), Vector2(mx + e.x * (pw * 0.5 - 14.0), cy - 4.0 + absf(e.y) * 14.0), 1, hull.darkened(0.22))
	_r(img, 8, int(cy) - 1, pw - 16, 1, hull.lightened(0.3))


## A cryo pod, upright: a frosted window, somebody behind it.
static func _cryo_pod(img: Image, pw: int, base: int, sd: int) -> void:
	var shell := Color(0.7, 0.76, 0.83)
	_r(img, 3, base - 6, pw - 6, 6, STEEL)
	_r(img, 3, base - 6, pw - 6, 1, STEEL.lightened(0.3))
	_ell(img, pw * 0.5, base - 34.0, pw * 0.5 - 5.0, 8.0, shell)
	_r(img, 5, base - 34, pw - 10, 29, shell)
	_r(img, 5, base - 34, 2, 29, shell.lightened(0.2))
	_r(img, pw - 7, base - 34, 2, 29, shell.darkened(0.3))
	var win := Color(0.5, 0.78, 0.98)
	_ell(img, pw * 0.5, base - 31.0, pw * 0.5 - 9.0, 5.0, win)
	_r(img, 9, base - 31, pw - 18, 18, win)
	if sd % 4 != 3:                                           # who sleeps in it
		var who := win.darkened(0.55)
		_ell(img, pw * 0.5, base - 28.0, 3.5 + float(sd % 2), 4.0, who)
		_r(img, pw / 2 - 4, base - 24, 8, 11, who)
	for f in 14:                                              # frost
		_p(img, 9 + int(_h2(f, sd, 86) * float(pw - 18)), base - 33 + int(_h2(sd, f, 87) * 20.0), Color(0.95, 0.98, 1.0))
	_r(img, 9, base - 14, pw - 18, 1, Color(0.95, 0.98, 1.0))
	_r(img, 9, base - 11, pw - 18, 4, shell.darkened(0.25))    # its panel
	_p(img, 11, base - 9, Color(0.4, 0.9, 1.0))
	_p(img, 14, base - 9, FLUID if sd % 5 != 0 else Color(1.0, 0.4, 0.3))
	for f2 in 8:
		_p(img, 3 + int(_h2(f2, sd, 88) * float(pw - 6)), base - 2 - int(_h2(sd, f2, 89) * 3.0), Color(0.9, 0.96, 1.0))


## A holding cell: a back wall, posts, a field of force across its front; in some of them somebody (seed).
static func _pen_cell(img: Image, pw: int, base: int, sd: int) -> void:
	var top := base - 70
	_r(img, 0, top, pw, 30, STEEL.lightened(0.1))             # the back wall
	_r(img, 0, top, pw, 2, STEEL.lightened(0.4))
	for x in range(8, pw - 4, 12):
		_r(img, x, top + 3, 1, 26, STEEL.darkened(0.2))
	_r(img, pw - 22, top + 8, 14, 7, Color(0.1, 0.12, 0.14))    # (its number)
	_r(img, pw - 20, top + 10, 4, 3, FLUID)
	_r(img, pw - 14, top + 10, 4, 3, FLUID.darkened(0.3))
	_r(img, 0, top + 30, pw, 40, Color(0.13, 0.15, 0.19))       # the floor inside, a bunk, a drain
	_r(img, 6, top + 33, 30, 8, PALE.darkened(0.3))
	_r(img, 6, top + 41, 30, 2, PALE.darkened(0.55))
	_r(img, pw - 16, top + 52, 6, 4, Color(0.06, 0.07, 0.09))
	match sd % 4:
		1:                                                    # a small green one, sitting
			_ell(img, pw * 0.5 + 6.0, top + 46.0, 5.0, 5.0, Color(0.42, 0.78, 0.36))
			_r(img, pw / 2 + 2, top + 50, 8, 9, Color(0.36, 0.66, 0.3))
			_p(img, pw / 2 + 4, top + 46, Color(0.05, 0.06, 0.05))
			_p(img, pw / 2 + 8, top + 46, Color(0.05, 0.06, 0.05))
			_r(img, pw / 2 + 3, top + 39, 1, 3, Color(0.36, 0.66, 0.3))
			_r(img, pw / 2 + 9, top + 39, 1, 3, Color(0.36, 0.66, 0.3))
		2:                                                    # something slumped on the bunk
			_ell(img, 20.0, top + 34.0, 12.0, 4.0, Color(0.3, 0.26, 0.34))
			_ell(img, 10.0, top + 33.0, 4.0, 3.5, Color(0.36, 0.3, 0.4))
		_:
			pass
	_r(img, 0, top, 4, 70, STEEL)                             # the posts
	_r(img, pw - 4, top, 4, 70, STEEL.darkened(0.2))
	_r(img, 0, top, 1, 70, STEEL.lightened(0.35))
	_r(img, 4, top + 28, pw - 8, 4, STEEL.darkened(0.35))       # the emitters, above and below
	_r(img, 4, base - 4, pw - 8, 4, STEEL.darkened(0.35))
	_a(img, 4, top + 32, pw - 8, 34, Color(STASIS.r, STASIS.g, STASIS.b, 0.22))      # the field
	for x2 in range(6, pw - 6, 5):
		_a(img, x2, top + 32, 1, 34, Color(0.85, 0.7, 1.0, 0.5))
		_p(img, x2, top + 30, Color(0.9, 0.75, 1.0))
		_p(img, x2, base - 3, Color(0.9, 0.75, 1.0))


## Something they took, held in a field of stasis over a pad: a tractor, a cow, a road sign; or the pad alone.
static func _stasis(img: Image, pw: int, base: int, what: String) -> void:
	var mx := pw / 2
	var ph := 16 if what == "sign" else 32
	_ell(img, float(mx), base - ph * 0.5, pw * 0.5 - 1.0, ph * 0.5 - 1.0, STEEL.darkened(0.25))      # the pad
	_ell(img, float(mx), base - ph * 0.5 - 1.0, pw * 0.5 - 4.0, ph * 0.5 - 3.0, STEEL.lightened(0.1))
	_ell(img, float(mx), base - ph * 0.5 - 1.0, pw * 0.5 - 8.0, ph * 0.5 - 5.0, Color(0.3, 0.2, 0.45))
	var fl := base - ph / 2 - 8                               # what floats over it stands on this line
	match what:
		"tractor":
			var red := Color(0.78, 0.22, 0.16)
			_r(img, mx - 26, fl - 20, 28, 12, red)                # the hood
			_r(img, mx - 26, fl - 20, 28, 2, red.lightened(0.25))
			_r(img, mx - 28, fl - 16, 3, 8, Color(0.2, 0.2, 0.22))    # its grille
			_r(img, mx - 18, fl - 30, 2, 10, Color(0.2, 0.2, 0.22))   # the exhaust
			_r(img, mx + 2, fl - 36, 22, 3, red.darkened(0.2))    # the cab: a roof on four posts, glass
			_r(img, mx + 2, fl - 33, 2, 22, Color(0.2, 0.2, 0.22))
			_r(img, mx + 22, fl - 33, 2, 22, Color(0.2, 0.2, 0.22))
			_a(img, mx + 4, fl - 33, 18, 14, Color(0.6, 0.85, 0.95, 0.55))
			_r(img, mx + 2, fl - 14, 26, 8, red.darkened(0.12))
			_r(img, mx + 8, fl - 20, 8, 6, Color(0.15, 0.15, 0.17))   # the seat
			_ell(img, mx + 16.0, fl - 6.0, 13.0, 13.0, Color(0.1, 0.1, 0.12))    # the wheels
			_ell(img, mx + 16.0, fl - 6.0, 6.0, 6.0, Color(0.85, 0.75, 0.25))
			_ell(img, mx + 16.0, fl - 6.0, 2.0, 2.0, Color(0.2, 0.2, 0.22))
			_ell(img, mx - 18.0, fl - 1.0, 7.0, 7.0, Color(0.1, 0.1, 0.12))
			_ell(img, mx - 18.0, fl - 1.0, 3.0, 3.0, Color(0.85, 0.75, 0.25))
		"cow":
			var white := Color(0.93, 0.92, 0.88)
			var black := Color(0.13, 0.12, 0.13)
			_ell(img, float(mx) + 2.0, fl - 14.0, 15.0, 8.0, white)       # the body, its patches
			_ell(img, mx + 8.0, fl - 16.0, 6.0, 4.0, black)
			_ell(img, mx - 4.0, fl - 12.0, 4.0, 3.5, black)
			for lg in [mx - 8, mx - 3, mx + 9, mx + 14]:              # the legs, hanging
				_r(img, lg, fl - 8, 3, 9, white if lg != mx - 3 else black)
				_r(img, lg, fl, 3, 2, black)
			_ell(img, mx + 3.0, fl - 6.0, 4.0, 2.5, Color(0.95, 0.68, 0.7))     # the udder
			_ell(img, mx - 15.0, fl - 19.0, 5.5, 4.5, white)              # the head, lifted
			_r(img, mx - 21, fl - 18, 5, 4, Color(0.95, 0.72, 0.72))
			_p(img, mx - 16, fl - 21, black)
			_r(img, mx - 18, fl - 25, 2, 3, Color(0.85, 0.82, 0.7))
			_r(img, mx - 13, fl - 25, 2, 3, Color(0.85, 0.82, 0.7))
			_r(img, mx - 11, fl - 22, 3, 2, black)                      # (an ear)
			_line(img, Vector2(mx + 17.0, fl - 16.0), Vector2(mx + 21.0, fl - 6.0), 1, black)      # the tail
		"sign":
			_r(img, mx - 1, fl - 22, 2, 26, Color(0.62, 0.64, 0.68))    # its post, bent a little
			var oc := Vector2(mx, fl - 30.0)
			for yy in range(-9, 10):                                  # eight corners, red, a white bar
				for xx in range(-9, 10):
					if absi(xx) + absi(yy) <= 13:
						_p(img, int(oc.x) + xx, int(oc.y) + yy, Color(0.92, 0.94, 0.94) if (absi(xx) + absi(yy) >= 12 or absi(xx) == 9 or absi(yy) == 9) else Color(0.82, 0.14, 0.12))
			_r(img, int(oc.x) - 6, int(oc.y) - 1, 12, 3, Color(0.95, 0.96, 0.96))
		_:
			pass
	var topy := 2                                              # the field: a column of light from the pad up, a ring at its top
	_a(img, 5, topy + 3, pw - 10, base - ph / 2 - topy - 4, Color(STASIS.r, STASIS.g, STASIS.b, 0.16))
	_a(img, 5, topy + 3, 1, base - ph / 2 - topy - 4, Color(0.88, 0.72, 1.0, 0.55))
	_a(img, pw - 6, topy + 3, 1, base - ph / 2 - topy - 4, Color(0.88, 0.72, 1.0, 0.4))
	for q in 40:
		var a := TAU * float(q) / 40.0
		_p(img, int(mx + cos(a) * (pw * 0.5 - 5.0)), int(topy + 3 + sin(a) * 2.5), Color(0.9, 0.78, 1.0))
		if q % 3 == 0:
			_p(img, int(mx + cos(a) * (pw * 0.5 - 6.0)), int(base - ph * 0.5 - 1.0 + sin(a) * (ph * 0.5 - 4.0)), Color(0.9, 0.78, 1.0))
