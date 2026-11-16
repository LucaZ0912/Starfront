extends Control
## Package 54b (Luz): Drift – the card game at a lounge table (mockup_54b_drift). Cards 1–10 in four suits (comets,
## moons, suns, nebulae) and four Warp cards (worth nothing). You and two or three guests get two cards each; in turn
## each draws ("drift") or holds; over 21 burns out. Closest to 21 takes the pot – hitting exactly 21, a Singularity,
## wins at once. A Warp in your hand swaps one of your cards for the deck's top one (the Warp goes to
## the discard). Every move goes through the command bus (drift_move), so a co-op player's move can come the same way.
## No class_name: preload it.

signal finished(won: bool)

const MG = preload("res://data/minigames.gd")
const SUITS := ["comet", "moon", "sun", "nebula"]
const SUIT_COL := {"comet": Color(0.4, 0.85, 1.0), "moon": Color(0.85, 0.85, 0.95), "sun": Color(1.0, 0.75, 0.25), "nebula": Color(0.85, 0.45, 1.0)}

var stake := 0
var players: Array = []                          # {name, job, stars, hand: [[v, suit]], state: play/hold/burned, line, guest}
var deck: Array = []
var discard: Array = []
var turn := 0
var state := "play"                              # play, warp (choosing the card to swap), over
var won := false
var winners: Array = []
var msg := ""
var msg_t := 0.0
var _ai_t := 0.0
var _rng := RandomNumberGenerator.new()
var _ui := {}
var _btns := {}


func setup(cfg: Dictionary) -> void:
	stake = int(cfg.get("stake", 0))
	_rng.seed = Time.get_ticks_usec()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	players = [{"name": "You", "job": "", "stars": 0, "hand": [], "state": "play", "line": "", "guest": false}]
	var opp: Dictionary = cfg.get("opponent", {})
	if not opp.is_empty():
		players.append(_guest(opp))
	for o in cfg.get("others", []):
		if players.size() < 4:
			players.append(_guest(o))
	if players.size() < 2:
		players.append(_guest({"name": "A guest", "job": "drinker", "stars": 2}))
	deal()


func _guest(o: Dictionary) -> Dictionary:
	return {"name": String(o.get("name", "Guest")), "job": String(o.get("job", "")), "stars": int(o.get("stars", 2)), "hand": [], "state": "play", "line": "", "guest": true}


func _ready() -> void:
	_build_ui()


# ---------------------------------------------------------------- the cards

func deal() -> void:
	deck.clear()
	discard.clear()
	for s in SUITS:
		for v in range(1, 11):
			deck.append([v, s])
	for w in 4:
		deck.append([0, "warp"])
	deck.shuffle()
	for p in players:
		p["hand"] = [_draw_card(), _draw_card()]
		p["state"] = "play"
		p["line"] = ""
	turn = 0
	state = "play"
	winners = []
	# a Singularity on the deal wins at once
	var sing: Array = []
	for i in players.size():
		if total(players[i]) == 21:
			sing.append(i)
	if not sing.is_empty():
		_showdown(sing, "Singularity!")
		return
	_say("Your turn – drift or hold.")


func _draw_card() -> Array:
	if deck.is_empty():
		deck = discard.duplicate()
		discard.clear()
		deck.shuffle()
	return deck.pop_back() if not deck.is_empty() else [1, "comet"]


static func total(p: Dictionary) -> int:
	var t := 0
	for c in p["hand"]:
		t += int(c[0])
	return t


static func has_warp(p: Dictionary) -> bool:
	for c in p["hand"]:
		if String(c[1]) == "warp":
			return true
	return false


