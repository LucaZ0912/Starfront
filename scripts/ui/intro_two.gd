extends CanvasLayer
## Package 56 – the intro, sequence 2 (Luz): Beyond. The camera pans through a wreck field (the Gold Fleet's giants
## behind, wreck colossi, scrap), a violet portal tears open, spits violet sparks, then the Earthworks 190SL – burning,
## spinning; the pilot's Mayday; the camera pulls back and the ship's computer speaks (a hologram). Black. Dan's ship –
## a Kanayama-maru in his rust colours – comes through the debris, finds her, a life sign on board; the tractor beam
## pulls her out of the picture. Black. The lines follow the scene's own timing (Luz: not to be clicked away, a calm
## pace); hold Esc (Options/Start) to skip the whole sequence.

signal finished

const Story = preload("res://scripts/core/story.gd")
const StoryData = preload("res://data/story.gd")

## The steps: the scene's state ("look"), who speaks (""= nobody; "pilot" = the pilot's radio, no picture), the line,
## `hold` – seconds a step without a line lasts, `delay` – seconds before its line comes.
const STEPS := [
	{"look": "pan", "hold": 6.4},
	{"look": "portal", "hold": 3.6},
	{"look": "ejected", "who": "pilot", "text": "Mayday… please… I need help… the oxygen is running low…", "delay": 2.6},
	{"look": "computer", "who": "ship_ai", "text": "Pilot unconscious. Activating emergency protocol. Emergency life support online. Time remaining: 9 minutes 55 seconds.", "delay": 1.2},
	{"look": "black", "hold": 1.6},
	{"look": "dan", "who": "dan", "text": "Somewhere around here – that's where that strange signal came from…", "delay": 2.4},
	{"look": "approach", "who": "dan", "text": "Oh wow – that's an almost completely intact classic!", "delay": 4.0},
	{"look": "approach", "who": "ship_ai", "text": "One life sign registered on board.", "delay": 0.8},
	{"look": "approach", "who": "dan", "text": "What!? That can't be one of my crew! And I've got no pirate ships on my scope.", "delay": 0.6},
	{"look": "approach", "who": "ship_ai", "text": "Wreck life-support limit reached in 4 minutes and 30 seconds.", "delay": 0.8},
	{"look": "tow", "who": "dan", "text": "Oh damn. Well then – let's tow this old crate to the station.", "delay": 0.8},
	{"look": "away", "hold": 4.8},
]
const TYPE_RATE := 32.0                     # Luz: calm, about a fifth quicker than first tried
const SKIP_HOLD := 1.2
const PORTAL := Vector2(1560, 760)         # in the field's own coordinates
const REST := Vector2(1260, 860)           # where the 190SL drifts when Dan comes

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
var _far: Node2D                          # the giants far behind (parallax)
var _world: Node2D                        # the field, the portal, the ships – moved and scaled by the camera
var _box: Node2D
var _black: ColorRect
var cam := Vector2(700, 700)
var zoom := 1.0
var _tex := {}
var _pieces: Array = []                   # [texture, pos, angle, scale]
var _scrap: Array = []
var _sparks: Array = []                   # violet sparks from the portal: [pos, vel, life]
var _fire: Array = []                     # fire and smoke of the 190SL: [pos, vel, life, kind]
var portal_k := 0.0                       # 0 shut … 1 open
var sl_pos := PORTAL
var sl_vel := Vector2.ZERO
var sl_ang := 0.0
var sl_spin := 0.0
var sl_on := false
var dan_pos := Vector2(200, 640)
var dan_on := false
var beam := 0.0
const ALARM_VOL := 0.2                     # Luz: quieter, less tiring
var alarm_vol := 0.0
var dan_vol := 0.0


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_vs = get_viewport().get_visible_rect().size
	var bg := ColorRect.new()
	bg.color = Color(0.012, 0.014, 0.03)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)        # follows the window when it is resized (Luz)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	_far = Node2D.new()
	_far.draw.connect(_draw_far)
	add_child(_far)
	_world = Node2D.new()
	_world.draw.connect(_draw_world)
	add_child(_world)
	_black = ColorRect.new()
	_black.color = Color(0, 0, 0, 1)
	_black.set_anchors_preset(Control.PRESET_FULL_RECT)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_black)
	_box = Node2D.new()                      # over the black: the lines stay readable while the picture goes dark
	_box.draw.connect(_draw_box)
	add_child(_box)
	_build()
	Audio.loop("intro_amb", "amb_space", true, 0.6)
	_next()


