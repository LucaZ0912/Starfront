class_name BuildArt
extends RefCounted
## 0.7.50.11 (Luz: "the settlements look too chibi, too boxy"): the buildings of a settlement, each one its own – in
## the slanted view, the roof seen from above and the front below it. Architectures (o["arch"]):
##   prefab    corrugated metal roof with its ridges, panel walls with rivets, a canopy over the door, pipes, an air unit
##   container stacked shipping containers in different colours, ribbed, a ladder, a neon sign, cables
##   quonset   a ribbed half-barrel roof, its end wall with the door
##   dome      a habitat dome in rings, portholes, an airlock door in hazard stripes
##   pitched   a gabled roof of tiles (two slopes, the ridge), plastered or planked walls, shutters, a flower box
##   adobe     a flat roof with a parapet and rounded corners, rugs and water tanks on it, soft plaster, an arched door,
##             deep small windows, a canvas awning
##   stone     dressed stone, slate roof, pointed-arch windows lit gold, a small bell turret
##   module    white panels with rounded corners, a long window band, a green light strip, solar panels on the roof
## On the roofs: antennas, dishes, water tanks, solar panels, vents, planters, laundry lines – chosen by its seed.

const OUT := Color(0.09, 0.07, 0.11)


static func paint(img: Image, o: Dictionary, pw: int, total_h: int) -> void:
	var arch := String(o.get("arch", "prefab"))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(o.get("seed", 1))
	var roof: Color = o.get("col", Color(0.45, 0.45, 0.5))
	var wall: Color = o.get("col2", Color(0.6, 0.6, 0.62))
	var lamp: Color = o.get("lamp", Color(1.0, 0.85, 0.5))
	var win: Color = o.get("win", Color(1.0, 0.85, 0.55))
	var storeys := int(o.get("storeys", 1))
	var fh := 20 + (storeys - 1) * 14                      # the front wall's height (px)
	var base := total_h                                    # the ground line
	var top_face := base - fh                              # where the front starts (the roof's lower edge)
	match arch:
		"container":
			_container(img, rng, pw, base, fh, roof, wall, lamp, win)
			return
		"dome":
			_dome(img, rng, pw, base, fh, roof, wall, lamp, win)
			return
		"quonset":
			_quonset(img, rng, pw, base, fh, roof, wall, lamp, win)
			return
	# ---- the roof
	match arch:
		"pitched", "stone":
			_gable(img, rng, pw, 2, top_face, roof, arch == "stone")
		"adobe":
			_flat(img, rng, pw, 2, top_face, roof, true)
		"module":
			_flat(img, rng, pw, 2, top_face, roof, false)
			_rounded(img, pw, 2, 4)
		_:
			_corrugated(img, pw, 2, top_face, roof)
	_roof_clutter(img, rng, arch, pw, 4, top_face - 2, roof)
	# ---- the front
	match arch:
		"stone":
			_stone_wall(img, rng, 0, top_face, pw, fh, wall)
		"pitched":
			if rng.randf() < 0.5:
				_planks(img, 0, top_face, pw, fh, wall)
			else:
				_plaster(img, rng, 0, top_face, pw, fh, wall)
		"adobe":
			_plaster(img, rng, 0, top_face, pw, fh, wall)
			_rounded(img, pw, top_face, 3)
		"module":
			_r(img, 0, top_face, pw, fh, wall)
			_r(img, 0, top_face, pw, 1, wall.lightened(0.25))
			_r(img, 0, top_face + fh - 3, pw, 3, wall.darkened(0.12))
		_:
			_panels(img, 0, top_face, pw, fh, wall)
	_r(img, 0, top_face, pw, 2, roof.darkened(0.4))              # the eaves' shadow
	# doors and windows
	var door_x := int(o.get("door", pw / 2 - 5))
	door_x = clampi(door_x, 3, pw - 13)
	if arch == "module":
		_r(img, 4, top_face + 5, pw - 8, 7, Color(0.12, 0.2, 0.28))
		for gx in range(5, pw - 5, 6):
			_r(img, gx, top_face + 6, 4, 5, win.lerp(Color(0.6, 0.85, 1.0), 0.5) if rng.randf() < 0.6 else Color(0.22, 0.34, 0.45))
		_r(img, 4, top_face + 6, pw - 8, 1, Color(0.8, 0.95, 1.0, 1.0))
		_r(img, 0, top_face + 14, pw, 1, Color(o.get("acc", Color(0.25, 0.85, 0.55))))
	else:
		for row in storeys:
			var wy := top_face + 5 + row * 14
			var wx := 4
			while wx < pw - 10:
				if row == storeys - 1 and wx > door_x - 9 and wx < door_x + 13:
					wx += 3
					continue
				_window(img, rng, wx, wy, arch, win, wall)
				wx += 11 + rng.randi_range(0, 3)
	_door(img, rng, door_x, base - 16, arch, lamp, wall)
	_wall_clutter(img, rng, arch, pw, top_face, base, wall, lamp, door_x)
	# dust and grime along the foot
	for x in pw:
		if rng.randf() < 0.5:
			_p(img, x, base - 1, wall.darkened(0.35))


