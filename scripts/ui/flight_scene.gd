class_name FlightScene
extends CanvasLayer
## Package 50 (0.7.50.3): the flight down through the air to the place you picked – seen from above, like the rest of
## the game. The planet's own ground passes below (sea and coasts, dunes, ice and its cracks, glowing lava, craters –
## in the planet's colours) and comes closer, the ship's shadow closes in on her, clouds drift between you and the
## ground where there is air, the last of the entry heat fades; at the end the place itself comes into view (the
## blocks and lights of a city, domes, a pit mine, ruins, a wreck, a camp). Then the touchdown follows.

signal finished

const DURATION := 5.6

var body: Dictionary = {}
var site: Dictionary = {}
var atmo := false
var _t := 0.0
var _vs := Vector2(1600, 900)
var _ground: Sprite2D
var _clouds: Array = []               # [sprite, speed, base alpha]
var _ship: Sprite2D
var _shadow: Sprite2D
var _haze: ColorRect
var _place: Node2D
var _fx: Node2D
var _scroll := Vector2.ZERO
var _done := false
var _dest_y := 0.0                    # (unused since 0.7.50.6 – the place lies on the ground itself)
var _scroll0 := Vector2.ZERO          # 0.7.50.6: where the flight starts on the ground picture
var _place_at := Vector2.ZERO         # the place's spot on the ground picture – it moves with the ground
var _img: Image                       # the ground picture and which of its pixels are sea
var _sea := PackedByteArray()
var _S := 384
var city_day := 0.0                   # 0.7.50.6: the city by day (its roofs) or by night (its lights)
var city_style: Dictionary = {}
var lander := false                   # 0.7.50.4: a small place – the ship sends her landing drone down
var _drone: Sprite2D
var _ship_s := 1.0                    # the ship's base scale
var _drone_s := 1.0
const DRONE_AT := 0.46                # when the landing drone is launched (share of the flight)
# 0.7.50.15 (Luz): the way back up by the landing drone – it climbs off the pad, the ship comes down over it and takes
# it into her bay, then pulls away
const UP_TIME := 6.4
const CATCH_AT := 0.6                 # when the drone rises into her bay (share of the climb)
var up := false
var _up_scroll := Vector2.ZERO
var _clamped := false
var _drone_from := Vector2.ZERO       # up: the pad it lifts off from (screen)
# 0.7.50.16 (Luz): the drone and the ship to their real sizes – a big ship is huge beside its drone
const DRONE_M := 9.8                  # the drone picture's length (m)
const DRONE_MIN_PX := 30.0            # it never gets smaller than this on screen
var _ship_m := 30.0                   # her length (m)
var _home_y := 0.58                   # where she flies (share of the screen height)


## 0.7.50.15: the climb back up by the landing drone, caught by the ship.
func open_up(p_body: Dictionary, p_site: Dictionary) -> void:
	up = true
	open(p_body, p_site)


func open(p_body: Dictionary, p_site: Dictionary) -> void:
	layer = 13
	body = p_body
	site = p_site
	atmo = Universe.has_atmosphere(body)
	lander = String(site.get("kind", "")) != "city" or up
	_vs = get_viewport().get_visible_rect().size if get_viewport() != null else Vector2(1600, 900)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var bt := Universe.body_type(String(body.get("type", "")))
	# the ground: a tiling picture of this world, scrolled and slowly growing (you come closer)
	_ground = Sprite2D.new()
	var gd := ground_data(body)
	_ground.texture = gd["tex"]
	_img = gd["img"]
	_sea = gd["sea"]
	_S = _img.get_width()
	_ground.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_ground.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_ground.region_enabled = true
	_ground.position = _vs * 0.5
	add_child(_ground)
	# the place itself, drawn on the ground
	_place = Node2D.new()
	_place.draw.connect(_draw_place)
	add_child(_place)
	# the ship's shadow on the ground, the ship, the heat and flame
	var f := GameState.active()
	var tex: Texture2D = PixelArt.ship_texture(f.hull_id if f != null else "dragonfly", (f.gov if f.gov != "" else f.faction) if f != null else "player")
	_shadow = Sprite2D.new()
	_shadow.texture = tex
	_shadow.rotation = -PI * 0.5
	_shadow.modulate = Color(0, 0, 0, 0.45)
	add_child(_shadow)
	_fx = Node2D.new()
	_fx.draw.connect(_draw_fx)
	add_child(_fx)
	_ship = Sprite2D.new()
	_ship.texture = tex
	_ship.rotation = -PI * 0.5                 # nose up: she flies up the screen, the ground passes downwards
	_ship.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_shadow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var tw := maxf(tex.get_width(), 1.0)
	_ship_m = float(f.hull().get("length", 30)) if f != null else 30.0
	var ss := clampf(150.0 / tw, 2.0, 5.0)
	var dpx := ss * tw * DRONE_M / _ship_m                          # the drone beside her, to scale
	if up:
		# up close for the catch: the drone big enough to see, the ship as big as that makes her (a big ship fills
		# the sky over it); she flies higher up the screen, the drone climbs to her from below
		var ship_px := clampf(maxf(tw * ss * 1.45, 56.0 * _ship_m / DRONE_M), 120.0, _vs.y * 0.78)
		ss = ship_px / tw
		dpx = maxf(ship_px * DRONE_M / _ship_m, DRONE_MIN_PX)
		_home_y = clampf(0.5 - (ship_px * 0.5 + dpx + 40.0) / _vs.y * 0.35, 0.3, 0.5)
	_ship.scale = Vector2.ONE * ss
	_shadow.scale = Vector2.ONE * ss
	_ship.position = _vs * Vector2(0.5, _home_y)
	add_child(_ship)
	_ship_s = ss
	if lander:
		_drone = Sprite2D.new()
		_drone.texture = lander_texture()
		_drone.rotation = -PI * 0.5
		_drone.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_drone_s = maxf(dpx, DRONE_MIN_PX) / float(LanderArt.W)
		_drone.visible = false
		add_child(_drone)
		if up:
			move_child(_drone, _ship.get_index())     # she is above it: it slides in under her belly
	# clouds above it all, and the air's own haze
	if atmo:
		var ct := cloud_texture(int(hash(String(body.get("id", "")))), bt.get("cloud", Color(1, 1, 1)))
		for i in 3:
			var c := Sprite2D.new()
			c.texture = ct
			c.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			c.region_enabled = true
			c.region_rect = Rect2(Vector2(i * 173, i * 97), _vs / (2.2 + i * 0.9))
			c.scale = Vector2.ONE * (2.2 + i * 0.9)
			c.position = _vs * 0.5
			c.modulate.a = 0.0
			add_child(c)
			_clouds.append([c, 260.0 + i * 140.0, 0.55 - i * 0.12])
		_haze = ColorRect.new()
		var ac = bt.get("atmo", Color(0.6, 0.8, 1.0, 0.5))
		_haze.color = Color(ac.r, ac.g, ac.b, 0.3) if ac is Color else Color(0.6, 0.8, 1.0, 0.3)
		_haze.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_haze.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_haze)
	var title := UI.label("%s  ·  %s" % [String(site.get("name", "")), String(body.get("name", ""))], 20, UI.NEON_CYAN)
	title.position = Vector2(30, 24)
	add_child(title)
	# 0.7.50.6: the place lies on the ground and comes with it – where the ship will be at the end of the flight;
	# shifted so that it stands on land, not on the sea
	var g_end := lerpf(1.6, 4.2, 1.0)
	_place_at = Vector2(0, -_dist(DURATION)) + (_vs * Vector2(0.5, 0.58) + Vector2(0, -40.0) - _vs * 0.5) / g_end
	var land := _nearest_land(_place_at)
	_scroll0 = land - _place_at
	_place_at = land
	_scroll = _scroll0
	_up_scroll = _scroll0 + Vector2(0, -_dist(DURATION))       # up: from where the flight down ended
	_drone_from = _vs * 0.5 + (_place_at + _pad_off() * 4.0 - _up_scroll) * 4.2
	if String(site.get("kind", "")) == "city":
		var city := Universe.city_station(GameState.current_system, body, site)
		city_day = float(city.get("day", 0.0))
		city_style = CityStyle.of(city)
		city_style_key = CityStyle.key_for(city)
		_build_city()
	Audio.play("boost", "lift-off" if up else "flight down")
	_update(0.0)


