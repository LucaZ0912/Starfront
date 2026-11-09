class_name GroundView
extends CanvasLayer
## Package 49: on foot – a walkable place drawn over the space view (which keeps running below). The pilot walks with
## WASD (Shift runs), E uses what is in front of him: a shop door opens its window, the crew in the bar can be spoken
## to, the lift leads back to the ship. 0.7.49.2: the slanted view – furniture and people sorted by depth, space
## (the system's own star and the station's planet) beyond the window front.

signal used(zone: Dictionary)

const LAYER := 12
const BgShader = preload("res://shaders/background.gdshader")

var map: GroundMap
var station: Dictionary = {}
var pilot: Walker
var people: Array = []
var input_enabled := true
var zone: Dictionary = {}
var _space: ColorRect
var _sky: Node2D
var _world: Node2D
var _hull: TextureRect
var _window: Control                  # the window front's opening – space is only drawn inside it
var _neb: ColorRect
var _off0 = null
var _lights: Node2D
var _flicker: Array = []              # [sprite, base alpha, phase]
static var _glow_tex: Texture2D
var _sorted: Node2D
var _signs: Node2D
var _prompt: Label
var _title: Label
var _t := 0.0
var _ui: Control
# 0.7.49.6: lifts with doors, seats, the jukebox, talking to the crew
var _lift_node: Node2D
var _lift_open: Array = []            # 0 closed … 1 open, per lift
var _ride: Dictionary = {}            # riding the lift back to the ship: {lift, zone, phase, t}
var _arrive := 0.0                    # stepping out of the lift when the deck opens
var _arrive_lift := 0
var _seat: Dictionary = {}            # the seat the pilot sits on
var _stand_pos := Vector2.ZERO
var _music: AudioStreamPlayer
var track := -1                       # the jukebox: -1 off, else the track playing
var _toast := ""
var _toast_t := 0.0
var level := ""                         # 0.7.49.8: "hangar" or "commercial"
var _avail: Dictionary = {}
var _crew: Array = []
var _sys := -1
var _lift_menu: Control = null
var _ship_spr: Sprite2D
var talk: DialogueView = null          # a conversation (0.7.49.7: after Luz's mockup)
var talk_menu: CrewTalk = null          # its "Info": the questions, the record, signing on
var _talk_offer := {}
var _talk_index := -1
var _talk_hired := false


func _ready() -> void:
	layer = LAYER
	_space = ColorRect.new()                        # everything that is neither deck nor window: black
	_space.color = Color(0, 0, 0)
	_space.set_anchors_preset(Control.PRESET_FULL_RECT)
	_space.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_space)
	_world = Node2D.new()
	add_child(_world)
	var ui := Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	_ui = ui
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	_music.volume_db = -6.0
	add_child(_music)
	_title = UI.label("", 18, UI.NEON_CYAN)
	_title.position = Vector2(24, 18)
	ui.add_child(_title)
	var hint := UI.label("", 12, UI.TEXT_DIM)
	hint.position = Vector2(24, 46)
	hint.text = "%s %s %s %s walk  •  %s run  •  %s use / talk  •  the stairs in the hangar lead back to your ship" % [
		Keybinds.key_text("walk_up"), Keybinds.key_text("walk_left"), Keybinds.key_text("walk_down"), Keybinds.key_text("walk_right"),
		Keybinds.key_text("boost"), Keybinds.key_text("interact")]
	ui.add_child(hint)
	_prompt = UI.label("", 18, UI.GOLD)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.offset_top = -90
	_prompt.offset_bottom = -60
	_prompt.offset_left = -500
	_prompt.offset_right = 500
	ui.add_child(_prompt)


## A station's deck: available = service id -> "" or the reason it is closed; crew = the bar's offers.
## You start in the hangar, at the stairs up from your ship.
func setup_station(p_station: Dictionary, available: Dictionary, crew: Array = [], sys_id: int = -1) -> void:
	station = p_station
	_avail = available
	_crew = crew
	_sys = sys_id
	go_level("hangar", "stairs")


