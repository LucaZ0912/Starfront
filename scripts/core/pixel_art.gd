class_name PixelArt
extends RefCounted
## Generates all pixel-art textures at runtime (ships, stations, gates, asteroids, wrecks, icons).
## Textures are cached. Rendered with nearest filtering (see project.godot).

const FactionData = preload("res://data/factions.gd")
const ShipArt = preload("res://data/pixel_art.gd")
const NotoriousData = preload("res://scripts/core/notorious.gd")
## World units per pixel
const SCALE := 4.0

static var _cache := {}

const PALETTE := {
	"o": Color(0.05, 0.06, 0.09),
	"c": Color(0.12, 0.4, 0.7), "C": Color(0.6, 0.92, 1.0),
	"e": Color(0.25, 0.25, 0.3),
	"w": Color(0.55, 0.57, 0.62), "g": Color(0.28, 0.29, 0.32),
	"y": Color(1.0, 0.9, 0.4), "r": Color(1.0, 0.28, 0.22), "G": Color(0.3, 1.0, 0.45),
	"m": Color(0.95, 0.6, 0.15), "k": Color(0.48, 0.4, 0.28), "K": Color(0.68, 0.58, 0.4),
	"s": Color(0.12, 0.22, 0.5), "S": Color(0.3, 0.5, 0.88),
	# KHI construction yellow (package 25a) – stays yellow whoever owns the ship
	"Y": Color(0.95, 0.74, 0.12), "L": Color(1.0, 0.87, 0.38), "Q": Color(0.7, 0.48, 0.08),
	"x": Color(0.11, 0.11, 0.12), "z": Color(1.0, 0.5, 0.12),
	# Maison Aurelle ivory and gold (package 25c) – stays ivory whoever owns the ship
	"J": Color(1.0, 0.99, 0.95), "I": Color(0.92, 0.9, 0.84), "j": Color(0.74, 0.71, 0.64),
	"U": Color(0.84, 0.63, 0.22), "u": Color(1.0, 0.86, 0.52), "v": Color(0.16, 0.19, 0.28), "V": Color(1.0, 0.92, 0.66),
	# Hadrian Dynamics steel (package 25d): edge, gunmetal, dark steel, black seams, red lights
	"B": Color(0.5, 0.52, 0.56), "M": Color(0.31, 0.32, 0.35), "N": Color(0.2, 0.21, 0.23), "X": Color(0.1, 0.1, 0.12),
	"R": Color(0.95, 0.2, 0.14), "E": Color(1.0, 0.55, 0.42),
	# the Empress' park deck under glass: lawn, trees, pool, glass ribs
	"n": Color(0.4, 0.66, 0.46), "T": Color(0.15, 0.42, 0.3), "t": Color(0.3, 0.6, 0.36),
	"P": Color(0.2, 0.62, 0.92), "p": Color(0.72, 0.94, 1.0), "q": Color(0.66, 0.84, 0.92),
}
const FACTION := {
	"player": {"h": Color(0.62, 0.68, 0.77), "H": Color(0.85, 0.89, 0.95), "d": Color(0.42, 0.47, 0.57), "D": Color(0.27, 0.3, 0.38),
		"a": Color(0.25, 0.78, 1.0), "f": Color(0.55, 0.88, 1.0)},
	"khi_drone": {"h": Color(0.95, 0.74, 0.12), "H": Color(1.0, 0.87, 0.38), "d": Color(0.7, 0.48, 0.08), "D": Color(0.35, 0.24, 0.05),
		"a": Color(0.12, 0.12, 0.13), "f": Color(1.0, 0.7, 0.3)},
	"aurelle_drone": {"h": Color(0.92, 0.9, 0.84), "H": Color(1.0, 0.99, 0.95), "d": Color(0.74, 0.71, 0.64), "D": Color(0.84, 0.63, 0.22),
		"a": Color(0.84, 0.63, 0.22), "f": Color(0.7, 0.9, 1.0)},
	"pirate": {"h": Color(0.56, 0.42, 0.35), "H": Color(0.74, 0.58, 0.46), "d": Color(0.38, 0.27, 0.23), "D": Color(0.24, 0.17, 0.15),
		"a": Color(0.95, 0.22, 0.18), "f": Color(1.0, 0.55, 0.2)},
	"neutral": {"h": Color(0.66, 0.64, 0.56), "H": Color(0.86, 0.84, 0.74), "d": Color(0.45, 0.43, 0.37), "D": Color(0.3, 0.29, 0.25),
		"a": Color(1.0, 0.85, 0.3), "f": Color(1.0, 0.85, 0.5)},
}
const SHADE_DOWN := {"H": "h", "h": "d", "d": "D", "L": "Y", "Y": "Q", "J": "I", "I": "j", "u": "U", "B": "M", "M": "N"}
## Pirate copies of Hadrian ships are worn out: rusty steel, a dim orange light (package 25d)
const HDY_WORN := {"B": Color(0.56, 0.44, 0.34), "M": Color(0.38, 0.3, 0.24), "N": Color(0.26, 0.2, 0.17),
	"X": Color(0.13, 0.1, 0.09), "R": Color(1.0, 0.5, 0.18)}


