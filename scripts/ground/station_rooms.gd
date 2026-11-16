extends RefCounted
## Package 54c (Luz): the hand-built rooms of the special stations, each a level of its own in the station's lift.
## - The Vote (Landfall): the gallery over the drone shaft (mockup_54c_vote_galerie) – the shaft seen through the
##   window and under a strip of glass floor (VoteShaft draws it), the railing, the voting booths (your vote on the
##   bill, as at the Senate's stand), information, a souvenir stall – a sight.
## - The Cathedral of Return (Heimkehr): the nave (mockup_54c_kathedrale) – the great window with the Pilgrim Gate
##   (GateWindow draws it), the altar, pews, the Curia's chancery and the relic shrine on foot, the guard in gold – a sight.
## - The Meridian Sphere (Durchbruch): the control room of the Dyson sphere (mockup_54c_leitwarte) – the star and the
##   shell through the filter glass (SphereWindow), tiers of consoles, the sphere's holo, the Research Exchange on foot.
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


# ---------------------------------------------------------------- the Cathedral of Return: the nave

const NV_WALL := 9                  # the north wall's rows (1 … 9), the great window in it

static func build_nave(station: Dictionary) -> GroundMap:
	var W := 40
	var H := 32
	var CRED := Color(0.62, 0.12, 0.12)
	var GOLD := Color(0.88, 0.68, 0.3)
	var WARM := Color(1.0, 0.85, 0.6)
	var m := GroundMap.new()
	MuseumGen._pal(m, {})
	m.pal["floor"] = Color(0.84, 0.78, 0.68)
	m.pal["floor2"] = Color(0.74, 0.68, 0.58)
	m.pal["wall"] = Color(0.86, 0.8, 0.7)
	m.pal["trim"] = Color(0.62, 0.55, 0.45)
	m.pal["accent"] = GOLD
	m.style = "museum"
	m.title = "Cathedral of Return"
	m.hull_top = -9999
	m.set_meta("no_guards", true)
	m.setup(W, H)
	m.fill(0, 0, W, H, T.CAP)
	m.fill(1, 1, W - 2, NV_WALL, T.FACE)
	m.fill(1, NV_WALL + 1, W - 2, H - NV_WALL - 3, T.FLOOR, 47)
	# the north wall: the great pointed window onto space – the Pilgrim Gate in it (GateWindow draws it) – lancets, banners
	var wx := W / 2 - 8
	m.face_deco.append({"kind": "nave_window", "x": wx, "y": 1, "w": 16, "rows": NV_WALL - 1})
	m.window_rect = Rect2(wx, 1, 16, NV_WALL - 1)
	m.set_meta("gate_view", true)
	for lx in [3, 7, W - 9, W - 5]:
		m.face_deco.append({"kind": "cov_lancet", "x": lx, "y": 1, "w": 2, "rows": NV_WALL})
	for bn in [wx - 3, wx + 18]:
		m.face_deco.append({"kind": "cov_banner", "x": bn, "y": 1, "w": 1, "rows": 6})
	for pl in [wx - 1, wx + 16]:
		m.face_deco.append({"kind": "cov_pilaster", "x": pl, "y": 1, "w": 1, "rows": NV_WALL})
	m.lights.append({"pos": Vector2(W * 0.5, 5) * TILE, "r": 180.0, "col": Color(1.0, 0.85, 0.55), "a": 0.4})
	# the altar on its steps before the window, candles, candelabra
	var ay := NV_WALL + 1
	m.decals.append({"kind": "cov_steps", "x": W / 2 - 8, "y": ay + 1, "w": 16, "h": 2})
	m.add_object({"kind": "altar_cov", "x": W / 2 - 3, "y": ay, "w": 6, "h": 1})
	for cd in [W / 2 - 6, W / 2 + 5]:
		m.add_object({"kind": "candelabrum", "x": cd, "y": ay, "w": 1, "h": 1})
		m.lights.append({"pos": Vector2(cd + 0.5, ay - 1.0) * TILE, "r": 60.0, "col": Color(1.0, 0.75, 0.4), "a": 0.5, "flicker": true})
	# the nave: the runner, pews either side with the faithful, columns
	m.decals.append({"kind": "rug", "x": W / 2 - 2, "y": ay + 3, "w": 4, "h": H - ay - 5, "col": CRED.lightened(0.15)})
	for row in 5:
		for px in [W / 2 - 9, W / 2 + 3]:
			m.add_object({"kind": "museum_bench", "x": px, "y": ay + 5 + row * 3, "w": 6, "h": 1, "face": 1}, false)
	for cl in [Vector2i(9, ay + 4), Vector2i(W - 10, ay + 4), Vector2i(9, ay + 12), Vector2i(W - 10, ay + 12)]:
		m.add_object({"kind": "column", "x": cl.x, "y": cl.y, "w": 1, "h": 1})
	# the Curia's chancery in the west aisle, the relic shrine in the east
	m.face_deco.append({"kind": "edict_scroll", "x": 1, "y": 6, "w": 5})
	m.add_object({"kind": "counter", "x": 1, "y": ay + 3, "w": 6, "h": 1})
	for ck in 2:
		m.people.append({"pos": Vector2(2.5 + ck * 2.5, ay + 2.4) * TILE, "dir": 0, "role": "keeper"})
	m.add_object({"kind": "tithe_chest", "x": 7, "y": ay + 3, "w": 1, "h": 1})
	m.zones.append({"rect": Rect2(Vector2(1, ay + 4) * TILE, Vector2(7, 1.6) * TILE), "kind": "curia_chancery", "id": "curia_chancery",
		"title": "The Curia's chancery – tithe, petition, indulgence", "col": GOLD, "sign": Vector2(-100, -100)})
	m.add_object({"kind": "reliquary", "x": W - 7, "y": ay, "w": 5, "h": 1})
	m.add_object({"kind": "candle_rack", "x": W - 7, "y": ay + 3, "w": 5, "h": 1})
	m.people.append({"pos": Vector2(W - 4.5, ay + 1.6) * TILE, "dir": 0, "role": "keeper"})
	m.zones.append({"rect": Rect2(Vector2(W - 8, ay + 1.4) * TILE, Vector2(7, 1.4) * TILE), "kind": "relic_office", "id": "relic_office",
		"title": "The relic shrine – relics of Earth, a blessing", "col": GOLD, "sign": Vector2(-100, -100)})
	m.lights.append({"pos": Vector2(W - 4.5, ay + 1) * TILE, "r": 80.0, "col": Color(1.0, 0.85, 0.5), "a": 0.55, "flicker": true})
	m.lights.append({"pos": Vector2(4, ay + 3) * TILE, "r": 70.0, "col": Color(1.0, 0.9, 0.6), "a": 0.4})
	# a sight: the viewpoint before the altar (the gate in the window), information, a souvenir stall
	m.zones.append({"rect": Rect2(Vector2(W / 2 - 6, ay + 3) * TILE, Vector2(12, 1.4) * TILE), "kind": "viewpoint", "id": "viewpoint",
		"title": "The Pilgrim Gate – take a photo", "col": Color(1.0, 0.9, 0.5), "sign": Vector2(-100, -100)})
	m.add_object({"kind": "lectern", "x": 3, "y": H - 6, "w": 1, "h": 1})
	m.zones.append({"rect": Rect2(Vector2(2, H - 5) * TILE, Vector2(3, 1.4) * TILE), "kind": "sight_info", "id": "sight_info",
		"title": "Information – the Cathedral of Return", "col": GOLD, "sign": Vector2(-100, -100)})
	m.add_object({"kind": "stall", "x": W - 5, "y": H - 6, "w": 2, "h": 1, "col": CRED})
	m.zones.append({"rect": Rect2(Vector2(W - 6, H - 5.4) * TILE, Vector2(4, 1.6) * TILE), "kind": "souvenir", "id": "souvenir",
		"title": "Souvenir stall", "col": Color(1.0, 0.7, 0.35), "sign": Vector2(W - 4, H - 7.2) * TILE})
	m.set_meta("sight", {"theme": "nave", "event": "", "name": "The Cathedral of Return", "id": String(station.get("id", "")) + "_nave",
		"focus": Vector2(W * 0.5, 4.0) * TILE})
	# the windows' colours on the floor, censers
	for lp in [[6, 20, Color(0.95, 0.3, 0.2)], [W - 7, 22, Color(0.95, 0.7, 0.3)], [12, 27, Color(0.9, 0.5, 0.2)], [W - 12, 26, Color(0.9, 0.25, 0.25)]]:
		m.lights.append({"pos": Vector2(int(lp[0]), int(lp[1])) * TILE, "r": 46.0, "col": lp[2], "a": 0.28})
	for cz in [Vector2i(6, H - 9), Vector2i(W - 7, H - 9)]:
		m.add_object({"kind": "brazier", "x": cz.x, "y": cz.y, "w": 1, "h": 1})
		m.lights.append({"pos": Vector2(cz.x + 0.5, cz.y - 0.8) * TILE, "r": 50.0, "col": Color(1.0, 0.7, 0.4), "a": 0.4, "flicker": true})
	# the lifts back: an opening in the south; the Hierarch's guard in gold
	m.decals.append({"kind": "museum_exit", "x": W / 2 - 2, "y": H - 2, "w": 4, "h": 1})
	m.zones.append({"rect": Rect2(Vector2(W / 2 - 2, H - 3) * TILE, Vector2(4, 1.2) * TILE), "kind": "lift", "id": "lift",
		"title": "Lifts", "col": Color(0.4, 1.0, 0.6), "sign": Vector2(-100, -100)})
	m.spawn = Vector2(W * 0.5, H - 4.0) * TILE
	m.set_meta("guard_suit", "suit_mil_hierarch")
	m.set_meta("guard_posts", [Vector2(W * 0.5 - 7.0, ay + 1.6) * TILE, Vector2(W * 0.5 + 7.0, ay + 1.6) * TILE,
		Vector2(8.5, H - 6) * TILE, Vector2(W - 8.5, H - 6) * TILE])
	m.set_meta("tourists", 10)
	m.lights.append({"pos": Vector2(W * 0.5, 20) * TILE, "r": 260.0, "col": WARM, "a": 0.22})
	DeckGen._seats(m)
	for wp in [Vector2(5, 15), Vector2(34, 15), Vector2(5, 24), Vector2(34, 24), Vector2(20, 27), Vector2(9, 28)]:
		if m.free_at(wp * TILE, 6.0):
			m.wander.append(wp * TILE)
	return m