## Goes to a level of the station – "hangar" or "commercial"; arrive: "stairs" (at the hangar's stairs), "lift" (out
## of a lift, the doors opening).
func go_level(p_level: String, arrive: String = "lift") -> void:
	for c in _world.get_children():
		_world.remove_child(c)
		c.queue_free()
	people.clear()
	_lift_open.clear()
	_flicker.clear()
	_seat = {}
	_ride = {}
	_off0 = null
	zone = {}
	_arrive = 0.0
	_ship_spr = null
	level = p_level
	if level == "hangar":
		var sz := _ship_size()
		map = DeckGen.build_hangar(station, sz.x, sz.y, _avail)
	else:
		map = DeckGen.build(station, _avail, GameState.bar_offers(station) if _avail.has("bar") else [])
	_build()
	_space_view(_sys)
	_title.text = "%s – %s" % [map.title, "Hangar" if level == "hangar" else "Commercial level"]
	if arrive == "lift" and not map.lifts.is_empty():
		_arrive_lift = 0
		var l0: Dictionary = map.lifts[0]
		pilot.pos = Vector2((float(l0["x"]) + float(l0["w"]) * 0.5) * GroundMap.TILE, (float(l0["y"]) + 1.0) * GroundMap.TILE + 5.0)
		pilot.position = pilot.pos * GroundMap.SCALE
		pilot.dir = 0
		_lift_open[0] = 1.0
		_arrive = 0.7
	else:
		pilot.dir = 3
	_camera()


const HANGAR_ART := 3.5                 # art px per pixel of the ship's picture in the hangar


func _ship_tex() -> Texture2D:
	var f := GameState.active()
	if f == null:
		return PixelArt.ship_texture("dragonfly", "player")
	return PixelArt.ship_texture(f.hull_id, f.gov if f.gov != "" else f.faction)


## The ship's length and beam in art px (it lies nose to the east).
func _ship_size() -> Vector2:
	var t := _ship_tex()
	if t == null:
		return Vector2(64, 40)
	return Vector2(t.get_width(), t.get_height()) * HANGAR_ART


## Beyond the glass: the system's sky – its nebula, its star, the planet the station circles.
func _space_view(sys_id: int) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = BgShader
	var seed_v := float(sys_id) * 1.37 + 0.5
	var hue := float(sys_id) * 0.137
	mat.set_shader_parameter("seed", seed_v)
	mat.set_shader_parameter("neb_a", Color.from_hsv(fposmod(hue, 1.0), 0.7, 0.85))
	mat.set_shader_parameter("neb_b", Color.from_hsv(fposmod(hue + 0.45, 1.0), 0.6, 0.75))
	mat.set_shader_parameter("neb_strength", 1.1)
	_neb.material = mat
	if sys_id < 0:
		return
	var L := Universe.get_layout(sys_id)
	var star: Dictionary = L["star"]
	# placed beyond the window front (in the window's px) – they drift a little slower than the deck: far away
	var ww := _window.size.x
	var wh := _window.size.y
	var star_at := Vector2(ww * 0.12, wh * 0.38)
	var planet_at := Vector2(ww * 0.58, wh * 0.62)
	var st_spr := Celestial.make_star_sprite(star, 46.0)
	st_spr.position = star_at
	_sky.add_child(st_spr)
	var pi := int(station.get("planet", -1))
	if pi >= 0 and pi < L["planets"].size():
		var p: Dictionary = L["planets"][pi]
		var lit := (star_at - planet_at).normalized()
		var ps := Celestial.make_planet_sprite(p, wh * 0.95, lit)
		ps.position = planet_at
		_sky.add_child(ps)


