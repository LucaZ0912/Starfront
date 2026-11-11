extends Node2D
## 0.7.53.2 (Luz): the ominous feeling of a Precursor ruin – fog drifting low over the floor (inside everywhere,
## outside along the ruin's foot), and a burst of it when its entrance opens. Lies over the floor, under the people.
## No class_name: preload it.

var rects: Array = []                     # Rect2 in art px where the fog lies
var puffs: Array = []                     # {pos, vel, r, t, life}
var _t := 0.0


func burst(at: Vector2) -> void:
	for i in 26:
		puffs.append({"pos": at + Vector2(randf_range(-20, 20), randf_range(-8, 4)), "vel": Vector2(randf_range(-30, 30), randf_range(4, 26)),
			"r": randf_range(10, 22), "t": 0.0, "life": randf_range(3.0, 6.0)})


func _process(delta: float) -> void:
	_t += delta
	for p in puffs:
		p["t"] = float(p["t"]) + delta
		p["pos"] = (p["pos"] as Vector2) + (p["vel"] as Vector2) * delta
		p["vel"] = (p["vel"] as Vector2) * (1.0 - 0.4 * delta)
		p["r"] = float(p["r"]) + 6.0 * delta
	puffs = puffs.filter(func(p): return float(p["t"]) < float(p["life"]))
	queue_redraw()


func _draw() -> void:
	var s := GroundMap.SCALE
	for r in rects:
		var rr: Rect2 = r
		var bands := int(rr.size.y / 18.0) + 1
		for b in bands:
			var y0 := rr.position.y + b * 18.0
			var pts := PackedVector2Array()
			var n := maxi(8, int(rr.size.x / 24.0))
			for i in n + 1:
				var x := rr.position.x + rr.size.x * i / n
				pts.append(Vector2(x, y0 + sin(x * 0.05 + _t * 0.6 + b) * 3.0) * s)
			for i2 in n + 1:
				var x2 := rr.end.x - rr.size.x * i2 / n
				pts.append(Vector2(x2, y0 + 11.0 + sin(x2 * 0.04 + _t * 0.45 + b * 2.0) * 4.0) * s)
			draw_colored_polygon(pts, Color(0.74, 0.72, 0.84, 0.06 + 0.02 * float(b % 3)))
	for p in puffs:
		var k := 1.0 - float(p["t"]) / float(p["life"])
		draw_circle((p["pos"] as Vector2) * s, float(p["r"]) * s, Color(0.76, 0.73, 0.86, 0.12 * k))
