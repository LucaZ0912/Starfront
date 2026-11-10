class_name WeaponArt
extends RefCounted
## 0.7.52.3 (Luz: "the shots do not come from the tip – the weapons could do with much more detail"): the hand weapons
## as pixel pictures at the figures' own fineness (ChibiArt.CHAR_SCALE screen px a pixel, ~22 px a metre), seen from
## the side and pointing right: a pistol ~7 px, a rifle ~21, the Long Rail ~32. Each in its maker's look – Axiom white
## and cyan, Hadrian gunmetal and amber, Forge of Return dark bronze and red, Concord blue-white – with receiver,
## barrel, grip, magazine or power cell, sights, vents and glowing emitters, black-outlined like the figures.
## `art(family)` → {tex, grip (where the hand holds it), muzzle (the very tip), len}; the walker turns it towards its aim.

const OUT := Color(0.04, 0.04, 0.06)
static var _cache := {}


static func art(family: String) -> Dictionary:
	if _cache.has(family):
		return _cache[family]
	var spec := _paint(family)
	var img: Image = spec["img"]
	_outline(img)
	var out := {"tex": ImageTexture.create_from_image(img), "grip": spec["grip"] + Vector2(1, 1), "muzzle": spec["muzzle"] + Vector2(1, 1),
		"len": img.get_width()}
	_cache[family] = out
	return out