func _build() -> void:
	# the window: space drawn only behind the glass
	_window = Control.new()
	_window.clip_contents = true
	_window.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var wr := map.window_rect
	_window.position = wr.position * GroundMap.TILE * GroundMap.SCALE
	_window.size = wr.size * GroundMap.TILE * GroundMap.SCALE
	_world.add_child(_window)
	_neb = ColorRect.new()
	_neb.color = Color(0, 0, 0)
	_neb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_neb.set_anchors_preset(Control.PRESET_FULL_RECT)
	_neb.size = _window.size
	_window.add_child(_neb)
	_sky = Node2D.new()
	_window.add_child(_sky)
	# the station goes on round the deck – its structure seen from above, everywhere below the window front's top
	if map.hull_top > -9999:
		_hull = TextureRect.new()
		_hull.texture = map.hull_texture()
		_hull.stretch_mode = TextureRect.STRETCH_TILE
		_hull.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_hull.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var far := 4000.0 / GroundMap.SCALE
		_hull.position = Vector2(-far, map.hull_top * GroundMap.TILE) * GroundMap.SCALE
		_hull.size = Vector2(map.w * GroundMap.TILE + far * 2.0, (map.h - map.hull_top) * GroundMap.TILE + far)
		_hull.scale = Vector2.ONE * GroundMap.SCALE
		_world.add_child(_hull)
		var rim := ColorRect.new()                    # the edge where the station's structure meets space
		rim.color = Color(map.pal["wall_top"]).lightened(0.25)
		rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rim.position = _hull.position
		rim.size = Vector2(_hull.size.x * GroundMap.SCALE, GroundMap.SCALE)
		_world.add_child(rim)
	var spr := Sprite2D.new()
	spr.texture = map.texture()
	spr.centered = false
	spr.scale = Vector2.ONE * GroundMap.SCALE
	_world.add_child(spr)
	# the hangar: your own ship down in the bay, nose to the east, a shadow under it
	if map.ship_at != Vector2.INF:
		var tex := _ship_tex()
		if tex != null:
			var sh := Sprite2D.new()
			sh.texture = tex
			sh.scale = Vector2.ONE * HANGAR_ART * GroundMap.SCALE
			sh.position = (map.ship_at + Vector2(6, 8)) * GroundMap.SCALE
			sh.modulate = Color(0, 0, 0, 0.45)
			_world.add_child(sh)
			_ship_spr = Sprite2D.new()
			_ship_spr.texture = tex
			_ship_spr.scale = Vector2.ONE * HANGAR_ART * GroundMap.SCALE
			_ship_spr.position = map.ship_at * GroundMap.SCALE
			_ship_spr.modulate = Color(0.82, 0.84, 0.9)             # one level down, a little in the shade
			_world.add_child(_ship_spr)
	# the bay is far below: a haze over it, thicker towards the far wall
	if map.bay_rect.size.x > 0.0:
		var g := Gradient.new()
		g.set_color(0, Color(0.03, 0.05, 0.1, 0.62))
		g.set_color(1, Color(0.03, 0.05, 0.1, 0.22))
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.fill_from = Vector2(0, 0)
		gt.fill_to = Vector2(0, 1)
		gt.width = 4
		gt.height = 64
		var haze := TextureRect.new()
		haze.texture = gt
		haze.stretch_mode = TextureRect.STRETCH_SCALE
		haze.mouse_filter = Control.MOUSE_FILTER_IGNORE
		haze.position = map.bay_rect.position * GroundMap.TILE * GroundMap.SCALE
		haze.size = map.bay_rect.size * GroundMap.TILE * GroundMap.SCALE
		_world.add_child(haze)
	# life down in the bay: loaders, repair drones, the fuel truck (0.7.49.10)
	if map.bay_rect.size.x > 0.0 and map.ship_at != Vector2.INF:
		var floor_r := Rect2((map.bay_rect.position + Vector2(0, 2)) * GroundMap.TILE, (map.bay_rect.size - Vector2(0, 2)) * GroundMap.TILE)
		var ssz := _ship_size()
		var life := BayLife.new()
		life.setup(floor_r, Rect2(map.ship_at - ssz * 0.5, ssz), map.pal["accent"], hash(String(station.get("id", ""))))
		life.modulate = Color(0.8, 0.84, 0.92)        # a little in the haze, its lights still bright
		_world.add_child(life)
	_lift_node = Node2D.new()
	_lift_node.draw.connect(_draw_lifts)
	_world.add_child(_lift_node)
	for l in map.lifts:
		_lift_open.append(0.0)
	_sorted = Node2D.new()
	_sorted.y_sort_enabled = true
	_world.add_child(_sorted)
	for o in map.objects:
		var art: Dictionary = ObjArt.make(o, map.pal)
		var img: Image = art["image"]
		var os := Sprite2D.new()
		os.texture = ImageTexture.create_from_image(img)
		os.centered = false
		os.scale = Vector2.ONE * GroundMap.SCALE
		var sdy: float = float(o.get("sort_dy", 0.0)) * GroundMap.TILE        # sorts lower, drawn in the same place
		os.offset = Vector2(0, -img.get_height() - sdy)
		os.position = Vector2(float(o["x"]) * GroundMap.TILE, float(int(o["y"]) + int(o.get("h", 1))) * GroundMap.TILE + sdy) * GroundMap.SCALE
		_sorted.add_child(os)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(station.get("id", ""))) + 49
	for p in map.people:
		var w := Walker.new()
		var lk: Dictionary = p.get("look", {})
		if lk.is_empty():
			lk = ChibiArt.PilotArt.random_look(rng)
		w.setup(map, lk, p["pos"], true)
		w.dir = int(p.get("dir", 0))
		w.sitting = bool(p.get("sit", false))
		if String(p.get("role", "")) in ["bartender", "keeper"]:
			w.stays = true
		if String(p.get("role", "")) == "crew":
			w.marker = "!"
			w.set_meta("crew", int(p.get("crew", -1)))
		_sorted.add_child(w)
		people.append(w)
	var n := 5 + int(station.get("tier", 1)) * 2 if level != "hangar" else 2
	for i in n:
		if map.wander.is_empty():
			break
		var w2 := Walker.new()
		w2.setup(map, ChibiArt.PilotArt.random_look(rng), map.wander[i % map.wander.size()], true)
		_sorted.add_child(w2)
		people.append(w2)
	pilot = Walker.new()
	pilot.setup(map, GameState.pilot.get("look", ChibiArt.PilotArt.default_look()), map.spawn, false)
	_sorted.add_child(pilot)
	# light: lamps, neon, the window – added on top, the deck a little darker round them
	_lights = Node2D.new()
	_lights.z_index = 5
	var add_mat := CanvasItemMaterial.new()
	add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	for l in map.lights:
		_add_light(l, add_mat)
	for z in map.zones:
		var sp: Vector2 = z.get("sign", Vector2(-100, -100))
		if sp.x >= 0.0 and not z.get("vertical", false) and String(z.get("closed", "")) == "":
			_add_light({"pos": sp + Vector2(0, 6), "r": 30.0, "col": z.get("col", Color.WHITE), "a": 0.3}, add_mat)
	_world.add_child(_lights)
	_signs = Node2D.new()
	_signs.z_index = 10
	_signs.draw.connect(_draw_signs)
	_world.add_child(_signs)
	_camera()


