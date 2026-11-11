extends Node2D
## 0.7.52.22 (Luz, package 52b): things to work on with your tools on foot – a maintenance box (cut its flap open with
## the cutting torch: a button or a terminal behind it), a terminal (hack it), a carved tablet and a relic (scan them).
## One node per thing, in the ground view's sorted layer, drawn in art px × SCALE. The things live in
## `GroundMap.explore` ({kind, pos, state, …}); a zone of kind "explore" (its `i`) lets you use them.
## No class_name: preload it.

const ChibiArtE = preload("res://scripts/ground/chibi_art.gd")
const TITLES := {"panel": "Maintenance box – cut it open (cutting torch)", "terminal": "Terminal – hack it",
	"tablet": "Carved tablet – scan it (scanner on your belt)", "relic": "Relic – scan it (scanner on your belt)",
	"blastdoor": "Blast door – sealed (its release is in the box beside it)"}
const INSCRIPTIONS := [
	"\"…the ninth gate was sealed when the sky went quiet. Those who stayed kept the lamps lit…\"",
	"\"Here the builders counted the years by the turning of the red star – four hundred and twelve.\"",
	"\"Water below, under the third pillar. Take only what you carry.\"",
	"\"We were many. We went down into the warm dark and did not come up.\"",
	"\"The engine sleeps beneath. Wake it with the song of the three keys.\"",
]

var view                                    # the GroundView
var i := 0                                  # its index in map.explore


