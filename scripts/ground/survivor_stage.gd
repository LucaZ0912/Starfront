extends RefCounted
## Package 62a, part 7 (Luz): the stages of Survivor, as holograms far larger than the fights' grounds (about six
## times the area), with room to run. No cover here: obstacles that belong to the setting, in loose groups with wide
## lanes between them, so that you can lead a swarm round them. The dangers of the ground stay (they work on the
## others as on you).
##   outbreak: a colony under quarantine, by night. Two roads cross in its middle; round them parked rovers, cargo
##   containers, greenhouse domes, silos and gas tanks, fences, lamps; burning wrecks (embers round them), spilled
##   coolant (it holds back whoever walks through it).
##   takeover: (part 8) a city quarter by night, long after the machines took it: see _takeover.
##   whiteout: (part 9) a moon of ice, by day: see _whiteout.
## No class_name: preload("res://scripts/ground/survivor_stage.gd").

const TILE := GroundMap.TILE
const SW := 200                    # tiles
const SH := 140
const EDGE := 2                    # the wall of light round the hologram
const ROAD := 6                    # how wide a road is
const CELL_W := 20                 # one group of obstacles to a cell of this size at most
const CELL_H := 16
const CONT := [Color(0.75, 0.35, 0.15), Color(0.2, 0.45, 0.6), Color(0.3, 0.55, 0.3), Color(0.6, 0.6, 0.62), Color(0.7, 0.6, 0.2)]


