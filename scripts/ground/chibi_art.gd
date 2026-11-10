class_name ChibiArt
extends RefCounted
## People on foot. 0.7.49.11 (Luz's choice "C3"): tall figures (18 × 40 px, about six heads), built from the same
## "look" as the portrait (skin, hair, eyes, outfit and colours, beard, headgear), black outlines and a neon rim
## light – cyan from the left, pink from the right, as if lit by the station's signs. Drawn at CHAR_SCALE screen px
## per pixel (finer than the deck's ×3, so they stand as tall as the doors allow).
## Directions: 0 down (towards the viewer), 1 up (away), 2 left, 3 right (mirrored).
## Frames: 0 standing, 1 and 2 walking, 3 sitting.

const PilotArt = preload("res://scripts/core/pilot_art.gd")
const GearData = preload("res://data/gear.gd")
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
## 0.7.51.10 (Luz): the powers' guards wear the combat suits in their own colours – [plate, light]
const LIVERY := {
	"independent": [Color(0.22, 0.23, 0.28), Color(0.3, 0.95, 1.0)],
	"assembly": [Color(0.68, 0.74, 0.84), Color(0.4, 0.68, 1.0)],
	"covenant": [Color(0.42, 0.16, 0.14), Color(1.0, 0.8, 0.3)],
	"directorate": [Color(0.93, 0.95, 0.95), Color(0.25, 0.85, 0.55)],
}


