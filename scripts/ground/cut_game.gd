extends Control
## 0.7.52.22 (Luz, package 52b): the cutting torch at a maintenance box. One flap per box, each box its own shape
## (rounded, hexagon, round, trapezoid, notched, arched); the torch moves with WASD, Space burns. On the line the cut
## glows and runs on; off it the plate scorches and heats up – too hot, and the torch stops to cool. The suit pays the
## energy. When the line is cut all round, the flap falls away and shows what is behind: a button with its wiring, or
## a terminal to jack into. Engineering and the torch's quality make the line wider and the heat slower.
## No class_name: preload it.

signal finished(result: String)          # "button" (pressed), "terminal" (jack in), "" (left)

const SHAPES := ["rounded", "hex", "round", "trapezoid", "notched", "arch"]
const SPEED := 150.0                     # px a second the torch moves
const STEP := 4.0                        # the line in samples this far apart

var inside := "button"                   # what lies behind the flap: "button" or "terminal"
var shape := "rounded"
var label := "MAINT-04"
var skill := 0                           # Engineering
var quality := 1.0                       # the torch's strength
var tol := 8.0
var heat := 0.0
var over := false
var torch := Vector2.ZERO                # in box coordinates
var burning := false
var path: PackedVector2Array = []        # the cut line (closed), in box coordinates
var cut: PackedByteArray = []
var scorch: Array = []                   # [pos, r]
var sparks: Array = []                   # {p, v, t}
var falling := -1.0                      # the flap falling away (seconds), -1 still shut
var opened := false
var pressed := false
var t := 0.0
var _box := Rect2()
var _seed := 0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	tol = 7.0 + skill * 0.8 + (quality - 1.0) * 6.0
	_seed = hash(label)
	path = shape_path(shape, Vector2(330, 250))
	cut.resize(path.size())
	cut.fill(0)
	torch = path[0] + Vector2(-40, 30)
	Audio.play("ui_open", "cutting torch panel", -6.0)


## The flap's outline (closed, centred on 0,0) for a shape, about size big.
static func shape_path(sh: String, size: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var hw := size.x * 0.5
	var hh := size.y * 0.5
	match sh:
		"round":
			for i in 64:
				pts.append(Vector2.from_angle(i * TAU / 64.0) * hh)
		"hex":
			for i in 6:
				pts.append(Vector2.from_angle(i * TAU / 6.0) * Vector2(hw * 0.85, hh))
		"trapezoid":
			pts = PackedVector2Array([Vector2(-hw * 0.65, -hh), Vector2(hw * 0.65, -hh), Vector2(hw, hh), Vector2(-hw, hh)])
		"notched":
			var n := 34.0
			pts = PackedVector2Array([Vector2(-hw + n, -hh), Vector2(hw - n, -hh), Vector2(hw, -hh + n), Vector2(hw, hh - n),
				Vector2(hw - n, hh), Vector2(-hw + n, hh), Vector2(-hw, hh - n), Vector2(-hw, -hh + n)])
		"arch":
			pts.append(Vector2(-hw * 0.8, hh))
			pts.append(Vector2(-hw * 0.8, -hh * 0.2))
			for i in 25:
				pts.append(Vector2(-cos(PI * i / 24.0) * hw * 0.8, -hh * 0.2 - sin(PI * i / 24.0) * hh * 0.8))
			pts.append(Vector2(hw * 0.8, hh))
		_:
			var r := 30.0
			for c in [[Vector2(hw - r, -hh + r), -PI / 2], [Vector2(hw - r, hh - r), 0.0], [Vector2(-hw + r, hh - r), PI / 2], [Vector2(-hw + r, -hh + r), PI]]:
				for i in 9:
					pts.append((c[0] as Vector2) + Vector2.from_angle(float(c[1]) + PI / 2 * i / 8.0) * r)
	# resample to even steps
	var out := PackedVector2Array()
	for i in pts.size():
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % pts.size()]
		var n2 := maxi(1, int(a.distance_to(b) / STEP))
		for j in n2:
			out.append(a.lerp(b, float(j) / n2))
	return out


func cut_share() -> float:
	var n := 0
	for c in cut:
		n += int(c)
	return float(n) / maxf(1.0, float(cut.size()))


