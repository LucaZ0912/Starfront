class_name StoryUI
extends CanvasLayer
const AcqData = preload("res://data/acquaintances.gd")
## Package 55 (Luz, mockup_55*): what the story shows – a dialogue with a portrait (the game pauses; the answers can
## set story flags), a radio call in flight (top centre, typed, the game goes on; one after the other), a tip (over
## the module bar: "Got it", "No more tips"), the tracked mission's next goals (in space over the ship's panel, on
## foot under the suit's bars) and in space a gold diamond on its target (an arrow at the edge when it is off the
## screen). Also measures the "near" goals. Lives in Main.

const Data = preload("res://data/story.gd")
const PilotArt = preload("res://scripts/core/pilot_art.gd")
const DialogueViewS = preload("res://scripts/ground/dialogue_view.gd")
const GOLD := Color(1.0, 0.82, 0.35)

var main: Node = null
var _radio_q: Array = []
var _radio: PanelContainer = null
var _radio_text: Label = null
var _radio_t := 0.0
var _radio_shown := 0.0
var _radio_d := {}                      # the call shown (its "until" conditions)
var _radio_hint: Label = null
var _radio_layer: CanvasLayer = null    # Luz, 18 Nov 2026: over the windows (the station's too), under dialogues
var radio_avoid := Rect2()              # package 58: a part of the screen the call must not cover (the guided tour's frame)
var _tip: PanelContainer = null
var _tracker: PanelContainer = null
var _tracker_box: VBoxContainer = null
var _marker: Node2D
var _near_t := 0.0
var dialogue: Control = null            # the dialogue open (its layer pauses the game)
var _dlg_layer: CanvasLayer = null
var _dlg := {}                          # {id, mission, line, said}
var _dlg_q: Array = []
## Split screen (Luz, 25 Nov 2026, rule 7 as Luz set it: "the story's things happen with player 1 only, and both
## stand still during the talks"): a talk of the story is the first player's, stands over the whole picture and the
## game is paused for both players, wherever each of them is. What it moves on counts for both.
## The one exception is a counter's talk of their own (the Colosseum's Marshal, where everybody signs up for
## themselves: its data says "own"): it stands over the half of who began it, their own device answers, and while
## you are in different places the other player's view goes on meanwhile (main.talk_begin()).
var _dlg_seat := 0
var _dlg_half := false                  # … it stands in a half (main.talk_end() gives the half back)


func _ready() -> void:
	layer = 15                                       # over the HUD (10) and the ground (12), under the windows (25)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_marker = Node2D.new()
	_marker.draw.connect(_draw_marker)
	add_child(_marker)
	_radio_layer = CanvasLayer.new()
	_radio_layer.layer = 30
	_radio_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_radio_layer)
	GameState.story.show.connect(_on_show)
	GameState.story.changed.connect(_refresh_tracker)
	GameState.story.changed.connect(func(): AcqData.refresh())       # package 60: new acquaintances, changed steps
	_refresh_tracker()


func _on_show(kind: String, data: Dictionary) -> void:
	match kind:
		"radio":
			if bool(data.get("now", false)):
				# package 58: the guided tour's call comes at once – before any waiting, the one shown gives way
				_radio_q.push_front(data)
				if _radio != null and is_instance_valid(_radio):
					_radio.queue_free()
					_radio = null
					_radio_d = {}
			else:
				_radio_q.append(data)
		"dialogue":
			if not data.has("seat"):
				data = data.duplicate()
				data["seat"] = 1 if (Players.split and GameState.has_pilot2() and GameState.acting == 1 and bool(data.get("own", false))) else 0
			_dlg_q.append(data)
			if dialogue == null:
				_next_dialogue()
		"tip":
			_show_tip(String(data["id"]))


# ---------------------------------------------------------------- dialogues (the game pauses)

