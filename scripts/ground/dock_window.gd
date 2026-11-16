extends Node2D
## Package 54c (Luz): the galleries at the capitals' yards – what their window shows (mockup_54c_werft_*): the great
## work in its dock, drawn with its own art as it lies out there (the Res Publica, the Lux Aeterna, the jump gates
## being built), so big the window holds only part of it; gantries crossing in front with work lights, welding sparks,
## drones going about. By the sight's event: "test" – her drives lit, "segment" – a hull segment moved in on a tug,
## "jump" – a probe jumping through a gate (the ring flashing). No class_name: preload it.

const S := GroundMap.SCALE
## The yard's landmark: its art and seed (as in Universe), its accent.
const WORKS := {"concord_yards": ["res_publica", 4242, Color(0.4, 0.68, 1.0)], "forge": ["lux_aeterna", 4243, Color(0.88, 0.68, 0.3)],
	"axiom_yards": ["gate_frame", 700, Color(0.4, 1.0, 0.6)]}

var size_art := Vector2(704, 160)
var sight: Dictionary = {}
var kind := "concord_yards"
var _tex: Texture2D
var _t := 0.0


func setup(win_px: Vector2, p_kind: String) -> void:
	size_art = win_px / S
	kind = p_kind if WORKS.has(p_kind) else "concord_yards"
	var w: Array = WORKS[kind]
	_tex = load("res://scripts/core/station_art.gd").build({"art": String(w[0]), "tier": 1, "seed": int(w[1])})["texture"]


func _process(dt: float) -> void:
	_t += dt
	queue_redraw()


func _h(x: int, y: int, s: int = 0) -> float:
	var v := sin(float(x) * 12.9898 + float(y) * 78.233 + float(s) * 3.7) * 43758.5453
	return v - floor(v)


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(S, S))
	draw_rect(Rect2(Vector2.ZERO, size_art), Color(0.02, 0.02, 0.05))
	for i in 200:
		draw_rect(Rect2(Vector2(_h(i, 1) * size_art.x, _h(i, 2) * size_art.y), Vector2(1, 1)), Color(1, 1, 1, 0.3 + 0.5 * _h(i, 3)))
	var ev := String(sight.get("event", ""))
	var acc: Color = WORKS[kind][2]
	if _tex != null:
		var tw := Vector2(_tex.get_width(), _tex.get_height())
		if kind == "axiom_yards":
			for k in 3:                                                     # three gates being built, the middle one nearest
				var sc := size_art.y * (1.6 if k == 1 else 0.95) / tw.y
				var c := Vector2(size_art.x * (0.2 + k * 0.3), size_art.y * (0.55 if k == 1 else 0.45))
				draw_texture_rect(_tex, Rect2(c - tw * sc * 0.5, tw * sc), false)
				if ev == "jump" and k == 1 and fposmod(_t, 6.0) < 0.5:
					draw_circle(c, tw.x * sc * 0.28, Color(0.6, 1.0, 0.8, 0.5 * (1.0 - fposmod(_t, 6.0) / 0.5)))
		else:
			var sc2 := size_art.x * 0.62 / tw.x
			var c2 := Vector2(size_art.x * 0.52, size_art.y * 0.55)
			draw_texture_rect(_tex, Rect2(c2 - tw * sc2 * 0.5, tw * sc2), false)
			if ev == "test":                                                # her drives lit, aft
				var aft := c2 + Vector2(-tw.x * sc2 * 0.5, 0)
				for g in 6:
					draw_circle(aft + Vector2(-g * 6.0, 0), 14.0 - g * 2.0, Color(acc.lerp(Color(1, 1, 1), 0.5), 0.12 + 0.05 * sin(_t * 12.0)))
			if ev == "segment":                                             # a hull segment moved in on a tug
				var sx := fposmod(_t * 14.0, size_art.x + 120.0) - 60.0
				draw_rect(Rect2(Vector2(sx, size_art.y * 0.12), Vector2(44, 16)), Color(0.55, 0.58, 0.62))
				draw_rect(Rect2(Vector2(sx, size_art.y * 0.12), Vector2(44, 2)), Color(0.8, 0.82, 0.86))
				draw_rect(Rect2(Vector2(sx + 46, size_art.y * 0.12 + 5), Vector2(8, 6)), Color(0.85, 0.86, 0.9))
				draw_rect(Rect2(Vector2(sx + 54, size_art.y * 0.12 + 7), Vector2(2, 2)), acc)
	# gantries crossing in front, their work lights; welding sparks where they meet the hull; drones
	for gi in 4:
		var gx := size_art.x * (0.1 + gi * 0.27)
		draw_rect(Rect2(Vector2(gx, 0), Vector2(6, size_art.y)), Color(0.3, 0.32, 0.36))
		var ty := 0.0
		while ty < size_art.y:
			draw_rect(Rect2(Vector2(gx, ty), Vector2(6, 1)), Color(0.45, 0.47, 0.5))
			ty += 12.0
		draw_rect(Rect2(Vector2(gx - 1, size_art.y * 0.3), Vector2(8, 3)), Color(1.0, 0.95, 0.75, 0.6 + 0.4 * sin(_t * 2.0 + gi)))
	draw_rect(Rect2(Vector2(0, size_art.y * 0.18), Vector2(size_art.x, 5)), Color(0.3, 0.32, 0.36))
	for sp in 6:
		var p := Vector2(size_art.x * (0.15 + sp * 0.14), size_art.y * (0.35 + 0.1 * (sp % 3)))
		if _h(sp, int(_t * 3.0)) > 0.35:
			for k2 in 6:
				draw_rect(Rect2(p + Vector2((_h(sp, k2, int(_t * 15.0)) - 0.5) * 14.0, _h(k2, sp, int(_t * 15.0)) * 10.0), Vector2(1, 1)), Color(1.0, 0.95, 0.7))
			draw_circle(p + Vector2(0, 4), 5.0, Color(1.0, 0.9, 0.6, 0.3))
	for dr in 12:
		var q := Vector2(fposmod(dr * 59.0 + _t * (5.0 + dr % 4 * 3.0), size_art.x), 10.0 + fposmod(dr * 41.0, size_art.y - 20.0))
		draw_rect(Rect2(q, Vector2(4, 2)), Color(0.75, 0.78, 0.8))
		draw_rect(Rect2(q + Vector2(4, 0), Vector2(1, 1)), acc)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
