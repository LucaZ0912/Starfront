class_name BuildArt
extends RefCounted
## 0.7.50.11 (Luz: "the settlements look too chibi, too boxy"): the buildings of a settlement, each one its own – in
## the slanted view, the roof seen from above and the front below it.
## 0.7.51.6 (Luz: "buildings that look like suburban houses won't do at all – real sci-fi buildings, at real sizes"):
## every architecture rebuilt – no pitched roofs, no planks, no shutters, no flower boxes. Built of armour plate,
## printed regolith, composite and glass, sealed, lit by light strips. Architectures (o["arch"]):
##   hab      Independent – an armoured panel block: big plates with bevelled seams, a plated roof with heat-exchanger
##            fins, rounded windows set deep, a pressure door under a plated canopy, cables, a neon sign
##   stack    Independent – hab pods stacked two high, ribbed and armoured, each with its window band and light seam,
##            a steel stair up the side
##   hall     a pressure hall: a half-cylinder of armour segments with glowing seams, its end wall an airlock
##   dome     a habitat dome in rings, a glazed band, portholes, an airlock in hazard stripes
##   terrace  Assembly – pale composite and glass: rounded corners, a curtain wall of glass per storey, a terrace with a
##            glass railing, a roof garden and a small glass dome on top
##   spire    Covenant – dark red-brown dressed stone, a parapet of pointed merlons and a spire on the roof, tall
##            pointed-arch windows lit gold, a red banner, a heavy blast door in a pointed gold frame
##   module   Directorate – white panels with rounded corners, a long window band, a green light strip, a hexagonal
##            crown and solar panels on the roof
##   sinter   (dry worlds) printed regolith in fine layers, rounded, deep slot windows behind metal louvres, a shade
##            sail on masts, sand filters
## o["sealed"] (worlds without breathable air): portholes instead of windows, every door an airlock.
## 0.7.50.13: to scale with the people – about 15 art px a metre: a storey ~2.6 m (38 px), doors 2 m high (30 px).

const OUT := Color(0.09, 0.07, 0.11)
const STOREY := 38                     # art px – a storey, to scale with the people (who are ~27 art px tall)
const DOOR_W := 16
const DOOR_H := 30
const ALIAS := {"prefab": "hab", "container": "stack", "quonset": "hall", "pitched": "terrace", "stone": "spire", "adobe": "sinter"}
const ARCHES := ["hab", "stack", "hall", "dome", "terrace", "spire", "module", "sinter"]


