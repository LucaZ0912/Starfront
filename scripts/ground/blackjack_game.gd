extends Control
## Package 62, part 3 (Luz): blackjack in the Grand Centauria. You and two of the house's guests against the house;
## one seat stays free for a co-op player. You set your stake, the cards are dealt, and every seat in its turn takes
## a card, stands or doubles. The house draws to 16 and stands on 17; a blackjack pays 3 to 2. A kind hand (Dexterity,
## the perk Lucky Hand) lets a card that would take you over 21 slip back for the next now and then. Every seat's
## hand lives here by its number, and every move (bj_bet, bj_deal, bj_move) goes through the command bus with the
## seat, so a second player's can come the same way. The lounge's high table plays with larger chips.
## No class_name: preload it.

signal finished(won: bool)

const CD = preload("res://data/casino.gd")
const Cards = preload("res://scripts/ground/casino_cards.gd")
const NEON := [Color(1.0, 0.36, 0.66), Color(0.3, 0.9, 1.0), Color(1.0, 0.82, 0.25), Color(0.55, 1.0, 0.6), Color(0.72, 0.5, 1.0), Color(1.0, 0.45, 0.25)]
const SEAT_COL := [Color(1.0, 0.85, 0.35), Color(0.3, 0.9, 1.0), Color(1.0, 0.4, 0.75), Color(0.55, 1.0, 0.6)]
const SEAT_X := [0.39, 0.17, 0.61, 0.83]        # where the seats stand along the table (you a little left of the middle)
const CARD := Vector2(109.0, 153.0)             # the cards lie large on this table
const GAP := 46.0                               # … each a little over the one before
const STEP := 0.7                               # seconds between a guest's or the house's cards

var high := false
var chips: Array = CD.CHIPS
var limit := CD.LIMIT
var chip := 5
# split screen (Luz): the second player has the seat beside you and stakes from the same Coins. On a controller:
# left and right pick their chip, up puts it on, down takes the stake back; in their turn ✕ takes a card, □ stands,
# △ doubles; ✕ deals and goes on. The keys and the mouse are the player's at the keyboard.
var two := false
var chip2 := 5
var seats: Array = []                           # {name, guest, bet, hand, state: wait/play/stand/bust/bj, doubled, back}
var house: Array = []
var deck: Array = []
var state := "bet"                              # bet, play, house, done
var turn := -1
var msg := "Set your stake and have the cards dealt."
var last_bet := 0
var fast := false                               # (the smoke test) nobody waits between the cards
var _t := 0.0
var _st := 0.0
var _rng := RandomNumberGenerator.new()
var _btns := {}


func is_blackjack() -> bool:
	return true


func setup(cfg: Dictionary) -> void:
	high = bool(cfg.get("hi", false))
	chips = CD.CHIPS_HIGH if high else CD.CHIPS
	limit = CD.LIMIT_HIGH if high else CD.LIMIT
	chip = int(chips[0]) if high else int(chips[1])
	_rng.seed = Time.get_ticks_usec()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	two = Players.split and GameState.has_pilot2()
	chip2 = chip
	seats = [_seat("You" if not two else String(GameState.pilot_name).get_slice(" ", 0), false)]
	var gnames: Array = cfg.get("guests", ["A guest in white", "A guest in violet"])
	if two:
		var s2: Dictionary = _seat(String(GameState.pilot2.get("name", "Player 2")).get_slice(" ", 0), false)
		s2["p2"] = true
		seats.append(s2)
		gnames = gnames.slice(0, 1)                         # (one guest less: the seat is the second player's)
	for gname in gnames:
		seats.append(_seat(String(gname), true))
	_guests_bet()


## Is this seat one of you two?
func player_seat(seat: int) -> bool:
	return seat >= 0 and seat < seats.size() and not bool(seats[seat]["guest"])


## What the two of you have staked together.
func stake_sum() -> int:
	var n := 0
	for i in seats.size():
		if player_seat(i):
			n += int(seats[i]["bet"])
	return n


## The seat of the player at the keyboard and mouse.
func key_seat() -> int:
	return 1 if two and Players.on_keys(1) else 0


