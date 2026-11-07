extends RefCounted
## Package 28: the pilot's looks as a construction kit. One "look" dictionary drives both pictures, so they
## always match:
##   portrait(look) – a 48 x 48 pixel bust (menus, concourse, radio and news later)
##   sprite(look)   – a 16 x 16 top-down figure (prepared for part 7, when the pilot walks on the ground)
## Crews and mercenaries will get their portraits from the same kit (random_look).
##
## Look keys (all ints): body, skin, hair, hair_color, eyes, brows, beard, scar, freckles, outfit, color1, color2,
## implant, tattoo, headgear.

const SIZE := 48
const BODIES := ["Slim", "Average", "Broad"]
const SKINS := [Color8(255, 226, 200), Color8(243, 199, 160), Color8(226, 174, 128), Color8(199, 137, 92),
	Color8(161, 106, 68), Color8(122, 80, 52), Color8(88, 58, 40), Color8(214, 214, 222)]
const SKIN_NAMES := ["Porcelain", "Fair", "Light", "Tan", "Olive brown", "Brown", "Dark", "Ashen"]
const HAIRS := ["Bald", "Buzz cut", "Short", "Side part", "Long", "Ponytail", "Mohawk", "Curls", "Bun"]
const HAIR_COLORS := [Color8(30, 26, 28), Color8(70, 44, 30), Color8(120, 78, 44), Color8(150, 62, 34), Color8(222, 186, 108),
	Color8(236, 230, 210), Color8(140, 140, 146), Color8(250, 250, 250), Color8(255, 70, 170), Color8(60, 220, 240)]
const HAIR_COLOR_NAMES := ["Black", "Dark brown", "Brown", "Auburn", "Blond", "Platinum", "Grey", "White", "Neon pink", "Cyan"]
const EYES := [Color8(96, 62, 36), Color8(140, 110, 50), Color8(70, 140, 70), Color8(70, 120, 210), Color8(140, 150, 160), Color8(230, 160, 40)]
const EYE_NAMES := ["Brown", "Hazel", "Green", "Blue", "Grey", "Amber"]
const BROWS := ["Thin", "Normal", "Thick"]
const BEARDS := ["None", "Stubble", "Goatee", "Full beard", "Moustache"]
const SCARS := ["None", "Cheek", "Across the eye", "Brow"]
const OUTFITS := ["Flight suit", "Jacket", "Armoured suit", "Long coat"]
const CLOTH := [Color8(40, 46, 60), Color8(70, 80, 96), Color8(150, 156, 166), Color8(230, 232, 236), Color8(40, 70, 140),
	Color8(30, 150, 200), Color8(40, 110, 60), Color8(120, 130, 60), Color8(150, 40, 50), Color8(230, 100, 40),
	Color8(230, 190, 50), Color8(130, 60, 170), Color8(240, 70, 160), Color8(60, 230, 230)]
const CLOTH_NAMES := ["Graphite", "Slate", "Steel", "White", "Navy", "Sky", "Forest", "Olive", "Crimson", "Orange",
	"Gold", "Violet", "Neon pink", "Neon cyan"]
const IMPLANTS := ["None", "Cyber eye", "Jaw plate", "Temple circuits"]
const TATTOOS := ["None", "Cheek lines", "Forehead mark", "Neck lines"]
const HEADGEAR := ["None", "Headset", "Visor", "Glasses"]

## Every option of the kit: key, label, list of names (its length is the number of choices).
const OPTIONS := [
	["body", "Body", BODIES], ["skin", "Skin tone", SKIN_NAMES], ["hair", "Hair", HAIRS], ["hair_color", "Hair colour", HAIR_COLOR_NAMES],
	["eyes", "Eyes", EYE_NAMES], ["brows", "Brows", BROWS], ["beard", "Beard", BEARDS], ["scar", "Scar", SCARS],
	["freckles", "Freckles", ["No", "Yes"]], ["outfit", "Outfit", OUTFITS], ["color1", "Main colour", CLOTH_NAMES],
	["color2", "Accent colour", CLOTH_NAMES], ["implant", "Implant", IMPLANTS], ["tattoo", "Tattoo", TATTOOS],
	["headgear", "Headgear", HEADGEAR],
]

