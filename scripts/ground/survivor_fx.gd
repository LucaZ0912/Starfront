extends RefCounted
## Survivor: what the weapons look like where a plain line or ring is not enough (Luz, 23 Nov 2026): the ultimates
## above all ("a real feast for the eyes"; then: "a full overload of the senses", every one of them beating in wild
## colours), the silverblade's trail, the drone, the plasma orbs, the numbers of damage. Only drawing: every function
## paints onto the canvas item it is given (the ground, the layer of light that adds itself to what is under it, or
## the layer over the figures); nothing in here knows the rules. All lengths are screen px.

## A weapon's own colour: its numbers of damage are written in it, and its effects lean on it.
const WCOL := {"pulse": Color(0.45, 0.85, 1.0), "laser": Color(1.0, 0.42, 0.36), "plasma": Color(0.5, 1.0, 0.7), "drone": Color(1.0, 0.8, 0.35), "superlaser": Color(1.0, 0.55, 0.78),
	"blade": Color(0.86, 0.93, 1.0), "mines": Color(1.0, 0.55, 0.3), "sentry": Color(0.6, 0.95, 1.0), "cryo": Color(0.7, 0.9, 1.0), "gravity": Color(0.78, 0.58, 1.0),
	"taser": Color(1.0, 0.92, 0.4), "blackhole": Color(1.0, 0.66, 0.32), "orbs": Color(1.0, 0.5, 0.9)}
const PLAIN := Color(1.0, 0.97, 0.9)

static var _bad := {}                  # shapes that could not be filled, by who asked (each is said once)


## A number between 0 and 1 that is always the same for the same `x` (for sparks and cracks that must not jump about).
static func h(x: float) -> float:
	return fposmod(sin(x * 12.9898) * 43758.5453, 1.0)


## A colour of the rainbow: `x` runs round it once from 0 to 1 (and on); `soft`: how pale (0: full colour).
## (Luz, 24 Nov 2026) Red and what is near it are left out: red on the ground is theirs alone. The colours run from
## gold through green, blue and violet to pink, and back the same way.
static func hue(x: float, soft: float = 0.25) -> Color:
	return Color.from_hsv(0.12 + 0.76 * (1.0 - absf(2.0 * fposmod(x, 1.0) - 1.0)), 1.0 - soft, 1.0)


## Fills a shape, if it is one: a shape too thin or folded over itself is left out (and named once), so that nothing
## breaks the picture.
static func fill(o: CanvasItem, pts: PackedVector2Array, col: Color, who: String) -> void:
	if Geometry2D.triangulate_polygon(pts).is_empty():
		if not _bad.has(who):
			_bad[who] = true
			print("SFX: a shape that cannot be filled (%s): %s" % [who, str(pts)])
		return
	o.draw_colored_polygon(pts, col)


## A ring of `count` dashes, each `part` of its share long.
static func dashes(o: CanvasItem, c: Vector2, r: float, a0: float, count: int, part: float, col: Color, w: float) -> void:
	var step := TAU / count
	for q in count:
		o.draw_arc(c, r, a0 + q * step, a0 + (q + part) * step, 5, col, w)


## … and one whose dashes run through the rainbow (`t` turns the colours round it).
static func rainbow_dashes(o: CanvasItem, c: Vector2, r: float, a0: float, count: int, part: float, t: float, alpha: float, w: float) -> void:
	var step := TAU / count
	for q in count:
		o.draw_arc(c, r, a0 + q * step, a0 + (q + part) * step, 5, Color(hue(float(q) / count + t), alpha), w)


