extends CanvasLayer
## Timing game of the warp interdictor (phase 0.5 package 11). A marker bounces left and right
## on a bar; press the hit key (default E) or click while it is inside the green window. Enough
## hits before the time runs out pull the target out of warp; too many misses let it escape.
## Bigger hulls are harder: narrower window, faster marker, more hits needed.

signal finished(success: bool)

const DIFF := {
	1: {"zone": 0.15, "speed": 1.0, "hits": 2, "name": "small hull"},
	2: {"zone": 0.105, "speed": 1.35, "hits": 3, "name": "medium hull"},
	3: {"zone": 0.075, "speed": 1.7, "hits": 3, "name": "large hull"},
}
const MAX_MISSES := 2
const TIME_LIMIT := 14.0
const SPEEDUP := 1.15          # the marker gets faster after every hit
const BAR := Vector2(440, 30)

var target_name := ""
var size := 1
var duration := 10.0
var zone_w := 0.2
var speed := 1.0
var need := 2

var _t := 0.0
var _x := 0.0
var _dir := 1.0
var _zone := 0.5
var _hits := 0
var _misses := 0
var _flash := 0.0
var _flash_col := Color.WHITE
var _done := false
var _panel: PanelContainer
var _canvas: Control
var _info: Label
var _title: Label


func setup(p_name: String, p_size: int, p_duration: float, zone_bonus: float = 0.0) -> void:
	target_name = p_name
	size = clampi(p_size, 1, 3)
	duration = p_duration
	var d: Dictionary = DIFF[size]
	zone_w = float(d["zone"]) + zone_bonus
	speed = float(d["speed"])
	need = int(d["hits"])


func _ready() -> void:
	layer = 25
	_zone = randf_range(zone_w, 1.0 - zone_w)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_panel = UI.panel(Color(0.03, 0.05, 0.1, 0.94))
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = -BAR.x * 0.5 - 18
	_panel.offset_right = BAR.x * 0.5 + 18
	_panel.offset_top = -290
	_panel.offset_bottom = -150
	root.add_child(_panel)
	var v := UI.vbox(6)
	_panel.add_child(v)
	_title = UI.label("WARP INTERDICTION – %s (%s)" % [target_name, DIFF[size]["name"]], 14, UI.ACCENT)
	v.add_child(_title)
	_canvas = Control.new()
	_canvas.custom_minimum_size = BAR + Vector2(0, 16)
	_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	_canvas.draw.connect(_draw_bar)
	_canvas.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_hit())
	v.add_child(_canvas)
	_info = UI.label("", 12, UI.TEXT_DIM)
	v.add_child(_info)


func _process(delta: float) -> void:
	if _done:
		return
	_t += delta
	_x += _dir * speed * delta
	if _x >= 1.0:
		_x = 1.0
		_dir = -1.0
	elif _x <= 0.0:
		_x = 0.0
		_dir = 1.0
	_flash = maxf(0.0, _flash - delta)
	_info.text = "Press [%s] or click when the marker is in the green window  •  hits %d/%d  •  misses %d/%d  •  %d s" % [
		Keybinds.key_text("interdict_hit"), _hits, need, _misses, MAX_MISSES, int(ceil(maxf(duration - _t, 0.0)))]
	_canvas.queue_redraw()
	if _t >= duration:
		_end(false)


func _input(event: InputEvent) -> void:
	if _done:
		return
	if event.is_action_pressed("interdict_hit") and not event.is_echo():
		_hit()
		get_viewport().set_input_as_handled()


func _hit() -> void:
	if _done:
		return
	if absf(_x - _zone) <= zone_w * 0.5:
		_hits += 1
		speed *= SPEEDUP
		_flash = 0.35
		_flash_col = Color(0.35, 1.0, 0.5)
		if _hits >= need:
			_end(true)
			return
		_zone = randf_range(zone_w, 1.0 - zone_w)
	else:
		_misses += 1
		_flash = 0.35
		_flash_col = Color(1.0, 0.3, 0.3)
		if _misses >= MAX_MISSES:
			_end(false)


func _end(success: bool) -> void:
	if _done:
		return
	_done = true
	_title.text = "TARGET PULLED OUT OF WARP!" if success else "TARGET ESCAPED"
	_title.add_theme_color_override("font_color", Color(0.35, 1.0, 0.5) if success else Color(1.0, 0.35, 0.3))
	_canvas.queue_redraw()
	var tw := create_tween()
	tw.tween_interval(1.2)
	tw.tween_callback(func(): finished.emit(success))


func _draw_bar() -> void:
	var o := Vector2(0, 8)
	_canvas.draw_rect(Rect2(o, BAR), Color(0.08, 0.1, 0.16))
	# time left as a thin strip under the bar
	var left := clampf(1.0 - _t / maxf(duration, 0.01), 0.0, 1.0)
	_canvas.draw_rect(Rect2(o + Vector2(0, BAR.y + 3), Vector2(BAR.x * left, 3)), Color(0.4, 0.75, 1.0, 0.8))
	var zx := (_zone - zone_w * 0.5) * BAR.x
	_canvas.draw_rect(Rect2(o + Vector2(zx, 0), Vector2(zone_w * BAR.x, BAR.y)), Color(0.25, 0.9, 0.45, 0.55))
	_canvas.draw_rect(Rect2(o + Vector2(zx, 0), Vector2(zone_w * BAR.x, BAR.y)), Color(0.4, 1.0, 0.6), false, 2.0)
	var mx := _x * BAR.x
	_canvas.draw_rect(Rect2(o + Vector2(mx - 3, -5), Vector2(6, BAR.y + 10)), Color.WHITE)
	if _flash > 0.0:
		_canvas.draw_rect(Rect2(o, BAR), Color(_flash_col, _flash * 1.4), false, 3.0)
	_canvas.draw_rect(Rect2(o, BAR), Color(0.5, 0.6, 0.8), false, 1.0)
