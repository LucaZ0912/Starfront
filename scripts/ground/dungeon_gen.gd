extends RefCounted
## Package 53 (Luz): a site to explore, generated – two maps.
## OUTSIDE (`build_outside`): the drone's pad on the body's ground; in the north the site rises – for a Precursor ruin
## a facade of rusted iron four rows tall – with ONE entrance in the middle: open, or behind its panel (the cutting
## torch) or its computer (an E-Breach). Fog creeps along the ruin's foot; it spills out when the entrance opens.
## INSIDE (`build_inside`): rooms on a 3 × 3 grid joined by corridors three tiles wide (fights happen here too), the
## walls' faces made wherever a floor has rock above it; the entrance hall at the bottom (the way back out). Roles: guard
## rooms (foes), stores (caches), a control room (the theme's computer), a tablet room, the vault at the top right
## with its approach below: the theme's door in the approach's north wall (its panel beside it, the computer opens it
## too), an air shaft from the room beside the vault as the quiet way; in the vault the relic, guarded (Precursors:
## floating crystals with lightning – the computer or a panel in the vault switches them off). Panels elsewhere may
## be traps (an EMP) or hide a few credits. The theme (data/poi.gd) gives the look, the foes, the cover, the loot.
## 0.7.53.3 (Luz, package 53b): the STRUCTURE comes from the theme and is rolled anew for every site (Mystery-Dungeon-
## like: the grid's size, which cells are rooms and which junctions, the loops, where the things and the cover go);
## sites have LEVELS (`build_inside(body, site, depth)` – ladders and hatches between them; the target on the last);
## a city's way down starts in a back alley (`build_alley`); the sewers have a canal down their tunnels, a flooded
## tunnel to the way down (drained at the pumps) and tripwires across the ways.
## No class_name: preload it.

const PoiData = preload("res://data/poi.gd")
const ExploreNode = preload("res://scripts/ground/explore.gd")
const TILE := GroundMap.TILE
const T := GroundMap.T
const COLS := 3
const ROWS := 3
const CW := 22                         # a grid cell (tiles)
const CH := 17
const CORR := 3                        # corridor width (tiles) – wide enough to fight in


static func _theme(site: Dictionary) -> Dictionary:
	return PoiData.THEMES.get(String(site.get("theme", "precursor")), PoiData.THEMES["precursor"])


static func _palette(m: GroundMap, body: Dictionary, th: Dictionary) -> void:
	m.pal = DeckGen.palette_for_body(body).duplicate()
	for key in ["floor", "floor2", "wall", "wall_top", "trim", "accent"]:
		m.pal[key] = th[key]
	m.pal["frame"] = (th["wall"] as Color).darkened(0.25)
	m.style = String(th.get("style", ""))


# ---------------------------------------------------------------- outside

static func build_outside(body: Dictionary, site: Dictionary, ship_len: float, ship_beam: float) -> GroundMap:
	var th := _theme(site)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(site.get("seed", 53)) + 7
	var m := GroundMap.new()
	_palette(m, body, th)
	m.title = String(site.get("name", "Site"))
	m.hull_top = -60
	var sl := clampi(int(ceil(ship_len / TILE)) + 4, 10, 40)
	var sb := clampi(int(ceil(ship_beam / TILE)) + 4, 7, 20)
	var W := maxi(64, sl + 40)
	var H := maxi(46, sb + 34)
	m.setup(W, H)
	m.fill(0, 0, W, H, T.FLOOR, 13)
	m.fill(0, H - 1, W, 1, T.BLOCK, 13)
	m.fill(0, 0, 1, H, T.BLOCK, 13)
	m.fill(W - 1, 0, 1, H, T.BLOCK, 13)
	# the ruin rising in the north: its mass, its facade four rows tall
	m.fill(0, 0, W, 9, T.CAP)
	m.fill(0, 9, W, 4, T.FACE)
	var gx := W / 2 - 1
	m.fill(gx, 9, 3, 4, T.BLOCK, int(th["room_floor"]))
	# the pad, south-west, with the drone
	var px0 := 4
	var py0 := H - sb - 6
	m.fill(px0, py0, sl, sb, T.FLOOR, 14)
	m.decals.append({"kind": "landing_pad", "x": px0, "y": py0, "w": sl, "h": sb, "col": Color(0.95, 0.8, 0.2), "n": 1})
	m.pad_rects.append(Rect2(Vector2(px0, py0) * TILE, Vector2(sl, sb) * TILE))
	var sc := Vector2(px0 + sl * 0.5, py0 + sb * 0.5)
	m.ship_at = sc * TILE
	var bx := int(sc.x - ship_len / TILE * 0.5) + 1
	var bw := maxi(2, int(ship_len / TILE) - 2)
	var bh := maxi(1, int(ship_beam / TILE) - 1)
	m.fill(bx, int(sc.y - bh * 0.5), bw, bh, T.BLOCK, 14)
	var rx := int(sc.x) - 1
	var ry := int(sc.y + bh * 0.5)
	m.decals.append({"kind": "ramp", "x": rx, "y": ry, "w": 2, "h": 2, "col": Color(1.0, 0.8, 0.25)})
	m.spawn = Vector2(rx + 1.0, ry + 2.6) * TILE
	m.zones.append({"rect": Rect2(Vector2(rx - 0.5, ry) * TILE, Vector2(3, 3.2) * TILE), "kind": "exit", "id": "ship",
		"title": "Up the ramp – take off", "col": Color(0.4, 1.0, 0.6), "sign": Vector2(-100, -100)})
	m.add_object({"kind": "fuel_point", "x": px0 + sl + 1, "y": py0, "w": 2, "h": 1, "rise": 34})
	m.zones.append({"rect": Rect2(Vector2(px0 + sl + 0.4, py0 + 1.0) * TILE, Vector2(3.2, 1.6) * TILE), "kind": "charge", "id": "charge",
		"title": "Supply point – energy, oxygen and ammunition", "col": Color(0.35, 0.95, 1.0), "sign": Vector2(-100, -100)})
	for k in range(0, sl + 1, 4):
		m.lights.append({"pos": Vector2(px0 + k, py0) * TILE, "r": 22.0, "col": Color(1.0, 0.75, 0.3), "a": 0.35})
	# the entrance: open, or behind its panel, or its computer
	var lock: String = ["open", "panel", "computer"][rng.randi() % 3]
	if site.has("gate"):
		lock = String(site["gate"])
	var gate := ExploreNode.add(m, "ruin_gate", Vector2(gx + 1.5, 13) * TILE, {"tiles": [gx, 9, 3, 4], "lock": lock, "seed": rng.randi()})
	var gi := m.explore.find(gate)
	if lock == "panel":
		ExploreNode.add(m, "panel", Vector2(gx + 5.5, 13) * TILE, {"inside": "button", "door": gi, "wall": true, "style": String(th["style"]), "shape": "notched", "seed": rng.randi()})
	elif lock == "computer":
		ExploreNode.add(m, "terminal", Vector2(gx + 6.5, 15.2) * TILE, {"actions": ["door"], "door": gi, "style": String(th["computer"]), "seed": rng.randi()})
	m.zones.append({"rect": Rect2(Vector2(gx, 10.5) * TILE, Vector2(3, 3.4) * TILE), "kind": "dungeon_in", "id": "dungeon_in",
		"title": "Go in", "col": Color(0.7, 0.5, 1.0), "sign": Vector2(-100, -100)})
	m.set_meta("door_front", Vector2(gx + 1.5, 14.6) * TILE)
	# rubble and fallen pieces along the foot of the ruin (cover)
	for i in 16:
		var ox := rng.randi_range(3, W - 6)
		var oy := rng.randi_range(14, 19)
		if absi(ox - gx - 1) < 6:
			continue
		var kind: String = th["props"][rng.randi() % th["props"].size()]
		var ow := 3 if kind == "pillar_fallen" else 2
		var ok := true
		for yy in range(oy - 1, oy + 2):
			for xx in range(ox - 1, ox + ow + 1):
				if not GroundMap.walkable_t(m.t_at(xx, yy)) or m.floor_kind[clampi(yy, 0, H - 1) * W + clampi(xx, 0, W - 1)] == 14:
					ok = false
		if ok:
			var o := {"kind": kind, "x": ox, "y": oy, "w": ow, "h": 1}
			if kind == "rock":
				o["col"] = (th["wall"] as Color).darkened(0.2)
				o["seed"] = rng.randi()
			m.add_object(o)
	m.lights.append({"pos": Vector2(gx + 1.5, 12) * TILE, "r": 50.0, "col": th["light"], "a": 0.3, "flicker": true})
	if bool(th.get("fog", false)):
		m.set_meta("fog", [Rect2(Vector2(0, 12.6) * TILE, Vector2(W, 5.5) * TILE)])
	return m

