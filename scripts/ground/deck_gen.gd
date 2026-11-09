class_name DeckGen
extends RefCounted
## Package 49 (0.7.49.2, after Luz's sketch): the walkable deck of a station. On the left the lift lobby where you
## come up from the dock; from it a corridor runs to the right with most of the shops below it; above the corridor
## the big bar behind a railing – its far side a window front with space beyond. The bar counter stands at the right,
## round tables in the room, the crew looking for work stand about and can be spoken to. The look follows the
## station type. Deterministic from the station's id.

const CrewData = preload("res://data/crew.gd")
## floor, floor2 (corridor), shop_floor, wood (bar), carpet, wall (faces), accent
const PALETTES := {
	"trade": [Color(0.27, 0.3, 0.38), Color(0.31, 0.34, 0.43), Color(0.42, 0.38, 0.34), Color(0.46, 0.29, 0.17), Color(0.32, 0.2, 0.3), Color(0.62, 0.66, 0.76), Color(0.3, 0.85, 1.0)],
	"military": [Color(0.27, 0.29, 0.27), Color(0.31, 0.33, 0.3), Color(0.36, 0.37, 0.34), Color(0.4, 0.3, 0.2), Color(0.25, 0.28, 0.22), Color(0.52, 0.55, 0.5), Color(1.0, 0.35, 0.28)],
	"research": [Color(0.7, 0.74, 0.78), Color(0.76, 0.8, 0.83), Color(0.78, 0.8, 0.8), Color(0.62, 0.5, 0.38), Color(0.3, 0.45, 0.42), Color(0.9, 0.93, 0.95), Color(0.25, 0.85, 0.55)],
	"industry": [Color(0.3, 0.27, 0.24), Color(0.34, 0.3, 0.27), Color(0.4, 0.34, 0.28), Color(0.45, 0.3, 0.18), Color(0.35, 0.22, 0.16), Color(0.56, 0.48, 0.41), Color(1.0, 0.6, 0.15)],
	"mining_colony": [Color(0.32, 0.28, 0.23), Color(0.36, 0.31, 0.26), Color(0.42, 0.35, 0.28), Color(0.48, 0.32, 0.18), Color(0.38, 0.26, 0.16), Color(0.52, 0.43, 0.34), Color(1.0, 0.8, 0.2)],
	"agri": [Color(0.4, 0.34, 0.25), Color(0.44, 0.37, 0.28), Color(0.5, 0.43, 0.3), Color(0.52, 0.36, 0.2), Color(0.3, 0.4, 0.22), Color(0.68, 0.62, 0.5), Color(0.45, 0.9, 0.35)],
	"ice_refinery": [Color(0.58, 0.66, 0.74), Color(0.64, 0.72, 0.8), Color(0.66, 0.72, 0.78), Color(0.5, 0.4, 0.32), Color(0.3, 0.42, 0.55), Color(0.84, 0.91, 0.97), Color(0.45, 0.85, 1.0)],
	"shipyard": [Color(0.29, 0.3, 0.33), Color(0.33, 0.34, 0.37), Color(0.38, 0.38, 0.4), Color(0.44, 0.3, 0.18), Color(0.3, 0.28, 0.2), Color(0.56, 0.58, 0.62), Color(1.0, 0.85, 0.2)],
	"pirate_haven": [Color(0.17, 0.15, 0.16), Color(0.2, 0.18, 0.19), Color(0.24, 0.2, 0.2), Color(0.32, 0.2, 0.14), Color(0.3, 0.1, 0.16), Color(0.36, 0.3, 0.29), Color(1.0, 0.2, 0.35)],
	"resort": [Color(0.7, 0.65, 0.56), Color(0.75, 0.7, 0.6), Color(0.78, 0.72, 0.62), Color(0.55, 0.38, 0.22), Color(0.55, 0.3, 0.32), Color(0.93, 0.89, 0.81), Color(1.0, 0.82, 0.4)],
}
## Shops below the corridor (the bar has its own room); the ship services are terminals in the dock office.
const SHOPS := ["market", "outfitter", "shipyard", "bonds", "look", "refinery", "manufacturing", "senate", "curia", "exchange"]
const SHOP_W := 7
const DOCK_TERMINALS := ["fuel", "repair", "drones", "munitions", "hangar"]
const KIOSKS := ["news", "bulletin"]
## rows
const BAR_Y0 := 6                 # first floor row of the bar (rows 0 cap, 1–5 the window front)
const COR_Y0 := 15                # the railing row – the corridor below it to row 18
const COR_Y1 := 18
const SHOP_CAP := 19              # the corridor's south wall …
const SHOP_FACE := 20             # … the shop's back wall face, seen from inside
const SHOP_Y1 := 25               # last floor row of the shops
const LOBBY_X1 := 6               # the lift lobby: x 1 … 6, deep inside the station
const LOBBY_Y0 := COR_Y0 - 5      # its north wall (the lifts) – station all round it, not space
const CORNER_R := 6               # the window front's rounded corners (tiles)


