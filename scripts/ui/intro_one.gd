extends CanvasLayer
## Package 56 – the intro, sequence 1 (Luz): the pilot remembers. Black, the narrator's box at the bottom (no portrait,
## typed); Earth fades in; giant ships of the Expansion leave her; the Long Gate, the expedition's ships in line; the
## gate jump; the Veil creeps in from the edges, the Mayday; white-out. Click, Space/Enter or ✕/A moves the text on
## (the first press finishes the typing); it also goes on by itself. Hold Esc (or Options/Start) to skip.

signal finished

const EarthArt = preload("res://scripts/core/earth_art.gd")
const TunnelShader = preload("res://shaders/hyperspace.gdshader")
const VeilShader = preload("res://shaders/veil_edge.gdshader")

## The shots: what is seen ("look") and the narrator's line. `min` – seconds before the line may go on.
const SHOTS := [
	{"look": "black", "text": "The Age of Expansion had begun!"},
	{"look": "earth", "text": "Earth had grown too small for us, and the explorer's spirit of humankind drew us into the deepest depths of space.", "delay": 1.6},
	{"look": "ships", "text": "We broke through the Veil."},
	{"look": "gate", "text": "I was part of an expedition, somewhere around the year 12,600. They called us heroes, the future of humankind. But we knew we were expendable. We knew we would never see that pale blue dot again.", "delay": 1.2},
	{"look": "jump", "text": "What they didn't tell us about were the dangers, and what was waiting for us out there.", "delay": 2.2},
	{"look": "veil", "text": "Mayday! Mayday! Something's wrong! The readings are going crazy! AAAAAAAH—", "delay": 1.6, "red": true, "min": 7.4},
]
const TYPE_RATE := 32.0               # characters a second (the Mayday faster) – Luz: calm, but not too slow
const SKIP_HOLD := 1.2
const FREE_CAMERA := 0.0

var shot := -1
var t := 0.0                          # seconds in this shot
var total := 0.0
var typed := 0.0
var line_done_at := -1.0
var box_a := 0.0
var white := 0.0
var ending := false
var title := false                    # the title card after the white-out (Luz): dark, the Veil spreads from the middle, the name
var title_t := 0.0
var title_leave := -1.0               # when the player pressed on the card (it then goes dark)
const TITLE_READY := 7.6              # the name and its line are all there – from now a press goes on
var _done := false
const TITLE_MAIN := "SPACEFARER"
const TITLE_SUB := "BEYOND THE VEIL"
var skip_held := 0.0
var _vs := Vector2(1600, 900)
var _stars: Node2D
var _scene: Node2D
var _earth: Sprite2D
var _gate: Sprite2D
var _ships: Array = []                # [{sprite, from, to, t0, t1}]
var _tunnel: ColorRect
var _veil: ColorRect
var _flash: ColorRect
var _box: Node2D
var _shake := 0.0
var _ship_tex: Array = []
var _craft_tex: Array = []            # the fleet's small craft – the pilot sits in one of them
var _gate_tex: Texture2D
var _pending := []                    # StationArt jobs still baking


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_vs = get_viewport().get_visible_rect().size
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)        # follows the window when it is resized (Luz)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	_stars = Node2D.new()
	_stars.draw.connect(_draw_stars)
	_stars.modulate.a = 0.0
	add_child(_stars)
	_scene = Node2D.new()
	add_child(_scene)
	_tunnel = ColorRect.new()
	_tunnel.size = _vs
	_tunnel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tm := ShaderMaterial.new()
	tm.shader = TunnelShader
	tm.set_shader_parameter("swirl", 1.0)
	tm.set_shader_parameter("aspect", Vector2(_vs.x / _vs.y, 1.0))
	_tunnel.material = tm
	_tunnel.visible = false
	add_child(_tunnel)
	_veil = ColorRect.new()
	_veil.size = _vs
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vm := ShaderMaterial.new()
	vm.shader = VeilShader
	vm.set_shader_parameter("aspect", Vector2(_vs.x / _vs.y, 1.0))
	_veil.material = vm
	_veil.visible = false
	add_child(_veil)
	_box = Node2D.new()
	_box.draw.connect(_draw_box)
	add_child(_box)
	_flash = ColorRect.new()
	_flash.size = _vs
	_flash.color = Color(1, 1, 1, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)
	# the big pictures bake in the background while the first line is read
	for cs in 2:
		_craft_tex.append(StationArt.build({"art": "gold_ship_small", "tier": 1, "seed": cs})["texture"])
	_pending = [{"art": "long_gate", "tier": 1, "seed": 1}]
	for i in 3:
		_pending.append({"art": "gold_ship_new", "tier": 1, "seed": [2, 0, 1][i] + 4 * (3 + i)})
	StationArt.prebuild(_pending)
	_next_shot()