func _process(delta: float) -> void:
	if _done:
		return
	_t += delta
	_update(delta)
	if _t >= (UP_TIME if up else DURATION):
		_done = true
		finished.emit()


func _update(delta: float) -> void:
	if up:
		_update_up(delta)
		return
	var k := clampf(_t / DURATION, 0.0, 1.0)
	var gscale := lerpf(1.6, 4.2, smoothstep(0.0, 1.0, k))           # the ground comes closer
	_scroll = _scroll0 + Vector2(0, -_dist(_t))
	_ground.scale = Vector2.ONE * gscale
	_ground.region_rect = Rect2(_scroll - _vs / gscale * 0.5, _vs / gscale)
	# the shadow closes in on the ship as she comes down
	var alt := 1.0 - k
	_shadow.position = _ship.position + Vector2(40.0 + 160.0 * alt, 60.0 + 200.0 * alt)
	_shadow.modulate.a = lerpf(0.18, 0.55, k)
	var home := _vs * Vector2(0.5, 0.58) + Vector2(sin(_t * 1.3) * 6.0, sin(_t * 2.1) * 3.0)
	_ship.position = home
	if not lander:
		# into the city: she grows smaller and smaller as she sinks into its lights
		var sk := 1.0 - smoothstep(0.58, 1.0, k) * 0.92
		_ship.scale = Vector2.ONE * _ship_s * sk
		_shadow.scale = _ship.scale
		_shadow.position = _ship.position + (_shadow.position - _ship.position) * sk
		_shadow.modulate.a *= sk
	elif k >= DRONE_AT:
		# the landing drone drops out of her drone bay; she pulls up and away (nearer to you, bigger, gone),
		# and you follow the drone down
		var dk := clampf((k - DRONE_AT) / (1.0 - DRONE_AT), 0.0, 1.0)
		var pull := smoothstep(0.0, 0.45, dk)
		_ship.position = home + Vector2(0, -_vs.y * 0.9 * pull * pull)
		_ship.scale = Vector2.ONE * _ship_s * lerpf(1.0, 1.7, pull)
		_ship.modulate.a = 1.0 - smoothstep(0.25, 0.45, dk)
		_drone.visible = true
		_drone.position = home + Vector2(0, 40.0 * (1.0 - smoothstep(0.0, 0.2, dk)))
		_drone.scale = Vector2.ONE * _drone_s * lerpf(0.35, 1.0, smoothstep(0.0, 0.25, dk))
		_shadow.texture = _drone.texture
		_shadow.scale = _drone.scale
		_shadow.position = _drone.position + Vector2(30.0 + 90.0 * (1.0 - dk), 40.0 + 110.0 * (1.0 - dk))
	for c in _clouds:
		var sp: Sprite2D = c[0]
		var r := sp.region_rect
		r.position.y -= float(c[1]) * delta / sp.scale.x
		sp.region_rect = r
		# the clouds thin out as you get below them
		sp.modulate.a = float(c[2]) * clampf(1.0 - k * 1.1, 0.0, 1.0) * smoothstep(0.0, 0.12, k)
	if _haze != null:
		_haze.color.a = lerpf(0.32, 0.04, k)
	_place.queue_redraw()
	_fx.queue_redraw()


