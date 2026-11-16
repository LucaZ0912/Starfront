extends Control
## Package 54b (Luz): the lobby before every bar game – the mode, the seats (you, and a guest of the bar or one of your
## crew; a seat for a co-op player is already there, for later), the stake by your win streak (higher tiers locked),
## the rules, start. No class_name: preload it.

signal start(cfg: Dictionary)
signal closed

const MG = preload("res://data/minigames.gd")

var game := "billiards"
var place := {}                          # {title, id}
var guests: Array = []
var crew: Array = []
var mode := ""
var stake := 0
var opponent := {}
var _rules := false
var _panel: PanelContainer = null


func setup(p_game: String, p_place: Dictionary, p_guests: Array, p_crew: Array) -> void:
	game = p_game
	place = p_place
	guests = p_guests
	crew = p_crew
	mode = String((MG.GAMES[game]["modes"] as Array)[0][0])
	if not guests.is_empty():
		opponent = guests[0]
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()


func _streak() -> int:
	return int(GameState.minigame_streak.get(game, 0))


func _build() -> void:
	if _panel != null:
		_panel.queue_free()
	var dim := get_node_or_null("dim")
	if dim == null:
		var d := ColorRect.new()
		d.name = "dim"
		d.color = Color(0, 0, 0, 0.55)
		d.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(d)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(cc)
	_panel = UI.neon_panel(Color(1.0, 0.45, 0.7), Color(0.03, 0.05, 0.06, 0.96), 2)
	_panel.custom_minimum_size = Vector2(900, 0)
	cc.add_child(_panel)
	_panel.tree_exited.connect(cc.queue_free)
	var v := UI.vbox(10)
	_panel.add_child(v)
	var g: Dictionary = MG.GAMES[game]
	v.add_child(UI.label(String(g["name"]).to_upper(), 28, Color(1.0, 0.6, 0.8)))
	v.add_child(UI.label(String(place.get("title", g["where"])), 14, UI.TEXT_DIM))
	if _rules:
		v.add_child(UI.label("RULES – " + _mode_name(mode), 14, UI.TEXT_DIM))
		v.add_child(UI.wrap_label(String(g["rules"][mode]), 15, Color(0.9, 0.93, 1.0), 840))
		v.add_child(UI.button("Back", func(): _rules = false; _build()))
		return
	# the mode
	v.add_child(UI.label("GAME", 13, UI.TEXT_DIM))
	var rm := UI.hbox(8)
	for md in g["modes"]:
		var mid := String(md[0])
		var b := UI.button(("▶ " if mid == mode else "") + String(md[1]), func(): mode = mid; _build())
		b.custom_minimum_size = Vector2(160, 34)
		rm.add_child(b)
	v.add_child(rm)
	# the seats
	var practice := MG.solo(mode)
	v.add_child(UI.label("PLAYERS", 13, UI.TEXT_DIM))
	var seats := UI.hbox(12)
	seats.add_child(_seat("You – %s" % String(GameState.pilot.get("name", "you")),
		("Your best: %d" % int(GameState.minigame_best.get(game, 0))) if game == "rockhopper" else "Win streak %d at %s" % [_streak(), String(g["name"]).to_lower()], Color(0.5, 1.0, 0.6)))
	if game == "rockhopper":
		seats.add_child(_seat("The cabinet", "Tonight's best: %d  –  yours: %d" % [int((MG.arcade_board(String(place.get("id", "")), GameState.minigame_best)[0] as Array)[1]),
			int(GameState.minigame_best.get("rockhopper", 0))], Color(1.0, 0.45, 0.75)))
	elif practice:
		seats.add_child(_seat("Nobody", "Practice – the table to yourself", UI.TEXT_DIM))
	elif opponent.is_empty():
		seats.add_child(_seat("Free seat", "Choose who plays below", UI.TEXT_DIM))
	else:
		seats.add_child(_seat("%s, %s  %s" % [opponent["name"], opponent["job"], MG.stars_text(int(opponent["stars"]))],
			"Chosen – %s" % String(opponent.get("line", "")), Color(1.0, 0.8, 0.3)))
	v.add_child(seats)
	if not practice:
		v.add_child(UI.label("Who else is here:", 13, UI.TEXT_DIM))
		for p in guests + crew:
			var pp: Dictionary = p
			var on := not opponent.is_empty() and String(opponent["id"]) == String(pp["id"])
			var row := UI.button("%s%s, %s   %s   %s" % ["▶ " if on else "", pp["name"], pp["job"], MG.stars_text(int(pp["stars"])),
				"guest" if String(pp["kind"]) == "guest" else "crew aboard"], func(): opponent = pp; _build())
			row.alignment = HORIZONTAL_ALIGNMENT_LEFT
			v.add_child(row)
		var coop := UI.button("Co-op player – join with a friend in co-op (later)", func(): pass)
		coop.disabled = true
		coop.alignment = HORIZONTAL_ALIGNMENT_LEFT
		v.add_child(coop)
		# the stake
		v.add_child(UI.label("STAKE", 13, UI.TEXT_DIM))
		var rs := UI.hbox(8)
		for st in MG.stakes(_streak()):
			var amt := int(st[0])
			var open := bool(st[1]) and amt <= GameState.credits
			var b2 := UI.button(("▶ " if amt == stake else "") + ("None" if amt == 0 else "%d cr" % amt) + ("" if bool(st[1]) else " 🔒"), func(): stake = amt; _build())
			b2.disabled = not open
			rs.add_child(b2)
		v.add_child(rs)
		var t := MG.tier(_streak())
		v.add_child(UI.label("Win streak %d – %s stakes up to %d cr  (medium from 10 wins in a row, high from 25 – the guests get better too)" % [
			_streak(), String(MG.TIERS[t]["name"]), MG.max_stake(_streak())], 13, UI.TEXT_DIM))
	var bot := UI.hbox(10)
	bot.add_child(UI.button("Rules", func(): _rules = true; _build()))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bot.add_child(sp)
	bot.add_child(UI.button("Leave [Esc]", func(): closed.emit()))
	var go := UI.button("START  ▶", func(): _start())
	go.disabled = not practice and opponent.is_empty()
	bot.add_child(go)
	v.add_child(bot)


func _mode_name(m: String) -> String:
	for md in MG.GAMES[game]["modes"]:
		if String(md[0]) == m:
			return String(md[1])
	return m


func _seat(title: String, sub: String, col: Color) -> Control:
	var p := UI.neon_panel(col, Color(0.03, 0.05, 0.06, 0.9), 2)
	p.custom_minimum_size = Vector2(430, 64)
	var v := UI.vbox(2)
	p.add_child(v)
	v.add_child(UI.label(title, 17, col))
	v.add_child(UI.label(sub, 13, UI.TEXT_DIM))
	return p


func _start() -> void:
	var cfg := {"game": game, "mode": mode, "stake": 0 if MG.solo(mode) else stake, "opponent": {} if MG.solo(mode) else opponent}
	cfg["place"] = place
	var e: String = Commands.execute({"type": "minigame_begin", "game": game, "mode": mode, "stake": cfg["stake"], "opponent": cfg["opponent"], "place": String(place.get("id", ""))})
	if e != "":
		Audio.play("ui_error", "minigame: " + e)
		return
	start.emit(cfg)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_back", false, true):
		get_viewport().set_input_as_handled()
		if _rules:
			_rules = false
			_build()
		else:
			closed.emit()