func _process(delta: float) -> void:
	t += delta
	var vs := get_viewport_rect().size
	_box = Rect2(vs * 0.5 - Vector2(300, 220), Vector2(600, 480))
	if falling >= 0.0:
		falling += delta
		if falling > 0.7:
			opened = true
	if not opened and falling < 0.0:
		step(delta, Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down"), Input.is_action_pressed("foot_dodge"))
	for s in sparks:
		s["t"] = float(s["t"]) + delta
		s["v"] = (s["v"] as Vector2) + Vector2(0, 420) * delta
		s["p"] = (s["p"] as Vector2) + (s["v"] as Vector2) * delta
	sparks = sparks.filter(func(s): return float(s["t"]) < 0.45)
	queue_redraw()


## One moment of work: the torch moved by mv (−1..1), burning while `burn` (also for the smoke test).
func step(delta: float, mv: Vector2, burn: bool) -> void:
	if opened or falling >= 0.0:
		return
	if true:
		torch += mv * SPEED * delta
		torch = torch.clamp(Vector2(-280, -225), Vector2(280, 225))
		burning = burn and not over and GameState.gear.energy > 0.1
		if burning:
			var e := 5.0 * delta
			GameState.gear.energy = maxf(0.0, GameState.gear.energy - e)
			var near := false
			for i in path.size():
				if (path[i] as Vector2).distance_to(torch) <= tol:
					near = true
					if cut[i] == 0:
						cut[i] = 1
			heat += delta * (0.10 if near else 0.45) / (1.0 + 0.06 * skill)
			if not near:
				if scorch.is_empty() or (scorch[-1][0] as Vector2).distance_to(torch) > 5.0:
					scorch.append([torch, randf_range(5.0, 9.0)])
			for k in 3:
				sparks.append({"p": torch, "v": Vector2.from_angle(randf_range(-PI, 0.4)) * randf_range(60, 220), "t": 0.0})
			if cut_share() >= 0.985:
				cut.fill(1)
				falling = 0.0
				burning = false
				Audio.play("explosion_small", "the flap falls away", -14.0)
		else:
			heat = maxf(0.0, heat - delta * 0.35)
		if heat >= 1.0:
			over = true
			Audio.play("ui_error", "torch too hot", -8.0)
		if over and heat <= 0.4:
			over = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_back", false, true):
		get_viewport().set_input_as_handled()
		finished.emit("")
		return
	if opened and not pressed and event.is_action_pressed("foot_dodge", false, false):
		get_viewport().set_input_as_handled()
		pressed = true
		Audio.play("ui_click", "panel: " + inside)
		finished.emit(inside)
	elif event is InputEventKey:
		get_viewport().set_input_as_handled()          # the keys belong to the torch now


# ---------------------------------------------------------------- drawing

func _s(p: Vector2, s: String, col: Color, sz: int = 13, al := HORIZONTAL_ALIGNMENT_LEFT, w := -1.0) -> void:
	draw_string(ThemeDB.fallback_font, p, s, al, w, sz, col)


func _draw() -> void:
	var vs := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vs), Color(0, 0, 0, 0.6))
	var win := _box.grow_individual(30, 110, 200, 40)
	draw_rect(win, Color(0.03, 0.04, 0.07, 0.96))
	draw_rect(win, Color(1.0, 0.6, 0.25, 0.9), false, 2.0)
	_s(win.position + Vector2(18, 28), "%s – cut the flap open" % label, Color(1.0, 0.7, 0.35), 17)
	_s(win.position + Vector2(18, 50), "WASD: move the torch  •  Space: burn  •  stay on the line – off it the plate scorches and heats up  •  Esc: leave", Color(0.75, 0.78, 0.82), 12)
	var c := _box.get_center()
	_draw_housing(_box)
	# behind the flap: the recess and its machinery (seen once the flap falls)
	if falling >= 0.0:
		var poly := PackedVector2Array()
		for p in path:
			poly.append(c + p)
		draw_colored_polygon(poly, Color(0.04, 0.04, 0.05))
		_draw_machinery(c, poly)
		# the cut rim glows a while
		poly.append(poly[0])
		draw_polyline(poly, Color(1.0, 0.5, 0.2, maxf(0.15, 1.0 - falling)), 4.0)
		draw_polyline(poly, Color(0.25, 0.22, 0.2), 2.0)
	if falling < 0.7:
		_draw_flap(c, clampf(falling, 0.0, 0.7) / 0.7 if falling >= 0.0 else 0.0)
	for sc in scorch:
		draw_circle(c + (sc[0] as Vector2), float(sc[1]), Color(0.1, 0.08, 0.06, 0.55))
		draw_circle(c + (sc[0] as Vector2), float(sc[1]) * 0.5, Color(0.05, 0.04, 0.03, 0.6))
	# the plate glows round the torch as it heats
	if heat > 0.05 and not opened:
		draw_circle(c + torch, 40.0 * heat + 8.0, Color(1.0, 0.3, 0.1, 0.25 * heat))
	for s in sparks:
		var k := 1.0 - float(s["t"]) / 0.45
		draw_line(c + (s["p"] as Vector2), c + (s["p"] as Vector2) - (s["v"] as Vector2) * 0.03, Color(1.0, 0.6 + 0.3 * k, 0.25, k), 1.5)
	if not opened:
		_draw_torch(c + torch)
	else:
		var tx := "Space: press the button" if inside == "button" else ("Space: crawl in" if inside == "duct" else ("Space: take what is inside" if inside == "loot" else "Space: jack into the terminal"))
		_s(Vector2(_box.position.x, _box.end.y + 30), tx, Color(0.45, 1.0, 0.6) if inside == "button" else Color(0.4, 0.95, 1.0), 15, HORIZONTAL_ALIGNMENT_CENTER, _box.size.x)
	_draw_gauges(Vector2(_box.end.x + 40, _box.position.y + 10))