static func frame(look: Dictionary, dir: int, f: int) -> Texture2D:
	var l := PilotArt.clean(look)
	l["suit"] = String(look.get("suit", ""))             # 0.7.51.2: the suit (family) and, outside, its helmet
	l["helmet"] = bool(look.get("helmet", false))
	l["livery"] = String(look.get("livery", ""))            # 0.7.51.10: a power's colours on a combat suit
	var key := "%s_%s%d%s_%d_%d" % [PilotArt._key(l), l["suit"], int(l["helmet"]), l["livery"], dir, f]
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
	var suit := String(l.get("suit", ""))
	var sd: Dictionary = GearData.SUITS.get(suit, {})
	if not sd.is_empty():
		# 0.7.51.2: in the suit – its colours, plates on a combat suit, a zip and chest light on the others
		c1 = sd["col"]
		c2 = sd["trim"]
		outfit = 2 if suit.begins_with("suit_mil") else 0
	var combat := suit.begins_with("suit_mil")
	var heavy := suit == "suit_mil_heavy"
	var plate: Color = c1                     # 0.7.51.10: a combat suit – plates over a black undersuit, its lights
	var glow: Color = c2
	if combat and LIVERY.has(String(l.get("livery", ""))):
		plate = LIVERY[String(l["livery"])][0]
		glow = LIVERY[String(l["livery"])][1]
	var hand := skin
	if not sd.is_empty():
		hand = Color(0.14, 0.14, 0.17) if combat else c1.darkened(0.3)            # gloves
	if combat:
		c1 = Color(0.11, 0.11, 0.13)
	var sh := SH + (int(l["body"]) - 1) + (1 if heavy else 0)
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
	if not sd.is_empty():
		pants = c1.darkened(0.12) if not combat else c1
		boot = plate.darkened(0.45) if combat else Color(0.25, 0.26, 0.3)
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
	if outfit == 2 and sd.is_empty():
		_r(img, tx - 1, torso_top, 3, 2, c2.lightened(0.1))                        # shoulder plates
		if not side:
			_r(img, tx + tw - 2, torso_top, 3, 2, c2)
	# ---- arms and hands (swinging when walking)
	var al := TORSO + 1
	if side:
		var sw := step * 2
		_r(img, cx - 1 + sw, torso_top + 1, ARM - 1, al - 2, c1.darkened(0.2))
		_r(img, cx - 1 + sw, torso_top + al / 2, ARM - 1, 1, c1.darkened(0.4))
		_r(img, cx - 1 + sw, torso_top + al - 1, 2, 2, hand.darkened(0.08))
	else:
		var al_l := al - 2 + (step if step > 0 else 0)
		var al_r := al - 2 + (-step if step < 0 else 0)
		_r(img, tx - ARM, torso_top + 1, ARM, al_l, c1.darkened(0.12))
		_r(img, tx + tw, torso_top + 1, ARM, al_r, c1.darkened(0.3))
		_r(img, tx - ARM, torso_top + 1, 1, al_l, c1.lightened(0.05))
		_r(img, tx - ARM, torso_top + al / 2, ARM, 1, c1.darkened(0.25))
		_r(img, tx + tw, torso_top + al / 2, ARM, 1, c1.darkened(0.4))
		_r(img, tx - ARM, torso_top + 1 + al_l, ARM, 2, hand)
		_r(img, tx + tw, torso_top + 1 + al_r, ARM, 2, hand.darkened(0.15))
	# 0.7.51.2: the suit's life-support pack – on the back, its edge seen from the side
	if not sd.is_empty() and not sitting:
		var pk := c1.darkened(0.35)
		if back:
			_r(img, cx - 3, torso_top + 1, 6, 7, pk)
			_r(img, cx - 3, torso_top + 1, 6, 1, pk.lightened(0.2))
			_px(img, cx - 1, torso_top + 3, Color(0.35, 0.95, 1.0))
			_px(img, cx + 1, torso_top + 3, Color(0.4, 1.0, 0.55))
		elif side:
			_r(img, cx + int(sh * 0.8) - 1, torso_top + 1, 2, 7, pk)
		else:
			_r(img, cx - sh - 1, torso_top, 1, 2, pk.lightened(0.1))           # its straps over the shoulders
			_r(img, cx + sh, torso_top, 1, 2, pk)
	if combat and not sitting:
		_armour(img, plate, glow, heavy, cx, tx, tw, sh, torso_top, leg_top, feet, step, side, back)
	elif not sd.is_empty() and not sitting:
		_suit_detail(img, suit, c1, c2, cx, tx, tw, sh, torso_top, leg_top, side, back)
	# ---- neck and head
	_r(img, cx - 1, head_bot + 1, 2, NECK, skin.darkened(0.2) if sd.is_empty() else c2.darkened(0.2))
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
	# 0.7.51.2: the helmet – outside, where it is needed (0.7.51.10: or always, as the pilot wants it); its kind by the
	# suit: a glass dome (civilian, survey with its sensor), a hard shell with a lamp (work), a closed armoured helmet
	# with a dark visor (combat)
	if bool(l.get("helmet", false)) and not sd.is_empty():
		_helmet(img, suit, c1, c2, plate, glow, hx, head_top, head_bot, ey, side, back)
	return img