static var _cache := {}


static func default_look() -> Dictionary:
	return {"body": 1, "skin": 2, "hair": 2, "hair_color": 1, "eyes": 0, "brows": 1, "beard": 0, "scar": 0, "freckles": 0,
		"outfit": 0, "color1": 0, "color2": 5, "implant": 0, "tattoo": 0, "headgear": 0}


## A random look (crews and mercenaries later; the "Random" button of the creator).
static func random_look(rng: RandomNumberGenerator = null) -> Dictionary:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var l := {}
	for o in OPTIONS:
		l[o[0]] = rng.randi() % (o[2] as Array).size()
	# extras stay rarer than the basics
	for k in ["scar", "implant", "tattoo", "headgear"]:
		if rng.randf() < 0.6:
			l[k] = 0
	if rng.randf() < 0.5:
		l["beard"] = 0
	return l


## Clamps every value into its range (old or edited saves).
static func clean(look: Dictionary) -> Dictionary:
	var l := default_look()
	for o in OPTIONS:
		l[o[0]] = posmod(int(look.get(o[0], l[o[0]])), (o[2] as Array).size())
	return l


static func _key(look: Dictionary) -> String:
	var parts: Array = []
	for o in OPTIONS:
		parts.append(str(int(look.get(o[0], 0))))
	return ",".join(PackedStringArray(parts))


# ================================================================ Portrait (48 x 48, front view)

static func portrait(look: Dictionary) -> Texture2D:
	var l := clean(look)
	var key := "p" + _key(l)
	if not _cache.has(key):
		_cache[key] = ImageTexture.create_from_image(portrait_image(l))
	return _cache[key]


static func portrait_image(l: Dictionary) -> Image:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	# background: a dark gradient with faint scan lines
	for y in SIZE:
		for x in SIZE:
			var c := Color(0.05, 0.04, 0.1).lerp(Color(0.1, 0.08, 0.2), float(y) / SIZE)
			if y % 3 == 0:
				c = c.lightened(0.04)
			img.set_pixel(x, y, c)
	var skin: Color = SKINS[l["skin"]]
	var hair: Color = HAIR_COLORS[l["hair_color"]]
	var c1: Color = CLOTH[l["color1"]]
	var c2: Color = CLOTH[l["color2"]]
	var cx := 24.0
	var hy := 20.0                     # head centre
	var rx := 8.5
	var ry := 10.5
	# hair behind the head (long hair, ponytail, curls)
	match int(l["hair"]):
		4:
			_ellipse(img, cx, hy + 6.0, rx + 3.0, ry + 8.0, hair.darkened(0.15))
		5:
			_rect(img, 32, 16, 4, 16, hair.darkened(0.2))
			_rect(img, 33, 30, 2, 4, hair.darkened(0.35))
		7:
			_curls(img, cx, hy - 3.0, 14.0, hair)
	# body and outfit
	_body(img, l, c1, c2, skin)
	# neck
	_rect(img, 20, 28, 8, 7, skin.darkened(0.12))
	_rect(img, 20, 28, 2, 7, skin.darkened(0.22))
	# head with shading (light from the upper left) and an outline
	for y in SIZE:
		for x in SIZE:
			var dx := (float(x) + 0.5 - cx) / rx
			var dy := (float(y) + 0.5 - hy) / ry
			var dy2 := dy if dy < 0.0 else dy * (1.0 + dy * 0.25)    # a narrower chin
			var d := dx * dx + dy2 * dy2
			if d <= 1.0:
				var shade := clampf(0.5 + dx * 0.35 + dy * 0.2, 0.0, 1.0)
				var c := skin.lightened(0.08) if shade < 0.35 else (skin if shade < 0.62 else skin.darkened(0.14))
				if d > 0.86:
					c = skin.darkened(0.42)
				img.set_pixel(x, y, c)
	# ears
	for e in [[15, 19], [32, 19]]:
		_rect(img, e[0], e[1], 1, 4, skin.darkened(0.2))
	_face(img, l, skin, hair)
	_hair_front(img, l, hair, skin, cx, hy, rx, ry)
	_extras(img, l, skin)
	# a thin frame
	for i in SIZE:
		for p in [Vector2i(i, 0), Vector2i(i, SIZE - 1), Vector2i(0, i), Vector2i(SIZE - 1, i)]:
			img.set_pixelv(p, Color(0.35, 0.3, 0.55))
	return img


