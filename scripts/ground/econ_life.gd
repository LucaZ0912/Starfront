class_name EconLife
extends Node2D
## 0.7.50.12: life in a settlement's economy area (GroundMap.econ) – drawn in art px (the node is scaled):
## mining: the excavator swinging its arm at the bottom of the pit, haul trucks winding up and down the ramp (full on
## the way up, dust behind them), the conveyor running to the heap · fields: a harvester working its rows, crop drones
## · hydroponics: drones between the greenhouses · works: smoke from the chimneys, the gantry crane moving containers ·
## tank farm: the flare's flame, a tanker on the road · dish array / launch pad: a rocket now and then, the countdown
## lights · training yard: an armoured vehicle on its round, a patrol drone · gardens: birds · fish pens and rigs: a boat.

var info: Dictionary = {}
var _t := 0.0
var _path: Array = []                 # the trucks' way (mining)
var _puffs: Array = []                # [pos, vel, life, size, colour]
var _harv := 0.0


func setup(p_info: Dictionary) -> void:
	info = p_info
	scale = Vector2.ONE * GroundMap.SCALE
	z_index = 1
	if String(info.get("kind", "")) == "mining":
		var pit: Rect2 = info["pit"]
		var st := float(info.get("step", 14))
		_path = [info["heap"] + Vector2(-20, 6), Vector2(pit.position.x - 6, pit.end.y + 4), Vector2(pit.position.x - 6, pit.position.y + st * 0.5)]
		for lv in 5:
			var y := pit.position.y + lv * st + st * 0.5 + 1.0
			if lv % 2 == 0:
				_path.append(Vector2(pit.position.x + lv * st + 8, y))
				_path.append(Vector2(pit.end.x - lv * st - 16, y))
			else:
				_path.append(Vector2(pit.end.x - lv * st - 16, y))
				_path.append(Vector2(pit.position.x + lv * st + 8, y))
		_path.append(pit.get_center() + Vector2(-18, 6))


func _process(delta: float) -> void:
	_t += delta
	for p in _puffs:
		p[0] = (p[0] as Vector2) + (p[1] as Vector2) * delta
		p[2] = float(p[2]) - delta
	_puffs = _puffs.filter(func(p): return float(p[2]) > 0.0)
	match String(info.get("kind", "")):
		"industry":
			for s in info.get("stacks", []):
				if randf() < delta * 6.0:
					_puffs.append([s + Vector2(randf_range(-2, 2), 0), Vector2(randf_range(4, 9), randf_range(-14, -8)), randf_range(2.5, 4.0), randf_range(3.0, 5.0), Color(0.55, 0.55, 0.58)])
		"mining":
			if randf() < delta * 3.0:
				var pit: Rect2 = info["pit"]
				_puffs.append([pit.get_center() + Vector2(randf_range(-6, 6), randf_range(-2, 4)), Vector2(randf_range(-4, 4), randf_range(-6, -2)), randf_range(0.8, 1.6), randf_range(2.0, 4.0), Color(0.6, 0.52, 0.42)])
	queue_redraw()


## Ping-pong along a path: position and heading (+1 / -1) at a distance.
func _along(path: Array, d: float) -> Array:
	var total := 0.0
	for i in path.size() - 1:
		total += (path[i] as Vector2).distance_to(path[i + 1])
	var u := fposmod(d, total * 2.0)
	var back := u > total
	if back:
		u = total * 2.0 - u
	for i in path.size() - 1:
		var seg := (path[i] as Vector2).distance_to(path[i + 1])
		if u <= seg:
			var p := (path[i] as Vector2).lerp(path[i + 1], u / maxf(seg, 0.001))
			var dir := ((path[i + 1] as Vector2) - (path[i] as Vector2)).normalized() * (-1.0 if back else 1.0)
			return [p, dir, back]
		u -= seg
	return [path.back(), Vector2.RIGHT, back]