## 0.7.51.10 (Luz: "the combat suits should look a lot more dangerous"): plates over the black undersuit – a chest
## plate with its seam and light, a segmented belly, pauldrons, thigh, knee and shin plates, gauntlets; the heavy
## suit broader, its pauldrons standing out past the arms, an antenna off its pack.
static func _armour(img: Image, plate: Color, glow: Color, heavy: bool, cx: int, tx: int, tw: int, sh: int, torso_top: int,
		leg_top: int, feet: int, step: int, side: bool, back: bool) -> void:
	var dk := plate.darkened(0.3)
	var lt := plate.lightened(0.15)
	if side:
		_r(img, cx - 1, torso_top + 1, int(sh * 1.4), 6, plate)                     # the chest plate, seen side on
		_r(img, cx - 1, torso_top + 1, int(sh * 1.4), 1, lt)
		_r(img, cx - 1, torso_top + 8, int(sh * 1.2), 2, plate.darkened(0.1))
		_r(img, cx - 2, torso_top - 1, 5 if heavy else 4, 4, plate)                 # the pauldron
		_r(img, cx - 2, torso_top - 1, 5 if heavy else 4, 1, lt)
		var lx := cx - 1 + step * 2
		_r(img, lx, leg_top + 1, 3, 5, plate)                                     # thigh, knee, shin of the near leg
		_r(img, lx, leg_top + 7, 4, 2, lt)
		_r(img, lx, leg_top + 10, 3, feet - leg_top - 13, plate.darkened(0.05))
		_px(img, cx + int(sh * 1.4) - 2, torso_top + 3, glow)
		if heavy:
			_r(img, cx + int(sh * 0.8), torso_top - 7, 1, 8, Color(0.3, 0.3, 0.33))   # the antenna off the pack
			_px(img, cx + int(sh * 0.8), torso_top - 8, glow)
		return
	# legs: thigh plates, knee guards, shin plates (both legs; the far one darker)
	var lw := maxi(3, sh - 1)
	var up_l := maxi(0, step)
	var up_r := maxi(0, -step)
	for k in 2:
		var x0 := cx - lw if k == 0 else cx + 1
		var up := up_l if k == 0 else up_r
		var pc := plate if k == 0 else plate.darkened(0.15)
		_r(img, x0, leg_top + 1, lw, 5, pc)
		_r(img, x0, leg_top + 1, lw, 1, pc.lightened(0.15))
		_r(img, x0 - (1 if k == 0 else 0), leg_top + 7, lw + 1, 2, pc.lightened(0.18))
		_r(img, x0, leg_top + 10, lw, feet - leg_top - 13 - up, pc.darkened(0.05))
		_px(img, x0 + (lw - 1 if k == 0 else 0), leg_top + 11, dk)
	if back:
		_r(img, tx + 1, torso_top + 1, tw - 2, 6, plate)                          # the back plate around the pack
		_r(img, cx - 3, torso_top + 1, 6, 7, plate.darkened(0.35))
		_px(img, cx - 1, torso_top + 3, glow)
		_r(img, tx + 1, torso_top + 8, tw - 2, 2, plate.darkened(0.1))
	else:
		# the chest plate: two halves, a seam, a light under the collar; the belly in segments
		_r(img, tx + 1, torso_top + 1, tw - 2, 6, plate)
		_r(img, tx + 1, torso_top + 1, tw - 2, 1, lt)
		_r(img, cx, torso_top + 2, 1, 5, dk)
		_r(img, tx + 2, torso_top + 6, tw - 4, 1, dk)
		_px(img, cx + 2, torso_top + 3, glow)
		_px(img, cx - 3, torso_top + 4, glow.darkened(0.3))
		for seg in 2:
			_r(img, cx - 2 + seg, torso_top + 8 + seg * 2, 4 - seg * 2 + (2 if heavy else 0), 1, plate.darkened(0.08))
			_r(img, cx - 2 + seg - (1 if heavy else 0), torso_top + 8 + seg * 2, 1, 1, dk)
	# pauldrons – the heavy suit's stand out past the arms
	var pw := 5 if heavy else 4
	_r(img, tx - pw + 1, torso_top - 1, pw, 4, plate)
	_r(img, tx - pw + 1, torso_top - 1, pw, 1, lt)
	_r(img, tx + tw - 1, torso_top - 1, pw, 4, plate.darkened(0.12))
	_r(img, tx + tw - 1, torso_top - 1, pw, 1, lt.darkened(0.1))
	_r(img, tx - pw + 1, torso_top + 3, pw, 1, Color(0.04, 0.04, 0.06))
	_r(img, tx + tw - 1, torso_top + 3, pw, 1, Color(0.04, 0.04, 0.06))
	_px(img, tx - pw + 2, torso_top + 1, glow if heavy else dk)
	# gauntlets on the forearms
	_r(img, tx - ARM, torso_top + TORSO / 2 + 1, ARM, 4, plate.darkened(0.05))
	_r(img, tx + tw, torso_top + TORSO / 2 + 1, ARM, 4, plate.darkened(0.2))
	_px(img, tx - ARM + 1, torso_top + TORSO / 2 + 2, glow)
	if heavy:
		_r(img, tx + tw + pw - 2, torso_top - 9, 1, 8, Color(0.3, 0.3, 0.33))   # the antenna off the pack
		_px(img, tx + tw + pw - 2, torso_top - 10, glow)


