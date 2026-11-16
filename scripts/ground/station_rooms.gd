extends RefCounted
## Package 54c (Luz): the hand-built rooms of the special stations, each a level of its own in the station's lift.
## - The Vote (Landfall): the gallery over the drone shaft (mockup_54c_vote_galerie) – the shaft seen through the
##   window and under a strip of glass floor (VoteShaft draws it), the railing, the voting booths (your vote on the
##   bill, as at the Senate's stand), information, a souvenir stall – a sight.
## No class_name: preload it.

const T := GroundMap.T
const TILE := GroundMap.TILE
const MuseumGen = preload("res://scripts/ground/museum_gen.gd")
const BLUE := Color(0.4, 0.68, 1.0)


static func _zone(m: GroundMap, r: Rect2, kind: String, title: String, col: Color) -> void:
	m.zones.append({"rect": Rect2(r.position * TILE, r.size * TILE), "kind": kind, "id": kind, "title": title, "col": col, "sign": Vector2(-100, -100)})


# ---------------------------------------------------------------- The Vote: the gallery over the drone shaft

const VG_RAIL := 10                 # the railing's row – north of it the shaft
const VG_GLASS := 2                 # rows of glass floor south of the railing

static func build_vote_gallery(station: Dictionary) -> GroundMap:
	var W := 40
	var H := 24
	var m := GroundMap.new()
	MuseumGen._pal(m, {})
	m.pal["floor"] = Color(0.84, 0.86, 0.9)
	m.pal["floor2"] = Color(0.76, 0.79, 0.85)
	m.pal["wall"] = Color(0.86, 0.88, 0.92)
	m.pal["accent"] = BLUE
	m.style = "museum"
	m.title = "The Vote – the gallery"
	m.hull_top = -9999
	m.set_meta("no_guards", true)
	m.setup(W, H)
	m.fill(0, 0, W, H, T.CAP)
	# the shaft: seen through, not walked – VoteShaft draws it in the window, down under the glass floor too
	m.fill(0, 0, W, VG_RAIL, T.GLASS)
	m.window_rect = Rect2(0, 0, W, VG_RAIL + 1 + VG_GLASS)
	m.set_meta("shaft_view", true)
	m.set_meta("open_sky", true)
	m.fill(0, VG_RAIL, W, 1, T.BLOCK, 47)
	m.add_object({"kind": "glass_rail", "x": 0, "y": VG_RAIL, "w": W, "h": 1}, false)
	m.fill(1, VG_RAIL + 1, W - 2, H - VG_RAIL - 3, T.FLOOR, 47)
	m.decals.append({"kind": "glass_floor", "x": 1, "y": VG_RAIL + 1, "w": W - 2, "h": VG_GLASS})
	m.decals.append({"kind": "rug", "x": 1, "y": VG_RAIL + 1 + VG_GLASS, "w": W - 2, "h": 1, "col": BLUE.darkened(0.2)})
	# the voting booths: three cabins of frosted glass – your vote on the bill (as at the Senate's stand)
	var by := VG_RAIL + VG_GLASS + 3
	for bk in 3:
		var bx := 11 + bk * 7
		m.add_object({"kind": "vote_booth", "x": bx, "y": by, "w": 3, "h": 1})
		_zone(m, Rect2(bx - 0.5, by + 1, 4, 1.4), "senate_stand", "A voting booth – your vote on the bill", Color(0.4, 1.0, 0.6))
		m.lights.append({"pos": Vector2(bx + 1.5, by) * TILE, "r": 40.0, "col": BLUE, "a": 0.35})
	# a sight: the viewpoint along the railing, information, a souvenir stall; benches facing the shaft
	m.zones.append({"rect": Rect2(Vector2(3, VG_RAIL + 1) * TILE, Vector2(W - 6, 1.4) * TILE), "kind": "viewpoint", "id": "viewpoint",
		"title": "The shaft – take a photo", "col": Color(1.0, 0.9, 0.5), "sign": Vector2(-100, -100)})
	m.add_object({"kind": "holo_pillar", "x": 4, "y": by, "w": 1, "h": 1, "col": BLUE})
	_zone(m, Rect2(3, by + 1, 3, 1.4), "sight_info", "Information – The Vote", BLUE)
	m.add_object({"kind": "stall", "x": W - 6, "y": by, "w": 2, "h": 1, "col": BLUE})
	m.zones.append({"rect": Rect2(Vector2(W - 7, by + 0.6) * TILE, Vector2(4, 1.6) * TILE), "kind": "souvenir", "id": "souvenir",
		"title": "Souvenir stall", "col": BLUE, "sign": Vector2(W - 5, by - 1.2) * TILE})
	for bb in [Vector2i(3, by + 4), Vector2i(W - 7, by + 4), Vector2i(15, by + 5), Vector2i(22, by + 5)]:
		m.add_object({"kind": "museum_bench", "x": bb.x, "y": bb.y, "w": 3, "h": 1, "face": 1}, false)
	m.set_meta("sight", {"theme": "vote", "event": "", "name": "The Vote", "id": String(station.get("id", "")) + "_gallery",
		"focus": Vector2(W * 0.5, 4.0) * TILE})
	# the lifts back: an opening in the south, the Senate's guard in blue
	m.decals.append({"kind": "museum_exit", "x": W / 2 - 2, "y": H - 2, "w": 4, "h": 1})
	m.zones.append({"rect": Rect2(Vector2(W / 2 - 2, H - 3) * TILE, Vector2(4, 1.2) * TILE), "kind": "lift", "id": "lift",
		"title": "Lifts", "col": Color(0.4, 1.0, 0.6), "sign": Vector2(-100, -100)})
	m.spawn = Vector2(W * 0.5, H - 4.0) * TILE
	m.set_meta("guard_suit", "suit_mil_senate_eyes")
	m.set_meta("guard_posts", [Vector2(9.0, by + 1.6) * TILE, Vector2(W - 9.0, by + 1.6) * TILE])
	m.set_meta("tourists", 6)
	for lp in range(4, W - 2, 8):
		m.lights.append({"pos": Vector2(lp, H - 5) * TILE, "r": 80.0, "col": Color(0.95, 0.97, 1.0), "a": 0.25})
	DeckGen._seats(m)
	for wp in [Vector2(6, 13), Vector2(20, 13), Vector2(34, 13), Vector2(10, 19), Vector2(30, 19), Vector2(20, 20)]:
		if m.free_at(wp * TILE, 6.0):
			m.wander.append(wp * TILE)
	return m
