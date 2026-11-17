extends RefCounted
## Package 54c (Luz): Aureola over Compline (Heimkehr, the Covenant) – the Hierarch's palace, at the one true scale
## (a tile ~1 m; mockup_54c_aureola_uebersicht / _portal / _rand, mockup_54c_palast_vorhalle, mockup_54c_palast).
## - the palace platform: a great disc over the red clouds, the palace's front (60 m high – near it you only ever see
##   its foot) on its north side, the forecourt with the sun mosaic, braziers, pools, the chaplain-admiral; a gilded
##   balustrade along the rim, the bridge to the city in the south. Under the rim the sea of clouds (CloudSea).
## - the lobby: a vaulted hall before the throne room – the guard in two rows along the runner, the Curia's chancery
##   (edict, tithe, petition, indulgence), the relic office (relics, blessing), pews for the waiting.
## - the throne room: the dais with the throne and the Hierarch, behind it the back wall rising with the great window
##   through which the star rises over the red clouds; only the Allied of the Covenant may step up for an audience.
## No class_name: preload it.

const T := GroundMap.T
const TILE := GroundMap.TILE
const MuseumGen = preload("res://scripts/ground/museum_gen.gd")
const CRED := Color(0.62, 0.12, 0.12)
const GOLD := Color(0.88, 0.68, 0.3)
const WARM := Color(1.0, 0.85, 0.6)

# the platform
const PW := 120
const PH := 92
const FRONT_X := 12                 # the palace front: x 12 … 106 (95 m), rows 0 … 21 (its foot at row 22)
const FRONT_W := 95
const FRONT_ROWS := 22
const DISC := Vector2(60.0, 0.0)    # the disc's centre (under the palace) and radii, in tiles
const DISC_R := Vector2(60.0, 76.0)


static func _go(m: GroundMap, r: Rect2, to: String, at: String, title: String, col: Color) -> void:
	m.zones.append({"rect": Rect2(r.position * TILE, r.size * TILE), "kind": "museum_go", "id": "capital_go", "to": to, "at": at,
		"title": title, "col": col, "sign": Vector2(-100, -100)})


static func _zone(m: GroundMap, r: Rect2, kind: String, title: String, col: Color) -> void:
	m.zones.append({"rect": Rect2(r.position * TILE, r.size * TILE), "kind": kind, "id": kind, "title": title, "col": col, "sign": Vector2(-100, -100)})


static func _warm_pal(m: GroundMap, body: Dictionary) -> void:
	MuseumGen._pal(m, body)
	m.pal["floor"] = Color(0.84, 0.78, 0.68)
	m.pal["floor2"] = Color(0.74, 0.68, 0.58)
	m.pal["wall"] = Color(0.86, 0.8, 0.7)
	m.pal["trim"] = Color(0.62, 0.55, 0.45)
	m.pal["accent"] = GOLD


## The rim's row at column x: the deck runs to it, the balustrade stands on it.
static func rim_at(x: int) -> int:
	var k := (float(x) + 0.5 - DISC.x) / DISC_R.x
	return int(DISC_R.y * sqrt(maxf(0.0, 1.0 - k * k)))


# ---------------------------------------------------------------- the palace platform

