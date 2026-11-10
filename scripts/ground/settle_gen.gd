class_name SettleGen
extends RefCounted
## 0.7.50.10 (Luz): a settlement – the small places on a planet (outposts, mines, research camps) – as one walkable
## map under the open sky: its landing pads (four – the landing drones come and go on the free ones), a street with
## its shops (walk-in, like a station's), houses, the building its economy is known for, guards on their rounds.
## What bounds it is the world itself: dense jungle on a jungle world, platforms on the sea of an ocean world, dunes
## and rocks in the desert, ice on an ice world, a crater's rocks on barren worlds and moons, cooled lava on a lava
## world.

const TW := 66                        # the town's part of the map
const W := 94                         # 0.7.50.12: and east of it, behind a fence, the economy area
const H := 40
const B := 4                          # the border the world fills
const PAD := Vector2i(6, 5)           # a landing pad (tiles)
const STREET_Y := 20                  # the street's first row
const STREET_H := 4
const SHOP_CAP := STREET_Y + STREET_H # the shops' wall on the street's south side
const SHOP_X0 := 23
const SHOPS := ["market", "outfitter", "bar", "repair", "bulletin", "news"]

## The special building by what the place lives from: [title, service it opens, objects]
const SPECIAL := {
	"mining": ["ORE DEPOT", "market", "tower_rig"],
	"agri": ["AGRI CO-OP", "market", "greenhouse"],
	"industry": ["WORKSHOP", "market", "machine"],
	"refinery": ["REFINERY OUTLET", "market", "silo"],
	"chemistry": ["CHEM PLANT", "market", "silo"],
	"hightech": ["TECH LAB", "market", "dish"],
	"research": ["RESEARCH STATION", "market", "dish"],
	"military": ["RECRUITMENT", "bar", "banner"],
	"tourism": ["LOOKOUT HOTEL", "market", "parasol"],
}

## How each kind of world bounds a settlement: the ground's edge objects and their colours.
const BOUNDS := {
	"jungle": "jungle", "terran": "woods", "ocean": "sea", "desert": "dunes", "ice": "ice", "moon_ice": "ice",
	"lava": "lava", "moon_volcanic": "lava", "barren": "rocks", "dwarf": "rocks", "moon_rock": "rocks",
	"moon_captured": "rocks", "toxic": "toxic", "metal": "rocks",
}


## What the place lives from: a mine digs, a research camp researches; an outpost lives from its system's economy.
static func economy(site: Dictionary, sys_id: int) -> String:
	if site.has("economy"):
		return String(site["economy"])            # (a place with its own – and for the debug views)
	match String(site.get("kind", "")):
		"mine":
			return "mining"
		"research":
			return "research"
	if sys_id >= 0:
		return String(Economy.of(sys_id).get("main", "mining"))
	return "mining"


static func bounds(body: Dictionary) -> String:
	return String(BOUNDS.get(String(body.get("type", "")), "rocks"))


