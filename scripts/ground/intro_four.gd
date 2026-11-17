extends Node
## Package 56 – the intro, sequence 4 (Luz): Dan's station. White; the pilot asleep in the infirmary, Dan and the
## medic beside the bed – the medic can't make sense of the readings, Dan asks to be told. Black, "A few weeks later":
## the pilot wakes, Dan introduces himself, asks them to come to the bar when they're fit. Black, "A few days later":
## the pilot stands by the bed, the medic lets them go. Then the pilot walks: the lift only goes to the bar (the rest
## greyed out), the bar is empty, Dan stands at the window. The talk with Dan – who they are, the year it is – ends with
## the choice of the flight tutorial (story flag "flight_tutorial"); sequence 5 (the tutorial) or 6 follows (later).
## Hold Esc (Options) to skip the scenes in the infirmary – not the talk in the bar.

signal finished

const BED := [11, 21]                      # a recovery bed of the infirmary (DeckGen.build_clinic) – room round it
const BED_CAM := Vector2(12.0, 26.6)       # where the camera looks (tiles) – the bed above the dialogue box
const DAN_BED := Vector2(13.7, 23.6)
const DOC_BED := Vector2(10.4, 24.6)
const STAND := Vector2(13.4, 24.8)         # the pilot on their feet beside the bed
const DOC_STAND := Vector2(15.2, 24.4)
const WINDOW := Vector2(20.6, 8.6)         # Dan at the bar's window (between the barrels)
const SKIP_HOLD := 1.2

var main: Node
var phase := ""
var t := 0.0
var skip_held := 0.0
var _layer: CanvasLayer
var _veil: ColorRect                       # the white or black between the scenes
var _card: Label                           # "A few weeks later"
var _hint: Label
var _waiting := ""                         # the dialogue it waits for


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = 75
	add_child(_layer)
	_veil = ColorRect.new()
	_veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_veil.color = Color(1, 1, 1, 1)
	_layer.add_child(_veil)
	_card = UI.label("", 26, Color(0.9, 0.92, 1.0))
	_card.set_anchors_preset(Control.PRESET_FULL_RECT)
	_card.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_card.modulate.a = 0.0
	_layer.add_child(_card)
	_hint = UI.label("", 13, Color(0.7, 0.75, 0.85, 0.6))
	_hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_hint.position = Vector2(-220, -36)
	_layer.add_child(_hint)


func ground():
	return main.ground if main != null else null


## The story's settings on the deck for a phase.
func _mode(levels: Dictionary, hide_pilot: bool) -> Dictionary:
	return {"quiet": true, "hide_pilot": hide_pilot, "lift_only": "commercial", "lift_label": "Bar: Dan wants to see you",
		"levels": levels}


func begin() -> void:
	var g = ground()
	if g == null:
		return
	g.input_enabled = false
	g.story_mode = _mode({"clinic": {"bed": BED, "awake": false, "people": [{"who": "dan", "pos": DAN_BED, "dir": 2}, {"who": "doc", "pos": DOC_BED, "dir": 1}]}}, true)
	g.go_level("clinic", "story")
	g.story_cam = BED_CAM * GroundMap.TILE
	_veil.color = Color(1, 1, 1, 1)
	_phase("bed1")


func _phase(p: String) -> void:
	phase = p
	t = 0.0


