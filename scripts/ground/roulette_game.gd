extends Control
## Package 62, part 2 (Luz): roulette in the Grand Centauria. A wheel of light with 37 pockets, the ball a point of
## light; the cloth beside it: the numbers, the dozens, the columns, the six outside bets. You pick a chip and click
## a field (a right click takes the bet off it). Others of the house's guests sit at the table and bet too, and one
## seat stays free for a co-op player: every seat's bets live here by its number, and every move (roulette_bet,
## roulette_clear, roulette_spin) goes through the command bus with the seat, so a second player's can come the same
## way. The high table of the lounge plays with larger chips. No class_name: preload it.

signal finished(won: bool)

const CD = preload("res://data/casino.gd")
const NEON := [Color(1.0, 0.36, 0.66), Color(0.3, 0.9, 1.0), Color(1.0, 0.82, 0.25), Color(0.55, 1.0, 0.6), Color(0.72, 0.5, 1.0), Color(1.0, 0.45, 0.25)]
const SEAT_COL := [Color(1.0, 0.85, 0.35), Color(0.3, 0.9, 1.0), Color(1.0, 0.4, 0.75), Color(0.55, 1.0, 0.6)]
const SPIN_TIME := 4.0

var high := false
var chips: Array = CD.CHIPS
var limit := CD.LIMIT
var chip := 5
var seats: Array = []                            # {name, bets: {key: Coins}, guest: bool, back: Coins of the last spin}
var state := "bet"                               # bet, spin, done
var number := -1
var hop_from := -1
var history: Array = []
var msg := "Pick a chip, click the cloth. A right click takes a bet back."
var last_bets: Dictionary = {}
var _t := 0.0
var _st := 0.0
var _rng := RandomNumberGenerator.new()
var _btns := {}


func setup(cfg: Dictionary) -> void:
	high = bool(cfg.get("hi", false))
	chips = CD.CHIPS_HIGH if high else CD.CHIPS
	limit = CD.LIMIT_HIGH if high else CD.LIMIT
	chip = int(chips[0]) if high else int(chips[1])
	_rng.seed = Time.get_ticks_usec()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	seats = [{"name": "You", "bets": {}, "guest": false, "back": 0}]
	for gname in cfg.get("guests", ["A guest in white", "A guest in violet"]):
		seats.append({"name": String(gname), "bets": {}, "guest": true, "back": 0})
	_guests_bet()


func _ready() -> void:
	var vs := get_viewport_rect().size
	var row := UI.hbox(10)
	row.position = Vector2(vs.x * 0.5 - 420, vs.y - 112)
	add_child(row)
	row.add_child(UI.label("Chip", 16, UI.GOLD))
	for c in chips:
		var cv: int = c
		var b := UI.button("%d" % cv, func(): set_chip(cv))
		b.custom_minimum_size = Vector2(84, 46)
		row.add_child(b)
		_btns[cv] = b
	for bt in [["clear", "Clear", func(): Commands.execute({"type": "roulette_clear", "seat": 0})], ["again", "Same again", func(): again()],
			["spin", "SPIN  (Space)", func(): spin()], ["out", "Leave  (Esc)", func(): leave()]]:
		var b2 := UI.button(String(bt[1]), bt[2])
		b2.custom_minimum_size = Vector2(190 if String(bt[0]) == "spin" else 130, 46)
		row.add_child(b2)
		_btns[String(bt[0])] = b2


func set_chip(c: int) -> void:
	if c in chips:
		chip = c
		Audio.play("ui_click", "roulette: chip")


func total(seat: int) -> int:
	var n := 0
	for k in seats[seat]["bets"]:
		n += int(seats[seat]["bets"][k])
	return n