static func build(station: Dictionary, body: Dictionary, site: Dictionary, available: Dictionary, sys_id: int, uid: int = 0) -> GroundMap:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(site.get("id", "x"))) + 101
	var m := GroundMap.new()
	m.pal = DeckGen.palette_for_body(body)
	var dp: Array = CityStyle.deck(station)["pal"]               # the walls and lights in its power's colours
	var wall: Color = dp[5]
	m.pal["wall"] = wall
	m.pal["wall_top"] = wall.darkened(0.55)
	m.pal["trim"] = wall.darkened(0.35)
	m.pal["frame"] = wall.darkened(0.25)
	m.pal["accent"] = dp[6]
	m.pal["shop_floor"] = dp[2]
	m.pal["wood"] = dp[3]
	m.title = String(site.get("name", "Settlement"))
	m.setup(W, H)
	var bk := bounds(body)
	var sea := bk == "sea"
	# the ground (or the sea, with the settlement on its platforms)
	if sea:
		m.fill(0, 0, W, H, GroundMap.T.BLOCK, 10)
		m.fill(B, B + 1, 17, 18, GroundMap.T.FLOOR, 14)                     # the pad platform
		m.fill(B + 19, B + 6, TW - B * 2 - 19, 14, GroundMap.T.FLOOR, 14)   # the town platform, north …
		m.fill(B, STREET_Y - 1, TW - B, H - STREET_Y - B + 1, GroundMap.T.FLOOR, 14)   # … and along the street
		m.fill(B + 17, B + 8, 2, 3, GroundMap.T.FLOOR, 15)                  # a gangway across
	else:
		m.fill(0, 0, W, H, GroundMap.T.FLOOR, 13)
	# the pads, two by two, west of the town
	for i in 4:
		var px := B + 1 + (i % 2) * (PAD.x + 2)
		var py := B + 2 + (i / 2) * (PAD.y + 3)
		m.fill(px, py, PAD.x, PAD.y, GroundMap.T.FLOOR, 14)
		m.decals.append({"kind": "pad_marks", "x": px, "y": py, "w": PAD.x, "h": PAD.y, "col": Color(0.95, 0.8, 0.2)})
		m.pads.append(Vector2(px + PAD.x * 0.5, py + PAD.y * 0.5) * GroundMap.TILE)
		for c in [Vector2(px, py), Vector2(px + PAD.x, py), Vector2(px, py + PAD.y), Vector2(px + PAD.x, py + PAD.y)]:
			m.lights.append({"pos": c * GroundMap.TILE, "r": 16.0, "col": Color(1.0, 0.75, 0.3), "a": 0.4, "flicker": i == 0})
		m.zones.append({"rect": Rect2(), "kind": "label", "id": "pad_%d" % i, "title": "PAD %d" % (i + 1), "col": Color(0.95, 0.8, 0.2),
			"sign": Vector2(px + PAD.x * 0.5, py - 0.1) * GroundMap.TILE})
	# your landing drone on pad 1, its hatch to the south
	m.ship_at = m.pads[0]
	var p0: Vector2 = m.pads[0] / GroundMap.TILE
	m.fill(int(p0.x) - 1, int(p0.y) - 1, 3, 2, GroundMap.T.BLOCK, 14)
	m.spawn = Vector2(p0.x + 0.5, p0.y + 3.3) * GroundMap.TILE
	m.zones.append({"rect": Rect2(Vector2(p0.x - 1.5, p0.y + 1.2) * GroundMap.TILE, Vector2(4, 2.8) * GroundMap.TILE), "kind": "exit", "id": "ship",
		"title": "Board the landing drone – back up to your ship", "col": Color(0.4, 1.0, 0.6), "sign": Vector2(-100, -100)})
	# the street, from the pads to the far end
	var street_kind := 14 if CityStyle.key_for(station) in ["assembly", "directorate"] else 15
	m.fill(B + 1, STREET_Y, TW - B, STREET_H, GroundMap.T.FLOOR, street_kind)
	m.decals.append({"kind": "guide", "x": B + 1, "y": STREET_Y + 2, "w": TW - B, "h": 1, "col": m.pal["accent"]})
	# the shops on its south side – walk in
	var shops: Array = []
	for sid in SHOPS:
		if available.has(sid):
			shops.append(sid)
	var sx := SHOP_X0
	for s2 in shops:
		if sx + DeckGen.SHOP_W > TW - B:
			break
		DeckGen._shop(m, s2, sx, available, [], rng, station, SHOP_CAP)
		# 0.7.50.11: each shop its own striped awning over the street
		m.face_deco.append({"kind": "awning", "x": sx, "y": SHOP_CAP, "w": DeckGen.SHOP_W, "col": DeckGen._svc_col(s2).lerp(Color.from_hsv(rng.randf(), 0.5, 0.8), 0.35)})
		sx += DeckGen.SHOP_W - 1
	# the shops' block ends; the ground behind them is the world again
	var style := CityStyle.of(station)
	var roof := CityStyle.tone(style, "roof", 1.0)
	var face := CityStyle.tone(style, "facade", 1.0)
	var lamp: Color = m.pal["accent"]
	# the special building, then houses, north of the street
	var eco := economy(site, sys_id)
	var sp: Array = SPECIAL.get(eco, SPECIAL["mining"])
	var bx := B + 20
	var by := STREET_Y - 4                                             # its foot row (it stands on rows by … by+2)
	var skey := CityStyle.key_for(station)
	m.add_object(_building(_arch(skey, bk, rng, true), bx, by - 1, 9, 3, 2, skey, rng, lamp, 60))
	m.zones.append({"rect": Rect2(Vector2(bx + 3, by + 2) * GroundMap.TILE, Vector2(3, 1.6) * GroundMap.TILE), "kind": "service", "id": String(sp[1]),
		"title": String(sp[0]).capitalize() + "  –  " + {"mining": "ore straight from the mine", "agri": "food from its fields", "research": "samples and data", "industry": "parts from its shops",
			"refinery": "refined goods", "chemistry": "chemicals from the plant", "hightech": "tech from the lab", "military": "sign on crew", "tourism": "rooms and views"}.get(eco, "what the place makes"),
		"corp": "", "col": Color(1.0, 0.8, 0.3), "closed": String(available.get(String(sp[1]), "")),
		"sign": Vector2(-100, -100)})
	match String(sp[2]):
		"tower_rig":
			m.add_object({"kind": "tower_rig", "x": bx + 10, "y": by - 1, "w": 3, "h": 3})
			m.add_object({"kind": "ore_cart", "x": bx + 13, "y": by + 1, "w": 1, "h": 1})
			m.add_object({"kind": "rock", "x": bx + 14, "y": by, "w": 2, "h": 2, "col": Color(0.42, 0.36, 0.3)})
		"greenhouse":
			m.add_object({"kind": "greenhouse", "x": bx + 10, "y": by - 1, "w": 4, "h": 3})
			m.add_object({"kind": "silo", "x": bx + 14, "y": by, "w": 2, "h": 2})
		"silo":
			m.add_object({"kind": "silo", "x": bx + 10, "y": by, "w": 2, "h": 2, "col": Color(0.75, 0.78, 0.7)})
			m.add_object({"kind": "silo", "x": bx + 12, "y": by, "w": 2, "h": 2, "col": Color(0.72, 0.72, 0.75)})
			m.add_object({"kind": "pipes", "x": bx + 14, "y": by + 1, "w": 1, "h": 1})
		"dish":
			m.add_object({"kind": "dish", "x": bx + 10, "y": by, "w": 3, "h": 2})
			m.add_object({"kind": "holo_pillar", "x": bx + 13, "y": by + 1, "w": 1, "h": 1, "col": lamp})
		"machine":
			m.add_object({"kind": "machine", "x": bx + 10, "y": by, "w": 2, "h": 2})
			m.add_object({"kind": "crates", "x": bx + 12, "y": by + 1, "w": 2, "h": 1})
		"banner":
			m.add_object({"kind": "banner", "x": bx + 10, "y": by + 1, "w": 1, "h": 1, "col": lamp})
			m.add_object({"kind": "banner", "x": bx + 12, "y": by + 1, "w": 1, "h": 1, "col": lamp})
		_:
			m.add_object({"kind": "parasol", "x": bx + 10, "y": by + 1, "w": 2, "h": 1, "col": lamp})
	m.zones.append({"rect": Rect2(), "kind": "label", "id": "special_sign", "title": String(sp[0]), "col": Color(1.0, 0.8, 0.3),
		"sign": Vector2(bx + 4.5, by - 3.4) * GroundMap.TILE})
	m.lights.append({"pos": Vector2(bx + 4.5, by + 2.3) * GroundMap.TILE, "r": 46.0, "col": Color(1.0, 0.8, 0.45), "a": 0.35})
	# 0.7.50.11: the houses – each its own (architecture by the power and the world), in a front row along the street
	# and a back row behind it, with stalls, rovers, poles and greenery between
	var hx := bx + 17
	while hx + 5 < TW - B - 1:
		var hw := mini(rng.randi_range(5, 8), TW - B - 1 - hx)
		var hy := by - rng.randi_range(0, 1)
		var hd := 2 if rng.randf() < 0.6 else 3
		if hy + hd > by + 2:
			hy = by + 2 - hd
		m.add_object(_building(_arch(skey, bk, rng), hx, hy, hw, hd, 1 if rng.randf() < 0.7 else 2, skey, rng, lamp))
		m.lights.append({"pos": Vector2(hx + hw * 0.5, by + 2.4) * GroundMap.TILE, "r": 30.0, "col": Color(1.0, 0.82, 0.5), "a": 0.25})
		hx += hw
		var gap := rng.randi_range(1, 3)
		if gap >= 2 and hx + 2 < TW - B - 1:
			match rng.randi() % 4:
				0:
					m.add_object({"kind": "stall", "x": hx, "y": by + 1, "w": 2, "h": 1, "col": Color.from_hsv(rng.randf(), 0.6, 0.85), "seed": rng.randi()})
				1:
					m.add_object({"kind": "cable_pole", "x": hx, "y": by + 1, "w": 1, "h": 1})
				2:
					if bk in ["jungle", "woods"]:
						m.add_object({"kind": "shrub", "x": hx, "y": by + 1, "w": 2, "h": 1, "col": Color(0.22, 0.5, 0.24), "seed": rng.randi()})
					else:
						m.add_object({"kind": "barrel", "x": hx, "y": by + 1, "w": 1, "h": 1})
				_:
					m.add_object({"kind": "crates", "x": hx, "y": by + 1, "w": 2, "h": 1})
		hx += gap
	var hx2 := B + 21
	var back_y := B + 5
	while hx2 + 5 < TW - B - 1:
		var hw2 := mini(rng.randi_range(5, 9), TW - B - 1 - hx2)
		var hd2 := 2 + rng.randi() % 2
		m.add_object(_building(_arch(skey, bk, rng), hx2, back_y + rng.randi_range(0, 2), hw2, hd2, 1 + int(rng.randf() < 0.4), skey, rng, lamp))
		hx2 += hw2 + rng.randi_range(2, 5)
	m.add_object({"kind": "signpost", "x": B + 18, "y": STREET_Y - 1, "w": 1, "h": 1})
	m.add_object({"kind": "rover", "x": B + 2, "y": STREET_Y - 1, "w": 3, "h": 1, "col": Color.from_hsv(rng.randf(), 0.5, 0.75)})
	# lamp posts along the street, crates and life between
	var lx := B + 20
	while lx < TW - 1:
		m.add_object({"kind": "lamp_post", "x": lx, "y": STREET_Y - 1, "w": 1, "h": 1, "col": lamp})
		DeckGen._prop_light(m, "lamp_post", Vector2(lx + 0.5, STREET_Y - 0.7))
		lx += 9
	m.add_object({"kind": "crates", "x": B + 15, "y": STREET_Y - 3, "w": 2, "h": 1})
	m.add_object({"kind": "barrel", "x": B + 15, "y": B + 2, "w": 1, "h": 1})
	m.add_object({"kind": "machine", "x": B + 15, "y": B + 5, "w": 2, "h": 2})                 # the fuel pump by the pads
	# 0.7.50.12: what it lives from, east of the town behind a fence
	_econ(m, eco, bk, body, rng, sea)
	# what bounds it: the world
	_border(m, bk, body, rng)
	for k in 16:
		m.wander.append(Vector2(rng.randf_range(B + 2, TW - 1), rng.randf_range(STREET_Y + 0.3, STREET_Y + STREET_H - 0.4)) * GroundMap.TILE)
	for k2 in 4:
		m.wander.append(Vector2(rng.randf_range(B + 2, B + 17), rng.randf_range(B + 2, STREET_Y - 1)) * GroundMap.TILE)
	DeckGen._seats(m)
	return m