static func _body(img: Image, l: Dictionary, c1: Color, c2: Color, skin: Color) -> void:
	var bw: float = [0.85, 1.0, 1.18][int(l["body"])]
	for y in range(33, SIZE):
		var t := float(y - 33) / float(SIZE - 33)
		var half: float = (9.0 + 13.0 * minf(t * 1.6, 1.0)) * bw
		for x in SIZE:
			var dx := float(x) + 0.5 - 24.0
			if absf(dx) > half:
				continue
			var c := c1 if dx < half * 0.55 else c1.darkened(0.2)
			if absf(dx) > half - 1.0:
				c = c1.darkened(0.45)
			img.set_pixel(x, y, c)
	match int(l["outfit"]):
		0:   # flight suit: a collar ring, a zip and a chest strip
			for x in range(19, 29):
				img.set_pixel(x, 33, c2)
				img.set_pixel(x, 34, c2.darkened(0.25))
			_rect(img, 24, 35, 1, 13, c1.darkened(0.4))
			_rect(img, 13, 40, 7, 2, c2)
		1:   # jacket: open lapels over a shirt in the accent colour
			for y in range(33, SIZE):
				var w := 2 + (y - 33) / 3
				for x in range(24 - w, 24 + w):
					img.set_pixel(x, y, c2)
				img.set_pixel(24 - w - 1, y, c1.lightened(0.15))
				img.set_pixel(24 + w, y, c1.darkened(0.35))
		2:   # armoured suit: shoulder plates and segments
			for s in [-1, 1]:
				var x0: int = 24 + s * 13 - (6 if s < 0 else 0)
				_rect(img, x0, 35, 7, 4, c2)
				_rect(img, x0, 35, 7, 1, c2.lightened(0.3))
			for y in [40, 44]:
				for x in range(16, 33):
					img.set_pixel(x, y, c1.darkened(0.35))
			_rect(img, 22, 37, 5, 3, c2.darkened(0.1))
		3:   # long coat: a high collar and buttons
			for y in range(31, 37):
				for s in [-1, 1]:
					for k in 3:
						img.set_pixel(24 + s * (5 + k) - (1 if s < 0 else 0), y, c2 if k < 2 else c2.darkened(0.3))
			for y in [39, 42, 45]:
				img.set_pixel(22, y, c2.lightened(0.2))
				img.set_pixel(26, y, c2.lightened(0.2))


