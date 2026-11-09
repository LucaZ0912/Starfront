class_name DeckGen
extends RefCounted
## Package 49: the walkable deck of a station – an airlock where your ship lies, a promenade down the middle, shops
## and the bar as rooms on both sides, the ship services as terminals in a dock office, news and the bulletin board
## as kiosks. Its look follows the station type. Deterministic from the station's id.

## Floor, walls, accent (lights, signs) per station type.
const PALETTES := {
	"trade": {"floor": Color(0.2, 0.23, 0.3), "floor2": Color(0.24, 0.28, 0.36), "room_floor": Color(0.26, 0.27, 0.33), "wall": Color(0.58, 0.63, 0.74), "wall_dark": Color(0.3, 0.33, 0.42), "accent": Color(0.3, 0.85, 1.0)},
	"military": {"floor": Color(0.21, 0.23, 0.21), "floor2": Color(0.25, 0.27, 0.24), "room_floor": Color(0.24, 0.25, 0.24), "wall": Color(0.47, 0.5, 0.45), "wall_dark": Color(0.27, 0.29, 0.26), "accent": Color(1.0, 0.32, 0.25)},
	"research": {"floor": Color(0.66, 0.7, 0.74), "floor2": Color(0.72, 0.76, 0.8), "room_floor": Color(0.7, 0.74, 0.76), "wall": Color(0.9, 0.93, 0.95), "wall_dark": Color(0.55, 0.6, 0.65), "accent": Color(0.25, 0.9, 0.55)},
	"industry": {"floor": Color(0.24, 0.21, 0.19), "floor2": Color(0.28, 0.25, 0.22), "room_floor": Color(0.27, 0.24, 0.21), "wall": Color(0.52, 0.44, 0.37), "wall_dark": Color(0.3, 0.25, 0.21), "accent": Color(1.0, 0.6, 0.15)},
	"mining_colony": {"floor": Color(0.27, 0.23, 0.19), "floor2": Color(0.31, 0.26, 0.21), "room_floor": Color(0.3, 0.26, 0.22), "wall": Color(0.47, 0.38, 0.3), "wall_dark": Color(0.28, 0.22, 0.17), "accent": Color(1.0, 0.8, 0.2)},
	"agri": {"floor": Color(0.33, 0.27, 0.19), "floor2": Color(0.37, 0.3, 0.21), "room_floor": Color(0.36, 0.3, 0.22), "wall": Color(0.62, 0.57, 0.46), "wall_dark": Color(0.38, 0.34, 0.26), "accent": Color(0.45, 0.9, 0.35)},
	"ice_refinery": {"floor": Color(0.52, 0.6, 0.68), "floor2": Color(0.58, 0.66, 0.74), "room_floor": Color(0.56, 0.63, 0.7), "wall": Color(0.82, 0.9, 0.96), "wall_dark": Color(0.5, 0.58, 0.68), "accent": Color(0.45, 0.85, 1.0)},
	"shipyard": {"floor": Color(0.24, 0.25, 0.27), "floor2": Color(0.28, 0.29, 0.31), "room_floor": Color(0.27, 0.28, 0.3), "wall": Color(0.52, 0.54, 0.57), "wall_dark": Color(0.3, 0.31, 0.34), "accent": Color(1.0, 0.85, 0.2)},
	"pirate_haven": {"floor": Color(0.12, 0.11, 0.12), "floor2": Color(0.15, 0.13, 0.14), "room_floor": Color(0.15, 0.13, 0.14), "wall": Color(0.33, 0.27, 0.26), "wall_dark": Color(0.18, 0.15, 0.15), "accent": Color(1.0, 0.2, 0.32)},
	"resort": {"floor": Color(0.62, 0.58, 0.5), "floor2": Color(0.68, 0.64, 0.55), "room_floor": Color(0.66, 0.6, 0.52), "wall": Color(0.92, 0.88, 0.8), "wall_dark": Color(0.6, 0.52, 0.4), "accent": Color(1.0, 0.82, 0.4)},
}
## Rooms (a service each) – the bar is the big one; ship services sit as terminals in the dock office.
const ROOM_W := {"bar": 11, "market": 8, "outfitter": 8, "shipyard": 9, "bonds": 7, "look": 7, "refinery": 8,
	"manufacturing": 8, "senate": 8, "curia": 8, "exchange": 8}
