class_name StationArt
extends RefCounted
## Modular pixel-art stations (phase 0.5 package 6).
## A station is assembled from parts (hub, rings, docking arms with hangar bays, solar wings,
## greenhouse domes, refinery towers, tanks, cooling towers, dishes, armour, turrets, shipyard
## gantries, wreck hulls …). Every part writes a material and a height into a canvas; one shading
## pass turns heights into light, shadow and outlines, so all parts share the same pixel-art look.
## Type and tier decide which parts and how many – every type has its own silhouette.
## Besides the texture the builder returns the "live" points the station animates and uses:
## docking bays (mouth, direction, size), blinking lights, neon signs, steam/smoke vents and
## turret mounts (all in km relative to the station centre).

const PX := 4.0                                   # km per art pixel (same as ships)
const SIZE := {1: 240, 2: 320, 3: 400}            # canvas size (art px) by tier
const BAY_W := 46.0                               # hangar bay width / depth (art px) – an L hull is 38 x 30
const BAY_D := 50.0

enum {NONE, HULL, DARK, ACC, GLASS, SOLAR, GREEN, TANK, RUST, HANGAR, TRUSS, HOT, ICE, NEON, PANEL, ROCK, GUN, MARK, STAIN, CRYST}
enum {P_FLAT, P_PLATES, P_WINDOWS, P_CYL, P_SOLAR, P_TRUSS, P_HAZARD, P_ARMOR, P_BLOCK, P_RIBS, P_BAY, P_GIRDER}
enum {D_FLAT, D_DOME, D_TANK, D_GREEN, D_DISH, D_COOL, D_HUB, D_TURRET, D_ROCK, D_HOTTOWER}

static var _cache := {}

var n := 240
var c := 120.0
var mat := PackedByteArray()
var hgt := PackedFloat32Array()
var rng := RandomNumberGenerator.new()
var acc := Color.WHITE
var type := ""
var tier := 1
var bays: Array = []      # {pos, dir, width, depth} in art px relative to the centre
var lights: Array = []    # {pos, col, rate, phase, strobe}
var turrets: Array = []   # Vector2
var neons: Array = []     # {pos, ang, len, wid}
var vents: Array = []     # {pos, kind ("steam" / "smoke" / "spark" / "glow"), size}
var pads: Array = []      # package 26: landing pads {pos, radius, dir, hatch}


## Texture + live points for a station / haven dictionary (cached per type, tier and seed).
static func build(data: Dictionary) -> Dictionary:
	var t: String = data.get("art", data.get("type", "trade"))      # package 39: landmarks have an art of their own
	var tr := clampi(int(data.get("tier", 1)), 1, 3)
	var sd := int(data.get("seed", 1))
	var key := "%s_%d_%d" % [t, tr, sd]
	if _cache.has(key):
		return _cache[key]
	var a := StationArt.new()
	a._setup(t, tr, sd)
	match t:
		"trade":
			a._trade()
		"industry":
			a._industry()
		"mining_colony":
			a._mining()
		"agri":
			a._agri()
		"research":
			a._research()
		"military":
			a._military()
		"ice_refinery":
			a._ice()
		"shipyard":
			a._shipyard()
		"pirate_haven":
			a._haven()
		"waystation":
			a._waystation()
		"vote":
			a._vote()
		"vote_relay":
			a._vote_relay()
		"concord_yards":
			a._concord_yards()
		"res_publica":
			a._res_publica()
		"cathedral":
			a._cathedral()
		"pilgrim_gate":
			a._pilgrim_gate()
		"forge":
			a._forge()
		"lux_aeterna":
			a._lux_aeterna()
		"dyson_hub":
			a._dyson_hub()
		"mirror":
			a._mirror()
		"gate_frame":
			a._gate_frame()
		"axiom_yards":
			a._axiom_yards()
		_:
			a._trade()
	var img := a._render()
	var out := {
		"texture": ImageTexture.create_from_image(img), "size": a.n * PX, "radius": a.n * PX * 0.45,
		"bays": [], "lights": [], "turrets": [], "neons": [], "vents": [], "pads": [],
	}
	for pd in a.pads:
		out["pads"].append({"pos": (pd["pos"] as Vector2) * PX, "radius": float(pd["radius"]) * PX, "dir": pd["dir"], "hatch": float(pd["hatch"]) * PX})
	for b in a.bays:
		out["bays"].append({"pos": (b["pos"] as Vector2) * PX, "dir": b["dir"], "width": float(b["width"]) * PX, "depth": float(b["depth"]) * PX})
	for l in a.lights:
		var l2: Dictionary = l.duplicate()
		l2["pos"] = (l["pos"] as Vector2) * PX
		out["lights"].append(l2)
	for tp in a.turrets:
		out["turrets"].append((tp as Vector2) * PX)
	for ne in a.neons:
		var n2: Dictionary = ne.duplicate()
		n2["pos"] = (ne["pos"] as Vector2) * PX
		n2["len"] = float(ne["len"]) * PX
		n2["wid"] = float(ne["wid"]) * PX
		out["neons"].append(n2)
	for v in a.vents:
		var v2: Dictionary = v.duplicate()
		v2["pos"] = (v["pos"] as Vector2) * PX
		v2["size"] = float(v["size"]) * PX
		out["vents"].append(v2)
	_cache[key] = out
	return out


func _setup(t: String, tr: int, sd: int) -> void:
	type = t
	tier = tr
	rng.seed = sd
	n = int(SIZE[tier])
	if t == "shipyard":
		n = 320 + 60 * (tier - 1)
	elif t == "pirate_haven":
		n = 260 + 40 * (tier - 1)
	elif t == "waystation":
		n = 200 + 30 * (tier - 1)
	elif LANDMARK_SIZE.has(t):
		n = int(LANDMARK_SIZE[t])                      # package 39
	c = n * 0.5
	mat.resize(n * n)
	mat.fill(NONE)
	hgt.resize(n * n)
	hgt.fill(-1.0)
	acc = PixelArt.STATION_ACCENT.get(t, Color(0.3, 0.85, 1.0))
	if ASSEMBLY_ARTS.has(t):
		acc = Color(0.35, 0.62, 1.0)                  # Assembly blue
	if COVENANT_ARTS.has(t):
		acc = Color(1.0, 0.78, 0.3)                   # Covenant gold
	if DIRECTORATE_ARTS.has(t):
		acc = Color(0.3, 0.95, 0.6)                   # Directorate green


# ================================================================ Primitives

func P(r: float, ang: float) -> Vector2:
	return Vector2(c + cos(ang) * r, c + sin(ang) * r)


func _put(x: int, y: int, m: int, h: float, force: bool = false) -> void:
	if x < 0 or y < 0 or x >= n or y >= n:
		return
	var i := y * n + x
	if force or h >= hgt[i]:
		mat[i] = m
		hgt[i] = h if m != NONE else -1.0


## Oriented box: centre, angle, half length (along the angle), half width.
func box(p: Vector2, ang: float, hl: float, hw: float, m: int, h: float, pat: int = P_FLAT, force: bool = false) -> void:
	var ca := cos(ang)
	var sa := sin(ang)
	var ex := absf(ca) * hl + absf(sa) * hw
	var ey := absf(sa) * hl + absf(ca) * hw
	for y in range(int(floor(p.y - ey)), int(ceil(p.y + ey)) + 1):
		for x in range(int(floor(p.x - ex)), int(ceil(p.x + ex)) + 1):
			var dx := x + 0.5 - p.x
			var dy := y + 0.5 - p.y
			var u := dx * ca + dy * sa
			var v := -dx * sa + dy * ca
			if absf(u) > hl or absf(v) > hw:
				continue
			var mm := m
			var hh := h
			var iu := int(floor(u + hl))
			var iv := int(floor(v + hw))
			match pat:
				P_PLATES:
					if iu % 7 == 0 or (iv % 9 == 0 and hw > 6.0):
						mm = DARK
				P_WINDOWS:
					if iu % 9 == 0:
						mm = DARK
					elif absf(v) < hw * 0.4 and iu % 3 == 1 and absf(u) < hl - 3.0:
						mm = GLASS
				P_CYL:
					hh = h + sqrt(maxf(0.0, 1.0 - pow(v / hw, 2.0))) * hw * 0.7
					if iu % 10 == 0:
						mm = DARK
					elif absf(v) < 1.2 and iu % 3 == 1 and absf(u) < hl - 3.0:
						mm = GLASS
				P_SOLAR:
					if iu % 5 == 0 or iv % 4 == 0 or absf(v) > hw - 1.0:
						mm = TRUSS
					else:
						mm = SOLAR
				P_TRUSS:
					if absf(v) > hw - 1.2 or absf(u) > hl - 1.2:
						mm = TRUSS
					elif posmod(iu + iv, 6) == 0 or posmod(iu - iv, 6) == 0:
						mm = TRUSS
					else:
						continue
				P_HAZARD:
					mm = ACC if posmod(iu + iv, 6) < 3 else DARK
				P_ARMOR:
					hh = h + minf(minf(hw - absf(v), hl - absf(u)), 3.0) * 0.9
					if iu % 12 == 0 or iv % 12 == 0:
						mm = DARK
				P_BLOCK:
					hh = h + minf(minf(hw - absf(v), hl - absf(u)), 2.0)
					if iu % 8 == 4 and iv % 8 == 4:
						mm = DARK
					elif iu % 8 == 4 and iv % 8 == 5:
						mm = GLASS
				P_BAY:
					# hangar floor: darker towards the back, centre guide line, light strips on the walls
					hh = -clampf((hl - u) / (2.0 * hl), 0.0, 1.0)
					if absf(v) < 0.8 and iu % 6 < 4 and u < hl - 2.0:
						mm = MARK
					elif absf(v) > hw - 1.6 and iu % 5 == 2:
						mm = GLASS
						hh = 0.0
				P_GIRDER:
					# solid beam with lightening holes
					if absf(v) < hw - 1.5 and iu % 8 > 1 and iu % 8 < 6:
						mm = DARK
				P_RIBS:
					# ship hull under construction: ribs, plated sections and open gaps
					if iu % 5 == 0:
						mm = TRUSS
					elif posmod(iu / 5 + int(v > 0.0), 3) == 0:
						continue
			_put(x, y, mm, hh, force)


## Filled polygon with bevelled edges and a plate grid (armoured bodies, platforms).
func poly(pts: PackedVector2Array, m: int, h: float, bevel: float = 3.0, grid: int = 12) -> void:
	var lo := pts[0]
	var hi := pts[0]
	for q in pts:
		lo = Vector2(minf(lo.x, q.x), minf(lo.y, q.y))
		hi = Vector2(maxf(hi.x, q.x), maxf(hi.y, q.y))
	var cnt := pts.size()
	for y in range(int(floor(lo.y)), int(ceil(hi.y)) + 1):
		for x in range(int(floor(lo.x)), int(ceil(hi.x)) + 1):
			var p := Vector2(x + 0.5, y + 0.5)
			if not Geometry2D.is_point_in_polygon(p, pts):
				continue
			var d := INF
			for i in cnt:
				d = minf(d, p.distance_to(Geometry2D.get_closest_point_to_segment(p, pts[i], pts[(i + 1) % cnt])))
			var mm := m
			if grid > 0 and (posmod(x - int(c), grid) == 0 or posmod(y - int(c), grid) == 0) and d > bevel:
				mm = DARK
			_put(x, y, mm, h + minf(d, bevel) * 0.9)


func regular(center: Vector2, r: float, sides: int, rot: float = 0.0) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in sides:
		out.append(center + Vector2.from_angle(rot + k * TAU / sides) * r)
	return out


func seg(a: Vector2, b: Vector2, hw: float, m: int, h: float, pat: int = P_FLAT, force: bool = false) -> void:
	var d := b - a
	box((a + b) * 0.5, d.angle(), d.length() * 0.5, hw, m, h, pat, force)


