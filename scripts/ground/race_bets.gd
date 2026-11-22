extends Control
## Package 62b (Luz): a betting counter on The Track. The card of the next race: the course, the six pilots with
## their ships, their last races and the odds; you pick the kind of bet (win, place: among the first three, exacta:
## the first and the second in their order), a chip, and click a pilot. A ticket is final. Tickets that are decided
## are paid here when you come to the counter. With the perk Lucky Hand the clerk gives you a tip. Every ticket
## belongs to a seat and every bet goes through the command bus (race_bet, race_collect), so a co-op player's can
## come the same way. No class_name: preload it.

signal finished(won: bool)

const RD = preload("res://data/races.gd")
const Art = preload("res://scripts/ground/race_art.gd")
const NEON := [Color(1.0, 0.36, 0.66), Color(0.3, 0.9, 1.0), Color(1.0, 0.82, 0.25), Color(0.55, 1.0, 0.6), Color(0.72, 0.5, 1.0), Color(1.0, 0.45, 0.25)]

var kind := "win"
var chip := 5
var first := -1                                 # an exacta: the pilot picked to come first
var row := 0                                    # (the controller) the pilot marked
var msg := "Pick a kind of bet and a chip, then click a pilot."
var _t := 0.0
var _btns := {}


func is_race_bets() -> bool:
	return true


func setup(_cfg: Dictionary) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var d: Dictionary = RD.due(GameState.race_bets, RD.clock())
	if int(d["count"]) > 0:                          # the counter pays what is decided
		Commands.execute({"type": "race_collect", "seat": 0})
		msg = "%d of your %d tickets won: the clerk pays you %d Coins." % [int(d["won"]), int(d["count"]), int(d["back"])] if int(d["back"]) > 0 \
			else "None of your %d tickets won. Better luck in the next race." % int(d["count"])


func _ready() -> void:
	var vs := get_viewport_rect().size
	var rowc := UI.hbox(8)
	rowc.position = Vector2(60.0, vs.y - 100.0)
	add_child(rowc)
	rowc.add_child(UI.label("Bet", 16, UI.GOLD))
	for kk in RD.KINDS:
		var kv := String(kk)
		var b := UI.button(String(RD.KINDS[kk]), func(): set_kind(kv))
		b.custom_minimum_size = Vector2(120, 46)
		rowc.add_child(b)
		_btns[kv] = b
	rowc.add_child(UI.label("   Chip", 16, UI.GOLD))
	for c in RD.CHIPS:
		var cv: int = c
		var b2 := UI.button("%d" % cv, func(): set_chip(cv))
		b2.custom_minimum_size = Vector2(84, 46)
		rowc.add_child(b2)
		_btns[cv] = b2
	var b3 := UI.button("Leave  (Esc)", func(): finished.emit(false))
	b3.custom_minimum_size = Vector2(150, 46)
	rowc.add_child(b3)


func set_kind(k: String) -> void:
	kind = k
	first = -1
	msg = "An exacta: click who comes first, then who comes second." if k == "exacta" else "%s: click a pilot." % String(RD.KINDS[k])
	Audio.play("ui_click", "bets: kind")


func set_chip(c: int) -> void:
	chip = c
	Audio.play("ui_click", "bets: chip")


## You click pilot `i` (0 … 5) of the card.
func pick(i: int) -> void:
	var nx: Dictionary = RD.next_open(RD.clock())
	if kind == "exacta" and first < 0:
		first = i
		msg = "%s first. Now click who comes second." % String(RD.pilot(RD.race(int(nx["n"])), i)["name"])
		Audio.play("ui_click", "bets: first")
		return
	var e: String = Commands.execute({"type": "race_bet", "seat": 0, "kind": kind, "a": first if kind == "exacta" else i, "b": i if kind == "exacta" else -1, "stake": chip})
	first = -1
	msg = e if e != "" else "Your ticket is in. Take a seat and watch."
	Audio.play("ui_error" if e != "" else "arcade_coin", "bets: ticket")


func rows() -> Array:
	var out: Array = []
	for i in 6:
		out.append(Rect2(60.0, 250.0 + i * 78.0, 1150.0, 70.0))
	return out