# ---------------------------------------------------------------- roofs

static func _corrugated(img: Image, pw: int, y0: int, y1: int, roof: Color) -> void:
	_r(img, 0, y0, pw, y1 - y0, roof)
	for y in range(y0, y1):
		var k := (y - y0) % 3
		_r(img, 0, y, pw, 1, roof.lightened(0.12) if k == 0 else (roof.darkened(0.1) if k == 2 else roof))
	_r(img, 0, y0, pw, 1, roof.lightened(0.3))
	for x in range(0, pw, 16):                               # panel seams with rivets
		_r(img, x, y0, 1, y1 - y0, roof.darkened(0.2))
		for y2 in range(y0 + 2, y1, 5):
			_p(img, x + 2, y2, roof.lightened(0.25))
	# rust streaks now and then
	for x2 in range(5, pw, 23):
		_r(img, x2, y0 + 2, 1, (y1 - y0) / 2, roof.lerp(Color(0.55, 0.3, 0.15), 0.4))


static func _gable(img: Image, rng: RandomNumberGenerator, pw: int, y0: int, y1: int, roof: Color, slate: bool) -> void:
	var mid := y0 + (y1 - y0) * 2 / 5                        # the ridge – the far slope is lit, the near one in shade
	_r(img, 0, y0, pw, mid - y0, roof.lightened(0.12))
	_r(img, 0, mid, pw, y1 - mid, roof.darkened(0.08))
	var tile := 4 if slate else 5
	for y in range(y0, y1, 3):
		var off := 0 if ((y - y0) / 3) % 2 == 0 else tile / 2
		for x in range(-off, pw, tile):
			_p(img, x, y + 2, roof.darkened(0.25 if y >= mid else 0.12))           # the tiles' lower edges
			if rng.randf() < 0.04:
				_r(img, x + 1, y, tile - 1, 2, roof.lerp(Color(0.3, 0.45, 0.25), 0.3))   # moss
	_r(img, 0, mid - 1, pw, 2, roof.darkened(0.35))           # the ridge
	_r(img, 0, mid - 2, pw, 1, roof.lightened(0.3))
	_r(img, 0, y0, 2, y1 - y0, roof.darkened(0.2))            # the gable ends
	_r(img, pw - 2, y0, 2, y1 - y0, roof.darkened(0.3))


static func _flat(img: Image, rng: RandomNumberGenerator, pw: int, y0: int, y1: int, roof: Color, parapet: bool) -> void:
	_r(img, 0, y0, pw, y1 - y0, roof)
	for i in (pw * (y1 - y0)) / 22:                           # a little texture
		_p(img, rng.randi_range(2, pw - 3), rng.randi_range(y0 + 2, y1 - 2), roof.darkened(0.06) if rng.randf() < 0.5 else roof.lightened(0.05))
	if parapet:
		_r(img, 0, y0, pw, 2, roof.lightened(0.18))
		_r(img, 0, y0, 2, y1 - y0, roof.lightened(0.12))
		_r(img, pw - 2, y0, 2, y1 - y0, roof.darkened(0.15))
		_r(img, 2, y0 + 2, pw - 4, 1, roof.darkened(0.15))     # the parapet's inner shadow
		for x in range(6, pw - 4, 9):                          # water spouts
			_r(img, x, y1 - 1, 2, 2, roof.darkened(0.3))
	else:
		_r(img, 0, y0, pw, 1, roof.lightened(0.25))
		_r(img, 0, y1 - 2, pw, 2, roof.darkened(0.15))


static func _rounded(img: Image, pw: int, y0: int, r: int) -> void:
	for y in r:
		for x in r - y:
			_p(img, x, y0 + y, Color(0, 0, 0, 0))
			_p(img, pw - 1 - x, y0 + y, Color(0, 0, 0, 0))


