class_name ColossusShape
extends RefCounted
## Outline of a colossal asteroid (phase 0.5 package 5). One irregular polygon (local km around the
## rock's centre) is used for everything: the shader draws it, ships collide with it, and it
## blocks radar, locks and shots. Three shape families:
##   potato  – elongated, lumpy body
##   binary  – contact binary: two lobes joined by a narrow neck (peanut)
##   shard   – angular fragment with straight facets (broken off a larger body)

const SHAPES := ["potato", "binary", "shard"]
const SHAPE_NAMES := {"potato": "elongated", "binary": "contact binary", "shard": "angular fragment"}


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