func disc(p: Vector2, r: float, m: int, h: float, pat: int = D_FLAT) -> void:
	for y in range(int(floor(p.y - r)), int(ceil(p.y + r)) + 1):
		for x in range(int(floor(p.x - r)), int(ceil(p.x + r)) + 1):
			var dx := x + 0.5 - p.x
			var dy := y + 0.5 - p.y
			var d := sqrt(dx * dx + dy * dy)
			if d > r:
				continue
			var q := d / r
			var mm := m
			var hh := h
			match pat:
				D_DOME:
					hh = h + sqrt(maxf(0.0, r * r - d * d)) * 0.7
				D_TANK:
					hh = h + sqrt(maxf(0.0, r * r - d * d)) * 0.7
					if absf(q - 0.62) < 0.06 or (absf(dx) < 0.8 and q > 0.3):
						mm = DARK
				D_GREEN:
					hh = h + sqrt(maxf(0.0, r * r - d * d)) * 0.6
					var ang := atan2(dy, dx)
					if posmod(int(floor(ang / TAU * 16.0)), 2) == 0 and absf(fposmod(ang / TAU * 16.0, 1.0) - 0.5) > 0.42:
						mm = TRUSS
					elif absf(q - 0.5) < 0.05 or q > 0.92:
						mm = TRUSS
					else:
						mm = GREEN
				D_DISH:
					hh = h + q * r * 0.45
					if q < 0.13:
						mm = HULL
						hh = h + r * 0.5
					elif q > 0.9:
						mm = DARK
					elif posmod(int(floor(atan2(dy, dx) / TAU * 12.0)), 2) == 0 and absf(q - 0.55) < 0.03:
						mm = TRUSS
				D_COOL:
					if q > 0.72:
						hh = h + (1.0 - absf(q - 0.86) / 0.14) * r * 0.25
						mm = m
					else:
						mm = HANGAR
						hh = h - 2.0
				D_HOTTOWER:
					hh = h + sqrt(maxf(0.0, r * r - d * d)) * 0.5
					if q < 0.32:
						mm = HOT
					elif q < 0.42:
						mm = DARK
					elif absf(q - 0.75) < 0.05:
						mm = DARK
				D_HUB:
					hh = h + sqrt(maxf(0.0, r * r - d * d)) * 0.55
					if q < 0.3:
						mm = ACC
					elif q < 0.38:
						mm = DARK
					elif absf(q - 0.68) < 0.05 and posmod(int(floor(atan2(dy, dx) / TAU * 40.0)), 2) == 0:
						mm = GLASS
					elif absf(q - 0.86) < 0.03:
						mm = DARK
				D_TURRET:
					hh = h + sqrt(maxf(0.0, r * r - d * d)) * 0.6
					mm = GUN if q < 0.55 else DARK
				D_ROCK:
					hh = h + sqrt(maxf(0.0, r * r - d * d)) * 0.6 + (rng.randf() - 0.5) * 1.5
			_put(x, y, mm, hh)


func ring(p: Vector2, r0: float, r1: float, m: int, h: float, windows: bool = true, segs: int = 16) -> void:
	var rm := (r0 + r1) * 0.5
	var hw := (r1 - r0) * 0.5
	for y in range(int(floor(p.y - r1)), int(ceil(p.y + r1)) + 1):
		for x in range(int(floor(p.x - r1)), int(ceil(p.x + r1)) + 1):
			var dx := x + 0.5 - p.x
			var dy := y + 0.5 - p.y
			var d := sqrt(dx * dx + dy * dy)
			if d < r0 or d > r1:
				continue
			var t := (d - rm) / hw
			var ang := atan2(dy, dx)
			var mm := m
			var hh := h + sqrt(maxf(0.0, 1.0 - t * t)) * hw * 0.8
			var along := fposmod(ang / TAU * float(segs), 1.0)
			if along < 0.04:
				mm = DARK
			elif windows and absf(t) < 0.3 and posmod(int(floor(ang * rm / 2.5)), 2) == 0:
				mm = GLASS
			_put(x, y, mm, hh)


func erase_disc(p: Vector2, r: float) -> void:
	for y in range(int(floor(p.y - r)), int(ceil(p.y + r)) + 1):
		for x in range(int(floor(p.x - r)), int(ceil(p.x + r)) + 1):
			if Vector2(x + 0.5, y + 0.5).distance_to(p) <= r:
				_put(x, y, NONE, -1.0, true)


func light(p: Vector2, col: Color, rate: float = 1.5, strobe: bool = false) -> void:
	lights.append({"pos": p - Vector2(c, c), "col": col, "rate": rate, "phase": rng.randf() * TAU, "strobe": strobe})


func turret(p: Vector2, r: float = 6.0) -> void:
	for k in 8:
		var q := p + Vector2.from_angle(k * TAU / 8.0) * (r + 2.0)
		if _m(int(q.x), int(q.y)) == HANGAR or _m(int(p.x), int(p.y)) == HANGAR:
			return
	disc(p, r, DARK, 24.0, D_TURRET)
	turrets.append(p - Vector2(c, c))


func vent(p: Vector2, kind: String, size: float) -> void:
	vents.append({"pos": p - Vector2(c, c), "kind": kind, "size": size, "phase": rng.randf()})


## Docking arm from radius r0 to r1 along `ang`, with a hangar bay at its outer end.
func dock_arm(ang: float, r0: float, r1: float, w: float = 58.0, h: float = 12.0, pat: int = P_WINDOWS) -> void:
	var a := P(r0, ang)
	var b := P(r1, ang)
	seg(a, b, w * 0.5, HULL, h, pat)
	# reinforced collar around the bay mouth
	box(P(r1 - 3.0, ang), ang, 3.0, w * 0.5 + 2.0, DARK, h + 2.0, P_ARMOR)
	add_bay(ang, r1, h)


## Carves a hangar bay into whatever lies at radius r1 along ang (mouth at r1, opening outward).
func add_bay(ang: float, r1: float, h: float, bw: float = BAY_W, bd: float = BAY_D) -> void:
	var dir := Vector2.from_angle(ang)
	var mouth := P(r1, ang)
	box(mouth - dir * (bd * 0.5 - 1.0), ang, bd * 0.5 + 1.5, bw * 0.5, HANGAR, 1.0, P_BAY, true)
	# hazard frame either side of the mouth
	var side := dir.orthogonal()
	for s in [-1.0, 1.0]:
		box(mouth + side * s * (bw * 0.5 + 2.5) - dir * 4.0, ang, 4.0, 2.5, ACC, h + 3.0, P_HAZARD)
		light(mouth + side * s * (bw * 0.5 + 2.5), Color(1.0, 0.25, 0.2) if s < 0.0 else Color(0.3, 1.0, 0.4), 2.0, true)
	bays.append({"pos": mouth - Vector2(c, c), "dir": dir, "width": bw, "depth": bd})


func solar_wing(a: Vector2, b: Vector2, panel_w: float, h: float = 6.0) -> void:
	seg(a, b, 1.6, TRUSS, h + 1.0)
	var d := b - a
	var len := d.length()
	var dir := d / len
	var side := dir.orthogonal()
	var count := int(len / 22.0)
	for k in count:
		var t := (k + 0.5) / count
		var p := a + d * t
		for s in [-1.0, 1.0]:
			box(p + side * s * (panel_w * 0.5 + 2.0), d.angle(), len / count * 0.5 - 1.5, panel_w * 0.5, SOLAR, h, P_SOLAR)
	light(b, Color(1.0, 1.0, 1.0), 3.0, true)


# ================================================================ Layouts

func _trade() -> void:
	var hub := n * 0.11
	var r_ring := n * 0.29
	var thick := 8.0 + tier * 2.0
	# solar wings first (lowest)
	if tier >= 2:
		for s in [0.0, PI]:
			solar_wing(P(r_ring + thick, s), P(n * 0.48, s), 12.0 + tier * 2.0)
	# spokes and ring
	for k in 4:
		seg(P(hub, k * PI * 0.5), P(r_ring, k * PI * 0.5), 4.0, HULL, 9.0, P_PLATES)
	ring(Vector2(c, c), r_ring - thick * 0.5, r_ring + thick * 0.5, HULL, 9.0, true, 12 + tier * 4)
	if tier >= 3:
		ring(Vector2(c, c), n * 0.40, n * 0.43, PANEL, 7.0, true, 24)
		for k in 8:
			seg(P(r_ring + thick * 0.5, k * PI * 0.25 + PI * 0.125), P(n * 0.40, k * PI * 0.25 + PI * 0.125), 2.0, TRUSS, 7.5)
	# docking arms (diagonal, over the ring)
	var arms := tier + 1
	for k in arms:
		var ang := PI * 0.25 + k * TAU / arms
		dock_arm(ang, hub * 0.6, n * 0.48)
	# hub
	disc(Vector2(c, c), hub, HULL, 16.0, D_HUB)
	# neon billboards on the ring (corporate advertising)
	for k in 2:
		var ang2 := PI * 0.5 + k * PI
		var p := P(r_ring + thick * 0.5 + 4.0, ang2)
		box(p, ang2 + PI * 0.5, 10.0 + tier * 3.0, 3.0, DARK, 12.0)
		box(p, ang2 + PI * 0.5, 9.0 + tier * 3.0, 2.0, NEON, 13.0)
		neons.append({"pos": p - Vector2(c, c), "ang": ang2 + PI * 0.5, "len": (9.0 + tier * 3.0) * 2.0, "wid": 4.0})
	for k in 2 + tier:
		turret(P(r_ring, PI * 0.125 + k * TAU / (2 + tier)), 5.0)
	light(Vector2(c, c), Color(1, 1, 1), 1.0, true)


func _industry() -> void:
	var s := n * (0.2 + tier * 0.025)
	var cols := 2 + tier
	var cell := s * 2.0 / cols
	# conveyor trusses to the arms
	seg(P(0.0, 0.0), P(n * 0.48, 0.0), 6.0, TRUSS, 5.0, P_TRUSS)
	seg(P(0.0, PI), P(n * 0.48, PI), 6.0, TRUSS, 5.0, P_TRUSS)
	# factory blocks
	for gy in cols:
		for gx in cols:
			var p := Vector2(c - s + (gx + 0.5) * cell, c - s + (gy + 0.5) * cell)
			var hh := 8.0 + rng.randf_range(0.0, 10.0)
			var m := HULL if rng.randf() < 0.7 else PANEL
			box(p, 0.0, cell * 0.5 - 1.5, cell * 0.5 - 1.5, m, hh, P_BLOCK)
			if rng.randf() < 0.3:
				box(p, 0.0, cell * 0.3, cell * 0.12, ACC, hh + 2.5, P_FLAT)
			if rng.randf() < 0.45:
				var cp := p + Vector2(rng.randf_range(-cell * 0.2, cell * 0.2), rng.randf_range(-cell * 0.2, cell * 0.2))
				disc(cp, 4.0 + tier, DARK, hh + 4.0, D_HOTTOWER)
				vent(cp, "smoke", 5.0 + tier)
	# hazard band around the complex
	for side in 4:
		var ang := side * PI * 0.5
		box(P(s + 2.0, ang), ang + PI * 0.5, s, 2.0, ACC, 6.0, P_HAZARD)
	# small shipyard gantry
	if tier >= 2:
		var g := P(s + 30.0, PI * 0.5)
		box(g, 0.0, 30.0, 18.0, HULL, 5.0, P_RIBS)
		seg(g + Vector2(-34, -20), g + Vector2(34, -20), 2.5, TRUSS, 9.0)
		seg(g + Vector2(-34, 20), g + Vector2(34, 20), 2.5, TRUSS, 9.0)
		seg(g + Vector2(34, -20), g + Vector2(34, 20), 2.5, TRUSS, 9.0)
		for k in 3:
			vent(g + Vector2(rng.randf_range(-25, 25), rng.randf_range(-12, 12)), "spark", 2.0)
	# docking arms
	dock_arm(0.0, s, n * 0.48, 58.0, 11.0, P_PLATES)
	dock_arm(PI, s, n * 0.48, 58.0, 11.0, P_PLATES)
	if tier >= 3:
		dock_arm(-PI * 0.5, s, n * 0.48, 58.0, 11.0, P_PLATES)
	for k in 4:
		turret(P(s * 1.35, PI * 0.25 + k * PI * 0.5), 5.0)
		light(P(s * 1.35, PI * 0.25 + k * PI * 0.5) + Vector2(0, -7), Color(1.0, 0.6, 0.2), 1.2, true)


