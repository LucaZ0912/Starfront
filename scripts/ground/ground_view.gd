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
var _log: RichTextLabel = null           # 0.7.52.13: the event log on the right
var _toast_t := 0.0
var level := ""                         # 0.7.49.8: "hangar" or "commercial"
var _avail: Dictionary = {}
var _crew: Array = []
var _sys := -1
var _lift_menu: Control = null
var _ship_spr: Sprite2D
var _body: Dictionary = {}              # package 50: landed – the body and the site
var _lander := false                    # 0.7.50.4: down by the landing drone (small places), not the ship
var _ship_shadow: Sprite2D
var _touch := -1.0                      # 0.7.50.3: the touchdown under way (seconds), -1: none
var _ship_base := Vector2.ZERO
var _dust: Node2D
var _puffs: Array = []                  # [pos, vel, life, size]
var _shake := 0.0
const TOUCH_TIME := 2.4
const LIFT_TIME := 2.2
var _site: Dictionary = {}
var talk: DialogueView = null          # a conversation (0.7.49.7: after Luz's mockup)
var _hangar_uid := -1
var _star_spr: Node2D = null            # 0.7.49.14: kept in the visible part of the window front
var _planet_spr: Node2D = null
var _cam_c := Vector2.INF               # where the camera looks (screen px of the world), eased                   # 0.7.49.13: whose hangar this is (the active ship when it was built)
var _bartender: Walker = null
var _skyline: CitySkyline = null        # 0.7.50.5: the view from a city's tower bar
var _canyon: CityCanyon = null          # 0.7.50.6: the street canyon
var _tint: ColorRect = null             # 0.7.50.8: the street's light (night darker, dusk warm)
var _city_lights: Array = []            # [sprite, light, kind] – lights that follow the time of day
var _city_body: Dictionary = {}
var _day_t := 0.0
var _day_seen := -1.0                   # the daylight the view was last drawn in
var talk_menu: CrewTalk = null          # its "Info": the questions, the record, signing on
var _talk_offer := {}
var _talk_index := -1
var _talk_hired := false
var _hint: Label
var _hatch := 0.0                       # 0.7.50.15: the landing drone's ramp – 0 shut … 1 down
var _hatch_node: Node2D = null
const HATCH_TIME := 0.85
var env: Dictionary = {}                # 0.7.51.3: the world outside ({} on a station's or city's deck)
var hud: SuitHud = null
var _collapsed := false
var combat: GroundCombat = null         # package 52: the fight on foot (where weapons are allowed)
var combat_hud: CombatHud = null
var zoom := 1.0                         # 0.7.52.8: the camera's zoom (1 = as always)
var tac_zoom := 1.0                     # the tactical view's zoom: TAC_ZOOM_OUT, 1 or ZOOM_NEAR, kept for next time
var near_zoom := 1.0                    # 0.7.52.13 (Luz): in a fight also closer – 1 or ZOOM_NEAR
const TAC_ZOOM_OUT := 0.5
const ZOOM_NEAR := 1.5
var _tab_held := -1.0                   # 0.7.52.2: how long Tab is held (-1: up) – a tap switches the view, holding ends it
const TAB_HOLD := 0.35
const ExploreNode = preload("res://scripts/ground/explore.gd")
const VaultGen = preload("res://scripts/ground/vault_gen.gd")
const DroneBuddy = preload("res://scripts/ground/drone_buddy.gd")
const DungeonGen = preload("res://scripts/ground/dungeon_gen.gd")
const PoiData = preload("res://data/poi.gd")
const FogNode = preload("res://scripts/ground/fog.gd")
var _poi_cache := {}                     # 0.7.53.2: the site's two maps while you are there (outside, inside – their state kept)
var fog: Node2D = null
var depth := 0                            # 0.7.53.3: the level of a site you are on (0 the top)
var _city_site = null                     # 0.7.53.3: in a city, the site before the alley's sewers took its place
var _wires_t := {}
var _sink := {}
var _dark_rect: ColorRect = null           # 0.7.53.6: the level's darkness (the generator's power can change it)
var _haz_t := {}                          # 0.7.53.6: hazards' cool-downs (shock conduits)
var _fuses := {}
var _town_kind := ""
var _hostage := {}
var _out_env := {}                         # 0.7.53.20: a station's world outside – it comes in through a torn module
var _socket := -1                          # 0.7.53.16: the power socket you charge at (explore index), -1 none                        # 53c (Luz): the prisoner you rescue – {look, hp, w (Walker)}                      # 0.7.53.9: in a city, the way down taken – "" (the alley's sewers) or "maint"
var _drone_fx: Node2D = null              # 0.7.53.9: the maintenance drones drawn
var _rep_spots: Array = []                # 0.7.53.9: where on the walls they mend things                          # 0.7.53.7: charges and explosives about to go up – index -> seconds
const WreckShader = preload("res://shaders/wreck.gdshader")
const ParkedArt = preload("res://scripts/ground/parked_art.gd")                           # 0.7.53.4: riding the ancient lift – {"d", "t", "dir"}                        # 0.7.53.3: tripwires set off – index -> seconds to the blast
var _mm: Control = null                  # package 53a: the minimap of a site (what you have seen)
var _mm_img: Image = null
var _mm_tex: ImageTexture = null
var _mm_tile := Vector2i(-99, -99)
var poi_seen: PackedByteArray = PackedByteArray()
var buddy: Node2D = null                 # 0.7.52.25: your drones where there is no fight
const CutGame = preload("res://scripts/ground/cut_game.gd")
const HackGame = preload("res://scripts/ground/hack_game.gd")
var _named_lights := {}
var minigame: Control = null             # 0.7.52.22: the cutting torch or the hack, while it is open
var _game_layer: CanvasLayer = null
var _scan: Dictionary = {}               # 0.7.52.24: a scan running {i, t, need, key}
var _team_held := -1.0                  # 0.7.52.20: how long V is held (-1: up) – a tap picks whom, holding opens the wheel
var _revive := -1.0                     # 0.7.52.20: how long the use key is held beside a member down (-1: not)
const WHEEL_SLOW := 0.3                 # time runs at this pace while the command wheel is up
var _drone_held: Array = [-1.0, -1.0]   # 0.7.52.19: how long C / Shift+C is held over a kamikaze drone in the air (-1: up)
var _warned := {}


func _ready() -> void:
	layer = LAYER
	_space = ColorRect.new()                        # everything that is neither deck nor window: black
	_space.color = Color(0, 0, 0)
	_space.set_anchors_preset(Control.PRESET_FULL_RECT)
	_space.mouse_filter = Control.MOUSE_FILTER_STOP
	_space.gui_input.connect(_on_click)                # package 52: a click on a foe locks it
	add_child(_space)
	_world = Node2D.new()
	add_child(_world)
	var ui := Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	ui.z_index = 50                                 # above the neon signs (z 10) – talks and panels stay readable
	_ui = ui
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	_music.volume_db = -6.0
	add_child(_music)
	var plate := ColorRect.new()                    # 0.7.50.6: a dark plate behind the title – readable over a sunlit street
	plate.color = Color(0.0, 0.0, 0.03, 0.55)
	plate.position = Vector2(14, 12)
	plate.size = Vector2(540, 56)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(plate)
	_title = UI.label("", 18, UI.NEON_CYAN)
	_title.position = Vector2(24, 18)
	ui.add_child(_title)
	var hint := UI.label("", 12, UI.TEXT_DIM)
	hint.position = Vector2(24, 46)
	ui.add_child(hint)
	_hint = hint
	_set_hint()
	_prompt = UI.label("", 18, UI.GOLD)
	_prompt.add_theme_constant_override("outline_size", 7)             # 0.7.50.11: readable on snow and sand
	_prompt.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.05, 0.9))
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.offset_top = -90
	_prompt.offset_bottom = -60
	_prompt.offset_left = -500
	_prompt.offset_right = 500
	ui.add_child(_prompt)
	# 0.7.52.13 (Luz): the events on the right, as in space – what used to pop up in the middle
	var log_panel := UI.panel(Color(0.03, 0.05, 0.09, 0.8))
	log_panel.anchor_left = 1
	log_panel.anchor_right = 1
	log_panel.anchor_top = 1
	log_panel.anchor_bottom = 1
	log_panel.offset_left = -470
	log_panel.offset_right = -10
	log_panel.offset_top = -195
	log_panel.offset_bottom = -10
	log_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(log_panel)
	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_log.add_theme_font_size_override("normal_font_size", 12)
	log_panel.add_child(_log)
	GameState.message.connect(log_event)                 # a bound method: let go of when the view is freed
	hud = SuitHud.new()                             # 0.7.51.3: the suit's bars, the hazards, the belt
	ui.add_child(hud)
	combat_hud = CombatHud.new()                    # package 52
	combat_hud.suit_hud = hud
	ui.add_child(combat_hud)


## The line under the title: how to walk – and the way back (0.7.50.15: by the place you are in).
func _set_hint() -> void:
	if _hint == null:
		return
	var back := "the stairs in the hangar lead back to your ship"
	if level in ["landing", "settlement"] and _lander:
		back = "the landing drone's ramp takes you back up"
	elif level == "landing":
		back = "her ramp takes you back aboard"
	elif is_city():
		back = "the lifts lead to the hangar – your ship and the way up"
	_hint.text = "%s %s %s %s walk  •  %s run  •  %s use / talk  •  %s" % [
		Keybinds.key_text("walk_up"), Keybinds.key_text("walk_left"), Keybinds.key_text("walk_down"), Keybinds.key_text("walk_right"),
		Keybinds.key_text("foot_run"), Keybinds.key_text("interact"), back]
	if combat_allowed():
		_hint.text = "%s %s %s %s walk  •  %s next target / click  •  %s dodge  •  %s other weapon  •  %s tactics  •  1–4 belt" % [
			Keybinds.key_text("walk_up"), Keybinds.key_text("walk_left"), Keybinds.key_text("walk_down"), Keybinds.key_text("walk_right"),
			Keybinds.key_text("foot_target"), Keybinds.key_text("foot_dodge"), Keybinds.key_text("foot_swap"), Keybinds.key_text("foot_tactics")]


## A station's deck: available = service id -> "" or the reason it is closed; crew = the bar's offers.
## You start in the hangar, at the stairs up from your ship.
func setup_station(p_station: Dictionary, available: Dictionary, crew: Array = [], sys_id: int = -1) -> void:
	station = p_station
	_avail = available
	_crew = crew
	_sys = sys_id
	go_level("hangar", "stairs")


## Package 50: on a planet – the landing field at a site, your ship on the pad.
func setup_landing(p_body: Dictionary, p_site: Dictionary, sys_id: int = -1, touchdown: bool = false, by_lander: bool = false) -> void:
	_lander = by_lander
	_body = p_body
	_site = p_site
	station = {"id": String(p_site.get("id", "")), "name": String(p_site.get("name", ""))}
	_avail = {}
	_crew = []
	_sys = sys_id
	go_level("landing", "touchdown" if touchdown else "ramp")


## 0.7.50.10: a settlement – down by the landing drone on its first pad.
func setup_settlement(p_body: Dictionary, p_site: Dictionary, town: Dictionary, available: Dictionary, crew: Array, sys_id: int, touchdown: bool = false) -> void:
	_lander = true
	_body = p_body
	_site = p_site
	station = town
	_avail = available
	_crew = crew
	_sys = sys_id
	go_level("settlement", "touchdown" if touchdown else "ramp")


## Goes to a level of the station – "hangar" or "commercial"; arrive: "stairs" (at the hangar's stairs), "lift" (out
## of a lift, the doors opening).
func go_level(p_level: String, arrive: String = "lift") -> void:
	if map != null and _mm != null and map.has_meta("poi"):
		map.set_meta("seen", poi_seen)                  # 0.7.53.3: the minimap of the level you leave stays
	for c in _world.get_children():
		_world.remove_child(c)
		c.queue_free()
	people.clear()
	_bartender = null
	_lift_open.clear()
	_flicker.clear()
	_seat = {}
	_ride = {}
	_off0 = null
	_star_spr = null
	_planet_spr = null
	_skyline = null
	_canyon = null
	_hatch_node = null
	_tint = null
	_city_lights.clear()
	_cam_c = Vector2.INF
	zone = {}
	_arrive = 0.0
	_ship_spr = null
	_ship_shadow = null
	_touch = -1.0
	_puffs.clear()
	_dust = null
	if combat != null and is_instance_valid(combat):
		combat.leave()                                   # 0.7.52.20: who is still down there dies there
		if map != null and map.has_meta("foes"):
			var dd: Array = map.get_meta("dead", [])
			for f0 in combat.foes:
				if f0["dead"] and f0.has("spawn_i") and not dd.has(int(f0["spawn_i"])):
					dd.append(int(f0["spawn_i"]))
			map.set_meta("dead", dd)
	combat = null
	if pilot != null and is_instance_valid(pilot):
		pilot.aim = Vector2.INF
	level = p_level
	if is_town():
		# 0.7.53.3 (Luz): the back alley and the sewers below it are the city's site to explore; 0.7.53.7: a
		# settlement's is the old mine at its edge
		if level in ["alley", "dungeon", "minehead", "plaza"]:
			# 0.7.53.19: straight from one of the city's sites to another (the alley's lift up to the plaza) – the city first
			var want := "maint" if is_city() and _town_kind == "maint" else ("corp" if is_city() and _town_kind == "corp" else ("sewer" if is_city() else "mine"))
			if bool(_site.get("poi", false)) and String(_site.get("theme", "")) != want and _city_site != null:
				_site = _city_site
				_city_site = null
			if not bool(_site.get("poi", false)):
				_city_site = _site
				if is_city() and _town_kind == "corp":
					var cs0 := GameState.corp_site_for(String(station.get("id", "")))         # 0.7.53.19 (or a job's)
					_site = cs0 if not cs0.is_empty() else GameState.corp_poi(_sys, station)
				elif is_city() and _town_kind == "maint":
					var ms0 := GameState.maint_site_for(String(station.get("id", "")))         # 0.7.53.9 (53c: or a job's)
					_site = ms0 if not ms0.is_empty() else GameState.city_poi(_sys, station)
				elif is_city():
					var hs0 := GameState.sewer_site_for(String(station.get("id", "")))      # 0.7.53.17: or a heist's
					_site = hs0 if not hs0.is_empty() else GameState.city_poi(_sys, station)
				else:
					_site = GameState.settle_poi(_sys, station)
		elif _city_site != null:
			_site = _city_site
			_city_site = null
	env = ChibiArt.GearData.env_of(String(_body.get("type", ""))) if level in ["landing", "settlement", "dungeon", "minehead"] and not is_city() else {}
	_warned = {}
	if level == "settlement":
		map = SettleGen.build(station, _body, _site, _avail, _sys)
	elif level == "landing":
		var lsz := _ship_size()
		if bool(_site.get("poi", false)):
			map = _poi_map("landing", lsz)                            # package 53: a site to explore – outside
		elif bool(_site.get("vault", false)):
			map = VaultGen.build(_site)                               # 0.7.52.23: the debug vault, inside a station
			env = {}
		elif bool(_site.get("arena", false)):
			map = ArenaGen.build(_body, _site, lsz.x, lsz.y)          # package 52: the debug arena
		else:
			map = DeckGen.build_landing(_body, _site, lsz.x, lsz.y)
		if _lander:
			for zl in map.zones:
				if String(zl.get("id", "")) == "ship":
					zl["title"] = "Board the landing drone – back up to your ship"
	elif level == "dungeon":
		map = _poi_map("dungeon", Vector2.ZERO)                       # 0.7.53.2: inside the site (0.7.53.3: its level `depth`)
	elif level == "alley":
		map = _poi_map("alley", Vector2.ZERO)                         # 0.7.53.3: a city's back alley
	elif level == "plaza":
		map = _poi_map("plaza", Vector2.ZERO)                         # 0.7.53.19: a city's roof plaza
	elif level == "minehead":
		map = _poi_map("minehead", Vector2.ZERO)                      # 0.7.53.7: a settlement's old mine
	elif level == "hangar":
		var sz := _ship_size()
		var af := GameState.active()
		_hangar_uid = af.uid if af != null else 0
		map = DeckGen.build_hangar(station, sz.x, sz.y, _avail, _hangar_uid)
	elif level == "street":
		map = DeckGen.build(station, _avail, [], "street")
	elif level == "clinic":
		map = DeckGen.build_clinic(station, _avail)                 # 0.7.51.11: Mercy Hall, a level of its own
	elif level == "tower":
		var bar_only := {}
		for k in ["bar", "news", "bulletin"]:
			if _avail.has(k):
				bar_only[k] = _avail[k]
		map = DeckGen.build(station, bar_only, GameState.bar_offers(station) if _avail.has("bar") else [], "tower")
	else:
		map = DeckGen.build(station, _avail, GameState.bar_offers(station) if _avail.has("bar") else [])
	_out_env = {}
	if level == "dungeon" and map.has_meta("pressurized"):
		_out_env = env                                 # 0.7.53.20 (Luz): inside the station its own air – but not in a torn module
		env = {}
	if level in ["landing", "settlement"] and _lander and map.ship_at != Vector2.INF:
		_drone_ramp_zone()
	var lift_title := "Lifts – Hangar · Shopping street · Tower bar" if is_city() else "Lifts – Hangar · Commercial level"
	if _avail.has("clinic"):
		lift_title += " · Clinic"                                     # 0.7.51.11
	for zc in map.zones:
		if String(zc.get("id", "")) == "lift" and not level in ["settlement", "landing", "alley", "plaza"]:
			zc["title"] = lift_title
		elif is_city() and String(zc.get("id", "")) == "ship" and level == "hangar":
			zc["title"] = "Stairs down – aboard your ship and up through the hatch"
	_build()
	if combat_allowed():
		combat = GroundCombat.new()                   # package 52: weapons allowed here
		combat.setup(self, map)
		_world.add_child(combat)
		var flist: Array = map.get_meta("foes") if map.has_meta("foes") else _site.get("foes", [])     # 0.7.53.2: a dungeon's own
		var dead: Array = map.get_meta("dead", [])
		for i in mini(map.foe_spawns.size(), flist.size()):
			if dead.has(i):
				continue                                 # fallen on an earlier visit to this map
			var fe: Array = GroundCombat.FoeData.parse(String(flist[i]))         # "kind" or "kind@tier"
			var nf: Dictionary = combat.spawn(String(fe[0]), map.foe_spawns[i], "", String(fe[1]))
			nf["spawn_i"] = i
			var routes: Dictionary = map.get_meta("routes", {})
			if routes.has(i):
				nf["route"] = routes[i]                    # 0.7.53.22 (Luz): a guard on its rounds
				nf["rt_i"] = 0
			if bool(GroundCombat.FoeData.FOES.get(String(fe[0]), {}).get("drone", false)):
				nf["drone"] = true                       # 0.7.53.9: a maintenance drone – drawn as one, it flies
				(nf["w"] as Walker).visible = false
			if map.has_meta("passive"):
				nf["passive"] = true
	if combat_hud != null:
		combat_hud.combat = combat
	_close_game()
	_scan = {}
	if buddy != null and is_instance_valid(buddy):
		buddy.queue_free()
	buddy = null
	if combat == null:
		buddy = DroneBuddy.new()                       # 0.7.52.25 (Luz): the drones on your suit outside a fight too
		buddy.view = self
		_world.add_child(buddy)
	spawn_explore()                                   # 0.7.52.22: boxes, terminals, tablets, relics
	fog = null
	if map.has_meta("fog"):
		fog = FogNode.new()                            # 0.7.53.2 (Luz): the ruin's fog, low over the floor
		fog.rects = map.get_meta("fog")
		_world.add_child(fog)
		_world.move_child(fog, _sorted.get_index())
	if map.has_meta("plumes"):
		if fog == null:
			fog = FogNode.new()
			_world.add_child(fog)
			_world.move_child(fog, _sorted.get_index())
		fog.plumes = map.get_meta("plumes")
	if map.has_meta("wreck"):
		_add_wreck(map.get_meta("wreck"))
	if map.has_meta("parked"):
		var pk: Dictionary = map.get_meta("parked")                 # 0.7.53.11 (Luz): a fighter standing in the hangar, plastic
		var art: Dictionary = ParkedArt.make(String(pk["hull"]), String(pk["faction"]), float(pk["sc"]), int(pk["lift"]))
		var ps := Sprite2D.new()
		ps.texture = art["tex"]
		ps.centered = false
		ps.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ps.position = ((pk["c"] as Vector2) + (art["off"] as Vector2)) * GroundMap.SCALE
		ps.scale = Vector2.ONE * GroundMap.SCALE
		_world.add_child(ps)
		_world.move_child(ps, _sorted.get_index())
	_rep_spots = []
	_drone_fx = null
	if combat != null and combat.foes.any(func(f): return bool(f.get("drone", false))):
		_drone_fx = Node2D.new()
		_drone_fx.z_index = 8
		_drone_fx.draw.connect(_draw_drones)
		_world.add_child(_drone_fx)
		for y in range(1, map.h):
			for x in map.w:
				if GroundMap.walkable_t(map.t_at(x, y)) and map.t_at(x, y - 1) == GroundMap.T.FACE:
					_rep_spots.append(Vector2(x + 0.5, y + 0.6) * GroundMap.TILE)
	if not _hostage.is_empty():
		_hostage.erase("w")
		_spawn_hostage(pilot.pos + Vector2(14, 10))       # 53c: they came with you
		if level in ["landing", "alley", "minehead", "plaza"] and bool(_site.get("mission", false)):
			_mission_event("rescued")
			if _hostage.has("w"):
				(_hostage["w"] as Walker).leave_to = map.spawn
			_hostage = {}
	_poi_setup()                                      # package 53a: the minimap, the targets window
	_set_hint()
	_space_view(_sys)
	_title.text = "%s – %s" % [map.title, {"hangar": "Hangar", "landing": String(_body.get("name", "")), "settlement": String(_body.get("name", "")), "commercial": "Commercial level",
		"street": "Shopping street", "tower": "Tower bar · floor %d" % tower_floor(), "clinic": "Clinic – Mercy Hall", "dungeon": "inside" if depth == 0 else "level %d" % (depth + 1), "alley": "Back alley", "minehead": "The old mine", "plaza": "Roof plaza"}.get(level, "")]
	_hatch = 1.0 if arrive != "touchdown" else 0.0
	if arrive == "touchdown" and _ship_spr != null:
		_touch = 0.0                                   # she comes down onto the pad, then you walk down the ramp
		pilot.visible = false
	elif arrive == "clinic" and _clinic_spot() != Vector2.INF:
		# 0.7.51.4: you come to beside a clinic bed
		pilot.pos = _clinic_spot()
		pilot.position = pilot.pos * GroundMap.SCALE
		pilot.dir = 0
		_say_toast("You come to in the clinic of %s." % String(station.get("name", "the station")), 5.0)
	elif arrive == "mine_path" and map.has_meta("mine_path_front"):
		pilot.pos = map.get_meta("mine_path_front")      # 0.7.53.7: back into town from the old mine
		pilot.position = pilot.pos * GroundMap.SCALE
		pilot.dir = 0
	elif arrive == "dungeon_up" and map.has_meta("down_front"):
		pilot.pos = map.get_meta("down_front")          # 0.7.53.3: back up the ladder beside the hatch
		pilot.position = pilot.pos * GroundMap.SCALE
		pilot.dir = 0
	elif arrive == "dungeon_out" and map.has_meta("door_front"):
		pilot.pos = map.get_meta("door_front")          # 0.7.53.2: back out through the ruin's entrance
		pilot.position = pilot.pos * GroundMap.SCALE
		pilot.dir = 0
	elif arrive == "lift" and not map.lifts.is_empty():
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
	if level in ["landing", "settlement"] and _lander:
		return FlightScene.lander_texture()
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


