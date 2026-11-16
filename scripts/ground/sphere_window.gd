extends Node2D
## Package 54c (Luz): the Meridian Sphere's control room – what its window shows (mockup_54c_leitwarte): the star of
## Durchbruch through the filter glass (its own colour – an A star, white-blue), its granules, a prominence; the
## shell's frame rings crossing before it with the honeycomb of collectors on their built arcs; construction ships
## working along them, a collector held on an arm, welding sparks; small drones. By the sight's event: a solar storm
## (the prominence great), a flare (the glass darkening), a new field (more ships). No class_name: preload it.

const S := GroundMap.SCALE
var size_art := Vector2(640, 150)
var sight: Dictionary = {}
var star_col := Color(0.85, 0.92, 1.0)
var _tex: ImageTexture
var _t := 0.0
var _sc := Vector2.ZERO
var _sr := 0.0


func setup(win_px: Vector2, p_star: Color) -> void:
	size_art = win_px / S
	star_col = p_star
	_sc = Vector2(size_art.x * 0.48, size_art.y * 1.7)
	_sr = size_art.y * 1.62
	_paint()


func _process(dt: float) -> void:
	_t += dt
	queue_redraw()


func _h(x: int, y: int, s: int = 0) -> float:
	var v := sin(float(x) * 12.9898 + float(y) * 78.233 + float(s) * 3.7) * 43758.5453
	return v - floor(v)


func _vn(x: float, y: float) -> float:
	var xi := floori(x)
	var yi := floori(y)
	var fx := x - xi
	var fy := y - yi
	return lerpf(lerpf(_h(xi, yi), _h(xi + 1, yi), fx), lerpf(_h(xi, yi + 1), _h(xi + 1, yi + 1), fx), fy)