func _mining() -> void:
	var hub := n * 0.1
	var center := Vector2(c, c)
	# grabber arms holding asteroid chunks
	for k in 2:
		var ang := PI * 0.5 + k * PI + rng.randf_range(-0.35, 0.35)
		var tip := P(n * 0.41, ang)
		seg(P(hub, ang), tip, 4.5, TRUSS, 6.0, P_TRUSS)
		seg(P(hub, ang), P(n * 0.3, ang), 2.0, HULL, 7.0, P_GIRDER)
		var rock := P(n * 0.41 + 7.0 + tier * 2.0, ang)
		disc(rock, 11.0 + tier * 2.5, ROCK, 5.0, D_ROCK)
		for s in [-1.0, 1.0]:
			box(tip + Vector2.from_angle(ang + s * 0.8) * 7.0, ang + s * 0.6, 8.0, 2.2, DARK, 12.0, P_ARMOR)
		light(tip, Color(1.0, 0.8, 0.3), 2.0, true)
	# processing platform (cross) carrying the furnaces
	poly(PackedVector2Array([center + Vector2(-n * 0.3, -n * 0.07), center + Vector2(n * 0.3, -n * 0.07), center + Vector2(n * 0.3, n * 0.07), center + Vector2(-n * 0.3, n * 0.07)]), PANEL, 7.0, 3.0, 10)
	poly(regular(center, n * 0.2, 6, 0.0), HULL, 8.0, 3.0, 10)
	# ore silos in clusters along the platform
	for side in [-1.0, 1.0]:
		for k in 1 + tier:
			var sp := center + Vector2(side * n * (0.13 + k * 0.055), -n * 0.1)
			disc(sp, 6.0, PANEL, 11.0, D_TANK)
			disc(sp + Vector2(0, n * 0.2), 6.0, RUST, 11.0, D_TANK)
	# conveyors from the arms to the furnaces
	for k in 2:
		seg(P(n * 0.21, k * PI), P(n * 0.3, k * PI), 2.5, TRUSS, 12.0)
	# refinery towers with glowing furnaces
	var towers := 2 + tier
	for k in towers:
		var ang4 := k * TAU / towers + 0.5
		var p := P(n * 0.14, ang4)
		disc(p, 9.0 + tier, HULL, 13.0, D_HOTTOWER)
		vent(p, "glow", 5.0)
		vent(p, "smoke", 6.0 + tier)
	dock_arm(0.0, n * 0.28, n * 0.48, 58.0, 12.0, P_PLATES)
	dock_arm(PI, n * 0.28, n * 0.48, 58.0, 12.0, P_PLATES)
	disc(center, hub * 0.75, HULL, 20.0, D_HUB)
	for k in 2 + tier:
		turret(P(n * 0.21, PI * 0.25 + k * TAU / (2 + tier)), 5.0)


func _agri() -> void:
	var hub := n * 0.1
	# huge solar wings along the horizontal axis
	for s in [0.0, PI]:
		solar_wing(P(hub, s), P(n * 0.49, s), 22.0 + tier * 4.0, 4.0)
	# greenhouse domes on connectors
	var domes := 2 + tier * 2
	for k in domes:
		var half := domes / 2
		var side := -1.0 if k < half else 1.0
		var idx := k % half
		var ang := side * PI * 0.5 + (idx - (half - 1) * 0.5) * 0.5
		var p := P(n * 0.25, ang)
		seg(P(hub, ang), p, 3.0, HULL, 7.0, P_PLATES)
		disc(p, n * 0.07, GREEN, 9.0, D_GREEN)
		light(p + Vector2(0, -n * 0.07), Color(0.5, 1.0, 0.5), 0.8)
	# water tanks
	for k in 2 + tier:
		disc(P(n * 0.15, rng.randf() * TAU), 5.0, TANK, 9.0, D_TANK)
	dock_arm(PI * 0.5, hub * 0.6, n * 0.46, 56.0, 11.0)
	if tier >= 2:
		dock_arm(-PI * 0.5, hub * 0.6, n * 0.46, 56.0, 11.0)
	disc(Vector2(c, c), hub, HULL, 15.0, D_HUB)
	for k in 2:
		turret(P(hub + 8.0, PI * 0.25 + k * PI), 4.5)


func _research() -> void:
	var hub := n * 0.1
	var center := Vector2(c, c)
	# long sensor booms with blinking tips
	for k in 2:
		var ang := PI * 0.2 + k * PI
		seg(P(hub, ang), P(n * 0.49, ang), 2.0, TRUSS, 6.0)
		for j in 3:
			disc(P(n * (0.3 + j * 0.06), ang), 2.5, DARK, 7.0, D_DOME)
		light(P(n * 0.49, ang), Color(0.8, 0.5, 1.0), 4.0, true)
	# hexagonal lab deck
	poly(regular(center, n * 0.17, 6, PI / 6.0), PANEL, 8.0, 3.0, 8)
	# lab cylinders, ends carry dishes or observation domes
	var labs := 3 + tier
	for k in labs:
		var ang2 := PI * 0.75 + k * TAU / labs
		var end := P(n * (0.29 + 0.025 * tier), ang2)
		seg(P(hub * 0.8, ang2), end, 8.0, HULL, 10.0, P_CYL)
		if k % 2 == 0:
			disc(end + Vector2.from_angle(ang2) * (10.0 + tier * 2.0), 10.0 + tier * 2.0, HULL, 11.0, D_DISH)
		else:
			disc(end, 7.0, ACC, 14.0, D_DOME)
			light(end, acc, 1.2)
	dock_arm(PI * 0.2 + PI * 0.5, hub * 0.6, n * 0.47, 56.0, 12.0)
	if tier >= 3:
		dock_arm(PI * 0.2 - PI * 0.5, hub * 0.6, n * 0.47, 56.0, 12.0)
	# big dish on the deck
	disc(P(n * 0.11, PI * 1.25), 12.0 + tier * 2.0, HULL, 16.0, D_DISH)
	disc(center, hub * 0.7, HULL, 18.0, D_HUB)
	for k in 2:
		turret(P(n * 0.15, k * PI + PI * 0.7), 4.5)


func _military() -> void:
	var s := n * 0.36
	var center := Vector2(c, c)
	# outer armour belt (octagon) and raised inner deck
	poly(regular(center, s, 8, PI / 8.0), HULL, 9.0, 4.0, 12)
	poly(regular(center, s * 0.62, 8, PI / 8.0), PANEL, 13.0, 3.0, 8)
	ring(center, s * 0.62, s * 0.7, DARK, 12.0, false, 8)
	# armour ridges along the belt
	for k in 8:
		var ang := k * TAU / 8.0
		box(P(s * 0.82, ang), ang, s * 0.14, 2.5, DARK, 14.0, P_ARMOR)
	# command tower
	poly(regular(center, s * 0.3, 6, 0.0), HULL, 18.0, 3.0, 6)
	disc(center, s * 0.14, ACC, 24.0, D_DOME)
	for k in 6:
		light(P(s * 0.3, k * TAU / 6.0), Color(1.0, 0.3, 0.25), 0.8)
	# hangar gates in the faces
	var gates := 2 + int(tier >= 2)
	for k in gates:
		var ang2 := PI + k * TAU / gates if gates != 2 else k * PI
		add_bay(ang2, s * 0.94, 12.0, BAY_W + 4.0, BAY_D)
	# turret batteries along the belt
	var guns := 4 + tier * 2
	for k in guns:
		turret(P(s * 0.8, PI / guns + k * TAU / guns), 5.5)
	for k in 8:
		light(P(s * 1.0, PI / 8.0 + k * PI * 0.25), Color(1.0, 0.25, 0.2), 1.0, true)


func _ice() -> void:
	var hub := n * 0.09
	var center := Vector2(c, c)
	# square frame of girders carrying the tanks
	var fr := n * 0.25
	var corners := [center + Vector2(-fr, -fr), center + Vector2(fr, -fr), center + Vector2(fr, fr), center + Vector2(-fr, fr)]
	for k in 4:
		seg(corners[k], corners[(k + 1) % 4], 3.5, HULL, 6.0, P_GIRDER)
		seg(center, corners[k], 3.0, TRUSS, 5.0, P_TRUSS)
	# big spherical tanks at the corners and edge centres, frosted
	var spots: Array = corners.duplicate()
	if tier >= 2:
		spots.append_array([center + Vector2(-fr, 0), center + Vector2(fr, 0)])
	if tier >= 3:
		spots.append_array([center + Vector2(0, -fr), center + Vector2(0, fr)])
	for p in spots:
		disc(p, n * 0.075, TANK, 10.0, D_TANK)
		disc(p + Vector2(-n * 0.022, -n * 0.022), n * 0.028, ICE, 11.0 + n * 0.05, D_DOME)
	# processing deck with cooling towers
	poly(regular(center, n * 0.16, 8, PI / 8.0), PANEL, 9.0, 3.0, 9)
	var towers := 1 + tier
	for k in towers:
		var p2 := P(n * 0.1, k * TAU / towers + 0.4)
		disc(p2, n * 0.05, HULL, 13.0, D_COOL)
		vent(p2, "steam", n * 0.045)
	dock_arm(PI * 0.5, n * 0.2, n * 0.48, 56.0, 13.0, P_PLATES)
	dock_arm(-PI * 0.5, n * 0.2, n * 0.48, 56.0, 13.0, P_PLATES)
	disc(center, hub * 0.6, HULL, 22.0, D_HUB)
	for k in 2 + tier:
		turret(P(n * 0.36, PI * 0.25 + k * TAU / (2 + tier)), 4.5)


func _shipyard() -> void:
	var center := Vector2(c, c)
	# central spine
	box(center, 0.0, n * 0.46, 16.0, HULL, 10.0, P_WINDOWS)
	box(center, 0.0, n * 0.44, 3.0, ACC, 12.0, P_FLAT)
	# construction docks (one per tier), each with a hull being built
	var docks: Array = [[0.0, 1.0]] if tier == 1 else ([[-1.0, -1.0], [1.0, -1.0]] if tier == 2 else [[-1.0, -1.0], [0.0, 1.0], [1.0, -1.0]])
	for dk in docks:
		var x := c + float(dk[0]) * n * 0.3
		var sgn := float(dk[1])
		var base := Vector2(x, c + sgn * 16.0)
		var tip := Vector2(x, c + sgn * n * 0.47)
		var hw := n * 0.11
		var length := (tip - base).length()
		# girders and back wall
		seg(base + Vector2(-hw, 0), tip + Vector2(-hw, 0), 4.0, HULL, 12.0, P_GIRDER)
		seg(base + Vector2(hw, 0), tip + Vector2(hw, 0), 4.0, HULL, 12.0, P_GIRDER)
		box(base + Vector2(0, sgn * 4.0), 0.0, hw + 4.0, 4.0, DARK, 13.0, P_ARMOR)
		# ship under construction: tapered hull, bow plated, mid section open ribs, engines
		_hull_frame(base + Vector2(0, sgn * length * 0.52), sgn, length * 0.4, hw * 0.62)
		# gantry cross beams above the hull
		for j in 4:
			var yb := lerpf(base.y, tip.y, 0.18 + j * 0.22)
			seg(Vector2(x - hw, yb), Vector2(x + hw, yb), 1.6, TRUSS, 20.0)
			light(Vector2(x, yb), Color(1.0, 0.95, 0.75), 0.6)
		for sp in 5:
			vent(Vector2(x + rng.randf_range(-hw * 0.4, hw * 0.4), lerpf(base.y, tip.y, rng.randf_range(0.2, 0.85))), "spark", 2.0)
		light(tip + Vector2(-hw, 0), Color(1.0, 0.25, 0.2), 1.5, true)
		light(tip + Vector2(hw, 0), Color(0.3, 1.0, 0.4), 1.5, true)
	# player docking at both ends of the spine
	add_bay(0.0, n * 0.46, 12.0)
	add_bay(PI, n * 0.46, 12.0)
	disc(center, 22.0, HULL, 18.0, D_HUB)
	for k in 4:
		turret(Vector2(c + (k - 1.5) * n * 0.2, c + (1.0 if k % 2 == 0 else -1.0) * 22.0), 5.0)