func _next_dialogue() -> void:
	if _dlg_q.is_empty():
		return
	var d: Dictionary = _dlg_q.pop_front()
	var dd: Dictionary = Data.DIALOGUES.get(String(d["id"]), {})
	if dd.is_empty():
		return
	var who := String(dd["who"])
	var c: Dictionary = Data.CHARACTERS.get(who, {})
	_dlg_layer = CanvasLayer.new()
	_dlg_layer.layer = 80
	_dlg_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	_dlg_seat = int(d.get("seat", 0)) if (Players.split and GameState.has_pilot2()) else 0
	_dlg_half = bool(d.get("own", false)) and main != null and main.has_method("talk_begin") and main.halves_on()
	if _dlg_half:
		main.talk_begin(_dlg_seat, _dlg_layer)           # (a counter's own talk: over their half; in different places the other's view goes on)
	else:
		add_child(_dlg_layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.0 if bool(d.get("no_dim", false)) else 0.45)      # (Luz) a cutscene: the scene stays clear
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dlg_layer.add_child(dim)
	dialogue = DialogueViewS.new()
	dialogue.portrait_tex = GameState.story.portrait_of(who)
	dialogue.no_dim = bool(d.get("no_dim", false))
	dialogue.add_to_group("kbd_menu")
	_dlg_layer.add_child(dialogue)
	dialogue.open(GameState.story.look_of(who), String(c.get("name", who)), String(c.get("sub", "")), c.get("col", GOLD))
	_dlg = {"id": String(d["id"]), "mission": String(d.get("mission", "")), "line": 0, "said": [], "who": who}
	get_tree().paused = true
	_line(0)


func _line(i: int) -> void:
	var dd: Dictionary = Data.DIALOGUES[String(_dlg["id"])]
	var ln: Dictionary = (dd["lines"] as Array)[i]
	_dlg["line"] = i
	var who := String(ln.get("who", _dlg["who"]))
	_speaker(who)
	(_dlg["said"] as Array).append([who, String(ln["text"])])
	var opts: Array = []
	var shown: Array = []
	for a in ln.get("answers", []):
		var ans: Array = a
		if not answer_ok(ans):
			continue                                          # package 56: an answer only when its story flags say so
		shown.append(ans)
		var o := [String(ans[0]), func(): _answer(ans)]
		if ans.size() > 4 and bool((ans[4] as Dictionary).get("gold", false)):
			o.append(GOLD)                                    # package 56 (Luz): it moves the story on – in gold
		opts.append(o)
	_dlg["answers"] = shown
	if opts.is_empty():
		# package 56: no answers – a press goes on to the next line (or the line's "next"; -1: the end)
		var nxt := int(ln.get("next", i + 1 if i + 1 < (dd["lines"] as Array).size() else -1))
		dialogue.say(GameState.story.keys(String(ln["text"])), [], func(): _answer(["", nxt, []]))
		return
	dialogue.say(GameState.story.keys(String(ln["text"])), opts)


## Package 56: who speaks the line – one of the story's people, or the pilot ("you", their own face).
func _speaker(who: String) -> void:
	if dialogue == null:
		return
	if who == "you":
		var me: Dictionary = GameState.pilot_of(_dlg_seat)   # (the pilot who talks)
		dialogue.set_speaker(PilotArt.portrait(me.get("look", {})), String(me.get("name", GameState.pilot_name)), "", Color(0.45, 0.85, 1.0))
		return
	var c: Dictionary = Data.CHARACTERS.get(who, {})
	dialogue.set_speaker(GameState.story.portrait_of(who), String(c.get("name", who)), String(c.get("sub", "")), c.get("col", GOLD))


## Package 56: whether an answer is offered – its 5th entry {"if": [[flag, value], …] (one of them), "not": [flag, …]
## (none of them set)}; value true: the flag set at all.
static func answer_ok(ans: Array) -> bool:
	if ans.size() < 5:
		return true
	var c: Dictionary = ans[4]
	var fl: Dictionary = GameState.story.flags
	if c.has("if"):
		var any := false
		for pair in c["if"]:
			var v = fl.get(String(pair[0]), null)
			if v == null:
				continue
			if typeof(pair[1]) == TYPE_BOOL:
				any = any or bool(v) == bool(pair[1])
			else:
				any = any or (typeof(v) == typeof(pair[1]) and v == pair[1])
		if not any:
			return false
	for nf in c.get("not", []):
		var nv = fl.get(String(nf), null)
		if nv != null and not (typeof(nv) == TYPE_BOOL and not nv):
			return false
	return true


