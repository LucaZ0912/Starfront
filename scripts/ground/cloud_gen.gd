extends RefCounted
## Package 54 (Luz): the cloud cities over the gas giants – walked like the cities on the ground, in their own design.
## The hangar is the cities' hangar (DeckGen.build_hangar – its far wall a gate open to the sky); this script builds
## the rest at real scale (a tile ~1 m): the plaza with its balcony over the sea of clouds (shops, the lifts, a café,
## benches looking out), the skyrail station (the suspended car waiting at the platform) and the car itself, riding
## between the platforms. Everything under the deck's edge is left void: the view lays the sea of clouds there
## (scripts/ground/cloud_sea.gd). Deterministic from the city's id.

const T := GroundMap.T
const TILE := GroundMap.TILE

## The look of each power at the height of the clouds (Leitlinien 3.3): floor, floor2, wall, accent, trim, seat.
const STYLE := {
	"assembly": {"floor": Color(0.86, 0.82, 0.74), "floor2": Color(0.81, 0.77, 0.69), "wall": Color(0.91, 0.89, 0.83), "accent": Color(0.4, 0.75, 1.0),
		"trim": Color(0.66, 0.63, 0.57), "seat": Color(0.55, 0.4, 0.26), "parasol": [Color(0.98, 0.55, 0.3), Color(0.98, 0.85, 0.6), Color(0.45, 0.75, 0.95)]},
	"covenant": {"floor": Color(0.5, 0.38, 0.32), "floor2": Color(0.45, 0.34, 0.29), "wall": Color(0.56, 0.38, 0.31), "accent": Color(1.0, 0.78, 0.3),
		"trim": Color(0.36, 0.22, 0.17), "seat": Color(0.45, 0.12, 0.14), "parasol": [Color(0.7, 0.12, 0.14), Color(0.95, 0.75, 0.3), Color(0.55, 0.15, 0.2)]},
	"directorate": {"floor": Color(0.86, 0.89, 0.89), "floor2": Color(0.8, 0.84, 0.84), "wall": Color(0.95, 0.96, 0.96), "accent": Color(0.3, 0.9, 0.55),
		"trim": Color(0.62, 0.66, 0.66), "seat": Color(0.3, 0.55, 0.45), "parasol": [Color(0.9, 0.95, 0.95), Color(0.35, 0.85, 0.6), Color(0.75, 0.85, 0.85)]},
	"independent": {"floor": Color(0.33, 0.34, 0.38), "floor2": Color(0.29, 0.3, 0.34), "wall": Color(0.42, 0.44, 0.5), "accent": Color(0.3, 0.95, 1.0),
		"trim": Color(0.22, 0.23, 0.27), "seat": Color(0.75, 0.2, 0.55), "parasol": [Color(1.0, 0.3, 0.7), Color(0.3, 0.9, 1.0), Color(0.75, 0.45, 1.0)]},
}
const FRONT_NAMES := ["SKY CAFÉ", "UPDRAFT", "CIRRUS", "THE GONDOLA", "HIGH TEA", "ZEPHYR BAR"]
const STOPS := ["Central", "Skyring"]          # the skyrail's two stops: the main platform and the outer ring

## Rows of the plaza
const P_FRONT := 7                  # the shop fronts' cap (the shops lie north of it)
const P_FLOOR := 11                 # the plaza's first floor row
const P_RAIL := 25                  # the glass railing along the balcony's edge
const P_RIM := 26                   # the deck's rim (2 rows) – below it the void, the clouds
const SHOP_W := 7
const PLAZA_MORE := 14             # tiles of deck beyond each end of the plaza (seen, not walked)


static func key_for(station: Dictionary) -> String:
	return CityStyle.key_for(station)


static func palette(station: Dictionary) -> Dictionary:
	var s: Dictionary = STYLE.get(key_for(station), STYLE["assembly"])
	var wl: Color = s["wall"]
	return {"floor": s["floor"], "floor2": s["floor2"], "shop_floor": Color(s["floor"]).darkened(0.08), "wood": Color(0.55, 0.4, 0.25),
		"carpet": Color(0.3, 0.42, 0.5), "wall": wl, "wall_top": wl.darkened(0.42), "trim": s["trim"], "frame": Color(0.78, 0.8, 0.84),
		"accent": s["accent"], "type": "cloud_" + key_for(station)}


