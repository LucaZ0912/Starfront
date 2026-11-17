extends RefCounted
## Package 54a (Luz): the sights on the ground – a place on a world worth flying to and worth coming back to, built in
## great detail on the ground of its world: the landing place, the way there, a viewing terrace (glass railing, benches
## to sit on, an information holo, viewing scopes, a souvenir stall), other sightseers about; and what there is to see
## changes – by the hour and from visit to visit (an event: a rainbow in the spray, fireflies at night, …). At the
## railing you take photos (a collection; the rare events make rare photos). No class_name: preload it.

const T := GroundMap.T
const TILE := GroundMap.TILE
const WildGen = preload("res://scripts/ground/wild_gen.gd")
const WildArt = preload("res://scripts/ground/wild_art.gd")

const SightData = preload("res://data/sights.gd")
const THEME_OF := SightData.THEME_OF
const SIGHTS := SightData.SIGHTS
const PHOTO_PAY := 150                 # a travel magazine buys a new photo
const PHOTO_PAY_RARE := 600


static func theme_for(body: Dictionary) -> String:
	return String(THEME_OF.get(String(body.get("type", "")), ""))


## The event this visit (by the visit's number and the hour): its id.
static func event_for(theme: String, sid: String, visit: int, day: float) -> String:
	var ev: Dictionary = SIGHTS.get(theme, {}).get("events", {})
	var when := "night" if day < 0.25 else ("dusk" if day < 0.55 else "day")
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s_%d" % [sid, visit])
	var tot := 0.0
	var cands: Array = []
	for k in ev:
		var e: Array = ev[k]
		var w := String(e[1])
		if w == "any" or w == when or (w == "dawn" and when == "dusk"):
			cands.append([k, float(e[2])])
			tot += float(e[2])
	if cands.is_empty():
		return ""
	var r := rng.randf() * tot
	for c in cands:
		r -= float(c[1])
		if r <= 0.0:
			return String(c[0])
	return String(cands[0][0])


static func build(body: Dictionary, site: Dictionary, lsz: Vector2, event: String) -> GroundMap:
	var theme := String(site.get("theme", "falls"))
	match theme:
		"lagoon":
			return _lagoon(body, site, lsz, event)
		"icecave":
			return _icecave(body, site, lsz, event)
		"arches", "lava", "crater", "mirror":
			return _vista(body, site, lsz, event, theme)
		_:
			return _falls(body, site, lsz, event)


# ---------------------------------------------------------------- the waterfall (jungle)

## The jungle's ground (the wild's terrain and painter), composed for the view: a high rock wall across the north, the
## falls pouring off it seven metres wide into a great pool right under the terrace, the creek running off to the east;
## giant trees round the clearing; the landing place in the south-west, a path to the terrace.
static func _falls(body: Dictionary, site: Dictionary, lsz: Vector2, event: String) -> GroundMap:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(site.get("seed", 7)) + 54
	var th: Dictionary = WildGen.PoiData.THEMES["wild_jungle"]
	var m := GroundMap.new()
	m.pal = DeckGen.palette_for_body(body).duplicate()
	for key in ["floor", "floor2", "wall", "wall_top", "trim", "accent"]:
		m.pal[key] = th[key]
	m.pal["frame"] = (th["wall"] as Color).darkened(0.25)
	m.style = "wild"
	m.hull_top = -60
	var W := 66
	var H := 50
	m.setup(W, H)
	m.fill(0, 0, W, H, T.FLOOR, WildGen.FK)
	var ter := PackedByteArray()
	ter.resize(W * H)
	var sdf := PackedFloat32Array()
	sdf.resize(W * H)
	sdf.fill(-99.0)
	var pathm := PackedByteArray()
	pathm.resize(W * H)
	var sd := rng.randi() % 100000
	var wd := {"biome": "jungle", "seed": sd, "ter": ter, "sdf": sdf, "paths": [], "clear": [], "fords": [], "keep": [], "pathm": pathm,
		"shrine": Vector2(-900, -900)}
	# the rock wall: high across the north, a little higher over the falls
	var fx := W / 2 - 4
	var ch := PackedInt32Array()
	ch.resize(W)
	for x in W:
		ch[x] = 9 + int(WildGen.h(x / 5, 1, sd) * 2.5) + (1 if absi(x - fx - 3) < 6 else 0)
		for y in ch[x]:
			ter[y * W + x] = WildGen.CLIFF
	wd["cliff_h"] = ch
	wd["fall_x"] = fx + 2
	# thicket round the other sides
	for y2 in H:
		for x2 in W:
			var dw := 2 + int(WildGen.h(y2 / 4, 2, sd) * 2.0)
			var ds := 2 + int(WildGen.h(x2 / 4, 4, sd) * 2.0)
			if (x2 < dw or x2 >= W - dw or y2 >= H - ds) and ter[y2 * W + x2] == WildGen.OPEN:
				ter[y2 * W + x2] = WildGen.THICKET
	# the pool under the falls, the creek off to the east
	var pool := Vector2(fx + 3.5, ch[fx + 3] + 3.6) * TILE
	wd["pool"] = pool
	for yy in range(ch[fx + 3] - 1, ch[fx + 3] + 12):
		for xx in range(fx - 8, fx + 16):
			if xx < 0 or xx >= W or yy < 0 or yy >= H:
				continue
			var rel := (Vector2(xx + 0.5, yy + 0.5) * TILE - pool) / Vector2(1.0, 0.6)
			var v := (5.6 * TILE - rel.length() + (WildGen.h(xx, yy, sd) - 0.5) * 8.0) / TILE
			if v > sdf[yy * W + xx]:
				sdf[yy * W + xx] = v
	var creek := PackedVector2Array()
	var q := pool + Vector2(4.5 * TILE, 1.5 * TILE)
	var t := 0
	while q.x < W * TILE + 20.0 and t < 2000:
		creek.append(q)
		q += Vector2(1.0, 0.32).normalized().rotated(sin(t * 0.05 + sd) * 0.6) * 6.0
		t += 1
	wd["creek"] = creek
	WildGen._stamp(m, sdf, creek, 18.0)
	for i in W * H:
		if sdf[i] > 0.0 and ter[i] != WildGen.CLIFF:
			ter[i] = WildGen.WATER
	# the terrace right on the pool's south shore; the landing place in the south-west
	var x0 := fx - 7
	var x1 := fx + 13
	var y0 := int(pool.y / TILE) + 3
	var y1 := y0 + 8
	(wd["keep"] as Array).append(Rect2(x0 - 1, y0 - 1, x1 - x0 + 3, y1 - y0 + 3))
	(wd["clear"] as Array).append([Vector2((x0 + x1) * 0.5, y1 + 3.0) * TILE, 9.0 * TILE, 4.0 * TILE, "meadow"])
	var sl := clampi(int(ceil(lsz.x / TILE)) + 4, 10, 40)
	var sb := clampi(int(ceil(lsz.y / TILE)) + 4, 7, 20)
	WildGen._ship_spot(m, wd, 4, H - sb - 4, sl, sb)
	for yy2 in range(y0, y1 + 1):
		for xx2 in range(x0, x1 + 1):
			if ter[yy2 * W + xx2] == WildGen.WATER:
				ter[yy2 * W + xx2] = WildGen.OPEN
				sdf[yy2 * W + xx2] = -1.0
	WildGen._apply(m, wd)
	WildGen._ship(m, wd, sl, sb, lsz.x, lsz.y)
	WildGen._add_path(m, wd, WildGen._route(m.spawn, Vector2((x0 + x1) * 0.5, y1 + 1.2) * TILE, rng, 14.0))
	# giant trees round it all, rocks by the pool
	var trees: Array = []
	for tries in 700:
		var tx := rng.randi_range(4, W - 5)
		var ty := rng.randi_range(ch[tx] + 3, H - 4)
		if not WildGen._free(m, wd, tx, ty) or WildGen._sdf_at(m, wd, Vector2(tx + 0.5, ty + 0.5)) > -1.8 or WildGen._in_clearing(wd, Vector2(tx + 0.5, ty + 0.5) * TILE, 1.1):
			continue
		var near := false
		for o in trees:
			if (o as Vector2).distance_to(Vector2(tx, ty)) < 4.4:
				near = true
				break
		if near:
			continue
		trees.append(Vector2(tx, ty))
		WildGen._block_obj(m, {"kind": "wild_tree", "x": tx - 2, "y": ty - 1, "w": 5, "h": 2, "rise": 78, "seed": rng.randi() % 7}, [Vector2(tx, ty)])
	for rk in 9:
		var a := rng.randf() * TAU
		var rp := pool + Vector2(cos(a) * 6.4, sin(a) * 4.6) * TILE
		var rx := int(rp.x / TILE)
		var ry := int(rp.y / TILE)
		if WildGen._free(m, wd, rx, ry) and WildGen._free(m, wd, rx + 1, ry):
			WildGen._block_obj(m, {"kind": "wild_rock", "x": rx, "y": ry, "w": 2, "h": 1, "rise": 6, "seed": rng.randi() % 9, "col": Color(0.46, 0.44, 0.38)}, [Vector2(rx, ry), Vector2(rx + 1, ry)])
	m.set_meta("wild", wd)
	m.set_meta("tint", WildGen.TINT["jungle"])
	m.set_meta("water", WildGen.WATER_LOOK.get("jungle", {}))
	_terrace(m, site, x0, y0, x1, y1, Color(0.74, 0.7, 0.62), rng)
	m.set_meta("sight", {"theme": "falls", "event": event, "focus": Vector2(fx + 3.5, ch[fx + 3]) * TILE, "pool": pool,
		"fall": Rect2(Vector2(fx, 0) * TILE, Vector2(7, ch[fx + 3]) * TILE), "name": String(site.get("name", "")), "id": String(site.get("id", ""))})
	m.title = String(site.get("name", "The falls"))
	return m


# ---------------------------------------------------------------- the coral lagoon (ocean)