const DOCK_TERMINALS := ["fuel", "repair", "drones", "munitions", "hangar"]
const KIOSKS := ["news", "bulletin"]
const ROOM_H := 8
const PROM_H := 6


static func palette_for(station: Dictionary) -> Dictionary:
	var t := String(station.get("type", "trade"))
	if t in ["resort", "resort_habitat", "resort_bio"] or String(station.get("art", "")).begins_with("resort"):
		t = "resort"
	return (PALETTES.get(t, PALETTES["trade"]) as Dictionary).duplicate()


## available: service id -> "" (open) or the reason it is closed (StationUI.service_available).
static func build(station: Dictionary, available: Dictionary, look_seed: int = 0) -> GroundMap:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(station.get("id", "x"))) + look_seed
	var m := GroundMap.new()
	m.pal = palette_for(station)
	m.title = String(station.get("name", "Station"))
	var rooms: Array = []
	for sid in available:
		if ROOM_W.has(sid):
			rooms.append(sid)
	rooms.sort_custom(func(a, b): return int(a == "bar") > int(b == "bar"))       # the bar first, by the airlock
	var dock: Array = []
	for d in DOCK_TERMINALS:
		if available.has(d):
			dock.append(d)
	var tier := clampi(int(station.get("tier", 1)), 1, 3)
	# split the rooms over the two sides, the dock office first on the top side
	var top: Array = ["dock"] if not dock.is_empty() else []
	var bottom: Array = []
	var wt := 9 if not dock.is_empty() else 0
	var wb := 0
	for r in rooms:
		if wb <= wt:
			bottom.append(r)
			wb += int(ROOM_W[r])
		else:
			top.append(r)
			wt += int(ROOM_W[r])
	var ax := 9                                       # the airlock starts here – your ship lies in the space left of it
	var x0 := ax + 6                                  # the promenade starts after the airlock
	var length := maxi(maxi(wt, wb) + 4 + tier * 2, 30)
	var W := x0 + length + 2
	var H := 1 + ROOM_H + PROM_H + ROOM_H + 1
	m.setup(W, H)
	var py0 := 1 + ROOM_H                              # promenade rows py0 … py0+PROM_H-1
	# the promenade and the hull round it
	m.fill(x0 - 1, py0 - 1, length + 2, PROM_H + 2, GroundMap.T.WALL)
	m.fill(x0, py0, length, PROM_H, GroundMap.T.FLOOR, 0)
	# the airlock: your ship lies beyond the window
	m.room(ax, py0 - 2, x0 - ax, PROM_H + 4, 2)
	m.fill(x0 - 1, py0 + 2, 1, 2, GroundMap.T.DOOR, 2)
	m.fill(ax, py0, 1, PROM_H, GroundMap.T.WINDOW)
	m.fill(ax, py0 + 2, 1, 2, GroundMap.T.DOOR, 2)              # the hatch to the docking tube
	m.props.append({"kind": "stripes", "x": ax + 1, "y": py0 - 1, "w": x0 - ax - 2, "h": 1})
	m.props.append({"kind": "stripes", "x": ax + 1, "y": py0 + PROM_H, "w": x0 - ax - 2, "h": 1})
	m.spawn = Vector2(ax + 2.5, py0 + 3.0) * GroundMap.TILE
	m.zones.append({"rect": Rect2(Vector2(ax, py0) * GroundMap.TILE, Vector2(2.2, PROM_H) * GroundMap.TILE), "kind": "exit", "id": "ship",
		"title": "Your ship", "col": Color(0.4, 1.0, 0.6), "sign": Vector2(ax + 2.5, py0 - 1.4) * GroundMap.TILE})
	m.dock_at = Vector2(ax - 0.5, py0 + 3.0) * GroundMap.TILE                # the ship's nose touches the hatch here
	# windows in the outer hull of the promenade's far end
	m.fill(x0 + length, py0 + 1, 1, PROM_H - 2, GroundMap.T.WINDOW)
	# rooms on both sides
	_side(m, top, x0, py0, true, available, rng, dock, station)
	_side(m, bottom, x0, py0, false, available, rng, dock, station)
	# the promenade: pillars, planters, benches, holo adverts, kiosks
	var kiosk_x := x0 + 3
	for k in KIOSKS:
		if available.has(k):
			m.props.append({"kind": "terminal", "x": kiosk_x, "y": py0 + PROM_H / 2 - 1, "w": 1, "h": 1, "col": _svc_col(k), "icon": _svc_icon(k)})
			m.set_t(kiosk_x, py0 + PROM_H / 2 - 1, GroundMap.T.BLOCK)
			_zone(m, k, available, Rect2(Vector2(kiosk_x - 0.6, py0 + PROM_H / 2 - 1.6) * GroundMap.TILE, Vector2(2.2, 2.2) * GroundMap.TILE),
				Vector2(kiosk_x + 0.5, py0 + PROM_H / 2 - 1.3) * GroundMap.TILE)
			kiosk_x += 3
	var deco := ["planter", "bench", "holo", "planter", "pillar"]
	if String(station.get("type", "")) in ["industry", "mining_colony", "shipyard"]:
		deco = ["crates", "pillar", "machine", "bench", "crates"]
	elif String(station.get("type", "")) == "pirate_haven":
		deco = ["crates", "holo", "crates", "pillar"]
	elif String(station.get("type", "")) == "military":
		deco = ["pillar", "crates", "bench", "pillar"]
	var xx := kiosk_x + 2
	var i := 0
	while xx < x0 + length - 3:
		var kd: String = deco[i % deco.size()]
		var row := py0 + (0 if i % 2 == 0 else PROM_H - 1)
		var dw := 2 if kd in ["bench", "crates", "machine", "holo"] else 1
		# keep the doorways clear
		var clear := true
		for cx in range(xx - 1, xx + dw + 1):
			clear = clear and m.t_at(cx, row - 1) != GroundMap.T.DOOR and m.t_at(cx, row + 1) != GroundMap.T.DOOR
		if clear:
			m.props.append({"kind": kd, "x": xx, "y": row, "w": dw, "h": 1, "col": m.pal["accent"]})
			m.fill(xx, row, dw, 1, GroundMap.T.BLOCK)
		xx += rng.randi_range(4, 6)
		i += 1
	if String(station.get("type", "")) == "resort":
		var fx := x0 + length / 2
		m.props.append({"kind": "fountain", "x": fx, "y": py0 + 2, "w": 2, "h": 2})
		m.fill(fx, py0 + 2, 2, 2, GroundMap.T.BLOCK)
	for k2 in 14:
		m.wander.append(Vector2(rng.randf_range(x0 + 1, x0 + length - 1), rng.randf_range(py0 + 0.8, py0 + PROM_H - 0.8)) * GroundMap.TILE)
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


