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
	_zone(m, Rect2(mid - 2, P_TOP, 4, 1.6), "ctr_closed", "The Grand Centauria: the casino", PURPLE, {"closed": "Opening soon. The tables are still being painted.", "id": "ctr_casino"})
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
	m.add_object({"kind": "barrier", "x": mid - 3, "y": P_TOP + 31, "w": 6, "h": 1})
	_zone(m, Rect2(mid - 3, P_TOP + 29.6, 6.0, 1.4), "ctr_closed", "The back alleys", GREEN, {"closed": "Barred for now. Somewhere behind it, a bass is thumping.", "id": "ctr_alleys"})
	m.lights.append({"pos": Vector2(mid, P_TOP + 30.5) * TILE, "r": 60.0, "col": GREEN, "a": 0.5, "flicker": true})
	# ---- west: the Museum and its plaza, as they stood on Curie (mirrored: the Museum at the far west)
	var cur: GroundMap = MuseumGen.build_plaza(station, {})
	var KX := 10                                      # (Curie's lift kiosk ends here: left out)
	var sw := cur.w - KX                              # 52
	var wx0 := cx0 - sw                               # the stamp's west edge
	_stamp(m, cur, KX, cur.w, 9, wx0, P_TOP + 9, true)             # the plaza's rows (from its railing down)
	_stamp(m, cur, cur.w - 24, cur.w, 0, wx0, P_TOP, true)         # the Museum itself, with its roof
	for z in m.zones:
		if String(z.get("title", "")) == "MUSEUM OF CURIE":
			z["title"] = "THE MUSEUM"
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
	m.zones.append({"rect": Rect2(Vector2(hdx, P_TOP + 17) * TILE, Vector2(4, 1.6) * TILE), "kind": "museum_go", "id": "ctr_hall", "to": "street", "at": "lift",
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
	static func draw(ci: CanvasItem, t: float, night: float, y_lo: float, y_hi: float, fine: bool) -> void:
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
			if absf(ax + 55.0) > 260.0:
				ci.draw_rect(Rect2(ax + 14.0, -128.0, 82.0, 128.0), Color(1.0, 0.86, 0.6, (0.75 if night > 0.5 else 0.4) * (0.7 + 0.3 * hsh(ai, 4))))
				ci.draw_rect(Rect2(ax + 14.0, -128.0, 82.0, 6.0), Color([Color(1.0, 0.36, 0.66), Color(0.3, 0.9, 1.0), gold][ai % 3], 0.95))
				ci.draw_rect(Rect2(ax + 53.0, -122.0, 3.0, 122.0), Color(0.07, 0.07, 0.14))
			ci.draw_rect(Rect2(ax, -300.0, 14.0, 300.0), Color(0.16, 0.17, 0.26))
			ax += 110.0
			ai += 1
		ci.draw_rect(Rect2(-1620.0, -308.0, 3240.0, 9.0), gold)
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
