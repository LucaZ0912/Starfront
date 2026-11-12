extends RefCounted
## 53f-2 (Luz): the wild – a great open ground on a jungle, ocean or ice world, to hunt in and explore, a find at its
## end. One map, no inside (the whole site is its outside). After Luz' approved mockups `mockup_53f2_*`:
##   JUNGLE – a rock wall with a waterfall in the north (no way up), thorny thicket round the other sides; the creek
##     from the falls' pool across the forest (fords of stepping stones), winding paths, sunny clearings, giant trees,
##     undergrowth, fallen trunks; at the end, beyond the creek, an overgrown site of the Precursors.
##   COAST – an island chain in the open sea (the breakers too big to swim): beaches, tide pools, palms, driftwood,
##     boardwalks and sand bars between the islands; on the last island a crashed landing drone in its crater.
##   ICE – an ice cliff in the north with a cave (the nest in it), open water with drifting floes in the east, pressure
##     ridges west and south; crevasses with bridges across, cracks, glare ice, blocks of ice for cover.
## The ground's terrain per tile (`ter`, meta "wild") says what blocks; the water's depth (`sdf`, tiles, + in water) is
## shared with the water shader (shaders/wild_water.gdshader – waves rolling in, the surf on the beach). The painter
## (`paint`, called by GroundMap while it renders) draws it all with scripts/ground/wild_art.gd.
## No class_name: preload it.

const T := GroundMap.T
const TILE := 16
const FK := 46                                   # the floor kind of the wild – the painter covers it
const WildArt = preload("res://scripts/ground/wild_art.gd")
const ExploreNode = preload("res://scripts/ground/explore.gd")
const PoiData = preload("res://data/poi.gd")
const FoeDataW = preload("res://data/foes.gd")

const OPEN := 0
const WATER := 1
const FORD := 2
const CLIFF := 3
const THICKET := 4
const CHASM := 5
const RIDGE := 6
const BOARD := 7
const CAVE := 8
const BRIDGE := 9
const BLOCKED := [WATER, CLIFF, THICKET, CHASM, RIDGE]
const SEE_THROUGH := [WATER, CHASM]              # blocked, but you see and shoot across
const LOW_COVER := [RIDGE]

## The light of each world – the map and its trees are lit by it (as in the mockups); the animals and you are not.
const TINT := {"jungle": Color(0.76, 0.82, 0.68), "coast": Color(0.9, 0.92, 0.9), "ice": Color(0.86, 0.9, 0.98)}
## The water's colours for the shader: shallow, mid, deep, foam; waves (0 still, 1 the sea).
const WATER_LOOK := {
	"jungle": {"shallow": Color(0.22, 0.42, 0.42), "mid": Color(0.16, 0.36, 0.42), "deep": Color(0.1, 0.24, 0.3), "foam": Color(0.75, 0.9, 0.95), "waves": 0.0},
	"coast": {"shallow": Color(0.35, 0.78, 0.78), "mid": Color(0.1, 0.45, 0.62), "deep": Color(0.04, 0.2, 0.38), "foam": Color(0.93, 0.97, 1.0), "waves": 1.0},
	"ice": {"shallow": Color(0.12, 0.22, 0.32), "mid": Color(0.08, 0.15, 0.24), "deep": Color(0.05, 0.1, 0.17), "foam": Color(0.75, 0.88, 0.98), "waves": 0.4},
}


static func h(x: int, y: int, s: int = 0) -> float:
	return WildArt.h(x, y, s)


# ================================================================== building the map

static func build(body: Dictionary, site: Dictionary, ship_len: float, ship_beam: float) -> GroundMap:
	var theme := String(site.get("theme", "wild_jungle"))
	var th: Dictionary = PoiData.THEMES.get(theme, PoiData.THEMES["wild_jungle"])
	var biome := String(th.get("biome", "jungle"))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(site.get("seed", 53)) + 29
	var m := GroundMap.new()
	m.pal = DeckGen.palette_for_body(body).duplicate()
	for key in ["floor", "floor2", "wall", "wall_top", "trim", "accent"]:
		m.pal[key] = th[key]
	m.pal["frame"] = (th["wall"] as Color).darkened(0.25)
	m.style = "wild"
	m.title = String(site.get("name", "The wild"))
	m.hull_top = -60
	var W := 104 if biome == "coast" else 100
	var H := 70 if biome == "coast" else 66
	m.setup(W, H)
	m.fill(0, 0, W, H, T.FLOOR, FK)
	var ter := PackedByteArray()
	ter.resize(W * H)
	ter.fill(OPEN)
	var sdf := PackedFloat32Array()
	sdf.resize(W * H)
	sdf.fill(-99.0)
	var pathm := PackedByteArray()
	pathm.resize(W * H)
	var wd := {"biome": biome, "seed": rng.randi() % 100000, "ter": ter, "sdf": sdf, "paths": [], "clear": [], "fords": [], "keep": [],
		"pathm": pathm}
	var sl := clampi(int(ceil(ship_len / TILE)) + 4, 10, 40)
	var sb := clampi(int(ceil(ship_beam / TILE)) + 4, 7, 20)
	match biome:
		"coast":
			_coast(m, wd, rng, sl, sb)
		"ice":
			_ice(m, wd, rng, sl, sb)
		_:
			_jungle(m, wd, rng, sl, sb)
	_apply(m, wd)
	_ship(m, wd, sl, sb, ship_len, ship_beam)
	_animals(m, wd, th, site, rng)
	m.set_meta("wild", wd)
	m.set_meta("tint", TINT.get(biome, Color.WHITE))
	m.set_meta("water", WATER_LOOK.get(biome, {}))
	var see := PackedByteArray()
	see.resize(W * H)
	for i in W * H:
		see[i] = 1 if ter[i] in SEE_THROUGH else (2 if ter[i] in LOW_COVER else 0)
	m.set_meta("see", see)
	var dg: Dictionary = PoiData.DANGER.get(String(site.get("danger", "yellow")), PoiData.DANGER["yellow"])
	var foes: Array = m.get_meta("foes", [])
	var n_pred := foes.filter(func(x): return String(FoeDataW.FOES.get(String(x).split("@")[0], {}).get("wild", "")) == "territory").size()
	var goal: String = {"jungle": "An overgrown site of the Precursors beyond the creek – something lies on its altar",
		"coast": "A landing drone came down on the far island – its cargo pod may be whole",
		"ice": "A cave in the ice cliff – a nest, and in it something glows"}.get(biome, "")
	m.set_meta("poi", {"name": String(site.get("name", "")), "theme": theme, "theme_name": String(th["name"]), "levels": 1, "minutes": 20,
		"danger": String(site.get("danger", "yellow")), "danger_name": String(dg["name"]), "depth": 0, "wild": true,
		"targets": [["wild_find", goal], ["animals", "%d animals – %d that defend their ground" % [foes.size(), n_pred]]]})
	return m


## The terrain made into walkable and blocked tiles.
static func _apply(m: GroundMap, wd: Dictionary) -> void:
	var ter: PackedByteArray = wd["ter"]
	for y in m.h:
		for x in m.w:
			if ter[y * m.w + x] in BLOCKED:
				m.set_t(x, y, T.BLOCK, FK)
	# the edge of the map: never walkable
	for x2 in m.w:
		m.set_t(x2, 0, T.BLOCK, FK)
		m.set_t(x2, m.h - 1, T.BLOCK, FK)
	for y2 in m.h:
		m.set_t(0, y2, T.BLOCK, FK)
		m.set_t(m.w - 1, y2, T.BLOCK, FK)


static func _ti(m: GroundMap, x: int, y: int) -> int:
	return clampi(y, 0, m.h - 1) * m.w + clampi(x, 0, m.w - 1)


static func ter_at(m: GroundMap, x: int, y: int) -> int:
	if x < 0 or y < 0 or x >= m.w or y >= m.h:
		return CLIFF
	return int((m.get_meta("wild")["ter"] as PackedByteArray)[y * m.w + x]) if m.has_meta("wild") else OPEN


## A line of water (a creek) or a chasm: its depth stamped into a grid – half width hw (art px) less the distance.
static func _stamp(m: GroundMap, grid: PackedFloat32Array, pts: PackedVector2Array, hw: float) -> void:
	var r := int(ceil(hw / TILE)) + 3
	for q in pts:
		var tx := int(q.x / TILE)
		var ty := int(q.y / TILE)
		for yy in range(ty - r, ty + r + 1):
			for xx in range(tx - r, tx + r + 1):
				if xx < 0 or yy < 0 or xx >= m.w or yy >= m.h:
					continue
				var d := (Vector2(xx + 0.5, yy + 0.5) * TILE).distance_to(q)
				var v := (hw - d) / TILE
				var i := yy * m.w + xx
				if v > grid[i]:
					grid[i] = v