static func paint(img: Image, o: Dictionary, pw: int, total_h: int) -> void:
	var arch := String(o.get("arch", "hab"))
	arch = String(ALIAS.get(arch, arch))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(o.get("seed", 1))
	var roof: Color = o.get("col", Color(0.45, 0.45, 0.5))
	var wall: Color = o.get("col2", Color(0.6, 0.6, 0.62))
	var lamp: Color = o.get("lamp", Color(1.0, 0.85, 0.5))
	var win: Color = o.get("win", Color(1.0, 0.85, 0.55))
	var acc: Color = o.get("acc", Color(0.35, 0.95, 1.0))
	var sealed := bool(o.get("sealed", false))
	var storeys := int(o.get("storeys", 1))
	var fh := 6 + storeys * STOREY                         # the front wall's height (px)
	var base := total_h                                    # the ground line
	var top_face := base - fh                              # where the front starts (the roof's lower edge)
	match arch:
		"stack":
			_stack(img, rng, pw, base, fh, roof, wall, lamp, win, acc, sealed)
			return
		"dome":
			_dome(img, rng, pw, base, fh, roof, wall, lamp, win, acc)
			return
		"hall":
			_hall(img, rng, pw, base, fh, roof, wall, lamp, win, acc, sealed)
			return
	# ---- the roof, seen from above
	match arch:
		"terrace":
			_flat_roof(img, rng, pw, 2, top_face, roof, 6)
			_round_top(img, pw, 2, 6)
		"spire":
			_spire_roof(img, rng, pw, 2, top_face, roof, acc)
		"sinter":
			_flat_roof(img, rng, pw, 2, top_face, roof, 8)
			_round_top(img, pw, 2, 8)
		"module":
			_flat_roof(img, rng, pw, 2, top_face, roof, 4)
			_round_top(img, pw, 2, 4)
		_:
			_plate_roof(img, pw, 2, top_face, roof)
	_roof_clutter(img, rng, arch, pw, 4, top_face - 2, roof, acc)
	# ---- the front
	match arch:
		"spire":
			_stone(img, rng, 0, top_face, pw, fh, wall)
		"terrace":
			_composite(img, 0, top_face, pw, fh, wall)
			_round_top(img, pw, top_face, 4)
		"sinter":
			_printed(img, rng, 0, top_face, pw, fh, wall)
			_round_top(img, pw, top_face, 6)
		"module":
			_r(img, 0, top_face, pw, fh, wall)
			_r(img, 0, top_face, pw, 1, wall.lightened(0.25))
			_r(img, 0, top_face + fh - 3, pw, 3, wall.darkened(0.12))
			for x in range(0, pw, 24):
				_r(img, x, top_face + 2, 1, fh - 5, wall.darkened(0.08))
		_:
			_armour(img, rng, 0, top_face, pw, fh, wall)
	_r(img, 0, top_face, pw, 2, roof.darkened(0.45))              # the roof edge's shadow
	var door_x := int(o.get("door", pw / 2 - 5))
	door_x = clampi(door_x, 6, pw - DOOR_W - 6)
	# ---- the windows, storey by storey
	match arch:
		"module":
			for row2 in storeys:
				var by2 := top_face + 7 + row2 * STOREY
				_r(img, 4, by2, pw - 8, 15, Color(0.12, 0.2, 0.28))
				for gx in range(5, pw - 5, 9):
					if row2 == storeys - 1 and gx > door_x - 10 and gx < door_x + DOOR_W + 4:
						continue
					_r(img, gx, by2 + 1, 7, 13, win.lerp(Color(0.6, 0.85, 1.0), 0.5) if rng.randf() < 0.6 else Color(0.22, 0.34, 0.45))
					_r(img, gx + 1, by2 + 2, 2, 1, Color(0.85, 0.95, 1.0))
				_r(img, 4, by2 + 1, pw - 8, 1, Color(0.8, 0.95, 1.0, 1.0))
				_r(img, 0, by2 + 19, pw, 2, acc)
		"terrace":
			for row3 in storeys:
				var gy := top_face + 6 + row3 * STOREY
				_curtain(img, rng, 4, gy, pw - 8, 24, win, wall, door_x if row3 == storeys - 1 else -999, sealed)
				if row3 < storeys - 1:                           # a terrace slab with a glass railing
					_r(img, 0, gy + 29, pw, 3, wall.lightened(0.15))
					_r(img, 0, gy + 32, pw, 1, wall.darkened(0.3))
					_r(img, 2, gy + 23, pw - 4, 6, Color(0.6, 0.85, 0.95, 0.35))
					_r(img, 2, gy + 23, pw - 4, 1, Color(0.85, 0.95, 1.0))
					for pl in range(10, pw - 8, 26):
						_r(img, pl, gy + 18, 4, 5, Color(0.35, 0.3, 0.26))
						_ellipse(img, pl + 2, gy + 17, 3.5, 3.0, Color(0.3, 0.62, 0.34))
			_r(img, 0, top_face + 3, pw, 1, acc)
		_:
			for row in storeys:
				var wy := top_face + 8 + row * STOREY
				var wx := 6 if arch != "spire" else 12
				var step := 22 if arch != "spire" else 34
				while wx < pw - 16:
					var mg := 26 if arch == "sinter" else 16
					if row == storeys - 1 and wx > door_x - mg and wx < door_x + DOOR_W + mg - 10:
						wx += 3
						continue
					_window(img, rng, wx, wy, arch, win, wall, sealed)
					wx += step + rng.randi_range(0, 4)
	# ---- the door
	_door(img, rng, door_x, base - DOOR_H, arch, lamp, wall, acc, sealed)
	# ---- what makes it lived in and now: light strips, panels, signs, cables
	if arch in ["hab", "module", "sinter"]:
		_r(img, 0, top_face + 3, pw, 1, acc)
		_r(img, 0, top_face + 4, pw, 1, acc.darkened(0.5))
	if arch != "spire":
		var pnl := door_x + DOOR_W + 5 if door_x + DOOR_W + 11 < pw else door_x - 10
		_r(img, pnl, base - 20, 5, 8, Color(0.14, 0.15, 0.18))
		_r(img, pnl + 1, base - 19, 3, 3, acc)
		_r(img, pnl + 1, base - 15, 3, 1, Color(0.4, 1.0, 0.55))
	_wall_clutter(img, rng, arch, pw, top_face, base, wall, lamp, acc, door_x)
	# grime along the foot – or the Covenant's plinth
	if arch == "spire":
		_r(img, 0, base - 5, pw, 5, wall.darkened(0.3))
		_r(img, 0, base - 5, pw, 1, wall.lightened(0.1))
	else:
		_r(img, 0, base - 3, pw, 3, wall.darkened(0.25))
		for x in pw:
			if rng.randf() < 0.4:
				_p(img, x, base - 4, wall.darkened(0.32))


# ---------------------------------------------------------------- roofs

static func _plate_roof(img: Image, pw: int, y0: int, y1: int, roof: Color) -> void:
	## an armoured flat roof – big plates, bevelled edges, the rim raised
	_r(img, 0, y0, pw, y1 - y0, roof)
	for x in range(0, pw, 22):
		_r(img, x, y0, 1, y1 - y0, roof.darkened(0.22))
		_r(img, x + 1, y0, 1, y1 - y0, roof.lightened(0.1))
	for y in range(y0 + 10, y1, 11):
		_r(img, 0, y, pw, 1, roof.darkened(0.18))
	_r(img, 0, y0, pw, 2, roof.lightened(0.28))
	_r(img, 0, y0, 2, y1 - y0, roof.lightened(0.15))
	_r(img, pw - 2, y0, 2, y1 - y0, roof.darkened(0.25))
	_r(img, 0, y1 - 2, pw, 2, roof.darkened(0.2))


static func _flat_roof(img: Image, rng: RandomNumberGenerator, pw: int, y0: int, y1: int, roof: Color, rim: int) -> void:
	_r(img, 0, y0, pw, y1 - y0, roof)
	for i in (pw * (y1 - y0)) / 30:
		_p(img, rng.randi_range(2, pw - 3), rng.randi_range(y0 + 2, y1 - 2), roof.darkened(0.05) if rng.randf() < 0.5 else roof.lightened(0.04))
	_r(img, 0, y0, pw, 2, roof.lightened(0.2))
	_r(img, 0, y0, 2, y1 - y0, roof.lightened(0.1))
	_r(img, pw - 2, y0, 2, y1 - y0, roof.darkened(0.15))
	_r(img, 2, y0 + 2, pw - 4, 1, roof.darkened(0.12))
	_r(img, 0, y1 - 2, pw, 2, roof.darkened(0.18))
	if rim > 5:                                                  # a soft rounded rim
		_r(img, 3, y0 + 3, pw - 6, 1, roof.lightened(0.08))