## 0.7.50.15: up by the drone – the ground falls away below it, the clouds close in; the ship comes down over it
## out of the sky, takes it up into her bay on a tractor beam, the clamps close, and she pulls away.
func _update_up(delta: float) -> void:
	var k := clampf(_t / UP_TIME, 0.0, 1.0)
	var gscale := lerpf(4.2, 1.4, smoothstep(0.0, 1.0, k))
	_up_scroll.y -= lerpf(110.0, 560.0, k) * delta / gscale
	_scroll = _up_scroll
	_ground.scale = Vector2.ONE * gscale
	_ground.region_rect = Rect2(_scroll - _vs / gscale * 0.5, _vs / gscale)
	var home := _vs * Vector2(0.5, _home_y) + Vector2(sin(_t * 1.3) * 5.0, sin(_t * 2.1) * 2.5)
	var below := home + Vector2(0, minf(_ship_len_px() * 0.5 + LanderArt.W * _drone_s + 60.0, _vs.y * 0.95 - home.y))
	# the drone: off the pad and up, then into her bay
	var rise := smoothstep(CATCH_AT, CATCH_AT + 0.2, k)
	var climb := smoothstep(0.0, 0.25, k)
	_drone.visible = rise < 0.999
	_drone.position = _drone_from.lerp(below, climb).lerp(home, rise)
	_drone.scale = Vector2.ONE * _drone_s * lerpf(1.0, 1.12, rise)
	_drone.modulate.a = 1.0 - smoothstep(0.75, 1.0, rise)
	# its shadow stays on the ground, falling behind and fading
	_shadow.texture = _drone.texture
	_shadow.scale = Vector2.ONE * _drone_s * lerpf(1.0, 0.6, climb)
	_shadow.position = _drone.position + Vector2(30.0 + 220.0 * k, 40.0 + 260.0 * k)
	_shadow.modulate.a = 0.5 * (1.0 - smoothstep(0.0, 0.5, k))
	# the ship: down out of the sky over it, holding, then away
	var arr := smoothstep(0.26, 0.56, k)
	var pull := smoothstep(0.86, 1.0, k)
	_ship.position = home + Vector2(0, -_vs.y * 0.9 * pow(1.0 - arr, 2.0)) + Vector2(0, -_vs.y * 0.9 * pull * pull)
	_ship.scale = Vector2.ONE * _ship_s * lerpf(1.7, 1.0, arr) * lerpf(1.0, 1.7, pull)
	_ship.modulate.a = smoothstep(0.26, 0.38, k) * (1.0 - smoothstep(0.93, 1.0, k))
	if rise >= 0.999 and not _clamped:
		_clamped = true
		Audio.play("dock_clamp", "drone caught")
	for c in _clouds:
		var sp: Sprite2D = c[0]
		var r := sp.region_rect
		r.position.y -= float(c[1]) * delta / sp.scale.x
		sp.region_rect = r
		sp.modulate.a = float(c[2]) * smoothstep(0.35, 0.95, k)            # up into the clouds
	if _haze != null:
		_haze.color.a = lerpf(0.04, 0.32, k)
	_place.queue_redraw()
	_fx.queue_redraw()


## Her length on screen now (px).
func _ship_len_px() -> float:
	return _ship.texture.get_width() * _ship.scale.x


## Her flame, below her (she flies up the screen) – from her tail, as big as she is.
func _ship_flame(p: Vector2, thrust: float) -> void:
	var half := _ship_len_px() * 0.5
	var bw := _ship.texture.get_height() * _ship.scale.x
	var tail := p + Vector2(0, half * 0.92)
	for j in 3:
		var len := half * (0.7 - j * 0.16) * thrust * (0.85 + 0.15 * sin(_t * 30.0 + j))
		var w := bw * (0.14 - j * 0.035)
		_fx.draw_colored_polygon(PackedVector2Array([tail + Vector2(-w, 0), tail + Vector2(0, len), tail + Vector2(w, 0)]),
			Color([Color(1.0, 0.5, 0.15), Color(1.0, 0.8, 0.3), Color(1, 1, 0.85)][j], 0.55 * _ship.modulate.a))


## Where a place's landing pad lies from its middle (blocks) – as _draw_place draws it.
func _pad_off() -> Vector2:
	match String(site.get("kind", "")):
		"outpost", "research":
			return Vector2(0, 3)
		"mine":
			return Vector2(4, 6)
		"ruins":
			return Vector2(0, 8)
		"crash":
			return Vector2(0, 10)
		"city":
			return Vector2(0, 2)
	return Vector2.ZERO


## The drone's own lift: its four fans glowing, the two thrusters at its tail (screen: nose up).
func _drone_fx(q: Vector2, sc: float, a: float) -> void:
	for f in LanderArt.FANS:
		var rel: Vector2 = (f as Vector2) - LanderArt.C
		var at := q + Vector2(rel.y, -rel.x) * sc
		var fl := 0.8 + 0.2 * sin(_t * 40.0 + rel.x)
		_fx.draw_circle(at, 4.2 * sc * fl, Color(0.35, 0.95, 1.0, 0.16 * a))
		_fx.draw_circle(at, 2.2 * sc, Color(0.6, 1.0, 1.0, 0.22 * a))
	for jd in 2:
		var tail := q + Vector2(0, (LanderArt.C.x + 0.5) * sc)
		var ln := (5.0 - jd * 1.6) * sc * (0.85 + 0.15 * sin(_t * 34.0 + jd))
		for side in [-3.0, 3.0]:
			var b: Vector2 = tail + Vector2(side * sc, 0)
			_fx.draw_colored_polygon(PackedVector2Array([b + Vector2(-1.4 + jd * 0.5, 0) * sc, b + Vector2(0, ln), b + Vector2(1.4 - jd * 0.5, 0) * sc]),
				Color([Color(1.0, 0.6, 0.2), Color(1, 1, 0.85)][jd], 0.6 * a))