static func _face(img: Image, l: Dictionary, skin: Color, hair: Color) -> void:
	var eye: Color = EYES[l["eyes"]]
	var dark := skin.darkened(0.45)
	# eyes: lid, white and iris (looking slightly to the left)
	for e in [[19, 20], [27, 20]]:
		img.set_pixel(e[0], e[1] - 1, dark)
		img.set_pixel(e[0] + 1, e[1] - 1, dark)
		img.set_pixel(e[0], e[1], Color(0.95, 0.95, 0.95))
		img.set_pixel(e[0] + 1, e[1], eye)
		img.set_pixel(e[0] + 2, e[1], Color(0.8, 0.8, 0.82) if e[0] < 24 else skin.darkened(0.15))
	# brows
	var bc := hair.darkened(0.3) if int(l["hair"]) != 0 else skin.darkened(0.5)
	match int(l["brows"]):
		0:
			for e in [18, 27]:
				_rect(img, e, 17, 3, 1, bc)
		1:
			for e in [18, 27]:
				_rect(img, e, 17, 4, 1, bc)
		2:
			for e in [17, 27]:
				_rect(img, e, 16, 5, 2, bc)
	# nose and mouth
	img.set_pixel(24, 22, skin.darkened(0.18))
	img.set_pixel(24, 23, skin.darkened(0.25))
	img.set_pixel(23, 24, skin.darkened(0.35))
	img.set_pixel(25, 24, skin.darkened(0.3))
	var lip := skin.lerp(Color(0.6, 0.2, 0.2), 0.45)
	_rect(img, 22, 26, 5, 1, lip.darkened(0.25))
	_rect(img, 23, 27, 3, 1, lip)
	if int(l["freckles"]) == 1:
		for p in [[18, 23], [20, 24], [19, 22], [28, 23], [30, 24], [29, 22]]:
			img.set_pixel(p[0], p[1], skin.darkened(0.25))
	# beard
	var hc := hair if int(l["hair"]) != 0 else HAIR_COLORS[1]
	match int(l["beard"]):
		1:
			for y in range(23, 31):
				for x in range(17, 32):
					if (x + y) % 2 == 0 and _in_head(x, y) and not (y in [26, 27] and x >= 22 and x <= 26):
						img.set_pixel(x, y, img.get_pixel(x, y).lerp(hc, 0.45))
		2:
			_rect(img, 22, 28, 5, 3, hc)
			_rect(img, 21, 25, 7, 1, hc.darkened(0.1))
		3:
			for y in range(21, 32):
				for x in range(15, 34):
					if _in_head(x, y) and (x < 19 or x > 29 or y > 27) and not (y in [26, 27] and x >= 22 and x <= 26):
						img.set_pixel(x, y, hc if (x + y) % 3 != 0 else hc.darkened(0.2))
		4:
			_rect(img, 21, 25, 7, 1, hc)
			img.set_pixel(21, 26, hc)
			img.set_pixel(27, 26, hc)
	# scar
	var sc := skin.lerp(Color(0.95, 0.75, 0.75), 0.6)
	match int(l["scar"]):
		1:
			for i in 5:
				img.set_pixel(29 + i / 2, 21 + i, sc)
		2:
			for y in range(16, 25):
				if y != 20:
					img.set_pixel(28, y, sc)
		3:
			img.set_pixel(19, 16, sc)
			img.set_pixel(20, 17, sc)
			img.set_pixel(20, 15, sc)


static func _hair_front(img: Image, l: Dictionary, hair: Color, skin: Color, cx: float, hy: float, rx: float, ry: float) -> void:
	var dark := hair.darkened(0.25)
	match int(l["hair"]):
		0:   # bald: a shine
			img.set_pixel(20, 12, skin.lightened(0.3))
			img.set_pixel(21, 11, skin.lightened(0.3))
		1:   # buzz cut: a thin cap
			for y in range(8, 15):
				for x in range(14, 35):
					if _in_ellipse(x, y, cx, hy, rx + 0.4, ry + 0.4) and y <= 13:
						img.set_pixel(x, y, hair if (x + y) % 2 == 0 else dark)
		2, 4, 5, 8:   # short (also under long hair, ponytail and bun)
			_cap(img, cx, hy, rx, ry, hair, dark, 14)
			_rect(img, 15, 15, 2, 5, dark)
			_rect(img, 31, 15, 2, 5, dark)
			if int(l["hair"]) == 8:
				_ellipse(img, cx, 6.5, 4.5, 3.8, hair)
				_rect(img, 21, 6, 6, 1, dark)
			if int(l["hair"]) == 4:
				_rect(img, 14, 14, 3, 18, hair)
				_rect(img, 31, 14, 3, 18, hair.darkened(0.15))
		3:   # side part: a fringe swept across the forehead
			_cap(img, cx, hy, rx, ry, hair, dark, 13)
			for i in 9:
				_rect(img, 16 + i, 13 + i / 3, 1, 3 - i / 4, hair if i % 3 != 2 else dark)
			_rect(img, 15, 14, 2, 6, dark)
		6:   # mohawk: shaved sides, a crest on top
			for y in range(9, 15):
				for x in range(15, 34):
					if _in_ellipse(x, y, cx, hy, rx, ry) and (x + y) % 3 == 0:
						img.set_pixel(x, y, skin.lerp(hair, 0.3))
			for y in range(2, 14):
				var w := 2 if y < 5 else 3
				_rect(img, 24 - w, y, w * 2, 1, hair if y % 2 == 0 else dark)
		7:   # curls: the cloud in front, framing the face
			for y in range(4, 17):
				for x in range(9, 40):
					if _in_ellipse(x, y, cx, hy - 3.0, 14.0, 12.0) and not _in_ellipse(x, y, cx, hy + 1.0, rx - 0.5, ry - 1.0):
						img.set_pixel(x, y, hair if (x * 3 + y * 5) % 7 > 2 else dark)