static func build(stage_id: String, seed_n: int) -> GroundMap:
	if stage_id == "takeover":
		return _takeover(stage_id, seed_n)                   # (part 8) the second stage has a ground of its own
	if stage_id == "whiteout":
		return _whiteout(stage_id, seed_n)                   # (part 9) … and so has the third
	var m := GroundMap.new()
	m.pal = DeckGen.palette_for_body({"type": "barren"})
	m.pal["terrain_a"] = Color(0.3, 0.31, 0.34)
	m.pal["terrain_b"] = Color(0.34, 0.34, 0.37)
	m.pal["terrain_c"] = Color(0.26, 0.27, 0.31)
	m.pal["floor"] = Color(0.27, 0.28, 0.33)
	m.pal["floor2"] = Color(0.31, 0.32, 0.37)
	m.title = "The Colosseum"
	m.hull_top = -60
	m.setup(SW, SH)
	m.fill(0, 0, SW, SH, GroundMap.T.BLOCK, 13)
	m.fill(EDGE, EDGE, SW - EDGE * 2, SH - EDGE * 2, GroundMap.T.FLOOR, 13)
	var mx := SW / 2
	var my := SH / 2
	m.fill(EDGE, my - ROAD / 2, SW - EDGE * 2, ROAD, GroundMap.T.FLOOR, 14)          # two roads cross in the middle
	m.fill(mx - ROAD / 2, EDGE, ROAD, SH - EDGE * 2, GroundMap.T.FLOOR, 14)
	m.spawn = Vector2(mx, my) * TILE
	m.set_meta("from_gate", m.spawn)
	m.set_meta("sv_stage", stage_id)
	m.set_meta("col_vr", stage_id)
	m.set_meta("col_vr_name", "Outbreak")
	m.set_meta("dark", Color(0.5, 0.52, 0.68))                 # by night: the lamps and the fires glow in it
	m.decals.append({"kind": "mat", "x": mx - 2, "y": my - 1, "w": 4, "h": 2, "col": Color(0.3, 0.9, 1.0)})
	m.zones.append({"rect": Rect2(Vector2(mx - 2, my - 1.0) * TILE, Vector2(4.0, 2.0) * TILE), "kind": "sv_giveup", "id": "sv_giveup",
		"title": "End the run: leave the hologram", "col": Color(1.0, 0.45, 0.4), "sign": Vector2(-100, -100)})
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("sv_%s_%d" % [stage_id, seed_n])
	var burn: Array = []
	var slow: Array = []
	# is this patch of ground free for something to stand on (off the roads, clear of where you begin)?
	var clear := func(x: int, y: int, w: int, h: int) -> bool:
		if x < EDGE + 2 or y < EDGE + 2 or x + w > SW - EDGE - 2 or y + h > SH - EDGE - 2:
			return false
		if Rect2(x - 1, y - 1, w + 2, h + 2).intersects(Rect2(EDGE, my - ROAD / 2, SW, ROAD)) or Rect2(x - 1, y - 1, w + 2, h + 2).intersects(Rect2(mx - ROAD / 2, EDGE, ROAD, SH)):
			return false
		if Vector2(x + w * 0.5, y + h * 0.5).distance_to(Vector2(mx, my)) < 11.0:
			return false
		for yy in range(y, y + h):
			for xx in range(x, x + w):
				if not GroundMap.walkable_t(m.t_at(xx, yy)):
					return false
		return true
	var put := func(o: Dictionary) -> bool:
		if not clear.call(int(o["x"]), int(o["y"]), int(o.get("w", 1)), int(o.get("h", 1))):
			return false
		m.add_object(o)
		return true
	# ---- the groups of obstacles, one to a cell of the field at most
	var kinds: Array = ["containers", "containers", "rovers", "rovers", "dome", "silo", "fence", "fence", "wreck", "wreck", "coolant", "tanks", "crates"]
	for cy in range(EDGE + 2, SH - EDGE - CELL_H, CELL_H):
		for cx in range(EDGE + 2, SW - EDGE - CELL_W, CELL_W):
			if rng.randf() < 0.14:
				continue
			var ox := cx + rng.randi_range(1, 6)
			var oy := cy + rng.randi_range(1, 5)
			match String(kinds[rng.randi() % kinds.size()]):
				"containers":                                     # two or three cargo containers, a lane between the rows
					put.call({"kind": "container", "x": ox, "y": oy, "w": 6, "h": 2, "col": CONT[rng.randi() % CONT.size()]})
					put.call({"kind": "container", "x": ox + rng.randi_range(0, 3), "y": oy + 5, "w": 6, "h": 2, "col": CONT[rng.randi() % CONT.size()]})
					if rng.randf() < 0.5:
						put.call({"kind": "crates", "x": ox + 7, "y": oy + 1, "w": 2, "h": 1})
				"rovers":                                         # rovers left where they stood, a loader
					put.call({"kind": "rover", "x": ox, "y": oy, "w": 3, "h": 2, "col": Color.from_hsv(rng.randf(), 0.45, 0.7)})
					put.call({"kind": "rover", "x": ox + 5, "y": oy + 3, "w": 3, "h": 2, "col": Color.from_hsv(rng.randf(), 0.45, 0.7)})
					if rng.randf() < 0.5:
						put.call({"kind": "cargo_loader", "x": ox + 1, "y": oy + 5, "w": 3, "h": 1, "rise": 24})
				"dome":                                           # a greenhouse dome, what was stacked beside it
					put.call({"kind": "dome", "x": ox, "y": oy, "w": 5, "h": 3})
					put.call({"kind": "crates", "x": ox + 6, "y": oy + 2, "w": 2, "h": 1})
					put.call({"kind": "barrel", "x": ox + 1, "y": oy + 5, "w": 1, "h": 1})
				"silo":
					put.call({"kind": "silo", "x": ox, "y": oy, "w": 4, "h": 3, "rise": 110, "col": Color(0.6, 0.63, 0.6)})
					put.call({"kind": "cable_drum", "x": ox + 6, "y": oy + 3, "w": 2, "h": 1})
				"tanks":
					put.call({"kind": "gas_tank", "x": ox, "y": oy, "w": 5, "h": 3})
				"fence":                                          # a stretch of the quarantine's fence, a gap in it
					var across := rng.randf() < 0.5
					for k in 3:
						if k == 1 and rng.randf() < 0.6:
							continue
						if across:
							put.call({"kind": "fence", "x": ox + k * 3, "y": oy + 2, "w": 3, "h": 1})
						else:
							put.call({"kind": "fence", "x": ox + 3, "y": oy + k * 3, "w": 1, "h": 3})
				"crates":
					put.call({"kind": "crates", "x": ox, "y": oy, "w": 2, "h": 1})
					put.call({"kind": "crates", "x": ox + 3, "y": oy + 2, "w": 2, "h": 1})
					put.call({"kind": "barrel", "x": ox + 6, "y": oy + 1, "w": 1, "h": 1})
					put.call({"kind": "fire_barrel", "x": ox + 2, "y": oy + 5, "w": 1, "h": 1})
					m.lights.append({"pos": Vector2(ox + 2.5, oy + 5.2) * TILE, "r": 70.0, "col": Color(1.0, 0.6, 0.25), "a": 0.5, "flicker": true})
				"wreck":                                          # a wreck that still burns: embers on the ground round it
					if put.call({"kind": "tank_vehicle", "x": ox + 2, "y": oy + 2, "w": 4, "h": 2}):
						burn.append(Rect2(Vector2(ox, oy) * TILE, Vector2(8, 6) * TILE))
						m.lights.append({"pos": Vector2(ox + 4.0, oy + 3.0) * TILE, "r": 110.0, "col": Color(1.0, 0.45, 0.15), "a": 0.5, "flicker": true})
				"coolant":                                        # a split tank, its coolant all over the ground
					if clear.call(ox, oy, 9, 6):
						put.call({"kind": "barrel", "x": ox + 4, "y": oy + 2, "w": 1, "h": 1})
						put.call({"kind": "barrel", "x": ox + 5, "y": oy + 3, "w": 1, "h": 1})
						slow.append(Rect2(Vector2(ox, oy) * TILE, Vector2(9, 6) * TILE))
						m.lights.append({"pos": Vector2(ox + 4.5, oy + 3.0) * TILE, "r": 90.0, "col": Color(0.3, 0.9, 1.0), "a": 0.3})
	# ---- lamps along the roads
	var li := 0
	for lx in range(EDGE + 6, SW - EDGE - 4, 13):
		for ly in [my - ROAD / 2 - 1, my + ROAD / 2]:
			if absi(lx - mx) < ROAD:
				continue
			if li % 4 != 3:                                       # (one in four is out)
				m.add_object({"kind": "lamp_post", "x": lx, "y": ly, "w": 1, "h": 1})
				m.lights.append({"pos": Vector2(lx + 0.5, ly + 0.5) * TILE, "r": 120.0, "col": Color(1.0, 0.92, 0.75), "a": 0.5})
			li += 1
	for ly2 in range(EDGE + 6, SH - EDGE - 4, 13):
		for lx2 in [mx - ROAD / 2 - 1, mx + ROAD / 2]:
			if absi(ly2 - my) < ROAD:
				continue
			if li % 4 != 3:
				m.add_object({"kind": "lamp_post", "x": lx2, "y": ly2, "w": 1, "h": 1})
				m.lights.append({"pos": Vector2(lx2 + 0.5, ly2 + 0.5) * TILE, "r": 120.0, "col": Color(1.0, 0.92, 0.75), "a": 0.5})
			li += 1
	m.lights.append({"pos": m.spawn, "r": 150.0, "col": Color(0.4, 0.9, 1.0), "a": 0.35})
	# part 7c-2: crates standing about the colony (far from each other, not near where you begin), and those who lie
	# there and rise later
	var crs: Array = []
	var tries := 0
	while crs.size() < 18 and tries < 900:
		tries += 1
		var cp := Vector2(rng.randi_range(EDGE + 4, SW - EDGE - 5) + 0.5, rng.randi_range(EDGE + 4, SH - EDGE - 5) + 0.5) * TILE
		if m.free_at(cp, 6.0) and cp.distance_to(m.spawn) > 14.0 * TILE and not crs.any(func(c): return (c as Vector2).distance_to(cp) < 22.0 * TILE):
			crs.append(cp)
	m.set_meta("sv_crates", crs)
	var sls: Array = []
	tries = 0
	while sls.size() < 70 and tries < 1500:
		tries += 1
		var slp := Vector2(rng.randi_range(EDGE + 3, SW - EDGE - 4) + 0.5, rng.randi_range(EDGE + 3, SH - EDGE - 4) + 0.5) * TILE
		if m.free_at(slp, 8.0) and slp.distance_to(m.spawn) > 9.0 * TILE and not sls.any(func(c): return (c as Vector2).distance_to(slp) < 5.0 * TILE):
			sls.append(slp)
	m.set_meta("sv_sleepers", sls)
	m.set_meta("col_hazards", [
		{"kind": "burn", "rects": burn, "name": "Burning wrecks: the embers round them burn whoever stands there.", "dps": 12.0, "dtype": "explosive", "pulse": [], "look": "embers"},
		{"kind": "slow", "rects": slow, "name": "Spilled coolant: it holds back whoever walks through it.", "k": 0.55, "look": "coolant"}])
	m.set_meta("col_haz_state", {"t": 0.0, "tick": 0.0, "cloud": 2.0, "n": 0})
	return m


