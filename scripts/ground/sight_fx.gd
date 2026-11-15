extends Node2D
## Package 54a (Luz): what makes a sight alive, over the map – the falls' spray always, and this visit's event: a
## rainbow (or by night a moonbow) in the spray, morning mist over the pool, fireflies over the water, a herd come to
## drink. `day` dims what needs light; the camera flashes of the sightseers now and then.

const S := GroundMap.SCALE
const CreatureArtF = preload("res://scripts/ground/creature_art.gd")

var sight: Dictionary = {}
var under := false                       # the layer under the map: what lives in the water (corals, fish, jellyfish)
var day := 1.0
var view = null
var _t := 0.0
var _rng := RandomNumberGenerator.new()
var _flies: Array = []
var _flashes: Array = []                 # [pos, t]
var _herd: Array = []                    # [pos, dir, phase]


func setup(p_sight: Dictionary, p_day: float) -> void:
	sight = p_sight
	day = p_day
	_rng.seed = hash(String(sight.get("id", "")))
	var pool: Vector2 = sight.get("pool", sight.get("focus", Vector2.ZERO))
	for i in 46:
		_flies.append([pool + Vector2(_rng.randf_range(-130, 130), _rng.randf_range(-20, 110)), _rng.randf() * TAU, _rng.randf_range(0.6, 1.4)])
	if String(sight.get("event", "")) == "herd":
		for i in 4:
			_herd.append([pool + Vector2(-118.0 - i * 20.0 + _rng.randf_range(-4, 4), 4.0 + i * 9.0), 3, _rng.randf() * 3.0])   # on the west shore, drinking


func _process(delta: float) -> void:
	_t += delta
	# a sightseer takes a photo now and then
	if view != null and _rng.randf() < delta * 0.5 and not view.people.is_empty():
		var w = view.people[_rng.randi() % view.people.size()]
		if is_instance_valid(w) and not w.sitting:
			_flashes.append([w.pos + Vector2(0, -26), 0.0])
	for f in _flashes:
		f[1] = float(f[1]) + delta
	_flashes = _flashes.filter(func(f): return float(f[1]) < 0.25)
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * S)
	var ev := String(sight.get("event", ""))
	if under:
		match String(sight.get("theme", "")):
			"lagoon":
				_lagoon(ev)
			"arches", "lava", "crater":
				_sky(ev)
		return
	match String(sight.get("theme", "")):
		"falls":
			_falls(ev)
		"lagoon":
			_lagoon_over(ev)
		"icecave":
			_icecave(ev)
		"arches":
			_arches_over(ev)
		"lava":
			_lava_over(ev)
		"crater":
			_crater_over(ev)
		"skyring":
			_skyring(ev)
	for f in _flashes:
		var a := 1.0 - float(f[1]) / 0.25
		var p: Vector2 = f[0]
		draw_rect(Rect2(p + Vector2(-5, 0), Vector2(11, 1)), Color(1, 1, 1, a))
		draw_rect(Rect2(p + Vector2(0, -5), Vector2(1, 11)), Color(1, 1, 1, a))
		draw_circle(p, 2.0, Color(1, 1, 1, a))


## The lagoon: corals glowing under the shallow water, fish darting over them; by the event shoals of bright fish,
## glowing jellyfish at night, the sun going down over the reef, a great creature passing outside the reef.
func _lagoon(ev: String) -> void:
	var lit := clampf(0.3 + day * 0.8, 0.0, 1.0)
	var cols := [Color(1.0, 0.45, 0.55), Color(1.0, 0.7, 0.3), Color(0.6, 0.4, 1.0), Color(0.3, 1.0, 0.75), Color(1.0, 0.9, 0.5)]
	for cr in sight.get("corals", []):
		var p: Vector2 = cr[0]
		var r := float(cr[1])
		var cc: Color = cols[int(cr[2])]
		var sway := sin(_t * 0.8 + p.x * 0.05) * 0.6
		draw_circle(p + Vector2(0, 2), r * 0.7, Color(0.1, 0.25, 0.3, 0.25))           # its shadow on the sand
		for br in 5:                                                                   # branches, swaying a little
			var a := -PI * 0.5 + (br - 2) * 0.45
			var e := p + Vector2(cos(a) * r + sway, sin(a) * r * 0.8)
			var m2 := p.lerp(e, 0.55) + Vector2(sin(br * 1.9) * 2.0, 0)
			draw_line(p, m2, Color(cc.darkened(0.2), 0.7 * lit), 1.0)
			draw_line(m2, e, Color(cc, 0.75 * lit), 1.0)
			draw_rect(Rect2(e - Vector2(1, 1), Vector2(2, 2)), Color(cc.lightened(0.3), 0.85 * lit))
			draw_rect(Rect2(m2 + Vector2(1, -1), Vector2(1, 1)), Color(cc.lightened(0.2), 0.7 * lit))
	var fc: Vector2 = sight.get("pool", Vector2.ZERO)
	var n_fish := 3 if ev != "shoal" else 9
	for s in n_fish:
		var cen := fc + Vector2(sin(s * 2.3) * 220.0, cos(s * 1.7) * 90.0)
		var col: Color = cols[s % cols.size()]
		for f in 14:
			var an := _t * (0.5 + 0.1 * s) + f * 0.22 + s
			var q := cen + Vector2(cos(an) * (30.0 + f * 1.5), sin(an) * (16.0 + f))
			draw_rect(Rect2(q, Vector2(3, 1)), Color(col.r * lit, col.g * lit, col.b * lit, 0.85))
	match ev:
		"glow":
			for j in 44:
				var jp := fc + Vector2(sin(j * 3.1) * 280.0 + sin(_t * 0.2 + j) * 12.0, cos(j * 2.3) * 120.0 + cos(_t * 0.15 + j) * 8.0)
				var pulse := 0.5 + 0.5 * sin(_t * 1.5 + j)
				var jc := Color(0.4, 0.9, 1.0) if j % 3 else Color(1.0, 0.45, 0.9)
				draw_circle(jp, 4.0 + pulse * 1.5, Color(jc, 0.08 + 0.08 * pulse))         # its glow in the water
				draw_rect(Rect2(jp + Vector2(-2, -1), Vector2(5, 2)), Color(jc.lightened(0.3), 0.75))   # the bell
				draw_rect(Rect2(jp + Vector2(-1, -2), Vector2(3, 1)), Color(jc.lightened(0.5), 0.8))
				for tl in 3:
					draw_line(jp + Vector2(tl - 1, 1), jp + Vector2(tl - 1 + sin(_t * 2.0 + tl + j) * 1.5, 6.0 + pulse * 2.0), Color(jc, 0.45), 1.0)
		"sunset":
			var sy := fc.y - 230.0
			for g in 6:
				draw_circle(Vector2(fc.x, sy), 60.0 - g * 9.0, Color(1.0, 0.55, 0.25, 0.05 + g * 0.03))
			for st in 22:                                          # its path of light on the water
				var yy := sy + 40.0 + st * 12.0
				var ww := 18.0 + st * 3.0 + sin(_t * 2.0 + st) * 6.0
				draw_rect(Rect2(fc.x - ww * 0.5, yy, ww, 2.0), Color(1.0, 0.75, 0.4, 0.35 * (1.0 - st / 22.0)))
		"whale":
			var rp: Array = sight.get("reef", [fc, Vector2(400, 200)])
			var wx := (rp[0] as Vector2).x - (rp[1] as Vector2).x * 1.1 + fposmod(_t * 18.0, (rp[1] as Vector2).x * 2.2)
			var wy := (rp[0] as Vector2).y - (rp[1] as Vector2).y * 1.05
			var pts := PackedVector2Array()
			for i in 20:
				var an2 := TAU * i / 20.0
				pts.append(Vector2(wx + cos(an2) * 70.0, wy + sin(an2) * 16.0))
			draw_colored_polygon(pts, Color(0.02, 0.08, 0.15, 0.45))
			draw_colored_polygon(PackedVector2Array([Vector2(wx - 70, wy), Vector2(wx - 96, wy - 14), Vector2(wx - 92, wy + 14)]), Color(0.02, 0.08, 0.15, 0.45))
			if fposmod(_t, 6.0) < 1.2:
				for sp in 8:                                       # its spout
					draw_circle(Vector2(wx + 40.0 + sin(sp) * 3.0, wy - 8.0 - sp * 4.0), 3.0 + sp * 0.5, Color(1, 1, 1, 0.4 - sp * 0.04))