## A move of one of you in their turn.
func act(seat: int, what: String) -> void:
	if state != "play" or turn != seat or not player_seat(seat):
		return
	var e: String = Commands.execute({"type": "bj_move", "seat": seat, "move": what})
	if e != "":
		msg = e
		Audio.play("ui_error", "blackjack: refused")


## Split screen: a player on a controller.
func _two_step() -> void:
	for h in 2:
		if Players.on_keys(h):
			continue
		if state == "bet":
			var ch: int = chip2 if h == 1 else chip
			for dirn in [["foot_belt_4", -1], ["foot_belt_2", 1]]:      # their D-pad left / right: the chip
				if Players.just_pressed(h, String(dirn[0])):
					ch = int(chips[(chips.find(ch) + int(dirn[1]) + chips.size()) % chips.size()])
			if h == 1:
				chip2 = ch
			else:
				chip = ch
			if Players.just_pressed(h, "foot_belt_1"):           # up: the chip onto their box
				var e: String = Commands.execute({"type": "bj_bet", "seat": h, "chip": ch})
				msg = e if e != "" else "%s stakes %d Coins." % [String(seats[h]["name"]), int(seats[h]["bet"])]
				Audio.play("ui_error" if e != "" else "ui_click", "blackjack: stake")
			if Players.just_pressed(h, "foot_belt_3"):           # down: their stake back
				Commands.execute({"type": "bj_bet", "seat": h, "chip": -1})
		if Players.just_pressed(h, "interact"):                # ✕
			if state == "play":
				act(h, "hit")
			else:
				deal_or_next()
		if Players.just_pressed(h, "foot_swap"):               # □
			act(h, "stand")
		if Players.just_pressed(h, "foot_team"):               # △
			act(h, "double")


func _seat(nm: String, guest: bool) -> Dictionary:
	return {"name": nm, "guest": guest, "bet": 0, "hand": [], "state": "wait", "doubled": false, "back": 0}


func _ready() -> void:
	var vs := get_viewport_rect().size
	var row := UI.hbox(8)
	row.position = Vector2(vs.x * 0.5 - 640, vs.y - 112)
	add_child(row)
	row.add_child(UI.label("Chip", 16, UI.GOLD))
	for c in chips:
		var cv: int = c
		var b := UI.button("+%d" % cv, func(): add_chip(cv))
		b.custom_minimum_size = Vector2(84, 46)
		row.add_child(b)
		_btns[cv] = b
	for bt in [["clear", "Clear", func(): Commands.execute({"type": "bj_bet", "seat": 0, "chip": -1})], ["deal", "DEAL  (Space)", func(): deal_or_next()],
			["hit", "Card  (H)", func(): you("hit")], ["stand", "Stand  (S)", func(): you("stand")], ["double", "Double  (D)", func(): you("double")],
			["out", "Leave  (Esc)", func(): leave()]]:
		var b2 := UI.button(String(bt[1]), bt[2])
		b2.custom_minimum_size = Vector2(190 if String(bt[0]) == "deal" else 136, 46)
		row.add_child(b2)
		_btns[String(bt[0])] = b2


func add_chip(c: int) -> void:
	chip = c
	var ks := key_seat()
	var e: String = Commands.execute({"type": "bj_bet", "seat": ks, "chip": c})
	msg = e if e != "" else ("Your stake: %d Coins." % int(seats[0]["bet"]) if not two else "%s stakes %d Coins." % [String(seats[ks]["name"]), int(seats[ks]["bet"])])
	Audio.play("ui_error" if e != "" else "ui_click", "blackjack: chip")


## A seat puts `amount` Coins more on its box (less than one: takes its stake back). "" or why not.
func bet(seat: int, amount: int) -> String:
	if state != "bet":
		return "The cards are on the table."
	if seat < 0 or seat >= seats.size():
		return "No such seat."
	if amount <= 0:
		seats[seat]["bet"] = 0
		return ""
	var now := int(seats[seat]["bet"])
	if now + amount > limit:
		return "The table's limit is %d Coins a hand." % limit
	if player_seat(seat) and now + amount > GameState.coins_of(seat):
		return "Not enough Coins."                         # (each of you stakes from their own Coins)
	seats[seat]["bet"] = now + amount
	return ""