## The coast's ground and painter, composed for the view: a beach in the south (palms, dune grass, the landing place),
## the lagoon shallow and turquoise before it, closed by a ring of reef islets, the deep sea beyond them; a jetty of
## planks out over the lagoon to a viewing platform; the terrace on the beach.
static func _lagoon(body: Dictionary, site: Dictionary, lsz: Vector2, event: String) -> GroundMap:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(site.get("seed", 7)) + 55
	var th: Dictionary = WildGen.PoiData.THEMES["wild_coast"]
	var m := GroundMap.new()
	m.pal = DeckGen.palette_for_body(body).duplicate()
	for key in ["floor", "floor2", "wall", "wall_top", "trim", "accent"]:
		m.pal[key] = th[key]
	m.pal["frame"] = (th["wall"] as Color).darkened(0.25)
	m.style = "wild"
	m.hull_top = -60
	var W := 70
	var H := 54
	m.setup(W, H)
	m.fill(0, 0, W, H, T.FLOOR, WildGen.FK)
	var ter := PackedByteArray()
	ter.resize(W * H)
	var sdf := PackedFloat32Array()
	sdf.resize(W * H)
	var pathm := PackedByteArray()
	pathm.resize(W * H)
	var sd := rng.randi() % 100000
	var wd := {"biome": "coast", "seed": sd, "ter": ter, "sdf": sdf, "paths": [], "clear": [], "fords": [], "keep": [], "pathm": pathm,
		"crater": Vector2(-900, -900), "pools": [], "boards": []}
	var shore := H * 0.6
	var rc := Vector2(W * 0.5, shore + 2.0)
	var rr := Vector2(W * 0.47, shore * 0.86)
	# the reef islets along an arc round the lagoon
	var islets: Array = []
	var a := PI * 1.08
	while a < PI * 1.92:
		var c := rc + Vector2(cos(a) * rr.x, sin(a) * rr.y)
		islets.append([c, Vector2(rng.randf_range(2.2, 4.0), rng.randf_range(1.1, 1.9))])
		a += rng.randf_range(0.11, 0.2)
	wd["islands"] = islets
	for y in H:
		for x in W:
			var d := shore + sin(x * 0.17 + sd) * 1.2 - (y + 0.5)          # the beach: water north of it
			for il in islets:
				var c2: Vector2 = il[0]
				var r2: Vector2 = il[1]
				d = minf(d, (Vector2((x + 0.5 - c2.x) / r2.x, (y + 0.5 - c2.y) / r2.y).length() - 1.0) * minf(r2.x, r2.y))
			d += (WildGen.h(x / 3, y / 3, sd) - 0.5) * 1.2
			var inside := (Vector2(x + 0.5, y + 0.5) - rc) / rr
			if d > 0.0 and inside.length() < 0.97:
				d = minf(d * 0.35, 3.2) + 0.3                              # the lagoon: shallow, turquoise
			if y >= shore + 2.0:
				d = minf(d, -1.0)                                          # the land runs on to the edges in the south
			sdf[y * W + x] = d
			if d > 0.0:
				ter[y * W + x] = WildGen.WATER
	# the terrace on the beach, the jetty out over the lagoon to the platform
	var cx := W / 2
	var y_t0 := int(shore) + 2
	var y_t1 := y_t0 + 7
	var x0 := cx - 10
	var x1 := cx + 10
	var py0 := int(shore) - 15
	var px0 := cx - 5
	var px1 := cx + 5
	(wd["keep"] as Array).append(Rect2(x0 - 1, y_t0 - 1, x1 - x0 + 3, y_t1 - y_t0 + 3))
	var jetty := PackedVector2Array()
	for yy in range(py0 + 3, y_t0 + 1):
		jetty.append(Vector2(cx + 0.5, yy + 0.5) * TILE)
		for xx in [cx - 1, cx, cx + 1]:
			if ter[yy * W + xx] == WildGen.WATER:
				ter[yy * W + xx] = WildGen.BOARD
	(wd["boards"] as Array).append([jetty, false])
	for yy2 in range(py0, py0 + 4):
		for xx2 in range(px0, px1 + 1):
			ter[yy2 * W + xx2] = WildGen.BOARD
	var sl := clampi(int(ceil(lsz.x / TILE)) + 4, 10, 40)
	var sb := clampi(int(ceil(lsz.y / TILE)) + 4, 7, 20)
	WildGen._ship_spot(m, wd, 4, H - sb - 3, sl, sb)
	for yy3 in range(y_t0, y_t1 + 1):
		for xx3 in range(x0, x1 + 1):
			ter[yy3 * W + xx3] = WildGen.OPEN
	WildGen._apply(m, wd)
	WildGen._ship(m, wd, sl, sb, lsz.x, lsz.y)
	WildGen._add_path(m, wd, WildGen._route(m.spawn, Vector2(cx - 4.0, y_t1 + 1.2) * TILE, rng, 12.0))
	# palms along the beach, rocks with seaweed at the waterline, driftwood
	for tries in 500:
		var tx := rng.randi_range(3, W - 4)
		var ty := rng.randi_range(int(shore) + 1, H - 3)
		if not WildGen._free(m, wd, tx, ty) or not WildGen._free(m, wd, tx + 1, ty) or WildGen._in_clearing(wd, Vector2(tx + 0.5, ty + 0.5) * TILE, 1.0):
			continue
		var dd := sdf[ty * W + tx]
		var r3 := rng.randf()
		if dd < -2.0 and r3 < 0.16:
			WildGen._block_obj(m, {"kind": "palm", "x": tx - 1, "y": ty, "w": 3, "h": 1, "rise": 50, "seed": rng.randi() % 8}, [Vector2(tx, ty)])
		elif dd > -1.8 and dd < -0.5 and r3 < 0.06:
			WildGen._block_obj(m, {"kind": "wild_rock", "x": tx, "y": ty, "w": 2, "h": 1, "rise": 6, "seed": rng.randi() % 9, "col": Color(0.42, 0.42, 0.44), "weed": true}, [Vector2(tx, ty), Vector2(tx + 1, ty)])
		elif dd > -3.0 and dd < -1.0 and r3 < 0.03 and WildGen._free(m, wd, tx + 2, ty):
			WildGen._block_obj(m, {"kind": "driftwood", "x": tx, "y": ty, "w": 3, "h": 1, "rise": 0, "seed": rng.randi() % 6}, [Vector2(tx, ty), Vector2(tx + 1, ty), Vector2(tx + 2, ty)])
	# palms on the reef islets
	for il2 in islets:
		var ic: Vector2 = il2[0]
		if rng.randf() < 0.55:
			m.add_object({"kind": "palm", "x": int(ic.x) - 1, "y": int(ic.y), "w": 3, "h": 1, "rise": 50, "seed": rng.randi() % 8}, false)
	m.set_meta("wild", wd)
	m.set_meta("tint", WildGen.TINT["coast"])
	var wl: Dictionary = (WildGen.WATER_LOOK.get("coast", {}) as Dictionary).duplicate()
	wl["shallow"] = Color(0.42, 0.88, 0.82)
	wl["mid"] = Color(0.12, 0.58, 0.7)
	wl["waves"] = 0.35                                           # calm inside the reef
	m.set_meta("water", wl)
	_terrace(m, site, x0, y_t0, x1, y_t1, Color(0.82, 0.76, 0.62), rng)
	# the jetty's end: a platform of planks with a railing round it – there you look out over the reef
	m.decals.append({"kind": "plank_deck", "x": px0, "y": py0, "w": px1 - px0 + 1, "h": 4, "col": Color(0.52, 0.38, 0.23)})
	m.fill(px0, py0, px1 - px0 + 1, 1, T.BLOCK)
	m.add_object({"kind": "glass_rail", "x": px0, "y": py0, "w": px1 - px0 + 1, "h": 1}, false)
	m.add_object({"kind": "scope", "x": px0 + 1, "y": py0 + 1, "w": 1, "h": 1, "col": Color(0.45, 0.9, 1.0)})
	m.add_object({"kind": "scope", "x": px1 - 1, "y": py0 + 1, "w": 1, "h": 1, "col": Color(0.45, 0.9, 1.0)})
	# the viewpoint is out there now, not at the terrace's railing
	for z in m.zones:
		if String(z.get("kind", "")) == "viewpoint":
			z["rect"] = Rect2(Vector2(px0 + 0.5, py0 + 0.8) * TILE, Vector2(px1 - px0, 2.6) * TILE)
	# the terrace's railing has a gap where the jetty starts
	m.objects = m.objects.filter(func(o): return not (String(o["kind"]) == "glass_rail" and int(o["y"]) == y_t0))
	m.add_object({"kind": "glass_rail", "x": x0, "y": y_t0, "w": cx - 2 - x0, "h": 1}, false)
	m.add_object({"kind": "glass_rail", "x": cx + 2, "y": y_t0, "w": x1 - cx - 1, "h": 1}, false)
	for gx in range(cx - 1, cx + 2):
		m.set_t(gx, y_t0, T.FLOOR)
	# corals under the lagoon, for the light to play on
	var corals: Array = []
	for k in 70:
		var q := Vector2(rng.randf_range(6.0, W - 6.0), rng.randf_range(4.0, shore - 1.0))
		var ins := (q - rc) / rr
		if ins.length() < 0.93 and sdf[int(q.y) * W + int(q.x)] > 0.5:
			corals.append([q * TILE, rng.randf_range(4.0, 10.0), rng.randi() % 5])
	m.set_meta("sight", {"theme": "lagoon", "event": event, "focus": Vector2(cx, shore * 0.35) * TILE, "pool": Vector2(cx, shore * 0.55) * TILE,
		"corals": corals, "reef": [rc * TILE, rr * TILE], "name": String(site.get("name", "")), "id": String(site.get("id", ""))})
	m.title = String(site.get("name", "The lagoon"))
	return m


# ---------------------------------------------------------------- the ice cathedral (ice worlds)

