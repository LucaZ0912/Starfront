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


## 0.7.52.23 (Luz): a heavy blast door in a wall's gap – two leaves with chevrons, a seam, bolts, a frame with warning
## lights; open, the leaves slide into the walls. Drawn in art px from the gap's bottom centre.
func _draw_blastdoor(d: Dictionary, t: float) -> void:
	var tl: Array = d["tiles"]
	var gw := float(tl[2]) * 16.0
	var gh := float(tl[3]) * 16.0
	var top := -gh
	var k := float(d.get("open_k", 0.0))
	# the frame round the gap
	draw_rect(Rect2(-gw * 0.5 - 4, top - 4, 4, gh + 4), Color(0.12, 0.13, 0.15))          # the frame's dark edge
	draw_rect(Rect2(gw * 0.5, top - 4, 4, gh + 4), Color(0.12, 0.13, 0.15))
	draw_rect(Rect2(-gw * 0.5 - 4, top - 4, gw + 8, 4), Color(0.12, 0.13, 0.15))
	draw_rect(Rect2(-gw * 0.5 - 3, top - 3, 3, gh + 3), Color(0.45, 0.47, 0.5))
	draw_rect(Rect2(gw * 0.5, top - 3, 3, gh + 3), Color(0.3, 0.32, 0.35))
	draw_rect(Rect2(-gw * 0.5 - 3, top - 4, gw + 6, 3), Color(0.5, 0.52, 0.55))
	# what is behind: the dark of the vault while it opens, the floor once it is open
	draw_rect(Rect2(-gw * 0.5, top, gw, gh), Color(0.05, 0.06, 0.08, 1.0 - k))
	# the leaves
	var half := gw * 0.5 * (1.0 - k)
	for side in [-1.0, 1.0]:
		if half < 0.5:
			continue
		var x0 := -half if side < 0.0 else 0.0
		var x0b := -gw * 0.5 if side < 0.0 else gw * 0.5 - half
		var r := Rect2(x0b, top, half, gh)
		draw_rect(r, Color(0.36, 0.38, 0.42))
		draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), Color(0.55, 0.57, 0.6))
		# chevrons in yellow and black, slanting to the seam
		var y := top + 8.0
		while y < -6.0:
			var pts := PackedVector2Array([Vector2(r.position.x, y), Vector2(r.end.x, y + 5.0 * side), Vector2(r.end.x, y + 5.0 * side + 3.0), Vector2(r.position.x, y + 3.0)])
			draw_colored_polygon(pts, Color(0.95, 0.78, 0.15))
			y += 8.0
		draw_rect(Rect2(r.position.x, -6, r.size.x, 4), Color(0.2, 0.21, 0.24))
		for by in [top + 4, -10.0]:
			draw_circle(Vector2(r.position.x + r.size.x * 0.5, by), 1.2, Color(0.65, 0.67, 0.7))
		x0 = x0
	if k < 0.05:
		draw_line(Vector2(0, top), Vector2(0, 0), Color(0.08, 0.08, 0.1), 1.5)                  # the seam
		draw_rect(Rect2(-3, top + gh * 0.45, 6, 5), Color(0.15, 0.16, 0.18))                    # the lock
		draw_rect(Rect2(-2, top + gh * 0.45 + 1, 4, 2), Color(1.0, 0.25, 0.2) if fposmod(t, 1.0) < 0.6 else Color(0.4, 0.1, 0.08))
	# the warning lights over the door: red while sealed, green open, turning while it opens
	for lx in [-gw * 0.5 - 2, gw * 0.5 + 2]:
		var lc := Color(1.0, 0.25, 0.2) if String(d["state"]) != "open" else (Color(1.0, 0.75, 0.2) if k < 1.0 else Color(0.3, 1.0, 0.45))
		var on := fposmod(t * (3.0 if k > 0.0 and k < 1.0 else 1.0), 1.0) < 0.6
		draw_circle(Vector2(lx, top - 7), 2.5, lc if on else lc.darkened(0.6))
		draw_circle(Vector2(lx, top - 7), 6.0, Color(lc, 0.2 if on else 0.05))


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