## Hull of a large ship being built (shipyard): bow plated with windows, open ribs mid-ship, engines aft.
func _hull_frame(mid: Vector2, sgn: float, hl: float, hw: float) -> void:
	for y in range(int(mid.y - hl), int(mid.y + hl) + 1):
		var t := (float(y) + 0.5 - (mid.y - hl)) / (2.0 * hl)        # 0..1 along the hull
		if sgn < 0.0:
			t = 1.0 - t                                               # t = 0 at the dock wall, 1 at the bow
		var w := hw * (1.0 - pow(t, 3.0) * 0.75)
		for x in range(int(mid.x - w), int(mid.x + w) + 1):
			var v := absf(float(x) + 0.5 - mid.x) / w
			if v > 1.0:
				continue
			var hh := 6.0 + sqrt(maxf(0.0, 1.0 - v * v)) * hw * 0.5
			var m := HULL
			if t > 0.25 and t < 0.68:
				# open section: ribs every 5 px, dark interior between
				if posmod(y, 5) == 0 or v > 0.86:
					m = TRUSS
					hh += 1.0
				else:
					m = DARK
					hh -= 2.0
			elif t >= 0.68:
				if posmod(y, 7) == 0:
					m = DARK
				elif v < 0.3 and posmod(y, 3) == 1:
					m = GLASS
			else:
				if v < 0.55 and posmod(y, 6) < 3:
					m = DARK if v > 0.3 else TRUSS
			_put(x, y, m, hh)
	# engine nozzles at the dock end
	for s in [-1.0, 1.0]:
		disc(mid + Vector2(s * hw * 0.45, -sgn * hl * 0.98), hw * 0.28, DARK, 16.0, D_DISH)


# ================================================================ Package 39: landmarks of Landfall

const LANDMARK_SIZE := {"vote": 540, "vote_relay": 120, "concord_yards": 440, "res_publica": 560,
	"cathedral": 520, "pilgrim_gate": 300, "forge": 460, "lux_aeterna": 600,
	"dyson_hub": 480, "mirror": 170, "gate_frame": 190, "axiom_yards": 440}
const COVENANT_ARTS := {"cathedral": true, "pilgrim_gate": true, "forge": true, "lux_aeterna": true}
const DIRECTORATE_ARTS := {"dyson_hub": true, "mirror": true, "gate_frame": true, "axiom_yards": true}
const ASSEMBLY_ARTS := {"vote": true, "vote_relay": true, "concord_yards": true, "res_publica": true}
const VOTE_RELAY_ANGLE := 0.4                       # where the first relay lies (Universe._special_structures)


## The Vote: the Assembly's great trade hub over Agora, where the citizens' votes from every gate come together. A
## broad domed hub, a wide habitat ring full of windows, a thin outer ring of data emitters on long spokes, four
## docking arms and four small drone hangars facing the relay stations.
func _vote() -> void:
	var center := Vector2(c, c)
	var r_ring := n * 0.27
	var r_out := n * 0.44
	# outer data ring on spokes (lowest)
	for k in 12:
		var a := k * TAU / 12.0 + PI / 12.0
		seg(P(r_ring + 10.0, a), P(r_out, a), 1.8, TRUSS, 6.0)
	ring(center, r_out - 3.0, r_out + 3.0, PANEL, 7.0, false, 48)
	for k in 24:
		var a2 := k * TAU / 24.0
		disc(P(r_out, a2), 4.5, DARK, 10.0, D_DISH)
		light(P(r_out, a2), Color(0.45, 0.75, 1.0), 0.8 + 0.05 * (k % 5))
	# solar wings between the docking arms
	for k in 4:
		solar_wing(P(r_ring + 12.0, k * PI * 0.5), P(r_out - 8.0, k * PI * 0.5), 14.0, 5.0)
	# the habitat ring and its spokes
	for k in 8:
		seg(P(n * 0.12, k * PI * 0.25), P(r_ring, k * PI * 0.25), 5.0, HULL, 10.0, P_PLATES)
	ring(center, r_ring - 13.0, r_ring + 13.0, HULL, 10.0, true, 32)
	ring(center, r_ring - 2.0, r_ring + 2.0, ACC, 12.0, false, 64)
	# four docking arms (diagonal) with the player bays
	for k in 4:
		dock_arm(PI * 0.25 + k * PI * 0.5, n * 0.1, n * 0.36, 52.0, 12.0)
	# four small drone hangars facing the relays (the drones fly out and in)
	for k in 4:
		var a3 := VOTE_RELAY_ANGLE + k * TAU / 4.0
		box(P(r_ring + 15.0, a3), a3, 9.0, 11.0, HULL, 13.0, P_ARMOR)
		box(P(r_ring + 22.0, a3), a3, 2.5, 7.0, HANGAR, 1.0, P_FLAT, true)
		for sgn in [-1.0, 1.0]:
			light(P(r_ring + 23.0, a3) + Vector2.from_angle(a3).orthogonal() * sgn * 9.0, Color(1.0, 0.75, 0.3), 2.5, true)
	# the hub: a broad dome with the chamber of votes in the middle
	disc(center, n * 0.13, HULL, 14.0, D_HUB)
	ring(center, n * 0.13 - 3.0, n * 0.13, DARK, 16.0, false, 32)
	disc(center, n * 0.065, GLASS, 20.0, D_DOME)
	for k in 6:
		box(P(n * 0.095, k * TAU / 6.0), k * TAU / 6.0, 5.0, 2.0, ACC, 19.0)
	# blue neon bands on the ring (the Assembly's colours), white beacons on the hub
	for k in 4:
		var a4 := k * PI * 0.5
		var p := P(r_ring + 15.0, a4 + PI * 0.12)
		box(p, a4 + PI * 0.62, 14.0, 3.0, DARK, 14.0)
		box(p, a4 + PI * 0.62, 13.0, 2.0, NEON, 15.0)
		neons.append({"pos": p - center, "ang": a4 + PI * 0.62, "len": 26.0, "wid": 4.0})
	for k in 6:
		turret(P(r_ring, PI * 0.125 + k * TAU / 6.0 + 0.2), 5.0)
	light(center, Color(1, 1, 1), 1.0, true)
	for k in 4:
		light(P(n * 0.13, k * PI * 0.5), Color(0.5, 0.8, 1.0), 1.2, true)


## A relay station round The Vote: an octagonal platform with a small drone hangar facing the hub, a dish and two
## solar panels. Which way it faces comes from its seed (400 + index).
func _vote_relay() -> void:
	var center := Vector2(c, c)
	var k := posmod(int(rng.seed) - 400, 8)
	var face := VOTE_RELAY_ANGLE + k * TAU / 4.0 + PI          # towards The Vote
	solar_wing(P(n * 0.2, face + PI * 0.5), P(n * 0.46, face + PI * 0.5), 9.0, 4.0)
	solar_wing(P(n * 0.2, face - PI * 0.5), P(n * 0.46, face - PI * 0.5), 9.0, 4.0)
	poly(regular(center, n * 0.24, 8, PI / 8.0), HULL, 9.0, 3.0, 9)
	ring(center, n * 0.24 - 2.0, n * 0.24 + 1.0, ACC, 11.0, false, 16)
	# the drone hangar
	box(P(n * 0.2, face), face, 8.0, 10.0, HULL, 12.0, P_ARMOR)
	box(P(n * 0.26, face), face, 3.0, 6.5, HANGAR, 1.0, P_FLAT, true)
	for sgn in [-1.0, 1.0]:
		light(P(n * 0.27, face) + Vector2.from_angle(face).orthogonal() * sgn * 8.0, Color(1.0, 0.75, 0.3), 2.5, true)
	# dish towards the gates (away from the hub)
	disc(P(n * 0.12, face + PI), 9.0, DARK, 14.0, D_DISH)
	light(P(n * 0.12, face + PI), Color(0.45, 0.8, 1.0), 0.9)
	disc(center, 7.0, GLASS, 13.0, D_DOME)
	light(center, Color(0.45, 0.75, 1.0), 1.4, true)


## Concord Yards: the Assembly's shipyard at Ostrakon. A tower where wide gantries reach out to the Res Publica in her
## berth beside it (left), a long spine with three construction berths – Concord carriers being built – and docking
## bays at its end and on the tower.
func _concord_yards() -> void:
	var tx := c - n * 0.2                                      # the tower
	# gantries to the Res Publica (left edge of the picture, she lies beyond it)
	for j in 3:
		var y := c + (j - 1) * n * 0.2
		seg(Vector2(2.0, y), Vector2(tx, y), 6.0, HULL, 9.0, P_GIRDER)
		seg(Vector2(2.0, y - 10.0), Vector2(tx, y - 10.0), 1.5, TRUSS, 10.0)
		seg(Vector2(2.0, y + 10.0), Vector2(tx, y + 10.0), 1.5, TRUSS, 10.0)
		for q in 4:
			light(Vector2(10.0 + q * (tx - 20.0) / 3.0, y), Color(1.0, 0.85, 0.4), 0.7)
		vent(Vector2(8.0 + j * 9.0, y + 5.0), "spark", 2.0)
	# the spine to the right
	var sx := (tx + n * 0.97) * 0.5
	box(Vector2(sx, c), 0.0, (n * 0.97 - tx) * 0.5, 15.0, HULL, 10.0, P_WINDOWS)
	box(Vector2(sx, c), 0.0, (n * 0.97 - tx) * 0.5 - 2.0, 2.5, ACC, 12.0)
	# three berths with Concord carriers being built
	var docks: Array = [[0.02, -1.0], [0.26, -1.0], [0.14, 1.0]]
	for dk in docks:
		var x := c + float(dk[0]) * n
		var sgn := float(dk[1])
		var base := Vector2(x, c + sgn * 16.0)
		var tip := Vector2(x, c + sgn * n * 0.47)
		var hw := n * 0.085
		var length := (tip - base).length()
		seg(base + Vector2(-hw, 0), tip + Vector2(-hw, 0), 3.5, HULL, 12.0, P_GIRDER)
		seg(base + Vector2(hw, 0), tip + Vector2(hw, 0), 3.5, HULL, 12.0, P_GIRDER)
		box(base + Vector2(0, sgn * 4.0), 0.0, hw + 4.0, 4.0, DARK, 13.0, P_ARMOR)
		var mid := base + Vector2(0, sgn * length * 0.52)
		_hull_frame(mid, sgn, length * 0.4, hw * 0.55)
		# the flight decks of a carrier either side, half plated
		for sd in [-1.0, 1.0]:
			box(mid + Vector2(sd * hw * 0.62, -sgn * length * 0.05), PI * 0.5, length * 0.26, hw * 0.16, DARK, 11.0, P_RIBS)
		box(mid + Vector2(0, sgn * length * 0.2), PI * 0.5, length * 0.14, 1.2, ACC, 30.0)
		for j2 in 4:
			var yb := lerpf(base.y, tip.y, 0.18 + j2 * 0.22)
			seg(Vector2(x - hw, yb), Vector2(x + hw, yb), 1.6, TRUSS, 20.0)
			light(Vector2(x, yb), Color(1.0, 0.95, 0.75), 0.6)
		for sp in 4:
			vent(Vector2(x + rng.randf_range(-hw * 0.4, hw * 0.4), lerpf(base.y, tip.y, rng.randf_range(0.2, 0.85))), "spark", 2.0)
		light(tip + Vector2(-hw, 0), Color(1.0, 0.25, 0.2), 1.5, true)
		light(tip + Vector2(hw, 0), Color(0.3, 1.0, 0.4), 1.5, true)
	# the tower over the gantries
	box(Vector2(tx, c), PI * 0.5, n * 0.3, 20.0, HULL, 14.0, P_ARMOR)
	box(Vector2(tx, c), PI * 0.5, n * 0.28, 3.0, ACC, 17.0)
	disc(Vector2(tx, c), 24.0, HULL, 20.0, D_HUB)
	# docking: the end of the spine and the ends of the tower
	add_bay(0.0, n * 0.48, 12.0)
	box(Vector2(tx, c - n * 0.3), 0.0, 26.0, 8.0, HULL, 12.0, P_PLATES)
	box(Vector2(tx, c + n * 0.3), 0.0, 26.0, 8.0, HULL, 12.0, P_PLATES)
	# the Assembly's neon
	var pn := Vector2(tx + 26.0, c - n * 0.16)
	box(pn, PI * 0.5, 18.0, 3.0, DARK, 16.0)
	box(pn, PI * 0.5, 17.0, 2.0, NEON, 17.0)
	neons.append({"pos": pn - Vector2(c, c), "ang": PI * 0.5, "len": 34.0, "wid": 4.0})
	for k in 4:
		turret(Vector2(tx + (1.0 if k % 2 == 0 else -1.0) * 26.0, c + (k - 1.5) * n * 0.16), 5.0)
	light(Vector2(tx, c - n * 0.3), Color(1.0, 0.3, 0.25), 1.2, true)
	light(Vector2(tx, c + n * 0.3), Color(1.0, 0.3, 0.25), 1.2, true)


