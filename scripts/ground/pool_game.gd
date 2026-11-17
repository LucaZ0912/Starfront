extends Control
## Package 54b (Luz): billiards at the bar's pool table (mockup_54b_billard) – the camera down on the table: wooden rails,
## leather pockets, the cloth lit by the lamp; real balls (cushions, ball on ball, follow, draw and side on the cue
## ball); 8-ball and 9-ball against a guest of the bar (or one of your crew), or practice alone. Aim with the mouse,
## hold the left button for power, let go to shoot; the right button (or WASD) sets the spin. Every shot goes through
## the command bus (pool_shot) – so later a co-op player's shot can come the same way.
## No class_name: preload it.

signal finished(won: bool)

const MG = preload("res://data/minigames.gd")
const AW := 534
const AH := 300
const R := 5.0                                   # a ball's radius (art px; the field 354 × 180 = 2.54 × 1.27 m)
const FX0 := 90.0
const FY0 := 68.0
const FX1 := 444.0
const FY1 := 248.0
const DECEL := 150.0                             # rolling friction, px/s²
const MAX_V := 880.0
const SUB := 8

var mode := "8ball"
var opponent := {}
var stake := 0
var balls: Array = []                            # {n, p: Vector2, v: Vector2, in: bool}
var turn := 0                                    # 0 you, 1 the opponent
var groups := ["", ""]                           # "solid" / "stripe"
var state := "aim"                               # aim, place, roll, ai, over
var aim_a := 0.0
var power := 0.0
var charging := false
var spin := Vector2.ZERO                         # x side, y follow (+) / draw (−), each −1…1
var spin_drag := false
var msg := ""
var msg_t := 0.0
var break_shot := true
var won := false
var _first_hit := -1
var _potted: Array = []
var _cushion_after := false
var _shot_dir := Vector2.RIGHT
var _cue_spin := Vector2.ZERO
var _cue_touched := false
var _ai_t := 0.0
var _ai_plan := {}
var _rng := RandomNumberGenerator.new()
var _table: ImageTexture
var _ball_tex := {}
var _t := 0.0
var _ui := {}


func setup(cfg: Dictionary) -> void:
	mode = String(cfg.get("mode", "8ball"))
	opponent = cfg.get("opponent", {})
	stake = int(cfg.get("stake", 0))
	_rng.seed = Time.get_ticks_usec()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_table = ImageTexture.create_from_image(_paint_table())
	for n in 16:
		_ball_tex[n] = ImageTexture.create_from_image(_paint_ball(n))
	rack()


func _ready() -> void:
	_build_ui()


# ---------------------------------------------------------------- the rack, the rules

func rack() -> void:
	balls.clear()
	var foot := Vector2(FX0 + (FX1 - FX0) * 0.75, (FY0 + FY1) * 0.5)
	if mode == "9ball":
		var rows9 := [1, 2, 3, 2, 1]
		var k := 0
		var spots: Array = []
		for r in rows9.size():
			for i in rows9[r]:
				spots.append(foot + Vector2(r * R * 1.75, (i - (rows9[r] - 1) * 0.5) * R * 2.02))
		var mids := [2, 3, 4, 5, 6, 7, 8]                 # (0.7.80: the 1 was in here too – two 1s, no 4)
		for mi in range(mids.size() - 1, 0, -1):          # shuffled with the table's own dice
			var mj := _rng.randi() % (mi + 1)
			var mt = mids[mi]
			mids[mi] = mids[mj]
			mids[mj] = mt
		var nums: Array = [1, mids[0], mids[1], mids[2], 9, mids[3], mids[4], mids[5], mids[6]]
		for s in spots:
			balls.append({"n": int(nums[k]), "p": s, "v": Vector2.ZERO, "in": false})
			k += 1
	else:
		var rest: Array = [1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 12, 13, 14, 15]
		rest.shuffle()
		var k2 := 0
		for r2 in 5:
			for i2 in r2 + 1:
				var n := 0
				if r2 == 2 and i2 == 1:
					n = 8
				elif r2 == 4 and i2 == 0:
					n = 1
				elif r2 == 4 and i2 == 4:
					n = 9
				else:
					while int(rest[k2]) in [1, 9]:
						k2 += 1
					n = int(rest[k2])
					k2 += 1
				balls.append({"n": n, "p": foot + Vector2(r2 * R * 1.75, (i2 - r2 * 0.5) * R * 2.02), "v": Vector2.ZERO, "in": false})
	balls.append({"n": 0, "p": Vector2(FX0 + 88.0, (FY0 + FY1) * 0.5), "v": Vector2.ZERO, "in": false})
	groups = ["", ""]
	turn = 0 if mode == "practice" or _rng.randf() < 0.5 else 1
	break_shot = true
	state = "aim"
	aim_a = 0.0
	_say("You break." if turn == 0 else "%s breaks." % _opp_name())
	_next_turn_setup()


func _cue() -> Dictionary:
	for b in balls:
		if int(b["n"]) == 0:
			return b
	return {}


func _on_table() -> Array:
	return balls.filter(func(b): return not bool(b["in"]))


func _opp_name() -> String:
	return String(opponent.get("name", "Your opponent")).split(" ")[0].replace("\"", "")


## The balls the player at the table may hit first.
func legal_targets(who: int) -> Array:
	var on := _on_table().filter(func(b): return int(b["n"]) != 0)
	if mode == "9ball":
		var lo := 99
		for b in on:
			lo = mini(lo, int(b["n"]))
		return on.filter(func(b): return int(b["n"]) == lo)
	if mode == "practice":
		return on
	var g := String(groups[who])
	if g == "":
		return on.filter(func(b): return int(b["n"]) != 8)
	var mine := on.filter(func(b): return _group_of(int(b["n"])) == g)
	return mine if not mine.is_empty() else on.filter(func(b): return int(b["n"]) == 8)


