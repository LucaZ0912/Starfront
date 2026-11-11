extends RefCounted
## 0.7.52.23 (Luz): the debug vault – a closed room inside a space station to try the tools in one go. You come in by
## the airlock at the south. At the top of the room a sealed blast door; beside it a maintenance box to cut open, the
## door's release button behind its flap. Through the door the vault: a relic in a laser cage, and at the side a
## terminal – hack it and switch the lasers off, then scan the crystal.
## No class_name: preload it.

const ExploreNode = preload("res://scripts/ground/explore.gd")
const TILE := GroundMap.TILE
const W := 30
const H := 30
const DOOR := Rect2i(14, 12, 2, 4)          # the blast door's gap in the wall (tiles)
const CAGE := Rect2i(12, 6, 6, 3)           # the laser cage's footprint (tiles)


static func build(site: Dictionary) -> GroundMap:
	var m := GroundMap.new()
	m.pal = DeckGen.palette_for({"type": "military"}).duplicate()
	m.pal["accent"] = Color(1.0, 0.45, 0.3)
	m.title = String(site.get("name", "Debug Vault"))
	m.hull_top = -60
	m.setup(W, H)
	m.fill(0, 0, W, H, GroundMap.T.CAP)
	# the vault (north), its wall face; the wall between with the door's gap; the room you come into (south)
	m.fill(8, 2, 14, 2, GroundMap.T.FACE)
	m.fill(8, 4, 14, 8, GroundMap.T.FLOOR, 1)
	m.fill(5, 14, 20, 2, GroundMap.T.FACE)
	m.fill(5, 16, 20, 11, GroundMap.T.FLOOR, 0)
	m.fill(DOOR.position.x, DOOR.position.y, DOOR.size.x, DOOR.size.y, GroundMap.T.BLOCK, 1)      # sealed (it opens: DOOR)
	m.fill(CAGE.position.x, CAGE.position.y, CAGE.size.x, CAGE.size.y, GroundMap.T.BLOCK, 1)      # the lasers keep you out
	# floors, stripes, pipes, screens and lamps
	m.decals.append({"kind": "stripes", "x": 13, "y": 16, "w": 4, "h": 1})
	m.decals.append({"kind": "stripes", "x": 13, "y": 26, "w": 4, "h": 1})
	m.decals.append({"kind": "guide", "x": 6, "y": 20, "w": 18, "h": 1, "col": Color(1.0, 0.45, 0.3)})
	m.decals.append({"kind": "guide", "x": 9, "y": 10, "w": 12, "h": 1, "col": Color(0.4, 0.9, 1.0)})
	m.decals.append({"kind": "piperun", "x": 8, "y": 4, "w": 3, "h": 1})
	m.decals.append({"kind": "piperun", "x": 19, "y": 4, "w": 3, "h": 1})
	for fd in [[6, 14, "screen", 2], [9, 14, "lamp", 1], [20, 14, "lamp", 1], [22, 14, "screen", 2], [9, 2, "screen", 2], [19, 2, "screen", 2], [12, 2, "lamp", 1], [17, 2, "lamp", 1]]:
		m.face_deco.append({"kind": String(fd[2]), "x": int(fd[0]), "y": int(fd[1]), "w": int(fd[3]), "col": Color(1.0, 0.45, 0.3) if int(fd[1]) == 14 else Color(0.4, 0.9, 1.0)})
	for lp in [[7, 17], [23, 17], [7, 25], [23, 25], [15, 22]]:
		m.lights.append({"pos": Vector2(lp[0], lp[1]) * TILE, "r": 40.0, "col": Color(1.0, 0.55, 0.4), "a": 0.35})
	m.lights.append({"pos": Vector2(15, 7.5) * TILE, "r": 70.0, "col": Color(1.0, 0.25, 0.2), "a": 0.4, "flicker": true, "id": "cage"})
	for lv in [[10, 6], [20, 6], [10, 10], [20, 10]]:
		m.lights.append({"pos": Vector2(lv[0], lv[1]) * TILE, "r": 36.0, "col": Color(0.4, 0.85, 1.0), "a": 0.3})
	m.add_object({"kind": "crates", "x": 6, "y": 23, "w": 2, "h": 1})
	m.add_object({"kind": "barrel", "x": 23, "y": 22, "w": 1, "h": 1})
	m.add_object({"kind": "barrel", "x": 22, "y": 25, "w": 1, "h": 1})
	# the airlock you came by (back to your ship)
	m.spawn = Vector2(15, 24.5) * TILE
	m.zones.append({"rect": Rect2(Vector2(13, 25.6) * TILE, Vector2(4, 1.4) * TILE), "kind": "exit", "id": "ship",
		"title": "Airlock – back to your ship", "col": Color(0.4, 1.0, 0.6), "sign": Vector2(-100, -100)})
	# the things: the door, the box beside it (the button behind the flap), the cage, the relic, the terminal
	var door := ExploreNode.add(m, "blastdoor", Vector2(DOOR.position.x + 1, DOOR.end.y) * TILE, {"tiles": [DOOR.position.x, DOOR.position.y, DOOR.size.x, DOOR.size.y]})
	var di := m.explore.find(door)
	ExploreNode.add(m, "panel", Vector2(18.5, 17.2) * TILE, {"inside": "button", "door": di, "shape": "notched", "seed": 4242})
	var cage := ExploreNode.add(m, "cage", Vector2(15, 8.6) * TILE, {"tiles": [CAGE.position.x, CAGE.position.y, CAGE.size.x, CAGE.size.y], "no_zone": true})
	var ci := m.explore.find(cage)
	ExploreNode.add(m, "relic", Vector2(15, 7.9) * TILE, {"cage": ci, "no_zone": true})
	ExploreNode.add(m, "terminal", Vector2(20, 6.2) * TILE, {"actions": ["lasers", "power", "data"], "cage": ci, "seed": 77})
	return m
