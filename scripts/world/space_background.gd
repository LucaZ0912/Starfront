class_name SpaceBackground
extends CanvasLayer
## Full-screen shader background (nebula + stars with parallax).

const BgShader = preload("res://shaders/background.gdshader")

var rect: ColorRect
var mat: ShaderMaterial


func setup(seed_v: float, hue: float, strength: float = 1.0) -> void:
	layer = -10
	rect = ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mat = ShaderMaterial.new()
	mat.shader = BgShader
	mat.set_shader_parameter("seed", seed_v)
	mat.set_shader_parameter("neb_a", Color.from_hsv(fposmod(hue, 1.0), 0.7, 0.85))
	mat.set_shader_parameter("neb_b", Color.from_hsv(fposmod(hue + 0.45, 1.0), 0.6, 0.75))
	mat.set_shader_parameter("neb_strength", strength)
	rect.material = mat
	add_child(rect)


func follow(cam: Camera2D) -> void:
	if mat != null and cam != null:
		# Zoom-independent: the background stays the same across zoom levels
		# and only shifts with movement (very distant stars/nebula).
		var o := cam.position * 0.004
		mat.set_shader_parameter("offset", Vector2(fposmod(o.x, 40000.0), fposmod(-o.y, 40000.0)))