func _group_of(n: int) -> String:
	return "solid" if n >= 1 and n <= 7 else ("stripe" if n >= 9 else ("eight" if n == 8 else "cue"))


func _next_turn_setup() -> void:
	power = 0.0
	charging = false
	if state == "over":
		return
	if turn == 1:
		state = "ai" if state != "place_ai" else "place_ai"
		_ai_t = 1.1
		_ai_plan = {}


# ---------------------------------------------------------------- the shot and the balls rolling

## A shot (from the command bus): the cue ball off at the angle, power 0…1, spin.
func shoot(angle: float, pw: float, sp: Vector2) -> void:
	if state == "roll" or state == "over":
		return
	var cb := _cue()
	_shot_dir = Vector2.RIGHT.rotated(angle)
	cb["v"] = _shot_dir * (60.0 + MAX_V * clampf(pw, 0.0, 1.0))
	_cue_spin = sp.clamp(Vector2(-1, -1), Vector2(1, 1))
	_cue_touched = false
	_first_hit = -1
	_potted = []
	state = "roll"
	Audio.play("pool_cue", "pool: shot", -6.0 + pw * 6.0, 0.1)


func _physics(dt: float) -> void:
	# 0.7.80 (Luz): so many steps that no ball moves more than half a pixel in one – the contact point (and with it
	# where a ball goes) is right also on a hard shot
	var vmax := 0.0
	for b0 in balls:
		if not bool(b0["in"]):
			vmax = maxf(vmax, (b0["v"] as Vector2).length())
	var steps := clampi(int(ceil(vmax * dt / 0.5)), SUB, 96)
	var h := dt / steps
	for s in steps:
		for b in balls:
			if bool(b["in"]):
				continue
			var v: Vector2 = b["v"]
			var sp := v.length()
			if sp > 0.0:
				sp = maxf(0.0, sp - DECEL * h)
				v = v.normalized() * sp if sp > 2.0 else Vector2.ZERO
			b["v"] = v
			b["p"] = (b["p"] as Vector2) + v * h
		# ball on ball
		var on := _on_table()
		for i in on.size():
			for j in range(i + 1, on.size()):
				var a: Dictionary = on[i]
				var c: Dictionary = on[j]
				var d: Vector2 = (c["p"] as Vector2) - (a["p"] as Vector2)
				var dist := d.length()
				if dist < R * 2.0 and dist > 0.001:
					var nrm := d / dist
					var overlap := R * 2.0 - dist
					a["p"] = (a["p"] as Vector2) - nrm * overlap * 0.5
					c["p"] = (c["p"] as Vector2) + nrm * overlap * 0.5
					var rel := ((a["v"] as Vector2) - (c["v"] as Vector2)).dot(nrm)
					if rel > 0.0:
						var imp := nrm * rel * 0.97
						a["v"] = (a["v"] as Vector2) - imp
						c["v"] = (c["v"] as Vector2) + imp
						if int(a["n"]) == 0 or int(c["n"]) == 0:
							var other: Dictionary = c if int(a["n"]) == 0 else a
							var cue_b: Dictionary = a if int(a["n"]) == 0 else c
							if _first_hit < 0:
								_first_hit = int(other["n"])
							if not _cue_touched:
								_cue_touched = true      # follow or draw on the first contact
								cue_b["v"] = (cue_b["v"] as Vector2) + _shot_dir * _cue_spin.y * rel * 0.55
						Audio.play("pool_ball", "pool: balls", -16.0 + minf(rel / 50.0, 14.0), 0.15)
		# the cushions and the pockets
		for b2 in on:
			var p: Vector2 = b2["p"]
			var pk := _pocket_at(p)
			if pk >= 0:
				b2["in"] = true
				b2["v"] = Vector2.ZERO
				_potted.append(int(b2["n"]))
				Audio.play("pool_pocket", "pool: pocketed", -4.0)
				continue
			if _near_pocket(p):
				continue
			var v2: Vector2 = b2["v"]
			var hit := false
			if p.x < FX0 + R and v2.x < 0.0:
				p.x = FX0 + R
				v2.x = -v2.x * 0.76
				hit = true
			elif p.x > FX1 - R and v2.x > 0.0:
				p.x = FX1 - R
				v2.x = -v2.x * 0.76
				hit = true
			if p.y < FY0 + R and v2.y < 0.0:
				p.y = FY0 + R
				v2.y = -v2.y * 0.76
				hit = true
			elif p.y > FY1 - R and v2.y > 0.0:
				p.y = FY1 - R
				v2.y = -v2.y * 0.76
				hit = true
			if hit and v2.length() > 40.0:
				Audio.play("pool_cushion", "pool: cushion", -18.0 + minf(v2.length() / 60.0, 10.0), 0.1)
			if hit and int(b2["n"]) == 0 and absf(_cue_spin.x) > 0.05:
				v2 = v2.rotated(_cue_spin.x * 0.22)          # side spin bends the rebound
				_cue_spin.x *= 0.5
			b2["p"] = p
			b2["v"] = v2


func _pockets() -> Array:
	var mx := (FX0 + FX1) * 0.5
	return [Vector2(FX0, FY0), Vector2(mx, FY0 - 2.0), Vector2(FX1, FY0), Vector2(FX0, FY1), Vector2(mx, FY1 + 2.0), Vector2(FX1, FY1)]


func _pocket_at(p: Vector2) -> int:
	var pk := _pockets()
	for i in pk.size():
		if p.distance_to(pk[i]) < (8.5 if i % 3 != 1 else 7.5):
			return i
	return -1


func _near_pocket(p: Vector2) -> bool:
	for q in _pockets():
		if p.distance_to(q) < 15.0:
			return true
	return false