## The Res Publica, Concord Fleetworks' capital ship (0.6.39.2, after Luz's reference) – a supercarrier the size of a
## station, still in her berth, bow to the left. A long narrow bow split by the trench of her spinal railgun (against
## other capital ships), broad shoulders, swept wings at the stern with the engine core sunk between them – and
## everywhere on the hull small hatches the drones launch from. Part of a wing is still bare frame under scaffolding.
func _res_publica() -> void:
	# the wings at the stern (lowest), mirrored
	for sd in [-1.0, 1.0]:
		var wing := PackedVector2Array([Vector2(_rx(0.55), _ry(sd * 0.095)), Vector2(_rx(0.66), _ry(sd * 0.17)), Vector2(_rx(0.8), _ry(sd * 0.205)),
			Vector2(_rx(0.925), _ry(sd * 0.175)), Vector2(_rx(0.935), _ry(sd * 0.075)), Vector2(_rx(0.9), _ry(sd * 0.06)), Vector2(_rx(0.62), _ry(sd * 0.06))])
		poly(wing, HULL, 10.0, 3.0, 0)
		# grey stripes along the leading edge
		for i in 4:
			var o := 0.018 + i * 0.007
			seg(Vector2(_rx(0.64 + o * 0.6), _ry(sd * (0.155 - o))), Vector2(_rx(0.79), _ry(sd * (0.19 - o))), 0.6, PANEL, 13.5, P_FLAT, true)
		# a raised armour plate on the wing
		poly(PackedVector2Array([Vector2(_rx(0.68), _ry(sd * 0.15)), Vector2(_rx(0.8), _ry(sd * 0.18)), Vector2(_rx(0.9), _ry(sd * 0.16)),
			Vector2(_rx(0.9), _ry(sd * 0.115)), Vector2(_rx(0.7), _ry(sd * 0.105))]), HULL, 15.0, 2.5, 0)
		for i2 in 3:
			seg(Vector2(_rx(0.71), _ry(sd * (0.118 + i2 * 0.006))), Vector2(_rx(0.88), _ry(sd * (0.128 + i2 * 0.006))), 0.5, PANEL, 19.0, P_FLAT, true)
		# the shoulders
		poly(PackedVector2Array([Vector2(_rx(0.37), _ry(sd * 0.062)), Vector2(_rx(0.44), _ry(sd * 0.105)), Vector2(_rx(0.6), _ry(sd * 0.115)),
			Vector2(_rx(0.67), _ry(sd * 0.08)), Vector2(_rx(0.62), _ry(sd * 0.05)), Vector2(_rx(0.42), _ry(sd * 0.045))]), HULL, 13.0, 3.0, 0)
		seg(Vector2(_rx(0.45), _ry(sd * 0.095)), Vector2(_rx(0.59), _ry(sd * 0.104)), 0.6, PANEL, 16.5, P_FLAT, true)
		seg(Vector2(_rx(0.45), _ry(sd * 0.088)), Vector2(_rx(0.58), _ry(sd * 0.097)), 0.6, PANEL, 16.5, P_FLAT, true)
		# the bow halves either side of the railgun
		poly(PackedVector2Array([Vector2(_rx(0.03), _ry(sd * 0.012)), Vector2(_rx(0.035), _ry(sd * 0.04)), Vector2(_rx(0.07), _ry(sd * 0.05)),
			Vector2(_rx(0.4), _ry(sd * 0.068)), Vector2(_rx(0.46), _ry(sd * 0.05)), Vector2(_rx(0.46), _ry(sd * 0.012))]), HULL, 12.0, 2.5, 0)
		seg(Vector2(_rx(0.12), _ry(sd * 0.048)), Vector2(_rx(0.38), _ry(sd * 0.058)), 0.6, PANEL, 14.5, P_FLAT, true)
		# navigation lights at the wing tips
		light(Vector2(_rx(0.92), _ry(sd * 0.175)), Color(1.0, 0.25, 0.2) if sd < 0.0 else Color(0.3, 1.0, 0.4), 1.5, true)
	# the spine and the engine core sunk between the wings
	box(Vector2(_rx(0.64), c), 0.0, _rx(0.3), _rx(0.05), DARK, 8.0, P_FLAT, true)
	box(Vector2(_rx(0.53), c), 0.0, _rx(0.07), _rx(0.035), HULL, 15.0, P_ARMOR)
	box(Vector2(_rx(0.77), c), 0.0, _rx(0.17), _rx(0.026), HULL, 17.0, P_CYL)
	for k in 4:
		disc(Vector2(_rx(0.64 + k * 0.05), c), _rx(0.018), DARK, 18.0, D_TANK)
	for sd2 in [-1.0, 1.0]:
		box(Vector2(_rx(0.75), _ry(sd2 * 0.04)), 0.0, _rx(0.12), _rx(0.006), GUN, 12.0, P_RIBS)
	# engines
	for k2 in 3:
		var ep := Vector2(_rx(0.95), _ry((k2 - 1) * 0.03))
		box(ep - Vector2(8.0, 0), 0.0, 10.0, _rx(0.014), DARK, 16.0, P_ARMOR)
		disc(ep, _rx(0.015), DARK, 15.0, D_DISH)
		light(ep, Color(0.4, 0.7, 1.0), 0.5)
	# the railgun: a trench down the bow with rails, cross braces and the breech at its end
	box(Vector2(_rx(0.25), c), 0.0, _rx(0.21), _rx(0.015), DARK, 2.0, P_FLAT, true)
	for sd3 in [-1.0, 1.0]:
		box(Vector2(_rx(0.25), _ry(sd3 * 0.008)), 0.0, _rx(0.205), 1.0, ACC, 6.0, P_FLAT, true)
	var xb := _rx(0.06)
	while xb < _rx(0.45):
		box(Vector2(xb, c), PI * 0.5, _rx(0.012), 1.2, TRUSS, 5.0, P_FLAT, true)
		xb += _rx(0.035)
	box(Vector2(_rx(0.47), c), 0.0, _rx(0.025), _rx(0.03), GUN, 18.0, P_ARMOR)
	for k3 in 3:
		disc(Vector2(_rx(0.455 + k3 * 0.012), c), _rx(0.011), DARK, 21.0, D_TANK)
	light(Vector2(_rx(0.04), c), Color(0.6, 0.85, 1.0), 0.8, true)
	# the bridge on the shoulders
	box(Vector2(_rx(0.56), c), 0.0, _rx(0.03), _rx(0.022), HULL, 24.0, P_WINDOWS)
	light(Vector2(_rx(0.56), c), Color(1.0, 0.3, 0.25), 1.2, true)
	# drone hatches all over the hull (the drones of the live drawing launch from them)
	var rows := [[0.09, 0.37, 0.034, 0.04], [0.46, 0.6, 0.075, 0.03], [0.66, 0.9, 0.09, 0.04], [0.7, 0.88, 0.145, 0.035]]
	for r in rows:
		var x := float(r[0])
		while x <= float(r[1]):
			for sd4 in [-1.0, 1.0]:
				var hp := Vector2(_rx(x), _ry(sd4 * float(r[2])))
				box(hp, 0.0, 2.5, 1.6, HANGAR, 1.0, P_FLAT, true)
				_put(int(hp.x - 3.0), int(hp.y), MARK, 20.0, true)
				_put(int(hp.x + 3.0), int(hp.y), MARK, 20.0, true)
				vent(hp, "hatch", 1.0)
				if posmod(int(x * 100.0), 3) == 0:
					light(hp + Vector2(0.0, sd4 * 3.0), Color(1.0, 0.75, 0.3), 2.0, true)
			x += float(r[3])
	# still under construction: the lower wing tip is bare frame under scaffolding, welders at work
	box(Vector2(_rx(0.84), _ry(0.165)), -0.25, _rx(0.07), _rx(0.03), TRUSS, 22.0, P_TRUSS, true)
	box(Vector2(_rx(0.2), _ry(-0.055)), 0.03, _rx(0.06), _rx(0.012), TRUSS, 18.0, P_TRUSS, true)
	for k4 in 7:
		vent(Vector2(_rx(rng.randf_range(0.15, 0.92)), _ry(rng.randf_range(-0.17, 0.17))), "spark", 2.0)
	vent(Vector2(_rx(0.84), _ry(0.165)), "spark", 2.5)
	vent(Vector2(_rx(0.2), _ry(-0.055)), "spark", 2.5)


func _rx(f: float) -> float:
	return f * n


func _ry(f: float) -> float:
	return c + f * n

# ================================================================ 39b: landmarks of Heimkehr

## A pointed spire from `base` outwards along `ang`: a tapering body with a lantern window, a gold tip.
func spire(base: Vector2, ang: float, length: float, w: float, h: float) -> void:
	var dir := Vector2.from_angle(ang)
	var side := dir.orthogonal()
	poly(PackedVector2Array([base - side * w, base + dir * length * 0.7 - side * w * 0.55, base + dir * length, base + dir * length * 0.7 + side * w * 0.55, base + side * w]), HULL, h, 2.0, 0)
	box(base + dir * length * 0.45, ang, length * 0.12, w * 0.3, STAIN, h + 6.0, P_FLAT, true)
	box(base + dir * length * 0.92, ang, length * 0.06, w * 0.18, ACC, h + 8.0)


## A pointed window (lancet) of stained glass, `ang` = the way it points.
func lancet(p: Vector2, ang: float, length: float, w: float, h: float) -> void:
	var dir := Vector2.from_angle(ang)
	var side := dir.orthogonal()
	poly(PackedVector2Array([p - dir * length * 0.5 - side * w, p + dir * length * 0.25 - side * w, p + dir * length * 0.5, p + dir * length * 0.25 + side * w, p - dir * length * 0.5 + side * w]), STAIN, h, 0.0, 0)


