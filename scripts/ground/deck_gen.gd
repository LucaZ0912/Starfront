class_name DeckGen
extends RefCounted
## Package 49 (0.7.49.2, after Luz's sketch): the walkable deck of a station. On the left the lift lobby where you
## come up from the dock; from it a corridor runs to the right with most of the shops below it; above the corridor
## the big bar behind a railing – its far side a window front with space beyond. The bar counter stands at the right,
## round tables in the room, the crew looking for work stand about and can be spoken to. The look follows the
## station type. Deterministic from the station's id.

const CrewData = preload("res://data/crew.gd")
## floor, floor2 (corridor), shop_floor, wood (bar), carpet, wall (faces), accent
const PALETTES := {
	"trade": [Color(0.27, 0.3, 0.38), Color(0.31, 0.34, 0.43), Color(0.42, 0.38, 0.34), Color(0.46, 0.29, 0.17), Color(0.32, 0.2, 0.3), Color(0.62, 0.66, 0.76), Color(0.3, 0.85, 1.0)],
	"military": [Color(0.27, 0.29, 0.27), Color(0.31, 0.33, 0.3), Color(0.36, 0.37, 0.34), Color(0.4, 0.3, 0.2), Color(0.25, 0.28, 0.22), Color(0.52, 0.55, 0.5), Color(1.0, 0.35, 0.28)],
	"research": [Color(0.7, 0.74, 0.78), Color(0.76, 0.8, 0.83), Color(0.78, 0.8, 0.8), Color(0.62, 0.5, 0.38), Color(0.3, 0.45, 0.42), Color(0.9, 0.93, 0.95), Color(0.25, 0.85, 0.55)],
	"industry": [Color(0.3, 0.27, 0.24), Color(0.34, 0.3, 0.27), Color(0.4, 0.34, 0.28), Color(0.45, 0.3, 0.18), Color(0.35, 0.22, 0.16), Color(0.56, 0.48, 0.41), Color(1.0, 0.6, 0.15)],
	"mining_colony": [Color(0.32, 0.28, 0.23), Color(0.36, 0.31, 0.26), Color(0.42, 0.35, 0.28), Color(0.48, 0.32, 0.18), Color(0.38, 0.26, 0.16), Color(0.52, 0.43, 0.34), Color(1.0, 0.8, 0.2)],
	"agri": [Color(0.4, 0.34, 0.25), Color(0.44, 0.37, 0.28), Color(0.5, 0.43, 0.3), Color(0.52, 0.36, 0.2), Color(0.3, 0.4, 0.22), Color(0.68, 0.62, 0.5), Color(0.45, 0.9, 0.35)],
	"ice_refinery": [Color(0.58, 0.66, 0.74), Color(0.64, 0.72, 0.8), Color(0.66, 0.72, 0.78), Color(0.5, 0.4, 0.32), Color(0.3, 0.42, 0.55), Color(0.84, 0.91, 0.97), Color(0.45, 0.85, 1.0)],
	"shipyard": [Color(0.29, 0.3, 0.33), Color(0.33, 0.34, 0.37), Color(0.38, 0.38, 0.4), Color(0.44, 0.3, 0.18), Color(0.3, 0.28, 0.2), Color(0.56, 0.58, 0.62), Color(1.0, 0.85, 0.2)],
	"pirate_haven": [Color(0.17, 0.15, 0.16), Color(0.2, 0.18, 0.19), Color(0.24, 0.2, 0.2), Color(0.32, 0.2, 0.14), Color(0.3, 0.1, 0.16), Color(0.36, 0.3, 0.29), Color(1.0, 0.2, 0.35)],
	"waystation": [Color(0.3, 0.32, 0.36), Color(0.34, 0.36, 0.4), Color(0.44, 0.42, 0.4), Color(0.5, 0.3, 0.2), Color(0.6, 0.15, 0.2), Color(0.86, 0.84, 0.78), Color(0.3, 0.95, 1.0)],
	"resort": [Color(0.7, 0.65, 0.56), Color(0.75, 0.7, 0.6), Color(0.78, 0.72, 0.62), Color(0.55, 0.38, 0.22), Color(0.55, 0.3, 0.32), Color(0.93, 0.89, 0.81), Color(1.0, 0.82, 0.4)],
}
## 0.7.49.7: each station type its own deck – how its bar is furnished (style), its floors, how round the window
## front's corners are, what stands along the window and in the corridor, the colour of its seats.
const THEMES := {
	"trade": {"bar": "lounge", "floor": 3, "corner": 8, "cor_floor": 0, "deco": ["plant"],
		"props": ["lamp_post", "holo", "lamp_post", "holo", "plant", "holo"], "seat": Color(0.55, 0.22, 0.2)},
	"military": {"bar": "mess", "floor": 5, "corner": 2, "cor_floor": 5, "deco": ["banner", "locker"],
		"props": ["lamp_post", "crates", "banner", "holo", "locker", "lamp_post"], "seat": Color(0.36, 0.4, 0.33)},
	"research": {"bar": "cafe", "floor": 6, "corner": 8, "cor_floor": 6, "deco": ["holo_pillar", "plant"],
		"props": ["holo_pillar", "tank", "plant", "holo", "tank"], "seat": Color(0.82, 0.86, 0.9)},
	"industry": {"bar": "canteen", "floor": 8, "corner": 3, "cor_floor": 8, "deco": ["pipes", "vending"],
		"props": ["lamp_post", "pipes", "crates", "holo", "machine"], "seat": Color(0.62, 0.36, 0.14)},
	"mining_colony": {"bar": "dive", "floor": 9, "corner": 3, "cor_floor": 0, "deco": ["barrel", "ore_cart"],
		"props": ["ore_cart", "lamp_post", "barrel", "holo"], "seat": Color(0.5, 0.36, 0.2)},
	"agri": {"bar": "garden", "floor": 3, "corner": 8, "cor_floor": 0, "deco": ["planter"],
		"props": ["planter", "lamp_post", "flower_bed", "holo"], "seat": Color(0.5, 0.34, 0.18)},
	"ice_refinery": {"bar": "lounge", "floor": 6, "corner": 6, "cor_floor": 6, "deco": ["ice_sculpture", "heater"],
		"props": ["heater", "ice_sculpture", "lamp_post", "holo"], "seat": Color(0.3, 0.42, 0.6)},
	"shipyard": {"bar": "canteen", "floor": 5, "corner": 4, "cor_floor": 5, "deco": ["engine_part", "locker"],
		"props": ["engine_part", "lamp_post", "crates", "holo"], "seat": Color(0.75, 0.6, 0.15)},
	"resort": {"bar": "beach", "floor": 7, "corner": 8, "cor_floor": 6, "deco": ["palm"],
		"props": ["palm", "fountain", "flower_bed", "lamp_post", "palm", "holo"], "seat": Color(0.95, 0.5, 0.35)},
	"waystation": {"bar": "diner", "floor": 12, "corner": 8, "cor_floor": 0, "deco": ["plant"],
		"props": ["lamp_post", "vending", "holo", "plant"], "seat": Color(0.85, 0.2, 0.25)},
	"pirate_haven": {"bar": "dive", "floor": 9, "corner": 2, "cor_floor": 9, "deco": ["barrel", "cage"],
		"props": ["barrel", "trash", "holo", "cage", "holo"], "seat": Color(0.4, 0.18, 0.2)},
}
## Shops below the corridor (the bar has its own room); the ship services are terminals in the dock office.
const SHOPS := ["market", "outfitter", "shipyard", "bonds", "look", "refinery", "manufacturing", "senate", "curia", "exchange"]
const SHOP_W := 7
const DOCK_TERMINALS := ["fuel", "repair", "drones", "munitions", "hangar"]
const KIOSKS := ["news", "bulletin"]
## Holographic adverts in the corridor – made-up brands of the cluster.
const ADS := [["NEURO+", "think faster"], ["ORBITAL COLA", "taste the void"], ["SYNTH NOODLES", "hot · 24/7"],
	["DREAMWARE", "sleep implants"], ["CHROME & SOUL", "body mods"], ["VOIDBANK", "your credits, safe"],
	["STARLIGHT HOTEL", "rooms by the hour"], ["ZERO-G GYM", "lift nothing"], ["KAIJU TV", "live from the rim"]]
