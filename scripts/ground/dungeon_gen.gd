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

const FoeDataG = preload("res://data/foes.gd")
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
	if th.has("gate_lock"):
		lock = String(th["gate_lock"])
	var gate := ExploreNode.add(m, "ruin_gate", Vector2(gx + 1.5, 13) * TILE, {"tiles": [gx, 9, 3, 4], "lock": lock, "seed": rng.randi(), "style": String(th.get("style", ""))})
	var gi := m.explore.find(gate)
	if lock == "symbols":
		# 0.7.53.23 (Luz): the maw opens to its symbols touched in the right order – the monolith near tells it
		var so := _sym_order(rng)
		m.set_meta("sym_order", so)
		ExploreNode.add(m, "symbol_pillar", Vector2(gx + 6.5, 14.2) * TILE, {"door": gi, "order": so, "seed": rng.randi()})
		var mx2 := gx - 10 if gx > 14 else gx + 14
		m.fill(mx2 - 1, 18, 2, 1, T.BLOCK, 13)
		ExploreNode.add(m, "monolith", Vector2(mx2, 19) * TILE, {"seed": rng.randi()})
		m.lights.append({"pos": Vector2(mx2, 18) * TILE, "r": 70.0, "col": Color(0.62, 0.35, 1.0), "a": 0.4, "flicker": true})
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


# ---------------------------------------------------------------- outside: a research station (0.7.53.20)

## 0.7.53.20 (Luz, package 53d): a research station on a harsh world – two white modules on stilts (their roofs seen
## from above, their walls a band of windows), a tube between them, a dome, the radio mast; the airlock of the west
## module (its terminal beside it) and a torn-open module in the east (the breach – open, or a plate to cut); the
## looters' snow crawler, crates; the drone's pad in the south-west.
static func build_station_outside(body: Dictionary, site: Dictionary, ship_len: float, ship_beam: float) -> GroundMap:
	var th := _theme(site)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(site.get("seed", 53)) + 23
	var m := GroundMap.new()
	_palette(m, body, th)
	m.set_meta("roofs", true)
	m.title = String(site.get("name", "Research station"))
	m.hull_top = -60
	var sl := clampi(int(ceil(ship_len / TILE)) + 4, 10, 40)
	var sb := clampi(int(ceil(ship_beam / TILE)) + 4, 7, 20)
	var W := maxi(66, sl + 44)
	var H := maxi(46, sb + 34)
	m.setup(W, H)
	m.fill(0, 0, W, H, T.FLOOR, 13)
	m.fill(0, H - 1, W, 1, T.BLOCK, 13)
	m.fill(0, 0, 1, H, T.BLOCK, 13)
	m.fill(W - 1, 0, 1, H, T.BLOCK, 13)
	m.fill(0, 0, W, 1, T.BLOCK, 13)
	# the west module: roof rows 4–9, its wall four rows (the stilts the last)
	var ax := 6
	var aw := 18
	m.fill(ax, 4, aw, 6, T.CAP)
	m.fill(ax, 10, aw, 4, T.FACE)
	# the tube to the east module
	var bx := ax + aw + 8
	m.fill(ax + aw, 6, 8, 2, T.CAP)
	m.fill(ax + aw, 8, 8, 2, T.FACE)
	# the east module, torn open
	var bw := 18
	m.fill(bx, 3, bw, 6, T.CAP)
	m.fill(bx, 9, bw, 4, T.FACE)
	# the airlock in the west module's wall, its terminal on a post beside it
	var dx := ax + aw / 2
	var lock := ExploreNode.add(m, "airlock", Vector2(dx + 0.5, 14) * TILE, {"no_zone": true, "seed": rng.randi(), "tiles": []})
	var li := m.explore.find(lock)
	ExploreNode.add(m, "terminal", Vector2(dx + 3.5, 15.4) * TILE, {"actions": ["door"], "door": li, "seed": rng.randi(), "level": 1})
	# the breach in the east module's wall: open – or a buckled plate to cut away
	var brx := bx + bw / 2
	var breach := ExploreNode.add(m, "breach", Vector2(brx + 0.5, 13) * TILE, {"no_zone": true, "state": "open" if rng.randf() < 0.45 else "shut", "seed": rng.randi()})
	var bi := m.explore.find(breach)
	m.zones.append({"rect": Rect2(Vector2(brx + 0.5, 13) * TILE + Vector2(-26, -6), Vector2(52, 30)), "kind": "explore", "id": "explore", "i": bi, "title": "A module torn open"})
	for e in [[Vector2(dx + 0.5, 14) * TILE, li, "Through the airlock – inside"], [Vector2(brx + 0.5, 13) * TILE, bi, "Through the torn module – inside"]]:
		m.zones.append({"rect": Rect2((e[0] as Vector2) + Vector2(-20, -4), Vector2(40, 18)), "kind": "dungeon_in", "id": "dungeon_in", "gate": e[1],
			"title": String(e[2]), "col": Color(1.0, 0.45, 0.35), "sign": Vector2(-100, -100)})
	m.set_meta("door_front", Vector2(dx + 0.5, 15.6) * TILE)
	# the dome, the radio mast, the looters' crawler, crates
	m.add_object({"kind": "dome", "x": W - 14, "y": 20, "w": 9, "h": 4})
	m.add_object({"kind": "radio_mast", "x": 2, "y": 16, "w": 2, "h": 1})
	m.lights.append({"pos": Vector2(3, 16) * TILE + Vector2(0, -170), "r": 30.0, "col": Color(1.0, 0.2, 0.15), "a": 0.5, "flicker": true})
	m.add_object({"kind": "crawler", "x": ax + aw + 2, "y": 22, "w": 6, "h": 3})
	for cx in 3:
		m.add_object({"kind": "crates", "x": bx + 3 + cx * 4, "y": 17 + (cx % 2) * 2, "w": 2, "h": 1})
	for wl in range(ax + 2, bx + bw, 6):
		m.lights.append({"pos": Vector2(wl, 12.5) * TILE, "r": 36.0, "col": Color(1.0, 0.85, 0.6), "a": 0.35})
	# the pad, south-west, with the drone
	var px0 := 4
	var py0 := H - sb - 5
	m.fill(px0, py0, sl, sb, T.FLOOR, 14)
	m.decals.append({"kind": "landing_pad", "x": px0, "y": py0, "w": sl, "h": sb, "col": Color(0.95, 0.8, 0.2), "n": 1})
	m.pad_rects.append(Rect2(Vector2(px0, py0) * TILE, Vector2(sl, sb) * TILE))
	var sc := Vector2(px0 + sl * 0.5, py0 + sb * 0.5)
	m.ship_at = sc * TILE
	var sbx := int(sc.x - ship_len / TILE * 0.5) + 1
	var sbw := maxi(2, int(ship_len / TILE) - 2)
	var sbh := maxi(1, int(ship_beam / TILE) - 1)
	m.fill(sbx, int(sc.y - sbh * 0.5), sbw, sbh, T.BLOCK, 14)
	var rx := int(sc.x) - 1
	var ry := int(sc.y + sbh * 0.5)
	m.decals.append({"kind": "ramp", "x": rx, "y": ry, "w": 2, "h": 2, "col": Color(1.0, 0.8, 0.25)})
	m.spawn = Vector2(rx + 1.0, ry + 2.6) * TILE
	m.zones.append({"rect": Rect2(Vector2(rx - 0.5, ry) * TILE, Vector2(3, 3.2) * TILE), "kind": "exit", "id": "ship",
		"title": "Up the ramp – take off", "col": Color(0.4, 1.0, 0.6), "sign": Vector2(-100, -100)})
	m.add_object({"kind": "fuel_point", "x": px0 + sl + 1, "y": py0, "w": 2, "h": 1, "rise": 34})
	m.zones.append({"rect": Rect2(Vector2(px0 + sl + 0.4, py0 + 1.0) * TILE, Vector2(3.2, 1.6) * TILE), "kind": "charge", "id": "charge",
		"title": "Supply point – energy, oxygen and ammunition", "col": Color(0.35, 0.95, 1.0), "sign": Vector2(-100, -100)})
	return m


# ---------------------------------------------------------------- outside: a city's roof plaza (0.7.53.19)

## 0.7.53.19 (Luz, package 53d): up the lift to a roof plaza – open to the sky: the city beyond the railing with its
## towers, the sun, speeders and drones (the tower bar's view); pale paving, planters with trees, benches, lamps, a
## fountain; on the west the lift kiosk; at the east end the office tower of the corporation – its glass front, its
## guarded main doors, and round the side in a loading bay its back door (a keypad – cut it, or hack the terminal).
static func build_plaza(body: Dictionary, site: Dictionary) -> GroundMap:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(site.get("seed", 53)) + 19
	var m := GroundMap.new()
	m.pal = DeckGen.palette_for_body(body).duplicate()
	m.pal["floor"] = Color(0.7, 0.66, 0.6)
	m.pal["floor2"] = Color(0.64, 0.6, 0.55)
	m.pal["wall"] = Color(0.86, 0.87, 0.89)
	m.pal["wall_top"] = Color(0.12, 0.12, 0.15)
	m.pal["trim"] = Color(0.55, 0.57, 0.6)
	m.pal["accent"] = Color(0.95, 0.75, 0.3)
	m.pal["frame"] = Color(0.6, 0.62, 0.66)
	m.style = "plaza"
	m.title = String(site.get("name", "Roof plaza"))
	m.hull_top = -9999
	var W := 62
	var H := 28
	var KX := 10                                      # the kiosk's east edge
	var TX := W - 18                                  # the tower's west edge
	var BX := W - 7                                   # the loading bay (the back door)
	m.setup(W, H)
	m.fill(0, 0, W, H, T.FLOOR, 30)
	m.fill(0, H - 1, W, 1, T.BLOCK, 30)
	m.fill(0, 0, 1, H, T.BLOCK, 30)
	m.fill(W - 1, 0, 1, H, T.BLOCK, 30)
	# the open view north: the city (drawn behind, like the tower bar's window), a glass railing along the edge
	m.fill(KX, 0, TX - KX, 9, T.GLASS)
	m.window_rect = Rect2(KX, 0, TX - KX, 9)
	m.set_meta("open_sky", true)
	m.add_object({"kind": "glass_rail", "x": KX, "y": 9, "w": TX - KX, "h": 1})
	# the lift kiosk on the west
	m.fill(0, 0, KX, 9, T.CAP)
	m.fill(0, 9, KX, 4, T.FACE)
	for lx0 in [2, 6]:
		m.face_deco.append({"kind": "lift", "x": lx0, "y": 12, "w": 2, "col": Color(0.4, 1.0, 0.6)})
		m.lifts.append({"x": lx0, "y": 12, "w": 2})
	m.zones.append({"rect": Rect2(Vector2(2, 13) * TILE, Vector2(6, 1.4) * TILE), "kind": "lift", "id": "lift",
		"title": "Lift – back down into the city", "col": Color(0.4, 1.0, 0.6), "sign": Vector2(5, 10.2) * TILE})
	m.spawn = Vector2(5.0, 14.6) * TILE
	# the office tower at the east end: its roof, its glass front five rows tall
	m.fill(TX, 0, W - TX, 14, T.CAP)
	m.fill(TX, 14, BX - TX, 5, T.FACE)
	m.set_meta("tower_x", TX)
	m.zones.append({"rect": Rect2(), "kind": "label", "id": "corp_sign", "title": String(site.get("name", "Orison Holdings Tower")).replace(" Tower", "").to_upper(),
		"col": Color(0.95, 0.75, 0.3), "sign": Vector2(TX + 5.5, 14.6) * TILE})
	m.face_deco.append({"kind": "lift", "x": TX + 4, "y": 18, "w": 3, "col": Color(0.95, 0.85, 0.6)})       # the main doors (guarded)
	m.lights.append({"pos": Vector2(TX + 5.5, 19.5) * TILE, "r": 70.0, "col": Color(1.0, 0.9, 0.7), "a": 0.45})
	for gx in [TX + 2, TX + 8]:
		var lk := ChibiArt.PilotArt.random_look(rng)
		lk["suit"] = "suit_mil_light"
		lk["livery"] = "corp"
		lk["helmet"] = true
		m.people.append({"pos": Vector2(gx + 0.5, 19.8) * TILE, "dir": 0, "role": "keeper", "look": lk})
	m.zones.append({"rect": Rect2(Vector2(TX + 3, 19) * TILE, Vector2(5, 1.4) * TILE), "kind": "soon", "id": "front_doors",
		"title": "The main doors – staff only, guarded. Round the side there is a back door.", "col": Color(1.0, 0.8, 0.4), "sign": Vector2(-100, -100)})
	# the loading bay round the side: set back, its back door, a keypad, bins and crates
	m.fill(BX, 0, W - 1 - BX, 9, T.CAP)
	m.fill(BX, 9, W - 1 - BX, 4, T.FACE)
	m.fill(BX - 1, 9, 1, 10, T.CAP)
	var dxp := BX + 2
	var lock: String = ["panel", "computer"][rng.randi() % 2]
	var door := ExploreNode.add(m, "service_door", Vector2(dxp + 0.5, 13) * TILE, {"no_zone": true, "lock": lock, "seed": rng.randi(), "tiles": []})
	var di := m.explore.find(door)
	if lock == "panel":
		ExploreNode.add(m, "panel", Vector2(dxp + 3.0, 12) * TILE, {"inside": "button", "door": di, "wall": true, "style": "corp", "shape": "rounded", "seed": rng.randi()})
	else:
		ExploreNode.add(m, "terminal", Vector2(dxp + 3.0, 14.4) * TILE, {"actions": ["door"], "door": di, "style": "corp", "seed": rng.randi(), "level": 1})
	m.zones.append({"rect": Rect2(Vector2(dxp - 1, 13) * TILE, Vector2(3, 1.6) * TILE), "kind": "dungeon_in", "id": "dungeon_in", "gate": di,
		"title": "The back door – into the tower", "col": Color(1.0, 0.45, 0.35), "sign": Vector2(-100, -100)})
	m.set_meta("door_front", Vector2(dxp + 0.5, 15.2) * TILE)
	m.zones.append({"rect": Rect2(), "kind": "label", "id": "deliveries", "title": "DELIVERIES", "col": Color(0.9, 0.9, 0.9),
		"sign": Vector2(dxp + 0.5, 9.4) * TILE})
	m.add_object({"kind": "trash", "x": BX, "y": 14, "w": 2, "h": 1})
	m.add_object({"kind": "crates", "x": W - 3, "y": 16, "w": 2, "h": 1})
	m.lights.append({"pos": Vector2(dxp + 0.5, 13.5) * TILE, "r": 40.0, "col": Color(1.0, 0.85, 0.6), "a": 0.4})
	# the plaza: planters with trees, benches, lamps, a fountain in the middle
	var mx := (KX + TX) / 2
	m.add_object({"kind": "fountain", "x": mx - 2, "y": 17, "w": 4, "h": 2})
	m.lights.append({"pos": Vector2(mx, 17.5) * TILE, "r": 80.0, "col": Color(0.4, 0.85, 1.0), "a": 0.4})
	for tp in [Vector2i(KX + 3, 12), Vector2i(TX - 6, 12), Vector2i(KX + 4, 23), Vector2i(TX - 7, 23)]:
		m.add_object({"kind": "planter", "x": tp.x, "y": tp.y, "w": 3, "h": 1, "col": Color(0.78, 0.79, 0.82)})
		m.add_object({"kind": "tree", "x": tp.x, "y": tp.y - 1, "w": 3, "h": 1, "rise": 72})
	for bp in [Vector2i(mx - 7, 20), Vector2i(mx + 4, 20), Vector2i(mx - 3, 13)]:
		m.add_object({"kind": "bench", "x": bp.x, "y": bp.y, "w": 3, "h": 1})
	for lp in [Vector2i(KX + 1, 11), Vector2i(mx - 1, 11), Vector2i(TX - 2, 11), Vector2i(KX + 1, 25), Vector2i(TX - 2, 25)]:
		m.add_object({"kind": "lamp_post", "x": lp.x, "y": lp.y, "w": 1, "h": 1})
		m.lights.append({"pos": Vector2(lp.x + 0.5, lp.y) * TILE, "r": 60.0, "col": Color(1.0, 0.88, 0.65), "a": 0.35})
	# people stroll about
	for wy in [14, 16, 21, 24]:
		for wx in [KX + 6, mx - 5, mx + 5, TX - 4]:
			var wp := Vector2(wx + 0.5, wy + 0.5) * TILE
			if m.free_at(wp, 6.0):
				m.wander.append(wp)
	return m


