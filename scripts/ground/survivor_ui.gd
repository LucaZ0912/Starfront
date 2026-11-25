extends RefCounted
## Package 62a, part 7 (Luz): what Survivor shows over the picture.
##   Hud:     the shards towards the next level (a bar of segments across the top), the level, the clock, who is
##            out; at the foot your health and your dodges; at the left the five places for weapons and the five
##            for boni with their levels.
##   LevelUp: a new level: the run stands still, three cards, you take one (mouse, 1 / 2 / 3, or left / right and
##            Enter; the controller: left / right and cross). The card goes through the command bus, by seat.
##   Intro:   the picture before a run: you; the stage; the weapon you begin with.
##   Result:  the run is over: the time, who you put out, your level, what it pays.
##   Console: (part 7c-3) the console in the lobby: what your cores buy for good.
## Part 7c-1 (Luz: more detail, more colour, more neon): frames of light with brackets at their corners, a grid of
## light behind, each sign in a six-sided frame with rings turning round it; a card says in figures what it changes
## and what it fuses into.
## No class_name: preload("res://scripts/ground/survivor_ui.gd").

const SD = preload("res://data/survivor.gd")
const CYAN := Color(0.4, 0.92, 1.0)
const GOLD := Color(1.0, 0.82, 0.35)
const PINK := Color(1.0, 0.4, 0.8)
const GREEN := Color(0.4, 1.0, 0.6)
const RED := Color(1.0, 0.42, 0.42)
const DARK := Color(0.03, 0.04, 0.085)


## The colour of a card by its kind.
static func card_color(kind: String) -> Color:
	return {"weapon": GREEN, "up": CYAN, "bonus": GOLD, "bonus_up": GOLD, "ult": PINK, "heal": RED, "coins": GOLD}.get(kind, CYAN)


## Six corners round `c` (the first one again at the end, for a line all round).
static func hexpts(c: Vector2, r: float, rot: float = 0.0) -> PackedVector2Array:
	var out := PackedVector2Array()
	for q in 7:
		out.append(c + Vector2.from_angle(rot + q * TAU / 6.0) * r)
	return out


## A six-sided frame of light round `c`: a soft shine behind, the frame, two pairs of arcs turning round it.
static func hex_frame(ci: CanvasItem, c: Vector2, r: float, col: Color, t: float) -> void:
	for g in 4:
		ci.draw_circle(c, r * (1.25 - g * 0.2), Color(col, 0.03 + 0.022 * g))
	var inner := hexpts(c, r * 0.86, PI / 6.0)
	ci.draw_colored_polygon(inner.slice(0, 6), Color(DARK, 0.92))
	ci.draw_polyline(hexpts(c, r, PI / 6.0), Color(col, 0.95), 2.0)
	ci.draw_polyline(inner, Color(col, 0.3), 1.0)
	for q in 2:
		ci.draw_arc(c, r * 1.22, t * 0.9 + q * PI, t * 0.9 + q * PI + 1.15, 14, Color(col, 0.75), 2.0)
		ci.draw_arc(c, r * 1.36, -t * 0.6 + q * PI + 0.8, -t * 0.6 + q * PI + 1.5, 10, Color(col, 0.4), 1.5)


## Brackets of light at the four corners of `r`.
static func brackets(ci: CanvasItem, r: Rect2, col: Color, length: float = 22.0, wide: float = 3.0) -> void:
	for cx in 2:
		for cy in 2:
			var p := Vector2(r.position.x if cx == 0 else r.end.x, r.position.y if cy == 0 else r.end.y)
			var dx := 1.0 if cx == 0 else -1.0
			var dy := 1.0 if cy == 0 else -1.0
			ci.draw_rect(Rect2(Vector2(minf(p.x, p.x + dx * length), minf(p.y, p.y + dy * wide)), Vector2(length, wide)), col)
			ci.draw_rect(Rect2(Vector2(minf(p.x, p.x + dx * wide), minf(p.y, p.y + dy * length)), Vector2(wide, length)), col)


## The sign of a weapon, a bonus or a card, drawn round `c`.
static func icon(ci: CanvasItem, id: String, c: Vector2, r: float, col: Color) -> void:
	match id:
		"pulse":
			ci.draw_arc(c, r, 0.0, TAU, 28, col, 2.0)
			ci.draw_arc(c, r * 0.55, 0.0, TAU, 20, Color(col, 0.6), 2.0)
			ci.draw_circle(c, 2.5, col)
		"laser":
			ci.draw_line(c + Vector2(-r, r * 0.7), c + Vector2(r * 0.8, -r * 0.6), col, 3.0)
			ci.draw_circle(c + Vector2(r * 0.8, -r * 0.6), 3.5, col)
			ci.draw_circle(c + Vector2(-r, r * 0.7), 2.0, Color(col, 0.6))
		"plasma":                                           # a grenade and its burst
			ci.draw_circle(c, r * 0.45, col)
			for q in 6:
				var d := Vector2.from_angle(q * TAU / 6.0)
				ci.draw_line(c + d * r * 0.65, c + d * r, col, 2.0)
		"drone":                                            # shots in a ring
			ci.draw_rect(Rect2(c - Vector2(3.0, 3.0), Vector2(6.0, 6.0)), col)
			for q2 in 8:
				ci.draw_circle(c + Vector2.from_angle(q2 * TAU / 8.0) * r * 0.85, 2.0, col)
		"superlaser":                                       # a quarter of the round, swept
			ci.draw_arc(c + Vector2(-r * 0.7, r * 0.7), r * 1.5, -PI * 0.5, 0.0, 12, Color(col, 0.6), 2.0)
			ci.draw_line(c + Vector2(-r * 0.7, r * 0.7), c + Vector2(r * 0.75, -r * 0.35), col, 5.0)
		"blade":                                            # a blade with four points
			var st := PackedVector2Array()
			for q3 in 8:
				st.append(c + Vector2.from_angle(q3 * PI * 0.25 + 0.4) * (r if q3 % 2 == 0 else r * 0.3))
			ci.draw_colored_polygon(st, col)
		"amp":                                              # wider
			ci.draw_arc(c, r * 0.4, 0.0, TAU, 16, col, 2.0)
			ci.draw_arc(c, r, -0.6, 0.6, 8, col, 2.0)
			ci.draw_arc(c, r, PI - 0.6, PI + 0.6, 8, col, 2.0)
		"coolant":                                          # a crystal of frost
			for q4 in 3:
				var d4 := Vector2.from_angle(q4 * PI / 3.0 + PI * 0.5)
				ci.draw_line(c - d4 * r, c + d4 * r, col, 2.0)
		"reactor":                                          # a core in its ring
			ci.draw_circle(c, r * 0.4, col)
			ci.draw_arc(c, r * 0.85, 0.3, 2.4, 12, col, 2.5)
			ci.draw_arc(c, r * 0.85, 3.4, 5.6, 12, col, 2.5)
		"magnet":                                           # a horseshoe
			ci.draw_arc(c + Vector2(0.0, r * 0.1), r * 0.7, 0.0, PI, 14, col, 4.0)
			ci.draw_line(c + Vector2(-r * 0.7, r * 0.1), c + Vector2(-r * 0.7, -r * 0.8), col, 4.0)
			ci.draw_line(c + Vector2(r * 0.7, r * 0.1), c + Vector2(r * 0.7, -r * 0.8), col, 4.0)
		"nanite":                                           # a heart of small parts
			ci.draw_rect(Rect2(c + Vector2(-r * 0.2, -r * 0.8), Vector2(r * 0.4, r * 1.6)), col)
			ci.draw_rect(Rect2(c + Vector2(-r * 0.8, -r * 0.2), Vector2(r * 1.6, r * 0.4)), col)
			ci.draw_arc(c, r, 0.0, TAU, 20, Color(col, 0.5), 1.5)
		"servo":                                            # faster
			for q5 in 2:
				var ox := (q5 - 0.5) * r * 0.9
				ci.draw_polyline(PackedVector2Array([c + Vector2(ox - r * 0.35, -r * 0.7), c + Vector2(ox + r * 0.35, 0.0), c + Vector2(ox - r * 0.35, r * 0.7)]), col, 3.0)
		"shield":                                           # a dome
			ci.draw_arc(c + Vector2(0.0, r * 0.4), r, PI, TAU, 16, col, 3.0)
			ci.draw_line(c + Vector2(-r, r * 0.4), c + Vector2(r, r * 0.4), col, 2.0)
		"stasis":                                           # a glass of sand
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.7, -r), c + Vector2(r * 0.7, -r), c]), col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.7, r), c + Vector2(r * 0.7, r), c]), Color(col, 0.6))
		"overdrive":                                        # a bolt
			ci.draw_polyline(PackedVector2Array([c + Vector2(r * 0.3, -r), c + Vector2(-r * 0.4, 0.0), c + Vector2(r * 0.2, 0.0), c + Vector2(-r * 0.3, r)]), col, 3.0)
		"bomb":                                             # the three blades of the warning sign
			ci.draw_circle(c, r * 0.25, col)
			for q6 in 3:
				ci.draw_arc(c, r * 0.7, q6 * TAU / 3.0 - 0.5, q6 * TAU / 3.0 + 0.5, 8, col, r * 0.5)
		"medkit", "heal":
			ci.draw_rect(Rect2(c + Vector2(-r * 0.25, -r), Vector2(r * 0.5, r * 2.0)), col)
			ci.draw_rect(Rect2(c + Vector2(-r, -r * 0.25), Vector2(r * 2.0, r * 0.5)), col)
		"coins":
			ci.draw_circle(c, r * 0.8, col)
			ci.draw_circle(c, r * 0.45, Color(col.darkened(0.35), 1.0))
		"mines":                                            # a disc, its prongs, its light
			ci.draw_arc(c, r * 0.8, 0.0, TAU, 20, col, 2.5)
			ci.draw_circle(c, r * 0.28, col)
			for q7 in 4:
				var d7 := Vector2.from_angle(q7 * PI * 0.5 + PI * 0.25)
				ci.draw_line(c + d7 * r * 0.8, c + d7 * r * 1.15, col, 2.5)
		"sentry":                                           # a gun on three legs
			ci.draw_rect(Rect2(c + Vector2(-r * 0.45, -r * 0.8), Vector2(r * 0.95, r * 0.7)), col)
			ci.draw_line(c + Vector2(-r * 0.45, -r * 0.45), c + Vector2(-r * 1.1, -r * 0.45), col, 3.0)
			ci.draw_line(c + Vector2(0.0, -r * 0.1), c + Vector2(-r * 0.7, r), col, 2.0)
			ci.draw_line(c + Vector2(0.0, -r * 0.1), c + Vector2(r * 0.7, r), col, 2.0)
			ci.draw_line(c + Vector2(0.0, -r * 0.1), c + Vector2(0.0, r), col, 2.0)
		"cryo":                                             # a cone, flakes in it
			ci.draw_polyline(PackedVector2Array([c + Vector2(r, -r * 0.8), c + Vector2(-r, 0.0), c + Vector2(r, r * 0.8)]), col, 2.5)
			for q8 in 3:
				ci.draw_rect(Rect2(c + Vector2(r * (0.05 + q8 * 0.3), (q8 - 1) * r * 0.36) - Vector2(2.0, 2.0), Vector2(4.0, 4.0)), col)
		"gravity":                                          # a sphere, what it pulls in
			ci.draw_circle(c, r * 0.32, col)
			ci.draw_arc(c, r * 0.7, 0.4, 2.6, 10, col, 2.0)
			ci.draw_arc(c, r * 0.7, 3.55, 5.75, 10, col, 2.0)
			ci.draw_arc(c, r * 1.05, 2.0, 3.6, 10, Color(col, 0.6), 2.0)
			ci.draw_arc(c, r * 1.05, 5.15, 6.75, 10, Color(col, 0.6), 2.0)
		"stabiliser":                                       # a clock, held
			ci.draw_arc(c, r * 0.7, 0.0, TAU, 20, col, 2.0)
			ci.draw_line(c, c + Vector2(0.0, -r * 0.45), col, 2.0)
			ci.draw_line(c, c + Vector2(r * 0.32, 0.0), col, 2.0)
			ci.draw_line(c + Vector2(-r * 1.05, -r * 0.5), c + Vector2(-r * 1.05, r * 0.5), col, 2.5)
			ci.draw_line(c + Vector2(r * 1.05, -r * 0.5), c + Vector2(r * 1.05, r * 0.5), col, 2.5)
		"overclock":                                        # one more
			ci.draw_rect(Rect2(c + Vector2(-r * 0.95, -r * 0.7), Vector2(r * 0.3, r * 1.4)), col)
			ci.draw_rect(Rect2(c + Vector2(-r * 0.45, -r * 0.7), Vector2(r * 0.3, r * 1.4)), col)
			ci.draw_line(c + Vector2(r * 0.15, 0.0), c + Vector2(r, 0.0), col, 3.0)
			ci.draw_line(c + Vector2(r * 0.58, -r * 0.42), c + Vector2(r * 0.58, r * 0.42), col, 3.0)
		"shieldcell":                                       # a six-sided cell
			ci.draw_polyline(hexpts(c, r * 0.95, PI / 6.0), col, 2.5)
			ci.draw_colored_polygon(hexpts(c, r * 0.48, PI / 6.0).slice(0, 6), col)
		"scavenger":                                        # shards, and more of them
			for q9 in 3:
				var sc := c + Vector2((q9 - 1) * r * 0.7, r * 0.3 if q9 != 1 else -r * 0.3)
				ci.draw_colored_polygon(PackedVector2Array([sc + Vector2(0.0, -r * 0.5), sc + Vector2(r * 0.3, 0.0), sc + Vector2(0.0, r * 0.5), sc + Vector2(-r * 0.3, 0.0)]), col)
		"lucky":                                            # a crate, a star over it
			ci.draw_rect(Rect2(c + Vector2(-r * 0.7, 0.05 * r), Vector2(r * 1.4, r * 0.8)), col, false, 2.0)
			ci.draw_line(c + Vector2(-r * 0.7, r * 0.35), c + Vector2(r * 0.7, r * 0.35), col, 2.0)
			for q10 in 4:
				var d10 := Vector2.from_angle(q10 * PI * 0.25)
				ci.draw_line(c + Vector2(0.0, -r * 0.55) - d10 * r * 0.38, c + Vector2(0.0, -r * 0.55) + d10 * r * 0.38, col, 2.0)
		"taser":                                            # two prongs, a bolt jumping from them
			ci.draw_line(c + Vector2(-r, -r * 0.45), c + Vector2(-r * 0.35, -r * 0.45), col, 3.0)
			ci.draw_line(c + Vector2(-r, r * 0.45), c + Vector2(-r * 0.35, r * 0.45), col, 3.0)
			ci.draw_polyline(PackedVector2Array([c + Vector2(-r * 0.3, 0.0), c + Vector2(r * 0.1, -r * 0.5), c + Vector2(r * 0.3, r * 0.3), c + Vector2(r * 0.65, -r * 0.3), c + Vector2(r, r * 0.15)]),
				col, 2.5)
		"blackhole":                                        # nothing, a disc of light round it
			ci.draw_circle(c, r * 0.4, col)
			var bh := PackedVector2Array()
			for q12 in 21:
				bh.append(c + Vector2(cos(q12 * TAU / 20.0) * r * 1.05, sin(q12 * TAU / 20.0) * r * 0.38).rotated(-0.4))
			ci.draw_polyline(bh, col, 2.0)
		"capacitor":                                        # two plates, a spark between them
			ci.draw_rect(Rect2(c + Vector2(-r * 0.5, -r * 0.75), Vector2(r * 0.22, r * 1.5)), col)
			ci.draw_rect(Rect2(c + Vector2(r * 0.28, -r * 0.75), Vector2(r * 0.22, r * 1.5)), col)
			ci.draw_line(c + Vector2(-r * 1.05, 0.0), c + Vector2(-r * 0.5, 0.0), col, 2.0)
			ci.draw_line(c + Vector2(r * 0.5, 0.0), c + Vector2(r * 1.05, 0.0), col, 2.0)
			ci.draw_circle(c, r * 0.14, col)
		"massdriver":                                       # a push, and what it throws
			ci.draw_line(c + Vector2(-r, 0.0), c + Vector2(r * 0.1, 0.0), col, 3.0)
			ci.draw_polyline(PackedVector2Array([c + Vector2(-r * 0.3, -r * 0.45), c + Vector2(r * 0.15, 0.0), c + Vector2(-r * 0.3, r * 0.45)]), col, 3.0)
			ci.draw_rect(Rect2(c + Vector2(r * 0.4, -r * 0.5), Vector2(r * 0.6, r)), col)
		"override":                                         # a machine's eye, yours now: a six-sided frame, the eye, a tick
			ci.draw_polyline(hexpts(c, r, PI / 6.0), col, 2.0)
			ci.draw_circle(c + Vector2(0.0, -r * 0.2), r * 0.24, col)
			ci.draw_polyline(PackedVector2Array([c + Vector2(-r * 0.45, r * 0.3), c + Vector2(-r * 0.1, r * 0.6), c + Vector2(r * 0.5, r * 0.05)]), col, 2.5)
		"orbs":                                             # three orbs on their round
			ci.draw_arc(c, r * 0.8, 0.0, TAU, 24, Color(col, 0.45), 1.5)
			for q in 3:
				ci.draw_circle(c + Vector2.from_angle(-PI * 0.5 + q * TAU / 3.0) * r * 0.8, r * 0.28, col)
			ci.draw_circle(c, 2.0, Color(col, 0.7))
		"gyro":                                             # a wheel in its ring, tilted, on its axle
			ci.draw_arc(c, r, 0.0, TAU, 24, col, 2.0)
			var wheel := PackedVector2Array()                     # (drawn point by point: an icon must leave the window's own placing alone)
			for q in 21:
				wheel.append(c + Vector2(cos(q * TAU / 20.0) * r * 0.8, sin(q * TAU / 20.0) * r * 0.32).rotated(-0.5))
			ci.draw_polyline(wheel, col, 2.5)
			ci.draw_line(c + Vector2(0.0, -r * 1.15), c + Vector2(0.0, r * 1.15), Color(col, 0.7), 2.0)
			ci.draw_circle(c, 2.5, col)
		"core":                                             # a core: a six-sided cell, a point of light in it
			ci.draw_polyline(hexpts(c, r, 0.0), col, 2.0)
			ci.draw_polyline(hexpts(c, r * 0.55, 0.0), Color(col, 0.6), 1.5)
			ci.draw_circle(c, r * 0.22, col)
		"thermal":                                          # (part 9b) a core, heat rising from it
			ci.draw_circle(c + Vector2(0.0, r * 0.5), r * 0.34, col)
			for qth in 3:
				var xth := (qth - 1) * r * 0.6
				ci.draw_polyline(PackedVector2Array([c + Vector2(xth, r * 0.05), c + Vector2(xth + r * 0.2, -r * 0.3), c + Vector2(xth - r * 0.14, -r * 0.65), c + Vector2(xth + r * 0.1, -r)]), col, 2.0)
		"seal":                                             # (part 11b) a doorway, a field across it
			ci.draw_line(c + Vector2(-r * 0.85, -r), c + Vector2(-r * 0.85, r), col, 2.5)
			ci.draw_line(c + Vector2(r * 0.85, -r), c + Vector2(r * 0.85, r), col, 2.5)
			for qse in 3:
				ci.draw_line(c + Vector2(-r * 0.6, (qse - 1) * r * 0.6), c + Vector2(r * 0.6, (qse - 1) * r * 0.6), Color(col, 0.8), 1.5)
		"lock":
			ci.draw_rect(Rect2(c + Vector2(-r * 0.65, -r * 0.1), Vector2(r * 1.3, r * 0.95)), col)
			ci.draw_arc(c + Vector2(0.0, -r * 0.1), r * 0.45, PI, TAU, 10, col, 2.5)
		"reroll":                                           # two arrows, one after the other, round
			for q11 in 2:
				var a11 := q11 * PI
				ci.draw_arc(c, r * 0.75, a11 + 0.5, a11 + 2.7, 12, col, 2.5)
				var tip := c + Vector2.from_angle(a11 + 2.7) * r * 0.75
				var tang := Vector2.from_angle(a11 + 2.7 + PI * 0.5)
				ci.draw_colored_polygon(PackedVector2Array([tip + tang * r * 0.45, tip - tang * r * 0.1 + tang.orthogonal() * r * 0.35, tip - tang * r * 0.1 - tang.orthogonal() * r * 0.35]), col)
		"revive":                                           # a line of life that goes on
			ci.draw_polyline(PackedVector2Array([c + Vector2(-r, 0.0), c + Vector2(-r * 0.45, 0.0), c + Vector2(-r * 0.2, -r * 0.75), c + Vector2(r * 0.15, r * 0.65), c + Vector2(r * 0.4, 0.0),
				c + Vector2(r, 0.0)]), col, 2.5)
		_:
			ci.draw_rect(Rect2(c - Vector2(r, r) * 0.7, Vector2(r, r) * 1.4), col, false, 2.0)