static func _spire_roof(img: Image, rng: RandomNumberGenerator, pw: int, y0: int, y1: int, roof: Color, acc: Color) -> void:
	## the Covenant: a dark stone roof behind a parapet of pointed merlons, a spire rising from its middle
	var rt := y0 + 10
	_r(img, 0, rt, pw, y1 - rt, roof)
	for x in range(0, pw, 8):
		_r(img, x, rt, 1, y1 - rt, roof.darkened(0.12))
	_r(img, 0, rt, pw, 2, roof.lightened(0.15))
	for x2 in range(0, pw - 3, 8):                               # the merlons along the front edge, pointed
		for k in 4:
			_r(img, x2 + k, y1 - 4 - k, 7 - k * 2, 1, roof.lightened(0.12))
		_r(img, x2, y1 - 4, 7, 2, roof.lightened(0.05))
	# the spire: a pointed obelisk in the middle, a gold band, its light on top
	var sx := pw / 2
	var sh := y1 - y0 - 2
	var sb := y1 - 3
	for yy in sh:
		var ww := maxi(1, int(9.0 * (float(yy) / sh)) + 1)
		var c := roof.lightened(0.18) if yy % 6 != 0 else roof.darkened(0.1)
		_r(img, sx - ww, sb - sh + yy, ww, 1, c)
		_r(img, sx, sb - sh + yy, ww, 1, c.darkened(0.25))
	_r(img, sx, sb - sh + 4, 1, sh - 6, Color(1.0, 0.75, 0.35))      # a gold line of light up its face
	_r(img, sx - 7, sb - sh / 3, 14, 2, Color(0.95, 0.75, 0.3))
	_r(img, sx - 1, sb - sh - 2, 2, 2, Color(1.0, 0.35, 0.25))


static func _round_top(img: Image, pw: int, y0: int, r: int) -> void:
	for y in r:
		var cut := r - int(sqrt(float(r * r - (r - y) * (r - y))))
		for x in cut:
			_p(img, x, y0 + y, Color(0, 0, 0, 0))
			_p(img, pw - 1 - x, y0 + y, Color(0, 0, 0, 0))


static func _roof_clutter(img: Image, rng: RandomNumberGenerator, arch: String, pw: int, y0: int, y1: int, roof: Color, acc: Color) -> void:
	var kinds: Array
	match arch:
		"terrace":
			kinds = ["garden", "garden", "glassdome", "solar", "skylight"]
		"spire":
			kinds = ["vents", "dish"]
		"module":
			kinds = ["hexcrown", "solar", "solar", "dish"]
		"sinter":
			kinds = ["solar", "filter", "tank", "dish"]
		_:
			kinds = ["fins", "antenna", "dish", "vents", "tank", "fins", "solar"]
	var n := maxi(1, pw / 26) + 1
	var used := []
	if arch == "module":                                          # the Directorate's hexagonal crown, always
		_hex_crown(img, pw / 2 - 9, y0 + 1, acc)
		used.append(pw / 2 - 9)
	for i in n:
		var kind: String = kinds[rng.randi() % kinds.size()]
		var x := rng.randi_range(3, maxi(4, pw - 22))
		var y := rng.randi_range(y0 + 1, maxi(y0 + 2, y1 - 11))
		var clash := false
		for u in used:
			if absi(int(u) - x) < 22:
				clash = true
		if clash or (arch == "spire" and absi(x + 6 - pw / 2) < 14):
			continue
		used.append(x)
		match kind:
			"fins":                                               # a heat exchanger – a box of thin fins
				_r(img, x, y, 18, 9, roof.darkened(0.3))
				for f in range(x + 1, x + 17, 2):
					_r(img, f, y + 1, 1, 7, roof.lightened(0.25))
				_r(img, x, y + 8, 18, 1, roof.darkened(0.45))
				_r(img, x + 16, y + 1, 1, 1, acc)
			"antenna":                                            # a comm mast, its light
				_r(img, x + 3, y - 10, 1, 14, Color(0.25, 0.25, 0.28))
				_r(img, x, y - 6, 7, 1, Color(0.3, 0.3, 0.33))
				_r(img, x + 1, y - 2, 5, 1, Color(0.3, 0.3, 0.33))
				_p(img, x + 3, y - 11, Color(1.0, 0.3, 0.25))
				_r(img, x + 1, y + 3, 5, 2, Color(0.2, 0.2, 0.23))
			"dish":
				_ellipse(img, x + 6, y + 4, 6, 4, Color(0.8, 0.82, 0.85))
				_ellipse(img, x + 6, y + 3, 3.5, 2.2, Color(0.6, 0.62, 0.68))
				_r(img, x + 6, y + 6, 1, 4, Color(0.3, 0.3, 0.33))
				_p(img, x + 6, y + 2, acc)
			"vents":
				for k2 in 3:
					_r(img, x + k2 * 5, y + 2, 4, 4, roof.darkened(0.35))
					_r(img, x + k2 * 5, y + 2, 4, 1, roof.lightened(0.15))
			"tank":                                               # a pressure tank lying on its cradle
				_r(img, x, y + 1, 16, 7, Color(0.62, 0.66, 0.7))
				_ellipse(img, x, y + 4.5, 2.5, 3.5, Color(0.55, 0.58, 0.62))
				_ellipse(img, x + 16, y + 4.5, 2.5, 3.5, Color(0.5, 0.53, 0.57))
				_r(img, x, y + 2, 16, 1, Color(0.82, 0.86, 0.9))
				_r(img, x + 5, y + 1, 1, 7, Color(0.35, 0.95, 1.0))
			"solar":
				for k in 3:
					_r(img, x + k * 6, y, 5, 8, Color(0.14, 0.2, 0.42))
					_r(img, x + k * 6, y, 5, 1, Color(0.5, 0.65, 0.9))
					_r(img, x + k * 6 + 2, y + 1, 1, 7, Color(0.2, 0.3, 0.55))
			"skylight":
				_r(img, x, y, 14, 7, Color(0.45, 0.65, 0.78))
				_r(img, x, y, 14, 1, Color(0.85, 0.95, 1.0))
				_r(img, x + 7, y, 1, 7, Color(0.75, 0.85, 0.9))
			"garden":                                             # a roof garden in its bed
				_r(img, x, y + 1, 20, 8, Color(0.4, 0.42, 0.44))
				_r(img, x + 1, y + 2, 18, 6, Color(0.3, 0.24, 0.18))
				for k3 in 4:
					_ellipse(img, x + 3 + k3 * 5, y + 4, 2.8, 2.5, Color(0.3, 0.6, 0.32).lightened(0.08 * (k3 % 2)))
			"glassdome":
				_ellipse(img, x + 8, y + 5, 8, 5.5, Color(0.5, 0.75, 0.88, 1.0))
				_ellipse(img, x + 6, y + 3, 3.5, 2, Color(0.85, 0.95, 1.0))
				_r(img, x, y + 9, 17, 1, Color(0.6, 0.62, 0.64))
			"filter":                                             # a sand filter stack
				_r(img, x, y, 10, 9, roof.darkened(0.2))
				for k4 in 3:
					_r(img, x + 1, y + 1 + k4 * 3, 8, 1, roof.darkened(0.4))
				_r(img, x + 10, y + 3, 4, 2, Color(0.45, 0.45, 0.48))


