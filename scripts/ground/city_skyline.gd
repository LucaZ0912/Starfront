class_name CitySkyline
extends Node2D
## Package 50b (0.7.50.5): what you see from a city's tower bar, high up – the sky in the colour of the planet's air,
## towers far and near with their windows, speeders in their lanes and drones drifting past between them. Layers move
## at their own pace as you walk (the far ones hardly at all).
## 0.7.50.6: built in the city's style (CityStyle – independent, Assembly, Covenant, Directorate) and lit by its time
## of day: at night the windows and neon glow and red lights blink on the tops; by day the towers stand in the sun,
## their glass catching the sky, a few lights still on.
## 0.7.50.8: the day goes on while you sit there (set_day) – at dusk the sky turns to the colour of the star's
## setting light, the sun sinks behind the towers on the west (or rises in the east), and the windows come on one by
## one; at dawn the other way round.

const P := 3.0                          # one art pixel

var size := Vector2(1600, 400)
var style: Dictionary = CityStyle.STYLES["independent"]
var day := 0.0
var _rng := RandomNumberGenerator.new()
var _sky_top := Color(0.03, 0.03, 0.08)
var _sky_low := Color(0.3, 0.2, 0.25)
var _layers: Array = []                 # [node, towers, depth]
var _traffic: Node2D
var _speeders: Array = []               # [lane y, x, speed, size, colour]
var _drones: Array = []                 # [x, y, phase, speed]
var _beacons: Array = []                # [layer index, pos]
var _t := 0.0
var _scroll := 0.0
var _span := 4000.0
const PAR := [0.92, 0.78, 0.55]
var body: Dictionary = {}
var star_col := Color(1.0, 0.85, 0.5)
var sunset := Color(1.0, 0.45, 0.2)
var rising := false
var _sky: Node2D
var _sun: Node2D


func setup(p_size: Vector2, p_body: Dictionary, seed_v: int, span: float = 4000.0, p_style: Dictionary = {}, p_day: float = 0.0, p_star: Color = Color(1.0, 0.85, 0.5), p_rising: bool = false) -> void:
	size = p_size
	body = p_body
	_span = maxf(span, size.x + 400.0)
	_rng.seed = seed_v
	if not p_style.is_empty():
		style = p_style
	star_col = p_star
	sunset = CityStyle.sunset_color(star_col)
	rising = p_rising
	day = p_day
	_set_sky()
	var sky := Node2D.new()
	sky.draw.connect(_draw_sky.bind(sky))
	add_child(sky)
	_sky = sky
	_sun = Node2D.new()                                   # the sun, far away – behind all the towers
	_sun.draw.connect(_draw_sun)
	add_child(_sun)
	for d in 3:
		var node := Node2D.new()
		var towers := _make_towers(d)
		node.draw.connect(_draw_layer.bind(node, towers, d))
		add_child(node)
		_layers.append([node, towers, d])
		if d == 1:
			_traffic = Node2D.new()                       # the speeders fly between the far and the near towers
			_traffic.draw.connect(_draw_traffic)
			add_child(_traffic)
	var neon: Array = style["neon"]
	for i in 22:
		var lane: float = [0.3, 0.46, 0.62, 0.78][i % 4]
		_speeders.append([size.y * lane + _rng.randf_range(-6, 6), _rng.randf_range(-200.0, _span), _rng.randf_range(70.0, 190.0) * (1.0 if i % 2 == 0 else -1.0),
			lerpf(1.4, 2.6, lane), neon[i % neon.size()]])
	for j in 10:
		_drones.append([_rng.randf_range(0.0, _span), _rng.randf_range(size.y * 0.15, size.y * 0.75), _rng.randf() * TAU, _rng.randf_range(16.0, 40.0) * (1.0 if j % 2 == 0 else -1.0)])


func _set_sky() -> void:
	var sk: Array = CityStyle.sky(body, day, sunset)
	_sky_top = sk[0]
	_sky_low = sk[1]


## 0.7.50.8: the time of day changes – everything outside is drawn anew in its light.
func set_day(d: float, p_rising: bool) -> void:
	if absf(d - day) < 0.004 and p_rising == rising:
		return
	day = d
	rising = p_rising
	_set_sky()
	if _sky != null:
		_sky.queue_redraw()
	if _sun != null:
		_sun.queue_redraw()
	for l in _layers:
		(l[0] as Node2D).queue_redraw()