## The border: the world closes in round the settlement.
static func _border(m: GroundMap, bk: String, body: Dictionary, rng: RandomNumberGenerator) -> void:
	var bt := Universe.body_type(String(body.get("type", "")))
	var land: Color = Color(bt.get("b", Color(0.5, 0.45, 0.38)))
	if bk == "sea":
		# the sea all round; buoys and a mooring post here and there
		for k in 10:
			var p := Vector2(rng.randf_range(1, W - 2), rng.randf_range(1, 3) if k % 2 == 0 else rng.randf_range(H - 3, H - 1))
			m.lights.append({"pos": p * GroundMap.TILE, "r": 14.0, "col": Color(1.0, 0.3, 0.25) if k % 3 == 0 else Color(0.4, 1.0, 0.6), "a": 0.5, "flicker": true})
		return
	var kind := "rock"
	var col := land.darkened(0.25)
	var w := 2
	var hgt := 2
	match bk:
		"jungle", "woods":
			kind = "tree"
			col = Color(0.16, 0.42, 0.2) if bk == "jungle" else Color(0.22, 0.48, 0.24)
		"dunes":
			kind = "dune"
			col = land.lightened(0.1)
			w = 3
		"ice":
			kind = "crystal"
			col = Color(0.75, 0.9, 1.0)
		"lava":
			kind = "lava_rock"
			col = Color(0.22, 0.18, 0.17)
		"toxic":
			col = land.darkened(0.3).lerp(Color(0.5, 0.65, 0.2), 0.3)
	# fill the border ring – dense and irregular: big and small, kinds mixed, undergrowth in the gaps
	var green := kind == "tree"
	for pass_i in 2:
		for y in range(0, H, 1 if pass_i == 1 else 2):
			for x in range(0, W, 1 if pass_i == 1 else 2):
				var inner := x >= B and x < W - B and y >= B and y < H - B
				if inner:
					continue
				var o := _nature(kind, bk, col, rng, pass_i == 1 or y < 2)       # low things at the top edge – crowns would be cut
				var ow := int(o["w"])
				var oh := int(o["h"])
				if not _free(m, x, y, ow, oh):
					continue
				o["x"] = x
				o["y"] = y
				m.add_object(o)
				m.fill(x, y, ow, oh, GroundMap.T.BLOCK, 13)
	# a few further in, where nothing stands
	for k2 in 26:
		var x2 := rng.randi_range(B, TW - B - w)
		var y2 := rng.randi_range(B, H - B - hgt)
		if not _free(m, x2, y2, w, hgt) or (y2 >= DeckGen.COR_Y0 - 1 and y2 <= SHOP_CAP + 9):
			continue
		if x2 < B + 18 and y2 < STREET_Y:
			continue                                                       # not on the pads
		var o2 := _nature(kind, bk, col, rng, rng.randf() < 0.6)
		o2["x"] = x2
		o2["y"] = y2
		m.add_object(o2)
		m.fill(x2, y2, int(o2["w"]), int(o2["h"]), GroundMap.T.BLOCK, 13)
	if bk == "lava":
		for k3 in 8:
			m.lights.append({"pos": Vector2(rng.randf_range(0, W), rng.randf() * B if k3 % 2 == 0 else H - rng.randf() * B) * GroundMap.TILE, "r": 40.0, "col": Color(1.0, 0.45, 0.15), "a": 0.35, "flicker": true})


