extends Control
## Package 54b (Luz): darts at the board on the bar's wall (mockup_54b_darts) – the camera on the board: sisal,
## wires, the trebles and doubles, the numbers on the ring. 301 or 501 down to exactly nothing against a guest (or one
## of your crew) – below nothing is a bust, the turn's darts count for nothing; or around the clock alone. The hand
## sways – less with Reflexes, more after a few drinks; hold the right button to hold your breath (steady for a
## moment). Every throw goes through the command bus (dart_throw), so a co-op player's throw can come the same way.
## No class_name: preload it.

signal finished(won: bool)

const MG = preload("res://data/minigames.gd")
const AW := 534
const AH := 300
const BC := Vector2(267, 150)                    # the board's centre (art px)
const R_BULL := 4.0
const R_OUTER_BULL := 9.0
const R_T0 := 55.0
const R_T1 := 61.0
const R_D0 := 92.0
const R_D1 := 98.0
const ORDER := [20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5]

var mode := "301"
var opponent := {}
var stake := 0
var score := [301, 301]
var turn := 0
var darts_left := 3
var turn_start := 301
var this_turn: Array = []                        # labels of this turn's darts
var last_opp := ""
var stuck: Array = []                            # [pos, who] – darts in the board this turn
var flying := {}                                 # {from, to, t, who}
var state := "aim"                               # aim, fly, ai, wait, over
var clock_target := 1
var clock_darts := 0
var breath := 1.0
var holding := false
var won := false
var msg := ""
var msg_t := 0.0
var _t := 0.0
var _wait := 0.0
var _ai_t := 0.0
var _rng := RandomNumberGenerator.new()
var _board: ImageTexture
var _ui := {}
var _labels: Array = []
var _pad_aim := Vector2.INF                        # package 80: the controller's aim (art px)


func setup(cfg: Dictionary) -> void:
	mode = String(cfg.get("mode", "301"))
	opponent = cfg.get("opponent", {})
	stake = int(cfg.get("stake", 0))
	_rng.seed = Time.get_ticks_usec()
	var start := 501 if mode == "501" else 301
	score = [start, start]
	turn_start = start
	turn = 0 if mode == "clock" or _rng.randf() < 0.5 else 1
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_board = ImageTexture.create_from_image(_paint_board())
	_begin_turn()


func _ready() -> void:
	_build_ui()


func _opp_name() -> String:
	return String(opponent.get("name", "Your opponent")).split(" ")[0].replace("\"", "")


# ---------------------------------------------------------------- scoring

## What a dart at p (art px) scores: [points, label].
static func score_at(p: Vector2) -> Array:
	var d := p - BC
	var r := d.length()
	if r <= R_BULL:
		return [50, "Bull"]
	if r <= R_OUTER_BULL:
		return [25, "25"]
	if r > R_D1:
		return [0, "–"]
	var seg := int(fposmod(atan2(d.x, -d.y) + PI / 20.0, TAU) / (TAU / 20.0)) % 20
	var v: int = ORDER[seg]
	if r >= R_T0 and r <= R_T1:
		return [v * 3, "T%d" % v]
	if r >= R_D0:
		return [v * 2, "D%d" % v]
	return [v, str(v)]


## Where to aim for a number and ring ("S", "T", "D", "B" bull).
static func target(v: int, ring: String) -> Vector2:
	if ring == "B":
		return BC
	var seg := ORDER.find(v)
	var a := seg * TAU / 20.0
	var rr := (R_T1 + R_D0) * 0.5
	if ring == "T":
		rr = (R_T0 + R_T1) * 0.5
	elif ring == "D":
		rr = (R_D0 + R_D1) * 0.5
	return BC + Vector2(sin(a), -cos(a)) * rr


# ---------------------------------------------------------------- the throw

## How far the hand sways now (art px).
func sway_amp() -> float:
	var refl := GameState.pilot_attr("reflexes")
	var a := 16.0 - refl * 1.6 + _alcohol() * 14.0                 # 54b (Luz): harder – even a steady hand sways a ring's width
	return maxf(4.0, a) * (0.45 if holding and breath > 0.0 else 1.0)