static func _hex_crown(img: Image, x: int, y: int, acc: Color) -> void:
	## a hexagonal lantern on a Directorate roof – white, a green band of light
	for k in 4:
		_r(img, x + 4 - k, y + k, 10 + k * 2, 1, Color(0.95, 0.97, 0.97))
	_r(img, x, y + 4, 18, 4, Color(0.92, 0.94, 0.94))
	_r(img, x, y + 6, 18, 1, acc)
	for k2 in 4:
		_r(img, x + 1 + k2, y + 8 + k2, 16 - k2 * 2, 1, Color(0.78, 0.8, 0.82))
	_r(img, x + 7, y + 1, 4, 2, Color(0.55, 0.8, 0.9))


# ---------------------------------------------------------------- walls

static func _armour(img: Image, rng: RandomNumberGenerator, x0: int, y0: int, w: int, h: int, wall: Color) -> void:
	## big armour plates with bevelled seams – their rows offset, a bolt at each corner
	_r(img, x0, y0, w, h, wall)
	var rows := maxi(1, h / 20)
	var rh := h / rows
	for r in rows:
		var yy := y0 + r * rh
		var off := 0 if r % 2 == 0 else 14
		_r(img, x0, yy, w, 1, wall.darkened(0.25))
		_r(img, x0, yy + 1, w, 1, wall.lightened(0.12))
		for x in range(x0 - off, x0 + w, 28):
			if x > x0:
				_r(img, x, yy, 1, rh, wall.darkened(0.22))
				_r(img, x + 1, yy, 1, rh, wall.lightened(0.08))
			var tone := wall.lightened(rng.randf_range(-0.04, 0.04))
			_r(img, maxi(x0, x + 2), yy + 2, 24, rh - 3, tone)
			_p(img, x + 3, yy + 3, wall.lightened(0.25))
			_p(img, x + 25, yy + 3, wall.lightened(0.25))
	_r(img, x0, y0 + h - 5, w, 1, wall.darkened(0.15))


static func _composite(img: Image, x0: int, y0: int, w: int, h: int, wall: Color) -> void:
	## the Assembly: pale composite, smooth, light from above
	_r(img, x0, y0, w, h, wall)
	_r(img, x0, y0, w, 2, wall.lightened(0.15))
	_r(img, x0, y0, 3, h, wall.lightened(0.08))
	_r(img, x0 + w - 3, y0, 3, h, wall.darkened(0.08))


static func _printed(img: Image, rng: RandomNumberGenerator, x0: int, y0: int, w: int, h: int, wall: Color) -> void:
	## printed regolith: one smooth mass in faint layers, shaded round at its ends, a sun lip over the windows
	_r(img, x0, y0, w, h, wall)
	for y in range(y0, y0 + h, 3):
		_r(img, x0, y, w, 1, wall.darkened(0.035))
	for x in 6:                                                 # the rounded ends catch less light
		_r(img, x0 + x, y0, 1, h, wall.darkened(0.12 - x * 0.02))
		_r(img, x0 + w - 1 - x, y0, 1, h, wall.darkened(0.2 - x * 0.03))
	for i in (w * h) / 60:
		_p(img, x0 + rng.randi() % w, y0 + rng.randi() % h, wall.lightened(0.06))
	_r(img, x0, y0 + 5, w, 3, wall.lightened(0.1))               # the sun lip
	_r(img, x0, y0 + 8, w, 2, wall.darkened(0.3))


static func _stone(img: Image, rng: RandomNumberGenerator, x0: int, y0: int, w: int, h: int, wall: Color) -> void:
	## the Covenant: great smooth slabs of dark stone, buttresses between the bays with a gold line of light
	_r(img, x0, y0, w, h, wall)
	var row := 0
	for y in range(y0 + 6, y0 + h, 13):
		var off := 0 if row % 2 == 0 else 20
		for x in range(x0 - off, x0 + w, 40):
			var sc := wall.lightened(rng.randf_range(-0.03, 0.03))
			_r(img, x + 1, y + 1, 39, 12, sc)
			_r(img, x + 1, y + 1, 39, 1, sc.lightened(0.06))
		_r(img, x0, y, w, 1, wall.darkened(0.16))
		row += 1
	for bx in range(x0 + 1, x0 + w - 4, 34):                     # the buttresses
		_r(img, bx, y0 + 4, 5, h - 4, wall.darkened(0.2))
		_r(img, bx, y0 + 4, 1, h - 4, wall.lightened(0.1))
		_r(img, bx + 2, y0 + 8, 1, h - 12, Color(1.0, 0.75, 0.35))
		for k in 3:
			_r(img, bx + k, y0 + 4 - k, 5 - k * 2, 1, wall.darkened(0.1))
	_r(img, x0, y0 + 2, w, 3, wall.darkened(0.25))              # a cornice under the parapet
	_r(img, x0, y0 + 5, w, 1, Color(1.0, 0.75, 0.35, 0.8))