## 0.7.52.23 (Luz): a blast door in a wall's gap, drawn in art px from the gap's bottom centre (0.7.52.24: redesigned).
func _draw_blastdoor(d: Dictionary, t: float) -> void:
	# 0.7.52.24 (Luz, after her pictures): an octagonal blast door set in a recessed frame in the wall – heavy grey plate,
	# two parallel diagonal seams cutting it in three; the small one narrow and tall, the wide one broad with gentler
	# seams. Opening, the outer parts slide into the walls and the middle one rises into the lintel. Lamp strips of
	# red, amber and white beside the frame show its state.
	var tl: Array = d["tiles"]
	var gw := float(tl[2]) * 16.0
	var gh := float(tl[3]) * 16.0
	var top := -gh
	var k := float(d.get("open_k", 0.0))
	var wide: bool = gw > 40.0
	var steel := Color(0.4, 0.43, 0.48)
	var gap := PackedVector2Array([Vector2(-gw * 0.5, top), Vector2(gw * 0.5, top), Vector2(gw * 0.5, 0), Vector2(-gw * 0.5, 0)])
	# the recessed frame: a dark rebate round the gap, a lit bevel at its top and left, a step at the sill
	draw_rect(Rect2(-gw * 0.5 - 5, top - 5, gw + 10, 5), Color(0.2, 0.21, 0.24))
	draw_rect(Rect2(-gw * 0.5 - 5, top - 5, 5, gh + 5), Color(0.24, 0.25, 0.28))
	draw_rect(Rect2(gw * 0.5, top - 5, 5, gh + 5), Color(0.16, 0.17, 0.19))
	draw_rect(Rect2(-gw * 0.5 - 5, top - 5, gw + 10, 1), Color(0.55, 0.57, 0.6))
	draw_rect(Rect2(-gw * 0.5 - 5, top - 5, 1, gh + 5), Color(0.48, 0.5, 0.53))
	for sx in [-gw * 0.5 - 4, gw * 0.5 + 1]:                         # slots along the jambs
		for sy in range(int(top) + 4, -4, 8):
			draw_rect(Rect2(sx + 1, sy, 2, 4), Color(0.1, 0.1, 0.12))
	# behind it, while it opens: the dark beyond
	draw_colored_polygon(gap, Color(0.04, 0.05, 0.06, 1.0 - k))
	# the plate: an octagon in the gap
	var c := minf(gw, gh) * (0.28 if not wide else 0.3)
	var oct := PackedVector2Array([Vector2(-gw * 0.5 + c, top + 1), Vector2(gw * 0.5 - c, top + 1), Vector2(gw * 0.5 - 1, top + c), Vector2(gw * 0.5 - 1, -c),
		Vector2(gw * 0.5 - c, -1), Vector2(-gw * 0.5 + c, -1), Vector2(-gw * 0.5 + 1, -c), Vector2(-gw * 0.5 + 1, top + c)])
	# the plate's corners outside the octagon: wall plating of the frame, flush and darker
	if k < 1.0:
		draw_colored_polygon(gap, Color(0.3, 0.32, 0.36, 1.0 - k))
	# the three parts, cut by two parallel seams (slope: steep for the small, gentle for the wide)
	var sl := gh / (gw * (0.55 if wide else 0.9))
	var off := gw * (0.22 if wide else 0.17)
	var seam := func(o: float) -> PackedVector2Array:          # a long thin band along a seam line through (o, mid)
		var mid := top + gh * 0.5
		var dv := Vector2(1.0, sl).normalized()
		return PackedVector2Array([Vector2(o, mid) - dv * 400.0, Vector2(o, mid) + dv * 400.0])
	var halfplane := func(o: float, side: float) -> PackedVector2Array:   # everything on one side of a seam line
		var mid := top + gh * 0.5
		var dv := Vector2(1.0, sl).normalized()
		var nv := Vector2(-dv.y, dv.x) * side
		var a := Vector2(o, mid) - dv * 400.0
		var b := Vector2(o, mid) + dv * 400.0
		return PackedVector2Array([a, b, b + nv * 400.0, a + nv * 400.0])
	var parts: Array = []
	var left_p := Geometry2D.intersect_polygons(oct, halfplane.call(-off, 1.0))
	var right_p := Geometry2D.intersect_polygons(oct, halfplane.call(off, -1.0))
	var mid_a := Geometry2D.intersect_polygons(oct, halfplane.call(-off, -1.0))
	var mid_p: Array = Geometry2D.intersect_polygons(mid_a[0], halfplane.call(off, 1.0)) if not mid_a.is_empty() else []
	if not left_p.is_empty():
		parts.append([left_p[0], Vector2(-gw * 0.55 * k, 0)])
	if not mid_p.is_empty():
		parts.append([mid_p[0], Vector2(0, -gh * k)])
	if not right_p.is_empty():
		parts.append([right_p[0], Vector2(gw * 0.55 * k, 0)])
	for pr in parts:
		if k >= 1.0:
			break                                      # fully open: the parts are in the walls
		var poly := PackedVector2Array()
		for p in (pr[0] as PackedVector2Array):
			poly.append(p + (pr[1] as Vector2))
		var clipped := Geometry2D.intersect_polygons(poly, gap)
		for cp in clipped:
			draw_colored_polygon(cp, steel)
			# mottled wear and a lit upper edge
			var bb := Rect2(cp[0], Vector2.ZERO)
			for q in cp:
				bb = bb.expand(q)
			for m in 7:
				var mp := bb.position + Vector2(hash_f(m, int(d.get("seed", 1))) * bb.size.x, hash_f(m + 9, int(d.get("seed", 1))) * bb.size.y)
				var mr := 1.5 + hash_f(m + 3, 5) * 2.5
				if Geometry2D.is_point_in_polygon(mp, cp) and Geometry2D.is_point_in_polygon(mp + Vector2(mr, mr), cp) and Geometry2D.is_point_in_polygon(mp - Vector2(mr, mr), cp):
					draw_circle(mp, mr, Color(0.34, 0.36, 0.41, 0.6))
			var outl := cp.duplicate()
			outl.append(outl[0])
			draw_polyline(outl, Color(0.2, 0.21, 0.24), 1.0)
	# the octagon's raised rim and the seams, while shut
	if k < 0.02:
		var ring := oct.duplicate()
		ring.append(ring[0])
		draw_polyline(ring, Color(0.56, 0.58, 0.62), 1.0)
		for o in [-off, off]:
			var sg: PackedVector2Array = seam.call(o)
			var cut := Geometry2D.intersect_polyline_with_polygon(sg, oct)
			for ln in cut:
				draw_polyline(ln, Color(0.12, 0.12, 0.14), 1.5)
				draw_polyline(PackedVector2Array([ln[0] + Vector2(1, 0), ln[1] + Vector2(1, 0)]), Color(0.55, 0.57, 0.6, 0.6), 1.0)
		# a service hatch with two slots high on the plate (the wide one)
		if wide:
			draw_rect(Rect2(-gw * 0.36, top + 4, gw * 0.22, 6), Color(0.33, 0.35, 0.39))
			draw_rect(Rect2(-gw * 0.36 + 2, top + 5, gw * 0.18, 1), Color(0.22, 0.23, 0.26))
			draw_rect(Rect2(-gw * 0.36 + 2, top + 8, gw * 0.18, 1), Color(0.22, 0.23, 0.26))
	# 0.7.52.25 (Luz): one lamp beside the frame – red shut, amber blinking while it opens, green open
	var state := 0 if String(d["state"]) != "open" else (1 if k < 1.0 else 2)
	var lc: Color = [Color(1.0, 0.2, 0.15), Color(1.0, 0.75, 0.15), Color(0.3, 1.0, 0.45)][state]
	var lit := state != 1 or fposmod(t * 4.0, 1.0) < 0.6
	for lx in ([-gw * 0.5 - 9.0] if not wide else [-gw * 0.5 - 9.0, gw * 0.5 + 5.0]):
		var lp := Vector2(lx + 2, top + gh * 0.36)
		draw_rect(Rect2(lp - Vector2(3, 3), Vector2(6, 6)), Color(0.08, 0.08, 0.09))
		draw_rect(Rect2(lp - Vector2(3, 3), Vector2(6, 1)), Color(0.4, 0.42, 0.45))
		draw_circle(lp, 2.0, lc if lit else lc.darkened(0.7))
		if lit:
			draw_circle(lp, 5.5, Color(lc, 0.22))


