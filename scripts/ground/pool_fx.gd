extends Node2D
## Package 58, part 6 (Luz): the pool table in Dan's bar during the briefing – a cue ball and a few balls drawn over
## the table, a cue that strikes, a ball that rolls: Dan's shot goes wide (off a cushion, nowhere near a pocket),
## Ossa's drops into a corner pocket. Runs while the dialogue pauses the game (process always).
## A child of the GroundView's sorted layer, placed at the table's bottom edge; drawn in art px (scaled).

var table: Dictionary = {}               # the pool_table object (x, y in tiles; w 3, h 2)
var balls: Array = []                    # {pos (art px, local), col, on}
var _moves: Array = []                   # {i, from, to, t, dur, sink}
var _cue := {}                           # {from, to, t, dur}: the cue's stroke
const T := GroundMap.TILE


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Over this table: the felt as the art draws it (see ObjArt "pool_table": rise 6, the felt inset 3 px).
func setup(o: Dictionary) -> void:
	table = o
	scale = Vector2.ONE * GroundMap.SCALE
	position = Vector2(float(o["x"]) * T, float(int(o["y"]) + int(o.get("h", 2))) * T) * GroundMap.SCALE
	z_index = 1
	var f := felt()
	balls = [
		{"pos": f.position + Vector2(f.size.x * 0.25, f.size.y * 0.5), "col": Color(0.97, 0.97, 0.92), "on": true},   # the cue ball
		{"pos": f.position + Vector2(f.size.x * 0.62, f.size.y * 0.42), "col": Color(0.9, 0.2, 0.2), "on": true},
		{"pos": f.position + Vector2(f.size.x * 0.78, f.size.y * 0.3), "col": Color(0.95, 0.8, 0.2), "on": true},
		{"pos": f.position + Vector2(f.size.x * 0.7, f.size.y * 0.72), "col": Color(0.2, 0.3, 0.9), "on": true},
		{"pos": f.position + Vector2(f.size.x * 0.84, f.size.y * 0.16), "col": Color(0.06, 0.06, 0.07), "on": true},   # the black
	]


## The felt in local art px (the node sits at the table's bottom-left corner).
func felt() -> Rect2:
	return Rect2(Vector2(3, -2.0 * T - 2.0 + 4.0), Vector2(3.0 * T - 6.0, 2.0 * T - 10.0))


## Dan's shot: hard at the red, which runs off the far cushion and stops short of everything.
func shot_miss() -> void:
	var f := felt()
	_strike(0, (balls[1]["pos"] as Vector2) + Vector2(-2.6, 0.4), 0.45)
	_after(0.45, func():
		_roll(1, f.position + Vector2(f.size.x - 3.0, f.size.y * 0.18), 0.55, false)
		_after(0.55, func(): _roll(1, f.position + Vector2(f.size.x * 0.58, f.size.y * 0.2), 0.9, false))
		_roll(0, (balls[0]["pos"] as Vector2) + Vector2(5.0, 1.0), 0.6, false))


## Ossa's shot (Luz): the black, cleanly into the top right corner pocket – the game won.
func shot_sink() -> void:
	var f := felt()
	var black: Vector2 = balls[4]["pos"]
	var from: Vector2 = balls[0]["pos"]
	var dir := ((f.position + Vector2(f.size.x, 0.0)) - black).normalized()
	_strike(0, black - dir * 3.0, 0.5)
	_after(0.5, func():
		_roll(4, f.position + Vector2(f.size.x + 0.5, -0.5), 0.5, true)
		_roll(0, from.lerp(black, 0.8), 0.6, false))


func _strike(i: int, aim_at: Vector2, dur: float) -> void:
	var b: Vector2 = balls[i]["pos"]
	var back := (b - aim_at).normalized()
	_cue = {"from": b + back * 18.0, "to": b + back * 2.5, "t": 0.0, "dur": 0.32}
	Audio.play("pool_cue", "briefing: a shot", -6.0)
	_after(0.3, func(): _roll(i, aim_at, dur, false))


func _roll(i: int, to: Vector2, dur: float, sink: bool) -> void:
	_moves.append({"i": i, "from": balls[i]["pos"], "to": to, "t": 0.0, "dur": dur, "sink": sink})


func _after(secs: float, f: Callable) -> void:
	get_tree().create_timer(secs, true).timeout.connect(f)


func _process(dt: float) -> void:
	for m in _moves.duplicate():
		m["t"] = float(m["t"]) + dt
		var k := clampf(float(m["t"]) / float(m["dur"]), 0.0, 1.0)
		balls[int(m["i"])]["pos"] = (m["from"] as Vector2).lerp(m["to"], 1.0 - pow(1.0 - k, 2.0))
		if k >= 1.0:
			_moves.erase(m)
			if bool(m["sink"]):
				balls[int(m["i"])]["on"] = false
				Audio.play("pool_pocket", "briefing: pocketed", -4.0)
			elif int(m["i"]) != 0:
				Audio.play("pool_cushion", "briefing: cushion", -14.0)
	if not _cue.is_empty():
		_cue["t"] = float(_cue["t"]) + dt
		if float(_cue["t"]) > float(_cue["dur"]) + 0.5:
			_cue = {}
	queue_redraw()


func _draw() -> void:
	for b in balls:
		if bool(b["on"]):
			draw_circle((b["pos"] as Vector2) + Vector2(0.4, 0.6), 1.7, Color(0, 0, 0, 0.35))
			draw_circle(b["pos"], 1.6, b["col"])
			draw_circle((b["pos"] as Vector2) + Vector2(-0.5, -0.5), 0.5, Color(1, 1, 1, 0.7))
	if not _cue.is_empty():
		var k := clampf(float(_cue["t"]) / float(_cue["dur"]), 0.0, 1.0)
		var tip: Vector2 = (_cue["from"] as Vector2).lerp(_cue["to"], k * k)
		var back: Vector2 = ((_cue["from"] as Vector2) - (_cue["to"] as Vector2)).normalized()
		draw_line(tip, tip + back * 30.0, Color(0.55, 0.36, 0.2), 1.2)
		draw_line(tip, tip + back * 1.5, Color(0.85, 0.9, 1.0), 1.2)
