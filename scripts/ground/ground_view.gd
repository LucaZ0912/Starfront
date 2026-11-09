class_name GroundView
extends CanvasLayer
## Package 49: on foot – a walkable place drawn over the space view (which keeps running below). The pilot walks with
## WASD (Shift runs), E uses what is in front of him: a shop door opens its window, the airlock leads back to the ship.
## Built from a GroundMap; the first places are station decks (DeckGen).

signal used(zone: Dictionary)

const LAYER := 12
const PilotArt = preload("res://scripts/core/pilot_art.gd")

var map: GroundMap
var station: Dictionary = {}
var pilot: Walker
var people: Array = []
var input_enabled := true
var zone: Dictionary = {}
var _world: Node2D
var _signs: Node2D
var _prompt: Label
var _title: Label
var _t := 0.0


func _ready() -> void:
	layer = LAYER
	var bg := ColorRect.new()
	bg.color = Color(0.01, 0.012, 0.03)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	_world = Node2D.new()
	add_child(_world)
	var ui := Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	_title = UI.label("", 18, UI.NEON_CYAN)
	_title.position = Vector2(24, 18)
	ui.add_child(_title)
	var hint := UI.label("", 12, UI.TEXT_DIM)
	hint.position = Vector2(24, 46)
	hint.text = "%s %s %s %s walk  •  %s run  •  %s use  •  back to the ship through the airlock" % [
		Keybinds.key_text("walk_up"), Keybinds.key_text("walk_left"), Keybinds.key_text("walk_down"), Keybinds.key_text("walk_right"),
		Keybinds.key_text("boost"), Keybinds.key_text("interact")]
	ui.add_child(hint)
	_prompt = UI.label("", 18, UI.GOLD)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.offset_top = -90
	_prompt.offset_bottom = -60
	_prompt.offset_left = -400
	_prompt.offset_right = 400
	ui.add_child(_prompt)


## A station's deck: available = service id -> "" or the reason it is closed.
func setup_station(p_station: Dictionary, available: Dictionary) -> void:
	station = p_station
	map = DeckGen.build(station, available)
	_build()
	_title.text = "%s – %s" % [map.title, "Promenade"]


func _build() -> void:
	var spr := Sprite2D.new()
	spr.texture = map.texture()
	spr.centered = false
	spr.scale = Vector2.ONE * GroundMap.SCALE
	_world.add_child(spr)
	_add_docked_ship()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(station.get("id", ""))) + 49
	# the people who stay put (bartender, shopkeepers, guests) and some who stroll about
	for p in map.people:
		var w := Walker.new()
		w.setup(map, PilotArt.random_look(rng), p["pos"], true)
		w.facing = float(p.get("facing", 0.0))
		w.sitting = true                              # they keep their place
		_world.add_child(w)
		people.append(w)
	var n := 4 + int(station.get("tier", 1)) * 2
	for i in n:
		if map.wander.is_empty():
			break
		var w2 := Walker.new()
		w2.setup(map, PilotArt.random_look(rng), map.wander[i % map.wander.size()], true)
		_world.add_child(w2)
		people.append(w2)
	pilot = Walker.new()
	pilot.setup(map, GameState.pilot.get("look", PilotArt.default_look()), map.spawn, false)
	_world.add_child(pilot)
	_signs = Node2D.new()
	_signs.z_index = 5
	_signs.draw.connect(_draw_signs)
	_world.add_child(_signs)
	_camera()


## Your ship outside the airlock window, nose to the hatch (ship pixels ×4 art px – a person is 16).
func _add_docked_ship() -> void:
	var f := GameState.active()
	if f == null or map.dock_at == Vector2.INF:
		return
	var tex := PixelArt.ship_texture(f.hull_id, "player")
	var k := 4.0 * GroundMap.SCALE
	var size := Vector2(tex.get_width(), tex.get_height()) * k
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.centered = false
	spr.scale = Vector2.ONE * k
	spr.position = map.dock_at * GroundMap.SCALE - Vector2(size.x, size.y * 0.5)
	_world.add_child(spr)
	var tube := ColorRect.new()
	tube.color = Color(0.45, 0.48, 0.55)
	tube.position = map.dock_at * GroundMap.SCALE - Vector2(4, 22)
	tube.size = Vector2(GroundMap.TILE * GroundMap.SCALE * 0.5 + 6, 44)
	_world.add_child(tube)