## An answer (of those shown): its flag set, on to its line (or the end).
func choose(i: int) -> void:
	var ans: Array = _dlg.get("answers", [])
	if dialogue != null and ans.is_empty():
		dialogue.choose(0)                                    # a line without answers: on
		return
	_answer(ans[i] if i < ans.size() else ["", -1, []])


func _answer(ans: Array) -> void:
	var fl: Array = ans[2] if ans.size() > 2 else []
	if fl.size() >= 2:
		GameState.story.set_flag(String(fl[0]), fl[1])
	if ans.size() > 3 and String(ans[3]) != "":
		# package 56 (Luz): the pilot says it out loud – the answer at length, with their own face
		(_dlg["said"] as Array).append(["you", String(ans[3])])
		_speaker("you")
		_dlg["answers"] = []                                  # a press goes on (no answers to pick here)
		var nxt := int(ans[1])
		dialogue.say(GameState.story.keys(String(ans[3])), [], func(): _answer(["", nxt, []]))
		return
	if String(ans[0]) != "":
		(_dlg["said"] as Array).append(["you", String(ans[0])])
	if int(ans[1]) >= 0:
		_line(int(ans[1]))
		return
	var fin := _dlg.duplicate(true)
	_close_dialogue()
	GameState.story.dialogue_done(String(fin["mission"]), String(fin["id"]), fin["said"])
	_next_dialogue()


func _close_dialogue() -> void:
	if _dlg_layer != null:
		_dlg_layer.queue_free()
	_dlg_layer = null
	dialogue = null
	_dlg = {}
	get_tree().paused = false
	if _dlg_half and main != null:
		main.talk_end()
	_dlg_half = false
	_dlg_seat = 0


# ---------------------------------------------------------------- radio calls (the game goes on)

func _show_radio(d: Dictionary) -> void:
	var who := String(d.get("who", ""))
	var c: Dictionary = Data.CHARACTERS.get(who, {})
	if who == "you":
		c = {"name": GameState.pilot_name, "sub": "your ship", "col": Color(0.45, 0.85, 1.0)}      # package 58, part 8: you on the radio
	var col: Color = c.get("col", GOLD)
	_radio = UI.neon_panel(col, Color(0.03, 0.04, 0.08, 0.95), 2)
	_radio.custom_minimum_size = Vector2(660, 0)
	_radio.mouse_filter = Control.MOUSE_FILTER_IGNORE        # clicks go through to the window below
	_radio_layer.add_child(_radio)
	_radio_d = d
	var h := UI.hbox(12)
	_radio.add_child(h)
	var fr := UI.neon_panel(col, Color(0.05, 0.06, 0.1), 2)
	h.add_child(fr)
	var tr := TextureRect.new()
	tr.texture = GameState.story.portrait_of(who) if who != "you" else PilotArt.portrait(GameState.pilot.get("look", {}))
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.custom_minimum_size = Vector2(84, 84)
	fr.add_child(tr)
	var v := UI.vbox(2)
	h.add_child(v)
	var nh := UI.hbox(8)
	v.add_child(nh)
	nh.add_child(UI.label("◉ RADIO", 12, Color(1.0, 0.35, 0.3)))
	nh.add_child(UI.label("%s · %s" % [String(c.get("name", who)), String(c.get("sub", ""))], 14, col.lightened(0.15)))
	_radio_text = UI.wrap_label("\"%s\"" % GameState.story.keys(String(d["text"])), 14, Color(0.94, 0.95, 1.0), 520)
	_radio_text.visible_characters = 0
	v.add_child(_radio_text)
	_radio_hint = UI.label("past calls in the journal (%s)" % Keybinds.key_text("journal"), 11, UI.TEXT_DIM)
	v.add_child(_radio_hint)
	for c2 in _radio.find_children("*", "Control", true, false):
		(c2 as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	_radio_t = 4.0 + String(d["text"]).length() / 22.0
	_radio.scale = Vector2.ONE * radio_scale()
	_place_radio()
	_radio_shown = 0.0
	Audio.play("notify", "radio call", -6.0)


func _radio_step(dt: float) -> void:
	if _radio == null:
		if not _radio_q.is_empty() and not get_tree().paused:
			_show_radio(_radio_q.pop_front())
		return
	_radio_shown += dt * 40.0
	_radio_text.visible_characters = int(_radio_shown)
	# (Luz) the keys follow the device in use: picked up the controller (or the mouse) while the call is on – it says so
	var pad_now: bool = Pad.enabled and Pad.using_pad
	if pad_now != bool(_radio_d.get("_pad", pad_now)) and _radio_d.has("text"):
		_radio_text.text = "\"%s\"" % GameState.story.keys(String(_radio_d["text"]))
	_radio_d["_pad"] = pad_now
	_radio_t -= dt
	_place_radio()
	# a call that waited for something goes the moment it is done (package 58: the guided tour's steps)
	if _radio_d.has("until") and not radio_held(_radio_d):
		_radio.queue_free()
		_radio = null
		_radio_d = {}
		return
	if _radio_t > 0.0:
		return
	# a call that waits for something stays (Luz, 18 Nov 2026) – until it is done, or the next call comes
	if radio_held(_radio_d) and _radio_q.is_empty():
		var h := String(_radio_d.get("hint", ""))
		_radio_hint.text = ("◌ %s" % h) if h != "" else "◌ stays until it is done  •  past calls in the journal (%s)" % Keybinds.key_text("journal")
		_radio_hint.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35))
		return
	_radio.queue_free()
	_radio = null
	_radio_d = {}


