extends RefCounted
## Package 62a, part 7 (Luz): the pictures of Survivor's swarms, drawn like the figures and the creatures (one
## scale, rim light, outline) so that they belong to the same world.
##   shambler: one of the colony who still walks: hunched, the head to one side, the arms stretched out ahead, the
##   work overalls torn, the skin a sick green, the eyes two points of light. Four colours of overalls.
## dir: 0 towards you, 1 away, 2 side (left), 3 side (right, mirrored); f: 0 standing, 1 / 2 walking.
## No class_name: preload("res://scripts/ground/survivor_art.gd").

const CA = preload("res://scripts/ground/creature_art.gd")
const W := 24
const H := 40
const SUITS := [Color(0.62, 0.36, 0.14), Color(0.22, 0.33, 0.48), Color(0.42, 0.43, 0.46), Color(0.48, 0.44, 0.2)]
const SKINS := [Color(0.5, 0.62, 0.44), Color(0.56, 0.6, 0.5), Color(0.44, 0.56, 0.46)]

## How large the picture of each kind is (art px; a shambler's where a kind is not named).
const SIZES := {"warden": Vector2i(76, 64), "core": Vector2i(52, 66), "pylon": Vector2i(20, 60), "bulwark": Vector2i(36, 62), "seeker": Vector2i(16, 16), "jammer": Vector2i(20, 46), "hunter": Vector2i(44, 22), "enforcer": Vector2i(22, 58), "gunner": Vector2i(26, 58), "scout": Vector2i(30, 22), "hauler": Vector2i(40, 56), "bloater": Vector2i(32, 40), "shieldbearer": Vector2i(28, 40), "screecher": Vector2i(38, 24), "foreman": Vector2i(52, 66),
	"brood": Vector2i(78, 66), "mite": Vector2i(22, 14), "burrower": Vector2i(28, 30), "rimeback": Vector2i(36, 34), "glider": Vector2i(44, 22), "worm": Vector2i(48, 76), "heart": Vector2i(48, 70)}

static var _cache := {}


## The size of a kind's picture (art px).
static func size_of(kind: String) -> Vector2i:
	return SIZES.get(kind, Vector2i(W, H))


## The picture of one of the swarm as a texture, cached. `v`: which of its looks.
static func texture(kind: String, v: int, dir: int, f: int) -> Texture2D:
	var key := "%s_%d_%d_%d" % [kind, v % 4, dir, f]
	if not _cache.has(key):
		_cache[key] = ImageTexture.create_from_image(image(kind, v % 4, dir, f))
	return _cache[key]


