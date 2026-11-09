class_name ChibiArt
extends RefCounted
## Package 49 (0.7.49.2): people on foot in a slanted, cosy top-down view – a small figure (16 × 24 art px) with a big
## head, seen from the front, the back or the side, built from the same "look" as the portrait (skin, hair, eyes,
## outfit colours, beard, headgear). Four directions × three frames (standing, two steps).
## Directions: 0 down (towards the viewer), 1 up (away), 2 left, 3 right. Frame 3 (0.7.49.7): sitting, the legs bent.

const PilotArt = preload("res://scripts/core/pilot_art.gd")
const W := 16
const H := 24
const OUTLINE := Color(0.09, 0.07, 0.11)

static var _cache := {}


static func frame(look: Dictionary, dir: int, f: int) -> Texture2D:
	var l := PilotArt.clean(look)
	var key := "%s_%d_%d" % [PilotArt._key(l), dir, f]
	if not _cache.has(key):
		var img := _draw(l, dir if dir != 3 else 2, f)
		if dir == 3:
			img.flip_x()
		_outline(img)
		_cache[key] = ImageTexture.create_from_image(img)
	return _cache[key]


static func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < W and y < H:
		img.set_pixel(x, y, c)


static func _rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			_px(img, xx, yy, c)


static func _draw(l: Dictionary, dir: int, f: int) -> Image:
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c1: Color = PilotArt.CLOTH[l["color1"]]
	var c2: Color = PilotArt.CLOTH[l["color2"]]
	var skin: Color = PilotArt.SKINS[l["skin"]]
	var hair: Color = PilotArt.HAIR_COLORS[l["hair_color"]]
	var eye: Color = PilotArt.EYES[l["eyes"]]
	var bw: int = [4, 5, 6][int(l["body"])]                     # half the shoulders' width … roughly
	var cx := 8
	var step := 0 if f == 0 or f == 3 else (1 if f == 1 else -1)
	# legs and shoes (rows 19–23)
	var pants: Color = c1.darkened(0.45) if int(l["outfit"]) != 2 else c1.darkened(0.2)
	var shoe := Color(0.16, 0.13, 0.12)
	if f == 3:
		if dir == 2:
			_rect(img, cx - 6, 18, 7, 3, pants)                  # the thighs forward, on the seat
			_rect(img, cx - 6, 21, 3, 2, pants.darkened(0.1))     # the shins down
			_rect(img, cx - 7, 23, 4, 1, shoe)
		elif dir == 0:
			_rect(img, cx - 3, 19, 3, 2, pants.lightened(0.08))   # the knees towards you
			_rect(img, cx, 19, 3, 2, pants.lightened(0.08))
			_rect(img, cx - 3, 21, 3, 1, pants.darkened(0.1))
			_rect(img, cx, 21, 3, 1, pants.darkened(0.1))
			_rect(img, cx - 3, 22, 3, 1, shoe)
			_rect(img, cx, 22, 3, 1, shoe)
	elif dir == 2:
		_rect(img, cx - 2 + step, 19, 3, 4, pants)
		_rect(img, cx - 1 - step, 19, 3, 4, pants.darkened(0.15))
		_rect(img, cx - 3 + step, 23, 4, 1, shoe)
		_rect(img, cx - 2 - step, 23, 3, 1, shoe.lightened(0.1))
	else:
		_rect(img, cx - 3, 19 - maxi(0, step), 3, 4 + maxi(0, step), pants)
		_rect(img, cx, 19 - maxi(0, -step), 3, 4 + maxi(0, -step), pants.darkened(0.1))
		_rect(img, cx - 3, 23, 3, 1, shoe)
		_rect(img, cx, 23, 3, 1, shoe)
	# body (rows 11–19)
	var top := 11
	if dir == 2:
		_rect(img, cx - 3, top, 6, 8, c1)
		_rect(img, cx - 3, top, 6, 1, c1.lightened(0.2))
		_rect(img, cx + 2, top + 1, 1, 7, c1.darkened(0.25))
		if int(l["outfit"]) in [1, 3]:
			_rect(img, cx - 4, top + 6, 1, 3, c1.darkened(0.15))          # coat tail
		_rect(img, cx - 3, top + 5, 6, 1, c2)                            # belt
		# the arm swings
		_rect(img, cx - 1 - step, top + 1, 2, 6, c1.darkened(0.12))
		_rect(img, cx - 1 - step, top + 7, 2, 1, skin)
	else:
		_rect(img, cx - bw, top + 1, bw * 2, 7, c1)
		_rect(img, cx - bw + 1, top, bw * 2 - 2, 1, c1.lightened(0.15))
		_rect(img, cx - bw, top + 5, bw * 2, 1, c2)                      # belt / accent
		if dir == 0:
			_rect(img, cx - 1, top + 1, 2, 4, c2 if int(l["outfit"]) in [0, 2] else c1.lightened(0.25))   # zip / collar
			if int(l["outfit"]) == 3:
				_rect(img, cx - bw, top + 1, 2, 7, c1.darkened(0.2))      # coat lapels
				_rect(img, cx + bw - 2, top + 1, 2, 7, c1.darkened(0.2))
		# arms at the sides, swinging
		_rect(img, cx - bw - 1, top + 1 + maxi(0, step), 1, 6, c1.darkened(0.2))
		_rect(img, cx + bw, top + 1 + maxi(0, -step), 1, 6, c1.darkened(0.2))
		_px(img, cx - bw - 1, top + 7 + maxi(0, step), skin)
		_px(img, cx + bw, top + 7 + maxi(0, -step), skin)
	# head (rows 1–11): big and round
	var hx0 := cx - 5
	var hy0 := 1
	for y in 10:
		for x in 10:
			var dx := (x + 0.5 - 5.0) / 5.0
			var dy := (y + 0.5 - 5.2) / 5.2
			if dx * dx + dy * dy <= 1.0:
				_px(img, hx0 + x, hy0 + y, skin if y > 1 else skin.lightened(0.05))
	_px(img, hx0 + 1, hy0 + 8, skin.darkened(0.12))
	var bald := int(l["hair"]) == 0
	var hs := int(l["hair"])
	if dir == 1:
		# from behind: all hair (or the bald head with a little shine)
		for y2 in 9:
			for x2 in 10:
				var dx2 := (x2 + 0.5 - 5.0) / 5.0
				var dy2 := (y2 + 0.5 - 5.0) / 5.0
				if dx2 * dx2 + dy2 * dy2 <= 1.0 and not bald:
					_px(img, hx0 + x2, hy0 + y2, hair if (x2 + y2) % 5 != 0 else hair.darkened(0.15))
		if hs in [4, 5]:
			_rect(img, cx - 2, hy0 + 8, 4, 4 if hs == 4 else 3, hair.darkened(0.1))     # long hair / ponytail
		if hs == 8:
			_rect(img, cx - 1, hy0 - 1, 3, 2, hair.darkened(0.2))                         # bun
		if bald:
			_px(img, cx - 2, hy0 + 2, skin.lightened(0.3))
	else:
		# hair on top (front / side)
		if not bald:
			var fringe := 3 if hs in [2, 3, 7] else 2
			if hs == 1:
				fringe = 1
			for x3 in 10:
				for y3 in fringe + 1:
					var dx3 := (x3 + 0.5 - 5.0) / 5.0
					var dy3 := (y3 + 0.5 - 5.2) / 5.2
					if dx3 * dx3 + dy3 * dy3 <= 1.0:
						_px(img, hx0 + x3, hy0 + y3, hair)
			if hs == 3:
				_rect(img, hx0 + 1, hy0 + 2, 4, 2, hair)                                   # side part
			if hs == 6:
				_rect(img, cx - 1, hy0 - 2, 2, 4, hair)                                    # mohawk
			if hs in [4, 5]:
				_rect(img, hx0, hy0 + 2, 1, 7 if hs == 4 else 3, hair)
				_rect(img, hx0 + 9, hy0 + 2, 1, 7 if hs == 4 else 3, hair)
				if dir == 2:
					_rect(img, hx0 + 6, hy0 + 2, 3, 7 if hs == 4 else 4, hair)
			if hs == 7:
				for k in 5:
					_px(img, hx0 + 1 + k * 2, hy0, hair.lightened(0.15))
			if hs == 8:
				_rect(img, cx - 1, hy0 - 1, 3, 2, hair.darkened(0.2))
			if dir == 2:
				_rect(img, hx0 + 5, hy0 + 1, 5, 4, hair)                                  # the back of the head
		# the face
		if dir == 0:
			_px(img, cx - 2, hy0 + 5, OUTLINE)
			_px(img, cx + 1, hy0 + 5, OUTLINE)
			_px(img, cx - 2, hy0 + 4, eye.lightened(0.2))
			_px(img, cx + 1, hy0 + 4, eye.lightened(0.2))
			_px(img, cx - 3, hy0 + 6, skin.darkened(0.1) if int(l["freckles"]) == 0 else Color(0.75, 0.45, 0.3))
			_px(img, cx + 2, hy0 + 6, skin.darkened(0.1) if int(l["freckles"]) == 0 else Color(0.75, 0.45, 0.3))
			_rect(img, cx - 1, hy0 + 7, 2, 1, skin.darkened(0.3))                          # mouth
			if int(l["beard"]) == 1:
				_rect(img, cx - 3, hy0 + 7, 6, 2, Color(hair, 0.5).lerp(skin, 0.4))
			elif int(l["beard"]) in [2, 3]:
				_rect(img, cx - (1 if int(l["beard"]) == 2 else 3), hy0 + 7, 2 if int(l["beard"]) == 2 else 6, 2 if int(l["beard"]) == 2 else 3, hair)
				_rect(img, cx - 1, hy0 + 7, 2, 1, skin.darkened(0.3))
			elif int(l["beard"]) == 4:
				_rect(img, cx - 2, hy0 + 6, 4, 1, hair)
		elif dir == 2:
			_px(img, cx - 3, hy0 + 5, OUTLINE)
			_px(img, cx - 3, hy0 + 4, eye.lightened(0.2))
			_px(img, hx0, hy0 + 6, skin.darkened(0.1))                                      # nose
			_px(img, cx - 3, hy0 + 7, skin.darkened(0.3))
			if int(l["beard"]) in [2, 3]:
				_rect(img, hx0 + 1, hy0 + 7, 4, 2, hair)
		# headgear
		match int(l["headgear"]):
			1:
				_rect(img, hx0 - 1 if dir != 2 else hx0 + 4, hy0 + 4, 1, 3, Color(0.25, 0.25, 0.3))     # headset
				_rect(img, hx0 + 1, hy0, 8, 1, Color(0.25, 0.25, 0.3))
			2:
				if dir == 0:
					_rect(img, cx - 3, hy0 + 4, 6, 2, Color(0.3, 0.85, 1.0))                   # visor
				elif dir == 2:
					_rect(img, hx0, hy0 + 4, 3, 2, Color(0.3, 0.85, 1.0))
			3:
				if dir == 0:
					_rect(img, cx - 3, hy0 + 4, 2, 2, Color(0.75, 0.85, 0.95))
					_rect(img, cx + 1, hy0 + 4, 2, 2, Color(0.75, 0.85, 0.95))
		if int(l["implant"]) == 1 and dir == 0:
			_px(img, cx + 1, hy0 + 4, Color(1.0, 0.25, 0.25))
	return img


## A dark outline round the figure – it reads on any floor.
static func _outline(img: Image) -> void:
	var src := img.duplicate()
	for y in H:
		for x in W:
			if src.get_pixel(x, y).a > 0.0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < W and q.y < H and src.get_pixel(q.x, q.y).a > 0.5:
					img.set_pixel(x, y, OUTLINE)
					break