## The Cathedral of Return over Vesper: the Covenant's home – a cruciform nave of pale stone with flying buttresses,
## a great rose window of stained glass ringed in gold (the sun over the road), spires at every arm and pinnacles along
## the nave; and, modern beneath the old forms, docking arms, solar sails and gold neon.
func _cathedral() -> void:
	var center := Vector2(c, c)
	# solar sails and docking arms (lowest) on the diagonals
	for k in 4:
		var a := PI * 0.25 + k * PI * 0.5
		solar_wing(P(n * 0.2, a + 0.22), P(n * 0.46, a + 0.22), 10.0, 5.0)
		dock_arm(a, n * 0.12, n * 0.4, 46.0, 11.0)
	# flying buttresses along the nave and the transept
	for sd in [-1.0, 1.0]:
		for j in 5:
			var y := c - n * 0.34 + j * n * 0.17
			if absf(y - c) < n * 0.08:
				continue
			seg(Vector2(c + sd * n * 0.05, y), Vector2(c + sd * n * 0.13, y + n * 0.03), 2.2, HULL, 9.0, P_GIRDER)
			disc(Vector2(c + sd * n * 0.13, y + n * 0.03), 5.0, HULL, 12.0, D_DOME)
	# the nave (vertical) and the transept (horizontal)
	box(center, PI * 0.5, n * 0.42, n * 0.065, HULL, 14.0, P_PLATES)
	box(center, 0.0, n * 0.3, n * 0.055, HULL, 13.0, P_PLATES)
	box(center, PI * 0.5, n * 0.4, 2.0, PANEL, 16.0)                     # a crimson runner down the roof
	box(center, 0.0, n * 0.28, 2.0, PANEL, 15.5)
	# lancet windows along the nave and transept
	for j2 in 6:
		for sd2 in [-1.0, 1.0]:
			lancet(Vector2(c + sd2 * n * 0.04, c - n * 0.36 + j2 * n * 0.05 + (n * 0.47 if j2 >= 3 else 0.0)), -PI * 0.5, 14.0, 3.0, 17.0)
	for j3 in 3:
		for sd3 in [-1.0, 1.0]:
			lancet(Vector2(c - n * 0.26 + j3 * n * 0.05 + (n * 0.37 if sd3 > 0.0 else 0.0), c + n * 0.032), -PI * 0.5, 12.0, 3.0, 16.5)
	# the apse at the head of the nave, with its chapels
	disc(Vector2(c, c - n * 0.42), n * 0.06, HULL, 12.0, D_FLAT)
	ring(Vector2(c, c - n * 0.42), n * 0.045, n * 0.06, PANEL, 14.0, false, 12)
	disc(Vector2(c, c - n * 0.42), n * 0.03, ACC, 16.0, D_DOME)
	for k2 in 5:
		var a2 := -PI * 0.5 + (k2 - 2) * 0.45
		disc(Vector2(c, c - n * 0.42) + Vector2.from_angle(a2) * n * 0.07, n * 0.022, HULL, 13.0, D_DOME)
		lancet(Vector2(c, c - n * 0.42) + Vector2.from_angle(a2) * n * 0.045, a2, 12.0, 3.0, 20.0)
	# spires at the ends of the arms and at the crossing's corners, pinnacles along the nave
	spire(Vector2(c, c + n * 0.42), PI * 0.5, n * 0.07, 9.0, 18.0)
	spire(Vector2(c - n * 0.3, c), PI, n * 0.08, 9.0, 18.0)
	spire(Vector2(c + n * 0.3, c), 0.0, n * 0.08, 9.0, 18.0)
	spire(Vector2(c, c - n * 0.49), -PI * 0.5, n * 0.035, 6.0, 18.0)
	for k3 in 4:
		var a3 := PI * 0.25 + k3 * PI * 0.5
		spire(center + Vector2.from_angle(a3) * n * 0.17, a3, n * 0.08, 7.0, 22.0)
	for j4 in 7:
		for sd4 in [-1.0, 1.0]:
			var py := c - n * 0.36 + j4 * n * 0.12
			if absf(py - c) < n * 0.07:
				continue
			disc(Vector2(c + sd4 * n * 0.065, py), 3.0, ACC, 19.0, D_DOME)
	# the rose window over the crossing, ringed in gold – the sun over the road
	disc(center, n * 0.13, HULL, 22.0, D_FLAT)
	disc(center, n * 0.115, STAIN, 24.0, D_FLAT)
	for k4 in 16:
		var a4 := k4 * TAU / 16.0
		seg(center + Vector2.from_angle(a4) * n * 0.03, center + Vector2.from_angle(a4) * n * 0.115, 0.7, DARK, 25.0, P_FLAT, true)
	ring(center, n * 0.055, n * 0.062, DARK, 24.5, false, 32)
	ring(center, n * 0.115, n * 0.135, ACC, 24.0, false, 48)
	for k5 in 24:
		var a5 := k5 * TAU / 24.0
		box(center + Vector2.from_angle(a5) * n * 0.15, a5, 5.0, 1.6, ACC, 23.0)       # the sun's rays
	disc(center, n * 0.025, ACC, 27.0, D_DOME)
	# gold neon over the docking arms, lights like candles along the nave
	for k6 in 2:
		var a6 := PI * 0.25 + k6 * PI
		var pn := P(n * 0.33, a6) + Vector2.from_angle(a6).orthogonal() * 30.0
		box(pn, a6, 13.0, 3.0, DARK, 13.0)
		box(pn, a6, 12.0, 2.0, NEON, 14.0)
		neons.append({"pos": pn - center, "ang": a6, "len": 24.0, "wid": 4.0})
	for j5 in 10:
		light(Vector2(c + (1.0 if j5 % 2 == 0 else -1.0) * n * 0.07, c - n * 0.38 + j5 * n * 0.08), Color(1.0, 0.75, 0.35), 0.4)
	for k7 in 4:
		turret(P(n * 0.22, k7 * PI * 0.5 + 0.35), 5.0)
	light(center, Color(1.0, 0.85, 0.5), 0.8, true)


## The Pilgrim Gate: a ceremonial gate ring of ivory and gold with the sun's rays all round and stained glass in its
## rim. It points home; the live drawing adds the light it throws towards Earth and the pilgrims passing through.
func _pilgrim_gate() -> void:
	var center := Vector2(c, c)
	for k in 12:
		var a := k * TAU / 12.0
		spire(center + Vector2.from_angle(a) * n * 0.36, a, n * 0.12, 7.0, 12.0)
	ring(center, n * 0.27, n * 0.37, HULL, 10.0, false, 24)
	ring(center, n * 0.3, n * 0.34, STAIN, 18.0, false, 24)
	for k2 in 24:
		var a2 := k2 * TAU / 24.0
		seg(center + Vector2.from_angle(a2) * n * 0.29, center + Vector2.from_angle(a2) * n * 0.35, 0.8, ACC, 19.0, P_FLAT, true)
	ring(center, n * 0.265, n * 0.285, ACC, 20.0, false, 48)
	ring(center, n * 0.36, n * 0.375, ACC, 20.0, false, 48)
	for k3 in 8:
		light(center + Vector2.from_angle(k3 * TAU / 8.0 + 0.2) * n * 0.32, Color(1.0, 0.85, 0.45), 0.7)


## The Forge of Return near Lauds: a foundry of crimson iron – furnace towers glowing, chimneys smoking, a farm of red
## focus crystals – berths with Covenant ships being built and, to the left, the gantries to the Lux Aeterna.
func _forge() -> void:
	var tx := c - n * 0.2
	for j in 3:
		var y := c + (j - 1) * n * 0.2
		seg(Vector2(2.0, y), Vector2(tx, y), 6.0, HULL, 9.0, P_GIRDER)
		seg(Vector2(2.0, y - 10.0), Vector2(tx, y - 10.0), 1.5, TRUSS, 10.0)
		for q in 4:
			light(Vector2(10.0 + q * (tx - 20.0) / 3.0, y), Color(1.0, 0.6, 0.3), 0.7)
		vent(Vector2(8.0 + j * 9.0, y + 5.0), "spark", 2.0)
	# the foundry block to the right with its furnace towers and chimneys
	box(Vector2(c + n * 0.2, c), 0.0, n * 0.26, n * 0.12, HULL, 11.0, P_ARMOR)
	for k in 3:
		var fp := Vector2(c + n * 0.06 + k * n * 0.14, c - n * 0.03)
		disc(fp, n * 0.058, HULL, 16.0, D_HOTTOWER)
		ring(fp, n * 0.058, n * 0.066, PANEL, 18.0, false, 16)
		vent(fp, "glow", n * 0.03)
		vent(fp + Vector2(0, n * 0.07), "smoke", 6.0)
		box(fp + Vector2(0, n * 0.07), 0.0, 4.0, 4.0, DARK, 18.0)
	box(Vector2(c + n * 0.2, c + n * 0.09), 0.0, n * 0.24, 2.0, ACC, 15.0)
	# the crystal farm below: clusters of red focus crystals in gold frames
	box(Vector2(c + n * 0.2, c + n * 0.28), 0.0, n * 0.25, n * 0.13, HULL, 8.0, P_ARMOR)
	box(Vector2(c + n * 0.2, c + n * 0.28), 0.0, n * 0.23, n * 0.11, PANEL, 9.0, P_GIRDER)
	# the great crystal in its gold cradle in the middle of the farm
	var gc := Vector2(c + n * 0.2, c + n * 0.28)
	poly(regular(gc, n * 0.06, 6, PI / 6.0), PANEL, 14.0, 3.0, 0)
	poly(PackedVector2Array([gc + Vector2(-n * 0.05, 0), gc + Vector2(0, -n * 0.035), gc + Vector2(n * 0.05, 0), gc + Vector2(0, n * 0.035)]), CRYST, 30.0, 4.0, 0)
	light(gc, Color(1.0, 0.3, 0.35), 0.4)
	for k2 in 22:
		var cp := Vector2(c + rng.randf_range(0.0, n * 0.42), c + n * 0.18 + rng.randf_range(0.0, n * 0.2))
		if cp.distance_to(gc) < n * 0.075:
			continue
		for j2 in 4:
			var a2 := -PI * 0.5 + rng.randf_range(-0.9, 0.9)
			var l := rng.randf_range(9.0, 22.0)
			poly(PackedVector2Array([cp - Vector2.from_angle(a2).orthogonal() * 3.5, cp + Vector2.from_angle(a2) * l, cp + Vector2.from_angle(a2).orthogonal() * 3.5]), CRYST, 12.0 + l, 2.0, 0)
		if k2 % 3 == 0:
			light(cp, Color(1.0, 0.25, 0.3), 0.5)
	# a berth above with a Covenant warship being built
	var base := Vector2(c + n * 0.2, c - n * 0.13)
	seg(base + Vector2(-n * 0.24, 0), base + Vector2(-n * 0.24, -n * 0.3), 3.5, HULL, 12.0, P_GIRDER)
	seg(base + Vector2(n * 0.24, 0), base + Vector2(n * 0.24, -n * 0.3), 3.5, HULL, 12.0, P_GIRDER)
	_hull_frame(base + Vector2(0, -n * 0.17), -1.0, n * 0.13, n * 0.06)
	for sp in 4:
		vent(base + Vector2(rng.randf_range(-n * 0.05, n * 0.05), -n * rng.randf_range(0.08, 0.28)), "spark", 2.0)
	# the tower over the gantries
	box(Vector2(tx, c), PI * 0.5, n * 0.3, 20.0, HULL, 14.0, P_ARMOR)
	box(Vector2(tx, c), PI * 0.5, n * 0.28, 3.0, ACC, 17.0)
	disc(Vector2(tx, c), 24.0, HULL, 20.0, D_HUB)
	spire(Vector2(tx, c - n * 0.3), -PI * 0.5, n * 0.08, 8.0, 18.0)
	spire(Vector2(tx, c + n * 0.3), PI * 0.5, n * 0.08, 8.0, 18.0)
	add_bay(0.0, n * 0.47, 12.0)
	for k3 in 4:
		turret(Vector2(tx + (1.0 if k3 % 2 == 0 else -1.0) * 26.0, c + (k3 - 1.5) * n * 0.16), 5.0)


