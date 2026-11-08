class_name ColossusShape
extends RefCounted
## Outline of a colossal asteroid (phase 0.5 package 5). One irregular polygon (local km around the
## rock's centre) is used for everything: the shader draws it, ships collide with it, and it
## blocks radar, locks and shots. Three shape families:
##   potato  – elongated, lumpy body
##   binary  – contact binary: two lobes joined by a narrow neck (peanut)
##   shard   – angular fragment with straight facets (broken off a larger body)

const SHAPES := ["potato", "binary", "shard"]
const SHAPE_NAMES := {"potato": "elongated", "binary": "contact binary", "shard": "angular fragment",
	"slab": "blocky slab", "spindle": "spindle", "rubble": "rubble pile", "kidney": "kidney", "teardrop": "teardrop", "spiky": "ice ball"}
## 0.6.35.5: two more shapes for each kind of rock (metal, stone, ice)
const SHAPES_BY_CLASS := {
	"metallic": ["potato", "binary", "shard", "slab", "spindle"],
	"stony": ["potato", "binary", "shard", "rubble", "kidney"],
	"icy": ["potato", "binary", "shard", "teardrop", "spiky"],
}
## how the shader lights a shape: 0 round body, 1 two lobes, 2 flat facets
const SHADER_SHAPE := {"potato": 0, "binary": 1, "shard": 2, "slab": 2, "spindle": 0, "rubble": 1, "kidney": 0, "teardrop": 0, "spiky": 0}


static func shapes_for(cls: String) -> Array:
	return SHAPES_BY_CLASS.get(cls, SHAPES)


## Polygon for shape `shape` whose farthest point is `R` km from the centre.
static func generate(shape: String, R: float, rng: RandomNumberGenerator) -> PackedVector2Array:
	var pts := PackedVector2Array()
	match shape:
		"binary":
			# two overlapping lobes; the centre lies inside both, so every ray hits the far side once
			var c1 := Vector2(-0.42, 0.0)
			var r1 := rng.randf_range(0.54, 0.6)
			var c2 := Vector2(rng.randf_range(0.36, 0.42), rng.randf_range(-0.05, 0.05))
			var r2 := rng.randf_range(0.43, 0.5)
			var p1 := rng.randf() * TAU
			var p2 := rng.randf() * TAU
			var n := 56
			for i in n:
				var a := TAU * i / n
				var d := Vector2.from_angle(a)
				var t := maxf(_ray_far(c1, r1, d), _ray_far(c2, r2, d))
				t *= 1.0 + 0.035 * sin(3.0 * a + p1) + 0.025 * sin(7.0 * a + p2) + rng.randf_range(-0.012, 0.012)
				pts.append(d * t)
		"shard":
			# few big straight facets, slightly split so the edges are not perfectly clean
			var k := rng.randi_range(6, 8)
			var stretch := rng.randf_range(0.62, 0.82)
			var angs: Array = []
			for i in k:
				angs.append(TAU * (i + rng.randf_range(-0.3, 0.3)) / k)
			angs.sort()
			var corners := PackedVector2Array()
			for a in angs:
				var r := rng.randf_range(0.62, 1.0)
				corners.append(Vector2(cos(a) * r, sin(a) * r * stretch))
			for i in k:
				var a0: Vector2 = corners[i]
				var a1: Vector2 = corners[(i + 1) % k]
				var nrm := (a1 - a0).orthogonal().normalized()
				pts.append(a0)
				for s in [0.33, 0.66]:
					pts.append(a0.lerp(a1, s) + nrm * rng.randf_range(-0.018, 0.012))
		"slab":
			# a blocky slab: a superellipse with flat sides and a couple of notches
			var e2 := rng.randf_range(0.5, 0.7)
			var n3 := 48
			var notch := rng.randf() * TAU
			for i in n3:
				var a := TAU * i / n3
				var c := cos(a)
				var s := sin(a)
				var r := pow(pow(absf(c), 6.0) + pow(absf(s) / e2, 6.0), -1.0 / 6.0)
				r *= 1.0 - 0.14 * exp(-pow(wrapf(a - notch, -PI, PI), 2.0) / 0.03) + rng.randf_range(-0.012, 0.012)
				pts.append(Vector2(c, s) * r)
		"spindle":
			# long and thin, pointed at both ends
			var e3 := rng.randf_range(0.26, 0.36)
			var q4 := rng.randf() * TAU
			var n4 := 48
			for i in n4:
				var a := TAU * i / n4
				var taper := 0.55 + 0.45 * absf(sin(a))
				var bump := 1.0 + 0.05 * sin(4.0 * a + q4) + rng.randf_range(-0.015, 0.015)
				pts.append(Vector2(cos(a), sin(a) * e3 * taper) * bump)
		"rubble":
			# a rubble pile: strong lumps all round
			var r1 := rng.randf() * TAU
			var r2 := rng.randf() * TAU
			var r3 := rng.randf() * TAU
			var n5 := 52
			for i in n5:
				var a := TAU * i / n5
				var bump := 1.0 + 0.16 * sin(3.0 * a + r1) + 0.11 * sin(5.0 * a + r2) + 0.07 * sin(9.0 * a + r3) + rng.randf_range(-0.03, 0.03)
				pts.append(Vector2(cos(a), sin(a) * 0.82) * bump)
		"kidney":
			# a bean with a deep dent on one side
			var dent := rng.randf() * TAU
			var e4 := rng.randf_range(0.55, 0.7)
			var n6 := 52
			for i in n6:
				var a := TAU * i / n6
				var r := 1.0 - 0.38 * exp(-pow(wrapf(a - dent, -PI, PI), 2.0) / 0.22) + 0.04 * sin(3.0 * a) + rng.randf_range(-0.015, 0.015)
				pts.append(Vector2(cos(a), sin(a) * e4) * r)
		"teardrop":
			# round head, long pointed tail – like a frozen comet
			var n7 := 52
			for i in n7:
				var a := TAU * i / n7
				var r := 0.42 + 0.58 * pow((1.0 + cos(a)) * 0.5, 3.0) + 0.03 * sin(5.0 * a) + rng.randf_range(-0.015, 0.015)
				pts.append(Vector2(cos(a), sin(a)) * r)
		"spiky":
			# 0.6.35.6: a rounded ice ball with a few soft bulges (the star shape was too much)
			var k2 := rng.randi_range(4, 6)
			var off := rng.randf() * TAU
			var q5 := rng.randf() * TAU
			var n8 := 60
			for i in n8:
				var a := TAU * i / n8
				var r := 0.86 + 0.1 * pow(absf(cos(k2 * (a + off) * 0.5)), 2.0) + 0.03 * sin(3.0 * a + q5) + rng.randf_range(-0.012, 0.012)
				pts.append(Vector2(cos(a), sin(a) * 0.92) * r)
		_:
			# potato: lumpy ellipse
			var e := rng.randf_range(0.52, 0.7)
			var q1 := rng.randf() * TAU
			var q2 := rng.randf() * TAU
			var q3 := rng.randf() * TAU
			var n2 := 44
			for i in n2:
				var a := TAU * i / n2
				var bump := 1.0 + 0.1 * sin(2.0 * a + q1) + 0.07 * sin(3.0 * a + q2) + 0.04 * sin(5.0 * a + q3) + rng.randf_range(-0.02, 0.02)
				pts.append(Vector2(cos(a), sin(a) * e) * bump)
	# normalise to R and rotate randomly
	var mx := 0.0
	for p in pts:
		mx = maxf(mx, p.length())
	var rot := rng.randf() * TAU
	for i in pts.size():
		pts[i] = (pts[i] / mx * R).rotated(rot)
	return pts


