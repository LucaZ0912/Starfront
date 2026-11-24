extends RefCounted
## Package 62a, part 11a (Luz, 24 Nov 2026): the Alien Laboratory, Survivor's fourth stage and the first with walls.
## Nine halls in a grid of three by three (A1 … C3, each RW × RH tiles), every hall joined to its neighbours by a
## corridor CW wide and CL long; the doorways are as wide as the corridors, and no hall is a dead end. You begin in
## the middle one, the Core Hall, beside the great tank.
##   A1, C3 Specimen Hall: rows of tanks, some broken, their nutrient on the floor (it holds back whoever walks in it)
##   A3, C1 Operating Theatre: tables under their lamps, instrument carts
##   A2 Hangar: a parked saucer, landing rings, crates
##   C2 Cryo Vault: pods along the wall and in rows, frost
##   B1 Holding Pens: cells behind fields of force, a guard post
##   B3 Trophy Room: what they took, in stasis: tractors, cows, road signs
##   B2 Core Hall: the great tank, cables running out of it to four rows of consoles
## For the game (map metas): "sv_walls" true; "sv_regions": the halls (0 … 8, row by row) and the corridors as rects of
## tiles; "sv_links": [region, region, a, b] for every doorway, a and b its two ends (art px); "sv_room_ids";
## "sv_grids" (part 11b): the laser grids, {"a", "b", "ph"} each: a doorway's two ends, where it stands in its beat.
## No class_name: preload("res://scripts/ground/survivor_lab.gd").

const TILE := GroundMap.TILE
const T := GroundMap.T
const RW := 80
const RH := 48
const CL := 20
const CW := 12
const X0 := 2
const Y0 := 4
const LW := X0 + RW * 3 + CL * 2 + 2
const LH := Y0 + RH * 3 + CL * 2 + 2
const IDS := ["A1", "A2", "A3", "B1", "B2", "B3", "C1", "C2", "C3"]
const KINDS := ["specimen", "hangar", "theatre", "pens", "core", "trophy", "theatre", "cryo", "specimen"]
const NAMES := {"specimen": "Specimen Hall", "hangar": "Hangar", "theatre": "Operating Theatre", "pens": "Holding Pens", "core": "Core Hall", "trophy": "Trophy Room", "cryo": "Cryo Vault"}
## The colour of each hall's guide line.
const LINES := {"specimen": Color(0.35, 0.95, 0.45), "hangar": Color(1.0, 0.72, 0.25), "theatre": Color(0.85, 0.95, 1.0), "pens": Color(0.72, 0.5, 1.0), "core": Color(1.0, 0.9, 0.4),
	"trophy": Color(1.0, 0.5, 0.85), "cryo": Color(0.45, 0.8, 1.0)}
const GREEN := Color(0.3, 0.95, 0.5)
const VIOLET := Color(0.72, 0.45, 1.0)


## The hall in column c, row r (tiles).
static func room(c: int, r: int) -> Rect2i:
	return Rect2i(X0 + c * (RW + CL), Y0 + r * (RH + CL), RW, RH)