## 0.7.51.10: what makes the other suits their own – the work suit's chest box and reflective bands, the survey suit's
## sensor pod and its cyan seams, the civilian suit's soft folds and its chest light.
static func _suit_detail(img: Image, suit: String, c1: Color, c2: Color, cx: int, tx: int, tw: int, sh: int, torso_top: int,
		leg_top: int, side: bool, back: bool) -> void:
	match suit:
		"suit_work":
			_r(img, tx, torso_top + 6, tw, 1, Color(0.95, 0.95, 0.9))                 # reflective bands
			if not side:
				_r(img, tx - ARM, torso_top + 7, ARM, 1, Color(0.95, 0.95, 0.9))
				_r(img, tx + tw, torso_top + 7, ARM, 1, Color(0.95, 0.95, 0.9))
			if not side and not back:
				_r(img, cx - 2, torso_top + 2, 4, 3, Color(0.25, 0.26, 0.3))            # the chest box
				_px(img, cx - 1, torso_top + 3, Color(1.0, 0.6, 0.2))
				_px(img, cx + 1, torso_top + 3, Color(0.4, 1.0, 0.55))
			_r(img, tx - 1, torso_top, 3, 2, c2)                                     # shoulder pads
			_r(img, tx + tw - 2, torso_top, 3, 2, c2.darkened(0.15))
		"suit_survey":
			if not back:
				_r(img, tx + 1, torso_top + 1, 1, TORSO - 3, c2)                       # cyan seams
				_r(img, tx + tw - 2, torso_top + 1, 1, TORSO - 3, c2.darkened(0.2))
			_r(img, tx + tw - 1, torso_top - 1, 3, 3, Color(0.3, 0.32, 0.36))         # the sensor pod on the shoulder
			_px(img, tx + tw, torso_top, c2)
		_:
			if not side and not back:
				_r(img, tx + 1, torso_top + 5, tw - 2, 1, c1.darkened(0.12))           # a soft fold
			_r(img, tx, torso_top + 9, tw, 1, c2.darkened(0.1))


