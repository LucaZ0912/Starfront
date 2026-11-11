extends Control
## 0.7.52.23 (Luz, package 52b): hacking a terminal – the security grid. Your probe goes node by node (WASD) from your
## jack to the core; red tracers run their loops – touch one and the trace climbs, three and you are out (the alarm
## goes). The core sits behind a lock that only a gold key opens. Electronics slows the tracers and gives more time.
## Done, you choose what to do with the terminal (open a door, power off or on, data, …).
## No class_name: preload it.

signal finished(result: String)          # an action id, "fail" (locked out), "" (pulled out)

const COLS := 9
const ROWS := 6
const ACTION_NAMES := {"lasers": "Laser cage off", "door": "Open the door", "power": "Power off / on", "turrets": "Turrets off", "cameras": "Cameras off", "data": "Download data"}

var level := 1                           # 1..3 – tracers and their pace
var skill := 0                           # Electronics
var actions: Array = ["door", "data"]
var title := "TERMINAL"
var seed_n := 0

var walls := {}                          # Vector2i -> true
var entry := Vector2i(0, ROWS - 1)
var core := Vector2i(COLS - 1, 0)
var lock := Vector2i(COLS - 1, 1)
var key := Vector2i(4, 0)
var probe := Vector2i.ZERO
var trail: Array = []
var has_key := false
var tracers: Array = []                  # {loop: [Vector2i], i, t}
var trace := 0
var trace_max := 3
var time_left := 40.0
var tick := 0.6
var immune := 0.0
var state := "run"                       # run, won, lost
var sel := 0
var t := 0.0
var _o := Vector2.ZERO
var _step := Vector2(82, 84)
var _hold := 0.0
var _flash := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	tick = (0.62 - 0.08 * (level - 1)) * (1.0 + 0.05 * skill)
	time_left = 34.0 + 2.0 * skill
	trace_max = 3 + (1 if skill >= 6 else 0)
	_build()
	probe = entry
	trail = [entry]
	Audio.play("ui_open", "terminal: jacked in", -6.0)


## Walls at random (the seed), the core reachable only through the lock, the key somewhere reachable; tracers on
## rectangular loops of free nodes away from your jack.
func _build() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_n
	for attempt in 60:
		walls.clear()
		for i in 7 + level:
			walls[Vector2i(rng.randi_range(1, COLS - 2), rng.randi_range(0, ROWS - 1))] = true
		walls[Vector2i(COLS - 2, 0)] = true                  # the core's other way in is shut: only through the lock
		walls.erase(entry)
		walls.erase(lock)
		walls.erase(core)
		key = Vector2i(rng.randi_range(2, COLS - 3), rng.randi_range(0, ROWS - 1))
		if walls.has(key):
			continue
		if _reach(entry, key, false) and _reach(key, lock, false) and _reach(entry, core, true):
			break
	tracers.clear()
	for n in level + 1:
		for tries in 30:
			var x := rng.randi_range(1, COLS - 4)
			var y := rng.randi_range(0, ROWS - 3)
			var w := rng.randi_range(2, 3)
			var h := rng.randi_range(1, 2)
			var loop := _rect_loop(x, y, w, h)
			if not loop.is_empty() and not loop.has(entry) and not loop.has(core):
				tracers.append({"loop": loop, "i": rng.randi_range(0, loop.size() - 1), "t": rng.randf() * tick})
				break


func _rect_loop(x: int, y: int, w: int, h: int) -> Array:
	var out: Array = []
	for i in w:
		out.append(Vector2i(x + i, y))
	for j in h:
		out.append(Vector2i(x + w, y + j))
	for i2 in w:
		out.append(Vector2i(x + w - i2, y + h))
	for j2 in h:
		out.append(Vector2i(x, y + h - j2))
	for c in out:
		if walls.has(c) or c.x >= COLS or c.y >= ROWS:
			return []
	return out


func _free(c: Vector2i, keyed: bool) -> bool:
	if c.x < 0 or c.y < 0 or c.x >= COLS or c.y >= ROWS or walls.has(c):
		return false
	return keyed or c != lock