static func build(stage_id: String, seed_n: int) -> GroundMap:
	var m := GroundMap.new()
	m.pal = DeckGen.palette_for_body({"type": "barren"})
	m.pal["floor"] = Color(0.17, 0.2, 0.25)
	m.pal["floor2"] = Color(0.2, 0.235, 0.29)
	m.pal["wall"] = Color(0.7, 0.76, 0.8)
	m.pal["wall_top"] = Color(0.13, 0.16, 0.2)
	m.pal["accent"] = Color(0.45, 1.0, 0.75)
	m.style = "lab"
	m.title = "The Colosseum"
	m.hull_top = -60
	m.setup(LW, LH)
	m.fill(0, 0, LW, LH, T.CAP)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("sv_%s_%d" % [stage_id, seed_n])
	var regs: Array = []
	var links: Array = []
	for r in 3:
		for c in 3:
			var rr := room(c, r)
			regs.append(rr)
			m.fill(rr.position.x, rr.position.y, RW, RH, T.FLOOR, 51)
	var doors: Array = []                                      # what is painted across each doorway: [rect (px), the two halls it joins]
	var runs: Array = []                                       # the corridors, for their guide lines: [rect (tiles), hall, hall, across?]
	for r2 in 3:                                               # the corridors running east and west
		for c2 in 2:
			var a := room(c2, r2)
			var cr := Rect2i(a.end.x, a.position.y + (RH - CW) / 2, CL, CW)
			regs.append(cr)
			m.fill(cr.position.x, cr.position.y, CL, CW, T.FLOOR, 52)
			var ri := regs.size() - 1
			links.append([r2 * 3 + c2, ri, Vector2(cr.position.x, cr.position.y) * TILE, Vector2(cr.position.x, cr.end.y) * TILE])
			links.append([ri, r2 * 3 + c2 + 1, Vector2(cr.end.x, cr.position.y) * TILE, Vector2(cr.end.x, cr.end.y) * TILE])
			doors.append(Rect2i(cr.position.x * TILE - 3, cr.position.y * TILE, 6, CW * TILE))
			doors.append(Rect2i(cr.end.x * TILE - 3, cr.position.y * TILE, 6, CW * TILE))
			runs.append([cr, r2 * 3 + c2, r2 * 3 + c2 + 1, false])
	for r3 in 2:                                               # … and those running north and south
		for c3 in 3:
			var a2 := room(c3, r3)
			var vr := Rect2i(a2.position.x + (RW - CW) / 2, a2.end.y, CW, CL)
			regs.append(vr)
			m.fill(vr.position.x, vr.position.y, CW, CL, T.FLOOR, 52)
			var vi := regs.size() - 1
			links.append([r3 * 3 + c3, vi, Vector2(vr.position.x, vr.position.y) * TILE, Vector2(vr.end.x, vr.position.y) * TILE])
			links.append([vi, (r3 + 1) * 3 + c3, Vector2(vr.position.x, vr.end.y) * TILE, Vector2(vr.end.x, vr.end.y) * TILE])
			doors.append(Rect2i(vr.position.x * TILE, vr.position.y * TILE - 3, CW * TILE, 6))
			doors.append(Rect2i(vr.position.x * TILE, vr.end.y * TILE - 3, CW * TILE, 6))
			runs.append([vr, r3 * 3 + c3, (r3 + 1) * 3 + c3, true])
	for y in range(2, LH):                                     # every wall north of a floor shows its face, two rows high
		for x in LW:
			if m.t_at(x, y) == T.FLOOR and m.t_at(x, y - 1) == T.CAP:
				m.set_t(x, y - 1, T.FACE)
				m.set_t(x, y - 2, T.FACE)
	# ---- painted into the floor: the stripes of the doorways, the guide lines, each hall's letters
	for dr in doors:
		m.decals.append({"kind": "lab_door", "rect": dr})
	for run in runs:
		var rc: Rect2i = run[0]
		var ca: Color = LINES[String(KINDS[int(run[1])])]
		var cb: Color = LINES[String(KINDS[int(run[2])])]
		if bool(run[3]):
			var lx := (rc.position.x * TILE + rc.end.x * TILE) / 2
			m.decals.append({"kind": "lab_line", "rect": Rect2i(lx - 7, (rc.position.y - 4) * TILE, 3, (CL + 8) * TILE), "col": ca})
			m.decals.append({"kind": "lab_line", "rect": Rect2i(lx + 4, (rc.position.y - 4) * TILE, 3, (CL + 8) * TILE), "col": cb})
		else:
			var ly := (rc.position.y * TILE + rc.end.y * TILE) / 2
			m.decals.append({"kind": "lab_line", "rect": Rect2i((rc.position.x - 4) * TILE, ly - 7, (CL + 8) * TILE, 3), "col": ca})
			m.decals.append({"kind": "lab_line", "rect": Rect2i((rc.position.x - 4) * TILE, ly + 4, (CL + 8) * TILE, 3), "col": cb})
		var mid := Vector2(rc.position + rc.size / 2) * TILE
		m.lights.append({"pos": mid, "r": 120.0, "col": Color(0.6, 0.95, 0.9), "a": 0.16})
	var slow: Array = []
	var crs: Array = []
	for q in 9:
		var rr2: Rect2i = regs[q]
		var ox := rr2.position.x
		var oy := rr2.position.y
		var kind := String(KINDS[q])
		var lc: Color = LINES[kind]
		var sign_at := Vector2(ox + RW * 0.5, oy + (RH * 0.5 if kind != "core" else 38.5)) * TILE
		m.decals.append({"kind": "lab_sign", "x": int(sign_at.x), "y": int(sign_at.y), "txt": String(IDS[q]), "k": 8, "col": lc})
		match kind:
			"specimen":
				_specimen(m, rng, ox, oy, slow)
			"theatre":
				_theatre(m, rng, ox, oy)
			"hangar":
				_hangar(m, rng, ox, oy)
			"cryo":
				_cryo(m, rng, ox, oy)
			"pens":
				_pens(m, rng, ox, oy)
			"trophy":
				_trophy(m, rng, ox, oy)
			"core":
				_core(m, ox, oy, slow)
		for spot in ([Vector2(12.5, 24.5), Vector2(68.5, 24.5)] if kind == "core" else [Vector2(30.5, 14.5), Vector2(48.5, 33.5)]):     # crates stand in the halls, not in the corridors
			var cp: Vector2 = (Vector2(ox, oy) + spot) * TILE
			for tr in 12:
				if m.free_at(cp, 7.0):
					crs.append(cp)
					break
				cp += Vector2(rng.randf_range(-1.5, 1.5), rng.randf_range(-1.5, 1.5)) * TILE
	var core: Rect2i = regs[4]
	m.spawn = Vector2(core.position.x + RW * 0.5, core.position.y + 31.0) * TILE
	m.set_meta("from_gate", m.spawn)
	m.set_meta("sv_stage", stage_id)
	m.set_meta("col_vr", stage_id)
	m.set_meta("col_vr_name", "Alien Laboratory")
	m.set_meta("dark", Color(0.6, 0.66, 0.78))                 # indoors, cool and rather dark: what glows shows
	m.set_meta("sv_walls", true)
	m.set_meta("sv_regions", regs)
	m.set_meta("sv_links", links)
	m.set_meta("sv_room_ids", IDS)
	m.set_meta("sv_crates", crs)
	m.set_meta("sv_landmark", Vector2(core.position.x + RW * 0.5, core.position.y + 24.0) * TILE)
	m.decals.append({"kind": "mat", "x": core.position.x + RW / 2 - 2, "y": core.position.y + 30, "w": 4, "h": 2, "col": Color(0.3, 0.9, 1.0)})
	m.zones.append({"rect": Rect2(Vector2(core.position.x + RW / 2 - 2, core.position.y + 30.0) * TILE, Vector2(4.0, 2.0) * TILE), "kind": "sv_giveup", "id": "sv_giveup",
		"title": "End the run: leave the hologram", "col": Color(1.0, 0.45, 0.4), "sign": Vector2(-100, -100)})
	m.lights.append({"pos": m.spawn, "r": 150.0, "col": Color(0.5, 1.0, 0.8), "a": 0.3})
	m.set_meta("col_hazards", [
		{"kind": "slow", "rects": slow, "name": "Spilled nutrient: it holds back whoever walks through it.", "k": 0.55, "look": "nutrient"}])
	# (part 11b) laser grids across the doorways at one end of every other corridor: never one of the Core Hall's, so
	# that nobody begins a run shut in by them
	var grids: Array = []
	for gq in 12:
		if gq % 2 != int(seed_n) % 2:
			continue
		var pick := gq * 2 + (rng.randi() % 2)
		var mate := gq * 2 + (1 if pick == gq * 2 else 0)
		if int(links[pick][0]) == 4 or int(links[pick][1]) == 4:
			pick = mate
		var gl: Array = links[pick]
		grids.append({"a": gl[2], "b": gl[3], "ph": rng.randf() * 5.0})
		for ge in [gl[2], gl[3]]:
			m.decals.append({"kind": "lab_emitter", "x": int((ge as Vector2).x), "y": int((ge as Vector2).y)})
	m.set_meta("sv_grids", grids)
	m.set_meta("col_haz_state", {"t": 0.0, "tick": 0.0, "cloud": 2.0, "n": 0})
	return m