## A seat puts `amount` Coins on a field (less than nothing: takes the bet off it). "" or why not.
func place(seat: int, key: String, amount: int) -> String:
	if state != "bet":
		return "No more bets."
	if seat < 0 or seat >= seats.size() or not CD.bet_ok(key):
		return "No such bet."
	var bets: Dictionary = seats[seat]["bets"]
	if amount <= 0:
		bets.erase(key)
		return ""
	if total(seat) + amount > limit:
		return "The table's limit is %d Coins a spin." % limit
	if seat == 0 and total(0) + amount > GameState.coins:
		return "Not enough Coins."
	bets[key] = int(bets.get(key, 0)) + amount
	return ""


func clear(seat: int) -> void:
	if state == "bet" and seat >= 0 and seat < seats.size():
		(seats[seat]["bets"] as Dictionary).clear()


func again() -> void:
	if state != "bet":
		return
	Commands.execute({"type": "roulette_clear", "seat": 0})
	for k in last_bets:
		Commands.execute({"type": "roulette_bet", "seat": 0, "key": String(k), "chip": int(last_bets[k])})


func spin() -> void:
	if state == "done":
		_new_round()
		return
	var e: String = Commands.execute({"type": "roulette_spin"})
	if e != "":
		msg = e
		Audio.play("ui_error", "roulette: refused")


func leave() -> void:
	if state != "spin":
		finished.emit(false)


## The command bus has turned the wheel: the ball runs to `n` (`from`: where it lay before it hopped on, or -1).
func spin_result(n: int, from: int, back: int) -> void:
	number = n
	hop_from = from
	state = "spin"
	_st = 0.0
	last_bets = (seats[0]["bets"] as Dictionary).duplicate()
	seats[0]["back"] = back
	for i in range(1, seats.size()):
		seats[i]["back"] = CD.settle(seats[i]["bets"], n)
	msg = "No more bets."
	Audio.play("card_shuffle", "roulette: the wheel")


func _guests_bet() -> void:
	for i in range(1, seats.size()):
		var bets: Dictionary = seats[i]["bets"]
		bets.clear()
		for k in 1 + _rng.randi() % 3:
			var key: String = ["red", "black", "even", "odd", "d%d" % (1 + _rng.randi() % 3), "c%d" % (1 + _rng.randi() % 3), "n%d" % (_rng.randi() % 37), "n%d" % (_rng.randi() % 37)][_rng.randi() % 8]
			bets[key] = int(bets.get(key, 0)) + int(chips[_rng.randi() % 2]) * (1 + _rng.randi() % 3)


func _new_round() -> void:
	state = "bet"
	for s in seats:
		(s["bets"] as Dictionary).clear()
		s["back"] = 0
	_guests_bet()
	msg = "Place your bets."


func _process(dt: float) -> void:
	_t += dt
	if state == "spin":
		_st += dt
		if _st >= SPIN_TIME:
			state = "done"
			_st = 0.0
			history.push_front(number)
			if history.size() > 12:
				history.pop_back()
			var staked := total(0)
			var back := int(seats[0]["back"])
			var call := "%d, %s." % [number, "green" if number == 0 else ("red" if CD.is_red(number) else "black")]
			if hop_from >= 0:
				call = "The ball hops on from %d: %s" % [hop_from, call]
			msg = call + ("  You get %d Coins back." % back if back > 0 else ("  The house takes %d Coins." % staked if staked > 0 else ""))
			Audio.play("arcade_coin" if back > staked else "ui_click", "roulette: the number")
	elif state == "done":
		_st += dt
	for c in chips:
		(_btns[c] as Button).modulate = Color(1.0, 0.85, 0.4) if int(c) == chip else Color.WHITE
	(_btns["spin"] as Button).text = "NEXT ROUND  (Space)" if state == "done" else "SPIN  (Space)"
	(_btns["spin"] as Button).disabled = state == "spin" or (state == "bet" and total(0) == 0)
	(_btns["clear"] as Button).disabled = state != "bet"
	(_btns["again"] as Button).disabled = state != "bet" or last_bets.is_empty()
	(_btns["out"] as Button).disabled = state == "spin"
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_back", false, true):
		get_viewport().set_input_as_handled()
		leave()
	elif event is InputEventKey and event.pressed and not event.echo:
		var kc := (event as InputEventKey).keycode
		if kc == KEY_SPACE or kc == KEY_ENTER:
			get_viewport().set_input_as_handled()
			spin()
		elif kc >= KEY_1 and kc < KEY_1 + chips.size():
			set_chip(int(chips[kc - KEY_1]))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and state == "bet":
		var mb := event as InputEventMouseButton
		var fr := fields()
		for k in fr:
			if (fr[k] as Rect2).has_point(mb.position):
				var e: String = Commands.execute({"type": "roulette_bet", "seat": 0, "key": String(k), "chip": chip if mb.button_index == MOUSE_BUTTON_LEFT else -1})
				msg = e if e != "" else "%d Coins on the cloth." % total(0)
				Audio.play("ui_error" if e != "" else "ui_click", "roulette: bet")
				accept_event()
				return


