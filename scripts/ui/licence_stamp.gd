extends Control
## Package 59, part 3 (Luz): your pilot licence, in the design of the power that takes you in, and the stamp coming
## down on it: "APPROVED". The card slides in over the dimmed room, the stamp drops with a jolt, lifts, the mark stays.
## Add it to a CanvasLayer; it frees itself and emits "finished" (a press skips the wait once the stamp is down).

signal finished

const PilotArt = preload("res://scripts/core/pilot_art.gd")
const T_IN := 0.7              # the card slides in
const T_DROP := 1.7            # the stamp starts down
const T_HIT := 1.95            # … and lands
const T_LIFT := 2.5            # the stamp is gone
const T_HOLD := 5.2            # the card stays this long
const T_OUT := 5.9

var faction := "assembly"
var speed := 1.0
var _t := 0.0
var _pressed := false
var _done := false
var _portrait: Texture2D = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_portrait = PilotArt.portrait(PilotArt.clean(GameState.pilot.get("look", {})))


func _input(e: InputEvent) -> void:
	if (e is InputEventMouseButton and e.pressed) or (e is InputEventJoypadButton and e.pressed and e.button_index == JOY_BUTTON_A) \
			or (e is InputEventKey and e.pressed and not e.echo and e.keycode in [KEY_E, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]):
		_pressed = true
		get_viewport().set_input_as_handled()


func _process(dt: float) -> void:
	if _done:
		return
	_t += dt * speed
	if _pressed and _t > T_LIFT + 0.3 and _t < T_HOLD:
		_t = T_HOLD                                   # a press: on with it
	_pressed = false
	if _t >= T_OUT:
		_done = true
		finished.emit()
		queue_free()
		return
	queue_redraw()


## Whether the stamp has landed (for the tests and the story's sound).
func stamped() -> bool:
	return _t >= T_HIT


