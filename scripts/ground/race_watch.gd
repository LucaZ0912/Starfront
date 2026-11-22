extends Control
## Package 62b (Luz): a seat in The Track's cinema: the race large before you. Beside it the standing, under it the
## speaker's word and your tickets on this race. Before a race you may wait for its start, during it skip to its
## end (the races' clock is moved on; the race itself is the same). No class_name: preload it.

signal finished(won: bool)

const RD = preload("res://data/races.gd")
const Art = preload("res://scripts/ground/race_art.gd")

var _t := 0.0
var _btns := {}
var _was := ""


func is_race_watch() -> bool:
	return true


func setup(_cfg: Dictionary) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	var vs := get_viewport_rect().size
	var row := UI.hbox(8)
	row.position = Vector2(vs.x * 0.5 - 290.0, vs.y - 78.0)
	add_child(row)
	for bt in [["go", "Wait for the start  (Space)", func(): go()], ["out", "Stand up  (Esc)", func(): finished.emit(false)]]:
		var b := UI.button(String(bt[1]), bt[2])
		b.custom_minimum_size = Vector2(330 if String(bt[0]) == "go" else 240, 46)
		row.add_child(b)
		_btns[String(bt[0])] = b


## Space: before a race on to its start, during it on to its end.
func go() -> void:
	var st := String(RD.phase(RD.clock())["state"])
	if st != "result":
		Commands.execute({"type": "race_wait"})
		Audio.play("ui_click", "race: on")


func _process(dt: float) -> void:
	_t += dt
	var st := String(RD.phase(RD.clock())["state"])
	if st != _was:
		if st == "run":
			Audio.play("undock_release", "race: start")
		elif st == "result" and _was == "run":
			Audio.play("arcade_coin", "race: over")
		_was = st
	(_btns["go"] as Button).text = {"bets": "Wait for the start  (Space)", "run": "Skip to the end  (Space)", "result": "The next race follows"}[st]
	(_btns["go"] as Button).disabled = st == "result"
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_back", false, true):
		get_viewport().set_input_as_handled()
		finished.emit(false)
	elif event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode in [KEY_SPACE, KEY_ENTER]:
		get_viewport().set_input_as_handled()
		go()


func pad_button(b: String, pressed: bool) -> bool:
	if not pressed:
		return true
	if b == "cross":
		go()
	elif b == "circle":
		finished.emit(false)
	return true


func _draw() -> void:
	var vs := get_viewport_rect().size
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, vs), Color(0.02, 0.01, 0.04, 0.98))
	var t: float = RD.clock()
	var ph: Dictionary = RD.phase(t)
	var race: Dictionary = RD.race(int(ph["n"]))
	var state := String(ph["state"])
	var rt := float(ph["rt"])
	var sr := Rect2(60.0, 60.0, vs.x - 470.0, (vs.x - 470.0) / 2.6)
	draw_rect(sr.grow(10.0), Color(0.05, 0.04, 0.08))
	Art.draw(self, sr, t, true)
	# ---- the standing
	var px := sr.end.x + 40.0
	draw_string(font, Vector2(px, 96.0), "The standing" if state == "run" else ("The result" if state == "result" else "The card"), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 24, Color(1.0, 0.85, 0.4))
	var st: Array = RD.standing(race, rt) if state != "bets" else range(6)
	for q in 6:
		var i := int(st[q])
		var pl: Dictionary = RD.pilot(race, i)
		var out: bool = state != "bets" and RD.wrecked(race, i, rt)
		var y := 150.0 + q * 62.0
		draw_rect(Rect2(px, y - 30.0, 330.0, 54.0), Color(0.07, 0.05, 0.13))
		draw_rect(Rect2(px, y - 30.0, 330.0, 54.0), Color(pl["col"], 0.3 if out else 0.85), false, 2.0)
		draw_string(font, Vector2(px + 12.0, y + 4.0), ("%d" % (q + 1)) if state != "bets" else "", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 24, Color(1, 1, 1, 0.9))
		draw_string(font, Vector2(px + 46.0, y - 4.0), "%d  %s" % [i + 1, String(pl["name"])], HORIZONTAL_ALIGNMENT_LEFT, 270.0, 18, Color(pl["col"]).darkened(0.4) if out else Color(pl["col"]).lightened(0.2))
		draw_string(font, Vector2(px + 46.0, y + 16.0), "wrecked, the pilot is picked up" if out else "%s   ·   win %s" % [String(pl["ship"]), Art._odds(float(race["win"][i]))], HORIZONTAL_ALIGNMENT_LEFT, 270.0, 13,
			Color(1.0, 0.5, 0.5) if out else Color(0.7, 0.75, 0.88))
	# ---- the speaker, your tickets
	var by := sr.end.y + 50.0
	var word: String = RD.speaker(race, rt) if state != "bets" else "Next: %s, three laps through %s. The start in %s." % [String(race["track"]["name"]), String(race["track"]["where"]), Art.mmss(float(ph["left"]))]
	draw_string(font, Vector2(60.0, by), word, HORIZONTAL_ALIGNMENT_LEFT, sr.size.x, 24, Color(1.0, 0.95, 0.6))
	draw_string(font, Vector2(60.0, by + 50.0), "Your tickets on this race", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17, Color(0.6, 0.65, 0.78))
	var n := 0
	for b in GameState.race_bets:
		if int(b["n"]) != int(race["n"]) or int(b.get("seat", 0)) != 0 or n >= 6:
			continue
		var line := "%s   ·   %d Coins at %s" % [RD.bet_text(race, b), int(b["stake"]), Art._odds(float(b["odds"]))]
		var lc := Color(0.9, 0.93, 1.0)
		if state == "result":
			var won: bool = RD.bet_won(race, String(b["kind"]), int(b["a"]), int(b.get("b", -1)))
			line += "   ·   won %d: the counter pays" % int(floor(int(b["stake"]) * float(b["odds"]))) if won else "   ·   lost"
			lc = Color(0.5, 1.0, 0.6) if won else Color(1.0, 0.5, 0.5)
		draw_string(font, Vector2(60.0 + (n % 2) * sr.size.x * 0.5, by + 80.0 + (n / 2) * 26.0), line, HORIZONTAL_ALIGNMENT_LEFT, sr.size.x * 0.5 - 20.0, 16, lc)
		n += 1
	if n == 0:
		draw_string(font, Vector2(60.0, by + 80.0), "None. The counters take bets until the start.", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color(0.75, 0.8, 0.92))
