extends Node2D
## 0.7.52.22 (Luz, package 52b): things to work on with your tools on foot – a maintenance box (cut its flap open with
## the cutting torch: a button or a terminal behind it), a terminal (hack it), a carved tablet and a relic (scan them).
## One node per thing, in the ground view's sorted layer, drawn in art px × SCALE. The things live in
## `GroundMap.explore` ({kind, pos, state, …}); a zone of kind "explore" (its `i`) lets you use them.
## No class_name: preload it.

const ChibiArtE = preload("res://scripts/ground/chibi_art.gd")
const TITLES := {"panel": "Maintenance box – cut it open (cutting torch)", "terminal": "Terminal – hack it",
	"tablet": "Carved tablet – scan it (scanner on your belt)", "relic": "Relic – scan it (scanner on your belt)",
	"blastdoor": "Blast door – sealed (its release is in the box beside it)",
	"vent": "Ventilation shaft – welded shut (cutting torch)",
	"crate": "Supply cache – open it (E)",
	"ruin_gate": "The ruin's entrance – sealed",
	"rust_door": "An old rusted door – sealed (its panel beside it)",
	"grate_door": "A rusted grate door – locked (its box beside it)",
	"steel_door": "A steel door with a code lock – sealed",
	"valve": "Valve wheel – turn it (E): the pumps drain the flooded tunnel",
	"tripwire": "A tripwire – a grenade on the end of it. Disarm it (E)",
	"alarm": "Alarm box – cut its wires (cutting torch) before it rings",
	"bulkhead": "A jammed bulkhead – no power (its box beside it, or the emergency generator)",
	"blackbox": "The flight recorder – pull it out (E)",
	"generator": "The emergency generator – route its power (E)",
	"mine_gen": "The old generator – start it (E)",
	"vein": "Something glitters in the rock – cut it out (cutting torch)",
	"rubble": "A fall of rock buries the drift – blast it (a frag grenade as a charge)",
	"crank_door": "A security door – no power. Crank it open (E, takes a while, loud) – or its fuse box",
	"fuse_box": "A fuse box – a fuse is missing. Put in a spare (E)"}
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


## 0.7.53.2 (Luz): the ruin's entrance in its facade – an angular frame, the old rusted double door with its bands and
## rivets, a line of glyphs and an emblem glowing faintly over it; open, the leaves are pulled into the walls.
func _draw_gate(d: Dictionary, t: float) -> void:
	var tl: Array = d["tiles"]
	var gw := float(tl[2]) * 16.0
	var gh := float(tl[3]) * 16.0
	var top := -gh
	var k := float(d.get("open_k", 0.0))
	var gl := 0.5 + 0.3 * sin(t * 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-gw * 0.5 - 8, 0), Vector2(-gw * 0.5 - 8, top + 10), Vector2(0, top - 8), Vector2(gw * 0.5 + 8, top + 10), Vector2(gw * 0.5 + 8, 0)]), Color(0.14, 0.1, 0.09))
	draw_colored_polygon(PackedVector2Array([Vector2(-gw * 0.5 - 2, 0), Vector2(-gw * 0.5 - 2, top + 12), Vector2(0, top - 2), Vector2(gw * 0.5 + 2, top + 12), Vector2(gw * 0.5 + 2, 0)]), Color(0.05, 0.04, 0.04, 1.0 - k * 0.6))
	var half := gw * 0.5 * (1.0 - k)
	for side in [-1.0, 1.0]:
		if half < 0.6:
			continue
		var x0 := -gw * 0.5 if side < 0.0 else gw * 0.5 - half
		var r := Rect2(x0, top + 12, half, gh - 12)
		draw_rect(r, Color(0.45, 0.31, 0.21))
		draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), Color(0.6, 0.44, 0.32))
		for band in 3:
			var by := r.position.y + 6 + band * (r.size.y - 10) / 3.0
			draw_rect(Rect2(r.position.x, by, r.size.x, 3), Color(0.28, 0.19, 0.13))
			var nr := int(r.size.x / 5.0)
			for rv in nr:
				draw_rect(Rect2(r.position.x + 2 + rv * 5, by + 1, 1, 1), Color(0.62, 0.46, 0.33))
		for rs in 10:
			draw_rect(Rect2(r.position.x + hash_f(rs, int(side) + 5) * r.size.x, r.position.y + hash_f(rs, int(side) + 9) * r.size.y, 1.5, 1.2), Color(0.55, 0.28, 0.12))
	if k < 0.05:
		draw_line(Vector2(0, top + 12), Vector2(0, 0), Color(0.1, 0.08, 0.07), 1.5)
	for gi in 6:
		draw_rect(Rect2(-gw * 0.4 + gi * gw * 0.14, top + 6, gw * 0.08, 1), Color(0.7, 0.5, 1.0, gl))
	draw_circle(Vector2(0, top - 12), 5.0, Color(0.15, 0.1, 0.09))
	draw_arc(Vector2(0, top - 12), 4.0, 0.0, TAU, 12, Color(0.7, 0.5, 1.0, gl), 0.8)
	draw_line(Vector2(0, top - 16), Vector2(0, top - 8), Color(0.7, 0.5, 1.0, gl), 0.8)