## Over the map at the lagoon: the sun's glare and the reflections on the water by the hour.
func _lagoon_over(ev: String) -> void:
	if ev != "glow" or view == null or view.map == null or not view.map.has_meta("wild"):
		return
	# by night the jellyfish's light shines up through the dark (over the night's shade, only where there is water)
	var ter: PackedByteArray = view.map.get_meta("wild")["ter"]
	var mw: int = view.map.w
	var fc: Vector2 = sight.get("pool", Vector2.ZERO)
	for j in 44:
		var jp := fc + Vector2(sin(j * 3.1) * 280.0 + sin(_t * 0.2 + j) * 12.0, cos(j * 2.3) * 120.0 + cos(_t * 0.15 + j) * 8.0)
		var tx := int(jp.x / GroundMap.TILE)
		var ty := int(jp.y / GroundMap.TILE)
		if tx < 0 or ty < 0 or tx >= mw or ty >= view.map.h or int(ter[ty * mw + tx]) != 1:
			continue
		var pulse := 0.5 + 0.5 * sin(_t * 1.5 + j)
		var jc := Color(0.4, 0.9, 1.0) if j % 3 else Color(1.0, 0.45, 0.9)
		draw_circle(jp, 6.0 + pulse * 2.0, Color(jc, 0.1 + 0.08 * pulse))
		draw_rect(Rect2(jp + Vector2(-2, -1), Vector2(5, 2)), Color(jc.lightened(0.4), 0.55 + 0.3 * pulse))


func _hh(a: int, b: int) -> float:
	var v := sin(float(a) * 12.9898 + float(b) * 78.233) * 43758.5453
	return v - floor(v)