func _exit_tree() -> void:
	Audio.loop("intro_alarm", "alarm_hull", false)
	StationArt.reap(true)


# ---------------------------------------------------------------- the shots

func _next_shot() -> void:
	shot += 1
	t = 0.0
	typed = 0.0
	line_done_at = -1.0
	if shot >= SHOTS.size():
		_end()
		return
	var look := String(SHOTS[shot]["look"])
	match look:
		"earth":
			EarthArt.land_at(0.0, 0.0)                       # the map (half a second) – still black here
			_earth = Sprite2D.new()
			_earth.texture = EarthArt.texture(170, 12.0, 22.0, Vector3(-0.8, -0.25, 0.55))
			_earth.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			_earth.modulate.a = 0.0
			_scene.add_child(_earth)
		"ships":
			_launch_ships()
		"gate":
			_to_gate()
		"jump":
			Audio.play("jump_hyperspace", "intro")
			_flash.color.a = 0.9
			for s in _ships:
				s["sprite"].queue_free()
			_ships.clear()
			if _gate != null:
				_gate.queue_free()
				_gate = null
			_tunnel.visible = true
			_stars.visible = false
		"veil":
			_veil.visible = true
			Audio.loop("intro_alarm", "alarm_hull", true, 0.4)     # Luz: quieter, less tiring


func _launch_ships() -> void:
	_take_ready()
	if _ship_tex.is_empty():
		return
	var plan := [[Vector2(0.62, 0.36), 0.95, 1.0], [Vector2(0.78, 0.55), 0.6, 1.8], [Vector2(0.86, 0.2), 0.42, 0.6],
		[Vector2(0.52, 0.12), 0.3, 2.6], [Vector2(0.93, 0.42), 0.25, 3.4]]
	for i in plan.size():
		var p: Array = plan[i]
		var sp := Sprite2D.new()
		sp.texture = _ship_tex[i % _ship_tex.size()]
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var sc: float = float(p[1]) * _vs.y / 900.0
		sp.scale = Vector2.ONE * sc
		var to: Vector2 = (p[0] as Vector2) * _vs
		var dir := Vector2.from_angle(-0.52)
		sp.rotation = dir.angle()
		_scene.add_child(sp)
		_ships.append({"sprite": sp, "from": to - dir * 260.0 * sc, "to": to + dir * 180.0 * sc, "t0": float(p[2]), "t1": float(p[2]) + 14.0,
			"glow": sc})
	# the small craft round the giants, a little quicker, each its own way
	var crafts := [[0, Vector2(-0.07, 0.05), 0.0], [0, Vector2(0.09, -0.06), 0.3], [0, Vector2(0.02, 0.1), 0.6], [1, Vector2(-0.05, -0.07), 0.5],
		[1, Vector2(0.06, 0.07), 1.2], [2, Vector2(-0.04, 0.05), 0.9], [3, Vector2(0.03, -0.05), 1.5]]
	var dir2 := Vector2.from_angle(-0.52)
	for j in crafts.size():
		var cr: Array = crafts[j]
		var big: Dictionary = _ships[int(cr[0])]
		var sp2 := Sprite2D.new()
		sp2.texture = _craft_tex[j % 2]
		sp2.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var sc2 := (0.62 - int(cr[0]) * 0.1) * _vs.y / 900.0
		sp2.scale = Vector2.ONE * sc2
		sp2.rotation = dir2.angle() + (j % 3 - 1) * 0.06
		_scene.add_child(sp2)
		var off: Vector2 = (cr[1] as Vector2) * _vs
		_ships.append({"sprite": sp2, "from": (big["from"] as Vector2) + off - dir2 * 40.0, "to": (big["to"] as Vector2) + off + dir2 * 70.0,
			"t0": float(big["t0"]) + float(cr[2]), "t1": float(big["t1"]) + float(cr[2]), "glow": sc2 * 0.18, "back": 34.0 * sc2})