## Something stands here if its whole footprint is free floor.
static func _put(m: GroundMap, o: Dictionary) -> bool:
	for yy in range(int(o["y"]), int(o["y"]) + int(o.get("h", 1))):
		for xx in range(int(o["x"]), int(o["x"]) + int(o.get("w", 1))):
			if m.t_at(xx, yy) != T.FLOOR:
				return false
	m.add_object(o)
	return true


## The columns something stands in either side of a hall's middle lane (step apart, w wide).
static func _cols(first: int, step: int, count: int, w: int) -> Array:
	var out: Array = []
	for k in count:
		out.append(first + k * step)
	for k2 in count:
		out.append(RW - first - w - k2 * step)
	return out


static func _specimen(m: GroundMap, rng: RandomNumberGenerator, ox: int, oy: int, slow: Array) -> void:
	var broken := 0
	for ty in [4, 9, 37, 42]:
		for tx in _cols(4, 5, 5, 2):
			var sd := rng.randi() % 5
			var burst: bool = broken < 3 and rng.randf() < 0.07 and tx > 5 and tx < RW - 8
			if burst:
				sd = 9
				broken += 1
				slow.append(Rect2(Vector2(ox + tx - 2, oy + ty + 1) * TILE, Vector2(6, 3) * TILE))
			_put(m, {"kind": "spec_tank", "x": ox + tx, "y": oy + ty, "w": 2, "h": 1, "rise": 28, "seed": sd})
			if not burst and (tx / 5 + ty) % 2 == 0:
				m.lights.append({"pos": Vector2(ox + tx + 1.0, oy + ty - 0.4) * TILE, "r": 52.0, "col": GREEN, "a": 0.3})