func _alcohol() -> float:
	var a := float(GameState.pilot.get("alcohol", 0.0))
	var since := GameState.play_time - float(GameState.pilot.get("alcohol_t", GameState.play_time))
	return clampf(a - since / 600.0, 0.0, 1.0)


func _sway() -> Vector2:
	var a := sway_amp()
	return Vector2(sin(_t * 2.1) + 0.45 * sin(_t * 5.3), sin(_t * 2.7 + 0.6) + 0.35 * sin(_t * 6.1)) * a


## A throw (from the command bus): the dart flies to p.
func throw_at(p: Vector2) -> void:
	if state == "over" or state == "fly" or darts_left <= 0:
		return
	flying = {"from": p + Vector2(40, 120), "to": p, "t": 0.0, "who": turn}
	state = "fly"
	Audio.play("dart_throw", "darts: throw", -6.0, 0.15)


func _land(p: Vector2) -> void:
	var sc := score_at(p)
	stuck.append([p, turn])
	darts_left -= 1
	Audio.play("dart_hit", "darts: thud", -2.0, 0.1)
	if mode == "clock":
		clock_darts += 1
		var want := clock_target
		var hit := false
		if want <= 20:
			hit = int(sc[0]) > 0 and int(sc[0]) <= 60 and String(sc[1]).trim_prefix("T").trim_prefix("D") == str(want)
		else:
			hit = int(sc[0]) >= 25
		this_turn.append(String(sc[1]))
		if hit:
			clock_target += 1
			if clock_target > 21:
				var best := int(GameState.minigame_best.get("darts_clock", 999))
				if clock_darts < best:
					GameState.minigame_best["darts_clock"] = clock_darts
				_end(true, "Round the clock in %d darts%s." % [clock_darts, " – a new best" if clock_darts < best else ""])
				return
		_after_dart()
		return
	this_turn.append(String(sc[1]))
	var left: int = int(score[turn]) - int(sc[0])
	if left == 0:
		score[turn] = 0
		_end(turn == 0, ("You check out with %s." if turn == 0 else "%s checks out with %s." % [_opp_name(), "%s"]) % String(sc[1]))
		return
	if left < 0:
		score[turn] = turn_start
		_say("Bust! %s." % ("Your turn counts for nothing" if turn == 0 else "%s's turn counts for nothing" % _opp_name()))
		darts_left = 0
	else:
		score[turn] = left
	_after_dart()


func _after_dart() -> void:
	if darts_left > 0:
		state = "aim" if turn == 0 or mode == "clock" else "ai"
		_ai_t = 0.9
		return
	state = "wait"
	_wait = 1.1


func _begin_turn() -> void:
	darts_left = 3
	this_turn = []
	stuck = []
	turn_start = int(score[turn])
	state = "aim" if turn == 0 or mode == "clock" else "ai"
	_ai_t = 1.2
	if mode != "clock":
		_say("Your darts." if turn == 0 else "%s steps up to the line." % _opp_name())


func _next_turn() -> void:
	if mode != "clock":
		if turn == 1:
			last_opp = " · ".join(PackedStringArray(this_turn)) + "  (%d)" % (turn_start - int(score[1]))
		turn = 1 - turn
	_begin_turn()


func _end(you_won: bool, why: String) -> void:
	state = "over"
	won = you_won
	_say(why)
	Commands.execute({"type": "minigame_end", "won": you_won})
	Audio.play("mission_complete" if you_won else "warn", "darts: game over")
	_show_result()


func finish(you_won: bool) -> void:
	if state == "over":
		return
	_end(you_won, "You win." if you_won else ("You concede." if mode != "clock" else "Practice over."))


func _say(t: String) -> void:
	msg = t
	msg_t = 3.5


# ---------------------------------------------------------------- the opponent

## Where the guest aims with this many points left: trebles while far off, then a finish in one dart if there is one.
func ai_aim(left: int) -> Vector2:
	if left > 60:
		return target(20, "T")
	if left == 50:
		return target(0, "B")
	if left <= 20:
		return target(left, "S")
	if left <= 40 and left % 2 == 0:
		return target(left / 2, "D")
	if left % 3 == 0:
		return target(left / 3, "T")
	return target(mini(20, left - 20 if left > 20 else left), "S")    # leave something to finish with