static func build_platform(station: Dictionary, body: Dictionary) -> GroundMap:
	var m := GroundMap.new()
	CloudGenP._base(m, station, "Aureola: the Palace of the Hierarch")
	m.remove_meta("few_guards")
	m.pal["floor"] = Color(0.86, 0.8, 0.7)                        # warm pale stone (the mockup), not the plaza's own
	m.pal["floor2"] = Color(0.78, 0.72, 0.62)
	m.set_meta("rim_warm", true)
	m.setup(PW, PH)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5410
	var curve: Array = []
	for x in PW:
		var ry := rim_at(x)
		curve.append(ry)
		if ry < 2:
			continue
		for y in ry:
			m.set_t(x, y, T.FLOOR, 47)
			if y < FRONT_ROWS + 1:
				m.set_t(x, y, T.BLOCK, 47)                      # beside the palace: deck seen, not walked
		m.set_t(x, ry, T.BLOCK, 47)
		m.decals.append({"kind": "cov_rail", "x": x, "y": ry, "w": 1, "h": 1})
		for fy in range(ry + 1, mini(ry + 4, PH)):
			m.set_t(x, fy, T.FACE)
	m.set_meta("rim_curve", curve)
	# (Luz) where the rim drops from one column to the next, the deck's side gets its balustrade too
	for x2 in PW:
		var r0: int = curve[x2]
		if r0 < 2:
			continue
		for nb in [-1, 1]:
			var rn: int = curve[x2 + nb] if x2 + nb >= 0 and x2 + nb < PW else 0
			for ys in range(maxi(rn + 1, 0), r0):
				m.set_t(x2, ys, T.BLOCK, 47)
				m.decals.append({"kind": "cov_rail", "x": x2, "y": ys, "w": 1, "h": 1, "side": true, "edge": nb})
	m.set_meta("rim_y", 0)
	# the palace front: its foot along row 22; the portal 10 m wide in the middle
	m.fill(FRONT_X, 0, FRONT_W, FRONT_ROWS, T.FACE)
	m.face_deco.append({"kind": "palace_front", "x": FRONT_X, "y": 0, "w": FRONT_W, "rows": FRONT_ROWS})
	var px := FRONT_X + FRONT_W / 2 - 5                         # the portal: x 54 … 63
	m.decals.append({"kind": "cov_steps", "x": px - 16, "y": FRONT_ROWS, "w": 42, "h": 3})
	_go(m, Rect2(px + 1, FRONT_ROWS, 8, 1.4), "pnarthex", "from_forecourt", "Into the palace", WARM)
	m.set_meta("from_narthex", Vector2(px + 5, FRONT_ROWS + 3.2) * TILE)
	m.lights.append({"pos": Vector2(px + 5, FRONT_ROWS - 2) * TILE, "r": 200.0, "col": Color(1.0, 0.8, 0.5), "a": 0.45})
	# the forecourt: the runner to the bridge, the sun mosaic, braziers, two pools, the chaplain-admiral
	var cx := px + 5
	m.decals.append({"kind": "sun_mosaic", "x": cx - 16, "y": 32, "w": 32, "h": 20})
	m.decals.append({"kind": "rug", "x": cx - 2, "y": FRONT_ROWS + 3, "w": 4, "h": PH - FRONT_ROWS - 3, "col": CRED.lightened(0.15)})
	for by in [30, 40, 50, 60, 68]:
		for bx in [cx - 6, cx + 5]:
			m.add_object({"kind": "brazier", "x": bx, "y": by, "w": 1, "h": 1})
			m.lights.append({"pos": Vector2(bx + 0.5, by - 0.8) * TILE, "r": 60.0, "col": Color(1.0, 0.7, 0.4), "a": 0.45, "flicker": true})
	for pl in [cx - 34, cx + 22]:
		m.decals.append({"kind": "pool_red", "x": pl, "y": 36, "w": 12, "h": 8})
		m.fill(pl + 1, 37, 10, 6, T.BLOCK, 47)
	m.add_object({"kind": "statue", "x": cx + 26, "y": 52, "w": 2, "h": 1, "seed": 777, "species": "suit_civil", "rise": 60})
	m.add_object({"kind": "plaque_stone", "x": cx + 26, "y": 54, "w": 2, "h": 1})
	for lt in [Vector2i(cx - 22, 28), Vector2i(cx + 21, 28), Vector2i(cx - 30, 50), Vector2i(cx + 29, 50), Vector2i(cx - 14, 62), Vector2i(cx + 13, 62)]:
		m.add_object({"kind": "lantern", "x": lt.x, "y": lt.y, "w": 1, "h": 1, "rise": 60, "col": Color(1.0, 0.75, 0.35)})
		m.lights.append({"pos": Vector2(lt.x + 0.5, lt.y - 0.5) * TILE, "r": 64.0, "col": Color(1.0, 0.75, 0.35), "a": 0.32})
	# benches by the balustrade, looking out over the clouds
	for bx2 in [18, 30, 42, 74, 86, 98]:
		var ry2 := mini(mini(rim_at(bx2), rim_at(bx2 + 1)), rim_at(bx2 + 2)) - 2
		if ry2 > FRONT_ROWS + 4:
			DeckGen._seat(m, "bench", bx2, ry2, 0, Color(0.55, 0.38, 0.22), rng, 0.4, 3)
	# the bridge to the city: 6 m wide, from the rim down to the map's foot
	var b0 := cx - 3
	var by0 := rim_at(cx) - 1
	for yb in range(by0, PH):
		for xb in range(b0, b0 + 6):
			m.set_t(xb, yb, T.FLOOR, 47)
		m.set_t(b0 - 1, yb, T.BLOCK, 47)
		m.set_t(b0 + 6, yb, T.BLOCK, 47)
		m.decals.append({"kind": "cov_rail", "x": b0 - 1, "y": yb, "w": 1, "h": 1, "side": true})
		m.decals.append({"kind": "cov_rail", "x": b0 + 6, "y": yb, "w": 1, "h": 1, "side": true})
	m.decals = m.decals.filter(func(d): return not (String(d["kind"]) == "cov_rail" and not d.has("side") and int(d["x"]) >= b0 and int(d["x"]) < b0 + 6))
	m.zones.append({"rect": Rect2(Vector2(b0, PH - 2) * TILE, Vector2(6, 1.6) * TILE), "kind": "museum_go", "id": "capital_go", "to": "cstation",
		"at": "from_palace", "stop": 3, "title": "Over the bridge: the palace's skyrail station", "col": Color(1.0, 0.8, 0.45), "sign": Vector2(-100, -100)})
	m.set_meta("from_station", Vector2(cx, PH - 3.5) * TILE)
	m.spawn = Vector2(cx, PH - 3.5) * TILE
	# the guard at the portal; pilgrims
	m.set_meta("guard_suit", "suit_mil_hierarch")
	m.set_meta("guard_posts", [Vector2(px - 1.5, FRONT_ROWS + 3.4) * TILE, Vector2(px + 11.5, FRONT_ROWS + 3.4) * TILE,
		Vector2(px - 8.5, FRONT_ROWS + 3.4) * TILE, Vector2(px + 18.5, FRONT_ROWS + 3.4) * TILE])
	m.set_meta("tourists", 10)
	m.set_meta("open_sky", true)
	# 54c (Luz): the forecourt is a sight – the viewpoint before the stair, a plaque with the palace's story, a stall
	m.zones.append({"rect": Rect2(Vector2(cx - 12, FRONT_ROWS + 5) * TILE, Vector2(24, 1.4) * TILE), "kind": "viewpoint", "id": "viewpoint",
		"title": "The palace: take a photo", "col": Color(1.0, 0.9, 0.5), "sign": Vector2(-100, -100)})
	m.add_object({"kind": "plaque_stone", "x": cx - 20, "y": 30, "w": 2, "h": 1})
	_zone(m, Rect2(cx - 21, 31, 4, 1.4), "sight_info", "Information: the Palace of the Hierarch", Color(1.0, 0.9, 0.5))
	m.add_object({"kind": "stall", "x": cx + 18, "y": 30, "w": 2, "h": 1, "col": Color(0.85, 0.2, 0.15)})
	m.zones.append({"rect": Rect2(Vector2(cx + 17, 30.6) * TILE, Vector2(4, 1.6) * TILE), "kind": "souvenir", "id": "souvenir",
		"title": "Souvenir stall", "col": Color(1.0, 0.7, 0.35), "sign": Vector2(cx + 19, 29.2) * TILE})
	m.set_meta("sight", {"theme": "palace", "event": "", "name": "The Palace of the Hierarch", "id": String(station.get("id", "")) + "_palace",
		"focus": Vector2(cx, 40) * TILE})
	DeckGen._seats(m)
	for wp in [Vector2(cx - 12, 30), Vector2(cx + 12, 30), Vector2(cx - 20, 46), Vector2(cx + 18, 46), Vector2(cx - 8, 58), Vector2(cx + 8, 58),
			Vector2(cx - 30, 32), Vector2(cx + 32, 32), Vector2(cx, 70), Vector2(cx - 40, 40), Vector2(cx + 40, 40)]:
		if m.free_at(wp * TILE, 6.0):
			m.wander.append(wp * TILE)
	return m


