class_name DescentFx
extends Node2D
## Package 50: what the eye sees of a descent or an ascent – the engine's flame while the ship speeds up, and on
## worlds with an air the heat of the way down. The view sets `flame` and `heat` (0…1) and keeps the node on the ship.
## 0.7.50.16 (Luz: "the flame far too big, the heat wants more detail"): the flame keeps to the ship's own size (it
## shrinks with her as she sinks) – a hot core, its outer glow, shock diamonds in it; the heat is a bow shock shaped
## round her nose – layered from white-hot at the stagnation point through orange to a dim red edge, flickering – a
## turbulent plasma wake streaming back from its rim, sparks of the ablating hull shed behind her, and a soft glow of
## ionised air round it all. The heat stays a little bigger than the sinking ship, so it reads as a glowing ember.

var ship: Node2D = null
var flame := 0.0
var heat := 0.0
var size := 60.0                      # the ship's radius (km)
var heat_col := Color(1.0, 0.55, 0.2)
var _t := 0.0
var _ss := 1.0                        # the ship's own scale (the flame)
var _hs := 1.0                        # the heat's scale
var _sparks: Array = []               # [pos (in r), vel (r/s), life, max life]


func _ready() -> void:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD          # fire and plasma add their light
	material = m


func _process(delta: float) -> void:
	_t += delta
	if ship != null and is_instance_valid(ship):
		position = ship.position
		rotation = float(ship.get("heading"))
		_ss = float(ship.scale.x)
		_hs = lerpf(_ss, maxf(_ss, 0.35), clampf(heat * 1.4, 0.0, 1.0))
	# sparks of the hull, shed from the rim of the shock and blown back
	if heat > 0.05:
		if randf() < heat * 70.0 * delta:
			var side := -1.0 if randf() < 0.5 else 1.0
			var y := side * randf_range(0.4, 1.1)
			_sparks.append([Vector2(randf_range(0.1, 0.7), y), Vector2(randf_range(-9.0, -5.0), y * randf_range(0.3, 1.0)), 0.0, randf_range(0.35, 0.8)])
	for s in _sparks:
		s[0] = (s[0] as Vector2) + (s[1] as Vector2) * delta
		s[2] = float(s[2]) + delta
	_sparks = _sparks.filter(func(s): return float(s[2]) < float(s[3]))
	queue_redraw()


func _draw() -> void:
	var r := size
	if flame > 0.01:
		_draw_flame(r * _ss)
	if heat > 0.01:
		_draw_heat(r * _hs)


## The engine's flame behind her (she flies along +x): its glow, the flame, the hot core, shock diamonds.
func _draw_flame(r: float) -> void:
	var x0 := -r * 0.62
	var L := r * (0.9 + 0.9 * flame)
	var flick := 0.92 + 0.08 * sin(_t * 47.0) * sin(_t * 19.0)
	draw_circle(Vector2(x0, 0), r * 0.42, Color(1.0, 0.6, 0.25, 0.18 * flame))
	var layers := [[1.0, 0.34, Color(1.0, 0.42, 0.12), 0.32], [0.78, 0.25, Color(1.0, 0.7, 0.25), 0.45], [0.55, 0.15, Color(1.0, 0.93, 0.65), 0.6], [0.34, 0.07, Color(1, 1, 1), 0.75]]
	for ly in layers:
		var len: float = L * float(ly[0]) * flick
		var w: float = r * float(ly[1])
		var pts := PackedVector2Array()
		for i in 9:
			var u := float(i) / 8.0
			pts.append(Vector2(x0 - len * u, w * sin(PI * 0.5 + u * PI * 0.5) * (1.0 - u * 0.15)))
		for i in range(7, -1, -1):
			var u2 := float(i) / 8.0
			pts.append(Vector2(x0 - len * u2, -w * sin(PI * 0.5 + u2 * PI * 0.5) * (1.0 - u2 * 0.15)))
		draw_colored_polygon(pts, Color(ly[2] as Color, flame * float(ly[3])))
	for d in 3:                                                           # shock diamonds
		var dx := x0 - L * (0.22 + d * 0.2)
		var dw := r * 0.06 * (1.0 - d * 0.25)
		draw_colored_polygon(PackedVector2Array([Vector2(dx + dw * 2.0, 0), Vector2(dx, dw), Vector2(dx - dw * 2.0, 0), Vector2(dx, -dw)]),
			Color(1, 1, 0.9, flame * (0.7 - d * 0.18) * flick))