static func glow_texture() -> Texture2D:
	if _glow_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.35, Color(1, 1, 1, 0.55))
		g.add_point(0.7, Color(1, 1, 1, 0.15))
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.5)
		gt.fill_to = Vector2(1.0, 0.5)
		gt.width = 128
		gt.height = 128
		_glow_tex = gt
	return _glow_tex


func _add_light(l: Dictionary, mat: Material) -> void:
	var sp := Sprite2D.new()
	sp.texture = glow_texture()
	sp.material = mat
	var r: float = l.get("r", 40.0)
	sp.scale = Vector2(1.0, 0.7) * r * 2.0 * GroundMap.SCALE / 128.0          # pools on the floor: a little flattened
	sp.position = Vector2(l["pos"]) * GroundMap.SCALE
	var a: float = l.get("a", 0.3)
	sp.modulate = Color(Color(l.get("col", Color.WHITE)), a)
	_lights.add_child(sp)
	if l.get("flicker", false):
		_flicker.append([sp, a, randf() * 50.0])


func _process(delta: float) -> void:
	_t += delta
	for f in _flicker:
		var ph: float = f[2]
		var k := 1.0
		if fposmod(_t * 0.7 + ph, 9.0) < 0.18:
			k = 0.35 if fposmod(_t * 31.0, 1.0) < 0.5 else 0.8
		(f[0] as Sprite2D).modulate.a = float(f[1]) * k
	if pilot == null:
		return
	_toast_t = maxf(_toast_t - delta, 0.0)
	if _arrive > 0.0:
		_arrive -= delta
		pilot.step(Vector2.DOWN, delta, 0.8)
	elif not _ride.is_empty():
		_ride_step(delta)
	elif input_enabled and talk == null and _lift_menu == null:
		var dir := Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
		if not _seat.is_empty():
			if dir.length() > 0.3:
				_stand_up()
		else:
			pilot.step(dir, delta, 1.6 if Input.is_action_pressed("boost") else 1.0)
	else:
		pilot.moving = false
	_doors(delta)
	if not _seat.is_empty():
		zone = _seat
	else:
		zone = map.zone_at(pilot.pos)
	if zone.get("kind", "") == "label" or not _ride.is_empty() or talk != null:
		zone = {} if _seat.is_empty() else _seat
	_prompt.text = _toast if _toast_t > 0.0 else ("" if talk != null or talk_menu != null or _lift_menu != null else _prompt_text(zone))
	_camera()
	_signs.queue_redraw()


func _prompt_text(z: Dictionary) -> String:
	if z.is_empty():
		return ""
	var key := Keybinds.key_text("interact")
	match String(z["kind"]):
		"exit", "lift":
			return "[%s] %s" % [key, z["title"]]
		"crew":
			return "[%s] Talk to %s – looking for a post" % [key, z["title"]]
		"seat":
			return "[%s] Stand up" % key if not _seat.is_empty() else "[%s] %s" % [key, z["title"]]
		"jukebox":
			return "[%s] Jukebox – %s" % [key, ("next track (now: %s)" % Jukebox.track_name(track)) if track >= 0 else "play some music"]
	if String(z.get("closed", "")) != "":
		return "%s – closed: %s" % [z["title"], z["closed"]]
	return "[%s] %s%s" % [key, z["title"], ("  –  " + String(z["corp"])) if String(z.get("corp", "")) != "" else ""]


func _unhandled_input(event: InputEvent) -> void:
	if _lift_menu != null:
		if event.is_action_pressed("menu_back", false, true):
			get_viewport().set_input_as_handled()
			_close_lift_menu()
		elif event is InputEventKey and event.is_pressed() and not event.is_echo():
			var k := (event as InputEventKey).keycode
			if k == KEY_1 or k == KEY_2:
				get_viewport().set_input_as_handled()
				_choose_level("hangar" if k == KEY_1 else "commercial")
		return
	if talk_menu != null:
		if event.is_action_pressed("menu_back", false, true):
			get_viewport().set_input_as_handled()
			talk_menu._close()
		return
	if talk != null:
		if event.is_action_pressed("menu_back", false, true):
			get_viewport().set_input_as_handled()
			talk.close()
		return
	if not input_enabled or pilot == null:
		return
	if event.is_action_pressed("interact", false, false):
		get_viewport().set_input_as_handled()
		use()