func _draw_fx() -> void:
	var p := _ship.position
	var fs := _ship.scale.x / _ship_s
	if up:
		var k := clampf(_t / UP_TIME, 0.0, 1.0)
		if _drone.visible:
			_drone_fx(_drone.position, _drone.scale.x, _drone.modulate.a)
		# the tractor beam from her bay down to it, then the flash of the clamps
		var beam := smoothstep(CATCH_AT - 0.06, CATCH_AT, k) * (1.0 - smoothstep(CATCH_AT + 0.2, CATCH_AT + 0.24, k))
		if beam > 0.0:
			var dq := _drone.position
			var wd := 9.0 * _drone.scale.x
			_fx.draw_colored_polygon(PackedVector2Array([p + Vector2(-wd * 0.5, 0), p + Vector2(wd * 0.5, 0), dq + Vector2(wd, 0), dq + Vector2(-wd, 0)]),
				Color(0.35, 0.95, 1.0, 0.3 * beam))
			for i in 5:
				var ry := fposmod(_t * 1.6 + i * 0.2, 1.0)
				var rp := dq.lerp(p, ry)
				_fx.draw_arc(rp, lerpf(wd, wd * 0.5, ry), 0.0, TAU, 28, Color(0.7, 1.0, 1.0, 0.7 * beam * (1.0 - ry)), 3.0)
		var flash := 1.0 - clampf(absf(k - (CATCH_AT + 0.2)) / 0.04, 0.0, 1.0)
		if flash > 0.0:
			_fx.draw_circle(p, 60.0 * fs, Color(0.7, 1.0, 1.0, 0.5 * flash))
		if _ship.modulate.a <= 0.02:
			return
		# her flame – a glow while she holds, full as she pulls away
		var thrust := smoothstep(0.84, 0.9, k)
		if thrust <= 0.01:
			return
		_ship_flame(p, thrust)
		return
	if lander and _drone != null and _drone.visible:
		var dk := clampf((_t / DURATION - DRONE_AT) / (1.0 - DRONE_AT), 0.0, 1.0)
		if dk < 0.12:
			_fx.draw_circle(p + Vector2(0, 30), 40.0 * (1.0 - dk / 0.12), Color(1.0, 0.9, 0.6, 0.6 * (1.0 - dk / 0.12)))   # the bay
		# the drone's own lift: its fans and thrusters
		_drone_fx(_drone.position, _drone.scale.x, 1.0)
		if _ship.modulate.a <= 0.02:
			return
	# the last of the entry heat, at the start
	var heat := clampf(1.0 - _t / 1.6, 0.0, 1.0) if atmo else 0.0
	if heat > 0.0:
		for i in 4:
			_fx.draw_circle(p + Vector2(0, -20), 90.0 - i * 18.0, Color(1.0, 0.6 - i * 0.08, 0.25, heat * (0.12 + i * 0.06)))
	# the flame, below her (she flies up)
	_ship_flame(p, 1.0)