## A move (from the command bus): "drift", "hold", or "warp" with the index of the card to swap.
func move(what: String, card: int = -1) -> void:
	if state == "over" or turn >= players.size():
		return
	var p: Dictionary = players[turn]
	match what:
		"drift":
			p["hand"].append(_draw_card())
			Audio.play("ui_click", "drift: a card", -8.0, 0.2)
			if total(p) == 21:
				_showdown([turn], "Singularity!")
			elif total(p) > 21:
				p["state"] = "burned"
				p["line"] = "BURNED OUT – %d" % total(p)
				_say("%s burned out (%d)." % ["You" if turn == 0 else String(p["name"]).split(" ")[0], total(p)])
				_next()
		"hold":
			p["state"] = "hold"
			p["line"] = "holds"
			_next()
		"warp":
			var hand: Array = p["hand"]
			var wi := -1
			for i in hand.size():
				if String(hand[i][1]) == "warp":
					wi = i
					break
			if wi < 0 or card < 0 or card >= hand.size() or card == wi:
				return
			var old: Array = hand[card]
			hand[card] = _draw_card()
			discard.append(old)
			discard.append(hand[wi])
			hand.remove_at(wi)
			_say("%s warps a %d away." % ["You" if turn == 0 else String(p["name"]).split(" ")[0], int(old[0])])
			Audio.play("ui_open", "drift: warp", -6.0)
			state = "play"
			if total(p) == 21:
				_showdown([turn], "Singularity!")
			elif total(p) > 21:
				p["state"] = "burned"
				p["line"] = "BURNED OUT – %d" % total(p)
				_next()


func _next() -> void:
	turn += 1
	while turn < players.size() and String(players[turn]["state"]) != "play":
		turn += 1
	_ai_t = 1.0
	if turn >= players.size():
		var best := -1
		for p in players:
			if String(p["state"]) != "burned":
				best = maxi(best, total(p))
		var win: Array = []
		for i in players.size():
			if String(players[i]["state"]) != "burned" and total(players[i]) == best:
				win.append(i)
		_showdown(win, "")


func _showdown(win: Array, why: String) -> void:
	state = "over"
	winners = win
	won = win.has(0)
	var names := PackedStringArray()
	for i in win:
		names.append("You" if i == 0 else String(players[i]["name"]))
	var pot := stake * players.size()
	var share := pot / maxi(win.size(), 1)
	if win.is_empty():
		_say("Everyone burned out – the house keeps the pot.")
	else:
		_say("%s%s %s with %d%s." % [why + " " if why != "" else "", ", ".join(names), "wins" if win.size() == 1 else "share the pot", total(players[win[0]]),
			("" if stake <= 0 else " – %d cr" % share)])
	Commands.execute({"type": "minigame_end", "won": won, "pot": share if won else 0})
	Audio.play("mission_complete" if won else "warn", "drift: showdown")
	_show_result(share)


func finish(you_won: bool) -> void:
	if state == "over":
		return
	if you_won:
		_showdown([0], "")
	else:
		players[0]["state"] = "burned"
		_showdown([1], "You fold.")


func _say(t: String) -> void:
	msg = t
	msg_t = 4.0


# ---------------------------------------------------------------- the guests

## How far a guest draws: the better ones hold sooner and use the Warp well.
static func ai_choice(p: Dictionary) -> String:
	var t := total(p)
	var stars := int(p.get("stars", 2))
	if has_warp(p):
		var lo := 99
		for c in p["hand"]:
			if String(c[1]) != "warp":
				lo = mini(lo, int(c[0]))
		if lo <= 3 and t <= 15:
			return "warp"
	var hold_at := 14 + stars + (1 if stars >= 4 else 0)
	return "drift" if t < hold_at else "hold"


func _ai_step(dt: float) -> void:
	_ai_t -= dt
	if _ai_t > 0.0:
		return
	var p: Dictionary = players[turn]
	var c := ai_choice(p)
	_ai_t = 0.9
	if c == "warp":
		var lo := 0
		var lv := 99
		for i in (p["hand"] as Array).size():
			var cd: Array = p["hand"][i]
			if String(cd[1]) != "warp" and int(cd[0]) < lv:
				lv = int(cd[0])
				lo = i
		Commands.execute({"type": "drift_move", "move": "warp", "card": lo})
	else:
		if c == "drift":
			p["line"] = ["drifting… \"One more.\"", "drifting… \"Hit me.\"", "drifting…"][_rng.randi() % 3]
		Commands.execute({"type": "drift_move", "move": c})


func _process(dt: float) -> void:
	msg_t = maxf(0.0, msg_t - dt)
	if state == "play" and turn > 0 and turn < players.size():
		_ai_step(dt)
	_update_ui()
	queue_redraw()


# ---------------------------------------------------------------- input