func _draw() -> void:
	var cov := faction == "covenant"
	var vs := size
	var k := clampf(vs.y / 900.0, 0.8, 2.4)
	var a_in := clampf(_t / T_IN, 0.0, 1.0)
	var a_out := 1.0 - clampf((_t - T_HOLD) / (T_OUT - T_HOLD), 0.0, 1.0)
	var al := ease(a_in, 0.4) * a_out
	draw_rect(Rect2(Vector2.ZERO, vs), Color(0, 0, 0, 0.62 * al))
	# the card
	var cw := 760.0 * k
	var ch := 440.0 * k
	var shake := Vector2.ZERO
	if _t >= T_HIT and _t < T_HIT + 0.28:
		var sk := 1.0 - (_t - T_HIT) / 0.28
		shake = Vector2(sin(_t * 90.0), cos(_t * 70.0)) * 9.0 * k * sk
	var o := (vs - Vector2(cw, ch)) * 0.5 + Vector2(0.0, (1.0 - ease(a_in, 0.3)) * 60.0 * k) + shake
	var bg := Color(0.23, 0.06, 0.08) if cov else Color(0.91, 0.93, 0.96)
	var fg := Color(0.95, 0.86, 0.63) if cov else Color(0.09, 0.16, 0.31)
	var head := Color(0.62, 0.08, 0.12) if cov else Color(0.16, 0.32, 0.72)
	var hfg := Color(1.0, 0.84, 0.48) if cov else Color(0.95, 0.97, 1.0)
	var rim := Color(1.0, 0.8, 0.3) if cov else Color(0.16, 0.32, 0.72)
	var mark := Color(1.0, 0.8, 0.3) if cov else Color(0.12, 0.54, 0.3)
	draw_rect(Rect2(o - Vector2(4, 4) * k, Vector2(cw, ch) + Vector2(8, 8) * k), Color(rim, al))
	draw_rect(Rect2(o, Vector2(cw, ch)), Color(bg, al))
	if cov:
		draw_rect(Rect2(o + Vector2(10, 10) * k, Vector2(cw, ch) - Vector2(20, 20) * k), Color(rim, 0.5 * al), false, 2.0 * k)
	# the head strip with the crest
	var hh := 74.0 * k
	draw_rect(Rect2(o, Vector2(cw, hh)), Color(head, al))
	var font := get_theme_default_font()
	var title := "COVENANT OF RETURN  ·  PILOT'S SEAL" if cov else "CLUSTER ASSEMBLY  ·  PILOT LICENCE"
	draw_string(font, o + Vector2(26.0 * k, 47.0 * k), title, HORIZONTAL_ALIGNMENT_LEFT, -1, int(26 * k), Color(hfg, al))
	_crest(o + Vector2(cw - 46.0 * k, hh * 0.5), 24.0 * k, cov, al)
	# the portrait
	var pr := Rect2(o + Vector2(30, 104) * k, Vector2(170, 170) * k)
	draw_rect(pr.grow(3.0 * k), Color(rim, al))
	draw_rect(pr, Color(0.35, 0.11, 0.13, al) if cov else Color(0.79, 0.84, 0.93, al))
	if _portrait != null:
		draw_texture_rect(_portrait, pr, false, Color(1, 1, 1, al))
	# the entries
	var rows := [["Name", String(GameState.pilot.get("name", GameState.pilot_name))], ["Origin", "Earth (unverified)"],
		["Seal" if cov else "Class", "first" if cov else "basic"], ["Ratings", "none"], ["Ship", "Dragonfly"]]
	var y := 132.0
	for r in rows:
		draw_string(font, o + Vector2(232.0 * k, y * k), String(r[0]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, int(15 * k), Color(fg, 0.6 * al))
		draw_string(font, o + Vector2(340.0 * k, y * k), String(r[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, int(22 * k), Color(fg, al))
		y += 38.0
	draw_line(o + Vector2(30, 318) * k, o + Vector2(cw - 30.0 * k, 318.0 * k), Color(fg, 0.25 * al), 1.5 * k)
	draw_string(font, o + Vector2(30.0 * k, 356.0 * k), "The road leads home." if cov else "The Cluster is home.", HORIZONTAL_ALIGNMENT_LEFT, -1, int(17 * k), Color(fg, 0.7 * al))
	draw_string(font, o + Vector2(30.0 * k, 396.0 * k), "No. %s-%05d" % ["CR" if cov else "CA", 40000 + absi(hash(String(GameState.pilot.get("name", "pilot")))) % 50000],
		HORIZONTAL_ALIGNMENT_LEFT, -1, int(15 * k), Color(fg, 0.55 * al))
	# the mark the stamp leaves, askew
	var mp := o + Vector2(cw - 190.0 * k, ch - 104.0 * k)
	if _t >= T_HIT:
		var ma := clampf((_t - T_HIT) / 0.08, 0.0, 1.0) * a_out
		draw_set_transform(mp, deg_to_rad(-13.0), Vector2.ONE)
		var mw := 300.0 * k
		var mh := 78.0 * k
		draw_rect(Rect2(Vector2(-mw, -mh) * 0.5, Vector2(mw, mh)), Color(mark, 0.9 * ma), false, 5.0 * k)
		draw_rect(Rect2(Vector2(-mw, -mh) * 0.5 + Vector2(8, 8) * k, Vector2(mw, mh) - Vector2(16, 16) * k), Color(mark, 0.5 * ma), false, 1.5 * k)
		draw_string(font, Vector2(-mw * 0.5, 16.0 * k), "APPROVED", HORIZONTAL_ALIGNMENT_CENTER, mw, int(44 * k), Color(mark, 0.92 * ma))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# the stamp itself: down from above, a jolt, up and away
	if _t >= T_DROP and _t < T_LIFT:
		var up := 0.0
		if _t < T_HIT:
			up = 1.0 - ease((_t - T_DROP) / (T_HIT - T_DROP), 2.6)
		else:
			up = ease((_t - T_HIT - 0.12) / (T_LIFT - T_HIT - 0.12), 0.5) if _t > T_HIT + 0.12 else 0.0
		var sp := mp + Vector2(0.0, -vs.y * 0.75 * up)
		draw_set_transform(sp, deg_to_rad(-13.0), Vector2.ONE)
		var bw := 330.0 * k
		draw_rect(Rect2(Vector2(-bw * 0.5, -70.0 * k), Vector2(bw, 110.0 * k)), Color(0.2, 0.2, 0.24, a_out))
		draw_rect(Rect2(Vector2(-bw * 0.5, 26.0 * k), Vector2(bw, 14.0 * k)), Color(mark.darkened(0.3), a_out))
		draw_rect(Rect2(Vector2(-46.0 * k, -230.0 * k), Vector2(92.0 * k, 164.0 * k)), Color(0.3, 0.3, 0.35, a_out))
		draw_circle(Vector2(0.0, -236.0 * k), 62.0 * k, Color(0.36, 0.36, 0.42, a_out))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The power's crest, small: the Assembly's open hand in a round field, the Covenant's sun over its road.
func _crest(c: Vector2, r: float, cov: bool, al: float) -> void:
	if cov:
		draw_circle(c, r, Color(1.0, 0.8, 0.3, al))
		draw_circle(c, r * 0.86, Color(0.62, 0.08, 0.12, al))
		draw_circle(c + Vector2(0, -r * 0.2), r * 0.3, Color(1.0, 0.8, 0.3, al))
		for i in 7:
			var d := Vector2.from_angle(-PI + i * PI / 6.0)
			draw_line(c + Vector2(0, -r * 0.2) + d * r * 0.4, c + Vector2(0, -r * 0.2) + d * r * 0.62, Color(1.0, 0.8, 0.3, al), 2.0)
		draw_line(c + Vector2(-r * 0.25, r * 0.7), c + Vector2(-r * 0.08, r * 0.2), Color(1.0, 0.8, 0.3, al), 2.0)
		draw_line(c + Vector2(r * 0.25, r * 0.7), c + Vector2(r * 0.08, r * 0.2), Color(1.0, 0.8, 0.3, al), 2.0)
	else:
		draw_circle(c, r, Color(0.92, 0.95, 1.0, al))
		draw_circle(c, r * 0.86, Color(0.16, 0.32, 0.72, al))
		draw_rect(Rect2(c + Vector2(-r * 0.3, -r * 0.05), Vector2(r * 0.6, r * 0.5)), Color(0.95, 0.97, 1.0, al))
		for i in 4:
			draw_rect(Rect2(c + Vector2(-r * 0.3 + i * r * 0.16, -r * 0.5), Vector2(r * 0.11, r * 0.5)), Color(0.95, 0.97, 1.0, al))