func _exit_tree() -> void:
	Audio.loop("intro_amb", "amb_space", false)
	Audio.loop("intro_fire", "alarm_hull", false)
	Audio.loop("intro_dan", "engine_loop", false)


## The pictures and the field.
func _build() -> void:
	_tex["giant"] = StationArt.build({"art": "gold_colossus", "tier": 2, "seed": 2 + 4 * 11})["texture"]
	_tex["giant2"] = StationArt.build({"art": "gold_colossus", "tier": 3, "seed": 0 + 4 * 5})["texture"]
	_tex["sl"] = StationArt.build({"art": "gold_ship_small", "tier": 2, "seed": 0})["texture"]
	_tex["dan"] = PixelArt.rust_texture("kanayama")
	var rng := RandomNumberGenerator.new()
	rng.seed = 5657
	for pc in [[0, Vector2(380, 360), 0.5, 0.8], [5, Vector2(1880, 1180), -1.1, 0.95], [10, Vector2(820, 1260), 2.2, 0.65],
			[7, Vector2(2300, 420), 0.9, 0.7]]:
		var tx: Texture2D = StationArt.build({"art": "wreck_piece", "tier": 1 + int(pc[0]) % 3, "seed": int(pc[0])})["texture"]
		_pieces.append([tx, pc[1], pc[2], pc[3]])
	for i in 70:
		var tx2: Texture2D = PixelArt.scrap_sprite(30 + i % 6, rng.randi_range(18, 34), ["iron_ore", "copper_ore", "nickel_ore"][i % 3])
		_scrap.append([tx2, Vector2(rng.randf_range(-200, 2800), rng.randf_range(0, 1700)), rng.randf() * TAU, rng.randf_range(-0.2, 0.2)])


# ---------------------------------------------------------------- steps

func _next() -> void:
	step += 1
	t = 0.0
	typed = 0.0
	line_done_at = -1.0
	box_a = 0.0
	if step >= STEPS.size():
		_end()
		return
	match String(STEPS[step]["look"]):
		"portal":
			Audio.play("gate_activate", "intro", -2.0)
		"ejected":
			sl_on = true
			sl_pos = PORTAL
			sl_vel = Vector2(-260, 70)
			sl_spin = 3.2
			Audio.play("explosion_small", "intro", -4.0)
			alarm_vol = ALARM_VOL
			Audio.loop("intro_fire", "alarm_hull", true, alarm_vol)
		"dan":
			portal_k = 0.0
			sl_pos = REST
			sl_vel = Vector2(-6, 2)
			sl_spin = 0.35
			dan_on = true
			dan_pos = Vector2(-1100, 560)
		"tow":
			Audio.play("scan_ping", "intro", -6.0)


## How long a line stays once it is all there – its own timing, never clicked away.
static func read_time(n: int) -> float:
	return 2.4 + n * 0.04


func _end() -> void:
	if ending:
		return
	ending = true
	var tw := create_tween()
	tw.tween_property(_black, "color:a", 1.0, 1.0)
	tw.tween_interval(0.5)
	tw.tween_callback(_finish)


func _finish() -> void:
	if _done:
		return
	_done = true
	finished.emit()
	queue_free()


func skip() -> void:
	step = STEPS.size() - 1
	_end()


func _advance() -> void:
	if step < 0 or step >= STEPS.size():
		return
	var sd: Dictionary = STEPS[step]
	if not sd.has("text"):
		return
	if t < float(sd.get("delay", 0.6)):
		return
	if typed < String(sd["text"]).length():
		typed = String(sd["text"]).length()
		line_done_at = t
		return
	_next()


# ---------------------------------------------------------------- time

func _process(delta: float) -> void:
	_vs = get_viewport().get_visible_rect().size
	if Input.is_key_pressed(KEY_ESCAPE) or Input.is_joy_button_pressed(0, JOY_BUTTON_START):
		skip_held += delta
		if skip_held >= SKIP_HOLD and not ending:
			skip()
	else:
		skip_held = maxf(0.0, skip_held - delta * 2.0)
	step_time(delta)