## The box itself: a heavy steel housing – bevelled frame, bolts, a vent, warning stripes, its plate and a status light,
## conduits running in.
func _draw_housing(r: Rect2) -> void:
	var steel := Color(0.36, 0.38, 0.42)
	# conduits into the box, top and bottom
	for x in [r.position.x + 70, r.position.x + 110, r.end.x - 90]:
		draw_rect(Rect2(Vector2(x, r.position.y - 36), Vector2(22, 36)), Color(0.22, 0.23, 0.26))
		draw_rect(Rect2(Vector2(x + 3, r.position.y - 36), Vector2(5, 36)), Color(0.32, 0.33, 0.37))
		for yy in [r.position.y - 30, r.position.y - 16]:
			draw_rect(Rect2(Vector2(x - 3, yy), Vector2(28, 6)), Color(0.45, 0.46, 0.5))
	draw_rect(Rect2(Vector2(r.position.x + 200, r.end.y), Vector2(30, 40)), Color(0.2, 0.2, 0.22))
	draw_rect(Rect2(Vector2(r.position.x + 194, r.end.y + 4), Vector2(42, 8)), Color(0.42, 0.43, 0.47))
	# the frame: outer dark rim, bevel light top-left, shade bottom-right
	draw_rect(r.grow(10), Color(0.12, 0.13, 0.15))
	draw_rect(r.grow(6), Color(0.28, 0.3, 0.33))
	draw_rect(Rect2(r.position - Vector2(6, 6), Vector2(r.size.x + 12, 4)), Color(0.55, 0.57, 0.6))
	draw_rect(Rect2(r.position - Vector2(6, 6), Vector2(4, r.size.y + 12)), Color(0.48, 0.5, 0.53))
	draw_rect(Rect2(Vector2(r.position.x - 6, r.end.y + 2), Vector2(r.size.x + 12, 4)), Color(0.16, 0.17, 0.19))
	draw_rect(Rect2(Vector2(r.end.x + 2, r.position.y - 6), Vector2(4, r.size.y + 12)), Color(0.18, 0.19, 0.21))
	draw_rect(r, steel)
	# brushed lines and wear
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	for i in 40:
		var y := r.position.y + rng.randf() * r.size.y
		draw_line(Vector2(r.position.x + 4, y), Vector2(r.position.x + 4 + rng.randf_range(40, r.size.x - 8), y), Color(0.4, 0.42, 0.46, 0.35), 1.0)
	for i2 in 14:
		var sp := r.position + Vector2(rng.randf() * r.size.x, rng.randf() * r.size.y)
		draw_line(sp, sp + Vector2(rng.randf_range(-14, 14), rng.randf_range(-3, 3)), Color(0.55, 0.57, 0.6, 0.6), 1.0)
	# seams with their rivets, left and right of the flap
	for sx in [r.position.x + 58, r.end.x - 74]:
		draw_line(Vector2(sx, r.position.y + 56), Vector2(sx, r.end.y - 40), Color(0.22, 0.23, 0.26), 2.0)
		draw_line(Vector2(sx + 2, r.position.y + 56), Vector2(sx + 2, r.end.y - 40), Color(0.5, 0.52, 0.56), 1.0)
		for ry in range(int(r.position.y) + 70, int(r.end.y) - 44, 28):
			draw_circle(Vector2(sx - 7, ry), 2.6, Color(0.25, 0.26, 0.28))
			draw_circle(Vector2(sx - 7.6, ry - 0.6), 1.6, Color(0.62, 0.64, 0.67))
	# hinges down the left edge
	for hy in [r.position.y + 90, r.position.y + 230, r.end.y - 110]:
		draw_rect(Rect2(Vector2(r.position.x - 12, hy), Vector2(14, 40)), Color(0.2, 0.21, 0.23))
		draw_rect(Rect2(Vector2(r.position.x - 10, hy + 2), Vector2(4, 36)), Color(0.55, 0.57, 0.6))
		for kn in 3:
			draw_line(Vector2(r.position.x - 12, hy + 13 + kn * 7), Vector2(r.position.x + 2, hy + 13 + kn * 7), Color(0.12, 0.12, 0.14), 1.0)
	# a recessed handle on the right
	var hd := Rect2(Vector2(r.end.x - 46, r.position.y + 190), Vector2(18, 90))
	draw_rect(hd, Color(0.14, 0.15, 0.17))
	draw_rect(Rect2(hd.position + Vector2(4, 8), Vector2(10, 74)), Color(0.5, 0.52, 0.56))
	draw_rect(Rect2(hd.position + Vector2(4, 8), Vector2(3, 74)), Color(0.68, 0.7, 0.73))
	# rust and grime running down from the bolts and seams
	for i4 in 9:
		var rx := r.position.x + 20 + rng.randf() * (r.size.x - 40)
		var ry0 := r.position.y + 20 + rng.randf() * 60.0
		var ln := rng.randf_range(30.0, 140.0)
		draw_line(Vector2(rx, ry0), Vector2(rx + rng.randf_range(-2, 2), ry0 + ln), Color(0.42, 0.26, 0.14, 0.22), rng.randf_range(1.5, 3.5))
	draw_rect(Rect2(Vector2(r.position.x, r.end.y - 70), Vector2(r.size.x, 40)), Color(0.2, 0.16, 0.12, 0.12))
	# a barcode sticker and an embossed rib under the plate
	var bcr := Rect2(Vector2(r.end.x - 140, r.end.y - 62), Vector2(90, 24))
	draw_rect(bcr, Color(0.88, 0.88, 0.84))
	for bi in 26:
		if rng.randf() < 0.6:
			draw_rect(Rect2(bcr.position + Vector2(5 + bi * 3, 3), Vector2(rng.randi_range(1, 2), 13)), Color(0.08, 0.08, 0.08))
	_s(bcr.position + Vector2(5, 22), "SN 04-%05d" % (_seed % 100000), Color(0.2, 0.2, 0.2), 7)
	draw_line(Vector2(r.position.x + 14, r.position.y + 56), Vector2(r.position.x + 200, r.position.y + 56), Color(0.24, 0.25, 0.28), 2.0)
	draw_line(Vector2(r.position.x + 14, r.position.y + 58), Vector2(r.position.x + 200, r.position.y + 58), Color(0.5, 0.52, 0.56), 1.0)
	# warning stripes along the bottom
	var sb := Rect2(Vector2(r.position.x + 12, r.end.y - 30), Vector2(r.size.x - 24, 18))
	draw_rect(sb, Color(0.95, 0.78, 0.15))
	var x0 := sb.position.x
	while x0 < sb.end.x:
		var quad := PackedVector2Array([Vector2(x0, sb.end.y), Vector2(minf(x0 + 12, sb.end.x), sb.end.y),
			Vector2(minf(x0 + 24, sb.end.x), sb.position.y), Vector2(minf(x0 + 12, sb.end.x), sb.position.y)])
		draw_colored_polygon(quad, Color(0.1, 0.1, 0.1))
		x0 += 24.0
	draw_rect(sb, Color(0.1, 0.1, 0.1), false, 1.0)
	# the plate with its name, a status light
	var lp := Rect2(Vector2(r.position.x + 14, r.position.y + 12), Vector2(150, 34))
	draw_rect(lp, Color(0.78, 0.78, 0.72))
	draw_rect(lp, Color(0.25, 0.25, 0.25), false, 1.0)
	_s(lp.position + Vector2(8, 15), label, Color(0.12, 0.12, 0.14), 13)
	_s(lp.position + Vector2(8, 29), ("AIR SHAFT – KEEP CLEAR" if inside == "duct" else ("SUPPLY CACHE – SEALED" if inside == "loot" else "⚡ HIGH VOLTAGE – AUTHORISED ONLY")), Color(0.6, 0.1, 0.08), 8)
	var led := Vector2(r.end.x - 28, r.position.y + 28)
	draw_circle(led, 8.0, Color(0.12, 0.12, 0.14))
	var on: bool = fposmod(t, 1.2) < 0.9 and not opened
	draw_circle(led, 5.0, Color(1.0, 0.25, 0.2) if on else Color(0.35, 0.1, 0.08))
	# a vent, right side
	for i3 in 8:
		var vy := r.position.y + 70 + i3 * 12
		draw_rect(Rect2(Vector2(r.end.x - 52, vy), Vector2(34, 6)), Color(0.12, 0.13, 0.15))
		draw_rect(Rect2(Vector2(r.end.x - 52, vy), Vector2(34, 2)), Color(0.5, 0.52, 0.56))
	# bolts at the corners and along the edges
	for bp in [Vector2(14, 14), Vector2(r.size.x - 14, 14), Vector2(14, r.size.y - 14), Vector2(r.size.x - 14, r.size.y - 14),
			Vector2(r.size.x * 0.5, 10), Vector2(r.size.x * 0.5, r.size.y - 10)]:
		var bc: Vector2 = r.position + bp
		draw_circle(bc, 7.0, Color(0.2, 0.21, 0.23))
		draw_circle(bc, 5.5, Color(0.55, 0.57, 0.6))
		draw_line(bc - Vector2(3.5, 0).rotated(0.6), bc + Vector2(3.5, 0).rotated(0.6), Color(0.25, 0.26, 0.28), 1.5)


