extends RefCounted
## Package 62a, parts 4 and 5 (Luz): the ground the Colosseum's fights are fought on. The arena builds whole maps as
## holograms, far larger than the arena itself: a setting (a canyon of dust, a shelf of ice, a yard of containers, a
## ruin in the jungle, a field of lava, a back lot of the city by night) mixed with a ground plan (an open field, a
## canyon of long walls with gaps, a fortress round the middle, three lanes). Every setting has a danger of its own:
## clouds that block the sight, sheets of ice you slide on, ground that burns, undergrowth that holds you back.
## You begin in the south, the others in the north; charging points stand at five fixed places; a wall of light runs
## round the field where the hologram ends. At your starting point a pad lets you give up.
## No class_name: preload it.

const CD = preload("res://data/colosseum.gd")
const TILE := GroundMap.TILE
const VW := 84                     # a fight's map (tiles): far larger than the arena
const VH := 58
const EDGE := 2                    # the wall of light round it (tiles)
const BODY_FLOOR := {"yard": 14, "neon": 14}      # (the rest: the ground of a planet)


static func build(setting_id: String, seed_n: int, layout_id: String = "open") -> GroundMap:
	var st: Dictionary = CD.SETTINGS[0]
	for s in CD.SETTINGS:
		if String(s["id"]) == setting_id:
			st = s
	var sid := String(st["id"])
	var m := GroundMap.new()
	m.pal = DeckGen.palette_for_body({"type": String(st["body"])})
	if sid == "neon":
		m.pal["floor"] = Color(0.2, 0.2, 0.28)
		m.pal["floor2"] = Color(0.24, 0.24, 0.32)
	m.title = "The Colosseum"
	m.hull_top = -60
	m.setup(VW, VH)
	var kind := int(BODY_FLOOR.get(sid, 13))
	m.fill(0, 0, VW, VH, GroundMap.T.BLOCK, kind)
	m.fill(EDGE, EDGE, VW - EDGE * 2, VH - EDGE * 2, GroundMap.T.FLOOR, kind)
	var mid := VW / 2
	m.spawn = Vector2(mid, VH - EDGE - 3.5) * TILE
	m.set_meta("from_gate", m.spawn)
	m.set_meta("col_vr", sid)
	m.set_meta("col_vr_name", String(st["name"]))
	m.set_meta("col_layout", layout_id)
	m.decals.append({"kind": "mat", "x": mid - 2, "y": VH - EDGE - 3, "w": 4, "h": 2, "col": Color(0.3, 0.9, 1.0)})
	m.zones.append({"rect": Rect2(Vector2(mid - 2, VH - EDGE - 3.0) * TILE, Vector2(4.0, 2.0) * TILE), "kind": "col_giveup", "id": "col_giveup",
		"title": "Give up: leave the hologram", "col": Color(1.0, 0.45, 0.4), "sign": Vector2(-100, -100)})
	for fx in [mid - 9, mid, mid + 9]:
		m.foe_spawns.append(Vector2(fx + 0.5, EDGE + 4.5) * TILE)
	# charging points spread over the field: energy and ammunition, for you and for the others; one use draws a point
	# dry for a while. `col_stations`: [{"at": where you stand to use it, "cool": seconds until it is ready, "i"}]
	var stations: Array = []
	var spots: Array = [Vector2(0.2, 0.26), Vector2(0.8, 0.26), Vector2(0.5, 0.5), Vector2(0.2, 0.76), Vector2(0.8, 0.76)]
	for si in mini(CD.STATIONS, spots.size()):
		var sx := int(VW * (spots[si] as Vector2).x)
		var sy := int(VH * (spots[si] as Vector2).y)
		m.add_object({"kind": "fuel_point", "x": sx, "y": sy, "w": 2, "h": 1, "rise": 34})
		var at := Vector2(sx + 1.0, sy + 1.7) * TILE
		stations.append({"at": at, "cool": 0.0, "i": si})
		m.zones.append({"rect": Rect2(Vector2(sx - 0.6, sy + 1.0) * TILE, Vector2(3.2, 1.6) * TILE), "kind": "col_charge", "id": "col_charge_%d" % si, "i": si,
			"title": "Charging point: energy and ammunition", "col": Color(0.35, 0.95, 1.0), "sign": Vector2(-100, -100)})
		m.lights.append({"pos": at, "r": 44.0, "col": Color(0.35, 0.95, 1.0), "a": 0.4})
	m.set_meta("col_stations", stations)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("col_vr_%s_%s_%d" % [setting_id, layout_id, seed_n])
	var rock: Color = (m.pal["terrain_a"] as Color).darkened(0.25).lerp(Color(0.45, 0.43, 0.42), 0.5)
	if sid == "ice":
		rock = Color(0.72, 0.84, 0.95)
	elif sid == "jungle":
		rock = Color(0.4, 0.46, 0.38)
	elif sid == "lava":
		rock = Color(0.2, 0.17, 0.18)
	var keep: Array = [m.spawn] + m.foe_spawns + stations.map(func(sd): return sd["at"])
	var near := func(p: Vector2, tiles: float) -> bool:
		for k in keep:
			if (k as Vector2).distance_to(p) < tiles * TILE:
				return true
		return false
	# ---- the ground plan: what divides the field
	var made := bool(st.get("made", false))
	var wall := func(x: int, y: int, w: int, h: int) -> void:      # a stretch of wall, tile by tile clear of what must stay free
		for yy in range(y, y + h):
			for xx in range(x, x + w):
				if xx < EDGE + 1 or yy < EDGE + 1 or xx >= VW - EDGE - 1 or yy >= VH - EDGE - 1 or not GroundMap.walkable_t(m.t_at(xx, yy)):
					continue
				if near.call(Vector2(xx + 0.5, yy + 0.5) * TILE, 3.2):
					continue
				if made:
					m.add_object({"kind": "bulwark", "x": xx, "y": yy, "w": 1, "h": 1})
				elif not m.free_at(Vector2(xx + 0.5, yy + 0.5) * TILE, 2.0):
					continue                                    # (a block of rock stands here already)
				elif w >= 2 and h >= 2 and xx + 1 < x + w and yy + 1 < y + h and xx + 1 < VW - EDGE - 1 and yy + 1 < VH - EDGE - 1 \
						and not near.call(Vector2(xx + 1.5, yy + 0.5) * TILE, 3.2) and not near.call(Vector2(xx + 0.5, yy + 1.5) * TILE, 3.2) \
						and not near.call(Vector2(xx + 1.5, yy + 1.5) * TILE, 3.2):
					m.add_object({"kind": "rock" if sid != "lava" else "lava_rock", "x": xx, "y": yy, "w": 2, "h": 2, "col": rock, "seed": rng.randi()})
				else:
					m.add_object({"kind": "rock" if sid != "lava" else "lava_rock", "x": xx, "y": yy, "w": 1, "h": 1, "col": rock, "seed": rng.randi()})
	var lava_lines: Array = []
	match layout_id:
		"canyon":                                              # two long walls across, three gaps in each
			for wy in [int(VH * 0.36), int(VH * 0.64)]:
				var gaps: Array = [rng.randi_range(8, 20), rng.randi_range(34, 46), rng.randi_range(60, 72)]
				var x := EDGE + 1
				while x < VW - EDGE - 1:
					if gaps.any(func(g): return x + 1 >= int(g) and x < int(g) + 6):
						x += 2
						continue
					wall.call(x, wy, 2, 2)
					x += 2
		"fortress":                                            # a ring round the middle, a gate on every side; pieces of an outer ring
			var cx := VW / 2
			var cy := VH / 2
			for xx in range(cx - 11, cx + 12):
				if absi(xx - cx) > 2:
					wall.call(xx, cy - 7, 1, 1)
					wall.call(xx, cy + 7, 1, 1)
			for yy in range(cy - 7, cy + 8):
				if absi(yy - cy) > 2:
					wall.call(cx - 11, yy, 1, 1)
					wall.call(cx + 11, yy, 1, 1)
			for q in 8:
				var a := q * TAU / 8.0 + 0.4
				wall.call(int(cx + cos(a) * 24.0) - 2, int(cy + sin(a) * 15.0), 4, 1)
		"lanes":                                               # two strips from north to south, two crossings in each
			for lx in [int(VW * 0.36), int(VW * 0.64)]:
				var crossings: Array = [rng.randi_range(12, 18), rng.randi_range(36, 44)]
				for yy in range(EDGE + 8, VH - EDGE - 8, 1 if sid == "lava" else 2):
					if crossings.any(func(c): return yy + (0 if sid == "lava" else 1) >= int(c) and yy < int(c) + 5):
						continue
					if sid == "lava":                               # (a stream of lava: no way across, but you see across)
						for xx in [lx, lx + 1]:
							if not near.call(Vector2(xx + 0.5, yy + 0.5) * TILE, 3.2):
								m.set_t(xx, yy, GroundMap.T.BLOCK)
								lava_lines.append(Rect2(Vector2(xx, yy) * TILE, Vector2(TILE, TILE)))
					else:
						wall.call(lx, yy, 2, 2)
	m.set_meta("col_lava", lava_lines)
	# ---- the cover, cell by cell (clear round where anybody begins and round the charging points)
	var pieces := {
		"crates": [[["crates", 2, 1], ["crates", 2, 1, 0, 1]], [["crates", 2, 1]], [["crates", 2, 1], ["barrier", 1, 2, 2, 0]]],
		"barrier": [[["barrier", 3, 1]], [["barrier", 1, 3]], [["barrier", 4, 1]]],
		"rock": [[["rock", 2, 1]], [["rock", 2, 2]], [["rock", 3, 2]]],
		"lava_rock": [[["lava_rock", 2, 1]], [["lava_rock", 2, 2]], [["lava_rock", 3, 2]]],
		"bulwark": [[["bulwark", 3, 1]], [["bulwark", 1, 3]]],
		"barrel": [[["barrel", 1, 1], ["barrel", 1, 1, 1, 0]]],
		"tree": [[["tree", 1, 1]], [["tree", 1, 1], ["tree", 1, 1, 2, 1]], [["tree", 1, 1], ["rock", 2, 1, 1, 1]]],
	}
	var skip := 0.2 if layout_id == "open" else 0.42
	for cy2 in range(EDGE + 2, VH - EDGE - 5, 6):
		for cx2 in range(EDGE + 2, VW - EDGE - 5, 7):
			if rng.randf() < skip:
				continue
			var what := String((st["cover"] as Array)[rng.randi() % (st["cover"] as Array).size()])
			var set_: Array = pieces[what]
			var piece: Array = set_[rng.randi() % set_.size()]
			var ox := cx2 + rng.randi_range(0, 3)
			var oy := cy2 + rng.randi_range(0, 2)
			var ok := true
			for part in piece:
				var px := ox + (int(part[3]) if part.size() > 3 else 0)
				var py := oy + (int(part[4]) if part.size() > 4 else 0)
				for yy2 in range(py - 1, py + int(part[2]) + 1):
					for xx2 in range(px - 1, px + int(part[1]) + 1):
						if not GroundMap.walkable_t(m.t_at(xx2, yy2)) or xx2 >= VW - EDGE - 1 or yy2 >= VH - EDGE - 1:
							ok = false
				for ki in keep.size():
					if (keep[ki] as Vector2).distance_to(Vector2(px + 1.0, py + 0.5) * TILE) < (5.5 if ki < 4 else 3.5) * TILE:
						ok = false
			if not ok:
				continue
			for part2 in piece:
				var o := {"kind": String(part2[0]), "x": ox + (int(part2[3]) if part2.size() > 3 else 0), "y": oy + (int(part2[4]) if part2.size() > 4 else 0),
					"w": int(part2[1]), "h": int(part2[2])}
				if String(o["kind"]) in ["rock", "lava_rock"]:
					o["col"] = rock
					o["seed"] = rng.randi()
				m.add_object(o)
	# ---- the setting's danger
	var rects: Array = []
	var want := {"ice": [7, 9, 5], "burn": [6, 5, 3], "slow": [7, 8, 5]}.get(String(st["hazard"]), [0, 0, 0]) as Array
	var tries := 0
	while rects.size() < int(want[0]) and tries < 200:
		tries += 1
		var rw := int(want[1]) + rng.randi_range(-1, 2)
		var rh := int(want[2]) + rng.randi_range(-1, 1)
		var rx := rng.randi_range(EDGE + 2, VW - EDGE - 2 - rw)
		var ry := rng.randi_range(EDGE + 8, VH - EDGE - 8 - rh)
		var r := Rect2(Vector2(rx, ry) * TILE, Vector2(rw, rh) * TILE)
		if near.call(r.get_center(), 6.5) or rects.any(func(q2): return (q2 as Rect2).grow(TILE * 2.0).intersects(r)):
			continue
		if tries < 150:                                           # (on open ground while there is some to be found)
			var open := true
			for ty2 in range(ry, ry + rh):
				for tx2 in range(rx, rx + rw):
					if not m.free_at(Vector2(tx2 + 0.5, ty2 + 0.5) * TILE, 2.0):
						open = false
			if not open:
				continue
		rects.append(r)
	var hz := {"kind": String(st["hazard"]), "rects": rects, "name": String(st["danger"])}
	match String(st["hazard"]):
		"burn":
			hz["dps"] = 14.0 if sid == "yard" else 16.0
			hz["dtype"] = "optical" if sid == "yard" else "explosive"
			hz["pulse"] = [2.5, 3.5] if sid == "yard" else []      # (the yard's plates go on and off; embers always burn)
			hz["look"] = "plates" if sid == "yard" else "embers"
		"slow":
			hz["k"] = 0.55
			for rr in rects:                                      # green over it (nothing in your way)
				for sq in 5:
					var sp := (rr as Rect2).position + Vector2(rng.randf() * (rr as Rect2).size.x, rng.randf() * (rr as Rect2).size.y)
					var tx := int(sp.x / TILE)
					var ty := int(sp.y / TILE)
					if GroundMap.walkable_t(m.t_at(tx, ty)):
						m.add_object({"kind": "shrub", "x": tx, "y": ty, "w": 1, "h": 1}, false)
		"cloud":
			hz["every"] = 8.0 if sid == "dust" else 6.5
			hz["time"] = 9.0 if sid == "dust" else 5.0
			hz["r"] = 46.0 if sid == "dust" else 40.0
			hz["look"] = "dust" if sid == "dust" else "steam"
			var vents: Array = []
			if sid == "neon":
				var vt := 0
				while vents.size() < 8 and vt < 200:
					vt += 1
					var vp := Vector2(rng.randi_range(EDGE + 4, VW - EDGE - 5) + 0.5, rng.randi_range(EDGE + 9, VH - EDGE - 10) + 0.5) * TILE
					if m.free_at(vp, 6.0) and not near.call(vp, 5.0) and not vents.any(func(v): return (v as Vector2).distance_to(vp) < 8.0 * TILE):
						vents.append(vp)
			hz["spots"] = vents
	m.set_meta("col_hazards", [hz])
	m.set_meta("col_haz_state", {"t": 0.0, "tick": 0.0, "cloud": 2.0, "n": 0})
	if sid in ["yard", "neon"]:                                 # floodlights on masts; the lot by night in neon
		var cols: Array = [Color(1.0, 0.95, 0.8)] if sid == "yard" else [Color(1.0, 0.36, 0.66), Color(0.3, 0.9, 1.0), Color(0.72, 0.5, 1.0)]
		var li := 0
		for lx2 in range(EDGE + 6, VW - EDGE - 4, 14):
			for ly in [EDGE + 6, VH / 2, VH - EDGE - 8]:
				m.lights.append({"pos": Vector2(lx2, ly) * TILE, "r": 130.0, "col": cols[li % cols.size()], "a": 0.3 if sid == "yard" else 0.42})
				li += 1
	if sid == "lava":
		for rr2 in rects:
			m.lights.append({"pos": (rr2 as Rect2).get_center(), "r": 90.0, "col": Color(1.0, 0.45, 0.15), "a": 0.35, "flicker": true})
	weigh(m)
	return m