static func _roof_clutter(img: Image, rng: RandomNumberGenerator, arch: String, pw: int, y0: int, y1: int, roof: Color) -> void:
	var n := maxi(1, pw / 24)
	var used := []
	for i in n + 1:
		var kind := rng.randi() % 7
		var x := rng.randi_range(3, maxi(4, pw - 16))
		var y := rng.randi_range(y0 + 1, maxi(y0 + 2, y1 - 10))
		var clash := false
		for u in used:
			if absi(int(u) - x) < 14:
				clash = true
		if clash:
			continue
		used.append(x)
		match kind:
			0:                                                 # an air unit with its fan
				_r(img, x, y, 12, 8, roof.lightened(0.2))
				_r(img, x, y + 6, 12, 2, roof.darkened(0.2))
				_ellipse(img, x + 6, y + 3.5, 3.5, 2.5, roof.darkened(0.35))
				_p(img, x + 6, y + 3, roof.lightened(0.3))
			1:                                                 # a water tank on legs
				_r(img, x + 1, y + 6, 1, 5, roof.darkened(0.4))
				_r(img, x + 9, y + 6, 1, 5, roof.darkened(0.4))
				_ellipse(img, x + 5.5, y + 4, 5.5, 4.0, Color(0.55, 0.6, 0.62))
				_ellipse(img, x + 4.5, y + 3, 2.5, 1.5, Color(0.72, 0.78, 0.8))
			2:                                                 # solar panels
				if arch == "adobe":
					continue
				for k in 3:
					_r(img, x + k * 5, y, 4, 7, Color(0.16, 0.24, 0.45))
					_r(img, x + k * 5, y, 4, 1, Color(0.45, 0.6, 0.85))
					_p(img, x + k * 5 + 1, y + 3, Color(0.35, 0.5, 0.8))
			3:                                                 # an antenna mast with its light
				_r(img, x + 3, y - 10, 1, 14, Color(0.25, 0.25, 0.28))
				_r(img, x, y - 6, 7, 1, Color(0.3, 0.3, 0.33))
				_r(img, x + 1, y - 2, 5, 1, Color(0.3, 0.3, 0.33))
				_p(img, x + 3, y - 11, Color(1.0, 0.3, 0.25))
			4:                                                 # a small dish
				_ellipse(img, x + 5, y + 4, 5, 3.5, Color(0.8, 0.8, 0.82))
				_ellipse(img, x + 5, y + 3, 3, 2, Color(0.62, 0.62, 0.66))
				_r(img, x + 5, y + 5, 1, 4, Color(0.3, 0.3, 0.33))
			5:                                                 # vents / a skylight
				if rng.randf() < 0.5:
					for k2 in 3:
						_r(img, x + k2 * 4, y + 2, 3, 3, roof.darkened(0.3))
				else:
					_r(img, x, y, 10, 6, Color(0.5, 0.68, 0.78))
					_r(img, x, y, 10, 1, Color(0.85, 0.95, 1.0))
			6:                                                 # planters on an Assembly roof, a laundry line elsewhere
				if arch in ["pitched", "module", "adobe"]:
					for k3 in 3:
						_r(img, x + k3 * 5, y + 3, 4, 3, Color(0.42, 0.3, 0.2))
						_ellipse(img, x + k3 * 5 + 2, y + 2, 2.5, 2.5, Color(0.3, 0.6, 0.3))
				else:
					_r(img, x, y + 2, 1, 6, Color(0.3, 0.3, 0.3))
					_r(img, x + 16, y + 2, 1, 6, Color(0.3, 0.3, 0.3))
					_r(img, x, y + 2, 17, 1, Color(0.2, 0.2, 0.2))
					for k4 in 4:
						_r(img, x + 2 + k4 * 4, y + 3, 3, 4, Color.from_hsv(rng.randf(), 0.5, 0.85))


# ---------------------------------------------------------------- walls

static func _panels(img: Image, x0: int, y0: int, w: int, h: int, wall: Color) -> void:
	_r(img, x0, y0, w, h, wall)
	for x in range(x0, x0 + w, 12):
		_r(img, x, y0, 1, h, wall.darkened(0.18))
		_p(img, x + 2, y0 + 3, wall.lightened(0.2))
		_p(img, x + 2, y0 + h - 4, wall.lightened(0.2))
	_r(img, x0, y0 + h - 4, w, 1, wall.darkened(0.12))