# ---------------------------------------------------------------- the lobby

static func build_lobby(station: Dictionary, body: Dictionary) -> GroundMap:
	# (Luz: much, much more in it – as in the Senate) the gate and its guard, the runner over the sun mosaic, the
	# chancery with its queue, the relic office with its shrine and candles, a lectern with the Book of Return, Earth
	# on a globe, cases of relics, saints, fonts at the doors, censers, coloured light from the windows, pilgrims
	var W := 40
	var H := 28
	var m := GroundMap.new()
	_warm_pal(m, body)
	m.style = "museum"
	m.title = "The Palace: the lobby"
	m.hull_top = -9999
	m.set_meta("no_guards", true)
	m.setup(W, H)
	m.fill(0, 0, W, H, T.CAP)
	m.fill(1, 1, W - 2, 6, T.FACE)
	m.fill(1, 7, W - 2, H - 9, T.FLOOR, 47)
	# the north wall: pilasters, lancets, banners, the inner doors to the throne room (8 m) open on its glow
	var gx := W / 2 - 4
	for pl in [8, 12, W - 13, W - 9]:
		m.face_deco.append({"kind": "cov_pilaster", "x": pl, "y": 1, "w": 1, "rows": 6})
	for lx in [10, W - 11]:
		m.face_deco.append({"kind": "cov_lancet", "x": lx, "y": 1, "w": 2, "rows": 6})
	m.face_deco.append({"kind": "palace_gate", "x": gx, "y": 1, "w": 8, "rows": 6})
	for bn in [gx - 2, gx + 9]:
		m.face_deco.append({"kind": "cov_banner", "x": bn, "y": 1, "w": 1, "rows": 5})
	_go(m, Rect2(gx + 1, 7, 6, 1.2), "throne", "from_narthex", "Into the throne room", WARM)
	m.set_meta("from_throne", Vector2(W * 0.5, 9.6) * TILE)
	m.lights.append({"pos": Vector2(W * 0.5, 6) * TILE, "r": 160.0, "col": Color(1.0, 0.75, 0.45), "a": 0.5})
	for cd in [gx - 1, gx + 8]:
		m.add_object({"kind": "candelabrum", "x": cd, "y": 7, "w": 1, "h": 1})
		m.lights.append({"pos": Vector2(cd + 0.5, 6) * TILE, "r": 50.0, "col": Color(1.0, 0.75, 0.4), "a": 0.4, "flicker": true})
	# the floor: the sun of the Return under the runner
	m.decals.append({"kind": "sun_mosaic", "x": W / 2 - 7, "y": 13, "w": 14, "h": 8})
	m.decals.append({"kind": "rug", "x": W / 2 - 2, "y": 7, "w": 4, "h": H - 9, "col": CRED.lightened(0.15)})
	# the Curia's chancery in the west: the edict on a lit scroll, the counter with three clerks, the tithe chest, the
	# queue before it behind a rope, a clerk's desk with ledgers
	m.face_deco.append({"kind": "edict_scroll", "x": 1, "y": 3, "w": 6})
	m.add_object({"kind": "counter", "x": 2, "y": 11, "w": 7, "h": 1})
	for ck in 3:
		m.people.append({"pos": Vector2(3.5 + ck * 2.0, 10.4) * TILE, "dir": 0, "role": "keeper"})
	m.add_object({"kind": "tithe_chest", "x": 10, "y": 11, "w": 1, "h": 1})
	m.add_object({"kind": "lectern", "x": 1, "y": 8, "w": 1, "h": 1})
	_zone(m, Rect2(2, 12, 9, 1.6), "curia_chancery", "The Curia's chancery: tithe, petition, indulgence", GOLD)
	m.add_object({"kind": "rope", "x": 2, "y": 15, "w": 8, "h": 1}, false)
	m.lights.append({"pos": Vector2(4.5, 5) * TILE, "r": 80.0, "col": Color(1.0, 0.9, 0.6), "a": 0.4})
	# the relic office in the east: the shrine, the priest at his counter, racks of candles, cases with relics of Earth
	m.add_object({"kind": "reliquary", "x": W - 9, "y": 8, "w": 5, "h": 1})
	m.add_object({"kind": "counter", "x": W - 10, "y": 11, "w": 7, "h": 1})
	m.people.append({"pos": Vector2(W - 6.5, 10.4) * TILE, "dir": 0, "role": "keeper"})
	m.add_object({"kind": "candle_rack", "x": W - 10, "y": 14, "w": 4, "h": 1})
	m.add_object({"kind": "candle_rack", "x": W - 5, "y": 14, "w": 4, "h": 1})
	_zone(m, Rect2(W - 10, 12, 7, 1.6), "relic_office", "The relic office: relics of Earth, a blessing", GOLD)
	for dc in [W - 10, W - 7, W - 4]:
		m.add_object({"kind": "display", "x": dc, "y": 18, "w": 2, "h": 1, "col": Color(1.0, 0.85, 0.5)})
	_stand_sign(m, "RELICS OF EARTH", Vector2(W - 6, 20.2), Color(1.0, 0.85, 0.55))
	m.lights.append({"pos": Vector2(W - 6.5, 8.5) * TILE, "r": 80.0, "col": Color(1.0, 0.85, 0.5), "a": 0.55, "flicker": true})
	m.lights.append({"pos": Vector2(W - 6.5, 14) * TILE, "r": 60.0, "col": Color(1.0, 0.8, 0.45), "a": 0.45, "flicker": true})
	m.lights.append({"pos": Vector2(W - 6, 18) * TILE, "r": 60.0, "col": Color(1.0, 0.9, 0.6), "a": 0.35})
	# the west below the chancery: Earth on a globe – the home they mean to return to – and the Book of Return
	m.add_object({"kind": "globe", "x": 3, "y": 19, "w": 2, "h": 1})
	m.add_object({"kind": "lectern", "x": 7, "y": 19, "w": 1, "h": 1})
	_stand_sign(m, "EARTH – THE HOME WE RETURN TO", Vector2(5, 21.2), Color(1.0, 0.85, 0.55))
	m.people.append({"pos": Vector2(8.2, 20.4) * TILE, "dir": 2, "role": "keeper"})        # a priest reading from the Book
	m.lights.append({"pos": Vector2(5, 19) * TILE, "r": 60.0, "col": Color(0.6, 0.85, 1.0), "a": 0.3})
	# columns, pews for the waiting, saints by the doors, fonts of blessed water, censers
	for cl in [Vector2i(12, 13), Vector2i(W - 13, 13), Vector2i(12, 21), Vector2i(W - 13, 21)]:
		m.add_object({"kind": "column", "x": cl.x, "y": cl.y, "w": 1, "h": 1})
	for pw in [Vector2i(13, 17), Vector2i(W - 17, 17), Vector2i(13, 23), Vector2i(W - 17, 23)]:
		m.add_object({"kind": "museum_bench", "x": pw.x, "y": pw.y, "w": 4, "h": 1, "face": 1}, false)
	for sx in [2, W - 4]:
		m.add_object({"kind": "statue", "x": sx, "y": H - 4, "w": 2, "h": 1, "seed": 610 + sx, "species": "suit_civil"})
	for fx in [W / 2 - 4, W / 2 + 3]:
		m.add_object({"kind": "font", "x": fx, "y": H - 4, "w": 1, "h": 1})
	for cz in [Vector2i(9, 24), Vector2i(W - 10, 24)]:
		m.add_object({"kind": "brazier", "x": cz.x, "y": cz.y, "w": 1, "h": 1})
		m.lights.append({"pos": Vector2(cz.x + 0.5, cz.y - 0.8) * TILE, "r": 50.0, "col": Color(1.0, 0.7, 0.4), "a": 0.4, "flicker": true})
	# the windows' colours on the floor
	for lp in [[6, 16, Color(0.95, 0.3, 0.2)], [W - 7, 23, Color(0.95, 0.7, 0.3)], [15, 25, Color(0.9, 0.5, 0.2)], [W - 15, 10, Color(0.9, 0.25, 0.25)]]:
		m.lights.append({"pos": Vector2(int(lp[0]), int(lp[1])) * TILE, "r": 44.0, "col": lp[2], "a": 0.28})
	# the guard: four at the inner doors, three either side of the runner
	var posts: Array = [Vector2(gx - 0.5, 9.0), Vector2(gx + 1.0, 8.6), Vector2(gx + 7.0, 8.6), Vector2(gx + 8.5, 9.0)]
	for gy in [12.6, 17.6, 22.6]:
		posts.append(Vector2(W * 0.5 - 3.0, gy))
		posts.append(Vector2(W * 0.5 + 3.0, gy))
	m.set_meta("guard_suit", "suit_mil_hierarch")
	m.set_meta("guard_posts", posts.map(func(p): return (p as Vector2) * TILE))
	MuseumGen._exit(m, W / 2 - 2, H - 2, 4, "pplaza", "from_narthex", "Out to the forecourt")
	m.set_meta("from_forecourt", Vector2(W * 0.5, H - 3.5) * TILE)
	m.lights.append({"pos": Vector2(W * 0.5, 16) * TILE, "r": 260.0, "col": WARM, "a": 0.22})
	m.set_meta("tourists", 8)
	DeckGen._seats(m)
	for wp in [Vector2(9, 17), Vector2(30, 16), Vector2(6, 24), Vector2(34, 24), Vector2(12, 25), Vector2(28, 25), Vector2(5, 16)]:
		if m.free_at(wp * TILE, 6.0):
			m.wander.append(wp * TILE)
	return m


