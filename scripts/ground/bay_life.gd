class_name BayLife
extends Node2D
## Package 49 (0.7.49.10): life down in the hangar bay, roughly to scale – tiny loaders shuttle crates between the
## stacks along the walls and the ship, repair drones hover along the hull and weld (sparks), a fuel truck stands at
## the stern with its hose, fuel pulsing through. Drawn in art px (×SCALE), under the bay's haze.

const LOADER_SPEED := 9.0           # art px per second – slow: it is far below
const DRONE_SPEED := 14.0

var bay := Rect2()                   # art px
var ship := Rect2()                  # art px: the ship's outline (nose to the east)
var accent := Color(0.3, 0.9, 1.0)
var loaders: Array = []              # {pos, from, to, state, wait, load}
var drones: Array = []               # {pos, target, wait, weld}
var sparks: Array = []               # {pos, vel, life}
var fuel_at := Vector2.ZERO
var _t := 0.0
var _rng := RandomNumberGenerator.new()


func setup(p_bay: Rect2, p_ship: Rect2, p_accent: Color, seed_v: int) -> void:
	bay = p_bay
	ship = p_ship
	accent = p_accent
	_rng.seed = seed_v
	scale = Vector2.ONE * GroundMap.SCALE
	for i in 3:
		var stack := _stack_point(i)
		loaders.append({"pos": stack, "from": stack, "to": _ship_side(i), "state": 0, "wait": _rng.randf_range(0.0, 3.0), "load": true})
	for j in 4:
		var p := _hull_point()
		drones.append({"pos": p + Vector2(_rng.randf_range(-20, 20), _rng.randf_range(-14, 14)), "target": p, "wait": 0.0, "weld": 0.0,
			"bob": _rng.randf() * TAU})
	fuel_at = Vector2(ship.position.x - 12.0, ship.get_center().y + ship.size.y * 0.32)


## Crate stacks along the bay's walls (top or bottom edge).
func _stack_point(i: int) -> Vector2:
	var top := i % 2 == 0
	var x := bay.position.x + bay.size.x * (0.15 + 0.3 * i + _rng.randf_range(-0.05, 0.05))
	return Vector2(x, bay.position.y + 8.0 if top else bay.end.y - 8.0)


## A loading point beside the ship's hull.
func _ship_side(i: int) -> Vector2:
	var top := i % 2 == 0
	var x := ship.position.x + ship.size.x * _rng.randf_range(0.3, 0.7)
	return Vector2(x, ship.position.y - 4.0 if top else ship.end.y + 4.0)


func _hull_point() -> Vector2:
	return Vector2(_rng.randf_range(ship.position.x + ship.size.x * 0.15, ship.end.x - ship.size.x * 0.15),
		_rng.randf_range(ship.position.y + ship.size.y * 0.2, ship.end.y - ship.size.y * 0.2))


func _process(delta: float) -> void:
	_t += delta
	for l in loaders:
		_loader(l, delta)
	for d in drones:
		_drone(d, delta)
	for s in sparks:
		s["pos"] = (s["pos"] as Vector2) + (s["vel"] as Vector2) * delta
		s["vel"] = (s["vel"] as Vector2) + Vector2(0, 30) * delta
		s["life"] = float(s["life"]) - delta
	sparks = sparks.filter(func(s): return float(s["life"]) > 0.0)
	queue_redraw()


## A loader drives along the floor (first across, then up or down), picks up a crate at the stack, sets it down at
## the ship, and back.
func _loader(l: Dictionary, delta: float) -> void:
	if float(l["wait"]) > 0.0:
		l["wait"] = float(l["wait"]) - delta
		return
	var goal: Vector2 = l["to"] if int(l["state"]) == 0 else l["from"]
	var p: Vector2 = l["pos"]
	var step := LOADER_SPEED * delta
	if absf(goal.x - p.x) > 0.5:
		p.x = move_toward(p.x, goal.x, step)
	elif absf(goal.y - p.y) > 0.5:
		p.y = move_toward(p.y, goal.y, step)
	else:
		l["state"] = 1 - int(l["state"])
		l["load"] = int(l["state"]) == 0              # loaded on the way to the ship, empty on the way back
		l["wait"] = _rng.randf_range(1.5, 3.5)
		if int(l["state"]) == 0:
			l["to"] = _ship_side(_rng.randi() % 2)
	l["pos"] = p