## 0.7.50.12: the economy area – what the place lives from, seen over a fence at the end of the street: an open pit
## with its excavator and haul trucks (mining), fields with a harvester and crop drones – or rows of greenhouses and
## hydroponic domes where nothing grows outside – (farming), halls with smoking chimneys and a container yard under a
## gantry crane (industry), a tank farm with its flare and tankers (refinery, chemistry), a dish array and a launch pad
## (research, high tech), a training yard with armoured vehicles (military), gardens and a lookout tower (tourism).
## On an ocean world: fish pens with a boat between them, or a rig on its platform.
const GROWS := ["terran", "jungle", "ocean", "desert"]


static func _econ(m: GroundMap, eco: String, bk: String, body: Dictionary, rng: RandomNumberGenerator, sea: bool) -> void:
	var rx := TW + 2
	var ry := B + 1
	var rw := W - B - rx
	var rh := H - B - 1 - ry
	var T := GroundMap.TILE
	m.fill(rx - 1, B, rw + 1, H - B * 2, GroundMap.T.BLOCK, 10 if sea else 13)
	# the fence along it – the street ends at it: a lookout
	m.add_object({"kind": "fence", "x": TW + 1, "y": B, "w": 1, "h": STREET_Y - B})
	m.add_object({"kind": "fence", "x": TW + 1, "y": STREET_Y + STREET_H, "w": 1, "h": H - B - STREET_Y - STREET_H})
	m.add_object({"kind": "railing", "x": TW + 1, "y": STREET_Y, "w": 1, "h": STREET_H})
	var growing := String(body.get("type", "")) in GROWS and Universe.has_atmosphere(body)
	var kind := eco
	if eco == "agri" and not growing and not sea:
		kind = "hydro"
	if sea:
		kind = "pens" if eco in ["agri", "tourism", "research", "hightech"] else "rig"
	var info := {"kind": kind, "rect": Rect2(Vector2(rx, ry) * T, Vector2(rw, rh) * T)}
	var title: String = {"mining": "OPEN PIT", "agri": "FIELDS", "hydro": "HYDROPONICS", "industry": "WORKS", "refinery": "TANK FARM",
		"chemistry": "CHEM WORKS", "research": "DISH ARRAY", "hightech": "LAUNCH PAD", "military": "TRAINING YARD",
		"tourism": "GARDENS", "pens": "FISH PENS", "rig": "OFFSHORE RIG"}.get(kind, "WORKS")
	m.zones.append({"rect": Rect2(), "kind": "label", "id": "econ_sign", "title": String(title), "col": Color(1.0, 0.8, 0.3),
		"sign": Vector2(TW + 0.5, STREET_Y - 1.4) * T})
	match kind:
		"mining":
			var pit := Rect2i(rx + 1, ry + 1, rw - 2, rh - 9)
			var stp := mini(pit.size.x, pit.size.y) * T / 12
			m.decals.append({"kind": "pit", "x": pit.position.x, "y": pit.position.y, "w": pit.size.x, "h": pit.size.y, "levels": 5, "step": stp})
			info["pit"] = Rect2(Vector2(pit.position) * T, Vector2(pit.size) * T)
			info["step"] = stp
			info["heap"] = Vector2(rx + rw - 5, ry + rh - 4) * T
			m.add_object({"kind": "heap", "x": rx + rw - 7, "y": ry + rh - 5, "w": 5, "h": 3, "col": Color(0.45, 0.38, 0.3)})
			m.add_object({"kind": "heap", "x": rx + 2, "y": ry + rh - 4, "w": 4, "h": 2, "col": Color(0.4, 0.4, 0.42)})
			m.add_object({"kind": "tower_rig", "x": rx + rw / 2 - 1, "y": ry + rh - 4, "w": 3, "h": 2})
		"agri":
			var cols := [Color(0.85, 0.72, 0.3), Color(0.35, 0.62, 0.25), Color(0.25, 0.48, 0.2), Color(0.55, 0.35, 0.55), Color(0.62, 0.55, 0.25)]
			var fields: Array = []
			for fx in 2:
				for fy in 3:
					var f := Rect2i(rx + 1 + fx * (rw / 2), ry + 1 + fy * (rh / 3), rw / 2 - 2, rh / 3 - 2)
					m.decals.append({"kind": "field", "x": f.position.x, "y": f.position.y, "w": f.size.x, "h": f.size.y,
						"col": cols[rng.randi() % cols.size()], "vert": rng.randf() < 0.4})
					fields.append(Rect2(Vector2(f.position) * T, Vector2(f.size) * T))
			m.decals.append({"kind": "canal", "x": rx + rw / 2 - 1, "y": ry + 1, "w": 1, "h": rh - 2})
			for k in 2:
				m.add_object({"kind": "silo", "x": rx + rw - 3, "y": ry + rh - 3 - k * 3, "w": 2, "h": 2, "col": Color(0.78, 0.76, 0.7)})
			info["fields"] = fields
		"hydro":
			for gy in 4:
				for gx in 3:
					if (gx + gy) % 3 == 2:
						m.add_object(_building("dome", rx + 1 + gx * 7, ry + 1 + gy * 7, 5, 3, 1, "assembly", rng, Color(0.6, 1.0, 0.7)))
					else:
						m.add_object({"kind": "greenhouse", "x": rx + 1 + gx * 7, "y": ry + 2 + gy * 7, "w": 6, "h": 3})
			info["fields"] = [Rect2(Vector2(rx, ry) * T, Vector2(rw, rh) * T)]
		"industry":
			m.decals.append({"kind": "yard", "x": rx, "y": ry, "w": rw, "h": rh})
			m.add_object(_building("prefab", rx + 1, ry + 2, 10, 4, 2, "independent", rng, Color(1.0, 0.8, 0.4)))
			m.add_object(_building("quonset", rx + 12, ry + 2, 8, 4, 1, "independent", rng, Color(1.0, 0.8, 0.4)))
			m.add_object({"kind": "smokestack", "x": rx + 3, "y": ry + 7, "w": 2, "h": 1})
			m.add_object({"kind": "smokestack", "x": rx + 7, "y": ry + 7, "w": 2, "h": 1, "col": Color(0.55, 0.5, 0.5)})
			for row in 2:
				for cy in 3:
					m.add_object(_building("container", rx + 2 + cy * 7, ry + rh - 4 - row * 5, 6, 2, 1, "independent", rng, Color(1.0, 0.8, 0.4)))
			for k in 6:                                               # pallets and crates in the yard
				var cx2 := rx + 2 + rng.randi_range(0, rw - 5)
				var cy2 := ry + 11 + rng.randi_range(0, 5)
				if _free_any(m, cx2, cy2, 2, 1):
					m.add_object({"kind": "crates" if k % 2 == 0 else "barrel", "x": cx2, "y": cy2, "w": 2 if k % 2 == 0 else 1, "h": 1})
			m.decals.append({"kind": "piperun", "x": rx + 1, "y": ry + 9, "w": rw - 2, "h": 1})
			info["stacks"] = [Vector2(rx + 4, ry + 7 - 4.2) * T, Vector2(rx + 8, ry + 7 - 4.2) * T]
			info["crane"] = Rect2(Vector2(rx + 1, ry + rh - 11) * T, Vector2(rw - 2, 9) * T)
			info["road"] = [Vector2(rx + 2, ry + 18) * T, Vector2(rx + rw - 3, ry + 18) * T]
		"refinery", "chemistry":
			m.decals.append({"kind": "yard", "x": rx, "y": ry, "w": rw, "h": rh})
			var tank_col := Color(0.82, 0.82, 0.78) if eco == "refinery" else Color(0.7, 0.82, 0.68)
			for ty in 3:
				for tx in 4:
					m.add_object({"kind": "silo", "x": rx + 1 + tx * 5, "y": ry + 2 + ty * 7, "w": 4, "h": 3, "rise": 18 + rng.randi() % 8, "col": tank_col.darkened(rng.randf() * 0.12)})
				m.decals.append({"kind": "piperun", "x": rx + 1, "y": ry + 6 + ty * 7, "w": rw - 4, "h": 1})
			m.add_object({"kind": "flare", "x": rx + rw - 3, "y": ry + rh - 3, "w": 2, "h": 2})
			info["flare"] = Vector2(rx + rw - 2, ry + rh - 1) * T + Vector2(0, -56 - 2 * T + 4)
			info["road"] = [Vector2(rx + 1, ry + rh - 1.5) * T, Vector2(rx + rw - 5, ry + rh - 1.5) * T]
		"research", "hightech":
			for dy in 2:
				for dx in 3:
					var dsz := 4 + rng.randi() % 2
					m.add_object({"kind": "dish", "x": rx + 1 + dx * 7, "y": ry + 1 + dy * 7, "w": dsz, "h": 2, "rise": 26 + dsz * 4})
					if dx > 0:
						m.decals.append({"kind": "cable", "x": rx + 3 + (dx - 1) * 7, "y": ry + 3 + dy * 7, "dx": 7 * T, "dy": 0})
			m.add_object(_building("module", rx + 2, ry + 15, 9, 3, 2, "directorate", rng, Color(0.6, 1.0, 0.8)))
			m.decals.append({"kind": "cable", "x": rx + 6, "y": ry + 10, "dx": 0, "dy": 5 * T})
			m.add_object({"kind": "rover", "x": rx + 13, "y": ry + 17, "w": 3, "h": 1, "col": Color(0.85, 0.85, 0.88)})
			var lp := Rect2i(rx + rw - 9, ry + rh - 9, 7, 7)
			m.decals.append({"kind": "pad_marks", "x": lp.position.x, "y": lp.position.y, "w": lp.size.x, "h": lp.size.y, "col": Color(0.95, 0.4, 0.2)})
			info["launch"] = Vector2(lp.position.x + lp.size.x * 0.5, lp.position.y + lp.size.y * 0.6) * T
		"military":
			m.decals.append({"kind": "yard", "x": rx, "y": ry, "w": rw, "h": rh})
			for t in 5:
				m.add_object({"kind": "target", "x": rx + 2 + t * 4, "y": ry + 2, "w": 1, "h": 1})
			for v in 3:
				m.add_object({"kind": "tank_vehicle", "x": rx + 2 + v * 7, "y": ry + rh - 3, "w": 5, "h": 2})
			m.add_object(_building("prefab", rx + 2, ry + 8, 12, 3, 1, "independent", rng, Color(1.0, 0.8, 0.4)))
			info["loop"] = Rect2(Vector2(rx + 2, ry + 13) * T, Vector2(rw - 4, 9) * T)
		"tourism":
			for k2 in 14:
				var gx2 := rx + 1 + rng.randi_range(0, rw - 4)
				var gy2 := ry + 1 + rng.randi_range(0, rh - 4)
				if not _free_any(m, gx2, gy2, 3, 2):
					continue
				var pick := rng.randi() % 3
				if pick == 0:
					m.add_object({"kind": "tree", "x": gx2, "y": gy2, "w": 2, "h": 2, "rise": 44, "species": "broad", "col": Color(0.25, 0.55, 0.28), "seed": rng.randi()})
				elif pick == 1:
					m.add_object({"kind": "flower_bed", "x": gx2, "y": gy2, "w": 3, "h": 1})
				else:
					m.add_object({"kind": "palm", "x": gx2, "y": gy2, "w": 1, "h": 1})
			m.add_object({"kind": "fountain", "x": rx + rw / 2 - 1, "y": ry + rh / 2, "w": 2, "h": 2})
			m.add_object({"kind": "lookout", "x": rx + rw - 5, "y": ry + 2, "w": 3, "h": 2})
		"pens":
			var pens: Array = []
			for py2 in 3:
				for px2 in 2:
					var pr := Rect2i(rx + 2 + px2 * 10, ry + 2 + py2 * 9, 7, 6)
					m.decals.append({"kind": "pen", "x": pr.position.x, "y": pr.position.y, "w": pr.size.x, "h": pr.size.y})
					pens.append(Vector2(pr.position.x + pr.size.x * 0.5, pr.position.y + pr.size.y * 0.5) * T)
			m.decals.append({"kind": "boardwalk", "x": rx + 9, "y": ry + 2, "w": 2, "h": 25})       # the walkway between them
			for bw in 3:
				m.decals.append({"kind": "boardwalk", "x": rx + 5, "y": ry + 5 + bw * 9, "w": 11, "h": 1})
			info["pens"] = pens
		"rig":
			var rp := Rect2i(rx + 4, ry + 6, 12, 10)
			m.fill(rp.position.x, rp.position.y, rp.size.x, rp.size.y, GroundMap.T.BLOCK, 14)
			m.add_object({"kind": "tower_rig", "x": rp.position.x + 4, "y": rp.position.y + 3, "w": 3, "h": 3})
			m.add_object({"kind": "silo", "x": rp.position.x + 1, "y": rp.position.y + 6, "w": 3, "h": 3})
			m.add_object({"kind": "flare", "x": rp.position.x + 9, "y": rp.position.y + 7, "w": 2, "h": 2})
			info["flare"] = Vector2(rp.position.x + 10, rp.position.y + 9) * T + Vector2(0, -56 - 2 * T + 4)
			info["pens"] = [Vector2(rx + 14, ry + 22) * T, Vector2(rp.position.x + 6, rp.position.y + rp.size.y + 1) * T]
	m.econ = info


