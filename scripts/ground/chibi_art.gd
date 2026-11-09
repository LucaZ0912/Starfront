class_name ChibiArt
extends RefCounted
## People on foot. 0.7.49.11 (Luz's choice "C3"): tall figures (18 × 40 px, about six heads), built from the same
## "look" as the portrait (skin, hair, eyes, outfit and colours, beard, headgear), black outlines and a neon rim
## light – cyan from the left, pink from the right, as if lit by the station's signs. Drawn at CHAR_SCALE screen px
## per pixel (finer than the deck's ×3, so they stand as tall as the doors allow).
## Directions: 0 down (towards the viewer), 1 up (away), 2 left, 3 right (mirrored).
## Frames: 0 standing, 1 and 2 walking, 3 sitting.

const PilotArt = preload("res://scripts/core/pilot_art.gd")
const W := 18
const H := 40
const CHAR_SCALE := 2.0
const OUTLINE := Color(0.06, 0.05, 0.08)
const RIM_L := Color(0.3, 0.9, 1.0)
const RIM_R := Color(1.0, 0.35, 0.8)
const HIP_SIT := 10                   # sitting: the hips this many px above the feet

# proportions
const HW := 7                         # head width
const HH := 8                         # head height
const NECK := 2
const TORSO := 12
const LEGS := 17
const SH := 5                         # half the shoulders' width (± body type)
const ARM := 3

static var _cache := {}


static func frame(look: Dictionary, dir: int, f: int) -> Texture2D:
	var l := PilotArt.clean(look)
	var key := "%s_%d_%d" % [PilotArt._key(l), dir, f]
	if not _cache.has(key):
		var img := _draw(l, 2 if dir == 3 else dir, f)
		if dir == 3:
			img.flip_x()
		_rim(img)
		_outline(img)
		_cache[key] = ImageTexture.create_from_image(img)
	return _cache[key]


static func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < W and y < H:
		img.set_pixel(x, y, c)