func _falls(ev: String) -> void:
	var fo: Vector2 = sight.get("focus", Vector2.ZERO)
	var pool: Vector2 = sight.get("pool", fo)
	# the falls themselves: a curtain of water pouring off the wall, streaks racing down, the lip bright at the top
	var fr: Rect2 = sight.get("fall", Rect2())
	if fr.size.x > 0.0:
		var lit := clampf(0.35 + day * 0.75, 0.0, 1.0)
		draw_rect(fr, Color(Color(0.55, 0.72, 0.82) * Color(lit, lit, lit), 1.0))
		for sx in int(fr.size.x):
			var k := float(sx) / fr.size.x
			var edge := 1.0 - absf(k - 0.5) * 2.0
			var spd := 70.0 + _hh(sx, 1) * 50.0
			var ln := 6.0 + _hh(sx, 2) * 14.0
			var off := fposmod(_t * spd + _hh(sx, 3) * 400.0, fr.size.y + ln)
			for rep in 3:
				var y := fr.position.y + fposmod(off + rep * fr.size.y / 3.0, fr.size.y + ln) - ln
				var c := Color(0.85, 0.95, 1.0, 0.75 * (0.4 + 0.6 * edge))
				draw_rect(Rect2(fr.position.x + sx, maxf(y, fr.position.y), 1.0, minf(ln, fr.end.y - maxf(y, fr.position.y))), Color(c.r * lit, c.g * lit, c.b * lit, c.a))
			if sx % 3 == 0:
				draw_rect(Rect2(fr.position.x + sx, fr.position.y + 2.0, 2.0, 2.0), Color(1, 1, 1, 0.8 * lit))
		draw_rect(Rect2(fr.position.x - 2.0, fr.position.y, 2.0, fr.size.y), Color(0.3, 0.4, 0.45, 0.5))
		draw_rect(Rect2(fr.end.x, fr.position.y, 2.0, fr.size.y), Color(0.2, 0.28, 0.3, 0.6))
		# foam where it lands
		for fm in 18:
			var ph2 := fposmod(_t * 1.3 + fm * 0.31, 1.0)
			draw_circle(Vector2(fr.position.x + _hh(fm, 4) * fr.size.x, fr.end.y + 2.0 + ph2 * 8.0), 3.0 + 4.0 * (1.0 - ph2), Color(1, 1, 1, 0.5 * (1.0 - ph2) * lit))
		# rings spreading over the pool
		for rg in 3:
			var ph3 := fposmod(_t * 0.35 + rg / 3.0, 1.0)
			draw_arc(Vector2(pool.x, fr.end.y + 14.0), 10.0 + ph3 * 60.0, 0.15, PI - 0.15, 24, Color(1, 1, 1, 0.25 * (1.0 - ph3) * lit), 1.0)
	# the spray where the falls hit the pool – always
	var foot := fr.end.y if fr.size.x > 0.0 else pool.y
	for i in 22:
		var ph := fposmod(_t * 0.45 + i * 0.137, 1.0)
		var px := pool.x + sin(i * 2.7) * (fr.size.x * 0.6 + 10.0) * ph
		var py := foot + 4.0 - ph * 22.0
		draw_circle(Vector2(px, py), 2.0 + ph * 5.0, Color(1, 1, 1, 0.16 * (1.0 - ph)))
	match ev:
		"rainbow", "moonbow":
			var c := Vector2(pool.x, fr.end.y + 30.0) if fr.size.x > 0.0 else pool + Vector2(0, 6)
			var cols := [Color(1, 0.3, 0.3), Color(1, 0.6, 0.2), Color(1, 0.95, 0.3), Color(0.4, 1, 0.4), Color(0.3, 0.7, 1), Color(0.6, 0.4, 1)]
			var a0 := 0.32 if ev == "rainbow" else 0.18
			for i in cols.size():
				var col: Color = cols[i] if ev == "rainbow" else Color(0.85, 0.9, 1.0)
				draw_arc(c, 84.0 - i * 2.0, PI * 1.05, PI * 1.95, 48, Color(col, a0 * (0.75 + 0.25 * sin(_t * 0.8))), 2.0)
		"mist":
			for i in 9:
				var mx := pool.x - 140.0 + fposmod(_t * 6.0 + i * 37.0, 280.0)
				draw_circle(Vector2(mx, pool.y + 20.0 + sin(i * 1.7) * 18.0), 26.0 + (i % 3) * 8.0, Color(1, 1, 1, 0.1))
		"fireflies":
			for fl in _flies:
				var p: Vector2 = fl[0]
				var q := p + Vector2(sin(_t * float(fl[2]) + float(fl[1])) * 14.0, cos(_t * 0.7 * float(fl[2]) + float(fl[1])) * 8.0)
				var on := 0.5 + 0.5 * sin(_t * 3.0 * float(fl[2]) + float(fl[1]) * 3.0)
				draw_circle(q, 2.5, Color(0.8, 1.0, 0.4, 0.18 * on))
				draw_rect(Rect2(q, Vector2(1, 1)), Color(0.9, 1.0, 0.5, 0.9 * on))
		"herd":
			for hd in _herd:
				var tex := CreatureArtF.texture("grazer", int(hd[1]), int(_t * 1.5 + float(hd[2])) % 2, false, 0)
				if tex != null:
					draw_texture(tex, (hd[0] as Vector2) - Vector2(tex.get_width() * 0.5, tex.get_height()))