## Uses what the pilot stands at (also for the smoke test; instant: the lift without its ride).
func use(instant: bool = false) -> bool:
	if not _ride.is_empty() or talk != null or _arrive > 0.0 or _lift_menu != null:
		return false
	if not _seat.is_empty():
		_stand_up()
		return true
	if zone.is_empty() or String(zone.get("closed", "")) != "":
		return false
	match String(zone["kind"]):
		"seat":
			_sit(zone)
			return true
		"jukebox":
			_jukebox()
			return true
		"crew":
			return open_talk(zone)
		"lift":
			if instant:
				return false
			_open_lift_menu(zone)
			return true
		"exit":
			if not instant:
				_start_ride(zone, "", -1)
				return true
	Audio.play("ui_open", "on foot: use")
	used.emit(zone)
	return true


# ---------------------------------------------------------------- 0.7.49.6: lifts, seats, jukebox, crew talk

func _lift_door_pos(i: int) -> Vector2:
	var l: Dictionary = map.lifts[i]
	return Vector2((float(l["x"]) + float(l["w"]) * 0.5) * GroundMap.TILE, (float(l["y"]) + 1.0) * GroundMap.TILE)


## The doors slide open when someone comes close (or the lift is being ridden), and shut again.
func _doors(delta: float) -> void:
	for i in map.lifts.size():
		var dp := _lift_door_pos(i)
		var want := 0.0
		if _arrive > 0.0 and i == _arrive_lift:
			want = 1.0
		elif not _ride.is_empty() and int(_ride["lift"]) == i:
			want = 1.0 if int(_ride["phase"]) < 2 else 0.0
		elif pilot.visible and absf(pilot.pos.x - dp.x) < 18.0 and pilot.pos.y - dp.y < 22.0:
			want = 1.0
		var was: float = _lift_open[i]
		_lift_open[i] = move_toward(was, want, delta * 2.6)
		if was == 0.0 and _lift_open[i] > 0.0:
			Audio.play("ui_open", "on foot: lift doors")
	_lift_node.queue_redraw()


func _draw_lifts() -> void:
	var s := GroundMap.SCALE
	_lift_node.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * s)
	for i in map.lifts.size():
		var l: Dictionary = map.lifts[i]
		var px := float(l["x"]) * GroundMap.TILE
		var py := float(l["y"]) * GroundMap.TILE
		var pw := float(l["w"]) * GroundMap.TILE
		var o: float = _lift_open[i]
		var half := (pw - 6.0) * 0.5
		var dw := roundf(half * (1.0 - o))
		var top := py - 10.0
		var hh := GroundMap.TILE + 7.0
		if dw > 0.0:
			_lift_node.draw_rect(Rect2(px + 3.0, top, dw, hh), Color(0.62, 0.65, 0.7))
			_lift_node.draw_rect(Rect2(px + 3.0, top, 1.0, hh), Color(0.75, 0.78, 0.82))
			_lift_node.draw_rect(Rect2(px + 3.0 + dw - 1.0, top, 1.0, hh), Color(0.4, 0.42, 0.46))
			_lift_node.draw_rect(Rect2(px + pw - 3.0 - dw, top, dw, hh), Color(0.56, 0.59, 0.64))
			_lift_node.draw_rect(Rect2(px + pw - 3.0 - dw, top, 1.0, hh), Color(0.3, 0.32, 0.36))
		# the lamp over the doors: green when open
		var lc := Color(0.4, 1.0, 0.6) if o > 0.5 else Color(1.0, 0.6, 0.25)
		_lift_node.draw_rect(Rect2(px + pw * 0.5 - 2.0, py - 14.0, 4.0, 1.0), lc)
	_lift_node.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The lift's little panel: which level?
func _open_lift_menu(z: Dictionary) -> void:
	Audio.play("ui_open", "on foot: lift panel")
	var c := CenterContainer.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(c)
	var p := UI.neon_panel(Color(0.4, 1.0, 0.6, 0.85), Color(0.03, 0.05, 0.06, 0.96), 2)
	p.custom_minimum_size = Vector2(380, 0)
	c.add_child(p)
	var v := UI.vbox(8)
	p.add_child(v)
	v.add_child(UI.label("LIFT", 20, Color(0.4, 1.0, 0.6)))
	v.add_child(UI.label("Which level?", 13, UI.TEXT_DIM))
	for lv in [["hangar", "1.  Hangar – your ship"], ["commercial", "2.  Commercial level – shops and the bar"]]:
		var here: bool = lv[0] == level
		var b := UI.button(String(lv[1]) + ("   (you are here)" if here else ""), func(): _choose_level(String(lv[0])))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = here
		v.add_child(b)
	v.add_child(UI.button("Cancel [Esc]", _close_lift_menu))
	_lift_menu = c
	_lift_menu.set_meta("zone", z)