## The cards are dealt: your stake goes, two cards to every seat that has staked and two to the house (one open).
func deal() -> String:
	if state != "bet":
		return "The cards are on the table."
	var stake := stake_sum() if two else int(seats[0]["bet"])      # (split screen: whoever of you has staked plays; both stakes go)
	if stake <= 0:
		return "Set your stake first."
	if int(seats[0]["bet"]) > GameState.coins or (two and int(seats[1]["bet"]) > GameState.coins_of(1)):
		return "Not enough Coins. The cashier is in the lobby."
	GameState.coins -= int(seats[0]["bet"])
	if two:
		GameState.add_coins(1, -int(seats[1]["bet"]))          # (split screen: their stake out of their own Coins)
	last_bet = int(seats[0]["bet"])
	deck = CD.new_deck(GameState.casino_rng(), CD.BJ_DECKS)
	house = [deck.pop_back(), deck.pop_back()]
	for s in seats:
		s["hand"] = []
		s["doubled"] = false
		s["back"] = 0
		s["state"] = "wait"
		if int(s["bet"]) > 0:
			s["hand"] = [deck.pop_back(), deck.pop_back()]
			s["state"] = "bj" if CD.bj_natural(s["hand"]) else "play"
	state = "play"
	turn = -1
	_st = 0.0
	msg = "The cards are dealt."
	Audio.play("card_shuffle", "blackjack: deal")
	if CD.bj_natural(house):                     # the house looks at its card: a blackjack ends the round at once
		for s2 in seats:
			if String(s2["state"]) == "play":
				s2["state"] = "stand"
	_advance()
	return ""


## A seat's move in its turn: "hit" (a card), "stand", "double" (the stake again, one card, then it stands).
func move(seat: int, what: String) -> String:
	if state != "play" or seat != turn:
		return "It is not that seat's turn."
	var s: Dictionary = seats[seat]
	var hand: Array = s["hand"]
	match what:
		"stand":
			s["state"] = "stand"
		"hit", "double":
			if what == "double":
				if hand.size() != 2:
					return "You can only double on your first two cards."
				if player_seat(seat):
					if GameState.coins_of(seat) < int(s["bet"]):
						return "Not enough Coins to double."
					GameState.add_coins(seat, -int(s["bet"]))
				s["bet"] = int(s["bet"]) * 2
				s["doubled"] = true
			var card: Array = deck.pop_back()
			var kind := false
			if player_seat(seat) and CD.bj_total(hand + [card]) > 21 \
					and _rng.randf() < CD.bj_luck(GameState.pilot_attr("dexterity"), GameState.has_perk(CD.PERK)):
				card = deck.pop_back()               # (a kind hand: that card slips back, the next comes)
				kind = true
			hand.append(card)
			var t: int = CD.bj_total(hand)
			if player_seat(seat):
				msg = ("%s: " % String(s["name"]) if two else "") + ("A kind hand: the card slips back. " if kind else "") + "%s: %d." % [CD.card_name(card), t]
			Audio.play("card_play", "blackjack: card")
			if t > 21:
				s["state"] = "bust"
				if player_seat(seat):
					msg += " Over 21."
			elif t == 21 or what == "double":
				s["state"] = "stand"
		_:
			return "No such move."
	if String(s["state"]) != "play":
		_advance()
	return ""


func _advance() -> void:
	_st = 0.0
	for i in seats.size():
		if String(seats[i]["state"]) == "play":
			turn = i
			if two and player_seat(i):
				msg = "%s's turn: a card, stand or double." % String(seats[i]["name"])
			elif i == 0 and not msg.contains(":"):
				msg = "Your turn: a card, stand or double."
			return
	turn = -1
	state = "house"


func _house_step() -> void:
	var anyone := seats.any(func(s): return String(s["state"]) == "stand")
	if anyone and CD.bj_total(house) < 17:
		house.append(deck.pop_back())
		Audio.play("card_play", "blackjack: house")
		return
	_settle()