## The ice cathedral: the portal's blue glow breathing, glints on the ice, snow blown across the field, spindrift off the
## glacier's edge; by the event the ice glowing deep blue (its light falling out over the lake), an aurora over the
## glacier mirrored in the lake, sun dogs over the ice field, the ice singing in the wind.
func _icecave(ev: String) -> void:
	var pr: Array = sight.get("portal", [Vector2.ZERO, 0.0, 0.0, 100.0])
	var pc: Vector2 = pr[0]
	var base := float(pr[2])
	var hw := float(pr[3])
	var vp: Vector2 = sight.get("vp", pc)
	var lk: Array = sight.get("lake", [vp, 100.0, 40.0])
	var lc: Vector2 = lk[0]
	var lrx := float(lk[1])
	var lry := float(lk[2])
	var dark := clampf(1.0 - day, 0.0, 1.0)
	var breathe := 0.5 + 0.5 * sin(_t * 0.6)
	var strong := 1.6 if ev == "glow" else 1.0
	# the portal's glow
	for g in 12:
		draw_circle(vp + Vector2(0, 10), 24.0 + g * 8.0, Color(0.35, 0.75, 1.0, (0.008 + 0.008 * breathe) * strong * (0.5 + dark * 0.6)))
	var fw := hw * 0.3
	draw_rect(Rect2(vp.x - fw * 0.5, vp.y - (base - vp.y) * 0.7, fw, (base - vp.y) * 0.75), Color(0.6, 0.95, 1.0, (0.05 + 0.05 * breathe) * strong))
	if ev == "glow":
		# its light falling out of the portal and over the lake
		for r in 7:
			var a0 := -0.55 + r * 0.18 + sin(_t * 0.3 + r) * 0.02
			var a1 := a0 + 0.07
			var L := 150.0 + (r % 3) * 30.0
			var poly := PackedVector2Array([vp + Vector2(0, 20), vp + Vector2(sin(a0) * L, cos(a0) * L + 20.0), vp + Vector2(sin(a1) * L, cos(a1) * L + 20.0)])
			draw_colored_polygon(poly, Color(0.45, 0.85, 1.0, 0.05 + 0.03 * sin(_t * 0.8 + r)))
	# glints on the ice
	for gl in 50:
		var gp := Vector2(lc.x + (_hh(gl, 1) - 0.5) * lrx * 3.2, lc.y + (_hh(gl, 2) - 0.2) * 520.0)
		var tw := sin(_t * (1.5 + _hh(gl, 3) * 2.0) + gl * 2.1)
		if tw > 0.92:
			var ga := (tw - 0.92) / 0.08
			draw_rect(Rect2(gp + Vector2(-2, 0), Vector2(5, 1)), Color(1, 1, 1, 0.8 * ga))
			draw_rect(Rect2(gp + Vector2(0, -2), Vector2(1, 5)), Color(1, 1, 1, 0.8 * ga))
	# snow blown across the field; spindrift streaming off the glacier's edge
	var wind := 2.4 if ev == "singing" else 1.0
	var mw := 66.0 * GroundMap.TILE
	for fl in 90:
		var sx := fposmod(_hh(fl, 4) * mw + _t * (40.0 + _hh(fl, 5) * 30.0) * wind, mw)
		var sy := _hh(fl, 6) * 52.0 * GroundMap.TILE + sin(_t * 1.3 + fl) * 6.0
		draw_rect(Rect2(sx, sy, 1.0 + float(fl % 2), 1.0), Color(1, 1, 1, 0.55))
	for sp in (36 if ev == "singing" else 14):
		var ph := fposmod(_t * 0.4 * wind + sp * 0.173, 1.0)
		var sx2 := pc.x - hw * 2.6 + _hh(sp, 7) * hw * 5.2 + ph * 60.0 * wind
		draw_circle(Vector2(sx2, 8.0 + ph * 10.0 - sin(ph * PI) * 12.0), 3.0 + ph * 9.0, Color(1, 1, 1, 0.2 * sin(ph * PI)))
	match ev:
		"aurora":
			# curtains of light over the glacier, waving; mirrored faintly in the lake
			var cols := [Color(0.3, 1.0, 0.55), Color(0.35, 0.95, 0.8), Color(0.65, 0.4, 1.0)]
			var gl := float(sight.get("glacier", 200.0))
			for band in 3:
				var y0 := gl * 0.55 + band * 18.0
				for x in range(0, int(mw), 3):
					var wave := sin(x * 0.012 + _t * 0.35 + band * 1.7) * 14.0 + sin(x * 0.031 - _t * 0.6 + band) * 6.0
					var inten := 0.5 + 0.5 * sin(x * 0.02 + _t * 0.9 + band * 2.3)
					var col: Color = cols[band]
					var hgt := 40.0 + inten * 36.0
					var yt := y0 + wave
					var in_arch := Vector2((x - pc.x) / hw, (yt - base) / (base - float(pr[1]))).length() < 1.05
					var am := 0.35 if in_arch else 1.0                             # seen over the glacier, faint through the portal
					var ray := 0.55 + 0.45 * sin(x * 0.7 + _t * 1.7 + band * 3.0) * _hh(x / 3, band)      # its rays, flickering
					draw_rect(Rect2(x, yt - hgt, 3.0, hgt * 0.5), Color(col, (0.03 + 0.08 * inten) * am * ray))
					draw_rect(Rect2(x, yt - hgt * 0.5, 3.0, hgt * 0.5), Color(col, (0.06 + 0.14 * inten) * am * ray))
					draw_rect(Rect2(x, yt - 4.0, 3.0, 4.0), Color(col.lightened(0.3), (0.18 + 0.2 * inten) * am))
					var ry := lc.y - lry * 0.8 + (yt - y0) * 0.3                   # its mirror in the lake
					if absf(x - lc.x) < lrx * 0.9:
						var ek := absf(x - lc.x) / lrx
						draw_rect(Rect2(x, ry + band * 6.0, 3.0, 10.0 + inten * 8.0), Color(col, (0.05 + 0.08 * inten) * (1.0 - ek)))
		"sundog":
			# the sun low over the glacier, the ring of light round it, two mock suns and the pillar
			var sun := Vector2(pc.x, float(pr[1]) - 10.0)
			for g2 in 5:
				draw_circle(sun, 22.0 - g2 * 4.0, Color(1.0, 0.98, 0.9, 0.08 + g2 * 0.1))
			draw_arc(sun, 96.0, 0.0, TAU, 96, Color(1.0, 1.0, 1.0, 0.22), 3.0)
			draw_arc(sun, 99.0, 0.0, TAU, 96, Color(1.0, 0.75, 0.5, 0.12), 2.0)
			draw_arc(sun, 93.0, 0.0, TAU, 96, Color(0.6, 0.8, 1.0, 0.12), 2.0)
			for side in [-1.0, 1.0]:
				var dog := sun + Vector2(side * 98.0, 0)
				for g3 in 3:
					draw_circle(dog, 10.0 - g3 * 3.0, Color(1.0, 0.95, 0.85, 0.14 + g3 * 0.14))
				draw_rect(Rect2(dog.x + (4.0 if side > 0.0 else -30.0), dog.y - 1.0, 26.0, 2.0), Color(1, 1, 1, 0.12))   # its tail, outward
			draw_rect(Rect2(sun.x - 2.0, sun.y - 46.0, 4.0, 160.0), Color(1.0, 0.95, 0.85, 0.12))
			draw_arc(sun + Vector2(0, -96), 60.0, PI * 0.15, PI * 0.85, 32, Color(1, 1, 1, 0.14), 2.0)
			# and all of it mirrored in the lake's polished ice, squashed by the angle
			draw_set_transform(Vector2(0, lc.y * S * 0.6), 0.0, Vector2(S, S * 0.4))
			var ms := Vector2(sun.x, lc.y)
			for g4 in 4:
				draw_circle(ms, 16.0 - g4 * 4.0, Color(1.0, 0.98, 0.9, 0.06 + g4 * 0.08))
			draw_arc(ms, 96.0, 0.0, TAU, 96, Color(1.0, 1.0, 1.0, 0.16), 3.0)
			draw_arc(ms, 99.0, 0.0, TAU, 96, Color(1.0, 0.75, 0.5, 0.1), 2.0)
			for side2 in [-1.0, 1.0]:
				for g5 in 3:
					draw_circle(ms + Vector2(side2 * 98.0, 0), 9.0 - g5 * 3.0, Color(1.0, 0.95, 0.85, 0.1 + g5 * 0.12))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * S)
			for dd in 40:                                                      # diamond dust in the air
				var dp := Vector2(_hh(dd, 8) * mw, 60.0 + _hh(dd, 9) * 500.0)
				if sin(_t * 3.0 + dd * 1.7) > 0.6:
					draw_rect(Rect2(dp, Vector2(1, 1)), Color(1, 1, 0.9, 0.9))
		"singing":
			# the ice humming: rings of sound out of the portal, the pillars' light trembling
			for rg in 4:
				var ph2 := fposmod(_t * 0.5 + rg / 4.0, 1.0)
				draw_arc(vp + Vector2(0, 30), 30.0 + ph2 * 220.0, PI * 0.12, PI * 0.88, 48, Color(0.7, 0.95, 1.0, 0.22 * (1.0 - ph2)), 2.0)
			for k in 30:
				var q := vp + Vector2((_hh(k, 10) - 0.5) * hw * 1.6, (_hh(k, 11) - 0.7) * 120.0)
				draw_rect(Rect2(q + Vector2(sin(_t * 9.0 + k) * 1.5, 0), Vector2(1, 3)), Color(0.8, 0.98, 1.0, 0.4 + 0.3 * sin(_t * 5.0 + k)))


