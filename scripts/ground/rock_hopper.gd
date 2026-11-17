extends Control
## Package 54b (Luz): Rock Hopper – the arcade cabinet in the diners and beach bars (mockup_54b_rockhopper). A mining
## tug in an asteroid field: the drill laser cracks the rocks (big ones split, small ones shatter), ore spills out,
## the tractor beam pulls it into the hold; only what you bring home to the refinery in the middle is banked (points)
## – and there the tank is filled again. Lose the tug and the hold goes with it. From wave 3 pirate drones hunt you.
## Fuel runs down; three tugs. A high score game only: the cabinet keeps tonight's best.
## No class_name: preload it.

signal finished(won: bool)

const MG = preload("res://data/minigames.gd")
const AW := 534
const AH := 300
const SX0 := 92.0
const SY0 := 36.0
const SX1 := 442.0
const SY1 := 270.0
const ORE := 50                                  # points per nugget banked
const HOLD := 6
const LASER := 72.0

var place := {}
var score := 0
var wave := 0
var tugs := 3
var hold := 0
var fuel := 1.0
var tug := {}                                    # {p, v, a, inv, dead_t}
var rocks: Array = []                            # {p, v, r, hp, pts, spin, a}
var nuggets: Array = []                          # {p, v, t}
var drones: Array = []                           # {p, v, hp, cd}
var shots: Array = []                            # {p, v, t}
var bits: Array = []                             # {p, v, t, col} – sparks and debris
var state := "play"                              # play, over
var lasering := false
var beaming := false
var pad_thrust := false                           # package 80: R2 held
var pad_buttons := ["r2", "cross", "square"]

## Package 80: the controller's buttons read here each frame (pad_buttons) – the game does not wait for the context.
var _pad_prev := {}


func _pad_poll() -> void:
	for b in pad_buttons:
		var h := Pad.held(b)
		if h != bool(_pad_prev.get(b, false)):
			_pad_prev[b] = h
			pad_button(b, h)
var msg := ""
var msg_t := 0.0
var _t := 0.0
var _turn_key_t := 0.0
var _rng := RandomNumberGenerator.new()
var _cab: ImageTexture
var _ui := {}


func setup(cfg: Dictionary) -> void:
	place = cfg.get("place", {})
	_rng.seed = Time.get_ticks_usec()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_cab = ImageTexture.create_from_image(_paint_cabinet())
	Audio.play("arcade_coin", "rock hopper: a credit in", -4.0)
	_new_tug()
	tug["inv"] = 0.0
	_next_wave()


func _ready() -> void:
	_build_ui()


func centre() -> Vector2:
	return Vector2((SX0 + SX1) * 0.5, (SY0 + SY1) * 0.5 + 6.0)


func _new_tug() -> void:
	tug = {"p": centre() + Vector2(0, 26), "v": Vector2.ZERO, "a": -PI * 0.5, "inv": 2.0, "dead_t": 0.0}
	fuel = 1.0


func _next_wave() -> void:
	wave += 1
	if wave > 1:
		score += 250 * (wave - 1)
		_say("WAVE %d  +%d" % [wave, 250 * (wave - 1)])
	else:
		_say("WAVE 1: crack them, haul the ore home")
	for i in 3 + wave:
		var p := centre()
		while p.distance_to(centre()) < 80.0:
			p = Vector2(_rng.randf_range(SX0, SX1), _rng.randf_range(SY0, SY1))
		add_rock(p, _rng.randf_range(15.0, 22.0))
	for d in clampi(wave - 2, 0, 4):
		drones.append({"p": Vector2(SX0 + 4.0 if d % 2 == 0 else SX1 - 4.0, _rng.randf_range(SY0, SY1)), "v": Vector2.ZERO, "hp": 0.6, "cd": 2.0 + d})


