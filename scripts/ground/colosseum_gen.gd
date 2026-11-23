extends RefCounted
## Package 62a, part 1 (Luz): the plaza before the Colosseum, at the end of Line B. Built like the plaza of the
## Commercial District (the same way down to the metro, drawn fronts either side, the roofs of tall buildings in the
## south), with more marble and larger, grander figures: four colossi of the arena's champions on plinths, two
## greater ones at the grand stair, two long basins, bowls of holo fire, cypresses. West stands The Laurel, a very
## fine house of residences (apartments for sale later: its door is shut for now). North stands the Colosseum itself:
## a giant round of marble in four rings of arches, strips of neon running pulsing between them, a dome of holograms
## over the arena, a giant screen over its gate that announces the next fight. It is far larger than the picture: from
## the plaza you see its foot; the viewing scope shows the whole of it. The gate is still shut.
## No class_name: preload it.

const Gen = preload("res://scripts/ground/centauria_gen.gd")
const MuseumGen = preload("res://scripts/ground/museum_gen.gd")
const T := GroundMap.T
const TILE := GroundMap.TILE
const QW := 110                    # the map's width (tiles)
const QX := 28                     # the central plaza: its west edge …
const QCW := 54                    # … and its width
const MID := QX + QCW / 2          # its middle column
const NEON := [Color(1.0, 0.36, 0.66), Color(0.3, 0.9, 1.0), Color(1.0, 0.82, 0.25), Color(0.72, 0.5, 1.0)]
const MARBLE := Color(0.93, 0.91, 0.86)
const MARBLE_NIGHT := Color(0.4, 0.4, 0.52)

# ---- the Colosseum's measures (window px on the plaza: 1 unit = 1 px; its foot's middle at 0, 0; up = -y)
const R0 := 1500.0                 # half its width at the ground
const TH := 430.0                  # a ring's height
const TIERS := 4
const SETBACK := 55.0              # each ring stands this much further in
const ARCHES := 30                 # arches round the half you see
const SPAN := 1.47                 # … from -SPAN to SPAN (radians round the drum)
const CROWN := 110.0               # the wall over the last ring
const DOME := 820.0                # the holo dome's height over the crown
const GATE_W := 380.0
const GATE_H := 330.0
const SCREEN := Rect2(-430.0, -700.0, 860.0, 300.0)      # the screen over the gate

## The arena's fighters (made up until the fights are built): who the screen announces, whose colossi stand outside.
const FIGHTERS := [
	{"name": "VEX", "suit": "suit_mil_heavy", "seed": 11, "col": Color(1.0, 0.36, 0.66)},
	{"name": "OKONKWO", "suit": "suit_mil_light", "seed": 23, "col": Color(0.3, 0.9, 1.0)},
	{"name": "SABER NINE", "suit": "suit_mil_pathfinder", "seed": 37, "col": Color(1.0, 0.82, 0.25)},
	{"name": "MOTHER BRINE", "suit": "suit_mil_heavy", "seed": 41, "col": Color(0.55, 1.0, 0.6)},
	{"name": "DORN", "suit": "suit_mil_light", "seed": 53, "col": Color(1.0, 0.5, 0.25)},
	{"name": "PALE TESSA", "suit": "suit_survey", "seed": 67, "col": Color(0.9, 0.95, 1.0)},
	{"name": "KILN", "suit": "suit_work", "seed": 79, "col": Color(1.0, 0.3, 0.3)},
	{"name": "THE WIDOW", "suit": "suit_mil_light", "seed": 83, "col": Color(0.72, 0.5, 1.0)},
]
const MODES := ["KING OF THE COLOSSEUM", "TEAM DEATHMATCH", "SURVIVOR"]
const CARD := 12.0                 # seconds one announcement runs

static var _tex := {}


static func hsh(i: int, salt: int) -> float:
	return fposmod(sin(float(i) * 12.9898 + float(salt) * 78.233) * 43758.5453, 1.0)


## A fighter as a picture: in the suit's colours, or as a figure of marble.
static func fighter_tex(i: int, marble: bool) -> Texture2D:
	var key := "%d_%d" % [i, int(marble)]
	if _tex.has(key):
		return _tex[key]
	var f: Dictionary = FIGHTERS[posmod(i, FIGHTERS.size())]
	var rng := RandomNumberGenerator.new()
	rng.seed = 6200 + int(f["seed"])
	var look: Dictionary = ChibiArt.PilotArt.random_look(rng)
	look["suit"] = String(f["suit"])
	look["helmet"] = int(f["seed"]) % 2 == 1
	var tex: Texture2D = ChibiArt.frame(look, 0, 0)
	if marble:
		var img: Image = tex.get_image()
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				if c.a > 0.05:
					var l := pow(clampf(c.get_luminance() * 1.25, 0.0, 1.0), 0.75)
					img.set_pixel(x, y, Color(0.3, 0.3, 0.36).lerp(Color(0.98, 0.97, 0.94), l))
		tex = ImageTexture.create_from_image(img)
	_tex[key] = tex
	return tex


## Which two the screen announces at the clock `t`, and in what mode: [a, b, mode].
static func card(t: float) -> Array:
	var n := int(floor(t / CARD))
	var a := posmod(n * 3, FIGHTERS.size())
	var b := posmod(a + 1 + posmod(n, FIGHTERS.size() - 1), FIGHTERS.size())
	return [a, b, posmod(n, MODES.size())]


# ---------------------------------------------------------------- the map

static func build_plaza(_station: Dictionary) -> GroundMap:
	var W := QW
	var H := Gen.PH
	var top := Gen.P_TOP
	var m := GroundMap.new()
	MuseumGen._pal(m, {})
	m.pal["floor"] = Color(0.8, 0.78, 0.74)
	m.pal["floor2"] = Color(0.7, 0.68, 0.66)
	m.pal["wall"] = Color(0.6, 0.58, 0.6)
	m.pal["frame"] = Color(0.6, 0.58, 0.6)
	m.pal["accent"] = Color(1.0, 0.82, 0.35)
	m.style = "plaza"
	m.title = "Centauria"
	m.hull_top = -9999
	m.set_meta("few_guards", true)
	m.setup(W, H)
	var GOLD := Color(1.0, 0.82, 0.35)
	var WHITE := Color(0.95, 0.95, 1.0)
	var CYAN := Color(0.3, 0.9, 1.0)
	var PINK := Color(1.0, 0.36, 0.66)
	var PURPLE := Color(0.72, 0.5, 1.0)
	var cols := [GOLD, WHITE, CYAN, PINK, PURPLE]
	m.window_rect = Rect2(0, 0, W, top)
	m.set_meta("open_sky", true)
	m.fill(0, top, W, H - top, T.BLOCK, 30)
	var mid := MID
	var props: Array = []
	var marble: Array = []
	# ---- the central plaza: marble; the grand stair up to the gate in its middle, the podium either side of it
	m.fill(QX, top + 3, QCW, 25, T.FLOOR, 30)
	m.fill(mid - 12, top, 24, 3, T.FLOOR, 30)
	marble.append(Rect2(Vector2(QX, top + 3) * TILE, Vector2(QCW, 25) * TILE))
	m.set_meta("col_stair", Rect2(Vector2(mid - 12, top) * TILE, Vector2(24, 3) * TILE))
	m.set_meta("col_podium", [Rect2(Vector2(QX, top) * TILE, Vector2(mid - 12 - QX, 3) * TILE), Rect2(Vector2(mid + 12, top) * TILE, Vector2(QX + QCW - mid - 12, 3) * TILE)])
	m.zones.append({"rect": Rect2(Vector2(mid - 4, top) * TILE, Vector2(8, 1.4) * TILE), "kind": "museum_go", "id": "col_gate", "to": "zcolin", "at": "from_plaza",
		"title": "Through the great gate: the Colosseum", "col": GOLD, "sign": Vector2(-100, -100)})        # part 2: the gate stands open
	m.set_meta("from_gate", Vector2(mid, top + 4.0) * TILE)
	for lx in range(QX + 3, QX + QCW - 2, 6):
		m.lights.append({"pos": Vector2(lx, top + 3.2) * TILE, "r": 40.0, "col": NEON[(lx / 6) % NEON.size()], "a": 0.4})
	m.lights.append({"pos": Vector2(mid, top + 1.5) * TILE, "r": 150.0, "col": GOLD, "a": 0.4})
	# ---- the way down to the station, as on the other plaza (MetroFx draws it): Line B
	var kx := mid - 2
	var ky := top + 13
	m.fill(kx - 1, ky, 6, 1, T.BLOCK, 30)
	m.fill(kx - 1, ky + 1, 1, 2, T.BLOCK, 30)
	m.fill(kx + 4, ky + 1, 1, 2, T.BLOCK, 30)
	m.set_meta("ctr_metro", Vector2(kx - 1, ky) * TILE)
	m.set_meta("ctr_metro_line", "B")
	m.set_meta("ctr_metro_stop", 2)
	m.set_meta("ctr_metro_tick", "COLOSSEUM  ·  MIND THE STEPS  ·  LINE B TO CENTAURIA CENTRAL  ·  SIGN UP IN THE LOBBY  ·  ")
	_z(m, Rect2(kx, ky + 1.0, 4.0, 2.2), "ctr_down", "Stairs down: the station, Line B to Centauria Central", Color(0.35, 1.0, 0.55), {"stop": 2})
	m.lights.append({"pos": Vector2(kx + 2.0, ky + 2.4) * TILE, "r": 50.0, "col": GOLD, "a": 0.22})
	m.lights.append({"pos": Vector2(kx + 2.0, ky - 0.6) * TILE, "r": 50.0, "col": WHITE, "a": 0.3})
	m.set_meta("from_station", Vector2(kx + 2.0, ky + 4.2) * TILE)
	m.spawn = m.get_meta("from_station")
	m.set_meta("col_mosaic", Vector2(mid, top + 8.5) * TILE)           # a round mosaic between the stair and the metro
	# ---- two long basins
	var pools: Array = []
	for px in [QX + 4, QX + QCW - 16]:
		m.fill(px, top + 7, 12, 2, T.BLOCK, 30)
		pools.append(Rect2(Vector2(px, top + 7) * TILE, Vector2(12, 2) * TILE))
		m.lights.append({"pos": Vector2(px + 6, top + 8) * TILE, "r": 120.0, "col": CYAN, "a": 0.45})
	m.set_meta("col_pools", pools)
	# ---- the colossi: two great ones at the stair, four on the plaza
	var ci := 0
	for cp in [[mid - 17, top + 4, 3, 4.6], [mid + 14, top + 4, 3, 4.6], [QX + 7, top + 18, 2, 3.1], [QX + 17, top + 22, 2, 3.1], [QX + QCW - 19, top + 22, 2, 3.1],
			[QX + QCW - 9, top + 18, 2, 3.1]]:
		var cw := int(cp[2])
		m.fill(int(cp[0]), int(cp[1]), cw, 2, T.BLOCK, 30)
		props.append({"kind": "colossus", "pos": Vector2(int(cp[0]), int(cp[1]) + 2) * TILE, "w": cw * TILE, "who": ci, "k": float(cp[3]), "flip": ci % 2 == 1})
		m.lights.append({"pos": Vector2(cp[0] + cw * 0.5, cp[1] + 2.4) * TILE, "r": 70.0 if cw == 3 else 54.0, "col": FIGHTERS[ci]["col"], "a": 0.5})
		ci += 1
	# ---- bowls of holo fire, cypresses, banners of the champions
	for bz in [Vector2i(mid - 13, top + 3), Vector2i(mid + 12, top + 3), Vector2i(QX + 2, top + 12), Vector2i(QX + QCW - 3, top + 12), Vector2i(QX + 2, top + 25),
			Vector2i(QX + QCW - 3, top + 25)]:
		m.fill(bz.x, bz.y, 1, 1, T.BLOCK, 30)
		props.append({"kind": "brazier", "pos": Vector2(bz.x, bz.y + 1) * TILE, "w": TILE, "seed": bz.x + bz.y})
		m.lights.append({"pos": Vector2(bz.x + 0.5, bz.y + 0.5) * TILE, "r": 80.0, "col": Color(1.0, 0.6, 0.25), "a": 0.55, "flicker": true})
	for cy in [Vector2i(QX + 1, top + 5), Vector2i(QX + QCW - 2, top + 5), Vector2i(QX + 1, top + 16), Vector2i(QX + QCW - 2, top + 16), Vector2i(QX + 12, top + 26),
			Vector2i(QX + QCW - 13, top + 26), Vector2i(mid - 9, top + 26), Vector2i(mid + 8, top + 26)]:
		m.fill(cy.x, cy.y, 1, 1, T.BLOCK, 30)
		props.append({"kind": "cypress", "pos": Vector2(cy.x, cy.y + 1) * TILE, "w": TILE, "seed": cy.x * 3 + cy.y})
	var bi := 0
	for bn in [Vector2i(mid - 8, top + 4), Vector2i(mid + 7, top + 4), Vector2i(QX + 12, top + 12), Vector2i(QX + QCW - 13, top + 12)]:
		m.fill(bn.x, bn.y, 1, 1, T.BLOCK, 30)
		props.append({"kind": "banner", "pos": Vector2(bn.x, bn.y + 1) * TILE, "w": TILE, "who": 2 + bi})
		bi += 1
	# ---- benches, lamps, pillars of light, stalls with the arena's wares
	for bq in [Vector2i(mid - 11, top + 10), Vector2i(mid + 8, top + 10), Vector2i(mid - 7, top + 20), Vector2i(mid + 4, top + 20), Vector2i(QX + 6, top + 11),
			Vector2i(QX + QCW - 9, top + 11)]:
		m.add_object({"kind": "bench", "x": bq.x, "y": bq.y, "w": 3, "h": 1, "face": 0}, false)
	var li := 0
	for lp in [Vector2i(mid - 6, top + 5), Vector2i(mid + 5, top + 5), Vector2i(QX + 3, top + 20), Vector2i(QX + QCW - 4, top + 20), Vector2i(mid - 12, top + 18),
			Vector2i(mid + 11, top + 18), Vector2i(mid - 4, top + 24), Vector2i(mid + 3, top + 24)]:
		m.add_object({"kind": "holo_pillar" if li % 2 == 0 else "lamp_post", "x": lp.x, "y": lp.y, "w": 1, "h": 1, "col": cols[li % cols.size()]})
		m.lights.append({"pos": Vector2(lp.x + 0.5, lp.y) * TILE, "r": 70.0, "col": cols[li % cols.size()], "a": 0.5})
		li += 1
	var rng := RandomNumberGenerator.new()
	rng.seed = 6221
	for k in 3:
		for side in 2:
			var sx: int = (QX + 5 + k * 4) if side == 0 else (QX + QCW - 7 - k * 4)
			m.add_object({"kind": "stall", "x": sx, "y": top + 15, "w": 2, "h": 1, "col": cols[(k + side) % cols.size()]})
			m.people.append({"pos": Vector2(sx + 1.0, top + 14.8) * TILE, "dir": 0, "role": "keeper"})
			m.lights.append({"pos": Vector2(sx + 1.0, top + 15.6) * TILE, "r": 34.0, "col": cols[(k + side) % cols.size()], "a": 0.5})
	# the viewing scope: the whole of the Colosseum
	m.add_object({"kind": "scope", "x": mid, "y": top + 25, "w": 1, "h": 1, "col": GOLD})
	_z(m, Rect2(mid - 0.4, top + 24.0, 1.8, 2.4), "ctr_scope", "The viewing scope: the whole of the Colosseum", GOLD, {"what": "col"})
	m.lights.append({"pos": Vector2(mid + 0.5, top + 25.0) * TILE, "r": 30.0, "col": GOLD, "a": 0.5})
	# ---- west: The Laurel, a house of residences, on a marble forecourt (apartments later)
	var wx1 := QX
	m.fill(1, top + 9, wx1 - 1, 19, T.FLOOR, 30)
	marble.append(Rect2(Vector2(1, top + 9) * TILE, Vector2(wx1 - 1, 19) * TILE))
	Gen._prop(m, 2, wx1 - 4, top, 6, GOLD)
	m.face_deco.clear()
	var rdx := 2 + (wx1 - 4) / 2
	m.set_meta("col_res", {"x": 2.0 * TILE, "w": float(wx1 - 4) * TILE, "base": (top + 9.0) * TILE, "h": 560.0, "door": float(rdx) * TILE})
	_z(m, Rect2(rdx - 2, top + 9.0, 4.0, 1.5), "ctr_closed", "The Laurel: residences", GOLD, {"closed": "The Laurel. Apartments with a view of the Colosseum: for sale soon.", "id": "col_laurel"})
	m.people.append({"pos": Vector2(rdx + 2.6, top + 9.6) * TILE, "dir": 1, "role": "keeper"})        # the doorman
	m.lights.append({"pos": Vector2(rdx, top + 10.0) * TILE, "r": 120.0, "col": Color(1.0, 0.9, 0.7), "a": 0.55})
	for rc in [rdx - 5, rdx + 4]:
		m.fill(rc, top + 10, 1, 1, T.BLOCK, 30)
		props.append({"kind": "cypress", "pos": Vector2(rc, top + 11) * TILE, "w": TILE, "seed": rc})
	for wl in [Vector2i(4, top + 16), Vector2i(wx1 - 6, top + 16), Vector2i(4, top + 24), Vector2i(wx1 - 6, top + 24)]:
		m.add_object({"kind": "lamp_post", "x": wl.x, "y": wl.y, "w": 1, "h": 1, "col": GOLD})
		m.lights.append({"pos": Vector2(wl.x + 0.5, wl.y) * TILE, "r": 70.0, "col": GOLD, "a": 0.45})
	m.add_object({"kind": "fountain", "x": rdx - 2, "y": top + 18, "w": 4, "h": 2})
	m.fill(rdx - 2, top + 18, 4, 2, T.BLOCK)
	m.lights.append({"pos": Vector2(rdx, top + 18.5) * TILE, "r": 90.0, "col": CYAN, "a": 0.45})
	for wb in [Vector2i(rdx - 7, top + 20), Vector2i(rdx + 5, top + 20)]:
		m.add_object({"kind": "bench", "x": wb.x, "y": wb.y, "w": 3, "h": 1, "face": 0}, false)
	# ---- east: a row of houses (shops under awnings, as on the other plaza), a café before them
	var ex0 := QX + QCW
	m.fill(ex0, top + 9, W - 1 - ex0, 19, T.FLOOR, 30)
	marble.append(Rect2(Vector2(ex0, top + 9) * TILE, Vector2(W - 1 - ex0, 19) * TILE))
	Gen._prop(m, ex0 + 1, W - 3 - ex0, top, 6, PINK)
	m.set_meta("ctr_facades", [{"x": (ex0 + 1.0) * TILE, "w": float(W - 3 - ex0) * TILE, "base": (top + 9.0) * TILE, "h": 470.0, "col": PINK, "seed": 143, "kind": "prop"}])
	for ti in 6:
		var tx := ex0 + 4 + (ti % 3) * 7
		var ty := top + 14 + (ti / 3) * 5
		m.add_object({"kind": "round_table", "x": tx + 1, "y": ty, "w": 1, "h": 1})
		m.add_object({"kind": "parasol", "x": tx, "y": ty, "w": 3, "h": 1, "col": cols[ti % cols.size()]}, false)
		DeckGen._seat(m, "chair", tx, ty, 3, Color(0.75, 0.72, 0.68), rng, 0.6)
		DeckGen._seat(m, "chair", tx + 2, ty, 2, Color(0.75, 0.72, 0.68), rng, 0.6)
	for el in [Vector2i(ex0 + 2, top + 11), Vector2i(W - 4, top + 11), Vector2i(ex0 + 2, top + 25), Vector2i(W - 4, top + 25)]:
		m.add_object({"kind": "lamp_post", "x": el.x, "y": el.y, "w": 1, "h": 1, "col": cols[(el.x + el.y) % cols.size()]})
		m.lights.append({"pos": Vector2(el.x + 0.5, el.y) * TILE, "r": 70.0, "col": cols[(el.x + el.y) % cols.size()], "a": 0.45})
	m.set_meta("col_marble", marble)
	m.set_meta("col_props", props)
	m.set_meta("roof_mid", mid)
	m.set_meta("roof_closed", true)                    # (no street south here: the roofs stand in one row)
	m.set_meta("tourists", 30)
	DeckGen._seats(m)
	for gx in range(3, W - 3, 6):
		for gy in [top + 12, top + 17, top + 21, top + 26]:
			var wp := Vector2(gx, gy)
			if m.free_at(wp * TILE, 6.0):
				m.wander.append(wp * TILE)
	for gx2 in range(QX + 4, QX + QCW - 3, 6):
		if m.free_at(Vector2(gx2, top + 5) * TILE, 6.0):
			m.wander.append(Vector2(gx2, top + 5) * TILE)
	return m


