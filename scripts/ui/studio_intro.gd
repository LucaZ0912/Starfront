extends Node
## Studio intro "dlirius games": the animated d (assets/intro, made from dlirius/games.gif) on black –
## a laser shot for every colour bar that flies in – then "dlirius games" in silver with two brackets
## above it, as wide apart as the lettering. A click makes the brackets slam together around the d
## (hammer on iron). Any key skips the intro, a second click too. Then the main menu.

const MENU := "res://scenes/menu.tscn"
const SHEET := preload("res://assets/intro/dlirius_sheet.png")
const LASER := preload("res://assets/intro/laser.wav")
const HAMMER := preload("res://assets/intro/hammer.wav")
const FRAMES := 55
const COLS := 11
const FW := 320
const FRAME_TIME := 0.1
const SHOTS := [8, 10, 14, 16, 19, 22, 25, 28, 31, 34, 37, 40, 42, 44]   # a colour bar starts flying in
const D_BOX := Rect2(80, 30, 140, 270)          # the finished d inside a frame (x, y, w, h)
const SCALE := 1.6
const SILVER := Color(0.76, 0.78, 0.82)
const LEAD_IN := 0.5
const HOLD_OPEN := 4.0                           # without a click: how long the title stays
const HOLD_CLOSED := 1.8                         # after the brackets slammed shut

var auto_skip := true                            # false in tests: no automatic jump to the menu
var root: Control
var anim: TextureRect
var atlas: AtlasTexture
var title: Label
var left_b: Label
var right_b: Label
var laser_players: Array = []
var hammer_player: AudioStreamPlayer
var t := 0.0
var frame := -1
var phase := "anim"                              # anim → title → closing → closed → out
var closed := false
var _out_t := -1.0
var _shake := 0.0
var _left_open := 0.0
var _right_open := 0.0
var _left_shut := 0.0
var _right_shut := 0.0


func _ready() -> void:
	if auto_skip and ("--smoketest" in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless"):
		_to_menu.call_deferred()
		return
	_build()


func _build() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)
	atlas = AtlasTexture.new()
	atlas.atlas = SHEET
	atlas.region = Rect2(0, 0, FW, FW)
	anim = TextureRect.new()
	anim.texture = atlas
	anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	anim.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	anim.stretch_mode = TextureRect.STRETCH_SCALE
	anim.size = Vector2(FW, FW) * SCALE
	anim.modulate.a = 0.0
	anim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(anim)
	title = _label("dlirius games", 64)
	title.modulate.a = 0.0
	left_b = _label("(", 380)
	right_b = _label(")", 380)
	left_b.modulate.a = 0.0
	right_b.modulate.a = 0.0
	for i in 3:
		var lp := AudioStreamPlayer.new()
		lp.stream = LASER
		lp.volume_db = -6.0
		add_child(lp)
		laser_players.append(lp)
	hammer_player = AudioStreamPlayer.new()
	hammer_player.stream = HAMMER
	add_child(hammer_player)
	_layout.call_deferred()


func _label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", SILVER)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("shadow_offset_y", 3)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(l)
	return l


## Places the animation in the middle, the title below, the brackets at the ends of the title –
## and works out where they end up: tight around the d.
func _layout() -> void:
	var vs: Vector2 = root.get_viewport_rect().size
	var anim_pos := Vector2((vs.x - anim.size.x) / 2.0, vs.y * 0.44 - anim.size.y / 2.0)
	anim.position = anim_pos
	var title_size := title.get_combined_minimum_size()
	title.size = title_size
	title.position = Vector2((vs.x - title_size.x) / 2.0, anim_pos.y + anim.size.y + 10.0)
	var bsize := left_b.get_combined_minimum_size()
	left_b.size = bsize
	right_b.size = right_b.get_combined_minimum_size()
	var d_left := anim_pos.x + D_BOX.position.x * SCALE
	var d_right := anim_pos.x + D_BOX.end.x * SCALE
	var d_mid_y := anim_pos.y + (D_BOX.position.y + D_BOX.size.y / 2.0) * SCALE
	var by := d_mid_y - bsize.y / 2.0
	_left_open = title.position.x - bsize.x * 0.5
	_right_open = title.position.x + title_size.x - right_b.size.x * 0.5
	_left_shut = d_left - bsize.x * 0.95
	_right_shut = d_right - right_b.size.x * 0.05
	left_b.position = Vector2(_left_open, by)
	right_b.position = Vector2(_right_open, by)


func _process(delta: float) -> void:
	if root == null:
		return
	t += delta
	match phase:
		"anim":
			anim.modulate.a = clampf((t - LEAD_IN * 0.4) / 0.3, 0.0, 1.0)
			var f := clampi(int((t - LEAD_IN) / FRAME_TIME), -1, FRAMES - 1)
			while frame < f:
				frame += 1
				_show_frame(frame)
				if frame in SHOTS:
					_laser()
			if frame >= FRAMES - 1 and t > LEAD_IN + FRAMES * FRAME_TIME + 0.2:
				_start_title()
		"title":
			var a := clampf((t - _title_t) / 0.8, 0.0, 1.0)
			title.modulate.a = a
			left_b.modulate.a = a
			right_b.modulate.a = a
			if auto_skip and t - _title_t > HOLD_OPEN:
				_fade_out()
		"closed":
			if auto_skip and t - _closed_t > HOLD_CLOSED:
				_fade_out()
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 3.0)
		root.position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 10.0 * _shake
	else:
		root.position = Vector2.ZERO
	if _out_t >= 0.0:
		_out_t += delta
		root.modulate.a = 1.0 - clampf(_out_t / 0.7, 0.0, 1.0)
		if _out_t >= 0.75 and auto_skip:
			_to_menu()


var _title_t := 0.0
var _closed_t := 0.0


func _show_frame(i: int) -> void:
	atlas.region = Rect2((i % COLS) * FW, (i / COLS) * FW, FW, FW)


var shots_fired := 0


func _laser() -> void:
	shots_fired += 1
	for lp in laser_players:
		if not lp.playing:
			lp.pitch_scale = randf_range(0.94, 1.06)
			lp.play()
			return
	laser_players[0].play()


func _start_title() -> void:
	phase = "title"
	_title_t = t


## The brackets slam together around the d – hammer on iron.
func close_brackets() -> void:
	if closed:
		return
	closed = true
	if phase == "anim":
		frame = FRAMES - 1
		_show_frame(frame)
		anim.modulate.a = 1.0
	title.modulate.a = 1.0
	left_b.modulate.a = 1.0
	right_b.modulate.a = 1.0
	phase = "closing"
	var tw := create_tween().set_parallel(true)
	tw.tween_property(left_b, "position:x", _left_shut, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(right_b, "position:x", _right_shut, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(_slammed)


func _slammed() -> void:
	hammer_player.play()
	_shake = 1.0
	phase = "closed"
	_closed_t = t
	for b in [left_b, right_b]:
		b.modulate = Color(1.6, 1.6, 1.7)
		create_tween().tween_property(b, "modulate", Color.WHITE, 0.5)


func _fade_out() -> void:
	if _out_t < 0.0:
		phase = "out"
		_out_t = 0.0


func _input(event: InputEvent) -> void:
	if root == null or _out_t >= 0.0:
		return
	if event is InputEventMouseButton and event.pressed:
		if not closed:
			close_brackets()
		elif phase == "closed":
			_fade_out()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		_fade_out()
		get_viewport().set_input_as_handled()


func _to_menu() -> void:
	if is_inside_tree():
		get_tree().change_scene_to_file(MENU)
