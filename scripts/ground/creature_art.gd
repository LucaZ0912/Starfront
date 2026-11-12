extends RefCounted
## Package 53f (Luz, 12 Nov 2026): the creatures and machines that are not people – drawn like the figures (ChibiArt:
## CHAR_SCALE screen px a pixel, rim light and outline), each its own size: the corporations' security robot (lanky,
## grey with sand-coloured plates, a narrow head with a red eye), the Precursors' robot (dark machinery under glossy blue
## plates – red once it sees you), the Dark Ones' necrotic things (black, violet cracks and eyes, steaming), the
## sewer's mutant rats, the mine's cave crawlers, the research station's escaped specimens.
## dir: 0 towards you, 1 away, 2 side (left), 3 side (right, mirrored); f: 0 standing, 1/2 walking. No class_name.

const KINDS := {
	"sec_robot": {"w": 22, "h": 58},
	"pre_robot": {"w": 24, "h": 58},
	"necrotic": {"w": 28, "h": 48},
	"rat": {"w": 16, "h": 9},
	"rat_brood": {"w": 30, "h": 17},
	"crawler": {"w": 28, "h": 14},
	"specimen": {"w": 26, "h": 20},
	# 53f-2 (Luz): the wild animals - jungle, coast, ice
	"grazer": {"w": 46, "h": 32},
	"glider": {"w": 18, "h": 10},
	"pack_hunter": {"w": 32, "h": 20},
	"lurker": {"w": 36, "h": 17},
	"shore_crab": {"w": 12, "h": 8},
	"armor_crab": {"w": 34, "h": 21},
	"sand_lurker": {"w": 24, "h": 20},
	"furball": {"w": 18, "h": 13},
	"frost_bear": {"w": 38, "h": 30},
	"frost_worm": {"w": 28, "h": 24},
}

const VIO := Color(0.62, 0.35, 1.0)
const ANIMALS := ["grazer", "glider", "pack_hunter", "lurker", "shore_crab", "armor_crab", "sand_lurker", "furball", "frost_bear", "frost_worm"]