func _to_gate() -> void:
	_take_ready()
	_flash.color.a = 0.35
	if _earth != null:
		_earth.queue_free()
		_earth = null
	for s in _ships:
		s["sprite"].queue_free()
	_ships.clear()
	_gate = Sprite2D.new()
	_gate.texture = _gate_tex
	_gate.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_gate.position = Vector2(_vs.x * 0.56, _vs.y * 0.44)
	_gate.scale = Vector2.ONE * _vs.y / 900.0 * 0.95
	_scene.add_child(_gate)
	Audio.play("gate_activate", "intro", -4.0)
	if _ship_tex.is_empty():
		return
	for i in 5:
		var sp := Sprite2D.new()
		sp.texture = _ship_tex[i % _ship_tex.size()]
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var sc := (0.3 - i * 0.04) * _vs.y / 900.0
		sp.scale = Vector2.ONE * sc
		var tgt := _gate.position
		var start := Vector2(_vs.x * (0.02 + i * 0.075), _vs.y * (0.5 + i * 0.045))
		sp.rotation = (tgt - start).angle()
		_scene.add_child(sp)
		_ships.append({"sprite": sp, "from": start, "to": start.lerp(tgt, 0.62 - i * 0.07), "t0": 0.0, "t1": 18.0, "glow": sc})
	# the small craft fly with them – one of them is yours
	for j in 6:
		var big2: Dictionary = _ships[j % 5]
		var sp3 := Sprite2D.new()
		sp3.texture = _craft_tex[j % 2]
		sp3.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var sc3 := (0.42 - (j % 5) * 0.05) * _vs.y / 900.0
		sp3.scale = Vector2.ONE * sc3
		var o3 := Vector2(0.0, (-1.0 if j % 2 == 0 else 1.0) * (0.035 + (j % 3) * 0.012)) * _vs + Vector2(j * 9.0, 0.0)
		sp3.rotation = (big2["sprite"] as Sprite2D).rotation
		_scene.add_child(sp3)
		_ships.append({"sprite": sp3, "from": (big2["from"] as Vector2) + o3, "to": (big2["to"] as Vector2) + o3 + Vector2.from_angle(sp3.rotation) * 30.0,
			"t0": 0.0, "t1": 18.0, "glow": sc3 * 0.18, "back": 34.0 * sc3})


func _take_ready() -> void:
	if _gate_tex != null and not _ship_tex.is_empty():
		return
	StationArt.reap(true)                                   # wait for whatever is still baking (only if the reader is fast)
	_gate_tex = StationArt.build(_pending[0])["texture"]
	_ship_tex.clear()
	for i in range(1, _pending.size()):
		_ship_tex.append(StationArt.build(_pending[i])["texture"])


func _end() -> void:
	if ending:
		return
	ending = true
	box_a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "white", 1.0, 1.1)
	tw.tween_interval(0.7)
	tw.tween_callback(_title_start)


## The title card: out of the white into the dark, the Veil spreading from the middle to the edges, then the name.
func _title_start() -> void:
	title = true
	title_t = 0.0
	Audio.loop("intro_alarm", "alarm_hull", false)
	_tunnel.visible = false
	_scene.visible = false
	_stars.visible = false
	var vm := _veil.material as ShaderMaterial
	vm.set_shader_parameter("centre", 1.0)
	vm.set_shader_parameter("amount", 0.0)
	_veil.visible = true
	Audio.play("gate_activate", "intro", -10.0, 0.0)


func _finish() -> void:
	if _done:
		return
	_done = true
	Audio.loop("intro_alarm", "alarm_hull", false)
	finished.emit()
	queue_free()


## Skip to the end (Esc held, the debug menu, the smoke test).
func skip() -> void:
	if title:
		if title_t < 99.0:
			title_t = 99.0                           # straight to the end of the card
		return
	shot = SHOTS.size() - 1
	_end()


# ---------------------------------------------------------------- time