static func _r(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
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
	var outfit := int(l["outfit"])
	var sh := SH + (int(l["body"]) - 1)
	var cx := W / 2
	var sitting := f == 3
	var legs := LEGS if not sitting else HIP_SIT
	var feet := H - 1
	var leg_top := feet - legs + 1
	var torso_top := leg_top - TORSO
	var head_bot := torso_top - NECK
	var head_top := head_bot - HH + 1
	var pants := c1.darkened(0.45) if outfit != 2 else c1.darkened(0.15)
	var boot := Color(0.17, 0.14, 0.13)
	var step := 0 if f == 0 or f == 3 else (1 if f == 1 else -1)
	var side := dir == 2
	var back := dir == 1
	# ---- legs and boots
	if sitting:
		if side:
			_r(img, cx - 6, leg_top, 8, 3, pants)                      # thighs forward on the seat
			_r(img, cx - 6, leg_top, 8, 1, pants.lightened(0.12))
			_r(img, cx - 6, leg_top + 3, 3, legs - 5, pants.darkened(0.1))   # shins down
			_r(img, cx - 7, feet - 1, 4, 2, boot)
			_r(img, cx - 7, feet - 1, 4, 1, boot.lightened(0.25))
		elif not back:
			_r(img, cx - 4, leg_top, 3, 3, pants.lightened(0.1))       # knees towards you
			_r(img, cx + 1, leg_top, 3, 3, pants)
			_r(img, cx - 4, leg_top + 3, 3, legs - 5, pants.darkened(0.08))
			_r(img, cx + 1, leg_top + 3, 3, legs - 5, pants.darkened(0.18))
			_r(img, cx - 5, feet - 1, 4, 2, boot)
			_r(img, cx + 1, feet - 1, 4, 2, boot.darkened(0.1))
			_r(img, cx - 5, feet - 1, 4, 1, boot.lightened(0.25))
	elif side:
		var lw := 3
		# the far leg darker; striding: one forward, one back
		_r(img, cx - 2 - step * 2, leg_top, lw, legs - 3, pants.darkened(0.18))
		_r(img, cx - 2 - step * 2 - 1, feet - 2, lw + 1, 3, boot.darkened(0.15))
		_r(img, cx - 1 + step * 2, leg_top, lw, legs - 3, pants)
		_r(img, cx - 1 + step * 2, leg_top, 1, legs - 3, pants.lightened(0.12))
		_r(img, cx - 2 + step * 2, feet - 2, lw + 2, 3, boot)
		_r(img, cx - 2 + step * 2, feet - 2, lw + 2, 1, boot.lightened(0.25))
	else:
		var lw2 := maxi(3, sh - 1)
		var up_l := maxi(0, step)                                      # walking: the lifted leg is shorter
		var up_r := maxi(0, -step)
		_r(img, cx - lw2, leg_top, lw2, legs - 3 - up_l, pants)
		_r(img, cx + 1, leg_top, lw2, legs - 3 - up_r, pants.darkened(0.12))
		_r(img, cx - lw2, leg_top, 1, legs - 3 - up_l, pants.lightened(0.12))
		_r(img, cx - 2, leg_top + legs / 2, 1, 1, pants.darkened(0.25))
		_r(img, cx + 2, leg_top + legs / 2, 1, 1, pants.darkened(0.3))
		_r(img, cx - lw2 - 1, feet - 2 - up_l, lw2 + 1, 3, boot)
		_r(img, cx + 1, feet - 2 - up_r, lw2 + 1, 3, boot.darkened(0.1))
		if not back:
			_r(img, cx - lw2 - 1, feet - 2 - up_l, lw2 + 1, 1, boot.lightened(0.25))
			_r(img, cx + 1, feet - 2 - up_r, lw2 + 1, 1, boot.lightened(0.15))
	# ---- torso: broad shoulders, a narrower waist
	var tw := sh * 2 if not side else int(sh * 1.6)
	var tx := cx - tw / 2
	for y in TORSO:
		var yy := torso_top + y
		var inset := 1 if y == 0 else 0
		var taper := int(round(float(y) / TORSO)) if not side else 0
		_r(img, tx + inset + taper, yy, tw - 2 * (inset + taper), 1, c1)
		_px(img, tx + inset + taper, yy, c1.lightened(0.18))
		_px(img, tx + tw - 1 - inset - taper, yy, c1.darkened(0.3))
	if not side and not back:
		if outfit in [1, 3]:
			_r(img, cx - 1, torso_top + 1, 2, TORSO - 2, c2.lightened(0.1))        # the shirt under the jacket
			_r(img, cx - 2, torso_top + 1, 1, 3, c1.darkened(0.25))                # lapels
			_r(img, cx + 1, torso_top + 1, 1, 3, c1.darkened(0.25))
		else:
			_r(img, cx, torso_top + 1, 1, TORSO - 3, c1.darkened(0.25))           # zip
			_r(img, cx - sh + 2, torso_top + 2, 2, 2, c2)                          # chest patch
			_px(img, cx + sh - 3, torso_top + 2, Color(0.4, 1.0, 0.8))             # a little light
	elif back:
		_r(img, cx - 2, torso_top + 2, 4, 1, c1.darkened(0.2))                     # shoulder seam
		_r(img, cx, torso_top + 3, 1, TORSO - 5, c1.darkened(0.15))
	var belt_y := leg_top - 2
	_r(img, tx + (1 if not side else 0), belt_y, tw - (2 if not side else 0), 1, c2.darkened(0.2))
	if not side and not back:
		_px(img, cx, belt_y, Color(0.85, 0.75, 0.4))
	if outfit == 3 and not sitting:
		var tl := LEGS / 2
		if not side:
			_r(img, tx, leg_top - 1, 2, tl, c1.darkened(0.1))
			_r(img, tx + tw - 2, leg_top - 1, 2, tl, c1.darkened(0.25))
			if back:
				_r(img, tx, leg_top - 1, tw, tl - 2, c1.darkened(0.15))
		else:
			_r(img, tx - 1 + 3, leg_top - 1, 2, tl, c1.darkened(0.15))
	if outfit == 2:
		_r(img, tx - 1, torso_top, 3, 2, c2.lightened(0.1))                        # shoulder plates
		if not side:
			_r(img, tx + tw - 2, torso_top, 3, 2, c2)
	# ---- arms and hands (swinging when walking)
	var al := TORSO + 1
	if side:
		var sw := step * 2
		_r(img, cx - 1 + sw, torso_top + 1, ARM - 1, al - 2, c1.darkened(0.2))
		_r(img, cx - 1 + sw, torso_top + al / 2, ARM - 1, 1, c1.darkened(0.4))
		_r(img, cx - 1 + sw, torso_top + al - 1, 2, 2, skin.darkened(0.08))
	else:
		var al_l := al - 2 + (step if step > 0 else 0)
		var al_r := al - 2 + (-step if step < 0 else 0)
		_r(img, tx - ARM, torso_top + 1, ARM, al_l, c1.darkened(0.12))
		_r(img, tx + tw, torso_top + 1, ARM, al_r, c1.darkened(0.3))
		_r(img, tx - ARM, torso_top + 1, 1, al_l, c1.lightened(0.05))
		_r(img, tx - ARM, torso_top + al / 2, ARM, 1, c1.darkened(0.25))
		_r(img, tx + tw, torso_top + al / 2, ARM, 1, c1.darkened(0.4))
		_r(img, tx - ARM, torso_top + 1 + al_l, ARM, 2, skin)
		_r(img, tx + tw, torso_top + 1 + al_r, ARM, 2, skin.darkened(0.15))
	# ---- neck and head
	_r(img, cx - 1, head_bot + 1, 2, NECK, skin.darkened(0.2))
	var hx := cx - HW / 2
	for y in HH:
		var cut := 1 if (y == 0 or y == HH - 1) else 0
		_r(img, hx + cut, head_top + y, HW - 2 * cut, 1, skin)
		_px(img, hx + HW - 1 - cut, head_top + y, skin.darkened(0.15))
	var hs := int(l["hair"])
	var bald := hs == 0
	var ey := head_top + HH / 2
	if back:
		# from behind: the hair (or a bald head with a shine)
		if not bald:
			_r(img, hx, head_top - 1, HW, HH - 1, hair)
			_r(img, hx + 1, head_top - 2, HW - 2, 1, hair)
			_r(img, hx + 1, head_top - 1, HW / 2, 1, hair.lightened(0.22))
			if hs in [4, 5]:
				_r(img, hx, head_top + HH - 2, HW, 5 if hs == 4 else 2, hair.darkened(0.1))
				if hs == 5:
					_r(img, cx - 1, head_top + HH, 2, 5, hair.darkened(0.15))
			if hs == 8:
				_r(img, cx - 2, head_top - 4, 4, 3, hair.darkened(0.15))
			if hs == 6:
				_r(img, cx - 1, head_top - 4, 2, 3, hair)
		else:
			_px(img, hx + 2, head_top + 1, skin.lightened(0.3))
	elif side:
		_px(img, hx - 1, ey + 1, skin)                                   # nose
		_px(img, hx + 1, ey, eye.darkened(0.2))
		_r(img, hx + 1, ey - 1, 2, 1, hair.darkened(0.1))
		_px(img, hx + 1, ey + 2, skin.darkened(0.35))
		_px(img, hx + HW / 2 + 1, ey + 1, skin.darkened(0.25))            # ear
		if not bald:
			_r(img, hx + 1, head_top - 2, HW - 1, 3, hair)
			_r(img, hx + HW / 2, head_top - 1, HW / 2 + 1, HH / 2 + 1, hair)
			_r(img, hx + 2, head_top - 2, HW / 2, 1, hair.lightened(0.22))
			if hs in [4, 5]:
				_r(img, hx + HW - 1, head_top + 2, 2, HH + (3 if hs == 4 else 0), hair.darkened(0.1))
			if hs == 5:
				_r(img, hx + HW + 1, head_top + 2, 2, 4, hair.darkened(0.15))
			if hs == 6:
				_r(img, hx + 2, head_top - 4, HW - 3, 2, hair)
			if hs == 8:
				_r(img, hx + HW - 2, head_top - 3, 3, 3, hair.darkened(0.15))
		if int(l["beard"]) in [2, 3]:
			_r(img, hx, ey + 2, HW / 2, HH - HH / 2 - 2, hair)
		if int(l["headgear"]) == 2:
			_r(img, hx - 1, ey - 1, 3, 2, Color(0.3, 0.85, 1.0))
	else:
		_px(img, cx - 2, ey, Color(0.95, 0.95, 0.95))
		_px(img, cx - 1, ey, eye.darkened(0.2))
		_px(img, cx + 1, ey, eye.darkened(0.2))
		_px(img, cx + 2, ey, Color(0.95, 0.95, 0.95))
		_r(img, cx - 2, ey - 1, 2, 1, hair.darkened(0.1))                # brows
		_r(img, cx + 1, ey - 1, 2, 1, hair.darkened(0.1))
		_px(img, cx, ey + 1, skin.darkened(0.2))                          # nose
		_r(img, cx - 1, ey + 2, 3, 1, skin.darkened(0.35))                # mouth
		if int(l["freckles"]) == 1:
			_px(img, cx - 3, ey + 1, Color(0.75, 0.45, 0.3))
			_px(img, cx + 3, ey + 1, Color(0.75, 0.45, 0.3))
		match int(l["beard"]):
			1:
				_r(img, hx + 1, ey + 2, HW - 2, 2, Color(hair, 0.5).lerp(skin, 0.45))
			2:
				_r(img, cx - 1, ey + 2, 3, 2, hair)
				_r(img, cx - 1, ey + 2, 3, 1, skin.darkened(0.35))
			3:
				_r(img, hx + 1, ey + 1, HW - 2, HH - HH / 2 - 1, hair)
				_r(img, cx - 1, ey + 2, 3, 1, skin.darkened(0.35))
			4:
				_r(img, cx - 2, ey + 1, 5, 1, hair)
		if not bald:
			_r(img, hx, head_top - 1, HW, 3, hair)
			_r(img, hx + 1, head_top - 2, HW - 2, 1, hair)
			_r(img, hx + 1, head_top - 2, HW / 2 - 1, 1, hair.lightened(0.25))
			_r(img, hx - 1, head_top, 1, HH / 2, hair.darkened(0.1))
			_r(img, hx + HW, head_top, 1, HH / 2, hair.darkened(0.2))
			if hs == 1:
				_r(img, hx, head_top + 1, HW, 1, skin)                    # buzz cut: only a cap of hair
			if hs in [2, 3, 7]:
				_r(img, hx + (0 if hs == 3 else 2), head_top + 1, HW / 2, 1, hair)
			if hs in [4, 5]:
				_r(img, hx - 1, head_top, 1, HH + (4 if hs == 4 else 1), hair.darkened(0.1))
				_r(img, hx + HW, head_top, 1, HH + (4 if hs == 4 else 1), hair.darkened(0.2))
			if hs == 6:
				_r(img, hx, head_top - 1, HW, 2, skin)
				_r(img, cx - 1, head_top - 4, 2, 5, hair)
			if hs == 7:
				for k in 4:
					_px(img, hx + k * 2, head_top - 2, hair.lightened(0.15))
			if hs == 8:
				_r(img, cx - 2, head_top - 4, 4, 2, hair.darkened(0.15))
		match int(l["headgear"]):
			1:
				_r(img, hx - 1, ey - 1, 1, 3, Color(0.25, 0.25, 0.3))
				_r(img, hx, head_top - 2, HW, 1, Color(0.25, 0.25, 0.3))
			2:
				_r(img, hx, ey - 1, HW, 2, Color(0.3, 0.85, 1.0))
			3:
				_r(img, cx - 3, ey, 2, 1, Color(0.8, 0.9, 1.0, 0.8))
				_r(img, cx + 1, ey, 2, 1, Color(0.8, 0.9, 1.0, 0.8))
		if int(l["implant"]) == 1:
			_px(img, cx + 1, ey, Color(1.0, 0.25, 0.25))
	return img


## Neon rim light: the left edge catches cyan, the right edge pink.
static func _rim(img: Image) -> void:
	var src := img.duplicate()
	for y in H:
		for x in W:
			var c: Color = src.get_pixel(x, y)
			if c.a < 0.5:
				continue
			if x < W / 2 and (x == 0 or src.get_pixel(x - 1, y).a < 0.5):
				img.set_pixel(x, y, c.lerp(RIM_L, 0.45))
			elif x >= W / 2 and (x == W - 1 or src.get_pixel(x + 1, y).a < 0.5):
				img.set_pixel(x, y, c.lerp(RIM_R, 0.6))


## A black outline round the figure – it reads on any floor.
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