static func _z(m: GroundMap, r: Rect2, kind: String, title: String, col: Color, extra: Dictionary = {}) -> void:
	Gen._zone(m, r, kind, title, col, extra)


# ---------------------------------------------------------------- the Colosseum, drawn

## The height of the whole building with its dome.
static func full_height() -> float:
	return TH * TIERS + CROWN + DOME


## The screen over the gate: the next fight. A fighter in a combat suit is pushed in at the top right, then "VS",
## then the other at the bottom left; their names, the mode, the hour.
static func draw_screen(ci: CanvasItem, r: Rect2, t: float) -> void:
	var font := ThemeDB.fallback_font
	var cd := card(t)
	var a: Dictionary = FIGHTERS[int(cd[0])]
	var b: Dictionary = FIGHTERS[int(cd[1])]
	var u := fposmod(t, CARD)
	var h := r.size.y
	ci.draw_rect(r.grow(14.0), Color(0.05, 0.04, 0.08))
	ci.draw_rect(r, Color(0.07, 0.03, 0.12))
	var ka := ease(clampf((u - 0.5) / 0.7, 0.0, 1.0), 0.3)
	var kb := ease(clampf((u - 2.6) / 0.7, 0.0, 1.0), 0.3)
	var kv := clampf((u - 1.7) / 0.35, 0.0, 1.0)
	# the two halves: a slanted band in each one's colour
	var ca: Color = a["col"]
	var cb: Color = b["col"]
	if ka > 0.0:
		ci.draw_colored_polygon(PackedVector2Array([Vector2(r.end.x - r.size.x * 0.62 * ka, r.position.y), Vector2(r.end.x, r.position.y), Vector2(r.end.x, r.position.y + h * 0.5),
			Vector2(r.end.x - r.size.x * 0.5 * ka, r.position.y + h * 0.5)]), Color(ca, 0.3))
	if kb > 0.0:
		ci.draw_colored_polygon(PackedVector2Array([Vector2(r.position.x, r.position.y + h * 0.5), Vector2(r.position.x + r.size.x * 0.5 * kb, r.position.y + h * 0.5),
			Vector2(r.position.x + r.size.x * 0.62 * kb, r.end.y), Vector2(r.position.x, r.end.y)]), Color(cb, 0.3))
	var ph := h * 0.62
	var ta := fighter_tex(int(cd[0]), false)
	var tb := fighter_tex(int(cd[1]), false)
	var pw := ph * float(ta.get_width()) / float(ta.get_height())
	if ka > 0.0:
		var ax := lerpf(r.end.x - pw, r.end.x - pw - r.size.x * 0.1, ka)
		ci.draw_texture_rect(ta, Rect2(ax, r.position.y + 4.0, pw, ph), false, Color(1, 1, 1, ka))
		ci.draw_string(font, Vector2(r.position.x + r.size.x * 0.4, r.position.y + h * 0.3), String(a["name"]), HORIZONTAL_ALIGNMENT_RIGHT, r.size.x * 0.34, int(h * 0.15), Color(ca.lightened(0.3), ka))
	if kb > 0.0:
		var bx := lerpf(r.position.x, r.position.x + r.size.x * 0.1, kb)
		ci.draw_texture_rect(tb, Rect2(bx, r.end.y - ph - 4.0, pw, ph), false, Color(1, 1, 1, kb))
		ci.draw_string(font, Vector2(r.position.x + r.size.x * 0.27, r.end.y - h * 0.14), String(b["name"]), HORIZONTAL_ALIGNMENT_LEFT, r.size.x * 0.4, int(h * 0.15), Color(cb.lightened(0.3), kb))
	if kv > 0.0:
		var vs := int(h * (0.3 + 0.2 * (1.0 - kv)))
		ci.draw_string(font, Vector2(r.position.x, r.position.y + h * 0.5 + vs * 0.36), "VS", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, vs, Color(1.0, 0.95, 0.7, kv))
	ci.draw_string(font, Vector2(r.position.x + 14.0, r.position.y + h * 0.13), "NEXT FIGHT", HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(h * 0.09), Color(1.0, 0.85, 0.4, 0.6 + 0.4 * absf(sin(t * 3.0))))
	if u > 4.0:
		ci.draw_string(font, Vector2(r.position.x, r.end.y - h * 0.03), "%s   ·   TONIGHT" % String(MODES[int(cd[2])]), HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 14.0, int(h * 0.075),
			Color(0.8, 0.95, 1.0, clampf(u - 4.0, 0.0, 1.0)))
	for sl in range(0, int(h), 6):
		ci.draw_rect(Rect2(r.position.x, r.position.y + sl, r.size.x, 1.5), Color(0, 0, 0, 0.18))
	ci.draw_rect(r, Color(NEON[int(t * 0.5) % NEON.size()], 0.9), false, 5.0)


