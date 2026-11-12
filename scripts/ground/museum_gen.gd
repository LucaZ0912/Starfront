extends RefCounted
## Package 53e (Luz, 12 Nov 2026): the Museum in the city on Curie – three maps.
##  * the roof plaza (`build_plaza`): up the lift, the city beyond the railing; an avenue of statues to the Museum's
##    white front with its columns, its glass dome on the roof and its doors open;
##  * the Museum's rooms, each a map of its own (0.7.53.26, Luz – after the mockup): the hall (`build_hall`) with the
##    curator's desk, behind it the grand stairs up to the gate of the first floor, the gallery above as scenery, under
##    its wings an arch west to the minerals (`build_minerals`) and one east with the stairs down; the first floor
##    (`build_floor1`) – the Old World west, the Severance east, the grand stairs up to the gate of the second floor
##    (`build_floor2`), the Precursors';
##  * the basement (`build_basement`): the Dark Ones – black glass walls with the reliefs of their ruins, a cast of a
##    membrane door, the cases in a ring round a round pool where a monolith's cast is raised once every piece of
##    theirs is there.
## The cases are explore nodes ("vitrine" on the floor, "niche" in a wall; data in `exhibit`): filled ones show their
## piece, empty ones its outline and a "?". No class_name: preload it.

const T := GroundMap.T
const TILE := GroundMap.TILE
const MuseumData = preload("res://data/museum.gd")
const ExploreNodeM = preload("res://scripts/ground/explore.gd")

const WARM := Color(1.0, 0.92, 0.78)
const VIO := Color(0.62, 0.35, 1.0)


static func _pal(m: GroundMap, body: Dictionary) -> void:
	m.pal = DeckGen.palette_for_body(body).duplicate()
	m.pal["floor"] = Color(0.86, 0.84, 0.8)
	m.pal["floor2"] = Color(0.7, 0.66, 0.61)
	m.pal["wall"] = Color(0.88, 0.87, 0.84)
	m.pal["wall_top"] = Color(0.14, 0.13, 0.15)
	m.pal["trim"] = Color(0.62, 0.6, 0.56)
	m.pal["accent"] = Color(0.95, 0.75, 0.35)
	m.pal["frame"] = Color(0.7, 0.68, 0.64)
	m.pal["wood"] = Color(0.42, 0.26, 0.16)


# ---------------------------------------------------------------- the cases

## A case on the floor, its footprint 2 × 1 tiles at (x, y) (3 × 2 for a room's centrepiece).
static func _case(m: GroundMap, x: int, y: int, id: String, big: bool = false, dark: bool = false) -> Dictionary:
	var fw := 3 if big else 2
	var fh := 2 if big else 1
	m.fill(x, y, fw, fh, T.BLOCK)
	var pos := Vector2(x + fw * 0.5, y + fh) * TILE
	var d := ExploreNodeM.add(m, "vitrine", pos, {"exhibit": id, "big": big, "dark": dark})
	_title(m, d)
	m.lights.append({"pos": pos + Vector2(0, -12 if not big else -20), "r": 34.0 if not big else 56.0,
		"col": VIO.lightened(0.3) if dark else WARM, "a": (0.28 if not big else 0.22) if GameState.museum_donated.has(id) else 0.1})
	if GameState.museum_donated.has(id):
		m.wander.append(pos + Vector2(0, 16 if not big else 24))      # visitors stop before the filled ones
	return d


## A case set into a wall's face; (x, y) its left tile at the face's foot row (the floor row below the face).
static func _niche(m: GroundMap, x: int, y: int, id: String, dark: bool = false) -> Dictionary:
	var pos := Vector2(x + 1.0, y) * TILE
	var d := ExploreNodeM.add(m, "niche", pos, {"exhibit": id, "dark": dark, "wall": true})
	_title(m, d)
	if GameState.museum_donated.has(id):
		m.lights.append({"pos": pos + Vector2(0, -14), "r": 26.0, "col": VIO.lightened(0.3) if dark else WARM, "a": 0.35})
	return d