## Package 80: with the controller ✕ spins, □ clears, △ the same again, ◯ leaves (the cloth itself needs the mouse).
func pad_button(b: String, pressed: bool) -> bool:
	if not pressed:
		return true
	match b:
		"cross":
			spin()
		"square":
			Commands.execute({"type": "roulette_clear", "seat": 0})
		"triangle":
			again()
		"circle":
			leave()
	return true


## The cloth's fields: key -> its rect on the screen.
func fields() -> Dictionary:
	var vs := get_viewport_rect().size
	var o := Vector2(vs.x * 0.5 - 60.0, 210.0)
	var cw := 62.0
	var ch := 66.0
	var out := {"n0": Rect2(o.x, o.y, cw, ch * 3.0)}
	for c in 12:
		for r in 3:
			out["n%d" % (c * 3 + 3 - r)] = Rect2(o.x + cw * (c + 1), o.y + ch * r, cw, ch)
	for r2 in 3:
		out["c%d" % (3 - r2)] = Rect2(o.x + cw * 13.0, o.y + ch * r2, cw * 1.2, ch)
	for d in 3:
		out["d%d" % (d + 1)] = Rect2(o.x + cw * (1 + d * 4), o.y + ch * 3.0, cw * 4.0, ch * 0.8)
	for q in CD.OUTSIDE.size():
		out[String(CD.OUTSIDE[q][0])] = Rect2(o.x + cw * (1 + q * 2), o.y + ch * 3.8, cw * 2.0, ch * 0.8)
	return out


func _num_col(n: int) -> Color:
	return Color(0.1, 0.75, 0.45) if n == 0 else (Color(0.9, 0.16, 0.3) if CD.is_red(n) else Color(0.1, 0.1, 0.16))


