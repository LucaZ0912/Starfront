extends Node2D
## Package 59, part 2 (Luz): the Threshold's jump through its own black hole – the ship swirls into the hole in its
## middle, as if a whirlpool filter lay on it.
##   "in" (leaving): the core's hole swells, the hull winds up round it and is drawn in, tips last; then the hole
##        collapses with a flash and a purple ring and is gone.
##   "out" (arriving, for the next part): a flash, the hole opens, the hull unwinds out of it, the hole settles
##        back into the core.
## A child of the ship's parent, at the ship's core; the real ship is hidden while its picture swirls.

signal finished

const WhirlShader = preload("res://shaders/whirl.gdshader")
const SWELL := 0.9             # the hole swells before the hull moves
const PULL := 4.2              # the whirl
const COLLAPSE := 0.45         # the hole falls in on itself
const FLASH := 1.8             # the flash and the ring running out
const TWIST := 14.0            # radians of winding at the centre when all is in

var ship: Node2D = null
var mode := "in"
var speed := 1.0
var _t := 0.0
var _R := 60.0                 # the core hole's radius (world units)
var _hole := 1.0               # the hole's size (1 = as in the core, 0 = gone)
var _flash := -1.0             # 0 … 1 the flash and ring (-1: none)
var _done := false
var _spr: Sprite2D = null
var _mat: ShaderMaterial = null


func setup(s: Node2D, m: String) -> void:
	ship = s
	mode = m
	z_index = 3
	var fit = s.get("fit")
	var hull: Dictionary = fit.hull()
	var tex: Texture2D = PixelArt.ship_texture(fit.hull_id, String(s.get("paint")))
	var img: Image = tex.get_image()
	var core := Vector2(img.get_width(), img.get_height()) * 0.5
	if hull.has("black_hole"):
		var cr: Array = hull["black_hole"]["core"]
		core = Vector2(float(cr[0]) + 1.5, float(cr[1]) + 1.5)
	# a square picture with the core in its middle (the whirl turns round it)
	var far := 0.0
	for cn in [Vector2.ZERO, Vector2(img.get_width(), 0), Vector2(0, img.get_height()), Vector2(img.get_width(), img.get_height())]:
		far = maxf(far, core.distance_to(cn))
	var side := int(ceil(far)) * 2 + 4
	var sq := Image.create(side, side, false, Image.FORMAT_RGBA8)
	var src := img.duplicate()
	src.convert(Image.FORMAT_RGBA8)
	sq.blit_rect(src, Rect2i(0, 0, src.get_width(), src.get_height()), Vector2i(int(round(side * 0.5 - core.x)), int(round(side * 0.5 - core.y))))
	var head: float = float(s.get("heading"))
	position = s.position + ((core - Vector2(img.get_width(), img.get_height()) * 0.5) * PixelArt.SCALE).rotated(head)
	_R = PixelArt.black_hole_texture().get_width() * PixelArt.SCALE * 0.32
	_mat = ShaderMaterial.new()
	_mat.shader = WhirlShader
	_spr = Sprite2D.new()
	_spr.texture = ImageTexture.create_from_image(sq)
	_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_spr.scale = Vector2.ONE * PixelArt.SCALE
	_spr.rotation = head
	_spr.material = _mat
	_spr.show_behind_parent = true
	add_child(_spr)
	s.set_meta("fx_hidden", true)                  # its picture takes its place (the ship itself not drawn)
	s.queue_redraw()
	if mode == "out":
		_hole = 0.0
		_whirl(1.0)
	else:
		_whirl(0.0)


## How long the whole thing takes (s, at speed 1).
func total() -> float:
	return SWELL + PULL + COLLAPSE + FLASH if mode == "in" else 0.5 + 0.9 + PULL + 0.7


func _process(dt: float) -> void:
	if _done:
		return
	_t += dt * speed
	if mode == "in":
		_step_in()
	else:
		_step_out()
	queue_redraw()