## 0.7.50.15: the landing drone's ramp – you come out at its foot and go in at its top; the ground decal of a ship's
## ramp is not wanted under it.
func _drone_ramp_zone() -> void:
	map.decals = map.decals.filter(func(d): return String(d.get("kind", "")) != "ramp")
	var top := map.ship_at + LanderArt.ramp_top() * HANGAR_ART
	var foot := map.ship_at + LanderArt.ramp_foot() * HANGAR_ART
	map.spawn = foot + Vector2(0, 6)
	for z in map.zones:
		if String(z.get("id", "")) == "ship":
			z["rect"] = Rect2(Vector2(top.x - 1.7 * GroundMap.TILE, top.y - 4.0), Vector2(3.4 * GroundMap.TILE, foot.y - top.y + 1.4 * GroundMap.TILE))
			z["title"] = "Board the landing drone – take off"


func _drone_ramp_top() -> Vector2:
	return map.ship_at + LanderArt.ramp_top() * HANGAR_ART


func _draw_hatch() -> void:
	if _ship_spr == null or not is_instance_valid(_ship_spr):
		return
	LanderArt.draw_ramp(_hatch_node, _ship_spr.position, _ship_spr.scale.x, _hatch, _t, _ship_spr.modulate.a)


## 0.7.51.2: the pilot in the suit they wear (its helmet on outside, where the air is not to be breathed – 0.7.51.3).
func pilot_look() -> Dictionary:
	var lk: Dictionary = (GameState.pilot.get("look", ChibiArt.PilotArt.default_look()) as Dictionary).duplicate()
	lk["suit"] = ChibiArt.GearData.family(String(GameState.gear.suit))
	lk["helmet"] = needs_helmet() or GameState.gear.helmet == "always" or GameState.gear.combat_t > 0.0   # 0.7.51.10
	lk["arm_up"] = combat != null and combat.arm_raised()                          # 0.7.52.14: the laser arm raised
	return lk


## Outside on a world whose air is not to be breathed (or is poisoned, or there is none).
func needs_helmet() -> bool:
	return not env.is_empty() and ChibiArt.GearData.needs_helmet(env)


## 0.7.53.20: in a module torn open (its bulkhead not sealed)?
func _in_leak() -> bool:
	if pilot == null:
		return false
	for z in map.zones:
		if String(z.get("kind", "")) == "leak" and (z["rect"] as Rect2).has_point(pilot.pos) and String(map.explore[int(z["i"])]["state"]) == "open":
			return true
	return false


## 0.7.51.3: under a roof – in a shop, the bar, a building's door (the suit rests there).
func indoors() -> bool:
	if env.is_empty():
		return true
	var z := map.zone_at(pilot.pos) if pilot != null else {}
	return String(z.get("kind", "")) in ["service", "crew", "seat", "jukebox"]


## A step outside for the suit: energy, air, what gets through; warnings; collapsing at the end.
func _env_step(delta: float) -> void:
	if map != null and map.has_meta("pressurized") and level == "dungeon":
		env = _out_env if _in_leak() else {}           # 0.7.53.20 (Luz)
	if hud != null:
		hud.env = env
		hud.indoors = indoors()
	if env.is_empty() or indoors() or _touch >= 0.0 or not _ride.is_empty() or _collapsed:
		if hud != null:
			hud.exposure = 0.0
		return
	var g = GameState.gear
	var h0: float = g.health
	var r: Dictionary = g.env_step(delta, env, Input.is_action_pressed("foot_run"))
	if Commands.suit_god:
		g.health = h0                                   # 0.7.51.5 (debug): the world outside does not hurt
	if hud != null:
		hud.exposure = float(r["exposure"])
	var t: Dictionary = g.totals()
	for w in [["energy", g.energy / maxf(float(t["energy"]), 1.0), "Suit energy low – find a supply point or use an energy cell."],
			["oxygen", g.oxygen / maxf(float(t["oxygen"]), 1.0) if not bool(env.get("breathable", true)) else 1.0, "Oxygen low – back to the drone, a supply point or a cartridge."],
			["health", g.health / ChibiArt.GearData.HEALTH, "You are badly hurt – a medkit, or get under a roof."]]:
		var k := String(w[0])
		if float(w[1]) < 0.25 and not _warned.has(k):
			_warned[k] = true
			_say_toast(String(w[2]), 4.0)
			Audio.play("ui_error", "suit warning")
		elif float(w[1]) > 0.4:
			_warned.erase(k)
	if g.health <= 0.0:
		_collapse()


## The body gives out: dark, and someone finds you (0.7.51.4: the clinic).
func _collapse(reason: String = "") -> void:
	if _collapsed:
		return
	_collapsed = true
	input_enabled = false
	pilot.moving = false
	pilot.aim = Vector2.INF
	used.emit({"kind": "collapse", "rect": Rect2(), "reason": reason})      # package 52: "fight" – shot down


## Package 52: left click on a foe – lock it and make it the active target; right click – let it go.
func _on_click(event: InputEvent) -> void:
	if combat == null or not input_enabled or _collapsed or not (event is InputEventMouseButton) or not event.pressed:
		return
	# 0.7.52.8 / 0.7.52.13 (Luz): the mouse wheel steps the zoom – in a fight normal and near, in the tactical view also
	# out to half
	if event.button_index == MOUSE_BUTTON_WHEEL_DOWN or event.button_index == MOUSE_BUTTON_WHEEL_UP:
		zoom_step(-1 if event.button_index == MOUSE_BUTTON_WHEEL_DOWN else 1)
		return
	if event.button_index != MOUSE_BUTTON_LEFT and event.button_index != MOUSE_BUTTON_RIGHT:
		return
	var f = combat.foe_at((event.position - _world.position) / (GroundMap.SCALE * zoom))
	if f == null:
		return
	if event.button_index == MOUSE_BUTTON_LEFT:
		combat.lock(f)
	else:
		combat.unlock(f)


## 0.7.52.13: a step of the zoom (+1 nearer, -1 further) – the fight: normal, near; the tactical view: out, normal, near.
func zoom_step(d: int) -> void:
	if combat == null:
		return
	var steps: Array = [TAC_ZOOM_OUT, 1.0, ZOOM_NEAR] if combat.tactics != 0 else [1.0, ZOOM_NEAR]
	var cur: float = tac_zoom if combat.tactics != 0 else near_zoom
	var i := 0
	for k in steps.size():
		if absf(float(steps[k]) - cur) < 0.01:
			i = k
	var nz: float = steps[clampi(i + d, 0, steps.size() - 1)]
	if combat.tactics != 0:
		tac_zoom = nz
	else:
		near_zoom = nz


## Package 52: may weapons be used here? So far only in the debug arena (Luz: the real fights come once the system
## stands); never in the built-up parts of cities.
## 0.7.53.5 (Luz): turrets – on, they turn to you when they see you (in reach, not cloaked, nothing high between),
## ring the alarm and fire bursts; low cover halves their aim, an EMP stuns them; off they hang still.
const TURRET_REACH := 230.0
const TURRET_ROF := 0.32
func _turrets_step(delta: float) -> void:
	for d in map.explore:
		if String(d["kind"]) != "turret":
			continue
		d["flash"] = maxf(0.0, float(d.get("flash", 0.0)) - delta)
		if String(d["state"]) != "on" or combat.emp_t > 0.0:
			continue
		var eye: Vector2 = (d["pos"] as Vector2) + Vector2(0, 10)
		var pp: Vector2 = combat.pilot_pos()
		if eye.distance_to(pp) > TURRET_REACH or combat.pilot_hidden() or bool(combat.sight(eye, pp)["blocked"]) or Commands.suit_god:
			d["seen"] = false
			continue
		var want := ((pp + Vector2(0, -12)) - ((d["pos"] as Vector2) + Vector2(0, -26))).angle()
		d["ang"] = lerp_angle(float(d.get("ang", PI * 0.5)), want, minf(1.0, delta * 6.0))
		if not bool(d.get("seen", false)):
			d["seen"] = true
			d["cool"] = 0.6                               # it turns before it fires
			_say_toast("A turret has you – get into cover!", 2.0)
			raise_alarm()
		d["cool"] = float(d.get("cool", 0.0)) - delta
		if float(d["cool"]) > 0.0:
			continue
		d["cool"] = TURRET_ROF
		d["flash"] = 0.06
		var sg: Dictionary = combat.sight(eye, pp)
		var chance := 0.42 * (0.45 if sg["cover"] else 1.0)
		var muzzle: Vector2 = (d["pos"] as Vector2) + Vector2(0, -26) + Vector2.from_angle(float(d["ang"])) * 12.0
		var res := {"to": null, "dmg": 7.0, "dtype": "kinetic", "splash": 0.0, "from": null}
		var end: Vector2
		if randf() < chance:
			res["kind"] = "hit"
			end = pp + Vector2(randf_range(-2, 2), -12 + randf_range(-3, 3))
		elif sg["cover"]:
			res["kind"] = "blocked"
			end = (sg["at"] as Vector2) + Vector2(0, -6)
		else:
			res["kind"] = "miss"
			end = pp + Vector2(randf_range(-26, 26), randf_range(-20, 8))
		combat.shots.append({"a": muzzle, "b": end, "t": 0.0, "life": maxf(0.05, muzzle.distance_to(end) / 900.0), "kind": "slug",
			"col": Color(1.0, 0.85, 0.4), "res": res, "done": false})
		Audio.play("w_autocannon", "turret fires", -12.0)


## 0.7.53.5 (Luz): the alarm – if the level has a box that is not cut, it rings: everyone here comes for you and two
## more of them come in from the way you came.
func raise_alarm() -> void:
	if combat == null:
		return
	_site["alarmed"] = true                              # package 53c: a heist's rule
	for d in map.explore:
		if String(d["kind"]) == "alarm" and String(d["state"]) == "armed":
			d["state"] = "ringing"
			for f in combat.alive():
				combat._wake(f)
			var th: Dictionary = PoiData.layer(String(_site.get("theme", "precursor")), depth)
			var dg: Dictionary = PoiData.DANGER.get(String(_site.get("danger", "yellow")), PoiData.DANGER["yellow"])
			for i in 2:
				var sp: Vector2 = combat._free_near(map.spawn + Vector2(randf_range(-30, 30), randf_range(0, 20)))
				if sp != Vector2.INF:
					var nf: Dictionary = combat.spawn(String(th["foes"][randi() % th["foes"].size()]), sp, "", String(dg["tiers"][randi() % (dg["tiers"] as Array).size()]))
					combat._wake(nf)
			_say_toast("ALARM! The whole place knows you are here – and more of them are coming.", 3.5)
			Audio.play("warn", "alarm rings", 0.0)
			return


## 0.7.53.6 (Luz): the wreck of a crash site – the ship's own picture at the ground's scale, shaded into hull plates
## and burnt (shaders/wreck.gdshader); its shadow; the stern torn off and lying apart.
func _add_wreck(w: Dictionary) -> void:
	var tex: Texture2D = PixelArt.ship_texture(String(w["hull"]), "independent")
	var sz := Vector2(tex.get_width(), tex.get_height())
	for piece in [[w["c"], w["ang"], w["cut"]], [w["stern_c"], w["stern_ang"], w["stern_cut"]]]:
		var sh := Sprite2D.new()
		sh.texture = tex
		sh.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sh.modulate = Color(0, 0, 0, 0.45)
		sh.position = ((piece[0] as Vector2) + Vector2(10, 16)) * GroundMap.SCALE
		sh.rotation = float(piece[1])
		sh.scale = Vector2.ONE * float(w["sc"]) * GroundMap.SCALE
		var shm := ShaderMaterial.new()
		shm.shader = WreckShader
		shm.set_shader_parameter("px_size", sz)
		shm.set_shader_parameter("art_per_px", float(w["sc"]))
		shm.set_shader_parameter("burnt", 1.0)
		shm.set_shader_parameter("cut", piece[2])
		sh.material = shm
		_world.add_child(sh)
		_world.move_child(sh, _sorted.get_index())
		var sp := Sprite2D.new()
		sp.texture = tex
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sp.position = (piece[0] as Vector2) * GroundMap.SCALE
		sp.rotation = float(piece[1])
		sp.scale = Vector2.ONE * float(w["sc"]) * GroundMap.SCALE
		var mat := ShaderMaterial.new()
		mat.shader = WreckShader
		mat.set_shader_parameter("px_size", sz)
		mat.set_shader_parameter("art_per_px", float(w["sc"]))
		mat.set_shader_parameter("burnt", float(w["burnt"]))
		mat.set_shader_parameter("cut", piece[2])
		sp.material = mat
		_world.add_child(sp)
		_world.move_child(sp, _sorted.get_index())


## 0.7.53.6: a wreck's hazards – a live conduit shocks you when you step on it (now and then), a gas leak burns your
## lungs unless your helmet is on.
func _hazards_step(delta: float) -> void:
	for k in _haz_t.keys():
		_haz_t[k] = float(_haz_t[k]) - delta
		if float(_haz_t[k]) <= 0.0:
			_haz_t.erase(k)
	for i in map.explore.size():
		var d: Dictionary = map.explore[i]
		var kd := String(d["kind"])
		if kd == "conduit" and not _haz_t.has(i) and (d["pos"] as Vector2).distance_to(pilot.pos) < 10.0:
			_haz_t[i] = 1.2
			if not Commands.suit_god:
				combat._hurt_pilot(16.0, "optical")
			combat.sparks.append({"pos": d["pos"], "vel": Vector2(0, -40), "t": 0.0, "col": Color(0.6, 0.85, 1.0)})
			combat.floaters.append({"pos": pilot.pos + Vector2(0, -40), "text": "ZAP", "col": Color(0.6, 0.85, 1.0), "t": 0.0})
			Audio.play("shield_down", "shock conduit", -6.0)
		elif kd == "searchlight":
			var lp := (d["pos"] as Vector2)
			var rel := pilot.pos - lp
			var ang := float(d.get("ang", 0.0))
			var seen := rel.length() < 150.0 and absf(angle_difference(Vector2(rel.x, rel.y / 0.6).angle(), ang)) < 0.3 and not combat.pilot_hidden()
			d["seen"] = seen
			if seen and not bool(d.get("raised", false)):
				d["raised"] = true                              # 0.7.53.11: caught in the light – the guards come
				_say_toast("Caught in the searchlight – they know you are here!", 2.5)
				Audio.play("warn", "searchlight", -2.0)
				for f in combat.alive():
					combat._wake(f)
		elif kd == "steam" and not _haz_t.has(i) and (d["pos"] as Vector2).distance_to(pilot.pos) < 16.0 \
				and fposmod(Time.get_ticks_msec() * 0.001 + float(int(d.get("seed", 0)) % 9), 4.0) < 1.2:
			_haz_t[i] = 1.0
			if not Commands.suit_god:
				combat._hurt_pilot(12.0, "kinetic")
			combat.floaters.append({"pos": pilot.pos + Vector2(0, -40), "text": "steam!", "col": Color(0.9, 0.95, 1.0), "t": 0.0})
		elif kd == "loose_rock" and String(d["state"]) == "shut" and (d["pos"] as Vector2).distance_to(pilot.pos) < 14.0 and not combat.sneaking:
			d["state"] = "falling"                         # 0.7.53.7: a crack, dust – then the rock comes down
			_fuses[i] = 0.7
			_say_toast("A crack overhead – move!", 1.2)
			Audio.play("warn", "rockfall", -4.0)
		elif kd == "gas" and (d["pos"] as Vector2).distance_to(pilot.pos) < float(d.get("r", 30.0)):
			if GameState.gear.helmet != "always" and GameState.gear.combat_t <= 0.0 and not Commands.suit_god:
				combat._hurt_pilot(4.0 * delta, "kinetic")
				if not _haz_t.has(-1 - i):
					_haz_t[-1 - i] = 4.0
					_say_toast("Toxic gas – put your helmet on (Gear: helmet always) or get out of it.", 2.5)


## 0.7.53.9 (Luz): the reactor restarted – it spins up, the lights come back on level by level.
func _restart_reactor(d: Dictionary) -> void:
	for r in map.explore:
		if String(r["kind"]) == "reactor":
			r["state"] = "on"
			r["start"] = 0.0
	var lit := Color(0.95, 0.95, 0.97)
	for key in _poi_cache.keys():
		if String(key).begins_with("dungeon_"):
			(_poi_cache[key] as GroundMap).set_meta("dark", lit)
	if _dark_rect != null and is_instance_valid(_dark_rect):
		var tw := create_tween()
		tw.tween_interval(2.5)
		tw.tween_property(_dark_rect, "color", lit, 3.0)
	Audio.play("module_on", "reactor restart", 0.0)
	_poi_target_done(d)


## 0.7.53.16 (Luz): charging at a power socket – while E is held and you stay by it, small arcs leap to the suit and
## its energy fills (the socket's own store runs down); no shooting meanwhile (GroundCombat._pilot_fire).
const SOCKET_RATE := 30.0                 # energy a second
var socket_hold_test := false             # the smoke test holds the key


func charging() -> bool:
	return _socket >= 0


func _socket_step(delta: float) -> void:
	if _socket < 0:
		return
	var sd: Dictionary = map.explore[_socket] if _socket < map.explore.size() else {}
	var g = GameState.gear
	var mx := float(g.totals()["energy"])
	var stay: bool = not sd.is_empty() and Input.is_action_pressed("interact") and String(zone.get("kind", "")) == "socket" \
		and int(zone.get("i", -1)) == _socket and input_enabled and not _collapsed
	if socket_hold_test:
		stay = not sd.is_empty() and not _collapsed
	if not stay or float(sd.get("charge", 0.0)) <= 0.0 or g.energy >= mx - 0.01:
		if not sd.is_empty():
			sd.erase("arc")
			if g.energy >= mx - 0.01:
				_say_toast("Charged – the suit's energy is full.", 1.5)
			elif float(sd.get("charge", 0.0)) <= 0.0:
				_say_toast("The socket is drawn dry.", 1.5)
		_socket = -1
		return
	var add := minf(minf(SOCKET_RATE * delta, mx - g.energy), float(sd["charge"]))
	g.energy += add
	sd["charge"] = float(sd["charge"]) - add
	sd["arc"] = pilot.pos - (sd["pos"] as Vector2)
	if randf() < delta * 6.0:
		Audio.play("ui_click", "socket arc", -14.0)


## 0.7.53.23 (Luz, package 53d): the Dark Ones' symbols – touched in the right order a membrane opens; a wrong one
## sends out a wave of force (and the order begins again). A monolith's vision tells the order.
const SYMBOLS := [["●", "the Eye"], ["▲", "the Tooth"], ["◆", "the Coil"], ["■", "the Gate"]]
const VISIONS := ["You stand under a sky without stars. Something breathes beneath the ground – slowly, for an age.",
	"Figures in a ring, kneeling round a pit. None of them looks up. Something in the pit does.",
	"A city of black glass, grown like coral. Its people sleep in the walls. They are dreaming of you.",
	"The stars go out one by one, and the dark between them leans closer to listen.",
	"A voice that is not a voice counts backwards. You do not know from what number."]
const WAVE_DMG := 18.0


func _symbol_menu(d: Dictionary) -> void:
	_close_lift_menu()
	Audio.play("ui_open", "symbol stones", -6.0)
	var c := CenterContainer.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(c)
	var vio := Color(0.62, 0.35, 1.0)
	var p := UI.neon_panel(Color(vio, 0.9), Color(0.03, 0.02, 0.05, 0.96), 2)
	p.custom_minimum_size = Vector2(420, 0)
	c.add_child(p)
	var v := UI.vbox(8)
	p.add_child(v)
	v.add_child(UI.label("THE SYMBOL STONES", 20, vio))
	var seq: Array = d.get("seq", [])
	v.add_child(UI.label("Touch the signs in their order.  %d of 4 glow." % seq.size(), 13, UI.TEXT_DIM))
	var keys: Array = []
	for i in 4:
		var si := i
		var lit := seq.has(i)
		var b := UI.button("%d.  %s  %s%s" % [i + 1, SYMBOLS[i][0], SYMBOLS[i][1], "   (glowing)" if lit else ""], func(): _touch_symbol(d, si))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = lit
		v.add_child(b)
		keys.append(func(): _touch_symbol(d, si))
	v.add_child(UI.button("Step back [Esc]", _close_lift_menu))
	_lift_menu = c
	_lift_menu.set_meta("zone", {})
	_lift_menu.set_meta("keys", keys)