## The ice's ground and painter, composed for the view: a glacier wall across the north, fifteen metres high, banded
## with the years' layers; in it the cathedral's portal, an arch nineteen metres wide, and through it the nave – a hall
## of blue ice going back into the dark, pillars where the ice ran down and froze, a frozen waterfall glowing at its
## end; a frozen lake before the portal, clear as glass; seracs and pressure ridges round it, a crevasse in the east
## with a bridge over it; the landing place in the south-west.
static func _icecave(body: Dictionary, site: Dictionary, lsz: Vector2, event: String) -> GroundMap:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(site.get("seed", 7)) + 56
	var th: Dictionary = WildGen.PoiData.THEMES.get("wild_ice", WildGen.PoiData.THEMES["wild_jungle"])
	var m := GroundMap.new()
	m.pal = DeckGen.palette_for_body(body).duplicate()
	for key in ["floor", "floor2", "wall", "wall_top", "trim", "accent"]:
		m.pal[key] = th[key]
	m.pal["frame"] = (th["wall"] as Color).darkened(0.25)
	m.style = "wild"
	m.hull_top = -60
	var W := 66
	var H := 52
	m.setup(W, H)
	m.fill(0, 0, W, H, T.FLOOR, WildGen.FK)
	var ter := PackedByteArray()
	ter.resize(W * H)
	var sdf := PackedFloat32Array()
	sdf.resize(W * H)
	sdf.fill(-99.0)
	var pathm := PackedByteArray()
	pathm.resize(W * H)
	var sd := rng.randi() % 100000
	var cx := W / 2
	var wd := {"biome": "ice", "seed": sd, "ter": ter, "sdf": sdf, "paths": [], "clear": [], "fords": [], "keep": [], "pathm": pathm,
		"cave_x": cx, "crevs": [], "bridges": [], "glare": []}
	# the glacier wall: high across the north, highest over the portal
	var ch := PackedInt32Array()
	ch.resize(W)
	for x in W:
		ch[x] = 13 + int(WildGen.h(x / 5, 1, sd) * 2.5) + (2 if absi(x - cx) < 12 else 0)
		for y in ch[x]:
			ter[y * W + x] = WildGen.CLIFF
	wd["cliff_h"] = ch
	var base := ch[cx]
	var hw := 9.5
	# the portal's threshold: you can step in under the arch
	for yy in range(base - 2, base):
		for xx in range(cx - 6, cx + 7):
			ter[yy * W + xx] = WildGen.CAVE
	# pressure ridges round the field, west, east and south
	for y2 in H:
		for x2 in W:
			var dw := 2 + int(WildGen.h(y2 / 3, 2, sd) * 2.5)
			var de := 2 + int(WildGen.h(y2 / 3, 5, sd) * 2.5)
			var ds := 2 + int(WildGen.h(x2 / 3, 3, sd) * 2.5)
			if (x2 < dw or x2 >= W - de or y2 >= H - ds) and ter[y2 * W + x2] == WildGen.OPEN:
				ter[y2 * W + x2] = WildGen.RIDGE
	# the crevasse in the east, from the glacier's foot down to the ridges, a bridge over it
	var chasm := PackedFloat32Array()
	chasm.resize(W * H)
	chasm.fill(-99.0)
	var ca := Vector2(W - 13.0, ch[W - 13] + 1.0) * TILE
	var cb := Vector2(W - 9.0, H - 4.0) * TILE
	var pts := PackedVector2Array()
	var n := int(ca.distance_to(cb))
	for s in n:
		var t := float(s) / n
		pts.append(ca.lerp(cb, t) + (cb - ca).normalized().orthogonal() * sin(t * 7.0 + sd) * 16.0)
	(wd["crevs"] as Array).append(pts)
	WildGen._stamp(m, chasm, pts, 15.0)
	for i in W * H:
		if chasm[i] > 0.0 and ter[i] == WildGen.OPEN:
			ter[i] = WildGen.CHASM
	wd["chasm"] = chasm
	var bi := int(pts.size() * 0.5)
	var bc := pts[bi]
	var bdir := (pts[mini(bi + 3, pts.size() - 1)] - pts[maxi(bi - 3, 0)]).normalized()
	(wd["bridges"] as Array).append([bc, bdir])
	for yy5 in range(int(bc.y / TILE) - 3, int(bc.y / TILE) + 4):
		for xx5 in range(int(bc.x / TILE) - 3, int(bc.x / TILE) + 4):
			var rel := Vector2(xx5 + 0.5, yy5 + 0.5) * TILE - bc
			if absf(rel.dot(bdir)) < 1.2 * TILE and rel.length() < 2.6 * TILE and ter[yy5 * W + xx5] == WildGen.CHASM:
				ter[yy5 * W + xx5] = WildGen.BRIDGE
	# the frozen lake before the portal; the terrace south of it
	var lake := Vector2(cx + 0.5, base + 3.6) * TILE
	var lrx := 11.0 * TILE
	var lry := 2.7 * TILE
	wd["lake"] = [lake, lrx, lry]
	wd["portal"] = [Vector2(cx + 0.5, 0.0) * TILE, 5.0 * TILE, float(base) * TILE, hw * TILE]
	var x0 := cx - 10
	var x1 := cx + 10
	var y0 := base + 7
	var y1 := y0 + 7
	(wd["keep"] as Array).append(Rect2(x0 - 1, y0 - 1, x1 - x0 + 3, y1 - y0 + 3))
	(wd["keep"] as Array).append(Rect2(cx - 13, base - 2, 27, 10))
	var sl := clampi(int(ceil(lsz.x / TILE)) + 4, 10, 40)
	var sb := clampi(int(ceil(lsz.y / TILE)) + 4, 7, 20)
	WildGen._ship_spot(m, wd, 4, H - sb - 4, sl, sb)
	for yy3 in range(y0, y1 + 1):
		for xx3 in range(x0, x1 + 1):
			ter[yy3 * W + xx3] = WildGen.OPEN
	WildGen._apply(m, wd)
	WildGen._ship(m, wd, sl, sb, lsz.x, lsz.y)
	WildGen._add_path(m, wd, WildGen._route(m.spawn, Vector2(cx - 3.0, y1 + 1.2) * TILE, rng, 12.0))
	# seracs: blocks and towers of ice broken off the glacier, crystals of rime
	var blocks := 0
	for tries in 600:
		if blocks >= 22:
			break
		var bx := rng.randi_range(3, W - 5)
		var by := rng.randi_range(ch[bx] + 1, H - 5)
		if not WildGen._free(m, wd, bx, by) or not WildGen._free(m, wd, bx + 1, by) or chasm[by * W + bx] > -1.5 or WildGen._in_clearing(wd, Vector2(bx + 0.5, by + 0.5) * TILE, 1.0):
			continue
		if rng.randf() < 0.7:
			WildGen._block_obj(m, {"kind": "ice_block", "x": bx, "y": by, "w": 2, "h": 1, "rise": 14 + rng.randi() % 14, "seed": rng.randi() % 9}, [Vector2(bx, by), Vector2(bx + 1, by)])
		else:
			var cc := Color(0.55, 0.88, 1.0) if rng.randf() < 0.7 else Color(0.7, 0.6, 1.0)
			WildGen._block_obj(m, {"kind": "crystal", "x": bx, "y": by, "w": 2, "h": 1, "col": cc, "seed": rng.randi()}, [Vector2(bx, by), Vector2(bx + 1, by)])
			m.lights.append({"pos": Vector2(bx + 1.0, by + 0.3) * TILE, "r": 30.0, "col": cc, "a": 0.35, "flicker": true})
		blocks += 1
	# crystals on the portal's threshold, glowing
	for k in [-7, 6]:
		var kx: int = cx + k
		var kc := Color(0.5, 0.9, 1.0) if k > 0 else Color(0.72, 0.62, 1.0)
		m.add_object({"kind": "crystal", "x": kx, "y": base - 2, "w": 2, "h": 1, "rise": 30, "col": kc, "seed": rng.randi()}, false)
		m.set_t(kx, base - 2, T.BLOCK, WildGen.FK)
		m.set_t(kx + 1, base - 2, T.BLOCK, WildGen.FK)
		m.lights.append({"pos": Vector2(kx + 1.0, base - 1.5) * TILE, "r": 44.0, "col": kc, "a": 0.4, "flicker": true})
	m.lights.append({"pos": Vector2(cx + 0.5, base - 1.0) * TILE, "r": 110.0, "col": Color(0.4, 0.75, 1.0), "a": 0.35})
	for gl in 8:
		var gp := Vector2(rng.randf_range(6, W - 8), rng.randf_range(base + 12, H - 6)) * TILE
		if not WildGen._in_clearing(wd, gp, 1.0):
			(wd["glare"] as Array).append([gp, rng.randf_range(16.0, 34.0)])
	m.set_meta("wild", wd)
	m.set_meta("tint", WildGen.TINT["ice"])
	m.set_meta("water", WildGen.WATER_LOOK.get("ice", {}))
	m.set_meta("sight_paint", "icecave")
	_terrace(m, site, x0, y0, x1, y1, Color(0.66, 0.7, 0.76), rng)
	var vp := Vector2(cx + 0.5, base - (base - 5.0) * 0.3) * TILE
	m.set_meta("sight", {"theme": "icecave", "event": event, "focus": Vector2(cx + 0.5, 8.0) * TILE, "pool": lake, "vp": vp,
		"portal": wd["portal"], "lake": wd["lake"], "glacier": float(base) * TILE, "name": String(site.get("name", "")), "id": String(site.get("id", ""))})
	m.title = String(site.get("name", "The Ice Cathedral"))
	return m


## Painted after the ice's own painter: the glacier's banded face, the portal and the nave behind it, the frozen lake.
static func paint_extra(m: GroundMap, wd: Dictionary, p) -> void:
	match String(m.get_meta("sight_paint", "")):
		"icecave":
			_paint_icecave(m, wd, p)
		"vista":
			_paint_vista(m, wd, p)