## A winding way from a to b (art px): points about every 6 px, wiggled, smoothed.
static func _route(a: Vector2, b: Vector2, rng: RandomNumberGenerator, wig: float = 22.0) -> PackedVector2Array:
	var n := maxi(2, int(a.distance_to(b) / 48.0))
	var ctrl: Array = [a]
	var nrm := (b - a).normalized().orthogonal()
	for i in range(1, n):
		ctrl.append(a.lerp(b, float(i) / n) + nrm * rng.randf_range(-wig, wig))
	ctrl.append(b)
	for it in 2:                                          # Chaikin: rounder corners
		var sm: Array = [ctrl[0]]
		for k in ctrl.size() - 1:
			var p0: Vector2 = ctrl[k]
			var p1: Vector2 = ctrl[k + 1]
			sm.append(p0.lerp(p1, 0.25))
			sm.append(p0.lerp(p1, 0.75))
		sm.append(ctrl[ctrl.size() - 1])
		ctrl = sm
	var out := PackedVector2Array()
	for k2 in ctrl.size() - 1:
		var p2: Vector2 = ctrl[k2]
		var p3: Vector2 = ctrl[k2 + 1]
		var steps := maxi(1, int(p2.distance_to(p3) / 6.0))
		for s in steps:
			out.append(p2.lerp(p3, float(s) / steps))
	out.append(ctrl[ctrl.size() - 1])
	return out


static func _add_path(m: GroundMap, wd: Dictionary, pts: PackedVector2Array) -> void:
	(wd["paths"] as Array).append(pts)
	var pm: PackedByteArray = wd["pathm"]
	for q in pts:
		var tx := int(q.x / TILE)
		var ty := int(q.y / TILE)
		for yy in range(ty - 1, ty + 2):
			for xx in range(tx - 1, tx + 2):
				if xx >= 0 and yy >= 0 and xx < m.w and yy < m.h:
					pm[yy * m.w + xx] = 1


static func _in_keep(wd: Dictionary, x: int, y: int) -> bool:
	for r in wd["keep"]:
		if (r as Rect2).has_point(Vector2(x + 0.5, y + 0.5)):
			return true
	return false


static func _in_clearing(wd: Dictionary, p: Vector2, k: float = 1.0) -> bool:
	for c in wd["clear"]:
		var d := (p - (c[0] as Vector2)) / Vector2(float(c[1]), float(c[2])) / k
		if d.length() < 1.0:
			return true
	return false


## Is a tile free for a thing to stand on: open ground, off the paths, out of the kept places.
static func _free(m: GroundMap, wd: Dictionary, x: int, y: int, path_ok: bool = false) -> bool:
	if x < 2 or y < 2 or x >= m.w - 2 or y >= m.h - 2:
		return false
	var i := y * m.w + x
	if (wd["ter"] as PackedByteArray)[i] != OPEN or not GroundMap.walkable_t(m.t_at(x, y)):
		return false
	if not path_ok and (wd["pathm"] as PackedByteArray)[i] == 1:
		return false
	return not _in_keep(wd, x, y)


static func _block_obj(m: GroundMap, o: Dictionary, cells: Array) -> void:
	m.add_object(o, false)
	for c in cells:
		m.set_t(int(c.x), int(c.y), T.BLOCK, FK)


# ---------------------------------------------------------------- the ship's landing place

static func _ship_spot(m: GroundMap, wd: Dictionary, x0: int, y0: int, sl: int, sb: int) -> void:
	wd["ship_r"] = Rect2i(x0, y0, sl, sb)
	(wd["keep"] as Array).append(Rect2(x0 - 2, y0 - 2, sl + 6, sb + 6))
	(wd["clear"] as Array).append([Vector2(x0 + sl * 0.5, y0 + sb * 0.5) * TILE, (sl * 0.5 + 3.0) * TILE, (sb * 0.5 + 3.0) * TILE, "ship"])


static func _ship(m: GroundMap, wd: Dictionary, sl: int, sb: int, ship_len: float, ship_beam: float) -> void:
	var r: Rect2i = wd["ship_r"]
	var px0 := r.position.x
	var py0 := r.position.y
	var ter: PackedByteArray = wd["ter"]
	for yy in range(py0 - 1, py0 + sb + 2):
		for xx in range(px0 - 1, px0 + sl + 3):
			if xx > 0 and yy > 0 and xx < m.w - 1 and yy < m.h - 1 and ter[yy * m.w + xx] in BLOCKED:
				ter[yy * m.w + xx] = OPEN
				m.set_t(xx, yy, T.FLOOR, FK)
	var sc := Vector2(px0 + sl * 0.5, py0 + sb * 0.5)
	m.ship_at = sc * TILE
	var bx := int(sc.x - ship_len / TILE * 0.5) + 1
	var bw := maxi(2, int(ship_len / TILE) - 2)
	var bh := maxi(1, int(ship_beam / TILE) - 1)
	m.fill(bx, int(sc.y - bh * 0.5), bw, bh, T.BLOCK, FK)
	var rx := int(sc.x) - 1
	var ry := int(sc.y + bh * 0.5)
	m.decals.append({"kind": "ramp", "x": rx, "y": ry, "w": 2, "h": 2, "col": Color(1.0, 0.8, 0.25)})
	m.spawn = Vector2(rx + 1.0, ry + 2.6) * TILE
	m.zones.append({"rect": Rect2(Vector2(rx - 0.5, ry) * TILE, Vector2(3, 3.2) * TILE), "kind": "exit", "id": "ship",
		"title": "Up the ramp – take off", "col": Color(0.4, 1.0, 0.6), "sign": Vector2(-100, -100)})
	m.add_object({"kind": "fuel_point", "x": px0 + sl + 1, "y": py0, "w": 2, "h": 1, "rise": 34})
	m.zones.append({"rect": Rect2(Vector2(px0 + sl + 0.4, py0 + 1.0) * TILE, Vector2(3.2, 1.6) * TILE), "kind": "charge", "id": "charge",
		"title": "Supply point – energy, oxygen and ammunition", "col": Color(0.35, 0.95, 1.0), "sign": Vector2(-100, -100)})


# ---------------------------------------------------------------- the jungle