## The flap: a separate plate on the box – a recessed seam shown as the line to cut, its own bolts and a stencil.
## `drop` 0..1 as it falls away.
func _draw_flap(c: Vector2, drop: float) -> void:
	var poly := PackedVector2Array()
	var cen := c + Vector2(drop * 60.0, drop * drop * 260.0)
	var rot := drop * 0.7
	for p in path:
		poly.append(cen + (p as Vector2).rotated(rot) * (1.0 - drop * 0.15))
	draw_colored_polygon(poly, Color(0.43, 0.45, 0.49, 1.0 - drop * 0.3))
	# bevel: lighter edge up-left
	var rim := poly.duplicate()
	rim.append(rim[0])
	draw_polyline(rim, Color(0.2, 0.21, 0.24), 3.0)
	if drop <= 0.0:
		# the line to cut: dashed where still whole, a glowing then dark slit where cut
		for i in path.size():
			var a: Vector2 = c + path[i]
			var b: Vector2 = c + path[(i + 1) % path.size()]
			if cut[i] == 1:
				draw_line(a, b, Color(0.08, 0.06, 0.05), 3.0)
				draw_line(a, b, Color(1.0, 0.55, 0.2, 0.55), 1.5)
			elif i % 3 != 2:
				draw_line(a, b, Color(0.95, 0.9, 0.55, 0.85), 2.0)
	# stencil and bolts on the flap
	var lab := cen + Vector2(-60, -6).rotated(rot)
	if inside == "duct":
		# the vent's grille: slats across the flap
		var bb := Rect2(path[0], Vector2.ZERO)
		for pq in path:
			bb = bb.expand(pq)
		var y0 := bb.position.y + 16.0
		while y0 < bb.end.y - 12.0:
			var a0 := cen + Vector2(bb.position.x + 16.0, y0).rotated(rot) * (1.0 - drop * 0.15)
			var a1 := cen + Vector2(bb.end.x - 16.0, y0).rotated(rot) * (1.0 - drop * 0.15)
			draw_line(a0, a1, Color(0.16, 0.17, 0.2, 1.0 - drop * 0.3), 6.0)
			draw_line(a0 + Vector2(0, 3), a1 + Vector2(0, 3), Color(0.62, 0.64, 0.68, 1.0 - drop * 0.3), 1.5)
			y0 += 18.0
	_s(lab, "ACCESS" if inside != "duct" else "AIR SHAFT", Color(0.95, 0.78, 0.2, 0.9 - drop), 18)
	_s(lab + Vector2(0, 18).rotated(rot), "do not open under load", Color(0.2, 0.2, 0.22, 0.9 - drop), 10)
	var bounds := Rect2(path[0], Vector2.ZERO)
	for p2 in path:
		bounds = bounds.expand(p2)
	for corner in [Vector2(0.28, 0.28), Vector2(0.72, 0.28), Vector2(0.28, 0.72), Vector2(0.72, 0.72)]:
		var bp: Vector2 = cen + (bounds.position + bounds.size * corner).rotated(rot) * (1.0 - drop * 0.15)
		if Geometry2D.is_point_in_polygon(bp, poly):
			draw_circle(bp, 5.0, Color(0.25, 0.26, 0.28))
			draw_circle(bp, 3.5, Color(0.6, 0.62, 0.66))


