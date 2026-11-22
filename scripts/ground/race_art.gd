extends RefCounted
## Package 62b (Luz): the broadcast of the races, drawn: the course from the side (the lava canyons of Kiln, the
## rings of Lapis, the asteroid belt), the six ships with their trails, a wreck where one meets the course; before
## a race the card of the next one, after it the result. One picture for the screen on The Track's wall and for the
## large one you see from a seat. All static, drawn onto any CanvasItem. No class_name: preload it.

const RD = preload("res://data/races.gd")


static func _h(i: int, salt: int) -> float:
	return fposmod(sin(float(i) * 12.9898 + float(salt) * 78.233) * 43758.5453, 1.0)


static func mmss(s: float) -> String:
	return "%d:%02d" % [int(s) / 60, int(s) % 60]


## The course behind the ships: `scroll` runs with the leader.
static func _course(ci: CanvasItem, r: Rect2, id: String, scroll: float, t: float) -> void:
	var k := r.size.y / 100.0
	match id:
		"kiln":
			ci.draw_rect(r, Color(0.1, 0.03, 0.03))
			for layer in 2:
				var sp := scroll * (0.5 + layer * 0.5)
				var step := 46.0 * k
				var n := int(r.size.x / step) + 3
				var i0 := int(floor(sp / step))
				for i in n:
					var gi := i0 + i
					var x := r.position.x + gi * step - sp
					var top := (10.0 + _h(gi, 3 + layer) * 22.0) * k * (0.7 + layer * 0.5)
					var bot := (12.0 + _h(gi, 7 + layer) * 20.0) * k * (0.7 + layer * 0.5)
					var c := Color(0.22, 0.07, 0.05) if layer == 0 else Color(0.36, 0.12, 0.07)
					var x0 := clampf(x, r.position.x, r.end.x)
					var x1 := clampf(x + step * 0.5, r.position.x, r.end.x)
					var x2 := clampf(x + step, r.position.x, r.end.x)
					if x1 > x0 + 0.5 and x2 > x1 + 0.5:
						ci.draw_colored_polygon(PackedVector2Array([Vector2(x0, r.position.y), Vector2(x2, r.position.y), Vector2(x1, r.position.y + top)]), c)
						ci.draw_colored_polygon(PackedVector2Array([Vector2(x0, r.end.y), Vector2(x2, r.end.y), Vector2(x1, r.end.y - bot)]), c)
					if layer == 1 and _h(gi, 11) > 0.6 and x1 > r.position.x + 2.0 and x1 < r.end.x - 2.0:      # a fountain of lava
						var fh := (16.0 + 26.0 * absf(sin(t * 2.0 + gi))) * k
						ci.draw_rect(Rect2(x1 - 1.5 * k, r.end.y - fh, 3.0 * k, fh), Color(1.0, 0.6, 0.15, 0.9))
						ci.draw_circle(Vector2(x1, r.end.y - fh), 3.0 * k, Color(1.0, 0.85, 0.4))
			ci.draw_rect(Rect2(r.position.x, r.end.y - 5.0 * k, r.size.x, 5.0 * k), Color(1.0, 0.55, 0.12))
			ci.draw_rect(Rect2(r.position.x, r.end.y - 6.5 * k, r.size.x, 1.5 * k), Color(1.0, 0.85, 0.4, 0.8))
		"rings":
			ci.draw_rect(r, Color(0.02, 0.04, 0.12))
			var pc := Vector2(r.position.x + r.size.x * 0.2, r.end.y + r.size.y * 0.9)      # Lapis below, only its limb in the picture
			var pr := r.size.y * 1.5
			var limb := PackedVector2Array([Vector2(r.position.x, r.end.y)])
			for q0 in 25:
				var lx := r.position.x + r.size.x * q0 / 24.0
				var dx := lx - pc.x
				limb.append(Vector2(lx, clampf(pc.y - sqrt(maxf(0.0, pr * pr - dx * dx)), r.position.y, r.end.y - 0.5)))
			limb.append(Vector2(r.end.x, r.end.y))
			ci.draw_colored_polygon(limb, Color(0.08, 0.2, 0.5))
			for band in 5:
				var by := r.position.y + (14.0 + band * 17.0) * k
				ci.draw_rect(Rect2(r.position.x, by, r.size.x, (3.0 + band % 2 * 2.0) * k), Color(0.6, 0.8, 1.0, 0.1 + 0.04 * band))
			for i2 in 40:
				var sp2 := scroll * (0.4 + _h(i2, 21) * 0.9)
				var x3 := r.position.x + fposmod(_h(i2, 22) * r.size.x * 1.4 - sp2, r.size.x * 1.4) - r.size.x * 0.2
				var y3 := r.position.y + (6.0 + _h(i2, 23) * 88.0) * k
				var s3 := (1.5 + _h(i2, 24) * 4.5) * k
				if x3 > r.position.x + s3 and x3 < r.end.x - s3:
					ci.draw_rect(Rect2(x3 - s3, y3 - s3 * 0.7, s3 * 2.0, s3 * 1.4), Color(0.75, 0.9, 1.0, 0.5 + 0.4 * _h(i2, 25)))
		_:
			ci.draw_rect(r, Color(0.02, 0.02, 0.05))
			for st in 50:
				ci.draw_rect(Rect2(r.position.x + _h(st, 31) * (r.size.x - 2.0), r.position.y + _h(st, 32) * (r.size.y - 2.0), 1.0 * k, 1.0 * k), Color(1, 1, 1, 0.3 + 0.5 * _h(st, 33)))
			for i4 in 26:
				var sp4 := scroll * (0.35 + _h(i4, 41) * 1.0)
				var s4 := (3.0 + _h(i4, 44) * 9.0) * k
				var x4 := r.position.x + fposmod(_h(i4, 42) * r.size.x * 1.5 - sp4, r.size.x * 1.5) - r.size.x * 0.25
				var y4 := r.position.y + (6.0 + _h(i4, 43) * 88.0) * k
				if x4 > r.position.x + s4 and x4 < r.end.x - s4 and y4 > r.position.y + s4 and y4 < r.end.y - s4:
					var pts := PackedVector2Array()
					for q in 7:
						pts.append(Vector2(x4, y4) + Vector2.from_angle(q * TAU / 7.0 + t * (0.2 + _h(i4, 45))) * s4 * (0.7 + 0.3 * _h(i4 * 7 + q, 46)))
					ci.draw_colored_polygon(pts, Color(0.3, 0.28, 0.27).lerp(Color(0.5, 0.45, 0.4), _h(i4, 47)))