static func palette_for(station: Dictionary) -> Dictionary:
	var t := String(station.get("type", "trade"))
	if t.begins_with("resort") or String(station.get("art", "")).begins_with("resort"):
		t = "resort"
	var p: Array = PALETTES.get(t, PALETTES["trade"])
	var wall: Color = p[5]
	return {"floor": p[0], "floor2": p[1], "shop_floor": p[2], "wood": p[3], "carpet": p[4], "wall": wall,
		"wall_top": wall.darkened(0.55), "trim": wall.darkened(0.35), "frame": wall.darkened(0.25), "accent": p[6], "type": t}


## available: service id -> "" (open) or the reason it is closed. crew: the bar's offers (GameState.bar_offers).
static func build(station: Dictionary, available: Dictionary, crew: Array = []) -> GroundMap:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(station.get("id", "x")))
	var m := GroundMap.new()
	m.pal = palette_for(station)
	m.hull_top = BAR_Y0
	m.title = String(station.get("name", "Station"))
	var shops: Array = []
	for sid in SHOPS:
		if available.has(sid):
			shops.append(sid)
	var dock: Array = []
	for d in DOCK_TERMINALS:
		if available.has(d):
			dock.append(d)
	if not dock.is_empty():
		shops.insert(0, "dock")
	var x_shops := LOBBY_X1 + 2                         # the first shop starts right of the lobby
	var W := maxi(x_shops + shops.size() * (SHOP_W - 1) + 3, 44)
	var H := SHOP_Y1 + 2
	m.setup(W, H)
	var bx0 := LOBBY_X1 + 1                             # the bar's west wall
	# ---- the bar: a big window front to the north with rounded corners, the counter at the east
	m.fill(bx0, 0, W - bx0, 1, GroundMap.T.CAP)
	m.fill(bx0, 1, W - bx0, BAR_Y0 - 1, GroundMap.T.GLASS)
	m.fill(bx0, 0, CORNER_R, CORNER_R, GroundMap.T.GLASS)
	m.fill(W - CORNER_R, 0, CORNER_R, CORNER_R, GroundMap.T.GLASS)
	m.round_corners.append({"x": bx0, "r": CORNER_R, "side": -1})
	m.round_corners.append({"x": W - 1, "r": CORNER_R, "side": 1})
	m.fill(W - 1, BAR_Y0, 1, COR_Y1 - BAR_Y0 + 2, GroundMap.T.CAP)
	m.fill(bx0, BAR_Y0, 1, COR_Y0 - BAR_Y0, GroundMap.T.CAP)
	m.fill(bx0 + 1, BAR_Y0, W - bx0 - 2, COR_Y0 - BAR_Y0, GroundMap.T.FLOOR, 3)
	# the counter, the bartender behind it, the shelves
	var cx := W - 5
	m.add_object({"kind": "counter_v", "x": cx, "y": BAR_Y0 + 1, "w": 2, "h": 6})
	m.add_object({"kind": "fridge", "x": W - 2, "y": BAR_Y0, "w": 1, "h": 1, "col": m.pal["accent"]})
	m.add_object({"kind": "fridge", "x": W - 2, "y": BAR_Y0 + 6, "w": 1, "h": 1, "col": m.pal["accent"]})
	m.people.append({"pos": Vector2(W - 2.5, BAR_Y0 + 3.6) * GroundMap.TILE, "dir": 2, "role": "bartender"})
	for sy in range(BAR_Y0 + 1, BAR_Y0 + 7, 2):
		m.add_object({"kind": "stool", "x": cx - 1, "y": sy, "col": Color(0.75, 0.25, 0.22)}, false)
		if rng.randf() < 0.45:
			m.people.append({"pos": Vector2(cx - 0.5, sy + 1.1) * GroundMap.TILE, "dir": 3, "sit": true})
	m.zones.append({"rect": Rect2(), "kind": "label", "id": "bar_sign", "title": "BAR", "col": Color(1.0, 0.82, 0.35),
		"sign": Vector2(cx + 1, BAR_Y0 + 0.2) * GroundMap.TILE, "vertical": true})
	_zone(m, "bar", available, Rect2(Vector2(cx - 2, BAR_Y0) * GroundMap.TILE, Vector2(2, 7) * GroundMap.TILE), Vector2(-100, -100))
	# round tables with chairs and guests
	var tx := bx0 + 3
	var row := 0
	while tx + 2 < cx - 3:
		var ty := BAR_Y0 + 1 + (0 if row % 2 == 0 else 4)
		m.add_object({"kind": "round_table", "x": tx, "y": ty, "w": 2, "h": 2})
		m.add_object({"kind": "chair", "x": tx - 1, "y": ty + 1, "col": Color(0.55, 0.22, 0.2), "back": "up"}, false)
		m.add_object({"kind": "chair", "x": tx + 2, "y": ty + 1, "col": Color(0.55, 0.22, 0.2), "back": "up"}, false)
		if rng.randf() < 0.6:
			m.people.append({"pos": Vector2(tx - 0.5, ty + 2.1) * GroundMap.TILE, "dir": 3, "sit": true})
		if rng.randf() < 0.5:
			m.people.append({"pos": Vector2(tx + 2.5, ty + 2.1) * GroundMap.TILE, "dir": 2, "sit": true})
		tx += 5
		row += 1
	m.add_object({"kind": "jukebox", "x": bx0 + 1, "y": BAR_Y0 + 1, "w": 1, "h": 1, "col": Color(1.0, 0.45, 0.7)})
	m.add_object({"kind": "plant", "x": cx - 3, "y": BAR_Y0, "w": 1, "h": 1})
	m.add_object({"kind": "plant", "x": bx0 + 1, "y": COR_Y0 - 1, "w": 1, "h": 1})
	m.add_object({"kind": "sofa", "x": bx0 + 2, "y": COR_Y0 - 2, "w": 3, "h": 1, "col": m.pal["carpet"]})
	m.decals.append({"kind": "rug", "x": bx0 + 6, "y": BAR_Y0 + 3, "w": 5, "h": 3, "col": m.pal["carpet"]})
	# the crew looking for work – they stand about in the bar and can be spoken to
	var spots: Array = []
	for k in 8:
		spots.append(Vector2(rng.randf_range(bx0 + 2, cx - 2), rng.randf_range(BAR_Y0 + 1.5, COR_Y0 - 1.0)))
	var placed := 0
	for i in crew.size():
		if placed >= 6:
			break
		for s in spots:
			var p: Vector2 = s * GroundMap.TILE
			if m.free_at(p, 6.0):
				spots.erase(s)
				var o: Dictionary = crew[i]
				m.people.append({"pos": p, "dir": 0, "role": "crew", "crew": i, "look": o["m"].get("look", {})})
				m.zones.append({"rect": Rect2(p - Vector2(14, 18), Vector2(28, 30)), "kind": "crew", "id": "bar", "crew": i,
					"title": "%s – %s (%s)" % [String(o["m"].get("name", "?")), CrewData.role_name(String(o["m"]["role"])), String(o["m"].get("quality", "?"))],
					"col": Color(1.0, 0.85, 0.4), "sign": Vector2(-100, -100)})
				placed += 1
				break
	# ---- the railing between the bar and the corridor, two ways in
	var gap1 := bx0 + (cx - bx0) / 3
	var gap2 := bx0 + (cx - bx0) * 2 / 3
	var rx := bx0 + 1
	while rx < W - 1:
		if absi(rx - gap1) <= 1 or absi(rx - gap2) <= 1:
			m.set_t(rx, COR_Y0, GroundMap.T.FLOOR, 0)
			rx += 1
			continue
		var run := 1
		while rx + run < W - 1 and absi(rx + run - gap1) > 1 and absi(rx + run - gap2) > 1 and run < 4:
			run += 1
		m.add_object({"kind": "railing", "x": rx, "y": COR_Y0, "w": run, "h": 1})
		rx += run
	# ---- the corridor
	m.fill(bx0, COR_Y0 + 1, W - bx0 - 1, COR_Y1 - COR_Y0, GroundMap.T.FLOOR, 0)
	m.decals.append({"kind": "guide", "x": bx0, "y": COR_Y0 + 2, "w": W - bx0 - 1, "h": 1, "col": m.pal["accent"]})
	# ---- the lift lobby
	var ly := LOBBY_Y0
	m.fill(0, ly, LOBBY_X1 + 2, 1, GroundMap.T.CAP)
	m.fill(1, ly + 1, LOBBY_X1, 2, GroundMap.T.FACE)
	m.fill(0, ly + 1, 1, SHOP_Y1 - ly + 1, GroundMap.T.CAP)
	m.fill(1, ly + 3, LOBBY_X1, 8, GroundMap.T.FLOOR, 2)
	m.fill(0, ly + 11, LOBBY_X1 + 2, SHOP_Y1 - ly - 9, GroundMap.T.CAP)
	m.fill(LOBBY_X1 + 1, ly + 1, 1, COR_Y0 - ly - 1, GroundMap.T.CAP)
	m.fill(LOBBY_X1 + 1, COR_Y1 + 1, 1, ly + 11 - COR_Y1 - 1, GroundMap.T.CAP)
	m.fill(LOBBY_X1 + 1, COR_Y0, 1, COR_Y1 - COR_Y0 + 1, GroundMap.T.FLOOR, 0)
	m.face_deco.append({"kind": "lift", "x": 1, "y": ly + 2, "w": 2, "col": Color(0.4, 1.0, 0.6)})
	m.face_deco.append({"kind": "lift", "x": 4, "y": ly + 2, "w": 2, "col": Color(0.4, 1.0, 0.6)})
	m.decals.append({"kind": "mat", "x": 1, "y": ly + 3, "w": 5, "h": 1, "col": m.pal["accent"]})
	m.spawn = Vector2(3.5, ly + 4.6) * GroundMap.TILE
	m.zones.append({"rect": Rect2(Vector2(1, ly + 3) * GroundMap.TILE, Vector2(5, 1.4) * GroundMap.TILE), "kind": "exit", "id": "ship",
		"title": "Lift to the dock – your ship", "col": Color(0.4, 1.0, 0.6), "sign": Vector2(3.5, ly + 0.7) * GroundMap.TILE})
	var kx := 2
	for k in KIOSKS:
		if available.has(k):
			m.add_object({"kind": "terminal", "x": kx, "y": ly + 9, "w": 1, "h": 1, "col": _svc_col(k), "icon": _svc_icon(k)})
			_zone(m, k, available, Rect2(Vector2(kx - 0.5, ly + 7.6) * GroundMap.TILE, Vector2(2, 1.6) * GroundMap.TILE), Vector2(kx + 0.5, ly + 8.4) * GroundMap.TILE)
			kx += 3
	m.add_object({"kind": "plant", "x": 1, "y": ly + 7, "w": 1, "h": 1})
	m.add_object({"kind": "bench", "x": 3, "y": ly + 6, "w": 2, "h": 1, "col": m.pal["accent"]})
	# ---- the shops below the corridor
	m.fill(bx0, SHOP_CAP, W - bx0, 1, GroundMap.T.CAP)
	var sx := x_shops - 1
	for s2 in shops:
		_shop(m, s2, sx, available, dock, rng, station)
		sx += SHOP_W - 1
	m.fill(sx, SHOP_CAP, W - sx, SHOP_Y1 - SHOP_CAP + 2, GroundMap.T.CAP)
	# corridor dressing: lamp posts and plants on the south side, between the doors
	var lx := bx0 + 2
	while lx < W - 2:
		if m.t_at(lx, SHOP_CAP) == GroundMap.T.CAP and m.t_at(lx - 1, SHOP_CAP) == GroundMap.T.CAP and m.t_at(lx + 1, SHOP_CAP) == GroundMap.T.CAP and m.t_at(lx, COR_Y1) == GroundMap.T.FLOOR:
			m.add_object({"kind": "plant" if (lx / 4) % 2 == 0 else "lamp_post", "x": lx, "y": COR_Y1, "w": 1, "h": 1, "col": m.pal["accent"]})
		lx += 4
	for k2 in 14:
		m.wander.append(Vector2(rng.randf_range(bx0 + 1, W - 3), rng.randf_range(COR_Y0 + 1.3, COR_Y1 - 0.1)) * GroundMap.TILE)
	for k3 in 4:
		m.wander.append(Vector2(rng.randf_range(bx0 + 2, cx - 3), rng.randf_range(BAR_Y0 + 1.5, COR_Y0 - 1.2)) * GroundMap.TILE)
	return m