## 0.7.51.10: the helmets by the suit.
static func _helmet(img: Image, suit: String, c1: Color, c2: Color, plate: Color, glow: Color, hx: int, head_top: int,
		head_bot: int, ey: int, side: bool, back: bool) -> void:
	if suit.begins_with("suit_mil"):
		var heavy := suit == "suit_mil_heavy"
		var gtop := head_top - 2
		var gbot := head_bot + 1
		for y in range(gtop, gbot + 1):                                             # a closed shell
			var cut := 2 if y == gtop else (1 if y == gtop + 1 else 0)
			_r(img, hx - 1 + cut, y, HW + 2 - 2 * cut, 1, plate if y < ey else plate.darkened(0.12))
		_r(img, hx, gtop, HW, 1, plate.lightened(0.2))
		if back:
			_r(img, hx + HW / 2, gtop, 1, gbot - gtop, plate.darkened(0.25))       # its ridge
		elif side:
			if not heavy:                                                           # the visor juts out, the back flares
				_r(img, hx - 3, ey - 2, 3, 4, plate.darkened(0.08))
				_r(img, hx - 3, ey - 2, 3, 1, plate.lightened(0.15))
				_r(img, hx - 3, ey - 1, 4, 2, Color(0.04, 0.04, 0.06))
				_px(img, hx - 3, ey - 1, Color(0.5, 0.6, 0.75))
				_r(img, hx - 2, ey + 2, 2, 2, plate.darkened(0.3))
				_r(img, hx + HW + 1, ey - 1, 1, 4, plate.darkened(0.2))
				_px(img, hx + HW + 1, ey, glow)
			else:
				_r(img, hx - 1, ey - 1, 3, 3, Color(0.04, 0.04, 0.06))              # the visor, side on
				_px(img, hx - 1, ey - 1, glow)
		else:
			if heavy:                                                               # a T-slit, lit red
				_r(img, hx, ey - 1, HW, 1, Color(0.04, 0.04, 0.06))
				_r(img, hx + HW / 2 - 1, ey - 1, 2, 4, Color(0.04, 0.04, 0.06))
				_r(img, hx + 1, ey - 1, HW - 2, 1, glow)
			else:                                                                   # a broad dark visor with a glint
				_r(img, hx, ey - 2, HW, 3, Color(0.04, 0.04, 0.06))
				_r(img, hx + 1, ey - 2, 2, 1, Color(0.5, 0.6, 0.75))
				_px(img, hx + HW - 2, ey, glow)
			_r(img, hx - 1, ey + 2, 1, 2, plate.darkened(0.3))                       # the jaw guard
			_r(img, hx + HW, ey + 2, 1, 2, plate.darkened(0.4))
		_r(img, hx - 1, gbot, HW + 2, 1, plate.darkened(0.4))                          # the neck seal
		return
	if suit == "suit_work":
		var wtop := head_top - 3
		_r(img, hx - 1, wtop + 1, HW + 2, 3, Color(0.95, 0.75, 0.2))                       # the hard shell
		_r(img, hx, wtop, HW, 1, Color(1.0, 0.85, 0.35))
		if not back:
			_r(img, hx, wtop + 4, HW, 4, Color(0.55, 0.8, 0.95, 0.55))           # the face glass
			_r(img, hx + (1 if side else 0), wtop + 5, 2, 1, Color(1, 1, 1, 0.85))
			_r(img, hx + HW / 2 - 1, wtop + 1, 2, 1, Color(1.0, 0.95, 0.7))         # the lamp
		_r(img, hx - 1, head_bot + 1, HW + 2, 1, Color(0.25, 0.26, 0.3))
		return
	# 0.7.51.10 (Luz: "like today's NASA helmets with the gold visors"): civilian and survey – a hard white EVA shell a
	# size bigger than the head, the gold sun visor down over the face, the visor's frame; the survey suit's lamps and
	# camera on its side
	var shell := Color(0.93, 0.93, 0.9)
	var gold := Color(0.9, 0.66, 0.22)
	var etop := head_top - 3
	var ebot := head_bot + 1
	for y3 in range(etop, ebot + 1):
		var cut3 := 2 if y3 == etop else (1 if y3 == etop + 1 or y3 == ebot else 0)
		_r(img, hx - 2 + cut3, y3, HW + 4 - 2 * cut3, 1, shell if y3 < ey + 2 else shell.darkened(0.08))
	_r(img, hx - 1, etop, HW + 2, 1, Color(1, 1, 1))
	if back:
		_r(img, hx, etop + 2, HW, 1, shell.darkened(0.15))
	elif side:
		_r(img, hx - 2, ey - 2, 3, 5, gold.darkened(0.1))                            # the visor's edge, side on
		_px(img, hx - 2, ey - 2, Color(1.0, 0.92, 0.6))
		_r(img, hx + 1, ey - 3, 1, 7, shell.darkened(0.25))                          # its frame
	else:
		_r(img, hx - 1, ey - 3, HW + 2, 6, shell.darkened(0.3))                       # the visor's frame
		_r(img, hx, ey - 2, HW, 4, gold)                                               # the gold visor
		_r(img, hx, ey - 2, HW, 1, gold.lightened(0.25))
		_r(img, hx, ey + 1, HW, 1, gold.darkened(0.25))
		_r(img, hx + 1, ey - 1, 2, 1, Color(1.0, 0.95, 0.75))                         # the sun on it
		_px(img, hx + HW - 2, ey, Color(1.0, 0.85, 0.5))
	_r(img, hx - 2, ebot, HW + 4, 1, c2)                                               # the neck ring in the suit's trim
	if suit == "suit_survey" and not back:
		var lx := hx + HW + 1 if not side else hx + HW
		_r(img, lx, ey - 3, 1, 3, Color(0.3, 0.32, 0.36))                             # lamps and camera on the side
		_px(img, lx, ey - 3, Color(1.0, 0.98, 0.85))
		_px(img, lx, ey - 1, c2)


