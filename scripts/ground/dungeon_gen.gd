extends RefCounted
## Package 53a (Luz): a site to explore, generated. Outside the drone's pad on the body's ground, east of it the site
## cut into the rock: rooms on a 3 × 3 grid joined by wide corridors (three tiles – there is fighting here too), the
## walls' faces made wherever a floor has rock above it. The rooms get roles: the entrance (from the pad), guard
## rooms (foes), stores (crates), a control room (a terminal), a tablet room, and the vault at the top right with its
## approach below it: a blast door in the approach's north wall (its box on the wall beside it), the terminal in the
## control room opens it as well, and an air shaft from the room beside the vault is the quiet way round. In the vault
## the target. What lies where is written into `map.poi` for the "possible targets" window.
## The look and who is there come from the theme (data/poi.gd). No class_name: preload it.

const PoiData = preload("res://data/poi.gd")
const ExploreNode = preload("res://scripts/ground/explore.gd")
const TILE := GroundMap.TILE
const T := GroundMap.T
const COLS := 3
const ROWS := 3
const CW := 22                         # a grid cell (tiles)
const CH := 17
const CORR := 3                        # corridor width (tiles) – wide enough to fight in


static func build(body: Dictionary, site: Dictionary, ship_len: float, ship_beam: float) -> GroundMap:
	var theme := String(site.get("theme", "ruin"))
	var th: Dictionary = PoiData.THEMES.get(theme, PoiData.THEMES["ruin"])
	var dg: Dictionary = PoiData.DANGER.get(String(site.get("danger", "yellow")), PoiData.DANGER["yellow"])
	var rng := RandomNumberGenerator.new()
	rng.seed = int(site.get("seed", 53))
	var m := GroundMap.new()
	m.pal = DeckGen.palette_for_body(body).duplicate()
	for key in ["floor", "floor2", "wall", "wall_top", "trim", "accent"]:
		m.pal[key] = th[key]
	m.pal["frame"] = (th["wall"] as Color).darkened(0.25)
	m.title = String(site.get("name", "Site"))
	m.hull_top = -60
	# ---- the pad outside (as at the debug arena)
	var sl := clampi(int(ceil(ship_len / TILE)) + 4, 10, 40)
	var sb := clampi(int(ceil(ship_beam / TILE)) + 4, 7, 20)
	var rx0 := sl + 12                                   # where the site's rock begins
	var W := rx0 + COLS * CW + 3
	var H := maxi(ROWS * CH + 4, sb + 20)
	m.setup(W, H)
	m.fill(0, 0, W, H, T.FLOOR, 13)
	m.fill(rx0, 0, W - rx0, H, T.CAP)
	m.fill(0, 0, rx0, 1, T.BLOCK, 13)
	m.fill(0, H - 1, rx0, 1, T.BLOCK, 13)
	m.fill(0, 0, 1, H, T.BLOCK, 13)
	var px0 := 3
	var py0 := H / 2 - sb / 2 - 2
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
	# ---- the rooms
	var rooms := {}                                        # Vector2i cell -> Rect2i
	for cy in ROWS:
		for cx in COLS:
			var w := rng.randi_range(11, 16)
			var h := rng.randi_range(7, 10)
			var x := rx0 + cx * CW + rng.randi_range(2, CW - w - 2)
			var y := 1 + cy * CH + 3 + rng.randi_range(0, CH - h - 5)
			rooms[Vector2i(cx, cy)] = Rect2i(x, y, w, h)
	var vault_c := Vector2i(COLS - 1, 0)
	var appr_c := Vector2i(COLS - 1, 1)
	# the vault sits over its approach: their columns overlap so the corridor between them runs straight
	var ap: Rect2i = rooms[appr_c]
	var vr: Rect2i = rooms[vault_c]
	vr.position.x = clampi(ap.position.x + ap.size.x / 2 - vr.size.x / 2, rx0 + (COLS - 1) * CW + 1, W - vr.size.x - 2)
	rooms[vault_c] = vr
	var room_floor := int(th["room_floor"])
	for c in rooms:
		var r: Rect2i = rooms[c]
		m.fill(r.position.x, r.position.y, r.size.x, r.size.y, T.FLOOR, room_floor)
	# ---- the corridors: a spanning tree over the grid (not the vault), a loop or two more, the vault only from below
	var edges: Array = []
	var inn: Array = [Vector2i(0, 1)]
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
		var dv2: Vector2i = [Vector2i(1, 0), Vector2i(0, 1)][rng.randi() % 2]
		var b2: Vector2i = a2 + dv2
		if cells.has(b2) and not edges.any(func(e): return (e[0] == a2 and e[1] == b2) or (e[0] == b2 and e[1] == a2)):
			edges.append([a2, b2])
	var hall_floor := int(th["hall_floor"])
	for e2 in edges:
		_corridor(m, rooms[e2[0]], rooms[e2[1]], hall_floor)
	# the way in from the pad: west into the entrance room
	var en: Rect2i = rooms[Vector2i(0, 1)]
	var ecy := en.position.y + en.size.y / 2
	m.fill(px0 + sl + 4, ecy - 1, en.position.x - (px0 + sl + 4), CORR, T.FLOOR, hall_floor)
	# the vault: straight up from its approach, through a blast door in the approach's north wall
	var dx := clampi(ap.position.x + ap.size.x / 2, vr.position.x + 2, vr.end.x - 3)
	m.fill(dx - 1, vr.end.y, CORR, ap.position.y - vr.end.y, T.FLOOR, hall_floor)
	var door_gap := Rect2i(dx - 1, ap.position.y - 3, CORR, 3)
	# ---- the walls' faces: two rows above every floor that has rock above it
	_faces(m)
	m.fill(door_gap.position.x, door_gap.position.y, door_gap.size.x, door_gap.size.y, T.BLOCK, hall_floor)
	# ---- roles
	var others: Array = cells.filter(func(c3): return c3 != Vector2i(0, 1) and c3 != appr_c)
	for i in others.size():
		var j := rng.randi() % others.size()
		var tmp = others[i]
		others[i] = others[j]
		others[j] = tmp
	var control: Vector2i = others[0]
	var stores: Array = [others[1], others[2]]
	var tablet_c: Vector2i = others[3]
	var guards: Array = [others[4], appr_c] if others.size() > 4 else [appr_c]
	var role_of := {Vector2i(0, 1): "entrance", vault_c: "vault", appr_c: "approach", control: "control", tablet_c: "tablets"}
	for s2 in stores:
		role_of[s2] = "store"
	if others.size() > 4:
		role_of[others[4]] = "guard"
	# ---- the things
	var door := ExploreNode.add(m, "blastdoor", Vector2(dx + 0.5, ap.position.y) * TILE, {"tiles": [door_gap.position.x, door_gap.position.y, door_gap.size.x, door_gap.size.y], "seed": rng.randi()})
	var di := m.explore.find(door)
	ExploreNode.add(m, "panel", Vector2(dx + 3.5, ap.position.y) * TILE, {"inside": "button", "door": di, "seed": rng.randi()})
	var cr: Rect2i = rooms[control]
	ExploreNode.add(m, "terminal", Vector2(cr.position.x + cr.size.x - 3, cr.position.y + 1.4) * TILE,
		{"actions": ["door", "data"], "door": di, "seed": rng.randi(), "level": 1 + int(String(site.get("danger", "yellow")) == "red")})
	ExploreNode.add(m, "relic", Vector2(vr.position.x + vr.size.x * 0.5, vr.position.y + vr.size.y * 0.5) * TILE, {"target": true, "seed": rng.randi()})
	m.lights.append({"pos": Vector2(vr.position.x + vr.size.x * 0.5, vr.position.y + vr.size.y * 0.5) * TILE, "r": 60.0, "col": th["light"], "a": 0.4, "flicker": true})
	var tr: Rect2i = rooms[tablet_c]
	var n_tab := 3
	for ti in n_tab:
		ExploreNode.add(m, "tablet", Vector2(tr.position.x + 2.5 + ti * maxf(2.0, (tr.size.x - 5) / 2.0), tr.position.y + 0.9) * TILE, {"seed": rng.randi()})
	var n_cache := 0
	for s3 in stores:
		var sr: Rect2i = rooms[s3]
		for ci in rng.randi_range(2, 3):
			ExploreNode.add(m, "crate", Vector2(sr.position.x + 2.5 + ci * 3, sr.position.y + sr.size.y - 1.5) * TILE,
				{"welded": ci == 0, "seed": rng.randi(), "theme": theme})
			n_cache += 1
	# the air shaft: from the room beside the vault up into the rock and along into the vault
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
	# ---- foes: guard rooms and the approach; the leader by the vault's door
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
	site["foes"] = foes
	# ---- cover and lights in the rooms (not on the things' spots)
	for c4 in rooms:
		var rr: Rect2i = rooms[c4]
		for ck in rng.randi_range(2, 4):                 # the theme's wear: cracks across the floor
			m.decals.append({"kind": "cable", "x": rng.randi_range(rr.position.x + 1, rr.end.x - 3), "y": rng.randi_range(rr.position.y + 1, rr.end.y - 2),
				"dx": rng.randi_range(-30, 30), "dy": rng.randi_range(4, 22)})
		m.lights.append({"pos": Vector2(rr.position.x + rr.size.x * 0.5, rr.position.y + 1) * TILE, "r": 46.0, "col": th["light"], "a": 0.22})
		if role_of.get(c4, "") in ["vault", "tablets", "store"]:
			continue
		for pi in rng.randi_range(1, 3):
			var kind: String = th["props"][rng.randi() % th["props"].size()]
			var ow := 2 if kind != "barrel" else 1
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
					o["col"] = (th["wall"] as Color).darkened(0.15)
					o["seed"] = rng.randi()
				m.add_object(o)
	# ---- what lies where, for the "possible targets" window
	m.set_meta("poi", {"name": String(site.get("name", "")), "theme": theme, "theme_name": String(th["name"]), "levels": 1, "minutes": 15,
		"danger": String(site.get("danger", "yellow")), "danger_name": String(dg["name"]),
		"targets": [["relic", "A relic signature – deep inside, behind a sealed blast door%s" % (" (and an air shaft)" if vent_ok else "")],
			["tablets", "%d carved tablets" % n_tab], ["caches", "%d supply caches, one welded shut" % n_cache],
			["core", "A data core in a control room"], ["foes", "%d hostiles – raiders, a leader by the inner door" % foes.size()]]})
	return m


