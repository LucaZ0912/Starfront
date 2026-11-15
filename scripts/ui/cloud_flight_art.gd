extends RefCounted
## 0.7.54.3 (Luz: "the approach far too plain beside the other flights"): a cloud city's platforms painted in pixel art
## for the flight in – seen from above at a slant like everything else. Its deck of pale paving with a promenade ring
## and green terraces, the buildings in its power's style (glass and stone with roof gardens and domes, the Covenant's
## dark stone with golden windows and spires, the Directorate's white blocks with green bands and hexagon crowns, the
## free city's dark towers with neon), their shadows; the rim with running lights; under it the spindles, lift tanks
## and the glowing rings of the antigrav rotors going down into the haze. The main platform has the hangar on its rim,
## its gate open. Deterministic from a seed. No class_name: preload it.

const TILT := 0.42                      # the disc's ellipse (height / width)


static func _h(x: int, y: int, s: int) -> float:
	var v := sin(float(x) * 12.9898 + float(y) * 78.233 + float(s) * 3.7) * 43758.5453
	return v - floor(v)


static func _rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	var r := Rect2i(x, y, w, h).intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	if r.size.x <= 0 or r.size.y <= 0:
		return
	if c.a >= 0.999:
		img.fill_rect(r, c)
		return
	for yy in range(r.position.y, r.end.y):
		for xx in range(r.position.x, r.end.x):
			img.set_pixel(xx, yy, img.get_pixel(xx, yy).blend(c))


static func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c if c.a >= 0.999 else img.get_pixel(x, y).blend(c))


const STYLE_COLS := {
	"assembly": {"stone": Color(0.9, 0.88, 0.82), "glass": Color(0.42, 0.6, 0.72), "roof": Color(0.95, 0.94, 0.9), "accent": Color(0.55, 0.85, 1.0), "deck": Color(0.84, 0.81, 0.74)},
	"covenant": {"stone": Color(0.5, 0.33, 0.27), "glass": Color(1.0, 0.8, 0.4), "roof": Color(0.38, 0.24, 0.2), "accent": Color(1.0, 0.78, 0.3), "deck": Color(0.55, 0.42, 0.36)},
	"directorate": {"stone": Color(0.95, 0.96, 0.96), "glass": Color(0.55, 0.75, 0.72), "roof": Color(0.98, 0.98, 0.98), "accent": Color(0.3, 0.95, 0.55), "deck": Color(0.86, 0.89, 0.89)},
	"independent": {"stone": Color(0.36, 0.38, 0.44), "glass": Color(0.25, 0.3, 0.4), "roof": Color(0.28, 0.3, 0.35), "accent": Color(1.0, 0.35, 0.8), "deck": Color(0.4, 0.42, 0.46)},
}


## A platform of radius r (art px). Returns {img, centre (the disc's middle in the image), gate (the gate's middle, or
## Vector2.INF)}.
## What lights up at night (windows, the rim's running lights, the gate) – [x, y, colour], gathered while painting.
static var _lit: Array = []


