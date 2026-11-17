extends CanvasLayer
## Package 56 – the intro, sequence 3 (Luz): still in the dark, ceiling lights pass from the bottom to the top – the
## pilot on a stretcher, rushed down a corridor of Dan's station; the medic speaks; the lights go faster; white-out.
## Then the character creator follows as the medical scanner. On its own timing (no clicks); hold Esc to skip.

signal finished

const Story = preload("res://scripts/core/story.gd")
const StoryData = preload("res://data/story.gd")

const STEPS := [
	{"look": "dark", "hold": 1.4},
	{"look": "lights", "who": "doc", "text": "We have to hurry if we want to save this one.", "delay": 1.6},
	{"look": "lights", "who": "doc", "text": "Full body scan, facial reconstruction – and all physical and mental data.", "delay": 0.6},
	{"look": "white", "hold": 1.8},
]
const TYPE_RATE := 32.0
const SKIP_HOLD := 1.2

var step := -1
var t := 0.0
var total := 0.0
var typed := 0.0
var line_done_at := -1.0
var box_a := 0.0
var skip_held := 0.0
var ending := false
var _done := false
var _vs := Vector2(1600, 900)
var _scene: Node2D
var _box: Node2D
var _white: ColorRect
var speed := 0.0                          # how fast the ceiling passes (px a second)
var scroll := 0.0
var light_a := 0.0                        # the lights fade in out of the dark
var ticks := 0                            # typing ticks played (the smoke test)


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_vs = get_viewport().get_visible_rect().size
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	_scene = Node2D.new()
	_scene.draw.connect(_draw_scene)
	add_child(_scene)
	_box = Node2D.new()
	_box.draw.connect(_draw_box)
	add_child(_box)
	_white = ColorRect.new()
	_white.color = Color(1, 1, 1, 0)
	_white.set_anchors_preset(Control.PRESET_FULL_RECT)
	_white.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_white)
	_next()


func _next() -> void:
	step += 1
	t = 0.0
	typed = 0.0
	line_done_at = -1.0
	box_a = 0.0
	if step >= STEPS.size():
		_end()


func _end() -> void:
	if ending:
		return
	ending = true
	_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	finished.emit()
	queue_free()


func skip() -> void:
	step = STEPS.size()
	_end()


## How long a line stays once it is all there.
static func read_time(n: int) -> float:
	return 2.4 + n * 0.04


func _process(delta: float) -> void:
	_vs = get_viewport().get_visible_rect().size
	if Input.is_key_pressed(KEY_ESCAPE) or Input.is_joy_button_pressed(0, JOY_BUTTON_START):
		skip_held += delta
		if skip_held >= SKIP_HOLD and not ending:
			skip()
	else:
		skip_held = maxf(0.0, skip_held - delta * 2.0)
	step_time(delta)


func step_time(delta: float) -> void:
	t += delta
	total += delta
	if ending or step >= STEPS.size():
		return
	var sd: Dictionary = STEPS[step]
	if sd.has("text"):
		if t >= float(sd.get("delay", 0.6)):
			box_a = minf(1.0, box_a + delta * 3.0)
			var n := String(sd["text"]).length()
			if typed < n:
				var before := int(typed)
				typed = minf(n, typed + delta * TYPE_RATE)
				for ci in range(before, int(typed)):
					if ci % 2 == 0 and String(sd["text"])[ci] != " ":
						Audio.play("ui_type", "", -10.0, 0.08)        # someone speaks: the soft tick
						ticks += 1
						break
				if typed >= n:
					line_done_at = t
			elif line_done_at >= 0.0 and t - line_done_at > read_time(n):
				_next()
				return
	elif t >= float(sd.get("hold", 1.0)):
		_next()
		return
	# the corridor: the lights come up out of the dark and go faster with each line
	match String(sd["look"]):
		"dark":
			speed = 160.0
		"lights":
			light_a = minf(1.0, light_a + delta / 1.5)
			speed = lerpf(speed, 260.0 if step == 1 else 520.0, delta * 0.8)
		"white":
			speed = lerpf(speed, 700.0, delta)
			_white.color.a = clampf(t / 1.2, 0.0, 1.0)
	scroll += speed * delta
	_scene.queue_redraw()
	_box.queue_redraw()


