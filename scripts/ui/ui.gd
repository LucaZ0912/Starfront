class_name UI
extends RefCounted
## Small helpers for building interfaces in code.

const BG := Color(0.05, 0.07, 0.12, 0.92)
const BORDER := Color(0.25, 0.45, 0.7, 0.8)
const ACCENT := Color(0.4, 0.85, 1.0)
## Cyberpunk palette for station interfaces
const NEON_PINK := Color(1.0, 0.25, 0.7)
const NEON_CYAN := Color(0.25, 0.95, 1.0)
const NEON_BG := Color(0.03, 0.02, 0.07, 0.96)
const TEXT_DIM := Color(0.62, 0.66, 0.78)
const GOOD := Color(0.45, 1.0, 0.6)
const BAD := Color(1.0, 0.45, 0.45)
const GOLD := Color(1.0, 0.82, 0.35)


static func panel_style(bg: Color = BG, border: Color = BORDER) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(8)
	return sb


static func panel(bg: Color = BG) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", panel_style(bg))
	return p


## Panel with a glowing neon border (station UI).
static func neon_panel(border: Color = NEON_PINK, bg: Color = NEON_BG, width: int = 2) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := panel_style(bg, border)
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(2)
	sb.shadow_color = Color(border, 0.35)
	sb.shadow_size = 8
	sb.set_content_margin_all(12)
	p.add_theme_stylebox_override("panel", sb)
	return p


static func label(text: String, size: int = 14, color: Color = Color(0.9, 0.93, 1.0)) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func wrap_label(text: String, size: int = 13, color: Color = TEXT_DIM, width: float = 300.0) -> Label:
	var l := label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(width, 0)
	return l


static func button(text: String, cb: Callable, tooltip: String = "") -> Button:
	var b := Button.new()
	b.text = text
	b.tooltip_text = tooltip
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	return b


static func bar(color: Color, width: float = 200.0) -> ProgressBar:
	var pb := ProgressBar.new()
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(width, 7)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.5)
	pb.add_theme_stylebox_override("fill", fill)
	pb.add_theme_stylebox_override("background", bg)
	return pb


static func icon(tex: Texture2D, size: float) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.custom_minimum_size = Vector2(size, size)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return r


static func hbox(sep: int = 6) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


static func vbox(sep: int = 4) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func spacer() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c


static func clear(node: Node) -> void:
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()


## Large neon menu button (main menu / pause menu).
static func menu_button(text: String, cb: Callable, col: Color = NEON_CYAN, width: float = 320.0) -> Button:
	var b := button(text, cb)
	b.custom_minimum_size = Vector2(width, 46)
	b.add_theme_font_size_override("font_size", 19)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	for st in ["normal", "hover", "pressed", "disabled"]:
		var sb := panel_style(Color(0.03, 0.02, 0.08, 0.85), Color(col, 0.55))
		sb.set_border_width_all(0)
		sb.border_width_left = 3
		sb.set_corner_radius_all(0)
		sb.content_margin_left = 18
		if st == "hover":
			sb.bg_color = Color(col.darkened(0.75), 0.9)
			sb.border_color = col
			sb.border_width_left = 6
		elif st == "disabled":
			sb.border_color = Color(col, 0.15)
		b.add_theme_stylebox_override(st, sb)
	b.add_theme_color_override("font_color", Color(0.9, 0.93, 1.0))
	b.add_theme_color_override("font_hover_color", col)
	b.add_theme_color_override("font_disabled_color", Color(0.4, 0.42, 0.5))
	return b
