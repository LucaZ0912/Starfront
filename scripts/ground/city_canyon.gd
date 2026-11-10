class_name CityCanyon
extends Node2D
## 0.7.50.6 (Luz: "the street feels like a room – make it a street canyon"): above the shop fronts on the north side
## of a city's shopping street the buildings rise up into the sky – storey on storey of windows, balconies, fire
## escapes, air units, signs and banners in the city's style – and only a strip of sky is left at the top, speeders
## crossing it. Strings of lights hang along the street. Day or night by where the city lies.

const P := 3.0

var size := Vector2(1600, 600)
var style: Dictionary = CityStyle.STYLES["independent"]
var day := 0.0
var _blds: Array = []
var _sky_top := Color.BLACK
var _sky_low := Color.BLACK
var _sky_h := 90.0
var _static: Node2D
var _moving: Node2D
var _speeders: Array = []
var _t := 0.0


func setup(p_size: Vector2, body: Dictionary, p_style: Dictionary, p_day: float, seed_v: int) -> void:
	size = p_size
	style = p_style
	day = p_day
	var sk: Array = CityStyle.sky(body, day)
	_sky_top = sk[0]
	_sky_low = sk[1]
	_sky_h = snappedf(size.y * 0.2, P)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var x := 0.0
	var crowns: Array = style["crowns"]
	var neon: Array = style["neon"]
	var grid: bool = style["grid"]
	while x < size.x:
		var w := snappedf((rng.randf_range(4.0, 9.0) if not grid else 6.0) * 48.0, P)
		var top := snappedf(_sky_h * rng.randf_range(0.15, 1.0), P)
		if grid:
			top = snappedf(_sky_h * [0.3, 0.6][int(x / w) % 2], P)
		var face := CityStyle.tone(style, "facade", day)
		face = face.lightened(rng.randf_range(0.0, 0.07)).darkened(rng.randf_range(0.0, 0.1))
		_blds.append({"x": x, "w": w, "top": top, "face": face, "seed": rng.randi(), "crown": String(crowns[rng.randi() % crowns.size()]),
			"neon": rng.randf() < float(style["neon_share"][2]) + (0.45 if String(style["sign"]) == "banner" else 0.15), "ncol": neon[rng.randi() % neon.size()], "green": rng.randf() < float(style["green"]),
			"escape": rng.randf() < 0.5})
		x += w
	for i in 6:
		_speeders.append([rng.randf_range(0.0, size.x), rng.randf_range(_sky_h * 0.15, _sky_h * 0.75), rng.randf_range(60.0, 160.0) * (1.0 if i % 2 == 0 else -1.0), neon[i % neon.size()]])
	_static = Node2D.new()
	_static.draw.connect(_draw_static)
	add_child(_static)
	_moving = Node2D.new()
	_moving.draw.connect(_draw_moving)
	add_child(_moving)


func _process(delta: float) -> void:
	_t += delta
	for s in _speeders:
		s[0] = fposmod(float(s[0]) + float(s[2]) * delta, size.x + 200.0)
	_moving.queue_redraw()


