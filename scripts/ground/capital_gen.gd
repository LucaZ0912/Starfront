extends RefCounted
## Package 54c (Luz): the hand-built places of the capitals. Neo Kallipolis on Agora (Landfall, the Assembly): the
## Plaza of the Vote before the Senate (mockup_54c_kallipolis), the Senate's lobby – the party office for donations,
## the lobbyist's corner for a bribe, the bill of the day (mockup_54c_senat_lobby) – and the gallery high over the
## plenary chamber with the voting stand (mockup_54c_senat_galerie; the chamber itself is drawn by SenateChamber).
## Built from the Museum's pieces where they fit (white stone, columns, stairs, gates). No class_name: preload it.

const T := GroundMap.T
const TILE := GroundMap.TILE
const MuseumGen = preload("res://scripts/ground/museum_gen.gd")
const ASSEMBLY_BLUE := Color(0.2, 0.4, 0.8)
const WARM := Color(1.0, 0.92, 0.78)


static func _go(m: GroundMap, r: Rect2, to: String, at: String, title: String, col: Color) -> void:
	m.zones.append({"rect": Rect2(r.position * TILE, r.size * TILE), "kind": "museum_go", "id": "capital_go", "to": to, "at": at,
		"title": title, "col": col, "sign": Vector2(-100, -100)})


## 54c (Luz): a sign on two posts standing on the floor (its feet at `foot`, in tiles) – not one hanging from nothing.
static func _stand_sign(m: GroundMap, text: String, foot: Vector2, col: Color) -> void:
	m.zones.append({"rect": Rect2(), "kind": "label", "id": "m_label", "title": text, "col": col, "stand": 12, "sign": foot * TILE - Vector2(0, 16)})


static func _zone(m: GroundMap, r: Rect2, kind: String, title: String, col: Color) -> void:
	m.zones.append({"rect": Rect2(r.position * TILE, r.size * TILE), "kind": kind, "id": kind, "title": title, "col": col, "sign": Vector2(-100, -100)})


# ---------------------------------------------------------------- the Plaza of the Vote