static func platform(r: int, sd: int, style: String, look: Dictionary, gate: bool, day: float = 1.0) -> Dictionary:
	_lit = []
	var sc: Dictionary = STYLE_COLS.get(style, STYLE_COLS["assembly"])
	var hz: Color = look.get("haze", Color(0.95, 0.82, 0.62))
	var ry := int(r * TILT)
	var top := int(r * 0.75)                                   # room for the buildings rising
	var under := int(r * 1.1)                                  # room for what hangs below
	var W := r * 2 + 12
	var H := top + ry * 2 + 14 + under
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := W / 2
	var cy := top + ry
	var rng := RandomNumberGenerator.new()
	rng.seed = sd
	# under the deck: spindles, lift tanks, rotor rings – fading into the haze
	var n_sp := 5 + r / 40
	for i in n_sp:
		var a := lerpf(0.15, PI - 0.15, (float(i) + 0.5) / n_sp)
		var sx := cx + int(cos(a) * r * 0.75 * (0.6 + 0.4 * rng.randf()))
		var sy := cy + int(sin(a) * ry * 0.7) + 10
		var ln := int(r * rng.randf_range(0.45, 1.0))
		var wd := maxi(3, int(r * rng.randf_range(0.03, 0.06)))
		for yy in ln:
			var k := float(yy) / ln
			var ww := maxi(1, int(wd * (1.0 - k * 0.75)))
			for xx in ww:
				var lx2 := float(xx) / maxf(ww, 1.0)
				var c := Color(0.6, 0.62, 0.66).lerp(Color(0.26, 0.27, 0.3), lx2)
				if yy % 9 == 0:
					c = c.darkened(0.25)                               # its segments
				_px(img, sx - ww / 2 + xx, sy + yy, c.lerp(hz, k * 0.75))
		if rng.randf() < 0.6:
			# a lift tank: a capsule round the spindle, lit from the left, its caps, a band of yellow
			var ty := sy + int(ln * 0.3)
			var tw := wd * 2 + 4
			var th := wd * 3 + 6
			var fade := clampf(float(ty - sy) / maxf(ln, 1.0), 0.0, 1.0) * 0.4
			for yy3 in th:
				var capk := 1.0
				var e := float(yy3) / th
				if e < 0.15:
					capk = sqrt(1.0 - pow(1.0 - e / 0.15, 2.0))
				elif e > 0.85:
					capk = sqrt(1.0 - pow((e - 0.85) / 0.15, 2.0))
				var half := int(tw * 0.5 * capk)
				for xx3 in range(-half, half + 1):
					var lx := float(xx3 + half) / maxf(half * 2.0, 1.0)
					var tc := Color(0.78, 0.8, 0.84).lerp(Color(0.34, 0.36, 0.4), lx)
					if absi(yy3 - th / 2) <= 1:
						tc = Color(0.95, 0.75, 0.2).lerp(tc, 0.3)
					_px(img, sx + xx3, ty + yy3, tc.lerp(hz, fade))
		else:
			var ry2 := int(sy + ln * 0.5)
			var rr := wd * 2 + 2
			for t in 40:
				var an := TAU * t / 40.0
				_px(img, sx + int(cos(an) * rr), ry2 + int(sin(an) * rr * 0.35), Color(0.45, 0.88, 1.0, 0.9).lerp(hz, 0.25))
		_rect(img, sx - 1, sy + ln - 2, 3, 2, Color(0.55, 0.9, 1.0))
	# the rim's face: plates darkening down, running lights
	for x in range(cx - r, cx + r + 1):
		var dx := float(x - cx) / r
		if absf(dx) > 1.0:
			continue
		var ey := cy + int(sqrt(1.0 - dx * dx) * ry)
		for k2 in 9:
			var c2 := Color(0.62, 0.63, 0.66).lerp(Color(0.3, 0.31, 0.34), float(k2) / 9.0)
			if (x / 6) % 2 == 0:
				c2 = c2.darkened(0.06)
			_px(img, x, ey + k2, c2)
		if x % 7 == 0:
			_px(img, x, ey + 4, Color(0.55, 0.9, 1.0))
			_lit.append([x, ey + 4, Color(0.55, 0.95, 1.0)])
	# the deck: paving, rings, the promenade, terraces of green, a plaza in the middle
	var deck: Color = sc["deck"]
	for y in range(cy - ry, cy + ry + 1):
		for x in range(cx - r, cx + r + 1):
			var dx2 := float(x - cx) / r
			var dy2 := float(y - cy) / ry
			var d := sqrt(dx2 * dx2 + dy2 * dy2)
			if d > 1.0:
				continue
			var c3 := deck.lerp(deck.darkened(0.06), _h(x / 3, y / 2, sd))
			if d > 0.9:
				c3 = deck.lightened(0.08)                              # the promenade
				if d > 0.985:
					c3 = Color(0.95, 0.96, 0.97)                       # its railing
			elif d > 0.7 and d < 0.8 and fposmod(atan2(dy2, dx2) * 3.0, TAU) < 3.6:
				c3 = Color(0.32, 0.5, 0.26).lerp(Color(0.45, 0.65, 0.32), _h(x / 2, y, sd + 1))   # terraces
			elif d < 0.22:
				c3 = deck.lightened(0.12) if int(d * 30.0) % 2 == 0 else deck.lightened(0.04)    # the plaza
			elif int(d * 18.0) % 3 == 0 and _h(x, y, sd + 2) < 0.6:
				c3 = c3.darkened(0.05)                                   # ring paths
			c3 = c3.darkened(0.12 * clampf(dx2 + dy2 * 0.6, 0.0, 1.0))  # lit from the upper left
			img.set_pixel(x, y, c3)
	# buildings: placed in rings, drawn back to front
	var bl: Array = []
	var nb := 6 + r / 14
	for i in nb:
		var a2 := rng.randf() * TAU
		var dd := rng.randf_range(0.28, 0.68)
		bl.append(Vector2(cx + cos(a2) * r * dd, cy + sin(a2) * ry * dd))
	bl.append(Vector2(cx, cy - ry * 0.05))                            # the tallest in the middle
	bl.sort_custom(func(p, q): return p.y < q.y)
	for i in bl.size():
		var b: Vector2 = bl[i]
		var central := i == bl.size() - 1 or b.distance_to(Vector2(cx, cy - ry * 0.05)) < 1.0
		var bw := int(r * rng.randf_range(0.08, 0.14) * (1.6 if central else 1.0))
		var bd := int(bw * TILT)
		var bh := int(r * rng.randf_range(0.12, 0.3) * (2.0 if central else 1.0))
		_building(img, int(b.x), int(b.y), bw, bd, bh, style, sc, rng)
	var gpos := Vector2.INF
	if gate:
		gpos = _gate(img, cx, cy + ry + 4, r)
	# 0.7.54.3 (Luz): by the hour – dusk and night darken it, and then its windows, rim lights and the gate glow
	if day < 0.75:
		var f := lerpf(0.32, 1.0, clampf(day / 0.75, 0.0, 1.0))
		var tint := Color(f * 0.92, f * 0.95, f * 1.08)
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				if c.a > 0.0:
					img.set_pixel(x, y, Color(c.r * tint.r, c.g * tint.g, minf(c.b * tint.b, 1.0), c.a))
		var on := 1.0 - clampf(day / 0.75, 0.0, 1.0)
		for l in _lit:
			var lc: Color = l[2]
			var base := img.get_pixel(int(l[0]), int(l[1]))
			img.set_pixel(int(l[0]), int(l[1]), base.lerp(lc, clampf(on * 1.6, 0.0, 1.0)))
	return {"img": img, "centre": Vector2(cx, cy), "gate": gpos}