## A case's line on the screen: what is in it, or what belongs in it.
static func _title(m: GroundMap, d: Dictionary) -> void:
	var id := String(d["exhibit"])
	var t := ""
	if GameState.museum_donated.has(id):
		t = "%s – look at it (E)" % MuseumData.exhibit_name(id)
	elif GameState.museum_finds.has(id):
		t = "An empty case – you carry what belongs here: set in %s (E)" % MuseumData.exhibit_name(id)
	else:
		t = "An empty case – something of %s belongs here (E)" % MuseumData.room_name(MuseumData.room_of(id)).replace("The ", "the ")
	for z in m.zones:
		if String(z.get("kind", "")) == "explore" and int(z.get("i", -1)) == m.explore.find(d):
			z["title"] = t


static func retitle(m: GroundMap) -> void:
	for d in m.explore:
		if String(d["kind"]) in ["vitrine", "niche"]:
			_title(m, d)


static func _ids(room: String) -> Array:
	return MuseumData.of_room(room).map(func(e): return String(e["id"]))


static func _rail(m: GroundMap, x: int, y: int, w: int, h: int) -> void:
	m.add_object({"kind": "m_rail", "x": x, "y": y, "w": w, "h": h})


static func _label(m: GroundMap, text: String, at: Vector2, col: Color) -> void:
	m.zones.append({"rect": Rect2(), "kind": "label", "id": "m_label", "title": text, "col": col, "sign": at * TILE})


# ---------------------------------------------------------------- the roof plaza

static func build_plaza(station: Dictionary, body: Dictionary) -> GroundMap:
	var m := GroundMap.new()
	_pal(m, body)
	m.pal["floor"] = Color(0.7, 0.66, 0.6)
	m.pal["floor2"] = Color(0.64, 0.6, 0.55)
	m.pal["wall"] = Color(0.86, 0.87, 0.89)
	m.style = "plaza"
	m.title = "Museum of Curie"
	m.hull_top = -9999
	var W := 62
	var H := 28
	var KX := 10                                      # the lift kiosk's east edge
	var MX := W - 24                                  # the Museum's west edge
	m.setup(W, H)
	m.fill(0, 0, W, H, T.FLOOR, 30)
	m.fill(0, H - 1, W, 1, T.BLOCK, 30)
	m.fill(0, 0, 1, H, T.BLOCK, 30)
	m.fill(W - 1, 0, 1, H, T.BLOCK, 30)
	# the view north over the railing, the city beyond
	m.fill(KX, 0, MX - KX, 9, T.GLASS)
	m.window_rect = Rect2(KX, 0, MX - KX, 9)
	m.set_meta("open_sky", true)
	m.add_object({"kind": "glass_rail", "x": KX, "y": 9, "w": MX - KX, "h": 1})
	# the lift kiosk
	m.fill(0, 0, KX, 9, T.CAP)
	m.fill(0, 9, KX, 4, T.FACE)
	for lx0 in [2, 6]:
		m.face_deco.append({"kind": "lift", "x": lx0, "y": 12, "w": 2, "col": Color(0.4, 1.0, 0.6)})
		m.lifts.append({"x": lx0, "y": 12, "w": 2})
	m.zones.append({"rect": Rect2(Vector2(2, 13) * TILE, Vector2(6, 1.4) * TILE), "kind": "lift", "id": "lift",
		"title": "Lift – back down into the city", "col": Color(0.4, 1.0, 0.6), "sign": Vector2(5, 10.2) * TILE})
	m.spawn = Vector2(5.0, 14.6) * TILE
	# the Museum: its roof with the glass dome over the hall, its front – white stone, columns, the doors open
	m.fill(MX, 0, W - MX, 14, T.CAP)
	m.fill(MX, 14, W - MX - 1, 3, T.FACE)
	m.set_meta("tower_x", 9999)
	m.set_meta("museum_x", MX)
	m.decals.append({"kind": "museum_roof", "x": MX, "y": 0, "w": W - MX, "h": 14})
	var dx := MX + 10
	m.face_deco.append({"kind": "museum_doors", "x": dx, "y": 14, "w": 4})
	for bx in [MX + 4, MX + 17]:
		m.face_deco.append({"kind": "banner_m", "x": bx, "y": 14, "w": 1, "col": Color(0.15, 0.22, 0.45) if bx < dx else Color(0.45, 0.15, 0.25)})
	m.decals.append({"kind": "steps", "x": MX, "y": 17, "w": W - MX - 1, "h": 2})
	for cx in range(MX + 1, W - 2, 3):
		if cx >= dx - 1 and cx <= dx + 4:
			continue
		m.add_object({"kind": "column", "x": cx, "y": 17, "w": 1, "h": 1})
	_label(m, "MUSEUM OF CURIE", Vector2(dx + 2, 13.6), Color(0.95, 0.8, 0.45))
	m.zones.append({"rect": Rect2(Vector2(dx, 17) * TILE, Vector2(4, 1.6) * TILE), "kind": "museum_in", "id": "museum_in",
		"title": "Into the Museum", "col": Color(1.0, 0.85, 0.5), "sign": Vector2(-100, -100)})
	m.set_meta("door_front", Vector2(dx + 2, 19.2) * TILE)
	m.lights.append({"pos": Vector2(dx + 2, 18) * TILE, "r": 80.0, "col": Color(1.0, 0.85, 0.6), "a": 0.5})
	# the avenue: a path of darker stone to the doors, statues either side – a pilot, a soldier, a colonist, a Precursor
	m.decals.append({"kind": "path_m", "x": KX, "y": 19, "w": MX - KX, "h": 2})
	m.add_object({"kind": "statue", "x": 16, "y": 16, "w": 2, "h": 1, "seed": 71, "species": "suit_survey"})
	m.add_object({"kind": "statue", "x": 28, "y": 16, "w": 2, "h": 1, "seed": 72, "species": "suit_mil_light"})
	m.add_object({"kind": "statue", "x": 16, "y": 23, "w": 2, "h": 1, "seed": 73, "species": "suit_civil"})
	m.add_object({"kind": "statue_precursor", "x": 28, "y": 23, "w": 2, "h": 1})
	for tp in [Vector2i(KX + 2, 12), Vector2i(KX + 12, 12), Vector2i(KX + 2, 24)]:
		m.add_object({"kind": "planter", "x": tp.x, "y": tp.y, "w": 3, "h": 1, "col": Color(0.78, 0.79, 0.82)})
		m.add_object({"kind": "tree", "x": tp.x, "y": tp.y - 1, "w": 3, "h": 1, "rise": 72})
	m.add_object({"kind": "bench", "x": 21, "y": 13, "w": 3, "h": 1})
	m.add_object({"kind": "bench", "x": 21, "y": 24, "w": 3, "h": 1})
	m.add_object({"kind": "poster", "x": 34, "y": 23, "w": 1, "h": 1})
	for lp in [Vector2i(14, 18), Vector2i(26, 18), Vector2i(34, 18), Vector2i(14, 22), Vector2i(26, 22)]:
		m.add_object({"kind": "lamp_post", "x": lp.x, "y": lp.y, "w": 1, "h": 1})
		m.lights.append({"pos": Vector2(lp.x + 0.5, lp.y) * TILE, "r": 60.0, "col": Color(1.0, 0.88, 0.65), "a": 0.35})
	for wp in [Vector2(20, 18), Vector2(32, 21), Vector2(44, 20), Vector2(52, 21), Vector2(24, 15), Vector2(36, 25), Vector2(48, 24)]:
		if m.free_at(wp * TILE, 6.0):
			m.wander.append(wp * TILE)
	return m