func _touch_symbol(d: Dictionary, i: int) -> void:
	var seq: Array = d.get("seq", [])
	var order: Array = d["order"]
	if seq.size() < order.size() and int(order[seq.size()]) == i:
		seq.append(i)
		d["seq"] = seq
		Audio.play("ui_click", "symbol touched", -4.0)
		if seq.size() >= order.size():
			d["state"] = "open"
			_close_lift_menu()
			open_door(map.explore[int(d["door"])])
			_say_toast("The fourth sign burns – the stone draws back.", 3.0)
			Audio.play("shield_down", "membrane opens", -2.0)
			return
		_symbol_menu(d)
		return
	d["seq"] = []
	_close_lift_menu()
	_dark_wave(pilot.pos)
	_say_toast("Wrong – a wave of force rolls out of the stone! The signs go dark again.", 3.0)


## 0.7.53.23: a wave of force – hurts whoever stands near (you, foes alike).
func _dark_wave(at: Vector2) -> void:
	if combat != null:
		combat._explode(at + Vector2(0, -4), 40.0, WAVE_DMG, "explosive", null)
	elif not Commands.suit_god:
		GameState.gear.health = maxf(1.0, GameState.gear.health - WAVE_DMG)
	Audio.play("shield_down", "dark wave", 0.0)


## 0.7.53.19 (Luz, package 53d): the corporate tower's cameras and light barriers. A camera sweeps; in its view (and
## not behind a wall) it notices you within a moment – then it rings the alarm. A light barrier rings it as soon as you
## cross it (crouched or not). The security centre switches both off for the whole tower; an EMP blinds the cameras.
const VAULT_DRILL := 20.0
const REINFORCE_DELAY := 5.0


## 0.7.53.22 (Luz): found out on a level of the tower – a few seconds later more guards come up the lift (once).
func _reinforce_step(delta: float) -> void:
	if not map.has_meta("reinforce") or map.has_meta("reinforced"):
		return
	var t := float(map.get_meta("reinf_t", -1.0))
	if t < 0.0:
		if combat.alive().any(func(f): return f["aware"] and not f.has("reinf")):
			map.set_meta("reinf_t", REINFORCE_DELAY)
			_say_toast("They have seen you – security is on its way up the lift!", 3.0)
			Audio.play("warn", "reinforcements called", -2.0)
		return
	t -= delta
	map.set_meta("reinf_t", t)
	if t > 0.0:
		return
	map.set_meta("reinforced", true)
	var rf: Dictionary = map.get_meta("reinforce")
	var at: Vector2 = rf["at"]
	var k := 0
	for kd in rf["kinds"]:
		var fe: Array = GroundCombat.FoeData.parse(String(kd))
		var sp: Vector2 = combat._free_near(at + Vector2((k % 3 - 1) * 14.0, (k / 3) * 14.0))
		k += 1
		if sp == Vector2.INF:
			continue
		var nf: Dictionary = combat.spawn(String(fe[0]), sp, "", String(fe[1]))
		nf["reinf"] = true
		combat._wake(nf)
	_say_toast("The lift doors open – security!", 2.5)
	Audio.play("dock_clamp", "lift arrives", -2.0)
const CAM_NOTICE := 0.8


func _cams_step(delta: float) -> void:
	var cams_off := bool(_site.get("cams_off", false))
	var beams_off := bool(_site.get("beams_off", false))
	for d in map.explore:
		var kd := String(d["kind"])
		if kd == "camera":
			if cams_off and String(d["state"]) == "on":
				d["state"] = "off"
			if String(d["state"]) != "on" or combat.emp_t > 0.0 or Commands.suit_god:
				continue
			var eye: Vector2 = (d["pos"] as Vector2) + Vector2(0, 4)
			var rel := pilot.pos - eye
			var flat := Vector2(rel.x, rel.y / 0.75)
			var seen := flat.length() < ExploreNode.CAM_REACH and absf(angle_difference(flat.angle(), float(d.get("ang", PI * 0.5)))) < ExploreNode.CAM_HALF \
				and not combat.pilot_hidden() and not bool(combat.sight(eye + Vector2(0, 10), pilot.pos)["blocked"])
			d["notice"] = clampf(float(d.get("notice", 0.0)) + (delta / CAM_NOTICE if seen else -delta * 0.5), 0.0, 1.0)
			if float(d["notice"]) >= 1.0 and not bool(d.get("raised", false)):
				d["raised"] = true
				_say_toast("A camera has you – the alarm!", 2.5)
				Audio.play("warn", "camera alarm", -2.0)
				raise_alarm()
		elif kd == "glyph_trap":
			if String(d.get("state", "")) != "spent" and (d["pos"] as Vector2).distance_to(pilot.pos) < 10.0:
				d["state"] = "spent"                       # 0.7.53.23 (Luz): a glyph flares under your feet
				_say_toast("A glyph flares under your feet – a wave of force!", 2.5)
				_dark_wave(d["pos"])
		elif kd == "laser_gate":
			if beams_off and String(d["state"]) == "on":
				d["state"] = "off"
			if String(d["state"]) != "on" or Commands.suit_god:
				continue
			var a: Vector2 = d["pos"]
			var ln := float(d.get("len", 3)) * GroundMap.TILE
			var b: Vector2 = a + (Vector2(0, ln) if bool(d.get("vertical", true)) else Vector2(ln, 0))
			if Geometry2D.get_closest_point_to_segment(pilot.pos, a, b).distance_to(pilot.pos) < 4.0:
				d["state"] = "tripped"
				_say_toast("You broke a light barrier – the alarm!", 2.5)
				Audio.play("warn", "light barrier", -2.0)
				raise_alarm()


## 53c (Luz): the rescued prisoner – a walker that follows you (along a path round walls), hurt by blasts.
func _spawn_hostage(at: Vector2) -> void:
	if _hostage.is_empty():
		return
	var w := Walker.new()
	w.setup(map, _hostage["look"], at, false)
	w.stays = true
	_sorted.add_child(w)
	_hostage["w"] = w
	_hostage["repath"] = 0.0


func _hostage_step(delta: float) -> void:
	if _hostage.is_empty() or not _hostage.has("w") or not is_instance_valid(_hostage["w"]):
		return
	var w: Walker = _hostage["w"]
	var d := w.pos.distance_to(pilot.pos)
	_hostage["repath"] = float(_hostage["repath"]) - delta
	if d < 26.0:
		w.moving = false
		return
	if float(_hostage["repath"]) <= 0.0 or w._pi >= w._path.size():
		w._path = map.path(w.pos, pilot.pos)
		w._pi = 0
		_hostage["repath"] = 0.5
	w._follow(delta, 1.25 if d > 80.0 else 0.95)


## 53c: a blast near the prisoner hurts them; at nothing they die – the rescue has failed.
func _hostage_blast(at: Vector2, r: float) -> void:
	if _hostage.is_empty() or not _hostage.has("w") or not is_instance_valid(_hostage["w"]):
		return
	var w: Walker = _hostage["w"]
	var dd := w.pos.distance_to(at)
	if dd >= r:
		return
	_hostage["hp"] = float(_hostage["hp"]) - 45.0 * (1.0 - dd / r)
	if float(_hostage["hp"]) <= 0.0:
		w.down = true
		_hostage = {}
		GameState.ground_goal(_site, false, 1.0, "the prisoner died")
		_site["goal_done"] = true
		_say_toast("The prisoner is dead – the rescue has failed.", 4.0)
	else:
		_say_toast("The prisoner is hurt! (%d %%)" % int(float(_hostage["hp"]) / 60.0 * 100.0), 2.0)


## 0.7.53.9 (Luz): maintenance drones – while they leave you be they fly from one spot on the walls to the next and
## mend it with their beam; provoked, the fight takes them (they fly over everything, their walker unseen).
func _drones_step(delta: float) -> void:
	if _drone_fx == null:
		return
	for f in combat.alive():
		if not bool(f.get("drone", false)):
			continue
		var w: Walker = f["w"]
		f["bob"] = float(f.get("bob", randf() * TAU)) + delta * 3.0
		if f["aware"] or _rep_spots.is_empty():
			f["rep"] = 0.0
			continue
		var goal: Vector2 = f.get("rgoal", Vector2.INF)
		if goal == Vector2.INF or (float(f.get("rep", 0.0)) <= 0.0 and w.pos.distance_to(goal) < 3.0 and f.has("mended")):
			var home: Vector2 = f["home"]
			var near: Array = _rep_spots.filter(func(p): return (p as Vector2).distance_to(home) < 180.0)
			if near.is_empty():
				near = _rep_spots
			goal = near[randi() % near.size()]
			f["rgoal"] = goal
			f.erase("mended")
		if w.pos.distance_to(goal) > 3.0:
			w.pos = w.pos.move_toward(goal, 34.0 * delta)                 # it flies – over cover, straight
			w.position = w.pos * GroundMap.SCALE
			f["rep"] = 0.0
		elif not f.has("mended"):
			f["mended"] = true
			f["rep"] = randf_range(2.5, 4.5)
		else:
			f["rep"] = maxf(0.0, float(f["rep"]) - delta)
	_drone_fx.queue_redraw()


## A maintenance drone: a quadcopter twice the size of yours in safety yellow, its rotors a blur, a tool arm; mending,
## a cyan beam onto the wall and sparks; provoked, its light turns red.
func _draw_drones() -> void:
	var s := GroundMap.SCALE
	var t := Time.get_ticks_msec() * 0.001
	for f in combat.alive():
		if not bool(f.get("drone", false)):
			continue
		var p: Vector2 = (f["w"] as Walker).pos
		var hov := 30.0 + sin(float(f.get("bob", 0.0))) * 2.0
		var c := (p - Vector2(0, hov)) * s
		_drone_fx.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		_drone_fx.draw_circle(p * s, 9.0 * s, Color(0, 0, 0, 0.3))
		_drone_fx.draw_set_transform(c, 0.0, Vector2.ONE * s)
		for rx in [-11.0, 11.0]:
			for ry in [-6.0, 6.0]:
				_drone_fx.draw_line(Vector2.ZERO, Vector2(rx, ry), Color(0.25, 0.25, 0.27), 1.5)
				_drone_fx.draw_circle(Vector2(rx, ry), 5.0, Color(0.6, 0.62, 0.65, 0.35 + 0.15 * sin(t * 40.0 + rx)))
				_drone_fx.draw_circle(Vector2(rx, ry), 1.2, Color(0.2, 0.2, 0.22))
		_drone_fx.draw_rect(Rect2(-7, -5, 14, 10), Color(0.95, 0.75, 0.15))
		_drone_fx.draw_rect(Rect2(-7, -5, 14, 2), Color(1.0, 0.88, 0.4))
		for st in 3:
			_drone_fx.draw_rect(Rect2(-6 + st * 5, 2, 3, 2), Color(0.1, 0.1, 0.1))
		_drone_fx.draw_rect(Rect2(-1, 5, 2, 6), Color(0.3, 0.3, 0.32))
		_drone_fx.draw_circle(Vector2(4, -3), 1.2, Color(1.0, 0.25, 0.2) if f["aware"] else Color(0.3, 1.0, 0.6))
		if float(f.get("rep", 0.0)) > 0.0:
			var to: Vector2 = (p + Vector2(0, -22)) * s
			_drone_fx.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			_drone_fx.draw_line(c + Vector2(0, 11) * s, to, Color(0.6, 0.95, 1.0, 0.9), 2.0)
			_drone_fx.draw_line(c + Vector2(0, 11) * s, to, Color(0.3, 0.7, 1.0, 0.35), 6.0)
			for sp in 6:
				var sa := hash(int(t * 20.0) + sp) % 628 / 100.0
				_drone_fx.draw_line(to, to + Vector2(cos(sa), sin(sa)) * (4.0 + sp) * 2.0, Color(1.0, 0.85, 0.4), 1.5)
		_drone_fx.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## 0.7.53.7: charges and explosives burning down; loose rock coming down.
func _fuses_step(delta: float) -> void:
	for k0 in _fuses.keys():
		var d0: Dictionary = map.explore[int(k0)]
		if String(d0["kind"]) == "crank_door":
			d0["crank"] = float(d0.get("crank", 0.0)) + delta * 6.0
	for k in _fuses.keys():
		_fuses[k] = float(_fuses[k]) - delta
		if float(_fuses[k]) > 0.0:
			continue
		_fuses.erase(k)
		var d: Dictionary = map.explore[int(k)]
		match String(d["kind"]):
			"loose_rock":
				d["state"] = "fallen"
				combat.booms.append({"pos": d["pos"], "r": 22.0, "t": 0.0, "col": Color(0.6, 0.55, 0.5)})
				if (d["pos"] as Vector2).distance_to(pilot.pos) < 18.0 and not Commands.suit_god:
					combat._hurt_pilot(26.0, "kinetic")
				for f in combat.alive():
					if (f["w"] as Walker).pos.distance_to(d["pos"]) < 18.0:
						combat._hurt_foe(f, 26.0, "kinetic")
				Audio.play("explosion_small", "rockfall", -6.0)
			"rubble":
				combat._explode((d["pos"] as Vector2) + Vector2(0, -8), 60.0, 50.0, "explosive", null)
			"tnt":
				d["state"] = "gone"
				combat._explode(d["pos"], 80.0, 70.0, "explosive", null)
			"crank_door":
				open_door(d)                                  # 0.7.53.9: cranked open
			"vault_door":
				open_door(d)                                  # 0.7.53.19: the drill is through
				_say_toast("The drill is through – the vault door swings aside.", 3.0)
				Audio.play("dock_clamp", "vault opens", 0.0)
			"cells":
				d["state"] = "open"                           # 53c: the prisoner comes out
				d["prisoner"] = false
				var lk: Dictionary = ChibiArt.PilotArt.random_look()
				lk["suit"] = "suit_civil"
				_hostage = {"look": lk, "hp": 60.0}
				_spawn_hostage((d["pos"] as Vector2) + Vector2(0, 20))
				_say_toast("The lock gives – \"Get me out of here!\" They follow you. Keep them alive.", 3.5)
				Audio.play("dock_clamp", "cell opened", -6.0)


## 0.7.53.7 (Luz): something blew up at `at` – boxes of explosives near it go up a moment later, rubble near it is
## blown away (called by the fight's blasts).
func blast_near(at: Vector2, r: float) -> void:
	if map == null:
		return
	_hostage_blast(at, r)                              # 53c: the prisoner
	for i in map.explore.size():
		var d: Dictionary = map.explore[i]
		var dist := (d["pos"] as Vector2).distance_to(at)
		if String(d["kind"]) == "tnt" and String(d["state"]) == "shut" and dist < r + 10.0 and dist > 1.0 and not _fuses.has(i):
			d["state"] = "lit"
			_fuses[i] = 0.25
		elif String(d["kind"]) == "rubble" and String(d["state"]) != "open" and dist < r + 16.0:
			d["state"] = "open"
			_fuses.erase(i)
			for t in d.get("tiles", []):
				map.set_t(int(t[0]), int(t[1]), GroundMap.T.FLOOR, 25)
			map.refresh_texture()
			map._astar = null
			if combat != null:
				combat._build_cover()
			_say_toast("The rubble is blown away – the drift is open.", 2.5)


## 0.7.53.7: one of a thing out of your grenade places, belt or pockets.
func _take_one(id: String) -> void:
	var gr = GameState.gear
	for arr in [gr.grenades, gr.belt, gr.inv]:
		for i in (arr as Array).size():
			var p: Dictionary = arr[i]
			if not p.is_empty() and String(p["id"]) == id:
				p["n"] = int(p["n"]) - 1
				if int(p["n"]) <= 0:
					arr[i] = {}
				return


## 0.7.53.7: a shot landing at p sets off a box of explosives it hits.
func shot_lands(p: Vector2) -> void:
	if map == null:
		return
	for i in map.explore.size():
		var d: Dictionary = map.explore[i]
		if String(d["kind"]) == "tnt" and String(d["state"]) == "shut" and ((d["pos"] as Vector2) + Vector2(0, -6)).distance_to(p) < 14.0:
			d["state"] = "lit"
			_fuses[i] = 0.15


## 0.7.53.6 (Luz): the emergency generator – where its power goes.
func _open_power_menu(d: Dictionary) -> void:
	Audio.play("ui_open", "generator")
	var c := CenterContainer.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(c)
	var p := UI.neon_panel(Color(1.0, 0.8, 0.3, 0.85), Color(0.05, 0.04, 0.03, 0.96), 2)
	p.custom_minimum_size = Vector2(460, 0)
	c.add_child(p)
	var v := UI.vbox(8)
	p.add_child(v)
	v.add_child(UI.label("EMERGENCY POWER", 20, Color(1.0, 0.8, 0.3)))
	v.add_child(UI.label("Barely enough for one – where does it go?", 13, UI.TEXT_DIM))
	var opts := [["doors", "1.  The bulkheads – they open (the lights go out)"], ["lights", "2.  The lights – the bulkheads stay jammed"]]
	var keys: Array = []
	for o in opts:
		var pick := func(): _route_power(d, String(o[0]))
		var b := UI.button(String(o[1]), pick)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = String(d.get("route", "lights")) == String(o[0])
		v.add_child(b)
		keys.append(pick)
	v.add_child(UI.button("Cancel [Esc]", _close_lift_menu))
	_lift_menu = c
	_lift_menu.set_meta("zone", {})
	_lift_menu.set_meta("keys", keys)


func _route_power(d: Dictionary, to: String) -> void:
	_close_lift_menu()
	d["route"] = to
	if to == "doors":
		if d.has("door") and int(d["door"]) >= 0:
			open_door(map.explore[int(d["door"])])
		if _dark_rect != null and is_instance_valid(_dark_rect):
			_dark_rect.color = Color(0.45, 0.28, 0.27)
		_say_toast("The bulkheads groan open – and the lights die. Only the red emergency lamps now.", 3.5)
	else:
		if _dark_rect != null and is_instance_valid(_dark_rect):
			_dark_rect.color = map.get_meta("dark", Color(0.78, 0.55, 0.52))
		_say_toast("The lights flicker back on.", 2.0)
	Audio.play("module_on", "power routed", -4.0)


## 0.7.53.4: the ancient lift by you ({} none).
func _lift_here() -> Dictionary:
	for d in map.explore:
		if String(d["kind"]) in ["ancient_lift", "cage"] and (d["pos"] as Vector2).distance_to(pilot.pos) < 40.0:
			return d
	return {}


## 0.7.53.4 (Luz): riding the ancient lift – onto the platform's middle, then it sinks (or rises) and you with it.
func _sink_step(delta: float) -> void:
	var d: Dictionary = _sink["d"]
	_sink["t"] = float(_sink["t"]) + delta
	var tt := float(_sink["t"])
	var c: Vector2 = d["pos"]
	if tt < 0.5:
		pilot.step((c - pilot.pos).limit_length(1.0), delta, 0.8)
		return
	pilot.pos = c
	var k := clampf((tt - 0.5) / 1.3, 0.0, 1.0)
	d["sink"] = k
	pilot.position = (c + Vector2(0, 14.0 * k)) * GroundMap.SCALE
	pilot.modulate.a = 1.0 - k
	if k >= 1.0:
		var down := int(_sink["dir"]) > 0
		d["sink"] = 0.0
		_sink = {}
		pilot.modulate.a = 1.0
		depth = depth + 1 if down else maxi(0, depth - 1)
		go_level("dungeon", "dungeon_down" if down else "dungeon_up")
		_say_toast("The platform settles – level %d." % (depth + 1), 2.0)


## 0.7.53.3: wading through the sewer's canal is slow.
func _wade() -> float:
	if map == null or pilot == null:
		return 1.0
	var tx := int(pilot.pos.x / GroundMap.TILE)
	var ty := int(pilot.pos.y / GroundMap.TILE)
	if tx < 0 or ty < 0 or tx >= map.w or ty >= map.h:
		return 1.0
	return 0.55 if map.floor_kind[ty * map.w + tx] == 18 else 1.0


## 0.7.53.3: tripwires – walking into one (not sneaking) sets off its grenade a moment later; sneaking you step over.
func _wires_step(delta: float) -> void:
	if combat == null or map == null:
		return
	for k in _wires_t.keys():
		_wires_t[k] = float(_wires_t[k]) - delta
		if float(_wires_t[k]) <= 0.0:
			var d0: Dictionary = map.explore[int(k)]
			_wires_t.erase(k)
			combat._explode((d0["pos"] as Vector2) + Vector2(0, 6), 70.0, 55.0, "explosive", null)
			raise_alarm()
	for i in map.explore.size():
		var d: Dictionary = map.explore[i]
		if String(d["kind"]) != "tripwire" or String(d["state"]) != "shut":
			continue
		var a: Vector2 = d["pos"]
		var ln := float(d.get("len", 3)) * GroundMap.TILE
		var b: Vector2 = a + (Vector2(0, ln) if bool(d.get("vertical", true)) else Vector2(ln, 0))
		if Geometry2D.get_closest_point_to_segment(pilot.pos, a, b).distance_to(pilot.pos) < 4.0 and not combat.sneaking:
			d["state"] = "fired"
			_wires_t[i] = 0.6
			_say_toast("Click – a tripwire!", 1.5)
			Audio.play("warn", "tripwire", -2.0)


func combat_allowed() -> bool:
	return (level == "landing" and (bool(_site.get("arena", false)) or bool(_site.get("vault", false)) or bool(_site.get("poi", false)))) \
		or (level == "dungeon" and bool(_site.get("poi", false)))


func _slung() -> String:
	for w in GameState.gear.weapons:
		if String(w) != "":
			return String(ChibiArt.GearData.base(String(w)).get("dtype", "kinetic"))
	return ""


