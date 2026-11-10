class_name EconLife
extends Node2D
## 0.7.50.12: life in a settlement's economy area (GroundMap.econ) – drawn in art px (the node is scaled).
## 0.7.50.13 (Luz: "keep the sizes consistent"): every machine to scale with the people (VehicleArt). The mine is now
## seen from its rim: below the berm the pit falls away bench by bench into the haze – a haul truck on the first
## bench, the excavator loading another on the next, a third far down; things deeper lie further in the haze.
## Fields: a combine harvester working a field, crop drones · works: smoke, the gantry crane, a delivery truck · tank
## farm: the flare, a tanker · dishes: a maintenance drone · training yard: an armoured vehicle on its round, a drone ·
## gardens: birds · fish pens and rigs: a work boat.

var info: Dictionary = {}
var _t := 0.0
var _puffs: Array = []                # [pos, vel, life, size, colour]
const HAZE := Color(0.62, 0.66, 0.74)


func setup(p_info: Dictionary) -> void:
	info = p_info
	scale = Vector2.ONE * GroundMap.SCALE
	z_index = 1


func _process(delta: float) -> void:
	_t += delta
	for p in _puffs:
		p[0] = (p[0] as Vector2) + (p[1] as Vector2) * delta
		p[2] = float(p[2]) - delta
	_puffs = _puffs.filter(func(p): return float(p[2]) > 0.0)
	match String(info.get("kind", "")):
		"industry":
			for s in info.get("stacks", []):
				if randf() < delta * 8.0:
					_puffs.append([s + Vector2(randf_range(-3, 3), 0), Vector2(randf_range(5, 12), randf_range(-18, -10)), randf_range(3.0, 5.0), randf_range(5.0, 9.0), Color(0.58, 0.58, 0.6)])
	queue_redraw()


## Ping-pong along a path: [position, heading, going back].
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


