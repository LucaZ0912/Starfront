extends Control
## Package 62, part 3 (Luz): poker in the Grand Centauria: Hold'em without a limit. You buy in for Coins and sit
## with three of the house's guests, each with a name, a way of playing and a strength; now and then somebody you
## know sits there. Two cards each, five on the table, four rounds of betting, side pots when a seat is all in. The
## house takes five per cent of a pot that has seen the flop. You may stand up between the hands (or once you have
## folded) and take your chips along. A kind hand (Dexterity, the perk Lucky Hand) lets you read a tell of one of
## the guests now and then; the cards are never touched. One seat stays free for a co-op player: every seat's
## cards and chips live here by its number, and every move (poker_sit, poker_move, poker_next, poker_leave) goes
## through the command bus with the seat. No class_name: preload it.

signal finished(won: bool)

const CD = preload("res://data/casino.gd")
const Cards = preload("res://scripts/ground/casino_cards.gd")
const NEON := [Color(1.0, 0.36, 0.66), Color(0.3, 0.9, 1.0), Color(1.0, 0.82, 0.25), Color(0.55, 1.0, 0.6), Color(0.72, 0.5, 1.0), Color(1.0, 0.45, 0.25)]
const SEAT_COL := [Color(1.0, 0.85, 0.35), Color(0.3, 0.9, 1.0), Color(1.0, 0.4, 0.75), Color(0.55, 1.0, 0.6)]
const SEAT_AT := [Vector2(0.0, 1.0), Vector2(-1.0, 0.0), Vector2(0.0, -1.0), Vector2(1.0, 0.0)]      # round the table: you, left, top, right
const THINK := 0.9                              # seconds a guest takes
const MAX_RAISES := 3                           # a guest raises no more often in one round of betting

var high := false
var buyins: Array = CD.POKER_BUYINS
var level := 0                                  # the buy-in of this sitting (0: not sat down yet)
var bb := 2
var sb := 1
var seats: Array = []                           # {name, job, style, stars, who, line, guest, stack, hole, bet, total, folded, allin, acted, last, won, value}
var board: Array = []
var deck: Array = []
var button := 0
var street := -1                                # -1 no hand, 0 before the flop, 1 flop, 2 turn, 3 river, 4 the showdown
var state := "buy"                              # buy, hand, show
var turn := -1
var cur_bet := 0
var min_raise := 0
var raises := 0
var rake := 0                                   # what the house took of the last pot
var hands := 0
var paid := 0                                   # Coins you have bought in for in this sitting
var met: Array = []                             # the story's people you have played a hand with here
var tell_seat := -1
var tell := ""
var shown := false                              # the last hand went to a showdown
var msg := "Buy in and take your seat."
var fast := false                               # (the smoke test) nobody thinks long
var _t := 0.0
var _st := 0.0
var _rng := RandomNumberGenerator.new()
var _btns := {}
var _buy_row: HBoxContainer
var _slider: HSlider


func is_poker() -> bool:
	return true


func setup(cfg: Dictionary) -> void:
	high = bool(cfg.get("hi", false))
	buyins = CD.POKER_BUYINS_HIGH if high else CD.POKER_BUYINS
	_rng.seed = Time.get_ticks_usec()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	seats = [_seat({"name": "You", "job": "", "style": "", "stars": 0, "who": "", "line": ""}, false)]
	var gs: Array = cfg.get("guests", [])
	while gs.size() < 3:
		gs.append(CD.poker_guest(_rng, high))
	for g in gs.slice(0, 3):
		seats.append(_seat(g, true))


func _seat(g: Dictionary, guest: bool) -> Dictionary:
	return {"name": String(g["name"]), "job": String(g.get("job", "")), "style": String(g.get("style", "careful")), "stars": int(g.get("stars", 3)),
		"who": String(g.get("who", "")), "line": String(g.get("line", "")), "guest": guest, "stack": 0, "hole": [], "bet": 0, "total": 0,
		"folded": true, "allin": false, "acted": false, "last": "", "won": 0, "value": 0}