func _close_lift_menu() -> void:
	if _lift_menu != null:
		_lift_menu.queue_free()
	_lift_menu = null


func _choose_level(target: String) -> void:
	if _lift_menu == null:
		return
	var z: Dictionary = _lift_menu.get_meta("zone", {})
	_close_lift_menu()
	if target != level:
		_start_ride(z, target)


## Into a lift (and on to another level), or down the stairs to the ship (lift -1).
func _start_ride(z: Dictionary, target: String = "", lift: int = -2) -> void:
	var best := 0
	if lift == -2:
		for i in map.lifts.size():
			if absf(_lift_door_pos(i).x - pilot.pos.x) < absf(_lift_door_pos(best).x - pilot.pos.x):
				best = i
	else:
		best = lift
	_ride = {"lift": best, "zone": z, "phase": 0, "t": 0.0, "target": target}


## Into the lift: walk to the doors, step in, the doors close, then the other level (or back to the ship).
func _ride_step(delta: float) -> void:
	_ride["t"] = float(_ride["t"]) + delta
	var dp: Vector2
	if int(_ride["lift"]) >= 0:
		dp = _lift_door_pos(int(_ride["lift"])) + Vector2(0, 5)
	else:
		var zr: Rect2 = (_ride["zone"] as Dictionary)["rect"]
		dp = Vector2(zr.position.x + 8.0, zr.get_center().y)
	match int(_ride["phase"]):
		0:
			var to := dp - pilot.pos
			if to.length() < 3.0 or float(_ride["t"]) > 1.6:
				_ride["phase"] = 1
				_ride["t"] = 0.0
			else:
				if not pilot.step(to.normalized(), delta, 1.0):
					pilot.pos += to.normalized() * minf(to.length(), Walker.SPEED * delta)
					pilot.position = pilot.pos * GroundMap.SCALE
		1:
			pilot.dir = 0
			pilot.modulate.a = maxf(0.0, 1.0 - float(_ride["t"]) / 0.35)
			if float(_ride["t"]) > 0.35:
				pilot.visible = false
				_ride["phase"] = 2
				_ride["t"] = 0.0
		2:
			if float(_ride["t"]) > (0.6 if int(_ride["lift"]) >= 0 else 0.15):
				var z: Dictionary = _ride["zone"]
				var target := String(_ride.get("target", ""))
				_ride["phase"] = 3
				if target != "":
					go_level(target, "lift")
				else:
					used.emit(z)


func _sit(z: Dictionary) -> void:
	_stand_pos = pilot.pos
	_seat = z
	pilot.pos = z["seat"]
	pilot.position = pilot.pos * GroundMap.SCALE
	pilot.dir = int(z.get("dir", 0))
	pilot.sitting = true
	pilot.moving = false


func _stand_up() -> void:
	_seat = {}
	pilot.sitting = false
	pilot.pos = _stand_pos
	pilot.position = pilot.pos * GroundMap.SCALE


func is_sitting() -> bool:
	return not _seat.is_empty()


## The jukebox: the next track, and after the last one quiet again.
func _jukebox() -> void:
	track += 1
	if track >= Jukebox.TRACKS.size():
		track = -1
		_music.stop()
		_toast = "The jukebox falls silent."
	else:
		_music.stream = Jukebox.stream(track)
		_music.play()
		_toast = "♪  Now playing: %s" % Jukebox.track_name(track)
	_toast_t = 2.5


## Talking to someone looking for a post – a conversation with just them.
func open_talk(z: Dictionary) -> bool:
	var offers: Array = GameState.bar_offers(station)
	var i := int(z.get("crew", -1))
	if i < 0 or i >= offers.size():
		return false
	Audio.play("ui_open", "on foot: talk")
	_talk_offer = offers[i]
	_talk_index = i
	_talk_hired = false
	var m: Dictionary = _talk_offer["m"]
	var q := String(m["quality"])
	talk = DialogueView.new()
	_ui.add_child(talk)
	talk.open(m.get("look", {}), String(m["name"]), "%s · %s %s" % [CrewTalk.CrewData.role_name(String(m["role"])), q,
		CrewTalk.CrewData.QUALITY_NAMES.get(q, "")], CrewTalk.CrewData.QUALITY_COLORS.get(q, UI.NEON_CYAN))
	talk.closed.connect(func(): talk = null)
	talk.say(CrewTalk.greeting(m), _talk_options())
	for w in people:
		if is_instance_valid(w) and w.has_meta("crew") and int(w.get_meta("crew")) == i:
			w.dir = 0 if pilot.pos.y > w.pos.y else 1
	return true