func _process(delta: float) -> void:
	_t += delta
	if pilot == null:
		return
	if input_enabled:
		var dir := Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
		pilot.step(dir, delta, 1.6 if Input.is_action_pressed("boost") else 1.0)
	else:
		pilot.moving = false
	zone = map.zone_at(pilot.pos)
	if zone.get("kind", "") == "label":
		zone = {}
	_prompt.text = _prompt_text(zone)
	_camera()
	_signs.queue_redraw()


func _prompt_text(z: Dictionary) -> String:
	if z.is_empty():
		return ""
	var key := Keybinds.key_text("interact")
	if z["kind"] == "exit":
		return "[%s] Back to your ship" % key
	if String(z.get("closed", "")) != "":
		return "%s – closed: %s" % [z["title"], z["closed"]]
	return "[%s] %s%s" % [key, z["title"], ("  –  " + String(z["corp"])) if String(z.get("corp", "")) != "" else ""]


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled or pilot == null:
		return
	if event.is_action_pressed("interact", false, false):
		get_viewport().set_input_as_handled()
		use()


## Uses what the pilot stands at (also for the smoke test).
func use() -> bool:
	if zone.is_empty() or String(zone.get("closed", "")) != "":
		return false
	Audio.play("ui_open", "on foot: use")
	used.emit(zone)
	return true


## Puts the pilot at a zone (debug, smoke test).
func walk_to_zone(id: String) -> bool:
	for z in map.zones:
		if String(z.get("id", "")) == id and z["kind"] != "label":
			var r: Rect2 = z["rect"]
			for k in 40:
				var p := r.position + Vector2(randf(), randf()) * r.size
				if map.free_at(p, Walker.RADIUS):
					pilot.pos = p
					pilot.position = p * GroundMap.SCALE
					zone = map.zone_at(p)
					return true
	return false


func _camera() -> void:
	var vs := get_viewport().get_visible_rect().size
	var mp := map.size_px() * GroundMap.SCALE
	var c := pilot.position
	var off := vs * 0.5 - c
	# keep the map on the screen where it is bigger than the screen, centre it where it is smaller
	if mp.x > vs.x:
		off.x = clampf(off.x, vs.x - mp.x, 0.0)
	else:
		off.x = (vs.x - mp.x) * 0.5
	if mp.y > vs.y:
		off.y = clampf(off.y, vs.y - mp.y, 0.0)
	else:
		off.y = (vs.y - mp.y) * 0.5
	_world.position = off.round()


## Shop signs over the doors (crisp text in screen pixels), a glow at the door the pilot stands at.
func _draw_signs() -> void:
	var font := ThemeDB.fallback_font
	var s := GroundMap.SCALE
	for z in map.zones:
		var c: Color = z.get("col", Color.WHITE)
		var txt: String = String(z["title"]).to_upper()
		if String(z.get("closed", "")) != "":
			txt += " · CLOSED"
			c = Color(0.55, 0.55, 0.6)
		var size := 13 if z["kind"] != "service" or not DeckGen.DOCK_TERMINALS.has(String(z["id"])) else 10
		var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var p: Vector2 = (z["sign"] as Vector2) * s - Vector2(tw * 0.5, 0)
		var glow: float = 0.75 + 0.25 * sin(_t * 2.0 + p.x * 0.01)
		_signs.draw_rect(Rect2(p + Vector2(-6, -size), Vector2(tw + 12, size + 6)), Color(0.02, 0.03, 0.06, 0.8))
		_signs.draw_rect(Rect2(p + Vector2(-6, -size), Vector2(tw + 12, size + 6)), Color(c, 0.6 * glow), false, 1.5)
		_signs.draw_string(font, p, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(c, glow))
	if not zone.is_empty() and zone["kind"] != "label":
		var r: Rect2 = zone["rect"]
		_signs.draw_rect(Rect2(r.position * s, r.size * s), Color(1.0, 0.85, 0.35, 0.10 + 0.05 * sin(_t * 4.0)))