func _ready() -> void:
	var vs := get_viewport_rect().size
	_buy_row = UI.hbox(12)
	_buy_row.position = Vector2(vs.x * 0.5 - 90.0 * buyins.size() - 100.0, vs.y * 0.44 - 26.0)
	add_child(_buy_row)
	_buy_row.add_child(UI.label("Buy in for", 18, UI.GOLD))
	for bi in buyins:
		var bv: int = bi
		var b := UI.button("%d Coins" % bv, func(): buy(bv))
		b.custom_minimum_size = Vector2(170, 52)
		_buy_row.add_child(b)
		_btns["buy_%d" % bv] = b
	var row := UI.hbox(8)
	row.position = Vector2(vs.x * 0.5 - 640, vs.y - 78)
	add_child(row)
	for bt in [["fold", "Fold  (F)", func(): you("fold")], ["call", "Check  (C)", func(): you("call")], ["raise", "Raise  (R)", func(): you("raise")]]:
		var b2 := UI.button(String(bt[1]), bt[2])
		b2.custom_minimum_size = Vector2(190, 46)
		row.add_child(b2)
		_btns[String(bt[0])] = b2
	_slider = HSlider.new()
	_slider.custom_minimum_size = Vector2(240, 46)
	_slider.focus_mode = Control.FOCUS_NONE
	row.add_child(_slider)
	for bt2 in [["allin", "All in  (A)", func(): you("allin")], ["next", "NEXT HAND  (Space)", func(): next()], ["out", "Stand up  (Esc)", func(): leave()]]:
		var b3 := UI.button(String(bt2[1]), bt2[2])
		b3.custom_minimum_size = Vector2(200 if String(bt2[0]) == "next" else 150, 46)
		row.add_child(b3)
		_btns[String(bt2[0])] = b3


func pot() -> int:
	var n := 0
	for s in seats:
		n += int(s["total"])
	return n


func buy(amount: int) -> void:
	var e: String = Commands.execute({"type": "poker_sit", "seat": 0, "buyin": amount})
	if e != "":
		msg = e
		Audio.play("ui_error", "poker: refused")


## You buy in (or buy in again once your chips are gone): the Coins go, the chips lie before you. The first buy-in
## sets the table's blinds and what the guests have before them.
func sit(seat: int, amount: int) -> String:
	if state != "buy" or seat != 0:
		return "You sit already."
	if not amount in buyins or (level > 0 and amount != level):
		return "The table takes %s Coins." % (str(level) if level > 0 else " or ".join(buyins.map(func(b): return str(b))))
	if GameState.coins < amount:
		return "Not enough Coins. The cashier is in the lobby."
	GameState.coins -= amount
	paid += amount
	seats[0]["stack"] = int(seats[0]["stack"]) + amount
	if level == 0:
		level = amount
		bb = maxi(2, amount / CD.POKER_BLINDS)
		sb = bb / 2
		for i in range(1, seats.size()):
			seats[i]["stack"] = _guest_stack()
		button = _rng.randi() % seats.size()
	Audio.play("arcade_coin", "poker: buy in")
	_new_hand()
	return ""


func _guest_stack() -> int:
	return int(level * _rng.randf_range(0.7, 1.6) / bb) * bb


func _new_hand() -> void:
	for i in range(1, seats.size()):                # a guest without chips makes room for the next
		if int(seats[i]["stack"]) < bb:
			var was := String(seats[i]["name"])
			seats[i] = _seat(CD.poker_guest(_rng, high), true)
			seats[i]["stack"] = _guest_stack()
			GameState.log_msg("%s leaves the poker table. %s takes the seat." % [was, String(seats[i]["name"])], GameState.COL_INFO)
	deck = CD.new_deck(GameState.casino_rng())
	board = []
	rake = 0
	shown = false
	for s in seats:
		s["hole"] = [deck.pop_back(), deck.pop_back()]
		s["bet"] = 0
		s["total"] = 0
		s["folded"] = false
		s["allin"] = false
		s["acted"] = false
		s["last"] = ""
		s["won"] = 0
		s["value"] = 0
		if String(s["who"]) != "" and not String(s["who"]) in met:
			met.append(String(s["who"]))
	button = (button + 1) % seats.size()
	street = 0
	state = "hand"
	cur_bet = 0
	min_raise = bb
	raises = 0
	_put((button + 1) % seats.size(), sb)
	seats[(button + 1) % seats.size()]["last"] = "small blind"
	_put((button + 2) % seats.size(), bb)
	seats[(button + 2) % seats.size()]["last"] = "big blind"
	cur_bet = bb
	turn = (button + 2) % seats.size()
	tell_seat = -1
	tell = ""
	if _rng.randf() < CD.tell_luck(GameState.pilot_attr("dexterity"), GameState.has_perk(CD.PERK)):
		tell_seat = 1 + _rng.randi() % (seats.size() - 1)
	_tell_update()
	msg = "A new hand. The blinds are %d and %d." % [sb, bb]
	Audio.play("card_shuffle", "poker: deal")
	_next_turn()