## A corridor three tiles wide between two rooms: along from the first room's middle, then up or down to the second's.
static func _corridor(m: GroundMap, a: Rect2i, b: Rect2i, fk: int) -> void:
	var ca := a.position + a.size / 2
	var cb := b.position + b.size / 2
	var x0 := mini(ca.x, cb.x)
	var x1 := maxi(ca.x, cb.x)
	for x in range(x0 - 1, x1 + 2):
		for k in CORR:
			var y := ca.y - 1 + k
			if not GroundMap.walkable_t(m.t_at(x, y)):
				m.set_t(x, y, T.FLOOR, fk)
	var y0 := mini(ca.y, cb.y)
	var y1 := maxi(ca.y, cb.y)
	for y2 in range(y0 - 1, y1 + 2):
		for k2 in CORR:
			var xx := cb.x - 1 + k2
			if not GroundMap.walkable_t(m.t_at(xx, y2)):
				m.set_t(xx, y2, T.FLOOR, fk)


## The walls' faces: where a floor has rock right above it, the two rock rows above become the wall's face.
static func _faces(m: GroundMap) -> void:
	var marks: Array = []
	for y in range(2, m.h):
		for x in m.w:
			if GroundMap.walkable_t(m.t_at(x, y)) and m.floor_kind[y * m.w + x] != 13 and m.floor_kind[y * m.w + x] != 14 and m.t_at(x, y - 1) == T.CAP:
				marks.append(Vector2i(x, y))
	for p in marks:
		for d in [1, 2]:
			if m.t_at(p.x, p.y - d) == T.CAP:
				m.set_t(p.x, p.y - d, T.FACE)
