extends RefCounted
## 0.7.52.23 (Luz): the debug vault – a closed room inside a space station to try the tools in one go. You come in by
## the airlock at the south. At the top of the room a sealed blast door (0.7.52.24: the wide one); beside it a
## maintenance box to cut open, the door's release button behind its flap. Through the door the vault: a relic in a
## laser cage, and at the side a terminal – hack it (an E-Breach) and switch the lasers off, then scan the crystal.
## 0.7.52.24: the terminal also opens the small blast door in the vault's back wall – a niche with a carved tablet.
## No class_name: preload it.

const ExploreNode = preload("res://scripts/ground/explore.gd")
const TILE := GroundMap.TILE
const W := 30
const H := 31
const DOOR := Rect2i(12, 15, 6, 4)          # the wide blast door's gap in the wall (tiles)
const DOOR_SMALL := Rect2i(14, 4, 2, 3)     # the small one, into the niche
const CAGE := Rect2i(12, 9, 6, 3)           # the laser cage's footprint (tiles)
## 0.7.52.27 (Luz): the air shaft – from the start room's north wall up behind the vault's west wall into the vault
const DUCT := [[6, 18], [6, 17], [6, 16], [6, 15], [6, 14], [6, 13], [6, 12], [6, 11], [6, 10], [7, 10]]