func _settle() -> void:
	state = "done"
	_st = 0.0
	for s in seats:
		if int(s["bet"]) > 0:
			s["back"] = CD.bj_back(int(s["bet"]), s["hand"], house)
	var staked := int(seats[0]["bet"])
	var back := int(seats[0]["back"])
	GameState.coins += back
	GameState.casino_book(staked, back)                    # (the house's book is the first player's own play)
	if two:                                                # split screen: each is paid into their own Coins; the word below speaks of both
		GameState.add_coins(1, int(seats[1]["back"]))
		staked = stake_sum()
		back += int(seats[1]["back"])
	var ht: int = CD.bj_total(house)
	var call := "The house has blackjack." if CD.bj_natural(house) else ("The house goes over with %d." % ht if ht > 21 else "The house stands on %d." % ht)
	if back > staked:
		msg = "%s %s You get %d Coins back." % [call, "Blackjack!" if CD.bj_natural(seats[0]["hand"]) else "You win.", back]
	elif back == staked:
		msg = "%s A stand-off: your stake comes back." % call
	else:
		msg = "%s The house takes %d Coins." % [call, staked]
	Audio.play("arcade_coin" if back > staked else "ui_click", "blackjack: settled")


func _guests_bet() -> void:
	for i in range(1, seats.size()):
		if not bool(seats[i]["guest"]):
			continue                                      # (split screen: the second player sets their own stake)
		seats[i]["bet"] = int(chips[_rng.randi() % 2]) * (1 + _rng.randi() % 4)


func _new_round() -> void:
	state = "bet"
	turn = -1
	house = []
	for s in seats:
		s["hand"] = []
		s["bet"] = 0
		s["back"] = 0
		s["state"] = "wait"
		s["doubled"] = false
	_guests_bet()
	msg = "Set your stake and have the cards dealt."


func deal_or_next() -> void:
	if state == "done":
		_new_round()
		return
	if state == "bet" and int(seats[0]["bet"]) == 0 and last_bet > 0 and not two:      # (the same stake again)
		Commands.execute({"type": "bj_bet", "seat": 0, "chip": mini(last_bet, limit)})
	var e: String = Commands.execute({"type": "bj_deal"})
	if e != "":
		msg = e
		Audio.play("ui_error", "blackjack: refused")


func you(what: String) -> void:
	if two:
		act(key_seat(), what)                             # (split screen: the keys and the mouse are the player's at the keyboard)
		return
	if state != "play" or turn != 0:
		return
	var e: String = Commands.execute({"type": "bj_move", "seat": 0, "move": what})
	if e != "":
		msg = e
		Audio.play("ui_error", "blackjack: refused")


func leave() -> void:
	if state == "bet" or state == "done":
		finished.emit(false)
	else:
		msg = "Play the hand out first."


func _process(dt: float) -> void:
	_t += dt
	var step := 0.0 if fast else STEP
	if two:
		_two_step()
	if state == "play" and turn > 0 and bool(seats[turn]["guest"]):
		_st += dt
		if _st >= step:
			_st = 0.0
			move(turn, CD.bj_guest(seats[turn]["hand"], int(house[0][0])))
	elif state == "house":
		_st += dt
		if _st >= step:
			_st = 0.0
			_house_step()
	var mine := state == "play" and (turn == 0 if not two else (player_seat(turn) and turn == key_seat()))
	for c in chips:
		(_btns[c] as Button).disabled = state != "bet"
		(_btns[c] as Button).modulate = Color(1.0, 0.85, 0.4) if int(c) == chip else Color.WHITE
	(_btns["clear"] as Button).disabled = state != "bet"
	(_btns["deal"] as Button).text = "NEXT HAND  (Space)" if state == "done" else "DEAL  (Space)"
	(_btns["deal"] as Button).disabled = state == "play" or state == "house" or (state == "bet" and (stake_sum() == 0 if two else (int(seats[0]["bet"]) == 0 and last_bet == 0)))
	(_btns["hit"] as Button).disabled = not mine
	(_btns["stand"] as Button).disabled = not mine
	(_btns["double"] as Button).disabled = not mine or (seats[0]["hand"] as Array).size() != 2 or GameState.coins < int(seats[0]["bet"])
	(_btns["out"] as Button).disabled = state == "play" or state == "house"
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_back", false, true):
		get_viewport().set_input_as_handled()
		leave()
	elif event is InputEventKey and event.pressed and not event.echo:
		var kc := (event as InputEventKey).keycode
		var used := true
		if kc == KEY_SPACE or kc == KEY_ENTER:
			if state == "play":
				you("hit")
			else:
				deal_or_next()
		elif kc == KEY_H:
			you("hit")
		elif kc == KEY_S:
			you("stand")
		elif kc == KEY_D:
			you("double")
		elif kc >= KEY_1 and kc < KEY_1 + chips.size() and state == "bet":
			add_chip(int(chips[kc - KEY_1]))
		else:
			used = false
		if used:
			get_viewport().set_input_as_handled()


