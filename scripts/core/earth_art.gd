extends RefCounted
## Package 56 (Luz): Earth as she really looks – for the intro. The continents are rough outlines in longitude and
## latitude, laid into a 360 × 180 map once; a picture is the globe seen from straight ahead (looking at lon0 / lat0),
## lit from the side: deep sea, green land, sand of the deserts, ice at the poles, clouds from noise on the sphere,
## the lights of cities on the night side, a blue rim of air. Pixel art: `px` across, drawn large with nearest filter.

## [lon, lat] corners, west negative, south negative.
const LANDS := [
	# Africa
	[[-17, 21], [-16, 28], [-10, 31], [-6, 35.8], [10, 37.2], [11, 33], [20, 31], [25, 32], [32, 31.3], [34, 28], [38, 18], [43, 12], [51, 12],
		[48, 5], [41, -2], [40, -10], [36, -18], [35, -24], [32, -29], [27, -34], [20, -35], [17, -29], [14, -22], [12, -14], [13, -6], [9, -1],
		[9, 4], [4, 6], [-3, 5], [-8, 4.5], [-13, 8], [-15, 11], [-17, 15]],
	# Europe and Asia
	[[-9, 36.5], [-9, 43], [-2, 43.5], [-1.5, 46.5], [-4.5, 48.5], [1.5, 50.5], [4, 52], [8, 54], [8.5, 57.5], [10.5, 57.5], [11, 59], [5, 58.5],
		[5, 62], [10, 64], [15, 68.5], [20, 70], [28, 71], [33, 69.5], [41, 67], [44, 68.5], [55, 68.5], [60, 69.5], [69, 73], [80, 72.5],
		[95, 76], [105, 78], [114, 74], [130, 71], [140, 72.5], [160, 69.5], [180, 69], [180, 65], [172, 60], [163, 58], [156, 51], [156, 57],
		[143, 59], [135, 54.5], [141, 52], [140, 48], [131, 42.5], [129, 35], [126.5, 37.5], [125, 40], [121, 39], [119, 35], [122, 30],
		[118, 24], [110, 21], [108, 21.5], [106, 18], [109, 12], [105, 8.7], [100.5, 13.5], [99, 9], [103, 1.5], [100, 3], [98, 8], [97.5, 16],
		[94, 16], [92, 22], [88, 21.5], [80, 15.5], [80, 10], [77, 8], [73, 17], [72.5, 21], [67, 24.5], [62, 25], [57, 25.5], [56, 27],
		[51, 27], [48.5, 30], [50, 30], [53, 26.8], [56.5, 24], [59.5, 22.5], [57, 19], [52, 16], [45, 12.8], [43, 13], [39, 21], [35, 28],
		[34.5, 31.5], [35.5, 36], [30, 36.5], [27, 37], [26, 40], [29, 41], [33, 42], [41, 41], [41.5, 42.5], [37.5, 45], [33.5, 44.5],
		[30.5, 46.5], [28.5, 44], [27.5, 42], [24, 40.5], [22.5, 37], [21, 39], [19.5, 41.8], [16, 43.5], [13.5, 45.5], [12.5, 44], [16, 41.5],
		[18.5, 40], [16, 38], [12.5, 41.5], [10, 44], [7, 43.5], [3, 43.2], [3.2, 41.8], [0, 39.5], [-0.5, 38], [-2, 36.7], [-5.5, 36]],
	# Great Britain and Ireland
	[[-5.5, 50], [1.5, 51], [1.8, 52.8], [0, 53.5], [-1.5, 55.5], [-2, 57.5], [-3.5, 58.6], [-5, 58.5], [-6, 56.5], [-5, 55], [-3, 54.5], [-4.5, 53.2], [-4.5, 51.8]],
	[[-10, 51.6], [-6, 52], [-6, 54], [-7.5, 55.2], [-10, 54]],
	# Iceland, Madagascar, Sri Lanka, Japan, Sumatra, Borneo, New Guinea, Arabia's Sinai closed in Africa/Asia
	[[-24, 64], [-14, 64.5], [-14, 66], [-22, 66.4]],
	[[44, -25], [47, -25], [50, -15.5], [49, -12], [44, -17]],
	[[80, 9.8], [81.8, 7], [80, 6], [79.8, 8]],
	[[130, 31], [132, 34], [135, 34], [140, 35], [141, 38], [142, 41], [140, 40.5], [139.5, 38], [136.5, 37], [133, 35.5], [130.5, 34]],
	[[141.5, 42], [145.5, 43.3], [142, 45.5], [140, 43]],
	[[95.5, 5.5], [98, 4], [104, -2], [106, -5.8], [102, -4], [96, 2]],
	[[109, 1.5], [111, 1], [114, 4.5], [117, 7], [119, 5], [118, 1], [116, -4], [110.5, -3], [109, -0.5]],
	[[105.5, -6], [114, -7], [114.5, -8.5], [106, -7.5]],
	[[131, -1.5], [138, -1.5], [146, -6], [150, -10.5], [141, -9], [137.5, -6], [132, -4]],
	# Australia, New Zealand
	[[113.5, -22], [114.5, -26], [115, -34], [117.5, -35], [123, -34], [129, -31.5], [135, -34.8], [138, -35.5], [140, -38], [146, -39],
		[150, -37.5], [153.5, -28], [153, -25], [150, -22], [146, -18.5], [145.5, -15], [142.5, -10.7], [141.5, -13], [141, -17], [139.5, -17.5],
		[136.5, -15], [136.5, -12], [132, -11.2], [130, -13], [126.5, -14], [122, -17], [121, -19.5], [116, -20.8]],
	[[172.5, -34.5], [178.5, -37.5], [176, -41.5], [174, -41], [172.5, -40.5]],
	[[173, -41], [174, -42], [171, -45.5], [167, -46.5], [168.5, -44], [171.5, -41.5]],
	# North and Central America
	[[-168, 65.5], [-162, 70], [-156, 71.3], [-141, 69.8], [-128, 70], [-115, 68.5], [-95, 68], [-90, 69], [-82, 69.5], [-80, 63],
		[-93, 62], [-94, 58.5], [-90, 57], [-82, 55], [-79, 51.5], [-78.5, 58.5], [-77.5, 62.5], [-72, 61.5], [-64.5, 60.5], [-61, 56.5],
		[-56, 52], [-60, 50], [-66, 49.5], [-64, 47], [-60, 46], [-66, 44.5], [-70, 43.5], [-70.5, 41.6], [-74, 40.5], [-76, 38], [-76, 35],
		[-81, 31.5], [-80, 27], [-80.5, 25.2], [-82, 26.5], [-83, 29.8], [-89, 30.3], [-94, 29.6], [-97.3, 27.5], [-97.5, 22], [-95.5, 18.7],
		[-91, 18.8], [-90.5, 21], [-87, 21.5], [-88.5, 16], [-84, 15.5], [-83.5, 11], [-81.5, 8.8], [-77.5, 8.6], [-78.5, 7.2], [-80.5, 7.4],
		[-85.7, 10], [-87.5, 13], [-91.5, 14], [-94.5, 16], [-97.5, 16], [-105.5, 20], [-105.5, 23], [-109.5, 26], [-112.5, 29.5],
		[-114.8, 31.5], [-114, 28], [-111, 24], [-110, 23], [-112, 25], [-114.5, 28], [-117, 32.5], [-120.5, 34.5], [-122.5, 37.5], [-124, 40.5],
		[-124.5, 43], [-124, 46.5], [-122.5, 48], [-127, 50.5], [-131, 54], [-134, 58], [-140, 60], [-147, 61], [-151, 59.5], [-155, 57.8],
		[-158, 56.5], [-162, 55], [-158, 58.5], [-162, 60], [-165, 62.5]],
	# Cuba, Hispaniola
	[[-85, 21.8], [-82, 23.2], [-77, 21.8], [-74, 20], [-77.5, 19.8], [-81, 21.5]],
	[[-74.5, 19.8], [-69, 19.8], [-68.4, 18.5], [-74, 18.3]],
	# the Arctic islands, Greenland
	[[-73, 78], [-60, 82], [-32, 83.5], [-20, 82], [-18, 76], [-22, 70], [-30, 68.5], [-40, 65], [-43, 60], [-50, 61.5], [-53, 66], [-55, 70],
		[-60, 75.5], [-70, 76.5]],
	[[-120, 72], [-100, 74], [-80, 74], [-62, 82], [-90, 81], [-115, 77]],
	[[-90, 72], [-75, 73.5], [-62, 67], [-65, 63], [-77, 64], [-82, 66.5]],
	[[10, 77], [18, 80.5], [27, 80], [22, 77.5], [15, 76.5]],
	[[52, 71], [58, 75.5], [68, 77], [56, 73], [53.5, 72]],
	# South America
	[[-77.5, 8.6], [-72, 12], [-66, 10.8], [-61.5, 10.6], [-57, 6], [-51.5, 4.5], [-50, 1.8], [-48.5, -1.2], [-44.5, -2.5], [-40, -2.8], [-35.2, -5.5],
		[-35, -9], [-38.5, -13], [-39, -17.5], [-41, -22], [-44.5, -23.2], [-48.5, -26], [-48.8, -28.5], [-53, -33.5], [-57.5, -35.2], [-57, -38],
		[-62, -39], [-65, -41], [-63.5, -42.7], [-65, -45], [-67.5, -46.5], [-65.8, -48], [-69, -51.5], [-68.5, -53], [-66.5, -55], [-71, -55],
		[-74.5, -52], [-75.5, -47], [-73.5, -42], [-73.5, -37], [-71.5, -30], [-70.3, -18.5], [-75.5, -15], [-79, -8], [-81.2, -5.5],
		[-80, -2], [-80.5, 0.5], [-78.8, 2], [-77.5, 4], [-77.3, 7.3]],
]
const LIGHTS := [[0, 49], [10, 51], [-3, 40], [12, 42], [30, 45], [37, 55], [31, 30], [3, 6.5], [28, -26], [-75, 41], [-87, 41], [-118, 34],
	[-99, 19.5], [-46, -23.5], [-58, -34.5], [77, 28], [73, 19], [88, 22.5], [116, 40], [121, 31], [114, 22.5], [139.5, 35.6], [127, 37.5],
	[151, -33.8], [145, -37.8], [100.5, 13.7], [106.8, -6.2], [55, 25], [44, 33], [51, 35.7], [-43, -22.9], [36.8, -1.3], [-122, 37.7],
	[-79.4, 43.7], [-73.6, 45.5], [18, 59.3], [24, 60], [-0.1, 51.5], [2.3, 48.8], [13.4, 52.5], [16.4, 48.2], [21, 52.2], [-9.1, 38.7]]
