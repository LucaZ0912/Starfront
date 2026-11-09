class_name Celestial
extends Node2D
## Objects in a system: station, hyperspace gate, asteroid, anomaly, wreck.
## Star and planets are rendered by the SystemView as celestial bodies (see make_*_sprite).
## `data` references the dictionary from the Universe layout directly (changes persist).

const PlanetShader = preload("res://shaders/planet.gdshader")
const StarShader = preload("res://shaders/star.gdshader")
const NeutronShader = preload("res://shaders/neutron.gdshader")          # package 37
const BlackHoleShader = preload("res://shaders/blackhole.gdshader")
const LensShader = preload("res://shaders/lens.gdshader")
const ColossusShader = preload("res://shaders/colossus.gdshader")
const FactionData = preload("res://data/factions.gd")
const COLOSSUS_BODY := 0.8      # outer radius of the rock relative to the shader quad

static var label_scale := 1.0
static var show_labels := true

var kind := ""
var data: Dictionary = {}
var radius := 30.0
var light_dir := Vector2(-0.7, -0.5)
var _t := 0.0
var _tex: Texture2D
var view = null            # SystemView (set by _add_celestial)
var _col_sprite: Sprite2D
var poly: PackedVector2Array   # colossus outline (local km), see ColossusShape
var radar_hidden := false      # colossus completely inside another one's radar shadow (Recon view)
var art: Dictionary = {}          # station / haven: StationArt.build() result
var turret_aim: Array = []        # current barrel angle per turret (station defence)
var turret_flash: Array = []      # muzzle flash timer per turret
var pad_ship := {}                # package 26: pad index -> the ship landing on / lifting off it
var pad_open := {}                # pad index -> hatch 0 (shut) … 1 (open)
var pad_want := {}                # pad index -> where its hatch is heading (0 shut, 1 open)
var _pad_check := 0.5


func setup(p_kind: String, p_data: Dictionary, p_light_dir: Vector2 = Vector2(-0.7, -0.5)) -> void:
	kind = p_kind
	data = p_data
	light_dir = p_light_dir
	position = data.get("pos", Vector2.ZERO)
	match kind:
		"planet":
			radius = float(data["radius"])
			add_child(make_planet_sprite(data, radius, light_dir))
			z_index = -5
		"star_far":
			radius = float(data["radius"])
			add_child(make_star_sprite(data["color"], radius))
			z_index = -6
		"station", "haven", "structure":
			# modular pixel-art station (StationArt): texture + docking bays, lights, vents, turrets
			# (package 39: "structure" = a landmark that is no station – relays, a capital ship in her berth)
			art = StationArt.build(data)
			_tex = art["texture"]
			radius = float(art["radius"])
			for i in art["turrets"].size():
				turret_aim.append(randf() * TAU)
				turret_flash.append(0.0)
		"gate":
			_tex = PixelArt.gate_texture_styled(int(data["class"]), String(data.get("style", "")))      # package 40b
			radius = _tex.get_width() * 4.0 * 0.45
		"asteroid":
			# texture is created lazily on first draw (SystemView only shows asteroids near the camera)
			radius = float(data["radius"])
			rotation = float(data.get("seed", 0) % 628) / 100.0
		"colossus":
			# foreground rock rendered by a shader, lit from the star's direction
			radius = float(data["radius"])
			poly = colossus_poly(data)
			z_index = 15
			_col_sprite = make_colossus_sprite(data)
			add_child(_col_sprite)
		"anomaly":
			radius = 90.0 if not data.get("veil", false) else 420.0
		"wreck":
			_tex = PixelArt.wreck_texture(int(data.get("seed", 3)))
			radius = 40.0
			if data.has("hulk"):                         # package 40c: a warship's hulk of an old battle
				_tex = PixelArt.hulk_texture(String(data["hulk"]), int(data["seed"]))
				radius = maxf(_tex.get_width(), _tex.get_height()) * PixelArt.SCALE * 0.42
				rotation = float(data.get("rot", 0.0))
			elif data.get("relic", false):               # a pre-Severance derelict
				_tex = PixelArt.relic_texture(int(data["seed"]))
				radius = _tex.get_width() * PixelArt.SCALE * 2.0 * 0.4
				rotation = float(data.get("rot", 0.0))
		"site":
			radius = float(data.get("radius", 8000.0))
			z_index = -2
		"hazard":
			radius = float(data.get("radius", 30000.0))
			z_index = -3
		"pod":
			radius = 30.0                        # package 31a: an escape pod
		"beacon":
			radius = 45.0
	if kind in ["planet", "star_far", "colossus"]:
		pass
	elif z_index == 0:
		z_index = -1 if kind in ["station", "haven", "gate", "asteroid", "structure"] else 0


## Outline of a colossus (from the layout; generated from its seed if missing).
static func colossus_poly(d: Dictionary) -> PackedVector2Array:
	if d.has("poly"):
		return d["poly"]
	var rng := RandomNumberGenerator.new()
	rng.seed = int(d.get("seed", 1))
	d["poly"] = ColossusShape.generate(String(d.get("shape", "potato")), float(d["radius"]), rng)
	return d["poly"]


## Colossal asteroid as a shader sprite (see shaders/colossus.gdshader).
static func make_colossus_sprite(d: Dictionary) -> Sprite2D:
	var spr := Sprite2D.new()
	spr.texture = PixelArt.white()
	var R := float(d["radius"])
	var quad := R * 2.0 / COLOSSUS_BODY
	spr.scale = Vector2.ONE * quad / 64.0
	var pal: Array = PixelArt.ore_palette(String(d["ore"]))
	var mat := ShaderMaterial.new()
	mat.shader = ColossusShader
	mat.set_shader_parameter("col_dark", pal[0])
	mat.set_shader_parameter("col_mid", pal[1].lerp(pal[2], 0.5))
	mat.set_shader_parameter("col_light", pal[3])
	mat.set_shader_parameter("col_accent", pal[4])
	mat.set_shader_parameter("kind", {"metallic": 0, "stony": 1, "icy": 2}.get(String(d["class"]), 1))
	mat.set_shader_parameter("shape", int(ColossusShape.SHADER_SHAPE.get(String(d.get("shape", "potato")), 0)))
	mat.set_shader_parameter("seed", float(posmod(int(d["seed"]), 997)) * 0.37)
	var to_star := -(d["pos"] as Vector2)
	mat.set_shader_parameter("light_dir", to_star.normalized() if to_star.length() > 1.0 else Vector2(-0.7, -0.6))
	# outline in quad space (-1..1); the shader holds up to 64 points
	var src := colossus_poly(d)
	var pts := PackedVector2Array()
	var k := 1.0 / (R / COLOSSUS_BODY)
	for i in mini(src.size(), 64):
		pts.append(src[i] * k)
	mat.set_shader_parameter("poly_n", pts.size())
	# deepest point inside the outline (sets the height of the dome)
	var deep := 0.05
	for gy in 21:
		for gx in 21:
			var q := Vector2(gx - 10, gy - 10) / 10.0 * COLOSSUS_BODY
			if Geometry2D.is_point_in_polygon(q, pts):
				deep = maxf(deep, -ColossusShape.signed_dist(pts, q))
	mat.set_shader_parameter("depth_max", deep)
	while pts.size() < 64:
		pts.append(Vector2.ZERO)
	mat.set_shader_parameter("poly", pts)
	spr.material = mat
	return spr