static func _ship(ci: CanvasItem, at: Vector2, k: float, col: Color, trail: float) -> void:
	ci.draw_rect(Rect2(at.x - trail, at.y - 0.8 * k, trail, 1.6 * k), Color(col, 0.45))
	ci.draw_colored_polygon(PackedVector2Array([at + Vector2(8.0, 0.0) * k, at + Vector2(-3.0, -3.5) * k, at + Vector2(-1.0, 0.0) * k, at + Vector2(-3.0, 3.5) * k]), col)
	ci.draw_circle(at + Vector2(-2.5, 0.0) * k, 1.4 * k, Color(1, 1, 1, 0.9))


## The whole picture into `r` at the races' clock `t`. `big`: the large picture (more text on it).
static func draw(ci: CanvasItem, r: Rect2, t: float, big: bool) -> void:
	var font := ThemeDB.fallback_font
	var k := r.size.y / 100.0
	var fs := int(maxf(6.0, 7.0 * k * (0.62 if big else 1.0)))
	var ph: Dictionary = RD.phase(t)
	var race: Dictionary = RD.race(int(ph["n"]))
	var tr: Dictionary = race["track"]
	var state := String(ph["state"])
	var rt := float(ph["rt"])
	var st: Array = RD.standing(race, rt)
	var lead := 0.0
	for i in 6:
		if not RD.wrecked(race, i, rt) or rt >= RD.RUN - 0.01:
			lead = maxf(lead, RD.progress(race, i, rt))
	lead = minf(lead, 1.02)
	var span := r.size.x * 9.0
	_course(ci, r, String(tr["id"]), lead * span if state != "bets" else t * 6.0 * k, t)
	if state != "bets":
		var line_x := r.position.x + r.size.x * 0.7 + (1.0 - lead) * span        # the line
		if line_x > r.position.x + 2.0 and line_x < r.end.x - 4.0 * k:
			for cy in 10:
				ci.draw_rect(Rect2(line_x + (cy % 2) * 2.0 * k, r.position.y + cy * r.size.y / 10.0, 2.0 * k, r.size.y / 10.0), Color(1, 1, 1, 0.75))
		for i2 in 6:
			var p: float = RD.progress(race, i2, rt)
			var x := r.position.x + r.size.x * 0.7 - (lead - p) * span
			var y := r.position.y + (24.0 + i2 * 10.5) * k + sin(t * 2.3 + i2 * 1.7) * 2.0 * k
			var col: Color = RD.pilot(race, i2)["col"]
			if x < r.position.x + 10.0 * k or x > r.end.x - 9.0 * k:
				continue
			if RD.wrecked(race, i2, rt):
				var age := rt - float(race["crash_t"][i2])
				ci.draw_line(Vector2(x - 4.0 * k, y - 4.0 * k), Vector2(x + 4.0 * k, y + 4.0 * k), col.darkened(0.3), 1.5 * k)
				ci.draw_line(Vector2(x - 4.0 * k, y + 4.0 * k), Vector2(x + 4.0 * k, y - 4.0 * k), col.darkened(0.3), 1.5 * k)
				if age < 1.6:
					ci.draw_arc(Vector2(x, y), (3.0 + age * 12.0) * k, 0.0, TAU, 20, Color(1.0, 0.8, 0.35, 1.0 - age / 1.6), 1.5 * k)
			else:
				_ship(ci, Vector2(x, y), k, col, minf(22.0 * k, x - r.position.x - 4.0 * k))
				ci.draw_string(font, Vector2(x - 20.0 * k, y - 4.5 * k), str(i2 + 1), HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs, col.lightened(0.3))
	# ---- the words over it
	var head := "%s  ·  " % String(tr["name"]).to_upper()
	if state == "bets":
		head += "STARTS IN %s" % mmss(float(ph["left"]))
	elif state == "run":
		head += "LAP %d / %d" % [mini(RD.LAPS, 1 + int(lead * RD.LAPS)), RD.LAPS]
	else:
		head += "RESULT"
	ci.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 13.0 * k if not big else 9.0 * k), Color(0.01, 0.01, 0.03, 0.72))
	ci.draw_string(font, Vector2(r.position.x + 5.0 * k, r.position.y + (9.5 * k if not big else 6.5 * k)), head, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 10.0 * k, fs + (1 if not big else 4), Color(0.75, 0.95, 1.0))
	if state == "bets":
		ci.draw_string(font, Vector2(r.position.x, r.position.y + 30.0 * k), "BETS ARE OPEN", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, fs + 2, Color(1.0, 0.85, 0.3, 0.6 + 0.4 * absf(sin(t * 2.0))))
		for i3 in 6:                                      # the card of the next race: who flies, at what odds
			var pl: Dictionary = RD.pilot(race, i3)
			var cx := r.position.x + r.size.x * (0.06 + 0.31 * (i3 % 3))
			var cy2 := r.position.y + (46.0 + (i3 / 3) * 16.0) * k
			_ship(ci, Vector2(cx, cy2 - 2.5 * k), k * 0.8, pl["col"], 0.0)
			ci.draw_string(font, Vector2(cx + 9.0 * k, cy2), "%d %s  %s" % [i3 + 1, String(pl["name"]).get_slice(" ", 1), _odds(float(race["win"][i3]))], HORIZONTAL_ALIGNMENT_LEFT, r.size.x * 0.27, fs, Color(pl["col"]).lightened(0.2))
		if int(ph["n"]) > 0:
			var prev: Dictionary = RD.race(int(ph["n"]) - 1)
			var names: Array = []
			for q in 3:
				names.append("%d %s" % [q + 1, String(RD.pilot(prev, int(prev["order"][q]))["name"]).get_slice(" ", 1)])
			ci.draw_string(font, Vector2(r.position.x, r.end.y - 6.0 * k), "LAST RACE:  " + "   ".join(names), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, fs, Color(0.8, 0.85, 0.95, 0.85))
	elif state == "result":
		ci.draw_rect(Rect2(r.position.x + r.size.x * 0.25, r.position.y + 24.0 * k, r.size.x * 0.5, 56.0 * k), Color(0.01, 0.01, 0.03, 0.8))
		for q2 in 3:
			var pi := int(race["order"][q2])
			var pl2: Dictionary = RD.pilot(race, pi)
			ci.draw_string(font, Vector2(r.position.x + r.size.x * 0.25, r.position.y + (40.0 + q2 * 14.0) * k), "%d   %s, %s" % [q2 + 1, String(pl2["name"]), String(pl2["ship"])],
				HORIZONTAL_ALIGNMENT_CENTER, r.size.x * 0.5, fs + 2, Color(pl2["col"]).lightened(0.2))
	if not big and state == "run":                          # (the small screen: the first three in a corner)
		for q3 in 3:
			var pl3: Dictionary = RD.pilot(race, int(st[q3]))
			ci.draw_string(font, Vector2(r.end.x - 62.0 * k, r.position.y + (23.0 + q3 * 8.0) * k), "%d %s" % [q3 + 1, String(pl3["name"]).get_slice(" ", 1)], HORIZONTAL_ALIGNMENT_LEFT, 60.0 * k, fs,
				Color(pl3["col"]).lightened(0.2))
	ci.draw_rect(r, Color(0.3, 0.9, 1.0, 0.8), false, maxf(1.5, k))


static func _odds(o: float) -> String:
	return ("%.1f" % o) if o < 10.0 else ("%d" % int(o))