static func _jungle(m: GroundMap, wd: Dictionary, rng: RandomNumberGenerator, sl: int, sb: int) -> void:
	var W := m.w
	var H := m.h
	var ter: PackedByteArray = wd["ter"]
	var sdf: PackedFloat32Array = wd["sdf"]
	var sd: int = wd["seed"]
	# the rock wall in the north, the thicket round the rest
	var ch := PackedInt32Array()
	ch.resize(W)
	for x in W:
		ch[x] = 5 + int(h(x / 6, 1, sd) * 2.0)
		for y in ch[x]:
			ter[y * W + x] = CLIFF
	wd["cliff_h"] = ch
	for y2 in H:
		for x2 in W:
			var dw := 3 + int(h(y2 / 4, 2, sd) * 2.5)
			var de := 3 + int(h(y2 / 4, 3, sd) * 2.5)
			var ds := 3 + int(h(x2 / 4, 4, sd) * 2.5)
			if (x2 < dw or x2 >= W - de or y2 >= H - ds) and ter[y2 * W + x2] == OPEN:
				ter[y2 * W + x2] = THICKET
	# the waterfall, its pool, the creek across the forest to the east
	var wx := int(W * rng.randf_range(0.42, 0.55))
	wd["fall_x"] = wx
	var pool := Vector2(wx + 1.5, ch[wx] + 2.2) * TILE
	wd["pool"] = pool
	for yy in range(ch[wx], ch[wx] + 6):
		for xx in range(wx - 4, wx + 7):
			var v := (2.8 * TILE - (Vector2(xx + 0.5, yy + 0.5) * TILE).distance_to(pool)) / TILE
			if xx >= 0 and xx < W and v > sdf[yy * W + xx]:
				sdf[yy * W + xx] = v
	var creek := PackedVector2Array()
	var q := pool
	var tgt := Vector2(W * TILE + 40.0, H * rng.randf_range(0.58, 0.68) * TILE)
	var t := 0
	while q.x < W * TILE + 20.0 and t < 2000:
		creek.append(q)
		var dirv := (tgt - q).normalized().rotated(sin(t * 0.045 + sd) * 0.75)
		q += dirv * 6.0
		t += 1
	wd["creek"] = creek
	_stamp(m, sdf, creek, 24.0)
	for i in W * H:
		if sdf[i] > 0.0 and ter[i] != CLIFF:
			ter[i] = WATER
	# two fords of stepping stones
	for fr in [0.36, 0.74]:
		var fi := clampi(int(creek.size() * fr), 2, creek.size() - 3)
		var fc: Vector2 = creek[fi]
		var fdir: Vector2 = (creek[fi + 2] - creek[fi - 2]).normalized()
		(wd["fords"] as Array).append([fc, fdir])
		for yy2 in range(int(fc.y / TILE) - 3, int(fc.y / TILE) + 4):
			for xx2 in range(int(fc.x / TILE) - 3, int(fc.x / TILE) + 4):
				if xx2 < 0 or yy2 < 0 or xx2 >= W or yy2 >= H:
					continue
				var rel := Vector2(xx2 + 0.5, yy2 + 0.5) * TILE - fc
				if absf(rel.dot(fdir)) < 1.3 * TILE and rel.length() < 3.4 * TILE and ter[yy2 * W + xx2] == WATER:
					ter[yy2 * W + xx2] = FORD
	# the ship's landing place in the south-west; the Precursors' site beyond the creek in the north-east
	_ship_spot(m, wd, 7, H - sb - 7, sl, sb)
	var shrine := Vector2(W - 15, ch[W - 15] + 6)
	for tries in 12:
		var ok := true
		for yy3 in range(int(shrine.y) - 4, int(shrine.y) + 5):
			for xx3 in range(int(shrine.x) - 7, int(shrine.x) + 8):
				if xx3 >= 0 and xx3 < W and yy3 >= 0 and yy3 < H and sdf[yy3 * W + xx3] > -1.5:
					ok = false
		if ok:
			break
		shrine += Vector2(-3, 0) if tries % 2 == 0 else Vector2(0, -1)
	wd["shrine"] = shrine * TILE
	(wd["keep"] as Array).append(Rect2(shrine.x - 7, shrine.y - 4, 14, 9))
	for yy4 in range(int(shrine.y) - 4, int(shrine.y) + 5):
		for xx4 in range(int(shrine.x) - 7, int(shrine.x) + 8):
			if xx4 >= 0 and xx4 < W and ter[yy4 * W + xx4] == THICKET:
				ter[yy4 * W + xx4] = OPEN
	# clearings: one on this side for the herd, one beyond the creek, one in the south-east
	var cands := [Vector2(W * 0.3, H * 0.52), Vector2(W * 0.68, H * 0.24), Vector2(W * 0.74, H * 0.83)]
	for cc in cands:
		var c: Vector2 = cc
		for tries2 in 20:
			if _sdf_at(m, wd, c) < -6.0:
				break
			c += Vector2(rng.randf_range(-4, 4), rng.randf_range(-4, 4))
		(wd["clear"] as Array).append([c * TILE, rng.randf_range(6.0, 8.0) * TILE, rng.randf_range(4.0, 5.0) * TILE, "meadow"])
	var c1: Vector2 = (wd["clear"] as Array)[1][0]
	var c2: Vector2 = (wd["clear"] as Array)[2][0]
	var c3: Vector2 = (wd["clear"] as Array)[3][0]
	var f1: Vector2 = (wd["fords"] as Array)[0][0]
	var f2: Vector2 = (wd["fords"] as Array)[1][0]
	var sr: Rect2i = wd["ship_r"]
	var start := (Vector2(sr.position) + Vector2(sr.size.x + 3, sr.size.y * 0.5)) * TILE
	var goal: Vector2 = wd["shrine"] + Vector2(0, 3.5 * TILE)
	for leg in [[start, c1], [c1, f1], [f1, c2], [c2, goal], [c1, c3], [c3, f2], [f2, goal]]:
		_add_path(m, wd, _route(leg[0], leg[1], rng))
	# the find: on the altar of the overgrown site
	ExploreNode.add(m, "wild_find", wd["shrine"] + Vector2(0, 0.5 * TILE), {"style": "shrine", "seed": rng.randi()})
	m.lights.append({"pos": wd["shrine"] + Vector2(0, -6), "r": 60.0, "col": Color(0.7, 0.55, 1.0), "a": 0.45, "flicker": true})
	for pl in 2:
		var px := int(shrine.x) + (-6 if pl == 0 else 3)                 # stumps of its columns – cover
		_block_obj(m, {"kind": "wild_rock", "x": px, "y": int(shrine.y) + 2, "w": 2, "h": 1, "rise": 6, "seed": 3 + pl, "col": Color(0.5, 0.36, 0.26)},
			[Vector2(px, int(shrine.y) + 2), Vector2(px + 1, int(shrine.y) + 2)])
	# the giant trees, between the paths
	var trees: Array = []
	for tries3 in 900:
		var tx := rng.randi_range(4, W - 5)
		var ty := rng.randi_range(ch[clampi(tx, 0, W - 1)] + 3, H - 4)
		if not _free(m, wd, tx, ty) or _sdf_at(m, wd, Vector2(tx + 0.5, ty + 0.5)) > -1.6 or _in_clearing(wd, Vector2(tx + 0.5, ty + 0.5) * TILE, 1.1):
			continue
		var near := false
		for o in trees:
			if (o as Vector2).distance_to(Vector2(tx, ty)) < 4.6:
				near = true
				break
		if near:
			continue
		trees.append(Vector2(tx, ty))
		_block_obj(m, {"kind": "wild_tree", "x": tx - 2, "y": ty - 1, "w": 5, "h": 2, "rise": 78, "seed": rng.randi() % 7}, [Vector2(tx, ty)])
	# fallen trunks by the paths (cover), rocks
	var logs := 0
	for tries4 in 300:
		if logs >= 7:
			break
		var lx := rng.randi_range(5, W - 9)
		var ly := rng.randi_range(10, H - 6)
		var ok2 := true
		for k in 4:
			if not _free(m, wd, lx + k, ly, true) or (wd["pathm"] as PackedByteArray)[ly * W + lx + k] == 1:
				ok2 = false
		var by_path := false
		for yy5 in range(ly - 3, ly + 4):
			if yy5 > 0 and yy5 < H and (wd["pathm"] as PackedByteArray)[yy5 * W + lx + 1] == 1:
				by_path = true
		if ok2 and by_path:
			_block_obj(m, {"kind": "wild_log", "x": lx, "y": ly, "w": 4, "h": 1, "rise": 0, "seed": rng.randi() % 5}, [Vector2(lx, ly), Vector2(lx + 1, ly), Vector2(lx + 2, ly), Vector2(lx + 3, ly)])
			logs += 1
	for rk in 10:
		var rx := rng.randi_range(5, W - 6)
		var ry := rng.randi_range(9, H - 6)
		if _free(m, wd, rx, ry) and _free(m, wd, rx + 1, ry):
			_block_obj(m, {"kind": "wild_rock", "x": rx, "y": ry, "w": 2, "h": 1, "rise": 6, "seed": rng.randi() % 9, "col": Color(0.46, 0.44, 0.38)}, [Vector2(rx, ry), Vector2(rx + 1, ry)])


## The water's depth at a point (tiles) – bilinear between the tiles' centres.
static func _sdf_at(m: GroundMap, wd: Dictionary, p_tiles: Vector2) -> float:
	var sdf: PackedFloat32Array = wd["sdf"]
	var fx := p_tiles.x - 0.5
	var fy := p_tiles.y - 0.5
	var x0 := clampi(int(floor(fx)), 0, m.w - 1)
	var y0 := clampi(int(floor(fy)), 0, m.h - 1)
	var x1 := mini(x0 + 1, m.w - 1)
	var y1 := mini(y0 + 1, m.h - 1)
	var ax := clampf(fx - floor(fx), 0.0, 1.0)
	var ay := clampf(fy - floor(fy), 0.0, 1.0)
	var a := lerpf(sdf[y0 * m.w + x0], sdf[y0 * m.w + x1], ax)
	var b := lerpf(sdf[y1 * m.w + x0], sdf[y1 * m.w + x1], ax)
	return lerpf(a, b, ay)


# ---------------------------------------------------------------- the coast