func _moving() -> bool:
	for b in balls:
		if not bool(b["in"]) and (b["v"] as Vector2).length() > 0.0:
			return true
	return false


# ---------------------------------------------------------------- after the shot: the rules

func _shot_over() -> void:
	if mode == "practice":
		if _cue()["in"]:
			_respot_cue()
		state = "aim"
		if _on_table().size() <= 1:
			_say("Table cleared: R racks again.")
		return
	var who := turn
	var cue_in := _potted.has(0)
	var legal := legal_targets(who)
	var legal_n := legal.map(func(b): return int(b["n"]))
	# what counted as legal before this shot (the balls just pocketed were still there)
	var foul := cue_in or _first_hit < 0
	if not foul and not break_shot:
		if mode == "9ball":
			foul = _first_hit != _lowest_before()
		else:
			var g := String(groups[who])
			if g == "":
				foul = _first_hit == 8
			else:
				var cleared := _group_cleared_before(who)
				foul = not (_group_of(_first_hit) == g or (cleared and _first_hit == 8))
	var potted_obj := _potted.filter(func(n): return int(n) != 0)
	var was_break := break_shot
	break_shot = false
	if was_break and mode != "9ball" and potted_obj.has(8):
		_respot(8)                                   # the 8 on the break goes back on its spot
		potted_obj.erase(8)
	# the deciding ball
	if mode == "9ball" and potted_obj.has(9):
		if foul:
			_respot(9)
		else:
			_end(who == 0, "You pocket the 9." if who == 0 else "%s pockets the 9." % _opp_name())
			return
	if mode != "9ball" and potted_obj.has(8):
		var ok := not foul and String(groups[who]) != "" and _group_cleared_before(who)
		var subj := "You sink" if who == 0 else "%s sinks" % _opp_name()
		_end((who == 0) == ok, ("%s the 8: game." if ok else "%s the 8 too early (or with a foul): game lost.") % subj)
		return
	# groups
	if mode != "9ball" and String(groups[who]) == "" and not foul and not potted_obj.is_empty():
		var g2 := _group_of(int(potted_obj[0]))
		if g2 in ["solid", "stripe"]:
			groups[who] = g2
			groups[1 - who] = "stripe" if g2 == "solid" else "solid"
			_say("%s take%s the %ss." % ["You" if who == 0 else _opp_name(), "" if who == 0 else "s", g2])
	var keep := false
	if not foul:
		if mode == "9ball":
			keep = not potted_obj.is_empty()
		else:
			for n in potted_obj:
				if String(groups[who]) == "" or _group_of(int(n)) == String(groups[who]):
					keep = true
	if cue_in:
		_respot_cue()
	if foul:
		turn = 1 - turn
		_say("Foul: %s." % ("ball in hand for you" if turn == 0 else "ball in hand for %s" % _opp_name()))
		state = "place" if turn == 0 else "place_ai"
	elif keep:
		state = "aim"
		if who == 1:
			_quip(true)
	else:
		if who == 1:
			_quip(false)
		turn = 1 - turn
		state = "aim"
		if turn == 0:
			_say("Your shot.")
	_next_turn_setup()


var _before := []                                # the balls on the table when the shot began


func _lowest_before() -> int:
	var lo := 99
	for n in _before:
		if int(n) != 0:
			lo = mini(lo, int(n))
	return lo


func _group_cleared_before(who: int) -> bool:
	var g := String(groups[who])
	if g == "":
		return false
	for n2 in _before:
		if _group_of(int(n2)) == g:
			return false                              # one of them was still on the table when the shot began
	return true


func _respot_cue() -> void:
	var cb := _cue()
	cb["in"] = false
	cb["v"] = Vector2.ZERO
	cb["p"] = _free_spot(Vector2(FX0 + 88.0, (FY0 + FY1) * 0.5))


func _respot(n: int) -> void:
	for b in balls:
		if int(b["n"]) == n:
			b["in"] = false
			b["v"] = Vector2.ZERO
			b["p"] = _free_spot(Vector2(FX0 + (FX1 - FX0) * 0.75, (FY0 + FY1) * 0.5))


func _free_spot(p: Vector2) -> Vector2:
	var q := p
	for i in 60:
		if _spot_free(q):
			return q
		q = p + Vector2(i * 2.0, 0)
	return q


func _spot_free(q: Vector2) -> bool:
	if q.x < FX0 + R or q.x > FX1 - R or q.y < FY0 + R or q.y > FY1 - R:
		return false
	for b in _on_table():
		if int(b["n"]) != 0 and (b["p"] as Vector2).distance_to(q) < R * 2.1:
			return false
	return true


func _end(you_won: bool, why: String) -> void:
	state = "over"
	won = you_won
	_say(why)
	Commands.execute({"type": "minigame_end", "won": you_won})
	Audio.play("mission_complete" if you_won else "warn", "pool: game over")
	_show_result()


## Debug / concede: the game ends now.
func finish(you_won: bool) -> void:
	if state == "over":
		return
	_end(you_won, "You win." if you_won else ("You concede." if mode != "practice" else "Practice over."))


func _alcohol() -> float:
	var a := float(GameState.pilot.get("alcohol", 0.0))
	var since := GameState.play_time - float(GameState.pilot.get("alcohol_t", GameState.play_time))
	return clampf(a - since / 600.0, 0.0, 1.0)


func _say(t: String) -> void:
	msg = t
	msg_t = 4.0


func _quip(good: bool) -> void:
	var lines := ["\"Too easy.\"", "\"Watch and learn.\"", "\"That's how it's done.\""] if good else ["\"Damn.\"", "\"Your shot, spacer.\"", "\"The table's crooked.\""]
	_say("%s: %s" % [_opp_name(), lines[_rng.randi() % lines.size()]])