## The place ahead: it comes into view at the top and slides down to meet the ship.
func _draw_place() -> void:
	var gscale := _ground.scale.x
	var c := _to_screen(_place_at)
	if c.y < -900.0:
		return
	var kd := String(site.get("kind", "outpost"))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(site.get("id", "")))
	var u := gscale * 4.0                       # one "block" in screen px
	# the place stands on its own ground (no city on the open sea)
	var bt := Universe.body_type(String(body.get("type", "")))
	var land: Color = Color(bt.get("b", Color(0.45, 0.42, 0.38))).lerp(Color(bt.get("c", Color(0.6, 0.56, 0.48))), 0.4)
	if kd == "city":
		_draw_city_lights(c, u, rng)
		return
	var plate := Vector2(26, 20) * u
	_place.draw_rect(Rect2(c - plate * 0.5 - Vector2(u, u) * 2.0, plate + Vector2(u, u) * 4.0), land.darkened(0.15))
	_place.draw_rect(Rect2(c - plate * 0.5, plate), land)
	match kd:
		"city":
			# blocks of houses along a grid of streets, windows lit
			for gy in range(-4, 5):
				for gx in range(-6, 7):
					if absi(gx) + absi(gy) > 9:
						continue
					var bp := c + Vector2(gx, gy) * u * 5.0
					var bs := Vector2(rng.randf_range(2.5, 4.2), rng.randf_range(2.5, 4.2)) * u
					var rc := Color(0.35, 0.37, 0.42).lerp(Color(0.55, 0.5, 0.45), rng.randf())
					_place.draw_rect(Rect2(bp - bs * 0.5 + Vector2(u * 0.4, u * 0.4), bs), Color(0, 0, 0, 0.35))
					_place.draw_rect(Rect2(bp - bs * 0.5, bs), rc)
					_place.draw_rect(Rect2(bp - bs * 0.5, Vector2(bs.x, u * 0.3)), rc.lightened(0.2))
					for w in 3:
						if rng.randf() < 0.6:
							_place.draw_rect(Rect2(bp + Vector2(rng.randf_range(-0.4, 0.3), rng.randf_range(-0.4, 0.3)) * bs, Vector2(u * 0.35, u * 0.35)), Color(1.0, 0.85, 0.45))
			for s in range(-6, 7):
				_place.draw_rect(Rect2(c + Vector2(s * u * 5.0 + u * 2.5 - u * 0.4, -u * 25.0), Vector2(u * 0.8, u * 50.0)), Color(0.22, 0.22, 0.24, 0.55))
			_landing_pad(c + Vector2(0, u * 2.0), u)
		"outpost", "research":
			for i in 5:
				var dp := c + Vector2(rng.randf_range(-12, 12), rng.randf_range(-8, 8)) * u
				var dr := rng.randf_range(2.0, 3.5) * u
				_place.draw_circle(dp + Vector2(u * 0.5, u * 0.5), dr, Color(0, 0, 0, 0.3))
				_place.draw_circle(dp, dr, Color(0.8, 0.82, 0.86))
				_place.draw_circle(dp - Vector2(dr, dr) * 0.3, dr * 0.4, Color(1, 1, 1, 0.5))
			if kd == "research":
				_place.draw_line(c + Vector2(8, -4) * u, c + Vector2(8, -10) * u, Color(0.7, 0.7, 0.75), u * 0.4)
				_place.draw_circle(c + Vector2(8, -10) * u, u * 0.7, Color(0.4, 1.0, 0.6))
			_landing_pad(c + Vector2(0, u * 3.0), u)
		"mine":
			for r in 4:
				_place.draw_arc(c + Vector2(-8, -2) * u, (6.0 - r * 1.3) * u, 0.0, TAU, 32, Color(0.35, 0.28, 0.2).darkened(r * 0.12), u * 1.2)
			_place.draw_line(c + Vector2(-8, -2) * u, c + Vector2(10, 4) * u, Color(0.5, 0.45, 0.35), u * 0.8)
			_landing_pad(c + Vector2(4, 6) * u, u)
		"ruins":
			for i in 14:
				var rp := c + Vector2(rng.randf_range(-14, 14), rng.randf_range(-10, 10)) * u
				_place.draw_rect(Rect2(rp, Vector2(rng.randf_range(2, 7), rng.randf_range(0.8, 1.6)) * u), Color(0.55, 0.5, 0.48))
			_landing_pad(c + Vector2(0, u * 8.0), u)
		"crash":
			_place.draw_circle(c, u * 9.0, Color(0.1, 0.08, 0.06, 0.5))
			_place.draw_line(c + Vector2(-16, -10) * u, c, Color(0.12, 0.1, 0.08, 0.6), u * 4.0)
			_place.draw_rect(Rect2(c - Vector2(5, 2) * u, Vector2(10, 4) * u), Color(0.45, 0.47, 0.5))
			_place.draw_circle(c + Vector2(3, 0) * u, u * 1.4, Color(1.0, 0.5, 0.2, 0.6 + 0.3 * sin(_t * 9.0)))
			_landing_pad(c + Vector2(0, u * 10.0), u)
		_:
			_landing_pad(c, u)


## 0.7.50.7: a city's ground plan, seen from the air – its form follows the world it stands on, its streets the power
## that built it. Laid out once (offsets in blocks from its middle), only on land (piers and floating platforms only on
## the sea):
##   radial (terran) · harbour (ocean: along the coast, piers and platforms out on the water) · clearings (jungle,
##   lava: quarters in clearings, roads between) · walled (desert: a dense square behind its wall, an oasis) ·
##   domes (ice, toxic: quarters under domes, tubes between) · crater (barren, rocky moons: on the crater's rim and
##   in its middle) · grid (metal worlds).
## Streets: independent – a few crooked avenues; Assembly – ring roads and parks; Covenant – spokes to a great
## cathedral square; Directorate – a strict grid.
const CITY_FORMS := {"terran": "radial", "ocean": "harbour", "jungle": "clearings", "lava": "clearings", "desert": "walled",
	"ice": "domes", "toxic": "domes", "metal": "grid", "barren": "crater", "dwarf": "crater", "moon_rock": "crater",
	"moon_ice": "domes", "moon_volcanic": "clearings", "moon_captured": "crater"}
enum CP { BLD, ROAD, PARK, MARK, PIER, RIM }
var city_form := "radial"
var city_style_key := "independent"
var _city_pts: Array = []             # [offset (blocks), size, kind CP, warm 0..1]


func _tex_sea(off: Vector2) -> bool:
	if _sea.is_empty():
		return false
	var p := _place_at + off * 4.0
	return _sea[posmod(int(floor(p.y)), _S) * _S + posmod(int(floor(p.x)), _S)] == 1


func _near_sea(off: Vector2, r: float) -> bool:
	for k in 8:
		if _tex_sea(off + Vector2.from_angle(k * TAU / 8.0) * r):
			return true
	return false


func _cp(off: Vector2, size: float, kind: int, rng: RandomNumberGenerator) -> void:
	var sea := _tex_sea(off)
	if kind == CP.PIER:
		if not sea:
			return
	elif sea:
		return
	_city_pts.append([off, size, kind, rng.randf()])