static func _planks(img: Image, x0: int, y0: int, w: int, h: int, wall: Color) -> void:
	_r(img, x0, y0, w, h, wall)
	for y in range(y0, y0 + h, 3):
		_r(img, x0, y, w, 1, wall.darkened(0.15))
	for x in range(x0 + 5, x0 + w, 17):
		for y2 in range(y0, y0 + h, 6):
			_p(img, x + (y2 % 4), y2 + 1, wall.darkened(0.25))


static func _plaster(img: Image, rng: RandomNumberGenerator, x0: int, y0: int, w: int, h: int, wall: Color) -> void:
	_r(img, x0, y0, w, h, wall)
	for i in (w * h) / 14:
		_p(img, x0 + rng.randi() % w, y0 + rng.randi() % h, wall.darkened(0.07) if rng.randf() < 0.6 else wall.lightened(0.06))
	_r(img, x0, y0 + h - 3, w, 3, wall.darkened(0.12))          # the plinth
	for k in 2:                                                 # cracks
		var cx := x0 + rng.randi_range(4, w - 5)
		var cy := y0 + rng.randi_range(3, h - 6)
		for t in 4:
			_p(img, cx + t * (1 if k == 0 else -1), cy + t, wall.darkened(0.25))


static func _stone_wall(img: Image, rng: RandomNumberGenerator, x0: int, y0: int, w: int, h: int, wall: Color) -> void:
	_r(img, x0, y0, w, h, wall)
	var row := 0
	for y in range(y0, y0 + h, 4):
		var off := 0 if row % 2 == 0 else 4
		for x in range(x0 - off, x0 + w, 8):
			var sc := wall.lightened(rng.randf_range(-0.08, 0.08))
			_r(img, x + 1, y + 1, 7, 3, sc)
			_r(img, x + 1, y + 1, 7, 1, sc.lightened(0.1))
		_r(img, x0, y, w, 1, wall.darkened(0.3))
		row += 1


# ---------------------------------------------------------------- doors, windows, things on the walls

static func _window(img: Image, rng: RandomNumberGenerator, x: int, y: int, arch: String, win: Color, wall: Color) -> void:
	var lit := rng.randf() < 0.65
	var glass := win if lit else Color(0.16, 0.2, 0.27)
	match arch:
		"stone":
			_r(img, x, y + 2, 6, 8, Color(0.12, 0.1, 0.1))
			_r(img, x + 1, y + 3, 4, 7, glass.lerp(Color(1.0, 0.75, 0.35), 0.5) if lit else glass)
			_p(img, x + 2, y + 1, Color(0.12, 0.1, 0.1))
			_p(img, x + 3, y + 1, Color(0.12, 0.1, 0.1))
			_p(img, x + 2, y + 2, glass)
			_p(img, x + 3, y + 2, glass)
			_r(img, x - 1, y + 10, 8, 1, wall.lightened(0.15))
		"adobe":
			_r(img, x, y + 1, 6, 6, wall.darkened(0.3))
			_r(img, x + 1, y + 2, 4, 4, glass)
			_r(img, x, y + 7, 6, 1, wall.darkened(0.15))
		_:
			_r(img, x - 1, y - 1, 9, 9, wall.darkened(0.3))      # the frame
			_r(img, x, y, 7, 7, glass)
			_r(img, x + 3, y, 1, 7, wall.darkened(0.3))          # the mullion
			if lit:
				_p(img, x + 1, y + 1, glass.lightened(0.4))
				if rng.randf() < 0.4:
					_r(img, x, y, 2, 7, glass.darkened(0.3))      # a curtain
			else:
				_p(img, x + 5, y + 1, Color(0.6, 0.75, 0.9))       # the sky in the glass
			_r(img, x - 1, y + 8, 9, 1, wall.lightened(0.2))     # the sill
			if arch == "pitched":
				_r(img, x - 3, y - 1, 2, 9, Color(0.35, 0.45, 0.3))   # shutters
				_r(img, x + 8, y - 1, 2, 9, Color(0.35, 0.45, 0.3))
				if rng.randf() < 0.5:
					_r(img, x - 1, y + 9, 9, 2, Color(0.45, 0.3, 0.2))   # a flower box
					for f in 3:
						_p(img, x + f * 3, y + 8, Color.from_hsv(rng.randf(), 0.6, 0.95))