## Part 6 (Luz): the others and your team know the ground: their ways go round what burns and, where it is not
## much farther, round the undergrowth.
static func weigh(m: GroundMap) -> void:
	m.path(m.spawn, m.spawn)                                    # (the grid of ways is made on the first call)
	for h in m.get_meta("col_hazards", []):
		var k := 7.0 if String(h["kind"]) == "burn" else (1.8 if String(h["kind"]) == "slow" else 1.0)
		if k == 1.0:
			continue
		for r in h["rects"]:
			var rr: Rect2 = r
			for ty in range(int(rr.position.y / TILE), int(ceil(rr.end.y / TILE))):
				for tx in range(int(rr.position.x / TILE), int(ceil(rr.end.x / TILE))):
					if tx >= 0 and ty >= 0 and tx < m.w and ty < m.h:
						m._astar.set_point_weight_scale(Vector2i(tx, ty), k)


## Is a danger that pulses on at the clock `t`?
static func live(h: Dictionary, t: float) -> bool:
	var p: Array = h.get("pulse", [])
	if p.size() < 2:
		return true
	return fposmod(t, float(p[0]) + float(p[1])) < float(p[0])


## What the ground does to who walks at `p`: "" (nothing), "ice" (you slide), "slow" (it holds you back).
static func ground_at(m: GroundMap, p: Vector2) -> String:
	for h in m.get_meta("col_hazards", []):
		if String(h["kind"]) in ["ice", "slow"]:
			for r in h["rects"]:
				if (r as Rect2).has_point(p):
					return String(h["kind"])
	return ""