## rows
const BAR_Y0 := 8                 # first floor row of the bar (rows 0 cap, 1–7 the window front)
const COR_Y0 := 17                # the railing row – the corridor below it to row 20
const COR_Y1 := 20
const SHOP_CAP := 21              # the corridor's south wall …
const SHOP_FACE := 22             # … the shop's back wall face, seen from inside
const SHOP_Y1 := 27               # last floor row of the shops
const LOBBY_X1 := 6               # the lift lobby: x 1 … 6, deep inside the station
const LOBBY_Y0 := COR_Y0 - 5      # its north wall (the lifts) – station all round it, not space
const CORNER_R := BAR_Y0          # the window front's rounded corners (tiles)


static func palette_for(station: Dictionary) -> Dictionary:
	var t := String(station.get("type", "trade"))
	if t.begins_with("resort") or String(station.get("art", "")).begins_with("resort"):
		t = "resort"
	var p: Array = PALETTES.get(t, PALETTES["trade"])
	var wall: Color = p[5]
	return {"floor": p[0], "floor2": p[1], "shop_floor": p[2], "wood": p[3], "carpet": p[4], "wall": wall,
		"wall_top": wall.darkened(0.55), "trim": wall.darkened(0.35), "frame": wall.darkened(0.25), "accent": p[6], "type": t}


## available: service id -> "" (open) or the reason it is closed. crew: the bar's offers (GameState.bar_offers).
static func build(station: Dictionary, available: Dictionary, crew: Array = []) -> GroundMap:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(station.get("id", "x")))
	var m := GroundMap.new()
	m.pal = palette_for(station)
	m.hull_top = BAR_Y0
	m.title = String(station.get("name", "Station"))
	var shops: Array = []
	for sid in SHOPS:
		if available.has(sid) and not sid in HANGAR_SERVICES:
			shops.append(sid)
	var dock: Array = []
	for d in DOCK_TERMINALS:
		if available.has(d) and not d in HANGAR_SERVICES:
			dock.append(d)
	if not dock.is_empty():
		shops.insert(0, "dock")
	var x_shops := LOBBY_X1 + 2                         # the first shop starts right of the lobby
	var W := maxi(x_shops + shops.size() * (SHOP_W - 1) + 3, 44 if String(station.get("type", "")) != "waystation" else 36)
	var H := SHOP_Y1 + 2
	m.setup(W, H)
	var bx0 := LOBBY_X1 + 1                             # the bar's west wall
	var th: Dictionary = THEMES.get(String(m.pal["type"]), THEMES["trade"])
	if String(station.get("type", "")) == "waystation":
		_dome_room(m, th, bx0, W, available, crew, rng)
	else:
		_bar_room(m, th, bx0, W, available, crew, rng)
	# ---- the corridor
	m.fill(bx0, COR_Y0 + 1, W - bx0 - 1, COR_Y1 - COR_Y0, GroundMap.T.FLOOR, int(th["cor_floor"]))
	m.decals.append({"kind": "guide", "x": bx0, "y": COR_Y0 + 2, "w": W - bx0 - 1, "h": 1, "col": m.pal["accent"]})
	# ---- the lift lobby
	var ly := LOBBY_Y0
	m.fill(0, ly, LOBBY_X1 + 2, 1, GroundMap.T.CAP)
	m.fill(1, ly + 1, LOBBY_X1, 2, GroundMap.T.FACE)
	m.fill(0, ly + 1, 1, SHOP_Y1 - ly + 1, GroundMap.T.CAP)
	m.fill(1, ly + 3, LOBBY_X1, 8, GroundMap.T.FLOOR, 2)
	m.fill(0, ly + 11, LOBBY_X1 + 2, SHOP_Y1 - ly - 9, GroundMap.T.CAP)
	m.fill(LOBBY_X1 + 1, ly + 1, 1, COR_Y0 - ly - 1, GroundMap.T.CAP)
	m.fill(LOBBY_X1 + 1, COR_Y1 + 1, 1, ly + 11 - COR_Y1 - 1, GroundMap.T.CAP)
	m.fill(LOBBY_X1 + 1, COR_Y0, 1, COR_Y1 - COR_Y0 + 1, GroundMap.T.FLOOR, 0)
	for lx0 in [1, 4]:
		m.face_deco.append({"kind": "lift", "x": lx0, "y": ly + 2, "w": 2, "col": Color(0.4, 1.0, 0.6)})
		m.lifts.append({"x": lx0, "y": ly + 2, "w": 2})
	m.decals.append({"kind": "mat", "x": 1, "y": ly + 3, "w": 5, "h": 1, "col": m.pal["accent"]})
	m.spawn = Vector2(3.5, ly + 4.6) * GroundMap.TILE
	m.zones.append({"rect": Rect2(Vector2(1, ly + 3) * GroundMap.TILE, Vector2(5, 1.4) * GroundMap.TILE), "kind": "lift", "id": "lift",
		"title": "Lifts – Hangar · Commercial level", "col": Color(0.4, 1.0, 0.6), "sign": Vector2(3.5, ly + 0.7) * GroundMap.TILE})
	var kx := 2
	for k in KIOSKS:
		if available.has(k):
			m.add_object({"kind": "terminal", "x": kx, "y": ly + 9, "w": 1, "h": 1, "col": _svc_col(k), "icon": _svc_icon(k)})
			_zone(m, k, available, Rect2(Vector2(kx - 0.5, ly + 7.6) * GroundMap.TILE, Vector2(2, 1.6) * GroundMap.TILE), Vector2(kx + 0.5, ly + 8.4) * GroundMap.TILE)
			kx += 3
	m.add_object({"kind": "plant", "x": 1, "y": ly + 7, "w": 1, "h": 1})
	m.add_object({"kind": "bench", "x": 3, "y": ly + 6, "w": 2, "h": 1, "col": m.pal["accent"], "face": 0}, false)
	# ---- the shops below the corridor
	m.fill(bx0, SHOP_CAP, W - bx0, 1, GroundMap.T.CAP)
	var sx := x_shops - 1
	for s2 in shops:
		_shop(m, s2, sx, available, dock, rng, station)
		sx += SHOP_W - 1
	m.fill(sx, SHOP_CAP, W - sx, SHOP_Y1 - SHOP_CAP + 2, GroundMap.T.CAP)
	# corridor dressing: lamp posts and plants on the south side, between the doors
	var lx := bx0 + 2
	var slot := 0
	var ads := ADS.duplicate()
	ads.shuffle()
	var ad_cols := [Color(0.3, 0.95, 1.0), Color(1.0, 0.3, 0.75), Color(0.75, 0.45, 1.0), Color(0.45, 1.0, 0.55)]
	# one thing per stretch of wall between two doors
	var wall_spots: Array = []
	var n_ads := 0
	var run0 := -1
	for xx in range(bx0 + 1, W - 1):
		var wall := m.t_at(xx, SHOP_CAP) == GroundMap.T.CAP and m.t_at(xx, COR_Y1) == GroundMap.T.FLOOR
		if wall and run0 < 0:
			run0 = xx
		if (not wall or xx == W - 2) and run0 >= 0:
			var run1 := xx - 1 if not wall else xx
			if run1 - run0 >= 2:
				wall_spots.append((run0 + run1) / 2)
			run0 = -1
	for lx2 in wall_spots:
		lx = lx2
		if true:
			var pk: String = (th["props"] as Array)[slot % (th["props"] as Array).size()]
			match pk:
				"holo":
					var ad: Array = ads[n_ads % ads.size()]
					n_ads += 1
					var ac: Color = ad_cols[rng.randi() % ad_cols.size()]
					m.holos.append({"pos": Vector2(lx + 0.5, SHOP_CAP + 0.35) * GroundMap.TILE, "text": ad[0], "sub": ad[1], "col": ac})
					m.lights.append({"pos": Vector2(lx + 0.5, COR_Y1 + 0.2) * GroundMap.TILE, "r": 36.0, "col": ac, "a": 0.3, "flicker": true})
				_:
					m.add_object({"kind": pk, "x": lx, "y": COR_Y1, "w": 1, "h": 1, "col": m.pal["accent"]})
					_prop_light(m, pk, Vector2(lx + 0.5, COR_Y1 + 0.3))
			slot += 1
	_seats(m)
	for k2 in 14:
		m.wander.append(Vector2(rng.randf_range(bx0 + 1, W - 3), rng.randf_range(COR_Y0 + 1.3, COR_Y1 - 0.1)) * GroundMap.TILE)
	return m