## Part 8 (Luz): AI Takeover: a city quarter by night, long after the machines took it. Two broken roads cross in
## its middle. No lamps: wrecks burn, radio masts blink red. In place of cover: heaps of rubble, burnt-out cars, rows
## of tank traps, what is left of bunkers, fallen pillars, barricades; north-east of the middle a landing ship that
## came down long ago. Spilled oil holds back whoever walks through it. Craters, scorch marks and cracks all over
## the ground (map meta "sv_decor").
const RUBBLE := [Color(0.4, 0.41, 0.46), Color(0.36, 0.37, 0.43), Color(0.44, 0.43, 0.45)]
const SCRAP := [Color(0.2, 0.19, 0.21), Color(0.24, 0.2, 0.18), Color(0.18, 0.2, 0.24)]

static func _takeover(stage_id: String, seed_n: int) -> GroundMap:
	var m := GroundMap.new()
	m.pal = DeckGen.palette_for_body({"type": "barren"})
	m.pal["terrain_a"] = Color(0.2, 0.21, 0.26)
	m.pal["terrain_b"] = Color(0.23, 0.24, 0.29)
	m.pal["terrain_c"] = Color(0.17, 0.18, 0.23)
	m.pal["floor"] = Color(0.25, 0.26, 0.31)
	m.pal["floor2"] = Color(0.28, 0.29, 0.34)
	m.title = "The Colosseum"
	m.hull_top = -60
	m.setup(SW, SH)
	m.fill(0, 0, SW, SH, GroundMap.T.BLOCK, 13)
	m.fill(EDGE, EDGE, SW - EDGE * 2, SH - EDGE * 2, GroundMap.T.FLOOR, 13)
	var mx := SW / 2
	var my := SH / 2
	m.fill(EDGE, my - ROAD / 2, SW - EDGE * 2, ROAD, GroundMap.T.FLOOR, 14)
	m.fill(mx - ROAD / 2, EDGE, ROAD, SH - EDGE * 2, GroundMap.T.FLOOR, 14)
	m.spawn = Vector2(mx, my) * TILE
	m.set_meta("from_gate", m.spawn)
	m.set_meta("sv_stage", stage_id)
	m.set_meta("col_vr", stage_id)
	m.set_meta("col_vr_name", "AI Takeover")
	m.set_meta("dark", Color(0.48, 0.5, 0.66))                 # a little darker than the colony, and no lamp is left standing
	m.decals.append({"kind": "mat", "x": mx - 2, "y": my - 1, "w": 4, "h": 2, "col": Color(1.0, 0.35, 0.3)})
	m.zones.append({"rect": Rect2(Vector2(mx - 2, my - 1.0) * TILE, Vector2(4.0, 2.0) * TILE), "kind": "sv_giveup", "id": "sv_giveup",
		"title": "End the run: leave the hologram", "col": Color(1.0, 0.45, 0.4), "sign": Vector2(-100, -100)})
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("sv_%s_%d" % [stage_id, seed_n])
	var burn: Array = []
	var slow: Array = []
	var decor: Array = []
	var clear := func(x: int, y: int, w: int, h: int) -> bool:
		if x < EDGE + 2 or y < EDGE + 2 or x + w > SW - EDGE - 2 or y + h > SH - EDGE - 2:
			return false
		if Rect2(x - 1, y - 1, w + 2, h + 2).intersects(Rect2(EDGE, my - ROAD / 2, SW, ROAD)) or Rect2(x - 1, y - 1, w + 2, h + 2).intersects(Rect2(mx - ROAD / 2, EDGE, ROAD, SH)):
			return false
		if Vector2(x + w * 0.5, y + h * 0.5).distance_to(Vector2(mx, my)) < 11.0:
			return false
		for yy in range(y, y + h):
			for xx in range(x, x + w):
				if not GroundMap.walkable_t(m.t_at(xx, yy)):
					return false
		return true
	var put := func(o: Dictionary) -> bool:
		if not clear.call(int(o["x"]), int(o["y"]), int(o.get("w", 1)), int(o.get("h", 1))):
			return false
		m.add_object(o)
		return true
	# ---- the landing ship that came down long ago: north-east of the middle
	var sx := mx + 16
	var sy := my - 24
	if put.call({"kind": "dropship_wreck", "x": sx, "y": sy, "w": 10, "h": 5, "rise": 52}):
		m.set_meta("sv_landmark", Vector2(sx + 5.0, sy + 6.5) * TILE)
		m.lights.append({"pos": Vector2(sx + 5.0, sy + 5.5) * TILE, "r": 130.0, "col": Color(0.6, 0.8, 1.0), "a": 0.22})
		for dq in 7:
			decor.append({"kind": "scorch", "pos": Vector2(sx - 2.0 + dq * 2.2, sy + 6.2 + (dq % 2) * 0.8) * TILE, "r": 20.0 + (dq % 3) * 6.0})
		decor.append({"kind": "crater", "pos": Vector2(sx - 5.0, sy + 6.0) * TILE, "r": 30.0})
		put.call({"kind": "rubble", "x": sx + 11, "y": sy + 3, "w": 3, "h": 2, "col": RUBBLE[0]})
	# ---- the groups of what stands in the way, one to a cell of the field at most
	var kinds: Array = ["rubble", "rubble", "rubble", "cars", "cars", "traps", "traps", "bunker", "pillars", "wreck", "wreck", "mast", "oil", "barricade"]
	for cy in range(EDGE + 2, SH - EDGE - CELL_H, CELL_H):
		for cx in range(EDGE + 2, SW - EDGE - CELL_W, CELL_W):
			if rng.randf() < 0.12:
				continue
			var ox := cx + rng.randi_range(1, 6)
			var oy := cy + rng.randi_range(1, 5)
			match String(kinds[rng.randi() % kinds.size()]):
				"rubble":                                         # heaps of broken wall, a slab come down beside them
					put.call({"kind": "rubble", "x": ox, "y": oy, "w": 4, "h": 2, "col": RUBBLE[rng.randi() % RUBBLE.size()]})
					put.call({"kind": "rubble", "x": ox + 5 + rng.randi_range(0, 2), "y": oy + 3, "w": 3, "h": 2, "col": RUBBLE[rng.randi() % RUBBLE.size()]})
					if rng.randf() < 0.5:
						put.call({"kind": "rubble", "x": ox + 1, "y": oy + 5, "w": 2, "h": 1, "col": RUBBLE[rng.randi() % RUBBLE.size()]})
					decor.append({"kind": "crack", "pos": Vector2(ox + 2.0, oy + 3.4) * TILE, "r": 46.0, "a": rng.randf() * TAU})
				"cars":                                           # ground cars left where they burnt out
					put.call({"kind": "wreck_car", "x": ox, "y": oy, "w": 3, "h": 2, "col": SCRAP[rng.randi() % SCRAP.size()]})
					put.call({"kind": "wreck_car", "x": ox + 5, "y": oy + 3 + rng.randi_range(0, 1), "w": 3, "h": 2, "col": SCRAP[rng.randi() % SCRAP.size()]})
					decor.append({"kind": "scorch", "pos": Vector2(ox + 1.5, oy + 2.6) * TILE, "r": 22.0})
					if rng.randf() < 0.4:
						put.call({"kind": "fire_barrel", "x": ox + 4, "y": oy + 1, "w": 1, "h": 1})
						m.lights.append({"pos": Vector2(ox + 4.5, oy + 1.2) * TILE, "r": 70.0, "col": Color(1.0, 0.6, 0.25), "a": 0.5, "flicker": true})
				"traps":                                          # a row of tank traps, room to slip through between them
					var across := rng.randf() < 0.5
					for k in 5:
						if across:
							put.call({"kind": "tank_trap", "x": ox + k * 2, "y": oy + 2 + (k % 2), "w": 1, "h": 1})
						else:
							put.call({"kind": "tank_trap", "x": ox + 3 + (k % 2), "y": oy + k * 2, "w": 1, "h": 1})
				"bunker":                                         # what is left of a bunker: two walls at an angle, a barricade before them
					put.call({"kind": "bulwark", "x": ox, "y": oy, "w": 6, "h": 1, "col": Color(0.34, 0.35, 0.4)})
					put.call({"kind": "bulwark", "x": ox, "y": oy + 1, "w": 1, "h": 4, "col": Color(0.34, 0.35, 0.4)})
					put.call({"kind": "rubble", "x": ox + 6, "y": oy + 1, "w": 2, "h": 1, "col": RUBBLE[1]})
					put.call({"kind": "barrier", "x": ox + 3, "y": oy + 4, "w": 3, "h": 1, "col": Color(0.3, 0.31, 0.36)})
				"pillars":                                        # the pillars of a road that ran above: fallen, a slab between them
					put.call({"kind": "pillar_fallen", "x": ox, "y": oy + 1, "w": 5, "h": 1})
					put.call({"kind": "slab", "x": ox + 2, "y": oy + 3, "w": 3, "h": 2})
					put.call({"kind": "pillar_fallen", "x": ox + 6, "y": oy + 5, "w": 4, "h": 1})
					decor.append({"kind": "crack", "pos": Vector2(ox + 1.0, oy + 2.6) * TILE, "r": 60.0, "a": rng.randf() * TAU})
				"wreck":                                          # an armoured vehicle that still burns: embers on the ground round it
					if put.call({"kind": "tank_vehicle", "x": ox + 2, "y": oy + 2, "w": 4, "h": 2, "col": Color(0.2, 0.21, 0.2)}):
						burn.append(Rect2(Vector2(ox, oy) * TILE, Vector2(8, 6) * TILE))
						m.lights.append({"pos": Vector2(ox + 4.0, oy + 3.0) * TILE, "r": 120.0, "col": Color(1.0, 0.42, 0.14), "a": 0.55, "flicker": true})
						decor.append({"kind": "scorch", "pos": Vector2(ox + 4.0, oy + 4.3) * TILE, "r": 40.0})
				"mast":                                           # a radio mast of the machines, its red light blinking
					if put.call({"kind": "radio_mast", "x": ox + 2, "y": oy + 2, "w": 1, "h": 1}):
						m.lights.append({"pos": Vector2(ox + 2.5, oy + 2.4) * TILE, "r": 60.0, "col": Color(1.0, 0.2, 0.15), "a": 0.45, "flicker": true})
						put.call({"kind": "rubble", "x": ox + 4, "y": oy + 3, "w": 2, "h": 1, "col": RUBBLE[2]})
						put.call({"kind": "barrier", "x": ox, "y": oy + 4, "w": 3, "h": 1, "col": Color(0.3, 0.31, 0.36)})
				"oil":                                            # a tanker's load all over the ground
					if clear.call(ox, oy, 9, 6):
						put.call({"kind": "barrel", "x": ox + 4, "y": oy + 2, "w": 1, "h": 1})
						put.call({"kind": "barrel", "x": ox + 5, "y": oy + 3, "w": 1, "h": 1})
						slow.append(Rect2(Vector2(ox, oy) * TILE, Vector2(9, 6) * TILE))
				"barricade":                                      # a line the last ones held: plated sections, gaps between them
					for k2 in 3:
						put.call({"kind": "barrier", "x": ox + k2 * 4, "y": oy + 2 + (k2 % 2), "w": 3, "h": 1, "col": Color(0.3, 0.31, 0.36)})
					put.call({"kind": "rubble", "x": ox + 2, "y": oy + 5, "w": 2, "h": 1, "col": RUBBLE[0]})
	# ---- what the fighting left on the ground: craters, scorch marks, cracks (not where you begin)
	for q in 170:
		var dp := Vector2(rng.randf_range(EDGE + 3.0, SW - EDGE - 3.0), rng.randf_range(EDGE + 3.0, SH - EDGE - 3.0))
		if dp.distance_to(Vector2(mx, my)) < 5.0:
			continue
		var roll := q % 5
		if roll == 0 and m.free_at(dp * TILE, 14.0):
			decor.append({"kind": "crater", "pos": dp * TILE, "r": rng.randf_range(9.0, 22.0)})
		elif roll <= 2:
			decor.append({"kind": "scorch", "pos": dp * TILE, "r": rng.randf_range(12.0, 30.0)})
		else:
			decor.append({"kind": "crack", "pos": dp * TILE, "r": rng.randf_range(30.0, 70.0), "a": rng.randf() * TAU})
	m.set_meta("sv_decor", decor)
	m.lights.append({"pos": m.spawn, "r": 150.0, "col": Color(1.0, 0.5, 0.45), "a": 0.3})
	# crates standing about (far from each other, not near where you begin)
	var crs: Array = []
	var tries := 0
	while crs.size() < 18 and tries < 900:
		tries += 1
		var cp := Vector2(rng.randi_range(EDGE + 4, SW - EDGE - 5) + 0.5, rng.randi_range(EDGE + 4, SH - EDGE - 5) + 0.5) * TILE
		if m.free_at(cp, 6.0) and cp.distance_to(m.spawn) > 14.0 * TILE and not crs.any(func(c): return (c as Vector2).distance_to(cp) < 22.0 * TILE):
			crs.append(cp)
	m.set_meta("sv_crates", crs)
	m.set_meta("col_hazards", [
		{"kind": "burn", "rects": burn, "name": "Burning wrecks: the embers round them burn whoever stands there.", "dps": 12.0, "dtype": "explosive", "pulse": [], "look": "embers"},
		{"kind": "slow", "rects": slow, "name": "Spilled oil: it holds back whoever walks through it.", "k": 0.55, "look": "oil"}])
	m.set_meta("col_haz_state", {"t": 0.0, "tick": 0.0, "cloud": 2.0, "n": 0})
	return m


