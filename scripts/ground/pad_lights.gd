class_name PadLights
extends Node2D
## 0.7.50.15 (Luz: "the landing pads want more detail"): the lights round a settlement's (or a landing field's) pads –
## steady and dim while a pad is clear, a running chase towards it while a drone comes in (outwards while one lifts
## off), cyan while one stands on it; and over each pad's corner its status: CLEAR, INBOUND, DEPARTING, OCCUPIED,
## or YOUR DRONE.

var rects: Array = []                 # the pads (art px)
var traffic: PadTraffic = null        # the other drones – on pads 1… (pad 0 is yours)
var own := 0                          # the player's pad, -1: none
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func state(i: int) -> String:
	if i == own:
		return "own"
	if traffic != null and is_instance_valid(traffic):
		var j := i - (1 if own == 0 else 0)
		if j >= 0 and j < traffic.pads.size():
			return String(traffic.pads[j]["state"])
	return "empty"


func _edge(r: Rect2) -> Array:
	var pts: Array = []
	var x := r.position.x + 3.0
	while x <= r.end.x - 3.0:
		pts.append(Vector2(x, r.position.y + 2.5))
		x += 16.0
	var y := r.position.y + 18.0
	while y <= r.end.y - 3.0:
		pts.append(Vector2(r.end.x - 2.5, y))
		y += 16.0
	x = r.end.x - 3.0
	while x >= r.position.x + 3.0:
		pts.append(Vector2(x, r.end.y - 2.5))
		x -= 16.0
	y = r.end.y - 18.0
	while y >= r.position.y + 3.0:
		pts.append(Vector2(r.position.x + 2.5, y))
		y -= 16.0
	return pts


func _draw() -> void:
	var S := GroundMap.SCALE
	var font := ThemeDB.fallback_font
	for i in rects.size():
		var r: Rect2 = rects[i]
		var st := state(i)
		var pts := _edge(r)
		var n := pts.size()
		for j in n:
			var col := Color(1.0, 0.72, 0.3)
			var a := 0.35 + 0.12 * sin(_t * 2.0 + i)
			match st:
				"landing", "lifting":
					var dirk := 1.0 if st == "landing" else -1.0
					var ph := fposmod(_t * 1.4 * dirk - float(j) / n * 3.0, 1.0)
					a = 1.0 if ph < 0.16 else 0.22
					col = Color(1.0, 0.85, 0.5) if ph < 0.16 else Color(1.0, 0.65, 0.25)
				"parked", "own":
					col = Color(0.35, 0.95, 1.0)
					a = 0.55 + 0.15 * sin(_t * 1.5 + j * 0.4)
			var p: Vector2 = pts[j] * S
			draw_circle(p, 8.0 * S, Color(col, 0.1 * a))
			draw_circle(p, 3.5 * S, Color(col, 0.3 * a))
			draw_circle(p, 1.7 * S, Color(col.lightened(0.35), minf(a * 1.3, 1.0)))
		var txt: String = {"own": "YOUR DRONE", "parked": "OCCUPIED", "landing": "INBOUND", "lifting": "DEPARTING"}.get(st, "CLEAR")
		var tc: Color = {"own": Color(0.35, 0.95, 1.0), "parked": Color(1.0, 0.45, 0.35), "landing": Color(1.0, 0.75, 0.3), "lifting": Color(1.0, 0.75, 0.3)}.get(st, Color(0.45, 1.0, 0.55))
		var blink := st in ["landing", "lifting"] and fposmod(_t * 2.0, 1.0) > 0.7
		var tp := Vector2(r.position.x + 58.0, r.position.y - 4.0) * S        # beside its PAD sign
		var sz := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
		draw_rect(Rect2(tp + Vector2(0, -14), Vector2(sz.x + 12, 19)), Color(0.02, 0.03, 0.05, 0.6))
		draw_rect(Rect2(tp + Vector2(0, -14), Vector2(3, 19)), Color(tc, 0.9))
		if not blink:
			draw_string(font, tp + Vector2(7, 0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, tc)