static func _door(img: Image, rng: RandomNumberGenerator, x: int, y: int, arch: String, lamp: Color, wall: Color) -> void:
	match arch:
		"adobe", "stone":
			_r(img, x, y + 2, 10, 14, Color(0.18, 0.12, 0.08))
			_r(img, x + 1, y + 3, 8, 13, Color(0.38, 0.24, 0.14))
			_r(img, x + 2, y, 6, 2, Color(0.18, 0.12, 0.08))     # the arch
			_r(img, x + 5, y + 4, 1, 12, Color(0.28, 0.17, 0.1))
			if arch == "adobe":                                   # a canvas awning
				for k in 6:
					_r(img, x - 3 + k * 3, y - 4, 3, 3, Color(0.85, 0.35, 0.25) if k % 2 == 0 else Color(0.95, 0.88, 0.75))
		_:
			_r(img, x - 1, y - 1, 12, 17, wall.darkened(0.35))
			_r(img, x, y, 10, 16, Color(0.18, 0.2, 0.24))
			_r(img, x + 1, y + 1, 4, 15, Color(0.3, 0.33, 0.38))
			_r(img, x + 5, y + 1, 4, 15, Color(0.26, 0.29, 0.34))
			_r(img, x, y + 6, 10, 1, Color(0.15, 0.16, 0.2))
			_r(img, x - 2, y - 4, 14, 2, wall.darkened(0.4))      # the canopy
			_r(img, x - 2, y - 2, 14, 1, wall.darkened(0.2))
	_r(img, x + 3, y - 7 if arch != "adobe" else y - 7, 4, 2, lamp)   # the lamp over the door
	_p(img, x + 4, y - 5, lamp.lightened(0.4))
	_r(img, x - 1, y + 16, 12, 1, wall.lightened(0.15))       # the step


static func _wall_clutter(img: Image, rng: RandomNumberGenerator, arch: String, pw: int, y0: int, y1: int, wall: Color, lamp: Color, door_x: int) -> void:
	# a pipe running down the wall, a meter box, a poster or a sign
	var px := 2 if door_x > pw / 2 else pw - 4
	if arch in ["prefab", "quonset", "container", "module"]:
		_r(img, px, y0 + 1, 2, y1 - y0 - 1, wall.darkened(0.3))
		_r(img, px, y0 + 1, 1, y1 - y0 - 1, wall.lightened(0.1))
	if rng.randf() < 0.6:
		var bx := rng.randi_range(4, pw - 12)
		if absi(bx - door_x) > 12:
			_r(img, bx, y1 - 10, 6, 5, Color(0.32, 0.34, 0.36))
			_p(img, bx + 1, y1 - 9, Color(0.4, 1.0, 0.5))
	if arch in ["prefab", "container"] and rng.randf() < 0.5:
		var sx := rng.randi_range(4, pw - 20)
		if absi(sx - door_x) > 14:
			_r(img, sx, y0 + 3, 16, 4, Color(0.06, 0.06, 0.08))
			_r(img, sx + 1, y0 + 4, 14, 2, Color.from_hsv(rng.randf(), 0.7, 1.0))   # a little neon sign


# ---------------------------------------------------------------- whole buildings of other shapes

static func _container(img: Image, rng: RandomNumberGenerator, pw: int, base: int, fh: int, roof: Color, wall: Color, lamp: Color, win: Color) -> void:
	var cols := [Color(0.62, 0.22, 0.18), Color(0.2, 0.42, 0.6), Color(0.75, 0.55, 0.15), Color(0.3, 0.5, 0.3), Color(0.55, 0.55, 0.58)]
	var levels := 2
	var x := 0
	while x < pw - 6:
		var cw := mini(pw - x, rng.randi_range(22, 34))
		for lv in levels:
			var c: Color = cols[rng.randi() % cols.size()]
			var y_front := base - (lv + 1) * 14
			var y_top := y_front - (img.get_height() - fh - 8) / levels
			if lv == levels - 1 and rng.randf() < 0.35:
				continue                                         # a gap in the upper row
			_r(img, x, y_top, cw, y_front - y_top, c.lightened(0.08))          # its top
			for rx in range(x, x + cw, 3):
				_r(img, rx, y_top, 1, y_front - y_top, c.darkened(0.08))
			_r(img, x, y_front, cw, 14, c)                      # its side
			for rx2 in range(x + 1, x + cw - 1, 2):
				_r(img, rx2, y_front + 1, 1, 12, c.darkened(0.15))
			_r(img, x, y_front, cw, 1, c.lightened(0.25))
			_r(img, x, y_front, 1, 14, c.darkened(0.35))
			if rng.randf() < 0.5:
				_r(img, x + cw / 2 - 3, y_front + 3, 6, 5, win if rng.randf() < 0.6 else Color(0.16, 0.2, 0.27))   # a cut-in window
		x += cw + 1
	_door(img, rng, pw / 2 - 5, base - 16, "prefab", lamp, wall)
	_r(img, pw - 6, base - 28, 1, 28, Color(0.3, 0.3, 0.32))      # a ladder
	_r(img, pw - 2, base - 28, 1, 28, Color(0.3, 0.3, 0.32))
	for ly in range(base - 26, base, 4):
		_r(img, pw - 6, ly, 5, 1, Color(0.35, 0.35, 0.38))