# ---------------------------------------------------------------- inside

## A site's level `depth` (0 the top), rolled from the theme's structure (data/poi.gd): a grid of cells, some rooms,
## the rest junctions where the ways cross; ways `corr` tiles wide (with a canal down their middle in the sewers);
## a spanning tree from the entrance and a loop or two more. The last level holds the target behind the theme's door
## (the vault above its approach); a level above it holds the way down at its far end (in the sewers: behind a
## flooded tunnel – a valve wheel or the pump control drains it).
## 53f (Luz): a foe for a place – now and then (the theme's `creatures` share) one of its creatures instead of a person.
static func _foe_pick(th: Dictionary, rng: RandomNumberGenerator) -> String:
	var cr: Dictionary = th.get("creatures", {})
	if not (cr.get("kinds", []) as Array).is_empty() and rng.randf() < float(cr.get("share", 0.0)):
		return String(cr["kinds"][rng.randi() % cr["kinds"].size()])
	return String(th["foes"][rng.randi() % th["foes"].size()])


static func build_inside(body: Dictionary, site: Dictionary, depth: int = 0) -> GroundMap:
	var theme := String(site.get("theme", "precursor"))
	var th: Dictionary = PoiData.layer(theme, depth)
	if bool(site.get("pest", false)):
		# 53f (Luz): a rat plague – sewers on every level, rats everywhere, their brood mother at the bottom
		th = PoiData.layer(theme, 0).duplicate(true)
		th["foes"] = ["mut_rat"]
		th["leader"] = "rat_brood"
		th["creatures"] = {"kinds": [], "share": 0.0}
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
	var red := String(site.get("danger", "yellow")) == "red"
	if red and not bool(th.get("spine", false)):
		cols += 1                                        # 0.7.53.24 (Luz): a dangerous site is a bigger one
		rows += 1 if rows < 3 else 0
	var cw := int(th["cell_w"])
	var chh := int(th["cell_h"])
	var corr := int(th["corr"])
	var canal := bool(th.get("canal", false))
	var spine := bool(th.get("spine", false))       # 0.7.53.6: a ship – one long main corridor, the cabins off it
	var SP := 9 if spine else 0                      # the spine's band: its wall's face, five tiles of floor, a margin
	var W := cols * cw + 4
	var H := rows * chh + 4 + SP
	m.setup(W, H)
	m.fill(0, 0, W, H, T.CAP)
	# ---- the cells: where the entrance, the target or the way down lie; which are rooms
	var entr_c := Vector2i(rng.randi_range(0, cols - 1), rows - 1)
	var far_c := Vector2i(cols - 1 if entr_c.x < cols / 2 else 0, 0)
	var vault_c := far_c
	var appr_c := Vector2i(far_c.x, 1)
	var down_c := far_c
	if spine:
		appr_c = Vector2i(-9, -9)                    # the spine is its approach
	var need: Array = [entr_c]
	if last:
		need += [vault_c] if spine else [vault_c, appr_c]
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
	for si in rng.randi_range(int(th.get("stores", [1, 2])[0]), int(th.get("stores", [1, 2])[1])) + (1 if red else 0):
		if spare.size() > si + 2:
			stores.append(spare[1 + si])
	var tablet_c := Vector2i(-1, -1)
	if int(th.get("tablets", 0)) > 0 and spare.size() > 3 and last:
		tablet_c = spare[3]
	var hangar_c := Vector2i(-9, -9)
	var cells_c := Vector2i(-9, -9)
	var rescue := String(site.get("goal", "")) == "rescue" and depth == 0
	if rescue and bool(th.get("cells", false)) and spare.size() > stores.size() + 1:
		cells_c = spare[stores.size() + 1]               # 53c: the prisoner's cells come first
		if bool(th.get("hangar", false)) and spare.size() > stores.size() + 2:
			hangar_c = spare[stores.size() + 2]
	else:
		if bool(th.get("hangar", false)) and spare.size() > stores.size() + 2:
			hangar_c = spare[stores.size() + 1]          # 0.7.53.11: the pirates' hangar
		if bool(th.get("cells", false)) and spare.size() > stores.size() + 3:
			cells_c = spare[stores.size() + 2]           # 0.7.53.11: the cells
	need.append(control)
	need += stores
	if hangar_c.x >= 0:
		need.append(hangar_c)
	if cells_c.x >= 0:
		need.append(cells_c)
	if tablet_c.x >= 0:
		need.append(tablet_c)
	var rooms := {}                                     # cell -> Rect2i (rooms and junctions alike)
	var is_room := {}
	for c in cells:
		var room: bool = need.has(c) or rng.randf() < float(th["room_chance"])
		var r: Rect2i
		if room:
			var w := rng.randi_range(int(th["room_w"][0]), mini(int(th["room_w"][1]), cw - 3))
			if last and c == vault_c and String(th.get("target", "")) == "reactor":
				w = mini(maxi(w, 11), cw - 3)                # 0.7.53.9: room round the reactor
			if last and c == vault_c and String(th.get("target", "")) == "dark_relic":
				w = cw - 3                                   # 0.7.53.23: the pit at the bottom
			if c == entr_c and (String(th.get("outside", "ruin")) in ["alley", "lift"] or depth > 0):
				w = mini(maxi(w, corr + 8), cw - 3)          # room for the ladder beside the way in from above
			var h := rng.randi_range(int(th["room_h"][0]), mini(int(th["room_h"][1]), chh - 5))
			if last and c == vault_c and String(th.get("target", "")) == "reactor":
				h = mini(maxi(h, 9), chh - 5)
			if last and c == vault_c and String(th.get("target", "")) == "dark_relic":
				h = chh - 5
			if c == hangar_c:
				w = cw - 3                                   # 0.7.53.11: the hangar as big as its cell allows
				h = chh - 5
			var x: int = 2 + c.x * cw + rng.randi_range(1, maxi(1, cw - w - 1))
			var y: int = 1 + c.y * chh + (SP if c.y >= 1 else 0) + 3 + rng.randi_range(0, maxi(0, chh - h - 5))
			r = Rect2i(x, y, w, h)
		else:
			var jx: int = 2 + c.x * cw + cw / 2 - corr / 2 + rng.randi_range(-2, 2)
			var jy: int = 1 + c.y * chh + (SP if c.y >= 1 else 0) + chh / 2 - corr / 2 + rng.randi_range(-1, 1)
			r = Rect2i(jx, jy, corr, corr)
		rooms[c] = r
		is_room[c] = room
	var ap := Rect2i()
	var vr := Rect2i()
	var targets_pre: Array = []
	var spine_r := Rect2i(2, 1 + chh + 3, W - 4, 5)
	if last and spine:
		ap = spine_r
		vr = rooms[vault_c]
	elif last:
		ap = rooms[appr_c]
		vr = rooms[vault_c]
		vr.position.x = clampi(ap.position.x + ap.size.x / 2 - vr.size.x / 2, 2 + vault_c.x * cw + 1, mini(W - vr.size.x - 2, 2 + (vault_c.x + 1) * cw - vr.size.x))
		rooms[vault_c] = vr
	var rf := int(th["room_floor"])
	var hf := int(th["hall_floor"])
	for c2 in cells:
		var r2: Rect2i = rooms[c2]
		if spine and not is_room[c2]:
			continue
		var rfk := rf
		if is_room[c2] and float(th.get("carpet_share", 0.0)) > 0.0 and c2 != entr_c and rng.randf() < float(th.get("carpet_share", 0.0)):
			rfk = 29                                       # 0.7.53.19: an office – carpet
		if is_room[c2] and bool(th.get("round_rooms", false)) and not (last and c2 == vault_c):
			_fill_round(m, r2, rfk)                       # 0.7.53.23 (Luz): the Dark Ones' round chambers
		else:
			m.fill(r2.position.x, r2.position.y, r2.size.x, r2.size.y, T.FLOOR, rfk if is_room[c2] else hf)
		if canal and not is_room[c2]:
			m.fill(r2.position.x, r2.position.y + 2, r2.size.x, r2.size.y - 4, T.FLOOR, 18)      # the canals meet: a cross
			m.fill(r2.position.x + 2, r2.position.y, r2.size.x - 4, r2.size.y, T.FLOOR, 18)
	# ---- the ways: a spanning tree from the entrance (the vault or the way down left out), a loop or two more
	var tree_cells: Array = cells.filter(func(c3): return c3 != (vault_c if last else down_c))
	var edges: Array = []
	var inn: Array = [entr_c]
	if spine:
		# the main corridor along the hull, each cabin joined to it straight up or down (the vault only by its door)
		m.fill(spine_r.position.x, spine_r.position.y, spine_r.size.x, spine_r.size.y, T.FLOOR, hf)
		for c9 in cells:
			if not is_room[c9] or (last and c9 == vault_c):
				continue
			var r9: Rect2i = rooms[c9]
			var cx9 := r9.position.x + r9.size.x / 2
			var y_a := mini(r9.get_center().y, spine_r.get_center().y)
			var y_b := maxi(r9.get_center().y, spine_r.get_center().y)
			for y9 in range(y_a, y_b + 1):
				for k9 in corr:
					if not GroundMap.walkable_t(m.t_at(cx9 - corr / 2 + k9, y9)):
						m.set_t(cx9 - corr / 2 + k9, y9, T.FLOOR, hf)
		inn = tree_cells.duplicate()                 # (no tree to grow)
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
	for extra in (0 if spine else rng.randi_range(int(th["loops"][0]), int(th["loops"][1]))):
		var a2: Vector2i = tree_cells[rng.randi() % tree_cells.size()]
		var b2: Vector2i = a2 + [Vector2i(1, 0), Vector2i(0, 1)][rng.randi() % 2]
		if tree_cells.has(b2) and not edges.any(func(e): return (e[0] == a2 and e[1] == b2) or (e[0] == b2 and e[1] == a2)):
			edges.append([a2, b2])
	for e2 in edges:
		_corridor(m, rooms[e2[0]], rooms[e2[1]], hf, corr, canal, bool(th.get("rails", false)))
	# the way to the far cell: on the last level straight up from the approach through the door; above it, a tunnel
	# to the room with the way down (flooded in the sewers)
	var door_gap := Rect2i()
	var dx := 0
	var flood_tiles: Array = []
	if last:
		dx = clampi(ap.position.x + ap.size.x / 2, vr.position.x + 2, vr.end.x - 3)
		m.fill(dx - 1, vr.end.y, CORR, ap.position.y - vr.end.y, T.FLOOR, hf)
		door_gap = Rect2i(dx - 1, ap.position.y - 3, CORR, 3)
	elif not spine:
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
	if hangar_c.x >= 0:
		# 0.7.53.11 (Luz): a fighter of the game standing in the hangar – it blocks the floor under it (high cover)
		var hr: Rect2i = rooms[hangar_c]
		var himg: Image = PixelArt.ship_texture("hornet", "pirate").get_image()
		if himg.is_compressed():
			himg.decompress()
		var hsc := minf(hr.size.x * TILE * 0.6 / himg.get_width(), hr.size.y * TILE * 0.5 / himg.get_height())
		var hcen := Vector2(hr.position.x + hr.size.x * 0.5, hr.position.y + hr.size.y * 0.55) * TILE
		for ty in range(hr.position.y, hr.end.y):
			for tx in range(hr.position.x, hr.end.x):
				if parked_covers(himg, hcen, hsc, Vector2(tx + 0.5, ty + 0.5) * TILE):
					m.set_t(tx, ty, T.BLOCK, rf)
		m.set_meta("parked", {"hull": "hornet", "faction": "pirate", "c": hcen, "sc": hsc, "lift": 18})
		m.decals.append({"kind": "stripes", "x": hr.position.x + 1, "y": hr.end.y - 1, "w": hr.size.x - 2, "h": 1})
	var rubble_tiles: Array = []
	var side_room := Rect2i()
	if bool(th.get("rubble", false)):
		# 0.7.53.7 (Luz): a drift buried by a fall – behind it a small chamber with a cache; blast the rubble away
		for c11 in cells:
			if side_room.has_area() or not is_room[c11] or need.has(c11):
				continue
			var r11: Rect2i = rooms[c11]
			for dir in [1, -1]:
				var x0 := r11.end.x if dir == 1 else r11.position.x - 11
				var y0 := r11.position.y + r11.size.y / 2 - 2
				var ok := true
				for yy in range(y0 - 3, y0 + 6):
					for xx in (range(x0, x0 + 12) if dir == 1 else range(x0 - 1, x0 + 11)):
						if m.t_at(xx, yy) != T.CAP:
							ok = false
				if ok:
					var sx := x0 if dir == 1 else x0 + 6
					m.fill(sx, y0 + 1, 5, 3, T.FLOOR, hf)                              # the drift
					side_room = Rect2i(x0 + (5 if dir == 1 else 0), y0, 6, 5)
					m.fill(side_room.position.x, side_room.position.y, side_room.size.x, side_room.size.y, T.FLOOR, rf)
					var rx0 := sx + (1 if dir == 1 else 2)
					for ry in 3:
						for rx in 2:
							rubble_tiles.append([rx0 + rx, y0 + 1 + ry])
					break
			if side_room.has_area():
				break
	# 0.7.53.24 (Luz): a hidden cache – a chamber behind a cracked wall on a level whose tablets or monolith tell of it
	var hid_tiles: Array = []
	var hid_room := Rect2i()
	var hidden_ok := false
	var hints := (last and tablet_c.x >= 0) or String(th.get("computer", "")) == "monolith"
	if hints and not side_room.has_area():
		for c12 in cells:
			if hid_room.has_area() or not is_room[c12] or c12 == entr_c:
				continue
			var r12: Rect2i = rooms[c12]
			for dir2 in [1, -1]:
				var x2 := r12.end.x if dir2 == 1 else r12.position.x - 11
				var y2 := r12.position.y + r12.size.y / 2 - 2
				var ok2 := true
				for yy in range(y2 - 3, y2 + 6):
					for xx in (range(x2, x2 + 12) if dir2 == 1 else range(x2 - 1, x2 + 11)):
						if m.t_at(xx, yy) != T.CAP:
							ok2 = false
				if ok2:
					var sx2 := x2 if dir2 == 1 else x2 + 6
					m.fill(sx2, y2 + 1, 5, 3, T.FLOOR, hf)
					hid_room = Rect2i(x2 + (5 if dir2 == 1 else 0), y2, 6, 5)
					m.fill(hid_room.position.x, hid_room.position.y, hid_room.size.x, hid_room.size.y, T.FLOOR, rf)
					var hx := sx2 if dir2 == 1 else sx2 + 3
					for hy in 3:
						for hxx in 2:
							hid_tiles.append([hx + hxx, y2 + 1 + hy])
					break
	_faces(m)
	for ht in hid_tiles:
		m.set_t(int(ht[0]), int(ht[1]), T.BLOCK, rf)
	if not hid_tiles.is_empty():
		var hw := ExploreNode.add(m, "cracked_wall", Vector2(float(hid_tiles[0][0]) + 1.0, float(hid_tiles[0][1]) + 3.0) * TILE, {"tiles": hid_tiles, "seed": rng.randi(), "no_zone": true})
		m.set_meta("hidden_wall", m.explore.find(hw))
		m.zones.append({"rect": Rect2(Vector2(float(hid_tiles[0][0]) - 1.0, float(hid_tiles[0][1])) * TILE, Vector2(4, 3) * TILE), "kind": "explore", "id": "explore",
			"i": m.explore.find(hw), "title": "A cracked wall – it sounds hollow (a cutting torch gets through)"})
		ExploreNode.add(m, "crate", Vector2(hid_room.position.x + 3, hid_room.position.y + 3.2) * TILE, {"seed": rng.randi(), "theme": theme, "museum": true, "hidden": true})
		hidden_ok = true
	for rt in rubble_tiles:
		m.set_t(int(rt[0]), int(rt[1]), T.BLOCK, hf)
	if not rubble_tiles.is_empty():
		var rc2 := Vector2(float(rubble_tiles[0][0]) + 1.0, float(rubble_tiles[0][1]) + 2.0) * TILE
		ExploreNode.add(m, "rubble", rc2, {"tiles": rubble_tiles, "seed": rng.randi()})
		ExploreNode.add(m, "crate", Vector2(side_room.position.x + 3, side_room.position.y + 3.2) * TILE, {"seed": rng.randi(), "theme": theme, "museum": true})
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
	var lift_way := String(th.get("descent", "hatch")) in ["lift", "cage"]
	var lift_kind := "cage" if String(th.get("descent", "")) == "cage" else "ancient_lift"
	var out_ladder := String(th.get("outside", "ruin")) in ["alley", "lift"] or depth > 0
	if depth > 0 and lift_way:
		# 0.7.53.4 (Luz): you come down on the ancient lift – it takes you back up too
		var lp0 := Vector2(en.position.x + en.size.x * 0.5, en.position.y + 3.2) * TILE
		_ancient_lift(m, lp0, "active", rf, lift_kind)
		m.spawn = lp0 + Vector2(0, 30)
		m.zones.append({"rect": Rect2(lp0 - Vector2(20, 12), Vector2(40, 26)), "kind": "dungeon_up", "id": "dungeon_up",
			"title": "The ancient lift – ride it back up" if lift_kind == "ancient_lift" else "The cage – ride it back up", "col": Color(0.7, 0.5, 1.0), "sign": Vector2(-100, -100)})
	elif out_ladder:
		# a ladder on the entrance room's north wall: up to the street (or the level above)
		var lx := _wall_spot(m, en, en.position.x + en.size.x / 2)
		var up_kind := "ladder"
		if String(th.get("descent", "")) == "stairs":
			up_kind = "stairs_up" if depth > 0 else "service_lift"            # 0.7.53.9: stairwell door, the service lift
		elif String(th.get("descent", "")) == "ramp":
			up_kind = "stairs_up"                                             # 0.7.53.11: the way back up the ramp
		elif String(th.get("descent", "")) == "keylift":
			up_kind = "service_lift"                                          # 0.7.53.19: the tower's lift back up
		elif String(th.get("descent", "")) == "maw":
			up_kind = "spiral_up"                                             # 0.7.53.23: stone steps winding up
		ExploreNode.add(m, up_kind, Vector2(lx + 0.5, en.position.y) * TILE, {"no_zone": true, "up": true})
		m.spawn = Vector2(lx + 0.5, en.position.y + 1.6) * TILE
		m.zones.append({"rect": Rect2(Vector2(lx - 1.0, en.position.y) * TILE, Vector2(3.0, 1.4) * TILE), "kind": "dungeon_out" if depth == 0 else "dungeon_up",
			"id": "dungeon_out" if depth == 0 else "dungeon_up", "title": ("The service lift – back up" if up_kind == "service_lift" else ("Up the stairs" if up_kind == "stairs_up" else ("Climb the ladder – back up to the street" if depth == 0 else "Climb the ladder – back up"))),
			"col": Color(0.4, 1.0, 0.6), "sign": Vector2(-100, -100)})
		m.lights.append({"pos": Vector2(lx + 0.5, en.position.y + 0.5) * TILE, "r": 70.0, "col": Color(0.85, 0.95, 1.0), "a": 0.4})
	else:
		m.spawn = Vector2(en.position.x + en.size.x * 0.5, en.end.y - 1.2) * TILE
		m.zones.append({"rect": Rect2(Vector2(en.position.x + en.size.x * 0.5 - 2, en.end.y - 1.0) * TILE, Vector2(4, 1.0) * TILE), "kind": "dungeon_out",
			"id": "dungeon_out", "title": "The back door – out to the plaza" if theme == "corp" else "Back out into the open", "col": Color(0.4, 1.0, 0.6), "sign": Vector2(-100, -100)})
		m.decals.append({"kind": "stripes", "x": int(en.position.x + en.size.x * 0.5) - 2, "y": en.end.y - 1, "w": 4, "h": 1})
	var lift_i := -1
	if not last and lift_way:
		# 0.7.53.4 (Luz): the way down in the old ruins – an ancient lift; sometimes it sleeps and must be woken
		var drl: Rect2i = rooms[down_c]
		var lp := Vector2(drl.position.x + drl.size.x * 0.5, drl.position.y + drl.size.y * 0.5) * TILE
		var lft := _ancient_lift(m, lp, "dormant" if rng.randf() < 0.55 else "active", rf, lift_kind)
		lift_i = m.explore.find(lft)
		m.zones.append({"rect": Rect2(lp - Vector2(20, 12), Vector2(40, 26)), "kind": "dungeon_down", "id": "dungeon_down",
			"title": "The ancient lift – ride it down" if lift_kind == "ancient_lift" else "The cage – ride it down", "col": Color(0.7, 0.5, 1.0), "sign": Vector2(-100, -100)})
		m.set_meta("down_front", lp + Vector2(0, 30))
		m.lights.append({"pos": lp, "r": 60.0, "col": th["light"], "a": 0.3, "flicker": true})
	elif not last and String(th.get("descent", "")) == "keylift":
		# 0.7.53.19 (Luz): the tower's lift down – it wants a key card; the fire stairs in another room ring the alarm
		var drk: Rect2i = rooms[down_c]
		var kx := _wall_spot(m, drk, drk.position.x + drk.size.x / 2)
		ExploreNode.add(m, "service_lift", Vector2(kx + 0.5, drk.position.y) * TILE, {"no_zone": true, "card": true})
		m.zones.append({"rect": Rect2(Vector2(kx - 1.0, drk.position.y) * TILE, Vector2(3.0, 1.4) * TILE), "kind": "dungeon_down", "id": "dungeon_down",
			"need_card": true, "title": "The lift down – it wants a key card", "col": Color(0.4, 0.85, 1.0), "sign": Vector2(-100, -100)})
		m.set_meta("down_front", Vector2(kx + 0.5, drk.position.y + 1.6) * TILE)
		var fcs: Array = cells.filter(func(cf): return is_room[cf] and not need.has(cf))
		if fcs.is_empty():
			fcs = cells.filter(func(cf2): return is_room[cf2] and cf2 != entr_c and cf2 != down_c)
		if not fcs.is_empty():
			var fr: Rect2i = rooms[fcs[rng.randi() % fcs.size()]]
			var fx := _wall_spot(m, fr, fr.position.x + 2)
			ExploreNode.add(m, "stairs_down", Vector2(fx + 0.5, fr.position.y) * TILE + Vector2(0, 14), {"no_zone": true, "fire": true, "seed": rng.randi()})
			m.zones.append({"rect": Rect2(Vector2(fx - 1.0, fr.position.y) * TILE, Vector2(3.0, 2.0) * TILE), "kind": "dungeon_down", "id": "dungeon_down",
				"fire_door": true, "title": "The fire stairs down – its door is alarmed", "col": Color(1.0, 0.4, 0.3), "sign": Vector2(-100, -100)})
			targets_pre.append(["stairs", "The fire stairs – quick, but their door rings the alarm"])
	elif not last:
		# the way down: a hatch in the far room's floor
		var drr: Rect2i = rooms[down_c]
		var hp := Vector2(drr.position.x + drr.size.x * 0.5, drr.position.y + drr.size.y * 0.5) * TILE
		ExploreNode.add(m, {"hole": "deck_hole", "stairs": "stairs_down", "ramp": "ramp_down", "maw": "maw"}.get(String(th.get("descent", "")), "hatch"), hp, {"no_zone": true, "seed": rng.randi()})
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
	var targets: Array = targets_pre.duplicate()
	if hidden_ok:
		targets.append(["hidden", "Something is hidden on this level – the inscriptions may tell where"])
	if not rubble_tiles.is_empty():
		targets.append(["rubble", "A buried side drift – something was stored behind the fall"])
	var n_cache := 0
	var vent_ok := false
	var cr: Rect2i = rooms[control]
	if last:
		var door := ExploreNode.add(m, String(th.get("door", "blastdoor")), Vector2(dx + 0.5, ap.position.y) * TILE,
			{"tiles": [door_gap.position.x, door_gap.position.y, door_gap.size.x, door_gap.size.y], "seed": rng.randi()})
		di = m.explore.find(door)
		if String(th.get("door", "")) == "crank_door":
			ExploreNode.add(m, "fuse_box", Vector2(dx + 3.5, ap.position.y) * TILE, {"door": di, "wall": true, "seed": rng.randi()})
		elif String(th.get("door", "")) == "membrane":
			# 0.7.53.23 (Luz): the membrane opens to its symbols touched in the right order (a monolith's vision tells it)
			var so := _sym_order(rng)
			m.set_meta("sym_order", so)
			ExploreNode.add(m, "symbol_pillar", Vector2(dx + 4.5, ap.position.y + 1.2) * TILE, {"door": di, "order": so, "seed": rng.randi()})
		elif String(th.get("door", "")) == "vault_door":
			# 0.7.53.19 (Luz): the vault's lock – hacked here, then the drill bites (it takes a while, and it is loud)
			ExploreNode.add(m, "terminal", Vector2(dx + 4.5, ap.position.y + 1.4) * TILE, {"actions": ["vault"], "door": di, "style": "corp", "seed": rng.randi(),
				"level": 2 + int(String(site.get("danger", "yellow")) == "red")})
		else:
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
		elif String(th.get("target", "")) == "loot_room":
			# 0.7.53.11: the captain's hoard – stacked crates of loot, a strongbox
			for lc in 4:
				ExploreNode.add(m, "crate", Vector2(vr.position.x + 2.0 + lc * 2.5, vr.position.y + 1.8) * TILE, {"seed": rng.randi(), "theme": theme, "welded": lc == 0})
			ExploreNode.add(m, "crate", rc * TILE, {"target": true, "safe": true, "welded": true, "seed": rng.randi(), "theme": theme})
			n_cache += 5
			m.lights.append({"pos": rc * TILE, "r": 70.0, "col": Color(1.0, 0.75, 0.3), "a": 0.4})
			targets.append(["loot_room", "The captain's hoard – behind a code door, the command room opens it"])
		elif String(th.get("target", "")) == "dark_relic":
			# 0.7.53.23 (Luz): the bottom – a vast pit across the chamber's back, something sleeping in it; at its edge on
			# an altar the relic
			var pit := Rect2i(vr.position.x + 1, vr.position.y, vr.size.x - 2, maxi(3, vr.size.y / 2))
			m.fill(pit.position.x, pit.position.y, pit.size.x, pit.size.y, T.BLOCK, rf)
			ExploreNode.add(m, "sleeper", Vector2(pit.position.x + pit.size.x * 0.5, pit.end.y) * TILE, {"no_zone": true, "w": pit.size.x, "h": pit.size.y, "seed": rng.randi()})
			var rp := Vector2(rc.x, pit.end.y + 1.8) * TILE
			ExploreNode.add(m, "relic", rp, {"target": true, "seed": rng.randi(), "no_zone": true, "style": "darkones"})
			m.lights.append({"pos": rp, "r": 70.0, "col": th["light"], "a": 0.45, "flicker": true})
			m.lights.append({"pos": Vector2(pit.position.x + pit.size.x * 0.5, pit.position.y + pit.size.y * 0.5) * TILE, "r": 140.0, "col": th["light"], "a": 0.25})
			targets.append(["dark_relic", "A relic of the Dark Ones – at the edge of the pit at the bottom"])
			targets.append(["sleeper", "Something vast sleeps in the pit"])
		elif String(th.get("target", "")) == "research_logs":
			# 0.7.53.20 (Luz): the sample store – the research computer with the station's logs, cabinets of samples
			ExploreNode.add(m, "terminal", Vector2(rc.x, rc.y - 0.6) * TILE, {"actions": ["logs"], "target": true, "seed": rng.randi(), "level": 1 + int(String(site.get("danger", "yellow")) == "red")})
			for sc4 in 3:
				ExploreNode.add(m, "crate", Vector2(vr.position.x + 2.0 + sc4 * 2.6, vr.position.y + 1.8) * TILE, {"seed": rng.randi(), "theme": theme, "welded": sc4 == 0})
			n_cache += 3
			m.lights.append({"pos": rc * TILE, "r": 70.0, "col": Color(0.5, 0.85, 1.0), "a": 0.45})
			targets.append(["research_logs", "The research computer – its logs, in the sample store below"])
		elif String(th.get("target", "")) == "corp_vault":
			# 0.7.53.19 (Luz): the vault – shelves of strongboxes, the main one in the middle
			for lc2 in 5:
				ExploreNode.add(m, "crate", Vector2(vr.position.x + 2.0 + lc2 * 2.4, vr.position.y + 1.8) * TILE, {"seed": rng.randi(), "theme": theme, "safe": lc2 == 2})
			ExploreNode.add(m, "crate", rc * TILE, {"target": true, "safe": true, "welded": true, "seed": rng.randi(), "theme": theme})
			n_cache += 6
			m.lights.append({"pos": rc * TILE, "r": 80.0, "col": Color(0.95, 0.8, 0.45), "a": 0.45})
			targets.append(["corp_vault", "The vault – at the bottom, behind the round door: hack its lock, then the drill"])
		elif String(th.get("target", "")) == "reactor":
			# 0.7.53.9 (Luz): the reactor – its pit in the middle of the room (it stands in the way), its panel before it
			# (0.7.53.9 fix, Luz: the reactor in the room's middle, its panel wholly in the room)
			var rcx := vr.position.x + vr.size.x * 0.5
			var rcy := vr.position.y + vr.size.y * 0.5 - 0.5
			var rt := Rect2i(int(round(rcx - 3.0)), int(round(rcy - 1.5)), 6, 3)
			m.fill(rt.position.x, rt.position.y, rt.size.x, rt.size.y, T.BLOCK, rf)
			ExploreNode.add(m, "reactor", Vector2(rt.position.x + 3.0, rt.position.y + 1.5) * TILE + Vector2(0, 6), {"no_zone": true, "tiles": [rt.position.x, rt.position.y, rt.size.x, rt.size.y]})
			ExploreNode.add(m, "terminal", Vector2(vr.position.x + 2.5, vr.end.y - 0.8) * TILE, {"actions": ["restart"], "target": true, "style": "pump", "seed": rng.randi(), "level": 1})
			targets.append(["reactor", "The reactor – on the lowest level; restart it at its panel"])
		elif String(th.get("target", "")) == "find":
			# 0.7.53.7 (Luz): a rare find in the rock of the deepest chamber – cut it out
			ExploreNode.add(m, "vein", rc * TILE, {"target": true, "seed": rng.randi()})
			m.lights.append({"pos": rc * TILE, "r": 50.0, "col": Color(0.95, 0.85, 0.5), "a": 0.4, "flicker": true})
			targets.append(["find", "Something glitters in the deepest chamber – behind an old gate"])
		elif String(th.get("target", "")) == "blackbox":
			# 0.7.53.6 (Luz): the flight recorder – orange, armoured, bolted into a rack in the ship's core
			ExploreNode.add(m, "blackbox", rc * TILE, {"target": true, "seed": rng.randi()})
			ExploreNode.add(m, "crate", Vector2(vr.end.x - 2.0, vr.position.y + 1.6) * TILE, {"welded": true, "seed": rng.randi(), "theme": theme})
			n_cache += 1
			m.lights.append({"pos": rc * TILE, "r": 60.0, "col": Color(1.0, 0.6, 0.2), "a": 0.45, "flicker": true})
			targets.append(["blackbox", "The flight recorder – on the lower deck, behind a jammed bulkhead"])
		else:
			# the dealer's office: the computer with the client list, a rug, a desk, the safe
			m.decals.append({"kind": "rug", "x": int(rc.x) - 3, "y": int(rc.y) - 1, "w": 6, "h": 3, "col": Color(0.55, 0.18, 0.13)})
			var heist := String(site.get("goal", "")) == "heist"         # 0.7.53.17 (Luz): a heist goes for the safe
			ExploreNode.add(m, "terminal", Vector2(rc.x, rc.y - 0.6) * TILE, {"actions": ["list", "door"], "door": di, "target": not heist, "style": "dealer",
				"seed": rng.randi(), "level": 2 + int(String(site.get("danger", "yellow")) == "red")})
			ExploreNode.add(m, "crate", Vector2(vr.end.x - 2.0, vr.position.y + 1.6) * TILE, {"welded": true, "safe": true, "target": heist, "seed": rng.randi(), "theme": theme})
			n_cache += 1
			m.lights.append({"pos": rc * TILE, "r": 80.0, "col": th["light"], "a": 0.45})
			if heist:
				targets.append(["safe", "The dealer's safe – in his office behind a code door; cut it open"])
			else:
				targets.append(["dealer", "The dealer's computer – the client list, in an office behind a code door"])
		var acts: Array = ["door", "data"]
		if ci >= 0:
			acts = ["door", "crystals", "data"]
		if bool(th.get("turret", false)):
			# 0.7.53.5 (Luz): a turret on the office wall – it covers the door; the control room's computer stops it
			ExploreNode.add(m, "turret", Vector2(_wall_spot(m, vr, vr.end.x - 3) + 0.5, vr.position.y) * TILE, {"no_zone": true, "state": "on", "seed": rng.randi()})
			acts = ["door", "turrets", "data"]
			targets.append(["turret", "A turret guarding the office – its control room can switch it off"])
		if String(th.get("computer", "")) == "ship":
			# 0.7.53.6 (Luz): the emergency generator – route its power to the bulkheads (or the lights)
			ExploreNode.add(m, "generator", Vector2(cr.position.x + cr.size.x - 3, cr.position.y + 1.6) * TILE, {"door": di, "seed": rng.randi()})
			targets.append(["power", "The emergency generator – where its power goes"])
			acts = []
		if String(th.get("target", "")) == "corp_vault":
			acts = ["data"]
		if String(th.get("computer", "")) == "monolith":
			_monolith(m, cr, rng)                         # 0.7.53.23: a monolith – its vision tells the symbols
			targets.append(["monolith", "A monolith – a vision, if you scan it"])
			acts = []
		var term := {"actions": acts, "door": di, "seed": rng.randi(), "style": String(th.get("computer", "")), "level": 1 + int(String(site.get("danger", "yellow")) == "red")}
		if ci >= 0:
			term["cage"] = ci
		if not acts.is_empty():
			ExploreNode.add(m, "terminal", Vector2(cr.position.x + cr.size.x - 3, cr.position.y + 1.6) * TILE, term)
	elif lift_i >= 0 and lift_kind == "cage":
		# 0.7.53.7 (Luz): the cage has no power – start the old generator beside the mine's control
		var dormant2 := String(m.explore[lift_i]["state"]) == "dormant"
		ExploreNode.add(m, "terminal", Vector2(cr.position.x + cr.size.x - 3, cr.position.y + 1.6) * TILE,
			{"actions": ["data"], "seed": rng.randi(), "style": String(th.get("computer", "")), "level": 1})
		if dormant2:
			ExploreNode.add(m, "mine_gen", Vector2(cr.position.x + 3, cr.position.y + 1.8) * TILE, {"lift": lift_i, "seed": rng.randi()})
			targets.append(["cage", "The cage down – no power; the old generator by the control starts it"])
		else:
			targets.append(["cage", "The cage down – it has power"])
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
		if String(th.get("computer", "")) == "monolith":
			_monolith(m, cr, rng)
			targets.append(["monolith", "A monolith – a vision, if you scan it"])
			acts2 = []
		if bool(th.get("security", false)):
			acts2 = ["cameras", "beams", "data"]                  # 0.7.53.19 (Luz): the security centre
			targets.append(["security", "The security centre – cameras and light barriers off, the company's data"])
		if not acts2.is_empty():
			ExploreNode.add(m, "terminal", Vector2(cr.position.x + cr.size.x - 3, cr.position.y + 1.6) * TILE,
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
	elif String(th.get("traps", "")) == "shock" and spine:
		# 0.7.53.6: open conduits sparking across the main corridor; a gas leak in it
		for sk in rng.randi_range(2, 3):
			var sxp := rng.randi_range(spine_r.position.x + 4, spine_r.end.x - 5)
			ExploreNode.add(m, "conduit", Vector2(sxp + 0.5, spine_r.position.y + rng.randi_range(1, 3) + 0.5) * TILE, {"no_zone": true, "seed": rng.randi()})
		var gx := rng.randi_range(spine_r.position.x + 6, spine_r.end.x - 7)
		ExploreNode.add(m, "gas", Vector2(gx + 0.5, spine_r.position.y + 2.5) * TILE, {"no_zone": true, "r": 34.0, "seed": rng.randi()})
	elif String(th.get("traps", "")) == "steam":
		var placed3 := 0
		for e7 in edges:
			if placed3 >= 3:
				break
			var spot3 := _wire_spot(m, rooms[e7[0]], rooms[e7[1]], corr)
			if spot3.is_empty():
				continue
			var sp3: Vector2 = spot3["pos"]
			var mid3: Vector2 = sp3 + (Vector2(0, TILE * 1.5) if bool(spot3["vertical"]) else Vector2(TILE * 1.5, 0))
			ExploreNode.add(m, "steam" if placed3 % 2 == 0 else "conduit", mid3, {"no_zone": true, "seed": rng.randi()})
			placed3 += 1
		# fuse boxes: beside a crank door, a quicker way through it
	elif String(th.get("traps", "")) == "mine":
		var placed2 := 0
		for e6 in edges:
			if placed2 >= 3:
				break
			var spot := _wire_spot(m, rooms[e6[0]], rooms[e6[1]], corr)
			if spot.is_empty():
				continue
			var sp2: Vector2 = spot["pos"]
			var mid2: Vector2 = sp2 + (Vector2(0, TILE * 1.5) if bool(spot["vertical"]) else Vector2(TILE * 1.5, 0))
			match placed2 % 3:
				0:
					ExploreNode.add(m, "loose_rock", mid2, {"no_zone": true, "seed": rng.randi()})
				1:
					ExploreNode.add(m, "gas", mid2, {"no_zone": true, "r": 26.0, "seed": rng.randi()})
				2:
					ExploreNode.add(m, "tripwire", sp2, {"len": spot["len"], "vertical": spot["vertical"], "seed": rng.randi(), "no_zone": true})
					var wl2 := float(spot["len"]) * TILE
					m.zones.append({"rect": Rect2(sp2 - Vector2(14, 4), Vector2(28, wl2 + 4)) if bool(spot["vertical"]) else Rect2(sp2 - Vector2(4, 14), Vector2(wl2 + 4, 28)),
						"kind": "explore", "id": "explore", "i": m.explore.size() - 1, "title": "A tripwire – disarm it (E)"})
			placed2 += 1
		# boxes of explosives against the walls of a few rooms (they go up when something blows up near them)
		var tn := 0
		for c10 in cells:
			if tn >= 3 or not is_room[c10] or role_of.get(c10, "") in ["vault", "entrance"]:
				continue
			var r10: Rect2i = rooms[c10]
			var tp := Vector2(r10.position.x + 1.5 + rng.randi_range(0, r10.size.x - 3), r10.position.y + 0.9) * TILE
			ExploreNode.add(m, "tnt", tp, {"no_zone": true, "seed": rng.randi()})
			tn += 1
	elif String(th.get("traps", "")) == "glyphs":
		# 0.7.53.23 (Luz): glyphs on the floor of the ways – step on one and a wave of force rolls out
		var placed6 := 0
		for e10 in edges:
			if placed6 >= 3:
				break
			var spot6 := _wire_spot(m, rooms[e10[0]], rooms[e10[1]], corr)
			if spot6.is_empty():
				continue
			var sp6: Vector2 = spot6["pos"]
			var mid6: Vector2 = sp6 + (Vector2(0, TILE * 1.5) if bool(spot6["vertical"]) else Vector2(TILE * 1.5, 0))
			ExploreNode.add(m, "glyph_trap", mid6, {"no_zone": true, "seed": rng.randi()})
			placed6 += 1
		if placed6 > 0:
			targets.append(["glyphs", "%d glyphs on the floor of the ways" % placed6])
	elif String(th.get("traps", "")) == "lab":
		var placed5 := 0
		for e9 in edges:
			if placed5 >= 3:
				break
			var spot5 := _wire_spot(m, rooms[e9[0]], rooms[e9[1]], corr)
			if spot5.is_empty():
				continue
			var sp5: Vector2 = spot5["pos"]
			var mid5: Vector2 = sp5 + (Vector2(0, TILE * 1.0) if bool(spot5["vertical"]) else Vector2(TILE * 1.0, 0))
			ExploreNode.add(m, "gas" if placed5 != 1 else "steam", mid5, {"no_zone": true, "r": 24.0, "seed": rng.randi()})
			placed5 += 1
	elif String(th.get("traps", "")) == "beams" and bool(th.get("beams", false)):
		# 0.7.53.19 (Luz): light barriers across the ways to the vault – crossed, they ring the alarm
		var placed4 := 0
		for e8 in edges:
			if placed4 >= 3:
				break
			var bs := _wire_spot(m, rooms[e8[0]], rooms[e8[1]], corr)
			if bs.is_empty():
				continue
			ExploreNode.add(m, "laser_gate", bs["pos"], {"len": bs["len"], "vertical": bs["vertical"], "state": "on", "seed": rng.randi(), "no_zone": true})
			placed4 += 1
		if ap.has_area():
			ExploreNode.add(m, "laser_gate", Vector2(ap.position.x, ap.position.y + ap.size.y * 0.5) * TILE, {"len": ap.size.x, "vertical": false, "state": "on", "seed": rng.randi(), "no_zone": true})
			placed4 += 1
		if placed4 > 0:
			targets.append(["beams", "%d light barriers on the way to the vault" % placed4])
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
	# 0.7.53.20 (Luz): a module or two torn open – the world outside comes in until its emergency bulkhead is sealed
	if bool(th.get("pressurized", false)):
		m.set_meta("pressurized", true)
	if th.has("leaks"):
		var lk_cells: Array = cells.filter(func(cl9): return is_room[cl9] and not role_of.get(cl9, "") in ["vault", "entrance"] and cl9 != cells_c)
		_shuffle(lk_cells, rng)
		var n_lk := rng.randi_range(int(th["leaks"][0]), int(th["leaks"][1]))
		for lkc in lk_cells.slice(0, n_lk):
			var lr: Rect2i = rooms[lkc]
			var lx := _wall_spot(m, lr, lr.position.x + lr.size.x / 2)
			var leak := ExploreNode.add(m, "leak", Vector2(lx + 0.5, lr.position.y) * TILE, {"no_zone": true, "wall": true, "state": "open", "seed": rng.randi(),
				"rect": [lr.position.x, lr.position.y, lr.size.x, lr.size.y]})
			var lki := m.explore.find(leak)
			m.zones.append({"rect": Rect2(Vector2(lr.position) * TILE, Vector2(lr.size) * TILE), "kind": "leak", "id": "leak", "i": lki, "title": ""})
			var sx2 := _wall_spot(m, lr, lr.position.x + 1)
			if absi(sx2 - lx) < 3:
				sx2 = _wall_spot(m, lr, lr.end.x - 2)
			ExploreNode.add(m, "seal_panel", Vector2(sx2 + 0.5, lr.position.y) * TILE, {"wall": true, "leak": lki, "seed": rng.randi()})
			targets.append(["leak", "A module torn open – no air, no warmth, until its bulkhead is sealed"])
	# 0.7.53.19 (Luz): cameras on the rooms' walls, sweeping – seen, the alarm rings; the key card for the lifts
	if th.has("cams"):
		var cam_cells: Array = cells.filter(func(cc9): return is_room[cc9] and role_of.get(cc9, "") != "vault")
		_shuffle(cam_cells, rng)
		var n_cam := rng.randi_range(int(th["cams"][0]), int(th["cams"][1]))
		var made_cam := 0
		for ccm in cam_cells:
			if made_cam >= n_cam:
				break
			var rcm: Rect2i = rooms[ccm]
			var cx2 := _wall_spot(m, rcm, rcm.position.x + (1 if rng.randf() < 0.5 else rcm.size.x - 2))
			var cpm := Vector2(cx2 + 0.5, rcm.position.y) * TILE
			if m.t_at(cx2, rcm.position.y - 1) != T.FACE or m.explore.any(func(d9): return (d9["pos"] as Vector2).distance_to(cpm) < 30.0):
				continue
			var base_a := PI * 0.5 + (0.45 if cx2 < rcm.position.x + rcm.size.x / 2 else -0.45)
			ExploreNode.add(m, "camera", cpm, {"no_zone": true, "wall": true, "state": "on", "base": base_a, "seed": rng.randi()})
			made_cam += 1
		if made_cam > 0:
			targets.append(["cameras", "%d cameras watching the rooms" % made_cam])
	if bool(th.get("keycard", false)):
		var kcs: Array = cells.filter(func(ck): return is_room[ck] and ck != entr_c and ck != down_c and ck != control)
		if kcs.is_empty():
			kcs = [control]
		var kr: Rect2i = rooms[kcs[rng.randi() % kcs.size()]]
		ExploreNode.add(m, "keycard", Vector2(kr.position.x + 1.5 + rng.randf() * maxf(1.0, kr.size.x - 3), kr.position.y + 1.6) * TILE, {"seed": rng.randi()})
		targets.append(["keycard", "A key card for the lifts – somewhere in an office"])
	# 0.7.53.5 (Luz): an alarm box on a guard room's wall – once it rings, the whole level comes for you
	if bool(th.get("alarm", false)):
		var ars: Array = cells.filter(func(c8): return is_room[c8] and role_of.get(c8, "") in ["", "approach"])
		if not ars.is_empty():
			var arr: Rect2i = rooms[ars[rng.randi() % ars.size()]]
			ExploreNode.add(m, "alarm", Vector2(_wall_spot(m, arr, arr.position.x + 3) + 0.5, arr.position.y) * TILE, {"wall": true, "state": "armed", "seed": rng.randi()})
			targets.append(["alarm", "An alarm – cut its box before anyone rings it"])
	if cells_c.x >= 0:
		var clr: Rect2i = rooms[cells_c]
		var cpos := Vector2(clr.position.x + clr.size.x * 0.5, clr.position.y + 2.0) * TILE
		ExploreNode.add(m, "cells", cpos, {"no_zone": true, "w": clr.size.x - 2, "seed": rng.randi(), "prisoner": rescue, "style": String(th.get("style", ""))})
		m.fill(clr.position.x + 1, clr.position.y, clr.size.x - 2, 2, T.BLOCK, rf)
		if rescue:
			# 53c (Luz): the prisoner of a rescue – pick the cell's lock (E)
			m.zones.append({"rect": Rect2(cpos + Vector2(-30, -6), Vector2(60, 22)), "kind": "explore", "id": "explore", "i": m.explore.size() - 1,
				"title": "The cell – pick its lock (E)"})
			targets.append(["cells", "The prisoner – in the cells" if String(th.get("style", "")) != "research" else "The researchers – sealed into a cold store"])
		else:
			targets.append(["cells", "Prisoners in cells – for a rescue, later"] if String(th.get("style", "")) != "research" else ["shelter", "People sealed into a cold store"])
	# ---- foes: in the guard rooms and – in the tunnels – at the junctions
	var foes: Array = []
	var tiers: Array = dg["tiers"]
	var cult := bool(site.get("cult", false)) and th.has("cult_foes")
	if cult:
		th["foes"] = th["cult_foes"]                       # 0.7.53.23 (Luz): a job finds the cult in the ruin
		th["leader"] = th["cult_leader"]
	if (th["foes"] as Array).is_empty():
		guards = []                                         # an empty ruin
	if th.has("patrols"):
		# 0.7.53.22 (Luz): a corporate tower – only one or two guards on a level, walking their rounds from room to room;
		# found out, more of them come up the lift
		var stops: Array = cells.filter(func(cp9): return role_of.get(cp9, "") != "vault" and (cp9 != entr_c or depth > 0))
		var routes := {}
		for pg in rng.randi_range(int(th["patrols"][0]), int(th["patrols"][1])):
			_shuffle(stops, rng)
			var route: Array = []
			for st9 in stops.slice(0, mini(4, stops.size())):
				var r9: Rect2i = rooms[st9]
				var q9 := Vector2(r9.position.x + r9.size.x * 0.5, r9.position.y + r9.size.y * 0.5 + 0.5) * TILE
				if m.free_at(q9, 6.0):
					route.append(q9)
			if route.size() < 2:
				continue
			routes[m.foe_spawns.size()] = route
			m.foe_spawns.append(route[0])
			foes.append("%s@%s" % [_foe_pick(th, rng), String(tiers[rng.randi() % tiers.size()])])
		m.set_meta("routes", routes)
		if bool(th.get("reinforce", false)):
			var kinds: Array = []
			for kn in {"green": 2, "yellow": 3, "red": 4}.get(String(site.get("danger", "yellow")), 3):
				kinds.append("%s@%s" % [_foe_pick(th, rng), String(tiers[rng.randi() % tiers.size()])])
			if last and String(th.get("leader", "")) != "":
				kinds.append("%s@%s" % [String(th["leader"]), String(dg["leader"])])
			m.set_meta("reinforce", {"at": m.get_meta("down_front") if depth == 0 and m.has_meta("down_front") else m.spawn, "kinds": kinds})
		guards = []
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
				var fk := _foe_pick(th, rng)
				foes.append("%s@%s" % [fk, String(tiers[rng.randi() % tiers.size()])])
				for sw in int(FoeDataG.FOES.get(fk, {}).get("swarm", 0)):           # 53f: rats come in swarms
					var sp2 := p + Vector2(rng.randf_range(-14, 14), rng.randf_range(-8, 8))
					if m.free_at(sp2, 4.0):
						m.foe_spawns.append(sp2)
						foes.append("%s@green" % fk)
	if last and String(th.get("leader", "")) != "" and not th.has("patrols"):
		var lp := Vector2(dx + 0.5, ap.position.y + (2.5 if spine else 3.0)) * TILE
		if m.free_at(lp, 6.0):
			m.foe_spawns.append(lp)
			foes.append("%s@%s" % [String(th["leader"]), String(dg["leader"])])
			for sw2 in int(FoeDataG.FOES.get(String(th["leader"]), {}).get("swarm", 0)):     # 53f: the brood mother's brood
				var sp3 := lp + Vector2(rng.randf_range(-20, 20), rng.randf_range(4, 14))
				if m.free_at(sp3, 4.0):
					m.foe_spawns.append(sp3)
					foes.append("mut_rat@%s" % String(tiers[rng.randi() % tiers.size()]))
	m.set_meta("foes", foes)
	if bool(th.get("passive_foes", false)):
		m.set_meta("passive", true)                      # 0.7.53.9: they leave you be – until shot at
	# ---- 0.7.53.16 (Luz): power sockets on the walls of a room or two – hold E beside one and it charges the suit
	var sock_cells: Array = []
	for c7 in cells:
		if is_room[c7] and not role_of.get(c7, "") in ["vault", "tablets"]:
			sock_cells.append(c7)
	_shuffle(sock_cells, rng)
	var n_sock := 0
	for c8 in sock_cells:
		if n_sock >= (2 if sock_cells.size() >= 4 else 1):
			break
		var r8: Rect2i = rooms[c8]
		var sx := _wall_spot(m, r8, r8.position.x + 2 + rng.randi() % maxi(1, r8.size.x - 4))
		var sp := Vector2(sx + 0.5, r8.position.y) * TILE
		if m.t_at(sx, r8.position.y - 1) != T.FACE or m.explore.any(func(d8): return (d8["pos"] as Vector2).distance_to(sp) < 40.0):
			continue
		ExploreNode.add(m, "power_socket", sp, {"no_zone": true, "wall": true, "charge": 260.0, "seed": rng.randi()})
		m.zones.append({"rect": Rect2(sp + Vector2(-16, 0), Vector2(32, 26)), "kind": "socket", "id": "socket", "i": m.explore.size() - 1,
			"title": "Power socket"})
		n_sock += 1
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
	if spine:
		for sg in cols * 2:
			_scatter_cover(m, th, rng, Rect2i(spine_r.position.x + sg * (spine_r.size.x / (cols * 2)), spine_r.position.y, spine_r.size.x / (cols * 2), spine_r.size.y), 1, false)
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
static func _ancient_lift(m: GroundMap, p: Vector2, state: String, fk: int, kind: String = "ancient_lift") -> Dictionary:
	var tx := int(p.x / TILE)
	var ty := int(p.y / TILE)
	for sx in [-2, 2]:
		m.set_t(tx + sx, ty, T.BLOCK, fk)
	return ExploreNode.add(m, kind, p, {"no_zone": true, "state": state})


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


## 0.7.53.23: a round chamber – the floor only inside the ellipse its rect holds.
static func _fill_round(m: GroundMap, r: Rect2i, fk: int) -> void:
	var c := Vector2(r.position.x + r.size.x * 0.5, r.position.y + r.size.y * 0.5)
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var dx := (x + 0.5 - c.x) / (r.size.x * 0.5)
			var dy := (y + 0.5 - c.y) / (r.size.y * 0.5)
			if dx * dx + dy * dy <= 1.08:
				m.set_t(x, y, T.FLOOR, fk)


## 0.7.53.23: four symbols in an order of their own – for a pillar and the monolith that tells it.
static func _monolith(m: GroundMap, r: Rect2i, rng: RandomNumberGenerator) -> void:
	var mp := Vector2i(r.position.x + r.size.x / 2, r.position.y + r.size.y / 2)
	m.fill(mp.x - 1, mp.y, 2, 1, T.BLOCK, m.floor_kind[mp.y * m.w + mp.x])
	ExploreNode.add(m, "monolith", Vector2(mp.x, mp.y + 1) * TILE, {"seed": rng.randi()})
	m.lights.append({"pos": Vector2(mp.x, mp.y) * TILE, "r": 70.0, "col": Color(0.62, 0.35, 1.0), "a": 0.4, "flicker": true})


static func _sym_order(rng: RandomNumberGenerator) -> Array:
	var o := [0, 1, 2, 3]
	_shuffle(o, rng)
	return o


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
		var ow := 3 if kind in ["pillar_fallen", "pipe_bundle", "partition"] else (1 if kind == "pillar_corp" else 2)
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
		elif kind == "sofa":
			o["col"] = Color(0.25, 0.3, 0.42)                    # 0.7.53.19: a lobby's sofa
		elif kind == "planter":
			o["col"] = Color(0.78, 0.79, 0.82)
		m.add_object(o)
		placed += 1


## A way between two cells: along from the first's middle, then up or down to the second's – `corr` tiles wide;
## with a canal, its middle tiles are water (wadeable) and its edges walkways.
static func _corridor(m: GroundMap, a: Rect2i, b: Rect2i, fk: int, corr: int = CORR, canal: bool = false, rails: bool = false) -> void:
	var ca := a.position + a.size / 2
	var cb := b.position + b.size / 2
	var lo := -corr / 2
	for x in range(mini(ca.x, cb.x) - corr / 2, maxi(ca.x, cb.x) + corr / 2 + 1):
		for k in corr:
			var y := ca.y + lo + k
			if not GroundMap.walkable_t(m.t_at(x, y)):
				m.set_t(x, y, T.FLOOR, 18 if canal and k >= 2 and k < corr - 2 else (26 if rails and k == corr / 2 else fk))
	for y2 in range(mini(ca.y, cb.y) - corr / 2, maxi(ca.y, cb.y) + corr / 2 + 1):
		for k2 in corr:
			var x2 := cb.x + lo + k2
			if not GroundMap.walkable_t(m.t_at(x2, y2)):
				m.set_t(x2, y2, T.FLOOR, 18 if canal and k2 >= 2 and k2 < corr - 2 else (27 if rails and k2 == corr / 2 else fk))


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


# ---------------------------------------------------------------- outside: the old mine by a settlement (0.7.53.7)

## 0.7.53.7 (Luz): the old mine at the edge of a settlement – the shaft house with its headframe in the north (its
## gate chained: cut it, or it hangs open), the winding house and an ore bin beside it, tailings heaps behind, rails
## out of the shaft with lorries (one tipped over), barrels, crates, lamps; in the south the path back into town.
static func build_minehead(body: Dictionary, site: Dictionary) -> GroundMap:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(site.get("seed", 53)) + 17
	var m := GroundMap.new()
	m.pal = DeckGen.palette_for_body(body).duplicate()
	m.title = String(site.get("name", "The old mine"))
	m.hull_top = -60
	var W := 54
	var H := 30
	m.setup(W, H)
	m.fill(0, 0, W, H, T.FLOOR, 13)
	m.fill(0, 0, W, 1, T.BLOCK, 13)
	m.fill(0, 0, 1, H, T.BLOCK, 13)
	m.fill(W - 1, 0, 1, H, T.BLOCK, 13)
	m.fill(0, H - 1, W, 1, T.BLOCK, 13)
	# tailings heaps along the north
	for th2 in 7:
		var hx := 2 + th2 * 4 + rng.randi_range(0, 2)
		if hx > 14 and hx < 40:
			continue
		m.add_object({"kind": "heap", "x": hx, "y": rng.randi_range(2, 4), "w": 3, "h": 2, "col": Color(0.5, 0.48, 0.45)})
	# the shaft house and headframe, its gate on the south side
	var sx := W / 2 - 5
	var sy := 6
	m.add_object({"kind": "shaft_house", "x": sx, "y": sy, "w": 10, "h": 3})
	m.fill(sx, sy, 10, 3, T.BLOCK, 13)
	var gp := Vector2(sx + 5, sy + 3) * TILE
	var gate := ExploreNode.add(m, "mine_gate", gp, {"no_zone": true, "state": "open" if rng.randf() < 0.3 else "shut", "seed": rng.randi()})
	var gi := m.explore.find(gate)
	m.zones.append({"rect": Rect2(gp + Vector2(-26, -8), Vector2(52, 30)), "kind": "explore", "id": "explore", "i": gi, "title": "The gate into the shaft"})
	m.zones.append({"rect": Rect2(gp + Vector2(-18, -2), Vector2(36, 16)), "kind": "dungeon_in", "id": "dungeon_in", "gate": gi,
		"title": "Into the old mine", "col": Color(1.0, 0.75, 0.4), "sign": Vector2(-100, -100)})
	m.set_meta("door_front", gp + Vector2(0, 26))
	m.add_object({"kind": "winding_house", "x": sx + 12, "y": sy + 1, "w": 4, "h": 2})
	m.fill(sx + 12, sy + 1, 4, 2, T.BLOCK, 13)
	m.add_object({"kind": "ore_bin", "x": sx + 18, "y": sy, "w": 3, "h": 2})
	# rails out of the shaft east, lorries, one tipped with its ore spilled
	m.decals.append({"kind": "rails", "x": sx + 5, "y": sy + 4, "w": W - sx - 8, "h": 1})
	m.add_object({"kind": "ore_cart", "x": sx + 10, "y": sy + 4, "w": 2, "h": 1})
	m.add_object({"kind": "ore_cart", "x": sx + 18, "y": sy + 4, "w": 2, "h": 1})
	m.add_object({"kind": "heap", "x": sx + 13, "y": sy + 6, "w": 2, "h": 1, "col": Color(0.55, 0.45, 0.3)})
	# barrels, crates, rocks, a lamp or two
	for bi in 3:
		m.add_object({"kind": "barrel", "x": 8 + bi, "y": 12, "w": 1, "h": 1})
	m.add_object({"kind": "crates", "x": 12, "y": 12, "w": 2, "h": 1})
	for rk in 8:
		var rx := rng.randi_range(3, W - 5)
		var ry := rng.randi_range(14, H - 6)
		if GroundMap.walkable_t(m.t_at(rx, ry)) and GroundMap.walkable_t(m.t_at(rx + 1, ry)):
			m.add_object({"kind": "rock", "x": rx, "y": ry, "w": 2, "h": 1, "col": Color(0.45, 0.4, 0.34), "seed": rng.randi()})
	for lp in [Vector2(sx - 4, sy + 6), Vector2(sx + 22, sy + 7), Vector2(18, 20)]:
		m.add_object({"kind": "lamp_post", "x": int(lp.x), "y": int(lp.y), "w": 1, "h": 1})
		m.lights.append({"pos": (lp + Vector2(0.5, 0.5)) * TILE, "r": 70.0, "col": Color(1.0, 0.85, 0.6), "a": 0.35})
	m.lights.append({"pos": gp + Vector2(0, 6), "r": 40.0, "col": Color(1.0, 0.7, 0.4), "a": 0.3})
	for db in 30:
		m.decals.append({"kind": "debris", "x": rng.randi_range(2, W - 3), "y": rng.randi_range(10, H - 3), "w": 1, "h": 1, "seed": rng.randi()})
	# the path back into town, south
	var px := W / 2 - 2
	m.fill(px, H - 1, 4, 1, T.FLOOR, 15)
	for yy in range(H - 8, H):
		m.fill(px, yy, 4, 1, T.FLOOR, 15)
	m.spawn = Vector2(px + 2, H - 3) * TILE
	m.zones.append({"rect": Rect2(Vector2(px, H - 2) * TILE, Vector2(4, 1.6) * TILE), "kind": "town_path", "id": "town_path",
		"title": "The path back into town", "col": Color(0.4, 1.0, 0.6), "sign": Vector2(-100, -100)})
	return m


# ---------------------------------------------------------------- outside: a pirate base in a cliff (0.7.53.11)

## 0.7.53.11 (Luz): a pirate base built into a cliff in the north – a big hangar gate of welded plates under a skull
## banner, a side door with its guard; watchtowers with searchlights sweeping the ground, a scrap fence with a gap,
## gliders parked, fires in barrels, crates of loot. The hangar gate is sealed (hack its terminal); the side door has a
## code lock (cut its box).
static func build_cliff(body: Dictionary, site: Dictionary, ship_len: float, ship_beam: float) -> GroundMap:
	var th := _theme(site)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(site.get("seed", 53)) + 19
	var m := GroundMap.new()
	_palette(m, body, th)
	m.title = String(site.get("name", "Pirate base"))
	m.hull_top = -60
	var sl := clampi(int(ceil(ship_len / TILE)) + 4, 10, 40)
	var sb := clampi(int(ceil(ship_beam / TILE)) + 4, 7, 20)
	var W := maxi(70, sl + 46)
	var H := maxi(44, sb + 32)
	m.setup(W, H)
	m.fill(0, 0, W, H, T.FLOOR, 13)
	m.fill(0, H - 1, W, 1, T.BLOCK, 13)
	m.fill(0, 0, 1, H, T.BLOCK, 13)
	m.fill(W - 1, 0, 1, H, T.BLOCK, 13)
	m.fill(0, 0, W, 6, T.CAP)
	m.fill(0, 6, W, 5, T.FACE)
	# the hangar gate (7 wide) and the side door
	var gx := W / 2 - 4
	m.fill(gx, 6, 7, 5, T.BLOCK, 22)
	var gate := ExploreNode.add(m, "pirate_gate", Vector2(gx + 3.5, 11) * TILE, {"tiles": [gx, 6, 7, 5], "lock": "computer", "seed": rng.randi()})
	var gi := m.explore.find(gate)
	ExploreNode.add(m, "terminal", Vector2(gx + 9.5, 13.0) * TILE, {"actions": ["door"], "door": gi, "style": "", "seed": rng.randi()})
	var sx := gx + 16
	m.fill(sx, 8, 3, 3, T.BLOCK, 22)
	var side := ExploreNode.add(m, "steel_door", Vector2(sx + 1.5, 11) * TILE, {"tiles": [sx, 8, 3, 3], "seed": rng.randi()})
	var si := m.explore.find(side)
	ExploreNode.add(m, "panel", Vector2(sx + 4.5, 11) * TILE, {"inside": "button", "door": si, "style": "hideout", "seed": rng.randi()})
	for e in [[gx, 7, gi, "Through the hangar gate – inside"], [sx, 3, si, "Through the side door – inside"]]:
		m.zones.append({"rect": Rect2(Vector2(int(e[0]), 10.6) * TILE, Vector2(int(e[1]), 1.6) * TILE), "kind": "dungeon_in", "id": "dungeon_in", "gate": e[2],
			"title": String(e[3]), "col": Color(1.0, 0.35, 0.3), "sign": Vector2(-100, -100)})
	m.set_meta("door_front", Vector2(gx + 3.5, 13.2) * TILE)
	m.face_deco.append({"kind": "skull_banner", "x": gx + 2, "y": 6, "w": 3, "col": Color(0.9, 0.2, 0.15)})
	m.face_deco.append({"kind": "graffiti", "x": 4, "y": 8, "w": 8, "col": Color(0.9, 0.3, 0.2)})
	m.face_deco.append({"kind": "graffiti", "x": W - 14, "y": 7, "w": 8, "col": Color(0.3, 0.8, 0.9)})
	# the pad, south-west
	var px0 := 4
	var py0 := H - sb - 5
	m.fill(px0, py0, sl, sb, T.FLOOR, 14)
	m.decals.append({"kind": "landing_pad", "x": px0, "y": py0, "w": sl, "h": sb, "col": Color(0.95, 0.8, 0.2), "n": 1})
	m.pad_rects.append(Rect2(Vector2(px0, py0) * TILE, Vector2(sl, sb) * TILE))
	var sc2 := Vector2(px0 + sl * 0.5, py0 + sb * 0.5)
	m.ship_at = sc2 * TILE
	var bx := int(sc2.x - ship_len / TILE * 0.5) + 1
	var bw := maxi(2, int(ship_len / TILE) - 2)
	var bh := maxi(1, int(ship_beam / TILE) - 1)
	m.fill(bx, int(sc2.y - bh * 0.5), bw, bh, T.BLOCK, 14)
	var rx := int(sc2.x) - 1
	var ry := int(sc2.y + bh * 0.5)
	m.decals.append({"kind": "ramp", "x": rx, "y": ry, "w": 2, "h": 2, "col": Color(1.0, 0.8, 0.25)})
	m.spawn = Vector2(rx + 1.0, ry + 2.6) * TILE
	m.zones.append({"rect": Rect2(Vector2(rx - 0.5, ry) * TILE, Vector2(3, 3.2) * TILE), "kind": "exit", "id": "ship",
		"title": "Up the ramp – take off", "col": Color(0.4, 1.0, 0.6), "sign": Vector2(-100, -100)})
	# the scrap fence between, a gap where the road goes in
	var fy := py0 - 4
	for fx in range(2, W - 2, 2):
		if absi(fx - (gx + 3)) < 4:
			continue
		m.add_object({"kind": "barrier", "x": fx, "y": fy, "w": 2, "h": 1, "col": Color(0.42, 0.38, 0.36)})
	# watchtowers with searchlights, gliders, fires in barrels, crates of loot
	for tw in [Vector2i(gx - 10, 15), Vector2i(gx + 22, 16)]:
		m.add_object({"kind": "watchtower", "x": tw.x, "y": tw.y, "w": 2, "h": 2})
		ExploreNode.add(m, "searchlight", Vector2(tw.x + 1, tw.y + 1) * TILE, {"no_zone": true, "seed": rng.randi(), "ang": rng.randf() * TAU})
	for gl in 2:
		m.add_object({"kind": "glider", "x": gx + 12 + gl * 5, "y": 20, "w": 4, "h": 2})
	for fb in [Vector2i(gx - 3, 14), Vector2i(gx + 10, 15), Vector2i(8, 18)]:
		m.add_object({"kind": "fire_barrel", "x": fb.x, "y": fb.y, "w": 1, "h": 1})
		m.lights.append({"pos": (Vector2(fb) + Vector2(0.5, 0.2)) * TILE, "r": 50.0, "col": Color(1.0, 0.55, 0.2), "a": 0.45, "flicker": true})
	m.add_object({"kind": "crates", "x": 10, "y": 22, "w": 2, "h": 1})
	m.add_object({"kind": "crates", "x": W - 12, "y": 24, "w": 2, "h": 1})
	# guards outside
	var foes: Array = []
	var dg: Dictionary = PoiData.DANGER.get(String(site.get("danger", "yellow")), PoiData.DANGER["yellow"])
	for gp in [Vector2(sx + 1.5, 12.5), Vector2(gx - 9.5, 18.5), Vector2(gx + 14.5, 23.0)]:
		if m.free_at(gp * TILE, 6.0):
			m.foe_spawns.append(gp * TILE)
			foes.append("%s@%s" % [_foe_pick(th, rng), String(dg["tiers"][0])])
	m.set_meta("foes", foes)
	m.lights.append({"pos": Vector2(gx + 3.5, 11) * TILE, "r": 70.0, "col": Color(1.0, 0.3, 0.22), "a": 0.35})
	return m


## 0.7.53.11 (Luz): a ship standing in a hangar – where its picture (at sc, its centre c) covers the ground.
static func parked_covers(img: Image, c: Vector2, sc: float, p: Vector2) -> bool:
	var q := (p - c) / sc + Vector2(img.get_width(), img.get_height()) * 0.5
	if q.x < 0 or q.y < 0 or q.x >= img.get_width() or q.y >= img.get_height():
		return false
	return img.get_pixel(int(q.x), int(q.y)).a > 0.5


# ---------------------------------------------------------------- outside: a crash site (0.7.53.6)

const HullData53 = preload("res://data/hulls.gd")
const ART_PER_M := 15.0                 # the ground's scale: about 15 art px a metre (BuildArt, 0.7.50.13)


## Where a ship's picture ends on its south side at a share f of its length (0 stern, 1 nose), in art px.
static func ship_edge(img: Image, c: Vector2, sc: float, ang: float, f: float) -> Vector2:
	var sw := img.get_width()
	var sh := img.get_height()
	var sx := clampi(int(f * sw), 0, sw - 1)
	var sy := sh - 1
	while sy > 0 and img.get_pixel(sx, sy).a < 0.5:
		sy -= 1
	return c + (Vector2(sx + 0.5, sy + 0.5) * sc - Vector2(sw, sh) * sc * 0.5).rotated(ang)


## Does a piece of the ship (centre c, turned ang, the share [cut) left out) cover the point p (art px)?
static func ship_covers(img: Image, c: Vector2, sc: float, ang: float, cut: Vector2, p: Vector2) -> bool:
	var sw := img.get_width()
	var sh := img.get_height()
	var q := ((p - c).rotated(-ang) + Vector2(sw, sh) * sc * 0.5) / sc
	if q.x < 0 or q.y < 0 or q.x >= sw or q.y >= sh:
		return false
	var f := q.x / sw
	if f >= cut.x and f < cut.y:
		return false
	return img.get_pixel(int(q.x), int(q.y)).a > 0.5


## 0.7.53.6 (Luz): a crash site – a ship of the game come down in the north of the field, at the ground's real scale
## (15 art px a metre: a 92 m freighter is wider than the screen), nose dug into the ground, its stern torn away and
## lying back along the furrow it ploughed. Two ways in on its south flank: a breach (open, or a plate wedged in it –
## cut it) and the emergency airlock (its terminal on a post – hack it). Its cargo strewn about – containers, one
## burst open; fires, smoke, debris, craters; scavengers camped to the east.
static func build_wreck_outside(body: Dictionary, site: Dictionary, ship_len: float, ship_beam: float) -> GroundMap:
	var th := _theme(site)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(site.get("seed", 53)) + 13
	var hull := String(site.get("hull", "freighter"))
	var img: Image = PixelArt.ship_texture(hull, "independent").get_image()
	if img.is_compressed():
		img.decompress()
	var sw := img.get_width()
	var sh := img.get_height()
	var length_m := float(HullData53.HULLS.get(hull, {}).get("length", 60))
	var sc := length_m * ART_PER_M / sw
	var L := sw * sc
	var B := sh * sc
	var m := GroundMap.new()
	m.pal = DeckGen.palette_for_body(body).duplicate()
	m.title = String(site.get("name", "Crash site"))
	m.hull_top = -60
	var W := int(L / TILE) + 70                      # room in the west for the trench it ploughed
	var H := int(B / TILE) + 36
	m.setup(W, H)
	m.fill(0, 0, W, H, T.FLOOR, 13)
	m.fill(0, H - 1, W, 1, T.BLOCK, 13)
	m.fill(0, 0, 1, H, T.BLOCK, 13)
	m.fill(W - 1, 0, 1, H, T.BLOCK, 13)
	m.fill(0, 0, W, 1, T.BLOCK, 13)
	var ang := rng.randf_range(-0.07, 0.07)
	var c := Vector2(W * TILE - L * 0.5 - 10.0 * TILE, 2.0 * TILE + B * 0.5 + 10.0)
	var cut_f := rng.randf_range(0.1, 0.17)
	var stern_ang := ang - rng.randf_range(0.25, 0.45)
	# where it broke: the stern piece lies a little back from the break, turned away
	var brk := c + Vector2(cut_f * L - L * 0.5, 0).rotated(ang)
	var piece_mid := brk + Vector2(-cut_f * L * 0.5 - 50.0, 30.0)
	var stern_c := piece_mid - Vector2(cut_f * L * 0.5 - L * 0.5, 0).rotated(stern_ang)
	# what the hull stands on: blocked
	for ty in H:
		for tx in W:
			var p := Vector2(tx + 0.5, ty + 0.5) * TILE
			if ship_covers(img, c, sc, ang, Vector2(0.0, cut_f), p) or ship_covers(img, stern_c, sc, stern_ang, Vector2(cut_f, 1.01), p):
				m.set_t(tx, ty, T.BLOCK, 13)
	m.set_meta("wreck", {"hull": hull, "c": c, "sc": sc, "ang": ang, "cut": Vector2(0.0, cut_f), "stern_c": stern_c, "stern_ang": stern_ang,
		"stern_cut": Vector2(cut_f, 1.01), "burnt": rng.randf_range(0.35, 0.55)})
	# the furrow it ploughed, from the west to its stern; craters; debris; scorch
	# 0.7.53.6 (Luz): the impact trench – as wide as much of its hull, ploughed along its course from the west edge to
	# where it lies, earth thrown up in walls along both sides, gouges along it; the stern lies in it
	var dirv := Vector2.RIGHT.rotated(ang)
	var t_end := c - dirv * (L * 0.5 - 30.0)
	var t_start := t_end - dirv * (t_end.x + 40.0) / maxf(0.2, dirv.x)
	m.decals.append({"kind": "trench", "x": 0, "y": 0, "a": t_start, "b": t_end, "wid": B * 0.62, "seed": rng.randi()})
	for cr in 6:
		m.decals.append({"kind": "crater", "x": rng.randi_range(4, W - 6), "y": rng.randi_range(int((c.y + B * 0.5) / TILE) + 3, H - 4), "w": rng.randi_range(2, 4), "h": 2})
	for db in 120:
		m.decals.append({"kind": "debris", "x": rng.randi_range(2, W - 3), "y": rng.randi_range(int((c.y + B * 0.4) / TILE), H - 3), "w": 1, "h": 1, "seed": rng.randi()})
	# the pad, south-west, with the drone
	var sl := clampi(int(ceil(ship_len / TILE)) + 4, 10, 40)
	var sb := clampi(int(ceil(ship_beam / TILE)) + 4, 7, 20)
	var px0 := 4
	var py0 := H - sb - 5
	m.fill(px0, py0, sl, sb, T.FLOOR, 14)
	m.decals.append({"kind": "landing_pad", "x": px0, "y": py0, "w": sl, "h": sb, "col": Color(0.95, 0.8, 0.2), "n": 1})
	m.pad_rects.append(Rect2(Vector2(px0, py0) * TILE, Vector2(sl, sb) * TILE))
	var sc2 := Vector2(px0 + sl * 0.5, py0 + sb * 0.5)
	m.ship_at = sc2 * TILE
	var bx := int(sc2.x - ship_len / TILE * 0.5) + 1
	var bw := maxi(2, int(ship_len / TILE) - 2)
	var bh := maxi(1, int(ship_beam / TILE) - 1)
	m.fill(bx, int(sc2.y - bh * 0.5), bw, bh, T.BLOCK, 14)
	var rx := int(sc2.x) - 1
	var ry := int(sc2.y + bh * 0.5)
	m.decals.append({"kind": "ramp", "x": rx, "y": ry, "w": 2, "h": 2, "col": Color(1.0, 0.8, 0.25)})
	m.spawn = Vector2(rx + 1.0, ry + 2.6) * TILE
	m.zones.append({"rect": Rect2(Vector2(rx - 0.5, ry) * TILE, Vector2(3, 3.2) * TILE), "kind": "exit", "id": "ship",
		"title": "Up the ramp – take off", "col": Color(0.4, 1.0, 0.6), "sign": Vector2(-100, -100)})
	m.add_object({"kind": "fuel_point", "x": px0 + sl + 1, "y": py0, "w": 2, "h": 1, "rise": 34})
	m.zones.append({"rect": Rect2(Vector2(px0 + sl + 0.4, py0 + 1.0) * TILE, Vector2(3.2, 1.6) * TILE), "kind": "charge", "id": "charge",
		"title": "Supply point – energy, oxygen and ammunition", "col": Color(0.35, 0.95, 1.0), "sign": Vector2(-100, -100)})
	# the ways in: the breach and the emergency airlock on its south flank
	var bp := ship_edge(img, c, sc, ang, rng.randf_range(0.36, 0.46))
	var ap := ship_edge(img, c, sc, ang, rng.randf_range(0.58, 0.7))
	var breach := ExploreNode.add(m, "breach", bp, {"no_zone": true, "state": "open" if rng.randf() < 0.45 else "shut", "seed": rng.randi()})
	var bi := m.explore.find(breach)
	m.zones.append({"rect": Rect2(bp + Vector2(-26, -6), Vector2(52, 30)), "kind": "explore", "id": "explore", "i": bi, "title": "A breach in the hull"})
	var lock := ExploreNode.add(m, "airlock", ap, {"no_zone": true, "seed": rng.randi(), "tiles": []})
	var ai := m.explore.find(lock)
	ExploreNode.add(m, "terminal", ap + Vector2(34, 22), {"actions": ["door"], "door": ai, "style": "ship", "seed": rng.randi()})
	for e in [[bp, bi, "Through the breach – inside"], [ap, ai, "Through the airlock – inside"]]:
		m.zones.append({"rect": Rect2((e[0] as Vector2) + Vector2(-20, -4), Vector2(40, 18)), "kind": "dungeon_in", "id": "dungeon_in", "gate": e[1],
			"title": String(e[2]), "col": Color(1.0, 0.45, 0.35), "sign": Vector2(-100, -100)})
	m.set_meta("door_front", bp + Vector2(0, 26))
	# cargo: containers thrown out of its hold – one burst open, its goods spilled
	var placed: Array = []
	for ci in rng.randi_range(4, 6):
		for tries in 12:
			var ox := rng.randi_range(4, W - 10)
			var oy := rng.randi_range(int((c.y + B * 0.5) / TILE) + 3, H - 6)
			var ok := true
			for yy in range(oy - 1, oy + 4):
				for xx in range(ox - 1, ox + 8):
					if not GroundMap.walkable_t(m.t_at(xx, yy)) or m.floor_kind[clampi(yy, 0, H - 1) * W + clampi(xx, 0, W - 1)] == 14:
						ok = false
			for pl in placed:
				if absi(int(pl.x) - ox) < 10 and absi(int(pl.y) - oy) < 5:
					ok = false
			if ok:
				var open := ci == 0
				m.add_object({"kind": "container", "x": ox, "y": oy, "w": 6, "h": 2, "col": [Color(0.75, 0.35, 0.15), Color(0.2, 0.45, 0.6), Color(0.3, 0.55, 0.3), Color(0.6, 0.6, 0.62), Color(0.7, 0.6, 0.2)][ci % 5], "open": open})
				if open:
					m.add_object({"kind": "crates", "x": ox + 7, "y": oy + 1, "w": 2, "h": 1})
				placed.append(Vector2i(ox, oy))
				break
	# rocks (cover), the scavengers' camp to the east
	for rk in 10:
		var rx2 := rng.randi_range(3, W - 4)
		var ry2 := rng.randi_range(int((c.y + B * 0.5) / TILE) + 2, H - 3)
		if GroundMap.walkable_t(m.t_at(rx2, ry2)) and GroundMap.walkable_t(m.t_at(rx2 + 1, ry2)) and m.floor_kind[ry2 * W + rx2] != 14:
			m.add_object({"kind": "rock", "x": rx2, "y": ry2, "w": 2, "h": 1, "col": Color(0.45, 0.4, 0.34), "seed": rng.randi()})
	var camp := Vector2i(W - 12, H - 10)
	m.add_object({"kind": "rover", "x": camp.x, "y": camp.y, "w": 3, "h": 2})
	m.add_object({"kind": "crates", "x": camp.x - 3, "y": camp.y + 2, "w": 2, "h": 1})
	m.lights.append({"pos": Vector2(camp.x, camp.y + 2) * TILE, "r": 60.0, "col": Color(1.0, 0.8, 0.5), "a": 0.35})
	var foes: Array = []
	var dg: Dictionary = PoiData.DANGER.get(String(site.get("danger", "yellow")), PoiData.DANGER["yellow"])
	for fi in rng.randi_range(2, 3):
		var fp := Vector2(camp.x - 2 + fi * 2, camp.y + 4) * TILE
		if m.free_at(fp, 6.0):
			m.foe_spawns.append(fp)
			foes.append("%s@%s" % [_foe_pick(th, rng), String(dg["tiers"][0])])
	m.set_meta("foes", foes)
	# fires along the hull, smoke rising
	var plumes: Array = []
	for fr in 4:
		var fq := ship_edge(img, c, sc, ang, rng.randf_range(0.15, 0.85)) + Vector2(0, -rng.randf_range(20, B * 0.6))
		plumes.append(fq)
		m.lights.append({"pos": fq, "r": 50.0, "col": Color(1.0, 0.55, 0.2), "a": 0.45, "flicker": true})
	plumes.append(piece_mid)
	m.lights.append({"pos": piece_mid, "r": 50.0, "col": Color(1.0, 0.55, 0.2), "a": 0.45, "flicker": true})
	# bigger pieces torn off it: engine parts, heaps of plating
	for pc in 6:
		var qx := rng.randi_range(4, W - 6)
		var qy := rng.randi_range(int((c.y + B * 0.5) / TILE) + 2, H - 4)
		if GroundMap.walkable_t(m.t_at(qx, qy)) and GroundMap.walkable_t(m.t_at(qx + 2, qy)) and m.floor_kind[qy * W + qx] != 14:
			m.add_object({"kind": ["engine_part", "heap"][pc % 2], "x": qx, "y": qy, "w": 3 if pc % 2 == 0 else 2, "h": 1, "col": Color(0.45, 0.46, 0.5)})
	m.set_meta("plumes", plumes)
	m.lights.append({"pos": bp + Vector2(0, 12), "r": 50.0, "col": Color(1.0, 0.3, 0.2), "a": 0.35, "flicker": true})
	m.lights.append({"pos": ap + Vector2(0, 8), "r": 40.0, "col": Color(1.0, 0.2, 0.15), "a": 0.35})
	return m