## 0.7.53.2 (Luz): a Precursor door inside – a rusted iron slab in the wall's gap, heavy bands, rivets; open, it is
## pulled up into the lintel.
func _draw_rust_door(d: Dictionary, t: float) -> void:
	var tl: Array = d["tiles"]
	var gw := float(tl[2]) * 16.0
	var gh := float(tl[3]) * 16.0
	var top := -gh
	var k := float(d.get("open_k", 0.0))
	draw_rect(Rect2(-gw * 0.5 - 4, top - 4, 4, gh + 4), Color(0.12, 0.09, 0.08))
	draw_rect(Rect2(gw * 0.5, top - 4, 4, gh + 4), Color(0.12, 0.09, 0.08))
	draw_rect(Rect2(-gw * 0.5 - 4, top - 4, gw + 8, 4), Color(0.16, 0.12, 0.1))
	draw_rect(Rect2(-gw * 0.5, top, gw, gh), Color(0.04, 0.03, 0.03, 1.0 - k))
	var hh := gh * (1.0 - k)
	if hh > 0.6 and String(d["kind"]) == "grate_door":
		# 0.7.53.3: a rusted grate – bars, two cross bands, a padlock; the dark tunnel behind it
		var rg := Rect2(-gw * 0.5, top, gw, hh)
		for bx in int(gw / 4.0):
			draw_rect(Rect2(rg.position.x + 1 + bx * 4, rg.position.y, 1.4, rg.size.y), Color(0.45, 0.36, 0.26))
		for cb in [0.15, 0.55]:
			if hh > gh * cb:
				draw_rect(Rect2(rg.position.x, rg.position.y + gh * cb, gw, 2), Color(0.4, 0.31, 0.22))
		draw_rect(Rect2(rg.position.x, rg.end.y - 2, gw, 2), Color(0.35, 0.27, 0.2))
		if String(d["state"]) != "open":
			draw_rect(Rect2(-2, top + gh * 0.5, 4, 5), Color(0.75, 0.62, 0.2))
	elif hh > 0.6 and String(d["kind"]) == "bulkhead":
		# 0.7.53.6: a ship's bulkhead, jammed – grey, hazard chevrons, a dark gap at its foot, sparks from its motor
		var rb := Rect2(-gw * 0.5, top, gw, hh)
		draw_rect(rb, Color(0.45, 0.47, 0.5))
		draw_rect(Rect2(rb.position.x, rb.position.y, gw, 2), Color(0.62, 0.64, 0.67))
		for ch in int(gw / 6.0):
			draw_line(Vector2(rb.position.x + ch * 6, rb.end.y - 10), Vector2(rb.position.x + ch * 6 + 3, rb.end.y - 6), Color(0.95, 0.75, 0.1), 2.0)
		draw_rect(Rect2(-0.5, rb.position.y, 1, hh), Color(0.25, 0.25, 0.27))
		if String(d["state"]) != "open":
			draw_rect(Rect2(rb.position.x, rb.end.y - 3, gw, 3), Color(0.03, 0.03, 0.04))
			if fposmod(t * 1.3, 2.0) < 0.2:
				draw_circle(Vector2(gw * 0.5 - 2, top + 4), 1.5, Color(1.0, 0.85, 0.4))
	elif hh > 0.6 and String(d["kind"]) == "crank_door":
		# 0.7.53.9: a security door, dead – grey leaves, a yellow band, its card reader dark
		var rc7 := Rect2(-gw * 0.5, top, gw, hh)
		draw_rect(rc7, Color(0.45, 0.47, 0.5))
		draw_rect(Rect2(rc7.position.x, rc7.position.y + 10, gw, 3), Color(0.85, 0.7, 0.15))
		draw_rect(Rect2(-0.5, rc7.position.y, 1, hh), Color(0.25, 0.25, 0.27))
	elif hh > 0.6 and String(d["kind"]) == "steel_door":
		# 0.7.53.3: the dealer's door – heavy steel, hazard bands, rivets
		var rs2 := Rect2(-gw * 0.5, top, gw, hh)
		draw_rect(rs2, Color(0.42, 0.44, 0.47))
		draw_rect(Rect2(rs2.position.x, rs2.position.y, gw, 1), Color(0.6, 0.62, 0.65))
		var nb2 := int(hh / 9.0)
		for band2 in nb2:
			draw_rect(Rect2(rs2.position.x + 2, rs2.position.y + 4 + band2 * 9, gw - 4, 2), Color(0.85, 0.68, 0.15))
		draw_rect(Rect2(-0.5, rs2.position.y, 1, hh), Color(0.2, 0.21, 0.23))
		draw_rect(Rect2(rs2.position.x, rs2.end.y - 1, gw, 1), Color(0.2, 0.21, 0.23))
	elif hh > 0.6:
		var r := Rect2(-gw * 0.5, top, gw, hh)
		draw_rect(r, Color(0.46, 0.31, 0.21))
		draw_rect(Rect2(r.position.x, r.end.y - 1, r.size.x, 1), Color(0.25, 0.17, 0.12))
		var nb := int(hh / 10.0)
		for band in nb:
			var by := r.position.y + 4 + band * 10
			draw_rect(Rect2(r.position.x, by, r.size.x, 3), Color(0.28, 0.19, 0.13))
			for rv in int(gw / 6.0):
				draw_rect(Rect2(r.position.x + 2 + rv * 6, by + 1, 1, 1), Color(0.62, 0.46, 0.33))
		for rs in 14:
			draw_rect(Rect2(r.position.x + hash_f(rs, 21) * r.size.x, r.position.y + hash_f(rs, 22) * r.size.y, 1.5, 1.2), Color(0.55, 0.28, 0.12))
		for st in 3:
			var sx := r.position.x + hash_f(st, 23) * r.size.x
			draw_line(Vector2(sx, r.position.y), Vector2(sx, r.position.y + r.size.y * (0.4 + 0.5 * hash_f(st, 24))), Color(0.5, 0.25, 0.1, 0.45), 1.0)
	var lc := Color(0.7, 0.5, 1.0) if String(d["state"]) != "open" else Color(0.3, 1.0, 0.45)
	draw_circle(Vector2(gw * 0.5 + 6, top + gh * 0.4), 1.6, Color(lc, 0.5 + 0.4 * sin(t * 2.0)))


## 0.7.53.4 (Luz): the Precursors' ancient lift – a round iron platform set into the floor in a rusted ring of glyphs,
## two obelisks with crystals beside it, a console before it. Dormant: dust and cracks, dull crystals, a red glyph;
## woken: the glyphs glow, arcs leap between the crystals, a column of light stands over it, motes rise. Riding it,
## the platform (`sink` 0..1) goes down into the dark.
func _draw_ancient_lift(d: Dictionary, t: float) -> void:
	var s := GroundMap.SCALE
	var on := String(d["state"]) != "dormant"
	var sink := float(d.get("sink", 0.0))
	var vi := Color(0.7, 0.5, 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.55) * s)
	draw_circle(Vector2.ZERO, 30.0, Color(0, 0, 0, 0.35))
	draw_circle(Vector2.ZERO, 27.0, Color(0.3, 0.21, 0.15))
	draw_arc(Vector2.ZERO, 27.0, 0.0, TAU, 48, Color(0.45, 0.32, 0.22), 1.5)
	for gi in 16:
		var ga := gi * TAU / 16.0
		var gp := Vector2(cos(ga), sin(ga)) * 23.5
		var gc := vi if on else Color(0.3, 0.24, 0.32)
		if on:
			gc.a = 0.6 + 0.4 * sin(t * 3.0 + gi)
		draw_line(gp - Vector2(sin(ga), -cos(ga)) * 1.6, gp + Vector2(sin(ga), -cos(ga)) * 1.6, gc, 1.2)
	if sink > 0.0:
		draw_circle(Vector2.ZERO, 20.0, Color(0.02, 0.01, 0.03))                       # the shaft opening as it goes down
		draw_circle(Vector2.ZERO, 20.0 * (1.0 - sink * 0.5), Color(0.26, 0.2, 0.18).darkened(sink))
	else:
		draw_circle(Vector2.ZERO, 20.0, Color(0.22, 0.17, 0.14) if not on else Color(0.26, 0.2, 0.18))
		for rr in [15.0, 10.0, 5.0]:
			draw_arc(Vector2.ZERO, rr, 0.0, TAU, 40, Color(0.14, 0.1, 0.08), 1.0)
	if not on:
		for ds in 22:
			draw_circle(Vector2(hash_f(ds, 41) * 36.0 - 18.0, hash_f(ds, 42) * 30.0 - 15.0), 0.9, Color(0.42, 0.36, 0.3))
		draw_line(Vector2(-14, -6), Vector2(-4, 2), Color(0.06, 0.04, 0.03), 1.0)
		draw_line(Vector2(-4, 2), Vector2(3, 0), Color(0.06, 0.04, 0.03), 1.0)
	else:
		draw_circle(Vector2.ZERO, 19.0, Color(vi, 0.18 + 0.06 * sin(t * 2.0)))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * s)
	for sx in [-34.0, 34.0]:
		var base := Vector2(sx, 0)
		draw_colored_polygon(PackedVector2Array([base + Vector2(-5, 3), base + Vector2(5, 3), base + Vector2(3, -34), base + Vector2(-3, -34)]), Color(0.38, 0.27, 0.19))
		draw_line(base + Vector2(-5, 3), base + Vector2(-3, -34), Color(0.5, 0.36, 0.25), 1.0)
		draw_line(base + Vector2(5, 3), base + Vector2(3, -34), Color(0.22, 0.15, 0.11), 1.0)
		for gl in 3:
			draw_line(base + Vector2(-1.5, -8 - gl * 8), base + Vector2(1.5, -10 - gl * 8), vi if on else Color(0.3, 0.22, 0.3), 0.8)
		var cy := -42.0 + (sin(t * 1.8 + sx) * 1.5 if on else 0.0)
		var cr := PackedVector2Array([base + Vector2(0, cy - 7), base + Vector2(4, cy), base + Vector2(0, cy + 6), base + Vector2(-4, cy)])
		draw_colored_polygon(cr, Color(0.8, 0.6, 1.0) if on else Color(0.3, 0.26, 0.36))
		draw_line(base + Vector2(0, cy - 7), base + Vector2(0, cy + 6), Color(1, 1, 1, 0.6) if on else Color(0.45, 0.4, 0.5), 0.6)
		if on:
			draw_circle(base + Vector2(0, cy), 9.0, Color(vi, 0.18))
	if on:
		draw_rect(Rect2(-18, -70, 36, 70), Color(vi, 0.1 + 0.04 * sin(t * 2.5) + 0.15 * sink))
		draw_rect(Rect2(-12, -70, 24, 70), Color(0.85, 0.75, 1.0, 0.08))
		var pts := PackedVector2Array()
		for si in 13:
			pts.append(Vector2(-34.0 + si * (68.0 / 12.0), -42.0 + (sin(t * 23.0 + si * 1.7) * 3.0 if si > 0 and si < 12 else 0.0)))
		draw_polyline(pts, Color(0.85, 0.75, 1.0, 0.85), 0.8)
		for mo in 10:
			var ph := fposmod(t * 0.4 + mo * 0.1, 1.0)
			draw_circle(Vector2(hash_f(mo, 43) * 30.0 - 15.0, -ph * 64.0), 0.9, Color(0.9, 0.8, 1.0, 1.0 - ph))
	var cp := Vector2(0, 26)
	draw_rect(Rect2(cp.x - 5, cp.y - 10, 10, 10), Color(0.34, 0.25, 0.18))
	draw_rect(Rect2(cp.x - 6, cp.y - 12, 12, 3), Color(0.42, 0.31, 0.22))
	draw_circle(cp + Vector2(0, -10.5), 2.0, Color(0.3, 1.0, 0.6) if on else Color(1.0, 0.3, 0.25, 0.6 + 0.4 * sin(t * 3.0)))