# ---------------------------------------------------------------- the opponent

func _ai_step(dt: float) -> void:
	_ai_t -= dt
	var stars := clampi(int(opponent.get("stars", 3)), 1, 5)
	if state == "place_ai" and _ai_t < 0.6:
		_ai_place()
		state = "ai"
		return
	if _ai_plan.is_empty() and _ai_t < 0.9:
		_ai_plan = _ai_choose(_cue()["p"])
	if _ai_plan.is_empty():
		return
	aim_a = lerp_angle(aim_a, float(_ai_plan["a"]), 1.0 - exp(-dt * 6.0))
	if _ai_t < 0.45:
		power = float(_ai_plan["pw"]) * clampf((0.45 - _ai_t) / 0.4, 0.0, 1.0)
	if _ai_t <= 0.0:
		var err := _rng.randfn(0.0, ai_error(stars))
		_take_shot(float(_ai_plan["a"]) + err, float(_ai_plan["pw"]) * _rng.randf_range(0.92, 1.08), Vector2(0, float(_ai_plan.get("spin", 0.0))))


## The best shot from p: for each legal ball and pocket, the ghost ball, both lines clear, the cut not too thin.
func _ai_choose(cp: Vector2) -> Dictionary:
	var best := {}
	var best_s := -1.0
	for b in legal_targets(turn):
		var tp: Vector2 = b["p"]
		for pk0 in _pockets():
			var pk := _pocket_mouth(pk0)                      # 0.7.80: into the mouth – not at the cushions beside it
			if pk.distance_to(tp) < 1.0:
				continue
			var to_pk := (pk as Vector2) - tp
			var side_pk: bool = absf((pk0 as Vector2).x - (FX0 + FX1) * 0.5) < 1.0
			if side_pk and absf(to_pk.normalized().y) < 0.55:
				continue                                         # a side pocket only takes a ball coming in fairly straight
			var ghost := tp - to_pk.normalized() * R * 2.0
			var to_g := ghost - cp
			var cosc := to_g.normalized().dot(to_pk.normalized())
			if cosc < 0.3:
				continue
			if not _clear(cp, ghost, [0, int(b["n"])]) or not _clear(tp, pk, [int(b["n"])]):
				continue
			# 0.7.80 (Luz): the easiest pot – a straight cut, both distances short (the error grows with them)
			var s := cosc * cosc * 100000.0 / ((to_g.length() + 30.0) * (to_pk.length() + 30.0))
			if s > best_s:
				best_s = s
				var need := (sqrt(2.0 * DECEL * (to_g.length() + to_pk.length() / maxf(cosc, 0.3) * 1.3)) + 80.0) * 1.25
				best = {"a": to_g.angle(), "pw": clampf((need - 60.0) / MAX_V, 0.15, 1.0), "spin": -0.3 if to_g.length() < 60.0 else 0.0}
	if best.is_empty():                                # no clean pot: hit a legal ball at least
		var lt := legal_targets(turn)
		if not lt.is_empty():
			var tb: Dictionary = lt[_rng.randi() % lt.size()]
			best = {"a": ((tb["p"] as Vector2) - cp).angle(), "pw": 0.45}
		else:
			best = {"a": 0.0, "pw": 0.4}
	if break_shot:
		best = {"a": (Vector2(FX0 + (FX1 - FX0) * 0.75, (FY0 + FY1) * 0.5) - cp).angle() + _rng.randf_range(-0.02, 0.02), "pw": 1.0}
	return best


## 0.7.80: where a ball goes in – a little inside from the pocket's point, so its way there stays off the cushions.
func _pocket_mouth(pk: Vector2) -> Vector2:
	var mx := (FX0 + FX1) * 0.5
	if absf(pk.x - mx) < 1.0:
		return Vector2(mx, pk.y + (5.0 if pk.y < (FY0 + FY1) * 0.5 else -5.0))
	return pk + Vector2(4.0 if pk.x < mx else -4.0, 4.0 if pk.y < (FY0 + FY1) * 0.5 else -4.0)


## How far off the opponent's cue goes (radians, one sigma) by its stars – 0.7.80 (Luz): the strong ones really strong.
func ai_error(stars: int) -> float:
	return [0.045, 0.028, 0.016, 0.0065, 0.0035][clampi(stars, 1, 5) - 1]


func _clear(a: Vector2, b: Vector2, skip: Array) -> bool:
	for o in _on_table():
		if int(o["n"]) in skip:
			continue
		var p: Vector2 = o["p"]
		var t := clampf((p - a).dot(b - a) / maxf((b - a).length_squared(), 0.001), 0.0, 1.0)
		if p.distance_to(a.lerp(b, t)) < R * 2.0:
			return false
	return true


func _ai_place() -> void:
	var cb := _cue()
	var best_p: Vector2 = cb["p"]
	var best_s := -1.0
	for i in 40:
		var q := Vector2(_rng.randf_range(FX0 + 10, FX1 - 10), _rng.randf_range(FY0 + 10, FY1 - 10))
		if not _spot_free(q):
			continue
		var plan := _ai_choose(q)
		var s := 1.0 if plan.has("spin") else 0.1
		if s > best_s:
			best_s = s
			best_p = q
	cb["p"] = best_p
	_ai_plan = {}


func _take_shot(a: float, pw: float, sp: Vector2) -> void:
	_before = _on_table().map(func(b): return int(b["n"]))
	Commands.execute({"type": "pool_shot", "angle": a, "power": pw, "spin": [sp.x, sp.y]})


# ---------------------------------------------------------------- the loop and the player's hand

