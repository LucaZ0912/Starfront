class_name Celestial
extends Node2D
## Objects in a system: station, hyperspace gate, asteroid, anomaly, wreck.
## Star and planets are rendered by the SystemView as celestial bodies (see make_*_sprite).
## `data` references the dictionary from the Universe layout directly (changes persist).

const PlanetShader = preload("res://shaders/planet.gdshader")
const StarShader = preload("res://shaders/star.gdshader")
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
		"station", "haven":
			# modular pixel-art station (StationArt): texture + docking bays, lights, vents, turrets
			art = StationArt.build(data)
			_tex = art["texture"]
			radius = float(art["radius"])
			for i in art["turrets"].size():
				turret_aim.append(randf() * TAU)
				turret_flash.append(0.0)
		"gate":
			_tex = PixelArt.gate_texture(int(data["class"]))
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
			radius = 90.0
		"wreck":
			_tex = PixelArt.wreck_texture(int(data.get("seed", 3)))
			radius = 40.0
		"pod":
			radius = 30.0                        # package 31a: an escape pod
		"beacon":
			radius = 45.0
	if kind in ["planet", "star_far", "colossus"]:
		pass
	elif z_index == 0:
		z_index = -1 if kind in ["station", "haven", "gate", "asteroid"] else 0


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
	mat.set_shader_parameter("shape", {"potato": 0, "binary": 1, "shard": 2}.get(String(d.get("shape", "potato")), 0))
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
	var t: Dictionary = Universe.PLANET_TYPES[p["type"]]
	var spr := Sprite2D.new()
	spr.texture = PixelArt.white()
	var ring: bool = p.get("ring", false)
	var quad := r * (2.0 / 0.5 if ring else 2.0 / 0.86)
	spr.scale = Vector2.ONE * quad / 64.0
	var mat := ShaderMaterial.new()
	mat.shader = PlanetShader
	mat.set_shader_parameter("col_a", t["a"])
	mat.set_shader_parameter("col_b", t["b"])
	mat.set_shader_parameter("col_c", t["c"])
	mat.set_shader_parameter("atmo", t["atmo"])
	mat.set_shader_parameter("gas", t["gas"])
	mat.set_shader_parameter("seed", float(p.get("seed", 1.0)))
	mat.set_shader_parameter("light_dir", ldir)
	mat.set_shader_parameter("has_ring", 1.0 if ring else 0.0)
	mat.set_shader_parameter("radius", 0.5 if ring else 0.86)
	mat.set_shader_parameter("pixels", clampf(quad / 7.0, 48.0, 220.0))
	mat.set_shader_parameter("spin", 0.004 if r > 300.0 else 0.015)
	spr.material = mat
	return spr


static func make_star_sprite(col: Color, r: float) -> Sprite2D:
	var spr := Sprite2D.new()
	spr.texture = PixelArt.white()
	var quad := r * 2.0 / 0.45
	spr.scale = Vector2.ONE * quad / 64.0
	var mat := ShaderMaterial.new()
	mat.shader = StarShader
	mat.set_shader_parameter("color", col)
	mat.set_shader_parameter("pixels", clampf(quad / 10.0, 60.0, 200.0))
	spr.material = mat
	return spr


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
	return "%s  •  deposit %s" % [", ".join(parts), deposit_text()]


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
			return float(data["amount"]) <= 0.0
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
		"planet", "star_far":
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
			return "%s\nPirate Haven – hostile\nIts guns fire on anyone who comes close.\nDocking requires pirate reputation (later)." % data["name"]
		"gate":
			var to: int = data["to"]
			var sec: float = Universe.systems[to]["security"]
			return "%s\nRoute class %d   Destination security: %.1f\nClick: hyperspace jump" % [data["name"], int(data["class"]), sec]
		"asteroid":
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


func _process(delta: float) -> void:
	_t += delta
	if kind == "asteroid":
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
	if kind in ["station", "haven"]:
		for i in turret_flash.size():
			turret_flash[i] = maxf(0.0, float(turret_flash[i]) - delta)
		for pi in pad_want:
			pad_open[pi] = move_toward(float(pad_open.get(pi, 0.0)), float(pad_want[pi]), delta * 1.6)
		if not pad_ship.is_empty():
			_pad_check -= delta
			if _pad_check <= 0.0:
				_pad_check = 0.5
				_free_dead_pads()
		if visible:
			queue_redraw()
		return
	if kind in ["gate", "anomaly", "wreck", "beacon", "pod"]:
		queue_redraw()


func _draw() -> void:
	match kind:
		"station", "haven":
			var size := Vector2.ONE * float(art["size"])
			draw_texture_rect(_tex, Rect2(-size * 0.5, size), false)
			_draw_station_live()
			if has_pads():
				_draw_pads()
			if String(data.get("faction", "")) != "":
				_draw_holo_banner(String(data["faction"]), size.x)
		"gate":
			var size := Vector2(_tex.get_width(), _tex.get_height()) * 4.0
			var c := PixelArt.gate_color(int(data["class"]))
			var inner := size.x * 0.36
			for i in 4:
				draw_circle(Vector2.ZERO, inner * (1.0 - i * 0.2), Color(c, 0.06 + 0.04 * sin(_t * 2.0 + i)))
			for i in 6:
				var a := _t * (0.6 + i * 0.13) + i
				draw_arc(Vector2.ZERO, inner * (0.3 + i * 0.11), a, a + 1.6, 16, Color(c.lightened(0.3), 0.5), 6.0)
			draw_texture_rect(_tex, Rect2(-size * 0.5, size), false)
		"asteroid":
			if _tex == null:
				var px := int(float(data["radius"]) / 2.2)
				_tex = PixelArt.asteroid_sprite(String(data.get("class", "stony")), String(data.get("shape", "round")), int(data.get("seed", 1)), px, data["ore"])
			var size := Vector2(_tex.get_width(), _tex.get_height()) * (float(data["radius"]) * 2.0 / _tex.get_width()) * 1.05
			var mod := Color(0.35, 0.35, 0.4, 0.6) if is_depleted() else Color.WHITE
			draw_texture_rect(_tex, Rect2(-size * 0.5, size), false, mod)
		"anomaly":
			if not data["revealed"]:
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
		"wreck":
			var size := Vector2(_tex.get_width(), _tex.get_height()) * PixelArt.SCALE
			draw_texture_rect(_tex, Rect2(-size * 0.5, size), false)
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, Color(0.6, 1.0, 0.6, 0.25 + 0.2 * sin(_t * 3.0)), 2.0)
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
	if show_labels and (kind in ["station", "haven", "gate"] or (kind == "anomaly" and data["revealed"])):
		var font := ThemeDB.fallback_font
		var s := label_scale
		var off := radius + 16.0 * s
		if kind == "beacon":
			off = 14.0 * s
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