static func _coast(m: GroundMap, wd: Dictionary, rng: RandomNumberGenerator, sl: int, sb: int) -> void:
	var W := m.w
	var H := m.h
	var ter: PackedByteArray = wd["ter"]
	var sdf: PackedFloat32Array = wd["sdf"]
	var sd: int = wd["seed"]
	# the islands: the big one in the south-west where you land, a chain of small ones to the north-east, the far one
	var isl: Array = [[Vector2(W * 0.2, H * 0.64), Vector2(W * 0.15, H * 0.22)]]
	var n_chain := 4
	var far := Vector2(W * 0.82, H * 0.22)
	var from: Vector2 = (isl[0][0] as Vector2) + (far - (isl[0][0] as Vector2)).normalized() * Vector2(W * 0.15, H * 0.22).length() * 0.8
	for k in n_chain:
		var f := (float(k) + 0.6) / (float(n_chain) + 0.4)
		var c := from.lerp(far, f) + Vector2(rng.randf_range(-4, 4), rng.randf_range(-5, 5))
		isl.append([c, Vector2(rng.randf_range(5.0, 7.5), rng.randf_range(3.5, 5.5))])
	isl.append([far, Vector2(12.0, 9.0)])
	# and a few that lead nowhere
	for k2 in 3:
		isl.append([Vector2(rng.randf_range(W * 0.5, W * 0.9), rng.randf_range(H * 0.55, H * 0.85)), Vector2(rng.randf_range(4.0, 7.0), rng.randf_range(3.0, 5.0))])
	wd["islands"] = isl
	for y in H:
		for x in W:
			var d := 99.0
			for il in isl:
				var c2: Vector2 = il[0]
				var r2: Vector2 = il[1]
				var e := (Vector2((x + 0.5 - c2.x) / r2.x, (y + 0.5 - c2.y) / r2.y).length() - 1.0) * minf(r2.x, r2.y)
				d = minf(d, e)
			d += (h(x / 3, y / 3, sd) - 0.5) * 1.6
			var edge := float(mini(mini(x, y), mini(W - 1 - x, H - 1 - y)))
			d = maxf(d, 4.0 - edge)
			sdf[y * W + x] = d
			if d > 0.0:
				ter[y * W + x] = WATER
	# between the islands of the chain: boardwalks on posts, or a sand bar at low tide
	var boards: Array = []
	for k3 in range(0, n_chain + 1):
		var a: Vector2 = (isl[k3][0] as Vector2) + Vector2(0.5, 0.5)
		var b: Vector2 = (isl[k3 + 1][0] as Vector2) + Vector2(0.5, 0.5)
		var bar := k3 % 2 == 1
		var seg := PackedVector2Array()
		var n := int(a.distance_to(b) * 3.0)
		for s in n + 1:
			var q := a.lerp(b, float(s) / n)
			var i := _ti(m, int(q.x), int(q.y))
			if sdf[i] > -1.2:
				seg.append(q * TILE)
				for oy in range(-1, 2):
					for ox in range(-1, 2):
						var xx := int(q.x) + ox
						var yy := int(q.y) + oy
						if xx > 0 and yy > 0 and xx < W - 1 and yy < H - 1 and (absi(ox) + absi(oy) <= 1 or bar) and ter[yy * W + xx] == WATER:
							ter[yy * W + xx] = FORD if bar else BOARD
		boards.append([seg, bar])
	wd["boards"] = boards
	# the ship on the big island
	var mc: Vector2 = isl[0][0]
	_ship_spot(m, wd, int(mc.x - sl * 0.5), int(mc.y - sb * 0.5) + 2, sl, sb)
	# the crater on the far island, the landing drone in it
	var cc := far + Vector2(0.5, 0.5)
	wd["crater"] = cc * TILE
	(wd["keep"] as Array).append(Rect2(cc.x - 6, cc.y - 5, 12, 10))
	_block_obj(m, {"kind": "lander_wreck", "x": int(cc.x) - 3, "y": int(cc.y) - 1, "w": 6, "h": 2, "rise": 46, "seed": sd % 9},
		[Vector2(int(cc.x) - 2, int(cc.y) - 1), Vector2(int(cc.x) - 1, int(cc.y) - 1), Vector2(int(cc.x), int(cc.y) - 1), Vector2(int(cc.x) + 1, int(cc.y) - 1),
		Vector2(int(cc.x) - 1, int(cc.y)), Vector2(int(cc.x), int(cc.y)), Vector2(int(cc.x) + 1, int(cc.y))])
	ExploreNode.add(m, "wild_find", (cc + Vector2(3.6, 2.2)) * TILE, {"style": "pod", "seed": rng.randi()})
	m.set_meta("plumes", [cc * TILE + Vector2(6, -18), cc * TILE + Vector2(-10, -10)])
	m.lights.append({"pos": cc * TILE, "r": 46.0, "col": Color(1.0, 0.6, 0.3), "a": 0.4, "flicker": true})
	# palms, rocks with seaweed, driftwood, tide pools (painted)
	var pools: Array = []
	for tries in 700:
		var x2 := rng.randi_range(3, W - 4)
		var y2 := rng.randi_range(3, H - 4)
		if not _free(m, wd, x2, y2) or not _free(m, wd, x2 + 1, y2):
			continue
		var dd := sdf[y2 * W + x2]
		var r3 := rng.randf()
		if dd < -2.5 and r3 < 0.1:
			_block_obj(m, {"kind": "palm", "x": x2 - 1, "y": y2, "w": 3, "h": 1, "rise": 50, "seed": rng.randi() % 8}, [Vector2(x2, y2)])
		elif dd > -2.2 and dd < -0.6 and r3 < 0.05:
			_block_obj(m, {"kind": "wild_rock", "x": x2, "y": y2, "w": 2, "h": 1, "rise": 6, "seed": rng.randi() % 9, "col": Color(0.42, 0.42, 0.44), "weed": true}, [Vector2(x2, y2), Vector2(x2 + 1, y2)])
		elif dd > -3.0 and dd < -1.0 and r3 < 0.035 and _free(m, wd, x2 + 2, y2):
			_block_obj(m, {"kind": "driftwood", "x": x2, "y": y2, "w": 3, "h": 1, "rise": 0, "seed": rng.randi() % 6}, [Vector2(x2, y2), Vector2(x2 + 1, y2), Vector2(x2 + 2, y2)])
		elif dd > -2.6 and dd < -1.2 and r3 < 0.06 and pools.size() < 16:
			pools.append(Vector2(x2 + 0.5, y2 + 0.5) * TILE)
	wd["pools"] = pools


# ---------------------------------------------------------------- the ice

static func _ice(m: GroundMap, wd: Dictionary, rng: RandomNumberGenerator, sl: int, sb: int) -> void:
	var W := m.w
	var H := m.h
	var ter: PackedByteArray = wd["ter"]
	var sdf: PackedFloat32Array = wd["sdf"]
	var sd: int = wd["seed"]
	# the ice cliff in the north; the cave in it with the nest
	var ch := PackedInt32Array()
	ch.resize(W)
	for x in W:
		ch[x] = 6 + int(h(x / 5, 1, sd) * 2.0)
		for y in ch[x]:
			ter[y * W + x] = CLIFF
	wd["cliff_h"] = ch
	var cx := int(W * rng.randf_range(0.56, 0.68))
	wd["cave_x"] = cx
	for yy in range(2, ch[cx] + 1):
		for xx in range(cx - 3, cx + 4):
			var e := Vector2((xx - cx) / 3.6, (yy - ch[cx]) / float(ch[cx] - 1)).length()
			if e < 1.0:
				ter[yy * W + xx] = CAVE
	# open water with pack ice in the east
	for y2 in H:
		var edge := W - 16.0 + sin(y2 * 0.15 + sd) * 2.5 + sin(y2 * 0.41) * 1.0
		for x2 in W:
			var d := x2 + 0.5 - edge
			sdf[y2 * W + x2] = d
			if d > 0.0 and ter[y2 * W + x2] == OPEN:
				ter[y2 * W + x2] = WATER
	# pressure ridges west and south
	var ridge: Array = []
	for y3 in H:
		var dw := 2 + int(h(y3 / 3, 2, sd) * 2.5)
		for x3 in dw:
			if ter[y3 * W + x3] == OPEN:
				ter[y3 * W + x3] = RIDGE
	for x4 in W:
		var ds := 2 + int(h(x4 / 3, 3, sd) * 2.5)
		for y4 in range(H - ds, H):
			if ter[y4 * W + x4] == OPEN:
				ter[y4 * W + x4] = RIDGE
	# the crevasses, a bridge over each
	var chasm := PackedFloat32Array()
	chasm.resize(W * H)
	chasm.fill(-99.0)
	var crevs: Array = []
	for cv in 2:
		var a := Vector2(W * (0.3 if cv == 0 else 0.5) + rng.randf_range(-3, 3), (ch[int(W * 0.3)] + 1.0) if cv == 0 else H * 0.42) * TILE
		var b := Vector2(W * (0.37 if cv == 0 else 0.78) + rng.randf_range(-3, 3), H - 10.0) * TILE
		var pts := PackedVector2Array()
		var n := int(a.distance_to(b))
		for s in n:
			var t := float(s) / n
			var q := a.lerp(b, t) + (b - a).normalized().orthogonal() * sin(t * 9.0 + cv * 2.0 + sd) * 18.0
			pts.append(q)
		crevs.append(pts)
		_stamp(m, chasm, pts, 15.0)
	wd["crevs"] = crevs
	for i in W * H:
		if chasm[i] > 0.0 and ter[i] == OPEN:
			ter[i] = CHASM
	wd["chasm"] = chasm
	var bridges: Array = []
	for cv2 in crevs.size():
		var pts2: PackedVector2Array = crevs[cv2]
		var bi := int(pts2.size() * (0.45 if cv2 == 0 else 0.55))
		var bc := pts2[bi]
		var bdir := (pts2[mini(bi + 3, pts2.size() - 1)] - pts2[maxi(bi - 3, 0)]).normalized()
		bridges.append([bc, bdir])
		for yy5 in range(int(bc.y / TILE) - 3, int(bc.y / TILE) + 4):
			for xx5 in range(int(bc.x / TILE) - 3, int(bc.x / TILE) + 4):
				if xx5 < 0 or yy5 < 0 or xx5 >= W or yy5 >= H:
					continue
				var rel := Vector2(xx5 + 0.5, yy5 + 0.5) * TILE - bc
				if absf(rel.dot(bdir)) < 1.2 * TILE and rel.length() < 2.6 * TILE and ter[yy5 * W + xx5] == CHASM:
					ter[yy5 * W + xx5] = BRIDGE
	wd["bridges"] = bridges
	# the ship in the south-west; the nest in the cave
	_ship_spot(m, wd, 6, H - sb - 6, sl, sb)
	var nest := Vector2(cx + 0.5, ch[cx] - 1.6) * TILE
	wd["nest"] = nest
	(wd["keep"] as Array).append(Rect2(cx - 4, 0, 9, ch[cx] + 3))
	ExploreNode.add(m, "wild_find", nest + Vector2(0, 8), {"style": "nest", "seed": rng.randi()})
	m.lights.append({"pos": nest, "r": 48.0, "col": Color(0.5, 0.85, 1.0), "a": 0.5, "flicker": true})
	# blocks of ice for cover, broken ice
	var blocks := 0
	for tries in 500:
		if blocks >= 16:
			break
		var bx := rng.randi_range(4, W - 18)
		var by := rng.randi_range(ch[clampi(bx, 0, W - 1)] + 3, H - 6)
		if _free(m, wd, bx, by) and _free(m, wd, bx + 1, by) and chasm[by * W + bx] < -1.0:
			_block_obj(m, {"kind": "ice_block", "x": bx, "y": by, "w": 2, "h": 1, "rise": 14, "seed": rng.randi() % 9}, [Vector2(bx, by), Vector2(bx + 1, by)])
			blocks += 1
	var patches: Array = []
	for gl in 16:
		patches.append([Vector2(rng.randf_range(6, W - 20), rng.randf_range(10, H - 8)) * TILE, rng.randf_range(16.0, 40.0)])
	wd["glare"] = patches


