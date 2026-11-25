extends Control
## Package 80 (Luz): a controller's wheel – the action wheel (□ held: approach, follow, orbit, warp, dock / jump,
## drones, wingmen) or the window wheel (Options held). The stick picks a field, letting go of the button does it.
## Package 58: the drone wheel (◯ held); an item [label, id, true] is marked in gold (the drone's job now). The wheel
## grows with big screens, as the radio calls, and a little with many fields.

var items: Array = []               # [label, id] or [label, id, marked]
var title := ""
var sel := -1
var _t := 0.0
const R := 150.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(dt: float) -> void:
	_t += dt
	queue_redraw()


func pick(v: Vector2) -> void:
	if v.length() < 0.5 or items.is_empty():
		return
	var a := fposmod(v.angle() + PI / 2.0 + PI / items.size(), TAU)
	sel = int(a / (TAU / items.size())) % items.size()


func chosen() -> String:
	return String(items[sel][1]) if sel >= 0 and sel < items.size() else ""


var seat := 0                       # split screen in space: whose controller it belongs to (it is drawn as theirs)


func _draw() -> void:
	var m0 := get_tree().current_scene
	if seat == 1 and m0 != null and "view" in m0 and m0.view != null and is_instance_valid(m0.view) and "eyes_two" in m0.view and m0.view.eyes_two:
		m0.view.in_eye(1, _draw_now)                  # (their glyphs, their HUD, their view's level)
	else:
		_draw_now()


func _draw_now() -> void:
	var font := get_theme_font("font", "Label")
	var k := clampf(get_viewport_rect().size.y / 900.0, 1.0, 2.4)
	var n := items.size()
	var rr := (R if n <= 8 else R * 1.2) * k
	var fs := int(round(13.0 * k))
	var c := get_viewport_rect().size * 0.5 + Vector2(0, -40.0 * k)
	var cy := Color(0.25, 0.95, 1.0)
	var gold := Color(1.0, 0.82, 0.35)
	draw_circle(c, rr, Color(0.02, 0.04, 0.08, 0.86))
	draw_arc(c, rr, 0, TAU, 64, Color(cy, 0.7), 2.0)
	draw_circle(c, 44 * k, Color(0.04, 0.07, 0.12, 0.95))
	draw_arc(c, 44 * k, 0, TAU, 32, Color(cy, 0.5), 1.5)
	var tw := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(font, c + Vector2(-tw * 0.5, 5 * k), title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, gold)
	for i in n:
		var a := -PI / 2 + i * TAU / n
		if i == sel:
			var h := PI / n
			var pts := PackedVector2Array([c + Vector2.from_angle(a - h) * 48 * k, c + Vector2.from_angle(a - h) * (rr - 2),
				c + Vector2.from_angle(a + h) * (rr - 2), c + Vector2.from_angle(a + h) * 48 * k])
			draw_colored_polygon(pts, Color(cy, 0.22 + 0.05 * sin(_t * 6.0)))
		var q := c + Vector2.from_angle(a) * (rr * 0.68)
		var on: bool = (items[i] as Array).size() > 2 and bool(items[i][2])
		var lab := ("● " if on else "") + String(items[i][0])
		var lw := font.get_string_size(lab, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var col := gold if on else (Color.WHITE if i == sel else Color(0.8, 0.84, 0.92))
		draw_string(font, q + Vector2(-lw * 0.5, 5 * k), lab, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
	var hint := "the stick picks · let go to do it · %s: cancel" % Pad.glyph("circle")
	if Pad._wheel_btn == "circle":
		hint = "the stick picks · let go to do it · %s: cancel" % Pad.glyph("cross")
	var hfs := int(round(12.0 * k))
	var hw := font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, hfs).x
	draw_rect(Rect2(c + Vector2(-hw * 0.5 - 10 * k, rr + 8 * k), Vector2(hw + 20 * k, 24 * k)), Color(0.02, 0.04, 0.08, 0.86))
	draw_string(font, c + Vector2(-hw * 0.5, rr + 24 * k), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, hfs, Color(0.62, 0.66, 0.78))