func _process(delta: float) -> void:
	t += delta
	var g = ground()
	if g == null or not is_instance_valid(g):
		return
	# hold Esc to skip the infirmary's scenes (never the talk in the bar)
	if phase in ["bed1", "talk1", "black1", "wake", "talk2", "black2", "stand"] and (Input.is_key_pressed(KEY_ESCAPE) or Input.is_joy_button_pressed(0, JOY_BUTTON_START)):
		skip_held += delta
		if skip_held >= SKIP_HOLD:
			skip_held = 0.0
			_skip_to_walk()
			return
	else:
		skip_held = maxf(0.0, skip_held - delta * 2.0)
	_hint.text = ("Hold %s to skip" % Pad.glyph("options") if Pad.using_pad else "Hold Esc to skip") if phase in ["bed1", "talk1", "black1", "wake", "talk2", "black2", "stand", "talk3"] else ""
	match phase:
		"bed1":                                  # out of the white onto the bed
			_veil.color = Color(1, 1, 1, 1.0 - clampf(t / 1.8, 0.0, 1.0))
			if t > 2.6:
				_talk("intro_bed", "talk1")
		"talk1":
			if _talk_done():
				_phase("black1")
		"black1":                                # black, "A few weeks later", the pilot wakes
			_veil.color = Color(0, 0, 0, clampf(t / 1.0, 0.0, 1.0))
			_card.text = "A few weeks later"
			_card.modulate.a = clampf((t - 1.2) / 0.8, 0.0, 1.0) * (1.0 - clampf((t - 3.6) / 0.8, 0.0, 1.0))
			if t > 3.0 and not g.story_mode.get("levels", {}).get("clinic", {}).get("awake", false):
				g.story_mode = _mode({"clinic": {"bed": BED, "awake": true, "people": [{"who": "dan", "pos": DAN_BED, "dir": 2}]}}, true)
				g.go_level("clinic", "story")
				g.story_cam = BED_CAM * GroundMap.TILE
			if t > 4.6:
				_phase("wake")
		"wake":
			_veil.color = Color(0, 0, 0, 1.0 - clampf(t / 1.4, 0.0, 1.0))
			if t > 1.8:
				_talk("intro_wake", "talk2")
		"talk2":
			if _talk_done():
				_phase("black2")
		"black2":                                # black, "A few days later", on their feet
			_veil.color = Color(0, 0, 0, clampf(t / 1.0, 0.0, 1.0))
			_card.text = "A few days later"
			_card.modulate.a = clampf((t - 1.2) / 0.8, 0.0, 1.0) * (1.0 - clampf((t - 3.6) / 0.8, 0.0, 1.0))
			if t > 3.0 and g.pilot != null and not g.pilot.visible:
				_standing(g)
			if t > 4.6:
				_phase("stand")
		"stand":
			_veil.color = Color(0, 0, 0, 1.0 - clampf(t / 1.4, 0.0, 1.0))
			if t > 1.6:
				_talk("intro_doc", "talk3")
		"talk3":
			if _talk_done():
				_free_walk(g)
		"walk":                                  # free – the lift to the bar, Dan at the window
			pass
		"talk4":
			if _talk_done():
				_phase("done")
				var tut := bool(GameState.story.flags.get("flight_tutorial", false))
				if tut:
					main._start_intro_five("bar")             # sequence 5: the flight training (scripts/ground/intro_five.gd)
				else:
					# Luz: straight on – Dan has more to talk about; the prologue's last step, "Talk to Dan" (sequence 6)
					GameState.story.goto_step("prologue", 3)
					main._start_intro_six("bar")
				finished.emit()
				queue_free()


## The pilot on their feet beside the bed, the medic with them.
func _standing(g) -> void:
	g.story_mode = _mode({"clinic": {"people": [{"who": "doc", "pos": DOC_STAND, "dir": 2, "talk": true}], "spawn": STAND},
		"commercial": {"people": [{"who": "dan", "pos": WINDOW, "dir": 1, "marker": "!"}]}}, false)
	g.go_level("clinic", "story")
	g.pilot.dir = 3
	g.story_cam = (STAND + Vector2(0.8, 2.0)) * GroundMap.TILE


func _free_walk(g) -> void:
	_phase("walk")
	_veil.color = Color(0, 0, 0, 0)
	_card.modulate.a = 0.0
	g.story_cam = Vector2.INF
	g.input_enabled = true
	GameState.story.set_flag("intro_stage", "four_walk")
	if not GameState.story.running("prologue") and not GameState.story.done.has("prologue"):
		GameState.story.start("prologue")              # Luz: "talk to Dan in the bar" – in the tracker and the journal
	if not g.story_talk.is_connected(_on_story_talk):
		g.story_talk.connect(_on_story_talk)


## Esc held: straight to walking about (the scenes in the infirmary skipped).
func _skip_to_walk() -> void:
	var g = ground()
	if main != null and main.story_ui != null and main.story_ui.dialogue != null:
		main.story_ui._close_dialogue()
		main.story_ui._dlg_q.clear()
	_waiting = ""
	_standing(g)
	_free_walk(g)


func _on_story_talk(who: String) -> void:
	if who == "dan" and phase == "walk":
		_talk("intro_dan_bar", "talk4")
	elif who == "doc" and phase == "walk":
		GameState.story.show.emit("dialogue", {"id": "intro_doc_again", "mission": ""})     # Luz: she can be asked again


func _talk(id: String, next: String) -> void:
	_waiting = id
	GameState.story.show.emit("dialogue", {"id": id, "mission": ""})
	_phase(next)


func _talk_done() -> bool:
	if main == null or main.story_ui == null:
		return true
	return main.story_ui.dialogue == null and main.story_ui._dlg_q.is_empty()