static func _free_any(m: GroundMap, x: int, y: int, w: int, h: int) -> bool:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			if xx >= m.w or yy >= m.h:
				return false
			for o in m.objects:
				if xx >= int(o["x"]) and xx < int(o["x"]) + int(o.get("w", 1)) and yy >= int(o["y"]) and yy < int(o["y"]) + int(o.get("h", 1)):
					return false
	return true


## 0.7.50.11: which architecture a house gets – by its power, and the world it stands on.
static func _arch(skey: String, bk: String, rng: RandomNumberGenerator, special: bool = false) -> String:
	var pool: Array = {"independent": ["prefab", "container", "quonset", "prefab"], "assembly": ["pitched", "dome", "pitched", "prefab"],
		"covenant": ["stone", "stone", "pitched"], "directorate": ["module", "dome", "module"]}.get(skey, ["prefab"])
	if special:
		pool = {"independent": ["prefab"], "assembly": ["pitched"], "covenant": ["stone"], "directorate": ["module"]}.get(skey, ["prefab"])
	if bk == "dunes" and rng.randf() < (0.4 if special else 0.6):
		return "adobe"
	if bk in ["ice", "rocks", "lava"] and not special and rng.randf() < 0.45:
		return ["dome", "quonset"][rng.randi() % 2]
	return String(pool[rng.randi() % pool.size()])