class Hud extends Control:
	var game
	var ui = load("res://scripts/ground/survivor_ui.gd")
	var _t := 0.0

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(dt: float) -> void:
		_t += dt

	## One place for a weapon or a bonus: dark, a frame of light, brackets at its corners.
	func _slot(r: Rect2, col: Color, full: bool) -> void:
		draw_rect(r, Color(DARK, 0.88))
		if full:
			draw_rect(r.grow(2.0), Color(col, 0.12))
			draw_rect(r, Color(col, 0.55), false, 1.0)
			ui.brackets(self, r, col, 10.0, 2.0)
		else:
			draw_rect(r, Color(0.4, 0.46, 0.58, 0.35), false, 1.0)
			draw_line(r.get_center() + Vector2(-5.0, 0.0), r.get_center() + Vector2(5.0, 0.0), Color(0.4, 0.46, 0.58, 0.3), 1.0)
			draw_line(r.get_center() + Vector2(0.0, -5.0), r.get_center() + Vector2(0.0, 5.0), Color(0.4, 0.46, 0.58, 0.3), 1.0)

	func _draw() -> void:
		if game == null or not is_instance_valid(game):
			return
		var run: Dictionary = game.run
		var vs := get_viewport_rect().size
		var font := ThemeDB.fallback_font
		# ---- the shards towards the next level: a bar of segments, your level in a six-sided plate at its left end
		# (a picture too narrow for it, a half of a split screen: the bar under the place's title instead of running
		# into it, the health above the weapons and the list of what happens instead of into the list)
		var bw := minf(660.0, vs.x - 190.0)
		var slim_top: bool = vs.x * 0.5 - bw * 0.5 - 66.0 < 560.0         # (the place's title plate reaches about this far)
		var bx := vs.x * 0.5 - bw * 0.5 - (9.0 if slim_top else 0.0)
		var by := 76.0 if slim_top else 18.0
		var plate := Rect2(bx - 66.0, by - 8.0, bw + 150.0, 34.0)
		draw_rect(plate, Color(DARK, 0.84))
		draw_line(Vector2(plate.position.x, plate.end.y), Vector2(plate.end.x, plate.end.y), Color(CYAN, 0.8), 2.0)
		ui.brackets(self, plate, Color(CYAN, 0.7), 12.0, 2.0)
		var need: int = SD.need(int(run["level"]))
		var k := clampf(float(int(run["xp"])) / float(need), 0.0, 1.0)
		var segs := 28
		var sw := (bw - (segs - 1) * 3.0) / segs
		for q in segs:
			var fill := clampf(k * segs - q, 0.0, 1.0)
			var sr := Rect2(bx + q * (sw + 3.0), by, sw, 18.0)
			draw_rect(sr, Color(0.1, 0.16, 0.24))
			if fill > 0.0:
				draw_rect(Rect2(sr.position, Vector2(sr.size.x * fill, sr.size.y)), CYAN.lerp(Color(1, 1, 1), 0.45 if (k * segs - q) < 1.0 else 0.0))
				draw_rect(Rect2(sr.position, Vector2(sr.size.x * fill, 4.0)), Color(1, 1, 1, 0.35))
		var lc := Vector2(bx - 34.0, by + 9.0)
		draw_colored_polygon((ui.hexpts(lc, 22.0, PI / 6.0) as PackedVector2Array).slice(0, 6), DARK)
		draw_polyline(ui.hexpts(lc, 22.0, PI / 6.0), CYAN, 2.0)
		draw_string(font, lc + Vector2(-22.0, 7.0), "%d" % int(run["level"]), HORIZONTAL_ALIGNMENT_CENTER, 44.0, 19, Color(1, 1, 1))
		draw_string(font, Vector2(bx - 66.0, by + 44.0), "LEVEL", HORIZONTAL_ALIGNMENT_CENTER, 64.0, 10, Color(CYAN, 0.85))
		draw_string(font, Vector2(bx + bw + 8.0, by + 16.0), "%d" % int(run["kills"]), HORIZONTAL_ALIGNMENT_LEFT, 80.0, 18, GOLD)
		draw_string(font, Vector2(bx + bw + 8.0, by + 44.0), "OUT", HORIZONTAL_ALIGNMENT_LEFT, 80.0, 10, Color(GOLD, 0.85))
		# ---- the clock, on a plate under the bar
		var cx := vs.x * 0.5
		draw_colored_polygon(PackedVector2Array([Vector2(cx - 118.0, by + 26.0), Vector2(cx + 118.0, by + 26.0), Vector2(cx + 92.0, by + 82.0), Vector2(cx - 92.0, by + 82.0)]), Color(DARK, 0.84))
		draw_line(Vector2(cx - 92.0, by + 82.0), Vector2(cx + 92.0, by + 82.0), Color(CYAN, 0.8), 2.0)
		draw_string(font, Vector2(cx - 118.0, by + 68.0), SD.time_text(float(run["t"])), HORIZONTAL_ALIGNMENT_CENTER, 236.0, 38, Color(1, 1, 1))
		draw_string(font, Vector2(cx - 118.0, by + 100.0), "of %s" % SD.time_text(SD.RUN_TIME), HORIZONTAL_ALIGNMENT_CENTER, 236.0, 12, Color(0.72, 0.78, 0.9))
		# ---- at the foot: your health in segments, your dodges
		var hbw := minf(600.0, vs.x - 340.0)
		var slim_foot: bool = vs.x * 0.5 + hbw * 0.5 + 170.0 > vs.x - 465.0      # (the list of what happens begins about there)
		var hb := Rect2(vs.x * 0.5 - hbw * 0.5, vs.y - (224.0 if slim_foot else 42.0), hbw, 16.0)
		var hk := clampf(float(run["hp"]) / SD.max_hp(run), 0.0, 1.0)
		var hcol := RED if hk < 0.35 else GREEN
		draw_rect(hb.grow(5.0), Color(DARK, 0.84))
		ui.brackets(self, hb.grow(5.0), Color(hcol, 0.7), 10.0, 2.0)
		var hsegs := 20
		var hw := (hb.size.x - (hsegs - 1) * 3.0) / hsegs
		for q2 in hsegs:
			var hf := clampf(hk * hsegs - q2, 0.0, 1.0)
			var hr := Rect2(hb.position.x + q2 * (hw + 3.0), hb.position.y, hw, hb.size.y)
			draw_rect(hr, Color(0.12, 0.14, 0.18))
			if hf > 0.0:
				draw_rect(Rect2(hr.position, Vector2(hr.size.x * hf, hr.size.y)), hcol if not (hk < 0.35 and fposmod(_t * 3.0, 1.0) < 0.5) else hcol.lightened(0.4))
				draw_rect(Rect2(hr.position, Vector2(hr.size.x * hf, 4.0)), Color(1, 1, 1, 0.3))
		draw_string(font, Vector2(hb.position.x - 110.0, hb.position.y + 14.0), "%d / %d" % [int(ceil(clampf(float(run["hp"]), 0.0, SD.max_hp(run)))), int(SD.max_hp(run))], HORIZONTAL_ALIGNMENT_RIGHT, 100.0, 15, hcol)
		for dq in 2:
			var full: bool = float(game.dash_charges) >= float(dq + 1)
			var dc := Vector2(hb.end.x + 26.0 + dq * 24.0, hb.position.y + 8.0)
			draw_colored_polygon(PackedVector2Array([dc + Vector2(-8.0, -8.0), dc + Vector2(2.0, -8.0), dc + Vector2(9.0, 0.0), dc + Vector2(2.0, 8.0), dc + Vector2(-8.0, 8.0), dc + Vector2(-1.0, 0.0)]),
				GREEN if full else Color(0.14, 0.2, 0.2))
		draw_string(font, Vector2(hb.end.x + 68.0, hb.position.y + 13.0), "%s dodge" % (game.view.key_of("foot_dodge") if game.view != null and Players.split else Keybinds.key_text("foot_dodge")), HORIZONTAL_ALIGNMENT_LEFT, 200.0, 12, Color(0.72, 0.8, 0.86))
		var ex := hb.end.x + 34.0                                # (part 7c-3) beside them: the Shield Cell as it charges, the last chance while it is still to come
		if float(game.mods.get("cell", 0.0)) > 0.0:
			var ck := 1.0 - clampf(float(game.cell_t) / float(game.mods["cell"]), 0.0, 1.0)
			var ec := Vector2(ex, hb.position.y - 28.0)
			draw_circle(ec, 16.0, Color(DARK, 0.86))
			draw_arc(ec, 14.0, -PI * 0.5, -PI * 0.5 + TAU * ck, 24, CYAN if ck >= 1.0 else Color(CYAN, 0.45), 2.5)
			ui.icon(self, "shieldcell", ec, 7.0, CYAN if ck >= 1.0 else Color(0.4, 0.5, 0.6))
			ex += 40.0
		if bool(run.get("revive", false)):
			var vc := Vector2(ex, hb.position.y - 28.0)
			draw_circle(vc, 16.0, Color(DARK, 0.86))
			draw_arc(vc, 14.0, 0.0, TAU, 24, PINK, 2.0)
			ui.icon(self, "revive", vc, 8.0, PINK.lightened(0.2))
		# ---- at the left: the places for weapons and for boni
		var ss := 50.0
		var gap := 6.0
		var two_on: bool = game != null and game.two != null and is_instance_valid(game.two)      # split screen: a row for the second player's weapons above yours
		for grp in (4 if two_on else 2):                     # (0, 1: your weapons and boni; 2, 3: the second player's, above yours)
			var items: Array = (run["boni"] if grp == 1 else run.get("boni2", [])) if grp % 2 == 1 else (game.weapons_of(grp / 2) if two_on else run["weapons"])
			var gy := vs.y - 150.0 + (grp % 2) * (ss + 24.0) - (2.0 * (ss + 24.0) if grp >= 2 else 0.0)
			draw_string(font, Vector2(16.0, gy - 6.0), ["WEAPONS" if not two_on else "P1 WEAPONS", "BONI" if not two_on else "P1 BONI", "P2 WEAPONS", "P2 BONI"][grp], HORIZONTAL_ALIGNMENT_LEFT, 200.0, 11,
				Color([CYAN, GOLD, PINK, PINK.lerp(GOLD, 0.5)][grp], 0.8))
			for i in SD.SLOTS:
				var r := Rect2(16.0 + i * (ss + gap), gy, ss, ss)
				if i >= items.size():
					_slot(r, CYAN, false)
					continue
				var col: Color = [CYAN, GOLD, PINK, PINK.lerp(GOLD, 0.5)][grp]
				var ult: bool = grp % 2 == 0 and int(items[i][1]) >= SD.ULT
				if ult:
					col = Color.from_hsv(fposmod(_t * 0.2 + i * 0.13, 1.0), 0.55, 1.0)      # (a weapon that is its ultimate: all colours)
				_slot(r, col, true)
				ui.icon(self, String(items[i][0]), r.get_center() + Vector2(0.0, -5.0), 14.0, col)
				for lv in SD.MAX_LEVEL:
					draw_rect(Rect2(r.position.x + 6.0 + lv * 8.0, r.end.y - 9.0, 6.0, 4.0), col if lv < int(items[i][1]) else Color(0.2, 0.24, 0.3))
		_stage(vs, font)

	## Part 7c-2: what the stage adds to the display: a boss's name and what is left of it; what a crate gave you, while
	## it lasts; arrows at the edge of the picture (to a crate that came down, to where a flock comes from); a word
	## across the picture.
	func _stage(vs: Vector2, font: Font) -> void:
		var bi: Dictionary = game.boss_info()
		if not bi.is_empty():
			var bb := Rect2(vs.x * 0.5 - 430.0, 166.0, 860.0, 16.0)
			draw_rect(bb.grow(6.0), Color(DARK, 0.86))
			ui.brackets(self, bb.grow(6.0), RED, 14.0, 3.0)
			draw_rect(Rect2(vs.x * 0.5 - 150.0, bb.position.y - 36.0, 300.0, 30.0), Color(DARK, 0.86))       # (a plate: the name reads over whatever shines behind it)
			draw_string(font, Vector2(bb.position.x, bb.position.y - 12.0), String(bi["name"]).to_upper(), HORIZONTAL_ALIGNMENT_CENTER, bb.size.x, 22, Color(1.0, 0.75, 0.7))
			var segs := 40
			var sw := (bb.size.x - (segs - 1) * 3.0) / segs
			for q in segs:
				var f := clampf(float(bi["k"]) * segs - q, 0.0, 1.0)
				var sr := Rect2(bb.position.x + q * (sw + 3.0), bb.position.y, sw, bb.size.y)
				draw_rect(sr, Color(0.16, 0.08, 0.1))
				if f > 0.0:
					draw_rect(Rect2(sr.position, Vector2(sr.size.x * f, sr.size.y)), Color(0.38, 0.58, 0.82) if (int(bi.get("shield", 0)) > 0 or bool(bi.get("under", false))) else RED.lerp(GOLD, 0.25 * absf(sin(_t * 4.0))))
					draw_rect(Rect2(sr.position, Vector2(sr.size.x * f, 4.0)), Color(1, 1, 1, 0.3))
			if bool(bi.get("under", false)):                      # (part 9c) The Ice Worm under the ice: nothing reaches it there
				var ur := Rect2(vs.x * 0.5 - 190.0, bb.end.y + 12.0, 380.0, 28.0)
				draw_rect(ur, Color(DARK, 0.86))
				draw_string(font, ur.position + Vector2(0.0, 20.0), "UNDER THE ICE: WATCH THE MARKS", HORIZONTAL_ALIGNMENT_CENTER, ur.size.x, 16, Color(0.65, 0.85, 1.0))
			if int(bi.get("shield", 0)) > 0:                      # (part 8c) The Core behind its shield: how many pylons still stand
				var hr := Rect2(vs.x * 0.5 - 150.0, bb.end.y + 12.0, 300.0, 28.0)
				draw_rect(hr, Color(DARK, 0.86))
				draw_string(font, hr.position + Vector2(0.0, 20.0), "SHIELDED: %d PYLON%s" % [int(bi["shield"]), "" if int(bi["shield"]) == 1 else "S"], HORIZONTAL_ALIGNMENT_CENTER, hr.size.x, 16,
					Color(0.65, 0.85, 1.0))
			for ph in 3:
				var pc := Vector2(bb.end.x - 14.0 - ph * 20.0, bb.position.y - 18.0)
				draw_colored_polygon(PackedVector2Array([pc + Vector2(0.0, -6.0), pc + Vector2(7.0, 0.0), pc + Vector2(0.0, 6.0), pc + Vector2(-7.0, 0.0)]),
					RED if (3 - ph) >= int(bi["phase"]) else Color(0.25, 0.14, 0.16))
		var its: Array = [["shield", float(game.shield_t), float(SD.ITEMS["shield"]["time"]), CYAN], ["stasis", float(game.stasis_t), float(SD.ITEMS["stasis"]["time"]), Color(0.6, 0.8, 1.0)],
			["overdrive", float(game.over_t), float(SD.ITEMS["overdrive"]["time"]), GOLD], ["magnet", float(game.magnet_t), 3.0, GREEN],
			["override", float(game.ovr_t), float(SD.ITEMS["override"]["time"]), Color(0.4, 1.0, 0.55)], ["seal", float(game.seal_t), float(game.seal_len), Color(0.55, 1.0, 0.75)]]
		if float(game.emp_t) > 0.0:                             # (part 8b) an EMP: nothing charges: a plate over your weapons' places
			var er := Rect2(12.0, vs.y - 156.0, 284.0, 62.0)
			draw_rect(er, Color(0.2, 0.3, 0.5, 0.5 + 0.2 * absf(sin(_t * 20.0))))
			draw_rect(er, Color(0.7, 0.85, 1.0), false, 2.0)
			draw_string(font, er.position + Vector2(0.0, 38.0), "EMP   %s" % str(snappedf(float(game.emp_t), 0.1)), HORIZONTAL_ALIGNMENT_CENTER, er.size.x, 26, Color(1, 1, 1))
		if bool(game.in_storm):                                 # (part 9c) out in The Storm Heart's storm
			var sr9 := Rect2(vs.x * 0.5 - 220.0, vs.y * 0.5 + 126.0, 440.0, 34.0)
			draw_rect(sr9, Color(0.05, 0.02, 0.03, 0.8))
			draw_rect(sr9, Color(RED, 0.75 + 0.25 * absf(sin(_t * 10.0))), false, 2.0)
			draw_string(font, sr9.position + Vector2(0.0, 24.0), "IN THE STORM: BACK INTO THE EYE", HORIZONTAL_ALIGNMENT_CENTER, sr9.size.x, 20, Color(1.0, 0.85, 0.82))
		if not (game.avas as Array).is_empty():                 # (part 9b) an avalanche: get behind something solid; in cover it says so
			var ar := Rect2(vs.x * 0.5 - 250.0, vs.y * 0.5 + 126.0, 500.0, 34.0)
			var safe := bool(game.in_cover)
			draw_rect(ar, Color(0.02, 0.05, 0.03, 0.8) if safe else Color(0.05, 0.02, 0.03, 0.8))
			draw_rect(ar, Color(GREEN if safe else RED, 0.75 + 0.25 * absf(sin(_t * 10.0))), false, 2.0)
			draw_string(font, ar.position + Vector2(0.0, 24.0), "IN COVER" if safe else "AVALANCHE: GET BEHIND SOMETHING SOLID", HORIZONTAL_ALIGNMENT_CENTER, ar.size.x, 20, Color(0.8, 1.0, 0.85) if safe else Color(1.0, 0.85, 0.82))
		if bool(game.walls_on):                                 # (part 11b) the Alien Laboratory: a purge, a lockdown, a saucer's hold
			var note := ""
			var safe9 := false
			if not (game.purge as Dictionary).is_empty():
				var in_it: bool = (game.purge["r"] as Rect2).has_point(game.view.pilot.pos)
				var where := String(game.purge["name"])
				safe9 = not in_it
				if bool(game.purge["lit"]):
					note = "THE PURGE: GET OUT" if in_it else "%s BURNS" % where
				else:
					var secs := int(ceil(SD.PURGE_WARN - float(game.purge["t"])))
					note = ("PURGE IN %d: GET OUT OF %s" % [secs, where]) if in_it else ("PURGE IN %d: %s WILL BURN" % [secs, where])
			elif float(game.hold_t) > 0.0:
				note = "HELD: DODGE TO BREAK FREE"
			elif bool(game._lock_wait) and String(game.boss_kind) == "mastermind":      # (part 11c) it wakes: the way to its hall
				note = "THE MASTERMIND WAKES: TO THE CORE HALL"
				if int(game._lock_reg) >= 0 and int(game._lock_reg) < (game._regs as Array).size():
					var rel9: Vector2 = ((game._regs[int(game._lock_reg)] as Rect2).get_center() - game.view.pilot.pos) * float(GroundMap.SCALE) * maxf(0.2, float(game.view.zoom))
					if absf(rel9.x) > vs.x * 0.5 - 80.0 or absf(rel9.y) > vs.y * 0.5 - 80.0:
						var dv9 := rel9.normalized()
						var ap9 := vs * 0.5 + dv9 * minf((vs.x * 0.5 - 90.0) / maxf(0.001, absf(dv9.x)), (vs.y * 0.5 - 90.0) / maxf(0.001, absf(dv9.y)))
						var sd9 := dv9.orthogonal()
						draw_colored_polygon(PackedVector2Array([ap9 + dv9 * 28.0, ap9 - dv9 * 10.0 + sd9 * 18.0, ap9 - dv9 * 10.0 - sd9 * 18.0]), GOLD)
			elif float(game.lock_t) > 0.0 and String(game.boss_kind) == "":
				note = "LOCKDOWN: %d" % int(ceil(float(game.lock_t)))
			if note != "":
				var nr := Rect2(vs.x * 0.5 - 260.0, vs.y * 0.5 + 126.0, 520.0, 34.0)
				draw_rect(nr, Color(0.02, 0.05, 0.03, 0.8) if safe9 else Color(0.05, 0.02, 0.03, 0.8))
				draw_rect(nr, Color(GREEN if safe9 else RED, 0.75 + 0.25 * absf(sin(_t * 10.0))), false, 2.0)
				draw_string(font, nr.position + Vector2(0.0, 24.0), note, HORIZONTAL_ALIGNMENT_CENTER, nr.size.x, 20, Color(0.8, 1.0, 0.85) if safe9 else Color(1.0, 0.85, 0.82))
		if float(game.lit_t) > 0.25:                            # you stand in a searchlight
			var lr := Rect2(vs.x * 0.5 - 150.0, vs.y * 0.5 + 126.0, 300.0, 34.0)      # (on a dark plate: the swarm stands behind it)
			draw_rect(lr, Color(0.05, 0.02, 0.03, 0.8))
			draw_rect(lr, Color(RED, 0.75 + 0.25 * absf(sin(_t * 10.0))), false, 2.0)
			draw_string(font, lr.position + Vector2(0.0, 24.0), "IN THE LIGHT: MOVE", HORIZONTAL_ALIGNMENT_CENTER, lr.size.x, 20, Color(1.0, 0.85, 0.82))
		var on: Array = its.filter(func(q2): return float(q2[1]) > 0.0)
		for qi in on.size():
			var ic := Vector2(vs.x * 0.5 + (qi - (on.size() - 1) * 0.5) * 64.0, vs.y - 150.0)      # (above the line of what you can do here)
			draw_circle(ic, 24.0, Color(DARK, 0.86))
			draw_arc(ic, 22.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(float(on[qi][1]) / float(on[qi][2]), 0.0, 1.0), 32, on[qi][3], 3.0)
			ui.icon(self, String(on[qi][0]), ic, 11.0, on[qi][3])
		if game.view != null and is_instance_valid(game.view) and game.view.pilot != null:
			var zoom := maxf(0.2, float(game.view.zoom))
			var pp: Vector2 = game.view.pilot.pos
			var centre := vs * 0.5
			for cr in game.crates:                             # a crate that came down, out of sight: an arrow at the edge
				if not bool(cr.get("mark", false)):
					continue
				var rel: Vector2 = ((cr["pos"] as Vector2) - pp) * float(GroundMap.SCALE) * zoom
				if absf(rel.x) < vs.x * 0.5 - 50.0 and absf(rel.y) < vs.y * 0.5 - 50.0:
					continue
				var dv := rel.normalized()
				var ap := centre + dv * minf((vs.x * 0.5 - 70.0) / maxf(0.001, absf(dv.x)), (vs.y * 0.5 - 70.0) / maxf(0.001, absf(dv.y)))
				var ccol := GOLD if (bool(cr["great"]) or bool(cr.get("weapon", false))) else CYAN      # (part 7f: a weapon crate is golden)
				var sd := dv.orthogonal()
				draw_colored_polygon(PackedVector2Array([ap + dv * 20.0, ap - dv * 8.0 + sd * 13.0, ap - dv * 8.0 - sd * 13.0]), ccol)
				draw_rect(Rect2(ap - dv * 30.0 - Vector2(8.0, 6.0), Vector2(16.0, 12.0)), Color(DARK, 0.9))
				draw_rect(Rect2(ap - dv * 30.0 - Vector2(8.0, 6.0), Vector2(16.0, 12.0)), ccol, false, 2.0)
			if not (game.flock_warn as Dictionary).is_empty():   # a flock is about to come: from where
				var fd: Vector2 = -(game.flock_warn["dir"] as Vector2)
				var fp2 := centre + fd * minf((vs.x * 0.5 - 90.0) / maxf(0.001, absf(fd.x)), (vs.y * 0.5 - 90.0) / maxf(0.001, absf(fd.y)))
				var fs := fd.orthogonal()
				var blink := 0.5 + 0.5 * absf(sin(_t * 14.0))
				for ch in 3:
					var cb := fp2 + fd * (ch * 16.0 - 10.0)
					draw_polyline(PackedVector2Array([cb + fs * 18.0 + fd * 10.0, cb, cb - fs * 18.0 + fd * 10.0]), Color(RED, blink * (1.0 - ch * 0.25)), 5.0)
		var pop: Dictionary = game.item_pop                      # (part 7f) the sign of an item just taken: it springs up over you, stands a moment, then goes down to where what lasts is shown
		if not pop.is_empty() and SD.ITEMS.has(String(pop["id"])):
			var pt := float(pop["t"])
			var pcol: Color = SD.ITEMS[String(pop["id"])].get("col", CYAN)
			var go := clampf((pt - 0.8) / 0.4, 0.0, 1.0)
			var sc := (0.2 + 1.1 * (pt / 0.16)) if pt < 0.16 else (1.3 - 0.3 * clampf((pt - 0.16) / 0.12, 0.0, 1.0))
			sc = lerpf(sc, 0.3, go * go)
			var at := Vector2(vs.x * 0.5, vs.y * 0.5 - 168.0).lerp(Vector2(vs.x * 0.5, vs.y - 150.0), go * go)
			var pa := 1.0 - clampf((pt - 1.05) / 0.15, 0.0, 1.0)
			if pt < 0.34:                                         # (rays as it springs up)
				for q3 in 10:
					var rd := Vector2.from_angle(q3 * TAU / 10.0 + 0.3)
					draw_line(at + rd * (80.0 + pt * 320.0), at + rd * (104.0 + pt * 470.0), Color(pcol, 1.0 - pt / 0.34), 4.0)
			draw_set_transform(at, 0.0, Vector2(sc, sc))
			for g3 in 3:
				draw_circle(Vector2.ZERO, 92.0 - g3 * 14.0, Color(pcol, 0.06 * pa))
			draw_colored_polygon((ui.hexpts(Vector2.ZERO, 62.0, PI / 6.0) as PackedVector2Array).slice(0, 6), Color(DARK, 0.93 * pa))
			draw_polyline(ui.hexpts(Vector2.ZERO, 62.0, PI / 6.0), Color(pcol, pa), 3.0)
			draw_polyline(ui.hexpts(Vector2.ZERO, 72.0, PI / 6.0 + _t * 0.8), Color(pcol, 0.45 * pa), 1.5)
			draw_set_transform(at, 0.0, Vector2(sc * 3.0, sc * 3.0))
			ui.icon(self, String(pop["id"]), Vector2.ZERO, 11.0, Color(pcol.lightened(0.25), pa))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if float(game.banner_t) > 0.0:
			var bk := clampf(float(game.banner_t) / 0.5, 0.0, 1.0) * clampf((3.2 - float(game.banner_t)) / 0.25, 0.0, 1.0)
			var by2 := vs.y * 0.27
			draw_rect(Rect2(0.0, by2 - 50.0, vs.x, 70.0), Color(DARK, 0.62 * bk))
			draw_line(Vector2(0.0, by2 - 50.0), Vector2(vs.x, by2 - 50.0), Color(GOLD, 0.8 * bk), 2.0)
			draw_line(Vector2(0.0, by2 + 20.0), Vector2(vs.x, by2 + 20.0), Color(GOLD, 0.8 * bk), 2.0)
			draw_string(font, Vector2(0.0, by2), String(game.banner), HORIZONTAL_ALIGNMENT_CENTER, vs.x, 46, Color(1.0, 0.92, 0.65, bk))