func _put(i: int, amount: int) -> int:
	var s: Dictionary = seats[i]
	var n := mini(amount, int(s["stack"]))
	s["stack"] = int(s["stack"]) - n
	s["bet"] = int(s["bet"]) + n
	s["total"] = int(s["total"]) + n
	if int(s["stack"]) == 0:
		s["allin"] = true
	return n


func to_call(i: int) -> int:
	return maxi(0, cur_bet - int(seats[i]["bet"]))


## The least a raise must go to, and all a seat can put in this round.
func min_to(i: int) -> int:
	return mini(cur_bet + min_raise, top(i))


func top(i: int) -> int:
	return int(seats[i]["bet"]) + int(seats[i]["stack"])


## A seat's move in its turn: "fold", "call" (or check when nothing is to pay), "raise" to `to` Coins in this
## round, "allin". "" or why not.
func move(seat: int, what: String, to: int = 0) -> String:
	if state != "hand" or seat != turn:
		return "It is not that seat's turn."
	var s: Dictionary = seats[seat]
	var owe := to_call(seat)
	match what:
		"fold":
			s["folded"] = true
			s["last"] = "folds"
		"call":
			var n := _put(seat, owe)
			s["last"] = "checks" if owe == 0 else ("all in for %d" % n if bool(s["allin"]) else "calls %d" % n)
		"raise", "allin":
			if what == "allin":
				to = top(seat)
			to = mini(to, top(seat))
			if to <= cur_bet:                        # (not enough to raise: that is a call)
				return move(seat, "call")
			if to < cur_bet + min_raise and to < top(seat):
				return "A raise must go to %d at least." % (cur_bet + min_raise)
			_put(seat, to - int(s["bet"]))
			min_raise = maxi(min_raise, to - cur_bet)
			var opened := cur_bet == 0
			cur_bet = to
			raises += 1
			for o in seats:
				o["acted"] = false
			s["last"] = "all in for %d" % to if bool(s["allin"]) else ("bets %d" % to if opened else "raises to %d" % to)
		_:
			return "No such move."
	s["acted"] = true
	Audio.play("card_play" if what != "fold" else "ui_click", "poker: move")
	if seat != 0:
		msg = "%s %s." % [String(s["name"]), String(s["last"])]
	_next_turn(seat)
	return ""


func _alive() -> Array:
	var out: Array = []
	for i in seats.size():
		if not bool(seats[i]["folded"]):
			out.append(i)
	return out


## Who is next: from the seat after `from` round the table, the first that is still in, has chips, and has not
## answered the bet yet. Nobody: the round of betting is over.
func _next_turn(from: int = -1) -> void:
	_st = 0.0
	if _alive().size() <= 1:
		_finish()
		return
	var start := (turn if from < 0 else from) + 1
	for k in seats.size():
		var i := (start + k) % seats.size()
		var s: Dictionary = seats[i]
		if not bool(s["folded"]) and not bool(s["allin"]) and (not bool(s["acted"]) or int(s["bet"]) < cur_bet):
			turn = i
			_set_slider()
			return
	_end_street()


func _end_street() -> void:
	for s in seats:
		s["bet"] = 0
		s["acted"] = false
		if not bool(s["folded"]) and not bool(s["allin"]):
			s["last"] = ""
	cur_bet = 0
	min_raise = bb
	raises = 0
	turn = -1
	_st = 0.0
	if street >= 3:
		_finish()
		return
	street += 1
	for k in (3 if street == 1 else 1):
		board.append(deck.pop_back())
	Audio.play("card_play", "poker: the board")
	msg = ["", "The flop.", "The turn.", "The river."][street]
	_tell_update()
	var can: Array = _alive().filter(func(i): return not bool(seats[i]["allin"]))
	if can.size() <= 1:                            # nobody left to bet against: the rest of the board comes by itself
		return
	turn = button
	_next_turn(button)