# ---- 54a: the vistas – their sky under the map (it shows where the map is left clear), their life over it

func _grad(top: Color, mid: Color, bot: Color, h: float, w: float) -> void:
	var n := 24
	for i in n:
		var k := float(i) / n
		var c := top.lerp(mid, k * 2.0) if k < 0.5 else mid.lerp(bot, (k - 0.5) * 2.0)
		draw_rect(Rect2(0, h * k, w, h / n + 1.0), c)


func _stars(n: int, h: float, w: float, a: float, seed_k: int) -> void:
	for i in n:
		var p := Vector2(_hh(i, seed_k) * w, pow(_hh(i, seed_k + 1), 1.3) * h)
		var tw := 0.6 + 0.4 * sin(_t * (1.0 + _hh(i, seed_k + 2) * 3.0) + i)
		var big := _hh(i, seed_k + 3) > 0.93
		draw_rect(Rect2(p, Vector2(2, 2) if big else Vector2(1, 1)), Color(1.0, 0.97, 0.9, a * tw))


func _sky(ev: String) -> void:
	var hz := float(sight.get("hz", 150.0))
	var w := float(sight.get("w", 1056.0))
	var h := hz + 4.0
	var theme := String(sight.get("theme", ""))
	match theme:
		"arches":
			var sunset := ev == "sunset" or (day > 0.25 and day < 0.55)
			if day < 0.25:
				_grad(Color(0.02, 0.02, 0.07), Color(0.04, 0.05, 0.12), Color(0.12, 0.1, 0.2), h, w)
				_stars(220 if ev == "stars" else 120, h, w, 0.9, 30)
				if ev == "stars":                                         # the band of the galaxy across the sky
					for i in 500:
						var t := _hh(i, 40)
						var q := Vector2(t * w, h * (0.9 - t * 0.8) + (_hh(i, 41) - 0.5) * 34.0 * (1.0 - absf(_hh(i, 42) - 0.5)))
						draw_rect(Rect2(q, Vector2(1, 1)), Color(0.9, 0.88, 1.0, 0.25 + 0.3 * _hh(i, 43)))
					for g in 10:
						var t2 := g / 10.0
						draw_circle(Vector2(t2 * w + 40.0, h * (0.9 - t2 * 0.8)), 26.0, Color(0.6, 0.55, 0.8, 0.05))
			elif sunset:
				_grad(Color(0.2, 0.16, 0.4), Color(0.86, 0.42, 0.36), Color(1.0, 0.72, 0.36), h, w)
				var arcs: Array = sight.get("arches", [])
				var sx := float((arcs[arcs.size() - 1] as Array)[0]) if not arcs.is_empty() else w * 0.5
				var sun := Vector2(sx, hz - 14.0 + sin(_t * 0.02) * 2.0)
				for g2 in 8:
					draw_circle(sun, 70.0 - g2 * 7.0, Color(1.0, 0.6, 0.3, 0.04 + g2 * 0.015))
				draw_circle(sun, 15.0, Color(1.0, 0.86, 0.55))
				draw_circle(sun, 12.0, Color(1.0, 0.95, 0.75))
				for c in 5:                                                # thin cloud lit from below
					var cy := hz - 60.0 + c * 9.0
					draw_rect(Rect2(fposmod(c * 230.0 + _t * 3.0, w + 200.0) - 200.0, cy, 160.0 - c * 12.0, 2.0), Color(1.0, 0.55, 0.45, 0.5))
			else:
				_grad(Color(0.28, 0.5, 0.86), Color(0.5, 0.7, 0.92), Color(0.92, 0.86, 0.74), h, w)
				for c2 in 6:                                               # high thin cloud
					draw_rect(Rect2(fposmod(c2 * 190.0 + _t * 4.0, w + 220.0) - 220.0, 30.0 + c2 * 11.0, 140.0, 3.0), Color(1, 1, 1, 0.35))
		"lava":
			var lit := clampf(day, 0.0, 1.0)
			_grad(Color(0.1, 0.05, 0.05).lerp(Color(0.32, 0.25, 0.24), lit), Color(0.25, 0.1, 0.06).lerp(Color(0.45, 0.3, 0.24), lit), Color(0.55, 0.2, 0.06).lerp(Color(0.66, 0.38, 0.22), lit), h, w)
			for c3 in 14:                                                  # ash clouds drifting, lit from below
				var cx := fposmod(_hh(c3, 50) * w + _t * (3.0 + _hh(c3, 51) * 4.0), w + 160.0) - 80.0
				var cy2 := 20.0 + _hh(c3, 52) * (hz - 40.0)
				for b in 9:
					var bq := Vector2(cx + b * 12.0 + sin(b * 2.3) * 6.0, cy2 + sin(b * 1.7) * 6.0)
					draw_circle(bq, 10.0 + (b % 3) * 5.0, Color(0.16, 0.1, 0.1, 0.12))
					draw_circle(bq + Vector2(0, 8), 7.0, Color(0.8, 0.3, 0.1, 0.04))
		_:
			_grad(Color(0, 0, 0.01), Color(0.01, 0.01, 0.02), Color(0.03, 0.03, 0.05), h, w)
			_stars(260 if (ev == "stars" or day < 0.25) else 140, h, w, 0.95 if day < 0.4 else 0.6, 60)
			if ev == "stars":
				for i2 in 600:
					var t3 := _hh(i2, 61)
					var q2 := Vector2(t3 * w, h * (0.15 + t3 * 0.7) + (_hh(i2, 62) - 0.5) * 40.0)
					draw_rect(Rect2(q2, Vector2(1, 1)), Color(0.9, 0.9, 1.0, 0.2 + 0.35 * _hh(i2, 63)))
			if day >= 0.25:                                                # the sun, hard and white without air
				var sp := Vector2(w * 0.12, 26.0)
				for g3 in 6:
					draw_circle(sp, 30.0 - g3 * 4.0, Color(1, 1, 0.95, 0.04 + g3 * 0.03))
				draw_circle(sp, 6.0, Color(1, 1, 1))
			if ev == "rise":                                               # the planet it circles, rising behind the far rim
				var pc := Vector2(w * 0.62, hz + 24.0)
				var pr := 112.0
				draw_circle(pc, pr + 5.0, Color(0.5, 0.7, 1.0, 0.12))                    # its air, a thin bright ring
				draw_circle(pc, pr, Color(0.78, 0.62, 0.42))
				for yb in range(int(pc.y - pr), int(pc.y + pr), 2):                    # its bands, each a chord
					var hw2 := sqrt(maxf(0.0, pr * pr - pow(yb + 1.0 - pc.y, 2.0)))
					var bv := sin((yb - pc.y) * 0.09 + sin((yb - pc.y) * 0.031) * 2.0)
					var bc := Color(0.62, 0.45, 0.3, 0.55) if bv > 0.3 else (Color(0.92, 0.82, 0.64, 0.45) if bv < -0.4 else Color(0, 0, 0, 0))
					if bc.a > 0.0:
						draw_rect(Rect2(pc.x - hw2, yb, hw2 * 2.0, 2.0), bc)
				draw_circle(pc + Vector2(-38.0, 30.0), 9.0, Color(0.7, 0.36, 0.22, 0.7))      # a storm in its bands
				for sh in 16:                                                          # the night side: lit from the west
					draw_circle(pc + Vector2(30.0 + sh * 5.0, 0), pr - sh * 2.0, Color(0, 0, 0.02, 0.06))
			if ev == "meteor":
				for mt in 6:
					var ph := fposmod(_t * 0.35 + mt * 0.37, 1.0)
					if ph < 0.25:
						var st := Vector2(_hh(mt, 70) * w, 10.0 + _hh(mt, 71) * hz * 0.5)
						var en := st + Vector2(-90.0, 45.0) * (ph / 0.25)
						draw_line(st + (en - st) * 0.5, en, Color(1.0, 0.95, 0.8, 0.8 * (1.0 - ph * 4.0)), 2.0)
						draw_line(st, st + (en - st) * 0.5, Color(1.0, 0.95, 0.8, 0.25 * (1.0 - ph * 4.0)), 1.0)