## The bar with its window front (every station but the waystations).
static func _bar_room(m: GroundMap, th: Dictionary, bx0: int, W: int, available: Dictionary, crew: Array, rng: RandomNumberGenerator) -> void:
	var cr := int(th["corner"])
	# ---- the bar: a big window front to the north (its corners as round as the station likes), the counter east
	m.fill(bx0, 0, W - bx0, 1, GroundMap.T.CAP)
	m.fill(bx0, 1, W - bx0, BAR_Y0 - 1, GroundMap.T.GLASS)
	m.fill(bx0, 0, cr, cr, GroundMap.T.GLASS)
	m.fill(W - cr, 0, cr, cr, GroundMap.T.GLASS)
	if cr < BAR_Y0:
		m.fill(bx0, cr, 1, BAR_Y0 - cr, GroundMap.T.CAP)
		m.fill(W - 1, cr, 1, BAR_Y0 - cr, GroundMap.T.CAP)
	m.window_rect = Rect2(bx0, 0, W - bx0, BAR_Y0)
	m.round_corners.append({"x": bx0, "r": cr, "side": -1})
	m.round_corners.append({"x": W - 1, "r": cr, "side": 1})
	m.fill(W - 1, BAR_Y0, 1, COR_Y1 - BAR_Y0 + 2, GroundMap.T.CAP)
	m.fill(bx0, BAR_Y0, 1, COR_Y0 - BAR_Y0, GroundMap.T.CAP)
	m.fill(bx0 + 1, BAR_Y0, W - bx0 - 2, COR_Y0 - BAR_Y0, GroundMap.T.FLOOR, int(th["floor"]))
	# the counter, the bartender behind it, the stools
	var cx := W - 5
	m.add_object({"kind": "counter_v", "x": cx, "y": BAR_Y0 + 1, "w": 2, "h": 6})
	m.add_object({"kind": "fridge", "x": W - 2, "y": BAR_Y0, "w": 1, "h": 1, "col": m.pal["accent"]})
	m.add_object({"kind": "fridge", "x": W - 2, "y": BAR_Y0 + 6, "w": 1, "h": 1, "col": m.pal["accent"]})
	m.people.append({"pos": Vector2(W - 2.5, BAR_Y0 + 3.6) * GroundMap.TILE, "dir": 2, "role": "bartender"})
	for sy in range(BAR_Y0 + 1, BAR_Y0 + 7, 2):
		_seat(m, "stool", cx - 1, sy, 3, Color(0.75, 0.25, 0.22), rng, 0.45)
	m.lights.append({"pos": Vector2(cx + 1, BAR_Y0 + 2.5) * GroundMap.TILE, "r": 60.0, "col": Color(1.0, 0.3, 0.7), "a": 0.55, "flicker": true})
	m.lights.append({"pos": Vector2(cx - 0.5, BAR_Y0 + 3.5) * GroundMap.TILE, "r": 46.0, "col": Color(1.0, 0.75, 0.4), "a": 0.3})
	m.zones.append({"rect": Rect2(), "kind": "label", "id": "bar_sign", "title": "BAR", "col": Color(1.0, 0.3, 0.72),
		"sign": Vector2(cx + 1, BAR_Y0 + 0.2) * GroundMap.TILE, "vertical": true})
	_zone(m, "bar", available, Rect2(Vector2(cx - 2, BAR_Y0) * GroundMap.TILE, Vector2(2, 7) * GroundMap.TILE), Vector2(-100, -100))
	# along the window: what this station puts there
	var dk: Array = th["deco"]
	var dxp := bx0 + 4
	var di := 0
	while dxp < cx - 3:
		var dkind: String = dk[di % dk.size()]
		m.add_object({"kind": dkind, "x": dxp, "y": BAR_Y0, "w": 1, "h": 1, "col": m.pal["accent"]})
		_prop_light(m, dkind, Vector2(dxp + 0.5, BAR_Y0 + 0.8))
		dxp += 7
		di += 1
	# the room itself, after the station's taste
	var x0 := bx0 + 2
	var x1 := cx - 3
	var sc: Color = th["seat"]
	match String(th["bar"]):
		"mess", "canteen", "garden":
			_bar_long(m, x0, x1, sc, rng, String(th["bar"]))
		"cafe":
			_bar_cafe(m, x0, x1, sc, rng)
		"dive":
			_bar_dive(m, x0, x1, sc, rng)
		"beach":
			_bar_beach(m, x0, x1, sc, rng)
		_:
			_bar_lounge(m, x0, x1, sc, rng)
	m.add_object({"kind": "jukebox", "x": bx0 + 1, "y": BAR_Y0 + 1, "w": 1, "h": 1, "col": Color(1.0, 0.45, 0.7)})
	m.lights.append({"pos": Vector2(bx0 + 1.5, BAR_Y0 + 2.2) * GroundMap.TILE, "r": 40.0, "col": Color(1.0, 0.45, 0.7), "a": 0.4})
	m.zones.append({"rect": Rect2(Vector2(bx0 + 0.9, BAR_Y0 + 1.6) * GroundMap.TILE, Vector2(1.8, 1.4) * GroundMap.TILE), "kind": "jukebox",
		"id": "jukebox", "title": "Jukebox", "sign": Vector2(-100, -100)})
	# the planet's and the stars' cold light falling in through the window front
	var wx := bx0 + 4
	while wx < W - 4:
		m.lights.append({"pos": Vector2(wx, BAR_Y0 + 0.6) * GroundMap.TILE, "r": 56.0, "col": Color(0.45, 0.6, 1.0), "a": 0.14})
		wx += 6
	m.add_object({"kind": "plant", "x": cx - 3, "y": BAR_Y0, "w": 1, "h": 1})
	_place_crew(m, crew, rng, bx0 + 2, cx - 2, BAR_Y0 + 1.5, COR_Y0 - 1.0)
	# ---- the railing between the bar and the corridor, two ways in
	var gap1 := bx0 + (cx - bx0) / 3
	var gap2 := bx0 + (cx - bx0) * 2 / 3
	var rx := bx0 + 1
	while rx < W - 1:
		if absi(rx - gap1) <= 1 or absi(rx - gap2) <= 1:
			m.set_t(rx, COR_Y0, GroundMap.T.FLOOR, 0)
			rx += 1
			continue
		var run := 1
		while rx + run < W - 1 and absi(rx + run - gap1) > 1 and absi(rx + run - gap2) > 1 and run < 4:
			run += 1
		m.add_object({"kind": "railing", "x": rx, "y": COR_Y0, "w": run, "h": 1})
		rx += run
	for k3 in 4:
		m.wander.append(Vector2(rng.randf_range(bx0 + 2, cx - 3), rng.randf_range(BAR_Y0 + 1.5, COR_Y0 - 1.2)) * GroundMap.TILE)