func _you(what: String, card: int = -1) -> void:
	if turn != 0 or state == "over":
		return
	if what == "warp" and card < 0:
		if has_warp(players[0]):
			state = "warp"
			_say("Click the card to warp away.")
		return
	Commands.execute({"type": "drift_move", "move": what, "card": card})


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT and state == "warp":
		var hand: Array = players[0]["hand"]
		for i in hand.size():
			if _card_rect(0, i).has_point(get_local_mouse_position()) and String(hand[i][1]) != "warp":
				_you("warp", i)
				accept_event()
				return


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_back", false, true):
		get_viewport().set_input_as_handled()
		if state == "over":
			finished.emit(won)
		else:
			finish(false)
	elif event is InputEventKey and event.pressed and not event.echo and turn == 0 and state == "play":
		match (event as InputEventKey).keycode:
			KEY_D:
				_you("drift")
			KEY_H:
				_you("hold")
			KEY_W:
				_you("warp")


# ---------------------------------------------------------------- drawing

func _seat_pos(i: int) -> Vector2:
	var vs := get_viewport_rect().size
	var c := vs * 0.5
	match i:
		0:
			return c + Vector2(-150, 150)
		1:
			return c + Vector2(-540, -90) if players.size() > 2 else c + Vector2(-100, -300)
		2:
			return c + Vector2(-100, -300) if players.size() > 3 else c + Vector2(370, -90)
		_:
			return c + Vector2(370, -90)


func _card_rect(i: int, k: int) -> Rect2:
	var big := i == 0
	var sz := Vector2(96, 136) if big else Vector2(66, 94)
	return Rect2(_seat_pos(i) + Vector2(k * (100.0 if big else 60.0), 0), sz)


func _draw() -> void:
	var vs := get_viewport_rect().size
	var c := vs * 0.5
	draw_rect(Rect2(Vector2.ZERO, vs), Color(0.1, 0.07, 0.09))
	for i in 30:
		draw_circle(c, 760.0 - i * 20.0, Color(0.16, 0.1, 0.12, 0.05))
	draw_circle(c + Vector2(5, 15), 372.0, Color(0, 0, 0, 0.4))
	draw_circle(c, 372.0, Color(0.55, 0.42, 0.2))
	draw_circle(c, 360.0, Color(0.35, 0.24, 0.14))
	draw_circle(c, 336.0, Color(0.12, 0.28, 0.32))
	for i2 in 20:
		draw_circle(c + Vector2(0, -20), 330.0 - i2 * 15.0, Color(0.25, 0.5, 0.52, 0.03))
	# the deck, the discard, the pot
	for d in mini(4, deck.size()):
		_back(c + Vector2(-110 - d, -60 - d * 2))
	if not discard.is_empty():
		var top: Array = discard.back()
		_face(c + Vector2(30, -60), top, false)
	var font := ThemeDB.fallback_font
	draw_string(font, c + Vector2(-106, 54), "DECK %d" % deck.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, UI.TEXT_DIM)
	draw_string(font, c + Vector2(34, 54), "DISCARD", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, UI.TEXT_DIM)
	for ch in mini(players.size() * 2, 12):
		var cp := c + Vector2(-40 + (ch % 4) * 16, -120 + (ch / 4) * 12)
		draw_circle(cp, 9.0, Color(0.9, 0.3, 0.3) if ch % 2 else Color(0.95, 0.85, 0.4))
		draw_arc(cp, 9.0, 0, TAU, 20, Color(1, 1, 1, 0.6), 2.0)
	# the hands
	for i3 in players.size():
		var p: Dictionary = players[i3]
		var hand: Array = p["hand"]
		for k in hand.size():
			var r := _card_rect(i3, k)
			var hidden := i3 > 0 and k == 0 and state != "over"
			if hidden:
				_back(r.position)
			else:
				_face(r.position, hand[k], i3 == 0, state == "warp" and i3 == 0 and String(hand[k][1]) != "warp")
		if i3 > 0:
			var lp := _seat_pos(i3) + Vector2(0, -44)
			var col := Color(1.0, 0.8, 0.3) if not winners.has(i3) else Color(0.5, 1.0, 0.6)
			draw_string(font, lp, "%s, %s  %s" % [p["name"], p["job"], MG.stars_text(int(p["stars"]))], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, col)
			var line := String(p["line"])
			if state == "over":
				line = ("BURNED OUT – %d" % total(p)) if String(p["state"]) == "burned" else "%d" % total(p)
			elif turn == i3:
				line = line if line != "" else "thinking…"
			draw_string(font, lp + Vector2(0, 22), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.45, 0.45) if String(p["state"]) == "burned" else Color(0.62, 0.66, 0.78))