## One step of the scene (also driven by the smoke test).
func step_time(delta: float) -> void:
	t += delta
	total += delta
	if ending or step >= STEPS.size():
		_world.queue_redraw()
		_box.queue_redraw()
		return
	var sd: Dictionary = STEPS[step]
	var look := String(sd["look"])
	# the line
	if sd.has("text"):
		if t >= float(sd.get("delay", 0.6)):
			box_a = minf(1.0, box_a + delta * 3.0)
			var n := String(sd["text"]).length()
			if typed < n:
				var before := int(typed)
				typed = minf(n, typed + delta * TYPE_RATE)
				# Luz: a soft tick while someone speaks – every other letter, never on a space
				for ci in range(before, int(typed)):
					if ci % 2 == 0 and String(sd["text"])[ci] != " ":
						Audio.play("ui_type", "", -10.0, 0.08)
						break
				if typed >= n:
					line_done_at = t
			elif line_done_at >= 0.0 and t - line_done_at > read_time(n):
				_next()
				return
	elif t >= float(sd.get("hold", 2.0)):
		_next()
		return
	# the black between the two halves, and the fade in at the start
	# Luz: the alarm only until the first box – then it fades out (over 2.5 s)
	# Luz: Dan's engines – they come up as he flies in and fade as he pulls away
	var want := 0.0
	if dan_on:
		match look:
			"dan":
				want = clampf(t / 2.5, 0.0, 1.0) * 0.55
			"approach", "tow":
				want = 0.45
			"away":
				want = 0.45 * (1.0 - clampf(t / 4.5, 0.0, 1.0))
	if want > 0.0 or dan_vol > 0.0:
		dan_vol = move_toward(dan_vol, want, delta * 0.4)
		Audio.loop("intro_dan", "engine_loop", dan_vol > 0.001, dan_vol, 0.7)
	if alarm_vol > 0.0 and (look != "ejected" or box_a > 0.0):
		alarm_vol = maxf(0.0, alarm_vol - delta * ALARM_VOL / 2.5)
		Audio.loop("intro_fire", "alarm_hull", alarm_vol > 0.0, alarm_vol)
	var black := 0.0
	match look:
		"pan":
			black = 1.0 - clampf(t / 1.6, 0.0, 1.0)
		"computer":
			black = clampf((t - 2.0) / 9.0, 0.0, 0.55)              # Luz: zooming out, it already goes dark
		"black":
			black = clampf(0.55 + t / 1.2, 0.0, 1.0)
		"dan":
			black = 1.0 - clampf(t / 1.2, 0.0, 1.0)
	_black.color.a = black
	_scene_step(look, delta)
	_world.queue_redraw()
	_far.queue_redraw()
	_box.queue_redraw()


func _scene_step(look: String, delta: float) -> void:
	# the camera
	match look:
		"pan":
			cam = Vector2(700, 700).lerp(Vector2(1200, 760), smoothstep(0.0, 1.0, t / 6.5))
			zoom = 1.0
		"portal":
			cam = cam.lerp(Vector2(1320, 770), delta * 0.8)
		"ejected":
			cam = cam.lerp(sl_pos.lerp(PORTAL, 0.4), delta * 1.2)
		"computer", "black":
			zoom = lerpf(zoom, 0.45, delta * 0.25)                  # slowly out
			cam = cam.lerp(Vector2(1300, 820), delta * 0.4)
		"dan":
			dan_pos = dan_pos.move_toward(Vector2(120, 690), 115.0 * delta)
			zoom = 0.85
			cam = dan_pos + Vector2(150, 40)                       # the 190SL still out of sight to the right
		"approach":
			dan_pos = dan_pos.lerp(REST + Vector2(-430, -70), delta * 0.35)
			cam = cam.lerp((dan_pos + sl_pos) * 0.5, delta * 0.6)
		"tow", "away":
			beam = minf(1.0, beam + delta * 1.2)
			var pull := REST + Vector2(-430, -70) + Vector2.from_angle(0.15) * 330.0
			if look == "away":
				dan_pos += Vector2(-150, -25) * delta * minf(1.0, t / 1.5)
				pull = dan_pos + Vector2.from_angle(0.15) * 330.0
			sl_pos = sl_pos.lerp(pull, delta * 0.8)
			sl_spin = lerpf(sl_spin, 0.0, delta)
			if look == "away":
				_black.color.a = clampf((t - 3.0) / 1.8, 0.0, 1.0)
	# the portal
	if look in ["portal", "ejected"]:
		portal_k = minf(1.0, portal_k + delta / 1.4)
	elif look == "computer":
		portal_k = maxf(0.0, portal_k - delta / 2.5)
	if portal_k > 0.0 and look in ["portal", "ejected", "computer"]:
		for i in int(30.0 * delta * 60.0 * portal_k / 30.0) + 1:
			var a := randf() * TAU
			_sparks.append([PORTAL + Vector2.from_angle(a) * 20.0, Vector2.from_angle(a + randf_range(-0.4, 0.4)) * randf_range(60, 260), randf_range(0.8, 2.0)])
	for s in _sparks:
		s[0] += s[1] * delta
		s[1] *= 1.0 - delta * 0.8
		s[2] -= delta
	_sparks = _sparks.filter(func(s): return s[2] > 0.0)
	# the 190SL: tumbling, slowing, burning
	if sl_on:
		sl_pos += sl_vel * delta
		sl_vel *= 1.0 - delta * 0.35
		sl_ang += sl_spin * delta
		if look in ["ejected", "computer"]:
			sl_spin = lerpf(sl_spin, 1.1, delta * 0.3)
		var burn := 1.0 if look in ["ejected", "computer"] else 0.35
		if randf() < burn:
			for i in 2:
				_fire.append([sl_pos + Vector2(randf_range(-14, 14), randf_range(-10, 10)), Vector2(randf_range(-20, 20), randf_range(-20, 20)) - sl_vel * 0.2, randf_range(0.3, 0.7), 0])
			_fire.append([sl_pos, Vector2(randf_range(-12, 12), randf_range(-12, 12)) - sl_vel * 0.1, randf_range(1.8, 3.2), 1])
	for f in _fire:
		f[0] += f[1] * delta
		f[2] -= delta
	_fire = _fire.filter(func(f): return f[2] > 0.0)