func _paint() -> void:
	var W := int(size_art.x)
	var H := int(size_art.y)
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var core := star_col.lerp(Color(1, 1, 1), 0.45)
	var limb := star_col.lerp(Color(0.3, 0.45, 0.9), 0.6).darkened(0.15)
	for y in H:
		for x in W:
			var d := Vector2(x, y).distance_to(_sc)
			var c := Color(0.02, 0.02, 0.04)
			if d < _sr:
				var k := d / _sr
				c = core.lerp(limb, pow(k, 2.0)).darkened(0.08 * _vn(x / 4.0, y / 4.0))
			elif d < _sr + 16.0:
				c = star_col.lerp(Color(0.02, 0.02, 0.04), (d - _sr) / 16.0)
			elif _h(x, y, 5) > 0.992:
				c = Color(1, 1, 1, 0.8)
			img.set_pixel(x, y, c)
	# the shell's frame rings with their collectors
	for ring in [[0.0, H * 0.75, 0.18], [0.35, H * 0.5, 0.32], [-0.4, H * 0.25, 0.25]]:
		for a10 in 700:
			var a2 := a10 * TAU / 700.0
			var q := Vector2(cos(a2) * W * 0.8, sin(a2) * W * 0.8 * float(ring[2])).rotated(float(ring[0])) + Vector2(W * 0.5, float(ring[1]))
			if q.y < 0 or q.y >= H or q.x < 0 or q.x >= W:
				continue
			for t in 2:
				img.set_pixel(clampi(int(q.x) + t, 0, W - 1), int(q.y), Color(0.18, 0.18, 0.2))
			if a10 % 9 == 0 and sin(a2 * 3.0) > -0.2:
				for hy in range(-4, 5):
					for hx in range(-6, 7):
						if absf(hx) + absf(hy) * 1.4 < 6.5:
							var px := int(q.x) + hx
							var py := int(q.y) + hy
							if px >= 0 and py >= 0 and px < W and py < H:
								img.set_pixel(px, py, Color(0.1, 0.13, 0.17) if (hx + hy) % 3 else Color(0.16, 0.2, 0.26))
				if int(q.y) - 2 >= 0:
					img.set_pixel(int(q.x), int(q.y) - 2, Color(0.4, 1.0, 0.6))
	_tex = ImageTexture.create_from_image(img)


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(S, S))
	if _tex != null:
		draw_texture(_tex, Vector2.ZERO)
	var ev := String(sight.get("event", ""))
	# the prominence arching off the limb, slowly rising and falling (great in a storm)
	var big := 2.0 if ev == "storm" else 1.0
	for pa in 50:
		var a := lerpf(-2.25, -1.8, float(pa) / 50.0)
		var r := _sr + sin(float(pa) / 50.0 * PI) * (22.0 + 6.0 * sin(_t * 0.4)) * big
		draw_circle(_sc + Vector2(cos(a), sin(a)) * r, 2.5 * big, Color(star_col.lerp(Color(1, 1, 1), 0.4), 0.6))
	# construction ships working along the rings: long white hulls, a collector on an arm, sparks
	var ships := 3 if ev != "field" else 5
	for k in ships:
		var sx := fposmod(size_art.x * (0.18 + k * 0.27) + _t * (3.0 + k), size_art.x + 120.0) - 60.0
		var sy := size_art.y * (0.25 + 0.2 * (k % 3)) + sin(_t * 0.3 + k) * 3.0
		var sc := 1.0 - (k % 3) * 0.2
		var L := 56.0 * sc
		var hh := 12.0 * sc
		draw_rect(Rect2(Vector2(sx - L * 0.5 + 3, sy + 3), Vector2(L, hh)), Color(0, 0, 0, 0.35))
		draw_rect(Rect2(Vector2(sx - L * 0.5, sy), Vector2(L, hh)), Color(0.86, 0.9, 0.92))
		draw_rect(Rect2(Vector2(sx - L * 0.5, sy), Vector2(L, 2)), Color(1, 1, 1))
		draw_rect(Rect2(Vector2(sx - L * 0.5, sy + hh - 2), Vector2(L, 2)), Color(0.55, 0.6, 0.64))
		draw_rect(Rect2(Vector2(sx - L * 0.5 - 6 * sc, sy + 2), Vector2(6 * sc, hh - 4)), Color(0.3, 0.34, 0.38))
		draw_rect(Rect2(Vector2(sx - L * 0.5 - 9 * sc, sy + hh * 0.5 - 1), Vector2(3 * sc, 3)), Color(0.6, 0.85, 1.0, 0.6 + 0.4 * sin(_t * 9.0)))
		var wl := sx - L * 0.5 + 4.0
		while wl < sx + L * 0.5 - 2:
			draw_rect(Rect2(Vector2(wl, sy + hh * 0.5), Vector2(2, 1)), Color(0.4, 1.0, 0.6))
			wl += 6.0 * sc + 2.0
		var ax := sx + L * 0.5 - 8.0 * sc
		draw_rect(Rect2(Vector2(ax, sy - 14 * sc), Vector2(2, 14 * sc)), Color(0.6, 0.62, 0.66))
		draw_rect(Rect2(Vector2(ax - 8 * sc, sy - 22 * sc), Vector2(16 * sc, 9 * sc)), Color(0.14, 0.18, 0.22))
		draw_rect(Rect2(Vector2(ax - 8 * sc, sy - 22 * sc), Vector2(16 * sc, 1)), Color(0.4, 1.0, 0.6))
		for sp in 5:
			if _h(sp, int(_t * 12.0) + k * 7) > 0.4:
				draw_rect(Rect2(Vector2(ax + (_h(sp, k, 9) - 0.5) * 10.0, sy - 22 * sc + _h(sp, k, 8) * 8.0), Vector2(1, 1)), Color(1.0, 0.95, 0.7))
		draw_circle(Vector2(ax, sy - 18 * sc), 4.0 * sc, Color(1.0, 0.9, 0.6, 0.25 + 0.15 * sin(_t * 20.0 + k)))
	for dr in 10:                                                          # small drones going about
		var q := Vector2(fposmod(dr * 61.0 + _t * (6.0 + dr % 3 * 4.0), size_art.x), 10.0 + fposmod(dr * 37.0, size_art.y - 20.0))
		draw_rect(Rect2(q, Vector2(4, 2)), Color(0.75, 0.78, 0.8))
		draw_rect(Rect2(q + Vector2(4, 0), Vector2(1, 1)), Color(0.4, 1.0, 0.6))
	# a flare: the filter glass darkens over the brightness
	if ev == "flare":
		var f := maxf(0.0, sin(_t * 0.5))
		draw_rect(Rect2(Vector2.ZERO, size_art), Color(0.05, 0.08, 0.12, 0.45 * f))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