static func hash_f(a: int, b: int) -> float:
	return fposmod(sin(float(a) * 12.9898 + float(b) * 78.233) * 43758.5453, 1.0)


## 0.7.52.23 (Luz): the laser cage round the relic – four posts with glowing heads and red beams between them at three
## heights; off, the posts go dark and the beams are gone.
func _draw_cage(d: Dictionary, t: float) -> void:
	var tl: Array = d["tiles"]
	var cw := float(tl[2]) * 16.0 - 8.0
	var ch := float(tl[3]) * 16.0 - 8.0
	var on := String(d["state"]) != "off"
	var posts := [Vector2(-cw * 0.5, -ch), Vector2(cw * 0.5, -ch), Vector2(-cw * 0.5, 0), Vector2(cw * 0.5, 0)]
	# the beams behind first (the far row), then the posts, then the near beams
	if on:
		for hgt in [6.0, 13.0, 20.0]:
			var a := Color(1.0, 0.15, 0.1, 0.55 + 0.25 * sin(t * 13.0 + hgt))
			for pair in [[0, 1], [0, 2], [1, 3]]:
				var p0: Vector2 = posts[pair[0]] + Vector2(0, -hgt)
				var p1: Vector2 = posts[pair[1]] + Vector2(0, -hgt)
				draw_line(p0, p1, Color(1.0, 0.2, 0.15, 0.25), 3.0)
				draw_line(p0, p1, a, 1.0)
	for pp in posts:
		draw_rect(Rect2(pp + Vector2(-2, -24), Vector2(4, 24)), Color(0.25, 0.26, 0.3))
		draw_rect(Rect2(pp + Vector2(-2, -24), Vector2(1, 24)), Color(0.45, 0.47, 0.52))
		draw_rect(Rect2(pp + Vector2(-3, -27), Vector2(6, 4)), Color(0.18, 0.19, 0.22))
		draw_circle(pp + Vector2(0, -26), 1.8, Color(1.0, 0.3, 0.2) if on else Color(0.2, 0.2, 0.22))
	if on:
		for hgt2 in [6.0, 13.0, 20.0]:
			var p2: Vector2 = posts[2] + Vector2(0, -hgt2)
			var p3: Vector2 = posts[3] + Vector2(0, -hgt2)
			draw_line(p2, p3, Color(1.0, 0.2, 0.15, 0.3), 3.0)
			draw_line(p2, p3, Color(1.0, 0.45, 0.35, 0.8), 1.0)