## The corners of a shape with `sides` sides, closed.
static func poly(c: Vector2, r: float, sides: int, rot: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for q in sides + 1:
		pts.append(c + Vector2.from_angle(rot + q * TAU / sides) * r)
	return pts


## A star: `points` long rays, filled.
static func star(o: CanvasItem, c: Vector2, r_out: float, r_in: float, points: int, rot: float, col: Color) -> void:
	if r_out < 2.5:
		return                                                   # (too small to have a shape)
	var pts := PackedVector2Array()
	for q in points * 2:
		pts.append(c + Vector2.from_angle(rot + q * PI / points) * (r_out if q % 2 == 0 else r_in))
	fill(o, pts, col, "a star")


## Thin rays through a point, as a lens makes of a bright light.
static func flare(o: CanvasItem, c: Vector2, r: float, rot: float, rays: int, col: Color, w: float) -> void:
	for q in rays:
		var d := Vector2.from_angle(rot + q * PI / rays) * r
		o.draw_line(c - d, c + d, col, w)
		o.draw_line(c - d * 0.45, c + d * 0.45, Color(1, 1, 1, col.a), maxf(1.0, w * 0.5))


## A bolt of lightning from `a` to `b`: a jagged line (`seed` picks which; another seed, another bolt).
static func bolt(o: CanvasItem, a: Vector2, b: Vector2, seed: float, amp: float, col: Color, w: float) -> PackedVector2Array:
	var nrm := (b - a).orthogonal().normalized()
	var pts := PackedVector2Array([a])
	var parts := clampi(int(a.distance_to(b) / 22.0), 3, 9)
	for q in range(1, parts):
		pts.append(a.lerp(b, float(q) / parts) + nrm * (h(seed + q * 3.7) - 0.5) * 2.0 * amp)
	pts.append(b)
	o.draw_polyline(pts, col, w)
	o.draw_polyline(pts, Color(1, 1, 1, col.a), maxf(1.0, w * 0.35))
	return pts


## A trail behind something fast: `pts` from where it is now back to where it was, thinning and fading.
static func ribbon(o: CanvasItem, pts: PackedVector2Array, col: Color, w: float) -> void:
	var cnt := pts.size()
	for q in cnt - 1:
		var k := 1.0 - float(q) / maxf(1.0, cnt - 1.0)
		o.draw_line(pts[q], pts[q + 1], Color(col, col.a * k * k), maxf(1.0, w * k))


## … and one that runs through the rainbow along its length and beats: wider and narrower as the colours pass.
static func rainbow_ribbon(o: CanvasItem, pts: PackedVector2Array, t: float, alpha: float, w: float) -> void:
	var cnt := pts.size()
	for q in cnt - 1:
		var k := 1.0 - float(q) / maxf(1.0, cnt - 1.0)
		var beat := 0.65 + 0.35 * sin(t * 9.0 - q * 0.45)
		o.draw_line(pts[q], pts[q + 1], Color(hue(t * 0.7 - q * 0.022), alpha * sqrt(k)), maxf(1.0, w * (0.35 + 0.65 * k) * beat))


## Small lights that come and go on a ring (`rainbow`: each in a colour of its own).
static func glints(o: CanvasItem, c: Vector2, r: float, t: float, count: int, col: Color, size: float, rainbow: bool = false) -> void:
	for q in count:
		var k := fposmod(t * (0.6 + h(q * 1.9)) + h(q * 5.3), 1.0)
		var p := c + Vector2.from_angle(h(q * 9.1) * TAU + t * 0.3) * r
		var s := size * sin(k * PI)
		if s < 2.5:
			continue
		var gc: Color = hue(float(q) / count + t * 0.4, 0.15) if rainbow else col
		fill(o, PackedVector2Array([p + Vector2(0.0, -s), p + Vector2(s * 0.5, 0.0), p + Vector2(0.0, s), p + Vector2(-s * 0.5, 0.0)]), Color(gc, col.a * sin(k * PI)), "a glint")


## A snow crystal: six arms, each with two small branches.
static func crystal(o: CanvasItem, c: Vector2, r: float, rot: float, col: Color) -> void:
	for q in 6:
		var d := Vector2.from_angle(rot + q * PI / 3.0)
		o.draw_line(c, c + d * r, col, 1.5)
		o.draw_line(c + d * r * 0.55, c + d * r * 0.55 + d.rotated(0.9) * r * 0.32, col, 1.0)
		o.draw_line(c + d * r * 0.55, c + d * r * 0.55 + d.rotated(-0.9) * r * 0.32, col, 1.0)


# ---------------------------------------------------------------- the numbers of damage

## What a hit took, over the head of whoever it hit: it jumps up, stands a moment, fades. `k`: how far through its
## time (0 … 1); `hard`: a hit that struck twice as hard; `shield`: a shield took it.
static func number(o: CanvasItem, font: Font, at: Vector2, val: int, col: Color, k: float, hard: bool, shield: bool) -> void:
	var size := 17 if val < 20 else (21 if val < 60 else (26 if val < 200 else 32))
	if hard:
		size += 5
	if k < 0.12:
		size += int(8.0 * (1.0 - k / 0.12))                 # (it comes in large)
	var rise := 34.0 * (1.0 - pow(1.0 - k, 2.0))
	var alpha := clampf((1.0 - k) * 3.0, 0.0, 1.0)
	var c := Color(0.6, 0.82, 1.0) if shield else col
	var txt := str(val) + ("!" if hard else "")
	var p := at + Vector2(-60.0, -rise)
	o.draw_string_outline(font, p, txt, HORIZONTAL_ALIGNMENT_CENTER, 120.0, size, 5, Color(0.03, 0.03, 0.06, alpha * 0.9))
	o.draw_string(font, p, txt, HORIZONTAL_ALIGNMENT_CENTER, 120.0, size, Color(c, alpha))


# ---------------------------------------------------------------- the pulse: the Nova Field

## The Nova Field on the ground: a field of light that stands and runs through every colour: ripples running out in
## it, two lattices turning against each other, a rim of dashes; `beat`: 1 at the moment it burns, falling to 0.
static func nova_ground(o: CanvasItem, c: Vector2, r: float, t: float, beat: float) -> void:
	var base := t * 0.22
	o.draw_circle(c, r, Color(hue(base, 0.35), 0.1 + 0.05 * beat))
	o.draw_circle(c, r * 0.62, Color(hue(base + 0.33, 0.35), 0.07 + 0.08 * beat))
	o.draw_circle(c, r * 0.3, Color(hue(base + 0.66, 0.35), 0.07 + 0.1 * beat))
	for q in 4:
		var k := fposmod(t * 0.6 + q / 4.0, 1.0)
		o.draw_arc(c, r * k, 0.0, TAU, 56, Color(hue(base + k * 0.8, 0.2), 0.55 * sin(k * PI)), 2.5)
	var outer := poly(c, r * 0.8, 6, t * 0.25)
	var inner := poly(c, r * 0.5, 6, -t * 0.4)
	var third := poly(c, r * 0.8, 6, t * 0.25 + PI / 6.0)
	o.draw_polyline(outer, Color(hue(base + 0.15, 0.2), 0.5), 2.0)
	o.draw_polyline(third, Color(hue(base + 0.5, 0.2), 0.35), 1.5)
	o.draw_polyline(inner, Color(hue(base + 0.8, 0.2), 0.55), 2.0)
	for q2 in 6:
		o.draw_line(inner[q2], outer[q2], Color(hue(base + q2 / 6.0, 0.2), 0.3), 1.5)
		o.draw_line(outer[q2], c + (outer[q2] - c) * 1.25, Color(hue(base + q2 / 6.0 + 0.5, 0.1), 0.45), 2.5)
	rainbow_dashes(o, c, r, t * 0.6, 28, 0.55, base, 0.75 + 0.25 * beat, 3.5)
	rainbow_dashes(o, c, r * 0.93, -t * 0.9, 16, 0.3, -base, 0.6, 2.0)
	o.draw_arc(c, r * (1.0 + 0.07 * (1.0 - beat)), 0.0, TAU, 64, Color(hue(base + 0.5, 0.1), 0.6 * beat), 5.0)
	o.draw_arc(c, r * (1.0 + 0.16 * (1.0 - beat)), 0.0, TAU, 64, Color(hue(base, 0.1), 0.3 * beat), 2.0)


static func nova_glow(o: CanvasItem, gt: Texture2D, c: Vector2, r: float, t: float, beat: float) -> void:
	var base := t * 0.22
	o.draw_texture_rect(gt, Rect2(c - Vector2(r, r) * 1.25, Vector2(r, r) * 2.5), false, Color(hue(base, 0.3), 0.22 + 0.22 * beat))
	o.draw_texture_rect(gt, Rect2(c - Vector2(r, r) * 0.6, Vector2(r, r) * 1.2), false, Color(hue(base + 0.5, 0.3), 0.18 + 0.2 * beat))
	for q0 in 12:                                              # its rim: twelve stretches of colour, running round
		o.draw_arc(c, r, q0 * TAU / 12.0 + t * 0.5, (q0 + 1) * TAU / 12.0 + t * 0.5, 8, Color(hue(base + q0 / 12.0, 0.15), 0.3 + 0.25 * beat), 10.0)
	glints(o, c, r, t, 18, Color(1, 1, 1, 0.95), 10.0, true)
	for q in 12:                                               # motes of light rising in it
		var k := fposmod(t * 0.5 + h(q * 2.7), 1.0)
		var p := c + Vector2((h(q * 4.1) - 0.5) * r * 1.4, (h(q * 6.3) - 0.5) * r * 1.2 - k * 46.0)
		o.draw_rect(Rect2(p, Vector2(3.0, 3.0)), Color(hue(base + q / 12.0, 0.2), 0.9 * sin(k * PI)))


# ---------------------------------------------------------------- the laser: the Prism Array

## A beam of the Prism Array: split light. `hop`: 0 from you, 1 and 2 where it jumps on; `k`: 1 fresh … 0 gone.
static func prism_over(o: CanvasItem, a: Vector2, b: Vector2, hop: int, k: float, t: float) -> void:
	var col := hue(t * 0.9 + hop * 0.33, 0.15)
	var nrm := (b - a).orthogonal().normalized()
	for q in 3:                                                # (the fringes of colour beside it)
		var off := (q - 1) * 5.0
		o.draw_line(a + nrm * off, b + nrm * off, Color(hue(t * 0.9 + hop * 0.33 + q * 0.33, 0.05), 0.6 * k), 2.5)
	o.draw_line(a, b, Color(col, 0.9 * k), 8.0 - hop)
	o.draw_line(a, b, Color(1, 1, 1, k), 2.5)
	flare(o, b, 30.0 * k, t * 6.0 + hop, 3, Color(col, k), 3.0)
	star(o, b, 11.0 * k, 3.5 * k, 4, PI * 0.25 + t * 3.0, Color(1, 1, 1, k))
	if hop == 0:
		flare(o, a, 16.0 * k, -t * 5.0, 2, Color(col, 0.8 * k), 2.0)


static func prism_glow(o: CanvasItem, gt: Texture2D, a: Vector2, b: Vector2, hop: int, k: float, t: float) -> void:
	var col := hue(t * 0.9 + hop * 0.33, 0.15)
	o.draw_line(a, b, Color(col, 0.45 * k), 22.0)
	o.draw_texture_rect(gt, Rect2(b - Vector2(46.0, 46.0), Vector2(92.0, 92.0)), false, Color(col, 0.95 * k))


# ---------------------------------------------------------------- bursts: the Plasma Rain, the Minefield

## A comet of plasma on its way down onto `to` (`k`: 0 high up … 1 there).
static func comet(o: CanvasItem, to: Vector2, k: float, col: Color) -> void:
	var fall := Vector2(-90.0, 760.0)
	var p := to - fall * (1.0 - k * k)
	var back := -fall.normalized()
	o.draw_line(p, p + back * 190.0, Color(col, 0.22), 14.0)
	o.draw_line(p, p + back * 120.0, Color(col, 0.75), 7.0)
	o.draw_line(p, p + back * 60.0, Color(1, 1, 1, 0.95), 3.0)
	o.draw_circle(p, 9.0, col)
	o.draw_circle(p, 4.5, Color(1, 1, 1))


## Where a comet will land: a ring of dashes closing in.
static func comet_mark(o: CanvasItem, to: Vector2, r: float, k: float, t: float, col: Color) -> void:
	dashes(o, to, r, t * 2.0, 10, 0.55, Color(col, 0.55 + 0.4 * k), 3.0)
	o.draw_arc(to, r * (1.0 - k), 0.0, TAU, 24, Color(col.lightened(0.4), 0.75), 2.0)
	o.draw_circle(to, r * k, Color(col, 0.12))
	o.draw_line(to + Vector2(-7.0, 0.0), to + Vector2(7.0, 0.0), Color(col, 0.8), 2.0)
	o.draw_line(to + Vector2(0.0, -7.0), to + Vector2(0.0, 7.0), Color(col, 0.8), 2.0)


static func burst_ground(o: CanvasItem, c: Vector2, r: float, k: float, col: Color) -> void:
	o.draw_circle(c, r * 0.9, Color(0.02, 0.03, 0.03, 0.3 * (1.0 - k)))       # (what it leaves on the ground for a moment)
	o.draw_circle(c, r * (0.3 + 0.7 * minf(1.0, k * 2.5)), Color(col, 0.3 * (1.0 - k)))
	o.draw_arc(c, r * (0.4 + 0.8 * k), 0.0, TAU, 48, Color(col.lightened(0.5), 0.95 * (1.0 - k)), 5.0)
	o.draw_arc(c, r * (0.15 + 1.25 * k), 0.0, TAU, 48, Color(col, 0.6 * (1.0 - k)), 2.0)
	o.draw_arc(c, r * (0.1 + 1.6 * k), 0.0, TAU, 48, Color(col.lightened(0.3), 0.35 * (1.0 - k)), 1.5)


static func burst_glow(o: CanvasItem, gt: Texture2D, c: Vector2, r: float, k: float, col: Color) -> void:
	var s := r * (1.6 + 1.2 * k)
	o.draw_texture_rect(gt, Rect2(c - Vector2(s, s), Vector2(s, s) * 2.0), false, Color(col, 0.85 * pow(1.0 - k, 2.0)))
	o.draw_texture_rect(gt, Rect2(c - Vector2(r, r) * 0.7, Vector2(r, r) * 1.4), false, Color(1, 1, 1, 0.9 * pow(1.0 - k, 3.0)))


## Sparks flying out of a burst, embers rising from it (`seed`: which burst this is).
static func burst_over(o: CanvasItem, c: Vector2, r: float, k: float, col: Color, seed: float) -> void:
	for q in 14:
		var d := Vector2.from_angle(h(seed + q * 1.7) * TAU)
		var far := r * (0.5 + 0.9 * h(seed + q * 4.3))
		var p0 := c + d * far * k * 0.75 + Vector2(0.0, -14.0 * sin(k * PI))
		var p1 := c + d * far * minf(1.0, k * 1.25) + Vector2(0.0, -20.0 * sin(k * PI))
		o.draw_line(p0, p1, Color(col.lightened(0.4), 0.95 * (1.0 - k)), 2.5)
	for q2 in 8:
		var e := c + Vector2((h(seed + q2 * 2.9) - 0.5) * r * 1.3, (h(seed + q2 * 7.7) - 0.5) * r * 0.9 - k * 50.0)
		o.draw_rect(Rect2(e, Vector2(3.0, 3.0)), Color(col.lightened(0.3), 0.9 * (1.0 - k)))


## The Minefield: light running from mine to mine of one ring, in every colour (`pts` in their order round it; a gap
## where one is gone).
static func mine_links(o: CanvasItem, pts: Array, t: float) -> void:
	var cnt := pts.size()
	for q in cnt:
		if pts[q] == null or pts[(q + 1) % cnt] == null:
			continue
		var a: Vector2 = pts[q]
		var b: Vector2 = pts[(q + 1) % cnt]
		var col := hue(t * 0.5 + float(q) / cnt, 0.15)
		o.draw_line(a, b, Color(col, 0.14), 10.0)
		o.draw_line(a, b, Color(col, 0.6 + 0.25 * sin(t * 5.0 + q)), 2.5)
		var k := fposmod(t * 0.9 + q * 0.13, 1.0)
		o.draw_circle(a.lerp(b, k), 4.0, Color(1, 1, 1, 0.95))
		o.draw_arc(a, 15.0, 0.0, TAU, 16, Color(col, 0.55), 2.0)


# ---------------------------------------------------------------- the drone: the Carrier Swarm

## The drone as it hovers: its shadow on the ground under it, itself above; `aim`: the way its gun looks; `fire`:
## it has just fired; `swarm`: one of the Carrier Swarm (a brighter light).
static func drone(o: CanvasItem, tex: Texture2D, at: Vector2, lift: float, aim: float, fire: bool, swarm: bool) -> void:
	o.draw_set_transform(at, 0.0, Vector2(1.0, 0.4))
	o.draw_circle(Vector2.ZERO, 16.0, Color(0, 0, 0, 0.3))
	o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var c := at + Vector2(0.0, -lift)
	var gun := Vector2(cos(aim), sin(aim) * 0.6)
	var root := c + Vector2(0.0, 6.0)
	if gun.y < 0.0:                                            # (its gun looks away from us: behind its body)
		o.draw_line(root, root + gun * 24.0, Color(0.12, 0.13, 0.17), 6.0)
	var sz := Vector2(tex.get_width(), tex.get_height()) * 3.0
	o.draw_texture_rect(tex, Rect2(c - sz * 0.5, sz), false)
	if gun.y >= 0.0:
		o.draw_line(root, root + gun * 24.0, Color(0.12, 0.13, 0.17), 6.0)
		o.draw_line(root + gun * 18.0, root + gun * 24.0, Color(1.0, 0.8, 0.35) if swarm else Color(0.4, 0.9, 1.0), 3.0)
	if fire:
		star(o, root + gun * 30.0, 13.0, 4.0, 4, aim, Color(1.0, 0.95, 0.7))


## One of the drone's shots: a short streak; one that goes through whoever it hits: a long bright one in `col`.
static func tracer(o: CanvasItem, p: Vector2, dir: Vector2, pierce: bool, col: Color) -> void:
	if pierce:
		o.draw_line(p - dir * 34.0, p, Color(col, 0.75), 5.0)
		o.draw_line(p - dir * 20.0, p, Color(1.0, 0.97, 0.9), 2.5)
		o.draw_circle(p, 3.5, Color(1, 1, 1))
	else:
		o.draw_line(p - dir * 14.0, p, Color(1.0, 0.8, 0.35, 0.85), 3.0)
		o.draw_circle(p, 3.0, Color(1.0, 1.0, 0.8))


# ---------------------------------------------------------------- the superlaser: the Sunlance

## The Sunlance: a beam like a sun's, turning the whole round: what it leaves behind for a moment (running through
## the colours as it cools), the beam itself, filaments of colour flickering along it, a sun at its root. `way`: +1
## or -1, the way it turns; `a0`: where it began.
static func sun_over(o: CanvasItem, so: Vector2, a: float, reach: float, way: float, a0: float, t: float) -> void:
	for q in range(22, 0, -1):
		var ta := a - way * q * 0.035
		if (ta - a0) * way < 0.0:
			continue
		o.draw_line(so, so + Vector2.from_angle(ta) * reach, Color(hue(0.08 + q * 0.035, 0.1), 0.2 * (1.0 - q / 23.0)), 26.0)
	var se := so + Vector2.from_angle(a) * reach
	var nrm := Vector2.from_angle(a).orthogonal()
	var throb := 1.0 + 0.12 * sin(t * 30.0)
	o.draw_line(so, se, Color(1.0, 0.45, 0.12, 0.5), 52.0 * throb)
	o.draw_line(so, se, Color(1.0, 0.78, 0.3, 0.92), 30.0 * throb)
	o.draw_line(so, se, Color(1.0, 0.97, 0.85), 13.0)
	for q3 in 4:                                               # filaments of colour winding along it
		var off := (q3 - 1.5) * 11.0
		bolt(o, so + nrm * off, se + nrm * off, floor(t * 40.0) + q3 * 50.0, 8.0, Color(hue(t * 1.3 + q3 * 0.25, 0.1), 0.85), 2.5)
	for q2 in 18:                                              # sparks thrown off it
		var u := h(q2 * 7.3 + floor(t * 24.0))
		var sp := so.lerp(se, u) + nrm * (h(q2 * 3.1 + floor(t * 24.0)) - 0.5) * 90.0
		o.draw_rect(Rect2(sp, Vector2(3.0, 3.0)), Color(hue(u + t, 0.2), 0.95))
	o.draw_circle(so, 24.0, Color(1.0, 0.85, 0.45))
	o.draw_circle(so, 14.0, Color(1.0, 1.0, 0.92))
	flare(o, so, 62.0, t * 3.0, 6, Color(hue(t * 0.8, 0.2), 0.85), 3.0)
	flare(o, se, 34.0, -t * 5.0, 3, Color(hue(t * 0.8 + 0.5, 0.2), 0.9), 3.0)


static func sun_glow(o: CanvasItem, gt: Texture2D, so: Vector2, a: float, reach: float, t: float) -> void:
	var se := so + Vector2.from_angle(a) * reach
	o.draw_line(so, se, Color(1.0, 0.55, 0.15, 0.3), 86.0)
	o.draw_line(so, se, Color(hue(t * 0.8, 0.2), 0.16), 120.0)
	o.draw_texture_rect(gt, Rect2(so - Vector2(130.0, 130.0), Vector2(260.0, 260.0)), false, Color(1.0, 0.75, 0.3, 0.9))
	o.draw_texture_rect(gt, Rect2(se - Vector2(80.0, 80.0), Vector2(160.0, 160.0)), false, Color(hue(t * 0.8 + 0.5, 0.2), 0.85))


## What the Sunlance burns into the ground where its beam ends.
static func sun_ground(o: CanvasItem, c: Vector2, a: float, reach: float, way: float, a0: float) -> void:
	var back := minf(absf(a - a0), 1.5)
	o.draw_arc(c, reach, a - way * back, a, 32, Color(1.0, 0.92, 0.4, 0.55), 7.0)
	o.draw_arc(c, reach - 9.0, a - way * back * 0.6, a, 24, Color(1.0, 0.85, 0.5, 0.55), 2.5)


# ---------------------------------------------------------------- the silverblade: its trail, the Silver Storm

## A silverblade: a star of steel spinning, bright at its heart (`rim`: the colour of its edge).
static func blade(o: CanvasItem, c: Vector2, spin: float, r: float, rim: Color) -> void:
	star(o, c, r, r * 0.3, 4, spin, Color(0.86, 0.9, 0.96))
	var edge := PackedVector2Array()
	for q in 9:
		edge.append(c + Vector2.from_angle(spin + q * PI * 0.25) * (r if q % 2 == 0 else r * 0.3))
	o.draw_polyline(edge, rim, 2.0)
	o.draw_circle(c, r * 0.22, Color(1, 1, 1))


# ---------------------------------------------------------------- the plasma orbs: the Fusion Halo

## The round the orbs keep to, on the ground (`halo`: the Fusion Halo: every colour).
static func orbs_ground(o: CanvasItem, c: Vector2, r: float, t: float, halo: bool) -> void:
	if halo:
		rainbow_dashes(o, c, r, t * 0.8, 24, 0.5, t * 0.3, 0.4, 2.5)
		glints(o, c, r, t, 12, Color(1, 1, 1, 0.9), 8.0, true)
	else:
		dashes(o, c, r, t * 0.8, 24, 0.5, Color(1.0, 0.5, 0.9, 0.22), 2.0)
		glints(o, c, r, t, 8, Color(1.0, 0.8, 0.95, 0.8), 6.0)


## An orb of plasma: a white heart, a shell of colour, small arcs of lightning creeping over it.
static func orb(o: CanvasItem, c: Vector2, r: float, col: Color, t: float, seed: float) -> void:
	o.draw_circle(c, r, Color(col, 0.55))
	o.draw_circle(c, r * 0.68, col.lightened(0.35))
	o.draw_circle(c, r * 0.36, Color(1, 1, 1))
	for q in 3:
		var a := h(seed + q * 2.1 + floor(t * 14.0)) * TAU
		bolt(o, c + Vector2.from_angle(a) * r * 0.4, c + Vector2.from_angle(a + 0.9) * r * 1.35, seed + q + floor(t * 14.0), 4.0, Color(col.lightened(0.5), 0.9), 1.5)
	o.draw_arc(c, r * 1.15, t * 6.0 + seed, t * 6.0 + seed + 2.0, 10, Color(col.lightened(0.3), 0.8), 2.0)


static func orb_glow(o: CanvasItem, gt: Texture2D, c: Vector2, r: float, col: Color) -> void:
	o.draw_texture_rect(gt, Rect2(c - Vector2(r, r) * 3.0, Vector2(r, r) * 6.0), false, Color(col, 0.75))
	o.draw_texture_rect(gt, Rect2(c - Vector2(r, r) * 1.4, Vector2(r, r) * 2.8), false, Color(1, 1, 1, 0.7))


## The Fusion Halo bursts: a ring of plasma running out (`k`: how far it has run, 0 … 1).
static func halo_ground(o: CanvasItem, c: Vector2, r: float, k: float, t: float) -> void:
	rainbow_dashes(o, c, r, t * 2.0, 36, 0.8, t * 0.6, 0.95 * (1.0 - k), 7.0 * (1.0 - k) + 2.0)
	o.draw_arc(c, r - 9.0, 0.0, TAU, 64, Color(1, 1, 1, 0.6 * (1.0 - k)), 2.0)
	o.draw_arc(c, r + 12.0, 0.0, TAU, 64, Color(hue(t * 0.6 + 0.5, 0.2), 0.35 * (1.0 - k)), 3.0)


# ---------------------------------------------------------------- the sentry: the Battery

## The Battery: a field of light between its three guns, light from gun to gun and from each to you, rings turning
## under each: all of it running through the colours.
static func battery_ground(o: CanvasItem, you: Vector2, guns: Array, t: float) -> void:
	var cnt := guns.size()
	var base := t * 0.3
	if cnt == 3:
		var ga: Vector2 = guns[0]
		var gb: Vector2 = guns[1]
		var gc: Vector2 = guns[2]
		if absf((gb - ga).cross(gc - ga)) > 40.0:
			fill(o, PackedVector2Array([ga, gb, gc]), Color(hue(base, 0.3), 0.1 + 0.04 * sin(t * 3.0)), "the Battery's field")
	for q in cnt:
		var a: Vector2 = guns[q]
		var col := hue(base + float(q) / maxf(1.0, cnt), 0.2)
		o.draw_circle(a, 30.0, Color(col, 0.12))
		rainbow_dashes(o, a, 30.0, t * 1.5 + q, 10, 0.55, base + q * 0.2, 0.9, 3.0)
		dashes(o, a, 22.0, -t * 2.2 + q, 6, 0.4, Color(1, 1, 1, 0.6), 2.0)
		o.draw_line(a, you, Color(col, 0.25 + 0.1 * sin(t * 4.0 + q)), 2.0)
		o.draw_circle(a.lerp(you, fposmod(t * 1.1 + q * 0.37, 1.0)), 3.0, Color(1, 1, 1, 0.7))
		if cnt > 1:
			var b: Vector2 = guns[(q + 1) % cnt]
			o.draw_line(a, b, Color(col, 0.16), 10.0)
			o.draw_line(a, b, Color(col, 0.65 + 0.2 * sin(t * 3.0 + q * 2.0)), 2.5)
			o.draw_circle(a.lerp(b, fposmod(t * 0.7 + q * 0.3, 1.0)), 4.0, Color(1, 1, 1, 0.95))


## A shot of the Battery: thicker than a single gun's, a small star where it strikes.
static func battery_shot(o: CanvasItem, a: Vector2, b: Vector2, k: float, col: Color) -> void:
	o.draw_line(a, b, Color(col, 0.85 * k), 7.0)
	o.draw_line(a, b, Color(0.95, 1.0, 1.0, k), 3.0)
	flare(o, b, 22.0 * k, 0.4, 2, Color(col, k), 2.5)
	star(o, b, 12.0 * k, 4.0 * k, 4, 0.0, Color(0.9, 1.0, 1.0, k))


## … and the light of it: a glow under each gun.
static func battery_glow(o: CanvasItem, gt: Texture2D, guns: Array, t: float) -> void:
	for q in guns.size():
		var a: Vector2 = guns[q]
		o.draw_texture_rect(gt, Rect2(a - Vector2(46.0, 46.0), Vector2(92.0, 92.0)), false, Color(hue(t * 0.3 + float(q) / maxf(1.0, guns.size()), 0.2), 0.55 + 0.15 * sin(t * 4.0 + q)))


# ---------------------------------------------------------------- the cryo: Absolute Zero

## Absolute Zero: a wave of cold running out all round: a front of ice, spikes on it, crystals in what it has
## crossed; the light of the north in it (the colours of ice: cyan to violet).
static func zero_ground(o: CanvasItem, c: Vector2, r: float, k: float, seed: float) -> void:
	o.draw_circle(c, r, Color(0.6, 0.9, 1.0, 0.18 * (1.0 - k)))
	o.draw_arc(c, r, 0.0, TAU, 72, Color(0.9, 0.98, 1.0, 0.95 * (1.0 - k)), 5.0)
	for q0 in 3:                                               # bands of northern light behind the front
		o.draw_arc(c, r * (0.86 - q0 * 0.12), 0.0, TAU, 56, Color(hue(0.5 + 0.12 * q0 + k * 0.2, 0.25), 0.5 * (1.0 - k)), 4.0 - q0)
	for q in 36:                                               # spikes of ice on its front
		var d := Vector2.from_angle(q * TAU / 36.0 + seed)
		var tall := 12.0 + 20.0 * h(seed + q * 2.3)
		var side := d.orthogonal() * 5.0
		fill(o, PackedVector2Array([c + d * (r - 6.0) + side, c + d * (r + tall), c + d * (r - 6.0) - side]), Color(hue(0.5 + 0.3 * h(seed + q * 1.1), 0.6), 0.9 * (1.0 - k)), "a spike of ice")
	for q2 in 18:                                              # crystals in what it has crossed
		var p := c + Vector2.from_angle(h(seed + q2 * 5.1) * TAU) * r * (0.2 + 0.7 * h(seed + q2 * 8.7))
		crystal(o, p, 7.0 + 9.0 * h(seed + q2 * 3.3), k * 1.5 + q2, Color(hue(0.5 + 0.35 * h(seed + q2 * 6.6), 0.55), 0.95 * (1.0 - k)))


## What Absolute Zero leaves on the ground for a while: cracks in the frost, running out from where you stood.
static func frost_ground(o: CanvasItem, c: Vector2, r: float, k: float, seed: float) -> void:
	var a := 0.5 * (1.0 - k)
	o.draw_circle(c, r, Color(0.7, 0.92, 1.0, 0.1 * (1.0 - k)))
	o.draw_arc(c, r, 0.0, TAU, 64, Color(0.85, 0.97, 1.0, a), 2.0)
	for q in 12:
		var ang := q * TAU / 12.0 + seed
		var pts := PackedVector2Array([c + Vector2.from_angle(ang) * r * 0.12])
		for s in range(1, 6):
			pts.append(c + Vector2.from_angle(ang + (h(seed + q * 3.1 + s) - 0.5) * 0.3) * r * (0.12 + 0.17 * s))
		var col := hue(0.5 + 0.3 * h(seed + q * 0.7), 0.6)
		o.draw_polyline(pts, Color(col, a), 1.5)
		o.draw_line(pts[3], pts[3] + Vector2.from_angle(ang + 0.8) * r * 0.14, Color(col, a * 0.8), 1.0)


# ---------------------------------------------------------------- the gravity well: the Singularity

## The Singularity: a dark heart, arms of light of every colour winding into it, motes falling in, light bent round
## it.
static func sing_over(o: CanvasItem, c: Vector2, r: float, t: float, grow: float) -> void:
	for arm in 5:
		var pts := PackedVector2Array()
		for s in 15:
			var u := s / 14.0
			pts.append(c + Vector2.from_angle(t * 2.6 + arm * TAU / 5.0 + u * 2.8) * lerpf(22.0 * grow, r * 0.9, u) * Vector2(1.0, 0.62))
		o.draw_polyline(pts, Color(hue(t * 0.4 + arm / 5.0, 0.15), 0.7), 3.5)
		o.draw_polyline(pts, Color(1.0, 0.95, 1.0, 0.5), 1.0)
	for q in 26:
		var u2 := fposmod(h(q * 1.3) + t * 0.8, 1.0)
		var p := c + Vector2.from_angle(h(q * 3.3) * TAU + u2 * 3.4 + t) * lerpf(r * 0.95, 20.0 * grow, u2) * Vector2(1.0, 0.62)
		o.draw_rect(Rect2(p, Vector2(3.0, 3.0)), Color(hue(h(q * 0.9) + t * 0.5, 0.2), 0.95 * sin(u2 * PI)))
	o.draw_circle(c, 21.0 * grow, Color(0.03, 0.0, 0.08))
	o.draw_arc(c, 21.0 * grow, 0.0, TAU, 32, Color(hue(t * 0.4, 0.3), 1.0), 3.0)
	o.draw_arc(c, 28.0 * grow, t * 3.0, t * 3.0 + 2.4, 14, Color(hue(t * 0.4 + 0.33, 0.2), 0.9), 2.5)
	o.draw_arc(c, 28.0 * grow, t * 3.0 + PI, t * 3.0 + PI + 2.4, 14, Color(hue(t * 0.4 + 0.66, 0.2), 0.9), 2.5)
	o.draw_arc(c, 36.0 * grow, -t * 2.0, -t * 2.0 + 1.4, 10, Color(1.0, 0.9, 1.0, 0.6), 1.5)
	o.draw_arc(c, 44.0 * grow, t * 1.4, t * 1.4 + 1.0, 10, Color(hue(t * 0.4 + 0.5, 0.2), 0.5), 1.5)


## The Singularity crushes what it pulled in: all falls to a point, then rings of force run out in every colour.
static func crush_over(o: CanvasItem, c: Vector2, r: float, k: float) -> void:
	if k < 0.35:
		var u := k / 0.35
		o.draw_arc(c, r * (1.0 - u), 0.0, TAU, 48, Color(0.9, 0.75, 1.0, 0.9), 4.0)
		for q in 14:
			var d := Vector2.from_angle(q * TAU / 14.0)
			o.draw_line(c + d * r * (1.0 - u), c + d * r * (1.0 - u) * 0.6, Color(hue(q / 14.0, 0.2), 0.9), 2.0)
	else:
		var u2 := (k - 0.35) / 0.65
		for q2 in 3:
			o.draw_arc(c, r * (1.4 - q2 * 0.28) * u2, 0.0, TAU, 64, Color(hue(q2 * 0.33 + u2, 0.15), 0.95 * (1.0 - u2)), 8.0 * (1.0 - u2) + 1.0)
		flare(o, c, r * 0.9 * (1.0 - u2), 0.4, 4, Color(1.0, 0.9, 1.0, 1.0 - u2), 3.0)


# ---------------------------------------------------------------- the taser, Chain Lightning

## The Taser's shock: a cone of lightning from you, the way you look (`a`), `r` long, `arc` half its angle; `k`: 1
## fresh … 0 gone; `frame`: which flicker.
static func taser_over(o: CanvasItem, c: Vector2, a: float, r: float, arc: float, k: float, frame: float) -> void:
	o.draw_line(c, c + Vector2.from_angle(a - arc) * r, Color(1.0, 0.9, 0.4, 0.5 * k), 2.0)
	o.draw_line(c, c + Vector2.from_angle(a + arc) * r, Color(1.0, 0.9, 0.4, 0.5 * k), 2.0)
	o.draw_arc(c, r, a - arc, a + arc, 14, Color(1.0, 0.9, 0.4, 0.7 * k), 2.5)
	for q in 7:
		var at := a + (h(frame * 1.7 + q * 3.1) * 2.0 - 1.0) * arc * 0.92
		var far := r * (0.72 + 0.28 * h(frame * 2.3 + q * 5.7))
		bolt(o, c, c + Vector2.from_angle(at) * far, frame * 3.1 + q * 11.0, 7.0, Color(1.0, 0.92, 0.35, k), 3.0)
		star(o, c + Vector2.from_angle(at) * far, 6.0 * k, 2.0 * k, 4, frame + q, Color(1, 1, 0.9, k))


static func taser_glow(o: CanvasItem, gt: Texture2D, c: Vector2, a: float, r: float, arc: float, k: float) -> void:
	var fan := PackedVector2Array([c])
	for q in 9:
		fan.append(c + Vector2.from_angle(a - arc + q * arc * 0.25) * r)
	fill(o, fan, Color(1.0, 0.9, 0.4, 0.3 * k), "the taser's cone")
	var mid := c + Vector2.from_angle(a) * r * 0.6
	o.draw_texture_rect(gt, Rect2(mid - Vector2(r, r) * 0.8, Vector2(r, r) * 1.6), false, Color(1.0, 0.95, 0.5, 0.7 * k))


## A jump of the Chain Lightning: bolts over one another in changing colours, forks off it, a star where it strikes.
static func chain_over(o: CanvasItem, a: Vector2, b: Vector2, k: float, seed: float) -> void:
	var col := hue(h(seed * 0.37) * 0.6 + 0.1, 0.2)
	var pts := bolt(o, a, b, seed, 14.0, Color(col, k), 6.0)
	bolt(o, a, b, seed + 31.0, 10.0, Color(hue(h(seed * 0.37) * 0.6 + 0.45, 0.2), 0.8 * k), 3.0)
	bolt(o, a, b, seed + 63.0, 7.0, Color(1.0, 1.0, 0.85, 0.7 * k), 1.5)
	var mid: Vector2 = pts[pts.size() / 2]
	var along := (b - a).normalized()
	bolt(o, mid, mid + along.rotated(0.9) * (20.0 + 16.0 * h(seed + 2.0)), seed + 7.0, 5.0, Color(col, 0.85 * k), 2.0)
	bolt(o, mid, mid + along.rotated(-0.8) * (16.0 + 14.0 * h(seed + 5.0)), seed + 9.0, 5.0, Color(col, 0.7 * k), 2.0)
	flare(o, b, 22.0 * k, seed, 3, Color(col, k), 2.5)
	star(o, b, 10.0 * k, 3.5 * k, 4, seed, Color(1, 1, 0.9, k))


static func chain_glow(o: CanvasItem, gt: Texture2D, a: Vector2, b: Vector2, k: float, seed: float) -> void:
	var col := hue(h(seed * 0.37) * 0.6 + 0.1, 0.2)
	o.draw_line(a, b, Color(col, 0.45 * k), 22.0)
	o.draw_texture_rect(gt, Rect2(b - Vector2(42.0, 42.0), Vector2(84.0, 84.0)), false, Color(col, 0.95 * k))


# ---------------------------------------------------------------- the Blackhole Gun: Event Horizon

## A black hole of the Event Horizon: a wider disc of light in three layers whose colours wander, streaks of every
## colour falling in along it, a ring of bent light close round the dark (`seed`: which of the three).
static func horizon_over(o: CanvasItem, c: Vector2, grow: float, t: float, seed: float) -> void:
	var base := t * 0.15 + seed
	o.draw_set_transform(c, -0.35, Vector2(1.0, 0.36))
	o.draw_arc(Vector2.ZERO, 66.0 * grow, 0.0, TAU, 48, Color(hue(base, 0.2), 0.4), 10.0)
	o.draw_arc(Vector2.ZERO, 50.0 * grow, 0.0, TAU, 48, Color(hue(base + 0.12, 0.25), 0.85), 8.0)
	o.draw_arc(Vector2.ZERO, 37.0 * grow, 0.0, TAU, 40, Color(1.0, 0.96, 0.85, 0.95), 5.0)
	for q in 14:
		var a0 := h(q * 2.1) * TAU + t * (2.0 + h(q * 4.7) * 2.0)
		o.draw_arc(Vector2.ZERO, (40.0 + 30.0 * h(q * 6.1)) * grow, a0, a0 + 0.7, 8, Color(hue(base + h(q * 1.3), 0.15), 0.9), 2.5)
	o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	o.draw_circle(c, 21.0 * grow, Color(0.0, 0.0, 0.0))
	o.draw_arc(c, 21.0 * grow, 0.0, TAU, 32, Color(1.0, 0.9, 0.7), 2.5)
	o.draw_arc(c, 26.0 * grow, PI * 1.05, PI * 1.95, 18, Color(hue(base + 0.25, 0.3), 0.85), 2.5)      # (light from behind it, bent over its top)
	o.draw_arc(c, 31.0 * grow, PI * 1.15, PI * 1.85, 14, Color(hue(base + 0.5, 0.3), 0.5), 1.5)
	o.draw_set_transform(c, -0.35, Vector2(1.0, 0.36))
	o.draw_arc(Vector2.ZERO, 50.0 * grow, 0.15, PI - 0.15, 28, Color(hue(base + 0.12, 0.25), 0.9), 8.0)
	o.draw_arc(Vector2.ZERO, 37.0 * grow, 0.15, PI - 0.15, 24, Color(1.0, 0.96, 0.85, 0.95), 5.0)
	o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## … and on the ground: what it draws in, as streaks towards its middle; the wake it leaves (`wake`: where it was).
static func horizon_ground(o: CanvasItem, c: Vector2, r: float, t: float, wake: PackedVector2Array, seed: float) -> void:
	ribbon(o, wake, Color(0.0, 0.0, 0.02, 0.5), 46.0)
	rainbow_ribbon(o, wake, t + seed, 0.45, 5.0)
	for q in 20:
		var u := fposmod(h(q * 1.7) + t * 0.9, 1.0)
		var d := Vector2.from_angle(h(q * 3.9) * TAU + u * 1.6)
		o.draw_line(c + d * lerpf(r, r * 0.2, u), c + d * lerpf(r, r * 0.2, minf(1.0, u + 0.12)), Color(hue(t * 0.15 + seed + h(q * 0.7) * 0.4, 0.2), 0.7 * sin(u * PI)), 2.0)


# ---------------------------------------------------------------- part 7f (Luz, 23 Nov 2026): what a crate's item looks like

const NUKE_LIFE := 3.4             # seconds from the Atomic Bomb's flash until its cloud has drifted away
const SCORCH_LIFE := 8.0           # … and how long the ground stays scorched


## The Atomic Bomb on the ground: the ring of force running out over it to the bomb's reach, dust thrown up along it
## (`t`: seconds since it went off).
static func nuke_ground(o: CanvasItem, c: Vector2, r: float, t: float) -> void:
	var k := clampf(t / 0.7, 0.0, 1.0)
	if k >= 1.0:
		return
	var rr := r * (0.1 + 0.9 * (1.0 - pow(1.0 - k, 2.0)))
	o.draw_circle(c, rr, Color(1.0, 0.72, 0.38, 0.16 * (1.0 - k)))
	o.draw_arc(c, rr, 0.0, TAU, 80, Color(1.0, 0.88, 0.62, 0.9 * (1.0 - k)), 28.0 * (1.0 - k * 0.5))
	o.draw_arc(c, rr * 0.93, 0.0, TAU, 80, Color(1.0, 0.92, 0.5, 0.5 * (1.0 - k)), 14.0)
	for q in 30:
		var a := q * TAU / 30.0 + h(q * 3.1)
		o.draw_circle(c + Vector2.from_angle(a) * rr * (0.95 + 0.07 * h(q * 7.7)), 7.0 + 10.0 * h(q * 1.3), Color(0.5, 0.42, 0.36, 0.42 * (1.0 - k)))


## … the earth it scorched: dark, streaks running out from the middle, embers that die down (`k`: 0 fresh … 1 gone).
static func scorch_ground(o: CanvasItem, c: Vector2, r: float, k: float, t: float) -> void:
	var a := 1.0 - k * k
	o.draw_set_transform(c, 0.0, Vector2(1.0, 0.6))
	o.draw_circle(Vector2.ZERO, r, Color(0.05, 0.03, 0.03, 0.3 * a))
	o.draw_circle(Vector2.ZERO, r * 0.7, Color(0.03, 0.02, 0.02, 0.4 * a))
	o.draw_circle(Vector2.ZERO, r * 0.38, Color(0.02, 0.01, 0.01, 0.5 * a))
	for q in 14:
		var d := Vector2.from_angle(q * TAU / 14.0 + h(q * 2.3))
		o.draw_line(d * r * 0.45, d * r * (1.05 + 0.35 * h(q * 4.1)), Color(0.04, 0.02, 0.02, 0.36 * a), 6.0)
	if k < 0.55:
		for q2 in 12:
			var ep := Vector2.from_angle(h(q2 * 6.1) * TAU) * r * (0.15 + 0.7 * h(q2 * 2.9))
			o.draw_circle(ep, 3.0, Color(1.0, 0.5, 0.15, (0.55 - k) * 1.6 * (0.5 + 0.5 * sin(t * 6.0 + q2 * 1.7))))
	o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## … its light: the flash over everything, the glow of the fire in its cloud.
static func nuke_glow(o: CanvasItem, gt: Texture2D, c: Vector2, r: float, t: float) -> void:
	if t < 0.9:
		var gr := r * 1.5
		o.draw_texture_rect(gt, Rect2(c - Vector2(gr, gr), Vector2(gr, gr) * 2.0), false, Color(1.0, 0.9, 0.7, 0.9 * (1.0 - t / 0.9)))
	var heat := clampf(1.0 - (t - 0.4) / 1.7, 0.0, 1.0)
	if t > 0.3 and heat > 0.0:
		var up := 330.0 * (1.0 - pow(1.0 - clampf((t - 0.3) / 1.2, 0.0, 1.0), 2.0))
		o.draw_texture_rect(gt, Rect2(c + Vector2(-230.0, -up - 230.0), Vector2(460.0, 460.0)), false, Color(1.0, 0.55, 0.2, 0.7 * heat))
		o.draw_texture_rect(gt, Rect2(c + Vector2(-150.0, -150.0), Vector2(300.0, 300.0)), false, Color(1.0, 0.5, 0.15, 0.5 * heat))


## … and what stands over the figures: the white flash, the ball of fire, then the cloud: a stem of smoke rising,
## a cap rolling out over it, a collar round the stem; it cools from fire to smoke, drifts aside and thins.
static func nuke_over(o: CanvasItem, c: Vector2, r: float, t: float) -> void:
	if t < 0.35:
		o.draw_circle(c, r * 1.8, Color(1.0, 1.0, 1.0, pow(1.0 - t / 0.35, 2.0)))
	var grow := clampf((t - 0.3) / 1.2, 0.0, 1.0)
	var eg := 1.0 - pow(1.0 - grow, 2.0)
	var out := clampf((t - 2.3) / (NUKE_LIFE - 2.3), 0.0, 1.0)
	var al := 1.0 - out
	var heat := clampf(1.0 - (t - 0.4) / 1.7, 0.0, 1.0)
	var drift := 70.0 * out
	var smoke := Color(0.34, 0.29, 0.28)
	var lit := Color(0.66, 0.56, 0.5)
	var fire := Color(1.0, 0.56, 0.16)
	if t < 1.0:                                                   # the ball of fire, swelling and rising
		var fk := clampf(t / 0.5, 0.0, 1.0)
		var fr := 30.0 + 130.0 * (1.0 - pow(1.0 - fk, 2.0))
		var fa := clampf((1.0 - t) / 0.5, 0.0, 1.0)
		var fc := c + Vector2(0.0, -40.0 - 120.0 * clampf(t / 1.0, 0.0, 1.0))
		o.draw_circle(fc, fr, Color(1.0, 0.4, 0.1, 0.85 * fa))
		o.draw_circle(fc, fr * 0.74, Color(1.0, 0.72, 0.22, 0.9 * fa))
		o.draw_circle(fc, fr * 0.42, Color(1.0, 0.97, 0.8, 0.95 * fa))
	if t < 0.3:
		return
	var rise := 330.0 * eg
	var cap := c + Vector2(drift, -rise - 30.0)
	var cap_r := (60.0 + 95.0 * eg) * (1.0 + 0.3 * out)
	for q in 10:                                                  # the stem: puffs one over the other, wide at its foot
		var sk := float(q) / 9.0
		var sp := (c + Vector2(0.0, -104.0)).lerp(cap + Vector2(0.0, cap_r * 0.3), sk) + Vector2(sin(t * 2.2 + q * 1.4) * 5.0 + drift * sk * 0.2, 0.0)      # (it begins over your head: you stay to be seen under it)
		var sr := (36.0 if q == 0 else 27.0 + 6.0 * sin(q * 2.1 + t * 1.5)) * (0.5 + 0.5 * minf(1.0, eg * 2.0))
		o.draw_circle(sp, sr, Color(smoke.lerp(fire, heat * 0.5), 0.92 * al))
		o.draw_circle(sp + Vector2(-sr * 0.24, -sr * 0.2), sr * 0.66, Color(lit.lerp(Color(1.0, 0.8, 0.4), heat * 0.6), 0.7 * al))
	o.draw_set_transform(cap + Vector2(0.0, cap_r * 0.22), 0.0, Vector2(1.0, 0.42))      # the cap's underside, in its own shadow
	o.draw_circle(Vector2.ZERO, cap_r * 0.95, Color(smoke.darkened(0.35), 0.9 * al))
	o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for q2 in 11:                                                 # the cap: lobes round its rim, rolling outwards
		var a := q2 * TAU / 11.0 + t * 0.5
		var lp := cap + Vector2(cos(a) * cap_r * 0.72, sin(a) * cap_r * 0.3 - cap_r * 0.08)
		var lr := cap_r * (0.4 + 0.07 * sin(q2 * 1.9 + t * 2.0))
		o.draw_circle(lp, lr, Color(smoke.lerp(fire, heat * 0.55), 0.95 * al))
	o.draw_circle(cap + Vector2(0.0, -cap_r * 0.18), cap_r * 0.74, Color(smoke.lerp(fire, heat * 0.6), 0.95 * al))
	for q3 in 11:                                                 # … lit from the upper left
		var a2 := q3 * TAU / 11.0 + t * 0.5
		var lp2 := cap + Vector2(cos(a2) * cap_r * 0.72, sin(a2) * cap_r * 0.3 - cap_r * 0.08)
		if lp2.y > cap.y + cap_r * 0.12:
			continue
		var lr2 := cap_r * (0.4 + 0.07 * sin(q3 * 1.9 + t * 2.0))
		o.draw_circle(lp2 + Vector2(-lr2 * 0.2, -lr2 * 0.24), lr2 * 0.62, Color(lit.lerp(Color(1.0, 0.86, 0.5), heat * 0.7), 0.75 * al))
	o.draw_circle(cap + Vector2(-cap_r * 0.16, -cap_r * 0.34), cap_r * 0.5, Color(lit.lerp(Color(1.0, 0.9, 0.6), heat * 0.7), 0.7 * al))
	if heat > 0.0:                                                # the fire still in it
		o.draw_circle(cap + Vector2(0.0, cap_r * 0.05), cap_r * 0.4, Color(1.0, 0.75, 0.3, 0.55 * heat * al))
		o.draw_circle(cap + Vector2(0.0, cap_r * 0.05), cap_r * 0.2, Color(1.0, 0.96, 0.8, 0.6 * heat * al))
	var col_y := c.y - rise * 0.52                              # the collar round the stem
	o.draw_set_transform(Vector2(c.x + drift * 0.5, col_y), 0.0, Vector2(1.0, 0.26))
	o.draw_arc(Vector2.ZERO, 70.0 + 50.0 * eg + 40.0 * out, 0.0, TAU, 40, Color(1.0, 1.0, 1.0, 0.55 * al * eg), 7.0)
	o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The Shield: a dome of six-sided cells round you, a wave of light running over them. `blink`: it is about to go;
## `hit`: 0 … 1, something has just struck it.
static func shield_dome(o: CanvasItem, c: Vector2, r: float, t: float, blink: bool, hit: float) -> void:
	var a := (0.35 + 0.5 * absf(sin(t * 12.0))) if blink else 0.9
	var col := Color(0.45, 0.9, 1.0).lerp(Color(1, 1, 1), hit)
	o.draw_circle(c, r, Color(col, 0.07 + 0.28 * hit))
	var cell := r * 0.25
	for row in range(-4, 5):
		for q in range(-4, 5):
			var p := Vector2((q + (0.5 if (row & 1) != 0 else 0.0)) * cell * 1.732, row * cell * 1.5)
			var d := p.length() / r
			if d > 0.93:
				continue
			var wave := 0.5 + 0.5 * sin(t * 5.0 - d * 7.0 + q * 0.7)
			o.draw_polyline(poly(c + p * (0.84 + 0.14 * d), cell * (0.98 - 0.26 * d * d), 6, PI / 6.0), Color(col, a * (0.22 + 0.58 * wave) * (0.4 + 0.6 * d)), 1.5)
	o.draw_arc(c, r, 0.0, TAU, 48, Color(col, a), 3.0 + 4.0 * hit)
	o.draw_arc(c, r * 0.9, PI * 1.12, PI * 1.55, 12, Color(1, 1, 1, a * 0.75), 2.5)


## The Magnet: lines of its field winding in to you from all round, light running in along them.
static func magnet_over(o: CanvasItem, c: Vector2, t: float, k: float) -> void:
	var col := Color(0.4, 1.0, 0.6)
	for q in 8:
		var a0 := q * TAU / 8.0 + t * 0.4
		var ph := fposmod(t * 1.3 + q * 0.37, 1.0)
		var pts := PackedVector2Array()
		for s in 9:
			var u := clampf(ph - 0.3 + s * 0.0375, 0.0, 1.0)      # (a stretch of the line, running inwards)
			pts.append(c + Vector2.from_angle(a0 + u * 1.7) * (300.0 * (1.0 - u) + 22.0))
		for s2 in pts.size() - 1:
			o.draw_line(pts[s2], pts[s2 + 1], Color(col, k * 0.85 * float(s2 + 1) / pts.size()), 1.0 + 3.0 * float(s2) / pts.size())
	o.draw_arc(c, 30.0 + 6.0 * sin(t * 9.0), 0.0, TAU, 28, Color(col, 0.7 * k), 2.5)


## The Medkit: crosses of green light rising round you (`k`: 0 … 1 of its moment).
static func heal_over(o: CanvasItem, c: Vector2, k: float) -> void:
	for q in 8:
		var qk := clampf(k * 1.4 - q * 0.05, 0.0, 1.0)
		if qk <= 0.0 or qk >= 1.0:
			continue
		var p := c + Vector2((h(q * 3.3) - 0.5) * 84.0, 6.0 - qk * (70.0 + 50.0 * h(q * 1.7)))
		var s := 6.0 + 6.0 * h(q * 5.1)
		var a := sin(qk * PI)
		o.draw_rect(Rect2(p + Vector2(-s, -s * 0.34), Vector2(s * 2.0, s * 0.68)), Color(0.35, 1.0, 0.5, a))
		o.draw_rect(Rect2(p + Vector2(-s * 0.34, -s), Vector2(s * 0.68, s * 2.0)), Color(0.35, 1.0, 0.5, a))
		o.draw_rect(Rect2(p + Vector2(-s * 0.6, -s * 0.14), Vector2(s * 1.2, s * 0.28)), Color(0.9, 1.0, 0.92, a))
		o.draw_rect(Rect2(p + Vector2(-s * 0.14, -s * 0.6), Vector2(s * 0.28, s * 1.2)), Color(0.9, 1.0, 0.92, a))


## … and the ring of it running out over the ground.
static func heal_ground(o: CanvasItem, c: Vector2, k: float) -> void:
	o.draw_circle(c, 30.0 + 120.0 * k, Color(0.35, 1.0, 0.5, 0.14 * (1.0 - k)))
	o.draw_arc(c, 30.0 + 120.0 * k, 0.0, TAU, 48, Color(0.5, 1.0, 0.6, 0.9 * (1.0 - k)), 6.0)
	o.draw_arc(c, 18.0 + 80.0 * k, 0.0, TAU, 40, Color(0.85, 1.0, 0.9, 0.6 * (1.0 - k)), 2.0)


## Stasis: the wave of it running out over the ground when it begins (`k`: 0 … 1).
static func stasis_ground(o: CanvasItem, c: Vector2, r: float, k: float) -> void:
	var rr := r * (1.0 - pow(1.0 - k, 2.0))
	o.draw_circle(c, rr, Color(0.6, 0.8, 1.0, 0.12 * (1.0 - k)))
	o.draw_arc(c, rr, 0.0, TAU, 80, Color(0.8, 0.92, 1.0, 0.9 * (1.0 - k)), 10.0)
	o.draw_arc(c, rr * 0.9, 0.0, TAU, 80, Color(0.5, 0.75, 1.0, 0.5 * (1.0 - k)), 4.0)
	dashes(o, c, rr * 0.8, k * 1.5, 24, 0.4, Color(0.8, 0.92, 1.0, 0.5 * (1.0 - k)), 3.0)


## … and its clock round you: twelve marks, a hand, and the part of the round that is still left (`left`: 1 … 0).
static func stasis_clock(o: CanvasItem, c: Vector2, left: float, t: float) -> void:
	var col := Color(0.72, 0.88, 1.0)
	var r := 62.0
	o.draw_arc(c, r, 0.0, TAU, 48, Color(col, 0.25), 2.0)
	o.draw_arc(c, r, -PI * 0.5, -PI * 0.5 + TAU * left, 48, Color(col, 0.95), 4.0)
	for q in 12:
		var d := Vector2.from_angle(q * TAU / 12.0)
		o.draw_line(c + d * (r - (9.0 if q % 3 == 0 else 5.0)), c + d * r, Color(col, 0.8), 2.0)
	var hand := Vector2.from_angle(-PI * 0.5 + TAU * left)
	o.draw_line(c, c + hand * (r - 12.0), Color(1, 1, 1, 0.9), 2.0)
	o.draw_circle(c + hand * r, 4.0 + 1.5 * sin(t * 8.0), Color(1, 1, 1, 0.95))


## Overdrive: echoes of you where you just were, rings of gold turning round you, sparks rising.
static func overdrive_over(o: CanvasItem, c: Vector2, t: float, trail: PackedVector2Array, blink: bool) -> void:
	var a := (0.4 + 0.5 * absf(sin(t * 12.0))) if blink else 1.0
	var gold := Color(1.0, 0.82, 0.3)
	for q in trail.size():
		var k := 1.0 - float(q + 1) / (trail.size() + 1.0)
		o.draw_rect(Rect2(trail[q] + Vector2(-13.0, -74.0), Vector2(26.0, 74.0)), Color(gold, 0.22 * k * a))
		o.draw_rect(Rect2(trail[q] + Vector2(-9.0, -96.0), Vector2(18.0, 22.0)), Color(gold, 0.22 * k * a))
	for q2 in 2:
		var rr := 50.0 + q2 * 12.0
		var rot := t * (5.0 if q2 == 0 else -3.6)
		o.draw_arc(c, rr, rot, rot + 1.9, 14, Color(gold, 0.85 * a), 3.0)
		o.draw_arc(c, rr, rot + PI, rot + PI + 1.9, 14, Color(gold, 0.85 * a), 3.0)
	for q3 in 9:
		var sk := fposmod(t * (0.9 + 0.5 * h(q3 * 2.1)) + h(q3 * 4.7), 1.0)
		var sp := c + Vector2((h(q3 * 8.3) - 0.5) * 90.0, 40.0 - sk * 120.0)
		var s := 5.0 * sin(sk * PI)
		if s > 2.5:
			fill(o, PackedVector2Array([sp + Vector2(0.0, -s * 1.6), sp + Vector2(s * 0.6, 0.0), sp + Vector2(0.0, s * 1.6), sp + Vector2(-s * 0.6, 0.0)]), Color(1.0, 0.95, 0.6, a * sin(sk * PI)), "an overdrive spark")


## … and its light.
static func overdrive_glow(o: CanvasItem, gt: Texture2D, c: Vector2, t: float) -> void:
	var gr := 96.0 + 12.0 * sin(t * 10.0)
	o.draw_texture_rect(gt, Rect2(c - Vector2(gr, gr), Vector2(gr, gr) * 2.0), false, Color(1.0, 0.75, 0.25, 0.55))


## Over a machine an Override turned: a small six-sided sign of green light, bobbing.
static func ovr_mark(o: CanvasItem, p: Vector2, t: float) -> void:
	var c := p + Vector2(0.0, sin(t * 5.0 + p.x * 0.05) * 2.5)
	o.draw_colored_polygon(poly(c, 8.0, 6, PI / 6.0).slice(0, 6), Color(0.03, 0.12, 0.06, 0.9))
	o.draw_polyline(poly(c, 8.0, 6, PI / 6.0), Color(0.4, 1.0, 0.55), 2.0)
	o.draw_circle(c, 2.5, Color(0.8, 1.0, 0.85))
