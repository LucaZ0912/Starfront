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
var _por: TextureRect                   # package 56: kept, so the speaker can change (the pilot answering)
var _frame: PanelContainer


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
	_frame = frame
	var por := TextureRect.new()
	_por = por
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


## Package 56: someone else speaks now – the portrait, the name and the frame's colour change.
func set_speaker(tex: Texture2D, who: String, sub: String, col: Color) -> void:
	if _por != null:
		_por.texture = tex
	if _name != null:
		_name.text = who
		_name.add_theme_color_override("font_color", col)
	if _sub != null:
		_sub.text = sub
	if _frame != null:
		var sb := (_frame.get_theme_stylebox("panel") as StyleBoxFlat).duplicate() as StyleBoxFlat
		sb.border_color = Color(col, 0.9)
		sb.shadow_color = Color(col, 0.35)
		_frame.add_theme_stylebox_override("panel", sb)


var _cont := Callable()                 # package 56 (Luz): a line without answers – a press (✕, click, E) goes on


## Says a line; options: [[label, Callable], …] – your possible answers; or none and `cont`, called on a press.
func say(text: String, options: Array, cont: Callable = Callable()) -> void:
	_text.text = text
	_text.visible_characters = 0
	_shown = 0.0
	_options = options
	_cont = cont
	UI.clear(_choices)
	for i in options.size():
		var o: Array = options[i]
		var b := UI.button("%d.  %s" % [i + 1, o[0]], o[1])
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if o.size() > 2:
			b.add_theme_color_override("font_color", o[2])        # package 56: an answer that moves the story on (gold)
			b.add_theme_color_override("font_hover_color", (o[2] as Color).lightened(0.25))
		_choices.add_child(b)
	_choice_panel.visible = false
	_hint.text = ""


func _process(delta: float) -> void:
	if _text == null:
		return
	if _text.visible_characters >= 0 and _text.visible_characters < _text.text.length():
		var before := int(_shown)
		_shown += delta * TYPE_SPEED
		_text.visible_characters = int(_shown)
		# package 56 (Luz): the soft tick while someone speaks – as in the intro's scenes
		for ci in range(before, mini(int(_shown), _text.text.length())):
			if ci % 2 == 0 and _text.text[ci] != " ":
				Audio.play("ui_type", "", -10.0, 0.08)
				break
	else:
		_finish()


func _finish() -> void:
	_text.visible_characters = -1
	if _cont.is_valid():
		_hint.text = ("%s go on" % Pad.glyph("cross")) if Pad.using_pad else "Click, E or Space: go on"
		return
	if not _choice_panel.visible:
		_choice_panel.visible = true
		_hint.text = ("%s answer  •  %s leave" % [Pad.glyph("cross"), Pad.glyph("circle")]) if Pad.using_pad else "1–%d answer  •  Esc leave" % _options.size()


func is_typing() -> bool:
	return _text.visible_characters >= 0 and _text.visible_characters < _text.text.length()


func _go_on() -> void:
	var c := _cont
	_cont = Callable()
	c.call()


## Picks answer i (0-based) – also for the smoke test (a line without answers: goes on).
func choose(i: int) -> void:
	if _cont.is_valid():
		_finish()
		_go_on()
		return
	if i >= 0 and i < _options.size():
		_finish()
		(_options[i][1] as Callable).call()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event.is_pressed() or event.is_echo():
		return
	if event.is_action_pressed("interact") or (event is InputEventKey and (event as InputEventKey).keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]):
		get_viewport().set_input_as_handled()
		if _cont.is_valid() and not is_typing():
			_go_on()
		else:
			_finish()
		return
	if event is InputEventKey:
		var k := (event as InputEventKey).keycode
		if k >= KEY_1 and k <= KEY_9:
			get_viewport().set_input_as_handled()
			choose(int(k - KEY_1))


## Package 56: a click goes on (a line without answers) – or shows the whole line at once.
func _input(event: InputEvent) -> void:
	if not visible or not _cont.is_valid():
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		if is_typing():
			_finish()
		else:
			_go_on()


## Package 80: the controller – ✕ while the words come shows them at once; then the answers by the menus' rules.
func pad_button(b: String, pressed: bool) -> bool:
	if b == "cross" and pressed and is_typing():
		_finish()
		return true
	if b == "cross" and pressed and _cont.is_valid():
		_go_on()                                      # package 56: a line without answers – on
		return true
	return false


func close() -> void:
	closed.emit()
	queue_free()