## A drone flies to a spot on the hull, hovers and welds a while (sparks), then on to the next.
func _drone(d: Dictionary, delta: float) -> void:
	var p: Vector2 = d["pos"]
	var tg: Vector2 = d["target"] + Vector2(0, -3)
	if p.distance_to(tg) > 1.0:
		d["pos"] = p.move_toward(tg, DRONE_SPEED * delta)
		return
	d["weld"] = float(d["weld"]) + delta
	if _rng.randf() < delta * 14.0:
		sparks.append({"pos": tg + Vector2(0, 3), "vel": Vector2(_rng.randf_range(-12, 12), _rng.randf_range(-16, -4)), "life": _rng.randf_range(0.2, 0.5)})
	if float(d["weld"]) > _rng.randf_range(3.0, 7.0):
		d["weld"] = 0.0
		d["target"] = _hull_point()


func _draw() -> void:
	# the fuel truck at the stern: its hose to the ship, fuel pulsing along it
	var f := fuel_at
	draw_rect(Rect2(f + Vector2(-6, -3), Vector2(12, 5)), Color(0.75, 0.55, 0.15))
	draw_rect(Rect2(f + Vector2(-6, -3), Vector2(12, 1)), Color(0.95, 0.75, 0.3))
	draw_rect(Rect2(f + Vector2(3, -4), Vector2(3, 6)), Color(0.35, 0.37, 0.42))
	draw_rect(Rect2(f + Vector2(-5, 2), Vector2(2, 1)), Color(0.1, 0.1, 0.1))
	draw_rect(Rect2(f + Vector2(2, 2), Vector2(2, 1)), Color(0.1, 0.1, 0.1))
	var hose_end := Vector2(ship.position.x + ship.size.x * 0.12, ship.get_center().y + ship.size.y * 0.12)
	draw_line(f + Vector2(6, -1), hose_end, Color(0.15, 0.15, 0.17), 1.0)
	var k := fposmod(_t * 0.6, 1.0)
	draw_rect(Rect2((f + Vector2(6, -1)).lerp(hose_end, k) - Vector2(0.5, 0.5), Vector2(1, 1)), Color(1.0, 0.75, 0.25))
	if fposmod(_t, 1.0) < 0.5:
		draw_rect(Rect2(f + Vector2(-6, -4), Vector2(1, 1)), Color(1.0, 0.6, 0.1))
	# loaders: a little forklift, a crate on the forks when loaded, a blinking light
	for l in loaders:
		var p: Vector2 = l["pos"]
		draw_rect(Rect2(p + Vector2(-3, -2), Vector2(6, 4)), Color(0.95, 0.75, 0.15))
		draw_rect(Rect2(p + Vector2(-3, -2), Vector2(6, 1)), Color(1.0, 0.9, 0.5))
		draw_rect(Rect2(p + Vector2(-1, -3), Vector2(2, 1)), Color(0.2, 0.2, 0.22))
		draw_rect(Rect2(p + Vector2(3, 0), Vector2(2, 1)), Color(0.4, 0.4, 0.45))
		if bool(l["load"]):
			draw_rect(Rect2(p + Vector2(3, -3), Vector2(3, 3)), Color(0.55, 0.4, 0.22))
		if fposmod(_t * 2.0 + p.x, 1.0) < 0.5:
			draw_rect(Rect2(p + Vector2(-1, -4), Vector2(1, 1)), Color(1.0, 0.5, 0.1))
	# drones: tiny bodies, a light below, bobbing
	for d in drones:
		var q: Vector2 = d["pos"] + Vector2(0, sin(_t * 4.0 + float(d["bob"])) * 0.8)
		draw_rect(Rect2(q + Vector2(-2, -1), Vector2(4, 2)), Color(0.75, 0.78, 0.85))
		draw_rect(Rect2(q + Vector2(-3, -1), Vector2(1, 1)), Color(0.4, 0.42, 0.48))
		draw_rect(Rect2(q + Vector2(2, -1), Vector2(1, 1)), Color(0.4, 0.42, 0.48))
		draw_rect(Rect2(q + Vector2(0, 1), Vector2(1, 1)), accent)
		if float(d["weld"]) > 0.0 and fposmod(_t * 9.0, 1.0) < 0.6:
			draw_rect(Rect2(q + Vector2(0, 2), Vector2(1, 2)), Color(0.85, 0.95, 1.0))
	for s in sparks:
		draw_rect(Rect2(s["pos"], Vector2(1, 1)), Color(1.0, 0.85, 0.4, clampf(float(s["life"]) * 3.0, 0.0, 1.0)))