## The hand is over: the pots go to the best hands (or to the one seat still in), the house takes its share.
func _finish() -> void:
	var alive := _alive()
	shown = alive.size() > 1
	if shown:
		while board.size() < 5:
			board.append(deck.pop_back())
		for i in alive:
			seats[i]["value"] = CD.hand_value((seats[i]["hole"] as Array) + board)
	street = 4
	state = "show"
	turn = -1
	var pots: Array = CD.poker_pots(seats.map(func(s): return int(s["total"])), seats.map(func(s): return bool(s["folded"])), seats.map(func(s): return int(s["value"])))
	var uncalled := 0                              # (a bet nobody answered is no pot: it goes back, the house takes nothing of it)
	if pots.size() >= 2 and (pots[pots.size() - 1]["winners"] as Array).size() == 1:
		var lastp: Dictionary = pots[pots.size() - 1]
		var tops: Array = seats.filter(func(s): return not bool(s["folded"]) and int(s["total"]) == seats.map(func(q): return 0 if bool(q["folded"]) else int(q["total"])).max())
		if tops.size() == 1:
			uncalled = int(lastp["amount"])
			seats[int(lastp["winners"][0])]["stack"] = int(seats[int(lastp["winners"][0])]["stack"]) + uncalled
			pots.pop_back()
	rake = 0
	if board.size() >= 3 and not pots.is_empty():
		var live := 0
		for lp in pots:
			live += int(lp["amount"])
		rake = mini(mini(CD.RAKE_CAP_HIGH if high else CD.RAKE_CAP, int(live * CD.RAKE)), int(pots[0]["amount"]) - 1)
		rake = maxi(0, rake)
		pots[0]["amount"] = int(pots[0]["amount"]) - rake
	for p in pots:
		var w: Array = p["winners"]
		var share := int(p["amount"]) / w.size()
		var left := int(p["amount"]) - share * w.size()
		for i2 in w:
			seats[i2]["won"] = int(seats[i2]["won"]) + share
		seats[int(w[0])]["won"] = int(seats[int(w[0])]["won"]) + left
	var names: Array = []
	for s in seats:
		s["stack"] = int(s["stack"]) + int(s["won"])
		if int(s["won"]) > 0:
			names.append("%s (%d)" % ["You" if not bool(s["guest"]) else String(s["name"]), int(s["won"])])
	hands += 1
	var best := ""
	if shown:
		var top_i := int(alive[0])
		for i3 in alive:
			if int(seats[i3]["value"]) > int(seats[top_i]["value"]):
				top_i = i3
		best = "%s. " % CD.hand_name(int(seats[top_i]["value"]))
	msg = "%sThe pot goes to %s.%s" % [best, " and ".join(names), "  The house takes %d." % rake if rake > 0 else ""]
	Audio.play("arcade_coin" if int(seats[0]["won"]) > int(seats[0]["total"]) else "ui_click", "poker: the pot")


## On to the next hand (you, or the table for you): out of chips you buy in again or stand up.
func next() -> String:
	if state != "show":
		return "The hand is still played."
	if int(seats[0]["stack"]) < 1:
		state = "buy"
		street = -1
		msg = "Your chips are gone. Buy in again for %d Coins, or stand up." % level
		return ""
	_new_hand()
	return ""


## You stand up: your chips go back into your pocket as Coins. Not while you hold cards in a hand.
func stand_up() -> String:
	if state == "hand" and not bool(seats[0]["folded"]):
		return "Play the hand out first, or fold."
	var back := int(seats[0]["stack"])
	seats[0]["stack"] = 0
	GameState.coins += back
	if paid > 0:
		GameState.casino_book(paid, back)
		GameState.log_msg("You stand up from the poker table with %d Coins (bought in for %d)." % [back, paid], GameState.COL_GOOD if back >= paid else GameState.COL_INFO)
	if hands > 0:
		var Acq = load("res://data/acquaintances.gd")
		for who in met:
			Acq.played_with(String(who))
	finished.emit(back > paid)
	return ""