## The ceiling seen from the stretcher: light panels sliding up, a glow round each, a little smear with speed.
func _draw_scene() -> void:
	var w := _vs.x
	var h := _vs.y
	var gap := h * 0.24
	var cx := w * 0.5
	var pw := minf(400.0, w * 0.28)
	var smear := speed * 0.05
	var n := int(h / gap) + 3
	for i in n:
		var y := fposmod(h - (i * gap + scroll), gap * n) - gap
		var edge := clampf(1.0 - absf(y - h * 0.5) / (h * 0.62), 0.0, 1.0)
		var a := light_a * (0.35 + 0.65 * edge)
		for g in 6:
			_scene.draw_rect(Rect2(cx - pw * 0.58 - g * 26, y - 30 - g * 14, pw * 1.16 + g * 52, 60 + g * 28 + smear), Color(0.75, 0.9, 1.0, 0.035 * a))
		_scene.draw_rect(Rect2(cx - pw * 0.5, y - 14, pw, 28 + smear), Color(0.85, 0.95, 1.0, 0.55 * a))
		_scene.draw_rect(Rect2(cx - pw * 0.47, y - 8, pw * 0.94, 16 + smear * 0.8), Color(1, 1, 1, 0.8 * a))
	# the corridor's walls, dark at the edges
	for x in 140:
		var c := Color(0, 0, 0, 1.0 - x / 140.0)
		_scene.draw_rect(Rect2(x, 0, 1, h), c)
		_scene.draw_rect(Rect2(w - 1 - x, 0, 1, h), c)


func _draw_box() -> void:
	var f := ThemeDB.fallback_font
	var hint := "Hold %s to skip" % Pad.glyph("options") if Pad.using_pad else "Hold Esc to skip"
	var ha := 0.35 + 0.65 * clampf(skip_held / SKIP_HOLD, 0.0, 1.0)
	_box.draw_string(f, Vector2(_vs.x - 210, _vs.y - 22), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.7, 0.75, 0.85, ha * 0.7))
	if ending or step < 0 or step >= STEPS.size() or box_a <= 0.0:
		return
	var sd: Dictionary = STEPS[step]
	if not sd.has("text"):
		return
	var who := String(sd["who"])
	var c: Dictionary = StoryData.CHARACTERS.get(who, {})
	var col: Color = c.get("col", Color(0.55, 0.85, 1.0))
	var a := box_a
	var bw := minf(1120.0, _vs.x - 60.0)
	var r := Rect2(_vs.x * 0.5 - bw * 0.5, _vs.y - 200.0, bw, 150.0)
	_box.draw_rect(r, Color(0.02, 0.03, 0.06, 0.92 * a))
	_box.draw_rect(r, Color(col, 0.9 * a), false, 2.0)
	var pr := Rect2(r.position + Vector2(16, 15), Vector2(120, 120))
	_box.draw_texture_rect(Story.portrait_of(who), pr, false, Color(1, 1, 1, a))
	_box.draw_rect(pr, Color(col, 0.8 * a), false, 2.0)
	var x0 := pr.end.x + 24.0
	var y := r.position.y + 40.0
	var nm := String(c.get("name", who)).to_upper()
	if c.has("sub"):
		nm += "  ·  " + String(c["sub"]).to_upper()
	_box.draw_string(f, Vector2(x0, y), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(col, a))
	y += 30.0
	var text := String(sd["text"]).substr(0, int(typed))
	var line := ""
	for w in text.split(" "):
		var tst := (line + " " + w).strip_edges()
		if f.get_string_size(tst, HORIZONTAL_ALIGNMENT_LEFT, -1, 21).x > r.end.x - x0 - 30.0 and line != "":
			_box.draw_string(f, Vector2(x0, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color(0.93, 0.95, 1.0, a))
			y += 28.0
			line = w
		else:
			line = tst
	_box.draw_string(f, Vector2(x0, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color(0.93, 0.95, 1.0, a))


func _input(event: InputEvent) -> void:
	# on its own timing – nothing clicks a line away; Esc is held to skip, never the pause menu
	if event is InputEventMouseButton or (event is InputEventKey and event.keycode in [KEY_ESCAPE, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]):
		get_viewport().set_input_as_handled()