## One building standing at (x, y) (its front's foot): a shadow, its front and side, its roof (gardens, a dome, a
## spire or a crown by style), windows.
static func _building(img: Image, x: int, y: int, w: int, d: int, h: int, style: String, sc: Dictionary, rng: RandomNumberGenerator) -> void:
	var stone: Color = sc["stone"]
	var glass: Color = sc["glass"]
	var roof: Color = sc["roof"]
	var acc: Color = sc["accent"]
	_rect(img, x - w / 2 + 3, y - 1, w + 4, d / 2 + 3, Color(0, 0, 0, 0.2))           # its shadow
	var x0 := x - w / 2
	# the front face
	for yy in h:
		for xx in w:
			var c := stone.lerp(stone.darkened(0.12), float(yy) / maxf(h, 1.0))
			var band := yy % 6
			match style:
				"covenant":
					if band >= 2 and band <= 4 and xx % 4 == 1:
						c = glass                                             # golden windows
				"directorate":
					if band == 2 and xx > 0 and xx < w - 1:
						c = acc.darkened(0.2)                                 # green light bands
					elif band >= 3 and band <= 4 and xx % 3 != 0:
						c = glass
				"independent":
					if band >= 2 and band <= 4 and xx % 3 != 0:
						c = glass if rng.randf() < 0.85 else acc
				_:
					if band >= 1 and band <= 4 and xx > 0 and xx < w - 1:
						c = glass.lerp(glass.lightened(0.3), float(xx) / w)       # curtain glass
			if c == glass and rng.randf() < 0.7:
				_lit.append([x0 + xx, y - yy, Color(1.0, 0.86, 0.55) if style != "independent" else (acc if rng.randf() < 0.3 else Color(0.6, 0.9, 1.0))])
			elif style == "assembly" and band >= 1 and band <= 4 and xx > 0 and xx < w - 1 and rng.randf() < 0.45:
				_lit.append([x0 + xx, y - yy, Color(1.0, 0.88, 0.6)])
			elif style == "directorate" and band == 2:
				_lit.append([x0 + xx, y - yy, acc])
			if xx == 0:
				c = c.lightened(0.12)
			if xx == w - 1:
				c = c.darkened(0.25)
			_px(img, x0 + xx, y - yy, c)
	# the roof
	var ry0 := y - h - d
	for yy2 in d:
		for xx2 in w:
			var c2 := roof.lerp(roof.darkened(0.08), float(xx2) / w)
			if yy2 == 0:
				c2 = c2.lightened(0.15)
			_px(img, x0 + xx2, ry0 + yy2, c2)
	match style:
		"covenant":
			for sp in [x0 + 1, x0 + w - 2]:
				for k in int(h * 0.5):
					var sw := maxi(1, int(3.0 * (1.0 - float(k) / (h * 0.5))))
					_rect(img, sp - sw / 2, ry0 - k, sw, 1, stone.darkened(0.15))
				_px(img, sp, ry0 - int(h * 0.5), acc)
		"directorate":
			var hx := x0 + w / 2
			for k3 in 4:
				_rect(img, hx - 4 + k3, ry0 - k3, 8 - k3 * 2, 1, acc if k3 == 3 else Color(0.98, 0.98, 0.98))
		"independent":
			_rect(img, x0 + 1, ry0 + 1, 2, 1, acc)
			_rect(img, x0 + w / 2, ry0 - 6, 1, 6, Color(0.5, 0.52, 0.56))          # an antenna
			_px(img, x0 + w / 2, ry0 - 7, Color(1.0, 0.3, 0.3))
		_:
			if w > 8 and rng.randf() < 0.5:
				var dc := x0 + w / 2
				for k4 in range(-3, 4):
					_rect(img, dc - int(sqrt(9.0 - k4 * k4) * 1.4), ry0 + d / 2 + k4 - 3, int(sqrt(9.0 - k4 * k4) * 2.8) + 1, 1, glass.lightened(0.35))
			else:
				_rect(img, x0 + 1, ry0 + 1, w - 2, maxi(1, d - 2), Color(0.38, 0.56, 0.3))       # a roof garden
				for g in int(w / 3):
					_px(img, x0 + 1 + g * 3, ry0 + 1, Color(0.55, 0.75, 0.4))