# ---------------------------------------------------------------- drawing

func _to_screen(p: Vector2) -> Vector2:
	return (p - cam) * zoom + _vs * 0.5


func _draw_far() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 57
	for i in 900:
		_far.draw_rect(Rect2(rng.randf() * _vs.x, rng.randf() * _vs.y, 1, 1), Color(1, 1, 1, rng.randf_range(0.1, 0.6)))
	var par := -(cam - Vector2(900, 700)) * 0.08
	var g: Texture2D = _tex["giant"]
	_far.draw_set_transform(Vector2(_vs.x * 0.78, _vs.y * 0.25) + par, -0.4, Vector2.ONE * 2.2 * (0.85 + zoom * 0.15))
	_far.draw_texture(g, -g.get_size() * 0.5, Color(0.22, 0.21, 0.26))
	var g2: Texture2D = _tex["giant2"]
	_far.draw_set_transform(Vector2(_vs.x * 0.11, _vs.y * 0.85) + par, 0.6, Vector2.ONE * 1.4 * (0.85 + zoom * 0.15))
	_far.draw_texture(g2, -g2.get_size() * 0.5, Color(0.16, 0.16, 0.2))
	_far.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for i in 1100:
		var q := Vector2(rng.randf() * _vs.x, rng.randf() * _vs.y) + par * 2.0
		var col: Color = [Color(0.45, 0.42, 0.38), Color(0.55, 0.32, 0.18), Color(0.75, 0.62, 0.25)][rng.randi() % 3]
		col.a = 0.3
		_far.draw_rect(Rect2(Vector2(fposmod(q.x, _vs.x), fposmod(q.y, _vs.y)), Vector2(1, 1)), col)