static func _cap(img: Image, cx: float, hy: float, rx: float, ry: float, hair: Color, dark: Color, line: int) -> void:
	for y in range(5, line + 1):
		for x in range(12, 37):
			if _in_ellipse(x, y, cx, hy, rx + 1.4, ry + 1.6):
				var c := hair if x < 26 else dark
				if y == line and (x % 3 == 0):
					c = dark
				img.set_pixel(x, y, c)


static func _curls(img: Image, cx: float, cy: float, r: float, hair: Color) -> void:
	for y in SIZE:
		for x in SIZE:
			if _in_ellipse(x, y, cx, cy, r, r * 0.9) and y < 34:
				img.set_pixel(x, y, hair.darkened(0.15) if (x * 5 + y * 3) % 6 > 1 else hair.darkened(0.35))


static func _extras(img: Image, l: Dictionary, skin: Color) -> void:
	# implants
	match int(l["implant"]):
		1:   # cyber eye: a glowing lens in a metal ring
			_rect(img, 26, 18, 5, 4, Color(0.45, 0.48, 0.52))
			_rect(img, 27, 19, 3, 2, Color(1.0, 0.25, 0.2))
			img.set_pixel(28, 19, Color(1.0, 0.8, 0.7))
		2:   # jaw plate
			_rect(img, 28, 23, 4, 6, Color(0.55, 0.58, 0.62))
			_rect(img, 28, 23, 4, 1, Color(0.8, 0.83, 0.88))
			img.set_pixel(30, 26, Color(0.3, 0.9, 1.0))
		3:   # temple circuits
			for p in [[16, 15], [16, 16], [17, 17], [17, 18], [16, 19], [18, 17]]:
				img.set_pixel(p[0], p[1], Color(0.3, 0.95, 1.0))
	# tattoos
	var ink := Color(0.15, 0.35, 0.55)
	match int(l["tattoo"]):
		1:
			_rect(img, 18, 22, 1, 4, ink)
			_rect(img, 20, 22, 1, 3, ink)
		2:
			img.set_pixel(24, 12, ink)
			img.set_pixel(23, 13, ink)
			img.set_pixel(25, 13, ink)
			img.set_pixel(24, 14, ink)
		3:
			for y in range(29, 34):
				img.set_pixel(21 + (y % 2), y, ink)
				img.set_pixel(26 - (y % 2), y, ink)
	# headgear
	match int(l["headgear"]):
		1:   # headset: a band over the head, an earpiece and a microphone
			for x in range(14, 35):
				var y := int(round(9.0 + pow((float(x) - 24.0) / 10.0, 2.0) * 7.0))
				img.set_pixel(x, y, Color(0.25, 0.27, 0.3))
			_rect(img, 13, 17, 3, 6, Color(0.2, 0.22, 0.25))
			_rect(img, 14, 23, 1, 3, Color(0.2, 0.22, 0.25))
			for i in 6:
				img.set_pixel(15 + i, 26, Color(0.2, 0.22, 0.25))
			img.set_pixel(21, 26, Color(0.9, 0.3, 0.2))
		2:   # visor across the eyes
			_rect(img, 15, 18, 19, 4, Color(0.2, 0.85, 1.0, 1.0).darkened(0.35))
			_rect(img, 15, 18, 19, 1, Color(0.6, 1.0, 1.0))
			_rect(img, 15, 21, 19, 1, Color(0.1, 0.4, 0.5))
		3:   # glasses
			for e in [18, 26]:
				var fc := Color(0.15, 0.15, 0.18)
				_rect(img, e, 18, 5, 1, fc)
				_rect(img, e, 22, 5, 1, fc)
				_rect(img, e, 18, 1, 5, fc)
				_rect(img, e + 4, 18, 1, 5, fc)
			_rect(img, 23, 19, 3, 1, Color(0.15, 0.15, 0.18))