## The people looking for a post stand about in the room (x0…x1, y0…y1 in tiles) and can be spoken to.
static func _place_crew(m: GroundMap, crew: Array, rng: RandomNumberGenerator, x0: float, x1: float, y0: float, y1: float) -> void:
	var spots: Array = []
	for k in 10:
		spots.append(Vector2(rng.randf_range(x0, x1), rng.randf_range(y0, y1)))
	var placed := 0
	for i in crew.size():
		if placed >= 6:
			break
		for sp in spots:
			var p: Vector2 = sp * GroundMap.TILE
			if m.free_at(p, 6.0):
				spots.erase(sp)
				var o: Dictionary = crew[i]
				m.people.append({"pos": p, "dir": 0, "role": "crew", "crew": i, "look": o["m"].get("look", {})})
				m.zones.append({"rect": Rect2(p - Vector2(14, 18), Vector2(28, 30)), "kind": "crew", "id": "bar", "crew": i,
					"title": "%s – %s (%s)" % [String(o["m"].get("name", "?")), CrewData.role_name(String(o["m"]["role"])), String(o["m"].get("quality", "?"))],
					"col": Color(1.0, 0.85, 0.4), "sign": Vector2(-100, -100)})
				placed += 1
				break


## 0.7.49.8: a waystation – no wide bar but a round glass dome out front, a diner under it: a counter with stools,
## booths, a checkered floor, the jukebox under the glass.
static func _dome_room(m: GroundMap, th: Dictionary, bx0: int, W: int, available: Dictionary, crew: Array, rng: RandomNumberGenerator) -> void:
	var R := BAR_Y0
	var dx := clampi((bx0 + W) / 2 - R, bx0 + 1, W - 2 * R - 1)
	m.fill(dx, 0, 2 * R, R, GroundMap.T.GLASS)
	m.window_rect = Rect2(dx, 0, 2 * R, R)
	m.round_corners.append({"x": dx, "r": R, "side": -1})
	m.round_corners.append({"x": dx + 2 * R - 1, "r": R, "side": 1})
	m.fill(dx, R, 1, COR_Y0 - R, GroundMap.T.CAP)
	m.fill(dx + 2 * R - 1, R, 1, COR_Y0 - R, GroundMap.T.CAP)
	m.fill(dx + 1, R, 2 * R - 2, COR_Y0 - R, GroundMap.T.FLOOR, 12)
	# the corridor's north wall, a door into the diner
	m.fill(bx0, COR_Y0, W - bx0, 1, GroundMap.T.CAP)
	m.fill(dx + R - 1, COR_Y0, 2, 1, GroundMap.T.DOOR, 12)
	m.fill(W - 1, COR_Y0, 1, COR_Y1 - COR_Y0 + 2, GroundMap.T.CAP)
	m.zones.append({"rect": Rect2(), "kind": "label", "id": "diner_sign", "title": "Diner · open 24/7", "col": Color(0.3, 0.95, 1.0),
		"sign": Vector2(dx + R, COR_Y0 + 0.55) * GroundMap.TILE})
	# the counter across the room, the cook behind it, stools in front
	m.add_object({"kind": "bar_counter", "x": dx + 4, "y": R + 4, "w": 8, "h": 1})
	m.people.append({"pos": Vector2(dx + R, R + 3.7) * GroundMap.TILE, "dir": 0, "role": "bartender"})
	m.add_object({"kind": "fridge", "x": dx + 4, "y": R + 2, "w": 1, "h": 1, "col": m.pal["accent"]})
	m.add_object({"kind": "vending", "x": dx + 11, "y": R + 2, "w": 1, "h": 1, "col": Color(1.0, 0.4, 0.4)})
	for i in 4:
		_seat(m, "stool", dx + 4 + i * 2, R + 5, 1, Color(0.85, 0.2, 0.25), rng, 0.5)
	m.lights.append({"pos": Vector2(dx + R, R + 4.6) * GroundMap.TILE, "r": 64.0, "col": Color(1.0, 0.8, 0.5), "a": 0.3})
	if available.has("bar"):
		_zone(m, "bar", available, Rect2(Vector2(dx + 4, R + 5) * GroundMap.TILE, Vector2(8, 2) * GroundMap.TILE), Vector2(-100, -100))
	# booths in the four corners
	for b in [Vector2i(dx + 2, R + 1), Vector2i(dx + 2 * R - 4, R + 1), Vector2i(dx + 2, R + 6), Vector2i(dx + 2 * R - 4, R + 6)]:
		m.add_object({"kind": "table_small", "x": b.x, "y": b.y, "w": 1, "h": 1})
		_seat(m, "chair", b.x - 1, b.y, 3, Color(0.85, 0.2, 0.25), rng, 0.5)
		_seat(m, "chair", b.x + 1, b.y, 2, Color(0.85, 0.2, 0.25), rng, 0.45)
		m.lights.append({"pos": Vector2(b.x + 0.5, b.y + 0.6) * GroundMap.TILE, "r": 28.0, "col": Color(1.0, 0.6, 0.6), "a": 0.22})
	m.add_object({"kind": "jukebox", "x": dx + R - 1, "y": R, "w": 1, "h": 1, "col": Color(0.3, 0.95, 1.0)})
	m.lights.append({"pos": Vector2(dx + R - 0.5, R + 1.2) * GroundMap.TILE, "r": 40.0, "col": Color(0.3, 0.95, 1.0), "a": 0.4})
	m.zones.append({"rect": Rect2(Vector2(dx + R - 1.6, R + 0.6) * GroundMap.TILE, Vector2(2.2, 1.4) * GroundMap.TILE), "kind": "jukebox",
		"id": "jukebox", "title": "Jukebox", "sign": Vector2(-100, -100)})
	m.add_object({"kind": "plant", "x": dx + 1, "y": COR_Y0 - 1, "w": 1, "h": 1})
	m.add_object({"kind": "plant", "x": dx + 2 * R - 2, "y": COR_Y0 - 1, "w": 1, "h": 1})
	for k in 3:
		m.lights.append({"pos": Vector2(dx + 3 + k * 5, R + 0.4) * GroundMap.TILE, "r": 48.0, "col": Color(0.45, 0.6, 1.0), "a": 0.14})
	_place_crew(m, crew, rng, dx + 2, dx + 2 * R - 2, R + 2.5, COR_Y0 - 0.8)
	for k3 in 3:
		m.wander.append(Vector2(rng.randf_range(dx + 2, dx + 2 * R - 2), rng.randf_range(R + 6.5, COR_Y0 - 0.5)) * GroundMap.TILE)