## A vehicle picture standing with its wheels on `foot` (bottom centre), facing its way (east or west).
func _vehicle(kind: String, foot: Vector2, east: bool, col: Color = Color(0.95, 0.75, 0.15), tint: Color = Color.WHITE) -> void:
	var tex := VehicleArt.texture(kind, col)
	var sz := Vector2(tex.get_width(), tex.get_height())
	if kind in VehicleArt.HOVER:
		# 0.7.50.14: it floats – its light on the ground below, a gentle bob
		draw_set_transform(foot, 0.0, Vector2(1.0, 0.22))
		draw_circle(Vector2.ZERO, sz.x * 0.42, Color(VehicleArt.GLOW, 0.16))
		draw_circle(Vector2.ZERO, sz.x * 0.25, Color(VehicleArt.GLOW, 0.14))
		foot += Vector2(0, -6.0 + sin(_t * 2.4 + foot.x * 0.02) * 1.5)
	draw_set_transform(foot, 0.0, Vector2(1.0 if east else -1.0, 1.0))
	draw_texture_rect(tex, Rect2(Vector2(-sz.x * 0.5, -sz.y), sz), false, tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw() -> void:
	var r: Rect2 = info.get("rect", Rect2())
	match String(info.get("kind", "")):
		"mining":
			_draw_mining(r)
		"agri", "hydro":
			_draw_fields()
		"industry":
			_draw_crane()
			var road2: Array = info.get("road", [])
			if road2.size() == 2:
				var af := _along(road2, _t * 20.0)
				_vehicle("tanker", af[0], (af[1] as Vector2).x >= 0.0, Color(0.9, 0.5, 0.15))
		"refinery", "chemistry":
			_draw_flare()
			var road: Array = info.get("road", [])
			if road.size() == 2:
				var a := _along(road, _t * 20.0)
				_vehicle("tanker", a[0], (a[1] as Vector2).x >= 0.0, Color(0.2, 0.45, 0.7))
		"research", "hightech":
			var c := r.get_center()
			_drone(c + Vector2(cos(_t * 0.4) * r.size.x * 0.35, sin(_t * 0.7) * r.size.y * 0.3), Color(0.4, 1.0, 0.6))
		"military":
			var lr: Rect2 = info.get("loop", Rect2())
			var loop := [Vector2(lr.position.x, lr.end.y), Vector2(lr.end.x, lr.end.y)]
			var a2 := _along(loop, _t * 22.0)
			_vehicle("apc", a2[0], (a2[1] as Vector2).x >= 0.0, Color(0.36, 0.42, 0.3))
			_drone(lr.get_center() + Vector2(cos(_t * 0.5), sin(_t * 0.5) * 0.6) * 60.0 + Vector2(0, -60), Color(1.0, 0.3, 0.25))
		"tourism":
			for b in 5:
				var bp := r.position + Vector2(fposmod(_t * 22.0 + b * 70.0, r.size.x), 30.0 + b * 60.0 + sin(_t * 2.0 + b) * 8.0)
				var flap := 3.0 if fposmod(_t * 6.0 + b, 1.0) < 0.5 else -2.0
				draw_line(bp, bp + Vector2(-5, flap), Color(0.15, 0.15, 0.18), 1.0)
				draw_line(bp, bp + Vector2(5, flap), Color(0.15, 0.15, 0.18), 1.0)
		"pens", "rig":
			if String(info["kind"]) == "rig":
				_draw_flare()
			var pens: Array = info.get("pens", [])
			if pens.size() >= 2:
				var a3 := _along(pens, _t * 16.0)
				var bp2: Vector2 = a3[0]
				var east := (a3[1] as Vector2).x >= 0.0
				for k in 4:
					var wk := bp2 + Vector2((-1.0 if east else 1.0) * (60 + k * 12), -4 + k * 2)
					draw_line(wk, wk + Vector2(0, 6 + k * 2), Color(0.85, 0.92, 1.0, 0.45 - k * 0.1), 2.0)
				_vehicle("boat", bp2, east, Color(0.85, 0.3, 0.2))
	for p in _puffs:
		var k2 := clampf(float(p[2]) / 3.0, 0.0, 1.0)
		draw_circle(p[0], float(p[3]) * (1.8 - k2), Color(p[4], 0.4 * k2))


# ---------------------------------------------------------------- the mine, seen from its rim

func _draw_mining(r: Rect2) -> void:
	var bands: Array = info.get("bands", [])
	if bands.size() < 7:
		return
	# deepest first: a truck far down, then the haze over it
	var b3: Array = bands[6]
	var a3 := _along([Vector2(r.position.x + 60, float(b3[1]) - 4), Vector2(r.end.x - 60, float(b3[1]) - 4)], _t * 14.0 + 200.0)
	_vehicle("haul_full" if bool(a3[2]) else "haul", a3[0], (a3[1] as Vector2).x >= 0.0)
	_haze(Rect2(r.position.x, float(bands[5][0]), r.size.x, r.end.y - float(bands[5][0])), 0.5)
	# the second bench: the excavator loading a truck – then it drives off and comes back
	var b2: Array = bands[4]
	var floor2 := float(b2[1]) - 6.0
	var ex := Vector2(r.position.x + 70, floor2)
	var cycle := fposmod(_t, 36.0)
	var load := clampf(cycle / 16.0, 0.0, 1.0)
	var tx := r.position.x + 196
	if cycle > 16.0:
		var k := (cycle - 16.0) / 20.0
		tx += sin(k * PI) * (r.size.x - 200)                     # away and back again
	_vehicle("haul_full" if load > 0.6 and cycle < 26.0 else "haul", Vector2(tx, floor2), cycle < 16.0 or cycle > 26.0)
	_excavator(ex, cycle < 16.0)
	_haze(Rect2(r.position.x, float(bands[3][0]), r.size.x, float(b2[1]) - float(bands[3][0])), 0.22)
	# the first bench, just below the rim: a loaded truck on its way up and over
	var b1: Array = bands[2]
	var a1 := _along([Vector2(r.position.x + 80, float(b1[1]) - 6), Vector2(r.end.x - 80, float(b1[1]) - 6)], _t * 18.0)
	_vehicle("haul_full" if bool(a1[2]) else "haul", a1[0], (a1[1] as Vector2).x >= 0.0)
	if randf() < 0.3:
		_puffs.append([(a1[0] as Vector2) + Vector2((-1.0 if (a1[1] as Vector2).x > 0 else 1.0) * 70, -6), Vector2(randf_range(-6, 6), randf_range(-8, -3)), 1.5, 6.0, Color(0.62, 0.55, 0.45)])


func _haze(rr: Rect2, a: float) -> void:
	draw_rect(rr, Color(HAZE, a))


## The excavator: its tracks and house (a picture), the boom, the stick and the bucket alive – digging at the face
## (west), swinging over to the truck (east) to tip its load.
func _excavator(foot: Vector2, working: bool) -> void:
	var tex := VehicleArt.texture("excavator", Color(0.95, 0.72, 0.12))
	var sz := Vector2(tex.get_width(), tex.get_height())
	draw_texture_rect(tex, Rect2(foot - Vector2(sz.x * 0.5, sz.y), sz), false)
	var phase := sin(_t * 0.55) if working else -0.6
	var root := foot + Vector2(-sz.x * 0.5 + 40, -sz.y + 30)
	var boom_ang := lerpf(-2.6, -0.5, (phase + 1.0) * 0.5)                # out over the face … over to the truck
	var j2 := root + Vector2.from_angle(boom_ang) * 70.0
	var j3 := j2 + Vector2.from_angle(boom_ang + 1.9 - (phase + 1.0) * 0.4) * 48.0
	var yel := Color(0.95, 0.72, 0.12)
	# 0.7.50.14: an articulated arm, glowing joints, a cutter claw with its plasma edge
	draw_line(root, j2, Color(0.08, 0.07, 0.1), 12.0)
	draw_line(root, j2, yel, 9.0)
	draw_line(root.lerp(j2, 0.15), root.lerp(j2, 0.85), Color(0.25, 0.26, 0.3), 3.0)
	draw_line(root.lerp(j2, 0.2), root.lerp(j2, 0.8), VehicleArt.GLOW, 1.0)
	draw_line(j2, j3, Color(0.08, 0.07, 0.1), 9.0)
	draw_line(j2, j3, yel.darkened(0.08), 6.0)
	for jp in [root, j2]:
		draw_circle(jp, 6.0, Color(0.15, 0.15, 0.18))
		draw_circle(jp, 3.0, VehicleArt.GLOW)
	var claw := PackedVector2Array([j3 + Vector2(-12, -6), j3 + Vector2(12, -6), j3 + Vector2(6, 12), j3 + Vector2(0, 6), j3 + Vector2(-6, 12)])
	draw_colored_polygon(claw, Color(0.3, 0.32, 0.36))
	var hot := Color(1.0, 0.45, 0.25, 0.6 + 0.4 * sin(_t * 18.0))
	draw_line(j3 + Vector2(-6, 12), j3 + Vector2(6, 12), hot, 2.0)
	draw_circle(j3 + Vector2(0, 12), 6.0, Color(1.0, 0.5, 0.3, 0.15))
	if working and phase < -0.85 and randf() < 0.4:
		_puffs.append([j3 + Vector2(randf_range(-8, 8), 6), Vector2(randf_range(-8, 8), randf_range(-10, -3)), 1.4, 5.0, Color(0.6, 0.52, 0.42)])


func _drone(p: Vector2, light: Color) -> void:
	draw_circle(p + Vector2(4, 24), 5.0, Color(0, 0, 0, 0.25))
	draw_rect(Rect2(p - Vector2(7, 2), Vector2(14, 5)), Color(0.3, 0.32, 0.36))
	for s in [-1.0, 1.0]:
		draw_line(p + Vector2(7 * s, 0), p + Vector2(12 * s, -3), Color(0.5, 0.52, 0.55), 2.0)
		draw_line(p + Vector2(12 * s - 4, -3), p + Vector2(12 * s + 4, -3), Color(0.7, 0.72, 0.75, 0.6), 1.0)
	if fposmod(_t * 2.0, 1.0) < 0.5:
		draw_rect(Rect2(p + Vector2(-1, 2), Vector2(3, 2)), light)


# ---------------------------------------------------------------- fields

func _draw_fields() -> void:
	var fields: Array = info.get("fields", [])
	if fields.is_empty():
		return
	if String(info["kind"]) == "agri":
		# the combine works one field, row by row – the cut part behind it
		var f: Rect2 = fields[1 % fields.size()]
		var rows := maxi(1, int(f.size.y / 40.0))
		var u := fposmod(_t * 14.0, f.size.x * rows)
		var row := int(u / f.size.x)
		var x := fmod(u, f.size.x)
		var east := row % 2 == 0
		if not east:
			x = f.size.x - x
		x = clampf(x, 80.0, f.size.x - 80.0)                # the machine stays on its field
		var y := f.position.y + 30 + row * 40
		draw_rect(Rect2(f.position, Vector2(f.size.x, minf(row * 40.0 + 4.0, f.size.y))), Color(0.6, 0.5, 0.28, 0.55))
		_vehicle("combine", Vector2(f.position.x + x, minf(y + 26, f.end.y + 10)), east, Color(0.2, 0.55, 0.25))
		if randf() < 0.3:
			_puffs.append([Vector2(f.position.x + x + (-60 if east else 60), y), Vector2((-8 if east else 8), -4), 1.4, 5.0, Color(0.88, 0.78, 0.45)])
	# crop drones drifting over the fields, spraying
	for d in 3:
		var fr: Rect2 = fields[(d * 2) % fields.size()]
		var p := fr.get_center() + Vector2(cos(_t * 0.5 + d * 2.1) * fr.size.x * 0.35, sin(_t * 0.8 + d) * fr.size.y * 0.3)
		_drone(p, Color(0.4, 1.0, 0.5))
		if fposmod(_t + d, 3.0) < 1.5:
			for k in 4:
				draw_rect(Rect2(p + Vector2(randf_range(-6, 6), randf_range(5, 14)), Vector2(1, 1)), Color(0.7, 0.9, 1.0, 0.6))


# ---------------------------------------------------------------- works, tank farms

func _draw_crane() -> void:
	var r: Rect2 = info.get("crane", Rect2())
	if r.size.x <= 0.0:
		return
	draw_rect(Rect2(r.position.x, r.position.y - 1, r.size.x, 3), Color(0.3, 0.3, 0.32))
	draw_rect(Rect2(r.position.x, r.end.y - 1, r.size.x, 3), Color(0.3, 0.3, 0.32))
	var bx := r.position.x + (0.5 + 0.4 * sin(_t * 0.2)) * r.size.x
	var ty := r.position.y + (0.25 + 0.5 * (0.5 + 0.5 * sin(_t * 0.5))) * r.size.y
	var hgt := 150.0                                         # a gantry ten metres tall
	for leg_y in [r.position.y, r.end.y]:
		draw_rect(Rect2(bx - 22, leg_y - hgt, 6, hgt), Color(0.85, 0.65, 0.12))
		draw_rect(Rect2(bx + 16, leg_y - hgt, 6, hgt), Color(0.85, 0.65, 0.12))
		for yy in range(int(leg_y - hgt + 10), int(leg_y), 18):
			draw_line(Vector2(bx - 16, yy), Vector2(bx + 16, yy + 14), Color(0.8, 0.6, 0.1), 1.0)
		draw_rect(Rect2(bx - 26, leg_y - 4, 52, 6), Color(0.3, 0.3, 0.32))
	draw_rect(Rect2(bx - 24, r.position.y - hgt - 10, 48, r.size.y + 12), Color(0.95, 0.75, 0.15))     # the bridge
	for yy2 in range(int(r.position.y - hgt - 8), int(r.end.y - hgt), 10):
		draw_line(Vector2(bx - 22, yy2), Vector2(bx + 22, yy2 + 8), Color(0.82, 0.62, 0.1), 1.0)
	draw_rect(Rect2(bx - 24, r.position.y - hgt - 10, 48, 2), Color(1.0, 0.92, 0.55))
	draw_rect(Rect2(bx - 14, ty - hgt - 8, 28, 14), Color(0.3, 0.3, 0.33))                     # the trolley
	draw_line(Vector2(bx - 6, ty - hgt + 6), Vector2(bx - 6, ty - 40), Color(0.2, 0.2, 0.22), 1.0)
	draw_line(Vector2(bx + 6, ty - hgt + 6), Vector2(bx + 6, ty - 40), Color(0.2, 0.2, 0.22), 1.0)
	# the container on its spreader: twelve metres long, it hangs east-west
	draw_rect(Rect2(Vector2(bx - 90, ty - 40), Vector2(180, 38)), Color(0.2, 0.45, 0.65))
	for cx in range(int(bx - 88), int(bx + 90), 3):
		draw_rect(Rect2(cx, ty - 38, 1, 34), Color(0.16, 0.38, 0.56))
	draw_rect(Rect2(Vector2(bx - 90, ty - 40), Vector2(180, 2)), Color(0.4, 0.62, 0.8))
	draw_rect(Rect2(Vector2(bx - 92, ty - 44), Vector2(184, 4)), Color(0.3, 0.3, 0.32))


func _draw_flare() -> void:
	var p: Vector2 = info.get("flare", Vector2.ZERO)
	if p == Vector2.ZERO:
		return
	var h := 34.0 + sin(_t * 9.0) * 5.0 + sin(_t * 23.0) * 3.0
	draw_circle(p + Vector2(0, -14), 40.0, Color(1.0, 0.55, 0.15, 0.1))
	draw_colored_polygon(PackedVector2Array([p + Vector2(-9, 0), p + Vector2(sin(_t * 5.0) * 5.0, -h), p + Vector2(9, 0)]), Color(1.0, 0.5, 0.12, 0.9))
	draw_colored_polygon(PackedVector2Array([p + Vector2(-4, 0), p + Vector2(sin(_t * 7.0) * 2.0, -h * 0.6), p + Vector2(4, 0)]), Color(1.0, 0.92, 0.6, 0.95))