# ================================================================ Top-down sprite (16 x 16, part 7)

static func sprite(look: Dictionary) -> Texture2D:
	var l := clean(look)
	var key := "s" + _key(l)
	if not _cache.has(key):
		_cache[key] = ImageTexture.create_from_image(sprite_image(l))
	return _cache[key]


## Seen from above, facing right (like the ships): shoulders in the outfit colours, the head with its hair.
static func sprite_image(l: Dictionary) -> Image:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c1: Color = CLOTH[l["color1"]]
	var c2: Color = CLOTH[l["color2"]]
	var skin: Color = SKINS[l["skin"]]
	var hair: Color = HAIR_COLORS[l["hair_color"]]
	var bw: float = [3.2, 3.8, 4.5][int(l["body"])]
	for y in 16:
		for x in 16:
			var dx := (float(x) + 0.5 - 7.0) / 2.6
			var dy: float = (float(y) + 0.5 - 8.0) / bw
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(x, y, c1 if dy < 0.3 else c1.darkened(0.25))
	# arms
	_rect(img, 7, 8 - int(bw) - 1, 4, 2, c1.darkened(0.15))
	_rect(img, 7, 8 + int(bw), 4, 2, c1.darkened(0.3))
	_rect(img, 10, 8 - int(bw) - 1, 1, 2, skin)
	_rect(img, 10, 8 + int(bw), 1, 2, skin.darkened(0.2))
	if int(l["outfit"]) in [2, 3]:
		_rect(img, 5, 8 - int(bw), 3, int(bw) * 2, c2)
	# head
	var bald := int(l["hair"]) == 0
	for y in 16:
		for x in 16:
			var dx2 := float(x) + 0.5 - 8.0
			var dy2 := float(y) + 0.5 - 8.0
			var r := dx2 * dx2 + dy2 * dy2
			if r <= 6.5:
				var c := skin if bald or dx2 > 1.2 else hair
				if int(l["hair"]) == 7 and r <= 9.0:
					c = hair
				img.set_pixel(x, y, c)
	if int(l["hair"]) == 5:
		_rect(img, 4, 7, 2, 2, hair.darkened(0.2))
	if int(l["headgear"]) == 2:
		_rect(img, 10, 6, 1, 4, Color(0.3, 0.9, 1.0))
	return img


# ================================================================ Helpers

static func _rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			if xx >= 0 and yy >= 0 and xx < img.get_width() and yy < img.get_height():
				img.set_pixel(xx, yy, c)


static func _ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for y in img.get_height():
		for x in img.get_width():
			if _in_ellipse(x, y, cx, cy, rx, ry):
				img.set_pixel(x, y, c)


static func _in_ellipse(x: int, y: int, cx: float, cy: float, rx: float, ry: float) -> bool:
	var dx := (float(x) + 0.5 - cx) / rx
	var dy := (float(y) + 0.5 - cy) / ry
	return dx * dx + dy * dy <= 1.0


static func _in_head(x: int, y: int) -> bool:
	var dx := (float(x) + 0.5 - 24.0) / 8.5
	var dy := (float(y) + 0.5 - 20.0) / 10.5
	var dy2 := dy if dy < 0.0 else dy * (1.0 + dy * 0.25)
	return dx * dx + dy2 * dy2 <= 0.86