## How long the radio still talks: what is left of the call on screen, and every call waiting (each as long as
## _show_radio gives it). Package 58, part 8: the warp to the Roost is timed to end with the talk.
func radio_left() -> float:
	var t := maxf(_radio_t, 0.0) if _radio != null else 0.0
	for d in _radio_q:
		t += 4.0 + String((d as Dictionary).get("text", "")).length() / 22.0 + 0.05
	return t


## Whether a call still waits for what it asks: a flag set ("until_flag"), its step over ("until_step"), or a
## code condition ("until": a Callable giving true when done).
func radio_held(d: Dictionary) -> bool:
	var st = GameState.story
	if String(d.get("until_flag", "")) != "" and not bool(st.flags.get(String(d["until_flag"]), false)):
		return true
	if bool(d.get("until_step", false)):
		var mid := String(d.get("mission", ""))
		if st.running(mid) and st.step_index(mid) == int(d.get("step", -1)):
			return true
	var u = d.get("until", null)
	if u is Callable and (u as Callable).is_valid() and not bool((u as Callable).call()):
		return true
	return false


## Top centre in flight; at the bottom while a station window is open (so it covers none of its buttons).
## Package 58, part 8: how far down the radio sits at the top (lower while the Roost's bar is shown).
var radio_top := 72.0


## Split screen: the story is the first player's (Luz). What it shows over the game (a radio call, a tip, the marks
## at its goals) stands in their half while the picture is in two.
func _area() -> Rect2:
	if main != null and is_instance_valid(main) and main.has_method("halves_on") and main.halves_on():
		return main.half_rect(0)
	return Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size)


func _place_radio() -> void:
	if _radio == null:
		return
	var vs := _area().size
	var sz := _radio.get_combined_minimum_size() * _radio.scale
	var low := false
	var m := get_tree().current_scene
	if m != null and m.get("station_panel") != null and is_instance_valid(m.station_panel) and m.station_panel.visible:
		low = true
	var y := vs.y - sz.y - 30.0 if low else radio_top
	if radio_avoid.size != Vector2.ZERO and Rect2(Vector2((vs.x - sz.x) * 0.5, y), sz).intersects(radio_avoid):
		y = 72.0 if low else vs.y - sz.y - 30.0                   # the other end of the screen
		if Rect2(Vector2((vs.x - sz.x) * 0.5, y), sz).intersects(radio_avoid):
			y = clampf(radio_avoid.end.y + 12.0, 72.0, vs.y - sz.y - 10.0) if radio_avoid.end.y + sz.y + 20.0 < vs.y else maxf(10.0, radio_avoid.position.y - sz.y - 12.0)
	_radio.position = Vector2(roundf((vs.x - sz.x) * 0.5), y)


## Luz, 18 Nov 2026: on big screens the call grows with the screen (it stays readable).
func radio_scale() -> float:
	return clampf(get_viewport().get_visible_rect().size.y / 900.0, 1.0, 2.4)