static func _paint_icecave(m: GroundMap, wd: Dictionary, p) -> void:
	var sd: int = wd["seed"]
	var ch: PackedInt32Array = wd["cliff_h"]
	var W := m.w * TILE
	# the glacier's face: the years' layers in bands, dust in some, seracs' cracks running down
	for xx in W:
		var top := WildGen._cliff_top(m, ch, xx, sd)
		for yy in range(3, top):
			var band := yy + int(sin(xx * 0.021 + sd) * 5.0 + sin(xx * 0.07) * 1.5)
			var c: Color = p.img.get_pixel(xx, yy)
			if band % 13 == 0:
				c = c.darkened(0.16)
			elif band % 13 == 1:
				c = c.lightened(0.1)
			if band % 47 == 3 or band % 47 == 4:
				c = c.lerp(Color(0.5, 0.52, 0.56), 0.45)                       # a layer of old dust
			if WildArt.h(xx / 9, 1, sd + 31) < 0.12 and WildArt.h(xx, yy / 6, sd + 32) < 0.5 and yy > top * 0.3:
				c = c.darkened(0.22)                                            # a crack down the face
			p.P(xx, yy, c)
		for k in 3:
			p.P(xx, top - 1 - k, Color(0.3, 0.45, 0.65, 0.35 - k * 0.1))     # its shadow foot
	# the portal and the nave behind it
	var pr: Array = wd["portal"]
	var pc: Vector2 = pr[0]
	var top_y: float = pr[1]
	var base: float = pr[2]
	var hw: float = pr[3]
	var hh := base - top_y
	var vp := Vector2(pc.x, base - hh * 0.3)
	for yy2 in range(0, int(base) + 2):
		for xx2 in range(int(pc.x - hw * 1.2), int(pc.x + hw * 1.2) + 1):
			var dx := (xx2 + 0.5 - pc.x) / hw
			var dy := (yy2 + 0.5 - base) / hh
			var e := sqrt(dx * dx + dy * dy) + (WildArt.h(xx2 / 3, yy2 / 3, sd + 40) - 0.5) * 0.03
			if e >= 1.0 and e < 1.13:                                           # the arch's rim of clear ice
				var k2 := (e - 1.0) / 0.13
				var rc := Color(0.92, 0.98, 1.0).lerp(Color(0.5, 0.72, 0.92), k2)
				if (xx2 + yy2) % 7 == 0:
					rc = rc.lightened(0.2)
				p.P(xx2, yy2, rc)
				continue
			if e >= 1.0:
				continue
			var c2: Color
			var rv := Vector2((xx2 - vp.x) / hw, (yy2 - vp.y) / hh)
			var dk := clampf(rv.length() * 1.5, 0.0, 1.0)                      # the depth: dark in the middle, light at the walls
			var fz := (yy2 - vp.y) / (base - vp.y)
			var fhw := hw * (0.16 + 0.7 * fz)                                   # the floor's half width at this depth
			if yy2 > vp.y and absf(xx2 + 0.5 - vp.x) < fhw:
				# the nave's floor of polished ice in perspective, the light running along it
				var u := (xx2 - vp.x) / maxf(1.0, (yy2 - vp.y))
				c2 = Color(0.04, 0.1, 0.2).lerp(Color(0.46, 0.7, 0.9), pow(clampf(fz, 0.0, 1.0), 1.4))
				if absf(fposmod(u * 3.0, 1.0) - 0.5) < 0.04:
					c2 = c2.lightened(0.12)
				if absf(u) < 0.22:
					c2 = c2.lerp(Color(0.6, 0.9, 1.0), 0.35 * (1.0 - absf(u) / 0.22) * (1.0 - fz * 0.6))   # the waterfall mirrored
				if absf(xx2 + 0.5 - vp.x) > fhw - 1.5:
					c2 = c2.lightened(0.3)                                      # where floor meets wall
			else:
				# the vault: scalloped ice, blue where the light comes through, dark into the depth
				c2 = Color(0.03, 0.07, 0.16).lerp(Color(0.3, 0.6, 0.88), pow(dk, 1.2))
				var sc := sin(xx2 * 0.33 + sin(yy2 * 0.21) * 2.0) * sin(yy2 * 0.41 + sin(xx2 * 0.13) * 1.6)
				if sc > 0.72:
					c2 = c2.lightened(0.14 * dk + 0.04)
				elif sc < -0.8:
					c2 = c2.darkened(0.15)
			p.P(xx2, yy2, c2)
	# where the portal opens onto the field: the old cave's dark gone, the nave's blue light spilling onto the snow
	for yy7 in range(int(base), int(base) + 10):
		for xx7 in range(int(pc.x - hw * 1.1), int(pc.x + hw * 1.1)):
			var sn := Color(0.9, 0.94, 0.98).lerp(Color(0.8, 0.86, 0.93), WildArt.h(xx7 / 2, yy7 / 2, 701))
			var k7 := clampf(1.0 - (yy7 - base) / 10.0, 0.0, 1.0) * clampf(1.0 - absf(xx7 - pc.x) / hw, 0.0, 1.0)
			var o7: Color = p.img.get_pixel(xx7, yy7)
			if o7.r < 0.5 or k7 > 0.0:
				p.P(xx7, yy7, (sn if o7.r < 0.5 else o7).lerp(Color(0.55, 0.8, 0.97), k7 * 0.7))
	# the frozen waterfall at the nave's end: it flares out where it froze on the floor, streaks of white in its blue
	var fw := hw * 0.3
	var ft := vp.y - hh * 0.32
	var fb := vp.y + 3.0
	for yy3 in range(int(ft), int(fb)):
		var f3 := (yy3 - ft) / (fb - ft)
		var half := fw * 0.5 * (0.75 + 0.55 * f3 * f3)
		for xx3 in range(int(vp.x - half), int(vp.x + half) + 1):
			var k3 := absf(xx3 + 0.5 - vp.x) / half
			var c3 := Color(0.5, 0.84, 1.0).lerp(Color(0.86, 0.98, 1.0), WildArt.h(xx3, 7, sd + 50))
			if WildArt.h(xx3, 8, sd + 51) > 0.72:
				c3 = Color(0.95, 1.0, 1.0)                                      # a streak of white ice
			if WildArt.h(xx3, yy3 / 3, sd + 52) < 0.08:
				c3 = c3.darkened(0.2)
			c3 = c3.lerp(Color(0.2, 0.45, 0.7), k3 * k3 * 0.6)
			p.P(xx3, yy3, c3)
	for xx8 in range(int(vp.x - fw * 0.5), int(vp.x + fw * 0.5), 2):          # its fringe of icicles on top, under the vault
		for t8 in 2 + int(WildArt.h(xx8, 9, sd) * 5.0):
			p.P(xx8, int(ft) - 1 - t8, Color(0.8, 0.95, 1.0, 0.8))
	# the pillars: three pairs going back into the dark, where ice ran from the vault and froze to the floor
	for d in [0.32, 0.55, 0.85]:
		var t: float = d
		for side in [-1.0, 1.0]:
			var px: float = vp.x + side * hw * 0.82 * t
			var foot := vp.y + (base - vp.y) * t
			var head := vp.y - hh * 0.55 * t - 4.0
			var w := 4.0 + 12.0 * t
			var lit := 0.35 + 0.65 * t
			for yy4 in range(int(head), int(foot)):
				var f := (yy4 - head) / (foot - head)
				var waist := 1.0 - 0.45 * sin(f * PI) * (1.0 if absf(f - 0.5) < 0.5 else 0.0)
				var ww := w * (0.55 + 0.45 * waist) * (1.0 + (1.0 - f) * 0.3 + pow(f, 6.0) * 0.6) * (0.85 + 0.3 * WildArt.h(yy4 / 5, int(px), sd + 61))
				for xx4 in range(int(px - ww * 0.5), int(px + ww * 0.5) + 1):
					var k4: float = (xx4 + 0.5 - px) / (ww * 0.5)
					var c4 := Color(0.45, 0.75, 0.95).lerp(Color(0.85, 0.97, 1.0), clampf(-k4 * 0.8 + 0.2, 0.0, 1.0))   # lit from the left
					if k4 > 0.5:
						c4 = c4.darkened(0.25)
					if WildArt.h(xx4 / 2, yy4 / 5, sd + 60) < 0.12:
						c4 = c4.lightened(0.18)
					if Vector2((xx4 + 0.5 - pc.x) / hw, (yy4 + 0.5 - base) / hh).length() < 0.97:     # in the vault, not past the arch
						p.P(xx4, yy4, Color(c4 * Color(lit, lit, lit), 1.0).lerp(Color(0.04, 0.1, 0.2), (1.0 - lit) * 0.5))
	# icicles hanging from the arch, longest at its crown; the rim's shadow on the snow
	for xx5 in range(int(pc.x - hw * 0.95), int(pc.x + hw * 0.95), 3):
		var dxx := (xx5 + 0.5 - pc.x) / hw
		var ytop := base - sqrt(maxf(0.0, 1.0 - dxx * dxx)) * hh
		var il := 4 + int(WildArt.h(xx5, 3, sd + 70) * (10.0 + 12.0 * (1.0 - absf(dxx))))
		for t5 in il:
			var w5 := 2 if t5 < il * 0.4 else 1
			p.R(xx5, int(ytop) + t5, w5, 1, Color(0.9, 0.98, 1.0).lerp(Color(0.55, 0.8, 0.98), float(t5) / il))
	# the frozen lake: ice as clear as glass, deep blue, bubbles caught in it, white cracks, the portal mirrored
	var lk: Array = wd["lake"]
	var lc: Vector2 = lk[0]
	var lrx: float = lk[1]
	var lry: float = lk[2]
	for yy6 in range(int(lc.y - lry) - 3, int(lc.y + lry) + 4):
		for xx6 in range(int(lc.x - lrx) - 3, int(lc.x + lrx) + 4):
			var e6 := Vector2((xx6 + 0.5 - lc.x) / lrx, (yy6 + 0.5 - lc.y) / lry).length() + (WildArt.h(xx6 / 4, yy6 / 4, sd + 80) - 0.5) * 0.08
			if e6 < 1.0:
				var c6 := Color(0.14, 0.32, 0.55).lerp(Color(0.4, 0.66, 0.88), clampf(e6 * e6, 0.0, 1.0))
				var mx := absf(xx6 + 0.5 - pc.x) / hw
				if yy6 < lc.y and mx < 0.9:
					c6 = c6.lerp(Color(0.55, 0.85, 1.0), 0.22 * (1.0 - mx) * (1.0 - (yy6 - (lc.y - lry)) / lry))   # the portal's glow in the ice
				if WildArt.h(xx6 / 2, yy6 / 2, sd + 81) < 0.015:
					c6 = Color(0.85, 0.95, 1.0)                                 # a bubble caught in the ice
				if (xx6 * 3 + yy6 * 7) % 41 == 0:
					c6 = c6.lightened(0.25)
				p.P(xx6, yy6, c6)
			elif e6 < 1.08:
				p.P(xx6, yy6, Color(0.95, 0.98, 1.0))                           # snow drifted on its edge
	for bb in 12:                                                               # bubbles in columns, rising frozen
		var bx := lc.x + (WildArt.h(bb, 1, sd + 82) - 0.5) * lrx * 1.5
		var by := lc.y + (WildArt.h(bb, 2, sd + 82) - 0.5) * lry * 1.2
		for k6 in 5:
			p.circ(bx + sin(k6 * 1.3) * 1.5, by - k6 * 3.0, 1.6 - k6 * 0.2, Color(0.8, 0.93, 1.0, 0.8))
	for ck in 7:
		var a := lc + Vector2((WildArt.h(ck, 1, sd + 83) - 0.5) * lrx * 1.6, (WildArt.h(ck, 2, sd + 83) - 0.5) * lry * 1.4)
		var b := a + Vector2(WildArt.h(ck, 3, sd + 83) - 0.5, (WildArt.h(ck, 4, sd + 83) - 0.5) * 0.4).normalized() * (30.0 + WildArt.h(ck, 5, sd + 83) * 40.0)
		var nn := int(a.distance_to(b))
		for t6 in nn:
			var q := a.lerp(b, float(t6) / nn) + Vector2(0, sin(t6 * 0.4 + ck) * 1.5)
			if Vector2((q.x - lc.x) / lrx, (q.y - lc.y) / lry).length() < 0.95:
				p.P(int(q.x), int(q.y), Color(0.9, 0.97, 1.0, 0.85))


# ---------------------------------------------------------------- the vistas: arches, lava terraces, the crater

## The three far views, built alike: the terrace on an edge (a canyon's rim, a platform over the lava, a crater's
## rim), the view north across it to the horizon; the sky beyond is left clear in the map and drawn under it (the sun
## setting through the arches, a planet rising behind the crater's far rim, the volcano's glowing smoke). Everything
## north of the edge is scenery, not ground: you look, you do not walk there. South of it the world's own ground, the
## landing place in the south-west, a path to the terrace.
const VISTA := {
	"arches": {"seed": 57, "hz": 150.0, "stone": Color(0.82, 0.68, 0.54), "tint": Color(1.0, 0.96, 0.92), "rock": Color(0.66, 0.36, 0.24), "name": "The Red Arches"},
	"lava": {"seed": 58, "hz": 150.0, "stone": Color(0.42, 0.4, 0.4), "tint": Color(1.0, 0.94, 0.9), "rock": Color(0.2, 0.18, 0.18), "name": "The Fire Terraces"},
	"mirror": {"seed": 61, "hz": 150.0, "stone": Color(0.92, 0.93, 0.92), "tint": Color(1.0, 1.0, 0.98), "rock": Color(0.7, 0.55, 0.4), "name": "The Mirror Front"},
	"crater": {"seed": 59, "hz": 150.0, "stone": Color(0.62, 0.63, 0.66), "tint": Color(1.0, 1.0, 1.0), "rock": Color(0.46, 0.45, 0.46), "name": "The Great Crater"},
}
const RIM := 23                                     # the edge's row: the terrace's railing stands on it