# ---------------------------------------------------------------- outside: a city's back alley (0.7.53.3)

## 0.7.53.3 (Luz, package 53b): a city's way down – a back alley off the shopping street. On its west side a building
## with the lifts back up to the street (and the rest of the city); in the alley a manhole, its cover pushed aside,
## steam rising, a ladder down into the sewers. Bins, crates, lamps, a neon sign.
static func build_alley(body: Dictionary, site: Dictionary) -> GroundMap:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(site.get("seed", 53)) + 11
	var m := GroundMap.new()
	m.pal = DeckGen.palette_for_body(body).duplicate()
	m.pal["floor"] = Color(0.2, 0.2, 0.23)
	m.pal["floor2"] = Color(0.17, 0.17, 0.2)
	m.pal["wall"] = Color(0.4, 0.33, 0.3)
	m.pal["wall_top"] = Color(0.08, 0.08, 0.1)
	m.pal["trim"] = Color(0.25, 0.25, 0.28)
	m.pal["accent"] = Color(1.0, 0.3, 0.75)
	m.pal["frame"] = Color(0.25, 0.25, 0.28)
	m.style = "alley"
	m.title = String(site.get("name", "Back alley"))
	m.hull_top = -60
	var W := 50
	var H := 18
	m.setup(W, H)
	m.fill(0, 0, W, H, T.FLOOR, 23)
	m.fill(0, 0, W, 3, T.CAP)
	m.fill(0, 3, W, 4, T.FACE)
	m.fill(0, H - 3, W, 3, T.CAP)
	m.fill(0, 7, 1, H - 10, T.BLOCK, 23)
	m.fill(W - 1, 7, 1, H - 10, T.BLOCK, 23)
	# the lift building: its glass lobby front with two lifts
	for lx0 in [3, 7]:
		m.face_deco.append({"kind": "lift", "x": lx0, "y": 6, "w": 2, "col": Color(0.4, 1.0, 0.6)})
		m.lifts.append({"x": lx0, "y": 6, "w": 2})
	m.set_meta("lobby", [1, 12])                        # the face drawn as the lift building's front
	m.zones.append({"rect": Rect2(Vector2(3, 7) * TILE, Vector2(6, 1.4) * TILE), "kind": "lift", "id": "lift",
		"title": "Lift – back up to the shopping street", "col": Color(0.4, 1.0, 0.6), "sign": Vector2(6, 4.2) * TILE})
	m.spawn = Vector2(6.0, 8.6) * TILE
	# the manhole: somewhere along the alley, its cover pushed aside
	var mx := rng.randi_range(22, W - 10)
	var my := rng.randi_range(9, H - 6)
	ExploreNode.add(m, "manhole", Vector2(mx + 0.5, my + 0.5) * TILE, {"no_zone": true, "seed": rng.randi()})
	m.zones.append({"rect": Rect2(Vector2(mx - 1.0, my - 0.8) * TILE, Vector2(3.0, 2.6) * TILE), "kind": "dungeon_in", "id": "dungeon_in",
		"title": "Climb down into the sewers", "col": Color(0.4, 1.0, 0.5), "sign": Vector2(-100, -100)})
	m.set_meta("door_front", Vector2(mx + 0.5, my + 2.2) * TILE)
	m.lights.append({"pos": Vector2(mx + 0.5, my + 0.5) * TILE, "r": 26.0, "col": Color(0.4, 1.0, 0.5), "a": 0.35, "flicker": true})
	# along the walls: bins, crates, barrels, rubbish; lamps; a neon sign
	var spots: Array = []
	for i in 14:
		var ox := rng.randi_range(13, W - 4)
		var oy: int = [7, 7, 7, H - 5][rng.randi() % 4]
		var kind: String = ["trash", "crates", "barrel", "crates", "trash"][rng.randi() % 5]
		var ow := 2
		if absi(ox - mx) < 4 or spots.any(func(sp): return absi(int(sp) - ox) < 3 and oy == 7):
			continue
		if oy == 7:
			spots.append(ox)
		m.add_object({"kind": kind, "x": ox, "y": oy, "w": ow, "h": 1})
	for lx in range(14, W - 2, 12):
		m.lights.append({"pos": Vector2(lx, 7.2) * TILE, "r": 60.0, "col": Color(1.0, 0.85, 0.6), "a": 0.35})
	var nx := rng.randi_range(16, W - 12)
	m.face_deco.append({"kind": "neon", "x": nx, "y": 4, "w": 5, "col": [Color(1.0, 0.3, 0.75), Color(0.3, 0.9, 1.0), Color(1.0, 0.8, 0.3)][rng.randi() % 3],
		"text": ["RAMEN", "BAR", "NOODLE", "PAWN", "REPAIR"][rng.randi() % 5]})
	m.lights.append({"pos": Vector2(nx + 2.5, 7.5) * TILE, "r": 90.0, "col": Color(1.0, 0.3, 0.75), "a": 0.4})
	return m