## Package 80: with the controller ✕ deals, takes a card or goes on, □ stands, △ doubles, ◯ leaves; while you set
## your stake left and right pick the chip, up puts it on, down takes the stake back.
func pad_button(b: String, pressed: bool) -> bool:
	if not pressed:
		return true
	if two:
		return true                                       # (split screen: the controllers are read in _two_step)
	match b:
		"cross":
			if state == "play":
				you("hit")
			else:
				deal_or_next()
		"square":
			you("stand")
		"triangle":
			you("double")
		"circle":
			leave()
		"left", "right":
			if state == "bet":
				chip = int(chips[(chips.find(chip) + (1 if b == "right" else -1) + chips.size()) % chips.size()])
		"up":
			if state == "bet":
				add_chip(chip)
		"down":
			if state == "bet":
				Commands.execute({"type": "bj_bet", "seat": 0, "chip": -1})
	return true


func _seat_at(i: int) -> Vector2:
	var vs := get_viewport_rect().size
	var kx: float = SEAT_X[i % SEAT_X.size()]
	return Vector2(vs.x * kx, vs.y * 0.53 - absf(kx - 0.5) * vs.y * 0.3)


func _hand(at: Vector2, hand: Array, hide_second: bool, glow: Color, dim: bool) -> void:
	var sz: Vector2 = CARD
	var x0 := at.x - (sz.x + (hand.size() - 1) * GAP) * 0.5
	for k in hand.size():
		var p := Vector2(x0 + k * GAP, at.y)
		if hide_second and k == 1:
			Cards.back(self, p, sz)
		else:
			Cards.face(self, p, sz, hand[k], glow if k == hand.size() - 1 else Color(0, 0, 0, 0), dim)