## One side of the promenade: rooms in a row, each with its door onto the promenade.
static func _side(m: GroundMap, list: Array, x0: int, py0: int, top: bool, available: Dictionary, rng: RandomNumberGenerator, dock: Array, station: Dictionary) -> void:
	var x := x0
	for r in list:
		var rw: int = 9 if r == "dock" else int(ROOM_W[r])
		var ry: int = py0 - 1 - ROOM_H if top else py0 + PROM_H
		m.room(x, ry, rw, ROOM_H + 1, 3 if r == "bar" else 1)
		# the shared wall with the promenade gets a door in the middle
		var wall_y: int = py0 - 1 if top else py0 + PROM_H
		var dx := x + rw / 2 - 1
		m.fill(dx, wall_y, 2, 1, GroundMap.T.DOOR, 1)
		var inner_y0: int = ry + 1
		var inner_y1: int = ry + ROOM_H - 1                                 # last floor row
		var back_y: int = inner_y0 if top else inner_y1                     # the row against the outer wall
		var sign := Vector2(dx + 1, (wall_y + 1.3) if top else (wall_y - 0.3)) * GroundMap.TILE
		var door_zone := Rect2(Vector2(x + 1, inner_y0) * GroundMap.TILE, Vector2(rw - 2, inner_y1 - inner_y0 + 1) * GroundMap.TILE)
		if r == "dock":
			# the dock office: a terminal for each ship service against the back wall
			var step := maxi(1, (rw - 2) / maxi(dock.size(), 1))
			for di in dock.size():
				var d: String = dock[di]
				var tx: int = x + 1 + di * step
				m.props.append({"kind": "terminal", "x": tx, "y": back_y, "w": 1, "h": 1, "col": _svc_col(d), "icon": _svc_icon(d)})
				m.set_t(tx, back_y, GroundMap.T.BLOCK)
				var front_y: int = back_y + 1 if top else back_y - 1
				_zone(m, d, available, Rect2(Vector2(tx - 0.2, min(back_y, front_y)) * GroundMap.TILE, Vector2(1.4, 2) * GroundMap.TILE),
					Vector2(tx + 0.5, (back_y + 1.6) if top else (back_y - 0.6)) * GroundMap.TILE)
			m.zones.append({"rect": Rect2(), "kind": "label", "title": "Dock Office", "col": m.pal["accent"], "sign": sign, "id": "dock"})
			x += rw - 1
			continue
		_zone(m, r, available, door_zone, sign)
		_furnish(m, r, x, rw, inner_y0, inner_y1, back_y, top, rng, station)
		var front_y: int = inner_y1 if top else inner_y0                # the row by the door
		for cx in [x + 1, x + rw - 2]:
			if m.t_at(cx, front_y) == GroundMap.T.FLOOR:
				m.props.append({"kind": "planter", "x": cx, "y": front_y, "w": 1, "h": 1})
				m.set_t(cx, front_y, GroundMap.T.BLOCK)
		var outer_y: int = ry if top else ry + ROOM_H
		for sx in range(x + 2, x + rw - 2, 3):
			m.props.append({"kind": "wallscreen", "x": sx, "y": outer_y, "w": 1, "h": 1, "col": _svc_col(r)})
		x += rw - 1