static func add(map: GroundMap, kind: String, pos: Vector2, extra: Dictionary = {}) -> Dictionary:
	var d := {"kind": kind, "pos": pos, "state": "shut", "seed": randi() % 100000}
	d.merge(extra, true)
	if kind == "panel":
		d["inside"] = String(d.get("inside", "button"))
		d["shape"] = String(d.get("shape", ["rounded", "hex", "round", "trapezoid", "notched", "arch"][int(d["seed"]) % 6]))
		d["label"] = "MAINT-%02d" % (int(d["seed"]) % 90 + 10)
	if kind in ["panel", "terminal"]:
		d["actions"] = d.get("actions", ["door", "power", "data"])
	map.explore.append(d)
	if bool(d.get("no_zone", false)):
		return d
	map.zones.append({"rect": Rect2(pos - Vector2(16, 10), Vector2(32, 24)), "kind": "explore", "id": "explore",
		"i": map.explore.size() - 1, "title": String(TITLES.get(kind, kind))})
	return d


func _process(delta: float) -> void:
	var d: Dictionary = view.map.explore[i]
	if String(d["kind"]) == "blastdoor" and String(d["state"]) == "open":
		d["open_k"] = minf(1.0, float(d.get("open_k", 0.0)) + delta / 1.4)       # 0.7.52.23: it slides apart
	queue_redraw()