## The giant's colours (from its planet type): bands from high to deep, the deep, the haze, the sky, the lightning.
static func giant_look(gtype: String) -> Dictionary:
	var pt: Dictionary = Universe.PLANET_TYPES.get(gtype, Universe.PLANET_TYPES["gas"])
	var a: Color = pt["a"]
	var b: Color = pt["b"]
	var c: Color = pt["c"]
	var look := {"bands": [c.lerp(b, 0.25), b, c.lightened(0.04), a.lerp(b, 0.35), b.lerp(c, 0.55)],
		"deep": a.darkened(0.55), "haze": c.lerp(b, 0.3).lightened(0.06), "sky_top": c.lerp(Color(0.62, 0.7, 0.88), 0.25),
		"sky_low": b.lerp(c, 0.4), "flash": Color(0.85, 0.9, 1.0)}
	match gtype:
		"red_gas":
			look["flash"] = Color(1.0, 0.85, 0.7)
			var soft: Array = []
			for bc in look["bands"]:
				soft.append((bc as Color).lerp(Color(0.86, 0.62, 0.5), 0.35))       # a smoggy rust, not pure red
			look["bands"] = soft
			look["haze"] = Color(0.9, 0.66, 0.55)
			look["sky_top"] = Color(0.95, 0.75, 0.62)
			look["sky_low"] = Color(0.85, 0.5, 0.4)
		"toxic":
			look["flash"] = Color(0.85, 1.0, 0.6)
		"ice_giant":
			look["flash"] = Color(0.8, 0.95, 1.0)
	return look


## The city's air: most giants' air is thin or poisonous at the city's height (the suit), some breathe like a home
## world (Luz). Deterministic per body.
static func breathable(body: Dictionary) -> bool:
	var t := String(body.get("type", "gas"))
	var h := absi(hash(String(body.get("id", "")).split("~")[0] + "_air")) % 100
	return (t == "gas" and h < 40) or (t == "red_gas" and h < 20)


## The cities' services on the plaza: the station's shops (not the hangar's, not the clinic's image studio).
static func _plaza_shops(available: Dictionary) -> Array:
	var shops: Array = []
	for sid in DeckGen.SHOPS:
		if available.has(sid) and not sid in DeckGen.HANGAR_SERVICES:
			if sid == "look" and available.has("clinic"):
				continue
			shops.append(sid)
	var dock: Array = []
	for d in DeckGen.DOCK_TERMINALS:
		if available.has(d) and not d in DeckGen.HANGAR_SERVICES:
			dock.append(d)
	if not dock.is_empty():
		shops.insert(0, "dock")
	return shops


static func _base(m: GroundMap, station: Dictionary, title: String) -> void:
	m.pal = palette(station)
	m.style = "cloud"
	m.hull_top = -9999
	m.title = title
	m.set_meta("clouds", true)
	m.set_meta("few_guards", true)                 # Luz: few guards on the plaza


# ---------------------------------------------------------------- the plaza