## The Colosseum: the caller sets the transform (the foot's middle at the origin). Only what stands between y_lo and
## y_hi (heights over the ground) is drawn; `fine`: with the small things (figures in the arches, banners).
static func draw_colosseum(ci: CanvasItem, t: float, night: float, y_lo: float, y_hi: float, fine: bool) -> void:
	var nk := night > 0.5
	var marble := MARBLE_NIGHT if nk else MARBLE
	var top := TH * TIERS
	var rt := R0 - (TIERS - 1) * SETBACK
	# ---- the holo dome over the arena, the rim's far side
	if y_hi > top:
		var base := top + CROWN
		var rim := PackedVector2Array()
		for q in 33:
			var ang := PI + q * PI / 32.0
			rim.append(Vector2(cos(ang) * rt, -base + sin(ang) * rt * 0.1))
		rim.append(Vector2(rt, -base))
		ci.draw_colored_polygon(rim, marble.darkened(0.45))
		ci.draw_polyline(rim, Color(NEON[1], 0.8), 6.0)
		var pulse := 0.5 + 0.5 * sin(t * 1.3)
		for mer in 13:                                     # the dome's ribs of light
			var fx := sin(-1.45 + mer * 2.9 / 12.0)
			var pts := PackedVector2Array()
			for e in 13:
				var el := e * PI * 0.5 / 12.0
				pts.append(Vector2(fx * rt * cos(el), -base - DOME * sin(el)))
			ci.draw_polyline(pts, Color(NEON[1 if mer % 2 == 0 else 3], (0.3 if nk else 0.14) + 0.2 * pulse), 6.0)
		for par in 6:                                      # … and its rings, one of them rising
			var el2 := (par + fposmod(t * 0.12, 1.0)) * PI * 0.5 / 6.0
			var rr := rt * cos(el2)
			var hy := -base - DOME * sin(el2)
			var ring := PackedVector2Array()
			for q2 in 25:
				var an2 := q2 * PI / 24.0
				ring.append(Vector2(-cos(an2) * rr, hy + sin(an2) * rr * 0.1))
			ci.draw_polyline(ring, Color(NEON[3 if par % 2 == 0 else 1], (0.5 if nk else 0.22) * (1.0 - el2 / (PI * 0.5) * 0.6)), 6.0)
		# the arena's mark turning in the dome: a ring and a blade of light
		var mc := Vector2(0.0, -base - DOME * 0.42)
		var mw := 210.0 * absf(cos(t * 0.4))
		var mark := PackedVector2Array()
		for q3 in 25:
			mark.append(mc + Vector2(cos(q3 * TAU / 24.0) * mw, sin(q3 * TAU / 24.0) * 210.0))
		ci.draw_polyline(mark, Color(NEON[2], 0.35 if nk else 0.2), 10.0)
		ci.draw_line(mc + Vector2(0.0, 290.0), mc + Vector2(0.0, -290.0), Color(NEON[2], 0.4 if nk else 0.22), 12.0)
		ci.draw_line(mc + Vector2(-mw * 0.5, 150.0), mc + Vector2(mw * 0.5, 150.0), Color(NEON[2], 0.4 if nk else 0.22), 10.0)
	# ---- the rings of arches
	for tier in TIERS:
		var y0 := tier * TH
		var y1 := y0 + TH
		if y0 > y_hi or y1 < y_lo:
			continue
		var R := R0 - tier * SETBACK
		var ncol: Color = NEON[tier % NEON.size()]
		var dirn := 1.0 if tier % 2 == 0 else -1.0
		for a in ARCHES:
			var th0 := -SPAN + a * 2.0 * SPAN / ARCHES
			var th1 := th0 + 2.0 * SPAN / ARCHES
			var thm := (th0 + th1) * 0.5
			var x0 := R * sin(th0)
			var x1 := R * sin(th1)
			var w := x1 - x0
			var shade := 0.5 + 0.5 * cos(thm)
			var body := marble.darkened((1.0 - shade) * 0.6)
			ci.draw_rect(Rect2(x0, -y1, w + 0.6, TH), body)
			if w > 12.0:
				var ow := w * 0.56
				var ox := x0 + (w - ow) * 0.5
				var oh := TH * 0.6
				var ob := y0 + 46.0
				var lit := hsh(a + tier * 37, 5)
				var hole := Color(1.0, 0.72, 0.4).darkened(0.25 + 0.5 * lit) if nk else Color(0.2, 0.19, 0.25).lightened(0.1 * lit)
				hole = hole.darkened((1.0 - shade) * 0.5)
				ci.draw_rect(Rect2(ox, -(ob + oh - ow * 0.5), ow, oh - ow * 0.5), hole)
				ci.draw_circle(Vector2(ox + ow * 0.5, -(ob + oh - ow * 0.5)), ow * 0.5, hole)
				if fine and ow > 30.0:
					if tier > 0 and (a + tier) % 2 == 0:               # a figure of marble in the arch
						ci.draw_rect(Rect2(ox + ow * 0.36, -(ob + oh * 0.5), ow * 0.28, oh * 0.5), body.lightened(0.12))
						ci.draw_circle(Vector2(ox + ow * 0.5, -(ob + oh * 0.56)), ow * 0.13, body.lightened(0.12))
					elif tier == 0 and a % 3 == 1:                      # a champion's banner
						var bc: Color = FIGHTERS[a % FIGHTERS.size()]["col"]
						ci.draw_rect(Rect2(ox + ow * 0.2, -(ob + oh * 0.82), ow * 0.6, oh * 0.6), Color(bc.darkened(0.25), 0.95))
						ci.draw_rect(Rect2(ox + ow * 0.2, -(ob + oh * 0.82), ow * 0.6, 5.0), Color(1.0, 0.85, 0.4))
				# the arch's edge, a thin line of light
				ci.draw_rect(Rect2(ox - 3.0, -(ob + oh - ow * 0.5), 3.0, oh - ow * 0.5), Color(ncol, 0.25 + 0.3 * shade))
				ci.draw_rect(Rect2(ox + ow, -(ob + oh - ow * 0.5), 3.0, oh - ow * 0.5), Color(ncol, 0.25 + 0.3 * shade))
			if a % 3 == 0 and w > 8.0:                                 # a strip of neon up the pier, its light climbing
				for sg in 6:
					var up := fposmod(sg / 6.0 - t * 0.45 + a * 0.13, 1.0)
					ci.draw_rect(Rect2(x0 - 3.0, -(y0 + (sg + 1) * TH / 6.0), 6.0, TH / 6.0 - 3.0), Color(NEON[(a / 3 + tier) % NEON.size()], (0.25 + 0.75 * up * up) * (0.4 + 0.6 * shade)))
			# the cornice and the strip of neon running round over it, pulsing
			ci.draw_rect(Rect2(x0, -y1, w + 0.6, 26.0), body.lightened(0.08))
			var run := pow(maxf(0.0, sin(thm * 7.0 - t * (1.5 + tier * 0.35) * dirn + tier)), 2.0)
			ci.draw_rect(Rect2(x0, -y1 + 26.0, w + 0.6, 22.0), Color(ncol, (0.45 + 0.55 * run) * (0.5 + 0.5 * shade)))
			ci.draw_rect(Rect2(x0, -y1 + 33.0, w + 0.6, 8.0), Color(ncol.lightened(0.5), run * (0.5 + 0.5 * shade)))
			ci.draw_rect(Rect2(x0, -y0 - 12.0, w + 0.6, 12.0), body.darkened(0.12))
	# ---- the crown: a wall, masts with floodlights
	if y_hi > top:
		for a2 in ARCHES:
			var c0 := -SPAN + a2 * 2.0 * SPAN / ARCHES
			var cx0 := rt * sin(c0)
			var cx1 := rt * sin(c0 + 2.0 * SPAN / ARCHES)
			var sh2 := 0.5 + 0.5 * cos(c0 + SPAN / ARCHES)
			ci.draw_rect(Rect2(cx0, -(top + CROWN), cx1 - cx0 + 0.6, CROWN), marble.darkened((1.0 - sh2) * 0.6).lightened(0.05))
			ci.draw_rect(Rect2(cx0, -(top + CROWN), cx1 - cx0 + 0.6, 10.0), Color(NEON[2], 0.5 + 0.5 * absf(sin(t * 2.0 + a2 * 0.4))))
			if a2 % 5 == 2:
				var mx := (cx0 + cx1) * 0.5
				ci.draw_rect(Rect2(mx - 5.0, -(top + CROWN + 170.0), 10.0, 170.0), marble.darkened(0.3))
				ci.draw_rect(Rect2(mx - 34.0, -(top + CROWN + 200.0), 68.0, 34.0), Color(1.0, 0.97, 0.85) if nk else Color(0.75, 0.75, 0.8))
				if nk:
					ci.draw_circle(Vector2(mx, -(top + CROWN + 184.0)), 60.0, Color(1.0, 0.95, 0.8, 0.14))
	# ---- the gate and the screen over it
	if y_lo < -SCREEN.position.y:
		var gr := Rect2(-GATE_W * 0.5, -GATE_H, GATE_W, GATE_H)
		ci.draw_rect(gr.grow_individual(46.0, 46.0, 46.0, 0.0), marble.lightened(0.04))
		# (part 2) the gate stands open: the hall's light, the red carpet running in, the doors of bronze swung aside
		ci.draw_rect(gr, Color(0.22, 0.16, 0.12))
		for dp in 5:
			ci.draw_rect(Rect2(-GATE_W * 0.32 + dp * 16.0, -GATE_H + 30.0 + dp * 26.0, GATE_W * 0.64 - dp * 32.0, GATE_H - 30.0 - dp * 26.0), Color(1.0, 0.86, 0.6, 0.16))
		ci.draw_rect(Rect2(-34.0, -GATE_H * 0.5, 68.0, GATE_H * 0.3), Color(0.7, 0.9, 1.0, 0.6))      # (far off: the gate to the stands)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(-70.0, 0.0), Vector2(70.0, 0.0), Vector2(30.0, -GATE_H * 0.22), Vector2(-30.0, -GATE_H * 0.22)]), Color(0.66, 0.1, 0.18))
		for side in 2:
			var dx0 := gr.position.x if side == 0 else gr.end.x - GATE_W * 0.2
			ci.draw_rect(Rect2(dx0, gr.position.y, GATE_W * 0.2, GATE_H), Color(0.16, 0.11, 0.08))
			for dl in 8:                                   # the doors: bands, studs of light
				ci.draw_rect(Rect2(dx0, gr.position.y + 14.0 + dl * 40.0, GATE_W * 0.2, 5.0), Color(0.55, 0.4, 0.2))
				ci.draw_rect(Rect2(dx0 + GATE_W * 0.1 - 3.0, gr.position.y + 30.0 + dl * 40.0, 6.0, 6.0), Color(1.0, 0.82, 0.35, 0.4 + 0.6 * absf(sin(t * 1.5 + dl + side))))
		var gp := 0.6 + 0.4 * absf(sin(t * 1.8))
		ci.draw_rect(gr, Color(1.0, 0.82, 0.35, gp), false, 8.0)
		ci.draw_rect(gr.grow_individual(46.0, 46.0, 46.0, 0.0), Color(NEON[0], 0.5 * gp), false, 5.0)
		ci.draw_rect(Rect2(-190.0, -GATE_H - 40.0, 380.0, 36.0), Color(0.08, 0.06, 0.08))
		ci.draw_string(ThemeDB.fallback_font, Vector2(-300.0, -GATE_H - 12.0), "C O L O S S E U M", HORIZONTAL_ALIGNMENT_CENTER, 600.0, 30, Color(1.0, 0.88, 0.5))
		draw_screen(ci, SCREEN, t)


# ---------------------------------------------------------------- the nodes