func _spr(tx: Texture2D, p: Vector2, ang: float, sc: float, mod: Color = Color.WHITE) -> void:
	_world.draw_set_transform(_to_screen(p), ang, Vector2.ONE * sc * zoom)
	_world.draw_texture(tx, -tx.get_size() * 0.5, mod)
	_world.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_world() -> void:
	for pc in _pieces:
		_spr(pc[0], pc[1], float(pc[2]), float(pc[3]))
	for sc in _scrap:
		_spr(sc[0], sc[1], float(sc[2]) + total * float(sc[3]), 1.0)
	# the portal
	if portal_k > 0.0:
		var p := _to_screen(PORTAL)
		var r := 95.0 * zoom * portal_k
		for i in 7:
			_world.draw_circle(p, r * (1.4 - i * 0.18), Color(0.55, 0.2, 0.9, 0.08 * portal_k))
		for i in 5:
			var a0 := total * (0.8 + i * 0.3) + i * 1.3
			_world.draw_arc(p, r * (0.4 + i * 0.16), a0, a0 + 4.0, 48, Color(0.85, 0.5, 1.0, 0.6 * portal_k), 3.0 * zoom)
		_world.draw_circle(p, r * 0.32, Color(0.95, 0.85, 1.0, 0.85 * portal_k))
		_world.draw_circle(p, r * 0.18, Color(1, 1, 1, portal_k))
	for s in _sparks:
		_world.draw_rect(Rect2(_to_screen(s[0]), Vector2(3, 3) * zoom), Color(0.8, 0.45, 1.0, clampf(float(s[2]), 0.0, 1.0)))
	# smoke under, fire over the 190SL
	for f in _fire:
		if int(f[3]) == 1:
			var life: float = f[2]
			_world.draw_circle(_to_screen(f[0]), (16.0 - life * 3.0) * zoom, Color(0.25, 0.22, 0.22, clampf(life * 0.12, 0.0, 0.3)))
	if dan_on:
		var dt: Texture2D = _tex["dan"]
		_spr(dt, dan_pos, 0.15, 5.0)
		# his engines
		var back := _to_screen(dan_pos) - Vector2.from_angle(0.15) * dt.get_width() * 2.5 * zoom
		_world.draw_circle(back, 14.0 * zoom, Color(1.0, 0.6, 0.25, 0.35))
		_world.draw_circle(back, 6.0 * zoom, Color(1.0, 0.9, 0.7, 0.8))
	if beam > 0.0 and dan_on:
		var a := _to_screen(dan_pos + Vector2.from_angle(0.15) * 240.0)
		var b := _to_screen(sl_pos)
		for i in 6:
			_world.draw_line(a, b, Color(0.4, 1.0, 0.7, (0.1 + i * 0.03) * beam), (26.0 - i * 4.0) * zoom)
		for i in 8:
			var k := fposmod(total * 0.8 + i / 8.0, 1.0)
			_world.draw_circle(b.lerp(a, k), 4.0 * zoom, Color(0.7, 1.0, 0.85, 0.5 * beam))
	if sl_on:
		_spr(_tex["sl"], sl_pos, sl_ang, 1.5, Color(0.85, 0.8, 0.78))
	for f in _fire:
		if int(f[3]) == 0:
			var life2: float = f[2]
			_world.draw_circle(_to_screen(f[0]), (2.0 + life2 * 7.0) * zoom, [Color(1.0, 0.55, 0.15), Color(1.0, 0.85, 0.3), Color(0.9, 0.25, 0.1)][int(life2 * 10.0) % 3] * Color(1, 1, 1, clampf(life2 * 2.0, 0.0, 0.9)))


## The box: a portrait left (none for the pilot's radio), the name in the speaker's colour, the line typed.
func _draw_box() -> void:
	var f := ThemeDB.fallback_font
	var hint := "Hold %s to skip" % Pad.glyph("options") if Pad.using_pad else "Hold Esc to skip"
	var ha := 0.35 + 0.65 * clampf(skip_held / SKIP_HOLD, 0.0, 1.0)
	_box.draw_string(f, Vector2(_vs.x - 210, _vs.y - 22), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.7, 0.75, 0.85, ha * 0.7))
	if skip_held > 0.0:
		_box.draw_arc(Vector2(_vs.x - 228, _vs.y - 27), 8.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(skip_held / SKIP_HOLD, 0.0, 1.0), 24, Color(0.85, 0.9, 1.0, 0.9), 2.0)
	if ending or step < 0 or step >= STEPS.size() or box_a <= 0.0:
		return
	var sd: Dictionary = STEPS[step]
	if not sd.has("text"):
		return
	var who := String(sd["who"])
	var pilot := who == "pilot"
	var c: Dictionary = StoryData.CHARACTERS.get(who, {})
	var col: Color = Color(1.0, 0.35, 0.3) if pilot else c.get("col", Color(0.55, 0.85, 1.0))
	var a := box_a
	var bw := minf(1120.0, _vs.x - 60.0)
	var r := Rect2(_vs.x * 0.5 - bw * 0.5, _vs.y - 200.0, bw, 150.0)
	_box.draw_rect(r, Color(0.02, 0.03, 0.06, 0.92 * a))
	_box.draw_rect(r, Color(col, 0.9 * a), false, 2.0)
	var x0 := r.position.x + 28.0
	var y := r.position.y + 40.0
	if not pilot:
		var pr := Rect2(r.position + Vector2(16, 15), Vector2(120, 120))
		var tex: Texture2D = load("res://scripts/core/holo_art.gd").portrait(col, fmod(total * 0.5, 1.0)) if c.get("holo", false) else Story.portrait_of(who)
		_box.draw_texture_rect(tex, pr, false, Color(1, 1, 1, a))
		_box.draw_rect(pr, Color(col, 0.8 * a), false, 2.0)
		x0 = pr.end.x + 24.0
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
	_box.draw_string(f, Vector2(x0, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color(1, 0.86, 0.84, a) if pilot else Color(0.93, 0.95, 1.0, a))


# ---------------------------------------------------------------- input

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton or (event is InputEventKey and event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]):
		get_viewport().set_input_as_handled()        # Luz: the lines keep their timing – nothing clicks them away