func _process(dt: float) -> void:
	_t += dt
	for kk in RD.KINDS:
		(_btns[String(kk)] as Button).modulate = Color(1.0, 0.85, 0.4) if String(kk) == kind else Color.WHITE
	for c in RD.CHIPS:
		(_btns[c] as Button).modulate = Color(1.0, 0.85, 0.4) if int(c) == chip else Color.WHITE
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var rs := rows()
		for i in rs.size():
			if (rs[i] as Rect2).has_point((event as InputEventMouseButton).position):
				row = i
				pick(i)
				accept_event()
				return


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_back", false, true):
		get_viewport().set_input_as_handled()
		finished.emit(false)
	elif event is InputEventKey and event.pressed and not event.echo:
		var kc := (event as InputEventKey).keycode
		if kc >= KEY_1 and kc <= KEY_6:
			get_viewport().set_input_as_handled()
			row = kc - KEY_1
			pick(row)


## Package 80: with the controller up and down mark a pilot, ✕ bets on it, □ changes the kind of bet, left and
## right the chip, ◯ leaves.
func pad_button(b: String, pressed: bool) -> bool:
	if not pressed:
		return true
	match b:
		"up", "down":
			row = posmod(row + (1 if b == "down" else -1), 6)
		"left", "right":
			chip = int(RD.CHIPS[posmod(RD.CHIPS.find(chip) + (1 if b == "right" else -1), RD.CHIPS.size())])
		"cross":
			pick(row)
		"square":
			var ks: Array = RD.KINDS.keys()
			set_kind(String(ks[(ks.find(kind) + 1) % ks.size()]))
		"circle":
			finished.emit(false)
	return true