## Painting in the picture's own coordinates (a pixel of room all round for the outline is added here).
static func _r(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in range(y + 1, y + h + 1):
		for xx in range(x + 1, x + w + 1):
			if xx >= 1 and yy >= 1 and xx < img.get_width() - 1 and yy < img.get_height() - 1:
				img.set_pixel(xx, yy, c)


static func _p(img: Image, x: int, y: int, c: Color) -> void:
	_r(img, x, y, 1, 1, c)


## A blank picture w × h with a pixel of room all round for the outline (all coordinates below are +1).
static func _blank(w: int, h: int) -> Image:
	var img := Image.create(w + 2, h + 2, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img


## Shading helper: a part with a light top edge and a dark underside.
static func _part(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	_r(img, x, y, w, h, c)
	_r(img, x, y, w, 1, c.lightened(0.28))
	if h > 1:
		_r(img, x, y + h - 1, w, 1, c.darkened(0.35))


static func _paint(f: String) -> Dictionary:
	var img: Image
	var grip := Vector2.ZERO
	var muzzle := Vector2.ZERO
	match f:
		"wp_laser_pistol":           # Axiom: white shell, a cyan cell, a ringed emitter
			img = _blank(9, 6)
			var w := Color(0.9, 0.92, 0.95)
			_part(img, 0, 0, 7, 3, w)                                  # the slide
			_part(img, 6, 1, 3, 1, Color(0.62, 0.66, 0.72))            # the emitter
			_p(img, 9, 2, Color(0.45, 1.0, 1.0))
			_p(img, 7, 1, Color(0.3, 0.85, 1.0))                       # its ring
			_r(img, 3, 2, 3, 1, Color(0.3, 0.85, 1.0))                 # the cell's glow
			_part(img, 1, 3, 2, 3, Color(0.32, 0.34, 0.38))            # the grip
			_p(img, 4, 4, Color(0.32, 0.34, 0.38))                     # trigger guard
			grip = Vector2(2, 4)
			muzzle = Vector2(9, 2)
		"wp_pistol":                 # Hadrian slug pistol: gunmetal, amber sight, chunky
			img = _blank(9, 6)
			var g := Color(0.34, 0.36, 0.4)
			_part(img, 0, 0, 8, 3, g)
			_r(img, 7, 2, 2, 1, Color(0.2, 0.21, 0.24))                # the bore
			_p(img, 1, 0, Color(1.0, 0.72, 0.25))                      # the sights
			_p(img, 6, 0, Color(1.0, 0.72, 0.25))
			_r(img, 2, 2, 4, 1, g.darkened(0.25))                      # the ejection port
			_part(img, 1, 3, 2, 3, Color(0.2, 0.18, 0.16))
			_p(img, 4, 4, g.darkened(0.3))
			grip = Vector2(2, 4)
			muzzle = Vector2(9, 2)
		"wp_smg":                    # Hadrian burst gun: short, a long magazine, a vented shroud
			img = _blank(14, 8)
			var g2 := Color(0.32, 0.34, 0.38)
			_part(img, 0, 1, 3, 3, Color(0.22, 0.22, 0.24))            # folded stock
			_part(img, 3, 0, 7, 4, g2)                                 # the receiver
			_part(img, 10, 1, 4, 2, g2.darkened(0.15))                 # the vented shroud
			for k in range(10, 14, 2):
				_p(img, k, 2, Color(0.12, 0.12, 0.14))
			_p(img, 14, 2, Color(0.18, 0.18, 0.2))
			_p(img, 5, 0, Color(1.0, 0.72, 0.25))                      # amber sight
			_part(img, 6, 4, 2, 4, Color(0.24, 0.24, 0.26))            # the magazine
			_part(img, 4, 4, 1, 3, Color(0.2, 0.18, 0.16))             # the grip
			_r(img, 3, 2, 4, 1, Color(1.0, 0.65, 0.2))                 # a status strip
			grip = Vector2(4, 5)
			muzzle = Vector2(14, 2)
		"wp_laser_rifle":            # Axiom: a long white shell, cyan coils along the barrel, an optic, a cell behind
			img = _blank(22, 8)
			var w2 := Color(0.9, 0.92, 0.95)
			_part(img, 0, 2, 5, 3, Color(0.78, 0.8, 0.84))             # the stock
			_part(img, 5, 1, 9, 4, w2)                                 # the receiver
			_part(img, 14, 2, 7, 2, Color(0.62, 0.66, 0.72))           # the barrel
			for k2 in range(15, 21, 2):
				_p(img, k2, 2, Color(0.3, 0.85, 1.0))                   # focusing coils
			_p(img, 21, 3, Color(0.45, 1.0, 1.0))                      # the emitter
			_p(img, 22, 3, Color(0.75, 1.0, 1.0))
			_part(img, 7, 0, 4, 1, Color(0.2, 0.22, 0.26))             # the optic
			_p(img, 10, 0, Color(0.4, 0.9, 1.0))
			_r(img, 6, 3, 6, 1, Color(0.3, 0.85, 1.0))                 # the power line
			_part(img, 8, 5, 2, 3, Color(0.32, 0.34, 0.38))            # the grip
			_part(img, 11, 5, 2, 2, Color(0.55, 0.6, 0.68))            # the cell
			grip = Vector2(9, 6)
			muzzle = Vector2(22, 3)
		"wp_beam":                   # Concord cutting beam: blue-white, a fat focusing head, a hose to the cell
			img = _blank(18, 8)
			var b := Color(0.82, 0.88, 0.96)
			_part(img, 0, 2, 4, 3, Color(0.3, 0.4, 0.6))               # the cell
			_part(img, 4, 1, 8, 4, b)
			_part(img, 12, 0, 4, 6, Color(0.6, 0.7, 0.85))             # the focusing head
			_r(img, 13, 1, 1, 4, Color(0.35, 0.95, 1.0))
			_r(img, 16, 2, 2, 2, Color(0.55, 1.0, 1.0))                # the lens
			_r(img, 5, 3, 6, 1, Color(0.35, 0.75, 1.0))
			_part(img, 6, 5, 2, 3, Color(0.25, 0.28, 0.35))
			grip = Vector2(7, 6)
			muzzle = Vector2(18, 3)
		"wp_rifle":                  # Hadrian rail carbine: gunmetal, rails along the barrel, a box magazine, amber lights
			img = _blank(21, 8)
			var g3 := Color(0.34, 0.36, 0.4)
			_part(img, 0, 2, 4, 3, Color(0.22, 0.22, 0.24))            # the stock
			_part(img, 4, 1, 8, 4, g3)                                 # the receiver
			_part(img, 12, 1, 8, 1, Color(0.5, 0.52, 0.56))            # the upper rail
			_part(img, 12, 3, 8, 1, Color(0.5, 0.52, 0.56))            # the lower rail
			_r(img, 13, 2, 7, 1, Color(1.0, 0.75, 0.3))                # the charge between them
			_p(img, 21, 2, Color(1.0, 0.9, 0.6))
			_part(img, 6, 0, 3, 1, Color(0.2, 0.2, 0.22))              # the sight
			_p(img, 8, 0, Color(1.0, 0.72, 0.25))
			_part(img, 9, 5, 2, 3, Color(0.24, 0.24, 0.26))            # the magazine
			_part(img, 6, 5, 2, 3, Color(0.2, 0.18, 0.16))             # the grip
			grip = Vector2(7, 6)
			muzzle = Vector2(21, 2)
		"wp_shotgun":                # Forge of Return scatter gun: dark bronze, a wide double bore, a pump, red glow
			img = _blank(20, 8)
			var br := Color(0.42, 0.3, 0.2)
			_part(img, 0, 2, 5, 3, Color(0.3, 0.2, 0.14))              # the stock
			_part(img, 5, 1, 6, 4, br)                                 # the receiver
			_part(img, 11, 1, 8, 2, br.darkened(0.15))                 # the barrels
			_r(img, 19, 1, 1, 2, Color(0.12, 0.1, 0.09))
			_part(img, 12, 3, 5, 2, Color(0.25, 0.18, 0.13))           # the pump
			_r(img, 6, 3, 4, 1, Color(1.0, 0.3, 0.2))                  # a red glow seam
			_p(img, 9, 1, Color(1.0, 0.45, 0.25))
			_part(img, 6, 5, 2, 3, Color(0.2, 0.15, 0.12))
			grip = Vector2(7, 6)
			muzzle = Vector2(20, 2)
		"wp_sniper":                 # Forge of Return long rail: very long, a big scope, a bipod, red rails
			img = _blank(32, 9)
			var br2 := Color(0.36, 0.26, 0.2)
			_part(img, 0, 3, 6, 3, Color(0.26, 0.18, 0.13))            # the stock with its cheek rest
			_p(img, 2, 2, Color(0.26, 0.18, 0.13))
			_part(img, 6, 2, 9, 4, br2)                                # the receiver
			_part(img, 15, 2, 15, 1, Color(0.45, 0.42, 0.4))           # the long rails
			_part(img, 15, 4, 15, 1, Color(0.45, 0.42, 0.4))
			_r(img, 16, 3, 14, 1, Color(1.0, 0.35, 0.25))              # the charge
			_r(img, 30, 2, 2, 3, Color(0.3, 0.28, 0.27))               # the muzzle brake
			_part(img, 8, 0, 6, 2, Color(0.18, 0.18, 0.2))             # the scope
			_p(img, 13, 0, Color(1.0, 0.45, 0.35))
			_part(img, 10, 6, 2, 3, Color(0.2, 0.15, 0.12))            # the grip
			_p(img, 20, 6, Color(0.3, 0.28, 0.27))                     # the folded bipod
			_r(img, 21, 7, 3, 1, Color(0.3, 0.28, 0.27))
			grip = Vector2(11, 7)
			muzzle = Vector2(32, 3)
		"wp_launcher":               # Hadrian grenade launcher: olive drum, a fat tube, a sight frame
			img = _blank(20, 9)
			var ol := Color(0.4, 0.44, 0.32)
			_part(img, 0, 3, 4, 3, Color(0.24, 0.24, 0.22))            # the stock
			_part(img, 4, 2, 6, 4, ol.darkened(0.1))
			_part(img, 6, 5, 5, 3, ol)                                 # the drum
			_p(img, 8, 6, Color(1.0, 0.6, 0.2))
			_part(img, 10, 1, 9, 4, ol)                                # the tube
			_r(img, 18, 2, 2, 2, Color(0.1, 0.1, 0.1))                 # its bore
			_part(img, 12, 0, 3, 1, Color(0.22, 0.22, 0.2))            # the sight frame
			_p(img, 14, 0, Color(1.0, 0.72, 0.25))
			_part(img, 5, 6, 1, 3, Color(0.2, 0.18, 0.16))
			grip = Vector2(5, 7)
			muzzle = Vector2(20, 3)
		_:
			img = _blank(14, 6)
			_part(img, 0, 1, 12, 3, Color(0.34, 0.36, 0.4))
			grip = Vector2(4, 4)
			muzzle = Vector2(14, 2)
	return {"img": img, "grip": grip, "muzzle": muzzle}


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