const DESERTS := [[-15, 15, 35, 32], [35, 12, 60, 32], [55, 25, 75, 45], [80, 36, 120, 48], [115, -32, 140, -18], [12, -28, 22, -18],
	[-117, 25, -103, 38], [-72, -30, -68, -17]]

static var _map: PackedByteArray = PackedByteArray()      # 360 × 180: 0 sea, 1 land, 2 desert, 3 ice
static var _cache := {}


static func _inside(poly: Array, x: float, y: float) -> bool:
	var c := false
	var n := poly.size()
	var j := n - 1
	for i in n:
		var yi := float(poly[i][1])
		var yj := float(poly[j][1])
		if (yi > y) != (yj > y):
			var xi := float(poly[i][0])
			var xj := float(poly[j][0])
			if x < (xj - xi) * (y - yi) / (yj - yi) + xi:
				c = not c
		j = i
	return c


static func _build_map() -> void:
	_map.resize(360 * 180)
	var boxes := []                                       # each outline's bounds – most cells skip most outlines
	for poly in LANDS:
		var bb := Rect2(Vector2(poly[0][0], poly[0][1]), Vector2.ZERO)
		for q in poly:
			bb = bb.expand(Vector2(q[0], q[1]))
		boxes.append(bb)
	for la in 180:
		var lat := 89.5 - la
		for lo in 360:
			var lon := -179.5 + lo
			var v := 0
			for pi in LANDS.size():
				var bb: Rect2 = boxes[pi]
				if lon < bb.position.x or lon > bb.end.x or lat < bb.position.y or lat > bb.end.y:
					continue
				if _inside(LANDS[pi], lon, lat):
					v = 1
					break
			if lat < -66.0 or (lat < -62.0 and lon > -65.0 and lon < -55.0):
				v = 3                                     # Antarctica and its peninsula
			if v == 1:
				for d in DESERTS:
					var inset := minf(minf(lon - float(d[0]), float(d[2]) - lon), minf(lat - float(d[1]), float(d[3]) - lat))
					var wob := sin(lon * 0.3 + lat * 0.55) * 2.5 + sin(lon * 0.7 - lat * 0.4) * 1.5
					if inset + wob > 1.5:
						v = 2
				if lat > 66.0 and lon > -75.0 and lon < -15.0:
					v = 3                                 # Greenland's ice
			_map[la * 360 + lo] = v