func _reach(a: Vector2i, b: Vector2i, keyed: bool) -> bool:
	var seen := {a: true}
	var q := [a]
	while not q.is_empty():
		var c: Vector2i = q.pop_front()
		if c == b:
			return true
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if not seen.has(n) and (_free(n, keyed) or n == b):
				seen[n] = true
				q.append(n)
	return false


func tracer_at(c: Vector2i) -> bool:
	for tr in tracers:
		if (tr["loop"] as Array)[int(tr["i"])] == c:
			return true
	return false


func move(d: Vector2i) -> void:
	if state != "run":
		return
	var n := probe + d
	if n == lock and not has_key:
		_flash = 0.4
		Audio.play("ui_error", "hack: locked", -10.0)
		return
	if not _free(n, true):
		return
	probe = n
	if trail.size() > 1 and trail[-2] == n:
		trail.pop_back()
	else:
		trail.append(n)
	Audio.play("ui_click", "hack: step", -16.0)
	if probe == key and not has_key:
		has_key = true
		Audio.play("module_on", "hack: key", -8.0)
	_check()
	if probe == core:
		state = "won"
		Audio.play("lock_acquired", "hack: core", -4.0)


func _check() -> void:
	if immune <= 0.0 and tracer_at(probe):
		trace += 1
		immune = 1.0
		Audio.play("warn", "hack: traced", -8.0)
		if trace >= trace_max:
			state = "lost"


func _process(delta: float) -> void:
	t += delta
	immune = maxf(0.0, immune - delta)
	_flash = maxf(0.0, _flash - delta)
	if state == "run":
		time_left -= delta
		if time_left <= 0.0:
			time_left = 0.0
			state = "lost"
		for tr in tracers:
			tr["t"] = float(tr["t"]) + delta
			if float(tr["t"]) >= tick:
				tr["t"] = 0.0
				tr["i"] = (int(tr["i"]) + 1) % (tr["loop"] as Array).size()
		_check()
		# held keys repeat
		var dv := Vector2i.ZERO
		if Input.is_action_pressed("walk_up"):
			dv = Vector2i(0, -1)
		elif Input.is_action_pressed("walk_down"):
			dv = Vector2i(0, 1)
		elif Input.is_action_pressed("walk_left"):
			dv = Vector2i(-1, 0)
		elif Input.is_action_pressed("walk_right"):
			dv = Vector2i(1, 0)
		if dv != Vector2i.ZERO:
			_hold += delta
			if _hold >= 0.22:
				_hold = 0.1
				move(dv)
		else:
			_hold = 0.0
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_back", false, true):
		get_viewport().set_input_as_handled()
		finished.emit("" if state != "lost" else "fail")
		return
	if not (event is InputEventKey) or not event.is_pressed() or event.is_echo():
		if event is InputEventKey:
			get_viewport().set_input_as_handled()
		return
	get_viewport().set_input_as_handled()
	if state == "run":
		for pair in [["walk_up", Vector2i(0, -1)], ["walk_down", Vector2i(0, 1)], ["walk_left", Vector2i(-1, 0)], ["walk_right", Vector2i(1, 0)]]:
			if event.is_action_pressed(String(pair[0]), false, false):
				_hold = 0.0
				move(pair[1])
				return
	elif state == "won":
		if event.is_action_pressed("walk_up", false, false):
			sel = posmod(sel - 1, actions.size())
		elif event.is_action_pressed("walk_down", false, false):
			sel = posmod(sel + 1, actions.size())
		elif event.is_action_pressed("foot_dodge", false, false) or event.is_action_pressed("interact", false, false):
			finished.emit(String(actions[sel]))
	elif state == "lost":
		if event.is_action_pressed("foot_dodge", false, false) or event.is_action_pressed("interact", false, false):
			finished.emit("fail")


# ---------------------------------------------------------------- drawing

func _s(p: Vector2, s: String, col: Color, sz: int = 13, al := HORIZONTAL_ALIGNMENT_LEFT, w := -1.0) -> void:
	draw_string(ThemeDB.fallback_font, p, s, al, w, sz, col)