## What stands in a room.
static func _furnish(m: GroundMap, r: String, x: int, rw: int, y0: int, y1: int, back_y: int, top: bool, rng: RandomNumberGenerator, station: Dictionary) -> void:
	var col := _svc_col(r)
	var mid_y: int = (y0 + y1) / 2
	var dir := 1 if top else -1
	var counter_y: int = back_y + 2 * dir                              # shelf at the back, the keeper, then the counter
	match r:
		"bar":
			m.props.append({"kind": "bar_counter", "x": x + 2, "y": counter_y, "w": rw - 4, "h": 1})
			m.fill(x + 2, counter_y, rw - 4, 1, GroundMap.T.BLOCK)
			m.props.append({"kind": "shelf", "x": x + 2, "y": back_y, "w": rw - 4, "h": 1})
			m.fill(x + 1, back_y, rw - 2, 1, GroundMap.T.BLOCK)
			m.people.append({"pos": Vector2(x + rw / 2.0, back_y + dir + 0.5) * GroundMap.TILE, "facing": PI * 0.5 if top else -PI * 0.5, "role": "bartender"})
			var stool_y: int = counter_y + dir
			for k in range(x + 3, x + rw - 3, 2):
				m.props.append({"kind": "stool", "x": k, "y": stool_y})
				if rng.randf() < 0.5:
					m.people.append({"pos": (Vector2(k, stool_y) + Vector2(0.5, 0.5)) * GroundMap.TILE, "facing": -PI * 0.5 if top else PI * 0.5, "sit": true})
			var ty: int = stool_y + (1 if top else -2)
			for k2 in range(x + 2, x + rw - 3, 4):
				if ty >= y0 and ty + 1 <= y1:
					m.props.append({"kind": "table", "x": k2, "y": ty, "w": 2, "h": 2})
					m.fill(k2, ty, 2, 2, GroundMap.T.BLOCK)
					if rng.randf() < 0.6:
						m.people.append({"pos": (Vector2(k2 - 0.4, ty + 1)) * GroundMap.TILE, "facing": 0.0, "sit": true})
		"market":
			m.props.append({"kind": "counter", "x": x + 2, "y": counter_y, "w": rw - 4, "h": 1, "col": col})
			m.fill(x + 2, counter_y, rw - 4, 1, GroundMap.T.BLOCK)
			m.props.append({"kind": "crates", "x": x + 1, "y": back_y, "w": rw - 2, "h": 1})
			m.fill(x + 1, back_y, rw - 2, 1, GroundMap.T.BLOCK)
			_keeper(m, x, rw, back_y, top)
		"outfitter":
			m.props.append({"kind": "rack", "x": x + 1, "y": back_y, "w": rw - 2, "h": 1, "col": col})
			m.fill(x + 1, back_y, rw - 2, 1, GroundMap.T.BLOCK)
			m.props.append({"kind": "counter", "x": x + 2, "y": counter_y, "w": rw - 4, "h": 1, "col": col})
			m.fill(x + 2, counter_y, rw - 4, 1, GroundMap.T.BLOCK)
			_keeper(m, x, rw, back_y, top)
		"shipyard":
			var wy: int = y0 - 1 if top else y1 + 1
			m.fill(x + 1, wy, rw - 2, 1, GroundMap.T.WINDOW)
			m.props.append({"kind": "ship", "x": x + 2, "y": back_y, "w": rw - 4, "h": 2 if top else 1, "hull": _yard_hull(station)})
			m.fill(x + 2, back_y, rw - 4, 1, GroundMap.T.BLOCK)
			m.props.append({"kind": "counter", "x": x + 3, "y": mid_y, "w": rw - 6, "h": 1, "col": col})
			m.fill(x + 3, mid_y, rw - 6, 1, GroundMap.T.BLOCK)
		"bonds", "exchange", "senate", "curia":
			m.props.append({"kind": "rug", "x": x + 2, "y": mid_y - 1, "w": rw - 4, "h": 3, "col": col})
			m.props.append({"kind": "counter", "x": x + 2, "y": counter_y, "w": rw - 4, "h": 1, "col": col})
			m.fill(x + 2, counter_y, rw - 4, 1, GroundMap.T.BLOCK)
			m.props.append({"kind": "terminal", "x": x + 1, "y": back_y, "w": 1, "h": 1, "col": col, "icon": _svc_icon(r)})
			m.set_t(x + 1, back_y, GroundMap.T.BLOCK)
			_keeper(m, x, rw, back_y, top)
		"look":
			m.props.append({"kind": "mirror", "x": x + 2, "y": back_y, "w": rw - 4, "h": 1})
			m.fill(x + 2, back_y, rw - 4, 1, GroundMap.T.BLOCK)
			m.props.append({"kind": "stool", "x": x + rw / 2, "y": counter_y})
			m.props.append({"kind": "holo", "x": x + 1, "y": mid_y, "w": 1, "h": 2, "col": Color(1.0, 0.45, 0.8)})
		"refinery", "manufacturing":
			m.props.append({"kind": "machine", "x": x + 1, "y": back_y, "w": rw - 2, "h": 1})
			m.fill(x + 1, back_y, rw - 2, 1, GroundMap.T.BLOCK)
			m.props.append({"kind": "counter", "x": x + 2, "y": mid_y, "w": rw - 4, "h": 1, "col": col})
			m.fill(x + 2, mid_y, rw - 4, 1, GroundMap.T.BLOCK)


static func _keeper(m: GroundMap, x: int, rw: int, back_y: int, top: bool) -> void:
	m.people.append({"pos": (Vector2(x + rw / 2.0, back_y + 0.5) + Vector2(0, 1.0 if top else -1.0)) * GroundMap.TILE,
		"facing": PI * 0.5 if top else -PI * 0.5, "role": "keeper"})


static func _yard_hull(station: Dictionary) -> String:
	var yard: Array = station.get("shipyard", [])
	for h in yard:
		if PixelArt.ShipArt.SHIPS.has(String(h)):
			return String(h)
	return "dragonfly"