## A building object: its architecture, size, colours by kind and power.
static func _building(arch: String, x: int, y: int, w: int, h: int, storeys: int, skey: String, rng: RandomNumberGenerator, lamp: Color, door: int = -1) -> Dictionary:
	var roof: Color
	var wall: Color
	match arch:
		"pitched":
			roof = [Color(0.62, 0.32, 0.22), Color(0.42, 0.4, 0.45), Color(0.55, 0.42, 0.28)][rng.randi() % 3]
			wall = [Color(0.88, 0.84, 0.74), Color(0.62, 0.45, 0.3), Color(0.8, 0.82, 0.86)][rng.randi() % 3]
		"stone":
			roof = Color(0.3, 0.27, 0.3)
			wall = Color(0.58, 0.46, 0.4).lerp(Color(0.5, 0.48, 0.45), rng.randf())
		"adobe":
			roof = Color(0.85, 0.72, 0.52).lightened(rng.randf_range(-0.05, 0.05))
			wall = Color(0.82, 0.66, 0.46).lightened(rng.randf_range(-0.06, 0.04))
		"module":
			roof = Color(0.86, 0.88, 0.88)
			wall = Color(0.9, 0.92, 0.92)
		"dome":
			roof = Color(0.82, 0.84, 0.86) if rng.randf() < 0.6 else Color(0.62, 0.66, 0.72)
			wall = roof.darkened(0.1)
		"quonset":
			roof = [Color(0.55, 0.58, 0.55), Color(0.45, 0.5, 0.42), Color(0.6, 0.55, 0.45)][rng.randi() % 3]
			wall = roof.darkened(0.15)
		_:
			roof = [Color(0.45, 0.47, 0.52), Color(0.5, 0.36, 0.28), Color(0.35, 0.45, 0.5), Color(0.55, 0.55, 0.5)][rng.randi() % 4]
			wall = [Color(0.6, 0.62, 0.66), Color(0.55, 0.5, 0.42), Color(0.42, 0.5, 0.55)][rng.randi() % 3]
	var rise := 22 + rng.randi_range(0, 10) + (storeys - 1) * 14
	if arch == "dome":
		rise = 18 + w * 3
	var acc: Color = CityStyle.STYLES.get(skey, CityStyle.STYLES["independent"])["accent"]
	return {"kind": "building", "arch": arch, "x": x, "y": y, "w": w, "h": h, "rise": rise, "storeys": storeys, "col": roof, "col2": wall,
		"seed": rng.randi(), "lamp": lamp, "win": Color(1.0, 0.85, 0.55) if rng.randf() < 0.7 else Color(0.75, 0.88, 1.0), "acc": acc,
		"door": door if door >= 0 else rng.randi_range(8, maxi(9, w * 16 - 18))}


