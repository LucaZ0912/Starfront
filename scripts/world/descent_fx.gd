class_name DescentFx
extends Node2D
## Package 50: what the eye sees of a descent or an ascent – the engine's flame while the ship speeds up, and on
## worlds with an air the heat of the way down: a glowing bow shock in front of the ship, plasma streaming past it,
## flickering. The view sets `flame` and `heat` (0…1) and keeps the node on the ship.

var ship: Node2D = null
var flame := 0.0
var heat := 0.0
var size := 60.0                      # the ship's radius (km)
var heat_col := Color(1.0, 0.55, 0.2)
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	if ship != null and is_instance_valid(ship):
		position = ship.position
		rotation = float(ship.get("heading"))
		# the flame shrinks with the ship; the heat round it stays big – a glowing ball sinking into the world
		var ss := float(ship.scale.x)
		scale = Vector2.ONE * lerpf(ss, maxf(ss, 0.85), clampf(heat * 1.5, 0.0, 1.0))
	queue_redraw()


func _draw() -> void:
	var r := size
	# the flame behind the ship (it flies along +x)
	if flame > 0.01:
		for i in 4:
			var len := r * (1.6 + 1.4 * flame) * (1.0 - i * 0.18) * (0.9 + 0.1 * sin(_t * 40.0 + i))
			var w := r * (0.38 - i * 0.07)
			var pts := PackedVector2Array([Vector2(-r * 0.6, -w), Vector2(-r * 0.6 - len, 0.0), Vector2(-r * 0.6, w)])
			draw_colored_polygon(pts, Color([Color(1.0, 0.45, 0.1), Color(1.0, 0.75, 0.2), Color(1.0, 0.95, 0.6), Color(1, 1, 1)][i], flame * (0.35 + i * 0.15)))
	if heat <= 0.01:
		return
	# the bow shock: layered glow in front of the ship
	var fl := 0.85 + 0.15 * sin(_t * 31.0) * sin(_t * 13.0)
	draw_circle(Vector2.ZERO, r * 2.4, Color(heat_col, heat * 0.12))                # the glow all round
	draw_circle(Vector2(r * 0.3, 0), r * 1.5, Color(1.0, 0.75, 0.45, heat * 0.18))
	for k in 5:
		var rr := r * (1.25 + k * 0.32)
		var a := heat * fl * (0.45 - k * 0.07)
		draw_arc(Vector2(r * 0.15, 0), rr, -1.25, 1.25, 28, Color(heat_col.lerp(Color(1, 1, 0.85), 0.5 - k * 0.1), a), r * 0.28)
	draw_circle(Vector2(r * 0.7, 0), r * 0.55, Color(1.0, 0.9, 0.7, heat * 0.35 * fl))
	# plasma streaming past along the hull, behind the ship
	for s in 14:
		var side := -1.0 if s % 2 == 0 else 1.0
		var ph := fposmod(_t * (2.2 + (s % 5) * 0.4) + s * 0.37, 1.0)
		var y := side * r * (0.75 + 0.35 * sin(s * 1.7))
		var x0 := r * (0.9 - ph * 3.4)
		draw_line(Vector2(x0, y * (1.0 + ph * 0.6)), Vector2(x0 - r * 0.9, y * (1.0 + ph * 0.9)), Color(heat_col, heat * (1.0 - ph) * 0.8), r * 0.09)
	# a shimmer of heat all round
	for j in 3:
		draw_arc(Vector2.ZERO, r * (1.1 + 0.1 * sin(_t * 9.0 + j * 2.0)), 0.0, TAU, 32, Color(1.0, 0.7, 0.4, heat * 0.12), r * 0.12)