func _talk_options() -> Array:
	if _talk_hired:
		return [["Goodbye.", func(): talk.close()]]
	return [["Info – tell me about yourself.", talk_info], ["Goodbye.", func(): talk.close()]]


## "Info": the questions about trade, skill and price, the record, signing on.
func talk_info() -> void:
	if talk == null or talk_menu != null:
		return
	talk.visible = false
	talk_menu = CrewTalk.new()
	_ui.add_child(talk_menu)
	talk_menu.setup(_talk_offer, _talk_index)
	talk_menu.hired.connect(func(idx: int):
		_talk_hired = true
		_on_hired(idx))
	talk_menu.closed.connect(func():
		talk_menu = null
		if talk != null:
			talk.visible = true
			talk.say("See you aboard, captain." if _talk_hired else "Anything else, captain?", _talk_options()))


## Hired: that one heads for the lift; the others' places in the bar's list move up.
func _on_hired(idx: int) -> void:
	for z in map.zones.duplicate():
		if z["kind"] == "crew":
			if int(z["crew"]) == idx:
				map.zones.erase(z)
			elif int(z["crew"]) > idx:
				z["crew"] = int(z["crew"]) - 1
	for w in people:
		if not is_instance_valid(w) or not w.has_meta("crew"):
			continue
		var c := int(w.get_meta("crew"))
		if c == idx:
			w.marker = ""
			w.remove_meta("crew")
			w.leave_to = _lift_door_pos(0) + Vector2(0, 5) if not map.lifts.is_empty() else map.spawn
		elif c > idx:
			w.set_meta("crew", c - 1)


## Puts the pilot at a zone (debug, smoke test).
func walk_to_zone(id: String) -> bool:
	for z in map.zones:
		if String(z.get("id", "")) == id and z["kind"] != "label":
			var r: Rect2 = z["rect"]
			for k in 60:
				var p := r.position + Vector2(randf(), randf()) * r.size
				if map.free_at(p, Walker.RADIUS):
					pilot.pos = p
					pilot.position = p * GroundMap.SCALE
					zone = z
					_arrive = 0.0
					return true
	return false


func _camera() -> void:
	var vs := get_viewport().get_visible_rect().size
	var mp := map.size_px() * GroundMap.SCALE
	var c := pilot.position + Vector2(0, -24)
	var off := vs * 0.5 - c
	if mp.x > vs.x:
		off.x = clampf(off.x, vs.x - mp.x, 0.0)
	else:
		off.x = (vs.x - mp.x) * 0.5
	if mp.y > vs.y:
		off.y = clampf(off.y, vs.y - mp.y, 0.0)
	else:
		off.y = (vs.y - mp.y) * 0.5
	_world.position = off.round()
	# space beyond the glass moves only a little – it is far away
	if _off0 == null:
		_off0 = off
	_sky.position = (-(off - (_off0 as Vector2)) * 0.9).round()
	var m := _neb.material as ShaderMaterial
	if m != null:
		m.set_shader_parameter("offset", -off * 0.3)


const _GLOW_OFFS := [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(0, 2), Vector2(-1, -1), Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1)]


## Neon: a soft halo in the tube's colour, a bright core near white.
func _neon_text(font: Font, p: Vector2, txt: String, size: int, c: Color, k: float) -> void:
	for o in _GLOW_OFFS:
		_signs.draw_string(font, p + o * 1.5, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(c, 0.16 * k))
	for o2 in _GLOW_OFFS:
		_signs.draw_string(font, p + o2 * 0.6, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(c, 0.3 * k))
	_signs.draw_string(font, p, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(c.lerp(Color.WHITE, 0.55), 0.6 + 0.4 * k))


func _neon_rect(r: Rect2, c: Color, k: float) -> void:
	_signs.draw_rect(r.grow(2), Color(c, 0.12 * k), false, 6.0)
	_signs.draw_rect(r, Color(c, 0.45 * k), false, 3.0)
	_signs.draw_rect(r, Color(c.lerp(Color.WHITE, 0.5), 0.5 + 0.5 * k), false, 1.0)


## How lit a neon is now: mostly steady, now and then a stutter.
func _flick(seed_v: float) -> float:
	if fposmod(_t * 0.6 + seed_v, 11.0) < 0.22:
		return 0.25 if fposmod(_t * 27.0, 1.0) < 0.5 else 0.9
	return 0.92 + 0.08 * sin(_t * 3.0 + seed_v)


