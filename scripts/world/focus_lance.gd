extends Node2D
## The bundled focus lance of the Covenant's Acolyte and Templar (package 25f, 0.4.25.32): the red beams
## of all crystals meet in one point between the ship and its target, charge it for a moment, then a thick
## beam burns into the target for about a second (the damage is dealt over that second).

const CHARGE := 0.55             # seconds the beams feed the meeting point
const BURN := 1.0                # seconds the lance burns into the target
const MEET := 0.38               # where the beams meet: share of the way from the ship to the target

var shooter = null
var target = null
var view = null
var damage := 0.0
var dtype := "optical"
var n := 3
var width := 10.0
var col := Color(1.0, 0.18, 0.12)
var t := 0.0
var _dealt := 0.0
var reach := 900.0


func setup(p_shooter, p_target, w: Dictionary, p_view) -> void:
	shooter = p_shooter
	target = p_target
	view = p_view
	damage = float(w["damage"])
	dtype = String(w["damage_type"])
	n = maxi(int(w.get("bundle", 3)), 2)
	width = 6.0 + float(n) * 2.0
	reach = float(w.get("range", 900.0))
	z_index = 5


func _valid(o) -> bool:
	return o != null and is_instance_valid(o) and not o.dying


func _meet() -> Vector2:
	return shooter.position.lerp(target.position, MEET)


## Review K7: the lance breaks off when its target warps away, cloaks or gets far out of reach.
func _gone() -> bool:
	if target is Ship and (target.in_warp() or not target.is_targetable()):
		return true
	return shooter.position.distance_to(target.position) > reach * 1.5


func _process(delta: float) -> void:
	if not _valid(shooter) or not _valid(target) or _gone():
		queue_free()
		return
	t += delta
	if t > CHARGE:
		# burn: the damage is dealt bit by bit over BURN seconds
		var share := clampf((t - CHARGE) / BURN, 0.0, 1.0)
		var due := damage * share - _dealt
		if due > 0.0:
			_dealt += due
			target.take_damage(due, dtype, shooter)
	if t >= CHARGE + BURN:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	if not _valid(shooter) or not _valid(target):
		return
	var meet: Vector2 = _meet() - position
	var fwd: Vector2 = (target.position - shooter.position).normalized()
	var side: Vector2 = fwd.orthogonal()
	var r := float(shooter.radius)
	var charge := clampf(t / CHARGE, 0.0, 1.0)
	# the crystal beams from the ship's hardpoints into the meeting point
	for k in n:
		var s := (float(k) / maxf(float(n - 1), 1.0)) * 2.0 - 1.0
		var from: Vector2 = shooter.position - position + side * s * r * 0.55
		var a := 0.55 + 0.45 * charge
		draw_line(from, meet, Color(col, a), 2.5)
		draw_line(from, meet, Color(1.0, 0.8, 0.7, a * 0.6), 1.0)
	# the charged point
	var glow := r * (0.12 + 0.25 * charge)
	var flick := randf_range(0.85, 1.15)
	draw_circle(meet, glow * 2.2 * flick, Color(col, 0.18 + 0.2 * charge))
	draw_circle(meet, glow * flick, Color(1.0, 0.45, 0.3, 0.7))
	draw_circle(meet, glow * 0.45 * flick, Color(1, 1, 1, 0.9))
	if t <= CHARGE:
		return
	# the lance: a thick beam from the point into the target, flickering, fading at the end
	var burn := clampf((t - CHARGE) / BURN, 0.0, 1.0)
	var fade := 1.0 - maxf(0.0, (burn - 0.8) / 0.2)
	var to: Vector2 = target.position - position
	var wd := width * randf_range(0.9, 1.1)
	draw_line(meet, to, Color(col, 0.35 * fade), wd * 2.2)
	draw_line(meet, to, Color(col, 0.9 * fade), wd)
	draw_line(meet, to, Color(1.0, 0.85, 0.75, 0.9 * fade), wd * 0.35)
	draw_circle(to, wd * 1.3 * flick, Color(1.0, 0.5, 0.3, 0.6 * fade))