func _face(p: Vector2, card: Array, big: bool, glow: bool = false) -> void:
	var sz := Vector2(96, 136) if big else Vector2(66, 94)
	var r := Rect2(p, sz)
	draw_rect(Rect2(p + Vector2(4, 5), sz), Color(0, 0, 0, 0.35))
	var font := ThemeDB.fallback_font
	var suit := String(card[1])
	var cen := p + sz * 0.5
	if suit == "warp":
		draw_rect(r, Color(0.15, 0.08, 0.25))
		for i in 6:
			draw_arc(cen, 8.0 + i * 7.0 * (sz.x / 96.0), i * 0.8, i * 0.8 + 4.0, 30, Color(0.85, 0.45, 1.0, 0.8 - i * 0.1), 3.0)
		draw_string(font, p + Vector2(8, 24), "WARP", HORIZONTAL_ALIGNMENT_LEFT, -1, 18 if big else 13, Color(0.95, 0.75, 1.0))
		draw_string(font, p + Vector2(8, sz.y - 10), "0", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.95, 0.75, 1.0))
		draw_rect(r, Color(0.85, 0.45, 1.0), false, 3.0)
		return
	var col: Color = SUIT_COL[suit]
	draw_rect(r, Color(0.93, 0.92, 0.88))
	draw_rect(r.grow(-5), Color(0.08, 0.1, 0.16))
	draw_string(font, p + Vector2(10, 30 if big else 24), str(card[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 26 if big else 20, col)
	_symbol(suit, cen, 22.0 if big else 15.0, col)
	draw_string(font, p + Vector2(sz.x - (34 if big else 26), sz.y - 12), str(card[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 20 if big else 15, col)
	if glow:
		draw_rect(r.grow(3), Color(0.85, 0.45, 1.0, 0.7), false, 3.0)


func _symbol(suit: String, at: Vector2, s: float, col: Color) -> void:
	match suit:
		"comet":
			draw_circle(at + Vector2(s * 0.3, -s * 0.3), s * 0.35, col)
			for t in 3:
				draw_line(at + Vector2(s * 0.2, -s * 0.2), at + Vector2(-s * 0.7 + t * 4, s * 0.7 - t * 6), Color(col, 0.6), 2.0)
		"moon":
			draw_circle(at, s * 0.6, col)
			draw_circle(at + Vector2(s * 0.3, -s * 0.15), s * 0.5, Color(0.08, 0.1, 0.16))
		"sun":
			draw_circle(at, s * 0.42, col)
			for i in 8:
				var a := i * TAU / 8.0
				draw_line(at + Vector2(cos(a), sin(a)) * s * 0.55, at + Vector2(cos(a), sin(a)) * s * 0.85, col, 2.0)
		"nebula":
			for i in 4:
				draw_circle(at + Vector2(cos(i * 1.7), sin(i * 2.3)) * s * 0.3, s * (0.4 - i * 0.05), Color(col, 0.5))


func _back(p: Vector2) -> void:
	var sz := Vector2(66, 94)
	draw_rect(Rect2(p + Vector2(4, 5), sz), Color(0, 0, 0, 0.35))
	draw_rect(Rect2(p, sz), Color(0.2, 0.12, 0.3))
	draw_rect(Rect2(p, sz).grow(-5), Color(0.35, 0.2, 0.5), false, 2.0)
	draw_circle(p + sz * 0.5, 12.0, Color(1.0, 0.45, 0.75, 0.6))
	draw_arc(p + sz * 0.5, 20.0, 0, TAU, 30, Color(1.0, 0.45, 0.75, 0.4), 2.0)


# ---------------------------------------------------------------- the panels

func _build_ui() -> void:
	var vs := get_viewport_rect().size
	var tl := UI.neon_panel(Color(1.0, 0.45, 0.7), Color(0.03, 0.05, 0.06, 0.88), 2)
	tl.position = Vector2(20, 20)
	tl.custom_minimum_size = Vector2(420, 0)
	add_child(tl)
	var v := UI.vbox(4)
	tl.add_child(v)
	v.add_child(UI.label("DRIFT", 26, Color(1.0, 0.6, 0.8)))
	_ui["sub"] = UI.label("Closest to 21 wins the pot", 15)
	_ui["hand"] = UI.label("", 22, Color(0.5, 1.0, 0.6))
	_ui["warp"] = UI.label("", 14, Color(0.85, 0.45, 1.0))
	_ui["msg"] = UI.label("", 14, Color(1.0, 0.95, 0.6))
	for k in ["sub", "hand", "warp", "msg"]:
		v.add_child(_ui[k])
	var tr := UI.neon_panel(Color(1.0, 0.8, 0.3), Color(0.03, 0.05, 0.06, 0.88), 2)
	tr.custom_minimum_size = Vector2(400, 0)
	tr.position = Vector2(vs.x - 420, 20)
	add_child(tr)
	var v2 := UI.vbox(4)
	tr.add_child(v2)
	var streak := int(GameState.minigame_streak.get("drift", 0))
	v2.add_child(UI.label("Pot %d cr" % (stake * players.size()) if stake > 0 else "No stake", 22, Color(1.0, 0.85, 0.4)))
	v2.add_child(UI.label("%d at the table × %d cr" % [players.size(), stake], 15))
	v2.add_child(UI.label("Win streak %d – %s stakes (up to %d cr)" % [streak, String(MG.TIERS[MG.tier(streak)]["name"]), MG.max_stake(streak)], 13, UI.TEXT_DIM))
	var row := UI.hbox(16)
	row.position = Vector2(vs.x * 0.5 - 330, vs.y - 108)
	add_child(row)
	for b in [["drift", "DRIFT  (draw)"], ["hold", "HOLD"], ["warp", "WARP  (swap)"]]:
		var id: String = b[0]
		var btn := UI.button(String(b[1]), func(): _you(id))
		btn.custom_minimum_size = Vector2(200, 46)
		row.add_child(btn)
		_btns[id] = btn
	var hint := UI.label("D: drift  •  H: hold  •  W: warp – then click the card to swap  •  Esc: fold", 15)
	hint.position = Vector2(vs.x * 0.5 - 330, vs.y - 40)
	add_child(hint)


func _update_ui() -> void:
	if not _ui.has("hand"):
		return
	var me: Dictionary = players[0]
	_ui["hand"].text = "Your hand: %d%s" % [total(me), "  – BURNED OUT" if String(me["state"]) == "burned" else ""]
	_ui["warp"].text = "Warp held – swap a card with the deck's top" if has_warp(me) else ""
	_ui["msg"].text = msg if msg_t > 0.0 else ("Your turn – drift or hold." if turn == 0 and state == "play" else "")
	var mine := turn == 0 and state == "play"
	(_btns["drift"] as Button).disabled = not mine
	(_btns["hold"] as Button).disabled = not mine
	(_btns["warp"] as Button).disabled = not mine or not has_warp(me)


func _show_result(share: int) -> void:
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cc)
	var p := UI.neon_panel(Color(0.5, 1.0, 0.6) if won else Color(1.0, 0.4, 0.4), Color(0.03, 0.05, 0.06, 0.95), 2)
	p.custom_minimum_size = Vector2(460, 0)
	cc.add_child(p)
	var v := UI.vbox(10)
	p.add_child(v)
	v.add_child(UI.label("YOU WIN" if won else "YOU LOSE", 26, Color(0.5, 1.0, 0.6) if won else Color(1.0, 0.45, 0.45)))
	v.add_child(UI.label(msg, 14, UI.TEXT_DIM))
	if stake > 0:
		v.add_child(UI.label(("+%d cr" % share) if won else ("−%d cr" % stake), 18, Color(1.0, 0.85, 0.4)))
	v.add_child(UI.label("Win streak: %d" % int(GameState.minigame_streak.get("drift", 0)), 14, Color(0.9, 0.93, 1.0)))
	v.add_child(UI.button("Back to the table [Esc]", func(): finished.emit(won)))