const SEATS := ["chair", "stool", "sofa", "bench", "lounger", "crate_seat"]


## Where someone sits on seat i of a seat object: just in front of it (drawn over it), raised onto it by the walker.
static func _seat_pos(o: Dictionary, i: int = 0) -> Vector2:
	return Vector2(float(o["x"]) + 0.5 + i, float(o["y"]) + 1.02) * GroundMap.TILE


## A seat (chair, stool, bench …) facing `face`; now and then somebody already sits there.
static func _seat(m: GroundMap, kind: String, x: int, y: int, face: int, col: Color, rng: RandomNumberGenerator, chance: float, w: int = 1) -> void:
	var o := {"kind": kind, "x": x, "y": y, "w": w, "h": 1, "col": col, "face": face}
	m.add_object(o, false)
	if kind == "bench" and face == 1:
		m.add_object({"kind": "bench_back", "x": x, "y": y, "w": w, "h": 1, "col": col, "sort_dy": 0.15}, false)
	for i in w:
		if rng.randf() < chance:
			m.people.append({"pos": _seat_pos(o, i), "dir": face, "sit": true})


## Light from props that glow.
static func _prop_light(m: GroundMap, kind: String, at: Vector2) -> void:
	var c := Color.BLACK
	var r := 30.0
	match kind:
		"lamp_post":
			c = Color(m.pal["accent"]).lerp(Color.WHITE, 0.3)
			r = 44.0
		"holo_pillar":
			c = m.pal["accent"]
		"tank":
			c = Color(0.3, 1.0, 0.6)
		"heater":
			c = Color(1.0, 0.5, 0.15)
		"fountain":
			c = Color(0.4, 0.8, 1.0)
		"vending":
			c = Color(0.5, 0.8, 1.0)
		"engine_part":
			c = Color(0.4, 0.75, 1.0)
	if c != Color.BLACK:
		m.lights.append({"pos": at * GroundMap.TILE, "r": r, "col": c, "a": 0.32})


## Round tables, a chair either side, a sofa and a rug – the classic lounge (trade hubs, ice refineries).
static func _bar_lounge(m: GroundMap, x0: int, x1: int, sc: Color, rng: RandomNumberGenerator) -> void:
	var tx := x0 + 2
	var row := 0
	while tx + 2 < x1:
		var ty := BAR_Y0 + 2 + (0 if row % 2 == 0 else 4)
		m.add_object({"kind": "round_table", "x": tx, "y": ty, "w": 2, "h": 2})
		_seat(m, "chair", tx - 1, ty, 3, sc, rng, 0.55)
		_seat(m, "chair", tx + 2, ty, 2, sc, rng, 0.45)
		m.lights.append({"pos": Vector2(tx + 1.0, ty + 1.2) * GroundMap.TILE, "r": 30.0, "col": Color(1.0, 0.7, 0.4), "a": 0.22})
		tx += 5
		row += 1
	m.add_object({"kind": "plant", "x": x0 - 1, "y": COR_Y0 - 1, "w": 1, "h": 1})
	_seat(m, "sofa", x0, COR_Y0 - 2, 0, m.pal["carpet"], rng, 0.3, 3)
	m.decals.append({"kind": "rug", "x": x0 + 4, "y": BAR_Y0 + 4, "w": 5, "h": 3, "col": m.pal["carpet"]})


## Long tables with benches either side – a mess hall (military), a canteen (industry, shipyards), picnic tables
## among the planters (agri).
static func _bar_long(m: GroundMap, x0: int, x1: int, sc: Color, rng: RandomNumberGenerator, style: String) -> void:
	var tw := 4 if style != "garden" else 3
	var tx := x0 + 1
	while tx + tw <= x1:
		for ty in [BAR_Y0 + 2, BAR_Y0 + 6]:
			m.add_object({"kind": "table", "x": tx, "y": ty, "w": tw, "h": 1})
			_seat(m, "bench", tx, ty - 1, 0, sc, rng, 0.35, tw)
			_seat(m, "bench", tx, ty + 1, 1, sc, rng, 0.35, tw)
			m.lights.append({"pos": Vector2(tx + tw * 0.5, ty + 0.6) * GroundMap.TILE, "r": 40.0,
				"col": Color(1.0, 0.95, 0.85) if style != "garden" else Color(1.0, 0.75, 0.45), "a": 0.2})
		tx += tw + 2
	if style == "canteen":
		for k in 2:
			m.add_object({"kind": "vending", "x": x0 - 1 + k, "y": COR_Y0 - 1, "w": 1, "h": 1, "col": Color(0.4, 0.75, 1.0)})
	elif style == "garden":
		m.add_object({"kind": "flower_bed", "x": x0, "y": COR_Y0 - 1, "w": 3, "h": 1})
	else:
		m.add_object({"kind": "crates", "x": x0 - 1, "y": COR_Y0 - 1, "w": 2, "h": 1})


## Small square tables for two, bright and quiet – a café (research stations).
static func _bar_cafe(m: GroundMap, x0: int, x1: int, sc: Color, rng: RandomNumberGenerator) -> void:
	for ty in [BAR_Y0 + 2, BAR_Y0 + 5]:
		var tx := x0 + 1 + (0 if ty == BAR_Y0 + 2 else 2)
		while tx + 1 < x1:
			m.add_object({"kind": "table_small", "x": tx, "y": ty, "w": 1, "h": 1})
			_seat(m, "chair", tx - 1, ty, 3, sc, rng, 0.45)
			_seat(m, "chair", tx + 1, ty, 2, sc, rng, 0.4)
			tx += 5
	m.add_object({"kind": "plant", "x": x0 - 1, "y": COR_Y0 - 1, "w": 1, "h": 1})
	m.add_object({"kind": "holo_pillar", "x": x0 + 3, "y": COR_Y0 - 1, "w": 1, "h": 1, "col": m.pal["accent"]})
	_prop_light(m, "holo_pillar", Vector2(x0 + 3.5, COR_Y0 - 0.2))


## A dive: a pool table, barrels for tables, crates to sit on (mining colonies, pirate havens).
static func _bar_dive(m: GroundMap, x0: int, x1: int, sc: Color, rng: RandomNumberGenerator) -> void:
	m.add_object({"kind": "pool_table", "x": x0 + 1, "y": BAR_Y0 + 3, "w": 3, "h": 2})
	m.lights.append({"pos": Vector2(x0 + 2.5, BAR_Y0 + 4.2) * GroundMap.TILE, "r": 40.0, "col": Color(0.6, 1.0, 0.6), "a": 0.25})
	for ty in [BAR_Y0 + 2, BAR_Y0 + 6]:
		var tx := x0 + 7 + (0 if ty == BAR_Y0 + 2 else 2)
		while tx + 1 < x1:
			m.add_object({"kind": "barrel_table", "x": tx, "y": ty, "w": 1, "h": 1})
			_seat(m, "crate_seat", tx - 1, ty, 3, sc, rng, 0.5)
			_seat(m, "crate_seat", tx + 1, ty, 2, sc, rng, 0.45)
			m.lights.append({"pos": Vector2(tx + 0.5, ty + 0.6) * GroundMap.TILE, "r": 26.0, "col": Color(1.0, 0.6, 0.3), "a": 0.25, "flicker": true})
			tx += 5
	m.decals.append({"kind": "rug", "x": x0, "y": BAR_Y0 + 2, "w": 5, "h": 4, "col": Color(0.3, 0.18, 0.12)})
	m.add_object({"kind": "barrel", "x": x0 - 1, "y": COR_Y0 - 1, "w": 1, "h": 1})
	m.add_object({"kind": "trash", "x": x0, "y": COR_Y0 - 1, "w": 1, "h": 1})