# ---------------------------------------------------------------- inside

## A site's level `depth` (0 the top), rolled from the theme's structure (data/poi.gd): a grid of cells, some rooms,
## the rest junctions where the ways cross; ways `corr` tiles wide (with a canal down their middle in the sewers);
## a spanning tree from the entrance and a loop or two more. The last level holds the target behind the theme's door
## (the vault above its approach); a level above it holds the way down at its far end (in the sewers: behind a
## flooded tunnel – a valve wheel or the pump control drains it).
static func build_inside(body: Dictionary, site: Dictionary, depth: int = 0) -> GroundMap:
	var theme := String(site.get("theme", "precursor"))
	var th: Dictionary = PoiData.layer(theme, depth)
	var nlev := PoiData.levels(theme)
	var last := depth >= nlev - 1
	var dg: Dictionary = PoiData.DANGER.get(String(site.get("danger", "yellow")), PoiData.DANGER["yellow"])
	var rng := RandomNumberGenerator.new()
	rng.seed = int(site.get("seed", 53)) + depth * 1013
	var m := GroundMap.new()
	_palette(m, body, th)
	m.title = String(site.get("name", "Site"))
	m.hull_top = -60
	var cols := rng.randi_range(int(th["cols"][0]), int(th["cols"][1]))
	var rows := rng.randi_range(int(th["rows"][0]), int(th["rows"][1]))
	var cw := int(th["cell_w"])
	var chh := int(th["cell_h"])
	var corr := int(th["corr"])
	var canal := bool(th.get("canal", false))
	var W := cols * cw + 4
	var H := rows * chh + 4
	m.setup(W, H)
	m.fill(0, 0, W, H, T.CAP)
	# ---- the cells: where the entrance, the target or the way down lie; which are rooms
	var entr_c := Vector2i(rng.randi_range(0, cols - 1), rows - 1)
	var far_c := Vector2i(cols - 1 if entr_c.x < cols / 2 else 0, 0)
	var vault_c := far_c
	var appr_c := Vector2i(far_c.x, 1)
	var down_c := far_c
	var need: Array = [entr_c]
	if last:
		need += [vault_c, appr_c]
	else:
		need.append(down_c)
	var cells: Array = []
	for cy in rows:
		for cx in cols:
			cells.append(Vector2i(cx, cy))
	# the roles that want a room – picked first, so a sparse sewer still has them
	var spare: Array = cells.filter(func(c): return not need.has(c))
	_shuffle(spare, rng)
	var control: Vector2i = spare[0]
	var stores: Array = []
	for si in rng.randi_range(int(th.get("stores", [1, 2])[0]), int(th.get("stores", [1, 2])[1])):
		if spare.size() > si + 2:
			stores.append(spare[1 + si])
	var tablet_c := Vector2i(-1, -1)
	if int(th.get("tablets", 0)) > 0 and spare.size() > 3 and last:
		tablet_c = spare[3]
	need.append(control)
	need += stores
	if tablet_c.x >= 0:
		need.append(tablet_c)
	var rooms := {}                                     # cell -> Rect2i (rooms and junctions alike)
	var is_room := {}
	for c in cells:
		var room: bool = need.has(c) or rng.randf() < float(th["room_chance"])
		var r: Rect2i
		if room:
			var w := rng.randi_range(int(th["room_w"][0]), mini(int(th["room_w"][1]), cw - 3))
			if c == entr_c and (String(th.get("outside", "ruin")) == "alley" or depth > 0):
				w = mini(maxi(w, corr + 8), cw - 3)          # room for the ladder beside the way in from above
			var h := rng.randi_range(int(th["room_h"][0]), mini(int(th["room_h"][1]), chh - 5))
			var x: int = 2 + c.x * cw + rng.randi_range(1, maxi(1, cw - w - 1))
			var y: int = 1 + c.y * chh + 3 + rng.randi_range(0, maxi(0, chh - h - 5))
			r = Rect2i(x, y, w, h)
		else:
			var jx: int = 2 + c.x * cw + cw / 2 - corr / 2 + rng.randi_range(-2, 2)
			var jy: int = 1 + c.y * chh + chh / 2 - corr / 2 + rng.randi_range(-1, 1)
			r = Rect2i(jx, jy, corr, corr)
		rooms[c] = r
		is_room[c] = room
	var ap := Rect2i()
	var vr := Rect2i()
	if last:
		ap = rooms[appr_c]
		vr = rooms[vault_c]
		vr.position.x = clampi(ap.position.x + ap.size.x / 2 - vr.size.x / 2, 2 + vault_c.x * cw + 1, mini(W - vr.size.x - 2, 2 + (vault_c.x + 1) * cw - vr.size.x))
		rooms[vault_c] = vr
	var rf := int(th["room_floor"])
	var hf := int(th["hall_floor"])
	for c2 in cells:
		var r2: Rect2i = rooms[c2]
		m.fill(r2.position.x, r2.position.y, r2.size.x, r2.size.y, T.FLOOR, rf if is_room[c2] else hf)
		if canal and not is_room[c2]:
			m.fill(r2.position.x, r2.position.y + 2, r2.size.x, r2.size.y - 4, T.FLOOR, 18)      # the canals meet: a cross
			m.fill(r2.position.x + 2, r2.position.y, r2.size.x - 4, r2.size.y, T.FLOOR, 18)
	# ---- the ways: a spanning tree from the entrance (the vault or the way down left out), a loop or two more
	var tree_cells: Array = cells.filter(func(c3): return c3 != (vault_c if last else down_c))
	var edges: Array = []
	var inn: Array = [entr_c]
	while inn.size() < tree_cells.size():
		var cand: Array = []
		for a in inn:
			for dv in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var b: Vector2i = a + dv
				if tree_cells.has(b) and not inn.has(b):
					cand.append([a, b])
		var pick: Array = cand[rng.randi() % cand.size()]
		edges.append(pick)
		inn.append(pick[1])
	for extra in rng.randi_range(int(th["loops"][0]), int(th["loops"][1])):
		var a2: Vector2i = tree_cells[rng.randi() % tree_cells.size()]
		var b2: Vector2i = a2 + [Vector2i(1, 0), Vector2i(0, 1)][rng.randi() % 2]
		if tree_cells.has(b2) and not edges.any(func(e): return (e[0] == a2 and e[1] == b2) or (e[0] == b2 and e[1] == a2)):
			edges.append([a2, b2])
	for e2 in edges:
		_corridor(m, rooms[e2[0]], rooms[e2[1]], hf, corr, canal)
	# the way to the far cell: on the last level straight up from the approach through the door; above it, a tunnel
	# to the room with the way down (flooded in the sewers)
	var door_gap := Rect2i()
	var dx := 0
	var flood_tiles: Array = []
	if last:
		dx = clampi(ap.position.x + ap.size.x / 2, vr.position.x + 2, vr.end.x - 3)
		m.fill(dx - 1, vr.end.y, CORR, ap.position.y - vr.end.y, T.FLOOR, hf)
		door_gap = Rect2i(dx - 1, ap.position.y - 3, CORR, 3)
	else:
		var nb: Vector2i = Vector2i(down_c.x, down_c.y + 1)
		if not tree_cells.has(nb):
			nb = Vector2i(down_c.x + (1 if down_c.x == 0 else -1), down_c.y)
		var before := {}
		for y0 in H:
			for x0 in W:
				if GroundMap.walkable_t(m.t_at(x0, y0)):
					before[Vector2i(x0, y0)] = true
		_corridor(m, rooms[nb], rooms[down_c], hf, corr, canal)
		if bool(th.get("flood", false)):
			var dr: Rect2i = rooms[down_c]
			for y1 in H:
				for x1 in W:
					var q := Vector2i(x1, y1)
					if GroundMap.walkable_t(m.t_at(x1, y1)) and not before.has(q) and not dr.has_point(q):
						flood_tiles.append([x1, y1, m.floor_kind[y1 * W + x1]])
	_faces(m)
	if last:
		m.fill(door_gap.position.x, door_gap.position.y, door_gap.size.x, door_gap.size.y, T.BLOCK, hf)
	for ft in flood_tiles:
		m.set_t(int(ft[0]), int(ft[1]), T.BLOCK, 20)          # deep water – the pumps drain it
	# bridges over the canal here and there
	if canal:
		for e3 in edges:
			if rng.randf() < 0.6:
				_bridge(m, rooms[e3[0]], rooms[e3[1]], corr)
	# ---- the way in (and out)
	var en: Rect2i = rooms[entr_c]
	var lift_way := String(th.get("descent", "hatch")) == "lift"
	var out_ladder := String(th.get("outside", "ruin")) == "alley" or depth > 0
	if depth > 0 and lift_way:
		# 0.7.53.4 (Luz): you come down on the ancient lift – it takes you back up too
		var lp0 := Vector2(en.position.x + en.size.x * 0.5, en.position.y + 3.2) * TILE
		_ancient_lift(m, lp0, "active", rf)
		m.spawn = lp0 + Vector2(0, 30)
		m.zones.append({"rect": Rect2(lp0 - Vector2(20, 12), Vector2(40, 26)), "kind": "dungeon_up", "id": "dungeon_up",
			"title": "The ancient lift – ride it back up", "col": Color(0.7, 0.5, 1.0), "sign": Vector2(-100, -100)})
	elif out_ladder:
		# a ladder on the entrance room's north wall: up to the street (or the level above)
		var lx := _wall_spot(m, en, en.position.x + en.size.x / 2)
		ExploreNode.add(m, "ladder", Vector2(lx + 0.5, en.position.y) * TILE, {"no_zone": true, "up": true})
		m.spawn = Vector2(lx + 0.5, en.position.y + 1.6) * TILE
		m.zones.append({"rect": Rect2(Vector2(lx - 1.0, en.position.y) * TILE, Vector2(3.0, 1.4) * TILE), "kind": "dungeon_out" if depth == 0 else "dungeon_up",
			"id": "dungeon_out" if depth == 0 else "dungeon_up", "title": "Climb the ladder – back up to the street" if depth == 0 else "Climb the ladder – back up",
			"col": Color(0.4, 1.0, 0.6), "sign": Vector2(-100, -100)})
		m.lights.append({"pos": Vector2(lx + 0.5, en.position.y + 0.5) * TILE, "r": 70.0, "col": Color(0.85, 0.95, 1.0), "a": 0.4})
	else:
		m.spawn = Vector2(en.position.x + en.size.x * 0.5, en.end.y - 1.2) * TILE
		m.zones.append({"rect": Rect2(Vector2(en.position.x + en.size.x * 0.5 - 2, en.end.y - 1.0) * TILE, Vector2(4, 1.0) * TILE), "kind": "dungeon_out",
			"id": "dungeon_out", "title": "Back out into the open", "col": Color(0.4, 1.0, 0.6), "sign": Vector2(-100, -100)})
		m.decals.append({"kind": "stripes", "x": int(en.position.x + en.size.x * 0.5) - 2, "y": en.end.y - 1, "w": 4, "h": 1})
	var lift_i := -1
	if not last and lift_way:
		# 0.7.53.4 (Luz): the way down in the old ruins – an ancient lift; sometimes it sleeps and must be woken
		var drl: Rect2i = rooms[down_c]
		var lp := Vector2(drl.position.x + drl.size.x * 0.5, drl.position.y + drl.size.y * 0.5) * TILE
		var lft := _ancient_lift(m, lp, "dormant" if rng.randf() < 0.55 else "active", rf)
		lift_i = m.explore.find(lft)
		m.zones.append({"rect": Rect2(lp - Vector2(20, 12), Vector2(40, 26)), "kind": "dungeon_down", "id": "dungeon_down",
			"title": "The ancient lift – ride it down", "col": Color(0.7, 0.5, 1.0), "sign": Vector2(-100, -100)})
		m.set_meta("down_front", lp + Vector2(0, 30))
		m.lights.append({"pos": lp, "r": 60.0, "col": th["light"], "a": 0.3, "flicker": true})
	elif not last:
		# the way down: a hatch in the far room's floor
		var drr: Rect2i = rooms[down_c]
		var hp := Vector2(drr.position.x + drr.size.x * 0.5, drr.position.y + drr.size.y * 0.5) * TILE
		ExploreNode.add(m, "hatch", hp, {"no_zone": true, "seed": rng.randi()})
		m.zones.append({"rect": Rect2(hp - Vector2(20, 14), Vector2(40, 30)), "kind": "dungeon_down", "id": "dungeon_down",
			"title": "Climb down – deeper in", "col": Color(1.0, 0.7, 0.35), "sign": Vector2(-100, -100)})
		m.set_meta("down_front", hp + Vector2(0, 26))
		m.lights.append({"pos": hp, "r": 40.0, "col": Color(1.0, 0.7, 0.35), "a": 0.3})
	var style := String(th.get("style", ""))
	var guards: Array = cells.filter(func(c4): return not need.has(c4) or c4 == appr_c)
	var role_of := {entr_c: "entrance", control: "control"}
	if last:
		role_of[vault_c] = "vault"
		role_of[appr_c] = "approach"
	else:
		role_of[down_c] = "down"
	for s2 in stores:
		role_of[s2] = "store"
	if tablet_c.x >= 0:
		role_of[tablet_c] = "tablets"
	# ---- the things
	var di := -1
	var ci := -1
	var targets: Array = []
	var n_cache := 0
	var vent_ok := false
	var cr: Rect2i = rooms[control]
	if last:
		var door := ExploreNode.add(m, String(th.get("door", "blastdoor")), Vector2(dx + 0.5, ap.position.y) * TILE,
			{"tiles": [door_gap.position.x, door_gap.position.y, door_gap.size.x, door_gap.size.y], "seed": rng.randi()})
		di = m.explore.find(door)
		ExploreNode.add(m, "panel", Vector2(dx + 3.5, ap.position.y) * TILE, {"inside": "button", "door": di, "style": style, "seed": rng.randi()})
		var rc := Vector2(vr.position.x + vr.size.x * 0.5, vr.position.y + vr.size.y * 0.5 + 0.4)
		if String(th.get("target", "relic")) == "relic":
			if String(th.get("guard", "")) == "crystals":
				var gt := Rect2i(int(rc.x) - 2, int(rc.y) - 1, 4, 2)
				m.fill(gt.position.x, gt.position.y, gt.size.x, gt.size.y, T.BLOCK, rf)
				var guard := ExploreNode.add(m, "crystals", rc * TILE + Vector2(0, 4), {"tiles": [gt.position.x, gt.position.y, gt.size.x, gt.size.y], "no_zone": true})
				ci = m.explore.find(guard)
				ExploreNode.add(m, "panel", Vector2(vr.position.x + 2.5, vr.position.y) * TILE, {"inside": "button", "effect": "crystals", "cage": ci, "wall": true, "style": style, "seed": rng.randi(), "shape": "round"})
			var relic := {"target": true, "seed": rng.randi(), "no_zone": true}
			if ci >= 0:
				relic["cage"] = ci
			ExploreNode.add(m, "relic", rc * TILE, relic)
			m.lights.append({"pos": rc * TILE, "r": 60.0, "col": th["light"], "a": 0.4, "flicker": true})
			targets.append(["relic", "A relic signature – deep inside, behind an old door%s" % (", guarded by floating crystals" if ci >= 0 else "")])
		else:
			# the dealer's office: the computer with the client list, a rug, a desk, the safe
			m.decals.append({"kind": "rug", "x": int(rc.x) - 3, "y": int(rc.y) - 1, "w": 6, "h": 3, "col": Color(0.55, 0.18, 0.13)})
			ExploreNode.add(m, "terminal", Vector2(rc.x, rc.y - 0.6) * TILE, {"actions": ["list", "door"], "door": di, "target": true, "style": "dealer",
				"seed": rng.randi(), "level": 2 + int(String(site.get("danger", "yellow")) == "red")})
			ExploreNode.add(m, "crate", Vector2(vr.end.x - 2.0, vr.position.y + 1.6) * TILE, {"welded": true, "safe": true, "seed": rng.randi(), "theme": theme})
			n_cache += 1
			m.lights.append({"pos": rc * TILE, "r": 80.0, "col": th["light"], "a": 0.45})
			targets.append(["dealer", "The dealer's computer – the client list, in an office behind a code door"])
		var acts: Array = ["door", "data"]
		if ci >= 0:
			acts = ["door", "crystals", "data"]
		var term := {"actions": acts, "door": di, "seed": rng.randi(), "style": String(th.get("computer", "")), "level": 1 + int(String(site.get("danger", "yellow")) == "red")}
		if ci >= 0:
			term["cage"] = ci
		ExploreNode.add(m, "terminal", Vector2(cr.position.x + cr.size.x - 3, cr.position.y + 1.6) * TILE, term)
	elif lift_i >= 0:
		# 0.7.53.4: their computer wakes the lift; so does a crystal panel somewhere else on the level
		var dormant := String(m.explore[lift_i]["state"]) == "dormant"
		ExploreNode.add(m, "terminal", Vector2(cr.position.x + cr.size.x - 3, cr.position.y + 1.6) * TILE,
			{"actions": ["lift", "data"] if dormant else ["data"], "lift": lift_i, "seed": rng.randi(), "style": String(th.get("computer", "")), "level": 1})
		if dormant:
			var pcs: Array = cells.filter(func(c7): return is_room[c7] and c7 != down_c and c7 != control)
			if not pcs.is_empty():
				var pr: Rect2i = rooms[pcs[rng.randi() % pcs.size()]]
				ExploreNode.add(m, "panel", Vector2(_wall_spot(m, pr, pr.position.x + pr.size.x - 3) + 0.5, pr.position.y) * TILE,
					{"inside": "button", "effect": "lift", "lift": lift_i, "wall": true, "style": style, "seed": rng.randi(), "shape": "round"})
			targets.append(["lift", "An ancient lift down – it sleeps; their computer or a crystal panel wakes it"])
		else:
			targets.append(["lift", "An ancient lift down – awake"])
	else:
		# the pump control drains the flooded way; a valve wheel beside the water does it by hand
		var acts2: Array = ["drain", "data"] if not flood_tiles.is_empty() else ["data"]
		var pt := ExploreNode.add(m, "terminal", Vector2(cr.position.x + cr.size.x - 3, cr.position.y + 1.6) * TILE,
			{"actions": acts2, "seed": rng.randi(), "style": String(th.get("computer", "")), "level": 1, "flood": flood_tiles})
		if not flood_tiles.is_empty():
			ExploreNode.add(m, "valve", Vector2(_wall_spot(m, cr, cr.position.x + 2) + 0.5, cr.position.y) * TILE, {"wall": true, "flood": flood_tiles, "seed": rng.randi()})
			targets.append(["water", "A flooded tunnel to the way down – the pumps drain it"])
	if tablet_c.x >= 0:
		var tr: Rect2i = rooms[tablet_c]
		for ti in int(th.get("tablets", 0)):
			ExploreNode.add(m, "tablet", Vector2(tr.position.x + 2.5 + ti * maxf(2.0, (tr.size.x - 5) / 2.0), tr.position.y + 0.9) * TILE, {"seed": rng.randi()})
		targets.append(["tablets", "%d carved tablets" % int(th.get("tablets", 0))])
	for s3 in stores:
		var sr: Rect2i = rooms[s3]
		for cj in rng.randi_range(2, 3):
			ExploreNode.add(m, "crate", Vector2(sr.position.x + 2.5 + cj * 3, sr.position.y + sr.size.y - 1.5) * TILE, {"welded": cj == 0, "seed": rng.randi(), "theme": theme})
			n_cache += 1
	# traps: panels with an EMP (the Precursors) or tripwires across the ways (the sewers)
	if String(th.get("traps", "")) == "emp":
		for pc in [guards[0] if guards.size() > 1 else control, tablet_c if tablet_c.x >= 0 else control]:
			if not is_room.get(pc, false) or pc == appr_c:
				continue
			var prr: Rect2i = rooms[pc]
			var trap := rng.randf() < 0.55
			ExploreNode.add(m, "panel", Vector2(_wall_spot(m, prr, prr.position.x + 2) + 0.5, prr.position.y) * TILE, {"inside": "button", "effect": "emp" if trap else "cache",
				"trap": trap, "wall": true, "style": style, "seed": rng.randi(), "shape": ["rounded", "hex", "arch"][rng.randi() % 3]})
	elif String(th.get("traps", "")) == "tripwire":
		var placed := 0
		for e4 in edges:
			if placed >= rng.randi_range(2, 3):
				break
			var wire := _wire_spot(m, rooms[e4[0]], rooms[e4[1]], corr)
			if not wire.is_empty():
				var wp: Vector2 = wire["pos"]
				ExploreNode.add(m, "tripwire", wp, {"len": wire["len"], "vertical": wire["vertical"], "seed": rng.randi(), "no_zone": true})
				var wl := float(wire["len"]) * TILE
				var wr := Rect2(wp - Vector2(14, 4), Vector2(28, wl + 4)) if bool(wire["vertical"]) else Rect2(wp - Vector2(4, 14), Vector2(wl + 4, 28))
				m.zones.append({"rect": wr, "kind": "explore", "id": "explore", "i": m.explore.size() - 1, "title": "A tripwire – disarm it (E)"})
				placed += 1
	# the air shaft from the room beside the vault (the Precursors)
	if last and bool(th.get("vent", true)) and String(th.get("target", "relic")) == "relic":
		var side_c := Vector2i(vault_c.x + (-1 if vault_c.x > 0 else 1), 0)
		if rooms.has(side_c) and is_room.get(side_c, false):
			var sr2: Rect2i = rooms[side_c]
			var vx := sr2.end.x - 3 if side_c.x < vault_c.x else sr2.position.x + 2
			var yd := mini(sr2.position.y, vr.position.y) - 3
			var tx := vr.position.x + 1 if side_c.x < vault_c.x else vr.end.x - 2
			var duct: Array = []
			for yy in range(sr2.position.y - 1, yd - 1, -1):
				duct.append([vx, yy])
			var stp := 1 if tx > vx else -1
			for xx in range(vx + stp, tx + stp, stp):
				duct.append([xx, yd])
			for yy2 in range(yd + 1, vr.position.y):
				duct.append([tx, yy2])
			var clear := yd >= 1
			for dc in duct:
				var tt := m.t_at(int(dc[0]), int(dc[1]))
				if GroundMap.walkable_t(tt) or tt == T.BLOCK:
					clear = false
			if clear:
				for dc2 in duct:
					m.set_t(int(dc2[0]), int(dc2[1]), m.t_at(int(dc2[0]), int(dc2[1])), 16)
				var vent := ExploreNode.add(m, "vent", Vector2(vx + 0.5, sr2.position.y) * TILE, {"duct": duct, "label": "VENT-%02d" % rng.randi_range(10, 99), "seed": rng.randi()})
				ExploreNode.add(m, "vent_end", Vector2(tx + (1 if stp > 0 else 0), vr.position.y) * TILE, {"no_zone": true, "vent": m.explore.find(vent)})
				vent_ok = true
	# ---- foes: in the guard rooms and – in the tunnels – at the junctions
	var foes: Array = []
	var tiers: Array = dg["tiers"]
	for gc in guards:
		var gr: Rect2i = rooms[gc]
		var n_g := rng.randi_range(int(dg["guards"][0]), int(dg["guards"][1]))
		if not is_room.get(gc, false):
			n_g = rng.randi_range(0, 2)
		for gi in n_g:
			if foes.size() >= int(dg.get("cap", 12)):
				break                                           # 0.7.53.4: a level holds only so many
			var p := (Vector2(gr.position.x + 1 + rng.randf() * maxf(1.0, gr.size.x - 2), gr.position.y + 1.2 + rng.randf() * maxf(0.5, gr.size.y - 2.4))) * TILE
			if m.free_at(p, 6.0) and m.floor_kind[int(p.y / TILE) * W + int(p.x / TILE)] != 18:
				m.foe_spawns.append(p)
				foes.append("%s@%s" % [String(th["foes"][rng.randi() % th["foes"].size()]), String(tiers[rng.randi() % tiers.size()])])
	if last:
		var lp := Vector2(dx + 0.5, ap.position.y + 3.0) * TILE
		if m.free_at(lp, 6.0):
			m.foe_spawns.append(lp)
			foes.append("%s@%s" % [String(th["leader"]), String(dg["leader"])])
	m.set_meta("foes", foes)
	# ---- cover (0.7.53.3, Luz: more of it – to go about it tactically) and lights
	for c5 in cells:
		var rr: Rect2i = rooms[c5]
		if is_room[c5]:
			m.lights.append({"pos": Vector2(rr.position.x + rr.size.x * 0.5, rr.position.y + 1) * TILE, "r": 50.0, "col": th["light"], "a": 0.25})
		if role_of.get(c5, "") in ["vault", "tablets", "store"]:
			continue
		var n_c := rng.randi_range(int(th["cover"][0]), int(th["cover"][1]))
		if not is_room[c5]:
			n_c = 1
		_scatter_cover(m, th, rng, Rect2i(rr.position.x - (2 if not is_room[c5] else 0), rr.position.y, rr.size.x + (4 if not is_room[c5] else 0), rr.size.y), n_c, role_of.get(c5, "") == "entrance")
	# cover along the long ways too
	for e5 in edges:
		if rng.randf() < 0.7:
			var ra: Rect2i = rooms[e5[0]]
			var rb: Rect2i = rooms[e5[1]]
			var mid := (ra.get_center() + rb.get_center()) / 2
			_scatter_cover(m, th, rng, Rect2i(mid.x - 4, mid.y - corr / 2, 8, corr), 1, false)
	if bool(th.get("fog", false)):
		var fr: Array = []
		for c6 in cells:
			if is_room[c6]:
				var r6: Rect2i = rooms[c6]
				fr.append(Rect2(Vector2(r6.position.x, r6.position.y + 1) * TILE, Vector2(r6.size.x, r6.size.y - 1.6) * TILE))
		m.set_meta("fog", fr)
	if th.has("dark"):
		m.set_meta("dark", th["dark"])
	targets.append(["caches", "%d supply caches, one welded shut" % n_cache if n_cache > 0 else "No caches on this level"])
	if last and String(th.get("target", "relic")) == "relic":
		targets.append(["core", "Their computer in a control room"])
	targets.append(["foes", "%d hostiles here%s" % [foes.size(), " – a leader by the inner door" if last else ""]])
	m.set_meta("poi", {"name": String(site.get("name", "")), "theme": theme, "theme_name": String(th["name"]), "levels": nlev, "minutes": 15 + 8 * (nlev - 1),
		"danger": String(site.get("danger", "yellow")), "danger_name": String(dg["name"]), "depth": depth, "targets": targets, "vent": vent_ok})
	return m