## 53f-2: volume for the animals – each column lit from above (lighter on top, darker at the belly), a fine mottled
## texture, a glint in each eye-dark pixel's neighbour.
static func _volume(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var src: Image = img.duplicate()
	for x in w:
		var top := -1
		var bot := -1
		for y in h:
			if src.get_pixel(x, y).a > 0.3:
				if top < 0:
					top = y
				bot = y
		if top < 0:
			continue
		var span := maxf(1.0, float(bot - top))
		for y2 in range(top, bot + 1):
			var c := src.get_pixel(x, y2)
			if c.a <= 0.3:
				continue
			var t := float(y2 - top) / span
			var n := (fposmod(sin(float(x) * 12.9898 + float(y2) * 78.233) * 43758.5453, 1.0) - 0.5) * 0.09
			var lum := 0.16 * pow(1.0 - t, 2.0) - 0.22 * pow(t, 2.0) + n
			var c2 := c.lightened(lum) if lum > 0.0 else c.darkened(-lum)
			c2.a = c.a
			img.set_pixel(x, y2, c2)


static var _cache := {}


## The picture as a texture, cached (the necrotic's steam in eight steps).
static func texture(kind: String, dir: int, f: int, alert: bool, step: int) -> Texture2D:
	var key := "%s_%d_%d_%d_%d" % [kind, dir, f, int(alert), step if kind == "necrotic" else 0]
	if not _cache.has(key):
		_cache[key] = ImageTexture.create_from_image(image(kind, dir, f, alert, step * 0.125))
	return _cache[key]


static func image(kind: String, dir: int, f: int = 0, alert: bool = false, t: float = 0.0) -> Image:
	var k: Dictionary = KINDS.get(kind, {"w": 20, "h": 40})
	var img := Image.create(int(k["w"]), int(k["h"]), false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var d := 2 if dir == 3 else dir
	match kind:
		"sec_robot":
			_sec_robot(img, d, f)
		"pre_robot":
			_pre_robot(img, d, f, alert)
		"necrotic":
			_necrotic(img, d, f, t)
		"rat":
			_rat(img, d, f)
		"rat_brood":
			var small := Image.create(16, 9, false, Image.FORMAT_RGBA8)       # a rat twice the size, darker
			small.fill(Color(0, 0, 0, 0))
			_rat(small, d, f)
			small.resize(30, 17, Image.INTERPOLATE_NEAREST)
			for yy in small.get_height():
				for xx in small.get_width():
					var c := small.get_pixel(xx, yy)
					if c.a > 0.0:
						img.set_pixel(xx, yy, c.darkened(0.15))
		"crawler":
			_crawler(img, d, f)
		"specimen":
			_specimen(img, d, f)
		"grazer", "glider", "pack_hunter", "lurker", "shore_crab", "armor_crab", "sand_lurker", "furball", "frost_bear", "frost_worm":
			if d == 2:
				_animal(img, kind, f, alert)
			else:
				_front_of(img, kind, d, f, alert)                        # towards you / away: the side picture turned
	if kind in ANIMALS:
		_volume(img)                                         # 53f-2 (Luz: more detail): lit from above, a texture
	if dir == 3:
		img.flip_x()
	_rim(img)
	_outline(img)
	return img


## The figures' rim light (cyan from the left, pink from the right) – on the outer edges only, sized to this picture.
static func _rim(img: Image) -> void:
	var src := img.duplicate()
	var w := img.get_width()
	var h := img.get_height()
	for y in h:
		var row: Array = []
		for x in w:
			if src.get_pixel(x, y).a >= 0.5:
				row.append(x)
		if row.is_empty():
			continue
		var l: int = row.min()
		var r: int = row.max()
		img.set_pixel(l, y, src.get_pixel(l, y).lerp(ChibiArt.RIM_L, 0.4))
		img.set_pixel(r, y, src.get_pixel(r, y).lerp(ChibiArt.RIM_R, 0.5))


static func _outline(img: Image) -> void:
	var src := img.duplicate()
	var w := img.get_width()
	var h := img.get_height()
	for y in h:
		for x in w:
			if src.get_pixel(x, y).a >= 0.5:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < w and q.y < h and src.get_pixel(q.x, q.y).a >= 0.5:
					img.set_pixel(x, y, ChibiArt.OUTLINE)
					break


static func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		if c.a >= 0.999:
			img.set_pixel(x, y, c)
		else:
			img.set_pixel(x, y, img.get_pixel(x, y).blend(c))


static func _r(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			_px(img, xx, yy, c)


static func _ell(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for yy in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for xx in range(int(cx - rx) - 1, int(cx + rx) + 2):
			var dx := (xx + 0.5 - cx) / rx
			var dy := (yy + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				_px(img, xx, yy, c)


# ---------------------------------------------------------------- the corporations' security robot

static func _sec_robot(img: Image, dir: int, f: int) -> void:
	var g := Color(0.5, 0.52, 0.55)
	var gd := g.darkened(0.35)
	var tan := Color(0.72, 0.56, 0.32)
	var blk := Color(0.1, 0.1, 0.12)
	var W := img.get_width()
	var H := img.get_height()
	var cx := W / 2
	var step := 0 if f == 0 else (1 if f == 1 else -1)
	var hip := H - 22
	if dir == 2:
		# side on: thin, the head forward, the rifle along the body
		for leg in [-1, 1]:
			var lx: int = cx - 1 + leg * step * 2
			var c: Color = g if leg == 1 else gd
			_r(img, lx, hip, 2, 10, c)                                  # thigh
			_px(img, lx, hip + 10, blk)
			_r(img, lx + (1 if leg == 1 else 0), hip + 11, 2, 9, c)    # shin, a tan plate
			_r(img, lx + 1, hip + 12, 1, 4, tan)
			_r(img, lx - 1, H - 2, 4, 2, gd)                            # foot
		_r(img, cx - 2, hip - 3, 4, 3, gd)                              # pelvis
		_r(img, cx - 1, hip - 9, 2, 6, blk)                             # the spine
		_r(img, cx - 3, hip - 19, 7, 10, g)                             # the chest
		_r(img, cx - 3, hip - 19, 7, 1, g.lightened(0.15))
		_r(img, cx + 1, hip - 17, 2, 6, tan)
		_r(img, cx - 2, hip - 15, 2, 3, blk)
		_r(img, cx - 2, hip - 24, 3, 5, gd)                             # the neck
		_r(img, cx - 5, hip - 30, 7, 6, g)                              # the head, thrust forward
		_r(img, cx - 5, hip - 30, 7, 1, g.lightened(0.2))
		_px(img, cx - 5, hip - 27, Color(1.0, 0.2, 0.15))
		_r(img, cx - 1, hip - 29, 2, 1, tan)
		_r(img, cx + 1, hip - 34, 1, 4, gd)                             # the antenna
		_r(img, cx - 1 - step, hip - 18, 2, 12, gd)                     # the arm
		_r(img, cx - 8, hip - 8, 10, 2, blk)                            # the rifle
		_px(img, cx - 8, hip - 8, Color(1.0, 0.25, 0.2))
		return
	var back := dir == 1
	# the legs: long, thin, segmented
	for leg in [-1, 1]:
		var up: int = maxi(0, step * leg)
		var lx: int = cx + (2 if leg == 1 else -4)
		var c2: Color = g if leg == -1 else g.darkened(0.12)
		_r(img, lx, hip, 2, 10 - up, c2)
		_r(img, lx - 1, hip + 10 - up, 3, 1, blk)                       # the knee
		_r(img, lx, hip + 11 - up, 2, 9, c2)
		if not back:
			_r(img, lx, hip + 12 - up, 2, 3, tan)                       # a plate on the shin
		_r(img, lx - 1, H - 2 - up, 4, 2, gd)
	_r(img, cx - 4, hip - 3, 8, 3, gd)                                  # the pelvis
	_r(img, cx - 1, hip - 9, 2, 6, blk)                                 # the spine, cables beside it
	_px(img, cx - 2, hip - 7, Color(0.3, 0.3, 0.32))
	_px(img, cx + 1, hip - 5, Color(0.3, 0.3, 0.32))
	# the chest: broad, angular, tan trims and vents
	for y in 10:
		var inset := y / 4
		_r(img, cx - 6 + inset, hip - 19 + y, 12 - inset * 2, 1, g)
	_r(img, cx - 6, hip - 19, 12, 1, g.lightened(0.18))
	if not back:
		_r(img, cx - 5, hip - 17, 2, 3, tan)
		_r(img, cx + 3, hip - 17, 2, 3, tan)
		_r(img, cx - 2, hip - 16, 4, 1, blk)
		_r(img, cx - 2, hip - 14, 4, 1, blk)
		_px(img, cx - 3, hip - 12, Color(0.3, 1.0, 0.4))
	else:
		_r(img, cx - 3, hip - 18, 6, 6, gd)                             # the power pack
		_px(img, cx, hip - 16, Color(1.0, 0.75, 0.3))
	# the arms: long and thin, a tan cuff; the rifle in one hand
	for arm in [-1, 1]:
		var ax: int = cx + (7 if arm == 1 else -9)
		var sw: int = step * arm
		_r(img, ax, hip - 19, 2, 2, gd)                                 # the shoulder joint
		_r(img, ax, hip - 17 + sw, 2, 7, g)
		_px(img, ax, hip - 10 + sw, blk)
		_r(img, ax, hip - 9 + sw, 2, 6, g.darkened(0.1))
		_r(img, ax, hip - 8 + sw, 2, 2, tan)
		_r(img, ax, hip - 3 + sw, 2, 2, blk)                            # the hand
	if not back:
		_r(img, cx - 11, hip - 4, 4, 2, blk)                            # the rifle, held low
		_r(img, cx - 11, hip - 2, 1, 6, blk)
		_px(img, cx - 11, hip + 4, Color(1.0, 0.25, 0.2))
	# the neck and the head: narrow, tall, a tan stripe, the red eyes at its side
	_r(img, cx - 1, hip - 23, 2, 4, blk)
	_r(img, cx - 2, hip - 32, 5, 9, g)
	_r(img, cx - 2, hip - 32, 5, 1, g.lightened(0.2))
	_r(img, cx - 2, hip - 24, 5, 1, gd)
	if not back:
		_r(img, cx, hip - 31, 1, 6, tan)
		_px(img, cx + 2, hip - 28, Color(1.0, 0.2, 0.15))
		_px(img, cx + 2, hip - 27, Color(0.3, 1.0, 0.4))
	_r(img, cx + 3, hip - 35, 1, 4, gd)                                 # the antenna


# ---------------------------------------------------------------- the Precursors' robot

static func _pre_robot(img: Image, dir: int, f: int, alert: bool) -> void:
	var blue := Color(0.15, 0.45, 0.95) if not alert else Color(0.9, 0.15, 0.12)
	var bl := blue.lightened(0.35)
	var mech := Color(0.16, 0.16, 0.18)
	var md := Color(0.08, 0.08, 0.09)
	var steel := Color(0.42, 0.43, 0.46)
	var gold := Color(0.85, 0.66, 0.3)
	var W := img.get_width()
	var H := img.get_height()
	var cx := W / 2
	var step := 0 if f == 0 else (1 if f == 1 else -1)
	var hip := H - 22
	var side := dir == 2
	var back := dir == 1
	# legs: dark machinery, pistons, blue guards on the shins
	for leg in ([-1, 1] if not side else [1, -1]):
		var up: int = maxi(0, step * leg) if not side else 0
		var lx: int = cx + (2 if leg == 1 else -5) if not side else cx - 1 + leg * step * 2
		var c: Color = mech if leg == -1 or side else mech.darkened(0.2)
		_r(img, lx, hip, 3, 10 - up, c)
		_px(img, lx + 1, hip + 3, steel)
		_r(img, lx, hip + 10 - up, 3, 1, md)
		_r(img, lx, hip + 11 - up, 3, 9, c)
		if not back:
			_r(img, lx, hip + 12 - up, 3, 4, blue)                       # the shin guard
			_px(img, lx, hip + 12 - up, bl)
		_r(img, lx - 1, H - 2 - up, 5, 2, md)
	# the waist: pistons, gold
	_r(img, cx - 4, hip - 4, 8, 4, mech)
	_px(img, cx - 3, hip - 6, gold)
	_r(img, cx - 3, hip - 7, 1, 3, gold)
	_r(img, cx + 2, hip - 7, 1, 3, gold)
	# the chest: machinery, the blue V-plate over it
	if not side:
		_r(img, cx - 6, hip - 19, 12, 12, mech)
		for k in 6:
			_px(img, cx - 5 + (k * 3) % 10, hip - 17 + (k * 5) % 9, steel)
		if not back:
			for y in 7:
				var half := 6 - y / 2
				_r(img, cx - half, hip - 20 + y, 2, 1, blue)              # the V
				_r(img, cx + half - 2, hip - 20 + y, 2, 1, blue)
			_r(img, cx - 6, hip - 20, 12, 1, bl)
			_ell(img, cx, hip - 13, 1.6, 1.6, blue.lightened(0.5))         # the core light
		else:
			_r(img, cx - 6, hip - 20, 12, 3, blue)
			_r(img, cx - 1, hip - 17, 2, 9, md)                            # the spine
	else:
		_r(img, cx - 3, hip - 19, 7, 12, mech)
		_r(img, cx - 3, hip - 20, 7, 3, blue)
		_px(img, cx - 3, hip - 20, bl)
	# the arms: a big shoulder cylinder, dark forearms with blue guards
	for arm in ([-1, 1] if not side else [1]):
		var ax: int = cx + (6 if arm == 1 else -9) if not side else cx - 1
		var sw: int = step * arm
		_r(img, ax, hip - 20, 3, 4, steel)                              # the shoulder
		_r(img, ax, hip - 20, 3, 1, steel.lightened(0.3))
		_r(img, ax, hip - 16 + sw, 3, 6, mech)
		_r(img, ax, hip - 10 + sw, 3, 6, mech.darkened(0.1))
		_r(img, ax, hip - 9 + sw, 3, 3, blue)
		_r(img, ax, hip - 4 + sw, 3, 2, md)
	# the neck: cables; the head: a long carapace swept back
	_r(img, cx - 1, hip - 25, 2, 5, md)
	_px(img, cx - 2, hip - 24, gold)
	if side:
		for y2 in 7:
			_r(img, cx - 4 + y2 / 2, hip - 31 + y2, 9 - y2 / 3, 1, blue)
		_r(img, cx - 4, hip - 31, 6, 1, bl)
		_r(img, cx - 4, hip - 26, 3, 2, md)                              # the face under the carapace
		_px(img, cx - 4, hip - 25, blue.lightened(0.6))
	else:
		_r(img, cx - 3, hip - 32, 6, 7, blue)
		_r(img, cx - 2, hip - 33, 4, 1, blue)
		_r(img, cx - 3, hip - 32, 6, 1, bl)
		if not back:
			_r(img, cx - 2, hip - 27, 4, 2, md)                          # the face
			_r(img, cx - 1, hip - 26, 2, 1, blue.lightened(0.6))
		else:
			_r(img, cx - 1, hip - 31, 2, 5, blue.darkened(0.3))


# ---------------------------------------------------------------- the Dark Ones' necrotic things

static func _necrotic(img: Image, dir: int, f: int, t: float) -> void:
	var sk := Color(0.08, 0.07, 0.1)
	var sk2 := Color(0.17, 0.15, 0.2)
	var W := img.get_width()
	var H := img.get_height()
	var cx := W / 2
	var step := 0 if f == 0 else (1 if f == 1 else -1)
	var hip := H - 16
	var side := dir == 2
	var back := dir == 1
	# legs: short, bent, broad feet
	for leg in [-1, 1]:
		var up: int = maxi(0, step * leg)
		var lx: int = cx + (1 if leg == 1 else -5) if not side else cx - 2 + leg * step * 2
		_r(img, lx, hip, 4, 8 - up, sk if leg == -1 else sk2)
		_r(img, lx + (1 if not side else -1), hip + 8 - up, 4, 6, sk)
		_r(img, lx - 1, H - 2 - up, 6, 2, sk2)
	# the body: hunched, the shoulders broad and high, the head low between them
	var tw := 16 if not side else 9
	for y in 16:
		var w := tw - int(abs(y - 4) * 0.45)
		_r(img, cx - w / 2 + (2 if side else 0), hip - 16 + y, w, 1, sk2 if y < 3 else sk)
	# the long arms hanging to the knees, big hands
	for arm in ([-1, 1] if not side else [1]):
		var ax: int = cx + (7 if arm == 1 else -10) if not side else cx - 2
		var sw: int = step * arm
		_r(img, ax, hip - 15, 3, 10 + sw, sk2)
		_r(img, ax - (0 if arm == 1 else 1), hip - 5 + sw, 4, 8, sk)
		_r(img, ax - 1, hip + 3 + sw, 5, 3, sk2)                         # the hand, claws
		_px(img, ax - 1, hip + 6 + sw, Color(0.3, 0.2, 0.35))
		_px(img, ax + 3, hip + 6 + sw, Color(0.3, 0.2, 0.35))
	# the head, low and forward
	var hx := cx - 3 + (-3 if side else 0)
	_ell(img, hx + 3, hip - 17, 4, 4, sk)
	if not back:
		var e1 := Color(0.88, 0.65, 1.0)
		_r(img, hx + 1, hip - 18, 2, 1, e1)                               # the eyes, glowing
		if not side:
			_r(img, hx + 4, hip - 18, 2, 1, e1)
		_r(img, hx + 2, hip - 15, 3, 1, VIO.darkened(0.2))                # a mouth, glowing faintly
	# the cracks: violet, glowing, branching over the body
	var cracks := [[cx - 4, hip - 13, 1, 1], [cx - 3, hip - 12, 1, 1], [cx - 3, hip - 11, 1, 1], [cx - 2, hip - 10, 1, 1],
		[cx + 2, hip - 14, 1, 1], [cx + 3, hip - 13, 1, 1], [cx + 3, hip - 12, 1, 1], [cx + 1, hip - 7, 1, 1], [cx + 2, hip - 6, 1, 1],
		[cx - 1, hip - 5, 1, 1], [cx - 5, hip + 2, 1, 1], [cx + 4, hip + 4, 1, 1], [cx - 9, hip - 10, 1, 1], [cx + 8, hip - 8, 1, 1]]
	for c in cracks:
		if side and (c[0] < cx - 3 or c[0] > cx + 4):
			continue
		_px(img, int(c[0]) + (2 if side else 0), int(c[1]), VIO.lightened(0.15))
	# the steam: wisps rising off the shoulders, drifting with time
	for s in 11:
		var ph := fposmod(t * 0.7 + s * 0.37, 1.0)
		var sx := cx + (-6 if s % 2 == 0 else 5) + int(sin(t * 2.0 + s) * 1.5)
		var sy := hip - 17 - int(ph * 12.0)
		_px(img, sx, sy, Color(0.8, 0.75, 0.88, 0.7 * (1.0 - ph)))
		_px(img, sx + 1, sy - 1, Color(0.8, 0.75, 0.88, 0.45 * (1.0 - ph)))
		_px(img, sx - 1, sy - 2, Color(0.8, 0.75, 0.88, 0.3 * (1.0 - ph)))


# ---------------------------------------------------------------- the small ones

static func _rat(img: Image, dir: int, f: int) -> void:
	var fur := Color(0.36, 0.3, 0.26)
	var skin := Color(0.78, 0.52, 0.5)
	var W := img.get_width()
	var H := img.get_height()
	if dir == 2:
		_ell(img, 8, H - 4, 5, 2.6, fur)                                   # the body
		_r(img, 6, H - 6, 3, 1, skin)                                      # a bald patch
		_ell(img, 3, H - 4, 2.2, 1.8, fur.lightened(0.08))                 # the head
		_px(img, 1, H - 4, skin)                                           # the snout
		_px(img, 3, H - 5, Color(1.0, 0.15, 0.1))                          # the eye
		_px(img, 4, H - 7, skin)                                           # the ear
		for t in 4:
			_px(img, 13 + t, H - 4 + (t % 2) - (f % 2), skin.darkened(0.2))   # the tail
		_px(img, 5 + (f % 2), H - 1, fur.darkened(0.3))
		_px(img, 10 - (f % 2), H - 1, fur.darkened(0.3))
	else:
		_ell(img, W / 2.0, H - 4, 3.5, 3, fur)
		_r(img, W / 2 - 1, H - 6, 2, 1, skin)
		if dir == 0:
			_px(img, W / 2 - 2, H - 4, Color(1.0, 0.15, 0.1))
			_px(img, W / 2 + 1, H - 4, Color(1.0, 0.15, 0.1))
			_px(img, W / 2, H - 2, skin)
		else:
			_r(img, W / 2, H - 1, 1, 1, skin.darkened(0.2))


static func _crawler(img: Image, dir: int, f: int) -> void:
	var ch := Color(0.32, 0.27, 0.22)
	var cd := ch.darkened(0.35)
	var glow := Color(0.55, 1.0, 0.8)
	var W := img.get_width()
	var H := img.get_height()
	var cx := W / 2
	# six legs splayed, three a side
	for l in 3:
		var lx: int = 6 + l * 7
		var lift: int = (1 if (l + f) % 2 == 0 and f != 0 else 0)
		_r(img, lx - 3, H - 5 - lift, 2, 4, cd)
		_r(img, lx + 2, H - 5 + lift, 2, 4, cd)
	# the shell: segmented, low, pale glowing spots
	if dir == 2:
		_ell(img, cx, H - 7, 11, 4, ch)
		_ell(img, cx - 10, H - 7, 3, 3, ch.lightened(0.08))                # the head
		_px(img, cx - 12, H - 8, glow)
		for m in 3:
			_r(img, cx - 13, H - 6 + m, 2, 1, cd)                           # mandibles
	else:
		_ell(img, cx, H - 7, 9, 5, ch)
		for seg in 4:
			_r(img, cx - 8, H - 10 + seg * 2, 16, 1, cd)
		if dir == 0:
			_px(img, cx - 2, H - 4, glow)
			_px(img, cx + 1, H - 4, glow)
	for sp in 5:
		_px(img, cx - 7 + sp * 3, H - 9 + (sp % 2), glow.darkened(0.2))


static func _specimen(img: Image, dir: int, f: int) -> void:
	var sk := Color(0.82, 0.74, 0.74)
	var sd := sk.darkened(0.25)
	var W := img.get_width()
	var H := img.get_height()
	var cx := W / 2
	var step := 0 if f == 0 else (1 if f == 1 else -1)
	if dir == 2:
		for l in [[6, 1], [8, -1], [17, 1], [19, -1]]:
			_r(img, int(l[0]) + step * int(l[1]), H - 8, 2, 8, sd if int(l[1]) == -1 else sk)
		_ell(img, 13, H - 10, 8, 4, sk)                                     # the body, thin
		for rb in 4:
			_r(img, 9 + rb * 3, H - 13, 1, 4, sd)                            # ribs showing
		_ell(img, 4, H - 13, 3.5, 2.5, sk)                                  # the long head
		_r(img, 0, H - 13, 3, 2, sk)
		for e in 3:
			_px(img, 2 + e * 2, H - 14, Color(1.0, 0.85, 0.2))              # many eyes
		_r(img, 7, H - 13, 2, 3, Color(0.25, 0.27, 0.3))                    # the broken collar
		_px(img, 8, H - 10, Color(1.0, 0.3, 0.25))
		_r(img, 21, H - 12, 4, 1, sd)                                        # the tail
	else:
		for l2 in [-6, -3, 2, 5]:
			_r(img, cx + l2, H - 7, 2, 7, sd if l2 > 0 else sk)
		_ell(img, cx, H - 10, 6, 5, sk)
		_ell(img, cx, H - 15, 3.5, 3, sk)
		if dir == 0:
			for e2 in [[-2, -16], [1, -16], [-1, -14], [2, -14]]:
				_px(img, cx + int(e2[0]), H + int(e2[1]), Color(1.0, 0.85, 0.2))
			_r(img, cx - 3, H - 12, 6, 1, Color(0.25, 0.27, 0.3))
			_px(img, cx + 2, H - 11, Color(1.0, 0.3, 0.25))


# ---------------------------------------------------------------- 53f-2: the wild animals (side on; turned for the front)

static func _animal(img: Image, kind: String, f: int, alert: bool) -> void:
	match kind:
		"grazer":
			_grazer(img, f, alert)
		"glider":
			_glider(img, f, alert)
		"pack_hunter":
			_pack_hunter(img, f, alert)
		"lurker":
			_lurker(img, f, alert)
		"shore_crab":
			_shore_crab(img, f, alert)
		"armor_crab":
			_armor_crab(img, f, alert)
		"sand_lurker":
			_sand_lurker(img, f, alert)
		"furball":
			_furball(img, f, alert)
		"frost_bear":
			_frost_bear(img, f, alert)
		"frost_worm":
			_frost_worm(img, f, alert)


## Towards you or away: the side picture squeezed narrow and centred - a simple turn that reads at their size.
static func _front_of(img: Image, kind: String, dir: int, f: int, alert: bool) -> void:
	var side := Image.create(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
	side.fill(Color(0, 0, 0, 0))
	_animal(side, kind, f, alert)
	var nw := maxi(6, int(img.get_width() * 0.5))
	side.resize(nw, img.get_height(), Image.INTERPOLATE_NEAREST)
	img.blend_rect(side, Rect2i(0, 0, nw, img.get_height()), Vector2i((img.get_width() - nw) / 2, 0))
	if dir == 1:
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				if c.a > 0.0:
					img.set_pixel(x, y, c.darkened(0.12))


static func _legs(img: Image, xs: Array, top: int, h: int, c: Color, f: int) -> void:
	for i in xs.size():
		var lift := 1 if f != 0 and (i + f) % 2 == 0 else 0
		_r(img, int(xs[i]), top, 2, h - lift, c if i % 2 == 0 else c.darkened(0.15))


## The jungle's grazing herd: a big six-legged plant-eater, a long low neck, a ridge of plates down its back, pale
## stripes on a green-brown hide, a small head with blunt tusks.
static func _grazer(img: Image, f: int, alert: bool) -> void:
	var hide := Color(0.36, 0.38, 0.22)
	var dark := hide.darkened(0.35)
	var H := img.get_height()
	_legs(img, [14, 20, 26, 31, 37, 41], H - 11, 11, dark, f)
	_ell(img, 28, H - 17, 15, 8, hide)
	for st in 5:
		_r(img, 18 + st * 5, H - 23, 2, 9, Color(0.62, 0.6, 0.42))
	for pl in 6:
		_r(img, 17 + pl * 4, H - 26 - (pl % 2), 3, 3, Color(0.5, 0.36, 0.22))
	for nk in 9:
		_r(img, 13 - nk, H - 20 + int(nk * 0.3), 3, 4, hide.lightened(0.04))
	_ell(img, 4, H - 16, 4, 3, hide)
	_px(img, 3, H - 17, Color(0.1, 0.1, 0.08))
	_r(img, 1, H - 14, 2, 2, Color(0.9, 0.86, 0.72))
	_r(img, 42, H - 18, 3, 2, dark)


## A small glider lizard: orange membranes between its legs, a striped tail.
static func _glider(img: Image, f: int, alert: bool) -> void:
	var sk := Color(0.32, 0.5, 0.3)
	var H := img.get_height()
	var spread := 2 if f != 0 else 1
	_r(img, 4, H - 6 - spread, 9, spread + 2, Color(0.95, 0.55, 0.2))
	_ell(img, 8, H - 4, 5, 2, sk)
	_ell(img, 2, H - 4, 2, 1.6, sk.lightened(0.1))
	_px(img, 1, H - 5, Color(1.0, 0.9, 0.2))
	for t in 5:
		_px(img, 13 + t, H - 4 + (t % 2), sk if t % 2 == 0 else Color(0.85, 0.75, 0.3))
	_px(img, 5, H - 1, sk.darkened(0.3))
	_px(img, 11, H - 1, sk.darkened(0.3))


## A pack hunter: lean, long-tailed, a crest of quills, dark green with a yellow eye - they hunt in threes.
static func _pack_hunter(img: Image, f: int, alert: bool) -> void:
	var sk := Color(0.18, 0.3, 0.2)
	var H := img.get_height()
	_legs(img, [10, 13, 20, 23], H - 8, 8, sk.darkened(0.3), f)
	_ell(img, 16, H - 11, 9, 4, sk)
	_r(img, 9, H - 9, 14, 1, Color(0.5, 0.55, 0.32))
	for q in 6:
		_r(img, 10 + q * 2, H - 16 - (q % 2) * 2, 1, 3 + (q % 2) * 2, Color(0.75, 0.3, 0.15) if alert else Color(0.5, 0.25, 0.15))
	_ell(img, 5, H - 13, 4, 3, sk)
	_r(img, 0, H - 13, 4, 2, sk.lightened(0.08))
	_r(img, 0, H - 11, 4, 1, Color(0.9, 0.88, 0.8))
	_px(img, 4, H - 14, Color(1.0, 0.85, 0.2))
	for t in 8:
		_px(img, 24 + t, H - 11 - int(t * 0.4), sk if t < 6 else sk.darkened(0.2))


## The lurker: flat, wide-jawed, its hide mottled like the leaves - half seen until it moves (alert: plain to see).
static func _lurker(img: Image, f: int, alert: bool) -> void:
	var a := 1.0 if alert else 0.55
	var H := img.get_height()
	var g1 := Color(0.22, 0.4, 0.18, a)
	var g2 := Color(0.35, 0.52, 0.22, a)
	_legs(img, [8, 12, 24, 28], H - 5, 5, Color(0.15, 0.25, 0.12, a), f)
	_ell(img, 18, H - 8, 14, 5, g1)
	for m in 14:
		_r(img, 6 + (m * 7) % 24, H - 12 + (m * 3) % 6, 3, 2, g2 if m % 2 == 0 else Color(0.18, 0.3, 0.14, a))
	_ell(img, 4, H - 8, 5, 4, g1)
	_r(img, 0, H - 7, 6, 2, Color(0.55, 0.15, 0.15, a))
	_r(img, 0, H - 8, 6, 1, Color(0.95, 0.92, 0.8, a))
	_px(img, 3, H - 11, Color(1.0, 0.75, 0.2, maxf(a, 0.8)))
	for fr in 4:
		_px(img, 6 + fr, H - 13 - fr % 2, Color(0.5, 0.65, 0.25, a))
	_r(img, 31, H - 8, 5, 2, g1)


## A beach crab - small, orange, it scuttles off sideways.
static func _shore_crab(img: Image, f: int, alert: bool) -> void:
	var sh := Color(0.9, 0.45, 0.2)
	var H := img.get_height()
	_ell(img, 6, H - 3, 4, 2.4, sh)
	_px(img, 4, H - 6, Color(0.1, 0.1, 0.1))
	_px(img, 7, H - 6, Color(0.1, 0.1, 0.1))
	_r(img, 0, H - 5, 2, 2, sh.lightened(0.1))
	_r(img, 10, H - 5, 2, 2, sh.lightened(0.1))
	for l in 3:
		_px(img, 2 + l * 3, H - 2 + (1 if f != 0 and l % 2 == 0 else 0), sh.darkened(0.3))


## The armoured crab: as big as a hover-bike, a blue-grey shell with barnacles, one huge claw.
static func _armor_crab(img: Image, f: int, alert: bool) -> void:
	var sh := Color(0.32, 0.4, 0.5)
	var H := img.get_height()
	for l in 4:
		var lx := 8 + l * 5
		var lift := 1 if f != 0 and l % 2 == f % 2 else 0
		_r(img, lx, H - 6 - lift, 2, 6 - lift, sh.darkened(0.35))
		_px(img, lx - 1, H - 6 - lift, sh.darkened(0.35))
	_ell(img, 18, H - 10, 13, 6, sh)
	_ell(img, 16, H - 12, 9, 3, sh.lightened(0.12))
	for b in 6:
		_px(img, 9 + b * 3, H - 14 + (b % 2), Color(0.85, 0.85, 0.8))
	_px(img, 7, H - 15, Color(0.1, 0.1, 0.12))
	_r(img, 7, H - 14, 1, 2, sh.darkened(0.2))
	_ell(img, 3, H - 11, 4, 4, sh.lightened(0.05))
	_r(img, 0, H - 13, 3, 2, Color(0.75, 0.3, 0.25) if alert else sh.darkened(0.25))


## The sand lurker: a ring-mouthed eel rearing from a mound of sand.
static func _sand_lurker(img: Image, f: int, alert: bool) -> void:
	var sand := Color(0.8, 0.72, 0.52)
	var sk := Color(0.55, 0.45, 0.5)
	var H := img.get_height()
	_ell(img, 12, H - 3, 11, 3, sand)
	var rise := 11 if alert else 4
	for y in rise:
		_r(img, 10 + int(sin(y * 0.4) * 1.5), H - 5 - y, 5, 1, sk if y % 3 else sk.darkened(0.2))
	if alert:
		_ell(img, 12, H - 6 - rise, 4, 3, sk.lightened(0.1))
		_ell(img, 12, H - 6 - rise, 2.5, 2, Color(0.5, 0.1, 0.12))
		for t in 6:
			var a2 := t * TAU / 6.0
			_px(img, int(12 + cos(a2) * 2.5), int(H - 6 - rise + sin(a2) * 2), Color(0.95, 0.92, 0.85))


## A furball of the ice: round, shaggy, little horns, in small groups.
static func _furball(img: Image, f: int, alert: bool) -> void:
	var fur := Color(0.88, 0.84, 0.76)
	var H := img.get_height()
	_legs(img, [5, 11], H - 3, 3, Color(0.35, 0.3, 0.28), f)
	_ell(img, 9, H - 7, 7, 5, fur)
	for t in 8:
		_px(img, 3 + t * 2, H - 12 + (t % 2), fur.darkened(0.12))
	_ell(img, 3, H - 8, 3, 2.5, fur.lightened(0.04))
	_px(img, 2, H - 9, Color(0.1, 0.1, 0.1))
	_px(img, 1, H - 7, Color(0.35, 0.25, 0.25))
	_px(img, 3, H - 11, Color(0.55, 0.48, 0.4))


## The frost bear: big, white, pale blue plates down its back, a dark muzzle.
static func _frost_bear(img: Image, f: int, alert: bool) -> void:
	var fur := Color(0.9, 0.92, 0.95)
	var H := img.get_height()
	_legs(img, [9, 13, 25, 29], H - 9, 9, fur.darkened(0.2), f)
	for l in [9, 13, 25, 29]:
		_r(img, int(l) - 1, H - 2, 4, 2, fur.darkened(0.3))
	_ell(img, 20, H - 15, 14, 8, fur)
	for pl in 5:
		_r(img, 13 + pl * 4, H - 23 + (pl % 2), 3, 3, Color(0.55, 0.7, 0.85))
	_ell(img, 6, H - 16, 6, 5, fur)
	_r(img, 0, H - 15, 4, 3, Color(0.25, 0.25, 0.3))
	_px(img, 5, H - 18, Color(0.15, 0.2, 0.35) if not alert else Color(0.9, 0.2, 0.15))
	_px(img, 8, H - 21, fur.darkened(0.15))


## The frost worm: a pale blue segmented worm arching out of the snow, its mouth glowing.
static func _frost_worm(img: Image, f: int, alert: bool) -> void:
	var sk := Color(0.62, 0.78, 0.9)
	var H := img.get_height()
	_ell(img, 14, H - 2, 13, 2, Color(0.95, 0.97, 1.0))
	if not alert:
		for i in 14:                                                       # a low arch in the snow, waiting
			var t := float(i) / 13.0
			_ell(img, 4.0 + t * 18.0, float(H - 3) - sin(t * PI) * 6.0, 3, 3, sk if i % 2 == 0 else sk.darkened(0.12))
		return
	for i2 in 12:                                                          # rearing up out of the snow, swaying
		var t2 := float(i2) / 11.0
		var x2 := 12.0 + sin(t2 * PI * 1.4) * 4.0
		var y2 := float(H - 3) - t2 * 17.0
		_ell(img, x2, y2, 3.4 - t2 * 0.6, 3, sk if i2 % 2 == 0 else sk.darkened(0.12))
	_ell(img, 12.0 + sin(PI * 1.4) * 4.0, H - 21, 3.5, 3, sk.lightened(0.1))
	_ell(img, 12.0 + sin(PI * 1.4) * 4.0, H - 21, 2, 1.5, Color(0.5, 0.9, 1.0))
