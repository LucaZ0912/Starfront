class_name ArenaGen
extends RefCounted
## Package 52: the debug arena (Luz, 10 Nov 2026: "for now the debug arena is enough") – open ground of the world,
## the landing drone on its pad to the west (the way back up, a charging point beside it), and to the east a wide field
## of cover: crate stacks, plated barriers and boulders you can shoot over (low), bulwarks you cannot see through
## (high), barrels. Foes stand at the far side (map.foe_spawns).

const TILE := GroundMap.TILE


static func build(body: Dictionary, site: Dictionary, ship_len: float, ship_beam: float) -> GroundMap:
	var m := GroundMap.new()
	m.pal = DeckGen.palette_for_body(body)
	m.title = String(site.get("name", "Debug Arena"))
	m.hull_top = -60
	var sl := clampi(int(ceil(ship_len / TILE)) + 4, 10, 40)
	var sb := clampi(int(ceil(ship_beam / TILE)) + 4, 7, 20)
	var W := sl + 52
	var H := maxi(sb + 22, 34)
	m.setup(W, H)
	m.fill(0, 0, W, H, GroundMap.T.FLOOR, 13)
	m.fill(0, 0, W, 1, GroundMap.T.BLOCK, 13)
	m.fill(0, H - 1, W, 1, GroundMap.T.BLOCK, 13)
	m.fill(0, 0, 1, H, GroundMap.T.BLOCK, 13)
	m.fill(W - 1, 0, 1, H, GroundMap.T.BLOCK, 13)
	# the pad with the drone, its ramp to the south
	var px0 := 3
	var py0 := H / 2 - sb / 2 - 2
	m.fill(px0, py0, sl, sb, GroundMap.T.FLOOR, 14)
	m.decals.append({"kind": "landing_pad", "x": px0, "y": py0, "w": sl, "h": sb, "col": Color(0.95, 0.8, 0.2), "n": 1})
	m.pad_rects.append(Rect2(Vector2(px0, py0) * TILE, Vector2(sl, sb) * TILE))
	var sc := Vector2(px0 + sl * 0.5, py0 + sb * 0.5)
	m.ship_at = sc * TILE
	var bx := int(sc.x - ship_len / TILE * 0.5) + 1
	var bw := maxi(2, int(ship_len / TILE) - 2)
	var bh := maxi(1, int(ship_beam / TILE) - 1)
	m.fill(bx, int(sc.y - bh * 0.5), bw, bh, GroundMap.T.BLOCK, 14)
	var rx := int(sc.x) - 1
	var ry := int(sc.y + bh * 0.5)
	m.decals.append({"kind": "ramp", "x": rx, "y": ry, "w": 2, "h": 2, "col": Color(1.0, 0.8, 0.25)})
	m.spawn = Vector2(rx + 1.0, ry + 2.6) * TILE
	m.zones.append({"rect": Rect2(Vector2(rx - 0.5, ry) * TILE, Vector2(3, 3.2) * TILE), "kind": "exit", "id": "ship",
		"title": "Up the ramp – take off", "col": Color(0.4, 1.0, 0.6), "sign": Vector2(-100, -100)})
	for k in range(0, sl + 1, 4):
		m.lights.append({"pos": Vector2(px0 + k, py0) * TILE, "r": 22.0, "col": Color(1.0, 0.75, 0.3), "a": 0.35, "flicker": k % 8 == 0})
		m.lights.append({"pos": Vector2(px0 + k, py0 + sb) * TILE, "r": 22.0, "col": Color(1.0, 0.75, 0.3), "a": 0.35})
	m.add_object({"kind": "fuel_point", "x": px0 + sl + 1, "y": py0, "w": 2, "h": 1, "rise": 34})
	m.zones.append({"rect": Rect2(Vector2(px0 + sl + 0.4, py0 + 1.0) * TILE, Vector2(3.2, 1.6) * TILE), "kind": "charge", "id": "charge",
		"title": "Supply point – energy, oxygen and ammunition", "col": Color(0.35, 0.95, 1.0), "sign": Vector2(-100, -100)})
	m.zones.append({"rect": Rect2(), "kind": "label", "id": "arena_sign", "title": "DEBUG ARENA  →",
		"col": Color(1.0, 0.45, 0.35), "sign": Vector2(px0 + sl + 1, py0 + sb + 1.5) * TILE})
	# the field of cover, cell by cell
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(site.get("id", "arena"))) + 52
	var x0 := px0 + sl + 5
	var rock: Color = (m.pal["terrain_a"] as Color).darkened(0.25).lerp(Color(0.45, 0.43, 0.42), 0.5)
	var pieces := [
		[["crates", 2, 1], ["crates", 2, 1, 0, 1]],                 # a stack two deep
		[["barrier", 3, 1]], [["barrier", 1, 3]], [["barrier", 4, 1]],
		[["rock", 2, 1]], [["rock", 2, 2]],
		[["barrel", 1, 1], ["barrel", 1, 1, 1, 0]],
		[["bulwark", 3, 1]], [["bulwark", 1, 3]],
		[["crates", 2, 1], ["barrier", 1, 2, 2, 0]],
	]
	for cy in range(2, H - 4, 6):
		for cx in range(x0, W - 4, 7):
			if rng.randf() < 0.18:
				continue
			var piece: Array = pieces[rng.randi() % pieces.size()]
			var ox := cx + rng.randi_range(0, 3)
			var oy := cy + rng.randi_range(0, 2)
			var ok := true
			for part in piece:
				var px := ox + (int(part[3]) if part.size() > 3 else 0)
				var py := oy + (int(part[4]) if part.size() > 4 else 0)
				for yy in range(py - 1, py + int(part[2]) + 1):
					for xx in range(px - 1, px + int(part[1]) + 1):
						if not GroundMap.walkable_t(m.t_at(xx, yy)) or xx >= W - 2 or yy >= H - 2:
							ok = false
			if not ok:
				continue
			for part2 in piece:
				var o := {"kind": String(part2[0]), "x": ox + (int(part2[3]) if part2.size() > 3 else 0), "y": oy + (int(part2[4]) if part2.size() > 4 else 0),
					"w": int(part2[1]), "h": int(part2[2])}
				if o["kind"] == "rock":
					o["col"] = rock
					o["seed"] = rng.randi()
				m.add_object(o)
	# where foes stand: the far third of the field
	for k2 in 40:
		var p := Vector2(rng.randf_range(W * 0.68, W - 3), rng.randf_range(3, H - 3)) * TILE
		if m.free_at(p, 6.0):
			m.foe_spawns.append(p)
		if m.foe_spawns.size() >= 10:
			break
	# no strollers here (map.wander stays empty): only the fight
	return m