## The heat of the way down: glow, wake, the shock shell round her nose, the white-hot point, streaks, sparks.
func _draw_heat(r: float) -> void:
	var fl := 0.85 + 0.15 * sin(_t * 31.0) * sin(_t * 13.0)
	var hot := Color(1.0, 0.96, 0.85)
	var mid := heat_col.lerp(Color(1.0, 0.75, 0.35), 0.5)
	var edge := heat_col.lerp(Color(0.75, 0.15, 0.3), 0.45)
	# the ionised air all round
	draw_circle(Vector2(r * 0.3, 0), r * 2.1, Color(heat_col, heat * 0.05))
	draw_circle(Vector2(r * 0.6, 0), r * 1.3, Color(mid, heat * 0.07))
	# the wake: plasma streaming back from the shock's rim, wavering, thinning out
	for k in 3:
		var wl := r * (3.4 - k * 0.8) * (0.9 + 0.1 * heat)
		var ww := r * (1.15 - k * 0.25)
		var pts := PackedVector2Array()
		var n := 14
		for i in n + 1:
			var u := float(i) / n
			var wob := sin(_t * (11.0 + k * 3.0) - u * 9.0 + k) * r * 0.07 * u
			pts.append(Vector2(r * 0.3 - wl * u, ww * (pow(1.0 - u, 0.7) + 0.03) * (1.0 + 0.25 * sin(u * PI)) + wob))
		for i in range(n, -1, -1):
			var u2 := float(i) / n
			var wob2 := sin(_t * (11.0 + k * 3.0) - u2 * 9.0 + k) * r * 0.07 * u2      # (the same: the wake sways, it does not cross)
			pts.append(Vector2(r * 0.3 - wl * u2, -ww * (pow(1.0 - u2, 0.7) + 0.03) * (1.0 + 0.25 * sin(u2 * PI)) + wob2))
		draw_colored_polygon(pts, Color([edge, heat_col, mid][k], heat * [0.14, 0.16, 0.18][k] * fl))
	# turbulent bands in the wake
	for b in 8:
		var side := -1.0 if b % 2 == 0 else 1.0
		var ph := fposmod(_t * (1.6 + (b % 4) * 0.35) + b * 0.29, 1.0)
		var y := side * r * (0.55 + 0.4 * sin(b * 2.3))
		var x := r * (0.4 - ph * 3.6)
		draw_line(Vector2(x, y * (1.0 - ph * 0.4)), Vector2(x - r * (0.5 + ph * 0.6), y * (1.0 - ph * 0.55)), Color(mid.lerp(hot, 0.3), heat * (1.0 - ph) * 0.55), r * 0.05)
	# the bow shock: a shell round her nose, three layers, its edge flickering
	for k2 in 3:
		var vx := r * (1.28 - k2 * 0.12)
		var th := r * (0.55 - k2 * 0.18)
		var half := r * (1.25 - k2 * 0.18)
		var outer := PackedVector2Array()
		var inner := PackedVector2Array()
		var m := 18
		for i in m + 1:
			var yy := lerpf(-half, half, float(i) / m)
			var q := yy / half
			var jit := sin(_t * 37.0 + yy * 0.9 / maxf(r, 0.001) * 6.0 + k2) * r * 0.035
			var bx := vx - r * 1.05 * q * q + jit
			var nrm := Vector2(1.0, 2.0 * r * 1.05 * q / half).normalized()     # the shell's normal, forwards
			outer.append(Vector2(bx, yy))
			inner.append(Vector2(bx, yy) - nrm * th * (1.0 - 0.88 * q * q))
		inner.reverse()
		var band := outer + inner
		draw_colored_polygon(band, Color([edge, mid, hot][k2], heat * fl * [0.35, 0.4, 0.5][k2]))
	# the stagnation point – white-hot at her nose
	draw_circle(Vector2(r * 1.0, 0), r * 0.38, Color(hot, heat * 0.45 * fl))
	draw_circle(Vector2(r * 1.08, 0), r * 0.18, Color(1, 1, 1, heat * 0.7 * fl))
	# streaks flowing over the shell and off its rim
	for s2 in 6:
		var ph2 := fposmod(_t * 2.6 + s2 * 0.17, 1.0)
		var side2 := -1.0 if s2 % 2 == 0 else 1.0
		var yy2 := side2 * r * (0.2 + ph2 * 1.0)
		var q2 := yy2 / (r * 1.25)
		var xx := r * 1.2 - r * 1.05 * q2 * q2
		draw_line(Vector2(xx, yy2), Vector2(xx - r * 0.35, yy2 + side2 * r * 0.12), Color(hot, heat * 0.5 * (1.0 - ph2)), r * 0.035)
	# sparks of the hull
	for sp in _sparks:
		var a := 1.0 - float(sp[2]) / float(sp[3])
		var p: Vector2 = (sp[0] as Vector2) * r
		draw_line(p, p - (sp[1] as Vector2).normalized() * r * 0.12, Color(1.0, 0.85, 0.5, heat * a), maxf(r * 0.03, 1.0))
		draw_circle(p, maxf(r * 0.025, 0.8), Color(1, 1, 0.9, heat * a))