## A tower's colour in the light of now: its style's tone, far ones fading into the air, at dusk lit by the sunset.
func _tower_col(t: Dictionary, d: int) -> Color:
	var fade_k: float = [0.38, 0.16, 0.02][d] if day < 0.5 else [0.5, 0.25, 0.05][d]
	var base := CityStyle.tone(style, "tower", day).lerp(_sky_low, fade_k)
	return base.lightened(float(t["l"])).darkened(float(t["dk"]))


func _draw_sun() -> void:
	# up by day, low and big at dusk, below the horizon at night; in the west when it sets, the east when it rises
	if day <= 0.02:
		return
	var dk := CityStyle.dusk(day)
	var y := size.y * (1.08 - 0.8 * day)                    # at the change it touches the towers' tops
	var x := size.x * (0.82 if rising else 0.18)
	var p := Vector2(x, y)
	var col := star_col.lerp(Color.WHITE, 0.4).lerp(sunset, dk)
	var r := lerpf(26.0, 40.0, dk)
	for g in 4:
		_sun.draw_circle(p, r * (4.5 - g), Color(col, (0.05 + 0.04 * g) * (0.5 + dk)))
	_sun.draw_circle(p, r, col.lerp(Color.WHITE, 0.35))
	_sun.draw_circle(p, r * 0.7, col.lerp(Color.WHITE, 0.7))
	# at dusk a band of light along the horizon
	if dk > 0.05:
		_sun.draw_rect(Rect2(-200.0 + -position.x, size.y * 0.62, _span + 400.0, size.y * 0.4), Color(sunset, 0.18 * dk))


## Towers of one depth: 0 far, 1 middle, 2 near.
func _make_towers(d: int) -> Array:
	var out: Array = []
	var x := -120.0
	var grid: bool = style["grid"]
	var crowns: Array = style["crowns"]
	var neon: Array = style["neon"]
	while x < _span:
		var w := _rng.randf_range([36.0, 60.0, 110.0][d], [70.0, 130.0, 220.0][d])
		if grid:
			w = [48.0, 90.0, 160.0][d] + float(_rng.randi() % 2) * [12.0, 24.0, 36.0][d]
		var top := size.y * _rng.randf_range([0.18, 0.3, 0.5][d], [0.55, 0.7, 0.9][d])
		if d == 2 and _rng.randf() < 0.45:
			x += w + _rng.randf_range(120.0, 360.0)        # the near ones stand apart – you see past them
			continue
		var t := {"x": snappedf(x, P), "w": snappedf(w, P), "top": snappedf(top, P), "l": _rng.randf_range(0.0, 0.06), "dk": _rng.randf_range(0.0, 0.08),
			"seed": _rng.randi(), "neon": _rng.randf() < float(style["neon_share"][d]), "ncol": neon[_rng.randi() % neon.size()],
			"crown": String(crowns[_rng.randi() % crowns.size()]), "green": _rng.randf() < float(style["green"])}
		out.append(t)
		if d < 2 or t["crown"] in ["antenna", "spire"]:
			_beacons.append([d, Vector2(t["x"] + t["w"] * 0.5, t["top"] - _crown_h(t))])
		x += w + (_rng.randf_range([-10.0, 10.0, 60.0][d], [20.0, 70.0, 160.0][d]) if not grid else [12.0, 30.0, 90.0][d])
	return out


func _crown_h(t: Dictionary) -> float:
	match String(t["crown"]):
		"antenna":
			return 18.0
		"spire":
			return float(t["w"]) * 1.1
		"dome", "round":
			return float(t["w"]) * 0.45
		"gothic":
			return float(t["w"]) * 0.5
		"hex":
			return float(t["w"]) * 0.2
	return 0.0


## The camera's offset in the world (screen px): the layers keep nearly still on the screen, the far ones most.
func scroll(off_x: float) -> void:
	_scroll = off_x
	for l in _layers:
		(l[0] as Node2D).position.x = round(-off_x * PAR[int(l[2])])
	if _sun != null:
		_sun.position.x = round(-off_x * 0.97)
	if _traffic != null:
		_traffic.position.x = round(-off_x * 0.7)


func _process(delta: float) -> void:
	_t += delta
	for s in _speeders:
		s[1] = float(s[1]) + float(s[2]) * delta
		if float(s[1]) > _span:
			s[1] = -200.0
		elif float(s[1]) < -200.0:
			s[1] = _span
	for d in _drones:
		d[0] = fposmod(float(d[0]) + float(d[3]) * delta, _span)
	if _traffic != null:
		_traffic.queue_redraw()