## The targets of a whole site (all its levels) for the window outside.
static func site_targets(maps: Array) -> Array:
	var out: Array = []
	var n_foes := 0
	var n_cache := 0
	for mp in maps:
		for tg in (mp as GroundMap).get_meta("poi")["targets"]:
			match String(tg[0]):
				"foes":
					n_foes += ((mp as GroundMap).get_meta("foes", []) as Array).size()
				"caches":
					n_cache += (mp as GroundMap).explore.filter(func(d): return String(d["kind"]) == "crate").size()
				_:
					out.append(tg)
	out.append(["caches", "%d supply caches, some welded shut" % n_cache])
	out.append(["foes", "%d hostiles – and a leader by the inner door" % n_foes])
	return out


## 0.7.53.4 (Luz): the Precursors' ancient lift – a round platform in a ring of glyphs, two obelisks with crystals
## beside it (they stand in the way), a console before it. "dormant" (wake it first) or "active".
static func _ancient_lift(m: GroundMap, p: Vector2, state: String, fk: int) -> Dictionary:
	var tx := int(p.x / TILE)
	var ty := int(p.y / TILE)
	for sx in [-2, 2]:
		m.set_t(tx + sx, ty, T.BLOCK, fk)
	return ExploreNode.add(m, "ancient_lift", p, {"no_zone": true, "state": state})