## A beach bar: sand, a pool in the middle, sun loungers under parasols, palms – resorts.
static func _bar_beach(m: GroundMap, x0: int, x1: int, sc: Color, rng: RandomNumberGenerator) -> void:
	var pw := mini(10, (x1 - x0) / 2)
	var px0 := x0 + 2
	m.fill(px0, BAR_Y0 + 2, pw, 3, GroundMap.T.BLOCK, 10)
	for k in pw / 2:
		m.lights.append({"pos": Vector2(px0 + 1 + k * 2, BAR_Y0 + 3.5) * GroundMap.TILE, "r": 30.0, "col": Color(0.3, 0.8, 1.0), "a": 0.22})
	var lx := px0
	while lx + 1 < px0 + pw:
		_seat(m, "lounger", lx, BAR_Y0 + 6, 0, sc if (lx / 2) % 2 == 0 else Color(0.3, 0.75, 0.85), rng, 0.4)
		m.add_object({"kind": "parasol", "x": lx + 1, "y": BAR_Y0 + 6, "w": 1, "h": 1, "col": [Color(1.0, 0.45, 0.4), Color(1.0, 0.85, 0.35), Color(0.35, 0.8, 0.9)][(lx / 3) % 3]})
		lx += 3
	# little tables for two by the pool
	var tx := px0 + pw + 3
	while tx + 1 < x1:
		for ty in [BAR_Y0 + 2, BAR_Y0 + 5]:
			m.add_object({"kind": "table_small", "x": tx, "y": ty, "w": 1, "h": 1})
			_seat(m, "chair", tx - 1, ty, 3, Color(0.95, 0.95, 0.9), rng, 0.45)
			_seat(m, "chair", tx + 1, ty, 2, Color(0.95, 0.95, 0.9), rng, 0.4)
		tx += 5
	m.add_object({"kind": "palm", "x": x0 - 1, "y": COR_Y0 - 1, "w": 1, "h": 1})
	m.add_object({"kind": "palm", "x": px0 + pw, "y": COR_Y0 - 1, "w": 1, "h": 1})
	m.add_object({"kind": "flower_bed", "x": x0, "y": COR_Y0 - 1, "w": 2, "h": 1})


## Every free seat becomes a place to sit down (E): chairs, bar stools, the sofa, the lobby bench.
static func _seats(m: GroundMap) -> void:
	for o in m.objects:
		var k := String(o["kind"])
		if not k in SEATS:
			continue
		for i in int(o.get("w", 1)):
			var sp := _seat_pos(o, i)
			var taken := false
			for p in m.people:
				if (p["pos"] as Vector2).distance_to(sp) < 8.0:
					taken = true
			if taken:
				continue
			var r := Rect2(sp + Vector2(-0.8, -0.9) * GroundMap.TILE, Vector2(1.6, 1.7) * GroundMap.TILE)
			if k in ["sofa", "bench", "lounger"]:
				r = Rect2(sp + Vector2(-0.5, -0.4) * GroundMap.TILE, Vector2(1.0, 1.4) * GroundMap.TILE)
			m.zones.append({"rect": r, "kind": "seat", "id": "seat", "title": {"chair": "Sit down", "stool": "Sit at the bar",
				"sofa": "Sit on the sofa", "bench": "Sit on the bench", "lounger": "Lie in the sun", "crate_seat": "Sit down"}[k],
				"seat": sp, "dir": int(o.get("face", 0)), "sign": Vector2(-100, -100)})


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


## One shop room below the corridor: a door in the corridor's wall, its back wall (seen from inside) with shelves,
## the counter along the right side with the shopkeeper behind it.
static func _shop(m: GroundMap, id: String, sx: int, available: Dictionary, dock: Array, rng: RandomNumberGenerator, station: Dictionary, cap_y: int = SHOP_CAP) -> void:
	var scap := cap_y
	var sface := cap_y + 1
	var sy1 := cap_y + (SHOP_Y1 - SHOP_CAP)
	var rw := SHOP_W
	m.fill(sx, scap, rw, sy1 - scap + 2, GroundMap.T.CAP)
	m.fill(sx + 1, sface, rw - 2, 1, GroundMap.T.FACE)
	m.fill(sx + 1, sface + 1, rw - 2, sy1 - sface, GroundMap.T.FLOOR, 1)
	var dx := sx + rw / 2 - 1
	m.fill(dx, scap, 2, 2, GroundMap.T.DOOR, 1)
	var col: Color = _svc_col(id) if id != "dock" else m.pal["accent"]
	var sign := Vector2(dx + 1, scap + 0.55) * GroundMap.TILE
	var inside := Rect2(Vector2(sx + 1, sface + 1) * GroundMap.TILE, Vector2(rw - 2, sy1 - sface) * GroundMap.TILE)
	if id == "dock":
		var tx := sx + 1
		for d in dock:
			if tx >= sx + rw - 1:
				break
			m.add_object({"kind": "terminal", "x": tx, "y": sy1, "w": 1, "h": 1, "col": _svc_col(d), "icon": _svc_icon(d)})
			_zone(m, d, available, Rect2(Vector2(tx - 0.1, sy1 - 1.3) * GroundMap.TILE, Vector2(1.2, 1.5) * GroundMap.TILE),
				Vector2(-100, -100))
			m.lights.append({"pos": Vector2(tx + 0.5, sy1 - 0.2) * GroundMap.TILE, "r": 18.0, "col": _svc_col(d), "a": 0.3})
			tx += 1
		m.zones.append({"rect": Rect2(), "kind": "label", "title": "Dock Office", "col": col, "sign": sign, "id": "dock"})
		m.add_object({"kind": "plant", "x": sx + rw - 2, "y": sface + 1, "w": 1, "h": 1})
		return
	_zone(m, id, available, inside, sign)
	var deco := "shelf"
	match id:
		"outfitter":
			deco = "rack"
		"shipyard", "exchange", "senate", "curia", "bonds":
			deco = "screen"
		"look":
			deco = "poster"
	for fx in range(sx + 1, sx + rw - 1, 2):
		if fx + 1 < sx + rw - 1 and not (fx <= dx + 1 and fx + 1 >= dx):
			m.face_deco.append({"kind": deco, "x": fx, "y": sface, "w": 2, "col": col})
	# the counter on the right, the shopkeeper behind it facing the room
	m.add_object({"kind": "counter_v", "x": sx + rw - 3, "y": sface + 2, "w": 1, "h": 3})
	m.people.append({"pos": Vector2(sx + rw - 1.5, sface + 3.8) * GroundMap.TILE, "dir": 2, "role": "keeper"})
	m.wander.append(Vector2(sx + rw - 3.6, sface + 3.4) * GroundMap.TILE)          # customers at the counter
	match id:
		"market":
			m.add_object({"kind": "crates", "x": sx + 1, "y": sy1, "w": 2, "h": 1})
		"outfitter", "shipyard":
			m.add_object({"kind": "display", "x": sx + 1, "y": sy1 - 1, "w": 2, "h": 1, "col": col})
		"refinery", "manufacturing":
			m.add_object({"kind": "machine", "x": sx + 1, "y": sy1 - 1, "w": 2, "h": 2})
		_:
			m.add_object({"kind": "plant", "x": sx + 1, "y": sy1, "w": 1, "h": 1})
	m.decals.append({"kind": "mat", "x": dx, "y": sface + 1, "w": 2, "h": 1, "col": col})