func _process(delta: float) -> void:
	t += delta
	total += delta
	var vs_now := get_viewport().get_visible_rect().size
	if vs_now != _vs:
		_vs = vs_now
		_stars.queue_redraw()                         # Luz: a resized window gets its stars everywhere, not just the old size
	if Input.is_key_pressed(KEY_ESCAPE) or Input.is_joy_button_pressed(0, JOY_BUTTON_START):
		skip_held += delta
		if skip_held >= SKIP_HOLD and not ending:
			skip()
	else:
		skip_held = maxf(0.0, skip_held - delta * 2.0)
	if title:
		_title_step(delta)
		return
	if ending:
		_flash.color = Color(1, 1, 1, white)
		_shake = 0.0
		_box.queue_redraw()
		_place()
		return
	var sd: Dictionary = SHOTS[shot]
	var look := String(sd["look"])
	var delay := float(sd.get("delay", 0.6))
	# the box and its line
	if t >= delay:
		box_a = minf(1.0, box_a + delta * 3.0)
		var rate := TYPE_RATE * (1.7 if sd.get("red", false) else 1.0)
		var n := String(sd["text"]).length()
		if typed < n:
			typed = minf(n, typed + delta * rate)
			if typed >= n:
				line_done_at = t
		elif line_done_at >= 0.0 and t - line_done_at > _read_time(sd) and t >= float(sd.get("min", 0.0)):
			_advance()
			return                                   # the next shot starts next frame (its look, not this one's at t = 0)
	_flash.color.a = maxf(0.0, _flash.color.a - delta * 1.4)
	match look:
		"earth":
			_stars.modulate.a = minf(1.0, t / 1.5)
			if _earth != null:
				_earth.modulate.a = clampf((t - 0.6) / 4.0, 0.0, 1.0)
		"ships":
			pass
		"jump":
			(_tunnel.material as ShaderMaterial).set_shader_parameter("tint", Color(0.55, 0.78, 1.0))
			_shake = 0.0
		"veil":
			var k := clampf(t / 5.0, 0.0, 1.0)
			# Luz: it runs until the violet has eaten the whole picture (amount past 1 closes the middle too)
			(_veil.material as ShaderMaterial).set_shader_parameter("amount", clampf(t / 7.0, 0.0, 1.0) * 1.95)
			(_tunnel.material as ShaderMaterial).set_shader_parameter("tint", Color(0.55, 0.78, 1.0).lerp(Color(0.8, 0.45, 1.0), k))
			_shake = 2.0 + k * 4.0                       # Luz: the tunnel keeps its pace – no strobing
	_place()
	_box.queue_redraw()


## The card's timeline: the white fades into the dark (0–1.6 s), the Veil spreads from the middle (0.8–5 s), the name
## comes (4.2–7 s) and stays until the player presses something; then everything goes black (1.5 s).


func _title_step(delta: float) -> void:
	title_t += delta
	_veil.size = _vs
	_flash.size = _vs
	if title_t >= 99.0:
		_finish()
		return
	var k := clampf((title_t - 0.8) / 4.2, 0.0, 1.0)
	(_veil.material as ShaderMaterial).set_shader_parameter("amount", 1.0 - pow(1.0 - k, 2.0))
	var w := 1.0 - clampf(title_t / 1.6, 0.0, 1.0)
	var dark := clampf((title_t - title_leave) / 1.5, 0.0, 1.0) if title_leave >= 0.0 else 0.0
	_flash.color = Color(w, w, w, maxf(w, dark)) if dark <= 0.0 else Color(0, 0, 0, dark)
	_box.queue_redraw()
	if title_leave >= 0.0 and dark >= 1.0:
		_finish()


## Luz: the card waits for the player – any key, click or button once it is all there.
func title_continue() -> void:
	if title and title_t >= TITLE_READY and title_leave < 0.0:
		title_leave = title_t


func _draw_title() -> void:
	var a := clampf((title_t - 4.2) / 1.8, 0.0, 1.0)
	if a <= 0.0:
		return
	var f := ThemeDB.fallback_font
	var ctr := _vs * 0.5 + Vector2(0, -20)
	var big := int(_vs.y / 900.0 * 104.0)
	var small := int(_vs.y / 900.0 * 30.0)
	var sp := big * 0.16
	var w := _spaced_width(f, TITLE_MAIN, big, sp)
	var p := ctr + Vector2(-w * 0.5, big * 0.3)
	# the glow: the word again and again, wide and violet, under the bright one
	for g in [[10.0, 0.06], [6.0, 0.1], [3.0, 0.16]]:
		for o in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
			_spaced(f, TITLE_MAIN, p + o * float(g[0]), big, sp, Color(0.7, 0.35, 1.0, float(g[1]) * a))
	_spaced(f, TITLE_MAIN, p, big, sp, Color(0.93, 0.95, 1.0, a))
	# a sheen running over it once
	var sheen := clampf((title_t - 5.2) / 1.6, 0.0, 1.0)
	if sheen > 0.0 and sheen < 1.0:
		var sx := p.x - 60.0 + (w + 120.0) * sheen
		_box.draw_rect(Rect2(sx - 18.0, p.y - big * 0.9, 36.0, big * 1.1), Color(1.0, 0.95, 0.8, 0.12 * a))
	# the line and the subtitle
	var b := clampf((title_t - 5.4) / 1.6, 0.0, 1.0)
	var lw := w * 0.42 * b
	_box.draw_line(ctr + Vector2(-lw, big * 0.62), ctr + Vector2(lw, big * 0.62), Color(0.75, 0.45, 1.0, 0.7 * b), 2.0)
	if title_t >= TITLE_READY and title_leave < 0.0:
		var hint := "Press any button to continue"
		var hw := f.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		var ha := clampf((title_t - TITLE_READY) / 1.2, 0.0, 1.0) * (0.35 + 0.15 * sin(title_t * 2.0))
		_box.draw_string(f, Vector2(_vs.x * 0.5 - hw * 0.5, _vs.y - 48.0), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.85, 0.8, 1.0, ha))
	var sw := _spaced_width(f, TITLE_SUB, small, small * 0.55)
	_spaced(f, TITLE_SUB, ctr + Vector2(-sw * 0.5, big * 0.62 + small * 1.6), small, small * 0.55, Color(0.8, 0.6, 1.0, b))


