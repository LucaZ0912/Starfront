class_name Fx
extends Node2D
## Short-lived effects: laser beam, explosion, flash, warp streak, click marker, damage number.

var kind := ""
var life := 0.3
var max_life := 0.3
var a := Vector2.ZERO
var b := Vector2.ZERO
var color := Color.WHITE
var size := 10.0


static func beam(from: Vector2, to: Vector2, col: Color, width: float) -> Fx:
	var f := Fx.new()
	f.kind = "beam"
	f.a = from
	f.b = to
	f.color = col
	f.size = width
	f.life = 0.15
	f.max_life = 0.15
	return f


static func explosion(pos: Vector2, radius: float, col: Color) -> Fx:
	var f := Fx.new()
	f.kind = "explosion"
	f.position = pos
	f.size = maxf(radius, 8.0)
	f.color = col
	f.life = 0.45
	f.max_life = 0.45
	return f


static func flash(pos: Vector2, col: Color, radius: float) -> Fx:
	var f := Fx.new()
	f.kind = "flash"
	f.position = pos
	f.color = col
	f.size = radius
	f.life = 0.6
	f.max_life = 0.6
	return f


static func warp_streak(pos: Vector2, dir: Vector2, col: Color) -> Fx:
	var f := Fx.new()
	f.kind = "streak"
	f.position = pos
	f.a = dir
	f.color = col
	f.life = 0.7
	f.max_life = 0.7
	return f


static func marker(pos: Vector2, col: Color) -> Fx:
	var f := Fx.new()
	f.kind = "marker"
	f.position = pos
	f.color = col
	f.life = 0.5
	f.max_life = 0.5
	return f


## Floating damage number (constant size on screen, rises and fades).
## Blue = shield damage, red = hull damage (armour + structure).
var text := ""


static func damage_number(pos: Vector2, amount: float, col: Color) -> Fx:
	var f := Fx.new()
	f.kind = "number"
	f.position = pos
	f.color = col
	f.text = str(int(round(amount))) if amount >= 1.0 else "%.1f" % amount
	f.a = Vector2(randf_range(-14.0, 14.0), randf_range(-6.0, 6.0))
	f.life = 0.9
	f.max_life = 0.9
	f.z_index = 20
	return f


## Floating text (e.g. "+2.4 Iron Ore" over a mined asteroid), rises and fades like damage numbers.
## A puff of black smoke drifting away (KHI refineries, package 25a).
static func smoke(pos: Vector2, drift: Vector2, radius: float) -> Fx:
	var f := Fx.new()
	f.kind = "smoke"
	f.position = pos
	f.a = drift
	f.size = maxf(radius, 2.5)
	f.color = Color(0.2, 0.19, 0.18)
	f.life = 2.4
	f.max_life = 2.4
	return f


static func float_text(pos: Vector2, txt: String, col: Color) -> Fx:
	var f := Fx.new()
	f.kind = "number"
	f.position = pos
	f.color = col
	f.text = txt
	f.a = Vector2(randf_range(-10.0, 10.0), randf_range(-4.0, 4.0))
	f.life = 1.3
	f.max_life = 1.3
	f.z_index = 20
	return f


func _process(delta: float) -> void:
	life -= delta
	if kind == "smoke":
		position += a * delta
	if life <= 0.0:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := clampf(life / max_life, 0.0, 1.0)
	match kind:
		"beam":
			draw_line(a - position, b - position, Color(color, t), size)
			draw_line(a - position, b - position, Color(1, 1, 1, t * 0.8), size * 0.35)
		"explosion":
			draw_circle(Vector2.ZERO, size * (1.1 - t * 0.6), Color(color, t * 0.5))
			draw_circle(Vector2.ZERO, size * 0.5 * (1.1 - t), Color(1, 0.95, 0.8, t * 0.8))
			draw_arc(Vector2.ZERO, size * (1.3 - t * 0.5), 0.0, TAU, 32, Color(color, t), 2.0)
		"flash":
			draw_circle(Vector2.ZERO, size * (1.2 - t), Color(color, t * 0.5))
			draw_circle(Vector2.ZERO, size * 0.4 * t, Color(1, 1, 1, t))
			draw_arc(Vector2.ZERO, size * (1.5 - t), 0.0, TAU, 40, Color(color, t), 3.0)
		"streak":
			var slen := 4000.0 * (1.0 - t)
			for i in 5:
				var off := a.orthogonal() * (i - 2) * 10.0
				draw_line(off, off + a * slen, Color(color, t * (1.0 - absf(i - 2) * 0.3)), 3.0 - absf(i - 2) * 0.8)
			draw_circle(a * slen, 25.0 * t, Color(1, 1, 1, t))
		"smoke":
			var g := 1.0 - t
			draw_circle(Vector2.ZERO, size * (0.6 + g * 1.6), Color(color, 0.7 * t))
			draw_circle(Vector2(size * 0.4, -size * 0.3) * g, size * (0.4 + g * 1.1), Color(color.lightened(0.18), 0.55 * t))
			draw_circle(Vector2(-size * 0.3, size * 0.2) * g, size * (0.3 + g * 0.9), Color(color.darkened(0.4), 0.6 * t))
		"marker":
			draw_arc(Vector2.ZERO, 8.0 + 30.0 * t, 0.0, TAU, 24, Color(color, t), 2.0)
		"number":
			var z := get_viewport().get_canvas_transform().get_scale().x
			var rise := (1.0 - t) * 34.0
			var alpha := clampf(t * 2.5, 0.0, 1.0)
			var font := ThemeDB.fallback_font
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE / maxf(z, 0.0001))
			var p := a + Vector2(-8.0, -26.0 - rise)
			draw_string_outline(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, 4, Color(0, 0, 0, 0.75 * alpha))
			draw_string(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(color, alpha))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