func _draw() -> void:
	match String(info.get("kind", "")):
		"mining":
			_draw_mining()
		"agri", "hydro":
			_draw_fields()
		"industry":
			_draw_crane()
			var road2: Array = info.get("road", [])
			if road2.size() == 2:
				var af := _along(road2, _t * 14.0)
				_truck(af[0], af[1], Color(0.95, 0.6, 0.15), "dump", fposmod(_t, 20.0) < 10.0)
		"refinery", "chemistry":
			_draw_flare()
			var road: Array = info.get("road", [])
			if road.size() == 2:
				var a := _along(road, _t * 18.0)
				_truck(a[0], a[1], Color(0.85, 0.85, 0.82), "tank", true)
		"research", "hightech":
			_draw_launch()
		"military":
			var r: Rect2 = info.get("loop", Rect2())
			var loop := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position]
			var a2 := _along(loop, _t * 16.0)
			_truck(a2[0], a2[1], Color(0.36, 0.42, 0.3), "apc", false)
			_drone(r.get_center() + Vector2(cos(_t * 0.5), sin(_t * 0.5) * 0.6) * 60.0, Color(0.4, 1.0, 0.5))
		"tourism":
			for b in 4:
				var bp := (info["rect"] as Rect2).position + Vector2(fposmod(_t * 20.0 + b * 70.0, (info["rect"] as Rect2).size.x), 30.0 + b * 40.0 + sin(_t * 2.0 + b) * 6.0)
				var flap := 2.0 if fposmod(_t * 6.0 + b, 1.0) < 0.5 else -1.0
				draw_line(bp, bp + Vector2(-3, flap), Color(0.15, 0.15, 0.18), 1.0)
				draw_line(bp, bp + Vector2(3, flap), Color(0.15, 0.15, 0.18), 1.0)
		"pens", "rig":
			if String(info["kind"]) == "rig":
				_draw_flare()
			var pens: Array = info.get("pens", [])
			if pens.size() >= 2:
				var a3 := _along(pens, _t * 14.0)
				_boat(a3[0], a3[1])
	for p in _puffs:
		var k := clampf(float(p[2]) / 3.0, 0.0, 1.0)
		draw_circle(p[0], float(p[3]) * (1.8 - k), Color(p[4], 0.45 * k))


# ---------------------------------------------------------------- mining

func _draw_mining() -> void:
	var pit: Rect2 = info["pit"]
	# the conveyor from the pit's rim to the heap, its belt moving
	var c0 := Vector2(pit.end.x - 24, pit.end.y - 4)
	var c1: Vector2 = info["heap"] + Vector2(-6, -6)
	draw_line(c0, c1, Color(0.18, 0.18, 0.2), 5.0)
	draw_line(c0, c1, Color(0.35, 0.33, 0.3), 3.0)
	var n := int(c0.distance_to(c1) / 6.0)
	for i in n:
		var u := fposmod(i / float(n) + _t * 0.15, 1.0)
		draw_rect(Rect2(c0.lerp(c1, u) - Vector2(1, 1), Vector2(2, 2)), Color(0.55, 0.45, 0.32))
	# the excavator at the bottom, its arm swinging between the face and the truck
	var ex := pit.get_center() + Vector2(6, 2)
	draw_set_transform(ex, 0.0, Vector2.ONE * 1.6)
	ex = Vector2.ZERO
	draw_rect(Rect2(ex + Vector2(-9, 2), Vector2(18, 5)), Color(0.15, 0.15, 0.15))            # tracks
	draw_rect(Rect2(ex + Vector2(-8, -5), Vector2(16, 8)), Color(0.92, 0.72, 0.15))           # body
	draw_rect(Rect2(ex + Vector2(2, -9), Vector2(6, 5)), Color(0.85, 0.65, 0.12))             # cab
	draw_rect(Rect2(ex + Vector2(3, -8), Vector2(4, 2)), Color(0.45, 0.65, 0.8))
	var ang := -2.4 + sin(_t * 0.7) * 0.7
	var j1 := ex + Vector2(-4, -4)
	var j2 := j1 + Vector2.from_angle(ang) * 14.0
	var j3 := j2 + Vector2.from_angle(ang + 1.2 + sin(_t * 0.7 + 1.0) * 0.4) * 10.0
	draw_line(j1, j2, Color(0.85, 0.65, 0.12), 3.0)
	draw_line(j2, j3, Color(0.8, 0.6, 0.1), 2.0)
	draw_rect(Rect2(j3 - Vector2(3, 2), Vector2(6, 4)), Color(0.3, 0.28, 0.25))             # the bucket
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# haul trucks, winding up and down the ramp – full on the way up
	for k in 2:
		var a := _along(_path, _t * 22.0 + k * 260.0)
		_truck(a[0], a[1], Color(0.95, 0.75, 0.15), "dump", not bool(a[2]))
		if randf() < 0.15:
			_puffs.append([(a[0] as Vector2) - (a[1] as Vector2) * 8.0, Vector2(randf_range(-3, 3), randf_range(-4, -1)), 1.0, 2.5, Color(0.6, 0.52, 0.42)])