func _build_city() -> void:
	_city_pts.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(site.get("id", ""))) + 3
	city_form = String(CITY_FORMS.get(String(body.get("type", "")), "radial"))
	var st: Dictionary = city_style if not city_style.is_empty() else CityStyle.STYLES["independent"]
	var sk := city_style_key
	var grid := sk == "directorate" or city_form == "grid"
	# the quarters: where the buildings stand
	var centres: Array = [Vector2.ZERO]
	match city_form:
		"clearings":
			centres = []
			for i in rng.randi_range(4, 5):
				centres.append(Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(4.0, 17.0) if i > 0 else Vector2.ZERO)
		"domes":
			centres = [Vector2.ZERO]
			for i2 in rng.randi_range(2, 3):
				centres.append(Vector2.from_angle(i2 * TAU / 3.0 + rng.randf() * 0.6) * rng.randf_range(11.0, 15.0))
	var n := 900
	for i3 in n:
		var off := Vector2.ZERO
		match city_form:
			"harbour":
				off = Vector2.from_angle(rng.randf() * TAU) * absf(rng.randfn(0.0, 0.45)) * 28.0
				if not _near_sea(off, 4.0) and rng.randf() < 0.55:
					continue                                       # it crowds along the coast
			"clearings":
				off = centres[i3 % centres.size()] + Vector2.from_angle(rng.randf() * TAU) * absf(rng.randfn(0.0, 0.5)) * 6.0
			"walled":
				off = Vector2(rng.randf_range(-13.0, 13.0), rng.randf_range(-11.0, 11.0))
			"domes":
				var dc: Vector2 = centres[i3 % centres.size()]
				off = dc + Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * (7.0 if dc == Vector2.ZERO else 5.0)
			"crater":
				if rng.randf() < 0.7:
					off = Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(12.0, 16.5)
				else:
					off = Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * 4.5
			_:
				off = Vector2.from_angle(rng.randf() * TAU) * absf(rng.randfn(0.0, 0.38)) * 26.0
		if grid:
			off = off.snapped(Vector2(1.0, 1.0))
			if int(off.x) % 5 == 0 or int(off.y) % 5 == 0:
				continue                                           # the streets between the blocks
		var sz := 0.24 if off.length() < 5.0 else 0.16
		if sk == "covenant" and off.length() < 3.5:
			continue                                               # the cathedral square
		if sk == "assembly" and rng.randf() < 0.12:
			_cp(off, 0.9, CP.PARK, rng)                              # parks and gardens between the houses
			continue
		_cp(off, sz, CP.BLD, rng)
	# the streets
	var reach := 24.0 if city_form != "clearings" else 20.0
	if city_form == "walled":
		reach = 13.0                                               # inside its wall
	match sk:
		"directorate":
			for gl in range(-25, 26, 5):
				for t in range(-25, 26):
					var a := Vector2(gl, t)
					var b := Vector2(t, gl)
					if a.length() < reach:
						_cp(a, 0.18, CP.ROAD, rng)
					if b.length() < reach:
						_cp(b, 0.18, CP.ROAD, rng)
		"assembly":
			for ring in [8.0, 16.0]:
				for k in int(ring * 4.0):
					_cp(Vector2.from_angle(k * TAU / (ring * 4.0)) * ring, 0.18, CP.ROAD, rng)
			for sp in 4:
				var dir := Vector2.from_angle(sp * PI * 0.5 + 0.4)
				for t2 in 50:
					_cp(dir * t2 * 0.5, 0.18, CP.ROAD, rng)
			for pk in 5:                                           # bigger parks
				var pc := Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(4.0, 18.0)
				for q in 14:
					_cp(pc + Vector2(rng.randf_range(-2.0, 2.0), rng.randf_range(-2.0, 2.0)), 1.0, CP.PARK, rng)
		"covenant":
			for sp2 in 8:
				var dir2 := Vector2.from_angle(sp2 * TAU / 8.0)
				for t3 in range(8, 52):
					_cp(dir2 * t3 * 0.5, 0.18, CP.ROAD, rng)
			for k2 in 28:                                          # the square's ring of lamps
				_cp(Vector2.from_angle(k2 * TAU / 28.0) * 3.6, 0.2, CP.ROAD, rng)
			_cp(Vector2.ZERO, 1.4, CP.MARK, rng)                     # the cathedral
		_:
			for av in 6:
				var dir3 := Vector2.from_angle(rng.randf() * PI)
				var bend := rng.randf_range(-0.012, 0.012)
				for t4 in 64:
					var tt := (t4 - 32) * 0.75
					var off2 := dir3.rotated(bend * tt) * tt
					if off2.length() < reach:
						_cp(off2, 0.18, CP.ROAD, rng)
	# what the world adds
	match city_form:
		"harbour":
			# piers out into the sea, platforms floating on it
			var piers := 0
			for tries in 200:
				var po := Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(4.0, 22.0)
				if _tex_sea(po) or not _near_sea(po, 2.5) or piers >= 9:
					continue
				var to_sea := Vector2.ZERO
				for k3 in 16:
					var d := Vector2.from_angle(k3 * TAU / 16.0)
					if _tex_sea(po + d * 2.5):
						to_sea = d
						break
				for t5 in range(2, 16):
					_cp(po + to_sea * t5 * 0.5, 0.2, CP.PIER, rng)
				piers += 1
			for pf in 3:
				var fc := Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(18.0, 30.0)
				for q2 in 40:
					_cp(fc + Vector2(rng.randf_range(-2.0, 2.0), rng.randf_range(-2.0, 2.0)), 0.18, CP.PIER, rng)
		"walled":
			for e in 104:
				var t6 := e / 104.0 * 4.0
				var wp: Vector2
				if t6 < 1.0:
					wp = Vector2(lerpf(-14.0, 14.0, t6), -12.0)
				elif t6 < 2.0:
					wp = Vector2(14.0, lerpf(-12.0, 12.0, t6 - 1.0))
				elif t6 < 3.0:
					wp = Vector2(lerpf(14.0, -14.0, t6 - 2.0), 12.0)
				else:
					wp = Vector2(-14.0, lerpf(12.0, -12.0, t6 - 3.0))
				_cp(wp, 0.3, CP.RIM, rng)
			for q3 in 30:                                          # the oasis
				_cp(Vector2(rng.randf_range(-2.5, 2.5), rng.randf_range(-2.0, 2.0)) + Vector2(5, 3), 1.0, CP.PARK, rng)
		"domes":
			for dc2 in centres:
				var rr := 7.5 if dc2 == Vector2.ZERO else 5.5
				for k4 in 48:
					_cp(dc2 + Vector2.from_angle(k4 * TAU / 48.0) * rr, 0.22, CP.RIM, rng)
			for i4 in range(1, centres.size()):
				var dd: Vector2 = centres[i4]
				for t7 in 20:
					_cp(dd * (t7 / 20.0), 0.2, CP.ROAD, rng)
		"clearings":
			for i5 in range(1, centres.size()):
				var cc: Vector2 = centres[i5]
				var prev: Vector2 = centres[i5 - 1]
				for t8 in 24:
					_cp(prev.lerp(cc, t8 / 24.0), 0.18, CP.ROAD, rng)
		"crater":
			for k5 in 96:
				_cp(Vector2.from_angle(k5 * TAU / 96.0) * 10.5, 0.3, CP.RIM, rng)