## 0.7.51.13 (Luz): the easter egg behind the clinic's scanner – a skeleton the size of a person, bones lit pale
## cyan: the skull with its sockets, the spine, ribs, pelvis, the arm and leg bones (striding when walking).
static func skeleton(dir: int, f: int) -> Texture2D:
	var key := "skel_%d_%d" % [dir, f]
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var bone := Color(0.88, 0.97, 1.0)
	var dim := Color(0.55, 0.85, 1.0)
	var cx := W / 2
	var feet := H - 1
	var leg_top := feet - LEGS + 1
	var torso_top := leg_top - TORSO
	var head_bot := torso_top - NECK
	var head_top := head_bot - HH + 1
	var step := 0 if f == 0 or f == 3 else (1 if f == 1 else -1)
	var side := dir == 2 or dir == 3
	# the skull
	_r(img, cx - 3, head_top, 7, HH - 2, bone)
	_r(img, cx - 2, head_bot - 1, 5, 2, bone)
	if dir != 1:
		if side:
			_px(img, cx - 2, head_top + 3, Color(0.05, 0.08, 0.12))
			_r(img, cx - 3, head_bot - 1, 2, 1, dim)
		else:
			_r(img, cx - 2, head_top + 3, 2, 2, Color(0.05, 0.08, 0.12))           # the sockets
			_r(img, cx + 1, head_top + 3, 2, 2, Color(0.05, 0.08, 0.12))
			_px(img, cx, head_top + 5, Color(0.05, 0.08, 0.12))
			for t in 3:
				_px(img, cx - 1 + t, head_bot, Color(0.05, 0.08, 0.12))             # the teeth
	# the spine and the ribs
	_r(img, cx, head_bot + 1, 1, TORSO + NECK - 1, bone)
	for k in 4:
		var rw := 5 - (k / 2) if not side else 3
		_r(img, cx - rw, torso_top + 2 + k * 2, rw * 2 + 1, 1, dim)
	_r(img, cx - 4, torso_top + 1, 9 if not side else 4, 1, bone)                   # the collar bones
	# the pelvis
	_r(img, cx - 3, leg_top - 2, 7 if not side else 4, 2, bone)
	# the arms
	if not side:
		_r(img, cx - 5, torso_top + 1, 1, TORSO - 1, bone)
		_r(img, cx + 5, torso_top + 1, 1, TORSO - 1, bone)
		_r(img, cx - 6, torso_top + TORSO - 1, 2, 2, dim)
		_r(img, cx + 5, torso_top + TORSO - 1, 2, 2, dim)
	else:
		_r(img, cx + step * 2, torso_top + 2, 1, TORSO - 2, bone)
	# the legs, striding
	var up_l := maxi(0, step)
	var up_r := maxi(0, -step)
	if side:
		_r(img, cx - 1 - step * 2, leg_top, 1, LEGS - 2, dim)
		_r(img, cx + step * 2, leg_top, 1, LEGS - 2, bone)
		_r(img, cx + step * 2 - 1, feet - 1, 3, 1, bone)
	else:
		_r(img, cx - 2, leg_top, 1, LEGS - 2 - up_l, bone)
		_r(img, cx + 2, leg_top, 1, LEGS - 2 - up_r, bone)
		_r(img, cx - 3, leg_top + LEGS / 2 - up_l, 2, 1, dim)                       # the knees
		_r(img, cx + 2, leg_top + LEGS / 2 - up_r, 2, 1, dim)
		_r(img, cx - 3, feet - 1 - up_l, 3, 1, bone)
		_r(img, cx + 2, feet - 1 - up_r, 3, 1, bone)
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


static func _blend(img: Image, x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= W or y >= H:
		return
	var b := img.get_pixel(x, y)
	if b.a <= 0.0:
		img.set_pixel(x, y, c)
	else:
		img.set_pixel(x, y, Color(b.lerp(Color(c.r, c.g, c.b), c.a), 1.0))


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