## Package 58: the call still typing? (a confirm first shows all of it)
func radio_typing() -> bool:
	return _radio != null and _radio_text != null and _radio_text.visible_characters >= 0 and _radio_text.visible_characters < _radio_text.get_total_character_count()


func radio_finish_typing() -> void:
	if _radio_text != null:
		_radio_shown = 99999.0
		_radio_text.visible_characters = -1


# ---------------------------------------------------------------- tips

func _show_tip(id: String) -> void:
	if _tip != null:
		_tip.queue_free()
	var t: Dictionary = Data.TIPS[id]
	_tip = UI.neon_panel(Color(0.4, 0.8, 1.0), Color(0.02, 0.05, 0.1, 0.95), 2)
	_tip.custom_minimum_size = Vector2(480, 0)
	_tip.position = _area().position + Vector2(_area().size.x * 0.5 - 240, _area().size.y - 300)
	add_child(_tip)
	var v := UI.vbox(4)
	_tip.add_child(v)
	v.add_child(UI.label("TIP · %s" % String(t["title"]).to_upper(), 13, Color(0.4, 0.8, 1.0)))
	v.add_child(UI.wrap_label(GameState.story.keys(String(t["text"])), 13, Color(0.92, 0.94, 1.0), 450))
	var hb := UI.hbox(10)
	v.add_child(hb)
	hb.add_child(UI.button("Got it", close_tip))
	hb.add_child(UI.button("No more tips", func():
		GameState.story.tips_off = true
		close_tip()))


func close_tip() -> void:
	if _tip != null:
		_tip.queue_free()
	_tip = null


# ---------------------------------------------------------------- the tracked mission and its marker

func _refresh_tracker() -> void:
	var st = GameState.story
	if _tracker != null:
		_tracker.queue_free()
		_tracker = null
	if st.tracked == "" or not st.running(st.tracked):
		return
	var md: Dictionary = st.mission_data(st.tracked)
	var step: Dictionary = st.step_data(st.tracked)
	_tracker = UI.neon_panel(Color(GOLD, 0.8), Color(0.03, 0.04, 0.08, 0.88), 1)
	_tracker.custom_minimum_size = Vector2(318, 0)
	_tracker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tracker)
	_tracker_box = UI.vbox(2)
	_tracker.add_child(_tracker_box)
	_tracker_box.add_child(UI.label("◆ %s" % String(md.get("title", "")).to_upper(), 12, GOLD))
	_tracker_box.add_child(UI.wrap_label(String(step.get("title", "")), 14, Color.WHITE, 300))
	var parts: PackedStringArray = []
	for gl in st.goal_lines(st.tracked):
		parts.append(("✓ " if gl[1] else "▸ ") + String(gl[0]))
	_tracker_box.add_child(UI.wrap_label("   ".join(parts), 12, Color(0.75, 0.9, 0.8), 300))
	_tracker_box.add_child(UI.label("%s: journal" % Keybinds.key_text("journal"), 11, UI.TEXT_DIM))


func _place_tracker() -> void:
	if _tracker == null:
		return
	var on_foot: bool = main != null and main.ground != null and is_instance_valid(main.ground)
	_tracker.visible = GameState.running and dialogue == null and not (on_foot and main.ground.in_colosseum())      # (Luz: not in the Colosseum)
	var vs := get_viewport().get_visible_rect().size
	if on_foot:
		# 0.8.58.6 (Luz: it covered the team): bottom left, over the belt – the top left is the suit's, the cover's
		# and the team's
		_tracker.position = Vector2(14, vs.y - 104 - _tracker.size.y)
	else:
		_tracker.position = Vector2(10, vs.y - 252 - _tracker.size.y)     # over the ship's panel


## The targets of the tracked mission's goals now (object ids in this system).
func marker_targets() -> Array:
	var st = GameState.story
	var out: Array = []
	if st.tracked == "" or not st.running(st.tracked):
		return out
	var m: Dictionary = st.missions[st.tracked]
	for g in st.step_data(st.tracked).get("goals", []):
		if bool((m["goals"] as Dictionary).get(String(g["id"]), false)):
			continue
		var t: String = st.goal_target(st.tracked, g)
		if t != "" and not out.has(t):
			out.append(t)
	var mt := String(m.get("target", ""))
	if out.is_empty() and mt != "":
		out.append(mt)                                     # package 56: the step's target, marked (the scrap to cut)
	return out