# ---------------------------------------------------------------- the Museum's rooms (0.7.53.26, Luz: one room each)

## A way to another of the Museum's rooms: a zone on the floor; `at` names the map meta where you arrive there.
static func _go(m: GroundMap, r: Rect2, to: String, at: String, title: String, col: Color, sign: Vector2 = Vector2(-100, -100)) -> void:
	m.zones.append({"rect": Rect2(r.position * TILE, r.size * TILE), "kind": "museum_go", "id": "museum_go", "to": to, "at": at,
		"title": title, "col": col, "sign": sign * TILE if sign.x >= 0.0 else sign})


static func _room(station: Dictionary, body: Dictionary, W: int, H: int, fk: int) -> GroundMap:
	var m := GroundMap.new()
	_pal(m, body)
	m.style = "museum"
	m.title = "Museum of Curie"
	m.hull_top = -9999
	m.setup(W, H)
	m.fill(0, 0, W, H, T.CAP)
	m.fill(1, 2, W - 2, 2, T.FACE)
	m.fill(1, 4, W - 2, H - 6, T.FLOOR, fk)
	return m


## The hall (as in the mockup): above it, seen over the rail, the gallery of the first floor in a U – its front with
## the exhibitions' banners and the Museum's name; in its middle the grand stairs up to the gate of the first floor;
## under the gallery's wings two arches – west to the minerals, east the stairs down to the Dark Ones. Before the stairs
## the curator's desk, statues either side, the runner to the doors.
static func build_hall(station: Dictionary, body: Dictionary) -> GroundMap:
	var W := 36
	var H := 25
	var m := GroundMap.new()
	_pal(m, body)
	m.style = "museum"
	m.title = "Museum of Curie"
	m.hull_top = -9999
	m.setup(W, H)
	m.fill(0, 0, W, H, T.CAP)
	# the gallery above (scenery – the first floor is a room of its own up the stairs)
	m.fill(1, 1, W - 2, 4, T.BLOCK, 35)
	m.fill(1, 5, 7, 5, T.BLOCK, 35)
	m.fill(W - 8, 5, 7, 5, T.BLOCK, 35)
	_rail(m, 8, 4, W - 16, 1)
	_rail(m, 7, 5, 1, 5)
	_rail(m, W - 8, 5, 1, 5)
	m.add_object({"kind": "bust", "x": 3, "y": 2, "w": 1, "h": 1, "col": Color(0.92, 0.9, 0.86)})
	m.add_object({"kind": "plant", "x": 11, "y": 2, "w": 1, "h": 1})
	m.add_object({"kind": "plant", "x": W - 12, "y": 2, "w": 1, "h": 1})
	m.add_object({"kind": "bust", "x": W - 4, "y": 2, "w": 1, "h": 1, "col": Color(0.6, 0.48, 0.4)})
	m.add_object({"kind": "museum_bench", "x": 2, "y": 7, "w": 3, "h": 1})
	m.add_object({"kind": "museum_bench", "x": W - 5, "y": 7, "w": 3, "h": 1})
	# its fronts: the band behind the stairs, the wings
	m.fill(8, 5, W - 16, 3, T.FACE)
	m.fill(1, 10, 7, 3, T.FACE)
	m.fill(W - 8, 10, 7, 3, T.FACE)
	m.fill(8, 8, W - 16, H - 10, T.FLOOR, 34)
	m.fill(1, 13, 7, H - 15, T.FLOOR, 34)
	m.fill(W - 8, 13, 7, H - 15, T.FLOOR, 34)
	for bn in [[9, Color(0.35, 0.22, 0.12)], [11, Color(0.15, 0.22, 0.45)], [W - 12, Color(0.4, 0.25, 0.18)], [W - 10, Color(0.12, 0.1, 0.16)]]:
		m.face_deco.append({"kind": "banner_m", "x": int(bn[0]), "y": 5, "w": 1, "col": bn[1]})
	# the grand stairs up to the gate of the first floor
	var sx := W / 2 - 3
	m.fill(sx, 8, 6, 8, T.FLOOR, 36)
	m.fill(sx + 1, 8, 4, 8, T.FLOOR, 37)
	m.face_deco.append({"kind": "museum_gate", "x": sx, "y": 5, "w": 6})
	_label(m, "MUSEUM OF CURIE", Vector2(W * 0.5, 4.6), Color(0.95, 0.8, 0.45))
	_go(m, Rect2(sx, 8, 6, 1.2), "museum_1", "from_hall", "Up through the gate – the first floor: The Old World and The Severance", WARM)
	m.set_meta("from_1", Vector2(W * 0.5, 9.6) * TILE)
	m.lights.append({"pos": Vector2(W * 0.5, 7.0) * TILE, "r": 70.0, "col": WARM, "a": 0.4})
	# the arches under the wings
	m.face_deco.append({"kind": "arch_min", "x": 2, "y": 10, "w": 5})
	_go(m, Rect2(2, 13, 5, 1.2), "museum_min", "from_hall", "Through the arch – Minerals", Color(0.6, 0.9, 1.0), Vector2(4.5, 9.6))
	m.set_meta("from_min", Vector2(4.5, 14.6) * TILE)
	m.lights.append({"pos": Vector2(4.5, 12.5) * TILE, "r": 50.0, "col": Color(0.75, 0.9, 1.0), "a": 0.45})
	m.face_deco.append({"kind": "arch_down", "x": W - 7, "y": 10, "w": 5})
	_go(m, Rect2(W - 7, 13, 5, 1.2), "museum_down", "museum_in", "Stairs down – The Dark Ones", VIO.lightened(0.3), Vector2(W - 4.5, 9.6))
	m.set_meta("from_down", Vector2(W - 4.5, 14.6) * TILE)
	m.lights.append({"pos": Vector2(W - 4.5, 12.5) * TILE, "r": 60.0, "col": VIO, "a": 0.55})
	# the desk, the curator, statues, busts, plants, benches; the runner and the doors
	m.add_object({"kind": "statue", "x": sx - 4, "y": 15, "w": 2, "h": 1, "seed": 74, "species": "suit_survey"})
	m.add_object({"kind": "statue", "x": sx + 8, "y": 15, "w": 2, "h": 1, "seed": 75, "species": "suit_civil"})
	m.add_object({"kind": "curator_desk", "x": sx - 1, "y": 18, "w": 8, "h": 1})
	var cur := ChibiArt.PilotArt.random_look(_rng(station, 53))
	cur["suit"] = ""
	m.people.append({"pos": Vector2(W * 0.5, 17.7) * TILE, "dir": 0, "role": "keeper", "look": cur})
	m.zones.append({"rect": Rect2(Vector2(sx - 1, 19) * TILE, Vector2(8, 1.4) * TILE), "kind": "curator", "id": "curator",
		"title": "The curator – donations, your finds, a hint (E)", "col": Color(1.0, 0.85, 0.5), "sign": Vector2(-100, -100)})
	m.fill(W / 2 - 1, 20, 2, 3, T.FLOOR, 42)
	m.decals.append({"kind": "rosette", "x": W / 2 - 3, "y": 20, "w": 6, "h": 3})
	m.add_object({"kind": "bust", "x": 1, "y": 18, "w": 1, "h": 1, "col": Color(0.92, 0.9, 0.86)})
	m.add_object({"kind": "bust", "x": W - 2, "y": 18, "w": 1, "h": 1, "col": Color(0.6, 0.48, 0.4)})
	m.add_object({"kind": "plant", "x": 9, "y": 13, "w": 1, "h": 1})
	m.add_object({"kind": "plant", "x": W - 10, "y": 13, "w": 1, "h": 1})
	m.add_object({"kind": "plant", "x": 9, "y": 22, "w": 1, "h": 1})
	m.add_object({"kind": "plant", "x": W - 10, "y": 22, "w": 1, "h": 1})
	m.add_object({"kind": "museum_bench", "x": 3, "y": 21, "w": 3, "h": 1})
	m.add_object({"kind": "museum_bench", "x": W - 6, "y": 21, "w": 3, "h": 1})
	m.add_object({"kind": "terminal", "x": 11, "y": 20, "w": 1, "h": 1})
	m.decals.append({"kind": "museum_doors_s", "x": W / 2 - 2, "y": H - 2, "w": 4, "h": 1})
	m.zones.append({"rect": Rect2(Vector2(W / 2 - 2, H - 3) * TILE, Vector2(4, 1.0) * TILE), "kind": "museum_out", "id": "museum_out",
		"title": "Out onto the roof plaza", "col": Color(0.4, 1.0, 0.6), "sign": Vector2(-100, -100)})
	m.spawn = Vector2(W * 0.5, H - 3.4) * TILE
	m.lights.append({"pos": Vector2(W * 0.5, 15) * TILE, "r": 200.0, "col": Color(1.0, 0.97, 0.9), "a": 0.22})   # the dome's daylight
	m.lights.append({"pos": Vector2(W * 0.5, 18) * TILE, "r": 60.0, "col": WARM, "a": 0.3})
	for wp in [Vector2(W * 0.5 + 3, 21), Vector2(6, 16), Vector2(W - 6, 16), Vector2(12, 11), Vector2(W - 12, 11), Vector2(W * 0.5 - 4, 22)]:
		if m.free_at(wp * TILE, 6.0):
			m.wander.append(wp * TILE)
	return m