func _process(dt: float) -> void:
	_t += dt
	_pad_poll()
	msg_t = maxf(0.0, msg_t - dt)
	match state:
		"roll":
			_physics(dt)
			if not _moving():
				_shot_over()
		"ai", "place_ai":
			_ai_step(dt)
		"aim":
			if turn == 0 or mode == "practice":
				_which_hand()
				var m := _art_mouse()
				var cp: Vector2 = _cue()["p"]
				if _stick_hand:
					_pad_aim_step(dt)                           # package 80: the controller's sticks
				elif m.distance_to(cp) > 2.0 and not spin_drag:
					aim_a = (m - cp).angle() + sin(_t * 2.1) * 0.05 * _alcohol()     # after a few drinks the cue wanders
				if charging:
					power = minf(1.0, power + dt * 0.9)
				if not _stick_hand:
					var kv := Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
						float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
					if kv.length() > 0.1:
						spin = (spin + Vector2(kv.x, -kv.y) * dt * 1.5).limit_length(1.0)
		"place":
			_which_hand()
			var cb := _cue()
			if _stick_hand:
				_pad_aim_step(dt)
			else:
				var q := _art_mouse().clamp(Vector2(FX0 + R, FY0 + R), Vector2(FX1 - R, FY1 - R))
				if _spot_free(q):
					cb["p"] = q
	_update_ui()
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if state == "over":
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if state == "place" and mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			state = "aim"
			_say("Ball placed: your shot.")
			accept_event()
			return
		if state != "aim" or (turn != 0 and mode != "practice"):
			return
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				charging = true
				power = 0.0
			elif charging:
				charging = false
				if power > 0.03:
					_take_shot(aim_a, power, spin)
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			spin_drag = mb.pressed
			accept_event()
	elif event is InputEventMouseMotion and spin_drag:
		spin = (spin + Vector2((event as InputEventMouseMotion).relative.x, -(event as InputEventMouseMotion).relative.y) * 0.01).limit_length(1.0)


## Package 80 (Luz): with the controller – the left stick aims the cue (the D-pad nudges it), the right stick sets
## the spin, L2 held charges and letting go shoots; placing the cue ball: the left stick moves it, ✕ puts it down;
## △ racks again (practice), ✕ after the game: back to the table. The game reads the sticks itself; whatever was
## moved last aims – the sticks or the mouse.
var _stick_hand := false
var _mouse_seen := Vector2.INF
var pad_buttons := ["l2", "left", "right", "cross", "triangle"]

## Package 80: the controller's buttons read here each frame (pad_buttons) – the game does not wait for the context.
var _pad_prev := {}


func _pad_poll() -> void:
	for b in pad_buttons:
		var h := Pad.held(b)
		if h != bool(_pad_prev.get(b, false)):
			_pad_prev[b] = h
			pad_button(b, h)


func _which_hand() -> void:
	var mp := get_local_mouse_position()
	if _mouse_seen != Vector2.INF and mp.distance_to(_mouse_seen) > 1.5:
		_stick_hand = false
	_mouse_seen = mp
	if Pad.left_stick().length() > 0.25 or Pad.right_stick().length() > 0.15:
		_stick_hand = true


func _pad_aim_step(dt: float) -> void:
	var l := Pad.left_stick()
	var r := Pad.right_stick()
	if state == "aim" and (turn == 0 or mode == "practice"):
		if l.length() > 0.3:
			aim_a = lerp_angle(aim_a, l.angle(), 1.0 - exp(-dt * lerpf(0.6, 5.0, Pad.mg_aim) * l.length()))     # (Settings → Controller)
		if r.length() > 0.15:
			spin = Vector2(r.x, -r.y).limit_length(1.0)
	elif state == "place" and l.length() > 0.1:
		var cb := _cue()
		var q: Vector2 = ((cb["p"] as Vector2) + l * 90.0 * dt).clamp(Vector2(FX0 + R, FY0 + R), Vector2(FX1 - R, FY1 - R))
		if _spot_free(q):
			cb["p"] = q


func pad_button(b: String, pressed: bool) -> bool:
	var mine := turn == 0 or mode == "practice"
	match b:
		"l2":
			if state == "aim" and mine:
				if pressed:
					charging = true
					power = 0.0
				elif charging:
					charging = false
					if power > 0.03:
						_take_shot(aim_a, power, spin)
			return true
		"left", "right":
			if pressed and state == "aim" and mine:
				aim_a += 0.003 * (-1.0 if b == "left" else 1.0)
			return true
		"cross":
			if pressed and state == "place":
				state = "aim"
				_say("Ball placed: your shot.")
			elif pressed and state == "over":
				finished.emit(won)
			return true
		"triangle":
			if pressed and mode == "practice" and state != "roll":
				rack()
			return true
	return false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_back", false, true):
		get_viewport().set_input_as_handled()
		if state == "over":
			finished.emit(won)
		else:
			finish(false)
	elif event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_R and mode == "practice" and state != "roll":
		rack()


func _scale() -> float:
	var vs := get_viewport_rect().size
	return floorf((minf(vs.x / AW, vs.y / AH) + 0.02) * 2.0) / 2.0


func _origin() -> Vector2:
	var vs := get_viewport_rect().size
	return (vs - Vector2(AW, AH) * _scale()) * 0.5


func _art_mouse() -> Vector2:
	return (get_local_mouse_position() - _origin()) / _scale()


# ---------------------------------------------------------------- drawing