# ---------------------------------------------------------------- Basics

static func _pad(rows: Array) -> Array:
	var w := 0
	for r in rows:
		w = maxi(w, String(r).length())
	var out: Array = []
	for r in rows:
		out.append(String(r).rpad(w, "."))
	return out


## Mirrors the top half downwards; the bottom half is shaded darker.
static func _mirror_v(top: Array) -> Array:
	var out: Array = top.duplicate()
	for i in range(top.size() - 2, -1, -1):
		var src: String = top[i]
		var row := ""
		for ch in src:
			row += SHADE_DOWN.get(ch, ch)
		out.append(row)
	return out


## Character grid -> Image with automatic outline (1 px border).
static func grid_to_image(rows: Array, colors: Dictionary, outline: bool = true) -> Image:
	var h := rows.size()
	var w := String(rows[0]).length()
	var img := Image.create(w + 2, h + 2, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var solid := {}
	for y in h:
		var row: String = rows[y]
		for x in w:
			var ch := row[x]
			if ch == ".":
				continue
			var col: Color = colors.get(ch, PALETTE.get(ch, Color.MAGENTA))
			img.set_pixel(x + 1, y + 1, col)
			solid[Vector2i(x + 1, y + 1)] = true
	if outline:
		var oc: Color = PALETTE["o"]
		for y in h + 2:
			for x in w + 2:
				var p := Vector2i(x, y)
				if solid.has(p):
					continue
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					if solid.has(p + d):
						img.set_pixel(x, y, oc)
						break
	return img


static func _colors(faction: String) -> Dictionary:
	var c: Dictionary = PALETTE.duplicate()
	if faction.begins_with("notorious_"):
		c.merge(notorious_paint(int(faction.trim_prefix("notorious_"))), true)
		return c
	if not FACTION.has(faction) and FactionData.FACTIONS.has(faction):
		c.merge(paint(faction), true)
		return c
	c.merge(FACTION.get(faction, FACTION["neutral"]), true)
	return c


## Own paint of a notorious pirate (phase 0.5 package 15).
static func notorious_paint(i: int) -> Dictionary:
	var key := "paint_notorious_%d" % i
	if _cache.has(key):
		return _cache[key]
	var p: Array = NotoriousData.PAINTS[i % NotoriousData.PAINTS.size()]
	var hull: Color = p[0]
	var acc: Color = p[1]
	var out := {"h": hull, "H": hull.lightened(0.3), "d": hull.darkened(0.3), "D": hull.darkened(0.6),
		"a": acc, "f": acc.lightened(0.3)}
	_cache[key] = out
	return out


## Engine flames where the drives really are (package 25d): groups of rows with engine-glow pixels ("f")
## at the stern of the art. [] = one flame on the centre line as before (a group covers the centre row);
## otherwise [[local position (world units, x forward), radius], …] – e.g. the Goliath's two arm drives.
static func engine_points(key: String) -> Array:
	var ck := "engines_" + key
	if _cache.has(ck):
		return _cache[ck]
	var art: Array = ShipArt.SHIPS.get(key, [])
	var rows := _pad(art) if ShipArt.FULL.has(key) else _mirror_v(_pad(art))
	var h := rows.size()
	var w := String(rows[0]).length() if h > 0 else 0
	var first := {}
	var min_x := 1 << 20
	for y in h:
		var fx := String(rows[y]).find("f")
		if fx >= 0:
			first[y] = fx
			min_x = mini(min_x, fx)
	var groups: Array = []
	var cur: Array = []
	for y2 in h:
		if first.has(y2) and int(first[y2]) <= min_x + 3:
			cur.append(y2)
		elif not cur.is_empty():
			groups.append(cur)
			cur = []
	if not cur.is_empty():
		groups.append(cur)
	var out: Array = []
	var mid := (h - 1) / 2
	for g in groups:
		if mid in g:
			out = []
			break
		var gy := (float(g[0]) + float(g[g.size() - 1])) * 0.5
		var gx := float(first[g[0]])
		var pos := (Vector2(gx + 1.5, gy + 1.5) - Vector2(w + 2, h + 2) * 0.5) * SCALE
		out.append([pos, clampf(float(g.size()) * SCALE * 0.9, 6.0, 40.0)])
	_cache[ck] = out
	return out


static func engine_glow(key: String) -> Color:
	if key.begins_with("notorious_"):
		return notorious_paint(int(key.trim_prefix("notorious_")))["f"]
	if FACTION.has(key):
		return FACTION[key]["f"]
	if FactionData.FACTIONS.has(key):
		return paint(key)["f"]
	return FACTION["neutral"]["f"]


## Ship paint of a government / pirate faction (phase 0.5 package 10): hull shades from the
## faction's hull colour, accents and engine glow from its main colour.
static func paint(fid: String) -> Dictionary:
	var key := "paint_" + fid
	if _cache.has(key):
		return _cache[key]
	var fd: Dictionary = FactionData.FACTIONS[fid]
	var hull: Color = fd["hull"]
	var acc: Color = fd["color"]
	var out := {"h": hull, "H": hull.lightened(0.25), "d": hull.darkened(0.3), "D": hull.darkened(0.55),
		"a": acc, "f": acc.lightened(0.35)}
	_cache[key] = out
	return out


static func white() -> Texture2D:
	if not _cache.has("white"):
		var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		_cache["white"] = ImageTexture.create_from_image(img)
	return _cache["white"]


# ---------------------------------------------------------------- Ships

## frame >= 0: animation frame of an animated hull (see anim_frames()).
static func ship_texture(hull_id: String, faction: String, frame: int = -1) -> Texture2D:
	var key := "ship_%s_%s_%d" % [hull_id, faction, frame]
	if not _cache.has(key):
		var art: Array = ShipArt.SHIPS.get(hull_id, ShipArt.SHIPS["dragonfly"])
		var rows := _pad(art) if ShipArt.FULL.has(hull_id) else _mirror_v(_pad(art))
		if frame >= 0:
			rows = _animate(rows, frame, anim_frames(hull_id))
		var cols := _colors(faction)
		if String(GameData.hulls.get(hull_id, {}).get("maker", "")) == "hadrian" and is_pirate_paint(faction):
			cols.merge(HDY_WORN, true)
		_cache[key] = ImageTexture.create_from_image(grid_to_image(rows, cols))
	return _cache[key]


## The two arms of a ship with swinging arms (Goliath, package 25d): [upper, lower] – the same size as
## the ship's picture, everything else transparent.
static func arm_textures(key: String, faction: String) -> Array:
	var ck := "arms_%s_%s" % [key, faction]
	if not _cache.has(ck):
		var rows := _mirror_v(_pad(ShipArt.SHIPS[key]))
		var n := rows.size()
		var mid := (n - 1) / 2
		var blank := ".".repeat(String(rows[0]).length())
		var up: Array = []
		var lo: Array = []
		for i in n:
			up.append(rows[i] if i < mid else blank)
			lo.append(rows[i] if i > mid else blank)
		var cols := _colors(faction)
		if is_pirate_paint(faction):
			cols.merge(HDY_WORN, true)
		_cache[ck] = [ImageTexture.create_from_image(grid_to_image(up, cols)), ImageTexture.create_from_image(grid_to_image(lo, cols))]
	return _cache[ck]


## Pirate paints: plain pirates, the pirate factions and notorious captains.
static func is_pirate_paint(faction: String) -> bool:
	if faction == "pirate" or faction.begins_with("notorious_"):
		return true
	return FactionData.FACTIONS.has(faction) and String(FactionData.FACTIONS[faction].get("kind", "")) == "pirate"


## Number of animation frames of a hull (0 = not animated).
static func anim_frames(hull_id: String) -> int:
	return int(ShipArt.ANIM.get(hull_id, 0))


## Current animation frame of a hull (-1 = not animated), about 7 frames per second.
static func anim_frame(hull_id: String) -> int:
	var n := anim_frames(hull_id)
	return -1 if n <= 0 else int(Time.get_ticks_msec() / 140) % n


## Package 25c (Empress): ripples move over the pool water; in the first half of the cycle a glint
## runs along the glass dome from stern to bow.
static func _animate(rows: Array, f: int, n: int) -> Array:
	var w := String(rows[0]).length()
	var h := rows.size()
	var half := maxi(n / 2, 1)
	var gx := -14.0 + float(f) / float(half) * float(w + 28) if f < half else -1000.0
	var fw := f / 2                  # the water ripples move at half speed (0.4.25.16)
	var glow := absf(float(f) - float(n) * 0.5) / (float(n) * 0.5)     # 1 → 0 → 1 over the cycle
	var out: Array = []
	for y in h:
		var src: String = rows[y]
		var row := ""
		for x in src.length():
			var ch := src[x]
			var gd := absf(float(x) - gx - float(y - h / 2) * 0.6)
			if (ch == "c" or ch == "q") and gd < 1.6:
				ch = "C"                 # the glint on the dome's frame
			elif gd < 0.9 and ch in "nTtryP":
				ch = "q"                 # … and as a pale streak on the glass over the deck
			elif ch == "P" and ((x + 2 * y + fw) % 6 == 0 or (x - y + fw * 2) % 12 == 0):
				ch = "p"
			elif ch == "R" and glow > 0.55:
				ch = "E"                 # Goliath: the red slits glow up (package 25d)
			row += ch
		out.append(row)
	return out


# ---------------------------------------------------------------- Station

const STATION_ACCENT := {
	"trade": Color(0.3, 0.85, 1.0), "industry": Color(1.0, 0.6, 0.2), "mining_colony": Color(0.9, 0.75, 0.3),
	"agri": Color(0.45, 1.0, 0.4), "research": Color(0.75, 0.45, 1.0), "military": Color(1.0, 0.3, 0.3),
	"ice_refinery": Color(0.85, 0.95, 1.0), "shipyard": Color(1.0, 0.5, 0.85), "pirate_haven": Color(1.0, 0.15, 0.2),
}


## Station art: see StationArt (modular stations, phase 0.5 package 6).


# ---------------------------------------------------------------- Hyperspace gate

static func gate_texture(cls: int) -> Texture2D:
	var key := "gate_%d" % cls
	if _cache.has(key):
		return _cache[key]
	var n := 61
	var c := 30
	var rows: Array = []
	for y in n:
		var row := ""
		for x in n:
			var dx := float(x - c)
			var dy := float(y - c)
			var r := sqrt(dx * dx + dy * dy)
			var ang := atan2(dy, dx)
			var seg := int((ang + PI) / TAU * 16.0)
			var lit := (-dx - dy) / maxf(r, 0.001)
			var ch := "."
			if r >= 23.0 and r <= 28.5:
				if seg % 2 == 0:
					ch = "H" if lit > 0.4 else ("h" if lit > -0.4 else "d")
				else:
					ch = "d" if r > 24.0 else "D"
				if r < 24.0 and seg % 2 == 0:
					ch = "a"
			elif r > 28.5 and r <= 30.0 and seg % 4 == 0:
				ch = "w"
			row += ch
		rows.append(row)
	var colors := _colors("neutral")
	colors["h"] = Color(0.5, 0.53, 0.6)
	colors["H"] = Color(0.75, 0.78, 0.85)
	colors["d"] = Color(0.3, 0.32, 0.38)
	colors["a"] = gate_color(cls)
	_cache[key] = ImageTexture.create_from_image(grid_to_image(rows, colors))
	return _cache[key]


static func gate_color(cls: int) -> Color:
	return [Color(0.35, 0.7, 1.0), Color(1.0, 0.75, 0.3), Color(1.0, 0.35, 0.35)][clampi(cls - 1, 0, 2)]


# ---------------------------------------------------------------- Asteroids

## Asteroid palettes per ore: built from a base tone and an accent (veins / glints).
const ORE_TINT := {
	"iron_ore": [Color(0.5, 0.44, 0.38), Color(0.75, 0.45, 0.3)],
	"nickel_ore": [Color(0.48, 0.47, 0.44), Color(0.85, 0.85, 0.7)],
	"titanium_ore": [Color(0.45, 0.5, 0.6), Color(0.6, 0.85, 1.0)],
	"cobalt_ore": [Color(0.38, 0.42, 0.55), Color(0.35, 0.55, 1.0)],
	"platinum_ore": [Color(0.55, 0.55, 0.58), Color(0.95, 0.95, 1.0)],
	"iridium_ore": [Color(0.42, 0.4, 0.46), Color(1.0, 0.85, 0.45)],
	"silicate_rock": [Color(0.62, 0.55, 0.45), Color(0.8, 0.75, 0.62)],
	"bauxite": [Color(0.6, 0.38, 0.28), Color(0.85, 0.5, 0.35)],
	"olivine": [Color(0.5, 0.52, 0.36), Color(0.6, 0.85, 0.35)],
	"rare_earth_ore": [Color(0.55, 0.45, 0.42), Color(0.95, 0.55, 0.75)],
	"xeno_crystal": [Color(0.4, 0.33, 0.52), Color(0.9, 0.45, 1.0)],
	"neodymium_ore": [Color(0.45, 0.42, 0.5), Color(0.6, 1.0, 0.8)],
	"water_ice": [Color(0.75, 0.85, 0.92), Color(1.0, 1.0, 1.0)],
	"ammonia_ice": [Color(0.72, 0.78, 0.72), Color(0.9, 1.0, 0.85)],
	"methane_ice": [Color(0.62, 0.72, 0.85), Color(0.75, 0.9, 1.0)],
	"deuterium_ice": [Color(0.55, 0.7, 0.9), Color(0.5, 0.8, 1.0)],
	"helium3_ice": [Color(0.7, 0.68, 0.85), Color(1.0, 0.85, 1.0)],
	"cryo_crystal": [Color(0.55, 0.85, 0.9), Color(0.4, 1.0, 1.0)],
}
static var _ore_pal := {}


static func ore_palette(ore: String) -> Array:
	if _ore_pal.has(ore):
		return _ore_pal[ore]
	var t: Array = ORE_TINT.get(ore, ORE_TINT["iron_ore"])
	var b: Color = t[0]
	var pal := [b.darkened(0.6), b.darkened(0.32), b, b.lightened(0.25), t[1]]
	_ore_pal[ore] = pal
	return pal


## Icon-sized asteroid for UI (refinery, inventory): round shape in the ore's class style.
static func asteroid_texture(seed_v: int, size: int, ore: String) -> Texture2D:
	var cls: String = GameData.commodities.get(ore, {}).get("class", "stony")
	return asteroid_sprite(cls, "round", seed_v, size, ore)


## Procedural asteroid. shape: round / potato / binary / fragment / shard.
## Look by class: metallic = veins + glints, stony = craters + speckles,
## icy = light, translucent rim, cracks and sparkles. Cached; seeds are bucketed into
## 8 variants per shape so a dense field reuses textures.
static func asteroid_sprite(cls: String, shape: String, seed_v: int, px: int, ore: String) -> Texture2D:
	var variant := posmod(seed_v, 8)
	px = clampi(int(round(px / 4.0)) * 4, 8, 48)
	var key := "ast2_%s_%s_%d_%d_%s" % [cls, shape, variant, px, ore]
	if _cache.has(key):
		return _cache[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = variant * 7919 + px * 31 + shape.hash()
	var noise := FastNoiseLite.new()
	noise.seed = variant * 131 + shape.length()
	noise.frequency = 0.18
	var c := px / 2.0
	var R := px * 0.42
	var rot := rng.randf() * TAU
	# Shape parameters
	var poly: Array = []
	if shape == "fragment":
		var n := rng.randi_range(5, 7)
		for k in n:
			var a := TAU * k / n + rng.randf_range(-0.25, 0.25)
			poly.append(Vector2.from_angle(a) * R * rng.randf_range(0.65, 1.0))
	var lobe := rng.randf_range(0.42, 0.52)
	# 1) mask
	var mask := []
	for y in px:
		var row := []
		for x in px:
			var d := Vector2(x + 0.5 - c, y + 0.5 - c)
			var q := d.rotated(-rot)
			var inside := false
			match shape:
				"potato":
					var e := Vector2(q.x / 1.35, q.y / 0.72)
					inside = e.length() < R * 0.95 * (0.88 + 0.18 * noise.get_noise_2d(e.angle() * 3.0, 0.0))
				"binary":
					var a1 := Vector2(-R * 0.38, 0.0)
					var a2 := Vector2(R * 0.42, R * 0.05)
					inside = q.distance_to(a1) < R * 0.6 * (0.9 + 0.15 * noise.get_noise_2d(x * 0.9, y * 0.9)) or q.distance_to(a2) < R * lobe * (0.9 + 0.15 * noise.get_noise_2d(y * 0.9, x * 0.9))
				"fragment":
					inside = Geometry2D.is_point_in_polygon(q, PackedVector2Array(poly))
				"shard":
					var jag := 1.0 + 0.12 * noise.get_noise_2d(x * 1.5, y * 1.5)
					inside = absf(q.x) / (R * 1.05) + absf(q.y) / (R * 0.36) < jag
					var q2 := q.rotated(0.9) + Vector2(R * 0.2, -R * 0.1)
					inside = inside or absf(q2.x) / (R * 0.6) + absf(q2.y) / (R * 0.22) < jag
				_:
					inside = d.length() < R * (0.82 + 0.25 * noise.get_noise_2d(cos(d.angle()) * 6.0, sin(d.angle()) * 6.0))
			row.append(inside)
		mask.append(row)
	# 2) surface
	var craters: Array = []
	var ncr := rng.randi_range(3, 6) if cls == "stony" else rng.randi_range(0, 2)
	for k in ncr:
		craters.append([Vector2(rng.randf_range(c - R * 0.6, c + R * 0.6), rng.randf_range(c - R * 0.6, c + R * 0.6)), rng.randf_range(1.2, maxf(1.5, px * 0.11))])
	var rarity: String = GameData.commodities.get(ore, {}).get("rarity", "common")
	var accent_p: float = {"common": 0.02, "uncommon": 0.035, "rare": 0.055}.get(rarity, 0.02)
	var rows: Array = []
	for y in px:
		var line := ""
		for x in px:
			if not mask[y][x]:
				line += "."
				continue
			var edge: bool = x == 0 or y == 0 or x == px - 1 or y == px - 1 or not mask[y][x - 1] or not mask[y][x + 1] or not mask[y - 1][x] or not mask[y + 1][x]
			var dx := x + 0.5 - c
			var dy := y + 0.5 - c
			var l := (-dx - dy) / (R * 1.4) + noise.get_noise_2d(x * 2.0, y * 2.0) * 0.35
			if cls == "icy":
				l += 0.25
			var level := 2
			if l > 0.35:
				level = 4
			elif l > 0.0:
				level = 3
			elif l < -0.45:
				level = 1
			for cr in craters:
				var cd: float = (Vector2(x, y) - cr[0]).length()
				if cd < cr[1]:
					level = maxi(1, level - 1)
				elif cls == "stony" and cd < cr[1] + 1.0:
					level = mini(4, level + 1)
			var ch := str(level)
			var ridge := absf(noise.get_noise_2d(x * 0.55 + 40.0, y * 0.55))
			match cls:
				"metallic":
					if ridge < 0.05 and not edge:
						ch = "x"
					elif rng.randf() < 0.025 and level >= 3:
						ch = "w"
				"stony":
					if rng.randf() < accent_p and not edge:
						ch = "x"
				"icy":
					if edge:
						ch = "e"
					elif ridge < 0.04:
						ch = "1"
					elif rng.randf() < 0.04:
						ch = "w"
			if ch != "x" and cls != "metallic" and rng.randf() < accent_p * 0.6 and not edge:
				ch = "x"
			line += ch
		rows.append(line)
	var pal: Array = ore_palette(ore)
	var colors := {"1": pal[0], "2": pal[1], "3": pal[2], "4": pal[3], "x": pal[4], "w": Color(1, 1, 1, 0.95), "e": Color(pal[3], 0.55)}
	_cache[key] = ImageTexture.create_from_image(grid_to_image(rows, colors, cls != "icy"))
	return _cache[key]


# ---------------------------------------------------------------- Wreck

static func wreck_texture(seed_v: int) -> Texture2D:
	var key := "wreck_%d" % seed_v
	if _cache.has(key):
		return _cache[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var n := 22
	var grid: Array = []
	for y in n:
		var r: Array = []
		r.resize(n)
		r.fill(".")
		grid.append(r)
	for i in rng.randi_range(4, 7):
		var p := Vector2(rng.randf_range(4, n - 4), rng.randf_range(4, n - 4))
		var dir := Vector2.from_angle(rng.randf() * TAU)
		var length := rng.randi_range(3, 8)
		var ch: String = ["h", "d", "d", "D"][rng.randi() % 4]
		for k in length:
			var q := p + dir * k
			var xi := clampi(int(q.x), 0, n - 1)
			var yi := clampi(int(q.y), 0, n - 1)
			grid[yi][xi] = ch
			if rng.randf() < 0.4:
				grid[clampi(yi + 1, 0, n - 1)][xi] = "d"
	for i in 3:
		grid[rng.randi_range(5, n - 6)][rng.randi_range(5, n - 6)] = "r"
	var rows: Array = []
	for r in grid:
		rows.append("".join(PackedStringArray(r)))
	_cache[key] = ImageTexture.create_from_image(grid_to_image(rows, _colors("neutral")))
	return _cache[key]


# ---------------------------------------------------------------- Module icons

const IconArt = preload("res://data/module_icons.gd")
const ICON_PALETTE := {
	"W": Color(0.86, 0.88, 0.92), "g": Color(0.55, 0.57, 0.63), "d": Color(0.3, 0.32, 0.38),
	"b": Color(0.22, 0.45, 0.92), "c": Color(0.45, 0.9, 1.0), "y": Color(1.0, 0.86, 0.3),
	"n": Color(1.0, 0.55, 0.15), "r": Color(0.95, 0.25, 0.2), "p": Color(0.72, 0.42, 1.0),
	"G": Color(0.3, 0.8, 0.4), "k": Color(0.5, 0.36, 0.22), "K": Color(0.74, 0.57, 0.36),
}
## Frame colour by module size
const SIZE_COLORS := {1: Color(0.55, 0.65, 0.75), 2: Color(0.4, 0.75, 1.0), 3: Color(1.0, 0.75, 0.3)}


static func module_icon_key(module_id: String) -> String:
	if module_id.begins_with("builtin:"):
		return {"builtin:refinery": "refinery", "builtin:prospect": "t_prospect", "builtin:factory": "factory", "builtin:market": "market",
			"builtin:afterburner": "o_afterburner", "builtin:pd": "w_pointdef"}.get(module_id, "empty")
	if not GameData.modules.has(module_id):
		return "empty"
	var m: Dictionary = GameData.modules[module_id]
	match String(m["slot"]):
		"weapon":
			if m.get("pd", false):
				return "w_pointdef"
			if m.get("mines", false):
				return "w_mines"
			return "w_" + String(m.get("damage_type", "kinetic"))
		"tool":
			return "t_" + String(m.get("tool", "scanner"))
		"optional":
			if m.has("solar"):
				return "o_solar"
			if m.has("cabin"):
				return "o_cabin_" + String(m["cabin"])
			match String(m.get("active", "")):
				"jammer":
					return "o_jammer"
				"afterburner":
					return "o_afterburner"
				"shield_boost":
					return "o_shieldboost"
				"armor_repair":
					return "o_armorrep"
			for k in [["ore_cargo", "o_orehold"], ["mining_bonus", "o_mining"], ["survey_range_mult", "o_survey_amp"],
					["cargo", "o_cargo"], ["shield", "o_shield"], ["armor", "o_armor"], ["speed_mult", "o_afterburner"],
					["range_mult", "o_targeting"], ["fuel", "o_fuel"], ["cap_bonus", "o_capacitor"]]:
				if m.has(k[0]):
					return k[1]
			return "o_cargo"
	return String(m["slot"])


static func icon_texture(key: String) -> Texture2D:
	var ck := "icon_" + key
	if not _cache.has(ck):
		var art: Array = IconArt.ICONS.get(key, IconArt.ICONS["empty"])
		var rows: Array = []
		for r in art:
			rows.append(String(r).rpad(16, ".").substr(0, 16))
		_cache[ck] = ImageTexture.create_from_image(grid_to_image(rows, ICON_PALETTE))
	return _cache[ck]


static func module_icon(module_id: String) -> Texture2D:
	return icon_texture(module_icon_key(module_id))