func _draw_static() -> void:
	var n := _static
	# the strip of sky between the tops
	var bands := 10
	for i in bands:
		n.draw_rect(Rect2(0, _sky_h * i / bands, size.x, _sky_h / bands + 1.0), _sky_top.lerp(_sky_low, float(i) / bands))
	# far towers in the gap, faint
	var fr := RandomNumberGenerator.new()
	fr.seed = 5
	var fx := 0.0
	var far := CityStyle.tone(style, "tower", day).lerp(_sky_low, 0.5)
	while fx < size.x:
		var fw := fr.randf_range(30.0, 70.0)
		var ft := _sky_h * fr.randf_range(0.2, 0.7)
		n.draw_rect(Rect2(snappedf(fx, P), snappedf(ft, P), snappedf(fw, P), _sky_h), far)
		fx += fw + fr.randf_range(4.0, 30.0)
	var wins: Array = style["win"]
	var lit: float = float(style["lit"]) * lerpf(0.75, 0.15, day)
	var sign_kind := String(style["sign"])
	for b in _blds:
		var r := RandomNumberGenerator.new()
		r.seed = int(b["seed"])
		var x: float = b["x"]
		var w: float = b["w"]
		var top: float = b["top"]
		var face: Color = b["face"]
		n.draw_rect(Rect2(x, top, w, size.y - top), face)
		n.draw_rect(Rect2(x, top, P * 2, size.y - top), face.lightened(0.1 + 0.1 * day))
		n.draw_rect(Rect2(x + w - P * 2, top, P * 2, size.y - top), face.darkened(0.3))
		_crown(n, b)
		# storeys of windows
		var y := top + 18.0
		var floor_n := 0
		var covenant := sign_kind == "banner"
		while y < size.y - 40.0:
			var row_on := r.randf() < lit * 1.3 if style["grid"] else true
			var wx := x + 12.0
			while wx < x + w - 24.0:
				var on := row_on and r.randf() < (0.85 if style["grid"] else lit)
				var wc: Color = wins[0] if r.randf() < float(style["warm"]) else wins[1]
				var wr := Rect2(wx, y, 12.0, 15.0)
				n.draw_rect(wr.grow(P * 0.67), face.darkened(0.25))
				n.draw_rect(wr, Color(wc, lerpf(0.72, 0.5, day)) if on else face.darkened(0.45).lerp(_sky_top.lightened(0.35), 0.5 * day))
				if covenant:                                   # pointed arches over the windows
					n.draw_colored_polygon(PackedVector2Array([wr.position, Vector2(wr.position.x + 6.0, wr.position.y - 6.0), Vector2(wr.end.x, wr.position.y)]), face.darkened(0.25))
				if on and day < 0.5 and r.randf() < 0.3:          # someone's curtain, a plant on the sill
					n.draw_rect(Rect2(wx, y, 4.0, 15.0), Color(wc.darkened(0.4), 0.8))
				wx += 24.0
			# balconies, fire escapes, air units
			if b["green"] and floor_n % 2 == 1:
				n.draw_rect(Rect2(x + 6.0, y + 17.0, w - 12.0, P), face.lightened(0.2))
				for g in int((w - 12.0) / 12.0):
					if r.randf() < 0.7:
						n.draw_rect(Rect2(x + 8.0 + g * 12.0, y + 11.0, 8.0, 6.0), Color(0.28, 0.58, 0.3).lerp(Color(0.4, 0.7, 0.35), day))
			elif style.get("escapes", false) and b["escape"]:
				var ex := x + w * 0.62
				n.draw_rect(Rect2(ex, y + 17.0, 46.0, P), Color(0.12, 0.12, 0.14))           # the landing
				var flip := floor_n % 2 == 0
				n.draw_line(Vector2(ex + (0.0 if flip else 46.0), y + 18.0), Vector2(ex + (46.0 if flip else 0.0), y - 12.0), Color(0.14, 0.14, 0.16), 2.0)
			if r.randf() < 0.25 and sign_kind != "band":
				n.draw_rect(Rect2(x + r.randf_range(10.0, w - 30.0), y + 18.0, 15.0, 9.0), face.darkened(0.15).lightened(0.05))   # an air unit
			if sign_kind == "band" and b["neon"] and floor_n % 3 == 0:
				n.draw_rect(Rect2(x, y - 6.0, w, P), Color(b["ncol"], lerpf(0.9, 0.45, day)))
			y += 32.0
			floor_n += 1
		# the street's light falling up the lowest storeys at night – or the canyon's shade by day
		var shade_h := 120.0
		for k in 8:
			var a := (1.0 - k / 8.0)
			if day < 0.5:
				n.draw_rect(Rect2(x, size.y - shade_h * (k + 1) / 8.0, w, shade_h / 8.0), Color(1.0, 0.7, 0.4, 0.05 * a * (1.0 - day)))
			else:
				n.draw_rect(Rect2(x, size.y - shade_h * 2.0 * (k + 1) / 8.0, w, shade_h * 2.0 / 8.0), Color(0.05, 0.06, 0.12, 0.06 * a * day))
		# signs: a tall neon board, the Covenant's banners
		if b["neon"]:
			var nc: Color = b["ncol"]
			if sign_kind == "vertical" and style.get("escapes", false):
				var sx := x + 20.0
				var sh := minf(size.y - top - 80.0, 220.0)
				var sy := size.y - 60.0 - sh
				n.draw_rect(Rect2(sx - 6, sy - 6, 36, sh + 12), Color(nc, 0.12 * (1.0 - day * 0.6)))
				n.draw_rect(Rect2(sx, sy, 24, sh), Color(0.04, 0.04, 0.06))
				n.draw_rect(Rect2(sx, sy, 24, sh), Color(nc, lerpf(0.95, 0.6, day)), false, 2.0)
				var gy := sy + 8.0
				while gy < sy + sh - 14.0:                     # glyphs, one under the other
					var gw := r.randi_range(2, 4)
					for gk in gw:
						n.draw_rect(Rect2(sx + 5 + gk * 4, gy + r.randi_range(0, 6), 3, r.randi_range(3, 8)), Color(nc.lerp(Color.WHITE, 0.45), lerpf(0.95, 0.6, day)))
					gy += 18.0
			elif sign_kind == "banner":
				var bh := minf(size.y - top - 110.0, 190.0)
				var by := size.y - 100.0 - bh                    # low enough to be seen from the street
				for bx in [x + w * 0.2, x + w * 0.7]:
					n.draw_rect(Rect2(bx, by, 22.0, bh), Color(0.62, 0.08, 0.12))
					n.draw_rect(Rect2(bx + 2.0, by, 2.0, bh), Color(0.78, 0.16, 0.18))
					n.draw_colored_polygon(PackedVector2Array([Vector2(bx, by + bh), Vector2(bx + 22.0, by + bh), Vector2(bx + 11.0, by - 12.0 + bh)]), face)
					n.draw_rect(Rect2(bx + 9.0, by + 14.0, 4.0, 18.0), Color(1.0, 0.8, 0.3))
					n.draw_rect(Rect2(bx + 4.0, by + 20.0, 14.0, 4.0), Color(1.0, 0.8, 0.3))
					n.draw_rect(Rect2(bx - 2.0, by - 2.0, 26.0, 3.0), Color(0.35, 0.3, 0.2))
	# strings of lights along the street, sagging between the buildings
	var string_kind := String(style["string"])
	var sy0 := size.y - 70.0
	var sx0 := 0.0
	var sr := RandomNumberGenerator.new()
	sr.seed = 9
	while sx0 < size.x:
		var span := sr.randf_range(180.0, 300.0)
		var pts := PackedVector2Array()
		for k2 in 13:
			var u := k2 / 12.0
			pts.append(Vector2(sx0 + span * u, sy0 + sin(u * PI) * 26.0))
		if string_kind != "holo":
			n.draw_polyline(pts, Color(0.08, 0.08, 0.1), 2.0)
		for k3 in range(1, 12):
			var lp := pts[k3]
			match string_kind:
				"lanterns":
					var lc: Color = (style["neon"] as Array)[k3 % (style["neon"] as Array).size()]
					n.draw_rect(Rect2(lp + Vector2(-4, 2), Vector2(8, 10)), Color(lc, 0.9))
					n.draw_circle(lp + Vector2(0, 7), 10.0, Color(lc, 0.15 * (1.0 - day * 0.7)))
				"bulbs":
					n.draw_circle(lp + Vector2(0, 3), 3.0, Color(1.0, 0.9, 0.65, lerpf(1.0, 0.6, day)))
					n.draw_circle(lp + Vector2(0, 3), 9.0, Color(1.0, 0.85, 0.5, 0.15 * (1.0 - day * 0.7)))
				"pennants":
					var pc := Color(0.7, 0.1, 0.14) if k3 % 2 == 0 else Color(1.0, 0.8, 0.3)
					n.draw_colored_polygon(PackedVector2Array([lp, lp + Vector2(10, 0), lp + Vector2(5, 14)]), pc)
				"holo":
					if k3 % 3 == 0:
						n.draw_rect(Rect2(lp + Vector2(-1, -2), Vector2(2, 4)), Color(style["accent"], 0.8))
		if string_kind == "holo":
			n.draw_polyline(pts, Color(style["accent"], lerpf(0.5, 0.25, day)), 2.0)
		sx0 += span