## A city from above: its ground plan (see _build_city) – by night its lights, by day its roofs, parks and streets –
## fading up as you come near; the ship sinks into it.
func _draw_city_lights(c: Vector2, u: float, rng: RandomNumberGenerator) -> void:
	var k := clampf(_t / DURATION, 0.0, 1.0)
	var a := smoothstep(0.05, 0.4, k)
	if a <= 0.0:
		return
	if _city_pts.is_empty():
		_build_city()
	var st: Dictionary = city_style if not city_style.is_empty() else CityStyle.STYLES["independent"]
	var day := city_day > 0.5
	var wins: Array = st["win"]
	var roof := CityStyle.tone(st, "roof", 1.0)
	var acc: Color = st["accent"]
	# a crater's floor and rim, by day and night
	if city_form == "crater":
		_place.draw_arc(c, u * 10.5, 0.0, TAU, 64, Color(0, 0, 0, 0.25 * a), u * 2.0)
		_place.draw_circle(c, u * 9.5, Color(0, 0, 0, 0.12 * a))
	for i in _city_pts.size():
		var pt: Array = _city_pts[i]
		var p: Vector2 = c + (pt[0] as Vector2) * u
		var sz: float = float(pt[1]) * u
		var kind: int = pt[2]
		var w: float = pt[3]
		if day:
			match kind:
				CP.BLD:
					var bs := sz * 3.2
					var rc := roof.lightened(w * 0.15).darkened((1.0 - w) * 0.18)
					_place.draw_rect(Rect2(p + Vector2(bs * 0.4, bs * 0.4), Vector2(bs, bs)), Color(0, 0, 0, 0.3 * a))
					_place.draw_rect(Rect2(p, Vector2(bs, bs)), Color(rc, 0.95 * a))
				CP.ROAD, CP.PIER:
					_place.draw_rect(Rect2(p, Vector2(sz * 2.5, sz * 2.5)), Color(0.33, 0.33, 0.35, 0.85 * a) if kind == CP.ROAD else Color(0.55, 0.5, 0.42, 0.9 * a))
				CP.PARK:
					_place.draw_rect(Rect2(p, Vector2(sz, sz)), Color(0.3, 0.55, 0.28, 0.85 * a))
				CP.MARK:
					_place.draw_circle(p, sz, Color(roof.darkened(0.2), a))
					_place.draw_circle(p - Vector2(sz, sz) * 0.25, sz * 0.5, Color(roof.lightened(0.2), a))
					_place.draw_circle(p, sz * 0.25, Color(1.0, 0.8, 0.3, a))
				CP.RIM:
					_place.draw_rect(Rect2(p, Vector2(sz * 2.0, sz * 2.0)), Color(roof.lightened(0.25), 0.9 * a))
			continue
		# by night
		match kind:
			CP.BLD:
				if fposmod(_t * (0.3 + w * 1.2) + i * 0.37, 1.0) < 0.05:
					continue                                           # a light goes out for a blink
				var col: Color = wins[0] if w < float(st["warm"]) else wins[1]
				_place.draw_rect(Rect2(p, Vector2(sz, sz)), Color(col, 0.9 * a))
			CP.ROAD:
				_place.draw_rect(Rect2(p, Vector2(sz, sz)), Color(Color(1.0, 0.85, 0.55) if st.get("grid", false) == false else Color(0.85, 1.0, 0.95), 0.85 * a))
			CP.PIER:
				_place.draw_rect(Rect2(p, Vector2(sz, sz)), Color(1.0, 0.95, 0.8, 0.9 * a))
			CP.MARK:
				_place.draw_circle(p, sz * 1.4, Color(1.0, 0.75, 0.35, 0.1 * a))
				_place.draw_circle(p, sz * 0.5, Color(1.0, 0.8, 0.4, 0.25 * a))
				_place.draw_rect(Rect2(p - Vector2(u, u) * 0.15, Vector2(u, u) * 0.3), Color(1.0, 0.95, 0.75, a))
			CP.RIM:
				_place.draw_rect(Rect2(p, Vector2(sz, sz)), Color(acc, 0.8 * a))
			_:
				pass


## The flight's distance along the ground picture after t seconds (the ground comes closer and slows).
func _dist(t: float) -> float:
	var steps := 90
	var dt := minf(t, DURATION) / steps
	var d := 0.0
	for i in steps:
		var k := (i + 0.5) * dt / DURATION
		d += lerpf(520.0, 140.0, k) * dt / lerpf(1.6, 4.2, smoothstep(0.0, 1.0, k))
	return d


## A spot on the ground picture → the screen, and back.
func _to_screen(p: Vector2) -> Vector2:
	return _vs * 0.5 + (p - _scroll) * _ground.scale.x


func _is_sea(screen_p: Vector2) -> bool:
	if _sea.is_empty():
		return false
	var p := _scroll + (screen_p - _vs * 0.5) / _ground.scale.x
	var x := posmod(int(floor(p.x)), _S)
	var y := posmod(int(floor(p.y)), _S)
	return _sea[y * _S + x] == 1


