class_name CitySkyline
extends Node2D
## Package 50b (0.7.50.5): what you see from a city's tower bar, high up – the night sky in the colour of the
## planet's air, the city's glow on the horizon, towers far and near with their lit windows and neon, red lights
## blinking on their tops; speeders in their lanes and drones drifting past between them. Layers move at their own
## pace as you walk (the far ones hardly at all).

const P := 3.0                          # one art pixel

var size := Vector2(1600, 400)
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


func setup(p_size: Vector2, body: Dictionary, seed_v: int, span: float = 4000.0) -> void:
	size = p_size
	_span = maxf(span, size.x + 400.0)
	_rng.seed = seed_v
	var bt := Universe.body_type(String(body.get("type", "")))
	var ac = bt.get("atmo", Color(0.5, 0.7, 1.0))
	var air: Color = ac if ac is Color else Color(0.5, 0.7, 1.0)
	_sky_top = Color(0.02, 0.025, 0.07).lerp(Color(air.r, air.g, air.b), 0.08)
	_sky_low = Color(air.r, air.g, air.b).darkened(0.55).lerp(Color(1.0, 0.5, 0.3), 0.35)
	var sky := Node2D.new()
	sky.draw.connect(_draw_sky.bind(sky))
	add_child(sky)
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
	for i in 22:
		var lane: float = [0.3, 0.46, 0.62, 0.78][i % 4]
		_speeders.append([size.y * lane + _rng.randf_range(-6, 6), _rng.randf_range(-200.0, _span), _rng.randf_range(70.0, 190.0) * (1.0 if i % 2 == 0 else -1.0),
			lerpf(1.4, 2.6, lane), [Color(0.3, 0.95, 1.0), Color(1.0, 0.35, 0.7), Color(1.0, 0.85, 0.5), Color(0.6, 0.5, 1.0)][i % 4]])
	for j in 10:
		_drones.append([_rng.randf_range(0.0, _span), _rng.randf_range(size.y * 0.15, size.y * 0.75), _rng.randf() * TAU, _rng.randf_range(16.0, 40.0) * (1.0 if j % 2 == 0 else -1.0)])


## Towers of one depth: 0 far, 1 middle, 2 near.
func _make_towers(d: int) -> Array:
	var out: Array = []
	var x := -120.0
	while x < _span:
		var w := _rng.randf_range([36.0, 60.0, 110.0][d], [70.0, 130.0, 220.0][d])
		var top := size.y * _rng.randf_range([0.18, 0.3, 0.5][d], [0.55, 0.7, 0.9][d])
		if d == 2 and _rng.randf() < 0.45:
			x += w + _rng.randf_range(120.0, 360.0)        # the near ones stand apart – you see past them
			continue
		var base := Color(0.05, 0.06, 0.1).lerp(_sky_low, [0.28, 0.12, 0.02][d])
		var t := {"x": snappedf(x, P), "w": snappedf(w, P), "top": snappedf(top, P), "col": base.lightened(_rng.randf_range(0.0, 0.08)),
			"seed": _rng.randi(), "neon": _rng.randf() < [0.1, 0.35, 0.5][d], "ncol": [Color(0.3, 0.95, 1.0), Color(1.0, 0.3, 0.72), Color(0.75, 0.45, 1.0), Color(1.0, 0.75, 0.3)][_rng.randi() % 4],
			"crown": _rng.randi() % 3}
		out.append(t)
		if t["crown"] == 0 or d < 2:
			_beacons.append([d, Vector2(t["x"] + t["w"] * 0.5, t["top"] - (18.0 if t["crown"] == 0 else 0.0))])
		x += w + _rng.randf_range([-10.0, 10.0, 60.0][d], [20.0, 70.0, 160.0][d])
	return out


## The camera's offset in the world (screen px): the layers keep nearly still on the screen, the far ones most.
func scroll(off_x: float) -> void:
	_scroll = off_x
	for l in _layers:
		(l[0] as Node2D).position.x = round(-off_x * [0.92, 0.78, 0.55][int(l[2])])
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
	for s in 60:
		var p := Vector2(sr.randf() * size.x, sr.randf() * size.y * 0.45)
		n.draw_rect(Rect2(p.snapped(Vector2(P, P)), Vector2(P, P)), Color(1, 1, 1, sr.randf_range(0.15, 0.5)))
	# the city's glow over the horizon
	n.draw_rect(Rect2(0, size.y * 0.75, size.x, size.y * 0.25), Color(1.0, 0.55, 0.3, 0.1))