## What stands north of the plaza (window px): the sky with Lapis, the city's skyline, and right behind the plaza the
## Colosseum: only its foot fits on the screen. Everything shifts a little as you walk.
class ColSky extends Node2D:
	const CG = preload("res://scripts/ground/colosseum_gen.gd")
	const Gen = preload("res://scripts/ground/centauria_gen.gd")
	var size := Vector2.ZERO
	var view = null
	var night := 0.0
	var _t := 0.0

	func setup(p_size: Vector2, p_view, p_night: float) -> void:
		size = p_size
		view = p_view
		night = p_night

	func _process(dt: float) -> void:
		_t += dt
		queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var mid := float(CG.MID) * GroundMap.TILE * GroundMap.SCALE
		var cam := mid
		if view != null and is_instance_valid(view) and (view._cam_c as Vector2) != Vector2.INF:
			cam = (view._cam_c as Vector2).x
		var d := cam - mid
		Gen.draw_sky(self, Rect2(0, 0, w, h), night, mid - 1500.0 + d * 0.92, h - 900.0, 620.0, _t)
		Gen.draw_skyline(self, w, h, d, night, 0.3)
		draw_set_transform(Vector2(mid + d * 0.04, h), 0.0, Vector2.ONE)
		CG.draw_colosseum(self, GameState.play_time, night, 0.0, h + 60.0, true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## (Luz) through the viewing scope on the plaza: the view pulls back until the whole of the Colosseum stands in it,
## its dome of holograms over it, the city small beside it, Lapis behind; traffic in the air, at night beams of
## light from its crown and fireworks. Esc (or a click) puts the scope down.
class ColScope extends Control:
	const CG = preload("res://scripts/ground/colosseum_gen.gd")
	const Gen = preload("res://scripts/ground/centauria_gen.gd")
	const PULL := 4.5
	var night := 0.0
	var _t := 0.0
	var _sparks: Array = []

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP
		clip_contents = true

	func _process(dt: float) -> void:
		_t += dt
		if night > 0.5 and randf() < dt * 1.1:
			_sparks.append({"x": randf_range(-2400.0, 2400.0), "y": randf_range(2200.0, 3600.0), "t": 0.0, "col": CG.NEON[randi() % 4]})
		for s in _sparks:
			s["t"] = float(s["t"]) + dt
		_sparks = _sparks.filter(func(s): return float(s["t"]) < 1.8)
		queue_redraw()

	## How far the view has pulled back (0 = as from the plaza, 1 = the whole Colosseum).
	func pulled() -> float:
		return ease(clampf(_t / PULL, 0.0, 1.0), -2.2)

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var k := pulled()
		var s_far := minf(h * 0.8 / CG.full_height(), w * 0.86 / (CG.R0 * 2.0))
		var sc := lerpf(1.0, s_far, k)
		var org := Vector2(w * 0.5, lerpf(h * 0.9, h * 0.9, k))
		Gen.draw_sky(self, Rect2(0, 0, w, h), night, lerpf(w * 0.5 - 1500.0, w * 0.2, k), lerpf(h * 0.9 - 900.0, h * 0.3, k), lerpf(620.0, h * 0.22, k), _t, true)
		draw_set_transform(org, 0.0, Vector2(sc, sc))
		for layer in 2:                                    # the city round it, small against it
			var bw: float = [130.0, 190.0][layer]
			var shade: float = [0.24, 0.16][layer]
			for b in range(-34, 34):
				var bx: float = b * bw
				if absf(bx) < CG.R0 * 0.94:
					continue
				var bh: float = 200.0 + CG.hsh(b, layer * 7 + 2) * float([900.0, 640.0][layer])
				var tint: Color = CG.NEON[int(CG.hsh(b, layer + 11) * 4.0) % 4]
				var body := Color(shade, shade, shade + 0.08).lerp(tint, 0.18)
				if night > 0.5:
					body = body.darkened(0.45)
				draw_rect(Rect2(bx, -bh, bw - 14.0, bh), body)
				for r2 in int(bh / 60.0):
					if CG.hsh(b * 31 + r2, layer + 40) < (0.6 if night > 0.5 else 0.3):
						draw_rect(Rect2(bx + 10.0, -bh + 14.0 + r2 * 60.0, bw - 34.0, 22.0), Color(tint if r2 % 3 == 0 else Color(1.0, 0.92, 0.7), 0.8 if night > 0.5 else 0.4))
		if night > 0.5:                                    # beams of light from the crown
			for lz in 6:
				var p0 := Vector2((lz - 2.5) * 460.0, -(CG.TH * CG.TIERS + CG.CROWN))
				var ang := -PI * 0.5 + sin(_t * (0.3 + lz * 0.09) + lz * 1.7) * 0.7
				draw_line(p0, p0 + Vector2.from_angle(ang) * 2600.0, Color(CG.NEON[lz % 4], 0.22), 30.0)
		CG.draw_colosseum(self, GameState.play_time, night, 0.0, (org.y / sc) + 100.0, sc > 0.45)
		for a in 8:                                        # traffic in the air
			var dir := 1.0 if a % 2 == 0 else -1.0
			var ax := (fposmod(a * 733.0 + _t * (150.0 + a * 21.0), 8000.0) - 4000.0) * dir
			var ay := -500.0 - a * 380.0
			draw_rect(Rect2(ax - dir * 70.0, ay, 70.0, 6.0), Color(1.0, 0.9, 0.6, 0.35))
			draw_circle(Vector2(ax, ay + 3.0), 12.0, Color(1.0, 0.95, 0.8))
		for s in _sparks:
			var st2 := float(s["t"])
			var rr := 40.0 + st2 * 280.0
			for q2 in 16:
				draw_circle(Vector2(float(s["x"]), -float(s["y"])) + Vector2.from_angle(q2 * TAU / 16.0) * rr + Vector2(0.0, st2 * st2 * 60.0), 15.0, Color(s["col"], clampf(1.0 - st2 / 1.8, 0.0, 1.0)))
		# the plaza at its feet: marble, the lights of the crowd
		draw_rect(Rect2(-6000.0, 0.0, 12000.0, 2000.0), Color(0.3, 0.3, 0.38) if night > 0.5 else Color(0.8, 0.78, 0.74))
		for pl in 40:
			draw_circle(Vector2(-1500.0 + CG.hsh(pl, 8) * 3000.0, 40.0 + CG.hsh(pl, 9) * 300.0), 13.0, Color(CG.NEON[pl % 4], 0.8))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_rect(Rect2(0, 0, w, h), Color(0, 0, 0, 0.9), false, 36.0)
		draw_string(ThemeDB.fallback_font, Vector2(0, h - 34.0), "The Colosseum   ·   Esc: put the scope down", HORIZONTAL_ALIGNMENT_CENTER, w, 20, Color(0.8, 0.9, 1.0))


## The plaza's own things, drawn (art px). "floor" lies under the people: the marble in great slabs with joints of
## gold, the round mosaic, the two basins with their jets, the grand stair, the podium beside it. "res": the front of
## The Laurel, storey by storey, under the people too. "prop" stands among them, drawn from its own line upward: a
## colossus on its plinth, a bowl of holo fire, a cypress, a champion's banner.
class ColFx extends Node2D:
	const CG = preload("res://scripts/ground/colosseum_gen.gd")
	var part := "floor"
	var data := {}
	var map: GroundMap = null
	var night := 0.0
	var open := 0.0                  # (the lobby) how far the wall of light before the fighters' area has gone out …
	var gate := 0.0                  # … and how far the fighters' gate stands open
	var _t := 0.0
	var _acc := 0.0

	func _process(dt: float) -> void:
		_t += dt
		_acc += dt
		if _acc > (0.06 if part != "res" else 0.25):
			_acc = 0.0
			queue_redraw()

	func _draw() -> void:
		match part:
			"floor":
				_floor()
			"res":
				_res()
			"hall_floor":
				_hall_floor()
			"hall_wall":
				_hall_wall()
			"st_floor":
				_st_floor()
			"ar_floor":
				CG.draw_arena_ground(self, GameState.play_time)
			_:
				_prop()

	func _marble() -> Color:
		return Color(0.42, 0.42, 0.54) if night > 0.5 else Color(0.9, 0.88, 0.83)

	func _floor() -> void:
		var nk := night > 0.5
		var mc := _marble()
		var gold := Color(1.0, 0.82, 0.35, 0.75 if nk else 0.5)
		for r in map.get_meta("col_marble", []):
			var rr: Rect2 = r
			draw_rect(rr, mc)
			for gx in range(int(rr.position.x), int(rr.end.x), 48):          # slabs of three tiles, every other one a shade darker
				for gy in range(int(rr.position.y), int(rr.end.y), 48):
					var k := CG.hsh(gx / 48 + gy / 48 * 57, 3)
					if k > 0.45:
						draw_rect(Rect2(gx, gy, minf(48.0, rr.end.x - gx), minf(48.0, rr.end.y - gy)), mc.darkened(0.05 + 0.07 * k))
					if k < 0.3:                                             # a vein
						draw_line(Vector2(gx + 6.0, gy + 10.0 + k * 60.0), Vector2(minf(gx + 40.0, rr.end.x), gy + 30.0 - k * 40.0), mc.darkened(0.2), 1.0)
			for gx2 in range(int(rr.position.x), int(rr.end.x) + 1, 48):
				draw_rect(Rect2(gx2, rr.position.y, 1.0, rr.size.y), gold)
			for gy2 in range(int(rr.position.y), int(rr.end.y) + 1, 48):
				draw_rect(Rect2(rr.position.x, gy2, rr.size.x, 1.0), gold)
		# the mosaic: rings, rays, the arena's mark
		var c: Vector2 = map.get_meta("col_mosaic", Vector2.ZERO)
		draw_set_transform(c, 0.0, Vector2(1.0, 0.7))
		draw_circle(Vector2.ZERO, 52.0, mc.lightened(0.1))
		for q in 16:
			draw_colored_polygon(PackedVector2Array([Vector2.from_angle(q * TAU / 16.0) * 20.0, Vector2.from_angle((q + 0.5) * TAU / 16.0) * 48.0, Vector2.from_angle((q + 1.0) * TAU / 16.0) * 20.0]),
				[Color(0.65, 0.2, 0.3), Color(0.2, 0.4, 0.6)][q % 2].lerp(mc, 0.35))
		draw_arc(Vector2.ZERO, 52.0, 0.0, TAU, 48, Color(1.0, 0.82, 0.35), 2.0)
		draw_arc(Vector2.ZERO, 20.0, 0.0, TAU, 32, Color(1.0, 0.82, 0.35), 1.5)
		draw_arc(Vector2.ZERO, 58.0, 0.0, TAU, 48, Color(CG.NEON[int(_t * 0.7) % 4], 0.5 + 0.4 * absf(sin(_t * 2.0))), 1.5)
		draw_circle(Vector2.ZERO, 18.0, mc.darkened(0.25))
		draw_arc(Vector2.ZERO, 10.0, 0.0, TAU, 20, Color(1.0, 0.82, 0.35), 2.0)
		draw_line(Vector2(0.0, 14.0), Vector2(0.0, -14.0), Color(1.0, 0.9, 0.6), 2.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# the basins: a rim of marble, water, jets in a row
		for p in map.get_meta("col_pools", []):
			var pr: Rect2 = p
			draw_rect(Rect2(pr.position.x + 2.0, pr.end.y, pr.size.x, 3.0), Color(0, 0, 0, 0.25))
			draw_rect(pr, mc.lightened(0.12))
			draw_rect(pr.grow(-3.0), Color(0.1, 0.3, 0.5) if nk else Color(0.25, 0.55, 0.75))
			for wv in 10:
				var wx := pr.position.x + 5.0 + fposmod(wv * 23.0 + _t * (5.0 + wv % 3), pr.size.x - 16.0)
				draw_rect(Rect2(wx, pr.position.y + 6.0 + (wv * 7) % int(pr.size.y - 12.0), 6.0, 1.0), Color(0.8, 0.95, 1.0, 0.45))
			for j in 6:
				var jx := pr.position.x + 16.0 + j * (pr.size.x - 32.0) / 5.0
				var jh := 12.0 + 8.0 * absf(sin(_t * 1.6 + j * 0.9))
				draw_rect(Rect2(jx - 0.5, pr.get_center().y - jh, 1.5, jh), Color(0.85, 0.97, 1.0, 0.85))
				draw_circle(Vector2(jx, pr.get_center().y - jh), 2.0, Color(CG.NEON[(j + int(_t)) % 4], 0.7) if nk else Color(0.9, 0.98, 1.0, 0.8))
				draw_arc(Vector2(jx, pr.get_center().y), 3.0 + fposmod(_t * 3.0 + j, 3.0), 0.0, TAU, 10, Color(0.85, 0.97, 1.0, 0.3), 1.0)
			draw_rect(pr.grow(-3.0), Color(0.3, 0.9, 1.0, 0.7 if nk else 0.3), false, 1.0)
		# the podium beside the stair: its face, a strip of light, a balustrade
		for pd in map.get_meta("col_podium", []):
			var dr: Rect2 = pd
			draw_rect(dr, mc.lightened(0.06))
			draw_rect(Rect2(dr.position.x, dr.end.y - 16.0, dr.size.x, 16.0), mc.darkened(0.2))
			draw_rect(Rect2(dr.position.x, dr.end.y - 9.0, dr.size.x, 2.0), Color(CG.NEON[2], 0.6 + 0.4 * absf(sin(_t * 1.4))))
			for bx in range(int(dr.position.x) + 4, int(dr.end.x) - 2, 8):
				draw_rect(Rect2(bx, dr.end.y - 26.0, 2.0, 10.0), mc.lightened(0.14))
			draw_rect(Rect2(dr.position.x, dr.end.y - 28.0, dr.size.x, 2.5), mc.lightened(0.18))
		# the grand stair: step after step, a line of light under every lip, cheeks either side
		var sr: Rect2 = map.get_meta("col_stair", Rect2())
		draw_rect(sr, mc.darkened(0.08))
		var n := 9
		for s in n:
			var sy := sr.position.y + s * sr.size.y / n
			draw_rect(Rect2(sr.position.x, sy, sr.size.x, sr.size.y / n - 1.5), mc.lightened(0.1 - s * 0.012))
			var run := 0.4 + 0.6 * absf(sin(_t * 2.0 - s * 0.6))
			draw_rect(Rect2(sr.position.x, sy + sr.size.y / n - 1.5, sr.size.x, 1.5), Color(CG.NEON[0 if s % 2 == 0 else 1], (0.9 if nk else 0.5) * run))
		for side in 2:
			var chx := sr.position.x - 4.0 if side == 0 else sr.end.x
			draw_rect(Rect2(chx, sr.position.y, 4.0, sr.size.y), mc.darkened(0.25))
			draw_rect(Rect2(chx + 1.0, sr.position.y, 2.0, sr.size.y), Color(CG.NEON[2], 0.8))

	## The Laurel: a tall, fine house of residences. Marble and glass, fins of gold, balconies with green, a lobby
	## full of warm light under a canopy.
	func _res() -> void:
		var font := ThemeDB.fallback_font
		var nk := night > 0.5
		var x := float(data["x"])
		var w := float(data["w"])
		var base := float(data["base"])
		var h := float(data["h"])
		var body := Color(0.44, 0.44, 0.56) if nk else Color(0.92, 0.9, 0.86)
		var gold := Color(1.0, 0.82, 0.35)
		draw_rect(Rect2(x, base - h, w, h), body)
		var fh := 22.0
		var floors := int((h - 46.0) / fh)
		for f in floors:
			var fy := base - 46.0 - (f + 1) * fh
			draw_rect(Rect2(x + 4.0, fy + 3.0, w - 8.0, fh - 9.0), Color(0.08, 0.1, 0.18) if nk else Color(0.3, 0.42, 0.55))
			var bays := int((w - 8.0) / 20.0)
			for b in bays:
				var bx := x + 4.0 + b * (w - 8.0) / bays
				var bw := (w - 8.0) / bays
				var k := CG.hsh(f * 31 + b, 7)
				if nk and k < 0.55:
					draw_rect(Rect2(bx + 1.5, fy + 4.0, bw - 3.0, fh - 11.0), Color(1.0, 0.86, 0.6, 0.55 + 0.4 * k) if k > 0.12 else Color(0.5, 0.8, 1.0, 0.6))
				elif not nk and k < 0.3:
					draw_rect(Rect2(bx + 1.5, fy + 4.0, bw - 3.0, fh - 11.0), Color(0.75, 0.88, 1.0, 0.35))
				draw_rect(Rect2(bx - 0.5, fy + 3.0, 1.0, fh - 9.0), body.darkened(0.1))
				if (f + b) % 3 == 0:                                   # a balcony: glass, a planter with green
					draw_rect(Rect2(bx + 1.0, fy + fh - 10.0, bw - 2.0, 5.0), Color(0.7, 0.9, 1.0, 0.35))
					draw_rect(Rect2(bx + 1.0, fy + fh - 10.0, bw - 2.0, 1.0), Color(0.9, 0.97, 1.0, 0.8))
					draw_rect(Rect2(bx + 3.0, fy + fh - 13.0, 5.0, 3.0), Color(0.25, 0.6, 0.3))
			draw_rect(Rect2(x, fy + fh - 5.0, w, 4.0), body.lightened(0.1))
			if f % 5 == 4:                                         # a band of gold every fifth floor
				draw_rect(Rect2(x, fy + fh - 2.0, w, 1.5), Color(gold, 0.5 + 0.5 * absf(sin(_t * 0.8 + f * 0.35))))
		for fin in 2:                                              # a fin of gold up either edge
			var fx := x + fin * (w - 3.0)
			draw_rect(Rect2(fx, base - h, 3.0, h - 46.0), gold.darkened(0.15 if nk else 0.0))
		# the lobby: glass, warm light, plants; the doors; the canopy with its name
		var dx := float(data["door"])
		draw_rect(Rect2(x, base - 46.0, w, 46.0), body.darkened(0.1))
		draw_rect(Rect2(x + 6.0, base - 40.0, w - 12.0, 38.0), Color(1.0, 0.85, 0.6, 0.8) if nk else Color(0.55, 0.62, 0.7))
		for lp in int((w - 12.0) / 26.0):
			draw_rect(Rect2(x + 6.0 + lp * 26.0, base - 40.0, 2.0, 38.0), body.darkened(0.2))
			draw_circle(Vector2(x + 19.0 + lp * 26.0, base - 31.0), 2.5, Color(1.0, 0.95, 0.8, 0.9 if nk else 0.5))
		draw_rect(Rect2(dx - 18.0, base - 34.0, 36.0, 34.0), Color(0.12, 0.1, 0.1))
		draw_rect(Rect2(dx - 16.0, base - 32.0, 15.0, 32.0), Color(0.85, 0.75, 0.55, 0.85) if nk else Color(0.5, 0.56, 0.62))
		draw_rect(Rect2(dx + 1.0, base - 32.0, 15.0, 32.0), Color(0.85, 0.75, 0.55, 0.85) if nk else Color(0.5, 0.56, 0.62))
		draw_rect(Rect2(dx - 18.0, base - 34.0, 36.0, 34.0), gold, false, 1.5)
		draw_rect(Rect2(dx - 44.0, base - 52.0, 88.0, 12.0), Color(0.07, 0.06, 0.08))
		draw_rect(Rect2(dx - 44.0, base - 52.0, 88.0, 12.0), Color(gold, 0.7 + 0.3 * absf(sin(_t * 1.2))), false, 1.0)
		draw_string(font, Vector2(dx - 44.0, base - 43.0), "THE LAUREL", HORIZONTAL_ALIGNMENT_CENTER, 88.0, 8, Color(1.0, 0.9, 0.6))
		draw_string(font, Vector2(dx - 44.0, base - 55.0), "RESIDENCES", HORIZONTAL_ALIGNMENT_CENTER, 88.0, 5, Color(0.9, 0.92, 1.0, 0.8))
		draw_rect(Rect2(dx - 12.0, base - 2.0, 24.0, 2.0), Color(0.62, 0.1, 0.22))           # a runner of red before the doors

	# ---- package 62a, part 2: the lobby and the stands
	func _marble_rect(rr: Rect2, mc: Color, gold: Color) -> void:
		draw_rect(rr, mc)
		for gx in range(int(rr.position.x), int(rr.end.x), 48):
			for gy in range(int(rr.position.y), int(rr.end.y), 48):
				var k := CG.hsh(gx / 48 + gy / 48 * 57, 3)
				if k > 0.45:
					draw_rect(Rect2(gx, gy, minf(48.0, rr.end.x - gx), minf(48.0, rr.end.y - gy)), mc.darkened(0.05 + 0.07 * k))
		for gx2 in range(int(rr.position.x), int(rr.end.x) + 1, 48):
			draw_rect(Rect2(gx2, rr.position.y, 1.0, rr.size.y), gold)
		for gy2 in range(int(rr.position.y), int(rr.end.y) + 1, 48):
			draw_rect(Rect2(rr.position.x, gy2, rr.size.x, 1.0), gold)

	## The lobby's floor: marble, the red carpet with its cords, the fighters' area a shade bluer.
	func _hall_floor() -> void:
		var mc := Color(0.82, 0.8, 0.76)
		var gold := Color(1.0, 0.82, 0.35, 0.5)
		var fl := float(CG.L_F0) * 16.0
		_marble_rect(Rect2(16.0, fl, (CG.LW - 2) * 16.0, (CG.L_F1 - CG.L_F0 + 1) * 16.0), mc, gold)
		var ar := Rect2(CG.REG_X * 16.0, fl, CG.REG_W * 16.0, 7.0 * 16.0)
		draw_rect(ar, Color(0.3, 0.6, 0.9, 0.16))
		draw_rect(ar, Color(0.3, 0.9, 1.0, 0.5 + 0.3 * sin(_t * 1.5)), false, 1.0)
		var cr: Rect2 = map.get_meta("col_carpet", Rect2())
		draw_rect(cr, Color(0.62, 0.1, 0.18))
		draw_rect(Rect2(cr.position.x + 3.0, cr.position.y, cr.size.x - 6.0, cr.size.y), Color(0.7, 0.13, 0.22))
		for side in 2:
			var ex := cr.position.x + 1.0 if side == 0 else cr.end.x - 2.0
			draw_rect(Rect2(ex, cr.position.y, 1.0, cr.size.y), Color(1.0, 0.82, 0.35))
			var px := cr.position.x - 5.0 if side == 0 else cr.end.x + 4.0
			var y := cr.position.y + 24.0
			while y < fl + (CG.L_F1 - CG.L_F0) * 16.0:              # posts of gold, a cord of velvet from one to the next
				draw_rect(Rect2(px - 0.5, y, 2.0, 30.0), Color(0.5, 0.08, 0.16))
				draw_circle(Vector2(px + 0.5, y), 2.2, Color(1.0, 0.82, 0.35))
				draw_circle(Vector2(px + 0.5, y), 1.0, Color(1.0, 0.95, 0.7))
				y += 32.0

	## The lobby's north wall: marble pilasters and niches, strips of neon running, the open gate to the stands with
	## the screen over it, the ranking, the fighters' gate (`gate`: how far it stands open).
	func _hall_wall() -> void:
		var font := ThemeDB.fallback_font
		var W := float(CG.LW) * 16.0
		var fl := float(CG.L_F0) * 16.0
		var mc := Color(0.84, 0.82, 0.78)
		var mid := float(CG.LMID) * 16.0
		draw_rect(Rect2(16.0, 0.0, W - 32.0, fl), mc.darkened(0.14))
		for i in range(1, CG.LW - 1, 3):
			var x := i * 16.0
			draw_rect(Rect2(x + 14.0, 44.0, 26.0, fl - 60.0), mc.darkened(0.32))
			draw_circle(Vector2(x + 27.0, 44.0), 13.0, mc.darkened(0.32))
			if (i / 3) % 2 == 0:
				var bc: Color = CG.FIGHTERS[(i / 3) % CG.FIGHTERS.size()]["col"]
				draw_rect(Rect2(x + 19.0, 46.0, 16.0, 62.0), bc.darkened(0.3))
				draw_rect(Rect2(x + 19.0, 46.0, 16.0, 2.0), Color(1.0, 0.82, 0.35))
			draw_rect(Rect2(x + 2.0, 26.0, 8.0, fl - 26.0), mc.lightened(0.06))
			draw_rect(Rect2(x + 5.0, 30.0, 2.0, fl - 40.0), Color(CG.NEON[(i / 3) % 4], 0.35 + 0.5 * absf(sin(_t * 1.6 - i * 0.2))))
		draw_rect(Rect2(16.0, 0.0, W - 32.0, 10.0), Color(0.1, 0.09, 0.14))
		draw_rect(Rect2(16.0, 10.0, W - 32.0, 12.0), mc.lightened(0.05))
		for sg in range(16, int(W) - 16, 12):
			var run := pow(maxf(0.0, sin(sg * 0.05 - _t * 2.2)), 2.0)
			draw_rect(Rect2(sg, 22.0, 12.0, 4.0), Color(CG.NEON[0], 0.4 + 0.6 * run))
			draw_rect(Rect2(sg, fl - 12.0, 12.0, 3.0), Color(CG.NEON[1], 0.35 + 0.65 * pow(maxf(0.0, sin(sg * 0.05 + _t * 1.7)), 2.0)))
		draw_rect(Rect2(16.0, fl - 9.0, W - 32.0, 9.0), mc.darkened(0.25))
		# the open gate to the stands: the arena's light in it, the far rows of the round, the rail
		var gr := Rect2(mid - 48.0, fl - 108.0, 96.0, 108.0)
		draw_rect(gr.grow_individual(10.0, 10.0, 10.0, 0.0), mc.lightened(0.08))
		draw_rect(gr, Color(0.55, 0.78, 0.95))
		for b in 5:
			draw_rect(Rect2(gr.position.x, gr.position.y + 14.0 + b * 9.0, gr.size.x, 5.0), Color(0.2, 0.18, 0.3, 0.75 - b * 0.1))
			for p in 12:
				draw_rect(Rect2(gr.position.x + 3.0 + p * 7.8 + (b % 2) * 3.0, gr.position.y + 14.0 + b * 9.0, 2.0, 3.0), Color(CG.NEON[(p + b) % 4], 0.8))
		draw_rect(Rect2(gr.position.x, gr.position.y + 62.0, gr.size.x, 46.0), Color(0.85, 0.93, 1.0))
		draw_rect(Rect2(gr.position.x, gr.position.y + 60.0, gr.size.x, 2.0), Color(0.3, 0.9, 1.0))
		draw_rect(Rect2(gr.position.x, gr.position.y + 62.0, gr.size.x, 46.0), Color(0.4, 0.75, 1.0, 0.25 + 0.2 * absf(sin(_t * 0.9))))
		draw_rect(gr, Color(1.0, 0.82, 0.35, 0.7 + 0.3 * absf(sin(_t * 1.8))), false, 2.5)
		CG.draw_screen(self, Rect2(mid - 62.0, 4.0, 124.0, 43.0), GameState.play_time)
		# the ranking, west
		var rk := Rect2(mid - 20.0 * 16.0, 34.0, 168.0, 104.0)
		draw_rect(rk.grow(3.0), mc.lightened(0.05))
		draw_rect(rk, Color(0.04, 0.04, 0.09))
		draw_string(font, rk.position + Vector2(6.0, 11.0), "THE RANKING", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 8, Color(1.0, 0.85, 0.4))
		var rows: Array = CG.RANK.duplicate()
		if GameState.col_registered:
			rows.append([GameState.pilot_name.to_upper(), 0])
		for r in mini(rows.size(), 9):
			var mine := r >= CG.RANK.size()
			var ry := rk.position.y + 21.0 + r * 9.2
			draw_string(font, Vector2(rk.position.x + 6.0, ry), "%d" % (r + 1) if not mine else "NEW", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 6, Color(0.6, 0.65, 0.78))
			draw_string(font, Vector2(rk.position.x + 26.0, ry), String(rows[r][0]), HORIZONTAL_ALIGNMENT_LEFT, 96.0, 6,
				Color(0.5, 1.0, 0.6) if mine else Color(CG.FIGHTERS[r % CG.FIGHTERS.size()]["col"]).lightened(0.3))
			draw_string(font, Vector2(rk.end.x - 40.0, ry), "%d" % int(rows[r][1]), HORIZONTAL_ALIGNMENT_RIGHT, 34.0, 6, Color(0.85, 0.9, 1.0))
		draw_rect(rk, Color(CG.NEON[1], 0.8), false, 1.5)
		# the fighters' gate, behind the registration
		var fg := Rect2(CG.FG_X * 16.0, fl - 100.0, 80.0, 100.0)
		draw_rect(fg.grow_individual(8.0, 8.0, 8.0, 0.0), mc.lightened(0.08))
		draw_rect(fg, Color(0.75, 0.92, 1.0))
		for st in 6:
			draw_rect(Rect2(fg.position.x + st * 5.0, fg.position.y + st * 6.0, fg.size.x - st * 10.0, fg.size.y - st * 6.0), Color(0.3, 0.6, 0.85, 0.16))
		var leaf := fg.size.x * 0.5 * (1.0 - gate)
		for side in 2:
			var lx := fg.position.x if side == 0 else fg.end.x - leaf
			if leaf > 0.5:
				draw_rect(Rect2(lx, fg.position.y, leaf, fg.size.y), Color(0.2, 0.15, 0.12))
				for dl in 6:
					draw_rect(Rect2(lx, fg.position.y + 8.0 + dl * 16.0, leaf, 2.0), Color(0.55, 0.4, 0.2))
				draw_rect(Rect2(lx if side == 1 else lx + leaf - 2.0, fg.position.y, 2.0, fg.size.y), Color(1.0, 0.3, 0.3).lerp(Color(0.3, 1.0, 0.7), gate))
		draw_rect(fg, Color(1.0, 0.3, 0.3).lerp(Color(0.3, 1.0, 0.7), gate), false, 2.0)
		var sign := Rect2(fg.position.x + 4.0, fg.position.y - 22.0, 72.0, 11.0)
		draw_rect(sign, Color(0.04, 0.04, 0.08))
		draw_string(font, sign.position + Vector2(0.0, 8.0), "FIGHTERS ONLY" if gate < 0.5 else "FIGHTERS", HORIZONTAL_ALIGNMENT_CENTER, 72.0, 6,
			Color(1.0, 0.4, 0.4).lerp(Color(0.4, 1.0, 0.75), gate))

	## The stands' floor: dark stone going down in steps to the rail of glass, lights along the aisles.
	func _st_floor() -> void:
		var sr: Rect2 = map.get_meta("col_stands", Rect2())
		draw_rect(sr, Color(0.2, 0.2, 0.27))
		var row := 0
		for gy in range(int(sr.position.y), int(sr.end.y), 32):
			draw_rect(Rect2(sr.position.x, gy, sr.size.x, 32.0), Color(0.2, 0.2, 0.27).lightened(0.035 * row))
			draw_rect(Rect2(sr.position.x, gy + 30.0, sr.size.x, 2.0), Color(0.1, 0.1, 0.15))
			for lx in range(int(sr.position.x) + 8, int(sr.end.x), 48):
				draw_rect(Rect2(lx, gy + 28.0, 6.0, 1.5), Color(0.3, 0.9, 1.0, 0.5 + 0.4 * absf(sin(_t * 1.4 + lx * 0.02))))
			row += 1
		var ry := float(CG.S_TOP) * 16.0                                # the rail: glass, a line of light on its top
		draw_rect(Rect2(0.0, ry + 2.0, float(CG.SW2) * 16.0, 14.0), Color(0.6, 0.85, 1.0, 0.22))
		draw_rect(Rect2(0.0, ry + 2.0, float(CG.SW2) * 16.0, 1.5), Color(0.5, 0.95, 1.0, 0.9))
		for px in range(0, CG.SW2 * 16, 48):
			draw_rect(Rect2(px, ry, 2.0, 16.0), Color(0.75, 0.78, 0.85))

	func _prop() -> void:
		var font := ThemeDB.fallback_font
		var nk := night > 0.5
		var w := float(data.get("w", 16.0))
		var mc := _marble()
		match String(data.get("kind", "")):
			"colossus":
				var who := int(data.get("who", 0))
				var k := float(data.get("k", 3.0))
				var f: Dictionary = CG.FIGHTERS[who % CG.FIGHTERS.size()]
				var col: Color = f["col"]
				var ph := 26.0                                     # the plinth
				draw_rect(Rect2(3.0, -2.0, w, 5.0), Color(0, 0, 0, 0.3))
				draw_rect(Rect2(0.0, -ph, w, ph), mc.darkened(0.12))
				draw_rect(Rect2(-1.5, -ph, w + 3.0, 4.0), mc.lightened(0.1))
				draw_rect(Rect2(-1.5, -4.0, w + 3.0, 4.0), mc.lightened(0.02))
				draw_rect(Rect2(2.0, -ph + 7.0, w - 4.0, 9.0), Color(0.06, 0.05, 0.08))
				draw_string(font, Vector2(2.0, -ph + 14.0), String(f["name"]), HORIZONTAL_ALIGNMENT_CENTER, w - 4.0, 5 if w < 40.0 else 7, col.lightened(0.3))
				draw_rect(Rect2(0.0, -ph + 18.0, w, 1.5), Color(col, 0.6 + 0.4 * absf(sin(_t * 1.7 + who))))
				if data.has("year"):                             # (the lobby: an earlier champion, the year of the title)
					draw_string(font, Vector2(0.0, -1.5), "CHAMPION %d" % int(data["year"]), HORIZONTAL_ALIGNMENT_CENTER, w, 4, Color(0.2, 0.2, 0.25))
				var tex: Texture2D = CG.fighter_tex(who, true)
				var th := tex.get_height() * k
				var tw := tex.get_width() * k
				var tr := Rect2(w * 0.5 - tw * 0.5, -ph - th + k * 1.0, tw, th)
				if bool(data.get("flip", false)):
					draw_set_transform(Vector2(w, 0.0), 0.0, Vector2(-1.0, 1.0))
				draw_texture_rect(tex, tr, false, Color(0.6, 0.62, 0.78) if nk else Color(1, 1, 1))
				# a blade of light in the raised hand: the champion's colour
				var hx := tr.end.x - tw * 0.12
				var hy := tr.position.y + th * 0.52
				draw_line(Vector2(hx, hy + th * 0.3), Vector2(hx + tw * 0.1, tr.position.y - th * 0.18), Color(col, 0.35), 5.0)
				draw_line(Vector2(hx, hy + th * 0.3), Vector2(hx + tw * 0.1, tr.position.y - th * 0.18), col.lightened(0.5), 1.5)
				draw_circle(Vector2(hx + tw * 0.1, tr.position.y - th * 0.18), 2.5 + absf(sin(_t * 2.4 + who)), Color(col.lightened(0.5), 0.9))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			"regdesk":     # the registration's counter: marble, a strip of gold, its sign of light over it, a terminal
				draw_rect(Rect2(3.0, -2.0, w, 5.0), Color(0, 0, 0, 0.3))
				draw_rect(Rect2(0.0, -16.0, w, 16.0), mc.darkened(0.16))
				draw_rect(Rect2(-1.0, -25.0, w + 2.0, 10.0), mc.lightened(0.1))
				draw_rect(Rect2(3.0, -8.0, w - 6.0, 1.5), Color(1.0, 0.82, 0.35, 0.7 + 0.3 * absf(sin(_t * 1.5))))
				draw_rect(Rect2(w - 34.0, -34.0, 16.0, 10.0), Color(0.05, 0.06, 0.1))
				draw_rect(Rect2(w - 33.0, -33.0, 14.0, 8.0), Color(0.3, 0.9, 1.0, 0.6 + 0.3 * sin(_t * 4.0)))
				var sg2 := Rect2(w * 0.5 - 52.0, -70.0, 104.0, 14.0)
				draw_rect(sg2, Color(0.05, 0.04, 0.08, 0.85))
				draw_rect(sg2, Color(1.0, 0.82, 0.35, 0.7 + 0.3 * absf(sin(_t * 1.2))), false, 1.0)
				draw_string(font, sg2.position + Vector2(0.0, 10.0), "REGISTRATION", HORIZONTAL_ALIGNMENT_CENTER, 104.0, 8, Color(1.0, 0.9, 0.6))
			"screenwall":  # a screen of marble seen from above: its top, its end towards you, a line of light along it
				var ln := float(data.get("len", 16.0))
				draw_rect(Rect2(4.0, -1.0, 12.0, 3.0), Color(0, 0, 0, 0.3))
				draw_rect(Rect2(2.0, -ln - 12.0, 12.0, ln), mc.lightened(0.06))
				draw_rect(Rect2(2.0, -12.0, 12.0, 12.0), mc.darkened(0.2))
				draw_rect(Rect2(7.0, -ln - 12.0, 2.0, ln), Color(0.3, 0.9, 1.0, 0.45 + 0.4 * absf(sin(_t * 1.3))))
				draw_rect(Rect2(2.0, -4.0, 12.0, 1.5), Color(0.3, 0.9, 1.0, 0.7))
			"barrier":     # the wall of light across the way in: it flickers and falls apart as `open` goes to 1
				var ln2 := float(data.get("len", 48.0))
				var al := 1.0 - open
				if al > 0.01:
					draw_rect(Rect2(1.0, -ln2, 14.0, ln2), Color(0.3, 0.75, 1.0, 0.3 * al))
					draw_rect(Rect2(6.0, -ln2, 4.0, ln2), Color(0.5, 0.9, 1.0, 0.9 * al))
					for cx2 in 2:
						for cy2 in int((ln2 + 36.0) / 6.0):
							var keep := CG.hsh(cx2 * 31 + cy2, 9)
							if keep < open * 1.15:
								continue                               # (this piece has gone out)
							var fl2 := 0.55 + 0.45 * CG.hsh(cx2 + cy2 * 3 + int(_t * (8.0 + 30.0 * open)), 10)
							draw_rect(Rect2(3.0 + cx2 * 5.0, -ln2 - 36.0 + cy2 * 6.0, 5.0, 5.0), Color(0.3, 0.75, 1.0, 0.42 * al * fl2))
					for sl in 5:
						var sy := -ln2 - 36.0 + fposmod(_t * 26.0 + sl * 17.0, ln2 + 36.0)
						draw_rect(Rect2(3.0, sy, 10.0, 1.0), Color(0.8, 0.97, 1.0, 0.6 * al))
					draw_rect(Rect2(3.0, -ln2 - 36.0, 10.0, 1.5), Color(0.7, 0.95, 1.0, 0.9 * al))
			"brazier":
				draw_rect(Rect2(4.0, -2.0, 10.0, 4.0), Color(0, 0, 0, 0.3))
				draw_rect(Rect2(6.5, -18.0, 3.0, 18.0), mc.darkened(0.2))
				draw_rect(Rect2(3.0, -3.0, 10.0, 3.0), mc.darkened(0.1))
				draw_colored_polygon(PackedVector2Array([Vector2(1.0, -24.0), Vector2(15.0, -24.0), Vector2(11.0, -17.0), Vector2(5.0, -17.0)]), mc.lightened(0.05))
				draw_rect(Rect2(1.0, -25.0, 14.0, 1.5), Color(1.0, 0.82, 0.35))
				for fl in 5:                                       # a flame of light
					var fk := fposmod(_t * (1.4 + fl * 0.23) + fl * 0.37 + float(data.get("seed", 0)), 1.0)
					var fx := 8.0 + sin(_t * 3.0 + fl * 1.9) * 3.0 * (1.0 - fk)
					draw_circle(Vector2(fx, -26.0 - fk * 16.0), 4.5 * (1.0 - fk) + 0.8, Color(1.0, 0.75 - 0.4 * fk, 0.2 + 0.5 * fk, 0.75 * (1.0 - fk)))
				draw_circle(Vector2(8.0, -27.0), 3.0, Color(1.0, 0.95, 0.7, 0.9))
			"cypress":
				draw_rect(Rect2(4.0, -2.0, 11.0, 4.0), Color(0, 0, 0, 0.3))
				draw_rect(Rect2(3.0, -9.0, 10.0, 9.0), mc.darkened(0.15))
				draw_rect(Rect2(2.0, -10.0, 12.0, 2.0), mc.lightened(0.08))
				var g := Color(0.1, 0.3, 0.2) if nk else Color(0.16, 0.42, 0.26)
				var sd := int(data.get("seed", 0))
				for lv in 12:
					var ly := -10.0 - lv * 5.0
					var lw := (6.5 - absf(lv - 3.0) * 0.55) * (1.0 if lv < 10 else 0.5)
					draw_rect(Rect2(8.0 - lw + CG.hsh(sd + lv, 2) * 1.5 - 0.7, ly - 5.5, lw * 2.0, 6.0), g.lightened(0.12 * CG.hsh(sd + lv, 4)))
				draw_rect(Rect2(7.5, -73.0, 1.0, 4.0), g)
			"banner":
				var who2 := int(data.get("who", 0))
				var f2: Dictionary = CG.FIGHTERS[who2 % CG.FIGHTERS.size()]
				var col2: Color = f2["col"]
				draw_rect(Rect2(5.0, -2.0, 8.0, 4.0), Color(0, 0, 0, 0.3))
				draw_rect(Rect2(7.0, -78.0, 2.0, 78.0), mc.darkened(0.25))
				draw_rect(Rect2(5.0, -3.0, 6.0, 3.0), mc.darkened(0.1))
				draw_rect(Rect2(-6.0, -78.0, 28.0, 2.0), Color(1.0, 0.82, 0.35))
				var sway := sin(_t * 1.1 + who2) * 1.5
				draw_colored_polygon(PackedVector2Array([Vector2(-5.0, -76.0), Vector2(21.0, -76.0), Vector2(21.0 + sway, -30.0), Vector2(8.0 + sway, -24.0), Vector2(-5.0 + sway, -30.0)]), col2.darkened(0.35))
				var btex: Texture2D = CG.fighter_tex(who2, false)
				draw_texture_rect(btex, Rect2(8.0 - btex.get_width() * 0.5 + sway * 0.5, -72.0, btex.get_width(), btex.get_height()), false)
				draw_rect(Rect2(-5.0, -76.0, 26.0, 1.0), Color(col2.lightened(0.4), 0.9))
				draw_string(font, Vector2(-5.0 + sway, -33.0), String(f2["name"]).get_slice(" ", 0), HORIZONTAL_ALIGNMENT_CENTER, 26.0, 4, Color(1, 1, 1, 0.9))


# ---------------------------------------------------------------- package 62a, part 2: the inside

## Package 62a, part 2 (Luz): the Colosseum's lobby, behind the great gate. A high hall of marble. A red carpet runs
## from the gate (south) straight to an open gate (north) that leads onto the stands; four figures of earlier
## champions stand either side of it. East the registration: a counter with one of the house; behind it, in an
## area shut off by screens of marble and a wall of light, the fighters' gate. Once you have signed up the wall of
## light goes out and the gate opens (`open`: built open). West the board with the ranking, benches.
const LW := 46                     # the lobby's width (tiles) …
const LH := 38                     # … and height
const L_F0 := 10                   # its floor's first row (the north wall above is drawn)
const L_F1 := 33                   # … and last
const LMID := LW / 2
const REG_X := LMID + 9            # the registration: the counter's west end …
const REG_W := 11                  # … and width; the shut area lies north of it
const FG_X := LMID + 12            # the fighters' gate in the north wall: its west edge (5 tiles wide)
const RANK := [["VEX", 2140], ["THE WIDOW", 2085], ["OKONKWO", 1990], ["SABER NINE", 1870], ["MOTHER BRINE", 1790], ["KILN", 1655], ["DORN", 1540], ["PALE TESSA", 1420]]

static func build_lobby(_station: Dictionary, open: bool) -> GroundMap:
	var m := GroundMap.new()
	MuseumGen._pal(m, {})
	m.pal["floor"] = Color(0.8, 0.78, 0.74)
	m.pal["floor2"] = Color(0.7, 0.68, 0.66)
	m.pal["wall"] = Color(0.5, 0.48, 0.52)
	m.pal["frame"] = Color(0.5, 0.48, 0.52)
	m.pal["accent"] = Color(1.0, 0.82, 0.35)
	m.style = "plaza"
	m.title = "The Colosseum"
	m.hull_top = -9999
	m.set_meta("no_guards", true)
	m.setup(LW, LH)
	var GOLD := Color(1.0, 0.82, 0.35)
	var CYAN := Color(0.3, 0.9, 1.0)
	var mid := LMID
	var props: Array = []
	m.fill(0, 0, LW, LH, T.CAP)
	m.fill(1, 0, LW - 2, L_F0, T.BLOCK, 0)                       # the north wall: drawn over
	m.fill(1, L_F0, LW - 2, L_F1 - L_F0 + 1, T.FLOOR, 0)
	# the great gate (south) and the open gate to the stands (north), the red carpet between them
	m.fill(mid - 3, L_F1 + 1, 6, 2, T.FLOOR, 0)
	m.zones.append({"rect": Rect2(Vector2(mid - 3, L_F1 + 1.2) * TILE, Vector2(6, 1.7) * TILE), "kind": "museum_go", "id": "col_out", "to": "zcol", "at": "from_gate",
		"title": "Out onto the plaza", "col": GOLD, "sign": Vector2(-100, -100)})
	m.set_meta("from_plaza", Vector2(mid, L_F1 + 0.2) * TILE)
	m.spawn = m.get_meta("from_plaza")
	m.zones.append({"rect": Rect2(Vector2(mid - 3, L_F0) * TILE, Vector2(6, 1.4) * TILE), "kind": "museum_go", "id": "col_stands", "to": "zcolst", "at": "from_lobby",
		"title": "Through the gate: the stands", "col": CYAN, "sign": Vector2(-100, -100)})
	m.set_meta("from_stands", Vector2(mid, L_F0 + 2.0) * TILE)
	m.set_meta("col_carpet", Rect2(Vector2(mid - 2, L_F0) * TILE, Vector2(4, L_F1 + 3 - L_F0) * TILE))
	m.lights.append({"pos": Vector2(mid, L_F0 + 0.5) * TILE, "r": 110.0, "col": Color(0.8, 0.95, 1.0), "a": 0.3})
	m.lights.append({"pos": Vector2(mid, L_F1 + 1.0) * TILE, "r": 90.0, "col": GOLD, "a": 0.4})
	# earlier champions either side of the carpet
	var si := 0
	for sy in [L_F0 + 3, L_F0 + 9, L_F0 + 15, L_F0 + 21]:
		for sx in [mid - 6, mid + 4]:
			m.fill(sx, sy, 2, 2, T.BLOCK, 0)
			props.append({"kind": "colossus", "pos": Vector2(sx, sy + 2) * TILE, "w": 2 * TILE, "who": si, "k": 1.8, "flip": sx > mid, "year": 2731 - si * 3})
			m.lights.append({"pos": Vector2(sx + 1.0, sy + 2.3) * TILE, "r": 36.0, "col": FIGHTERS[si % FIGHTERS.size()]["col"], "a": 0.22})
			si += 1
	for bz in [mid - 5, mid + 4]:
		m.fill(bz, L_F0, 1, 1, T.BLOCK, 0)
		props.append({"kind": "brazier", "pos": Vector2(bz, L_F0 + 1) * TILE, "w": TILE, "seed": bz})
		m.lights.append({"pos": Vector2(bz + 0.5, L_F0 + 0.5) * TILE, "r": 70.0, "col": Color(1.0, 0.6, 0.25), "a": 0.5, "flicker": true})
	# ---- east: the registration; behind its counter the shut area with the fighters' gate
	var rx := REG_X
	var ry := L_F0 + 7                                           # the counter's row
	m.fill(rx, ry, REG_W, 1, T.BLOCK, 0)
	props.append({"kind": "regdesk", "pos": Vector2(rx, ry + 1) * TILE, "w": REG_W * TILE})
	m.people.append({"pos": Vector2(rx + REG_W * 0.5, ry - 0.1) * TILE, "dir": 0, "role": "keeper", "look": load("res://scripts/core/story.gd").look_of("marshal")})      # (part 3) Cass Ardent, the Marshal of the Lists
	Gen._zone(m, Rect2(rx + 2, ry + 1.0, REG_W - 4, 1.3), "col_register", "The registration: talk to the Marshal of the Lists", GOLD, {"id": "col_register"})
	m.lights.append({"pos": Vector2(rx + REG_W * 0.5, ry + 1.2) * TILE, "r": 80.0, "col": GOLD, "a": 0.3})
	for scx in [rx - 1, rx + REG_W]:                             # the screens of marble either side, down to the counter
		m.fill(scx, L_F0, 1, 8, T.BLOCK, 0)
	var gap := Rect2i(rx - 1, L_F0 + 2, 1, 3)                    # the way in, through the west screen: a wall of light until you have signed up
	if open:
		m.fill(gap.position.x, gap.position.y, 1, 3, T.FLOOR, 0)
	props.append({"kind": "screenwall", "pos": Vector2(rx - 1, L_F0 + 2) * TILE, "w": TILE, "len": 2 * TILE})
	props.append({"kind": "screenwall", "pos": Vector2(rx - 1, L_F0 + 8) * TILE, "w": TILE, "len": 3 * TILE})
	props.append({"kind": "screenwall", "pos": Vector2(rx + REG_W, L_F0 + 8) * TILE, "w": TILE, "len": 8 * TILE})
	props.append({"kind": "barrier", "pos": Vector2(rx - 1, L_F0 + 5) * TILE, "w": TILE, "len": 3 * TILE})
	m.set_meta("col_area", Vector2(rx + REG_W * 0.5 - 1.0, L_F0 + 3.0) * TILE)      # where the scene looks
	m.set_meta("col_open", open)
	m.set_meta("from_reg", Vector2(rx + REG_W * 0.5, ry + 1.8) * TILE)
	Gen._zone(m, Rect2(FG_X, L_F0, 5, 1.4), "col_fgate", "The fighters' gate", CYAN, {"id": "col_fgate"})
	m.lights.append({"pos": Vector2(FG_X + 2.5, L_F0 + 0.6) * TILE, "r": 80.0, "col": CYAN if open else Color(1.0, 0.3, 0.3), "a": 0.5})
	# ---- west: the ranking on the wall, benches before it, cypresses in the corners
	for bq in [mid - 19, mid - 14]:
		m.add_object({"kind": "bench", "x": bq, "y": L_F0 + 2, "w": 3, "h": 1, "face": 0}, false)
	for cy in [Vector2i(2, L_F0), Vector2i(LW - 3, L_F0), Vector2i(2, L_F1), Vector2i(LW - 3, L_F1), Vector2i(mid - 9, L_F0)]:
		m.fill(cy.x, cy.y, 1, 1, T.BLOCK, 0)
		props.append({"kind": "cypress", "pos": Vector2(cy.x, cy.y + 1) * TILE, "w": TILE, "seed": cy.x + cy.y})
	for lp in [Vector2i(5, L_F0 + 9), Vector2i(5, L_F0 + 18), Vector2i(LW - 6, L_F0 + 13), Vector2i(LW - 6, L_F0 + 20), Vector2i(mid - 12, L_F0 + 14), Vector2i(mid + 11, L_F0 + 14)]:
		m.add_object({"kind": "holo_pillar", "x": lp.x, "y": lp.y, "w": 1, "h": 1, "col": [GOLD, CYAN][(lp.x + lp.y) % 2]})
		m.lights.append({"pos": Vector2(lp.x + 0.5, lp.y) * TILE, "r": 60.0, "col": [GOLD, CYAN][(lp.x + lp.y) % 2], "a": 0.28})
	for bq2 in [Vector2i(8, L_F0 + 12), Vector2i(8, L_F0 + 20), Vector2i(LW - 12, L_F0 + 16)]:
		m.add_object({"kind": "bench", "x": bq2.x, "y": bq2.y, "w": 3, "h": 1, "face": 0}, false)
	m.set_meta("col_props", props)
	m.set_meta("tourists", 12)
	DeckGen._seats(m)
	for gx in range(4, LW - 3, 5):
		for gy in [L_F0 + 11, L_F0 + 16, L_F0 + 21]:
			if m.free_at(Vector2(gx, gy) * TILE, 6.0):
				m.wander.append(Vector2(gx, gy) * TILE)
	return m


## … and the stands: through the lobby's open gate. You come out at the top of a part of the round: rows of seats
## going down north to a walk along a rail of glass; beyond it, below, the arena (ArenaSky draws it and the rest of
## the round). Every row is a seat; from a seat the camera looks down into the arena.
const SW2 := 64                    # the stands' width (tiles)
const SH2 := 30
const S_TOP := 14                  # the rail's row: north of it the view

static func build_stands(_station: Dictionary) -> GroundMap:
	var m := GroundMap.new()
	MuseumGen._pal(m, {})
	m.pal["floor"] = Color(0.3, 0.3, 0.38)
	m.pal["floor2"] = Color(0.24, 0.24, 0.32)
	m.pal["wall"] = Color(0.5, 0.48, 0.52)
	m.pal["frame"] = Color(0.5, 0.48, 0.52)
	m.pal["accent"] = Color(0.3, 0.9, 1.0)
	m.style = "plaza"
	m.title = "The Colosseum"
	m.hull_top = -9999
	m.set_meta("no_guards", true)
	m.setup(SW2, SH2)
	var CYAN := Color(0.3, 0.9, 1.0)
	var mid := SW2 / 2
	m.window_rect = Rect2(0, 0, SW2, S_TOP)
	m.fill(0, S_TOP, SW2, SH2 - S_TOP, T.CAP)
	m.fill(0, S_TOP, SW2, 1, T.BLOCK, 0)                         # the rail
	m.fill(1, S_TOP + 1, SW2 - 2, 11, T.FLOOR, 0)
	m.fill(mid - 3, S_TOP + 12, 6, 2, T.FLOOR, 0)                # the way back into the lobby
	m.zones.append({"rect": Rect2(Vector2(mid - 3, S_TOP + 12.2) * TILE, Vector2(6, 1.7) * TILE), "kind": "museum_go", "id": "col_back", "to": "zcolin", "at": "from_stands",
		"title": "Back into the lobby", "col": Color(1.0, 0.82, 0.35), "sign": Vector2(-100, -100)})
	m.set_meta("from_lobby", Vector2(mid, S_TOP + 11.4) * TILE)
	m.spawn = m.get_meta("from_lobby")
	m.set_meta("col_focus", Vector2(mid, S_TOP - 5.0) * TILE)       # where a seat looks: down into the arena
	m.set_meta("col_stands", Rect2(Vector2(1, S_TOP + 1) * TILE, Vector2(SW2 - 2, 11) * TILE))
	var rng := RandomNumberGenerator.new()
	rng.seed = 6231
	for row in 3:                                                # three rows of seats, an aisle in the middle and at the ends
		var sy := S_TOP + 5 + row * 2
		for sx in range(3, SW2 - 5, 3):
			if absi(sx + 1 - mid) < 4 or (sx / 3) % 6 == 5:
				continue
			DeckGen._seat(m, "bench", sx, sy, 1, [Color(0.55, 0.16, 0.26), Color(0.5, 0.14, 0.24)][row % 2], rng, 0.45, 3)
	for lx in range(4, SW2 - 2, 8):
		m.lights.append({"pos": Vector2(lx, S_TOP + 1.2) * TILE, "r": 60.0, "col": CYAN, "a": 0.35})
	m.lights.append({"pos": Vector2(mid, S_TOP + 12.0) * TILE, "r": 90.0, "col": Color(1.0, 0.82, 0.35), "a": 0.4})
	m.set_meta("tourists", 8)
	DeckGen._seats(m)
	for gx in range(4, SW2 - 3, 6):
		for gy in [S_TOP + 2, S_TOP + 3]:
			if m.free_at(Vector2(gx, gy) * TILE, 6.0):
				m.wander.append(Vector2(gx, gy) * TILE)
	return m


# ---- the arena's floor at rest (window px): how the wave of blue light and the system's test run by the clock
const WAVE := 7.0                  # seconds between two waves of light
const TEST := 38.0                 # … between two tests of the system
const TEST_LEN := 7.0

static func _ell(c: Vector2, rx: float, ry: float, a0: float = 0.0, a1: float = TAU, n: int = 72) -> PackedVector2Array:
	var out := PackedVector2Array()
	for q in n + 1:
		var a := a0 + (a1 - a0) * q / n
		out.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return out


const A_TIERS := 5                 # the tiers of seats round the arena …
const A_TX := 74.0                 # … each this much wider …
const A_TY := 50.0                 # … and deeper than the one below it
const A_WALL := 22.0               # the arena's wall: how high it stands over the floor (window px)
const A_CELL := 32.0               # a tile of the floor

## The arena from the stands, seen as everything on foot is seen: from above. The whole round lies before you:
## the tiers of seats go down in rings from the rail you stand at to the arena's wall and rise again on the far
## side, the crowd in them; in their middle, below the wall, the floor of white tiles. Now and then a wave of blue
## light runs over the tiles, now and then the system tries itself (holograms of cover flicker up out of the tiles
## and fall back into them). The cube of screens hangs over the middle, its shadow under it.
static func draw_arena(ci: CanvasItem, w: float, h: float, cx: float, t: float, _night: float) -> void:
	ci.draw_rect(Rect2(0, 0, w, h), Color(0.05, 0.05, 0.1))
	var ac := Vector2(cx, h * 0.54)
	var rx := w * 0.36
	var ry := h * 0.3
	var wx := rx + 26.0                                         # the wall's outer edge
	var wy := ry + 16.0
	# ---- the tiers, the outermost first; a line of light on every step, the rows of seats as rings
	for k in range(A_TIERS, 0, -1):
		var ex := wx + k * A_TX
		var ey := wy + k * A_TY
		ci.draw_colored_polygon(_ell(ac, ex, ey), Color(0.15, 0.15, 0.22).lightened(0.03 * (A_TIERS - k)))
		ci.draw_polyline(_ell(ac, ex - A_TX * 0.34, ey - A_TY * 0.34), Color(0.36, 0.12, 0.2), 9.0)
		ci.draw_polyline(_ell(ac, ex - A_TX * 0.7, ey - A_TY * 0.7), Color(0.36, 0.12, 0.2), 9.0)
		ci.draw_polyline(_ell(ac, ex - A_TX + 2.0, ey - A_TY + 2.0), Color(NEON[k % 3], 0.35 + 0.25 * absf(sin(t * 1.3 + k))), 2.5)
	for q in 28:                                                 # the aisles between the blocks of seats
		var a := (q + 0.5) * TAU / 28.0
		var dv := Vector2(cos(a), sin(a))
		ci.draw_line(ac + Vector2(dv.x * (wx + 4.0), dv.y * (wy + 4.0)), ac + Vector2(dv.x * (wx + A_TIERS * A_TX), dv.y * (wy + A_TIERS * A_TY)), Color(0.11, 0.11, 0.17), 12.0)
		ci.draw_line(ac + Vector2(dv.x * (wx + 4.0), dv.y * (wy + 4.0)), ac + Vector2(dv.x * (wx + A_TIERS * A_TX), dv.y * (wy + A_TIERS * A_TY)), Color(0.3, 0.9, 1.0, 0.22), 2.0)
	for p in 1100:                                               # the crowd: heads in the rows
		var pa := hsh(p, 4) * TAU
		if fposmod(pa * 28.0 / TAU, 1.0) > 0.42 and fposmod(pa * 28.0 / TAU, 1.0) < 0.58:
			continue                                              # (an aisle)
		var pk := 1 + int(hsh(p, 5) * A_TIERS) % A_TIERS
		var row := 0.34 if p % 2 == 0 else 0.7
		var pp := ac + Vector2(cos(pa) * (wx + pk * A_TX - A_TX * row), sin(pa) * (wy + pk * A_TY - A_TY * row))
		if pp.y < -8.0 or pp.y > h + 8.0 or pp.x < -8.0 or pp.x > w + 8.0:
			continue
		var pc: Color = [Color(0.9, 0.8, 0.7), NEON[0], NEON[1], NEON[2], Color(0.8, 0.85, 1.0), Color(0.55, 0.4, 0.3)][int(hsh(p, 6) * 6.0) % 6]
		var up := 2.0 if int(t * 2.0 + p) % 11 == 0 else 0.0
		ci.draw_rect(Rect2(pp.x - 3.0, pp.y - 9.0 - up, 6.0, 6.0), pc)
		ci.draw_rect(Rect2(pp.x - 4.0, pp.y - 3.0 - up, 8.0, 5.0), pc.darkened(0.45))
	# ---- the arena's wall: its top all round, the inner face of the far side, a line of light on both edges
	ci.draw_colored_polygon(_ell(ac, wx, wy), Color(0.3, 0.29, 0.38))
	ci.draw_polyline(_ell(ac, wx, wy), Color(NEON[1], 0.85), 3.0)
	ci.draw_polyline(_ell(ac, rx, ry), Color(NEON[1], 0.5), 2.0)
	# ---- the floor, below the wall: white tiles in the same square grid as every floor on foot
	var fc := ac + Vector2(0.0, A_WALL)                           # (the floor lies lower: its far edge shows the wall's face)
	ci.draw_colored_polygon(_ell(ac, rx, ry), Color(0.92, 0.93, 0.96))
	var face := _ell(ac, rx, ry, PI, TAU)
	var lower := _ell(fc, rx, ry, TAU, PI)
	var band := PackedVector2Array(face)
	band.append_array(lower)
	ci.draw_colored_polygon(band, Color(0.2, 0.2, 0.28))
	ci.draw_polyline(_ell(ac + Vector2(0.0, A_WALL * 0.5), rx, ry, PI + 0.06, TAU - 0.06), Color(NEON[0], 0.5 + 0.3 * absf(sin(t * 1.1))), 2.5)
	ci.draw_polyline(_ell(fc + Vector2(0.0, 5.0), rx - 4.0, ry, PI + 0.1, TAU - 0.1), Color(0.3, 0.35, 0.5, 0.25), 10.0)      # (its shadow on the tiles)
	var joint := Color(0.68, 0.72, 0.82)
	var gy := fc.y - floorf(ry / A_CELL) * A_CELL
	while gy < ac.y + ry:
		var v1 := (gy - ac.y) / ry
		var v2 := (gy - fc.y) / ry
		if absf(v1) < 1.0 and absf(v2) < 1.0:
			var half := rx * minf(sqrt(1.0 - v1 * v1), sqrt(1.0 - v2 * v2))
			ci.draw_line(Vector2(ac.x - half, gy), Vector2(ac.x + half, gy), joint, 1.5)
		gy += A_CELL
	var gx := -floorf(rx / A_CELL) * A_CELL
	while gx < rx:
		var s := ry * sqrt(maxf(0.0, 1.0 - (gx / rx) * (gx / rx)))
		if s > A_WALL * 0.5:
			ci.draw_line(Vector2(ac.x + gx, fc.y - s), Vector2(ac.x + gx, ac.y + s), joint, 1.5)
		gx += A_CELL
	for sh in 3:                                                 # the tiles lie a little in shade towards the wall
		ci.draw_polyline(_ell(ac, rx - 10.0 - sh * 16.0, ry - 8.0 - sh * 10.0, 0.0, PI), Color(0.35, 0.42, 0.6, 0.1 - sh * 0.025), 18.0)
	ci.draw_arc(fc, 70.0, 0.0, TAU, 48, Color(0.35, 0.7, 1.0, 0.45), 3.0)       # the middle's mark
	ci.draw_line(Vector2(ac.x - rx + 30.0, fc.y), Vector2(ac.x + rx - 30.0, fc.y), Color(0.35, 0.7, 1.0, 0.25), 3.0)
	# ---- the wave of blue light
	var n := int(floor(t / WAVE))
	var wk := fposmod(t, WAVE) / 2.6
	if wk < 1.0:
		if n % 2 == 0:                                            # a line running from the far side to you
			for tr in 6:
				var ly := fc.y - ry + (2.0 * ry) * wk - tr * 9.0
				var w1 := (ly - ac.y) / ry
				var w2 := (ly - fc.y) / ry
				if absf(w1) < 1.0 and absf(w2) < 1.0:
					var half2 := rx * minf(sqrt(1.0 - w1 * w1), sqrt(1.0 - w2 * w2))
					ci.draw_line(Vector2(ac.x - half2, ly), Vector2(ac.x + half2, ly), Color(0.3, 0.7, 1.0, (0.85 - tr * 0.14) * (1.0 - 0.3 * wk)), 8.0 - tr)
		else:                                                     # a ring from the middle
			for tr2 in 4:
				var rs := wk - tr2 * 0.05
				if rs > 0.02:
					ci.draw_polyline(_ell(fc, rx * rs * 0.97, minf(ry - A_WALL, rx * rs * 0.97)), Color(0.3, 0.7, 1.0, (0.85 - tr2 * 0.2) * (1.0 - wk)), 8.0 - tr2 * 1.5)
	# ---- the system's test: cover and platforms of light flicker up out of the tiles
	var tk := fposmod(t, TEST)
	if tk < TEST_LEN:
		var grow := clampf(tk / 1.4, 0.0, 1.0) * clampf((TEST_LEN - tk) / 1.4, 0.0, 1.0)
		for b in 9:
			var bu := (hsh(b + int(t / TEST) * 7, 11) - 0.5) * 1.5
			var bv := (hsh(b + int(t / TEST) * 7, 12) - 0.5) * 1.2
			if bu * bu + bv * bv > 0.55:
				continue
			var bp := fc + Vector2(snappedf(bu * rx, A_CELL), snappedf(bv * (ry - A_WALL), A_CELL))
			var bw := A_CELL * (2.0 + float(int(hsh(b, 13) * 3.0)))
			var bd := A_CELL * (1.0 + float(int(hsh(b, 14) * 2.0)))        # how deep it stands on the tiles
			var bh := (26.0 + hsh(b, 15) * 34.0) * grow
			var al := (0.55 + 0.45 * hsh(b + int(t * 12.0), 16)) * grow
			var hc := Color(0.35, 0.75, 1.0, 0.9 * al)
			ci.draw_rect(Rect2(bp.x, bp.y - bd - bh, bw, bd), Color(0.45, 0.8, 1.0, 0.4 * al))                  # its top
			ci.draw_rect(Rect2(bp.x, bp.y - bh, bw, bh), Color(0.25, 0.6, 1.0, 0.28 * al))                      # its face towards you
			ci.draw_rect(Rect2(bp.x, bp.y - bd - bh, bw, bd + bh), hc, false, 2.0)
			ci.draw_line(Vector2(bp.x, bp.y - bh), Vector2(bp.x + bw, bp.y - bh), hc, 2.0)
			for sl in range(0, int(bh), 6):
				ci.draw_rect(Rect2(bp.x, bp.y - sl - 1.0, bw, 1.0), Color(0.6, 0.9, 1.0, 0.3 * al))
		ci.draw_string(ThemeDB.fallback_font, Vector2(cx - 220.0, ac.y + ry - 30.0), "HOLO GRID  ·  SYSTEM TEST", HORIZONTAL_ALIGNMENT_CENTER, 440.0, 18, Color(0.2, 0.55, 0.95, 0.5 + 0.5 * absf(sin(t * 5.0))))
	# ---- the cube of screens over the middle: its shadow on the tiles, the lines it hangs on
	ci.draw_colored_polygon(_ell(fc + Vector2(0.0, 16.0), 150.0, 34.0), Color(0.2, 0.25, 0.4, 0.22))
	var sr := Rect2(cx - 160.0, fc.y - 215.0, 320.0, 112.0)
	for side in 2:
		var sx := sr.position.x + 14.0 if side == 0 else sr.end.x - 14.0
		ci.draw_line(Vector2(sx, sr.position.y), Vector2(sx + (-260.0 if side == 0 else 260.0), -20.0), Color(0.4, 0.42, 0.5, 0.7), 2.0)
	ci.draw_rect(Rect2(sr.position.x - 10.0, sr.end.y + 10.0, sr.size.x + 20.0, 14.0), Color(0.12, 0.11, 0.18))      # (the cube's underside)
	draw_screen(ci, sr, t)


# ---------------------------------------------------------------- package 62a, part 3: the arena itself

## The arena you step into after the countdown: a great oval of white tiles inside its wall, the tiers of seats and
## the crowd all round (drawn), the fighters' gate in the south (the way back into the lobby), the gate of the
## others in the north (shut). No fight yet: that follows.
const AW := 60                     # the arena's map (tiles) …
const AH := 44
const A_C := Vector2(30.0, 22.0)   # … the middle of its floor …
const A_R := Vector2(25.0, 15.0)   # … and the floor's radii

static func build_arena(_station: Dictionary) -> GroundMap:
	var m := GroundMap.new()
	MuseumGen._pal(m, {})
	m.pal["floor"] = Color(0.9, 0.91, 0.94)
	m.pal["floor2"] = Color(0.86, 0.87, 0.9)
	m.pal["wall"] = Color(0.3, 0.29, 0.38)
	m.pal["frame"] = Color(0.3, 0.29, 0.38)
	m.pal["accent"] = Color(0.3, 0.9, 1.0)
	m.style = "plaza"
	m.title = "The Colosseum"
	m.hull_top = -9999
	m.set_meta("no_guards", true)
	m.setup(AW, AH)
	m.fill(0, 0, AW, AH, T.BLOCK, 0)
	for y in AH:
		for x in AW:
			var d := Vector2((x + 0.5 - A_C.x) / A_R.x, (y + 0.5 - A_C.y) / A_R.y)
			if d.length() < 0.985:
				m.set_t(x, y, T.FLOOR)
	var gy := int(A_C.y + A_R.y)                                 # the fighters' gate: a passage through the wall, south
	m.fill(int(A_C.x) - 1, gy - 1, 2, 3, T.FLOOR, 0)
	m.zones.append({"rect": Rect2(Vector2(A_C.x - 1.0, gy + 0.6) * TILE, Vector2(2.0, 1.4) * TILE), "kind": "museum_go", "id": "col_leave", "to": "zcolin", "at": "from_reg",
		"title": "Leave the arena: back into the lobby", "col": Color(0.4, 1.0, 0.7), "sign": Vector2(-100, -100)})
	m.set_meta("from_gate", Vector2(A_C.x, gy - 2.2) * TILE)
	m.spawn = m.get_meta("from_gate")
	for lq in 10:
		var la := lq * TAU / 10.0
		m.lights.append({"pos": (A_C + Vector2(cos(la) * A_R.x * 0.6, sin(la) * A_R.y * 0.6)) * TILE, "r": 150.0, "col": Color(0.85, 0.92, 1.0), "a": 0.14})
	m.set_meta("tourists", 0)
	return m


## The arena's ground, drawn (art px, under the people): the tiers and the crowd round it, its wall with the two
## gates, the floor of white tiles in the map's own grid, the wave of blue light, the middle's mark.
static func draw_arena_ground(ci: CanvasItem, t: float) -> void:
	var c := A_C * float(TILE)
	var rx := A_R.x * TILE
	var ry := A_R.y * TILE
	ci.draw_rect(Rect2(-200.0, -200.0, AW * TILE + 400.0, AH * TILE + 400.0), Color(0.05, 0.05, 0.1))
	for k in range(5, 0, -1):
		var ex := rx + 14.0 + k * 30.0
		var ey := ry + 12.0 + k * 24.0
		ci.draw_colored_polygon(_ell(c, ex, ey), Color(0.15, 0.15, 0.22).lightened(0.03 * (5 - k)))
		ci.draw_polyline(_ell(c, ex - 10.0, ey - 8.0), Color(0.36, 0.12, 0.2), 4.0)
		ci.draw_polyline(_ell(c, ex - 21.0, ey - 17.0), Color(0.36, 0.12, 0.2), 4.0)
		ci.draw_polyline(_ell(c, ex - 29.0, ey - 23.0), Color(NEON[k % 3], 0.35 + 0.25 * absf(sin(t * 1.3 + k))), 1.5)
	for q in 28:
		var a := (q + 0.5) * TAU / 28.0
		var dv := Vector2(cos(a), sin(a))
		ci.draw_line(c + Vector2(dv.x * (rx + 16.0), dv.y * (ry + 14.0)), c + Vector2(dv.x * (rx + 164.0), dv.y * (ry + 132.0)), Color(0.11, 0.11, 0.17), 5.0)
	for p in 900:
		var pa := hsh(p, 4) * TAU
		if fposmod(pa * 28.0 / TAU, 1.0) > 0.42 and fposmod(pa * 28.0 / TAU, 1.0) < 0.58:
			continue
		var pk := 1 + int(hsh(p, 5) * 5.0) % 5
		var row := 10.0 if p % 2 == 0 else 21.0
		var pp := c + Vector2(cos(pa) * (rx + 14.0 + pk * 30.0 - row), sin(pa) * (ry + 12.0 + pk * 24.0 - row * 0.8))
		var pc: Color = [Color(0.9, 0.8, 0.7), NEON[0], NEON[1], NEON[2], Color(0.8, 0.85, 1.0), Color(0.55, 0.4, 0.3)][int(hsh(p, 6) * 6.0) % 6]
		var up := 1.0 if int(t * 2.0 + p) % 11 == 0 else 0.0
		ci.draw_rect(Rect2(pp.x - 1.5, pp.y - 4.0 - up, 3.0, 3.0), pc)
		ci.draw_rect(Rect2(pp.x - 2.0, pp.y - 1.0 - up, 4.0, 2.5), pc.darkened(0.45))
	# the wall, its inner face on the far side, the two gates
	ci.draw_colored_polygon(_ell(c, rx + 14.0, ry + 12.0), Color(0.3, 0.29, 0.38))
	ci.draw_polyline(_ell(c, rx + 14.0, ry + 12.0), Color(NEON[1], 0.85), 1.5)
	ci.draw_colored_polygon(_ell(c, rx, ry), Color(0.2, 0.2, 0.28))
	var fc := c + Vector2(0.0, 12.0)                              # the floor lies below the wall's top
	var fl := PackedVector2Array()
	for q2 in 72:
		var a2 := q2 * TAU / 72.0
		var pt := c + Vector2(cos(a2) * rx, sin(a2) * ry)
		if sin(a2) < 0.0:
			pt = fc + Vector2(cos(a2) * rx, sin(a2) * ry)
			pt.y = minf(pt.y, c.y - 0.5)                          # (at its two ends the far edge meets the near one)
		fl.append(pt)
	ci.draw_colored_polygon(fl, Color(0.92, 0.93, 0.96))
	ci.draw_polyline(_ell(c + Vector2(0.0, 6.0), rx, ry, PI + 0.05, TAU - 0.05), Color(NEON[0], 0.5 + 0.3 * absf(sin(t * 1.1))), 1.5)
	ci.draw_polyline(_ell(fc + Vector2(0.0, 3.0), rx - 3.0, ry, PI + 0.1, TAU - 0.1), Color(0.3, 0.35, 0.5, 0.22), 5.0)
	var joint := Color(0.68, 0.72, 0.82)
	for gy in range(0, AH * TILE + 1, TILE):                     # the joints, on the map's own grid
		var v1 := (gy - c.y) / ry
		var v2 := (gy - fc.y) / ry
		if absf(v1) < 1.0 and (gy > c.y or absf(v2) < 1.0):
			var half := rx * sqrt(1.0 - v1 * v1) if gy > c.y else rx * sqrt(1.0 - v2 * v2)
			ci.draw_line(Vector2(c.x - half, gy), Vector2(c.x + half, gy), joint, 1.0)
	for gx in range(0, AW * TILE + 1, TILE):
		var u := (gx - c.x) / rx
		if absf(u) < 1.0:
			var s := ry * sqrt(1.0 - u * u)
			ci.draw_line(Vector2(gx, fc.y - s), Vector2(gx, c.y + s), joint, 1.0)
	ci.draw_arc(fc, 40.0, 0.0, TAU, 40, Color(0.35, 0.7, 1.0, 0.45), 1.5)
	ci.draw_line(Vector2(c.x - rx + 16.0, fc.y), Vector2(c.x + rx - 16.0, fc.y), Color(0.35, 0.7, 1.0, 0.25), 1.5)
	# the fighters' gate (south, open: a light of green) and the gate of the others (north, shut: red)
	ci.draw_rect(Rect2(c.x - 16.0, c.y + ry - 18.0, 32.0, 46.0), Color(0.86, 0.88, 0.92))
	ci.draw_rect(Rect2(c.x - 20.0, c.y + ry - 6.0, 4.0, 34.0), Color(0.4, 1.0, 0.7, 0.6 + 0.4 * absf(sin(t * 2.0))))
	ci.draw_rect(Rect2(c.x + 16.0, c.y + ry - 6.0, 4.0, 34.0), Color(0.4, 1.0, 0.7, 0.6 + 0.4 * absf(sin(t * 2.0))))
	ci.draw_rect(Rect2(c.x - 22.0, fc.y - ry - 12.0, 44.0, 12.0), Color(0.16, 0.12, 0.1))
	ci.draw_rect(Rect2(c.x - 22.0, fc.y - ry - 12.0, 44.0, 12.0), Color(1.0, 0.35, 0.35, 0.6 + 0.4 * absf(sin(t * 1.6))), false, 1.5)
	# the wave of blue light
	var n := int(floor(t / WAVE))
	var wk := fposmod(t, WAVE) / 2.6
	if wk < 1.0:
		if n % 2 == 0:
			for tr in 6:
				var ly := fc.y - ry + (2.0 * ry) * wk - tr * 4.0
				var w1 := (ly - c.y) / ry
				if absf(w1) < 1.0 and ly > fc.y - ry:
					var half2 := rx * sqrt(1.0 - w1 * w1)
					ci.draw_line(Vector2(c.x - half2, ly), Vector2(c.x + half2, ly), Color(0.3, 0.7, 1.0, (0.85 - tr * 0.14) * (1.0 - 0.3 * wk)), 4.0 - tr * 0.5)
		else:
			for tr2 in 4:
				var rs := wk - tr2 * 0.05
				if rs > 0.02:
					ci.draw_polyline(_ell(fc, rx * rs * 0.97, minf(ry - 12.0, rx * rs * 0.97)), Color(0.3, 0.7, 1.0, (0.85 - tr2 * 0.2) * (1.0 - wk)), 4.0 - tr2 * 0.7)


## What you see from the stands, beyond the rail (window px; in the sky's layer).
class ArenaSky extends Node2D:
	const CG = preload("res://scripts/ground/colosseum_gen.gd")
	var size := Vector2.ZERO
	var view = null
	var night := 0.0

	func setup(p_size: Vector2, p_view, p_night: float) -> void:
		size = p_size
		view = p_view
		night = p_night

	func _process(_dt: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var mid := float(CG.SW2) * 0.5 * GroundMap.TILE * GroundMap.SCALE
		var cam := mid
		if view != null and is_instance_valid(view) and (view._cam_c as Vector2) != Vector2.INF:
			cam = (view._cam_c as Vector2).x
		CG.draw_arena(self, size.x, size.y, mid, GameState.play_time, night)      # (it lies where it lies: no shift against the camera)