func _draw_marker() -> void:
	if main == null or main.view == null or not is_instance_valid(main.view) or (main.ground != null and is_instance_valid(main.ground)) or not GameState.running:
		return
	var v = main.view
	var font := ThemeDB.fallback_font
	var vs := _area().size
	# (two halves: the world's own transform is the whole picture's; in your half the same view is centred on the half)
	var shift: Vector2 = _area().get_center() - get_viewport().get_visible_rect().size * 0.5
	for t in marker_targets():
		var n = v.find_object(t)
		var p := Vector2.ZERO
		var dkm := 0.0
		var nm: String = String(t)
		if n == null or not is_instance_valid(n) or not (n is CanvasItem):
			# package 58: a field or a planet / moon (no node of its own) – its place from the system's layout
			var fd: Dictionary = Universe.warp_target(int(v.system_id), String(t))
			if fd.is_empty():
				continue
			p = v.get_global_transform_with_canvas() * (fd["pos"] as Vector2) + shift
			if v.player != null and is_instance_valid(v.player):
				dkm = (fd["pos"] as Vector2).distance_to(v.player.position)
			nm = String(fd.get("name", t))
		else:
			p = (n as CanvasItem).get_global_transform_with_canvas().origin + shift
			if v.player != null and is_instance_valid(v.player):
				dkm = (n as Node2D).position.distance_to(v.player.position)
			nm = String(n.data.get("name", t)) if "data" in n and n.data is Dictionary else t
			if n is Ship:
				nm = (n as Ship).fit.ship_name                    # package 56: Old Betty
			elif n.has_method("title"):
				nm = String(n.title())                            # the scrap to cut, the colossus
		var inside := Rect2(Vector2(30, 30), vs - Vector2(60, 60)).has_point(p)
		if inside:
			var pts := PackedVector2Array([p + Vector2(0, -16), p + Vector2(16, 0), p + Vector2(0, 16), p + Vector2(-16, 0), p + Vector2(0, -16)])
			_marker.draw_polyline(pts, GOLD, 2.0)
			_marker.draw_circle(p, 3.0, GOLD)
			_marker.draw_string(font, p + Vector2(22, -4), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, GOLD)
			_marker.draw_string(font, p + Vector2(22, 14), "objective · %s" % SystemView.fmt_dist(dkm), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(GOLD, 0.8))
		else:
			var c := vs * 0.5
			var d := (p - c).normalized()
			var e := c + d * minf((vs.x * 0.5 - 40.0) / maxf(absf(d.x), 0.001), (vs.y * 0.5 - 40.0) / maxf(absf(d.y), 0.001))
			var a := d.angle()
			_marker.draw_colored_polygon(PackedVector2Array([e + Vector2.from_angle(a) * 14, e + Vector2.from_angle(a + 2.5) * 12, e + Vector2.from_angle(a - 2.5) * 12]), GOLD)
			_marker.draw_string(font, e - d * 30 + Vector2(-60, 4), "%s %s" % [nm, SystemView.fmt_dist(dkm)], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, GOLD)


# ---------------------------------------------------------------- each frame

func _process(dt: float) -> void:
	_radio_step(dt)
	_place_tracker()
	_marker.queue_redraw()
	if dialogue != null and not get_tree().paused:
		get_tree().paused = true
	if dialogue != null and _dlg_half and main != null:
		main.talk_tick()                                 # (the game is paused for who talks: the halves and the other player's view are seen to from here)
	_near_t -= dt
	if _near_t <= 0.0:
		_near_t = 0.5
		_check_near()


## The "near" goals: how far the active ship is from their targets.
func _check_near() -> void:
	if main == null or main.view == null or not is_instance_valid(main.view):
		return
	var v = main.view
	if v.player == null or not is_instance_valid(v.player):
		return
	for ng in GameState.story.near_goals():
		var n = v.find_object(String(ng[2]))
		if n == null or not is_instance_valid(n):
			continue
		var d: float = (n as Node2D).position.distance_to(v.player.position)
		GameState.story.event("near", {"id": String(ng[2]), "km": d})