func _step_in() -> void:
	var t2 := SWELL + PULL
	if _t < SWELL:
		_hole = 1.0 + 0.25 * ease(_t / SWELL, 0.5)
	elif _t < t2:
		var p := (_t - SWELL) / PULL
		_hole = 1.25 + 0.35 * p
		_whirl(p)
	elif _t < t2 + COLLAPSE:
		_whirl(1.0)
		_hole = 1.6 * (1.0 - ease((_t - t2) / COLLAPSE, 2.2))
	elif _t < t2 + COLLAPSE + FLASH:
		_hole = 0.0
		_flash = (_t - t2 - COLLAPSE) / FLASH
	else:
		_finish()


func _step_out() -> void:
	# a flash first, out of it the hole; the hull unwinds out of it; the hole settles into the core
	var a := 0.5
	var b := a + 0.9
	var c := b + PULL
	if _t < a:
		_flash = _t / a * 0.35
	elif _t < b:
		_flash = -1.0
		_hole = 1.6 * ease((_t - a) / 0.9, 0.4)
	elif _t < c:
		var p := 1.0 - (_t - b) / PULL
		_hole = 1.25 + 0.35 * p
		_whirl(p)
	elif _t < c + 0.7:
		_whirl(0.0)
		_hole = 1.25 - 0.25 * ease((_t - c) / 0.7, 0.5)
	else:
		_finish()


## The hull's picture: p 0 = as it is, 1 = wound up and all of it in the hole.
func _whirl(p: float) -> void:
	p = clampf(p, 0.0, 1.0)
	_mat.set_shader_parameter("twist", TWIST * ease(p, 1.3) * (-1.0 if mode == "out" else 1.0))
	_mat.set_shader_parameter("pull", ease(p, 3.4))


func _finish() -> void:
	_done = true
	_flash = -1.0
	if mode == "out" and ship != null and is_instance_valid(ship):
		ship.remove_meta("fx_hidden")
		ship.queue_redraw()
	finished.emit()
	queue_free()


func _draw() -> void:
	var k := _hole
	if k > 0.001:
		# the core's own black hole with its turning disc, grown; a violet halo of bent light round it
		var tex := PixelArt.black_hole_texture()
		var sz := Vector2(tex.get_width(), tex.get_height()) * PixelArt.SCALE * k
		var r := _R * k
		var glow := clampf((k - 1.0) / 0.6, 0.0, 1.0)
		draw_circle(Vector2.ZERO, r * 2.4, Color(0.5, 0.25, 0.95, 0.10 * glow))
		draw_circle(Vector2.ZERO, r * 1.7, Color(0.6, 0.3, 1.0, 0.16 * glow))
		draw_texture_rect(tex, Rect2(-sz * 0.5, sz), false)
	if _flash >= 0.0 and _flash < 1.0:
		var f := _flash
		var gl := f / 0.06 if f < 0.06 else pow(1.0 - (f - 0.06) / 0.94, 1.7)
		var big := _R * 2.2
		# the flash: a white-hot centre, a wide halo and four rays
		draw_circle(Vector2.ZERO, big * (1.0 + 2.5 * f) * 2.2, Color(0.75, 0.55, 1.0, 0.3 * gl))
		draw_circle(Vector2.ZERO, big * (1.0 + 1.5 * f), Color(0.95, 0.9, 1.0, 0.75 * gl))
		draw_circle(Vector2.ZERO, big * 0.45, Color(1, 1, 1, gl))
		for i in 4:
			var dv := Vector2.from_angle(PI * 0.25 + i * PI * 0.5) * big * (3.0 + 3.0 * f)
			draw_line(-dv * 0.1, dv, Color(0.95, 0.88, 1.0, 0.85 * gl), maxf(3.0, big * 0.08))
		var hv := Vector2.RIGHT * big * (5.0 + 4.0 * f)
		draw_line(-hv, hv, Color(0.9, 0.8, 1.0, 0.6 * gl), maxf(2.0, big * 0.05))
		# the purple ring running out
		var rr := lerpf(_R * 0.6, _R * 16.0, ease(f, 0.35))
		draw_arc(Vector2.ZERO, rr, 0.0, TAU, 128, Color(0.72, 0.38, 1.0, 0.95 * (1.0 - f)), maxf(3.0, _R * 0.5 * (1.0 - f)))
		draw_arc(Vector2.ZERO, rr * 0.93, 0.0, TAU, 128, Color(0.85, 0.6, 1.0, 0.35 * (1.0 - f)), maxf(2.0, _R * 1.0 * (1.0 - f)))