## The minerals room through the west arch: the Giant Diamond on its dais, six cases in the back wall, the rest spread.
static func build_minerals(station: Dictionary, body: Dictionary) -> GroundMap:
	var m := _room(station, body, 23, 20, 41)
	var mn := _ids("minerals")
	var wall_i := [1, 4, 7, 10, 13, 16]
	var wall_x := [2, 5, 8, 12, 15, 18]
	for k in 6:
		_niche(m, wall_x[k], 4, mn[wall_i[k]])
	m.set_meta("from_hall", Vector2(11.5, 16.4) * TILE)
	_case(m, 10, 9, mn[0], true)
	var free := [2, 3, 5, 6, 8, 9, 11, 12, 14, 15, 17, 18, 19]
	var spots := [Vector2i(2, 7), Vector2i(6, 6), Vector2i(15, 6), Vector2i(19, 7), Vector2i(5, 9), Vector2i(16, 9),
		Vector2i(2, 12), Vector2i(6, 13), Vector2i(15, 13), Vector2i(19, 12), Vector2i(3, 16), Vector2i(7, 16), Vector2i(16, 16)]
	for k2 in free.size():
		_case(m, spots[k2].x, spots[k2].y, mn[free[k2]])
	m.add_object({"kind": "rope", "x": 9, "y": 12, "w": 5, "h": 1})
	m.add_object({"kind": "statue", "x": 19, "y": 16, "w": 2, "h": 1, "seed": 78, "species": "suit_work"})
	m.add_object({"kind": "geode_big", "x": 1, "y": 9, "w": 2, "h": 1})
	m.add_object({"kind": "terminal", "x": 21, "y": 9, "w": 1, "h": 1})
	m.add_object({"kind": "museum_bench", "x": 10, "y": 15, "w": 3, "h": 1})
	m.decals.append({"kind": "museum_arch_s", "x": 10, "y": 18, "w": 3, "h": 1})
	_go(m, Rect2(10, 17, 3, 1.0), "museum", "from_min", "Back through the arch – the hall", Color(0.4, 1.0, 0.6))
	m.spawn = m.get_meta("from_hall")
	_label(m, "MINERALS", Vector2(11.5, 2.4), Color(0.6, 0.9, 1.0))
	m.lights.append({"pos": Vector2(11.5, 10) * TILE, "r": 200.0, "col": Color(0.85, 0.92, 1.0), "a": 0.2})
	for wp in [Vector2(11.5, 14), Vector2(4, 11), Vector2(19, 11)]:
		if m.free_at(wp * TILE, 6.0):
			m.wander.append(wp * TILE)
	return m


