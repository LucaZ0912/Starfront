class_name Projectile
extends Node2D
## Kinetic rounds (straight, with lead) and explosive rockets (homing, area damage).

var shooter = null
var target = null
var faction := ""
var damage := 0.0
var dtype := "kinetic"
var splash := 0.0
var homing := false
var cap_drain := 0.0             # ion torpedo: drains the capacitor of the ship it hits
var speed := 1000.0
var life := 1.0
var vel := Vector2.ZERO
var color := Color.WHITE
var view: Node


func setup(p_shooter, p_target, w: Dictionary, p_view: Node) -> void:
	shooter = p_shooter
	target = p_target
	view = p_view
	faction = p_shooter.faction
	damage = float(w["damage"])
	dtype = w["damage_type"]
	splash = float(w.get("splash", 0.0))
	homing = bool(w.get("homing", false))
	cap_drain = float(w.get("cap_drain", 0.0))
	speed = float(w["projectile_speed"])
	color = GameData.DAMAGE_COLORS[dtype]
	position = p_shooter.position
	# compute lead
	var tpos: Vector2 = p_target.position
	var t := position.distance_to(tpos) / speed
	var aim: Vector2 = tpos + p_target.velocity * t
	var dir := (aim - position).normalized()
	if not homing:
		dir = dir.rotated(randf_range(-0.03, 0.03))
	else:
		dir = dir.rotated(randf_range(-0.5, 0.5))
	vel = dir * speed
	life = float(w["range"]) / speed * 1.5 + 0.3
	rotation = vel.angle()


func _physics_process(delta: float) -> void:
	life -= delta
	if homing and target != null and is_instance_valid(target) and target.is_targetable():
		var desired: Vector2 = (target.position - position).normalized() * speed
		vel = vel.move_toward(desired, speed * 3.0 * delta)
	position += vel * delta
	rotation = vel.angle()
	# Colossal asteroids stop shots (cover) – the shot bursts on the surface, no damage
	for co in view.colossi:
		var rel: Vector2 = position - co.position
		if rel.length() < float(co.radius) and ColossusShape.contains(co.poly, rel):
			view.spawn_fx(Fx.explosion(position, maxf(splash * 0.5, 10.0), Color(0.85, 0.8, 0.7)))
			queue_free()
			return
	for n in get_tree().get_nodes_in_group("ships"):
		if not n.is_targetable() or not _hits(n):
			continue
		if position.distance_to(n.position) < n.radius:
			_impact(n)
			return
	if life <= 0.0:
		if splash > 0.0:
			_impact(null)
		else:
			queue_free()
	queue_redraw()


## Shots hit their own target and ships hostile to the shooter (never the shooter itself).
func _hits(n) -> bool:
	if n == target:
		return true
	if shooter != null and is_instance_valid(shooter):
		return n != shooter and Ship.hostile(shooter, n)
	return Ship.are_hostile(faction, n.faction)


func _impact(hit) -> void:
	var src = shooter if (shooter != null and is_instance_valid(shooter)) else null
	if splash > 0.0:
		for n in get_tree().get_nodes_in_group("ships"):
			if not n.is_targetable() or not _hits(n):
				continue
			var d := position.distance_to(n.position)
			if d < splash + n.radius:
				var falloff := 1.0 - 0.5 * clampf(d / (splash + n.radius), 0.0, 1.0)
				n.take_damage(damage * falloff, dtype, src)
		view.spawn_fx(Fx.explosion(position, splash, color))
	elif hit != null:
		if cap_drain > 0.0:
			hit.fit.capacitor = maxf(0.0, hit.fit.capacitor - cap_drain)
		hit.take_damage(damage, dtype, src)
		view.spawn_fx(Fx.explosion(position, 12.0, color))
	queue_free()


func _draw() -> void:
	if homing:
		draw_colored_polygon(PackedVector2Array([Vector2(7, 0), Vector2(-5, 3), Vector2(-5, -3)]), color)
		draw_line(Vector2(-5, 0), Vector2(-18, 0), Color(1.0, 0.7, 0.3, 0.6), 2.0)
	else:
		draw_line(Vector2(-10, 0), Vector2(4, 0), color, 2.0)