func node(c: Vector2i) -> Vector2:
	return _o + Vector2(c.x * _step.x, c.y * _step.y)


func _draw() -> void:
	var vs := get_viewport_rect().size
	var g := Color(0.3, 1.0, 0.7)
	draw_rect(Rect2(Vector2.ZERO, vs), Color(0, 0, 0, 0.62))
	var r := Rect2(vs * 0.5 - Vector2(470, 350), Vector2(940, 700))
	draw_rect(r, Color(0.02, 0.05, 0.05, 0.97))
	draw_rect(r, Color(g, 0.9), false, 2.0)
	# scan lines
	for y in range(int(r.position.y) + 2, int(r.end.y), 4):
		draw_line(Vector2(r.position.x + 2, y), Vector2(r.end.x - 2, y), Color(g, 0.025), 1.0)
	_s(r.position + Vector2(18, 30), "%s  •  SECURITY GRID %d – run your probe to the core" % [title, level], g, 17)
	_s(r.position + Vector2(18, 52), "WASD: one node at a time  •  red tracers run their loops – touch one and the trace climbs  •  the gold key opens the lock  •  Esc: pull out", Color(0.75, 0.78, 0.82), 12)
	_o = r.position + Vector2(140, 120)
	# links
	for y2 in ROWS:
		for x in COLS:
			var c := Vector2i(x, y2)
			if walls.has(c):
				continue
			for d in [Vector2i(1, 0), Vector2i(0, 1)]:
				var n: Vector2i = c + d
				if n.x < COLS and n.y < ROWS and not walls.has(n):
					draw_line(node(c), node(n), Color(g, 0.22), 2.0)
	# tracers' loops, dashed
	for tr in tracers:
		var lp: Array = tr["loop"]
		for i in lp.size():
			var a := node(lp[i])
			var b := node(lp[(i + 1) % lp.size()])
			for j in 6:
				if j % 2 == 0:
					draw_line(a.lerp(b, j / 6.0), a.lerp(b, (j + 1) / 6.0), Color(1.0, 0.3, 0.25, 0.45), 2.0)
	# nodes
	for y3 in ROWS:
		for x3 in COLS:
			var c3 := Vector2i(x3, y3)
			if walls.has(c3):
				draw_rect(Rect2(node(c3) - Vector2(15, 15), Vector2(30, 30)), Color(0.14, 0.17, 0.2))
				draw_rect(Rect2(node(c3) - Vector2(15, 15), Vector2(30, 30)), Color(0.25, 0.3, 0.34), false, 1.0)
				continue
			draw_circle(node(c3), 7.0, Color(0.05, 0.16, 0.13))
			draw_arc(node(c3), 7.0, 0, TAU, 16, Color(g, 0.55), 1.5)
	# your path
	for i2 in trail.size() - 1:
		draw_line(node(trail[i2]), node(trail[i2 + 1]), g, 4.0)
	# entry, key, lock, core
	var e := node(entry)
	draw_rect(Rect2(e - Vector2(17, 17), Vector2(34, 34)), Color(g, 0.25))
	_s(e + Vector2(-40, 36), "your jack", g, 11, HORIZONTAL_ALIGNMENT_CENTER, 80)
	if not has_key:
		var kp := node(key)
		draw_circle(kp, 11.0 + sin(t * 4.0), Color(1.0, 0.8, 0.3))
		_s(kp + Vector2(-30, -18), "key", Color(1.0, 0.8, 0.3), 11, HORIZONTAL_ALIGNMENT_CENTER, 60)
	var lk := node(lock)
	var lc := Color(1.0, 0.8, 0.3) if not has_key else Color(g, 0.6)
	if _flash > 0.0:
		lc = Color(1.0, 0.3, 0.25)
	draw_rect(Rect2(lk - Vector2(14, 14), Vector2(28, 28)), Color(lc, 0.25))
	draw_rect(Rect2(lk - Vector2(14, 14), Vector2(28, 28)), lc, false, 2.0)
	_s(lk + Vector2(-30, 30), "lock" if not has_key else "open", lc, 11, HORIZONTAL_ALIGNMENT_CENTER, 60)
	var cp := node(core)
	var hexp := PackedVector2Array()
	for i3 in 6:
		hexp.append(cp + Vector2.from_angle(i3 * TAU / 6.0 + t * 0.6) * 25.0)
	draw_colored_polygon(hexp, Color(0.2, 0.9, 1.0, 0.45 if state != "won" else 0.9))
	_s(cp + Vector2(-50, 46), "CORE", Color(0.4, 0.95, 1.0), 13, HORIZONTAL_ALIGNMENT_CENTER, 100)
	# tracers
	for tr2 in tracers:
		var lp2: Array = tr2["loop"]
		var at := node(lp2[int(tr2["i"])]).lerp(node(lp2[(int(tr2["i"]) + 1) % lp2.size()]), clampf(float(tr2["t"]) / tick, 0.0, 1.0) * 0.35)
		draw_circle(at, 13.0, Color(1.0, 0.25, 0.2, 0.35))
		draw_circle(at, 7.5, Color(1.0, 0.35, 0.3))
	# the probe
	var pp := node(probe)
	draw_circle(pp, 15.0, Color(g, 0.3 if immune <= 0.0 else 0.15 + 0.15 * sin(t * 30.0)))
	draw_circle(pp, 9.0, Color(0.85, 1.0, 0.95))
	# trace, time
	var sy := r.end.y - 56
	_s(Vector2(r.position.x + 18, sy), "TRACE", Color(1.0, 0.45, 0.4), 13)
	for i4 in trace_max:
		draw_rect(Rect2(Vector2(r.position.x + 80 + i4 * 30, sy - 13), Vector2(24, 14)), Color(1.0, 0.35, 0.3) if i4 < trace else Color(0.22, 0.1, 0.1))
	_s(Vector2(r.position.x + 80 + trace_max * 30 + 12, sy), "%d touches: locked out, the alarm goes" % trace_max, Color(0.7, 0.72, 0.76), 11)
	_s(Vector2(r.position.x + 520, sy), "TIME  0:%02d" % int(ceil(time_left)), g if time_left > 8.0 else Color(1.0, 0.5, 0.4), 14)
	_s(Vector2(r.position.x + 650, sy), "Electronics %d" % skill, Color(0.7, 0.72, 0.76), 11)
	# done: what to do with it / locked out
	if state == "won":
		var mr := Rect2(r.position + Vector2(r.size.x * 0.5 - 200, 170), Vector2(400, 60 + actions.size() * 34))
		draw_rect(mr, Color(0.02, 0.08, 0.07, 0.97))
		draw_rect(mr, g, false, 2.0)
		_s(mr.position + Vector2(16, 28), "ACCESS GRANTED – what now?", g, 15)
		for i5 in actions.size():
			var rr := Rect2(mr.position + Vector2(16, 42 + i5 * 34), Vector2(368, 28))
			if i5 == sel:
				draw_rect(rr, Color(g, 0.2))
				draw_rect(rr, g, false, 1.5)
			_s(rr.position + Vector2(10, 19), String(ACTION_NAMES.get(actions[i5], actions[i5])), Color(0.9, 1.0, 0.95), 13)
		_s(Vector2(mr.position.x, mr.end.y + 22), "W / S: choose  •  Space: do it", Color(0.75, 0.78, 0.82), 12, HORIZONTAL_ALIGNMENT_CENTER, mr.size.x)
	elif state == "lost":
		var lr := Rect2(r.position + Vector2(r.size.x * 0.5 - 200, 230), Vector2(400, 90))
		draw_rect(lr, Color(0.12, 0.02, 0.02, 0.97))
		draw_rect(lr, Color(1.0, 0.35, 0.3), false, 2.0)
		_s(lr.position + Vector2(16, 32), "TRACED – LOCKED OUT", Color(1.0, 0.45, 0.4), 17)
		_s(lr.position + Vector2(16, 58), "The alarm goes. Space: pull out.", Color(0.85, 0.8, 0.8), 12)