func _ai_step(dt: float) -> void:
	_ai_t -= dt
	if _ai_t > 0.0:
		return
	var stars := clampi(int(opponent.get("stars", 3)), 1, 5)
	var sd := 14.0 - 2.4 * stars
	var aim := ai_aim(int(score[1]))
	_throw(aim + Vector2(_rng.randfn(0.0, sd), _rng.randfn(0.0, sd)))


func _throw(p: Vector2) -> void:
	Commands.execute({"type": "dart_throw", "x": p.x, "y": p.y})


# ---------------------------------------------------------------- the loop, the hand

func _process(dt: float) -> void:
	_t += dt
	_pad_aim_step(dt)
	_pad_poll()
	msg_t = maxf(0.0, msg_t - dt)
	if holding and breath > 0.0:
		breath = maxf(0.0, breath - dt / 1.8)
	elif not holding:
		breath = minf(1.0, breath + dt / 4.0)
	match state:
		"fly":
			flying["t"] = float(flying["t"]) + dt / 0.22
			if float(flying["t"]) >= 1.0:
				var to: Vector2 = flying["to"]
				flying = {}
				state = "landed"
				_land(to)
		"ai":
			_ai_step(dt)
		"wait":
			_wait -= dt
			if _wait <= 0.0:
				_next_turn()
	_update_ui()
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			holding = mb.pressed
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed and state == "aim" and (turn == 0 or mode == "clock"):
			var p := _art_mouse() + _sway() + Vector2(_rng.randfn(0.0, 2.2), _rng.randfn(0.0, 2.2))     # the release is never quite clean
			_throw(p)
			accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_back", false, true):
		get_viewport().set_input_as_handled()
		if state == "over":
			finished.emit(won)
		else:
			finish(false)


func _scale() -> float:
	var vs := get_viewport_rect().size
	return floorf((minf(vs.x / AW, vs.y / AH) + 0.02) * 2.0) / 2.0


func _origin() -> Vector2:
	return (get_viewport_rect().size - Vector2(AW, AH) * _scale()) * 0.5


func _art_mouse() -> Vector2:
	if _pad_aim != Vector2.INF:
		return _pad_aim
	return (get_local_mouse_position() - _origin()) / _scale()


## Package 80 (Luz): with the controller – the left stick moves the aim (the right stick finely), L1 held holds the
## breath, L2 throws; ✕ after the game: back to the table. The game reads the sticks itself; whatever was moved last
## aims – the sticks or the mouse.
var _mouse_seen := Vector2.INF
var pad_buttons := ["l1", "l2", "cross"]

## Package 80: the controller's buttons read here each frame (pad_buttons) – the game does not wait for the context.
var _pad_prev := {}


func _pad_poll() -> void:
	for b in pad_buttons:
		var h := Pad.held(b)
		if h != bool(_pad_prev.get(b, false)):
			_pad_prev[b] = h
			pad_button(b, h)


func _pad_aim_step(dt: float) -> void:
	var mp := get_local_mouse_position()
	if _mouse_seen != Vector2.INF and mp.distance_to(_mouse_seen) > 1.5:
		_pad_aim = Vector2.INF                     # the mouse moved: it aims again
	_mouse_seen = mp
	var l := Pad.left_stick()
	var r := Pad.right_stick()
	if l.length() < 0.1 and r.length() < 0.1:
		return
	if _pad_aim == Vector2.INF:
		_pad_aim = BC
	_pad_aim = (_pad_aim + (l * lerpf(20.0, 110.0, Pad.mg_aim) + r * lerpf(5.0, 30.0, Pad.mg_aim)) * dt).clamp(Vector2(4, 4), Vector2(AW - 4, AH - 4))


func pad_button(b: String, pressed: bool) -> bool:
	match b:
		"l1":
			holding = pressed
			return true
		"l2":
			if pressed and state == "aim" and (turn == 0 or mode == "clock"):
				_throw(_art_mouse() + _sway() + Vector2(_rng.randfn(0.0, 2.2), _rng.randfn(0.0, 2.2)))
			return true
		"cross":
			if pressed and state == "over":
				finished.emit(won)
			return true
	return false