func _draw_sky(n: Node2D) -> void:
	var bands := 24
	for i in bands:
		var k := float(i) / (bands - 1)
		n.draw_rect(Rect2(0, size.y * i / bands, size.x, size.y / bands + 1.0), _sky_top.lerp(_sky_low, pow(k, 1.6)))
	var sr := RandomNumberGenerator.new()
	sr.seed = 77
	if day < 0.6:
		for s in 60:
			var p := Vector2(sr.randf() * size.x, sr.randf() * size.y * 0.45)
			n.draw_rect(Rect2(p.snapped(Vector2(P, P)), Vector2(P, P)), Color(1, 1, 1, sr.randf_range(0.15, 0.5) * (1.0 - day / 0.6)))
	else:
		# a few clouds drifting high up, and the sun's glare low on one side
		for c in 6:
			var cp := Vector2(sr.randf() * size.x, sr.randf_range(0.08, 0.35) * size.y)
			for b in 4:
				var cw := snappedf(sr.randf_range(40.0, 90.0), P)
				n.draw_rect(Rect2((cp + Vector2(b * 22.0 - 30.0, (b % 2) * 6.0)).snapped(Vector2(P, P)), Vector2(cw, P * 3)), Color(1, 1, 1, 0.22 * day))
		n.draw_circle(Vector2(size.x * 0.12, size.y * 0.55), size.y * 0.5, Color(1.0, 0.95, 0.8, 0.12 * day))
	# the city's glow (at night) or haze (by day) over the horizon
	n.draw_rect(Rect2(0, size.y * 0.75, size.x, size.y * 0.25), Color(1.0, 0.55, 0.3, 0.1 * (1.0 - day)) if day < 0.5 else Color(_sky_low, 0.25))


func _draw_layer(n: Node2D, towers: Array, d: int) -> void:
	var r := RandomNumberGenerator.new()
	var wins: Array = style["win"]
	var warm: float = style["warm"]
	var lit_share: float = float(style["lit"]) * lerpf(1.0, 0.18, day)
	var grid: bool = style["grid"]
	var sign_kind := String(style["sign"])
	for t in towers:
		r.seed = int(t["seed"])
		var x: float = t["x"]
		var w: float = t["w"]
		var top: float = t["top"]
		var col := _tower_col(t, d)
		var h := size.y - top + 40.0
		var lit_edge := col.lightened(0.12 + 0.18 * day).lerp(sunset, CityStyle.dusk(day) * 0.5)
		n.draw_rect(Rect2(x, top, w, h), col)
		# the side the light falls on (the sun by day is low on the left)
		n.draw_rect(Rect2(x, top, P * (1 if d == 0 else 2), h), lit_edge)
		n.draw_rect(Rect2(x + w - P * 2, top, P * 2, h), col.darkened(0.3))
		_draw_crown(n, t, col, lit_edge, d)
		# windows
		var cell: float = [P * 2, P * 3, P * 4][d]
		var yy: float = top + cell
		var row := 0
		var ww: float = P * (1 if d == 0 else 2) * (0.67 if d == 0 else 1.0)
		var wh: float = P * (1 if d < 2 else 2)
		while yy < size.y + 20.0:
			var xx: float = x + cell * 0.5 + P
			# the Directorate: whole floors lit evenly; the others: window by window
			var row_lit := r.randf() < lit_share * 1.3 if grid else true
			while xx < x + w - cell * 0.5 - P:
				var rv := r.randf()
				var on := row_lit and rv < (0.85 if grid else lit_share)
				if on:
					var wc: Color = wins[0] if r.randf() < warm else wins[1]
					n.draw_rect(Rect2(snappedf(xx, P), snappedf(yy, P), ww, wh), Color(wc, [0.45, 0.65, 0.85][d] * lerpf(1.0, 0.5, day)))
				elif day > 0.3:
					# glass catching the sky
					n.draw_rect(Rect2(snappedf(xx, P), snappedf(yy, P), ww, wh), Color(_sky_top.lightened(0.3), 0.35 * day * [0.5, 0.8, 1.0][d]))
				xx += cell
			# Assembly: green balconies every few floors
			if t["green"] and d > 0 and row % 4 == 2:
				n.draw_rect(Rect2(x + P, snappedf(yy + P * 2, P), w - P * 2, P), Color(0.25, 0.55, 0.28))
				for g in int(w / (P * 4)):
					if r.randf() < 0.6:
						n.draw_rect(Rect2(x + P * 2 + g * P * 4, snappedf(yy, P), P * 2, P * 2), Color(0.3, 0.62, 0.32))
			# Directorate: a green light band every few floors
			if sign_kind == "band" and t["neon"] and row % 5 == 0:
				var bc: Color = t["ncol"]
				n.draw_rect(Rect2(x, snappedf(yy - P, P), w, P), Color(bc, lerpf(0.9, 0.5, day)))
			yy += cell * 1.3
			row += 1
		# a neon sign running down it, or the Covenant's banners
		if t["neon"] and d > 0:
			var nc: Color = t["ncol"]
			var nx := x + w * 0.2
			var nh: float = minf(h * 0.6, [30.0, 70.0, 140.0][d])
			if sign_kind == "vertical":
				n.draw_rect(Rect2(nx - P * 2, top + 20.0, P * 4, nh), Color(nc, 0.18 * (1.0 - day * 0.7)))
				n.draw_rect(Rect2(nx - P * 0.5, top + 20.0, P, nh), Color(nc.lerp(Color.WHITE, 0.4), lerpf(0.9, 0.55, day)))
			elif sign_kind == "banner":
				var bw := maxf(P * 3, snappedf(w * 0.18, P))
				for side in 2:
					var bx := x + (w * 0.22 if side == 0 else w * 0.78 - bw)
					n.draw_rect(Rect2(bx, top + 14.0, bw, nh), Color(0.62, 0.08, 0.12))
					n.draw_colored_polygon(PackedVector2Array([Vector2(bx, top + 14.0 + nh), Vector2(bx + bw, top + 14.0 + nh), Vector2(bx + bw * 0.5, top + 14.0 + nh - bw * 0.6)]), col)
					n.draw_rect(Rect2(bx + bw * 0.5 - P * 0.5, top + 24.0, P, P * 3), Color(1.0, 0.8, 0.3))
					n.draw_rect(Rect2(bx + bw * 0.5 - P * 1.5, top + 24.0 + P, P * 3, P), Color(1.0, 0.8, 0.3))
	# a haze over the far ones
	if d == 0:
		n.draw_rect(Rect2(-200.0, 0, _span + 400.0, size.y), Color(_sky_low, 0.18 + 0.12 * day))