## Behind the flap: the recess, a mounting plate, bundles of wire, a board with chips – and the button or the terminal.
func _draw_machinery(c: Vector2, poly: PackedVector2Array) -> void:
	var bounds := Rect2(poly[0], Vector2.ZERO)
	for p in poly:
		bounds = bounds.expand(p)
	if inside == "loot":
		# package 53a: inside a welded cache – packed supplies, a credit chip, padding
		draw_colored_polygon(poly, Color(0.1, 0.09, 0.08))
		for bi in 6:
			var bp := c + Vector2(-90 + (bi % 3) * 64, -50 + (bi / 3) * 60)
			if Geometry2D.is_point_in_polygon(bp + Vector2(25, 20), poly):
				draw_rect(Rect2(bp, Vector2(52, 42)), [Color(0.55, 0.45, 0.3), Color(0.3, 0.45, 0.55), Color(0.5, 0.25, 0.22)][bi % 3])
				draw_rect(Rect2(bp, Vector2(52, 4)), Color(1, 1, 1, 0.15))
				draw_rect(Rect2(bp + Vector2(20, 14), Vector2(12, 12)), Color(0.9, 0.9, 0.85, 0.6))
		draw_rect(Rect2(c + Vector2(-20, 66), Vector2(40, 18)), Color(0.95, 0.8, 0.3))
		draw_string(ThemeDB.fallback_font, c + Vector2(-16, 80), "CR", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.2, 0.15, 0.05))
		return
	if inside == "duct":
		# 0.7.52.27: behind a vent's grille – the shaft running off into the dark, its ribs closing in, a draught of dust
		for k in 9:
			var f := 1.0 - k * 0.1
			var rr := Rect2(c - bounds.size * 0.5 * f, bounds.size * f)
			draw_rect(rr, Color(0.22 - k * 0.022, 0.23 - k * 0.022, 0.26 - k * 0.024))
			draw_rect(rr, Color(0.36 - k * 0.03, 0.38 - k * 0.03, 0.42 - k * 0.03), false, 2.0)
		draw_rect(Rect2(c - bounds.size * 0.06, bounds.size * 0.12), Color(0.01, 0.01, 0.015))
		for dp in 14:
			var q := c + Vector2(sin(t * 0.7 + dp * 1.7) * bounds.size.x * 0.3, cos(t * 0.5 + dp * 2.3) * bounds.size.y * 0.3)
			draw_circle(q, 1.2, Color(0.8, 0.78, 0.7, 0.25))
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed + 7
	var inner := func(q: Vector2, shrink: float) -> bool:
		var sp := PackedVector2Array()
		for p0 in poly:
			sp.append(c + (p0 - c) * shrink)
		return Geometry2D.is_point_in_polygon(q, sp)
	# depth: the recess's walls – lit along the top edge, in shadow below; darker towards the back
	for k in 7:
		var sh := PackedVector2Array()
		for p2 in poly:
			sh.append(c + (p2 - c) * (1.0 - k * 0.035) + Vector2(0, k * 1.5))
		draw_colored_polygon(sh, Color(0.16 - k * 0.016, 0.17 - k * 0.016, 0.19 - k * 0.016))
	var back := PackedVector2Array()
	for p3 in poly:
		back.append(c + (p3 - c) * 0.76 + Vector2(0, 10))
	draw_colored_polygon(back, Color(0.07, 0.075, 0.085))
	# the back wall: a perforated mounting rail grid
	for gx in range(int(bounds.position.x) + 16, int(bounds.end.x) - 10, 18):
		for gy in range(int(bounds.position.y) + 18, int(bounds.end.y) - 10, 18):
			var q := Vector2(gx, gy)
			if inner.call(q, 0.74):
				draw_circle(q, 2.0, Color(0.03, 0.03, 0.035))
	var k2 := clampf(minf(bounds.size.x, bounds.size.y) / 275.0, 0.7, 1.05)
	# two conduits come in through the wall, clamped
	for side in [-1.0, 1.0]:
		var e0 := c + Vector2(side * bounds.size.x * 0.36, -bounds.size.y * 0.18)
		if not inner.call(e0, 0.95):
			e0 = c + Vector2(side * bounds.size.x * 0.28, -bounds.size.y * 0.1)
		var e1 := c + Vector2(side * 70.0 * k2, -30.0 * k2)
		draw_line(e0, e1, Color(0.18, 0.19, 0.21), 14.0 * k2)
		draw_line(e0, e1, Color(0.32, 0.33, 0.36), 6.0 * k2)
		var cm := e0.lerp(e1, 0.35)
		draw_rect(Rect2(cm - Vector2(5, 10) * k2, Vector2(10, 20) * k2), Color(0.55, 0.56, 0.58))
	# the mounting plate with its screws and a sticker
	var mp := Rect2(c - Vector2(115, 85) * k2, Vector2(230, 170) * k2)
	draw_rect(mp.grow(2), Color(0.1, 0.11, 0.12))
	draw_rect(mp, Color(0.24, 0.26, 0.28))
	draw_rect(Rect2(mp.position, Vector2(mp.size.x, 2)), Color(0.38, 0.4, 0.43))
	for sp2 in [mp.position + Vector2(8, 8), Vector2(mp.end.x - 8, mp.position.y + 8), Vector2(mp.position.x + 8, mp.end.y - 8), mp.end - Vector2(8, 8)]:
		draw_circle(sp2, 4.0, Color(0.15, 0.15, 0.17))
		draw_circle(sp2, 3.0, Color(0.6, 0.62, 0.65))
		draw_line(sp2 - Vector2(2, 0), sp2 + Vector2(2, 0), Color(0.2, 0.2, 0.22), 1.0)
	var stk := Rect2(Vector2(mp.end.x - 52 * k2, mp.position.y + 14 * k2), Vector2(40, 16) * k2)
	draw_rect(stk, Color(0.95, 0.8, 0.2))
	draw_string(ThemeDB.fallback_font, stk.position + Vector2(3, 12 * k2), "⚠ 400V", HORIZONTAL_ALIGNMENT_LEFT, -1, int(9 * k2), Color(0.1, 0.1, 0.1))
	# a heat sink with its fins, a relay with screw terminals, a row of fuses
	var hs := Rect2(Vector2(mp.position.x + 14 * k2, mp.position.y + 14 * k2), Vector2(56, 34) * k2)
	draw_rect(hs, Color(0.5, 0.52, 0.56))
	for f in 7:
		draw_rect(Rect2(hs.position + Vector2(3 + f * 7.6 * k2, 2), Vector2(3 * k2, hs.size.y - 4)), Color(0.66, 0.68, 0.72))
	var rl := Rect2(Vector2(mp.position.x + 14 * k2, mp.end.y - 62 * k2), Vector2(44, 40) * k2)
	draw_rect(rl, Color(0.1, 0.1, 0.11))
	draw_rect(Rect2(rl.position + Vector2(4, 4), Vector2(rl.size.x - 8, 9 * k2)), Color(0.95, 0.75, 0.2))
	for tn in 4:
		draw_circle(rl.position + Vector2(7 + tn * 10 * k2, rl.size.y - 8 * k2), 3.0 * k2, Color(0.8, 0.65, 0.3))
	var fz := Vector2(mp.end.x - 30 * k2, mp.end.y - 70 * k2)
	for fi in 3:
		var fr := Rect2(fz + Vector2(0, fi * 18 * k2), Vector2(22, 9) * k2)
		draw_rect(fr, Color(0.6, 0.85, 0.95, 0.75))
		draw_rect(Rect2(fr.position, Vector2(4 * k2, fr.size.y)), Color(0.75, 0.75, 0.78))
		draw_rect(Rect2(Vector2(fr.end.x - 4 * k2, fr.position.y), Vector2(4 * k2, fr.size.y)), Color(0.75, 0.75, 0.78))
		draw_line(fr.position + Vector2(4 * k2, fr.size.y * 0.5), Vector2(fr.end.x - 4 * k2, fr.position.y + fr.size.y * 0.5), Color(0.3, 0.3, 0.32), 1.0)
	# the board: green, traces, chips with pins, capacitors, blinking LEDs
	var pcb := Rect2(c + Vector2(-70, 34) * k2, Vector2(140, 40) * k2)
	draw_rect(pcb.grow(1), Color(0.05, 0.2, 0.1))
	draw_rect(pcb, Color(0.1, 0.38, 0.2))
	for tr in 8:
		var ty := pcb.position.y + 3 + tr * 4.6 * k2
		draw_line(Vector2(pcb.position.x + 5, ty), Vector2(pcb.position.x + 20 + rng.randf() * (pcb.size.x - 30), ty), Color(0.75, 0.65, 0.3, 0.7), 1.0)
	for ch in 2:
		var cr := Rect2(pcb.position + Vector2((14 + ch * 56) * k2, 9 * k2), Vector2(36, 20) * k2)
		draw_rect(cr, Color(0.08, 0.08, 0.09))
		draw_string(ThemeDB.fallback_font, cr.position + Vector2(3, 13 * k2), "CX-%d" % (40 + ch), HORIZONTAL_ALIGNMENT_LEFT, -1, int(8 * k2), Color(0.6, 0.6, 0.6))
		for pn in 6:
			var px := cr.position.x + 3 + pn * 5.6 * k2
			draw_line(Vector2(px, cr.position.y - 3), Vector2(px, cr.position.y), Color(0.75, 0.75, 0.75), 1.0)
			draw_line(Vector2(px, cr.end.y), Vector2(px, cr.end.y + 3), Color(0.75, 0.75, 0.75), 1.0)
	for cp in 3:
		var ccp := pcb.position + Vector2((122 + (cp % 2) * 9) * k2, (8 + cp * 11) * k2)
		draw_circle(ccp, 4.0 * k2, Color(0.15, 0.2, 0.5))
		draw_circle(ccp, 2.0 * k2, Color(0.6, 0.65, 0.75))
	for ld in 3:
		var on: bool = fposmod(t * 2.0 + ld * 0.7, 1.5) < 0.8
		draw_circle(pcb.position + Vector2(pcb.size.x - 10 - ld * 9, pcb.size.y - 5), 2.5, Color(0.3, 1.0, 0.4) if on else Color(0.1, 0.3, 0.12))
	# wire bundles from the conduits and the walls to the part and the board – red, blue, yellow, black, green – with
	# ties and little tags
	var cols := [Color(0.85, 0.2, 0.15), Color(0.2, 0.45, 0.9), Color(0.95, 0.8, 0.2), Color(0.12, 0.12, 0.13), Color(0.3, 0.75, 0.35)]
	for wi in 12:
		var from := Vector2.ZERO
		for tries in 12:
			from = c + Vector2(rng.randf_range(-0.42, 0.42) * bounds.size.x, rng.randf_range(-0.42, 0.42) * bounds.size.y)
			if inner.call(from, 0.8):
				break
		var to := c + Vector2(rng.randf_range(-50, 50), rng.randf_range(-36, 40)) * k2
		var mid := from.lerp(to, 0.5) + Vector2(rng.randf_range(-20, 20), rng.randf_range(10, 34))
		var pts := PackedVector2Array()
		for s in 15:
			var q2 := s / 14.0
			pts.append(from.lerp(mid, q2).lerp(mid.lerp(to, q2), q2))
		var wc: Color = cols[wi % cols.size()]
		draw_polyline(pts, wc.darkened(0.55), 5.0)
		draw_polyline(pts, wc, 3.0)
		draw_line(pts[3], pts[4], wc.lightened(0.35), 1.0)
		draw_line(pts[5] - Vector2(0, 4), pts[5] + Vector2(0, 4), Color(0.92, 0.92, 0.88), 2.0)
		if wi % 4 == 0:
			draw_rect(Rect2(pts[8] + Vector2(2, -3), Vector2(14, 7)), Color(0.92, 0.92, 0.88))
			draw_string(ThemeDB.fallback_font, pts[8] + Vector2(3, 3), ["L1", "N", "PE"][wi % 3], HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.1, 0.1, 0.1))
	# the part
	if inside == "button":
		var bc := c + Vector2(0, -22) * k2
		var hr := 44.0 * k2
		draw_rect(Rect2(bc - Vector2(hr + 3, hr + 3), Vector2(hr + 3, hr + 3) * 2), Color(0.08, 0.08, 0.09))
		draw_rect(Rect2(bc - Vector2(hr, hr), Vector2(hr, hr) * 2), Color(0.95, 0.78, 0.15))
		var x0 := bc.x - hr
		while x0 < bc.x + hr:
			var qd := PackedVector2Array([Vector2(x0, bc.y + hr), Vector2(minf(x0 + 8, bc.x + hr), bc.y + hr), Vector2(minf(x0 + 8, bc.x + hr), bc.y + hr - 6)])
			draw_colored_polygon(qd, Color(0.1, 0.1, 0.1))
			x0 += 16.0
		for sc in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			draw_circle(bc + sc * (hr - 6), 3.0, Color(0.3, 0.3, 0.32))
		draw_circle(bc, 34.0 * k2, Color(0.15, 0.15, 0.17))
		draw_circle(bc, 30.0 * k2, Color(0.3, 0.3, 0.33))
		draw_circle(bc + Vector2(0, 3), 25.0 * k2, Color(0.4, 0.05, 0.04) if not pressed else Color(0.05, 0.35, 0.15))
		draw_circle(bc, 25.0 * k2, Color(0.9, 0.18, 0.12) if not pressed else Color(0.2, 0.95, 0.4))
		draw_circle(bc + Vector2(-8, -8) * k2, 8.0 * k2, Color(1, 1, 1, 0.3))
		var lb := Rect2(bc + Vector2(-48, hr + 6) * Vector2(k2, 1.0), Vector2(96 * k2, 16))
		draw_rect(lb, Color(0.1, 0.1, 0.11))
		draw_string(ThemeDB.fallback_font, lb.position + Vector2(0, 12), "DOOR RELEASE", HORIZONTAL_ALIGNMENT_CENTER, lb.size.x, 10, Color(0.95, 0.8, 0.2))
	else:
		var sr := Rect2(c + Vector2(-78, -76) * k2, Vector2(130, 84) * k2)
		draw_rect(sr.grow(7), Color(0.12, 0.13, 0.15))
		draw_rect(sr.grow(5), Color(0.22, 0.23, 0.26))
		draw_rect(sr, Color(0.02, 0.08, 0.05))
		for ln in 6:
			var w := 20.0 + fposmod(ln * 37.0 + t * 20.0, sr.size.x - 40.0)
			draw_line(sr.position + Vector2(8, 10 + ln * 11 * k2), sr.position + Vector2(8 + w, 10 + ln * 11 * k2), Color(0.3, 1.0, 0.6, 0.7), 2.0)
		if fposmod(t, 1.0) < 0.5:
			draw_rect(Rect2(sr.position + Vector2(8, sr.size.y - 12), Vector2(7, 6)), Color(0.3, 1.0, 0.6))
		draw_rect(sr, Color(0.3, 1.0, 0.6, 0.06))
		for kx in 4:
			for ky in 2:
				var kr := Rect2(Vector2(sr.position.x + kx * 20 * k2, sr.end.y + 12 + ky * 13), Vector2(16, 10) * Vector2(k2, 1.0))
				draw_rect(kr, Color(0.3, 0.32, 0.36))
				draw_rect(Rect2(kr.position, Vector2(kr.size.x, 2)), Color(0.45, 0.47, 0.52))
		var jp := c + Vector2(76, -34) * k2
		draw_circle(jp, 16.0 * k2, Color(0.18, 0.19, 0.21))
		draw_circle(jp, 12.0 * k2, Color(0.08, 0.08, 0.1))
		draw_circle(jp, 7.0 * k2, Color(0.2, 0.9, 1.0, 0.5 + 0.4 * sin(t * 4.0)))
		draw_string(ThemeDB.fallback_font, jp + Vector2(-30, 28 * k2), "JACK", HORIZONTAL_ALIGNMENT_CENTER, 60, 11, Color(0.4, 0.95, 1.0))


