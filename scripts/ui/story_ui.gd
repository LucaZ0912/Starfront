class_name StoryUI
extends CanvasLayer
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
var _tip: PanelContainer = null
var _tracker: PanelContainer = null
var _tracker_box: VBoxContainer = null
var _marker: Node2D
var _near_t := 0.0
var dialogue: Control = null            # the dialogue open (its layer pauses the game)
var _dlg_layer: CanvasLayer = null
var _dlg := {}                          # {id, mission, line, said}
var _dlg_q: Array = []


func _ready() -> void:
	layer = 15                                       # over the HUD (10) and the ground (12), under the windows (25)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_marker = Node2D.new()
	_marker.draw.connect(_draw_marker)
	add_child(_marker)
	GameState.story.show.connect(_on_show)
	GameState.story.changed.connect(_refresh_tracker)
	_refresh_tracker()


func _on_show(kind: String, data: Dictionary) -> void:
	match kind:
		"radio":
			_radio_q.append(data)
		"dialogue":
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
	add_child(_dlg_layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dlg_layer.add_child(dim)
	dialogue = DialogueViewS.new()
	dialogue.portrait_tex = GameState.story.portrait_of(who)
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
	for a in ln.get("answers", []):
		var ans: Array = a
		opts.append([String(ans[0]), func(): _answer(ans)])
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
		dialogue.set_speaker(PilotArt.portrait(GameState.pilot.get("look", {})), GameState.pilot_name, "", Color(0.45, 0.85, 1.0))
		return
	var c: Dictionary = Data.CHARACTERS.get(who, {})
	dialogue.set_speaker(GameState.story.portrait_of(who), String(c.get("name", who)), String(c.get("sub", "")), c.get("col", GOLD))


## An answer: its flag set, on to its line (or the end).
func choose(i: int) -> void:
	var dd: Dictionary = Data.DIALOGUES[String(_dlg["id"])]
	var ln: Dictionary = (dd["lines"] as Array)[int(_dlg["line"])]
	var ans: Array = (ln.get("answers", []) as Array)
	_answer(ans[i] if i < ans.size() else ["", -1, []])


func _answer(ans: Array) -> void:
	var fl: Array = ans[2] if ans.size() > 2 else []
	if fl.size() >= 2:
		GameState.story.set_flag(String(fl[0]), fl[1])
	if ans.size() > 3 and String(ans[3]) != "":
		# package 56 (Luz): the pilot says it out loud – the answer at length, with their own face
		(_dlg["said"] as Array).append(["you", String(ans[3])])
		_speaker("you")
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


# ---------------------------------------------------------------- radio calls (the game goes on)

func _show_radio(d: Dictionary) -> void:
	var who := String(d.get("who", ""))
	var c: Dictionary = Data.CHARACTERS.get(who, {})
	var col: Color = c.get("col", GOLD)
	_radio = UI.neon_panel(col, Color(0.03, 0.04, 0.08, 0.93), 2)
	_radio.position = Vector2(470, 72)
	_radio.custom_minimum_size = Vector2(660, 0)
	add_child(_radio)
	var h := UI.hbox(12)
	_radio.add_child(h)
	var fr := UI.neon_panel(col, Color(0.05, 0.06, 0.1), 2)
	h.add_child(fr)
	var tr := TextureRect.new()
	tr.texture = GameState.story.portrait_of(who)
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
	v.add_child(UI.label("past calls in the journal (%s)" % Keybinds.key_text("journal"), 11, UI.TEXT_DIM))
	_radio_t = 4.0 + String(d["text"]).length() / 22.0
	_radio_shown = 0.0
	Audio.play("notify", "radio call", -6.0)


func _radio_step(dt: float) -> void:
	if _radio == null:
		if not _radio_q.is_empty() and not get_tree().paused:
			_show_radio(_radio_q.pop_front())
		return
	_radio_shown += dt * 40.0
	_radio_text.visible_characters = int(_radio_shown)
	_radio_t -= dt
	if _radio_t <= 0.0:
		_radio.queue_free()
		_radio = null


# ---------------------------------------------------------------- tips

func _show_tip(id: String) -> void:
	if _tip != null:
		_tip.queue_free()
	var t: Dictionary = Data.TIPS[id]
	_tip = UI.neon_panel(Color(0.4, 0.8, 1.0), Color(0.02, 0.05, 0.1, 0.95), 2)
	_tip.custom_minimum_size = Vector2(480, 0)
	_tip.position = Vector2(get_viewport().get_visible_rect().size.x * 0.5 - 240, get_viewport().get_visible_rect().size.y - 300)
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
	_tracker.visible = GameState.running and dialogue == null
	if on_foot:
		_tracker.position = Vector2(14, 214)                    # under the suit's bars
	else:
		var vs := get_viewport().get_visible_rect().size
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
	var vs := get_viewport().get_visible_rect().size
	for t in marker_targets():
		var n = v.find_object(t)
		if n == null or not is_instance_valid(n) or not (n is CanvasItem):
			continue
		var p: Vector2 = (n as CanvasItem).get_global_transform_with_canvas().origin
		var dkm := 0.0
		if v.player != null and is_instance_valid(v.player):
			dkm = (n as Node2D).position.distance_to(v.player.position)
		var nm: String = String(n.data.get("name", t)) if "data" in n and n.data is Dictionary else t
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