## The Lux Aeterna, the Forge of Return's capital ship – long and splendid, crimson and gold. A great red focus crystal
## in a gold fork at the bow, huge weapon towers fore and aft along the spine, and at her heart a habitat ring the
## spine runs through; spires and stained glass on her towers, engines aft. Part of her is still under scaffolding.
func _lux_aeterna() -> void:
	# the spine (bow to the left)
	poly(PackedVector2Array([Vector2(_rx(0.08), _ry(-0.03)), Vector2(_rx(0.3), _ry(-0.06)), Vector2(_rx(0.82), _ry(-0.07)), Vector2(_rx(0.95), _ry(-0.05)),
		Vector2(_rx(0.95), _ry(0.05)), Vector2(_rx(0.82), _ry(0.07)), Vector2(_rx(0.3), _ry(0.06)), Vector2(_rx(0.08), _ry(0.03))]), HULL, 12.0, 3.0, 0)
	box(Vector2(_rx(0.52), c), 0.0, _rx(0.42), 2.0, ACC, 14.0)
	for sd in [-1.0, 1.0]:
		seg(Vector2(_rx(0.1), _ry(sd * 0.033)), Vector2(_rx(0.94), _ry(sd * 0.068)), 1.2, ACC, 13.0, P_FLAT, true)
	# the habitat ring at her heart
	var rc := Vector2(_rx(0.52), c)
	ring(rc, _rx(0.13), _rx(0.19), PANEL, -10.0, false, 32)
	ring(rc, _rx(0.14), _rx(0.18), HULL, 2.0, true, 32)
	for k in 12:
		var a := k * TAU / 12.0
		seg(rc + Vector2.from_angle(a) * _rx(0.06), rc + Vector2.from_angle(a) * _rx(0.135), 2.0, PANEL, 10.0, P_GIRDER)
		box(rc + Vector2.from_angle(a) * _rx(0.16), a, 4.0, 3.0, STAIN, 18.0, P_FLAT, true)
	ring(rc, _rx(0.185), _rx(0.195), ACC, 19.0, false, 64)
	disc(rc, _rx(0.06), HULL, 16.0, D_HUB)
	# the bow: a gold fork holding the great focus crystal
	for sd2 in [-1.0, 1.0]:
		poly(PackedVector2Array([Vector2(_rx(0.03), _ry(sd2 * 0.045)), Vector2(_rx(0.14), _ry(sd2 * 0.05)), Vector2(_rx(0.16), _ry(sd2 * 0.025)), Vector2(_rx(0.06), _ry(sd2 * 0.02))]), PANEL, 16.0, 2.0, 0)
	poly(PackedVector2Array([Vector2(_rx(0.025), c), Vector2(_rx(0.07), _ry(-0.028)), Vector2(_rx(0.13), c), Vector2(_rx(0.07), _ry(0.028))]), CRYST, 24.0, 3.0, 0)
	# weapon towers: two fore of the ring, two aft – heavy turrets with long twin barrels
	for tx in [0.24, 0.34, 0.7, 0.8]:
		var tp := Vector2(_rx(tx), c)
		poly(regular(tp, _rx(0.06), 8, PI / 8.0), HULL, 20.0, 3.0, 0)
		ring(tp, _rx(0.052), _rx(0.06), PANEL, 23.0, false, 16)
		disc(tp, _rx(0.038), PANEL, 28.0, D_TURRET)
		var aim := -1.0 if tx < 0.5 else 1.0                       # the fore towers aim ahead, the aft ones astern
		for sd3 in [-1.0, 1.0]:
			box(tp + Vector2(aim * _rx(0.075), sd3 * 6.0), 0.0, _rx(0.055), 2.8, GUN, 32.0)
			box(tp + Vector2(aim * _rx(0.128), sd3 * 6.0), 0.0, 3.0, 3.6, PANEL, 33.0)
		turrets.append(tp - Vector2(c, c))
	# side batteries and spires along her flanks
	for k2 in 6:
		var x := _rx(0.2 + k2 * 0.12)
		if absf(x - rc.x) < _rx(0.2):
			continue
		for sd4 in [-1.0, 1.0]:
			spire(Vector2(x, _ry(sd4 * 0.055)), PI * 0.5 * sd4, _rx(0.05), 5.0, 15.0)
	# the bridge tower aft, with stained glass
	box(Vector2(_rx(0.88), c), 0.0, _rx(0.05), _rx(0.035), HULL, 24.0, P_WINDOWS)
	lancet(Vector2(_rx(0.88), c), PI, 18.0, 4.0, 30.0)
	# engines
	for k3 in 4:
		var ep := Vector2(_rx(0.96), _ry((k3 - 1.5) * 0.026))
		disc(ep, _rx(0.013), DARK, 15.0, D_DISH)
		light(ep, Color(1.0, 0.55, 0.25), 0.5)
	# still under construction: a flank section bare under scaffolding, welders at work
	box(Vector2(_rx(0.75), _ry(0.06)), 0.0, _rx(0.08), _rx(0.025), TRUSS, 22.0, P_TRUSS, true)
	for k4 in 7:
		vent(Vector2(_rx(rng.randf_range(0.15, 0.92)), _ry(rng.randf_range(-0.06, 0.06))), "spark", 2.0)
	for k5 in 8:
		light(Vector2(_rx(0.12 + k5 * 0.11), _ry(0.075 * (1.0 if k5 % 2 == 0 else -1.0))), Color(1.0, 0.8, 0.4), 0.6)
	light(Vector2(_rx(0.06), c), Color(1.0, 0.3, 0.35), 0.9, true)

# ================================================================ 39c: landmarks of Durchbruch

## A hexagonal collector tile (green photovoltaic glass in a silver frame).
func collector(p: Vector2, r: float, h: float) -> void:
	poly(regular(p, r, 6, PI / 6.0), HULL, h, 1.5, 0)
	poly(regular(p, r - 2.5, 6, PI / 6.0), SOLAR, h + 3.0, 0.0, 0)
	_put(int(p.x), int(p.y), ACC, h + 3.0, true)


## The Meridian Sphere: the hub of the Dyson sphere, built into its shell – a hexagonal core of silver, a honeycomb
## of collector tiles round it, an energy conduit glowing green at its heart, three docking arms, dishes and radiators.
func _dyson_hub() -> void:
	var center := Vector2(c, c)
	# radiators (lowest), on the diagonals
	for k in 6:
		var a := k * TAU / 6.0 + PI / 6.0
		box(P(n * 0.38, a), a, n * 0.1, 3.0, PANEL, 7.0, P_RIBS)
	# the honeycomb of collectors
	var hx := n * 0.045
	for q in range(-5, 6):
		for r in range(-5, 6):
			var hp := center + Vector2(hx * 1.75 * (q + r * 0.5), hx * 1.52 * r)
			var d := hp.distance_to(center)
			if d < n * 0.17 or d > n * 0.36:
				continue
			collector(hp, hx * 0.95, 9.0)
	# three docking arms
	for k2 in 3:
		dock_arm(k2 * TAU / 3.0 - PI * 0.5, n * 0.14, n * 0.47, 46.0, 12.0)
	# the core
	poly(regular(center, n * 0.17, 6, 0.0), HULL, 14.0, 4.0, 10)
	poly(regular(center, n * 0.11, 6, 0.0), PANEL, 18.0, 3.0, 0)
	disc(center, n * 0.07, ACC, 22.0, D_HUB)
	disc(center, n * 0.03, GLASS, 26.0, D_DOME)
	for k3 in 6:
		var a3 := k3 * TAU / 6.0
		seg(P(n * 0.07, a3), P(n * 0.16, a3), 1.2, ACC, 19.0, P_FLAT, true)
		disc(P(n * 0.135, a3 + PI / 6.0), 7.0, DARK, 20.0, D_DISH)
		light(P(n * 0.17, a3), Color(0.4, 1.0, 0.65), 1.0)
	for k4 in 4:
		turret(P(n * 0.2, k4 * PI * 0.5 + 0.4), 5.0)
	light(center, Color(0.6, 1.0, 0.8), 0.6, true)


## A solar mirror over Curie: the hub with its control module and two small solar sails – the curved reflector itself
## is drawn live, turned to the planet (Celestial._draw_landmark_live).
func _mirror() -> void:
	var center := Vector2(c, c)
	solar_wing(P(n * 0.08, PI * 0.5), P(n * 0.22, PI * 0.5), 6.0, 5.0)
	solar_wing(P(n * 0.08, -PI * 0.5), P(n * 0.22, -PI * 0.5), 6.0, 5.0)
	disc(center, n * 0.075, HULL, 14.0, D_HUB)
	disc(center, n * 0.03, ACC, 17.0, D_DOME)
	light(center, Color(0.6, 1.0, 0.8), 1.2, true)


## A small jump gate being built by the Axiom Yards: a ring partly closed, partly still bare frame under scaffolding,
## welders at work. How far it has got comes from its seed.
func _gate_frame() -> void:
	var center := Vector2(c, c)
	var done := 0.35 + 0.6 * fposmod(float(rng.seed) * 0.618, 1.0)
	var start := rng.randf() * TAU
	var segs := 24
	for k in segs:
		var a := start + k * TAU / segs
		var p := center + Vector2.from_angle(a + PI / segs) * n * 0.36
		if float(k) / segs < done:
			box(p, a + PI * 0.5 + PI / segs, n * 0.05, n * 0.06, HULL, 12.0, P_ARMOR)
			box(p - Vector2.from_angle(a + PI / segs) * n * 0.04, a + PI * 0.5 + PI / segs, n * 0.045, 2.0, ACC, 15.0)
		else:
			box(p, a + PI * 0.5 + PI / segs, n * 0.05, n * 0.06, HULL, 10.0, P_TRUSS, true)
			if k % 2 == 0:
				vent(p, "spark", 2.0)
	for k2 in 4:
		var a2 := start + k2 * TAU / 4.0
		box(center + Vector2.from_angle(a2) * n * 0.44, a2, 6.0, 5.0, PANEL, 14.0)
		light(center + Vector2.from_angle(a2) * n * 0.46, Color(0.4, 1.0, 0.6), 1.2, true)


## The Axiom Yards at Meitner: a slender spine with swept sensor fins, berths with sleek Axiom hulls being built,
## docking at both ends. (The live drawing adds ships that cloak and uncloak; the small gates being built lie round it.)
func _axiom_yards() -> void:
	var center := Vector2(c, c)
	# swept fins
	for sd in [-1.0, 1.0]:
		poly(PackedVector2Array([Vector2(c - n * 0.05, c), Vector2(c - n * 0.3, c + sd * n * 0.42), Vector2(c - n * 0.2, c + sd * n * 0.44), Vector2(c + n * 0.08, c + sd * 0.04 * n)]), PANEL, 8.0, 2.0, 0)
		seg(Vector2(c - n * 0.02, c + sd * n * 0.02), Vector2(c - n * 0.25, c + sd * n * 0.43), 0.8, ACC, 10.0, P_FLAT, true)
	# the spine
	box(center, 0.0, n * 0.46, 13.0, HULL, 11.0, P_WINDOWS)
	box(center, 0.0, n * 0.44, 1.5, ACC, 13.0)
	# berths along the spine with sleek hulls
	for j in 3:
		var x := c + n * (0.06 + j * 0.13)
		for sd2 in [-1.0, 1.0]:
			var base := Vector2(x, c + sd2 * 15.0)
			var tip := Vector2(x, c + sd2 * n * 0.3)
			seg(base + Vector2(-n * 0.045, 0), tip + Vector2(-n * 0.045, 0), 2.0, HULL, 12.0, P_GIRDER)
			seg(base + Vector2(n * 0.045, 0), tip + Vector2(n * 0.045, 0), 2.0, HULL, 12.0, P_GIRDER)
			var mid := (base + tip) * 0.5
			poly(PackedVector2Array([mid + Vector2(0, -sd2 * n * 0.11), mid + Vector2(-n * 0.028, sd2 * n * 0.07), mid + Vector2(n * 0.028, sd2 * n * 0.07)]), PANEL, 13.0, 2.0, 0)
			seg(mid + Vector2(0, -sd2 * n * 0.1), mid + Vector2(0, sd2 * n * 0.06), 0.8, ACC, 15.0, P_FLAT, true)
			vent(mid, "spark", 2.0)
			light(tip, Color(0.4, 1.0, 0.6), 1.3, true)
	# sensor dishes and a hub at the left end
	disc(Vector2(c - n * 0.36, c), n * 0.06, HULL, 16.0, D_HUB)
	disc(Vector2(c - n * 0.36, c - n * 0.1), 9.0, DARK, 18.0, D_DISH)
	disc(Vector2(c - n * 0.36, c + n * 0.1), 9.0, DARK, 18.0, D_DISH)
	add_bay(0.0, n * 0.47, 12.0)
	add_bay(PI, n * 0.47, 12.0)
	for k in 4:
		turret(Vector2(c - n * 0.1 + k * n * 0.12, c + (1.0 if k % 2 == 0 else -1.0) * 20.0), 4.5)

## Package 26: a waystation – a small hub on struts with round landing pads (2 / 3 / 4 by tier) for S and M
## ships: hazard rim, a landing circle, a hatch in the middle the ships sink through, lights around it.
const PAD_R := 19.0