## The first floor: up from the hall's gate (the stairs down at its south); the Old World west, the Severance east; in
## its middle the grand stairs up to the gate of the second floor.
static func build_floor1(station: Dictionary, body: Dictionary) -> GroundMap:
	var W := 44
	var H := 23
	var m := _room(station, body, W, H, 35)
	var sx := W / 2 - 3
	m.fill(sx, 4, 6, 6, T.FLOOR, 36)
	m.fill(sx + 1, 4, 4, 6, T.FLOOR, 37)
	m.face_deco.append({"kind": "museum_gate", "x": sx, "y": 2, "w": 6, "rows": 2})
	_go(m, Rect2(sx, 4, 6, 1.2), "museum_2", "from_1", "Up through the gate – the second floor: The Precursors", WARM)
	m.set_meta("from_2", Vector2(W * 0.5, 10.8) * TILE)
	m.fill(sx, H - 5, 6, 3, T.FLOOR, 45)
	_go(m, Rect2(sx, H - 4, 6, 2), "museum", "from_1", "Down the grand stairs – the hall", Color(0.4, 1.0, 0.6))
	m.set_meta("from_hall", Vector2(W * 0.5, H - 6.0) * TILE)
	m.spawn = m.get_meta("from_hall")
	m.add_object({"kind": "plant", "x": sx - 1, "y": 4, "w": 1, "h": 1})
	m.add_object({"kind": "plant", "x": sx + 6, "y": 4, "w": 1, "h": 1})
	# the Old World (west)
	var ow := _ids("oldworld")
	_niche(m, 3, 4, ow[0])
	_niche(m, 10, 4, ow[3])
	m.add_object({"kind": "globe", "x": 14, "y": 7, "w": 2, "h": 1})
	_case(m, 4, 10, ow[1])
	_case(m, 10, 13, ow[2])
	_case(m, 4, 16, ow[4])
	m.add_object({"kind": "bust", "x": 16, "y": 12, "w": 1, "h": 1, "col": Color(0.92, 0.9, 0.86)})
	m.add_object({"kind": "statue", "x": 1, "y": 19, "w": 2, "h": 1, "seed": 76, "species": "suit_civil"})
	m.add_object({"kind": "museum_bench", "x": 10, "y": 19, "w": 3, "h": 1})
	_label(m, "THE OLD WORLD", Vector2(9, 2.4), Color(0.95, 0.75, 0.45))
	m.lights.append({"pos": Vector2(4, 3) * TILE, "r": 40.0, "col": Color(1.0, 0.3, 0.6), "a": 0.45})      # the record's pink glow
	m.lights.append({"pos": Vector2(9, 12) * TILE, "r": 170.0, "col": WARM, "a": 0.2})
	# the Severance (east)
	var sv := _ids("severance")
	_case(m, 33, 9, sv[0], true)
	_niche(m, 28, 4, sv[2])
	m.face_deco.append({"kind": "memorial", "x": 36, "y": 2, "w": 4})
	_case(m, 28, 14, sv[1])
	_case(m, 39, 7, sv[3])
	_case(m, 38, 15, sv[4])
	m.add_object({"kind": "statue", "x": 41, "y": 19, "w": 2, "h": 1, "seed": 77, "species": "suit_mil_light"})
	m.add_object({"kind": "museum_bench", "x": 31, "y": 19, "w": 3, "h": 1})
	_label(m, "THE SEVERANCE", Vector2(34, 2.4), Color(0.55, 0.85, 1.0))
	m.lights.append({"pos": Vector2(34, 12) * TILE, "r": 170.0, "col": Color(0.8, 0.9, 1.0), "a": 0.2})
	for wp in [Vector2(8, 8), Vector2(12, 16), Vector2(30, 12), Vector2(36, 17), Vector2(W * 0.5, 13)]:
		if m.free_at(wp * TILE, 6.0):
			m.wander.append(wp * TILE)
	return m


