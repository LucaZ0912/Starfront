class_name Walker
extends Node2D
## Package 49: someone on foot – the pilot or a person on the deck. Position in art px of the GroundMap (the view
## draws everything ×SCALE) at the feet; 0.7.49.2: a small figure in the slanted view (ChibiArt), facing one of four
## ways, stepping while it walks.

const SPEED := 58.0                # art px per second
const RADIUS := 4.0

var map: GroundMap
var look: Dictionary = {}
var pos := Vector2.ZERO            # art px, the feet
var dir := 0                       # 0 down (towards you), 1 up, 2 left, 3 right
var moving := false
var sitting := false
var npc := false
var marker := ""                   # "!" over someone you can talk to
var stays := false                 # keeps its place (shopkeeper, bartender)
var _t := 0.0
var _walk := 0.0
var _goal := Vector2.INF
var _wait := 0.0


func setup(p_map: GroundMap, p_look: Dictionary, p_pos: Vector2, p_npc: bool) -> void:
	map = p_map
	look = p_look
	pos = p_pos
	npc = p_npc
	position = pos * GroundMap.SCALE
	_wait = randf_range(0.0, 3.0)
	_t = randf() * 10.0


## Moves by `d` (length ≤ 1) for `delta` seconds, sliding along walls. Returns true if it moved at all.
func step(d: Vector2, delta: float, speed_mult: float = 1.0) -> bool:
	moving = false
	if d.length() < 0.05:
		return false
	var v := d.limit_length(1.0) * SPEED * speed_mult * delta
	var moved := false
	var nx := pos + Vector2(v.x, 0.0)
	if map.free_at(nx, RADIUS):
		pos = nx
		moved = true
	var ny := pos + Vector2(0.0, v.y)
	if map.free_at(ny, RADIUS):
		pos = ny
		moved = true
	if absf(d.x) > absf(d.y) * 1.1:
		dir = 3 if d.x > 0.0 else 2
	else:
		dir = 0 if d.y > 0.0 else 1
	if moved:
		moving = true
		_walk += delta * speed_mult
	position = pos * GroundMap.SCALE
	return moved


func _process(delta: float) -> void:
	_t += delta
	if npc and not sitting and not stays and marker == "":
		_wander(delta)
	queue_redraw()


## People on the deck stroll from one spot to the next and stand about a while.
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
		moving = false


func _draw() -> void:
	var s := GroundMap.SCALE
	var f := 0
	if moving:
		f = 1 + int(_walk * 7.0) % 2
	var tex := ChibiArt.frame(look, dir, f)
	var size := Vector2(tex.get_width(), tex.get_height()) * s
	var bob := 0.0
	if not moving and not sitting:
		bob = round(sin(_t * 2.2) * 0.4)               # breathing
	# a soft shadow at the feet
	draw_set_transform(Vector2(0, -1.0 * s), 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 6.0 * s, Color(0, 0, 0, 0.28))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if not npc:
		draw_set_transform(Vector2(0, -1.0 * s), 0.0, Vector2(1.0, 0.45))
		draw_arc(Vector2.ZERO, 8.0 * s, 0.0, TAU, 32, Color(0.35, 1.0, 0.55, 0.7 + 0.2 * sin(_t * 4.0)), 2.0)      # that is you
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if sitting:
		# sitting: the legs hidden by the chair or the counter – only the upper body shows, a little lower
		var keep := 18.0
		draw_texture_rect_region(tex, Rect2(Vector2(-size.x * 0.5, -keep * s + 2.0 * s), Vector2(size.x, keep * s)), Rect2(0, 0, tex.get_width(), keep))
	else:
		draw_texture_rect(tex, Rect2(Vector2(-size.x * 0.5, -size.y + bob * s), size), false)
	if marker != "":
		var y0 := -size.y - 10.0 + sin(_t * 3.0) * 3.0
		draw_rect(Rect2(Vector2(-9, y0 - 18), Vector2(18, 20)), Color(1.0, 0.85, 0.35))
		draw_rect(Rect2(Vector2(-9, y0 - 18), Vector2(18, 20)), Color(0.15, 0.1, 0.05), false, 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(-4, y0 - 2), marker, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.2, 0.1, 0.05))
