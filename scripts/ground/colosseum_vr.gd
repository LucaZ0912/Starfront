extends RefCounted
## Package 62a, part 4 (Luz): the ground the Colosseum's fights are fought on. The arena builds whole maps as
## holograms: a setting each (a canyon of dust, a shelf of ice, a yard of containers), far larger than the arena
## itself. You begin in the south, the three others in the north, cover all over the field between; a wall of light
## runs round it where the hologram ends. At your starting point a pad lets you give up.
## No class_name: preload it.

const CD = preload("res://data/colosseum.gd")
const TILE := GroundMap.TILE
const VW := 84                     # a fight's map (tiles): far larger than the arena
const VH := 58
const EDGE := 2                    # the wall of light round it (tiles)


static func build(setting_id: String, seed_n: int) -> GroundMap:
	var st: Dictionary = CD.SETTINGS[0]
	for s in CD.SETTINGS:
		if String(s["id"]) == setting_id:
			st = s
	var m := GroundMap.new()
	m.pal = DeckGen.palette_for_body({"type": String(st["body"])})
	m.title = "The Colosseum"
	m.hull_top = -60
	m.setup(VW, VH)
	var kind := 14 if String(st["id"]) == "yard" else 13
	m.fill(0, 0, VW, VH, GroundMap.T.BLOCK, kind)
	m.fill(EDGE, EDGE, VW - EDGE * 2, VH - EDGE * 2, GroundMap.T.FLOOR, kind)
	var mid := VW / 2
	m.spawn = Vector2(mid, VH - EDGE - 3.5) * TILE
	m.set_meta("from_gate", m.spawn)
	m.set_meta("col_vr", String(st["id"]))
	m.set_meta("col_vr_name", String(st["name"]))
	m.decals.append({"kind": "mat", "x": mid - 2, "y": VH - EDGE - 3, "w": 4, "h": 2, "col": Color(0.3, 0.9, 1.0)})
	m.zones.append({"rect": Rect2(Vector2(mid - 2, VH - EDGE - 3.0) * TILE, Vector2(4.0, 2.0) * TILE), "kind": "col_giveup", "id": "col_giveup",
		"title": "Give up: leave the hologram", "col": Color(1.0, 0.45, 0.4), "sign": Vector2(-100, -100)})
	for fx in [mid - 9, mid, mid + 9]:
		m.foe_spawns.append(Vector2(fx + 0.5, EDGE + 4.5) * TILE)
	# (Luz) charging points spread over the field: energy and ammunition, for you and for the others; one use draws
	# a point dry for a while. `col_stations`: [{"at": where you stand to use it, "cool": seconds until it is ready, "i"}]
	var stations: Array = []
	var spots: Array = [Vector2(0.2, 0.26), Vector2(0.8, 0.26), Vector2(0.5, 0.5), Vector2(0.2, 0.76), Vector2(0.8, 0.76)]
	for si in mini(CD.STATIONS, spots.size()):
		var sx := int(VW * (spots[si] as Vector2).x)
		var sy := int(VH * (spots[si] as Vector2).y)
		m.add_object({"kind": "fuel_point", "x": sx, "y": sy, "w": 2, "h": 1, "rise": 34})
		var at := Vector2(sx + 1.0, sy + 1.7) * TILE
		stations.append({"at": at, "cool": 0.0, "i": si})
		m.zones.append({"rect": Rect2(Vector2(sx - 0.6, sy + 1.0) * TILE, Vector2(3.2, 1.6) * TILE), "kind": "col_charge", "id": "col_charge_%d" % si, "i": si,
			"title": "Charging point: energy and ammunition", "col": Color(0.35, 0.95, 1.0), "sign": Vector2(-100, -100)})
		m.lights.append({"pos": at, "r": 44.0, "col": Color(0.35, 0.95, 1.0), "a": 0.4})
	m.set_meta("col_stations", stations)
	# the cover, cell by cell (clear round where anybody begins)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("col_vr_%s_%d" % [setting_id, seed_n])
	var rock: Color = (m.pal["terrain_a"] as Color).darkened(0.25).lerp(Color(0.45, 0.43, 0.42), 0.5)
	if String(st["id"]) == "ice":
		rock = Color(0.72, 0.84, 0.95)
	var pieces := {
		"crates": [[["crates", 2, 1], ["crates", 2, 1, 0, 1]], [["crates", 2, 1]], [["crates", 2, 1], ["barrier", 1, 2, 2, 0]]],
		"barrier": [[["barrier", 3, 1]], [["barrier", 1, 3]], [["barrier", 4, 1]]],
		"rock": [[["rock", 2, 1]], [["rock", 2, 2]], [["rock", 3, 2]]],
		"bulwark": [[["bulwark", 3, 1]], [["bulwark", 1, 3]]],
		"barrel": [[["barrel", 1, 1], ["barrel", 1, 1, 1, 0]]],
	}
	var keep: Array = [m.spawn] + m.foe_spawns + stations.map(func(sd): return sd["at"])
	for cy in range(EDGE + 2, VH - EDGE - 5, 6):
		for cx in range(EDGE + 2, VW - EDGE - 5, 7):
			if rng.randf() < 0.2:
				continue
			var what := String((st["cover"] as Array)[rng.randi() % (st["cover"] as Array).size()])
			var set_: Array = pieces[what]
			var piece: Array = set_[rng.randi() % set_.size()]
			var ox := cx + rng.randi_range(0, 3)
			var oy := cy + rng.randi_range(0, 2)
			var ok := true
			for part in piece:
				var px := ox + (int(part[3]) if part.size() > 3 else 0)
				var py := oy + (int(part[4]) if part.size() > 4 else 0)
				for yy in range(py - 1, py + int(part[2]) + 1):
					for xx in range(px - 1, px + int(part[1]) + 1):
						if not GroundMap.walkable_t(m.t_at(xx, yy)) or xx >= VW - EDGE - 1 or yy >= VH - EDGE - 1:
							ok = false
				for ki in keep.size():
					if (keep[ki] as Vector2).distance_to(Vector2(px + 1.0, py + 0.5) * TILE) < (5.5 if ki < 4 else 3.5) * TILE:
						ok = false
			if not ok:
				continue
			for part2 in piece:
				var o := {"kind": String(part2[0]), "x": ox + (int(part2[3]) if part2.size() > 3 else 0), "y": oy + (int(part2[4]) if part2.size() > 4 else 0),
					"w": int(part2[1]), "h": int(part2[2])}
				if o["kind"] == "rock":
					o["col"] = rock
					o["seed"] = rng.randi()
				m.add_object(o)
	if String(st["id"]) == "yard":                              # floodlights on masts
		for lx in range(EDGE + 6, VW - EDGE - 4, 14):
			for ly in [EDGE + 6, VH / 2, VH - EDGE - 8]:
				m.lights.append({"pos": Vector2(lx, ly) * TILE, "r": 130.0, "col": Color(1.0, 0.95, 0.8), "a": 0.3})
	return m