## 0.7.51.13 (Luz): the easter egg – behind the scanner in the treatment room the pilot shows as a skeleton, lit
## above the capsule's glass.
func _xray_step() -> void:
	var on := false
	for z in map.zones:
		if String(z.get("id", "")) == "xray" and (z["rect"] as Rect2).has_point(pilot.pos):
			on = true
	if on != pilot.xray:
		pilot.xray = on
		pilot.z_index = 6 if on else 0
		pilot.modulate = Color(0.7, 1.0, 1.0, 0.9) if on else Color.WHITE
		pilot.queue_redraw()
		if on:
			Audio.play("ui_click", "clinic scanner")


## 0.7.51.4: where you wake – inside the clinic, by its beds (INF: no clinic here).
func _clinic_spot() -> Vector2:
	for zw in map.zones:                                          # 0.7.51.11: beside a bed in the recovery room
		if String(zw.get("id", "")) == "wake":
			return (zw["rect"] as Rect2).get_center()
	for z in map.zones:
		if String(z.get("kind", "")) == "service" and String(z.get("id", "")) == "clinic":
			var r: Rect2 = z["rect"]
			return Vector2(r.position.x + r.size.x * 0.6, r.get_center().y)
	return Vector2.INF


## 0.7.51.4: wake in the clinic – on the commercial level of a station, in a city's street. False if there is none.
func wake_in_clinic() -> bool:
	if not _avail.has("clinic"):
		return false
	go_level("clinic", "clinic")                                  # 0.7.51.11: in its recovery room
	return _clinic_spot() != Vector2.INF


## 0.7.51.3: the people out in the open on a hostile world wear suits and helmets too.
func _outside_look(lk: Dictionary, rng: RandomNumberGenerator, guard_look: bool = false) -> Dictionary:
	if not needs_helmet():
		return lk
	var l2 := lk.duplicate()
	l2["suit"] = "suit_mil_light" if guard_look else ["suit_civil", "suit_work", "suit_survey"][rng.randi() % 3]
	l2["helmet"] = true
	return l2


## 0.7.50.5: in a city (a station on the ground)?
func is_city() -> bool:
	return bool(station.get("city", false))


## 0.7.50.10: in a city or a settlement – a place on the ground with people, guards and its own time of day.
func is_town() -> bool:
	return bool(station.get("city", false)) or bool(station.get("settlement", false))


## 0.7.50.6: how much daylight the city has (0 night … 1 day).
func city_day() -> float:
	return float(station.get("day", 0.0)) if is_town() else 0.0


## How high up the tower bar is.
func tower_floor() -> int:
	return 140 + absi(hash(String(station.get("id", "")))) % 160


## Beyond the glass: the system's sky – its nebula, its star, the planet the station circles.
## In a city's tower bar (0.7.50.5): the city at night – towers, speeders, drones.
func _space_view(sys_id: int) -> void:
	if is_town():
		_neb.material = null
		_neb.color = Color(0.02, 0.02, 0.05)
		var body := Universe.find_body(sys_id, String(station.get("body", ""))) if sys_id >= 0 else {}
		_city_body = body
		var cst := CityStyle.of(station)
		var dk := city_day()
		var star := CityStyle.star_color(sys_id)
		if _window.size.x > 0.0 and level == "street":
			_canyon = CityCanyon.new()                 # 0.7.50.6: the street canyon above the shop fronts
			_canyon.setup(_window.size, body, cst, dk, hash(String(station.get("id", ""))) + 11, star)
			_sky.add_child(_canyon)
		elif _window.size.x > 0.0:
			_skyline = CitySkyline.new()
			_skyline.setup(_window.size, body, hash(String(station.get("id", ""))) + 3, _window.size.x + map.size_px().x * GroundMap.SCALE, cst, dk,
				star, CityStyle.rising(station, body) if not body.is_empty() else false)
			_sky.add_child(_skyline)
		return
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
	_star_spr = st_spr
	var pi := int(station.get("planet", -1))
	if pi >= 0 and pi < L["planets"].size():
		var p: Dictionary = L["planets"][pi]
		var lit := (star_at - planet_at).normalized()
		var ps := Celestial.make_planet_sprite(p, wh * 0.95, lit)
		ps.position = planet_at
		_sky.add_child(ps)
		_planet_spr = ps


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
	var plights: PadLights = null
	if not map.pad_rects.is_empty():
		plights = PadLights.new()                     # 0.7.50.15: the pads' lights and their status
		plights.rects = map.pad_rects
		plights.own = 0 if map.ship_at != Vector2.INF else -1
		_world.add_child(plights)
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
			_ship_shadow = sh
			_ship_spr = Sprite2D.new()
			_ship_spr.texture = tex
			_ship_spr.scale = Vector2.ONE * HANGAR_ART * GroundMap.SCALE
			_ship_spr.position = map.ship_at * GroundMap.SCALE
			_ship_base = _ship_spr.position
			_ship_spr.modulate = Color(0.82, 0.84, 0.9) if level == "hangar" else Color.WHITE   # one level down, in the shade
			_world.add_child(_ship_spr)
			if level in ["landing", "settlement"] and _lander:
				_hatch_node = Node2D.new()                # 0.7.50.15: its ramp, folding down and up
				_hatch_node.draw.connect(_draw_hatch)
				_world.add_child(_hatch_node)
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
	# 0.7.50.12: life in a settlement's economy area
	if not map.econ.is_empty():
		var el := EconLife.new()
		el.setup(map.econ)
		_world.add_child(el)
	# 0.7.50.10: the other landing drones coming and going on a settlement's free pads
	if map.pads.size() > 1:
		var pt := PadTraffic.new()
		var prng := RandomNumberGenerator.new()
		prng.seed = hash(String(station.get("id", ""))) + 77
		pt.setup(map.pads.slice(1), prng, Color(map.pal.get("terrain_b", Color(0.6, 0.55, 0.45))))
		_world.add_child(pt)
		if plights != null:
			plights.traffic = pt
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
		if String(p.get("role", "")) == "bartender":
			_bartender = w
		if String(p.get("role", "")) == "crew":
			w.marker = "!"
			w.set_meta("crew", int(p.get("crew", -1)))
		_sorted.add_child(w)
		people.append(w)
	if is_town():
		_add_guards(rng)
	var n := 5 + int(station.get("tier", 1)) * 2 if level in ["commercial", "street", "tower", "settlement"] else 2
	if level == "street":
		n += 6                                        # a city's street is busy
	for i in n:
		if map.wander.is_empty():
			break
		var w2 := Walker.new()
		w2.setup(map, _outside_look(ChibiArt.PilotArt.random_look(rng), rng), map.wander[i % map.wander.size()], true)
		_sorted.add_child(w2)
		people.append(w2)
	pilot = Walker.new()
	pilot.setup(map, pilot_look(), map.spawn, false)
	pilot.slung = _slung()
	_sorted.add_child(pilot)
	# light: lamps, neon, the window – added on top, the deck a little darker round them
	_lights = Node2D.new()
	_lights.z_index = 5
	var add_mat := CanvasItemMaterial.new()
	add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	# 0.7.50.6: a city's street lies under the open sky – night darkens it (the lamps and neon then glow), day lights
	# it (they hardly show); the tower bar's window lets in the sun by day
	if is_town() and level in ["street", "settlement", "alley", "minehead", "plaza"]:
		var tint := ColorRect.new()
		_tint = tint
		var mm := CanvasItemMaterial.new()
		mm.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
		tint.material = mm
		tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tx0 := DeckGen.LOBBY_X1 + 1                  # the street only – not the lift lobby, not inside the shops
		tint.position = Vector2(tx0, map.hull_top) * GroundMap.TILE * GroundMap.SCALE
		tint.size = Vector2(map.w - tx0, DeckGen.SHOP_CAP + 1 - map.hull_top) * GroundMap.TILE * GroundMap.SCALE
		if level in ["settlement", "alley", "minehead"]:  # all of it lies under the sky
			tint.position = Vector2.ZERO
			tint.size = map.size_px() * GroundMap.SCALE
		elif level == "plaza":                            # 0.7.53.19: the roof plaza – not over the view of the city
			tint.position = Vector2(0, map.window_rect.end.y) * GroundMap.TILE * GroundMap.SCALE
			tint.size = Vector2(map.w, map.h - map.window_rect.end.y) * GroundMap.TILE * GroundMap.SCALE
		_world.add_child(tint)
	if map.has_meta("dark"):
		var dk := ColorRect.new()                        # 0.7.53.3 (Luz): the sewers are dark – the lamps glow in it
		var dm := CanvasItemMaterial.new()
		dm.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
		dk.material = dm
		dk.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dk.color = map.get_meta("dark")
		dk.position = Vector2(0, map.hull_top) * GroundMap.TILE * GroundMap.SCALE
		dk.size = (map.size_px() - Vector2(0, map.hull_top * GroundMap.TILE)) * GroundMap.SCALE
		dk.z_index = 4
		_world.add_child(dk)
		_dark_rect = dk
	if not map.has_meta("dark"):
		_dark_rect = null
	_named_lights.clear()
	for l in map.lights:
		var lsp := _add_light(l, add_mat)
		if l.has("id"):
			_named_lights[String(l["id"])] = lsp           # 0.7.52.23: a light that can be switched (the laser cage's)
		if is_town() and level in ["street", "settlement", "alley", "minehead", "plaza"]:
			_city_lights.append([lsp, l, "street"])
		elif is_city() and level == "tower" and Color(l.get("col", Color.WHITE)).b > 0.9 and Color(l.get("col", Color.WHITE)).r < 0.5:
			lsp.scale *= 1.4                           # the light through the glass: sun, sunset or night
			_city_lights.append([lsp, l, "window"])
	for z in map.zones:
		var sp: Vector2 = z.get("sign", Vector2(-100, -100))
		if sp.x >= 0.0 and not z.get("vertical", false) and String(z.get("closed", "")) == "":
			_add_light({"pos": sp + Vector2(0, 6), "r": 30.0, "col": z.get("col", Color.WHITE), "a": 0.3}, add_mat)
	_world.add_child(_lights)
	if is_town():
		_apply_day(city_day(), true)
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


func _add_light(l: Dictionary, mat: Material) -> Sprite2D:
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
	return sp


## 0.7.50.9: city guards – some posted by the lifts and the ways in, some on patrol; more of them the safer the
## system. In their power's uniform, a visor down. Weapons stay holstered in the city (and the pilot's too).
func _add_guards(rng: RandomNumberGenerator) -> void:
	var g := CityStyle.guards(station)
	var sec := float(Universe.systems[_sys].get("security", 0.5)) if _sys >= 0 and _sys < Universe.systems.size() else 0.5
	var posts: Array = []
	for z in map.zones:
		if String(z.get("id", "")) in ["lift", "ship"] and (z["rect"] as Rect2).size.x > 0.0:
			var r: Rect2 = z["rect"]
			posts.append(r.get_center() + Vector2(r.size.x * 0.5 + 10.0, 14.0))
	var n_post := mini(posts.size(), 1 + int(round(sec * 2.0)))
	var n_patrol := int(round(sec * 2.5)) + (1 if level == "street" else 0)
	var made := 0
	for i in n_post + n_patrol:
		var lk := ChibiArt.PilotArt.random_look(rng)
		lk["outfit"] = 2
		lk["color1"] = int(g["c1"])
		lk["color2"] = int(g["c2"])
		lk["headgear"] = 2 if rng.randf() < 0.7 else 1
		# 0.7.51.10 (Luz): in a combat suit of their power's colours, the helmet on (a heavy one now and then at a post)
		lk["suit"] = "suit_mil_heavy" if i < n_post and rng.randf() < 0.3 else "suit_mil_light"
		lk["livery"] = CityStyle.key_for(station)
		lk["helmet"] = true
		var w := Walker.new()
		var at: Vector2
		if i < n_post:
			at = posts[i]
			if not map.free_at(at):
				continue
		elif not map.wander.is_empty():
			at = map.wander[rng.randi() % map.wander.size()]
		else:
			continue
		w.setup(map, lk, at, true)
		w.guard = true
		w.set_meta("guard", true)
		if i < n_post:
			w.stays = true
			w.dir = 0
		else:
			for k in 4:
				w.patrol.append(map.wander[rng.randi() % map.wander.size()])
		_sorted.add_child(w)
		people.append(w)
		made += 1


## The guard nearest the pilot, if near enough to speak to.
func _near_guard() -> Walker:
	if pilot == null:
		return null
	for w in people:
		if is_instance_valid(w) and w.guard and w.pos.distance_to(pilot.pos) < 22.0:
			return w
	return null


## 0.7.50.8: the day goes on while you are in a city – the sky outside, the street's light, the light through the
## bar's glass follow it (checked twice a second).
func _update_city_day(delta: float) -> void:
	_day_t -= delta
	if _day_t > 0.0 or _city_body.is_empty():
		return
	_day_t = 0.5
	_apply_day(CityStyle.daylight(station, _city_body))


func _apply_day(d: float, force: bool = false) -> void:
	if not force and absf(d - _day_seen) < 0.004:
		return
	_day_seen = d
	station["day"] = d
	var dk := CityStyle.dusk(d)
	var sunset := CityStyle.sunset_color(CityStyle.star_color(_sys))
	if _skyline != null:
		_skyline.set_day(d, CityStyle.rising(station, _city_body) if not _city_body.is_empty() else false)
	if _canyon != null:
		_canyon.set_day(d)
	if _tint != null:
		_tint.color = Color(0.58, 0.62, 0.82).lerp(Color.WHITE, smoothstep(0.0, 0.65, d)).lerp(Color(1.0, 0.78, 0.62), dk * 0.5)
	for cl in _city_lights:
		var sp: Sprite2D = cl[0]
		var l: Dictionary = cl[1]
		var a0: float = l.get("a", 0.3)
		var col0: Color = l.get("col", Color.WHITE)
		var a := a0
		var col := col0
		if String(cl[2]) == "street":
			a = a0 * lerpf(1.0, 0.4, smoothstep(0.4, 0.8, d))
		else:
			col = col0.lerp(Color(1.0, 0.9, 0.7), smoothstep(0.3, 0.7, d)).lerp(sunset, dk * 0.85)
			a = lerpf(a0, 0.3, d) + dk * 0.18
		sp.modulate = Color(col, a)
		for f in _flicker:
			if f[0] == sp:
				f[1] = a