# ================================================================== the animals

static func _animals(m: GroundMap, wd: Dictionary, th: Dictionary, site: Dictionary, rng: RandomNumberGenerator) -> void:
	var foes: Array = []
	var spawns: Array = []
	var danger := String(site.get("danger", "yellow"))
	var ship_c: Vector2 = Vector2((wd["ship_r"] as Rect2i).get_center()) * TILE
	var groups: Array = (th.get("animals", []) as Array).duplicate(true)
	if site.has("hunt_kind"):
		groups.append([String(site["hunt_kind"]), int(site.get("hunt_n", 1)) + (0 if bool(site.get("hunt_alpha", false)) else 1), "solo"])
	var herd_i := 0
	var alpha_done := false
	for g in groups:
		var kind := String(g[0])
		var n := int(g[1])
		var how := String(g[2])
		var fd: Dictionary = FoeDataW.FOES.get(kind, {})
		var pred := String(fd.get("wild", "")) == "territory"
		var tier := "green"
		if pred:
			tier = {"green": "green", "yellow": "yellow", "red": "red"}.get(danger, "yellow")
			if danger == "yellow" and rng.randf() < 0.4:
				tier = "green"
		var centre := Vector2.INF
		if how == "herd":
			var cl: Array = (wd["clear"] as Array).filter(func(c): return String(c[3]) == "meadow")
			if not cl.is_empty():
				centre = cl[herd_i % cl.size()][0]
				herd_i += 1
		if how in ["herd", "pack"] and centre == Vector2.INF:
			centre = _spot(m, wd, rng, kind, ship_c)
		for i in n:
			var p := Vector2.INF
			if centre != Vector2.INF:
				for tries in 30:
					var q := centre + Vector2(rng.randf_range(-40, 40), rng.randf_range(-26, 26))
					if m.free_at(q, 5.0) and _tile_ok(m, wd, q):
						p = q
						break
			if p == Vector2.INF:
				p = _spot(m, wd, rng, kind, ship_c)
			if p == Vector2.INF:
				continue
			var entry := "%s@%s" % [kind, tier]
			if site.has("hunt_kind") and kind == String(site["hunt_kind"]) and bool(site.get("hunt_alpha", false)) and not alpha_done:
				entry = "%s@red" % kind
				alpha_done = true
				m.set_meta("alpha_i", spawns.size())
			foes.append(entry)
			spawns.append(p)
	m.foe_spawns = spawns
	m.set_meta("foes", foes)


static func _tile_ok(m: GroundMap, wd: Dictionary, p: Vector2) -> bool:
	var x := int(p.x / TILE)
	var y := int(p.y / TILE)
	return _free(m, wd, x, y, true)


## A place for an animal of a kind: away from the ship, where its kind lives.
static func _spot(m: GroundMap, wd: Dictionary, rng: RandomNumberGenerator, kind: String, ship_c: Vector2) -> Vector2:
	for tries in 300:
		var x := rng.randi_range(4, m.w - 5)
		var y := rng.randi_range(4, m.h - 5)
		if not _free(m, wd, x, y, kind in ["glider", "shore_crab", "furball", "grazer"]):
			continue
		var p := Vector2(x + 0.5, y + 0.6) * TILE
		if p.distance_to(ship_c) < 260.0:
			continue
		var d := _sdf_at(m, wd, Vector2(x + 0.5, y + 0.5))
		match kind:
			"lurker":
				if d < -4.5 or d > -0.8:
					continue                                       # by the creek, in the reeds
			"shore_crab":
				if d < -2.6 or d > -0.4:
					continue
			"armor_crab":
				if d < -3.5 or d > -0.8 or p.distance_to(ship_c) < 420.0:
					continue
			"sand_lurker":
				if d > -1.8:
					continue
			"frost_bear", "pack_hunter":
				if p.distance_to(ship_c) < 480.0:
					continue
		if not m.free_at(p, 5.0):
			continue
		return p
	return Vector2.INF


# ================================================================== painting

## Paints the whole ground of the wild into the map's image (GroundMap calls it while it renders); water is left
## clear – the water shader lies under the map.
static func paint(m: GroundMap, img: Image) -> void:
	var wd: Dictionary = m.get_meta("wild")
	var p = WildArt.new(img)
	match String(wd["biome"]):
		"coast":
			_paint_coast(m, wd, p)
		"ice":
			_paint_ice(m, wd, p)
		_:
			_paint_jungle(m, wd, p)


## Water and land at the pixel: the depth between the tiles, a little noise in the shore. Clears the water, paints a
## band along the shore (mud, wet sand, the ice's edge).
static func _carve(m: GroundMap, wd: Dictionary, p, bank_a: Color, bank_b: Color, band: float, sd: int) -> void:
	var sdf: PackedFloat32Array = wd["sdf"]
	var clear := Color(0, 0, 0, 0)
	for ty in m.h:
		for tx in m.w:
			var lo := 99.0
			var hi := -99.0
			for oy in range(-1, 2):
				for ox in range(-1, 2):
					var v: float = sdf[_ti(m, tx + ox, ty + oy)]
					lo = minf(lo, v)
					hi = maxf(hi, v)
			if hi < -band - 0.6:
				continue                                          # dry land all round
			if lo > 1.0:
				p.img.fill_rect(Rect2i(tx * TILE, ty * TILE, TILE, TILE), clear)      # open water
				continue
			for py in range(ty * TILE, ty * TILE + TILE):
				for px in range(tx * TILE, tx * TILE + TILE):
					var v2 := _sdf_at(m, wd, Vector2(px + 0.5, py + 0.5) / TILE) + (WildArt.h(px / 3, py / 3, sd) - 0.5) * 0.35
					if v2 > 0.0:
						p.img.set_pixel(px, py, clear)
					elif v2 > -band:
						p.P(px, py, bank_a.lerp(bank_b, WildArt.h(px / 2, py / 2, sd + 1)).lerp(p.img.get_pixel(px, py), clampf(-v2 / band, 0.0, 1.0) * 0.6))


## A meadow: an ellipse of grass that fades into the ground at a ragged edge.
static func _meadow(p, c: Vector2, rx: float, ry: float, col: Color, sd: int) -> void:
	for y in range(int(c.y - ry) - 2, int(c.y + ry) + 3):
		for x in range(int(c.x - rx) - 2, int(c.x + rx) + 3):
			var e := Vector2((x - c.x) / rx, (y - c.y) / ry).length() + (WildArt.h(x / 4, y / 4, sd + 77) - 0.5) * 0.3
			if e < 1.0:
				p.P(x, y, Color(col.lerp(col.lightened(0.12), WildArt.h(x / 2, y / 2, sd + 78)), clampf((1.0 - e) * 3.0, 0.0, 0.85)))


static func _stroke(p, pts: PackedVector2Array, r: float, a: Color, b: Color, sd: int, step: int = 3) -> void:
	for i in range(0, pts.size(), step):
		var q := pts[i]
		p.circ(q.x, q.y, r, a.lerp(b, WildArt.h(int(q.x) / 3, int(q.y) / 3, sd)), r * 0.7)