# ---------------------------------------------------------------- windows, doors, things on the walls

static func _window(img: Image, rng: RandomNumberGenerator, x: int, y: int, arch: String, win: Color, wall: Color, sealed: bool) -> void:
	var lit := rng.randf() < 0.65
	var glass := win if lit else Color(0.14, 0.19, 0.27)
	if sealed and arch != "spire":
		_porthole(img, x + 6, y + 8, 6.5, glass, lit, wall)
		return
	match arch:
		"spire":                                                # a pair of tall lancet slits, lit gold
			var gl := glass.lerp(Color(1.0, 0.72, 0.3), 0.65) if lit else glass
			for k in 2:
				var lx := x + 1 + k * 6
				_r(img, lx - 1, y + 3, 6, 25, Color(0.08, 0.05, 0.05))
				_r(img, lx, y + 4, 4, 24, gl)
				_r(img, lx + 1, y + 2, 2, 2, Color(0.08, 0.05, 0.05))
				_p(img, lx + 1, y + 3, gl)
				_p(img, lx + 2, y + 3, gl)
				_r(img, lx, y + 4, 1, 24, gl.lightened(0.3))
			_r(img, x, y + 28, 12, 1, Color(1.0, 0.75, 0.35))
		"sinter":                                               # a deep slot behind metal louvres
			_r(img, x, y + 3, 12, 16, wall.darkened(0.35))
			_r(img, x + 2, y + 5, 8, 12, glass)
			for l in range(y + 6, y + 17, 3):
				_r(img, x + 1, l, 10, 1, Color(0.5, 0.48, 0.45))
			_r(img, x, y + 3, 12, 1, wall.darkened(0.5))
			_r(img, x - 1, y + 19, 14, 1, wall.lightened(0.12))
		_:                                                      # a wide rounded pane set deep in its armoured frame
			_rrect(img, x - 2, y + 1, 19, 15, wall.darkened(0.42), 2)
			_rrect(img, x, y + 3, 15, 11, glass, 1)
			_r(img, x, y + 3, 15, 2, glass.darkened(0.25))       # the frame's shadow on the glass
			if lit:
				_r(img, x + 1, y + 10, 13, 3, glass.darkened(0.1))
			_r(img, x + 1, y + 6, 6, 1, Color(1, 1, 1, 0.4))
			_r(img, x - 2, y + 15, 18, 1, Color(0.35, 0.95, 1.0, 0.55) if lit else wall.darkened(0.3))


static func _porthole(img: Image, cx: int, cy: int, rad: float, glass: Color, lit: bool, wall: Color) -> void:
	_ellipse(img, cx, cy, rad + 2.0, rad + 2.0, wall.darkened(0.45))
	_ellipse(img, cx, cy, rad + 1.0, rad + 1.0, Color(0.6, 0.62, 0.66))
	_ellipse(img, cx, cy, rad - 0.5, rad - 0.5, glass)
	for a in 8:                                                 # the bolts round its ring
		_p(img, int(cx + cos(a * PI / 4.0) * (rad + 1.0)), int(cy + sin(a * PI / 4.0) * (rad + 1.0)), wall.darkened(0.6))
	_r(img, cx - 3, cy - 3, 2, 2, Color(1, 1, 1, 0.6))


static func _curtain(img: Image, rng: RandomNumberGenerator, x0: int, y0: int, w: int, h: int, win: Color, wall: Color, door_x: int, sealed: bool) -> void:
	## the Assembly's glass front: tall panes in thin frames, the sky and the rooms behind
	_r(img, x0, y0, w, h, Color(0.2, 0.26, 0.32))
	var px := x0 + 1
	while px < x0 + w - 2:
		var pwid := mini(11, x0 + w - 1 - px)
		if door_x > -999 and px + pwid > door_x - 4 and px < door_x + DOOR_W + 4:
			_r(img, px, y0 + 1, pwid, h - 2, wall)
			px += pwid + 1
			continue
		var lit := rng.randf() < 0.55
		var g := win.lerp(Color(1, 1, 1), 0.15) if lit else Color(0.38, 0.55, 0.68)
		_r(img, px, y0 + 1, pwid, h - 2, g)
		_r(img, px, y0 + 1, pwid, 3, g.lightened(0.25))
		if not lit:
			for d in 6:
				_p(img, px + 2 + d, y0 + 12 - d, Color(0.75, 0.88, 0.96))
		px += pwid + 1
	_r(img, x0, y0 + h / 2, w, 1, Color(0.5, 0.56, 0.6, 0.6))
	if sealed:                                                  # the glass doubled, a pressure frame
		_r(img, x0, y0, w, 1, Color(0.65, 0.68, 0.72))
		_r(img, x0, y0 + h - 1, w, 1, Color(0.65, 0.68, 0.72))