## The plaza (mockup_54v2_plaza): the shops' fronts along the north side – glass fronts between pillars, the storeys
## above them, the lifts in the middle; the plaza 14 m deep with trees in planters, lamps, a café with parasols at the
## east end; along the south edge the glass railing (1.1 m) and benches facing out over the clouds; the deck's rim
## below it and the void – the sea of clouds 2 km down. Shops are walked into like everywhere else.
static func build_plaza(station: Dictionary, available: Dictionary) -> GroundMap:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(station.get("id", "x"))) + 540
	var m := GroundMap.new()
	_base(m, station, String(station.get("name", "Cloud city")))
	var shops := _plaza_shops(available)
	var half := (shops.size() + 1) / 2
	var CAFE_W := 12
	var Wi := 2 + shops.size() * (SHOP_W - 1) + 1 + 8 + CAFE_W + 4
	Wi = maxi(Wi, 48)
	var o := PLAZA_MORE                                # 0.7.54 (Luz): the platform goes on beyond the plaza's ends
	var W := Wi + o * 2
	var H := P_RIM + 16
	m.setup(W, H)
	m.set_meta("rim_y", P_RIM)
	var acc: Color = m.pal["accent"]
	# the deck all along (beyond the plaza's ends you only look at it), the railing, the rim
	m.fill(0, P_FLOOR, W, P_RAIL - P_FLOOR, T.BLOCK, 47)
	m.fill(o + 1, P_FLOOR, Wi - 2, P_RAIL - P_FLOOR, T.FLOOR, 47)
	m.fill(0, P_RAIL, W, 1, T.BLOCK, 47)
	m.add_object({"kind": "glass_rail", "x": 0, "y": P_RAIL, "w": W, "h": 1}, false)
	m.fill(0, P_RIM, W, 2, T.FACE)
	# the fronts: north of the plaza everything is building – the shops, the lift hall, the café; on beyond the ends
	m.fill(0, 0, W, P_FLOOR, T.CAP)
	m.fill(0, P_FRONT + 1, W, 3, T.FACE)
	for ex in [[0, o], [o + Wi, W - o - Wi]]:
		var fx0: int = ex[0]
		var fw0: int = ex[1]
		var fxx := fx0 + 1
		var fi := 0
		while fxx + 6 <= fx0 + fw0:
			m.face_deco.append({"kind": "cloud_front", "x": fxx, "y": P_FRONT + 1, "w": 6, "col": [Color(1.0, 0.6, 0.3), Color(0.4, 0.85, 1.0), Color(0.6, 1.0, 0.5)][(fxx + fi) % 3], "door": -1})
			fxx += 7
			fi += 1
	# the plaza's ends: a hedge of planters across – the deck goes on behind them
	for ex2 in [o, o + Wi - 1]:
		for yy0 in range(P_FLOOR, P_RAIL):
			m.add_object({"kind": "planter", "x": ex2, "y": yy0, "w": 1, "h": 1, "col": Color(m.pal["wall"]).darkened(0.12)})
	var x := o + 2
	var n := 0
	var lift_x := -1
	for i in shops.size() + 1:
		if i == half:
			lift_x = x                                    # the lifts in the middle of the row
			x += 8
			continue
		var sid: String = shops[i if i < half else i - 1]
		_shop_n(m, sid, x, available, rng, station)
		x += SHOP_W - 1
		n += 1
	if lift_x < 0:
		lift_x = x
		x += 8
	# the lift hall: two lifts in a recess of the front, lit
	for k in 2:
		m.face_deco.append({"kind": "lift", "x": lift_x + 1 + k * 3, "y": P_FRONT + 3, "w": 2, "col": Color(0.4, 1.0, 0.6)})
		m.lifts.append({"x": lift_x + 1 + k * 3, "y": P_FRONT + 3, "w": 2})
	m.face_deco.append({"kind": "cloud_lifts", "x": lift_x, "y": P_FRONT + 1, "w": 7, "col": acc})
	m.zones.append({"rect": Rect2(Vector2(lift_x + 1, P_FLOOR) * TILE, Vector2(5, 1.4) * TILE), "kind": "lift", "id": "lift",
		"title": "Lifts", "col": Color(0.4, 1.0, 0.6), "sign": Vector2(lift_x + 3.5, P_FRONT + 0.7) * TILE})
	m.spawn = Vector2(lift_x + 3.5, P_FLOOR + 1.6) * TILE
	m.decals.append({"kind": "mat", "x": lift_x + 1, "y": P_FLOOR, "w": 5, "h": 1, "col": acc})
	# the café at the east end: its front, the terrace with tables under parasols
	var cx := x + 1
	var cname: String = FRONT_NAMES[rng.randi() % FRONT_NAMES.size()]
	m.face_deco.append({"kind": "cloud_front", "x": cx, "y": P_FRONT + 1, "w": CAFE_W - 2, "col": Color(1.0, 0.72, 0.35), "door": -1, "cafe": true})
	m.zones.append({"rect": Rect2(), "kind": "label", "id": "cafe", "title": cname, "col": Color(1.0, 0.75, 0.4),
		"sign": Vector2(cx + (CAFE_W - 2) * 0.5, P_FRONT + 0.85) * TILE})
	m.add_object({"kind": "counter", "x": cx + 1, "y": P_FLOOR + 1, "w": CAFE_W - 4, "h": 1})
	m.fill(cx, P_FLOOR, 1, 2, T.BLOCK, 47)
	m.fill(cx + CAFE_W - 3, P_FLOOR, 1, 2, T.BLOCK, 47)
	m.people.append({"pos": Vector2(cx + CAFE_W * 0.5 - 1, P_FLOOR + 0.7) * TILE, "dir": 0, "role": "keeper"})
	var pcols: Array = (STYLE.get(key_for(station), STYLE["assembly"]) as Dictionary)["parasol"]
	var seat_c: Color = (STYLE.get(key_for(station), STYLE["assembly"]) as Dictionary)["seat"]
	var tx := cx
	var ty := P_FLOOR + 3
	var ti := 0
	while tx + 3 < o + Wi - 2:
		for row in 2:
			var yy := ty + row * 4
			m.add_object({"kind": "round_table", "x": tx + 1, "y": yy, "w": 1, "h": 1})
			DeckGen._seat(m, "chair", tx, yy, 3, seat_c, rng, 0.35)
			DeckGen._seat(m, "chair", tx + 2, yy, 2, seat_c, rng, 0.35)
			m.add_object({"kind": "parasol", "x": tx, "y": yy, "w": 3, "h": 1, "col": pcols[ti % pcols.size()]}, false)
			ti += 1
		tx += 5
	# the plaza: trees in planters, lamps, an information pillar; benches along the railing looking out
	var px0 := o + 3
	var k2 := 0
	var trees: Array = range(px0 + 3, cx - 2, 9)
	for tb in range(o - 6, 0, -9):
		trees.append(tb)                              # beyond the ends too
	for tb2 in range(o + Wi + 3, W - 3, 9):
		trees.append(tb2)
	for tx2 in trees:
		if absi(tx2 - (lift_x + 3)) < 4:
			continue
		m.add_object({"kind": "planter", "x": tx2, "y": P_FLOOR + 4, "w": 3, "h": 1, "col": Color(m.pal["wall"]).darkened(0.12)})
		m.add_object({"kind": "tree", "x": tx2, "y": P_FLOOR + 3, "w": 3, "h": 1, "rise": 84, "seed": k2 * 7 + 3}, false)
		k2 += 1
	for lx in range(px0 + 1 - o, W - 3, 8):
		if lx < 1 or absi(lx - o) < 2 or absi(lx - (o + Wi - 1)) < 2:
			continue
		m.add_object({"kind": "lamp_post", "x": lx, "y": P_RAIL - 3, "w": 1, "h": 1, "rise": 60})
		m.lights.append({"pos": Vector2(lx + 0.5, P_RAIL - 3.3) * TILE, "r": 64.0, "col": Color(1.0, 0.9, 0.7), "a": 0.32})
		var bx := lx + 2
		if bx + 3 < W - 1 and not (bx <= o and bx + 3 > o) and not (bx <= o + Wi - 1 and bx + 3 > o + Wi - 1):
			DeckGen._seat(m, "bench", bx, P_RAIL - 1, 0, Color(0.55, 0.4, 0.26), rng, 0.4, 3)
	m.add_object({"kind": "holo_pillar", "x": lift_x + 9, "y": P_FLOOR + 3, "w": 1, "h": 1, "col": acc})
	m.lights.append({"pos": Vector2(lift_x + 9.5, P_FLOOR + 3.3) * TILE, "r": 40.0, "col": acc, "a": 0.35})
	m.zones.append({"rect": Rect2(Vector2(lift_x + 8.5, P_FLOOR + 3.5) * TILE, Vector2(2, 1.2) * TILE), "kind": "soon", "id": "info",
		"title": "Information – %s, %s" % [String(station.get("name", "")), _what(station)], "col": acc, "sign": Vector2(-100, -100)})
	# the power's flags on the pillars between the shops
	var dk: Dictionary = CityStyle.deck(station)
	var fl: Array = dk["flag"]
	m.face_deco.append({"kind": String(dk["flag_kind"]), "x": lift_x - 1, "y": P_FRONT + 3, "w": 1, "col": fl[0], "col2": fl[1], "sign": dk.get("sign", "cross")})
	m.face_deco.append({"kind": String(dk["flag_kind"]), "x": lift_x + 7, "y": P_FRONT + 3, "w": 1, "col": fl[0], "col2": fl[1], "sign": dk.get("sign", "cross")})
	DeckGen._seats(m)
	for k3 in 16:
		var wp := Vector2(rng.randf_range(o + 2.5, o + Wi - 3.5), rng.randf_range(P_FLOOR + 1.2, P_RAIL - 1.4)) * TILE
		if m.free_at(wp, 6.0):
			m.wander.append(wp)
	m.set_meta("spindles", _spindles(W, P_RIM + 2, rng))
	return m