func _draw_torch(p: Vector2) -> void:
	# the reticle, the nozzle's flame when burning
	draw_arc(p, tol, 0.0, TAU, 24, Color(1.0, 0.9, 0.5, 0.45), 1.0)
	draw_line(p + Vector2(-16, 0), p + Vector2(-tol - 2, 0), Color(1.0, 0.9, 0.6, 0.8), 1.5)
	draw_line(p + Vector2(tol + 2, 0), p + Vector2(16, 0), Color(1.0, 0.9, 0.6, 0.8), 1.5)
	draw_line(p + Vector2(0, -16), p + Vector2(0, -tol - 2), Color(1.0, 0.9, 0.6, 0.8), 1.5)
	draw_line(p + Vector2(0, tol + 2), p + Vector2(0, 16), Color(1.0, 0.9, 0.6, 0.8), 1.5)
	if burning:
		draw_circle(p, 18.0 + sin(t * 40.0) * 2.0, Color(1.0, 0.55, 0.2, 0.35))
		draw_circle(p, 9.0, Color(1.0, 0.85, 0.55))
		draw_circle(p, 4.0, Color(1, 1, 1))
	elif over:
		draw_circle(p, 6.0, Color(1.0, 0.3, 0.2, 0.5 + 0.5 * sin(t * 10.0)))


func _draw_gauges(o: Vector2) -> void:
	_s(o, "PLATE HEAT", Color(1.0, 0.7, 0.35), 13)
	draw_rect(Rect2(o + Vector2(0, 10), Vector2(120, 12)), Color(0.12, 0.12, 0.15))
	draw_rect(Rect2(o + Vector2(0, 10), Vector2(120 * clampf(heat, 0.0, 1.0), 12)), Color(1.0, 0.3, 0.2) if over else Color(1.0, 0.6, 0.2))
	if over:
		_s(o + Vector2(0, 40), "too hot – the torch cools", Color(1.0, 0.45, 0.35), 11)
	_s(o + Vector2(0, 74), "ENERGY", Color(1.0, 0.82, 0.3), 13)
	var tt: Dictionary = GameState.gear.totals()
	draw_rect(Rect2(o + Vector2(0, 84), Vector2(120, 12)), Color(0.12, 0.12, 0.15))
	draw_rect(Rect2(o + Vector2(0, 84), Vector2(120 * clampf(GameState.gear.energy / maxf(float(tt["energy"]), 1.0), 0.0, 1.0), 12)), Color(1.0, 0.82, 0.3))
	_s(o + Vector2(0, 124), "CUT  %d %%" % int(cut_share() * 100.0), Color(0.85, 0.9, 1.0), 13)
	_s(o + Vector2(0, 160), "Engineering %d:" % skill, Color(0.7, 0.72, 0.76), 11)
	_s(o + Vector2(0, 174), "line width %.0f px" % (tol * 2.0), Color(0.7, 0.72, 0.76), 11)