func add_rock(p: Vector2, r: float) -> void:
	var pts := PackedVector2Array()
	for i in 11:
		pts.append(Vector2(cos(i * TAU / 11.0), sin(i * TAU / 11.0)) * (0.75 + _rng.randf() * 0.35))
	var sp := _rng.randf_range(8.0, 24.0) * (1.0 + wave * 0.08)
	rocks.append({"p": p, "v": Vector2.RIGHT.rotated(_rng.randf() * TAU) * sp, "r": r, "hp": r * 0.09, "pts": pts,
		"spin": _rng.randf_range(-0.6, 0.6), "a": 0.0, "vein": _rng.randf() < 0.6})


func _wrap(p: Vector2) -> Vector2:
	return Vector2(SX0 + fposmod(p.x - SX0, SX1 - SX0), SY0 + fposmod(p.y - SY0, SY1 - SY0))


# ---------------------------------------------------------------- the game

func step(dt: float) -> void:
	_t += dt
	msg_t = maxf(0.0, msg_t - dt)
	for b in bits:
		b["p"] = (b["p"] as Vector2) + (b["v"] as Vector2) * dt
		b["t"] = float(b["t"]) - dt
	bits = bits.filter(func(b): return float(b["t"]) > 0.0)
	if state != "play":
		return
	_tug_step(dt)
	for r in rocks:
		r["p"] = _wrap((r["p"] as Vector2) + (r["v"] as Vector2) * dt)
		r["a"] = float(r["a"]) + float(r["spin"]) * dt
		var off: Vector2 = (r["p"] as Vector2) - centre()          # the refinery's shield turns the rocks away
		if off.length() < float(r["r"]) + 17.0 and (r["v"] as Vector2).dot(off) < 0.0:
			r["v"] = (r["v"] as Vector2).bounce(off.normalized())
	for n in nuggets:
		n["p"] = _wrap((n["p"] as Vector2) + (n["v"] as Vector2) * dt)
		n["v"] = (n["v"] as Vector2) * pow(0.6, dt)
		n["t"] = float(n["t"]) - dt
	nuggets = nuggets.filter(func(n): return float(n["t"]) > 0.0)
	_drones_step(dt)
	for s in shots:
		s["p"] = (s["p"] as Vector2) + (s["v"] as Vector2) * dt
		s["t"] = float(s["t"]) - dt
	shots = shots.filter(func(s): return float(s["t"]) > 0.0 and Rect2(SX0, SY0, SX1 - SX0, SY1 - SY0).has_point(s["p"]))
	if rocks.is_empty() and nuggets.is_empty() and hold == 0 and drones.is_empty():
		_next_wave()


