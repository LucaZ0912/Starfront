extends RefCounted
## Package 59, part 3 (Luz): the office of the naturalisation, the last scene of the intro – a room of its own in the
## colours of the power that takes you in.
## - Assembly: "Registry Office 14-C" – blue and white, bright; the counter under the screens, waiting chairs, and a
##   passage straight through the middle of the room where people keep walking by (the story moves them).
## - Covenant: "Chancery of the Return" – crimson and gold, darker; lancets and banners, a raised desk on steps, a
##   runner up to it, braziers, and soldiers at their posts along the walls and at the door.
## No class_name: preload it.

const T := GroundMap.T
const TILE := GroundMap.TILE
const MuseumGen = preload("res://scripts/ground/museum_gen.gd")
const W := 32
const H := 22
const PASS_Y := 13                       # the Assembly's passage: its top row (three rows)


## Where everyone stands (tiles): the official behind the desk, you and Imre before it.
static func spots(faction: String) -> Dictionary:
	if faction == "covenant":
		return {"official": Vector2(W * 0.5, 7.5), "you": Vector2(W * 0.5 + 0.9, 11.6), "imre": Vector2(W * 0.5 - 0.9, 11.6),
			"cam": Vector2(W * 0.5, 10.4)}
	return {"official": Vector2(W * 0.5, 6.5), "you": Vector2(W * 0.5 + 0.9, 9.3), "imre": Vector2(W * 0.5 - 0.9, 9.3),
		"cam": Vector2(W * 0.5, 9.6)}


## The two ends of the Assembly's passage (tiles): the walkers go from one to the other.
static func passage_ends() -> Array:
	return [Vector2(1.2, PASS_Y + 1.5), Vector2(W - 1.2, PASS_Y + 1.5)]


static func build(station: Dictionary, faction: String) -> GroundMap:
	return _covenant(station) if faction == "covenant" else _assembly(station)