static func _svc(id: String) -> Dictionary:
	for s in GameData.services:
		if String(s["id"]) == id:
			return s
	return {}


static func _svc_col(id: String) -> Color:
	var s := _svc(id)
	return GameData.corp(String(s.get("corp", ""))).get("color", Color(0.4, 0.8, 1.0)) if not s.is_empty() else Color(0.4, 0.8, 1.0)


static func _svc_icon(id: String) -> String:
	return String(_svc(id).get("icon", "o_cargo"))


static func _zone(m: GroundMap, id: String, available: Dictionary, r: Rect2, sign: Vector2) -> void:
	var s := _svc(id)
	m.zones.append({"rect": r, "kind": "service", "id": id, "title": String(s.get("title", id)),
		"corp": String(GameData.corp(String(s.get("corp", ""))).get("name", "")), "col": _svc_col(id),
		"closed": String(available.get(id, "")), "sign": sign})


## One shop room below the corridor: a door in the corridor's wall, its back wall (seen from inside) with shelves,
## the counter along the right side with the shopkeeper behind it.
static func _shop(m: GroundMap, id: String, sx: int, available: Dictionary, dock: Array, rng: RandomNumberGenerator, station: Dictionary) -> void:
	var rw := SHOP_W
	m.fill(sx, SHOP_CAP, rw, SHOP_Y1 - SHOP_CAP + 2, GroundMap.T.CAP)
	m.fill(sx + 1, SHOP_FACE, rw - 2, 1, GroundMap.T.FACE)
	m.fill(sx + 1, SHOP_FACE + 1, rw - 2, SHOP_Y1 - SHOP_FACE, GroundMap.T.FLOOR, 1)
	var dx := sx + rw / 2 - 1
	m.fill(dx, SHOP_CAP, 2, 2, GroundMap.T.DOOR, 1)
	var col: Color = _svc_col(id) if id != "dock" else m.pal["accent"]
	var sign := Vector2(dx + 1, SHOP_CAP + 0.55) * GroundMap.TILE
	var inside := Rect2(Vector2(sx + 1, SHOP_FACE + 1) * GroundMap.TILE, Vector2(rw - 2, SHOP_Y1 - SHOP_FACE) * GroundMap.TILE)
	if id == "dock":
		var tx := sx + 1
		for d in dock:
			if tx >= sx + rw - 1:
				break
			m.add_object({"kind": "terminal", "x": tx, "y": SHOP_FACE + 1, "w": 1, "h": 1, "col": _svc_col(d), "icon": _svc_icon(d)})
			_zone(m, d, available, Rect2(Vector2(tx - 0.1, SHOP_FACE + 1.4) * GroundMap.TILE, Vector2(1.2, 1.6) * GroundMap.TILE),
				Vector2(-100, -100))
			tx += 1
		m.zones.append({"rect": Rect2(), "kind": "label", "title": "Dock Office", "col": col, "sign": sign, "id": "dock"})
		m.add_object({"kind": "plant", "x": sx + rw - 2, "y": SHOP_Y1, "w": 1, "h": 1})
		return
	_zone(m, id, available, inside, sign)
	var deco := "shelf"
	match id:
		"outfitter":
			deco = "rack"
		"shipyard", "exchange", "senate", "curia", "bonds":
			deco = "screen"
		"look":
			deco = "poster"
	for fx in range(sx + 1, sx + rw - 1, 2):
		if fx + 1 < sx + rw - 1 and not (fx <= dx + 1 and fx + 1 >= dx):
			m.face_deco.append({"kind": deco, "x": fx, "y": SHOP_FACE, "w": 2, "col": col})
	# the counter on the right, the shopkeeper behind it facing the room
	m.add_object({"kind": "counter_v", "x": sx + rw - 3, "y": SHOP_FACE + 2, "w": 1, "h": 3})
	m.people.append({"pos": Vector2(sx + rw - 1.5, SHOP_FACE + 3.8) * GroundMap.TILE, "dir": 2, "role": "keeper"})
	match id:
		"market":
			m.add_object({"kind": "crates", "x": sx + 1, "y": SHOP_Y1, "w": 2, "h": 1})
		"outfitter", "shipyard":
			m.add_object({"kind": "display", "x": sx + 1, "y": SHOP_Y1 - 1, "w": 2, "h": 1, "col": col})
		"refinery", "manufacturing":
			m.add_object({"kind": "machine", "x": sx + 1, "y": SHOP_Y1 - 1, "w": 2, "h": 2})
		_:
			m.add_object({"kind": "plant", "x": sx + 1, "y": SHOP_Y1, "w": 1, "h": 1})
	m.decals.append({"kind": "mat", "x": dx, "y": SHOP_FACE + 1, "w": 2, "h": 1, "col": col})