## A vehicle seen from above-front: wheels, body, cab, its load.
func _truck(p: Vector2, dir: Vector2, col: Color, kind: String, loaded: bool) -> void:
	var f := 1.0 if dir.x >= 0.0 else -1.0
	draw_rect(Rect2(p + Vector2(-9, 2), Vector2(18, 4)), Color(0.12, 0.12, 0.13))
	for wx in [-7, -1, 5]:
		draw_rect(Rect2(p + Vector2(wx, 3), Vector2(3, 3)), Color(0.25, 0.25, 0.27))
	draw_rect(Rect2(p + Vector2(-9, -5), Vector2(18, 8)), col)
	draw_rect(Rect2(p + Vector2(-9, -5), Vector2(18, 1)), col.lightened(0.25))
	draw_rect(Rect2(p + Vector2(3 * f - (0 if f > 0 else 6), -9), Vector2(6, 5)), col.darkened(0.12))     # the cab
	draw_rect(Rect2(p + Vector2(4 * f - (0 if f > 0 else 4), -8), Vector2(4, 2)), Color(0.45, 0.65, 0.8))
	match kind:
		"dump":
			draw_rect(Rect2(p + Vector2(-8 * f - (0 if f > 0 else 9), -8), Vector2(9, 4)), col.darkened(0.25))
			if loaded:
				draw_rect(Rect2(p + Vector2(-7 * f - (0 if f > 0 else 7), -10), Vector2(7, 3)), Color(0.5, 0.4, 0.3))
		"tank":
			draw_rect(Rect2(p + Vector2(-8 * f - (0 if f > 0 else 10), -10), Vector2(10, 6)), Color(0.75, 0.75, 0.72))
			draw_rect(Rect2(p + Vector2(-8 * f - (0 if f > 0 else 10), -10), Vector2(10, 1)), Color(0.9, 0.9, 0.88))
		"apc":
			draw_rect(Rect2(p + Vector2(-3, -9), Vector2(7, 4)), col.darkened(0.1))
			draw_line(p + Vector2(0, -7), p + Vector2(9 * f, -8), col.darkened(0.3), 1.5)
	draw_rect(Rect2(p + Vector2(9 * f - (1 if f > 0 else 0), -3), Vector2(1, 2)), Color(1, 1, 0.85))


func _drone(p: Vector2, light: Color) -> void:
	draw_circle(p + Vector2(4, 14), 3.0, Color(0, 0, 0, 0.25))
	draw_rect(Rect2(p - Vector2(4, 1), Vector2(8, 3)), Color(0.3, 0.32, 0.36))
	for s in [-1.0, 1.0]:
		draw_line(p + Vector2(4 * s, 0), p + Vector2(7 * s, -2), Color(0.5, 0.52, 0.55), 1.0)
		draw_line(p + Vector2(7 * s - 2, -2), p + Vector2(7 * s + 2, -2), Color(0.7, 0.72, 0.75, 0.6), 1.0)
	if fposmod(_t * 2.0, 1.0) < 0.5:
		draw_rect(Rect2(p + Vector2(-1, 1), Vector2(2, 1)), light)


# ---------------------------------------------------------------- fields