## What the city lives on (for the information pillar).
static func _what(station: Dictionary) -> String:
	return String(Universe.CLOUD_KINDS.get(String(station.get("giant", "gas")), Universe.CLOUD_KINDS["gas"])["what"])


## Under the deck's rim: struts, lift tanks and antigrav rotors going down into the haze – [x art px, length, width].
static func _spindles(W: int, rim_bottom: int, rng: RandomNumberGenerator) -> Dictionary:
	var out: Array = []
	var x := rng.randf_range(4.0, 9.0)
	while x < W - 2:
		out.append([x * TILE, rng.randf_range(40.0, 120.0), rng.randf_range(8.0, 20.0), rng.randf() < 0.35])
		x += rng.randf_range(7.0, 13.0)
	return {"y": rim_bottom * TILE, "list": out}


## A shop north of the plaza: the room behind the front (its back wall seen from inside, shelves on it, the counter
## on the right with the keeper behind it); the door through the front – glass to either side, the sign over it.
static func _shop_n(m: GroundMap, id: String, sx: int, available: Dictionary, rng: RandomNumberGenerator, station: Dictionary) -> void:
	var rw := SHOP_W
	m.fill(sx + 1, 1, rw - 2, 2, T.FACE)
	m.fill(sx + 1, 3, rw - 2, P_FRONT - 3, T.FLOOR, 1)
	var dx := sx + rw / 2 - 1
	m.fill(dx, P_FRONT, 2, 4, T.DOOR, 47)
	var col: Color = DeckGen._svc_col(id) if id != "dock" else m.pal["accent"]
	m.face_deco.append({"kind": "cloud_front", "x": sx + 1, "y": P_FRONT + 1, "w": rw - 1, "col": col, "door": dx})
	var sign := Vector2(dx + 1, P_FRONT + 0.85) * TILE
	var inside := Rect2(Vector2(sx + 1, 3) * TILE, Vector2(rw - 2, P_FRONT - 3) * TILE)
	if id == "dock":
		var tx := sx + 1
		for d in DeckGen.DOCK_TERMINALS:
			if not available.has(d) or d in DeckGen.HANGAR_SERVICES:
				continue
			if tx >= sx + rw - 1:
				break
			m.add_object({"kind": "terminal", "x": tx, "y": 3, "w": 1, "h": 1, "col": DeckGen._svc_col(d), "icon": DeckGen._svc_icon(d)})
			DeckGen._zone(m, d, available, Rect2(Vector2(tx - 0.1, 3.6) * TILE, Vector2(1.2, 1.5) * TILE), Vector2(-100, -100))
			m.lights.append({"pos": Vector2(tx + 0.5, 4.2) * TILE, "r": 18.0, "col": DeckGen._svc_col(d), "a": 0.3})
			tx += 1
		m.zones.append({"rect": Rect2(), "kind": "label", "title": "Dock Office", "col": col, "sign": sign, "id": "dock"})
		return
	DeckGen._zone(m, id, available, inside, sign)
	var deco := "shelf"
	match id:
		"outfitter", "gear":
			deco = "rack"
		"shipyard", "exchange", "senate", "curia", "bonds":
			deco = "screen"
		"look":
			deco = "poster"
	for fx in range(sx + 1, sx + rw - 2, 2):
		m.face_deco.append({"kind": deco, "x": fx, "y": 1, "w": 2, "col": col})
	m.add_object({"kind": "counter_v", "x": sx + rw - 3, "y": 3, "w": 1, "h": 3})
	m.people.append({"pos": Vector2(sx + rw - 1.5, 4.8) * TILE, "dir": 2, "role": "keeper"})
	m.wander.append(Vector2(sx + rw - 3.6, 5.2) * TILE)
	m.lights.append({"pos": Vector2(sx + rw * 0.5, 5.0) * TILE, "r": 40.0, "col": col.lerp(Color.WHITE, 0.5), "a": 0.22})
	if id == "market":
		m.add_object({"kind": "crates", "x": sx + 1, "y": P_FRONT - 1, "w": 2, "h": 1})
	else:
		m.add_object({"kind": "plant", "x": sx + 1, "y": P_FRONT - 1, "w": 1, "h": 1})