## 54c (Luz): a sign on two posts standing on the floor.
static func _stand_sign(m: GroundMap, text: String, foot: Vector2, col: Color) -> void:
	m.zones.append({"rect": Rect2(), "kind": "label", "id": "m_label", "title": text, "col": col, "stand": 12, "sign": foot * TILE - Vector2(0, 16)})


# ---------------------------------------------------------------- the throne room

const DAIS_Y := 11                  # the plinth's top row (the throne on it); the steps below it down to row 15

static func build_throne(station: Dictionary, body: Dictionary, allied: bool) -> GroundMap:
	# (Luz) a throne of a man's size raised high on a plinth under a canopy, with far more about it: the sun's halo on
	# the wall under the window, tables with the regalia, a kneeler, tall candelabra, censers, statues of the Hierarchs
	# before him, pews for the court along the walls, courtiers, the sun mosaic, the windows' colours on the floor
	var W := 40
	var H := 34
	var m := GroundMap.new()
	_warm_pal(m, body)
	m.style = "museum"
	m.title = "The Palace: the throne room"
	m.hull_top = -9999
	m.set_meta("no_guards", true)
	m.setup(W, H)
	m.fill(0, 0, W, H, T.CAP)
	m.fill(1, 1, W - 2, DAIS_Y - 1, T.FACE)
	m.fill(1, DAIS_Y, W - 2, H - DAIS_Y - 2, T.FLOOR, 47)
	# the back wall: the great window – the star rising over the clouds – the sun's halo under it, pilasters, lancets
	m.face_deco.append({"kind": "throne_window", "x": W / 2 - 7, "y": 1, "w": 14, "rows": DAIS_Y - 4})
	m.face_deco.append({"kind": "sun_halo", "x": W / 2 - 4, "y": DAIS_Y - 4, "w": 8, "rows": 3})
	for pl in [5, 10, W - 11, W - 6]:
		m.face_deco.append({"kind": "cov_pilaster", "x": pl, "y": 1, "w": 1, "rows": DAIS_Y - 1})
	for bn in [7, 12, W - 13, W - 8]:
		m.face_deco.append({"kind": "cov_banner", "x": bn, "y": 1, "w": 1, "rows": 7})
	for lx in [2, W - 4]:
		m.face_deco.append({"kind": "cov_lancet", "x": lx, "y": 1, "w": 2, "rows": DAIS_Y - 2})
	m.lights.append({"pos": Vector2(W * 0.5, 5) * TILE, "r": 230.0, "col": Color(1.0, 0.72, 0.45), "a": 0.65})
	# the plinth (2 m up) with the throne under its canopy, the regalia either side; the broad steps below
	var cx := W / 2
	m.decals.append({"kind": "cov_plinth", "x": cx - 5, "y": DAIS_Y, "w": 10, "h": 2})
	m.fill(cx - 5, DAIS_Y, 10, 2, T.BLOCK, 47)
	m.decals.append({"kind": "cov_steps", "x": 9, "y": DAIS_Y + 2, "w": W - 18, "h": 3, "dark": true})
	m.fill(1, DAIS_Y, 8, 5, T.BLOCK, 47)                          # beside the dais: the room's corners behind the guard
	m.fill(W - 9, DAIS_Y, 8, 5, T.BLOCK, 47)
	m.add_object({"kind": "throne_small", "x": cx - 1, "y": DAIS_Y, "w": 2, "h": 1}, false)
	m.add_object({"kind": "baldachin", "x": cx - 3, "y": DAIS_Y, "w": 6, "h": 1}, false)
	for rt in [cx - 5, cx + 4]:
		m.add_object({"kind": "regalia_table", "x": rt, "y": DAIS_Y, "w": 1, "h": 1}, false)
	# the Hierarch: an old man in a long coat of crimson and gold, a white beard – seated on the throne
	var hl := {"body": 1, "skin": 2, "hair": 1, "hair_color": 7, "eyes": 4, "brows": 1, "beard": 3, "scar": 0, "freckles": 0,
		"outfit": 3, "color1": 8, "color2": 10, "implant": 0, "tattoo": 0, "headgear": 0}
	m.people.append({"pos": Vector2(cx, DAIS_Y + 1.03) * TILE, "dir": 0, "role": "keeper", "sit": true, "hierarch": true, "look": hl})
	for cd in [cx - 8, cx + 7]:
		m.add_object({"kind": "candelabrum", "x": cd, "y": DAIS_Y + 1, "w": 1, "h": 1})
		m.lights.append({"pos": Vector2(cd + 0.5, DAIS_Y - 0.5) * TILE, "r": 70.0, "col": Color(1.0, 0.75, 0.4), "a": 0.5, "flicker": true})
	m.decals.append({"kind": "rug", "x": cx - 2, "y": DAIS_Y + 5, "w": 4, "h": H - DAIS_Y - 7, "col": CRED.lightened(0.15)})
	m.decals.append({"kind": "sun_mosaic", "x": cx - 7, "y": 21, "w": 14, "h": 8})
	m.decals.append({"kind": "rug", "x": cx - 2, "y": 21, "w": 4, "h": 8, "col": CRED.lightened(0.15)})
	# before the plinth: the guard; the rope – unless you are of the Allied, then the guard stands aside
	var foot := DAIS_Y + 5
	m.set_meta("guard_suit", "suit_mil_hierarch")
	if allied:
		m.add_object({"kind": "kneeler", "x": cx - 1, "y": DAIS_Y + 2, "w": 2, "h": 1}, false)
		_zone(m, Rect2(cx - 3, DAIS_Y + 2, 6, 1.6), "audience", "Kneel before the Hierarch: an audience", GOLD)
		m.set_meta("guard_posts", [Vector2(9.5, foot + 0.6) * TILE, Vector2(W - 9.5, foot + 0.6) * TILE,
			Vector2(cx - 6.0, DAIS_Y + 2.6) * TILE, Vector2(cx + 6.0, DAIS_Y + 2.6) * TILE])
	else:
		m.add_object({"kind": "rope", "x": 9, "y": foot - 1, "w": W - 18, "h": 1})
		_zone(m, Rect2(10, foot, W - 20, 1.6), "audience_denied", "The guard bars the way to the throne", Color(1.0, 0.5, 0.4))
		m.set_meta("guard_posts", [Vector2(cx - 3.0, foot + 0.6) * TILE, Vector2(cx + 3.0, foot + 0.6) * TILE,
			Vector2(10.5, foot + 0.6) * TILE, Vector2(W - 10.5, foot + 0.6) * TILE, Vector2(cx - 6.0, DAIS_Y + 2.6) * TILE, Vector2(cx + 6.0, DAIS_Y + 2.6) * TILE])
	m.set_meta("audience", allied)
	# the nave: columns, the Hierarchs of old in stone, pews for the court along the walls, censers, courtiers
	for cl in [Vector2i(7, 19), Vector2i(W - 8, 19), Vector2i(7, 27), Vector2i(W - 8, 27)]:
		m.add_object({"kind": "column", "x": cl.x, "y": cl.y, "w": 1, "h": 1})
	for sx in [Vector2i(2, 17), Vector2i(W - 4, 17), Vector2i(2, 25), Vector2i(W - 4, 25)]:
		m.add_object({"kind": "statue", "x": sx.x, "y": sx.y, "w": 2, "h": 1, "seed": 620 + sx.x + sx.y, "species": "suit_civil"})
	for pw in [Vector2i(9, 21), Vector2i(W - 13, 21), Vector2i(9, 25), Vector2i(W - 13, 25), Vector2i(9, 29), Vector2i(W - 13, 29)]:
		m.add_object({"kind": "museum_bench", "x": pw.x, "y": pw.y, "w": 4, "h": 1, "face": 1}, false)
	for cz in [Vector2i(10, foot + 1), Vector2i(W - 11, foot + 1)]:
		m.add_object({"kind": "brazier", "x": cz.x, "y": cz.y + 1, "w": 1, "h": 1})
		m.lights.append({"pos": Vector2(cz.x + 0.5, cz.y + 0.2) * TILE, "r": 50.0, "col": Color(1.0, 0.7, 0.4), "a": 0.45, "flicker": true})
	for ct in [Vector2(13.5, 18.4), Vector2(26.5, 18.4), Vector2(5.5, 21.5), Vector2(34.5, 22.5)]:
		m.people.append({"pos": ct * TILE, "dir": 0 if ct.y > 20.0 else 1, "role": "keeper"})
	for lp in [[5, 22, Color(0.95, 0.3, 0.2)], [W - 6, 24, Color(0.95, 0.7, 0.3)], [10, 30, Color(0.9, 0.5, 0.2)], [W - 10, 30, Color(0.9, 0.25, 0.25)]]:
		m.lights.append({"pos": Vector2(int(lp[0]), int(lp[1])) * TILE, "r": 50.0, "col": lp[2], "a": 0.3})
	MuseumGen._exit(m, W / 2 - 2, H - 2, 4, "pnarthex", "from_throne", "Back to the lobby")
	m.set_meta("from_narthex", Vector2(W * 0.5, H - 3.5) * TILE)
	m.lights.append({"pos": Vector2(W * 0.5, 22) * TILE, "r": 260.0, "col": WARM, "a": 0.2})
	m.set_meta("tourists", 3)
	DeckGen._seats(m)
	for wp in [Vector2(14, 23), Vector2(26, 23), Vector2(15, 30), Vector2(25, 30)]:
		if m.free_at(wp * TILE, 6.0):
			m.wander.append(wp * TILE)
	return m