static func _paint_jungle(m: GroundMap, wd: Dictionary, p) -> void:
	var sd: int = wd["seed"]
	var W := m.w * TILE
	var H := m.h * TILE
	var ter: PackedByteArray = wd["ter"]
	p.tile_ground(Color(0.17, 0.24, 0.1), Color(0.12, 0.17, 0.07), 501)
	for bl in 70:                                                      # darker and lighter hollows in the litter
		p.circ(WildArt.h(bl, 1, sd) * W, WildArt.h(bl, 2, sd) * H, 30.0 + WildArt.h(bl, 3, sd) * 40.0,
			Color(0.08, 0.12, 0.04, 0.25) if bl % 2 == 0 else Color(0.25, 0.3, 0.12, 0.18), 20.0 + WildArt.h(bl, 4, sd) * 20.0)
	# the clearings with sun on them
	for cl in wd["clear"]:
		var c: Vector2 = cl[0]
		_meadow(p, c, float(cl[1]), float(cl[2]), Color(0.3, 0.42, 0.16), sd)
		for gr in int(float(cl[1]) * float(cl[2]) * 0.12):
			var a3 := WildArt.h(gr, 1, sd + int(c.x)) * TAU
			var d3 := sqrt(WildArt.h(gr, 2, sd + int(c.x)))
			p.grass_tuft(c.x + cos(a3) * d3 * float(cl[1]), c.y + sin(a3) * d3 * float(cl[2]), Color(0.42, 0.6, 0.24), gr)
		if String(cl[3]) == "ship":
			for sc in 30:                                              # scorched where the ship came down
				p.circ(c.x + (WildArt.h(sc, 1, sd) - 0.5) * float(cl[1]) * 1.4, c.y + (WildArt.h(sc, 2, sd) - 0.5) * float(cl[2]) * 1.2, 6.0, Color(0.2, 0.16, 0.1, 0.4), 3.0)
	# the paths – packed earth, tufts along their edges
	for pts in wd["paths"]:
		_stroke(p, pts, 9.0, Color(0.42, 0.33, 0.2), Color(0.36, 0.28, 0.17), 517, 1)
	for pts2 in wd["paths"]:
		var pa: PackedVector2Array = pts2
		for e in range(0, pa.size(), 7):
			var nrm := (pa[mini(e + 1, pa.size() - 1)] - pa[maxi(e - 1, 0)]).normalized().orthogonal()
			p.grass_tuft(pa[e].x + nrm.x * 10.0, pa[e].y + nrm.y * 10.0, Color(0.35, 0.55, 0.22), e)
			if e % 21 == 0:
				p.R(int(pa[e].x) - 6, int(pa[e].y) - 1, 12, 2, Color(0.3, 0.22, 0.13))        # a root across the path
	# leaf litter, twigs, moss
	for i in int(W * H / 170):
		var px := int(WildArt.h(i, 1, 511) * W)
		var py := int(WildArt.h(i, 2, 511) * H)
		match i % 4:
			0:
				p.leaf(px, py, WildArt.h(i, 3, 511) * TAU, 3.0, Color(0.45, 0.33, 0.14))
			1:
				p.leaf(px, py, WildArt.h(i, 3, 511) * TAU, 2.5, Color(0.3, 0.42, 0.16))
			2:
				p.R(px, py, 3, 1, Color(0.32, 0.24, 0.14))
			_:
				p.circ(px, py, 2.5, Color(0.25, 0.38, 0.14), 1.5)
	# the creek: muddy banks, water clear for the shader, reeds, the fords' stepping stones
	_carve(m, wd, p, Color(0.26, 0.24, 0.16), Color(0.22, 0.2, 0.13), 0.55, sd)
	var creek: PackedVector2Array = wd["creek"]
	for k2 in range(0, creek.size(), 5):
		if k2 % 15 == 0:
			var q3: Vector2 = creek[k2]
			var nrm2 := (creek[mini(k2 + 1, creek.size() - 1)] - creek[maxi(k2 - 1, 0)]).normalized().orthogonal()
			for side in [-1.0, 1.0]:
				var rp: Vector2 = q3 + nrm2 * 30.0 * side
				if ter[_ti(m, int(rp.x / TILE), int(rp.y / TILE))] == OPEN:
					for rd in 4:
						p.R(int(rp.x) + rd * 2, int(rp.y) - 7 + rd % 2, 1, 7, Color(0.4, 0.55, 0.25))
						p.P(int(rp.x) + rd * 2, int(rp.y) - 8 + rd % 2, Color(0.55, 0.42, 0.25))
	for fd in wd["fords"]:
		var fc: Vector2 = fd[0]
		var fdir: Vector2 = fd[1]
		var nrm3 := fdir.orthogonal()
		for st in range(-5, 6):
			var sp: Vector2 = fc + nrm3 * st * 8.0 + fdir * (WildArt.h(st, 1, sd) - 0.5) * 6.0
			p.rock(sp.x, sp.y, 4.5, Color(0.55, 0.53, 0.48), sd + st)
			p.rock(sp.x + fdir.x * 9.0, sp.y + fdir.y * 9.0, 3.5, Color(0.5, 0.49, 0.45), sd + st + 30)
	# undergrowth: big leaves, ferns, flowers
	for ug in int(m.w * m.h / 5):
		var ux := WildArt.h(ug, 5, 525) * W
		var uy := WildArt.h(ug, 6, 525) * H
		var tx := int(ux / TILE)
		var ty := int(uy / TILE)
		if ter[_ti(m, tx, ty)] != OPEN or (wd["pathm"] as PackedByteArray)[_ti(m, tx, ty)] == 1 or _in_clearing(wd, Vector2(ux, uy), 0.9):
			continue
		match ug % 5:
			0, 4:
				p.broadleaf(ux, uy, 526 + ug, 0.9 if ug % 5 == 0 else 0.6)
			1:
				p.fern(ux, uy, 527 + ug)
			2:
				p.flower_bush(ux, uy, [Color(0.95, 0.3, 0.45), Color(1.0, 0.8, 0.25), Color(0.65, 0.4, 1.0)][ug % 3], 528 + ug)
			_:
				p.fern(ux, uy, 529 + ug)
	# the thicket round the edges – too dense to push through
	for ty2 in m.h:
		for tx2 in m.w:
			if ter[ty2 * m.w + tx2] == THICKET:
				p.thorn_bush(tx2 * TILE + 8 + (WildArt.h(tx2, ty2, sd) - 0.5) * 8.0, ty2 * TILE + 8 + (WildArt.h(ty2, tx2, sd) - 0.5) * 6.0, 10.0 + WildArt.h(tx2, ty2, sd + 1) * 3.0, sd + tx2 * 131 + ty2)
	# the rock wall in the north with the waterfall
	var ch: PackedInt32Array = wd["cliff_h"]
	for xp in m.w * TILE:
		var topp := _cliff_top(m, ch, xp, sd)
		p.cliff_face(xp, 0, 1, topp, Color(0.42, 0.38, 0.32), 512)
		p.R(xp, topp - 2, 1, 2, Color(0.2, 0.18, 0.15))
	for sc in m.w * 2:                                                   # scree at its foot
		var sx := sc * 8 + WildArt.h(sc, 1, sd) * 6.0
		p.rock(sx, _cliff_top(m, ch, int(sx), sd) + 2.0 + WildArt.h(sc, 2, sd) * 4.0, 3.0 + WildArt.h(sc, 3, sd) * 3.0, Color(0.44, 0.4, 0.34), sd + sc)
	for x in m.w:
		var top := ch[x] * TILE
		for v in 3:                                                    # creepers hanging down the wall
			if WildArt.h(x, v, sd + 3) < 0.35:
				var vx := x * TILE + v * 5 + 2
				for t2 in int(WildArt.h(x, v, sd + 4) * float(top) * 0.7):
					p.P(vx + int(sin(t2 * 0.4) * 1.2), top - 1 - t2 if v % 2 == 0 else t2, Color(0.2, 0.38, 0.16))
	var wx: int = wd["fall_x"]
	var ftop := ch[wx] * TILE
	for wf in ftop + 6:
		for wxx in range(wx * TILE + 2, wx * TILE + 3 * TILE - 2):
			p.P(wxx, wf, Color(0.6, 0.78, 0.9).lerp(Color(0.85, 0.95, 1.0), WildArt.h(wxx, wf, 513)))
	# the overgrown site of the Precursors: a platform of rusted stone, a gate in the wall, vines over all of it
	var sh: Vector2 = wd["shrine"]
	p.R(int(sh.x) - 88, int(sh.y) - 40, 176, 96, Color(0.38, 0.27, 0.2))
	for rs in 260:
		var rx := int(sh.x) - 88 + int(WildArt.h(rs, 1, 531) * 176)
		var ry := int(sh.y) - 40 + int(WildArt.h(rs, 2, 531) * 96)
		p.R(rx, ry, 3, 1, Color(0.55, 0.34, 0.2) if rs % 3 else Color(0.28, 0.2, 0.15))
	for gx in range(-88, 88, 16):
		p.R(int(sh.x) + gx, int(sh.y) - 40, 1, 96, Color(0.3, 0.21, 0.15))
	for gy in range(-40, 56, 16):
		p.R(int(sh.x) - 88, int(sh.y) + gy, 176, 1, Color(0.3, 0.21, 0.15))
	for col in 3:                                                       # fallen columns lying across it, mossed
		var cx0 := int(sh.x) - 80 + col * 58
		var cy0 := int(sh.y) - 30 + (col % 2) * 52
		for t in 34:
			for th in 8:
				var cc := Color(0.5, 0.37, 0.27).lerp(Color(0.32, 0.23, 0.17), float(th) / 8.0)
				if t % 9 == 0:
					cc = cc.darkened(0.2)
				if th < 2 and WildArt.h(t, col, sd) < 0.5:
					cc = Color(0.3, 0.46, 0.2)
				p.P(cx0 + t, cy0 + th, cc)
		p.R(cx0, cy0 + 8, 34, 2, Color(0, 0, 0, 0.3))
	p.R(int(sh.x) - 14, int(sh.y) - 18, 28, 20, Color(0.48, 0.35, 0.26))                # the altar
	p.R(int(sh.x) - 14, int(sh.y) - 18, 28, 2, Color(0.6, 0.45, 0.32))
	p.R(int(sh.x) - 12, int(sh.y) + 2, 24, 4, Color(0.3, 0.21, 0.15))
	for vn in 40:
		var vx2 := int(sh.x) - 88 + int(WildArt.h(vn, 1, 533) * 176)
		var vy2 := int(sh.y) - 40 + int(WildArt.h(vn, 2, 533) * 96)
		for t4 in 6 + vn % 5 * 3:
			p.P(vx2 + int(sin(t4 * 0.6) * 1.2), vy2 + t4, Color(0.25, 0.48, 0.2))
		if vn % 3 == 0:
			p.leaf_cluster(vx2, vy2, 5.0, [Color(0.1, 0.25, 0.1), Color(0.2, 0.42, 0.16), Color(0.4, 0.6, 0.25)], vn)
	var gate_top := ch[clampi(int(sh.x / TILE), 0, m.w - 1)] * TILE
	p.R(int(sh.x) - 22, gate_top - 50, 44, 50, Color(0.38, 0.27, 0.2))
	p.R(int(sh.x) - 13, gate_top - 40, 26, 40, Color(0.06, 0.05, 0.05))
	p.R(int(sh.x) - 22, gate_top - 50, 44, 3, Color(0.5, 0.38, 0.28))
	for vn2 in 14:
		for t5 in 6 + vn2 % 5 * 3:
			p.P(int(sh.x) - 20 + vn2 * 3 + int(sin(t5 * 0.6) * 1.2), gate_top - 50 + t5, Color(0.25, 0.48, 0.2))