# ---------------------------------------------------------------- the skyrail station

## Where the car's doors are (tiles from its west end) – the platform's screen doors open there.
const CAR_LEN := 20
const CAR_DOORS := [4, 9, 15]
## Rows of the station
const S_TOP := 3                   # the hall's wall: its face 3 rows from here (the hall's roof above)
const S_FLOOR := S_TOP + 3         # the platform's first row
const S_EDGE := S_FLOOR + 7        # the screen doors along the edge
const S_RIM := S_EDGE + 1          # the platform's rim (a row) – the beam and the car below it


## The skyrail station (mockup_54v2_bahnhof): the hall's back wall with the departures board, ticket machines and (on
## the main platform) the lift; the platform 7 m deep with benches; the yellow line, glass screens with doors where
## the car's doors are; under the edge the beam and the car hanging from it, 20 m long, its doors open. stop 0 is the
## main platform (Central), 1 the outer ring (Skyring – its observation deck beside the platform).
static func build_station(station: Dictionary, stop: int) -> GroundMap:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(station.get("id", "x"))) + 560 + stop
	var m := GroundMap.new()
	_base(m, station, "%s – %s" % [String(station.get("name", "")), STOPS[stop]])
	m.style = "cloud_station"
	var W := 44 if stop == 0 else 58
	var H := S_RIM + 18
	m.setup(W, H)
	m.set_meta("rim_y", S_RIM)
	var acc: Color = m.pal["accent"]
	m.fill(0, 0, W, S_TOP, T.CAP)
	m.fill(1, S_TOP, W - 2, 3, T.FACE)
	m.fill(0, 0, 1, S_RIM, T.CAP)
	m.fill(W - 1, 0, 1, S_RIM, T.CAP)
	m.fill(1, S_FLOOR, W - 2, S_EDGE - S_FLOOR + 1, T.FLOOR, 48)
	m.fill(0, S_RIM, W, 1, T.FACE)
	var car_x := 8
	m.set_meta("car", {"x": car_x * TILE, "y": (S_RIM + 1) * TILE, "len": CAR_LEN * TILE, "doors": CAR_DOORS, "open": true})
	m.set_meta("beam_y", (S_RIM + 1) * TILE)
	m.decals.append({"kind": "cloud_edge", "x": 1, "y": S_EDGE - 1, "w": W - 2, "h": 1, "col": Color(0.95, 0.8, 0.2)})
	# the screen doors: glass panes along the edge, open where the car's doors stand
	var gaps: Array = []
	for d in CAR_DOORS:
		gaps.append(car_x + int(d))
	var gx := 1
	while gx < W - 1:
		if gx in gaps:
			gx += 2
			continue
		var gw := 1
		while gx + gw < W - 1 and not (gx + gw) in gaps:
			gw += 1
		m.fill(gx, S_EDGE, gw, 1, T.BLOCK, 48)
		m.add_object({"kind": "glass_rail", "x": gx, "y": S_EDGE, "w": gw, "h": 1}, false)
		gx += gw
	for g in gaps:
		m.face_deco.append({"kind": "gangway", "x": g, "y": S_RIM, "w": 2, "col": Color(0.95, 0.8, 0.2)})
		m.zones.append({"rect": Rect2(Vector2(g - 0.2, S_EDGE - 0.6) * TILE, Vector2(2.4, 1.6) * TILE), "kind": "board", "id": "board",
			"title": "Board the skyrail – to %s" % STOPS[1 - stop], "col": acc, "sign": Vector2(-100, -100)})
	m.set_meta("rail_front", Vector2(gaps[1] + 1.0, S_EDGE - 1.0) * TILE)
	# the hall's wall: the departures board, ticket machines, the doors to the staff rooms
	m.face_deco.append({"kind": "departures", "x": 12, "y": S_TOP, "w": 8, "col": Color(1.0, 0.78, 0.3), "to": STOPS[1 - stop]})
	m.zones.append({"rect": Rect2(), "kind": "label", "id": "dep", "title": "Departures – %s every 6 min" % STOPS[1 - stop],
		"col": Color(1.0, 0.8, 0.4), "sign": Vector2(16, S_TOP - 0.5) * TILE})
	m.lights.append({"pos": Vector2(16, S_FLOOR + 0.5) * TILE, "r": 70.0, "col": Color(1.0, 0.8, 0.4), "a": 0.28})
	for tm in 2:
		m.face_deco.append({"kind": "ticket", "x": 3 + tm * 2, "y": S_TOP + 2, "w": 1, "col": Color(0.4, 1.0, 0.7)})
	m.zones.append({"rect": Rect2(), "kind": "label", "id": "stop", "title": "Skyrail · %s" % STOPS[stop], "col": acc,
		"sign": Vector2(27, S_TOP + 1.2) * TILE})
	# benches on the platform, facing the track; lights along the hall
	for bx in [6, 10, 26, 30]:
		if bx + 3 < W - 1:
			DeckGen._seat(m, "bench", bx, S_FLOOR + 2, 0, Color(0.55, 0.4, 0.26), rng, 0.45, 3)
	for lx in range(4, W - 2, 6):
		m.lights.append({"pos": Vector2(lx, S_FLOOR + 1.0) * TILE, "r": 56.0, "col": Color(1.0, 0.95, 0.85), "a": 0.22})
	if stop == 0:
		var lx0 := W - 8
		for k in 2:
			m.face_deco.append({"kind": "lift", "x": lx0 + k * 3, "y": S_TOP + 2, "w": 2, "col": Color(0.4, 1.0, 0.6)})
			m.lifts.append({"x": lx0 + k * 3, "y": S_TOP + 2, "w": 2})
		m.zones.append({"rect": Rect2(Vector2(lx0, S_FLOOR) * TILE, Vector2(5, 1.4) * TILE), "kind": "lift", "id": "lift",
			"title": "Lifts", "col": Color(0.4, 1.0, 0.6), "sign": Vector2(lx0 + 2.5, S_TOP - 0.5) * TILE})
		m.spawn = Vector2(lx0 + 2.5, S_FLOOR + 1.6) * TILE
	else:
		# the observation deck beside the platform: the railing along its edge, benches, viewing scopes
		var ox := 36
		m.fill(ox, S_EDGE, W - ox - 1, 1, T.BLOCK, 48)
		for o0 in m.objects.duplicate():
			if String(o0["kind"]) == "glass_rail" and int(o0["x"]) + int(o0["w"]) > ox:
				o0["w"] = maxi(1, ox - int(o0["x"]))
		m.add_object({"kind": "glass_rail", "x": ox, "y": S_EDGE, "w": W - ox - 1, "h": 1}, false)
		var lk := giant_look(String(station.get("giant", "gas")))
		m.face_deco.append({"kind": "cloud_window", "x": ox, "y": S_TOP, "w": W - ox - 1, "col": acc, "sky0": lk["sky_top"], "sky1": lk["sky_low"]})
		m.zones.append({"rect": Rect2(), "kind": "label", "id": "obs", "title": "Observation deck", "col": acc, "sign": Vector2(ox + (W - ox) * 0.5, S_TOP - 0.5) * TILE})
		for sx in [ox + 2, ox + 9, ox + 16]:
			if sx + 1 < W - 1:
				m.add_object({"kind": "scope", "x": sx, "y": S_EDGE - 1, "w": 1, "h": 1, "col": acc})
				m.zones.append({"rect": Rect2(Vector2(sx - 0.4, S_EDGE - 2.0) * TILE, Vector2(1.8, 1.4) * TILE), "kind": "scope", "id": "scope",
					"title": "Look through the scope", "col": acc, "sign": Vector2(-100, -100)})
		for bx2 in [ox + 4, ox + 11]:
			DeckGen._seat(m, "bench", bx2, S_FLOOR + 3, 0, Color(0.55, 0.4, 0.26), rng, 0.4, 3)
		m.spawn = m.get_meta("rail_front")
	DeckGen._seats(m)
	for k3 in 10:
		var wp := Vector2(rng.randf_range(2.5, W - 3.5), rng.randf_range(S_FLOOR + 1.2, S_EDGE - 1.2)) * TILE
		if m.free_at(wp, 6.0):
			m.wander.append(wp)
	m.set_meta("spindles", _spindles(W, S_RIM + 1, rng))
	return m