# ---------------------------------------------------------------- 0.7.49.8: the hangar

const HANGAR_SERVICES := ["hangar", "shipyard"]   # 0.7.49.9: shops on the hangar walkway, not up on the commercial level
const HANGAR_STAIRS := 3              # tiles at the west end: the stairs down to the ship
const HANGAR_LOBBY := 6               # tiles at the east end: the lifts


## The hangar level: a raised walkway along a glass front, below it the closed hangar where your ship stands (its
## length decides the walkway's); the stairs down to the ship at the west end (you start there), the lifts at the
## east end. ship_len / ship_beam: the ship's size in art px (nose to the east).
## The number of the hangar a ship stands in at this station.
static func hangar_no(station: Dictionary, uid: int) -> int:
	return 1 + absi(hash("%s_%d" % [String(station.get("id", "")), uid])) % 24


static func build_hangar(station: Dictionary, ship_len: float, ship_beam: float, available: Dictionary = {}, uid: int = 0) -> GroundMap:
	var m := GroundMap.new()
	m.pal = palette_for(station)
	m.title = String(station.get("name", "Station"))
	var hshops: Array = []
	for hs in HANGAR_SERVICES:
		if available.has(hs):
			hshops.append(hs)
	var HW := clampi(maxi(int(ceil(ship_len / GroundMap.TILE)) + 10, hshops.size() * (SHOP_W - 1) + 2), 22, 64)
	var HH := clampi(int(ceil(ship_beam / GroundMap.TILE)) + 6, 9, 16)
	var x_h := 1 + HANGAR_STAIRS                         # the hangar's first column
	var W := x_h + HW + HANGAR_LOBBY + 1
	var G := 3 + HH                                      # the glass front's first row
	var H := G + 6 + (SHOP_Y1 - SHOP_CAP + 2 if not hshops.is_empty() else 0)
	m.setup(W, H)
	m.hull_top = -60                                     # all round: the station
	m.under_glass = 11
	# the hangar: its far wall with the bay doors, the floor below
	m.fill(x_h - 1, 0, HW + 2, 1, GroundMap.T.CAP)
	m.fill(x_h, 1, HW, 2, GroundMap.T.FACE)
	m.fill(x_h, 3, HW, HH, GroundMap.T.BLOCK, 11)
	m.fill(x_h - 1, 1, 1, G + 1, GroundMap.T.CAP)
	m.fill(x_h + HW, 1, 1, G + 1, GroundMap.T.CAP)
	m.face_deco.append({"kind": "bay_door", "x": x_h + HW / 2 - 5, "y": 2, "w": 10, "col": m.pal["accent"]})
	m.decals.append({"kind": "bay", "x": x_h, "y": 3, "w": HW, "h": HH, "col": m.pal["accent"]})
	m.decals.append({"kind": "pad", "x": x_h + 3, "y": 4, "w": HW - 6, "h": HH - 2, "col": Color(0.95, 0.8, 0.2)})
	m.bay_rect = Rect2(x_h, 1, HW, G - 1)
	# the glass front of the walkway
	m.fill(x_h, G, HW, 2, GroundMap.T.GLASS)
	# the walkway, the stairs end, the lifts end
	m.fill(0, G - 1, x_h, 1, GroundMap.T.CAP)
	m.fill(1, G, HANGAR_STAIRS - 1 + 1, 2, GroundMap.T.FACE)
	m.fill(x_h + HW + 1, G - 1, HANGAR_LOBBY, 1, GroundMap.T.CAP)
	m.fill(x_h + HW + 1, G, HANGAR_LOBBY - 1, 2, GroundMap.T.FACE)
	m.fill(0, G, 1, 6, GroundMap.T.CAP)
	m.fill(W - 1, G - 1, 1, 7, GroundMap.T.CAP)
	m.fill(1, G + 2, W - 2, 3, GroundMap.T.FLOOR, 0)
	m.fill(0, G + 5, W, 1, GroundMap.T.CAP)
	m.decals.append({"kind": "stairs", "x": 1, "y": G + 2, "w": 2, "h": 3, "col": m.pal["accent"]})
	m.decals.append({"kind": "guide", "x": 3, "y": G + 3, "w": W - 4, "h": 1, "col": m.pal["accent"]})
	m.spawn = Vector2(2.6, G + 3.5) * GroundMap.TILE
	m.zones.append({"rect": Rect2(Vector2(1, G + 2) * GroundMap.TILE, Vector2(2.2, 3) * GroundMap.TILE), "kind": "exit", "id": "ship",
		"title": "Stairs down – back aboard your ship", "col": Color(0.4, 1.0, 0.6), "sign": Vector2(-100, -100)})
	var lx0 := x_h + HW + 1
	for k in 2:
		m.face_deco.append({"kind": "lift", "x": lx0 + k * 3, "y": G + 1, "w": 2, "col": Color(0.4, 1.0, 0.6)})
		m.lifts.append({"x": lx0 + k * 3, "y": G + 1, "w": 2})
	m.zones.append({"rect": Rect2(Vector2(lx0, G + 2) * GroundMap.TILE, Vector2(5, 1.4) * GroundMap.TILE), "kind": "lift", "id": "lift",
		"title": "Lifts – Hangar · Commercial level", "col": Color(0.4, 1.0, 0.6), "sign": Vector2(-100, -100)})
	m.zones.append({"rect": Rect2(), "kind": "label", "id": "hangar_sign", "title": "Hangar %02d" % hangar_no(station, uid),
		"col": m.pal["accent"], "sign": Vector2(x_h + HW * 0.5, G + 0.45) * GroundMap.TILE})
	# the ship lies in the middle of the bay, nose to the east
	m.ship_at = Vector2(x_h + HW * 0.5, 3 + HH * 0.5) * GroundMap.TILE
	# things on the hangar floor, lamps over it, a mechanic or two
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(station.get("id", "x"))) + 7
	var lxx := x_h + 3
	while lxx < x_h + HW - 2:
		m.lights.append({"pos": Vector2(lxx, 3 + HH * 0.5) * GroundMap.TILE, "r": 70.0, "col": Color(0.8, 0.88, 1.0), "a": 0.08})
		lxx += 7
	# the hangar's services: shops on the south side of the walkway
	var hsx := x_h + 1
	for hs2 in hshops:
		_shop(m, hs2, hsx, available, [], rng, station, G + 5)
		hsx += SHOP_W - 1
	for k3 in 3:
		m.lights.append({"pos": Vector2(x_h + HW * (0.2 + k3 * 0.3), G + 3.0) * GroundMap.TILE, "r": 44.0, "col": Color(m.pal["accent"]).lerp(Color.WHITE, 0.4), "a": 0.22})
	m.add_object({"kind": "plant", "x": W - 2, "y": G + 4, "w": 1, "h": 1})
	# a bench by the glass, facing the ship – clear of the shop doors on the other side
	_seat(m, "bench", x_h + HW / 2 - 4, G + 2, 1, m.pal["accent"], rng, 0.0, 2)
	_seats(m)
	for k4 in 5:
		m.wander.append(Vector2(rng.randf_range(4, W - 3), rng.randf_range(G + 2.4, G + 4.2)) * GroundMap.TILE)
	return m


