class_name DialogueView
extends Control
## Package 49 (0.7.49.7, after Luz's mockup): a conversation – the one you talk to large on the left (portrait in a
## frame), what they say in the box along the bottom, typed out, and your answers in a box above it on the right.
## Meant for every conversation to come (Teil 8: story, quests); for now the crew in the bar. Keys: 1–9 pick an
## answer, E / Space show the whole line at once.

signal closed

const PilotArt = preload("res://scripts/core/pilot_art.gd")
const TYPE_SPEED := 55.0             # characters per second

var _name: Label
var _sub: Label
var _text: Label
var _choices: VBoxContainer
var _choice_panel: PanelContainer
var _options: Array = []
var _shown := 0.0
var _hint: Label
var portrait_tex: Texture2D = null      # 0.7.53.30 (Luz): a thing's picture instead of a face (the Museum's cases)


func open(look: Dictionary, who: String, sub: String, col: Color) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.35)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	# the one you talk to: a big framed portrait, bottom left
	var frame := UI.neon_panel(Color(col, 0.9), Color(0.03, 0.03, 0.06, 0.97), 3)
	frame.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	frame.offset_left = 40
	frame.offset_right = 40 + 300
	frame.offset_top = -40 - 330
	frame.offset_bottom = -40
	add_child(frame)
	var por := TextureRect.new()
	por.texture = portrait_tex if portrait_tex != null else PilotArt.portrait(look)
	por.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	por.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	por.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	por.custom_minimum_size = Vector2(290, 320)
	frame.add_child(por)
	# what they say: the box along the bottom
	var box := UI.neon_panel(Color(0.85, 0.88, 0.95, 0.7), Color(0.02, 0.02, 0.04, 0.95), 2)
	box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	box.offset_left = 360
	box.offset_right = -40
	box.offset_top = -40 - 170
	box.offset_bottom = -40
	add_child(box)
	var bv := UI.vbox(6)
	box.add_child(bv)
	var nr := UI.hbox(10)
	bv.add_child(nr)
	_name = UI.label(who, 20, col)
	nr.add_child(_name)
	_sub = UI.label(sub, 14, UI.TEXT_DIM)
	nr.add_child(_sub)
	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_font_size_override("font_size", 18)
	_text.add_theme_color_override("font_color", Color(0.94, 0.95, 1.0))
	_text.custom_minimum_size = Vector2(600, 90)
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bv.add_child(_text)
	_hint = UI.label("", 11, UI.TEXT_DIM)
	bv.add_child(_hint)
	# your answers: a box above it, on the right
	_choice_panel = UI.neon_panel(Color(0.35, 0.55, 1.0, 0.9), Color(0.03, 0.04, 0.1, 0.95), 2)
	_choice_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_choice_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_choice_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_choice_panel.offset_right = -40
	_choice_panel.offset_bottom = -40 - 170 - 14
	_choice_panel.offset_left = -40 - 340
	_choice_panel.offset_top = -40 - 170 - 14 - 60
	add_child(_choice_panel)
	_choices = UI.vbox(4)
	_choices.custom_minimum_size = Vector2(320, 0)
	_choice_panel.add_child(_choices)


## Says a line; options: [[label, Callable], …] – your possible answers.
func say(text: String, options: Array) -> void:
	_text.text = text
	_text.visible_characters = 0
	_shown = 0.0
	_options = options
	UI.clear(_choices)
	for i in options.size():
		var o: Array = options[i]
		var b := UI.button("%d.  %s" % [i + 1, o[0]], o[1])
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_choices.add_child(b)
	_choice_panel.visible = false
	_hint.text = ""


func _process(delta: float) -> void:
	if _text == null:
		return
	if _text.visible_characters >= 0 and _text.visible_characters < _text.text.length():
		_shown += delta * TYPE_SPEED
		_text.visible_characters = int(_shown)
	else:
		_finish()


func _finish() -> void:
	_text.visible_characters = -1
	if not _choice_panel.visible:
		_choice_panel.visible = true
		_hint.text = "1–%d answer  •  Esc leave" % _options.size()


func is_typing() -> bool:
	return _text.visible_characters >= 0 and _text.visible_characters < _text.text.length()


## Picks answer i (0-based) – also for the smoke test.
func choose(i: int) -> void:
	if i >= 0 and i < _options.size():
		_finish()
		(_options[i][1] as Callable).call()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event.is_pressed() or event.is_echo():
		return
	if event.is_action_pressed("interact") or (event is InputEventKey and (event as InputEventKey).keycode == KEY_SPACE):
		get_viewport().set_input_as_handled()
		_finish()
		return
	if event is InputEventKey:
		var k := (event as InputEventKey).keycode
		if k >= KEY_1 and k <= KEY_9:
			get_viewport().set_input_as_handled()
			choose(int(k - KEY_1))


func close() -> void:
	closed.emit()
	queue_free()