static func _assembly(_station: Dictionary) -> GroundMap:
	var BLUE := Color(0.3, 0.58, 1.0)
	var CYAN := Color(0.45, 0.85, 1.0)
	var m := GroundMap.new()
	MuseumGen._pal(m, {})
	m.pal["floor"] = Color(0.86, 0.88, 0.92)
	m.pal["floor2"] = Color(0.74, 0.78, 0.86)
	m.pal["wall"] = Color(0.9, 0.92, 0.95)
	m.pal["frame"] = Color(0.8, 0.84, 0.9)
	m.pal["trim"] = Color(0.5, 0.58, 0.72)
	m.pal["accent"] = BLUE
	m.style = "museum"
	m.title = "Registry Office 14-C"
	m.hull_top = -9999
	m.set_meta("no_guards", true)
	m.setup(W, H)
	m.fill(0, 0, W, H, T.CAP)
	m.fill(1, 2, W - 2, 3, T.FACE)
	m.fill(1, 5, W - 2, H - 7, T.FLOOR, 34)
	# the north wall: a strip of light, banners of light, the Vote's channel on two screens
	m.face_deco.append({"kind": "light_strip", "x": 1, "y": 2, "w": W - 2, "at": 8, "col": CYAN})
	for bn in [3, 6, W - 7, W - 4]:
		m.face_deco.append({"kind": "holo_banner", "x": bn, "y": 2, "w": 1, "col": BLUE})
	for sc in [9, W - 13]:
		m.face_deco.append({"kind": "screen", "x": sc, "y": 3, "w": 4, "col": CYAN})
	MuseumGen._label(m, "REGISTRY OFFICE 14-C", Vector2(W * 0.5, 1.6), Color(0.75, 0.88, 1.0))
	# the counter under the screens, the clerk's things on it; the queue's place marked on the floor
	m.add_object({"kind": "counter", "x": W / 2 - 5, "y": 7, "w": 10, "h": 1})
	m.add_object({"kind": "holo_pillar", "x": W / 2 - 6, "y": 6, "w": 1, "h": 1, "col": CYAN})
	m.add_object({"kind": "holo_pillar", "x": W / 2 + 5, "y": 6, "w": 1, "h": 1, "col": CYAN})
	m.decals.append({"kind": "rug", "x": W / 2 - 3, "y": 8, "w": 6, "h": 3, "col": Color(0.25, 0.4, 0.75)})
	m.lights.append({"pos": Vector2(W * 0.5, 7.0) * TILE, "r": 110.0, "col": Color(0.8, 0.9, 1.0), "a": 0.4})
	# waiting corners left and right: benches, plants, a news wall
	for bx in [2, 6, W - 9, W - 5]:
		m.add_object({"kind": "museum_bench", "x": bx, "y": 9, "w": 3, "h": 1, "face": 0}, false)
	for pl in [Vector2i(1, 5), Vector2i(W - 2, 5), Vector2i(1, H - 4), Vector2i(W - 2, H - 4)]:
		m.add_object({"kind": "plant", "x": pl.x, "y": pl.y, "w": 1, "h": 1})
	m.add_object({"kind": "news_wall", "x": 3, "y": 6, "w": 3, "h": 1})
	m.add_object({"kind": "news_wall", "x": W - 6, "y": 6, "w": 3, "h": 1})
	# the passage through the middle of the room: a runner from wall to wall, open at both ends
	m.fill(0, PASS_Y, W, 3, T.FLOOR, 36)
	m.decals.append({"kind": "rug", "x": 0, "y": PASS_Y, "w": W, "h": 3, "col": Color(0.2, 0.34, 0.66)})
	for gx in [0, W - 1]:
		m.lights.append({"pos": Vector2(gx + 0.5, PASS_Y + 1.5) * TILE, "r": 60.0, "col": CYAN, "a": 0.35})
	# the south half: more benches, the seal in the floor
	m.decals.append({"kind": "senate_seal", "x": W / 2 - 4, "y": PASS_Y + 3, "w": 8, "h": 4})
	for bx2 in [3, W - 6]:
		m.add_object({"kind": "museum_bench", "x": bx2, "y": H - 5, "w": 3, "h": 1, "face": 1}, false)
	m.spawn = Vector2(W * 0.5 + 0.9, 9.3) * TILE
	m.lights.append({"pos": Vector2(W * 0.5, H * 0.5) * TILE, "r": 320.0, "col": Color(0.88, 0.94, 1.0), "a": 0.35})
	DeckGen._seats(m)
	return m