## The wall of light where the hologram ends, and the grid running over the ground as the map comes up (art px,
## under the people).
class VrFx extends Node2D:
	const CV = preload("res://scripts/ground/colosseum_vr.gd")
	const CD = preload("res://data/colosseum.gd")
	var boot := 1.0                  # 1 … 0: the map is still coming up
	var stations: Array = []         # the charging points ({at, cool}): a ring of light round each, dim while it is drawn dry
	var _t := 0.0

	func _process(dt: float) -> void:
		_t += dt
		boot = maxf(0.0, boot - dt / 2.2)
		queue_redraw()

	func _draw() -> void:
		var w := float(CV.VW * CV.TILE)
		var h := float(CV.VH * CV.TILE)
		var e := float(CV.EDGE * CV.TILE)
		var blue := Color(0.3, 0.75, 1.0)
		for side in 4:
			var r: Rect2 = [Rect2(0, 0, w, e), Rect2(0, h - e, w, e), Rect2(0, e, e, h - e * 2.0), Rect2(w - e, e, e, h - e * 2.0)][side]
			draw_rect(r, Color(0.03, 0.05, 0.12, 0.92))
			var horiz := side < 2
			var n := int((r.size.x if horiz else r.size.y) / 16.0)
			for i in n + 1:
				if horiz:
					draw_rect(Rect2(r.position.x + i * 16.0, r.position.y, 1.0, r.size.y), Color(blue, 0.35))
				else:
					draw_rect(Rect2(r.position.x, r.position.y + i * 16.0, r.size.x, 1.0), Color(blue, 0.35))
			for j in 3:
				var o := j * 16.0
				if horiz:
					draw_rect(Rect2(r.position.x, r.position.y + o, r.size.x, 1.0), Color(blue, 0.35))
				else:
					draw_rect(Rect2(r.position.x + o, r.position.y, 1.0, r.size.y), Color(blue, 0.35))
		var inner := Rect2(e, e, w - e * 2.0, h - e * 2.0)
		draw_rect(inner, Color(blue, 0.6 + 0.4 * absf(sin(_t * 1.6))), false, 2.0)
		draw_rect(inner.grow(-3.0), Color(blue, 0.18), false, 4.0)
		for sd in stations:
			var at: Vector2 = sd["at"]
			var cool := float(sd["cool"])
			draw_set_transform(at + Vector2(0.0, -4.0), 0.0, Vector2(1.0, 0.5))
			if cool <= 0.0:
				draw_arc(Vector2.ZERO, 20.0 + 3.0 * sin(_t * 3.0), 0.0, TAU, 32, Color(0.35, 0.95, 1.0, 0.85), 2.0)
				draw_arc(Vector2.ZERO, 12.0, 0.0, TAU, 24, Color(0.35, 0.95, 1.0, 0.35), 5.0)
			else:
				draw_arc(Vector2.ZERO, 20.0, 0.0, TAU, 32, Color(1.0, 0.4, 0.35, 0.5), 2.0)
				draw_arc(Vector2.ZERO, 20.0, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - cool / CD.STATION_COOL), 32, Color(0.35, 0.95, 1.0, 0.9), 2.5)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if boot > 0.0:                                          # the map comes up: the grid still shows through, a line of light runs over it
			for gx in range(int(e), int(w - e) + 1, 16):
				draw_rect(Rect2(gx, e, 1.0, h - e * 2.0), Color(blue, 0.5 * boot))
			for gy in range(int(e), int(h - e) + 1, 16):
				draw_rect(Rect2(e, gy, w - e * 2.0, 1.0), Color(blue, 0.5 * boot))
			var ly := e + (h - e * 2.0) * (1.0 - boot)
			draw_rect(Rect2(e, ly - 3.0, w - e * 2.0, 6.0), Color(0.7, 0.95, 1.0, 0.8 * boot))
			draw_rect(inner, Color(0.85, 0.95, 1.0, 0.35 * boot))