# ---------------------------------------------------------------- the car

## Rows of the car
const C_X := 7                     # the car's first column inside
const C_TOP := 5                   # its roof's edge (the north wall's top)
const C_FLOOR := 8                 # the first floor row (the window wall 2 rows above it)
const C_SOUTH := 11                # the glass down to the floor on the south side


## The skyrail's car from inside (mockup_54v2_fahrt): 20 × 3 m; the north wall big windows (the giant's sky through
## them) with the doors in the middle; seats along it facing the aisle and the glass on the south side, which goes
## down to the floor – under it the sea of clouds passing by. The view runs the ride (GroundView._rail_step).
static func build_car(station: Dictionary, to_stop: int) -> GroundMap:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(station.get("id", "x"))) + 580
	var m := GroundMap.new()
	_base(m, station, "Skyrail – to %s" % STOPS[to_stop])
	m.style = "cloud_car"
	m.pal["floor"] = Color(0.42, 0.44, 0.48)
	m.pal["floor2"] = Color(0.39, 0.41, 0.45)
	m.pal["wall"] = Color(0.86, 0.88, 0.9)
	m.pal["wall_top"] = Color(0.66, 0.68, 0.72)
	m.pal["frame"] = Color(0.86, 0.88, 0.9)
	m.remove_meta("few_guards")
	m.set_meta("no_guards", true)
	var W := C_X * 2 + CAR_LEN
	var H := 24
	m.setup(W, H)
	m.fill(C_X - 1, C_TOP, CAR_LEN + 2, 1, T.CAP)
	m.fill(C_X, C_TOP + 1, CAR_LEN, 2, T.GLASS)
	m.window_rect = Rect2(C_X, C_TOP + 1, CAR_LEN, 2)
	m.fill(C_X - 1, C_TOP + 1, 1, C_SOUTH - C_TOP, T.CAP)
	m.fill(C_X + CAR_LEN, C_TOP + 1, 1, C_SOUTH - C_TOP, T.CAP)
	m.fill(C_X, C_FLOOR, CAR_LEN, C_SOUTH - C_FLOOR, T.FLOOR, 49)
	m.fill(C_X, C_SOUTH, CAR_LEN, 1, T.BLOCK, 49)
	# 0.7.54 (Luz): the car closed – its roof and its side towards you drawn in front, the inside seen through the windows
	m.set_meta("car_shell", {"x0": (C_X - 1) * TILE, "x1": (C_X + CAR_LEN + 1) * TILE, "top": C_TOP * TILE - 2,
		"side": C_TOP * TILE + 12, "bottom": (C_SOUTH + 1) * TILE,
		"door": Rect2((C_X + 9) * TILE, (C_TOP + 1) * TILE, 2 * TILE, 2 * TILE)})
	m.set_meta("beam_y", (C_TOP - 1) * TILE)
	m.set_meta("riding", true)
	var dmid := C_X + 9                              # the doors in the middle of the north wall (the platform's side)
	m.decals.append({"kind": "car_door", "x": dmid, "y": C_FLOOR, "w": 2, "h": 1, "col": Color(0.95, 0.6, 0.2)})
	m.face_deco.append({"kind": "car_doors", "x": dmid, "y": C_TOP + 1, "w": 2, "col": Color(0.95, 0.6, 0.2)})
	m.face_deco.append({"kind": "car_board", "x": dmid, "y": C_TOP + 1, "w": 2, "col": Color(1.0, 0.78, 0.3)})
	m.zones.append({"rect": Rect2(Vector2(dmid - 0.3, C_FLOOR - 0.1) * TILE, Vector2(2.6, 1.4) * TILE), "kind": "alight", "id": "alight",
		"title": "Get off – %s" % STOPS[to_stop], "col": Color(0.95, 0.65, 0.25), "sign": Vector2(-100, -100),
		"closed": "The doors are shut – the car is running."})
	m.set_meta("rail_front", Vector2(dmid + 1.0, C_FLOOR + 1.2) * TILE)
	m.spawn = m.get_meta("rail_front")
	var seat_c := Color(0.25, 0.42, 0.62)
	for sx in range(C_X, C_X + CAR_LEN):
		if sx >= dmid - 1 and sx <= dmid + 2:
			continue
		DeckGen._seat(m, "chair", sx, C_FLOOR, 0, seat_c, rng, 0.3)
	for pole in [C_X + 4, C_X + 15]:
		m.add_object({"kind": "car_pole", "x": pole, "y": C_FLOOR + 2, "w": 1, "h": 1})
	m.lights.append({"pos": Vector2(C_X + CAR_LEN * 0.5, C_FLOOR + 1.0) * TILE, "r": 200.0, "col": Color(1.0, 0.93, 0.8), "a": 0.14})
	DeckGen._seats(m)
	for k in 6:
		m.wander.append(Vector2(rng.randf_range(C_X + 1.0, C_X + CAR_LEN - 1.0), C_FLOOR + 1.6 + rng.randf() * 0.6) * TILE)
	return m