func _spaced_width(f: Font, text: String, size: int, sp: float) -> float:
	var w := 0.0
	for ch in text:
		w += f.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + sp
	return w - sp


func _spaced(f: Font, text: String, p: Vector2, size: int, sp: float, col: Color) -> void:
	var x := p.x
	for ch in text:
		_box.draw_string(f, Vector2(x, p.y), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
		x += f.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + sp


func _read_time(sd: Dictionary) -> float:
	if sd.get("red", false):
		return 0.8
	return 2.4 + String(sd["text"]).length() * 0.04


func _advance() -> void:
	var n := String(SHOTS[shot]["text"]).length()
	if t < float(SHOTS[shot].get("delay", 0.6)):
		return
	if typed < n:
		typed = n
		line_done_at = t
		return
	box_a = 0.0
	_next_shot()


## Where everything is this frame: the camera drifts slowly, the ships glide, the Mayday shakes it all.
func _place() -> void:
	var off := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake
	var drift := Vector2(-total * 2.2, -total * 0.8)
	_scene.position = off
	_stars.position = drift * 0.15 + off * 0.5
	_tunnel.position = off - Vector2(12, 12)
	_tunnel.size = _vs + Vector2(24, 24)
	_veil.size = _vs
	_flash.size = _vs
	_box.queue_redraw()
	if _earth != null:
		var sh := String(SHOTS[mini(shot, SHOTS.size() - 1)]["look"])
		var big := _vs.y / 900.0 * (3.6 + total * 0.008)
		_earth.scale = Vector2.ONE * big
		var target := Vector2(_vs.x * 0.39, _vs.y * 0.49) if sh == "earth" else Vector2(_vs.x * 0.27, _vs.y * 0.62)
		_earth.position = _earth.position.lerp(target, 0.02) if _earth.position != Vector2.ZERO else target
		_earth.position += drift * 0.0
	for s in _ships:
		var k := clampf((t - float(s["t0"])) / (float(s["t1"]) - float(s["t0"])), 0.0, 1.0)
		var sp: Sprite2D = s["sprite"]
		sp.position = (s["from"] as Vector2).lerp(s["to"], k)
		sp.modulate.a = clampf((t - float(s["t0"])) * 0.8, 0.0, 1.0)
	_scene.queue_redraw()
	if not _scene.draw.is_connected(_draw_glows):
		_scene.draw.connect(_draw_glows)


## The ships' engines and the gate's field.
func _draw_glows() -> void:
	if _gate != null:
		var r := 238.0 * _gate.scale.x
		var pulse := 0.5 + 0.5 * sin(total * 1.7)
		_scene.draw_circle(_gate.position, r, Color(0.3, 0.55, 1.0, 0.1 + pulse * 0.05))
		_scene.draw_circle(_gate.position, r * 0.62, Color(0.5, 0.75, 1.0, 0.08 + pulse * 0.05))
		_scene.draw_circle(_gate.position, r * 0.24, Color(0.85, 0.95, 1.0, 0.22 + pulse * 0.1))
		var rng := RandomNumberGenerator.new()
		rng.seed = 56
		for i in 140:
			var a := rng.randf() * TAU + total * rng.randf_range(0.05, 0.3)
			var d := sqrt(rng.randf()) * r * 0.97
			_scene.draw_rect(Rect2(_gate.position + Vector2.from_angle(a) * d, Vector2(2, 2) * _gate.scale.x * 1.6), Color(0.6, 0.85, 1.0, rng.randf_range(0.1, 0.4)))
	for s in _ships:
		var sp: Sprite2D = s["sprite"]
		if sp.modulate.a <= 0.0:
			continue
		var sc: float = float(s["glow"])
		var back := sp.position - Vector2.from_angle(sp.rotation) * float(s.get("back", 250.0 * sc))
		for i in 5:
			_scene.draw_circle(back - Vector2.from_angle(sp.rotation) * i * 26.0 * sc, (34.0 - i * 6.0) * sc, Color(0.55, 0.8, 1.0, 0.12 * sp.modulate.a))
		_scene.draw_circle(back, 12.0 * sc, Color(0.92, 0.97, 1.0, 0.85 * sp.modulate.a))


func _draw_stars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 56
	var w := _vs.x + 200.0
	var h := _vs.y + 200.0
	for i in 900:
		_stars.draw_rect(Rect2(rng.randf() * w - 100.0, rng.randf() * h - 100.0, 2 if rng.randf() < 0.06 else 1, 1), Color(0.9, 0.93, 1.0, rng.randf_range(0.15, 0.85)))
	for i in 2600:
		var x := rng.randf() * w - 100.0
		var y := 40.0 + x * 0.32 + rng.randfn(0.0, 70.0)
		_stars.draw_rect(Rect2(x, y, 1, 1), Color(0.75, 0.75, 0.95, rng.randf_range(0.05, 0.22)))


## The narrator's box: no portrait, the line typed (silently – Luz: the typing sound only when someone speaks).
func _draw_box() -> void:
	if title:
		_draw_title()
		return
	if ending:
		if skip_held > 0.0:
			pass
		return
	var f := ThemeDB.fallback_font
	var sd: Dictionary = SHOTS[shot]
	var red: bool = sd.get("red", false)
	var a := box_a
	var bw := minf(1040.0, _vs.x - 60.0)
	var r := Rect2(_vs.x * 0.5 - bw * 0.5, _vs.y - 190.0, bw, 130.0)
	if a > 0.0:
		var shake := Vector2(randf_range(-2, 2), randf_range(-1.5, 1.5)) if red else Vector2.ZERO
		r.position += shake
		_box.draw_rect(r, Color(0.02, 0.03, 0.06, 0.9 * a))
		var col := Color(1.0, 0.35, 0.3, a) if red else Color(0.55, 0.85, 1.0, 0.9 * a)
		_box.draw_rect(r, col, false, 2.0)
		_box.draw_rect(r.grow(-5), Color(col, 0.25 * a), false, 1.0)
		var text := String(sd["text"]).substr(0, int(typed))
		var lines := _wrap(f, text, bw - 60.0, 22)
		var y := r.position.y + 40.0
		for ln in lines:
			_box.draw_string(f, Vector2(r.position.x + 30, y), ln, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 0.86, 0.84, a) if red else Color(0.93, 0.95, 1.0, a))
			y += 30.0
	# hold to skip
	var hint := "Hold %s to skip" % Pad.glyph("options") if Pad.using_pad else "Hold Esc to skip"
	var ha := 0.35 + 0.65 * clampf(skip_held / SKIP_HOLD, 0.0, 1.0)
	_box.draw_string(f, Vector2(_vs.x - 210, _vs.y - 22), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.7, 0.75, 0.85, ha * 0.7))
	if skip_held > 0.0:
		_box.draw_arc(Vector2(_vs.x - 228, _vs.y - 27), 8.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(skip_held / SKIP_HOLD, 0.0, 1.0), 24, Color(0.85, 0.9, 1.0, 0.9), 2.0)


func _wrap(f: Font, text: String, width: float, size: int) -> Array:
	var out := []
	var line := ""
	for w in text.split(" "):
		var tst := (line + " " + w).strip_edges()
		if f.get_string_size(tst, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width and line != "":
			out.append(line)
			line = w
		else:
			line = tst
	out.append(line)
	return out


# ---------------------------------------------------------------- input

func _input(event: InputEvent) -> void:
	# Luz: the sequence runs on its own timing – nothing clicks a line away; Esc is held to skip, never the pause menu
	if title and event.is_pressed() and not event.is_echo() and (event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton):
		title_continue()
	if event is InputEventMouseButton or (event is InputEventKey and event.keycode in [KEY_ESCAPE, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]):
		get_viewport().set_input_as_handled()