## The tower's top, in its style.
func _draw_crown(n: Node2D, t: Dictionary, col: Color, lit: Color, d: int) -> void:
	var x: float = t["x"]
	var w: float = t["w"]
	var top: float = t["top"]
	match String(t["crown"]):
		"antenna":
			n.draw_rect(Rect2(x + w * 0.5 - P * 0.5, top - 18.0, P, 18.0), col.lightened(0.1))
		"step":
			n.draw_rect(Rect2(x + w * 0.15, top - P * 3, w * 0.7, P * 3), col)
			n.draw_rect(Rect2(x + w * 0.3, top - P * 6, w * 0.4, P * 3), col)
		"spire":
			var sh := w * 1.1
			n.draw_colored_polygon(PackedVector2Array([Vector2(x, top), Vector2(x + w * 0.5, top - sh), Vector2(x + w, top)]), col)
			n.draw_colored_polygon(PackedVector2Array([Vector2(x, top), Vector2(x + w * 0.5, top - sh), Vector2(x + w * 0.3, top)]), lit)
			n.draw_rect(Rect2(x + w * 0.5 - P * 0.5, top - sh - P * 3, P, P * 3), Color(1.0, 0.8, 0.3))
			for cx in [x, x + w - P * 2]:                  # small pinnacles at the corners
				n.draw_colored_polygon(PackedVector2Array([Vector2(cx, top), Vector2(cx + P, top - P * 6), Vector2(cx + P * 2, top)]), col)
		"gothic":
			n.draw_rect(Rect2(x + w * 0.1, top - w * 0.25, w * 0.8, w * 0.25), col)
			n.draw_colored_polygon(PackedVector2Array([Vector2(x + w * 0.1, top - w * 0.25), Vector2(x + w * 0.5, top - w * 0.5), Vector2(x + w * 0.9, top - w * 0.25)]), col)
			n.draw_circle(Vector2(x + w * 0.5, top - w * 0.2), w * 0.09, Color(1.0, 0.75, 0.35, lerpf(0.9, 0.5, day)))     # a rose window
		"dome":
			n.draw_circle(Vector2(x + w * 0.5, top), w * 0.45, col)
			n.draw_circle(Vector2(x + w * 0.38, top - w * 0.12), w * 0.18, Color(lit, 0.6))
			if t["green"]:
				n.draw_rect(Rect2(x + P, top - P * 2, w - P * 2, P * 2), Color(0.3, 0.6, 0.32))
		"round":
			n.draw_circle(Vector2(x + w * 0.5, top + w * 0.05), w * 0.5, col)
			n.draw_rect(Rect2(x + w * 0.2, top - w * 0.42, w * 0.6, P), Color(style["accent"], 0.6))
		"terrace":
			for s in 3:
				var tw := w * (0.8 - s * 0.22)
				var tx := x + (w - tw) * 0.5
				n.draw_rect(Rect2(tx, top - (s + 1) * P * 4, tw, P * 4), col)
				n.draw_rect(Rect2(tx, top - (s + 1) * P * 4, tw, P), Color(0.3, 0.6, 0.3))
		"hex":
			var ch := w * 0.2
			n.draw_colored_polygon(PackedVector2Array([Vector2(x, top), Vector2(x + ch, top - ch), Vector2(x + w - ch, top - ch), Vector2(x + w, top)]), col)
			n.draw_rect(Rect2(x + ch, top - ch, w - ch * 2, P), Color(style["accent"], lerpf(0.8, 0.4, day)))
			if d > 0:                                       # solar panels catching the light
				n.draw_rect(Rect2(x + ch + P, top - ch + P * 2, w - ch * 2 - P * 2, P), Color(0.3, 0.45, 0.7))
		_:
			n.draw_rect(Rect2(x - P, top, w + P * 2, P), col.lightened(0.18))