static func build_senate_plaza(station: Dictionary, body: Dictionary) -> GroundMap:
	var m := GroundMap.new()
	MuseumGen._pal(m, body)
	m.pal["floor"] = Color(0.86, 0.85, 0.82)
	m.pal["floor2"] = Color(0.74, 0.73, 0.7)
	m.style = "plaza"
	m.title = "Neo Kallipolis – Plaza of the Vote"
	m.hull_top = -9999
	var W := 66
	var H := 34
	m.setup(W, H)
	m.fill(0, 0, W, H, T.FLOOR, 30)
	m.fill(0, H - 1, W, 1, T.BLOCK, 30)
	m.fill(0, 0, 1, H, T.BLOCK, 30)
	m.fill(W - 1, 0, 1, H, T.BLOCK, 30)
	# the lift kiosk in the west
	var KX := 9
	m.fill(0, 0, KX, 10, T.CAP)
	m.fill(0, 10, KX, 3, T.FACE)
	for lx0 in [1, 5]:
		m.face_deco.append({"kind": "lift", "x": lx0, "y": 12, "w": 2, "col": Color(0.4, 1.0, 0.6)})
		m.lifts.append({"x": lx0, "y": 12, "w": 2})
	m.zones.append({"rect": Rect2(Vector2(1, 13) * TILE, Vector2(6, 1.4) * TILE), "kind": "lift", "id": "lift",
		"title": "Lift – back down into the city", "col": Color(0.4, 1.0, 0.6), "sign": Vector2(4.5, 10.2) * TILE})
	m.spawn = Vector2(4.5, 14.6) * TILE
	# the civic buildings either side of the Senate: white, their glass bands, the Assembly's banners
	for wing in [[KX, 18], [48, W]]:
		var wx0: int = wing[0]
		var wx1: int = wing[1]
		m.fill(wx0, 0, wx1 - wx0, 10, T.CAP)
		m.fill(wx0, 10, wx1 - wx0, 3, T.FACE)
		m.face_deco.append({"kind": "senate_front", "x": wx0, "y": 10, "w": wx1 - wx0, "rows": 3})
		for bx in range(wx0 + 2, wx1 - 1, 5):
			m.face_deco.append({"kind": "holo_banner", "x": bx, "y": 10, "w": 1, "col": ASSEMBLY_BLUE})
	# the Senate: its roof with the glass dome over the chamber, its front – columns, the bronze doors, the great stair
	var SX := 18
	var SW := 30
	m.fill(SX, 0, SW, 13, T.CAP)
	m.fill(SX, 13, SW, 3, T.FACE)
	m.decals.append({"kind": "senate_roof", "x": SX, "y": 0, "w": SW, "h": 13})       # (Luz: more sci-fi)
	var dx := SX + SW / 2 - 2
	m.face_deco.append({"kind": "senate_front", "x": SX, "y": 13, "w": SW, "rows": 3})
	m.face_deco.append({"kind": "senate_doors", "x": dx, "y": 13, "w": 4})
	for bx2 in [SX + 2, SX + 6, SX + SW - 7, SX + SW - 3]:
		m.face_deco.append({"kind": "holo_banner", "x": bx2, "y": 13, "w": 1, "col": ASSEMBLY_BLUE})
	m.decals.append({"kind": "steps_lit", "x": SX, "y": 16, "w": SW, "h": 3})     # flush with the front (Luz)
	for cx in range(SX + 1, SX + SW, 3):
		if cx >= dx - 1 and cx <= dx + 4:
			continue
		m.add_object({"kind": "pylon", "x": cx, "y": 16, "w": 1, "h": 1})
		m.lights.append({"pos": Vector2(cx + 0.5, 15.5) * TILE, "r": 22.0, "col": Color(0.45, 0.85, 1.0), "a": 0.3})
	MuseumGen._label(m, "THE SENATE OF THE ASSEMBLY", Vector2(dx + 2, 12.6), Color(0.95, 0.85, 0.55))
	_go(m, Rect2(dx, 16, 4, 1.6), "senate", "from_plaza", "Into the Senate", Color(1.0, 0.85, 0.5))
	m.set_meta("from_senate", Vector2(dx + 2, 18.4) * TILE)
	m.set_meta("door_front", Vector2(dx + 2, 18.4) * TILE)
	m.lights.append({"pos": Vector2(dx + 2, 17) * TILE, "r": 90.0, "col": Color(1.0, 0.85, 0.6), "a": 0.5})
	# the plaza: the avenue to the doors, the founders' fountain in the middle
	m.decals.append({"kind": "path_m", "x": dx, "y": 19, "w": 4, "h": 4})
	var fx := SX + SW / 2 - 2
	m.add_object({"kind": "fountain", "x": fx, "y": 25, "w": 4, "h": 2})
	m.fill(fx, 25, 4, 2, T.BLOCK)
	for st in [[fx - 3, 24, "suit_civil"], [fx + 1, 23, "suit_survey"], [fx + 5, 24, "suit_mil_light"]]:
		m.add_object({"kind": "holo_statue", "x": int(st[0]), "y": int(st[1]), "w": 2, "h": 1, "seed": 540 + int(st[0]), "species": String(st[2])})
	m.add_object({"kind": "plaque_stone", "x": fx + 1, "y": 28, "w": 2, "h": 1})     # (Luz) a bronze plaque on a stone: THE FOUNDERS
	m.lights.append({"pos": Vector2(fx + 2, 25.5) * TILE, "r": 70.0, "col": Color(0.6, 0.85, 1.0), "a": 0.3})
	for tp in [Vector2i(11, 18), Vector2i(52, 18), Vector2i(11, 28), Vector2i(52, 28)]:
		m.add_object({"kind": "planter", "x": tp.x, "y": tp.y, "w": 3, "h": 1, "col": Color(0.78, 0.79, 0.82)})
		m.add_object({"kind": "tree", "x": tp.x, "y": tp.y - 1, "w": 3, "h": 1, "rise": 72})
	for lp in [Vector2i(17, 22), Vector2i(47, 22), Vector2i(17, 30), Vector2i(47, 30), Vector2i(dx - 2, 21), Vector2i(dx + 5, 21)]:
		m.add_object({"kind": "pylon", "x": lp.x, "y": lp.y, "w": 1, "h": 1})
		m.lights.append({"pos": Vector2(lp.x + 0.5, lp.y) * TILE, "r": 60.0, "col": Color(0.75, 0.92, 1.0), "a": 0.35})
	for bn in [Vector2i(22, 30), Vector2i(39, 30)]:
		m.add_object({"kind": "bench", "x": bn.x, "y": bn.y, "w": 3, "h": 1, "face": 0}, false)
	# the bill of the day on a holo
	m.add_object({"kind": "holo_pillar", "x": 44, "y": 20, "w": 1, "h": 1, "col": Color(0.45, 0.75, 1.0)})
	_zone(m, Rect2(43, 21, 3, 1.4), "senate_info", "The bill on the floor", Color(0.45, 0.75, 1.0))
	m.lights.append({"pos": Vector2(44.5, 20.5) * TILE, "r": 40.0, "col": Color(0.45, 0.75, 1.0), "a": 0.35})
	DeckGen._seats(m)
	for wp in [Vector2(14, 22), Vector2(26, 21), Vector2(40, 21), Vector2(52, 23), Vector2(22, 27), Vector2(44, 27), Vector2(30, 31), Vector2(56, 30)]:
		if m.free_at(wp * TILE, 6.0):
			m.wander.append(wp * TILE)
	return m