static func _vista(body: Dictionary, site: Dictionary, lsz: Vector2, event: String, theme: String) -> GroundMap:
	var vd: Dictionary = VISTA[theme]
	var rng := RandomNumberGenerator.new()
	rng.seed = int(site.get("seed", 7)) + int(vd["seed"])
	var th: Dictionary = WildGen.PoiData.THEMES["wild_jungle"]
	var m := GroundMap.new()
	m.pal = DeckGen.palette_for_body(body).duplicate()
	for key in ["floor", "floor2", "wall", "wall_top", "trim", "accent"]:
		m.pal[key] = th[key]
	m.pal["frame"] = (th["wall"] as Color).darkened(0.25)
	m.style = "wild"
	m.hull_top = -60
	var W := 66
	var H := 50
	m.setup(W, H)
	m.fill(0, 0, W, H, T.FLOOR, WildGen.FK)
	var ter := PackedByteArray()
	ter.resize(W * H)
	var sdf := PackedFloat32Array()
	sdf.resize(W * H)
	sdf.fill(-99.0)
	var pathm := PackedByteArray()
	pathm.resize(W * H)
	var sd := rng.randi() % 100000
	var cx := W / 2
	var hz: float = vd["hz"]
	var wd := {"biome": theme, "seed": sd, "ter": ter, "sdf": sdf, "paths": [], "clear": [], "fords": [], "keep": [], "pathm": pathm,
		"hz": hz, "rim": RIM}
	# the view: scenery, not ground; rocks heaped along the other edges
	for y in H:
		for x in W:
			var dw := 2 + int(WildGen.h(y / 3, 2, sd) * 2.0)
			var ds := 2 + int(WildGen.h(x / 3, 3, sd) * 2.0)
			if y < RIM or x < dw or x >= W - dw or y >= H - ds:
				ter[y * W + x] = WildGen.CLIFF
	var x0 := cx - 10
	var x1 := cx + 10
	var y0 := RIM
	var y1 := y0 + 7
	(wd["keep"] as Array).append(Rect2(x0 - 1, y0 - 1, x1 - x0 + 3, y1 - y0 + 3))
	var sl := clampi(int(ceil(lsz.x / TILE)) + 4, 10, 40)
	var sb := clampi(int(ceil(lsz.y / TILE)) + 4, 7, 20)
	WildGen._ship_spot(m, wd, 4, H - sb - 4, sl, sb)
	for yy in range(y0, y1 + 1):
		for xx in range(x0, x1 + 1):
			ter[yy * W + xx] = WildGen.OPEN
	# the lava's rivers down the terraces (the water's shader shows them, in the lava's colours)
	var rivers: Array = []
	var steps: Array = []
	if theme == "lava":
		var top := hz + 30.0
		var n_st := 5
		for s in n_st + 1:
			steps.append(top + (RIM * TILE - 14.0 - top) * float(s) / n_st)
		for r in 3:
			var q := Vector2(cx * TILE + (r - 1) * 70.0 + rng.randf_range(-12, 12), top - 6.0)
			var pts := PackedVector2Array()
			var dirx := rng.randf_range(-0.5, 0.5)
			while q.y < RIM * TILE - 20.0:
				pts.append(q)
				dirx = clampf(dirx + rng.randf_range(-0.25, 0.25), -0.9, 0.9)
				q += Vector2(dirx * 3.0, 3.0)
				q.x = clampf(q.x, 60.0, W * TILE - 60.0)
			rivers.append(pts)
			WildGen._stamp(m, sdf, pts, 7.0 if r != 1 else 9.0)
		for pl in 3:                                          # pools on the ledges
			var pc := Vector2(cx * TILE + (pl - 1) * 150.0 + rng.randf_range(-20, 20), float(steps[1 + pl]) + 14.0)
			for yy2 in range(int(pc.y / TILE) - 2, int(pc.y / TILE) + 3):
				for xx2 in range(int(pc.x / TILE) - 5, int(pc.x / TILE) + 6):
					var v := 2.4 - ((Vector2(xx2 + 0.5, yy2 + 0.5) * TILE - pc) / Vector2(1.0, 0.45)).length() / TILE
					var i := yy2 * W + xx2
					if v > sdf[i]:
						sdf[i] = v
		for i2 in W * H:
			if sdf[i2] > 0.0 and i2 / W < RIM:
				ter[i2] = WildGen.WATER
			elif i2 / W >= RIM:
				sdf[i2] = -99.0
	wd["rivers"] = rivers
	wd["steps"] = steps
	WildGen._apply(m, wd)
	WildGen._ship(m, wd, sl, sb, lsz.x, lsz.y)
	WildGen._add_path(m, wd, WildGen._route(m.spawn, Vector2(cx - 3.0, y1 + 1.2) * TILE, rng, 12.0))
	# boulders on the near ground
	var rk := 0
	for tries in 500:
		if rk >= 16:
			break
		var tx := rng.randi_range(3, W - 5)
		var ty := rng.randi_range(RIM + 2, H - 5)
		if not WildGen._free(m, wd, tx, ty) or not WildGen._free(m, wd, tx + 1, ty) or WildGen._in_clearing(wd, Vector2(tx + 0.5, ty + 0.5) * TILE, 1.0):
			continue
		var kind := "lava_rock" if theme == "lava" and rng.randf() < 0.5 else "rock"
		WildGen._block_obj(m, {"kind": kind, "x": tx, "y": ty, "w": 2, "h": 1, "seed": rng.randi(), "col": (vd["rock"] as Color).lightened(rng.randf_range(-0.05, 0.08))}, [Vector2(tx, ty), Vector2(tx + 1, ty)])
		rk += 1
	# glowing cracks by the lava, their light
	var cracks: Array = []
	if theme == "lava":
		for ck in 9:
			var a := Vector2(rng.randf_range(4, W - 6), rng.randf_range(RIM + 2, H - 6)) * TILE
			if WildGen._in_clearing(wd, a, 1.0) or Rect2(x0 * TILE, y0 * TILE, (x1 - x0 + 1) * TILE, (y1 - y0 + 1) * TILE).has_point(a):
				continue
			var b := a + Vector2(rng.randf_range(-1, 1), rng.randf_range(-0.4, 0.4)).normalized() * rng.randf_range(30.0, 70.0)
			cracks.append([a, b])
			m.lights.append({"pos": a.lerp(b, 0.5), "r": 34.0, "col": Color(1.0, 0.45, 0.12), "a": 0.4, "flicker": true})
		for rv in rivers:
			var pv: PackedVector2Array = rv
			for k in range(0, pv.size(), 14):
				m.lights.append({"pos": pv[k], "r": 52.0, "col": Color(1.0, 0.5, 0.15), "a": 0.35, "flicker": true})
	wd["cracks"] = cracks
	m.set_meta("wild", wd)
	m.set_meta("tint", vd["tint"])
	if theme == "lava":
		m.set_meta("water", {"shallow": Color(0.75, 0.16, 0.03), "mid": Color(1.0, 0.45, 0.06), "deep": Color(1.0, 0.78, 0.25), "foam": Color(0.3, 0.1, 0.06), "waves": 0.25})
	m.set_meta("sight_paint", "vista")
	_terrace(m, site, x0, y0, x1, y1, vd["stone"], rng)
	var sight := {"theme": theme, "event": event, "focus": Vector2(cx + 0.5, 6.5) * TILE, "pool": Vector2(cx + 0.5, RIM - 7.0) * TILE,
		"hz": hz, "rim": float(RIM * TILE), "w": float(W * TILE), "rivers": rivers, "steps": steps,
		"name": String(site.get("name", "")), "id": String(site.get("id", ""))}
	if theme == "arches":
		sight["arches"] = _arch_list(W)
	elif theme == "crater":
		sight["peak"] = Vector2(cx * TILE + 40.0, hz + 110.0)
	elif theme == "lava":
		sight["cone"] = Vector2(cx * TILE - 60.0, hz - 62.0)
	m.set_meta("sight", sight)
	m.title = String(site.get("name", vd["name"]))
	return m


## The arches across the canyon: [centre x, foot y, width, height, haze] (art px), far ones first.
static func _arch_list(W: int) -> Array:
	var c := W * TILE * 0.5
	return [[c - 230.0, 222.0, 84.0, 96.0, 0.38], [c + 205.0, 234.0, 110.0, 116.0, 0.28], [c + 4.0, 256.0, 150.0, 172.0, 0.12]]


static func _paint_vista(m: GroundMap, wd: Dictionary, p) -> void:
	var theme := String(wd["biome"])
	var sd: int = wd["seed"]
	var W := m.w * TILE
	var hz: float = wd["hz"]
	var rim := float(int(wd["rim"]) * TILE)
	match theme:
		"arches":
			p.tile_ground(Color(0.8, 0.5, 0.32), Color(0.72, 0.43, 0.27), 901, 2)
		"lava":
			p.tile_ground(Color(0.17, 0.155, 0.16), Color(0.23, 0.2, 0.2), 902, 2)
		"mirror":
			p.tile_ground(Color(0.78, 0.6, 0.42), Color(0.7, 0.53, 0.36), 904, 2)
		_:
			p.tile_ground(Color(0.52, 0.52, 0.54), Color(0.43, 0.43, 0.46), 903, 2)
	_near_ground(m, wd, p, "arches" if theme == "mirror" else theme)
	# the view: the sky left clear for the layer under the map, the far land painted
	var clear := Color(0, 0, 0, 0)
	p.img.fill_rect(Rect2i(0, 0, W, int(rim)), clear)
	match theme:
		"arches":
			_pv_arches(m, wd, p, W, hz, rim, sd)
		"lava":
			_pv_lava(m, wd, p, W, hz, rim, sd)
		"mirror":
			_pv_mirror(m, wd, p, W, hz, rim, sd)
		_:
			_pv_crater(m, wd, p, W, hz, rim, sd)
	# the edge itself: its lip lit, the drop's shadow just under it
	for x in W:
		var e := rim - 2.0 - WildArt.h(x / 4, 5, sd) * 2.0
		var lip: Color = p.img.get_pixel(x, int(rim) + 3)
		for k in 3:
			p.P(x, int(e) + k, lip.lightened(0.18 - k * 0.05))
		for k2 in 6:
			p.P(x, int(e) - 1 - k2, Color(0, 0, 0, 0.35 - k2 * 0.05))