func _draw() -> void:
	var s := _scale()
	var o := _origin()
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color(0.08, 0.05, 0.04))
	draw_set_transform(o, 0.0, Vector2(s, s))
	draw_texture(_table, Vector2.ZERO)
	var cp: Vector2 = _cue()["p"]
	var my_turn := (turn == 0 or mode == "practice")
	# the aim help: to the first ball it would touch, the ghost ball, where the object ball goes
	if state == "aim" and my_turn:
		# 54b (Luz): the line goes on off the cushions too – 0.7.80 (Luz): one bank only, fainter after it
		var d := Vector2.RIGHT.rotated(aim_a)
		var from := cp
		for seg in 2:
			var hit := _ray(from, d)
			var end: Vector2 = hit["end"]
			var a := 0.55 * (1.0 - seg * 0.28)
			var n := int(from.distance_to(end) / 3.0)
			for i in n:
				if i % 2 == 0:
					var q := from + d * ((R if seg == 0 else 0.0) + i * 3.0)
					draw_rect(Rect2(q.floor(), Vector2(1, 1)), Color(1, 1, 1, a))
			if hit.has("ball"):
				draw_arc(end, R, 0.0, TAU, 20, Color(1, 1, 1, a + 0.15), 1.0)
				var tp: Vector2 = hit["ball"]
				var od := (tp - end).normalized()
				for k in 10:
					if k % 2 == 0:
						draw_rect(Rect2((tp + od * (R + 1.0 + k * 2.6)).floor(), Vector2(1, 1)), Color(1.0, 0.9, 0.4, 0.7))
				break
			if _near_pocket(end):
				break                                          # off into a pocket – no cushion there
			if end.x <= FX0 + R + 0.01 or end.x >= FX1 - R - 0.01:
				d.x = -d.x * 0.76                          # 0.7.80 (Luz): as the cushion does – the ball leaves flatter
			if end.y <= FY0 + R + 0.01 or end.y >= FY1 - R - 0.01:
				d.y = -d.y * 0.76
			d = d.normalized()
			if absf(spin.x) > 0.05:
				d = d.rotated(spin.x * 0.22)               # side spin bends the rebound
			draw_rect(Rect2(end.floor() - Vector2(1, 1), Vector2(2, 2)), Color(1, 1, 1, a))   # where it touches the cushion
			from = end + d * 0.05
	# the balls: shadow, then the ball
	for b in _on_table():
		var p: Vector2 = b["p"]
		draw_circle(p + Vector2(1.5, 2.0), R, Color(0, 0, 0, 0.35))
	for b2 in _on_table():
		var p2: Vector2 = (b2["p"] as Vector2).round()
		draw_texture(_ball_tex[int(b2["n"])], p2 - Vector2(6, 6))
	if state == "place":
		draw_arc(cp, R + 2.0, 0.0, TAU, 20, Color(0.5, 1.0, 0.6, 0.6 + 0.3 * sin(_t * 6.0)), 1.0)
	# the cue: pulled back with the power
	if state in ["aim", "ai"] and (my_turn or state == "ai"):
		var d2 := Vector2.RIGHT.rotated(aim_a)
		var back := cp - d2 * (R + 3.0 + power * 22.0)
		var nrm := d2.orthogonal()
		for t in 170:
			var q2 := back - d2 * t
			var c: Color
			if t < 2:
				c = Color(0.35, 0.55, 0.85)
			elif t < 6:
				c = Color(0.95, 0.94, 0.9)
			elif t < 100:
				c = Color(0.86, 0.72, 0.5)
			elif t < 130:
				c = Color(0.15, 0.12, 0.12) if (t / 3) % 2 == 0 else Color(0.25, 0.2, 0.18)
			else:
				c = Color(0.32, 0.14, 0.08)
			var wv := 1 if t < 60 else 2
			for k2 in range(-wv + 1, wv + 1):
				draw_rect(Rect2((q2 + nrm * k2).floor(), Vector2(1, 1)), c)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Along a line from p: the first ball (its centre when touched: the ghost) or the cushion.
func _ray(p: Vector2, d: Vector2) -> Dictionary:
	var best := 9999.0
	var out := {}
	for b in _on_table():
		if int(b["n"]) == 0:
			continue
		var c: Vector2 = b["p"]
		var f := c - p
		var t := f.dot(d)
		if t <= 0.0:
			continue
		var h2 := f.length_squared() - t * t
		var rr := (R * 2.0) * (R * 2.0)
		if h2 > rr:
			continue
		var tt := t - sqrt(rr - h2)
		if tt < best:
			best = tt
			out = {"end": p + d * tt, "ball": c}
	if out.is_empty():
		var tx := ((FX1 - R) - p.x) / d.x if d.x > 0.0 else (((FX0 + R) - p.x) / d.x if d.x < 0.0 else 9999.0)
		var ty := ((FY1 - R) - p.y) / d.y if d.y > 0.0 else (((FY0 + R) - p.y) / d.y if d.y < 0.0 else 9999.0)
		out = {"end": p + d * minf(tx, ty)}
	return out


# ---------------------------------------------------------------- the panels