## 0.7.53.9 (Luz): the reactor – a round pit, three rings over it, the core in the middle. Off: dark, still, red;
## starting (`start` 0..1): the rings turn faster, the core glows up, steam; running: bright, humming.
func _draw_reactor(d: Dictionary, t: float) -> void:
	var s := GroundMap.SCALE
	var k := float(d.get("start", 1.0 if String(d["state"]) == "on" else 0.0))
	var on := k > 0.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.56) * s)
	draw_circle(Vector2.ZERO, 54.0, Color(0.2, 0.2, 0.22))
	draw_circle(Vector2.ZERO, 50.0, Color(0.45, 0.46, 0.5))
	draw_circle(Vector2.ZERO, 44.0, Color(0.06, 0.06, 0.08))
	var spin := float(d.get("spin", 0.0))
	for ri in 3:
		var rr := 38.0 - ri * 10.0
		for a in 48:
			var ang := a * TAU / 48.0 + spin * (1.0 + ri * 0.6) * (1.0 if ri % 2 == 0 else -1.0)
			var col := Color(0.85, 0.7, 0.15) if a % 8 == 0 else Color(0.55, 0.57, 0.6)
			draw_circle(Vector2(cos(ang), sin(ang)) * rr, 1.3, col)
	if on:
		draw_circle(Vector2(0, -6), 13.0, Color(0.5, 0.9, 1.0, 0.35 + 0.65 * k))
		draw_circle(Vector2(0, -6), 8.0 * k + 2.0, Color(0.9, 1.0, 1.0, k))
	else:
		draw_circle(Vector2(0, -6), 13.0, Color(0.15, 0.18, 0.2))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * s)
	if on:
		for st in 12:
			var ph := fposmod(t * 0.6 + st * 0.083, 1.0)
			draw_circle(Vector2(sin(st * 2.3) * 12.0, -10.0 - ph * 60.0), 3.0 + ph * 4.0, Color(0.85, 0.95, 1.0, 0.25 * (1.0 - ph) * k))
		draw_rect(Rect2(-6, -80, 12, 74), Color(0.5, 0.9, 1.0, 0.1 * k))


## 0.7.53.2 (Luz): the relic's guardians – crystals floating round it, lightning leaping between them; off, they sink
## to the floor and go dark.
func _draw_crystals(d: Dictionary, t: float) -> void:
	var on := String(d["state"]) != "off"
	var n := 3
	var pts: Array = []
	for c in n:
		var ang := t * 0.6 + c * TAU / n
		var alt := 22.0 + sin(t * 2.0 + c) * 2.0 if on else 1.0
		pts.append(Vector2(cos(ang if on else c * TAU / n) * 20.0, sin(ang if on else c * TAU / n) * 9.0 - 8.0 - alt))
	if on:
		for c2 in n:
			var a: Vector2 = pts[c2]
			var b: Vector2 = pts[(c2 + 1) % n]
			var pl := PackedVector2Array([a])
			for s in range(1, 6):
				pl.append(a.lerp(b, s / 6.0) + Vector2(hash_f(int(t * 20.0) + s, c2) * 5.0 - 2.5, hash_f(int(t * 20.0) + s, c2 + 5) * 5.0 - 2.5))
			pl.append(b)
			draw_polyline(pl, Color(0.6, 0.85, 1.0, 0.35), 2.5)
			draw_polyline(pl, Color(0.9, 0.95, 1.0, 0.9), 0.8)
	for q in pts:
		var gnd: Vector2 = Vector2(q.x, q.y * 0.0 + (q.y + (22.0 if on else 1.0)) * 1.0)
		draw_set_transform(gnd * GroundMap.SCALE, 0.0, Vector2(1.0, 0.45) * GroundMap.SCALE)
		draw_circle(Vector2.ZERO, 3.0, Color(0, 0, 0, 0.3))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * GroundMap.SCALE)
		var cc := Color(0.45, 0.8, 1.0) if on else Color(0.25, 0.3, 0.38)
		draw_colored_polygon(PackedVector2Array([q + Vector2(0, -5), q + Vector2(3, 0), q + Vector2(0, 5), q + Vector2(-3, 0)]), cc)
		draw_colored_polygon(PackedVector2Array([q + Vector2(0, -5), q + Vector2(3, 0), q + Vector2(0, 0)]), cc.lightened(0.4))
		if on:
			draw_circle(q, 6.0, Color(0.5, 0.8, 1.0, 0.15))


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
		if d.has("door"):
			d["wall"] = true                       # 0.7.52.27 (Luz): a door's box hangs on the wall beside it
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
	if String(d["kind"]) == "valve" and String(d["state"]) == "turning":
		d["spin"] = float(d.get("spin", 0.0)) + delta * 4.0
	if String(d["kind"]) == "vent_end":
		# 0.7.52.28 (Luz): the hatch flips open when you come to it from inside the shaft
		var vi2 = d.get("vent")
		var vent_open: bool = vi2 == null or String(view.map.explore[int(vi2)]["state"]) != "shut"
		if vent_open and String(d["state"]) == "shut" and view.pilot.pos.distance_to((d["pos"] as Vector2) + Vector2(-8, -8)) < 22.0:
			d["state"] = "open"
			Audio.play("dock_clamp", "vent hatch flips open", -12.0)
		if String(d["state"]) == "open":
			d["open_k"] = minf(1.0, float(d.get("open_k", 0.0)) + delta / 0.45)
	if String(d["kind"]) == "reactor" and String(d["state"]) == "on":
		d["start"] = minf(1.0, float(d.get("start", 0.0)) + delta / 4.0)          # 0.7.53.9: it spins up
		d["spin"] = float(d.get("spin", 0.0)) + delta * (0.3 + 3.0 * float(d["start"]))
	if String(d["kind"]) in ["blastdoor", "rust_door", "ruin_gate", "grate_door", "steel_door", "bulkhead", "airlock", "crank_door"] and String(d["state"]) == "open":
		d["open_k"] = minf(1.0, float(d.get("open_k", 0.0)) + delta / 1.4)       # 0.7.52.23: it slides apart
	queue_redraw()