func _draw() -> void:
	var vs := get_viewport_rect().size
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, vs), Color(0.03, 0.02, 0.07, 0.95))
	# ---- the table: half a round of cloth with rings of neon round it
	var tc := Vector2(vs.x * 0.5, vs.y * 0.2)
	var tr := vs.x * 0.44
	draw_set_transform(tc, 0.0, Vector2(1.0, 0.62))
	draw_circle(Vector2.ZERO, tr, Color(0.16, 0.05, 0.24))
	draw_circle(Vector2.ZERO, tr - 26.0, Color(0.2, 0.07, 0.3))
	for g in 4:
		draw_arc(Vector2.ZERO, tr + 6.0 + g * 9.0, 0.0, PI, 72, Color(NEON[(g + int(_t * 2.0)) % NEON.size()], 0.95 - g * 0.2), 4.0)
	draw_arc(Vector2.ZERO, tr * 0.52, 0.15, PI - 0.15, 48, Color(1.0, 0.82, 0.3, 0.35), 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_rect(Rect2(0.0, 0.0, vs.x, tc.y), Color(0.03, 0.02, 0.07))
	draw_string(font, Vector2(40.0, 70.0), "HIGH-STAKES BLACKJACK" if high else "BLACKJACK", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 40, Color(1.0, 0.5, 0.8).lerp(Color(0.3, 0.9, 1.0), 0.5 + 0.5 * sin(_t * 1.5)))
	draw_string(font, Vector2(40.0, 104.0), ("The limit: %d Coins a hand   ·   you hold %d Coins   ·   blackjack pays 3 to 2   ·   the house stands on 17" % [limit, GameState.coins]) if not two else ("The limit: %d Coins a hand   ·   %s holds %d Coins   ·   %s holds %d Coins   ·   blackjack pays 3 to 2" % [limit, String(seats[0]["name"]), GameState.coins, String(seats[1]["name"]), GameState.coins_of(1)]),
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17, Color(1.0, 0.85, 0.4))
	draw_line(Vector2(tc.x - tr - 40.0, tc.y), Vector2(tc.x + tr + 40.0, tc.y), Color(1.0, 0.36, 0.66, 0.9), 4.0)
	draw_string(font, Vector2(tc.x - 300.0, vs.y * 0.44), "BLACKJACK PAYS 3 TO 2", HORIZONTAL_ALIGNMENT_CENTER, 600.0, 20, Color(1.0, 0.82, 0.3, 0.5))
	# ---- the house
	var hy := tc.y + 24.0
	if house.is_empty():
		Cards.back(self, Vector2(tc.x - CARD.x * 0.5, hy), CARD, true)
	else:
		_hand(Vector2(tc.x, hy), house, state == "play", Color(0, 0, 0, 0), false)
	var hs := "The house"
	if not house.is_empty():
		hs = "The house shows %s" % CD.card_name(house[0]) if state == "play" else "The house: %d" % CD.bj_total(house)
	draw_string(font, Vector2(tc.x - 300.0, hy + CARD.y + 28.0), hs, HORIZONTAL_ALIGNMENT_CENTER, 600.0, 19, Color(0.9, 0.93, 1.0))
	# ---- the seats
	for i in seats.size() + 1:
		var free := i >= seats.size()
		var at := _seat_at(i)
		var col: Color = SEAT_COL[i % SEAT_COL.size()]
		var plate := Rect2(at.x - 130.0, at.y + CARD.y + 14.0, 260.0, 70.0)
		var mine := not free and state == "play" and turn == i
		draw_rect(plate, Color(0.06, 0.05, 0.12))
		draw_rect(plate, Color(col, 0.35 if free else 0.9), false, 4.0 if mine else 2.0)
		if mine:
			draw_rect(plate.grow(5.0), Color(col, 0.4 + 0.4 * absf(sin(_t * 4.0))), false, 2.0)
		if free:
			draw_rect(Rect2(at.x - CARD.x * 0.5, at.y, CARD.x, CARD.y), Color(col, 0.25), false, 2.0)
			draw_string(font, plate.position + Vector2(12.0, 28.0), "A free seat", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color(0.6, 0.65, 0.78))
			draw_string(font, plate.position + Vector2(12.0, 52.0), "for a co-op player (later)", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color(0.5, 0.54, 0.66))
			continue
		var s: Dictionary = seats[i]
		var hand: Array = s["hand"]
		var st := String(s["state"])
		if hand.is_empty():
			draw_rect(Rect2(at.x - CARD.x * 0.5, at.y, CARD.x, CARD.y), Color(col, 0.3), false, 2.0)
		else:
			_hand(at, hand, false, Color(col, 0.9) if mine else Color(0, 0, 0, 0), st == "bust")
		Cards.chips(self, Vector2(at.x - 120.0, at.y - 26.0), int(s["bet"]), col)
		draw_string(font, plate.position + Vector2(12.0, 28.0), String(s["name"]), HORIZONTAL_ALIGNMENT_LEFT, 236.0, 16, col)
		var line := "stake %d" % int(s["bet"]) if int(s["bet"]) > 0 else "no stake yet"
		var lc := Color(0.85, 0.9, 1.0)
		if not hand.is_empty():
			line = "%d%s" % [CD.bj_total(hand), "  (doubled)" if bool(s["doubled"]) else ""]
			if st == "bj":
				line = "Blackjack"
				lc = Color(1.0, 0.85, 0.4)
			elif st == "bust":
				line += "  over"
				lc = Color(1.0, 0.45, 0.45)
			if state == "done":
				var bk := int(s["back"])
				line += "   ·   back %d of %d" % [bk, int(s["bet"])]
				lc = Color(0.5, 1.0, 0.6) if bk > int(s["bet"]) else (Color(0.85, 0.9, 1.0) if bk == int(s["bet"]) else Color(1.0, 0.45, 0.45))
		draw_string(font, plate.position + Vector2(12.0, 54.0), line, HORIZONTAL_ALIGNMENT_LEFT, 236.0, 15, lc)
	draw_string(font, Vector2(0.0, vs.y - 140.0), msg, HORIZONTAL_ALIGNMENT_CENTER, vs.x, 20, Color(1.0, 0.95, 0.6))
