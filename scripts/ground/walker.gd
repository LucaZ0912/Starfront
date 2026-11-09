class_name Walker
extends Node2D
## Package 49: someone on foot – the pilot or a person on the deck. Position in art px of the GroundMap (the view
## draws everything ×SCALE); the top-down sprite from PilotArt, turned to where it walks, bobbing while it moves.

const PilotArt = preload("res://scripts/core/pilot_art.gd")
const SPEED := 58.0                # art px per second
const RADIUS := 4.0

var map: GroundMap
var look: Dictionary = {}
var pos := Vector2.ZERO            # art px
var facing := 0.0
var moving := false
var sitting := false
var npc := false
var _t := 0.0
var _goal := Vector2.INF
var _wait := 0.0
var _tex: Texture2D


func setup(p_map: GroundMap, p_look: Dictionary, p_pos: Vector2, p_npc: bool) -> void:
	map = p_map
	look = p_look
	pos = p_pos
	npc = p_npc
	_tex = PilotArt.sprite(look)
	position = pos * GroundMap.SCALE
	_wait = randf_range(0.0, 3.0)


## Moves by `dir` (length ≤ 1) for `delta` seconds, sliding along walls. Returns true if it moved at all.
func step(dir: Vector2, delta: float, speed_mult: float = 1.0) -> bool:
	moving = false
	if dir.length() < 0.05:
		return false
	var d := dir.limit_length(1.0) * SPEED * speed_mult * delta
	var moved := false
	var nx := pos + Vector2(d.x, 0.0)
	if map.free_at(nx, RADIUS):
		pos = nx
		moved = true
	var ny := pos + Vector2(0.0, d.y)
	if map.free_at(ny, RADIUS):
		pos = ny
		moved = true
	if moved:
		facing = lerp_angle(facing, dir.angle(), clampf(delta * 14.0, 0.0, 1.0))
		moving = true
	position = pos * GroundMap.SCALE
	return moved


func _process(delta: float) -> void:
	_t += delta
	if npc and not sitting:
		_wander(delta)
	queue_redraw()


## People on the deck stroll from one spot of the promenade to the next and stand about a while.
func _wander(delta: float) -> void:
	if _wait > 0.0:
		_wait -= delta
		moving = false
		return
	if _goal == Vector2.INF:
		if map.wander.is_empty():
			return
		_goal = map.wander[randi() % map.wander.size()]
	var to := _goal - pos
	if to.length() < 4.0 or not step(to.normalized(), delta, 0.6):
		_goal = Vector2.INF
		_wait = randf_range(1.5, 6.0)


func _draw() -> void:
	if _tex == null:
		return
	var s := GroundMap.SCALE
	var bob := 0.0
	if moving:
		bob = sin(_t * 14.0) * 0.6
	var size := Vector2(_tex.get_width(), _tex.get_height()) * s
	# a soft shadow, then the body turned to where it faces
	draw_circle(Vector2(1.5, 2.5) * s, 5.0 * s, Color(0, 0, 0, 0.25))
	if not npc:
		draw_arc(Vector2.ZERO, 9.0 * s, 0.0, TAU, 32, Color(0.35, 1.0, 0.55, 0.75 + 0.2 * sin(_t * 4.0)), 2.0)      # that is you
	draw_set_transform(Vector2(0, bob * s), facing, Vector2.ONE * (0.92 if sitting else 1.0))
	draw_texture_rect(_tex, Rect2(-size * 0.5, size), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