static func image(kind: String, v: int, dir: int, f: int) -> Image:
	var sz := size_of(kind)
	var img := Image.create(sz.x, sz.y, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var d := 2 if dir == 3 else dir
	match kind:
		"runner":
			_runner(img, d, f, v)
		"spitter":
			_spitter(img, d, f, v)
		"bloater":
			_bloater(img, d, f, v)
		"shieldbearer":
			_shieldbearer(img, d, f, v)
		"howler":
			_howler(img, d, f, v)
		"hauler":
			_hauler(img, d, f, v, false)
		"foreman":
			_hauler(img, d, f, v, true)
		"screecher":
			_screecher(img, f, v)
		"brood":
			_brood(img, f)
		"enforcer":
			_enforcer(img, d, f, v, false)
		"gunner":
			_enforcer(img, d, f, v, true)
		"scout":
			_scout(img, d, f, v)
		"bulwark":
			_bulwark(img, d, f, v)
		"seeker":
			_seeker(img, f, v)
		"jammer":
			_jammer(img, d, f, v)
		"hunter":
			_hunter(img, f, v)
		"warden":
			_warden(img, d, f)
		"core":
			_core(img, f)
		"pylon":
			_pylon(img, f)
		"mite":
			_mite(img, d, f, v)
		"burrower":
			_burrower(img, d, f, v)
		"rimeback":
			_rimeback(img, d, f, v)
		"shardthrower":
			_shardthrower(img, d, f, v)
		"glider":
			_glider(img, f, v)
		"worm":
			_iceworm(img, d, f)
		"heart":
			_stormheart(img, f)
		_:
			_shambler(img, d, f, v)
	if dir == 3:
		img.flip_x()
	CA._rim(img)
	CA._outline(img)
	return img


static func _shambler(img: Image, dir: int, f: int, v: int) -> void:
	var skin: Color = SKINS[v % SKINS.size()]
	var skin2 := skin.darkened(0.28)
	var suit: Color = SUITS[v % SUITS.size()]
	var suit2 := suit.darkened(0.3)
	var boot := Color(0.12, 0.12, 0.14)
	var hair := Color(0.16, 0.14, 0.13)
	var eye := Color(0.92, 1.0, 0.4)
	var gore := Color(0.36, 0.08, 0.1)
	var cx := W / 2
	var step := 0 if f == 0 else (1 if f == 1 else -1)
	var hip := H - 13
	var side := dir == 2
	var back := dir == 1
	# the legs: dragging, one after the other
	for leg in [-1, 1]:
		var up: int = maxi(0, step * leg)
		var lx: int = (cx - 4 if leg == -1 else cx + 1) if not side else cx - 1 + leg * step * 2
		CA._r(img, lx, hip, 3, 10 - up, suit2 if leg == -1 else suit)
		CA._r(img, lx - (1 if side else 0), H - 3 - up, 4, 2, boot)
	# the body: hunched; from the side leaning forward, the shoulders ahead of the hips
	if side:
		for y in 12:
			var lean := int(float(11 - y) * 0.36)
			CA._r(img, cx - 3 - lean, hip - 12 + y, 6, 1, suit2 if y < 2 else suit)
		CA._r(img, cx - 2, hip - 6, 2, 3, skin2)                       # a tear in the overalls
		CA._px(img, cx - 2, hip - 4, gore)
	else:
		CA._r(img, cx - 5, hip - 12, 10, 12, suit)
		CA._r(img, cx - 5, hip - 12, 10, 2, suit2)                      # the shoulders, sunk
		CA._r(img, cx - 5, hip - 1, 10, 1, suit2)
		if not back:
			CA._r(img, cx + 1, hip - 8, 3, 3, skin2)                    # a tear, what is under it
			CA._px(img, cx + 2, hip - 7, gore)
			CA._r(img, cx - 4, hip - 5, 2, 1, gore)
	# the arms: stretched out ahead
	if side:
		CA._r(img, cx - 11, hip - 11, 7, 2, suit)
		CA._r(img, cx - 13, hip - 11, 2, 2, skin)
		CA._r(img, cx - 10, hip - 8 + step, 6, 2, suit2)
		CA._r(img, cx - 12, hip - 8 + step, 2, 2, skin2)
	else:
		for arm in [-1, 1]:
			var ax: int = cx - 7 if arm == -1 else cx + 5
			var sw: int = step * arm
			CA._r(img, ax, hip - 11, 2, 5 + sw, suit2)
			CA._r(img, ax, hip - 6 + sw, 2, 3, skin)                    # the forearm bare, the sleeve gone
			if not back:
				CA._r(img, ax - (1 if arm == -1 else 0), hip - 4 + sw, 3, 2, skin2)      # the hands, held out at you
	# the head: low, to one side
	var hx: int = cx + (-5 if side else (1 if v % 2 == 0 else -1))
	var hy := hip - 16
	CA._ell(img, hx + 0.5, hy, 3.6, 4.0, skin)
	if back:
		CA._r(img, hx - 3, hy - 4, 7, 6, hair)
	else:
		CA._r(img, hx - 3, hy - 4, 7, 2, hair)
		CA._px(img, hx - 3 if side else hx + 3, hy - 2, hair)
		if side:
			CA._px(img, hx - 2, hy, eye)
			CA._r(img, hx - 3, hy + 2, 2, 1, gore)
		else:
			CA._px(img, hx - 1, hy, eye)
			CA._px(img, hx + 2, hy, eye)
			CA._r(img, hx - 1, hy + 2, 3, 1, gore)


# ---------------------------------------------------------------- the shards of light

## Part 7c (Luz: more of a look of the future): a shard as a small cell of energy, a crystal with six sides, a core
## of light down its middle and a glint running over it. Four kinds by what it is worth (SD.shard_tier): cyan,
## green, gold (larger), magenta (larger still). `f`: 0 … 3, the glint on its way.
const SHARD_COL := [Color(0.3, 0.9, 1.0), Color(0.4, 1.0, 0.55), Color(1.0, 0.8, 0.3), Color(1.0, 0.4, 0.85)]
const SHARD_SIZE := [Vector2i(7, 9), Vector2i(7, 9), Vector2i(9, 11), Vector2i(11, 13)]


static func shard(tier: int, f: int) -> Texture2D:
	var key := "shard_%d_%d" % [tier, f]
	if not _cache.has(key):
		var sz: Vector2i = SHARD_SIZE[clampi(tier, 0, 3)]
		var col: Color = SHARD_COL[clampi(tier, 0, 3)]
		var img := Image.create(sz.x + 2, sz.y + 2, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		var half := sz.x / 2
		for y in sz.y:
			var inset := maxi(0, half - y) if y < half else maxi(0, half - (sz.y - 1 - y))
			for x in range(inset, sz.x - inset):
				var c := col
				if x < half:
					c = col.lightened(0.3)                          # the side towards the light
				elif x > half:
					c = col.darkened(0.32)
				if y < half:
					c = c.lightened(0.15)
				img.set_pixel(x + 1, y + 1, c)
		for y2 in range(2, sz.y - 2):                            # the core of light
			img.set_pixel(half + 1, y2 + 1, col.lerp(Color(1, 1, 1), 0.75 if (y2 + f) % 2 == 0 else 0.5))
		var gy := 1 + (f * (sz.y - 3)) / 3                       # the glint, on its way down the bright side
		img.set_pixel(maxi(1, half - 1) + 1, gy + 1, Color(1, 1, 1))
		if half >= 4:
			img.set_pixel(half - 2 + 1, gy + 2, Color(1, 1, 1, 0.8))
		CA._outline(img)
		_cache[key] = ImageTexture.create_from_image(img)
	return _cache[key]


# ---------------------------------------------------------------- part 7c-2: the rest of the stage

## A figure of the swarm from parts: legs, a body, arms, a head. `p`: "skin", "suit" (colours), "w" / "h" (the
## body's width seen from the front, its height), "lean" (from the side: how far the shoulders stand ahead of the
## hips), "arms": "out" (stretched ahead) | "down" | "back" (trailing) | "up" (thrown up), "head" (its radius), "low"
## (how deep it hangs), "eye" (the colour of the eyes), "hair" (a colour, or none), "legs" (their length).
## "arms": "none" draws none (a kind that holds them its own way puts them on afterwards).
## Returns where its parts ended up ({"cx", "hip", "hx", "hy", "top"}) for what a kind adds on top.
static func _figure(img: Image, dir: int, f: int, p: Dictionary) -> Dictionary:
	var skin: Color = p.get("skin", SKINS[0])
	var skin2 := skin.darkened(0.28)
	var suit: Color = p.get("suit", SUITS[0])
	var suit2 := suit.darkened(0.3)
	var boot := Color(0.12, 0.12, 0.14)
	var cx := img.get_width() / 2
	var hh := img.get_height()
	var step := 0 if f == 0 else (1 if f == 1 else -1)
	var legs := int(p.get("legs", 10))
	var hip := hh - 3 - legs
	var bw := int(p.get("w", 10))
	var bh := int(p.get("h", 12))
	var lean := float(p.get("lean", 0.36))
	var side := dir == 2
	var back := dir == 1
	var stride := int(p.get("stride", 2))
	for leg in [-1, 1]:
		var up: int = maxi(0, step * leg)
		var lx: int = (cx - bw / 2 + 1 if leg == -1 else cx + bw / 2 - 4) if not side else cx - 1 + leg * step * stride
		CA._r(img, lx, hip, 3, legs - up, suit2 if leg == -1 else suit)
		CA._r(img, lx - (1 if side else 0), hh - 3 - up, 4, 2, boot)
	var top_off := 0
	if side:
		for y in bh:
			var off := int(float(bh - 1 - y) * lean)
			if y == 0:
				top_off = off
			CA._r(img, cx - 3 - off, hip - bh + y, 6, 1, suit2 if y < 2 else suit)
	else:
		CA._r(img, cx - bw / 2, hip - bh, bw, bh, suit)
		CA._r(img, cx - bw / 2, hip - bh, bw, 2, suit2)
		CA._r(img, cx - bw / 2, hip - 1, bw, 1, suit2)
	var arms := String(p.get("arms", "out"))
	if side:
		var sx := cx - 3 - top_off
		match arms:
			"out":
				CA._r(img, sx - 7, hip - bh + 1, 7, 2, suit)
				CA._r(img, sx - 9, hip - bh + 1, 2, 2, skin)
				CA._r(img, sx - 6, hip - bh + 4 + step, 6, 2, suit2)
				CA._r(img, sx - 8, hip - bh + 4 + step, 2, 2, skin2)
			"down":
				CA._r(img, sx + 1, hip - bh + 2, 2, 7 + step, suit2)
				CA._r(img, sx + 1, hip - bh + 9 + step, 2, 2, skin)
			"back":
				CA._r(img, sx + 5, hip - bh + 2, 6, 2, suit2)
				CA._r(img, sx + 11, hip - bh + 2 + step, 2, 2, skin)
			"up":
				for q in 6:
					CA._r(img, sx - 1 - q, hip - bh - q, 2, 2, suit2 if q < 4 else skin)
	else:
		for arm in [-1, 1]:
			var ax: int = cx - bw / 2 - 2 if arm == -1 else cx + bw / 2
			var sw: int = step * arm
			match arms:
				"up":
					CA._r(img, ax, hip - bh - 5, 2, 7, suit2)
					CA._r(img, ax, hip - bh - 7, 2, 2, skin)
				"back":
					CA._r(img, ax - (1 if arm == -1 else -1), hip - bh + 2, 2, 6, suit2)
					CA._r(img, ax - (2 if arm == -1 else -2), hip - bh + 7, 2, 2, skin)
				"none":
					pass
				_:
					CA._r(img, ax, hip - bh + 1, 2, 5 + sw, suit2)
					CA._r(img, ax, hip - bh + 6 + sw, 2, 3, skin)
					if arms == "out" and not back:
						CA._r(img, ax - (1 if arm == -1 else 0), hip - bh + 8 + sw, 3, 2, skin2)
	var hr := float(p.get("head", 3.6))
	var hx: int = cx + (-5 - top_off if side else int(p.get("tilt", 0)))
	var hy := hip - bh - int(hr) + int(p.get("low", 0))
	CA._ell(img, hx + 0.5, hy, hr, hr + 0.4, skin)
	var hair = p.get("hair", Color(0.16, 0.14, 0.13))
	var eye: Color = p.get("eye", Color(0.92, 1.0, 0.4))
	if back:
		if hair != null:
			CA._r(img, hx - 3, hy - 4, 7, 6, hair)
	else:
		if hair != null:
			CA._r(img, hx - 3, hy - 4, 7, 2, hair)
		if side:
			CA._px(img, hx - 2, hy, eye)
		else:
			CA._px(img, hx - 1, hy, eye)
			CA._px(img, hx + 2, hy, eye)
	return {"cx": cx, "hip": hip, "hx": hx, "hy": hy, "top": top_off, "bw": bw, "bh": bh}


## A limb: a row of squares `w` wide from a to b.
static func _limb(img: Image, a: Vector2, b: Vector2, w: int, col: Color) -> void:
	var steps := int(maxf(absf(b.x - a.x), absf(b.y - a.y)))
	for q in steps + 1:
		var p := a.lerp(b, float(q) / float(maxi(1, steps)))
		CA._r(img, int(round(p.x)) - w / 2, int(round(p.y)) - w / 2, w, w, col)


## The runner: a courier of the colony in full flight: the body far forward, the head ahead of it, the arms trailing,
## the legs in a long stride; a bright jacket with the courier's stripe, a satchel on the back.
static func _runner(img: Image, dir: int, f: int, v: int) -> void:
	var jacket: Color = [Color(0.82, 0.68, 0.14), Color(0.7, 0.22, 0.2), Color(0.16, 0.5, 0.52), Color(0.5, 0.5, 0.54)][v % 4]
	var jacket2 := jacket.darkened(0.3)
	var skin: Color = SKINS[(v + 1) % 3]
	var bag := Color(0.36, 0.26, 0.16)
	var white := Color(0.95, 0.95, 0.9)
	var gore := Color(0.36, 0.08, 0.1)
	if dir != 2:
		var g := _figure(img, dir, f, {"skin": skin, "suit": jacket, "w": 8, "h": 10, "lean": 0.8, "arms": "back", "head": 3.2, "low": 2, "legs": 12, "stride": 4})
		var cx: int = g["cx"]
		var hip: int = g["hip"]
		if dir == 0:
			CA._r(img, cx - 4, hip - 6, 8, 1, white)                           # the courier's stripe
			_limb(img, Vector2(cx - 4, hip - 9), Vector2(cx + 3, hip - 2), 1, bag)      # the strap of the satchel
			CA._r(img, int(g["hx"]) - 1, int(g["hy"]) + 2, 3, 1, gore)
		else:
			CA._r(img, cx - 3, hip - 8, 6, 5, bag)                             # the satchel on the back
			CA._r(img, cx - 3, hip - 8, 6, 1, bag.lightened(0.2))
			CA._px(img, cx, hip - 5, white)
		return
	var boot := Color(0.12, 0.12, 0.14)
	var cloth := Color(0.2, 0.2, 0.25)
	var eye := Color(0.92, 1.0, 0.4)
	var hair := Color(0.16, 0.14, 0.13)
	var up := Vector2(0.0, 0.0 if f == 0 else -1.0)                # (in a stride the body is off the ground a little)
	var hipp := Vector2(14.0, 26.0) + up
	var sh := Vector2(8.0, 19.0) + up
	var ahead: Array = [Vector2(9.0, 30.0), Vector2(8.0, 34.0)]     # a leg: its knee, its foot
	var behind: Array = [Vector2(18.0, 31.0), Vector2(21.0, 34.0)]
	var near: Array = [Vector2(13.0, 31.0), Vector2(13.0, 36.0)]
	var far: Array = [Vector2(15.0, 31.0), Vector2(16.0, 36.0)]
	if f == 1:
		near = ahead
		far = behind
	elif f == 2:
		near = behind
		far = ahead
	for leg in [[far, cloth.darkened(0.25)], [near, cloth]]:
		var kn: Vector2 = leg[0][0]
		var ft: Vector2 = leg[0][1]
		_limb(img, hipp, kn, 3, leg[1])
		_limb(img, kn, ft, 2, leg[1])
		CA._r(img, int(ft.x) - 3, int(ft.y) + 1, 4, 2, boot)
	_limb(img, hipp + Vector2(0.0, -1.0), sh, 5, jacket)            # the body, far forward
	_limb(img, Vector2(9.0, 24.0) + up, Vector2(13.0, 20.0) + up, 1, white)              # the courier's stripe
	CA._r(img, 14, 18 + int(up.y), 5, 4, bag)                         # the satchel on the back
	CA._r(img, 14, 18 + int(up.y), 5, 1, bag.lightened(0.2))
	_limb(img, Vector2(14.0, 19.0) + up, Vector2(9.0, 17.0) + up, 1, bag)
	var sw := 0 if f == 0 else (1 if f == 1 else -1)
	_limb(img, Vector2(9.0, 21.0) + up, Vector2(16.0, 25.0 + sw) + up, 2, jacket2)       # the arm, trailing
	CA._r(img, 17, 25 + sw + int(up.y), 2, 2, skin)
	CA._ell(img, 5.0, 15.5 + up.y, 3.2, 3.4, skin)                    # the head, ahead of all of it
	CA._r(img, 3, 12 + int(up.y), 6, 2, hair)
	CA._px(img, 9, 12 + int(up.y), hair)                              # … the hair streaming
	CA._px(img, 10, 13 + int(up.y), hair)
	CA._px(img, 3, 15 + int(up.y), eye)
	CA._r(img, 2, 17 + int(up.y), 2, 1, gore)


## The spitter: thin, the neck swollen to a sack that glows.
static func _spitter(img: Image, dir: int, f: int, v: int) -> void:
	var g := _figure(img, dir, f, {"skin": SKINS[v % 3].lerp(Color(0.5, 0.75, 0.35), 0.4), "suit": [Color(0.35, 0.3, 0.42), Color(0.3, 0.38, 0.3), Color(0.42, 0.36, 0.3), Color(0.3, 0.32, 0.4)][v % 4],
		"w": 8, "h": 11, "lean": 0.25, "arms": "down", "head": 3.4, "low": -2, "legs": 10})
	var sack := Color(0.5, 0.92, 0.3)
	var hx: int = g["hx"]
	var hy: int = g["hy"]
	if dir == 2:
		CA._ell(img, hx + 1.5, hy + 5.0, 3.6, 3.0, sack)
		CA._px(img, hx, hy + 4, Color(0.85, 1.0, 0.6))
		CA._r(img, hx - 4, hy + 1, 2, 2, Color(0.1, 0.2, 0.05))            # the mouth, open
		CA._px(img, hx - 4, hy + 3, sack)
	elif dir == 0:
		CA._ell(img, hx + 0.5, hy + 5.0, 4.2, 3.0, sack)
		CA._px(img, hx - 1, hy + 4, Color(0.85, 1.0, 0.6))
		CA._r(img, hx - 1, hy + 2, 3, 2, Color(0.1, 0.2, 0.05))
		CA._px(img, hx, hy + 8, sack)
	else:
		CA._ell(img, hx + 0.5, hy + 5.0, 3.6, 2.4, sack.darkened(0.25))


## The bloater: swollen round in a protective suit that has burst at its seams; what is in it glows.
static func _bloater(img: Image, dir: int, f: int, v: int) -> void:
	var suit: Color = [Color(0.85, 0.5, 0.12), Color(0.8, 0.72, 0.2), Color(0.75, 0.4, 0.15), Color(0.7, 0.6, 0.25)][v % 4]
	var skin: Color = SKINS[v % 3].lerp(Color(0.45, 0.7, 0.3), 0.5)
	var cx := img.get_width() / 2
	var hh := img.get_height()
	var step := 0 if f == 0 else (1 if f == 1 else -1)
	for leg in [-1, 1]:
		var up: int = maxi(0, step * leg)
		CA._r(img, cx - 5 if leg == -1 else cx + 2, hh - 9, 3, 6 - up, suit.darkened(0.3))
		CA._r(img, cx - 6 if leg == -1 else cx + 2, hh - 3 - up, 4, 2, Color(0.12, 0.12, 0.14))
	var by := hh - 17.0 + absf(float(step)) * 0.5
	CA._ell(img, cx, by, 11.0 if dir != 2 else 9.5, 10.0, suit)
	CA._ell(img, cx - 3.0, by - 3.0, 5.0, 4.0, suit.lightened(0.15))
	var glow := Color(0.55, 1.0, 0.35)
	if dir != 1:                                               # the seams, burst: what is under them glows
		for q in 5:
			CA._px(img, cx + 1 + (q % 2), int(by) - 6 + q * 3, glow)
		CA._r(img, cx - 6, int(by) + 2, 4, 1, glow)
		CA._r(img, cx + 3, int(by) - 2, 3, 1, glow.darkened(0.2))
	for arm in [-1, 1]:                                        # small arms, held away from the body
		CA._r(img, cx + arm * 11 - (1 if arm == 1 else 0), int(by) - 3, 2, 5, suit.darkened(0.25))
		CA._r(img, cx + arm * 11 - (1 if arm == 1 else 0), int(by) + 2, 2, 2, skin)
	var hx := cx - (3 if dir == 2 else 0)
	CA._ell(img, hx + 0.5, by - 12.0, 3.2, 3.4, skin)
	if dir == 1:
		CA._r(img, hx - 2, int(by) - 15, 6, 4, suit.darkened(0.2))                      # the hood from behind
	else:
		CA._r(img, hx - 3, int(by) - 16, 7, 2, suit.darkened(0.2))                       # what is left of the hood
		CA._px(img, hx - 1, int(by) - 12, Color(0.92, 1.0, 0.4))
		if dir == 0:
			CA._px(img, hx + 2, int(by) - 12, Color(0.92, 1.0, 0.4))


## The shieldbearer: one of the colony's guards, a helmet, a shield before it (`v` 2 and 3: the shield is broken).
static func _shieldbearer(img: Image, dir: int, f: int, v: int) -> void:
	var navy := Color(0.16, 0.2, 0.34)
	var g := _figure(img, dir, f, {"skin": SKINS[v % 3], "suit": navy, "w": 10, "h": 12, "lean": 0.12, "arms": "down", "head": 3.6, "hair": null, "legs": 10})
	var cx: int = g["cx"]
	var hip: int = g["hip"]
	var hx: int = g["hx"]
	var hy: int = g["hy"]
	var helm := Color(0.22, 0.26, 0.4)
	CA._r(img, hx - 3, hy - 4, 7, 4, helm)                         # the helmet
	if dir == 1:
		CA._r(img, hx - 3, hy, 7, 2, helm)
	elif dir == 0:
		CA._r(img, hx - 3, hy - 1, 7, 1, Color(0.5, 0.75, 0.9, 0.7))       # what is left of its visor
		CA._r(img, cx - 4, hip - 8, 8, 1, Color(0.85, 0.85, 0.3))          # the stripe of the guard
	else:
		CA._r(img, hx - 4, hy - 1, 3, 1, Color(0.5, 0.75, 0.9, 0.7))
	if v >= 2 or dir == 1:
		return
	var steel := Color(0.66, 0.7, 0.76)
	if dir == 0:
		CA._r(img, cx - 7, hip - 13, 13, 16, steel)
		CA._r(img, cx - 7, hip - 13, 13, 1, steel.lightened(0.25))
		CA._r(img, cx - 7, hip + 2, 13, 1, steel.darkened(0.3))
		CA._r(img, cx - 4, hip - 10, 7, 2, Color(0.1, 0.12, 0.18))         # the slit to look through
		CA._r(img, cx - 6, hip - 5, 11, 2, Color(0.85, 0.85, 0.3))
		CA._r(img, cx - 5, hip - 1, 2, 1, steel.darkened(0.35))            # dents
		CA._r(img, cx + 2, hip - 3, 3, 1, steel.darkened(0.35))
	else:
		CA._r(img, cx - 9, hip - 14, 3, 17, steel)
		CA._r(img, cx - 9, hip - 14, 1, 17, steel.lightened(0.25))
		CA._r(img, cx - 8, hip - 6, 2, 2, Color(0.85, 0.85, 0.3))


## The howler: thin, pale, bald; the chest out, the arms thrown wide behind it, the head thrown back, the jaw wide
## open; the ribs show through what is left of the shirt.
static func _howler(img: Image, dir: int, f: int, v: int) -> void:
	var pale: Color = SKINS[v % 3].lerp(Color(0.75, 0.8, 0.72), 0.5)
	var shirt: Color = [Color(0.3, 0.28, 0.3), Color(0.34, 0.26, 0.26), Color(0.26, 0.3, 0.3), Color(0.3, 0.3, 0.24)][v % 4]
	var shirt2 := shirt.darkened(0.3)
	var g := _figure(img, dir, f, {"skin": pale, "suit": shirt, "w": 7, "h": 13, "lean": -0.12, "arms": "none", "head": 3.8, "low": -1, "legs": 11, "hair": null, "eye": pale})
	var hx: int = g["hx"]
	var hy: int = g["hy"]
	var cx: int = g["cx"]
	var hip: int = g["hip"]
	var top := hip - 13
	var dark := Color(0.08, 0.02, 0.04)
	var tooth := Color(0.92, 0.9, 0.85)
	var red := Color(1.0, 0.45, 0.35)
	var sw := 0 if f == 0 else (1 if f == 1 else -1)
	if dir == 2:
		_limb(img, Vector2(cx + 1, top + 3), Vector2(cx + 5, top + 8 - sw), 2, shirt2.darkened(0.2))       # the arm behind
		CA._r(img, cx + 5, top + 9 - sw, 2, 2, pale.darkened(0.2))
		_limb(img, Vector2(cx, top + 3), Vector2(cx + 7, top + 6 + sw), 2, shirt2)                       # … and the one before it
		CA._r(img, cx + 8, top + 6 + sw, 2, 2, pale)
		CA._px(img, cx + 10, top + 5 + sw, pale)                         # the fingers, spread
		CA._px(img, cx + 10, top + 7 + sw, pale)
		CA._r(img, hx - 3, hy - 3, 3, 4, dark)                          # the jaw, wide open, turned up
		CA._px(img, hx - 3, hy - 3, tooth)
		CA._px(img, hx - 1, hy + 1, tooth)
		CA._px(img, hx + 1, hy - 2, red)                                # the eye, far back
		for rb in 3:                                                    # the ribs
			CA._r(img, cx - 3, top + 4 + rb * 3, 3, 1, pale.darkened(0.15))
		CA._r(img, cx - 1, hip - 1, 1, 3, shirt2)                        # what hangs from the shirt
		CA._r(img, cx + 2, hip - 1, 1, 2, shirt2)
	else:
		for arm in [-1, 1]:                                             # the arms, thrown wide
			var sx: int = cx + arm * 4 - (1 if arm == -1 else 0)
			_limb(img, Vector2(sx, top + 3), Vector2(sx + arm * 5, top + 8 + sw * arm), 2, shirt2)
			CA._r(img, sx + arm * 5 - (1 if arm == -1 else 0), top + 9 + sw * arm, 2, 2, pale)
			CA._px(img, sx + arm * 6 - (1 if arm == -1 else 0), top + 11 + sw * arm, pale)
		if dir == 0:
			CA._r(img, hx - 1, hy, 4, 5, dark)                            # the jaw, wide open
			CA._px(img, hx - 1, hy, tooth)
			CA._px(img, hx + 2, hy, tooth)
			CA._px(img, hx, hy + 4, tooth)
			CA._px(img, hx + 1, hy + 4, tooth)
			CA._px(img, hx - 2, hy - 2, red)
			CA._px(img, hx + 3, hy - 2, red)
			for rb2 in 3:
				CA._r(img, cx - 2, top + 4 + rb2 * 3, 5, 1, pale.darkened(0.15))
			CA._r(img, cx - 3, hip - 1, 1, 3, shirt2)
			CA._r(img, cx + 2, hip - 1, 1, 2, shirt2)
		else:
			CA._r(img, cx - 2, top + 3, 1, 7, shirt2)                    # the spine through the shirt


## The hauler: a dock worker grown into the frame of a loader: thick legs of steel, great arms with claws, a small
## head between them.
static func _hauler(img: Image, dir: int, f: int, v: int, boss: bool) -> void:
	var ww := img.get_width()
	var hh := img.get_height()
	var cx := ww / 2
	var yel: Color = Color(0.86, 0.64, 0.1) if not boss else Color(0.9, 0.42, 0.1)
	var yel2 := yel.darkened(0.3)
	var blk := Color(0.1, 0.1, 0.12)
	var steel := Color(0.42, 0.45, 0.5)
	var skin: Color = SKINS[v % 3]
	var step := 0 if f == 0 else (1 if f == 1 else -1)
	var side := dir == 2
	var leg_h := 16 if not boss else 18
	var hip := hh - 3 - leg_h
	var half := 12 if not boss else 15
	if side:
		half = half * 2 / 3
	for leg in [-1, 1]:                                        # the legs of the frame
		var up: int = maxi(0, step * leg) * 2
		var lx: int = cx - half + 1 if leg == -1 else cx + half - 8
		if side:
			lx = cx - 3 + leg * step * 3
		CA._r(img, lx, hip, 7, leg_h - up, yel if leg == 1 else yel2)
		CA._r(img, lx + 2, hip + 4, 3, leg_h - 8 - up, blk)
		CA._r(img, lx - 1, hh - 4 - up, 9, 3, steel.darkened(0.3))
	var bh := 20 if not boss else 24
	var top := hip - bh
	CA._r(img, cx - half + 4, top + 3, half * 2 - 8, bh - 3, Color(0.2, 0.2, 0.25))      # the body in the frame
	CA._r(img, cx - half, top, 3, bh, yel)                               # the frame: its posts, its bars
	CA._r(img, cx + half - 3, top, 3, bh, yel2)
	CA._r(img, cx - half, top, half * 2, 3, yel)
	CA._r(img, cx - half, top + bh - 3, half * 2, 3, yel2)
	for q in range(cx - half, cx + half - 1, 4):                          # warning stripes on the bar
		CA._r(img, q, top, 2, 3, blk)
	if dir != 1:
		CA._r(img, cx - half + 4, top + 9, half * 2 - 8, 2, yel2)
		CA._px(img, cx - 2, top + 13, Color(0.36, 0.08, 0.1))
		CA._r(img, cx - 1, top + 14, 3, 1, Color(0.36, 0.08, 0.1))
	for arm in ([-1, 1] if not side else [-1]):                        # the arms: a pad at the shoulder, a beam, a claw
		var sw: int = step * arm
		var ax: int = cx + arm * (half + 4) - 3 if not side else cx - half - 7
		CA._r(img, ax - 1, top - 1, 8, 7, yel if arm == -1 else yel2)
		CA._r(img, ax, top + 6, 6, bh - 4 + sw, steel)
		CA._r(img, ax + 2, top + 8, 2, bh - 8 + sw, blk)
		CA._r(img, ax - 1, top + bh + 2 + sw, 8, 4, steel.darkened(0.35))
		CA._r(img, ax - 1, top + bh + 6 + sw, 2, 3, steel.darkened(0.2))
		CA._r(img, ax + 5, top + bh + 6 + sw, 2, 3, steel.darkened(0.2))
	var hx := cx - (4 if side else 0)
	var hy := top - 4
	CA._ell(img, hx + 0.5, hy, 4.0, 4.4, skin)
	if boss:                                                   # The Foreman: a hard hat, a cage over the head, a red lamp
		CA._r(img, hx - 5, hy - 6, 11, 4, Color(0.94, 0.94, 0.9))
		CA._r(img, hx - 6, hy - 3, 13, 1, Color(0.8, 0.8, 0.76))
		CA._r(img, cx - half - 1, top - 12, 2, 12, steel)
		CA._r(img, cx + half - 1, top - 12, 2, 12, steel)
		CA._r(img, cx - half - 1, top - 13, half * 2 + 2, 2, steel)
		CA._r(img, cx + half - 4, top - 17, 4, 4, Color(1.0, 0.25, 0.2))
		CA._px(img, cx + half - 3, top - 16, Color(1.0, 0.8, 0.7))
	if dir != 1:
		var eye := Color(1.0, 0.35, 0.25) if boss else Color(0.92, 1.0, 0.4)
		CA._px(img, hx - 1 - (1 if side else 0), hy, eye)
		if not side:
			CA._px(img, hx + 2, hy, eye)
		CA._r(img, hx - 1 - (2 if side else 0), hy + 2, 3, 1, Color(0.2, 0.05, 0.06))
	else:
		CA._r(img, hx - 3, hy - 4, 7, 5, Color(0.16, 0.14, 0.13))


## The screecher: an old survey drone the sickness has grown over, seen as it comes at you: a hull with a dark visor
## and two red eyes, flesh on it, fangs under it, what is left of its mast, strands hanging from it; wings of skin on
## fingers of bone (`f`: the beat of the wings: 0 level, 1 up, 2 down).
static func _screecher(img: Image, f: int, v: int) -> void:
	var cx := img.get_width() / 2
	var cy := 13
	var hull := Color(0.48, 0.5, 0.55)
	var flesh: Color = [Color(0.5, 0.14, 0.16), Color(0.44, 0.16, 0.22), Color(0.52, 0.2, 0.14), Color(0.4, 0.14, 0.2)][v % 4]
	var bone := flesh.lightened(0.3)
	var red := Color(1.0, 0.25, 0.2)
	var dark := Color(0.07, 0.07, 0.1)
	for wg in [-1, 1]:                                         # the wings: a finger of bone ahead, skin hanging from it
		for q in 13:
			var k := float(q) / 12.0
			var ly := -2.0 - q * 0.2 - sin(k * PI) * 1.5
			if f == 1:
				ly = -2.0 - q * 0.75
			elif f == 2:
				ly = -1.0 + q * 0.45 - sin(k * PI) * 3.0
			var x: int = cx + 5 + q if wg == 1 else cx - 6 - q
			var y: int = cy + int(round(ly))
			var th := maxi(1, int(round(7.0 - q * 0.42 - 1.6 * sin(float(q % 4) / 4.0 * PI))))
			CA._r(img, x, y + 1, 1, th, flesh.darkened(0.42) if (q % 4 == 0 and q > 0) else flesh.darkened(0.1))
			if q % 4 == 2:
				CA._px(img, x, y + 2, flesh.lightened(0.12))            # (a vein)
			CA._px(img, x, y, bone)
		var tipx: int = cx + 17 if wg == 1 else cx - 18
		var tipy: int = cy + int(round(-11.0 if f == 1 else (4.4 if f == 2 else -4.4)))
		CA._px(img, tipx + wg, tipy - 1, bone)                            # a claw at its tip
	CA._ell(img, cx, cy + 0.5, 5.0, 4.5, hull)                         # the hull
	CA._ell(img, cx - 1.0, cy - 2.0, 3.0, 1.4, hull.lightened(0.22))
	CA._r(img, cx - 4, cy, 8, 2, dark)                                 # its visor, two eyes in it
	CA._r(img, cx - 3, cy, 2, 1, red)
	CA._r(img, cx + 1, cy, 2, 1, red)
	CA._px(img, cx - 3, cy + 1, red.darkened(0.45))
	CA._px(img, cx + 2, cy + 1, red.darkened(0.45))
	CA._ell(img, cx + 2.5, cy - 3.0, 2.6, 1.8, flesh)                  # what grows on it
	CA._px(img, cx + 2, cy - 4, flesh.lightened(0.25))
	CA._r(img, cx - 5, cy + 2, 3, 2, flesh.darkened(0.15))
	CA._r(img, cx - 2, cy + 3, 4, 1, dark)                             # a mouth under the visor, fangs
	CA._px(img, cx - 2, cy + 3, bone)
	CA._px(img, cx + 1, cy + 3, bone)
	CA._r(img, cx - 3, cy - 7, 1, 4, hull.darkened(0.3))               # what is left of its mast
	CA._px(img, cx - 3, cy - 8, red if f == 0 else hull.darkened(0.3))
	var sway := 0 if f == 0 else (1 if f == 1 else -1)
	for st in [[-4, 3], [-1, 5], [3, 3]]:                              # strands hanging from it, swinging
		for q2 in int(st[1]):
			CA._px(img, cx + int(st[0]) + (sway if q2 >= int(st[1]) - 2 else 0), cy + 5 + q2, flesh.darkened(0.3) if q2 < int(st[1]) - 1 else bone)


## The Brood: a mound of flesh with sacks that swell and sink (`f`), a mouth at its top, many eyes.
static func _brood(img: Image, f: int) -> void:
	var ww := img.get_width()
	var hh := img.get_height()
	var cx := ww / 2
	var deep := Color(0.3, 0.1, 0.2)
	var mid := Color(0.44, 0.16, 0.26)
	var lite := Color(0.58, 0.26, 0.34)
	var swell := 0.0 if f == 0 else (1.0 if f == 1 else -1.0)
	CA._ell(img, cx, hh - 16.0, 35.0, 14.0, deep)                     # the mound
	CA._ell(img, cx, hh - 30.0, 26.0, 20.0, mid)
	CA._ell(img, cx - 6.0, hh - 38.0, 14.0, 10.0, lite)
	for q in 7:                                                # roots of flesh, feeling their way out
		var tx := cx - 34 + q * 11 + int(swell)
		CA._r(img, tx, hh - 6 - (q % 2) * 2, 3, 5 + (q % 2) * 2, deep)
	var sacks: Array = [[-22, -22, 7.0], [20, -24, 8.0], [-8, -14, 6.0], [10, -10, 6.5], [0, -34, 6.0], [-26, -8, 5.0], [27, -9, 5.5]]
	for sk in sacks:                                           # the sacks: thin skin, what is in them glows
		var r: float = float(sk[2]) + swell * 0.8
		CA._ell(img, cx + int(sk[0]), hh - 18.0 + float(sk[1]), r, r * 0.9, Color(0.72, 0.5, 0.42))
		CA._ell(img, cx + int(sk[0]) - 1.0, hh - 19.0 + float(sk[1]), r * 0.55, r * 0.5, Color(0.6, 1.0, 0.4))
	CA._ell(img, cx, hh - 52.0, 9.0, 5.0, Color(0.08, 0.02, 0.05))      # the mouth at its top
	for t in 6:
		CA._px(img, cx - 7 + t * 3, hh - 55, Color(0.92, 0.9, 0.82))
		CA._px(img, cx - 6 + t * 3, hh - 49, Color(0.92, 0.9, 0.82))
	for e in 9:                                                # its eyes
		var ex := cx - 20 + e * 5 + (e % 2) * 2
		var ey := hh - 40 + (e * 7) % 11
		CA._px(img, ex, ey, Color(0.95, 1.0, 0.4))
		CA._px(img, ex + 1, ey, Color(0.6, 0.7, 0.2))


## A crate (`great`: a boss's, with gold on it) and one of the colony lying on the ground (a sleeper, `v`: which).
static func crate(great: bool, open: bool) -> Texture2D:
	var key := "crate_%d_%d" % [int(great), int(open)]
	if not _cache.has(key):
		var ww := 20 if great else 16
		var hh := 17 if great else 14
		var img := Image.create(ww + 2, hh + 2, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		var body := Color(0.3, 0.36, 0.46) if not great else Color(0.42, 0.34, 0.16)
		var line := Color(0.35, 0.95, 1.0) if not great else Color(1.0, 0.85, 0.35)
		CA._r(img, 1, 5, ww, hh - 4, body)
		CA._r(img, 1, hh - 2, ww, 3, body.darkened(0.35))
		if not open:
			CA._r(img, 1, 2, ww, 4, body.lightened(0.22))                 # the lid
			CA._r(img, 1, 5, ww, 1, body.darkened(0.4))
		else:
			CA._r(img, 2, 5, ww - 2, 3, Color(0.05, 0.06, 0.1))            # open: dark inside, the lid gone
		CA._r(img, 1, 9, ww, 2, line)                                  # a stripe of light
		CA._r(img, ww / 2 - 1, 7, 4, 6, line.lightened(0.3))
		for cq in [1, ww - 1]:
			CA._r(img, cq, 5, 2, hh - 4, body.darkened(0.25))
		CA._outline(img)
		_cache[key] = ImageTexture.create_from_image(img)
	return _cache[key]


static func lying(v: int) -> Texture2D:
	var key := "lying_%d" % (v % 4)
	if not _cache.has(key):
		var img := Image.create(32, 14, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		var skin: Color = SKINS[v % 3].darkened(0.1)
		var suit: Color = SUITS[v % 4].darkened(0.15)
		CA._r(img, 8, 5, 12, 6, suit)                                  # the body, on its side
		CA._r(img, 8, 5, 12, 1, suit.lightened(0.15))
		CA._r(img, 20, 6, 9, 2, suit.darkened(0.25))                   # the legs
		CA._r(img, 20, 9, 8, 2, suit.darkened(0.35))
		CA._r(img, 28, 6, 2, 2, Color(0.12, 0.12, 0.14))
		CA._r(img, 27, 9, 2, 2, Color(0.12, 0.12, 0.14))
		CA._ell(img, 5.0, 8.0, 3.4, 3.4, skin)                          # the head
		CA._r(img, 2, 5, 6, 2, Color(0.16, 0.14, 0.13))
		CA._r(img, 10, 11, 7, 2, suit.darkened(0.3))                   # an arm under it
		CA._r(img, 17, 11, 2, 2, skin)
		CA._outline(img)
		_cache[key] = ImageTexture.create_from_image(img)
	return _cache[key]


# ---------------------------------------------------------------- part 7c-3: what you set down

## A mine on the ground: a flat disc of steel, a light at its middle (`lit`: the light is on).
static func mine(lit: bool) -> Texture2D:
	var key := "mine_%d" % int(lit)
	if not _cache.has(key):
		var img := Image.create(13, 9, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		var steel := Color(0.34, 0.37, 0.44)
		CA._ell(img, 6.5, 5.5, 5.4, 2.8, steel.darkened(0.35))               # its rim
		CA._ell(img, 6.5, 4.3, 5.4, 2.8, steel)                             # its top
		CA._ell(img, 6.5, 4.0, 3.4, 1.6, steel.lightened(0.18))
		CA._r(img, 6, 3, 2, 2, Color(1.0, 0.25, 0.2) if lit else Color(0.4, 0.1, 0.1))
		if lit:
			CA._px(img, 6, 3, Color(1.0, 0.8, 0.7))
		for sp in [2, 10]:                                               # two prongs
			CA._px(img, sp, 4, steel.darkened(0.5))
		CA._outline(img)
		_cache[key] = ImageTexture.create_from_image(img)
	return _cache[key]


## A sentry's gun: three legs, a housing with a light, a barrel the way it aims (`dir`: 0 towards you, 1 away,
## 2 left, 3 right; `fire`: it has just fired).
static func sentry(dir: int, fire: bool) -> Texture2D:
	var key := "sentry_%d_%d" % [dir, int(fire)]
	if not _cache.has(key):
		var img := Image.create(18, 20, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		var steel := Color(0.3, 0.33, 0.4)
		var hull := Color(0.4, 0.48, 0.58)
		var cyan := Color(0.4, 0.95, 1.0)
		var hot := Color(1.0, 1.0, 0.85)
		_limb(img, Vector2(9, 12), Vector2(4, 17), 1, steel)                 # its legs
		_limb(img, Vector2(9, 12), Vector2(14, 17), 1, steel)
		_limb(img, Vector2(9, 12), Vector2(9, 18), 1, steel.darkened(0.2))
		CA._r(img, 3, 17, 2, 1, steel.darkened(0.3))
		CA._r(img, 14, 17, 2, 1, steel.darkened(0.3))
		CA._r(img, 8, 18, 2, 1, steel.darkened(0.3))
		CA._r(img, 8, 10, 2, 3, steel)                                      # its neck
		CA._r(img, 5, 5, 8, 6, hull)                                        # the housing
		CA._r(img, 5, 5, 8, 1, hull.lightened(0.25))
		CA._r(img, 5, 10, 8, 1, hull.darkened(0.3))
		var d := 2 if dir == 3 else dir
		match d:
			0:                                                           # the barrel towards you
				CA._r(img, 8, 7, 3, 3, Color(0.06, 0.07, 0.1))
				CA._px(img, 9, 8, hot if fire else steel)
				CA._px(img, 6, 6, cyan)
			1:                                                           # … away from you
				CA._r(img, 8, 1, 2, 5, steel)
				CA._px(img, 8, 0, hot if fire else steel.darkened(0.3))
				CA._px(img, 9, 0, hot if fire else steel.darkened(0.3))
				CA._r(img, 6, 7, 6, 2, hull.darkened(0.2))
			_:                                                           # … to the side
				CA._r(img, 1, 7, 5, 2, steel)
				CA._r(img, 0, 7, 1, 2, hot if fire else steel.darkened(0.35))
				CA._px(img, 11, 6, cyan)
				CA._r(img, 12, 6, 1, 4, hull.darkened(0.25))
		if dir == 3:
			img.flip_x()
		CA._rim(img)
		CA._outline(img)
		_cache[key] = ImageTexture.create_from_image(img)
	return _cache[key]


# ---------------------------------------------------------------- part 8: AI Takeover: the machines

## The colours of the machines' units (their plates), by look.
const UNIT := [Color(0.78, 0.22, 0.18), Color(0.26, 0.42, 0.74), Color(0.52, 0.58, 0.26), Color(0.74, 0.48, 0.16)]


## The Enforcer: the corporations' security robot as the machines run it now: matt and dark, its plates in the
## colour of its unit (`v`), every light on it red. The Gunner (`gunner`): the same frame, red plates, a long gun.
static func _enforcer(img: Image, dir: int, f: int, v: int, gunner: bool) -> void:
	CA._sec_robot(img, dir, f)
	var trim: Color = Color(0.66, 0.12, 0.1) if gunner else UNIT[v % 4]
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a < 0.5:
				continue
			if c.g > 0.8 and c.r < 0.5:                                # its green light: red now
				img.set_pixel(x, y, Color(1.0, 0.2, 0.15))
			elif c.r > 0.9 and c.g < 0.4:                              # (the red eye stays)
				pass
			elif c.r - c.b > 0.2 and c.r > 0.5:                        # the sand-coloured plates: the unit's colour
				img.set_pixel(x, y, trim.lightened(0.12) if c.r > 0.75 else trim)
			else:
				img.set_pixel(x, y, Color(c.r * 0.62, c.g * 0.64, c.b * 0.72, c.a))      # matt and dark
	if not gunner:
		return
	var cx := img.get_width() / 2
	var hip := img.get_height() - 22
	var blk := Color(0.06, 0.06, 0.08)
	var hot := Color(1.0, 0.3, 0.2)
	if dir == 2:                                                       # the long gun: forward along the body
		CA._r(img, cx - 12, hip - 11, 13, 3, blk)
		CA._r(img, cx - 6, hip - 12, 6, 5, Color(0.16, 0.16, 0.2))
		CA._px(img, cx - 12, hip - 10, hot)
		CA._r(img, cx - 3, hip - 19, 6, 2, trim.lightened(0.15))
	elif dir == 0:                                                     # … held low before it, a heavy plate on the shoulder
		CA._r(img, cx - 12, hip - 15, 4, 13, blk)
		CA._r(img, cx - 13, hip - 21, 6, 5, trim)
		CA._r(img, cx - 13, hip - 21, 6, 1, trim.lightened(0.2))
		CA._r(img, cx - 12, hip - 2, 4, 2, hot)
		CA._r(img, cx - 5, hip - 13, 10, 2, trim)
	else:
		CA._r(img, cx + 8, hip - 15, 3, 13, blk)
		CA._r(img, cx + 7, hip - 21, 5, 4, trim)


## The Scout: a machine on four legs, low and long: a narrow head with one red eye, a body of dark steel with a
## stripe of its unit's colour, an aerial at its back. It gallops (`f` 1: stretched out, 2: gathered).
static func _scout(img: Image, dir: int, f: int, v: int) -> void:
	var steel := Color(0.3, 0.32, 0.38)
	var dark := Color(0.16, 0.17, 0.21)
	var trim: Color = UNIT[v % 4]
	var red := Color(1.0, 0.2, 0.15)
	if dir == 2:
		var front: Array = [Vector2(11, 20), Vector2(6, 18), Vector2(14, 19)]      # where its feet stand: standing, stretched, gathered
		var rear: Array = [Vector2(21, 20), Vector2(26, 18), Vector2(17, 19)]
		for far in [1, 0]:                                             # the far pair first, darker
			var lc: Color = dark if far == 1 else steel.darkened(0.15)
			var ox := 2.0 if far == 1 else 0.0
			_limb(img, Vector2(11.0 + ox, 12.0), (front[f] as Vector2) + Vector2(ox, 0.0 if far == 0 else -1.0), 2 - far, lc)
			_limb(img, Vector2(21.0 + ox, 12.0), (rear[f] as Vector2) + Vector2(ox, 0.0 if far == 0 else -1.0), 2 - far, lc)
		var lift := -1.0 if f == 1 else 0.0
		CA._ell(img, 16.0, 10.0 + lift, 8.5, 3.6, steel)                   # the body
		CA._r(img, 10, 7 + int(lift), 12, 1, steel.lightened(0.2))
		CA._r(img, 11, 10 + int(lift), 9, 1, trim)
		CA._r(img, 20, 8 + int(lift), 4, 4, steel.darkened(0.12))          # its haunch
		CA._r(img, 8, 9 + int(lift), 3, 3, dark)                            # the neck
		CA._r(img, 2, 7 + int(lift), 7, 5, steel.darkened(0.08))           # the head: narrow, thrust forward
		CA._r(img, 2, 7 + int(lift), 7, 1, steel.lightened(0.2))
		CA._r(img, 2, 9 + int(lift), 2, 1, red)
		CA._px(img, 2, 11 + int(lift), dark)
		_limb(img, Vector2(24.0, 8.0 + lift), Vector2(28.0, 3.0 + lift), 1, dark)   # its aerial
		CA._px(img, 28, 2 + int(lift), red if f == 0 else dark)
		return
	var cx := img.get_width() / 2
	var up := 1 if f == 1 else 0
	var up2 := 1 if f == 2 else 0
	_limb(img, Vector2(cx - 4, 13), Vector2(cx - 5, 20 - up), 2, steel.darkened(0.15))
	_limb(img, Vector2(cx + 3, 13), Vector2(cx + 4, 20 - up2), 2, steel.darkened(0.25))
	_limb(img, Vector2(cx - 2, 11), Vector2(cx - 3, 18 - up2), 1, dark)
	_limb(img, Vector2(cx + 1, 11), Vector2(cx + 2, 18 - up), 1, dark)
	CA._ell(img, cx, 9.0, 5.5, 4.2, steel)
	CA._r(img, cx - 4, 5, 8, 1, steel.lightened(0.2))
	CA._r(img, cx - 5, 9, 10, 1, trim)
	if dir == 0:
		CA._r(img, cx - 3, 9, 6, 6, steel.darkened(0.08))                   # the head, low before the body
		CA._r(img, cx - 3, 9, 6, 1, steel.lightened(0.2))
		CA._r(img, cx - 2, 11, 4, 1, red)
		CA._px(img, cx - 1, 13, dark)
		CA._px(img, cx, 13, dark)
	else:
		CA._r(img, cx - 1, 1, 1, 5, dark)                                   # its aerial, a light at its back
		CA._px(img, cx - 1, 0, red if f == 0 else dark)
		CA._r(img, cx - 2, 8, 4, 2, dark)


# ---------------------------------------------------------------- part 8b: the rest of the machines

## The Bulwark: the Precursors' robot as the machines run it now: its plates dull red, a tall shield before it, heavy
## plates on its shoulders, the tube of a mortar over its back.
static func _bulwark(img: Image, dir: int, f: int, v: int) -> void:
	CA._pre_robot(img, dir, f, true)
	var plate: Color = UNIT[v % 4].darkened(0.25)
	var steel := Color(0.36, 0.38, 0.44)
	var dark := Color(0.08, 0.08, 0.1)
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a < 0.5:
				continue
			if c.r > 0.7 and c.g > 0.5 and c.b < 0.5:                  # its gold: steel now
				img.set_pixel(x, y, steel)
			elif c.r > 0.6 and c.g < 0.4:                              # its plates: dull red
				img.set_pixel(x, y, Color(c.r * 0.72, c.g * 0.6, c.b * 0.6, c.a))
	var cx := img.get_width() / 2
	var hip := img.get_height() - 22
	if dir == 2:
		_limb(img, Vector2(cx + 3, hip - 18), Vector2(cx + 9, hip - 35), 3, dark)        # the mortar's tube over its back
		CA._r(img, cx + 8, hip - 38, 4, 3, steel)
		CA._r(img, cx - 9, hip - 17, 3, 22, steel)                         # the shield before it
		CA._r(img, cx - 9, hip - 17, 1, 22, steel.lightened(0.25))
		CA._r(img, cx - 8, hip - 8, 2, 3, plate.lightened(0.3))
		CA._r(img, cx - 3, hip - 22, 7, 4, plate)                          # the plate on its shoulder
	elif dir == 0:
		CA._r(img, cx + 7, hip - 37, 4, 14, dark)                          # the tube behind its shoulder
		CA._r(img, cx + 7, hip - 38, 4, 2, steel)
		CA._r(img, cx - 13, hip - 23, 7, 7, plate)                         # heavy plates on the shoulders
		CA._r(img, cx + 6, hip - 23, 7, 7, plate)
		CA._r(img, cx - 13, hip - 23, 7, 1, plate.lightened(0.25))
		CA._r(img, cx + 6, hip - 23, 7, 1, plate.lightened(0.25))
		CA._r(img, cx - 16, hip - 15, 8, 21, steel)                        # the shield on its arm
		CA._r(img, cx - 16, hip - 15, 8, 1, steel.lightened(0.3))
		CA._r(img, cx - 16, hip + 5, 8, 1, steel.darkened(0.35))
		CA._r(img, cx - 14, hip - 10, 4, 2, dark)
		CA._r(img, cx - 15, hip - 4, 6, 2, plate.lightened(0.3))
	else:
		CA._r(img, cx - 2, hip - 38, 4, 18, dark)                          # the tube down its back
		CA._r(img, cx - 2, hip - 39, 4, 2, steel)
		CA._r(img, cx - 13, hip - 23, 7, 7, plate)
		CA._r(img, cx + 6, hip - 23, 7, 7, plate)


## The Seeker: a mine that rolls: a ball of dark steel, a band of red light round it, studs (`f`: how far it has rolled).
static func _seeker(img: Image, f: int, v: int) -> void:
	var steel := Color(0.26, 0.27, 0.33)
	var red := Color(1.0, 0.22, 0.16)
	CA._ell(img, 8.0, 9.0, 6.0, 6.0, steel)
	CA._ell(img, 6.5, 7.0, 3.0, 2.6, steel.lightened(0.22))
	CA._r(img, 2, 8 + (f % 2), 12, 2, red.darkened(0.25))                  # the band of light
	CA._r(img, 4 + f * 3, 8 + (f % 2), 3, 2, red.lightened(0.3))           # … a bright stretch running round it
	for st in 4:                                                       # studs, turning with it
		var a := st * PI * 0.5 + f * 0.5 + 0.4
		CA._px(img, 8 + int(round(cos(a) * 6.5)), 9 + int(round(sin(a) * 6.5)), UNIT[v % 4])
	CA._px(img, 8, 3, steel.darkened(0.4))


## The Jammer: a mast on three legs, a ring of emitters at its top, a core of blue light that beats (`f`).
static func _jammer(img: Image, dir: int, f: int, v: int) -> void:
	var steel := Color(0.34, 0.36, 0.42)
	var dark := Color(0.14, 0.15, 0.19)
	var blue := Color(0.35, 0.7, 1.0)
	var cx := img.get_width() / 2
	var step := 0 if f == 0 else (1 if f == 1 else -1)
	_limb(img, Vector2(cx, 30), Vector2(cx - 7, 43 - maxi(0, step)), 2, dark)       # its legs
	_limb(img, Vector2(cx, 30), Vector2(cx + 6, 43 - maxi(0, -step)), 2, steel.darkened(0.2))
	_limb(img, Vector2(cx, 30), Vector2(cx, 44), 1, dark)
	CA._r(img, cx - 8, 43 - maxi(0, step), 3, 2, dark)
	CA._r(img, cx + 5, 43 - maxi(0, -step), 3, 2, dark)
	CA._r(img, cx - 2, 27, 4, 5, steel)                                    # the box they carry
	CA._r(img, cx - 2, 27, 4, 1, steel.lightened(0.25))
	CA._px(img, cx - 1 if dir != 1 else cx, 29, Color(1.0, 0.25, 0.2))
	CA._r(img, cx - 1, 9, 2, 18, steel.darkened(0.1))                       # the mast
	CA._r(img, cx - 2, 18, 4, 1, UNIT[v % 4])
	CA._ell(img, cx, 7.0, 7.0, 3.0, dark)                                   # the ring of emitters
	CA._ell(img, cx, 6.0, 7.0, 3.0, steel)
	CA._ell(img, cx, 6.0, 4.0, 1.6, dark)
	CA._r(img, cx - 1, 3, 2, 4, blue if f != 2 else blue.lightened(0.5))    # the core
	CA._px(img, cx - 7, 6, blue if f == 1 else blue.darkened(0.4))
	CA._px(img, cx + 6, 6, blue if f == 2 else blue.darkened(0.4))
	CA._px(img, cx - 1, 1, blue.lightened(0.6) if f == 0 else blue)


## The Hunter: a flying wing as it comes at you: a pod with one red eye slit, swept wings, two engines that flicker
## (`f`), a gun under it.
static func _hunter(img: Image, f: int, v: int) -> void:
	var cx := img.get_width() / 2
	var cy := 10
	var steel := Color(0.3, 0.32, 0.4)
	var dark := Color(0.12, 0.13, 0.17)
	var red := Color(1.0, 0.22, 0.16)
	for wg in [-1, 1]:                                                 # the wings: swept back, thinning to their tips
		for q in 16:
			var x: int = cx + 5 + q if wg == 1 else cx - 6 - q
			var y: int = cy - 1 + q / 4
			CA._r(img, x, y, 1, maxi(1, 5 - q / 4), steel if q % 5 != 0 else steel.darkened(0.3))
			CA._px(img, x, y, steel.lightened(0.25))
		CA._r(img, cx + (5 if wg == 1 else -8), cy + 3, 3, 3, dark)             # an engine at each wing's root
		CA._px(img, cx + (6 if wg == 1 else -7), cy + 5, Color(0.8, 0.5, 1.0) if f != 0 else Color(1.0, 0.85, 1.0))
		CA._px(img, cx + (20 if wg == 1 else -21), cy + 3, UNIT[v % 4])         # a light at each tip
	CA._ell(img, cx, cy + 0.5, 6.0, 4.6, steel.darkened(0.1))                # the pod
	CA._ell(img, cx - 1.0, cy - 1.5, 3.6, 1.6, steel.lightened(0.2))
	CA._r(img, cx - 4, cy, 8, 2, dark)                                      # its eye slit
	CA._r(img, cx - 2, cy, 4, 1, red)
	CA._px(img, cx - 1 + f % 2, cy, red.lightened(0.5))
	CA._r(img, cx - 1, cy + 5, 2, 4, dark)                                  # the gun under it
	CA._px(img, cx - 1, cy + 9, red if f == 1 else dark)
	CA._r(img, cx - 1, cy - 7, 1, 3, dark)                                  # a fin


# ---------------------------------------------------------------- part 8c: the bosses of AI Takeover

## The Warden: a walker on four legs: a broad armoured hull, a turret with one red eye slit, a rocket pod on each
## shoulder, the lens of its laser on a mast (`f`: which pair of legs is lifted).
static func _warden(img: Image, dir: int, f: int) -> void:
	var steel := Color(0.25, 0.27, 0.33)
	var dark := Color(0.1, 0.11, 0.14)
	var plate := Color(0.5, 0.15, 0.14)
	var red := Color(1.0, 0.25, 0.18)
	var cx := img.get_width() / 2
	var gy := img.get_height() - 2                                # where its feet stand
	var la := 3 if f == 1 else 0                                  # the legs of one diagonal lifted, then those of the other
	var lb := 3 if f == 2 else 0
	if dir == 2:                                               # from its side (it looks to the left)
		_limb(img, Vector2(cx - 12, 30), Vector2(cx - 22, 40), 3, dark)             # the legs of its far side
		_limb(img, Vector2(cx - 22, 40), Vector2(cx - 20, gy - lb), 3, dark)
		_limb(img, Vector2(cx + 14, 30), Vector2(cx + 24, 40), 3, dark)
		_limb(img, Vector2(cx + 24, 40), Vector2(cx + 22, gy - la), 3, dark)
		CA._ell(img, cx, 26.0, 27.0, 11.0, steel)                        # the hull
		CA._ell(img, cx - 2.0, 22.0, 22.0, 6.0, steel.lightened(0.15))
		CA._r(img, cx - 20, 27, 40, 3, plate)
		CA._ell(img, cx - 22.0, 22.0, 9.0, 8.0, steel.darkened(0.1))      # its head, forward
		CA._r(img, cx - 31, 21, 8, 2, dark)                               # the eye slit
		CA._r(img, cx - 31, 21, 4, 2, red)
		CA._r(img, cx + 4, 8, 16, 9, dark)                                # a rocket pod on its back
		CA._r(img, cx + 4, 8, 16, 2, steel.lightened(0.2))
		for q in 3:
			CA._px(img, cx + 4, 11 + q * 2, red.darkened(0.2))
		CA._r(img, cx - 4, 6, 3, 12, dark)                                # the mast of its laser
		CA._ell(img, cx - 3.0, 5.0, 3.5, 3.5, steel)
		CA._px(img, cx - 3, 5, red)
		CA._px(img, cx - 4, 5, red.lightened(0.5))
		_limb(img, Vector2(cx - 16, 32), Vector2(cx - 28, 44), 4, steel.darkened(0.15))      # the legs of its near side
		_limb(img, Vector2(cx - 28, 44), Vector2(cx - 27, gy - la), 4, steel)
		CA._r(img, cx - 31, gy - la - 1, 9, 3, dark)
		_limb(img, Vector2(cx + 10, 32), Vector2(cx + 20, 44), 4, steel.darkened(0.15))
		_limb(img, Vector2(cx + 20, 44), Vector2(cx + 18, gy - lb), 4, steel)
		CA._r(img, cx + 14, gy - lb - 1, 9, 3, dark)
		CA._r(img, cx - 30, 42, 5, 5, plate)                              # plates on its knees
		CA._r(img, cx + 18, 42, 5, 5, plate)
		return
	var front := dir == 0
	_limb(img, Vector2(cx - 10, 30), Vector2(cx - 17, 40), 3, dark)                 # its hind legs, behind the hull
	_limb(img, Vector2(cx - 17, 40), Vector2(cx - 16, gy - 4 - lb), 3, dark)
	_limb(img, Vector2(cx + 10, 30), Vector2(cx + 17, 40), 3, dark)
	_limb(img, Vector2(cx + 17, 40), Vector2(cx + 16, gy - 4 - la), 3, dark)
	CA._ell(img, cx, 26.0, 23.0, 12.0, steel)                            # the hull
	CA._ell(img, cx, 21.0, 18.0, 6.0, steel.lightened(0.15))
	CA._r(img, cx - 18, 28, 36, 3, plate)
	for wq in 2:                                               # a rocket pod on each shoulder
		var px0: int = cx + (16 if wq == 1 else -27)
		CA._r(img, px0, 9, 11, 10, dark)
		CA._r(img, px0, 9, 11, 2, steel.lightened(0.2))
		if front:
			for q2 in 6:
				CA._px(img, px0 + 2 + (q2 % 3) * 3, 13 + (q2 / 3) * 3, red.darkened(0.15))
		else:
			CA._r(img, px0 + 2, 13, 7, 4, steel.darkened(0.3))
	CA._ell(img, cx, 17.0, 10.0, 8.0, steel.darkened(0.08))               # the turret
	if front:
		CA._r(img, cx - 7, 16, 14, 3, dark)                               # its eye slit
		CA._r(img, cx - 4, 16, 8, 2, red)
		CA._px(img, cx - 1 + (f % 2), 16, red.lightened(0.6))
	else:
		for q3 in 3:
			CA._r(img, cx - 6, 14 + q3 * 3, 12, 1, dark)                    # vents at its back
	CA._r(img, cx - 1, 2, 3, 9, dark)                                     # the mast of its laser
	CA._ell(img, cx, 3.0, 3.5, 3.0, steel)
	CA._px(img, cx, 3, red)
	CA._px(img, cx - 1, 3, red.lightened(0.5))
	_limb(img, Vector2(cx - 18, 30), Vector2(cx - 30, 38), 4, steel.darkened(0.15))      # its fore legs, wide
	_limb(img, Vector2(cx - 30, 38), Vector2(cx - 31, gy - la), 4, steel)
	CA._r(img, cx - 35, gy - la - 1, 9, 3, dark)
	_limb(img, Vector2(cx + 18, 30), Vector2(cx + 30, 38), 4, steel.darkened(0.15))
	_limb(img, Vector2(cx + 30, 38), Vector2(cx + 31, gy - lb), 4, steel)
	CA._r(img, cx + 27, gy - lb - 1, 9, 3, dark)
	CA._r(img, cx - 33, 36, 5, 5, plate)                                  # plates on its knees
	CA._r(img, cx + 28, 36, 5, 5, plate)


## The Core: the mind of the machines: a sphere of dark steel held in two claws over a pedestal, an eye of red light
## in it that beats (`f`), cables down into the ground.
static func _core(img: Image, f: int) -> void:
	var steel := Color(0.24, 0.26, 0.32)
	var dark := Color(0.09, 0.1, 0.13)
	var red := Color(1.0, 0.22, 0.16)
	var cx := img.get_width() / 2
	var hh := img.get_height()
	CA._ell(img, cx, hh - 7.0, 23.0, 6.0, dark)                           # the pedestal
	CA._ell(img, cx, hh - 9.0, 19.0, 4.5, steel)
	CA._ell(img, cx, hh - 10.0, 12.0, 2.5, steel.lightened(0.18))
	for q in 5:                                                # cables from it into the ground
		CA._r(img, cx - 21 + q * 10, hh - 5 - (q % 2), 2, 4, dark)
	CA._r(img, cx - 3, hh - 30, 6, 20, dark)                              # the column
	CA._r(img, cx - 2, hh - 30, 1, 20, steel.lightened(0.1))
	for q2 in 3:
		CA._r(img, cx - 5, hh - 14 - q2 * 5, 10, 1, steel)
	var cy := 22
	for wq in 2:                                               # the claws that hold it
		var wg := -1 if wq == 0 else 1
		_limb(img, Vector2(cx + wg * 4, hh - 30), Vector2(cx + wg * 20, cy + 8), 3, steel.darkened(0.15))
		_limb(img, Vector2(cx + wg * 20, cy + 8), Vector2(cx + wg * 17, cy - 12), 3, steel)
		CA._r(img, cx + wg * 17 - 1, cy - 14, 3, 3, red.darkened(0.3))
	CA._ell(img, cx, cy, 15.0, 15.0, dark)                                # the sphere
	CA._ell(img, cx - 3.0, cy - 4.0, 10.0, 8.0, steel)
	CA._ell(img, cx, cy, 11.0, 11.0, steel.darkened(0.25))
	var beat := 7.0 if f == 0 else (8.5 if f == 1 else 6.0)
	CA._ell(img, cx, cy, beat, beat, red.darkened(0.35))                   # its eye
	CA._ell(img, cx, cy, beat * 0.62, beat * 0.62, red)
	CA._ell(img, cx - 1.0, cy - 1.0, beat * 0.28, beat * 0.28, Color(1.0, 0.9, 0.82))
	for q3 in 8:                                               # seams round the sphere, lit in turn
		var a := q3 * TAU / 8.0 + 0.2
		CA._px(img, cx + int(round(cos(a) * 13.0)), cy + int(round(sin(a) * 13.0)), red if (q3 + f) % 2 == 0 else red.darkened(0.5))
	CA._r(img, cx - 1, 2, 2, 6, dark)                                     # an aerial
	CA._px(img, cx, 1, red if f != 2 else red.lightened(0.5))


## A pylon of The Core: a slim tower on a foot, rings round its shaft, a crystal at its top that feeds the shield
## (`f`: how brightly it beats).
static func _pylon(img: Image, f: int) -> void:
	var steel := Color(0.27, 0.29, 0.36)
	var dark := Color(0.1, 0.11, 0.14)
	var blue := Color(0.45, 0.78, 1.0)
	var cx := img.get_width() / 2
	var hh := img.get_height()
	CA._ell(img, cx, hh - 4.0, 8.5, 3.5, dark)                            # its foot
	CA._ell(img, cx, hh - 5.0, 6.0, 2.2, steel)
	CA._r(img, cx - 2, 16, 4, hh - 21, steel.darkened(0.1))                # the shaft
	CA._r(img, cx - 2, 16, 1, hh - 21, steel.lightened(0.2))
	for q in 4:                                                # rings round it, a small light on each
		CA._r(img, cx - 3, 22 + q * 9, 6, 2, dark)
		CA._px(img, cx + (q % 2) * 2 - 1, 23 + q * 9, Color(1.0, 0.25, 0.2) if (q + f) % 3 == 0 else Color(0.5, 0.12, 0.1))
	CA._r(img, cx - 4, 13, 8, 3, dark)                                    # the socket of its crystal
	var lit := blue if f == 0 else (blue.lightened(0.45) if f == 1 else blue.darkened(0.2))
	for q2 in 6:                                               # the crystal: a diamond
		var half := q2 if q2 < 3 else 5 - q2
		CA._r(img, cx - 1 - half, 2 + q2 * 2, 2 + half * 2, 2, lit if q2 != 2 else lit.lightened(0.3))
	CA._px(img, cx - 1, 6, Color(1, 1, 1))


## The drone that flies with you (part 7d, Luz, 23 Nov 2026): a small hull between two rotors, a lens in front (`f`:
## how its rotors stand; `swarm`: one of the Carrier Swarm, with a band of gold instead of cyan).
static func drone(f: int, swarm: bool) -> Texture2D:
	var key := "drone_%d_%d" % [f % 2, int(swarm)]
	if not _cache.has(key):
		var img := Image.create(24, 14, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		var steel := Color(0.42, 0.45, 0.53)
		var dark := Color(0.16, 0.17, 0.22)
		CA._r(img, 3, 6, 18, 2, dark)                                       # the arms to its rotors
		CA._ell(img, 12.0, 8.0, 5.0, 4.0, steel)                            # the hull
		CA._ell(img, 11.0, 6.5, 3.0, 1.6, steel.lightened(0.25))
		CA._r(img, 9, 9, 6, 1, Color(1.0, 0.8, 0.35) if swarm else Color(0.3, 0.9, 1.0))
		CA._px(img, 12, 11, Color(1.0, 0.3, 0.25))                           # its lens
		for wq in 2:
			var rx := 4 if wq == 0 else 19
			CA._r(img, rx, 4, 1, 3, dark)                                     # a rotor's shaft
			if f % 2 == 0:
				CA._r(img, rx - 3, 3, 7, 1, Color(0.78, 0.83, 0.92, 0.9))        # its blades, a blur
			else:
				CA._r(img, rx - 2, 3, 5, 1, Color(0.78, 0.83, 0.92, 0.6))
				CA._px(img, rx - 3, 2, Color(0.78, 0.83, 0.92, 0.5))
				CA._px(img, rx + 3, 2, Color(0.78, 0.83, 0.92, 0.5))
		CA._outline(img)
		_cache[key] = ImageTexture.create_from_image(img)
	return _cache[key]


# ---------------------------------------------------------------- part 9a: what lives on Whiteout's ice

const FROST := Color(0.86, 0.95, 1.0)
const FROST_D := Color(0.48, 0.7, 0.95)
const CHITIN := [Color(0.15, 0.17, 0.28), Color(0.19, 0.16, 0.27), Color(0.13, 0.2, 0.27), Color(0.2, 0.19, 0.24)]


static func _hash1(i: int) -> float:
	return fposmod(sin(float(i) * 12.9898) * 43758.5453, 1.0)


## Spikes of ice standing on something from `x0` to `x1`, their feet at `by`, up to `tall` high (lit from the left).
static func _ice(img: Image, x0: int, x1: int, by: int, tall: int, seed_n: int) -> void:
	var mid := (x0 + x1) * 0.5
	var half := maxf(1.0, (x1 - x0) * 0.5)
	var x := x0
	var sp := 0
	while x < x1:
		var wd := 2 + int(_hash1(sp * 7 + seed_n * 13) * 3.0)
		var hgt := int(round(tall * (0.45 + 0.55 * _hash1(sp * 3 + seed_n * 5 + 1)) * (1.0 - 0.45 * absf((x + wd * 0.5 - mid) / half))))
		for q in wd:
			var up := maxi(1, hgt - absi(q - wd / 2) * 2)
			for y in up:
				CA._px(img, x + q, by - y, FROST if (q == 0 or y == up - 1) else (FROST_D if q == wd - 1 else FROST.lerp(FROST_D, 0.45)))
		x += wd
		sp += 1


## The Frost Mite: a small thing on six legs, its shell nearly black against the snow, a ridge of frost down its
## back, pale eyes (`f`: which legs are set down).
static func _mite(img: Image, dir: int, f: int, v: int) -> void:
	var shell: Color = CHITIN[v % 4]
	var lit := shell.lightened(0.22)
	var leg := shell.darkened(0.3)
	var eye := Color(0.55, 0.95, 1.0)
	if dir == 2:
		for q in 3:                                                   # three legs on this side, each set down in its turn
			var lx := 7 + q * 3
			var down := 1 if (f + q) % 2 == 0 else 0
			_limb(img, Vector2(lx, 9), Vector2(lx - 1 + (q - 1), 11 + down), 1, leg)
		CA._ell(img, 11.0, 7.5, 5.5, 3.2, shell)
		CA._r(img, 8, 5, 6, 1, lit)
		CA._r(img, 3, 6, 4, 4, shell.darkened(0.1))                   # the head
		CA._px(img, 3, 7, eye)
		CA._px(img, 2, 9, leg)                                        # its jaws
		for q2 in 3:
			CA._px(img, 9 + q2 * 2, 4, FROST)                         # the ridge of frost
		CA._px(img, 11, 3, FROST)
		return
	var cx := img.get_width() / 2
	for side in [-1, 1]:
		for q3 in 3:
			var down2 := 1 if (f + q3 + (0 if side < 0 else 1)) % 2 == 0 else 0
			_limb(img, Vector2(cx + side * 3, 6 + q3), Vector2(cx + side * (6 + (q3 % 2)), 8 + q3 + down2), 1, leg)
	CA._ell(img, float(cx), 7.0, 4.6, 4.2, shell)
	CA._r(img, cx - 2, 3, 4, 1, lit)
	if dir == 0:
		CA._r(img, cx - 2, 8, 4, 4, shell.darkened(0.1))            # the head, low before it
		CA._px(img, cx - 2, 9, eye)
		CA._px(img, cx + 1, 9, eye)
		CA._px(img, cx - 1, 12, leg)
		CA._px(img, cx, 12, leg)
		CA._px(img, cx - 1, 4, FROST)
		CA._px(img, cx, 5, FROST)
	else:
		for q4 in 3:
			CA._px(img, cx - (q4 % 2), 4 + q4 * 2, FROST)


## The Burrower: what lives under the ice. A thick body in rings of dark plate, risen out of the hole it broke; two
## pale claws to dig with, a round mouth full of teeth, no eyes (`f`: it sways).
static func _burrower(img: Image, dir: int, f: int, v: int) -> void:
	var hide: Color = [Color(0.25, 0.2, 0.33), Color(0.2, 0.22, 0.35), Color(0.28, 0.2, 0.29), Color(0.21, 0.24, 0.31)][v % 4]
	var lit := hide.lightened(0.2)
	var claw := Color(0.88, 0.91, 0.95)
	var maw := Color(0.78, 0.2, 0.3)
	var cx := img.get_width() / 2
	var base := img.get_height() - 3
	var sway: int = [0, -1, 1][f]
	for q in 7:                                                       # the ice it broke, lying round where it stands
		CA._r(img, cx - 11 + q * 3 + (q % 2), base - (q % 3), 3, 2 + (q % 3), FROST if q % 2 == 0 else FROST_D)
	if dir == 2:
		for s in 5:                                                   # rings of plate, leaning the way it goes
			var sy := base - 3 - s * 4
			var sx := cx + 4 - s * 2 + (sway if s > 2 else 0)
			CA._ell(img, float(sx), float(sy), 6.5 - s * 0.5, 3.2, hide if s % 2 == 0 else hide.darkened(0.14))
			CA._r(img, sx - 3, sy - 3, 5, 1, lit)
		var hx := cx - 6 + sway
		var hy := base - 21
		CA._ell(img, float(hx), float(hy), 4.6, 4.2, hide.darkened(0.05))      # the head, bent down at you
		CA._ell(img, float(hx) - 2.5, float(hy) + 1.0, 2.2, 2.6, maw)
		CA._px(img, hx - 5, hy, claw)                                          # teeth
		CA._px(img, hx - 5, hy + 2, claw)
		CA._px(img, hx - 3, hy + 3, claw)
		var bob := f % 2
		_limb(img, Vector2(cx - 1, base - 12), Vector2(cx - 10, base - 9 + bob), 2, hide.darkened(0.2))      # the arm it digs with
		_limb(img, Vector2(cx - 10, base - 9 + bob), Vector2(cx - 12, base - 4 + bob), 1, claw)
		_limb(img, Vector2(cx - 10, base - 9 + bob), Vector2(cx - 9, base - 4 + bob), 1, claw)
		return
	for s2 in 5:
		var sy2 := base - 3 - s2 * 4
		var off := sway if s2 > 2 else 0
		CA._ell(img, float(cx + off), float(sy2), 7.0 - s2 * 0.6, 3.2, hide if s2 % 2 == 0 else hide.darkened(0.14))
		CA._r(img, cx - 2 + off, sy2 - 3, 4, 1, lit)
	var hx2 := cx + sway
	var hy2 := base - 22
	CA._ell(img, float(hx2), float(hy2), 5.0, 4.5, hide.darkened(0.05))
	for side in [-1, 1]:                                              # the claws, held wide
		var up := (f % 2) if side < 0 else ((f + 1) % 2)
		_limb(img, Vector2(cx + side * 5, base - 13), Vector2(cx + side * 11, base - 10 - up), 2, hide.darkened(0.2))
		_limb(img, Vector2(cx + side * 11, base - 10 - up), Vector2(cx + side * 12, base - 5 - up), 1, claw)
		_limb(img, Vector2(cx + side * 11, base - 10 - up), Vector2(cx + side * 10, base - 5 - up), 1, claw)
	if dir == 0:
		CA._ell(img, float(hx2), float(hy2) + 1.0, 3.2, 3.0, maw)        # its mouth: a ring of teeth
		CA._ell(img, float(hx2), float(hy2) + 1.0, 1.5, 1.4, Color(0.2, 0.05, 0.1))
		for t in 6:
			CA._px(img, hx2 + int(round(cos(t * TAU / 6.0) * 2.7 - 0.5)), hy2 + 1 + int(round(sin(t * TAU / 6.0) * 2.5 - 0.5)), claw)
	else:
		CA._r(img, cx - 1 + sway, hy2 - 3, 2, 8, lit)                # the ridge down its back


## The Rimeback: a heavy beast on four legs, its head low, dark fur; on its back a shell of ice grown in spikes
## (`v` 2 and 3: the shell is broken off, stumps of it are left).
static func _rimeback(img: Image, dir: int, f: int, v: int) -> void:
	var fur: Color = [Color(0.25, 0.22, 0.31), Color(0.2, 0.23, 0.32)][v % 2]
	var lit := fur.lightened(0.18)
	var dark := fur.darkened(0.3)
	var horn := Color(0.86, 0.87, 0.8)
	var eye := Color(0.75, 0.95, 1.0)
	var shell := v < 2
	var base := img.get_height() - 2
	var st: int = [0, 1, 0][f]
	var st2: int = [0, 0, 1][f]
	if dir == 2:
		_limb(img, Vector2(13, base - 9), Vector2(12, base - st2), 3, dark)                # the far legs
		_limb(img, Vector2(26, base - 9), Vector2(27, base - st), 3, dark)
		_limb(img, Vector2(10, base - 9), Vector2(9, base - st), 3, fur.darkened(0.12))    # the near ones
		_limb(img, Vector2(23, base - 9), Vector2(24, base - st2), 3, fur.darkened(0.12))
		CA._ell(img, 18.0, float(base) - 13.0, 11.5, 7.5, fur)                             # the body, the hump of its shoulders
		CA._ell(img, 13.0, float(base) - 16.0, 6.5, 6.0, fur)
		CA._r(img, 9, base - 21, 14, 1, lit)
		CA._ell(img, 5.5, float(base) - 9.0, 4.5, 4.2, fur.darkened(0.08))                 # the head, low
		CA._px(img, 3, base - 10, eye)
		_limb(img, Vector2(4, base - 12), Vector2(1, base - 15), 1, horn)                  # a horn
		CA._r(img, 2, base - 6, 3, 1, dark)                                                # the jaw
		_ice(img, 8, 30, base - 20, 10 if shell else 3, v)
		return
	var cx := img.get_width() / 2
	_limb(img, Vector2(cx - 7, base - 9), Vector2(cx - 8, base - st), 3, fur.darkened(0.12))
	_limb(img, Vector2(cx + 6, base - 9), Vector2(cx + 7, base - st2), 3, fur.darkened(0.12))
	CA._ell(img, float(cx), float(base) - 14.0, 11.0, 9.0, fur)
	CA._r(img, cx - 6, base - 23, 12, 1, lit)
	if dir == 0:
		CA._ell(img, float(cx), float(base) - 9.0, 5.5, 5.0, fur.darkened(0.08))           # the head, low before its chest
		CA._px(img, cx - 3, base - 10, eye)
		CA._px(img, cx + 2, base - 10, eye)
		_limb(img, Vector2(cx - 4, base - 12), Vector2(cx - 8, base - 16), 1, horn)
		_limb(img, Vector2(cx + 3, base - 12), Vector2(cx + 7, base - 16), 1, horn)
		CA._r(img, cx - 2, base - 6, 4, 1, dark)
	_ice(img, cx - 10, cx + 10, base - 21, 10 if shell else 3, v)


## The block of ice a crate of Whiteout is frozen into (drawn over the crate).
static func ice_block() -> Texture2D:
	if not _cache.has("ice_block"):
		var img := Image.create(26, 24, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		for y in range(5, 23):                                          # its body: you see the crate through it
			for x in range(2, 24):
				img.set_pixel(x, y, Color(0.55, 0.8, 1.0, 0.5 if (x + y) % 7 != 0 else 0.62))
		for x2 in range(2, 24):                                         # its top: cut at a slant, brighter
			var up := 2 + int(_hash1(x2 / 3 + 40) * 3.0)
			for y2 in range(5 - up, 6):
				img.set_pixel(x2, y2, Color(0.85, 0.95, 1.0, 0.8))
		for y3 in range(4, 23):
			img.set_pixel(2, y3, Color(0.95, 0.99, 1.0, 0.9))             # the lit edge
			img.set_pixel(23, y3, Color(0.3, 0.55, 0.9, 0.8))             # the edge in shadow
		for x3 in range(2, 24):
			img.set_pixel(x3, 22, Color(0.3, 0.55, 0.9, 0.8))
		for g in 4:                                                     # glints across its face
			for q in 5 - g:
				img.set_pixel(6 + g * 4 + q, 9 + g * 3 - q, Color(1.0, 1.0, 1.0, 0.85))
		_cache["ice_block"] = ImageTexture.create_from_image(img)
	return _cache["ice_block"]


# ---------------------------------------------------------------- part 9b: the rest of Whiteout

## The Shardthrower: thin and tall, dark, long needles of ice grown out of its back; one arm raised with a needle in
## its hand (`f`: its step).
static func _shardthrower(img: Image, dir: int, f: int, v: int) -> void:
	var skin: Color = [Color(0.2, 0.24, 0.36), Color(0.24, 0.22, 0.36), Color(0.18, 0.27, 0.34), Color(0.23, 0.25, 0.31)][v % 4]
	var lit := skin.lightened(0.2)
	var dark := skin.darkened(0.3)
	var cx := img.get_width() / 2
	var st: int = [0, 1, 0][f]
	var st2: int = [0, 0, 1][f]
	_limb(img, Vector2(cx - 2, 27), Vector2(cx - 3, 38 - st), 2, dark)
	_limb(img, Vector2(cx + 2, 27), Vector2(cx + 3, 38 - st2), 2, dark)
	_ice(img, cx - 6, cx + 6, 17, 11, v + 3)                                # the needles on its back, behind its head
	CA._r(img, cx - 4, 16, 8, 12, skin)                                     # the body
	CA._r(img, cx - 4, 16, 8, 1, lit)
	CA._ell(img, float(cx) + (-1.5 if dir == 2 else 0.0), 12.0, 3.4, 3.4, skin.darkened(0.08))
	if dir == 0:
		CA._px(img, cx - 2, 12, Color(0.6, 0.95, 1.0))
		CA._px(img, cx + 1, 12, Color(0.6, 0.95, 1.0))
	elif dir == 2:
		CA._px(img, cx - 4, 12, Color(0.6, 0.95, 1.0))
	var hand := Vector2(cx + (7 if dir != 2 else -7), 9)                    # the arm it throws with, raised
	_limb(img, Vector2(cx + (4 if dir != 2 else -4), 18), hand, 2, dark)
	_limb(img, hand, hand + Vector2((2 if dir != 2 else -2), -6), 1, FROST)
	CA._px(img, int(hand.x), int(hand.y) - 7, FROST_D)
	_limb(img, Vector2(cx - (4 if dir != 2 else -4), 18), Vector2(cx - (6 if dir != 2 else -5), 26), 2, dark)


## The Glider: what sails over the ice: a dark body, wide pale wings like a ray's, rime along their edges (`f`: how
## its wings stand).
static func _glider(img: Image, f: int, v: int) -> void:
	var cx := img.get_width() / 2
	var cy := 10
	var body: Color = CHITIN[v % 4]
	var wing := Color(0.5, 0.62, 0.8)
	var beat: int = [0, -2, 2][f]
	for wg in [-1, 1]:
		for q in 18:
			var x: int = cx + 4 + q if wg == 1 else cx - 5 - q
			var y: int = cy - 2 + (q * beat) / 18 + q / 6
			CA._r(img, x, y, 1, maxi(1, 7 - q / 3), wing if q % 4 != 0 else wing.darkened(0.2))
			CA._px(img, x, y, FROST)
	CA._ell(img, float(cx), float(cy) + 1.0, 5.0, 6.0, body)
	CA._ell(img, float(cx) - 1.0, float(cy) - 1.0, 2.6, 2.4, body.lightened(0.2))
	CA._px(img, cx - 2, cy + 3, Color(0.6, 0.95, 1.0))
	CA._px(img, cx + 1, cy + 3, Color(0.6, 0.95, 1.0))
	CA._r(img, cx - 1, cy + 7, 2, 4, body.darkened(0.2))                    # its tail


# ---------------------------------------------------------------- part 9c: the bosses of Whiteout

## The Ice Worm, risen out of the ice it broke: rings of pale armour one over the other, dark between them, spikes
## of ice along its sides and on its head, a round mouth full of teeth (`f`: it sways).
static func _iceworm(img: Image, dir: int, f: int) -> void:
	var plate := Color(0.6, 0.76, 0.92)
	var gap := Color(0.12, 0.17, 0.33)
	var maw := Color(0.86, 0.2, 0.42)
	var cx := img.get_width() / 2
	var base := img.get_height() - 4
	var sway: int = [0, -1, 1][f]
	for q in 11:                                                      # the ice it broke, lying round where it stands
		CA._r(img, cx - 20 + q * 4 - (q % 2), base - (q % 3) * 2, 4, 3 + (q % 3) * 2, FROST if q % 2 == 0 else FROST_D)
	var top := Vector2(cx, base)
	for s in 11:
		var sy := base - 4 - s * 5
		var off := (sway * s) / 4 + (-(s * s) / 14 if dir == 2 else 0)
		var rx := 11.5 - s * 0.32
		CA._ell(img, float(cx + off), float(sy), rx, 3.8, gap)
		CA._ell(img, float(cx + off), float(sy) - 1.2, rx, 2.7, plate if s % 2 == 0 else plate.darkened(0.12))
		CA._r(img, cx + off - int(rx) + 2, sy - 3, 5, 1, FROST)
		CA._px(img, cx + off - int(rx) - 1, sy - 1, FROST)                # a spike at either side of each ring
		CA._px(img, cx + off - int(rx) - 2, sy - 2, FROST)
		CA._px(img, cx + off + int(rx), sy - 1, FROST_D)
		CA._px(img, cx + off + int(rx) + 1, sy - 2, FROST_D)
		top = Vector2(cx + off, sy)
	var hx := int(top.x) + (-4 if dir == 2 else 0)
	var hy := int(top.y) - 7
	_ice(img, hx - 9, hx + 9, hy - 5, 8, 5)                                # the crown of ice on its head
	CA._ell(img, float(hx), float(hy), 9.5, 8.0, plate.darkened(0.05))
	CA._ell(img, float(hx) - 2.0, float(hy) - 3.0, 5.0, 3.0, FROST)
	if dir == 1:
		CA._r(img, hx - 1, hy - 4, 2, 10, gap)                               # the seam down its back
		return
	var mx := float(hx) + (-3.0 if dir == 2 else 0.0)
	CA._ell(img, mx, float(hy) + 2.0, 5.6 if dir == 0 else 3.6, 5.2, maw)       # its mouth: a ring of teeth
	CA._ell(img, mx, float(hy) + 2.0, 2.8 if dir == 0 else 1.8, 2.6, Color(0.2, 0.04, 0.1))
	for t in 8:
		CA._px(img, int(round(mx + cos(t * TAU / 8.0) * (4.8 if dir == 0 else 3.0) - 0.5)), hy + 2 + int(round(sin(t * TAU / 8.0) * 4.4 - 0.5)), Color(0.95, 0.97, 1.0))


## The Storm Heart: a tall crystal with many faces, pale at its edges and deep blue within, a heart of light beating
## in it (`f`); splinters of ice hang in the air round it.
static func _stormheart(img: Image, f: int) -> void:
	var cx := img.get_width() / 2
	var pale := Color(0.84, 0.95, 1.0)
	var mid := Color(0.48, 0.74, 0.98)
	var deep := Color(0.2, 0.36, 0.78)
	for y in range(4, 62):
		var hw := 0.0
		if y < 24:
			hw = 14.0 * float(y - 4) / 20.0
		else:
			hw = 14.0 - 9.0 * float(y - 24) / 38.0
		for x in range(cx - int(hw), cx + int(hw) + 1):
			var k := float(x - cx) / maxf(1.0, hw)
			var c := pale.lerp(mid, clampf(k + 0.75, 0.0, 1.0)) if k < 0.0 else mid.lerp(deep, clampf(k * 1.3, 0.0, 1.0))
			if absi(x - cx) <= 1 and y > 8:
				c = pale                                                # the edge down its middle
			CA._px(img, x, y, c)
	for fy in [14, 24, 40]:                                            # the lines where its faces meet
		for x2 in range(cx - 12, cx + 13):
			if img.get_pixel(clampi(x2, 0, img.get_width() - 1), fy).a > 0.5:
				CA._px(img, x2, fy + (absi(x2 - cx) / 3), deep if x2 > cx else mid)
	var beat: float = [0.55, 0.8, 1.0][f]                                   # the heart of light in it
	CA._ell(img, float(cx), 27.0, 6.0, 8.5, Color(0.55, 0.3, 0.95, 0.75))
	CA._ell(img, float(cx), 27.0, 4.0, 6.0, Color(0.95, 0.55, 0.95).lerp(Color(1, 1, 1), beat * 0.5))
	CA._ell(img, float(cx), 27.0, 1.8, 2.8, Color(1, 1, 1, beat))
	for q in 6:                                                        # splinters hanging in the air round it
		var a := q * TAU / 6.0 + f * 0.25
		var sp := Vector2(cx + cos(a) * 19.0, 34.0 + sin(a) * 20.0)
		CA._r(img, int(sp.x), int(sp.y) - 2, 2, 5, pale if q % 2 == 0 else mid)
		CA._px(img, int(sp.x), int(sp.y) - 3, pale)
	for q2 in 7:                                                       # the ice under it
		CA._r(img, cx - 13 + q2 * 4, img.get_height() - 5 - (q2 % 3), 3, 3 + (q2 % 3), FROST if q2 % 2 == 0 else FROST_D)