func leave() -> void:
	var e: String = Commands.execute({"type": "poker_leave", "seat": 0})
	if e != "":
		msg = e
		Audio.play("ui_error", "poker: refused")


func you(what: String) -> void:
	if state != "hand" or turn != 0:
		return
	var e: String = Commands.execute({"type": "poker_move", "seat": 0, "move": what, "to": int(_slider.value) if _slider != null else min_to(0)})
	if e != "":
		msg = e
		Audio.play("ui_error", "poker: refused")


func _set_slider() -> void:
	if _slider == null or turn != 0:
		return
	_slider.min_value = min_to(0)
	_slider.max_value = maxi(min_to(0), top(0))
	_slider.step = maxi(1, sb)
	_slider.value = clampi(cur_bet + maxi(min_raise, pot() / 2 / bb * bb), min_to(0), top(0))


func _tell_update() -> void:
	tell = ""
	if tell_seat > 0 and not bool(seats[tell_seat]["folded"]):
		tell = CD.tell_text(CD.poker_equity(seats[tell_seat]["hole"], board, _rng, 80))


func _guest_move() -> void:
	var s: Dictionary = seats[turn]
	var hs: float = CD.poker_equity(s["hole"], board, _rng, 60)
	var d: Dictionary = CD.poker_ai(_rng, hs, String(s["style"]), int(s["stars"]), _alive().size() - 1, to_call(turn), pot(), int(s["bet"]), min_to(turn), top(turn), bb, raises < MAX_RAISES)
	var e := move(turn, String(d["move"]), int(d["to"]))
	if e != "":
		move(turn, "call" if to_call(turn) == 0 else "fold")


func _process(dt: float) -> void:
	_t += dt
	if state == "hand":
		_st += dt
		var wait := 0.0 if fast else (0.35 if bool(seats[0]["folded"]) else THINK)
		if turn > 0 and _st >= wait:
			_st = 0.0
			_guest_move()
		elif turn < 0 and _st >= wait:               # (all in: the board runs out)
			_end_street()
	if _buy_row != null:
		_buy_row.visible = state == "buy"
		for bi in buyins:
			(_btns["buy_%d" % int(bi)] as Button).disabled = GameState.coins < int(bi) or (level > 0 and int(bi) != level)
		var mine := state == "hand" and turn == 0
		var owe := to_call(0) if mine else 0
		(_btns["fold"] as Button).disabled = not mine
		(_btns["call"] as Button).disabled = not mine
		(_btns["call"] as Button).text = "Check  (C)" if owe == 0 else "Call %d  (C)" % mini(owe, int(seats[0]["stack"]))
		var may := mine and top(0) > cur_bet
		(_btns["raise"] as Button).disabled = not may
		(_btns["raise"] as Button).text = ("Bet %d  (R)" if cur_bet == 0 else "Raise to %d  (R)") % int(_slider.value) if may else "Raise  (R)"
		_slider.editable = may
		(_btns["allin"] as Button).disabled = not mine
		(_btns["next"] as Button).disabled = state != "show"
		(_btns["out"] as Button).disabled = state == "hand" and not bool(seats[0]["folded"])
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_back", false, true):
		get_viewport().set_input_as_handled()
		leave()
	elif event is InputEventKey and event.pressed and not event.echo:
		var kc := (event as InputEventKey).keycode
		var used := true
		match kc:
			KEY_SPACE, KEY_ENTER:
				if state == "show":
					Commands.execute({"type": "poker_next"})
				elif state == "hand":
					you("call")
			KEY_F:
				you("fold")
			KEY_C:
				you("call")
			KEY_R:
				you("raise")
			KEY_A:
				you("allin")
			KEY_LEFT, KEY_RIGHT:
				if _slider != null:
					_slider.value += _slider.step * (1 if kc == KEY_RIGHT else -1)
			_:
				used = false
		if used:
			get_viewport().set_input_as_handled()


## Package 80: with the controller ✕ checks or calls (and goes on to the next hand), □ folds, △ raises to what the
## slider shows (left and right move it), ◯ stands up.
func pad_button(b: String, pressed: bool) -> bool:
	if not pressed:
		return true
	match b:
		"cross":
			if state == "show":
				Commands.execute({"type": "poker_next"})
			elif state == "buy":
				buy(level if level > 0 else int(buyins[0]))
			else:
				you("call")
		"square":
			you("fold")
		"triangle":
			you("raise")
		"left", "right":
			if _slider != null:
				_slider.value += _slider.step * (1 if b == "right" else -1)
		"circle":
			leave()
	return true