func _process(delta: float) -> void:
	_scan_step(delta)
	_duct_step()
	if _mm != null and is_instance_valid(_mm):
		_poi_reveal()                                  # package 53a: the minimap fills in
		_mm.queue_redraw()
	_t += delta
	for f in _flicker:
		var ph: float = f[2]
		var k := 1.0
		if fposmod(_t * 0.7 + ph, 9.0) < 0.18:
			k = 0.35 if fposmod(_t * 31.0, 1.0) < 0.5 else 0.8
		(f[0] as Sprite2D).modulate.a = float(f[1]) * k
	if pilot == null:
		return
	if level == "clinic":
		_xray_step()
	_toast_t = maxf(_toast_t - delta, 0.0)
	if is_town():
		_update_city_day(delta)
	_update_dust(delta)
	_env_step(delta)
	_socket_step(delta)
	if not _collapsed:
		GameState.gear.health_step(delta)                # 0.7.53.16 (Luz): the body mends slowly, up to 75 %
	if _hatch_node != null and is_instance_valid(_hatch_node):
		_hatch_node.queue_redraw()
	if _touch >= 0.0:
		_touchdown_step(delta)
	elif _arrive > 0.0:
		_arrive -= delta
		pilot.step(Vector2.DOWN, delta, 0.8)
	elif not _ride.is_empty():
		_ride_step(delta)
	elif not _sink.is_empty():
		_sink_step(delta)
	elif input_enabled and talk == null and _lift_menu == null and minigame == null:
		var dir := Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
		if not _seat.is_empty():
			if dir.length() > 0.3:
				_stand_up()
		else:
			var run := Input.is_action_pressed("foot_run")
			if combat != null and combat.sneaking:
				run = false                                 # 0.7.52.21: sneaking – half speed, no running
			if combat == null or not combat.dodging():
				pilot.step(dir, delta, (1.6 if run else 1.0) * GameState.gear.speed_mult(run) * (0.5 if combat != null and combat.sneaking else 1.0) * _wade())      # 0.7.51.3: the suit's weight, a stimulant, a sprint booster
	else:
		pilot.moving = false
	if combat != null and not _collapsed and _touch < 0.0 and _ride.is_empty():
		_wires_step(delta)
		_turrets_step(delta)
		_hazards_step(delta)
		_fuses_step(delta)
		_drones_step(delta)
		_mission_step(delta)
		_hostage_step(delta)
		_cams_step(delta)
		_reinforce_step(delta)
		combat.step(delta * (WHEEL_SLOW if combat.wheel_open else 1.0), Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down") if input_enabled else Vector2.ZERO)
		_team_keys(delta)
		if _tab_held >= 0.0:
			var was := _tab_held
			_tab_held += delta
			if was < TAB_HOLD and _tab_held >= TAB_HOLD and combat.tactics != 0:
				combat.tactics = 0                        # held: the tactical view goes off
				Audio.play("ui_close", "tactical view off", -6.0)
		for di in 2:                                     # 0.7.52.19 (Luz): held – the kamikaze drone comes back
			if float(_drone_held[di]) >= 0.0:
				_drone_held[di] = float(_drone_held[di]) + delta
				if float(_drone_held[di]) >= TAB_HOLD:
					_drone_held[di] = -1.0
					var rmsg: String = combat.drone_recall(di)
					if rmsg != "":
						_say_toast(rmsg, 2.0)
		var helm: bool = pilot_look()["helmet"]
		if helm != bool(pilot.look.get("helmet", false)):
			pilot.look = pilot_look()                    # 0.7.51.10: the helmet closes for the fight
	_doors(delta)
	if not _seat.is_empty():
		zone = _seat
	else:
		zone = map.zone_at(pilot.pos)
	if zone.get("kind", "") == "label" or not _ride.is_empty() or talk != null:
		zone = {} if _seat.is_empty() else _seat
	if zone.is_empty() and is_town() and _ride.is_empty() and talk == null and _near_guard() != null:
		zone = {"kind": "guard", "id": "guard", "title": String(CityStyle.guards(station)["name"]), "rect": Rect2()}
	_camera(delta)
	_prompt.text = "" if talk != null or talk_menu != null or _lift_menu != null else _prompt_text(zone)     # 0.7.52.13: events go to the log
	_signs.queue_redraw()


func _prompt_text(z: Dictionary) -> String:
	if z.is_empty():
		return ""
	var key := Keybinds.key_text("interact")
	match String(z["kind"]):
		"exit", "lift", "charge":
			return "[%s] %s" % [key, z["title"]]
		"soon":
			return String(z["title"])
		"socket":                                       # 0.7.53.16
			var sk: Dictionary = map.explore[int(z["i"])]
			if float(sk.get("charge", 0.0)) <= 0.0:
				return "A power socket – drawn dry"
			return ("Charging…  %d / %d" % [int(GameState.gear.energy), int(GameState.gear.totals()["energy"])]) if charging() \
				else "[hold %s] Power socket – charge the suit (%d left in it)" % [key, int(sk["charge"])]
		"crew":
			return "[%s] Talk to %s – looking for a post" % [key, z["title"]]
		"seat":
			return "[%s] Stand up" % key if not _seat.is_empty() else "[%s] %s" % [key, z["title"]]
		"guard":
			return "[%s] %s – weapons stay holstered in the city" % [key, z["title"]]
		"jukebox":
			return "[%s] Jukebox – %s" % [key, ("next track (now: %s)" % Jukebox.track_name(track)) if track >= 0 else "play some music"]
	if String(z.get("closed", "")) != "":
		return "%s – closed: %s" % [z["title"], z["closed"]]
	return "[%s] %s%s" % [key, z["title"], ("  –  " + String(z["corp"])) if String(z.get("corp", "")) != "" else ""]


func _unhandled_input(event: InputEvent) -> void:
	if minigame != null:
		return                                         # 0.7.52.22: the torch or the hack has the keys
	if _lift_menu != null:
		if event.is_action_pressed("menu_back", false, true):
			get_viewport().set_input_as_handled()
			_close_lift_menu()
		elif event is InputEventKey and event.is_pressed() and not event.is_echo():
			var k := (event as InputEventKey).keycode
			var keys: Array = _lift_menu.get_meta("keys", [])
			var n := k - KEY_1
			if n >= 0 and n < keys.size():
				get_viewport().set_input_as_handled()
				(keys[n] as Callable).call()
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
	if combat != null and _ride.is_empty() and _touch < 0.0 and not _collapsed:
		if event.is_action_pressed("foot_tactics", false, true):
			get_viewport().set_input_as_handled()
			if not event.is_echo():
				_tab_held = 0.0
			return
		if event.is_action_released("foot_tactics", true):
			get_viewport().set_input_as_handled()
			if _tab_held >= 0.0 and _tab_held < TAB_HOLD:
				combat.cycle_tactics()                    # a tap: your sight, the target's sight, yours …
			_tab_held = -1.0
			return
		if event.is_action_pressed("foot_zoom", false, true) and combat.tactics == 0:
			get_viewport().set_input_as_handled()
			near_zoom = 1.0 if near_zoom > 1.0 else ZOOM_NEAR           # 0.7.52.13: in the fight – near and back
			return
		if event.is_action_pressed("foot_zoom", false, true) and combat.tactics != 0:
			get_viewport().set_input_as_handled()
			tac_zoom = 1.0 if tac_zoom < 1.0 else TAC_ZOOM_OUT         # 0.7.52.8: out and back on its key
			return
		if event.is_action_pressed("foot_target_near", false, true):
			get_viewport().set_input_as_handled()
			combat.nearest_target()                      # 0.7.52.9 (Luz): Shift+R – the nearest foe
			return
		if event.is_action_pressed("foot_sneak", false, false):
			get_viewport().set_input_as_handled()
			_say_toast(combat.toggle_sneak(), 2.5)         # 0.7.52.21 (Luz): Ctrl – sneaking on / off
			return
		# 0.7.52.20 (Luz): V – a tap picks whom the orders go to, held: the command wheel (time runs slow)
		if event.is_action_pressed("foot_team", false, true):
			get_viewport().set_input_as_handled()
			if not combat.allies.is_empty():
				_team_held = 0.0
			else:
				_say_toast("Nobody came along – pick your ground team in the Pilot window (Gear).", 2.5)
			return
		if event.is_action_released("foot_team", false) and _team_held >= 0.0:
			get_viewport().set_input_as_handled()
			if combat.wheel_open:
				var pick := GroundCombat.wheel_pick(wheel_centre(), get_viewport().get_mouse_position())
				combat.wheel_open = false
				if pick != "":
					var who = null if combat.team_sel >= combat.allies.size() else combat.allies[combat.team_sel]
					_say_toast(combat.order(who, pick), 2.5)
			else:
				combat.team_sel = (combat.team_sel + 1) % (combat.allies.size() + 1)
				_say_toast("Orders to: %s" % ("all" if combat.team_sel >= combat.allies.size() else String(combat.allies[combat.team_sel]["name"])), 1.5)
			_team_held = -1.0
			return
		# 0.7.52.20: the use key held beside a member down brings them back
		if event.is_action_pressed("interact", false, false) and combat.revive_near() != null:
			get_viewport().set_input_as_handled()
			_revive = 0.0
			combat.reviving = combat.revive_near()
			return
		# 0.7.52.11 C, 0.7.52.18 Shift+C the second drone; 0.7.52.19 (Luz): over a kamikaze drone in the air a tap sends it,
		# holding the key calls it back
		for di in 2:
			var act := "foot_drone" if di == 0 else "foot_drone_2"
			if event.is_action_pressed(act, false, true):
				get_viewport().set_input_as_handled()
				if combat.drone_kamikaze_up(di):
					_drone_held[di] = 0.0
				else:
					_say_toast(combat.drone_command(di), 2.0)
				return
		for di2 in 2:
			if event.is_action_released("foot_drone" if di2 == 0 else "foot_drone_2", false) and float(_drone_held[di2]) >= 0.0:
				get_viewport().set_input_as_handled()
				_drone_held[di2] = -1.0
				_say_toast(combat.drone_command(di2), 2.0)       # a tap: away at the target
				return
		if event.is_action_pressed("foot_grenade", false, false):
			get_viewport().set_input_as_handled()
			if not combat.grenade_down():
				_say_toast("No grenade in your grenade places.", 2.0)
			return
		if event.is_action_released("foot_grenade", false) and combat.gr_hold >= 0:
			get_viewport().set_input_as_handled()
			var gmsg := combat.grenade_up()
			if gmsg != "":
				_say_toast(gmsg, 1.5)
			return
		if event.is_action_pressed("foot_target", false, true):
			get_viewport().set_input_as_handled()
			combat.next_target()
			return
		if event.is_action_pressed("foot_dodge", false, true):
			get_viewport().set_input_as_handled()
			combat.dodge(Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down"))
			return
		if event.is_action_pressed("foot_swap", false, true):
			get_viewport().set_input_as_handled()
			_say_toast(combat.swap_weapon(), 2.0)
			return
	if event.is_action_pressed("interact", false, false):
		get_viewport().set_input_as_handled()
		use()
	elif _ride.is_empty() and _touch < 0.0:
		if buddy != null and combat == null:
			for di in 2:                                   # 0.7.52.25: C / Shift+C – your drones up and back
				if event.is_action_pressed("foot_drone" if di == 0 else "foot_drone_2", false, true):
					get_viewport().set_input_as_handled()
					_say_toast(buddy.command(di), 2.0)
					return
		for n in mini(4, GameState.gear.belt.size()):            # 0.7.52.9: the belt on its own (rebindable) keys
			if event.is_action_pressed("foot_belt_%d" % (n + 1), false, false):
				get_viewport().set_input_as_handled()
				use_belt(n)
				return
		if event.is_action_pressed("foot_grenade", false, false):
			get_viewport().set_input_as_handled()
			_say_toast("No fighting here – the grenades stay on your suit.", 2.5)


## 0.7.52.5: where the mouse points on the map (art px).
func mouse_art() -> Vector2:
	return (get_viewport().get_mouse_position() - _world.position) / (GroundMap.SCALE * zoom)


## 0.7.51.3: a belt place on its number key.
func use_belt(n: int) -> void:
	var b = GameState.gear.belt[n] if n < GameState.gear.belt.size() else {}
	if b is Dictionary and not (b as Dictionary).is_empty():
		var bid := String(b["id"])
		if bid.begins_with("tl_scanner") and _scan_start(n):
			return                                     # 0.7.52.24: scanning (hold the key)
		if bid.begins_with("tl_cloak"):
			_say_toast(combat.cloak(bid) if combat != null else "Nothing to hide from here.", 2.5)     # 0.7.52.25
			return
		if bid.begins_with("tl_cutter") and not zone.is_empty() and String(zone.get("kind", "")) == "explore":
			explore_use(zone)                          # 0.7.52.22: the torch at a box
			return
	var msg: String = GameState.gear.use_belt(n)
	if msg != "":
		_say_toast(msg, 2.5)
		Audio.play("ui_click", "belt")


# ---------------------------------------------------------------- 0.7.52.22 (package 52b): tools at work

## The things to work on placed in this map get their nodes (call after the map is built or a thing added).
func spawn_explore() -> void:
	for n in _sorted.get_children():
		if n.has_meta("explore"):
			n.queue_free()
	for i in map.explore.size():
		var nd := ExploreNode.new()
		nd.view = self
		nd.i = i
		nd.set_meta("explore", true)
		nd.position = (map.explore[i]["pos"] as Vector2) * GroundMap.SCALE
		_sorted.add_child(nd)


func add_explore(kind: String, pos: Vector2, extra: Dictionary = {}) -> Dictionary:
	var d := ExploreNode.add(map, kind, pos, extra)
	spawn_explore()
	return d


## The belt piece of a family ("tl_cutter") – its id, or "".
func belt_tool(fam: String) -> String:
	for b in GameState.gear.belt:
		if b is Dictionary and not (b as Dictionary).is_empty() and String(b["id"]).begins_with(fam):
			return String(b["id"])
	return ""


func explore_use(z: Dictionary) -> bool:
	var d: Dictionary = map.explore[int(z["i"])]
	match String(d["kind"]):
		"panel":
			if String(d["state"]) == "shut":
				var tool := belt_tool("tl_cutter")
				if tool == "":
					_say_toast("It is welded shut – you need a cutting torch on your belt.", 3.0)
					return true
				var cg = CutGame.new()
				cg.inside = String(d["inside"])
				cg.shape = String(d["shape"])
				cg.label = String(d["label"])
				cg.skill = GameState.skill_level("engineering")
				cg.quality = float(ChibiArt.GearData.stats(tool).get("strength", 1.0))
				cg.finished.connect(func(res: String): _cut_done(d, res))
				_open_game(cg)
			elif String(d["inside"]) == "button":
				_explore_effect(d, "door")
			else:
				_open_hack(d)
			return true
		"terminal":
			_open_hack(d)
			return true
		"vent":
			if String(d["state"]) != "shut":
				_say_toast("The shaft is open – crawl in.", 2.0)
				return true
			var tool2 := belt_tool("tl_cutter")
			if tool2 == "":
				_say_toast("The grille is welded shut – you need a cutting torch on your belt.", 3.0)
				return true
			var vg = CutGame.new()
			vg.inside = "duct"
			vg.shape = "rounded"
			vg.label = String(d.get("label", "VENT-06"))
			vg.skill = GameState.skill_level("engineering")
			vg.quality = float(ChibiArt.GearData.stats(tool2).get("strength", 1.0))
			vg.finished.connect(func(res: String): _cut_done(d, res))
			_open_game(vg)
			return true
		"crate":
			if String(d["state"]) != "shut":
				_say_toast("Empty.", 1.5)
				return true
			if bool(d.get("welded", false)):
				var t3 := belt_tool("tl_cutter")
				if t3 == "":
					_say_toast("Welded shut – you need a cutting torch on your belt.", 3.0)
					return true
				var lg = CutGame.new()
				lg.inside = "loot"
				lg.shape = ["rounded", "hex", "notched", "trapezoid"][int(d.get("seed", 0)) % 4]
				lg.label = "CACHE-%02d" % (int(d.get("seed", 0)) % 90 + 10)
				lg.skill = GameState.skill_level("engineering")
				lg.quality = float(ChibiArt.GearData.stats(t3).get("strength", 1.0))
				lg.finished.connect(func(res: String): _cut_done(d, res))
				_open_game(lg)
				return true
			_loot(d)
			return true
		"ruin_gate":
			if String(d["state"]) == "open":
				_say_toast("Open – go in.", 1.5)
			elif String(d.get("lock", "open")) == "open":
				open_door(d)                               # it gives way to a push
			else:
				_say_toast("Sealed – %s." % ("its panel is on the wall beside it (cutting torch)" if String(d["lock"]) == "panel" else "the computer by it opens it (E-Breach)"), 3.0)
			return true
		"breach":
			if String(d["state"]) == "open":
				_say_toast("Open – climb in.", 1.5)
				return true
			var t6 := belt_tool("tl_cutter")
			if t6 == "":
				_say_toast("A buckled plate is wedged in it – you need a cutting torch on your belt.", 3.0)
				return true
			var bg = CutGame.new()
			bg.inside = "duct"
			bg.shape = "notched"
			bg.label = "HULL-%02d" % (int(d.get("seed", 0)) % 90 + 10)
			bg.skill = GameState.skill_level("engineering")
			bg.quality = float(ChibiArt.GearData.stats(t6).get("strength", 1.0))
			bg.finished.connect(func(res: String): _cut_done(d, res))
			_open_game(bg)
			return true
		"airlock", "pirate_gate":
			_say_toast("Sealed – its terminal beside it opens it (E-Breach)." if String(d["state"]) != "open" else "Open – go in.", 2.5)
			return true
		"blackbox":
			if String(d["state"]) != "taken":
				d["state"] = "taken"                        # 0.7.53.6 (Luz): the crash site's target
				_poi_target_done(d)
			else:
				_say_toast("An empty rack.", 1.5)
			return true
		"generator":
			_open_power_menu(d)
			return true
		"seal_panel":
			var lkd: Dictionary = map.explore[int(d.get("leak", 0))]
			if String(lkd["state"]) == "open":
				lkd["state"] = "sealed"                    # 0.7.53.20 (Luz): the emergency bulkhead seals the torn module
				_say_toast("The emergency plate slams over the hole – the air comes back, it warms up.", 3.0)
				Audio.play("dock_clamp", "bulkhead sealed", -2.0)
			else:
				_say_toast("Sealed.", 1.2)
			return true
		"keycard":
			if String(d["state"]) != "taken":
				d["state"] = "taken"                       # 0.7.53.19 (Luz): the lifts' key card
				_site["card"] = true
				_say_toast("A key card – the lifts down will take you now.", 3.0)
				Audio.play("ui_buy", "key card", -6.0)
			return true
		"vault_door":
			_say_toast({"shut": "The vault door – its lock wants a hack at the terminal beside it, then the drill.",
				"drilling": "The drill is biting – hold out.", "open": "Open."}.get(String(d["state"]), ""), 2.5)
			return true
		"cells":
			if not bool(d.get("prisoner", false)) or String(d["state"]) == "open":
				_say_toast("Empty cells.", 1.2)
			elif String(d["state"]) == "picking":
				_say_toast("Still picking the lock…", 1.2)
			else:
				d["state"] = "picking"                     # 53c: a few seconds at the lock
				_fuses[map.explore.find(d)] = 3.0
				_say_toast("You work at the cell's lock…", 2.0)
			return true
		"crank_door":
			if String(d["state"]) == "open":
				_say_toast("Open.", 1.2)
			elif String(d["state"]) == "cranking":
				_say_toast("Still cranking…", 1.2)
			else:
				d["state"] = "cranking"                    # 0.7.53.9 (Luz): by hand – slow and loud
				_fuses[map.explore.find(d)] = 4.0
				_say_toast("You crank the door open by hand – it takes a while, and it is loud.", 2.5)
				Audio.play("dock_clamp", "crank door", -6.0)
				if combat != null:
					for f in combat.alive():
						if (f["w"] as Walker).pos.distance_to(pilot.pos) < 300.0:
							combat._wake(f)
			return true
		"fuse_box":
			if String(d["state"]) == "open":
				_say_toast("The fuse is in – the door has power.", 1.5)
			else:
				d["state"] = "open"                        # 0.7.53.9: a spare fuse from the box's own clip
				if d.has("door"):
					open_door(map.explore[int(d["door"])])
				_say_toast("You put a spare fuse in – the door slides open.", 2.5)
			return true
		"mine_gen":
			if String(d["state"]) == "open":
				_say_toast("It runs – the cage has power.", 1.5)
			else:
				d["state"] = "open"                        # 0.7.53.7 (Luz): pull the cord – loud
				if d.has("lift"):
					map.explore[int(d["lift"])]["state"] = "active"
				_say_toast("The generator coughs, then roars – the cage's lamp turns green. Everyone down here heard that.", 3.0)
				Audio.play("module_on", "mine generator", 0.0)
				if combat != null:
					for f in combat.alive():
						if (f["w"] as Walker).pos.distance_to(pilot.pos) < 420.0:
							combat._wake(f)
			return true
		"mine_gate":
			if String(d["state"]) == "open":
				_say_toast("Open – go down.", 1.5)
				return true
			var t7 := belt_tool("tl_cutter")
			if t7 == "":
				_say_toast("Chained shut – you need a cutting torch on your belt.", 3.0)
				return true
			var mg = CutGame.new()
			mg.inside = "duct"
			mg.shape = "rounded"
			mg.label = "GATE-%02d" % (int(d.get("seed", 0)) % 90 + 10)
			mg.skill = GameState.skill_level("engineering")
			mg.quality = float(ChibiArt.GearData.stats(t7).get("strength", 1.0))
			mg.finished.connect(func(res: String): _cut_done(d, res))
			_open_game(mg)
			return true
		"vein":
			if String(d["state"]) == "taken":
				_say_toast("Only an empty socket in the rock.", 1.5)
			elif belt_tool("tl_cutter") == "":
				_say_toast("Set in solid rock – you need a cutting torch to cut it out.", 2.5)
			else:
				d["state"] = "taken"                       # 0.7.53.7 (Luz): the mine's target
				_poi_target_done(d)
			return true
		"rubble":
			if String(d["state"]) == "open":
				return true
			if String(d["state"]) == "charged":
				_say_toast("The charge is set – get back!", 1.5)
				return true
			if GameState.gear.count("gr_frag") <= 0:
				_say_toast("You need a frag grenade as a charge – or set off a box of explosives near it.", 3.0)
				return true
			_take_one("gr_frag")
			d["state"] = "charged"
			_fuses[map.explore.find(d)] = 3.0
			_say_toast("Charge set – three seconds. Get back!", 2.0)
			return true
		"bulkhead":
			_say_toast("Jammed – no power. The box beside it, or the emergency generator." if String(d["state"]) != "open" else "Open.", 2.5)
			return true
		"rust_door", "grate_door", "steel_door":
			_say_toast("Sealed – its panel is beside it, or a computer somewhere opens it." if String(d["state"]) != "open" else "Open.", 2.5)
			return true
		"valve":
			if String(d["state"]) == "open":
				_say_toast("Turned all the way – the tunnel is drained.", 2.0)
			else:
				d["state"] = "open"                        # 0.7.53.3: by hand – loud: the pipes bang and knock
				_drain(d.get("flood", []))
				if combat != null:
					for f in combat.alive():
						if (f["w"] as Walker).pos.distance_to(pilot.pos) < 360.0:
							combat._wake(f)
			return true
		"alarm":
			if String(d["state"]) == "cut":
				_say_toast("Its wires hang loose – it will not ring.", 2.0)
			elif String(d["state"]) == "ringing":
				_say_toast("Too late – it is ringing.", 2.0)
			elif belt_tool("tl_cutter") == "":
				_say_toast("You need a cutting torch on your belt to cut its wires.", 2.5)
			else:
				d["state"] = "cut"                         # 0.7.53.5: quietly
				GameState.skill_xp("engineering", 2.0)
				_say_toast("You cut the alarm's wires – it will not ring now.", 2.5)
				Audio.play("dock_clamp", "alarm cut", -10.0)
			return true
		"tripwire":
			if String(d["state"]) == "shut":
				d["state"] = "disarmed"                    # 0.7.53.3: carefully – the pin back in, the wire cut
				GameState.skill_xp("engineering", 2.0)
				var left: int = GameState.gear.add_item("gr_frag", 1)
				_say_toast("Disarmed – you cut the wire%s." % (" and keep its grenade" if left == 0 else ""), 2.5)
			return true
		"blastdoor":
			_say_toast("Sealed – its release is in the maintenance box beside it." if String(d["state"]) != "open" else "Open.", 2.5)
			return true
		"tablet", "relic", "monolith":
			_say_toast("Hold the scanner's belt key here to scan it." if belt_tool("tl_scanner") != "" else "You need a scanner on your belt to read it.", 3.0)
			return true
		"cracked_wall":
			if String(d["state"]) == "open":
				return true
			if belt_tool("tl_cutter") == "":
				_say_toast("A cracked wall – it sounds hollow behind it. A cutting torch on your belt would get through.", 3.0)
				return true
			d["state"] = "open"                            # 0.7.53.24 (Luz): through the cracked wall – the hidden cache
			for ht in d["tiles"]:
				map.set_t(int(ht[0]), int(ht[1]), GroundMap.T.FLOOR, map.floor_kind[int(ht[1]) * map.w + int(ht[0])])
			map._astar = null
			if combat != null:
				combat._build_cover()
			_say_toast("The torch bites, the stones fall in – a hidden chamber behind them.", 3.0)
			Audio.play("explosion_small", "wall falls in", -8.0)
			return true
		"symbol_pillar":
			if String(d["state"]) == "open":
				_say_toast("The signs glow – it is open.", 1.5)
			else:
				_symbol_menu(d)                            # 0.7.53.23 (Luz): the symbol puzzle
			return true
	return false


func _open_game(g: Control) -> void:
	_close_game()
	_game_layer = CanvasLayer.new()
	_game_layer.layer = 70
	add_child(_game_layer)
	minigame = g
	_game_layer.add_child(g)
	pilot.moving = false


func _close_game() -> void:
	if _game_layer != null and is_instance_valid(_game_layer):
		_game_layer.queue_free()
	_game_layer = null
	minigame = null


func _cut_done(d: Dictionary, res: String) -> void:
	_close_game()
	if res == "":
		_say_toast("You leave the box – the cut is lost.", 2.0)
		return
	d["state"] = "open"
	if res == "loot":
		_loot(d)
		return
	if String(d["kind"]) == "mine_gate":
		_say_toast("The chain parts – the gate swings open.", 2.5)                       # 0.7.53.7
		Audio.play("dock_clamp", "mine gate cut", -4.0)
		return
	if String(d["kind"]) == "breach":
		_say_toast("The plate drops away – the breach is open. Climb in.", 2.5)       # 0.7.53.6
		Audio.play("dock_clamp", "breach cut open", -4.0)
		return
	if res == "duct":
		open_vent(d)
		return
	if res == "button":
		_explore_effect(d, String(d.get("effect", "door")))
	else:
		_open_hack(d)


func _open_hack(d: Dictionary) -> void:
	if float(d.get("locked_t", 0.0)) > Time.get_ticks_msec() * 0.001:
		_say_toast("Locked out – it will not let you in for a while.", 2.5)
		return
	# 0.7.52.24 (Luz): it takes an E-Breach from your belt – used up with the try
	var bi := -1
	for i in GameState.gear.belt.size():
		var b = GameState.gear.belt[i]
		if b is Dictionary and not (b as Dictionary).is_empty() and String(b["id"]) == "cs_breach" and bi < 0:
			bi = i
	if bi < 0:
		_say_toast("You need an E-Breach on your belt to jack in.", 3.0)
		return
	var bp: Dictionary = GameState.gear.belt[bi]
	bp["n"] = int(bp["n"]) - 1
	if int(bp["n"]) <= 0:
		GameState.gear.belt[bi] = {}
	if String(d.get("state", "")) == "hacked":
		_say_toast("You are already in – it does what you told it.", 2.0)
	var hg = HackGame.new()
	hg.level = int(d.get("level", 1))
	hg.skill = GameState.skill_level("electronics")
	hg.actions = d.get("actions", ["door", "data"])
	hg.title = "TERMINAL" if String(d["kind"]) == "terminal" else String(d.get("label", "TERMINAL"))
	hg.seed_n = int(d.get("seed", 1)) + int(d.get("tries", 0))
	hg.finished.connect(func(res: String): _hack_done(d, res))
	_open_game(hg)


func _hack_done(d: Dictionary, res: String) -> void:
	_close_game()
	d["tries"] = int(d.get("tries", 0)) + 1
	match res:
		"":
			_say_toast("You pull out.", 1.5)
		"fail":
			d["locked_t"] = Time.get_ticks_msec() * 0.001 + 60.0
			_say_toast("Traced – the alarm goes!", 3.0)
			Audio.play("warn", "hack failed: alarm")
			raise_alarm()                                  # 0.7.53.5: a real alarm, where there is one
			if combat != null:
				for f in combat.alive():
					if (f["w"] as Walker).pos.distance_to(pilot.pos) < 600.0:
						combat._wake(f)
		_:
			d["state"] = "hacked" if String(d["kind"]) == "terminal" else d["state"]
			d["hacked"] = true
			GameState.skill_xp("electronics", 3.0)
			_explore_effect(d, res)


## What a button or a hacked terminal does. (0.7.52.22: the doors, lights, turrets and cameras of the places to
## explore come with package 53 – here it is said and logged.)
func _explore_effect(d: Dictionary, what: String) -> void:
	var txt := ""
	match what:
		"door":
			d["door_open"] = true
			txt = "A door unlocks somewhere close – clunk."
			if d.has("door"):
				var dd2: Dictionary = map.explore[int(d["door"])]
				open_door(dd2)                                  # 0.7.52.23: its blast door slides open
				txt = {"ruin_gate": "The entrance grinds open – fog spills out.", "rust_door": "The old door shrieks open.",
					"grate_door": "The grate swings open with a rusty squeal.", "steel_door": "The code lock blinks green – the steel door slides open.",
					"bulkhead": "The bulkhead grinds open on the last of its power.", "airlock": "The airlock hisses – its hatch slides open.",
					"crank_door": "The security door slides open.", "pirate_gate": "The hangar gate grinds apart."}.get(String(dd2["kind"]), "The blast door grinds open.")
			Audio.play("dock_clamp", "door released", -4.0)
		"lasers":
			if d.has("cage"):
				cage_off(map.explore[int(d["cage"])])
			txt = "The laser cage goes dark."
			Audio.play("module_off", "lasers off", -4.0)
		"crystals":
			if d.has("cage"):
				cage_off(map.explore[int(d["cage"])])
			txt = "The crystals sink to the floor – their lightning dies."
			Audio.play("shield_down", "crystal guardians off", -4.0)
		"drain":
			_drain(d.get("flood", []))                     # 0.7.53.3: the pumps run
			txt = ""
		"lift":
			txt = "Somewhere in the ruin something wakes – the ancient lift hums, its crystals light up."
			for al in map.explore:
				if String(al["kind"]) == "ancient_lift" and String(al["state"]) == "dormant":
					al["state"] = "active"                     # 0.7.53.4
			Audio.play("module_on", "ancient lift wakes", -2.0)
		"list":
			txt = ""
			_poi_target_done(d)
		"logs":
			txt = ""
			_poi_target_done(d)                            # 0.7.53.20: the research station's logs
		"restart":
			txt = ""
			_restart_reactor(d)                            # 0.7.53.3: the dealer's client list – the site's target
		"emp":
			txt = "A trap! An EMP – shields, drones and energy weapons are down for a moment."
			if combat != null:
				combat.emp(GroundCombat.EMP_TIME)
			Audio.play("shield_down", "EMP trap", 0.0)
		"cache":
			var cr := 40 + int(d.get("seed", 0)) % 120
			GameState.credits += cr
			txt = "Behind the flap: a forgotten stash – %d cr." % cr
		"power":
			d["power_off"] = not bool(d.get("power_off", false))
			txt = "The power goes %s." % ("off" if bool(d["power_off"]) else "back on")
			Audio.play("module_off" if bool(d["power_off"]) else "module_on", "power switched", -4.0)
		"turrets":
			txt = "The turrets power down."
			for tu in map.explore:
				if String(tu["kind"]) == "turret":
					tu["state"] = "off"                        # 0.7.53.5
		"cameras":
			txt = "The cameras go blind – on every level."
			_site["cams_off"] = true                       # 0.7.53.19 (Luz)
			for cm in map.explore:
				if String(cm["kind"]) == "camera":
					cm["state"] = "off"
			Audio.play("module_off", "cameras off", -4.0)
		"beams":
			txt = "The light barriers go dark – on every level."
			_site["beams_off"] = true                      # 0.7.53.19 (Luz)
			for lb in map.explore:
				if String(lb["kind"]) == "laser_gate":
					lb["state"] = "off"
			Audio.play("module_off", "light barriers off", -4.0)
		"vault":
			if d.has("door"):
				var vd: Dictionary = map.explore[int(d["door"])]
				if String(vd["state"]) == "shut":
					vd["state"] = "drilling"                 # 0.7.53.19 (Luz): the drill bites – it takes a while, and it is loud
					_fuses[int(d["door"])] = VAULT_DRILL
					if combat != null:
						for f in combat.alive():
							if (f["w"] as Walker).pos.distance_to(vd["pos"]) < 360.0:
								combat._wake(f)
					Audio.play("w_autocannon", "vault drill", -8.0)
			txt = "The lock gives – the drill bites into the vault door. Hold out (%d s)." % int(VAULT_DRILL)
		"data":
			var n := 4 + int(d.get("seed", 0)) % 5
			GameState.research_data += n
			txt = "Data downloaded – %d research data." % n
			if level == "dungeon" and (depth == PoiData.levels(String(_site.get("theme", "precursor"))) - 1 or (String(_site.get("theme", "")) == "corp" and depth == 1)):
				_mission_event("data")                     # package 53c: the spy's goal (0.7.53.19: a tower's – the security centre)
	if txt != "" and not (what == "door" and d.has("door") and String(map.explore[int(d["door"])]["kind"]) == "ruin_gate"):
		_say_toast(txt, 3.0)                           # (the toast goes into the event log too; the gate says its own)


# ---------------------------------------------------------------- package 53a: sites to explore

## A crate opened: credits and a thing or two from the site's theme into your pockets.
func _loot(d: Dictionary) -> void:
	d["state"] = "open"
	var th: Dictionary = PoiData.THEMES.get(String(d.get("theme", _site.get("theme", "precursor"))), PoiData.THEMES["precursor"])
	var rng := RandomNumberGenerator.new()
	rng.seed = int(d.get("seed", 1))
	var cr := rng.randi_range(int(th["credits"][0]), int(th["credits"][1]))
	if bool(d.get("safe", false)):
		cr *= 3                                          # 0.7.53.3: the dealer's safe
	if bool(d.get("hidden", false)):
		cr *= 3                                          # 0.7.53.24: a hidden cache
	GameState.credits += cr
	var got: Array = ["%d cr" % cr]
	if th.has("research"):
		var rs := rng.randi_range(int(th["research"][0]), int(th["research"][1]))
		GameState.research_data += rs
		got.append("%d research data" % rs)                 # 0.7.53.2: scan data
	var mr := PoiData.museum_roll(String(d.get("theme", _site.get("theme", "precursor"))), rng)
	if mr == "" and bool(d.get("museum", false)) and rng.randf() < (0.8 if bool(d.get("hidden", false)) else 0.5):
		var ml: Array = PoiData.MUSEUM_RELICS.get(String(d.get("theme", "")), [])
		if not ml.is_empty():
			mr = String(ml[rng.randi() % ml.size()][0])          # 0.7.53.7: the buried cache – half the time a find
	if mr != "":
		GameState.museum_find(mr)
		got.append("a find for the Museum: %s" % PoiData.museum_name(mr))
	if bool(d.get("target", false)):
		call_deferred("_poi_target_done", d)              # 0.7.53.11: the captain's strongbox
	for i in rng.randi_range(1, 2):
		var id: String = th["loot"][rng.randi() % th["loot"].size()]
		var n := rng.randi_range(1, 2)
		var left: int = GameState.gear.add_item(id, n)
		if left < n:
			got.append("%s ×%d" % [String(ChibiArt.GearData.base(id).get("name", id)), n - left])
		else:
			got.append("(no room for %s)" % String(ChibiArt.GearData.base(id).get("name", id)))
	Audio.play("ui_buy", "crate looted", -6.0)
	_say_toast("Cache opened: %s." % ", ".join(PackedStringArray(got)), 3.5)


## The site's target done: it is used up (it will be gone from the planet map); the way back is open.
func _poi_target_done(d: Dictionary) -> void:
	if not bool(_site.get("poi", false)):
		return
	if bool(_site.get("mission", false)):
		_mission_event("target")                         # package 53c: the job pays at its giver
		if bool(_site.get("goal_done", false)) or String(_site.get("goal", "")) in ["bounty_foot", "spy", "rescue"]:
			if String(_site.get("goal", "")) in ["bounty_foot", "spy", "rescue"]:
				_say_toast("Not what the job is about – but it is yours.", 2.5)
			return
	GameState.poi_use(String(_site.get("id", "")))
	if String(_site.get("theme", "")) == "pirate":
		var pay3 := 900 + int(d.get("seed", 0)) % 700              # 0.7.53.11: the Red Talons' hoard
		GameState.credits += pay3
		_say_toast("The captain's strongbox – %d cr and the Red Talons' bounty data. Get out before they regroup." % pay3, 5.5)
		Audio.play("lock_acquired", "site target done", -2.0)
		return
	if String(_site.get("theme", "")) == "darkones":
		var dl: Array = PoiData.MUSEUM_RELICS["darkones"]
		var dr := String(dl[int(d.get("seed", 0)) % dl.size()][0])      # 0.7.53.23: a relic of the Dark Ones
		GameState.museum_find(dr)
		GameState.research_data += 12
		_say_toast("You take it from the altar: %s – a find for the Museum. Below you, in the pit, something shifts in its sleep." % PoiData.museum_name(dr), 6.0)
		Audio.play("lock_acquired", "site target done", -2.0)
		return
	if String(_site.get("theme", "")) == "research":
		var pay5 := 500 + int(d.get("seed", 0)) % 400                # 0.7.53.20: the research logs
		GameState.credits += pay5
		GameState.research_data += 14
		_say_toast("The research logs are yours – 14 research data, %d cr from a buyer. Back out when you like." % pay5, 5.5)
		Audio.play("lock_acquired", "site target done", -2.0)
		return
	if String(_site.get("theme", "")) == "corp":
		var pay4 := 1800 + int(d.get("seed", 0)) % 1200             # 0.7.53.19: the corporate vault
		GameState.credits += pay4
		GameState.research_data += 6
		_say_toast("The vault's main box – %d cr and the company's research data. Now get out." % pay4, 5.5)
		Audio.play("lock_acquired", "site target done", -2.0)
		return
	if String(_site.get("theme", "")) == "maint":
		var pay2 := 600 + int(d.get("seed", 0)) % 400              # 0.7.53.9: the city pays for its power back
		GameState.credits += pay2
		_say_toast("The reactor hums – the power is back, level by level the lights come on. %d cr from the city. Back up when you like." % pay2, 6.0)
		Audio.play("lock_acquired", "site target done", -2.0)
		return
	if String(_site.get("theme", "")) == "mine":
		var list: Array = PoiData.MUSEUM_RELICS["mine"]
		var mf := String(list[int(d.get("seed", 0)) % list.size()][0])            # 0.7.53.7: the mine's prize
		GameState.museum_find(mf)
		var pay := 250 + int(d.get("seed", 0)) % 300
		GameState.credits += pay
		_say_toast("You cut it out of the rock: %s – a find for the Museum (and %d cr in ore besides). Back up when you like." % [PoiData.museum_name(mf), pay], 5.5)
		Audio.play("lock_acquired", "site target done", -2.0)
		return
	if String(_site.get("theme", "")) == "wreck":
		var rw := 500 + int(d.get("seed", 0)) % 450              # 0.7.53.6: the flight recorder – its owners pay
		GameState.credits += rw
		GameState.research_data += 2
		_say_toast("The flight recorder is yours – its owners pay %d cr for it. Back out when you like." % rw, 5.5)
		Audio.play("lock_acquired", "site target done", -2.0)
		return
	if String(_site.get("theme", "")) == "sewer":
		var pay := 400 + int(d.get("seed", 0)) % 500           # 0.7.53.3: the client list – sold on, or a bounty lead later
		GameState.credits += pay
		_say_toast("The client list is yours – names, drops, debts. Worth %d cr to the right people. Back up when you like." % pay, 5.5)
		Audio.play("lock_acquired", "site target done", -2.0)
		return
	var n := 6 + int(d.get("seed", 0)) % 6
	GameState.research_data += n
	var rng := RandomNumberGenerator.new()
	rng.seed = int(d.get("seed", 0)) + 99
	var mr: String = PoiData.museum_roll(String(_site.get("theme", "precursor")), rng) if rng.randf() < 0.6 else ""
	if mr == "" and rng.randf() < 0.25:
		mr = String(PoiData.MUSEUM_RELICS.get(String(_site.get("theme", "precursor")), [[""]])[0][0])
	if mr != "":
		GameState.museum_find(mr)
	_say_toast("The relic read – the site's prize is yours (+%d research data)%s. Back to the ship when you like." % [n, (" – and a find for the Museum: %s" % PoiData.museum_name(mr)) if mr != "" else ""], 5.5)
	Audio.play("lock_acquired", "site target done", -2.0)


## 0.7.53.2: the site's maps while you are there – built once (inside first: the window lists what is in it),
## kept, so doors stay open and the fallen stay down as you go in and out.
func _poi_map(lv: String, lsz: Vector2) -> GroundMap:
	var sid := String(_site.get("id", ""))
	if String(_poi_cache.get("site", "")) != sid:
		_poi_cache = {"site": sid}
	var theme := String(_site.get("theme", "precursor"))
	var nlev := PoiData.levels(theme)
	for dl in nlev:                                     # 0.7.53.3: every level, built once
		if not _poi_cache.has("dungeon_%d" % dl):
			_poi_cache["dungeon_%d" % dl] = DungeonGen.build_inside(_body, _site, dl)
	if lv == "dungeon":
		return _poi_cache["dungeon_%d" % clampi(depth, 0, nlev - 1)]
	if not _poi_cache.has("outside"):
		var mo: GroundMap
		if String(PoiData.THEMES.get(theme, {}).get("outside", "ruin")) == "alley":
			mo = DungeonGen.build_alley(_body, _site)
		elif String(PoiData.THEMES.get(theme, {}).get("outside", "ruin")) == "plaza":
			mo = DungeonGen.build_plaza(_body, _site)                                   # 0.7.53.19
		elif String(PoiData.THEMES.get(theme, {}).get("outside", "ruin")) == "station":
			mo = DungeonGen.build_station_outside(_body, _site, lsz.x, lsz.y)          # 0.7.53.20
		elif String(PoiData.THEMES.get(theme, {}).get("outside", "ruin")) == "cliff":
			mo = DungeonGen.build_cliff(_body, _site, lsz.x, lsz.y)                       # 0.7.53.11
		elif String(PoiData.THEMES.get(theme, {}).get("outside", "ruin")) == "lift":
			mo = DeckGen.build_landing(_body, _site, lsz.x, lsz.y)                      # 0.7.53.9: a field with a service hatch
			mo.zones.append({"rect": Rect2(mo.spawn + Vector2(40, -30), Vector2(40, 30)), "kind": "dungeon_in", "id": "dungeon_in",
				"title": "The service hatch – down into the tunnels", "col": Color(1.0, 0.75, 0.4), "sign": Vector2(-100, -100)})
			mo.set_meta("door_front", mo.spawn + Vector2(60, 10))
		elif String(PoiData.THEMES.get(theme, {}).get("outside", "ruin")) == "minehead":
			mo = DungeonGen.build_minehead(_body, _site)                                # 0.7.53.7
		elif String(PoiData.THEMES.get(theme, {}).get("outside", "ruin")) == "wreck":
			mo = DungeonGen.build_wreck_outside(_body, _site, lsz.x, lsz.y)            # 0.7.53.6
		else:
			mo = DungeonGen.build_outside(_body, _site, lsz.x, lsz.y)
		var info: Dictionary = (_poi_cache["dungeon_0"] as GroundMap).get_meta("poi").duplicate()
		var all: Array = []
		for dl2 in nlev:
			all.append(_poi_cache["dungeon_%d" % dl2])
		info["targets"] = DungeonGen.site_targets(all)
		mo.set_meta("poi", info)
		_poi_cache["outside"] = mo
	return _poi_cache["outside"]


## The site's entrance outside ({} none).
func _poi_gate() -> Dictionary:
	for d in map.explore:
		if String(d["kind"]) == "ruin_gate":
			return d
	return {}


## On landing at a site: its minimap and – a site found on the map – the window with what the scanner picks up.
func _poi_setup() -> void:
	if _mm != null and is_instance_valid(_mm):
		_mm.queue_free()
	_mm = null
	if not map.has_meta("poi"):
		return
	if map.has_meta("seen"):
		poi_seen = map.get_meta("seen")                  # 0.7.53.3: what you saw of this level stays seen
	else:
		poi_seen = PackedByteArray()
		poi_seen.resize(map.w * map.h)
		poi_seen.fill(0)
	_mm_img = Image.create(map.w, map.h, false, Image.FORMAT_RGBA8)
	_mm_img.fill(Color(0, 0, 0, 0))
	for yy in map.h:
		for xx in map.w:
			if poi_seen[yy * map.w + xx] == 1:
				_mm_img.set_pixel(xx, yy, _mm_col(xx, yy))
	_mm_tex = ImageTexture.create_from_image(_mm_img)
	_mm_tile = Vector2i(-99, -99)
	_mm = Control.new()
	_mm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mm.set_anchors_preset(Control.PRESET_FULL_RECT)
	_mm.draw.connect(_draw_minimap)
	_ui.add_child(_mm)
	if not bool(_site.get("mission", false)) and level in ["landing", "alley", "minehead", "plaza"] and not map.has_meta("shown") and not bool(_site.get("used", false)):
		map.set_meta("shown", true)
		call_deferred("_poi_window")
	elif bool(_site.get("mission", false)) and not map.has_meta("shown") and (level in ["landing", "alley", "minehead", "plaza"] or (level == "dungeon" and depth == 0 and String(_site.get("goal", "")) == "reactivate")):
		map.set_meta("shown", true)
		call_deferred("_mission_window")             # package 53c: the job's briefing


## What the minimap shows of a tile once seen.
func _mm_col(x: int, y: int) -> Color:
	var t := map.t_at(x, y)
	var fk := map.floor_kind[y * map.w + x]
	if GroundMap.walkable_t(t) or t == GroundMap.T.BLOCK:
		if fk == 13 or fk == 14:
			return Color(0.45, 0.4, 0.32, 0.9)
		if fk == 16:
			return Color(0.55, 0.45, 0.8, 0.9)
		if fk == 18 or fk == 20:
			return Color(0.3, 0.55, 0.65, 0.9) if fk == 18 else Color(0.2, 0.35, 0.55, 0.95)
		return Color(0.62, 0.64, 0.68, 0.95)
	if t == GroundMap.T.FACE:
		return Color(0.32, 0.33, 0.36, 0.95)
	return Color(0, 0, 0, 0)


## Seen: the tiles round you that a line from you reaches (walls stop it; their faces still show).
func _poi_reveal() -> void:
	if _mm == null or pilot == null:
		return
	var tp := Vector2i(int(pilot.pos.x / GroundMap.TILE), int(pilot.pos.y / GroundMap.TILE))
	if tp == _mm_tile:
		return
	_mm_tile = tp
	var r := 9
	var changed := false
	for y in range(tp.y - r, tp.y + r + 1):
		for x in range(tp.x - r, tp.x + r + 1):
			if x < 0 or y < 0 or x >= map.w or y >= map.h or Vector2(x - tp.x, y - tp.y).length() > r:
				continue
			if poi_seen[y * map.w + x] == 1:
				continue
			var d := Vector2(x - tp.x, y - tp.y)
			var n := int(d.length() * 2.0)
			var ok := true
			for s in range(1, n):
				var q := Vector2(tp) + d * (float(s) / n)
				var qt := map.t_at(int(round(q.x)), int(round(q.y)))
				if not (GroundMap.walkable_t(qt) or qt == GroundMap.T.BLOCK):
					ok = false
					break
			if ok:
				poi_seen[y * map.w + x] = 1
				_mm_img.set_pixel(x, y, _mm_col(x, y))
				changed = true
	if changed:
		_mm_tex.update(_mm_img)


func _draw_minimap() -> void:
	if _mm == null or not is_instance_valid(_mm) or not map.has_meta("poi"):
		return                                       # (the old one, freed, draws a last time)
	var vs := _mm.get_viewport_rect().size
	var mw := 300.0
	var sc := mw / float(map.w)
	var r := Rect2(Vector2(vs.x - mw - 16, 84), Vector2(mw, map.h * sc))
	_mm.draw_rect(r.grow(6), Color(0.02, 0.03, 0.05, 0.82))
	_mm.draw_rect(r.grow(6), Color(0.75, 0.55, 1.0, 0.6), false, 1.5)
	_mm.draw_texture_rect(_mm_tex, r, false)
	# the things seen: the target, terminals, caches, doors
	for d in map.explore:
		var p: Vector2 = d["pos"]
		var ti := int(p.y / GroundMap.TILE - 0.5) * map.w + int(p.x / GroundMap.TILE)
		if ti < 0 or ti >= poi_seen.size() or poi_seen[ti] == 0:
			continue
		var c: Color = {"relic": Color(0.85, 0.5, 1.0), "terminal": Color(0.3, 1.0, 0.6), "crate": Color(1.0, 0.8, 0.3), "blastdoor": Color(1.0, 0.35, 0.3),
			"tablet": Color(0.6, 0.85, 1.0), "vent": Color(0.75, 0.6, 1.0), "hatch": Color(1.0, 0.7, 0.35), "ladder": Color(0.4, 1.0, 0.6),
			"valve": Color(0.4, 0.8, 0.9), "rust_door": Color(1.0, 0.35, 0.3), "grate_door": Color(1.0, 0.35, 0.3), "steel_door": Color(1.0, 0.35, 0.3),
			"tripwire": Color(1.0, 0.25, 0.2), "ancient_lift": Color(0.75, 0.55, 1.0), "turret": Color(1.0, 0.35, 0.3), "alarm": Color(1.0, 0.25, 0.2),
			"blackbox": Color(1.0, 0.6, 0.2), "generator": Color(1.0, 0.85, 0.3), "deck_hole": Color(1.0, 0.7, 0.35), "breach": Color(0.4, 1.0, 0.6),
			"airlock": Color(0.4, 1.0, 0.6), "bulkhead": Color(1.0, 0.35, 0.3), "conduit": Color(0.6, 0.85, 1.0), "gas": Color(0.5, 0.9, 0.3),
			"cage": Color(1.0, 0.75, 0.4), "mine_gen": Color(1.0, 0.85, 0.3), "vein": Color(0.95, 0.85, 0.4), "rubble": Color(0.7, 0.6, 0.5),
			"tnt": Color(1.0, 0.25, 0.2), "loose_rock": Color(0.7, 0.6, 0.5), "mine_gate": Color(0.4, 1.0, 0.6)}.get(String(d["kind"]), Color(0, 0, 0, 0))
		if String(d["kind"]) == "blastdoor" and String(d["state"]) == "open":
			c = Color(0.3, 1.0, 0.45)
		if String(d["state"]) in ["scanned", "open", "hacked"] and String(d["kind"]) != "blastdoor":
			c = c.darkened(0.5)
		if c.a > 0.0:
			_mm.draw_circle(r.position + p * sc / GroundMap.TILE, 2.6, c)
	for d2 in map.explore:
		if String(d2["kind"]) == "cracked_wall" and bool(d2.get("hinted", false)) and String(d2["state"]) != "open":
			var hp: Vector2 = r.position + (d2["pos"] as Vector2) * sc / GroundMap.TILE
			_mm.draw_circle(hp, 6.0, Color(0.1, 0.08, 0.02, 0.9))
			_mm.draw_string(ThemeDB.fallback_font, hp + Vector2(-4, 5), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 0.85, 0.35))
	var pp := r.position + pilot.pos * sc / GroundMap.TILE
	_mm.draw_circle(pp, 3.5, Color(0.2, 0.2, 0.2))
	_mm.draw_circle(pp, 2.5, Color(0.4, 1.0, 0.6))
	var lvn := ""
	if int(map.get_meta("poi").get("levels", 1)) > 1 and level == "dungeon":
		lvn = "  ·  level %d of %d" % [depth + 1, int(map.get_meta("poi")["levels"])]
	_mm.draw_string(ThemeDB.fallback_font, r.position + Vector2(0, -10), String(map.get_meta("poi")["name"]) + lvn, HORIZONTAL_ALIGNMENT_LEFT, mw, 12, Color(0.85, 0.75, 1.0))


## Package 53a (Luz): landing at a site found on the map – what the scanner picks up, before you go in.
func _poi_window() -> void:
	if not map.has_meta("poi") or _lift_menu != null:
		return
	var info: Dictionary = map.get_meta("poi")
	Audio.play("ui_open", "site: possible targets")
	var c := CenterContainer.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(c)
	var gold := Color(0.95, 0.8, 0.3)
	var p := UI.neon_panel(Color(gold, 0.9), Color(0.03, 0.04, 0.07, 0.97), 2)
	p.custom_minimum_size = Vector2(720, 0)
	c.add_child(p)
	var v := UI.vbox(8)
	p.add_child(v)
	v.add_child(UI.label(String(info["name"]).to_upper(), 22, gold))
	v.add_child(UI.label("%s  •  %d level%s  •  about %d minutes  •  danger: %s" % [String(info["theme_name"]), int(info["levels"]),
		"" if int(info["levels"]) == 1 else "s", int(info["minutes"]), String(info["danger_name"])], 13, UI.TEXT_DIM))
	v.add_child(HSeparator.new())
	v.add_child(UI.label("WHAT YOUR SCANNER PICKS UP – POSSIBLE TARGETS", 14, Color(0.85, 0.9, 1.0)))
	for tg in info["targets"]:
		var td: Dictionary = PoiData.TARGETS.get(String(tg[0]), {})
		var row := UI.hbox(10)
		var bar := ColorRect.new()
		bar.color = td.get("col", Color.WHITE)
		bar.custom_minimum_size = Vector2(6, 48)
		row.add_child(bar)
		var col := UI.vbox(2)
		col.add_child(UI.label(String(tg[1]), 14, Color(0.92, 0.95, 1.0)))
		col.add_child(UI.label("needs: %s      gives: %s" % [String(td.get("needs", "")), String(td.get("gives", ""))], 11, UI.TEXT_DIM))
		row.add_child(col)
		v.add_child(row)
	v.add_child(HSeparator.new())
	var keys: Array = []
	var go := func(): _close_lift_menu()
	var back := func():
		_close_lift_menu()
		for z in map.zones:
			if String(z.get("id", "")) == "ship":
				_open_takeoff_menu(z)
	var b1 := UI.button("1.  Go in", go)
	if level in ["alley", "minehead", "plaza"]:
		back = func(): _close_lift_menu()
	var b2 := UI.button("2.  Not now – back to the ship" if not level in ["alley", "minehead", "plaza"] else "2.  Not now", back)
	v.add_child(b1)
	v.add_child(b2)
	keys.append(go)
	keys.append(back)
	_lift_menu = c
	_lift_menu.set_meta("zone", {})
	_lift_menu.set_meta("keys", keys)


## Package 53c (Luz): arriving at a job's site – its briefing: what to do, what counts, what it pays.
func _mission_window() -> void:
	if _lift_menu != null:
		return
	var mm: Dictionary = {}
	for m in GameState.missions:
		if String(m.get("type", "")) == "ground" and String(m["site"]["id"]) == String(_site.get("id", "")):
			mm = m
	if mm.is_empty():
		return
	Audio.play("ui_open", "job briefing")
	var c := CenterContainer.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(c)
	var gold := Color(0.95, 0.8, 0.3)
	var p := UI.neon_panel(Color(gold, 0.9), Color(0.03, 0.04, 0.07, 0.97), 2)
	p.custom_minimum_size = Vector2(680, 0)
	c.add_child(p)
	var v := UI.vbox(8)
	p.add_child(v)
	v.add_child(UI.label("BRIEFING – " + String(mm["title"]).to_upper(), 20, gold))
	v.add_child(UI.label(String(mm["desc"]), 14, Color(0.92, 0.95, 1.0)))
	var rules := {"relic": "Another raider crew will come for the relic – be quick.",
		"salvage": "The flight recorder lies in the wreck's lower deck.",
		"bounty_foot": "The captain is somewhere inside. When the alarm rings, they run.",
		"heist": ({"sewer": "The dealer's safe is in the office behind a code door – cut it open (cutting torch); a turret guards it. ",
			"corp": "The vault is at the bottom: a key card for the lifts (or the fire stairs – loud), cameras and light barriers (the security centre switches them off), then hack and drill the vault door. "}.get(String(_site.get("theme", "")), "The strongbox is behind the code door below. ")) \
			+ ("An alarm fails the job." if bool(_site.get("hard", false)) else "An alarm halves the pay."),
		"spy": ("The data is in the security centre on the second level. " if String(_site.get("theme", "")) == "corp" else "The data is in the deepest computer. ") + "Unseen, they pay a bonus.",
		"reactivate": "Restart the reactor on the lowest level.",
		"recover": "The research computer is in the sample store below. Torn modules have no air and no warmth – seal their bulkheads.",
		"investigate": "The cult gathers at the bottom of the ruin. Find out what they are doing – and stop their priest. The symbols open the membranes; a monolith's vision tells their order.",
		"rescue": ("The researchers are sealed into a cold store inside. Open it; they follow you – bring them out alive." if String(_site.get("theme", "")) == "research"
			else "The prisoner is in the cells inside. Pick the lock; they follow you – bring them out alive.")}
	v.add_child(UI.label(String(rules.get(String(_site.get("goal", "")), "")), 13, UI.TEXT_DIM))
	v.add_child(UI.label("Pay: %s  •  danger: %s" % [GameData.fmt_credits(int(mm["reward"])), String(PoiData.DANGER.get(String(_site.get("danger", "yellow")), {}).get("name", ""))], 13, gold))
	var go := func(): _close_lift_menu()
	var b1 := UI.button("1.  Understood", go)
	v.add_child(b1)
	_lift_menu = c
	_lift_menu.set_meta("zone", {})
	_lift_menu.set_meta("keys", [go])


## Package 53c: a job's goal reached at its site (or failed) – its rules: a heist's alarm, spying unseen.
func _mission_event(kind: String) -> void:
	if not bool(_site.get("mission", false)) or bool(_site.get("goal_done", false)):
		return
	var goal := String(_site.get("goal", ""))
	var want := {"relic": "target", "salvage": "target", "reactivate": "target", "heist": "target", "bounty_foot": "leader", "spy": "data", "rescue": "rescued", "recover": "target", "investigate": "leader"}
	if String(want.get(goal, "")) != kind:
		return
	_site["goal_done"] = true
	var mult := 1.0
	var note := ""
	if goal == "heist" and bool(_site.get("alarmed", false)):
		if bool(_site.get("hard", false)):
			GameState.poi_use(String(_site.get("id", "")))
			GameState.ground_goal(_site, false, 1.0, "the alarm rang")
			_say_toast("The alarm rang – the job is blown.", 4.0)
			return
		mult = 0.5
		note = "an alarm rang: half pay"
	if goal == "spy" and not bool(_site.get("seen", false)):
		mult = 1.3
		note = "unseen: bonus"
	GameState.poi_use(String(_site.get("id", "")))
	GameState.ground_goal(_site, true, mult, note)
	_say_toast("Job done%s – report back for your pay." % ((" (" + note + ")") if note != "" else ""), 4.0)
	Audio.play("lock_acquired", "job goal done", -2.0)


## Package 53c: a job's site while you are in it – seen or not, the alarm, the captain fallen, the second raider crew.
func _mission_step(delta: float) -> void:
	if not bool(_site.get("mission", false)) or combat == null or level != "dungeon":
		return
	if combat.alive().any(func(f): return f["aware"]):
		_site["seen"] = true
	if map.explore.any(func(d): return String(d["kind"]) == "alarm" and String(d["state"]) == "ringing"):
		_site["alarmed"] = true
	var goal := String(_site.get("goal", ""))
	if goal in ["bounty_foot", "investigate"]:
		var th: Dictionary = PoiData.layer(String(_site.get("theme", "")), depth)
		var lk := String(th.get("cult_leader", "")) if bool(_site.get("cult", false)) else String(th.get("leader", ""))     # 0.7.53.23: the cult's priest
		for f in combat.foes:
			if f["dead"] and String(f["kind"]) == lk:
				_mission_event("leader")
	if goal == "relic" and not bool(_site.get("goal_done", false)) and not bool(_site.get("raced", false)):
		_site["race_t"] = float(_site.get("race_t", 0.0)) + delta
		if float(_site["race_t"]) > 240.0:
			_site["raced"] = true                          # the other crew arrives
			for i in 3:
				var sp: Vector2 = combat._free_near(map.spawn + Vector2(randf_range(-30, 30), randf_range(-10, 10)))
				if sp != Vector2.INF:
					var nf: Dictionary = combat.spawn(["bandit_scrapper", "bandit_rifleman", "bandit_gunner"][i], sp, "", "yellow")
					combat._wake(nf)
			_say_toast("Another raider crew is here – they are after the relic too!", 3.5)


## 0.7.52.23: a blast door opens – its gap walkable, the leaves slide into the walls.
func open_door(d: Dictionary) -> void:
	if String(d["state"]) == "open":
		return
	d["state"] = "open"
	if String(d["kind"]) == "ruin_gate":
		if fog != null and is_instance_valid(fog):
			fog.burst((d["pos"] as Vector2) + Vector2(0, -8))          # 0.7.53.2 (Luz): fog spills out
		for z in map.zones:
			if String(z.get("kind", "")) == "dungeon_in":
				z["title"] = "Go in"
		_say_toast("The entrance grinds open – fog spills out.", 3.0)
		Audio.play("dock_clamp", "ruin gate opens", -2.0)
	var tl: Array = d.get("tiles", [])
	if tl.size() < 4:
		return                                             # 0.7.53.6: the airlock – the way in is its zone
	map.fill(int(tl[0]), int(tl[1]), int(tl[2]), int(tl[3]), GroundMap.T.DOOR, 1)
	map._astar = null
	if combat != null:
		combat._build_cover()


## 0.7.53.3 (Luz): the pumps drain a flooded tunnel – its water runs off, the walkways and the canal come out of it.
func _drain(tiles: Array) -> void:
	if tiles.is_empty():
		return
	var any := false
	for t in tiles:
		if map.t_at(int(t[0]), int(t[1])) == GroundMap.T.BLOCK:
			map.set_t(int(t[0]), int(t[1]), GroundMap.T.FLOOR, int(t[2]))
			any = true
	for d in map.explore:
		if String(d["kind"]) in ["valve", "terminal"] and d.has("flood"):
			d["drained"] = true
			if String(d["kind"]) == "valve":
				d["state"] = "open"
	if not any:
		return
	map.refresh_texture()
	map._astar = null
	if combat != null:
		combat._build_cover()
	_say_toast("The pumps thunder – the water runs off. The flooded tunnel is clear.", 3.0)
	Audio.play("undock_release", "tunnel drained", -4.0)


## 0.7.52.27 (Luz): a vent cut open – its duct can be crawled through (you sneak in it).
func open_vent(d: Dictionary) -> void:
	d["state"] = "open"
	for c in d.get("duct", []):
		map.set_t(int(c[0]), int(c[1]), GroundMap.T.FLOOR, 16)
	map.refresh_texture()                              # 0.7.52.28: the shaft shows only once it is open
	map._astar = null
	if combat != null:
		combat._build_cover()
	_say_toast("The grille drops – the shaft is open. Crawl in.", 2.5)


## In a duct you go on all fours: sneaking (and back up when you are out).
var _duct_sneak := false


func _duct_step() -> void:
	if combat == null or pilot == null:
		return
	var tx := int(floor(pilot.pos.x / GroundMap.TILE))
	var ty := int(floor(pilot.pos.y / GroundMap.TILE))
	var in_duct := tx >= 0 and ty >= 0 and tx < map.w and ty < map.h and map.floor_kind[ty * map.w + tx] == 16 and GroundMap.walkable_t(map.t_at(tx, ty))
	if in_duct and not combat.sneaking:
		combat.toggle_sneak()
		_duct_sneak = true
		_say_toast("You crawl into the shaft – low and quiet.", 2.0)
	elif not in_duct and _duct_sneak:
		_duct_sneak = false
		if combat.sneaking:
			combat.toggle_sneak()


## 0.7.52.23: the laser cage switched off – you may step up to what it guarded (the posts stay).
func cage_off(d: Dictionary) -> void:
	if String(d["state"]) == "off":
		return
	d["state"] = "off"
	if _named_lights.has("cage") and is_instance_valid(_named_lights["cage"]):
		(_named_lights["cage"] as Node2D).visible = false
	var tl: Array = d["tiles"]
	if String(d["kind"]) == "crystals":
		map.fill(int(tl[0]), int(tl[1]), int(tl[2]), int(tl[3]), GroundMap.T.FLOOR)     # 0.7.53.2: nothing left standing
		map._astar = null
		if combat != null:
			combat._build_cover()
		return
	map.fill(int(tl[0]), int(tl[1]), int(tl[2]), int(tl[3]), GroundMap.T.FLOOR, 1)
	for c in [Vector2i(int(tl[0]), int(tl[1])), Vector2i(int(tl[0]) + int(tl[2]) - 1, int(tl[1])), Vector2i(int(tl[0]), int(tl[1]) + int(tl[3]) - 1),
			Vector2i(int(tl[0]) + int(tl[2]) - 1, int(tl[1]) + int(tl[3]) - 1)]:
		map.set_t(c.x, c.y, GroundMap.T.BLOCK)
	map._astar = null
	if combat != null:
		combat._build_cover()


## 0.7.52.24 (Luz): scanning – the scanner's belt key held at a tablet or a relic, standing still.
func _scan_start(n: int) -> bool:
	var best := -1
	var bd := 46.0
	for i in map.explore.size():
		var d: Dictionary = map.explore[i]
		if String(d["kind"]) in ["tablet", "relic", "monolith"]:
			var dd := (d["pos"] as Vector2).distance_to(pilot.pos)
			if dd < bd:
				bd = dd
				best = i
	if best < 0:
		return false
	if String(map.explore[best]["state"]) == "scanned":
		_say_toast("Already scanned.", 1.5)
		return true
	var cg = map.explore[best].get("cage")
	if cg != null and String(map.explore[int(cg)]["state"]) != "off":
		_say_toast("The crystals' lightning scatters the scan – switch them off first." if String(map.explore[int(cg)]["kind"]) == "crystals" else "The laser cage is in the way – the beams scatter the scan. Switch it off first.", 3.0)
		return true
	_scan = {"i": best, "t": 0.0, "need": 3.0 * (1.0 - 0.04 * GameState.skill_level("science")), "key": n, "at": pilot.pos}
	Audio.play("ui_click", "scan starts", -8.0)
	return true


func _scan_step(delta: float) -> void:
	if _scan.is_empty():
		return
	var held := Input.is_action_pressed("foot_belt_%d" % (int(_scan["key"]) + 1))
	if not held or pilot.pos.distance_to(_scan["at"]) > 3.0:
		_say_toast("Scan broken off – hold the key and stand still.", 2.0)
		_scan = {}
		return
	_scan["t"] = float(_scan["t"]) + delta
	if float(_scan["t"]) >= float(_scan["need"]):
		var d: Dictionary = map.explore[int(_scan["i"])]
		_scan = {}
		scan_done(d)


func scan_done(d: Dictionary) -> void:
	d["state"] = "scanned"
	if bool(d.get("target", false)):
		_poi_target_done(d)
	var n := 3 + int(d.get("seed", 0)) % 4 + (3 if String(d["kind"]) == "relic" else 0)
	GameState.research_data += n
	GameState.skill_xp("science", 3.0)
	GameState.codex.event("scan_" + String(d["kind"]))
	var txt := ""
	if String(d["kind"]) == "tablet":
		txt = String(ExploreNode.INSCRIPTIONS[int(d.get("seed", 0)) % ExploreNode.INSCRIPTIONS.size()])
		_say_toast("The tablet reads: %s  (+%d research data)" % [txt, n], 6.0)
	elif String(d["kind"]) == "monolith":
		# 0.7.53.23 (Luz): a vision – and in it the order of the symbols, where there are symbol stones on this map
		txt = String(VISIONS[int(d.get("seed", 0)) % VISIONS.size()])
		if map.has_meta("sym_order"):
			var so: Array = map.get_meta("sym_order")
			txt += "  In the vision four signs burn, one after another: %s." % "  ".join(PackedStringArray(so.map(func(i): return "%s %s" % [SYMBOLS[int(i)][0], SYMBOLS[int(i)][1]])))
		_say_toast("%s  (+%d research data)" % [txt, n], 9.0)
	else:
		txt = "A relic of the ones before – its lattice hums at a frequency nobody makes any more."
		_say_toast("%s  (+%d research data)" % [txt, n], 5.0)
	if String(d["kind"]) in ["tablet", "monolith"] and map.has_meta("hidden_wall"):
		var hw: Dictionary = map.explore[int(map.get_meta("hidden_wall"))]
		if not bool(hw.get("hinted", false)) and String(hw["state"]) != "open":
			hw["hinted"] = true                            # 0.7.53.24 (Luz): it tells of a hollow behind a wall – a ? on the map
			_say_toast("…and it tells of a hollow behind a cracked wall on this level – marked on your map (?).", 4.0)
			log_event("A hidden chamber – marked on the map", Color(0.95, 0.8, 0.4))
	log_event("Scanned: %s  +%d research data" % [txt.left(80), n], Color(0.45, 0.9, 1.0))
	Audio.play("lock_acquired", "scan done", -6.0)


## 0.7.52.20: V held opens the wheel; the use key held beside a member down brings them back.
func _team_keys(delta: float) -> void:
	if _team_held >= 0.0:
		_team_held += delta
		if _team_held >= 0.2 and not combat.wheel_open:
			combat.wheel_open = true
			Audio.play("ui_open", "command wheel", -8.0)
	if _revive >= 0.0:
		var a = combat.reviving
		if a == null or not Input.is_action_pressed("interact") or combat.revive_near() != a:
			_revive = -1.0
			combat.reviving = null
			combat.revive_k = 0.0
			return
		_revive += delta
		combat.revive_k = clampf(_revive / GroundCombat.CrewData.REVIVE_TIME, 0.0, 1.0)
		if _revive >= GroundCombat.CrewData.REVIVE_TIME:
			combat.revive(a)
			_say_toast("%s is back on their feet." % String(a["name"]), 2.0)
			_revive = -1.0
			combat.reviving = null
			combat.revive_k = 0.0


## Where the command wheel sits on the screen: round you.
func wheel_centre() -> Vector2:
	return pilot.get_global_transform_with_canvas().origin + Vector2(0, -40)


## Uses what the pilot stands at (also for the smoke test; instant: the lift without its ride).
func use(instant: bool = false) -> bool:
	if not _ride.is_empty() or talk != null or _arrive > 0.0 or _lift_menu != null or _touch >= 0.0:
		return false
	if not _seat.is_empty():
		_stand_up()
		return true
	if zone.is_empty() or String(zone.get("closed", "")) != "":
		return false
	match String(zone["kind"]):
		"seat":
			_sit(zone)
			if String(zone.get("title", "")) == "Sit at the bar" and _bartender != null:
				open_bartender()
			return true
		"jukebox":
			_jukebox()
			return true
		"crew":
			return open_talk(zone)
		"soon":
			_say_toast(String(zone["title"]), 3.0)
			return true
		"socket":
			var sd: Dictionary = map.explore[int(zone["i"])]
			if float(sd.get("charge", 0.0)) <= 0.0:
				_say_toast("The socket is dead – drawn dry.", 2.0)
			elif GameState.gear.energy >= float(GameState.gear.totals()["energy"]) - 0.5:
				_say_toast("The suit's energy is full.", 1.5)
			else:
				_socket = int(zone["i"])                  # 0.7.53.16 (Luz): held – it charges (_socket_step)
				Audio.play("module_on", "socket charging", -6.0)
			return true
		"charge":
			GameState.gear.charge()                   # 0.7.51.3: energy and oxygen full again (0.7.52.12: and the rounds)
			_say_toast("Supplied – energy, oxygen and ammunition are full.", 2.5)
			Audio.play("dock_clamp", "charging point")
			return true
		"guard":
			var gl: Array = CityStyle.guards(station)["lines"]
			var gw := _near_guard()
			if gw != null:
				gw.dir = 0
			_say_toast("%s: \"%s\"" % [String(zone["title"]), String(gl[randi() % gl.size()])], 4.0)
			return true
		"lift":
			if instant:
				return false
			if level == "landing" and bool(_site.get("poi", false)):
				_say_toast("(Debug site) In a city this lift goes back up to the shopping street.", 2.5)
				return true
			_open_lift_menu(zone)
			return true
		"exit":
			if _hangar_stale():
				_say_toast("The %s is stored here now – your active ship stands in %s. Take the lift." % [_stored_name(), _active_hangar()])
				return false
			if not instant:
				if level in ["landing", "settlement"] or is_city():
					_open_takeoff_menu(zone)              # 0.7.50.15 (Luz): up to orbit – or to the planet map
				else:
					_start_ride(zone, "", -1)
				return true
		"service":
			if String(zone.get("id", "")) == "bar" and _bartender != null:
				return open_bartender()
		"explore":
			return explore_use(zone)                     # 0.7.52.22
		"dungeon_in":
			var gate := _poi_gate()
			if zone.has("gate"):
				gate = map.explore[int(zone["gate"])]          # 0.7.53.6: the breach or the airlock of a wreck
				if String(gate["state"]) != "open":
					_say_toast({"breach": "A buckled plate is wedged in the breach – cut it out (cutting torch).",
						"mine_gate": "The gate is chained shut – cut the chain (cutting torch).",
						"pirate_gate": "The hangar gate is sealed – its terminal beside it opens it (E-Breach).",
						"steel_door": "A code lock – cut its box beside the door (cutting torch).",
					"service_door": "The back door is locked – its keypad beside it (cutting torch) or the terminal (E-Breach)."}.get(String(gate["kind"]), "The airlock is sealed – its terminal on the post beside it opens it (E-Breach)."), 3.0)
					return true
			if bool(_site.get("used", false)) or GameState.poi_used.has(String(_site.get("id", ""))):
				_say_toast("Nothing more down there – the place is cleared out. Come back another time.", 3.0)
			elif gate.is_empty() or String(gate["state"]) == "open":
				if zone.has("gate"):
					map.set_meta("door_front", (gate["pos"] as Vector2) + Vector2(0, 26))   # 0.7.53.15 (Luz): out the way you came in
				depth = 0
				go_level("dungeon", "dungeon_in")          # 0.7.53.2: into the site
			else:
				_say_toast("The entrance is shut." + (" Its panel is beside it." if String(gate.get("lock", "")) == "panel" else (" Its computer stands by it." if String(gate.get("lock", "")) == "computer" else " Use it to open it.")), 3.0)
			return true
		"dungeon_out":
			depth = 0
			if is_city() and _town_kind == "maint":
				_town_kind = ""
				go_level("street", "lift")              # 0.7.53.9: the service lift back up
				return true
			if is_city() and _town_kind == "corp":
				go_level("plaza", "dungeon_out")        # 0.7.53.19: out by the back door
				return true
			go_level("alley" if is_city() else ("minehead" if is_town() else "landing"), "dungeon_out")           # 0.7.53.2: back out
			return true
		"mine_path":
			go_level("minehead", "path")                 # 0.7.53.7 (Luz): to the old mine at the town's edge
			return true
		"town_path":
			if not is_town():
				_say_toast("(Debug site) In a settlement this path leads back into town.", 2.5)
				return true
			go_level("settlement", "mine_path")
			return true
		"dungeon_down":
			var al := _lift_here()
			if not al.is_empty():
				if String(al["state"]) == "dormant":
					_say_toast("The cage has no power – start the old generator by the mine's control." if String(al["kind"]) == "cage"
						else "The ancient lift sleeps – their computer can wake it, or a crystal panel somewhere on this level.", 3.5)
					return true
				_sink = {"d": al, "t": 0.0, "dir": 1}         # 0.7.53.4 (Luz): the platform sinks with you
				Audio.play("dock_clamp", "ancient lift", -4.0)
				return true
			if bool(zone.get("need_card", false)) and not bool(_site.get("card", false)):
				_say_toast("The lift wants a key card – look in the offices. Or the fire stairs (they ring the alarm).", 3.5)
				return true                                  # 0.7.53.19 (Luz)
			if bool(zone.get("fire_door", false)):
				_say_toast("The fire door's alarm goes off!", 2.5)
				raise_alarm()
			depth += 1                                   # 0.7.53.3: a level deeper
			go_level("dungeon", "dungeon_down")
			_say_toast("Down the ladder – level %d." % (depth + 1), 2.0)
			return true
		"dungeon_up":
			var al2 := _lift_here()
			if not al2.is_empty():
				_sink = {"d": al2, "t": 0.0, "dir": -1}
				Audio.play("dock_clamp", "ancient lift", -4.0)
				return true
			depth = maxi(0, depth - 1)
			go_level("dungeon", "dungeon_up")
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
	var af := GameState.active()
	var hname := "Hangar %02d – your %s" % [DeckGen.hangar_no(station, af.uid if af != null else 0), af.ship_name if af != null else "ship"]
	var lvls := [["hangar", "1.  " + hname], ["commercial", "2.  Commercial level – shops and the bar"]]
	if is_city():
		lvls = [["hangar", "1.  " + hname], ["street", "2.  Shopping street – the shops"], ["tower", "3.  Tower bar – floor %d, a view over the city" % tower_floor()]]
	if _avail.has("clinic"):                                      # 0.7.51.11: the clinic, its own level
		lvls.append(["clinic", "%d.  Clinic – Mercy Hall, treatment and recovery" % (lvls.size() + 1)])
	if is_city():                                                 # 0.7.53.3 (Luz): the way down into the sewers
		lvls.append(["alley", "%d.  Back alley – a manhole down into the sewers" % (lvls.size() + 1)])
	if is_city():                                                 # 0.7.53.19 (Luz): up to the roof plaza
		var cs1 := GameState.corp_site_for(String(station.get("id", "")))
		var cname := String((cs1 if not cs1.is_empty() else GameState.corp_poi(_sys, station)).get("name", "a corporate tower"))
		lvls.append(["plaza", "%d.  Roof plaza – the %s" % [lvls.size() + 1, cname]])
	if is_city() and not GameState.maint_site_for(String(station.get("id", ""))).is_empty():
		lvls.append(["maint", "%d.  Maintenance level – the power is out down there" % (lvls.size() + 1)])     # 0.7.53.9
	var keys: Array = []
	for lv in lvls:
		keys.append(func(): _choose_level(String(lv[0])))
		var here: bool = lv[0] == level and (lv[0] != "hangar" or not _hangar_stale())
		var b := UI.button(String(lv[1]) + ("   (you are here)" if here else ""), func(): _choose_level(String(lv[0])))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = here
		v.add_child(b)
	v.add_child(UI.button("Cancel [Esc]", _close_lift_menu))
	_lift_menu = c
	_lift_menu.set_meta("zone", z)
	_lift_menu.set_meta("keys", keys)


## 0.7.50.15 (Luz): taking off – back to orbit, or to the planet map to pick another place.
func _open_takeoff_menu(z: Dictionary) -> void:
	Audio.play("ui_open", "on foot: take off")
	var c := CenterContainer.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(c)
	var p := UI.neon_panel(Color(0.4, 1.0, 0.6, 0.85), Color(0.03, 0.05, 0.06, 0.96), 2)
	p.custom_minimum_size = Vector2(440, 0)
	c.add_child(p)
	var v := UI.vbox(8)
	p.add_child(v)
	v.add_child(UI.label("TAKE OFF", 20, Color(0.4, 1.0, 0.6)))
	var bname := String(_body.get("name", ""))
	if bname == "":
		bname = String(Universe.find_body(GameState.current_system, String(station.get("body", ""))).get("name", "the planet"))
	v.add_child(UI.label("Aboard the landing drone – where to?" if _lander else "Aboard your ship and up through the hatch – where to?", 13, UI.TEXT_DIM))
	var opts := [["orbit", "1.  Back to orbit" + (" – the drone docks with your ship" if _lander else "")],
		["map", "2.  To the planet map – another place on %s" % bname]]
	var keys: Array = []
	for o in opts:
		var b := UI.button(String(o[1]), func(): _choose_takeoff(String(o[0])))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		v.add_child(b)
		keys.append(func(): _choose_takeoff(String(o[0])))
	v.add_child(UI.button("Cancel [Esc]", _close_lift_menu))
	_lift_menu = c
	_lift_menu.set_meta("zone", z)
	_lift_menu.set_meta("keys", keys)


func _choose_takeoff(dest: String) -> void:
	if _lift_menu == null:
		return
	var z: Dictionary = (_lift_menu.get_meta("zone", {}) as Dictionary).duplicate()
	_close_lift_menu()
	z["dest"] = dest
	z["animate"] = true
	_start_ride(z, "", -1)


func _close_lift_menu() -> void:
	if _lift_menu != null:
		_lift_menu.queue_free()
	_lift_menu = null


func _choose_level(target: String) -> void:
	if _lift_menu == null:
		return
	var z: Dictionary = _lift_menu.get_meta("zone", {})
	_close_lift_menu()
	if target == "maint":
		_town_kind = "maint"                             # 0.7.53.9: the lift goes straight down into the tunnels
		depth = 0
		go_level("dungeon", "dungeon_in")
		return
	if target == "plaza":
		_town_kind = "corp"                              # 0.7.53.19: the corporate tower's plaza
	elif target == "alley":
		_town_kind = ""
	if target != level or (target == "hangar" and _hangar_stale()):
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
	elif level in ["landing", "settlement"] and _lander and map.ship_at != Vector2.INF:
		dp = _drone_ramp_top()
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
			if level in ["landing", "settlement"] and int(_ride["lift"]) < 0 and _ship_spr != null:
				# lift-off: dust, she rises off the pad, bigger (nearer to you), and is gone upwards
				var lt := float(_ride["t"])
				if _lander:
					_hatch = 1.0 - clampf(lt / HATCH_TIME, 0.0, 1.0)     # 0.7.50.15: the ramp folds up first
					if lt < HATCH_TIME:
						return
					lt -= HATCH_TIME
				if lt < 0.05 and _puffs.is_empty():
					_dust_burst(map.ship_at, 18)
					Audio.play("boost", "lift-off")
				var lk := clampf(lt / LIFT_TIME, 0.0, 1.0)
				_ship_spr.position = _ship_base + Vector2(0, -260.0 * lk * lk)
				_ship_spr.scale = Vector2.ONE * HANGAR_ART * GroundMap.SCALE * lerpf(1.0, 1.6, lk * lk)
				_ship_spr.modulate.a = 1.0 - smoothstep(0.7, 1.0, lk)
				if _ship_shadow != null:
					_ship_shadow.modulate.a = 0.45 * (1.0 - lk)
				if lt < LIFT_TIME:
					return
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


# ---------------------------------------------------------------- 0.7.50.3: touchdown and dust

## The ship comes down onto the pad – from above (nearer, bigger) to her place, her shadow meeting her; dust and a jolt
## as she sets down; then the pilot walks down the ramp.
func _touchdown_step(delta: float) -> void:
	_touch += delta
	var k := clampf(_touch / TOUCH_TIME, 0.0, 1.0)
	var h := 1.0 - smoothstep(0.0, 1.0, minf(k / 0.8, 1.0))
	_ship_spr.position = _ship_base + Vector2(0, -240.0 * h)
	_ship_spr.scale = Vector2.ONE * HANGAR_ART * GroundMap.SCALE * lerpf(1.0, 1.55, h)
	if _ship_shadow != null:
		_ship_shadow.modulate.a = lerpf(0.45, 0.12, h)
		_ship_shadow.scale = Vector2.ONE * HANGAR_ART * GroundMap.SCALE * lerpf(1.0, 0.8, h)
	if k >= 0.8 and _puffs.is_empty() and _touch - delta < TOUCH_TIME * 0.8 + 0.05:
		_dust_burst(map.ship_at, 22)
		_shake = 0.35
		Audio.play("dock_clamp", "touchdown")
	if k >= 1.0:
		# down the ramp (0.7.50.15: the drone's folds down first)
		var ramp_top: Vector2 = map.spawn - Vector2(0, 2.2 * GroundMap.TILE)
		var after := _touch - TOUCH_TIME
		if _lander:
			ramp_top = _drone_ramp_top()
			_hatch = clampf(after / HATCH_TIME, 0.0, 1.0)
			if after < HATCH_TIME:
				return
			after -= HATCH_TIME
		var wk := clampf(after / 0.9, 0.0, 1.0)
		pilot.visible = true
		pilot.dir = 0
		pilot.pos = ramp_top.lerp(map.spawn, wk)
		pilot.position = pilot.pos * GroundMap.SCALE
		pilot.moving = wk < 1.0
		if wk >= 1.0:
			_touch = -1.0
			pilot.moving = false


func _dust_burst(at: Vector2, n: int) -> void:
	if _dust == null or not is_instance_valid(_dust):
		_dust = Node2D.new()
		_dust.z_index = 9
		_dust.draw.connect(_draw_dust)
		_world.add_child(_dust)
	var dc: Color = map.pal.get("terrain_c", Color(0.7, 0.65, 0.55))
	for i in n:
		var a := randf() * TAU
		_puffs.append([at + Vector2.from_angle(a) * randf_range(10.0, 30.0), Vector2.from_angle(a) * randf_range(25.0, 70.0), randf_range(0.8, 1.6), randf_range(5.0, 11.0), dc])


func _update_dust(delta: float) -> void:
	if _puffs.is_empty():
		return
	for p in _puffs:
		p[0] = (p[0] as Vector2) + (p[1] as Vector2) * delta
		p[1] = (p[1] as Vector2) * (1.0 - delta * 1.6)
		p[2] = float(p[2]) - delta
		p[3] = float(p[3]) + delta * 9.0
	_puffs = _puffs.filter(func(p): return float(p[2]) > 0.0)
	if _dust != null and is_instance_valid(_dust):
		_dust.queue_redraw()


func _draw_dust() -> void:
	var s := GroundMap.SCALE
	for p in _puffs:
		var c: Color = p[4]
		_dust.draw_circle((p[0] as Vector2) * s, float(p[3]) * s, Color(c.lightened(0.15), clampf(float(p[2]) * 0.35, 0.0, 0.4)))


# ---------------------------------------------------------------- 0.7.49.13: ships, the bartender, drinks

## Back from a service window: if the active ship changed (the hangar service), say where it stands now.
func on_service_closed() -> void:
	if level == "hangar" and _hangar_stale():
		_say_toast("Your active ship, the %s, stands in %s – the lift takes you there." % [GameState.active().ship_name, _active_hangar()], 6.0)


func _hangar_stale() -> bool:
	var af := GameState.active()
	return level == "hangar" and af != null and af.uid != _hangar_uid


func _active_hangar() -> String:
	var af := GameState.active()
	return "Hangar %02d" % DeckGen.hangar_no(station, af.uid if af != null else 0)


func _stored_name() -> String:
	var f := GameState.get_fit(_hangar_uid)
	return f.ship_name if f != null else "old ship"


func _say_toast(t: String, secs: float = 4.0) -> void:
	_toast = t
	_toast_t = secs
	log_event(t, Color(1.0, 0.85, 0.45))                  # 0.7.52.13 (Luz): into the log on the right


## 0.7.52.13: a line in the event log, with the time.
func log_event(text: String, col: Color = Color(0.85, 0.9, 1.0)) -> void:
	if _log == null or text == "":
		return
	var tm := Time.get_time_string_from_system().substr(0, 5)
	_log.append_text("[color=#8090a0]%s[/color] [color=#%s]%s[/color]\n" % [tm, col.to_html(false), text])


const DRINKS := [
	["Nebula Ale", 8, 0.15, Color(0.95, 0.7, 0.25)],
	["Pulsar Punch", 14, 0.25, Color(1.0, 0.35, 0.55)],
	["Void Whisky", 25, 0.35, Color(0.75, 0.45, 0.15)],
	["Orbital Cola – no alcohol", 4, 0.0, Color(0.35, 0.18, 0.1)],
]
const BAR_TALK := [
	"Saw a hauler come in yesterday with half a moon stuck to its hull. Pilot swore it followed him.",
	"Tip from the house: never fly through an ion storm on an empty stomach. Or a full one.",
	"The pirates out at the rim pay in old coins. Good money, if you like your money haunted.",
	"They say the gates were built by someone who came before the Severance. I say they were built by someone who never had to use them.",
	"Prices for ice are up again. Everyone wants their drinks cold and their reactors colder.",
	"If you're heading out to the Far Reaches: bring fuel. Then bring more fuel.",
	"A man once paid his tab in live crabs. We still have one. He runs the till on Tuesdays.",
	"Rumour has it the Veil whispers if you park close enough. I asked it for a tip once. Nothing.",
	"Miners tip best. Traders talk most. Pirates do both, and then they shoot someone.",
	"The jukebox only knows three songs. So do I, after a long shift.",
	"Keep an eye on the bounty board – the big names don't stay big for long.",
	"Old gates are slow, but they get you there. Mostly. Usually. Eventually.",
	"I had a robot bartender once. Made perfect drinks. Terrible listener.",
	"Word is a derelict from before the Severance drifts near a battlefield out there. Full of old tech, they say. And full of something else, they also say.",
	"Want my advice? Hire a good engineer before you need one. Afterwards they cost twice as much.",
	"We're out of synthetic olives. Don't ask what's in the real ones.",
]


## The bartender: a drink, a word, or who is looking for a post.
func open_bartender() -> bool:
	if _bartender == null or talk != null:
		return false
	Audio.play("ui_open", "on foot: bartender")
	talk = DialogueView.new()
	_ui.add_child(talk)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(station.get("id", ""))) + 13
	var bname: String = CrewTalk.CrewData.FIRST_NAMES[rng.randi() % CrewTalk.CrewData.FIRST_NAMES.size()]
	talk.open(_bartender.look, bname, "Bartender", Color(1.0, 0.75, 0.35))
	talk.closed.connect(func(): talk = null)
	talk.say(["What'll it be, captain?", "Evening. Long flight?", "Welcome in. First one's not free, but it's good."][randi() % 3], _bar_options())
	return true


