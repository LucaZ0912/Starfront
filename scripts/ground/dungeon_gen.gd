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


# ---------------------------------------------------------------- inside

static func build_inside(body: Dictionary, site: Dictionary) -> GroundMap:
	var th := _theme(site)
	var theme := String(site.get("theme", "precursor"))
	var dg: Dictionary = PoiData.DANGER.get(String(site.get("danger", "yellow")), PoiData.DANGER["yellow"])
	var rng := RandomNumberGenerator.new()
	rng.seed = int(site.get("seed", 53))
	var m := GroundMap.new()
	_palette(m, body, th)
	m.title = String(site.get("name", "Site"))
	m.hull_top = -60
	var W := COLS * CW + 4
	var H := ROWS * CH + 4
	m.setup(W, H)
	m.fill(0, 0, W, H, T.CAP)
	var rooms := {}
	for cy in ROWS:
		for cx in COLS:
			var w := rng.randi_range(11, 16)
			var h := rng.randi_range(7, 10)
			var x := 2 + cx * CW + rng.randi_range(1, CW - w - 1)
			var y := 1 + cy * CH + 3 + rng.randi_range(0, CH - h - 5)
			rooms[Vector2i(cx, cy)] = Rect2i(x, y, w, h)
	var entr_c := Vector2i(1, ROWS - 1)
	var vault_c := Vector2i(COLS - 1, 0)
	var appr_c := Vector2i(COLS - 1, 1)
	var ap: Rect2i = rooms[appr_c]
	var vr: Rect2i = rooms[vault_c]
	vr.position.x = clampi(ap.position.x + ap.size.x / 2 - vr.size.x / 2, 2 + (COLS - 1) * CW + 1, W - vr.size.x - 2)
	rooms[vault_c] = vr
	var rf := int(th["room_floor"])
	for c in rooms:
		var r: Rect2i = rooms[c]
		m.fill(r.position.x, r.position.y, r.size.x, r.size.y, T.FLOOR, rf)
	# the corridors: a spanning tree from the entrance (not the vault), a loop or two more
	var edges: Array = []
	var inn: Array = [entr_c]
	var cells: Array = []
	for c2 in rooms:
		if c2 != vault_c:
			cells.append(c2)
	while inn.size() < cells.size():
		var cand: Array = []
		for a in inn:
			for dv in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var b: Vector2i = a + dv
				if cells.has(b) and not inn.has(b):
					cand.append([a, b])
		var pick: Array = cand[rng.randi() % cand.size()]
		edges.append(pick)
		inn.append(pick[1])
	for extra in 2:
		var a2: Vector2i = cells[rng.randi() % cells.size()]
		var b2: Vector2i = a2 + [Vector2i(1, 0), Vector2i(0, 1)][rng.randi() % 2]
		if cells.has(b2) and not edges.any(func(e): return (e[0] == a2 and e[1] == b2) or (e[0] == b2 and e[1] == a2)):
			edges.append([a2, b2])
	var hf := int(th["hall_floor"])
	for e2 in edges:
		_corridor(m, rooms[e2[0]], rooms[e2[1]], hf)
	# the vault: straight up from its approach through the theme's door
	var dx := clampi(ap.position.x + ap.size.x / 2, vr.position.x + 2, vr.end.x - 3)
	m.fill(dx - 1, vr.end.y, CORR, ap.position.y - vr.end.y, T.FLOOR, hf)
	var door_gap := Rect2i(dx - 1, ap.position.y - 3, CORR, 3)
	_faces(m)
	m.fill(door_gap.position.x, door_gap.position.y, door_gap.size.x, door_gap.size.y, T.BLOCK, hf)
	# the entrance hall: the way back out at its foot
	var en: Rect2i = rooms[entr_c]
	m.spawn = Vector2(en.position.x + en.size.x * 0.5, en.end.y - 1.2) * TILE
	m.zones.append({"rect": Rect2(Vector2(en.position.x + en.size.x * 0.5 - 2, en.end.y - 1.0) * TILE, Vector2(4, 1.0) * TILE), "kind": "dungeon_out",
		"id": "dungeon_out", "title": "Back out into the open", "col": Color(0.4, 1.0, 0.6), "sign": Vector2(-100, -100)})
	m.decals.append({"kind": "stripes", "x": int(en.position.x + en.size.x * 0.5) - 2, "y": en.end.y - 1, "w": 4, "h": 1})
	# ---- roles
	var others: Array = cells.filter(func(c3): return c3 != entr_c and c3 != appr_c)
	for i in others.size():
		var j := rng.randi() % others.size()
		var tmp = others[i]
		others[i] = others[j]
		others[j] = tmp
	var control: Vector2i = others[0]
	var stores: Array = [others[1], others[2]]
	var tablet_c: Vector2i = others[3]
	var guards: Array = [appr_c] + others.slice(4)
	var role_of := {entr_c: "entrance", vault_c: "vault", appr_c: "approach", control: "control", tablet_c: "tablets"}
	for s2 in stores:
		role_of[s2] = "store"
	var style := String(th.get("style", ""))
	# ---- the things: the door, its panel, the guarded relic, the computer, tablets, caches, the shaft, panels
	var door := ExploreNode.add(m, String(th.get("door", "blastdoor")), Vector2(dx + 0.5, ap.position.y) * TILE,
		{"tiles": [door_gap.position.x, door_gap.position.y, door_gap.size.x, door_gap.size.y], "seed": rng.randi()})
	var di := m.explore.find(door)
	ExploreNode.add(m, "panel", Vector2(dx + 3.5, ap.position.y) * TILE, {"inside": "button", "door": di, "style": style, "seed": rng.randi()})
	var rc := Vector2(vr.position.x + vr.size.x * 0.5, vr.position.y + vr.size.y * 0.5 + 0.4)
	var guard := {}
	var ci := -1
	if String(th.get("guard", "")) == "crystals":
		var gt := Rect2i(int(rc.x) - 2, int(rc.y) - 1, 4, 2)
		m.fill(gt.position.x, gt.position.y, gt.size.x, gt.size.y, T.BLOCK, rf)
		guard = ExploreNode.add(m, "crystals", rc * TILE + Vector2(0, 4), {"tiles": [gt.position.x, gt.position.y, gt.size.x, gt.size.y], "no_zone": true})
		ci = m.explore.find(guard)
		ExploreNode.add(m, "panel", Vector2(vr.position.x + 2.5, vr.position.y) * TILE, {"inside": "button", "effect": "crystals", "cage": ci, "wall": true, "style": style, "seed": rng.randi(), "shape": "round"})
	var relic := {"target": true, "seed": rng.randi(), "no_zone": true}
	if ci >= 0:
		relic["cage"] = ci
	ExploreNode.add(m, "relic", rc * TILE, relic)
	m.lights.append({"pos": rc * TILE, "r": 60.0, "col": th["light"], "a": 0.4, "flicker": true})
	var cr: Rect2i = rooms[control]
	var acts: Array = ["door", "data"]
	if ci >= 0:
		acts = ["door", "crystals", "data"]
	var term := {"actions": acts, "door": di, "seed": rng.randi(), "style": String(th.get("computer", "")), "level": 1 + int(String(site.get("danger", "yellow")) == "red")}
	if ci >= 0:
		term["cage"] = ci
	ExploreNode.add(m, "terminal", Vector2(cr.position.x + cr.size.x - 3, cr.position.y + 1.6) * TILE, term)
	var tr: Rect2i = rooms[tablet_c]
	for ti in 3:
		ExploreNode.add(m, "tablet", Vector2(tr.position.x + 2.5 + ti * maxf(2.0, (tr.size.x - 5) / 2.0), tr.position.y + 0.9) * TILE, {"seed": rng.randi()})
	var n_cache := 0
	for s3 in stores:
		var sr: Rect2i = rooms[s3]
		for cj in rng.randi_range(2, 3):
			ExploreNode.add(m, "crate", Vector2(sr.position.x + 2.5 + cj * 3, sr.position.y + sr.size.y - 1.5) * TILE, {"welded": cj == 0, "seed": rng.randi(), "theme": theme})
			n_cache += 1
	# panels on other walls: a trap (an EMP) or a few credits behind them
	var n_trap := 0
	for pc in [guards[0] if guards.size() > 1 else control, tablet_c]:
		var prr: Rect2i = rooms[pc]
		if pc == appr_c:
			continue
		var trap := rng.randf() < 0.55
		n_trap += int(trap)
		ExploreNode.add(m, "panel", Vector2(prr.position.x + 2.5, prr.position.y) * TILE, {"inside": "button", "effect": "emp" if trap else "cache",
			"trap": trap, "wall": true, "style": style, "seed": rng.randi(), "shape": ["rounded", "hex", "arch"][rng.randi() % 3]})
	# the air shaft from the room beside the vault
	var side_c := Vector2i(COLS - 2, 0)
	var vent_ok := false
	if rooms.has(side_c):
		var sr2: Rect2i = rooms[side_c]
		var vx := sr2.end.x - 3
		var yd := mini(sr2.position.y, vr.position.y) - 3
		var tx := vr.position.x + 1
		var duct: Array = []
		for yy in range(sr2.position.y - 1, yd - 1, -1):
			duct.append([vx, yy])
		for xx in range(vx + 1, tx + 1):
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
			ExploreNode.add(m, "vent_end", Vector2(tx + 1, vr.position.y) * TILE, {"no_zone": true, "vent": m.explore.find(vent)})
			vent_ok = true
	# ---- foes
	var foes: Array = []
	var tiers: Array = dg["tiers"]
	for gc in guards:
		var gr: Rect2i = rooms[gc]
		var n_g := rng.randi_range(int(dg["guards"][0]), int(dg["guards"][1]))
		for gi in n_g:
			var p := (Vector2(gr.position.x + 2 + rng.randf() * (gr.size.x - 4), gr.position.y + 1.5 + rng.randf() * (gr.size.y - 3))) * TILE
			if m.free_at(p, 6.0):
				m.foe_spawns.append(p)
				foes.append("%s@%s" % [String(th["foes"][rng.randi() % th["foes"].size()]), String(tiers[rng.randi() % tiers.size()])])
	var lp := Vector2(dx + 0.5, ap.position.y + 3.0) * TILE
	if m.free_at(lp, 6.0):
		m.foe_spawns.append(lp)
		foes.append("%s@%s" % [String(th["leader"]), String(dg["leader"])])
	m.set_meta("foes", foes)
	# ---- cover and lights
	for c4 in rooms:
		var rr: Rect2i = rooms[c4]
		m.lights.append({"pos": Vector2(rr.position.x + rr.size.x * 0.5, rr.position.y + 1) * TILE, "r": 46.0, "col": th["light"], "a": 0.2})
		if role_of.get(c4, "") in ["vault", "tablets", "store", "entrance"]:
			continue
		for pi in rng.randi_range(2, 3):
			var kind: String = th["props"][rng.randi() % th["props"].size()]
			var ow := 3 if kind == "pillar_fallen" else 2
			var ox := rng.randi_range(rr.position.x + 2, rr.end.x - 2 - ow)
			var oy := rng.randi_range(rr.position.y + 2, rr.end.y - 3)
			var ok := true
			for yy3 in range(oy - 1, oy + 2):
				for xx3 in range(ox - 1, ox + ow + 1):
					if not GroundMap.walkable_t(m.t_at(xx3, yy3)):
						ok = false
			for d0 in m.explore:
				if (d0["pos"] as Vector2).distance_to(Vector2(ox + 1, oy) * TILE) < 40.0:
					ok = false
			if ok:
				var o := {"kind": kind, "x": ox, "y": oy, "w": ow, "h": 1}
				if kind == "rock":
					o["col"] = (th["wall"] as Color).darkened(0.2)
					o["seed"] = rng.randi()
				m.add_object(o)
	if bool(th.get("fog", false)):
		var fr: Array = []                                   # low over the rooms' floors, not over the solid mass
		for c5 in rooms:
			var r5: Rect2i = rooms[c5]
			fr.append(Rect2(Vector2(r5.position.x, r5.position.y + 1) * TILE, Vector2(r5.size.x, r5.size.y - 1.6) * TILE))
		m.set_meta("fog", fr)
	m.set_meta("poi", {"name": String(site.get("name", "")), "theme": theme, "theme_name": String(th["name"]), "levels": 1, "minutes": 15,
		"danger": String(site.get("danger", "yellow")), "danger_name": String(dg["name"]),
		"targets": [["relic", "A relic signature – deep inside, behind an old door%s%s" % [", guarded by floating crystals" if ci >= 0 else "", " (and an air shaft)" if vent_ok else ""]],
			["tablets", "3 carved tablets"], ["caches", "%d supply caches, one welded shut" % n_cache],
			["core", "Their computer in a control room"], ["foes", "%d hostiles – raiders, a leader by the inner door" % foes.size()]]})
	return m


## A corridor three tiles wide between two rooms: along from the first room's middle, then up or down to the second's.
static func _corridor(m: GroundMap, a: Rect2i, b: Rect2i, fk: int) -> void:
	var ca := a.position + a.size / 2
	var cb := b.position + b.size / 2
	for x in range(mini(ca.x, cb.x) - 1, maxi(ca.x, cb.x) + 2):
		for k in CORR:
			if not GroundMap.walkable_t(m.t_at(x, ca.y - 1 + k)):
				m.set_t(x, ca.y - 1 + k, T.FLOOR, fk)
	for y2 in range(mini(ca.y, cb.y) - 1, maxi(ca.y, cb.y) + 2):
		for k2 in CORR:
			if not GroundMap.walkable_t(m.t_at(cb.x - 1 + k2, y2)):
				m.set_t(cb.x - 1 + k2, y2, T.FLOOR, fk)


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
