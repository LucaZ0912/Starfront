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
var leave_to := Vector2.INF        # walks there and is gone (hired crew off to the lift)
var drink_t := 0.0                 # 0.7.49.13: seconds left of a drink (the glass goes up to the mouth and down)
var drink_col := Color(0.95, 0.7, 0.25)
var guard := false                 # 0.7.50.9: a city guard – posted (stays) or on patrol
var patrol: Array = []             # the points a guard walks between, in turn
var _pp := 0
const DRINK_TIME := 3.2
var _t := 0.0
var _walk := 0.0
var _goal := Vector2.INF
var _wait := 0.0
var _path := PackedVector2Array()
var _pi := 0
var _stuck := 0.0
const SIT_LIFT := 0.5              # art px: a sitter is drawn this much higher – on the seat, not in the floor


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
	drink_t = maxf(0.0, drink_t - delta)
	if leave_to != Vector2.INF:
		if _path.is_empty():
			_path = map.path(pos, leave_to)
			_pi = 0
		if pos.distance_to(leave_to) < 6.0 or not _follow(delta, 0.9):
			queue_free()
	elif npc and not patrol.is_empty() and not stays:
		_patrol(delta)
	elif npc and not sitting and not stays and marker == "":
		_wander(delta)
	queue_redraw()


## People on the deck stroll from one spot to the next along a path round walls and furniture, and stand about.
func _wander(delta: float) -> void:
	if _wait > 0.0:
		_wait -= delta
		moving = false
		return
	if _goal == Vector2.INF:
		if map.wander.is_empty():
			return
		_goal = map.wander[randi() % map.wander.size()]
		_path = map.path(pos, _goal)
		_pi = 0
		if _path.is_empty():
			_goal = Vector2.INF
			_wait = 1.0
			return
	if not _follow(delta, 0.6):
		_goal = Vector2.INF
		_path = PackedVector2Array()
		_wait = randf_range(1.5, 6.0)
		moving = false


## 0.7.50.9: a guard walks the round – from one point to the next, a look about at each.
func _patrol(delta: float) -> void:
	if _wait > 0.0:
		_wait -= delta
		moving = false
		return
	if _path.is_empty() or _pi >= _path.size():
		_pp = (_pp + 1) % patrol.size()
		_path = map.path(pos, patrol[_pp])
		_pi = 0
		if _path.is_empty():
			_wait = 1.0
			return
	if not _follow(delta, 0.5):
		_path = PackedVector2Array()
		_wait = randf_range(1.5, 3.5)
		dir = randi() % 4
		moving = false


## One step along the path; false when it is walked (or hopelessly stuck).
func _follow(delta: float, mult: float) -> bool:
	if _pi >= _path.size():
		return false
	var to := _path[_pi] - pos
	if to.length() < 2.5:
		_pi += 1
		return _pi < _path.size()
	if step(to.normalized(), delta, mult):
		_stuck = 0.0
	else:
		_stuck += delta
		if _stuck > 0.8:
			_stuck = 0.0
			_pi += 1                     # skip a corner it cannot round
	return true


func _draw() -> void:
	var s := GroundMap.SCALE
	var f := 0
	if moving:
		f = 1 + int(_walk * 7.0) % 2
	var tex := ChibiArt.frame(look, dir, f)
	var size := Vector2(tex.get_width(), tex.get_height()) * ChibiArt.CHAR_SCALE        # 0.7.49.11: finer than the deck
	var bob := 0.0
	if not moving and not sitting:
		bob = round(sin(_t * 2.2) * 0.4) * ChibiArt.CHAR_SCALE / s     # breathing
	# a soft shadow at the feet
	if not sitting:
		draw_set_transform(Vector2(0, -1.0 * s), 0.0, Vector2(1.0, 0.45))
		draw_circle(Vector2.ZERO, 6.0 * s, Color(0, 0, 0, 0.28))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if not npc:
		draw_set_transform(Vector2(0, -1.0 * s), 0.0, Vector2(1.0, 0.45))
		draw_arc(Vector2.ZERO, 8.0 * s, 0.0, TAU, 32, Color(0.35, 1.0, 0.55, 0.7 + 0.2 * sin(_t * 4.0)), 2.0)      # that is you
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if sitting:
		# sitting on the seat: legs bent, the figure raised onto it
		var st := ChibiArt.frame(look, dir, 3)
		draw_texture_rect(st, Rect2(Vector2(-size.x * 0.5, -size.y - SIT_LIFT * s), size), false)
	else:
		draw_texture_rect(tex, Rect2(Vector2(-size.x * 0.5, -size.y + bob * s), size), false)
	if guard and not sitting:
		# 0.7.50.9: a guard's rifle slung across the chest (pointing down – it stays there), a lamp on the shoulder
		var cs2 := ChibiArt.CHAR_SCALE
		var gy0 := -size.y + bob * s
		var side := -1.0 if dir == 2 else 1.0
		if dir != 1:
			var a := Vector2(-6.0 * side, 15.0) * cs2 + Vector2(0, gy0)
			var b := Vector2(6.0 * side, 27.0) * cs2 + Vector2(0, gy0)
			draw_line(a, b, Color(0.06, 0.06, 0.08), 3.0 * cs2)
			draw_line(a, b, Color(0.3, 0.32, 0.36), 1.0 * cs2)
		var lamp: Color = PilotArt_CLOTH(int(look.get("color2", 3)))
		if fposmod(_t * 1.3 + pos.x * 0.01, 2.0) < 1.4:
			draw_rect(Rect2(Vector2(-7.0 * cs2 * side - 2.0, gy0 + 13.0 * cs2), Vector2(4, 4)), lamp.lightened(0.3))
	if drink_t > 0.0:
		# the glass: from the hand up to the mouth, a sip, back down
		var p := 1.0 - drink_t / DRINK_TIME
		var up := clampf(sin(p * PI) * 1.4, 0.0, 1.0)
		var cs := ChibiArt.CHAR_SCALE
		var lift := SIT_LIFT * s if sitting else -bob * s
		var hand_y := -(ChibiArt.H - 31) * cs - lift if sitting else -(ChibiArt.H - 24) * cs
		var mouth_y := -(ChibiArt.H - 14) * cs - lift if sitting else -(ChibiArt.H - 6) * cs
		var gx := (-6.0 if dir == 2 else 5.0) * cs
		if dir == 3:
			gx = 4.0 * cs
		var gy := lerpf(hand_y, mouth_y, up)
		draw_rect(Rect2(Vector2(gx - 3, gy - 8), Vector2(6, 9)), Color(0.06, 0.05, 0.08))
		draw_rect(Rect2(Vector2(gx - 2, gy - 7), Vector2(4, 7)), drink_col)
		draw_rect(Rect2(Vector2(gx - 2, gy - 7), Vector2(4, 2)), Color(0.95, 0.95, 0.9))
	if marker != "":
		var y0 := -size.y - 10.0 + sin(_t * 3.0) * 3.0
		draw_rect(Rect2(Vector2(-9, y0 - 18), Vector2(18, 20)), Color(1.0, 0.85, 0.35))
		draw_rect(Rect2(Vector2(-9, y0 - 18), Vector2(18, 20)), Color(0.15, 0.1, 0.05), false, 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(-4, y0 - 2), marker, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.2, 0.1, 0.05))


static func PilotArt_CLOTH(i: int) -> Color:
	var c: Array = ChibiArt.PilotArt.CLOTH
	return c[posmod(i, c.size())]