func _crown(n: Node2D, b: Dictionary) -> void:
	var x: float = b["x"]
	var w: float = b["w"]
	var top: float = b["top"]
	var face: Color = b["face"]
	match String(b["crown"]):
		"spire", "gothic":
			n.draw_colored_polygon(PackedVector2Array([Vector2(x, top), Vector2(x + w * 0.5, top - 40.0), Vector2(x + w, top)]), face)
			n.draw_circle(Vector2(x + w * 0.5, top - 4.0), 10.0, Color(1.0, 0.75, 0.35, lerpf(0.9, 0.5, day)))
		"dome", "round":
			n.draw_rect(Rect2(x + 6.0, top - 6.0, w - 12.0, 6.0), face.lightened(0.1))
		"terrace":
			n.draw_rect(Rect2(x, top - 6.0, w, 6.0), Color(0.3, 0.58, 0.32))
		"hex":
			n.draw_rect(Rect2(x, top, w, P), Color(style["accent"], 0.7))
		"antenna":
			n.draw_rect(Rect2(x + w * 0.7, top - 24.0, P, 24.0), face.lightened(0.15))
		_:
			n.draw_rect(Rect2(x, top - P, w, P), face.lightened(0.2))


func _draw_moving() -> void:
	for s in _speeders:
		var p := Vector2(float(s[0]) - 100.0, float(s[1]))
		var dir := signf(float(s[2]))
		var body := Color(0.12, 0.13, 0.17).lerp(Color(0.55, 0.58, 0.64), day)
		if day < 0.6:
			_moving.draw_rect(Rect2(p.x - (36.0 if dir > 0 else -12.0), p.y + 2.0, 36.0, 2.0), Color(s[3], 0.25))
		_moving.draw_rect(Rect2(p - Vector2(12, 4), Vector2(24, 8)), body)
		_moving.draw_rect(Rect2(p + Vector2(-12, 2), Vector2(24, 2)), Color(s[3], 0.9))
		_moving.draw_rect(Rect2(p + Vector2(dir * 10.0 - 2.0, -2), Vector2(4, 3)), Color(1, 1, 0.9))
	# now and then a light goes out, comes on
	if day < 0.5 and fposmod(_t, 3.0) < 0.15:
		_moving.draw_rect(Rect2(fposmod(_t * 137.0, size.x), size.y * 0.5, 12.0, 15.0), Color(0, 0, 0, 0.5))