static func _door(img: Image, rng: RandomNumberGenerator, x: int, y: int, arch: String, lamp: Color, wall: Color, acc: Color, sealed: bool) -> void:
	var w := DOOR_W
	var h := DOOR_H
	if sealed and arch != "spire":
		_airlock(img, x, y, wall, acc, lamp)
		return
	match arch:
		"spire":                                                # a blast door in a pointed gold frame
			_r(img, x - 3, y - 2, w + 6, h + 2, Color(0.85, 0.65, 0.3))
			for k in 6:
				_r(img, x - 3 + k, y - 2 - k, w + 6 - k * 2, 1, Color(0.85, 0.65, 0.3))
			_r(img, x - 1, y, w + 2, h, Color(0.12, 0.08, 0.08))
			for k2 in 5:
				_r(img, x - 1 + k2, y - k2, w + 2 - k2 * 2, 1, Color(0.12, 0.08, 0.08))
			_r(img, x, y + 1, w / 2 - 1, h - 1, Color(0.3, 0.28, 0.3))           # two heavy metal leaves
			_r(img, x + w / 2, y + 1, w / 2, h - 1, Color(0.25, 0.23, 0.25))
			_r(img, x, y + 1, w, 1, Color(0.45, 0.42, 0.44))
			_r(img, x + 2, y + 12, w - 4, 2, Color(0.18, 0.16, 0.17))
			_r(img, x + 2, y + 22, w - 4, 2, Color(0.18, 0.16, 0.17))
			_r(img, x + w / 2 - 1, y + 1, 1, h - 1, Color(1.0, 0.75, 0.35))
			_r(img, x + 3, y + 6, 2, 2, Color(1.0, 0.75, 0.35))
			_r(img, x + w - 5, y + 6, 2, 2, Color(1.0, 0.75, 0.35))
			_r(img, x - 2, y + h, w + 4, 2, wall.lightened(0.15))
			return
		"terrace":                                              # a glass sliding door
			_r(img, x - 1, y - 1, w + 2, h + 1, wall.darkened(0.3))
			_r(img, x, y, w, h, Color(0.45, 0.65, 0.78))
			_r(img, x + w / 2, y, 1, h, wall.darkened(0.2))
			_r(img, x + 1, y + 1, w - 2, 2, Color(0.85, 0.95, 1.0))
			for d in 6:
				_p(img, x + 2 + d, y + 14 - d, Color(0.85, 0.95, 1.0))
			_r(img, x - 6, y - 5, w + 12, 3, wall.lightened(0.15))   # a thin cantilevered canopy
			_r(img, x - 6, y - 2, w + 12, 1, acc)
			_r(img, x - 2, y + h, w + 4, 2, wall.lightened(0.15))
			return
	# a pressure door: two leaves under a plated canopy, a light in the seam
	_rrect(img, x - 3, y - 3, w + 6, h + 3, wall.darkened(0.42), 3)
	_r(img, x, y, w, h, Color(0.2, 0.22, 0.26))
	_r(img, x + 1, y + 1, w / 2 - 1, h - 1, Color(0.33, 0.36, 0.41))
	_r(img, x + w / 2 + 1, y + 1, w / 2 - 2, h - 1, Color(0.29, 0.32, 0.37))
	_r(img, x + 2, y + 5, w / 2 - 3, 6, Color(0.4, 0.58, 0.68))
	_r(img, x + w / 2 + 2, y + 5, w / 2 - 4, 6, Color(0.36, 0.52, 0.62))
	_r(img, x + w / 2, y + 1, 1, h - 1, acc)
	for st in range(y + 16, y + h - 2, 4):                      # hazard chevrons at the foot
		_r(img, x + 1, st, 2, 2, Color(0.95, 0.78, 0.15))
		_r(img, x + w - 3, st, 2, 2, Color(0.95, 0.78, 0.15))
	_r(img, x - 6, y - 7, w + 12, 3, wall.darkened(0.45))       # the plated canopy
	_r(img, x - 6, y - 4, w + 12, 1, acc)
	_r(img, x + w / 2 - 2, y - 10, 5, 2, lamp)
	_r(img, x - 2, y + h, w + 4, 2, wall.lightened(0.12))


static func _airlock(img: Image, x: int, y: int, wall: Color, acc: Color, lamp: Color) -> void:
	## an airlock: a heavy frame striped in hazard colours, a round-cornered hatch, its status light
	var w := DOOR_W
	var h := DOOR_H
	_rrect(img, x - 5, y - 5, w + 10, h + 5, Color(0.18, 0.19, 0.22), 4)
	for k in w + 10:
		var c := Color(0.95, 0.78, 0.15) if ((k + 2) / 3) % 2 == 0 else Color(0.14, 0.14, 0.16)
		_r(img, x - 5 + k, y - 5, 1, 2, c)
	_rrect(img, x, y, w, h, Color(0.42, 0.45, 0.5), 3)
	_r(img, x + 2, y + 2, w - 4, h - 4, Color(0.36, 0.39, 0.44))
	_ellipse(img, x + w * 0.5, y + 8.0, 4.0, 4.0, Color(0.22, 0.3, 0.38))
	_ellipse(img, x + w * 0.5, y + 8.0, 2.5, 2.5, Color(0.5, 0.75, 0.9))
	_r(img, x + w / 2 - 4, y + 16, 8, 2, Color(0.25, 0.27, 0.3))   # its wheel lock
	_r(img, x + w / 2 - 1, y + 13, 2, 8, Color(0.25, 0.27, 0.3))
	_r(img, x - 4, y + 4, 2, h - 6, Color(0.95, 0.78, 0.15))
	_r(img, x + w + 2, y + 4, 2, h - 6, Color(0.95, 0.78, 0.15))
	_r(img, x + w + 2, y - 2, 3, 3, Color(0.4, 1.0, 0.55))         # pressurised: green
	_r(img, x + w / 2 - 2, y - 9, 5, 2, lamp)
	_r(img, x - 3, y + h, w + 6, 2, Color(0.3, 0.32, 0.35))