func _bar_options() -> Array:
	var o: Array = [["A drink, please.", _bar_drinks], ["What's new?", _bar_talk]]
	if _avail.has("bar") and String(_avail.get("bar", "")) == "":
		o.append(["Who's looking for work here?", _bar_crew])
	o.append(["Goodbye.", func(): talk.close()])
	return o


func _bar_drinks() -> void:
	var o: Array = []
	for d in DRINKS:
		var dd: Array = d
		o.append(["%s – %s" % [dd[0], GameData.fmt_credits(int(dd[1]))], func(): _order(dd)])
	o.append(["Maybe later.", func(): talk.say("Suit yourself.", _bar_options())])
	talk.say("Here's what's on the shelf tonight.", o)


func _order(d: Array) -> void:
	if not GameState.spend(int(d[1])):
		talk.say("Credits first, captain. House rules.", _bar_options())
		return
	Audio.play("buy", "on foot: a drink")
	pilot.drink_col = d[3]
	pilot.drink_t = Walker.DRINK_TIME
	# for later: alcohol makes things wobbly (a debuff to come); it wears off with play time
	var a := float(GameState.pilot.get("alcohol", 0.0))
	var since := GameState.play_time - float(GameState.pilot.get("alcohol_t", GameState.play_time))
	a = maxf(0.0, a - since / 600.0) + float(d[2])
	GameState.pilot["alcohol"] = minf(a, 1.0)
	GameState.pilot["alcohol_t"] = GameState.play_time
	var line := "One %s, coming up." % String(d[0])
	if float(GameState.pilot["alcohol"]) > 0.6:
		line = "One %s… you sure, captain? You're starting to lean." % String(d[0])
	talk.say(line, _bar_options())