# ---------------------------------------------------------------- 54c (Luz): the palace's skyrail station

## The skyrail's fourth stop in Aureola – built like the line's other stations (the platform, the screen doors, the
## car under the edge), dressed like the palace: warm stone, lancets and banners on the hall's wall, braziers and
## saints, the guard in gold at the passage; through the passage in the wall the way across to the palace platform.
static func build_station(station: Dictionary) -> GroundMap:
	var C = CloudGenP
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(station.get("id", "x"))) + 593
	var m := GroundMap.new()
	C._base(m, station, "%s: The Palace" % String(station.get("name", "Aureola")))
	m.remove_meta("few_guards")
	m.style = "cloud_station"
	m.pal["floor"] = Color(0.86, 0.8, 0.7)
	m.pal["floor2"] = Color(0.78, 0.72, 0.62)
	m.pal["wall"] = Color(0.86, 0.8, 0.7)
	m.set_meta("rim_warm", true)
	var W := 48
	var H: int = C.S_RIM + 18
	m.setup(W, H)
	m.set_meta("rim_y", C.S_RIM)
	m.fill(0, 0, W, C.S_TOP, T.CAP)
	m.fill(1, C.S_TOP, W - 2, 3, T.FACE)
	m.fill(0, 0, 1, C.S_RIM, T.CAP)
	m.fill(W - 1, 0, 1, C.S_RIM, T.CAP)
	m.fill(1, C.S_FLOOR, W - 2, C.S_EDGE - C.S_FLOOR + 1, T.FLOOR, 47)
	m.fill(0, C.S_RIM, W, 1, T.FACE)
	var car_x := 8
	m.set_meta("car", {"x": car_x * TILE, "y": (C.S_RIM + 1) * TILE, "len": C.CAR_LEN * TILE, "doors": C.CAR_DOORS, "open": true})
	m.set_meta("beam_y", (C.S_RIM + 1) * TILE)
	m.decals.append({"kind": "cloud_edge", "x": 1, "y": C.S_EDGE - 1, "w": W - 2, "h": 1, "col": GOLD})
	var gaps: Array = []
	for d in C.CAR_DOORS:
		gaps.append(car_x + int(d))
	var gx0 := 1
	while gx0 < W - 1:
		if gx0 in gaps:
			gx0 += 2
			continue
		var gw := 1
		while gx0 + gw < W - 1 and not (gx0 + gw) in gaps:
			gw += 1
		m.fill(gx0, C.S_EDGE, gw, 1, T.BLOCK, 47)
		m.add_object({"kind": "glass_rail", "x": gx0, "y": C.S_EDGE, "w": gw, "h": 1}, false)
		gx0 += gw
	for g in gaps:
		m.face_deco.append({"kind": "gangway", "x": g, "y": C.S_RIM, "w": 2, "col": GOLD})
		m.zones.append({"rect": Rect2(Vector2(g - 0.2, C.S_EDGE - 0.6) * TILE, Vector2(2.4, 1.6) * TILE), "kind": "board", "id": "board",
			"title": "Board the skyrail", "col": GOLD, "sign": Vector2(-100, -100)})
	m.set_meta("rail_front", Vector2(gaps[1] + 1.0, C.S_EDGE - 1.0) * TILE)
	# the hall's wall in the palace's stone: pilasters, lancets, banners, the departures in a gilded frame, the passage
	var gx := W - 14                                             # the passage across to the palace (6 m)
	for pl in range(2, W - 1, 6):
		if pl >= gx - 1 and pl <= gx + 7:
			continue
		m.face_deco.append({"kind": "cov_pilaster", "x": pl, "y": C.S_TOP, "w": 1, "rows": 3})
	for lx in [4, 22, 28]:
		m.face_deco.append({"kind": "cov_lancet", "x": lx, "y": C.S_TOP, "w": 2, "rows": 3})
	m.face_deco.append({"kind": "departures", "x": 10, "y": C.S_TOP, "w": 8, "col": Color(1.0, 0.78, 0.3)})
	m.zones.append({"rect": Rect2(), "kind": "label", "id": "dep", "title": "Departures: %s every 6 min" % C._dest_names(3, true),
		"col": Color(1.0, 0.8, 0.4), "sign": Vector2(14, C.S_TOP - 0.5) * TILE})
	m.face_deco.append({"kind": "palace_gate", "x": gx, "y": C.S_TOP, "w": 6, "rows": 3})
	for bn in [gx - 2, gx + 7]:
		m.face_deco.append({"kind": "cov_banner", "x": bn, "y": C.S_TOP, "w": 1, "rows": 3})
	m.zones.append({"rect": Rect2(), "kind": "label", "id": "stop", "title": "Skyrail · The Palace of the Hierarch", "col": GOLD,
		"sign": Vector2(gx + 3, C.S_TOP - 0.5) * TILE})
	_go(m, Rect2(gx + 1, C.S_FLOOR, 4, 1.2), "pplaza", "from_station", "Through the passage: across to the palace", WARM)
	m.set_meta("from_palace", Vector2(gx + 3, C.S_FLOOR + 1.8) * TILE)
	m.lights.append({"pos": Vector2(gx + 3, C.S_TOP + 1) * TILE, "r": 110.0, "col": Color(1.0, 0.8, 0.5), "a": 0.5})
	m.decals.append({"kind": "rug", "x": gx + 1, "y": C.S_FLOOR, "w": 4, "h": C.S_EDGE - C.S_FLOOR - 1, "col": CRED.lightened(0.15)})
	# on the platform: benches, braziers, saints on their plinths by the passage, pilgrims waiting
	for bx in [3, 13, 19]:
		DeckGen._seat(m, "bench", bx, C.S_FLOOR + 2, 0, Color(0.55, 0.38, 0.22), rng, 0.45, 3)
	for br in [Vector2i(9, C.S_FLOOR + 1), Vector2i(25, C.S_FLOOR + 1), Vector2i(W - 4, C.S_FLOOR + 3)]:
		m.add_object({"kind": "brazier", "x": br.x, "y": br.y, "w": 1, "h": 1})
		m.lights.append({"pos": Vector2(br.x + 0.5, br.y - 0.8) * TILE, "r": 60.0, "col": Color(1.0, 0.7, 0.4), "a": 0.45, "flicker": true})
	for sx in [gx - 4, gx + 9]:
		m.add_object({"kind": "statue", "x": sx, "y": C.S_FLOOR, "w": 2, "h": 1, "seed": 600 + sx, "species": "suit_civil"})
	for lx2 in range(4, W - 2, 6):
		m.lights.append({"pos": Vector2(lx2, C.S_FLOOR + 1.0) * TILE, "r": 56.0, "col": Color(1.0, 0.88, 0.7), "a": 0.24})
	m.set_meta("guard_suit", "suit_mil_hierarch")
	m.set_meta("guard_posts", [Vector2(gx - 0.6, C.S_FLOOR + 1.4) * TILE, Vector2(gx + 6.6, C.S_FLOOR + 1.4) * TILE])
	m.set_meta("tourists", 5)
	m.spawn = m.get_meta("rail_front")
	DeckGen._seats(m)
	for k3 in 10:
		var wp := Vector2(rng.randf_range(2.5, W - 3.5), rng.randf_range(C.S_FLOOR + 1.2, C.S_EDGE - 1.2)) * TILE
		if m.free_at(wp, 6.0):
			m.wander.append(wp)
	m.set_meta("spindles", C._spindles(W, C.S_RIM + 1, rng))
	return m


const CloudGenP = preload("res://scripts/ground/cloud_gen.gd")