## The near ground: by world – wind ripples and desert scrub, rope lava and ash, regolith with small craters; the path.
static func _near_ground(m: GroundMap, wd: Dictionary, p, theme: String) -> void:
	var sd: int = wd["seed"]
	var W := m.w * TILE
	var H := m.h * TILE
	var rim := float(int(wd["rim"]) * TILE)
	var area := int(W * (H - rim))
	match theme:
		"arches":
			for d in area / 900:                                         # wind ripples in the sand
				var dx := int(WildArt.h(d, 1, 911) * W)
				var dy := int(rim + WildArt.h(d, 2, 911) * (H - rim))
				for t in 10 + int(WildArt.h(d, 3, 911) * 14):
					p.P(dx + t, dy + int(sin(t * 0.4) * 1.2), Color(0.66, 0.38, 0.23))
					p.P(dx + t, dy + 1 + int(sin(t * 0.4) * 1.2), Color(0.88, 0.6, 0.4))
			for s in area / 2600:                                        # scrub: grey-green tufts, their shadows
				var sx := WildArt.h(s, 4, 912) * W
				var sy := rim + WildArt.h(s, 5, 912) * (H - rim)
				p.circ(sx + 2.0, sy + 3.0, 5.0, Color(0.4, 0.2, 0.12, 0.35), 2.0)
				for k in 9:
					var a := WildArt.h(s, k, 913) * TAU
					p.R(int(sx + cos(a) * 3.5), int(sy + sin(a) * 2.0), 2, 1, Color(0.5, 0.56, 0.42).lerp(Color(0.66, 0.7, 0.55), WildArt.h(k, s, 914)))
			for pb in area / 700:                                        # pebbles
				var px := int(WildArt.h(pb, 6, 915) * W)
				var py := int(rim + WildArt.h(pb, 7, 915) * (H - rim))
				p.P(px, py, Color(0.5, 0.28, 0.18))
				p.P(px, py - 1, Color(0.9, 0.66, 0.5))
			for pts in wd["paths"]:
				WildGen._stroke(p, pts, 8.0, Color(0.86, 0.6, 0.42), Color(0.82, 0.56, 0.38), 517, 1)
		"lava":
			for r in area / 1400:                                        # rope lava: its folds
				var rx := WildArt.h(r, 1, 921) * W
				var ry := rim + WildArt.h(r, 2, 921) * (H - rim)
				for f in 5:
					for t in 14:
						var a := -0.9 + t * 0.13
						p.P(int(rx + sin(a) * (6.0 + f * 3.0)), int(ry + f * 3.0 - cos(a) * 4.0), Color(0.3, 0.26, 0.26))
			for a2 in area / 9000:                                       # drifts of ash, sulphur round a vent
				var ac := Vector2(WildArt.h(a2, 3, 922) * W, rim + WildArt.h(a2, 4, 922) * (H - rim))
				p.circ(ac.x, ac.y, 22.0 + WildArt.h(a2, 5, 922) * 20.0, Color(0.42, 0.4, 0.4, 0.35), 9.0)
				if a2 % 3 == 0:
					p.circ(ac.x + 8.0, ac.y, 7.0, Color(0.85, 0.78, 0.25, 0.6), 3.5)
					p.circ(ac.x + 8.0, ac.y, 2.5, Color(0.1, 0.08, 0.08), 1.5)
			for ck in wd.get("cracks", []):                              # cracks glowing from below
				var a: Vector2 = ck[0]
				var b: Vector2 = ck[1]
				var n := int(a.distance_to(b))
				for t2 in n:
					var q := a.lerp(b, float(t2) / n) + Vector2(0, sin(t2 * 0.35) * 2.0)
					p.R(int(q.x) - 1, int(q.y) - 1, 3, 3, Color(0.35, 0.1, 0.05))
					p.P(int(q.x), int(q.y), Color(1.0, 0.6, 0.15))
			for pts2 in wd["paths"]:
				WildGen._stroke(p, pts2, 8.0, Color(0.3, 0.28, 0.28), Color(0.27, 0.25, 0.25), 517, 1)
		_:
			for c in area / 2200:                                        # small craters, lit from the west
				var cc := Vector2(WildArt.h(c, 1, 931) * W, rim + WildArt.h(c, 2, 931) * (H - rim))
				var cr := 3.0 + pow(WildArt.h(c, 3, 931), 3.0) * 16.0
				p.circ(cc.x, cc.y, cr + 1.5, Color(0.6, 0.6, 0.62), (cr + 1.5) * 0.6)
				p.circ(cc.x, cc.y, cr, Color(0.36, 0.36, 0.39), cr * 0.6)
				p.circ(cc.x + cr * 0.25, cc.y + cr * 0.1, cr * 0.75, Color(0.47, 0.47, 0.5), cr * 0.42)
			for pts3 in wd["paths"]:                                     # the way trodden, boot prints in it
				WildGen._stroke(p, pts3, 7.0, Color(0.4, 0.4, 0.42), Color(0.38, 0.38, 0.4), 517, 1)
				var pa: PackedVector2Array = pts3
				for e in range(0, pa.size(), 3):
					p.R(int(pa[e].x) + (2 if e % 6 == 0 else -3), int(pa[e].y), 2, 3, Color(0.3, 0.3, 0.32))
	# where the ship came down: scorched
	for cl in wd["clear"]:
		if String(cl[3]) == "ship":
			var c2: Vector2 = cl[0]
			for sc in 26:
				p.circ(c2.x + (WildArt.h(sc, 1, sd) - 0.5) * float(cl[1]) * 1.4, c2.y + (WildArt.h(sc, 2, sd) - 0.5) * float(cl[2]) * 1.2, 6.0, Color(0.15, 0.12, 0.1, 0.3), 3.0)
	# the rocks heaped along the edges
	var ter: PackedByteArray = wd["ter"]
	var rc: Color = {"arches": Color(0.62, 0.32, 0.2), "lava": Color(0.16, 0.14, 0.14)}.get(theme, Color(0.44, 0.44, 0.46))
	for ty in range(int(wd["rim"]), m.h):
		for tx in m.w:
			if ter[ty * m.w + tx] == WildGen.CLIFF:
				for b in 2:
					var bx := tx * TILE + 4.0 + WildArt.h(tx, ty + b * 7, sd) * 8.0
					var by := ty * TILE + 5.0 + b * 7.0
					var br := 5.0 + WildArt.h(ty, tx + b, sd) * 4.0
					p.circ(bx + 1.5, by + 2.0, br, rc.darkened(0.4), br * 0.7)
					p.circ(bx, by, br, rc.lerp(rc.lightened(0.15), WildArt.h(tx, ty, sd + 1)), br * 0.7)
					p.circ(bx - br * 0.3, by - br * 0.25, br * 0.4, rc.lightened(0.25), br * 0.25)


# ---- the arches: far mesas, the plain with the arches on it, the canyon at our feet

static func _pv_arches(m: GroundMap, wd: Dictionary, p, W: int, hz: float, rim: float, sd: int) -> void:
	var far_rim := 276.0
	var floor_y := 334.0
	# the far plain: hazy far off, redder near, streaked by the wind, scrub getting bigger towards us
	for y in range(int(hz) - 4, int(far_rim) + 10):
		var k := clampf((y - hz) / (far_rim - hz), 0.0, 1.0)
		for x in W:
			var c := Color(0.86, 0.66, 0.56).lerp(Color(0.8, 0.48, 0.3), k)
			if WildArt.h(x / 7, y / 2, 940) < 0.2:
				c = c.darkened(0.05)
			p.P(x, y, c)
	for s in 260:
		var sy := hz + pow(WildArt.h(s, 1, 941), 0.7) * (far_rim - hz - 4.0)
		var k2 := (sy - hz) / (far_rim - hz)
		var sx := WildArt.h(s, 2, 941) * W
		p.R(int(sx), int(sy), 1 + int(k2 * 3.0), 1 + int(k2 * 1.5), Color(0.55, 0.5, 0.4).lerp(Color(0.8, 0.6, 0.5), 0.5 * (1.0 - k2)))
	# far mesas and buttes on the horizon, in the haze
	var mesas := [[-20.0, 180.0, 46.0], [150.0, 260.0, 28.0], [300.0, 330.0, 54.0], [560.0, 760.0, 38.0], [800.0, 840.0, 60.0], [880.0, 1080.0, 34.0]]
	for me in mesas:
		var mx0: float = me[0]
		var mx1: float = me[1]
		var mh: float = me[2]
		for x in range(int(mx0) - 26, int(mx1) + 26):
			if x < 0 or x >= W:
				continue
			var edge := minf(x - mx0, mx1 - x)
			var top := hz - mh
			if edge < 0.0:
				top = hz - mh + (-edge) * mh / 26.0 * 1.0                   # the talus down its flanks
			var cap := top + 5.0
			for y2 in range(int(top), int(hz) + 3):
				var c2 := Color(0.62, 0.44, 0.48)
				if y2 < cap and edge >= 0.0:
					c2 = Color(0.7, 0.55, 0.55)                               # the caprock
				elif (y2 + int(x * 0.02)) % 7 == 0:
					c2 = c2.darkened(0.06)
				if edge >= 0.0 and edge < 3.0:
					c2 = c2.darkened(0.08) if x > (mx0 + mx1) * 0.5 else c2.lightened(0.06)
				p.P(x, y2, c2.lerp(Color(0.8, 0.68, 0.7), 0.25))
	# the arches, the far ones first; their shadows on the plain
	for a in _arch_list(m.w):
		_rock_arch(p, a[0], a[1], a[2], a[3], a[4], sd)
	# a few hoodoos, spires of rock, on the plain
	for hd in 7:
		var hx := 40.0 + WildArt.h(hd, 1, 945) * (W - 80.0)
		var hy := hz + 30.0 + WildArt.h(hd, 2, 945) * 80.0
		var hh := 12.0 + (hy - hz) * 0.25
		var skip := false
		for a2 in _arch_list(m.w):
			if absf(hx - float(a2[0])) < float(a2[2]) * 0.7:
				skip = true
		if skip:
			continue
		for y3 in int(hh):
			var w3 := 2.0 + (1.0 - y3 / hh) * 2.5 + (2.0 if y3 > hh - 4.0 else 0.0)
			for x3 in range(int(hx - w3), int(hx + w3) + 1):
				p.P(x3, int(hy - y3), Color(0.78, 0.42, 0.26).darkened(0.15 if x3 > hx else 0.0).lerp(Color(0.8, 0.65, 0.62), 0.3 * (1.0 - (hy - hz) / 110.0)))
	# the canyon: the far wall's face banded red, cream and rust; the talus; the dry wash on its floor with green in it
	for x in W:
		var lip := far_rim + sin(x * 0.02 + sd) * 4.0 + WildArt.h(x / 6, 1, 946) * 3.0
		var fl := floor_y + sin(x * 0.013) * 5.0
		for y in range(int(lip), int(fl)):
			var depth := (y - lip) / (fl - lip)
			var band := int(y + sin(x * 0.03) * 3.0) % 22
			var c3 := Color(0.82, 0.42, 0.24)
			if band < 3:
				c3 = Color(0.92, 0.78, 0.6)                                 # a pale layer
			elif band < 8:
				c3 = Color(0.72, 0.32, 0.2)
			elif band < 10:
				c3 = Color(0.6, 0.28, 0.2)
			if WildArt.h(x / 3, 2, 947) < 0.18:
				c3 = c3.darkened(0.12 + depth * 0.1)                        # a groove worn down the face
			if depth > 0.78:
				c3 = c3.lerp(Color(0.86, 0.6, 0.42), (depth - 0.78) / 0.22 * 0.7)   # the talus at its foot
			p.P(x, y, c3.darkened(depth * 0.12))
		p.P(x, int(lip), Color(0.96, 0.8, 0.62))
		p.P(x, int(lip) + 1, Color(0.9, 0.66, 0.46))
		for y4 in range(int(fl), int(rim) - 18):
			var c4 := Color(0.86, 0.68, 0.5).lerp(Color(0.8, 0.58, 0.42), WildArt.h(x / 4, y4 / 2, 948))
			var wash := absf(y4 - (fl + 10.0 + sin(x * 0.025 + sd) * 6.0))
			if wash < 2.5:
				c4 = Color(0.62, 0.5, 0.42) if wash > 1.0 else Color(0.45, 0.62, 0.72)   # the wash, a thread of water in it
			p.P(x, y4, c4)
		for y5 in range(int(rim) - 18, int(rim) - 2):
			var k5 := (y5 - (rim - 18.0)) / 16.0
			p.P(x, y5, Color(0.5, 0.24, 0.16).lerp(Color(0.3, 0.14, 0.1), k5))   # our own wall going down, in shadow
	for tr in 34:                                                       # cottonwoods along the wash
		var tx := WildArt.h(tr, 1, 949) * W
		var ty := floor_y + 6.0 + sin(tx * 0.025 + sd) * 6.0 + (WildArt.h(tr, 2, 949) - 0.5) * 8.0
		p.circ(tx + 2.0, ty + 3.0, 5.0, Color(0.3, 0.16, 0.1, 0.4), 2.0)
		p.circ(tx, ty, 4.5, Color(0.36, 0.5, 0.22), 3.5)
		p.circ(tx - 1.0, ty - 1.0, 2.5, Color(0.55, 0.68, 0.32), 2.0)