## The wall of light where the hologram ends, the charging points' rings, the setting's danger on the ground, and the
## grid running over it all as the map comes up (art px, under the people).
class VrFx extends Node2D:
	const CV = preload("res://scripts/ground/colosseum_vr.gd")
	const CD = preload("res://data/colosseum.gd")
	var boot := 1.0                  # 1 … 0: the map is still coming up
	var stations: Array = []         # the charging points ({at, cool}): a ring of light round each, dim while it is drawn dry
	var hazards: Array = []          # the setting's danger (map meta col_hazards)
	var state: Dictionary = {}       # … and its clock (map meta col_haz_state)
	var lava: Array = []             # streams of lava (tiles as rects)
	var decor: Array = []            # (part 8) what lies on a stage's ground: {kind: "crater" | "scorch" | "crack", pos, r, a}; (part 9) "drift" | "hair" | "melt" | "track" (pts, across)
	var tw: int = CV.VW              # the hologram's size in tiles (part 7: Survivor's stages are far larger)
	var th: int = CV.VH
	var _banks := {}                 # … where they lie (to find their banks)
	var _t := 0.0

	static func _h(i: int, salt: int) -> float:
		return fposmod(sin(float(i) * 12.9898 + float(salt) * 78.233) * 43758.5453, 1.0)

	func _process(dt: float) -> void:
		_t += dt
		boot = maxf(0.0, boot - dt / 2.2)
		queue_redraw()

	func _draw() -> void:
		var w := float(tw * CV.TILE)
		var h := float(th * CV.TILE)
		var e := float(CV.EDGE * CV.TILE)
		var blue := Color(0.3, 0.75, 1.0)
		var ht := float(state.get("t", _t))
		for dc in decor:                                        # (part 8) what the fighting left on the ground
			var dp: Vector2 = dc["pos"]
			var dr := float(dc["r"])
			match String(dc["kind"]):
				"crater":
					draw_set_transform(dp, 0.0, Vector2(1.0, 0.6))
					draw_circle(Vector2.ZERO, dr, Color(0.05, 0.05, 0.07, 0.75))
					draw_circle(Vector2(0.0, dr * 0.14), dr * 0.68, Color(0.02, 0.02, 0.03, 0.8))
					draw_arc(Vector2.ZERO, dr, PI, TAU, 20, Color(0.5, 0.5, 0.57, 0.55), 1.0)
					draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				"scorch":
					draw_set_transform(dp, 0.0, Vector2(1.0, 0.6))
					for sq in 3:
						draw_circle(Vector2(_h(int(dp.x) + sq, 1) * 8.0 - 4.0, _h(int(dp.y) + sq, 2) * 6.0 - 3.0), dr * (1.0 - sq * 0.25), Color(0.02, 0.02, 0.03, 0.2))
					draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				"crack":
					var cpts := PackedVector2Array([dp])
					for cq in 6:
						cpts.append(cpts[cq] + Vector2.from_angle(float(dc.get("a", 0.0)) + (_h(int(dp.x) + cq, 3) - 0.5) * 1.5) * dr / 6.0)
					draw_polyline(cpts, Color(0.05, 0.05, 0.07, 0.8), 1.0)
					draw_line(cpts[3], cpts[3] + Vector2.from_angle(float(dc.get("a", 0.0)) + 1.1) * dr * 0.3, Color(0.05, 0.05, 0.07, 0.7), 1.0)
				"track":                                          # (part 9) a track trodden into the snow: packed and darker, the ruts of sledges along it
					var tpts: PackedVector2Array = dc["pts"]
					var tacr: Vector2 = dc.get("across", Vector2.DOWN)
					draw_polyline(tpts, Color(0.3, 0.43, 0.7, 0.2), dr + 14.0)
					draw_polyline(tpts, Color(0.3, 0.43, 0.7, 0.24), dr)
					for ts in [-1.0, 1.0]:
						var rut := PackedVector2Array()
						var lip := PackedVector2Array()
						for tp in tpts:
							rut.append(tp + tacr * (ts * dr * 0.26))
							lip.append(tp + tacr * (ts * dr * 0.26 + 2.0))
						draw_polyline(rut, Color(0.2, 0.33, 0.62, 0.5), 2.0)
						draw_polyline(lip, Color(1.0, 1.0, 1.0, 0.4), 1.0)
				"drift":                                          # (part 9) a drift of snow: lit from the upper left, its shadow in its lee
					draw_set_transform(dp, 0.0, Vector2(1.0, 0.42))
					draw_circle(Vector2(3.0, 5.0), dr, Color(0.36, 0.5, 0.76, 0.3))
					draw_circle(Vector2.ZERO, dr, Color(0.86, 0.92, 1.0, 0.6))
					draw_circle(Vector2(-dr * 0.2, -dr * 0.24), dr * 0.58, Color(1.0, 1.0, 1.0, 0.55))
					draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				"melt":                                           # the ground round a steam vent: wet, dark, the snow gone
					draw_set_transform(dp, 0.0, Vector2(1.0, 0.6))
					draw_circle(Vector2.ZERO, dr, Color(0.36, 0.47, 0.64, 0.4))
					draw_circle(Vector2.ZERO, dr * 0.66, Color(0.2, 0.26, 0.36, 0.55))
					draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# ---- the danger on the ground
		if _banks.is_empty() and not lava.is_empty():
			for lr0 in lava:
				_banks[(lr0 as Rect2).position] = true
		var li := 0
		for lr in lava:
			var l: Rect2 = lr
			li += 1
			draw_rect(l, Color(0.92, 0.3, 0.05))
			var drift := fposmod(_t * 5.0 + _h(li, 1) * 16.0, 16.0)             # the stream moves south
			draw_rect(Rect2(l.position.x + 2.0 + _h(li, 2) * 6.0, l.position.y + drift - 1.0, 5.0 + _h(li, 3) * 4.0, 2.0).intersection(l), Color(1.0, 0.82, 0.3))
			draw_rect(Rect2(l.position.x + 1.0 + _h(li, 4) * 9.0, l.position.y + fposmod(drift + 8.0, 16.0) - 1.0, 4.0, 2.0).intersection(l), Color(0.4, 0.1, 0.04, 0.85))
			draw_rect(l, Color(1.0, 0.6, 0.2, 0.18 + 0.12 * sin(_t * 2.0 + l.position.y * 0.05)))
			for side2 in [-1.0, 1.0]:                                          # a dark crust where the stream meets the rock
				if not _banks.has(l.position + Vector2(side2 * 16.0, 0.0)):
					draw_rect(Rect2(l.position.x if side2 < 0.0 else l.end.x - 3.0, l.position.y, 3.0, 16.0), Color(0.22, 0.07, 0.05))
					draw_rect(Rect2(l.position.x + 3.0 if side2 < 0.0 else l.end.x - 5.0, l.position.y + _h(li, 5) * 10.0, 2.0, 5.0), Color(0.5, 0.14, 0.05))
			for end2 in [-1.0, 1.0]:
				if not _banks.has(l.position + Vector2(0.0, end2 * 16.0)):
					draw_rect(Rect2(l.position.x, l.position.y if end2 < 0.0 else l.end.y - 3.0, 16.0, 3.0), Color(0.22, 0.07, 0.05))
		for hz in hazards:
			var on: bool = CV.live(hz, ht)
			var ri := 0
			if String(hz.get("look", "")) == "floe":             # (part 9) floes of bare ice: a sheet deeper in colour than the snow, a rim of snow round it, glints running over it
				var fi := 0
				for fl in hz.get("floes", []):
					var poly: PackedVector2Array = fl
					fi += 1
					var mid := Vector2.ZERO
					for pt in poly:
						mid += pt
					mid /= float(poly.size())
					var inner := PackedVector2Array()
					for pt2 in poly:
						inner.append(mid + (pt2 - mid) * 0.74)
					draw_colored_polygon(poly, Color(0.4, 0.66, 0.9, 0.92))
					draw_colored_polygon(inner, Color(0.56, 0.8, 0.98, 0.5))
					for k7 in 12:                                      # (glints, each lighting up in its turn)
						var gp7 := mid + (poly[int(_h(fi * 31 + k7, 21) * (poly.size() - 1))] - mid) * (0.12 + 0.66 * _h(fi * 31 + k7, 22))
						var ga7 := 0.35 + 0.5 * absf(sin(_t * 0.9 + _h(fi * 31 + k7, 23) * TAU))
						draw_line(gp7, gp7 + Vector2(12.0 + _h(k7, 24) * 16.0, -3.0 - _h(k7, 25) * 3.0), Color(1.0, 1.0, 1.0, ga7), 1.0)
					var rim := poly.duplicate()
					rim.append(poly[0])
					draw_polyline(rim, Color(0.2, 0.42, 0.72, 0.55), 4.0)
					draw_polyline(rim, Color(0.95, 0.98, 1.0, 0.95), 1.5)
				continue
			for rr in hz.get("rects", []):
				var r: Rect2 = rr
				ri += 1
				match String(hz["kind"]):
					"ice":
						draw_rect(r, Color(0.62, 0.84, 1.0, 0.62))
						draw_rect(r.grow(-3.0), Color(0.8, 0.94, 1.0, 0.35))
						for k in 10:
							var sx := r.position.x + 3.0 + _h(ri * 7 + k, 1) * (r.size.x - 34.0)
							var sy := r.position.y + 6.0 + _h(ri * 7 + k, 2) * (r.size.y - 10.0)
							draw_line(Vector2(sx, sy), Vector2(sx + 14.0 + _h(k, 3) * 14.0, sy - 3.0 - _h(k, 4) * 3.0), Color(1, 1, 1, 0.85), 1.0)
						draw_rect(r, Color(0.35, 0.68, 1.0, 0.9), false, 1.5)
					"slow":
						if String(hz.get("look", "")) == "oil":             # (part 8) spilled oil: a dark sheet, a sheen of colours drifting over it
							for ob in 7:                                         # (a puddle with arms, not a sheet with corners)
								var oc := r.get_center() + Vector2((_h(ri * 23 + ob, 14) - 0.5) * r.size.x * 0.5, (_h(ri * 23 + ob, 15) - 0.5) * r.size.y * 0.4)
								draw_set_transform(oc, 0.0, Vector2(1.0, 0.6))
								draw_circle(Vector2.ZERO, r.size.x * (0.2 + 0.14 * _h(ri * 23 + ob, 16)), Color(0.02, 0.02, 0.04, 0.5))
								draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
							for k6 in 12:
								var op := r.position + Vector2(8.0 + _h(ri * 19 + k6, 11) * (r.size.x - 26.0), 8.0 + _h(ri * 19 + k6, 12) * (r.size.y - 16.0))
								draw_rect(Rect2(op + Vector2(sin(_t * 0.5 + k6) * 2.0, 0.0), Vector2(7.0, 1.0)), Color.from_hsv(fposmod(_h(k6, 13) + _t * 0.05, 1.0), 0.5, 0.9, 0.35))
							continue
						if String(hz.get("look", "")) == "coolant":         # (part 7) spilled coolant: a pale blue sheet, glints drifting over it
							draw_rect(r.grow(-4.0), Color(0.25, 0.75, 0.95, 0.3))
							draw_rect(r.grow(-10.0), Color(0.45, 0.9, 1.0, 0.22))
							for k5 in 14:
								var gp := r.position + Vector2(8.0 + _h(ri * 17 + k5, 9) * (r.size.x - 22.0), 8.0 + _h(ri * 17 + k5, 10) * (r.size.y - 16.0))
								draw_rect(Rect2(gp + Vector2(sin(_t * 0.8 + k5) * 2.0, 0.0), Vector2(5.0, 1.0)), Color(0.85, 1.0, 1.0, 0.5))
							continue
						draw_rect(r, Color(0.08, 0.26, 0.12, 0.55))
						for k2 in 40:
							draw_rect(Rect2(r.position.x + _h(ri * 11 + k2, 3) * (r.size.x - 4.0), r.position.y + _h(ri * 11 + k2, 4) * (r.size.y - 4.0), 4.0, 3.0),
								Color(0.2, 0.5 + 0.2 * _h(k2, 5), 0.22, 0.85))
					"burn":
						if String(hz.get("look", "")) == "plates":
							draw_rect(r, Color(0.16, 0.17, 0.2))
							for sx2 in range(int(r.position.x), int(r.end.x), 8):
								draw_rect(Rect2(sx2, r.position.y, 4.0, 2.0), Color(1.0, 0.82, 0.25))
								draw_rect(Rect2(sx2, r.end.y - 2.0, 4.0, 2.0), Color(1.0, 0.82, 0.25))
							if on:
								draw_rect(r, Color(0.5, 0.9, 1.0, 0.25 + 0.2 * _h(int(_t * 20.0), ri)))
								for k3 in 7:
									var a := r.position + Vector2(_h(int(_t * 12.0) + k3 * 5, ri) * r.size.x, _h(int(_t * 12.0) + k3 * 5, ri + 9) * r.size.y)
									draw_line(a, a + Vector2(_h(k3 + int(_t * 12.0), 3) * 14.0 - 7.0, _h(k3 + int(_t * 12.0), 4) * 10.0 - 5.0), Color(0.8, 0.97, 1.0), 1.0)
								draw_rect(r, Color(0.5, 0.95, 1.0, 0.9), false, 1.5)
							else:
								var p: Array = hz.get("pulse", [1.0, 1.0])
								var left := float(p[0]) + float(p[1]) - fposmod(ht, float(p[0]) + float(p[1]))
								draw_rect(r, Color(1.0, 0.82, 0.25, 0.5 if left > 0.8 else 0.5 + 0.5 * absf(sin(_t * 14.0))), false, 1.0)
						else:
							draw_rect(r, Color(0.16, 0.06, 0.04, 0.85))
							for k4 in 26:
								var ep := r.position + Vector2(_h(ri * 13 + k4, 6) * (r.size.x - 6.0), _h(ri * 13 + k4, 7) * (r.size.y - 4.0))
								draw_rect(Rect2(ep, Vector2(3.0 + _h(k4, 8) * 5.0, 2.0)), Color(1.0, 0.4 + 0.4 * absf(sin(_t * 2.0 + k4)), 0.1, 0.9))
							draw_rect(r, Color(1.0, 0.5, 0.15, 0.5 + 0.3 * sin(_t * 3.0)), false, 1.0)
			for sp in hz.get("spots", []):                         # a vent in the ground
				var v: Vector2 = sp
				draw_rect(Rect2(v.x - 8.0, v.y - 6.0, 16.0, 12.0), Color(0.08, 0.08, 0.1))
				for gl in 4:
					draw_rect(Rect2(v.x - 7.0, v.y - 5.0 + gl * 3.0, 14.0, 1.0), Color(0.4, 0.42, 0.5))
		for dc2 in decor:                                      # (part 9) hairline cracks: over the ice they run through
			if String(dc2["kind"]) == "hair":
				var hp0: Vector2 = dc2["pos"]
				var hpts := PackedVector2Array([hp0])
				for hq in 5:
					hpts.append(hpts[hq] + Vector2.from_angle(float(dc2.get("a", 0.0)) + (_h(int(hp0.x) + hq, 5) - 0.5) * 1.3) * float(dc2["r"]) / 5.0)
				draw_polyline(hpts, Color(0.22, 0.38, 0.66, 0.6), 1.0)
				draw_line(hpts[2], hpts[2] + Vector2.from_angle(float(dc2.get("a", 0.0)) - 1.0) * float(dc2["r"]) * 0.28, Color(0.22, 0.38, 0.66, 0.5), 1.0)
				draw_line(hpts[0] + Vector2(0.0, -1.0), hpts[1] + Vector2(0.0, -1.0), Color(1.0, 1.0, 1.0, 0.55), 1.0)
		# ---- the wall of light round the hologram
		for side in 4:
			var r2: Rect2 = [Rect2(0, 0, w, e), Rect2(0, h - e, w, e), Rect2(0, e, e, h - e * 2.0), Rect2(w - e, e, e, h - e * 2.0)][side]
			draw_rect(r2, Color(0.03, 0.05, 0.12, 0.92))
			var horiz := side < 2
			var n := int((r2.size.x if horiz else r2.size.y) / 16.0)
			for i in n + 1:
				if horiz:
					draw_rect(Rect2(r2.position.x + i * 16.0, r2.position.y, 1.0, r2.size.y), Color(blue, 0.35))
				else:
					draw_rect(Rect2(r2.position.x, r2.position.y + i * 16.0, r2.size.x, 1.0), Color(blue, 0.35))
			for j in 3:
				var o := j * 16.0
				if horiz:
					draw_rect(Rect2(r2.position.x, r2.position.y + o, r2.size.x, 1.0), Color(blue, 0.35))
				else:
					draw_rect(Rect2(r2.position.x + o, r2.position.y, 1.0, r2.size.y), Color(blue, 0.35))
		var inner := Rect2(e, e, w - e * 2.0, h - e * 2.0)
		draw_rect(inner, Color(blue, 0.6 + 0.4 * absf(sin(_t * 1.6))), false, 2.0)
		draw_rect(inner.grow(-3.0), Color(blue, 0.18), false, 4.0)
		for sd in stations:
			var at: Vector2 = sd["at"]
			var cool := float(sd["cool"])
			draw_set_transform(at + Vector2(0.0, -4.0), 0.0, Vector2(1.0, 0.5))
			if cool <= 0.0:
				draw_arc(Vector2.ZERO, 20.0 + 3.0 * sin(_t * 3.0), 0.0, TAU, 32, Color(0.35, 0.95, 1.0, 0.85), 2.0)
				draw_arc(Vector2.ZERO, 12.0, 0.0, TAU, 24, Color(0.35, 0.95, 1.0, 0.35), 5.0)
			else:
				draw_arc(Vector2.ZERO, 20.0, 0.0, TAU, 32, Color(1.0, 0.4, 0.35, 0.5), 2.0)
				draw_arc(Vector2.ZERO, 20.0, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - cool / CD.STATION_COOL), 32, Color(0.35, 0.95, 1.0, 0.9), 2.5)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if boot > 0.0:                                          # the map comes up: the grid still shows through, a line of light runs over it
			for gx in range(int(e), int(w - e) + 1, 16):
				draw_rect(Rect2(gx, e, 1.0, h - e * 2.0), Color(blue, 0.5 * boot))
			for gy in range(int(e), int(h - e) + 1, 16):
				draw_rect(Rect2(e, gy, w - e * 2.0, 1.0), Color(blue, 0.5 * boot))
			var ly := e + (h - e * 2.0) * (1.0 - boot)
			draw_rect(Rect2(e, ly - 3.0, w - e * 2.0, 6.0), Color(0.7, 0.95, 1.0, 0.8 * boot))
			draw_rect(inner, Color(0.85, 0.95, 1.0, 0.35 * boot))