func _arches_over(ev: String) -> void:
	var hz := float(sight.get("hz", 150.0))
	var w := float(sight.get("w", 1056.0))
	var rim := float(sight.get("rim", 368.0))
	if day > 0.3:
		for b in 2:                                                       # two raptors circling over the canyon
			var c := Vector2(w * (0.35 + b * 0.3), hz + 40.0 + b * 30.0)
			var a := _t * (0.25 + b * 0.07) + b * 2.0
			var q := c + Vector2(cos(a) * 80.0, sin(a) * 22.0)
			var fl := sin(_t * 6.0 + b) * 1.5
			draw_line(q, q + Vector2(-6, -2 + fl), Color(0.15, 0.08, 0.06), 1.0)
			draw_line(q, q + Vector2(6, -2 + fl), Color(0.15, 0.08, 0.06), 1.0)
	for d in 12:                                                          # sand blown across the near ground
		var ph := fposmod(_t * 0.25 + d * 0.083, 1.0)
		var y := rim + 30.0 + _hh(d, 80) * 400.0
		draw_rect(Rect2(ph * (w + 120.0) - 60.0, y, 18.0 + _hh(d, 81) * 20.0, 1.0), Color(0.95, 0.75, 0.55, 0.3 * sin(ph * PI)))
	match ev:
		"dust":                                                           # a dust devil wandering over the far plain
			var bx := fposmod(_t * 9.0, w + 200.0) - 100.0
			var by := hz + 70.0
			for k in 40:
				var hh := k * 1.6
				var r := 3.0 + hh * 0.18
				var an := _t * 5.0 + k * 0.9
				draw_circle(Vector2(bx + cos(an) * r + sin(k * 0.3) * 2.0, by - hh), 2.0 + k * 0.05, Color(0.88, 0.66, 0.48, 0.25 * (1.0 - k / 40.0)))
			draw_circle(Vector2(bx, by + 2.0), 10.0, Color(0.85, 0.6, 0.42, 0.25))
		"storm":                                                          # a wall of sand along the horizon, coming on
			for x in range(0, int(w), 6):
				var top := hz - 40.0 + sin(x * 0.02 + _t * 0.4) * 12.0 + sin(x * 0.07 - _t) * 5.0
				draw_rect(Rect2(x, top, 6.0, hz + 100.0 - top), Color(0.72, 0.46, 0.3, 0.5))
				draw_circle(Vector2(x + 3.0, top), 9.0, Color(0.8, 0.55, 0.38, 0.45))
			for k3 in 30:                                                  # billows rolling in it
				var bq := Vector2(fposmod(_hh(k3, 85) * w + _t * 12.0, w), hz - 20.0 + _hh(k3, 86) * 90.0)
				draw_circle(bq, 14.0 + _hh(k3, 87) * 10.0, Color(0.6, 0.38, 0.25, 0.08))