static func build(site: Dictionary) -> GroundMap:
	var m := GroundMap.new()
	m.pal = DeckGen.palette_for({"type": "military"}).duplicate()
	m.pal["accent"] = Color(1.0, 0.45, 0.3)
	m.title = String(site.get("name", "Debug Vault"))
	m.hull_top = -60
	m.setup(W, H)
	m.fill(0, 0, W, H, GroundMap.T.CAP)
	# the niche (top), the vault, the room you come into (south) – each with its north wall's face of two rows
	m.fill(12, 0, 6, 2, GroundMap.T.FACE)
	m.fill(12, 2, 6, 2, GroundMap.T.FLOOR, 1)
	m.fill(8, 5, 14, 2, GroundMap.T.FACE)
	m.fill(8, 7, 14, 8, GroundMap.T.FLOOR, 1)
	m.fill(5, 17, 20, 2, GroundMap.T.FACE)
	m.fill(5, 19, 20, 11, GroundMap.T.FLOOR, 0)
	for dr in [DOOR, DOOR_SMALL]:
		m.fill(dr.position.x, dr.position.y, dr.size.x, dr.size.y, GroundMap.T.BLOCK, 1)        # sealed (open: DOOR)
	m.fill(CAGE.position.x, CAGE.position.y, CAGE.size.x, CAGE.size.y, GroundMap.T.BLOCK, 1)    # the lasers keep you out
	for dc in DUCT:
		m.set_t(int(dc[0]), int(dc[1]), m.t_at(int(dc[0]), int(dc[1])), 16)     # the shaft (0.7.52.28: wall until it is cut open)
	# floors, stripes, pipes, screens and lamps
	m.decals.append({"kind": "stripes", "x": 11, "y": 19, "w": 8, "h": 1})
	m.decals.append({"kind": "stripes", "x": 13, "y": 29, "w": 4, "h": 1})
	m.decals.append({"kind": "guide", "x": 6, "y": 23, "w": 18, "h": 1, "col": Color(1.0, 0.45, 0.3)})
	m.decals.append({"kind": "guide", "x": 9, "y": 13, "w": 12, "h": 1, "col": Color(0.4, 0.9, 1.0)})
	m.decals.append({"kind": "piperun", "x": 8, "y": 7, "w": 3, "h": 1})
	m.decals.append({"kind": "piperun", "x": 19, "y": 7, "w": 3, "h": 1})
	for fd in [[9, 17, "lamp", 1], [20, 17, "lamp", 1], [22, 17, "screen", 2], [9, 5, "screen", 2], [19, 5, "screen", 2], [11, 5, "lamp", 1], [18, 5, "lamp", 1]]:
		m.face_deco.append({"kind": String(fd[2]), "x": int(fd[0]), "y": int(fd[1]), "w": int(fd[3]), "col": Color(1.0, 0.45, 0.3) if int(fd[1]) == 17 else Color(0.4, 0.9, 1.0)})
	for lp in [[7, 20], [23, 20], [7, 28], [23, 28], [15, 25]]:
		m.lights.append({"pos": Vector2(lp[0], lp[1]) * TILE, "r": 40.0, "col": Color(1.0, 0.55, 0.4), "a": 0.35})
	m.lights.append({"pos": Vector2(15, 10.5) * TILE, "r": 70.0, "col": Color(1.0, 0.25, 0.2), "a": 0.4, "flicker": true, "id": "cage"})
	for lv in [[10, 9], [20, 9], [10, 13], [20, 13]]:
		m.lights.append({"pos": Vector2(lv[0], lv[1]) * TILE, "r": 36.0, "col": Color(0.4, 0.85, 1.0), "a": 0.3})
	m.lights.append({"pos": Vector2(15, 3) * TILE, "r": 30.0, "col": Color(1.0, 0.85, 0.6), "a": 0.3})
	m.add_object({"kind": "crates", "x": 6, "y": 26, "w": 2, "h": 1})
	m.add_object({"kind": "barrel", "x": 23, "y": 25, "w": 1, "h": 1})
	m.add_object({"kind": "barrel", "x": 22, "y": 28, "w": 1, "h": 1})
	# the airlock you came by (back to your ship)
	m.spawn = Vector2(15, 27.5) * TILE
	m.zones.append({"rect": Rect2(Vector2(13, 28.6) * TILE, Vector2(4, 1.4) * TILE), "kind": "exit", "id": "ship",
		"title": "Airlock – back to your ship", "col": Color(0.4, 1.0, 0.6), "sign": Vector2(-100, -100)})
	# the things: the doors, the box beside the wide one (the button behind the flap), the cage, the relic, the
	# terminal (lasers, the small door), the tablet in the niche
	var door := ExploreNode.add(m, "blastdoor", Vector2(DOOR.position.x + DOOR.size.x * 0.5, DOOR.end.y) * TILE,
		{"tiles": [DOOR.position.x, DOOR.position.y, DOOR.size.x, DOOR.size.y], "seed": 11})
	var di := m.explore.find(door)
	var small := ExploreNode.add(m, "blastdoor", Vector2(DOOR_SMALL.position.x + DOOR_SMALL.size.x * 0.5, DOOR_SMALL.end.y) * TILE,
		{"tiles": [DOOR_SMALL.position.x, DOOR_SMALL.position.y, DOOR_SMALL.size.x, DOOR_SMALL.size.y], "seed": 5})
	var si := m.explore.find(small)
	ExploreNode.add(m, "panel", Vector2(19.5, 19) * TILE, {"inside": "button", "door": di, "shape": "notched", "seed": 4242})
	var cage := ExploreNode.add(m, "cage", Vector2(15, 11.6) * TILE, {"tiles": [CAGE.position.x, CAGE.position.y, CAGE.size.x, CAGE.size.y], "no_zone": true})
	var ci := m.explore.find(cage)
	ExploreNode.add(m, "relic", Vector2(15, 10.9) * TILE, {"cage": ci, "no_zone": true})
	ExploreNode.add(m, "terminal", Vector2(20, 9.2) * TILE, {"actions": ["lasers", "door", "power", "data"], "cage": ci, "door": si, "seed": 77})
	ExploreNode.add(m, "tablet", Vector2(15, 3.2) * TILE, {"seed": 3})
	var vent := ExploreNode.add(m, "vent", Vector2(6.5, 19) * TILE, {"duct": DUCT, "label": "VENT-06", "seed": 606})        # 0.7.52.27
	ExploreNode.add(m, "vent_end", Vector2(8, 11) * TILE, {"no_zone": true, "vent": m.explore.find(vent)})
	return m