func _waystation() -> void:
	var center := Vector2(c, c)
	var count := tier + 1
	var rp := n * 0.33
	var hub := n * 0.12
	var off := rng.randf() * TAU
	# struts to the pads (lowest), then the hub
	for k in count:
		var ang := off + k * TAU / count
		seg(P(hub * 0.8, ang), P(rp - PAD_R, ang), 5.0, HULL, 9.0, P_PLATES)
		seg(P(hub * 0.8, ang + 0.18), P(rp - PAD_R * 0.6, ang + 0.35), 1.6, TRUSS, 8.0)
	ring(center, hub * 1.05, hub * 1.4, PANEL, 10.0, true, 12)
	disc(center, hub, HULL, 15.0, D_HUB)
	disc(center, hub * 0.45, ACC, 18.0, D_DOME)
	if tier >= 2:
		# a small solar array between two struts
		solar_wing(P(hub * 1.4, off + PI / count), P(n * 0.46, off + PI / count), 10.0)
	for k in count:
		var ang2 := off + k * TAU / count
		var pc := P(rp, ang2)
		var dir := Vector2.from_angle(ang2)
		disc(pc, PAD_R + 2.0, DARK, 10.0, D_FLAT)
		disc(pc, PAD_R, PANEL, 11.0, D_FLAT)
		ring(pc, PAD_R * 0.58, PAD_R * 0.66, MARK, 11.4, false, 24)        # the landing circle
		for j in 12:
			var a3 := j * TAU / 12.0
			if j % 2 == 0:
				box(pc + Vector2.from_angle(a3) * (PAD_R - 1.8), a3, 1.4, 2.6, ACC, 11.6, P_HAZARD)
		box(pc, ang2, 7.0, 7.0, DARK, 11.2)                                # the hatch (doors drawn live)
		for j2 in 4:
			light(pc + Vector2.from_angle(ang2 + PI * 0.25 + j2 * PI * 0.5) * (PAD_R + 1.0), Color(1.0, 0.72, 0.25), 1.2)
		pads.append({"pos": pc - Vector2(c, c), "radius": PAD_R, "dir": dir, "hatch": 7.0})
	light(center, Color(1, 1, 1), 1.0, true)


func _haven() -> void:
	# a cluster of patched-together wrecks around a scrap core
	var parts := 4 + tier
	var centers: Array = []
	for k in parts:
		var ang := k * TAU / parts + rng.randf_range(-0.4, 0.4)
		var r := n * rng.randf_range(0.17, 0.3)
		var p := P(r, ang)
		centers.append(p)
		var hl := rng.randf_range(n * 0.11, n * 0.19)
		var hw := rng.randf_range(n * 0.045, n * 0.075)
		var a2 := ang + rng.randf_range(-1.2, 1.2)
		box(p, a2, hl, hw, RUST if k % 2 == 0 else DARK, 8.0 + rng.randf() * 4.0, P_PLATES)
		box(p + Vector2.from_angle(a2) * hl * 0.6, a2, hl * 0.3, hw * 0.6, HULL, 12.0, P_CYL)
		# battle damage
		for hcount in 2:
			erase_disc(p + Vector2.from_angle(rng.randf() * TAU) * hw, rng.randf_range(2.0, 4.5))
		light(p + Vector2.from_angle(a2) * hl, Color(1.0, 0.15, 0.15), 1.2, true)
	for p2 in centers:
		seg(Vector2(c, c), p2, 2.0, TRUSS, 6.0)
	# containers
	for k in 8 + tier * 3:
		var cp := P(n * rng.randf_range(0.08, 0.35), rng.randf() * TAU)
		box(cp, rng.randf() * PI, 4.0, 2.5, [RUST, PANEL, ACC, DARK][rng.randi() % 4], 7.0, P_FLAT)
	disc(Vector2(c, c), n * 0.08, RUST, 12.0, D_DOME)
	disc(Vector2(c, c), n * 0.035, ACC, 18.0, D_DOME)
	var bang := rng.randf() * TAU
	box(P(n * 0.12 - 18.0, bang), bang, 22.0, 27.0, DARK, 10.0, P_PLATES)
	add_bay(bang, n * 0.12 + 3.0, 12.0, BAY_W - 4.0, BAY_D * 0.8)
	for k in 3 + tier:
		turret(P(n * rng.randf_range(0.14, 0.34), rng.randf() * TAU), 5.5)
	for k in 6:
		light(P(n * rng.randf_range(0.05, 0.4), rng.randf() * TAU), Color(1.0, 0.1, 0.1), rng.randf_range(0.5, 2.0), rng.randf() < 0.5)


# ================================================================ Shading

func _render() -> Image:
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var pal := _palettes()
	var outline := Color(0.05, 0.06, 0.09)
	for y in n:
		for x in n:
			var i := y * n + x
			var m := int(mat[i])
			if m == NONE:
				continue
			var h := hgt[i]
			if m == HANGAR:
				# hangar interior: dark, slightly see-through, deeper = darker
				var depth := clampf(-h, 0.0, 1.0)
				var hc := Color(0.09, 0.1, 0.14).lerp(Color(0.015, 0.015, 0.03), depth)
				img.set_pixel(x, y, Color(hc, 0.88))
				continue
			if m == MARK:
				img.set_pixel(x, y, Color(pal[MARK][1], 0.9))
				continue
			if m == STAIN:
				# 39b: stained glass – panes of colour in a dark lead mesh
				if posmod(x, 3) == 0 or posmod(y, 4) == 0:
					img.set_pixel(x, y, Color(0.12, 0.08, 0.06))
				else:
					var sc := [Color(0.85, 0.12, 0.15), Color(1.0, 0.75, 0.25), Color(0.2, 0.35, 0.9), Color(0.55, 0.2, 0.75), Color(1.0, 0.5, 0.15)]
					img.set_pixel(x, y, sc[int(_hash(x / 3, y / 4) * 5.0) % 5])
				continue
			var empty_n := _m(x - 1, y) == NONE or _m(x + 1, y) == NONE or _m(x, y - 1) == NONE or _m(x, y + 1) == NONE
			if empty_n and m != GLASS and m != NEON:
				img.set_pixel(x, y, outline)
				continue
			var hul := _h(x - 1, y - 1, h)
			var hdr := _h(x + 1, y + 1, h)
			var tone := 1
			var slope := hdr - hul
			if hul > h + 2.0:
				tone = 0                         # cast shadow of a taller part
			elif slope > 0.8:
				tone = 2
			elif slope < -0.8:
				tone = 0
			var cols: Array = pal[m]
			var col: Color = cols[tone]
			if m == GLASS or m == NEON or m == HOT:
				col = cols[1] if (x * 7 + y * 13) % 5 != 0 else cols[2]
			elif _hash(x, y) < 0.03 and tone > 0 and m != TRUSS:
				col = cols[tone - 1]             # dither
			img.set_pixel(x, y, col)
	return img


func _m(x: int, y: int) -> int:
	if x < 0 or y < 0 or x >= n or y >= n:
		return NONE
	return int(mat[y * n + x])


func _h(x: int, y: int, fallback: float) -> float:
	if x < 0 or y < 0 or x >= n or y >= n or mat[y * n + x] == NONE:
		return fallback - 3.0
	return hgt[y * n + x]


func _hash(x: int, y: int) -> float:
	var v := sin(float(x) * 12.9898 + float(y) * 78.233 + float(rng.seed % 1000)) * 43758.5453
	return v - floor(v)


func _palettes() -> Dictionary:
	var hull := [Color(0.3, 0.33, 0.4), Color(0.52, 0.56, 0.64), Color(0.76, 0.8, 0.88)]
	if ASSEMBLY_ARTS.has(type):
		hull = [Color(0.4, 0.45, 0.56), Color(0.66, 0.72, 0.82), Color(0.88, 0.92, 0.98)]     # Assembly white and blue
	var panel := [Color(0.33, 0.31, 0.3), Color(0.5, 0.48, 0.45), Color(0.68, 0.65, 0.6)]
	if DIRECTORATE_ARTS.has(type):
		hull = [Color(0.36, 0.4, 0.42), Color(0.6, 0.66, 0.68), Color(0.84, 0.9, 0.9)]          # 39c: Directorate silver
		panel = [Color(0.12, 0.14, 0.15), Color(0.2, 0.23, 0.24), Color(0.32, 0.36, 0.37)]      # graphite
	if type == "cathedral":
		hull = [Color(0.34, 0.05, 0.07), Color(0.58, 0.1, 0.12), Color(0.8, 0.22, 0.19)]       # 0.6.39.5: crimson …
		panel = [Color(0.55, 0.38, 0.1), Color(0.84, 0.64, 0.22), Color(1.0, 0.86, 0.45)]      # … and gold
	elif type == "pilgrim_gate":
		hull = [Color(0.44, 0.39, 0.33), Color(0.7, 0.64, 0.55), Color(0.9, 0.85, 0.75)]       # 39b: pale stone and ivory
		panel = [Color(0.36, 0.06, 0.08), Color(0.56, 0.1, 0.12), Color(0.74, 0.2, 0.18)]      # crimson
	elif type in ["forge", "lux_aeterna"]:
		hull = [Color(0.34, 0.07, 0.08), Color(0.56, 0.13, 0.13), Color(0.76, 0.26, 0.22)]      # 39b: Covenant crimson
		panel = [Color(0.4, 0.3, 0.12), Color(0.62, 0.48, 0.2), Color(0.82, 0.68, 0.32)]       # dull gold
	if type == "pirate_haven":
		hull = [Color(0.22, 0.22, 0.25), Color(0.38, 0.38, 0.42), Color(0.55, 0.55, 0.58)]
	elif type == "military":
		hull = [Color(0.26, 0.29, 0.3), Color(0.42, 0.46, 0.47), Color(0.6, 0.65, 0.66)]
	return {
		HULL: hull,
		DARK: [Color(0.16, 0.17, 0.21), Color(0.26, 0.28, 0.34), Color(0.38, 0.41, 0.48)],
		PANEL: panel,
		ACC: [acc.darkened(0.55), acc.darkened(0.2), acc.lerp(Color.WHITE, 0.3)],
		CRYST: [Color(0.45, 0.02, 0.08), Color(0.85, 0.1, 0.18), Color(1.0, 0.55, 0.6)],      # 39b: focus crystals
		GLASS: [Color(0.9, 0.8, 0.45), acc.lerp(Color(1.0, 0.92, 0.6), 0.6), Color(1.0, 0.97, 0.85)],
		SOLAR: [Color(0.06, 0.1, 0.26), Color(0.12, 0.2, 0.46), Color(0.3, 0.45, 0.8)],
		GREEN: [Color(0.1, 0.3, 0.14), Color(0.2, 0.55, 0.26), Color(0.55, 0.92, 0.5)],
		TANK: [Color(0.55, 0.56, 0.6), Color(0.78, 0.79, 0.82), Color(0.95, 0.96, 0.98)],
		RUST: [Color(0.3, 0.15, 0.09), Color(0.5, 0.27, 0.16), Color(0.68, 0.42, 0.26)],
		HANGAR: [Color(0.05, 0.05, 0.08), Color(0.05, 0.05, 0.08), Color(0.05, 0.05, 0.08)],
		TRUSS: [Color(0.24, 0.26, 0.31), Color(0.38, 0.41, 0.48), Color(0.55, 0.59, 0.67)],
		MARK: [Color(0.55, 0.45, 0.15), Color(0.75, 0.62, 0.2), Color(0.9, 0.78, 0.3)],
		HOT: [Color(1.0, 0.45, 0.1), Color(1.0, 0.6, 0.2), Color(1.0, 0.85, 0.45)],
		ICE: [Color(0.55, 0.7, 0.8), Color(0.75, 0.88, 0.96), Color(0.92, 0.98, 1.0)],
		NEON: [acc, acc.lerp(Color.WHITE, 0.35), Color(1.0, 0.95, 1.0)],
		ROCK: [Color(0.25, 0.2, 0.17), Color(0.42, 0.35, 0.29), Color(0.6, 0.52, 0.44)],
		GUN: [Color(0.2, 0.21, 0.24), Color(0.34, 0.36, 0.4), Color(0.5, 0.52, 0.58)],
	}