func _tug_step(dt: float) -> void:
	if float(tug["dead_t"]) > 0.0:
		tug["dead_t"] = float(tug["dead_t"]) - dt
		if float(tug["dead_t"]) <= 0.0:
			if tugs <= 0:
				_game_over()
			else:
				_new_tug()
		return
	tug["inv"] = maxf(0.0, float(tug["inv"]) - dt)
	var turn := Input.get_axis("walk_left", "walk_right")
	if absf(turn) > 0.1:
		_turn_key_t = 0.6
		tug["a"] = float(tug["a"]) + turn * 3.4 * dt
	else:
		_turn_key_t = maxf(0.0, _turn_key_t - dt)
		var m := _art_mouse()
		if _turn_key_t <= 0.0 and not Pad.using_pad and Rect2(SX0, SY0, SX1 - SX0, SY1 - SY0).has_point(m) and m.distance_to(tug["p"]) > 6.0:
			tug["a"] = lerp_angle(float(tug["a"]), (m - (tug["p"] as Vector2)).angle(), 1.0 - exp(-dt * 7.0))
	var d := Vector2.RIGHT.rotated(float(tug["a"]))
	var thrust := (Input.is_action_pressed("walk_up") or pad_thrust) and fuel > 0.0
	var v: Vector2 = tug["v"]
	if thrust:
		v += d * 130.0 * dt
		fuel -= 0.035 * dt
		if _rng.randf() < 0.7:
			bits.append({"p": (tug["p"] as Vector2) - d * 8.0, "v": -d * 40.0 + Vector2(_rng.randf_range(-15, 15), _rng.randf_range(-15, 15)), "t": 0.25, "col": Color(1.0, 0.55, 0.2)})
	v = v.limit_length(140.0) * pow(0.85, dt)
	tug["v"] = v
	tug["p"] = _wrap((tug["p"] as Vector2) + v * dt)
	fuel -= 0.008 * dt
	# the drill laser: the first rock (or drone) along the beam
	if lasering and fuel > 0.0:
		fuel -= 0.02 * dt
		if fposmod(_t, 0.16) < dt:
			Audio.play("arcade_laser", "rock hopper: drill", -14.0, 0.05)
		var hit := _laser_hit()
		if not hit.is_empty():
			var tgt: Dictionary = hit["t"]
			tgt["hp"] = float(tgt["hp"]) - dt
			if _rng.randf() < 0.6:
				bits.append({"p": hit["at"], "v": Vector2(_rng.randf_range(-40, 40), _rng.randf_range(-40, 40)), "t": 0.2, "col": Color(1.0, 0.9, 0.4)})
			if float(tgt["hp"]) <= 0.0:
				if tgt.has("r"):
					_crack(tgt)
				else:
					_drone_down(tgt)
	# the tractor beam: the ore in front of you comes in
	if beaming and fuel > 0.0:
		fuel -= 0.015 * dt
		for n in nuggets:
			var to: Vector2 = (tug["p"] as Vector2) - (n["p"] as Vector2)
			if to.length() < 70.0 and absf(angle_difference(d.angle(), (-to).angle())) < 0.9:
				n["v"] = (n["v"] as Vector2).lerp(to.normalized() * 90.0, 1.0 - exp(-dt * 6.0))
	for n2 in nuggets.duplicate():
		if (n2["p"] as Vector2).distance_to(tug["p"]) < 7.0:
			if hold < HOLD:
				hold += 1
				nuggets.erase(n2)
				Audio.play("arcade_pickup", "rock hopper: ore in", -8.0, 0.05)
			elif msg_t <= 0.0:
				_say("HOLD FULL: bank it at the refinery")
	# home: docked slow at the refinery, the hold banked, the tank filled
	if (tug["p"] as Vector2).distance_to(centre()) < 21.0 and v.length() < 45.0:
		if hold > 0:
			var gain := hold * ORE * (2 if hold == HOLD else 1)
			score += gain
			_say("BANKED %d ORE  +%d%s" % [hold, gain, "  (FULL HOLD ×2)" if hold == HOLD else ""])
			hold = 0
			Audio.play("arcade_bank", "rock hopper: banked", -4.0)
		fuel = minf(1.0, fuel + dt * 0.8)
	fuel = maxf(0.0, fuel)
	# crashes
	if float(tug["inv"]) <= 0.0:
		for r in rocks:
			if (r["p"] as Vector2).distance_to(tug["p"]) < float(r["r"]) * 0.85 + 4.0:
				_lose_tug("CRASHED")
				return
		for s in shots:
			if (s["p"] as Vector2).distance_to(tug["p"]) < 5.0:
				_lose_tug("SHOT DOWN")
				return
		if fuel <= 0.0 and v.length() < 2.0 and (tug["p"] as Vector2).distance_to(centre()) > 21.0:
			_lose_tug("OUT OF FUEL")


func _laser_hit() -> Dictionary:
	var p: Vector2 = tug["p"]
	var d := Vector2.RIGHT.rotated(float(tug["a"]))
	var best := LASER
	var out := {}
	for t in rocks + drones:
		var c: Vector2 = t["p"]
		var rr := float(t.get("r", 5.0)) * 0.85
		var f := c - p
		var along := f.dot(d)
		if along <= 0.0 or along > best + rr:
			continue
		var side := absf(f.cross(d))
		if side < rr:
			var at := along - sqrt(maxf(0.0, rr * rr - side * side))
			if at < best:
				best = at
				out = {"t": t, "at": p + d * at}
	return out


func laser_end() -> Vector2:
	var hit := _laser_hit()
	return hit["at"] if not hit.is_empty() else (tug["p"] as Vector2) + Vector2.RIGHT.rotated(float(tug["a"])) * LASER