## Pixel planet as a shader sprite (also used by the system map).
static func make_planet_sprite(p: Dictionary, r: float, ldir: Vector2) -> Sprite2D:
	var t: Dictionary = Universe.body_type(String(p["type"]))      # package 36: planets and moons
	var spr := Sprite2D.new()
	spr.texture = PixelArt.white()
	var ring: bool = p.get("ring", false)
	var quad := r * (2.0 / 0.5 if ring else 2.0 / 0.86)
	spr.scale = Vector2.ONE * quad / 64.0
	var mat := ShaderMaterial.new()
	mat.shader = PlanetShader
	# package 38: every planet its own shade of its type (hue, saturation, brightness), sea, clouds and rings
	var rng := RandomNumberGenerator.new()
	rng.seed = int(float(p.get("seed", 1.0)) * 1000.0) + 38
	var dh := rng.randf_range(-0.035, 0.035)
	var dsat := rng.randf_range(0.85, 1.15)
	var dval := rng.randf_range(0.9, 1.1)
	for k in [["col_a", "a"], ["col_b", "b"], ["col_c", "c"]]:
		var c0: Color = t[k[1]]
		if p.get("deep", false):
			c0 = Color.from_hsv(0.62, minf(1.0, c0.s * 1.6 + 0.25), c0.v * 0.62)       # package 39: Boulé, deep blue
		if p.has("hue"):
			c0 = Color.from_hsv(float(p["hue"]), minf(1.0, c0.s * 1.5 + 0.2), c0.v * 0.85)   # 39b: the red giant Compline
		mat.set_shader_parameter(k[0], Color.from_hsv(fposmod(c0.h + dh, 1.0), clampf(c0.s * dsat, 0.0, 1.0), clampf(c0.v * dval, 0.0, 1.0)))
	mat.set_shader_parameter("atmo", t["atmo"])
	mat.set_shader_parameter("gas", t["gas"])
	mat.set_shader_parameter("seed", float(p.get("seed", 1.0)))
	mat.set_shader_parameter("light_dir", ldir)
	mat.set_shader_parameter("has_ring", 1.0 if ring else 0.0)
	mat.set_shader_parameter("radius", 0.5 if ring else 0.86)
	mat.set_shader_parameter("pixels", clampf(quad / 7.0, 48.0, 220.0))
	mat.set_shader_parameter("spin", 0.004 if r > 300.0 else 0.015)
	mat.set_shader_parameter("craters", float(t.get("craters", 0.0)))   # package 36: moons
	mat.set_shader_parameter("lumpy", float(t.get("lumpy", 0.0)))
	mat.set_shader_parameter("glow", float(t.get("glow", 0.0)))
	var sea := float(t.get("sea", 0.0))
	mat.set_shader_parameter("sea", clampf(sea + (rng.randf_range(-0.12, 0.12) if sea > 0.0 else 0.0), 0.0, 0.95))
	var cl := float(t.get("clouds", 0.0))
	mat.set_shader_parameter("clouds", clampf(cl + (rng.randf_range(-0.15, 0.15) if cl > 0.0 else 0.0), 0.0, 1.0))
	mat.set_shader_parameter("cloud_col", t.get("cloud", Color(1, 1, 1)))
	mat.set_shader_parameter("caps", float(t.get("caps", 0.0)) * rng.randf_range(0.6, 1.3))
	mat.set_shader_parameter("lava", float(t.get("lava", 0.0)))
	mat.set_shader_parameter("metal", float(t.get("metal", 0.0)))          # package 42: metal worlds
	mat.set_shader_parameter("storms", float(t.get("storms", 0.0)) * rng.randf_range(0.5, 1.2))
	mat.set_shader_parameter("faint", float(t.get("faint", 0.0)))
	mat.set_shader_parameter("city", float(p.get("city", 0.0)))
	mat.set_shader_parameter("city_style", float(p.get("city_style", 0.0)))      # package 39: Agora
	if p.get("terraform", false):
		mat.set_shader_parameter("terraform", 1.0)                                # 39c: Curie, half desert
		var dt: Dictionary = Universe.PLANET_TYPES["desert"]
		mat.set_shader_parameter("dry_a", dt["a"])
		mat.set_shader_parameter("dry_b", dt["b"])
		mat.set_shader_parameter("dry_c", dt["c"])
	mat.set_shader_parameter("ring_in", rng.randf_range(1.2, 1.5))
	mat.set_shader_parameter("ring_out", rng.randf_range(1.7, 1.95))
	mat.set_shader_parameter("ring_tilt", rng.randf_range(2.4, 4.5))
	if t.has("lumpy"):
		mat.set_shader_parameter("spin", 0.0)                          # moons turn one face to their planet
	spr.material = mat
	return spr


## Package 37: how a star is drawn – its visible extent (km; a neutron star's field lines and a black hole's disc
## reach far beyond the body) and the quad factor (quad width / visible radius).
static func star_look(star: Dictionary) -> Dictionary:
	var r := float(star.get("radius", 60000.0))
	match String(star.get("kind", "main")):
		"neutron":
			return {"vis_r": r * 15.0, "quad": 2.0 / 0.95, "kind": "neutron"}
		"blackhole":
			return {"vis_r": r * 6.0, "quad": 2.0 / 0.98, "kind": "blackhole"}
	return {"vis_r": r, "quad": 2.0 / 0.45, "kind": String(star.get("kind", "main"))}


## A star sprite of visible radius `r` (km or px). `star`: the layout's star dictionary (package 37) – or just a
## colour (an ordinary star).
static func make_star_sprite(star, r: float) -> Sprite2D:
	var sd: Dictionary = star if star is Dictionary else {"color": star, "kind": "main"}
	var look := star_look(sd)
	var spr := Sprite2D.new()
	spr.texture = PixelArt.white()
	var quad: float = r * float(look["quad"])
	spr.scale = Vector2.ONE * quad / 64.0
	var mat := ShaderMaterial.new()
	var col: Color = sd.get("color", Color(1.0, 0.85, 0.5))
	var col2: Color = sd.get("color2", col.lightened(0.6))
	match String(look["kind"]):
		"neutron":
			mat.shader = NeutronShader
			mat.set_shader_parameter("pixels", 420.0)
		"blackhole":
			mat.shader = BlackHoleShader
			mat.set_shader_parameter("pixels", 420.0)
		_:
			mat.shader = StarShader
			mat.set_shader_parameter("pixels", clampf(quad / 10.0, 60.0, 200.0))
			var tid := String(sd.get("star_id", "G"))
			var tdef: Dictionary = Universe.STAR_TYPES[Universe.star_index(tid)]
			mat.set_shader_parameter("mode", {"brown": 1, "giant": 2}.get(String(look["kind"]), 0))
			mat.set_shader_parameter("flares", 1.0 if bool(tdef.get("flares", true)) else 0.0)
			mat.set_shader_parameter("spots", 0.8 if tid in ["K", "M", "G"] else (0.3 if String(look["kind"]) == "main" else 0.0))
	mat.set_shader_parameter("color", col)
	mat.set_shader_parameter("color2", col2)
	mat.set_shader_parameter("seed", float(sd.get("seed", 1.0)))
	spr.material = mat
	return spr


## Package 37: the gravitational lens round a black hole – a child of its sprite, drawn behind it.
static func make_lens_sprite() -> Sprite2D:
	var lens := Sprite2D.new()
	lens.texture = PixelArt.white()
	lens.scale = Vector2.ONE * 1.8
	lens.show_behind_parent = true
	var mat := ShaderMaterial.new()
	mat.shader = LensShader
	mat.set_shader_parameter("horizon", 0.16 / 1.8)
	lens.material = mat
	return lens


func title() -> String:
	match kind:
		"asteroid":
			if not is_prospected():
				return "%s %s Asteroid" % [String(data.get("size", "")).capitalize(), String(data.get("class", "")).capitalize()]
			return "%s Asteroid (%s)" % [String(data.get("size", "")).capitalize(), GameData.item_name(data["ore"])]
		"colossus":
			return String(data["name"])
	return String(data.get("name", kind))


# ---------------------------------------------------------------- Prospecting (package 7)

func is_prospected() -> bool:
	return data.has("prospected")


## Scanner estimate: true value ± accuracy, stable per asteroid (seeded), never exact.
func _estimate(v: float, salt: float) -> float:
	var acc := float(data.get("prospected", 1.0))
	var h := fposmod(sin(float(int(data.get("seed", 1)) % 100000) * 0.0137 + salt * 12.9898) * 43758.5453, 1.0)
	return v * (1.0 + (h * 2.0 - 1.0) * acc)


func deposit_text() -> String:
	if float(data.get("amount", 0.0)) <= 0.0:
		return "empty"                               # 0.6.35.5: mined out (a colossus stays)
	return "~%.0f units (±%d%%)" % [_estimate(float(data["amount"]), 7.0), int(float(data.get("prospected", 1.0)) * 100.0)]


func composition_text() -> String:
	if not is_prospected():
		return "composition unknown"
	var mix: Dictionary = data.get("mix", {data["ore"]: 1.0})
	var est := {}
	var total := 0.0
	var k := 0
	for o in mix:
		k += 1
		est[o] = maxf(0.01, _estimate(float(mix[o]), float(k)))
		total += float(est[o])
	var parts: PackedStringArray = []
	for o in est:
		parts.append("%s ~%d%%" % [GameData.item_name(o), int(round(float(est[o]) / total * 100.0))])
	var extra := "  •  purity %s" % Universe.purity_grade(data)                  # package 41
	if kind == "colossus" and float(data.get("deep_amount", 0.0)) > 0.0:
		extra += "  •  deep: %s (deep core drill)" % GameData.item_name(String(data["deep_ore"]))
	return "%s  •  deposit %s%s" % [", ".join(parts), deposit_text(), extra]


# ---------------------------------------------------------------- 0.6.35.5: small asteroids break apart and return

const BREAK_TIME := 7.0
var _break_t := -1.0
var _fade_t := -1.0