static func land_at(lon: float, lat: float) -> int:
	if _map.is_empty():
		_build_map()
	var lo := clampi(int(floor(fposmod(lon + 180.0, 360.0))), 0, 359)
	var la := clampi(int(floor(89.999 - lat)), 0, 179)
	return _map[la * 360 + lo]


## An Earth-like world of its own (the main menu): continents from noise, seed `world`.
static var _wn: FastNoiseLite
static var _wn_seed := -1


static func world_at(world: int, lon: float, lat: float) -> int:
	if _wn == null or _wn_seed != world:
		_wn = FastNoiseLite.new()
		_wn.seed = world
		_wn.frequency = 1.1
		_wn.fractal_octaves = 5
		_wn_seed = world
	var g := Vector3(cos(deg_to_rad(lat)) * sin(deg_to_rad(lon)), sin(deg_to_rad(lat)), cos(deg_to_rad(lat)) * cos(deg_to_rad(lon)))
	var h := _wn.get_noise_3d(g.x * 1.6, g.y * 1.6, g.z * 1.6)
	if absf(lat) > 70.0 + h * 12.0:
		return 3
	if h < 0.06:
		return 0
	var dry := _wn.get_noise_3d(g.x * 4.0 + 9.0, g.y * 4.0, g.z * 4.0)
	if absf(absf(lat) - 24.0) < 11.0 and dry > -0.05:
		return 2
	return 1