func _build_ui() -> void:
	var tl := UI.neon_panel(Color(1.0, 0.45, 0.7), Color(0.03, 0.05, 0.06, 0.88), 2)
	tl.position = Vector2(20, 20)
	tl.custom_minimum_size = Vector2(470, 0)
	add_child(tl)
	var v := UI.vbox(4)
	tl.add_child(v)
	_ui["title"] = UI.label("", 20, Color(1.0, 0.6, 0.8))
	_ui["groups"] = UI.label("", 14, Color(0.75, 0.85, 1.0))
	_ui["msg"] = UI.label("", 14, Color(0.5, 1.0, 0.6))
	for k in ["title", "groups", "msg"]:
		v.add_child(_ui[k])
	var tr := UI.neon_panel(Color(1.0, 0.8, 0.3), Color(0.03, 0.05, 0.06, 0.88), 2)
	tr.custom_minimum_size = Vector2(400, 0)
	tr.position = Vector2(get_viewport_rect().size.x - 420, 20)
	add_child(tr)
	var v2 := UI.vbox(4)
	tr.add_child(v2)
	var streak := int(GameState.minigame_streak.get("billiards", 0))
	v2.add_child(UI.label("Stake %d cr" % stake if stake > 0 else ("No stake" if mode != "practice" else "Practice"), 20, Color(1.0, 0.85, 0.4)))
	v2.add_child(UI.label("Win streak %d: %s stakes (up to %d cr)" % [streak, String(MG.TIERS[MG.tier(streak)]["name"]), MG.max_stake(streak)], 14, Color(0.9, 0.93, 1.0)))
	v2.add_child(UI.label("medium from 10 wins, high from 25", 12, UI.TEXT_DIM))
	var hint := UI.label("Mouse: aim  •  hold left button: power, let go: shoot  •  right button + drag (or WASD): spin  •  Esc: concede" + ("  •  R: rack again" if mode == "practice" else ""), 15)
	hint.position = Vector2(get_viewport_rect().size.x * 0.5 - 420, get_viewport_rect().size.y - 40)
	add_child(hint)
	var pw := Control.new()
	pw.position = Vector2(get_viewport_rect().size.x - 100, 300)
	pw.size = Vector2(70, 380)
	add_child(pw)
	_ui["pw"] = pw
	pw.draw.connect(func():
		pw.draw_rect(Rect2(0, 0, 70, 380), Color(0.03, 0.05, 0.06, 0.88))
		pw.draw_rect(Rect2(0, 0, 70, 380), Color(0.35, 0.95, 1.0), false, 2.0)
		pw.draw_rect(Rect2(20, 20, 30, 230), Color(0.1, 0.12, 0.16))
		pw.draw_rect(Rect2(20, 20 + 230 * (1.0 - power), 30, 230 * power), Color(1.0, 0.6, 0.2).lerp(Color(1.0, 0.25, 0.2), power))
		pw.draw_string(ThemeDB.fallback_font, Vector2(10, 272), "POWER", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UI.TEXT_DIM)
		var c := Vector2(35, 318)
		pw.draw_circle(c, 24.0, Color(0.95, 0.94, 0.88))
		pw.draw_arc(c, 24.0, 0, TAU, 48, Color(0.4, 0.4, 0.4), 2.0)
		pw.draw_circle(c + Vector2(spin.x, -spin.y) * 18.0, 4.0, Color(0.9, 0.2, 0.2))
		pw.draw_string(ThemeDB.fallback_font, Vector2(16, 368), "SPIN", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UI.TEXT_DIM))


func _update_ui() -> void:
	if not _ui.has("title"):
		return
	var names := {"8ball": "8-BALL", "9ball": "9-BALL", "practice": "PRACTICE"}
	if mode == "practice":
		_ui["title"].text = "PRACTICE: the table to yourself"
		_ui["groups"].text = "%d balls left" % (_on_table().size() - 1)
	else:
		_ui["title"].text = "%s   vs %s, %s  %s" % [names[mode], opponent.get("name", "?"), opponent.get("job", ""), MG.stars_text(int(opponent.get("stars", 3)))]
		if mode == "9ball":
			_ui["groups"].text = "Lowest ball: %d" % _lowest_now()
		else:
			_ui["groups"].text = "You: %s      %s: %s" % [_group_text(0), _opp_name(), _group_text(1)]
	var t := msg if msg_t > 0.0 else ("Your shot" if turn == 0 or mode == "practice" else "%s's shot" % _opp_name())
	if state == "place":
		t = "Ball in hand: place the cue ball (click)"
	if not _ui.has("msg"):
		return
	_ui["msg"].text = t
	(_ui["pw"] as Control).queue_redraw()


func _lowest_now() -> int:
	var lo := 99
	for b in _on_table():
		if int(b["n"]) != 0:
			lo = mini(lo, int(b["n"]))
	return lo


func _group_text(who: int) -> String:
	var g := String(groups[who])
	if g == "":
		return "open"
	var left := _on_table().filter(func(b): return _group_of(int(b["n"])) == g).size()
	return "%ss %s" % [g, "●".repeat(7 - left) + "○".repeat(left)]


func _show_result() -> void:
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(cc)
	var p := UI.neon_panel(Color(0.5, 1.0, 0.6) if won else Color(1.0, 0.4, 0.4), Color(0.03, 0.05, 0.06, 0.95), 2)
	p.custom_minimum_size = Vector2(460, 0)
	cc.add_child(p)
	var v := UI.vbox(10)
	p.add_child(v)
	if mode == "practice":
		v.add_child(UI.label("PRACTICE OVER", 24, Color(0.9, 0.93, 1.0)))
	else:
		v.add_child(UI.label("YOU WIN" if won else "YOU LOSE", 26, Color(0.5, 1.0, 0.6) if won else Color(1.0, 0.45, 0.45)))
		v.add_child(UI.label(msg, 14, UI.TEXT_DIM))
		if stake > 0:
			v.add_child(UI.label(("+%d cr" % stake) if won else ("−%d cr" % stake), 18, Color(1.0, 0.85, 0.4)))
		v.add_child(UI.label("Win streak: %d" % int(GameState.minigame_streak.get("billiards", 0)), 14, Color(0.9, 0.93, 1.0)))
		if won and Commands.mg_last_tip != "":
			v.add_child(UI.wrap_label(Commands.mg_last_tip, 14, Color(0.6, 0.95, 1.0), 430))      # 54b: what the loser let slip
	v.add_child(UI.button("Back to the table [Esc]", func(): finished.emit(won)))


# ---------------------------------------------------------------- the pictures

