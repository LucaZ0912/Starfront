class_name PadTraffic
extends Node2D
## 0.7.50.10 (Luz): on a settlement's free landing pads other landing drones come and go – one drops in from above,
## its shadow closing in, sets down in a puff of dust, waits a while, lifts off and is gone; then the pad stays empty a
## little before the next one. (Later, in multiplayer, the other pilots' drones.)

const ART := 3.5 * 3.0                # the drone's picture scale on the ground (as the player's)
const DOWN := 2.4
const UP := 2.0

var pads: Array = []                  # [{pos (screen px), state, t, wait, tint}]
var _tex: Texture2D
var _puffs: Array = []                # [pos, vel, life, size]
var dust_col := Color(0.6, 0.55, 0.45)


func setup(pad_centres: Array, rng: RandomNumberGenerator, p_dust: Color) -> void:
	_tex = FlightScene.lander_texture()
	dust_col = p_dust
	for p in pad_centres:
		var st := "empty" if rng.randf() < 0.5 else "parked"
		pads.append({"pos": (p as Vector2) * GroundMap.SCALE, "state": st, "t": 0.0, "wait": rng.randf_range(2.0, 10.0),
			"tint": Color.from_hsv(rng.randf(), rng.randf_range(0.0, 0.35), rng.randf_range(0.75, 1.0))})


func _process(delta: float) -> void:
	for p in pads:
		p["t"] = float(p["t"]) + delta
		match String(p["state"]):
			"empty":
				if float(p["t"]) > float(p["wait"]):
					p["state"] = "landing"
					p["t"] = 0.0
					p["tint"] = Color.from_hsv(randf(), randf_range(0.0, 0.35), randf_range(0.75, 1.0))
			"landing":
				if float(p["t"]) >= DOWN:
					p["state"] = "parked"
					p["t"] = 0.0
					p["wait"] = randf_range(8.0, 25.0)
					_burst(p["pos"], 12)
			"parked":
				if float(p["t"]) > float(p["wait"]):
					p["state"] = "lifting"
					p["t"] = 0.0
					_burst(p["pos"], 10)
			"lifting":
				if float(p["t"]) >= UP:
					p["state"] = "empty"
					p["t"] = 0.0
					p["wait"] = randf_range(4.0, 14.0)
	for d in _puffs:
		d[0] = (d[0] as Vector2) + (d[1] as Vector2) * delta
		d[1] = (d[1] as Vector2) * 0.94
		d[2] = float(d[2]) - delta
	_puffs = _puffs.filter(func(d): return float(d[2]) > 0.0)
	queue_redraw()


func _burst(at: Vector2, n: int) -> void:
	for i in n:
		var a := randf() * TAU
		_puffs.append([at + Vector2(cos(a), sin(a) * 0.5) * 20.0, Vector2(cos(a), sin(a) * 0.5) * randf_range(60.0, 140.0), randf_range(0.6, 1.2), randf_range(6.0, 12.0)])


## How high a drone is over its pad (0 down … 1 out of sight) – and so how big and where.
func _height(p: Dictionary) -> float:
	match String(p["state"]):
		"landing":
			return pow(1.0 - clampf(float(p["t"]) / DOWN, 0.0, 1.0), 2.0)
		"lifting":
			return pow(clampf(float(p["t"]) / UP, 0.0, 1.0), 2.0)
		"parked":
			return 0.0
	return -1.0


func _draw() -> void:
	var tw := Vector2(_tex.get_width(), _tex.get_height()) * ART
	for p in pads:
		var h := _height(p)
		if h < 0.0:
			continue
		var at: Vector2 = p["pos"]
		var sc := lerpf(1.0, 1.7, h)
		var a := 1.0 - smoothstep(0.75, 1.0, h)
		# its shadow on the pad, closing in as it comes down
		draw_set_transform(at + Vector2(10, 14) + Vector2(80, 110) * h, 0.0, Vector2.ONE * (1.0 - h * 0.3))
		draw_texture_rect(_tex, Rect2(-tw * 0.5, tw), false, Color(0, 0, 0, 0.4 * (1.0 - h)))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var pos := at + Vector2(0, -300.0 * h)
		if String(p["state"]) in ["landing", "lifting"]:
			for j in 2:
				var ln := (26.0 - j * 9.0) * sc * (0.85 + 0.15 * sin(Time.get_ticks_msec() * 0.03 + j))
				draw_colored_polygon(PackedVector2Array([pos + Vector2(-tw.x * 0.42, -8 + j * 3) * sc, pos + Vector2(-tw.x * 0.42 - ln, 0), pos + Vector2(-tw.x * 0.42, 8 - j * 3) * sc]),
					Color([Color(1.0, 0.6, 0.2), Color(1, 1, 0.85)][j], 0.6 * a))
		draw_set_transform(pos, 0.0, Vector2.ONE * sc)
		draw_texture_rect(_tex, Rect2(-tw * 0.5, tw), false, Color(p["tint"], a))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if String(p["state"]) == "parked" and fposmod(float(p["t"]), 1.2) < 0.3:
			draw_circle(at + Vector2(0, -tw.y * 0.5), 3.0, Color(0.4, 1.0, 0.55))          # its beacon
	for d in _puffs:
		var k := clampf(float(d[2]), 0.0, 1.0)
		draw_circle(d[0], float(d[3]) * (1.6 - k * 0.6) * 1.5, Color(dust_col, 0.3 * k))