## The globe `px` art pixels across, looking at lon0/lat0, the sun from `sun` (x right, y down, z towards you);
## clouds turned by `cloud_lon` so they can drift on their own. `world` >= 0: an Earth-like world of its own.
static func texture(px: int, lon0: float, lat0: float, sun: Vector3 = Vector3(-0.75, -0.3, 0.6), cloud_lon: float = 0.0, world: int = -1) -> ImageTexture:
	var key := "%d_%.1f_%.1f_%.2f_%.2f_%.2f_%.1f_%d" % [px, lon0, lat0, sun.x, sun.y, sun.z, cloud_lon, world]
	var land := func(lo: float, la: float) -> int: return land_at(lo, la) if world < 0 else world_at(world, lo, la)
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(px, px, false, Image.FORMAT_RGBA8)
	var nz := FastNoiseLite.new()
	nz.seed = 56
	nz.frequency = 3.0
	nz.fractal_octaves = 4
	var nz2 := FastNoiseLite.new()
	nz2.seed = 12600
	nz2.frequency = 7.0
	var L := sun.normalized()
	var r := px * 0.5 - 3.0
	var c0 := Vector2(px * 0.5, px * 0.5)
	var cl0 := cos(deg_to_rad(lat0))
	var sl0 := sin(deg_to_rad(lat0))
	for y in px:
		for x in px:
			var d := (Vector2(x + 0.5, y + 0.5) - c0) / r
			var dd := d.length_squared()
			if dd > 1.0:
				var rim := sqrt(dd)
				if rim < 1.06:
					var lit := clampf(Vector3(d.x / rim, d.y / rim, 0.0).dot(L) + 0.35, 0.0, 1.0)
					img.set_pixel(x, y, Color(0.4, 0.65, 1.0, (1.0 - (rim - 1.0) / 0.06) * 0.75 * lit))
				continue
			var z := sqrt(1.0 - dd)
			var n := Vector3(d.x, d.y, z)                          # the surface seen from the front
			# turn the view back to the globe: tilt by lat0, then the longitude
			var gy := -n.y * cl0 + n.z * sl0
			var gz := n.y * sl0 + n.z * cl0
			var lat := rad_to_deg(asin(clampf(gy, -1.0, 1.0)))
			var lon := lon0 + rad_to_deg(atan2(n.x, gz))
			var kind: int = land.call(lon, lat)
			var light := n.dot(L)
			var day := clampf(light * 2.2 + 0.25, 0.0, 1.0)
			var g := Vector3(cos(deg_to_rad(lat)) * sin(deg_to_rad(lon)), sin(deg_to_rad(lat)), cos(deg_to_rad(lat)) * cos(deg_to_rad(lon)))
			var detail := nz2.get_noise_3d(g.x, g.y, g.z)
			var col: Color
			match kind:
				0:
					var shallow := 0.0
					for o in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
						if int(land.call(lon + o[0] * 1.2, lat + o[1] * 1.2)) != 0:
							shallow = 1.0
					col = Color(0.04, 0.13, 0.33).lerp(Color(0.08, 0.27, 0.48), shallow * 0.5 + detail * 0.15)
				1:
					var dry := clampf(0.5 - absf(absf(lat) - 25.0) / 30.0, 0.0, 0.5)
					col = Color(0.18, 0.4, 0.16).lerp(Color(0.42, 0.45, 0.22), dry + detail * 0.3)
					if absf(lat) < 12.0:
						col = col.lerp(Color(0.1, 0.3, 0.1), 0.5)         # rain forest
					if absf(lat) > 55.0:
						col = col.lerp(Color(0.3, 0.36, 0.28), 0.5)       # taiga and tundra
				2:
					col = Color(0.76, 0.62, 0.38).lerp(Color(0.62, 0.45, 0.28), clampf(detail + 0.4, 0.0, 1.0))
				3:
					col = Color(0.9, 0.93, 0.97)
			if kind != 3 and absf(lat) > 72.0:
				col = Color(0.88, 0.92, 0.96)                          # sea ice
			# clouds, turned on their own
			var cg := Vector3(cos(deg_to_rad(lat)) * sin(deg_to_rad(lon + cloud_lon)), sin(deg_to_rad(lat)), cos(deg_to_rad(lat)) * cos(deg_to_rad(lon + cloud_lon)))
			var cv := nz.get_noise_3d(cg.x * 1.6, cg.y * 2.4, cg.z * 1.6)
			var band := 0.12 if absf(lat) < 8.0 or (absf(lat) > 45.0 and absf(lat) < 65.0) else -0.06
			var cloud := clampf((cv + band - 0.16) * 2.6, 0.0, 0.85)
			col = col.lerp(Color(0.97, 0.98, 1.0), cloud)
			var shade := col * (0.08 + 0.92 * day)
			shade = shade.lerp(Color(0.5, 0.72, 1.0), pow(1.0 - z, 3.0) * 0.6 * day)   # air at the limb
			if day < 0.35 and kind in [1, 2] and cloud < 0.4:
				if world >= 0:
					if detail > 0.28 and kind == 1:
						shade = shade.lerp(Color(1.0, 0.8, 0.4), (1.0 - day / 0.35) * 0.85)
				for p in ([] if world >= 0 else LIGHTS):
					var dl := Vector2(fposmod(lon - float(p[0]) + 180.0, 360.0) - 180.0, lat - float(p[1]))
					if dl.length() < 1.4 + detail * 1.6 and detail > -0.25:
						shade = shade.lerp(Color(1.0, 0.8, 0.4), (1.0 - day / 0.35) * 0.9)
						break
			shade.a = 1.0
			img.set_pixel(x, y, shade)
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex
