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
	"fuse_box": "A fuse box – a fuse is missing. Put in a spare (E)",
	"pirate_gate": "The hangar gate – sealed (its terminal beside it)",
	"keycard": "A key card – take it (E)",
	"seal_panel": "Emergency bulkhead – seal the torn module (E)",
	"symbol_pillar": "Symbol stones – touch the symbols in their order (E)",
	"cracked_wall": "A cracked wall – it sounds hollow (a cutting torch gets through)",
	"monolith": "A monolith – scan it (scanner on your belt)",
	"membrane": "A membrane of living stone – sealed (the symbol stones beside it)",
	"vault_door": "The vault door – its lock wants a hack, then the drill (the terminal beside it)",
	"service_door": "The back door – locked (its keypad or the terminal)"}
const INSCRIPTIONS := [
	"\"…the ninth gate was sealed when the sky went quiet. Those who stayed kept the lamps lit…\"",
	"\"Here the builders counted the years by the turning of the red star – four hundred and twelve.\"",
	"\"Water below, under the third pillar. Take only what you carry.\"",
	"\"We were many. We went down into the warm dark and did not come up.\"",
	"\"The engine sleeps beneath. Wake it with the song of the three keys.\"",
]

const CAM_REACH := 120.0                    # 0.7.53.19: how far a security camera sees (art px)
const CAM_HALF := 0.42                      # half its view's angle
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
	if String(d.get("style", "")) == "darkones":
		# 0.7.53.23 (Luz): the Dark Ones' way in – a maw, two lips of stone; inside a violet glow; open, the lips part
		var k0 := float(d.get("open_k", 0.0))
		draw_circle(Vector2(0, -gh * 0.55), gw * 0.65, Color(0.03, 0.02, 0.04))
		draw_circle(Vector2(0, -gh * 0.55), gw * 0.4, Color(0.62, 0.35, 1.0, 0.2 + 0.25 * k0 + 0.1 * sin(t * 1.5)))
		for lp in 2:
			var sg := -1.0 if lp == 0 else 1.0
			for st in 12:
				var off := (gw * 0.55 + k0 * 10.0) * sg
				draw_rect(Rect2(off - 3.0 + sg * st * 0.4 - 3.0 * (1 - lp), -gh + st * (gh / 12.0), 6, gh / 12.0 + 1), Color(0.16, 0.14, 0.2))
		if k0 < 0.99:
			draw_rect(Rect2(-gw * 0.5 * (1.0 - k0), -gh, gw * (1.0 - k0), gh), Color(0.1, 0.08, 0.13, 0.85))
		return
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
	if String(d["kind"]) == "searchlight":
		d["ang"] = float(d.get("ang", 0.0)) + delta * 0.6                       # 0.7.53.11: it sweeps
	if String(d["kind"]) == "reactor" and String(d["state"]) == "on":
		d["start"] = minf(1.0, float(d.get("start", 0.0)) + delta / 4.0)          # 0.7.53.9: it spins up
		d["spin"] = float(d.get("spin", 0.0)) + delta * (0.3 + 3.0 * float(d["start"]))
	if String(d["kind"]) == "camera" and String(d["state"]) == "on":
		d["ang"] = float(d.get("base", PI * 0.5)) + sin(Time.get_ticks_msec() * 0.0006 + float(int(d.get("seed", 0)) % 7)) * 0.7     # 0.7.53.19: it sweeps
	if String(d["kind"]) in ["blastdoor", "rust_door", "ruin_gate", "grate_door", "steel_door", "bulkhead", "airlock", "crank_door", "pirate_gate", "vault_door", "service_door", "membrane"] and String(d["state"]) == "open":
		d["open_k"] = minf(1.0, float(d.get("open_k", 0.0)) + delta / 1.4)       # 0.7.52.23: it slides apart
	queue_redraw()


func _draw() -> void:
	var d: Dictionary = view.map.explore[i]
	var s := GroundMap.SCALE
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * s)
	var t := Time.get_ticks_msec() * 0.001
	var on_wall: bool = bool(d.get("wall", false)) or String(d["kind"]) in ["vent", "vent_end", "blastdoor", "rust_door", "ruin_gate", "crystals", "grate_door", "steel_door", "ladder", "valve",
		"manhole", "hatch", "tripwire", "ancient_lift", "turret", "alarm", "breach", "airlock", "bulkhead", "conduit", "gas", "deck_hole", "cage", "loose_rock", "tnt", "mine_gate", "rubble", "crank_door", "fuse_box", "reactor", "stairs_down", "stairs_up", "service_lift", "steam", "pirate_gate", "searchlight",
		"ramp_down", "cells", "power_socket", "camera", "vault_door", "service_door", "laser_gate", "leak", "seal_panel", "membrane", "maw", "spiral_up", "sleeper"]
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
		"pirate_gate":
			# 0.7.53.11: the hangar gate – two leaves of welded plates, hazard stripes along the top; they part sideways
			var tl8: Array = d["tiles"]
			var gw8 := float(tl8[2]) * 16.0
			var gh8 := float(tl8[3]) * 16.0
			var k8 := float(d.get("open_k", 0.0))
			draw_rect(Rect2(-gw8 * 0.5, -gh8, gw8, gh8), Color(0.03, 0.03, 0.04))
			var lw8 := gw8 * 0.5 * (1.0 - k8)
			for lf in [-1, 1]:
				var x0 := -gw8 * 0.5 if lf < 0 else gw8 * 0.5 - lw8
				if lw8 > 0.5:
					draw_rect(Rect2(x0, -gh8, lw8, gh8), Color(0.36, 0.37, 0.4))
					for pr in int(gh8 / 10.0):
						draw_rect(Rect2(x0, -gh8 + pr * 10, lw8, 1), Color(0.24, 0.24, 0.26))
						draw_rect(Rect2(x0, -gh8 + pr * 10 + 5, lw8, 1), Color(0.6, 0.35, 0.15, 0.5))
			for st in int(gw8 / 8.0):
				draw_rect(Rect2(-gw8 * 0.5 + st * 8, -gh8 - 4, 5, 4), Color(0.95, 0.75, 0.1))
			draw_circle(Vector2(0, -gh8 - 8), 2.0, Color(0.3, 1.0, 0.45) if String(d["state"]) == "open" else Color(1.0, 0.2, 0.15, 0.6 + 0.4 * sin(t * 3.0)))
		"searchlight":
			# 0.7.53.11: a searchlight on a watchtower – its cone sweeping the ground
			var a9 := float(d.get("ang", 0.0))
			var cone := PackedVector2Array([Vector2(0, -70)])
			for cs in 9:
				var ca := a9 - 0.3 + cs * 0.075
				cone.append(Vector2(0, -70) + Vector2(cos(ca), sin(ca) * 0.6) * 150.0 + Vector2(0, 70))
			draw_colored_polygon(cone, Color(1.0, 1.0, 0.85, 0.12 if not bool(d.get("seen", false)) else 0.22))
		"ramp_down":
			# 0.7.53.11: a cargo ramp down to the lower level – hazard stripes, its slope falling away
			draw_rect(Rect2(-22, -12, 44, 26), Color(0.06, 0.06, 0.07))
			for sl in 6:
				draw_rect(Rect2(-20, -10 + sl * 4, 40, 3), Color(0.38, 0.38, 0.4).darkened(sl * 0.12))
			for hz in 6:
				draw_rect(Rect2(-22 + hz * 8, -14, 5, 3), Color(0.95, 0.75, 0.1))
		"cells":
			# 0.7.53.11: the cells – bars across the room's back, a bunk, a prisoner sitting hunched
			var cw9 := float(d.get("w", 8)) * 16.0
			if String(d.get("style", "")) == "research":
				# 0.7.53.20: a station's cold store – a sealed door with a frosted window, people huddled behind it
				var opn := String(d.get("state", "")) == "open"
				draw_rect(Rect2(-cw9 * 0.5, -34, cw9, 34), Color(0.78, 0.8, 0.84))
				draw_rect(Rect2(-cw9 * 0.5, -34, cw9, 3), Color(0.95, 0.45, 0.2))
				draw_rect(Rect2(-14, -30, 28, 30), Color(0.4, 0.42, 0.46) if not opn else Color(0.06, 0.06, 0.08))
				if not opn:
					draw_rect(Rect2(-9, -26, 18, 10), Color(0.55, 0.75, 0.88))
					draw_circle(Vector2(-3, -19), 3.0, Color(0.6, 0.45, 0.35))
					draw_circle(Vector2(4, -20), 3.0, Color(0.5, 0.38, 0.3))
					for fr2 in 10:
						draw_rect(Rect2(-9 + fr2 * 2, -26 + (fr2 % 3) * 3, 2, 1), Color(1, 1, 1, 0.5))
				return
			draw_rect(Rect2(-cw9 * 0.5, -34, cw9, 34), Color(0.05, 0.05, 0.06, 0.6))
			var freed := String(d.get("state", "")) == "open"     # 53c: the rescued prisoner's cell stands open, empty
			for cb in int(cw9 / 5.0):
				var bx := -cw9 * 0.5 + cb * 5
				if freed and bx > -cw9 * 0.5 + cw9 / 9.0 and bx < -cw9 * 0.5 + cw9 * 2.0 / 9.0:
					continue
				draw_rect(Rect2(bx, -34, 1.5, 34), Color(0.5, 0.5, 0.52))
			for dv in range(1, 3):
				draw_rect(Rect2(-cw9 * 0.5 + dv * cw9 / 3.0 - 1, -34, 2, 34), Color(0.3, 0.3, 0.32))
			if freed:
				draw_rect(Rect2(-cw9 * 0.5 + cw9 / 9.0 - 2, -34, 2, 34), Color(0.62, 0.62, 0.64))   # the door swung aside
			for pr in 2:
				if freed and pr == 0:
					continue
				var pxp := -cw9 * 0.5 + (pr * 2 + 1) * cw9 / 6.0
				draw_circle(Vector2(pxp, -16), 4.0, Color(0.6, 0.45, 0.35))
				draw_rect(Rect2(pxp - 5, -12, 10, 9), Color(0.4, 0.38, 0.3))
		"membrane":
			# 0.7.53.23 (Luz): a membrane of living stone across the way – violet, veined, pulsing; open, it draws back
			var tl9: Array = d["tiles"]
			var gw9 := float(tl9[2]) * 16.0
			var gh9 := float(tl9[3]) * 16.0
			var k9 := float(d.get("open_k", 0.0))
			draw_rect(Rect2(-gw9 * 0.5 - 3, -gh9 - 3, gw9 + 6, gh9 + 3), Color(0.16, 0.14, 0.2))
			draw_rect(Rect2(-gw9 * 0.5, -gh9, gw9, gh9), Color(0.03, 0.02, 0.04))
			if k9 < 1.0:
				var mw := gw9 * (1.0 - k9)
				draw_rect(Rect2(-mw * 0.5, -gh9, mw, gh9), Color(0.32, 0.15, 0.38))
				for vn in 5:
					var vx := -mw * 0.5 + (vn + 0.5) * mw / 5.0
					for vy in int(gh9 / 3):
						draw_rect(Rect2(vx + sin(vy * 0.6 + vn + t) * 2.0, -gh9 + vy * 3, 1, 3), Color(0.55, 0.28, 0.62))
				draw_rect(Rect2(-mw * 0.5, -gh9, mw, gh9), Color(0.62, 0.35, 1.0, 0.1 + 0.08 * sin(t * 2.0)))
		"symbol_pillar":
			# 0.7.53.23 (Luz): the symbol stones – four signs in a pillar of black stone; touched ones glow
			draw_rect(Rect2(-8, -40, 16, 40), Color(0.08, 0.07, 0.11))
			draw_rect(Rect2(-8, -40, 16, 2), Color(0.25, 0.22, 0.3))
			var seq: Array = d.get("seq", [])
			for sy in 4:
				var lit := seq.has(sy) or String(d.get("state", "")) == "open"
				var gc := Color(0.62, 0.35, 1.0) if lit else Color(0.3, 0.2, 0.4)
				var cy := -34.0 + sy * 8.0
				match sy:
					0:
						draw_circle(Vector2(0, cy + 2), 2.2, gc)
					1:
						draw_colored_polygon(PackedVector2Array([Vector2(0, cy - 1), Vector2(3, cy + 4), Vector2(-3, cy + 4)]), gc)
					2:
						draw_colored_polygon(PackedVector2Array([Vector2(0, cy - 1), Vector2(3, cy + 2), Vector2(0, cy + 5), Vector2(-3, cy + 2)]), gc)
					_:
						draw_rect(Rect2(-2.5, cy, 5, 5), gc)
		"monolith":
			# 0.7.53.23 (Luz): a monolith – a slab of black glassy stone, its signs in a column, glowing as it is scanned
			var msc := String(d.get("state", "")) == "scanned"
			draw_rect(Rect2(-11, -64, 22, 64), Color(0.05, 0.04, 0.07))
			draw_rect(Rect2(-11, -64, 3, 64), Color(0.15, 0.13, 0.2))
			draw_rect(Rect2(-11, -64, 22, 2), Color(0.22, 0.2, 0.28))
			for gy in range(-56, -6, 8):
				var gl := Color(0.62, 0.35, 1.0, (0.9 if msc else 0.45) + 0.1 * sin(t * 2.0 + gy))
				draw_rect(Rect2(-3, gy, 6, 1), gl)
				draw_rect(Rect2(-1, gy - 2, 1, 5), gl)
		"maw":
			# 0.7.53.23: a maw in the floor – black, ringed with stone teeth, a faint violet glow far down
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5) * GroundMap.SCALE)
			draw_circle(Vector2.ZERO, 22.0, Color(0.16, 0.14, 0.2))
			draw_circle(Vector2.ZERO, 18.0, Color(0.02, 0.01, 0.03))
			draw_circle(Vector2.ZERO, 8.0, Color(0.62, 0.35, 1.0, 0.15 + 0.08 * sin(t)))
			for tk in 12:
				var a := tk * TAU / 12.0
				draw_rect(Rect2(Vector2(cos(a), sin(a)) * 19.0 - Vector2(1.5, 1.5), Vector2(3, 3)), Color(0.28, 0.25, 0.34))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * GroundMap.SCALE)
		"spiral_up":
			# 0.7.53.23: stone steps winding up out of sight
			for st2 in 6:
				draw_rect(Rect2(-16 + st2 * 2, -6 - st2 * 6, 32 - st2 * 4, 5), Color(0.2, 0.18, 0.24).lightened(st2 * 0.04))
				draw_rect(Rect2(-16 + st2 * 2, -6 - st2 * 6, 32 - st2 * 4, 1), Color(0.35, 0.32, 0.4))
		"cracked_wall":
			# 0.7.53.24 (Luz): a wall that is not quite a wall – cracks, a few stones loose, dust at its foot; cut, gone
			if String(d.get("state", "")) != "open":
				var tl4: Array = d["tiles"]
				var x0 := (float(tl4[0][0]) * 16.0) - (d["pos"] as Vector2).x
				var y0 := (float(tl4[0][1]) * 16.0) - (d["pos"] as Vector2).y
				draw_rect(Rect2(x0, y0, 32, 48), Color(0.3, 0.28, 0.27))
				for st4 in 9:
					draw_rect(Rect2(x0 + (st4 % 3) * 11 + 1, y0 + (st4 / 3) * 16 + 2, 9, 13), Color(0.36, 0.34, 0.32).darkened(0.08 * (st4 % 2)))
				for ck in 5:
					var cx4 := x0 + 4 + ck * 6
					draw_line(Vector2(cx4, y0 + 6), Vector2(cx4 + 4, y0 + 22 + ck * 3), Color(0.1, 0.09, 0.09), 1.0)
				draw_rect(Rect2(x0 - 2, y0 + 46, 36, 3), Color(0.45, 0.42, 0.38, 0.7))
		"glyph_trap":
			# 0.7.53.23: a glyph on the floor, glowing faintly – spent, it is dark
			if String(d.get("state", "")) != "spent":
				draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5) * GroundMap.SCALE)
				var gc2 := Color(0.62, 0.35, 1.0, 0.45 + 0.25 * sin(t * 2.5))
				draw_arc(Vector2.ZERO, 12.0, 0.0, TAU, 24, gc2, 1.2)
				draw_arc(Vector2.ZERO, 7.0, 0.0, TAU, 16, gc2, 1.0)
				for sp in 3:
					var a2 := sp * TAU / 3.0 + t * 0.2
					draw_line(Vector2(cos(a2), sin(a2)) * 7.0, Vector2(cos(a2), sin(a2)) * 12.0, gc2, 1.0)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * GroundMap.SCALE)
		"sleeper":
			# 0.7.53.23 (Luz): at the bottom, in the pit – something vast asleep: ridges of a back, folds, one closed eye
			var slw := float(d.get("w", 10)) * 16.0
			var slh := float(d.get("h", 4)) * 16.0
			draw_rect(Rect2(-slw * 0.5, -slh, slw, slh), Color(0.01, 0.0, 0.02))
			var breathe := sin(t * 0.5) * 1.5
			for rd in 9:
				var rx := -slw * 0.42 + rd * slw * 0.105
				var hump := slh * (0.45 - absf(rd - 4) * 0.06)
				draw_set_transform(Vector2(rx, -slh * 0.3 - breathe) * GroundMap.SCALE, 0.0, Vector2(1.0, 0.6) * GroundMap.SCALE)
				draw_circle(Vector2.ZERO, hump + 1.0, Color(0.32, 0.2, 0.46))
				draw_circle(Vector2(0, 1), hump, Color(0.08, 0.06, 0.11))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * GroundMap.SCALE)
			for e9 in 24:
				var ex := slw * 0.2 + e9 * 1.0
				draw_rect(Rect2(ex, -slh * 0.32 + sin(e9 / 24.0 * PI) * -3.0 - breathe, 1, 1), Color(0.75, 0.45, 1.0, 0.9))
			draw_rect(Rect2(-slw * 0.5, -slh, slw, 2), Color(0.25, 0.22, 0.3))
		"leak":
			# 0.7.53.20 (Luz): a module torn open – a ragged hole in the wall, the snow blowing in, frost on the floor;
			# sealed: an emergency plate over it, hazard-striped
			if String(d["state"]) == "open":
				draw_circle(Vector2(0, -24), 13.0, Color(0.05, 0.05, 0.07))
				for tk in 9:
					var at := tk * TAU / 9.0
					draw_rect(Rect2(Vector2(cos(at) * 13.0, -24.0 + sin(at) * 11.0) - Vector2(2, 1), Vector2(4, 3)), Color(0.82, 0.84, 0.88))
				for sn in 26:
					var ph := fposmod(t * 0.7 + sn * 0.137, 1.0)
					var sx := sin(sn * 2.3) * 10.0 + (ph * 40.0) * sin(sn * 1.7)
					draw_rect(Rect2(sx, -24.0 + ph * 60.0, 1.5, 1.5), Color(0.95, 0.97, 1.0, 1.0 - ph))
				for fr in 16:
					draw_rect(Rect2(sin(fr * 3.1) * 30.0, 6.0 + fr % 4 * 6.0, 6, 1), Color(0.85, 0.94, 1.0, 0.55))
			else:
				draw_rect(Rect2(-16, -40, 32, 32), Color(0.4, 0.42, 0.46))
				for st in 6:
					draw_rect(Rect2(-16 + st * 6, -40, 3, 32), Color(0.95, 0.75, 0.1, 0.8))
				draw_rect(Rect2(-16, -40, 32, 2), Color(0.6, 0.62, 0.66))
		"seal_panel":
			# 0.7.53.20: the emergency bulkhead's panel – a red lever (down: sealed), its lamp
			var sealed: bool = String(view.map.explore[int(d.get("leak", 0))]["state"]) != "open"
			draw_rect(Rect2(-7, -30, 14, 18), Color(0.25, 0.26, 0.29))
			draw_rect(Rect2(-6, -29, 12, 16), Color(0.75, 0.76, 0.8))
			draw_rect(Rect2(-2, -27 if not sealed else -21, 4, 7), Color(0.85, 0.15, 0.1))
			draw_circle(Vector2(4, -27), 1.2, Color(0.3, 1.0, 0.45) if sealed else Color(1.0, 0.2, 0.15, 0.6 + 0.4 * sin(t * 4.0)))
		"camera":
			# 0.7.53.19 (Luz): a security camera high on the wall, sweeping – its view a red cone on the floor (dark: off)
			var on9 := String(d["state"]) == "on"
			draw_rect(Rect2(-3, -40, 6, 4), Color(0.3, 0.31, 0.34))
			draw_rect(Rect2(-5, -36, 10, 6), Color(0.18, 0.19, 0.22))
			draw_rect(Rect2(-4, -35, 8, 1), Color(0.4, 0.42, 0.46))
			draw_circle(Vector2(3, -33), 1.2, Color(1.0, 0.15, 0.1) if on9 and fposmod(t, 1.0) < 0.6 else Color(0.25, 0.1, 0.1))
			if on9:
				var a9 := float(d.get("ang", PI * 0.5))
				var reach9 := CAM_REACH
				var pts9 := PackedVector2Array([Vector2(0, 4)])
				for sg in 9:
					var aa := a9 - CAM_HALF + 2.0 * CAM_HALF * sg / 8.0
					pts9.append(Vector2(0, 4) + Vector2(cos(aa), sin(aa) * 0.75) * reach9)
				draw_colored_polygon(pts9, Color(1.0, 0.25, 0.2, 0.08 + 0.18 * float(d.get("notice", 0.0))))
		"laser_gate":
			# 0.7.53.19 (Luz): a light barrier across the way – two posts, red beams between them (off: the posts dark)
			var ln5 := float(d.get("len", 3)) * 16.0
			var v5 := bool(d.get("vertical", true))
			var e5 := Vector2(0, ln5) if v5 else Vector2(ln5, 0)
			for pp5 in [Vector2.ZERO, e5]:
				draw_rect(Rect2(pp5.x - 2, pp5.y - 12, 4, 13), Color(0.22, 0.23, 0.26))
				draw_rect(Rect2(pp5.x - 2, pp5.y - 12, 4, 2), Color(0.45, 0.47, 0.5))
			if String(d["state"]) == "on":
				for bh in [-9.0, -5.0]:
					draw_line(Vector2(0, bh), e5 + Vector2(0, bh), Color(1.0, 0.2, 0.15, 0.3), 2.0)
					draw_line(Vector2(0, bh), e5 + Vector2(0, bh), Color(1.0, 0.45, 0.4, 0.8 + 0.2 * sin(t * 9.0)), 0.6)
		"keycard":
			# 0.7.53.19: a key card on a desk's corner – white, a gold stripe, a blinking chip
			if String(d["state"]) != "taken":
				draw_rect(Rect2(-5, -6, 10, 6), Color(0.94, 0.95, 0.97))
				draw_rect(Rect2(-5, -4, 10, 1), Color(0.95, 0.75, 0.3))
				draw_rect(Rect2(-3, -6, 2, 2), Color(0.85, 0.7, 0.3))
				draw_circle(Vector2(3, -5), 0.8, Color(0.3, 0.85, 1.0) if fposmod(t * 1.5, 1.0) < 0.5 else Color(0.1, 0.3, 0.4))
		"vault_door":
			# 0.7.53.19 (Luz): the round vault door set in the wall – spokes, bolts, the hub; the drill against it while
			# it bites; open, it swings aside
			var tl6: Array = d["tiles"]
			var gw6 := float(tl6[2]) * 16.0
			var gh6 := float(tl6[3]) * 16.0
			var k6 := float(d.get("open_k", 0.0))
			var c6 := Vector2(0, -gh6 * 0.5)
			var r6 := minf(gw6, gh6) * 0.5 + 4.0
			draw_circle(c6, r6 + 3.0, Color(0.2, 0.21, 0.24))
			draw_circle(c6, r6, Color(0.03, 0.03, 0.04))
			if k6 < 1.0:
				var off6 := Vector2(-r6 * 1.6 * k6, 0)
				draw_circle(c6 + off6, r6 - 1.0, Color(0.6, 0.62, 0.66))
				draw_circle(c6 + off6, r6 - 5.0, Color(0.5, 0.52, 0.56))
				for sp6 in 8:
					var a6 := sp6 * TAU / 8.0 + float(d.get("spin", 0.0))
					draw_rect(Rect2(c6 + off6 + Vector2(cos(a6), sin(a6)) * (r6 - 9.0) - Vector2(2, 2), Vector2(4, 4)), Color(0.75, 0.77, 0.8))
				draw_circle(c6 + off6, 7.0, Color(0.32, 0.33, 0.36))
				draw_circle(c6 + off6, 3.0, Color(0.75, 0.6, 0.25))
			if String(d["state"]) == "drilling":
				var dp6 := c6 + Vector2(r6 * 0.5, r6 * 0.4)
				draw_rect(Rect2(dp6.x - 2, dp6.y - 4, 18, 9), Color(0.85, 0.65, 0.15))
				draw_rect(Rect2(dp6.x - 8, dp6.y - 1, 8, 3), Color(0.5, 0.52, 0.55))
				for sk6 in 6:
					var ra := randf() * TAU
					draw_line(dp6 + Vector2(-8, 0), dp6 + Vector2(-8, 0) + Vector2(cos(ra), sin(ra)) * randf_range(3, 9), Color(1.0, 0.85, 0.4), 0.6)
		"service_door":
			# 0.7.53.19: the tower's back door – brushed steel, a narrow window, a lamp over it (red locked, green open)
			var ok7 := float(d.get("open_k", 0.0))
			draw_rect(Rect2(-14, -38, 28, 38), Color(0.32, 0.34, 0.37))
			draw_rect(Rect2(-12, -36, 24, 36), Color(0.03, 0.03, 0.04))
			var lw7 := 24.0 * (1.0 - ok7)
			draw_rect(Rect2(-12, -36, lw7, 36), Color(0.55, 0.57, 0.6))
			if lw7 > 6.0:
				draw_rect(Rect2(-9, -31, 4, 10), Color(0.35, 0.5, 0.62))
				draw_rect(Rect2(-12 + lw7 - 4, -20, 2, 5), Color(0.25, 0.26, 0.28))
			draw_rect(Rect2(-14, 0, 28, 2), Color(0.25, 0.26, 0.28))
			draw_circle(Vector2(0, -42), 1.6, Color(0.3, 1.0, 0.45) if String(d["state"]) == "open" else Color(1.0, 0.2, 0.15, 0.6 + 0.4 * sin(t * 3.0)))
		"power_socket":
			# 0.7.53.16 (Luz): a power socket on the wall – a heavy outlet box, two contacts, a charge bar; while you
			# charge, small arcs leap from its contacts to your suit (d["arc"]: where you stand, relative)
			var left := clampf(float(d.get("charge", 260.0)) / 260.0, 0.0, 1.0)
			var lc := Color(0.35, 0.85, 1.0) if left > 0.0 else Color(0.5, 0.2, 0.15)
			draw_rect(Rect2(-10, -34, 20, 24), Color(0.08, 0.09, 0.1))
			draw_rect(Rect2(-9, -33, 18, 22), Color(0.3, 0.33, 0.36))
			draw_rect(Rect2(-9, -33, 18, 3), Color(0.95, 0.75, 0.1))
			for hz in 3:
				draw_rect(Rect2(-8 + hz * 6, -33, 3, 3), Color(0.1, 0.1, 0.1))
			draw_rect(Rect2(-7, -28, 14, 9), Color(0.06, 0.06, 0.07))
			for pc in 2:
				var px := -4.0 + pc * 8.0
				draw_rect(Rect2(px - 1.5, -26, 3, 5), Color(0.75, 0.72, 0.6))
				draw_circle(Vector2(px, -27), 1.6, Color(lc, 0.5 + 0.5 * sin(t * 3.0 + pc)))
			draw_rect(Rect2(-7, -17, 14, 3), Color(0.05, 0.05, 0.06))
			draw_rect(Rect2(-7, -17, 14.0 * left, 3), lc)
			draw_rect(Rect2(-3, -11, 6, 4), Color(0.2, 0.22, 0.24))
			if d.has("arc"):
				var to: Vector2 = d["arc"]
				var rr := RandomNumberGenerator.new()
				rr.seed = int(t * 24.0) + int(d.get("seed", 0))
				for bolt in 2:
					var a0 := Vector2(-4.0 + bolt * 8.0, -26)
					var pts := PackedVector2Array([a0])
					var segs := 6
					for sg in range(1, segs):
						var p := a0.lerp(to + Vector2(0, -14), float(sg) / segs)
						pts.append(p + Vector2(rr.randf_range(-5, 5), rr.randf_range(-4, 4)))
					pts.append(to + Vector2(rr.randf_range(-4, 4), -14 + rr.randf_range(-6, 6)))
					draw_polyline(pts, Color(0.45, 0.85, 1.0, 0.35), 3.0)
					draw_polyline(pts, Color(0.9, 0.97, 1.0), 1.0)
				draw_circle(to + Vector2(0, -14), 5.0 + sin(t * 30.0), Color(0.5, 0.9, 1.0, 0.25))
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
			if String(d.get("style", "")) == "darkones":
				# 0.7.53.23: a relic of the Dark Ones on its altar – a black shard, never quite still
				draw_rect(Rect2(-10, -10, 20, 10), Color(0.09, 0.08, 0.12))
				draw_rect(Rect2(-10, -10, 20, 2), Color(0.22, 0.2, 0.28))
				var wob := sin(t * 1.3) * 1.5
				draw_colored_polygon(PackedVector2Array([Vector2(0, -30 + wob), Vector2(5, -19), Vector2(0, -11), Vector2(-5, -19)]), Color(0.06, 0.05, 0.09))
				draw_line(Vector2(0, -30 + wob), Vector2(0, -11), Color(0.62, 0.35, 1.0, 0.6 + 0.3 * sin(t * 2.0)), 1.0)
				return
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
