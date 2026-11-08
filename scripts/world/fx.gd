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


## 0.6.35.12: the flash going into warp – a blinding white burst with a wide blue glow and a lens streak.
static func warp_flash(pos: Vector2, radius: float) -> Fx:
	var f := Fx.new()
	f.kind = "warpflash"
	f.position = pos
	f.size = radius
	f.color = Color(0.6, 0.85, 1.0)
	f.life = 0.9
	f.max_life = 0.9
	f.z_index = 15
	return f


## 0.6.35.11: the glittering trail a ship leaves dropping out of warp – a long line of twinkling sparks behind it
## (longer than the combat view), brightest at the ship. It all flares up at once, then fades from the far end
## towards the ship.
const GLITTER_LIFE := 3.6              # 0.6.35.12: shorter
var sparks := PackedVector3Array()      # x, y = place (local), z = share of the length (0 at the ship, 1 far end)
var spark_phase := PackedFloat32Array()


static func glitter(pos: Vector2, back: Vector2, length: float, width: float, col: Color) -> Fx:
	var f := Fx.new()
	f.kind = "glitter"
	f.position = pos
	f.a = back
	f.size = length
	f.color = col
	f.life = GLITTER_LIFE
	f.max_life = GLITTER_LIFE
	var side := back.orthogonal()
	var n := int(clampf(length / 16.0, 60.0, 480.0))   # 0.6.41.5: about half the sparks (drawn one by one)
	for i in n:
		var u := pow(randf(), 1.4)                  # more sparks close to the ship
		var spread := width * (0.35 + 0.65 * u)    # the trail widens a little behind
		var p := back * (u * length) + side * randf_range(-spread, spread)
		f.sparks.append(Vector3(p.x, p.y, u))
		f.spark_phase.append(randf() * TAU)
	return f


## Package 25f: the Cathedral's anti-drone pulse – a red ring racing out to `radius`.
static func pulse(pos: Vector2, radius: float, col: Color) -> Fx:
	var f := Fx.new()
	f.kind = "pulse"
	f.position = pos
	f.color = col
	f.size = radius
	f.life = 1.1
	f.max_life = 1.1
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
	var bb := _bounds()
	# 0.6.41.5: off screen nothing is redrawn; 0.6.41.6: nor what would be a few pixels (the system map)
	if SystemView.on_screen(bb) and maxf(bb.size.x, bb.size.y) * SystemView.cam_zoom > 3.0:
		visible = true
		queue_redraw()
	else:
		visible = false


## Roughly where the effect draws (world coordinates).
func _bounds() -> Rect2:
	match kind:
		"beam":
			return Rect2(a, Vector2.ZERO).expand(b).grow(size)
		"glitter":
			return Rect2(position, Vector2.ZERO).expand(position + a * size).grow(400.0)
		"streak":
			return Rect2(position, Vector2.ZERO).expand(position + a * 4000.0).grow(60.0)
		"number":
			return Rect2(position - Vector2(400, 400), Vector2(800, 800))
	var r := size * 3.0 + 60.0
	return Rect2(position - Vector2(r, r), Vector2(r, r) * 2.0)


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
		"glitter":
			_draw_glitter()
		"warpflash":
			var e := 1.0 - t                                         # 0 → 1 over the life
			var hot := t * t
			draw_circle(Vector2.ZERO, size * (0.5 + 1.1 * e), Color(color, 0.35 * t))
			draw_circle(Vector2.ZERO, size * (0.35 + 0.6 * e), Color(color.lightened(0.4), 0.55 * t))
			draw_circle(Vector2.ZERO, size * (0.22 + 0.25 * e), Color(1, 1, 1, minf(1.0, 1.4 * t)))
			draw_circle(Vector2.ZERO, size * 0.12, Color(1, 1, 1, hot))
			draw_arc(Vector2.ZERO, size * (0.3 + 1.6 * e), 0.0, TAU, 48, Color(color.lightened(0.3), 0.8 * t), size * 0.04 * t + 1.0)
			# a lens streak across
			for i in 3:
				var w := size * (2.6 - i * 0.7) * (0.6 + 0.4 * t)
				draw_line(Vector2(-w, 0), Vector2(w, 0), Color(1, 1, 1, hot * (0.5 + 0.25 * i)), size * (0.05 - i * 0.012))
		"marker":
			draw_arc(Vector2.ZERO, 8.0 + 30.0 * t, 0.0, TAU, 24, Color(color, t), 2.0)
		"pulse":
			var rr := size * (1.0 - t * t)
			draw_arc(Vector2.ZERO, rr, 0.0, TAU, 96, Color(color, t), 14.0 + 30.0 * t)
			draw_arc(Vector2.ZERO, rr * 0.96, 0.0, TAU, 96, Color(1.0, 0.85, 0.6, t * 0.7), 4.0)
			draw_circle(Vector2.ZERO, rr, Color(color, 0.08 * t))
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


func _draw_glitter() -> void:
	var age := max_life - life
	var flare := clampf(1.0 - age / 0.5, 0.0, 1.0)            # everything flares up at the start
	var z := maxf(get_viewport().get_canvas_transform().get_scale().x, 0.0001)
	var px := 1.0 / z                                          # one screen pixel in world units
	# a faint glowing line along the course, fading from the far end towards the ship
	var segs := 24
	for i in segs:
		var u0 := float(i) / segs
		var u1 := float(i + 1) / segs
		var al := _glitter_alpha(u0, age) * 0.28
		if al <= 0.003:
			continue
		draw_line(a * (u0 * size), a * (u1 * size), Color(color, al), maxf(3.0 * px, 4.0))
	for i in sparks.size():
		var sp := sparks[i]
		var al := _glitter_alpha(sp.z, age)
		if al <= 0.01:
			continue
		var tw := 0.5 + 0.5 * sin(age * (5.0 + fmod(spark_phase[i] * 3.7, 9.0)) + spark_phase[i])
		tw = tw * tw * tw                                          # mostly dim, now and then a bright twinkle
		al *= 0.25 + 0.75 * tw
		var p := Vector2(sp.x, sp.y)
		var big := 1.25 - 0.55 * sp.z                              # bigger at the ship
		var d := maxf((1.6 + 1.5 * flare) * px * big, 0.8)
		draw_circle(p, d, Color(color.lerp(Color.WHITE, tw), al))
		if tw > 0.6 or flare > 0.3:
			var r := px * big * (2.0 + 5.0 * maxf(tw, flare))
			var c := Color(1, 1, 1, al * maxf(tw, flare))
			draw_line(p - Vector2(r, 0), p + Vector2(r, 0), c, maxf(px, 0.6))
			draw_line(p - Vector2(0, r), p + Vector2(0, r), c, maxf(px, 0.6))


## How bright the glitter trail is at share `u` of its length after `age` seconds: brightest at the ship, the far end
## goes out first, the part at the ship last.
func _glitter_alpha(u: float, age: float) -> float:
	var flare := clampf(1.0 - age / 0.5, 0.0, 1.0)
	var ends := max_life * (0.3 + 0.7 * (1.0 - u))
	var fade := clampf((ends - age) / 0.8, 0.0, 1.0)
	return (1.0 - 0.7 * u) * fade * (1.0 + 0.8 * flare)