func _draw_fields() -> void:
	var fields: Array = info.get("fields", [])
	if fields.is_empty():
		return
	if String(info["kind"]) == "agri":
		# the harvester works one field, row by row
		var f: Rect2 = fields[1 % fields.size()]
		var rows := maxi(1, int(f.size.y / 6.0))
		var u := fposmod(_t * 10.0, f.size.x * rows)
		var row := int(u / f.size.x)
		var x := fmod(u, f.size.x)
		if row % 2 == 1:
			x = f.size.x - x
		var hp := f.position + Vector2(x, 3 + row * 6)
		draw_rect(Rect2(f.position + Vector2(0, 0), Vector2(f.size.x, row * 6)), Color(0.55, 0.45, 0.25, 0.5))     # cut already
		var dir := 1.0 if row % 2 == 0 else -1.0
		draw_rect(Rect2(hp + Vector2(-8, -4), Vector2(16, 8)), Color(0.25, 0.55, 0.25))
		draw_rect(Rect2(hp + Vector2(8 * dir - (0 if dir > 0 else 3), -6), Vector2(3, 12)), Color(0.85, 0.75, 0.2))   # the header
		draw_rect(Rect2(hp + Vector2(-3, -9), Vector2(6, 5)), Color(0.2, 0.45, 0.2))
		draw_rect(Rect2(hp + Vector2(-2, -8), Vector2(4, 2)), Color(0.45, 0.65, 0.8))
		if randf() < 0.2:
			_puffs.append([hp - Vector2(10 * dir, 0), Vector2(-6 * dir, -3), 1.2, 2.5, Color(0.85, 0.75, 0.45)])
	# crop drones drifting over the fields, spraying
	for d in 3:
		var fr: Rect2 = fields[(d * 2) % fields.size()]
		var p := fr.get_center() + Vector2(cos(_t * 0.6 + d * 2.1) * fr.size.x * 0.35, sin(_t * 0.9 + d) * fr.size.y * 0.3)
		_drone(p, Color(0.4, 1.0, 0.5))
		if fposmod(_t + d, 3.0) < 1.5:
			for k in 3:
				draw_rect(Rect2(p + Vector2(randf_range(-4, 4), randf_range(3, 8)), Vector2(1, 1)), Color(0.7, 0.9, 1.0, 0.6))


# ---------------------------------------------------------------- works, tank farms, launch pads, boats

func _draw_crane() -> void:
	var r: Rect2 = info.get("crane", Rect2())
	if r.size.x <= 0.0:
		return
	# its rails, the gantry rolling along them: two legs standing up, the bridge high over the yard
	draw_rect(Rect2(r.position.x, r.position.y - 1, r.size.x, 2), Color(0.3, 0.3, 0.32))
	draw_rect(Rect2(r.position.x, r.end.y - 1, r.size.x, 2), Color(0.3, 0.3, 0.32))
	var bx := r.position.x + (0.5 + 0.42 * sin(_t * 0.25)) * r.size.x
	var ty := r.position.y + (0.3 + 0.4 * (0.5 + 0.5 * sin(_t * 0.6))) * r.size.y
	var hgt := 30.0
	for leg_y in [r.position.y, r.end.y]:
		draw_rect(Rect2(bx - 8, leg_y - hgt, 3, hgt), Color(0.85, 0.65, 0.12))
		draw_rect(Rect2(bx + 5, leg_y - hgt, 3, hgt), Color(0.85, 0.65, 0.12))
		draw_rect(Rect2(bx - 10, leg_y - 2, 20, 3), Color(0.3, 0.3, 0.32))
	draw_rect(Rect2(bx - 9, r.position.y - hgt - 4, 18, r.size.y + 4), Color(0.95, 0.75, 0.15))     # the bridge
	for yy in range(int(r.position.y - hgt), int(r.end.y - hgt), 6):
		draw_line(Vector2(bx - 8, yy), Vector2(bx + 8, yy + 5), Color(0.8, 0.6, 0.1), 1.0)
	draw_rect(Rect2(bx - 9, r.position.y - hgt - 4, 18, 1), Color(1.0, 0.92, 0.55))
	draw_rect(Rect2(bx - 5, ty - hgt - 3, 10, 6), Color(0.3, 0.3, 0.33))                     # the trolley
	draw_line(Vector2(bx, ty - hgt + 3), Vector2(bx, ty - 8), Color(0.2, 0.2, 0.22), 1.0)
	draw_line(Vector2(bx, ty - 20), Vector2(bx, ty - 8), Color(0.2, 0.2, 0.22), 1.0)
	draw_rect(Rect2(Vector2(bx - 9, ty - 8), Vector2(18, 8)), Color(0.2, 0.45, 0.65))          # the container on its hook
	draw_rect(Rect2(Vector2(bx - 9, ty - 8), Vector2(18, 1)), Color(0.4, 0.62, 0.8))