## The foot of a cliff at a pixel column: smooth between the tiles' rows, a little ragged.
static func _cliff_top(m: GroundMap, ch: PackedInt32Array, xp: int, sd: int) -> int:
	var tx := clampi(xp / TILE, 0, m.w - 1)
	var f := float(xp % TILE) / TILE
	var a := float(ch[tx])
	var v := a
	if f >= 0.5:
		v = lerpf(a, float(ch[mini(tx + 1, m.w - 1)]), f - 0.5)
	else:
		v = lerpf(a, float(ch[maxi(tx - 1, 0)]), 0.5 - f)
	return int(v * TILE + (WildArt.h(xp / 3, 1, sd + 9) - 0.5) * 4.0)


static func _paint_coast(m: GroundMap, wd: Dictionary, p) -> void:
	var sd: int = wd["seed"]
	var W := m.w * TILE
	var H := m.h * TILE
	var sdf: PackedFloat32Array = wd["sdf"]
	p.tile_ground(Color(0.86, 0.78, 0.58), Color(0.78, 0.7, 0.5), 601)
	for i in int(W * H / 90):                                          # shells, pebbles, darker grains
		var px := int(WildArt.h(i, 1, 602) * W)
		var py := int(WildArt.h(i, 2, 602) * H)
		p.P(px, py, Color(0.68, 0.6, 0.44) if i % 3 else Color(0.95, 0.9, 0.82))
	# grass on the islands' crowns, fading out into the sand; tufts of dune grass; the wrack line of the high tide
	for ty in m.h:
		for tx in m.w:
			var tv := sdf[ty * m.w + tx]
			if tv < -1.4:
				for py in range(ty * TILE, ty * TILE + TILE):
					for px in range(tx * TILE, tx * TILE + TILE):
						var v := _sdf_at(m, wd, Vector2(px + 0.5, py + 0.5) / TILE) + (WildArt.h(px / 5, py / 5, sd + 3) - 0.5) * 1.6
						if v < -3.4:
							p.P(px, py, Color(Color(0.34, 0.5, 0.24).lerp(Color(0.42, 0.58, 0.28), WildArt.h(px / 2, py / 2, sd + 4)), clampf((-3.4 - v) * 0.9, 0.0, 0.8)))
				for g in (4 if tv < -2.8 else 0):
					var gx := tx * TILE + WildArt.h(tx * 7 + g, ty, sd) * TILE
					var gy := ty * TILE + WildArt.h(ty * 5 + g, tx, sd) * TILE
					p.grass_tuft(gx, gy, Color(0.35, 0.55, 0.25).lerp(Color(0.5, 0.65, 0.3), WildArt.h(g, tx, sd)), g + tx)
			elif tv < -1.0 and tv > -1.9:
				for wr in 3:
					var wx := tx * TILE + WildArt.h(tx * 3 + wr, ty, sd + 5) * TILE
					var wy := ty * TILE + WildArt.h(ty * 3 + wr, tx, sd + 5) * TILE
					p.R(int(wx), int(wy), 3, 1, Color(0.3, 0.32, 0.18) if wr % 2 == 0 else Color(0.45, 0.36, 0.24))
			elif tv < -1.9 and WildArt.h(tx, ty, sd + 6) < 0.25:
				p.grass_tuft(tx * TILE + 8, ty * TILE + 8, Color(0.55, 0.6, 0.35), tx)
	# the ship's place: sand blown flat
	for cl in wd["clear"]:
		if String(cl[3]) == "ship":
			_meadow(p, cl[0], float(cl[1]), float(cl[2]), Color(0.82, 0.74, 0.54), sd + 2)
	# the crater: dug out, a thrown-up rim, scorched; debris round it
	var cc: Vector2 = wd["crater"]
	for yy3 in range(-58, 59):
		for xx3 in range(-92, 93):
			var e3 := Vector2(xx3 / 92.0, yy3 / 58.0).length() + (WildArt.h((xx3 + 200) / 4, (yy3 + 200) / 4, 611) - 0.5) * 0.08
			if e3 <= 1.0:
				var c5 := Color(0.3, 0.26, 0.2).lerp(Color(0.5, 0.42, 0.3), e3)
				if e3 > 0.86:
					c5 = Color(0.62, 0.52, 0.38).lerp(Color(0.7, 0.6, 0.45), WildArt.h(xx3, yy3, 612))
				if WildArt.h(xx3, yy3, 611) < 0.08:
					c5 = c5.darkened(0.4)
				p.P(int(cc.x) + xx3, int(cc.y) + yy3, c5)
	for db in 40:
		var a8 := WildArt.h(db, 1, 613) * TAU
		var d8 := 70.0 + WildArt.h(db, 2, 613) * 70.0
		p.R(int(cc.x + cos(a8) * d8), int(cc.y + sin(a8) * d8 * 0.6), 2 + db % 3, 2, Color(0.55, 0.57, 0.6).darkened(0.2 * (db % 2)))
	# tide pools with life in them
	for tp in wd["pools"]:
		var q: Vector2 = tp
		var r := 6.0 + WildArt.h(int(q.x), int(q.y), sd) * 4.0
		p.circ(q.x, q.y, r, Color(0.45, 0.42, 0.36), r * 0.6)
		p.circ(q.x, q.y, r - 1.5, Color(0.3, 0.6, 0.65), r * 0.5)
		p.R(int(q.x) - 2, int(q.y) - 1, 2, 2, Color(0.95, 0.5, 0.6))
		p.P(int(q.x) + 2, int(q.y), Color(1.0, 0.85, 0.3))
	# the sea: wet sand along the shore, the water clear for the shader
	_carve(m, wd, p, Color(0.64, 0.57, 0.42), Color(0.58, 0.52, 0.4), 0.45, sd)
	# boardwalks on posts; sand bars
	for bw in wd["boards"]:
		var seg: PackedVector2Array = bw[0]
		if seg.size() < 2:
			continue
		var bar: bool = bw[1]
		var a0 := seg[0]
		var a1 := seg[seg.size() - 1]
		var dirv := (a1 - a0).normalized()
		var nrm := dirv.orthogonal()
		var ln := int(a0.distance_to(a1))
		if bar:
			# a sand bar at low tide: wet sand, ragged, puddles and ripples on it
			for k5 in range(0, ln, 3):
				var q6 := a0 + dirv * k5
				for blob in 3:
					var off: Vector2 = nrm * (WildArt.h(k5, blob, sd) - 0.5) * 22.0
					p.circ(q6.x + off.x, q6.y + off.y, 9.0 + WildArt.h(k5, blob + 5, sd) * 6.0, Color(0.66, 0.6, 0.45).lerp(Color(0.6, 0.54, 0.41), WildArt.h(k5, blob + 9, sd)), 7.0)
			for k6 in range(0, ln, 9):
				var q7 := a0 + dirv * k6 + nrm * (WildArt.h(k6, 3, sd) - 0.5) * 16.0
				if k6 % 27 == 0:
					p.circ(q7.x, q7.y, 4.0, Color(0.38, 0.6, 0.65), 2.5)
				else:
					p.R(int(q7.x) - 3, int(q7.y), 6, 1, Color(0.56, 0.5, 0.38))
		else:
			# a boardwalk of planks across the water on posts, a rail along each side
			for k5 in range(-4, ln + 5):
				var q6 := a0 + dirv * k5
				var plank := Color(0.52, 0.38, 0.23) if (k5 / 4) % 2 == 0 else Color(0.46, 0.33, 0.2)
				for wdt in range(-10, 11):
					var b := q6 + nrm * wdt
					var c := plank
					if absi(wdt) >= 9:
						c = Color(0.36, 0.26, 0.15)
					elif k5 % 4 == 0:
						c = plank.darkened(0.25)
					p.R(int(b.x), int(b.y), 2, 2, c)
				p.R(int(q6.x + nrm.x * 11.0), int(q6.y + nrm.y * 11.0) + 1, 2, 1, Color(0, 0, 0, 0.35))
				if k5 % 14 == 0:
					for side in [-1.0, 1.0]:
						var post: Vector2 = q6 + nrm * 10.0 * side
						p.R(int(post.x) - 1, int(post.y), 3, 6, Color(0.25, 0.18, 0.12))


