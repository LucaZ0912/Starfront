extends Node2D
## 0.7.52.22 (Luz, package 52b): things to work on with your tools on foot – a maintenance box (cut its flap open with
## the cutting torch: a button or a terminal behind it), a terminal (hack it), a carved tablet and a relic (scan them).
## One node per thing, in the ground view's sorted layer, drawn in art px × SCALE. The things live in
## `GroundMap.explore` ({kind, pos, state, …}); a zone of kind "explore" (its `i`) lets you use them.
## No class_name: preload it.

const ChibiArtE = preload("res://scripts/ground/chibi_art.gd")
const TITLES := {"panel": "Maintenance box – cut it open (cutting torch)", "terminal": "Terminal – hack it",
	"tablet": "Carved tablet – scan it (scanner on your belt)", "relic": "Relic – scan it (scanner on your belt)"}
const INSCRIPTIONS := [
	"\"…the ninth gate was sealed when the sky went quiet. Those who stayed kept the lamps lit…\"",
	"\"Here the builders counted the years by the turning of the red star – four hundred and twelve.\"",
	"\"Water below, under the third pillar. Take only what you carry.\"",
	"\"We were many. We went down into the warm dark and did not come up.\"",
	"\"The engine sleeps beneath. Wake it with the song of the three keys.\"",
]

var view                                    # the GroundView
var i := 0                                  # its index in map.explore


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
	map.zones.append({"rect": Rect2(pos - Vector2(16, 10), Vector2(32, 24)), "kind": "explore", "id": "explore",
		"i": map.explore.size() - 1, "title": String(TITLES.get(kind, kind))})
	return d


func _process(_d: float) -> void:
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