func _crack(r: Dictionary) -> void:
	rocks.erase(r)
	var p: Vector2 = r["p"]
	var rad := float(r["r"])
	score += 10
	Audio.play("arcade_boom", "rock hopper: rock cracks", -10.0, 0.15)
	for i in 10:
		bits.append({"p": p, "v": Vector2.RIGHT.rotated(_rng.randf() * TAU) * _rng.randf_range(20, 60), "t": 0.5, "col": Color(0.7, 0.62, 0.8)})
	if rad > 11.0:
		for k in 2:
			add_rock(p + Vector2.RIGHT.rotated(_rng.randf() * TAU) * rad * 0.3, rad * 0.58)
	var n := (1 + _rng.randi() % 2) if bool(r.get("vein", true)) else 0
	if rad <= 11.0:
		n += 1
	for j in n:
		nuggets.append({"p": p, "v": Vector2.RIGHT.rotated(_rng.randf() * TAU) * _rng.randf_range(10, 30), "t": 20.0})


func _drones_step(dt: float) -> void:
	for dr in drones:
		var to: Vector2 = (tug["p"] as Vector2) - (dr["p"] as Vector2)
		var want := to.normalized().rotated(0.7) * 45.0 if to.length() < 80.0 else to.normalized() * 55.0
		dr["v"] = (dr["v"] as Vector2).lerp(want, 1.0 - exp(-dt * 1.5))
		dr["p"] = _wrap((dr["p"] as Vector2) + (dr["v"] as Vector2) * dt)
		dr["cd"] = float(dr["cd"]) - dt
		if float(dr["cd"]) <= 0.0 and float(tug["dead_t"]) <= 0.0:
			dr["cd"] = maxf(1.2, 2.8 - wave * 0.15)
			shots.append({"p": dr["p"], "v": to.normalized() * 120.0, "t": 3.0})


func _drone_down(dr: Dictionary) -> void:
	drones.erase(dr)
	score += 100
	_say("DRONE DOWN  +100")
	Audio.play("arcade_boom", "rock hopper: drone down", -6.0, 0.2)
	for i in 12:
		bits.append({"p": dr["p"], "v": Vector2.RIGHT.rotated(_rng.randf() * TAU) * _rng.randf_range(20, 70), "t": 0.5, "col": Color(1.0, 0.35, 0.4)})


func _lose_tug(why: String) -> void:
	tugs -= 1
	if hold > 0:
		for i in hold:                              # the hold spills out where the tug went
			nuggets.append({"p": tug["p"], "v": Vector2.RIGHT.rotated(_rng.randf() * TAU) * _rng.randf_range(15, 40), "t": 12.0})
	hold = 0
	_say("%s – %s" % [why, "%d TUGS LEFT" % tugs if tugs > 0 else "GAME OVER"])
	Audio.play("arcade_boom", "rock hopper: tug lost", -1.0, 0.0)
	for i in 18:
		bits.append({"p": tug["p"], "v": Vector2.RIGHT.rotated(_rng.randf() * TAU) * _rng.randf_range(20, 80), "t": 0.7, "col": Color(1.0, 0.75, 0.2)})
	tug["dead_t"] = 1.6
	tug["v"] = Vector2.ZERO


func _game_over() -> void:
	state = "over"
	Commands.execute({"type": "minigame_end", "won": false, "score": score})
	_show_result()


func finish(_w: bool) -> void:
	if state != "over":
		_game_over()


func _say(t: String) -> void:
	msg = t
	msg_t = 2.5


# ---------------------------------------------------------------- input, loop

func _process(dt: float) -> void:
	_pad_poll()
	step(dt)
	_update_ui()
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			lasering = mb.pressed
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			beaming = mb.pressed
			accept_event()


## Package 80 (Luz): with the controller – the left stick turns the tug (the InputMap's walk_left / walk_right), R2
## thrusts, ✕ fires the drill laser, □ the tractor beam; ✕ after the game: back to the lobby.
func pad_button(b: String, pressed: bool) -> bool:
	match b:
		"r2":
			pad_thrust = pressed
			return true
		"cross":
			if state == "over":
				if pressed:
					finished.emit(false)
			else:
				lasering = pressed
			return true
		"square":
			beaming = pressed
			return true
	return false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_back", false, true):
		get_viewport().set_input_as_handled()
		if state == "over":
			finished.emit(false)
		else:
			_game_over()
	elif event is InputEventKey and (event as InputEventKey).keycode == KEY_SPACE:
		lasering = event.is_pressed()