## A spot on a room's north wall (a whole face above it, not a way out), as near `want` as there is.
static func _wall_spot(m: GroundMap, r: Rect2i, want: int) -> int:
	var best := want
	var bd := 999
	for x in range(r.position.x + 1, r.end.x - 1):
		var ok := true
		for dx in [-1, 0, 1]:
			if m.t_at(x + dx, r.position.y - 1) != T.FACE:
				ok = false
		if ok and absi(x - want) < bd:
			bd = absi(x - want)
			best = x
	return best


static func _shuffle(a: Array, rng: RandomNumberGenerator) -> void:
	for i in a.size():
		var j := rng.randi() % a.size()
		var tmp = a[i]
		a[i] = a[j]
		a[j] = tmp


## Cover in a rect: the theme's props, kept clear of the walls, the things and each other.
static func _scatter_cover(m: GroundMap, th: Dictionary, rng: RandomNumberGenerator, rr: Rect2i, n: int, entrance: bool) -> void:
	var placed := 0
	for tries in n * 6:
		if placed >= n:
			return
		var kind: String = th["props"][rng.randi() % th["props"].size()]
		var ow := 3 if kind in ["pillar_fallen", "pipe_bundle"] else 2
		var ox := rng.randi_range(rr.position.x + 1, maxi(rr.position.x + 1, rr.end.x - 1 - ow))
		var oy := rng.randi_range(rr.position.y + 2, maxi(rr.position.y + 2, rr.end.y - 2))
		var ok := true
		for yy3 in range(oy - 1, oy + 2):
			for xx3 in range(ox - 1, ox + ow + 1):
				if not GroundMap.walkable_t(m.t_at(xx3, yy3)) or m.floor_kind[clampi(yy3, 0, m.h - 1) * m.w + clampi(xx3, 0, m.w - 1)] == 18:
					ok = false
		var cp := Vector2(ox + ow * 0.5, oy) * TILE
		for d0 in m.explore:
			if (d0["pos"] as Vector2).distance_to(cp) < 44.0:
				ok = false
		if entrance and cp.distance_to(m.spawn) < 56.0:
			ok = false
		for z in m.zones:
			if (z["rect"] as Rect2).grow(10).has_point(cp):
				ok = false
		if not ok:
			continue
		var o := {"kind": kind, "x": ox, "y": oy, "w": ow, "h": 1}
		if kind == "rock":
			o["col"] = (th["wall"] as Color).darkened(0.2)
			o["seed"] = rng.randi()
		m.add_object(o)
		placed += 1


