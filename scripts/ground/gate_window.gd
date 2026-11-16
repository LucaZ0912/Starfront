extends Node2D
## Package 54c (Luz): the Cathedral of Return – what the nave's great window shows: space, its stars, and the Pilgrim
## Gate in it exactly as it stands out there (its own art from StationArt: the ring, the twelve spires, the stained
## bands, the lights), its beam reaching out towards home. By the sight's event: a pilgrim ship jumping through the
## gate (a flash in the ring), the light falling (the beam bright). No class_name: preload it.

const S := GroundMap.SCALE
var size_art := Vector2(224, 128)
var sight: Dictionary = {}
var _gate: Texture2D
var _t := 0.0


func setup(win_px: Vector2) -> void:
	size_art = win_px / S
	_gate = load("res://scripts/core/station_art.gd").build({"art": "pilgrim_gate", "tier": 1, "seed": 777})["texture"]


func _process(dt: float) -> void:
	_t += dt
	queue_redraw()


func _h(x: int, y: int) -> float:
	var v := sin(float(x) * 12.9898 + float(y) * 78.233) * 43758.5453
	return v - floor(v)


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(S, S))
	draw_rect(Rect2(Vector2.ZERO, size_art), Color(0.02, 0.02, 0.06))
	for i in 160:                                                         # the stars, a few twinkling
		var q := Vector2(_h(i, 1) * size_art.x, _h(i, 2) * size_art.y)
		var a := 0.5 + 0.5 * sin(_t * (1.0 + _h(i, 3) * 3.0) + i)
		draw_rect(Rect2(q, Vector2(1, 1)), Color(1, 1, 1, 0.4 + 0.6 * a * _h(i, 4)))
	var ev := String(sight.get("event", ""))
	var gc := Vector2(size_art.x * 0.52, size_art.y * 0.5)
	var gs := minf(size_art.x, size_art.y) * 0.82
	# its beam, pointing home – up and away to the left
	var bright := 0.6 if ev == "lightfall" else 0.22
	for b in 40:
		var t := float(b) / 40.0
		draw_rect(Rect2(gc + Vector2(-t * size_art.x * 0.55, -t * size_art.y * 0.45), Vector2(3, 2)), Color(1.0, 0.9, 0.6, bright * (1.0 - t)))
	draw_circle(gc, gs * 0.2, Color(1.0, 0.85, 0.5, 0.12 + 0.05 * sin(_t * 1.5)))
	if _gate != null:
		var tw := Vector2(_gate.get_width(), _gate.get_height())
		var sc := gs / tw.x
		draw_texture_rect(_gate, Rect2(gc - tw * sc * 0.5, tw * sc), false)
	# a pilgrim ship jumping through: it comes in small, the ring flashes, it is gone
	if ev == "jump":
		var ph := fposmod(_t, 7.0)
		if ph < 2.0:
			var q2 := gc + Vector2(size_art.x * 0.4, size_art.y * 0.3).lerp(Vector2.ZERO, ph / 2.0)
			draw_rect(Rect2(q2, Vector2(3, 2)), Color(0.9, 0.92, 1.0))
			draw_rect(Rect2(q2 + Vector2(3, 0), Vector2(4, 1)), Color(0.5, 0.8, 1.0, 0.6))
		elif ph < 2.6:
			var k := 1.0 - (ph - 2.0) / 0.6
			draw_circle(gc, gs * 0.3, Color(1.0, 0.95, 0.8, 0.6 * k))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