func _scale() -> float:
	var vs := get_viewport_rect().size
	return floorf((minf(vs.x / AW, vs.y / AH) + 0.02) * 2.0) / 2.0


func _origin() -> Vector2:
	return (get_viewport_rect().size - Vector2(AW, AH) * _scale()) * 0.5


func _art_mouse() -> Vector2:
	return (get_local_mouse_position() - _origin()) / _scale()


# ---------------------------------------------------------------- drawing

func _draw() -> void:
	var s := _scale()
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color(0.09, 0.07, 0.1))
	draw_set_transform(_origin(), 0.0, Vector2(s, s))
	draw_texture(_cab, Vector2.ZERO)
	# the refinery
	var c := centre()
	draw_arc(c, 13.5, 0, TAU, 32, Color(0.2, 0.55, 0.6), 4.0)
	draw_circle(c, 5.0, Color(1.0, 0.75, 0.25).lerp(Color(1.0, 1.0, 0.7), 0.5 + 0.5 * sin(_t * 3.0)))
	for a in 8:
		var an := a * TAU / 8.0 + _t * 0.4
		draw_rect(Rect2(c + Vector2(cos(an), sin(an)) * 15.0, Vector2(1, 1)), Color(0.4, 1.0, 0.9))
	# rocks
	for r in rocks:
		var pts := PackedVector2Array()
		for q in r["pts"]:
			pts.append((r["p"] as Vector2) + (q as Vector2).rotated(float(r["a"])) * float(r["r"]))
		draw_colored_polygon(pts, Color(0.42, 0.37, 0.5))
		var out := pts.duplicate()
		out.append(pts[0])
		draw_polyline(out, Color(0.85, 0.75, 1.0), 1.0)
		draw_circle((r["p"] as Vector2) + Vector2(-0.25, -0.2).rotated(float(r["a"])) * float(r["r"]), float(r["r"]) * 0.16, Color(0.28, 0.24, 0.34))
		draw_circle((r["p"] as Vector2) + Vector2(0.3, 0.15).rotated(float(r["a"])) * float(r["r"]), float(r["r"]) * 0.12, Color(0.28, 0.24, 0.34))
		if bool(r.get("vein", false)):
			draw_line((r["p"] as Vector2) + Vector2(-0.3, 0.1).rotated(float(r["a"])) * float(r["r"]), (r["p"] as Vector2) + Vector2(0.05, -0.15).rotated(float(r["a"])) * float(r["r"]), Color(1.0, 0.8, 0.25), 1.0)
	# ore
	for n in nuggets:
		if float(n["t"]) > 3.0 or fposmod(_t * 8.0, 2.0) < 1.0:
			draw_circle(n["p"], 2.5, Color(1.0, 0.8, 0.25))
			draw_rect(Rect2((n["p"] as Vector2) + Vector2(-1, -1), Vector2(1, 1)), Color(1, 1, 0.8))
	# drones, their shots
	for dr in drones:
		var dp: Vector2 = dr["p"]
		draw_circle(dp, 5.0, Color(1.0, 0.25, 0.35))
		draw_circle(dp, 2.0, Color(0.05, 0.02, 0.05))
		draw_line(dp + Vector2(-7, 0), dp + Vector2(7, 0), Color(1.0, 0.5, 0.55), 1.0)
	for sh in shots:
		draw_rect(Rect2((sh["p"] as Vector2) - Vector2(1, 1), Vector2(2, 2)), Color(1.0, 0.4, 0.5))
	# the tug, its beams
	if state == "play" and float(tug["dead_t"]) <= 0.0 and (float(tug["inv"]) <= 0.0 or fposmod(_t * 10.0, 2.0) < 1.4):
		var p: Vector2 = tug["p"]
		var d := Vector2.RIGHT.rotated(float(tug["a"]))
		var nrm := d.orthogonal()
		if beaming and fuel > 0.0:
			for k in 3:
				var a0 := -0.9 + k * 0.9
				draw_line(p + d * 8.0, p + d.rotated(a0) * 70.0, Color(0.4, 1.0, 0.9, 0.18), 6.0)
		if lasering and fuel > 0.0:
			var e := laser_end()
			draw_line(p + d * 9.0, e, Color(1.0, 0.3, 0.3), 2.0)
			draw_line(p + d * 9.0, e, Color(1.0, 0.8, 0.8), 1.0)
		var body := PackedVector2Array([p + d * 8, p + d * 2 + nrm * 6, p - d * 7 + nrm * 6, p - d * 7 - nrm * 6, p + d * 2 - nrm * 6])
		draw_colored_polygon(body, Color(1.0, 0.75, 0.2))
		var bo := body.duplicate()
		bo.append(body[0])
		draw_polyline(bo, Color(1.0, 0.95, 0.6), 1.0)
		draw_circle(p - d, 2.0, Color(0.3, 0.9, 1.0))
	for b in bits:
		draw_rect(Rect2(b["p"], Vector2(1, 1)), Color(b["col"], clampf(float(b["t"]) * 3.0, 0.0, 1.0)))
	# scanlines; the bezel drawn again over whatever drifts off the screen's edge
	for y in range(int(SY0), int(SY1), 2):
		draw_rect(Rect2(SX0, y, SX1 - SX0, 1), Color(0, 0, 0, 0.16))
	for rr in [Rect2(0, 0, AW, SY0), Rect2(0, SY1, AW, AH - SY1), Rect2(0, SY0, SX0, SY1 - SY0), Rect2(SX1, SY0, AW - SX1, SY1 - SY0)]:
		draw_texture_rect_region(_cab, rr, rr)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ---------------------------------------------------------------- the panels