# ---------------------------------------------------------------- the Senate's lobby

static func build_senate_lobby(station: Dictionary, body: Dictionary) -> GroundMap:
	# (Luz: far more in it) – the security arches at the doors, the seal in the floor, the blue runner up to the stair,
	# the news screens, the founding exhibit, the information desk, the waiting corners, visitors
	var W := 40
	var H := 26
	var m := GroundMap.new()
	MuseumGen._pal(m, body)
	m.style = "museum"
	m.title = "The Senate – lobby"
	m.hull_top = -9999
	m.set_meta("no_guards", true)
	m.setup(W, H)
	m.fill(0, 0, W, H, T.CAP)
	m.fill(1, 2, W - 2, 3, T.FACE)
	m.fill(1, 5, W - 2, H - 7, T.FLOOR, 34)
	var cyan := Color(0.45, 0.85, 1.0)
	# the north wall: a light strip, banners of light, the Senate's channel on two screens, the stair to the gallery
	m.face_deco.append({"kind": "light_strip", "x": 1, "y": 2, "w": W - 2, "at": 8, "col": cyan})
	for bn in [3, 6, W - 7, W - 4]:
		m.face_deco.append({"kind": "holo_banner", "x": bn, "y": 2, "w": 1, "col": ASSEMBLY_BLUE})
	for sc in [9, W - 13]:
		m.face_deco.append({"kind": "screen", "x": sc, "y": 3, "w": 4, "col": cyan})
	var sx := W / 2 - 3
	m.fill(sx, 5, 6, 5, T.FLOOR, 36)
	m.fill(sx + 1, 5, 4, 5, T.FLOOR, 37)
	m.face_deco.append({"kind": "museum_gate", "x": sx, "y": 2, "w": 6})
	MuseumGen._label(m, "TO THE GALLERY", Vector2(W * 0.5, 1.6), Color(0.95, 0.85, 0.55))
	_go(m, Rect2(sx, 5, 6, 1.2), "sgallery", "from_lobby", "Up the stairs – the gallery over the chamber", WARM)
	m.set_meta("from_gallery", Vector2(W * 0.5, 7.0) * TILE)
	for bx in [sx - 3, sx + 7]:
		m.add_object({"kind": "holo_bust", "x": bx, "y": 5, "w": 2, "h": 1, "col": cyan})        # speakers past
	m.lights.append({"pos": Vector2(sx - 2, 5.5) * TILE, "r": 30.0, "col": cyan, "a": 0.3})
	m.lights.append({"pos": Vector2(sx + 8, 5.5) * TILE, "r": 30.0, "col": cyan, "a": 0.3})
	# the seal in the floor under the bill's holo, the blue runner from the doors to the stair
	m.decals.append({"kind": "rug", "x": W / 2 - 2, "y": 10, "w": 4, "h": H - 12, "col": Color(0.25, 0.4, 0.75)})
	m.decals.append({"kind": "senate_seal", "x": W / 2 - 4, "y": 11, "w": 8, "h": 5})
	m.add_object({"kind": "holo_pillar", "x": W / 2, "y": 13, "w": 1, "h": 1, "col": Color(0.45, 0.75, 1.0)})
	_zone(m, Rect2(W / 2 - 1, 14, 3, 1.4), "senate_info", "The bill on the floor", Color(0.45, 0.75, 1.0))
	m.lights.append({"pos": Vector2(W * 0.5 + 0.5, 13.5) * TILE, "r": 56.0, "col": Color(0.45, 0.75, 1.0), "a": 0.4})
	# the party office in the west: its counter, a holo of the donations, the campaigns' flags and screen, chairs
	m.add_object({"kind": "counter", "x": 2, "y": 9, "w": 6, "h": 1})
	m.add_object({"kind": "holo_pillar", "x": 3, "y": 7, "w": 1, "h": 1, "col": Color(0.95, 0.8, 0.35)})
	for fl in [[5, Color(0.2, 0.45, 0.85)], [7, Color(0.95, 0.75, 0.2)]]:
		m.add_object({"kind": "banner", "x": int(fl[0]), "y": 6, "w": 1, "h": 1, "col": fl[1]})
	m.add_object({"kind": "news_wall", "x": 9, "y": 7, "w": 3, "h": 1})
	m.people.append({"pos": Vector2(4.5, 8.4) * TILE, "dir": 1, "role": "keeper"})
	m.people.append({"pos": Vector2(6.5, 8.4) * TILE, "dir": 1, "role": "keeper"})
	_zone(m, Rect2(2, 10, 6, 1.6), "party_office", "Party office – a donation to a campaign", Color(0.95, 0.8, 0.35))
	m.lights.append({"pos": Vector2(5, 9) * TILE, "r": 60.0, "col": Color(1.0, 0.85, 0.45), "a": 0.4})
	for ch in [2, 7]:
		m.add_object({"kind": "chair", "x": ch, "y": 12, "w": 1, "h": 1})
	m.add_object({"kind": "plant", "x": 1, "y": 5, "w": 1, "h": 1})
	# the founding exhibit in the south-west: Agora on a globe, the first colony ship, the charter behind glass
	m.decals.append({"kind": "rug", "x": 2, "y": 15, "w": 10, "h": 5, "col": Color(0.3, 0.32, 0.4)})
	m.add_object({"kind": "globe", "x": 3, "y": 16, "w": 2, "h": 1})
	m.add_object({"kind": "holo_ship", "x": 6, "y": 16, "w": 2, "h": 1, "species": "mogura"})
	m.add_object({"kind": "display", "x": 9, "y": 16, "w": 2, "h": 1, "col": Color(0.95, 0.85, 0.55)})
	m.add_object({"kind": "rope", "x": 2, "y": 18, "w": 10, "h": 1}, false)
	_stand_sign(m, "THE FOUNDING", Vector2(7, 19.8), Color(0.9, 0.85, 0.7))
	m.lights.append({"pos": Vector2(7, 16.5) * TILE, "r": 70.0, "col": Color(1.0, 0.92, 0.75), "a": 0.35})
	# the lobbyist's corner in the east: a rug, leather, a low table, plants, soft light
	m.decals.append({"kind": "rug", "x": W - 9, "y": 7, "w": 8, "h": 5, "col": Color(0.55, 0.2, 0.2)})
	DeckGen._seat(m, "sofa", W - 7, 8, 1, Color(0.45, 0.25, 0.16), RandomNumberGenerator.new(), 0.0, 3)
	m.add_object({"kind": "table_small", "x": W - 6, "y": 10, "w": 1, "h": 1})
	m.add_object({"kind": "plant", "x": W - 3, "y": 8, "w": 1, "h": 1})
	m.add_object({"kind": "plant", "x": W - 9, "y": 8, "w": 1, "h": 1})
	m.people.append({"pos": Vector2(W - 3.5, 10.6) * TILE, "dir": 2, "role": "keeper"})      # the lobbyist, by his sofa
	_zone(m, Rect2(W - 8, 11, 5, 1.6), "lobbyist", "A word with the lobbyist", Color(1.0, 0.5, 0.4))
	m.lights.append({"pos": Vector2(W - 5.5, 9) * TILE, "r": 60.0, "col": Color(1.0, 0.75, 0.45), "a": 0.45})
	# the information desk in the south-east, a news screen, a vending machine, a waiting corner
	m.add_object({"kind": "curator_desk", "x": W - 10, "y": 16, "w": 6, "h": 1})
	m.people.append({"pos": Vector2(W - 7, 15.4) * TILE, "dir": 0, "role": "keeper"})
	_stand_sign(m, "INFORMATION", Vector2(W - 7, 19.6), Color(0.75, 0.9, 1.0))
	m.add_object({"kind": "news_wall", "x": W - 12, "y": 7, "w": 3, "h": 1})
	m.add_object({"kind": "vending", "x": W - 2, "y": 14, "w": 1, "h": 1})
	m.add_object({"kind": "plant", "x": W - 2, "y": 5, "w": 1, "h": 1})
	# pylons through the hall, benches between them
	for py2 in [Vector2i(13, 11), Vector2i(W - 14, 11), Vector2i(13, 18), Vector2i(W - 14, 18)]:
		m.add_object({"kind": "pylon", "x": py2.x, "y": py2.y, "w": 1, "h": 1})
		m.lights.append({"pos": Vector2(py2.x + 0.5, py2.y - 0.5) * TILE, "r": 26.0, "col": cyan, "a": 0.3})
	for bb in [Vector2i(14, 15), Vector2i(W - 17, 15)]:
		m.add_object({"kind": "museum_bench", "x": bb.x, "y": bb.y, "w": 3, "h": 1, "face": 1}, false)
	# the doors: security arches either side of the runner – (Luz) the only way in: glass barriers right across the hall,
	# a rope over the runner, a guard posted at each arch, a tone as you pass through
	var gates := [W / 2 - 5, W / 2 + 2]
	var scans: Array = []
	for gx in gates:
		m.add_object({"kind": "scanner_gate", "x": gx, "y": H - 6, "w": 3, "h": 1}, false)
		m.lights.append({"pos": Vector2(gx + 1.5, H - 6.5) * TILE, "r": 30.0, "col": Color(0.4, 1.0, 0.6), "a": 0.3})
		scans.append(Rect2(Vector2(gx, H - 6) * TILE, Vector2(3, 1) * TILE))
	m.set_meta("scanners", scans)
	m.add_object({"kind": "glass_rail", "x": 1, "y": H - 6, "w": W / 2 - 6, "h": 1})
	m.add_object({"kind": "rope", "x": W / 2 - 2, "y": H - 6, "w": 4, "h": 1})
	m.add_object({"kind": "glass_rail", "x": W / 2 + 5, "y": H - 6, "w": 1, "h": 1})
	m.add_object({"kind": "glass_rail", "x": W / 2 + 10, "y": H - 6, "w": W / 2 - 11, "h": 1})
	m.set_meta("guard_posts", [Vector2(W / 2 - 5.5, H - 6.4) * TILE, Vector2(W / 2 + 5.5, H - 6.4) * TILE])
	m.add_object({"kind": "counter", "x": W / 2 + 6, "y": H - 6, "w": 3, "h": 1})
	m.add_object({"kind": "terminal", "x": W / 2 + 9, "y": H - 6, "w": 1, "h": 1, "col": Color(0.4, 1.0, 0.6)})
	m.people.append({"pos": Vector2(W * 0.5 + 7.5, H - 6.6) * TILE, "dir": 0, "role": "keeper"})
	for pl in [Vector2i(1, H - 4), Vector2i(W - 2, H - 4), Vector2i(W / 2 - 7, H - 4), Vector2i(W / 2 + 6, H - 4)]:
		m.add_object({"kind": "plant", "x": pl.x, "y": pl.y, "w": 1, "h": 1})
	MuseumGen._exit(m, W / 2 - 2, H - 3, 4, "kplaza", "from_senate", "Out onto the Plaza of the Vote")
	m.set_meta("from_plaza", Vector2(W * 0.5, H - 4.5) * TILE)
	m.lights.append({"pos": Vector2(W * 0.5, 11) * TILE, "r": 240.0, "col": WARM, "a": 0.25})
	DeckGen._seats(m)
	for wp in [Vector2(12, 14), Vector2(27, 14), Vector2(16, 20), Vector2(24, 20), Vector2(20, 17), Vector2(8, 22), Vector2(32, 21)]:
		if m.free_at(wp * TILE, 6.0):
			m.wander.append(wp * TILE)
	m.set_meta("tourists", 6)
	return m