static func _dome(img: Image, rng: RandomNumberGenerator, pw: int, base: int, fh: int, roof: Color, wall: Color, lamp: Color, win: Color) -> void:
	var h := img.get_height()
	var cx := pw * 0.5
	var ry := float(h - 6) * 0.5
	var cy := float(base) - ry
	_ellipse(img, cx, cy + 3.0, pw * 0.5, ry, roof.darkened(0.35))
	_ellipse(img, cx, cy, pw * 0.5 - 1.0, ry - 1.0, roof)
	_ellipse(img, cx - pw * 0.12, cy - ry * 0.35, pw * 0.22, ry * 0.3, roof.lightened(0.15))
	for k in range(1, 4):                                       # its rings
		var yy := int(cy - ry + ry * 2.0 * k / 4.0)
		for x in pw:
			var dx := (x + 0.5 - cx) / (pw * 0.5 - 1.0)
			if absf(dx) < sqrt(maxf(0.0, 1.0 - pow((yy - cy) / (ry - 1.0), 2.0))):
				_p(img, x, yy, roof.darkened(0.15))
	for p in 4:                                                 # portholes
		var a := -0.9 + p * 0.6
		var px := cx + sin(a) * pw * 0.36
		var py := cy + ry * 0.35
		_ellipse(img, px, py, 3.0, 3.0, Color(0.2, 0.22, 0.26))
		_ellipse(img, px, py, 2.0, 2.0, win if rng.randf() < 0.6 else Color(0.18, 0.24, 0.32))
	var dx2 := int(cx) - 6                                      # the airlock, in hazard stripes
	for k2 in 12:
		_r(img, dx2 + k2, base - 18, 1, 18, Color(0.95, 0.78, 0.15) if (k2 / 2) % 2 == 0 else Color(0.15, 0.15, 0.17))
	_r(img, dx2 + 2, base - 15, 8, 15, Color(0.3, 0.33, 0.38))
	_r(img, dx2 + 5, base - 15, 1, 15, Color(0.2, 0.22, 0.26))
	_r(img, dx2 + 4, base - 22, 4, 2, lamp)


static func _quonset(img: Image, rng: RandomNumberGenerator, pw: int, base: int, fh: int, roof: Color, wall: Color, lamp: Color, win: Color) -> void:
	var h := img.get_height()
	var top := 4
	var front := base - fh
	_r(img, 0, top + 4, pw, front - top - 4, roof)
	for y in range(top + 4, front):                             # the barrel's curve: lit on top, darker at the sides
		var k := float(y - top - 4) / maxf(1.0, front - top - 4)
		_r(img, 0, y, pw, 1, roof.lightened(0.15 * (1.0 - absf(k - 0.35) * 2.0)))
	for x in range(0, pw, 6):                                   # the ribs
		_r(img, x, top + 4, 1, front - top - 4, roof.darkened(0.2))
	_ellipse(img, pw * 0.5, top + 5.0, pw * 0.5, 4.0, roof.lightened(0.1))
	# its end wall, an arch, with the door and two windows
	_ellipse(img, pw * 0.5, float(front + 4), pw * 0.5 - 1.0, 8.0, wall.darkened(0.1))
	_r(img, 0, front + 4, pw, fh - 4, wall)
	_panels(img, 0, front + 4, pw, fh - 4, wall)
	_window(img, rng, 6, front + 6, "prefab", win, wall)
	_window(img, rng, pw - 14, front + 6, "prefab", win, wall)
	_door(img, rng, pw / 2 - 5, base - 16, "prefab", lamp, wall)


# ---------------------------------------------------------------- helpers

static func _r(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	var r := Rect2i(x, y, w, h).intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	if r.size.x > 0 and r.size.y > 0:
		img.fill_rect(r, c)


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