func _build_ui() -> void:
	var o := _origin()
	var s := _scale()
	var at := func(ax: float, ay: float) -> Vector2: return o + Vector2(ax, ay) * s
	_ui["marquee"] = _lbl("ROCK  HOPPER", at.call(196, 2), 40, Color(1.0, 0.45, 0.75))
	_ui["score"] = _lbl("", at.call(SX0 + 8, SY0 + 4), 20, Color(0.4, 1.0, 0.9))
	_ui["hi"] = _lbl("", at.call(SX0 + 118, SY0 + 4), 20, Color(1.0, 0.8, 0.3))
	_ui["wave"] = _lbl("", at.call(SX1 - 72, SY0 + 4), 20, Color(0.4, 1.0, 0.9))
	_ui["hold"] = _lbl("", at.call(SX0 + 8, SY1 - 20), 20, Color(1.0, 0.8, 0.3))
	_ui["fuel"] = _lbl("", at.call(SX0 + 108, SY1 - 20), 20, Color(0.4, 1.0, 0.6))
	_ui["tugs"] = _lbl("", at.call(SX1 - 72, SY1 - 20), 20, Color(1.0, 0.75, 0.2))
	_ui["msg"] = _lbl("", at.call(SX0 + 90, SY0 + 36), 18, Color(1.0, 0.95, 0.6))
	var vs := get_viewport_rect().size
	var p := UI.neon_panel(Color(0.35, 0.95, 1.0), Color(0.03, 0.05, 0.06, 0.88), 2)
	p.position = Vector2(vs.x - 230, 300)
	p.custom_minimum_size = Vector2(210, 0)
	add_child(p)
	var v := UI.vbox(6)
	p.add_child(v)
	v.add_child(UI.label("TONIGHT'S BEST", 14, UI.TEXT_DIM))
	for row in MG.arcade_board(String(place.get("id", "")), GameState.minigame_best):
		var mine: bool = bool(row[2])
		v.add_child(UI.label("%-6s %6d" % [row[0], int(row[1])], 16, Color(0.5, 1.0, 0.6) if mine else Color(0.9, 0.93, 1.0)))
	v.add_child(UI.label("1 credit = 1 cr", 12, UI.TEXT_DIM))
	var hint := UI.label("W / ↑: thrust  •  mouse or A D: turn  •  left button (or Space): drill laser  •  right button: tractor beam  •  Esc: leave", 15)
	hint.position = Vector2(vs.x * 0.5 - 450, vs.y - 40)
	add_child(hint)