## The second floor: the Precursors – their tablets in the back wall, the Heart-Core on its dais, the rest about.
static func build_floor2(station: Dictionary, body: Dictionary) -> GroundMap:
	var W := 44
	var H := 19
	var m := _room(station, body, W, H, 35)
	var sx := W / 2 - 3
	m.fill(sx, H - 5, 6, 3, T.FLOOR, 45)
	_go(m, Rect2(sx, H - 4, 6, 2), "museum_1", "from_2", "Down the stairs – the first floor", Color(0.4, 1.0, 0.6))
	m.set_meta("from_1", Vector2(W * 0.5, H - 6.0) * TILE)
	m.spawn = m.get_meta("from_1")
	var pr := _ids("precursors")
	var tab_x := [3, 9, 15, 27, 33]
	for k3 in 5:
		_niche(m, tab_x[k3], 4, pr[5 + k3])
	_case(m, 20, 7, pr[2], true)
	_case(m, 5, 9, pr[0])
	_case(m, 12, 12, pr[1])
	_case(m, 30, 12, pr[3])
	_case(m, 37, 9, pr[4])
	m.add_object({"kind": "statue_precursor", "x": 15, "y": 8, "w": 2, "h": 1})
	m.add_object({"kind": "statue_precursor", "x": 27, "y": 8, "w": 2, "h": 1})
	m.add_object({"kind": "crystal", "x": 40, "y": 14, "w": 2, "h": 1, "col": Color(0.7, 0.55, 1.0)})
	m.add_object({"kind": "crystal", "x": 2, "y": 14, "w": 2, "h": 1, "col": Color(0.45, 0.85, 1.0)})
	m.add_object({"kind": "museum_bench", "x": 6, "y": 15, "w": 3, "h": 1})
	m.add_object({"kind": "museum_bench", "x": 34, "y": 15, "w": 3, "h": 1})
	m.add_object({"kind": "plant", "x": 40, "y": 4, "w": 1, "h": 1})
	_label(m, "THE PRECURSORS", Vector2(W * 0.5, 2.4), Color(0.75, 0.6, 1.0))
	m.lights.append({"pos": Vector2(W * 0.5, 9) * TILE, "r": 300.0, "col": Color(0.95, 0.9, 1.0), "a": 0.18})
	for wp in [Vector2(9, 7), Vector2(16, 14), Vector2(28, 14), Vector2(35, 7)]:
		if m.free_at(wp * TILE, 6.0):
			m.wander.append(wp * TILE)
	return m