static func _theatre(m: GroundMap, rng: RandomNumberGenerator, ox: int, oy: int) -> void:
	for ty in [5, 11, 35, 41]:
		for tx in [6, 20, RW - 23, RW - 9]:
			_put(m, {"kind": "op_table", "x": ox + tx, "y": oy + ty, "w": 3, "h": 2, "rise": 26, "seed": rng.randi() % 6})
			if rng.randf() < 0.7:
				_put(m, {"kind": "instr_cart", "x": ox + tx + 4, "y": oy + ty + (rng.randi() % 2), "w": 1, "h": 1, "rise": 10})
			m.lights.append({"pos": Vector2(ox + tx + 1.5, oy + ty + 0.6) * TILE, "r": 46.0, "col": Color(1.0, 0.97, 0.82), "a": 0.34})


static func _hangar(m: GroundMap, _rng: RandomNumberGenerator, ox: int, oy: int) -> void:
	m.decals.append({"kind": "lab_ring", "x": (ox + 40) * TILE, "y": (oy + 9) * TILE, "r": 124, "col": LINES["hangar"]})      # the ring the saucer stands in, two that are empty
	m.decals.append({"kind": "lab_ring", "x": (ox + 16) * TILE, "y": (oy + 40) * TILE, "r": 96, "col": LINES["hangar"]})
	m.decals.append({"kind": "lab_ring", "x": (ox + 64) * TILE, "y": (oy + 40) * TILE, "r": 96, "col": LINES["hangar"]})
	_put(m, {"kind": "saucer", "x": ox + 33, "y": oy + 6, "w": 14, "h": 6, "rise": 44})
	m.lights.append({"pos": Vector2(ox + 40.0, oy + 11.0) * TILE, "r": 150.0, "col": GREEN, "a": 0.3})
	m.lights.append({"pos": Vector2(ox + 40.0, oy + 5.0) * TILE, "r": 90.0, "col": Color(0.6, 1.0, 0.95), "a": 0.3})
	for c in [[3, 3], [6, 3], [3, 5], [74, 3], [71, 4], [3, 44], [6, 43], [75, 44], [72, 43]]:
		_put(m, {"kind": "crates", "x": ox + int(c[0]), "y": oy + int(c[1]), "w": 2, "h": 1})
	for b in [[9, 4], [70, 6], [9, 44], [69, 44]]:
		_put(m, {"kind": "barrel", "x": ox + int(b[0]), "y": oy + int(b[1]), "w": 1, "h": 1})
	for l in [[16, 40], [64, 40]]:
		m.lights.append({"pos": Vector2(ox + int(l[0]), oy + int(l[1])) * TILE, "r": 100.0, "col": LINES["hangar"], "a": 0.18})