func _lbl(t: String, pos: Vector2, sz: int, col: Color) -> Label:
	var l := UI.label(t, sz, col)
	l.position = pos
	add_child(l)
	return l


func _update_ui() -> void:
	if not _ui.has("score"):
		return
	_ui["score"].text = "ORE BANKED  %d" % score
	_ui["hi"].text = "HI  %d" % maxi(int(GameState.minigame_best.get("rockhopper", 0)), score)
	_ui["wave"].text = "WAVE %d" % wave
	_ui["hold"].text = "HOLD  " + "◆".repeat(hold) + "◇".repeat(HOLD - hold)
	var f := int(round(fuel * 10.0))
	_ui["fuel"].text = "FUEL  " + "▮".repeat(f) + "▯".repeat(10 - f)
	_ui["tugs"].text = "TUGS  " + "▲".repeat(maxi(tugs - (1 if float(tug["dead_t"]) <= 0.0 else 0), 0))
	_ui["msg"].text = msg if msg_t > 0.0 else ""


func _show_result() -> void:
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(cc)
	var p := UI.neon_panel(Color(1.0, 0.45, 0.75), Color(0.03, 0.05, 0.06, 0.95), 2)
	p.custom_minimum_size = Vector2(460, 0)
	cc.add_child(p)
	var v := UI.vbox(10)
	p.add_child(v)
	v.add_child(UI.label("GAME OVER", 28, Color(1.0, 0.45, 0.75)))
	v.add_child(UI.label("Ore banked: %d  –  wave %d" % [score, wave], 18, Color(0.4, 1.0, 0.9)))
	var best := int(GameState.minigame_best.get("rockhopper", 0))
	v.add_child(UI.label("A new best!" if score >= best and score > 0 else "Your best: %d" % best, 15, Color(1.0, 0.8, 0.3)))
	v.add_child(UI.button("Back to the cabinet [Esc]", func(): finished.emit(false)))


# ---------------------------------------------------------------- the cabinet

func _paint_cabinet() -> Image:
	var img := Image.create(AW, AH, false, Image.FORMAT_RGBA8)
	for y in AH:
		for x in AW:
			img.set_pixel(x, y, Color(0.09, 0.07, 0.1).lerp(Color(0.13, 0.1, 0.14), _h(x / 5, y / 7, 1)))
	for y2 in range(int(SY0) - 10, int(SY1) + 10):
		for x2 in range(int(SX0) - 10, int(SX1) + 10):
			img.set_pixel(x2, y2, Color(0.05, 0.05, 0.07))
	for e in 3:
		for x3 in range(int(SX0) - 10 + e, int(SX1) + 10 - e):
			var cc := Color(0.95, 0.3, 0.7).lerp(Color(0.05, 0.05, 0.07), e * 0.3)
			img.set_pixel(x3, int(SY0) - 10 + e, cc)
			img.set_pixel(x3, int(SY1) + 9 - e, cc)
	for y4 in range(int(SY0), int(SY1)):
		for x4 in range(int(SX0), int(SX1)):
			var c := Color(0.02, 0.02, 0.05)
			if _h(x4, y4, 9) < 0.006:
				c = Color(0.8, 0.85, 1.0)
			var cu := (Vector2(x4 - (SX0 + SX1) * 0.5, y4 - (SY0 + SY1) * 0.5) / Vector2(SX1 - SX0, SY1 - SY0) * 2.0).length()
			img.set_pixel(x4, y4, c.darkened(clampf((cu - 1.0) * 1.5, 0.0, 0.8)))
	return img


func _h(x: int, y: int, s: int = 0) -> float:
	var v := sin(float(x) * 12.9898 + float(y) * 78.233 + float(s) * 3.7) * 43758.5453
	return v - floor(v)