func _lava_over(ev: String) -> void:
	var w := float(sight.get("w", 1056.0))
	var rim := float(sight.get("rim", 368.0))
	var cone: Vector2 = sight.get("cone", Vector2(w * 0.5, 90.0))
	var night := clampf(1.0 - day, 0.0, 1.0)
	# the smoke out of the volcano, drifting east
	for p in 18:
		var ph := fposmod(_t * 0.06 + p / 18.0, 1.0)
		var q := cone + Vector2(ph * 120.0 + sin(ph * 6.0 + p) * 6.0, -ph * 110.0)
		draw_circle(q, 6.0 + ph * 22.0, Color(0.22, 0.18, 0.18, 0.45 * (1.0 - ph)))
		draw_circle(q + Vector2(0, 4), 4.0 + ph * 14.0, Color(1.0, 0.4, 0.1, 0.12 * (1.0 - ph) * (1.0 - ph)))
	draw_circle(cone + Vector2(0, 2), 16.0, Color(1.0, 0.5, 0.15, 0.25 + 0.1 * sin(_t * 2.0)))
	# the heat of the rivers glowing, more by night; where they pour down a face, streaks racing down
	var steps: Array = sight.get("steps", [])
	var strong := 1.6 if ev == "glow" else 1.0
	for rv in sight.get("rivers", []):
		var pv: PackedVector2Array = rv
		for k in range(0, pv.size(), 3):
			draw_circle(pv[k], 20.0, Color(1.0, 0.4, 0.1, (0.01 + 0.02 * night) * strong))
		for s in range(1, steps.size()):
			var fy := float(steps[s]) - 14.0
			for k2 in pv.size():
				if absf(pv[k2].y - fy) < 2.0:
					for st in 4:
						var off := fposmod(_t * 40.0 + st * 3.5 + k2, 14.0)
						draw_rect(Rect2(pv[k2].x - 4.0 + st * 2.5, fy + off, 1.0, 3.0), Color(1.0, 0.9, 0.5, 0.7))
					break
		if ev == "flow":                                                   # fresh lava: bright pulses running down
			for pu in 4:
				var idx := int(fposmod(_t * 14.0 + pu * pv.size() / 4.0, float(pv.size())))
				var q2 := pv[idx]
				draw_circle(q2, 6.0, Color(1.0, 0.7, 0.25, 0.22))
				draw_rect(Rect2(q2 - Vector2(2, 1), Vector2(4, 3)), Color(1.0, 0.92, 0.55, 0.55))
	# embers rising
	for e in 40:
		var ph2 := fposmod(_t * (0.12 + _hh(e, 90) * 0.1) + _hh(e, 91), 1.0)
		var q3 := Vector2(_hh(e, 92) * w + sin(_t + e) * 6.0, rim - ph2 * 220.0)
		draw_rect(Rect2(q3, Vector2(1, 1)), Color(1.0, 0.6, 0.2, 0.9 * (1.0 - ph2)))
	if ev == "fountain":                                                  # a fountain of lava bursting from a vent
		var v := Vector2(w * 0.5 + 150.0, (float(steps[2]) + 18.0) if steps.size() > 2 else 260.0)
		for f in 70:
			var life := fposmod(_t * 0.8 + _hh(f, 93), 1.0)
			var vx := (_hh(f, 94) - 0.5) * 50.0
			var vy := -80.0 - _hh(f, 95) * 60.0
			var tt := life * 1.6
			var q4 := v + Vector2(vx * tt, vy * tt + 90.0 * tt * tt)
			draw_rect(Rect2(q4, Vector2(2, 2)), Color(1.0, 0.75 - life * 0.4, 0.2, 1.0 - life * 0.7))
		draw_circle(v, 8.0, Color(1.0, 0.6, 0.2, 0.2))
		draw_circle(v, 3.0, Color(1.0, 0.9, 0.5, 0.8))


func _crater_over(ev: String) -> void:
	var hz := float(sight.get("hz", 150.0))
	var w := float(sight.get("w", 1056.0))
	# a research outpost on the crater floor, its beacon blinking
	var op := Vector2(w * 0.74, hz + 74.0)
	draw_rect(Rect2(op + Vector2(-6, -4), Vector2(12, 4)), Color(0.7, 0.72, 0.76))
	draw_rect(Rect2(op + Vector2(-1, -9), Vector2(1, 5)), Color(0.5, 0.5, 0.55))
	if fposmod(_t, 1.6) < 0.25:
		draw_circle(op + Vector2(-1, -10), 3.0, Color(1.0, 0.25, 0.2, 0.8))
	match ev:
		"shadow":                                                         # the long shadow of the far rim over the floor
			var pts := PackedVector2Array()
			pts.append(Vector2(0, hz + 30.0))
			for x in range(0, int(w) + 8, 8):
				pts.append(Vector2(x, hz + 70.0 + absf(sin(x * 0.009 + 1.0)) * 60.0 + sin(x * 0.05) * 8.0 + _hh(x / 8, 99) * 4.0))
			pts.append(Vector2(w, hz + 30.0))
			draw_colored_polygon(pts, Color(0.02, 0.02, 0.05, 0.55))
		"meteor":                                                         # now and then one strikes far out on the floor
			var ph := fposmod(_t * 0.2, 1.0)
			if ph < 0.15:
				var q := Vector2(w * 0.3 + fposmod(floor(_t * 0.2) * 377.0, w * 0.4), hz + 90.0)
				draw_circle(q, 4.0 + ph * 60.0, Color(1.0, 0.9, 0.7, 0.6 * (1.0 - ph / 0.15)))