## Neon shop signs mounted on the wall over the doors, the bar's tall neon sign, holographic adverts over the
## corridor wall, a glow where the pilot stands.
func _draw_signs() -> void:
	var font := ThemeDB.fallback_font
	var s := GroundMap.SCALE
	for h in map.holos:
		_draw_holo(font, h)
	for z in map.zones:
		var sp: Vector2 = z.get("sign", Vector2(-100, -100))
		if sp.x < 0.0:
			continue
		var c: Color = z.get("col", Color.WHITE)
		var k := _flick(sp.x * 0.13)
		if z.get("vertical", false):
			var letters: String = String(z["title"])
			var y := sp.y * s
			var box := Rect2(Vector2(sp.x * s - 20, y - 8), Vector2(40, letters.length() * 36 + 14))
			_signs.draw_rect(box, Color(0.03, 0.02, 0.05, 0.92))
			_neon_rect(box.grow(-4), Color(0.3, 0.95, 1.0), _flick(3.3))
			for i in letters.length():
				var ch := letters.substr(i, 1)
				var cw := font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
				var lk := k if i != 1 else _flick(7.7)
				_neon_text(font, Vector2(sp.x * s - cw * 0.5, y + 30 + i * 36), ch, 30, c, lk)
			continue
		var txt: String = String(z["title"]).to_upper()
		var closed := String(z.get("closed", "")) != ""
		if closed:
			txt += " · CLOSED"
			c = Color(0.45, 0.45, 0.5)
			k = 0.15
		var size := 15
		var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var p: Vector2 = sp * s - Vector2(tw * 0.5, -2)
		var plate := Rect2(p + Vector2(-10, -size - 3), Vector2(tw + 20, size + 11))
		# two brackets into the wall, a dark backing plate, the neon tube text and frame
		_signs.draw_rect(Rect2(plate.position + Vector2(8, -6), Vector2(3, 6)), Color(0.1, 0.1, 0.12))
		_signs.draw_rect(Rect2(plate.end - Vector2(11, plate.size.y + 6), Vector2(3, 6)), Color(0.1, 0.1, 0.12))
		_signs.draw_rect(plate, Color(0.02, 0.02, 0.04, 0.9))
		_neon_rect(plate.grow(-3), c, k * 0.8)
		_neon_text(font, p, txt, size, c, k)
	if not zone.is_empty() and zone["kind"] in ["service", "exit"] and zone["rect"].size.x > 0.0:
		var r: Rect2 = zone["rect"]
		_signs.draw_rect(Rect2(r.position * s, r.size * s), Color(1.0, 0.85, 0.35, 0.07 + 0.04 * sin(_t * 4.0)))


## A holographic advert hovering over the corridor wall: see-through, scan lines, now and then a jolt.
func _draw_holo(font: Font, h: Dictionary) -> void:
	var s := GroundMap.SCALE
	var c: Color = h["col"]
	var base: Vector2 = Vector2(h["pos"]) * s
	var k := _flick(base.x * 0.07)
	var jolt := 0.0
	if fposmod(_t * 0.9 + base.x * 0.01, 7.0) < 0.12:
		jolt = 5.0 * sin(_t * 90.0)
	var t1: String = h["text"]
	var t2: String = h["sub"]
	var w1 := font.get_string_size(t1, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	var w2 := font.get_string_size(t2, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	var bw := maxf(w1, w2) + 22.0
	var r := Rect2(base + Vector2(-bw * 0.5 + jolt, -62), Vector2(bw, 46))
	# the projector on the wall and its beam
	_signs.draw_rect(Rect2(base + Vector2(-8, -6), Vector2(16, 6)), Color(0.08, 0.08, 0.1))
	_signs.draw_rect(Rect2(base + Vector2(-2, -5), Vector2(4, 2)), Color(c, 0.9))
	_signs.draw_colored_polygon(PackedVector2Array([base + Vector2(-3, -5), base + Vector2(3, -5), r.end - Vector2(0, 0), Vector2(r.position.x, r.end.y)]), Color(c, 0.07 * k))
	_signs.draw_rect(r, Color(c, 0.22 * k))
	var yy := r.position.y + fposmod(_t * 20.0, 3.0)
	while yy < r.end.y:
		_signs.draw_line(Vector2(r.position.x, yy), Vector2(r.end.x, yy), Color(c, 0.1 * k), 1.0)
		yy += 3.0
	_signs.draw_rect(r, Color(c, 0.85 * k), false, 2.0)
	_signs.draw_string(font, Vector2(r.position.x + (bw - w1) * 0.5, r.position.y + 20), t1, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(c.lerp(Color.WHITE, 0.6), k))
	_signs.draw_string(font, Vector2(r.position.x + (bw - w2) * 0.5, r.position.y + 37), t2, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(c.lerp(Color.WHITE, 0.3), 0.9 * k))