func _draw_layer(n: Node2D, towers: Array, d: int) -> void:
	var r := RandomNumberGenerator.new()
	for t in towers:
		r.seed = int(t["seed"])
		var x: float = t["x"]
		var w: float = t["w"]
		var top: float = t["top"]
		var col: Color = t["col"]
		var h := size.y - top + 40.0
		n.draw_rect(Rect2(x, top, w, h), col)
		n.draw_rect(Rect2(x, top, P, h), col.lightened(0.12))                      # its lit edge
		n.draw_rect(Rect2(x + w - P, top, P, h), col.darkened(0.3))
		# its crown
		match int(t["crown"]):
			0:
				n.draw_rect(Rect2(x + w * 0.5 - P * 0.5, top - 18.0, P, 18.0), col.lightened(0.1))
			1:
				n.draw_rect(Rect2(x + w * 0.15, top - P * 3, w * 0.7, P * 3), col)
				n.draw_rect(Rect2(x + w * 0.3, top - P * 6, w * 0.4, P * 3), col)
			_:
				n.draw_rect(Rect2(x - P, top, w + P * 2, P), col.lightened(0.18))
		# windows: a grid, many of them lit
		var cell: float = [P * 2, P * 3, P * 4][d]
		var lit_share: float = [0.35, 0.4, 0.45][d]
		var yy: float = top + cell
		while yy < size.y + 20.0:
			var xx: float = x + cell * 0.5
			while xx < x + w - cell * 0.5:
				if r.randf() < lit_share:
					var wc: Color = Color(1.0, 0.82, 0.5) if r.randf() < 0.75 else Color(0.6, 0.85, 1.0)
					n.draw_rect(Rect2(snappedf(xx, P), snappedf(yy, P), P * (1 if d == 0 else 2) * (0.67 if d == 0 else 1.0), P * (1 if d < 2 else 2)), Color(wc, [0.45, 0.65, 0.85][d]))
				xx += cell
			yy += cell * 1.3
		# a neon sign running down it
		if t["neon"]:
			var nc: Color = t["ncol"]
			var nx := x + w * 0.2 if d > 0 else x + w * 0.5
			var nh := minf(h * 0.6, [30.0, 70.0, 140.0][d])
			n.draw_rect(Rect2(nx - P * 2, top + 20.0, P * (4 if d > 0 else 2), nh), Color(nc, 0.18))
			n.draw_rect(Rect2(nx - P * 0.5, top + 20.0, P, nh), Color(nc.lerp(Color.WHITE, 0.4), 0.9))
	# a haze over the far ones
	if d == 0:
		n.draw_rect(Rect2(-200.0, 0, _span + 400.0, size.y), Color(_sky_low, 0.18))


func _draw_traffic() -> void:
	# the red lights on the towers' tops, blinking
	for b in _beacons:
		var on := fposmod(_t * 0.7 + float((b[1] as Vector2).x) * 0.013, 1.4) < 0.3
		if not on:
			continue
		var bp: Vector2 = b[1]
		var lpos := bp + Vector2(-_scroll * ([0.92, 0.78, 0.55][int(b[0])] - 0.7), 0)
		_traffic.draw_circle(lpos, 6.0, Color(1.0, 0.2, 0.15, 0.3))
		_traffic.draw_rect(Rect2(lpos - Vector2(P, P) * 0.5, Vector2(P, P)), Color(1.0, 0.3, 0.25))
	for s in _speeders:
		var p := Vector2(float(s[1]), float(s[0]))
		var sz: float = s[3]
		var dir := signf(float(s[2]))
		var c: Color = s[4]
		# its light trail, its body, its headlight and tail light
		_traffic.draw_rect(Rect2(p.x - dir * 40.0 * sz if dir > 0 else p.x, p.y, 40.0 * sz, P * 0.67), Color(c, 0.18))
		_traffic.draw_rect(Rect2(p - Vector2(5, 2) * sz, Vector2(10, 4) * sz), Color(0.12, 0.13, 0.17))
		_traffic.draw_rect(Rect2(p + Vector2(-5 * sz, 1 * sz), Vector2(10, 1) * sz), Color(c, 0.9))
		_traffic.draw_rect(Rect2(p + Vector2(dir * 5 * sz - (0 if dir > 0 else P), -1 * sz), Vector2(P, P)), Color(1, 1, 0.9))
		_traffic.draw_circle(p + Vector2(dir * 9 * sz, 0), 5.0 * sz, Color(1, 1, 0.85, 0.15))
		_traffic.draw_rect(Rect2(p + Vector2(-dir * 5 * sz - (P if dir > 0 else 0), -1 * sz), Vector2(P, P)), Color(1.0, 0.25, 0.2))
	for d in _drones:
		var dp := Vector2(float(d[0]), float(d[1]) + sin(_t * 1.3 + float(d[2])) * 12.0).snapped(Vector2(P, P))
		_traffic.draw_rect(Rect2(dp - Vector2(P * 2, P * 0.5), Vector2(P * 4, P)), Color(0.25, 0.27, 0.32))
		_traffic.draw_rect(Rect2(dp - Vector2(P * 2, P * 1.5), Vector2(P, P)), Color(0.4, 0.42, 0.48))
		_traffic.draw_rect(Rect2(dp + Vector2(P, -P * 1.5), Vector2(P, P)), Color(0.4, 0.42, 0.48))
		if fposmod(_t * 1.5 + float(d[2]), 1.0) < 0.5:
			_traffic.draw_rect(Rect2(dp + Vector2(-P, -P), Vector2(P, P) * 0.67), Color(0.3, 1.0, 0.5))
		_traffic.draw_circle(dp + Vector2(0, P), 4.0, Color(0.6, 0.9, 1.0, 0.25))