static func _wall_clutter(img: Image, rng: RandomNumberGenerator, arch: String, pw: int, y0: int, y1: int, wall: Color, lamp: Color, acc: Color, door_x: int) -> void:
	var far := 3 if door_x > pw / 2 else pw - 5
	match arch:
		"hab", "module", "sinter":                                # a conduit down the wall, its light
			_r(img, far, y0 + 3, 3, y1 - y0 - 3, wall.darkened(0.32))
			_r(img, far, y0 + 3, 1, y1 - y0 - 3, wall.lightened(0.12))
			for cl in range(y0 + 10, y1 - 4, 14):
				_r(img, far - 1, cl, 5, 2, wall.darkened(0.45))
		"spire":                                                  # a red banner hanging between the bays
			var bx := far - 4 if far < pw / 2 else far - 8
			bx = clampi(bx, 2, pw - 14)
			_r(img, bx, y0 + 6, 12, 2, Color(0.85, 0.65, 0.3))
			_r(img, bx + 1, y0 + 8, 10, 26, Color(0.62, 0.1, 0.12))
			_r(img, bx + 1, y0 + 8, 1, 26, Color(0.75, 0.18, 0.18))
			for k in 4:
				_r(img, bx + 1 + k, y0 + 34 + k, 10 - k * 2, 1, Color(0.62, 0.1, 0.12))
			_r(img, bx + 5, y0 + 13, 2, 10, Color(0.95, 0.75, 0.3))    # the sun road
			_r(img, bx + 3, y0 + 16, 6, 2, Color(0.95, 0.75, 0.3))
	if arch == "hab" and rng.randf() < 0.75:                       # a neon sign, cables sagging along the front
		var sx := rng.randi_range(4, pw - 26)
		if absi(sx - door_x) > 18:
			_r(img, sx, y0 + 6, 22, 6, Color(0.05, 0.05, 0.08))
			var nc := Color.from_hsv(rng.randf(), 0.75, 1.0)
			_r(img, sx + 1, y0 + 7, 20, 1, nc)
			_r(img, sx + 1, y0 + 10, 20, 1, nc)
			for g in range(sx + 3, sx + 19, 4):
				_r(img, g, y0 + 8, 2, 2, nc.lightened(0.3))
	if arch == "hab":
		var cy := y0 + 3
		for x in pw:
			var sag := int(3.0 * sin(PI * float(x % 40) / 40.0))
			_p(img, x, cy + sag, Color(0.08, 0.08, 0.1))
	if arch == "sinter":                                           # a rounded portal round the door, sand filters by it
		_rrect(img, door_x - 7, y1 - DOOR_H - 9, DOOR_W + 14, DOOR_H + 9, wall.darkened(0.16), 7)
		_rrect(img, door_x - 5, y1 - DOOR_H - 7, DOOR_W + 10, DOOR_H + 7, wall.lightened(0.05), 6)
		_r(img, door_x - 5, y1 - DOOR_H - 7, DOOR_W + 10, 1, wall.lightened(0.18))
		_door(img, rng, door_x, y1 - DOOR_H, "hab", lamp, wall, acc, false)
		var fx := door_x + DOOR_W + 12 if door_x + DOOR_W + 24 < pw else door_x - 22
		_rrect(img, fx, y1 - 20, 9, 20, Color(0.5, 0.48, 0.45), 2)
		for k5 in 4:
			_r(img, fx + 1, y1 - 18 + k5 * 4, 7, 2, Color(0.3, 0.29, 0.28))


# ---------------------------------------------------------------- whole buildings of other shapes

const CONT_H := 38                     # a hab pod stands 2.6 m


static func _stack(img: Image, rng: RandomNumberGenerator, pw: int, base: int, fh: int, roof: Color, wall: Color, lamp: Color, win: Color, acc: Color, sealed: bool) -> void:
	var cols := [Color(0.62, 0.24, 0.2), Color(0.22, 0.4, 0.58), Color(0.72, 0.55, 0.18), Color(0.3, 0.46, 0.34), Color(0.5, 0.52, 0.56)]
	var levels := 2
	var x := 0
	var door_cx := pw / 2
	while x < pw - 14:
		var cw := mini(pw - 12 - x, rng.randi_range(26, 36))
		for lv in levels:
			var c: Color = cols[rng.randi() % cols.size()]
			var y_front := base - (lv + 1) * CONT_H
			var y_top := y_front - (img.get_height() - fh - 8) / levels
			if lv == levels - 1 and rng.randf() < 0.3:
				continue
			_r(img, x, y_top, cw, y_front - y_top, c.lightened(0.08))          # its top, ribbed
			for rx in range(x, x + cw, 4):
				_r(img, rx, y_top, 1, y_front - y_top, c.darkened(0.1))
			_rrect(img, x, y_front, cw, CONT_H, c, 2)                           # its side, armoured ribs
			for rx2 in range(x + 2, x + cw - 2, 4):
				_r(img, rx2, y_front + 3, 1, CONT_H - 6, c.darkened(0.15))
			_r(img, x, y_front, cw, 2, c.lightened(0.25))
			_r(img, x, y_front + CONT_H - 3, cw, 3, c.darkened(0.35))
			_r(img, x, y_front + CONT_H - 4, cw, 1, acc)                          # its light seam
			_r(img, x, y_front, 2, CONT_H, c.darkened(0.35))
			_r(img, x + cw - 2, y_front, 2, CONT_H, c.darkened(0.35))
			var mid := x + cw / 2
			if lv == 0 and absi(mid - door_cx) < cw / 2 + 4:
				continue
			if sealed:
				_porthole(img, mid, y_front + 15, 5.5, win if rng.randf() < 0.6 else Color(0.14, 0.19, 0.27), true, c)
			else:                                                                 # a window band
				_rrect(img, x + 4, y_front + 8, cw - 8, 12, c.darkened(0.45), 2)
				_r(img, x + 5, y_front + 9, cw - 10, 10, win if rng.randf() < 0.6 else Color(0.18, 0.24, 0.32))
				_r(img, x + 5, y_front + 9, cw - 10, 1, Color(1, 1, 1, 0.5))
		x += cw + 1
	_door(img, rng, door_cx - DOOR_W / 2, base - DOOR_H, "hab", lamp, wall, acc, sealed)
	# a steel stair up the side to the upper pods
	var sx := pw - 11
	_r(img, sx, base - CONT_H * 2, 2, CONT_H * 2, Color(0.28, 0.29, 0.32))
	_r(img, sx + 9, base - CONT_H * 2, 1, CONT_H * 2, Color(0.28, 0.29, 0.32))
	for k in 14:
		_r(img, sx + 2, base - 4 - k * 5, 7, 1, Color(0.42, 0.43, 0.46))
	_r(img, sx, base - CONT_H * 2, 11, 1, Color(0.95, 0.78, 0.15))