func _paint_table() -> Image:
	var img := Image.create(AW, AH, false, Image.FORMAT_RGBA8)
	for y in AH:
		for x in AW:
			var c := Color(0.16, 0.11, 0.08).lerp(Color(0.2, 0.14, 0.1), _h(x / 3, y / 16, 3))
			if y % 16 == 0:
				c = c.darkened(0.3)
			img.set_pixel(x, y, c)
	var x0 := 70
	var y0 := 48
	var x1 := 464
	var y1 := 268
	_rect(img, x0 + 4, y0 + 6, x1 - x0, y1 - y0, Color(0, 0, 0, 0.45))
	for y in range(y0, y1):
		for x in range(x0, x1):
			var c2 := Color(0.42, 0.22, 0.11).lerp(Color(0.5, 0.28, 0.14), _h(x / 9, y, 5))
			if y < y0 + 2 or x < x0 + 2:
				c2 = c2.lightened(0.2)
			if y > y1 - 3 or x > x1 - 3:
				c2 = c2.darkened(0.3)
			img.set_pixel(x, y, c2)
	var lamp := Vector2((FX0 + FX1) * 0.5, (FY0 + FY1) * 0.5)
	for y2 in range(int(FY0), int(FY1)):
		for x2 in range(int(FX0), int(FX1)):
			var l := clampf(1.0 - Vector2(x2 - lamp.x, (y2 - lamp.y) * 1.8).length() / 260.0, 0.0, 1.0)
			var c3 := Color(0.06, 0.32, 0.18).lerp(Color(0.12, 0.55, 0.32), l)
			if _h(x2, y2, 7) < 0.08:
				c3 = c3.darkened(0.06)
			img.set_pixel(x2, y2, c3)
	for e in 4:
		_rect(img, int(FX0), int(FY0) + e, int(FX1 - FX0), 1, Color(0.05, 0.28 - e * 0.03, 0.15))
		_rect(img, int(FX0), int(FY1) - 1 - e, int(FX1 - FX0), 1, Color(0.04, 0.22, 0.12))
		_rect(img, int(FX0) + e, int(FY0), 1, int(FY1 - FY0), Color(0.05, 0.28 - e * 0.03, 0.15))
		_rect(img, int(FX1) - 1 - e, int(FY0), 1, int(FY1 - FY0), Color(0.04, 0.22, 0.12))
	_rect(img, int(FX0) + 88, int(FY0) + 4, 1, int(FY1 - FY0) - 8, Color(0.7, 0.9, 0.75, 0.25))
	for pk in _pockets():
		_circ(img, pk.x, pk.y, 11.0, Color(0.12, 0.08, 0.06))
		_circ(img, pk.x, pk.y, 9.0, Color(0.02, 0.02, 0.02))
	for dm in 7:
		if dm != 3:
			var dx := x0 + 20 + (x1 - x0 - 40) * (dm + 1) / 8.0
			_circ(img, dx, y0 + 10, 1.5, Color(0.92, 0.9, 0.82))
			_circ(img, dx, y1 - 10, 1.5, Color(0.92, 0.9, 0.82))
	for dm2 in 3:
		var dy := y0 + 20 + (y1 - y0 - 40) * (dm2 + 1) / 4.0
		_circ(img, x0 + 10, dy, 1.5, Color(0.92, 0.9, 0.82))
		_circ(img, x1 - 10, dy, 1.5, Color(0.92, 0.9, 0.82))
	return img


func _paint_ball(n: int) -> Image:
	var img := Image.create(12, 12, false, Image.FORMAT_RGBA8)
	var cols := [Color(0.95, 0.94, 0.88), Color(0.95, 0.78, 0.15), Color(0.2, 0.35, 0.9), Color(0.9, 0.2, 0.15), Color(0.5, 0.2, 0.7),
		Color(0.95, 0.5, 0.12), Color(0.15, 0.6, 0.3), Color(0.55, 0.15, 0.12), Color(0.08, 0.08, 0.09)]
	var base: Color = cols[n if n <= 8 else n - 8]
	var c0 := Vector2(6, 6)
	for y in 12:
		for x in 12:
			var d := Vector2(x + 0.5, y + 0.5) - c0
			if d.length() > R:
				continue
			var c := base
			if n > 8 and absf(d.y) > 2.2:
				c = Color(0.95, 0.94, 0.88)
			var lit := clampf(1.0 - (d + Vector2(1.6, 1.6)).length() / (R * 1.6), 0.0, 1.0)
			img.set_pixel(x, y, c.darkened(0.35 * (1.0 - lit)).lightened(0.25 * lit * lit))
	if n > 0:
		for y2 in range(4, 8):
			for x2 in range(4, 8):
				if Vector2(x2 + 0.5, y2 + 0.5).distance_to(c0) <= 1.8:
					img.set_pixel(x2, y2, Color(0.97, 0.96, 0.9))
		img.set_pixel(6, 6, Color(0.1, 0.1, 0.1))
	img.set_pixel(4, 4, Color(1, 1, 1))
	return img


func _h(x: int, y: int, s: int = 0) -> float:
	var v := sin(float(x) * 12.9898 + float(y) * 78.233 + float(s) * 3.7) * 43758.5453
	return v - floor(v)


func _rect(img: Image, x: int, y: int, w: int, hh: int, c: Color) -> void:
	for yy in range(y, y + hh):
		for xx in range(x, x + w):
			if xx >= 0 and yy >= 0 and xx < AW and yy < AH:
				img.set_pixel(xx, yy, c if c.a >= 0.999 else img.get_pixel(xx, yy).lerp(Color(c.r, c.g, c.b), c.a))


func _circ(img: Image, cx: float, cy: float, r: float, c: Color) -> void:
	for y in range(int(cy - r) - 1, int(cy + r) + 2):
		for x in range(int(cx - r) - 1, int(cx + r) + 2):
			if x >= 0 and y >= 0 and x < AW and y < AH and Vector2(x + 0.5 - cx, y + 0.5 - cy).length() <= r:
				img.set_pixel(x, y, c)