func _draw_traffic() -> void:
	# the red lights on the towers' tops, blinking (at night)
	if day < 0.7:
		for b in _beacons:
			var on := fposmod(_t * 0.7 + float((b[1] as Vector2).x) * 0.013, 1.4) < 0.3
			if not on:
				continue
			var bp: Vector2 = b[1]
			var lpos := bp + Vector2(-_scroll * (float(PAR[int(b[0])]) - 0.7), 0)
			_traffic.draw_circle(lpos, 6.0, Color(1.0, 0.2, 0.15, 0.3 * (1.0 - day)))
			_traffic.draw_rect(Rect2(lpos - Vector2(P, P) * 0.5, Vector2(P, P)), Color(1.0, 0.3, 0.25))
	var body := Color(0.12, 0.13, 0.17).lerp(Color(0.55, 0.58, 0.64), day)
	for s in _speeders:
		var p := Vector2(float(s[1]), float(s[0]))
		var sz: float = s[3]
		var dir := signf(float(s[2]))
		var c: Color = s[4]
		# its light trail (at night), its body, its headlight and tail light
		if day < 0.6:
			_traffic.draw_rect(Rect2(p.x - dir * 40.0 * sz if dir > 0 else p.x, p.y, 40.0 * sz, P * 0.67), Color(c, 0.18 * (1.0 - day)))
		_traffic.draw_rect(Rect2(p - Vector2(5, 2) * sz, Vector2(10, 4) * sz), body)
		_traffic.draw_rect(Rect2(p + Vector2(-5 * sz, -2 * sz), Vector2(10, 1) * sz), body.lightened(0.25))
		_traffic.draw_rect(Rect2(p + Vector2(-5 * sz, 1 * sz), Vector2(10, 1) * sz), Color(c, 0.9))
		_traffic.draw_rect(Rect2(p + Vector2(dir * 5 * sz - (0.0 if dir > 0 else P), -1 * sz), Vector2(P, P)), Color(1, 1, 0.9))
		if day < 0.6:
			_traffic.draw_circle(p + Vector2(dir * 9 * sz, 0), 5.0 * sz, Color(1, 1, 0.85, 0.15))
		_traffic.draw_rect(Rect2(p + Vector2(-dir * 5 * sz - (P if dir > 0 else 0.0), -1 * sz), Vector2(P, P)), Color(1.0, 0.25, 0.2))
	for d in _drones:
		var dp := Vector2(float(d[0]), float(d[1]) + sin(_t * 1.3 + float(d[2])) * 12.0).snapped(Vector2(P, P))
		_traffic.draw_rect(Rect2(dp - Vector2(P * 2, P * 0.5), Vector2(P * 4, P)), Color(0.25, 0.27, 0.32).lerp(Color(0.45, 0.47, 0.52), day))
		_traffic.draw_rect(Rect2(dp - Vector2(P * 2, P * 1.5), Vector2(P, P)), Color(0.4, 0.42, 0.48))
		_traffic.draw_rect(Rect2(dp + Vector2(P, -P * 1.5), Vector2(P, P)), Color(0.4, 0.42, 0.48))
		if fposmod(_t * 1.5 + float(d[2]), 1.0) < 0.5:
			_traffic.draw_rect(Rect2(dp + Vector2(-P, -P), Vector2(P, P) * 0.67), Color(0.3, 1.0, 0.5))
		if day < 0.6:
			_traffic.draw_circle(dp + Vector2(0, P), 4.0, Color(0.6, 0.9, 1.0, 0.25))