## A natural arch of sandstone: two legs, the span over the opening; banded, the caprock pale, varnish streaking down,
## lit from the west; the haze of distance over it. The opening is left as it is (the sky, the plain behind).
static func _rock_arch(p, cx: float, foot: float, aw: float, ah: float, haze: float, sd: int) -> void:
	var leg := aw * 0.19
	var span := ah * 0.17
	p.circ(cx + aw * 0.3, foot + 2.0, aw * 0.55, Color(0.35, 0.14, 0.08, 0.3), 4.0)
	for y in range(int(foot - ah) - 2, int(foot) + 1):
		for x in range(int(cx - aw * 0.5) - 2, int(cx + aw * 0.5) + 3):
			var dx := (x + 0.5 - cx) / (aw * 0.5)
			if absf(dx) > 1.0:
				continue
			var top := foot - ah + pow(absf(dx), 3.0) * ah * 0.35 + (WildArt.h(x / 5, 1, sd + 950) - 0.5) * 4.0
			if y < top:
				continue
			var flare := 1.0 + clampf((y - (foot - 10.0)) / 10.0, 0.0, 1.0) * 0.12  # the legs flare at their feet
			var ox := (x + 0.5 - cx) / (aw * 0.5 - leg * flare)
			var oy := (y + 0.5 - foot) / (ah - span)
			var ein := sqrt(ox * ox + oy * oy)
			if ein < 1.0:
				continue
			var c := Color(0.8, 0.4, 0.22)
			var band := int(y + sin(x * 0.07) * 2.0) % 9
			if band == 0:
				c = c.darkened(0.1)
			elif band == 1:
				c = c.lightened(0.07)
			if y < top + 6.0:
				c = c.lerp(Color(0.92, 0.76, 0.56), 0.45)                   # the caprock
			if ein < 1.12:
				c = c.lightened(0.1) if x > cx else c.darkened(0.28)        # the opening's faces: the east one in the sun
			elif dx < -0.82:
				c = c.lightened(0.14)
			elif dx > 0.82:
				c = c.darkened(0.22)
			if WildArt.h(x / 2, 3, sd + 951) < 0.1 and y > top + 8.0 and ein > 1.15:
				c = c.darkened(0.2)                                         # desert varnish, streaking down
			if y < top + 1.0:
				c = c.lightened(0.25)
			p.P(x, y, c.lerp(Color(0.76, 0.62, 0.64), haze))


## Smooth value noise along a line (0…1).
static func _sn(x: float, s: int) -> float:
	var i := int(floor(x))
	var f := x - i
	f = f * f * (3.0 - 2.0 * f)
	return lerpf(WildArt.h(i, 1, s), WildArt.h(i + 1, 1, s), f)


static func _peak_h(dx: float) -> float:
	return 46.0 * exp(-pow(dx / 52.0, 2.0)) + 18.0 * exp(-pow((dx + 40.0) / 26.0, 2.0)) + 12.0 * exp(-pow((dx - 50.0) / 22.0, 2.0))


# ---- the lava: the volcano far off, the terraces stepping down to us, the rivers of lava over them

## 54c (Luz): the Mirror Front's view – far below the new fields in their strips, green, with the irrigation channels
## shining, on one side; the old desert on the other; the churned line of the front between them, the Institute's
## terraforming towers along it, white with a green light; hazy towards the horizon.
static func _pv_mirror(m: GroundMap, wd: Dictionary, p, W: int, hz: float, rim: float, sd: int) -> void:
	var haze := Color(0.95, 0.88, 0.76)
	for y in range(int(hz), int(rim)):
		var k := (float(y) - hz) / (rim - hz)
		var front := W * 0.46 + sin(y * 0.05) * 22.0 + (y - hz) * 0.9
		var strip := 6.0 + k * 22.0
		for x in W:
			var c: Color
			if float(x) < front:
				var pw2 := strip * 2.4                                         # parcels, wider and deeper the nearer
				var ph2 := maxf(3.0, strip * 0.55)
				var col := int(floor(x / pw2))
				var row := int(floor((y - hz) / ph2))
				var fi := (col * 7 + row * 3 + int(WildArt.h(col, row, sd) * 3.0)) % 4
				c = [Color(0.36, 0.56, 0.26), Color(0.44, 0.64, 0.3), Color(0.3, 0.5, 0.22), Color(0.55, 0.62, 0.3)][fi]
				if fmod(float(y) - hz, ph2) < 1.0:
					c = Color(0.62, 0.55, 0.4)                                   # a track between the parcels
				elif fmod(float(x), pw2) < 1.0 and col % 3 == 0:
					c = Color(0.55, 0.75, 0.88)                                  # an irrigation channel shining
			else:
				c = Color(0.84, 0.64, 0.42).lerp(Color(0.72, 0.5, 0.32), WildArt.h(x / 9, y / 4, sd))
				if float(x) - front < 5.0 + k * 6.0:
					c = Color(0.6, 0.52, 0.36)                                   # the churned line
			p.P(x, y, c.lerp(haze, (1.0 - k) * 0.55))
	for t in 8:                                                          # the towers along the front, nearer ones bigger
		var ty := hz + 10.0 + t * 22.0
		if ty > rim - 10.0:
			break
		var tx := W * 0.46 + sin(ty * 0.05) * 22.0 + (ty - hz) * 0.9 + 4.0
		var th := 14.0 + t * 6.0
		var tw := 2 + t / 2
		var tc := Color(0.92, 0.94, 0.94).lerp(haze, 0.5 - t * 0.05)
		for yy in int(th):
			for xx in tw:
				p.P(int(tx) + xx, int(ty - th) + yy, tc if xx < tw - 1 else tc.darkened(0.15))
		p.P(int(tx), int(ty - th), Color(0.4, 1.0, 0.6))
		p.P(int(tx) + 1, int(ty - th), Color(0.4, 1.0, 0.6))


static func _pv_lava(m: GroundMap, wd: Dictionary, p, W: int, hz: float, rim: float, sd: int) -> void:
	var steps: Array = wd["steps"]
	var cone := Vector2(W * 0.5 - 60.0, hz - 62.0)
	# the plain below the volcano, dark, far
	for y in range(int(hz) - 2, int(steps[0])):
		for x in W:
			p.P(x, y, Color(0.2, 0.15, 0.15).lerp(Color(0.14, 0.12, 0.12), (y - hz) / 40.0))
	# the volcano: a cone with its crater glowing, rivulets of lava down its flanks, other peaks behind in the smoke
	for pk in 4:
		var px := 80.0 + pk * 300.0 + WildArt.h(pk, 1, 960) * 60.0
		var ph := 20.0 + WildArt.h(pk, 2, 960) * 24.0
		for x in range(int(px - ph * 3.0), int(px + ph * 3.0)):
			var t := hz - ph + absf(x - px) / 3.0
			for y in range(int(t), int(hz) + 2):
				if x >= 0 and x < W:
					p.P(x, y, Color(0.26, 0.2, 0.22))
	for x2 in range(int(cone.x - 230.0), int(cone.x + 230.0)):
		var dx := absf(x2 - cone.x)
		var t2 := cone.y + maxf(0.0, dx - 22.0) * 0.36 + pow(maxf(0.0, dx - 22.0) / 210.0, 2.0) * 20.0
		for y2 in range(int(t2), int(steps[0]) + 2):
			var c := Color(0.16, 0.12, 0.12)
			if x2 < cone.x - 22.0:
				c = Color(0.22, 0.17, 0.16)                                  # its west flank, lit by the glow behind
			if WildArt.h(x2 / 3, y2 / 5, 961) < 0.15:
				c = c.darkened(0.25)
			p.P(x2, y2, c)
		if dx < 22.0:
			for k in 4:
				p.P(x2, int(t2) + k, Color(1.0, 0.55, 0.15).lerp(Color(0.5, 0.12, 0.05), k / 4.0))   # the crater's glowing lip
	for rv in 5:                                                        # rivulets down the flanks
		var q := cone + Vector2((rv - 2) * 9.0, 4.0)
		var dirx := (rv - 2) * 0.35 + (WildArt.h(rv, 3, 963) - 0.5) * 0.3
		for st in 30 + int(WildArt.h(rv, 4, 963) * 40.0):
			q += Vector2(dirx + sin(st * 0.3 + rv) * 0.4, 1.2)
			if q.y > float(steps[0]):
				break
			p.R(int(q.x), int(q.y), 2, 1, Color(1.0, 0.5, 0.12).lerp(Color(0.6, 0.12, 0.04), st / 70.0))
	# the terraces: ledges of black basalt, the faces between them of columns, lit red from the lava
	for s in steps.size() - 1:
		var ya: float = steps[s]
		var yb: float = steps[s + 1]
		var face := yb - 14.0
		for x3 in W:
			var lip := ya + sin(x3 * 0.04 + s * 1.7) * 2.0
			for y3 in range(int(lip), int(yb)):
				var c3: Color
				if y3 < face:
					c3 = Color(0.2, 0.17, 0.17).lerp(Color(0.26, 0.2, 0.19), WildArt.h(x3 / 3, y3 / 2, 962 + s))   # the ledge
					if (x3 * 3 + y3 * 5) % 37 == 0:
						c3 = c3.lightened(0.12)
				else:
					var col_i := (x3 + s * 3) % 7                                  # the face: basalt columns
					c3 = Color(0.13, 0.11, 0.11) if col_i == 0 else Color(0.2, 0.16, 0.16).lerp(Color(0.32, 0.2, 0.16), (y3 - face) / 14.0)
					if col_i == 1:
						c3 = c3.lightened(0.08)
				p.P(x3, y3, c3)
			p.P(x3, int(lip), Color(0.4, 0.3, 0.26))
	# the near bank under the platform
	for x4 in W:
		for y4 in range(int(steps[steps.size() - 1]), int(rim)):
			p.P(x4, y4, Color(0.18, 0.15, 0.15).lerp(Color(0.1, 0.08, 0.08), (y4 - float(steps[steps.size() - 1])) / 14.0))
	# the lava: clear for the shader, a crust glowing at its edge
	WildGen._carve(m, wd, p, Color(0.45, 0.1, 0.04), Color(0.85, 0.3, 0.06), 0.35, sd)