## 54a: the Skyring deck – over the clouds below the deck, east of the skyrail's car: this visit's event.
func _skyring(ev: String) -> void:
	var x0 := float(sight.get("x0", 0.0))
	var x1 := float(sight.get("x1", 900.0))
	var vy := float(sight.get("void", 300.0))
	var by := float(sight.get("bottom", 600.0))
	var cx := (x0 + x1) * 0.5
	var night := clampf(1.0 - day * 1.4, 0.0, 1.0)
	match ev:
		"glory":                                                        # the city's shadow on the clouds, rings of colour round it
			var c := Vector2(cx - 30.0, vy + 85.0)
			draw_circle(c, 26.0, Color(0.1, 0.1, 0.16, 0.22))
			draw_circle(c, 14.0, Color(0.1, 0.1, 0.16, 0.18))
			var cols := [Color(0.6, 0.85, 1.0), Color(0.5, 1.0, 0.6), Color(1.0, 0.95, 0.5), Color(1.0, 0.6, 0.35), Color(0.9, 0.4, 0.8)]
			for ring in 2:
				for i in cols.size():
					var r := 34.0 + ring * 26.0 + i * 3.2
					draw_arc(c, r, 0.0, TAU, 64, Color(cols[i], (0.3 - ring * 0.12) * (0.8 + 0.2 * sin(_t * 0.7))), 2.5)
		"lightning":                                                    # storms deep in the clouds flashing
			for s in 5:
				var period := 2.0 + _hh(s, 1) * 3.0
				var ph := fposmod(_t + _hh(s, 2) * period, period)
				if ph < 0.18:
					var q := Vector2(x0 + 40.0 + _hh(s, 3) * (x1 - x0 - 80.0), vy + 30.0 + _hh(s, 4) * 110.0)
					var a2 := (1.0 - ph / 0.18) * (0.6 if ph < 0.05 or ph > 0.1 else 0.25)
					draw_circle(q, 36.0, Color(0.7, 0.8, 1.0, 0.18 * a2))
					draw_circle(q, 18.0, Color(0.85, 0.9, 1.0, 0.3 * a2))
					var p0 := q + Vector2(0, -20)
					for seg in 6:                                            # its bolt, forking
						var p1 := p0 + Vector2((_hh(s * 7 + seg, int(_t / period)) - 0.5) * 12.0, 7.0)
						draw_line(p0, p1, Color(1, 1, 1, a2), 1.0)
						if seg == 2:
							draw_line(p1, p1 + Vector2(9, 6), Color(1, 1, 1, a2 * 0.6), 1.0)
						p0 = p1
		"sunset":                                                       # the star going down behind the deck: gold on the cloud tops
			var sx := cx - 30.0
			draw_rect(Rect2(x0, vy, x1 - x0, by - vy), Color(1.0, 0.5, 0.3, 0.1))
			for k in 26:
				var yy := vy + k * 7.0
				var ww := 22.0 + k * 3.0 + sin(_t * 0.8 + k * 0.7) * 6.0
				draw_rect(Rect2(sx - ww * 0.5 + sin(k * 1.3) * 6.0, yy, ww, 3.0), Color(1.0, 0.75, 0.4, 0.4 * (1.0 - k / 26.0)))
			for g in 6:
				draw_circle(Vector2(sx, vy + 20.0), 90.0 - g * 13.0, Color(1.0, 0.6, 0.3, 0.035))
			for e in 30:                                                 # cloud edges lit gold
				var q := Vector2(x0 + _hh(e, 7) * (x1 - x0), vy + _hh(e, 8) * 150.0)
				draw_rect(Rect2(q, Vector2(10.0 + _hh(e, 9) * 14.0, 1.0)), Color(1.0, 0.7, 0.4, 0.45))
		"moon":                                                         # a moon up behind the deck: its light silver on the cloud tops
			var mx := cx - 30.0
			for k in 26:
				var yy := vy + k * 7.0
				var ww := 16.0 + k * 2.2 + sin(_t * 0.8 + k * 0.7) * 5.0
				draw_rect(Rect2(mx - ww * 0.5 + sin(k * 1.3) * 6.0, yy, ww, 3.0), Color(0.85, 0.9, 1.0, 0.36 * (1.0 - k / 26.0)))
			for g in 6:
				draw_circle(Vector2(mx, vy + 40.0), 70.0 - g * 10.0, Color(0.7, 0.8, 1.0, 0.025))
			for e in 30:                                                 # cloud edges catching it
				var q := Vector2(x0 + _hh(e, 7) * (x1 - x0), vy + _hh(e, 8) * 150.0)
				draw_rect(Rect2(q, Vector2(10.0 + _hh(e, 9) * 14.0, 1.0)), Color(0.9, 0.95, 1.0, 0.3))
		"floaters":                                                     # great floaters drifting on the wind, tendrils hanging
			for f in 4:
				var fx := fposmod(x0 + _hh(f, 5) * (x1 - x0) + _t * (6.0 + f * 2.0), x1 - x0 + 120.0) + x0 - 60.0
				var fy := vy + 30.0 + f * 28.0 + sin(_t * 0.4 + f) * 6.0
				var sz := 18.0 + _hh(f, 6) * 12.0
				draw_circle(Vector2(fx, fy), sz, Color(0.75, 0.85, 1.0, 0.25))
				draw_circle(Vector2(fx - sz * 0.25, fy - sz * 0.3), sz * 0.45, Color(1, 1, 1, 0.25))
				for t in 5:
					var tx := fx - sz * 0.6 + t * sz * 0.3
					draw_line(Vector2(tx, fy + sz * 0.6), Vector2(tx + sin(_t * 1.5 + t + f) * 3.0, fy + sz * 1.8), Color(0.75, 0.85, 1.0, 0.3), 1.0)
				draw_circle(Vector2(fx, fy), sz * 0.3, Color(0.6, 1.0, 0.9, 0.25 * (0.5 + 0.5 * sin(_t * 2.0 + f)) * (0.4 + night)))