## A small asteroid mined out: it breaks into pieces that drift apart and fade; it grows back in 30–60 minutes
## (smaller rocks sooner, weighted random).
func shatter() -> void:
	if data.has("gone"):
		return
	data["gone"] = true
	var frac := clampf((float(data.get("radius", 15.0)) - 10.0) / 15.0, 0.0, 1.0)
	var roll := clampf(frac * 0.5 + (randf() + randf()) * 0.25, 0.0, 1.0)
	data["respawn_at"] = GameState.play_time + lerpf(30.0, 60.0, roll) * 60.0
	_break_t = 0.0
	set_process(true)
	queue_redraw()


## The rock is back (SystemView checks the time).
func restore() -> void:
	data.erase("gone")
	data.erase("respawn_at")
	data["amount"] = float(data.get("amount0", 60.0))
	_break_t = -1.0
	_fade_t = 0.0
	modulate.a = 0.0
	set_process(true)
	queue_redraw()


## Package 31a: who is in the pod and how long the signal lasts.
func pod_text() -> String:
	for pod in GameState.pods:
		if String(pod["id"]) == String(data.get("id", "")):
			var parts: Array = []
			for e in pod["crew"]:
				parts.append("%s (%s, %d:%02d)" % [e["m"]["name"], e["m"]["quality"], int(maxf(0.0, float(e["until"]) - GameState.play_time)) / 60, int(maxf(0.0, float(e["until"]) - GameState.play_time)) % 60])
			return ", ".join(PackedStringArray(parts))
	return "empty"


func is_depleted() -> bool:
	match kind:
		"asteroid":
			return float(data["amount"]) <= 0.0 or data.has("gone")
		"colossus":
			return float(data.get("amount", 0.0)) <= 0.0
		"anomaly":
			return bool(data["done"])
		"wreck":
			return float(data.get("salvage", 0.0)) >= 100.0
	return false


func is_pickable() -> bool:
	match kind:
		"anomaly":
			return bool(data["revealed"])
		"asteroid":
			return not is_depleted()
		"colossus", "haven":
			return true
		"planet", "star_far", "structure":
			return false
	return visible


func info_text() -> String:
	match kind:
		"planet":
			return "%s\n%s" % [data["name"], Universe.PLANET_TYPES[data["type"]]["name"]]
		"station":
			var tdef: Dictionary = GameData.station_types[data["type"]]
			var t := "%s\n%s (tier %d)\nClick: dock" % [data["name"], tdef["name"], int(data["tier"])]
			if not data["shipyard"].is_empty():
				t += "\nShipyard available"
			t += "\nNo-fire zone: %s" % SystemView.fmt_dist(float(data.get("zone", 15000.0)))
			return t
		"haven":
			if data.get("fortress", false):
				return "%s\nPirate Fortress – hostile\nHeavy guns and a garrison. Destroy the garrison to break it: bounty %s." % [data["name"], GameData.fmt_credits(int(data.get("bounty", 0)))]
			return "%s\nPirate Haven – hostile\nIts guns fire on anyone who comes close.\nDocking requires pirate reputation (later)." % data["name"]
		"hazard":
			match String(data.get("kind", "")):
				"radiation":
					return "%s\nShields drain, then the hull burns. Ore inside is purer." % data["name"]
				"ion_storm":
					return "%s\nRadar jammed, lightning knocks out systems. It drifts." % data["name"]
				"minefield":
					return "%s\nOld mines – they go off against anyone." % data["name"]
		"gate":
			var to: int = data["to"]
			var sec: float = Universe.systems[to]["security"]
			return "%s\nDestination security: %.1f\nClick: hyperspace jump" % [data["name"], sec]
		"asteroid":
			if kind == "colossus" and is_depleted():
				return "%s\nMined out – empty" % title()
			if not is_prospected():
				return "%s\nComposition unknown – lock it and use a Prospector Scanner\nClick: select (lock it and use a mining laser)" % title()
			return "%s\nDeposit: %s\nClick: select (lock it and use a mining laser)" % [title(), deposit_text()]
		"anomaly":
			if data["done"]:
				return "%s\nAlready analysed" % data["name"]
			return "%s\nAnalysis: %d%%\nClick with analyzer: analyse" % [data["name"], int(data["analysis"])]
		"pod":
			return "%s\n%s\nFly close to take it aboard" % [data["name"], pod_text()]
		"wreck":
			var items: Array = []
			for k in data["loot"]:
				items.append("%s ×%d" % [GameData.item_name(k), int(data["loot"][k])])
			return "%s\n%s\nClick with salvager: salvage (%d%%)" % [data["name"], ", ".join(PackedStringArray(items)), int(data.get("salvage", 0.0))]
		"beacon":
			return "→ %s\nClick: warp here" % data["name"]
	return title()


var gate_flash := 0.0              # package 40b: the gate flares up as a ship comes through (1 → 0)


func _process(delta: float) -> void:
	_t += delta
	if gate_flash > 0.0:
		gate_flash = maxf(0.0, gate_flash - delta * 0.7)
	if kind == "asteroid":
		if _break_t >= 0.0:
			_break_t += delta                            # 0.6.35.5: the pieces drift apart and fade
			queue_redraw()
			if _break_t > BREAK_TIME:
				_break_t = -1.0
				queue_redraw()
			return
		if _fade_t >= 0.0:
			_fade_t += delta
			modulate.a = clampf(_fade_t / 3.0, 0.0, 1.0)
			if _fade_t > 3.0:
				_fade_t = -1.0
				modulate.a = 1.0
		if not visible:
			set_process(false)                           # package 35: SystemView switches it on again when in view
			return
		if visible:
			rotation += float(data.get("spin", 0.0)) * delta
		return
	if kind == "colossus":
		# turn see-through while the player's ship is underneath
		var want := 1.0
		if view != null and view.player != null and is_instance_valid(view.player):
			var rel: Vector2 = view.player.position - position
			if rel.length() < radius + 600.0:
				var sd := ColossusShape.signed_dist(poly, rel)
				want = lerpf(0.35, 1.0, clampf((sd - 60.0) / (radius * 0.12 + 80.0), 0.0, 1.0))
		modulate.a = lerpf(modulate.a, want, clampf(delta * 6.0, 0.0, 1.0))
		# keep art pixels at ~4 screen pixels, like the ships
		if visible and view != null:
			var quad := radius * 2.0 / COLOSSUS_BODY
			var px := clampf(quad * float(view.camera.zoom.x) / PixelArt.SCALE, 48.0, 1600.0)
			(_col_sprite.material as ShaderMaterial).set_shader_parameter("pixels", floorf(px))
		return
	if kind == "wreck":
		data["life"] = float(data["life"]) - delta
		if float(data["life"]) <= 0.0:
			queue_free()
			return
	if kind in ["station", "haven", "structure"]:
		for i in turret_flash.size():
			turret_flash[i] = maxf(0.0, float(turret_flash[i]) - delta)
		for pi in pad_want:
			pad_open[pi] = move_toward(float(pad_open.get(pi, 0.0)), float(pad_want[pi]), delta * 1.6)
		if not pad_ship.is_empty():
			_pad_check -= delta
			if _pad_check <= 0.0:
				_pad_check = 0.5
				_free_dead_pads()
		var asz := float(art.get("size", radius * 2.0))
		if visible and asz * SystemView.cam_zoom > 3.0 and SystemView.on_screen_at(position, asz + 400.0):
			queue_redraw()                           # 0.6.41.5: not while off screen (0.6.41.6: nor as a speck)
		return
	if kind == "hazard":
		if String(data.get("kind", "")) == "ion_storm":
			position += (data["vel"] as Vector2) * delta              # the storm drifts
			data["pos"] = position
			if position.length() > Universe.SYSTEM_RADIUS * 0.9:
				data["vel"] = -(data["vel"] as Vector2)
		if SystemView.on_screen_at(position, radius * 1.2) and int(_t * 8.0) != int((_t - delta) * 8.0):
			queue_redraw()                                            # 0.6.41.5: a few redraws a second is enough
		return
	if kind in ["gate", "anomaly", "wreck", "beacon", "pod"] and SystemView.on_screen_at(position, radius * 4.0 + 600.0):
		queue_redraw()


func _draw() -> void:
	match kind:
		"station", "haven", "structure":
			var size := Vector2.ONE * float(art["size"])
			draw_texture_rect(_tex, Rect2(-size * 0.5, size), false)
			_draw_station_live()
			_draw_landmark_live()
			if has_pads():
				_draw_pads()
			if String(data.get("faction", "")) != "":
				_draw_holo_banner(String(data["faction"]), size.x)
		"gate":
			var size := Vector2(_tex.get_width(), _tex.get_height()) * 4.0
			var c := PixelArt.gate_color(int(data["class"]))
			var inner := size.x * (0.36 if not data.has("style") else 0.31)
			var st := String(data.get("style", ""))
			var fl := 1.0
			if st in ["old", "pirate"]:
				# package 40b: an old gate's field flickers, now and then it nearly dies
				fl = 0.55 + 0.45 * sin(_t * 7.3) * sin(_t * 2.1 + 1.0)
				if fposmod(_t, 4.7) < 0.18:
					fl = 0.12
				if st == "pirate":
					c = c.lerp(Color(1.0, 0.3, 0.25), 0.35)
			if gate_flash > 0.0:
				fl += gate_flash * 3.0
				draw_circle(Vector2.ZERO, inner * (1.0 + gate_flash * 0.8), Color(c.lightened(0.5), 0.35 * gate_flash))
			for i in 4:
				draw_circle(Vector2.ZERO, inner * (1.0 - i * 0.2), Color(c, (0.06 + 0.04 * sin(_t * 2.0 + i)) * fl))
			for i in 6:
				var a := _t * (0.6 + i * 0.13) + i
				draw_arc(Vector2.ZERO, inner * (0.3 + i * 0.11), a, a + 1.6, 16, Color(c.lightened(0.3), 0.5 * minf(fl, 1.5)), 6.0)
			draw_texture_rect(_tex, Rect2(-size * 0.5, size), false)
		"asteroid":
			if _tex == null:
				var px := int(float(data["radius"]) / 2.2)
				_tex = PixelArt.asteroid_sprite(String(data.get("class", "stony")), String(data.get("shape", "round")), int(data.get("seed", 1)), px, data["ore"])
			var size := Vector2(_tex.get_width(), _tex.get_height()) * (float(data["radius"]) * 2.0 / _tex.get_width()) * 1.05
			if data.has("gone"):
				if _break_t < 0.0:
					return                                   # broken apart – back later
				# 0.6.35.5: pieces drift apart, spin and fade
				var k := _break_t / BREAK_TIME
				var rng := RandomNumberGenerator.new()
				rng.seed = int(data.get("seed", 1))
				for i in 6:
					var dir := Vector2.from_angle(TAU * i / 6.0 + rng.randf_range(-0.4, 0.4))
					var ps := size * rng.randf_range(0.28, 0.45)
					var off := dir * float(data["radius"]) * (0.3 + 2.4 * k)
					draw_set_transform(off, rng.randf_range(-2.0, 2.0) * _break_t, Vector2.ONE)
					draw_texture_rect(_tex, Rect2(-ps * 0.5, ps), false, Color(0.8, 0.78, 0.75, 1.0 - k))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				return
			var mod := Color(0.35, 0.35, 0.4, 0.6) if is_depleted() else Color.WHITE
			draw_texture_rect(_tex, Rect2(-size * 0.5, size), false, mod)
		"anomaly":
			if not data["revealed"]:
				return
			if data.get("veil", false):
				_draw_rift()
				return
			var c := Color(0.8, 0.4, 1.0) if not data["done"] else Color(0.4, 0.4, 0.5)
			for i in 4:
				var r := radius * (0.35 + 0.25 * i) + 6.0 * sin(_t * 2.0 + i)
				var a := _t * (1.0 + i * 0.4) * (1.0 if i % 2 == 0 else -1.0)
				draw_arc(Vector2.ZERO, r, a, a + PI * 1.3, 8, Color(c, 0.85 - i * 0.18), 6.0)
			draw_circle(Vector2.ZERO, radius * 0.25, Color(c.lightened(0.4), 0.5 + 0.3 * sin(_t * 4.0)))
			if not data["done"] and float(data["analysis"]) > 0.0:
				draw_arc(Vector2.ZERO, radius + 20.0, -PI / 2.0, -PI / 2.0 + TAU * float(data["analysis"]) / 100.0, 40, Color(0.9, 0.7, 1.0), 6.0)
		"pod":
			# a small white capsule with a red beacon and a pulsing distress ring
			var s2 := PixelArt.SCALE
			draw_rect(Rect2(Vector2(-4, -7) * s2, Vector2(8, 14) * s2), Color(0.82, 0.84, 0.88))
			draw_rect(Rect2(Vector2(-3, -6) * s2, Vector2(6, 3) * s2), Color(0.35, 0.75, 1.0))
			draw_rect(Rect2(Vector2(-4, 4) * s2, Vector2(8, 3) * s2), Color(0.45, 0.47, 0.52))
			if fmod(_t, 1.0) < 0.5:
				draw_rect(Rect2(Vector2(-1, -9) * s2, Vector2(2, 2) * s2), Color(1.0, 0.25, 0.2))
			var pr := radius + 30.0 * fmod(_t, 2.0)
			draw_arc(Vector2.ZERO, pr, 0.0, TAU, 32, Color(1.0, 0.45, 0.3, 0.6 * (1.0 - fmod(_t, 2.0) / 2.0)), 3.0)
		"site":
			_draw_site()
		"hazard":
			_draw_hazard()
		"wreck":
			var size := Vector2(_tex.get_width(), _tex.get_height()) * PixelArt.SCALE * (2.0 if data.get("relic", false) else 1.0)
			draw_texture_rect(_tex, Rect2(-size * 0.5, size), false)
			var fixed: bool = data.has("hulk") or data.get("relic", false)
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(0.6, 1.0, 0.6, (0.08 + 0.06 * sin(_t * 3.0)) if fixed else (0.25 + 0.2 * sin(_t * 3.0))), 2.0)
			if float(data.get("salvage", 0.0)) > 0.0:
				draw_arc(Vector2.ZERO, radius + 8.0, -PI / 2.0, -PI / 2.0 + TAU * float(data["salvage"]) / 100.0, 32, Color(0.6, 1.0, 0.6), 4.0)
		"beacon":
			var s := label_scale
			var col := poi_color(String(data["kind"]))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(s, s))
			var pts := PackedVector2Array([Vector2(0, -9), Vector2(9, 0), Vector2(0, 9), Vector2(-9, 0)])
			draw_colored_polygon(pts, Color(col, 0.35 + 0.2 * sin(_t * 3.0)))
			pts.append(pts[0])
			draw_polyline(pts, col, 2.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Label (zoom-independent)
	if show_labels and (kind in ["station", "haven", "gate", "structure"] or (kind == "anomaly" and data["revealed"])):
		var font := ThemeDB.fallback_font
		var s := label_scale
		var off := radius + 16.0 * s
		if kind == "beacon":
			off = 14.0 * s
		if data.has("label_y"):
			off = float(data["label_y"]) - 30.0 * s       # 0.6.39.2: a long, thin landmark – the name above it
		draw_set_transform(Vector2(0.0, off), 0.0, Vector2(s, s))
		var text := title()
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		var col := Color(0.85, 0.9, 1.0, 0.9)
		if kind == "beacon":
			col = poi_color(String(data["kind"]))
		draw_string(font, Vector2(-w / 2.0 + 1, 13.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0, 0, 0, 0.8))
		draw_string(font, Vector2(-w / 2.0, 12.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, col)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Holo banner (phase 0.5 package 10): the coat of arms of the station's faction, projected
## beside the station – tinted, scanlined, flickering, now and then a glitch.
## Package 40d: radiation (a sickly yellow-green haze, hazard ring), an ion storm (blue clouds, lightning), an old
## minefield (a faint red-dashed border – the mines themselves are drawn by their own nodes).
func _draw_hazard() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(data.get("seed", 3))
	var px := maxf(1.0, 3.0 / maxf(SystemView.cam_zoom, 0.0001))
	match String(data.get("kind", "")):
		"radiation":
			var col := Color(0.75, 0.95, 0.25)
			# 40e: two slowly turning layers of one haze texture (was 27 big circles – heavy on the fill rate)
			var ht := PixelArt.haze_texture(int(data.get("seed", 3)), Color(col, 0.22))
			for layer in 2:
				draw_set_transform(Vector2.ZERO, _t * (0.01 if layer == 0 else -0.007) + layer * 1.3, Vector2.ONE)
				draw_texture_rect(ht, Rect2(-Vector2.ONE * radius, Vector2.ONE * radius * 2.0), false)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			var seg_n := 48
			for k in seg_n:
				if k % 2 == 0:
					var a0 := k * TAU / seg_n + _t * 0.03
					draw_arc(Vector2.ZERO, radius, a0, a0 + TAU / seg_n, 4, Color(1.0, 0.85, 0.1, 0.5), px * 2.0)
			# the trefoil, small, at the centre
			for k2 in 3:
				var a1 := k2 * TAU / 3.0 - PI / 2.0
				draw_arc(Vector2.ZERO, radius * 0.035, a1 - 0.5, a1 + 0.5, 8, Color(1.0, 0.85, 0.1, 0.25), radius * 0.03)
		"ion_storm":
			var it := PixelArt.haze_texture(int(data.get("seed", 3)), Color(0.35, 0.6, 1.0, 0.4))
			var it2 := PixelArt.haze_texture(int(data.get("seed", 3)) + 17, Color(0.65, 0.85, 1.0, 0.3))
			draw_set_transform(Vector2.ZERO, _t * 0.02, Vector2.ONE)
			draw_texture_rect(it, Rect2(-Vector2.ONE * radius, Vector2.ONE * radius * 2.0), false)
			draw_set_transform(Vector2.ZERO, -_t * 0.015 + 2.0, Vector2.ONE * 0.8)
			draw_texture_rect(it2, Rect2(-Vector2.ONE * radius, Vector2.ONE * radius * 2.0), false)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			# lightning: now and then a jagged bolt between two clouds
			var bolt := int(_t * 2.5)
			var brng := RandomNumberGenerator.new()
			brng.seed = bolt * 7919 + int(data.get("seed", 3))
			if fposmod(_t * 2.5, 1.0) < 0.35:
				var a := Vector2.from_angle(brng.randf() * TAU) * brng.randf() * radius * 0.7
				var b := Vector2.from_angle(brng.randf() * TAU) * brng.randf() * radius * 0.7
				var prev := a
				for j in 8:
					var q := a.lerp(b, (j + 1) / 8.0) + Vector2(brng.randf_range(-1, 1), brng.randf_range(-1, 1)) * radius * 0.04
					draw_line(prev, q, Color(0.8, 0.95, 1.0, 0.9), px * 2.5)
					prev = q
		"minefield":
			var seg_n2 := 40
			for k3 in seg_n2:
				if k3 % 2 == 0:
					var a2 := k3 * TAU / seg_n2
					draw_arc(Vector2.ZERO, radius, a2, a2 + TAU / seg_n2, 4, Color(1.0, 0.35, 0.2, 0.45), px * 1.5)


## Package 40c: the debris haze of an old battlefield or round a derelict – scraps of hull, drawn once.
func _draw_site() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(data.get("seed", 1))
	var n := 220 if String(data.get("kind", "")) == "battlefield" else 90
	for i in n:
		var p := Vector2.from_angle(rng.randf() * TAU) * pow(rng.randf(), 0.7) * radius
		var s := rng.randf_range(8.0, 30.0)
		var g := rng.randf_range(0.25, 0.5)
		var col := Color(g, g * 0.95, g * 0.9, 0.9) if rng.randf() < 0.8 else Color(0.5, 0.27, 0.12, 0.9)
		# a shard of hull plate: thin, turned any way
		draw_set_transform(p, rng.randf() * TAU, Vector2.ONE)
		draw_rect(Rect2(Vector2(-s * 0.5, -s * 0.12), Vector2(s, s * rng.randf_range(0.15, 0.35))), col)
		if rng.randf() < 0.3:
			draw_rect(Rect2(Vector2(-s * 0.2, -s * 0.3), Vector2(s * 0.4, s * 0.12)), col.darkened(0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Package 40c: a tear at the edge of the Veil – a jagged violet rent, white at its heart, shimmering, motes drifting in.
func _draw_rift() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(data.get("seed", 7))
	var done: bool = data["done"]
	var c := Color(0.75, 0.4, 1.0) if not done else Color(0.45, 0.4, 0.55)
	var pts := PackedVector2Array()
	var n := 14
	for i in n + 1:
		var y := lerpf(-radius, radius, float(i) / n)
		var x := rng.randf_range(-0.22, 0.22) * radius * (1.0 - absf(y / radius))
		x += sin(_t * 1.3 + i) * radius * 0.03
		pts.append(Vector2(x, y))
	# the open tear: a lens of deep violet round the rent, glowing at its rim
	var lens := PackedVector2Array()
	for i2 in 25:
		var u := float(i2) / 24.0 * TAU
		var y2 := cos(u) * radius
		var x2 := sin(u) * radius * 0.3 * (1.0 + 0.12 * sin(_t * 1.7 + u * 3.0)) * sqrt(maxf(0.0, 1.0 - pow(y2 / radius, 2.0)))
		lens.append(Vector2(x2 + pts[clampi(int((y2 / radius * 0.5 + 0.5) * n), 0, n)].x, y2))
	draw_colored_polygon(lens, Color(0.12, 0.02, 0.25, 0.75 if not done else 0.35))
	draw_circle(Vector2.ZERO, radius * 0.55, Color(c, 0.07))
	for k in 4:
		var wdt := (34.0 - k * 8.0) * (1.0 + 0.15 * sin(_t * 2.0 + k))
		var cc := c.lerp(Color(1, 0.95, 1), k / 3.0)
		draw_polyline(pts, Color(cc, (0.18 + k * 0.2) * (0.5 if done else 1.0)), wdt)
	for j in 18:
		var ph := fposmod(_t * 0.25 + j * 0.37, 1.0)
		var a0 := j * 2.4
		var p := Vector2.from_angle(a0) * radius * (1.4 - ph) * Vector2(0.7, 1.0)
		draw_rect(Rect2(p, Vector2(10, 10)), Color(c.lightened(0.4), 0.7 * ph))
	if not done and float(data["analysis"]) > 0.0:
		draw_arc(Vector2.ZERO, radius + 40.0, -PI / 2.0, -PI / 2.0 + TAU * float(data["analysis"]) / 100.0, 48, Color(0.9, 0.7, 1.0), 8.0)


func _draw_holo_banner(fid: String, st_size: float) -> void:
	var crest := CrestArt.texture(fid)
	var px := StationArt.PX
	var sc := px * 3.0                     # one crest pixel = 3 station pixels
	var bh := crest.get_height() * sc
	var bw := crest.get_width() * sc
	var center := Vector2(st_size * 0.5 + bw * 0.55, -st_size * 0.1)
	var top_left := center - Vector2(bw, bh) * 0.5
	var fc := FactionData.color_of(fid)
	var holo := Color(0.55, 0.9, 1.0).lerp(fc, 0.35)
	# flicker: soft pulse + short dropouts
	var tick := floorf(_t * 10.0)
	var rnd := fposmod(sin(tick * 12.9898 + float(int(data.get("seed", 1)) % 997)) * 43758.5453, 1.0)
	var alpha := 0.62 + 0.1 * sin(_t * 2.7)
	if rnd > 0.93:
		alpha *= 0.35
	# projector on the station rim + light cone
	var emitter := Vector2(st_size * 0.44, center.y + bh * 0.62)
	draw_rect(Rect2(emitter - Vector2(px * 3.0, px * 2.0), Vector2(px * 6.0, px * 4.0)), Color(0.25, 0.27, 0.32))
	draw_rect(Rect2(emitter - Vector2(px * 1.5, px * 1.0), Vector2(px * 3.0, px * 2.0)), Color(holo, 0.9))
	var cone := PackedVector2Array([emitter, top_left + Vector2(0.0, bh), top_left + Vector2(bw, bh)])
	draw_colored_polygon(cone, Color(holo, 0.07 * alpha / 0.62))
	draw_rect(Rect2(top_left - Vector2.ONE * px * 4.0, Vector2(bw, bh) + Vector2.ONE * px * 8.0), Color(holo, 0.06))
	# the crest, row by row (a glitch band shifts a few rows sideways)
	var glitch_row := -1
	var glitch_off := 0.0
	if rnd > 0.8 and rnd <= 0.93:
		glitch_row = int(rnd * 1000.0) % crest.get_height()
		glitch_off = (rnd - 0.86) * bw * 1.2
	var mod := Color(holo.r * 0.5 + 0.55, holo.g * 0.5 + 0.55, holo.b * 0.5 + 0.55, alpha)
	for row in crest.get_height():
		var off := glitch_off if glitch_row >= 0 and absi(row - glitch_row) <= 2 else 0.0
		draw_texture_rect_region(crest, Rect2(top_left + Vector2(off, row * sc), Vector2(bw, sc)), Rect2(0, row, crest.get_width(), 1), mod)
	# scanlines and a bright sweep running down
	var y := 0.0
	while y < bh:
		draw_rect(Rect2(top_left + Vector2(0.0, y), Vector2(bw, sc * 0.35)), Color(0.0, 0.05, 0.1, 0.22))
		y += sc * 2.0
	var sweep := fposmod(_t * 0.35, 1.0) * bh
	draw_rect(Rect2(top_left + Vector2(0.0, sweep), Vector2(bw, sc * 1.2)), Color(holo.lightened(0.5), 0.18 * alpha))


const VOTE_DRONES := 14              # drones on each lane between The Vote and a relay (0.6.39.2: many more)


## 39d: the ships in a yard's berths – the manufacturer's own hulls, bows outwards, under scaffolding, a section still
## open ("berth" vents of the art; the Axiom Yards' carry no hull and pick Threshold / Parallax by size).
func _draw_berths() -> void:
	var px := StationArt.PX
	for v in art["vents"]:
		if String(v["kind"]) != "berth":
			continue
		var hid := String(v.get("hull", ""))
		var ang := float(v.get("ang", PI * 0.5 * signf(float(v["size"]))))
		if hid == "":
			hid = "axa_threshold" if float(v["phase"]) > 0.5 else "axa_parallax"
		var tex: Texture2D = PixelArt.ship_texture(hid, "civilian" if v.has("hull") else "directorate")
		var tsz := Vector2(tex.get_width(), tex.get_height()) * PixelArt.SCALE
		draw_set_transform(v["pos"], ang, Vector2.ONE)
		draw_texture_rect(tex, Rect2(-tsz * 0.5, tsz), false, Color(0.92, 0.95, 0.95))
		var hl := tsz.x * 0.5
		var hw2 := tsz.y * 0.5 + px * 4.0
		for q in 4:
			var xq := lerpf(-hl * 0.8, hl * 0.8, q / 3.0)
			draw_line(Vector2(xq, -hw2), Vector2(xq, hw2), Color(0.5, 0.55, 0.57, 0.85), px * 1.5)
		draw_rect(Rect2(Vector2(-hl * 0.15, -tsz.y * 0.3), Vector2(hl * 0.45, tsz.y * 0.6)), Color(0.12, 0.14, 0.15, 0.55))
		for q2 in 6:
			draw_line(Vector2(-hl * 0.15 + q2 * hl * 0.09, -tsz.y * 0.3), Vector2(-hl * 0.15 + q2 * hl * 0.09, tsz.y * 0.3), Color(0.55, 0.6, 0.62, 0.7), px)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Work drones hopping between the welding spots ("spark" vents) of a landmark being built.
func _work_drones(count: int, col: Color) -> void:
	var px := StationArt.PX
	var spots: Array = art["vents"].filter(func(v): return String(v["kind"]) == "spark")
	if spots.is_empty():
		return
	for j in count:
		var cyc := _t / 5.0 + j * 0.61 + float(int(data.get("seed", 0)) % 5)
		var leg := int(floorf(cyc))
		var mv := smoothstep(0.0, 0.4, fposmod(cyc, 1.0))
		var a0: Vector2 = spots[(leg + j) % spots.size()]["pos"]
		var a1: Vector2 = spots[(leg + j + 1) % spots.size()]["pos"]
		var off := (a0.normalized() if a0.length() > 1.0 else Vector2.UP) * (40.0 + 15.0 * j)
		var dp := (a0 + off).lerp(a1 + off, mv)
		draw_rect(Rect2(dp - Vector2(px, px), Vector2(px * 2.0, px * 2.0)), Color(col, 0.95))
		draw_circle(dp, px * 2.5, Color(col, 0.25))
		if mv >= 1.0 and posmod(int(_t * 8.0) + j, 3) == 0:
			draw_circle(dp - off * 0.5, px * 2.0, Color(1.0, 0.95, 0.75, 0.9))


## Package 39: the life of the landmarks – drones shuttling between The Vote and its relay stations, the work
## drones round the Res Publica.
func _draw_landmark_live() -> void:
	var px := StationArt.PX
	_draw_berths()                                    # 39d: the ships being built in the yards' berths
	match String(data.get("art", "")):
		"weapon_platform":
			_work_drones(6, Color(1.0, 0.45, 0.35))
		"ew_yard", "khi_yard", "aur_yard", "hdy_yard":
			_work_drones(6, Color(1.0, 0.85, 0.5))
		"vote":
			var hub_r := float(art["size"]) * 0.32
			var k := 0
			for off in data.get("relay_offs", []):
				var to: Vector2 = off
				var dir := to.normalized()
				var a := dir * hub_r
				var b := to - dir * 260.0
				var lane := dir.orthogonal()
				for j in VOTE_DRONES:
					# 0.6.39.2: a busy shuttle – two lanes, out on one and back on the other
					var cyc := _t / 16.0 + float(j) / VOTE_DRONES * 2.0 + k * 0.17
					var f := fposmod(cyc, 1.0)
					var out := posmod(int(floorf(cyc)), 2) == 0
					var s := smoothstep(0.0, 1.0, f)
					var pos := a.lerp(b, s if out else 1.0 - s) + lane * (90.0 if out else -90.0) * sin(s * PI)
					var fade := clampf(minf(f, 1.0 - f) * 12.0, 0.0, 1.0)
					draw_set_transform(pos, dir.angle() + (0.0 if out else PI), Vector2.ONE)
					draw_rect(Rect2(Vector2(-px * 1.5, -px), Vector2(px * 3.0, px * 2.0)), Color(0.82, 0.88, 0.96, fade))
					draw_rect(Rect2(Vector2(-px * 5.5, -px * 0.4), Vector2(px * 4.0, px * 0.8)), Color(0.45, 0.7, 1.0, 0.45 * fade))
					draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
					draw_circle(pos, px * 3.0, Color(0.45, 0.7, 1.0, 0.18 * fade))
				k += 1
		"pilgrim_gate":
			# 39b: the light it throws home (away from the star) and the pilgrims passing through, one by one
			# (0.6.39.5: the light itself – rays from the spires gathering in a focus – is the SystemView's PilgrimBeam)
			var home := position.normalized() if position.length() > 1.0 else Vector2.RIGHT
			var gr := float(art["size"]) * 0.32
			draw_circle(Vector2.ZERO, gr * 0.8, Color(1.0, 0.85, 0.5, 0.06 + 0.03 * sin(_t * 2.0)))
			for j in 9:
				var f := fposmod(_t / 70.0 + j / 9.0, 1.0)              # from far away up to the gate
				var pos := -home * (4200.0 * (1.0 - f)) + home.orthogonal() * 120.0 * sin(j * 1.7)
				var a := clampf((1.0 - f) * 8.0, 0.0, 1.0) * clampf(f * 10.0, 0.0, 1.0)
				draw_set_transform(pos, home.angle(), Vector2.ONE)
				draw_rect(Rect2(Vector2(-px * 4.0, -px * 1.5), Vector2(px * 8.0, px * 3.0)), Color(0.86, 0.8, 0.68, a))
				draw_rect(Rect2(Vector2(-px * 1.0, -px * 1.0), Vector2(px * 2.0, px * 2.0)), Color(1.0, 0.85, 0.45, a))
				draw_rect(Rect2(Vector2(-px * 7.0, -px * 0.7), Vector2(px * 3.0, px * 1.4)), Color(1.0, 0.65, 0.3, 0.5 * a))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				if f > 0.97:
					draw_circle(pos, px * 10.0, Color(1.0, 0.9, 0.6, (f - 0.97) * 25.0))
		"mirror":
			# 39c / 0.6.39.8: a curved reflector that turns to Curie as you see her (in the local view she hangs in
			# the sky with parallax) – its facets gather the light into a beam that lands on the surface
			if view != null and data.has("beam_to"):
				var tv: Dictionary = view.body_view(String(data["beam_to"]))
				# only near the camera does the planet's place in the sky count – from afar aim at its true place
				if not tv.is_empty() and position.distance_to(view.camera.get_screen_center_position()) > 80000.0:
					var bd := Universe.body_by_id(view.layout, String(data["beam_to"]))
					tv = {"pos": bd["pos"], "r": float(bd["radius"])}
				if not tv.is_empty():
					var to: Vector2 = (tv["pos"] as Vector2) - position
					var dist := to.length()
					var size := float(art["size"])
					var rc := size * 0.5
					var foc := Vector2(rc * 0.9, 0.0)
					var hit_d := maxf(dist - float(tv["r"]) * 0.95, foc.x + 10.0)
					var lv := 0.8 + 0.2 * sin(_t * 0.9 + float(data.get("seed", 0)))
					draw_set_transform(Vector2.ZERO, to.angle(), Vector2.ONE)
					# the beam onto the planet
					draw_line(foc, Vector2(hit_d, 0), Color(1.0, 0.97, 0.85, 0.08 * lv), size * 0.5)
					draw_line(foc, Vector2(hit_d, 0), Color(1.0, 0.98, 0.9, 0.22 * lv), size * 0.14)
					draw_circle(Vector2(hit_d, 0), size * 0.45, Color(1.0, 0.95, 0.8, 0.14 * lv))
					draw_circle(Vector2(hit_d, 0), size * 0.16, Color(1.0, 0.98, 0.9, 0.35 * lv))
					# struts from the hub to the reflector
					for k in 3:
						var fa := (k - 1) * 0.5
						draw_line(Vector2.ZERO, Vector2(-cos(fa) * rc + rc * 0.45, sin(fa) * rc), Color(0.4, 0.45, 0.47), px * 2.0)
					# the facets on a curve, hollow side to the planet; light from each into the focus
					var nf := 11
					for k2 in nf:
						var fa2 := lerpf(-0.75, 0.75, float(k2) / (nf - 1))
						var fp := Vector2(-cos(fa2) * rc + rc * 0.45, sin(fa2) * rc)
						var tn := Vector2(sin(fa2), cos(fa2))
						var nrm := Vector2(cos(fa2), -sin(fa2))
						var hw := size * 0.065
						var q := PackedVector2Array([fp - tn * hw - nrm * px * 3.0, fp + tn * hw - nrm * px * 3.0, fp + tn * hw + nrm * px * 3.0, fp - tn * hw + nrm * px * 3.0])
						var shine := 0.75 + 0.25 * sin(_t * 1.1 + k2 * 0.6)
						draw_colored_polygon(q, Color(0.72 * shine, 0.86 * shine, 0.95 * shine))
						draw_line(fp - tn * hw, fp + tn * hw, Color(1.0, 1.0, 1.0, 0.8 * shine), px)
						draw_line(fp, foc, Color(1.0, 0.97, 0.85, 0.12 * lv), px * 1.5)
					draw_circle(foc, px * 5.0, Color(1.0, 0.98, 0.9, 0.7 * lv))
					draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"gate_frame":
			# 0.6.39.9: work drones at the unfinished ring – hopping from welding spot to welding spot
			var spots2: Array = art["vents"].filter(func(v): return String(v["kind"]) == "spark")
			if not spots2.is_empty():
				for j2 in 5:
					var cyc2 := _t / 5.0 + j2 * 0.61 + float(int(data.get("seed", 0)) % 5)
					var leg2 := int(floorf(cyc2))
					var mv2 := smoothstep(0.0, 0.4, fposmod(cyc2, 1.0))
					var a0: Vector2 = spots2[(leg2 + j2) % spots2.size()]["pos"]
					var a1: Vector2 = spots2[(leg2 + j2 + 1) % spots2.size()]["pos"]
					var off2 := a0.normalized() * (40.0 + 15.0 * j2)
					var dp := (a0 + off2).lerp(a1 + off2, mv2)
					draw_rect(Rect2(dp - Vector2(px, px), Vector2(px * 2.0, px * 2.0)), Color(0.75, 1.0, 0.85, 0.95))
					draw_circle(dp, px * 2.5, Color(0.4, 1.0, 0.6, 0.25))
					if mv2 >= 1.0 and posmod(int(_t * 8.0) + j2, 3) == 0:
						draw_circle(dp - off2 * 0.5, px * 2.0, Color(1.0, 0.95, 0.75, 0.9))
			# 39c: now and then a test: the ring flickers green, a wormhole tries to open – and collapses
			var cyc := fposmod(_t / 40.0 + float(int(data.get("seed", 0)) % 7) / 7.0, 1.0)
			if cyc < 0.08:
				var k2 := cyc / 0.08
				var r2 := float(art["size"]) * 0.33
				draw_circle(Vector2.ZERO, r2 * (0.3 + 0.7 * k2), Color(0.3, 1.0, 0.6, 0.35 * (1.0 - k2)))
				draw_arc(Vector2.ZERO, r2, 0.0, TAU, 32, Color(0.6, 1.0, 0.8, 0.8 * (1.0 - k2)), px * 3.0)
		"axiom_yards":
			# 39c: Axiom ships testing their cloaks round the yard – fading out, drifting on, fading in again
			for j in 4:
				var a3 := _t * 0.03 * (1.0 if j % 2 == 0 else -1.0) + j * TAU / 4.0
				var pos3 := Vector2.from_angle(a3) * float(art["size"]) * (0.75 + 0.1 * j)
				var vis := clampf(0.5 + 0.8 * sin(_t * 0.5 + j * 1.9), 0.0, 1.0)
				draw_set_transform(pos3, a3 + PI * 0.5 * (1.0 if j % 2 == 0 else -1.0), Vector2.ONE)
				var shp := PackedVector2Array([Vector2(px * 10.0, 0), Vector2(-px * 6.0, -px * 4.0), Vector2(-px * 4.0, 0), Vector2(-px * 6.0, px * 4.0)])
				draw_colored_polygon(shp, Color(0.55, 0.62, 0.64, vis))
				draw_line(Vector2(-px * 4.0, 0), Vector2(px * 9.0, 0), Color(0.3, 1.0, 0.6, vis), px)
				if vis > 0.05 and vis < 0.95:
					draw_arc(Vector2.ZERO, px * 12.0, 0.0, TAU, 16, Color(0.4, 0.9, 1.0, 0.4 * (1.0 - absf(vis - 0.5) * 2.0)), px)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"lux_aeterna":
			# 39b: the great focus crystal at her bow glows and pulses
			var size3 := float(art["size"])
			var cp := Vector2(-size3 * 0.42, 0.0)
			var pulse := 0.5 + 0.5 * sin(_t * 1.6)
			draw_circle(cp, size3 * 0.05, Color(1.0, 0.2, 0.3, 0.12 + 0.12 * pulse))
			draw_circle(cp, size3 * 0.025, Color(1.0, 0.45, 0.5, 0.18 + 0.2 * pulse))
			# 0.6.39.5: work drones at her hull – hopping from one welding spot to the next, flashing as they weld
			var spots: Array = art["vents"].filter(func(v): return String(v["kind"]) == "spark")
			if not spots.is_empty():
				for j in 14:
					var cyc := _t / 6.0 + j * 0.53
					var leg := int(floorf(cyc))
					var f := fposmod(cyc, 1.0)
					var p0: Vector2 = spots[(leg * 3 + j) % spots.size()]["pos"]
					var p1: Vector2 = spots[((leg + 1) * 3 + j) % spots.size()]["pos"]
					var off := Vector2(cos(j * 2.1), sin(j * 1.7)) * 70.0
					var mv := smoothstep(0.0, 0.35, f)                  # fly over, then hover and weld
					var pos := (p0 + off).lerp(p1 + off, mv) + Vector2(0.0, -sin(mv * PI) * 120.0)
					draw_rect(Rect2(pos - Vector2(px, px), Vector2(px * 2.0, px * 2.0)), Color(1.0, 0.8, 0.4, 0.95))
					draw_circle(pos, px * 2.5, Color(1.0, 0.6, 0.25, 0.25))
					if mv >= 1.0 and posmod(int(_t * 9.0) + j, 3) == 0:
						draw_circle(pos + Vector2(0.0, px * 3.0), px * 2.2, Color(1.0, 0.95, 0.75, 0.9))
		"res_publica":
			# 0.6.39.2: drones launching from the hatches on her hull, flying a short loop and landing again
			var hatches: Array = art["vents"].filter(func(v): return String(v["kind"]) == "hatch")
			if hatches.is_empty():
				return
			for j in 16:
				var hv: Dictionary = hatches[(j * 7) % hatches.size()]
				var hp: Vector2 = hv["pos"]
				var cyc := _t / 9.0 + j * 0.37
				var f := fposmod(cyc, 1.0)
				var side := signf(hp.y) if absf(hp.y) > 1.0 else 1.0
				var arc := sin(f * PI)
				var pos2 := hp + Vector2(cos(f * TAU) * 260.0, side * arc * 520.0)
				var a2 := clampf(arc * 4.0, 0.0, 1.0)
				draw_rect(Rect2(pos2 - Vector2(px, px), Vector2(px * 2.0, px * 2.0)), Color(0.85, 0.9, 1.0, a2))
				draw_circle(pos2, px * 3.0, Color(0.45, 0.7, 1.0, 0.2 * a2))


## Animated parts of a station: blinking lights, bay guide lights, neon signs, steam/smoke/sparks,
## shuttle traffic and turret barrels (all in local km, drawn over the texture).
func _draw_station_live() -> void:
	var px := StationArt.PX
	var acc: Color = PixelArt.STATION_ACCENT.get(String(data.get("type", "")), Color.WHITE)
	# vents: steam from cooling towers, smoke from chimneys, furnace glow, welding sparks
	for v in art["vents"]:
		var p: Vector2 = v["pos"]
		var sz: float = v["size"]
		var ph: float = v["phase"]
		match String(v["kind"]):
			"steam", "smoke":
				var steam: bool = v["kind"] == "steam"
				for j in 4:
					var f := fposmod(_t * (0.18 if steam else 0.3) + ph + j * 0.25, 1.0)
					var drift := Vector2(0.35, -1.0).normalized() * sz * f * (2.2 if steam else 3.0)
					var col := Color(0.85, 0.92, 1.0, 0.28 * (1.0 - f)) if steam else Color(0.35, 0.33, 0.32, 0.35 * (1.0 - f))
					draw_circle(p + drift, sz * (0.5 + f * (1.8 if steam else 1.2)), col)
			"glow":
				draw_circle(p, sz * 1.6, Color(1.0, 0.5, 0.15, 0.18 + 0.1 * sin(_t * 3.0 + ph * 10.0)))
			"spark":
				var h := fposmod(sin(floorf(_t * 14.0) * 12.9898 + ph * 78.233) * 43758.5453, 1.0)
				if h > 0.72:
					draw_rect(Rect2(p - Vector2.ONE * px, Vector2.ONE * px * 2.0), Color(1.0, 0.95, 0.7))
					draw_circle(p, px * 3.0, Color(1.0, 0.85, 0.4, 0.25))
	# neon advertising: scrolling bands
	for ne in art["neons"]:
		draw_set_transform(ne["pos"], float(ne["ang"]), Vector2.ONE)
		var len: float = ne["len"]
		var wid: float = ne["wid"]
		var segs := int(len / (px * 3.0))
		for k in segs:
			var on := posmod(k + int(_t * 7.0), 7) < 4
			var col2 := acc.lerp(Color.WHITE, 0.35) if on else Color(1.0, 0.3, 0.75)
			draw_rect(Rect2(Vector2(-len * 0.5 + k * len / segs, -wid * 0.5), Vector2(len / segs - px * 0.5, wid)), Color(col2, 0.9 if on else 0.55))
		draw_rect(Rect2(Vector2(-len * 0.5, -wid * 1.4), Vector2(len, wid * 2.8)), Color(acc, 0.12 + 0.06 * sin(_t * 5.0)))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# docking bays: chasing guide lights into the bay + shuttle traffic
	var bi := 0
	for b in art["bays"]:
		var mouth: Vector2 = b["pos"]
		var dir: Vector2 = b["dir"]
		var side := dir.orthogonal()
		var depth: float = b["depth"]
		var width: float = b["width"]
		var step := posmod(int(_t * 6.0), 5)
		for j in 5:
			var q := mouth - dir * depth * (0.08 + j * 0.18)
			var lit := j == step
			for sg in [-1.0, 1.0]:
				var lp: Vector2 = q + side * sg * (width * 0.5 - px * 1.5)
				draw_rect(Rect2(lp - Vector2.ONE * px * 0.6, Vector2.ONE * px * 1.2), Color(1.0, 0.75, 0.25, 1.0 if lit else 0.25))
				if lit:
					draw_circle(lp, px * 2.5, Color(1.0, 0.7, 0.2, 0.25))
		if kind == "station":
			var cyc := _t * 0.035 + bi * 0.41
			var f := fposmod(cyc, 1.0)
			var outbound := posmod(int(floorf(cyc)), 2) == 0
			var s := f if outbound else 1.0 - f
			var sp := mouth + dir * (s * 3200.0 - 120.0)
			var a := clampf(minf(f, 1.0 - f) * 8.0, 0.0, 1.0)
			draw_set_transform(sp, dir.angle() + (0.0 if outbound else PI), Vector2.ONE)
			draw_rect(Rect2(Vector2(-px * 2.0, -px), Vector2(px * 4.0, px * 2.0)), Color(0.75, 0.8, 0.9, a))
			draw_rect(Rect2(Vector2(-px * 6.0, -px * 0.4), Vector2(px * 4.0, px * 0.8)), Color(0.5, 0.8, 1.0, 0.35 * a))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		bi += 1
	# turret barrels (aim at their target when the station defends itself)
	for i in art["turrets"].size():
		var tp: Vector2 = art["turrets"][i]
		var aim: float = turret_aim[i]
		var tip := tp + Vector2.from_angle(aim) * px * 9.0
		draw_line(tp, tip, Color(0.2, 0.21, 0.25), px * 2.2)
		draw_line(tp, tip, Color(0.45, 0.48, 0.55), px * 1.0)
		if float(turret_flash[i]) > 0.0:
			draw_circle(tip, px * 4.0 * float(turret_flash[i]) / 0.25, Color(1.0, 0.8, 0.4, 0.8))
	# blinking navigation lights and beacons
	for l in art["lights"]:
		var lp2: Vector2 = l["pos"]
		var ph2: float = l["phase"]
		var a2 := 0.0
		if bool(l["strobe"]):
			a2 = 1.0 if fposmod(_t * float(l["rate"]) * 0.5 + ph2, 1.0) < 0.15 else 0.15
		else:
			a2 = 0.55 + 0.45 * sin(_t * float(l["rate"]) * 2.0 + ph2)
		var lc: Color = l["col"]
		draw_rect(Rect2(lp2 - Vector2.ONE * px, Vector2.ONE * px * 2.0), Color(lc, a2))
		if a2 > 0.5:
			draw_circle(lp2, px * 4.0, Color(lc, 0.2 * a2))


# ---------------------------------------------------------------- Package 26: landing pads

func has_pads() -> bool:
	return not art.get("pads", []).is_empty()


func pad_world(i: int) -> Vector2:
	return position + (art["pads"][i]["pos"] as Vector2)


func pad_dir(i: int) -> Vector2:
	return art["pads"][i]["dir"]


func pad_of(ship) -> int:
	for i in pad_ship:
		if pad_ship[i] == ship:
			return int(i)
	return -1


## A pad for `ship` (the one it already holds, else the free one nearest to `near`); -1 = all taken.
## Only one ship lands on or lifts off a pad at a time.
func claim_pad(ship, near: Vector2) -> int:
	var own := pad_of(ship)
	if own >= 0:
		return own
	_free_dead_pads()
	var best := -1
	var bd := INF
	for i2 in art["pads"].size():
		if pad_ship.has(i2):
			continue
		var d := pad_world(i2).distance_to(near)
		if d < bd:
			bd = d
			best = i2
	if best >= 0:
		pad_ship[best] = ship
	return best


## Review K11: frees the pads whose ship is gone or no longer landing / lifting off.
func _free_dead_pads() -> void:
	for i in pad_ship.keys():
		var s = pad_ship[i]
		if s == null or not is_instance_valid(s) or s.dying or not String(s.order.get("type", "")) in ["dock", "docking", "undocking"]:
			pad_ship.erase(i)
			pad_want[i] = 0.0


func release_pad(ship) -> void:
	var i := pad_of(ship)
	if i >= 0:
		pad_ship.erase(i)
		pad_want[i] = 0.0


func set_pad_open(i: int, open: bool) -> void:
	pad_want[i] = 1.0 if open else 0.0


## The pads' live parts: the sliding hatch doors and a status lamp (green = free, amber blinking = in use).
func _draw_pads() -> void:
	var px := StationArt.PX
	for i in art["pads"].size():
		var pd: Dictionary = art["pads"][i]
		var pc: Vector2 = pd["pos"]
		var dir: Vector2 = pd["dir"]
		var h: float = pd["hatch"]
		var k := float(pad_open.get(i, 0.0))
		draw_set_transform(pc, dir.angle(), Vector2.ONE)
		draw_rect(Rect2(Vector2(-h, -h), Vector2(h, h) * 2.0), Color(0.02, 0.02, 0.03))
		var door := h * (1.0 - k)
		if door > 0.5:
			draw_rect(Rect2(Vector2(-h, -h), Vector2(door, h * 2.0)), Color(0.3, 0.3, 0.33))
			draw_rect(Rect2(Vector2(h - door, -h), Vector2(door, h * 2.0)), Color(0.27, 0.27, 0.3))
			draw_rect(Rect2(Vector2(-h + door - px * 0.5, -h), Vector2(px * 0.5, h * 2.0)), Color(0.12, 0.12, 0.14))
			for st in [-1.0, 1.0]:
				draw_rect(Rect2(Vector2(-h, st * h * 0.5 - px * 0.5), Vector2(door, px)), Color(0.75, 0.6, 0.2, 0.8))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var busy := pad_ship.has(i)
		var lamp := pc + dir * (float(pd["radius"]) + px * 3.0)
		var on := not busy or fposmod(_t * 2.5, 1.0) < 0.5
		var lc := Color(1.0, 0.7, 0.2) if busy else Color(0.3, 1.0, 0.45)
		draw_rect(Rect2(lamp - Vector2.ONE * px, Vector2.ONE * px * 2.0), Color(lc, 1.0 if on else 0.25))
		if on:
			draw_circle(lamp, px * 4.0, Color(lc, 0.25))


## Docking bay closest to a point (world coordinates): {mouth, dir, width, depth} in world space.
func nearest_bay(from: Vector2) -> Dictionary:
	var best := {}
	var bd := INF
	for b in art.get("bays", []):
		var mouth: Vector2 = position + (b["pos"] as Vector2)
		var d := mouth.distance_to(from)
		if d < bd:
			bd = d
			best = {"mouth": mouth, "dir": b["dir"], "width": b["width"], "depth": b["depth"]}
	return best


static func poi_color(k: String) -> Color:
	match k:
		"orbit":
			return Color(0.55, 0.85, 1.0)
		"belt":
			return Color(0.9, 0.75, 0.45)
		"gate":
			return Color(0.6, 0.7, 1.0)
		"anomaly":
			return Color(0.85, 0.5, 1.0)
	return Color.WHITE