static func _dome(img: Image, rng: RandomNumberGenerator, pw: int, base: int, fh: int, roof: Color, wall: Color, lamp: Color, win: Color, acc: Color) -> void:
	var h := img.get_height()
	var cx := pw * 0.5
	var ry := float(h - 6) * 0.5
	var cy := float(base) - ry
	_ellipse(img, cx, cy + 3.0, pw * 0.5, ry, roof.darkened(0.35))
	_ellipse(img, cx, cy, pw * 0.5 - 1.0, ry - 1.0, roof)
	_ellipse(img, cx - pw * 0.12, cy - ry * 0.35, pw * 0.22, ry * 0.3, roof.lightened(0.15))
	_ellipse(img, cx, cy - ry * 0.55, pw * 0.2, ry * 0.22, Color(0.45, 0.68, 0.82))     # its glazed crown
	_ellipse(img, cx - pw * 0.06, cy - ry * 0.62, pw * 0.07, ry * 0.07, Color(0.85, 0.95, 1.0))
	for k in range(1, 4):                                       # its rings, a light seam in the lowest
		var yy := int(cy - ry + ry * 2.0 * k / 4.0)
		for x in pw:
			var dx := (x + 0.5 - cx) / (pw * 0.5 - 1.0)
			if absf(dx) < sqrt(maxf(0.0, 1.0 - pow((yy - cy) / (ry - 1.0), 2.0))):
				_p(img, x, yy, acc if k == 3 else roof.darkened(0.15))
	for p in 4:                                                 # portholes
		var a := -0.9 + p * 0.6
		var px := cx + sin(a) * pw * 0.36
		var py := cy + ry * 0.35
		if absf(px - cx) < 16:
			continue
		_porthole(img, int(px), int(py), 4.5, win if rng.randf() < 0.6 else Color(0.18, 0.24, 0.32), true, roof)
	_airlock(img, int(cx) - DOOR_W / 2, base - DOOR_H, roof, acc, lamp)


static func _hall(img: Image, rng: RandomNumberGenerator, pw: int, base: int, fh: int, roof: Color, wall: Color, lamp: Color, win: Color, acc: Color, sealed: bool) -> void:
	## a pressure hall: a half-cylinder of armour segments, glowing seams between them, the end wall an airlock
	var top := 4
	var front := base - fh
	_r(img, 0, top + 4, pw, front - top - 4, roof)
	for y in range(top + 4, front):
		var k := float(y - top - 4) / maxf(1.0, front - top - 4)
		_r(img, 0, y, pw, 1, roof.lightened(0.15 * (1.0 - absf(k - 0.35) * 2.0)))
	for x in range(0, pw, 14):                                  # the segments, a light in each seam
		_r(img, x, top + 4, 2, front - top - 4, roof.darkened(0.3))
		_r(img, x + 2, top + 4, 1, front - top - 4, roof.lightened(0.15))
		_r(img, x, top + 6 + (front - top) / 3, 2, 3, acc)
	_ellipse(img, pw * 0.5, top + 5.0, pw * 0.5, 4.0, roof.lightened(0.1))
	_ellipse(img, pw * 0.5, float(front + 4), pw * 0.5 - 1.0, 8.0, wall.darkened(0.1))
	_armour(img, rng, 0, front + 4, pw, fh - 4, wall)
	_r(img, 0, front + 4, pw, 1, acc)
	_window(img, rng, 8, front + 12, "hab", win, wall, sealed)
	_window(img, rng, pw - 20, front + 12, "hab", win, wall, sealed)
	if sealed:
		_airlock(img, pw / 2 - DOOR_W / 2, base - DOOR_H, wall, acc, lamp)
	else:
		_door(img, rng, pw / 2 - DOOR_W / 2, base - DOOR_H, "hab", lamp, wall, acc, false)


# ---------------------------------------------------------------- helpers

static func _r(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	var r := Rect2i(x, y, w, h).intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	if r.size.x > 0 and r.size.y > 0:
		img.fill_rect(r, c)


static func _rrect(img: Image, x: int, y: int, w: int, h: int, c: Color, rad: int) -> void:
	## a rectangle with its corners cut round
	for yy in h:
		var cut := 0
		if yy < rad:
			cut = rad - yy
		elif yy >= h - rad:
			cut = yy - (h - rad) + 1
		cut = mini(cut, rad)
		_r(img, x + cut, y + yy, w - cut * 2, 1, c)


static func _p(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)


static func _ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for yy in range(int(cy - ry - 1), int(cy + ry + 2)):
		for xx in range(int(cx - rx - 1), int(cx + rx + 2)):
			var dx := (xx + 0.5 - cx) / rx
			var dy := (yy + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				_p(img, xx, yy, c)