func _draw() -> void:
	var d: Dictionary = view.map.explore[i]
	var s := GroundMap.SCALE
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * s)
	var t := Time.get_ticks_msec() * 0.001
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, 0.45) * s)
	draw_circle(Vector2(0, 2), 9.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * s)
	match String(d["kind"]):
		"panel":
			# a steel box on its post, conduits in, the flap, its light
			draw_rect(Rect2(-1.5, -10, 3, 10), Color(0.25, 0.26, 0.29))
			draw_rect(Rect2(-9, -30, 18, 21), Color(0.12, 0.13, 0.15))
			draw_rect(Rect2(-8, -29, 16, 19), Color(0.38, 0.4, 0.44))
			draw_rect(Rect2(-8, -29, 16, 1), Color(0.55, 0.57, 0.6))
			draw_rect(Rect2(-6, -34, 2, 5), Color(0.2, 0.21, 0.24))
			draw_rect(Rect2(3, -34, 2, 5), Color(0.2, 0.21, 0.24))
			draw_rect(Rect2(-7, -13, 14, 2), Color(0.95, 0.78, 0.15))
			if String(d["state"]) == "shut":
				draw_rect(Rect2(-5, -26, 10, 11), Color(0.46, 0.48, 0.52))
				draw_rect(Rect2(-5, -26, 10, 11), Color(0.95, 0.9, 0.55, 0.6), false, 0.5)
			else:
				draw_rect(Rect2(-5, -26, 10, 11), Color(0.05, 0.05, 0.06))
				draw_circle(Vector2(0, -20.5), 2.5, Color(0.2, 0.9, 0.35) if String(d["inside"]) == "button" else Color(0.2, 0.9, 1.0))
			draw_circle(Vector2(6, -27), 1.0, Color(1.0, 0.25, 0.2) if fposmod(t, 1.2) < 0.9 else Color(0.3, 0.1, 0.1))
		"terminal":
			# a console on a stand, its screen alive
			draw_rect(Rect2(-3, -12, 6, 12), Color(0.22, 0.23, 0.26))
			draw_rect(Rect2(-10, -16, 20, 5), Color(0.3, 0.32, 0.36))
			draw_rect(Rect2(-9, -32, 18, 16), Color(0.14, 0.15, 0.17))
			var on: bool = String(d["state"]) != "dead"
			draw_rect(Rect2(-7.5, -30.5, 15, 12), Color(0.02, 0.1, 0.06) if on else Color(0.03, 0.03, 0.04))
			if on:
				for ln in 4:
					var w := 3.0 + fposmod(ln * 5.3 + t * 3.0, 9.0)
					draw_rect(Rect2(-6.5, -29 + ln * 2.6, w, 1), Color(0.3, 1.0, 0.6, 0.8) if String(d["state"]) != "hacked" else Color(0.4, 0.95, 1.0, 0.8))
			for k in 3:
				draw_rect(Rect2(-8 + k * 6, -15, 4, 2), Color(0.45, 0.47, 0.52))
		"tablet":
			draw_rect(Rect2(-9, -30, 18, 30), Color(0.08, 0.07, 0.06))
			draw_rect(Rect2(-8, -29, 16, 29), Color(0.55, 0.5, 0.44))
			draw_rect(Rect2(-8, -29, 16, 2), Color(0.66, 0.6, 0.53))
			for ln2 in 6:
				draw_rect(Rect2(-6, -25 + ln2 * 4, 12 - (ln2 % 3) * 2, 1), Color(0.33, 0.29, 0.25))
			if String(d["state"]) == "scanned":
				draw_rect(Rect2(-8, -29, 16, 29), Color(0.35, 0.9, 1.0, 0.15))
		"blastdoor":
			_draw_blastdoor(d, t)
		"cage":
			_draw_cage(d, t)
		"relic":
			draw_rect(Rect2(-7, -8, 14, 8), Color(0.3, 0.27, 0.32))
			draw_rect(Rect2(-7, -8, 14, 1), Color(0.45, 0.42, 0.48))
			var glow := 0.6 + 0.4 * sin(t * 2.0)
			var crystal := PackedVector2Array([Vector2(0, -26), Vector2(4, -16), Vector2(0, -9), Vector2(-4, -16)])
			draw_colored_polygon(crystal, Color(0.55, 0.35, 0.95))
			draw_colored_polygon(PackedVector2Array([Vector2(0, -26), Vector2(4, -16), Vector2(0, -16)]), Color(0.8, 0.65, 1.0))
			draw_circle(Vector2(0, -17), 7.0, Color(0.7, 0.5, 1.0, 0.18 * glow))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# the scan: a beam from your hand sweeping the thing, a ring filling
	var sc: Dictionary = view._scan
	if not sc.is_empty() and int(sc["i"]) == i:
		var k2 := clampf(float(sc["t"]) / float(sc["need"]), 0.0, 1.0)
		var hand: Vector2 = (view.pilot.pos - (d["pos"] as Vector2)) * s + Vector2(8, -60)
		var top := Vector2(0, -32) * s
		var bot := Vector2(0, -2) * s
		var sweep := top.lerp(bot, 0.5 + 0.5 * sin(t * 5.0))
		draw_colored_polygon(PackedVector2Array([hand, top + Vector2(-30, 0), bot + Vector2(-30, 0)]), Color(0.35, 0.9, 1.0, 0.1))
		draw_line(hand, sweep, Color(0.35, 0.9, 1.0, 0.75), 1.5)
		draw_line(sweep + Vector2(-30, 0), sweep + Vector2(30, 0), Color(0.5, 1.0, 1.0), 3.0)
		var c := Vector2(48, -110)
		draw_circle(c, 18.0, Color(0.03, 0.04, 0.08, 0.9))
		draw_arc(c, 15.0, -PI / 2, -PI / 2 + TAU * k2, 28, Color(0.35, 0.9, 1.0), 3.5)
		draw_string(ThemeDB.fallback_font, c + Vector2(-20, 4), "%d%%" % int(k2 * 100.0), HORIZONTAL_ALIGNMENT_CENTER, 40, 10, Color(0.9, 0.95, 1.0))