# ---------------------------------------------------------------- package 50: a landing field on a planet

## Colours for a landing site from the body it lies on.
static func palette_for_body(body: Dictionary) -> Dictionary:
	var bt := Universe.body_type(String(body.get("type", "")))
	var a: Color = bt.get("a", Color(0.4, 0.38, 0.35))
	var b: Color = bt.get("b", Color(0.5, 0.45, 0.38))
	var c: Color = bt.get("c", Color(0.62, 0.56, 0.45))
	var wall := Color(0.62, 0.64, 0.68)
	return {"floor": Color(0.42, 0.43, 0.46), "floor2": Color(0.46, 0.47, 0.5), "shop_floor": Color(0.5, 0.48, 0.45),
		"wood": Color(0.46, 0.3, 0.18), "carpet": Color(0.4, 0.25, 0.3), "wall": wall, "wall_top": wall.darkened(0.55),
		"trim": wall.darkened(0.35), "frame": wall.darkened(0.25), "accent": Color(1.0, 0.8, 0.25), "type": "landing",
		"terrain_a": a, "terrain_b": b, "terrain_c": c}


## The landing field at a site: the ground of the planet all round, a concrete pad with your ship on it and her ramp
## down, lights along the pad, fuel and crates, and a gravel path to the place itself (the city's gate, the camp …).
static func build_landing(body: Dictionary, site: Dictionary, ship_len: float, ship_beam: float) -> GroundMap:
	var m := GroundMap.new()
	m.pal = palette_for_body(body)
	m.title = String(site.get("name", "Landing site"))
	m.hull_top = -60
	var sl := clampi(int(ceil(ship_len / GroundMap.TILE)) + 4, 10, 40)
	var sb := clampi(int(ceil(ship_beam / GroundMap.TILE)) + 4, 7, 20)
	var W := sl + 24
	var H := sb + 12
	m.setup(W, H)
	m.fill(0, 0, W, H, GroundMap.T.FLOOR, 13)
	m.fill(0, 0, W, 1, GroundMap.T.BLOCK, 13)                  # an edge you cannot walk past (the ground goes on)
	m.fill(0, H - 1, W, 1, GroundMap.T.BLOCK, 13)
	m.fill(0, 0, 1, H, GroundMap.T.BLOCK, 13)
	m.fill(W - 1, 0, 1, H, GroundMap.T.BLOCK, 13)
	var px0 := 3
	var py0 := 3
	m.fill(px0, py0, sl, sb, GroundMap.T.FLOOR, 14)
	m.decals.append({"kind": "pad_marks", "x": px0, "y": py0, "w": sl, "h": sb, "col": Color(0.95, 0.8, 0.2)})
	# the ship on the pad, nose to the east – you cannot walk through her
	var sc := Vector2(px0 + sl * 0.5, py0 + sb * 0.5)
	m.ship_at = sc * GroundMap.TILE
	var bx := int(sc.x - ship_len / GroundMap.TILE * 0.5) + 1
	var bw := maxi(2, int(ship_len / GroundMap.TILE) - 2)
	var bh := maxi(1, int(ship_beam / GroundMap.TILE) - 1)
	m.fill(bx, int(sc.y - bh * 0.5), bw, bh, GroundMap.T.BLOCK, 14)
	# her ramp, down to the south side of the pad
	var rx := int(sc.x) - 1
	var ry := int(sc.y + bh * 0.5)
	m.decals.append({"kind": "ramp", "x": rx, "y": ry, "w": 2, "h": 2, "col": Color(1.0, 0.8, 0.25)})
	m.spawn = Vector2(rx + 1.0, ry + 2.6) * GroundMap.TILE
	m.zones.append({"rect": Rect2(Vector2(rx - 0.5, ry) * GroundMap.TILE, Vector2(3, 3.2) * GroundMap.TILE), "kind": "exit", "id": "ship",
		"title": "Up the ramp – take off", "col": Color(0.4, 1.0, 0.6), "sign": Vector2(-100, -100)})
	# lights round the pad, a fuel tank, crates
	for k in range(0, sl + 1, 4):
		m.lights.append({"pos": Vector2(px0 + k, py0) * GroundMap.TILE, "r": 22.0, "col": Color(1.0, 0.75, 0.3), "a": 0.35, "flicker": k % 8 == 0})
		m.lights.append({"pos": Vector2(px0 + k, py0 + sb) * GroundMap.TILE, "r": 22.0, "col": Color(1.0, 0.75, 0.3), "a": 0.35})
	m.add_object({"kind": "machine", "x": px0 + sl + 1, "y": py0, "w": 2, "h": 2})
	m.add_object({"kind": "crates", "x": px0 + sl + 1, "y": py0 + sb - 1, "w": 2, "h": 1})
	m.add_object({"kind": "lamp_post", "x": px0 + sl + 1, "y": py0 + sb + 2, "w": 1, "h": 1, "col": Color(1.0, 0.8, 0.4)})
	m.lights.append({"pos": Vector2(px0 + sl + 1.5, py0 + sb + 2.3) * GroundMap.TILE, "r": 44.0, "col": Color(1.0, 0.85, 0.5), "a": 0.35})
	# the path to the place itself
	var kd := String(site.get("kind", "outpost"))
	var path_y := py0 + sb + 3
	m.fill(int(sc.x), py0 + sb, 2, 3, GroundMap.T.FLOOR, 15)
	m.fill(int(sc.x), path_y, W - 2 - int(sc.x), 2, GroundMap.T.FLOOR, 15)
	var gx := W - 4
	m.add_object({"kind": "banner", "x": gx, "y": path_y - 2, "w": 1, "h": 1, "col": Universe.SITE_KINDS[kd]["col"]})
	m.add_object({"kind": "banner", "x": gx, "y": path_y + 2, "w": 1, "h": 1, "col": Universe.SITE_KINDS[kd]["col"]})
	m.zones.append({"rect": Rect2(Vector2(gx - 2, path_y - 0.5) * GroundMap.TILE, Vector2(4, 3) * GroundMap.TILE), "kind": "soon", "id": "site",
		"title": "%s – %s" % [String(site["name"]), "the city opens with the next update" if kd == "city" else "exploring comes with a later update"],
		"col": Universe.SITE_KINDS[kd]["col"], "sign": Vector2(-100, -100)})
	m.zones.append({"rect": Rect2(), "kind": "label", "id": "site_sign", "title": "%s  →" % String(site["name"]),
		"col": Universe.SITE_KINDS[kd]["col"], "sign": Vector2(gx - 3, path_y - 1.2) * GroundMap.TILE})
	for k2 in 4:
		m.wander.append(Vector2(randf_range(int(sc.x) + 2, W - 4), path_y + 1.0) * GroundMap.TILE)
	return m