# ---------------------------------------------------------------- the Meridian Sphere: the control room

const CR_WIN := 9                   # the window's rows (0 … 8); the room below

static func build_control(station: Dictionary) -> GroundMap:
	var W := 44
	var H := 28
	var GREEN := Color(0.4, 1.0, 0.6)
	var m := GroundMap.new()
	MuseumGen._pal(m, {})
	m.pal["floor"] = Color(0.86, 0.88, 0.87)
	m.pal["floor2"] = Color(0.78, 0.8, 0.8)
	m.pal["wall"] = Color(0.88, 0.9, 0.9)
	m.pal["frame"] = Color(0.88, 0.9, 0.9)
	m.pal["accent"] = GREEN
	m.style = "museum"
	m.title = "Meridian Sphere"
	m.hull_top = -9999
	m.set_meta("no_guards", true)
	m.setup(W, H)
	m.fill(0, 0, W, H, T.CAP)
	# the window front: the star through the filter glass, the shell, the construction ships (SphereWindow draws them)
	m.fill(0, 0, W, CR_WIN, T.GLASS)
	m.window_rect = Rect2(0, 0, W, CR_WIN)
	m.set_meta("sphere_view", true)
	m.fill(0, CR_WIN, W, 1, T.BLOCK, 47)
	m.decals.append({"kind": "light_band", "x": 0, "y": CR_WIN, "w": W, "h": 1, "col": GREEN})
	m.fill(1, CR_WIN + 1, W - 2, H - CR_WIN - 3, T.FLOOR, 47)
	# three tiers of consoles facing the window, technicians at them
	for tier in 3:
		var ty := CR_WIN + 3 + tier * 4
		var w := 30 - tier * 4
		var x0 := W / 2 - w / 2
		m.add_object({"kind": "console_row", "x": x0, "y": ty, "w": w, "h": 1})
		for cs in range(x0 + 2, x0 + w - 1, 4):
			if (cs + tier) % 3 != 0:
				m.add_object({"kind": "stool", "x": cs, "y": ty + 1, "w": 1, "h": 1}, false)
				m.people.append({"pos": Vector2(cs + 0.5, ty + 1.45) * TILE, "dir": 1, "role": "keeper", "sit": true})
		m.lights.append({"pos": Vector2(W * 0.5, ty) * TILE, "r": 120.0, "col": GREEN, "a": 0.15})
	# the sphere's holo in the middle below the tiers
	m.add_object({"kind": "sphere_holo", "x": W / 2 - 1, "y": H - 5, "w": 2, "h": 1}, false)
	m.fill(W / 2 - 1, H - 5, 2, 1, T.BLOCK, 47)
	m.lights.append({"pos": Vector2(W * 0.5, H - 7) * TILE, "r": 70.0, "col": GREEN, "a": 0.45})
	# the Research Exchange's counter in the west: data, exotic matter
	m.add_object({"kind": "counter", "x": 2, "y": H - 9, "w": 6, "h": 1})
	m.add_object({"kind": "holo_pillar", "x": 1, "y": H - 10, "w": 1, "h": 1, "col": GREEN})
	m.people.append({"pos": Vector2(5.0, H - 9.6) * TILE, "dir": 0, "role": "keeper"})
	_zone(m, Rect2(2, H - 8, 6, 1.6), "exchange_desk", "The Research Exchange – data and exotic matter", GREEN)
	# a sight: the viewpoint along the window, information, a souvenir stall; benches
	m.zones.append({"rect": Rect2(Vector2(2, CR_WIN + 1) * TILE, Vector2(W - 4, 1.4) * TILE), "kind": "viewpoint", "id": "viewpoint",
		"title": "The star and the shell – take a photo", "col": Color(1.0, 0.9, 0.5), "sign": Vector2(-100, -100)})
	m.add_object({"kind": "holo_pillar", "x": W - 3, "y": H - 10, "w": 1, "h": 1, "col": GREEN})
	_zone(m, Rect2(W - 4, H - 9, 3, 1.4), "sight_info", "Information – the Meridian Sphere", GREEN)
	m.add_object({"kind": "stall", "x": W - 7, "y": H - 5, "w": 2, "h": 1, "col": GREEN})
	m.zones.append({"rect": Rect2(Vector2(W - 8, H - 4.4) * TILE, Vector2(4, 1.6) * TILE), "kind": "souvenir", "id": "souvenir",
		"title": "Souvenir stall", "col": GREEN, "sign": Vector2(W - 6, H - 6.2) * TILE})
	for bb in [Vector2i(3, CR_WIN + 2), Vector2i(W - 6, CR_WIN + 2)]:
		m.add_object({"kind": "museum_bench", "x": bb.x, "y": bb.y, "w": 3, "h": 1, "face": 1}, false)
	m.set_meta("sight", {"theme": "sphere", "event": "", "name": "The Meridian Sphere", "id": String(station.get("id", "")) + "_control",
		"focus": Vector2(W * 0.5, 3.0) * TILE})
	# the lifts back
	m.decals.append({"kind": "museum_exit", "x": W / 2 - 2, "y": H - 2, "w": 4, "h": 1})
	m.zones.append({"rect": Rect2(Vector2(W / 2 - 2, H - 3) * TILE, Vector2(4, 1.2) * TILE), "kind": "lift", "id": "lift",
		"title": "Lifts", "col": GREEN, "sign": Vector2(-100, -100)})
	m.spawn = Vector2(W * 0.5, H - 3.6) * TILE
	m.set_meta("tourists", 4)
	m.lights.append({"pos": Vector2(W * 0.5, 0) * TILE, "r": 300.0, "col": Color(0.85, 0.92, 1.0), "a": 0.4})
	DeckGen._seats(m)
	for wp in [Vector2(6, 12), Vector2(38, 12), Vector2(5, 22), Vector2(39, 22), Vector2(14, 24), Vector2(30, 24)]:
		if m.free_at(wp * TILE, 6.0):
			m.wander.append(wp * TILE)
	return m
