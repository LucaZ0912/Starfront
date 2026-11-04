class_name TransitOverlay
extends CanvasLayer
## Full-screen tunnel effect when entering/leaving hyperspace.

signal finished

const TunnelShader = preload("res://shaders/hyperspace.gdshader")

var rect: ColorRect
var mat: ShaderMaterial
var label: Label
var _tween: Tween


func _ready() -> void:
	layer = 30
	visible = false
	rect = ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_STOP
	mat = ShaderMaterial.new()
	mat.shader = TunnelShader
	rect.material = mat
	add_child(rect)
	label = Label.new()
	label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	label.offset_bottom = -90
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	label.add_theme_constant_override("outline_size", 6)
	add_child(label)


## kind: "warp" (blue streaks) or "jump" (purple hyperspace vortex)
func play(kind: String, text: String, duration: float = 1.6) -> void:
	var vs := get_viewport().get_visible_rect().size
	mat.set_shader_parameter("aspect", Vector2(vs.x / vs.y, 1.0))
	if kind == "jump":
		mat.set_shader_parameter("tint", Color(0.7, 0.4, 1.0))
		mat.set_shader_parameter("swirl", 1.0)
		mat.set_shader_parameter("speed", 2.2)
	else:
		mat.set_shader_parameter("tint", Color(0.5, 0.8, 1.0))
		mat.set_shader_parameter("swirl", 0.0)
		mat.set_shader_parameter("speed", 1.6)
	label.text = text
	visible = true
	rect.modulate.a = 0.0
	label.modulate.a = 0.0
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(rect, "modulate:a", 1.0, 0.3)
	_tween.parallel().tween_property(label, "modulate:a", 1.0, 0.3)
	_tween.tween_interval(maxf(duration - 0.7, 0.1))
	_tween.tween_property(rect, "modulate:a", 0.0, 0.4)
	_tween.parallel().tween_property(label, "modulate:a", 0.0, 0.4)
	_tween.tween_callback(_done)


func _done() -> void:
	visible = false
	finished.emit()


func is_playing() -> bool:
	return visible