## 0.7.50.11: one thing of the world's edge – trees of several kinds and sizes, undergrowth, rock groups, dunes, ice.
static func _nature(kind: String, bk: String, col: Color, rng: RandomNumberGenerator, small: bool) -> Dictionary:
	var c := col.lightened(rng.randf_range(-0.07, 0.09))
	match kind:
		"tree":
			if small:
				return {"kind": "shrub", "w": 1 + rng.randi() % 2, "h": 1, "col": c.lightened(0.05), "seed": rng.randi()}
			var big := rng.randf() < 0.45
			var sp := "broad"
			if bk == "woods" and rng.randf() < 0.4:
				sp = "conifer"
			elif bk == "jungle" and rng.randf() < 0.15:
				sp = "palm"
			return {"kind": "tree", "w": 3 if big else 2, "h": 2, "rise": (58 if big else 44) + rng.randi_range(-4, 6), "species": sp,
				"vines": bk == "jungle" and rng.randf() < 0.6, "col": c, "seed": rng.randi()}
		"dune":
			if small or rng.randf() < 0.3:
				return {"kind": "rock", "w": 1 + rng.randi() % 2, "h": 1, "col": c.darkened(0.25), "seed": rng.randi()}
			return {"kind": "dune", "w": 3 + rng.randi() % 2, "h": 2, "col": c}
		"crystal":
			var roll := rng.randf()
			if small or roll < 0.3:
				return {"kind": "rock", "w": 1 + rng.randi() % 2, "h": 1, "col": Color(0.8, 0.86, 0.92), "seed": rng.randi()}
			if roll < 0.6:
				return {"kind": "dune", "w": 3, "h": 2, "col": Color(0.9, 0.94, 0.98)}                   # a snowdrift
			return {"kind": "crystal", "w": 2 + rng.randi() % 2, "h": 2, "col": c.lerp(Color(0.6, 0.85, 1.0), rng.randf() * 0.4), "seed": rng.randi()}
	# rocks (and lava rocks): groups of boulders of every size, moss on the wetter worlds
	if small:
		return {"kind": kind, "w": 1, "h": 1, "col": c, "seed": rng.randi(), "rise": 6}
	var rw := 2 + rng.randi() % 2
	return {"kind": kind, "w": rw, "h": 2, "col": c, "seed": rng.randi(), "rise": 8 + rng.randi() % 10, "moss": bk == "toxic"}


static func _free(m: GroundMap, x: int, y: int, w: int, h: int) -> bool:
	if x < 0 or y < 0 or x + w > m.w or y + h > m.h:
		return false
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			var t := m.t_at(xx, yy)
			if t != GroundMap.T.FLOOR or m.floor_kind[yy * m.w + xx] != 13:
				return false
	return true