static func _paint_ice(m: GroundMap, wd: Dictionary, p) -> void:
	var sd: int = wd["seed"]
	var W := m.w * TILE
	var H := m.h * TILE
	var ter: PackedByteArray = wd["ter"]
	p.tile_ground(Color(0.9, 0.94, 0.98), Color(0.8, 0.86, 0.93), 701, 3)
	# patches of bare blue ice, wind-polished
	for gl in wd["glare"]:
		var gc: Vector2 = gl[0]
		var gr: float = gl[1]
		for yy7 in range(int(gc.y - gr * 0.5), int(gc.y + gr * 0.5)):
			for xx7 in range(int(gc.x - gr), int(gc.x + gr)):
				var e7 := Vector2((xx7 - gc.x) / gr, (yy7 - gc.y) / (gr * 0.5)).length() + (WildArt.h(xx7 / 3, yy7 / 3, 723) - 0.5) * 0.4
				if e7 < 1.0:
					var c8 := Color(0.62, 0.8, 0.94).lerp(Color(0.72, 0.87, 0.97), WildArt.h(xx7 / 4, yy7, 724))
					if (xx7 + yy7 * 3) % 23 == 0:
						c8 = Color(0.95, 0.98, 1.0)
					p.P(xx7, yy7, c8)
	# drifts, wind ripples; cracks; broken ice
	for d in int(W * H / 2300):
		var dx := int(WildArt.h(d, 1, 702) * W)
		var dy := int(WildArt.h(d, 2, 702) * H)
		for t in 16 + int(WildArt.h(d, 3, 702) * 20):
			p.P(dx + t, dy + int(sin(t * 0.3) * 1.5), Color(0.72, 0.8, 0.9))
			p.P(dx + t, dy + 1 + int(sin(t * 0.3) * 1.5), Color(0.97, 0.99, 1.0))
	for ck in 14:
		var a := Vector2(WildArt.h(ck, 1, 708) * W, WildArt.h(ck, 2, 708) * H)
		var b := a + Vector2(WildArt.h(ck, 3, 708) - 0.5, WildArt.h(ck, 4, 708) - 0.3).normalized() * (90.0 + WildArt.h(ck, 5, 708) * 120.0)
		p.crack(a, b, 708 + ck)
	for rb2 in int(W * H / 5000):
		var rx := int(WildArt.h(rb2, 1, 714) * W)
		var ry := int(WildArt.h(rb2, 2, 714) * H)
		p.R(rx, ry, 3 + rb2 % 3, 2, Color(0.7, 0.84, 0.96))
		p.R(rx, ry + 2, 3 + rb2 % 3, 1, Color(0.45, 0.62, 0.82))
	# the crevasses: lit lip on one side, shadowed on the other, blue walls going dark, icicles
	var chasm: PackedFloat32Array = wd["chasm"]
	for crv in wd["crevs"]:
		var pts: PackedVector2Array = crv
		for t4 in pts.size():
			var q := pts[t4]
			var dv := (pts[mini(t4 + 2, pts.size() - 1)] - pts[maxi(t4 - 2, 0)]).normalized()
			var nrm := dv.orthogonal()
			if nrm.x > 0.0:
				nrm = -nrm                                                    # the lit lip on the west
			var wdt := 11.0 + sin(t4 * 0.05) * 2.0 + WildArt.h(t4 / 6, 1, 720) * 3.0
			for xo in range(-int(wdt) - 2, int(wdt) + 3):
				var ax := absf(xo) / wdt
				var c7: Color
				if ax > 1.0:
					c7 = Color(0.97, 0.99, 1.0) if xo > 0 else Color(0.62, 0.76, 0.9)
				elif ax > 0.7:
					c7 = Color(0.45, 0.65, 0.85).lerp(Color(0.2, 0.36, 0.55), (ax - 0.7) / 0.3)
				else:
					c7 = Color(0.12, 0.22, 0.36).lerp(Color(0.02, 0.04, 0.08), 1.0 - ax / 0.7)
				var at := q + nrm * xo
				if ax <= 1.0 and ax > 0.55 and WildArt.h(int(at.x) / 2, int(at.y) / 3, 721) < 0.05:
					c7 = c7.lightened(0.25)                                       # icicles on its walls
				p.R(int(at.x), int(at.y), 2, 2, c7)                               # (2 px: no holes along the bends)
	for br in wd["bridges"]:
		var bc: Vector2 = br[0]
		var bdir: Vector2 = br[1]
		var nrm := bdir.orthogonal()
		for along in range(-30, 31):
			for across in range(-11, 12):
				var bp: Vector2 = bc + nrm * along + bdir * across
				var col := Color(0.42, 0.44, 0.48)
				if absi(across) >= 10:
					col = Color(0.95, 0.75, 0.2)
				elif along % 5 == 0:
					col = Color(0.28, 0.3, 0.33)
				p.P(int(bp.x), int(bp.y), col)
	# open water in the east: the ice's edge, the water clear for the shader, floes drifting
	_carve(m, wd, p, Color(0.42, 0.62, 0.8), Color(0.62, 0.8, 0.94), 0.5, sd)
	var sdf: PackedFloat32Array = wd["sdf"]
	var nfl := 0
	for fl in 400:
		if nfl >= 22:
			break
		var fx := WildArt.h(fl, 1, 704) * W
		var fy := WildArt.h(fl, 2, 704) * H
		if _sdf_at(m, wd, Vector2(fx, fy) / TILE) > 2.2:
			p.floe(fx, fy, 10.0 + WildArt.h(fl, 3, 704) * 16.0, 704 + fl)
			nfl += 1
	# pressure ridges: tilted slabs heaped up
	for ty in m.h:
		for tx in m.w:
			if ter[ty * m.w + tx] == RIDGE:
				p.ridge_slab(tx * TILE + 4 + WildArt.h(tx, ty, sd) * 8.0, ty * TILE + 12.0, sd + tx * 37 + ty)
				if WildArt.h(ty, tx, sd) < 0.5:
					p.ridge_slab(tx * TILE + 10.0, ty * TILE + 6.0, sd + tx * 41 + ty * 3)
	# the ice cliff in the north: its face fractured, icicles below; the cave
	var ch: PackedInt32Array = wd["cliff_h"]
	var cave_x: int = wd["cave_x"]
	for xx2 in m.w * TILE:
		var top := _cliff_top(m, ch, xx2, sd)
		for yy2 in top:
			var c2 := Color(0.62, 0.8, 0.94).lerp(Color(0.45, 0.65, 0.85), float(yy2) / top)
			if (xx2 + int(WildArt.h(yy2 / 4, 1, 705) * 6)) % 9 == 0:
				c2 = c2.lightened(0.25)
			if WildArt.h(xx2 / 2, yy2 / 3, 706) < 0.08:
				c2 = c2.darkened(0.15)
			p.P(xx2, yy2, c2)
		p.P(xx2, 0, Color(0.95, 0.98, 1.0))
		p.P(xx2, 1, Color(0.95, 0.98, 1.0))
		if xx2 % 5 == 2:
			var il := 3 + int(WildArt.h(xx2, 1, 707) * 6)
			for t3 in il:
				p.P(xx2, top + t3, Color(0.85, 0.95, 1.0).lerp(Color(0.6, 0.8, 0.95), float(t3) / il))
	# the cave: an arched mouth in the face, dark and blue inside, icicles hanging over it
	var cfx := (cave_x + 0.5) * TILE
	var cfy := float(ch[cave_x] * TILE)
	for yy3 in range(0, int(cfy) + 6):
		for xx3 in range(int(cfx - 4.2 * TILE), int(cfx + 4.2 * TILE)):
			var e := Vector2((xx3 - cfx) / (3.9 * TILE), (yy3 - cfy) / (cfy - 14.0)).length() + (WildArt.h(xx3 / 3, yy3 / 3, sd + 8) - 0.5) * 0.08
			if e < 1.0:
				p.P(xx3, yy3, Color(0.04, 0.07, 0.13).lerp(Color(0.2, 0.32, 0.48), clampf(e * e, 0.0, 1.0)))
			elif e < 1.07:
				p.P(xx3, yy3, Color(0.85, 0.94, 1.0))
	for ic2 in range(int(cfx - 3.6 * TILE), int(cfx + 3.6 * TILE), 4):
		var dy := sqrt(maxf(0.0, 1.0 - pow((ic2 - cfx) / (3.9 * TILE), 2.0))) * (cfy - 14.0)
		var il2 := 4 + int(WildArt.h(ic2, 2, 707) * 7)
		for t5 in il2:
			p.P(ic2, int(cfy - dy) + t5, Color(0.85, 0.95, 1.0).lerp(Color(0.55, 0.78, 0.95), float(t5) / il2))


# ================================================================== the minimap

static func mm_col(m: GroundMap, x: int, y: int) -> Color:
	match ter_at(m, x, y):
		WATER:
			return Color(0.15, 0.35, 0.55, 0.95)
		FORD:
			return Color(0.35, 0.55, 0.6, 0.95)
		CLIFF, RIDGE:
			return Color(0.4, 0.4, 0.42, 0.95)
		THICKET:
			return Color(0.12, 0.25, 0.1, 0.95)
		CHASM:
			return Color(0.05, 0.08, 0.15, 0.95)
		BOARD, BRIDGE:
			return Color(0.6, 0.45, 0.25, 0.95)
		CAVE:
			return Color(0.25, 0.35, 0.5, 0.95)
	var b := String(m.get_meta("wild")["biome"]) if m.has_meta("wild") else ""
	return {"jungle": Color(0.22, 0.4, 0.16, 0.9), "coast": Color(0.82, 0.74, 0.55, 0.9), "ice": Color(0.85, 0.9, 0.96, 0.9)}.get(b, Color(0.5, 0.5, 0.5, 0.9))