func _bar_talk() -> void:
	talk.say(BAR_TALK[randi() % BAR_TALK.size()], _bar_options())


func _bar_crew() -> void:
	talk.close()
	used.emit({"kind": "service", "id": "bar"})


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


func _camera(delta: float = -1.0) -> void:
	var vs := get_viewport().get_visible_rect().size
	# 0.7.52.8: zoomed out only while the tactical view is open, as far as chosen there; eased in and out
	var zw := (tac_zoom if combat.tactics != 0 else near_zoom) if combat != null else 1.0
	zoom = zw if delta < 0.0 else lerpf(zoom, zw, 1.0 - exp(-delta * 10.0))
	if absf(zoom - zw) < 0.002:
		zoom = zw
	_world.scale = Vector2(zoom, zoom)
	var mp := map.size_px() * GroundMap.SCALE * zoom
	var c := pilot.position + Vector2(0, -24)
	# 0.7.49.14: sitting on the hangar's bench, the camera glides over to the ship – a look at her
	var at_ship := level == "hangar" and not _seat.is_empty() and map.ship_at != Vector2.INF
	if at_ship:
		c = map.ship_at * GroundMap.SCALE
	if delta < 0.0 or _cam_c == Vector2.INF:
		_cam_c = c
	else:
		var rate := 3.0 if at_ship or _cam_c.distance_to(c) > 120.0 else 14.0
		_cam_c = _cam_c.lerp(c, 1.0 - exp(-delta * rate))
	c = _cam_c * zoom
	var off := vs * 0.5 - c
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - (1.0 / 60.0))
		off += Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 10.0 * _shake / 0.35
	if mp.x > vs.x:
		off.x = clampf(off.x, vs.x - mp.x, 0.0)
	else:
		off.x = (vs.x - mp.x) * 0.5
	if mp.y > vs.y:
		off.y = clampf(off.y, vs.y - mp.y, 0.0)
	else:
		off.y = (vs.y - mp.y) * 0.5
	_world.position = off.round()
	# the star and the planet are far away: they stay in the part of the window front you can see, wherever you stand
	_sky.position = Vector2.ZERO
	if _window != null and _window.size.x > 0.0 and (_star_spr != null or _planet_spr != null):
		var wpos := off + _window.position
		var vis := Rect2(wpos, _window.size).intersection(Rect2(Vector2.ZERO, vs))
		if vis.size.x > 8.0:
			var lo := vis.position - wpos
			var wh := _window.size.y
			if _star_spr != null:
				_star_spr.position = (lo + Vector2(vis.size.x * 0.14, wh * 0.38)).round()
			if _planet_spr != null:
				_planet_spr.position = (lo + Vector2(vis.size.x * (0.62 if vis.size.x > 500.0 else 0.5), wh * 0.62)).round()
	if _skyline != null:
		_skyline.scroll(off.x)
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