func _draw() -> void:
	var vs := get_viewport_rect().size
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, vs), Color(0.03, 0.02, 0.07, 0.95))
	draw_string(font, Vector2(40.0, 70.0), "HIGH-STAKES ROULETTE" if high else "ROULETTE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 40, Color(1.0, 0.5, 0.8).lerp(Color(0.3, 0.9, 1.0), 0.5 + 0.5 * sin(_t * 1.5)))
	draw_string(font, Vector2(40.0, 104.0), "The limit: %d Coins a spin   ·   you hold %d Coins   ·   on the cloth %d" % [limit, GameState.coins, total(0)], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17, Color(1.0, 0.85, 0.4))
	# ---- the wheel: a ring of light, the pockets in it, the ball a point running round
	var wc := Vector2(vs.x * 0.24, vs.y * 0.47)
	var R := minf(250.0, vs.y * 0.27)
	var spin_k := clampf(_st / SPIN_TIME, 0.0, 1.0) if state == "spin" else 1.0
	var wa := _t * 0.35
	for g in 5:
		draw_arc(wc, R + 16.0 + g * 8.0, 0.0, TAU, 72, Color(NEON[(g + int(_t * 2.0)) % NEON.size()], 0.95 - g * 0.17), 4.0)
	var cl := fields()
	var cr := (cl["n0"] as Rect2).merge(cl["c1"]).merge(cl["high"]).grow(12.0)
	for g2 in 3:
		draw_rect(cr.grow(g2 * 5.0), Color(NEON[(g2 + int(_t * 1.5)) % NEON.size()], 0.85 - g2 * 0.25), false, 3.0)
	draw_circle(wc, R + 10.0, Color(0.05, 0.04, 0.1))
	var n := CD.WHEEL.size()
	for i in n:
		var a0 := wa + i * TAU / n
		var num: int = CD.WHEEL[i]
		var lit := state == "done" and num == number
		draw_arc(wc, R * 0.82, a0, a0 + TAU / n - 0.012, 4, _num_col(num).lightened(0.35 if lit else 0.0), R * 0.3)
		var lp := wc + Vector2.from_angle(a0 + TAU / n * 0.5) * R * 0.86
		draw_string(font, lp + Vector2(-12.0, 6.0), "%d" % num, HORIZONTAL_ALIGNMENT_CENTER, 24.0, 15, Color(1, 1, 1, 0.95))
	draw_arc(wc, R * 0.97, 0.0, TAU, 72, Color(1.0, 0.82, 0.35), 3.0)
	draw_arc(wc, R * 0.66, 0.0, TAU, 72, Color(1.0, 0.82, 0.35), 2.0)
	draw_circle(wc, R * 0.64, Color(0.07, 0.05, 0.14))
	for sp in 8:
		draw_line(wc, wc + Vector2.from_angle(-wa * 1.3 + sp * TAU / 8.0) * R * 0.6, Color(NEON[sp % NEON.size()], 0.45), 3.0)
	draw_circle(wc, R * 0.2, Color(1.0, 0.82, 0.35))
	if state != "bet":
		var idx := CD.WHEEL.find(number)
		var pa := wa + (idx + 0.5) * TAU / n
		var ba := pa - 16.0 * (1.0 - spin_k) * (1.0 - spin_k)
		var br := lerpf(R * 1.02, R * 0.74, spin_k * spin_k * spin_k)
		if hop_from >= 0 and spin_k < 0.93 and spin_k > 0.8:
			ba -= TAU / n * (1.0 - (spin_k - 0.8) / 0.13)
		var bp := wc + Vector2.from_angle(ba) * br
		draw_circle(bp, 16.0, Color(1, 1, 1, 0.18))
		draw_circle(bp, 8.0, Color(1.0, 1.0, 0.9))
	if state == "done":
		draw_circle(wc, R * 0.44, _num_col(number))
		draw_arc(wc, R * 0.44, 0.0, TAU, 48, Color(1.0, 0.85, 0.4, 0.6 + 0.4 * absf(sin(_t * 6.0))), 5.0)
		draw_string(font, wc + Vector2(-R * 0.44, R * 0.16), "%d" % number, HORIZONTAL_ALIGNMENT_CENTER, R * 0.88, int(R * 0.42), Color(1, 1, 1))
	# ---- the cloth
	var fr := fields()
	var mp := get_local_mouse_position()
	for k in fr:
		var r: Rect2 = fr[k]
		var key := String(k)
		var c := Color(0.08, 0.06, 0.16)
		var label := key
		if key.begins_with("n"):
			c = _num_col(int(key.substr(1)))
			label = key.substr(1)
		elif key == "red":
			c = Color(0.9, 0.16, 0.3)
			label = "Red"
		elif key == "black":
			c = Color(0.1, 0.1, 0.16)
			label = "Black"
		elif key.begins_with("d"):
			label = ["1 to 12", "13 to 24", "25 to 36"][int(key.substr(1)) - 1]
		elif key.begins_with("c"):
			label = "2 to 1"
		else:
			for o2 in CD.OUTSIDE:
				if String(o2[0]) == key:
					label = String(o2[1])
		var won := state == "done" and CD.bet_pays(key, number) > 0
		draw_rect(r.grow(-2.0), c.lightened(0.3) if won else c)
		draw_rect(r.grow(-2.0), Color(1.0, 0.85, 0.4) if won else (Color(0.3, 0.9, 1.0) if state == "bet" and r.has_point(mp) else Color(0.72, 0.5, 1.0, 0.6)), false, 3.0 if won else 2.0)
		draw_string(font, Vector2(r.position.x, r.get_center().y + 7.0), label, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 20 if key.begins_with("n") else 16, Color(1, 1, 1))
		for s in seats.size():                                   # the chips on it, every seat's in its own colour
			var amt := int((seats[s]["bets"] as Dictionary).get(key, 0))
			if amt > 0:
				var cp := r.position + Vector2(16.0 + s * 15.0, r.size.y - 15.0) if key.begins_with("n") else Vector2(r.end.x - 16.0 - s * 15.0, r.position.y + 15.0)
				draw_circle(cp, 13.0, Color(0.03, 0.02, 0.06))
				draw_circle(cp, 11.0, SEAT_COL[s % SEAT_COL.size()])
				draw_string(font, cp + Vector2(-12.0, 4.0), "%d" % amt, HORIZONTAL_ALIGNMENT_CENTER, 24.0, 10 if amt >= 100 else 12, Color(0.05, 0.04, 0.1))
	# ---- who sits at the table, the last numbers, the croupier's word
	var sy := 560.0
	var sx := vs.x * 0.5 - 60.0
	for s2 in seats.size() + 1:
		var free := s2 >= seats.size()
		var sr := Rect2(sx + s2 * 215.0, sy, 205.0, 62.0)
		draw_rect(sr, Color(0.06, 0.05, 0.12))
		draw_rect(sr, Color(SEAT_COL[s2 % SEAT_COL.size()], 0.35 if free else 0.9), false, 2.0)
		if free:
			draw_string(font, Vector2(sr.position.x + 10.0, sr.position.y + 26.0), "A free seat", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color(0.6, 0.65, 0.78))
			draw_string(font, Vector2(sr.position.x + 10.0, sr.position.y + 48.0), "for a co-op player (later)", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color(0.5, 0.54, 0.66))
		else:
			draw_string(font, Vector2(sr.position.x + 10.0, sr.position.y + 26.0), String(seats[s2]["name"]), HORIZONTAL_ALIGNMENT_LEFT, 190.0, 15, SEAT_COL[s2 % SEAT_COL.size()])
			var tb := total(s2)
			var bk := int(seats[s2]["back"])
			draw_string(font, Vector2(sr.position.x + 10.0, sr.position.y + 48.0), ("back %d of %d" % [bk, tb]) if state == "done" else "on the cloth %d" % tb, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13,
				Color(0.5, 1.0, 0.6) if state == "done" and bk > tb else Color(0.85, 0.9, 1.0))
	draw_string(font, Vector2(sx, sy + 96.0), "The last numbers", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color(0.62, 0.66, 0.78))
	for h in history.size():
		var hc := Vector2(sx + 150.0 + h * 44.0, sy + 91.0)
		draw_circle(hc, 18.0, _num_col(int(history[h])))
		draw_arc(hc, 18.0, 0.0, TAU, 24, Color(1.0, 0.85, 0.4, 0.9 if h == 0 else 0.3), 2.0)
		draw_string(font, hc + Vector2(-18.0, 6.0), "%d" % int(history[h]), HORIZONTAL_ALIGNMENT_CENTER, 36.0, 15, Color(1, 1, 1))
	draw_string(font, Vector2(sx, sy + 150.0), msg, HORIZONTAL_ALIGNMENT_LEFT, vs.x - sx - 30.0, 19, Color(1.0, 0.95, 0.6))