# ---------------------------------------------------------------- the gallery over the chamber

const GAL_Y := 13                                    # the balustrade's row – north of it the chamber far below

static func build_senate_gallery(station: Dictionary, body: Dictionary) -> GroundMap:
	var W := 36
	var H := 20
	var m := GroundMap.new()
	MuseumGen._pal(m, body)
	m.style = "museum"
	m.title = "The Senate – gallery"
	m.hull_top = -9999
	m.set_meta("no_guards", true)
	m.setup(W, H)
	m.fill(0, 0, W, H, T.CAP)
	# the chamber: seen through, not walked – SenateChamber draws it in the window
	m.fill(0, 0, W, GAL_Y, T.GLASS)
	m.window_rect = Rect2(0, 0, W, GAL_Y)
	m.set_meta("senate_view", true)
	m.fill(0, GAL_Y, W, 1, T.BLOCK, 34)
	m.add_object({"kind": "m_rail", "x": 0, "y": GAL_Y, "w": W, "h": 1}, false)
	m.fill(1, GAL_Y + 1, W - 2, H - GAL_Y - 3, T.FLOOR, 34)
	# the voting stand in the middle of the balcony, benches either side
	var vx := W / 2 - 2
	m.add_object({"kind": "terminal", "x": vx, "y": GAL_Y + 1, "w": 4, "h": 1, "col": Color(0.4, 1.0, 0.6)})
	m.fill(vx, GAL_Y + 1, 4, 1, T.BLOCK, 34)
	_zone(m, Rect2(vx - 0.5, GAL_Y + 2, 5, 1.4), "senate_stand", "The voting stand – your vote on the bill", Color(0.4, 1.0, 0.6))
	m.lights.append({"pos": Vector2(W * 0.5, GAL_Y + 1.5) * TILE, "r": 50.0, "col": Color(0.6, 1.0, 0.7), "a": 0.4})
	for bx in [3, 9, W - 12, W - 6]:
		m.add_object({"kind": "museum_bench", "x": bx, "y": GAL_Y + 2, "w": 3, "h": 1, "face": 1}, false)    # (Luz) facing the chamber
	MuseumGen._exit(m, W / 2 - 2, H - 2, 4, "senate", "from_gallery", "Down the stairs – back to the lobby")
	m.set_meta("from_lobby", Vector2(W * 0.5, H - 3.5) * TILE)
	m.lights.append({"pos": Vector2(W * 0.5, GAL_Y + 3) * TILE, "r": 200.0, "col": WARM, "a": 0.2})
	DeckGen._seats(m)
	for wp in [Vector2(6, 16.5), Vector2(14, 17), Vector2(24, 16.5), Vector2(30, 17)]:
		if m.free_at(wp * TILE, 6.0):
			m.wander.append(wp * TILE)
	m.set_meta("tourists", 4)
	return m