## The nearest spot on land (with land round it) to a spot on the ground picture.
func _nearest_land(p: Vector2) -> Vector2:
	if _sea.is_empty():
		return p
	for r in range(0, 200, 4):
		for k in 24:
			var q := p + Vector2.from_angle(k * TAU / 24.0) * r
			var ok := true
			for dd in [Vector2.ZERO, Vector2(14, 0), Vector2(-14, 0), Vector2(0, 14), Vector2(0, -14), Vector2(24, 0), Vector2(-24, 0)]:
				var x := posmod(int(q.x + dd.x), _S)
				var y := posmod(int(q.y + dd.y), _S)
				if _sea[y * _S + x] == 1:
					ok = false
					break
			if ok:
				return q
			if r == 0:
				break
	return p


## The landing drone every ship carries (0.7.50.4; 0.7.50.15: a dropship for four and a vehicle – LanderArt).
static func lander_texture() -> Texture2D:
	return LanderArt.texture()


func _landing_pad(p: Vector2, u: float) -> void:
	var s := Vector2(7, 5) * u
	_place.draw_rect(Rect2(p - s * 0.5, s), Color(0.52, 0.53, 0.55))
	_place.draw_rect(Rect2(p - s * 0.5, s), Color(0.95, 0.8, 0.2), false, maxf(1.0, u * 0.3))
	if fposmod(_t * 2.0, 1.0) < 0.5:
		for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			_place.draw_circle(p + s * 0.5 * corner, u * 0.4, Color(1.0, 0.8, 0.3))


## A tiling picture of a world's ground, in its own colours: sea and land, dunes, ice, lava, craters.
static func ground_texture(b: Dictionary) -> Texture2D:
	return ground_data(b)["tex"]


static var _ground_cache := {}


## 0.7.50.6: the ground picture with its sea mask ({tex, img, sea: PackedByteArray, 1 = sea}), kept per body.
static func ground_data(b: Dictionary) -> Dictionary:
	var key := String(b.get("id", "")) + String(b.get("type", ""))
	if _ground_cache.has(key):
		return _ground_cache[key]
	var bt := Universe.body_type(String(b.get("type", "")))
	var a: Color = bt.get("a", Color(0.3, 0.3, 0.35))
	var c1: Color = bt.get("b", Color(0.45, 0.42, 0.38))
	var c2: Color = bt.get("c", Color(0.6, 0.56, 0.48))
	var n := FastNoiseLite.new()
	n.seed = int(hash(String(b.get("id", "")))) & 0x7fffffff
	n.frequency = 0.0055                         # big continents, not a camouflage pattern
	n.fractal_octaves = 5
	var n2 := FastNoiseLite.new()
	n2.seed = n.seed + 7
	n2.frequency = 0.03
	var S := 384
	var img_a := n.get_seamless_image(S, S)
	var img_b := n2.get_seamless_image(S, S)
	var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
	var mask := PackedByteArray()
	mask.resize(S * S)
	mask.fill(0)
	var sea := float(bt.get("sea", 0.0))
	var lava := float(bt.get("lava", 0.0))
	var craters := float(bt.get("craters", 0.0))
	var caps := float(bt.get("caps", 0.0))
	for y in S:
		for x in S:
			var v := img_a.get_pixel(x, y).r
			var d := img_b.get_pixel(x, y).r
			var col: Color
			if sea > 0.0 and v < sea * 0.9:
				mask[y * S + x] = 1
				col = a.lerp(a.darkened(0.3), clampf((sea * 0.9 - v) * 3.0, 0.0, 1.0))
				if v > sea * 0.9 - 0.03:
					col = col.lerp(Color(0.85, 0.9, 0.95), 0.4)             # surf along the coast
			else:
				col = c1.lerp(c2, clampf((v - 0.3) * 1.6 + (d - 0.5) * 0.4, 0.0, 1.0))
				col = col.darkened(0.12 * d)
			if lava > 0.0 and absf(v - 0.5) < 0.02 + 0.02 * d:
				col = Color(1.0, 0.45, 0.1).lerp(Color(1.0, 0.85, 0.3), d)   # glowing cracks
			if caps > 0.6 and absf(d - 0.5) < 0.012:
				col = col.lightened(0.35)                                        # ice cracks / frost lines
			img.set_pixel(x, y, col)
	if craters > 0.0:
		var rng := RandomNumberGenerator.new()
		rng.seed = n.seed
		for k in int(10 * craters) + 4:
			var cx := rng.randi_range(0, S - 1)
			var cy := rng.randi_range(0, S - 1)
			var r := rng.randf_range(5.0, 22.0)
			for yy in range(-int(r) - 1, int(r) + 2):
				for xx in range(-int(r) - 1, int(r) + 2):
					var dd := sqrt(float(xx * xx + yy * yy))
					if dd <= r:
						var px := (cx + xx + S) % S
						var py := (cy + yy + S) % S
						var o := img.get_pixel(px, py)
						var rim := dd > r * 0.8
						img.set_pixel(px, py, o.lightened(0.15) if rim and yy < 0 else (o.darkened(0.12) if not rim else o.darkened(0.05)))
	var out := {"tex": ImageTexture.create_from_image(img), "img": img, "sea": mask}
	_ground_cache[key] = out
	return out


## Clouds that tile: soft white (or the world's own cloud colour) where the noise is high, see-through elsewhere.
static func cloud_texture(seed_v: int, col: Color) -> Texture2D:
	var n := FastNoiseLite.new()
	n.seed = seed_v & 0x7fffffff
	n.frequency = 0.02
	n.fractal_octaves = 3
	var S := 256
	var src := n.get_seamless_image(S, S)
	var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
	for y in S:
		for x in S:
			var v := src.get_pixel(x, y).r
			var a := clampf((v - 0.55) * 4.0, 0.0, 1.0)
			img.set_pixel(x, y, Color(col.r, col.g, col.b, a * 0.85))
	return ImageTexture.create_from_image(img)
