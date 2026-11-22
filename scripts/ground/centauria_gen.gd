extends RefCounted
## Package 61a (Luz): Centauria, the city of the home system – its trains.
## From the hangar the lift goes only to Centauria Central: stairs down onto an island platform, Line A on one side,
## Line B on the other. Real trains on rails, running by a timetable whether you are there or not; over each track a
## board with the seconds to the next train, or to its departure while it stands. Each line shuttles between Central
## and its district (more districts can be added: a line is an entry of LINES, a stop an entry of STOPS).
## You ride in the car, free to walk, the city's panorama passing in the windows: on Line A the casino towers, on
## Line B the stadium; at night a lot of colour, now and then fireworks and laser shows.
## No class_name: preload it.

const T := GroundMap.T
const TILE := GroundMap.TILE
const MuseumGen = preload("res://scripts/ground/museum_gen.gd")

const STOPS := ["Centauria Central", "Commercial District", "Colosseum"]
const HALT := 15.0                # how long a train stands at a stop
const TUNNEL := 3.5               # a ride begins and ends in a tunnel this long (s)
const ROLL := 3.0                 # the seconds a train takes to pull out of a station, or into it
const DOOR_TIME := 1.1            # the seconds the doors take to slide open, or shut
## A line: its name, its district (a stop), its colour, when in its round it stands at Central, how long its two rides
## take (out, back: a little different, as on a real line), its view, which side of the platform its track lies on.
const LINES := {
	"A": {"name": "LINE A", "to": 1, "col": Color(1.0, 0.36, 0.66), "offset": 0.0, "rides": [22.0, 24.0], "view": "casino", "side": "n"},
	"B": {"name": "LINE B", "to": 2, "col": Color(0.96, 0.94, 0.86), "offset": 38.0, "rides": [25.0, 21.0], "view": "stadium", "side": "s"},
}

const SW := 46                     # a station's size (tiles)
const SH := 20
const TRK_N := 4                   # the north track's rows (3)
const PLAT := 7                    # the platform's rows (7)
const TRK_S := 14                  # the south track's rows (3)
const CW := 34                     # the car inside
const C_X := 3
const C_WIN := 2                   # the windows' rows (3)
const C_FLOOR := 5                 # the floor's rows (4)


## A line's whole round (s): halt, ride out, halt, ride back.
static func period(line: String) -> float:
	var r: Array = LINES[line]["rides"]
	return HALT * 2.0 + float(r[0]) + float(r[1])


## Where a line's train is: {"at": stop (-1 while it runs), "from", "to", "k": 0 … 1 of the run, "ride": how long this
## run takes, "left": seconds until it leaves (standing) or arrives (running)}.
static func state(line: String, t: float) -> Dictionary:
	var ln: Dictionary = LINES[line]
	var dst := int(ln["to"])
	var r0 := float(ln["rides"][0])
	var r1 := float(ln["rides"][1])
	var u := fposmod(t - float(ln["offset"]), period(line))
	if u < HALT:
		return {"at": 0, "from": 0, "to": dst, "k": 0.0, "ride": r0, "left": HALT - u}
	if u < HALT + r0:
		return {"at": -1, "from": 0, "to": dst, "k": (u - HALT) / r0, "ride": r0, "left": HALT + r0 - u}
	if u < HALT * 2.0 + r0:
		return {"at": dst, "from": dst, "to": 0, "k": 0.0, "ride": r1, "left": HALT * 2.0 + r0 - u}
	return {"at": -1, "from": dst, "to": 0, "k": (u - HALT * 2.0 - r0) / r1, "ride": r1, "left": period(line) - u}


## Seconds until the line's train next stands at a stop (0 while it stands there).
static func next_at(line: String, stop: int, t: float) -> float:
	var st := state(line, t)
	var r: Array = LINES[line]["rides"]
	if int(st["at"]) == stop:
		return 0.0
	if int(st["at"]) < 0:
		if int(st["to"]) == stop:
			return float(st["left"])
		return float(st["left"]) + HALT + float(r[1] if int(st["to"]) != 0 else r[0])      # on to the far end, a halt, the ride back
	return float(st["left"]) + float(st["ride"])


## How far a train's doors stand open at a stop (0 shut … 1 open): they slide open when it has stopped and shut
## just before it leaves.
static func doors(line: String, stop: int, t: float) -> float:
	var st := state(line, t)
	if int(st["at"]) != stop:
		return 0.0
	return clampf(minf(HALT - float(st["left"]), float(st["left"])) / DOOR_TIME, 0.0, 1.0)


## The lines that call at a stop.
static func lines_at(stop: int) -> Array:
	return LINES.keys().filter(func(k): return stop == 0 or int(LINES[k]["to"]) == stop)


## What a board over a track says.
static func board_text(line: String, stop: int, t: float) -> String:
	var ln: Dictionary = LINES[line]
	var dest: String = STOPS[int(ln["to"])] if stop == 0 else STOPS[0]
	var st := state(line, t)
	if int(st["at"]) == stop:
		return "%s · %s · departs in %d s" % [ln["name"], dest, int(ceil(float(st["left"])))]
	return "%s · %s · next train %d s" % [ln["name"], dest, int(ceil(next_at(line, stop, t)))]


static func _zone(m: GroundMap, r: Rect2, kind: String, title: String, col: Color, extra: Dictionary = {}) -> void:
	var z := {"rect": Rect2(r.position * TILE, r.size * TILE), "kind": kind, "id": kind, "title": title, "col": col, "sign": Vector2(-100, -100)}
	z.merge(extra, true)
	m.zones.append(z)


## A station: the island platform, a track either side (only the tracks of the lines that call here; a wall instead
## of the other). Central: colourful, the stairs up to the hangar's lift. Commercial District: loud, the way up to
## the district. Colosseum: white shining marble, columns, the Colosseum's banners, its way up still shut.
static func build_station(_station: Dictionary, stop: int, came_by: String = "") -> GroundMap:
	var m := GroundMap.new()
	MuseumGen._pal(m, {})
	var marble := stop == 2
	var accent: Color = Color(0.3, 0.9, 1.0) if stop == 0 else (LINES["A"]["col"] if stop == 1 else Color(1.0, 0.82, 0.35))
	m.pal["floor"] = Color(0.93, 0.93, 0.95) if marble else (Color(0.5, 0.46, 0.6) if stop == 1 else Color(0.42, 0.46, 0.56))
	m.pal["floor2"] = Color(0.84, 0.84, 0.88) if marble else (Color(0.42, 0.38, 0.52) if stop == 1 else Color(0.36, 0.4, 0.5))
	m.pal["wall"] = Color(0.95, 0.95, 0.97) if marble else (Color(0.36, 0.3, 0.46) if stop == 1 else Color(0.3, 0.34, 0.44))
	m.pal["frame"] = m.pal["wall"]
	m.pal["trim"] = Color(0.8, 0.7, 0.4) if marble else Color(0.2, 0.22, 0.3)
	m.pal["accent"] = accent
	m.style = "museum"
	m.title = "Centauria"
	m.hull_top = -9999
	m.set_meta("no_guards", true)
	m.setup(SW, SH)
	m.fill(0, 0, SW, SH, T.CAP)
	m.fill(1, 1, SW - 2, 3, T.FACE)
	m.fill(1, PLAT, SW - 2, 7, T.FLOOR, 47 if marble else 34)
	var here: Array = lines_at(stop)
	var tracks: Array = []
	for lk in here:
		var north := String(LINES[lk]["side"]) == "n"
		var ty := TRK_N if north else TRK_S
		m.fill(0, ty, SW, 3, T.BLOCK, 0)
		tracks.append({"line": lk, "y": ty * TILE, "h": 3 * TILE, "dir": 1.0 if north else -1.0})
		# the edge of the platform: a yellow line, the place to board
		m.decals.append({"kind": "guide", "x": 1, "y": PLAT if north else PLAT + 6, "w": SW - 2, "h": 1, "col": Color(1.0, 0.82, 0.25)})
		var by := PLAT - 0.2 if north else PLAT + 5.6
		_zone(m, Rect2(SW * 0.5 - 9.0, by, 18.0, 1.6), "ctr_board", "Board %s to %s" % [String(LINES[lk]["name"]).capitalize(), STOPS[int(LINES[lk]["to"])] if stop == 0 else STOPS[0]],
			LINES[lk]["col"], {"line": lk, "id": "ctr_board_" + String(lk)})
	if not here.any(func(k): return String(LINES[k]["side"]) == "n"):
		m.fill(1, TRK_N, SW - 2, 3, T.FACE)                          # no north track here: the hall's wall
	m.set_meta("ctr_tracks", tracks)
	m.set_meta("ctr_stop", stop)
	# the north wall: light, banners, screens
	m.face_deco.append({"kind": "light_strip", "x": 1, "y": 1, "w": SW - 2, "at": 8, "col": accent})
	if marble:
		for cx in [6, 14, SW - 15, SW - 7]:
			m.add_object({"kind": "column", "x": cx, "y": PLAT + 1, "w": 1, "h": 1})
			m.add_object({"kind": "column", "x": cx, "y": PLAT + 5, "w": 1, "h": 1})
		for bx in [10, 18, SW - 19, SW - 11]:
			m.add_object({"kind": "banner", "x": bx, "y": PLAT + 3, "w": 1, "h": 1, "col": Color(0.85, 0.2, 0.22)})
		m.decals.append({"kind": "rug", "x": SW / 2 - 4, "y": PLAT + 4, "w": 8, "h": 2, "col": Color(0.7, 0.14, 0.18)})
		m.lights.append({"pos": Vector2(SW * 0.5, PLAT + 3.5) * TILE, "r": 320.0, "col": Color(1.0, 0.96, 0.85), "a": 0.4})
	else:
		var cols := [Color(1.0, 0.36, 0.66), Color(0.3, 0.9, 1.0), Color(1.0, 0.82, 0.25), Color(0.55, 1.0, 0.6), Color(0.72, 0.5, 1.0)]
		var k := 0
		for bx in range(4, SW - 4, 5):
			if String(LINES["A"]["side"]) == "n" and here.has("A"):
				break                                                   # (the north wall lies behind the track: the train covers it)
			m.face_deco.append({"kind": "holo_banner", "x": bx, "y": 1, "w": 1, "col": cols[k % cols.size()]})
			k += 1
		for ox in [5, 12, SW - 13, SW - 6]:
			m.add_object({"kind": "holo_pillar", "x": ox, "y": PLAT + 3, "w": 1, "h": 1, "col": cols[(ox + stop) % cols.size()]})
			m.lights.append({"pos": Vector2(ox + 0.5, PLAT + 3.0) * TILE, "r": 60.0, "col": cols[(ox + stop) % cols.size()], "a": 0.4})
		for bx2 in [8, SW - 11]:
			m.add_object({"kind": "museum_bench", "x": bx2, "y": PLAT + 3, "w": 3, "h": 1, "face": 0}, false)
		m.lights.append({"pos": Vector2(SW * 0.5, PLAT + 3.5) * TILE, "r": 300.0, "col": Color(0.9, 0.9, 1.0), "a": 0.3})
	# the way up, in the middle of the platform
	# (Luz: a real flight of stairs) – a stairwell: its roof at the back, a wall either side, the steps rising north
	# inside; you go in from the south only
	var sx := SW / 2 - 2
	m.fill(sx - 1, PLAT + 1, 6, 1, T.CAP)
	m.fill(sx - 1, PLAT + 2, 1, 2, T.FACE)
	m.fill(sx + 4, PLAT + 2, 1, 2, T.FACE)
	m.fill(sx, PLAT + 2, 4, 2, T.FLOOR, 36)
	m.fill(sx + 1, PLAT + 2, 2, 2, T.FLOOR, 37)
	m.lights.append({"pos": Vector2(sx + 2.0, PLAT + 2.6) * TILE, "r": 46.0, "col": accent, "a": 0.4})
	if stop == 0:
		_zone(m, Rect2(sx, PLAT + 2.0, 4.0, 2.2), "ctr_up", "Stairs up: the lift to the hangar", Color(0.4, 1.0, 0.6))
		MuseumGen._label(m, "CENTAURIA CENTRAL", Vector2(SW * 0.5, PLAT + 0.6), Color(0.75, 0.95, 1.0))
	elif stop == 1:
		_zone(m, Rect2(sx, PLAT + 2.0, 4.0, 2.2), "ctr_exit", "Stairs up: the Commercial District", Color(1.0, 0.6, 0.8))
		MuseumGen._label(m, "COMMERCIAL DISTRICT", Vector2(SW * 0.5, PLAT + 0.6), Color(1.0, 0.75, 0.88))
	else:
		_zone(m, Rect2(sx, PLAT + 2.0, 4.0, 2.2), "ctr_exit", "Stairs up: the Colosseum", Color(1.0, 0.85, 0.4),
			{"closed": "The Colosseum opens soon."})
		MuseumGen._label(m, "COLOSSEUM", Vector2(SW * 0.5, PLAT + 0.6), Color(1.0, 0.86, 0.45))
	m.spawn = Vector2(SW * 0.5, PLAT + 5.2) * TILE
	var side := String(LINES[came_by]["side"]) if LINES.has(came_by) and here.has(came_by) else String(LINES[here[0]]["side"])
	m.set_meta("rail_front", Vector2(SW * 0.5 + 5.5, PLAT + (0.9 if side == "n" else 6.0)) * TILE)
	m.set_meta("tourists", 7)
	DeckGen._seats(m)
	for wp in [Vector2(5, PLAT + 1.5), Vector2(SW - 5, PLAT + 1.5), Vector2(9, PLAT + 5.4), Vector2(SW - 9, PLAT + 5.4), Vector2(16, PLAT + 3.5), Vector2(SW - 16, PLAT + 3.5)]:
		if m.free_at(wp * TILE, 6.0):
			m.wander.append(wp * TILE)
	return m


# ---------------------------------------------------------------- the Commercial District

const PW := 160                    # the district's size (tiles)
const PH := 70                    # (six rows more in the south: the roofs of the tall buildings there, RoofFx)
const P_TOP := 30                  # its first row: north of it the casino's towers and the city (drawn by PlazaSky)
const P_CX := 55                   # the central plaza: its west edge …
const P_CW := 50                   # … and its width


## Lays a part of another map into this one (Luz: the Museum and its plaza from Curie): the columns sx0 … sx1 - 1 and
## the rows sy0 … of `src`, its west edge at ox, its row sy0 at oy; `mirror` turns it left to right.
static func _stamp(m: GroundMap, src: GroundMap, sx0: int, sx1: int, sy0: int, ox: int, oy: int, mirror: bool) -> void:
	var sw := sx1 - sx0
	for y in range(sy0, src.h):
		for x in range(sx0, sx1):
			var dx := ox + (sw - 1 - (x - sx0) if mirror else x - sx0)
			var dy := oy + y - sy0
			if dx < 0 or dy < 0 or dx >= m.w or dy >= m.h:
				continue
			m.tiles[dy * m.w + dx] = src.tiles[y * src.w + x]
			m.floor_kind[dy * m.w + dx] = src.floor_kind[y * src.w + x]
	var mv := func(v: Vector2) -> Vector2:              # a point (tiles)
		return Vector2(ox + (sx1 - v.x if mirror else v.x - sx0), oy + v.y - sy0)
	for list_name in ["objects", "decals", "face_deco"]:
		for o in src.get(list_name):
			var w := int(o.get("w", 1))
			var x := int(o["x"])
			var y := int(o["y"])
			if x < sx0 or x + w > sx1 or y < sy0:
				continue
			var c: Dictionary = (o as Dictionary).duplicate(true)
			c["x"] = ox + (sx1 - x - w if mirror else x - sx0)
			c["y"] = oy + y - sy0
			(m.get(list_name) as Array).append(c)
	for z in src.zones:
		var r: Rect2 = z["rect"]
		var sg: Vector2 = z.get("sign", Vector2(-100, -100))
		var label := r.size == Vector2.ZERO
		var px := (sg.x if label else r.get_center().x) / TILE
		var py := (sg.y if label else r.position.y) / TILE
		if px < sx0 or px >= sx1 or py < sy0 or String(z.get("kind", "")) in ["seat", "lift"]:
			continue
		var c2: Dictionary = (z as Dictionary).duplicate(true)
		if not label:
			var p0 := mv.call(r.position / TILE) as Vector2
			if mirror:
				p0.x -= r.size.x / TILE
			c2["rect"] = Rect2(p0 * TILE, r.size)
		if sg.x >= 0.0:
			c2["sign"] = (mv.call(sg / TILE) as Vector2) * TILE
		m.zones.append(c2)
	for l in src.lights:
		var lp: Vector2 = (l["pos"] as Vector2) / TILE
		if lp.x >= sx0 and lp.x < sx1 and lp.y >= sy0:
			var c3: Dictionary = (l as Dictionary).duplicate(true)
			c3["pos"] = (mv.call(lp) as Vector2) * TILE
			m.lights.append(c3)
	for wp in src.wander:
		var wt: Vector2 = (wp as Vector2) / TILE
		if wt.x >= sx0 and wt.x < sx1 and wt.y >= sy0:
			m.wander.append((mv.call(wt) as Vector2) * TILE)


## A filler building on the north side of a side plaza (Luz: so the scene is not empty): its roof, three rows of
## front in its colour, banners of light, lit windows.
static func _prop(m: GroundMap, x0: int, w: int, y0: int, cap: int, col: Color) -> void:
	m.fill(x0, y0, w, cap, T.CAP)
	m.fill(x0, y0 + cap, w, 3, T.FACE)
	m.face_deco.append({"kind": "light_strip", "x": x0, "y": y0 + cap, "w": w, "at": 8, "col": col})
	var k := 0
	for bx in range(x0 + 1, x0 + w - 1, 3):
		m.face_deco.append({"kind": "holo_banner" if k % 2 == 0 else "screen", "x": bx, "y": y0 + cap + (0 if k % 2 == 0 else 1), "w": 1 if k % 2 == 0 else 2,
			"col": col if k % 4 < 2 else col.lightened(0.4)})
		k += 1
	m.lights.append({"pos": Vector2(x0 + w * 0.5, y0 + cap + 3.5) * TILE, "r": 110.0, "col": col, "a": 0.35})


## The Commercial District (Luz's sketch): one wide map. In the middle the central plaza, the way up from the
## station in its middle, neon everywhere (a fountain, holo statues, pillars of light, stalls); north of it the
## casino's round glass towers and the city behind them (PlazaSky draws them, they shift as you walk). West the
## Museum with its plaza, as it stood on Curie; east the Commercial Hall with a plaza of its own; filler buildings
## between; in the south the way to the back alleys (a gate, shut for now).
static func build_plaza(station: Dictionary) -> GroundMap:
	var W := PW
	var H := PH
	var m := GroundMap.new()
	MuseumGen._pal(m, {})
	m.pal["floor"] = Color(0.36, 0.36, 0.48)
	m.pal["floor2"] = Color(0.28, 0.28, 0.4)
	m.pal["wall"] = Color(0.3, 0.28, 0.44)
	m.pal["frame"] = Color(0.3, 0.28, 0.44)
	m.pal["accent"] = Color(1.0, 0.36, 0.66)
	m.style = "plaza"
	m.title = "Centauria"
	m.hull_top = -9999
	m.set_meta("few_guards", true)
	m.setup(W, H)
	var PINK := Color(1.0, 0.36, 0.66)
	var CYAN := Color(0.3, 0.9, 1.0)
	var PURPLE := Color(0.72, 0.36, 1.0)
	var ORANGE := Color(1.0, 0.6, 0.25)
	var GOLD := Color(1.0, 0.82, 0.35)
	var GREEN := Color(0.35, 1.0, 0.55)
	var cols := [PINK, CYAN, GOLD, GREEN, PURPLE, ORANGE]
	# north of the district: open (the towers and the city show there)
	m.window_rect = Rect2(0, 0, W, P_TOP)
	m.set_meta("open_sky", true)
	m.fill(0, P_TOP, W, H - P_TOP, T.BLOCK, 30)
	var cx0 := P_CX
	var cx1 := P_CX + P_CW
	# ---- the central plaza
	m.fill(cx0, P_TOP, P_CW, 28, T.FLOOR, 30)
	m.decals.append({"kind": "steps_lit", "x": cx0 + 13, "y": P_TOP, "w": 24, "h": 2})         # the stair up into the casino's middle tower
	var mid := cx0 + P_CW / 2
	_zone(m, Rect2(mid - 2, P_TOP, 4, 1.6), "ctr_casino_in", "The Grand Centauria: into the casino", PURPLE, {"id": "ctr_casino"})      # package 62: open
	m.set_meta("from_casino", Vector2(mid, P_TOP + 2.2) * TILE)
	# (Luz: no pillars before it, the ends of the stair done properly) the casino stands on a podium: beside the stair
	# a terrace with a balustrade of glass, its front lit; the stair's cheek walls end it either side
	for tw in [[cx0, 13], [cx0 + 37, P_CW - 37]]:
		m.fill(int(tw[0]), P_TOP, int(tw[1]), 2, T.BLOCK, 30)
		m.decals.append({"kind": "terrace_lit", "x": int(tw[0]), "y": P_TOP, "w": int(tw[1]), "h": 2})
	for lx in [cx0 + 3, cx0 + 9, cx0 + 13, cx0 + 37, cx0 + 41, cx0 + 47]:
		m.lights.append({"pos": Vector2(lx, P_TOP + 2.2) * TILE, "r": 34.0, "col": PURPLE, "a": 0.4})
	# the way up from the station, in the middle of the plaza: a stairwell, its lamp green
	var kx := mid - 2
	var ky := P_TOP + 12
	m.fill(kx - 1, ky, 6, 1, T.BLOCK, 30)                  # (Luz) drawn by MetroFx: the wall with the board, two low walls, the lit steps
	m.fill(kx - 1, ky + 1, 1, 2, T.BLOCK, 30)
	m.fill(kx + 4, ky + 1, 1, 2, T.BLOCK, 30)
	m.fill(kx, ky + 1, 4, 2, T.FLOOR, 30)
	m.set_meta("ctr_metro", Vector2(kx - 1, ky) * TILE)
	_zone(m, Rect2(kx, ky + 1.0, 4.0, 2.2), "ctr_down", "Stairs down: the station, Line A to Centauria Central", GREEN)
	m.lights.append({"pos": Vector2(kx + 2.0, ky + 2.4) * TILE, "r": 50.0, "col": PINK, "a": 0.22})
	m.lights.append({"pos": Vector2(kx + 2.0, ky - 0.6) * TILE, "r": 50.0, "col": CYAN, "a": 0.3})
	m.set_meta("from_station", Vector2(kx + 2.0, ky + 4.2) * TILE)
	m.spawn = m.get_meta("from_station")
	# neon: two fountains, holo statues, pillars of light in every colour, lamps, a few bright stalls, benches, palms
	for fx in [cx0 + 10, cx1 - 14]:
		m.add_object({"kind": "fountain", "x": fx, "y": P_TOP + 9, "w": 4, "h": 2})
		m.fill(fx, P_TOP + 9, 4, 2, T.BLOCK)
		m.lights.append({"pos": Vector2(fx + 2, P_TOP + 9.5) * TILE, "r": 100.0, "col": CYAN, "a": 0.5})
	var si := 0
	for st in [Vector2i(cx0 + 5, P_TOP + 5), Vector2i(cx1 - 7, P_TOP + 5), Vector2i(cx0 + 5, P_TOP + 20), Vector2i(cx1 - 7, P_TOP + 20), Vector2i(mid - 9, P_TOP + 6),
			Vector2i(mid + 7, P_TOP + 6)]:
		m.add_object({"kind": "holo_statue", "x": st.x, "y": st.y, "w": 2, "h": 1, "seed": 611 + si * 7, "species": ["suit_civil", "suit_survey", "suit_mil_light"][si % 3]})
		m.lights.append({"pos": Vector2(st.x + 1.0, st.y) * TILE, "r": 44.0, "col": cols[si % cols.size()], "a": 0.5})
		si += 1
	var pi := 0
	for hp in [Vector2i(cx0 + 2, P_TOP + 3), Vector2i(cx1 - 3, P_TOP + 3), Vector2i(cx0 + 2, P_TOP + 14), Vector2i(cx1 - 3, P_TOP + 14), Vector2i(cx0 + 2, P_TOP + 25),
			Vector2i(cx1 - 3, P_TOP + 25), Vector2i(mid - 7, P_TOP + 17), Vector2i(mid + 6, P_TOP + 17), Vector2i(mid - 13, P_TOP + 24), Vector2i(mid + 12, P_TOP + 24),
			Vector2i(mid - 16, P_TOP + 3), Vector2i(mid + 15, P_TOP + 3)]:
		m.add_object({"kind": "holo_pillar", "x": hp.x, "y": hp.y, "w": 1, "h": 1, "col": cols[pi % cols.size()]})
		m.lights.append({"pos": Vector2(hp.x + 0.5, hp.y) * TILE, "r": 70.0, "col": cols[pi % cols.size()], "a": 0.5})
		pi += 1
	var rng := RandomNumberGenerator.new()
	rng.seed = 6112
	var n := 0
	for srow in [Vector2i(cx0 + 6, P_TOP + 15), Vector2i(cx1 - 20, P_TOP + 15)]:
		for k in 4:
			var sx: int = srow.x + k * 4
			m.add_object({"kind": "stall", "x": sx, "y": srow.y, "w": 2, "h": 1, "col": cols[n % cols.size()]})
			m.people.append({"pos": Vector2(sx + 1.0, srow.y - 0.2) * TILE, "dir": 0, "role": "keeper"})
			m.lights.append({"pos": Vector2(sx + 1.0, srow.y + 0.6) * TILE, "r": 34.0, "col": cols[n % cols.size()], "a": 0.5})
			n += 1
	for bn in [Vector2i(mid - 12, P_TOP + 11), Vector2i(mid + 9, P_TOP + 11), Vector2i(mid - 6, P_TOP + 21), Vector2i(mid + 4, P_TOP + 21)]:
		m.add_object({"kind": "bench", "x": bn.x, "y": bn.y, "w": 3, "h": 1, "face": 0}, false)
	for pp in [Vector2i(cx0 + 8, P_TOP + 23), Vector2i(cx1 - 11, P_TOP + 23), Vector2i(cx0 + 18, P_TOP + 6), Vector2i(cx1 - 21, P_TOP + 6)]:
		m.add_object({"kind": "planter", "x": pp.x, "y": pp.y, "w": 3, "h": 1, "col": Color(0.4, 0.36, 0.52)})
		m.add_object({"kind": "palm", "x": pp.x, "y": pp.y - 1, "w": 3, "h": 1, "rise": 56, "seed": pp.x % 8}, false)
	# the way south to the back alleys: a short street, a gate across it (Luz: their own map later)
	m.fill(mid - 3, P_TOP + 28, 6, 5, T.FLOOR, 30)
	m.zones.append({"rect": Rect2(Vector2(mid - 3, P_TOP + 30.2) * TILE, Vector2(6.0, 1.8) * TILE), "kind": "museum_go", "id": "ctr_alleys", "to": "zalley", "at": "from_plaza",
		"title": "Through the gate: the Back Alleys", "col": GREEN, "sign": Vector2(-100, -100)})        # package 61b: the gate is open
	m.set_meta("from_alleys", Vector2(mid, P_TOP + 29.4) * TILE)
	m.lights.append({"pos": Vector2(mid, P_TOP + 30.5) * TILE, "r": 60.0, "col": GREEN, "a": 0.5, "flicker": true})
	# ---- west: the Museum and its plaza, as they stood on Curie (mirrored: the Museum at the far west)
	var cur: GroundMap = MuseumGen.build_plaza(station, {})
	var KX := 10                                      # (Curie's lift kiosk ends here: left out)
	var sw := cur.w - KX                              # 52
	var wx0 := cx0 - sw                               # the stamp's west edge
	_stamp(m, cur, KX, cur.w, 9, wx0, P_TOP + 9, true)             # the plaza's rows (from its railing down)
	_stamp(m, cur, cur.w - 24, cur.w, 0, wx0, P_TOP, true)         # the Museum itself, with its roof
	var dfront: Vector2 = (cur.get_meta("door_front") as Vector2) / TILE
	m.set_meta("from_museum", Vector2(wx0 + (cur.w - dfront.x), P_TOP + dfront.y) * TILE)
	m.objects = m.objects.filter(func(o): return String(o.get("kind", "")) != "glass_rail")
	m.fill(wx0 + 24, P_TOP + 9, sw - 24, 1, T.FLOOR, 30)             # (where Curie's railing stood)
	_prop(m, wx0 + 25, sw - 26, P_TOP, 6, CYAN)                     # a filler building north of the Museum's plaza
	var facades: Array = [{"x": (wx0 + 25.0) * TILE, "w": (sw - 26.0) * TILE, "base": (P_TOP + 9.0) * TILE, "h": 470.0, "col": CYAN, "seed": 61, "kind": "prop"}]
	# ---- east: the Commercial Hall and its plaza
	var ex0 := cx1
	var ex1 := W - 1
	m.fill(ex0, P_TOP + 9, ex1 - ex0, 19, T.FLOOR, 30)
	_prop(m, ex0 + 1, 26, P_TOP, 6, PINK)                           # a filler building
	facades.append({"x": (ex0 + 1.0) * TILE, "w": 26.0 * TILE, "base": (P_TOP + 9.0) * TILE, "h": 470.0, "col": PINK, "seed": 97, "kind": "prop"})
	var hx := ex1 - 24                                # the Hall: its roof, its front, the doors
	m.fill(hx, P_TOP, 24, 14, T.CAP)
	m.fill(hx, P_TOP + 14, 24, 3, T.FACE)
	m.face_deco.append({"kind": "light_strip", "x": hx, "y": P_TOP + 14, "w": 24, "at": 8, "col": ORANGE})
	var hdx := hx + 10
	m.face_deco.append({"kind": "museum_gate", "x": hdx, "y": P_TOP + 14, "w": 4})
	for bx in [hx + 2, hx + 6, hx + 16, hx + 20]:
		m.face_deco.append({"kind": "holo_banner", "x": bx, "y": P_TOP + 14, "w": 1, "col": ORANGE if bx % 4 == 0 else GOLD})
	MuseumGen._label(m, "COMMERCIAL HALL", Vector2(hdx + 2, P_TOP + 13.6), Color(1.0, 0.85, 0.6))
	m.decals.append({"kind": "steps_lit", "x": hx, "y": P_TOP + 17, "w": 24, "h": 2})
	m.zones.append({"rect": Rect2(Vector2(hdx, P_TOP + 17) * TILE, Vector2(4, 1.6) * TILE), "kind": "museum_go", "id": "ctr_hall", "to": "street", "at": "from_plaza",
		"title": "Into the Commercial Hall: the city's shops", "col": ORANGE, "sign": Vector2(-100, -100)})
	m.set_meta("from_hall", Vector2(hdx + 2, P_TOP + 19.6) * TILE)
	facades.append({"x": float(hx) * TILE, "w": 24.0 * TILE, "base": (P_TOP + 17.0) * TILE, "h": 336.0, "col": ORANGE, "seed": 5, "kind": "hall"})
	m.set_meta("ctr_facades", facades)                              # (Luz: far more detail – their fronts are drawn, FacadeFx)
	m.zones = m.zones.filter(func(zl): return String(zl.get("title", "")) != "COMMERCIAL HALL")
	# (Luz) a viewing scope on the central plaza: the whole of the towers
	m.add_object({"kind": "scope", "x": mid + 9, "y": P_TOP + 22, "w": 1, "h": 1, "col": GOLD})
	_zone(m, Rect2(mid + 8.6, P_TOP + 21.0, 1.8, 2.4), "ctr_scope", "The viewing scope: the towers of the Grand Centauria", GOLD)
	m.lights.append({"pos": Vector2(mid + 9.5, P_TOP + 22.0) * TILE, "r": 30.0, "col": GOLD, "a": 0.5})
	m.lights.append({"pos": Vector2(hdx + 2, P_TOP + 18) * TILE, "r": 90.0, "col": ORANGE, "a": 0.55})
	# the Hall's plaza: a café under parasols, a market row, lamps, palms
	for ti in 6:
		var tx := ex0 + 5 + (ti % 3) * 6
		var ty := P_TOP + 14 + (ti / 3) * 4
		m.add_object({"kind": "round_table", "x": tx + 1, "y": ty, "w": 1, "h": 1})
		m.add_object({"kind": "parasol", "x": tx, "y": ty, "w": 3, "h": 1, "col": cols[ti % cols.size()]}, false)
		DeckGen._seat(m, "chair", tx, ty, 3, cols[ti % cols.size()].darkened(0.3), rng, 0.6)
		DeckGen._seat(m, "chair", tx + 2, ty, 2, cols[ti % cols.size()].darkened(0.3), rng, 0.6)
	for k2 in 5:
		var sx2: int = ex0 + 4 + k2 * 4
		m.add_object({"kind": "stall", "x": sx2, "y": P_TOP + 23, "w": 2, "h": 1, "col": cols[(k2 + 2) % cols.size()]})
		m.people.append({"pos": Vector2(sx2 + 1.0, P_TOP + 22.8) * TILE, "dir": 0, "role": "keeper"})
		m.lights.append({"pos": Vector2(sx2 + 1.0, P_TOP + 23.6) * TILE, "r": 34.0, "col": cols[(k2 + 2) % cols.size()], "a": 0.5})
	var li := 0
	for lp in [Vector2i(ex0 + 3, P_TOP + 11), Vector2i(ex0 + 22, P_TOP + 11), Vector2i(ex0 + 3, P_TOP + 26), Vector2i(ex0 + 26, P_TOP + 26), Vector2i(hx - 2, P_TOP + 20),
			Vector2i(ex1 - 3, P_TOP + 24)]:
		m.add_object({"kind": "lamp_post", "x": lp.x, "y": lp.y, "w": 1, "h": 1, "col": cols[li % cols.size()]})
		m.lights.append({"pos": Vector2(lp.x + 0.5, lp.y) * TILE, "r": 70.0, "col": cols[li % cols.size()], "a": 0.45})
		li += 1
	for pp2 in [Vector2i(hx + 2, P_TOP + 22), Vector2i(hx + 18, P_TOP + 22)]:
		m.add_object({"kind": "planter", "x": pp2.x, "y": pp2.y, "w": 3, "h": 1, "col": Color(0.4, 0.36, 0.52)})
		m.add_object({"kind": "palm", "x": pp2.x, "y": pp2.y - 1, "w": 3, "h": 1, "rise": 56, "seed": pp2.x % 8}, false)
	# neon round the Museum's plaza too (Luz: the neon stays around it)
	var ni := 0
	for np in [Vector2i(wx0 + 27, P_TOP + 11), Vector2i(wx0 + 48, P_TOP + 11), Vector2i(wx0 + 27, P_TOP + 26), Vector2i(wx0 + 48, P_TOP + 26)]:
		m.add_object({"kind": "holo_pillar", "x": np.x, "y": np.y, "w": 1, "h": 1, "col": cols[(ni + 1) % cols.size()]})
		m.lights.append({"pos": Vector2(np.x + 0.5, np.y) * TILE, "r": 70.0, "col": cols[(ni + 1) % cols.size()], "a": 0.45})
		ni += 1
	m.set_meta("tourists", 34)
	DeckGen._seats(m)
	for gx in range(wx0 + 28, ex1 - 2, 7):
		for gy in [P_TOP + 12, P_TOP + 19, P_TOP + 26]:
			var wp2 := Vector2(gx, gy)
			if m.free_at(wp2 * TILE, 6.0):
				m.wander.append(wp2 * TILE)
	for gx2 in range(cx0 + 3, cx1 - 2, 6):
		if m.free_at(Vector2(gx2, P_TOP + 4) * TILE, 6.0):
			m.wander.append(Vector2(gx2, P_TOP + 4) * TILE)
	return m


## The sky over Centauria: day or night, stars, Lapis with its rings (its middle at lx, ly; its radius lr).
static func draw_sky(ci: CanvasItem, r: Rect2, night: float, lx: float, ly: float, lr: float, t: float = 0.0, moons: bool = false) -> void:
	var sky_top := Color(0.2, 0.42, 0.8).lerp(Color(0.02, 0.02, 0.08), night)
	var sky_low := Color(0.7, 0.82, 0.96).lerp(Color(0.16, 0.07, 0.28), night)
	for i in 12:
		ci.draw_rect(Rect2(r.position.x, r.position.y + r.size.y * i / 12.0, r.size.x, r.size.y / 12.0 + 1.0), sky_top.lerp(sky_low, i / 11.0))
	if night > 0.5:
		for st in 160:
			var sx := r.position.x + fposmod(sin(st * 12.9898) * 43758.5453, 1.0) * r.size.x
			var sy := r.position.y + fposmod(sin(st * 78.233) * 43758.5453, 1.0) * r.size.y * 0.8
			ci.draw_rect(Rect2(sx, sy, 2.0, 2.0), Color(1, 1, 1, 0.3 + 0.5 * fposmod(sin(st * 3.7) * 99.0, 1.0)))
	draw_lapis(ci, Vector2(lx, ly), lr, night, t, moons)


## Lapis in the sky of Centauria (Luz: large, rich in detail): a deep blue ice giant, banded along its turning, streaks
## and storms drifting in the bands, a great dark spot, a soft night side, a haze of light round its limb; grand
## rings in many bands with a dark division, the giant's shadow lying across them behind it and theirs in a thin
## line across it. With `moons` its two other moons stand faint beside it: Ember (lava) and Glacia (ice).
static func draw_lapis(ci: CanvasItem, c: Vector2, r: float, night: float, t: float, moons: bool) -> void:
	var tilt := -0.35
	var flat := 0.3
	var light := 0.25                                 # the night side lies this way (rad)
	_lapis_rings(ci, c, r, tilt, flat, night, true)
	# the body: bands, duller towards the caps
	ci.draw_set_transform(c, tilt, Vector2.ONE)
	ci.draw_circle(Vector2.ZERO, r, Color(0.07, 0.14, 0.46))
	var nb := 36
	for b in nb:
		var y0 := -0.994 + 1.988 * b / nb
		var y1 := -0.994 + 1.988 * (b + 1) / nb
		var lat := absf((y0 + y1) * 0.5)
		var col := Color(0.06, 0.15, 0.55).lerp(Color(0.14, 0.34, 0.84), TowerArt.hsh(b, 71))
		if b % 5 == 2:
			col = col.lerp(Color(0.32, 0.64, 0.96), 0.5)          # pale belts
		if b % 7 == 4:
			col = col.lerp(Color(0.03, 0.07, 0.32), 0.65)         # dark belts
		if b % 11 == 6:
			col = col.lerp(Color(0.2, 0.7, 0.8), 0.35)            # a breath of teal
		col = col.lerp(Color(0.08, 0.16, 0.42), lat * lat * 0.7)
		var a0 := asin(y0)
		var a1 := asin(y1)
		var pts := PackedVector2Array()
		for k in 5:
			var a := lerpf(a0, a1, k / 4.0)
			pts.append(Vector2(cos(a), sin(a)) * r)
		for k2 in 5:
			var a2 := lerpf(a1, a0, k2 / 4.0)
			pts.append(Vector2(-cos(a2), sin(a2)) * r)
		ci.draw_colored_polygon(pts, col)
	# streaks in the bands
	for s in 34:
		var sy := TowerArt.hsh(s, 75) * 1.8 - 0.9
		var hw := sqrt(1.0 - sy * sy)
		var x0 := -hw + TowerArt.hsh(s, 76) * hw * 1.2
		var x1 := minf(hw, x0 + (0.3 + TowerArt.hsh(s, 77) * 0.9) * hw)
		ci.draw_line(Vector2(x0, sy) * r * 0.985, Vector2(x1, sy) * r * 0.985,
			Color(0.7, 0.88, 1.0, 0.16) if s % 3 != 0 else Color(0.02, 0.05, 0.25, 0.3), maxf(1.0, r * (0.004 + 0.008 * TowerArt.hsh(s, 78))))
	# storms drifting with its turning (flatter towards the limb); the first one the great dark spot
	for st in 7:
		var oy := TowerArt.hsh(st, 81) * 1.3 - 0.65
		var ow := sqrt(1.0 - oy * oy)
		var ox := fposmod(TowerArt.hsh(st, 82) + t * 0.003 * (0.5 + TowerArt.hsh(st, 83)), 1.0) * 2.0 - 1.0
		var fore := sqrt(maxf(0.0, 1.0 - ox * ox))
		var big := 2.4 if st == 0 else 1.0
		var rx := r * (0.03 + 0.05 * TowerArt.hsh(st, 84)) * fore * big
		var ry := r * (0.016 + 0.018 * TowerArt.hsh(st, 85)) * big
		if rx < r * 0.012:
			continue
		var oc := Vector2(ox * ow * 0.9, oy) * r
		if st == 0:
			_oval(ci, oc, rx * 1.2, ry * 1.3, Color(0.5, 0.78, 1.0, 0.4))
			_oval(ci, oc, rx, ry, Color(0.02, 0.05, 0.26, 0.85))
			_oval(ci, oc + Vector2(-rx * 0.2, -ry * 0.2), rx * 0.45, ry * 0.4, Color(0.1, 0.22, 0.6, 0.6))
		else:
			_oval(ci, oc, rx * 1.3, ry * 1.4, Color(0.04, 0.1, 0.38, 0.45))
			_oval(ci, oc, rx, ry, Color(0.62, 0.84, 1.0, 0.6))
			_oval(ci, oc, rx * 0.5, ry * 0.45, Color(0.9, 0.97, 1.0, 0.55))
	# the rings' shadow across it: a thin lens under where they cross
	var lens := PackedVector2Array()
	for k3 in 17:
		var la := lerpf(0.03, PI - 0.03, k3 / 16.0)
		lens.append(Vector2(cos(la), sin(la) * 0.74) * r * 0.995)
	for k4 in 17:
		var lb := lerpf(PI - 0.03, 0.03, k4 / 16.0)
		lens.append(Vector2(cos(lb), sin(lb) * 0.86) * r * 0.995)
	ci.draw_colored_polygon(lens, Color(0.0, 0.01, 0.06, 0.42))
	# its night side, soft; the lit limb; the haze round it
	_lapis_shade(ci, c, r, light, [0.74, 0.64, 0.54, 0.44, 0.34, 0.24, 0.14, 0.04, -0.06, -0.16, -0.26, -0.36], 0.11)
	ci.draw_set_transform(c, light, Vector2.ONE)
	ci.draw_arc(Vector2.ZERO, r * 0.975, PI * 0.5, PI * 1.5, 56, Color(0.45, 0.7, 1.0, 0.26), r * 0.05)
	ci.draw_arc(Vector2.ZERO, r * 1.012, 0.0, TAU, 80, Color(0.3, 0.55, 1.0, 0.2), r * 0.024)
	ci.draw_arc(Vector2.ZERO, r * 1.035, PI * 0.45, PI * 1.55, 56, Color(0.3, 0.55, 1.0, 0.1), r * 0.03)
	if night < 0.5:
		ci.draw_circle(Vector2.ZERO, r, Color(0.5, 0.66, 0.92, 0.3 * (1.0 - night)))         # the day's air over it
	_lapis_rings(ci, c, r, tilt, flat, night, false)
	if moons:
		# Ember, the lava moon: dark, glowing seams, a breath of fire round it
		var ep := c + Vector2(-2.45, 0.62) * r
		var er := r * 0.075
		ci.draw_set_transform(ep, 0.0, Vector2.ONE)
		ci.draw_circle(Vector2.ZERO, er * 1.6, Color(1.0, 0.4, 0.1, 0.07))
		ci.draw_circle(Vector2.ZERO, er, Color(0.22, 0.09, 0.07))
		for v in 11:
			var vp := Vector2(TowerArt.hsh(v, 91) * 2.0 - 1.0, TowerArt.hsh(v, 92) * 2.0 - 1.0) * er * 0.6
			var vd := Vector2.from_angle(TowerArt.hsh(v, 93) * TAU) * er * (0.2 + 0.3 * TowerArt.hsh(v, 94))
			ci.draw_line(vp, vp + vd, Color(1.0, 0.5, 0.14, 0.9), maxf(1.0, er * 0.08))
			ci.draw_circle(vp, maxf(1.0, er * 0.07), Color(1.0, 0.8, 0.35))
		_lapis_shade(ci, ep, er, light, [0.5, 0.15, -0.2], 0.3)
		# Glacia, the ice moon: pale, fine cracks
		var gp := c + Vector2(1.15, -1.2) * r
		var gr := r * 0.055
		ci.draw_set_transform(gp, 0.0, Vector2.ONE)
		ci.draw_circle(Vector2.ZERO, gr * 1.5, Color(0.7, 0.9, 1.0, 0.06))
		ci.draw_circle(Vector2.ZERO, gr, Color(0.8, 0.89, 0.97))
		for g in 8:
			var cp := Vector2(TowerArt.hsh(g, 95) * 2.0 - 1.0, TowerArt.hsh(g, 96) * 2.0 - 1.0) * gr * 0.6
			var cd := Vector2.from_angle(TowerArt.hsh(g, 97) * TAU) * gr * (0.25 + 0.35 * TowerArt.hsh(g, 98))
			ci.draw_line(cp, cp + cd, Color(0.4, 0.6, 0.85, 0.8), maxf(1.0, gr * 0.06))
		_lapis_shade(ci, gp, gr, light, [0.5, 0.15, -0.2], 0.3)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _oval(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in 16:
		pts.append(c + Vector2(cos(k * TAU / 16.0) * rx, sin(k * TAU / 16.0) * ry))
	ci.draw_colored_polygon(pts, col)


## The night side of a ball at c: crescents laid over each other, from its limb in to each of `edges` (the part of the
## radius where the shade ends: 1 the limb, 0 the middle, below 0 past it).
static func _lapis_shade(ci: CanvasItem, c: Vector2, r: float, light: float, edges: Array, alpha: float) -> void:
	ci.draw_set_transform(c, light, Vector2.ONE)
	for e in edges:
		var np := PackedVector2Array()
		for k in 33:
			var a := lerpf(-1.55, 1.55, k / 32.0)
			np.append(Vector2(cos(a), sin(a)) * r)
		for k2 in 33:
			var a2 := lerpf(1.55, -1.55, k2 / 32.0)
			np.append(Vector2(cos(a2) * float(e), sin(a2)) * r)
		ci.draw_colored_polygon(np, Color(0.0, 0.01, 0.07, alpha))


## Lapis' rings (inner edge, outer edge in radii; how dense; how blue): the half behind it (back) or before it. The
## giant's shadow falls across the half behind.
const LAPIS_RINGS := [[1.3, 1.4, 0.22, 0.2], [1.41, 1.58, 0.55, 0.5], [1.59, 1.8, 0.85, 0.9], [1.8, 1.86, 0.6, 0.3], [1.9, 2.08, 0.78, 0.7],
	[2.08, 2.2, 0.55, 0.1], [2.23, 2.3, 0.35, 0.6], [2.36, 2.385, 0.25, 0.4]]

static func _lapis_rings(ci: CanvasItem, c: Vector2, r: float, tilt: float, flat: float, night: float, back: bool) -> void:
	ci.draw_set_transform(c, tilt, Vector2(1.0, flat))
	var psi := PI * 1.5 + 0.5                         # where the shadow lies on them: behind it, out beside its limb
	var vis := lerpf(0.7, 1.0, night)
	for rg in LAPIS_RINGS:
		var mid := (float(rg[0]) + float(rg[1])) * 0.5
		var wd := (float(rg[1]) - float(rg[0])) * r
		var col: Color = Color(0.93, 0.9, 0.82).lerp(Color(0.66, 0.78, 1.0), float(rg[3]))
		var al := float(rg[2]) * vis
		var s1 := psi
		var dark := Color(col.darkened(0.86), al)
		if back:
			var nsub := maxi(1, int(ceil((float(rg[1]) - float(rg[0])) / 0.03)))
			for sb in nsub:
				var m2 := lerpf(float(rg[0]), float(rg[1]), (sb + 0.5) / nsub)
				var w2 := wd / nsub + 0.6
				var d2 := asin(clampf(1.0 / m2, 0.0, 1.0)) * 0.94
				ci.draw_arc(Vector2.ZERO, m2 * r, PI, psi - d2, 40, Color(col, al), w2)
				ci.draw_arc(Vector2.ZERO, m2 * r, psi - d2, psi + d2, 24, dark, w2)
				ci.draw_arc(Vector2.ZERO, m2 * r, psi + d2, TAU, 16, Color(col, al), w2)
			s1 = 0.0
			if wd > r * 0.1:
				ci.draw_arc(Vector2.ZERO, (mid + (float(rg[1]) - float(rg[0])) * 0.18) * r, PI, TAU, 56, Color(0.1, 0.1, 0.16, 0.22), maxf(1.0, wd * 0.07))
				ci.draw_arc(Vector2.ZERO, (mid - (float(rg[1]) - float(rg[0])) * 0.24) * r, PI, TAU, 56, Color(1, 1, 1, 0.14), maxf(1.0, wd * 0.05))
		else:
			var f0 := maxf(0.0, s1 - TAU)
			if f0 > 0.0:
				ci.draw_arc(Vector2.ZERO, mid * r, 0.0, f0, 8, dark, wd)
			ci.draw_arc(Vector2.ZERO, mid * r, f0, PI, 48, Color(col, al), wd)
			if wd > r * 0.1:
				ci.draw_arc(Vector2.ZERO, (mid + (float(rg[1]) - float(rg[0])) * 0.18) * r, 0.0, PI, 56, Color(0.1, 0.1, 0.16, 0.22), maxf(1.0, wd * 0.07))
				ci.draw_arc(Vector2.ZERO, (mid - (float(rg[1]) - float(rg[0])) * 0.24) * r, 0.0, PI, 56, Color(1, 1, 1, 0.14), maxf(1.0, wd * 0.05))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The city's skyline in two layers along the foot of a view w wide and h high: the far one goes with the camera (d)
## more than the near one; no higher than `tall` of the view.
static func draw_skyline(ci: CanvasItem, w: float, h: float, d: float, night: float, tall: float) -> void:
	var neon := [Color(1.0, 0.36, 0.66), Color(0.3, 0.9, 1.0), Color(1.0, 0.82, 0.25), Color(0.55, 1.0, 0.6), Color(0.72, 0.5, 1.0), Color(1.0, 0.55, 0.25)]
	for layer in 2:
		var par: float = [0.6, 0.32][layer]
		var bw: float = [120.0, 170.0][layer]
		var shade: float = [0.3, 0.2][layer]
		var n := int(w / bw) + 12
		for b in n:
			var x: float = (b - 6) * bw + d * par
			if x < -bw or x > w:
				continue
			var bh: float = (0.3 + TowerArt.hsh(b, layer * 7 + 1) * float([0.55, 0.7][layer])) * h * tall
			var tint: Color = neon[int(TowerArt.hsh(b, layer + 11) * neon.size()) % neon.size()]
			var body := Color(shade, shade, shade + 0.08).lerp(tint, 0.2 if night < 0.5 else 0.08)
			if night > 0.5:
				body = body.darkened(0.5)
			ci.draw_rect(Rect2(x, h - bh, bw - 14.0, bh), body)
			var rows := int(bh / 22.0)
			for r2 in rows:
				for c2 in int((bw - 26.0) / 18.0):
					if TowerArt.hsh(b * 31 + r2 * 7 + c2, layer + 40) < (0.5 if night > 0.5 else 0.25):
						ci.draw_rect(Rect2(x + 8.0 + c2 * 18.0, h - bh + 10.0 + r2 * 22.0, 9.0, 12.0), Color(tint if TowerArt.hsh(b + r2, layer + 51) < 0.5 else Color(1.0, 0.92, 0.7), 0.9 if night > 0.5 else 0.45))
			if TowerArt.hsh(b, layer + 60) > 0.5:
				ci.draw_rect(Rect2(x + 6.0, h - bh * 0.6, bw - 26.0, 6.0), Color(tint, 0.9 if night > 0.5 else 0.5))


## The towers of the Grand Centauria (Luz: the highest buildings of the city – far higher than the screen): three
## stepped towers of dark glass, round (shaded to both sides), structural ribs with strips of neon running up them,
## floors of windows lit in clusters, a ledge of light at every setback, bridges between them, crowns and spires with
## beacons; at their foot a podium of arcades and billboards and the great doors under a marquee.
## Drawn in tower units (1 unit = 1 window px down on the plaza), the foot of the middle tower at the origin, up = -y;
## the caller sets the transform. The lit windows are worked out once and kept.
class TowerArt:
	const SPECS := [
		{"x": -1160.0, "col": Color(1.0, 0.36, 0.66), "spire": 520.0, "tiers": [[0.0, 1800.0, 400.0], [1800.0, 3100.0, 330.0], [3100.0, 4100.0, 250.0], [4100.0, 4800.0, 160.0]]},
		{"x": 1160.0, "col": Color(0.3, 0.9, 1.0), "spire": 460.0, "tiers": [[0.0, 1600.0, 400.0], [1600.0, 2900.0, 320.0], [2900.0, 3800.0, 240.0], [3800.0, 4400.0, 150.0]]},
		{"x": 0.0, "col": Color(0.72, 0.42, 1.0), "spire": 900.0, "tiers": [[0.0, 2300.0, 560.0], [2300.0, 3900.0, 460.0], [3900.0, 5300.0, 350.0], [5300.0, 6300.0, 240.0], [6300.0, 7000.0, 140.0]]},
	]
	const TOP := 8100.0             # the tip of the highest spire
	const FLOOR := 30.0
	const COLW := 20.0
	const SIGNS := ["JACKPOT", "ROULETTE", "777", "SHOW TONIGHT", "HIGH ROLLERS", "LUCKY LAPIS"]
	static var _fine := {}          # "night|tower|tier" -> [[x, y, w, h, Color], …]
	static var _coarse := {}

	static func hsh(i: int, salt: int) -> float:
		return fposmod(sin(float(i) * 12.9898 + float(salt) * 78.233) * 43758.5453, 1.0)

	## The lit windows of one tier: single ones (fine) or whole clusters as one patch (coarse, for the far view).
	static func _windows(si: int, ti: int, lit_night: bool, fine: bool) -> Array:
		var key := "%d|%d|%d" % [1 if lit_night else 0, si, ti]
		var store: Dictionary = _fine if fine else _coarse
		if store.has(key):
			return store[key]
		var sp: Dictionary = SPECS[si]
		var tr: Array = sp["tiers"][ti]
		var cx := float(sp["x"])
		var y0 := float(tr[0])
		var y1 := float(tr[1])
		var hw := float(tr[2])
		var col: Color = sp["col"]
		var seed := si * 17 + ti * 5 + 3
		var out: Array = []
		var nf := int((y1 - y0) / FLOOR)
		var ncol := int(hw * 2.0 / COLW)
		var lit_cl := 0.44 if lit_night else 0.16
		if fine:
			for f in nf:
				for c in ncol:
					var cell := (f / 4) * 97 + (c / 3) + seed * 13
					var p := hsh(f * 131 + c, seed + 5)
					if not ((hsh(cell, seed) < lit_cl and p < 0.82) or p < 0.05):
						continue
					var k := hsh(cell, seed + 9)
					var wc: Color = Color(0.86, 0.9, 1.0) if k < 0.5 else (Color(0.8, 0.55, 1.0) if k < 0.8 else col.lightened(0.4))
					var wx := cx - hw + c * COLW + 4.0
					var edge := absf((wx + 6.0 - cx) / hw)
					out.append([wx, -(y0 + f * FLOOR) - 22.0, 12.0 * (1.0 - 0.55 * edge * edge), 15.0, Color(wc, (0.95 if lit_night else 0.5) * (1.0 - 0.5 * edge * edge))])
		else:
			for f2 in range(0, nf / 4 + 1):
				for c2 in range(0, ncol / 3 + 1):
					var cell2 := f2 * 97 + c2 + seed * 13
					if hsh(cell2, seed) >= lit_cl:
						continue
					var k2 := hsh(cell2, seed + 9)
					var wc2: Color = Color(0.86, 0.9, 1.0) if k2 < 0.5 else (Color(0.8, 0.55, 1.0) if k2 < 0.8 else col.lightened(0.4))
					var wx2 := cx - hw + c2 * 3.0 * COLW + 4.0
					var wy2 := -(y0 + f2 * 4.0 * FLOOR) - 4.0 * FLOOR + 10.0
					if wx2 + 50.0 > cx + hw or -wy2 > y1:
						continue
					out.append([wx2, wy2, 3.0 * COLW - 10.0, 4.0 * FLOOR - 20.0, Color(wc2, 0.75 if lit_night else 0.4)])
		store[key] = out
		return out

	static func _tower(ci: CanvasItem, si: int, t: float, night: float, y_lo: float, y_hi: float, fine: bool) -> void:
		var sp: Dictionary = SPECS[si]
		var cx := float(sp["x"])
		var col: Color = sp["col"]
		var tiers: Array = sp["tiers"]
		var lit_night := night > 0.5
		for ti in tiers.size():
			var tr: Array = tiers[ti]
			var y0 := float(tr[0])
			var y1 := float(tr[1])
			var hw := float(tr[2])
			if y0 > y_hi or y1 < y_lo:
				continue
			var top := -y1
			var hgt := y1 - y0
			var glass := Color(0.06, 0.09, 0.2).lerp(col, 0.1) if lit_night else Color(0.2, 0.32, 0.5).lerp(col, 0.14)
			ci.draw_rect(Rect2(cx - hw, top, hw * 2.0, hgt), glass)
			for e in 8:                                     # round: darker to both sides
				var ew := hw * 0.07
				var a := 0.5 * pow(1.0 - e / 8.0, 1.5)
				ci.draw_rect(Rect2(cx - hw + e * ew, top, ew + 1.0, hgt), Color(0.0, 0.0, 0.04, a))
				ci.draw_rect(Rect2(cx + hw - (e + 1) * ew, top, ew + 1.0, hgt), Color(0.0, 0.0, 0.04, a))
			ci.draw_rect(Rect2(cx - hw * 0.32, top, hw * 0.1, hgt), Color(1, 1, 1, 0.07))
			for wn in _windows(si, ti, lit_night, fine):
				var wy := float(wn[1])
				if -wy < y_lo - 40.0 or -wy > y_hi + 140.0:
					continue
				ci.draw_rect(Rect2(float(wn[0]), wy, float(wn[2]), float(wn[3])), wn[4])
			# the ribs, strips of neon up four of them (in lengths, a gap between)
			for r in [-0.8, -0.52, -0.2, 0.2, 0.52, 0.8]:
				ci.draw_rect(Rect2(cx + hw * float(r) - 5.0, top, 10.0, hgt), Color(0.03, 0.04, 0.09))
			var ni := 0
			for r2 in [-0.52, -0.2, 0.2, 0.52]:
				var nx := cx + hw * float(r2)
				var yy := y0 + 60.0
				while yy < y1 - 80.0:
					var se := minf(yy + 340.0, y1 - 60.0)
					if se > y_lo and yy < y_hi:
						var fl := 0.75 + 0.25 * sin(t * 1.3 + ni * 2.1 + yy * 0.01)
						ci.draw_rect(Rect2(nx - 2.5, -se, 5.0, se - yy), Color(col, 0.95 * fl))
						ci.draw_rect(Rect2(nx - 8.0, -se, 16.0, se - yy), Color(col, 0.16 * fl))
					yy += 420.0
				ni += 1
			# the ledge at the setback, a line of light under it
			ci.draw_rect(Rect2(cx - hw - 16.0, top - 4.0, hw * 2.0 + 32.0, 22.0), Color(0.12, 0.13, 0.2))
			ci.draw_rect(Rect2(cx - hw - 16.0, top + 16.0, hw * 2.0 + 32.0, 4.0), Color(col, 0.95))
		# the crown: a glass cap, a mast, a beacon; the middle tower with a ring of light
		var last: Array = tiers[tiers.size() - 1]
		var ty := -float(last[1])
		var thw := float(last[2])
		var spire := float(sp["spire"])
		if -ty < y_hi + spire + 200.0:
			ci.draw_colored_polygon(PackedVector2Array([Vector2(cx - thw, ty), Vector2(cx - thw * 0.3, ty - spire * 0.4), Vector2(cx + thw * 0.3, ty - spire * 0.4), Vector2(cx + thw, ty)]),
				Color(0.08, 0.1, 0.22).lerp(col, 0.2))
			ci.draw_line(Vector2(cx - thw, ty), Vector2(cx - thw * 0.3, ty - spire * 0.4), Color(col, 0.95), 6.0)
			ci.draw_line(Vector2(cx + thw, ty), Vector2(cx + thw * 0.3, ty - spire * 0.4), Color(col, 0.95), 6.0)
			ci.draw_rect(Rect2(cx - 6.0, ty - spire, 12.0, spire * 0.6), Color(0.7, 0.75, 0.9))
			ci.draw_circle(Vector2(cx, ty - spire), 22.0, col if int(t * 1.5 + si) % 2 == 0 else Color(1, 1, 1))
			ci.draw_circle(Vector2(cx, ty - spire), 60.0, Color(col, 0.18))
			if si == 2:
				ci.draw_arc(Vector2(cx, ty - spire * 0.4), thw * 1.3, PI, TAU, 40, Color(1.0, 0.82, 0.35, 0.9), 10.0)

	## The three towers, the bridges between them, the podium and the doors.
	static func draw(ci: CanvasItem, t: float, night: float, y_lo: float, y_hi: float, fine: bool, back: bool = false) -> void:
		var font := ThemeDB.fallback_font
		var gold := Color(1.0, 0.82, 0.35)
		_tower(ci, 0, t, night, y_lo, y_hi, fine)
		_tower(ci, 1, t, night, y_lo, y_hi, fine)
		for by in [950.0, 2500.0]:                          # bridges of glass from the side towers to the middle one
			if by > y_lo - 60.0 and by < y_hi + 60.0:
				for sd in [-1.0, 1.0]:
					var x0: float = sd * 540.0 if by < 2300.0 else sd * 450.0
					var x1: float = sd * 780.0 if by < 1700.0 else sd * 840.0
					var bx := minf(x0, x1)
					ci.draw_rect(Rect2(bx, -by - 40.0, absf(x1 - x0), 40.0), Color(0.1, 0.16, 0.3))
					ci.draw_rect(Rect2(bx, -by - 26.0, absf(x1 - x0), 12.0), Color(1.0, 0.94, 0.75, 0.7 if night > 0.5 else 0.3))
					ci.draw_rect(Rect2(bx, -by - 44.0, absf(x1 - x0), 4.0), Color(gold, 0.9))
		_tower(ci, 2, t, night, y_lo, y_hi, fine)
		if y_lo > 460.0:
			return
		# the podium: an arcade of glass between pillars, a gold rail
		ci.draw_rect(Rect2(-1620.0, -300.0, 3240.0, 300.0), Color(0.07, 0.07, 0.14))
		var ax := -1590.0
		var ai := 0
		while ax < 1590.0:
			if back or absf(ax + 55.0) > 260.0:
				ci.draw_rect(Rect2(ax + 14.0, -128.0, 82.0, 128.0), Color(1.0, 0.86, 0.6, (0.75 if night > 0.5 else 0.4) * (0.7 + 0.3 * hsh(ai, 4))))
				ci.draw_rect(Rect2(ax + 14.0, -128.0, 82.0, 6.0), Color([Color(1.0, 0.36, 0.66), Color(0.3, 0.9, 1.0), gold][ai % 3], 0.95))
				ci.draw_rect(Rect2(ax + 53.0, -122.0, 3.0, 122.0), Color(0.07, 0.07, 0.14))
			ci.draw_rect(Rect2(ax, -300.0, 14.0, 300.0), Color(0.16, 0.17, 0.26))
			ax += 110.0
			ai += 1
		ci.draw_rect(Rect2(-1620.0, -308.0, 3240.0, 9.0), gold)
		if back:
			return                                         # (Luz: seen from behind, for the lifts' ride: no billboards, no doors)
		# billboards along it: colours running, what is on tonight
		var bi := 0
		for bxx in [-1500.0, -1130.0, -760.0, 460.0, 830.0, 1200.0]:
			var hue := fposmod(t * 0.04 + bi * 0.17, 1.0)
			var bc := Color.from_hsv(hue, 0.75, 0.5 if night > 0.5 else 0.42)
			ci.draw_rect(Rect2(float(bxx) - 6.0, -296.0, 312.0, 152.0), Color(0.02, 0.02, 0.05))
			ci.draw_rect(Rect2(float(bxx), -290.0, 300.0, 140.0), bc)
			for sx in 6:
				var ox := fposmod(sx * 60.0 + t * 30.0, 300.0)
				ci.draw_rect(Rect2(float(bxx) + ox, -290.0, 14.0, 140.0), Color(1, 1, 1, 0.07))
			ci.draw_string(font, Vector2(float(bxx), -204.0), SIGNS[(bi + int(t / 5.0)) % SIGNS.size()], HORIZONTAL_ALIGNMENT_CENTER, 300.0, 46, Color(1, 1, 1, 0.96))
			ci.draw_rect(Rect2(float(bxx), -290.0, 300.0, 140.0), Color.from_hsv(hue, 0.5, 1.0), false, 4.0)
			bi += 1
		# the doors: a tall portal full of warm light, a marquee over it with running bulbs
		ci.draw_rect(Rect2(-250.0, -330.0, 500.0, 330.0), Color(0.16, 0.12, 0.08))
		ci.draw_rect(Rect2(-250.0, -330.0, 500.0, 330.0), gold, false, 8.0)
		ci.draw_rect(Rect2(-214.0, -292.0, 428.0, 292.0), Color(1.0, 0.9, 0.68, 0.95))
		for dv in [-107.0, 0.0, 107.0]:
			ci.draw_rect(Rect2(float(dv) - 4.0, -292.0, 8.0, 292.0), Color(0.3, 0.2, 0.12))
		ci.draw_rect(Rect2(-214.0, -180.0, 428.0, 6.0), Color(0.3, 0.2, 0.12))
		ci.draw_rect(Rect2(-380.0, -440.0, 760.0, 100.0), Color(0.05, 0.03, 0.1))
		ci.draw_rect(Rect2(-380.0, -440.0, 760.0, 100.0), Color(0.72, 0.42, 1.0), false, 5.0)
		ci.draw_string(font, Vector2(-380.0, -372.0), "THE GRAND CENTAURIA", HORIZONTAL_ALIGNMENT_CENTER, 760.0, 54, gold)
		var bn := 0
		for bxp in range(-370, 371, 37):
			for byp in [-432.0, -348.0]:
				ci.draw_circle(Vector2(float(bxp), float(byp)), 6.0, Color(1.0, 0.95, 0.7) if (bn + int(t * 6.0)) % 3 == 0 else Color(0.5, 0.35, 0.15))
			bn += 1


## What stands north of the district (window px): the sky with Lapis, the city's skyline in two layers, and right
## behind the plaza the towers of the Grand Centauria – only their feet fit on the screen, they go on far above it.
## Everything shifts a little as you walk (Luz: a parallax): the far things with you, the towers hardly at all.
class PlazaSky extends Node2D:
	const Gen = preload("res://scripts/ground/centauria_gen.gd")
	const LAPIS_X := 1250.0          # Lapis behind the towers: right of the plaza's middle, above the towers' foot, its radius (window px)
	const LAPIS_UP := 835.0
	const LAPIS_R := 900.0
	var size := Vector2.ZERO
	var view = null                  # the GroundView (its camera)
	var night := 0.0
	var _t := 0.0
	var _sparks: Array = []

	func setup(p_size: Vector2, p_view, p_night: float) -> void:
		size = p_size
		view = p_view
		night = p_night

	func _process(dt: float) -> void:
		_t += dt
		if night > 0.5:
			if randf() < dt * 0.7:
				_sparks.append({"x": randf_range(-1700.0, 1700.0), "y": randf_range(0.2, 0.75) * size.y, "t": 0.0,
					"col": [Color(1.0, 0.4, 0.7), Color(0.4, 0.9, 1.0), Color(1.0, 0.85, 0.3), Color(0.6, 1.0, 0.6), Color(0.75, 0.55, 1.0)][randi() % 5]})
			for s in _sparks:
				s["t"] = float(s["t"]) + dt
			_sparks = _sparks.filter(func(s): return float(s["t"]) < 1.6)
		queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var mid := (Gen.P_CX + Gen.P_CW * 0.5) * GroundMap.TILE * GroundMap.SCALE      # the central plaza's middle (window px)
		var cam := mid
		if view != null and is_instance_valid(view) and (view._cam_c as Vector2) != Vector2.INF:
			cam = (view._cam_c as Vector2).x
		var d := cam - mid
		Gen.draw_sky(self, Rect2(0, 0, w, h), night, mid + LAPIS_X + d * 0.92, h - LAPIS_UP, LAPIS_R, _t)       # (Luz: far larger)
		Gen.draw_skyline(self, w, h, d, night, 0.42)
		if night > 0.5:
			for s in _sparks:
				var st2 := float(s["t"])
				var rr := 14.0 + st2 * 90.0
				for q2 in 14:
					var dv := Vector2.from_angle(q2 * TAU / 14.0) * rr
					draw_circle(Vector2(mid + float(s["x"]) + d * 0.5, float(s["y"])) + dv + Vector2(0.0, st2 * st2 * 20.0), 4.0, Color(s["col"], clampf(1.0 - st2 / 1.6, 0.0, 1.0)))
		draw_set_transform(Vector2(mid + d * 0.05, h), 0.0, Vector2.ONE)
		Gen.TowerArt.draw(self, _t, night, 0.0, h + 60.0, true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## (Luz) through the viewing scope on the plaza: the view pulls back until the whole of the towers stands in it – the
## city small at their feet, a layer of cloud round their middle, Lapis behind, traffic in the air, at night lasers
## from their crowns and fireworks. Esc (or a click) puts the scope down.
class TowerScope extends Control:
	const Gen = preload("res://scripts/ground/centauria_gen.gd")
	const PULL := 4.5                # seconds the view takes to pull back
	var night := 0.0
	var _t := 0.0
	var _sparks: Array = []

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP
		clip_contents = true

	func _process(dt: float) -> void:
		_t += dt
		if night > 0.5 and randf() < dt * 1.2:
			_sparks.append({"x": randf_range(-2600.0, 2600.0), "y": randf_range(1200.0, 6500.0), "t": 0.0,
				"col": [Color(1.0, 0.4, 0.7), Color(0.4, 0.9, 1.0), Color(1.0, 0.85, 0.3), Color(0.6, 1.0, 0.6)][randi() % 4]})
		for s in _sparks:
			s["t"] = float(s["t"]) + dt
		_sparks = _sparks.filter(func(s): return float(s["t"]) < 1.8)
		queue_redraw()

	## How far the view has pulled back (0 = as from the plaza, 1 = the whole towers).
	func pulled() -> float:
		return ease(clampf(_t / PULL, 0.0, 1.0), -2.2)

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var k := pulled()
		var s_far := h * 0.9 / Gen.TowerArt.TOP
		var sc := lerpf(1.0, s_far, k)
		var org := Vector2(w * 0.5, lerpf(h * 0.86, h * 0.95, k))
		Gen.draw_sky(self, Rect2(0, 0, w, h), night, lerpf(w * 0.5 + Gen.PlazaSky.LAPIS_X, w * 0.5 + w * 0.21, k),
			lerpf(h * 0.86 - Gen.PlazaSky.LAPIS_UP, h * 0.42, k), lerpf(Gen.PlazaSky.LAPIS_R, h * 0.26, k), _t, true)
		draw_set_transform(org, 0.0, Vector2(sc, sc))
		# the city round them, small against the towers
		for layer in 2:
			var bw: float = [150.0, 210.0][layer]
			var shade: float = [0.24, 0.16][layer]
			for b in range(-40, 40):
				var bx: float = b * bw
				var bh: float = 260.0 + Gen.TowerArt.hsh(b, layer * 7 + 2) * float([900.0, 620.0][layer])
				var tint: Color = [Color(1.0, 0.36, 0.66), Color(0.3, 0.9, 1.0), Color(1.0, 0.82, 0.25), Color(0.55, 1.0, 0.6), Color(0.72, 0.5, 1.0)][int(Gen.TowerArt.hsh(b, layer + 11) * 5.0) % 5]
				var body := Color(shade, shade, shade + 0.08).lerp(tint, 0.18)
				if night > 0.5:
					body = body.darkened(0.45)
				draw_rect(Rect2(bx, -bh, bw - 16.0, bh), body)
				for r2 in int(bh / 60.0):
					if Gen.TowerArt.hsh(b * 31 + r2, layer + 40) < (0.6 if night > 0.5 else 0.3):
						draw_rect(Rect2(bx + 10.0, -bh + 14.0 + r2 * 60.0, bw - 36.0, 22.0), Color(tint if r2 % 3 == 0 else Color(1.0, 0.92, 0.7), 0.8 if night > 0.5 else 0.4))
		Gen.TowerArt.draw(self, _t, night, 0.0, (org.y / sc) + 100.0, sc > 0.4)
		# a layer of cloud round their middle, drifting
		for c in 9:
			var cx := fposmod(c * 900.0 + _t * (20.0 + c * 3.0), 8000.0) - 4000.0
			var cy := -3300.0 - Gen.TowerArt.hsh(c, 3) * 900.0
			for p in 4:
				draw_circle(Vector2(cx + p * 190.0, cy + sin(c + p) * 40.0), 170.0 - p * 22.0, Color(0.8, 0.84, 0.95, 0.16 if night > 0.5 else 0.3))
		# traffic in the air: lights crossing at many heights
		for a in 10:
			var dir := 1.0 if a % 2 == 0 else -1.0
			var ax := (fposmod(a * 733.0 + _t * (160.0 + a * 23.0), 9000.0) - 4500.0) * dir
			var ay := -700.0 - a * 610.0
			draw_rect(Rect2(ax - dir * 70.0, ay, 70.0, 6.0), Color(1.0, 0.9, 0.6, 0.35))
			draw_circle(Vector2(ax, ay + 3.0), 12.0, Color(1.0, 0.95, 0.8))
		if night > 0.5:
			for si in 3:
				var sp: Dictionary = Gen.TowerArt.SPECS[si]
				var tiers: Array = sp["tiers"]
				var p0 := Vector2(float(sp["x"]), -float((tiers[tiers.size() - 1] as Array)[1]) - float(sp["spire"]) * 0.4)
				for lz in 2:
					var ang := -PI * 0.5 + sin(_t * (0.3 + si * 0.13 + lz * 0.2) + si * 2.0 + lz) * 0.9
					draw_line(p0, p0 + Vector2.from_angle(ang) * 3000.0, Color(sp["col"], 0.3), 26.0)
			for s in _sparks:
				var st2 := float(s["t"])
				var rr := 40.0 + st2 * 300.0
				for q2 in 16:
					var dv := Vector2.from_angle(q2 * TAU / 16.0) * rr
					draw_circle(Vector2(float(s["x"]), -float(s["y"])) + dv + Vector2(0.0, st2 * st2 * 60.0), 16.0, Color(s["col"], clampf(1.0 - st2 / 1.8, 0.0, 1.0)))
		# the plaza at their feet
		draw_rect(Rect2(-6000.0, 0.0, 12000.0, 2000.0), Color(0.07, 0.07, 0.12))
		for pl in 40:
			draw_circle(Vector2(-1500.0 + Gen.TowerArt.hsh(pl, 8) * 3000.0, 40.0 + Gen.TowerArt.hsh(pl, 9) * 300.0), 14.0,
				Color([Color(1.0, 0.36, 0.66), Color(0.3, 0.9, 1.0), Color(1.0, 0.82, 0.25), Color(0.55, 1.0, 0.6)][pl % 4], 0.8))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# the scope's rim, what to press
		draw_rect(Rect2(0, 0, w, h), Color(0, 0, 0, 0.9), false, 36.0)
		draw_string(ThemeDB.fallback_font, Vector2(0, h - 34.0), "The Grand Centauria   ·   Esc: put the scope down", HORIZONTAL_ALIGNMENT_CENTER, w, 20, Color(0.8, 0.9, 1.0))


## (Luz: far more detail) the fronts of the buildings on the plaza, drawn storey by storey over the map and under the
## people (art px): the filler buildings – each a row of houses of different heights, windows lit in their own
## colours, balconies with plants, coolers, pipes, shops under striped awnings, neon signs upright and across,
## a billboard that changes, tanks and blinking masts on the roofs – and the Commercial Hall: a grand front with a
## great glass arch full of galleries and people, its name in lights, a running ticker, shop windows in three
## storeys, banners, a glass dome and turning holo marks on its roof.
class FacadeFx extends Node2D:
	const Gen = preload("res://scripts/ground/centauria_gen.gd")
	const NEON := [Color(1.0, 0.36, 0.66), Color(0.3, 0.9, 1.0), Color(1.0, 0.82, 0.25), Color(0.55, 1.0, 0.6), Color(0.72, 0.5, 1.0), Color(1.0, 0.55, 0.25)]
	const SHOPS := ["NOODLES", "ARCADE", "RAMEN", "PAWN", "TATTOO", "KARAOKE", "SUSHI", "BOOKS", "TEA", "VINYL", "PARTS", "FLOWERS", "24H", "DUMPLINGS"]
	const UPRIGHT := ["HOTEL", "BAR", "CLUB", "SAUNA", "CYBER", "DINER", "LOANS", "DOJO"]
	const ADS := ["NOVA COLA", "FLY AURELLE", "LAPIS VIEW", "KHI WORKS", "GRAND CENTAURIA", "PELAGIA TOURS"]
	var buildings: Array = []        # {x, base, w, h (art px), col, seed, kind: "prop" | "hall"}
	var night := 0.0
	var _t := 0.0
	var _acc := 0.0

	func _process(dt: float) -> void:
		_t += dt
		_acc += dt
		if _acc > 0.1:
			_acc = 0.0
			queue_redraw()

	func _h(i: int, salt: int) -> float:
		return Gen.TowerArt.hsh(i, salt)

	func _draw() -> void:
		for b in buildings:
			if String(b.get("kind", "")) == "hall":
				_hall(b)
			else:
				_row(b)

	## A row of houses: each its own width, height, wall and light.
	func _row(b: Dictionary) -> void:
		var x := float(b["x"])
		var seed := int(b["seed"])
		var end := x + float(b["w"])
		var i := 0
		while x < end - 20.0:
			var hw := minf(72.0 + _h(seed + i, 1) * 60.0, end - x)
			if end - (x + hw) < 60.0:
				hw = end - x
			_house(x, float(b["base"]), hw, float(b["h"]) * (0.62 + _h(seed + i, 2) * 0.38), seed * 31 + i * 7, b["col"])
			x += hw
			i += 1

	## One house (Luz: at the scale of the people before it): on the ground floor a shop with a door you could walk
	## through, a window full of goods and light, an awning, its name on a board; over it storeys as high as a room,
	## their windows framed (blinds, curtains, somebody looking out, a plant), balconies with washing on a line.
	func _house(x: float, base: float, w: float, h: float, seed: int, col: Color) -> void:
		var font := ThemeDB.fallback_font
		var top := base - h
		var nightly := night > 0.5
		var wall := Color(0.13, 0.13, 0.2).lerp([Color(0.3, 0.2, 0.4), Color(0.16, 0.3, 0.36), Color(0.34, 0.22, 0.2), Color(0.2, 0.22, 0.34)][int(_h(seed, 3) * 4.0) % 4], 0.6)
		var tint: Color = NEON[int(_h(seed, 4) * NEON.size()) % NEON.size()]
		var frame := wall.lightened(0.18)
		draw_rect(Rect2(x, top, w, h), wall)
		draw_rect(Rect2(x, top, 2.0, h), wall.lightened(0.12))
		draw_rect(Rect2(x + w - 2.0, top, 2.0, h), wall.darkened(0.35))
		# storeys: a room is two windows wide; lit room by room
		var shop := 54.0
		var st_h := 38.0
		var n := int((h - shop - 6.0) / st_h)
		var pitch := 18.0
		var cols := maxi(1, int((w - 12.0) / pitch))
		var x0 := x + (w - cols * pitch) * 0.5 + 3.0
		var balc := _h(seed, 5) < 0.55
		for s in n:
			var y := base - shop - (s + 1) * st_h
			draw_rect(Rect2(x + 2.0, y + st_h - 2.0, w - 4.0, 2.0), wall.darkened(0.3))
			draw_rect(Rect2(x + 2.0, y + st_h - 3.0, w - 4.0, 1.0), wall.lightened(0.1))
			for c in cols:
				var wx := x0 + c * pitch
				var wy := y + 7.0
				var cell := s * 13 + c / 2
				var on := (_h(seed + cell, 6) < (0.55 if nightly else 0.2) and _h(seed + s * 17 + c, 7) < 0.9) or _h(seed + s * 17 + c, 8) < 0.05
				draw_rect(Rect2(wx - 1.0, wy - 1.0, 14.0, 22.0), frame)
				var wc := Color(0.07, 0.09, 0.15)
				if on:
					wc = Color(1.0, 0.9, 0.66) if _h(seed + cell, 9) < 0.6 else tint.lerp(Color(1, 1, 1), 0.3)
					wc.a = 0.95 if nightly else 0.55
				draw_rect(Rect2(wx, wy, 12.0, 20.0), wc)
				if not on:
					draw_rect(Rect2(wx, wy, 12.0, 6.0), Color(0.35, 0.45, 0.7, 0.16))
				var hk := _h(seed + s * 5 + c, 10)
				if on and hk < 0.26:                                       # a blind half down
					draw_rect(Rect2(wx, wy, 12.0, 10.0), wall.darkened(0.25))
					for sl in 3:
						draw_rect(Rect2(wx, wy + 2.0 + sl * 3.0, 12.0, 1.0), wall.darkened(0.45))
				elif on and hk < 0.5:                                      # curtains
					draw_rect(Rect2(wx, wy, 3.0, 20.0), Color(tint.darkened(0.25), 0.85))
					draw_rect(Rect2(wx + 9.0, wy, 3.0, 20.0), Color(tint.darkened(0.25), 0.85))
				elif on and hk < 0.62:                                     # somebody at the window
					draw_rect(Rect2(wx + 2.5, wy + 13.0, 7.0, 7.0), Color(0.1, 0.08, 0.12, 0.85))
					draw_circle(Vector2(wx + 6.0, wy + 10.5), 2.6, Color(0.1, 0.08, 0.12, 0.85))
				elif hk > 0.86:                                            # a plant on the sill
					draw_rect(Rect2(wx + 2.0, wy + 17.0, 4.0, 3.0), Color(0.5, 0.3, 0.2))
					draw_circle(Vector2(wx + 4.0, wy + 14.5), 3.0, Color(0.18, 0.5, 0.26))
				draw_rect(Rect2(wx + 5.5, wy, 1.0, 20.0), frame)
				draw_rect(Rect2(wx, wy + 8.0, 12.0, 1.0), frame)
				draw_rect(Rect2(wx - 2.0, wy + 21.0, 16.0, 2.0), wall.lightened(0.28))
				if _h(seed + s * 29 + c, 11) < 0.1:                         # a cooler under the window
					draw_rect(Rect2(wx + 1.0, wy + 23.0, 10.0, 6.0), Color(0.55, 0.57, 0.62))
					draw_circle(Vector2(wx + 6.0, wy + 26.0), 2.0, Color(0.15, 0.15, 0.2))
			if balc and s % 2 == 1:
				var by := y + st_h - 13.0
				draw_rect(Rect2(x + 3.0, by + 11.0, w - 6.0, 2.0), Color(0.5, 0.52, 0.6))
				for pl in 3:
					if _h(seed + s * 3 + pl, 12) < 0.55:
						var bx := x + 8.0 + pl * (w - 24.0) / 3.0
						draw_rect(Rect2(bx, by + 6.0, 7.0, 5.0), Color(0.45, 0.28, 0.2))
						draw_circle(Vector2(bx + 3.5, by + 3.0), 4.5, Color(0.2, 0.58, 0.3))
				draw_rect(Rect2(x + 3.0, by, w - 6.0, 1.5), Color(0.68, 0.7, 0.78))
				for px in range(int(x) + 4, int(x + w) - 4, 5):
					draw_rect(Rect2(px, by, 1.0, 11.0), Color(0.45, 0.47, 0.55))
				if _h(seed + s, 24) < 0.45:                                  # washing on a line
					draw_rect(Rect2(x + 6.0, by - 8.0, w - 12.0, 0.8), Color(0.75, 0.75, 0.8))
					for ws in 4:
						var lcol: Color = NEON[(seed + s + ws) % NEON.size()]
						draw_rect(Rect2(x + 10.0 + ws * (w - 26.0) / 4.0, by - 8.0, 6.0, 7.0 + (ws % 2) * 2.0), lcol.lerp(Color(0.9, 0.9, 0.9), 0.45))
		# a pipe down one side, a strip of neon up the other
		draw_rect(Rect2(x + w - 6.0, top + 8.0, 2.0, h - shop - 10.0), Color(0.4, 0.42, 0.5))
		if _h(seed, 13) < 0.6:
			draw_rect(Rect2(x + 2.0, top + 10.0, 1.5, h - shop - 14.0), Color(tint, 0.6 + 0.3 * sin(_t * 2.0 + seed)))
		# the shop on the ground floor
		var sc: Color = NEON[int(_h(seed, 14) * NEON.size()) % NEON.size()]
		var sy := base - shop
		var flick := 1.0 if _h(seed, 15) > 0.25 else (0.35 + 0.65 * absf(sin(_t * 7.0 + seed)))
		draw_rect(Rect2(x + 2.0, sy, w - 4.0, shop), Color(0.05, 0.05, 0.09))
		draw_rect(Rect2(x + 4.0, sy + 2.0, w - 8.0, 11.0), Color(0.03, 0.03, 0.06))                      # its name on a board
		draw_rect(Rect2(x + 4.0, sy + 2.0, w - 8.0, 11.0), Color(sc, 0.8 * flick), false, 1.0)
		draw_string(font, Vector2(x + 4.0, sy + 11.0), SHOPS[int(_h(seed, 16) * SHOPS.size()) % SHOPS.size()], HORIZONTAL_ALIGNMENT_CENTER, w - 8.0, 9, Color(sc.lightened(0.3), flick))
		var aw := 0                                                                                    # the awning
		var ax := x + 3.0
		while ax < x + w - 3.0:
			var sw := minf(6.0, x + w - 3.0 - ax)
			draw_rect(Rect2(ax, sy + 14.0, sw, 7.0), sc if aw % 2 == 0 else Color(0.95, 0.95, 0.95))
			draw_rect(Rect2(ax, sy + 21.0, sw, 2.0), (sc if aw % 2 == 0 else Color(0.95, 0.95, 0.95)).darkened(0.3))
			ax += 6.0
			aw += 1
		draw_rect(Rect2(x + 3.0, sy + 23.0, w - 6.0, 1.5), Color(0, 0, 0, 0.4))
		var dx := x + w - 22.0                                                                         # the door: as high as a doorway
		draw_rect(Rect2(dx - 1.0, base - 32.0, 17.0, 32.0), frame)
		draw_rect(Rect2(dx, base - 31.0, 15.0, 31.0), Color(0.1, 0.12, 0.2))
		draw_rect(Rect2(dx + 1.5, base - 29.5, 12.0, 20.0), Color(1.0, 0.9, 0.62, 0.8 if nightly else 0.45))
		draw_rect(Rect2(dx + 3.0, base - 27.0, 9.0, 4.0), Color(sc, 0.95))
		draw_rect(Rect2(dx + 11.5, base - 13.0, 1.5, 5.0), Color(0.85, 0.85, 0.9))
		draw_rect(Rect2(dx - 2.0, base - 2.0, 19.0, 2.0), Color(0.5, 0.5, 0.56))
		draw_circle(Vector2(dx - 4.0, base - 34.0), 1.6, Color(1.0, 0.9, 0.6))
		var gw := dx - 5.0 - (x + 6.0)                                                                 # the window: goods on shelves, somebody inside
		draw_rect(Rect2(x + 5.0, base - 32.0, gw + 2.0, 28.0), frame)
		draw_rect(Rect2(x + 6.0, base - 31.0, gw, 26.0), Color(sc.lerp(Color(1.0, 0.92, 0.7), 0.55), 0.9 if nightly else 0.5))
		for sh in 2:
			var yy := base - 21.0 + sh * 10.0
			draw_rect(Rect2(x + 8.0, yy, gw - 4.0, 1.0), Color(0.1, 0.07, 0.1, 0.6))
			for q in int((gw - 6.0) / 6.0):
				var gh := 3.0 + _h(seed + sh * 11 + q, 25) * 4.0
				var gc: Color = NEON[int(_h(seed + sh * 7 + q, 26) * NEON.size()) % NEON.size()]
				draw_rect(Rect2(x + 9.0 + q * 6.0, yy - gh, 4.0, gh), Color(gc.darkened(0.35), 0.85))
		var kx := x + 6.0 + gw * (0.3 + 0.4 * _h(seed, 27))
		draw_rect(Rect2(kx - 4.0, base - 19.0, 8.0, 14.0), Color(0.1, 0.07, 0.11, 0.85))
		draw_circle(Vector2(kx, base - 22.0), 3.0, Color(0.1, 0.07, 0.11, 0.85))
		for mu in range(1, int(gw / 24.0) + 1):
			if x + 6.0 + mu * 24.0 < dx - 8.0:
				draw_rect(Rect2(x + 6.0 + mu * 24.0, base - 31.0, 1.0, 26.0), frame)
		draw_rect(Rect2(x + 6.0, base - 31.0, gw, 3.0), Color(1, 1, 1, 0.14))
		draw_rect(Rect2(x + 5.0, base - 5.0, gw + 2.0, 5.0), wall.darkened(0.25))
		if nightly:
			draw_rect(Rect2(x + 6.0, base, gw, 6.0), Color(sc.lerp(Color(1.0, 0.92, 0.7), 0.55), 0.1))  # its light on the pavement
		# an upright sign on the wall: letters one under the other
		if _h(seed, 17) < 0.7 and h > 200.0:
			var word: String = UPRIGHT[int(_h(seed, 18) * UPRIGHT.size()) % UPRIGHT.size()]
			var uc: Color = NEON[int(_h(seed, 19) * NEON.size()) % NEON.size()]
			var ux := x + (6.0 if _h(seed, 20) < 0.5 else w - 16.0)
			var uy := top + 22.0
			draw_rect(Rect2(ux - 1.0, uy - 2.0, 11.0, word.length() * 9.0 + 4.0), Color(0.02, 0.02, 0.05))
			draw_rect(Rect2(ux - 1.0, uy - 2.0, 11.0, word.length() * 9.0 + 4.0), uc, false, 1.0)
			for li in word.length():
				draw_string(font, Vector2(ux, uy + 7.0 + li * 9.0), word[li], HORIZONTAL_ALIGNMENT_CENTER, 9.0, 8, uc.lightened(0.3))
		# a billboard that changes, on the wider houses
		if w > 80.0 and h > 240.0:
			var ai := int(_t / 4.0 + seed) % ADS.size()
			var hue := fposmod(_h(seed, 21) + _t * 0.02, 1.0)
			var bbx := x + w * 0.5 - 30.0
			var bby := top + 46.0
			draw_rect(Rect2(bbx - 2.0, bby - 2.0, 64.0, 30.0), Color(0.02, 0.02, 0.05))
			draw_rect(Rect2(bbx, bby, 60.0, 26.0), Color.from_hsv(hue, 0.7, 0.5))
			draw_rect(Rect2(bbx + fposmod(_t * 14.0, 60.0), bby, 4.0, 26.0), Color(1, 1, 1, 0.12))
			draw_string(font, Vector2(bbx, bby + 16.0), ADS[ai], HORIZONTAL_ALIGNMENT_CENTER, 60.0, 7, Color(1, 1, 1))
		# the roof: its edge, a tank or a garden, a mast with a blinking lamp
		draw_rect(Rect2(x - 1.0, top - 3.0, w + 2.0, 4.0), wall.lightened(0.25))
		if _h(seed, 22) < 0.5:
			draw_rect(Rect2(x + 9.0, top - 9.0, 2.0, 7.0), Color(0.25, 0.22, 0.2))
			draw_rect(Rect2(x + 25.0, top - 9.0, 2.0, 7.0), Color(0.25, 0.22, 0.2))
			draw_rect(Rect2(x + 7.0, top - 27.0, 22.0, 19.0), Color(0.35, 0.3, 0.26))
			draw_rect(Rect2(x + 7.0, top - 20.0, 22.0, 1.5), Color(0.5, 0.5, 0.56))
			draw_colored_polygon(PackedVector2Array([Vector2(x + 5.0, top - 27.0), Vector2(x + 18.0, top - 34.0), Vector2(x + 31.0, top - 27.0)]), Color(0.45, 0.4, 0.34))
		else:
			for g in 4:
				draw_rect(Rect2(x + 6.0 + g * 9.0, top - 9.0 - _h(seed + g, 23) * 7.0, 7.0, 7.0 + _h(seed + g, 23) * 7.0), Color(0.18, 0.55, 0.28))
		var mx := x + w - 14.0
		draw_rect(Rect2(mx, top - 34.0, 1.5, 32.0), Color(0.6, 0.62, 0.7))
		draw_circle(Vector2(mx + 0.75, top - 35.0), 2.0, Color(1.0, 0.2, 0.2) if int(_t * 1.2 + seed) % 2 == 0 else Color(0.4, 0.1, 0.1))
		draw_rect(Rect2(x + 4.0, top - 2.0, w - 8.0, 1.5), Color(tint, 0.7))

	## The Commercial Hall's front.
	func _hall(b: Dictionary) -> void:
		var font := ThemeDB.fallback_font
		var x := float(b["x"])
		var w := float(b["w"])
		var base := float(b["base"])
		var h := float(b["h"])
		var top := base - h
		var mid := x + w * 0.5
		var gold := Color(1.0, 0.82, 0.35)
		var orange := Color(1.0, 0.6, 0.25)
		var wall := Color(0.2, 0.15, 0.14)
		# the body: a middle part higher than its two wings, gold edges
		draw_rect(Rect2(x, top + 40.0, w, h - 40.0), wall)
		draw_rect(Rect2(mid - 84.0, top, 168.0, h), wall.lightened(0.06))
		for ex in [x, x + w - 3.0, mid - 84.0, mid + 81.0]:
			draw_rect(Rect2(float(ex), top + (0.0 if absf(float(ex) - mid) < 90.0 else 40.0), 3.0, h), gold.darkened(0.2))
		draw_rect(Rect2(x, top + 38.0, w, 3.0), gold)
		draw_rect(Rect2(mid - 84.0, top - 2.0, 168.0, 3.0), gold)
		# the wings: three storeys of shop windows between pillars, each its own light and name; balconies, banners
		var side := 0
		for wx0 in [x + 6.0, mid + 90.0]:
			var ww := mid - 90.0 - (x + 6.0)
			for lv in 3:
				var ly := base - 30.0 - lv * 62.0
				var nshop := int(ww / 38.0)
				for s in nshop:
					var sx: float = float(wx0) + s * (ww / nshop)
					var sw := ww / nshop - 6.0
					var seed := side * 100 + lv * 10 + s
					var sc: Color = NEON[int(_h(seed, 31) * NEON.size()) % NEON.size()]
					draw_rect(Rect2(sx, ly - 30.0, sw, 30.0), Color(0.05, 0.04, 0.07))
					draw_rect(Rect2(sx + 2.0, ly - 26.0, sw - 4.0, 24.0), Color(sc.lerp(Color(1.0, 0.92, 0.72), 0.55), 0.9 if night > 0.5 else 0.55))
					for q in 3:
						draw_rect(Rect2(sx + 4.0 + q * (sw - 10.0) / 3.0, ly - 16.0 - _h(seed + q, 32) * 4.0, 3.0, 14.0 + _h(seed + q, 32) * 4.0), Color(0.1, 0.07, 0.1, 0.75))
					draw_string(font, Vector2(sx, ly - 33.0), SHOPS[(seed * 3 + 1) % SHOPS.size()], HORIZONTAL_ALIGNMENT_CENTER, sw, 6, sc.lightened(0.35))
					draw_rect(Rect2(sx - 3.0, ly - 44.0, 3.0, 44.0), wall.lightened(0.2))
				# the gallery's rail, a banner hanging from it now and then
				draw_rect(Rect2(float(wx0) - 3.0, ly, ww + 3.0, 2.0), gold.darkened(0.1))
				for bn in range(int(float(wx0)) + 14, int(float(wx0) + ww) - 6, 44):
					var bc: Color = NEON[(bn + lv) % NEON.size()]
					draw_colored_polygon(PackedVector2Array([Vector2(bn, ly + 2.0), Vector2(bn + 10.0, ly + 2.0), Vector2(bn + 10.0, ly + 14.0), Vector2(bn + 5.0, ly + 10.0), Vector2(bn, ly + 14.0)]), bc)
			# the ground floor of the wing: an arcade, lamps
			for ar in range(int(float(wx0)), int(float(wx0) + ww) - 10, 26):
				draw_rect(Rect2(ar + 3.0, base - 24.0, 20.0, 24.0), Color(1.0, 0.86, 0.6, 0.8 if night > 0.5 else 0.45))
				draw_rect(Rect2(ar, base - 28.0, 3.0, 28.0), wall.lightened(0.25))
				draw_circle(Vector2(ar + 13.0, base - 26.0), 2.0, gold)
			side += 1
		# the great arch of glass in the middle: galleries inside, people on them, an escalator's lights
		var aw := 132.0
		var ah := h - 150.0
		var ay := base - ah
		draw_rect(Rect2(mid - aw * 0.5 - 4.0, ay - 4.0, aw + 8.0, ah + 4.0), gold.darkened(0.25))
		draw_rect(Rect2(mid - aw * 0.5, ay, aw, ah), Color(1.0, 0.88, 0.62, 0.95 if night > 0.5 else 0.7))
		draw_circle(Vector2(mid, ay), aw * 0.5 + 4.0, gold.darkened(0.25))
		draw_circle(Vector2(mid, ay), aw * 0.5, Color(1.0, 0.9, 0.68, 0.95 if night > 0.5 else 0.7))
		for gl in 5:
			var gy := base - 34.0 - gl * 34.0
			draw_rect(Rect2(mid - aw * 0.5, gy, aw, 2.0), Color(0.45, 0.3, 0.18))
			for p in 7:
				var px := mid - aw * 0.5 + 6.0 + fposmod(_h(gl * 9 + p, 33) * aw + _t * (3.0 + _h(gl + p, 34) * 5.0) * (1.0 if p % 2 == 0 else -1.0), aw - 12.0)
				draw_rect(Rect2(px, gy - 9.0, 3.0, 9.0), Color(0.2, 0.12, 0.14, 0.85))
				draw_rect(Rect2(px, gy - 12.0, 3.0, 3.0), Color(0.32, 0.2, 0.18, 0.85))
		for mu in [-aw * 0.25, 0.0, aw * 0.25]:
			draw_rect(Rect2(mid + float(mu) - 1.0, ay - aw * 0.4, 2.0, ah + aw * 0.4), gold.darkened(0.3))
		for es in 9:
			draw_circle(Vector2(mid - 50.0 + es * 12.0, base - 40.0 - es * 15.0), 1.5, Color(0.3, 0.9, 1.0, 0.5 + 0.5 * sin(_t * 4.0 - es)))
		# the doors under it
		draw_rect(Rect2(mid - 34.0, base - 30.0, 68.0, 30.0), Color(0.14, 0.1, 0.08))
		for dd in 4:
			draw_rect(Rect2(mid - 31.0 + dd * 16.0, base - 27.0, 14.0, 27.0), Color(1.0, 0.94, 0.78, 0.9))
		# the name in lights, bulbs running round it; under it a ticker of what is inside
		var ny := ay - aw * 0.5 - 52.0
		draw_rect(Rect2(mid - 150.0, ny, 300.0, 32.0), Color(0.04, 0.03, 0.06))
		draw_rect(Rect2(mid - 150.0, ny, 300.0, 32.0), orange, false, 2.0)
		draw_string(font, Vector2(mid - 150.0, ny + 23.0), "COMMERCIAL HALL", HORIZONTAL_ALIGNMENT_CENTER, 300.0, 22, gold.lightened(0.2))
		var bi := 0
		for bx in range(int(mid) - 146, int(mid) + 147, 12):
			for byy in [ny + 2.0, ny + 30.0]:
				draw_circle(Vector2(bx, float(byy)), 1.6, Color(1.0, 0.95, 0.7) if (bi + int(_t * 6.0)) % 3 == 0 else Color(0.5, 0.35, 0.15))
			bi += 1
		var tick := "MARKET  ·  OUTFITTER  ·  GEAR  ·  CLINIC  ·  BAR  ·  QUARTERS  ·  OPEN ALL NIGHT  ·  "
		var off := int(_t * 5.0) % tick.length()
		var shown := (tick + tick).substr(off, 46)
		draw_rect(Rect2(mid - 140.0, ny + 36.0, 280.0, 11.0), Color(0.02, 0.02, 0.04))
		draw_string(font, Vector2(mid - 138.0, ny + 44.5), shown, HORIZONTAL_ALIGNMENT_LEFT, 276.0, 8, Color(0.4, 1.0, 0.7))
		# the roof: a dome of glass over the middle, masts, two holo marks turning, at night beams
		for aw2 in 7:
			draw_rect(Rect2(mid - 69.0 + aw2 * 21.0, top + 8.0, 12.0, 17.0), gold.darkened(0.3))
			draw_rect(Rect2(mid - 68.0 + aw2 * 21.0, top + 9.0, 10.0, 15.0), Color(1.0, 0.88, 0.62, 0.9 if night > 0.5 else 0.5))
			draw_rect(Rect2(mid - 63.5 + aw2 * 21.0, top + 9.0, 1.0, 15.0), gold.darkened(0.3))
		# (Luz: the dome was broken) half a dome on a drum with small windows: rings and ribs, lit from inside, a lamp on its tip
		var dr := 46.0
		var dby := top - 14.0
		draw_rect(Rect2(mid - dr - 7.0, dby, dr * 2.0 + 14.0, 12.0), wall.lightened(0.14))
		draw_rect(Rect2(mid - dr - 9.0, dby - 2.0, dr * 2.0 + 18.0, 3.0), gold)
		for dw in 9:
			draw_rect(Rect2(mid - dr + 3.0 + dw * 10.4, dby + 3.5, 6.0, 5.5), Color(1.0, 0.9, 0.65, 0.9 if night > 0.5 else 0.4))
		var dome := PackedVector2Array()
		for dk in 25:
			var da := PI + dk * PI / 24.0
			dome.append(Vector2(mid + cos(da) * dr, dby - 2.0 + sin(da) * dr))
		draw_colored_polygon(dome, Color(0.16, 0.34, 0.62) if night > 0.5 else Color(0.45, 0.68, 0.9))
		if night > 0.5:
			for dg in 4:
				var gr := dr * (0.92 - dg * 0.2)
				var glowp := PackedVector2Array()
				for dk2 in 13:
					var da2 := PI + dk2 * PI / 12.0
					glowp.append(Vector2(mid + cos(da2) * gr, dby - 2.0 + sin(da2) * gr * 0.8))
				draw_colored_polygon(glowp, Color(1.0, 0.85, 0.6, 0.1))
		for dph in [0.3, 0.62, 0.95, 1.25]:
			var ry := dby - 2.0 - sin(float(dph)) * dr
			var rx := cos(float(dph)) * dr
			draw_line(Vector2(mid - rx, ry), Vector2(mid + rx, ry), Color(0.85, 0.92, 1.0, 0.5), 1.0)
		for dl in [-1.15, -0.72, -0.35, 0.0, 0.35, 0.72, 1.15]:
			var rib := PackedVector2Array()
			for dk3 in 9:
				var ph2 := dk3 * PI * 0.5 / 8.0
				rib.append(Vector2(mid + cos(ph2) * sin(float(dl)) * dr, dby - 2.0 - sin(ph2) * dr))
			draw_polyline(rib, Color(0.85, 0.92, 1.0, 0.6), 1.0)
		draw_arc(Vector2(mid - 4.0, dby - 2.0), dr - 6.0, PI * 1.12, PI * 1.42, 10, Color(1, 1, 1, 0.3), 3.0)
		draw_arc(Vector2(mid, dby - 2.0), dr, PI, TAU, 32, gold, 2.0)
		draw_rect(Rect2(mid - 1.0, dby - dr - 16.0, 2.0, 15.0), gold)
		draw_circle(Vector2(mid, dby - dr - 17.0), 2.5, Color(1.0, 0.9, 0.6) if int(_t * 1.5) % 2 == 0 else gold.darkened(0.3))
		for hm in [-1.0, 1.0]:
			var hx := mid + float(hm) * (w * 0.5 - 60.0)
			var hy := top + 12.0
			var sq := absf(cos(_t * 1.2 + float(hm)))
			draw_colored_polygon(PackedVector2Array([Vector2(hx, hy - 22.0), Vector2(hx + 14.0 * sq, hy), Vector2(hx, hy + 22.0), Vector2(hx - 14.0 * sq, hy)]), Color(orange, 0.7))
			draw_rect(Rect2(hx - 1.0, hy + 22.0, 2.0, 8.0), Color(0.6, 0.62, 0.7))
			draw_rect(Rect2(hx + float(hm) * 34.0, top + 6.0, 1.5, 34.0), Color(0.6, 0.62, 0.7))
			draw_circle(Vector2(hx + float(hm) * 34.0 + 0.75, top + 5.0), 2.0, Color(1.0, 0.2, 0.2) if int(_t * 1.3 + float(hm)) % 2 == 0 else Color(0.4, 0.1, 0.1))
			if night > 0.5:
				var ang := -PI * 0.5 + sin(_t * 0.5 + float(hm)) * 0.5
				draw_line(Vector2(hx, hy), Vector2(hx, hy) + Vector2.from_angle(ang) * 260.0, Color(orange, 0.22), 6.0)


## (Luz) tall buildings round the south of the district, so the plaza lies wrapped in the city. You see them from
## above: their roofs come up from the bottom of the picture, and what stands on them stands upright (water towers,
## coolers with turning fans, stacks steaming, huts of stairs with a lit door, dishes, greenhouses, a bar with guests,
## projectors with a mark of light turning over them), between them pools, gardens, landing pads, solar panels. The
## highest ones carry a penthouse with lit windows and a mast. A line of neon runs along the edge that looks onto the
## plaza, and on that edge stand the backs of signs and masts. The roofs begin where the ground you can walk on ends
## and stand a few pixels over it (who stands at the very edge has the feet behind the parapet); the street to the
## back alleys stays open between two of them as a canyon, lanterns strung across it. Two rows: the near one (tier 2)
## lies further south, is larger and darker, throws its shade on the first and shifts against the camera a little.
## Drawn over the people and over the pools of light of the lamps (art px).
class RoofFx extends Node2D:
	const Gen = preload("res://scripts/ground/centauria_gen.gd")
	const NEON := [Color(1.0, 0.36, 0.66), Color(0.3, 0.9, 1.0), Color(1.0, 0.82, 0.25), Color(0.55, 1.0, 0.6), Color(0.72, 0.5, 1.0), Color(1.0, 0.55, 0.25)]
	const ALLEY := ["BAR", "INK", "LIVE", "24H", "DIVE", "RAMEN"]
	const BOARDS := ["NOVA COLA", "AURELLE", "KHI", "LAPIS VIEW", "PELAGIA", "ORBIT GIN", "HOTEL", "CLUB 9"]
	const OVER := 7.0                # how far a roof may stand over the last ground you can walk on (art px)
	const KINDS := 14                # (two of them billboards)
	const SLIT := 8.0                # between two buildings: a dark cleft
	var tier := 1
	var view = null
	var night := 0.0
	var gap := Rect2()               # the street to the back alleys: both rows leave it open
	var bottom := 0.0                # the map ends here
	var line := 0.0                  # the row of buildings begins here (tier 1: each roof at the ground it stands behind)
	var _roofs: Array = []           # {r: Rect2, seed, lvl, tint}
	var _t := 0.0
	var _acc := 0.0

	func setup(p_tier: int, p_view, m: GroundMap, p_night: float) -> void:
		tier = p_tier
		view = p_view
		night = p_night
		var tl := float(GroundMap.TILE)
		var mid := Gen.P_CX + Gen.P_CW / 2
		var street := Gen.P_TOP + 28                     # the plaza ends here, the street south begins
		bottom = float(m.h) * tl
		line = float(street) * tl if tier == 1 else bottom - 6.0 * tl
		gap = Rect2((mid - 3) * tl, float(street) * tl, 6.0 * tl, bottom - float(street) * tl + 400.0)
		var rng := RandomNumberGenerator.new()
		rng.seed = 6130 + tier * 77
		var x := -420.0
		var end := float(m.w) * tl + 420.0
		while x < end:
			var w := rng.randf_range(150.0, 250.0) if tier == 1 else rng.randf_range(250.0, 390.0)
			if x < gap.position.x and x + w > gap.position.x - 90.0:
				w = gap.position.x - x                       # this one ends at the street
			var y := line + (rng.randf_range(0.0, 26.0) if tier == 2 else 0.0)
			if tier == 1:
				# behind the lowest ground you can walk on in its width (the street itself aside)
				var low := street - 1
				for tx in range(maxi(0, int(floor(x / tl))), mini(m.w, int(ceil((x + w) / tl)))):
					for ty in range(m.h - 1, low, -1):
						if GroundMap.walkable_t(m.t_at(tx, ty)) and not (tx >= mid - 3 and tx < mid + 3):
							low = ty
							break
				y = float(low + 1) * tl - rng.randf_range(3.0, OVER)
			_roofs.append({"r": Rect2(x, y, w - SLIT, bottom - y + 400.0), "seed": rng.randi() % 100000, "lvl": rng.randi() % 3,
				"tint": NEON[rng.randi() % NEON.size()]})
			x += w
			if absf(x - gap.position.x) < 1.0:
				x = gap.end.x
		_roofs.sort_custom(func(a, b): return int(a["lvl"]) < int(b["lvl"]))

	## The outlines of the roofs (for the tests).
	func roofs() -> Array:
		return _roofs.map(func(d): return d["r"])

	func _process(dt: float) -> void:
		_t += dt
		if tier == 2 and view != null and is_instance_valid(view) and (view._cam_c as Vector2) != Vector2.INF:
			var midp := gap.get_center().x * GroundMap.SCALE
			position.x = -((view._cam_c as Vector2).x - midp) * 0.1      # the near row shifts against you
		_acc += dt
		if _acc > 0.08:
			_acc = 0.0
			queue_redraw()

	func _h(i: int, salt: int) -> float:
		return Gen.TowerArt.hsh(i, salt)

	func _draw() -> void:
		# only the roofs in the picture (and a little beside it)
		var lo := -1.0e9
		var hi := 1.0e9
		var wn := get_parent() as Node2D
		if wn != null and wn.scale.x > 0.0 and scale.x > 0.0:
			lo = ((-260.0 - wn.position.x) / wn.scale.x - position.x) / scale.x
			hi = ((get_viewport_rect().size.x + 260.0 - wn.position.x) / wn.scale.x - position.x) / scale.x
		if tier == 1:
			_alley()
		# between two buildings a dark cleft, a thread of neon deep in it (never the ground showing through)
		for d0 in _roofs:
			var r0: Rect2 = d0["r"]
			if r0.end.x > lo and r0.position.x < hi and absf(r0.end.x + SLIT - gap.position.x) > 1.0:
				draw_rect(Rect2(r0.end.x - 2.0, r0.position.y + 2.0, SLIT + 4.0, r0.size.y), Color(0.02, 0.02, 0.05))
				var tc: Color = d0["tint"]
				draw_rect(Rect2(r0.end.x + SLIT * 0.5 - 0.5, r0.position.y + 10.0, 1.0, r0.size.y), Color(tc, 0.3))
			elif r0.end.x > lo and r0.position.x < hi:
				draw_rect(Rect2(r0.end.x - 2.0, r0.position.y + 2.0, SLIT + 2.0, r0.size.y), Color(0.02, 0.02, 0.05))
		for d in _roofs:
			var r: Rect2 = d["r"]
			if r.end.x > lo and r.position.x < hi:
				_roof(d)
		if tier == 1:
			_lanterns()
			_gate()
		else:
			_drones()

	func _ell(c: Vector2, rx: float, ry: float, col: Color) -> void:
		var pts := PackedVector2Array()
		for k in 14:
			pts.append(c + Vector2(cos(k * TAU / 14.0) * rx, sin(k * TAU / 14.0) * ry))
		draw_colored_polygon(pts, col)

	## A box standing on the roof: its front (h high) down to yb, its top (d deep) above that.
	func _box(x: float, yb: float, w: float, d: float, h: float, top: Color, face: Color) -> void:
		draw_rect(Rect2(x + 3.0, yb - 2.0, w, 4.0), Color(0, 0, 0, 0.35))
		draw_rect(Rect2(x, yb - h, w, h), face)
		draw_rect(Rect2(x, yb - h - d, w, d), top)
		draw_rect(Rect2(x, yb - h - d, w, 1.0), top.lightened(0.25))

	## Somebody seen from behind, the feet at c.
	func _person(c: Vector2, col: Color) -> void:
		draw_rect(Rect2(c.x - 3.0, c.y - 7.0, 2.5, 7.0), Color(0.08, 0.08, 0.12))
		draw_rect(Rect2(c.x + 0.5, c.y - 7.0, 2.5, 7.0), Color(0.08, 0.08, 0.12))
		draw_rect(Rect2(c.x - 4.0, c.y - 16.0, 8.0, 10.0), col)
		draw_circle(Vector2(c.x, c.y - 19.0), 3.2, Color(0.16, 0.12, 0.12))

	func _roof(d: Dictionary) -> void:
		var r: Rect2 = d["r"]
		var seed := int(d["seed"])
		var lvl := int(d["lvl"])
		var tint: Color = d["tint"]
		var s := 1.35 if tier == 2 else 1.0
		var hues: Array = [Color(0.26, 0.2, 0.32), Color(0.16, 0.24, 0.3), Color(0.24, 0.2, 0.2)]
		var base: Color = Color(0.17, 0.17, 0.25).lerp(hues[seed % 3], 0.5)
		if night < 0.5:
			base = base.lightened(0.28)
		if tier == 2:
			base = base.darkened(0.3)
		# the shade it throws north: a little over the edge of the plaza (tier 1), over the lower roofs behind it (tier 2)
		var sh := 1.5 if tier == 1 else 3.5
		for k in 4:
			draw_rect(Rect2(r.position.x, r.position.y - (k + 1) * sh, r.size.x, sh), Color(0, 0, 0, (0.2 if tier == 1 else 0.34) * (1.0 - k / 4.0)))
		# its shadow on the lower roofs beside it (the higher it stands, the further it falls), then the roof itself
		draw_rect(Rect2(r.position + Vector2(5.0 + lvl * 4.0, 5.0 + lvl * 4.0), r.size), Color(0, 0, 0, 0.4))
		draw_rect(r, base)
		for px in range(int(r.position.x) + 18, int(r.end.x) - 4, 22):
			draw_rect(Rect2(px, r.position.y + 5.0, 1.0, r.size.y - 5.0), base.darkened(0.18))
		for py in range(int(r.position.y) + 40, int(minf(r.end.y, bottom + 60.0)), 44):
			draw_rect(Rect2(r.position.x + 3.0, py, r.size.x - 6.0, 1.0), base.darkened(0.12))
		for pu in 3:                                                                                   # rain standing in puddles: the neon in them
			var pp := r.position + Vector2(14.0 + _h(seed + pu, 50) * (r.size.x - 28.0), 24.0 + _h(seed + pu, 51) * 64.0 * s)
			_ell(pp, 7.0 + 6.0 * _h(seed + pu, 52), 2.5, Color(tint, 0.1))
		draw_rect(Rect2(r.position, Vector2(r.size.x, 4.0)), base.lightened(0.3))                      # the parapet
		draw_rect(Rect2(r.position, Vector2(3.0, r.size.y)), base.lightened(0.18))
		draw_rect(Rect2(r.end.x - 3.0, r.position.y, 3.0, r.size.y), base.darkened(0.3))
		var pulse := 0.75 + 0.25 * sin(_t * 1.4 + seed)
		draw_rect(Rect2(r.position.x + 2.0, r.position.y + 1.0, r.size.x - 4.0, 1.5), Color(tint, 0.95 * pulse))      # neon along the side of the plaza
		draw_rect(Rect2(r.position.x + 2.0, r.position.y - 2.0, r.size.x - 4.0, 3.0), Color(tint, 0.16 * pulse))
		if seed % 2 == 0:                                                                              # small lamps along it, running
			for k2 in range(0, int(r.size.x) - 10, 8):
				var on := (k2 / 8 + int(_t * 5.0)) % 6 == 0
				draw_rect(Rect2(r.position.x + 5.0 + k2, r.position.y + 6.0, 1.5, 1.5), Color(1.0, 0.95, 0.7, 0.95 if on else 0.22))
		# a duct along it, on its feet
		var dy := r.position.y + 13.0 * s
		draw_rect(Rect2(r.position.x + 9.0, dy + 2.0, r.size.x - 18.0, 1.5), Color(0, 0, 0, 0.3))
		draw_rect(Rect2(r.position.x + 8.0, dy, r.size.x - 16.0, 2.5), base.lightened(0.22))
		draw_rect(Rect2(r.position.x + 8.0, dy, r.size.x - 16.0, 1.0), base.lightened(0.4))
		for ft in range(int(r.position.x) + 14, int(r.end.x) - 10, 26):
			draw_rect(Rect2(ft, dy + 2.5, 1.5, 2.0), base.darkened(0.3))
		# what stands on it, in a row of places; the highest ones carry a penthouse in the middle
		var cw := 58.0 * s
		var n := int((r.size.x - 12.0) / cw)
		var pad := (r.size.x - n * cw) * 0.5
		var ty := r.position.y + (54.0 if tier == 1 else 56.0)
		var pent := n / 2 if (lvl == 2 and n >= 3) else -1
		var last := -1
		for c in n:
			var p := Vector2(r.position.x + pad + c * cw + cw * 0.5, ty)
			if c == pent:
				_pent(p, seed, tint, s, base)
				continue
			var kind := int(_h(seed + c * 7, 1) * KINDS) % KINDS
			if kind == last or (kind >= 12 and last >= 12):
				kind = (kind + 5) % 12
			last = kind
			_thing(kind, p, seed + c * 3, tint, s)
		# on the edge that looks onto the plaza: the back of a sign, its light spilling over; a mast with a lamp
		if _h(seed, 30) < 0.6 and r.size.x > 90.0:
			var bw := minf(72.0 * s, r.size.x - 30.0)
			var bx := r.position.x + 14.0 + _h(seed, 31) * (r.size.x - bw - 28.0)
			var bh := 8.0 * s
			draw_rect(Rect2(bx, r.position.y - bh, bw, bh + 3.0), Color(0.05, 0.05, 0.09))
			for st in 4:
				draw_rect(Rect2(bx + 3.0 + st * (bw - 7.0) / 3.0, r.position.y - bh, 1.0, bh + 6.0), Color(0.3, 0.32, 0.4))
			draw_line(Vector2(bx + 3.0, r.position.y + 2.0), Vector2(bx + bw - 3.0, r.position.y - bh + 1.0), Color(0.24, 0.26, 0.34), 1.0)
			var fl := 1.0 if _h(seed, 32) > 0.3 else (0.4 + 0.6 * absf(sin(_t * 6.0 + seed)))
			draw_rect(Rect2(bx - 1.0, r.position.y - bh - 2.0, bw + 2.0, 2.0), Color(tint, 0.95 * fl))
			draw_rect(Rect2(bx - 4.0, r.position.y - bh - 6.0, bw + 8.0, 4.0), Color(tint, 0.13 * fl))
		if _h(seed, 33) < 0.65:
			var mx := r.end.x - 18.0
			draw_rect(Rect2(mx, r.position.y - 9.0 * s, 1.5, 9.0 * s + 12.0), Color(0.62, 0.64, 0.72))
			draw_rect(Rect2(mx - 3.0, r.position.y - 5.0 * s, 7.5, 1.0), Color(0.62, 0.64, 0.72))
			draw_circle(Vector2(mx + 0.75, r.position.y - 9.0 * s - 1.0), 2.0, Color(1.0, 0.2, 0.2) if int(_t * 1.1 + seed) % 2 == 0 else Color(0.4, 0.1, 0.1))

	## A penthouse on a roof: its front with lit windows, a line of neon under its top, a unit and a mast on it.
	func _pent(p: Vector2, seed: int, tint: Color, s: float, base: Color) -> void:
		draw_set_transform(p, 0.0, Vector2(s, s))
		var nightly := night > 0.5
		_box(-27.0, 27.0, 54.0, 34.0, 20.0, base.lightened(0.16), base.lightened(0.04))
		draw_rect(Rect2(-27.0, 7.0, 54.0, 1.5), Color(tint, 0.9))
		for wi in 7:
			var on := _h(seed + wi, 60) < (0.72 if nightly else 0.2)
			var wc: Color = Color(1.0, 0.9, 0.65) if wi % 3 != 0 else tint.lerp(Color(1, 1, 1), 0.4)
			draw_rect(Rect2(-24.5 + wi * 7.2, 11.0, 5.0, 12.0), Color(wc, 0.9) if on else Color(0.05, 0.06, 0.1))
			if on and nightly:
				draw_rect(Rect2(-25.5 + wi * 7.2, 27.0, 7.0, 3.0), Color(wc, 0.12))
		_box(-20.0, -6.0, 12.0, 8.0, 5.0, Color(0.44, 0.46, 0.52), Color(0.24, 0.26, 0.32))
		draw_rect(Rect2(14.0, -50.0, 1.5, 36.0), Color(0.62, 0.64, 0.72))
		draw_rect(Rect2(11.0, -40.0, 7.5, 1.0), Color(0.62, 0.64, 0.72))
		draw_rect(Rect2(12.0, -32.0, 5.5, 1.0), Color(0.62, 0.64, 0.72))
		draw_circle(Vector2(14.75, -51.0), 2.0, Color(1.0, 0.2, 0.2) if int(_t * 1.3 + seed) % 2 == 0 else Color(0.45, 0.1, 0.1))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	## One thing on a roof. What is flat lies flat, what stands shows its front.
	func _thing(kind: int, p: Vector2, seed: int, tint: Color, s: float) -> void:
		draw_set_transform(p, 0.0, Vector2(s, s))
		var nightly := night > 0.5
		var lit := 0.9 if nightly else 0.45
		var metal := Color(0.36, 0.38, 0.46) if nightly else Color(0.5, 0.52, 0.58)
		var dark := Color(0.1, 0.1, 0.15)
		var warm := Color(1.0, 0.9, 0.65)
		match kind:
			0:      # a skylight, raised: the light of the rooms below
				var glow: Color = warm if seed % 2 == 0 else tint.lerp(Color(1, 1, 1), 0.3)
				if nightly:
					draw_rect(Rect2(-24.0, -19.0, 48.0, 36.0), Color(glow, 0.07))
				_box(-20.0, 14.0, 40.0, 24.0, 4.0, dark.lightened(0.1), dark)
				draw_rect(Rect2(-18.0, -12.0, 36.0, 20.0), Color(glow, lit))
				draw_rect(Rect2(-18.0, -12.0, 36.0, 3.0), Color(1, 1, 1, 0.18))
				draw_rect(Rect2(-1.0, -12.0, 2.0, 20.0), dark)
				draw_rect(Rect2(-18.0, -3.0, 36.0, 1.5), dark)
			1:      # coolers in a row, their fans turning
				for i in 3:
					var bx := -26.0 + i * 18.0
					_box(bx, 10.0, 16.0, 11.0, 8.0, metal, metal.darkened(0.4))
					draw_rect(Rect2(bx + 2.0, 4.0, 12.0, 1.0), dark)
					draw_rect(Rect2(bx + 2.0, 6.5, 12.0, 1.0), dark)
					var c := Vector2(bx + 8.0, -3.5)
					_ell(c, 6.0, 4.0, dark)
					var a := _t * 9.0 + i * 1.3
					for bl in 2:
						var v := Vector2(cos(a + bl * PI * 0.5) * 5.5, sin(a + bl * PI * 0.5) * 3.6)
						draw_line(c - v, c + v, metal.lightened(0.3), 1.0)
			2:      # a water tower on its legs
				_ell(Vector2(4.0, 16.0), 14.0, 4.0, Color(0, 0, 0, 0.35))
				draw_rect(Rect2(-10.0, -2.0, 2.0, 17.0), dark.lightened(0.15))
				draw_rect(Rect2(8.0, -2.0, 2.0, 17.0), dark.lightened(0.15))
				draw_line(Vector2(-9.0, 0.0), Vector2(9.0, 13.0), dark.lightened(0.15), 1.0)
				draw_line(Vector2(9.0, 0.0), Vector2(-9.0, 13.0), dark.lightened(0.15), 1.0)
				var wood := Color(0.32, 0.25, 0.22) if nightly else Color(0.46, 0.36, 0.28)
				draw_rect(Rect2(-13.0, -24.0, 26.0, 23.0), wood)
				for pl in range(-10, 13, 4):
					draw_rect(Rect2(pl, -24.0, 1.0, 23.0), wood.darkened(0.25))
				draw_rect(Rect2(8.0, -24.0, 5.0, 23.0), Color(0, 0, 0, 0.3))
				draw_rect(Rect2(-13.0, -19.0, 26.0, 1.5), metal)
				draw_rect(Rect2(-13.0, -8.0, 26.0, 1.5), metal)
				draw_colored_polygon(PackedVector2Array([Vector2(-15.0, -24.0), Vector2(0.0, -34.0), Vector2(15.0, -24.0)]), Color(0.3, 0.27, 0.27))
				if nightly:
					draw_rect(Rect2(-13.0, -24.0, 1.5, 23.0), Color(tint, 0.5))
			3:      # a landing pad, its lamps blinking in turn; now and then a skiff parked on it
				draw_circle(Vector2(0.0, 2.0), 23.0, dark)
				draw_circle(Vector2.ZERO, 23.0, Color(0.22, 0.22, 0.3))
				draw_arc(Vector2.ZERO, 19.0, 0.0, TAU, 32, Color(1.0, 0.82, 0.25), 2.0)
				draw_rect(Rect2(-8.0, -9.0, 3.0, 18.0), Color(0.92, 0.92, 0.95))
				draw_rect(Rect2(5.0, -9.0, 3.0, 18.0), Color(0.92, 0.92, 0.95))
				draw_rect(Rect2(-8.0, -1.5, 16.0, 3.0), Color(0.92, 0.92, 0.95))
				for i2 in 4:
					var lp := Vector2.from_angle(PI * 0.25 + i2 * PI * 0.5) * 23.0
					draw_circle(lp, 2.0, (Color(0.3, 1.0, 0.5) if i2 % 2 == 0 else Color(1.0, 0.3, 0.3)) if (int(_t * 2.0) + i2) % 2 == 0 else Color(0.2, 0.2, 0.25))
				if seed % 3 == 0:
					var hull: Color = tint.darkened(0.35)
					draw_rect(Rect2(-12.0, 4.0, 30.0, 5.0), Color(0, 0, 0, 0.4))
					draw_rect(Rect2(-15.0, -6.0, 30.0, 9.0), hull)
					draw_rect(Rect2(-15.0, 3.0, 30.0, 3.0), hull.darkened(0.4))
					draw_rect(Rect2(-7.0, -11.0, 14.0, 6.0), Color(0.5, 0.8, 0.95, 0.85))
					draw_rect(Rect2(-7.0, -11.0, 14.0, 1.0), Color(1, 1, 1, 0.5))
					draw_circle(Vector2(-15.0, -1.0), 1.6, warm)
					draw_circle(Vector2(15.0, -1.0), 1.4, Color(1.0, 0.25, 0.2))
			4:      # a pool lit from below, loungers and a parasol beside it
				if nightly:
					draw_rect(Rect2(-29.0, -20.0, 58.0, 40.0), Color(0.3, 0.9, 1.0, 0.09))
				draw_rect(Rect2(-28.0, -18.0, 56.0, 36.0), Color(0.34, 0.32, 0.36) if nightly else Color(0.5, 0.46, 0.42))
				draw_rect(Rect2(-15.0, -14.0, 39.0, 28.0), Color(0.2, 0.82, 0.96, 0.95 if nightly else 0.8))
				draw_rect(Rect2(-15.0, -14.0, 39.0, 2.0), Color(0.05, 0.3, 0.45, 0.6))
				for wv in 3:
					draw_rect(Rect2(-11.0 + wv * 11.0 + sin(_t * 1.5 + wv) * 3.0, -8.0 + wv * 7.0, 9.0, 1.0), Color(1, 1, 1, 0.55))
				draw_circle(Vector2(-8.0, 10.0), 1.5, Color(1, 1, 1, 0.9))
				draw_circle(Vector2(16.0, 10.0), 1.5, Color(1, 1, 1, 0.9))
				draw_rect(Rect2(-26.0, -12.0, 8.0, 4.0), Color(0.95, 0.95, 0.95))
				draw_rect(Rect2(-26.0, -4.0, 8.0, 4.0), Color(0.95, 0.95, 0.95))
				draw_rect(Rect2(-22.0, 6.0, 1.0, 8.0), dark)
				_ell(Vector2(-21.5, 6.0), 6.5, 4.0, tint.darkened(0.1))
			5:      # a garden in a planter, lights strung over it
				_box(-27.0, 17.0, 54.0, 30.0, 4.0, Color(0.1, 0.24, 0.15), Color(0.3, 0.22, 0.18))
				for tr in 5:
					var tp := Vector2(-18.0 + _h(seed + tr, 40) * 36.0, -4.0 + _h(seed + tr, 41) * 13.0)
					draw_rect(Rect2(tp.x - 1.0, tp.y, 2.0, 6.0), Color(0.25, 0.18, 0.12))
					draw_circle(tp + Vector2(1.5, -2.5), 7.0, Color(0, 0, 0, 0.25))
					draw_circle(tp + Vector2(0.0, -4.0), 7.0, Color(0.14, 0.44, 0.24) if nightly else Color(0.2, 0.56, 0.3))
					draw_circle(tp + Vector2(-2.0, -6.0), 3.5, Color(0.26, 0.62, 0.34))
				for sl in 7:
					var u := sl / 6.0
					draw_circle(Vector2(lerpf(-25.0, 25.0, u), -18.0 + sin(u * PI) * 5.0), 1.2, Color(warm, lit))
			6:      # solar panels, tilted
				for py in 2:
					for px in 3:
						var o := Vector2(-26.0 + px * 18.0, -14.0 + py * 15.0)
						draw_rect(Rect2(o + Vector2(2.0, 10.0), Vector2(16.0, 3.0)), Color(0, 0, 0, 0.35))
						draw_rect(Rect2(o, Vector2(16.0, 10.0)), Color(0.08, 0.16, 0.4))
						draw_rect(Rect2(o, Vector2(16.0, 1.5)), Color(0.5, 0.66, 1.0, 0.7))
						draw_rect(Rect2(o + Vector2(7.5, 0.0), Vector2(1.0, 10.0)), Color(0.04, 0.08, 0.2))
						draw_rect(Rect2(o + Vector2(0.0, 5.0), Vector2(16.0, 1.0)), Color(0.04, 0.08, 0.2))
			7:      # a stack, steaming, a unit beside it
				_box(-9.0, 14.0, 14.0, 9.0, 20.0, metal, metal.darkened(0.4))
				draw_rect(Rect2(-11.0, -17.0, 18.0, 3.0), metal.lightened(0.15))
				draw_rect(Rect2(-9.0, 0.0, 14.0, 1.5), Color(1.0, 0.82, 0.25, 0.8))
				_box(9.0, 14.0, 13.0, 9.0, 7.0, metal.darkened(0.1), metal.darkened(0.45))
				for pf in 3:
					var ph := fposmod(_t * 0.5 + pf / 3.0 + _h(seed, 42), 1.0)
					draw_circle(Vector2(-2.0 + sin(ph * 6.0 + seed) * 4.0, -18.0 - ph * 24.0), 4.0 + ph * 7.0, Color(0.9, 0.92, 1.0, (1.0 - ph) * 0.3))
			8:      # the hut of the stairs, its door lit; a dish beside it
				_box(2.0, 14.0, 22.0, 12.0, 16.0, metal.darkened(0.25), metal.darkened(0.5))
				draw_rect(Rect2(9.0, 2.0, 8.0, 12.0), Color(warm, lit) if seed % 2 == 0 else dark)
				draw_rect(Rect2(12.0, -1.0, 2.0, 1.5), Color(tint, 0.95))
				if nightly and seed % 2 == 0:
					draw_rect(Rect2(7.0, 14.0, 12.0, 4.0), Color(warm, 0.14))
				draw_rect(Rect2(-15.0, 0.0, 2.0, 14.0), dark.lightened(0.2))
				_ell(Vector2(-14.0, -7.0), 10.0, 12.0, Color(0.52, 0.54, 0.62) if nightly else Color(0.74, 0.76, 0.82))
				_ell(Vector2(-12.5, -7.0), 6.5, 8.5, Color(0.4, 0.42, 0.5))
				draw_line(Vector2(-12.5, -7.0), Vector2(-5.0, -13.0), dark.lightened(0.3), 1.0)
				draw_circle(Vector2(-5.0, -13.0), 1.2, Color(1.0, 0.25, 0.2))
			9:      # a bar on the roof: a counter with a strip of neon, bottles behind it, lights on a line, guests
				draw_rect(Rect2(-27.0, -26.0, 1.5, 36.0), dark.lightened(0.2))
				draw_rect(Rect2(25.5, -26.0, 1.5, 36.0), dark.lightened(0.2))
				for bt in 6:
					draw_rect(Rect2(-20.0 + bt * 4.5, -23.0, 2.0, 5.0), Color(NEON[(bt + seed) % NEON.size()] as Color, 0.85))
				_box(-22.0, -4.0, 30.0, 6.0, 8.0, Color(0.3, 0.2, 0.16), Color(0.14, 0.1, 0.12))
				draw_rect(Rect2(-22.0, -11.0, 30.0, 1.5), Color(tint, 0.95))
				if nightly:
					draw_rect(Rect2(-24.0, -4.0, 34.0, 5.0), Color(tint, 0.1))
				_person(Vector2(-14.0, 6.0), Color(0.3, 0.2, 0.36))
				_person(Vector2(-2.0, 7.0), Color(0.16, 0.3, 0.36))
				draw_rect(Rect2(17.5, 6.0, 1.0, 7.0), dark)
				_ell(Vector2(18.0, 6.0), 6.0, 3.5, Color(0.42, 0.42, 0.5))
				draw_circle(Vector2(18.0, 4.5), 1.0, Color(warm, lit))
				_person(Vector2(18.0, 0.0), Color(0.4, 0.18, 0.24))
				for sl2 in 9:
					var u2 := sl2 / 8.0
					draw_circle(Vector2(lerpf(-26.0, 26.0, u2), -26.0 + sin(u2 * PI) * 5.0), 1.3, Color(NEON[sl2 % NEON.size()] as Color, lit))
			10:     # a projector: a mark of light turning over it
				_ell(Vector2(0.0, 13.0), 13.0, 5.0, dark.lightened(0.12))
				_ell(Vector2(0.0, 12.0), 9.0, 3.2, Color(tint, 0.5))
				draw_colored_polygon(PackedVector2Array([Vector2(-8.0, 12.0), Vector2(8.0, 12.0), Vector2(15.0, -30.0), Vector2(-15.0, -30.0)]), Color(tint, 0.06))
				var wq := cos(_t * 1.2 + seed)
				if absf(wq) > 0.12:
					draw_colored_polygon(PackedVector2Array([Vector2(0.0, -32.0), Vector2(11.0 * wq, -16.0), Vector2(0.0, 0.0), Vector2(-11.0 * wq, -16.0)]), Color(tint, 0.6))
				draw_line(Vector2(0.0, -32.0), Vector2(0.0, 0.0), Color(1, 1, 1, 0.7), 1.0)
				for sc in 4:
					draw_rect(Rect2(-11.0 * absf(wq), -30.0 + sc * 7.0 + fposmod(_t * 6.0, 7.0), 22.0 * absf(wq), 1.0), Color(1, 1, 1, 0.25))
			12, 13: # a billboard on its scaffold, facing south: you see its front
				var fb := 1.0 if seed % 4 != 1 else (0.55 + 0.45 * absf(sin(_t * 7.0 + seed)))
				draw_rect(Rect2(-22.0, 12.0, 50.0, 4.0), Color(0, 0, 0, 0.35))
				for lg in 4:
					draw_rect(Rect2(-22.0 + lg * 14.0, 2.0, 1.5, 12.0), dark.lightened(0.25))
				draw_line(Vector2(-22.0, 13.0), Vector2(-8.0, 3.0), dark.lightened(0.25), 1.0)
				draw_line(Vector2(20.0, 13.0), Vector2(6.0, 3.0), dark.lightened(0.25), 1.0)
				if nightly:
					draw_rect(Rect2(-30.0, -27.0, 60.0, 35.0), Color(tint, 0.08 * fb))
					draw_rect(Rect2(-22.0, 14.0, 44.0, 5.0), Color(tint, 0.1 * fb))
				draw_rect(Rect2(-26.0, -23.0, 52.0, 26.0), Color(0.04, 0.04, 0.08))
				draw_rect(Rect2(-25.0, -22.0, 50.0, 24.0), Color(tint, 0.18 * fb))
				draw_rect(Rect2(-26.0, -23.0, 52.0, 26.0), Color(tint, 0.95 * fb), false, 1.5)
				draw_string(ThemeDB.fallback_font, Vector2(-25.0, -8.0), BOARDS[(seed + kind) % BOARDS.size()], HORIZONTAL_ALIGNMENT_CENTER, 50.0, 8, Color(tint.lerp(Color(1, 1, 1), 0.55), fb))
				draw_rect(Rect2(-14.0, -4.0, 28.0, 1.5), Color(1, 1, 1, 0.5 * fb))
				for bd in 6:
					draw_rect(Rect2(-22.0 + bd * 8.6, -1.0, 2.0, 2.0), Color(1.0, 0.95, 0.7, 0.9 if (bd + int(_t * 3.0)) % 3 == 0 else 0.25))
			_:      # a greenhouse, lit
				draw_rect(Rect2(-23.0, -14.0, 46.0, 29.0), Color(0.06, 0.1, 0.1))
				_box(-23.0, 15.0, 46.0, 18.0, 11.0, Color(0.5, 0.8, 0.7, 0.45), Color(0.4, 0.7, 0.6, 0.4))
				draw_rect(Rect2(-22.0, -13.0, 44.0, 27.0), Color(warm if seed % 2 == 0 else Color(0.8, 0.5, 1.0), lit * 0.3))
				for gb in 6:
					draw_circle(Vector2(-18.0 + gb * 7.2, 9.0 + (gb % 2) * 2.0), 3.5, Color(0.16, 0.5, 0.26))
					draw_circle(Vector2(-16.0 + gb * 7.2, -5.0), 3.0, Color(0.2, 0.56, 0.3))
				for gl in range(-23, 24, 9):
					draw_rect(Rect2(gl, -14.0, 1.0, 29.0), Color(0.85, 0.9, 0.95, 0.7))
				draw_rect(Rect2(-23.0, 4.0, 46.0, 1.0), Color(0.85, 0.9, 0.95, 0.8))
				draw_rect(Rect2(-23.0, -14.0, 46.0, 1.0), Color(0.85, 0.9, 0.95, 0.8))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	## The street to the back alleys goes on between the two buildings, where you cannot walk any more: darker the
	## deeper it runs, pools of neon on its floor, small signs out from both walls, a vent steaming; the walls shade it.
	func _alley() -> void:
		var tl := float(GroundMap.TILE)
		var x0 := gap.position.x
		var x1 := gap.end.x
		var ya := gap.position.y + 5.0 * tl               # the street you can walk ends here
		var deep := bottom - ya
		for k in 8:
			draw_rect(Rect2(x0, ya + deep * k / 8.0, x1 - x0, deep / 8.0 + 1.0), Color(0.02, 0.02, 0.06, 0.35 + 0.5 * k / 7.0))
		for k3 in 4:
			draw_rect(Rect2(x0 + k3 * 2.5, gap.position.y, 2.5, bottom - gap.position.y), Color(0, 0, 0, 0.3 - 0.07 * k3))
			draw_rect(Rect2(x1 - (k3 + 1) * 2.5, gap.position.y, 2.5, bottom - gap.position.y), Color(0, 0, 0, 0.3 - 0.07 * k3))
		for sg in 6:
			var west := sg % 2 == 0
			var sy := ya + 8.0 + sg * (deep - 20.0) / 6.0
			var col: Color = NEON[(sg * 2 + 1) % NEON.size()]
			var fl := 1.0 if sg % 3 != 1 else (0.35 + 0.65 * absf(sin(_t * 5.0 + sg)))
			var sx := x0 + 2.0 if west else x1 - 26.0
			draw_rect(Rect2(sx - 5.0, sy - 5.0, 34.0, 17.0), Color(col, 0.1 * fl))            # its light on the floor
			draw_rect(Rect2(sx, sy, 24.0, 7.0), Color(0.04, 0.04, 0.08))
			draw_rect(Rect2(sx, sy, 24.0, 7.0), Color(col, 0.9 * fl), false, 1.0)
			draw_string(ThemeDB.fallback_font, Vector2(sx + 2.0, sy + 6.0), ALLEY[sg % ALLEY.size()], HORIZONTAL_ALIGNMENT_CENTER, 20.0, 5, Color(col, fl))
		for pf in 3:
			var ph := fposmod(_t * 0.4 + pf / 3.0, 1.0)
			draw_circle(Vector2(x0 + 30.0 + sin(ph * 5.0) * 4.0, ya + deep * 0.55 - ph * 22.0), 4.0 + ph * 8.0, Color(0.9, 0.92, 1.0, (1.0 - ph) * 0.22))

	## Over the street: a line of neon down each wall, lanterns on lines strung from roof to roof, swaying a little.
	func _lanterns() -> void:
		var x0 := gap.position.x
		var x1 := gap.end.x
		var deep := bottom - gap.position.y
		draw_rect(Rect2(x0 - 1.0, gap.position.y, 2.0, deep), Color(0.55, 1.0, 0.6, 0.8))
		draw_rect(Rect2(x1 - 1.0, gap.position.y, 2.0, deep), Color(1.0, 0.36, 0.66, 0.8))
		var n := int(deep / 30.0)
		for ln in n:
			var ly := gap.position.y + 9.0 + ln * 30.0
			var pts := PackedVector2Array()
			for k in 9:
				var u := k / 8.0
				pts.append(Vector2(lerpf(x0, x1, u), ly + sin(u * PI) * (6.0 + sin(_t * 1.1 + ln) * 1.2)))
			draw_polyline(pts, Color(0.1, 0.1, 0.14), 1.0)
			for k2 in range(1, 8):
				var lc: Color = NEON[(k2 + ln) % NEON.size()]
				draw_circle(pts[k2] + Vector2(0.0, 2.0), 4.0, Color(lc, 0.16))
				draw_circle(pts[k2] + Vector2(0.0, 2.0), 1.8, lc)

	## (Luz) the sign of the back alleys hangs on a gate across the mouth of the street: a post at either wall, a beam,
	## the board in neon on it, a paper lantern either side under it.
	func _gate() -> void:
		var x0 := gap.position.x
		var x1 := gap.end.x
		var mx := (x0 + x1) * 0.5
		var gy := gap.position.y + 7.0
		var green := Color(0.55, 1.0, 0.6)
		var pink := Color(1.0, 0.36, 0.66)
		var steel := Color(0.2, 0.21, 0.3)
		var fl := 0.8 + 0.2 * sin(_t * 2.3)
		for s in 2:
			var px := x0 + 2.0 if s == 0 else x1 - 8.0
			draw_rect(Rect2(px + 2.0, gy - 1.0, 7.0, 3.0), Color(0, 0, 0, 0.35))
			draw_rect(Rect2(px - 1.0, gy - 3.0, 8.0, 3.0), steel.lightened(0.15))
			draw_rect(Rect2(px, gy - 40.0, 6.0, 38.0), steel)
			draw_rect(Rect2(px, gy - 40.0, 1.5, 38.0), steel.lightened(0.3))
			draw_rect(Rect2(px + 2.5, gy - 34.0, 1.5, 28.0), Color(green if s == 0 else pink, 0.95))
		draw_rect(Rect2(x0 + 1.0, gy - 46.0, x1 - x0 - 2.0, 6.0), steel)
		draw_rect(Rect2(x0 + 1.0, gy - 46.0, x1 - x0 - 2.0, 1.0), steel.lightened(0.35))
		for tr in range(int(x0) + 6, int(x1) - 6, 8):
			draw_line(Vector2(tr, gy - 41.0), Vector2(tr + 4.0, gy - 45.0), steel.lightened(0.2), 1.0)
		var br := Rect2(mx - 40.0, gy - 66.0, 80.0, 18.0)
		draw_rect(Rect2(mx - 26.0, gy - 48.0, 2.0, 3.0), steel.lightened(0.2))
		draw_rect(Rect2(mx + 24.0, gy - 48.0, 2.0, 3.0), steel.lightened(0.2))
		if night > 0.5:
			draw_rect(br.grow(5.0), Color(green, 0.08 * fl))
		draw_rect(br, Color(0.03, 0.04, 0.06))
		draw_rect(br.grow(-1.5), Color(green, 0.95 * fl), false, 1.5)
		draw_string(ThemeDB.fallback_font, Vector2(br.position.x, br.position.y + 13.0), "BACK ALLEYS", HORIZONTAL_ALIGNMENT_CENTER, br.size.x, 10, Color(green.lerp(Color(1, 1, 1), 0.45), fl))
		for s2 in 2:
			var lx := mx - 30.0 if s2 == 0 else mx + 30.0
			var sway := sin(_t * 1.3 + s2 * 2.0)
			draw_line(Vector2(lx, gy - 40.0), Vector2(lx + sway, gy - 35.0), steel.lightened(0.2), 1.0)
			draw_circle(Vector2(lx + sway, gy - 31.0), 7.0, Color(1.0, 0.3, 0.2, 0.14))
			draw_rect(Rect2(lx + sway - 3.0, gy - 35.0, 6.0, 8.0), Color(0.95, 0.25, 0.2))
			draw_rect(Rect2(lx + sway - 3.0, gy - 35.0, 6.0, 1.0), Color(0.2, 0.1, 0.1))
			draw_rect(Rect2(lx + sway - 3.0, gy - 28.0, 6.0, 1.0), Color(0.2, 0.1, 0.1))
			draw_rect(Rect2(lx + sway - 1.0, gy - 33.0, 2.0, 4.0), Color(1.0, 0.85, 0.5))

	## Small craft over the roofs: a hull, a white lamp ahead, a red one behind.
	func _drones() -> void:
		var span := gap.get_center().x * 2.0 + 840.0
		for i in 6:
			var dir := 1.0 if i % 2 == 0 else -1.0
			var u := fposmod(i * 540.0 + _t * (26.0 + i * 8.0), span)
			var p := Vector2((u if dir > 0.0 else span - u) - 420.0, line - 80.0 + i * 26.0 + sin(_t * 0.8 + i) * 4.0)
			draw_rect(Rect2(p + Vector2(3.0, 7.0), Vector2(9.0, 3.0)), Color(0, 0, 0, 0.3))
			draw_rect(Rect2(p - Vector2(4.5, 2.0), Vector2(9.0, 4.0)), Color(0.22, 0.24, 0.32))
			draw_circle(p + Vector2(dir * 5.0, 0.0), 1.5, Color(1.0, 0.97, 0.8))
			draw_circle(p - Vector2(dir * 5.0, 0.0), 1.2, Color(1.0, 0.25, 0.2) if int(_t * 3.0 + i) % 2 == 0 else Color(0.4, 0.1, 0.1))


## (Luz) the way down to the station on the plaza, drawn: a pit of lit steps going down north to the mouth of the
## tunnel, a rail down its middle, a low wall with a strip of light either side, a band for the blind before it; at
## its far end a wall with the board of the line (the next train in seconds, a ticker) between two pylons that carry
## the mark of the metro; a lamp on a post at the end of each low wall. Three parts: "floor" lies under the people,
## "wall" and "posts" stand among them (sorted by where they stand). Art px, the north-west corner of its six by
## three tiles at 0, 0; a part draws from its own line (base) upward.
class MetroFx extends Node2D:
	const Gen = preload("res://scripts/ground/centauria_gen.gd")
	const W := 96.0
	const TICK := "COMMERCIAL DISTRICT  ·  MIND THE STEPS  ·  LINE B TO THE COLOSSEUM FROM CENTRAL  ·  "
	var part := "floor"
	var base := 0.0                  # the line it stands on (art px below the corner)
	var line := "A"
	var stop := 1
	var night := 0.0
	var _t := 0.0
	var _acc := 0.0

	func _process(dt: float) -> void:
		_t += dt
		_acc += dt
		if _acc > 0.1:
			_acc = 0.0
			queue_redraw()

	func _draw() -> void:
		draw_set_transform(Vector2(0.0, -base), 0.0, Vector2.ONE)
		match part:
			"floor":
				_floor()
			"wall":
				_wall()
			_:
				_posts()
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	func _floor() -> void:
		var lc: Color = Gen.LINES[line]["col"]
		var nightly := night > 0.5
		var stone := Color(0.56, 0.57, 0.66) if nightly else Color(0.82, 0.83, 0.88)
		# a band for the blind before the steps, two arrows of light in the floor: in on the left, out on the right
		draw_rect(Rect2(16.0, 50.0, 64.0, 5.0), Color(0.95, 0.78, 0.22, 0.9))
		for dt2 in range(17, 80, 4):
			draw_rect(Rect2(dt2, 51.0, 2.0, 1.0), Color(0.55, 0.42, 0.08))
			draw_rect(Rect2(dt2, 53.0, 2.0, 1.0), Color(0.55, 0.42, 0.08))
		var blink := 0.55 + 0.45 * sin(_t * 3.0)
		draw_colored_polygon(PackedVector2Array([Vector2(32.0, 57.0), Vector2(37.0, 63.0), Vector2(27.0, 63.0)]), Color(0.45, 1.0, 0.6, 0.9 * blink))
		draw_colored_polygon(PackedVector2Array([Vector2(64.0, 63.0), Vector2(69.0, 57.0), Vector2(59.0, 57.0)]), Color(lc, 0.5))
		# the pit: eight steps down to the north, each nosing lit, darker the deeper; the light of the tunnel at its foot
		draw_rect(Rect2(14.0, 14.0, 68.0, 35.0), Color(0.04, 0.04, 0.08))
		for i in 8:
			var deep := i / 7.0
			var y := 44.0 - i * 4.0
			draw_rect(Rect2(16.0, y, 64.0, 4.0), stone.lerp(Color(0.07, 0.07, 0.13), 0.15 + deep * 0.75))
			draw_rect(Rect2(16.0, y, 64.0, 1.0), Color(1, 1, 1, 0.12 * (1.0 - deep)))
			draw_rect(Rect2(16.0, y + 3.0, 64.0, 1.0), Color(lc.lerp(Color(1, 1, 1), 0.25), 0.85 - deep * 0.5))
		draw_rect(Rect2(16.0, 16.0, 64.0, 6.0), Color(1.0, 0.9, 0.65, 0.3))
		draw_rect(Rect2(16.0, 22.0, 64.0, 5.0), Color(1.0, 0.9, 0.65, 0.12))
		draw_rect(Rect2(16.0, 16.0, 3.0, 32.0), Color(0, 0, 0, 0.35))
		draw_rect(Rect2(77.0, 16.0, 3.0, 32.0), Color(0, 0, 0, 0.35))
		# the rail down the middle
		draw_rect(Rect2(47.0, 18.0, 2.0, 31.0), Color(0.8, 0.82, 0.88))
		draw_rect(Rect2(47.0, 18.0, 1.0, 31.0), Color(1, 1, 1, 0.6))
		for rp in 4:
			draw_rect(Rect2(46.5, 20.0 + rp * 9.0, 3.0, 2.0), Color(0.3, 0.32, 0.4))
		# a low wall either side: its top, a strip of light let into it, its end towards you
		for s in 2:
			var wx := 2.0 if s == 0 else 82.0
			draw_rect(Rect2(wx + 2.0, 53.0, 12.0, 4.0), Color(0, 0, 0, 0.3))
			draw_rect(Rect2(wx, 14.0, 12.0, 34.0), stone)
			draw_rect(Rect2(wx, 14.0, 12.0, 1.0), stone.lightened(0.3))
			draw_rect(Rect2(wx + (11.0 if s == 0 else 0.0), 14.0, 1.0, 34.0), stone.darkened(0.4))
			draw_rect(Rect2(wx + 3.0, 16.0, 6.0, 30.0), Color(lc, 0.14))
			draw_rect(Rect2(wx + 5.0, 17.0, 2.0, 28.0), Color(lc, 0.95))
			draw_rect(Rect2(wx, 48.0, 12.0, 7.0), stone.darkened(0.3))
			draw_rect(Rect2(wx, 48.0, 12.0, 1.0), stone.lightened(0.2))
			draw_rect(Rect2(wx + 3.0, 51.0, 6.0, 2.0), Color(0.3, 0.9, 1.0, 0.9))

	func _wall() -> void:
		var lc: Color = Gen.LINES[line]["col"]
		var nightly := night > 0.5
		var cyan := Color(0.3, 0.9, 1.0)
		var font := ThemeDB.fallback_font
		var body := Color(0.1, 0.11, 0.18) if nightly else Color(0.2, 0.22, 0.3)
		var steel := Color(0.62, 0.64, 0.72)
		# its shade into the pit
		draw_rect(Rect2(16.0, 16.0, 64.0, 4.0), Color(0, 0, 0, 0.5))
		# the wall between the pylons: the board, a lintel with lamps over the mouth of the tunnel
		draw_rect(Rect2(12.0, -22.0, 72.0, 38.0), body)
		draw_rect(Rect2(11.0, -25.0, 74.0, 3.0), steel)
		draw_rect(Rect2(11.0, -25.0, 74.0, 1.0), Color(1, 1, 1, 0.5))
		if nightly:
			draw_rect(Rect2(10.0, -22.0, 76.0, 30.0), Color(cyan, 0.06))
		draw_rect(Rect2(14.0, -20.0, 68.0, 27.0), Color(0.02, 0.03, 0.07))
		draw_rect(Rect2(14.0, -20.0, 68.0, 27.0), Color(cyan, 0.85), false, 1.0)
		# the line: its badge and name; where to, and the next train in seconds
		draw_rect(Rect2(16.5, -18.0, 9.0, 8.0), lc)
		draw_string(font, Vector2(16.5, -11.5), line, HORIZONTAL_ALIGNMENT_CENTER, 9.0, 7, Color(0.06, 0.03, 0.06))
		draw_string(font, Vector2(28.0, -11.5), String(Gen.LINES[line]["name"]), HORIZONTAL_ALIGNMENT_LEFT, 34.0, 7, Color(1, 1, 1))
		draw_circle(Vector2(76.0, -14.0), 2.0, Color(0.45, 1.0, 0.6, 0.4 + 0.6 * absf(sin(_t * 2.0))))
		draw_rect(Rect2(16.0, -9.0, 64.0, 1.0), Color(cyan, 0.35))
		var left := Gen.next_at(line, stop, GameState.play_time)
		draw_string(font, Vector2(17.0, -2.0), "CENTRAL", HORIZONTAL_ALIGNMENT_LEFT, 40.0, 6, Color(0.75, 0.95, 1.0))
		if left <= 0.0:
			draw_string(font, Vector2(52.0, -2.0), "NOW", HORIZONTAL_ALIGNMENT_RIGHT, 27.0, 6, Color(0.45, 1.0, 0.6, 0.5 + 0.5 * absf(sin(_t * 4.0))))
		else:
			draw_string(font, Vector2(52.0, -2.0), "%d s" % int(ceil(left)), HORIZONTAL_ALIGNMENT_RIGHT, 27.0, 6, Color(1.0, 0.8, 0.3))
		draw_rect(Rect2(16.0, 0.0, 64.0, 1.0), Color(cyan, 0.35))
		var off := int(_t * 4.0) % TICK.length()
		draw_string(font, Vector2(17.0, 5.5), (TICK + TICK).substr(off, 22), HORIZONTAL_ALIGNMENT_LEFT, 62.0, 5, Color(0.45, 1.0, 0.7))
		draw_rect(Rect2(12.0, 9.0, 72.0, 7.0), body.darkened(0.3))
		draw_rect(Rect2(16.0, 14.0, 64.0, 2.0), Color(1.0, 0.9, 0.65, 0.85))
		for dl in 8:
			draw_rect(Rect2(19.0 + dl * 8.4, 11.0, 3.0, 2.0), Color(1.0, 0.95, 0.8))
		# the pylons, the mark of the metro on each
		for s in 2:
			var px := 0.0 if s == 0 else 84.0
			draw_rect(Rect2(px + 2.0, 14.0, 12.0, 4.0), Color(0, 0, 0, 0.35))
			draw_rect(Rect2(px, -36.0, 12.0, 52.0), body.lightened(0.06))
			draw_rect(Rect2(px, -36.0, 2.0, 52.0), body.lightened(0.3))
			draw_rect(Rect2(px + 10.0, -36.0, 2.0, 52.0), body.darkened(0.4))
			draw_rect(Rect2(px + 3.0, -26.0, 6.0, 38.0), Color(cyan, 0.12))
			draw_rect(Rect2(px + 5.0, -24.0, 2.0, 34.0), Color(cyan, 0.95))
			draw_rect(Rect2(px - 1.0, -38.0, 14.0, 3.0), steel)
			var mc := Vector2(px + 6.0, -47.0)
			if nightly:
				draw_circle(mc, 12.0, Color(cyan, 0.12))
			draw_rect(Rect2(px + 5.0, -40.0, 2.0, 3.0), steel)
			draw_circle(mc, 8.5, Color(0.03, 0.04, 0.08))
			draw_circle(mc, 7.5, cyan)
			draw_circle(mc, 5.6, Color(0.04, 0.08, 0.16))
			draw_string(font, Vector2(px + 1.0, -44.0), "M", HORIZONTAL_ALIGNMENT_CENTER, 10.0, 8, Color(1, 1, 1))

	func _posts() -> void:
		var lc: Color = Gen.LINES[line]["col"]
		var steel := Color(0.62, 0.64, 0.72)
		for s in 2:
			var px := 8.0 if s == 0 else 88.0
			var col: Color = Color(0.45, 1.0, 0.6) if s == 0 else lc
			draw_rect(Rect2(px - 3.0, 49.0, 6.0, 3.0), steel.darkened(0.35))
			draw_rect(Rect2(px - 1.5, 41.0, 3.0, 9.0), steel)
			if night > 0.5:
				draw_circle(Vector2(px, 37.0), 10.0, Color(col, 0.13))
			draw_rect(Rect2(px - 4.5, 31.5, 9.0, 10.0), Color(0.05, 0.06, 0.1))
			draw_rect(Rect2(px - 3.5, 32.5, 7.0, 8.0), col)
			draw_rect(Rect2(px - 3.5, 32.5, 7.0, 2.0), Color(1, 1, 1, 0.45))


## The Commercial Hall from inside (Luz): a great gallery under a vault of glass, as its front on the plaza promises.
## Along the north wall the city's shops as real fronts (the services a city's street has; shuttered fronts where
## special shops move in later), two galleries over them and the vault (all drawn: HallFx, HallSky). The lifts to the
## Hall's other floors at the west end, the escalators up to the galleries at the east end (closed for now), the
## doors out onto the plaza in the middle of the south wall. In the middle a fountain with a hologram of Lapis over
## it, kiosks, benches, palms; a food court south-west, two pavilions to let south-east.
const HW := 74
const HH := 30
const H_F0 := 13                   # the floor's first row (north of it the wall: fronts, galleries, vault)
const H_F1 := 26                   # its last row
const H_X0 := 9                    # the shop fronts begin here (west of it the lifts) …
const H_X1 := 59                   # … and end here (east of it the escalators)

static func build_hall(station: Dictionary, available: Dictionary) -> GroundMap:
	var m := GroundMap.new()
	MuseumGen._pal(m, {})
	m.pal["floor"] = Color(0.66, 0.62, 0.58)
	m.pal["floor2"] = Color(0.54, 0.49, 0.47)
	m.pal["wall"] = Color(0.3, 0.24, 0.24)
	m.pal["frame"] = Color(0.3, 0.24, 0.24)
	m.pal["accent"] = Color(1.0, 0.6, 0.25)
	m.style = "plaza"
	m.title = "Centauria"
	m.hull_top = -9999
	m.set_meta("few_guards", true)
	m.set_meta("no_guards", true)
	m.setup(HW, HH)
	var PINK := Color(1.0, 0.36, 0.66)
	var CYAN := Color(0.3, 0.9, 1.0)
	var GOLD := Color(1.0, 0.82, 0.35)
	var GREEN := Color(0.35, 1.0, 0.55)
	var PURPLE := Color(0.72, 0.36, 1.0)
	var ORANGE := Color(1.0, 0.6, 0.25)
	var cols := [PINK, CYAN, GOLD, GREEN, PURPLE, ORANGE]
	var rng := RandomNumberGenerator.new()
	rng.seed = 6113
	m.fill(0, 0, HW, HH, T.CAP)
	m.fill(H_X0, 0, HW - H_X0, H_F0, T.BLOCK, 30)                  # the north wall: drawn over (HallFx)
	m.fill(1, H_F0, HW - 2, H_F1 - H_F0 + 1, T.FLOOR, 30)
	# ---- west: the lifts to the Hall's other floors
	m.fill(1, H_F0 - 2, H_X0 - 2, 2, T.FACE)
	for lx0 in [2, 5]:
		m.face_deco.append({"kind": "lift", "x": lx0, "y": H_F0 - 1, "w": 2, "col": Color(0.4, 1.0, 0.6)})
		m.lifts.append({"x": lx0, "y": H_F0 - 1, "w": 2})
	m.decals.append({"kind": "mat", "x": 1, "y": H_F0, "w": 7, "h": 1, "col": m.pal["accent"]})
	m.zones.append({"rect": Rect2(Vector2(1, H_F0) * TILE, Vector2(7, 1.4) * TILE), "kind": "lift", "id": "lift", "title": "Lifts", "col": Color(0.4, 1.0, 0.6),
		"sign": Vector2(-100, -100)})
	m.lights.append({"pos": Vector2(4.5, H_F0 + 0.5) * TILE, "r": 60.0, "col": Color(0.4, 1.0, 0.6), "a": 0.35})
	# a row of terminals by the lifts: the dock office's and the kiosks'
	var tx := 2
	for k in DeckGen.KIOSKS + DeckGen.DOCK_TERMINALS:
		if available.has(k) and not k in DeckGen.HANGAR_SERVICES and tx < 8:
			m.add_object({"kind": "terminal", "x": tx, "y": H_F0 + 5, "w": 1, "h": 1, "col": DeckGen._svc_col(k), "icon": DeckGen._svc_icon(k)})
			DeckGen._zone(m, k, available, Rect2(Vector2(tx - 0.1, H_F0 + 3.7) * TILE, Vector2(1.2, 1.5) * TILE), Vector2(-100, -100))
			m.lights.append({"pos": Vector2(tx + 0.5, H_F0 + 4.8) * TILE, "r": 18.0, "col": DeckGen._svc_col(k), "a": 0.3})
			tx += 1
	# ---- north: the shops, a door each (the fronts themselves are drawn)
	var shops: Array = []
	for sid in DeckGen.SHOPS:
		if available.has(sid) and not sid in DeckGen.HANGAR_SERVICES and not (sid == "look" and available.has("clinic")):
			shops.append(sid)
	var fronts: Array = []
	var nf := maxi(5, shops.size())
	var fw := float(H_X1 - H_X0) / nf
	for i in nf:
		var fx := H_X0 + i * fw
		var dxc := fx + fw * 0.5
		var id := String(shops[i]) if i < shops.size() else ""
		var col: Color = DeckGen._svc_col(id) if id != "" else Color(0.6, 0.6, 0.7)
		var shut := true
		var title := ""
		if id != "":
			DeckGen._zone(m, id, available, Rect2(Vector2(dxc - 1.5, H_F0 - 0.3) * TILE, Vector2(3.0, 1.7) * TILE), Vector2(-100, -100))
			m.lights.append({"pos": Vector2(dxc, H_F0 + 0.4) * TILE, "r": 46.0, "col": col, "a": 0.4})
			shut = String(available.get(id, "")) != ""
			title = String(DeckGen._svc(id).get("title", id))
		else:
			_zone(m, Rect2(dxc - 1.5, H_F0 - 0.3, 3.0, 1.7), "ctr_closed", "A shop to let", Color(0.6, 0.6, 0.7),
				{"closed": "Opening soon. The shutters are down.", "id": "hall_soon_%d" % i})
		fronts.append({"x": fx * TILE, "w": fw * TILE, "id": id, "title": title, "col": col, "shut": shut, "seed": 700 + i * 13})
	m.set_meta("hall_fronts", fronts)
	# ---- east: the escalators up to the galleries (later)
	m.fill(H_X1 + 1, H_F0, 5, 1, T.BLOCK, 30)
	_zone(m, Rect2(H_X1 + 1.0, H_F0 + 1.0, 5.0, 1.4), "ctr_closed", "The escalators: up to the galleries", CYAN, {"closed": "The galleries open later.", "id": "hall_up"})
	# ---- south: the doors out onto the plaza
	var dx0 := HW / 2 - 3
	m.fill(dx0, H_F1 + 1, 6, 2, T.FLOOR, 30)
	m.decals.append({"kind": "mat", "x": dx0, "y": H_F1 + 1, "w": 6, "h": 1, "col": ORANGE})
	m.zones.append({"rect": Rect2(Vector2(dx0, H_F1 + 1.2) * TILE, Vector2(6, 1.7) * TILE), "kind": "museum_go", "id": "hall_out", "to": "zplaza", "at": "from_hall",
		"title": "Out onto the plaza of the Commercial District", "col": ORANGE, "sign": Vector2(-100, -100)})
	m.lights.append({"pos": Vector2(dx0 + 3.0, H_F1 + 1.5) * TILE, "r": 80.0, "col": ORANGE, "a": 0.45})
	m.set_meta("from_plaza", Vector2(dx0 + 3.0, H_F1 + 0.2) * TILE)
	m.spawn = m.get_meta("from_plaza")
	# ---- the middle: a fountain, the hologram of Lapis over it; kiosks, benches, palms, pillars of light
	var mid := HW / 2
	m.add_object({"kind": "fountain", "x": mid - 2, "y": H_F0 + 5, "w": 4, "h": 2})
	m.fill(mid - 2, H_F0 + 5, 4, 2, T.BLOCK)
	m.lights.append({"pos": Vector2(mid, H_F0 + 5.5) * TILE, "r": 110.0, "col": CYAN, "a": 0.5})
	m.set_meta("hall_holo", Vector2(mid, H_F0 + 7.0) * TILE)
	var n := 0
	for sx in [mid - 16, mid - 12, mid + 10, mid + 14]:
		m.add_object({"kind": "stall", "x": sx, "y": H_F0 + 4, "w": 2, "h": 1, "col": cols[n % cols.size()]})
		m.people.append({"pos": Vector2(sx + 1.0, H_F0 + 3.8) * TILE, "dir": 0, "role": "keeper"})
		m.lights.append({"pos": Vector2(sx + 1.0, H_F0 + 4.6) * TILE, "r": 34.0, "col": cols[n % cols.size()], "a": 0.5})
		n += 1
	for bn in [Vector2i(mid - 8, H_F0 + 3), Vector2i(mid + 5, H_F0 + 3), Vector2i(mid - 8, H_F0 + 9), Vector2i(mid + 5, H_F0 + 9)]:
		m.add_object({"kind": "bench", "x": bn.x, "y": bn.y, "w": 3, "h": 1, "face": 0}, false)
	for pp in [Vector2i(H_X0 + 3, H_F0 + 4), Vector2i(H_X1 - 4, H_F0 + 4), Vector2i(mid - 7, H_F0 + 12), Vector2i(mid + 5, H_F0 + 12)]:
		m.add_object({"kind": "planter", "x": pp.x, "y": pp.y, "w": 3, "h": 1, "col": Color(0.4, 0.36, 0.42)})
		m.add_object({"kind": "palm", "x": pp.x, "y": pp.y - 1, "w": 3, "h": 1, "rise": 56, "seed": pp.x % 8}, false)
	var pi := 0
	for hp in [Vector2i(H_X0 + 9, H_F0 + 2), Vector2i(H_X1 - 10, H_F0 + 2), Vector2i(mid - 5, H_F0 + 2), Vector2i(mid + 4, H_F0 + 2), Vector2i(HW - 4, H_F0 + 7)]:
		m.add_object({"kind": "holo_pillar", "x": hp.x, "y": hp.y, "w": 1, "h": 1, "col": cols[(pi + 2) % cols.size()]})
		m.lights.append({"pos": Vector2(hp.x + 0.5, hp.y) * TILE, "r": 64.0, "col": cols[(pi + 2) % cols.size()], "a": 0.45})
		pi += 1
	# ---- south-west: the food court: three counters, tables before them
	for fk in 3:
		var fsx: int = H_X0 + 2 + fk * 5
		m.add_object({"kind": "stall", "x": fsx, "y": H_F0 + 8, "w": 2, "h": 1, "col": cols[(fk * 2 + 5) % cols.size()]})
		m.people.append({"pos": Vector2(fsx + 1.0, H_F0 + 7.8) * TILE, "dir": 0, "role": "keeper"})
		m.lights.append({"pos": Vector2(fsx + 1.0, H_F0 + 8.6) * TILE, "r": 34.0, "col": cols[(fk * 2 + 5) % cols.size()], "a": 0.5})
	for ti in 8:
		var ttx := H_X0 + 1 + (ti % 4) * 5
		var tty := H_F0 + 10 + (ti / 4) * 3
		m.add_object({"kind": "round_table", "x": ttx + 1, "y": tty, "w": 1, "h": 1})
		DeckGen._seat(m, "chair", ttx, tty, 3, cols[ti % cols.size()].darkened(0.3), rng, 0.65)
		DeckGen._seat(m, "chair", ttx + 2, tty, 2, cols[ti % cols.size()].darkened(0.3), rng, 0.65)
	# ---- south-east: two pavilions to let (drawn), a sign before each
	var pavs: Array = []
	for pv in 2:
		var pvx := mid + 8 + pv * 10
		m.fill(pvx, H_F0 + 9, 8, 2, T.BLOCK, 30)
		if pv == 0 and available.has("paint"):
			# package 61d (Luz): Second Skin, paint for your ships – an open showroom, somebody before it
			pavs.append({"at": Vector2(pvx, H_F0 + 11) * TILE, "col": CYAN, "seed": 880, "shop": "SECOND SKIN"})
			DeckGen._zone(m, "paint", available, Rect2(Vector2(pvx + 2.5, H_F0 + 11.0) * TILE, Vector2(3.0, 1.4) * TILE), Vector2(-100, -100))
			m.people.append({"pos": Vector2(pvx + 6.6, H_F0 + 11.5) * TILE, "dir": 0, "role": "keeper"})
			m.lights.append({"pos": Vector2(pvx + 4.0, H_F0 + 11.4) * TILE, "r": 70.0, "col": Color(1.0, 0.95, 0.85), "a": 0.45})
			continue
		pavs.append({"at": Vector2(pvx, H_F0 + 11) * TILE, "col": cols[(pv * 3 + 1) % cols.size()], "seed": 880 + pv * 7})
		_zone(m, Rect2(pvx + 2.5, H_F0 + 11.0, 3.0, 1.4), "ctr_closed", "A shop to let", cols[(pv * 3 + 1) % cols.size()],
			{"closed": "Opening soon. Special shops will move in here.", "id": "hall_pav_%d" % pv})
	m.set_meta("hall_pavs", pavs)
	m.set_meta("tourists", 30)
	DeckGen._seats(m)
	for gx in range(4, HW - 3, 6):
		for gy in [H_F0 + 2, H_F0 + 7, H_F0 + 12]:
			var wp := Vector2(gx, gy)
			if m.free_at(wp * TILE, 6.0):
				m.wander.append(wp * TILE)
	return m


## (Luz) the sky over the Hall, seen through its vault of glass: day or night, Lapis with its rings (a Control: it
## cuts the picture off at its own edge).
class HallSky extends Control:
	const Gen = preload("res://scripts/ground/centauria_gen.gd")
	var night := 0.0
	var _t := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		clip_contents = true

	func _process(dt: float) -> void:
		_t += dt
		if int(_t * 4.0) != int((_t - dt) * 4.0):
			queue_redraw()

	func _draw() -> void:
		Gen.draw_sky(self, Rect2(0, 0, size.x, size.y), night, size.x * 0.64, size.y * 0.52, size.y * 0.3, _t)


## The Hall's inside, drawn (art px). "wall": the north wall from the floor up: the shop fronts (each service its
## name, its windows full of goods, a door of glass; shutters where a shop is to let), over them two galleries (shop
## windows at their back, people walking behind rails of glass, banners), pillars up to a cornice of lamps, the ribs of
## the vault, lights on lines; at the east end the escalators. It lies under the people. "pav" (a pavilion to let)
## and "holo" (Lapis turning over the fountain) stand among them, drawn from their own line upward.
class HallFx extends Node2D:
	const Gen = preload("res://scripts/ground/centauria_gen.gd")
	const NEON := [Color(1.0, 0.36, 0.66), Color(0.3, 0.9, 1.0), Color(1.0, 0.82, 0.25), Color(0.55, 1.0, 0.6), Color(0.72, 0.5, 1.0), Color(1.0, 0.55, 0.25)]
	const NAMES := ["NOODLES", "ARCADE", "RAMEN", "TATTOO", "KARAOKE", "SUSHI", "BOOKS", "TEA", "VINYL", "FLOWERS", "24H", "DUMPLINGS", "SHOES", "HATS", "TOYS", "OPTICS"]
	const Paints = preload("res://data/paints.gd")
	var part := "wall"
	var fronts: Array = []
	var night := 0.0
	var col := Color(1.0, 0.36, 0.66)
	var shop := ""                   # a pavilion with a shop in it: its name (61d: Second Skin, the paint shop)
	var seed := 0
	var _t := 0.0
	var _acc := 0.0

	func _process(dt: float) -> void:
		_t += dt
		_acc += dt
		if _acc > 0.1:
			_acc = 0.0
			queue_redraw()

	func _h(i: int, salt: int) -> float:
		return Gen.TowerArt.hsh(i, salt)

	func _draw() -> void:
		match part:
			"wall":
				_wall()
			"pav":
				_pav()
			_:
				_holo()

	func _wall() -> void:
		var font := ThemeDB.fallback_font
		var w := float(Gen.HW * GroundMap.TILE)
		var fl := float(Gen.H_F0 * GroundMap.TILE)
		var x0 := float(Gen.H_X0 * GroundMap.TILE)
		var nightly := night > 0.5
		var wall := Color(0.2, 0.15, 0.15)
		var gold := Color(1.0, 0.82, 0.35)
		var warm := Color(1.0, 0.9, 0.66)
		# the ribs of the vault before the sky
		for rx in range(0, int(w), 37):
			draw_rect(Rect2(rx, 0.0, 2.0, 54.0), Color(0.62, 0.56, 0.48))
		draw_rect(Rect2(0.0, 17.0, w, 1.5), Color(0.62, 0.56, 0.48))
		draw_rect(Rect2(0.0, 35.0, w, 1.5), Color(0.62, 0.56, 0.48))
		draw_rect(Rect2(0.0, 0.0, w, 54.0), Color(0.7, 0.9, 1.0, 0.06))
		# the wall behind the galleries (west of the fronts only down to the lifts' own wall)
		draw_rect(Rect2(0.0, 54.0, x0, fl - 32.0 - 54.0), wall)
		draw_rect(Rect2(x0, 54.0, w - x0, fl - 54.0), wall)
		# two galleries: shops at their back, people behind the rail, the slab with its strip of light
		for gi in 2:
			var gy := 150.0 - gi * 48.0
			var gx := 5.0
			var k := 0
			while gx < w - 30.0:
				var gw := minf(44.0 + _h(gi * 50 + k, 1) * 28.0, w - 4.0 - gx)
				var sc: Color = NEON[int(_h(gi * 50 + k, 2) * NEON.size()) % NEON.size()]
				draw_rect(Rect2(gx, gy - 37.0, gw - 6.0, 27.0), Color(0.05, 0.05, 0.09))
				draw_rect(Rect2(gx + 1.0, gy - 36.0, gw - 8.0, 25.0), Color(sc.lerp(warm, 0.6), 0.85 if nightly else 0.6))
				for q in int((gw - 12.0) / 7.0):
					var gh := 5.0 + _h(gi * 91 + k * 7 + q, 3) * 9.0
					draw_rect(Rect2(gx + 4.0 + q * 7.0, gy - 11.0 - gh, 4.0, gh), Color(0.1, 0.07, 0.1, 0.7))
				draw_rect(Rect2(gx, gy - 41.0, gw - 6.0, 3.0), Color(sc, 0.9))
				if gw > 52.0:
					draw_string(font, Vector2(gx, gy - 28.0), NAMES[(gi * 5 + k * 3) % NAMES.size()], HORIZONTAL_ALIGNMENT_CENTER, gw - 6.0, 6, Color(0.08, 0.05, 0.08, 0.8))
				gx += gw
				k += 1
			for p in 10:
				var px := fposmod(_h(gi * 9 + p, 33) * w + _t * (4.0 + _h(gi + p, 34) * 6.0) * (1.0 if p % 2 == 0 else -1.0), w)
				var cloth: Color = [Color(0.3, 0.2, 0.36), Color(0.16, 0.3, 0.36), Color(0.4, 0.18, 0.24), Color(0.32, 0.3, 0.2), Color(0.2, 0.22, 0.34)][(gi * 3 + p) % 5]
				draw_rect(Rect2(px - 3.5, gy - 22.0, 7.0, 13.0), cloth)
				draw_circle(Vector2(px, gy - 25.0), 3.0, Color(0.5, 0.36, 0.3) if p % 3 != 0 else Color(0.3, 0.2, 0.16))
			draw_rect(Rect2(0.0, gy - 12.0, w, 12.0), Color(0.6, 0.85, 1.0, 0.18))
			draw_rect(Rect2(0.0, gy - 13.0, w, 1.5), Color(0.86, 0.9, 1.0, 0.9))
			for rp in range(0, int(w), 16):
				draw_rect(Rect2(rp, gy - 13.0, 1.0, 13.0), Color(0.7, 0.72, 0.8, 0.8))
			draw_rect(Rect2(0.0, gy, w, 4.0), wall.lightened(0.28))
			draw_rect(Rect2(0.0, gy + 2.0, w, 1.5), Color(NEON[gi], 0.9))
			for bn in range(26, int(w) - 10, 74):
				var bc: Color = NEON[(bn / 74 + gi * 2) % NEON.size()]
				var bx := float(bn) + gi * 37.0
				if bx < w - 14.0:
					draw_colored_polygon(PackedVector2Array([Vector2(bx, gy + 4.0), Vector2(bx + 10.0, gy + 4.0), Vector2(bx + 10.0, gy + 20.0), Vector2(bx + 5.0, gy + 15.0), Vector2(bx, gy + 20.0)]), Color(bc, 0.9))
		# the cornice under the vault: gold, a line of lamps running
		draw_rect(Rect2(0.0, 54.0, w, 4.0), gold.darkened(0.25))
		var bi := 0
		for cx in range(4, int(w), 10):
			draw_circle(Vector2(cx, 56.0), 1.3, Color(1.0, 0.95, 0.7) if (bi + int(_t * 5.0)) % 4 == 0 else Color(0.55, 0.4, 0.2))
			bi += 1
		# the shop fronts, a pillar between each two (up to the cornice)
		for f in fronts:
			_front(f, fl, font)
		var edges: Array = fronts.map(func(f2): return float(f2["x"]))
		if not fronts.is_empty():
			edges.append(float(fronts[fronts.size() - 1]["x"]) + float(fronts[fronts.size() - 1]["w"]))
		for ex in edges:
			var pxx := float(ex)
			draw_rect(Rect2(pxx - 3.5, 58.0, 7.0, fl - 58.0), wall.lightened(0.32))
			draw_rect(Rect2(pxx - 3.5, 58.0, 1.5, fl - 58.0), wall.lightened(0.5))
			draw_rect(Rect2(pxx - 0.5, 62.0, 1.0, fl - 70.0), Color(gold, 0.7))
			draw_rect(Rect2(pxx - 5.0, fl - 5.0, 10.0, 5.0), wall.lightened(0.4))
			draw_rect(Rect2(pxx - 5.0, 58.0, 10.0, 3.0), gold.darkened(0.1))
		# over the lifts: their sign
		draw_rect(Rect2(8.0, 158.0, x0 - 20.0, 14.0), Color(0.03, 0.04, 0.06))
		draw_rect(Rect2(8.0, 158.0, x0 - 20.0, 14.0), Color(0.4, 1.0, 0.6, 0.9), false, 1.0)
		draw_string(font, Vector2(8.0, 169.0), "LIFTS", HORIZONTAL_ALIGNMENT_CENTER, x0 - 20.0, 9, Color(0.7, 1.0, 0.8))
		_escalators(fl, w)
		# lights on lines from the cornice, swaying a little
		for ln in range(0, int(w), 148):
			var pts := PackedVector2Array()
			for k2 in 13:
				var u := k2 / 12.0
				pts.append(Vector2(ln + u * 148.0, 60.0 + sin(u * PI) * (16.0 + sin(_t * 0.9 + ln) * 1.5)))
			draw_polyline(pts, Color(0.1, 0.1, 0.14), 1.0)
			for k3 in range(1, 12):
				var lc: Color = NEON[(k3 + ln / 148) % NEON.size()]
				if nightly:
					draw_circle(pts[k3] + Vector2(0.0, 2.0), 3.5, Color(lc, 0.16))
				draw_circle(pts[k3] + Vector2(0.0, 2.0), 1.5, lc)

	## One shop's front on the ground floor.
	func _front(f: Dictionary, fl: float, font: Font) -> void:
		var x := float(f["x"]) + 5.0
		var w := float(f["w"]) - 10.0
		var fcol: Color = f["col"]
		var sd := int(f["seed"])
		var nightly := night > 0.5
		var warm := Color(1.0, 0.9, 0.66)
		var frame := Color(0.34, 0.27, 0.26)
		var cx := x + w * 0.5
		var to_let := String(f["id"]) == ""
		var shut := bool(f["shut"])
		draw_rect(Rect2(x, fl - 52.0, w, 52.0), Color(0.05, 0.05, 0.09))
		var flick := 1.0 if _h(sd, 15) > 0.2 else (0.4 + 0.6 * absf(sin(_t * 7.0 + sd)))
		draw_rect(Rect2(x + 2.0, fl - 51.0, w - 4.0, 13.0), Color(0.03, 0.03, 0.06))
		if to_let:
			draw_rect(Rect2(x + 2.0, fl - 51.0, w - 4.0, 13.0), Color(0.4, 0.4, 0.48), false, 1.0)
			draw_rect(Rect2(x + 3.0, fl - 36.0, w - 6.0, 36.0), Color(0.3, 0.31, 0.37))
			for sl in range(0, 36, 3):
				draw_rect(Rect2(x + 3.0, fl - 36.0 + sl, w - 6.0, 1.0), Color(0.2, 0.21, 0.26))
			draw_rect(Rect2(cx - 30.0, fl - 27.0, 60.0, 13.0), Color(0.92, 0.9, 0.84))
			draw_string(font, Vector2(cx - 30.0, fl - 17.5), "OPENING SOON", HORIZONTAL_ALIGNMENT_CENTER, 60.0, 7, Color(0.2, 0.16, 0.2))
			return
		draw_rect(Rect2(x + 2.0, fl - 51.0, w - 4.0, 13.0), Color(fcol, 0.85 * flick), false, 1.0)
		draw_string(font, Vector2(x + 2.0, fl - 41.0), String(f["title"]).to_upper(), HORIZONTAL_ALIGNMENT_CENTER, w - 4.0, 9, Color(fcol.lightened(0.35), flick))
		var lit := Color(fcol.lerp(warm, 0.6), (0.92 if nightly else 0.6) if not shut else 0.15)
		# a window either side of the door: shelves of goods, somebody behind the counter on the left
		for side in 2:
			var wx0 := x + 4.0 if side == 0 else cx + 17.0
			var ww := cx - 17.0 - (x + 4.0)
			draw_rect(Rect2(wx0 - 1.0, fl - 36.0, ww + 2.0, 31.0), frame)
			draw_rect(Rect2(wx0, fl - 35.0, ww, 29.0), lit)
			if not shut:
				for sh in 2:
					var yy := fl - 23.0 + sh * 11.0
					draw_rect(Rect2(wx0 + 2.0, yy, ww - 4.0, 1.0), Color(0.1, 0.07, 0.1, 0.6))
					for q in int((ww - 6.0) / 6.0):
						var gh := 3.0 + _h(sd + side * 31 + sh * 11 + q, 25) * 5.0
						var gc: Color = NEON[int(_h(sd + side * 17 + sh * 7 + q, 26) * NEON.size()) % NEON.size()]
						draw_rect(Rect2(wx0 + 3.0 + q * 6.0, yy - gh, 4.0, gh), Color(gc.darkened(0.35), 0.85))
				if side == 0:
					var kx := wx0 + ww * 0.55
					draw_rect(Rect2(kx - 4.0, fl - 21.0, 8.0, 15.0), Color(0.1, 0.07, 0.11, 0.85))
					draw_circle(Vector2(kx, fl - 24.0), 3.0, Color(0.1, 0.07, 0.11, 0.85))
			var mu := wx0 + 24.0
			while mu < wx0 + ww - 6.0:
				draw_rect(Rect2(mu, fl - 35.0, 1.0, 29.0), frame)
				mu += 24.0
			draw_rect(Rect2(wx0, fl - 35.0, ww, 3.0), Color(1, 1, 1, 0.14))
			draw_rect(Rect2(wx0 - 1.0, fl - 5.0, ww + 2.0, 5.0), frame.darkened(0.2))
		# the door: two leaves of glass, as high as a doorway
		draw_rect(Rect2(cx - 15.0, fl - 36.0, 30.0, 36.0), frame.lightened(0.15))
		draw_rect(Rect2(cx - 13.5, fl - 34.0, 13.0, 34.0), Color(warm, 0.85 if nightly else 0.55) if not shut else Color(0.08, 0.09, 0.14))
		draw_rect(Rect2(cx + 0.5, fl - 34.0, 13.0, 34.0), Color(warm, 0.85 if nightly else 0.55) if not shut else Color(0.08, 0.09, 0.14))
		draw_rect(Rect2(cx - 3.0, fl - 18.0, 1.5, 6.0), Color(0.3, 0.3, 0.36))
		draw_rect(Rect2(cx + 1.5, fl - 18.0, 1.5, 6.0), Color(0.3, 0.3, 0.36))
		draw_rect(Rect2(cx - 15.0, fl - 38.0, 30.0, 2.0), Color(fcol, 0.9))
		if shut:
			draw_rect(Rect2(cx - 12.0, fl - 26.0, 24.0, 8.0), Color(0.7, 0.14, 0.16))
			draw_string(font, Vector2(cx - 12.0, fl - 19.5), "CLOSED", HORIZONTAL_ALIGNMENT_CENTER, 24.0, 6, Color(1, 1, 1))
		elif nightly:
			draw_rect(Rect2(x + 4.0, fl, w - 8.0, 6.0), Color(fcol.lerp(warm, 0.6), 0.09))

	## Two escalators from the floor up to the first gallery, their steps running, somebody riding.
	func _escalators(fl: float, w: float) -> void:
		var steel := Color(0.3, 0.32, 0.4)
		for e in 2:
			var a := Vector2(float(Gen.H_X1 + 1) * GroundMap.TILE + 6.0 + e * 40.0, fl)
			var b := Vector2(minf(a.x + 132.0, w - 30.0 + e * 20.0), 150.0)
			var up := e == 0
			var dim := 0.0 if up else 0.25
			draw_colored_polygon(PackedVector2Array([a, a + Vector2(26.0, 0.0), b + Vector2(26.0, 0.0), b]), steel.darkened(dim))
			var dv := b - a
			for s in 16:
				var u := fposmod(s / 16.0 + _t * 0.06 * (1.0 if up else -1.0), 1.0)
				var sp := a + dv * u
				draw_rect(Rect2(sp.x + 3.0, sp.y - 1.0, 20.0, 1.5), Color(0.75, 0.78, 0.86, 0.8))
			draw_colored_polygon(PackedVector2Array([a + Vector2(0.0, -13.0), a, b, b + Vector2(0.0, -13.0)]), Color(0.6, 0.85, 1.0, 0.2))
			draw_line(a + Vector2(0.0, -13.0), b + Vector2(0.0, -13.0), Color(0.06, 0.06, 0.1), 2.5)
			draw_line(a + Vector2(0.0, -11.0), b + Vector2(0.0, -11.0), Color(0.3, 0.9, 1.0, 0.8), 1.0)
			var ru := fposmod(_t * 0.06 + 0.3 + e * 0.4, 1.0)
			var rp2 := a + dv * (ru if up else 1.0 - ru) + Vector2(13.0, 0.0)
			draw_rect(Rect2(rp2.x - 3.5, rp2.y - 16.0, 7.0, 13.0), Color(0.2, 0.22, 0.34))
			draw_circle(Vector2(rp2.x, rp2.y - 19.0), 3.0, Color(0.5, 0.36, 0.3))
			draw_rect(Rect2(a.x - 2.0, fl - 3.0, 30.0, 3.0), Color(0.6, 0.62, 0.7))

	## A pavilion to let: its roof, its front with the shutters down, a sign.
	func _pav() -> void:
		var font := ThemeDB.fallback_font
		var w := 8.0 * GroundMap.TILE
		var body := Color(0.2, 0.2, 0.28)
		draw_rect(Rect2(3.0, -4.0, w, 6.0), Color(0, 0, 0, 0.3))
		draw_rect(Rect2(0.0, -78.0, w, 32.0), body.lightened(0.18))
		draw_rect(Rect2(0.0, -78.0, w, 1.5), body.lightened(0.4))
		draw_rect(Rect2(0.0, -78.0, w, 32.0), Color(col, 0.75), false, 1.0)                 # its roof: a line of neon round it,
		draw_rect(Rect2(34.0, -72.0, w - 68.0, 18.0), Color(0.08, 0.08, 0.12))              # a skylight dark for now,
		draw_rect(Rect2(36.0, -70.0, w - 72.0, 14.0), Color(0.3, 0.4, 0.55, 0.5))
		draw_rect(Rect2(w * 0.5 - 0.5, -70.0, 1.0, 14.0), Color(0.08, 0.08, 0.12))
		for pl in 2:                                                                        # a planter either end
			var plx := 8.0 if pl == 0 else w - 26.0
			draw_rect(Rect2(plx, -62.0, 18.0, 8.0), Color(0.36, 0.26, 0.2))
			for lf in 3:
				draw_circle(Vector2(plx + 3.0 + lf * 6.0, -64.0 - (lf % 2) * 2.0), 4.0, Color(0.2, 0.56, 0.3))
		draw_rect(Rect2(0.0, -46.0, w, 46.0), body)
		draw_rect(Rect2(0.0, -46.0, w, 2.0), Color(col, 0.9))
		draw_rect(Rect2(2.0, -44.0, w - 4.0, 10.0), Color(0.03, 0.03, 0.06))
		draw_rect(Rect2(2.0, -44.0, w - 4.0, 10.0), Color(col, 0.6), false, 1.0)
		if shop != "":
			# an open showroom: glass and light, three small ships turning on pedestals, each in another paint
			draw_string(font, Vector2(2.0, -36.0), shop, HORIZONTAL_ALIGNMENT_CENTER, w - 4.0, 8, Color(col.lightened(0.35), 0.9 + 0.1 * sin(_t * 2.0)))
			draw_rect(Rect2(4.0, -32.0, w - 8.0, 32.0), Color(0.08, 0.08, 0.12))
			draw_rect(Rect2(5.0, -31.0, w - 10.0, 30.0), Color(1.0, 0.95, 0.85, 0.85))
			for md in 3:
				var mx := 24.0 + md * 40.0
				var pid := String(Paints.ORDER[(md * 4 + int(_t / 5.0)) % (Paints.ORDER.size() - 1)])
				var hc: Color = Paints.PAINTS[pid]["hull"]
				var ac: Color = Paints.PAINTS[pid]["acc"]
				var sq := cos(_t * 1.1 + md * 2.1)
				draw_rect(Rect2(mx - 7.0, -9.0, 14.0, 8.0), Color(0.3, 0.3, 0.36))
				draw_rect(Rect2(mx - 7.0, -9.0, 14.0, 1.5), Color(0.5, 0.5, 0.56))
				if absf(sq) > 0.15:
					draw_colored_polygon(PackedVector2Array([Vector2(mx, -28.0), Vector2(mx + 10.0 * sq, -13.0), Vector2(mx, -16.0), Vector2(mx - 10.0 * sq, -13.0)]), hc)
					draw_colored_polygon(PackedVector2Array([Vector2(mx, -24.0), Vector2(mx + 3.0 * sq, -18.0), Vector2(mx, -17.0), Vector2(mx - 3.0 * sq, -18.0)]), ac)
				else:
					draw_rect(Rect2(mx - 1.0, -28.0, 2.0, 14.0), hc)
				draw_rect(Rect2(mx - 0.5, -13.0, 1.0, 4.0), Color(0.2, 0.2, 0.24))
			for gm in range(0, int(w), 32):
				draw_rect(Rect2(gm + 4.0, -32.0, 1.0, 32.0), Color(0.08, 0.08, 0.12))
			draw_rect(Rect2(5.0, -31.0, w - 10.0, 3.0), Color(1, 1, 1, 0.25))
			return
		draw_rect(Rect2(4.0, -32.0, w - 8.0, 32.0), Color(0.3, 0.31, 0.37))
		for sl in range(0, 32, 3):
			draw_rect(Rect2(4.0, -32.0 + sl, w - 8.0, 1.0), Color(0.2, 0.21, 0.26))
		draw_rect(Rect2(w * 0.5 - 30.0, -24.0, 60.0, 13.0), Color(0.92, 0.9, 0.84))
		draw_string(font, Vector2(w * 0.5 - 30.0, -14.5), "OPENING SOON", HORIZONTAL_ALIGNMENT_CENTER, 60.0, 7, Color(0.2, 0.16, 0.2))
		draw_string(font, Vector2(2.0, -36.0), "TO LET", HORIZONTAL_ALIGNMENT_CENTER, w - 4.0, 7, Color(col.lightened(0.3), 0.6 + 0.3 * sin(_t * 1.7)))

	## Over the fountain: Lapis as a hologram, turning, its light rising from the water.
	func _holo() -> void:
		draw_colored_polygon(PackedVector2Array([Vector2(-9.0, -22.0), Vector2(9.0, -22.0), Vector2(26.0, -84.0), Vector2(-26.0, -84.0)]), Color(0.3, 0.9, 1.0, 0.07))
		Gen.draw_lapis(self, Vector2(0.0, -62.0), 15.0, 1.0, _t * 30.0, false)
		for sc2 in 5:
			draw_rect(Rect2(-36.0, -88.0 + sc2 * 11.0 + fposmod(_t * 8.0, 11.0), 72.0, 1.0), Color(0.6, 1.0, 1.0, 0.12))


## Package 61b (Luz): the Back Alleys behind the gate on the plaza. A crowded street running east to west between
## high houses, dark even by day: along its north side front after front (noodle bars with a counter to the street,
## small shops, shutters, an arcade), neon signs over them in many layers; market stalls on the street, people close
## together (umbrellas when it rains), puddles with the neon in them; lines of lanterns across it, the roofs of low
## booths along its south side, now and then a craft with a searchlight overhead. In the middle of the north side
## the gate back to the plaza; at the east end the stairs down to the Static Feedback. The fronts, the signs and
## the roofs are drawn (AlleyFx).
const AW := 96
const AH := 26
const A_F0 := 14                   # the street's first row (north of it the houses' fronts, drawn)
const A_F1 := 19                   # its last row (Luz: narrow; south of it the roofs of the shops on that side, drawn)
const A_GATE := 45                 # the gate to the plaza: its west column (6 wide)
const A_BAR := 80                  # the bar's front: its west column (10 wide)

static func build_alleys(_station: Dictionary) -> GroundMap:
	var m := GroundMap.new()
	MuseumGen._pal(m, {})
	m.pal["floor"] = Color(0.21, 0.21, 0.28)
	m.pal["floor2"] = Color(0.15, 0.15, 0.21)
	m.pal["wall"] = Color(0.14, 0.13, 0.18)
	m.pal["frame"] = Color(0.14, 0.13, 0.18)
	m.pal["accent"] = Color(0.35, 1.0, 0.55)
	m.style = "plaza"
	m.title = "Centauria"
	m.hull_top = -9999
	m.set_meta("no_guards", true)
	m.setup(AW, AH)
	var cols := [Color(1.0, 0.36, 0.3), Color(1.0, 0.6, 0.2), Color(0.3, 0.9, 0.85), Color(1.0, 0.36, 0.66), Color(0.95, 0.85, 0.3), Color(0.6, 0.5, 1.0)]
	var rng := RandomNumberGenerator.new()
	rng.seed = 6121
	m.fill(0, 0, AW, AH, T.BLOCK, 0)
	m.fill(1, A_F0, AW - 2, A_F1 - A_F0 + 1, T.FLOOR, 0)              # (dark plates: a wet street at night)
	# the gate back to the plaza, a passage north through the houses
	m.fill(A_GATE, A_F0 - 3, 6, 3, T.FLOOR, 0)
	m.zones.append({"rect": Rect2(Vector2(A_GATE, A_F0 - 3) * TILE, Vector2(6, 1.7) * TILE), "kind": "museum_go", "id": "alley_gate", "to": "zplaza", "at": "from_alleys",
		"title": "Through the gate: the plaza of the Commercial District", "col": Color(0.35, 1.0, 0.55), "sign": Vector2(-100, -100)})
	m.set_meta("from_plaza", Vector2(A_GATE + 3.0, A_F0 + 0.8) * TILE)
	m.spawn = m.get_meta("from_plaza")
	m.lights.append({"pos": Vector2(A_GATE + 3.0, A_F0 - 1.0) * TILE, "r": 70.0, "col": Color(0.35, 1.0, 0.55), "a": 0.4})
	# the Static Feedback: stairs down under its sign, somebody at the door
	m.zones.append({"rect": Rect2(Vector2(A_BAR + 4.0, A_F0 - 0.2) * TILE, Vector2(3.4, 1.7) * TILE), "kind": "museum_go", "id": "bar_in", "to": "zbar", "at": "from_street",
		"title": "Down the stairs: the Static Feedback", "col": Color(1.0, 0.36, 0.66), "sign": Vector2(-100, -100)})
	m.set_meta("from_bar", Vector2(A_BAR + 5.7, A_F0 + 1.4) * TILE)
	m.people.append({"pos": Vector2(A_BAR + 2.6, A_F0 + 0.9) * TILE, "dir": 0, "role": "keeper"})
	m.lights.append({"pos": Vector2(A_BAR + 5.7, A_F0 + 0.4) * TILE, "r": 80.0, "col": Color(1.0, 0.3, 0.5), "a": 0.5, "flicker": true})
	# the fronts along the north side: what each is (the picture is drawn); a noodle bar has stools at its counter
	var fronts: Array = []
	var kinds := ["noodle", "shop", "shutter", "arcade", "noodle", "shop", "noodle", "shutter", "shop"]
	var x := 1
	var i := 0
	while x < AW - 1:
		var kind := String(kinds[i % kinds.size()])
		var w := rng.randi_range(6, 8)
		var stop := A_GATE if x < A_GATE else (A_BAR if x < A_BAR else AW - 1)
		if x == A_GATE:
			kind = "gate"
			w = 6
		elif x == A_BAR:
			kind = "bar"
			w = 10
		elif stop - (x + w) < 5:
			w = stop - x
		var fcol: Color = cols[(i * 5 + 1) % cols.size()]
		fronts.append({"x": float(x * TILE), "w": float(w * TILE), "kind": kind, "seed": 300 + i * 17, "col": fcol})
		if kind == "noodle":
			m.fill(x, A_F0, w, 1, T.BLOCK, 0)                  # its counter stands out into the street
			for sx in range(x + 1, x + w - 1, 2):
				DeckGen._seat(m, "stool", sx, A_F0 + 1, 1, fcol.darkened(0.35), rng, 0.7)
		if not kind in ["gate", "bar"]:
			m.lights.append({"pos": Vector2(x + w * 0.5, A_F0 + 0.8) * TILE, "r": 56.0, "col": fcol, "a": 0.42, "flicker": kind == "arcade"})
		x += w
		i += 1
	m.set_meta("alley_fronts", fronts)
	# (Luz: shops along both sides, hardly a stall) two stalls by the south side, their keepers; the light of the
	# shops on that side falling onto the street
	var n := 0
	for lx in range(4, AW - 3, 7):
		m.lights.append({"pos": Vector2(lx, A_F1 + 0.6) * TILE, "r": 50.0, "col": cols[(lx / 7 + 3) % cols.size()], "a": 0.4})
	for sp in [Vector2i(26, 5), Vector2i(66, 5)]:
		m.add_object({"kind": "stall", "x": sp.x, "y": A_F0 + sp.y, "w": 2, "h": 1, "col": cols[n % cols.size()]})
		m.people.append({"pos": Vector2(sp.x + 1.0, A_F0 + sp.y - 0.2) * TILE, "dir": 0, "role": "keeper"})
		m.lights.append({"pos": Vector2(sp.x + 1.0, A_F0 + sp.y + 0.6) * TILE, "r": 34.0, "col": cols[n % cols.size()], "a": 0.5})
		n += 1
	m.set_meta("tourists", 5)
	m.set_meta("stream", 86)                                          # (Luz) the crowd streaming east and west through it
	DeckGen._seats(m)
	for gx in range(3, AW - 2, 5):
		for gy in [A_F0 + 2, A_F0 + 4]:
			var wp := Vector2(gx, gy)
			if m.free_at(wp * TILE, 6.0):
				m.wander.append(wp * TILE)
	return m


## Package 61b (Luz): the Static Feedback, Luz' punk bar in a cellar under the Back Alleys. A small place (Luz: not
## much room, not much going on): a little stage at its west end, a short counter along the north wall, two booths in
## the east, pool, darts, an arcade cabinet, a Drift table and the jukebox; a door to a back room (shut); the stairs
## up to the street in the north-east. Dark wood, dark all over: the neon carries it. Nobody strolls in here: it is
## where the people of the story meet (BAR_SPOTS), your own crew waits here ("bar_crew": where they stand), and at
## night the band plays (The Hull Breach: four real people, see the story's characters) with a few dancing before
## them. Its north wall, its stage and the band's gear are drawn (BarFx).
const BW := 30
const BH := 18
const B_F0 := 7                    # the floor's first row (north of it the cellar's wall, drawn)
const B_F1 := 15
const B_STAGE := Rect2i(1, 7, 6, 4)                                  # the stage (tiles)
const BAR_SPOTS := {"luz": Vector2(15.5, 7.99), "ratte": Vector2(24.4, 12.7), "kraut": Vector2(28.3, 12.4)}       # (tiles)
const BAND := [["band_drums", Vector2(3.9, 8.4), "kit"], ["band_guitar", Vector2(2.1, 9.9), "guitar"], ["band_bass", Vector2(5.9, 9.8), "bass"],
	["band_voice", Vector2(4.0, 10.1), "mic"]]                      # who, where (tiles), what they play

static func build_punkbar(_station: Dictionary, night: bool = false) -> GroundMap:
	var m := GroundMap.new()
	MuseumGen._pal(m, {})
	m.pal["floor"] = Color(0.24, 0.2, 0.22)
	m.pal["floor2"] = Color(0.18, 0.15, 0.17)
	m.pal["wood"] = Color(0.27, 0.16, 0.11)
	m.set_meta("dark", Color(0.46, 0.4, 0.52))
	m.pal["wall"] = Color(0.2, 0.12, 0.12)
	m.pal["frame"] = Color(0.2, 0.12, 0.12)
	m.pal["accent"] = Color(1.0, 0.36, 0.66)
	m.style = "plaza"
	m.title = "Centauria"
	m.hull_top = -9999
	m.set_meta("no_guards", true)
	m.setup(BW, BH)
	var PINK := Color(1.0, 0.36, 0.66)
	var CYAN := Color(0.3, 0.9, 1.0)
	var RED := Color(1.0, 0.25, 0.25)
	var PURPLE := Color(0.72, 0.36, 1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 6122
	m.fill(0, 0, BW, BH, T.CAP)
	m.fill(1, 0, BW - 2, B_F0, T.BLOCK, 30)                          # the north wall: drawn over
	m.fill(1, B_F0, BW - 2, B_F1 - B_F0 + 1, T.FLOOR, 3)
	for nl in [[Vector2(8.0, B_F0 + 0.3), CYAN], [Vector2(21.5, B_F0 + 0.3), PURPLE], [Vector2(10.0, B_F0 + 5.0), CYAN], [Vector2(16.0, B_F0 + 7.5), PINK],
			[Vector2(22.0, B_F0 + 5.5), RED], [Vector2(26.5, B_F0 + 5.5), Color(0.55, 1.0, 0.6)], [Vector2(3.0, B_F0 + 7.5), PURPLE]]:
		m.lights.append({"pos": (nl[0] as Vector2) * TILE, "r": 50.0, "col": nl[1], "a": 0.42})
	# the stage (drawn); at night the band on it and a few dancing before it
	m.fill(B_STAGE.position.x, B_STAGE.position.y, B_STAGE.size.x, B_STAGE.size.y, T.BLOCK, 3)
	m.set_meta("bar_stage", Rect2(Vector2(B_STAGE.position) * TILE, Vector2(B_STAGE.size) * TILE))
	m.lights.append({"pos": Vector2(4.0, B_F0 + 2.5) * TILE, "r": 80.0, "col": RED, "a": 0.4})
	if night:
		var chars: Dictionary = load("res://data/story.gd").CHARACTERS
		var props: Array = []
		for bm in BAND:
			var at: Vector2 = (bm[1] as Vector2) * TILE
			m.people.append({"pos": at, "dir": 0, "role": "keeper", "look": (chars.get(String(bm[0]), {}) as Dictionary).get("look", {}), "dance": String(bm[2]) != "kit"})
			props.append({"at": at, "kind": String(bm[2])})
		m.set_meta("bar_band", props)
		for dp in [Vector2(2.4, 12.6), Vector2(4.3, 13.3), Vector2(6.2, 12.4)]:
			m.people.append({"pos": dp * TILE, "dir": 1, "role": "keeper", "dance": true})
	# the counter along the north wall, stools before it
	m.add_object({"kind": "bar_counter", "x": 11, "y": B_F0 + 1, "w": 10, "h": 1})
	for sx in range(12, 20, 2):
		DeckGen._seat(m, "stool", sx, B_F0 + 2, 1, Color(0.75, 0.25, 0.3), rng, 0.0)
	m.lights.append({"pos": Vector2(16.0, B_F0 + 1.0) * TILE, "r": 90.0, "col": PINK, "a": 0.4})
	m.lights.append({"pos": Vector2(16.0, B_F0 + 0.4) * TILE, "r": 50.0, "col": Color(1.0, 0.8, 0.5), "a": 0.3})
	# the games
	DeckGen._arcade(m, 7, B_F0, 0)
	DeckGen._dart_board(m, 9, B_F0 - 1)
	m.add_object({"kind": "jukebox", "x": 21, "y": B_F0, "w": 1, "h": 1, "col": PINK})
	m.zones.append({"rect": Rect2(Vector2(20.6, B_F0 + 0.8) * TILE, Vector2(1.8, 1.4) * TILE), "kind": "jukebox", "id": "jukebox", "title": "Jukebox", "sign": Vector2(-100, -100)})
	m.lights.append({"pos": Vector2(21.5, B_F0 + 0.6) * TILE, "r": 34.0, "col": PINK, "a": 0.4, "flicker": true})
	DeckGen._pool_table(m, 9, B_F0 + 4)
	m.add_object({"kind": "round_table", "x": 15, "y": B_F0 + 5, "w": 1, "h": 1})
	DeckGen._seat(m, "chair", 14, B_F0 + 5, 3, Color(0.4, 0.2, 0.3), rng, 0.0)
	DeckGen._seat(m, "chair", 16, B_F0 + 5, 2, Color(0.4, 0.2, 0.3), rng, 0.0)
	DeckGen._drift_zone(m, Rect2(Vector2(14, B_F0 + 5.8) * TILE, Vector2(3, 1.6) * TILE))
	m.add_object({"kind": "round_table", "x": 18, "y": B_F0 + 7, "w": 1, "h": 1})
	# the door to the back room (shut), the stairs up to the street
	_zone(m, Rect2(22.3, B_F0, 2.4, 1.4), "ctr_closed", "The back room", PURPLE, {"closed": "Private. Luz keeps the key.", "id": "bar_back"})
	m.fill(25, B_F0 - 2, 4, 2, T.FLOOR, 30)
	m.zones.append({"rect": Rect2(Vector2(25, B_F0 - 2) * TILE, Vector2(4, 1.7) * TILE), "kind": "museum_go", "id": "bar_out", "to": "zalley", "at": "from_bar",
		"title": "Up the stairs: the Back Alleys", "col": CYAN, "sign": Vector2(-100, -100)})
	m.set_meta("from_street", Vector2(27.0, B_F0 + 0.8) * TILE)
	m.spawn = m.get_meta("from_street")
	m.lights.append({"pos": Vector2(27.0, B_F0 - 0.5) * TILE, "r": 56.0, "col": CYAN, "a": 0.35})
	# two booths in the east: two sofas face to face, a table between
	for bk in 2:
		var bx := 21 + bk * 4
		DeckGen._seat(m, "sofa", bx, B_F0 + 3, 0, Color(0.45, 0.14, 0.2), rng, 0.0, 3)
		m.add_object({"kind": "round_table", "x": bx + 1, "y": B_F0 + 5, "w": 1, "h": 1})
		DeckGen._seat(m, "sofa", bx, B_F0 + 7, 1, Color(0.45, 0.14, 0.2), rng, 0.0, 3)
	# where your own crew waits (art px, the way they look)
	m.set_meta("bar_crew", [[Vector2(13.0, B_F0 + 3.3) * TILE, 1], [Vector2(17.1, B_F0 + 3.3) * TILE, 1], [Vector2(17.3, B_F0 + 7.7) * TILE, 3], [Vector2(19.6, B_F0 + 7.6) * TILE, 2],
		[Vector2(12.9, B_F0 + 5.4) * TILE, 2], [Vector2(13.4, B_F0 + 8.2) * TILE, 0]])
	m.set_meta("tourists", 0)                                         # (nobody strolls in here)
	DeckGen._seats(m)
	return m


## The Back Alleys, drawn (art px). "wall": the houses' fronts along the north side from the street up: shops (noodle
## bars open to the street, their steam; shop windows; shutters with scrawls; an arcade), dark storeys with a few lit
## windows, pipes and coolers, and signs in layers: blades standing out from the walls, boards, round marks, screens.
## The gate to the plaza and the front of the Static Feedback. "floor": the wet street, the neon lying in it. Both
## under the people. "over": lines of lanterns across the street, the booths' roofs along the south side, a craft
## with a searchlight now and then: over the people.
class AlleyFx extends Node2D:
	const Gen = preload("res://scripts/ground/centauria_gen.gd")
	const NEON := [Color(1.0, 0.36, 0.3), Color(1.0, 0.6, 0.2), Color(0.3, 0.9, 0.85), Color(1.0, 0.36, 0.66), Color(0.95, 0.85, 0.3), Color(0.6, 0.5, 1.0)]
	const FOOD := ["NOODLES", "RAMEN", "DUMPLINGS", "SOBA", "BROTH"]
	const SHOP := ["PAWN", "PARTS", "TATTOO", "VINYL", "24H", "LOANS", "OPTICS", "KEYS", "TEA"]
	const ADS := ["NOVA COLA", "ORBIT GIN", "FLY AURELLE", "KHI WORKS", "PELAGIA TOURS"]
	var part := "wall"
	var fronts: Array = []
	var night := 1.0
	var _t := 0.0
	var _acc := 0.0

	func _process(dt: float) -> void:
		_t += dt
		_acc += dt
		if _acc > 0.09:
			_acc = 0.0
			queue_redraw()

	func _h(i: int, salt: int) -> float:
		return Gen.TowerArt.hsh(i, salt)

	func _draw() -> void:
		match part:
			"wall":
				for f in fronts:
					_house(f)
				_cables()
			"floor":
				_floor()
			_:
				_over()

	## Marks like a script nobody reads: small blocks in a column.
	func _glyphs(x: float, y: float, n: int, sd: int, c: Color) -> void:
		for g in n:
			var gy := y + g * 9.0
			for q in 3:
				if _h(sd + g * 5 + q, 61) < 0.75:
					draw_rect(Rect2(x + 1.0 + (q % 2) * 4.0 * _h(sd + g + q, 62), gy + q * 2.6, 3.0 + _h(sd + g * 3 + q, 63) * 4.0, 1.6), c)

	func _house(f: Dictionary) -> void:
		var font := ThemeDB.fallback_font
		var x := float(f["x"])
		var w := float(f["w"])
		var sd := int(f["seed"])
		var fcol: Color = f["col"]
		var kind := String(f["kind"])
		var fl := float(Gen.A_F0 * GroundMap.TILE)
		var wall := Color(0.09, 0.09, 0.14).lerp([Color(0.2, 0.12, 0.16), Color(0.1, 0.16, 0.2), Color(0.18, 0.14, 0.1), Color(0.12, 0.12, 0.2)][sd % 4], 0.6)
		var warm := Color(1.0, 0.8, 0.5)
		draw_rect(Rect2(x, 0.0, w, fl), wall)
		draw_rect(Rect2(x, 0.0, 1.5, fl), wall.lightened(0.14))
		draw_rect(Rect2(x + w - 2.0, 0.0, 2.0, fl), wall.darkened(0.4))
		# the storeys over the shop: few windows lit, coolers, a balcony of iron on every second
		var st := 0
		var y := fl - 56.0 - 38.0
		while y > -30.0:
			draw_rect(Rect2(x + 2.0, y + 36.0, w - 4.0, 2.0), wall.darkened(0.35))
			var cols := maxi(1, int((w - 10.0) / 18.0))
			var ox := x + (w - cols * 18.0) * 0.5 + 3.0
			for c in cols:
				var wx := ox + c * 18.0
				var on := _h(sd + st * 13 + c / 2, 6) < 0.3
				draw_rect(Rect2(wx - 1.0, y + 6.0, 14.0, 22.0), wall.lightened(0.14))
				var wc := Color(0.04, 0.05, 0.09)
				if on:
					wc = Color(warm, 0.9) if _h(sd + st * 7 + c, 9) < 0.6 else Color(NEON[(sd + c) % NEON.size()], 0.75)
				draw_rect(Rect2(wx, y + 7.0, 12.0, 20.0), wc)
				if on and _h(sd + st * 5 + c, 10) < 0.4:
					draw_rect(Rect2(wx, y + 7.0, 12.0, 9.0), wall.darkened(0.2))
				draw_rect(Rect2(wx + 5.5, y + 7.0, 1.0, 20.0), wall.lightened(0.14))
				if _h(sd + st * 29 + c, 11) < 0.18:
					draw_rect(Rect2(wx + 1.0, y + 29.0, 10.0, 6.0), Color(0.4, 0.42, 0.48))
					draw_circle(Vector2(wx + 6.0, y + 32.0), 2.0, Color(0.1, 0.1, 0.14))
			if st % 2 == 1:
				draw_rect(Rect2(x + 3.0, y + 24.0, w - 6.0, 1.5), Color(0.3, 0.3, 0.36))
				for px in range(int(x) + 4, int(x + w) - 4, 4):
					draw_rect(Rect2(px, y + 24.0, 1.0, 12.0), Color(0.22, 0.22, 0.28))
			y -= 38.0
			st += 1
		draw_rect(Rect2(x + w - 7.0, 0.0, 2.0, fl - 56.0), Color(0.24, 0.25, 0.3))
		# the shop
		match kind:
			"noodle":
				_noodle(x, w, fl, sd, fcol, font)
			"shop":
				_shop(x, w, fl, sd, fcol, font)
			"shutter":
				_shutter(x, w, fl, sd, fcol)
			"arcade":
				_arcade(x, w, fl, sd, fcol, font)
			"gate":
				_gate(x, w, fl, font)
			_:
				_bar(x, w, fl, font)
		if kind in ["gate", "bar"]:
			return
		# signs in layers: a blade standing out from the wall, a round mark, a screen on the wider houses
		var flick := 1.0 if _h(sd, 15) > 0.3 else (0.35 + 0.65 * absf(sin(_t * 8.0 + sd)))
		var bc: Color = NEON[(sd + 2) % NEON.size()]
		var bh := 60.0 + _h(sd, 16) * 60.0
		var bx := x + (5.0 if sd % 2 == 0 else w - 19.0)
		draw_rect(Rect2(bx - 1.0, fl - 62.0 - bh, 14.0, bh + 2.0), Color(0.02, 0.02, 0.05))
		draw_rect(Rect2(bx - 1.0, fl - 62.0 - bh, 14.0, bh + 2.0), Color(bc, 0.9 * flick), false, 1.0)
		_glyphs(bx + 1.5, fl - 58.0 - bh, int(bh / 9.0), sd, Color(bc.lightened(0.3), flick))
		draw_rect(Rect2(bx - 4.0, fl - 64.0 - bh, 20.0, bh + 6.0), Color(bc, 0.05 * flick))
		if w > 96.0:
			var b2: Color = NEON[(sd + 5) % NEON.size()]
			var b2h := 36.0 + _h(sd, 26) * 44.0
			var b2x := x + (w - 19.0 if sd % 2 == 0 else 5.0)
			draw_rect(Rect2(b2x - 1.0, fl - 62.0 - b2h, 14.0, b2h + 2.0), Color(0.02, 0.02, 0.05))
			draw_rect(Rect2(b2x - 1.0, fl - 62.0 - b2h, 14.0, b2h + 2.0), Color(b2, 0.9), false, 1.0)
			_glyphs(b2x + 1.5, fl - 58.0 - b2h, int(b2h / 9.0), sd + 40, b2.lightened(0.3))
			draw_rect(Rect2(b2x - 4.0, fl - 64.0 - b2h, 20.0, b2h + 6.0), Color(b2, 0.05))
		if w > 104.0:
			var sc2: Color = NEON[(sd + 4) % NEON.size()]
			var sx := x + w * 0.5 - 26.0
			var sy := fl - 150.0 - _h(sd, 17) * 30.0
			draw_rect(Rect2(sx - 2.0, sy - 2.0, 56.0, 38.0), Color(0.02, 0.02, 0.05))
			for bnd in 6:
				draw_rect(Rect2(sx, sy + bnd * 5.7, 52.0, 5.7), Color.from_hsv(fposmod(_h(sd, 18) + bnd * 0.07 + _t * 0.03, 1.0), 0.75, 0.55))
			draw_rect(Rect2(sx, sy + fposmod(_t * 9.0, 34.0), 52.0, 2.0), Color(1, 1, 1, 0.14))
			draw_string(font, Vector2(sx, sy + 20.0), ADS[sd % ADS.size()], HORIZONTAL_ALIGNMENT_CENTER, 52.0, 7, Color(1, 1, 1))
			draw_rect(Rect2(sx - 2.0, sy - 2.0, 56.0, 38.0), Color(sc2, 0.8), false, 1.0)
		else:
			var rc: Color = NEON[(sd + 4) % NEON.size()]
			var cc := Vector2(x + w * 0.5 + 6.0, fl - 120.0 - _h(sd, 19) * 40.0)
			draw_circle(cc, 13.0, Color(0.02, 0.02, 0.05))
			draw_arc(cc, 11.0, 0.0, TAU, 20, Color(rc, 0.95), 1.5)
			draw_arc(cc, 6.0, _t * 1.5 + sd, _t * 1.5 + sd + 4.2, 12, Color(rc.lightened(0.3), 0.9), 1.5)
			draw_circle(cc, 16.0, Color(rc, 0.06))

	func _board(x: float, w: float, fl: float, text: String, c: Color, font: Font, flick: float) -> void:
		draw_rect(Rect2(x + 3.0, fl - 56.0, w - 6.0, 12.0), Color(0.02, 0.02, 0.05))
		draw_rect(Rect2(x + 3.0, fl - 56.0, w - 6.0, 12.0), Color(c, 0.85 * flick), false, 1.0)
		draw_string(font, Vector2(x + 3.0, fl - 46.5), text, HORIZONTAL_ALIGNMENT_CENTER, w - 6.0, 9, Color(c.lightened(0.35), flick))

	## A noodle bar: open to the street, its counter standing out, cooks behind it, lanterns, pots steaming.
	func _noodle(x: float, w: float, fl: float, sd: int, c: Color, font: Font) -> void:
		var flick := 1.0 if _h(sd, 20) > 0.25 else (0.4 + 0.6 * absf(sin(_t * 7.0 + sd)))
		_board(x, w, fl, FOOD[sd % FOOD.size()], c, font, flick)
		draw_rect(Rect2(x + 3.0, fl - 43.0, w - 6.0, 43.0), Color(0.1, 0.06, 0.05))
		draw_rect(Rect2(x + 5.0, fl - 41.0, w - 10.0, 30.0), Color(1.0, 0.72, 0.4, 0.85))
		for mb in int((w - 16.0) / 16.0):                              # the menu at the back
			draw_rect(Rect2(x + 9.0 + mb * 16.0, fl - 39.0, 12.0, 7.0), Color(0.95, 0.9, 0.75))
			draw_rect(Rect2(x + 10.0 + mb * 16.0, fl - 37.0, 8.0, 1.0), Color(0.5, 0.2, 0.15))
			draw_rect(Rect2(x + 10.0 + mb * 16.0, fl - 35.0, 6.0, 1.0), Color(0.5, 0.2, 0.15))
		for ck in maxi(1, int(w / 60.0)):                               # the cooks
			var cx := x + w * (0.3 + ck * 0.4) + sin(_t * 0.7 + ck + sd) * 4.0
			draw_rect(Rect2(cx - 4.5, fl - 27.0, 9.0, 16.0), Color(0.92, 0.9, 0.86))
			draw_circle(Vector2(cx, fl - 30.0), 3.4, Color(0.6, 0.42, 0.34))
			draw_rect(Rect2(cx - 3.5, fl - 35.0, 7.0, 2.5), Color(0.95, 0.95, 0.95))
		draw_rect(Rect2(x + 3.0, fl - 12.0, w - 6.0, 12.0), Color(0.3, 0.2, 0.16))        # the counter
		draw_rect(Rect2(x + 2.0, fl - 14.0, w - 4.0, 3.0), Color(0.5, 0.36, 0.26))
		draw_rect(Rect2(x + 3.0, fl - 5.0, w - 6.0, 1.5), Color(c, 0.8))
		for bw in int((w - 14.0) / 14.0):                               # bowls on it
			draw_rect(Rect2(x + 9.0 + bw * 14.0, fl - 16.0, 6.0, 2.5), Color(0.9, 0.9, 0.92))
		for ln in int((w - 10.0) / 12.0):                               # lanterns under the lintel
			var lx := x + 8.0 + ln * 12.0
			draw_rect(Rect2(lx, fl - 43.0, 1.0, 3.0), Color(0.1, 0.1, 0.1))
			draw_rect(Rect2(lx - 2.0, fl - 40.0, 5.0, 6.0), Color(0.95, 0.25, 0.2))
			draw_rect(Rect2(lx - 0.5, fl - 39.0, 2.0, 3.0), Color(1.0, 0.85, 0.5))
		for pf in 4:                                                    # steam
			var ph := fposmod(_t * 0.45 + pf / 4.0 + _h(sd, 42), 1.0)
			var px := x + w * (0.25 + 0.5 * _h(sd + pf, 43))
			draw_circle(Vector2(px + sin(ph * 6.0 + pf) * 4.0, fl - 18.0 - ph * 34.0), 4.0 + ph * 8.0, Color(0.95, 0.95, 1.0, (1.0 - ph) * 0.22))

	func _shop(x: float, w: float, fl: float, sd: int, c: Color, font: Font) -> void:
		var flick := 1.0 if _h(sd, 20) > 0.25 else (0.4 + 0.6 * absf(sin(_t * 7.0 + sd)))
		_board(x, w, fl, SHOP[sd % SHOP.size()], c, font, flick)
		var frame := Color(0.2, 0.19, 0.24)
		draw_rect(Rect2(x + 3.0, fl - 43.0, w - 6.0, 43.0), Color(0.04, 0.04, 0.07))
		var dx := x + w - 22.0
		draw_rect(Rect2(dx - 1.0, fl - 33.0, 17.0, 33.0), frame)
		draw_rect(Rect2(dx, fl - 32.0, 15.0, 32.0), Color(0.08, 0.09, 0.14))
		draw_rect(Rect2(dx + 1.5, fl - 30.0, 12.0, 20.0), Color(c.lerp(Color(1.0, 0.9, 0.7), 0.5), 0.6))
		var gw := dx - 5.0 - (x + 6.0)
		draw_rect(Rect2(x + 5.0, fl - 34.0, gw + 2.0, 29.0), frame)
		draw_rect(Rect2(x + 6.0, fl - 33.0, gw, 27.0), Color(c.lerp(Color(1.0, 0.9, 0.7), 0.45), 0.8))
		for sh in 2:
			var yy := fl - 22.0 + sh * 10.0
			draw_rect(Rect2(x + 8.0, yy, gw - 4.0, 1.0), Color(0.08, 0.06, 0.08, 0.7))
			for q in int((gw - 6.0) / 6.0):
				var gh := 3.0 + _h(sd + sh * 11 + q, 25) * 5.0
				draw_rect(Rect2(x + 9.0 + q * 6.0, yy - gh, 4.0, gh), Color(0.08, 0.06, 0.1, 0.75))
		for br in range(0, int(gw), 5):                                 # bars before the glass
			draw_rect(Rect2(x + 6.0 + br, fl - 33.0, 1.0, 27.0), Color(0.1, 0.1, 0.14, 0.7))
		draw_rect(Rect2(x + 5.0, fl - 5.0, gw + 2.0, 5.0), frame.darkened(0.3))

	func _shutter(x: float, w: float, fl: float, sd: int, c: Color) -> void:
		draw_rect(Rect2(x + 3.0, fl - 56.0, w - 6.0, 12.0), Color(0.06, 0.06, 0.09))
		draw_rect(Rect2(x + 4.0, fl - 43.0, w - 8.0, 43.0), Color(0.26, 0.27, 0.32))
		for sl in range(0, 43, 3):
			draw_rect(Rect2(x + 4.0, fl - 43.0 + sl, w - 8.0, 1.0), Color(0.17, 0.18, 0.22))
		var tag := PackedVector2Array()                                 # a scrawl across it
		for k in 9:
			tag.append(Vector2(x + 10.0 + k * (w - 22.0) / 8.0, fl - 22.0 + sin(k * 1.7 + sd) * 9.0 - (k % 2) * 6.0))
		draw_polyline(tag, Color(c, 0.85), 2.0)
		draw_polyline(tag, Color(c, 0.2), 5.0)
		for ps in 3:                                                    # bills pasted on it
			var px := x + 8.0 + _h(sd + ps, 71) * (w - 30.0)
			draw_rect(Rect2(px, fl - 40.0 + _h(sd + ps, 72) * 8.0, 11.0, 14.0), Color(0.86, 0.82, 0.7).darkened(_h(sd + ps, 73) * 0.3))
			draw_rect(Rect2(px + 2.0, fl - 36.0 + _h(sd + ps, 72) * 8.0, 7.0, 4.0), Color(NEON[(sd + ps) % NEON.size()], 0.8))

	func _arcade(x: float, w: float, fl: float, sd: int, c: Color, font: Font) -> void:
		_board(x, w, fl, "ARCADE", c, font, 0.6 + 0.4 * absf(sin(_t * 3.0)))
		draw_rect(Rect2(x + 3.0, fl - 43.0, w - 6.0, 43.0), Color(0.03, 0.03, 0.07))
		for cb in int((w - 10.0) / 16.0):
			var cx := x + 7.0 + cb * 16.0
			var sc: Color = NEON[(sd + cb * 2) % NEON.size()]
			draw_rect(Rect2(cx, fl - 36.0, 12.0, 34.0), Color(0.1, 0.1, 0.16))
			draw_rect(Rect2(cx + 1.5, fl - 33.0, 9.0, 9.0), Color(sc, 0.5 + 0.5 * absf(sin(_t * (2.0 + cb) + cb))))
			draw_rect(Rect2(cx + 2.5, fl - 31.0 + fposmod(_t * 5.0 + cb, 5.0), 3.0, 2.0), Color(1, 1, 1, 0.7))
			draw_rect(Rect2(cx + 2.0, fl - 20.0, 8.0, 3.0), Color(0.2, 0.2, 0.26))
			draw_rect(Rect2(cx - 2.0, fl - 38.0, 16.0, 16.0), Color(sc, 0.06))

	## The way back to the plaza: steps up between the houses, the light of the plaza beyond.
	func _gate(x: float, w: float, fl: float, font: Font) -> void:
		var green := Color(0.35, 1.0, 0.55)
		draw_rect(Rect2(x, 0.0, w, fl - 48.0), Color(0.05, 0.05, 0.09))
		draw_rect(Rect2(x + 14.0, fl - 150.0, w - 28.0, 100.0), Color(0.3, 0.3, 0.44, 0.5))            # the plaza's glow, far up the steps
		draw_rect(Rect2(x + 24.0, fl - 140.0, w - 48.0, 60.0), Color(0.6, 0.5, 0.8, 0.35))
		for sp in 9:
			var yy := fl - 48.0 - sp * 8.0
			var inset := sp * 3.0
			draw_rect(Rect2(x + inset, yy - 8.0, w - inset * 2.0, 8.0), Color(0.2, 0.2, 0.28).lightened(sp * 0.03))
			draw_rect(Rect2(x + inset, yy - 8.0, w - inset * 2.0, 1.0), Color(green, 0.5 - sp * 0.04))
		draw_rect(Rect2(x, fl - 70.0, 4.0, 70.0), Color(0.12, 0.12, 0.18))
		draw_rect(Rect2(x + w - 4.0, fl - 70.0, 4.0, 70.0), Color(0.12, 0.12, 0.18))
		draw_rect(Rect2(x + 1.5, fl - 66.0, 1.5, 60.0), Color(green, 0.85))
		draw_rect(Rect2(x + w - 3.0, fl - 66.0, 1.5, 60.0), Color(1.0, 0.36, 0.66, 0.85))
		draw_rect(Rect2(x - 6.0, fl - 84.0, w + 12.0, 14.0), Color(0.02, 0.03, 0.05))
		draw_rect(Rect2(x - 6.0, fl - 84.0, w + 12.0, 14.0), Color(green, 0.9), false, 1.0)
		draw_string(font, Vector2(x - 6.0, fl - 73.5), "COMMERCIAL DISTRICT", HORIZONTAL_ALIGNMENT_CENTER, w + 12.0, 8, Color(0.75, 1.0, 0.85))

	## The Static Feedback's front: brick, bills, a doorway with stairs down into red light, its name in neon.
	func _bar(x: float, w: float, fl: float, font: Font) -> void:
		var pink := Color(1.0, 0.36, 0.66)
		var cyan := Color(0.3, 0.9, 1.0)
		draw_rect(Rect2(x, 0.0, w, fl), Color(0.17, 0.09, 0.09))
		for by in range(0, int(fl), 6):
			draw_rect(Rect2(x, by, w, 1.0), Color(0.09, 0.05, 0.06))
			for bx in range(int(x) + (4 if (by / 6) % 2 == 0 else 10), int(x + w), 12):
				draw_rect(Rect2(bx, by, 1.0, 6.0), Color(0.09, 0.05, 0.06))
		for ps in 9:                                                    # bills
			var px := x + 6.0 + _h(ps, 81) * (w - 24.0)
			var py := fl - 60.0 + _h(ps, 82) * 44.0
			if absf(px - (x + 86.0)) < 26.0 and py > fl - 46.0:
				continue
			draw_rect(Rect2(px, py, 12.0, 15.0), Color(0.86, 0.8, 0.66).darkened(_h(ps, 83) * 0.35))
			draw_rect(Rect2(px + 2.0, py + 3.0, 8.0, 5.0), Color(NEON[ps % NEON.size()], 0.8))
			draw_rect(Rect2(px + 2.0, py + 10.0, 6.0, 1.0), Color(0.2, 0.15, 0.15))
		var dx := x + 64.0                                              # the doorway, stairs going down
		draw_rect(Rect2(dx - 3.0, fl - 46.0, 60.0, 46.0), Color(0.07, 0.06, 0.08))
		draw_rect(Rect2(dx, fl - 43.0, 54.0, 43.0), Color(0.03, 0.01, 0.02))
		for sp in 7:
			draw_rect(Rect2(dx + sp * 2.5, fl - 6.0 - sp * 5.5, 54.0 - sp * 5.0, 5.5), Color(0.5, 0.08, 0.12, 0.5 - sp * 0.06))
			draw_rect(Rect2(dx + sp * 2.5, fl - 6.0 - sp * 5.5, 54.0 - sp * 5.0, 1.0), Color(1.0, 0.3, 0.35, 0.6 - sp * 0.07))
		var beat := absf(sin(_t * 4.4))
		if night > 0.5:                                                 # at night the cellar thumps
			draw_rect(Rect2(dx, fl - 43.0, 54.0, 43.0), Color(1.0, 0.2, 0.4, 0.1 * beat))
		var f1 := 1.0 if fposmod(_t, 5.0) > 0.25 else 0.3
		draw_rect(Rect2(x + 8.0, fl - 108.0, w - 16.0, 50.0), Color(0.02, 0.02, 0.05))
		draw_string(font, Vector2(x + 8.0, fl - 88.0), "STATIC", HORIZONTAL_ALIGNMENT_CENTER, w - 16.0, 20, Color(pink.lightened(0.25), f1))
		draw_string(font, Vector2(x + 8.0, fl - 64.0), "FEEDBACK", HORIZONTAL_ALIGNMENT_CENTER, w - 16.0, 16, Color(cyan.lightened(0.25), 0.9))
		var wave := PackedVector2Array()
		for k in 25:
			wave.append(Vector2(x + 16.0 + k * (w - 32.0) / 24.0, fl - 82.0 + sin(k * 1.9 + _t * 6.0) * (2.0 + 3.0 * absf(sin(k * 0.7 + _t)))))
		draw_polyline(wave, Color(1.0, 0.95, 0.6, 0.9), 1.0)
		draw_rect(Rect2(x + 8.0, fl - 108.0, w - 16.0, 50.0), Color(pink, 0.8 * f1), false, 1.5)
		draw_rect(Rect2(x + 2.0, fl - 114.0, w - 4.0, 62.0), Color(pink, 0.05))
		draw_rect(Rect2(x + 10.0, fl - 40.0, 44.0, 11.0), Color(0.02, 0.02, 0.05))
		draw_rect(Rect2(x + 10.0, fl - 40.0, 44.0, 11.0), Color(1.0, 0.85, 0.3, 0.9), false, 1.0)
		draw_string(font, Vector2(x + 10.0, fl - 31.5), "LIVE AFTER DARK", HORIZONTAL_ALIGNMENT_CENTER, 44.0, 5, Color(1.0, 0.9, 0.5))

	## Cables from house to house, small lamps on them.
	func _cables() -> void:
		var w := float(Gen.AW * GroundMap.TILE)
		for c in 7:
			var y0 := 40.0 + c * 22.0
			var pts := PackedVector2Array()
			var x0 := _h(c, 91) * 120.0
			var span := 240.0 + _h(c, 92) * 200.0
			var xx := x0
			while xx < w:
				for k in 9:
					var u := k / 8.0
					pts.append(Vector2(xx + u * span, y0 + sin(u * PI) * 14.0))
				xx += span
			draw_polyline(pts, Color(0.03, 0.03, 0.05, 0.9), 1.0)

	## The wet street: the signs lying in it in long streaks, puddles.
	func _floor() -> void:
		var fl := float(Gen.A_F0 * GroundMap.TILE)
		var fb := float((Gen.A_F1 + 1) * GroundMap.TILE)
		for f in fronts:
			var x := float(f["x"])
			var w := float(f["w"])
			var c: Color = f["col"]
			var sd := int(f["seed"])
			if String(f["kind"]) == "bar":
				c = Color(1.0, 0.36, 0.66)
			elif String(f["kind"]) == "gate":
				c = Color(0.35, 1.0, 0.55)
			for s in 5:
				var sx := x + 6.0 + _h(sd + s, 51) * (w - 20.0)
				var sw := 4.0 + _h(sd + s, 52) * 12.0
				var sl := 26.0 + _h(sd + s, 53) * 70.0
				var a := 0.1 + 0.12 * _h(sd + s, 54) + 0.03 * sin(_t * 2.0 + sd + s)
				draw_rect(Rect2(sx, fl + 2.0, sw, sl), Color(c, a))
				draw_rect(Rect2(sx + sw * 0.3, fl + 2.0, sw * 0.4, sl * 0.6), Color(c.lightened(0.4), a))
		for p in 46:
			var pp := Vector2(20.0 + _h(p, 55) * (Gen.AW * GroundMap.TILE - 40.0), fl + 14.0 + _h(p, 56) * (fb - fl - 24.0))
			var pc: Color = NEON[p % NEON.size()]
			var pts := PackedVector2Array()
			var rx := 8.0 + _h(p, 57) * 14.0
			for k in 12:
				pts.append(pp + Vector2(cos(k * TAU / 12.0) * rx, sin(k * TAU / 12.0) * rx * 0.3))
			draw_colored_polygon(pts, Color(pc, 0.17))
			draw_rect(Rect2(pp.x - rx * 0.5, pp.y - 0.5, rx, 1.0), Color(1, 1, 1, 0.08 + 0.05 * sin(_t * 3.0 + p)))

	## Over the people: lanterns on lines across the street, the roofs of the booths along its south side (sheet
	## iron, tarps, vents steaming, a line of neon), a craft passing with its searchlight.
	func _over() -> void:
		var w := float(Gen.AW * GroundMap.TILE)
		var fl := float(Gen.A_F0 * GroundMap.TILE)
		var fb := float((Gen.A_F1 + 1) * GroundMap.TILE)
		var bottom := float(Gen.AH * GroundMap.TILE)
		for ln in 9:
			var x0 := 60.0 + ln * 168.0 + _h(ln, 31) * 60.0
			var x1 := x0 + 50.0 - _h(ln, 32) * 100.0
			var pts := PackedVector2Array()
			for k in 13:
				var u := k / 12.0
				pts.append(Vector2(lerpf(x0, x1, u) + sin(_t * 0.8 + ln) * 1.5 * sin(u * PI), lerpf(fl - 50.0, fb + 6.0, u) + sin(u * PI) * 10.0))
			draw_polyline(pts, Color(0.03, 0.03, 0.05), 1.0)
			for k2 in range(1, 12):
				var lc: Color = NEON[(k2 + ln) % NEON.size()]
				draw_circle(pts[k2] + Vector2(0.0, 3.0), 5.0, Color(lc, 0.14))
				draw_rect(Rect2(pts[k2].x - 2.0, pts[k2].y + 1.0, 4.0, 5.0), lc)
		# the booths' roofs
		var x := -6.0
		var i := 0
		while x < w:
			var rw := 70.0 + _h(i, 33) * 70.0
			var jit := _h(i, 34) * 6.0
			var tone := Color(0.16, 0.16, 0.2).lerp([Color(0.3, 0.14, 0.12), Color(0.12, 0.22, 0.24), Color(0.24, 0.2, 0.12), Color(0.16, 0.14, 0.26)][i % 4], 0.5)
			var r := Rect2(x, fb + jit, rw - 3.0, bottom - fb + 40.0)
			draw_rect(Rect2(r.position + Vector2(3.0, 3.0), r.size), Color(0, 0, 0, 0.4))
			draw_rect(r, tone)
			for st in range(int(r.position.x) + 4, int(r.end.x), 5):
				draw_rect(Rect2(st, r.position.y + 3.0, 1.0, r.size.y), tone.darkened(0.25))
			draw_rect(Rect2(r.position, Vector2(r.size.x, 3.0)), tone.lightened(0.3))
			var nc: Color = NEON[(i * 2 + 1) % NEON.size()]
			draw_rect(Rect2(r.position.x + 1.0, r.position.y + 0.5, r.size.x - 2.0, 1.5), Color(nc, 0.9))
			draw_rect(Rect2(r.position.x + 1.0, r.position.y - 3.0, r.size.x - 2.0, 3.0), Color(nc, 0.14))
			draw_rect(Rect2(r.position.x + 4.0, r.position.y - 10.0, r.size.x - 8.0, 11.0), nc.darkened(0.5))      # its awning out over the street
			for aw in range(int(r.position.x) + 4, int(r.end.x) - 6, 8):
				draw_rect(Rect2(aw, r.position.y - 10.0, 4.0, 11.0), nc.darkened(0.25))
			draw_rect(Rect2(r.position.x + 4.0, r.position.y - 11.0, r.size.x - 8.0, 1.5), Color(nc, 0.85))
			for lm in range(int(r.position.x) + 10, int(r.end.x) - 8, 14):
				draw_circle(Vector2(lm, r.position.y - 13.0), 4.0, Color(1.0, 0.85, 0.5, 0.14))
				draw_circle(Vector2(lm, r.position.y - 13.0), 1.5, Color(1.0, 0.9, 0.6))
			if i % 3 == 0:                                              # a tarp
				draw_rect(Rect2(r.position.x + 8.0, r.position.y + 14.0, r.size.x - 20.0, 30.0), nc.darkened(0.55))
				draw_rect(Rect2(r.position.x + 8.0, r.position.y + 14.0, r.size.x - 20.0, 2.0), nc.darkened(0.3))
			if i % 3 == 1:                                              # a vent, steaming
				var vp := Vector2(r.position.x + r.size.x * 0.5, r.position.y + 22.0)
				draw_rect(Rect2(vp - Vector2(6, 6), Vector2(12, 12)), Color(0.4, 0.42, 0.48))
				for pf in 3:
					var ph := fposmod(_t * 0.5 + pf / 3.0 + _h(i, 35), 1.0)
					draw_circle(vp + Vector2(sin(ph * 6.0 + i) * 4.0, -ph * 26.0), 4.0 + ph * 7.0, Color(0.92, 0.94, 1.0, (1.0 - ph) * 0.28))
			x += rw
			i += 1
		# a craft overhead, its searchlight on the street
		var cyc := fposmod(_t, 26.0)
		if cyc < 9.0:
			var cx := lerpf(-120.0, w + 120.0, cyc / 9.0)
			var cy := fl + 30.0 + sin(_t * 0.7) * 10.0
			var sp := Vector2(cx - 30.0, cy + 70.0)
			var beam := PackedVector2Array([Vector2(cx - 6.0, cy + 6.0), Vector2(cx + 6.0, cy + 6.0), sp + Vector2(34.0, 0.0), sp + Vector2(-34.0, 0.0)])
			draw_colored_polygon(beam, Color(0.85, 0.95, 1.0, 0.07))
			var ell := PackedVector2Array()
			for k3 in 14:
				ell.append(sp + Vector2(cos(k3 * TAU / 14.0) * 36.0, sin(k3 * TAU / 14.0) * 12.0))
			draw_colored_polygon(ell, Color(0.85, 0.95, 1.0, 0.12))
			draw_rect(Rect2(cx - 34.0, cy - 8.0, 68.0, 14.0), Color(0.05, 0.05, 0.08))
			draw_rect(Rect2(cx - 22.0, cy - 13.0, 36.0, 6.0), Color(0.07, 0.07, 0.11))
			draw_rect(Rect2(cx - 34.0, cy + 4.0, 68.0, 2.0), Color(0.3, 0.9, 1.0, 0.7))
			draw_circle(Vector2(cx + 34.0, cy - 1.0), 2.5, Color(1.0, 0.95, 0.8))
			draw_circle(Vector2(cx - 34.0, cy - 1.0), 2.0, Color(1.0, 0.25, 0.2) if int(_t * 4.0) % 2 == 0 else Color(0.4, 0.1, 0.1))


## The Static Feedback, drawn (art px). "wall": the cellar's north wall: brick, dark wood along its foot, pipes,
## bills, stickers and scrawls, behind the counter the shelves of bottles and the bar's name in neon over a line that
## never holds still, behind the stage a black cloth with the band's name, the door to the back room, the stairs'
## doorway. "stage": the stage's boards, its front with a row of small lamps, the amplifiers. Both under the people.
## "neon": over the room's darkness: the neon itself, the stage's beams at night, the haze. "prop": what one of the
## band plays (a drum kit, a guitar, a bass, a microphone), standing with them among the people.
class BarFx extends Node2D:
	const Gen = preload("res://scripts/ground/centauria_gen.gd")
	const NEON := [Color(1.0, 0.36, 0.66), Color(0.3, 0.9, 1.0), Color(1.0, 0.82, 0.25), Color(0.55, 1.0, 0.6), Color(0.72, 0.5, 1.0), Color(1.0, 0.45, 0.25)]
	const SHX := 172.0               # the shelves behind the counter: from here …
	const SHW := 168.0               # … this wide
	const DOORX := 357.0             # the door to the back room
	const STX := 400.0               # the stairs' doorway (4 tiles wide)
	var part := "wall"
	var prop := ""
	var night := 0.0
	var _t := 0.0
	var _acc := 0.0

	func _process(dt: float) -> void:
		_t += dt
		_acc += dt
		if _acc > 0.07:
			_acc = 0.0
			queue_redraw()

	func _h(i: int, salt: int) -> float:
		return Gen.TowerArt.hsh(i, salt)

	func _draw() -> void:
		match part:
			"wall":
				_wall()
			"neon":
				_neon()
			"stage":
				_stage()
			_:
				_prop()

	## The bar's name, the line under it, the small signs (the wall draws them; the neon draws them again, bright).
	func _signs(font: Font, fl: float) -> void:
		var pink := Color(1.0, 0.36, 0.66)
		var cyan := Color(0.3, 0.9, 1.0)
		var f1 := 1.0 if fposmod(_t, 6.0) > 0.3 else 0.35
		draw_string(font, Vector2(SHX + 4.0, 31.0), "STATIC FEEDBACK", HORIZONTAL_ALIGNMENT_CENTER, SHW - 8.0, 12, Color(pink.lightened(0.3), f1))
		var wave := PackedVector2Array()
		for k2 in 34:
			wave.append(Vector2(SHX + 10.0 + k2 * 4.5, 39.0 + sin(k2 * 1.7 + _t * 7.0) * (1.5 + 3.0 * absf(sin(k2 * 0.45 + _t * 1.3)))))
		draw_polyline(wave, Color(cyan.lightened(0.3), 0.95), 1.0)
		draw_rect(Rect2(SHX + 4.0, 16.0, SHW - 8.0, 32.0), Color(pink, 0.9 * f1), false, 1.5)
		draw_rect(Rect2(118.0, 22.0, 44.0, 12.0), Color(cyan, 0.95), false, 1.0)
		draw_string(font, Vector2(118.0, 31.0), "NO REQUESTS", HORIZONTAL_ALIGNMENT_CENTER, 44.0, 6, Color(0.7, 0.97, 1.0))
		draw_rect(Rect2(346.0, 24.0, 40.0, 12.0), Color(1.0, 0.85, 0.3, 0.95), false, 1.0)
		draw_string(font, Vector2(346.0, 33.0), "CASH ONLY", HORIZONTAL_ALIGNMENT_CENTER, 40.0, 6, Color(1.0, 0.9, 0.5))
		draw_rect(Rect2(STX + 14.0, fl - 96.0, 36.0, 11.0), Color(0.45, 1.0, 0.6, 0.95), false, 1.0)
		draw_string(font, Vector2(STX + 14.0, fl - 87.5), "STREET", HORIZONTAL_ALIGNMENT_CENTER, 36.0, 6, Color(0.75, 1.0, 0.85))

	func _wall() -> void:
		var font := ThemeDB.fallback_font
		var w := float(Gen.BW * GroundMap.TILE)
		var fl := float(Gen.B_F0 * GroundMap.TILE)
		var pink := Color(1.0, 0.36, 0.66)
		var cyan := Color(0.3, 0.9, 1.0)
		draw_rect(Rect2(16.0, 0.0, w - 32.0, fl), Color(0.2, 0.11, 0.1))
		for by in range(0, int(fl), 6):
			draw_rect(Rect2(16.0, by, w - 32.0, 1.0), Color(0.11, 0.06, 0.06))
			for bx in range(16 + (4 if (by / 6) % 2 == 0 else 10), int(w) - 16, 12):
				draw_rect(Rect2(bx, by, 1.0, 6.0), Color(0.11, 0.06, 0.06))
				if _h(bx * 7 + by, 21) < 0.1:
					draw_rect(Rect2(bx + 1.0, by + 1.0, 11.0, 5.0), Color(0.28, 0.16, 0.14))
		draw_rect(Rect2(16.0, 6.0, w - 32.0, 3.0), Color(0.3, 0.32, 0.36))                    # pipes under the vault
		draw_rect(Rect2(16.0, 12.0, w - 32.0, 2.0), Color(0.24, 0.2, 0.18))
		draw_rect(Rect2(112.0, fl - 30.0, w - 128.0, 30.0), Color(0.15, 0.09, 0.06))          # dark wood along its foot
		for pn in range(116, int(w) - 16, 14):
			draw_rect(Rect2(pn, fl - 28.0, 1.0, 28.0), Color(0.09, 0.05, 0.04))
		draw_rect(Rect2(112.0, fl - 31.0, w - 128.0, 2.0), Color(0.26, 0.16, 0.1))
		# behind the stage: a black cloth, the band's name on it; the lamps over the stage
		draw_rect(Rect2(16.0, 14.0, 96.0, fl - 14.0), Color(0.04, 0.04, 0.06))
		for fd in range(22, 112, 9):
			draw_rect(Rect2(fd, 14.0, 1.0, fl - 14.0), Color(0.09, 0.08, 0.1))
		draw_string(font, Vector2(16.0, 46.0), "THE HULL", HORIZONTAL_ALIGNMENT_CENTER, 96.0, 12, Color(0.92, 0.9, 0.84))
		draw_string(font, Vector2(16.0, 62.0), "BREACH", HORIZONTAL_ALIGNMENT_CENTER, 96.0, 12, Color(1.0, 0.3, 0.3))
		for lr in 4:
			draw_rect(Rect2(25.0 + lr * 24.0, 16.0, 6.0, 6.0), Color(0.1, 0.1, 0.12))
			draw_circle(Vector2(28.0 + lr * 24.0, 24.0), 2.5, NEON[lr % NEON.size()] if night > 0.5 else Color(0.2, 0.2, 0.24))
		# bills, stickers and scrawls over the brick
		for ps in 40:
			var px := 116.0 + _h(ps, 81) * (w - 150.0)
			var py := 18.0 + _h(ps, 82) * (fl - 54.0)
			if (px > SHX - 14.0 and px < SHX + SHW + 4.0) or (px > STX - 16.0) or (px > DOORX - 14.0 and py > fl - 62.0) or (px > 134.0 and px < 166.0 and py > 52.0) \
					or (px > 336.0 and px < 392.0 and py > 34.0):
				continue
			draw_rect(Rect2(px, py, 11.0, 14.0), Color(0.86, 0.8, 0.66).darkened(_h(ps, 83) * 0.45))
			draw_rect(Rect2(px + 2.0, py + 2.0, 7.0, 5.0), Color(NEON[ps % NEON.size()], 0.8))
			draw_rect(Rect2(px + 2.0, py + 9.0, 6.0, 1.0), Color(0.2, 0.15, 0.15))
		for sk in 60:
			var skx := 114.0 + _h(sk, 84) * (w - 134.0)
			var sky := 16.0 + _h(sk, 85) * (fl - 50.0)
			if skx > SHX - 6.0 and skx < SHX + SHW + 2.0:
				continue
			draw_rect(Rect2(skx, sky, 5.0, 3.5), Color(NEON[(sk * 3) % NEON.size()], 0.75))
		for tg in 3:
			var tag := PackedVector2Array()
			var tx := 120.0 if tg == 0 else (346.0 if tg == 1 else STX + 6.0)
			for k in 7:
				tag.append(Vector2(tx + k * 5.0, 54.0 + tg * 5.0 + sin(k * 2.1 + tg) * 7.0 - (k % 2) * 4.0))
			if tg == 0:
				draw_polyline(tag, Color(NEON[(tg + 1) % NEON.size()], 0.8), 1.5)
		# behind the counter: shelves of bottles; over them the name
		draw_rect(Rect2(SHX, 52.0, SHW, fl - 52.0), Color(0.07, 0.05, 0.07))
		for sh in 3:
			var yy := 70.0 + sh * 14.0
			draw_rect(Rect2(SHX + 2.0, yy, SHW - 4.0, 2.0), Color(0.3, 0.2, 0.16))
			draw_rect(Rect2(SHX + 2.0, yy - 12.0, SHW - 4.0, 12.0), Color(pink if sh % 2 == 0 else cyan, 0.07))
			for b in 23:
				var bh := 6.0 + _h(sh * 40 + b, 86) * 5.0
				draw_rect(Rect2(SHX + 4.0 + b * 7.1, yy - bh, 3.5, bh), Color(NEON[int(_h(sh * 40 + b, 87) * 6.0) % 6], 0.85))
				draw_rect(Rect2(SHX + 5.0 + b * 7.1, yy - bh - 2.0, 1.5, 2.0), Color(0.8, 0.8, 0.85))
		draw_rect(Rect2(SHX + 4.0, 16.0, SHW - 8.0, 32.0), Color(0.02, 0.02, 0.05))
		draw_rect(Rect2(118.0, 22.0, 44.0, 12.0), Color(0.02, 0.02, 0.05))
		draw_rect(Rect2(346.0, 24.0, 40.0, 12.0), Color(0.02, 0.02, 0.05))
		# the door to the back room
		draw_rect(Rect2(DOORX - 3.0, fl - 46.0, 40.0, 46.0), Color(0.08, 0.08, 0.1))
		draw_rect(Rect2(DOORX, fl - 42.0, 34.0, 42.0), Color(0.22, 0.24, 0.28))
		draw_rect(Rect2(DOORX, fl - 42.0, 34.0, 1.5), Color(0.34, 0.36, 0.42))
		for rv in 4:
			draw_circle(Vector2(DOORX + 4.0 + rv * 8.6, fl - 36.0), 1.0, Color(0.12, 0.12, 0.14))
		draw_string(font, Vector2(DOORX, fl - 22.0), "PRIVATE", HORIZONTAL_ALIGNMENT_CENTER, 34.0, 6, Color(0.9, 0.86, 0.7))
		draw_rect(Rect2(DOORX + 29.0, fl - 20.0, 3.0, 5.0), Color(1.0, 0.25, 0.2))
		# the stairs' doorway: the street's light falling down them
		draw_rect(Rect2(STX - 4.0, fl - 82.0, 72.0, 50.0), Color(0.07, 0.06, 0.08))
		draw_rect(Rect2(STX, fl - 78.0, 64.0, 46.0), Color(0.05, 0.07, 0.12))
		for sp in 8:
			draw_rect(Rect2(STX + sp * 1.5, fl - 34.0 - sp * 5.5, 64.0 - sp * 3.0, 5.5), Color(0.2, 0.3, 0.44, 0.35 + sp * 0.06))
			draw_rect(Rect2(STX + sp * 1.5, fl - 34.0 - sp * 5.5, 64.0 - sp * 3.0, 1.0), Color(cyan, 0.3 + sp * 0.06))
		draw_rect(Rect2(STX + 14.0, fl - 96.0, 36.0, 11.0), Color(0.02, 0.03, 0.05))
		_signs(font, fl)

	## Over the room's darkness: tubes of neon along the wall, the name and the signs once more, an arrow to the
	## stage, a bolt, "LOUD", the bottles catching the light; at night the stage's lamps and their beams; the haze.
	func _neon() -> void:
		var font := ThemeDB.fallback_font
		var w := float(Gen.BW * GroundMap.TILE)
		var fl := float(Gen.B_F0 * GroundMap.TILE)
		var bot := float((Gen.B_F1 + 1) * GroundMap.TILE)
		var pink := Color(1.0, 0.36, 0.66)
		var cyan := Color(0.3, 0.9, 1.0)
		draw_rect(Rect2(116.0, 9.0, w - 136.0, 1.5), Color(pink, 0.95))
		draw_rect(Rect2(116.0, 6.0, w - 136.0, 7.0), Color(pink, 0.1))
		draw_rect(Rect2(116.0, fl - 32.0, SHX - 120.0, 1.5), Color(cyan, 0.95))
		draw_rect(Rect2(SHX + SHW + 4.0, fl - 32.0, 10.0, 1.5), Color(cyan, 0.95))
		draw_rect(Rect2(SHX - 4.0, 8.0, SHW + 8.0, 48.0), Color(pink, 0.07))
		_signs(font, fl)
		draw_polyline(PackedVector2Array([Vector2(160.0, 46.0), Vector2(124.0, 46.0), Vector2(132.0, 40.0), Vector2(124.0, 46.0), Vector2(132.0, 52.0)]), Color(1.0, 0.45, 0.25, 0.95), 1.5)
		draw_polyline(PackedVector2Array([Vector2(130.0, 60.0), Vector2(124.0, 72.0), Vector2(132.0, 71.0), Vector2(126.0, 84.0)]), Color(1.0, 0.9, 0.3, 0.6 + 0.4 * absf(sin(_t * 9.0))), 1.5)
		draw_string(font, Vector2(348.0, 52.0), "LOUD", HORIZONTAL_ALIGNMENT_LEFT, 40.0, 9, Color(0.8, 0.55, 1.0, 0.7 + 0.3 * sin(_t * 2.0)))
		for sh in 3:
			var yy := 70.0 + sh * 14.0
			draw_rect(Rect2(SHX + 2.0, yy - 12.0, SHW - 4.0, 12.0), Color(pink if sh % 2 == 0 else cyan, 0.1))
			for b in 23:
				var bh := 6.0 + _h(sh * 40 + b, 86) * 5.0
				draw_rect(Rect2(SHX + 4.0 + b * 7.1, yy - bh, 1.0, bh), Color(NEON[int(_h(sh * 40 + b, 87) * 6.0) % 6].lightened(0.3), 0.9))
		if night > 0.5:
			for lr in 4:
				var lx := 28.0 + lr * 24.0
				var lc: Color = NEON[(lr + int(_t * 0.8)) % NEON.size()]
				var sway := sin(_t * (0.8 + lr * 0.25) + lr) * 22.0
				draw_circle(Vector2(lx, 24.0), 3.0, lc)
				draw_colored_polygon(PackedVector2Array([Vector2(lx - 2.0, 24.0), Vector2(lx + 2.0, 24.0), Vector2(lx + sway + 16.0, fl + 56.0), Vector2(lx + sway - 16.0, fl + 56.0)]), Color(lc, 0.07))
		for hz in 11:
			var hx := fposmod(_h(hz, 91) * w + _t * (3.0 + _h(hz, 92) * 5.0), w + 160.0) - 80.0
			var hy := 26.0 + _h(hz, 93) * (bot - 40.0)
			var hc: Color = NEON[hz % NEON.size()].lerp(Color(0.8, 0.8, 0.9), 0.6)
			var rx := 50.0 + _h(hz, 94) * 60.0
			var ry := 10.0 + _h(hz, 95) * 12.0
			var hp := PackedVector2Array()
			for k in 14:
				hp.append(Vector2(hx + cos(k * TAU / 14.0) * rx, hy + sin(k * TAU / 14.0) * ry))
			draw_colored_polygon(hp, Color(hc, 0.055))

	## The stage: its boards (a step higher than the floor), its front with a row of small lamps, an amplifier either side.
	func _stage() -> void:
		var r := Rect2(Vector2(Gen.B_STAGE.position) * GroundMap.TILE, Vector2(Gen.B_STAGE.size) * GroundMap.TILE)
		var nightly := night > 0.5
		draw_rect(Rect2(r.position.x + 3.0, r.end.y - 2.0, r.size.x, 5.0), Color(0, 0, 0, 0.35))
		draw_rect(Rect2(r.position.x, r.position.y - 12.0, r.size.x, r.size.y), Color(0.17, 0.12, 0.1))
		for pl in range(int(r.position.x), int(r.end.x), 12):
			draw_rect(Rect2(pl, r.position.y - 12.0, 1.0, r.size.y), Color(0.1, 0.07, 0.06))
		draw_rect(Rect2(r.position.x, r.end.y - 12.0, r.size.x, 12.0), Color(0.08, 0.07, 0.08))
		draw_rect(Rect2(r.position.x, r.end.y - 12.0, r.size.x, 1.5), Color(0.3, 0.24, 0.2))
		for fl in range(int(r.position.x) + 6, int(r.end.x), 12):
			draw_circle(Vector2(fl, r.end.y - 6.0), 1.6, Color(1.0, 0.3, 0.3) if nightly and (fl / 12 + int(_t * 4.0)) % 3 != 0 else Color(0.3, 0.1, 0.1))
		for am in 2:
			var ax := r.position.x + 3.0 if am == 0 else r.end.x - 25.0
			var ay := r.position.y - 30.0
			draw_rect(Rect2(ax, ay, 22.0, 30.0), Color(0.07, 0.07, 0.09))
			draw_rect(Rect2(ax + 2.0, ay + 2.0, 18.0, 20.0), Color(0.14, 0.14, 0.17))
			for gr in range(0, 20, 3):
				draw_rect(Rect2(ax + 2.0, ay + 2.0 + gr, 18.0, 1.0), Color(0.05, 0.05, 0.07))
			draw_circle(Vector2(ax + 18.0, ay + 26.0), 1.2, Color(1.0, 0.3, 0.2) if nightly else Color(0.3, 0.1, 0.1))

	## What one of the band plays, drawn before them (the node stands at their feet).
	func _prop() -> void:
		var hit := absf(sin(_t * 8.8))
		match prop:
			"kit":
				draw_circle(Vector2(0.0, -8.0), 10.0 + hit * 0.6, Color(0.75, 0.15, 0.2))
				draw_circle(Vector2(0.0, -8.0), 7.5, Color(0.9, 0.88, 0.82))
				draw_rect(Rect2(-19.0, -20.0, 11.0, 8.0), Color(0.75, 0.15, 0.2))
				draw_rect(Rect2(8.0, -20.0, 11.0, 8.0), Color(0.75, 0.15, 0.2))
				draw_rect(Rect2(-19.0, -20.0, 11.0, 1.5), Color(0.9, 0.88, 0.82))
				draw_rect(Rect2(8.0, -20.0, 11.0, 1.5), Color(0.9, 0.88, 0.82))
				draw_rect(Rect2(-23.0, -30.0 + hit * 1.5, 13.0, 2.0), Color(0.85, 0.75, 0.35))
				draw_rect(Rect2(11.0, -32.0 - hit * 1.5, 13.0, 2.0), Color(0.85, 0.75, 0.35))
				draw_rect(Rect2(-17.0, -28.0, 1.0, 26.0), Color(0.5, 0.52, 0.6))
				draw_rect(Rect2(17.0, -30.0, 1.0, 28.0), Color(0.5, 0.52, 0.6))
			"guitar", "bass":
				var bob := sin(_t * 4.4) * 1.0
				var body := Color(0.85, 0.2, 0.2) if prop == "guitar" else Color(0.2, 0.5, 0.85)
				draw_line(Vector2(-6.0, -10.0 + bob), Vector2(12.0, -19.0 + bob), Color(0.75, 0.56, 0.36), 2.0)
				draw_rect(Rect2(-11.0, -14.0 + bob, 9.0, 8.0), body)
				draw_rect(Rect2(-9.0, -12.0 + bob, 5.0, 4.0), body.lightened(0.35))
				draw_rect(Rect2(11.0, -21.0 + bob, 3.0, 3.0), Color(0.1, 0.1, 0.12))
			_:
				draw_rect(Rect2(6.0, -24.0, 1.0, 24.0), Color(0.6, 0.62, 0.7))
				draw_rect(Rect2(3.0, -1.0, 7.0, 1.5), Color(0.4, 0.42, 0.5))
				draw_line(Vector2(6.5, -24.0), Vector2(2.5, -26.5), Color(0.6, 0.62, 0.7), 1.0)
				draw_circle(Vector2(2.0, -27.0), 2.0, Color(0.3, 0.3, 0.36))


## Package 62, part 1 (Luz): the Grand Centauria from inside – the casino in the middle tower, six floors one over
## the other, the halls narrower the higher, joined by capsules of glass on the tower's outside (you step into one
## and ride up or down the tower: LiftRide): the lobby (reception, the cashier for Coins, a
## fountain under a chandelier of light), the machines, the tables, the track (the betting stations: a small cinema
## where the races are shown), the Aurum Bar, the VIP lounge in the tip. The higher, the wider the view through the
## glass wall: the plaza, the roofs, the whole city, the clouds from above and Lapis. Part 1 is the building: the
## tables and machines stand there, but nothing is played yet (but for the Drift table). The north wall, the view
## and what stands on the floors are drawn (CasinoFx, CasinoView).
const CAS_W := [56, 50, 50, 44, 38, 69]                              # each storey's width (tiles) …
const CAS_IW := [56, 50, 50, 44, 38, 40]                             # … its hall's (the lounge has a terrace east of its hall) …
const CAS_HH := [24, 24, 24, 24, 24, 28]                             # … and its depth
const V_T0 := 7                    # the lounge's terrace: its first row (it juts out north of the hall's wall)
const CAS_ALT := [40.0, 420.0, 760.0, 1500.0, 5080.0, 6330.0]        # how high each storey lies on the middle tower (TowerArt's units)
const C_F0 := 9                    # the storey's first row (north of it the wall of glass, drawn)
const C_F1 := 20
const CAS_FLOORS := ["Lobby", "The Machines", "The Tables", "The Track", "The Aurum Bar", "VIP Lounge"]
const VIP_NOTE := "Members only. A membership costs a great many Coins, and a word from the house."

## The house's own (dealers, bartenders, attendants): its livery, dark with gold.
static func _staff_look(rng: RandomNumberGenerator) -> Dictionary:
	var lk: Dictionary = ChibiArt.PilotArt.random_look(rng)
	lk.merge({"outfit": 1, "color1": 0, "color2": 10, "headgear": 0, "scar": 0, "tattoo": 0, "implant": 0}, true)
	return lk


## (Luz) the lounge's guests, the Cluster's one per cent: coats and jackets in white, gold, black, violet, crimson.
static func _rich_look(rng: RandomNumberGenerator) -> Dictionary:
	var lk: Dictionary = ChibiArt.PilotArt.random_look(rng)
	lk.merge({"outfit": [1, 3, 3][rng.randi() % 3], "color1": [3, 3, 10, 0, 11, 8, 4][rng.randi() % 7], "color2": [10, 10, 3, 13][rng.randi() % 4],
		"scar": 0, "tattoo": 0, "headgear": [0, 0, 0, 3, 2][rng.randi() % 5]}, true)
	return lk


## (Luz) who dances on the platforms: slim, in suits of gold, white and neon.
static func _dancer_look(rng: RandomNumberGenerator, i: int) -> Dictionary:
	var lk: Dictionary = ChibiArt.PilotArt.random_look(rng)
	lk.merge({"body": 0, "outfit": 0, "color1": [10, 3, 12, 13, 11][i % 5], "color2": [3, 10, 10, 3, 10][i % 5], "hair": [4, 2, 5, 9, 7, 8][i % 6],
		"hair_color": [5, 0, 8, 9, 4, 7][i % 6], "beard": 0 if i % 2 == 0 else [0, 1][rng.randi() % 2], "scar": 0, "headgear": 0, "implant": 0,
		"lipstick": 1 if i % 2 == 0 else 0, "eye_makeup": 3 if i % 2 == 0 else 1}, true)
	return lk


## Something that stands on a casino floor: its tiles are blocked, its picture is drawn (CasinoFx "prop").
static func _cprop(m: GroundMap, props: Array, kind: String, x: int, y: int, w: int, h: int, extra: Dictionary = {}) -> void:
	m.fill(x, y, w, h, T.BLOCK, 0)
	var p := {"kind": kind, "at": Vector2(x, y + h) * TILE, "w": float(w * TILE)}
	p.merge(extra, true)
	props.append(p)


static func build_casino(_station: Dictionary, storey: int, night: bool = false) -> GroundMap:
	storey = clampi(storey, 0, CAS_W.size() - 1)
	var W: int = CAS_W[storey]
	var H: int = CAS_HH[storey]
	var IW: int = CAS_IW[storey]                                     # (the hall itself)
	var f1: int = H - 4                                              # the floor's last row
	var m := GroundMap.new()
	MuseumGen._pal(m, {})
	m.pal["floor"] = Color(0.33, 0.26, 0.42)
	m.pal["floor2"] = Color(0.26, 0.2, 0.35)
	m.pal["carpet"] = Color(0.36, 0.12, 0.2)
	m.pal["wood"] = Color(0.3, 0.19, 0.13)
	m.pal["wall"] = Color(0.18, 0.12, 0.24)
	m.pal["frame"] = Color(0.18, 0.12, 0.24)
	m.pal["accent"] = Color(1.0, 0.82, 0.35)
	m.style = "plaza"
	m.title = "The Grand Centauria"
	m.hull_top = -9999
	m.set_meta("no_guards", true)
	m.setup(W, H)
	var GOLD := Color(1.0, 0.82, 0.35)
	var PURPLE := Color(0.72, 0.36, 1.0)
	var PINK := Color(1.0, 0.36, 0.66)
	var CYAN := Color(0.3, 0.9, 1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 6200 + storey
	var mid := IW / 2
	var props: Array = []
	m.fill(0, 0, W, H, T.CAP)
	m.fill(1, 0, IW - 2, C_F0, T.BLOCK, 0)                           # the north wall: drawn over
	m.fill(1, C_F0, IW - 2, f1 - C_F0 + 1, T.FLOOR, [0, 4, 4, 0, 3, 0][storey])
	# (Luz) the lifts: two capsules of glass in tubes on the tower's outside, at the east end of the north wall. The
	# tubes, the capsules and their doors are drawn (CasinoFx "wall" and "lift"); you step into one, north of the
	# floor's line. `cas_lifts`: the middle of each one's threshold (art px).
	var lx := IW - 8
	m.set_meta("cas_lifts", [Vector2(lx + 1, C_F0) * TILE, Vector2(lx + 4, C_F0) * TILE])
	m.decals.append({"kind": "mat", "x": lx, "y": C_F0, "w": 6, "h": 1, "col": GOLD})
	_zone(m, Rect2(lx, C_F0, 6.0, 1.4), "ctr_clift", "The lifts: the floors of the Grand Centauria", GOLD)
	m.lights.append({"pos": Vector2(lx + 3.0, C_F0 + 0.5) * TILE, "r": 56.0, "col": GOLD, "a": 0.4})
	m.spawn = Vector2(lx + 1, C_F0 + 0.45) * TILE
	m.set_meta("cas_floor", storey)
	if storey >= 1 and storey != 3:
		m.set_meta("cas_window", Rect2(24.0, 18.0, IW * TILE - 48.0, 94.0))      # the wall of glass (art px), the tubes in it
	else:
		m.set_meta("cas_views", [Rect2(lx * TILE - 2.0, 18.0, 84.0, 94.0)])          # (a wall of stone: the view only behind the tubes)
	match storey:
		0:      # the lobby: the doors to the plaza, a fountain, reception and cashier, sofas, palms
			m.fill(mid - 3, C_F1 + 1, 6, 2, T.FLOOR, 0)
			m.decals.append({"kind": "mat", "x": mid - 3, "y": C_F1 + 1, "w": 6, "h": 1, "col": PURPLE})
			m.zones.append({"rect": Rect2(Vector2(mid - 3, C_F1 + 1.2) * TILE, Vector2(6, 1.7) * TILE), "kind": "museum_go", "id": "cas_out", "to": "zplaza", "at": "from_casino",
				"title": "Out onto the plaza of the Commercial District", "col": PURPLE, "sign": Vector2(-100, -100)})
			m.set_meta("from_plaza", Vector2(mid, C_F1 + 0.2) * TILE)
			m.spawn = m.get_meta("from_plaza")
			m.decals.append({"kind": "rug", "x": mid - 2, "y": C_F0 + 6, "w": 4, "h": C_F1 - C_F0 - 5, "col": Color(0.5, 0.14, 0.3)})
			_cprop(m, props, "cfountain", mid - 3, C_F0 + 3, 6, 2, {})
			m.set_meta("cas_inlay", Vector2(mid, C_F0 + 4.2) * TILE)
			for rp in [mid - 3, mid + 2]:
				for rr in [C_F0 + 7, C_F0 + 8, C_F0 + 9, C_F0 + 10]:
					_cprop(m, props, "post", rp, rr, 1, 1, {"rope": rr < C_F0 + 10})
			m.lights.append({"pos": Vector2(mid, C_F0 + 3.5) * TILE, "r": 120.0, "col": GOLD, "a": 0.5})
			m.set_meta("cas_chandelier", Vector2(mid, C_F0 + 2.0) * TILE)
			_cprop(m, props, "desk", 5, C_F0, 7, 1, {"text": "RECEPTION", "col": PURPLE})
			m.people.append({"pos": Vector2(8.5, C_F0 - 0.05) * TILE, "dir": 0, "role": "keeper"})
			_zone(m, Rect2(5.0, C_F0 + 1.0, 7.0, 1.3), "ctr_closed", "Reception", PURPLE, {"closed": "Welcome to the Grand Centauria. The tables open soon: look around.", "id": "cas_reception"})
			_cprop(m, props, "desk", lx - 12, C_F0, 7, 1, {"text": "CASHIER", "col": GOLD})
			m.people.append({"pos": Vector2(lx - 8.5, C_F0 - 0.05) * TILE, "dir": 0, "role": "keeper"})
			_zone(m, Rect2(lx - 12.0, C_F0 + 1.0, 7.0, 1.3), "ctr_cashier", "The cashier: credits for Coins, Coins for credits", GOLD)
			m.lights.append({"pos": Vector2(lx - 8.5, C_F0 + 1.0) * TILE, "r": 60.0, "col": GOLD, "a": 0.45})
			for dm in [mid - 5, mid + 4]:
				m.people.append({"pos": Vector2(dm + 0.5, C_F1 + 0.4) * TILE, "dir": 0, "role": "keeper"})
				m.add_object({"kind": "holo_statue", "x": dm + (-3 if dm < mid else 2), "y": C_F1 - 1, "w": 2, "h": 1, "seed": 620 + dm, "species": "suit_civil"})
			for sg in [Vector2i(6, C_F0 + 5), Vector2i(W - 12, C_F0 + 5)]:
				DeckGen._seat(m, "sofa", sg.x, sg.y, 0, Color(0.42, 0.16, 0.5), rng, 0.4, 3)
				m.add_object({"kind": "round_table", "x": sg.x + 1, "y": sg.y + 2, "w": 1, "h": 1})
				DeckGen._seat(m, "sofa", sg.x, sg.y + 4, 1, Color(0.42, 0.16, 0.5), rng, 0.4, 3)
			for pp in [Vector2i(3, C_F0 + 2), Vector2i(lx - 17, C_F0 + 2), Vector2i(14, C_F1 - 2), Vector2i(W - 18, C_F1 - 2)]:
				m.add_object({"kind": "planter", "x": pp.x, "y": pp.y, "w": 3, "h": 1, "col": Color(0.4, 0.3, 0.5)})
				m.add_object({"kind": "palm", "x": pp.x, "y": pp.y - 1, "w": 3, "h": 1, "rise": 56, "seed": pp.x % 8}, false)
		1:      # the machines: rows of them back to back, stools before them
			for ry in [C_F0 + 2, C_F0 + 6, C_F0 + 10]:
				var k := 0
				for sx in range(4, lx - 2, 2):
					_cprop(m, props, "slot", sx, ry, 1, 1, {"seed": ry * 31 + sx, "col": [PINK, CYAN, GOLD, PURPLE][k % 4]})
					DeckGen._seat(m, "stool", sx, ry + 1, 1, Color(0.6, 0.2, 0.4), rng, 0.3)
					k += 1
				m.lights.append({"pos": Vector2(mid - 4, ry + 0.8) * TILE, "r": 150.0, "col": [PINK, CYAN, GOLD][(ry / 3) % 3], "a": 0.3})
				_zone(m, Rect2(4.0, ry + 1.0, lx - 6.0, 1.2), "ctr_slot", "Slot machine: play", PINK, {"id": "cas_slots_%d" % ry,
					"name": {C_F0 + 2: "Lucky Lapis", C_F0 + 6: "Comet Rush"}.get(ry, "Kiln Gold"), "mcol": [PINK, CYAN, GOLD][(ry / 3) % 3]})      # package 62, part 2: open
		2:      # the tables: two for roulette, three for cards, an oval for poker, and Drift
			var tables := [["roulette", 5, C_F0 + 3, 4], ["roulette", 15, C_F0 + 3, 4], ["cards", 26, C_F0 + 3, 3], ["cards", 34, C_F0 + 3, 3], ["cards", 30, C_F0 + 8, 3],
				["poker", 6, C_F0 + 8, 5]]
			for tb in tables:
				var tx := int(tb[1])
				var ty := int(tb[2])
				var tw := int(tb[3])
				_cprop(m, props, String(tb[0]), tx, ty, tw, 2, {"seed": tx * 7 + ty})
				m.people.append({"pos": Vector2(tx + tw * 0.5, ty - 0.1) * TILE, "dir": 0, "role": "keeper"})
				m.lights.append({"pos": Vector2(tx + tw * 0.5, ty + 1.0) * TILE, "r": 60.0, "col": GOLD if String(tb[0]) != "poker" else CYAN, "a": 0.4})
				if String(tb[0]) == "roulette":             # package 62, part 2: the wheel turns
					_zone(m, Rect2(tx, ty + 2.0, tw, 1.2), "ctr_roulette", "Roulette: take a seat", GOLD, {"id": "cas_table_%d_%d" % [tx, ty]})
				else:
					_zone(m, Rect2(tx, ty + 2.0, tw, 1.2), "ctr_closed", {"cards": "Blackjack", "poker": "Poker table"}[String(tb[0])], GOLD,
						{"closed": "The tables open soon. The dealer only shuffles for now.", "id": "cas_table_%d_%d" % [tx, ty]})
				for np in 2:                                # (Luz) guests play at every table
					m.people.append({"pos": Vector2(tx + 0.6 + np * (tw - 1.2), ty + 2.5) * TILE, "dir": 1, "role": "keeper", "look": ChibiArt.PilotArt.random_look(rng)})
			m.add_object({"kind": "round_table", "x": 19, "y": C_F0 + 9, "w": 1, "h": 1})          # (Drift can be played already)
			DeckGen._seat(m, "chair", 18, C_F0 + 9, 3, Color(0.4, 0.2, 0.5), rng, 0.5)
			DeckGen._seat(m, "chair", 20, C_F0 + 9, 2, Color(0.4, 0.2, 0.5), rng, 0.5)
			DeckGen._drift_zone(m, Rect2(Vector2(18, C_F0 + 9.8) * TILE, Vector2(3, 1.6) * TILE))
		3:      # the track: a small cinema where the races are shown, rows of seats, the betting counters (shut for now)
			for ry2 in [C_F0 + 3, C_F0 + 5, C_F0 + 7]:
				_cprop(m, props, "seats", mid - 11, ry2, 14, 1, {})
			for cx in [2, lx - 8]:
				_cprop(m, props, "desk", cx, C_F0, 7, 1, {"text": "BETS", "col": CYAN, "shut": true})
				_zone(m, Rect2(cx, C_F0 + 1.0, 7.0, 1.3), "ctr_closed", "Betting counter", CYAN, {"closed": "No bets yet. The first races are announced soon.", "id": "cas_bets_%d" % cx})
			for ob in [[4, C_F0 + 5, 0], [4, C_F0 + 8, 1], [lx - 6, C_F0 + 5, 2], [lx - 6, C_F0 + 8, 3]]:
				_cprop(m, props, "odds", int(ob[0]), int(ob[1]), 2, 1, {"seed": int(ob[2])})
				m.lights.append({"pos": Vector2(ob[0] + 1.0, ob[1] + 1.2) * TILE, "r": 36.0, "col": CYAN, "a": 0.3})
			for st2 in [Vector2i(lx - 1, C_F0 + 5), Vector2i(lx - 1, C_F0 + 9)]:
				m.add_object({"kind": "round_table", "x": st2.x + 1, "y": st2.y, "w": 1, "h": 1})
				DeckGen._seat(m, "chair", st2.x, st2.y, 3, Color(0.2, 0.4, 0.5), rng, 0.6)
				DeckGen._seat(m, "chair", st2.x + 2, st2.y, 2, Color(0.2, 0.4, 0.5), rng, 0.6)
			m.lights.append({"pos": Vector2(mid - 4, C_F0 + 1.0) * TILE, "r": 170.0, "col": CYAN, "a": 0.3})
		4:      # the Aurum Bar: the counter under the glass, a grand piano, sofas
			m.add_object({"kind": "bar_counter", "x": 4, "y": C_F0 + 1, "w": 12, "h": 1})
			m.people.append({"pos": Vector2(10.0, C_F0 + 0.99) * TILE, "dir": 0, "role": "bartender"})
			for sx2 in range(5, 16, 2):
				DeckGen._seat(m, "stool", sx2, C_F0 + 2, 1, Color(0.7, 0.55, 0.25), rng, 0.4)
			m.lights.append({"pos": Vector2(10.0, C_F0 + 1.0) * TILE, "r": 100.0, "col": GOLD, "a": 0.45})
			_cprop(m, props, "piano", lx - 10, C_F0 + 5, 4, 2, {})
			if night:
				m.people.append({"pos": Vector2(lx - 8.0, C_F0 + 7.6) * TILE, "dir": 1, "role": "keeper"})      # somebody plays, evenings
			m.lights.append({"pos": Vector2(lx - 8.0, C_F0 + 6.0) * TILE, "r": 70.0, "col": Color(1.0, 0.9, 0.7), "a": 0.4})
			for sg2 in [Vector2i(4, C_F0 + 6), Vector2i(12, C_F0 + 6), Vector2i(lx + 1, C_F0 + 6)]:
				DeckGen._seat(m, "sofa", sg2.x, sg2.y, 0, Color(0.5, 0.4, 0.2), rng, 0.45, 3)
				m.add_object({"kind": "round_table", "x": sg2.x + 1, "y": sg2.y + 2, "w": 1, "h": 1})
				DeckGen._seat(m, "sofa", sg2.x, sg2.y + 4, 1, Color(0.5, 0.4, 0.2), rng, 0.45, 3)
				m.lights.append({"pos": Vector2(sg2.x + 1.5, sg2.y + 2.5) * TILE, "r": 44.0, "col": GOLD, "a": 0.3})
		_:      # (Luz) the VIP lounge in the tip, a club for the Cluster's one per cent. West the hall: the bar, the DJ,
			# a dance floor between platforms where the house's dancers dance, booths, and along the south the high
			# tables (roulette, blackjack, poker). East, through a wall of glass, the terrace: it juts out beyond the
			# tower's wall, a pool to its very edge, loungers, a bar, fire in bowls, the clouds below, Lapis over it all.
			var tx := IW
			var tw := W - 3 - tx
			var t0 := V_T0
			var WHITE := Color(0.92, 0.9, 0.86)
			var VELVET := Color(0.22, 0.14, 0.3)
			var VIOLET := Color(0.62, 0.34, 1.0)
			var pods: Array = []
			m.set_meta("cas_dark", [Rect2(16.0, 112.0, (IW - 2) * TILE, (f1 + 1) * TILE - 112.0), Color(0.6, 0.54, 0.74)])
			# ---- the wall of glass between hall and terrace, the way through it
			m.fill(IW - 1, 0, 1, f1 + 1, T.BLOCK, 0)
			m.fill(IW - 1, C_F0 + 5, 1, 4, T.FLOOR, 0)
			m.set_meta("cas_door", Rect2(Vector2(IW - 1, C_F0 + 5) * TILE, Vector2(1, 4) * TILE))
			m.lights.append({"pos": Vector2(IW - 0.5, C_F0 + 7.0) * TILE, "r": 46.0, "col": CYAN, "a": 0.35})
			# ---- the hall: the bar under the glass, two behind it
			m.add_object({"kind": "bar_counter", "x": 3, "y": C_F0 + 1, "w": 10, "h": 1})
			m.people.append({"pos": Vector2(5.5, C_F0 + 0.99) * TILE, "dir": 0, "role": "bartender"})
			m.people.append({"pos": Vector2(10.5, C_F0 + 0.99) * TILE, "dir": 0, "role": "keeper"})
			for sx3 in range(3, 13, 2):
				DeckGen._seat(m, "stool", sx3, C_F0 + 2, 1, GOLD.darkened(0.25), rng, 0.6)
			m.lights.append({"pos": Vector2(8.0, C_F0 + 1.2) * TILE, "r": 120.0, "col": GOLD, "a": 0.5})
			# the DJ, the dance floor, the platforms (three round the floor, two out by the pool)
			_cprop(m, props, "dj", 16, C_F0 + 1, 6, 1, {})
			var djl := _dancer_look(rng, 3)
			djl["headgear"] = 1
			m.people.append({"pos": Vector2(19.0, C_F0 + 0.95) * TILE, "dir": 0, "role": "keeper", "dance": true, "look": djl})
			var dfl := Rect2i(15, C_F0 + 3, 8, 5)
			m.set_meta("cas_dfloor", Rect2(Vector2(dfl.position) * TILE, Vector2(dfl.size) * TILE))
			for dq in [Vector2(1.0, 1.2), Vector2(3.1, 0.9), Vector2(5.3, 1.3), Vector2(6.9, 2.5), Vector2(4.5, 2.9), Vector2(2.3, 3.3), Vector2(0.9, 2.5), Vector2(6.1, 4.2), Vector2(3.5, 4.4)]:
				m.people.append({"pos": (Vector2(dfl.position) + (dq as Vector2)) * TILE, "dir": rng.randi() % 4, "role": "keeper", "dance": true, "look": _rich_look(rng)})
			m.lights.append({"pos": Vector2(17.0, C_F0 + 5.5) * TILE, "r": 90.0, "col": PINK, "a": 0.42})
			m.lights.append({"pos": Vector2(21.0, C_F0 + 5.5) * TILE, "r": 90.0, "col": CYAN, "a": 0.42})
			var pi2 := 0
			for pd in [Vector2i(12, C_F0 + 3), Vector2i(24, C_F0 + 3), Vector2i(18, C_F0 + 8), Vector2i(tx, t0 + 5), Vector2i(tx + tw - 2, t0 + 5)]:
				var pdx: int = (pd as Vector2i).x
				var pdy: int = (pd as Vector2i).y
				_cprop(m, props, "podium", pdx, pdy, 2, 1, {"col": [PINK, CYAN, GOLD, GOLD, PINK][pi2], "lift": 16.0, "seed": pi2})
				m.people.append({"pos": Vector2(pdx + 1.0, pdy + 0.44) * TILE, "dir": 0, "role": "keeper", "dance": true, "look": _dancer_look(rng, pi2)})
				m.lights.append({"pos": Vector2(pdx + 1.0, pdy + 0.6) * TILE, "r": 40.0, "col": Color(1.0, 0.92, 0.75), "a": 0.5})
				if pdx < tx:
					pods.append(Vector2(pdx + 1.0, pdy + 0.44) * TILE)
				pi2 += 1
			m.set_meta("cas_pods", pods)
			# booths in velvet along the west
			for bg in [Vector2i(2, C_F0 + 4), Vector2i(7, C_F0 + 4), Vector2i(2, C_F0 + 10), Vector2i(7, C_F0 + 10)]:
				var bgx: int = (bg as Vector2i).x
				var bgy: int = (bg as Vector2i).y
				DeckGen._seat(m, "sofa", bgx, bgy, 0, VELVET, rng, 0.55, 3)
				m.add_object({"kind": "round_table", "x": bgx + 1, "y": bgy + 2, "w": 1, "h": 1})
				DeckGen._seat(m, "sofa", bgx, bgy + 4, 1, VELVET, rng, 0.55, 3)
				m.lights.append({"pos": Vector2(bgx + 1.5, bgy + 2.5) * TILE, "r": 44.0, "col": VIOLET, "a": 0.36})
			# the high tables along the south, on a carpet of their own
			m.decals.append({"kind": "rug", "x": 13, "y": C_F0 + 10, "w": 23, "h": 5, "col": Color(0.46, 0.1, 0.22)})
			for tb2 in [["roulette", 14, 4, "High-stakes roulette"], ["cards", 22, 3, "High-stakes blackjack"], ["poker", 29, 5, "High-stakes poker"]]:
				var hx := int(tb2[1])
				var hw := int(tb2[2])
				var hy := C_F0 + 11
				_cprop(m, props, String(tb2[0]), hx, hy, hw, 2, {"seed": hx * 3, "hi": true})
				m.people.append({"pos": Vector2(hx + hw * 0.5, hy - 0.1) * TILE, "dir": 0, "role": "keeper"})
				m.lights.append({"pos": Vector2(hx + hw * 0.5, hy + 1.0) * TILE, "r": 64.0, "col": GOLD, "a": 0.5})
				if String(tb2[0]) == "roulette":            # package 62, part 2: the high wheel turns
					_zone(m, Rect2(hx, hy + 2.0, hw, 1.2), "ctr_roulette", String(tb2[3]) + ": take a seat", GOLD, {"id": "cas_high_%d" % hx, "hi": true})
				else:
					_zone(m, Rect2(hx, hy + 2.0, hw, 1.2), "ctr_closed", String(tb2[3]), GOLD, {"closed": "The high tables open soon. No stake at them is small.", "id": "cas_high_%d" % hx})
				m.people.append({"pos": Vector2(hx + hw - 0.6, hy + 2.5) * TILE, "dir": 1, "role": "keeper", "look": _rich_look(rng)})
			m.set_meta("cas_rug", Rect2(Vector2(13, C_F0 + 10) * TILE, Vector2(23, 5) * TILE))
			_cprop(m, props, "lapis", 30, C_F0 + 6, 2, 1, {})
			m.lights.append({"pos": Vector2(31.0, C_F0 + 5.6) * TILE, "r": 62.0, "col": Color(0.4, 0.7, 1.0), "a": 0.45})
			# a pyramid of glasses, pillars of light at the way out to the terrace, two of the house at the lifts
			_cprop(m, props, "glasses", 27, C_F0 + 4, 1, 1, {})
			m.lights.append({"pos": Vector2(27.5, C_F0 + 4.3) * TILE, "r": 34.0, "col": GOLD, "a": 0.45})
			for hp in [Vector2i(37, C_F0 + 3), Vector2i(37, C_F0 + 9)]:
				var hpx: int = (hp as Vector2i).x
				var hpy: int = (hp as Vector2i).y
				m.add_object({"kind": "holo_pillar", "x": hpx, "y": hpy, "w": 1, "h": 1, "col": GOLD})
				m.lights.append({"pos": Vector2(hpx + 0.5, hpy + 0.5) * TILE, "r": 40.0, "col": GOLD, "a": 0.36})
			for gx2 in [lx - 0.6, lx + 6.6]:
				var gl := _staff_look(rng)
				gl["outfit"] = 3
				gl["headgear"] = 2
				m.people.append({"pos": Vector2(float(gx2), C_F0 + 0.9) * TILE, "dir": 0, "role": "keeper", "look": gl})
			# ---- the terrace: stone, the pool along its far edge
			m.fill(tx, t0, tw, f1 - t0 + 1, T.FLOOR, 30)
			m.decals.append({"kind": "terrace", "x": tx, "y": t0, "w": tw, "h": f1 - t0 + 1, "col": Color(0.8, 0.76, 0.7)})
			var deck := Rect2(Vector2(tx, t0) * TILE, Vector2(tw, f1 - t0 + 1) * TILE)
			m.set_meta("cas_terrace", deck)
			m.set_meta("cas_open", Rect2(deck.position, deck.size + Vector2(4.0, 10.0)))
			m.set_meta("cas_canvas", Rect2(0.0, 0.0, W * TILE, H * TILE))
			m.set_meta("cas_views", [Rect2(tx * TILE, 0.0, (W - tx) * TILE, t0 * TILE), Rect2(deck.end.x, deck.position.y, W * TILE - deck.end.x, H * TILE - deck.position.y),
				Rect2(deck.position.x, deck.end.y, deck.size.x, H * TILE - deck.end.y)])
			var pool := Rect2i(tx + 2, t0, tw - 4, 4)
			m.fill(pool.position.x, pool.position.y, pool.size.x, pool.size.y, T.BLOCK, 10)
			m.set_meta("cas_pool", Rect2(Vector2(pool.position) * TILE, Vector2(pool.size) * TILE))
			_zone(m, Rect2(pool.position.x, t0 + 4.0, pool.size.x, 0.9), "ctr_closed", "The pool", CYAN, {"closed": "The members swim. You have brought nothing to swim in.", "id": "cas_pool"})
			var tl := 0                                              # (the terrace's lamps have names: they follow the day)
			for pl in 5:
				m.lights.append({"pos": Vector2(pool.position.x + 2.2 + pl * 4.4, t0 + 2.8) * TILE, "r": 64.0, "col": CYAN, "a": 0.32, "id": "ctr_t%d" % tl})
				tl += 1
			for fb in [Vector2i(tx, t0 + 1), Vector2i(tx + tw - 1, t0 + 1), Vector2i(tx, f1), Vector2i(tx + tw - 1, f1)]:
				var fbx: int = (fb as Vector2i).x
				var fby: int = (fb as Vector2i).y
				_cprop(m, props, "flame", fbx, fby, 1, 1, {"seed": fbx + fby})
				m.lights.append({"pos": Vector2(fbx + 0.5, fby + 0.2) * TILE, "r": 54.0, "col": Color(1.0, 0.62, 0.25), "a": 0.5, "flicker": true, "id": "ctr_t%d" % tl})
				tl += 1
			for sf in [tx + 3, tx + 9, tx + 15]:
				DeckGen._seat(m, "sofa", int(sf), t0 + 5, 1, WHITE, rng, 0.6, 3)          # (they look out over the pool at Lapis)
			for rt in [tx + 7, tx + 13]:
				m.add_object({"kind": "round_table", "x": int(rt), "y": t0 + 5, "w": 1, "h": 1})
			m.add_object({"kind": "bar_counter", "x": tx + 19, "y": t0 + 8, "w": 5, "h": 1})        # the pool bar
			m.people.append({"pos": Vector2(tx + 21.5, t0 + 7.99) * TILE, "dir": 0, "role": "keeper"})
			for sx4 in [tx + 19, tx + 21, tx + 23]:
				DeckGen._seat(m, "stool", int(sx4), t0 + 9, 1, WHITE, rng, 0.5)
			m.lights.append({"pos": Vector2(tx + 21.5, t0 + 8.4) * TILE, "r": 70.0, "col": GOLD, "a": 0.45, "id": "ctr_t%d" % tl})
			tl += 1
			for lg2 in [Vector2i(tx + 5, t0 + 9), Vector2i(tx + 11, t0 + 9)]:
				var lgx: int = (lg2 as Vector2i).x
				var lgy: int = (lg2 as Vector2i).y
				DeckGen._seat(m, "sofa", lgx, lgy, 0, WHITE, rng, 0.5, 3)
				m.add_object({"kind": "round_table", "x": lgx + 1, "y": lgy + 2, "w": 1, "h": 1})
				DeckGen._seat(m, "sofa", lgx, lgy + 4, 1, WHITE, rng, 0.5, 3)
				m.lights.append({"pos": Vector2(lgx + 1.5, lgy + 2.5) * TILE, "r": 44.0, "col": Color(1.0, 0.85, 0.6), "a": 0.34, "id": "ctr_t%d" % tl})
				tl += 1
			_cprop(m, props, "glasses", tx + 9, t0 + 11, 1, 1, {})
			for lg in [tx + 3, tx + 5, tx + 8, tx + 10, tx + 13, tx + 15]:
				DeckGen._seat(m, "lounger", int(lg), f1 - 1, 0, WHITE if int(lg) % 2 == 1 else GOLD.darkened(0.1), rng, 0.5)      # (over the edge: the clouds)
			for pa in [tx + 4, tx + 9, tx + 14]:
				m.add_object({"kind": "parasol", "x": int(pa), "y": f1 - 1, "w": 1, "h": 1, "col": WHITE})
			for pp3 in [Vector2i(tx + 18, t0 + 13), Vector2i(tx + 1, t0 + 14), Vector2i(tx + 21, f1)]:
				var ppx: int = (pp3 as Vector2i).x
				var ppy: int = (pp3 as Vector2i).y
				m.add_object({"kind": "planter", "x": ppx, "y": ppy, "w": 3, "h": 1, "col": Color(0.5, 0.46, 0.44)})
				m.add_object({"kind": "palm", "x": ppx, "y": ppy - 1, "w": 3, "h": 1, "rise": 56, "seed": ppx % 8}, false)
	m.set_meta("cas_props", props)
	m.set_meta("tourists", [12, 16, 16, 10, 8, 0][storey])
	DeckGen._seats(m)
	if storey == 5:
		for gx in range(2, W - 3, 4):
			for gy in [C_F0, C_F0 + 2, C_F0 + 5, C_F0 + 8, C_F0 + 9, C_F0 + 13, C_F0 + 15]:
				var wp2 := Vector2(gx + 0.5, gy + 0.5)
				if m.free_at(wp2 * TILE, 6.0):
					m.wander.append(wp2 * TILE)
	else:
		for gx in range(3, W - 2, 5):
			for gy in [C_F0 + 2, C_F0 + 5, C_F0 + 9, C_F1]:
				var wp := Vector2(gx, gy)
				if m.free_at(wp * TILE, 6.0):
					m.wander.append(wp * TILE)
	# the house's own wear its livery; the lounge's guests are the Cluster's one per cent, a dozen of them strolling
	for p in m.people:
		if (p as Dictionary).has("look"):
			continue
		if String(p.get("role", "")) in ["keeper", "bartender"]:
			p["look"] = _staff_look(rng)
		elif storey == 5:
			p["look"] = _rich_look(rng)
	if storey == 5:
		for gi in 12:
			m.people.append({"pos": m.wander[(gi * 7 + 3) % m.wander.size()], "dir": 0, "look": _rich_look(rng)})
	return m


## (Luz) what you see through the casino's wall of glass, the wider the higher the floor: the city's skyline lower and
## lower, Lapis larger, from the bar up the clouds (a Control: it cuts the picture off at its own edge).
class CasinoView extends Control:
	const Gen = preload("res://scripts/ground/centauria_gen.gd")
	var storey := 1
	var night := 0.0
	var canvas := Rect2()            # (the lounge) the whole picture's frame in the map (art px): this window shows its part of it
	var origin := Vector2.ZERO       # … this window's own corner there
	var _t := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		clip_contents = true

	func _process(dt: float) -> void:
		_t += dt
		if int(_t * 5.0) != int((_t - dt) * 5.0):
			queue_redraw()

	func _draw() -> void:
		if canvas.size.x > 0.0:
			_lounge(canvas.position - origin, canvas.size.x, canvas.size.y)
			return
		var w := size.x
		var h := size.y
		Gen.draw_sky(self, Rect2(0, 0, w, h), night, w * 0.7, h * (0.56 - storey * 0.03), h * (0.2 + storey * 0.1), _t, storey >= 4)
		var tall: float = [1.0, 0.95, 0.7, 0.5, 0.26, 0.0][storey]
		if tall > 0.0:
			draw_set_transform(Vector2(0.0, h - h * 0.5), 0.0, Vector2(0.5, 0.5))
			Gen.draw_skyline(self, w * 2.0, h, _t * 0.0, night, tall)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if storey >= 4:                                                  # the clouds: a band at the bar, a sea of them at the tip
			var base := h * (0.86 if storey == 4 else 0.62)
			draw_rect(Rect2(0.0, base + 8.0, w, h - base), Color(0.72, 0.76, 0.9, 0.5 if night > 0.5 else 0.85))
			for c in 26:
				var cx := fposmod(Gen.TowerArt.hsh(c, 3) * w * 1.3 + _t * (1.0 + Gen.TowerArt.hsh(c, 4) * 2.0), w * 1.3) - w * 0.15
				var cy := base + Gen.TowerArt.hsh(c, 5) * 14.0
				draw_circle(Vector2(cx, cy), 9.0 + Gen.TowerArt.hsh(c, 6) * 12.0, Color(0.78, 0.82, 0.95, 0.42 if night > 0.5 else 0.8))

	## (Luz) the lounge's sky: one picture for all its windows and for the air round its terrace (cw x chh, the map's
	## own size). Lapis stands huge over the terrace, out of the clouds; two of its moons hang in the hall's windows;
	## under the clouds' tops the sea of cloud from above, drifting.
	func _lounge(off: Vector2, cw: float, chh: float) -> void:
		var top := 92.0
		var dark := night > 0.5
		Gen.draw_sky(self, Rect2(off.x, off.y, cw, 150.0), night, off.x + cw * 0.775, off.y + 60.0, 56.0, _t, false)     # (it sets transforms of its own)
		draw_set_transform(off, 0.0, Vector2.ONE)
		# Glacia and Ember, far smaller, west of it
		var gl := Vector2(cw * 0.27, 46.0)
		draw_circle(gl, 15.0, Color(0.6, 0.74, 0.9, 0.16))
		draw_circle(gl, 11.0, Color(0.86, 0.93, 1.0) if dark else Color(0.9, 0.95, 1.0, 0.75))
		draw_circle(gl + Vector2(3.5, 2.5), 9.0, Color(0.5, 0.62, 0.82, 0.55 if dark else 0.3))
		draw_circle(gl + Vector2(-3.0, -3.0), 2.0, Color(0.7, 0.82, 0.95, 0.8))
		var em := Vector2(cw * 0.43, 70.0)
		draw_circle(em, 9.0, Color(1.0, 0.4, 0.15, 0.14))
		draw_circle(em, 6.0, Color(0.32, 0.1, 0.08) if dark else Color(0.5, 0.3, 0.3, 0.75))
		draw_arc(em, 5.2, -0.4, 1.9, 10, Color(1.0, 0.5, 0.15, 0.9 if dark else 0.5), 1.2)                # its lit limb, two rivers of fire
		draw_line(em + Vector2(-3.5, -1.5), em + Vector2(1.0, 1.0), Color(1.0, 0.6, 0.2, 0.85 if dark else 0.45), 0.8)
		draw_line(em + Vector2(-1.0, 2.5), em + Vector2(2.5, -2.5), Color(1.0, 0.45, 0.12, 0.7 if dark else 0.4), 0.8)
		var base := Color(0.3, 0.34, 0.52) if dark else Color(0.8, 0.84, 0.95)
		var puff := Color(0.44, 0.48, 0.68) if dark else Color(0.96, 0.97, 1.0)
		draw_rect(Rect2(0.0, top + 9.0, cw, chh - top), base)
		for c in 80:
			var cx := fposmod(Gen.TowerArt.hsh(c, 3) * cw * 1.2 + _t * (0.8 + Gen.TowerArt.hsh(c, 4) * 1.6), cw * 1.2) - cw * 0.1
			draw_circle(Vector2(cx, top + 5.0 + Gen.TowerArt.hsh(c, 5) * 12.0), 8.0 + Gen.TowerArt.hsh(c, 6) * 11.0, puff if c % 3 == 0 else base)
		for c2 in 120:
			var k := Gen.TowerArt.hsh(c2, 13)
			var cx2 := fposmod(Gen.TowerArt.hsh(c2, 11) * cw + _t * (0.5 + k), cw + 60.0) - 30.0
			var cy2 := top + 28.0 + Gen.TowerArt.hsh(c2, 12) * (chh - top - 28.0)
			draw_circle(Vector2(cx2 + 4.0, cy2 + 5.0), 8.0 + k * 15.0, Color(base.darkened(0.14), 0.3))
			draw_circle(Vector2(cx2, cy2), 9.0 + k * 20.0, Color(puff, 0.28 + 0.4 * Gen.TowerArt.hsh(c2, 14)))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The casino's floors, drawn (art px). "wall": the north wall: marble and gold, pilasters, a cornice of lamps, the
## frames of the wall of glass (the view lies behind them), and what each floor has on it: the house's name in the
## lobby, the jackpot over the machines, the screen of the track with a race running on it, the back bar. Under the
## people. "over": the lobby's chandelier of light, over them. "prop": something on the floor (a slot machine, a
## roulette table, a card table, a poker table, a desk, the piano, a row of cinema seats), standing among them.
class CasinoFx extends Node2D:
	const Gen = preload("res://scripts/ground/centauria_gen.gd")
	const NEON := [Color(1.0, 0.36, 0.66), Color(0.3, 0.9, 1.0), Color(1.0, 0.82, 0.25), Color(0.55, 1.0, 0.6), Color(0.72, 0.5, 1.0), Color(1.0, 0.45, 0.25)]
	var part := "wall"
	var storey := 0
	var night := 0.0
	var data: Dictionary = {}        # a prop's own entries (kind, w, text, col, seed, shut)
	var at := Vector2.ZERO           # "over": where the chandelier hangs; "inlay": the middle of the floor's inlay
	var open := 0.0                  # "lift": how far the capsule's doors stand open (0 … 1)
	var _t := 0.0
	var _acc := 0.0

	func _process(dt: float) -> void:
		_t += dt
		_acc += dt
		if _acc > 0.08 or part == "lift" or part == "club":
			_acc = 0.0
			queue_redraw()

	func _h(i: int, salt: int) -> float:
		return Gen.TowerArt.hsh(i, salt)

	func _draw() -> void:
		match part:
			"wall":
				_wall()
			"over":
				_chandelier()
			"inlay":
				_inlay()
			"lift":
				_lift()
			"pool":
				_pool()
			"terrace":
				_terrace()
			"tfront":
				_tfront()
			"dfloor":
				_dfloor()
			"club":
				_club()
			_:
				_prop()

	func _wall() -> void:
		var font := ThemeDB.fallback_font
		var w := float(Gen.CAS_IW[storey] * GroundMap.TILE)
		var fl := float(Gen.C_F0 * GroundMap.TILE)
		var lx := w - 8.0 * GroundMap.TILE
		var gold := Color(1.0, 0.82, 0.35)
		var marble := Color(0.17, 0.11, 0.24)
		var glass := storey >= 1 and storey != 3
		# the wall: all of it where there is no glass; round the glass its frame; the lifts' own wall stays as it is
		if glass:
			draw_rect(Rect2(16.0, 0.0, w - 32.0, 18.0), marble)
			draw_rect(Rect2(16.0, 112.0, lx - 18.0, fl - 112.0), marble)
			draw_rect(Rect2(16.0, 18.0, 8.0, 94.0), marble)
			draw_rect(Rect2(24.0, 18.0, lx - 32.0, 94.0), Color(0.6, 0.8, 1.0, 0.07))
			for gl in range(40, int(lx) - 20, 70):
				draw_line(Vector2(gl, 108.0), Vector2(gl + 26.0, 22.0), Color(1, 1, 1, 0.05), 6.0)
		else:
			draw_rect(Rect2(16.0, 0.0, lx - 18.0, fl), marble)
		# (Luz) the lifts' bay at the east end: two tubes of glass on the tower's outside, a capsule waiting in each
		var bay := marble.lightened(0.05)
		draw_rect(Rect2(lx - 8.0, 0.0, 120.0, 24.0), bay)
		draw_rect(Rect2(lx - 8.0, 24.0, 6.0, fl - 24.0), bay)
		draw_rect(Rect2(lx + 34.0, 24.0, 12.0, fl - 24.0), bay)
		draw_rect(Rect2(lx + 82.0, 24.0, 30.0, fl - 24.0), bay)
		for tc in [lx + 16.0, lx + 64.0]:
			_tube(float(tc), fl)
			draw_rect(Rect2(float(tc) - 19.0, 24.0, 1.5, fl - 24.0), gold.darkened(0.2))
			draw_rect(Rect2(float(tc) + 17.5, 24.0, 1.5, fl - 24.0), gold.darkened(0.2))
		for vn in 14:                                                   # veins in the marble
			var vx := 20.0 + _h(vn + storey * 9, 11) * (w - 50.0)
			var vy := (_h(vn, 12) * 12.0) if glass or vx > lx - 24.0 else _h(vn, 12) * (fl - 30.0)
			draw_line(Vector2(vx, vy + 2.0), Vector2(vx + 14.0, vy + 9.0), Color(0.5, 0.4, 0.6, 0.25), 1.0)
		var bays := maxi(1, int((lx - 32.0) / 96.0))
		var bw := (lx - 32.0) / bays
		for b in bays + 1:                                              # pilasters of gold
			var px := 22.0 + b * bw
			draw_rect(Rect2(px - 3.0, 8.0, 6.0, fl - 8.0), gold.darkened(0.45))
			draw_rect(Rect2(px - 3.0, 8.0, 1.5, fl - 8.0), gold.darkened(0.1))
			draw_rect(Rect2(px - 5.0, 8.0, 10.0, 3.0), gold.darkened(0.2))
			draw_rect(Rect2(px - 5.0, fl - 5.0, 10.0, 5.0), gold.darkened(0.3))
		if glass:
			draw_rect(Rect2(16.0, 17.0, lx - 24.0, 1.5), gold.darkened(0.2))
			draw_rect(Rect2(16.0, 111.0, lx - 24.0, 2.0), gold.darkened(0.2))
			draw_rect(Rect2(24.0, 64.0, lx - 32.0, 1.0), Color(gold.darkened(0.3), 0.6))
		draw_rect(Rect2(16.0, 3.0, w - 32.0, 3.0), gold.darkened(0.2))    # the cornice, lamps running along it
		var bi := 0
		for cx in range(20, int(w) - 18, 9):
			draw_circle(Vector2(cx, 4.5), 1.2, Color(1.0, 0.95, 0.7) if (bi + int(_t * 5.0)) % 4 == 0 else Color(0.5, 0.36, 0.16))
			bi += 1
		# over the tubes: the floor's number and name; beside them the six floors as lamps, yours lit
		draw_string(font, Vector2(lx - 8.0, 18.0), "%d  ·  %s" % [storey + 1, String(Gen.CAS_FLOORS[storey]).to_upper()], HORIZONTAL_ALIGNMENT_CENTER, 120.0, 7, gold.lightened(0.2))
		draw_string(font, Vector2(lx + 82.0, 38.0), "LIFTS", HORIZONTAL_ALIGNMENT_CENTER, 30.0, 6, gold)
		for fi in 6:
			var fy := 112.0 - fi * 12.0
			if fi == storey:
				draw_rect(Rect2(lx + 94.0, fy - 2.0, 13.0, 10.0), Color(gold, 0.25))
			draw_rect(Rect2(lx + 96.0, fy, 9.0, 6.0), gold.lightened(0.2) if fi == storey else Color(0.3, 0.22, 0.38))
			draw_string(font, Vector2(lx + 86.0, fy + 6.0), "%d" % (fi + 1), HORIZONTAL_ALIGNMENT_LEFT, 9.0, 6, Color(0.8, 0.7, 0.9))
		var cxm := 16.0 + (lx - 16.0) * 0.5
		if storey == 0:
			cxm = w * 0.5                                               # (the lobby: over the doors' axis)
		match storey:
			0:      # the house's name; niches of light between the pilasters
				for b2 in bays:
					var nx := 22.0 + (b2 + 0.5) * bw
					if absf(nx - cxm) < 130.0:
						continue
					draw_rect(Rect2(nx - 14.0, 40.0, 28.0, 70.0), Color(0.08, 0.05, 0.12))
					draw_circle(Vector2(nx, 40.0), 14.0, Color(0.08, 0.05, 0.12))
					draw_rect(Rect2(nx - 10.0, 46.0, 20.0, 62.0), Color(0.72, 0.36, 1.0, 0.16 + 0.06 * sin(_t * 1.3 + b2)))
					draw_rect(Rect2(nx - 1.0, 60.0, 2.0, 40.0), Color(1.0, 0.82, 0.35, 0.7))
				draw_rect(Rect2(cxm - 124.0, 26.0, 248.0, 44.0), Color(0.03, 0.02, 0.05))
				draw_rect(Rect2(cxm - 124.0, 26.0, 248.0, 44.0), gold, false, 2.0)
				draw_string(font, Vector2(cxm - 124.0, 52.0), "THE GRAND CENTAURIA", HORIZONTAL_ALIGNMENT_CENTER, 248.0, 18, gold.lightened(0.2))
				draw_string(font, Vector2(cxm - 124.0, 64.0), "CASINO  ·  BAR  ·  LOUNGE", HORIZONTAL_ALIGNMENT_CENTER, 248.0, 7, Color(0.85, 0.7, 1.0))
				var b3 := 0
				for bx in range(int(cxm) - 120, int(cxm) + 121, 10):
					draw_circle(Vector2(bx, 28.0), 1.4, Color(1.0, 0.95, 0.7) if (b3 + int(_t * 6.0)) % 3 == 0 else Color(0.5, 0.36, 0.16))
					draw_circle(Vector2(bx, 68.0), 1.4, Color(1.0, 0.95, 0.7) if (b3 + int(_t * 6.0)) % 3 == 1 else Color(0.5, 0.36, 0.16))
					b3 += 1
			1:      # the jackpot over the machines, counting
				var js: String = GameData.fmt_credits(GameState.casino_jackpot).replace(" cr", "")      # (the house's jackpot, as it stands)
				draw_rect(Rect2(cxm - 80.0, 22.0, 160.0, 30.0), Color(0.03, 0.02, 0.05))
				draw_rect(Rect2(cxm - 80.0, 22.0, 160.0, 30.0), Color(1.0, 0.36, 0.66, 0.9), false, 1.5)
				draw_string(font, Vector2(cxm - 80.0, 33.0), "JACKPOT", HORIZONTAL_ALIGNMENT_CENTER, 160.0, 8, Color(1.0, 0.6, 0.8))
				draw_string(font, Vector2(cxm - 80.0, 48.0), js + " C", HORIZONTAL_ALIGNMENT_CENTER, 160.0, 13, gold.lightened(0.2))
			3:      # the track's screen: a race running on it, the odds beside it
				var sr := Rect2(cxm - 130.0, 14.0, 260.0, 100.0)
				draw_rect(sr.grow(3.0), Color(0.02, 0.02, 0.04))
				draw_rect(sr, Color(0.02, 0.04, 0.1))
				for gy in 6:                                            # the course: lines running towards you
					var yy := sr.position.y + 50.0 + gy * gy * 1.4 + fposmod(_t * 14.0, 6.0)
					if yy < sr.end.y:
						draw_rect(Rect2(sr.position.x, yy, sr.size.x, 1.0), Color(0.3, 0.9, 1.0, 0.25))
				for gx in range(-6, 7):
					draw_line(Vector2(cxm + gx * 6.0, sr.position.y + 50.0), Vector2(cxm + gx * 42.0, sr.end.y), Color(0.3, 0.9, 1.0, 0.18), 1.0)
				draw_rect(Rect2(sr.position.x, sr.position.y, sr.size.x, 50.0), Color(0.05, 0.02, 0.12))
				for st in 30:
					draw_rect(Rect2(sr.position.x + _h(st, 21) * sr.size.x, sr.position.y + _h(st, 22) * 46.0, 1.0, 1.0), Color(1, 1, 1, 0.6))
				for rc in 5:                                            # the racers, their trails
					var rx := cxm - 100.0 + fposmod(_h(rc, 23) * 200.0 + _t * (9.0 + rc * 3.0), 200.0)
					var ry := sr.position.y + 58.0 + rc * 8.0 + sin(_t * 1.7 + rc) * 3.0
					var rcol: Color = NEON[rc % NEON.size()]
					draw_rect(Rect2(rx - 16.0, ry, 16.0, 1.5), Color(rcol, 0.4))
					draw_colored_polygon(PackedVector2Array([Vector2(rx + 7.0, ry + 0.5), Vector2(rx - 2.0, ry - 3.0), Vector2(rx - 2.0, ry + 4.0)]), rcol)
				draw_string(font, Vector2(sr.position.x + 6.0, sr.position.y + 12.0), "RIM RUN  ·  LAP %d / 7" % (1 + int(_t / 9.0) % 7), HORIZONTAL_ALIGNMENT_LEFT, 180.0, 8, Color(0.75, 0.95, 1.0))
				draw_string(font, Vector2(sr.end.x - 86.0, sr.position.y + 12.0), "FIRST BETS SOON", HORIZONTAL_ALIGNMENT_RIGHT, 80.0, 6, Color(1.0, 0.85, 0.3, 0.6 + 0.4 * absf(sin(_t * 2.0))))
				draw_rect(sr, Color(0.3, 0.9, 1.0, 0.8), false, 1.5)
			4, 5:   # the back bar under the glass: bottles in a row, lit
				var bx0 := 56.0 if storey == 4 else 40.0
				var bbw := 208.0 if storey == 4 else 176.0
				draw_rect(Rect2(bx0, 114.0, bbw, fl - 114.0), Color(0.06, 0.04, 0.08))
				for bt in int(bbw / 7.2) - 1:
					var bh := 8.0 + _h(bt, 31) * 10.0
					draw_rect(Rect2(bx0 + 4.0 + bt * 7.2, fl - 4.0 - bh, 3.5, bh), Color(NEON[int(_h(bt, 32) * 6.0) % 6].lerp(gold, 0.4), 0.9))
				draw_rect(Rect2(bx0, fl - 4.0, bbw, 2.0), gold.darkened(0.2))
				if storey == 5:     # (Luz) the lounge: who may come in, in light over the DJ; the tower's corner where the terrace begins
					var nk := 0.7 + 0.3 * absf(sin(_t * 1.7))
					draw_rect(Rect2(246.0, 28.0, 116.0, 18.0), Color(1.0, 0.36, 0.66, 0.1 * nk))
					draw_rect(Rect2(246.0, 28.0, 116.0, 18.0), Color(1.0, 0.36, 0.66, 0.9 * nk), false, 1.5)
					draw_string(font, Vector2(246.0, 41.5), "MEMBERS ONLY", HORIZONTAL_ALIGNMENT_CENTER, 116.0, 10, Color(1.0, 0.7, 0.85, nk))
					draw_rect(Rect2(w - 16.0, 0.0, 16.0, fl), marble.lightened(0.1))
					draw_rect(Rect2(w - 16.0, 0.0, 1.5, fl), gold.darkened(0.2))
					draw_rect(Rect2(w - 1.5, 0.0, 1.5, fl), gold.darkened(0.2))
					draw_rect(Rect2(w - 9.0, 16.0, 2.0, fl - 32.0), Color(0.3, 0.9, 1.0, 0.85))
					draw_rect(Rect2(w - 16.0, 3.0, 16.0, 3.0), gold.darkened(0.2))
			_:
				draw_string(font, Vector2(16.0, 13.0), "ROULETTE  ·  BLACKJACK  ·  POKER  ·  DRIFT", HORIZONTAL_ALIGNMENT_CENTER, lx - 16.0, 8, gold.lightened(0.2))

	## (Luz) one of the lifts: a tube of glass on the outside of the tower (the view lies behind it), the rail up its
	## back, and the back half of the capsule that waits in it: glass above, a panel below, its roof a ring of gold with
	## a lamp, its floor a disc of light. `cx` its middle, `fl` the floor's line (art px). Under the people.
	func _tube(cx: float, fl: float) -> void:
		var gold := Color(1.0, 0.82, 0.35)
		draw_rect(Rect2(cx - 18.0, fl - 32.0, 36.0, 32.0), Color(0.07, 0.06, 0.1))                 # (the dock's foot: solid)
		draw_rect(Rect2(cx - 18.0, 24.0, 36.0, fl - 24.0), Color(0.62, 0.86, 1.0, 0.09))
		for e in 4:                                                     # round: darker to both sides
			draw_rect(Rect2(cx - 18.0 + e * 2.0, 24.0, 2.0, fl - 24.0), Color(0.02, 0.03, 0.1, 0.3 - e * 0.07))
			draw_rect(Rect2(cx + 16.0 - e * 2.0, 24.0, 2.0, fl - 24.0), Color(0.02, 0.03, 0.1, 0.3 - e * 0.07))
		draw_rect(Rect2(cx - 10.0, 24.0, 3.0, fl - 24.0), Color(1, 1, 1, 0.09))
		draw_rect(Rect2(cx - 1.5, 24.0, 3.0, fl - 70.0), Color(0.14, 0.11, 0.2, 0.9))       # the rail, lamps running up it
		for rl in 7:
			draw_rect(Rect2(cx - 1.0, 30.0 + rl * 10.0, 2.0, 3.0), Color(0.3, 0.9, 1.0, 1.0 if int(_t * 3.0) % 7 == 6 - rl else 0.3))
		draw_set_transform(Vector2(cx, 25.0), 0.0, Vector2(1.0, 0.25))
		draw_arc(Vector2.ZERO, 18.0, 0.0, PI, 18, gold.darkened(0.1), 3.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# the capsule's back
		draw_rect(Rect2(cx - 15.0, fl - 46.0, 30.0, 14.0), Color(0.85, 0.95, 1.0, 0.13))
		draw_rect(Rect2(cx - 15.0, fl - 32.0, 30.0, 29.0), Color(0.13, 0.1, 0.19))
		draw_rect(Rect2(cx - 15.0, fl - 32.0, 30.0, 1.5), gold.darkened(0.1))
		draw_rect(Rect2(cx - 11.0, fl - 27.0, 1.5, 20.0), Color(1.0, 0.85, 0.5, 0.75))
		draw_rect(Rect2(cx + 9.5, fl - 27.0, 1.5, 20.0), Color(1.0, 0.85, 0.5, 0.75))
		draw_rect(Rect2(cx - 15.0, fl - 46.0, 30.0, 43.0), Color(1.0, 0.9, 0.7, 0.08))
		draw_set_transform(Vector2(cx, fl - 45.0), 0.0, Vector2(1.0, 0.28))
		draw_circle(Vector2.ZERO, 15.0, Color(0.2, 0.16, 0.27))
		draw_circle(Vector2.ZERO, 10.0, Color(1.0, 0.95, 0.8, 0.9))
		draw_arc(Vector2.ZERO, 16.0, PI, TAU, 16, gold, 2.5)
		draw_set_transform(Vector2(cx, fl - 4.0), 0.0, Vector2(1.0, 0.28))
		draw_circle(Vector2.ZERO, 15.5, Color(0.1, 0.08, 0.15))
		draw_arc(Vector2.ZERO, 11.5, 0.0, TAU, 20, Color(0.3, 0.9, 1.0, 0.85), 2.0)
		draw_arc(Vector2.ZERO, 16.0, PI, TAU, 16, gold, 2.5)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	## A capsule's front (art px; the node stands at the middle of its threshold, among the people): its doors of bent
	## glass sliding apart round it, its frame of gold, the lamp over it. Drawn over whoever stands inside.
	func _lift() -> void:
		var gold := Color(1.0, 0.82, 0.35)
		var y0 := -47.0
		var dw := 15.0 * (1.0 - open)
		if dw > 0.5:
			draw_rect(Rect2(-15.0, y0 + 3.0, dw, 42.0), Color(0.72, 0.9, 1.0, 0.22))
			draw_rect(Rect2(15.0 - dw, y0 + 3.0, dw, 42.0), Color(0.72, 0.9, 1.0, 0.22))
			draw_rect(Rect2(-15.0 + dw - 1.0, y0 + 3.0, 1.0, 42.0), Color(1, 1, 1, 0.5))
			draw_rect(Rect2(15.0 - dw, y0 + 3.0, 1.0, 42.0), Color(1, 1, 1, 0.5))
			draw_line(Vector2(-13.0, y0 + 32.0), Vector2(-13.0 + minf(dw, 9.0), y0 + 8.0), Color(1, 1, 1, 0.24), 2.0)
			draw_line(Vector2(15.0 - minf(dw, 9.0), y0 + 38.0), Vector2(14.0, y0 + 20.0), Color(1, 1, 1, 0.16), 1.5)
		draw_rect(Rect2(-17.0, y0, 2.0, 46.0), gold.darkened(0.15))
		draw_rect(Rect2(15.0, y0, 2.0, 46.0), gold.darkened(0.15))
		draw_rect(Rect2(-17.0, y0, 1.0, 46.0), gold.lightened(0.25))
		draw_set_transform(Vector2(0.0, y0 + 2.0), 0.0, Vector2(1.0, 0.28))
		draw_arc(Vector2.ZERO, 16.0, 0.0, PI, 16, gold, 2.5)                     # the ring round its roof, the half towards you
		draw_set_transform(Vector2(0.0, -4.0), 0.0, Vector2(1.0, 0.28))
		draw_arc(Vector2.ZERO, 16.0, 0.0, PI, 16, gold, 2.5)                     # … and round its floor
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_rect(Rect2(-15.0, -1.0, 30.0, 1.5), Color(gold, 0.55 + 0.45 * open))
		draw_rect(Rect2(-2.5, y0 - 6.0, 5.0, 2.0), Color(0.4, 1.0, 0.6) if open > 0.5 else Color(1.0, 0.6, 0.25))

	## (Luz) the lounge's pool, to the terrace's very edge (art px, under the people): deep at the far edge, lamps
	## under the water, light rippling on it, Lapis lying on it as a gleam, a few of the members swimming.
	func _pool() -> void:
		var r: Rect2 = data.get("rect", Rect2())
		var x0 := r.position.x
		var y0 := r.position.y
		var pw := r.size.x
		var ph := r.size.y
		var stone := Color(0.9, 0.87, 0.82)
		for i in 8:
			draw_rect(Rect2(x0, y0 + ph * i / 8.0, pw, ph / 8.0 + 1.0), Color(0.03, 0.34, 0.56).lerp(Color(0.14, 0.7, 0.82), i / 7.0))
		for l in 8:
			var lp := Vector2(x0 + pw * (l + 0.5) / 8.0, y0 + ph - 9.0)
			draw_circle(lp, 11.0, Color(0.6, 1.0, 1.0, 0.06 + 0.14 * night))
			draw_circle(lp, 3.5, Color(0.9, 1.0, 1.0, 0.25 + 0.4 * night))
		draw_set_transform(Vector2(x0 + pw * 0.4, y0 + 18.0), 0.0, Vector2(1.0, 0.2))
		draw_circle(Vector2.ZERO, 70.0, Color(0.3, 0.5, 1.0, 0.12 + 0.14 * night))
		draw_circle(Vector2.ZERO, 34.0, Color(0.5, 0.7, 1.0, 0.1 + 0.1 * night))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for c in 34:
			var cp := Vector2(x0 + 6.0 + _h(c, 71) * (pw - 36.0), y0 + 5.0 + _h(c, 72) * (ph - 10.0))
			var wv := _t * (0.7 + _h(c, 73)) + c
			var pts := PackedVector2Array()
			for s in 6:
				pts.append(cp + Vector2(s * 5.0, sin(wv + s * 1.3) * 1.5))
			draw_polyline(pts, Color(0.88, 1.0, 1.0, 0.2 + 0.1 * sin(wv * 1.7)), 1.0)
		var skins := [Color8(243, 199, 160), Color8(161, 106, 68), Color8(226, 174, 128), Color8(122, 80, 52), Color8(255, 226, 200)]
		var hairs := [Color8(30, 26, 28), Color8(236, 230, 210), Color8(255, 70, 170), Color8(120, 78, 44), Color8(60, 220, 240)]
		for sw in 5:
			var sp := Vector2(x0 + 34.0 + _h(sw, 81) * (pw - 68.0) + sin(_t * (0.22 + 0.07 * sw) + sw * 2.0) * 24.0, y0 + 16.0 + _h(sw, 82) * (ph - 32.0) + sin(_t * 0.5 + sw) * 3.0)
			var skin: Color = skins[sw]
			var hair: Color = hairs[sw]
			draw_set_transform(sp + Vector2(0.0, 2.0), 0.0, Vector2(1.0, 0.4))
			draw_arc(Vector2.ZERO, 6.0 + fposmod(_t * 3.0 + sw * 1.7, 6.0), 0.0, TAU, 18, Color(1, 1, 1, 0.3), 1.0)
			if sw == 1:
				draw_arc(Vector2.ZERO, 8.0, 0.0, TAU, 18, Color(1.0, 0.82, 0.35), 3.5)          # (afloat in a ring of gold)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			draw_rect(Rect2(sp.x - 4.0, sp.y - 1.5, 8.0, 3.0), skin.darkened(0.12))
			draw_circle(sp + Vector2(0.0, -4.0), 3.2, skin)
			draw_rect(Rect2(sp.x - 3.3, sp.y - 7.6, 6.6, 3.0), hair)
		draw_rect(Rect2(x0 - 3.0, y0, 3.0, ph + 3.0), stone)
		draw_rect(Rect2(x0 + pw, y0, 3.0, ph + 3.0), stone)
		draw_rect(Rect2(x0 - 3.0, y0 + ph, pw + 6.0, 3.0), stone)
		for st in 3:
			draw_rect(Rect2(x0 + 2.0, y0 + ph - 5.0 - st * 5.0, 22.0 - st * 4.0, 4.0), Color(0.75, 0.95, 0.98, 0.5 - st * 0.1))     # the steps in
		draw_rect(Rect2(x0, y0 - 4.0, pw, 3.0), Color(0.8, 0.95, 1.0, 0.25))            # the far edge: the water runs over it
		draw_rect(Rect2(x0, y0 - 1.0, pw, 2.0), Color(0.92, 1.0, 1.0, 0.9))

	## The terrace's edges (under the people): the slab's face with a line of light under its lip, the balustrades of
	## glass east and north, and west the wall of glass to the hall with the way through it.
	func _terrace() -> void:
		var r: Rect2 = data.get("rect", Rect2())
		var pool: Rect2 = data.get("pool", Rect2())
		var door: Rect2 = data.get("door", Rect2())
		var gold := Color(1.0, 0.82, 0.35)
		var glass := Color(0.8, 0.95, 1.0)
		var x0 := r.position.x
		var x1 := r.end.x
		var y0 := r.position.y
		var y1 := r.end.y
		draw_rect(Rect2(x0, y1, r.size.x + 4.0, 10.0), Color(0.2, 0.17, 0.25))
		draw_rect(Rect2(x0, y1, r.size.x + 4.0, 2.0), Color(0.56, 0.52, 0.56))
		draw_rect(Rect2(x0, y1 + 8.0, r.size.x + 4.0, 1.5), Color(1.0, 0.82, 0.4, 0.95))
		draw_rect(Rect2(x1, y0, 4.0, r.size.y + 10.0), Color(0.26, 0.22, 0.3))
		draw_rect(Rect2(x1 - 4.0, y0, 3.0, r.size.y), Color(glass, 0.22))
		draw_rect(Rect2(x1 - 1.0, y0, 1.5, r.size.y), gold)
		for seg in [[x0, pool.position.x - 3.0], [pool.end.x + 3.0, x1]]:
			var sa: float = seg[0]
			var sb: float = seg[1]
			draw_rect(Rect2(sa, y0 - 13.0, sb - sa, 13.0), Color(glass, 0.2))
			draw_rect(Rect2(sa, y0 - 14.0, sb - sa, 1.5), gold)
			draw_rect(Rect2(sa, y0 - 1.0, sb - sa, 1.0), Color(1, 1, 1, 0.4))
		var wx := x0 - 10.0                                             # the wall of glass, seen from above: a pale strip between rails
		for part in [[float(Gen.C_F0 * GroundMap.TILE), door.position.y], [door.end.y, y1]]:
			var pa: float = part[0]
			var pb: float = part[1]
			draw_rect(Rect2(wx, pa, 5.0, pb - pa), Color(glass, 0.3))
			draw_rect(Rect2(wx - 1.5, pa, 1.5, pb - pa), gold.darkened(0.1))
			draw_rect(Rect2(wx + 5.0, pa, 1.5, pb - pa), gold.darkened(0.1))
			var py := pa
			while py < pb:
				draw_rect(Rect2(wx - 2.5, py, 10.0, 3.0), gold)
				py += 24.0
		for dy in [door.position.y - 3.0, door.end.y]:
			draw_rect(Rect2(wx - 3.0, float(dy), 11.0, 3.0), Color(0.3, 0.9, 1.0))
			draw_circle(Vector2(wx + 2.5, float(dy) + 1.5), 7.0, Color(0.3, 0.9, 1.0, 0.18))

	## The terrace's balustrade to the south, towards you (the node at its west end, among the people): glass under a
	## rail of gold; who stands at the edge stands behind it.
	func _tfront() -> void:
		var w := float(data.get("w", 16.0))
		var gold := Color(1.0, 0.82, 0.35)
		draw_rect(Rect2(0.0, -15.0, w, 15.0), Color(0.8, 0.95, 1.0, 0.17))
		var px := 0.0
		while px <= w:
			draw_rect(Rect2(px - 1.0, -15.0, 2.0, 15.0), Color(gold.darkened(0.2), 0.9))
			if px + 16.0 < w:
				draw_line(Vector2(px + 6.0, -3.0), Vector2(px + 14.0, -13.0), Color(1, 1, 1, 0.16), 2.0)
			px += 32.0
		draw_rect(Rect2(0.0, -16.0, w, 1.5), gold)

	## The lounge's dance floor (under the people): squares of light, each in its own colour, pulsing with the music.
	func _dfloor() -> void:
		var r: Rect2 = data.get("rect", Rect2())
		var beat := _t * 1.05
		draw_rect(r, Color(0.03, 0.02, 0.05))
		for ty in int(r.size.y / 16.0):
			for tx in int(r.size.x / 16.0):
				var i := ty * 31 + tx * 7
				var col: Color = NEON[(int(_h(i, 91) * 6.0) + int(beat + _h(i, 92) * 2.0)) % 6]
				var lit := 0.3 + 0.7 * pow(maxf(0.0, sin((beat + _h(i, 93)) * TAU)), 2.0)
				draw_rect(Rect2(r.position + Vector2(tx, ty) * 16.0 + Vector2(1.0, 1.0), Vector2(14.0, 14.0)), Color(col.r, col.g, col.b, 0.3 + 0.6 * lit))
				draw_rect(Rect2(r.position + Vector2(tx, ty) * 16.0 + Vector2(1.0, 1.0), Vector2(14.0, 2.0)), Color(1, 1, 1, 0.12 * lit))
		draw_rect(r, Color(1.0, 0.82, 0.35), false, 1.5)
		var rug: Rect2 = data.get("rug", Rect2())
		if rug.size.x > 0.0:                                            # the high tables' carpet: a line of gold in it, what it is for
			draw_rect(rug.grow(-5.0), Color(1.0, 0.82, 0.35, 0.5), false, 1.0)
			draw_string(ThemeDB.fallback_font, Vector2(rug.position.x, rug.end.y - 8.0), "H I G H     S T A K E S", HORIZONTAL_ALIGNMENT_CENTER, rug.size.x, 8, Color(1.0, 0.82, 0.35, 0.8))

	## (Luz) the club's light, over everything and added to it: beams sweeping over the dance floor from above, the
	## floor's own glow in time with the music, a spot on every platform, glitter in the air; at night the pool's glow.
	func _club() -> void:
		var r: Rect2 = data.get("dfloor", Rect2())
		var c := r.get_center()
		var beat := absf(sin(_t * 3.3))
		for b in 6:
			var col: Color = NEON[b % NEON.size()]
			var apex := Vector2(r.position.x + r.size.x * (b + 0.5) / 6.0, r.position.y - 150.0)
			var foot := Vector2(c.x + sin(_t * (0.5 + 0.13 * b) + b * 1.7) * r.size.x * 0.55, c.y + cos(_t * 0.4 + b) * r.size.y * 0.32)
			draw_colored_polygon(PackedVector2Array([apex + Vector2(-2.0, 0.0), apex + Vector2(2.0, 0.0), foot + Vector2(15.0, 0.0), foot + Vector2(-15.0, 0.0)]), Color(col, 0.07))
			draw_set_transform(foot, 0.0, Vector2(1.0, 0.4))
			draw_circle(Vector2.ZERO, 16.0, Color(col, 0.16))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_rect(r.grow(2.0), Color(1.0, 0.4, 0.8, 0.04 + 0.08 * beat))
		for p in data.get("pods", []):
			var pp: Vector2 = p
			draw_colored_polygon(PackedVector2Array([pp + Vector2(-3.0, -130.0), pp + Vector2(3.0, -130.0), pp + Vector2(15.0, 1.0), pp + Vector2(-15.0, 1.0)]), Color(1.0, 0.92, 0.75, 0.09))
		for g in 44:
			var gp := Vector2(r.position.x - 30.0 + _h(g, 101) * (r.size.x + 60.0), r.position.y - 60.0 + fposmod(_h(g, 102) * 150.0 + _t * (9.0 + _h(g, 103) * 12.0), 150.0))
			if sin(_t * (5.0 + _h(g, 104) * 6.0) + g) > 0.3:
				draw_rect(Rect2(gp, Vector2(1.5, 1.5)), Color(1.0, 0.9, 0.55, 0.8))
		var pool: Rect2 = data.get("pool", Rect2())
		if pool.size.x > 0.0 and night > 0.3:
			draw_rect(pool, Color(0.2, 0.8, 1.0, 0.14 * night))
			draw_rect(pool.grow(10.0), Color(0.2, 0.8, 1.0, 0.05 * night))

	## The lobby's floor round the fountain: rings and rays of gold let into the marble (under the people).
	func _inlay() -> void:
		var gold := Color(1.0, 0.82, 0.35, 0.55)
		draw_set_transform(at, 0.0, Vector2(1.0, 0.42))
		draw_arc(Vector2.ZERO, 70.0, 0.0, TAU, 56, gold, 2.5)
		draw_arc(Vector2.ZERO, 78.0, 0.0, TAU, 56, Color(gold, 0.35), 1.2)
		draw_arc(Vector2.ZERO, 112.0, 0.0, TAU, 64, gold, 3.0)
		for ry in 16:
			var a := ry * TAU / 16.0
			var d := Vector2.from_angle(a)
			var n := d.orthogonal()
			draw_colored_polygon(PackedVector2Array([d * 80.0 + n * 5.0, d * 109.0, d * 80.0 - n * 5.0]), Color(gold, 0.3 if ry % 2 == 0 else 0.5))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	## The lobby's chandelier: rings of light, one inside the other, turning slowly; its glow on the fountain below.
	func _chandelier() -> void:
		var gold := Color(1.0, 0.85, 0.5)
		draw_rect(Rect2(at.x - 0.5, at.y - 120.0, 1.0, 60.0), Color(0.6, 0.5, 0.3))
		for r in 4:
			var rr := 46.0 - r * 10.0
			var yy := at.y - 60.0 + r * 10.0
			draw_set_transform(Vector2(at.x, yy), 0.0, Vector2(1.0, 0.32))
			draw_arc(Vector2.ZERO, rr, 0.0, TAU, 40, Color(gold, 0.9), 2.0)
			for k in 12:
				var a := k * TAU / 12.0 + _t * (0.3 if r % 2 == 0 else -0.3)
				draw_circle(Vector2(cos(a), sin(a)) * rr, 2.6, Color(1.0, 0.97, 0.85))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_circle(Vector2(at.x, at.y - 44.0), 60.0, Color(gold, 0.06))
		draw_circle(Vector2(at.x, at.y - 44.0), 36.0, Color(gold, 0.07))

	## Something on the floor, drawn from its front line upward (the node stands at its front left corner).
	func _prop() -> void:
		var font := ThemeDB.fallback_font
		var w := float(data.get("w", 16.0))
		var sd := int(data.get("seed", 0))
		var c: Color = data.get("col", Color(1.0, 0.82, 0.35))
		var gold := Color(1.0, 0.82, 0.35)
		var hi := bool(data.get("hi", false))                          # (the lounge) a high table: black cloth, gold
		match String(data.get("kind", "")):
			"slot":     # a slot machine: its reels turning, a sign of light on top
				draw_rect(Rect2(3.0, -2.0, 14.0, 4.0), Color(0, 0, 0, 0.35))
				draw_rect(Rect2(1.0, -34.0, 14.0, 34.0), Color(0.08, 0.07, 0.12))
				draw_rect(Rect2(1.0, -34.0, 14.0, 34.0), Color(c, 0.85), false, 1.0)
				draw_rect(Rect2(2.5, -29.0, 11.0, 9.0), Color(0.02, 0.02, 0.04))
				for rl in 3:
					var sym := int(_t * (5.0 + rl * 2.0) + sd + rl * 3) % 5
					draw_rect(Rect2(3.5 + rl * 3.4, -28.0, 2.6, 7.0), [Color(1.0, 0.3, 0.4), Color(1.0, 0.85, 0.3), Color(0.4, 1.0, 0.6), Color(0.4, 0.8, 1.0), Color(0.9, 0.5, 1.0)][sym])
				draw_rect(Rect2(3.0, -17.0, 10.0, 4.0), Color(c, 0.5 + 0.4 * absf(sin(_t * 3.0 + sd))))
				draw_rect(Rect2(4.0, -10.0, 3.0, 2.0), Color(1.0, 0.3, 0.3))
				draw_rect(Rect2(9.0, -10.0, 3.0, 2.0), Color(0.3, 1.0, 0.5))
				draw_rect(Rect2(2.0, -39.0, 12.0, 5.0), Color(c.lightened(0.2), 0.9))
				draw_rect(Rect2(0.0, -41.0, 16.0, 9.0), Color(c, 0.1))
			"roulette": # a roulette table: the wheel turning, the cloth with its fields
				draw_rect(Rect2(3.0, -3.0, w, 6.0), Color(0, 0, 0, 0.35))
				draw_rect(Rect2(0.0, -8.0, w, 8.0), Color(0.22, 0.13, 0.08))
				draw_rect(Rect2(0.0, -36.0, w, 28.0), Color(0.32, 0.2, 0.12))
				draw_rect(Rect2(2.0, -34.0, w - 4.0, 24.0), Color(0.07, 0.06, 0.1) if hi else Color(0.05, 0.35, 0.36))
				if hi:
					draw_rect(Rect2(2.0, -34.0, w - 4.0, 24.0), Color(gold, 0.85), false, 1.0)
				for fx in range(0, int(w) - 34, 5):
					for fy in 3:
						draw_rect(Rect2(30.0 + fx, -32.0 + fy * 7.0, 4.0, 6.0), Color(0.75, 0.12, 0.2) if (fx / 5 + fy) % 2 == 0 else Color(0.06, 0.06, 0.09))
				var wc := Vector2(15.0, -22.0)
				draw_set_transform(wc, 0.0, Vector2(1.0, 0.8))
				draw_circle(Vector2.ZERO, 12.0, Color(0.25, 0.15, 0.08))
				for sg in 12:
					var a0 := sg * TAU / 12.0 + _t * 1.6
					draw_arc(Vector2.ZERO, 8.0, a0, a0 + TAU / 12.0, 4, Color(0.8, 0.14, 0.2) if sg % 2 == 0 else Color(0.06, 0.06, 0.09), 5.0)
				draw_circle(Vector2.ZERO, 3.0, gold)
				draw_circle(Vector2.from_angle(-_t * 2.2) * 9.5, 1.3, Color(1, 1, 1))
				draw_arc(Vector2.ZERO, 13.5, 0.0, TAU, 28, Color(0.3, 0.9, 1.0, 0.45 + 0.3 * absf(sin(_t * 2.0 + sd))), 1.2)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				draw_rect(Rect2(0.0, -36.0, w, 1.5), gold.darkened(0.1))
			"cards", "poker":   # a table for cards: the cloth, cards and chips on it, a line of light round its edge
				var felt := Color(0.3, 0.12, 0.4) if String(data.get("kind", "")) == "cards" else Color(0.08, 0.2, 0.36)
				if hi:
					felt = Color(0.08, 0.07, 0.12)
				draw_rect(Rect2(3.0, -3.0, w, 6.0), Color(0, 0, 0, 0.35))
				draw_rect(Rect2(2.0, -8.0, w - 4.0, 8.0), Color(0.2, 0.12, 0.08))
				draw_rect(Rect2(0.0, -34.0, w, 26.0), Color(0.3, 0.19, 0.12))
				draw_rect(Rect2(2.0, -32.0, w - 4.0, 22.0), felt)
				draw_rect(Rect2(2.0, -32.0, w - 4.0, 22.0), Color(gold, 0.9) if hi else Color(0.3, 0.9, 1.0, 0.6), false, 1.0)
				for cd in int((w - 12.0) / 10.0):
					draw_rect(Rect2(6.0 + cd * 10.0, -20.0, 5.0, 7.0), Color(0.95, 0.95, 0.92))
					draw_rect(Rect2(7.0 + cd * 10.0, -18.5, 3.0, 2.0), Color(0.85, 0.2, 0.3) if (cd + sd) % 2 == 0 else Color(0.1, 0.1, 0.14))
					draw_rect(Rect2(8.0 + cd * 10.0, -28.0, 3.0, 4.0 + (cd % 3)), NEON[(cd + sd) % NEON.size()])
			"desk":     # a counter: its top, its front with a strip of light, its sign over it (a shutter where it is shut)
				draw_rect(Rect2(3.0, -2.0, w, 5.0), Color(0, 0, 0, 0.35))
				draw_rect(Rect2(0.0, -14.0, w, 14.0), Color(0.14, 0.09, 0.2))
				draw_rect(Rect2(0.0, -22.0, w, 8.0), Color(0.3, 0.2, 0.4))
				draw_rect(Rect2(0.0, -22.0, w, 1.5), gold.darkened(0.1))
				draw_rect(Rect2(3.0, -8.0, w - 6.0, 1.5), Color(c, 0.9))
				if bool(data.get("shut", false)):
					draw_rect(Rect2(4.0, -52.0, w - 8.0, 30.0), Color(0.26, 0.27, 0.32))
					for sl in range(0, 30, 3):
						draw_rect(Rect2(4.0, -52.0 + sl, w - 8.0, 1.0), Color(0.17, 0.18, 0.22))
				else:
					draw_rect(Rect2(4.0, -50.0, w - 8.0, 28.0), Color(0.6, 0.85, 1.0, 0.14))
					draw_rect(Rect2(4.0, -50.0, w - 8.0, 28.0), Color(0.8, 0.9, 1.0, 0.5), false, 1.0)
				draw_rect(Rect2(w * 0.5 - 34.0, -66.0, 68.0, 12.0), Color(0.03, 0.02, 0.05))
				draw_rect(Rect2(w * 0.5 - 34.0, -66.0, 68.0, 12.0), Color(c, 0.9), false, 1.0)
				draw_string(font, Vector2(w * 0.5 - 34.0, -56.5), String(data.get("text", "")), HORIZONTAL_ALIGNMENT_CENTER, 68.0, 8, c.lightened(0.3))
			"piano":    # a grand piano, its lid up
				draw_rect(Rect2(4.0, -3.0, w, 6.0), Color(0, 0, 0, 0.35))
				draw_rect(Rect2(6.0, -10.0, 2.0, 10.0), Color(0.05, 0.05, 0.07))
				draw_rect(Rect2(w - 10.0, -10.0, 2.0, 10.0), Color(0.05, 0.05, 0.07))
				draw_rect(Rect2(0.0, -18.0, w, 9.0), Color(0.04, 0.04, 0.06))
				draw_rect(Rect2(2.0, -17.0, w - 22.0, 4.0), Color(0.95, 0.95, 0.92))
				for ky in range(4, int(w) - 22, 4):
					draw_rect(Rect2(ky, -17.0, 1.5, 2.5), Color(0.05, 0.05, 0.07))
				draw_colored_polygon(PackedVector2Array([Vector2(0.0, -18.0), Vector2(w, -18.0), Vector2(w, -40.0), Vector2(w * 0.45, -46.0), Vector2(0.0, -36.0)]), Color(0.06, 0.06, 0.09))
				draw_colored_polygon(PackedVector2Array([Vector2(4.0, -36.0), Vector2(w * 0.45, -45.0), Vector2(w - 2.0, -40.0), Vector2(w - 2.0, -58.0), Vector2(w * 0.4, -66.0)]), Color(0.1, 0.1, 0.14))
				draw_line(Vector2(6.0, -34.0), Vector2(w * 0.42, -62.0), Color(1, 1, 1, 0.25), 1.5)
			"cfountain":    # the lobby's fountain: two basins of marble and gold, jets of water, a Coin of light turning over it
				var fc := Vector2(w * 0.5, -15.0)
				draw_set_transform(fc + Vector2(0.0, 6.0), 0.0, Vector2(1.0, 0.3))
				draw_circle(Vector2.ZERO, w * 0.52, Color(0, 0, 0, 0.3))
				draw_set_transform(fc, 0.0, Vector2(1.0, 0.3))
				draw_circle(Vector2(0.0, 12.0), w * 0.5, Color(0.2, 0.13, 0.28))
				draw_circle(Vector2.ZERO, w * 0.5, Color(0.34, 0.24, 0.44))
				draw_arc(Vector2.ZERO, w * 0.5, 0.0, TAU, 40, gold, 2.5)
				draw_circle(Vector2.ZERO, w * 0.44, Color(0.2, 0.62, 0.8))
				for rp2 in 3:
					draw_arc(Vector2.ZERO, fposmod(_t * 9.0 + rp2 * 14.0, w * 0.42) + 2.0, 0.0, TAU, 28, Color(0.75, 0.95, 1.0, 0.35), 1.2)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				draw_rect(Rect2(fc.x - 3.0, fc.y - 12.0, 6.0, 12.0), Color(0.3, 0.2, 0.4))
				draw_set_transform(fc + Vector2(0.0, -14.0), 0.0, Vector2(1.0, 0.3))
				draw_circle(Vector2(0.0, 8.0), w * 0.2, Color(0.2, 0.13, 0.28))
				draw_circle(Vector2.ZERO, w * 0.2, Color(0.34, 0.24, 0.44))
				draw_arc(Vector2.ZERO, w * 0.2, 0.0, TAU, 28, gold, 2.0)
				draw_circle(Vector2.ZERO, w * 0.16, Color(0.3, 0.72, 0.9))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				draw_rect(Rect2(fc.x - 1.5, fc.y - 30.0, 3.0, 16.0), gold.darkened(0.15))
				for jt in 8:                                                # the jets: out of the upper basin into the lower
					var ja := jt * TAU / 8.0 + 0.2
					var top := fc + Vector2(cos(ja) * w * 0.17, -14.0 + sin(ja) * w * 0.05)
					var low := fc + Vector2(cos(ja) * w * 0.36, sin(ja) * w * 0.1)
					var k := fposmod(_t * 1.6 + jt * 0.13, 1.0)
					draw_line(top, top.lerp(low, 0.5) + Vector2(0.0, -5.0), Color(0.8, 0.96, 1.0, 0.55), 1.0)
					draw_line(top.lerp(low, 0.5) + Vector2(0.0, -5.0), low, Color(0.8, 0.96, 1.0, 0.45), 1.0)
					draw_circle(top.lerp(low, k) + Vector2(0.0, -5.0 * sin(k * PI)), 1.0, Color(1, 1, 1, 0.9))
				var cc := fc + Vector2(0.0, -46.0 + sin(_t * 1.2) * 1.5)           # the Coin
				var cwd := cos(_t * 1.1)
				draw_set_transform(cc, 0.0, Vector2(maxf(0.08, absf(cwd)), 1.0))
				draw_circle(Vector2.ZERO, 13.0, Color(1.0, 0.82, 0.35, 0.22))
				draw_arc(Vector2.ZERO, 12.0, 0.0, TAU, 28, Color(1.0, 0.88, 0.5, 0.95), 2.0)
				draw_arc(Vector2.ZERO, 8.5, 0.0, TAU, 24, Color(1.0, 0.88, 0.5, 0.55), 1.0)
				draw_arc(Vector2.ZERO, 5.0, 0.9, TAU - 0.9, 14, Color(1.0, 0.95, 0.7, 0.95), 2.0)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				for sl in range(-12, 13, 3):                                # (a hologram: its lines)
					draw_rect(Rect2(cc.x - 13.0, cc.y + sl, 26.0, 1.0), Color(0.05, 0.03, 0.08, 0.25))
				draw_colored_polygon(PackedVector2Array([Vector2(fc.x - 2.0, fc.y - 30.0), Vector2(fc.x + 2.0, fc.y - 30.0), Vector2(cc.x + 11.0, cc.y + 13.0), Vector2(cc.x - 11.0, cc.y + 13.0)]),
					Color(1.0, 0.85, 0.4, 0.1))
			"post":     # a post of gold; a rope of velvet from it down to the next
				draw_rect(Rect2(6.0, -3.0, 6.0, 3.0), Color(0, 0, 0, 0.35))
				draw_rect(Rect2(5.0, -3.0, 6.0, 2.0), gold.darkened(0.35))
				draw_rect(Rect2(7.0, -17.0, 2.0, 15.0), gold.darkened(0.1))
				draw_circle(Vector2(8.0, -18.0), 2.2, gold.lightened(0.15))
				if bool(data.get("rope", false)):
					draw_polyline(PackedVector2Array([Vector2(8.0, -15.0), Vector2(8.6, -8.0), Vector2(8.6, -3.0), Vector2(8.0, 1.0)]), Color(0.62, 0.1, 0.22), 2.0)
			"odds":     # a board of light: the racers and their odds
				draw_rect(Rect2(4.0, -2.0, w - 4.0, 4.0), Color(0, 0, 0, 0.35))
				draw_rect(Rect2(w * 0.5 - 2.0, -12.0, 4.0, 12.0), Color(0.12, 0.12, 0.18))
				draw_rect(Rect2(w * 0.5 - 7.0, -3.0, 14.0, 3.0), Color(0.2, 0.2, 0.28))
				draw_rect(Rect2(0.0, -56.0, w, 44.0), Color(0.02, 0.05, 0.1, 0.92))
				draw_rect(Rect2(0.0, -56.0, w, 44.0), Color(0.3, 0.9, 1.0, 0.85), false, 1.0)
				draw_string(font, Vector2(0.0, -48.5), "ODDS", HORIZONTAL_ALIGNMENT_CENTER, w, 6, Color(0.75, 0.95, 1.0))
				for od in 5:
					var oc: Color = NEON[(od + sd) % NEON.size()]
					var oy := -44.0 + od * 6.2
					draw_colored_polygon(PackedVector2Array([Vector2(3.0, oy), Vector2(8.0, oy + 2.0), Vector2(3.0, oy + 4.0)]), oc)
					var ow := 4.0 + _h(od + sd * 7 + int(_t / 4.0), 61) * 12.0
					draw_rect(Rect2(11.0, oy + 1.0, ow, 2.0), Color(oc, 0.8))
					draw_rect(Rect2(w - 6.0, oy + 0.5, 3.0, 3.0), Color(1, 1, 1, 0.35 + 0.5 * _h(od + int(_t * 2.0), 62 + sd)))
				draw_rect(Rect2(0.0, -56.0 + fposmod(_t * 12.0, 44.0), w, 1.0), Color(0.6, 0.95, 1.0, 0.25))
			"podium":   # (Luz) a round platform, a ring of light round it; who dances on it stands on its top (the node at its back)
				var oy := float(data.get("lift", 0.0))
				var pc := Vector2(w * 0.5, oy - 10.0)
				var pulse := absf(sin(_t * 3.3 + sd))
				draw_set_transform(pc + Vector2(0.0, 9.0), 0.0, Vector2(1.0, 0.36))
				draw_circle(Vector2.ZERO, w * 0.5 + 2.0, Color(0, 0, 0, 0.3))
				draw_set_transform(pc + Vector2(0.0, 7.0), 0.0, Vector2(1.0, 0.36))
				draw_circle(Vector2.ZERO, w * 0.47, Color(0.08, 0.06, 0.12))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				draw_rect(Rect2(pc.x - w * 0.47, pc.y, w * 0.94, 7.0), Color(0.1, 0.08, 0.15))
				draw_rect(Rect2(pc.x - w * 0.47, pc.y + 3.0, w * 0.94, 1.5), Color(c, 0.6 + 0.4 * pulse))
				draw_set_transform(pc + Vector2(0.0, 4.0), 0.0, Vector2(1.0, 0.36))
				draw_arc(Vector2.ZERO, w * 0.47, 0.0, PI, 16, Color(c, 0.6 + 0.4 * pulse), 2.0)
				draw_set_transform(pc, 0.0, Vector2(1.0, 0.36))
				draw_circle(Vector2.ZERO, w * 0.47, Color(0.16, 0.13, 0.22))
				draw_circle(Vector2.ZERO, w * 0.38, Color(c, 0.3 + 0.3 * pulse))
				draw_arc(Vector2.ZERO, w * 0.47, 0.0, TAU, 28, gold, 1.5)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				for gk in 8:                                                # glitter winding up round who dances
					var gu := fposmod(_t * 0.35 + gk * 0.125, 1.0)
					var ga := _t * 1.8 + gk * TAU / 8.0 + sd
					draw_rect(Rect2(pc + Vector2(cos(ga) * (w * 0.5 + 1.0), -6.0 - 22.0 * gu + sin(ga) * 3.0), Vector2(1.5, 1.5)), Color(1.0, 0.92, 0.6, 0.85 * (1.0 - gu)))
			"dj":       # the DJ's desk: two decks turning, bars of light jumping with the music on its front
				draw_rect(Rect2(3.0, -2.0, w, 5.0), Color(0, 0, 0, 0.35))
				draw_rect(Rect2(0.0, -16.0, w, 16.0), Color(0.07, 0.06, 0.1))
				draw_rect(Rect2(0.0, -24.0, w, 8.0), Color(0.16, 0.13, 0.22))
				draw_rect(Rect2(0.0, -24.0, w, 1.5), gold)
				for bq in int((w - 8.0) / 4.0):
					var bh2 := 2.0 + 10.0 * absf(sin(_t * (5.0 + _h(bq, 95) * 4.0) + bq))
					draw_rect(Rect2(4.0 + bq * 4.0, -3.0 - bh2, 3.0, bh2), NEON[bq % NEON.size()])
				for dk in [w * 0.3, w * 0.7]:
					draw_set_transform(Vector2(float(dk), -20.5), 0.0, Vector2(1.0, 0.4))
					draw_circle(Vector2.ZERO, 7.0, Color(0.03, 0.03, 0.05))
					draw_arc(Vector2.ZERO, 6.0, _t * 3.0, _t * 3.0 + 1.3, 6, Color(0.3, 0.9, 1.0), 1.5)
					draw_circle(Vector2.ZERO, 2.0, gold)
					draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				draw_rect(Rect2(w * 0.5 - 5.0, -23.0, 10.0, 5.0), Color(1.0, 0.36, 0.66, 0.6 + 0.4 * absf(sin(_t * 3.3))))
			"glasses":  # a pyramid of glasses on a small table, the wine sparkling in them
				draw_rect(Rect2(3.0, -2.0, 12.0, 4.0), Color(0, 0, 0, 0.35))
				draw_rect(Rect2(7.0, -10.0, 2.0, 10.0), gold.darkened(0.3))
				draw_set_transform(Vector2(8.0, -10.0), 0.0, Vector2(1.0, 0.4))
				draw_circle(Vector2.ZERO, 8.0, Color(0.95, 0.95, 0.98))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				for row in 4:
					for g in row + 1:
						var gx := 8.0 - row * 2.2 + g * 4.4
						var gy := -27.0 + row * 4.0
						draw_rect(Rect2(gx - 1.5, gy, 3.0, 3.0), Color(1.0, 0.9, 0.55, 0.92))
						draw_rect(Rect2(gx - 1.5, gy, 3.0, 1.0), Color(1, 1, 1, 0.85))
				for sk in 4:
					if sin(_t * (4.0 + sk) + sk * 2.0) > 0.4:
						draw_rect(Rect2(3.0 + _h(sk + int(_t * 2.0), 96) * 10.0, -28.0 + _h(sk, 97) * 16.0, 1.0, 1.0), Color(1, 1, 1, 0.95))
			"flame":    # a bowl of fire on a foot of stone
				draw_rect(Rect2(3.0, -2.0, 12.0, 4.0), Color(0, 0, 0, 0.35))
				draw_rect(Rect2(6.0, -9.0, 4.0, 9.0), Color(0.34, 0.3, 0.34))
				draw_colored_polygon(PackedVector2Array([Vector2(1.0, -14.0), Vector2(15.0, -14.0), Vector2(11.0, -8.0), Vector2(5.0, -8.0)]), Color(0.24, 0.21, 0.26))
				draw_rect(Rect2(1.0, -15.0, 14.0, 1.5), gold.darkened(0.2))
				for fl2 in 5:
					var fx2 := 4.0 + fl2 * 2.0
					var fh := 6.0 + 7.0 * absf(sin(_t * (6.0 + fl2) + fl2 * 1.9 + sd))
					draw_colored_polygon(PackedVector2Array([Vector2(fx2 - 2.2, -15.0), Vector2(fx2 + 2.2, -15.0), Vector2(fx2 + sin(_t * 5.0 + fl2) * 1.5, -15.0 - fh)]),
						Color(1.0, 0.5 + 0.35 * _h(fl2, 98), 0.15, 0.9))
				draw_circle(Vector2(8.0, -19.0), 13.0, Color(1.0, 0.6, 0.2, 0.12))
			"lapis":    # (Luz) Lapis as a hologram, turning over a foot of gold
				draw_set_transform(Vector2(w * 0.5, -4.0), 0.0, Vector2(1.0, 0.36))
				draw_circle(Vector2(0.0, 6.0), w * 0.5, Color(0, 0, 0, 0.3))
				draw_circle(Vector2.ZERO, w * 0.44, Color(0.1, 0.08, 0.15))
				draw_arc(Vector2.ZERO, w * 0.44, 0.0, TAU, 24, gold, 2.0)
				draw_circle(Vector2.ZERO, w * 0.25, Color(0.3, 0.9, 1.0, 0.5 + 0.3 * absf(sin(_t * 2.0))))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				draw_colored_polygon(PackedVector2Array([Vector2(w * 0.5 - 8.0, -5.0), Vector2(w * 0.5 + 8.0, -5.0), Vector2(w * 0.5 + 30.0, -74.0), Vector2(w * 0.5 - 30.0, -74.0)]), Color(0.3, 0.9, 1.0, 0.07))
				Gen.draw_lapis(self, Vector2(w * 0.5, -48.0), 17.0, 1.0, _t * 30.0, false)
				for sc2 in 6:
					draw_rect(Rect2(w * 0.5 - 40.0, -80.0 + sc2 * 11.0 + fposmod(_t * 8.0, 11.0), 80.0, 1.0), Color(0.6, 1.0, 1.0, 0.12))
			_:          # a row of cinema seats, seen from behind
				for s in int(w / 16.0):
					draw_rect(Rect2(s * 16.0 + 2.0, -3.0, 12.0, 3.0), Color(0.08, 0.05, 0.1))
					draw_rect(Rect2(s * 16.0 + 1.0, -22.0, 14.0, 19.0), Color(0.42, 0.14, 0.26))
					draw_rect(Rect2(s * 16.0 + 1.0, -22.0, 14.0, 3.0), Color(0.56, 0.2, 0.34))
					draw_rect(Rect2(s * 16.0 + 7.5, -19.0, 1.0, 16.0), Color(0.3, 0.1, 0.18))


## (Luz) a ride in one of the casino's capsules of glass, up or down the outside of the middle tower. The picture
## stays with the capsule: close while it starts, pulled back while it runs (so that you see where on the tower you
## are bound), close again where it stops. The floors hang beside the rails as names, the one you are bound for in
## gold; the other capsule comes the other way. Drawn in tower units (TowerArt), the tower seen from behind: no
## doors, no billboards. A Control over the whole screen; it fades in, and out once the new floor stands.
class LiftRide extends Control:
	const Gen = preload("res://scripts/ground/centauria_gen.gd")
	const FADE := 0.25
	const RAIL_X := 34.0
	var night := 0.0
	var a := 0                         # from this floor …
	var b := 0                         # … to this one
	var look: Dictionary = {}          # who rides
	var hint := ""
	var dur := 3.0                     # the ride itself (seconds)
	var _t := 0.0
	var _gone := -1.0                  # from 0 on: the new floor stands, the picture fades

	func setup(p_a: int, p_b: int, p_night: float, p_look: Dictionary) -> void:
		a = clampi(p_a, 0, Gen.CAS_ALT.size() - 1)
		b = clampi(p_b, 0, Gen.CAS_ALT.size() - 1)
		night = p_night
		look = p_look
		var far: float = absf(float(Gen.CAS_ALT[b]) - float(Gen.CAS_ALT[a]))
		dur = clampf(2.0 + far / 2400.0, 2.6, 4.6)

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP
		clip_contents = true
		modulate.a = 0.0

	func _process(dt: float) -> void:
		_t += dt
		modulate.a = clampf(_t / FADE, 0.0, 1.0)
		if _gone >= 0.0:
			_gone += dt
			if _gone > FADE:
				queue_free()
		queue_redraw()

	## The capsule stands at the other floor and the picture has gone dark: time to set the rider down there.
	func arrived() -> bool:
		return _t >= FADE + dur + FADE

	func skip() -> void:
		_t = maxf(_t, FADE + dur)

	func leave() -> void:
		if _gone < 0.0:
			_gone = 0.0

	## How far the capsule has run (0 … 1); it rests a moment at both ends.
	func run() -> float:
		return clampf((_t - FADE - 0.5) / maxf(dur - 1.0, 0.1), 0.0, 1.0)

	## The foot of the rails, seen from near: the lifts' hall at the back of the podium. Arches of glass full of warm
	## light, people walking behind them, palms before them, the house's name over it all.
	func _hall() -> void:
		var gold := Color(1.0, 0.82, 0.35)
		var font := ThemeDB.fallback_font
		var warm := Color(0.82, 0.67, 0.44) if night > 0.5 else Color(0.62, 0.6, 0.56)
		draw_rect(Rect2(-530.0, -300.0, 1060.0, 300.0), Color(0.08, 0.07, 0.15))
		for ar in 7:
			var ax := -455.0 + ar * 130.0
			draw_circle(Vector2(ax + 55.0, -180.0), 55.0, warm)
			draw_rect(Rect2(ax, -180.0, 110.0, 180.0), warm)
			draw_rect(Rect2(ax, -70.0, 110.0, 70.0), warm.lightened(0.12))
			for q in 2:                                                  # who walks behind the glass
				var px := ax + 20.0 + fposmod(Gen.TowerArt.hsh(ar * 2 + q, 51) * 70.0 + _t * (3.0 + q * 2.0) * (1.0 if (ar + q) % 2 == 0 else -1.0), 70.0)
				draw_rect(Rect2(px - 5.0, -44.0, 10.0, 44.0), warm.darkened(0.5))
				draw_circle(Vector2(px, -50.0), 6.5, warm.darkened(0.5))
			for mx in [36.0, 73.0]:
				draw_rect(Rect2(ax + float(mx), -228.0, 3.0, 228.0), Color(0.1, 0.08, 0.16))
			for my in [-150.0, -75.0]:
				draw_rect(Rect2(ax, float(my), 110.0, 3.0), Color(0.1, 0.08, 0.16))
			draw_arc(Vector2(ax + 55.0, -180.0), 55.0, PI, TAU, 24, gold, 4.0)
			draw_rect(Rect2(ax - 2.0, -180.0, 4.0, 180.0), gold.darkened(0.15))
			draw_rect(Rect2(ax + 108.0, -180.0, 4.0, 180.0), gold.darkened(0.15))
			if ar != 3:                                                 # a palm in a tub before every arch but the lifts'
				var pb := Vector2(ax + 55.0, 0.0)
				draw_rect(Rect2(pb.x - 16.0, -16.0, 32.0, 16.0), Color(0.3, 0.24, 0.36))
				draw_rect(Rect2(pb.x - 16.0, -16.0, 32.0, 3.0), gold.darkened(0.2))
				var pt := pb + Vector2(4.0, -96.0)
				draw_line(pb + Vector2(0.0, -16.0), pt, Color(0.3, 0.22, 0.14), 6.0)
				for fr in 7:
					var fd := Vector2.from_angle(-PI * 0.96 + fr * PI * 0.92 / 6.0)
					draw_line(pt, pt + fd * 30.0, Color(0.14, 0.4, 0.2), 5.0)
					draw_line(pt + fd * 30.0, pt + fd * 46.0 + Vector2(0.0, 16.0), Color(0.1, 0.32, 0.16), 4.0)
		draw_rect(Rect2(-530.0, -300.0, 1060.0, 52.0), Color(0.05, 0.03, 0.1))
		draw_rect(Rect2(-530.0, -250.0, 1060.0, 4.0), gold)
		draw_string(font, Vector2(-530.0, -262.0), "THE GRAND", HORIZONTAL_ALIGNMENT_CENTER, 450.0, 34, gold)
		draw_string(font, Vector2(80.0, -262.0), "CENTAURIA", HORIZONTAL_ALIGNMENT_CENTER, 450.0, 34, gold)
		var bn := 0
		for bx in range(-520, 521, 26):
			draw_circle(Vector2(float(bx), -244.0), 3.5, Color(1.0, 0.95, 0.7) if (bn + int(_t * 6.0)) % 3 == 0 else Color(0.5, 0.35, 0.15))
			bn += 1
		draw_rect(Rect2(66.0, -238.0, 100.0, 22.0), Color(0.03, 0.02, 0.06))
		draw_rect(Rect2(66.0, -238.0, 100.0, 22.0), Color(0.3, 0.9, 1.0, 0.9), false, 2.0)
		draw_string(font, Vector2(66.0, -221.0), "LIFTS", HORIZONTAL_ALIGNMENT_CENTER, 100.0, 18, Color(0.75, 0.95, 1.0))

	func _capsule(x: float, alt: float, rider: bool, v: float, sc: float) -> void:
		var gold := Color(1.0, 0.82, 0.35)
		var r := 24.0
		var hh := 86.0
		var top := -(alt + hh)
		var mid := Vector2(x, top + hh * 0.5)
		var away := clampf((0.9 - sc) / 0.5, 0.0, 1.0)                   # how far the picture has pulled back
		draw_circle(mid, maxf(64.0, 26.0 / sc), Color(1.0, 0.9, 0.6, (0.1 if rider else 0.05) + 0.08 * away))      # its light, seen from far
		var tail := clampf(absf(v) * 0.05, 0.0, maxf(240.0, 80.0 / sc))      # the wake behind it
		if tail > 6.0:
			var tw0 := maxf(r * 0.8, 4.0 / sc)
			var ty0 := -alt if v > 0.0 else top
			var ty1 := ty0 + (tail if v > 0.0 else -tail)
			draw_colored_polygon(PackedVector2Array([Vector2(x - tw0, ty0), Vector2(x + tw0, ty0), Vector2(x + tw0 * 0.15, ty1), Vector2(x - tw0 * 0.15, ty1)]), Color(1.0, 0.9, 0.6, 0.12 + 0.22 * away))
		if away > 0.0 and rider:                                        # (from far: a point of gold, a ring round it)
			draw_circle(mid, 7.0 / sc, Color(1.0, 0.95, 0.75, 0.95 * away))
			draw_arc(mid, (14.0 + 4.0 * sin(_t * 6.0)) / sc, 0.0, TAU, 24, Color(gold, 0.85 * away), 2.0 / sc)
		var shell := PackedVector2Array()
		for i in 13:
			shell.append(Vector2(x, top + r) + Vector2.from_angle(PI + i * PI / 12.0) * r)
		for i in 13:
			shell.append(Vector2(x, -alt - r) + Vector2.from_angle(i * PI / 12.0) * r)
		draw_colored_polygon(shell, Color(0.1, 0.12, 0.2, 0.6))                    # the cabin's dusk behind the glass …
		draw_colored_polygon(shell, Color(1.0, 0.9, 0.7, 0.22))                    # … and its own warm light
		draw_rect(Rect2(x - r + 3.0, -alt - 14.0, r * 2.0 - 6.0, 5.0), Color(0.12, 0.09, 0.17))
		draw_rect(Rect2(x - r + 3.0, -alt - 14.0, r * 2.0 - 6.0, 1.5), Color(0.3, 0.9, 1.0, 0.9))
		if rider and not look.is_empty():
			var tex := ChibiArt.frame(look, 0, 0)
			var th := 58.0
			var tw := th * tex.get_width() / float(tex.get_height())
			draw_texture_rect(tex, Rect2(x - tw * 0.5, -alt - 14.0 - th, tw, th), false)
		elif not rider:
			for q in 2:                                                  # two riding the other one, shadows
				draw_rect(Rect2(x - 12.0 + q * 14.0, -alt - 52.0, 9.0, 38.0), Color(0.05, 0.05, 0.1, 0.7))
				draw_circle(Vector2(x - 7.5 + q * 14.0, -alt - 57.0), 5.5, Color(0.05, 0.05, 0.1, 0.7))
		draw_colored_polygon(shell, Color(0.75, 0.92, 1.0, 0.16))                  # the glass
		draw_line(Vector2(x - r * 0.6, top + r), Vector2(x - r * 0.6, -alt - r), Color(1, 1, 1, 0.32), 3.0)
		var rim := shell.duplicate()
		rim.append(shell[0])
		draw_polyline(rim, gold, maxf(2.5, 1.6 / sc))
		draw_rect(Rect2(x - r, top + r - 2.0, r * 2.0, 4.0), gold)
		draw_rect(Rect2(x - r, -alt - r - 2.0, r * 2.0, 4.0), gold)
		draw_circle(Vector2(x, top - 4.0), 4.0, Color(0.3, 0.9, 1.0))
		draw_circle(Vector2(x, -alt + 4.0), 4.0, Color(0.3, 0.9, 1.0))

	func _draw() -> void:
		var w := size.x
		var h := size.y
		if _gone >= 0.0:
			draw_rect(Rect2(0.0, 0.0, w, h), Color(0.0, 0.0, 0.0, clampf(1.0 - _gone / FADE, 0.0, 1.0)))
			return
		var font := ThemeDB.fallback_font
		var gold := Color(1.0, 0.82, 0.35)
		var ya: float = Gen.CAS_ALT[a]
		var yb: float = Gen.CAS_ALT[b]
		var u := run()
		var e := u * u * u * (u * (u * 6.0 - 15.0) + 10.0)
		var cy := lerpf(ya, yb, e)
		var near := 2.6 * h / 1080.0
		var far := clampf(h * 0.62 / maxf(absf(yb - ya), 1.0), h * 0.9 / 9000.0, near)
		var sc := near * pow(far / near, smoothstep(0.04, 0.4, u) * (1.0 - smoothstep(0.6, 0.96, u)))
		var org := Vector2(w * 0.5 + RAIL_X * sc, h * 0.62 + cy * sc)        # (your rail in the middle of the picture)
		var y_lo := cy - (h * 0.38) / sc - 150.0
		var y_hi := cy + (h * 0.62) / sc + 150.0
		Gen.draw_sky(self, Rect2(0.0, 0.0, w, h), night, w * 0.8, h * 0.3, h * 0.27, _t, true)
		draw_set_transform(org, 0.0, Vector2(sc, sc))
		# the city round the towers, small against them
		if y_lo < 1300.0:
			for layer in 2:
				var bw: float = [150.0, 210.0][layer]
				var shade: float = [0.24, 0.16][layer]
				for bb in range(-40, 40):
					var bx: float = bb * bw
					var bh: float = 260.0 + Gen.TowerArt.hsh(bb, layer * 7 + 2) * float([900.0, 620.0][layer])
					var tint: Color = [Color(1.0, 0.36, 0.66), Color(0.3, 0.9, 1.0), Color(1.0, 0.82, 0.25), Color(0.55, 1.0, 0.6), Color(0.72, 0.5, 1.0)][int(Gen.TowerArt.hsh(bb, layer + 11) * 5.0) % 5]
					var body := Color(shade, shade, shade + 0.08).lerp(tint, 0.18)
					if night > 0.5:
						body = body.darkened(0.45)
					draw_rect(Rect2(bx, -bh, bw - 16.0, bh), body)
					for r2 in int(bh / 60.0):
						if Gen.TowerArt.hsh(bb * 31 + r2, layer + 40) < (0.6 if night > 0.5 else 0.3):
							draw_rect(Rect2(bx + 10.0, -bh + 14.0 + r2 * 60.0, bw - 36.0, 22.0), Color(tint if r2 % 3 == 0 else Color(1.0, 0.92, 0.7), 0.8 if night > 0.5 else 0.4))
		Gen.TowerArt.draw(self, _t, night, y_lo, y_hi, sc > 0.42, true)
		if y_lo < 320.0 and sc > 0.3:
			_hall()
		# the casino's floors: lit bands; the lounge's glow beats, its pool lies on the roof below the tip
		var beat := 0.6 + 0.4 * absf(sin(_t * 3.3))
		for bd in [[1, 560.0, Color(1.0, 0.36, 0.66)], [2, 560.0, gold], [3, 560.0, Color(0.3, 0.9, 1.0)], [4, 350.0, gold], [5, 140.0, Color(1.0, 0.4, 0.9)]]:
			var by: float = Gen.CAS_ALT[int(bd[0])]
			if by < y_lo - 100.0 or by > y_hi:
				continue
			var bhw := float(bd[1])
			var bcol: Color = bd[2]
			draw_rect(Rect2(-bhw + 14.0, -by - 62.0, bhw * 2.0 - 28.0, 58.0), Color(bcol, 0.2 * (beat if int(bd[0]) == 5 else 1.0)))
			draw_rect(Rect2(-bhw + 14.0, -by - 4.0, bhw * 2.0 - 28.0, 4.0), Color(bcol, 0.85))
		if 6300.0 > y_lo - 100.0 and 6300.0 < y_hi:
			draw_circle(Vector2(192.0, -6312.0), 62.0, Color(0.3, 0.9, 1.0, 0.05))
			draw_rect(Rect2(148.0, -6313.0, 88.0, 9.0), Color(0.2, 0.85, 0.95))
			draw_rect(Rect2(148.0, -6315.0, 88.0, 2.5), Color(0.9, 1.0, 1.0, 0.8))
			draw_rect(Rect2(236.0, -6330.0, 2.5, 26.0), Color(0.8, 0.95, 1.0, 0.6))
			for pm in [156.0, 226.0]:                                   # palms by the pool, a few of the members
				var pb := Vector2(float(pm), -6304.0)
				var pt := pb + Vector2(3.0, -36.0)
				draw_line(pb, pt, Color(0.34, 0.25, 0.16), 4.0)
				for fr in 7:
					var fd := Vector2.from_angle(-PI * 0.96 + fr * PI * 0.92 / 6.0)
					draw_line(pt, pt + fd * 13.0, Color(0.2, 0.52, 0.26), 3.0)
					draw_line(pt + fd * 13.0, pt + fd * 21.0 + Vector2(0.0, 7.0), Color(0.16, 0.44, 0.22), 2.5)
			for mb in 4:
				draw_rect(Rect2(166.0 + mb * 14.0, -6304.0 - 11.0, 3.5, 7.0), [Color(1.0, 0.95, 0.9), Color(1.0, 0.82, 0.35), Color(0.72, 0.42, 1.0), Color(0.9, 0.3, 0.4)][mb])
				draw_circle(Vector2(167.7 + mb * 14.0, -6304.0 - 13.0), 2.2, Color(0.85, 0.65, 0.5))
		# the rails, lamps running up them the way you ride
		var r_top: float = float(Gen.CAS_ALT[Gen.CAS_ALT.size() - 1]) + 130.0
		var ra := maxf(0.0, y_lo)
		var rb := minf(r_top, y_hi)
		if rb > ra:
			var lw := maxf(2.0, 1.6 / sc)
			for rx in [-RAIL_X, RAIL_X]:
				draw_rect(Rect2(float(rx) - 8.0, -rb, 16.0, rb - ra), Color(0.02, 0.03, 0.08, 0.82))
				draw_rect(Rect2(float(rx) - 8.0, -rb, lw, rb - ra), gold.darkened(0.1))
				draw_rect(Rect2(float(rx) + 8.0 - lw, -rb, lw, rb - ra), gold.darkened(0.1))
			var step := 60.0 if sc > 0.5 else 240.0
			var li := int(floorf(ra / step))
			var way := 1 if yb > ya else -1
			while li * step < rb:
				var on := posmod(li - way * int(_t * 10.0), 6) == 0
				for rx2 in [-RAIL_X, RAIL_X]:
					draw_rect(Rect2(float(rx2) - maxf(1.5, 1.2 / sc), -li * step - 4.0, maxf(3.0, 2.4 / sc), maxf(8.0, 3.0 / sc)), Color(0.3, 0.9, 1.0, 1.0 if on else 0.3))
				li += 1
			if r_top < y_hi:
				draw_rect(Rect2(-RAIL_X - 14.0, -r_top - 8.0, RAIL_X * 2.0 + 28.0, 8.0), gold)
		for i in Gen.CAS_ALT.size():                                    # where the capsules stop: a bracket of gold, the floor's light
			var sa: float = Gen.CAS_ALT[i]
			if sa < y_lo - 100.0 or sa > y_hi:
				continue
			draw_rect(Rect2(-RAIL_X - 30.0, -sa - 92.0, RAIL_X * 2.0 + 60.0, 90.0), Color(1.0, 0.92, 0.7, 0.12))
			draw_rect(Rect2(-RAIL_X - 34.0, -sa - 3.0, RAIL_X * 2.0 + 68.0, 5.0), gold)
		var v := (yb - ya) * 30.0 * u * u * (1.0 - u) * (1.0 - u) / maxf(dur - 1.0, 0.1)       # units a second
		_capsule(RAIL_X, lerpf(yb, ya, e), false, -v, sc)
		_capsule(-RAIL_X, cy, true, v, sc)
		# the layer of cloud round the towers' middle: the capsule runs through it
		if y_hi > 2900.0 and y_lo < 4700.0:
			for c in 12:
				var cx := fposmod(c * 700.0 + _t * (20.0 + c * 3.0), 8000.0) - 4000.0
				var ccy := -3300.0 - Gen.TowerArt.hsh(c, 3) * 900.0
				for p in 4:
					draw_circle(Vector2(cx + p * 190.0, ccy + sin(c + p) * 40.0), 170.0 - p * 22.0, Color(0.8, 0.84, 0.95, 0.16 if night > 0.5 else 0.3))
		# traffic in the air
		for tr in 10:
			var tay := 700.0 + tr * 610.0
			if tay < y_lo or tay > y_hi:
				continue
			var tdir := 1.0 if tr % 2 == 0 else -1.0
			var tax := (fposmod(tr * 733.0 + _t * (160.0 + tr * 23.0), 9000.0) - 4500.0) * tdir
			draw_rect(Rect2(tax - tdir * 70.0, -tay, 70.0, 6.0), Color(1.0, 0.9, 0.6, 0.35))
			draw_circle(Vector2(tax, -tay + 3.0), 12.0, Color(1.0, 0.95, 0.8))
		# the ground at their feet
		if y_lo < 60.0:
			draw_rect(Rect2(-40000.0, 0.0, 80000.0, 4000.0), Color(0.2, 0.2, 0.27).lerp(Color(0.07, 0.07, 0.12), night))
			for gl in 10:
				draw_rect(Rect2(-6000.0, 24.0 + gl * 46.0, 12000.0, 2.0), Color(1, 1, 1, 0.035))
			var lr := clampf(3.0 / sc, 4.0, 14.0)
			for pl in 40:
				var lpos := Vector2(-1500.0 + Gen.TowerArt.hsh(pl, 8) * 3000.0, 40.0 + Gen.TowerArt.hsh(pl, 9) * 300.0)
				var lcol: Color = [Color(1.0, 0.36, 0.66), Color(0.3, 0.9, 1.0), Color(1.0, 0.82, 0.25), Color(0.55, 1.0, 0.6)][pl % 4]
				draw_circle(lpos, lr * 3.0, Color(lcol, 0.12))
				draw_circle(lpos, lr, Color(lcol, 0.85))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# the floors' names beside the rails (window px), yours in gold
		var tiers: Array = Gen.TowerArt.SPECS[2]["tiers"]
		for i2 in Gen.CAS_FLOORS.size():
			var fa: float = Gen.CAS_ALT[i2]
			var sy := org.y - (fa + 43.0) * sc
			if sy < 40.0 or sy > h - 96.0:
				continue
			var hw := 560.0
			for tr2 in tiers:
				if fa >= float(tr2[0]):
					hw = float(tr2[2])
			var lx := org.x + minf((hw + 70.0) * sc, 190.0 * h / 1080.0)
			var on2 := i2 == b
			var txt := "%d   %s" % [i2 + 1, String(Gen.CAS_FLOORS[i2])]
			var tw2 := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16).x
			draw_rect(Rect2(lx - 8.0, sy - 14.0, tw2 + 16.0, 24.0), Color(0.02, 0.02, 0.06, 0.62))
			if on2:
				draw_rect(Rect2(lx - 8.0, sy - 14.0, tw2 + 16.0, 24.0), Color(gold, 0.9), false, 1.5)
			draw_line(Vector2(org.x + (RAIL_X + 12.0) * sc, sy), Vector2(lx - 8.0, sy), Color(gold if on2 else Color(0.7, 0.75, 0.9), 0.7), 1.5)
			draw_string(font, Vector2(lx, sy + 5.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, gold if on2 else Color(0.8, 0.84, 0.95, 0.9 if i2 == a else 0.6))
		# what rides where, how high
		draw_rect(Rect2(0.0, h - 78.0, w, 78.0), Color(0.0, 0.0, 0.03, 0.55))
		draw_string(font, Vector2(0.0, h - 46.0), "The Grand Centauria", HORIZONTAL_ALIGNMENT_CENTER, w, 20, gold)
		draw_string(font, Vector2(0.0, h - 20.0), "%s  to  %s      %d m      %s" % [String(Gen.CAS_FLOORS[a]), String(Gen.CAS_FLOORS[b]), int(cy * 0.12), hint],
			HORIZONTAL_ALIGNMENT_CENTER, w, 14, Color(0.8, 0.9, 1.0))
		var out := clampf((_t - FADE - dur) / FADE, 0.0, 1.0)
		if out > 0.0:
			draw_rect(Rect2(0.0, 0.0, w, h), Color(0.0, 0.0, 0.0, out))


## The car from inside, a metro car: the window wall to the north with three doors in it, seats along both walls
## facing the aisle, grab poles by the doors, a rubber floor with the line's stripe, the line's board over the doors.
static func build_car(station: Dictionary, line: String) -> GroundMap:
	var ln: Dictionary = LINES[line]
	var col: Color = ln["col"]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(station.get("id", "x"))) + 611 + line.unicode_at(0)
	var m := GroundMap.new()
	MuseumGen._pal(m, {})
	m.pal["floor"] = Color(0.3, 0.32, 0.38)
	m.pal["floor2"] = Color(0.26, 0.28, 0.34)
	m.pal["wall"] = Color(0.84, 0.86, 0.9)
	m.pal["wall_top"] = Color(0.62, 0.65, 0.72)
	m.pal["frame"] = Color(0.84, 0.86, 0.9)
	m.pal["accent"] = col
	m.style = "museum"
	m.title = "Centauria"
	m.hull_top = -9999
	m.set_meta("no_guards", true)
	var W := CW + C_X * 2
	var H := 13
	m.setup(W, H)
	m.fill(C_X - 1, C_WIN - 1, CW + 2, C_FLOOR + 4 - C_WIN + 2, T.CAP)
	m.fill(C_X, C_WIN, CW, 3, T.GLASS)
	m.window_rect = Rect2(C_X, C_WIN, CW, 3)
	m.fill(C_X, C_FLOOR, CW, 4, T.FLOOR, 49)
	m.decals.append({"kind": "guide", "x": C_X, "y": C_FLOOR + 2, "w": CW, "h": 1, "col": col})
	# three doors in the window wall, the line's board over the middle one
	var dmid := C_X + CW / 2 - 1
	var doors := [C_X + 5, dmid, C_X + CW - 7]
	for d in doors:
		m.decals.append({"kind": "car_door", "x": d, "y": C_FLOOR, "w": 2, "h": 1, "col": col})
		for pole in [d - 1, d + 2]:
			m.add_object({"kind": "car_pole", "x": pole, "y": C_FLOOR + 1, "w": 1, "h": 1, "rise": (C_FLOOR + 2 - C_WIN) * TILE - TILE - 10})
	m.set_meta("ctr_screen", Vector2(dmid + 1.0, C_WIN + 0.55) * TILE)        # (Luz) a little screen over the middle door
	m.set_meta("ctr_doors", doors.map(func(dd): return Rect2(Vector2(int(dd), C_WIN + 1) * TILE, Vector2(2, 2) * TILE)))
	# seats along both walls, facing the aisle; people in some of them
	var seat_c: Color = col.darkened(0.35)
	for sx in range(C_X, C_X + CW):
		var by_door := false
		for d2 in doors:
			by_door = by_door or (sx >= int(d2) - 1 and sx <= int(d2) + 2)
		if not by_door:
			DeckGen._seat(m, "chair", sx, C_FLOOR, 0, seat_c, rng, 0.3)
		if sx > C_X and sx < C_X + CW - 1 and sx % 6 != 0:
			DeckGen._seat(m, "chair", sx, C_FLOOR + 3, 1, seat_c, rng, 0.3)
	for d3 in doors:                                              # (Luz) every door is a way off, not only the middle one
		_zone(m, Rect2(int(d3) - 0.3, C_FLOOR - 0.1, 2.6, 1.4), "ctr_alight", "Get off", col, {"closed": "The doors are shut: the train is running.",
			"id": "ctr_alight_%d" % int(d3)})
	m.set_meta("rail_front", Vector2(dmid + 1.0, C_FLOOR + 1.5) * TILE)
	m.spawn = m.get_meta("rail_front")
	m.set_meta("ctr_line", line)
	m.set_meta("tourists", 3)
	for lx in range(C_X + 4, C_X + CW, 8):
		m.lights.append({"pos": Vector2(lx, C_FLOOR + 1.5) * TILE, "r": 90.0, "col": Color(1.0, 0.95, 0.85), "a": 0.22})
	DeckGen._seats(m)
	for k in 5:
		m.wander.append(Vector2(C_X + 3.0 + k * 6.0, C_FLOOR + 1.6) * TILE)
	return m


## The tracks of a station with their trains and screens, drawn over the map and under the people (art px).
## The trains come out of a tunnel at one end of the hall and leave into the one at the other (Luz: they were seen
## out beyond the station); sleek and low, a nose at each end, one band of dark glass, the line's colour in light.
class RailFx extends Node2D:
	const Gen = preload("res://scripts/ground/centauria_gen.gd")
	var tracks: Array = []
	var stop := 0
	var width := 0.0                 # the hall's width (art px)

	func _process(_dt: float) -> void:
		queue_redraw()

	## How far along its track the train stands from its place at the platform (0 = there, ±1 = out of the hall).
	func offset(line: String, t: float) -> float:
		var st: Dictionary = Gen.state(line, t)
		if int(st["at"]) == stop:
			return 0.0
		if int(st["at"]) >= 0:
			return 9.0                               # standing at the other end of the line
		var tr := float(st["k"]) * float(st["ride"])
		if int(st["from"]) == stop and tr < Gen.ROLL:
			return ease(tr / Gen.ROLL, 2.2)          # pulling out
		if int(st["to"]) == stop and float(st["ride"]) - tr < Gen.ROLL:
			return -(1.0 - ease(1.0 - (float(st["ride"]) - tr) / Gen.ROLL, 0.45))      # coming in from the other side
		return 9.0

	func _draw() -> void:
		var t := GameState.play_time
		var font := ThemeDB.fallback_font
		var mouth := 22.0                            # how deep a tunnel mouth stands in the hall
		for tr in tracks:
			var y := float(tr["y"])
			var h := float(tr["h"])
			var ln: Dictionary = Gen.LINES[String(tr["line"])]
			var col: Color = ln["col"]
			# the bed: a dark trough, a glowing guide rail (the trains float over it)
			draw_rect(Rect2(0, y, width, h), Color(0.05, 0.05, 0.08))
			draw_rect(Rect2(0, y + h * 0.5 - 5.0, width, 10.0), Color(0.1, 0.11, 0.15))
			draw_rect(Rect2(0, y + h * 0.5 - 1.0, width, 2.0), Color(col, 0.55))
			var xs := 8.0
			while xs < width:
				draw_rect(Rect2(xs, y + h * 0.5 - 4.0, 2.0, 8.0), Color(0.22, 0.24, 0.3))
				xs += 12.0
			# the train
			var off := offset(String(tr["line"]), t)
			if absf(off) < 1.5:
				var tl := width * 0.8
				var tx := (width - tl) * 0.5 + off * float(tr["dir"]) * width * 1.02
				var ty := y + 5.0
				var th := h - 13.0
				var open := absf(off) < 0.001
				var body := Color(0.86, 0.88, 0.93)
				# the glow under it
				draw_rect(Rect2(tx + 10.0, ty + th, tl - 20.0, 3.0), Color(col, 0.6))
				draw_rect(Rect2(tx + 4.0, ty + th + 3.0, tl - 8.0, 3.0), Color(col, 0.2))
				# the hull: a long body with a pointed nose at each end
				var nose := 26.0
				draw_colored_polygon(PackedVector2Array([Vector2(tx, ty + th * 0.62), Vector2(tx + nose, ty), Vector2(tx + tl - nose, ty),
					Vector2(tx + tl, ty + th * 0.62), Vector2(tx + tl - 6.0, ty + th), Vector2(tx + 6.0, ty + th)]), body)
				draw_colored_polygon(PackedVector2Array([Vector2(tx, ty + th * 0.62), Vector2(tx + tl, ty + th * 0.62),
					Vector2(tx + tl - 6.0, ty + th), Vector2(tx + 6.0, ty + th)]), body.darkened(0.25))
				# one band of dark glass, the cockpits in the noses
				draw_rect(Rect2(tx + nose + 4.0, ty + 5.0, tl - nose * 2.0 - 8.0, th * 0.34), Color(0.06, 0.09, 0.16))
				for ns in [0, 1]:
					var nx := tx + (6.0 if ns == 0 else tl - 6.0)
					var nd := 1.0 if ns == 0 else -1.0
					draw_colored_polygon(PackedVector2Array([Vector2(nx + nd * 3.0, ty + th * 0.52), Vector2(nx + nd * 20.0, ty + 4.0),
						Vector2(nx + nd * 24.0, ty + 4.0), Vector2(nx + nd * 24.0, ty + th * 0.52)]), Color(0.1, 0.16, 0.26))
				# the light inside, the line's colour as a strip of light along the hull
				var wx := tx + nose + 8.0
				while wx < tx + tl - nose - 14.0:
					draw_rect(Rect2(wx, ty + 7.0, 10.0, th * 0.34 - 4.0), Color(1.0, 0.94, 0.74, 0.5))
					wx += 16.0
				draw_rect(Rect2(tx + nose - 6.0, ty + th * 0.62 - 2.0, tl - nose * 2.0 + 12.0, 3.0), col)
				# the joints between the three cars, the doors (open while it stands)
				for jt in [1, 2]:
					draw_rect(Rect2(tx + tl * jt / 3.0 - 1.5, ty, 3.0, th), Color(0.08, 0.08, 0.12))
				var dop: float = Gen.doors(String(tr["line"]), stop, t) if open else 0.0
				for dk in [0.17, 0.34, 0.5, 0.66, 0.83]:
					var dx: float = tx + tl * float(dk) - 7.0
					# (Luz) the doors slide: two leaves parting, the light of the car in the gap
					if dop > 0.0:
						draw_rect(Rect2(dx + 7.0 - 7.0 * dop, ty + 4.0, 14.0 * dop, th - 5.0), Color(1.0, 0.95, 0.8, 0.95))
						draw_rect(Rect2(dx - 1.0, ty + 3.0, 16.0, 2.0), col)
					for leaf in [-1.0, 1.0]:
						var lx2: float = dx + (0.0 if leaf < 0.0 else 7.0) + leaf * 6.5 * dop
						draw_rect(Rect2(lx2, ty + 4.0, 7.0, th - 5.0), body.darkened(0.06))
						draw_rect(Rect2(lx2 + 1.5, ty + 6.0, 4.0, 6.0), Color(0.1, 0.16, 0.26))
						draw_rect(Rect2(lx2, ty + 4.0, 7.0, th - 5.0), body.darkened(0.3), false, 1.0)
				# its lights: white ahead, red behind
				var fwd := float(tr["dir"]) > 0.0
				draw_rect(Rect2(tx + (tl - 5.0 if fwd else 1.0), ty + th * 0.56, 4.0, 4.0), Color(1.0, 0.97, 0.8))
				draw_rect(Rect2(tx + (1.0 if fwd else tl - 5.0), ty + th * 0.56, 4.0, 4.0), Color(1.0, 0.25, 0.2))
			# the tunnel mouths at both ends of the hall: the train comes out of the dark and goes back into it
			for side in [0, 1]:
				var mx := -4000.0 if side == 0 else width - mouth
				var mw := 4000.0 + mouth if side == 0 else 4000.0 + mouth
				draw_rect(Rect2(mx, y - 3.0, mw, h + 6.0), Color(0.0, 0.0, 0.0))
				var ex := mouth if side == 0 else width - mouth
				draw_rect(Rect2(ex - (4.0 if side == 0 else 0.0), y - 3.0, 4.0, h + 6.0), Color(0.3, 0.32, 0.4))
				draw_rect(Rect2(ex - (2.0 if side == 0 else -2.0), y, 2.0, h), Color(col, 0.7))
				for cz in 4:
					draw_rect(Rect2(ex - (10.0 + cz * 4.0 if side == 0 else -(6.0 + cz * 4.0)), y + 3.0 + cz * (h - 8.0) / 3.0, 3.0, 2.0), Color(1.0, 0.8, 0.2))
			# the screen hung over the track: a bezel, dark glass, the line's lamp, the text
			var txt: String = Gen.board_text(String(tr["line"]), stop, t)
			var north := float(tr["dir"]) > 0.0
			var bw := 232.0
			var bh := 17.0
			var bx := 40.0 if north else width - bw - 40.0
			var by := y - bh - 4.0 if north else y + h + 4.0
			for arm in [bx + 20.0, bx + bw - 22.0]:
				draw_rect(Rect2(arm, by - 5.0 if north else by + bh, 2.0, 5.0), Color(0.45, 0.47, 0.55))
			draw_rect(Rect2(bx - 2.0, by - 2.0, bw + 4.0, bh + 4.0), Color(0.3, 0.32, 0.38))
			draw_rect(Rect2(bx, by, bw, bh), Color(0.02, 0.04, 0.08))
			for sl in range(0, int(bh), 2):
				draw_rect(Rect2(bx, by + sl, bw, 1.0), Color(1, 1, 1, 0.03))
			draw_rect(Rect2(bx + 4.0, by + 4.0, 9.0, 9.0), col if int(t * 2.0) % 2 == 0 or Gen.next_at(String(tr["line"]), stop, t) > 5.0 else col.darkened(0.6))
			draw_string(font, Vector2(bx + 18.0, by + 12.5), txt, HORIZONTAL_ALIGNMENT_LEFT, bw - 22.0, 9, Color(0.75, 0.95, 1.0))


## Inside the car: the doors in the window wall, sliding open at a stop and shut before it leaves (Luz), and the
## little screen over the middle door: "ARRIVAL 12 s" on the way, "DEPARTS 8 s" at a stop. (art px, under the people)
class CarScreen extends Node2D:
	const Gen = preload("res://scripts/ground/centauria_gen.gd")
	var line := "A"
	var at := Vector2.ZERO           # the screen's middle
	var doors: Array = []            # the doorways (Rect2)

	func _process(_dt: float) -> void:
		queue_redraw()

	func text() -> String:
		var st: Dictionary = Gen.state(line, GameState.play_time)
		var secs := int(ceil(float(st["left"])))
		return ("DEPARTS %d s" % secs) if int(st["at"]) >= 0 else ("ARRIVAL %d s" % secs)

	## How far the doors stand open now (0 … 1).
	func open() -> float:
		var st: Dictionary = Gen.state(line, GameState.play_time)
		return Gen.doors(line, int(st["at"]), GameState.play_time) if int(st["at"]) >= 0 else 0.0

	func _draw() -> void:
		var col: Color = Gen.LINES[line]["col"]
		var op := open()
		for r in doors:
			var d: Rect2 = r
			var half := d.size.x * 0.5
			# the frame, then the two leaves parting (the platform shows in the gap)
			draw_rect(Rect2(d.position - Vector2(2, 2), Vector2(d.size.x + 4.0, 3.0)), col)
			for leaf in [-1.0, 1.0]:
				var lx: float = d.position.x + (0.0 if leaf < 0.0 else half) + leaf * (half - 3.0) * op
				var lw := half
				if leaf < 0.0:
					lw = half - maxf(d.position.x - lx, 0.0)
					lx = maxf(lx, d.position.x - half + 3.0)
				draw_rect(Rect2(lx, d.position.y, half, d.size.y), Color(0.82, 0.84, 0.9))
				draw_rect(Rect2(lx + 3.0, d.position.y + 5.0, half - 6.0, d.size.y * 0.42), Color(0.45, 0.62, 0.85, 0.85))
				draw_rect(Rect2(lx, d.position.y, half, d.size.y), col, false, 1.5)
				draw_rect(Rect2(lx + 2.0, d.position.y + d.size.y - 5.0, half - 4.0, 2.0), col)
		var w := 74.0
		var h := 13.0
		var o := at - Vector2(w * 0.5, h * 0.5)
		draw_rect(Rect2(o - Vector2(2, 2), Vector2(w + 4.0, h + 4.0)), Color(0.3, 0.32, 0.38))
		draw_rect(Rect2(o, Vector2(w, h)), Color(0.02, 0.04, 0.08))
		draw_rect(Rect2(o + Vector2(3, 3), Vector2(7, 7)), col)
		draw_string(ThemeDB.fallback_font, o + Vector2(14.0, 10.0), text(), HORIZONTAL_ALIGNMENT_LEFT, w - 16.0, 8, Color(0.75, 0.95, 1.0))


## What the car's windows show (window px). At a stop: the station's wall. Then a tunnel (Luz): the ride begins and
## ends in one. In between, for about fifteen seconds, the city: the sky with Lapis and its rings, far behind
## everything the line's landmark, big (the casino towers, grand and gaudy / the stadium), the sea, the island's
## skyline in three layers; at night neon, laser shows, fireworks.
class Panorama extends Node2D:
	const Gen = preload("res://scripts/ground/centauria_gen.gd")
	const ROUTE := 2600.0            # how far the view runs in the open (px of the nearest layer)
	var size := Vector2.ZERO
	var line := "A"
	var night := 0.0                 # 0 day … 1 night
	var _t := 0.0
	var _sparks: Array = []          # fireworks: {x, y, t, col}

	func setup(p_size: Vector2, p_line: String, p_night: float) -> void:
		size = p_size
		line = p_line
		night = p_night

	## What is outside: {"mode": "station" | "tunnel" | "open", "a": how far along the open stretch, "cover": how much
	## of the window the tunnel's wall still (or already) hides, "cover_right": on which side, "run": how fast}.
	func view() -> Dictionary:
		var st: Dictionary = Gen.state(line, GameState.play_time)
		if int(st["at"]) >= 0:
			return {"mode": "station", "a": 0.0, "cover": 1.0, "cover_right": false, "run": 0.0, "shift": 0.0, "stop": int(st["at"]), "drift": 0.0}
		var ride := float(st["ride"])
		var tr := float(st["k"]) * ride
		var out := int(st["from"]) == 0
		# (Luz) pulling out, the station drifts off behind the train and the tunnel takes its place; coming in, the next
		# one slides into the windows
		var dsec := 2.4
		if tr < dsec:
			var dd := size.x * 1.25 * pow(tr / dsec, 2.0)
			return {"mode": "station", "a": 0.0, "cover": 1.0, "cover_right": false, "run": 0.0, "shift": dd * (1.0 if out else -1.0), "stop": int(st["from"]),
				"drift": -dd * (1.0 if out else -1.0)}
		if ride - tr < dsec:
			var da := size.x * 1.25 * pow((ride - tr) / dsec, 2.0)
			return {"mode": "station", "a": 0.0, "cover": 1.0, "cover_right": false, "run": 0.0, "shift": -da * (1.0 if out else -1.0), "stop": int(st["to"]),
				"drift": da * (1.0 if out else -1.0)}
		var ko := clampf((tr - Gen.TUNNEL) / maxf(ride - Gen.TUNNEL * 2.0, 0.1), 0.0, 1.0)
		var a := (ko if out else 1.0 - ko) * ROUTE
		var run := clampf(minf(tr, ride - tr) / Gen.ROLL, 0.0, 1.0)       # speeding up, slowing down
		var shift := tr * 520.0 * (1.0 if out else -1.0)
		if tr < Gen.TUNNEL - 0.5 or tr > ride - Gen.TUNNEL + 0.5:
			return {"mode": "tunnel", "a": a, "cover": 1.0, "cover_right": false, "run": run, "shift": shift}
		if tr < Gen.TUNNEL:
			# out of the tunnel: its wall slides away behind the train
			return {"mode": "open", "a": a, "cover": 1.0 - (tr - (Gen.TUNNEL - 0.5)) / 0.5, "cover_right": not out, "run": run, "shift": shift}
		if tr > ride - Gen.TUNNEL:
			return {"mode": "open", "a": a, "cover": (tr - (ride - Gen.TUNNEL)) / 0.5, "cover_right": out, "run": run, "shift": shift}
		return {"mode": "open", "a": a, "cover": 0.0, "cover_right": false, "run": run, "shift": shift}

	func _process(dt: float) -> void:
		_t += dt
		if night > 0.5:
			if randf() < dt * 0.6:
				_sparks.append({"x": randf_range(0.1, 0.9) * size.x, "y": randf_range(0.08, 0.4) * size.y, "t": 0.0,
					"col": [Color(1.0, 0.4, 0.7), Color(0.4, 0.9, 1.0), Color(1.0, 0.85, 0.3), Color(0.6, 1.0, 0.6), Color(0.75, 0.55, 1.0)][randi() % 5]})
			for s in _sparks:
				s["t"] = float(s["t"]) + dt
			_sparks = _sparks.filter(func(s): return float(s["t"]) < 1.6)
		queue_redraw()

	func _h(i: int, salt: int) -> float:
		return fposmod(sin(float(i) * 12.9898 + float(salt) * 78.233) * 43758.5453, 1.0)

	func _draw() -> void:
		var v := view()
		if String(v["mode"]) == "station":
			var dr := float(v["drift"])
			if absf(dr) > 0.5:
				_wall(0.0, size.x, float(v["shift"]), false)       # the tunnel where the station has gone
			_station(dr, int(v["stop"]))
			return
		if String(v["mode"]) == "tunnel":
			_wall(0.0, size.x, float(v["shift"]), false)
			return
		_city(float(v["a"]))
		var cov := float(v["cover"])
		if cov > 0.001:
			var cw := size.x * cov
			var x0 := size.x - cw if bool(v["cover_right"]) else 0.0
			_wall(x0, cw, float(v["shift"]), false)
			draw_rect(Rect2((x0 - 6.0) if bool(v["cover_right"]) else (x0 + cw), 0, 6.0, size.y), Color(0.32, 0.34, 0.42))      # the portal's edge

	## (Luz) the station outside the windows, as from the train: the hall's wall with its band and name, the screens,
	## pillars of light or marble columns and banners, benches, people waiting, the platform's edge. x0 = where its
	## left end stands (it drifts as the train pulls out).
	func _station(x0: float, stop: int) -> void:
		var w := size.x
		var h := size.y
		if x0 > w or x0 < -w:
			return
		var marble := stop == 2
		var accent: Color = Color(0.3, 0.9, 1.0) if stop == 0 else (Color(1.0, 0.36, 0.66) if stop == 1 else Color(1.0, 0.82, 0.35))
		var wall := Color(0.93, 0.93, 0.95) if marble else (Color(0.36, 0.3, 0.46) if stop == 1 else Color(0.3, 0.34, 0.44))
		var floor_c := Color(0.86, 0.86, 0.9) if marble else (Color(0.5, 0.46, 0.6) if stop == 1 else Color(0.42, 0.46, 0.56))
		var fy := h * 0.7
		draw_rect(Rect2(x0, 0, w, fy), wall)
		var tx := x0
		while tx < x0 + w:
			draw_rect(Rect2(tx, 0, 2.0, fy), wall.darkened(0.12))
			tx += 54.0
		draw_rect(Rect2(x0, h * 0.1, w, 4.0), accent)
		draw_rect(Rect2(x0, 0, w, 3.0), Color(1.0, 0.97, 0.9))                         # the light along the ceiling
		# the floor, the yellow line along the platform's edge
		draw_rect(Rect2(x0, fy, w, h - fy), floor_c)
		draw_rect(Rect2(x0, h - 9.0, w, 4.0), Color(1.0, 0.82, 0.25))
		var font := ThemeDB.fallback_font
		var name := String(Gen.STOPS[stop]).to_upper()
		for k in 2:
			var sx := x0 + w * (0.34 + k * 0.32)             # (between the car's doors, so the signs are not hidden)
			# the name in a lit sign, a pillar of light or a column beside it, a bench, people
			draw_rect(Rect2(sx - 120.0, h * 0.2, 240.0, 26.0), Color(0.03, 0.04, 0.08))
			draw_rect(Rect2(sx - 120.0, h * 0.2, 240.0, 26.0), accent, false, 2.0)
			draw_string(font, Vector2(sx - 116.0, h * 0.2 + 18.0), name, HORIZONTAL_ALIGNMENT_CENTER, 232.0, 13, accent.lightened(0.3))
			var px := sx - 190.0 if k == 0 else sx + 190.0
			if marble:
				draw_rect(Rect2(px - 9.0, h * 0.14, 18.0, fy - h * 0.14 + 10.0), Color(1, 1, 1))
				draw_rect(Rect2(px - 12.0, h * 0.14, 24.0, 6.0), Color(1.0, 0.82, 0.35))
				draw_rect(Rect2(px - 70.0, h * 0.18, 3.0, fy - h * 0.18), Color(0.8, 0.8, 0.85))
				draw_rect(Rect2(px - 67.0, h * 0.2, 30.0, 46.0), Color(0.85, 0.2, 0.22))
				draw_rect(Rect2(px - 60.0, h * 0.2 + 12.0, 16.0, 10.0), Color(1.0, 0.82, 0.35))
			else:
				var pc: Color = [Color(1.0, 0.36, 0.66), Color(1.0, 0.82, 0.25), Color(0.55, 1.0, 0.6)][(k + stop) % 3]
				draw_rect(Rect2(px - 16.0, h * 0.3, 32.0, fy - h * 0.3 + 6.0), Color(pc, 0.18))
				draw_rect(Rect2(px - 5.0, h * 0.3, 10.0, fy - h * 0.3 + 6.0), Color(pc, 0.9))
				draw_rect(Rect2(px - 9.0, fy + 2.0, 18.0, 6.0), Color(0.25, 0.25, 0.32))
			draw_rect(Rect2(sx - 60.0, fy - 14.0, 84.0, 8.0), Color(0.6, 0.16, 0.2))
			draw_rect(Rect2(sx - 56.0, fy - 6.0, 4.0, 10.0), Color(0.3, 0.1, 0.12))
			draw_rect(Rect2(sx + 16.0, fy - 6.0, 4.0, 10.0), Color(0.3, 0.1, 0.12))
			for q in 3:
				var hx := sx - 150.0 + q * 34.0 + _h(k * 7 + q, stop + 3) * 20.0
				var hc: Color = [Color(0.85, 0.3, 0.5), Color(0.3, 0.6, 0.85), Color(0.9, 0.7, 0.25), Color(0.4, 0.75, 0.5)][int(_h(k * 5 + q, stop + 9) * 4.0) % 4]
				draw_rect(Rect2(hx - 5.0, fy - 28.0, 10.0, 30.0), hc.darkened(0.25))
				draw_rect(Rect2(hx - 4.0, fy - 38.0, 8.0, 10.0), Color(0.86, 0.68, 0.55))
		# the portals at both ends of the hall
		draw_rect(Rect2(x0 - 10.0, 0, 10.0, h), Color(0.3, 0.32, 0.4))
		draw_rect(Rect2(x0 + w, 0, 10.0, h), Color(0.3, 0.32, 0.4))

	## A wall right outside the glass: the station's (lit tiles, a band in the line's colour) or the tunnel's (dark
	## rings of concrete, cables, lamps flying by).
	func _wall(x0: float, w: float, shift: float, station: bool) -> void:
		var h := size.y
		var col: Color = Gen.LINES[line]["col"]
		if station:
			draw_rect(Rect2(x0, 0, w, h), Color(0.62, 0.64, 0.7))
			var tx := x0
			while tx < x0 + w:
				draw_rect(Rect2(tx, 0, 2.0, h), Color(0.5, 0.52, 0.58))
				tx += 46.0
			draw_rect(Rect2(x0, h * 0.2, w, 5.0), col)
			draw_rect(Rect2(x0, h * 0.72, w, 3.0), Color(0.45, 0.47, 0.53))
			return
		draw_rect(Rect2(x0, 0, w, h), Color(0.05, 0.05, 0.08))
		var rx := fposmod(-shift, 70.0) - 70.0
		while rx < size.x:
			if rx + 6.0 > x0 and rx < x0 + w:
				draw_rect(Rect2(maxf(rx, x0), 0, 6.0, h), Color(0.11, 0.11, 0.15))
			rx += 70.0
		for cy in [0.3, 0.38, 0.8]:
			draw_rect(Rect2(x0, h * float(cy), w, 2.0), Color(0.16, 0.16, 0.2))
		var lx := fposmod(-shift * 1.0, 240.0) - 240.0
		while lx < size.x:
			if lx + 26.0 > x0 and lx < x0 + w:
				draw_rect(Rect2(maxf(lx, x0), h * 0.14, 26.0, 5.0), Color(1.0, 0.92, 0.7))
				draw_rect(Rect2(maxf(lx - 8.0, x0), h * 0.14 - 4.0, 42.0, 13.0), Color(1.0, 0.9, 0.6, 0.12))
			lx += 240.0

	## The landmark far behind the city: the casino's towers (Luz: in the background, bigger, more pompous) or the
	## stadium. It moves slowly, so it stays in sight for most of the ride.
	func _landmark(a: float, sea_y: float) -> void:
		var w := size.x
		var h := size.y
		var mx := w * 0.5 + (ROUTE * 0.5 - a) * 0.22
		var dim := 0.5 if night > 0.5 else 0.0
		if String(Gen.LINES[line]["view"]) == "casino":
			# five towers: the great one in the middle taller than the window, stepped and crowned, gold edges, bands
			# of running light, a dome between them, searchlights at night
			var specs := [[-250.0, 70.0, 0.74, Color(0.36, 0.2, 0.72)], [-135.0, 86.0, 0.98, Color(0.82, 0.22, 0.56)], [0.0, 120.0, 1.3, Color(0.62, 0.24, 0.9)],
				[135.0, 86.0, 0.98, Color(0.95, 0.5, 0.2)], [250.0, 70.0, 0.74, Color(0.2, 0.55, 0.85)]]
			draw_rect(Rect2(mx - 330.0, sea_y - h * 0.16, 660.0, h * 0.16 + h), Color(0.5, 0.42, 0.62).darkened(dim))         # the podium they stand on
			for sp in specs:
				var tx := mx + float(sp[0])
				var tw := float(sp[1])
				var thh := h * float(sp[2])
				var tc: Color = (sp[3] as Color).darkened(dim)
				var top := sea_y - thh
				draw_rect(Rect2(tx - tw * 0.5, top + thh * 0.18, tw, thh), tc)
				draw_rect(Rect2(tx - tw * 0.36, top + thh * 0.06, tw * 0.72, thh), tc.lightened(0.08))                       # the setback
				draw_rect(Rect2(tx - tw * 0.2, top - thh * 0.02, tw * 0.4, thh), tc.lightened(0.16))
				draw_colored_polygon(PackedVector2Array([Vector2(tx - tw * 0.2, top - thh * 0.02), Vector2(tx, top - thh * 0.16),
					Vector2(tx + tw * 0.2, top - thh * 0.02)]), Color(1.0, 0.82, 0.3))                                         # the crown
				draw_rect(Rect2(tx - 1.5, top - thh * 0.26, 3.0, thh * 0.1), Color(1.0, 0.9, 0.5))
				for edge in [-0.5, 0.5]:
					draw_rect(Rect2(tx + tw * float(edge) - 1.5, top + thh * 0.18, 3.0, thh), Color(1.0, 0.82, 0.3, 0.9))     # gold edges
				var rows := int(thh / 9.0)
				for r in rows:
					var lit := (r + int(_t * 4.0)) % 5 == 0
					draw_rect(Rect2(tx - tw * 0.5 + 5.0, top + thh * 0.2 + r * 9.0, tw - 10.0, 3.0), Color((sp[3] as Color).lightened(0.55), 0.95 if lit else (0.45 if night > 0.5 else 0.25)))
			draw_circle(Vector2(mx, sea_y - h * 0.16), 54.0, Color(1.0, 0.82, 0.3).darkened(dim * 0.6))                         # the golden dome
			draw_rect(Rect2(mx - 60.0, sea_y - h * 0.16, 120.0, h), Color(0.5, 0.42, 0.62).darkened(dim))
			if night > 0.5:
				for lz in 6:
					var ang := -PI * 0.5 + sin(_t * (0.35 + lz * 0.11) + lz * 1.7) * 0.8
					var p0 := Vector2(mx + (lz - 2.5) * 90.0, sea_y - h * 0.5)
					draw_line(p0, p0 + Vector2.from_angle(ang) * h * 1.2, Color([Color(1.0, 0.4, 0.7), Color(0.4, 0.9, 1.0), Color(1.0, 0.85, 0.3)][lz % 3], 0.3), 3.0)
		else:
			var sw2 := 620.0
			var top2 := sea_y - h * 0.5
			draw_rect(Rect2(mx - sw2 * 0.5, top2, sw2, h), Color(0.92, 0.92, 0.95).darkened(dim))
			for tier in 3:
				draw_rect(Rect2(mx - sw2 * 0.5 - 8.0, top2 + tier * h * 0.16, sw2 + 16.0, 6.0), Color(1.0, 0.82, 0.35).darkened(dim * 0.5))
				for cl2 in 22:
					draw_rect(Rect2(mx - sw2 * 0.5 + 10.0 + cl2 * (sw2 - 20.0) / 22.0, top2 + tier * h * 0.16 + 8.0, 12.0, h * 0.16 - 10.0), Color(0.12, 0.12, 0.18, 0.75))
			for fl in [-0.42, -0.2, 0.0, 0.2, 0.42]:
				draw_rect(Rect2(mx + float(fl) * sw2 - 1.0, top2 - h * 0.2, 2.0, h * 0.2), Color(0.8, 0.8, 0.85))
				draw_rect(Rect2(mx + float(fl) * sw2 + 1.0, top2 - h * 0.2, 20.0 + sin(_t * 3.0 + float(fl) * 9.0) * 3.0, 12.0), Color(0.85, 0.2, 0.22))
			if night > 0.5:
				draw_rect(Rect2(mx - sw2 * 0.5, top2 - 4.0, sw2, 4.0), Color(1.0, 0.92, 0.65))
				for lz2 in 4:
					var ang2 := -PI * 0.5 + sin(_t * (0.4 + lz2 * 0.13) + lz2) * 0.7
					var p1 := Vector2(mx + (lz2 - 1.5) * 150.0, top2)
					draw_line(p1, p1 + Vector2.from_angle(ang2) * h, Color(1.0, 0.95, 0.8, 0.28), 3.0)

	func _city(a: float) -> void:
		var w := size.x
		var h := size.y
		var sky_top := Color(0.24, 0.5, 0.86).lerp(Color(0.03, 0.03, 0.1), night)
		var sky_low := Color(0.72, 0.86, 0.98).lerp(Color(0.12, 0.06, 0.2), night)
		for i in 8:
			draw_rect(Rect2(0, h * 0.72 * i / 8.0, w, h * 0.72 / 8.0 + 1.0), sky_top.lerp(sky_low, i / 7.0))
		# Lapis with its rings, large behind everything (Luz: as it stands over the plaza; it barely moves)
		Gen.draw_lapis(self, Vector2(w * 0.74 - a * 0.012, h * 0.36), h * 0.86, night, _t, false)
		var sea_y := h * 0.72
		# the landmark, far behind everything; fireworks over it at night
		_landmark(a, sea_y)
		if night > 0.5:
			for s in _sparks:
				var st2 := float(s["t"])
				var rr := 8.0 + st2 * 46.0
				for q in 12:
					var d := Vector2.from_angle(q * TAU / 12.0) * rr
					draw_circle(Vector2(float(s["x"]), float(s["y"])) + d + Vector2(0.0, st2 * st2 * 10.0), 2.0, Color(s["col"], clampf(1.0 - st2 / 1.6, 0.0, 1.0)))
		# the sea
		draw_rect(Rect2(0, sea_y, w, h - sea_y), Color(0.08, 0.34, 0.6).lerp(Color(0.03, 0.06, 0.2), night))
		for i2 in 14:
			var wx := fposmod(_h(i2, 3) * w * 1.5 - a * 0.25, w * 1.5) - w * 0.25
			draw_rect(Rect2(wx, sea_y + 4.0 + _h(i2, 5) * (h - sea_y - 8.0), 26.0, 2.0), Color(0.75, 0.9, 1.0, 0.3 * (1.0 - night * 0.6)))
		# the skyline before it: middle and near – wilder and more colourful than other cities, kept low so the
		# landmark towers over it
		var neon := [Color(1.0, 0.36, 0.66), Color(0.3, 0.9, 1.0), Color(1.0, 0.82, 0.25), Color(0.55, 1.0, 0.6), Color(0.72, 0.5, 1.0), Color(1.0, 0.55, 0.25)]
		for layer in 2:
			var par: float = [0.55, 1.0][layer]
			var base: float = sea_y + float([4.0, 14.0][layer])
			var bw: float = [56.0, 76.0][layer]
			var n := int((ROUTE * par + w) / bw) + 2
			var shade: float = [0.32, 0.17][layer]
			for b in n:
				var x: float = b * bw - a * par
				if x < -bw or x > w:
					continue
				var bh: float = (0.08 + _h(b, layer * 7 + 1) * float([0.16, 0.26][layer])) * h
				var tint: Color = neon[int(_h(b, layer + 11) * neon.size()) % neon.size()]
				var body := Color(shade, shade, shade + 0.06).lerp(tint, 0.22 if night < 0.5 else 0.08)
				if night > 0.5:
					body = body.darkened(0.55)
				var top: float = base - bh
				draw_rect(Rect2(x, top, bw - 6.0, bh + (h - base)), body)
				if _h(b, layer + 23) > 0.6:
					draw_rect(Rect2(x + bw * 0.3, top - bh * 0.25, 4.0, bh * 0.25), body)
					draw_circle(Vector2(x + bw * 0.3 + 2.0, top - bh * 0.25), 2.5, tint if night > 0.5 else Color(0.9, 0.2, 0.2))
				var rows2 := int(bh / 9.0)
				for r2 in rows2:
					for cx2 in int((bw - 12.0) / 8.0):
						if _h(b * 31 + r2 * 7 + cx2, layer + 40) < (0.55 if night > 0.5 else 0.3):
							var wc: Color = tint if _h(b + r2, layer + 51) < 0.5 else Color(1.0, 0.92, 0.7)
							draw_rect(Rect2(x + 4.0 + cx2 * 8.0, top + 4.0 + r2 * 9.0, 4.0, 5.0), Color(wc, 0.95 if night > 0.5 else 0.5))
				if night > 0.5 and _h(b, layer + 60) > 0.55:
					draw_rect(Rect2(x + 3.0, top + bh * 0.4, bw - 12.0, 3.0), tint)
		# the viaduct's rail right outside the window
		draw_rect(Rect2(0, h - 5.0, w, 5.0), Color(0.12, 0.12, 0.16))
		var px := fposmod(-a * 2.4, 90.0)
		while px < w:
			draw_rect(Rect2(px, h - 14.0, 5.0, 14.0), Color(0.16, 0.16, 0.2))
			px += 90.0