static func _ray_far(c: Vector2, r: float, d: Vector2) -> float:
	var f := -c
	var b := f.dot(d)
	var disc := b * b - (f.length_squared() - r * r)
	return -b + sqrt(maxf(disc, 0.0))


static func contains(poly: PackedVector2Array, p: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(p, poly)


## Closest point on the outline, outward normal there and signed distance (negative = inside).
static func surface(poly: PackedVector2Array, p: Vector2) -> Array:
	var best := INF
	var cp := Vector2.ZERO
	var n := poly.size()
	for i in n:
		var q := Geometry2D.get_closest_point_to_segment(p, poly[i], poly[(i + 1) % n])
		var d := p.distance_squared_to(q)
		if d < best:
			best = d
			cp = q
	var dist := sqrt(best)
	var inside := contains(poly, p)
	var nrm := (p - cp) / dist if dist > 0.001 else p.normalized()
	if inside:
		nrm = -nrm
	return [cp, nrm, -dist if inside else dist]


static func signed_dist(poly: PackedVector2Array, p: Vector2) -> float:
	return float(surface(poly, p)[2])


## Fraction t (0..1) along a -> b where the segment first crosses the outline, or -1.
static func first_hit(poly: PackedVector2Array, a: Vector2, b: Vector2) -> float:
	var best := -1.0
	var len2 := a.distance_squared_to(b)
	if len2 < 0.0001:
		return -1.0
	var n := poly.size()
	for i in n:
		var x = Geometry2D.segment_intersects_segment(a, b, poly[i], poly[(i + 1) % n])
		if x != null:
			var t := a.distance_squared_to(x) / len2
			if best < 0.0 or t < best:
				best = t
	return sqrt(best) if best >= 0.0 else -1.0


## Length of the longest axis (for the info panel).
static func length_km(poly: PackedVector2Array) -> float:
	var mx := 0.0
	for i in poly.size():
		for j in range(i + 1, poly.size()):
			mx = maxf(mx, poly[i].distance_to(poly[j]))
	return mx