# ---------------------------------------------------------------- drawing

func _draw() -> void:
	var s := _scale()
	var o := _origin()
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color(0.12, 0.13, 0.15))
	draw_set_transform(o, 0.0, Vector2(s, s))
	draw_texture(_board, Vector2.ZERO)
	for d in stuck:
		_dart(d[0], int(d[1]), 1.0)
	if not flying.is_empty():
		var k := float(flying["t"])
		var p: Vector2 = (flying["from"] as Vector2).lerp(flying["to"], k) + Vector2(0, -sin(k * PI) * 20.0)
		_dart(p, int(flying["who"]), 2.6 - 1.6 * k)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# the numbers on the ring
	for i in 20:
		var a := i * TAU / 20.0
		var q := o + (BC + Vector2(sin(a), -cos(a)) * 109.0) * s
		draw_string(ThemeDB.fallback_font, q + Vector2(-24, 7), str(ORDER[i]), HORIZONTAL_ALIGNMENT_CENTER, 48, 20, Color(0.95, 0.92, 0.85))
	# the crosshair, swaying
	if state == "aim" and (turn == 0 or mode == "clock"):
		var ch := o + (_art_mouse() + _sway()) * s
		var col := Color(1.0, 0.3, 0.3) if not (holding and breath > 0.0) else Color(0.35, 0.95, 1.0)
		draw_arc(ch, 16.0, 0, TAU, 32, col, 3.0)
		for dv in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
			draw_line(ch + dv * 8.0, ch + dv * 26.0, col, 3.0)
		draw_circle(ch, 3.0, col)


func _dart(tip: Vector2, who: int, sc: float) -> void:
	var col := Color(0.3, 0.8, 1.0) if who == 0 else Color(1.0, 0.75, 0.25)
	for t in int(22 * sc):
		var q := tip + Vector2(t * 0.55, t * 0.9)
		var tt := t / sc
		var c := Color(0.75, 0.75, 0.78) if tt < 4 else (Color(0.25, 0.25, 0.28) if tt < 12 else col)
		var w := int(sc) if tt < 12 else int(sc) + int((tt - 12) * 0.5 * sc)
		draw_rect(Rect2(q.x - w, q.y, w * 2 + 1, 1), c)
	draw_rect(Rect2(tip, Vector2(1, 1)), Color(0.95, 0.95, 1.0))


# ---------------------------------------------------------------- the panels

func _build_ui() -> void:
	var vs := get_viewport_rect().size
	var tl := UI.neon_panel(Color(1.0, 0.45, 0.7), Color(0.03, 0.05, 0.06, 0.88), 2)
	tl.position = Vector2(20, 20)
	tl.custom_minimum_size = Vector2(400, 0)
	add_child(tl)
	var v := UI.vbox(4)
	tl.add_child(v)
	_ui["title"] = UI.label("", 18, Color(1.0, 0.6, 0.8))
	var row := UI.hbox(40)
	_ui["me"] = UI.label("", 40, Color(0.5, 1.0, 0.6))
	_ui["opp"] = UI.label("", 40, Color(1.0, 0.8, 0.3))
	row.add_child(_ui["me"])
	row.add_child(_ui["opp"])
	_ui["turn"] = UI.label("", 15)
	_ui["last"] = UI.label("", 13, UI.TEXT_DIM)
	_ui["msg"] = UI.label("", 14, Color(0.5, 1.0, 0.6))
	for k in ["title"]:
		v.add_child(_ui[k])
	v.add_child(row)
	for k2 in ["turn", "last", "msg"]:
		v.add_child(_ui[k2])
	var tr := UI.neon_panel(Color(1.0, 0.8, 0.3), Color(0.03, 0.05, 0.06, 0.88), 2)
	tr.custom_minimum_size = Vector2(400, 0)
	tr.position = Vector2(vs.x - 420, 20)
	add_child(tr)
	var v2 := UI.vbox(4)
	tr.add_child(v2)
	var streak := int(GameState.minigame_streak.get("darts", 0))
	v2.add_child(UI.label("Stake %d cr" % stake if stake > 0 else ("No stake" if mode != "clock" else "Practice"), 20, Color(1.0, 0.85, 0.4)))
	v2.add_child(UI.label("Win streak %d – %s stakes (up to %d cr)" % [streak, String(MG.TIERS[MG.tier(streak)]["name"]), MG.max_stake(streak)], 14, Color(0.9, 0.93, 1.0)))
	v2.add_child(UI.label("medium from 10 wins, high from 25", 12, UI.TEXT_DIM))
	var hp := UI.neon_panel(Color(0.35, 0.95, 1.0), Color(0.03, 0.05, 0.06, 0.88), 2)
	hp.custom_minimum_size = Vector2(400, 0)
	hp.position = Vector2(vs.x - 420, 140)
	add_child(hp)
	var v3 := UI.vbox(4)
	hp.add_child(v3)
	v3.add_child(UI.label("STEADY HAND", 13, UI.TEXT_DIM))
	var refl := GameState.pilot_attr("reflexes")
	v3.add_child(UI.label("Reflexes %d – the sway is %s" % [refl, "small" if refl >= 4 else ("moderate" if refl >= 2 else "big")], 15))
	_ui["drunk"] = UI.label("", 15, Color(1.0, 0.7, 0.4))
	_ui["breath"] = UI.label("", 15, Color(0.35, 0.95, 1.0))
	v3.add_child(_ui["drunk"])
	v3.add_child(_ui["breath"])
	var hint := UI.label("Move the mouse: aim (the hand sways)  •  hold right button: hold your breath  •  left click: throw  •  Esc: concede", 15)
	hint.position = Vector2(vs.x * 0.5 - 430, vs.y - 40)
	add_child(hint)