## A way between two cells: along from the first's middle, then up or down to the second's – `corr` tiles wide;
## with a canal, its middle tiles are water (wadeable) and its edges walkways.
static func _corridor(m: GroundMap, a: Rect2i, b: Rect2i, fk: int, corr: int = CORR, canal: bool = false) -> void:
	var ca := a.position + a.size / 2
	var cb := b.position + b.size / 2
	var lo := -corr / 2
	for x in range(mini(ca.x, cb.x) - corr / 2, maxi(ca.x, cb.x) + corr / 2 + 1):
		for k in corr:
			var y := ca.y + lo + k
			if not GroundMap.walkable_t(m.t_at(x, y)):
				m.set_t(x, y, T.FLOOR, 18 if canal and k >= 2 and k < corr - 2 else fk)
	for y2 in range(mini(ca.y, cb.y) - corr / 2, maxi(ca.y, cb.y) + corr / 2 + 1):
		for k2 in corr:
			var x2 := cb.x + lo + k2
			if not GroundMap.walkable_t(m.t_at(x2, y2)):
				m.set_t(x2, y2, T.FLOOR, 18 if canal and k2 >= 2 and k2 < corr - 2 else fk)


## A bridge of grating across a canal: three tiles of walkway over the water, half-way along a way.
static func _bridge(m: GroundMap, a: Rect2i, b: Rect2i, corr: int) -> void:
	var ca := a.position + a.size / 2
	var cb := b.position + b.size / 2
	if absi(ca.x - cb.x) > 8:
		var bx := (ca.x + cb.x) / 2
		for x in range(bx - 1, bx + 2):
			for k in corr:
				var y := ca.y - corr / 2 + k
				if m.t_at(x, y) == T.FLOOR and m.floor_kind[y * m.w + x] == 18:
					m.set_t(x, y, T.FLOOR, 19)