static func _covenant(_station: Dictionary) -> GroundMap:
	var CRED := Color(0.62, 0.12, 0.12)
	var GOLD := Color(0.88, 0.68, 0.3)
	var WALL := 5
	var m := GroundMap.new()
	MuseumGen._pal(m, {})
	m.pal["floor"] = Color(0.6, 0.5, 0.44)
	m.pal["floor2"] = Color(0.5, 0.4, 0.36)
	m.pal["wall"] = Color(0.66, 0.56, 0.5)
	m.pal["trim"] = Color(0.5, 0.4, 0.32)
	m.pal["accent"] = GOLD
	m.style = "museum"
	m.title = "Chancery of the Return"
	m.hull_top = -9999
	m.set_meta("no_guards", true)
	m.setup(W, H)
	m.fill(0, 0, W, H, T.CAP)
	m.fill(1, 1, W - 2, WALL, T.FACE)
	m.fill(1, WALL + 1, W - 2, H - WALL - 3, T.FLOOR, 47)
	# the north wall: lancets, the Covenant's banners, pilasters, the Hierarch's edict
	for lx in [3, 7, W - 9, W - 5]:
		m.face_deco.append({"kind": "cov_lancet", "x": lx, "y": 1, "w": 2, "rows": WALL})
	for bn in [W / 2 - 5, W / 2 + 4]:
		m.face_deco.append({"kind": "cov_banner", "x": bn, "y": 1, "w": 1, "rows": 5})
	for pl in [W / 2 - 3, W / 2 + 2]:
		m.face_deco.append({"kind": "cov_pilaster", "x": pl, "y": 1, "w": 1, "rows": WALL})
	m.face_deco.append({"kind": "edict_scroll", "x": W / 2 - 2, "y": 2, "w": 4})
	MuseumGen._label(m, "CHANCERY OF THE RETURN", Vector2(W * 0.5, 0.6), Color(1.0, 0.85, 0.5))
	# the raised desk on its steps, candelabra either side; the runner up to it
	var dy := WALL + 1
	m.decals.append({"kind": "cov_steps", "x": W / 2 - 6, "y": dy + 2, "w": 12, "h": 2})
	m.add_object({"kind": "counter", "x": W / 2 - 3, "y": dy + 2, "w": 6, "h": 1})
	for cd in [W / 2 - 5, W / 2 + 4]:
		m.add_object({"kind": "candelabrum", "x": cd, "y": dy + 1, "w": 1, "h": 1})
		m.lights.append({"pos": Vector2(cd + 0.5, dy) * TILE, "r": 60.0, "col": Color(1.0, 0.75, 0.4), "a": 0.5, "flicker": true})
	m.decals.append({"kind": "rug", "x": W / 2 - 2, "y": dy + 4, "w": 4, "h": H - dy - 6, "col": CRED.lightened(0.1)})
	m.add_object({"kind": "tithe_chest", "x": W / 2 + 3, "y": dy + 2, "w": 1, "h": 1})
	# columns, braziers, the windows' colours on the floor
	for cl in [Vector2i(6, dy + 5), Vector2i(W - 7, dy + 5), Vector2i(6, H - 6), Vector2i(W - 7, H - 6)]:
		m.add_object({"kind": "column", "x": cl.x, "y": cl.y, "w": 1, "h": 1})
	for bz in [Vector2i(3, dy + 2), Vector2i(W - 4, dy + 2), Vector2i(3, H - 4), Vector2i(W - 4, H - 4)]:
		m.add_object({"kind": "brazier", "x": bz.x, "y": bz.y, "w": 1, "h": 1})
		m.lights.append({"pos": Vector2(bz.x + 0.5, bz.y - 0.8) * TILE, "r": 56.0, "col": Color(1.0, 0.65, 0.35), "a": 0.5, "flicker": true})
	for lp in [[5, 12, Color(0.95, 0.3, 0.2)], [W - 6, 13, Color(0.95, 0.7, 0.3)], [9, 17, Color(0.9, 0.25, 0.25)], [W - 10, 17, Color(0.9, 0.5, 0.2)]]:
		m.lights.append({"pos": Vector2(int(lp[0]), int(lp[1])) * TILE, "r": 44.0, "col": lp[2], "a": 0.25})
	# the soldiers: along both walls, beside the desk, at the door (Luz: many of them, guarding the room)
	var posts: Array = []
	for i in 5:
		var gy := dy + 4.5 + i * 2.4
		posts.append(Vector2(2.2, gy) * TILE)
		posts.append(Vector2(W - 2.2, gy) * TILE)
	posts.append(Vector2(W * 0.5 - 4.6, dy + 4.6) * TILE)
	posts.append(Vector2(W * 0.5 + 4.6, dy + 4.6) * TILE)
	posts.append(Vector2(W * 0.5 - 3.4, H - 3.6) * TILE)
	posts.append(Vector2(W * 0.5 + 3.4, H - 3.6) * TILE)
	m.set_meta("guard_posts", posts)
	m.set_meta("guard_suit", "suit_mil_hierarch")
	m.decals.append({"kind": "museum_exit", "x": W / 2 - 2, "y": H - 2, "w": 4, "h": 1})
	m.spawn = Vector2(W * 0.5 + 0.9, 11.6) * TILE
	m.lights.append({"pos": Vector2(W * 0.5, 9) * TILE, "r": 240.0, "col": Color(1.0, 0.82, 0.55), "a": 0.22})
	return m
