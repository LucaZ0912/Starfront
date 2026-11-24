class_name ObjArt
extends RefCounted
## Package 49 (0.7.49.2): furniture in the slanted view – each piece its own picture: a top lit from above, a front
## face below it, standing on its footprint (w × h tiles) and rising `rise` art px above it. GroundView places it with
## its foot at the bottom of the footprint and sorts it by depth with the people.

const TILE := 16
const OUT := Color(0.09, 0.07, 0.11)

static var _cache := {}
const WildArtO = preload("res://scripts/ground/wild_art.gd")
const LabArtO = preload("res://scripts/ground/lab_art.gd")


## {image, rise} for an object.
static func make(o: Dictionary, pal: Dictionary) -> Dictionary:
	var key := "%s_%d_%d_%s_%s_%d_%d_%s_%s" % [o["kind"], int(o.get("w", 1)), int(o.get("h", 1)), str(o.get("col", "")), str(pal.get("wood", "")), int(o.get("face", 0)), int(o.get("x", 0)) % 4, str(o.get("col2", "")), str(o.get("win", "")) + str(o.get("seed", "")) + String(o.get("arch", "")) + String(o.get("species", "")) + str(o.get("patient", "")) + str(o.get("awake", "")) + str(o.get("no_balls", "")) + str(o.get("snow", ""))]
	if _cache.has(key):
		return _cache[key]
	var pw := int(o.get("w", 1)) * TILE
	var ph := int(o.get("h", 1)) * TILE
	var rise := _rise(String(o["kind"]))
	if o.has("rise"):
		rise = int(o["rise"])                       # 0.7.50.11: buildings and trees of their own height
	var img := Image.create(pw, ph + rise, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c: Color = o.get("col", pal.get("accent", Color(0.4, 0.8, 1.0)))
	var wood: Color = pal.get("wood", Color(0.42, 0.26, 0.14))
	var metal: Color = pal.get("wall", Color(0.6, 0.62, 0.68))
	if String(o["kind"]) == "building":
		BuildArt.paint(img, o, pw, ph + rise)
	elif String(o["kind"]) in LabArtO.OBJ_KINDS:
		LabArtO.paint_obj(o, img)                    # 62a part 11a: the Alien Laboratory's furniture
	elif String(o["kind"]) in WildArtO.OBJ_KINDS:
		WildArtO.paint_obj(o, img)                   # 53f-2 (Luz): trees, palms, trunks, ice, the crashed drone
	else:
		_paint(img, String(o["kind"]), pw, ph, rise, c, wood, metal, o)
	if bool(o.get("snow", false)):
		_snow(img)                                   # 62a part 9 (Whiteout): snowed in
	if not String(o["kind"]) in ["holo_ship", "holo_statue", "scanner_gate", "sphere_holo"]:
		_outline(img)                                # 0.7.53.27: a hologram has no outline
	var out := {"image": img, "rise": rise}
	_cache[key] = out
	return out


static func _rise(kind: String) -> int:
	match kind:
		"tree":
			return 46
		"shrub":
			return 8
		"smokestack":
			return 64
		"flare":
			return 56
		"lookout":
			return 54
		"heap":
			return 16
		"fence":
			return 10
		"target", "tank_vehicle":
			return 14
		"stall":
			return 22
		"rover":
			return 10
		"signpost", "cable_pole":
			return 30
		"tower_rig":
			return 70
		"silo":
			return 44
		"house":
			return 30
		"dish":
			return 34
		"crystal":
			return 22
		"dart_board":                         # 54b: a dartboard on its stand
			return 30
		"arcade":                             # 54b: an arcade cabinet
			return 26
		"greenhouse":
			return 20
		"rock", "lava_rock":
			return 10
		"pillar_fallen":
			return 9
		"slab":
			return 8
		"pipe_bundle", "weapon_crate":        # 0.7.53.3: the sewer's and the hideout's low cover
			return 9
		"container":                          # 0.7.53.6: a 6 m cargo container (2.6 m tall)
			return 30
		"watchtower":                         # 0.7.53.11: a pirates' watchtower on stilts (~8 m)
			return 110
		"glider":                             # 0.7.53.11: a pirate glider, parked
			return 12
		"fire_barrel":                        # 0.7.53.11: a barrel with a fire in it
			return 14
		"valve_box":                          # 0.7.53.9: a big valve housing – high cover
			return 24
		"cable_drum":                         # 0.7.53.9: a cable drum – low cover
			return 10
		"shaft_house":                        # 0.7.53.7: the shaft house with its headframe over it (~22 m)
			return 170
		"winding_house":
			return 50
		"ore_bin":
			return 60
		"locker_down", "seats":               # 0.7.53.6: a ship's lockers fallen over, a row of seats – low cover
			return 10
		"pump":                               # 0.7.53.3: a big pump – high cover
			return 26
		"dune":
			return 6
		"palm":
			return 34
		"parasol":
			return 28
		"banner", "holo_pillar", "pipes":
			return 24
		"tank", "ice_sculpture", "cage", "vending", "locker":
			return 20
		"fountain":
			return 16                           # (its jet inside the picture)
		"engine_part", "heater", "planter":
			return 14
		"barrel", "barrel_table", "ore_cart":
			return 12                           # (the lid and what stands on it inside the picture)
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
		"chair", "chair_back", "bench", "bench_back":
			return 12
		"sofa", "sofa_back":
			return 14
		"stool", "railing":
			return 6
		"med_bed", "med_bed_occ", "q_bed":
			return 14
		"med_pod":
			return 44
		"sculpt_chair":
			return 26
		"holo_bust":
			return 30
		"med_cabinet":
			return 30
		"office_desk", "partition":         # 0.7.53.19 (Luz): an office desk with its screen, a low screen – low cover
			return 12
		"lab_bench":                        # 0.7.53.20 (Luz): a lab bench – low cover
			return 12
		"obelisk", "bones", "altar":        # 0.7.53.23 (Luz): a fallen obelisk, bones of something vast, an altar – low cover
			return 12
		"obelisk_stand":                    # 0.7.53.23: an obelisk still standing – high cover
			return 52
		"cryo_tank", "sample_cabinet":      # 0.7.53.20: a cryo tank, a sample cabinet – high cover
			return 34
		"dome":                             # 0.7.53.20: a station's dome (a greenhouse)
			return 46
		"radio_mast":                       # 0.7.53.20: its radio mast (~12 m)
			return 170
		"crawler":                          # 0.7.53.20: a snow crawler (~6 m)
			return 30
		"server_rack":                      # 0.7.53.19: a server cabinet (~2.2 m) – high cover
			return 30
		"computer_wall":                    # package 58, part 7: the relay's wall of computers (~2.6 m)
			return 40
		"pillar_corp":                      # 0.7.53.19: a lobby's square pillar up to the ceiling – high cover
			return 44
		"glass_rail":                       # 0.7.53.19: the roof plaza's glass balustrade
			return 12
		"lift_tank":                        # 0.7.54.3: a lift tank hanging under the deck (as cover)
			return 60
		"rotor_ring":                       # 0.7.54.3: an antigrav rotor's ring set in the walkway
			return 8
		"lantern":                          # 0.7.54.3: the Covenant's lantern on its post
			return 56
		"gas_tank":                         # 0.7.54.2: a spherical gas tank on its legs (~5 m)
			return 64
		"compressor":                       # 0.7.54.2: a compressor block with fans on top
			return 26
		"gas_column":                       # 0.7.54.2: a separation column going up out of the picture
			return 220
		"gas_flare":                        # 0.7.54.2: the flare stack burning off what is left
			return 110
		"winch":                            # 0.7.54.2: an intake's winch at the edge
			return 18
		"scope":                            # package 54: a viewing scope on the observation deck (~1.4 m)
			return 22
		"car_pole":                         # package 54: a grab pole in the skyrail's car (floor to ceiling)
			return 34
		"statue":                           # 53e (Luz): the Museum's statues – a figure of pale stone on a pedestal
			return 44
		"statue_precursor":                 # 53e: a Precursor in iron-stone, tall and thin
			return 50
		"bust":
			return 30
		"column":                           # 53e: a column of the Museum's portico (~3.3 m)
			return 50
		"curator_desk":                     # 53e: the curator's counter (0.7.53.27: its top seen from above)
			return 30
		"museum_bench", "rope", "m_rail":
			return 8
		"globe":
			return 24
		"geode_big":
			return 26
		"ship_model":
			return 24
		"poster":
			return 26
		"holo_ship":                        # 0.7.53.27 (Luz): a hologram of a mining ship over its projector
			return 34
		"skull_cast":
			return 16
		"idol_cast":
			return 40
		"pylon":                            # 54c: a pylon of the Senate's front (~3.3 m)
			return 50
		"holo_statue":                      # 54c: a founder as a hologram
			return 40
		"scanner_gate":                     # 54c: the Senate's security arch (~2.6 m)
			return 30
		"throne_small":                     # 54c (Luz): the Hierarch's throne at a man's size
			return 34
		"baldachin":                        # 54c: the canopy over the throne (~5 m)
			return 64
		"regalia_table":
			return 10
		"kneeler":
			return 2
		"font":
			return 14
		"lectern":
			return 22
		"console_row":                      # 54c: a tier of consoles in the control room (~1.2 m)
			return 12
		"sphere_holo":                      # 54c: the Dyson sphere as a holo (~2 m)
			return 26
		"altar_cov":                        # 54c: the Cathedral's altar (~1.1 m)
			return 16
		"vote_booth":                       # 54c: a voting booth at The Vote (~2.4 m)
			return 30
		"brazier":                          # 54c: a fire bowl on a post (~1.5 m)
			return 22
		"tithe_chest":
			return 8
		"reliquary":                        # 54c: the relic shrine (~2.6 m)
			return 36
		"candle_rack":
			return 10
		"throne":                           # 54c: the Hierarch's throne (~3 m high back)
			return 40
		"candelabrum":                      # 54c: ~2.4 m
			return 30
		"plaque_stone":                     # 54c: a stone with a bronze plaque (~0.9 m)
			return 10
		"news_wall":                        # 54c: a news screen in the lobby
			return 26
		"tank_trap":                # 62a, part 8: a tank trap (~1.4 m), a heap of rubble, a burnt-out car, a landing ship's wreck
			return 12
		"rubble":
			return 10
		"wreck_car":
			return 12
		"dropship_wreck":
			return 52
		"barrier":                  # package 52: cover – a low plated barricade (~1.3 m) and a high bulwark (~2.6 m)
			return 8
		"bulwark":
			return 30
	return 6


static func _hn(a: int, b: int) -> float:
	var v := sin(float(a) * 12.9898 + float(b) * 78.233) * 43758.5453
	return v - floor(v)


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
		"statue", "statue_precursor":
			# 53e (Luz): a statue a little larger than life on a pedestal of pale stone
			var stn := Color(0.86, 0.86, 0.88)
			var pb := fy + ph
			_r(img, 1, pb - 12, pw - 2, 12, stn.darkened(0.1))
			_r(img, 1, pb - 12, pw - 2, 2, stn.lightened(0.1))
			_r(img, 0, pb - 14, pw, 2, stn)
			_r(img, pw / 2 - 5, pb - 7, 10, 2, stn.darkened(0.35))
			var top := pb - 14
			if kind == "statue":
				var lrng := RandomNumberGenerator.new()
				lrng.seed = 900 + int(o.get("seed", 1))
				var lk: Dictionary = ChibiArt.PilotArt.random_look(lrng)
				lk["suit"] = String(o.get("species", "suit_civil"))
				lk["helmet"] = false
				var fig: Image = ChibiArt.frame(lk, 0, 0).get_image()
				fig.resize(14, 32, Image.INTERPOLATE_NEAREST)
				for yy in fig.get_height():
					for xx in fig.get_width():
						var fc := fig.get_pixel(xx, yy)
						if fc.a > 0.0:
							var lum := fc.get_luminance()
							_p(img, pw / 2 - 7 + xx, top - 32 + yy, Color(0.62, 0.62, 0.64).lerp(Color(0.97, 0.97, 0.98), clampf(lum * 1.2, 0.0, 1.0)))
			else:
				var ps := Color(0.62, 0.5, 0.42)                      # weathered iron-stone, crystal inlays
				var cx := pw / 2
				_ellipse(img, cx, top - 34, 3.5, 5.5, ps.lightened(0.1))
				_r(img, cx - 1, top - 29, 3, 3, ps.darkened(0.1))
				_r(img, cx - 4, top - 26, 9, 14, ps)
				_r(img, cx - 4, top - 26, 2, 14, ps.lightened(0.15))
				_r(img, cx - 7, top - 25, 2, 18, ps.darkened(0.15))
				_r(img, cx + 6, top - 25, 2, 18, ps.darkened(0.2))
				_r(img, cx - 3, top - 12, 3, 12, ps)
				_r(img, cx + 1, top - 12, 3, 12, ps.darkened(0.1))
				_r(img, cx - 2, top - 22, 5, 1, Color(0.7, 0.55, 1.0))
				_p(img, cx, top - 36, Color(0.7, 0.55, 1.0))
		"pylon":
			# 54c (Luz: more sci-fi): a pylon of the Senate's front – white composite, slimmer in its waist, a blue
			# light in its groove, a lit cap
			var pb3 := fy + ph
			for yy in range(2, pb3):
				var t := float(yy) / pb3
				var hw := int(5.0 - sin(t * PI) * 1.5)
				_r(img, pw / 2 - hw, yy, hw * 2, 1, Color(0.9, 0.91, 0.94))
				_p(img, pw / 2 - hw, yy, Color(1, 1, 1))
				_p(img, pw / 2 + hw - 1, yy, Color(0.68, 0.7, 0.75))
			_r(img, pw / 2 - 1, 6, 2, pb3 - 12, Color(0.4, 0.82, 1.0))
			_r(img, pw / 2, 6, 1, pb3 - 12, Color(0.8, 0.97, 1.0))
			_r(img, pw / 2 - 6, 0, 12, 3, Color(0.95, 0.96, 0.98))
			_r(img, pw / 2 - 5, 3, 10, 1, Color(0.45, 0.85, 1.0))
			_r(img, pw / 2 - 7, pb3 - 4, 14, 4, Color(0.62, 0.64, 0.68))
			_r(img, pw / 2 - 6, pb3 - 4, 12, 1, Color(0.45, 0.85, 1.0))
		"holo_statue":
			# 54c (Luz: more sci-fi): a founder as a hologram, larger than life, over a dark projector disc
			var hb2 := fy + ph
			_ellipse(img, pw * 0.5, hb2 - 5, pw * 0.42, 4.5, Color(0.16, 0.17, 0.2))
			_ellipse(img, pw * 0.5, hb2 - 6, pw * 0.36, 3.0, Color(0.26, 0.28, 0.32))
			_ellipse(img, pw * 0.5, hb2 - 6, pw * 0.26, 1.8, Color(0.45, 0.9, 1.0))
			var lrng2 := RandomNumberGenerator.new()
			lrng2.seed = 900 + int(o.get("seed", 1))
			var lk2: Dictionary = ChibiArt.PilotArt.random_look(lrng2)
			lk2["suit"] = String(o.get("species", "suit_civil"))
			lk2["helmet"] = false
			var fig2: Image = ChibiArt.frame(lk2, 0, 0).get_image()
			fig2.resize(16, 36, Image.INTERPOLATE_NEAREST)
			var top2 := hb2 - 8
			for yy2 in fig2.get_height():
				for xx2 in fig2.get_width():
					var fc2 := fig2.get_pixel(xx2, yy2)
					if fc2.a > 0.0:
						var hcol := Color(0.3, 0.7, 1.0).lerp(Color(0.85, 1.0, 1.0), clampf(fc2.get_luminance() * 1.3, 0.0, 1.0))
						hcol.a = 0.8 if (top2 - 36 + yy2) % 3 != 0 else 0.45
						_p(img, pw / 2 - 8 + xx2, top2 - 36 + yy2, hcol)
			for cy3 in range(top2 - 36, top2):
				var spread2 := int(float(cy3 - (top2 - 36)) / 36.0 * 3.0)
				_p(img, pw / 2 - 10 - spread2, cy3, Color(0.45, 0.9, 1.0, 0.18))
				_p(img, pw / 2 + 9 + spread2, cy3, Color(0.45, 0.9, 1.0, 0.18))
		"scanner_gate":
			# 54c: the Senate's security arch – two posts and a beam of grey composite, a light field between them
			var gb := fy + ph
			_r(img, 0, 2, 4, gb - 2, Color(0.55, 0.57, 0.62))
			_r(img, pw - 4, 2, 4, gb - 2, Color(0.48, 0.5, 0.55))
			_r(img, 0, 0, pw, 5, Color(0.62, 0.64, 0.68))
			_r(img, 0, 0, pw, 1, Color(0.85, 0.87, 0.9))
			_r(img, 3, 6, 1, gb - 8, Color(0.4, 1.0, 0.6))
			_r(img, pw - 4, 6, 1, gb - 8, Color(0.4, 1.0, 0.6))
			_r(img, pw / 2 - 3, 2, 6, 1, Color(0.4, 1.0, 0.6))
			for yy4 in range(6, gb - 2):
				_r(img, 4, yy4, pw - 8, 1, Color(0.4, 1.0, 0.6, 0.07 if yy4 % 4 else 0.18))
		"throne_small":
			# 54c (Luz): the Hierarch's throne at a man's size – a tall carved back of gilded wood, the sun on its crown, a
			# crimson cushion and back panel with a gold border, carved arms ending in lions' heads, a footstool
			var b30 := fy + ph
			var gd := Color(0.88, 0.68, 0.3)
			var gdd := Color(0.62, 0.45, 0.18)
			_r(img, 4, 6, pw - 8, b30 - 10, gdd)                                 # the back's frame
			_r(img, 5, 7, pw - 10, b30 - 12, gd)
			_r(img, 8, 10, pw - 16, b30 - 22, Color(0.62, 0.12, 0.12))           # the crimson back panel
			_r(img, 8, 10, 1, b30 - 22, Color(0.75, 0.22, 0.2))
			for st in range(12, b30 - 14, 4):
				_p(img, pw / 2, st, gd)                                            # a stitched line of gold
			_ellipse(img, pw * 0.5, 5, 6, 5, gd)                                 # the sun on its crown, rays
			_ellipse(img, pw * 0.5, 5, 3.5, 3, Color(1.0, 0.92, 0.65))
			for ry in 8:
				var a := ry * TAU / 8.0
				_p(img, int(pw * 0.5 + cos(a) * 7.5), int(5 + sin(a) * 6.0), gd)
			_r(img, 6, 6, 2, 3, gd)                                               # finials on its corners
			_r(img, pw - 8, 6, 2, 3, gd)
			_r(img, 2, b30 - 14, 7, 9, gd)                                        # the arms, lions' heads at their ends
			_r(img, pw - 9, b30 - 14, 7, 9, gd)
			_r(img, 2, b30 - 14, 7, 1, Color(1.0, 0.85, 0.5))
			_r(img, pw - 9, b30 - 14, 7, 1, Color(1.0, 0.85, 0.5))
			_ellipse(img, 4, b30 - 6, 2.5, 2, gdd)
			_ellipse(img, pw - 5, b30 - 6, 2.5, 2, gdd)
			_r(img, 8, b30 - 12, pw - 16, 5, Color(0.7, 0.15, 0.15))             # the cushion
			_r(img, 8, b30 - 12, pw - 16, 1, Color(0.85, 0.3, 0.25))
			_r(img, 7, b30 - 7, pw - 14, 5, gdd)                                  # the seat's front, carved
			for cv in range(8, pw - 8, 3):
				_p(img, cv, b30 - 5, gd)
			_r(img, 9, b30 - 2, pw - 18, 2, Color(0.55, 0.12, 0.12))             # the footstool
		"baldachin":
			# 54c: the canopy over the throne – four gilded posts, a crimson valance with a gold fringe and the sun on it
			var b31 := fy + ph
			var gd2 := Color(0.88, 0.68, 0.3)
			for pp in [1, pw - 4]:
				_r(img, pp, 10, 3, b31 - 10, gd2.darkened(0.15))
				_r(img, pp, 10, 1, b31 - 10, Color(1.0, 0.85, 0.5))
				_ellipse(img, pp + 1.5, 9, 2.5, 2.5, gd2)
			_r(img, 0, 0, pw, 4, Color(0.62, 0.12, 0.12))                         # the canopy's top, seen from above
			_r(img, 0, 0, pw, 1, Color(0.8, 0.25, 0.2))
			_r(img, 0, 4, pw, 7, Color(0.55, 0.1, 0.1))                          # the valance
			for fr in range(0, pw, 2):
				_r(img, fr, 11, 1, 2 + (fr / 2) % 2, gd2)                         # the fringe
			_r(img, 0, 4, pw, 1, gd2)
			_ellipse(img, pw * 0.5, 7, 3, 2.5, gd2)
		"regalia_table":
			# 54c: a small table draped in crimson, the regalia on it – the crown, the sceptre, the orb
			var b32 := fy + ph
			var gd3 := Color(0.88, 0.68, 0.3)
			_r(img, 1, b32 - 12, pw - 2, 12, Color(0.55, 0.1, 0.1))
			_r(img, 1, b32 - 12, pw - 2, 2, Color(0.75, 0.2, 0.18))
			_r(img, 1, b32 - 3, pw - 2, 1, gd3)
			_r(img, 3, b32 - 16, 6, 3, gd3)                                       # the crown
			_p(img, 3, b32 - 17, gd3)
			_p(img, 6, b32 - 18, gd3)
			_p(img, 8, b32 - 17, gd3)
			_p(img, 5, b32 - 15, Color(0.8, 0.15, 0.2))
			_r(img, 11, b32 - 20, 1, 8, gd3)                                      # the sceptre
			_ellipse(img, 11.5, b32 - 21, 1.5, 1.5, Color(1.0, 0.9, 0.6))
			_ellipse(img, 13.5, b32 - 14, 2, 2, gd3)                              # the orb
		"kneeler":
			# 54c: a crimson kneeler with gold tassels before the throne
			_r(img, 2, fy + 3, pw - 4, ph - 7, Color(0.62, 0.12, 0.12))
			_r(img, 2, fy + 3, pw - 4, 2, Color(0.8, 0.25, 0.2))
			_r(img, 2, fy + ph - 5, pw - 4, 1, Color(0.88, 0.68, 0.3))
			_p(img, 2, fy + ph - 3, Color(0.88, 0.68, 0.3))
			_p(img, pw - 3, fy + ph - 3, Color(0.88, 0.68, 0.3))
		"font":
			# 54c: a font of blessed water at the doors – a stone basin on a pedestal, the water lit
			var b33 := fy + ph
			_r(img, pw / 2 - 2, b33 - 10, 4, 10, Color(0.8, 0.74, 0.64))
			_ellipse(img, pw * 0.5, b33 - 12, 7, 3.5, Color(0.86, 0.8, 0.7))
			_ellipse(img, pw * 0.5, b33 - 12.5, 5, 2.2, Color(0.45, 0.7, 0.85))
			_p(img, pw / 2 - 2, b33 - 13, Color(0.85, 0.95, 1.0))
			_r(img, pw / 2 - 4, b33 - 2, 8, 2, Color(0.7, 0.64, 0.54))
		"lectern":
			# 54c: a lectern of dark wood, the Book of Return open on it, a gold ribbon
			var b34 := fy + ph
			_r(img, pw / 2 - 1, b34 - 12, 3, 12, Color(0.4, 0.26, 0.15))
			_r(img, pw / 2 - 4, b34 - 2, 9, 2, Color(0.35, 0.22, 0.12))
			_r(img, 2, b34 - 20, pw - 4, 8, Color(0.45, 0.3, 0.17))
			_r(img, 3, b34 - 20, pw - 6, 6, Color(0.95, 0.9, 0.78))
			_r(img, pw / 2, b34 - 20, 1, 6, Color(0.7, 0.62, 0.5))
			for ln2 in 2:
				_r(img, 4, b34 - 18 + ln2 * 2, 3, 1, Color(0.5, 0.4, 0.3))
				_r(img, pw / 2 + 2, b34 - 18 + ln2 * 2, 3, 1, Color(0.5, 0.4, 0.3))
			_r(img, pw / 2, b34 - 14, 1, 4, Color(0.88, 0.68, 0.3))
		"console_row":
			# 54c (Luz): a tier of consoles facing the window – a dark desk with a green edge, screens in a row
			var b42 := fy + ph
			_r(img, 0, b42 - 10, pw, 10, Color(0.22, 0.25, 0.28))
			_r(img, 0, b42 - 10, pw, 2, Color(0.4, 1.0, 0.6))
			_r(img, 0, b42 - 2, pw, 2, Color(0.12, 0.14, 0.16))
			var si := 0
			for sx2 in range(4, pw - 12, 16):
				# the screens face the window (and the technicians): we see their backs, their glow round the edges
				var gcol: Color = [Color(0.25, 0.7, 0.45), Color(0.8, 0.55, 0.25), Color(0.3, 0.6, 0.85)][si % 3]
				_r(img, sx2 - 1, b42 - 23, 14, 1, Color(gcol, 0.6))
				_r(img, sx2, b42 - 22, 12, 10, Color(0.16, 0.18, 0.2))
				_r(img, sx2, b42 - 22, 12, 1, Color(0.3, 0.32, 0.36))
				_r(img, sx2 + 5, b42 - 12, 2, 2, Color(0.12, 0.13, 0.15))
				si += 1
		"sphere_holo":
			# 54c: the sphere as a holo over its projector – rings of green light round a small bright star
			var b43 := fy + ph
			_ellipse(img, pw * 0.5, b43 - 4, pw * 0.4, 3, Color(0.2, 0.22, 0.25))
			_ellipse(img, pw * 0.5, b43 - 5, 3, 1.5, Color(0.5, 1.0, 0.7))
			var hc2 := Vector2(pw * 0.5, b43 - 22)
			for rg in 3:
				for t2 in 60:
					var a5 := t2 * TAU / 60.0
					var q5 := hc2 + Vector2(cos(a5) * 13.0, sin(a5) * 13.0 * (0.3 + rg * 0.3)).rotated(rg * 0.6)
					_p(img, int(q5.x), int(q5.y), Color(0.5, 1.0, 0.7, 0.75))
			_ellipse(img, hc2.x, hc2.y, 3.5, 3.5, Color(0.9, 0.95, 1.0))
		"altar_cov":
			# 54c: the altar of the Cathedral of Return – white stone, a gold border, the sun of the Return on its front, a
			# white cloth with candles on it
			var b41 := fy + ph
			_r(img, 1, b41 - 16, pw - 2, 16, Color(0.92, 0.88, 0.8))
			_r(img, 1, b41 - 16, pw - 2, 2, Color(1, 1, 1))
			_r(img, 1, b41 - 3, pw - 2, 3, Color(0.7, 0.64, 0.54))
			_r(img, 3, b41 - 14, pw - 6, 1, Color(0.88, 0.68, 0.3))
			_ellipse(img, pw * 0.5, b41 - 8, 5, 4, Color(0.88, 0.68, 0.3))
			_ellipse(img, pw * 0.5, b41 - 8, 3, 2.5, Color(1.0, 0.9, 0.6))
			_r(img, 4, b41 - 22, pw - 8, 6, Color(0.96, 0.95, 0.92))
			_r(img, 4, b41 - 22, pw - 8, 1, Color(1, 1, 1))
			for cnd in range(8, pw - 8, 10):
				_r(img, cnd, b41 - 28, 2, 6, Color(0.95, 0.92, 0.85))
				_r(img, cnd, b41 - 30, 2, 2, Color(1.0, 0.8, 0.4))
		"vote_booth":
			# 54c (Luz): a voting booth of frosted glass at The Vote – a blue frame, the screen inside, a curtain of light
			var b40 := fy + ph
			_r(img, 0, 2, pw, b40 - 2, Color(0.7, 0.78, 0.9, 0.55))
			_r(img, 0, 0, pw, 3, Color(0.4, 0.68, 1.0))
			_r(img, 0, 0, 2, b40, Color(0.62, 0.66, 0.74))
			_r(img, pw - 2, 0, 2, b40, Color(0.5, 0.54, 0.62))
			_r(img, pw / 2 - 8, 10, 16, 10, Color(0.08, 0.14, 0.3))
			_r(img, pw / 2 - 7, 11, 14, 8, Color(0.25, 0.5, 0.95))
			_r(img, pw / 2 - 5, 13, 4, 4, Color(0.4, 1.0, 0.6))
			_r(img, pw / 2 + 1, 13, 4, 4, Color(1.0, 0.4, 0.4))
			_r(img, pw / 2 - 1, 20, 2, b40 - 22, Color(0.5, 0.54, 0.62))
			_r(img, 2, b40 - 3, pw - 4, 1, Color(0.4, 0.68, 1.0, 0.8))
		"brazier":
			# 54c: a fire bowl on a post (~1.5 m) – iron, a bowl of bronze, the flame
			var b20 := fy + ph
			_ellipse(img, pw * 0.5, b20 - 3, 5, 2.5, Color(0.25, 0.2, 0.16))
			_r(img, pw / 2 - 1, 8, 3, b20 - 10, Color(0.3, 0.24, 0.18))
			_ellipse(img, pw * 0.5, 8, 7, 3.5, Color(0.55, 0.4, 0.18))
			_ellipse(img, pw * 0.5, 7, 5, 2.2, Color(1.0, 0.65, 0.25))
			_ellipse(img, pw * 0.5, 4, 3, 3, Color(1.0, 0.85, 0.45))
			_r(img, pw / 2 - 1, 0, 2, 3, Color(1.0, 0.95, 0.7))
		"tithe_chest":
			# 54c: the tithe chest – dark wood bound in gold, a slot in its lid
			var b21 := fy + ph
			_r(img, 1, b21 - 14, pw - 2, 14, Color(0.42, 0.27, 0.15))
			_r(img, 1, b21 - 16, pw - 2, 4, Color(0.55, 0.36, 0.2))
			_r(img, 1, b21 - 12, pw - 2, 2, Color(0.88, 0.68, 0.3))
			_r(img, pw / 2 - 3, b21 - 16, 6, 1, Color(0.1, 0.08, 0.06))
			_r(img, pw / 2 - 1, b21 - 9, 2, 3, Color(0.88, 0.68, 0.3))
		"reliquary":
			# 54c: the relic office's shrine against the wall – gilded, glass panes, the relics glowing within
			var b22 := fy + ph
			_r(img, 0, b22 - 34, pw, 34, Color(0.55, 0.4, 0.2))
			_r(img, 2, b22 - 40, pw - 4, 8, Color(0.88, 0.68, 0.3))
			for gx2 in range(6, pw - 8, 14):
				_r(img, gx2, b22 - 30, 10, 18, Color(1.0, 0.9, 0.55, 0.9))
				_r(img, gx2 + 3, b22 - 24, 4, 8, Color(0.85, 0.75, 0.6))
			_r(img, 0, b22 - 8, pw, 8, Color(0.42, 0.27, 0.15))
			_r(img, 0, b22 - 8, pw, 2, Color(0.88, 0.68, 0.3))
		"candle_rack":
			# 54c: a rack of votive candles – iron, a row of flames
			var b23 := fy + ph
			_r(img, 1, b23 - 6, pw - 2, 3, Color(0.3, 0.24, 0.18))
			_r(img, 2, b23 - 3, 2, 3, Color(0.25, 0.2, 0.15))
			_r(img, pw - 4, b23 - 3, 2, 3, Color(0.25, 0.2, 0.15))
			for cn2 in range(3, pw - 3, 5):
				var chh := 4 + (cn2 % 3) * 2
				_r(img, cn2, b23 - 6 - chh, 2, chh, Color(0.95, 0.92, 0.85))
				_r(img, cn2, b23 - 9 - chh, 2, 3, Color(1.0, 0.8, 0.4))
		"throne":
			# 54c (Luz): the Hierarch's throne – a high back of gold and red, the sun on its crown, broad arms
			var b24 := fy + ph
			_r(img, 6, 0, pw - 12, b24 - 4, Color(0.75, 0.55, 0.22))
			_r(img, 10, 6, pw - 20, b24 - 16, Color(0.62, 0.12, 0.12))
			_r(img, 10, 6, 2, b24 - 16, Color(0.75, 0.22, 0.2))
			_ellipse(img, pw * 0.5, 4, 8, 6, Color(0.88, 0.68, 0.3))
			_ellipse(img, pw * 0.5, 4, 5, 4, Color(1.0, 0.92, 0.65))
			_r(img, 2, b24 - 18, 10, 14, Color(0.88, 0.68, 0.3))
			_r(img, pw - 12, b24 - 18, 10, 14, Color(0.88, 0.68, 0.3))
			_r(img, 2, b24 - 18, 10, 2, Color(1.0, 0.85, 0.5))
			_r(img, pw - 12, b24 - 18, 10, 2, Color(1.0, 0.85, 0.5))
			_r(img, 4, b24 - 4, pw - 8, 4, Color(0.55, 0.4, 0.18))
		"candelabrum":
			# 54c: a tall candelabrum of gilded bronze by the throne (~2.4 m), five candles
			var b25 := fy + ph
			_r(img, pw / 2 - 1, 8, 3, b25 - 10, Color(0.75, 0.55, 0.22))
			_ellipse(img, pw * 0.5, b25 - 2, 5, 2, Color(0.6, 0.45, 0.18))
			_r(img, 1, 10, pw - 2, 2, Color(0.75, 0.55, 0.22))
			for k5 in 5:
				var cx5 := 1 + k5 * (pw - 3) / 4
				_r(img, cx5, 4, 2, 6, Color(0.95, 0.92, 0.85))
				_r(img, cx5, 1, 2, 3, Color(1.0, 0.8, 0.4))
		"plaque_stone":
			# 54c (Luz): THE FOUNDERS on a bronze plaque let into a rough block of grey stone, its top lit
			var sb2 := fy + ph
			var stn2 := Color(0.56, 0.56, 0.58)
			for yy in range(sb2 - 22, sb2):
				var ins2 := 2 if yy < sb2 - 19 else 0
				_r(img, ins2 + int(_hn(yy, 3) * 2.0), yy, pw - ins2 * 2 - int(_hn(yy, 7) * 2.0), 1, stn2.darkened(0.12 if yy > sb2 - 12 else 0.0))
			_r(img, 3, sb2 - 22, pw - 6, 3, stn2.lightened(0.18))
			for sp2 in 9:
				_p(img, 3 + int(_hn(sp2, 11) * (pw - 6)), sb2 - 16 + int(_hn(sp2, 13) * 14), stn2.darkened(0.25))
			_r(img, 5, sb2 - 17, pw - 10, 9, Color(0.55, 0.38, 0.18))
			_r(img, 6, sb2 - 16, pw - 12, 7, Color(0.78, 0.58, 0.28))
			_r(img, 6, sb2 - 16, pw - 12, 1, Color(0.95, 0.8, 0.45))
			for lt in range(8, pw - 8, 2):
				_p(img, lt, sb2 - 13, Color(0.42, 0.28, 0.12))
			for lt2 in range(10, pw - 10, 3):
				_p(img, lt2, sb2 - 11, Color(0.5, 0.34, 0.15))
		"news_wall":
			# 54c: a free-standing news screen in the lobby – the Senate's channel: a speaker, a ticker running under it
			var nb := fy + ph
			_r(img, pw / 2 - 2, nb - 8, 4, 8, Color(0.3, 0.32, 0.36))
			_r(img, pw / 2 - 8, nb - 3, 16, 3, Color(0.3, 0.32, 0.36))
			_r(img, 0, 0, pw, nb - 8, Color(0.12, 0.13, 0.16))
			_r(img, 2, 2, pw - 4, nb - 12, Color(0.08, 0.14, 0.26))
			_r(img, 4, 4, 14, nb - 20, Color(0.2, 0.26, 0.36))
			_ellipse(img, 11, 10, 4, 4, Color(0.78, 0.62, 0.5))
			_r(img, 6, 15, 10, nb - 31, Color(0.2, 0.4, 0.8))
			for k3 in 3:
				_r(img, 22, 6 + k3 * 5, pw - 28 - k3 * 6, 2, Color(0.75, 0.85, 1.0) if k3 == 0 else Color(0.45, 0.6, 0.85))
			_r(img, 2, nb - 16, pw - 4, 4, Color(0.85, 0.2, 0.25))
			for tk in range(4, pw - 6, 7):
				_r(img, tk, nb - 15, 4, 2, Color(1, 1, 1))
		"bust":
			var bc: Color = o.get("col", Color(0.92, 0.9, 0.86))
			var bb := fy + ph
			_r(img, 3, bb - 16, pw - 6, 16, Color(0.86, 0.86, 0.88))
			_r(img, 3, bb - 16, 2, 16, Color(0.95, 0.95, 0.96))
			_r(img, 1, bb - 18, pw - 2, 3, Color(0.95, 0.95, 0.96))
			_r(img, 3, bb - 23, pw - 6, 5, bc.darkened(0.1))
			_ellipse(img, pw * 0.5, bb - 27, 4, 5, bc)
			_p(img, pw / 2 - 2, bb - 28, bc.darkened(0.35))
			_p(img, pw / 2 + 1, bb - 28, bc.darkened(0.35))
		"column":
			var cb := fy + ph
			_r(img, 2, fy - rise, pw - 4, rise + ph, Color(0.9, 0.9, 0.91))
			_r(img, 2, fy - rise, 2, rise + ph, Color(0.98, 0.98, 0.99))
			_r(img, pw - 4, fy - rise, 2, rise + ph, Color(0.7, 0.71, 0.74))
			for fl in [6, 9]:
				_r(img, fl, fy - rise + 3, 1, rise + ph - 6, Color(0.8, 0.81, 0.84))
			_r(img, 0, fy - rise, pw, 3, Color(0.96, 0.96, 0.97))
			_r(img, 0, cb - 3, pw, 3, Color(0.8, 0.81, 0.84))
		"curator_desk":
			# 53e (Luz): the curator's counter – dark wood panels under a marble top seen from above (0.7.53.27: with its
			# depth), brass trim, the Museum's emblem; on the top a holo terminal, a banker's lamp, books, a bell, a loupe
			# over a stone, leaflets, a nameplate
			var wd := Color(0.36, 0.22, 0.14)
			var br := Color(0.85, 0.66, 0.3)
			var db := fy + ph
			var top_y := db - 32                                # the top surface: 18 px deep
			_r(img, 0, top_y, pw, 18, Color(0.9, 0.89, 0.86))
			_r(img, 0, top_y, pw, 1, Color(1, 1, 1))
			_r(img, 0, top_y, 2, 18, Color(0.82, 0.81, 0.78))
			_r(img, pw - 2, top_y, 2, 18, Color(0.78, 0.77, 0.74))
			for vn in 7:
				for t in 5:
					_p(img, 8 + vn * 17 + t, top_y + 4 + t + (vn % 3) * 2, Color(0.8, 0.79, 0.76))
			_r(img, 0, top_y + 17, pw, 1, br)
			_r(img, 0, db - 14, pw, 14, wd)                     # the front
			for pp in range(0, pw - 4, 14):
				_r(img, pp + 2, db - 12, 10, 9, wd.lightened(0.08))
				_r(img, pp + 2, db - 12, 10, 1, wd.lightened(0.2))
			_r(img, 0, db - 2, pw, 2, wd.darkened(0.3))
			_ellipse(img, pw * 0.5, db - 7, 5, 5, br)
			_ellipse(img, pw * 0.5, db - 7, 3.5, 3.5, Color(0.12, 0.15, 0.25))
			_p(img, pw / 2, db - 7, br.lightened(0.4))
			# on the top (their feet on the surface, their bodies rising above it)
			var ty := top_y + 10
			_r(img, 8, ty - 13, 16, 11, Color(0.14, 0.15, 0.18))   # the terminal
			_r(img, 9, ty - 12, 14, 8, Color(0.3, 0.75, 0.95))
			_r(img, 10, ty - 11, 8, 1, Color(0.9, 1, 1))
			_r(img, 10, ty - 9, 11, 1, Color(0.7, 0.9, 1))
			_r(img, 14, ty - 2, 4, 3, Color(0.2, 0.2, 0.22))
			_r(img, 27, ty + 1, 9, 4, Color(0.25, 0.25, 0.28))     # a keyboard
			_r(img, 43, ty - 8, 2, 9, br)                          # the banker's lamp
			_r(img, 39, ty - 11, 10, 4, Color(0.15, 0.5, 0.3))
			_r(img, 39, ty - 11, 10, 1, Color(0.3, 0.75, 0.45))
			_r(img, 40, ty - 7, 8, 1, Color(1.0, 0.92, 0.6))
			_r(img, 41, ty + 1, 6, 2, br.darkened(0.2))
			for bk in 4:                                           # books
				_r(img, 56 + bk % 2, ty - bk * 3, 12, 3, [Color(0.55, 0.2, 0.2), Color(0.2, 0.35, 0.55), Color(0.3, 0.45, 0.25), Color(0.6, 0.5, 0.25)][bk])
				_r(img, 56 + bk % 2, ty - bk * 3, 12, 1, Color(0.9, 0.88, 0.8))
			_ellipse(img, 78, ty, 3, 3, br)                       # the bell
			_r(img, 78, ty - 4, 1, 2, br.lightened(0.3))
			_r(img, 86, ty, 7, 3, Color(0.5, 0.3, 0.7))             # a stone under a loupe
			_ellipse(img, 91, ty - 3, 3, 3, Color(0.75, 0.9, 1.0, 0.6))
			_r(img, 100, ty - 2, 10, 6, Color(0.9, 0.85, 0.7))       # leaflets
			_r(img, 101, ty - 1, 8, 1, Color(0.3, 0.4, 0.7))
			_r(img, 101, ty + 1, 8, 1, Color(0.7, 0.3, 0.3))
			_r(img, int(pw * 0.5) - 9, top_y + 13, 18, 4, br.darkened(0.25))   # the nameplate at the front edge
			_r(img, int(pw * 0.5) - 7, top_y + 14, 14, 1, Color(0.1, 0.08, 0.05))
		"museum_bench":
			var mb := fy + ph
			_r(img, 1, mb - 10, pw - 2, 7, Color(0.45, 0.12, 0.15))
			_r(img, 1, mb - 10, pw - 2, 2, Color(0.6, 0.2, 0.22))
			for bt in range(4, pw - 4, 8):
				_p(img, bt, mb - 6, Color(0.3, 0.06, 0.08))
			_r(img, 3, mb - 3, 2, 3, wood)
			_r(img, pw - 5, mb - 3, 2, 3, wood)
		"rope":
			# 53e: brass stanchions with a velvet rope sagging between
			var rb := fy + ph
			var posts := maxi(2, pw / 24 + 1)
			for pi in posts:
				var sx := 2 + int(float(pi) / (posts - 1) * (pw - 6))
				_r(img, sx, rb - 12, 2, 12, Color(0.85, 0.66, 0.3))
				_ellipse(img, sx + 1, rb - 13, 1.6, 1.6, Color(0.95, 0.8, 0.45))
				if pi < posts - 1:
					var ex := 2 + int(float(pi + 1) / (posts - 1) * (pw - 6))
					for xx2 in range(sx + 2, ex):
						var t := float(xx2 - sx) / (ex - sx)
						_p(img, xx2, rb - 10 + int(sin(t * PI) * 3), c if o.has("col") else Color(0.5, 0.1, 0.13))
		"m_rail":
			# 53e: the galleries' balustrade – white stone, a brass rail
			var mr := fy + ph
			if ph > TILE:
				# a rail running north–south: on the tiles' edge where `arch` says ("e"/"w"), else in the middle;
				# 0.7.53.29: down to the bottom of its tiles, where the front rail of the same height ends
				var ex := pw / 2 - 2
				if String(o.get("arch", "")) == "e":
					ex = pw - 4
				elif String(o.get("arch", "")) == "w":
					ex = 0
				_r(img, ex, fy - 6, 4, ph + 6 - 2, Color(0.92, 0.91, 0.88))
				_r(img, ex + 1, fy - 6, 1, ph + 6 - 2, Color(0.85, 0.66, 0.3))
				for by2 in range(fy - 4, mr - 2, 4):
					_p(img, ex + (3 if ex == 0 else 0), by2, Color(0.7, 0.68, 0.64))
			else:
				_r(img, 0, mr - 10, pw, 10, Color(0.86, 0.85, 0.82))
				_r(img, 0, mr - 10, pw, 2, Color(0.95, 0.94, 0.91))
				_r(img, 0, mr - 9, pw, 1, Color(0.85, 0.66, 0.3))
				for bx2 in range(2, pw - 1, 5):
					_r(img, bx2, mr - 7, 1, 5, Color(0.74, 0.72, 0.68))
				_r(img, 0, mr - 2, pw, 2, Color(0.7, 0.68, 0.64))
		"globe":
			var gb := fy + ph
			_r(img, pw / 2 - 2, gb - 12, 4, 12, wood)
			_r(img, pw / 2 - 8, gb - 3, 16, 3, wood.lightened(0.1))
			var gcx := pw * 0.5
			var gcy := gb - 22.0
			_ellipse(img, gcx, gcy, 10, 10, Color(0.2, 0.4, 0.75))
			for blob in [[-4, -4, 4, 3], [3, 2, 3, 5], [-1, 6, 3, 2], [-6, 1, 2, 2]]:
				_ellipse(img, gcx + blob[0], gcy + blob[1], blob[2], blob[3], Color(0.35, 0.6, 0.3))
			for a in 40:
				_p(img, int(gcx + cos(a * TAU / 40.0) * 11), int(gcy + sin(a * TAU / 40.0) * 11), Color(0.85, 0.66, 0.3))
			_ellipse(img, gcx - 4, gcy - 4, 2, 2, Color(1, 1, 1, 0.5))
		"geode_big":
			# 53e: a huge uncut amethyst geode, split – a showpiece
			var ggb := fy + ph
			_ellipse(img, pw * 0.5, ggb - 18, pw * 0.48, 18, Color(0.45, 0.4, 0.38))
			_ellipse(img, pw * 0.5, ggb - 17, pw * 0.36, 13, Color(0.25, 0.15, 0.32))
			for cq in 30:
				var a2 := cq * TAU / 30.0
				var rr := 4.0 + (cq % 3) * 3.0
				_r(img, int(pw * 0.5 + cos(a2) * rr * 1.3), int(ggb - 17 + sin(a2) * rr), 2, 3, Color(0.7, 0.5, 0.95).lerp(Color(0.95, 0.85, 1.0), (cq % 4) / 4.0))
		"ship_model":
			var sb := fy + ph
			_r(img, 2, sb - 10, pw - 4, 10, Color(0.9, 0.89, 0.86))
			_r(img, 2, sb - 10, pw - 4, 2, Color(1, 1, 1))
			_r(img, pw / 2 - 1, sb - 18, 2, 8, Color(0.4, 0.4, 0.42))
			_r(img, 6, sb - 25, pw - 12, 7, Color(0.38, 0.4, 0.46))
			_r(img, 6, sb - 25, pw - 12, 2, Color(0.58, 0.6, 0.66))
			_r(img, pw / 2 - 6, sb - 29, 12, 4, Color(0.48, 0.5, 0.56))
			_r(img, 3, sb - 23, 3, 3, Color(0.5, 0.8, 1.0))
		"holo_ship":
			# 0.7.53.27 (Luz): a ship of the game as a hologram - cyan, half see-through, scan lines - over a projector
			var hb := fy + ph
			_ellipse(img, pw * 0.5, hb - 4, pw * 0.42, 4, Color(0.14, 0.15, 0.18))
			_ellipse(img, pw * 0.5, hb - 5, pw * 0.3, 2.5, Color(0.25, 0.27, 0.3))
			_ellipse(img, pw * 0.5, hb - 6, 3, 1.5, Color(0.5, 0.95, 1.0))
			for cy2 in range(hb - 26, hb - 6):
				var spread := int((float(cy2 - (hb - 26)) / 20.0) * 4.0)
				_p(img, pw / 2 - 2 - spread, cy2, Color(0.4, 0.9, 1.0, 0.15))
				_p(img, pw / 2 + 2 + spread, cy2, Color(0.4, 0.9, 1.0, 0.15))
			var tex: Texture2D = PixelArt.ship_texture(String(o.get("species", "mogura")), "player")
			if tex != null:
				var si: Image = tex.get_image()
				si.convert(Image.FORMAT_RGBA8)
				var sc3 := minf(float(pw - 2) / si.get_width(), 26.0 / si.get_height())
				si.resize(maxi(1, int(si.get_width() * sc3)), maxi(1, int(si.get_height() * sc3)), Image.INTERPOLATE_BILINEAR)
				var ox := (pw - si.get_width()) / 2
				var oy := hb - 12 - si.get_height()
				for yy3 in si.get_height():
					for xx3 in si.get_width():
						var sc4 := si.get_pixel(xx3, yy3)
						if sc4.a > 0.3:
							var lum2 := sc4.get_luminance()
							var hc := Color(0.35, 0.85, 1.0).lerp(Color(0.85, 1.0, 1.0), lum2)
							hc.a = 0.75 if (oy + yy3) % 3 != 0 else 0.4
							_p(img, ox + xx3, oy + yy3, hc)
		"poster":
			var pb2 := fy + ph
			_r(img, pw / 2 - 1, pb2 - 6, 2, 6, Color(0.3, 0.3, 0.32))
			_r(img, 1, pb2 - 26, pw - 2, 20, Color(0.2, 0.2, 0.24))
			_r(img, 2, pb2 - 25, pw - 4, 18, Color(0.15, 0.1, 0.25))
			_r(img, 3, pb2 - 23, pw - 6, 7, Color(0.62, 0.35, 1.0))
			_r(img, 3, pb2 - 13, pw - 6, 2, Color(0.95, 0.85, 0.6))
		"skull_cast":
			# 53e: the cast of a giant skull from the Dark Ones' ruins on a low plinth
			var kb := fy + ph
			_r(img, 0, kb - 6, pw, 6, Color(0.1, 0.09, 0.12))
			_r(img, 0, kb - 6, pw, 1, Color(0.26, 0.22, 0.32))
			_ellipse(img, pw * 0.55, kb - 12, 9, 6, Color(0.75, 0.71, 0.63))
			_ellipse(img, pw * 0.5, kb - 13, 1.8, 1.8, Color(0.06, 0.05, 0.06))
			_ellipse(img, pw * 0.62, kb - 13, 1.8, 1.8, Color(0.06, 0.05, 0.06))
			_ellipse(img, pw * 0.72, kb - 11, 1.4, 1.4, Color(0.06, 0.05, 0.06))
			for bn in 5:
				_r(img, 2 + bn * 6, kb - 8 - (bn % 2), 7, 2, Color(0.7, 0.66, 0.58))
		"idol_cast":
			# 53e: the cast of one of their idols – tall, faceless, black, a violet line where the eyes would be
			var ib := fy + ph
			_r(img, 3, ib - 8, pw - 6, 8, Color(0.12, 0.1, 0.15))
			for t3 in 32:
				var ww := int(10 - absf(t3 - 13) * 0.35)
				_r(img, pw / 2 - ww / 2, ib - 40 + t3, ww, 1, Color(0.2, 0.17, 0.26).lerp(Color(0.32, 0.27, 0.4), t3 / 32.0))
			_r(img, pw / 2 - 4, ib - 33, 8, 1, Color(0.62, 0.35, 1.0))
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
			# a pot, fronds fanning out of it – inside its tile (they were loose squares, cut off at the tile's edge)
			var pb := fy + ph
			var pv := int(o["x"]) % 4
			for k in [0, 6, 1, 5, 2, 4, 3]:                              # the outer fronds first, the middle one on top
				var ft: float = (int(k) - 3) / 3.0
				var ln: float = 13.0 + float((int(k) * 5 + pv * 3) % 5)
				var lc := Color(0.14, 0.44 + 0.07 * ((int(k) + pv) % 3), 0.2)
				for sg in int(ln):
					var u: float = sg / ln
					var lx: float = pw * 0.5 + ft * 6.0 * (u * 0.35 + u * u * 0.65)
					var ly: float = pb - 9.0 - ln * u * (1.0 - 0.4 * absf(ft) * u)
					var lw := 2 if u < 0.8 else 1
					_r(img, clampi(int(lx) - (1 if lw == 2 else 0), 1, pw - 1 - lw), int(ly), lw, 2, lc.lightened(0.28 * u))
			_r(img, pw / 2 - 4, pb - 8, 8, 7, Color(0.55, 0.35, 0.25))
			_r(img, pw / 2 - 5, pb - 9, 10, 2, Color(0.7, 0.48, 0.35))
			_r(img, pw / 2 - 3, pb - 2, 6, 1, Color(0.4, 0.25, 0.18))
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
		"obelisk":
			# 0.7.53.23: a fallen obelisk of black glassy stone, signs along it glowing faintly
			var bo := fy + ph
			_r(img, 0, bo - 14, pw, 12, Color(0.08, 0.07, 0.11))
			_r(img, 0, bo - 14, pw, 3, Color(0.22, 0.2, 0.28))
			for gk in range(4, pw - 6, 7):
				_r(img, gk, bo - 9, 3, 1, Color(0.62, 0.35, 1.0))
				_r(img, gk + 1, bo - 10, 1, 3, Color(0.62, 0.35, 1.0))
			_r(img, pw - 7, bo - 18, 7, 16, Color(0.06, 0.05, 0.08))
		"obelisk_stand":
			# 0.7.53.23: a standing obelisk – tall, tapering, its signs in a column
			var bt := fy + ph
			for oy in 50:
				var ow := int(lerpf(float(pw) - 2.0, float(pw) * 0.45, float(oy) / 50.0))
				_r(img, (pw - ow) / 2, bt - 2 - oy, ow, 1, Color(0.08, 0.07, 0.11) if oy < 48 else Color(0.25, 0.22, 0.3))
			_r(img, (pw - int(pw * 0.6)) / 2, bt - 50, 2, 48, Color(0.2, 0.18, 0.26))
			for gy in range(bt - 44, bt - 6, 8):
				_r(img, pw / 2 - 2, gy, 4, 1, Color(0.62, 0.35, 1.0))
				_r(img, pw / 2 - 1, gy - 1, 1, 3, Color(0.62, 0.35, 1.0))
		"bones":
			# 0.7.53.23: the bones of something vast – ribs, a long bone, part of a skull too wide for any face
			var bb := fy + ph
			var bc := Color(0.72, 0.68, 0.6)
			for rb in 4:
				for t in 10:
					_r(img, 3 + rb * 6 + int(sin(t * 0.3) * 2.0), bb - 4 - t, 2, 1, bc.darkened(0.1 * (t % 3)))
			_r(img, 0, bb - 4, pw - 2, 3, bc.darkened(0.2))
			_ellipse(img, pw - 7, bb - 10, 6, 5, bc)
			_ellipse(img, pw - 9, bb - 11, 1.5, 1.5, Color(0.05, 0.04, 0.05))
			_ellipse(img, pw - 5, bb - 11, 1.5, 1.5, Color(0.05, 0.04, 0.05))
		"altar":
			# 0.7.53.23: an altar block of black stone, a groove round its top, a sign glowing on its front
			var ba := fy + ph
			_r(img, 1, ba - 16, pw - 2, 14, Color(0.09, 0.08, 0.12))
			_r(img, 1, ba - 16, pw - 2, 4, Color(0.22, 0.2, 0.28))
			_r(img, 3, ba - 14, pw - 6, 1, Color(0.05, 0.04, 0.07))
			_r(img, pw / 2 - 3, ba - 9, 6, 1, Color(0.62, 0.35, 1.0))
			_r(img, pw / 2, ba - 11, 1, 5, Color(0.62, 0.35, 1.0))
		"lab_bench":
			# 0.7.53.20: a white lab bench, instruments on it, a monitor flickering, a cup left behind
			var bl := fy + ph
			_r(img, 1, bl - 14, pw - 2, 9, Color(0.86, 0.87, 0.9))
			_r(img, 1, bl - 14, pw - 2, 1, Color(0.97, 0.97, 0.98))
			_r(img, 1, bl - 5, pw - 2, 4, Color(0.55, 0.57, 0.6))
			for eq in int(pw / 12):
				_r(img, 3 + eq * 12, bl - 20, 8, 6, Color(0.3, 0.32, 0.36))
				_r(img, 4 + eq * 12, bl - 19, 6, 3, [Color(0.3, 0.9, 0.6), Color(0.9, 0.3, 0.3), Color(0.3, 0.7, 1.0)][eq % 3])
			_r(img, pw - 6, bl - 13, 3, 3, Color(0.95, 0.93, 0.88))
		"cryo_tank":
			# 0.7.53.20: a cryo tank – a glass cylinder lit blue, frost at its foot
			var bc := fy + ph
			_r(img, 3, bc - 44, pw - 6, 42, Color(0.32, 0.34, 0.38))
			_r(img, 5, bc - 40, pw - 10, 34, Color(0.45, 0.75, 0.9))
			_r(img, 7, bc - 38, 3, 30, Color(0.85, 0.97, 1.0))
			_r(img, 3, bc - 46, pw - 6, 4, Color(0.55, 0.57, 0.62))
			_r(img, 2, bc - 4, pw - 4, 3, Color(0.85, 0.92, 0.98))
		"sample_cabinet":
			# 0.7.53.20: a sample cabinet – white, rows of labelled drawers, a red light
			var bs := fy + ph
			_r(img, 1, bs - 40, pw - 2, 38, Color(0.84, 0.85, 0.88))
			_r(img, 1, bs - 40, pw - 2, 5, Color(0.92, 0.93, 0.95))
			for dr in range(bs - 32, bs - 6, 6):
				_r(img, 4, dr, pw - 8, 4, Color(0.7, 0.72, 0.76))
				_r(img, pw / 2 - 2, dr + 1, 4, 1, Color(0.35, 0.36, 0.4))
			_p(img, pw - 5, bs - 37, Color(1.0, 0.25, 0.2))
		"dome":
			# 0.7.53.20: a dome – white panels, a lit window band, its little door
			var bd := fy + ph
			_ellipse(img, pw * 0.5, bd - 24, pw * 0.48, 26, Color(0.25, 0.27, 0.32))
			_ellipse(img, pw * 0.5, bd - 24, pw * 0.46, 24, Color(0.78, 0.81, 0.86))
			_ellipse(img, pw * 0.42, bd - 34, pw * 0.25, 12, Color(0.88, 0.9, 0.94))
			for ln in 4:
				_r(img, int(pw * 0.08), bd - 40 + ln * 9, int(pw * 0.84), 1, Color(0.6, 0.63, 0.68))
			_r(img, int(pw * 0.15), bd - 14, int(pw * 0.7), 4, Color(0.3, 0.6, 0.35))       # green behind the glass
			_r(img, int(pw * 0.5) - 5, bd - 12, 10, 12, Color(0.35, 0.37, 0.42))
		"radio_mast":
			# 0.7.53.20: a lattice radio mast, its red light on top
			var bm := fy + ph
			_r(img, pw / 2 - 1, bm - 170, 3, 170, Color(0.45, 0.47, 0.52))
			for lt in range(bm - 168, bm, 10):
				_r(img, 0, lt, pw, 1, Color(0.4, 0.42, 0.46))
			_r(img, pw / 2 - 2, bm - 172, 5, 3, Color(1.0, 0.2, 0.15))
		"crawler":
			# 0.7.53.20: a snow crawler – tracks, an orange body, a cab
			var bw := fy + ph
			_r(img, 0, bw - 8, pw, 8, Color(0.14, 0.14, 0.16))
			for tr in range(0, pw, 5):
				_r(img, tr, bw - 8, 2, 8, Color(0.28, 0.28, 0.3))
			_r(img, 2, bw - 30, pw - 4, 22, Color(0.85, 0.55, 0.15))
			_r(img, 2, bw - 30, pw - 4, 3, Color(0.95, 0.7, 0.3))
			_r(img, 6, bw - 40, int(pw * 0.45), 12, Color(0.25, 0.35, 0.45))
			_r(img, 8, bw - 38, int(pw * 0.45) - 4, 6, Color(0.55, 0.75, 0.9))
		"office_desk":
			# 0.7.53.19: a white desk, its screen glowing, a keyboard, a cup; the chair before it
			var b5 := fy + ph
			_r(img, 1, b5 - 14, pw - 2, 9, Color(0.9, 0.91, 0.93))                 # the top
			_r(img, 1, b5 - 14, pw - 2, 1, Color(1, 1, 1))
			_r(img, 1, b5 - 5, pw - 2, 4, Color(0.62, 0.64, 0.68))                 # its front panel
			_r(img, 6, b5 - 24, 12, 10, Color(0.12, 0.13, 0.15))                    # the screen
			_r(img, 7, b5 - 23, 10, 7, Color(0.3, 0.6, 0.9))
			_r(img, 8, b5 - 22, 5, 1, Color(0.75, 0.92, 1.0))
			_r(img, 11, b5 - 14, 2, 1, Color(0.2, 0.2, 0.22))
			_r(img, 20, b5 - 12, 7, 3, Color(0.2, 0.21, 0.24))                      # a keyboard
			_r(img, pw - 7, b5 - 13, 3, 3, Color(0.95, 0.94, 0.9))                  # a cup
		"partition":
			# 0.7.53.19: a low office screen – fabric in a steel frame
			var b6 := fy + ph
			_r(img, 0, b6 - 18, pw, 14, Color(0.42, 0.46, 0.56))
			_r(img, 0, b6 - 18, pw, 2, Color(0.6, 0.63, 0.7))
			for k6 in int(pw / 8):
				_r(img, k6 * 8 + 3, b6 - 15, 1, 10, Color(0.38, 0.42, 0.52))
			_r(img, 0, b6 - 4, pw, 2, Color(0.55, 0.57, 0.6))
			_r(img, 2, b6 - 2, 2, 2, Color(0.3, 0.31, 0.34))
			_r(img, pw - 4, b6 - 2, 2, 2, Color(0.3, 0.31, 0.34))
		"server_rack":
			# 0.7.53.19: a server cabinet – dark, rows of blinking lights, a glass door
			var b7 := fy + ph
			_r(img, 1, b7 - 40, pw - 2, 38, Color(0.13, 0.14, 0.17))
			_r(img, 1, b7 - 40, pw - 2, 6, Color(0.22, 0.23, 0.27))                # its top, seen from above
			for ry in range(b7 - 32, b7 - 6, 4):
				_r(img, 4, ry, pw - 8, 3, Color(0.2, 0.21, 0.25))
				for lx2 in range(6, pw - 8, 5):
					_p(img, lx2, ry + 1, [Color(0.3, 1.0, 0.5), Color(0.3, 0.8, 1.0), Color(1.0, 0.75, 0.3)][(lx2 + ry) % 3])
			_r(img, pw / 2, b7 - 32, 1, 26, Color(0.3, 0.32, 0.36))
			_r(img, 1, b7 - 3, pw - 2, 2, Color(0.08, 0.08, 0.1))
		"computer_wall":
			# package 58, part 7 (Luz): the relay's computer wall – cabinets of blinking lights the whole width, in the
			# middle a big screen: the cluster's map with the pirates' traffic (red lines to one point), a waveform
			var b9 := fy + ph
			_r(img, 0, b9 - 52, pw, 50, Color(0.11, 0.12, 0.15))
			_r(img, 0, b9 - 52, pw, 7, Color(0.2, 0.21, 0.25))                     # its top
			for cx9 in range(2, pw - 8, 10):
				_r(img, cx9, b9 - 43, 8, 38, Color(0.15, 0.16, 0.2))
				for ry9 in range(b9 - 40, b9 - 8, 4):
					for lx9 in range(cx9 + 1, cx9 + 7, 2):
						if (lx9 * 7 + ry9 * 3 + int(o.get("seed", 0))) % 5 != 0:
							_p(img, lx9, ry9, [Color(0.3, 1.0, 0.5), Color(0.3, 0.8, 1.0), Color(1.0, 0.75, 0.3), Color(1.0, 0.3, 0.25)][(lx9 + ry9) % 4])
			var sw := mini(pw - 20, 64)
			var sx := (pw - sw) / 2
			_r(img, sx - 2, b9 - 48, sw + 4, 34, Color(0.05, 0.05, 0.07))
			_r(img, sx, b9 - 46, sw, 30, Color(0.06, 0.1, 0.14))
			var hub := Vector2(sx + sw * 0.62, b9 - 33)
			for k9 in 9:
				var a9 := Vector2(sx + 3 + (k9 * 23 + int(o.get("seed", 0))) % (sw - 6), b9 - 44 + (k9 * 11) % 26)
				var n9 := int(a9.distance_to(hub) / 2.0)
				for t9 in n9:
					var q9 := a9.lerp(hub, float(t9) / float(maxi(n9, 1)))
					_p(img, int(q9.x), int(q9.y), Color(1.0, 0.3, 0.25, 0.8))
				_p(img, int(a9.x), int(a9.y), Color(1.0, 0.85, 0.5))
			_r(img, int(hub.x) - 1, int(hub.y) - 1, 3, 3, Color(1.0, 0.2, 0.15))
			for wx in sw - 4:
				_p(img, sx + 2 + wx, b9 - 20 + int(sin(wx * 0.6) * 2.0), Color(0.3, 1.0, 0.6))
			_r(img, 0, b9 - 3, pw, 2, Color(0.06, 0.06, 0.08))
		"pillar_corp":
			# 0.7.53.19: a square lobby pillar – pale stone, a gold band, rising to the ceiling
			var b8 := fy + ph
			var pc8 := Color(0.86, 0.86, 0.88)
			_r(img, 1, b8 - 56, pw - 2, 12, pc8.lightened(0.06))                    # its top (seen from above)
			_r(img, 1, b8 - 44, pw - 2, 42, pc8.darkened(0.08))
			_r(img, 1, b8 - 44, 2, 42, pc8.lightened(0.05))
			_r(img, pw - 3, b8 - 44, 2, 42, pc8.darkened(0.25))
			_r(img, 1, b8 - 30, pw - 2, 2, Color(0.95, 0.75, 0.3))
			_r(img, 1, b8 - 4, pw - 2, 2, Color(0.55, 0.57, 0.6))
		"lift_tank":
			var b16 := fy + ph
			for yy in range(4, b16 - 2):
				for xx in range(2, pw - 2):
					var k16 := float(xx) / pw
					var tc := Color(0.66, 0.68, 0.7).lerp(Color(0.32, 0.34, 0.38), k16)
					if (yy - 4) % 20 == 0:
						tc = tc.darkened(0.25)
					img.set_pixel(xx, yy, tc)
			_ellipse(img, pw / 2, 5, pw / 2 - 2, 4, Color(0.75, 0.77, 0.8))
			_r(img, pw / 2 - 6, b16 / 2, 12, 3, Color(0.95, 0.75, 0.2))
		"rotor_ring":
			var cy16 := fy + ph / 2
			_ellipse(img, pw / 2, cy16, pw / 2 - 1, ph / 2 - 1, Color(0.3, 0.31, 0.34))
			_ellipse(img, pw / 2, cy16, pw / 2 - 5, ph / 2 - 4, Color(0.45, 0.85, 1.0, 0.55))
			for bl in 6:
				var ba := bl * TAU / 6.0
				for tt in int(pw / 2 - 6):
					img.set_pixel(int(pw / 2 + cos(ba) * tt), int(cy16 + sin(ba) * tt * float(ph) / pw), Color(0.6, 0.62, 0.66))
		"lantern":
			var b15 := fy + ph
			_r(img, pw / 2 - 1, 10, 3, b15 - 12, Color(0.18, 0.14, 0.12))
			_r(img, pw / 2 - 4, b15 - 4, 9, 3, Color(0.22, 0.17, 0.14))
			_r(img, pw / 2 - 5, 2, 11, 12, Color(0.18, 0.14, 0.12))
			_r(img, pw / 2 - 4, 4, 9, 8, c)
			_r(img, pw / 2 - 1, 4, 3, 8, c.lightened(0.3))
			_r(img, pw / 2 - 6, 1, 13, 2, Color(0.75, 0.58, 0.25))
			_r(img, pw / 2 - 2, 0, 5, 1, Color(0.75, 0.58, 0.25))
		"gas_tank":
			var r := pw / 2 - 4
			var cy := fy + ph - r - 6
			var cx := pw / 2
			for lg in [-0.7, -0.25, 0.25, 0.7]:
				_r(img, cx + int(lg * r) - 2, cy, 4, fy + ph - cy - 2, Color(0.36, 0.37, 0.4))
			for yy in range(-r, r):
				for xx in range(-r, r):
					var d := Vector2(xx + 0.5, yy + 0.5).length()
					if d > r:
						continue
					var n := Vector3(xx, yy, sqrt(maxf(r * r - d * d, 0.0))).normalized()
					var li := clampf(n.dot(Vector3(-0.5, -0.6, 0.62).normalized()), 0.0, 1.0)
					var tc := Color(0.86, 0.86, 0.84).darkened(0.45).lerp(Color(0.95, 0.95, 0.93), li)
					if absi(yy) < 1:
						tc = tc.darkened(0.2)
					img.set_pixel(cx + xx, cy + yy, tc)
			_r(img, cx + r - 6, cy - r + 8, 2, r * 2 - 12, Color(0.3, 0.3, 0.32))
			_r(img, cx - r / 3 - 2, cy - r / 2 - 2, 5, 5, Color(0.95, 0.95, 0.9))
			_r(img, cx - r / 3, cy - r / 2, 1, 1, Color(1.0, 0.3, 0.2))
		"compressor":
			var b12 := fy + ph
			_r(img, 0, fy - 22, pw, ph + 22, Color(0.5, 0.52, 0.48))
			_r(img, 0, fy - 22, pw, 2, Color(0.66, 0.68, 0.64))
			for f in int(pw / 18):
				_ellipse(img, 9 + f * 18, fy - 12, 7, 3, Color(0.25, 0.26, 0.27))
				_ellipse(img, 9 + f * 18, fy - 12, 2, 1, Color(0.5, 0.5, 0.5))
			for yy2 in range(fy, b12 - 2, 4):
				_r(img, 2, yy2, pw - 4, 1, Color(0.42, 0.44, 0.4))
			_r(img, pw - 10, fy + 4, 6, 4, Color(0.15, 0.15, 0.17))
			_r(img, pw - 9, fy + 5, 4, 2, Color(0.4, 1.0, 0.5))
			_r(img, 4, fy + 2, 20, 4, Color(0.95, 0.75, 0.2))
		"gas_column":
			var b13 := fy + ph
			for yy3 in range(0, b13 - 4):
				for xx3 in pw:
					var k3 := float(xx3) / pw
					var cc := Color(0.72, 0.74, 0.76).lerp(Color(0.42, 0.44, 0.48), k3)
					if yy3 % 26 == 0:
						cc = cc.darkened(0.25)
					img.set_pixel(xx3, yy3, cc)
			for yy4 in range(10, b13 - 10, 40):
				_r(img, 0, yy4, pw, 2, Color(0.95, 0.75, 0.2))
			_r(img, 2, b13 - 6, pw - 4, 6, Color(0.36, 0.37, 0.4))
		"gas_flare":
			_r(img, pw / 2 - 3, 24, 6, fy + ph - 24, Color(0.42, 0.42, 0.45))
			_r(img, pw / 2 - 3, 24, 1, fy + ph - 24, Color(0.6, 0.6, 0.62))
			_r(img, pw / 2 - 6, fy + ph - 4, 12, 4, Color(0.3, 0.3, 0.32))
			for fl in 12:
				var fr := 6.0 - fl * 0.42
				_ellipse(img, pw / 2 + int(sin(fl * 1.7) * 2.0), 22 - fl * 2, fr, fr, Color(1.0, 0.55 + fl * 0.03, 0.15 + fl * 0.02))
		"winch":
			var b14 := fy + ph
			_r(img, 2, b14 - 16, pw - 4, 14, Color(0.4, 0.41, 0.44))
			_r(img, 2, b14 - 16, pw - 4, 2, Color(0.62, 0.64, 0.68))
			_ellipse(img, pw / 2, b14 - 9, pw / 2 - 6, 5, Color(0.55, 0.56, 0.58))
			_ellipse(img, pw / 2, b14 - 9, pw / 2 - 10, 3, Color(0.3, 0.31, 0.33))
			_r(img, 4, b14 - 4, pw - 8, 2, Color(0.95, 0.75, 0.2))
		"scope":
			# package 54: a viewing scope on its post – the barrel tilted out over the clouds, a coin slot
			var b10 := fy + ph
			_r(img, pw / 2 - 1, b10 - 18, 3, 16, Color(0.5, 0.52, 0.56))
			_r(img, pw / 2 - 4, b10 - 3, 9, 3, Color(0.35, 0.36, 0.4))
			_r(img, 2, b10 - 25, pw - 4, 7, c.darkened(0.35))
			_r(img, 2, b10 - 25, pw - 4, 2, c.lightened(0.1))
			_r(img, pw - 4, b10 - 24, 3, 5, Color(0.75, 0.9, 1.0))
		"car_pole":
			var b11 := fy + ph
			_r(img, pw / 2 - 1, 0, 2, b11 - 2, Color(0.82, 0.83, 0.85))           # 0.7.54.2: floor to ceiling
			_r(img, pw / 2 - 1, 0, 1, b11 - 2, Color(0.95, 0.96, 0.97))
			_r(img, pw / 2 - 3, 0, 6, 3, Color(0.5, 0.52, 0.56))
			_r(img, pw / 2 - 3, b11 - 3, 6, 2, Color(0.5, 0.52, 0.56))
		"glass_rail":
			# 0.7.53.19: a glass balustrade – panes in a steel rail
			var b9 := fy + ph
			_r(img, 0, b9 - 18, pw, 14, Color(0.55, 0.72, 0.85, 0.55))
			for k9 in range(0, pw, 24):
				_r(img, k9, b9 - 18, 2, 16, Color(0.72, 0.75, 0.8))
				_r(img, k9 + 6, b9 - 16, 2, 10, Color(0.9, 0.97, 1.0, 0.7))
			_r(img, 0, b9 - 19, pw, 2, Color(0.85, 0.87, 0.9))
			_r(img, 0, b9 - 4, pw, 2, Color(0.5, 0.52, 0.56))
		"sofa":
			var b4 := fy + ph
			if int(o.get("face", 0)) != 1:                                        # (facing up: its back is drawn over the sitters, "sofa_back")
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
		"sofa_back":
			# a sofa facing up, from behind: its back towards you, the sitters' heads over it
			var b4b := fy + ph
			_r(img, 1, b4b - 15, pw - 2, 12, c.darkened(0.3))
			_r(img, 1, b4b - 15, pw - 2, 2, c.darkened(0.12))
			_r(img, 1, b4b - 6, pw - 2, 3, c.darkened(0.42))
			for k in int(pw / 16) - 1:
				_r(img, k * 16 + 16, b4b - 13, 1, 7, c.darkened(0.4))
			_r(img, 0, b4b - 14, 3, 11, c.darkened(0.35))                         # the arms
			_r(img, pw - 3, b4b - 14, 3, 11, c.darkened(0.2))
			_r(img, 2, b4b - 3, 2, 3, Color(0.15, 0.12, 0.1))
			_r(img, pw - 4, b4b - 3, 2, 3, Color(0.15, 0.12, 0.1))
		"chair_back":
			# a chair facing up, from behind: its backrest towards you, the sitter's shoulders and head over it
			var bcb := fy + ph
			_r(img, 3, bcb - 14, pw - 6, 7, c.darkened(0.32))
			_r(img, 3, bcb - 14, pw - 6, 1, c.lightened(0.12))
			_r(img, 5, bcb - 12, pw - 10, 3, c.darkened(0.42))
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
		"cargo_loader":             # 0.7.50.15: a hover loader by the pads, a crate on its forks
			var gb3 := fy + ph - 1
			_r(img, 3, gb3 - 6, pw - 10, 4, Color(0.2, 0.21, 0.24))                  # its hover skirt
			_r(img, 5, gb3 - 2, pw - 14, 1, Color(0.35, 0.95, 1.0))
			_r(img, 6, gb3 - 18, 18, 12, Color(0.9, 0.68, 0.15))                     # the body
			_r(img, 6, gb3 - 18, 18, 2, Color(1.0, 0.82, 0.35))
			_r(img, 9, gb3 - 26, 10, 8, Color(0.25, 0.27, 0.3))                      # the cab, open
			_r(img, 10, gb3 - 25, 8, 4, Color(0.3, 0.75, 0.95, 0.8))
			_r(img, 8, gb3 - 27, 14, 2, Color(0.8, 0.6, 0.12))
			_r(img, 26, gb3 - 30, 2, 26, Color(0.3, 0.3, 0.33))                      # the mast
			_r(img, 26, gb3 - 9, pw - 28, 2, Color(0.3, 0.3, 0.33))                  # the forks
			_r(img, 29, gb3 - 21, pw - 32, 12, Color(0.5, 0.36, 0.2))                # the crate on them
			_r(img, 29, gb3 - 21, pw - 32, 1, Color(0.65, 0.48, 0.28))
			_r(img, 29, gb3 - 16, pw - 32, 1, Color(0.38, 0.27, 0.15))
			_r(img, 7, gb3 - 13, 2, 2, Color(1.0, 0.35, 0.25))
			_r(img, 21, gb3 - 13, 2, 2, Color(0.35, 0.95, 1.0))
		"fuel_point":               # 0.7.50.15: a pad's fuel point – the pump, its screen, the hose coiled on its side
			_r(img, 3, fy - 20, pw - 10, ph + 18, Color(0.82, 0.83, 0.85))
			_r(img, 3, fy - 20, pw - 10, 3, Color(0.95, 0.95, 0.96))
			_r(img, 3, fy - 4, pw - 10, 3, Color(0.95, 0.75, 0.15))
			_r(img, 6, fy - 15, pw - 16, 7, Color(0.05, 0.08, 0.1))
			_r(img, 7, fy - 14, int((pw - 18) * 0.6), 2, Color(0.4, 1.0, 0.55))
			_r(img, 7, fy - 11, int((pw - 18) * 0.4), 1, Color(0.35, 0.95, 1.0))
			_ellipse(img, pw - 6, fy - 4, 4, 5, Color(0.15, 0.15, 0.17))
			_ellipse(img, pw - 6, fy - 4, 2, 3, Color(0.32, 0.32, 0.35))
			_r(img, pw - 8, fy + ph - 6, 6, 3, Color(0.15, 0.15, 0.17))
			_r(img, pw / 2 - 2, fy - 24, 3, 4, Color(1.0, 0.45, 0.2))
		"machine":
			_r(img, 1, fy - 8, pw - 2, ph + 6, Color(0.32, 0.29, 0.26))
			_r(img, 1, fy - 8, pw - 2, 3, Color(0.45, 0.4, 0.36))
			_r(img, 4, fy - 3, pw - 8, 3, Color(0.95, 0.55, 0.15))
			for k in int(pw / 8):
				_r(img, 3 + k * 8, fy + ph - 6, 4, 4, Color(0.15, 0.15, 0.15))
		"lamp_post":                # (0.7.50.13: as tall as its rise – a street lamp in a settlement stands ~4 m)
			_r(img, pw / 2 - 1, 4, 2, fy + ph - 6, metal.darkened(0.3))
			_r(img, pw / 2 - 2, fy + ph - 4, 4, 2, metal.darkened(0.4))
			_ellipse(img, pw * 0.5, 3, 4, 3, c.lightened(0.4))
		"med_bed":                  # 0.7.51.4: a clinic bed – white frame, blue sheet, a monitor at its head
			_r(img, 1, fy, pw - 2, ph - 2, Color(0.88, 0.9, 0.92))
			_r(img, 2, fy + 2, pw - 4, ph - 6, Color(0.55, 0.75, 0.95))
			_r(img, 2, fy + 2, pw - 4, 4, Color(0.96, 0.97, 0.98))                       # the pillow
			_r(img, 2, fy + ph - 4, 2, 4, metal.darkened(0.4))
			_r(img, pw - 4, fy + ph - 4, 2, 4, metal.darkened(0.4))
			_r(img, pw - 7, fy - 12, 6, 8, Color(0.08, 0.1, 0.12))                       # the monitor
			_r(img, pw - 6, fy - 9, 4, 1, Color(0.4, 1.0, 0.55))
			_r(img, pw - 5, fy - 11, 1, 2, Color(0.4, 1.0, 0.55))
			_r(img, pw - 4, fy - 4, 1, 4, metal.darkened(0.3))
		"med_bed_occ":              # 0.7.51.11: a bed with its patient – the head on the pillow, the sheet over them, a drip
			var prng := RandomNumberGenerator.new()
			prng.seed = int(o.get("seed", 3))
			_r(img, 1, fy, pw - 2, ph - 2, Color(0.88, 0.9, 0.92))
			_r(img, 2, fy + 2, pw - 4, ph - 6, Color(0.55, 0.75, 0.95))
			_r(img, 2, fy + 2, pw - 4, 5, Color(0.96, 0.97, 0.98))
			var skin: Color = [Color(0.95, 0.8, 0.68), Color(0.78, 0.58, 0.42), Color(0.5, 0.34, 0.24), Color(0.88, 0.72, 0.58)][prng.randi() % 4]
			var hair: Color = [Color(0.2, 0.15, 0.1), Color(0.55, 0.35, 0.2), Color(0.85, 0.75, 0.45), Color(0.15, 0.15, 0.17)][prng.randi() % 4]
			var pat: Dictionary = o.get("patient", {})              # package 56: the pilot in the bed – their own colours
			if not pat.is_empty():
				var PAo = load("res://scripts/core/pilot_art.gd")
				skin = PAo.SKINS[int(pat.get("skin", 2)) % PAo.SKINS.size()]
				hair = PAo.HAIR_COLORS[int(pat.get("hair_color", 1)) % PAo.HAIR_COLORS.size()]
				if int(pat.get("hair", 2)) == 0:
					hair = skin.darkened(0.08)
			_ellipse(img, pw * 0.5, fy + 8.0, 5.0, 4.5, skin)                                 # the head on the pillow
			_r(img, pw / 2 - 5, fy + 3, 10, 3, hair)
			if bool(o.get("awake", false)):
				_r(img, pw / 2 - 2, fy + 7, 1, 2, Color(0.95, 0.95, 0.95))                    # 56: eyes open
				_r(img, pw / 2 + 1, fy + 7, 1, 2, Color(0.95, 0.95, 0.95))
				_r(img, pw / 2 - 2, fy + 8, 1, 1, Color(0.2, 0.25, 0.4))
				_r(img, pw / 2 + 1, fy + 8, 1, 1, Color(0.2, 0.25, 0.4))
			else:
				_r(img, pw / 2 - 2, fy + 8, 1, 1, Color(0.2, 0.15, 0.15))                    # eyes shut
				_r(img, pw / 2 + 1, fy + 8, 1, 1, Color(0.2, 0.15, 0.15))
			_r(img, 3, fy + 13, pw - 6, ph - 18, Color(0.62, 0.8, 0.97))                    # the sheet over them
			_r(img, 3, fy + 13, pw - 6, 2, Color(0.85, 0.93, 1.0))
			_r(img, 5, fy + 15, 3, 6, skin)                                                 # an arm on the sheet
			_r(img, 4, fy + ph - 9, pw - 8, 2, Color(0.5, 0.68, 0.88))
			_r(img, 2, fy + ph - 4, 2, 4, metal.darkened(0.4))
			_r(img, pw - 4, fy + ph - 4, 2, 4, metal.darkened(0.4))
			_r(img, pw - 7, fy - 12, 6, 8, Color(0.08, 0.1, 0.12))                         # the monitor
			_r(img, pw - 6, fy - 9, 4, 1, Color(0.4, 1.0, 0.55))
			_r(img, pw - 5, fy - 11, 1, 2, Color(0.4, 1.0, 0.55))
			_r(img, pw - 4, fy - 4, 1, 4, metal.darkened(0.3))
			_r(img, 1, fy - 12, 1, 14, Color(0.55, 0.58, 0.62))                           # the drip on its stand
			_r(img, 0, fy - 12, 3, 4, Color(0.8, 0.92, 1.0, 0.85))
		"q_bed":                    # package 58 (Luz): a bed in the quarters – a padded headboard, pillows, a blanket in
			# the room's colour; unmade while the robot cleans; with the pilot in it while they sleep (eyes shut, or open)
			var frame := Color(0.2, 0.18, 0.24)
			_r(img, 0, fy - 6, pw, 8, frame)                                                  # the headboard
			_r(img, 1, fy - 5, pw - 2, 5, c.darkened(0.45))
			for hx in range(3, pw - 2, 5):
				_r(img, hx, fy - 4, 1, 3, c.darkened(0.25))
			_r(img, 1, fy, pw - 2, ph - 2, frame.lightened(0.15))
			_r(img, 2, fy + 1, pw - 4, ph - 5, Color(0.92, 0.92, 0.95))                      # the sheet
			var pillows := 1 if pw < 40 else 2
			for pi in pillows:
				var pxw := (pw - 6) / pillows
				_r(img, 3 + pi * (pxw + 1), fy + 2, pxw - 1, 5, Color(0.98, 0.98, 1.0))
				_r(img, 3 + pi * (pxw + 1), fy + 6, pxw - 1, 1, Color(0.8, 0.8, 0.86))
			var pat2: Dictionary = o.get("patient", {})
			if not pat2.is_empty():
				var PAq = load("res://scripts/core/pilot_art.gd")
				var sk2: Color = PAq.SKINS[int(pat2.get("skin", 2)) % PAq.SKINS.size()]
				var hr2: Color = PAq.HAIR_COLORS[int(pat2.get("hair_color", 1)) % PAq.HAIR_COLORS.size()]
				if int(pat2.get("hair", 2)) == 0:
					hr2 = sk2.darkened(0.08)
				_ellipse(img, pw * 0.5, fy + 7.0, 5.0, 4.5, sk2)
				_r(img, pw / 2 - 5, fy + 2, 10, 3, hr2)
				if bool(o.get("awake", false)):
					_r(img, pw / 2 - 2, fy + 6, 1, 2, Color(0.95, 0.95, 0.95))
					_r(img, pw / 2 + 1, fy + 6, 1, 2, Color(0.95, 0.95, 0.95))
				else:
					_r(img, pw / 2 - 2, fy + 7, 1, 1, Color(0.2, 0.15, 0.15))
					_r(img, pw / 2 + 1, fy + 7, 1, 1, Color(0.2, 0.15, 0.15))
			if bool(o.get("unmade", false)):
				_r(img, 3, fy + 12, pw - 8, ph - 18, c.darkened(0.1))                       # the blanket thrown back
				_r(img, pw - 7, fy + 10, 5, ph - 14, c.darkened(0.3))
			else:
				_r(img, 2, fy + (11 if not pat2.is_empty() else 9), pw - 4, ph - (16 if not pat2.is_empty() else 14), c)     # the blanket
				_r(img, 2, fy + (11 if not pat2.is_empty() else 9), pw - 4, 2, c.lightened(0.3))
			_r(img, 1, fy + ph - 4, 2, 3, frame.darkened(0.3))
			_r(img, pw - 3, fy + ph - 4, 2, 3, frame.darkened(0.3))
		"med_pod":                  # 0.7.51.11: the auto-surgeon – a capsule under a glass lid, its arm over it, lit
			c = Color(0.4, 0.9, 1.0)
			_r(img, 2, fy + 2, pw - 4, ph - 4, Color(0.86, 0.88, 0.9))
			_r(img, 4, fy + 4, pw - 8, ph - 9, Color(0.18, 0.3, 0.36))
			_r(img, 4, fy + 4, pw - 8, ph - 9, Color(c, 0.35))
			_r(img, 5, fy + 5, pw - 10, 2, Color(0.85, 0.97, 1.0, 0.7))                    # the glass lid's glint
			_r(img, 3, fy + ph - 4, pw - 6, 2, c)                                          # its light strip
			# 0.7.51.13: the scanner screen standing at its head – glass in a frame, lit, a scan line across (step behind it …)
			_r(img, 3, 2, 2, fy + 4, Color(0.55, 0.58, 0.62))
			_r(img, pw - 5, 2, 2, fy + 4, Color(0.55, 0.58, 0.62))
			_r(img, 3, 0, pw - 6, 3, Color(0.5, 0.52, 0.56))
			_r(img, 5, 3, pw - 10, fy - 1, Color(0.55, 0.9, 1.0, 0.28))
			_r(img, 5, 3 + (fy - 1) / 3, pw - 10, 1, Color(0.6, 1.0, 1.0, 0.75))
			_r(img, 6, 4, 2, fy - 6, Color(1, 1, 1, 0.3))
			_r(img, pw / 2 - 1, fy - 2, 2, 8, Color(0.6, 0.62, 0.66))                      # the surgeon arm over it
			_r(img, pw / 2 - 2, fy + 4, 4, 3, Color(0.4, 0.42, 0.46))
			_r(img, pw / 2 - 1, fy + 7, 2, 1, Color(1.0, 0.3, 0.3))
			_r(img, pw - 6, fy - 6, 5, 7, Color(0.08, 0.1, 0.12))                          # its screen
			_r(img, pw - 5, fy - 4, 3, 1, Color(0.4, 1.0, 0.55))
			_r(img, pw - 5, fy - 2, 2, 1, c)
		"sculpt_chair":             # 0.7.51.11: Visage's sculpting chair – reclined, its scanner ring over the head, lit
			_r(img, pw / 2 - 2, fy + ph - 6, 4, 6, metal.darkened(0.35))                   # its stand
			_r(img, 4, fy + ph - 7, pw - 8, 2, metal.darkened(0.2))
			_r(img, 3, fy + 6, pw - 6, ph - 14, Color(0.18, 0.18, 0.22))                   # seat and back, padded
			_r(img, 3, fy + 6, pw - 6, 2, Color(0.32, 0.32, 0.38))
			_r(img, 5, fy, pw - 10, 8, Color(0.22, 0.22, 0.27))                            # the headrest
			for k in 3:
				_r(img, 4, fy + 10 + k * 5, pw - 8, 1, Color(0.12, 0.12, 0.15))
			_ellipse(img, pw * 0.5, fy - 6.0, pw * 0.42, 6.0, c)                            # the scanner ring
			_ellipse(img, pw * 0.5, fy - 6.0, pw * 0.42 - 2.0, 4.0, Color(0, 0, 0, 0))
			_r(img, pw / 2 - 1, 0, 2, fy - 10, metal.darkened(0.2))                         # its arm
			_r(img, 2, fy + 8, 2, 8, c.darkened(0.3))                                       # light strips on its sides
			_r(img, pw - 4, fy + 8, 2, 8, c.darkened(0.3))
		"holo_bust":                # 0.7.51.11: a holographic bust over its pedestal – the face being made
			_r(img, 3, fy + ph - 10, pw - 6, 10, Color(0.2, 0.2, 0.25))
			_r(img, 3, fy + ph - 10, pw - 6, 2, c)
			_r(img, 5, fy + ph - 12, pw - 10, 2, Color(c, 0.6))
			var hc := Color(c.lerp(Color(0.6, 1.0, 1.0), 0.5), 0.55)
			_ellipse(img, pw * 0.5, fy + ph - 26.0, 6.0, 7.5, hc)                           # the head
			_r(img, pw / 2 - 5, fy + ph - 18, 10, 5, hc)                                    # neck and shoulders
			_r(img, pw / 2 - 9, fy + ph - 14, 18, 3, hc)
			for sl in range(fy + ph - 34, fy + ph - 12, 3):
				_r(img, pw / 2 - 9, sl, 18, 1, Color(1, 1, 1, 0.18))                        # scan lines
			_r(img, pw / 2 - 3, fy + ph - 27, 2, 1, Color(1, 1, 1, 0.8))
			_r(img, pw / 2 + 1, fy + ph - 27, 2, 1, Color(1, 1, 1, 0.8))
		"med_cabinet":              # 0.7.51.11: a medicine cabinet – white, glass doors, boxes and vials, the cross on top
			_r(img, 1, 4, pw - 2, fy + ph - 5, Color(0.9, 0.92, 0.94))
			_r(img, 1, 4, pw - 2, 1, Color(1, 1, 1))
			_r(img, 3, 7, pw - 6, fy + ph - 12, Color(0.6, 0.75, 0.82))
			for sy in range(9, fy + ph - 6, 7):
				_r(img, 3, sy + 4, pw - 6, 1, Color(0.85, 0.88, 0.9))
				for bx in range(4, pw - 5, 4):
					_r(img, bx, sy, 3, 4, [Color(0.95, 0.95, 0.95), Color(0.9, 0.4, 0.35), Color(0.4, 0.75, 0.95), Color(0.95, 0.8, 0.3)][(bx + sy) % 4])
			_r(img, pw / 2, 7, 1, fy + ph - 12, Color(0.75, 0.8, 0.84))
			_r(img, pw / 2 - 3, 3, 6, 2, Color(0.9, 0.2, 0.2))            # the cross, whole (it was cut off at the top)
			_r(img, pw / 2 - 1, 1, 2, 6, Color(0.9, 0.2, 0.2))
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
		"pillar_fallen":
			# 0.7.53.2 (Luz): a Precursor pillar lying broken – rusted iron drums, fluted, its broken ends
			var rc := Color(0.45, 0.33, 0.24)
			var n := maxi(2, pw / 12)
			for k in n:
				var x0 := k * (pw / n) + 1
				var dw := pw / n - 2
				_r(img, x0, fy - 6, dw, ph + 3, rc.darkened(0.05 * (k % 2)))
				_r(img, x0, fy - 6, dw, 2, rc.lightened(0.22))
				_r(img, x0, fy + ph - 4, dw, 3, rc.darkened(0.35))
				for fl in 3:
					_r(img, x0, fy - 2 + fl * 3, dw, 1, rc.darkened(0.2))
				for s in 6:
					_p(img, x0 + int(GroundMap.hash2(k, s, 3) * dw), fy - 4 + int(GroundMap.hash2(k, s, 4) * (ph + 2)), Color(0.55, 0.28, 0.12))
			_r(img, pw - 3, fy - 4, 3, ph, rc.darkened(0.45))
			_p(img, pw - 2, fy - 6, rc.darkened(0.45))
		"slab":
			# 0.7.53.2 (Luz): a slab come down from the ceiling – tilted, its rebar sticking out, rubble round it
			var sc := Color(0.34, 0.26, 0.2)
			for yy in ph + 6:
				var off := int(float(yy) * 0.25)
				_r(img, 1 + off, fy - 6 + yy, pw - 6, 1, sc.darkened(0.08 * float(yy) / float(ph + 6)))
			_r(img, 1, fy - 6, pw - 6, 2, sc.lightened(0.2))
			for rb in 4:
				_r(img, 4 + rb * (pw - 10) / 4, fy - 12, 1, 7, Color(0.5, 0.3, 0.18))
			for rbl in 5:
				_p(img, int(GroundMap.hash2(rbl, 9, 2) * pw), fy + ph - 2 + int(GroundMap.hash2(rbl, 9, 3) * 2), Color(0.42, 0.36, 0.3))
		"container":
			# 0.7.53.6 (Luz): a cargo container thrown out of the wreck – its lid from above (ribs across), its long
			# side facing you (ribs), the door end with its bars – or sprung open, goods spilling
			var cc: Color = o.get("col", Color(0.75, 0.35, 0.15))
			var lid_h := ph
			var face_top := rise
			_r(img, 0, 0, pw, lid_h, cc.lightened(0.12))
			for rb in range(3, pw - 2, 6):
				_r(img, rb, 1, 2, lid_h - 2, cc.lightened(0.22))
				_r(img, rb + 2, 1, 1, lid_h - 2, cc.darkened(0.05))
			_r(img, 0, 0, pw, 2, cc.lightened(0.35))
			_r(img, 0, 0, 2, lid_h, cc.lightened(0.3))
			_r(img, 0, lid_h, pw, face_top, cc.darkened(0.12))
			for rb2 in range(2, pw - 1, 4):
				_r(img, rb2, lid_h + 1, 2, face_top - 2, cc.darkened(0.02))
				_r(img, rb2 + 2, lid_h + 1, 1, face_top - 2, cc.darkened(0.32))
			_r(img, 0, lid_h, pw, 2, cc.darkened(0.45))
			_r(img, 0, lid_h + face_top - 3, pw, 3, cc.darkened(0.5))
			_r(img, 8, lid_h + 8, 22, 8, Color(0.92, 0.92, 0.88))
			_r(img, 10, lid_h + 10, 18, 1, cc.darkened(0.3))
			_r(img, 10, lid_h + 13, 12, 1, cc.darkened(0.3))
			var dx := pw - 12
			_r(img, dx, lid_h, 12, face_top, cc.darkened(0.25))
			if bool(o.get("open", false)):
				_r(img, dx + 1, lid_h + 2, 10, face_top - 4, Color(0.03, 0.03, 0.04))
			else:
				for bar in 2:
					_r(img, dx + 3 + bar * 5, lid_h + 2, 1, face_top - 4, Color(0.75, 0.75, 0.72))
					_r(img, dx + 2 + bar * 5, lid_h + 12 + bar * 4, 3, 2, Color(0.85, 0.85, 0.8))
			_ellipse(img, pw * 0.4, lid_h + 14, 6, 4, cc.darkened(0.35))
		"watchtower":
			# 0.7.53.11: four stilts of scrap, braces, a platform of plates with a rail, a roof
			var tc := Color(0.38, 0.33, 0.28)
			for lg in 2:
				_r(img, 2 + lg * (pw - 6), fy - 76, 3, ph + 76, tc)
				_r(img, 2 + lg * (pw - 6), fy - 76, 1, ph + 76, tc.lightened(0.2))
			for br in 4:
				var by := fy - 70 + br * 18
				_r(img, 3, by, pw - 6, 1, tc.darkened(0.2))
			_r(img, 0, fy - 100, pw, 24, Color(0.4, 0.38, 0.38))
			_r(img, 0, fy - 100, pw, 2, Color(0.55, 0.52, 0.5))
			_r(img, 0, fy - 80, pw, 4, Color(0.3, 0.28, 0.28))
			_r(img, -2 + 2, fy - 110, pw, 8, Color(0.5, 0.15, 0.12))
			_r(img, pw / 2 - 3, fy - 94, 6, 5, Color(0.95, 0.95, 0.85))
		"glider":
			# 0.7.53.11: a pirates' glider – a low hull, red flash, a cowl, two skids
			_r(img, 2, fy - 4, pw - 4, ph + 2, Color(0.18, 0.16, 0.16))
			_r(img, 2, fy - 4, pw - 4, 2, Color(0.3, 0.28, 0.28))
			_r(img, 6, fy - 8, pw / 2, 5, Color(0.65, 0.15, 0.12))
			_r(img, pw - 12, fy - 2, 9, 6, Color(0.25, 0.25, 0.27))
			_ellipse(img, pw * 0.35, fy - 7, 5, 3, Color(0.4, 0.6, 0.75))
			_r(img, 4, fy + ph - 2, pw - 8, 2, Color(0.12, 0.12, 0.13))
		"fire_barrel":
			# 0.7.53.11: an oil drum with a fire burning in it
			var fbc := Color(0.32, 0.32, 0.36)
			_r(img, 2, fy - 8, pw - 4, ph + 6, fbc)
			_r(img, 2, fy - 4, pw - 4, 1, fbc.darkened(0.4))
			_ellipse(img, pw * 0.5, fy - 8, (pw - 4) * 0.5, 3, Color(0.1, 0.08, 0.08))
			for fl in 6:
				_r(img, 4 + fl * 2, fy - 12 - fl % 3 * 2, 2, 4, [Color(1.0, 0.85, 0.3), Color(1.0, 0.5, 0.15), Color(0.9, 0.25, 0.1)][fl % 3])
		"valve_box":
			# 0.7.53.9: a valve housing on the floor – a grey box, pipes into the floor, a red wheel on top
			var vb := Color(0.4, 0.42, 0.44)
			_r(img, 1, fy - 18, pw - 2, ph + 16, vb)
			_r(img, 1, fy - 18, pw - 2, 3, vb.lightened(0.25))
			_r(img, pw - 3, fy - 18, 2, ph + 16, vb.darkened(0.35))
			_ellipse(img, pw * 0.5, fy - 20, 6, 3, Color(0.65, 0.14, 0.1))
			_ellipse(img, pw * 0.5, fy - 20, 3, 1.5, Color(0.1, 0.1, 0.1))
			for pi in 2:
				_r(img, 3 + pi * (pw - 10), fy + ph - 6, 4, 6, Color(0.36, 0.42, 0.48))
			_r(img, 4, fy - 8, 8, 5, Color(0.85, 0.7, 0.15))
		"cable_drum":
			# 0.7.53.9: a wooden cable drum on its side, cable wound round it
			_ellipse(img, pw * 0.5, fy + ph * 0.3, pw * 0.48, ph * 0.5 + 4, Color(0.45, 0.32, 0.2))
			for cw in 4:
				_r(img, 3, fy - 4 + cw * 3, pw - 6, 2, Color(0.15, 0.15, 0.16))
			_ellipse(img, pw * 0.5, fy + ph * 0.3, 3, 3, Color(0.25, 0.18, 0.12))
		"shaft_house":
			# 0.7.53.7 (Luz): the old mine's shaft house – corrugated walls rusting, a pitched roof, and over it the
			# headframe: two lattice legs, braces, the sheave wheel at the top, its ropes going down into the shaft
			var wl := Color(0.36, 0.31, 0.26)
			var wall_top := fy - 58
			_r(img, 0, wall_top, pw, ph + 58, wl)
			for cg in range(0, pw, 3):
				_r(img, cg, wall_top, 1, ph + 58, wl.darkened(0.18))
			for rs in 26:
				_r(img, int(GroundMap.hash2(rs, 1, 141) * (pw - 3)), wall_top + int(GroundMap.hash2(rs, 2, 141) * 56), 2, 3, Color(0.5, 0.28, 0.14))
			_r(img, 0, wall_top - 14, pw, 16, Color(0.42, 0.34, 0.27))                 # the roof
			for rf in range(0, pw, 4):
				_r(img, rf, wall_top - 14, 1, 16, Color(0.34, 0.27, 0.21))
			_r(img, 0, wall_top - 14, pw, 2, Color(0.55, 0.45, 0.36))
			for wi in [12, pw - 26]:
				_r(img, wi, wall_top + 12, 14, 10, Color(0.08, 0.08, 0.09))             # windows, broken
				_r(img, wi + 1, wall_top + 13, 5, 4, Color(0.3, 0.38, 0.42))
			var tx := pw / 2
			var tt := 4
			for side in [-1, 1]:
				for yy in range(tt, wall_top - 12):
					var xo := int(10 + (yy - tt) * 0.35)
					_r(img, tx + side * xo, yy, 2, 1, Color(0.55, 0.28, 0.16))
			for br in range(tt + 8, wall_top - 12, 10):
				var xo2 := int(10 + (br - tt) * 0.35)
				_r(img, tx - xo2, br, xo2 * 2, 1, Color(0.48, 0.24, 0.14))
			_ellipse(img, tx, tt + 4, 9, 9, Color(0.38, 0.36, 0.35))
			_ellipse(img, tx, tt + 4, 6.5, 6.5, Color(0.16, 0.15, 0.15))
			for sp in 6:
				var a := sp * TAU / 6.0
				_r(img, tx + int(cos(a) * 4), tt + 4 + int(sin(a) * 4), 2, 2, Color(0.45, 0.43, 0.41))
			_r(img, tx - 1, tt + 4, 1, wall_top - tt + 30, Color(0.15, 0.15, 0.15))
			_r(img, tx + 7, tt + 4, 1, wall_top - tt + 20, Color(0.15, 0.15, 0.15))
			_r(img, 0, fy + ph - 3, pw, 3, wl.darkened(0.45))
		"winding_house":
			# 0.7.53.7: the winding house – brick, a dark window, a chimney
			var bc := Color(0.5, 0.36, 0.28)
			_r(img, 0, fy - 30, pw, ph + 30, bc)
			for row in range(fy - 30, fy + ph, 4):
				for bx in range((row / 4) % 2 * 4, pw, 8):
					_r(img, bx, row, 7, 3, bc.lerp(bc.darkened(0.25), GroundMap.hash2(bx, row, 142)))
			_r(img, 0, fy - 36, pw, 7, Color(0.36, 0.3, 0.25))
			_r(img, pw / 2 - 6, fy - 20, 12, 10, Color(0.08, 0.08, 0.09))
			_r(img, pw - 10, fy - 50, 5, 16, Color(0.4, 0.3, 0.25))
		"ore_bin":
			# 0.7.53.7: an ore bin on stilts, rusted, its chute hanging
			var ob := Color(0.42, 0.3, 0.2)
			_r(img, 0, fy - 56, pw, 30, ob)
			_r(img, 0, fy - 56, pw, 3, ob.lightened(0.2))
			for lg in 4:
				_r(img, 2 + lg * (pw - 6) / 3, fy - 26, 3, ph + 26, ob.darkened(0.25))
			_r(img, pw / 2 - 4, fy - 26, 8, 6, Color(0.3, 0.3, 0.32))
			for rs2 in 10:
				_p(img, int(GroundMap.hash2(rs2, 1, 143) * pw), fy - 54 + int(GroundMap.hash2(rs2, 2, 143) * 26), Color(0.55, 0.3, 0.15))
		"locker_down":
			# 0.7.53.6: a ship's locker fallen on its back – its doors to the sky, one sprung
			var lc := Color(0.4, 0.45, 0.5)
			_r(img, 1, fy - 6, pw - 2, ph + 2, lc)
			_r(img, 1, fy - 6, pw - 2, 2, lc.lightened(0.25))
			_r(img, pw / 2, fy - 6, 1, ph + 2, lc.darkened(0.35))
			for sl in 3:
				_r(img, 3, fy - 3 + sl * 2, pw / 2 - 5, 1, lc.darkened(0.25))
			_r(img, pw / 2 + 2, fy - 4, pw / 2 - 5, ph - 2, Color(0.08, 0.08, 0.09))
			_r(img, 1, fy + ph - 5, pw - 2, 3, lc.darkened(0.45))
		"seats":
			# 0.7.53.6: a row of seats torn loose – backs, belts dangling
			for st in int(pw / 8):
				var sx := 1 + st * 8
				_r(img, sx, fy - 9, 7, 6, Color(0.3, 0.3, 0.42))
				_r(img, sx, fy - 9, 7, 1, Color(0.42, 0.42, 0.55))
				_r(img, sx, fy - 3, 7, 5, Color(0.36, 0.36, 0.5))
				_r(img, sx + 3, fy - 3, 1, 6, Color(0.75, 0.6, 0.2))
			_r(img, 0, fy + 2, pw, 2, Color(0.25, 0.25, 0.27))
		"pipe_bundle":
			# 0.7.53.3 (Luz): pipes run low along the floor, clamped together – cover in the sewers
			for k in 3:
				var pc: Color = [Color(0.38, 0.31, 0.24), Color(0.33, 0.35, 0.39), Color(0.3, 0.33, 0.28)][k]
				var py := fy - 6 + k * 5
				_r(img, 0, py, pw, 5, pc)
				_r(img, 0, py, pw, 1, pc.lightened(0.3))
				_r(img, 0, py + 4, pw, 1, pc.darkened(0.45))
			for cl in range(4, pw - 2, 14):
				_r(img, cl, fy - 7, 3, 16, Color(0.25, 0.25, 0.27))
				_r(img, cl, fy - 7, 3, 1, Color(0.5, 0.5, 0.52))
			for dr in 3:
				_p(img, 3 + int(GroundMap.hash2(dr, int(o.get("x", 0)), 5) * (pw - 6)), fy + 9, Color(0.35, 0.45, 0.35))
		"pump":
			# 0.7.53.3: an old pump housing – a drum on a base, a gauge, a wheel, pipes into the floor
			var hc := Color(0.33, 0.38, 0.42)
			_r(img, 1, fy + ph - 6, pw - 2, 6, hc.darkened(0.35))
			_r(img, 3, fy - 20, pw - 6, ph + 15, hc)
			_r(img, 3, fy - 20, pw - 6, 3, hc.lightened(0.25))
			_r(img, pw - 5, fy - 20, 2, ph + 15, hc.darkened(0.3))
			_ellipse(img, pw * 0.5, fy - 8, 4.5, 4.5, Color(0.85, 0.85, 0.8))
			_ellipse(img, pw * 0.5, fy - 8, 3.5, 3.5, Color(0.15, 0.15, 0.15))
			_r(img, int(pw * 0.5), fy - 10, 1, 3, Color(0.9, 0.3, 0.2))
			_r(img, 5, fy + 1, pw - 10, 2, Color(0.55, 0.15, 0.12))
			for rs in 6:
				_p(img, 4 + int(GroundMap.hash2(rs, 2, 8) * (pw - 8)), fy - 18 + int(GroundMap.hash2(rs, 3, 8) * 20), Color(0.5, 0.3, 0.15))
		"weapon_crate":
			# 0.7.53.3: an olive arms crate, stencilled, its lid ajar on a rifle
			var wc := Color(0.3, 0.36, 0.25)
			_r(img, 1, fy - 5, pw - 2, ph + 2, wc)
			_r(img, 1, fy - 5, pw - 2, 4, wc.lightened(0.2))
			_r(img, 1, fy - 1, pw - 2, 1, wc.darkened(0.4))
			_r(img, 3, fy + 3, pw - 6, 1, wc.darkened(0.25))
			_r(img, 3, fy + 8, pw - 6, 1, wc.darkened(0.25))
			_r(img, pw / 2 - 5, fy + 4, 10, 3, Color(0.85, 0.8, 0.6))
			_r(img, 4, fy - 7, pw - 10, 2, Color(0.15, 0.15, 0.16))       # a rifle on top
			_r(img, pw - 8, fy - 7, 3, 1, Color(0.6, 0.6, 0.6))
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
			for k in (0 if bool(o.get("no_balls", false)) else 6):
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
		# ---- 0.7.50.10: the settlements and what bounds them
		"tree":                     # 0.7.50.11: trees of their kind – broad jungle crowns with vines, conifers, palms
			var tc: Color = o.get("col", Color(0.18, 0.45, 0.2))
			var trng := RandomNumberGenerator.new()
			trng.seed = int(o.get("seed", absi(int(o.get("x", 0)) * 7 + int(o.get("y", 0)) * 13)))
			var total := fy + ph
			var trunk := Color(0.32, 0.22, 0.14)
			match String(o.get("species", "broad")):
				"conifer":
					_r(img, pw / 2 - 2, total - 10, 4, 10, trunk)
					for t in 5:
						var ty := total - 10 - t * 8
						var tw := pw * (0.95 - t * 0.17)
						for yy in 10:
							var ww := int(tw * (float(yy) / 10.0))
							_r(img, pw / 2 - ww / 2, ty - 10 + yy, ww, 1, tc.darkened(0.15) if yy > 6 else tc)
						_r(img, pw / 2 - int(tw * 0.25), ty - 3, int(tw * 0.2), 1, tc.lightened(0.15))
				"palm":
					for k in 9:
						_r(img, pw / 2 - 1 + (1 if k % 2 == 0 else 0) + k / 3, total - 4 - k * 4, 3, 4, Color(0.5, 0.36, 0.22).lightened(0.05 * (k % 2)))
					var top := Vector2(pw / 2 + 3, total - 38)
					for a in 8:
						var ang := -PI + a * (PI / 7.0) + trng.randf_range(-0.1, 0.1)
						for t2 in 12:
							_r(img, int(top.x + cos(ang) * t2 * 1.4), int(top.y + sin(ang) * t2 * 0.6 + t2 * t2 * 0.04), 2, 2, tc.lightened(0.12 * (t2 % 2)))
				_:
					# roots and a trunk, then a crown of many clumps – dark beneath, lit on top (0.7.50.13: to its size)
					var ks := pw / 32.0
					var tw2 := maxi(6, pw / 7)
					var th := maxi(16, int(total * 0.4))
					_r(img, pw / 2 - tw2 / 2, total - th, tw2, th, trunk)
					_r(img, pw / 2 - tw2 / 2, total - th, maxi(2, tw2 / 3), th, trunk.lightened(0.12))
					for bk2 in 3:                                # bark
						_r(img, pw / 2 - tw2 / 2 + 2 + bk2 * 2, total - th + 6 + bk2 * 9, 1, 6, trunk.darkened(0.2))
					_r(img, pw / 2 - tw2 / 2 - 4, total - 4, 5, 4, trunk.darkened(0.1))
					_r(img, pw / 2 + tw2 / 2 - 1, total - 4, 5, 4, trunk.darkened(0.1))
					var crown_y := maxf(float(total - th) - float(fy) * 0.32, float(total - th) - 12.0 * ks)    # 0.7.53.21 (Luz): a small crown sits on its trunk
					for k2 in 12:
						var rx1 := trng.randf_range(7.0, 11.0) * ks
						var cx := clampf(pw * 0.5 + trng.randf_range(-pw * 0.32, pw * 0.32), rx1 + 1.0, pw - rx1 - 1.0)     # (inside the picture)
						var cy2 := crown_y + trng.randf_range(-10.0, 8.0) * ks
						_ellipse(img, cx, cy2 + 3.0 * ks, rx1, trng.randf_range(6.0, 9.0) * ks, tc.darkened(0.3))
					for k3 in 12:
						var rx2 := trng.randf_range(6.0, 9.0) * ks
						var cx2 := clampf(pw * 0.5 + trng.randf_range(-pw * 0.3, pw * 0.3), rx2 + 1.0, pw - rx2 - 1.0)
						var cy3 := crown_y + trng.randf_range(-12.0, 4.0) * ks
						_ellipse(img, cx2, cy3, rx2, trng.randf_range(5.0, 7.0) * ks, tc.lightened(trng.randf_range(-0.05, 0.08)))
					for k4 in int(20 * ks):
						_r(img, int(pw * 0.5 + trng.randf_range(-pw * 0.3, pw * 0.25)), int(crown_y + trng.randf_range(-14.0, 0.0) * ks), 2, 1, tc.lightened(0.3))
					if bool(o.get("vines", false)):
						for v in 4:
							var vx := int(pw * 0.5 + trng.randf_range(-pw * 0.35, pw * 0.35))
							var vl := trng.randi_range(6, 14)
							for yy2 in vl:
								_p(img, vx + (yy2 / 4) % 2, int(crown_y) + 6 + yy2, tc.darkened(0.45))
							_p(img, vx, int(crown_y) + 6 + vl, Color(0.9, 0.4, 0.6) if trng.randf() < 0.4 else tc.lightened(0.2))
		"shrub":                    # undergrowth: a fern, a bush with berries or flowers
			var sc2: Color = o.get("col", Color(0.22, 0.5, 0.24))
			var srng := RandomNumberGenerator.new()
			srng.seed = int(o.get("seed", 3))
			for k5 in 5:
				_ellipse(img, pw * 0.5 + srng.randf_range(-pw * 0.3, pw * 0.3), fy + ph * 0.5 + srng.randf_range(-4.0, 3.0), srng.randf_range(4.0, 7.0), srng.randf_range(3.0, 5.0), sc2.lightened(srng.randf_range(-0.12, 0.1)))
			for k6 in 4:
				if srng.randf() < 0.5:
					_p(img, int(pw * 0.5 + srng.randf_range(-pw * 0.3, pw * 0.3)), int(fy + ph * 0.4 + srng.randf_range(-3.0, 3.0)), Color.from_hsv(srng.randf(), 0.6, 0.95))
		"tank_trap":                # 62a, part 8 (Luz): a tank trap: steel beams welded into a cross, rusted
			var st8 := Color(0.3, 0.31, 0.36)
			var gb8 := fy + ph - 1
			for q8 in 21:                                         # two beams leaning across each other
				var bx8 := int(q8 * 13.0 / 20.0)
				_r(img, pw - 3 - bx8, gb8 - q8, 2, 2, st8.darkened(0.18))
				_r(img, 1 + bx8, gb8 - q8, 2, 2, st8)
				if q8 % 5 == 2:
					_p(img, 1 + bx8, gb8 - q8, Color(0.5, 0.27, 0.14))            # rust
			for q9 in 9:                                          # the third, towards you: short, its foot on the ground
				_r(img, pw / 2 - 1, gb8 - 10 + q9, 3, 1, st8.lightened(0.1))
			_r(img, pw / 2 - 2, gb8 - 1, 5, 2, st8.darkened(0.3))
			_r(img, pw / 2 - 2, gb8 - 12, 4, 4, st8.lightened(0.22))                # the plate they are welded to
			_p(img, pw / 2 - 1, gb8 - 11, st8.lightened(0.45))
			_p(img, 2, gb8 - 20, st8.lightened(0.3))
			_p(img, pw - 3, gb8 - 20, st8.lightened(0.3))
		"rubble":                   # 62a, part 8: what is left of a wall: broken concrete in a heap, rebar sticking out of it
			var rc8: Color = o.get("col", Color(0.4, 0.41, 0.46))
			var sd8 := int(o.get("x", 0)) * 7 + pw
			_ellipse(img, pw * 0.5, fy + ph - 6.0, pw * 0.5 - 1.0, minf(ph * 0.5, 10.0), rc8.darkened(0.32))
			for k8 in maxi(5, pw / 6):                            # blocks of concrete, each its own size
				var bw8 := 6 + int(_hn(sd8 + k8, 1) * 8.0)
				var bh8 := 4 + int(_hn(sd8 + k8, 2) * 6.0)
				var bx9 := 1 + int(_hn(sd8 + k8, 3) * maxf(1.0, float(pw - bw8 - 2)))
				var by8 := fy + ph - 3 - bh8 - int(_hn(sd8 + k8, 4) * minf(12.0, ph * 0.5 + rise * 0.7))
				var bc8 := rc8.darkened(0.14 * _hn(sd8 + k8, 5)).lightened(0.08 * _hn(sd8 + k8, 6))
				_r(img, bx9, by8, bw8, bh8, bc8)
				_r(img, bx9, by8, bw8, 1, bc8.lightened(0.24))
				_r(img, bx9, by8 + bh8 - 1, bw8, 1, bc8.darkened(0.32))
				if k8 % 2 == 0:
					_r(img, bx9 + bw8 - 3, by8 + 1, 1, bh8 - 2, bc8.darkened(0.22))
			for rb8 in maxi(2, pw / 16):                          # rebar
				var rx8 := 3 + int(_hn(sd8 + rb8, 7) * (pw - 6))
				var ry8 := fy - 3 + int(_hn(sd8 + rb8, 8) * 5.0)
				_r(img, rx8, ry8, 1, 9, Color(0.5, 0.28, 0.16))
				_p(img, rx8 + 1, ry8, Color(0.5, 0.28, 0.16))
			for d8 in pw / 2:                                     # dust and small stones at its foot
				_p(img, int(_hn(sd8 + d8, 9) * pw), fy + ph - 1 - int(_hn(sd8 + d8, 10) * 3.0), rc8.darkened(0.2) if d8 % 2 == 0 else rc8.lightened(0.12))
		"wreck_car":                # 62a, part 8: a ground car, burnt out: the shell, empty frames where its glass was, a door hanging
			var cc8: Color = o.get("col", Color(0.2, 0.19, 0.21))
			var gc8 := fy + ph
			_r(img, 3, gc8 - 6, pw - 6, 5, Color(0.07, 0.07, 0.09))
			_r(img, 1, gc8 - 16, pw - 2, 11, cc8)                               # the body
			_r(img, 1, gc8 - 16, pw - 2, 1, cc8.lightened(0.2))
			_r(img, 1, gc8 - 6, pw - 2, 1, cc8.darkened(0.45))
			_r(img, pw / 5, gc8 - 25, pw * 3 / 5, 10, cc8.darkened(0.1))        # the cabin
			_r(img, pw / 5, gc8 - 25, pw * 3 / 5, 1, cc8.lightened(0.16))
			_r(img, pw / 5 + 2, gc8 - 23, pw * 3 / 10 - 3, 6, Color(0.03, 0.03, 0.05))
			_r(img, pw / 2 + 1, gc8 - 23, pw * 3 / 10 - 3, 6, Color(0.03, 0.03, 0.05))
			for rs8 in 14:                                        # rust and soot
				_p(img, 2 + int(_hn(rs8, 31) * (pw - 4)), gc8 - 15 + int(_hn(rs8, 32) * 9.0), Color(0.46, 0.22, 0.1) if rs8 % 3 != 0 else Color(0.04, 0.04, 0.04))
			_r(img, pw - 10, gc8 - 14, 2, 9, Color(0.03, 0.03, 0.05))           # where a door was
			for dq8 in 8:
				_r(img, pw - 7 + dq8 / 3, gc8 - 13 + dq8, 3, 1, cc8.lightened(0.08))
			_r(img, 3, gc8 - 12, 3, 2, Color(0.5, 0.2, 0.12))                   # what is left of a lamp
		"dropship_wreck":           # 62a, part 8: a landing ship come down long ago: the hull broken in two, a wing standing up out of the ground
			var hc8 := Color(0.3, 0.34, 0.37)
			var gd8 := fy + ph
			_ellipse(img, pw * 0.5, gd8 - 8.0, pw * 0.48, 9.0, Color(0.06, 0.06, 0.08))     # the scar it ploughed
			for wy8 in 42:                                        # the tail fin, standing up out of the break: swept, blunt at its top
				_r(img, 70 + wy8 / 2, gd8 - 44 - wy8, 30 - wy8 / 2, 1, hc8.darkened(0.24) if wy8 % 8 == 0 else hc8.lightened(0.05))
				_p(img, 70 + wy8 / 2, gd8 - 44 - wy8, hc8.lightened(0.3))
			_r(img, 86, gd8 - 80, 12, 4, Color(0.62, 0.16, 0.12))
			_r(img, 6, gd8 - 46, 62, 36, hc8.darkened(0.12))                    # the stern, lying
			_r(img, 6, gd8 - 46, 62, 3, hc8.lightened(0.16))
			_r(img, 6, gd8 - 13, 62, 3, hc8.darkened(0.42))
			for pl8 in range(14, 66, 12):
				_r(img, pl8, gd8 - 43, 1, 30, hc8.darkened(0.32))
			_r(img, 0, gd8 - 40, 8, 24, Color(0.11, 0.11, 0.14))                # its engines
			_ellipse(img, 3.5, gd8 - 28.0, 3.5, 8.0, Color(0.04, 0.04, 0.05))
			_r(img, 18, gd8 - 34, 16, 5, Color(0.62, 0.16, 0.12))               # what is left of its markings
			_r(img, 38, gd8 - 34, 5, 5, Color(0.62, 0.16, 0.12))
			for jg8 in 9:                                         # the torn edge of the break
				_r(img, 66 + (jg8 % 3) * 2, gd8 - 46 + jg8 * 4, 3 + (jg8 * 5) % 4, 4, hc8.darkened(0.28))
			for yy8 in 30:                                        # the bow, a little apart, aslant
				var off8 := yy8 / 5
				_r(img, 88 + off8, gd8 - 40 + yy8, 58 - off8 * 2, 1, hc8.darkened(0.04 * float(yy8 / 10)))
			_r(img, 88, gd8 - 40, 58, 2, hc8.lightened(0.2))
			for pl9 in range(98, 140, 14):
				_r(img, pl9, gd8 - 37, 1, 24, hc8.darkened(0.3))
			_r(img, 124, gd8 - 35, 18, 10, Color(0.04, 0.06, 0.09))             # the cockpit, its glass gone
			_p(img, 128, gd8 - 32, Color(0.5, 0.7, 0.8))
			_p(img, 136, gd8 - 28, Color(0.5, 0.7, 0.8))
			for wq8 in 12:                                        # a wing torn off, lying before it
				_r(img, 24 + wq8 * 2, gd8 - 10 + wq8 / 2, 46 - wq8 * 3, 1, hc8.darkened(0.2 + 0.02 * wq8))
			_r(img, 24, gd8 - 10, 46, 1, hc8.lightened(0.12))
			for dp8 in 7:                                         # plates of its hull, strewn
				_r(img, 78 + int(_hn(dp8, 51) * 70.0), gd8 - 7 + int(_hn(dp8, 52) * 5.0), 4 + int(_hn(dp8, 53) * 5.0), 2, hc8.darkened(0.1 + 0.2 * _hn(dp8, 54)))
			for so8 in 40:                                        # soot
				_p(img, 8 + int(_hn(so8, 41) * (pw - 16)), gd8 - 44 + int(_hn(so8, 42) * 32.0), Color(0.05, 0.05, 0.06))
		"barrier", "bulwark":       # package 52: cover in a fight – plated sections with seams, a light strip, emitters
			var hi := kind == "bulwark"
			var bc: Color = o.get("col", Color(0.4, 0.43, 0.48))
			var lc: Color = Color(1.0, 0.62, 0.18) if not hi else Color(0.35, 0.9, 1.0)
			var face_h := 30 if hi else 12          # the front face, seen from the south
			var top_d := 8                          # the depth of its top
			if pw >= ph:
				var y0 := fy + ph - face_h - top_d
				_r(img, 0, y0, pw, top_d, bc.lightened(0.18))                   # the top
				_r(img, 0, y0, pw, 1, bc.lightened(0.38))
				_r(img, 0, y0 + top_d, pw, face_h, bc.darkened(0.12))           # the front face
				_r(img, 0, y0 + top_d, pw, 1, bc.darkened(0.4))
				for x in range(0, pw, 16):                                     # its sections
					_r(img, x, y0, 1, top_d + face_h, bc.darkened(0.45))
					_p(img, x + 3, y0 + top_d + 3, bc.lightened(0.3))
					_p(img, x + 12, y0 + top_d + 3, bc.lightened(0.3))
					if hi:
						_r(img, x + 4, y0 + top_d + 9, 8, 12, bc.darkened(0.22))  # an inset plate
						_r(img, x + 4, y0 + top_d + 9, 8, 1, bc.lightened(0.1))
				_r(img, 1, y0 + top_d + face_h - 5, pw - 2, 1, lc)               # the light strip low on the face
				_r(img, 1, y0 + top_d + face_h - 2, pw - 2, 2, bc.darkened(0.5))
				for x2 in range(8, pw, 16):
					_p(img, x2, y0 + 2, lc.lightened(0.3))                      # emitters along the top
			else:
				var yt := fy - (face_h - 12) - top_d + 4
				var x0 := 3
				var ww := pw - 6
				_r(img, x0, yt, ww, fy + ph - face_h - yt, bc.lightened(0.18))   # the top along its length
				_r(img, x0, yt, 1, fy + ph - face_h - yt, bc.lightened(0.38))
				_r(img, x0 + ww - 1, yt, 1, fy + ph - face_h - yt, bc.darkened(0.3))
				for y in range(yt + 12, fy + ph - face_h, 16):
					_r(img, x0, y, ww, 1, bc.darkened(0.4))
					_p(img, x0 + ww / 2, y + 5, lc.lightened(0.3))
				_r(img, x0, fy + ph - face_h, ww, face_h, bc.darkened(0.12))      # its end face to the south
				_r(img, x0, fy + ph - face_h, ww, 1, bc.darkened(0.4))
				_r(img, x0 + 1, fy + ph - 5, ww - 2, 1, lc)
				_r(img, x0, fy + ph - 2, ww, 2, bc.darkened(0.5))
				if hi:
					_r(img, x0 + 2, fy + ph - face_h + 6, ww - 4, 12, bc.darkened(0.22))
		"rock", "lava_rock":         # 0.7.50.11: a group of boulders, each its own – facets, cracks, moss or glowing seams
			var rc: Color = o.get("col", Color(0.45, 0.43, 0.42))
			var rrng := RandomNumberGenerator.new()
			rrng.seed = int(o.get("seed", absi(int(o.get("x", 0)) * 31 + int(o.get("y", 0)) * 17)))
			var n_r := rrng.randi_range(1, 3)
			for k7 in n_r:
				var rw2 := pw * rrng.randf_range(0.28, 0.48) / (1.0 if k7 == 0 else 1.3)
				var rh2 := rw2 * rrng.randf_range(0.65, 0.95)
				var rx := pw * 0.5 + rrng.randf_range(-pw * 0.22, pw * 0.22)
				var ry := float(fy + ph) - rh2 * 0.6 - rrng.randf_range(0.0, ph * 0.3)
				_ellipse(img, rx, ry + 2.0, rw2, rh2, rc.darkened(0.3))
				_ellipse(img, rx - 1.0, ry, rw2 - 1.0, rh2 - 1.0, rc.lightened(rrng.randf_range(-0.06, 0.06)))
				_ellipse(img, rx - rw2 * 0.3, ry - rh2 * 0.35, rw2 * 0.45, rh2 * 0.3, rc.lightened(0.16))
				_r(img, int(rx + rw2 * 0.1), int(ry - rh2 * 0.2), 1, int(rh2 * 0.6), rc.darkened(0.3))
				if bool(o.get("moss", false)):
					_ellipse(img, rx - rw2 * 0.2, ry - rh2 * 0.5, rw2 * 0.55, 2.5, Color(0.3, 0.52, 0.26))
				if kind == "lava_rock":
					for k8 in int(rw2 / 2):
						_p(img, int(rx - rw2 * 0.5) + k8 * 2, int(ry + (k8 % 3) - 1), Color(1.0, 0.5, 0.15))
		# ---- 0.7.50.12: the economy areas
		"fence":                    # a wire fence – posts, wire, along its length (w > h: east-west, else north-south)
			var fc := Color(0.42, 0.42, 0.44)
			if pw >= ph:
				for x in range(0, pw, 8):
					_r(img, x, fy + ph - 14, 2, 14, fc.darkened(0.2))
					_p(img, x, fy + ph - 15, Color(0.35, 0.95, 1.0))
				for k in 3:
					_r(img, 0, fy + ph - 12 + k * 4, pw, 1, fc)
			else:
				for y in range(fy, fy + ph, 8):
					_r(img, pw / 2 - 1, y - 10, 2, 12, fc.darkened(0.2))
					_p(img, pw / 2, y - 11, Color(0.35, 0.95, 1.0))
				_r(img, pw / 2, fy - 10, 1, ph + 10, fc)
				_r(img, pw / 2 - 2, fy - 6, 1, ph + 6, fc.lightened(0.1))
		"smokestack":               # a factory chimney, banded, its top blackened
			var sc4: Color = o.get("col", Color(0.62, 0.55, 0.5))
			var sw := maxi(12, int(pw * 0.6))
			_r(img, pw / 2 - sw / 2, 4, sw, fy + ph - 4, sc4)
			_r(img, pw / 2 - sw / 2, 4, sw / 4, fy + ph - 4, sc4.lightened(0.12))
			_r(img, pw / 2 + sw / 4, 4, sw / 4, fy + ph - 4, sc4.darkened(0.2))
			for yy6 in range(8, fy + ph - 4, 8):                          # its courses of brick
				_r(img, pw / 2 - sw / 2, yy6, sw, 1, sc4.darkened(0.1))
			for yb in range(14, fy + ph - 10, 26):                       # 0.7.50.14: plated rings with light between
				_r(img, pw / 2 - sw / 2 - 1, yb, sw + 2, 5, sc4.darkened(0.35))
				_r(img, pw / 2 - sw / 2, yb + 5, sw, 1, Color(0.35, 0.95, 1.0))
			_r(img, pw / 2 - sw / 2 + 2, 6, sw - 4, 3, Color(1.0, 0.55, 0.2))   # the hot vent at its top
			_r(img, pw / 2 - sw / 2 - 1, 2, sw + 2, 4, Color(0.15, 0.13, 0.13))
			_r(img, pw / 2 - 1, 10, 2, 2, Color(1.0, 0.3, 0.25))
			for lr in range(30, fy + ph - 8, 4):                          # the ladder
				_r(img, pw / 2 + sw / 2 - 4, lr, 3, 1, Color(0.3, 0.3, 0.3))
		"flare":                    # a refinery's flare stack – the flame itself is drawn alive
			_r(img, pw / 2 - 2, 6, 4, fy + ph - 6, Color(0.55, 0.55, 0.58))
			for yy4 in range(10, fy + ph - 4, 8):
				_r(img, pw / 2 - 5, yy4, 10, 1, Color(0.4, 0.4, 0.44))
			_r(img, pw / 2 - 4, 4, 8, 3, Color(0.3, 0.3, 0.32))
		"lookout":                  # 0.7.51.6: a lookout tower – a steel lattice, a glazed cab, a beacon
			var lc2 := Color(0.32, 0.33, 0.37)
			_r(img, 3, 18, 2, fy + ph - 18, lc2)
			_r(img, pw - 5, 18, 2, fy + ph - 18, lc2)
			for yy5 in range(24, fy + ph - 4, 9):
				for t5 in pw - 8:
					_p(img, 4 + t5, yy5 + int(t5 * 8.0 / (pw - 8)), lc2.lightened(0.1))
			_r(img, 0, 14, pw, 4, lc2.lightened(0.15))
			_r(img, 0, 17, pw, 1, Color(0.35, 0.95, 1.0))
			_r(img, 2, 4, pw - 4, 10, Color(0.4, 0.62, 0.75))
			_r(img, 2, 4, pw - 4, 2, Color(0.25, 0.26, 0.3))
			_r(img, 3, 7, 4, 2, Color(0.85, 0.95, 1.0))
			_r(img, pw / 2 - 1, 1, 2, 3, Color(1.0, 0.3, 0.25))
		"heap":                     # a stockpile of ore
			var hc: Color = o.get("col", Color(0.45, 0.38, 0.3))
			_ellipse(img, pw * 0.5, fy + ph - 6.0, pw * 0.5, 12.0, hc.darkened(0.2))
			_ellipse(img, pw * 0.45, fy + ph - 9.0, pw * 0.38, 10.0, hc)
			_ellipse(img, pw * 0.38, fy + ph - 14.0, pw * 0.18, 4.0, hc.lightened(0.15))
			for k12 in 20:
				_p(img, int(pw * 0.15 + (k12 * 37) % int(pw * 0.7)), int(fy + ph - 16 + (k12 * 13) % 14), hc.darkened(0.3) if k12 % 2 else Color(0.75, 0.6, 0.35))
		"target":                   # 0.7.51.6: a practice target – a plated stand projecting rings of light
			_r(img, pw / 2 - 1, fy - 2, 3, ph + 2, Color(0.25, 0.26, 0.3))
			_r(img, pw / 2 - 3, fy + ph - 3, 7, 3, Color(0.2, 0.21, 0.24))
			_ellipse(img, pw * 0.5, fy - 5.0, 6.5, 6.5, Color(1.0, 0.35, 0.25, 0.85))
			_ellipse(img, pw * 0.5, fy - 5.0, 5.0, 5.0, Color(0.12, 0.08, 0.1, 0.6))
			_ellipse(img, pw * 0.5, fy - 5.0, 3.0, 3.0, Color(1.0, 0.45, 0.3, 0.9))
			_ellipse(img, pw * 0.5, fy - 5.0, 1.5, 1.5, Color(1.0, 0.9, 0.8))
		"tank_vehicle":             # an armoured vehicle, parked: tracks, hull, turret and gun
			var tc2: Color = o.get("col", Color(0.35, 0.4, 0.3))
			var kz := maxf(1.0, pw / 80.0)
			var gb := fy + ph
			_r(img, 3, gb - int(10 * kz), pw - 6, int(7 * kz), Color(0.18, 0.19, 0.21))     # 0.7.50.14: its hover skirt
			for tx in range(5, pw - 5, 5):
				_r(img, tx, gb - int(4 * kz), 3, 2, Color(0.35, 0.95, 1.0))
			_r(img, 2, gb - int(24 * kz), pw - 4, int(14 * kz), tc2)                        # the hull
			_r(img, 2, gb - int(24 * kz), pw - 4, 2, tc2.lightened(0.15))
			for ap in range(10, pw - 8, 16):
				_r(img, ap, gb - int(22 * kz), 1, int(11 * kz), tc2.darkened(0.2))
			_r(img, pw / 2 - int(14 * kz), gb - int(36 * kz), int(28 * kz), int(12 * kz), tc2.darkened(0.08))   # the turret
			_r(img, pw / 2 + int(12 * kz), gb - int(32 * kz), int(34 * kz), int(4 * kz), tc2.darkened(0.25))   # the gun
		"stall":                    # 0.7.51.6: a market stall – a metal counter edged with light, a plated canopy on a mast, a holo sign
			var ac: Color = o.get("col", Color(0.85, 0.3, 0.25))
			var srng2 := RandomNumberGenerator.new()
			srng2.seed = int(o.get("seed", 5))
			_r(img, 3, 12, 2, fy + ph - 12, Color(0.28, 0.29, 0.32))
			_r(img, pw - 5, 12, 2, fy + ph - 12, Color(0.28, 0.29, 0.32))
			_r(img, 1, fy + ph - 9, pw - 2, 9, Color(0.32, 0.34, 0.38))           # the counter
			_r(img, 1, fy + ph - 9, pw - 2, 1, Color(0.55, 0.58, 0.62))
			_r(img, 1, fy + ph - 3, pw - 2, 1, ac)
			for g in range(3, pw - 4, 4):
				var gc := Color.from_hsv(srng2.randf(), 0.55, 0.9)
				_r(img, g, fy + ph - 12, 3, 3, gc)
				_p(img, g, fy + ph - 12, gc.lightened(0.4))
			_r(img, 0, 6, pw, 5, Color(0.22, 0.23, 0.26))                         # the canopy, plated
			_r(img, 0, 6, pw, 1, Color(0.45, 0.47, 0.5))
			_r(img, 0, 11, pw, 1, ac)
			_r(img, pw / 2 - 7, 0, 14, 5, Color(0.05, 0.05, 0.08))                  # its holo sign
			_r(img, pw / 2 - 6, 1, 12, 1, ac.lightened(0.3))
			_r(img, pw / 2 - 6, 3, 8, 1, ac)
		"rover":                    # a parked ground rover: six wheels, a cab, a cargo bed
			var rcol: Color = o.get("col", Color(0.75, 0.55, 0.2))
			var kr := maxf(1.0, pw / 48.0)
			var gb2 := fy + ph
			for wx in [int(3 * kr), int(pw - 20 * kr)]:                 # 0.7.50.14: two hover skids
				_r(img, wx, gb2 - int(6 * kr), int(16 * kr), int(4 * kr), Color(0.2, 0.21, 0.24))
				_r(img, wx + 2, gb2 - int(2 * kr), int(16 * kr) - 4, 2, Color(0.35, 0.95, 1.0))
			_r(img, 1, gb2 - int(15 * kr), pw - 2, int(9 * kr), rcol)
			_r(img, 1, gb2 - int(15 * kr), pw - 2, 2, rcol.lightened(0.2))
			_r(img, pw - int(15 * kr), gb2 - int(25 * kr), int(13 * kr), int(10 * kr), rcol.darkened(0.1))
			_r(img, pw - int(13 * kr), gb2 - int(23 * kr), int(9 * kr), int(5 * kr), Color(0.3, 0.5, 0.65))
			_r(img, pw - int(12 * kr), gb2 - int(22 * kr), int(3 * kr), int(2 * kr), Color(0.7, 0.85, 0.95))
			_r(img, int(3 * kr), gb2 - int(13 * kr), pw - int(20 * kr), int(5 * kr), rcol.darkened(0.25))
			for cg in range(int(5 * kr), pw - int(20 * kr), 6):
				_r(img, cg, gb2 - int(18 * kr), 4, int(3 * kr), Color(0.45, 0.4, 0.32))      # cargo in its bed
			_r(img, pw - 3, gb2 - int(13 * kr), 2, 2, Color(1.0, 0.95, 0.75))
		"signpost":                 # 0.7.51.6: a wayfinding pylon – three lit arrow plates
			_r(img, pw / 2 - 1, 2, 4, fy + ph - 2, Color(0.22, 0.23, 0.26))
			_r(img, pw / 2 - 1, 2, 1, fy + ph - 2, Color(0.4, 0.42, 0.46))
			_r(img, pw / 2 - 2, fy + ph - 4, 6, 4, Color(0.18, 0.19, 0.22))
			fy = 2 + 20                                    # the plates near its top
			for k10 in 3:
				var sc3: Color = [Color(0.35, 0.95, 1.0), Color(1.0, 0.75, 0.3), Color(0.45, 1.0, 0.6)][k10]
				var left := k10 % 2 == 0
				var ax := pw / 2 - (11 if left else -3)
				_r(img, ax, fy - 18 + k10 * 6, 12, 5, Color(0.06, 0.07, 0.09))
				_r(img, ax + 1, fy - 16 + k10 * 6, 10, 1, sc3)
				_p(img, ax + (0 if left else 11), fy - 16 + k10 * 6, sc3.lightened(0.4))
		"cable_pole":               # 0.7.51.6: a power mast – a steel conduit with its energy line, a junction box, a beacon
			_r(img, pw / 2 - 2, 4, 4, fy + ph - 4, Color(0.3, 0.31, 0.35))
			_r(img, pw / 2 - 2, 4, 1, fy + ph - 4, Color(0.48, 0.5, 0.54))
			_r(img, pw / 2, 10, 1, fy + ph - 16, Color(0.35, 0.95, 1.0))
			_r(img, pw / 2 - 7, 8, 15, 3, Color(0.25, 0.26, 0.3))
			for k11 in 3:
				_r(img, pw / 2 - 6 + k11 * 6, 6, 2, 2, Color(0.35, 0.95, 1.0))
			_r(img, pw / 2 + 2, 24, 5, 8, Color(0.36, 0.38, 0.42))
			_r(img, pw / 2 + 3, 26, 2, 2, Color(0.4, 1.0, 0.55))
			_r(img, pw / 2 - 1, 1, 2, 2, Color(1.0, 0.3, 0.25))
		"dune":
			var dc: Color = o.get("col", Color(0.85, 0.7, 0.45))
			_ellipse(img, pw * 0.5, fy + ph * 0.6, pw * 0.5, ph * 0.45 + 3.0, dc.darkened(0.12))
			_ellipse(img, pw * 0.45, fy + ph * 0.5, pw * 0.42, ph * 0.35 + 2.0, dc)
			_ellipse(img, pw * 0.35, fy + ph * 0.4, pw * 0.2, 2.0, dc.lightened(0.15))
		"arcade":                   # 54b (Luz): the Rock Hopper cabinet – dark sides, the lit marquee, the glowing screen, the controls
			var cab := Color(0.14, 0.1, 0.16)
			_r(img, 1, 2, pw - 2, fy + ph - 3, cab)
			_r(img, 1, 2, 2, fy + ph - 3, cab.lightened(0.12))
			_r(img, pw - 3, 2, 2, fy + ph - 3, cab.darkened(0.3))
			_r(img, 3, 3, pw - 6, 4, c)                           # the marquee
			_r(img, 4, 4, pw - 8, 1, c.lightened(0.4))
			_r(img, 3, 9, pw - 6, 9, Color(0.02, 0.03, 0.06))      # the screen
			_r(img, 5, 12, 2, 2, Color(1.0, 0.75, 0.2))
			_r(img, 9, 14, 3, 2, Color(0.6, 0.55, 0.7))
			_r(img, 7, 11, 1, 1, Color(0.4, 1.0, 0.9))
			for sy in range(9, 18, 2):
				_r(img, 3, sy, pw - 6, 1, Color(0.4, 1.0, 0.9, 0.12))
			_r(img, 2, 19, pw - 4, 4, cab.lightened(0.18))           # the control panel
			_r(img, 4, 20, 2, 2, Color(0.9, 0.9, 0.95))
			_r(img, 9, 20, 2, 2, Color(1.0, 0.3, 0.3))
			_r(img, 12, 20, 2, 2, Color(0.4, 1.0, 0.9))
		"dart_board":               # 54b (Luz): a dartboard on a stand – the post, the round board with its rings, a chalk tally
			var cx := pw * 0.5
			var post := Color(0.25, 0.25, 0.28)
			_r(img, int(cx) - 1, 10, 2, fy + ph - 12, post)
			_ellipse(img, cx, fy + ph - 2.0, 5.0, 1.5, post.darkened(0.3))
			_ellipse(img, cx, 9.0, 8.0, 8.0, Color(0.32, 0.18, 0.1))
			_ellipse(img, cx, 9.0, 6.5, 6.5, Color(0.12, 0.12, 0.12))
			_ellipse(img, cx, 9.0, 5.5, 5.5, Color(0.85, 0.15, 0.15))
			_ellipse(img, cx, 9.0, 4.8, 4.8, Color(0.92, 0.86, 0.68))
			_ellipse(img, cx, 9.0, 3.3, 3.3, Color(0.15, 0.6, 0.25))
			_ellipse(img, cx, 9.0, 2.6, 2.6, Color(0.1, 0.1, 0.1))
			_ellipse(img, cx, 9.0, 1.0, 1.0, Color(0.85, 0.15, 0.15))
			_r(img, int(cx) + 4, 6, 1, 3, Color(0.3, 0.8, 1.0))
		"crystal":                  # 54a: a cluster of crystals – six-sided prisms leaning out of a foot of rime, lit from the left
			var ic: Color = o.get("col", Color(0.75, 0.9, 1.0))
			var crng := RandomNumberGenerator.new()
			crng.seed = int(o.get("seed", 9))
			_ellipse(img, pw * 0.5, fy + ph - 4.0, pw * 0.5, 4.5, Color(0.88, 0.93, 0.98))       # the rime at its foot
			_ellipse(img, pw * 0.5, fy + ph - 5.0, pw * 0.32, 2.5, ic.darkened(0.45))            # the stone they grow out of
			var prisms: Array = []
			for k5 in crng.randi_range(4, 7):
				prisms.append([crng.randf_range(0.18, 0.82) * pw, crng.randi_range(int((fy + ph) * 0.35), fy + ph - 6), crng.randf_range(-0.35, 0.35), crng.randi_range(2, 4)])
			prisms.sort_custom(func(a, b): return int(a[1]) > int(b[1]))      # the tall ones behind
			for pr in prisms:
				var bx := float(pr[0])
				var hh := int(pr[1])
				var lean := float(pr[2])
				var hwid := int(pr[3])
				for yy in hh:
					var t := float(yy) / hh
					var wv := hwid if t < 0.72 else maxi(0, int(round(hwid * (1.0 - t) / 0.28)))
					var cxp := int(bx + lean * yy)
					var y := fy + ph - 5 - yy
					for xx in range(-wv - 1, wv + 2):
						var cq: Color
						if absi(xx) == wv + 1:
							cq = ic.darkened(0.5)                                  # its outline
						elif xx < 0:
							cq = ic.lightened(0.38)                                # the lit face
						elif xx == 0:
							cq = ic.lightened(0.7)                                 # the edge between the faces
						else:
							cq = ic.darkened(0.12)                                 # the face in shade
						if absi(xx) <= wv and yy % 7 == 3 and xx != 0:
							cq = cq.lightened(0.15)                                 # a growth line
						if xx == -1 and t > 0.15 and t < 0.6:
							cq = Color(1, 1, 1)                                    # the light inside it
						_r(img, cxp + xx, y, 1, 1, cq)
		"house":                    # a settlement building: its roof seen from above, its front with a door and windows
			var roof: Color = o.get("col", Color(0.4, 0.4, 0.45))
			var wall: Color = o.get("col2", metal)
			var fh := 22
			var roof_h := fy + ph - fh
			_r(img, 0, 2, pw, roof_h - 2, roof)
			_r(img, 0, 2, pw, 2, roof.lightened(0.2))
			_r(img, 0, roof_h - 2, pw, 2, roof.darkened(0.3))
			for sx in range(6, pw - 4, 12):                 # vents, a unit on the roof
				_r(img, sx, 8, 6, 4, roof.darkened(0.15))
			_r(img, 0, roof_h, pw, fh, wall)
			_r(img, 0, roof_h, pw, 2, wall.darkened(0.3))
			var door_x := int(o.get("door", pw / 2 - 5))
			_r(img, door_x, roof_h + 6, 10, fh - 6, Color(0.14, 0.14, 0.18))
			_r(img, door_x + 1, roof_h + 7, 8, 2, Color(o.get("lamp", Color(1.0, 0.85, 0.5))))
			for wx in range(4, pw - 8, 14):
				if wx > door_x - 10 and wx < door_x + 12:
					continue
				_r(img, wx, roof_h + 7, 8, 7, Color(0.1, 0.12, 0.16))
				_r(img, wx + 1, roof_h + 8, 6, 5, Color(o.get("win", Color(1.0, 0.85, 0.55))))
		"tower_rig":                # a mine's headframe: two legs, cross braces, the wheel on top
			var mc := metal.darkened(0.2)
			var top := 4
			_r(img, 3, top + 10, 3, fy + ph - top - 10, mc)
			_r(img, pw - 6, top + 10, 3, fy + ph - top - 10, mc)
			for yy2 in range(top + 14, fy + ph - 6, 12):
				for t2 in pw - 8:
					_p(img, 4 + t2, yy2 + int(t2 * 10.0 / (pw - 8)), mc.lightened(0.1))
			_ellipse(img, pw * 0.5, top + 8.0, 8.0, 8.0, mc.darkened(0.2))
			_ellipse(img, pw * 0.5, top + 8.0, 5.0, 5.0, Color(0, 0, 0, 0))
			_r(img, pw / 2 - 1, top + 8, 2, fy + ph - top - 10, Color(0.15, 0.15, 0.17))
			_r(img, pw / 2, top + 16, 1, fy + ph - top - 24, Color(0.35, 0.95, 1.0))     # 0.7.50.14: its energy core
			for cl2 in range(top + 20, fy + ph - 8, 22):
				_r(img, pw / 2 - 3, cl2, 6, 2, Color(0.35, 0.95, 1.0))
			_r(img, 0, fy + ph - 5, pw, 5, Color(0.3, 0.28, 0.25))
			_r(img, pw / 2 - 2, top, 4, 3, Color(1.0, 0.3, 0.2))
		"silo":
			var scol: Color = o.get("col", Color(0.7, 0.7, 0.68))
			_r(img, 2, 10, pw - 4, fy + ph - 12, scol)
			_r(img, 2, 10, 4, fy + ph - 12, scol.lightened(0.15))
			_r(img, pw - 6, 10, 4, fy + ph - 12, scol.darkened(0.2))
			_ellipse(img, pw * 0.5, 10.0, pw * 0.5 - 2.0, maxf(7.0, pw * 0.16), scol.lightened(0.1))
			for yy3 in range(16, fy + ph - 4, 9):
				_r(img, 2, yy3, pw - 4, 1, scol.darkened(0.15))
			_r(img, 2, int((fy + ph) * 0.55), pw - 4, 2, Color(0.35, 0.95, 1.0, 0.9))   # 0.7.50.14: its light band
			for sl in 3:
				_r(img, int(pw * 0.2) + sl * int(pw * 0.25), int((fy + ph) * 0.55) - 5, 2, 2, Color(0.4, 1.0, 0.55) if sl != 1 else Color(1.0, 0.7, 0.2))
			if pw >= 64:                                  # a big tank: a stair winding up, a railing on top
				for st2 in 12:
					_r(img, 6 + st2 * (pw - 14) / 12, fy + ph - 6 - st2 * (fy + ph - 20) / 12, 6, 2, scol.darkened(0.35))
				_r(img, 4, 6, pw - 8, 1, scol.darkened(0.3))
		"greenhouse":
			var gc := Color(0.55, 0.85, 0.7, 1.0)
			_r(img, 1, 6, pw - 2, fy + ph - 7, Color(0.22, 0.4, 0.28))
			for gx in range(3, pw - 3, 4):
				_r(img, gx, 8, 2, fy + ph - 11, Color(0.3, 0.6, 0.32))
			_r(img, 1, 6, pw - 2, 2, gc)
			for fx2 in range(1, pw, 8):
				_r(img, fx2, 6, 1, fy + ph - 7, gc.darkened(0.2))
		"dish":                     # a dish antenna on its mount – tipped up towards the sky
			var dry := maxf(9.0, pw * 0.22)
			var dcy := 6.0 + dry
			var mw := maxi(4, pw / 10)
			_r(img, pw / 2 - mw / 2, int(dcy), mw, fy + ph - int(dcy), metal.darkened(0.2))
			_r(img, pw / 2 - mw, fy + ph - 10, mw * 2, 10, metal.darkened(0.3))            # its base
			_ellipse(img, pw * 0.5, dcy + 2.0, pw * 0.47, dry, metal.darkened(0.15))
			_ellipse(img, pw * 0.5, dcy, pw * 0.45, dry - 1.0, metal.lightened(0.15))
			_ellipse(img, pw * 0.5, dcy - 1.0, pw * 0.36, dry * 0.7, metal.darkened(0.05))
			for rib in 5:
				_r(img, int(pw * 0.15 + rib * pw * 0.175), int(dcy - dry * 0.6), 1, int(dry * 1.2), metal.darkened(0.12))
			_r(img, pw / 2 - 1, 2, 2, int(dcy) - 2, metal.darkened(0.3))           # the feed on its struts
			_r(img, pw / 2 - 3, 1, 6, 4, metal.darkened(0.35))
			_r(img, pw / 2 - 2, 2, 4, 2, Color(0.35, 0.95, 1.0))                     # 0.7.50.14: the emitter glowing
			_ellipse(img, pw * 0.5, dcy - 1.0, pw * 0.12, dry * 0.25, Color(0.35, 0.95, 1.0, 0.5))
			_r(img, pw / 2 - 1, 0, 2, 2, Color(1.0, 0.3, 0.25))
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
			# a bench facing up, from behind: its backrest towards you, the sitters' shoulders and heads over it
			var b7 := fy + ph
			_r(img, 1, b7 - 14, pw - 2, 7, c.darkened(0.35))
			_r(img, 1, b7 - 14, pw - 2, 1, c.lightened(0.1))
			_r(img, 1, b7 - 8, pw - 2, 1, c.darkened(0.5))
			_r(img, 3, b7 - 13, 2, 6, metal.darkened(0.4))
			_r(img, pw - 5, b7 - 13, 2, 6, metal.darkened(0.4))
		"fridge":
			_r(img, 2, fy - 14, pw - 4, ph + 12, Color(0.75, 0.8, 0.85))
			_r(img, 3, fy - 13, pw - 6, 10, Color(0.3, 0.6, 0.8, 0.8))
			for k in int((pw - 8) / 4):
				_r(img, 4 + k * 4, fy - 11, 2, 6, [Color(0.9, 0.3, 0.2), Color(0.3, 0.8, 0.4), Color(0.95, 0.8, 0.3)][k % 3])


## Snow on an object (package 62a, part 9: Whiteout): a cap of it on whatever is the top of each column of its
## picture, thicker here and thinner there, a shade of blue under it; and now and then some lying on a ledge.
static func _snow(img: Image) -> void:
	var iw := img.get_width()
	var ih := img.get_height()
	var white := Color(0.95, 0.97, 1.0)
	var shade := Color(0.72, 0.82, 0.96)
	for x in iw:
		var top := -1
		for y in ih:
			if img.get_pixel(x, y).a > 0.6:
				top = y
				break
		if top < 0 or top > ih - 5:
			continue
		var deep := 2 + int(_hn(x / 3, 91) * 2.4)
		for q in deep:
			if top + q < ih and img.get_pixel(x, top + q).a > 0.6:
				img.set_pixel(x, top + q, white if q < deep - 1 else shade)
		if top > 0 and _hn(x / 2, 93) > 0.45:
			img.set_pixel(x, top - 1, white)                # (it lies a little above the edge here and there)


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