func _draw_flare() -> void:
	var p: Vector2 = info.get("flare", Vector2.ZERO)
	if p == Vector2.ZERO:
		return
	var h := 10.0 + sin(_t * 9.0) * 2.0 + sin(_t * 23.0) * 1.0
	draw_circle(p + Vector2(0, -4), 14.0, Color(1.0, 0.55, 0.15, 0.12))
	draw_colored_polygon(PackedVector2Array([p + Vector2(-4, 0), p + Vector2(sin(_t * 5.0) * 2.0, -h), p + Vector2(4, 0)]), Color(1.0, 0.5, 0.12, 0.9))
	draw_colored_polygon(PackedVector2Array([p + Vector2(-2, 0), p + Vector2(sin(_t * 7.0), -h * 0.6), p + Vector2(2, 0)]), Color(1.0, 0.92, 0.6, 0.95))


func _draw_launch() -> void:
	var lp: Vector2 = info.get("launch", Vector2.ZERO)
	if lp == Vector2.ZERO:
		return
	var period := 50.0
	var u := fposmod(_t + 20.0, period)
	var rise := 0.0
	if u > 40.0:
		rise = pow((u - 40.0) / 10.0, 2.0) * 400.0
	# the tower beside it, its lights counting down
	draw_rect(Rect2(lp + Vector2(10, -34), Vector2(3, 36)), Color(0.4, 0.4, 0.44))
	for k in 4:
		var on := u > 32.0 + k * 2.0 and u < 41.0
		draw_rect(Rect2(lp + Vector2(14, -30 + k * 7), Vector2(2, 2)), Color(1.0, 0.3, 0.2) if on else Color(0.3, 0.2, 0.2))
	if rise < 380.0:
		var rp := lp + Vector2(0, -rise)
		if rise > 0.0:
			for k2 in 3:
				_puffs.append([lp + Vector2(randf_range(-6, 6), 0), Vector2(randf_range(-20, 20), randf_range(-4, 2)), 2.0, 4.0, Color(0.85, 0.85, 0.85)])
			draw_colored_polygon(PackedVector2Array([rp + Vector2(-3, 2), rp + Vector2(0, 14 + sin(_t * 30.0) * 3.0), rp + Vector2(3, 2)]), Color(1.0, 0.7, 0.25))
		draw_rect(Rect2(rp + Vector2(-3, -26), Vector2(6, 28)), Color(0.92, 0.92, 0.94))
		draw_rect(Rect2(rp + Vector2(-3, -26), Vector2(2, 28)), Color(1, 1, 1))
		draw_colored_polygon(PackedVector2Array([rp + Vector2(-3, -26), rp + Vector2(0, -34), rp + Vector2(3, -26)]), Color(0.85, 0.3, 0.25))
		draw_rect(Rect2(rp + Vector2(-5, -4), Vector2(2, 6)), Color(0.6, 0.6, 0.65))
		draw_rect(Rect2(rp + Vector2(3, -4), Vector2(2, 6)), Color(0.6, 0.6, 0.65))


func _boat(p: Vector2, dir: Vector2) -> void:
	var f := 1.0 if dir.x >= 0.0 else -1.0
	for k in 3:
		draw_line(p - dir * (8 + k * 5), p - dir * (8 + k * 5) + dir.orthogonal() * (3 + k * 2), Color(0.85, 0.92, 1.0, 0.5 - k * 0.12), 1.0)
	draw_colored_polygon(PackedVector2Array([p + Vector2(-9, -2), p + Vector2(9 * f, -2) if f > 0 else p + Vector2(-9, -2), p + Vector2(11 * f, 0), p + Vector2(8 * f, 3), p + Vector2(-8 * f, 3)]), Color(0.85, 0.85, 0.82))
	draw_rect(Rect2(p + Vector2(-4, -6), Vector2(7, 5)), Color(0.75, 0.3, 0.25))
	draw_rect(Rect2(p + Vector2(-3, -5), Vector2(5, 2)), Color(0.5, 0.7, 0.85))