func _update_ui() -> void:
	if not _ui.has("title"):
		return
	if mode == "clock":
		_ui["title"].text = "AROUND THE CLOCK – alone"
		_ui["me"].text = "→ %s" % ("Bull" if clock_target > 20 else str(clock_target))
		_ui["opp"].text = ""
		_ui["turn"].text = "Darts thrown: %d   (best: %s)" % [clock_darts, str(GameState.minigame_best.get("darts_clock", "–"))]
	else:
		_ui["title"].text = "%s   vs %s, %s  %s" % [mode, opponent.get("name", "?"), opponent.get("job", ""), MG.stars_text(int(opponent.get("stars", 3)))]
		_ui["me"].text = "YOU %d" % int(score[0])
		_ui["opp"].text = "%s %d" % [_opp_name().to_upper(), int(score[1])]
		_ui["turn"].text = "This turn:  %s   –   darts left %s" % [" · ".join(PackedStringArray(this_turn)) if not this_turn.is_empty() else "–", "➶".repeat(darts_left)]
	_ui["last"].text = ("%s last: %s" % [_opp_name(), last_opp]) if last_opp != "" else ""
	_ui["msg"].text = msg if msg_t > 0.0 else ""
	var al := _alcohol()
	_ui["drunk"].text = "Sober – a steady hand" if al < 0.05 else ("A drink or two – a little wobbly" if al < 0.4 else "Had a few – the board swims")
	_ui["breath"].text = "Breath: " + "▮".repeat(int(round(breath * 8))) + "▯".repeat(8 - int(round(breath * 8)))


func _show_result() -> void:
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(cc)
	var p := UI.neon_panel(Color(0.5, 1.0, 0.6) if won else Color(1.0, 0.4, 0.4), Color(0.03, 0.05, 0.06, 0.95), 2)
	p.custom_minimum_size = Vector2(460, 0)
	cc.add_child(p)
	var v := UI.vbox(10)
	p.add_child(v)
	if mode == "clock":
		v.add_child(UI.label("ROUND THE CLOCK" if won else "PRACTICE OVER", 24, Color(0.9, 0.93, 1.0)))
		v.add_child(UI.label(msg, 14, UI.TEXT_DIM))
	else:
		v.add_child(UI.label("YOU WIN" if won else "YOU LOSE", 26, Color(0.5, 1.0, 0.6) if won else Color(1.0, 0.45, 0.45)))
		v.add_child(UI.label(msg, 14, UI.TEXT_DIM))
		if stake > 0:
			v.add_child(UI.label(("+%d cr" % stake) if won else ("−%d cr" % stake), 18, Color(1.0, 0.85, 0.4)))
		v.add_child(UI.label("Win streak: %d" % int(GameState.minigame_streak.get("darts", 0)), 14, Color(0.9, 0.93, 1.0)))
		if won and Commands.mg_last_tip != "":
			v.add_child(UI.wrap_label(Commands.mg_last_tip, 14, Color(0.6, 0.95, 1.0), 430))      # 54b: what the loser let slip
	v.add_child(UI.button("Back to the board [Esc]", func(): finished.emit(won)))