class LevelUp extends Control:
	signal finished(won: bool)
	const CW := 380.0
	const CH := 520.0
	var cards: Array = []
	var run: Dictionary = {}
	var level := 1
	var sel := 0
	var msg := ""
	var game = null                  # the run (part 7c-3: a reroll draws its cards anew)
	var ui = load("res://scripts/ground/survivor_ui.gd")
	var _t := 0.0
	var seat := 0                    # split screen: whose cards these are (0 you, 1 the second player)
	var who := ""                    # … and their name over the cards ("" one player)

	func is_sv_levelup() -> bool:
		return true

	func setup(cfg: Dictionary) -> void:
		cards = cfg.get("cards", [])
		run = cfg.get("run", {})
		game = cfg.get("game", null)
		level = int(cfg.get("level", 1))
		seat = int(cfg.get("seat", 0))
		who = String(cfg.get("who", ""))
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func rects() -> Array:
		var vs := get_viewport_rect().size
		var out: Array = []
		for i in cards.size():
			out.append(Rect2(vs.x * 0.5 - (cards.size() * (CW + 28.0) - 28.0) * 0.5 + i * (CW + 28.0), vs.y * 0.5 - CH * 0.5 + 50.0, CW, CH))
		return out

	## (Part 7c-3) Rerolls left in this run (bought at the console).
	func rerolls() -> int:
		return int(run.get("rerolls", 0))

	func reroll_rect() -> Rect2:
		var vs := get_viewport_rect().size
		return Rect2(vs.x * 0.5 - 190.0, vs.y * 0.5 + CH * 0.5 + 72.0, 380.0, 46.0)

	## The three cards are drawn anew (through the command bus).
	func reroll() -> void:
		if _t < 0.35:
			return
		var e := String(Commands.execute({"type": "sv_reroll", "seat": 0}))
		if e != "":
			msg = e
			Audio.play("ui_error", "survivor: no reroll")
			return
		if game != null and is_instance_valid(game):
			cards = game.cards
		sel = clampi(sel, 0, maxi(0, cards.size() - 1))
		msg = ""
		_t = 0.15

	## The card `i` is taken (through the command bus).
	func pick(i: int) -> void:
		if _t < 0.35 or i < 0 or i >= cards.size():
			return                                            # (not by a key still held from the run)
		var e := String(Commands.execute({"type": "sv_pick", "seat": 0, "i": i}))
		if e != "":
			msg = e
			Audio.play("ui_error", "survivor: a card")
			return
		Audio.play("ui_open", "survivor: a card taken")
		finished.emit(true)

	func _process(dt: float) -> void:
		_t += dt
		queue_redraw()
		if seat == 1 and Players.split:                      # split screen: the second player picks with their own device
			var lf: bool = Players.just_pressed(1, "pad_left", "menu") or Players.just_pressed(1, "walk_left")
			var rt: bool = Players.just_pressed(1, "pad_right", "menu") or Players.just_pressed(1, "walk_right")
			if lf or rt:
				sel = posmod(sel + (1 if rt else -1), maxi(1, cards.size()))
			elif Players.just_pressed(1, "pad_confirm", "menu") or Players.just_pressed(1, "interact"):
				pick(sel)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseMotion:
			var rs0 := rects()
			for i0 in rs0.size():
				if (rs0[i0] as Rect2).has_point((event as InputEventMouseMotion).position):
					sel = i0
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			var rs := rects()
			for i in rs.size():
				if (rs[i] as Rect2).has_point((event as InputEventMouseButton).position):
					pick(i)
			if rerolls() > 0 and reroll_rect().has_point((event as InputEventMouseButton).position):
				reroll()
			accept_event()

	func _unhandled_input(event: InputEvent) -> void:
		if event is InputEventKey and event.pressed and not event.echo:
			var k := (event as InputEventKey).keycode
			get_viewport().set_input_as_handled()
			if k >= KEY_1 and k <= KEY_3:
				pick(k - KEY_1)
			elif k == KEY_R:
				reroll()
			elif k in [KEY_LEFT, KEY_A]:
				sel = posmod(sel - 1, maxi(1, cards.size()))
			elif k in [KEY_RIGHT, KEY_D]:
				sel = posmod(sel + 1, maxi(1, cards.size()))
			elif k in [KEY_ENTER, KEY_SPACE, KEY_E]:
				pick(sel)

	func pad_button(b: String, pressed: bool) -> bool:
		if not pressed:
			return true
		match b:
			"left", "right":
				sel = posmod(sel + (1 if b == "right" else -1), maxi(1, cards.size()))
			"cross":
				pick(sel)
			"triangle":
				reroll()
		return true

	## One card: a frame of light in the colour of its kind, its sign in a six-sided frame, its name, its levels,
	## what it changes in figures, what it fuses into.
	func _card(r: Rect2, cd: Dictionary, hot: bool, i: int) -> void:
		var font := ThemeDB.fallback_font
		var kind := String(cd.get("kind", ""))
		var id := String(cd.get("id", ""))
		var col: Color = ui.card_color(kind)
		if kind == "ult":
			col = Color.from_hsv(fposmod(_t * 0.18 + i * 0.2, 1.0), 0.5, 1.0)      # (an ultimate: all colours, turning)
		if hot:
			r.position.y -= 12.0
		for g in 3:                                             # the light it throws round itself
			draw_rect(r.grow(5.0 + g * 6.0), Color(col, (0.09 if hot else 0.035) / (g + 1.0)))
		draw_rect(r, Color(DARK, 0.97))
		for gx in range(int(r.position.x) + 19, int(r.end.x), 38):     # a grid of light behind
			draw_line(Vector2(gx, r.position.y + 46.0), Vector2(gx, r.end.y - 2.0), Color(col, 0.045), 1.0)
		for gy in range(int(r.position.y) + 84, int(r.end.y), 38):
			draw_line(Vector2(r.position.x + 2.0, gy), Vector2(r.end.x - 2.0, gy), Color(col, 0.045), 1.0)
		var scan := r.position.y + 48.0 + fposmod(_t * 90.0 + i * 130.0, r.size.y - 52.0)      # a line of light running down it
		draw_rect(Rect2(r.position.x + 2.0, scan, r.size.x - 4.0, 2.0), Color(col, 0.16))
		# the band at its top: what kind of card it is
		var band := Rect2(r.position, Vector2(r.size.x, 44.0))
		draw_rect(band, Color(col, 0.17))
		draw_line(Vector2(r.position.x, band.end.y), Vector2(r.end.x, band.end.y), Color(col, 0.85), 2.0)
		var tag: String = {"weapon": "NEW WEAPON", "up": "WEAPON   ·   LEVEL %d" % int(cd.get("level", 1)), "bonus": "NEW BONUS", "bonus_up": "BONUS   ·   LEVEL %d" % int(cd.get("level", 1)),
			"ult": "ULTIMATE", "heal": "MED CELL", "coins": "COINS"}.get(kind, "")
		draw_string(font, band.position + Vector2(0.0, 29.0), tag, HORIZONTAL_ALIGNMENT_CENTER, band.size.x, 16, col.lightened(0.25))
		for tk in 4:
			draw_rect(Rect2(band.end.x - 16.0 - tk * 7.0, band.position.y + 17.0, 4.0, 10.0), Color(col, 0.5 - tk * 0.1))
			draw_rect(Rect2(band.position.x + 12.0 + tk * 7.0, band.position.y + 17.0, 4.0, 10.0), Color(col, 0.5 - tk * 0.1))
		# the frame
		draw_rect(r, Color(col, 1.0 if hot else 0.6), false, 3.0 if hot else 1.5)
		draw_rect(r.grow(-7.0), Color(col, 0.22), false, 1.0)
		ui.brackets(self, r.grow(3.0), col if hot else Color(col, 0.8), 28.0, 4.0)
		# its sign
		var c := r.position + Vector2(r.size.x * 0.5, 138.0)
		ui.hex_frame(self, c, 58.0, col, _t + i * 1.3)
		ui.icon(self, id, c, 30.0, col.lightened(0.2))
		if kind == "ult":
			for q in 6:
				draw_circle(c + Vector2.from_angle(_t * 1.4 + q * TAU / 6.0) * 74.0, 3.0, Color.from_hsv(fposmod(q / 6.0 + _t * 0.2, 1.0), 0.6, 1.0))
		# its name, its levels
		draw_string(font, r.position + Vector2(0.0, 250.0), String(cd.get("name", "")), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 27, Color(1, 1, 1))
		if kind in ["weapon", "up", "bonus", "bonus_up", "ult"]:
			var lv := mini(int(cd.get("level", 1)), SD.MAX_LEVEL)
			for p in SD.MAX_LEVEL:
				var pc := r.position + Vector2(r.size.x * 0.5 + (p - 2) * 22.0, 272.0)
				var lit := p < lv
				var fresh := p == lv - 1 and kind != "ult"
				var pcol := (col if not fresh else col.lerp(Color(1, 1, 1), 0.5 + 0.5 * sin(_t * 6.0))) if lit else Color(0.2, 0.24, 0.32)
				draw_colored_polygon(PackedVector2Array([pc + Vector2(0.0, -6.0), pc + Vector2(7.0, 0.0), pc + Vector2(0.0, 6.0), pc + Vector2(-7.0, 0.0)]), pcol)
		# what it does, in words (a new one, an ultimate, a med cell, a purse) and in figures (what a level changes)
		var y := r.position.y + 304.0
		if kind in ["weapon", "bonus", "ult", "heal", "coins"]:
			draw_multiline_string(font, Vector2(r.position.x + 28.0, y + 4.0), String(cd.get("text", "")), HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 56.0, 14, 4, Color(0.8, 0.86, 0.96))
			y += 58.0 if kind != "ult" else 0.0
		if kind != "ult":
			for ln in SD.card_lines(run, cd):
				draw_rect(Rect2(r.position.x + 24.0, y + 6.0, r.size.x - 48.0, 1.0), Color(col, 0.14))
				draw_string(font, Vector2(r.position.x + 28.0, y), String(ln[0]), HORIZONTAL_ALIGNMENT_LEFT, 200.0, 15, Color(0.68, 0.74, 0.86))
				var nw := font.get_string_size(String(ln[2]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17).x
				draw_string(font, Vector2(r.end.x - 28.0 - nw, y), String(ln[2]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17, col.lightened(0.3))
				if String(ln[1]) != "":
					var ow := font.get_string_size(String(ln[1]) + "  →  ", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15).x
					draw_string(font, Vector2(r.end.x - 28.0 - nw - ow, y), String(ln[1]) + "  →  ", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color(0.55, 0.6, 0.72))
				y += 25.0
		# what it fuses into
		var fz: Dictionary = SD.fusion(run, cd)
		if not fz.is_empty():
			var ready := bool(fz.get("ready", false))
			var fy := r.end.y - 62.0
			draw_rect(Rect2(r.position.x + 20.0, fy - 16.0, r.size.x - 40.0, 24.0), Color(PINK, 0.12 if ready else 0.05))
			var dm := Vector2(r.position.x + 34.0, fy - 4.0)
			draw_colored_polygon(PackedVector2Array([dm + Vector2(0.0, -5.0), dm + Vector2(5.0, 0.0), dm + Vector2(0.0, 5.0), dm + Vector2(-5.0, 0.0)]), PINK if ready else Color(PINK, 0.5))
			draw_string(font, Vector2(r.position.x + 46.0, fy + 1.0), String(fz["text"]), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 70.0, 12, PINK.lightened(0.3) if ready else Color(PINK, 0.6))
		# its key
		var kc := Vector2(r.position.x + r.size.x * 0.5, r.end.y - 22.0)
		draw_colored_polygon((ui.hexpts(kc, 14.0, PI / 6.0) as PackedVector2Array).slice(0, 6), Color(col, 0.2 if not hot else 0.4))
		draw_polyline(ui.hexpts(kc, 14.0, PI / 6.0), col, 1.5)
		draw_string(font, kc + Vector2(-14.0, 6.0), "%d" % (i + 1), HORIZONTAL_ALIGNMENT_CENTER, 28.0, 15, Color(1, 1, 1))

	func _draw() -> void:
		var vs := get_viewport_rect().size
		var font := ThemeDB.fallback_font
		draw_rect(Rect2(Vector2.ZERO, vs), Color(0.015, 0.02, 0.05, 0.8))
		for gx in range(0, int(vs.x), 64):                      # a grid of light over the picture
			draw_line(Vector2(gx, 0.0), Vector2(gx, vs.y), Color(CYAN, 0.035), 1.0)
		for gy in range(0, int(vs.y), 64):
			draw_line(Vector2(0.0, gy), Vector2(vs.x, gy), Color(CYAN, 0.035), 1.0)
		var hy := vs.y * 0.5 - CH * 0.5 - 30.0
		draw_string(font, Vector2(0.0, hy), "LEVEL %d" % level, HORIZONTAL_ALIGNMENT_CENTER, vs.x, 56, CYAN)
		if who != "":                                        # split screen: whose card this is
			var wc: Color = CYAN if seat == 0 else PINK
			draw_string(font, Vector2(0.0, hy - 62.0), "%s  PICKS A CARD" % who.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, vs.x, 24, wc)
		draw_line(Vector2(vs.x * 0.5 - 330.0, hy + 14.0), Vector2(vs.x * 0.5 - 90.0, hy + 14.0), Color(CYAN, 0.8), 2.0)
		draw_line(Vector2(vs.x * 0.5 + 90.0, hy + 14.0), Vector2(vs.x * 0.5 + 330.0, hy + 14.0), Color(CYAN, 0.8), 2.0)
		draw_string(font, Vector2(0.0, hy + 20.0), "TAKE ONE", HORIZONTAL_ALIGNMENT_CENTER, vs.x, 15, GOLD)
		var rs := rects()
		for i in rs.size():
			if i != sel:
				_card(rs[i], cards[i], false, i)
		if sel >= 0 and sel < rs.size():
			_card(rs[sel], cards[sel], true, sel)                # (the one you are on, on top)
		if rerolls() > 0:                                       # (part 7c-3) the reroll, while one is left
			var rr := reroll_rect()
			var hot := rr.has_point(get_local_mouse_position())
			draw_rect(rr, Color(GOLD, 0.16 if hot else 0.07))
			draw_rect(rr, Color(GOLD, 1.0 if hot else 0.7), false, 2.0)
			ui.brackets(self, rr.grow(3.0), GOLD, 12.0, 2.0)
			ui.icon(self, "reroll", rr.position + Vector2(30.0, 23.0), 11.0, GOLD)
			draw_string(font, rr.position + Vector2(56.0, 30.0), "R   REROLL   ·   %d left" % rerolls(), HORIZONTAL_ALIGNMENT_LEFT, rr.size.x - 60.0, 19, Color(1, 1, 1))
		if msg != "":
			draw_string(font, Vector2(0.0, vs.y * 0.5 + CH * 0.5 + 150.0), msg, HORIZONTAL_ALIGNMENT_CENTER, vs.x, 18, RED)


## (Part 7f, Luz, 23 Nov 2026) A weapon crate's draw: one, three or five reels turn and stop one after the other,
## each on a level of something you carry. The run stands still behind it. What the reels show is yours already (the
## run gave it when the crate was opened): this window only shows it. E, Enter, Space, a click or the pad's cross:
## the reels still turning stop at once; with all of them stopped the window closes.
class Draw extends Control:
	signal finished(won: bool)
	const RW := 216.0                # a reel's width and height, the gap between two
	const RH := 400.0
	const GAP := 26.0
	const ROW := 128.0               # how far apart the signs stand on a reel
	const FIRST := 1.25              # the first reel stops at this second, each further one STEP later
	const STEP := 0.55
	var rewards: Array = []
	var symbols: Array = []
	var great := false
	var ui = load("res://scripts/ground/survivor_ui.gd")
	var _t := 0.0
	var _stopped := 0                # reels that have stopped (for their sounds)

	func is_sv_draw() -> bool:
		return true

	func setup(cfg: Dictionary) -> void:
		rewards = cfg.get("rewards", [])
		symbols = cfg.get("symbols", [])
		if symbols.is_empty():
			symbols = [SD.START_WEAPON]
		great = bool(cfg.get("great", false))
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP

	## The second at which the reel `i` stops, and the one at which the last has stopped.
	func stop_at(i: int) -> float:
		return FIRST + i * STEP

	func done_at() -> float:
		return stop_at(maxi(0, rewards.size() - 1))

	func all_stopped() -> bool:
		return _t >= done_at()

	func rects() -> Array:
		var vs := get_viewport_rect().size
		var out: Array = []
		var cnt := rewards.size()
		for i in cnt:
			out.append(Rect2(vs.x * 0.5 - (cnt * (RW + GAP) - GAP) * 0.5 + i * (RW + GAP), vs.y * 0.5 - RH * 0.5 + 34.0, RW, RH))
		return out

	func press() -> void:
		if _t < 0.3:
			return                                            # (not by a key still held from the run)
		if not all_stopped():
			_t = done_at()
			return
		if _t < done_at() + 0.25:
			return
		Audio.play("ui_open", "survivor: the draw taken")
		finished.emit(true)

	func _process(dt: float) -> void:
		_t += dt
		var now := 0
		for i in rewards.size():
			if _t >= stop_at(i):
				now += 1
		if now > _stopped:
			_stopped = now
			var last := now >= rewards.size()
			Audio.play("sv_level" if last else "sv_item", "survivor: a reel stops", -4.0 if last else -9.0)
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			press()
			accept_event()

	func _unhandled_input(event: InputEvent) -> void:
		if event is InputEventKey and event.pressed and not event.echo:
			get_viewport().set_input_as_handled()
			if (event as InputEventKey).keycode in [KEY_ENTER, KEY_SPACE, KEY_E]:
				press()

	func pad_button(b: String, pressed: bool) -> bool:
		if pressed and b == "cross":
			press()
		return true

	## The sign that stands at the place `j` of the reel `i` (the place 0 is where it stops: what it gives).
	func sign_at(i: int, j: int) -> String:
		if j == 0:
			return String(rewards[i].get("id", ""))
		return String(symbols[posmod(j * 7 + i * 13 + (j * j) / 3, symbols.size())])

	static func sign_color(id: String) -> Color:
		return CYAN if SD.WEAPONS.has(id) else (RED if id == "heal" else GOLD)

	## One reel: its window, the signs running down it; stopped: what it gives, in a frame of light, its name, its level.
	func _reel(r: Rect2, i: int) -> void:
		var font := ThemeDB.fallback_font
		var rw: Dictionary = rewards[i]
		var kind := String(rw.get("kind", ""))
		var id := String(rw.get("id", ""))
		var appear := clampf((_t - 0.1 - i * 0.09) / 0.22, 0.0, 1.0)
		if appear <= 0.0:
			return
		var stop := stop_at(i)
		var stopped := _t >= stop
		var since := _t - stop
		var col: Color = ui.card_color(kind) if stopped else Color(0.7, 0.76, 0.9)
		r.position.y += pow(1.0 - appear, 2.0) * 46.0
		for g in 3:                                             # the light it throws round itself
			draw_rect(r.grow(5.0 + g * 6.0), Color(col, (0.1 if stopped else 0.03) / (g + 1.0) * appear))
		draw_rect(r, Color(DARK, 0.97 * appear))
		var band := Rect2(r.position, Vector2(r.size.x, 40.0))
		draw_rect(band, Color(col, 0.17 * appear))
		draw_line(Vector2(r.position.x, band.end.y), Vector2(r.end.x, band.end.y), Color(col, 0.85 * appear), 2.0)
		var tag: String = {"up": "WEAPON", "bonus_up": "BONUS", "heal": "MED CELL", "coins": "COINS", "ult": "ULTIMATE"}.get(kind, "") if stopped else "·  ·  ·"
		draw_string(font, band.position + Vector2(0.0, 27.0), tag, HORIZONTAL_ALIGNMENT_CENTER, band.size.x, 15, Color(col.lightened(0.25), appear))
		# the signs: fast at first, slower and slower, down onto what the reel gives
		var mid := Vector2(r.position.x + r.size.x * 0.5, r.position.y + 40.0 + 132.0)
		var k := clampf((_t - 0.25) / maxf(0.01, stop - 0.25), 0.0, 1.0)
		var pos := pow(1.0 - k, 3.0) * (18.0 + i * 6.0)           # places still to run
		var base := int(floor(pos))
		var half := 132.0
		draw_rect(Rect2(r.position.x + 2.0, mid.y - half, r.size.x - 4.0, half * 2.0), Color(0.0, 0.0, 0.0, 0.35 * appear))
		for j in range(base - 1, base + 3):
			var off := (j - pos) * ROW
			var vis := clampf(1.0 - absf(off) / (half * 0.98), 0.0, 1.0)
			if stopped and j != 0:
				vis *= clampf(1.0 - since / 0.25, 0.0, 1.0)         # (stopped: the signs above and below what it gives go out)
			if vis <= 0.0:
				continue
			var sid := sign_at(i, j)
			var scol := sign_color(sid)
			var c := mid + Vector2(0.0, off)
			if not stopped and k < 0.75:                         # (still fast: each sign draws a streak)
				draw_line(c + Vector2(0.0, -46.0), c + Vector2(0.0, 46.0), Color(scol, 0.1 * vis), 34.0)
			ui.icon(self, sid, c, 30.0 * (0.8 + 0.2 * vis), Color(scol, vis * appear * (1.0 if (stopped or j != 0) else 0.9)))
		for sd in [-1.0, 1.0]:                                  # the marks at its sides: here it stops
			var mp := Vector2(r.position.x + r.size.x * 0.5 + sd * (r.size.x * 0.5 - 4.0), mid.y)
			draw_colored_polygon(PackedVector2Array([mp + Vector2(0.0, -9.0), mp + Vector2(-sd * 13.0, 0.0), mp + Vector2(0.0, 9.0)]), Color(col, appear))
		draw_line(Vector2(r.position.x, mid.y + half), Vector2(r.end.x, mid.y + half), Color(col, 0.5 * appear), 1.0)
		draw_rect(r, Color(col, (1.0 if stopped else 0.55) * appear), false, 3.0 if stopped else 1.5)
		ui.brackets(self, r.grow(3.0), Color(col, appear), 24.0, 4.0)
		if not stopped:
			return
		# stopped: what it gives
		if since < 0.3:
			draw_rect(r, Color(1.0, 1.0, 1.0, 0.55 * (1.0 - since / 0.3)))
		ui.hex_frame(self, mid, 54.0 + 10.0 * maxf(0.0, 1.0 - since / 0.2), col, _t + i * 1.3)
		ui.icon(self, id, mid, 30.0, col.lightened(0.25))
		var ty := mid.y + half + 34.0
		draw_string(font, Vector2(r.position.x, ty), String(rw.get("name", "")), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 22, Color(1, 1, 1))
		if kind in ["up", "bonus_up"]:
			var lv := mini(int(rw.get("level", 1)), SD.MAX_LEVEL)
			for p in SD.MAX_LEVEL:
				var pc := Vector2(r.position.x + r.size.x * 0.5 + (p - 2) * 22.0, ty + 22.0)
				var pcol := (col if p != lv - 1 else col.lerp(Color(1, 1, 1), 0.5 + 0.5 * sin(_t * 6.0))) if p < lv else Color(0.2, 0.24, 0.32)
				draw_colored_polygon(PackedVector2Array([pc + Vector2(0.0, -6.0), pc + Vector2(7.0, 0.0), pc + Vector2(0.0, 6.0), pc + Vector2(-7.0, 0.0)]), pcol)
			draw_string(font, Vector2(r.position.x, ty + 54.0), "LEVEL %d" % lv, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 17, col.lightened(0.3))
		elif kind == "ult":
			draw_string(font, Vector2(r.position.x, ty + 30.0), "%s fused" % String(SD.WEAPONS[id]["name"]), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 15, col.lightened(0.3))
		else:
			draw_string(font, Vector2(r.position.x, ty + 30.0), ("+%d health" % int(SD.HEAL)) if kind == "heal" else "+15 Coins", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 17, col.lightened(0.3))

	func _draw() -> void:
		var vs := get_viewport_rect().size
		var font := ThemeDB.fallback_font
		var cnt := rewards.size()
		var tint := GOLD if cnt < 5 else Color.from_hsv(fposmod(_t * 0.35, 1.0), 0.5, 1.0)
		draw_rect(Rect2(Vector2.ZERO, vs), Color(0.015, 0.02, 0.05, 0.82))
		for gx in range(0, int(vs.x), 64):                      # a grid of light over the picture
			draw_line(Vector2(gx, 0.0), Vector2(gx, vs.y), Color(tint, 0.035), 1.0)
		for gy in range(0, int(vs.y), 64):
			draw_line(Vector2(0.0, gy), Vector2(vs.x, gy), Color(tint, 0.035), 1.0)
		var centre := vs * 0.5 + Vector2(0.0, 34.0)
		if cnt >= 3:                                            # three or five: rays of light turning behind the reels
			var rays := 12 if cnt == 3 else 20
			for q in rays:
				var a := q * TAU / rays + _t * (0.25 if cnt == 3 else 0.45)
				var rc: Color = GOLD if cnt == 3 else Color.from_hsv(fposmod(float(q) / rays + _t * 0.2, 1.0), 0.6, 1.0)
				draw_colored_polygon(PackedVector2Array([centre, centre + Vector2.from_angle(a - 0.07) * 1300.0, centre + Vector2.from_angle(a + 0.07) * 1300.0]), Color(rc, 0.05 if cnt == 3 else 0.075))
		if cnt == 5:                                            # five: lights raining down
			for q2 in 60:
				var fk := fposmod(_t * (0.25 + 0.3 * fposmod(q2 * 0.618, 1.0)) + fposmod(q2 * 0.377, 1.0), 1.0)
				var fp := Vector2(fposmod(q2 * 197.0, vs.x), fk * (vs.y + 40.0) - 20.0)
				var fs := 4.0 + 5.0 * fposmod(q2 * 0.271, 1.0)
				draw_colored_polygon(PackedVector2Array([fp + Vector2(0.0, -fs), fp + Vector2(fs * 0.6, 0.0), fp + Vector2(0.0, fs), fp + Vector2(-fs * 0.6, 0.0)]),
					Color.from_hsv(fposmod(q2 * 0.13 + _t * 0.3, 1.0), 0.6, 1.0, 0.8))
		var hy := vs.y * 0.5 - RH * 0.5 - 44.0
		var title: String = "JACKPOT" if cnt >= 5 else ("TRIPLE DRAW" if cnt >= 3 else "WEAPON CRATE")
		var beat := 1.0 + (0.06 * sin(_t * 9.0) if cnt >= 5 else 0.0)
		draw_string(font, Vector2(0.0, hy), title, HORIZONTAL_ALIGNMENT_CENTER, vs.x, int(round((70.0 if cnt >= 5 else 56.0) * beat)), tint)
		draw_line(Vector2(vs.x * 0.5 - 420.0, hy + 14.0), Vector2(vs.x * 0.5 - 150.0, hy + 14.0), Color(tint, 0.8), 2.0)
		draw_line(Vector2(vs.x * 0.5 + 150.0, hy + 14.0), Vector2(vs.x * 0.5 + 420.0, hy + 14.0), Color(tint, 0.8), 2.0)
		var sub: String = ("%s  ·  " % ("THE BOSS'S CRATE" if great else "AN ALPHA'S CRATE")) + ("FIVE REWARDS" if cnt >= 5 else ("THREE REWARDS" if cnt >= 3 else "ONE REWARD"))
		draw_string(font, Vector2(0.0, hy + 22.0), sub, HORIZONTAL_ALIGNMENT_CENTER, vs.x, 15, Color(tint.lightened(0.3), 0.95))
		var rs := rects()
		for i in rs.size():
			_reel(rs[i], i)
		var fy := vs.y * 0.5 + RH * 0.5 + 34.0 + 54.0
		if all_stopped():
			var br := Rect2(vs.x * 0.5 - 170.0, fy - 30.0, 340.0, 46.0)
			var glow := 0.5 + 0.5 * sin(_t * 5.0)
			draw_rect(br, Color(GOLD, 0.1 + 0.1 * glow))
			draw_rect(br, Color(GOLD, 0.75 + 0.25 * glow), false, 2.0)
			ui.brackets(self, br.grow(3.0), GOLD, 12.0, 2.0)
			draw_string(font, br.position + Vector2(0.0, 31.0), "E   TAKE", HORIZONTAL_ALIGNMENT_CENTER, br.size.x, 20, Color(1, 1, 1))
		else:
			draw_string(font, Vector2(0.0, fy), "E   stop the reels", HORIZONTAL_ALIGNMENT_CENTER, vs.x, 15, Color(0.72, 0.78, 0.9))


## (Luz) The picture before a run, in place of the fights' "versus": you at the left; at the right, above, the stage
## (its name, a picture of it, its dangers, how long it lasts) and, below, the weapon you begin with.
class Intro extends Control:
	signal finished(won: bool)
	const LEN := 4.6
	var you_tex: Texture2D = null
	var you_name := ""
	var weapon := "pulse"
	var stage := "outbreak"
	var ui = load("res://scripts/ground/survivor_ui.gd")
	var _t := 0.0

	func is_sv_intro() -> bool:
		return true

	func setup(cfg: Dictionary) -> void:
		you_tex = cfg.get("you_tex", null)
		you_name = String(cfg.get("you", "YOU"))
		weapon = String(cfg.get("weapon", SD.START_WEAPON))
		stage = String(cfg.get("stage", "outbreak"))
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _process(dt: float) -> void:
		_t += dt
		if _t >= LEN:
			set_process(false)
			finished.emit(true)
		queue_redraw()

	static func _h(i: int, salt: int) -> float:
		return fposmod(sin(float(i) * 12.9898 + float(salt) * 78.233) * 43758.5453, 1.0)

	## A picture of the stage Outbreak: the colony by night under the ringed giant, lamps, a wreck that burns, and
	## those who still walk.
	func _vista(r: Rect2) -> void:
		for b in 5:                                             # the night sky, lighter towards the ground
			draw_rect(Rect2(r.position.x, r.position.y + r.size.y * 0.14 * b, r.size.x, r.size.y * 0.14 + 1.0), Color(0.03 + 0.012 * b, 0.05 + 0.02 * b, 0.13 + 0.03 * b))
		for st in 46:
			var sp := r.position + Vector2(_h(st, 1) * (r.size.x - 4.0), _h(st, 2) * r.size.y * 0.55)
			draw_rect(Rect2(sp, Vector2(2.0, 2.0)), Color(1, 1, 1, 0.3 + 0.5 * _h(st, 3) * (0.6 + 0.4 * sin(_t * 2.0 + st))))
		var pc := r.position + Vector2(r.size.x * 0.78, r.size.y * 0.3)      # the giant and its rings
		draw_circle(pc, r.size.y * 0.22, Color(0.2, 0.36, 0.7))
		draw_circle(pc + Vector2(-5.0, -5.0), r.size.y * 0.175, Color(0.26, 0.45, 0.8))
		draw_rect(Rect2(pc.x - r.size.y * 0.2, pc.y - 4.0, r.size.y * 0.4, 3.0), Color(0.4, 0.6, 0.9, 0.6))
		draw_set_transform(pc, -0.35, Vector2(1.0, 0.24))
		draw_arc(Vector2.ZERO, r.size.y * 0.36, 0.0, TAU, 40, Color(0.75, 0.82, 0.95, 0.8), 3.0)
		draw_arc(Vector2.ZERO, r.size.y * 0.42, 0.0, TAU, 40, Color(0.75, 0.82, 0.95, 0.4), 2.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var gy := r.position.y + r.size.y * 0.7                    # the ground
		draw_rect(Rect2(r.position.x, gy, r.size.x, r.end.y - gy), Color(0.07, 0.08, 0.11))
		draw_rect(Rect2(r.position.x, gy, r.size.x, 2.0), Color(0.16, 0.18, 0.24))
		var dark := Color(0.04, 0.05, 0.08)
		# what stands there: a silo, a dome, containers, a fence
		var sx := r.position.x + r.size.x * 0.08
		draw_rect(Rect2(sx, gy - r.size.y * 0.42, 34.0, r.size.y * 0.42), dark)
		draw_circle(Vector2(sx + 17.0, gy - r.size.y * 0.42), 17.0, dark)
		draw_arc(Vector2(r.position.x + r.size.x * 0.3, gy), r.size.y * 0.2, PI, TAU, 24, Color(0.3, 0.9, 0.5, 0.35), 2.0)
		draw_colored_polygon(PackedVector2Array([Vector2(r.position.x + r.size.x * 0.3 - r.size.y * 0.2, gy), Vector2(r.position.x + r.size.x * 0.3 - r.size.y * 0.14, gy - r.size.y * 0.14),
			Vector2(r.position.x + r.size.x * 0.3, gy - r.size.y * 0.2), Vector2(r.position.x + r.size.x * 0.3 + r.size.y * 0.14, gy - r.size.y * 0.14), Vector2(r.position.x + r.size.x * 0.3 + r.size.y * 0.2, gy)]), dark)
		draw_rect(Rect2(r.position.x + r.size.x * 0.44, gy - 26.0, 66.0, 26.0), dark)
		draw_rect(Rect2(r.position.x + r.size.x * 0.47, gy - 50.0, 60.0, 24.0), Color(0.05, 0.06, 0.1))
		for fp in 9:
			draw_rect(Rect2(r.position.x + r.size.x * 0.62 + fp * 12.0, gy - 18.0, 2.0, 18.0), dark)
		draw_rect(Rect2(r.position.x + r.size.x * 0.62, gy - 14.0, 98.0, 1.0), dark)
		for lp in 2:                                            # lamps, their light on the ground
			var lx := r.position.x + r.size.x * (0.2 + lp * 0.36)
			draw_rect(Rect2(lx, gy - 48.0, 3.0, 48.0), Color(0.1, 0.11, 0.15))
			draw_colored_polygon(PackedVector2Array([Vector2(lx + 1.0, gy - 46.0), Vector2(lx + 30.0, gy + 4.0), Vector2(lx - 28.0, gy + 4.0)]), Color(1.0, 0.92, 0.7, 0.045))
			draw_circle(Vector2(lx + 1.0, gy - 49.0), 16.0, Color(1.0, 0.92, 0.7, 0.1))
			draw_rect(Rect2(lx - 5.0, gy - 52.0, 13.0, 6.0), Color(1.0, 0.93, 0.75))
		var wx := r.position.x + r.size.x * 0.9                    # a wreck that still burns
		draw_rect(Rect2(wx - 30.0, gy - 16.0, 56.0, 16.0), dark)
		draw_rect(Rect2(wx - 12.0, gy - 26.0, 22.0, 12.0), dark)
		for fl in 5:
			var fh := 14.0 + 12.0 * absf(sin(_t * 5.0 + fl * 1.7))
			draw_colored_polygon(PackedVector2Array([Vector2(wx - 22.0 + fl * 10.0, gy - 16.0), Vector2(wx - 17.0 + fl * 10.0, gy - 16.0 - fh), Vector2(wx - 12.0 + fl * 10.0, gy - 16.0)]),
				Color(1.0, 0.5 + 0.3 * _h(fl, 4), 0.15, 0.9))
		draw_circle(Vector2(wx, gy - 14.0), 46.0, Color(1.0, 0.5, 0.15, 0.08))
		for z in 9:                                             # those who still walk: dark shapes, two points of light for eyes
			var zx := r.position.x + 4.0 + fposmod(_h(z, 5) * r.size.x + _t * (5.0 + 4.0 * _h(z, 6)) * (1.0 if z % 2 == 0 else -1.0), r.size.x - 24.0)
			var zy := gy + 26.0 + _h(z, 7) * (r.end.y - gy - 30.0)
			var bob := absf(sin(_t * 3.0 + z)) * 2.0
			draw_rect(Rect2(zx, zy - 20.0 + bob, 9.0, 14.0), Color(0.02, 0.03, 0.04))
			draw_rect(Rect2(zx + 1.0, zy - 27.0 + bob, 7.0, 7.0), Color(0.02, 0.03, 0.04))
			draw_rect(Rect2(zx + (7.0 if z % 2 == 0 else -5.0), zy - 18.0 + bob, 7.0, 3.0), Color(0.02, 0.03, 0.04))
			draw_rect(Rect2(zx + 2.0, zy - 25.0 + bob, 2.0, 2.0), Color(0.9, 1.0, 0.4))
			draw_rect(Rect2(zx + 5.0, zy - 25.0 + bob, 2.0, 2.0), Color(0.9, 1.0, 0.4))
		draw_rect(r, Color(GREEN, 0.8), false, 2.0)
		ui.brackets(self, r.grow(3.0), GREEN, 20.0, 3.0)

	## (Part 9) A picture of the stage Whiteout: a moon of ice by day: peaks of ice under a pale sun with its ring,
	## snow driving across, a floe of bare ice, a vent that steams, and dark shapes in the snow.
	func _vista_whiteout(r: Rect2) -> void:
		var ice := Color(0.6, 0.92, 1.0)
		for b in 6:                                             # the sky: pale blue, nearly white towards the ground
			draw_rect(Rect2(r.position.x, r.position.y + r.size.y * 0.1 * b, r.size.x, r.size.y * 0.1 + 1.0), Color(0.46 + 0.075 * b, 0.68 + 0.05 * b, 0.93 + 0.012 * b))
		var gy := r.position.y + r.size.y * 0.58
		var sun := Vector2(r.position.x + r.size.x * 0.72, r.position.y + r.size.y * 0.24)
		draw_circle(sun, 50.0, Color(1.0, 1.0, 1.0, 0.14))      # the sun, pale, a ring round it, a sun dog to either side
		draw_circle(sun, 28.0, Color(1.0, 1.0, 1.0, 0.3))
		draw_circle(sun, 13.0, Color(1.0, 1.0, 0.96))
		draw_arc(sun, 46.0, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.5), 2.0)
		for sdg in [-1.0, 1.0]:
			draw_circle(sun + Vector2(sdg * 46.0, 0.0), 5.0, Color(1.0, 0.94, 0.78, 0.85))
		for row in 2:                                           # peaks of ice along the horizon, two rows: a lit face, a face in shadow
			var cnt := 7 if row == 0 else 9
			var bw := r.size.x / float(cnt)
			for pk in cnt:
				var x0 := r.position.x + pk * bw
				var ph := r.size.y * ((0.3 if row == 0 else 0.13) + (0.14 if row == 0 else 0.2) * _h(pk + row * 20, 42))
				var tip := Vector2(x0 + bw * (0.35 + 0.3 * _h(pk + row * 20, 43)), gy - ph)
				draw_colored_polygon(PackedVector2Array([Vector2(x0, gy), tip, Vector2(x0 + bw, gy)]), Color(0.64, 0.78, 0.95) if row == 0 else Color(0.44, 0.62, 0.88))
				draw_colored_polygon(PackedVector2Array([Vector2(x0, gy), tip, Vector2(tip.x + bw * 0.12, gy)]), Color(0.8, 0.9, 1.0) if row == 0 else Color(0.92, 0.97, 1.0))
		draw_rect(Rect2(r.position.x, gy, r.size.x, r.end.y - gy), Color(0.84, 0.9, 0.98))      # the snow
		draw_rect(Rect2(r.position.x, gy, r.size.x, 3.0), Color(0.6, 0.74, 0.93))
		for dr in 12:                                           # drifts, a shadow in the lee of each
			var dx := r.position.x + 10.0 + _h(dr, 51) * (r.size.x - 140.0)
			var dy := gy + 12.0 + _h(dr, 52) * (r.end.y - gy - 26.0)
			var dw := 50.0 + 60.0 * _h(dr, 53)
			draw_rect(Rect2(dx + 6.0, dy + 3.0, dw, 3.0), Color(0.58, 0.72, 0.92, 0.7))
			draw_rect(Rect2(dx, dy, dw, 3.0), Color(1.0, 1.0, 1.0, 0.9))
		var fc := Vector2(r.position.x + r.size.x * 0.3, gy + (r.end.y - gy) * 0.58)      # a floe of bare ice
		var floe := PackedVector2Array()
		for q in 28:
			floe.append(fc + Vector2(cos(q * TAU / 28.0) * r.size.x * 0.17, sin(q * TAU / 28.0) * 19.0))
		draw_colored_polygon(floe, Color(0.4, 0.66, 0.92))
		floe.append(floe[0])
		draw_polyline(floe, Color(1.0, 1.0, 1.0, 0.95), 2.0)
		for gl in 5:
			var gp := fc + Vector2((_h(gl, 54) - 0.5) * r.size.x * 0.24, (_h(gl, 55) - 0.5) * 20.0)
			draw_line(gp, gp + Vector2(26.0, -4.0), Color(1.0, 1.0, 1.0, 0.4 + 0.5 * absf(sin(_t * 1.4 + gl))), 1.5)
		var vp := Vector2(r.position.x + r.size.x * 0.62, gy + 34.0)      # a vent, steaming
		var hole := PackedVector2Array()
		for q2 in 16:
			hole.append(vp + Vector2(cos(q2 * TAU / 16.0) * 20.0, sin(q2 * TAU / 16.0) * 6.0))
		draw_colored_polygon(hole, Color(0.1, 0.13, 0.2))
		for st in 6:
			var sk := fposmod(_t * 0.45 + st / 6.0, 1.0)
			var sp := vp + Vector2(sin(_t * 1.6 + st * 1.9) * 7.0, -6.0 - sk * 74.0)
			draw_circle(sp + Vector2(2.0, 2.0), 8.0 + sk * 13.0, Color(0.3, 0.48, 0.8, 0.6 * (1.0 - sk)))
			draw_circle(sp, 6.0 + sk * 13.0, Color(1.0, 1.0, 1.0, 0.92 * (1.0 - sk)))
		var bx := r.position.x + r.size.x * 0.86                # a rimeback: a heavy dark shape, spikes of ice on its back
		var by := gy + 70.0 + absf(sin(_t * 2.0)) * 1.5
		var fur := Color(0.14, 0.14, 0.24)
		draw_rect(Rect2(bx - 26.0, by - 24.0, 50.0, 20.0), fur)
		draw_rect(Rect2(bx - 36.0, by - 16.0, 14.0, 12.0), fur)
		for lg in 4:
			draw_rect(Rect2(bx - 24.0 + lg * 13.0, by - 6.0, 6.0, 8.0), fur)
		draw_rect(Rect2(bx - 34.0, by - 12.0, 3.0, 3.0), ice)
		for spk in 6:
			var sx := bx - 22.0 + spk * 8.0
			var sh := 9.0 + 9.0 * _h(spk, 56)
			draw_colored_polygon(PackedVector2Array([Vector2(sx, by - 24.0), Vector2(sx + 4.0, by - 24.0 - sh), Vector2(sx + 8.0, by - 24.0)]), Color(0.42, 0.74, 1.0))
			draw_line(Vector2(sx, by - 24.0), Vector2(sx + 4.0, by - 24.0 - sh), Color(1.0, 1.0, 1.0), 1.5)
		for z in 12:                                            # mites: small dark things on six legs, frost on their backs
			var zx := r.position.x + 6.0 + fposmod(_h(z, 5) * r.size.x + _t * (9.0 + 7.0 * _h(z, 6)) * (1.0 if z % 2 == 0 else -1.0), r.size.x - 30.0)
			var zy := gy + 22.0 + _h(z, 7) * (r.end.y - gy - 28.0)
			var step := 1.0 if int(_t * 8.0 + z) % 2 == 0 else 0.0
			var shell := Color(0.09, 0.1, 0.2)
			draw_rect(Rect2(zx, zy - 8.0, 14.0, 6.0), shell)
			draw_rect(Rect2(zx + (12.0 if z % 2 == 0 else -3.0), zy - 7.0, 5.0, 5.0), shell)
			draw_rect(Rect2(zx + (15.0 if z % 2 == 0 else -2.0), zy - 6.0, 2.0, 2.0), ice)
			draw_rect(Rect2(zx + 3.0, zy - 9.0, 8.0, 1.0), Color(0.9, 0.97, 1.0))
			for lg2 in 3:
				draw_rect(Rect2(zx + 1.0 + lg2 * 5.0, zy - 2.0, 2.0, 2.0 + (step if lg2 % 2 == 0 else 1.0 - step)), shell)
		for sn in 44:                                           # snow driving across
			var nx := r.position.x + fposmod(_h(sn, 61) * r.size.x + _t * (130.0 + 90.0 * _h(sn, 62)), r.size.x - 24.0)
			var ny := r.position.y + 6.0 + _h(sn, 63) * (r.size.y - 16.0)
			draw_line(Vector2(nx, ny), Vector2(nx + 20.0, ny + 4.0), Color(1.0, 1.0, 1.0, 0.3 + 0.4 * _h(sn, 64)), 1.5)
		draw_rect(r, Color(ice, 0.8), false, 2.0)
		ui.brackets(self, r.grow(3.0), ice, 20.0, 3.0)

	## (Part 11a) A picture of the Alien Laboratory: a long corridor running in to a great tank that glows, strips of
	## light along its walls, small shapes with large heads coming down it, two tall thin ones, a saucer drifting by.
	func _vista_lab(r: Rect2) -> void:
		var lab := Color(0.55, 1.0, 0.35)
		var glow := Color(0.3, 1.0, 0.5)
		draw_rect(r, Color(0.09, 0.12, 0.15))                   # the wall: pale panels in a dim light
		var gy := r.position.y + r.size.y * 0.74
		for sx in range(int(r.position.x) + 40, int(r.end.x), 86):
			draw_rect(Rect2(sx, r.position.y, 2.0, gy - r.position.y), Color(0.05, 0.07, 0.09))
		var ly := r.position.y + r.size.y * 0.13                # a strip of light along it, a pulse running down it
		draw_rect(Rect2(r.position.x, ly, r.size.x, 3.0), Color(0.45, 1.0, 0.75, 0.9))
		draw_rect(Rect2(r.position.x, ly + 3.0, r.size.x, 8.0), Color(0.45, 1.0, 0.75, 0.08))
		draw_circle(Vector2(r.position.x + fposmod(_t * 220.0, r.size.x), ly + 1.5), 5.0, Color(0.9, 1.0, 0.95))
		draw_rect(Rect2(r.position.x, gy, r.size.x, r.end.y - gy), Color(0.04, 0.06, 0.08))      # the floor
		draw_rect(Rect2(r.position.x, gy, r.size.x, 2.0), Color(0.2, 0.6, 0.62, 0.7))
		var mid := r.position.x + r.size.x * 0.5
		var count := maxi(4, int(r.size.x / 150.0))
		var th := r.size.y * 0.46
		for q in count:                                         # tanks along the wall, something in each
			var tx := r.position.x + (q + 0.5) * r.size.x / count
			if absf(tx - mid) < 130.0:
				continue
			var beat := 0.5 + 0.5 * sin(_t * 1.3 + q * 1.7)
			draw_circle(Vector2(tx, gy - th * 0.5), th * (0.72 + 0.06 * beat), Color(glow, 0.07))
			draw_set_transform(Vector2(tx, gy + 12.0), 0.0, Vector2(1.0, 0.25))
			draw_circle(Vector2.ZERO, 40.0, Color(glow, 0.1))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			draw_rect(Rect2(tx - 22.0, gy - 8.0, 44.0, 8.0), Color(0.16, 0.19, 0.23))
			draw_rect(Rect2(tx - 18.0, gy - 8.0 - th, 36.0, th), Color(0.08, 0.42, 0.24))
			draw_rect(Rect2(tx - 18.0, gy - 8.0 - th, 36.0, 3.0), Color(0.3, 0.9, 0.5))
			draw_rect(Rect2(tx - 21.0, gy - 14.0 - th, 42.0, 7.0), Color(0.16, 0.19, 0.23))
			var dk := Color(0.02, 0.14, 0.08)
			var cy := gy - 8.0 - th * 0.5 + sin(_t * 0.9 + q) * 3.0
			match q % 3:
				0:                                              # curled up, a large head
					draw_circle(Vector2(tx - 1.0, cy - 9.0), 8.0, dk)
					draw_circle(Vector2(tx + 2.0, cy + 6.0), 7.0, dk)
				1:                                              # one of them, hanging in it
					draw_circle(Vector2(tx, cy - 12.0), 7.5, dk)
					draw_rect(Rect2(tx - 3.0, cy - 6.0, 6.0, 20.0), dk)
					draw_rect(Rect2(tx - 7.0, cy - 4.0, 2.0, 14.0), dk)
					draw_rect(Rect2(tx + 5.0, cy - 4.0, 2.0, 14.0), dk)
				_:                                              # a bell, its arms trailing
					draw_circle(Vector2(tx, cy - 8.0), 9.0, dk)
					for ar in 4:
						draw_line(Vector2(tx - 6.0 + ar * 4.0, cy - 2.0), Vector2(tx - 7.0 + ar * 4.0 + sin(_t * 2.0 + ar + q) * 3.0, cy + 16.0), dk, 2.0)
			draw_rect(Rect2(tx - 15.0, gy - 4.0 - th, 2.0, th * 0.7), Color(0.75, 1.0, 0.9, 0.55))
		var bt := Rect2(mid - 74.0, r.position.y + r.size.y * 0.1, 148.0, gy - 10.0 - r.position.y - r.size.y * 0.1)      # the great tank, and what sleeps in it
		var bb := 0.5 + 0.5 * sin(_t * 1.6)
		draw_circle(bt.get_center(), bt.size.y * (0.9 + 0.08 * bb), Color(glow, 0.07))
		draw_circle(bt.get_center(), bt.size.y * 0.62, Color(glow, 0.08 + 0.04 * bb))
		draw_rect(Rect2(bt.position.x - 12.0, gy - 12.0, bt.size.x + 24.0, 12.0), Color(0.16, 0.19, 0.23))
		for wl in 6:
			draw_rect(Rect2(bt.position.x - 8.0 + wl * (bt.size.x + 8.0) / 5.0, gy - 6.0, 10.0, 4.0), Color(0.95, 0.78, 0.2))
		draw_rect(bt, Color(0.06, 0.3, 0.2))
		draw_rect(Rect2(bt.position.x, bt.position.y, bt.size.x, 3.0), Color(0.3, 0.9, 0.5))
		draw_rect(Rect2(bt.position.x - 6.0, bt.position.y - 10.0, bt.size.x + 12.0, 11.0), Color(0.16, 0.19, 0.23))
		var brain := bt.get_center() + Vector2(0.0, -bt.size.y * 0.1 + sin(_t * 0.8) * 2.0)
		var mass := Color(0.16, 0.44, 0.3)
		draw_set_transform(brain, 0.0, Vector2(1.0, 0.72))
		draw_circle(Vector2(-14.0, 0.0), 34.0, mass)
		draw_circle(Vector2(16.0, 2.0), 32.0, mass.darkened(0.08))
		for fo in 7:
			draw_arc(Vector2(-34.0 + fo * 11.0, -4.0), 13.0, 0.4 + fo * 0.3, 2.6 + fo * 0.3, 8, mass.darkened(0.35), 2.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_rect(Rect2(brain.x - 1.0, brain.y - 22.0, 2.0, 44.0), mass.darkened(0.4))
		draw_colored_polygon(PackedVector2Array([brain + Vector2(-7.0, 18.0), brain + Vector2(7.0, 18.0), Vector2(brain.x + 2.0, bt.end.y), Vector2(brain.x - 2.0, bt.end.y)]), mass.darkened(0.15))
		draw_rect(Rect2(bt.position.x + 5.0, bt.position.y + 8.0, 3.0, bt.size.y * 0.6), Color(0.75, 1.0, 0.9, 0.5))
		for g in 2:                                             # two tall thin ones by the wall: one half inside it
			var gx := r.position.x + r.size.x * (0.3 if g == 0 else 0.71)
			var gc := Color(0.03, 0.05, 0.07, 0.42 if g == 0 else 1.0)
			var gb := gy + (0.0 if g == 0 else 10.0)
			draw_rect(Rect2(gx - 3.0, gb - 52.0, 6.0, 52.0), gc)
			draw_rect(Rect2(gx - 7.0, gb - 50.0, 2.0, 34.0), gc)
			draw_rect(Rect2(gx + 5.0, gb - 50.0, 2.0, 34.0), gc)
			draw_set_transform(Vector2(gx, gb - 64.0), 0.0, Vector2(1.0, 1.25))
			draw_circle(Vector2.ZERO, 11.0, gc)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			draw_rect(Rect2(gx - 8.0, gb - 66.0, 6.0, 3.0), Color(0.7, 0.8, 0.95, gc.a))
			draw_rect(Rect2(gx + 2.0, gb - 66.0, 6.0, 3.0), Color(0.7, 0.8, 0.95, gc.a))
		for z in 12:                                            # the small ones, coming along the hall: large heads, antennae, eyes of light
			var way := 1.0 if z % 2 == 0 else -1.0
			var zx := r.position.x + 6.0 + fposmod(_h(z, 41) * r.size.x + _t * (16.0 + 12.0 * _h(z, 42)) * way, r.size.x - 30.0)
			var deep := _h(z, 43)
			var zy := gy + 16.0 + deep * (r.end.y - gy - 20.0)
			var sc := 0.8 + deep * 0.5
			var bob := absf(sin(_t * 5.0 + z)) * 2.0
			var zc := Color(0.01, 0.03, 0.03)
			draw_rect(Rect2(zx - 4.0 * sc, zy - 13.0 * sc + bob, 8.0 * sc, 13.0 * sc - bob), zc)
			draw_circle(Vector2(zx, zy - 19.0 * sc + bob), 8.0 * sc, zc)
			draw_line(Vector2(zx - 4.0 * sc, zy - 25.0 * sc + bob), Vector2(zx - 6.0 * sc, zy - 34.0 * sc + bob), zc, 2.0)
			draw_line(Vector2(zx + 4.0 * sc, zy - 25.0 * sc + bob), Vector2(zx + 6.0 * sc, zy - 34.0 * sc + bob), zc, 2.0)
			draw_circle(Vector2(zx - 6.0 * sc, zy - 35.0 * sc + bob), 1.6, Color(1.0, 1.0, 0.5))
			draw_circle(Vector2(zx + 6.0 * sc, zy - 35.0 * sc + bob), 1.6, Color(1.0, 1.0, 0.5))
			draw_rect(Rect2(zx - 5.0 * sc + way * sc, zy - 21.0 * sc + bob, 3.0 * sc, 4.0 * sc), lab)
			draw_rect(Rect2(zx + 2.0 * sc + way * sc, zy - 21.0 * sc + bob, 3.0 * sc, 4.0 * sc), lab)
		var sp := Vector2(r.position.x + fposmod(_t * 34.0, r.size.x + 200.0) - 100.0, r.position.y + r.size.y * 0.3 + sin(_t * 1.3) * 5.0)      # a saucer drifting through the hall
		if sp.x > r.position.x + 60.0 and sp.x < r.end.x - 60.0:
			draw_colored_polygon(PackedVector2Array([sp + Vector2(-9.0, 6.0), sp + Vector2(9.0, 6.0), Vector2(sp.x + 30.0, gy), Vector2(sp.x - 30.0, gy)]), Color(0.5, 1.0, 0.6, 0.1))
			draw_set_transform(sp, 0.0, Vector2(1.0, 0.3))
			draw_circle(Vector2.ZERO, 44.0, Color(0.5, 0.56, 0.62))
			draw_set_transform(sp + Vector2(0.0, -7.0), 0.0, Vector2(1.0, 0.75))
			draw_circle(Vector2.ZERO, 17.0, Color(0.45, 0.85, 0.8))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			for sl in 6:
				draw_rect(Rect2(sp.x - 34.0 + sl * 13.0, sp.y + 3.0, 4.0, 4.0), lab if (sl + int(_t * 4.0)) % 2 == 0 else Color(1.0, 0.8, 0.3))
		draw_rect(r, Color(lab, 0.8), false, 2.0)
		ui.brackets(self, r.grow(3.0), lab, 20.0, 3.0)

	## (Part 8) A picture of the stage AI Takeover: what is left of a skyline against a red night, searchlights in
	## the clouds, tracers of a far fight, rubble before it, a wreck that burns, and red eyes in the dark.
	func _vista_takeover(r: Rect2) -> void:
		for b in 5:                                             # the night: a red glow low down
			draw_rect(Rect2(r.position.x, r.position.y + r.size.y * 0.145 * b, r.size.x, r.size.y * 0.145 + 1.0), Color(0.05 + 0.035 * b, 0.03 + 0.008 * b, 0.07 + 0.012 * b))
		var gy := r.position.y + r.size.y * 0.72
		for sl in 3:                                            # searchlights, swinging through the clouds
			var bx := r.position.x + r.size.x * (0.2 + sl * 0.29)
			var tip := Vector2(clampf(bx + sin(_t * 0.7 + sl * 2.1) * r.size.y * 0.5, r.position.x + 30.0, r.end.x - 30.0), r.position.y + 4.0)
			draw_colored_polygon(PackedVector2Array([Vector2(bx - 3.0, gy), Vector2(bx + 3.0, gy), tip + Vector2(26.0, 0.0), tip + Vector2(-26.0, 0.0)]), Color(1.0, 0.95, 0.8, 0.14))
			draw_rect(Rect2(tip.x - 30.0, r.position.y + 2.0, 60.0, 10.0), Color(1.0, 0.95, 0.8, 0.07))
		var dark := Color(0.03, 0.03, 0.05)
		for tw in 14:                                           # what is left of the skyline: broken towers
			var x0 := r.position.x + tw * r.size.x / 14.0
			var th := r.size.y * (0.16 + 0.36 * _h(tw, 11))
			var tww := r.size.x / 14.0 + 1.0 if tw < 13 else r.size.x / 14.0
			var tc := dark.lightened(0.035 * (tw % 3))
			draw_rect(Rect2(x0, gy - th + 10.0, tww, th - 10.0), tc)
			draw_colored_polygon(PackedVector2Array([Vector2(x0, gy - th + 11.0), Vector2(x0, gy - th + 3.0), Vector2(x0 + tww * 0.35, gy - th - 6.0 * _h(tw, 12)), Vector2(x0 + tww * 0.6, gy - th + 8.0),
				Vector2(x0 + tww, gy - th + 1.0), Vector2(x0 + tww, gy - th + 11.0)]), tc)
			if tw % 3 == 1:
				draw_rect(Rect2(x0 + tww * 0.3, gy - th * 0.55, 3.0, 3.0), Color(1.0, 0.25, 0.2, 0.55 + 0.4 * absf(sin(_t * 2.0 + tw))))
		for tr in 4:                                            # tracers
			var tk := fposmod(_t * 0.9 + tr * 0.27, 1.0)
			var td := Vector2(1.0, -0.25 + 0.5 * _h(tr, 23)).normalized() * (1.0 if tr % 2 == 0 else -1.0)
			var tp := r.position + Vector2(r.size.x * (0.5 + (tk - 0.5) * 0.9 * td.x), r.size.y * (0.14 + 0.36 * _h(tr, 22)) + (tk - 0.5) * 60.0 * td.y)
			if r.has_point(tp) and r.has_point(tp - td * 44.0):
				draw_line(tp - td * 44.0, tp, Color(0.75, 0.45, 1.0, 0.85), 2.0)
		draw_rect(Rect2(r.position.x, gy, r.size.x, r.end.y - gy), Color(0.06, 0.06, 0.09))      # the ground: rubble
		draw_rect(Rect2(r.position.x, gy, r.size.x, 2.0), Color(0.17, 0.14, 0.18))
		for rb in 16:
			draw_rect(Rect2(r.position.x + 6.0 + _h(rb, 31) * (r.size.x - 40.0), gy + 6.0 + _h(rb, 32) * (r.end.y - gy - 20.0), 10.0 + 14.0 * _h(rb, 33), 4.0 + 5.0 * _h(rb, 34)), Color(0.1, 0.1, 0.14))
		var wx := r.position.x + r.size.x * 0.88                   # a wreck that still burns
		draw_rect(Rect2(wx - 30.0, gy - 14.0, 56.0, 14.0), dark)
		draw_rect(Rect2(wx - 6.0, gy - 24.0, 26.0, 12.0), dark)
		for fl in 5:
			var fh := 12.0 + 12.0 * absf(sin(_t * 5.0 + fl * 1.7))
			draw_colored_polygon(PackedVector2Array([Vector2(wx - 22.0 + fl * 10.0, gy - 14.0), Vector2(wx - 17.0 + fl * 10.0, gy - 14.0 - fh), Vector2(wx - 12.0 + fl * 10.0, gy - 14.0)]),
				Color(1.0, 0.5 + 0.3 * _h(fl, 4), 0.15, 0.9))
		draw_circle(Vector2(wx, gy - 12.0), 44.0, Color(1.0, 0.5, 0.15, 0.08))
		for z in 10:                                            # those who walk here now: tall dark shapes, one red eye each
			var zx := r.position.x + 4.0 + fposmod(_h(z, 5) * r.size.x + _t * (5.0 + 4.0 * _h(z, 6)) * (1.0 if z % 2 == 0 else -1.0), r.size.x - 22.0)
			var zy := gy + 34.0 + _h(z, 7) * (r.end.y - gy - 38.0)
			var bob := absf(sin(_t * 3.0 + z)) * 1.5
			draw_rect(Rect2(zx + 1.0, zy - 13.0 + bob, 2.0, 13.0 - bob), Color(0.02, 0.02, 0.03))
			draw_rect(Rect2(zx + 5.0, zy - 13.0 + bob, 2.0, 13.0 - bob), Color(0.02, 0.02, 0.03))
			draw_rect(Rect2(zx, zy - 24.0 + bob, 8.0, 12.0), Color(0.02, 0.02, 0.03))
			draw_rect(Rect2(zx + 2.0, zy - 32.0 + bob, 5.0, 8.0), Color(0.02, 0.02, 0.03))
			draw_rect(Rect2(zx + (5.0 if z % 2 == 0 else 2.0), zy - 29.0 + bob, 2.0, 2.0), Color(1.0, 0.2, 0.15))
		draw_rect(r, Color(RED, 0.8), false, 2.0)
		ui.brackets(self, r.grow(3.0), RED, 20.0, 3.0)

	func _draw() -> void:
		var vs := get_viewport_rect().size
		var font := ThemeDB.fallback_font
		var k_in := ease(clampf(_t / 0.6, 0.0, 1.0), 0.3)
		var k2 := ease(clampf((_t - 0.25) / 0.6, 0.0, 1.0), 0.3)
		var k_out := clampf((_t - (LEN - 0.4)) / 0.4, 0.0, 1.0)
		draw_rect(Rect2(Vector2.ZERO, vs), Color(0.02, 0.02, 0.05))
		var lx := -vs.x * 0.6 * (1.0 - k_in)                   # three slanted fields sliding in: you from the left; the stage and your weapon from the right
		var rx := vs.x * 0.7 * (1.0 - k_in)
		var rx2 := vs.x * 0.7 * (1.0 - k2)
		var top := 0.42                                         # where the slanted edge stands at the top, the middle and the foot (shares of the width)
		var mid := 0.36
		var foot := 0.3
		var my := vs.y * 0.52
		draw_colored_polygon(PackedVector2Array([Vector2(lx, 0.0), Vector2(lx + vs.x * top, 0.0), Vector2(lx + vs.x * foot, vs.y), Vector2(lx, vs.y)]), Color(0.06, 0.2, 0.4))
		var machines := stage == "takeover"                     # (part 8) the second stage: its own colour, its own picture
		var snow := stage == "whiteout"                         # (part 9) the third: by day
		var stage_col: Color = SD.stage(stage).get("col", GREEN)
		draw_colored_polygon(PackedVector2Array([Vector2(rx + vs.x * top, 0.0), Vector2(rx + vs.x, 0.0), Vector2(rx + vs.x, my - 3.0), Vector2(rx + vs.x * mid, my - 3.0)]),
			Color(0.22, 0.07, 0.09) if machines else (Color(0.1, 0.24, 0.36) if snow else (Color(0.09, 0.2, 0.07) if stage == "lab" else Color(0.06, 0.22, 0.16))))
		draw_colored_polygon(PackedVector2Array([Vector2(rx2 + vs.x * mid, my + 3.0), Vector2(rx2 + vs.x, my + 3.0), Vector2(rx2 + vs.x, vs.y), Vector2(rx2 + vs.x * foot, vs.y)]), Color(0.05, 0.17, 0.24))
		for sl in range(0, int(vs.y), 8):
			draw_rect(Rect2(0.0, sl, vs.x, 2.0), Color(0, 0, 0, 0.14))
		draw_line(Vector2(rx + vs.x * mid, my), Vector2(rx + vs.x, my), Color(GOLD, 0.9), 2.0)
		# you
		if you_tex != null:
			var yh := vs.y * 0.6
			var yw := yh * you_tex.get_width() / you_tex.get_height()
			draw_texture_rect(you_tex, Rect2(lx + vs.x * 0.17 - yw * 0.5, vs.y * 0.78 - yh, yw, yh), false)
		draw_string(font, Vector2(lx + vs.x * 0.17 - 300.0, vs.y * 0.78 + 42.0), you_name, HORIZONTAL_ALIGNMENT_CENTER, 600.0, 34, Color(0.7, 0.9, 1.0))
		draw_string(font, Vector2(lx + vs.x * 0.17 - 300.0, vs.y * 0.78 + 70.0), "alone", HORIZONTAL_ALIGNMENT_CENTER, 600.0, 16, Color(0.6, 0.7, 0.85))
		draw_string(font, Vector2(lx + 40.0, 70.0), "SURVIVOR", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 44, GOLD)
		# the stage
		var sd: Dictionary = SD.stage(stage)
		var px := rx + vs.x * 0.46
		var pw := vs.x * 0.54 - 40.0
		draw_string(font, Vector2(px, 62.0), "THE STAGE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, GOLD)
		draw_string(font, Vector2(px, 124.0), String(sd["name"]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 62, stage_col)
		draw_string(font, Vector2(px + pw - 300.0, 104.0), SD.time_text(SD.RUN_TIME), HORIZONTAL_ALIGNMENT_RIGHT, 300.0, 44, Color(1, 1, 1))
		draw_string(font, Vector2(px + pw - 300.0, 126.0), "to hold out", HORIZONTAL_ALIGNMENT_RIGHT, 300.0, 15, Color(0.75, 0.85, 0.9))
		if stage == "lab":                                      # (part 11a) the fourth: indoors
			_vista_lab(Rect2(px, 150.0, pw, 250.0))
		elif machines:
			_vista_takeover(Rect2(px, 150.0, pw, 250.0))
		elif snow:
			_vista_whiteout(Rect2(px, 150.0, pw, 250.0))
		else:
			_vista(Rect2(px, 150.0, pw, 250.0))
		draw_string(font, Vector2(px, 432.0), String(sd["text"]), HORIZONTAL_ALIGNMENT_LEFT, pw, 18, Color(0.85, 0.92, 0.95))
		var dangers: Array = SD.stage_data(stage)["dangers"]
		var dx := px
		for dg in dangers:
			var dw := font.get_string_size(String(dg), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15).x + 44.0
			draw_rect(Rect2(dx, 452.0, dw, 30.0), Color(RED, 0.14))
			draw_rect(Rect2(dx, 452.0, dw, 30.0), Color(RED, 0.7), false, 1.0)
			draw_colored_polygon(PackedVector2Array([Vector2(dx + 10.0, 474.0), Vector2(dx + 17.0, 460.0), Vector2(dx + 24.0, 474.0)]), RED)
			draw_string(font, Vector2(dx + 32.0, 473.0), String(dg), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color(1.0, 0.8, 0.78))
			dx += dw + 12.0
		# the weapon you begin with
		var wd: Dictionary = SD.WEAPONS.get(weapon, SD.WEAPONS[SD.START_WEAPON])
		var wx := rx2 + vs.x * 0.42
		var wc := Vector2(wx + 170.0, my + (vs.y - my) * 0.54)
		draw_string(font, Vector2(wx, my + 52.0), "YOUR FIRST WEAPON", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, GOLD)
		ui.hex_frame(self, wc, 96.0, CYAN, _t)
		ui.icon(self, weapon, wc, 50.0, CYAN.lightened(0.2))
		draw_string(font, Vector2(wc.x + 190.0, wc.y - 10.0), String(wd["name"]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 54, Color(1, 1, 1))
		draw_multiline_string(font, Vector2(wc.x + 192.0, wc.y + 28.0), String(wd["text"]), HORIZONTAL_ALIGNMENT_LEFT, vs.x + rx2 - wc.x - 240.0, 19, 3, Color(0.8, 0.9, 0.95))
		var fzn := "Fuses with %s into %s" % [String(SD.BONI[String(wd["bonus"])]["name"]), String(wd["ult"])]
		draw_string(font, Vector2(wc.x + 192.0, wc.y + 112.0), fzn, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, PINK.lightened(0.2))
		draw_rect(Rect2(Vector2.ZERO, vs), Color(1, 1, 1, k_out))


class Result extends Control:
	signal finished(won: bool)
	var res: Dictionary = {}
	var _t := 0.0

	func is_sv_result() -> bool:
		return true

	func setup(cfg: Dictionary) -> void:
		res = cfg.get("res", {})
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func go() -> void:
		if _t < 0.8:
			return
		Audio.play("ui_open", "survivor: on")
		finished.emit(bool(res.get("survived", false)))

	func rect() -> Rect2:
		var vs := get_viewport_rect().size
		return Rect2(vs.x * 0.5 - 180.0, vs.y * 0.5 + 200.0, 360.0, 64.0)

	func _process(dt: float) -> void:
		_t += dt
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			if rect().has_point((event as InputEventMouseButton).position):
				go()
			accept_event()

	func _unhandled_input(event: InputEvent) -> void:
		if event.is_action_pressed("menu_back", false, true) or (event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode in [KEY_ENTER, KEY_SPACE]):
			get_viewport().set_input_as_handled()
			go()

	func pad_button(b: String, pressed: bool) -> bool:
		if pressed and b in ["cross", "circle"]:
			go()
		return true

	func _draw() -> void:
		var vs := get_viewport_rect().size
		var font := ThemeDB.fallback_font
		var held := bool(res.get("survived", false))
		var main := GREEN if held else PINK
		var ui = load("res://scripts/ground/survivor_ui.gd")
		draw_rect(Rect2(Vector2.ZERO, vs), Color(0.02, 0.02, 0.05, 0.9))
		for gx in range(0, int(vs.x), 64):
			draw_line(Vector2(gx, 0.0), Vector2(gx, vs.y), Color(main, 0.03), 1.0)
		for gy in range(0, int(vs.y), 64):
			draw_line(Vector2(0.0, gy), Vector2(vs.x, gy), Color(main, 0.03), 1.0)
		var box := Rect2(vs.x * 0.5 - 430.0, vs.y * 0.5 - 300.0, 860.0, 600.0)
		for g in 3:
			draw_rect(box.grow(6.0 + g * 7.0), Color(main, 0.05 / (g + 1.0)))
		draw_rect(box, Color(0.04, 0.05, 0.1, 0.98))
		draw_rect(box, main, false, 2.0)
		draw_rect(box.grow(-8.0), Color(main, 0.2), false, 1.0)
		ui.brackets(self, box.grow(4.0), main, 34.0, 5.0)
		draw_string(font, Vector2(box.position.x, box.position.y + 86.0), "YOU HELD OUT" if held else "THE RUN IS OVER", HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 60, main)
		draw_string(font, Vector2(box.position.x, box.position.y + 126.0), "Survivor   ·   %s" % String(SD.stage(String(res.get("stage", "outbreak")))["name"]), HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 20,
			Color(0.8, 0.85, 0.95))
		draw_string(font, Vector2(box.position.x, box.position.y + 226.0), SD.time_text(float(res.get("time", 0.0))), HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 84, Color(1, 1, 1))
		if bool(res.get("best", false)):
			draw_string(font, Vector2(box.position.x, box.position.y + 258.0), "your best time on this stage", HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 16, GOLD)
		var opened: Array = res.get("opened", [])               # (part 8) a boss put out for the first time opened a stage
		if not opened.is_empty():
			var ob := Rect2(box.position.x + 170.0, box.position.y + 268.0, box.size.x - 340.0, 28.0)
			draw_rect(ob, Color(GOLD, 0.14 + 0.06 * sin(_t * 4.0)))
			draw_rect(ob, GOLD, false, 1.5)
			draw_string(font, ob.position + Vector2(0.0, 20.0), "A NEW STAGE IS OPEN TO YOU:  %s" % ", ".join(opened.map(func(o): return String(o).to_upper())), HORIZONTAL_ALIGNMENT_CENTER, ob.size.x, 16,
				Color(1, 1, 1))
		var rows: Array = [["Put out", "%d" % int(res.get("kills", 0))], ["Level", "%d" % int(res.get("level", 1))], ["Coins", "+%d" % int(res.get("coins", 0))],
			["Rank points", "+%d" % int(res.get("xp", 0))], ["Cores", "+%d" % int(res.get("cores", 0))]]
		for i in rows.size():
			var ry := box.position.y + 308.0 + i * 36.0
			draw_rect(Rect2(box.position.x + 210.0, ry + 8.0, 440.0, 1.0), Color(main, 0.18))
			draw_string(font, Vector2(box.position.x + 220.0, ry), String(rows[i][0]), HORIZONTAL_ALIGNMENT_LEFT, 300.0, 22, Color(0.75, 0.8, 0.9))
			draw_string(font, Vector2(box.position.x + 340.0, ry), String(rows[i][1]), HORIZONTAL_ALIGNMENT_RIGHT, 300.0, 22, CYAN if i == 4 else (GOLD if i >= 2 else Color(1, 1, 1)))
			if i == 4:                                              # (part 7c-3: what they are for)
				ui.icon(self, "core", Vector2(box.position.x + 200.0, ry - 7.0), 8.0, CYAN)
		draw_string(font, Vector2(box.position.x, box.position.y + 484.0), "Cores buy what stays, at the console in the lobby.", HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 13, Color(0.6, 0.66, 0.78))
		var r := rect()
		var hot := r.has_point(get_local_mouse_position())
		draw_rect(r, Color(0.1, 0.3, 0.2) if hot else Color(0.06, 0.16, 0.12))
		draw_rect(r, GREEN, false, 2.0)
		ui.brackets(self, r.grow(3.0), GREEN, 14.0, 3.0)
		draw_string(font, r.position + Vector2(0.0, 40.0), "Back to the lobby", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 24, Color(1, 1, 1))


## Part 7c-3 (Luz): the Survivor console in the Colosseum's lobby: what your cores buy for good. At the left the
## arsenal (weapons and boni to unlock: they then lie among the cards of a run), at the right fine tuning (small
## shares, rank by rank), the rerolls and the last chance; above, your cores and how far you have come (the crowd in
## the stands goes by that). A tile is bought through the command bus (sv_buy), by seat. Mouse, the arrow keys and
## Enter, or the controller (the cross moves, ✕ buys, ◯ goes back).
class Console extends Control:
	signal finished(won: bool)
	const W := 1760.0
	const H := 900.0
	var sel := 0
	var msg := ""
	var msg_good := false
	var ui = load("res://scripts/ground/survivor_ui.gd")
	var _t := 0.0
	var _flash := 0.0                # the tile just bought lights up
	var _flash_i := -1

	func is_sv_console() -> bool:
		return true

	func setup(_cfg: Dictionary) -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func col() -> Dictionary:
		return GameState.col_state()

	## The console is laid out in its own measure (W by H) and scaled down where the window is smaller.
	func scale_k() -> float:
		var vs := get_viewport_rect().size
		return minf(1.0, minf(vs.x / (W + 60.0), vs.y / (H + 40.0)))

	## Where its top left corner lies in the window.
	func origin() -> Vector2:
		return (get_viewport_rect().size - Vector2(W, H) * scale_k()) * 0.5

	## A point of the window in the console's own measure, a tile's rect in the window.
	func to_design(p: Vector2) -> Vector2:
		return (p - origin()) / scale_k()

	func on_screen(r: Rect2) -> Rect2:
		return Rect2(origin() + r.position * scale_k(), r.size * scale_k())

	## The tiles: [{"what": "unlock" | "tune" | "reroll" | "revive", "kind": "weapon" | "bonus" | "tune" | "reroll" |
	## "revive", "id", "rect"}].
	func items() -> Array:
		var o := Vector2.ZERO
		var out: Array = []
		for i in SD.WEAPON_ORDER.size():
			out.append({"what": "unlock", "kind": "weapon", "id": String(SD.WEAPON_ORDER[i]), "rect": Rect2(o.x + (i % 7) * 151.4, o.y + 150.0 + (i / 7) * 162.0, 142.0, 150.0)})      # (seven to a row since there are thirteen)
		for j in SD.BONUS_ORDER.size():
			out.append({"what": "unlock", "kind": "bonus", "id": String(SD.BONUS_ORDER[j]), "rect": Rect2(o.x + (j % 7) * 151.4, o.y + 520.0 + (j / 7) * 132.0, 142.0, 120.0)})
		var rx := o.x + 1110.0
		for k in SD.TUNE_ORDER.size():
			out.append({"what": "tune", "kind": "tune", "id": String(SD.TUNE_ORDER[k]), "rect": Rect2(rx, o.y + 150.0 + k * 54.0, 650.0, 48.0)})
		out.append({"what": "reroll", "kind": "reroll", "id": "", "rect": Rect2(rx, o.y + 550.0, 650.0, 56.0)})
		out.append({"what": "revive", "kind": "revive", "id": "", "rect": Rect2(rx, o.y + 640.0, 650.0, 132.0)})
		return out

	## What a tile is called.
	func title_of(it: Dictionary) -> String:
		match String(it["kind"]):
			"weapon":
				return String(SD.WEAPONS[String(it["id"])]["name"])
			"bonus":
				return String(SD.BONI[String(it["id"])]["name"])
			"tune":
				return String(SD.TUNE[String(it["id"])]["name"])
			"reroll":
				return "Reroll"
		return "Last chance"

	## … and what it does, in a line.
	func text_of(it: Dictionary) -> String:
		var id := String(it["id"])
		match String(it["kind"]):
			"weapon":
				var wd: Dictionary = SD.WEAPONS[id]
				return "%s  With %s it becomes %s.%s" % [String(wd["text"]), String(SD.BONI[String(wd["bonus"])]["name"]), String(wd["ult"]),
					"  Its card comes from level %d of a run on." % int(wd["from"]) if int(wd.get("from", 0)) > 1 else ""]
			"bonus":
				var fz: Dictionary = SD.fusion({"weapons": [], "boni": []}, {"kind": "bonus", "id": id})
				return String(SD.BONI[id]["text"]) + ("  %s." % String(fz["text"]) if not fz.is_empty() else "")
			"tune":
				return "%s  %s a rank, ten ranks." % [String(SD.TUNE[id]["text"]), String(SD.TUNE[id]["per"])]
			"reroll":
				return "With a new level, draw its three cards anew: once, twice, three times a run."
		return "Once a run you stand up again with half your health, and a shock clears the ground round you."

	## The tile `i` is bought (through the command bus).
	func buy(i: int) -> void:
		var its := items()
		if _t < 0.25 or i < 0 or i >= its.size():
			return
		sel = i
		var it: Dictionary = its[i]
		var e := String(Commands.execute({"type": "sv_buy", "seat": 0, "what": String(it["what"]), "id": String(it["id"])}))
		msg = e if e != "" else "Yours: %s." % title_of(it)
		msg_good = e == ""
		if e == "":
			_flash = 0.6
			_flash_i = i
		Audio.play("ui_error" if e != "" else "sv_level", "survivor: the console")

	func back() -> void:
		Audio.play("ui_click", "survivor: the console shut")
		finished.emit(false)

	## The mark moves to the nearest tile that way.
	func move(d: Vector2) -> void:
		var its := items()
		var c: Vector2 = (its[sel]["rect"] as Rect2).get_center()
		var best := -1
		var best_s := INF
		for i in its.size():
			if i == sel:
				continue
			var v: Vector2 = (its[i]["rect"] as Rect2).get_center() - c
			var along := v.dot(d)
			if along <= 4.0:
				continue
			var sc := along + absf(v.dot(d.orthogonal())) * 2.5
			if sc < best_s:
				best_s = sc
				best = i
		if best >= 0:
			sel = best

	func _process(dt: float) -> void:
		_t += dt
		_flash = maxf(0.0, _flash - dt)
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseMotion:
			var its0 := items()
			for i0 in its0.size():
				if (its0[i0]["rect"] as Rect2).has_point(to_design((event as InputEventMouseMotion).position)):
					sel = i0
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			var its := items()
			for i in its.size():
				if (its[i]["rect"] as Rect2).has_point(to_design((event as InputEventMouseButton).position)):
					buy(i)
			accept_event()

	func _unhandled_input(event: InputEvent) -> void:
		if event.is_action_pressed("menu_back", false, true):
			get_viewport().set_input_as_handled()
			back()
		elif event is InputEventKey and event.pressed:
			var k := (event as InputEventKey).keycode
			var used := true
			match k:
				KEY_LEFT, KEY_A:
					move(Vector2.LEFT)
				KEY_RIGHT, KEY_D:
					move(Vector2.RIGHT)
				KEY_UP, KEY_W:
					move(Vector2.UP)
				KEY_DOWN, KEY_S:
					move(Vector2.DOWN)
				KEY_ENTER, KEY_SPACE, KEY_E:
					if not (event as InputEventKey).echo:
						buy(sel)
				_:
					used = false
			if used:
				get_viewport().set_input_as_handled()

	func pad_button(b: String, pressed: bool) -> bool:
		if not pressed:
			return true
		match b:
			"left":
				move(Vector2.LEFT)
			"right":
				move(Vector2.RIGHT)
			"up":
				move(Vector2.UP)
			"down":
				move(Vector2.DOWN)
			"cross":
				buy(sel)
			"circle":
				back()
		return true

	## What a tile costs, at its lower edge: a core and a figure (red when you cannot pay it), or a word when there is
	## nothing more to buy.
	func _price(p: Vector2, wide: float, cost: int, done: String, cores: int, tint: Color) -> void:
		var font := ThemeDB.fallback_font
		if cost < 0:
			draw_string(font, p, done, HORIZONTAL_ALIGNMENT_CENTER, wide, 13, Color(tint, 0.9))
			return
		var txt := "%d" % cost
		var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17).x
		var x0 := p.x + (wide - tw - 22.0) * 0.5
		var pc := CYAN if cores >= cost else RED
		ui.icon(self, "core", Vector2(x0 + 7.0, p.y - 6.0), 7.0, pc)
		draw_string(font, Vector2(x0 + 22.0, p.y), txt, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17, pc.lightened(0.2))

	## A tile's ground and frame: lit when it is yours, brackets when it is marked, a flash when just bought.
	func _plate(r: Rect2, tint: Color, mine: bool, hot: bool, i: int) -> void:
		for g in 3:
			draw_rect(r.grow(4.0 + g * 5.0), Color(tint, (0.1 if hot else (0.035 if mine else 0.0)) / (g + 1.0)))
		draw_rect(r, Color(DARK, 0.96))
		if mine:
			draw_rect(r, Color(tint, 0.07))
		draw_rect(r, Color(tint, 1.0 if hot else (0.7 if mine else 0.32)), false, 2.5 if hot else 1.5)
		if hot:
			ui.brackets(self, r.grow(4.0), tint, 18.0, 3.0)
		if i == _flash_i and _flash > 0.0:
			draw_rect(r, Color(1, 1, 1, 0.45 * _flash / 0.6))

	func _draw() -> void:
		var vs := get_viewport_rect().size
		var font := ThemeDB.fallback_font
		var c := col()
		var rec: Dictionary = SD.record(c)
		var cores := int(rec["cores"])
		var o := Vector2.ZERO
		draw_rect(Rect2(Vector2.ZERO, vs), Color(0.015, 0.02, 0.05, 0.94))
		for gx in range(0, int(vs.x), 64):                      # a grid of light over the picture
			draw_line(Vector2(gx, 0.0), Vector2(gx, vs.y), Color(CYAN, 0.03), 1.0)
		for gy in range(0, int(vs.y), 64):
			draw_line(Vector2(0.0, gy), Vector2(vs.x, gy), Color(CYAN, 0.03), 1.0)
		draw_set_transform(origin(), 0.0, Vector2(scale_k(), scale_k()))      # (from here on in the console's own measure)
		# ---- the head: what this is, your cores, how far you have come
		draw_string(font, o + Vector2(0.0, 50.0), "SURVIVOR CONSOLE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 46, GREEN)
		draw_string(font, o + Vector2(2.0, 82.0), "What your cores buy stays for every run to come.", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17, Color(0.78, 0.84, 0.94))
		draw_line(o + Vector2(0.0, 104.0), o + Vector2(W, 104.0), Color(GREEN, 0.6), 2.0)
		var cc := o + Vector2(W - 44.0, 44.0)
		ui.hex_frame(self, cc, 30.0, CYAN, _t)
		ui.icon(self, "core", cc, 15.0, CYAN.lightened(0.2))
		draw_string(font, Vector2(cc.x - 360.0, cc.y + 16.0), "%d" % cores, HORIZONTAL_ALIGNMENT_RIGHT, 300.0, 50, Color(1, 1, 1))
		draw_string(font, Vector2(cc.x - 360.0, cc.y + 40.0), "CORES   ·   %d earned in all" % int(rec["cores_all"]), HORIZONTAL_ALIGNMENT_RIGHT, 300.0, 12, Color(CYAN, 0.85))
		var prog: float = SD.progress(c)
		var pb := Rect2(o.x + 700.0, o.y + 30.0, 330.0, 14.0)
		draw_string(font, Vector2(pb.position.x, pb.position.y - 8.0), "UNLOCKED AND TUNED", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color(GOLD, 0.9))
		draw_string(font, Vector2(pb.position.x, pb.position.y - 8.0), "%d %%" % int(round(prog * 100.0)), HORIZONTAL_ALIGNMENT_RIGHT, pb.size.x, 15, Color(1, 1, 1))
		for q in 22:
			var sr := Rect2(pb.position.x + q * 15.0, pb.position.y, 12.0, pb.size.y)
			draw_rect(sr, Color(0.1, 0.16, 0.24))
			if prog * 22.0 > q:
				draw_rect(Rect2(sr.position, Vector2(sr.size.x * clampf(prog * 22.0 - q, 0.0, 1.0), sr.size.y)), GOLD)
		var rig_n: int = SD.rig_tier(c)                           # (part 10b) … and your rig
		draw_string(font, Vector2(pb.position.x, pb.end.y + 18.0), "The crowd in the stands grows with it, and your rig: step %d of %d%s" % [rig_n, SD.RIG_STEPS,
			"." if rig_n < SD.RIG_STEPS else (". The Champion's Regalia is yours." if bool(rec.get("suit", false)) else ". Make room: the Regalia waits.")], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color(0.6, 0.66, 0.78))
		# ---- the headings
		draw_string(font, o + Vector2(0.0, 136.0), "ARSENAL   ·   WEAPONS", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, GOLD)
		draw_string(font, o + Vector2(0.0, 506.0), "ARSENAL   ·   BONI", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, GOLD)
		draw_string(font, o + Vector2(1110.0, 136.0), "FINE TUNING", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, GOLD)
		draw_string(font, o + Vector2(1110.0, 542.0), "REROLL", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, GOLD)
		draw_string(font, o + Vector2(1110.0, 632.0), "LAST CHANCE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, PINK)
		draw_line(o + Vector2(1078.0, 124.0), o + Vector2(1078.0, 776.0), Color(CYAN, 0.2), 1.0)
		# ---- the tiles
		var its := items()
		sel = clampi(sel, 0, its.size() - 1)
		for i in its.size():
			var it: Dictionary = its[i]
			var r: Rect2 = it["rect"]
			var id := String(it["id"])
			var hot := i == sel
			var cost: int = SD.price(c, String(it["what"]), id)
			match String(it["kind"]):
				"weapon", "bonus":
					var weapon := String(it["kind"]) == "weapon"
					var mine: bool = SD.owned(c, id)
					var from_start: bool = id in SD.FREE_WEAPONS or id in SD.FREE_BONI
					var wc: Color = (GREEN if weapon else GOLD) if mine else (CYAN if cores >= cost else Color(0.5, 0.56, 0.7))
					_plate(r, wc, mine, hot, i)
					var hc := r.position + Vector2(r.size.x * 0.5, 62.0 if weapon else 42.0)
					var hr := 30.0 if weapon else 22.0
					if mine:
						ui.hex_frame(self, hc, hr, wc, _t + i * 0.7)
					else:
						draw_colored_polygon((ui.hexpts(hc, hr * 0.86, PI / 6.0) as PackedVector2Array).slice(0, 6), Color(DARK, 0.92))
						draw_polyline(ui.hexpts(hc, hr, PI / 6.0), Color(wc, 0.5), 1.5)
						ui.icon(self, "lock", r.position + Vector2(r.size.x - 20.0, 20.0), 7.0, Color(wc, 0.8))
					ui.icon(self, id, hc, hr * 0.5, wc.lightened(0.2) if mine else Color(wc, 0.6))
					draw_string(font, r.position + Vector2(4.0, 116.0 if weapon else 84.0), title_of(it), HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 8.0, 15 if weapon else 13,
						Color(1, 1, 1) if mine else Color(0.78, 0.82, 0.92))
					_price(r.position + Vector2(0.0, 140.0 if weapon else 108.0), r.size.x, cost, "FROM THE START" if from_start else "YOURS", cores, wc)
				"tune":
					var rank: int = SD.tune_rank(c, id)
					var tcol: Color = GOLD if rank > 0 else (CYAN if cores >= cost and cost >= 0 else Color(0.5, 0.56, 0.7))
					_plate(r, tcol, rank > 0, hot, i)
					draw_string(font, r.position + Vector2(16.0, 22.0), title_of(it), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color(1, 1, 1))
					draw_string(font, r.position + Vector2(16.0, 40.0), "%s a rank" % String(SD.TUNE[id]["per"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color(0.66, 0.72, 0.84))
					for p in SD.TUNE_MAX:
						draw_rect(Rect2(r.position.x + 170.0 + p * 27.0, r.position.y + 17.0, 21.0, 14.0), GOLD if p < rank else Color(0.14, 0.18, 0.26))
					draw_string(font, Vector2(r.position.x + 446.0, r.position.y + 31.0), SD.tune_text(id, rank), HORIZONTAL_ALIGNMENT_RIGHT, 80.0, 18, GOLD if rank > 0 else Color(0.5, 0.56, 0.68))
					_price(Vector2(r.position.x + 540.0, r.position.y + 31.0), 100.0, cost, "LAST RANK", cores, tcol)
				"reroll":
					var have := int(rec["reroll"])
					var rcol: Color = GOLD if have > 0 else (CYAN if cores >= cost and cost >= 0 else Color(0.5, 0.56, 0.7))
					_plate(r, rcol, have > 0, hot, i)
					ui.icon(self, "reroll", r.position + Vector2(34.0, 28.0), 13.0, rcol.lightened(0.2))
					draw_string(font, r.position + Vector2(68.0, 25.0), "Reroll", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 19, Color(1, 1, 1))
					draw_string(font, r.position + Vector2(68.0, 45.0), "a level's three cards drawn anew", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color(0.66, 0.72, 0.84))
					for p2 in SD.REROLL_COST.size():
						var dm := r.position + Vector2(332.0 + p2 * 34.0, 28.0)
						draw_colored_polygon(PackedVector2Array([dm + Vector2(0.0, -11.0), dm + Vector2(11.0, 0.0), dm + Vector2(0.0, 11.0), dm + Vector2(-11.0, 0.0)]), GOLD if p2 < have else Color(0.14, 0.18, 0.26))
					draw_string(font, Vector2(r.position.x + 446.0, r.position.y + 35.0), "%d a run" % have, HORIZONTAL_ALIGNMENT_RIGHT, 80.0, 16, GOLD if have > 0 else Color(0.5, 0.56, 0.68))
					_price(Vector2(r.position.x + 540.0, r.position.y + 35.0), 100.0, cost, "ALL THREE", cores, rcol)
				"revive":
					var got := bool(rec["revive"])
					var vcol: Color = PINK if (got or cores >= cost) else Color(0.6, 0.45, 0.6)
					_plate(r, vcol, got, hot, i)
					var vc := r.position + Vector2(70.0, 66.0)
					ui.hex_frame(self, vc, 40.0, vcol, _t)
					ui.icon(self, "revive", vc, 20.0, vcol.lightened(0.25))
					draw_string(font, r.position + Vector2(140.0, 42.0), "STAND UP AGAIN", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 24, Color(1, 1, 1))
					draw_multiline_string(font, r.position + Vector2(140.0, 68.0), "Once a run. Half your health, and a shock clears the ground round you.", HORIZONTAL_ALIGNMENT_LEFT, 360.0, 14, 3,
						Color(0.82, 0.8, 0.9))
					_price(Vector2(r.position.x + 520.0, r.position.y + 74.0), 120.0, cost, "YOURS", cores, vcol)
		# ---- what the marked tile does, what was said last, the keys
		var cur: Dictionary = its[sel]
		draw_rect(Rect2(o.x, o.y + 792.0, W, 50.0), Color(DARK, 0.9))
		draw_rect(Rect2(o.x, o.y + 792.0, 4.0, 50.0), GREEN)
		draw_string(font, o + Vector2(20.0, 824.0), title_of(cur).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, GREEN)
		var tw0 := font.get_string_size(title_of(cur).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18).x
		var long := font.get_string_size(text_of(cur), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15).x > W - 70.0 - tw0
		draw_multiline_string(font, o + Vector2(44.0 + tw0, 814.0 if long else 824.0), text_of(cur), HORIZONTAL_ALIGNMENT_LEFT, W - 70.0 - tw0, 15, 2, Color(0.84, 0.88, 0.96))
		if msg != "":
			draw_string(font, o + Vector2(0.0, 868.0), msg, HORIZONTAL_ALIGNMENT_LEFT, W * 0.6, 18, GREEN if msg_good else RED)
		draw_string(font, o + Vector2(W * 0.5, 868.0), "Click a tile, or the arrow keys and Enter: buy   ·   Esc: back to the lobby", HORIZONTAL_ALIGNMENT_RIGHT, W * 0.5, 14, Color(0.6, 0.65, 0.78))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