func _seat_pos(i: int) -> Vector2:
	var vs := get_viewport_rect().size
	var d: Vector2 = SEAT_AT[i % SEAT_AT.size()]
	return Vector2(vs.x * 0.5, vs.y * 0.44) + Vector2(d.x * vs.x * 0.36, d.y * vs.y * (0.33 if d.y > 0.0 else 0.27))


func _draw() -> void:
	var vs := get_viewport_rect().size
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, vs), Color(0.03, 0.02, 0.07, 0.98))
	var tc := Vector2(vs.x * 0.5, vs.y * 0.44)
	# ---- the table: an oval of cloth, rings of neon round it
	draw_set_transform(tc, 0.0, Vector2(1.0, 0.5))
	var tr := vs.x * 0.3
	draw_circle(Vector2.ZERO, tr + 22.0, Color(0.1, 0.05, 0.16))
	draw_circle(Vector2.ZERO, tr, Color(0.05, 0.16, 0.3))
	draw_circle(Vector2.ZERO, tr - 30.0, Color(0.06, 0.2, 0.36))
	for g in 4:
		draw_arc(Vector2.ZERO, tr + 26.0 + g * 9.0, 0.0, TAU, 96, Color(NEON[(g + int(_t * 2.0)) % NEON.size()], 0.95 - g * 0.2), 4.0)
	draw_arc(Vector2.ZERO, tr * 0.62, 0.0, TAU, 72, Color(0.3, 0.9, 1.0, 0.3), 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_string(font, Vector2(40.0, 70.0), "HIGH-STAKES POKER" if high else "POKER", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 40, Color(1.0, 0.5, 0.8).lerp(Color(0.3, 0.9, 1.0), 0.5 + 0.5 * sin(_t * 1.5)))
	var info := "Hold'em, no limit   ·   you hold %d Coins" % GameState.coins
	if level > 0:
		info += "   ·   the blinds: %d and %d   ·   the house takes 5 per cent of a pot that has seen the flop (at most %d)" % [sb, bb, CD.RAKE_CAP_HIGH if high else CD.RAKE_CAP]
	draw_string(font, Vector2(40.0, 104.0), info, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17, Color(1.0, 0.85, 0.4))
	# ---- the board and the pot
	var sz: Vector2 = Cards.SIZE
	if state != "buy":
		for k in 5:
			var p := Vector2(tc.x - (sz.x * 5.0 + 48.0) * 0.5 + k * (sz.x + 12.0), tc.y - sz.y * 0.5 + 6.0)
			if k < board.size():
				Cards.face(self, p, sz, board[k])
			else:
				draw_rect(Rect2(p, sz), Color(0.3, 0.9, 1.0, 0.18), false, 2.0)
		draw_string(font, Vector2(tc.x - 300.0, tc.y - sz.y * 0.5 - 16.0), "The pot: %d" % (pot() - rake if state == "show" else pot()), HORIZONTAL_ALIGNMENT_CENTER, 600.0, 24, Color(1.0, 0.85, 0.4))
	# ---- the seats
	for i in seats.size():
		var s: Dictionary = seats[i]
		var at := _seat_pos(i)
		var col: Color = SEAT_COL[i % SEAT_COL.size()]
		var mine := state == "hand" and turn == i
		var out := state != "buy" and bool(s["folded"])
		var big := i == 0
		var csz := sz if big else sz * 0.8
		var plate := Rect2(at.x - 150.0, at.y + (csz.y * 0.5 + 8.0 if big else csz.y * 0.5 + 6.0), 300.0, 74.0)
		if i == 2 or i == 0:
			plate.position = Vector2(at.x + csz.x + 30.0, at.y - 37.0)
		# the two cards
		if state != "buy" and not (s["hole"] as Array).is_empty():
			for k2 in 2:
				var cp := Vector2(at.x - csz.x - 4.0 + k2 * (csz.x + 8.0), at.y - csz.y * 0.5)
				if i == 0 or (state == "show" and shown and not out):
					Cards.face(self, cp, csz, s["hole"][k2], Color(col, 0.9) if state == "show" and int(s["won"]) > 0 else Color(0, 0, 0, 0), out)
				else:
					Cards.back(self, cp, csz, out)
		draw_rect(plate, Color(0.06, 0.05, 0.12))
		draw_rect(plate, Color(col, 0.35 if out else 0.9), false, 4.0 if mine else 2.0)
		if mine:
			draw_rect(plate.grow(5.0), Color(col, 0.4 + 0.4 * absf(sin(_t * 4.0))), false, 2.0)
		var nm := String(s["name"])
		if bool(s["guest"]):
			nm += "  " + "●".repeat(int(s["stars"]))
		draw_string(font, plate.position + Vector2(12.0, 24.0), nm, HORIZONTAL_ALIGNMENT_LEFT, 276.0, 16, Color(1.0, 0.82, 0.3) if String(s["who"]) != "" else col)
		var sub := "chips %d" % int(s["stack"])
		if bool(s["guest"]):
			sub += "   ·   %s, %s" % [String(s["job"]), String(CD.STYLES.get(String(s["style"]), {}).get("name", ""))]
		draw_string(font, plate.position + Vector2(12.0, 45.0), sub, HORIZONTAL_ALIGNMENT_LEFT, 276.0, 13, Color(0.85, 0.9, 1.0))
		var line := String(s["last"])
		var lc := Color(0.62, 0.66, 0.78)
		if state == "show" and int(s["won"]) > 0:
			line = "takes %d%s" % [int(s["won"]), ("  ·  " + CD.hand_name(int(s["value"]))) if shown else ""]
			lc = Color(0.5, 1.0, 0.6)
		elif state == "show" and shown and not out:
			line = CD.hand_name(int(s["value"]))
		elif state == "buy" and String(s["line"]) != "":
			line = String(s["line"])
		draw_string(font, plate.position + Vector2(12.0, 65.0), line, HORIZONTAL_ALIGNMENT_LEFT, 276.0, 13, lc)
		if i == tell_seat and tell != "" and not out and state == "hand":      # (a kind hand: you read this guest)
			draw_string(font, Vector2(plate.position.x, plate.end.y + 22.0), "You read a tell: %s %s." % [nm.get_slice(" ", 0), tell], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15,
				Color(1.0, 0.6, 0.85, 0.75 + 0.25 * sin(_t * 3.0)))
		# what lies before the seat in this round, and the dealer's button
		var mid := at.lerp(tc, 0.42 if i != 0 else 0.5)
		if int(s["bet"]) > 0:
			Cards.chips(self, mid + Vector2(-20.0, 0.0), int(s["bet"]), col)
		if state != "buy" and i == button:
			var bp := at.lerp(tc, 0.3) + Vector2(70.0, -6.0)
			draw_circle(bp, 15.0, Color(0.95, 0.95, 1.0))
			draw_string(font, bp + Vector2(-15.0, 6.0), "D", HORIZONTAL_ALIGNMENT_CENTER, 30.0, 16, Color(0.05, 0.04, 0.1))
	# a free seat for co-op
	var fr := Rect2(vs.x - 330.0, 40.0, 290.0, 62.0)
	draw_rect(fr, Color(0.06, 0.05, 0.12))
	draw_rect(fr, Color(0.72, 0.5, 1.0, 0.4), false, 2.0)
	draw_string(font, fr.position + Vector2(12.0, 26.0), "A free seat", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color(0.6, 0.65, 0.78))
	draw_string(font, fr.position + Vector2(12.0, 48.0), "for a co-op player (later)", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color(0.5, 0.54, 0.66))
	if state == "hand" and turn == 0:
		var mh: String = CD.hand_name(CD.hand_value((seats[0]["hole"] as Array) + board)) if board.size() >= 3 else ""
		draw_string(font, Vector2(0.0, vs.y - 122.0), "Your turn.%s" % ("  You hold: %s." % mh.to_lower() if mh != "" else ""), HORIZONTAL_ALIGNMENT_CENTER, vs.x, 16, Color(0.85, 0.9, 1.0))
	draw_string(font, Vector2(0.0, vs.y - 96.0), msg, HORIZONTAL_ALIGNMENT_CENTER, vs.x, 20, Color(1.0, 0.95, 0.6))