static func _cryo(m: GroundMap, rng: RandomNumberGenerator, ox: int, oy: int) -> void:
	var ice := Color(0.55, 0.85, 1.0)
	for k in 10:                                               # along the north wall
		for tx in [2 + k * 3, RW - 4 - k * 3]:
			_put(m, {"kind": "cryo_pod", "x": ox + tx, "y": oy, "w": 2, "h": 1, "rise": 30, "seed": rng.randi() % 20})
	for ty in [8, 36, 42]:                                     # … and in rows
		for tx2 in _cols(4, 5, 5, 2):
			_put(m, {"kind": "cryo_pod", "x": ox + tx2, "y": oy + ty, "w": 2, "h": 1, "rise": 30, "seed": rng.randi() % 20})
			if (tx2 / 5) % 2 == 0:
				m.decals.append({"kind": "lab_frost", "x": (ox + tx2 + 1) * TILE, "y": (oy + ty + 2) * TILE, "r": 30})
				m.lights.append({"pos": Vector2(ox + tx2 + 1.0, oy + ty) * TILE, "r": 56.0, "col": ice, "a": 0.26})
	for fx in range(4, RW - 2, 7):
		m.decals.append({"kind": "lab_frost", "x": (ox + fx) * TILE, "y": (oy + 2) * TILE, "r": 34})
	for fq in 9:                                               # frost over the floor, heavier where no door is (the south)
		m.decals.append({"kind": "lab_frost", "x": (ox + 34 + (fq % 3) * 6) * TILE, "y": (oy + 34 + (fq / 3) * 5) * TILE, "r": 44})
	m.lights.append({"pos": Vector2(ox + 40.0, oy + 40.0) * TILE, "r": 130.0, "col": ice, "a": 0.2})
	m.lights.append({"pos": Vector2(ox + 16.0, oy + 1.0) * TILE, "r": 130.0, "col": ice, "a": 0.2})
	m.lights.append({"pos": Vector2(ox + 64.0, oy + 1.0) * TILE, "r": 130.0, "col": ice, "a": 0.2})


