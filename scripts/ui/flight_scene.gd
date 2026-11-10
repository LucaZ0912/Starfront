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
var _dest_y := 0.0                    # where the place lies ahead, in screen px above the ship (shrinks as you fly)


func open(p_body: Dictionary, p_site: Dictionary) -> void:
	layer = 13
	body = p_body
	site = p_site
	atmo = Universe.has_atmosphere(body)
	_vs = get_viewport().get_visible_rect().size if get_viewport() != null else Vector2(1600, 900)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var bt := Universe.body_type(String(body.get("type", "")))
	# the ground: a tiling picture of this world, scrolled and slowly growing (you come closer)
	_ground = Sprite2D.new()
	_ground.texture = ground_texture(body)
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
	var ss := clampf(150.0 / maxf(tex.get_width(), 1.0), 2.0, 5.0)
	_ship.scale = Vector2.ONE * ss
	_shadow.scale = Vector2.ONE * ss
	_ship.position = _vs * Vector2(0.5, 0.58)
	add_child(_ship)
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
	_dest_y = _vs.y * 1.6
	Audio.play("boost", "flight down")
	_update(0.0)


func _process(delta: float) -> void:
	if _done:
		return
	_t += delta
	_update(delta)
	if _t >= DURATION:
		_done = true
		finished.emit()


func _update(delta: float) -> void:
	var k := clampf(_t / DURATION, 0.0, 1.0)
	var gscale := lerpf(1.6, 4.2, smoothstep(0.0, 1.0, k))           # the ground comes closer
	var speed := lerpf(520.0, 140.0, k)                                 # screen px per second
	_scroll.y -= speed * delta / gscale
	_ground.scale = Vector2.ONE * gscale
	_ground.region_rect = Rect2(_scroll - _vs / gscale * 0.5, _vs / gscale)
	_dest_y = maxf(0.0, _dest_y - speed * delta)
	if _t > DURATION * 0.55:
		_dest_y = lerpf(_dest_y, 0.0, delta * 1.6)
	# the shadow closes in on the ship as she comes down
	var alt := 1.0 - k
	_shadow.position = _ship.position + Vector2(40.0 + 160.0 * alt, 60.0 + 200.0 * alt)
	_shadow.modulate.a = lerpf(0.18, 0.55, k)
	_ship.position = _vs * Vector2(0.5, 0.58) + Vector2(sin(_t * 1.3) * 6.0, sin(_t * 2.1) * 3.0)
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


func _draw_fx() -> void:
	var p := _ship.position
	# the last of the entry heat, at the start
	var heat := clampf(1.0 - _t / 1.6, 0.0, 1.0) if atmo else 0.0
	if heat > 0.0:
		for i in 4:
			_fx.draw_circle(p + Vector2(0, -20), 90.0 - i * 18.0, Color(1.0, 0.6 - i * 0.08, 0.25, heat * (0.12 + i * 0.06)))
	# the flame, below her (she flies up)
	for j in 3:
		var len := (60.0 - j * 14.0) * (0.85 + 0.15 * sin(_t * 30.0 + j))
		_fx.draw_colored_polygon(PackedVector2Array([p + Vector2(-14 + j * 4, 55), p + Vector2(0, 55 + len), p + Vector2(14 - j * 4, 55)]),
			Color([Color(1.0, 0.5, 0.15), Color(1.0, 0.8, 0.3), Color(1, 1, 0.85)][j], 0.55))


## The place ahead: it comes into view at the top and slides down to meet the ship.
func _draw_place() -> void:
	var gscale := _ground.scale.x
	var c := _ship.position + Vector2(0, -_dest_y - 40.0)
	if c.y < -400.0:
		return
	var kd := String(site.get("kind", "outpost"))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(site.get("id", "")))
	var u := gscale * 4.0                       # one "block" in screen px
	# the place stands on its own ground (no city on the open sea)
	var bt := Universe.body_type(String(body.get("type", "")))
	var land: Color = Color(bt.get("b", Color(0.45, 0.42, 0.38))).lerp(Color(bt.get("c", Color(0.6, 0.56, 0.48))), 0.4)
	var plate := Vector2(36, 26) * u if kd == "city" else Vector2(26, 20) * u
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


func _landing_pad(p: Vector2, u: float) -> void:
	var s := Vector2(7, 5) * u
	_place.draw_rect(Rect2(p - s * 0.5, s), Color(0.52, 0.53, 0.55))
	_place.draw_rect(Rect2(p - s * 0.5, s), Color(0.95, 0.8, 0.2), false, maxf(1.0, u * 0.3))
	if fposmod(_t * 2.0, 1.0) < 0.5:
		for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			_place.draw_circle(p + s * 0.5 * corner, u * 0.4, Color(1.0, 0.8, 0.3))


## A tiling picture of a world's ground, in its own colours: sea and land, dunes, ice, lava, craters.
static func ground_texture(b: Dictionary) -> Texture2D:
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
	return ImageTexture.create_from_image(img)


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