# ---------------------------------------------------------------- the basement: the Dark Ones

static func build_basement(station: Dictionary, body: Dictionary) -> GroundMap:
	var m := GroundMap.new()
	_pal(m, body)
	m.pal["wall"] = Color(0.3, 0.27, 0.36)
	m.pal["accent"] = VIO
	m.style = "museum_dark"
	m.title = "Museum of Curie"
	m.hull_top = -9999
	var W := 40
	var H := 24
	m.setup(W, H)
	m.fill(0, 0, W, H, T.CAP)
	m.fill(2, 2, 36, 2, T.FACE)
	m.fill(2, 4, 36, 18, T.FLOOR, 40)
	m.set_meta("dark", Color(0.62, 0.58, 0.72))
	# the reliefs of their ruins on the back wall, the cast of a membrane door between them
	for rv in [[3, 0], [9, 1], [26, 2], [32, 3]]:
		m.face_deco.append({"kind": "relief", "x": int(rv[0]), "y": 2, "w": 5, "v": int(rv[1])})
		m.lights.append({"pos": Vector2(float(rv[0]) + 2.5, 4.4) * TILE, "r": 46.0, "col": VIO, "a": 0.45})
	m.face_deco.append({"kind": "membrane_cast", "x": 18, "y": 2, "w": 4})
	m.lights.append({"pos": Vector2(20, 4.2) * TILE, "r": 60.0, "col": VIO, "a": 0.55})
	# the stairs up (west)
	m.fill(2, 5, 3, 4, T.FLOOR, 44)
	_go(m, Rect2(2, 5, 3, 4), "museum", "from_down", "Stairs up – back to the hall", Color(0.4, 1.0, 0.6), Vector2(3.5, 4.6))
	m.spawn = Vector2(6.0, 7.2) * TILE
	m.lights.append({"pos": Vector2(3.5, 6.5) * TILE, "r": 46.0, "col": WARM, "a": 0.45})
	# the round pool in the middle, grooves running in to it – and on its plinth the monolith's cast, once raised
	m.decals.append({"kind": "ring_pool", "x": 14, "y": 9, "w": 12, "h": 7})
	m.fill(19, 12, 2, 1, T.BLOCK)
	var done := GameState.museum_room_done("darkones")
	var mono := ExploreNodeM.add(m, "monolith_cast", Vector2(20, 13) * TILE, {"state": "up" if done else "empty"})
	for z in m.zones:
		if int(z.get("i", -1)) == m.explore.find(mono):
			z["title"] = "The cast of a monolith – raised now that every piece of the Dark Ones is here (E)" if done \
				else "An empty plinth – kept for a monolith's cast, once every piece of the Dark Ones is here"
	if done:
		m.lights.append({"pos": Vector2(20, 10.5) * TILE, "r": 80.0, "col": VIO, "a": 0.6})
	# the cases round the pool
	var dk := _ids("darkones")
	var spots := [Vector2i(10, 7), Vector2i(28, 7), Vector2i(6, 12), Vector2i(32, 12), Vector2i(10, 17), Vector2i(28, 17), Vector2i(15, 20), Vector2i(23, 20)]
	for k in 8:
		_case(m, spots[k].x, spots[k].y, dk[k], false, true)
	m.add_object({"kind": "skull_cast", "x": 3, "y": 19, "w": 3, "h": 1})
	m.add_object({"kind": "obelisk", "x": 34, "y": 19, "w": 3, "h": 1})
	m.add_object({"kind": "idol_cast", "x": 19, "y": 20, "w": 2, "h": 1})
	m.add_object({"kind": "terminal", "x": 36, "y": 8, "w": 1, "h": 1})
	m.lights.append({"pos": Vector2(4.5, 19) * TILE, "r": 40.0, "col": Color(0.85, 0.8, 1.0), "a": 0.4})
	m.lights.append({"pos": Vector2(35.5, 19) * TILE, "r": 40.0, "col": Color(0.85, 0.8, 1.0), "a": 0.4})
	m.lights.append({"pos": Vector2(20, 13) * TILE, "r": 260.0, "col": VIO, "a": 0.18})
	_label(m, "THE DARK ONES", Vector2(20, 2.4), VIO.lightened(0.3))
	for wp in [Vector2(14, 10), Vector2(26, 10), Vector2(20, 17), Vector2(8, 15), Vector2(32, 15)]:
		if m.free_at(wp * TILE, 6.0):
			m.wander.append(wp * TILE)
	return m


static func _rng(station: Dictionary, k: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(station.get("id", "museum"))) + k
	return r