## The hangar on the rim with its gate open (a force field shimmering in it), the apron's lights. Returns the gate's
## middle in the image.
static func _gate(img: Image, x: int, y: int, r: int) -> Vector2:
	var gw := maxi(24, r / 7)
	var gh := maxi(10, gw / 3)
	var hx := x - gw / 2 - 6
	_rect(img, hx, y - gh - 10, gw + 12, gh + 16, Color(0.48, 0.5, 0.54))
	_rect(img, hx, y - gh - 10, gw + 12, 2, Color(0.75, 0.77, 0.8))
	_rect(img, hx + gw + 10, y - gh - 8, 2, gh + 14, Color(0.3, 0.31, 0.34))
	_rect(img, x - gw / 2, y - gh + 2, gw, gh + 4, Color(0.1, 0.11, 0.14))
	for fy in range(0, gh + 4, 2):
		_rect(img, x - gw / 2, y - gh + 2 + fy, gw, 1, Color(0.45, 0.85, 1.0, 0.18 if fy % 4 == 0 else 0.08))
	_rect(img, x - gw / 2, y + 5, gw, 1, Color(0.45, 0.85, 1.0))
	for gx in range(x - gw / 2, x + gw / 2):
		_lit.append([gx, y + 5, Color(0.5, 0.95, 1.0)])
		if gx % 3 == 0:
			_lit.append([gx, y - 2, Color(0.35, 0.7, 0.9)])
	for li in [x - gw / 2 - 3, x + gw / 2 + 2]:
		_rect(img, li, y - gh, 1, 2, Color(1.0, 0.8, 0.3))
		_rect(img, li, y - gh + 5, 1, 2, Color(1.0, 0.8, 0.3))
	return Vector2(x, y - gh / 2 + 3)