func _draw() -> void:
	var d: Dictionary = view.map.explore[i]
	var s := GroundMap.SCALE
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * s)
	var t := Time.get_ticks_msec() * 0.001
	var on_wall: bool = bool(d.get("wall", false)) or String(d["kind"]) in ["vent", "vent_end", "blastdoor", "rust_door", "ruin_gate", "crystals", "grate_door", "steel_door", "ladder", "valve",
		"manhole", "hatch", "tripwire", "ancient_lift", "turret", "alarm", "breach", "airlock", "bulkhead", "conduit", "gas", "deck_hole", "cage", "loose_rock", "tnt", "mine_gate", "rubble", "crank_door", "fuse_box", "reactor", "stairs_down", "stairs_up", "service_lift", "steam"]
	if not on_wall:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, 0.45) * s)
		draw_circle(Vector2(0, 2), 9.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * s)
	var kk := String(d["kind"])
	if kk == "panel" and on_wall:
		kk = "panel_rust" if String(d.get("style", "")) == "precursor" else "panel_wall"
	if kk == "terminal" and String(d.get("style", "")) == "precursor":
		kk = "terminal_precursor"
	if kk == "panel_wall" and String(d.get("style", "")) == "hideout":
		kk = "keypad"                                    # 0.7.53.3: the code lock beside the dealer's door
	if kk == "terminal" and String(d.get("style", "")) in ["pump", "dealer"]:
		kk = "terminal_" + String(d["style"])
	match kk:
		"ruin_gate":
			_draw_gate(d, t)
		"rust_door", "grate_door", "steel_door", "bulkhead", "crank_door":
			_draw_rust_door(d, t)
			if kk == "crank_door":
				# its hand crank beside it – turning while it is being cranked
				var cw := float(d.get("crank", 0.0))
				var cc := Vector2(float(d["tiles"][2]) * 8.0 + 9.0, -20.0)
				draw_arc(cc, 6.0, 0.0, TAU, 16, Color(0.75, 0.15, 0.1), 1.6)
				for sp in 4:
					var a7 := cw + sp * PI * 0.5
					draw_line(cc, cc + Vector2(cos(a7), sin(a7)) * 6.0, Color(0.75, 0.15, 0.1), 1.0)
		"reactor":
			_draw_reactor(d, t)
		"fuse_box":
			# 0.7.53.9: a fuse box on the wall – a row of fuses, one gap (until you put one in); its light
			draw_rect(Rect2(-9, -30, 18, 18), Color(0.1, 0.1, 0.1))
			draw_rect(Rect2(-8, -29, 16, 16), Color(0.36, 0.38, 0.36))
			draw_rect(Rect2(-6, -26, 12, 10), Color(0.08, 0.08, 0.09))
			for fu in 4:
				if fu != 2 or String(d["state"]) == "open":
					draw_rect(Rect2(-5 + fu * 3, -25, 2, 8), Color(0.8, 0.75, 0.6))
			draw_circle(Vector2(5, -14), 1.0, Color(0.3, 1.0, 0.45) if String(d["state"]) == "open" else Color(1.0, 0.2, 0.15))
		"stairs_down":
			# 0.7.53.9: an emergency stairwell going down – its railing, the steps falling away into the dark
			draw_rect(Rect2(-18, -12, 36, 24), Color(0.05, 0.05, 0.06))
			for stp in 5:
				draw_rect(Rect2(-16, -10 + stp * 4.5, 32, 2.5), Color(0.4, 0.41, 0.4).darkened(stp * 0.15))
			draw_rect(Rect2(-20, -14, 40, 2), Color(0.85, 0.7, 0.15))
			draw_rect(Rect2(-20, -14, 2, 26), Color(0.85, 0.7, 0.15))
			draw_rect(Rect2(18, -14, 2, 26), Color(0.85, 0.7, 0.15))
			draw_rect(Rect2(-8, -22, 16, 6), Color(0.15, 0.6, 0.3))
			draw_rect(Rect2(-6, -21, 3, 4), Color(0.9, 1.0, 0.9))
		"stairs_up":
			# 0.7.53.9: the stairwell door up – green exit sign over it
			draw_rect(Rect2(-12, -34, 24, 34), Color(0.22, 0.24, 0.22))
			draw_rect(Rect2(-10, -32, 20, 32), Color(0.38, 0.4, 0.38))
			draw_rect(Rect2(-10, -42, 20, 7), Color(0.15, 0.6, 0.3))
			draw_rect(Rect2(-8, -41, 3, 5), Color(0.9, 1.0, 0.9))
			draw_rect(Rect2(5, -18, 3, 2), Color(0.7, 0.7, 0.7))
		"service_lift":
			# 0.7.53.9: the service lift the city's lift brought you down in – its doors, a call panel
			draw_rect(Rect2(-16, -38, 32, 38), Color(0.18, 0.19, 0.21))
			draw_rect(Rect2(-14, -36, 13, 36), Color(0.45, 0.47, 0.5))
			draw_rect(Rect2(1, -36, 13, 36), Color(0.45, 0.47, 0.5))
			draw_rect(Rect2(-16, -42, 32, 4), Color(0.85, 0.7, 0.15))
			draw_rect(Rect2(18, -22, 5, 8), Color(0.12, 0.12, 0.14))
			draw_circle(Vector2(20.5, -18), 1.2, Color(0.3, 1.0, 0.45))
		"steam":
			# 0.7.53.9: a split pipe venting steam now and then (it scalds you when it bursts)
			draw_rect(Rect2(-10, -4, 20, 5), Color(0.42, 0.44, 0.46))
			draw_rect(Rect2(-2, -6, 4, 9), Color(0.3, 0.3, 0.32))
			var burst := fposmod(t + float(d.get("seed", 0) % 9), 4.0) < 1.2
			if burst:
				for sp3 in 14:
					var ph3 := fposmod(t * 2.0 + sp3 * 0.07, 1.0)
					draw_circle(Vector2(sin(sp3 * 1.9) * 6.0 * ph3, -6.0 - ph3 * 30.0), 3.0 + ph3 * 6.0, Color(0.9, 0.92, 0.95, 0.35 * (1.0 - ph3)))
		"breach":
			# 0.7.53.6 (Luz): a breach torn into the wreck's flank – plates bent outward, the dark inside, cables
			# hanging, sparks; shut: a buckled plate wedged across it (cut it)
			var pts := PackedVector2Array()
			for bi in 16:
				var ba := bi * TAU / 16.0
				pts.append(Vector2(cos(ba) * (18.0 + hash_f(bi, 61) * 7.0), -16.0 + sin(ba) * (12.0 + hash_f(bi, 62) * 4.0)))
			draw_colored_polygon(pts, Color(0.03, 0.03, 0.04))
			for bj in 16:
				var bo := (pts[bj] - Vector2(0, -16)).normalized()
				draw_line(pts[bj], pts[bj] + bo * 3.0, Color(0.62, 0.62, 0.64), 1.5)
			for cb in 4:
				var cx := -9.0 + cb * 6.0
				var cl := 10.0 + hash_f(cb, 63) * 8.0
				draw_line(Vector2(cx, -26), Vector2(cx + sin(t * 1.3 + cb) * 1.2, -26 + cl), [Color(0.8, 0.2, 0.15), Color(0.2, 0.4, 0.8), Color(0.85, 0.75, 0.2), Color(0.3, 0.3, 0.3)][cb], 0.8)
			if fposmod(t * 1.7, 2.3) < 0.25:
				for sp in 6:
					draw_circle(Vector2(8 + hash_f(sp, int(t * 10.0)) * 8, -22 + hash_f(int(t * 10.0), sp) * 10), 0.6, Color(1.0, 0.85, 0.4))
			if String(d["state"]) == "shut":
				draw_colored_polygon(PackedVector2Array([Vector2(-20, -24), Vector2(19, -30), Vector2(21, -6), Vector2(-18, -2)]), Color(0.45, 0.46, 0.5))
				draw_line(Vector2(-20, -24), Vector2(19, -30), Color(0.65, 0.66, 0.7), 1.0)
				draw_line(Vector2(-12, -14), Vector2(10, -18), Color(0.3, 0.3, 0.33), 0.8)
		"airlock":
			# 0.7.53.6: the emergency airlock in the hull – a hatch in a hazard frame, its light red until it opens
			var ok5 := float(d.get("open_k", 0.0))
			draw_rect(Rect2(-16, -36, 32, 36), Color(0.16, 0.16, 0.18))
			draw_rect(Rect2(-13, -33, 26, 33), Color(0.03, 0.03, 0.04))
			var lw := 13.0 * (1.0 - ok5)
			draw_rect(Rect2(-13, -33, lw, 33), Color(0.5, 0.52, 0.55))
			draw_rect(Rect2(13 - lw, -33, lw, 33), Color(0.5, 0.52, 0.55))
			for st in 7:
				draw_rect(Rect2(-16, -36 + st * 5, 3, 3), Color(0.95, 0.75, 0.1))
				draw_rect(Rect2(13, -36 + st * 5, 3, 3), Color(0.95, 0.75, 0.1))
			draw_rect(Rect2(-12, 0, 24, 3), Color(0.35, 0.35, 0.37))
			draw_circle(Vector2(0, -39), 1.6, Color(0.3, 1.0, 0.45) if String(d["state"]) == "open" else Color(1.0, 0.2, 0.15, 0.6 + 0.4 * sin(t * 3.0)))
		"blackbox":
			# 0.7.53.6: the flight recorder – an orange armoured box bolted into a rack, its beacon blinking
			if String(d["state"]) != "taken":
				draw_rect(Rect2(-10, -14, 20, 14), Color(0.25, 0.25, 0.27))
				draw_rect(Rect2(-7, -12, 14, 10), Color(0.95, 0.5, 0.12))
				draw_rect(Rect2(-7, -12, 14, 2), Color(1.0, 0.65, 0.25))
				draw_rect(Rect2(-5, -8, 10, 1), Color(0.2, 0.2, 0.2))
				draw_circle(Vector2(5, -10), 1.0, Color(1.0, 1.0, 0.6) if fposmod(t, 1.0) < 0.5 else Color(0.5, 0.4, 0.1))
			else:
				draw_rect(Rect2(-10, -14, 20, 14), Color(0.25, 0.25, 0.27))
				draw_rect(Rect2(-7, -12, 14, 10), Color(0.05, 0.05, 0.06))
		"generator":
			# 0.7.53.6: the emergency generator – a cabinet with three breakers and the bus it feeds
			var to := String(d.get("route", "lights"))
			draw_rect(Rect2(-12, -26, 24, 26), Color(0.1, 0.1, 0.1))
			draw_rect(Rect2(-11, -25, 22, 25), Color(0.32, 0.34, 0.32))
			draw_rect(Rect2(-11, -25, 22, 2), Color(0.45, 0.48, 0.45))
			for sw in 3:
				var on6 := (sw == 0 and to == "doors") or (sw == 1 and to == "lights")
				draw_rect(Rect2(-8 + sw * 6, -20, 4, 8), Color(0.3, 1.0, 0.4) if on6 else Color(1.0, 0.25, 0.2))
			draw_rect(Rect2(-8, -9, 16, 2), Color(1.0, 0.75, 0.2, 0.6 + 0.3 * sin(t * 6.0)))
		"conduit":
			# 0.7.53.6: an open conduit across the floor – live, sparking now and then (a shock if you step on it)
			draw_rect(Rect2(-8, -2, 16, 4), Color(0.12, 0.12, 0.13))
			draw_line(Vector2(-8, 0), Vector2(8, 0), Color(0.6, 0.6, 0.62), 0.8)
			if fposmod(t * 2.1 + float(d.get("seed", 0) % 7), 1.6) < 0.35:
				for sp2 in 5:
					draw_line(Vector2(-4 + sp2 * 2, 0), Vector2(-6 + sp2 * 3 + hash_f(sp2, int(t * 20.0)) * 4, -4 - hash_f(int(t * 20.0), sp2) * 6), Color(0.6, 0.85, 1.0), 0.6)
				draw_circle(Vector2.ZERO, 5.0, Color(0.5, 0.8, 1.0, 0.25))
		"gas":
			# 0.7.53.6: a gas leak – a green haze welling up from a split pipe
			var r6 := float(d.get("r", 30.0))
			for gp in 18:
				var ga := hash_f(gp, 71) * TAU + t * 0.2
				var gr := r6 * sqrt(hash_f(gp, 72)) * (0.8 + 0.2 * sin(t + gp))
				draw_circle(Vector2(cos(ga) * gr, sin(ga) * gr * 0.6 - 4.0), 6.0 + hash_f(gp, 73) * 5.0, Color(0.5, 0.9, 0.3, 0.09))
		"deck_hole":
			# 0.7.53.6: the deck gave way – a hole into the deck below, torn plates round it, a rope ladder hanging down
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.6) * GroundMap.SCALE)
			draw_circle(Vector2.ZERO, 22.0, Color(0.02, 0.02, 0.03))
			for e in 14:
				var ea := e * TAU / 14.0
				draw_line(Vector2(cos(ea), sin(ea)) * 21.0, Vector2(cos(ea), sin(ea)) * (25.0 + hash_f(e, 74) * 4.0), Color(0.55, 0.56, 0.6), 2.0)
			draw_circle(Vector2.ZERO, 14.0, Color(1.0, 0.4, 0.2, 0.12 + 0.04 * sin(t * 2.0)))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * GroundMap.SCALE)
			for rg in 4:
				draw_rect(Rect2(-5, -6 + rg * 3.5, 10, 1), Color(0.6, 0.5, 0.35))
			draw_line(Vector2(-5, -8), Vector2(-5, 6), Color(0.55, 0.45, 0.3), 0.8)
			draw_line(Vector2(5, -8), Vector2(5, 6), Color(0.55, 0.45, 0.3), 0.8)
		"ancient_lift":
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			_draw_ancient_lift(d, t)
		"cage":
			# 0.7.53.7 (Luz): the cage in its shaft – a steel cage on its rope, a gate in front; without power its lamp
			# is dark and red; riding it, it sinks
			var on7 := String(d["state"]) != "dormant"
			var sk7 := float(d.get("sink", 0.0))
			draw_rect(Rect2(-22, -40, 44, 44), Color(0.03, 0.03, 0.04))
			draw_rect(Rect2(-24, -42, 4, 46), Color(0.4, 0.3, 0.18))
			draw_rect(Rect2(20, -42, 4, 46), Color(0.4, 0.3, 0.18))
			draw_rect(Rect2(-24, -44, 48, 4), Color(0.45, 0.33, 0.2))
			var cy := 14.0 * sk7
			draw_rect(Rect2(-18, -36 + cy, 36, 38), Color(0.12, 0.12, 0.13))
			for bx in range(-17, 18, 4):
				draw_line(Vector2(bx, -36 + cy), Vector2(bx, 2 + cy), Color(0.48, 0.48, 0.5), 0.8)
			draw_rect(Rect2(-18, -36 + cy, 36, 2), Color(0.55, 0.55, 0.58))
			draw_rect(Rect2(-18, -16 + cy, 36, 1.5), Color(0.55, 0.55, 0.58))
			draw_line(Vector2(0, -44), Vector2(0, -36 + cy), Color(0.15, 0.15, 0.15), 1.0)
			draw_circle(Vector2(18, -46), 2.0, Color(0.3, 1.0, 0.45) if on7 else Color(1.0, 0.25, 0.2, 0.5 + 0.3 * sin(t * 2.0)))
		"mine_gen":
			# 0.7.53.7: an old generator on skids – a fuel tank, a pull cord; running, it shakes and puffs
			var run := String(d["state"]) == "open"
			var jig := sin(t * 40.0) * 0.6 if run else 0.0
			draw_rect(Rect2(-12 + jig, -14, 24, 14), Color(0.55, 0.45, 0.15))
			draw_rect(Rect2(-12 + jig, -14, 24, 2), Color(0.7, 0.6, 0.25))
			draw_rect(Rect2(-9 + jig, -20, 10, 6), Color(0.6, 0.15, 0.12))
			draw_circle(Vector2(7 + jig, -8), 3.0, Color(0.15, 0.15, 0.15))
			draw_rect(Rect2(-14, -1, 28, 2), Color(0.3, 0.3, 0.32))
			draw_circle(Vector2(-6, -17), 1.2, Color(0.3, 1.0, 0.45) if run else Color(1.0, 0.25, 0.2))
			if run:
				var ph7 := fposmod(t * 1.2, 1.0)
				draw_circle(Vector2(10, -16 - ph7 * 14), 2.0 + ph7 * 3.0, Color(0.4, 0.4, 0.4, 0.4 * (1.0 - ph7)))
		"vein":
			# 0.7.53.7 (Luz): the rare find – crystals and a glitter in a block of rock (cut out: an empty socket)
			draw_colored_polygon(PackedVector2Array([Vector2(-14, 0), Vector2(-10, -14), Vector2(2, -18), Vector2(13, -12), Vector2(14, 0)]), Color(0.3, 0.26, 0.22))
			if String(d["state"]) != "taken":
				for cr in 5:
					var cx7 := -8.0 + cr * 4.0
					draw_colored_polygon(PackedVector2Array([Vector2(cx7, -4), Vector2(cx7 + 2, -12 - cr % 2 * 3), Vector2(cx7 + 4, -4)]), Color(0.85, 0.9, 1.0, 0.9))
				draw_circle(Vector2(sin(t * 2.0) * 5.0, -10), 1.2 + sin(t * 5.0) * 0.6, Color(1.0, 1.0, 0.8))
			else:
				draw_rect(Rect2(-8, -10, 16, 6), Color(0.08, 0.07, 0.06))
		"rubble":
			# 0.7.53.7: a fall of rock across the drift – boulders and timber; a charge set: its light blinks
			if String(d["state"]) != "open":
				for rb in 14:
					var rp := Vector2(-14 + hash_f(rb, 81) * 28, -30 + hash_f(rb, 82) * 30)
					draw_circle(rp, 4.0 + hash_f(rb, 83) * 4.0, Color(0.38, 0.32, 0.27).lerp(Color(0.25, 0.21, 0.18), hash_f(rb, 84)))
				draw_line(Vector2(-12, -26), Vector2(10, -8), Color(0.42, 0.3, 0.17), 2.0)
				if String(d["state"]) == "charged":
					draw_circle(Vector2(0, -6), 2.0, Color(1.0, 0.2, 0.15) if fposmod(t * 4.0, 1.0) < 0.5 else Color(0.4, 0.1, 0.1))
		"loose_rock":
			# 0.7.53.7: loose rock in the roof – cracks, dust trickling; falling: dust, stones; fallen: a heap
			var st7 := String(d["state"])
			if st7 == "shut":
				if fposmod(t * 0.7 + float(d.get("seed", 0) % 5), 2.0) < 0.6:
					for dd7 in 4:
						draw_circle(Vector2(-4 + dd7 * 3, -30 + fposmod(t * 30.0 + dd7 * 7.0, 26.0)), 0.6, Color(0.6, 0.55, 0.5, 0.7))
			elif st7 == "falling":
				for fs in 8:
					draw_circle(Vector2(-10 + hash_f(fs, 85) * 20, -40 + fposmod(t * 200.0 + fs * 9.0, 40.0)), 2.5, Color(0.42, 0.36, 0.3))
				draw_circle(Vector2.ZERO, 16.0, Color(0.6, 0.55, 0.5, 0.25))
			else:
				for hp in 9:
					draw_circle(Vector2(-10 + hash_f(hp, 86) * 20, -3 + hash_f(hp, 87) * 5), 2.5 + hash_f(hp, 88) * 2.0, Color(0.4, 0.34, 0.28))
		"tnt":
			# 0.7.53.7 (Luz): a box of explosives – red, stencilled; it goes up when something blows up close by
			if String(d["state"]) == "shut":
				draw_rect(Rect2(-9, -12, 18, 12), Color(0.6, 0.12, 0.1))
				draw_rect(Rect2(-9, -12, 18, 3), Color(0.75, 0.2, 0.15))
				draw_rect(Rect2(-6, -7, 12, 3), Color(0.95, 0.9, 0.8))
				draw_rect(Rect2(-4, -6, 2, 1), Color(0.6, 0.12, 0.1))
				draw_rect(Rect2(0, -6, 3, 1), Color(0.6, 0.12, 0.1))
			else:
				draw_rect(Rect2(-9, -3, 18, 3), Color(0.1, 0.08, 0.08))
		"mine_gate":
			# 0.7.53.7: the gate into the shaft – rusted bars, a chain and padlock; cut: it hangs open
			draw_rect(Rect2(-18, -34, 36, 34), Color(0.02, 0.02, 0.03))
			if String(d["state"]) != "open":
				for bx2 in range(-17, 18, 4):
					draw_rect(Rect2(bx2, -34, 1.5, 34), Color(0.5, 0.38, 0.25))
				draw_rect(Rect2(-18, -22, 36, 2), Color(0.45, 0.33, 0.22))
				for ch in 8:
					draw_circle(Vector2(-7 + ch * 2, -19 + (ch % 2)), 0.8, Color(0.62, 0.62, 0.64))
				draw_rect(Rect2(-3, -18, 6, 5), Color(0.75, 0.62, 0.2))
			else:
				for bx3 in range(0, 18, 4):
					draw_line(Vector2(-18, -34 + bx3 * 0.2), Vector2(-26, -30 + bx3 * 1.8), Color(0.5, 0.38, 0.25), 1.2)
			draw_rect(Rect2(-20, -36, 40, 3), Color(0.4, 0.3, 0.2))
		"crystals":
			_draw_crystals(d, t)
		"panel_rust":
			# 0.7.53.2 (Luz): a Precursor panel on the wall – rusted, a corroded flap, a faint glow behind it
			draw_rect(Rect2(-9, -29, 18, 20), Color(0.1, 0.07, 0.06))
			draw_rect(Rect2(-8, -28, 16, 18), Color(0.4, 0.28, 0.2))
			draw_rect(Rect2(-8, -28, 16, 1), Color(0.55, 0.4, 0.3))
			for rs in 7:
				draw_rect(Rect2(-7 + hash_f(rs, 3) * 13, -27 + hash_f(rs, 4) * 15, 1.5, 1.2), Color(0.55, 0.28, 0.12))
			if String(d["state"]) == "shut":
				draw_rect(Rect2(-5, -25, 10, 10), Color(0.48, 0.34, 0.24))
				draw_rect(Rect2(-5, -25, 10, 10), Color(0.9, 0.75, 0.5, 0.5), false, 0.5)
			else:
				draw_rect(Rect2(-5, -25, 10, 10), Color(0.04, 0.03, 0.03))
				draw_circle(Vector2(0, -20), 2.5, Color(0.6, 0.45, 1.0) if not bool(d.get("trap", false)) else Color(0.45, 0.9, 1.0))
			draw_circle(Vector2(6, -26), 1.0, Color(0.7, 0.5, 1.0, 0.4 + 0.4 * sin(t * 2.0)))
		"terminal_precursor":
			# 0.7.53.2 (Luz): their computer – a curved stem out of a ring, a pane of glyphs hanging in the air over it
			draw_set_transform(Vector2(0, 0) * GroundMap.SCALE, 0.0, Vector2(1.0, 0.45) * GroundMap.SCALE)
			draw_arc(Vector2.ZERO, 7.0, 0.0, TAU, 20, Color(0.4, 0.3, 0.24), 2.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * GroundMap.SCALE)
			draw_colored_polygon(PackedVector2Array([Vector2(-2, 0), Vector2(-4, -9), Vector2(-1, -17), Vector2(3, -20), Vector2(1, -16), Vector2(-1, -9), Vector2(2, 0)]), Color(0.38, 0.27, 0.2))
			var hov := sin(t * 1.5) * 1.0
			var on2 := String(d["state"]) != "hacked"
			var pane := PackedVector2Array([Vector2(-8, -33 + hov), Vector2(7, -35 + hov), Vector2(9, -25 + hov), Vector2(-6, -23 + hov)])
			draw_colored_polygon(pane, Color(0.2, 0.75, 0.7, 0.35) if on2 else Color(0.5, 0.4, 0.9, 0.35))
			var pl := pane.duplicate()
			pl.append(pl[0])
			draw_polyline(pl, Color(0.4, 1.0, 0.9, 0.8) if on2 else Color(0.7, 0.55, 1.0, 0.8), 0.8)
			for gi in 3:
				draw_line(Vector2(-5 + gi, -30 + gi * 2.5 + hov), Vector2(3 + gi, -31 + gi * 2.5 + hov), Color(0.6, 1.0, 0.95, 0.8), 0.6)
		"panel_wall":
			# 0.7.52.27 (Luz): the box mounted on the wall beside a blast door – flush, its conduit running up
			draw_rect(Rect2(-1.5, -40, 3, 12), Color(0.2, 0.21, 0.24))
			draw_rect(Rect2(-9, -29, 18, 20), Color(0.1, 0.11, 0.13))
			draw_rect(Rect2(-8, -28, 16, 18), Color(0.38, 0.4, 0.44))
			draw_rect(Rect2(-8, -28, 16, 1), Color(0.55, 0.57, 0.6))
			draw_rect(Rect2(-8, -11, 16, 1), Color(0.2, 0.21, 0.24))
			draw_rect(Rect2(-7, -13, 14, 2), Color(0.95, 0.78, 0.15))
			if String(d["state"]) == "shut":
				draw_rect(Rect2(-5, -25, 10, 10), Color(0.46, 0.48, 0.52))
				draw_rect(Rect2(-5, -25, 10, 10), Color(0.95, 0.9, 0.55, 0.6), false, 0.5)
			else:
				draw_rect(Rect2(-5, -25, 10, 10), Color(0.05, 0.05, 0.06))
				draw_circle(Vector2(0, -20), 2.5, Color(0.2, 0.9, 0.35) if String(d["inside"]) == "button" else Color(0.2, 0.9, 1.0))
			draw_circle(Vector2(6, -26), 1.0, Color(1.0, 0.25, 0.2) if fposmod(t, 1.2) < 0.9 else Color(0.3, 0.1, 0.1))
		"vent":
			# 0.7.52.27 (Luz): a ventilation shaft's grille in the wall – welded shut, or cut open into the dark duct
			# (0.7.52.28: low, flush with the floor)
			draw_rect(Rect2(-9, -15, 18, 15), Color(0.12, 0.13, 0.15))
			if String(d["state"]) == "shut":
				draw_rect(Rect2(-8, -14, 16, 14), Color(0.42, 0.44, 0.48))
				for sl in 5:
					draw_rect(Rect2(-7, -12.5 + sl * 2.6, 14, 1.4), Color(0.18, 0.19, 0.22))
					draw_rect(Rect2(-7, -11.8 + sl * 2.6, 14, 0.6), Color(0.6, 0.62, 0.66))
				for bx in [-7.0, 7.0]:
					for by in [-13.0, -1.5]:
						draw_circle(Vector2(bx, by), 0.7, Color(0.7, 0.72, 0.75))
			else:
				draw_rect(Rect2(-8, -14, 16, 14), Color(0.03, 0.03, 0.04))
				draw_rect(Rect2(-6, -12, 12, 12), Color(0.06, 0.06, 0.07))
				draw_rect(Rect2(-4, -10, 8, 10), Color(0.02, 0.02, 0.03))
				draw_rect(Rect2(-8, -14, 16, 14), Color(1.0, 0.5, 0.2, 0.35), false, 0.6)
			draw_string(ThemeDB.fallback_font, Vector2(-9, -17), "VENT", HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color(0.9, 0.85, 0.5, 0.8))
		"turret":
			# 0.7.53.5 (Luz): a turret on the wall – a housing on a bracket, twin barrels following you, a red eye
			var on4 := String(d["state"]) == "on"
			draw_rect(Rect2(-2, -40, 4, 10), Color(0.15, 0.15, 0.16))
			draw_rect(Rect2(-9, -32, 18, 11), Color(0.2, 0.2, 0.22))
			draw_rect(Rect2(-9, -32, 18, 2), Color(0.38, 0.38, 0.4))
			var ang4 := float(d.get("ang", PI * 0.5))
			var dir4 := Vector2(cos(ang4), sin(ang4) * 0.6)
			for bo in [-1.5, 1.5]:
				var b0: Vector2 = Vector2(0, -26) + dir4.orthogonal() * bo
				draw_line(b0, b0 + dir4 * 11.0, Color(0.1, 0.1, 0.11), 1.6)
			if float(d.get("flash", 0.0)) > 0.0:
				draw_circle(Vector2(0, -26) + dir4 * 13.0, 2.5, Color(1.0, 0.85, 0.4))
			draw_circle(Vector2(4, -29), 1.4, (Color(1.0, 0.2, 0.15) if fposmod(t, 0.8) < 0.6 else Color(0.5, 0.1, 0.1)) if on4 else Color(0.25, 0.25, 0.25))
		"alarm":
			# 0.7.53.5: an alarm box – a red housing, a siren lamp on top; ringing, the lamp spins red light
			var st5 := String(d["state"])
			draw_rect(Rect2(-6, -30, 12, 14), Color(0.08, 0.08, 0.09))
			draw_rect(Rect2(-5, -29, 10, 12), Color(0.6, 0.12, 0.1) if st5 != "cut" else Color(0.3, 0.12, 0.1))
			draw_rect(Rect2(-3, -26, 6, 3), Color(0.9, 0.85, 0.75))
			draw_rect(Rect2(-3, -36, 6, 6), Color(0.5, 0.1, 0.08))
			if st5 == "ringing":
				var sp5 := t * 8.0
				draw_circle(Vector2(0, -33), 4.0, Color(1.0, 0.2, 0.15))
				draw_line(Vector2(0, -33), Vector2(0, -33) + Vector2(cos(sp5), sin(sp5) * 0.5) * 30.0, Color(1.0, 0.25, 0.2, 0.5), 3.0)
			elif st5 == "cut":
				for wi5 in 3:
					draw_line(Vector2(-3 + wi5 * 3, -17), Vector2(-4 + wi5 * 3, -12), [Color(1, 0.3, 0.2), Color(0.3, 0.6, 1), Color(1, 0.85, 0.2)][wi5], 0.6)
			else:
				draw_circle(Vector2(0, -33), 1.2, Color(1.0, 0.3, 0.2, 0.5 + 0.3 * sin(t * 2.0)))
		"keypad":
			# 0.7.53.3: a code lock on the wall – a keypad, a red light (cut it open: the wires behind it)
			draw_rect(Rect2(-6, -30, 12, 18), Color(0.08, 0.08, 0.09))
			draw_rect(Rect2(-5, -29, 10, 16), Color(0.2, 0.21, 0.23))
			if String(d["state"]) == "shut":
				for kb in 9:
					draw_rect(Rect2(-4 + (kb % 3) * 3, -26 + (kb / 3) * 3, 2, 2), Color(0.5, 0.8, 1.0, 0.8))
				draw_rect(Rect2(-4, -16, 8, 1.5), Color(1.0, 0.25, 0.2) if fposmod(t, 1.0) < 0.7 else Color(0.4, 0.1, 0.1))
			else:
				draw_rect(Rect2(-4, -27, 8, 10), Color(0.04, 0.04, 0.05))
				for wi in 3:
					draw_line(Vector2(-3 + wi * 3, -27), Vector2(-2 + wi * 2, -18), [Color(1, 0.3, 0.2), Color(0.3, 0.6, 1), Color(1, 0.85, 0.2)][wi], 0.6)
				draw_rect(Rect2(-4, -16, 8, 1.5), Color(0.3, 1.0, 0.45))
		"terminal_pump":
			# 0.7.53.3: the pump control – an old grey cabinet, a green screen, the level gauge
			draw_rect(Rect2(-9, -26, 18, 26), Color(0.1, 0.11, 0.1))
			draw_rect(Rect2(-8, -25, 16, 25), Color(0.32, 0.35, 0.32))
			draw_rect(Rect2(-8, -25, 16, 1), Color(0.48, 0.52, 0.47))
			draw_rect(Rect2(-6, -22, 12, 8), Color(0.04, 0.09, 0.05))
			var on3 := String(d["state"]) != "hacked"
			for ln in 3:
				draw_rect(Rect2(-5, -21 + ln * 2.5, 4 + ln * 2, 0.8), Color(0.4, 1.0, 0.5) if on3 else Color(1.0, 0.75, 0.3))
			draw_rect(Rect2(-6, -11, 3, 9), Color(0.1, 0.1, 0.1))
			var lvl := 0.2 if bool(d.get("drained", false)) else 0.85
			draw_rect(Rect2(-5.5, -2.5 - 8 * lvl, 2, 8 * lvl), Color(0.3, 0.7, 0.9))
			for bt in 3:
				draw_circle(Vector2(1 + bt * 3, -7), 1.0, [Color(1, 0.3, 0.2), Color(1, 0.8, 0.2), Color(0.3, 1, 0.4)][bt])
		"terminal_dealer":
			# 0.7.53.3: the dealer's computer on the desk – two screens, the list scrolling
			draw_rect(Rect2(-14, -10, 28, 10), Color(0.32, 0.22, 0.14))
			draw_rect(Rect2(-14, -10, 28, 2), Color(0.45, 0.32, 0.2))
			for sc in 2:
				var sx2 := -12 + sc * 13
				draw_rect(Rect2(sx2, -23, 11, 12), Color(0.08, 0.08, 0.09))
				draw_rect(Rect2(sx2 + 1, -22, 9, 9), Color(0.3, 0.6, 0.95, 0.85) if String(d["state"]) != "hacked" else Color(0.3, 0.9, 0.5, 0.85))
				for ln2 in 3:
					draw_rect(Rect2(sx2 + 2, -21 + ln2 * 2.6 + fposmod(t * 2.0, 2.6) * float(sc), 6 - ln2, 0.7), Color(0.9, 0.95, 1.0))
		"ladder":
			# 0.7.53.3: iron rungs up the wall, light falling down the shaft above
			draw_rect(Rect2(-8, -40, 16, 40), Color(0.02, 0.02, 0.03, 0.6))
			draw_rect(Rect2(-7, -40, 2, 40), Color(0.5, 0.45, 0.38))
			draw_rect(Rect2(5, -40, 2, 40), Color(0.5, 0.45, 0.38))
			for rg in 8:
				draw_rect(Rect2(-6, -38 + rg * 5, 12, 1.5), Color(0.58, 0.52, 0.42))
		"manhole":
			# 0.7.53.3: an open manhole in the alley – the cover pushed aside, the ladder's top, steam rising
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, 0.62) * GroundMap.SCALE)
			draw_circle(Vector2.ZERO, 11.0, Color(0.32, 0.32, 0.34))
			draw_circle(Vector2.ZERO, 9.0, Color(0.01, 0.01, 0.02))
			draw_circle(Vector2(17, 6), 10.0, Color(0.36, 0.35, 0.34))
			draw_circle(Vector2(17, 6), 8.5, Color(0.27, 0.26, 0.26))
			for gl in 4:
				draw_rect(Rect2(10, 1.5 + gl * 3, 14, 1), Color(0.42, 0.41, 0.4))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * GroundMap.SCALE)
			for rr in 3:
				draw_rect(Rect2(-4, -3 + rr * 2.5, 8, 1), Color(0.45, 0.42, 0.35))
			for st in 6:
				var ph := fposmod(t * 0.5 + st * 0.17, 1.0)
				draw_circle(Vector2(sin(st * 2.1 + t) * 4.0, -4 - ph * 26.0), 3.0 + ph * 5.0, Color(0.85, 0.9, 0.9, 0.18 * (1.0 - ph)))
		"hatch":
			# 0.7.53.3: a hatch in the floor, its lid up – a ladder down into a warm light
			draw_rect(Rect2(-10, -8, 20, 14), Color(0.25, 0.26, 0.28))
			draw_rect(Rect2(-8, -6, 16, 10), Color(0.08, 0.05, 0.03))
			draw_rect(Rect2(-8, -6, 16, 10), Color(1.0, 0.65, 0.3, 0.25 + 0.05 * sin(t * 3.0)))
			for hr in 3:
				draw_rect(Rect2(-5, -5 + hr * 3, 10, 1), Color(0.55, 0.5, 0.42))
			draw_rect(Rect2(-10, -18, 20, 10), Color(0.36, 0.37, 0.4))
			draw_rect(Rect2(-10, -18, 20, 1), Color(0.55, 0.56, 0.6))
			draw_rect(Rect2(-7, -15, 14, 1), Color(0.85, 0.7, 0.15))
		"valve":
			# 0.7.53.3: a red valve wheel on a pipe in the wall
			draw_rect(Rect2(-14, -22, 28, 4), Color(0.36, 0.3, 0.24))
			draw_rect(Rect2(-14, -22, 28, 1), Color(0.5, 0.42, 0.33))
			var ang := float(d.get("spin", 0.0))
			var col2 := Color(0.75, 0.15, 0.12) if String(d["state"]) != "open" else Color(0.35, 0.6, 0.3)
			draw_arc(Vector2(0, -20), 7.0, 0.0, TAU, 20, col2, 1.6)
			for sp in 4:
				var a2 := ang + sp * PI * 0.5
				draw_line(Vector2(0, -20), Vector2(0, -20) + Vector2(cos(a2), sin(a2)) * 7.0, col2, 1.0)
			draw_circle(Vector2(0, -20), 1.6, Color(0.85, 0.75, 0.3))
		"tripwire":
			# 0.7.53.3: a thin wire across the way at shin height, a grenade taped to the wall at its end
			if String(d["state"]) == "shut":
				var ln3 := float(d.get("len", 3)) * 16.0
				var v3 := bool(d.get("vertical", true))
				var e3 := Vector2(0, ln3) if v3 else Vector2(ln3, 0)
				draw_line(Vector2(0, -3), e3 + Vector2(0, -3), Color(0.9, 0.9, 0.8, 0.55 + 0.25 * sin(t * 5.0)), 0.5)
				draw_rect(Rect2(-2, -9, 4, 6), Color(0.3, 0.38, 0.22))
				draw_circle(Vector2(0, -8), 0.8, Color(1.0, 0.2, 0.15))
		"crate":
			# package 53a: a supply cache – a heavy chest with straps; welded ones show their seams; open: lid up, empty
			var cc := Color(0.45, 0.4, 0.3) if not bool(d.get("welded", false)) else Color(0.38, 0.4, 0.44)
			if bool(d.get("safe", false)):
				cc = Color(0.24, 0.25, 0.27)                 # 0.7.53.3: the dealer's safe
			draw_rect(Rect2(-9, -12, 18, 12), Color(0.08, 0.08, 0.09))
			draw_rect(Rect2(-8, -11, 16, 11), cc)
			draw_rect(Rect2(-8, -11, 16, 1), cc.lightened(0.25))
			draw_rect(Rect2(-5, -11, 2, 11), cc.darkened(0.3))
			draw_rect(Rect2(3, -11, 2, 11), cc.darkened(0.3))
			if String(d["state"]) == "shut":
				draw_rect(Rect2(-8, -15, 16, 4), cc.lightened(0.1))
				if bool(d.get("welded", false)):
					draw_line(Vector2(-8, -11), Vector2(8, -11), Color(1.0, 0.75, 0.35, 0.8), 0.8)
				draw_rect(Rect2(-1.5, -10, 3, 3), Color(0.85, 0.75, 0.3))
			else:
				draw_rect(Rect2(-8, -22, 16, 8), cc.darkened(0.15))
				draw_rect(Rect2(-7, -10, 14, 3), Color(0.04, 0.04, 0.05))
		"vent_end":
			# the shaft's other mouth: a hatch over its last stretch – unseen until the shaft is open; it flips open
			# onto the floor as you come out (0.7.52.28)
			var vi = d.get("vent")
			if vi != null and String(view.map.explore[int(vi)]["state"]) == "shut":
				pass
			else:
				var ok2 := float(d.get("open_k", 0.0))
				var wv := 16.0 * cos(ok2 * PI)
				if wv > 0.0:
					draw_rect(Rect2(-wv, -16, wv, 16), Color(0.4, 0.42, 0.46))
					for sl2 in 4:
						draw_rect(Rect2(-wv + wv * (0.15 + sl2 * 0.2), -14, maxf(0.6, wv * 0.08), 12), Color(0.2, 0.21, 0.24))
					draw_rect(Rect2(-wv, -16, wv, 16), Color(0.15, 0.16, 0.18), false, 0.6)
				else:
					draw_rect(Rect2(0, -16, -wv, 16), Color(0.28, 0.29, 0.32))
					draw_rect(Rect2(0, -16, -wv, 16), Color(0.12, 0.13, 0.15), false, 0.6)
					draw_rect(Rect2(0, -9, -wv * 0.3, 2), Color(0.5, 0.52, 0.56))
				draw_rect(Rect2(-1, -16, 1.5, 16), Color(0.55, 0.57, 0.6))           # the hinge
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