## Where a tripwire may go across a way: a run of `corr` walkable tiles across it, half-way along ({} none).
static func _wire_spot(m: GroundMap, a: Rect2i, b: Rect2i, corr: int) -> Dictionary:
	var ca := a.position + a.size / 2
	var cb := b.position + b.size / 2
	if absi(ca.x - cb.x) >= 8:
		var x := (ca.x + cb.x) / 2
		var y0 := ca.y - corr / 2
		for k in corr:
			if not GroundMap.walkable_t(m.t_at(x, y0 + k)):
				return {}
		if GroundMap.walkable_t(m.t_at(x, y0 - 1)):
			return {}
		return {"pos": Vector2(x + 0.5, y0) * TILE, "len": corr, "vertical": true}
	if absi(ca.y - cb.y) >= 8:
		var y := (ca.y + cb.y) / 2
		var x0 := cb.x - corr / 2
		for k2 in corr:
			if not GroundMap.walkable_t(m.t_at(x0 + k2, y)):
				return {}
		return {"pos": Vector2(x0, y + 0.5) * TILE, "len": corr, "vertical": false}
	return {}


## The walls' faces: where a floor has rock right above it, the two rock rows above become the wall's face.
static func _faces(m: GroundMap) -> void:
	var marks: Array = []
	for y in range(2, m.h):
		for x in m.w:
			if GroundMap.walkable_t(m.t_at(x, y)) and m.t_at(x, y - 1) == T.CAP:
				marks.append(Vector2i(x, y))
	for p in marks:
		for d in [1, 2]:
			if m.t_at(p.x, p.y - d) == T.CAP:
				m.set_t(p.x, p.y - d, T.FACE)