## Part 9a (Luz, 23 Nov 2026): Whiteout: a moon of ice, by day; the first stage that is bright. Snow all over, two
## trodden tracks that cross in its middle. What stands in the way: boulders, blocks of ice, clusters of crystals,
## and what a research station left behind, snowed in (containers, snow crawlers, a lookout, a dish; north-east of the
## middle its dome and its mast). Floes of bare ice (map meta "col_hazards", kind "ice": you slide on them), steam
## vents (map meta "sv_vents"; the game makes them burst), and the crates of this stage frozen in, one beside each
## of the first vents (map meta "sv_frozen"). Drifts of snow, hairline cracks in the ice, melted ground round the
## vents (map meta "sv_decor").
const SNOW_ROCK := [Color(0.34, 0.38, 0.47), Color(0.4, 0.43, 0.51), Color(0.3, 0.35, 0.45)]
const STATION := [Color(0.86, 0.42, 0.16), Color(0.8, 0.83, 0.88), Color(0.2, 0.46, 0.62), Color(0.86, 0.72, 0.2)]
const TRACK := 4                   # how wide a trodden track is
const VENTS := 26                  # steam vents on the field …
const VENT_CRATES := 16            # … and how many of them have a crate frozen in beside them

static func _whiteout(stage_id: String, seed_n: int) -> GroundMap:
	var m := GroundMap.new()
	m.pal = DeckGen.palette_for_body({"type": "barren"})
	m.pal["terrain_a"] = Color(0.6, 0.7, 0.86)
	m.pal["terrain_b"] = Color(0.68, 0.77, 0.91)               # (bright, but not white: what your weapons light must still show on it)
	m.pal["terrain_c"] = Color(0.78, 0.86, 0.97)
	m.pal["floor"] = Color(0.6, 0.66, 0.76)
	m.pal["floor2"] = Color(0.66, 0.72, 0.82)
	m.title = "The Colosseum"
	m.hull_top = -60
	m.setup(SW, SH)
	m.fill(0, 0, SW, SH, GroundMap.T.BLOCK, 13)
	m.fill(EDGE, EDGE, SW - EDGE * 2, SH - EDGE * 2, GroundMap.T.FLOOR, 13)
	var mx := SW / 2
	var my := SH / 2
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("sv_%s_%d" % [stage_id, seed_n])
	var taken := {}                                            # tiles nothing may stand on: the tracks, the ice, round the vents
	var ph1 := rng.randf() * TAU
	var ph2 := rng.randf() * TAU
	var track_h := PackedVector2Array()                        # two tracks trodden into the snow, winding a little, crossing in the middle
	var track_v := PackedVector2Array()                        # (drawn over the snow as packed snow, map meta "sv_decor": nothing stands on them)
	for tx in range(EDGE, SW - EDGE):
		var wy := 2.4 * sin(tx * 0.07 + ph1) * clampf(absf(tx - mx) / 14.0, 0.0, 1.0)
		var oy0 := my - TRACK / 2 + int(round(wy))
		track_h.append(Vector2(tx + 0.5, my + wy) * TILE)
		for q in range(-1, TRACK + 1):
			taken[Vector2i(tx, oy0 + q)] = true
	for ty in range(EDGE, SH - EDGE):
		var wx := 2.4 * sin(ty * 0.08 + ph2) * clampf(absf(ty - my) / 14.0, 0.0, 1.0)
		var ox0 := mx - TRACK / 2 + int(round(wx))
		track_v.append(Vector2(mx + wx, ty + 0.5) * TILE)
		for q2 in range(-1, TRACK + 1):
			taken[Vector2i(ox0 + q2, ty)] = true
	var sx := mx + 15                                          # where the station stands: north-east of the middle (no ice, no vent there)
	var sy := my - 26
	var station := Rect2(sx - 9, sy - 2, 26, 11)
	m.spawn = Vector2(mx, my) * TILE
	m.set_meta("from_gate", m.spawn)
	m.set_meta("sv_stage", stage_id)
	m.set_meta("col_vr", stage_id)
	m.set_meta("col_vr_name", "Whiteout")
	m.set_meta("dark", Color(0.86, 0.9, 0.98))                 # by day: only a cool cast over it all
	m.decals.append({"kind": "mat", "x": mx - 2, "y": my - 1, "w": 4, "h": 2, "col": Color(0.2, 0.6, 0.95)})
	m.zones.append({"rect": Rect2(Vector2(mx - 2, my - 1.0) * TILE, Vector2(4.0, 2.0) * TILE), "kind": "sv_giveup", "id": "sv_giveup",
		"title": "End the run: leave the hologram", "col": Color(1.0, 0.45, 0.4), "sign": Vector2(-100, -100)})
	var decor: Array = []
	decor.append({"kind": "track", "pos": track_h[0], "r": TRACK * TILE * 0.8, "pts": track_h, "across": Vector2.DOWN})
	decor.append({"kind": "track", "pos": track_v[0], "r": TRACK * TILE * 0.8, "pts": track_v, "across": Vector2.RIGHT})
	# ---- floes of bare ice: each a round of rows, wider and narrower by chance
	var rows: Array = []                                       # what the game takes for ice: a rect a row
	var floes: Array = []                                      # … and what is drawn: its outline
	var mids: Array = []
	var tries := 0
	while floes.size() < 10 and tries < 400:
		tries += 1
		var frx := rng.randf_range(6.5, 10.5)
		var fry := rng.randf_range(4.0, 6.5)
		var fc := Vector2(rng.randf_range(EDGE + 4.0 + frx, SW - EDGE - 4.0 - frx), rng.randf_range(EDGE + 4.0 + fry, SH - EDGE - 4.0 - fry))
		if fc.distance_to(Vector2(mx, my)) < 17.0 or absf(fc.x - mx) < frx + 6.0 or absf(fc.y - my) < fry + 6.0:
			continue
		if mids.any(func(q): return absf((q[0] as Vector2).x - fc.x) < float(q[1]) + frx + 5.0 and absf((q[0] as Vector2).y - fc.y) < float(q[2]) + fry + 4.0):
			continue
		if Rect2(fc.x - frx - 2.0, fc.y - fry - 2.0, frx * 2.0 + 4.0, fry * 2.0 + 4.0).intersects(station):
			continue
		mids.append([fc, frx, fry])
		var left := PackedVector2Array()
		var right := PackedVector2Array()
		var y0 := int(floor(fc.y - fry))
		var y1 := int(ceil(fc.y + fry))
		for ty2 in range(y0, y1):
			var k := clampf(1.0 - pow((ty2 + 0.5 - fc.y) / fry, 2.0), 0.0, 1.0)
			var hw := frx * sqrt(k)
			var xa := int(round(fc.x - hw * rng.randf_range(0.82, 1.08)))
			var xb := int(round(fc.x + hw * rng.randf_range(0.82, 1.08)))
			if xb - xa < 2:
				continue
			rows.append(Rect2(Vector2(xa, ty2) * TILE, Vector2(xb - xa, 1.0) * TILE))
			left.append(Vector2(xa, ty2 + 0.5) * TILE)
			right.append(Vector2(xb, ty2 + 0.5) * TILE)
			for tx2 in range(xa - 1, xb + 1):
				taken[Vector2i(tx2, ty2)] = true
				taken[Vector2i(tx2, ty2 - 1)] = true
				taken[Vector2i(tx2, ty2 + 1)] = true
		if left.size() < 4:
			mids.pop_back()
			continue
		var poly := PackedVector2Array()
		poly.append((left[0] + right[0]) * 0.5 + Vector2(0.0, -TILE * 0.7))
		for q3 in right.size():
			poly.append(right[q3])
		poly.append((left[left.size() - 1] + right[right.size() - 1]) * 0.5 + Vector2(0.0, TILE * 0.7))
		for q4 in range(left.size() - 1, -1, -1):
			poly.append(left[q4])
		floes.append(poly)
		for hq in 5:                                              # hairline cracks in it
			decor.append({"kind": "hair", "pos": (fc + Vector2(rng.randf_range(-frx, frx) * 0.6, rng.randf_range(-fry, fry) * 0.55)) * TILE, "r": rng.randf_range(26.0, 60.0), "a": rng.randf() * TAU})
	# ---- steam vents, far from each other and from where you begin; a crate frozen in beside each of the first ones
	var vents: Array = []
	var crs: Array = []
	tries = 0
	while vents.size() < VENTS and tries < 3000:
		tries += 1
		var vt := Vector2i(rng.randi_range(EDGE + 5, SW - EDGE - 6), rng.randi_range(EDGE + 5, SH - EDGE - 6))
		var vp := (Vector2(vt) + Vector2(0.5, 0.5)) * TILE
		if taken.has(vt) or vp.distance_to(m.spawn) < 10.0 * TILE or vents.any(func(c): return (c as Vector2).distance_to(vp) < 15.0 * TILE) or station.grow(3.0).has_point(Vector2(vt)):
			continue
		var side := Vector2i(2 if rng.randf() < 0.5 else -2, 0)
		if vents.size() < VENT_CRATES and taken.has(vt + side):
			continue
		vents.append(vp)
		for vy in range(-1, 2):
			for vx in range(-3, 4):
				taken[vt + Vector2i(vx, vy)] = true
		decor.append({"kind": "melt", "pos": vp, "r": 22.0})
		if crs.size() < VENT_CRATES:
			crs.append((Vector2(vt + side) + Vector2(0.5, 0.5)) * TILE)
	m.set_meta("sv_vents", vents)
	m.set_meta("sv_crates", crs)
	m.set_meta("sv_frozen", true)
	m.set_meta("sv_bright", true)                              # (what is only light would not show by day: the game draws shards and beacons with a body to them)
	# is this patch of ground free for something to stand on?
	var clear := func(x: int, y: int, w: int, h: int) -> bool:
		if x < EDGE + 2 or y < EDGE + 2 or x + w > SW - EDGE - 2 or y + h > SH - EDGE - 2:
			return false
		if Vector2(x + w * 0.5, y + h * 0.5).distance_to(Vector2(mx, my)) < 11.0:
			return false
		for yy in range(y, y + h):
			for xx in range(x, x + w):
				if taken.has(Vector2i(xx, yy)) or not GroundMap.walkable_t(m.t_at(xx, yy)):
					return false
		return true
	var put := func(o: Dictionary) -> bool:
		if not clear.call(int(o["x"]), int(o["y"]), int(o.get("w", 1)), int(o.get("h", 1))):
			return false
		m.add_object(o)
		return true
	# ---- the station: two domes and its mast, north-east of the middle
	if put.call({"kind": "dome", "x": sx, "y": sy, "w": 5, "h": 3, "snow": true}):
		m.set_meta("sv_landmark", Vector2(sx + 6.0, sy + 4.0) * TILE)
		put.call({"kind": "dome", "x": sx + 7, "y": sy + 1, "w": 5, "h": 3, "snow": true})
		put.call({"kind": "radio_mast", "x": sx + 13, "y": sy, "w": 2, "h": 1, "rise": 150})
		put.call({"kind": "container", "x": sx - 8, "y": sy + 1, "w": 6, "h": 2, "col": STATION[0], "snow": true})
		put.call({"kind": "container", "x": sx + 4, "y": sy + 6, "w": 6, "h": 2, "col": STATION[2], "snow": true})
		put.call({"kind": "crates", "x": sx + 1, "y": sy + 4, "w": 2, "h": 1, "snow": true})
		for dq in 4:
			decor.append({"kind": "drift", "pos": Vector2(sx - 2.0 + dq * 4.4, sy + 3.6 + (dq % 2) * 0.6) * TILE, "r": 20.0 + (dq % 3) * 6.0, "a": 0.0})
	# ---- the groups of what stands in the way, one to a cell of the field at most
	var kinds: Array = ["rocks", "rocks", "rocks", "ice", "ice", "crystals", "crystals", "crawler", "containers", "containers", "lookout", "dish", "open", "open"]
	var once := {"lookout": 2, "dish": 2}
	for cy in range(EDGE + 2, SH - EDGE - CELL_H, CELL_H):
		for cx in range(EDGE + 2, SW - EDGE - CELL_W, CELL_W):
			if rng.randf() < 0.1:
				continue
			var ox := cx + rng.randi_range(1, 6)
			var oy := cy + rng.randi_range(1, 5)
			var kind := String(kinds[rng.randi() % kinds.size()])
			if once.has(kind):
				if int(once[kind]) <= 0:
					kind = "rocks"
				else:
					once[kind] = int(once[kind]) - 1
			match kind:
				"rocks":                                          # boulders, snow on them, a drift in their lee
					put.call({"kind": "rock", "x": ox, "y": oy, "w": 2, "h": 2, "col": SNOW_ROCK[rng.randi() % SNOW_ROCK.size()], "seed": rng.randi(), "snow": true})
					put.call({"kind": "rock", "x": ox + 4 + rng.randi_range(0, 2), "y": oy + 3, "w": 2, "h": 1, "col": SNOW_ROCK[rng.randi() % SNOW_ROCK.size()], "seed": rng.randi(), "snow": true})
					if rng.randf() < 0.6:
						put.call({"kind": "rock", "x": ox + 1, "y": oy + 5, "w": 1, "h": 1, "col": SNOW_ROCK[rng.randi() % SNOW_ROCK.size()], "seed": rng.randi(), "snow": true})
					decor.append({"kind": "drift", "pos": Vector2(ox + 3.4, oy + 2.4) * TILE, "r": 30.0, "a": 0.0})
				"ice":                                            # blocks of ice pushed up out of the ground
					put.call({"kind": "ice_block", "x": ox, "y": oy + 1, "w": 2, "h": 1, "rise": 18 + rng.randi() % 12, "seed": rng.randi() % 9})
					put.call({"kind": "ice_block", "x": ox + 4, "y": oy + 3 + rng.randi_range(0, 1), "w": 2, "h": 1, "rise": 14 + rng.randi() % 14, "seed": rng.randi() % 9})
					if rng.randf() < 0.5:
						put.call({"kind": "ice_block", "x": ox + 1, "y": oy + 5, "w": 2, "h": 1, "rise": 14 + rng.randi() % 8, "seed": rng.randi() % 9})
					decor.append({"kind": "hair", "pos": Vector2(ox + 2.0, oy + 3.0) * TILE, "r": 50.0, "a": rng.randf() * TAU})
				"crystals":                                       # clusters of crystals in a loose round
					for k2 in 3:
						put.call({"kind": "crystal", "x": ox + [0, 5, 2][k2], "y": oy + [1, 2, 5][k2], "w": 2, "h": 1, "col": [Color(0.45, 0.85, 1.0), Color(0.75, 0.93, 1.0), Color(0.55, 0.7, 1.0)][rng.randi() % 3]})
					m.lights.append({"pos": Vector2(ox + 3.0, oy + 3.0) * TILE, "r": 90.0, "col": Color(0.5, 0.9, 1.0), "a": 0.22})
				"crawler":                                        # a snow crawler left where it froze, what it carried beside it
					put.call({"kind": "crawler", "x": ox, "y": oy, "w": 6, "h": 3, "snow": true})
					put.call({"kind": "crates", "x": ox + 7, "y": oy + 2, "w": 2, "h": 1, "snow": true})
					put.call({"kind": "barrel", "x": ox + 2, "y": oy + 5, "w": 1, "h": 1, "snow": true})
					decor.append({"kind": "drift", "pos": Vector2(ox + 3.0, oy + 3.6) * TILE, "r": 40.0, "a": 0.0})
				"containers":                                     # the station's containers, a lane between them
					put.call({"kind": "container", "x": ox, "y": oy, "w": 6, "h": 2, "col": STATION[rng.randi() % STATION.size()], "snow": true})
					put.call({"kind": "container", "x": ox + rng.randi_range(0, 3), "y": oy + 5, "w": 6, "h": 2, "col": STATION[rng.randi() % STATION.size()], "snow": true})
					decor.append({"kind": "drift", "pos": Vector2(ox + 3.0, oy + 2.6) * TILE, "r": 38.0, "a": 0.0})
				"lookout":
					put.call({"kind": "lookout", "x": ox, "y": oy, "w": 5, "h": 3, "rise": 150})
					put.call({"kind": "crates", "x": ox + 6, "y": oy + 3, "w": 2, "h": 1, "snow": true})
				"dish":
					put.call({"kind": "dish", "x": ox, "y": oy, "w": 6, "h": 3, "rise": 110})
					put.call({"kind": "cable_drum", "x": ox + 7, "y": oy + 3, "w": 2, "h": 1, "snow": true})
				_:                                                # open snow: nothing but drifts
					for k3 in 3:
						decor.append({"kind": "drift", "pos": Vector2(ox + rng.randf_range(0.0, 9.0), oy + rng.randf_range(0.0, 7.0)) * TILE, "r": rng.randf_range(26.0, 46.0), "a": 0.0})
	# ---- drifts of snow all over, hairline cracks here and there (not where you begin)
	for q5 in 150:
		var dp := Vector2(rng.randf_range(EDGE + 3.0, SW - EDGE - 3.0), rng.randf_range(EDGE + 3.0, SH - EDGE - 3.0))
		if dp.distance_to(Vector2(mx, my)) < 5.0 or taken.has(Vector2i(int(dp.x), int(dp.y))):
			continue
		if q5 % 4 == 0:
			decor.append({"kind": "hair", "pos": dp * TILE, "r": rng.randf_range(24.0, 50.0), "a": rng.randf() * TAU})
		else:
			decor.append({"kind": "drift", "pos": dp * TILE, "r": rng.randf_range(14.0, 34.0), "a": 0.0})
	m.set_meta("sv_decor", decor)
	m.lights.append({"pos": m.spawn, "r": 150.0, "col": Color(0.6, 0.95, 1.0), "a": 0.2})
	m.set_meta("col_hazards", [
		{"kind": "ice", "rects": rows, "floes": floes, "look": "floe", "name": "Bare ice: you keep your way on it and turn only slowly."}])
	m.set_meta("col_haz_state", {"t": 0.0, "tick": 0.0, "cloud": 2.0, "n": 0})
	return m