# ---- the crater: its far rim against the black, the floor with its central peak, our own wall going down

static func _pv_crater(m: GroundMap, wd: Dictionary, p, W: int, hz: float, rim: float, sd: int) -> void:
	var floor0 := hz + 44.0
	var floor1 := rim - 46.0
	# the far rim: jagged peaks, its inner face towards us, terraced where it slumped
	for x in W:
		var t := hz - 10.0 - _sn(x / 28.0, sd + 970) * 26.0 - _sn(x / 9.0, sd + 971) * 9.0 - _sn(x / 3.0, sd + 982) * 2.5 - absf(sin(x * 0.011 + sd)) * 14.0
		for y in range(int(t), int(floor0) + 2):
			var k := (y - t) / (floor0 - t)
			var c := Color(0.62, 0.62, 0.64).lerp(Color(0.44, 0.44, 0.47), k)
			if int(y + sin(x * 0.02) * 4.0) % 11 == 0:
				c = c.darkened(0.2)                                          # a slump terrace's shadow
			if WildArt.h(x / 4, y / 3, sd + 972) < 0.08:
				c = c.lightened(0.14)
			p.P(x, y, c)
		p.P(x, int(t), Color(0.8, 0.8, 0.82))
	# the floor: grey, flat, far; small craters squashed by the angle, boulders, rays of a fresh impact
	for y2 in range(int(floor0), int(floor1)):
		var k2 := (y2 - floor0) / (floor1 - floor0)
		for x2 in W:
			var c2 := Color(0.5, 0.5, 0.52).lerp(Color(0.46, 0.46, 0.48), WildArt.h(x2 / 4, y2 / 2, 973))
			p.P(x2, y2, c2.darkened(0.08 * (1.0 - k2)))
	for c3 in 70:
		var cy := floor0 + pow(WildArt.h(c3, 1, 974), 0.8) * (floor1 - floor0)
		var k3 := (cy - floor0) / (floor1 - floor0)
		var cx := WildArt.h(c3, 2, 974) * W
		var cr := (2.0 + pow(WildArt.h(c3, 3, 974), 3.0) * 22.0) * (0.5 + k3)
		var sq := 0.25 + 0.3 * k3
		p.circ(cx, cy, cr + 1.0, Color(0.6, 0.6, 0.62), (cr + 1.0) * sq)
		p.circ(cx, cy, cr, Color(0.34, 0.34, 0.37), cr * sq)
		p.circ(cx + cr * 0.2, cy + cr * sq * 0.15, cr * 0.75, Color(0.45, 0.45, 0.48), cr * sq * 0.7)
	var fresh := Vector2(W * 0.28, floor0 + 40.0)
	for ry in 14:                                                       # its rays
		var a := ry * TAU / 14.0 + WildArt.h(ry, 1, 975)
		for d in 120:
			var q := fresh + Vector2(cos(a), sin(a) * 0.35) * (d + 4.0)
			if q.y > floor0 and q.y < floor1 and WildArt.h(d, ry, 976) < 0.7:
				p.P(int(q.x), int(q.y), Color(0.68, 0.68, 0.7, 0.6 * (1.0 - d / 120.0)))
	p.circ(fresh.x, fresh.y, 5.0, Color(0.8, 0.8, 0.82), 2.0)
	p.circ(fresh.x, fresh.y, 3.5, Color(0.3, 0.3, 0.33), 1.2)
	# the central peak: a heap of uplifted rock, lit from the west, its shadow thrown east
	var pk := Vector2(W * 0.5 + 40.0, hz + 110.0)
	for yy in range(int(pk.y - 46.0), int(pk.y + 8.0)):
		for xx in range(int(pk.x - 120.0), int(pk.x + 160.0)):
			var dxk := (xx - pk.x)
			var hgt := _peak_h(dxk) + (WildArt.h(xx / 4, 3, sd + 977) - 0.5) * 3.0
			var top := pk.y - hgt
			if hgt < 1.5 or yy < top or yy > pk.y:
				continue
			var slope := _peak_h(dxk - 2.0) - _peak_h(dxk + 2.0)                # rising to the east: in shade; to the west: lit
			var c4 := Color(0.38, 0.38, 0.42).lerp(Color(0.68, 0.68, 0.7), clampf(0.5 - slope * 0.12, 0.0, 1.0))
			if yy - top < 1.5:
				c4 = c4.lightened(0.2)
			if WildArt.h(xx / 3, yy / 3, sd + 978) < 0.1:
				c4 = c4.darkened(0.12)
			var skirt := clampf((yy - (pk.y - 8.0)) / 8.0, 0.0, 1.0) * clampf(1.0 - hgt / 12.0, 0.0, 1.0)
			p.P(xx, yy, c4.lerp(p.img.get_pixel(xx, yy), skirt * 0.8))        # its foot fading into the floor
	for sx in 120:                                                      # its shadow on the floor, thrown east
		var sw := 4.0 * (1.0 - sx / 120.0)
		p.R(int(pk.x + 30.0 + sx), int(pk.y - sw * 0.3), 1, maxi(1, int(sw)), Color(0.15, 0.15, 0.18, 0.3 * (1.0 - sx / 120.0)))
	# our own wall going down to the floor: talus, boulders rolled down, streaks
	for x5 in W:
		for y5 in range(int(floor1), int(rim)):
			var k5 := (y5 - floor1) / (rim - floor1)
			var c5 := Color(0.46, 0.46, 0.49).lerp(Color(0.56, 0.56, 0.58), k5)
			if WildArt.h(x5 / 2, 4, sd + 979) < 0.12:
				c5 = c5.darkened(0.1)
			if WildArt.h(x5 / 3, y5 / 3, sd + 980) < 0.05:
				c5 = c5.lightened(0.2)
			p.P(x5, y5, c5)
	for b in 40:
		var bx := WildArt.h(b, 1, 981) * W
		var by := floor1 + WildArt.h(b, 2, 981) * (rim - floor1 - 6.0)
		var br := 1.5 + WildArt.h(b, 3, 981) * 3.0
		p.circ(bx + 1.0, by + 1.0, br, Color(0.2, 0.2, 0.22, 0.5), br * 0.6)
		p.circ(bx, by, br, Color(0.58, 0.58, 0.6), br * 0.6)


## Clears ground for building: open terrain, no trees or rocks there.
static func _clear_rect(m: GroundMap, wd: Dictionary, x: int, y: int, w: int, h: int) -> void:
	var ter: PackedByteArray = wd["ter"]
	var sdf: PackedFloat32Array = wd["sdf"]
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			if xx < 0 or yy < 0 or xx >= m.w or yy >= m.h:
				continue
			if ter[yy * m.w + xx] != WildGen.WATER:
				ter[yy * m.w + xx] = WildGen.OPEN
	var r := Rect2(x, y, w, h)
	m.objects = m.objects.filter(func(o): return not r.intersects(Rect2(float(o["x"]), float(o["y"]), float(o.get("w", 1)), float(o.get("h", 1)))))


## The viewing terrace (tiles x0…x1, y0…y1): pale stone, the glass railing along its north edge looking out, benches
## facing the view, the information holo, scopes, the souvenir stall; the viewpoint along the railing.
static func _terrace(m: GroundMap, site: Dictionary, x0: int, y0: int, x1: int, y1: int, stone: Color, rng: RandomNumberGenerator) -> void:
	for yy in range(y0, y1 + 1):
		for xx in range(x0, x1 + 1):
			m.set_t(xx, yy, T.FLOOR)
	m.decals.append({"kind": "terrace", "x": x0, "y": y0, "w": x1 - x0 + 1, "h": y1 - y0 + 1, "col": stone})
	m.fill(x0, y0, x1 - x0 + 1, 1, T.BLOCK)
	m.add_object({"kind": "glass_rail", "x": x0, "y": y0, "w": x1 - x0 + 1, "h": 1}, false)
	var acc := Color(0.45, 0.9, 1.0)
	for sx in [x0 + 2, x1 - 3]:
		m.add_object({"kind": "scope", "x": sx, "y": y0 + 1, "w": 1, "h": 1, "col": acc})
	DeckGen._seat(m, "bench", x0 + 4, y0 + 2, 1, Color(0.5, 0.36, 0.22), rng, 0.35, 3)
	DeckGen._seat(m, "bench", x1 - 7, y0 + 2, 1, Color(0.5, 0.36, 0.22), rng, 0.35, 3)
	var hx := (x0 + x1) / 2
	m.add_object({"kind": "holo_pillar", "x": hx, "y": y0 + 5, "w": 1, "h": 1, "col": acc})
	m.lights.append({"pos": Vector2(hx + 0.5, y0 + 5.3) * TILE, "r": 40.0, "col": acc, "a": 0.35})
	m.zones.append({"rect": Rect2(Vector2(hx - 0.5, y0 + 5.5) * TILE, Vector2(2, 1.2) * TILE), "kind": "sight_info", "id": "sight_info",
		"title": "Information: %s" % String(site.get("name", "")), "col": acc, "sign": Vector2(-100, -100)})
	m.add_object({"kind": "stall", "x": x1 - 2, "y": y1 - 1, "w": 2, "h": 1, "col": Color(1.0, 0.6, 0.3)})
	m.zones.append({"rect": Rect2(Vector2(x1 - 3.0, y1 - 1.6) * TILE, Vector2(4, 1.6) * TILE), "kind": "souvenir", "id": "souvenir",
		"title": "Souvenir stall", "col": Color(1.0, 0.7, 0.35), "sign": Vector2(x1 - 1, y1 - 2.2) * TILE})
	m.zones.append({"rect": Rect2(Vector2(x0 + 0.5, y0 + 0.8) * TILE, Vector2(x1 - x0, 1.4) * TILE), "kind": "viewpoint", "id": "viewpoint",
		"title": "The viewpoint: take a photo", "col": Color(1.0, 0.9, 0.5), "sign": Vector2(-100, -100)})
	m.zones.append({"rect": Rect2(), "kind": "label", "id": "sight_name", "title": String(site.get("name", "")), "col": Color(1.0, 0.9, 0.6),
		"sign": Vector2(hx + 0.5, y1 + 0.6) * TILE})
	for lx in [x0, x1]:
		m.add_object({"kind": "lamp_post", "x": lx, "y": y1, "w": 1, "h": 1, "rise": 50})
		m.lights.append({"pos": Vector2(lx + 0.5, y1 - 0.3) * TILE, "r": 56.0, "col": Color(1.0, 0.9, 0.7), "a": 0.3})
	DeckGen._seats(m)
	for k in 8:
		var wp := Vector2(rng.randf_range(x0 + 1.0, x1 - 1.0), rng.randf_range(y0 + 1.4, y1 - 0.5)) * TILE
		if m.free_at(wp, 6.0):
			m.wander.append(wp)
	m.set_meta("tourists", 7)
