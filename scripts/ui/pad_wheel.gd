extends Control
## Package 80 (Luz): a controller's wheel – the action wheel (□ held: approach, follow, orbit, warp, dock / jump,
## drones, wingmen) or the window wheel (Options held). The stick picks a field, letting go of the button does it.

var items: Array = []               # [label, id]
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


func _draw() -> void:
	var font := get_theme_font("font", "Label")
	var c := get_viewport_rect().size * 0.5 + Vector2(0, -40)
	var cy := Color(0.25, 0.95, 1.0)
	draw_circle(c, R, Color(0.02, 0.04, 0.08, 0.86))
	draw_arc(c, R, 0, TAU, 64, Color(cy, 0.7), 2.0)
	draw_circle(c, 44, Color(0.04, 0.07, 0.12, 0.95))
	draw_arc(c, 44, 0, TAU, 32, Color(cy, 0.5), 1.5)
	var tw := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	draw_string(font, c + Vector2(-tw * 0.5, 5), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 0.82, 0.35))
	var n := items.size()
	for i in n:
		var a := -PI / 2 + i * TAU / n
		if i == sel:
			var h := PI / n
			var pts := PackedVector2Array([c + Vector2.from_angle(a - h) * 48, c + Vector2.from_angle(a - h) * (R - 2),
				c + Vector2.from_angle(a + h) * (R - 2), c + Vector2.from_angle(a + h) * 48])
			draw_colored_polygon(pts, Color(cy, 0.22 + 0.05 * sin(_t * 6.0)))
		var q := c + Vector2.from_angle(a) * 100
		var lab := String(items[i][0])
		var lw := font.get_string_size(lab, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		draw_string(font, q + Vector2(-lw * 0.5, 5), lab, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE if i == sel else Color(0.8, 0.84, 0.92))
	var hint := "the stick picks · let go to do it · %s: cancel" % Pad.glyph("circle")
	var hw := font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	draw_string(font, c + Vector2(-hw * 0.5, R + 24), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.62, 0.66, 0.78))
