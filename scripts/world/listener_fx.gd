extends Node2D
## Package 58, part 5 (Luz): Silas Marr's Listener on his Bastion – antenna arms unfold from the hull, a dish rises
## and turns with a ring of light round it, and every few seconds a listening pulse runs out across the field.
## A child of the ship: drawn in its frame (the ship's heading), the pulses in world size.

var ship: Node2D = null
var unfold := 0.0                       # 0 folded … 1 out
var active := true                      # false: folding away again
var _t := 0.0
var _pulses: Array = []                 # ages (s) of the pulses running out
var _next := 0.0

const PULSE_EVERY := 3.2
const PULSE_LIFE := 2.6
const PULSE_R := 5200.0                 # how far a pulse runs (world units)


func _ready() -> void:
	z_index = 3


func _process(dt: float) -> void:
	_t += dt
	unfold = move_toward(unfold, 1.0 if active else 0.0, dt * 0.45)
	if active and unfold > 0.95:
		_next -= dt
		if _next <= 0.0:
			_next = PULSE_EVERY
			_pulses.append(0.0)
	for i in range(_pulses.size() - 1, -1, -1):
		_pulses[i] = float(_pulses[i]) + dt
		if float(_pulses[i]) > PULSE_LIFE:
			_pulses.remove_at(i)
	if not active and unfold <= 0.0 and _pulses.is_empty():
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	if ship == null or not is_instance_valid(ship):
		return
	var R: float = maxf(float(ship.get("radius")), 30.0)
	var head: float = float(ship.get("heading"))
	var cyan := Color(0.45, 0.9, 1.0)
	# the pulses: rings running out over the field, fading
	for age in _pulses:
		var k := float(age) / PULSE_LIFE
		var r := lerpf(R * 0.8, PULSE_R, ease(k, 0.6))
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 128, Color(cyan, 0.85 * (1.0 - k)), maxf(4.0, R * 0.08 * (1.0 - k)))
		draw_arc(Vector2.ZERO, r * 0.96, 0.0, TAU, 128, Color(cyan, 0.3 * (1.0 - k)), maxf(3.0, R * 0.2 * (1.0 - k)))
	if unfold <= 0.01:
		return
	draw_set_transform(Vector2.ZERO, head, Vector2.ONE)
	var u := ease(unfold, 0.5)
	var metal := Color(0.55, 0.6, 0.68)
	# four antenna arms out to the sides, each with a blinking tip
	for side in [-1.0, 1.0]:
		for along in [-0.35, 0.25]:
			var base := Vector2(R * along, side * R * 0.25)
			var tip := base + Vector2(R * 0.1, side * R * 0.95 * u)
			draw_line(base, tip, Color(0.08, 0.09, 0.12), maxf(7.0, R * 0.11))
			draw_line(base, tip, metal, maxf(4.0, R * 0.06))
			draw_line(base, tip, Color(cyan, 0.5), maxf(1.5, R * 0.02))
			var blink := 0.5 + 0.5 * sin(_t * 6.0 + along * 7.0 + side)
			draw_circle(tip, maxf(8.0, R * 0.12) * (0.7 + 0.5 * blink), Color(cyan, 0.25 * blink))
			draw_circle(tip, maxf(4.0, R * 0.07), Color(cyan, 0.5 + 0.5 * blink))
	# the dish on its mast, turning, with its ring of light
	var mast := Vector2(-R * 0.05, 0.0)
	var dr := R * 0.5 * u
	draw_circle(mast, dr * 2.2, Color(cyan, 0.08 + 0.06 * sin(_t * 3.0)))          # its glow
	draw_circle(mast, dr * 1.15, Color(0.06, 0.07, 0.1, 0.9))
	draw_circle(mast, dr, Color(0.7, 0.74, 0.8))
	draw_circle(mast, dr * 0.72, Color(0.42, 0.46, 0.54))
	var ang := _t * 1.4
	draw_line(mast, mast + Vector2.from_angle(ang) * dr * 1.25, Color(0.85, 0.9, 1.0), maxf(2.0, R * 0.03))
	draw_circle(mast + Vector2.from_angle(ang) * dr * 1.25, maxf(2.5, R * 0.035), cyan)
	draw_arc(mast, dr * 1.45, ang, ang + PI * 1.2, 32, Color(cyan, 0.9), maxf(4.0, R * 0.06))
	draw_arc(mast, dr * 1.8, -ang * 0.7, -ang * 0.7 + PI * 0.6, 24, Color(cyan, 0.6), maxf(3.0, R * 0.04))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