func _draw() -> void:
	var vs := get_viewport_rect().size
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, vs), Color(0.03, 0.02, 0.07, 0.98))
	var t: float = RD.clock()
	var nx: Dictionary = RD.next_open(t)
	var open := true
	var race: Dictionary = RD.race(int(nx["n"]))          # (while a race runs: the card of the one after it)
	var tr: Dictionary = race["track"]
	draw_string(font, Vector2(60.0, 70.0), "THE TRACK: BETS", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 40, Color(1.0, 0.5, 0.8).lerp(Color(0.3, 0.9, 1.0), 0.5 + 0.5 * sin(_t * 1.5)))
	draw_string(font, Vector2(60.0, 104.0), "The limit: %d Coins a race   ·   you hold %d Coins   ·   a ticket is final" % [RD.LIMIT, GameState.coins], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17, Color(1.0, 0.85, 0.4))
	draw_string(font, Vector2(60.0, 160.0), String(tr["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 30, Color(0.9, 0.95, 1.0))
	draw_string(font, Vector2(60.0, 190.0), "Three laps through %s. The danger: %s." % [String(tr["where"]), String(tr["hazard"])], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17, Color(0.7, 0.75, 0.88))
	draw_string(font, Vector2(660.0, 160.0), "starts in %s" % Art.mmss(float(nx["left"])), HORIZONTAL_ALIGNMENT_RIGHT, 550.0, 24, Color(1.0, 0.85, 0.3))
	if String(RD.phase(t)["state"]) != "bets":
		draw_string(font, Vector2(660.0, 190.0), "(the race before it is on the screen now)", HORIZONTAL_ALIGNMENT_RIGHT, 550.0, 15, Color(0.7, 0.75, 0.88))
	# ---- the card
	var heads := [["Pilot", 70.0], ["Ship", 400.0], ["Last races", 640.0], ["Win", 850.0], ["Place", 990.0]]
	for h in heads:
		draw_string(font, Vector2(60.0 + float(h[1]), 236.0), String(h[0]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color(0.6, 0.65, 0.78))
	var rs := rows()
	var mp := get_local_mouse_position()
	for i in 6:
		var r: Rect2 = rs[i]
		var pl: Dictionary = RD.pilot(race, i)
		var col: Color = pl["col"]
		var hot := open and (r.has_point(mp) or (Pad.using_pad and row == i))
		draw_rect(r, Color(0.07, 0.05, 0.13) if not hot else Color(0.12, 0.09, 0.2))
		draw_rect(r, Color(col, 0.9 if hot or first == i else 0.45), false, 3.0 if hot or first == i else 1.5)
		draw_string(font, r.position + Vector2(14.0, 46.0), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 30, col)
		Art._ship(self, r.position + Vector2(56.0, 35.0), 2.6, col, 0.0)
		draw_string(font, r.position + Vector2(90.0, 44.0), String(pl["name"]), HORIZONTAL_ALIGNMENT_LEFT, 300.0, 22, Color(0.95, 0.96, 1.0))
		draw_string(font, r.position + Vector2(400.0, 44.0), String(pl["ship"]), HORIZONTAL_ALIGNMENT_LEFT, 230.0, 19, Color(0.75, 0.8, 0.92))
		draw_string(font, r.position + Vector2(640.0, 44.0), RD.form(int(race["entry"][i]), int(race["n"])), HORIZONTAL_ALIGNMENT_LEFT, 200.0, 19, Color(0.75, 0.8, 0.92))
		draw_string(font, r.position + Vector2(850.0, 46.0), Art._odds(float(race["win"][i])), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 26, Color(1.0, 0.85, 0.4) if kind != "place" else Color(0.6, 0.6, 0.5))
		draw_string(font, r.position + Vector2(990.0, 46.0), Art._odds(float(race["place"][i])), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 26, Color(1.0, 0.85, 0.4) if kind == "place" else Color(0.6, 0.6, 0.5))
		if kind == "exacta" and first >= 0 and first != i:
			draw_string(font, r.position + Vector2(1070.0, 44.0), "%d" % int(RD.odds(race, "exacta", first, i)), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 19, Color(0.55, 1.0, 0.6))
	draw_string(font, Vector2(60.0, 250.0 + 6 * 78.0 + 22.0), "X: wrecked   ·   Win: comes first   ·   Place: among the first three   ·   Exacta: the first and the second in their order",
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color(0.6, 0.65, 0.78))
	if GameState.has_perk("lucky_hand") and open:
		draw_string(font, Vector2(60.0, 250.0 + 6 * 78.0 + 54.0), "The clerk leans over: \"%s is in good form today.\"" % String(RD.pilot(race, int(race["tip"]))["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17,
			Color(1.0, 0.6, 0.85))
	# ---- your tickets
	var tk := Rect2(1270.0, 140.0, vs.x - 1330.0, 660.0)
	draw_rect(tk, Color(0.06, 0.05, 0.12))
	for g in 3:
		draw_rect(tk.grow(g * 5.0), Color(NEON[(g + int(_t * 1.5)) % NEON.size()], 0.8 - g * 0.25), false, 3.0)
	draw_string(font, tk.position + Vector2(20.0, 40.0), "Your tickets", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 24, Color(1.0, 0.85, 0.4))
	var y := tk.position.y + 80.0
	var total := 0
	for b in GameState.race_bets:
		if int(b.get("seat", 0)) != 0 or y > tk.end.y - 70.0:
			continue
		var br: Dictionary = RD.race(int(b["n"]))
		draw_string(font, Vector2(tk.position.x + 20.0, y), RD.bet_text(br, b), HORIZONTAL_ALIGNMENT_LEFT, tk.size.x - 170.0, 16, Color(0.9, 0.93, 1.0))
		draw_string(font, Vector2(tk.end.x - 150.0, y), "%d × %s" % [int(b["stake"]), Art._odds(float(b["odds"]))], HORIZONTAL_ALIGNMENT_RIGHT, 130.0, 16, Color(1.0, 0.85, 0.4))
		draw_string(font, Vector2(tk.position.x + 20.0, y + 20.0), String(br["track"]["name"]) + ("" if int(b["n"]) == int(race["n"]) else "  (on the screen now)"), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color(0.6, 0.65, 0.78))
		if int(b["n"]) == int(race["n"]):
			total += int(b["stake"])
		y += 50.0
	if y < tk.position.y + 90.0:
		draw_string(font, tk.position + Vector2(20.0, 84.0), "No ticket yet.", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color(0.6, 0.65, 0.78))
	draw_string(font, Vector2(tk.position.x + 20.0, tk.end.y - 24.0), "Staked on this race: %d of %d" % [total, RD.LIMIT], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17, Color(0.85, 0.9, 1.0))
	draw_string(font, Vector2(60.0, vs.y - 124.0), msg, HORIZONTAL_ALIGNMENT_LEFT, vs.x - 120.0, 20, Color(1.0, 0.95, 0.6))
