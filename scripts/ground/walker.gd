class_name Walker
extends Node2D
## Package 49: someone on foot – the pilot or a person on the deck. Position in art px of the GroundMap (the view
## draws everything ×SCALE) at the feet; 0.7.49.2: a small figure in the slanted view (ChibiArt), facing one of four
## ways, stepping while it walks.

const SPEED := 58.0                # art px per second
const RADIUS := 4.0

var map: GroundMap
var look: Dictionary = {}
var slung := ""                         # 0.7.51.2: the pilot's first weapon (its damage type), slung across the back
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
var xray := false                  # 0.7.51.13: behind the clinic's scanner – drawn as a skeleton
var patrol: Array = []             # the points a guard walks between, in turn
var aim := Vector2.INF             # package 52: in a fight – the weapon in the hands, pointed there (art px)
var aim_dtype := "kinetic"         # its damage type (the colour of the weapon)
var aim_weapon := ""               # 0.7.52.3: the weapon's family (its picture, WeaponArt)
var down := false                  # package 52: fallen in a fight – lies on the ground
var crouch := false                # 0.7.52.21: sneaking – drawn low
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
	if xray:
		tex = ChibiArt.skeleton(dir, f)
	var size := Vector2(tex.get_width(), tex.get_height()) * ChibiArt.CHAR_SCALE        # 0.7.49.11: finer than the deck
	if down:
		# package 52: fallen – lying on the ground, the head to one side, darker
		draw_set_transform(Vector2(0, -1.0 * s), 0.0, Vector2(1.0, 0.45))
		draw_circle(Vector2.ZERO, 11.0 * s, Color(0, 0, 0, 0.3))
		var side := -1.0 if dir == 2 else 1.0
		draw_set_transform(Vector2(-size.y * 0.5 * side, -3.0 * s), PI * 0.5 * side, Vector2.ONE)
		draw_texture_rect(tex, Rect2(Vector2(-size.x * 0.5, -size.y), size), false, Color(0.62, 0.6, 0.62))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
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
		if aim != Vector2.INF and not down and dir == 1:
			_draw_aim(bob * s)                     # facing away: the weapon in front of the body, behind it for us
		if crouch:                                  # 0.7.52.21: sneaking – low, bent
			var cs2 := Vector2(size.x * 1.04, size.y * 0.86)
			draw_texture_rect(tex, Rect2(Vector2(-cs2.x * 0.5, -cs2.y + bob * s), cs2), false, Color(0.88, 0.85, 0.95))
		else:
			draw_texture_rect(tex, Rect2(Vector2(-size.x * 0.5, -size.y + bob * s), size), false)
	if aim != Vector2.INF and not sitting and not down:
		if dir != 1:
			_draw_aim(bob * s)
	elif guard and not sitting:
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
	if slung != "" and not guard and not sitting and aim == Vector2.INF:
		# 0.7.51.2: the weapon slung across the back – seen behind the shoulder, whole from behind
		var cs3 := ChibiArt.CHAR_SCALE
		var wy0 := -size.y + bob * s
		var wc: Color = {"optical": Color(0.75, 0.8, 0.88), "kinetic": Color(0.3, 0.32, 0.36), "explosive": Color(0.38, 0.42, 0.3)}.get(slung, Color(0.3, 0.32, 0.36))
		var a2 := Vector2(-6.0, 12.0) * cs3 + Vector2(0, wy0)
		var b2 := Vector2(6.0, 24.0) * cs3 + Vector2(0, wy0)
		if dir == 2 or dir == 3:
			a2 = Vector2(4.0 if dir == 2 else -4.0, 11.0) * cs3 + Vector2(0, wy0)
			b2 = Vector2(4.0 if dir == 2 else -4.0, 25.0) * cs3 + Vector2(0, wy0)
		if dir != 0:
			draw_line(a2, b2, Color(0.06, 0.06, 0.08), 3.0 * cs3)
			draw_line(a2, b2, wc, 1.0 * cs3)
			if slung == "optical":
				draw_circle(a2.lerp(b2, 0.2), 1.0 * cs3, Color(0.35, 0.95, 1.0))
		else:
			draw_line(a2 + Vector2(0, -2.0 * cs3), a2 + (b2 - a2) * 0.18, Color(0.06, 0.06, 0.08), 3.0 * cs3)    # its butt over the shoulder
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


## Package 52 / 0.7.52.3: where the weapon is held and where it points (screen px, relative to the walker): the hand at
## chest height on the side it points to, the angle straight at the aim (in line with the shots), the picture
## mirrored when pointing left, and the muzzle – the very tip, where the shots leave.
func aim_geom(bob_px: float = 0.0) -> Dictionary:
	var cs := ChibiArt.CHAR_SCALE
	var chest := Vector2(0, -ChibiArt.H * cs + bob_px + 22.0 * cs)
	var to := (aim - pos) * GroundMap.SCALE + Vector2(0, -14.0 * GroundMap.SCALE) - chest
	var d := to if to.length() > 0.1 else Vector2.RIGHT
	var flip := d.x < 0.0
	var hand := chest + Vector2(3.0 * cs * (-1.0 if flip else 1.0), 1.0 * cs)
	if aim_weapon == "wp_arm_laser":
		hand = chest + Vector2(6.0 * cs * (-1.0 if flip else 1.0), -5.0 * cs)        # 0.7.52.14: raised from the shoulder
	var art := WeaponArt.art(aim_weapon if aim_weapon != "" else "wp_" + aim_dtype)
	var sc := Vector2(cs, -cs if flip else cs)
	var ang := d.angle()
	var muzzle_px := hand + ((art["muzzle"] as Vector2) - (art["grip"] as Vector2)) * sc
	return {"hand": hand, "ang": ang, "scale": sc, "art": art, "muzzle": hand + (muzzle_px - hand).rotated(ang)}


## The weapon in the hands, pointed at the aim (WeaponArt's picture, turned and mirrored).
func _draw_aim(bob_px: float) -> void:
	var g := aim_geom(bob_px)
	var art: Dictionary = g["art"]
	draw_set_transform(g["hand"], g["ang"], g["scale"])
	draw_texture(art["tex"], -(art["grip"] as Vector2))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The muzzle in art px of the map – where this walker's shots leave (its chest when it holds no weapon up).
func muzzle_art() -> Vector2:
	if aim == Vector2.INF:
		return pos + Vector2(4.0 if dir != 2 else -4.0, -15.0)
	return pos + (aim_geom()["muzzle"] as Vector2) / GroundMap.SCALE