static func _pens(m: GroundMap, rng: RandomNumberGenerator, ox: int, oy: int) -> void:
	for ty in [0, 9, 33, 42]:
		for k in 5:
			for tx in [1 + k * 6, RW - 6 - k * 6]:
				_put(m, {"kind": "pen_cell", "x": ox + tx, "y": oy + ty, "w": 5, "h": 3, "rise": 26, "seed": rng.randi() % 8})
				if k % 2 == 0:
					m.lights.append({"pos": Vector2(ox + tx + 2.5, oy + ty + 3.2) * TILE, "r": 60.0, "col": VIOLET, "a": 0.24})
	for cy in [19, 28]:                                        # the guard post, where no door is (the west)
		_put(m, {"kind": "console_row", "x": ox + 4, "y": oy + cy, "w": 5, "h": 1})
		m.lights.append({"pos": Vector2(ox + 6.5, oy + cy + 1.0) * TILE, "r": 60.0, "col": GREEN, "a": 0.22})


static func _trophy(m: GroundMap, _rng: RandomNumberGenerator, ox: int, oy: int) -> void:
	var held: Array = [["tractor", 8, 6], ["cow", 22, 7], ["sign", 28, 12], ["cow", 54, 7], ["empty", 64, 5], ["sign", 71, 10],
		["empty", 8, 36], ["cow", 15, 41], ["sign", 26, 38], ["empty", 51, 41], ["tractor", 61, 37], ["sign", 74, 43],
		["empty", 56, 20], ["cow", 64, 25], ["empty", 72, 19]]                                # (the last three where no door is: the east)
	for h in held:
		var what := String(h[0])
		var sz := Vector2i(5, 3) if what == "tractor" else (Vector2i(3, 2) if what == "cow" else (Vector2i(2, 1) if what == "sign" else Vector2i(3, 2)))
		var rise := 44 if what == "tractor" else (40 if what == "sign" else 36)
		if _put(m, {"kind": "stasis", "x": ox + int(h[1]), "y": oy + int(h[2]), "w": sz.x, "h": sz.y, "rise": rise, "species": what}):
			m.lights.append({"pos": Vector2(ox + int(h[1]) + sz.x * 0.5, oy + int(h[2]) + sz.y * 0.5) * TILE, "r": 64.0, "col": VIOLET, "a": 0.3})


static func _core(m: GroundMap, ox: int, oy: int, slow: Array) -> void:
	var tank := Vector2((ox + 40) * TILE, (oy + 25) * TILE)
	for c in [[14, 8], [61, 8], [14, 39], [61, 39]]:           # four rows of consoles, a cable from the tank to each
		var cx := ox + int(c[0])
		var cy := oy + int(c[1])
		var at := Vector2(cx + 2.5, cy + 0.5) * TILE
		var side := -1.0 if int(c[0]) < 40 else 1.0
		var pts := PackedVector2Array([tank + Vector2(side * 60.0, 0.0), Vector2(tank.x + side * 110.0, tank.y), Vector2(tank.x + side * 110.0, at.y), Vector2(at.x - side * 30.0, at.y)])
		m.decals.append({"kind": "lab_cable", "pts": pts, "col": GREEN})
		_put(m, {"kind": "console_row", "x": cx, "y": cy, "w": 5, "h": 1})
		m.lights.append({"pos": at + Vector2(0.0, 10.0), "r": 60.0, "col": GREEN, "a": 0.22})
	for c2 in [[28, 12], [50, 12], [28, 35], [50, 35]]:        # four of the small tanks round it
		_put(m, {"kind": "spec_tank", "x": ox + int(c2[0]), "y": oy + int(c2[1]), "w": 2, "h": 1, "rise": 28, "seed": int(c2[0]) + int(c2[1])})
		m.lights.append({"pos": Vector2(ox + int(c2[0]) + 1.0, oy + int(c2[1]) - 0.4) * TILE, "r": 52.0, "col": GREEN, "a": 0.3})
	_put(m, {"kind": "big_tank", "x": ox + 36, "y": oy + 22, "w": 8, "h": 4, "rise": 64})
	m.lights.append({"pos": tank + Vector2(0.0, -40.0), "r": 190.0, "col": GREEN, "a": 0.36})
	slow.append(Rect2(Vector2(ox + 45, oy + 21) * TILE, Vector2(6, 4) * TILE))      # it leaks
