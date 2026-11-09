class_name ObjArt
extends RefCounted
## Package 49 (0.7.49.2): furniture in the slanted view – each piece its own picture: a top lit from above, a front
## face below it, standing on its footprint (w × h tiles) and rising `rise` art px above it. GroundView places it with
## its foot at the bottom of the footprint and sorts it by depth with the people.

const TILE := 16
const OUT := Color(0.09, 0.07, 0.11)

static var _cache := {}


## {image, rise} for an object.
static func make(o: Dictionary, pal: Dictionary) -> Dictionary:
	var key := "%s_%d_%d_%s_%s_%d_%d" % [o["kind"], int(o.get("w", 1)), int(o.get("h", 1)), str(o.get("col", "")), str(pal.get("wood", "")), int(o.get("face", 0)), int(o.get("x", 0)) % 4]
	if _cache.has(key):
		return _cache[key]
	var pw := int(o.get("w", 1)) * TILE
	var ph := int(o.get("h", 1)) * TILE
	var rise := _rise(String(o["kind"]))
	var img := Image.create(pw, ph + rise, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c: Color = o.get("col", pal.get("accent", Color(0.4, 0.8, 1.0)))
	var wood: Color = pal.get("wood", Color(0.42, 0.26, 0.14))
	var metal: Color = pal.get("wall", Color(0.6, 0.62, 0.68))
	_paint(img, String(o["kind"]), pw, ph, rise, c, wood, metal, o)
	_outline(img)
	var out := {"image": img, "rise": rise}
	_cache[key] = out
	return out


static func _rise(kind: String) -> int:
	match kind:
		"palm":
			return 34
		"parasol":
			return 28
		"banner", "holo_pillar", "pipes":
			return 24
		"tank", "ice_sculpture", "cage", "vending", "locker":
			return 20
		"engine_part", "fountain", "heater", "planter":
			return 14
		"barrel", "barrel_table", "ore_cart":
			return 8
		"pool_table", "trash", "flower_bed", "table_small", "lounger":
			return 6
		"crate_seat":
			return 4
		"plant", "terminal", "jukebox", "lamp_post", "display", "fridge":
			return 18
		"bar_counter", "counter", "counter_v", "machine", "crates":
			return 10
		"round_table", "table":
			return 8
		"chair", "bench", "bench_back":
			return 12
		"sofa":
			return 14
		"stool", "railing":
			return 6
	return 6


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


## The footprint starts at y = rise (the top `rise` px are what stands up above it).
static func _paint(img: Image, kind: String, pw: int, ph: int, rise: int, c: Color, wood: Color, metal: Color, o: Dictionary) -> void:
	var fy := rise                     # top of the footprint in the picture
	match kind:
		"round_table":
			_ellipse(img, pw * 0.5, fy + ph * 0.62, pw * 0.22, ph * 0.12, Color(0, 0, 0, 0.25))       # shadow
			_r(img, int(pw * 0.5) - 2, fy + int(ph * 0.3), 4, int(ph * 0.35), wood.darkened(0.4))    # the leg
			_ellipse(img, pw * 0.5, fy + ph * 0.25, pw * 0.44, ph * 0.3, wood.darkened(0.25))          # the rim
			_ellipse(img, pw * 0.5, fy + ph * 0.2, pw * 0.42, ph * 0.26, wood.lightened(0.1))          # the top
			_ellipse(img, pw * 0.5, fy + ph * 0.17, pw * 0.2, ph * 0.1, wood.lightened(0.22))
			_r(img, int(pw * 0.42), fy + int(ph * 0.12), 3, 4, Color(0.95, 0.85, 0.5))                 # a candle / glass
			_r(img, int(pw * 0.58), fy + int(ph * 0.18), 2, 3, Color(0.6, 0.85, 1.0))
		"table":
			_r(img, 2, fy - 2, pw - 4, ph - 4, wood.lightened(0.08))
			_r(img, 2, fy + ph - 6, pw - 4, 4, wood.darkened(0.3))
			_r(img, 3, fy + ph - 2, 2, 2, wood.darkened(0.5))
			_r(img, pw - 5, fy + ph - 2, 2, 2, wood.darkened(0.5))
		"chair":
			# 0.7.49.12: sized for the tall figures – the seat at hip height, the backrest up to the shoulders,
			# on the side away from the table (face: where the sitter looks)
			var fc := int(o.get("face", 0))
			var b := fy + ph
			if fc == 0:
				_r(img, 3, b - 24, pw - 6, 14, c.darkened(0.32))
				_r(img, 3, b - 24, pw - 6, 1, c.lightened(0.12))
				_r(img, 5, b - 21, pw - 10, 8, c.darkened(0.22))
			_r(img, 2, b - 12, pw - 4, 5, c.lightened(0.05))                 # the seat, seen from above
			_r(img, 2, b - 12, pw - 4, 1, c.lightened(0.22))
			_r(img, 2, b - 7, pw - 4, 2, c.darkened(0.3))                    # its front edge
			_r(img, 3, b - 5, 2, 5, Color(0.15, 0.14, 0.15))
			_r(img, pw - 5, b - 5, 2, 5, Color(0.15, 0.14, 0.15))
			if fc == 3:
				_r(img, 1, b - 24, 3, 19, c.darkened(0.3))
				_r(img, 1, b - 24, 3, 1, c.lightened(0.12))
			elif fc == 2:
				_r(img, pw - 4, b - 24, 3, 19, c.darkened(0.3))
				_r(img, pw - 4, b - 24, 3, 1, c.lightened(0.12))
		"stool":
			var b2 := fy + ph
			_r(img, pw / 2 - 1, b2 - 9, 2, 8, Color(0.2, 0.2, 0.22))
			_r(img, pw / 2 - 4, b2 - 3, 8, 1, Color(0.3, 0.3, 0.33))           # the foot ring
			_ellipse(img, pw * 0.5, b2 - 10, 5.5, 3, c.darkened(0.15))
			_ellipse(img, pw * 0.5, b2 - 11, 4.5, 2, c.lightened(0.15))
		"bar_counter":            # horizontal: a long counter, glasses on top
			_r(img, 0, fy - 4, pw, ph - 2, wood.darkened(0.05))
			_r(img, 0, fy - 4, pw, 3, wood.lightened(0.25))
			_r(img, 0, fy + ph - 9, pw, 6, wood.darkened(0.35))
			_r(img, 0, fy + ph - 3, pw, 1, wood.darkened(0.6))
			for k in int(pw / 7):
				_r(img, 3 + k * 7, fy - 3, 2, 3, Color(0.75, 0.9, 1.0))
		"counter_v":              # running down the room: the top and the face towards the left
			_r(img, 0, fy - 6, pw, ph, wood.lightened(0.05))
			_r(img, 0, fy - 6, pw, 2, wood.lightened(0.3))
			_r(img, 0, fy - 6, 4, ph, wood.darkened(0.3))
			_r(img, 0, fy + ph - 8, pw, 8, wood.darkened(0.35))
			for k in int(ph / 10):
				_r(img, pw - 7, fy - 2 + k * 10, 2, 3, Color(0.75, 0.9, 1.0))
		"counter":
			_r(img, 0, fy - 4, pw, ph - 2, metal.darkened(0.05))
			_r(img, 0, fy - 4, pw, 3, metal.lightened(0.25))
			_r(img, 0, fy + ph - 9, pw, 6, metal.darkened(0.35))
			_r(img, 0, fy + ph - 9, pw, 1, c)
		"crates":
			for k in int(pw / 10):
				var cc := Color(0.5, 0.36, 0.2) if k % 2 == 0 else Color(0.4, 0.42, 0.46)
				_r(img, 1 + k * 10, fy - 6, 9, ph + 4, cc)
				_r(img, 1 + k * 10, fy - 6, 9, 3, cc.lightened(0.25))
				_r(img, 1 + k * 10, fy + 2, 9, 1, cc.darkened(0.3))
		"plant":
			_r(img, pw / 2 - 5, fy + ph - 9, 10, 8, Color(0.55, 0.35, 0.25))
			_r(img, pw / 2 - 5, fy + ph - 9, 10, 2, Color(0.7, 0.48, 0.35))
			for k in 14:
				var lx := pw / 2 - 7 + int(GroundMap.hash2(k, int(o["x"])) * 14)
				var ly := fy + ph - 12 - int(GroundMap.hash2(k, int(o["y"]), 3) * 22)
				var lc := Color(0.2, 0.55 + 0.25 * GroundMap.hash2(k, 5), 0.25)
				_r(img, lx, ly, 3, 4, lc)
				_p(img, lx + 1, ly, lc.lightened(0.3))
		"terminal":
			_r(img, pw / 2 - 6, fy - 14, 12, ph + 10, Color(0.16, 0.17, 0.21))
			_r(img, pw / 2 - 5, fy - 13, 10, 9, c.darkened(0.2))
			_r(img, pw / 2 - 4, fy - 12, 6, 1, c.lightened(0.5))
			_r(img, pw / 2 - 4, fy - 9, 8, 1, c.lightened(0.2))
			_r(img, pw / 2 - 6, fy + ph - 4, 12, 2, Color(0.1, 0.1, 0.12))
			if o.has("icon"):
				var ic: Texture2D = PixelArt.icon_texture(String(o["icon"]))
				if ic != null:
					var im: Image = ic.get_image()
					im.convert(Image.FORMAT_RGBA8)
					var s := maxi(1, 8 / maxi(im.get_width(), 1))
					for yy in mini(im.get_height(), 8):
						for xx in mini(im.get_width(), 8):
							var pc := im.get_pixel(xx, yy)
							if pc.a > 0.3:
								_p(img, pw / 2 - 4 + xx, fy - 12 + yy, pc)
		"bench":
			var b3 := fy + ph
			if int(o.get("face", 0)) == 0:
				_r(img, 1, b3 - 22, pw - 2, 11, c.darkened(0.35))           # the backrest behind
				_r(img, 1, b3 - 22, pw - 2, 1, c.lightened(0.1))
			_r(img, 1, b3 - 12, pw - 2, 5, metal.lightened(0.05))              # the seat
			_r(img, 1, b3 - 12, pw - 2, 1, metal.lightened(0.3))
			_r(img, 1, b3 - 7, pw - 2, 2, metal.darkened(0.3))
			_r(img, 2, b3 - 5, 2, 5, Color(0.15, 0.15, 0.17))
			_r(img, pw - 4, b3 - 5, 2, 5, Color(0.15, 0.15, 0.17))
			if pw > 32:
				_r(img, pw / 2 - 1, b3 - 5, 2, 5, Color(0.15, 0.15, 0.17))
		"sofa":
			var b4 := fy + ph
			_r(img, 1, b4 - 24, pw - 2, 13, c.darkened(0.3))                    # the back
			_r(img, 1, b4 - 24, pw - 2, 2, c.darkened(0.15))
			_r(img, 3, b4 - 12, pw - 6, 6, c)                                     # the cushions
			_r(img, 3, b4 - 12, pw - 6, 1, c.lightened(0.2))
			for k in int(pw / 16):
				_r(img, 3 + k * 16 + 14, b4 - 12, 1, 6, c.darkened(0.2))
			_r(img, 1, b4 - 6, pw - 2, 3, c.darkened(0.35))
			_r(img, 0, b4 - 17, 3, 14, c.darkened(0.2))                            # the arms
			_r(img, pw - 3, b4 - 17, 3, 14, c.darkened(0.35))
			_r(img, 2, b4 - 3, 2, 3, Color(0.15, 0.12, 0.1))
			_r(img, pw - 4, b4 - 3, 2, 3, Color(0.15, 0.12, 0.1))
		"railing":
			_r(img, 0, fy + 2, pw, 2, metal.lightened(0.3))
			_r(img, 0, fy + 4, pw, 1, metal.darkened(0.3))
			for k in int(pw / 6) + 1:
				_r(img, mini(k * 6, pw - 2), fy + 4, 2, 9, metal.darkened(0.15))
			_r(img, 0, fy + 12, pw, 2, metal.darkened(0.35))
		"jukebox":
			_r(img, 2, fy - 14, pw - 4, ph + 10, Color(0.35, 0.12, 0.25))
			_ellipse(img, pw * 0.5, fy - 8, pw * 0.36, 7, c)
			_ellipse(img, pw * 0.5, fy - 8, pw * 0.24, 4, c.lightened(0.5))
			for k in 4:
				_r(img, 4, fy + k * 3, pw - 8, 1, Color(1.0, 0.75, 0.3))
		"display":
			_r(img, 1, fy - 14, pw - 2, ph + 12, Color(0.6, 0.75, 0.85, 0.5))
			_r(img, 1, fy - 14, pw - 2, 2, Color(0.85, 0.92, 1.0))
			_r(img, 1, fy + ph - 6, pw - 2, 6, metal.darkened(0.3))
			for k in int((pw - 4) / 6):
				_r(img, 3 + k * 6, fy - 6, 4, 4, c)
		"machine":
			_r(img, 1, fy - 8, pw - 2, ph + 6, Color(0.32, 0.29, 0.26))
			_r(img, 1, fy - 8, pw - 2, 3, Color(0.45, 0.4, 0.36))
			_r(img, 4, fy - 3, pw - 8, 3, Color(0.95, 0.55, 0.15))
			for k in int(pw / 8):
				_r(img, 3 + k * 8, fy + ph - 6, 4, 4, Color(0.15, 0.15, 0.15))
		"lamp_post":
			_r(img, pw / 2 - 1, fy - 12, 2, ph + 10, metal.darkened(0.3))
			_ellipse(img, pw * 0.5, fy - 14, 4, 3, c.lightened(0.4))
		"table_small":
			_r(img, 2, fy, pw - 4, ph - 6, wood.lightened(0.12))
			_r(img, 2, fy, pw - 4, 2, wood.lightened(0.3))
			_r(img, 2, fy + ph - 6, pw - 4, 3, wood.darkened(0.3))
			_r(img, pw / 2 - 1, fy + ph - 3, 2, 3, Color(0.15, 0.14, 0.15))
			_r(img, pw / 2 - 2, fy + 2, 2, 3, Color(0.95, 0.9, 0.8))
		"banner":
			_r(img, 2, fy - 22, 2, ph + 20, metal.darkened(0.4))
			_r(img, 4, fy - 20, pw - 5, 16, c.darkened(0.15))
			_r(img, 4, fy - 20, pw - 5, 2, c.lightened(0.2))
			_r(img, 6, fy - 15, pw - 9, 5, Color(0.95, 0.9, 0.7))
			_r(img, 1, fy + ph - 3, 5, 2, metal.darkened(0.5))
		"locker":
			_r(img, 1, fy - 18, pw - 2, ph + 16, metal.darkened(0.25))
			_r(img, 1, fy - 18, pw - 2, 2, metal.lightened(0.1))
			_r(img, pw / 2, fy - 16, 1, ph + 12, metal.darkened(0.5))
			for k in 3:
				_r(img, 3, fy - 15 + k * 3, pw / 2 - 4, 1, metal.darkened(0.45))
			_r(img, pw / 2 - 3, fy - 6, 2, 3, c)
		"holo_pillar":
			_r(img, pw / 2 - 5, fy + ph - 6, 10, 5, metal.darkened(0.35))
			_r(img, pw / 2 - 4, fy - 22, 8, ph + 16, Color(c, 0.35))
			_r(img, pw / 2 - 1, fy - 22, 2, ph + 16, Color(c.lightened(0.5), 0.6))
			for k in 4:
				_r(img, pw / 2 - 4, fy - 20 + k * 6, 8, 1, Color(c.lightened(0.4), 0.7))
		"tank":
			_r(img, 2, fy - 20, pw - 4, ph + 18, Color(0.55, 0.85, 0.8, 0.35))
			_r(img, 3, fy - 14, pw - 6, ph + 10, Color(0.2, 0.85, 0.55, 0.55))
			_ellipse(img, pw * 0.5, fy - 6, 3, 4, Color(0.75, 0.95, 0.6))
			_r(img, 1, fy - 21, pw - 2, 3, metal.darkened(0.3))
			_r(img, 1, fy + ph - 4, pw - 2, 4, metal.darkened(0.3))
			_r(img, 4, fy - 12, 1, 6, Color(1, 1, 1, 0.5))
		"pipes":
			for k in 3:
				var pc := metal.darkened(0.15 + 0.1 * k)
				_r(img, 1 + k * 5, fy - 22, 4, ph + 20, pc)
				_r(img, 1 + k * 5, fy - 22, 1, ph + 20, pc.lightened(0.25))
			_r(img, 0, fy - 8, pw, 3, metal.darkened(0.4))
			_ellipse(img, pw * 0.5, fy - 12, 3, 3, Color(0.85, 0.2, 0.15))
		"ore_cart":
			_r(img, 1, fy - 2, pw - 2, ph - 2, Color(0.4, 0.36, 0.32))
			_r(img, 1, fy - 2, pw - 2, 2, Color(0.55, 0.5, 0.45))
			for k in 6:
				_ellipse(img, 3 + GroundMap.hash2(k, 1) * (pw - 6), fy - 3 + GroundMap.hash2(k, 2) * 3, 2.5, 2, Color(0.55, 0.45, 0.35).lerp(c, 0.25 * GroundMap.hash2(k, 3)))
			_r(img, 2, fy + ph - 4, 3, 3, Color(0.12, 0.12, 0.12))
			_r(img, pw - 5, fy + ph - 4, 3, 3, Color(0.12, 0.12, 0.12))
		"barrel", "barrel_table":
			var bc := Color(0.45, 0.3, 0.16) if kind == "barrel_table" or int(o.get("x", 0)) % 2 == 0 else Color(0.35, 0.42, 0.5)
			_r(img, 2, fy - 6, pw - 4, ph + 3, bc)
			_r(img, 2, fy - 2, pw - 4, 1, bc.darkened(0.4))
			_r(img, 2, fy + ph - 6, pw - 4, 1, bc.darkened(0.4))
			_ellipse(img, pw * 0.5, fy - 6, (pw - 4) * 0.5, 3, bc.lightened(0.15))
			if kind == "barrel_table":
				_r(img, pw / 2 - 3, fy - 9, 2, 3, Color(0.95, 0.8, 0.3))
				_r(img, pw / 2 + 1, fy - 8, 2, 2, Color(0.6, 0.85, 1.0))
		"crate_seat":
			var b5 := fy + ph
			_r(img, 2, b5 - 13, pw - 4, 6, Color(0.62, 0.46, 0.28))              # the lid, from above
			_r(img, 2, b5 - 13, pw - 4, 1, Color(0.72, 0.56, 0.36))
			_r(img, 2, b5 - 7, pw - 4, 7, Color(0.5, 0.36, 0.2))
			_r(img, 2, b5 - 4, pw - 4, 1, Color(0.35, 0.24, 0.12))
			_r(img, 7, b5 - 7, 1, 7, Color(0.4, 0.28, 0.15))
		"pool_table":
			_r(img, 0, fy - 4, pw, ph - 2, Color(0.35, 0.2, 0.12))
			_r(img, 3, fy - 2, pw - 6, ph - 8, Color(0.1, 0.45, 0.25))
			for k in 6:
				_ellipse(img, 8 + GroundMap.hash2(k, 7) * (pw - 16), fy + 2 + GroundMap.hash2(k, 8) * (ph - 14), 1.5, 1.5,
					[Color(0.95, 0.95, 0.9), Color(0.9, 0.2, 0.2), Color(0.95, 0.8, 0.2), Color(0.2, 0.3, 0.9), Color(0.1, 0.1, 0.1), Color(0.9, 0.5, 0.1)][k])
			_r(img, 2, fy + ph - 6, 3, 6, Color(0.25, 0.14, 0.08))
			_r(img, pw - 5, fy + ph - 6, 3, 6, Color(0.25, 0.14, 0.08))
		"planter":
			_r(img, 0, fy, pw, ph - 2, Color(0.42, 0.3, 0.2))
			_r(img, 1, fy + 1, pw - 2, 4, Color(0.3, 0.2, 0.12))
			for k in int(pw / 4):
				var gx := 2 + k * 4
				var gh := 6 + int(GroundMap.hash2(k, int(o.get("x", 0))) * 8)
				_r(img, gx, fy + 2 - gh, 1, gh, Color(0.25, 0.6, 0.2))
				_r(img, gx - 1, fy + 2 - gh, 3, 3, Color(0.35, 0.75, 0.25) if k % 3 != 0 else Color(0.95, 0.8, 0.25))
		"ice_sculpture":
			_r(img, 3, fy + ph - 5, pw - 6, 4, Color(0.75, 0.8, 0.85))
			_ellipse(img, pw * 0.5, fy - 2, 5, 7, Color(0.75, 0.92, 1.0, 0.8))
			_ellipse(img, pw * 0.5 + 2, fy - 12, 2.5, 3, Color(0.8, 0.95, 1.0, 0.85))
			_r(img, pw / 2 + 1, fy - 10, 2, 6, Color(0.8, 0.95, 1.0, 0.85))
			_r(img, pw / 2 - 2, fy - 6, 1, 6, Color(1, 1, 1, 0.8))
		"heater":
			_r(img, 2, fy - 12, pw - 4, ph + 10, Color(0.25, 0.22, 0.2))
			for k in 4:
				_r(img, 4, fy - 9 + k * 4, pw - 8, 2, Color(1.0, 0.45 + 0.1 * k, 0.15))
		"engine_part":
			_r(img, 2, fy + ph - 5, pw - 4, 4, metal.darkened(0.4))
			_ellipse(img, pw * 0.5, fy - 2, pw * 0.42, 9, metal.darkened(0.15))
			_ellipse(img, pw * 0.5, fy - 2, pw * 0.3, 6, Color(0.15, 0.15, 0.18))
			_ellipse(img, pw * 0.5, fy - 2, pw * 0.15, 3, Color(0.4, 0.75, 1.0))
		"palm":
			for k in 8:
				_r(img, pw / 2 - 1 + (1 if k % 2 == 0 else 0), fy + ph - 4 - k * 4, 3, 4, Color(0.5, 0.36, 0.22).lightened(0.05 * (k % 2)))
			for a in 7:
				var ang := -PI + a * (PI / 6.0)
				for t in 9:
					_r(img, int(pw * 0.5 + cos(ang) * t * 1.2), int(fy - 28 + sin(ang) * t * 0.6 + t * 0.35 * absf(cos(ang))), 2, 2, Color(0.2, 0.6, 0.25).lightened(0.1 * (t % 2)))
			_r(img, pw / 2 - 5, fy + ph - 5, 10, 5, Color(0.6, 0.42, 0.3))
		"parasol":
			_r(img, pw / 2, fy - 22, 1, ph + 20, Color(0.85, 0.85, 0.8))
			_ellipse(img, pw * 0.5, fy - 22, pw * 0.48, 5, c)
			for k in 3:
				_r(img, int(pw * 0.5) - 6 + k * 5, fy - 25, 2, 5, Color(0.97, 0.95, 0.9))
		"lounger":
			var b6 := fy + ph
			_r(img, 2, b6 - 18, pw - 4, 7, Color(0.85, 0.82, 0.78))              # the raised back
			_r(img, 3, b6 - 17, pw - 6, 5, c.lightened(0.1))
			_r(img, 2, b6 - 11, pw - 4, 6, Color(0.92, 0.9, 0.85))               # the seat
			_r(img, 3, b6 - 10, pw - 6, 4, c)
			_r(img, 2, b6 - 5, pw - 4, 1, Color(0.6, 0.6, 0.6))
			_r(img, 3, b6 - 4, 1, 4, Color(0.6, 0.6, 0.6))
			_r(img, pw - 4, b6 - 4, 1, 4, Color(0.6, 0.6, 0.6))
		"fountain":
			_ellipse(img, pw * 0.5, fy + 4, pw * 0.48, 6, Color(0.75, 0.72, 0.65))
			_ellipse(img, pw * 0.5, fy + 3, pw * 0.4, 4, Color(0.35, 0.7, 0.9))
			_r(img, pw / 2 - 2, fy - 10, 4, 12, Color(0.75, 0.72, 0.65))
			_ellipse(img, pw * 0.5, fy - 11, 6, 2, Color(0.7, 0.9, 1.0, 0.8))
			_r(img, pw / 2 - 1, fy - 14, 2, 4, Color(0.8, 0.95, 1.0, 0.8))
		"flower_bed":
			_r(img, 0, fy, pw, ph - 2, Color(0.5, 0.4, 0.3))
			_r(img, 1, fy + 1, pw - 2, ph - 5, Color(0.3, 0.45, 0.2))
			for k in int(pw / 3):
				_r(img, 1 + k * 3, fy - 1 + (k % 2) * 3, 2, 2, [Color(1.0, 0.4, 0.5), Color(1.0, 0.85, 0.3), Color(0.7, 0.5, 1.0), Color(1, 1, 1)][k % 4])
		"trash":
			_ellipse(img, pw * 0.4, fy + 6, 5, 4, Color(0.18, 0.2, 0.18))
			_ellipse(img, pw * 0.65, fy + 8, 4, 3, Color(0.25, 0.22, 0.3))
			_r(img, 3, fy + 10, 3, 2, Color(0.8, 0.75, 0.3))
		"cage":
			_r(img, 1, fy - 18, pw - 2, 2, metal.darkened(0.3))
			_r(img, 1, fy + ph - 4, pw - 2, 3, metal.darkened(0.4))
			for k in 4:
				_r(img, 1 + k * 4, fy - 16, 1, ph + 12, metal.darkened(0.15))
			_ellipse(img, pw * 0.5, fy + 2, 3, 3, Color(0.85, 0.3, 0.2))
		"vending":
			_r(img, 1, fy - 18, pw - 2, ph + 16, Color(0.2, 0.22, 0.28))
			_r(img, 2, fy - 16, pw - 7, 14, c.darkened(0.1))
			for k in 3:
				_r(img, 3, fy - 15 + k * 4, pw - 9, 2, [Color(0.9, 0.3, 0.2), Color(0.3, 0.8, 0.4), Color(0.95, 0.8, 0.3)][k])
			_r(img, pw - 4, fy - 14, 2, 4, Color(0.95, 0.95, 0.5))
			_r(img, 2, fy + ph - 6, pw - 7, 3, Color(0.08, 0.08, 0.1))
		"bench_back":
			var b7 := fy + ph
			_r(img, 1, b7 - 12, pw - 2, 3, c.darkened(0.3))                # a rail at the small of the back: the sitters show above it
			_r(img, 1, b7 - 12, pw - 2, 1, c.lightened(0.15))
			_r(img, 1, b7 - 10, pw - 2, 1, c.darkened(0.5))
			_r(img, 3, b7 - 10, 2, 4, metal.darkened(0.4))
			_r(img, pw - 5, b7 - 10, 2, 4, metal.darkened(0.4))
		"fridge":
			_r(img, 2, fy - 14, pw - 4, ph + 12, Color(0.75, 0.8, 0.85))
			_r(img, 3, fy - 13, pw - 6, 10, Color(0.3, 0.6, 0.8, 0.8))
			for k in int((pw - 8) / 4):
				_r(img, 4 + k * 4, fy - 11, 2, 6, [Color(0.9, 0.3, 0.2), Color(0.3, 0.8, 0.4), Color(0.95, 0.8, 0.3)][k % 3])


static func _outline(img: Image) -> void:
	var src := img.duplicate()
	var iw := img.get_width()
	var ih := img.get_height()
	for y in ih:
		for x in iw:
			if src.get_pixel(x, y).a > 0.0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < iw and q.y < ih and src.get_pixel(q.x, q.y).a > 0.6:
					img.set_pixel(x, y, OUT)
					break