# ---------------------------------------------------------------- the picture

func _paint_board() -> Image:
	var img := Image.create(AW, AH, false, Image.FORMAT_RGBA8)
	for y in AH:
		for x in AW:
			var c := Color(0.22, 0.24, 0.27).lerp(Color(0.26, 0.28, 0.31), _h(x / 4, y / 4, 2))
			if x % 48 == 0 or y % 40 == 0:
				c = c.darkened(0.3)
			if (x % 48 == 4 or x % 48 == 44) and (y % 40 == 4 or y % 40 == 36):
				c = c.lightened(0.25)
			var l := clampf(1.0 - Vector2(x - BC.x, (y - BC.y) * 1.1).length() / 170.0, 0.0, 1.0)
			img.set_pixel(x, y, c.lerp(Color(1.0, 0.92, 0.75), l * 0.3))
	_circ(img, BC.x + 3, BC.y + 4, 122, Color(0, 0, 0, 0.45))
	_circ(img, BC.x, BC.y, 122, Color(0.32, 0.18, 0.1))
	_circ(img, BC.x, BC.y, 118, Color(0.12, 0.12, 0.12))
	for y3 in range(int(BC.y - R_D1) - 1, int(BC.y + R_D1) + 2):
		for x3 in range(int(BC.x - R_D1) - 1, int(BC.x + R_D1) + 2):
			var d := Vector2(x3 + 0.5 - BC.x, y3 + 0.5 - BC.y)
			var r := d.length()
			if r > R_D1:
				continue
			var seg := int(fposmod(atan2(d.x, -d.y) + PI / 20.0, TAU) / (TAU / 20.0))
			var dark := seg % 2 == 0
			var c2: Color
			if r <= R_BULL:
				c2 = Color(0.85, 0.15, 0.15)
			elif r <= R_OUTER_BULL:
				c2 = Color(0.15, 0.6, 0.25)
			elif (r >= R_T0 and r <= R_T1) or r >= R_D0:
				c2 = Color(0.85, 0.15, 0.15) if dark else Color(0.15, 0.6, 0.25)
			else:
				c2 = Color(0.1, 0.1, 0.1) if dark else Color(0.92, 0.86, 0.68)
			if _h(x3, y3, 5) < 0.12:
				c2 = c2.darkened(0.1)
			img.set_pixel(x3, y3, c2)
	for s in 20:
		var a2 := s * TAU / 20.0 - PI / 20.0
		for t in range(int(R_OUTER_BULL), int(R_D1)):
			img.set_pixel(int(BC.x + sin(a2) * t), int(BC.y - cos(a2) * t), Color(0.75, 0.75, 0.78))
	for rr in [R_OUTER_BULL, R_T0, R_T1, R_D0, R_D1]:
		for a3 in 400:
			var an := a3 * TAU / 400.0
			img.set_pixel(int(BC.x + cos(an) * rr), int(BC.y + sin(an) * rr), Color(0.75, 0.75, 0.78))
	return img


func _h(x: int, y: int, s: int = 0) -> float:
	var v := sin(float(x) * 12.9898 + float(y) * 78.233 + float(s) * 3.7) * 43758.5453
	return v - floor(v)


func _circ(img: Image, cx: float, cy: float, r: float, c: Color) -> void:
	for y in range(int(cy - r) - 1, int(cy + r) + 2):
		for x in range(int(cx - r) - 1, int(cx + r) + 2):
			if x >= 0 and y >= 0 and x < AW and y < AH and Vector2(x + 0.5 - cx, y + 0.5 - cy).length() <= r:
				img.set_pixel(x, y, c if c.a >= 0.999 else img.get_pixel(x, y).lerp(Color(c.r, c.g, c.b), c.a))
