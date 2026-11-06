class_name SystemView
extends Node2D
const FocusLanceScript = preload("res://scripts/world/focus_lance.gd")
## A complete star system as ONE continuous space (1 unit = 1 km).
## Zoom levels from the ship up to the whole system:
##   close: star and planets appear as celestial bodies in the background (direction + apparent size)
##   far:   everything lies flat on one plane (map mode with orbits, icons and labels)
## Warp runs live in the same view – the camera follows the ship and zooms out on the way.
##
## Controls: click an object = warp/approach + action, click empty space = sublight flight,
## click a pirate = attack (auto-battle). Mouse wheel = zoom level, WASD/middle mouse = camera.

const FactionData = preload("res://data/factions.gd")

signal hover_changed(text: String)
signal station_docked(station_id: String)
signal level_changed(level: int)
signal object_selected(id: String)   # clicked object -> HUD shows the selected-item panel

const MAX_ZOOM := 2.0
## Fixed zoom levels: 0 = Close Combat, 1 = Long-Range Recon (both local, bodies in the background),
## 2 = System (everything flat on one plane). The "System" value adapts to the window size.
const LEVEL_NAMES := ["Combat", "Recon", "System"]
const LEVEL_ZOOMS := [0.6, 0.05, 0.0]
const RADAR_SCREEN := 0.44       # radar radius as a share of the smaller screen side

var system_id := -1
var layout: Dictionary
var camera: Camera2D
var background: SpaceBackground
var sky: CanvasLayer
var body_layer: Node2D
var celestial_layer: Node2D
var ship_layer: Node2D
var fx_layer: Node2D
var overlay: Node2D

var bodies: Array = []           # [{data, sky (Sprite2D), map (Sprite2D), star (bool)}]
var celestials: Array = []
const FIELD_COLORS := {"metallic": Color(0.95, 0.65, 0.45), "stony": Color(0.92, 0.82, 0.55), "icy": Color(0.6, 0.85, 1.0)}
var by_id := {}                  # object id -> Celestial
var asteroid_nodes: Array = []   # drawn only near the camera (see _cull_asteroids)
var colossi: Array = []          # colossal asteroids: obstacles, cover, radar shadow
var debris_layer: Node2D         # scenery rocks outside fields (layout["debris"]), drawn in bulk
var _cull_timer := 0.0
var _pan_dist := 0.0              # distance dragged with the middle mouse button
var selected_id := ""            # object shown in the HUD's selected-item panel
var gates := {}                  # destination system id -> Celestial
var stations := {}               # station_id -> Celestial
var havens: Array = []           # Pirate Havens (hostile, guns fire on the player)
var _aggro := {}                 # ship instance id -> {ship, station, until}: fired inside a no-fire zone
var _def_cd := {}                # station / haven instance id -> Array of turret cooldowns
var _zone_warned := 0.0          # last "no-fire zone" warning (game time)
var _haven_warned := 0.0
var player: Ship = null
var hovered = null
var input_enabled := true
var follow := true

var _zoom := 0.6
var _min_zoom := 0.0002
var level := 0
var _warp_auto := false
var _warp_saved_zoom := 0.6
var _left_down := false
var _panning := false
var _last_hover := ""
var _npc_counter := 0
var _wreck_counter := 0
var _spots: Array = []           # pirate spawn points {pos, want, ships: Array}
var _respawn_timer := 90.0
var traffic                        # Traffic: shuttles, miners, patrols, live convoys (package 11)
const TrafficScript = preload("res://scripts/world/traffic.gd")
var _t := 0.0


func build(p_system: int) -> void:
	system_id = p_system
	layout = Universe.get_layout(system_id)
	background = SpaceBackground.new()
	add_child(background)
	background.setup(float(system_id) * 1.37 + 0.5, float(system_id) * 0.137, 0.8)
	sky = CanvasLayer.new()
	sky.layer = -9
	add_child(sky)

	body_layer = Node2D.new()
	body_layer.z_index = -20
	add_child(body_layer)
	celestial_layer = Node2D.new()
	add_child(celestial_layer)
	debris_layer = Node2D.new()
	debris_layer.z_index = -2
	celestial_layer.add_child(debris_layer)
	debris_layer.draw.connect(_draw_debris)
	ship_layer = Node2D.new()
	add_child(ship_layer)
	fx_layer = Node2D.new()
	add_child(fx_layer)
	overlay = Node2D.new()
	overlay.z_index = 50
	add_child(overlay)
	overlay.draw.connect(_draw_overlay)
	camera = Camera2D.new()
	add_child(camera)
	camera.make_current()
	var vs := get_viewport_rect().size
	_min_zoom = minf(vs.x, vs.y) / (Universe.SYSTEM_RADIUS * 2.3)
	_set_zoom(_zoom)

	_make_bodies()
	_spawn_celestials()
	sync_player()
	_spawn_pirates()
	_codex_discover()
	traffic = TrafficScript.new()
	traffic.name = "Traffic"
	traffic.view = self
	add_child(traffic)
	if player != null:
		camera.position = player.position


## Codex (package 18): what this system shows the pilot.
func _codex_discover() -> void:
	for f in [Universe.controller(system_id)] + Universe.claimants(system_id):
		if String(f) != "":
			GameState.codex.event("faction:" + String(f))
	if not colossi.is_empty():
		GameState.codex.event("colossus")
	if not havens.is_empty():
		GameState.codex.event("haven")


# ---------------------------------------------------------------- Setup

func _make_bodies() -> void:
	var star: Dictionary = layout["star"]
	var list: Array = [star]
	list.append_array(layout["planets"])
	for b in list:
		var is_star: bool = b["id"] == "star"
		var sky_spr: Sprite2D
		var map_spr: Sprite2D
		if is_star:
			sky_spr = Celestial.make_star_sprite(star["color"], 100.0)
			map_spr = Celestial.make_star_sprite(star["color"], float(star["radius"]))
		else:
			var ldir := (-(b["pos"] as Vector2)).normalized()
			sky_spr = Celestial.make_planet_sprite(b, 100.0, ldir)
			map_spr = Celestial.make_planet_sprite(b, float(b["radius"]), ldir)
		sky.add_child(sky_spr)
		map_spr.position = b["pos"]
		body_layer.add_child(map_spr)
		bodies.append({"data": b, "sky": sky_spr, "map": map_spr, "star": is_star,
			"quad": _quad_factor(b, is_star)})


func _quad_factor(b: Dictionary, is_star: bool) -> float:
	if is_star:
		return 2.0 / 0.45
	return 2.0 / 0.5 if b.get("ring", false) else 2.0 / 0.86


func _add_celestial(kind: String, data: Dictionary) -> Celestial:
	var c := Celestial.new()
	c.view = self
	c.setup(kind, data)
	if kind == "colossus":
		colossi.append(c)
	if kind == "asteroid":
		c.visible = false
		asteroid_nodes.append(c)
	celestial_layer.add_child(c)
	celestials.append(c)
	if data.has("id"):
		by_id[data["id"]] = c
	return c


func _spawn_celestials() -> void:
	for st in layout["stations"]:
		stations[st["id"]] = _add_celestial("station", st)
	for g in layout["gates"]:
		gates[int(g["to"])] = _add_celestial("gate", g)
	for a in layout["asteroids"]:
		_add_celestial("asteroid", a)
	for an in layout["anomalies"]:
		_add_celestial("anomaly", an)
	for co in layout.get("colossi", []):
		_add_celestial("colossus", co)
	for ph in layout.get("havens", []):
		var hv := _add_celestial("haven", ph)
		havens.append(hv)
		stations[ph["id"]] = hv      # dockable with pirate standing (package 12); zone 0 = no no-fire zone


## Makes sure exactly the active ship exists as a node.
func sync_player() -> void:
	var f := GameState.active()
	if player != null and is_instance_valid(player) and (f == null or player.fit != f):
		player.queue_free()
		player = null
	if f == null or f.system_id != system_id or f.in_transit():
		return
	if player == null or not is_instance_valid(player):
		player = Ship.new()
		player.manual = true
		player.setup(f, self)
		ship_layer.add_child(player)
		# package 23: no drone is out after a (re)start; after a jump they fly out again
		for r in f.drones:
			r["out"] = false
		if f.drone_relaunch > 0 and f.docked_at == "":
			var n := f.drone_relaunch
			f.drone_relaunch = 0
			get_tree().create_timer(1.2).timeout.connect(func():
				if player != null and is_instance_valid(player) and not player.is_docked():
					launch_drones(player, n))
		else:
			f.drone_relaunch = 0
		if f.docked_at == "":
			spawn_fx(Fx.flash(player.position, Color(0.6, 0.85, 1.0), player.radius * 3.0))


func remove_player() -> void:
	if player != null and is_instance_valid(player):
		player.queue_free()
	player = null


## gov: government / pirate faction (paint and name); "" = picked from the system for pirates.
func spawn_npc(preset_id: String, pos: Vector2, faction: String = "pirate", gov: String = "") -> Ship:
	_npc_counter += 1
	var f := GameState.create_from_preset(preset_id, faction)
	f.uid = -_npc_counter
	f.system_id = system_id
	if gov == "" and faction == "pirate":
		gov = Universe.pirate_faction(system_id)
	f.gov = gov
	if gov != "":
		GameState.codex.event("faction:" + gov)
	var prefix := "Pirate " if faction == "pirate" else ""
	if FactionData.FACTIONS.has(gov):
		prefix = String(FactionData.FACTIONS[gov]["pilot"]) + " "
	f.ship_name = prefix + String(GameData.hulls[f.hull_id]["name"])
	f.position = pos
	f.rotation = randf() * TAU
	# package 20: some NPCs carry the new equipment – pirates a radar jammer (they use it against
	# you), patrols point defense and shield transfer beams
	var extra := false
	if faction == "pirate" and randf() < PIRATE_JAMMER_CHANCE:
		extra = npc_extra(f, "o_jammer", true) or extra
	elif faction == "patrol":
		if randf() < 0.4:
			extra = npc_extra(f, "w_pointdef", false) or extra
		if randf() < 0.3:
			extra = npc_extra(f, "t_shieldxfer", false) or extra
	if extra:
		f.refill()
	var s := Ship.new()
	s.setup(f, self)
	if faction == "pirate":
		s.archetype = String(GameData.presets[preset_id].get("archetype", ""))
		# not every pirate is wanted; the reward grows with hull value and lawlessness and is
		# put out by a power – some pay better than others (package 13)
		var sec: float = Universe.systems[system_id]["security"]
		s.bounty_by = GameState.rep.issuer(system_id)
		if randf() < 0.75:
			var gen := float(FactionData.FACTIONS.get(s.bounty_by, {}).get("bounty", 1.0)) * GameState.news.bounty_mult(system_id)
			s.bounty = int(float(GameData.hulls[f.hull_id]["price"]) * 0.12 * lerpf(0.8, 1.6, 1.0 - sec) * gen / 10.0) * 10
	ship_layer.add_child(s)
	return s


const ModuleFamilies = preload("res://data/modules.gd")
const PIRATE_JAMMER_CHANCE := 0.22


## Puts a module of family `fam` (quality C, as big as the slot allows) into a free slot of its type –
## or, with `replace_last`, into the last one. False = no room.
func npc_extra(f: ShipFitting, fam: String, replace_last: bool) -> bool:
	var famd: Dictionary = ModuleFamilies.FAMILIES[fam]
	var stype := String(ModuleFamilies.ANCHORS[famd["anchor"]]["slot"])
	var keys: Array = []
	for k in f.slot_keys():
		if String(k).begins_with(stype + "_"):
			keys.append(k)
	var key := ""
	for k2 in keys:
		if String(f.modules.get(k2, "")) == "":
			key = k2
			break
	if key == "" and replace_last and not keys.is_empty():
		key = keys.back()
	if key == "":
		return false
	var size := mini(f.slot_max(key), int(famd["sizes"][1]))
	if size < int(famd["sizes"][0]):
		return false
	var mid := ModuleFamilies.id_of(fam, size, "C")
	if f.can_fit(key, mid) != "":
		return false
	f.set_module(key, mid)
	return true


## Loadout of a new pirate: an archetype (package 14) and its light / medium / heavy preset by security.
func _pirate_preset() -> String:
	var sec: float = Universe.systems[system_id]["security"]
	return String(ArchData.pick(sec)[1])


## Pirates lurk at asteroid fields and anomalies.
func _spawn_pirates() -> void:
	var sec: float = Universe.systems[system_id]["security"]
	if system_id == Universe.home_system:
		return
	var want := int(round((1.0 - sec) * 4.0))
	if want <= 0:
		return
	for f in layout["fields"]:
		_spots.append({"pos": f["pos"], "want": want, "ships": []})
	for an in layout["anomalies"]:
		_spots.append({"pos": an["pos"], "want": want + 1, "ships": []})
	for spot in _spots:
		_fill_spot(spot, false)


func _fill_spot(spot: Dictionary, announce: bool) -> void:
	var alive: Array = []
	for s in spot["ships"]:
		if is_instance_valid(s) and not s.dying:
			alive.append(s)
	spot["ships"] = alive
	var center: Vector2 = spot["pos"]
	while alive.size() < int(spot["want"]):
		var s := spawn_npc(_pirate_preset(), center + Vector2.from_angle(randf() * TAU) * randf_range(500.0, 5000.0))
		s.home = center
		alive.append(s)
	if announce:
		GameState.log_msg("Scanner: pirate activity is increasing.", GameState.COL_WARN)


# ---------------------------------------------------------------- Station raids (package 15)
# A 5-star captain's raid fought live: the station gets a hull bar, its turrets can be shot down
# (pirates bombard turrets first, then the hull) and are knocked offline by ion torpedoes. Raiders
# count as aggressors, so the remaining turrets fire back. Outcomes: the station falls (captain +bounty,
# red star, station offline), the time runs out (station holds), or the captain – about to lose – flees
# and hides. Pilots who helped defend get 20,000 cr and standing.

const STATION_HP := 15000.0          # per station tier
const TURRET_HP := 1200.0
const ION_EVERY := 10.0
const ION_OFF := 25.0
const BOMBARD_RANGE := 5000.0
const FLEE_AT := 0.3                 # the captain runs below 30 % armour + structure
const DEFENCE_REWARD := 20000
const DEFENCE_REP := 4.0
var raid_live := {}                  # {cap, st, hp, hp_max, turrets [{hp, off}], helped, ion_t, beam {}}
var _vanishing: Array = []           # [{ships, t}] – raiders jumping out after fleeing


## Is turret `i` of station `st` still firing (not shot down, not ion-disabled)?
func turret_ok(st, i: int) -> bool:
	if raid_live.is_empty() or raid_live["st"] != st:
		return true
	var t: Dictionary = raid_live["turrets"][i]
	return float(t["hp"]) > 0.0 and float(t["off"]) <= _t


func note_raid_help(ship) -> void:
	if not raid_live.is_empty():
		raid_live["helped"] = true


func _raid_group(id: String) -> Array:
	var e: Dictionary = notorious_ships.get(id, {})
	var out: Array = []
	if e.is_empty():
		return out
	if is_instance_valid(e["leader"]) and not e["leader"].dying:
		out.append(e["leader"])
	for s in e["escorts"]:
		if is_instance_valid(s) and not s.dying:
			out.append(s)
	return out


func _try_begin_raid() -> void:
	if GameState.notorious == null:
		return
	for c in GameState.notorious.alive_in(system_id):
		var r: Dictionary = c["raid"]
		if r.is_empty() or String(r["state"]) != "active" or not notorious_ships.has(c["id"]):
			continue
		var st = stations.get(String(r["station"]))
		var group := _raid_group(String(c["id"]))
		if st == null or not is_instance_valid(st) or group.is_empty():
			continue
		var tl: Array = st.art.get("turrets", [])
		var turrets: Array = []
		for i in tl.size():
			turrets.append({"hp": TURRET_HP, "off": 0.0})
		var hpm := STATION_HP * float(st.data.get("tier", 1))
		raid_live = {"cap": String(c["id"]), "st": st, "hp": hpm, "hp_max": hpm, "turrets": turrets, "helped": false, "ion_t": ION_EVERY * 0.5, "beam": {}}
		r["live"] = true
		var wt := Universe.warp_target(system_id, String(st.data["id"]))
		for s in group:
			s.raiding = true
			s.home = st.position
			s._wander = Vector2.ZERO
			if s.position.distance_to(st.position) > 30000.0 and not wt.is_empty():
				s.set_order({"type": "warp", "target": wt, "then": {}})
		GameState.log_msg("RAID: %s attacks %s – the station's hull and turrets are under fire!" % [NotoriousData.title(c), st.title()], GameState.COL_BAD)
		return


static func _dps(s: Ship) -> float:
	var d := 0.0
	for w in s.fit.stats()["weapons"]:
		d += float(w["damage"]) / maxf(float(w["cooldown"]), 0.1)
	return d


func _update_raid(delta: float) -> void:
	for v in _vanishing.duplicate():
		v["t"] = float(v["t"]) - delta
		if float(v["t"]) <= 0.0:
			for s in v["ships"]:
				if is_instance_valid(s) and not s.dying:
					spawn_fx(Fx.flash(s.position, Color(1.0, 0.4, 0.3), s.radius * 3.0))
					s.queue_free()
			_vanishing.erase(v)
	if raid_live.is_empty():
		_try_begin_raid()
		return
	var cap: Dictionary = GameState.notorious.get_captain(String(raid_live["cap"]))
	var st = raid_live["st"]
	if cap.is_empty() or not cap["alive"] or not is_instance_valid(st):
		_end_raid("killed")
		return
	var r: Dictionary = cap["raid"]
	var group := _raid_group(String(cap["id"]))
	if group.is_empty():
		_end_raid("killed")
		return
	var lead: Ship = group[0]
	# the station's guns treat the raiders as aggressors
	for s in group:
		_aggro[s.get_instance_id()] = {"ship": s, "station": st, "until": _t + 3.0}
	# about to lose: the captain flees and hides
	var ls := lead.fit.stats()
	if lead.notorious_id != "" and lead.fit.armor + lead.fit.structure < (float(ls["armor_max"]) + float(ls["structure_max"])) * FLEE_AT:
		GameState.log_msg("%s is badly hurt and breaks off the raid on %s – the pirates flee!" % [lead.display_name(), st.title()], GameState.COL_GOOD)
		GameState.notorious.raid_repelled(cap, true)
		for s in group:
			s.raiding = false
			s._called_help = true
			s.order = {"type": "idle"}
			s._start_fleeing(s.last_attacker)
			_aggro.erase(s.get_instance_id())
		_vanishing.append({"ships": group, "t": 8.0})
		notorious_ships.erase(String(cap["id"]))
		_end_raid("fled")
		return
	# bombardment: turrets first, then the hull
	var tl: Array = st.art.get("turrets", [])
	for s in group:
		if s.fleeing or s.in_warp() or s.position.distance_to(st.position) > float(st.radius) + BOMBARD_RANGE:
			continue
		if s.target != null and is_instance_valid(s.target) and not s.target.dying:
			continue                 # busy fighting ships
		var dmg := _dps(s) * delta
		var aim: Vector2 = st.position
		var ti := -1
		for i in raid_live["turrets"].size():
			if float(raid_live["turrets"][i]["hp"]) > 0.0:
				ti = i
				break
		if ti >= 0:
			var t: Dictionary = raid_live["turrets"][ti]
			t["hp"] = float(t["hp"]) - dmg
			aim = st.position + (tl[ti] as Vector2)
			if float(t["hp"]) <= 0.0:
				spawn_fx(Fx.explosion(aim, 60.0, Color(1.0, 0.6, 0.2)))
				if player != null and is_instance_valid(player):
					GameState.log_msg("%s: a defence turret was shot down (%d left)." % [st.title(), _turrets_left()], GameState.COL_WARN)
		else:
			raid_live["hp"] = float(raid_live["hp"]) - dmg
			aim = st.position + Vector2.from_angle(randf() * TAU) * float(st.radius) * 0.4
		var key: int = s.get_instance_id()
		raid_live["beam"][key] = float(raid_live["beam"].get(key, 0.0)) - delta
		if float(raid_live["beam"][key]) <= 0.0:
			raid_live["beam"][key] = randf_range(0.6, 1.1)
			spawn_fx(Fx.beam(s.position, aim, Color(1.0, 0.4, 0.3), 3.0))
			spawn_fx(Fx.explosion(aim, 18.0, Color(1.0, 0.55, 0.25)))
	# ion torpedoes knock turrets offline
	raid_live["ion_t"] = float(raid_live["ion_t"]) - delta
	if float(raid_live["ion_t"]) <= 0.0 and lead.fit.modules.values().has(GameData.legacy_id("w_ion_torpedo")) and not lead.in_warp():
		raid_live["ion_t"] = ION_EVERY
		ion_strike()
	if float(raid_live["hp"]) <= 0.0:
		spawn_fx(Fx.explosion(st.position, float(st.radius) * 0.8, Color(1.0, 0.5, 0.2)))
		GameState.notorious.raid_won(cap)
		_end_raid("won")
		return
	if GameState.play_time >= float(r.get("until", 0.0)):
		GameState.log_msg("%s holds out – %s gives up the raid." % [st.title(), NotoriousData.title(cap)], GameState.COL_GOOD)
		GameState.notorious.raid_repelled(cap, false)
		_end_raid("held")


## An ion torpedo from the captain knocks one working turret offline for ION_OFF seconds.
func ion_strike() -> bool:
	if raid_live.is_empty():
		return false
	var st = raid_live["st"]
	var group := _raid_group(String(raid_live["cap"]))
	if group.is_empty():
		return false
	var lead: Ship = group[0]
	var tl: Array = st.art.get("turrets", [])
	var cands: Array = []
	for i in raid_live["turrets"].size():
		if turret_ok(st, i):
			cands.append(i)
	if cands.is_empty():
		return false
	var i: int = cands[randi() % cands.size()]
	raid_live["turrets"][i]["off"] = _t + ION_OFF
	var tp: Vector2 = st.position + (tl[i] as Vector2)
	spawn_fx(Fx.beam(lead.position, tp, ION_COLOR, 5.0))
	spawn_fx(Fx.explosion(tp, 70.0, ION_COLOR))
	if player != null and is_instance_valid(player) and player.position.distance_to(st.position) < 80000.0:
		GameState.log_msg("%s: an ion torpedo knocks a defence turret offline for %d s!" % [st.title(), int(ION_OFF)], GameState.COL_WARN)
	return true


func _turrets_left() -> int:
	var n := 0
	for t in raid_live.get("turrets", []):
		if float(t["hp"]) > 0.0:
			n += 1
	return n


## outcome: won (station fell) | held | fled | killed (captain died)
func _end_raid(outcome: String) -> void:
	if raid_live.is_empty():
		return
	var st = raid_live["st"]
	var cap: Dictionary = GameState.notorious.get_captain(String(raid_live["cap"]))
	if not cap.is_empty() and not (cap["raid"] as Dictionary).is_empty():
		cap["raid"]["live"] = false
	for s in _raid_group(String(raid_live["cap"])):
		s.raiding = false
		_aggro.erase(s.get_instance_id())
	if outcome != "won" and bool(raid_live["helped"]) and is_instance_valid(st):
		GameState.add_credits(DEFENCE_REWARD)
		GameState.log_msg("%s thanks you for defending the station: %s." % [st.title(), GameData.fmt_credits(DEFENCE_REWARD)], GameState.COL_GOOD)
		GameState.rep.change(String(st.data.get("faction", "")), DEFENCE_REP, "you defended %s" % st.title())
	raid_live = {}


func _exit_tree() -> void:
	# leaving the system during a live raid: the cluster simulation takes over again
	if not raid_live.is_empty():
		var cap: Dictionary = GameState.notorious.get_captain(String(raid_live["cap"]))
		if not cap.is_empty() and not (cap["raid"] as Dictionary).is_empty():
			cap["raid"]["live"] = false
		raid_live = {}


func _draw_raid(o: Node2D, px: float) -> void:
	if raid_live.is_empty() or not is_instance_valid(raid_live["st"]):
		return
	var st = raid_live["st"]
	var w := 180.0 * px
	var top: Vector2 = st.position + Vector2(-w * 0.5, -(float(st.radius) + 40.0 * px))
	var k := clampf(float(raid_live["hp"]) / maxf(float(raid_live["hp_max"]), 1.0), 0.0, 1.0)
	o.draw_rect(Rect2(top, Vector2(w, 8.0 * px)), Color(0, 0, 0, 0.7))
	o.draw_rect(Rect2(top, Vector2(w * k, 8.0 * px)), Color(1.0 - k, 0.35 + 0.5 * k, 0.3))
	o.draw_rect(Rect2(top, Vector2(w, 8.0 * px)), Color(1, 1, 1, 0.8), false, 1.0 * px)
	var tl: Array = st.art.get("turrets", [])
	for i in raid_live["turrets"].size():
		var tp: Vector2 = st.position + (tl[i] as Vector2)
		var t: Dictionary = raid_live["turrets"][i]
		var sz := 9.0 * px
		if float(t["hp"]) <= 0.0:
			o.draw_line(tp - Vector2(sz, sz), tp + Vector2(sz, sz), Color(1.0, 0.25, 0.2), 2.5 * px)
			o.draw_line(tp - Vector2(sz, -sz), tp + Vector2(sz, -sz), Color(1.0, 0.25, 0.2), 2.5 * px)
		elif float(t["off"]) > _t:
			o.draw_arc(tp, sz * 1.3, 0.0, TAU, 16, ION_COLOR, 2.0 * px)
		else:
			var tk := clampf(float(t["hp"]) / TURRET_HP, 0.0, 1.0)
			o.draw_rect(Rect2(tp + Vector2(-sz, sz * 1.4), Vector2(sz * 2.0 * tk, 2.5 * px)), Color(0.4, 1.0, 0.5))


# ---------------------------------------------------------------- Notorious pirates (package 15)

const NotoriousData = preload("res://scripts/core/notorious.gd")
var notorious_ships := {}        # captain id -> {"leader": Ship, "escorts": [Ship]}
var _notorious_t := 0.0


## Spawns captains that are in this system; called on load and every second.
func _sync_notorious(arriving: bool) -> void:
	if GameState.notorious == null:
		return
	for c in GameState.notorious.alive_in(system_id):
		var e: Dictionary = notorious_ships.get(c["id"], {})
		if not e.is_empty() and is_instance_valid(e["leader"]) and not e["leader"].dying:
			continue
		if not e.is_empty():
			continue                 # killed here – the cluster sim already knows
		_spawn_captain(c, arriving)


func _spawn_captain(c: Dictionary, arriving: bool) -> Ship:
	var pos := Vector2.ZERO
	var spots: Array = []
	for f in layout["fields"]:
		spots.append(f["pos"])
	for an in layout["anomalies"]:
		spots.append(an["pos"])
	for hv in layout.get("havens", []):
		spots.append(hv["pos"])
	if spots.is_empty():
		spots.append(Vector2.from_angle(randf() * TAU) * 600000.0)
	if not NotoriousData.lawless(system_id) and not layout["fields"].is_empty():
		spots.clear()               # visiting safer space: they lurk in the asteroid fields
		for f in layout["fields"]:
			spots.append(f["pos"])
	pos = spots[randi() % spots.size()] + Vector2.from_angle(randf() * TAU) * randf_range(3000.0, 9000.0)
	if arriving and not layout["gates"].is_empty():
		var g: Dictionary = layout["gates"][randi() % layout["gates"].size()]
		pos = (g["pos"] as Vector2) * 0.97
	pos = clear_of_zones(pos)
	var raid_st = null
	if not (c.get("raid", {}) as Dictionary).is_empty() and String(c["raid"].get("state", "active")) == "active":
		raid_st = stations.get(String(c["raid"]["station"]))
		if raid_st != null and is_instance_valid(raid_st):
			pos = raid_st.position + Vector2.from_angle(randf() * TAU) * float(raid_st.data.get("zone", 15000.0)) * 0.6
		else:
			raid_st = null
	var lead := spawn_npc(String(c["preset"]), pos, "pirate", String(c["faction"]))
	lead.archetype = String(c["archetype"])
	lead.notorious_id = String(c["id"])
	lead.special = String(c["trait"])
	lead.toughness = NotoriousData.toughness(c)
	lead.raiding = raid_st != null
	if int(c["stars"]) >= 5:
		lead.fit.modules["weapon_0"] = GameData.legacy_id("w_ion_torpedo")
		lead.fit.mark_dirty()
	lead.fit.ship_name = NotoriousData.title(c)
	lead.paint = "notorious_%d" % int(c["paint"])
	lead.bounty = int(c["bounty"])
	lead.bounty_by = GameState.rep.issuer(system_id)
	lead.warrant_known = true        # everyone knows these faces
	lead.home = pos
	var esc: Array = []
	var i := 0
	for preset in c["escorts"]:
		var s := spawn_npc(String(preset), pos + Vector2.from_angle(i * 1.7) * (500.0 + i * 250.0), "pirate", String(c["faction"]))
		s.escort_of = lead
		s.home = pos
		s.raiding = raid_st != null
		s.fit.ship_name = "%s's %s" % [String(c["nick"]).trim_prefix("the ").capitalize(), GameData.hulls[s.fit.hull_id]["name"]]
		esc.append(s)
		i += 1
	notorious_ships[c["id"]] = {"leader": lead, "escorts": esc, "spawned": esc.size()}
	GameState.news.radio("Pirate captain %s sighted near %s with %d escorts." % [NotoriousData.title(c), landmark(pos), esc.size()], system_id)
	GameState.codex.event("notorious")
	if player != null and is_instance_valid(player):
		GameState.log_msg("Sensors: notorious pirate %s (%s) is in the system with %d escorts!" % [NotoriousData.title(c), NotoriousData.stars_text(c), esc.size()], GameState.COL_BAD)
		if raid_st != null:
			GameState.log_msg("%s is RAIDING %s!" % [NotoriousData.title(c), raid_st.title()], GameState.COL_BAD)
	return lead


## Escorts fly in formation around their captain and join its fights.
func _update_notorious(delta: float) -> void:
	_notorious_t -= delta
	if _notorious_t > 0.0:
		return
	_notorious_t = 0.5
	_sync_notorious(true)
	for id in notorious_ships.keys():
		var e: Dictionary = notorious_ships[id]
		var lead = e["leader"]
		var alive: Array = []
		for s in e["escorts"]:
			if is_instance_valid(s) and not s.dying:
				alive.append(s)
		e["escorts"] = alive
		if not is_instance_valid(lead) or lead.dying:
			for s in alive:
				s.escort_of = null   # leaderless: ordinary pirates now
				s.raiding = false
			continue
		var cap: Dictionary = GameState.notorious.get_captain(String(id))
		if not cap.is_empty():
			lead.bounty = int(cap["bounty"])
			lead.toughness = NotoriousData.toughness(cap)
			# the crew grows while it lives: newcomers warp in next to the captain
			var plan: Array = cap["escorts"]
			while int(e["spawned"]) < plan.size():
				var ns := spawn_npc(String(plan[int(e["spawned"])]), lead.position + Vector2.from_angle(randf() * TAU) * 900.0, "pirate", String(cap["faction"]))
				ns.escort_of = lead
				ns.home = lead.home
				ns.raiding = lead.raiding
				spawn_fx(Fx.flash(ns.position, Color(1.0, 0.4, 0.3), ns.radius * 3.0))
				alive.append(ns)
				e["spawned"] = int(e["spawned"]) + 1
		var i := 0
		for s in alive:
			i += 1
			if s.in_warp() or s.fleeing:
				continue
			var tgt = lead.target if (lead.target != null and is_instance_valid(lead.target)) else null
			if tgt != null:
				if s.target == null and String(s.order.get("type", "")) != "attack":
					s.set_order({"type": "attack", "target": tgt})
			elif s.target == null and (String(s.order.get("type", "")) != "keep" or s.order.get("node") != lead):
				s.set_order({"type": "keep", "node": lead, "r": 450.0 + i * 280.0})


func pirate_count() -> int:
	var c := 0
	for n in ship_layer.get_children():
		if n is Ship and n.faction == "pirate" and not n.dying:
			c += 1
	return c


# ---------------------------------------------------------------- Loop

func _process(delta: float) -> void:
	_t += delta
	_jam_tick -= delta
	if _jam_tick <= 0.0:
		_jam_tick = 0.5
		_apply_jamming()
		_market_tick(0.5)
	_update_camera(delta)
	_update_bodies()
	background.follow(camera)
	_update_hover()
	if sky_alpha() > 0.01:
		debris_layer.queue_redraw()
	_cull_timer -= delta
	if _cull_timer <= 0.0:
		_cull_timer = 0.2
		_cull_asteroids()
	_update_defence(delta)
	_update_interdict()
	_update_notorious(delta)
	_update_raid(delta)
	_respawn_timer -= delta
	if _respawn_timer <= 0.0:
		_respawn_timer = 120.0
		for spot in _spots:
			if player == null or player.position.distance_to(spot["pos"]) > 150000.0:
				_fill_spot(spot, false)
	# Glide smoothly to the target zoom level (unless the warp is steering the camera)
	if not (_warp_auto and player != null and is_instance_valid(player) and player.in_warp()):
		var target := level_zoom(level)
		if absf(log(_zoom) - log(target)) > 0.001:
			_set_zoom(exp(lerpf(log(_zoom), log(target), 1.0 - exp(-delta * 9.0))))
		else:
			_set_zoom(target)
	var ls := 1.0 / camera.zoom.x
	var show := camera.zoom.x > switch_zoom()
	if Celestial.label_scale != ls or Celestial.show_labels != show:
		Celestial.label_scale = ls
		Celestial.show_labels = show
		for c in celestials:
			if is_instance_valid(c):
				c.queue_redraw()
	overlay.queue_redraw()


func level_zoom(l: int) -> float:
	if l == 1:
		# recon: the radar shows exactly the recon range, whatever the window size
		var vs := get_viewport_rect().size
		return minf(vs.x, vs.y) * RADAR_SCREEN / GameData.RECON_RANGE
	return _min_zoom if l >= 2 else float(LEVEL_ZOOMS[l])


## Boundary between the local view (background bodies) and the system map.
func switch_zoom() -> float:
	return sqrt(level_zoom(1) * level_zoom(2))


## 1 = bodies in the background, 0 = flat map. The two ranges never overlap.
func sky_alpha() -> float:
	var zs := switch_zoom()
	return clampf((camera.zoom.x - zs) / (zs * 0.6), 0.0, 1.0)


func map_alpha() -> float:
	var zs := switch_zoom()
	return clampf((zs - camera.zoom.x) / (zs * 0.4), 0.0, 1.0)


func set_level(l: int) -> void:
	l = clampi(l, 0, 2)
	_warp_auto = false
	if l != level:
		level = l
		level_changed.emit(level)


func _set_zoom(z: float) -> void:
	_zoom = clampf(z, _min_zoom, MAX_ZOOM)
	camera.zoom = Vector2(_zoom, _zoom)


func _update_camera(delta: float) -> void:
	if input_enabled and get_viewport().gui_get_focus_owner() == null:
		var move := Vector2.ZERO
		if Input.is_action_pressed("cam_up"):
			move.y -= 1
		if Input.is_action_pressed("cam_down"):
			move.y += 1
		if Input.is_action_pressed("cam_left"):
			move.x -= 1
		if Input.is_action_pressed("cam_right"):
			move.x += 1
		if move != Vector2.ZERO:
			follow = false
			camera.position += move.normalized() * 900.0 * delta / camera.zoom.x
		_key_flight()
	# Automatic zoom during warp: out, watch, back in
	if player != null and is_instance_valid(player) and player.in_warp() and _warp_auto:
		var p := player.warp_progress()
		var dist := (player.warp["from"] as Vector2).distance_to(player.warp["to"])
		var vs := get_viewport_rect().size
		var far_zoom := clampf(minf(vs.x, vs.y) / (dist * 1.4), _min_zoom, _warp_saved_zoom)
		var k := 1.0
		if p < 0.25:
			k = smoothstep(0.0, 0.25, p)
		elif p > 0.78:
			k = 1.0 - smoothstep(0.78, 1.0, p)
		_set_zoom(exp(lerpf(log(_warp_saved_zoom), log(far_zoom), k)))
	if follow and player != null and is_instance_valid(player):
		camera.position = player.position
	camera.position = camera.position.limit_length(Universe.SYSTEM_RADIUS * 1.05)


## Keyboard / gamepad flight: the ship flies in the pressed direction (screen up = north) as long as
## a key is held and stops when it is released.
var _key_flying := false


func key_direction() -> Vector2:
	var d := Vector2.ZERO
	if Input.is_action_pressed("ship_up"):
		d.y -= 1
	if Input.is_action_pressed("ship_down"):
		d.y += 1
	if Input.is_action_pressed("ship_left"):
		d.x -= 1
	if Input.is_action_pressed("ship_right"):
		d.x += 1
	return d


func _key_flight() -> void:
	steer(key_direction())


## Flies the pilot's ship in direction `d` (zero = release: brake).
func steer(d: Vector2) -> void:
	if player == null or not is_instance_valid(player) or player.in_warp() or player.is_docked() or player.dying:
		_key_flying = false
		return
	# review (co-op): keyboard flight goes through the command bus like every other player order
	if d != Vector2.ZERO:
		_key_flying = true
		follow = true
		Commands.execute({"type": "key_steer", "x": d.x, "y": d.y})
	elif _key_flying:
		_key_flying = false
		Commands.execute({"type": "key_steer", "x": 0.0, "y": 0.0})


func center_on_player() -> void:
	follow = true
	if player != null and is_instance_valid(player):
		camera.position = player.position


## Star and planets: background bodies when close, flat on the map when far.
func _update_bodies() -> void:
	var z := camera.zoom.x
	var vs := get_viewport_rect().size
	var vmin := minf(vs.x, vs.y)
	var center := vs * 0.5
	var sky_a := sky_alpha()
	var map_a := map_alpha()
	for b in bodies:
		var data: Dictionary = b["data"]
		var r: float = data["radius"]
		var bpos: Vector2 = data["pos"]
		var quad: float = b["quad"]
		var sky_spr: Sprite2D = b["sky"]
		var map_spr: Sprite2D = b["map"]
		# Background representation
		var d := bpos - camera.position
		var dist := maxf(d.length(), 1.0)
		# Don't hide during a fly-over (camera inside/near the planet):
		# size is capped and the planet glides under the ship instead of flipping sides.
		var dist_eff := maxf(dist, r * 1.1)
		var app_r := minf(r * 420.0 / dist_eff, vmin * 0.42)
		if sky_a > 0.01 and app_r >= 2.0:
			sky_spr.visible = true
			# close bodies move towards the edge ("oblique" view of the planet), far ones towards the centre
			var side := clampf((dist - r) / (r * 2.0), 0.0, 1.0)   # 0 = directly above, 1 = to the side
			var off := minf(dist * 0.00035 + app_r * 0.9 * side, vmin * 0.5 + app_r * 0.4)
			sky_spr.position = center + d / dist * off
			sky_spr.scale = Vector2.ONE * app_r * quad / 64.0
			sky_spr.modulate.a = sky_a
			sky_spr.z_index = -clampi(int(dist / 1000.0), 0, 4000)
			_set_pixels(sky_spr, app_r * quad / 3.0)
		else:
			sky_spr.visible = false
		# Map representation (true position, minimum on-screen size)
		if map_a > 0.01:
			map_spr.visible = true
			var min_px := 14.0 if b["star"] else 6.0
			var rs := maxf(r * z, min_px)
			map_spr.scale = Vector2.ONE * (rs / z) * quad / 64.0
			map_spr.modulate.a = map_a
			_set_pixels(map_spr, rs * quad / 3.0)
		else:
			map_spr.visible = false


func _set_pixels(spr: Sprite2D, px: float) -> void:
	var mat := spr.material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("pixels", clampf(px, 16.0, 420.0))


# ---------------------------------------------------------------- Input

func _screen_to_world(p: Vector2) -> Vector2:
	return camera.position + (p - get_viewport_rect().size / 2.0) / camera.zoom.x


func _zoom_at(factor: float, _screen_pos: Vector2) -> void:
	set_level(level + (1 if factor < 1.0 else -1))


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		match mb.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				if mb.pressed:
					_zoom_at(1.2, mb.position)
			MOUSE_BUTTON_WHEEL_DOWN:
				if mb.pressed:
					_zoom_at(1.0 / 1.2, mb.position)
			MOUSE_BUTTON_MIDDLE:
				# Drag = pan the camera; a clean click (no drag) = its bound action
				# (default: centre on ship), handled like a hotkey by main.gd.
				if mb.pressed:
					_panning = true
					_pan_dist = 0.0
				else:
					_panning = false
					if _pan_dist < 6.0:
						var ev := InputEventMouseButton.new()
						ev.button_index = MOUSE_BUTTON_MIDDLE
						ev.pressed = true
						_forward_hotkey(ev)
			MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT:
				if mb.pressed:
					click(_screen_to_world(mb.position))
			_:
				_forward_hotkey(mb)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _panning:
		var rel := (event as InputEventMouseMotion).relative
		_pan_dist += rel.length()
		if _pan_dist >= 6.0:
			follow = false
			camera.position -= rel / camera.zoom.x


## Extra mouse buttons can be bound to game actions (Settings → Controls).
func _forward_hotkey(ev: InputEvent) -> void:
	var main := get_tree().current_scene
	if main != null and main.has_method("handle_input"):
		main.handle_input(ev)


## Returns {kind: ship/celestial/body, node|target} or {}.
func pick(pos: Vector2) -> Dictionary:
	var z := camera.zoom.x
	var tol := 12.0 / z
	var best := {}
	var best_d := INF
	# System level: big objects (stations, gates, fields, planets, star, anomalies) win,
	# with a generous click area around their icon – ships and asteroids come second.
	if z < switch_zoom():
		var grab := 26.0 / z
		for t in Universe.warp_targets(system_id):
			var r := grab
			if t["kind"] in ["star", "planet", "field"]:
				r = maxf(float(t["data"]["radius"]), grab)
			var d := pos.distance_to(t["pos"])
			if d < r and d / r < best_d:
				best_d = d / r
				best = {"kind": "body", "target": t}
		if not best.is_empty():
			return best
		best_d = INF
	for n in ship_layer.get_children():
		if n is Ship and (n.is_targetable() or (n.in_warp() and not n.dying)) and n != player and not under_colossus(n.position):
			var d := pos.distance_to(n.position)
			if d < n.radius + tol and d < best_d:
				best_d = d
				best = {"kind": "ship", "node": n}
	if not best.is_empty():
		return best
	for c in celestials:
		if is_instance_valid(c) and c.is_pickable():
			var d := pos.distance_to(c.position)
			var r: float = c.radius
			if c.kind == "colossus":
				# the outline counts, not the bounding circle
				if d > r + tol or ColossusShape.signed_dist(c.poly, pos - c.position) > tol:
					continue
				d = maxf(d, r * 0.5)   # smaller objects in front of it still win
			if c.kind in ["station", "gate"] or (c.kind == "anomaly"):
				r = maxf(r, 14.0 / z)
			if d < r + tol and d < best_d:
				best_d = d
				best = {"kind": "celestial", "node": c}
	if not best.is_empty():
		return best
	# Celestial bodies and asteroid fields (mostly in map mode)
	for t in Universe.warp_targets(system_id):
		if t["kind"] in ["station", "gate", "anomaly"]:
			continue
		var r := 14.0 / z
		if t["kind"] in ["star", "planet"]:
			r = maxf(float(t["data"]["radius"]), r)
		elif t["kind"] == "field" and z < switch_zoom():
			r = maxf(float(t["data"]["radius"]), r)
		else:
			continue
		var d := pos.distance_to(t["pos"])
		if d < r and d < best_d:
			best_d = d
			best = {"kind": "body", "target": t}
	return best


func click(pos: Vector2) -> void:
	if player == null or not is_instance_valid(player):
		return
	var p := pick(pos)
	match String(p.get("kind", "")):
		"ship", "celestial":
			select(Ship.object_key(p["node"]))
		"body":
			select(String(p["target"]["id"]))
		_:
			Commands.execute({"type": "move", "pos": pos})


## Shows an object in the HUD's selected-item panel (UI only – no game state change).
func select(id: String) -> void:
	selected_id = id
	object_selected.emit(id)


# ---------------------------------------------------------------- Objects by id
# Ids: celestial / warp-target ids ("st_3_0", "a_1_12", "planet_2", "star") or "ship:<uid>".

func find_object(id: String):
	if id.begins_with("ship:"):
		var uid := id.substr(5).to_int()
		for n in ship_layer.get_children():
			if n is Ship and n.fit.uid == uid and not n.dying:
				return n
		return null
	var c = by_id.get(id)
	if c != null and is_instance_valid(c):
		return c
	return null


## {id, name, kind, pos, node?} for any selectable object, or {}.
func describe(id: String) -> Dictionary:
	var n = find_object(id)
	if n != null:
		if n is Ship:
			return {"id": id, "name": n.display_name(), "kind": "ship", "pos": n.position, "node": n}
		return {"id": id, "name": n.title(), "kind": n.kind, "pos": n.position, "node": n}
	var t := Universe.warp_target(system_id, id)
	if t.is_empty():
		return {}
	return {"id": id, "name": t["name"], "kind": t["kind"], "pos": t["pos"]}


# ---------------------------------------------------------------- Orders (called by the command bus)

func order_move(pos: Vector2) -> void:
	var d := player.position.distance_to(pos)
	player.set_order({"type": "move", "pos": pos})
	spawn_fx(Fx.marker(pos, Color(0.3, 1.0, 0.5)))
	if d > 150000.0:
		var mins := d / maxf(float(player.fit.stats()["speed"]), 1.0) / 60.0
		GameState.log_msg("Sublight flight: approx. %d min. Click an object to warp for fast travel." % int(mins), GameState.COL_WARN)


func order_attack(uid: int) -> String:
	for n in ship_layer.get_children():
		if n is Ship and n.fit.uid == uid and n.is_targetable() and n.faction != "player":
			player.set_order({"type": "attack", "target": n})
			spawn_fx(Fx.marker(n.position, Color(1.0, 0.3, 0.3)))
			return ""
	return "Target not found."


## Movement relative to an object: approach / orbit / keep at range. Far away -> warp first.
func order_relative(kind: String, id: String, r: float) -> String:
	var d := describe(id)
	if d.is_empty():
		return "Unknown object."
	var o := {"type": kind, "id": id, "r": r}
	if not d.has("node"):
		command_target(Universe.warp_target(system_id, id), {})
		return ""
	if player.position.distance_to(d["pos"]) > Universe.WARP_MIN:
		var wt := Universe.warp_target(system_id, id)
		if wt.is_empty():
			wt = {"id": id, "kind": d["kind"], "name": d["name"], "pos": d["pos"], "land": float(d["node"].radius) + maxf(r, 800.0)}
		command_target(wt, o)
	else:
		player.set_order(resolve_order(o))
	return ""


## Follow a friendly ship – also into warp and through gates (package 17).
func order_follow(id: String) -> String:
	var n = find_object(id)
	if n == null or not (n is Ship) or n == player:
		return "Nothing to follow."
	if not n.escort_mark:
		return "You can only follow ships under your protection (marked green)."
	if traffic != null:
		var lead = traffic.group_leader(n)
		if lead != null:
			n = lead                 # the convoy goes where its lead ship goes
	player.set_order({"type": "follow", "node": n, "r": 800.0})
	if traffic != null:
		GameState.follow_convoy = traffic.convoy_of(n)
	if n.escort_kind == "patrol":
		GameState.log_msg("Following the %s – you stay with the patrol, in warp too." % n.display_name(), GameState.COL_INFO)
		return ""
	GameState.log_msg("Following %s – you stay with it, in warp too." % n.display_name(), GameState.COL_INFO)
	return ""


# ---------------------------------------------------------------- Package 20: mines & jamming

const MineScript = preload("res://scripts/world/mine.gd")
const JAM_VISIBLE := 3000.0      # jammed pilot: ships closer than this still show up
var _jam_tick := 0.0


## Lays a mine behind `ship` (mine launcher).
func lay_mine(ship: Ship, kind: String, slot: String, fuse: float, power: float):
	var m = MineScript.new()
	m.setup(ship, kind, slot, fuse, power, self)
	fx_layer.add_child(m)
	spawn_fx(Fx.flash(m.position, Color(GameData.MINES[kind]["color"]), 30.0))
	return m


## Mines of `ship` from launcher `slot` still out there.
func mines_of(ship: Ship, slot: String) -> int:
	var n := 0
	for m in get_tree().get_nodes_in_group("mines"):
		if is_instance_valid(m) and not m.is_queued_for_deletion() and m.layer == ship and m.slot == slot:
			n += 1
	return n


## Radar jammers that are running jam every hostile ship within their radius.
func _apply_jamming() -> void:
	var jammers: Array = []
	for n in ship_layer.get_children():
		if n is Ship and not n.dying:
			var r: float = n.jam_radius()
			if r > 0.0:
				jammers.append([n, r])
	for j in jammers:
		for n2 in ship_layer.get_children():
			if n2 is Ship and n2 != j[0] and not n2.dying and Ship.hostile(j[0], n2) and n2.position.distance_to(j[0].position) <= float(j[1]):
				n2.jam(1.0)


# ---------------------------------------------------------------- Package 25b: on-board market

const MARKET_TRADER_EVERY := Vector2(25.0, 50.0)   # seconds between two traders
const MARKET_PIRATE_VALUE := 60000                  # offers worth more than this attract pirates
const MARKET_PIRATE_CHECK := 45.0
var _market_t := 20.0
var _market_pirate_t := MARKET_PIRATE_CHECK
var market_buyers: Array = []                       # [{ship, done, leave_t, drone}]
var market_runway = null                            # the trader drone using the market ship's runway (0.4.25.41)
const MarketDroneScript = preload("res://scripts/world/market_drone.gd")
const MARKET_PARK := 1600.0                         # traders park this far away and send a cargo drone


## What traders are used to paying for `item` (commodity base price, modules at 60 % of their price).
static func market_base_price(item: String) -> int:
	if item.begins_with("mod:"):
		return int(float(GameData.modules.get(item.substr(4), {}).get("price", 100)) * 0.6)
	return int(GameData.commodities.get(item, {}).get("price", 10))


## The pilot's market is open: ship with an open market, standing still in space.
func market_active() -> bool:
	if player == null or not is_instance_valid(player) or player.is_docked() or player.in_warp():
		return false
	var f: ShipFitting = player.fit
	return f.hull().has("market") and f.market_open and not f.market_offers.is_empty() and player.velocity.length() < 15.0


func _market_tick(dt: float) -> void:
	for b in market_buyers.duplicate():
		var sh = b["ship"]
		if sh == null or not is_instance_valid(sh) or sh.dying:
			market_buyers.erase(b)
			continue
		var near: bool = player != null and is_instance_valid(player) and sh.position.distance_to(player.position) < MARKET_PARK + 700.0
		if not b["done"] and b.get("drone") == null and near and player.has_deck():
			# 0.4.25.41: a ship with a flight deck – the trader sends a cargo drone that lands on the runway
			var md = MarketDroneScript.new()
			md.setup(self, sh, player)
			ship_layer.add_child(md)
			b["drone"] = md
			sh.set_order({"type": "idle"})
			sh.velocity = Vector2.ZERO
			sh.activity = "Cargo drone at your market"
		elif not b["done"] and b.get("drone") == null and near and sh.position.distance_to(player.position) < 800.0:
			b["done"] = true
			market_trade(sh)
			_market_leave(b)
		elif b["done"]:
			b["leave_t"] = float(b["leave_t"]) - dt
			if float(b["leave_t"]) <= 0.0:
				spawn_fx(Fx.flash(sh.position, Color(0.6, 0.85, 1.0), sh.radius * 3.0))
				sh.queue_free()
				market_buyers.erase(b)
	if not market_active():
		return
	_market_t -= dt
	if _market_t <= 0.0:
		_market_t = randf_range(MARKET_TRADER_EVERY.x, MARKET_TRADER_EVERY.y)
		var tr: Ship = spawn_npc("civ_freighter" if randf() < 0.4 else "civ_shuttle", player.position + Vector2.from_angle(randf() * TAU) * 7000.0, "civilian", Universe.controller(system_id) if Universe.controller(system_id) in FactionData.POWERS else "")
		var park := 450.0 if not player.has_deck() else MARKET_PARK
		tr.set_order({"type": "move", "pos": player.position + Vector2.from_angle(randf() * TAU) * park})
		tr.activity = "Coming to trade"
		market_buyers.append({"ship": tr, "done": false, "leave_t": 0.0})
		GameState.news.radio("%s is coming over to your market." % tr.display_name(), system_id, player.position)
	_market_pirate_t -= dt
	if _market_pirate_t <= 0.0:
		_market_pirate_t = MARKET_PIRATE_CHECK
		var value := market_value()
		if value > MARKET_PIRATE_VALUE and randf() < clampf(float(value) / 500000.0, 0.08, 0.5):
			var n := randi_range(2, 4)
			for i in n:
				var p: Ship = spawn_npc(_pirate_preset(), player.position + Vector2.from_angle(randf() * TAU) * randf_range(6000.0, 9000.0))
				p.set_order({"type": "attack", "target": player})
			GameState.log_msg("Your market's wares (%s) have attracted %d pirates!" % [GameData.fmt_credits(value), n], GameState.COL_BAD)


## A trader drone is back aboard its trader: the trader leaves.
func market_drone_back(md) -> void:
	for b in market_buyers:
		if b.get("drone") == md:
			b["done"] = true
			b["drone"] = null
			if is_instance_valid(b["ship"]) and not b["ship"].dying:
				_market_leave(b)


func _market_leave(b: Dictionary) -> void:
	var sh: Ship = b["ship"]
	sh.set_order({"type": "move", "pos": sh.position + Vector2.from_angle(randf() * TAU) * 30000.0})
	sh.activity = "Leaving"
	b["leave_t"] = 25.0


## Total value of everything on offer.
func market_value() -> int:
	var v := 0
	if player == null or not is_instance_valid(player):
		return v
	for k in player.fit.market_offers:
		v += int(player.fit.market_offers[k]["amount"]) * int(player.fit.market_offers[k]["price"])
	return v


## A trader at the market buys something it finds fairly priced. Returns the credits earned.
## Simulation – in co-op this runs on the host only: it writes to GameState / the fitting directly.
func market_trade(buyer) -> int:
	var f: ShipFitting = player.fit
	var keys: Array = f.market_offers.keys()
	keys.shuffle()
	for item in keys:
		var off: Dictionary = f.market_offers[item]
		var have := int(floor(float(f.cargo.get(item, 0.0))))
		var amount := mini(int(off["amount"]), have)
		if amount <= 0:
			f.market_offers.erase(item)
			continue
		var price := int(off["price"])
		var max_price := float(market_base_price(String(item))) * randf_range(0.9, 1.5)
		if price > max_price:
			continue
		var budget := randf_range(3000.0, 25000.0)
		var n := clampi(int(budget / float(price)), 1, amount)
		f.remove_cargo(String(item), float(n))
		off["amount"] = int(off["amount"]) - n
		if int(off["amount"]) <= 0:
			f.market_offers.erase(item)
		GameState.add_credits(n * price)
		GameState.log_msg("Market: %s bought %d × %s for %s." % [buyer.display_name(), n, GameData.item_name(String(item)), GameData.fmt_credits(n * price)], GameState.COL_GOOD)
		return n * price
	GameState.log_msg("Market: %s found your prices too high and left." % buyer.display_name(), GameState.COL_WARN)
	return 0


# ---------------------------------------------------------------- Package 23: drones

const DroneScript = preload("res://scripts/world/drone.gd")


## Drones of carrier `c` that are out (launch order).
var _drones_by := {}
var _drones_frame := -1


## Review P2 (0.4.25.47): one pass over the ships per physics frame instead of one per call; launching drones
## refreshes it (see launch_drones).
func drones_of(c) -> Array:
	if c == null or not is_instance_valid(c):
		return []
	var fr := Engine.get_physics_frames()
	if fr != _drones_frame:
		_drones_frame = fr
		_drones_by.clear()
		for n in ship_layer.get_children():
			if n is Ship and n.is_drone and not n.dying and n.carrier != null and is_instance_valid(n.carrier):
				var k: int = n.carrier.get_instance_id()
				if not _drones_by.has(k):
					_drones_by[k] = []
				_drones_by[k].append(n)
	var out: Array = []
	for d in _drones_by.get(c.get_instance_id(), []):
		if is_instance_valid(d) and not d.dying:
			out.append(d)
	return out


## Drones head home: carrier docking / docked, aligning for warp, in warp or spooling the jump drive.
func drones_must_return(c) -> bool:
	if c.is_docked() or c.in_warp():
		return true
	var ot := String(c.order.get("type", ""))
	return ot == "docking" or (ot in ["warp", "travel"] and c.spool >= 0.0)


## Launches up to `n` drones (default: as many as the ship can control). "" = done.
func launch_drones(c, n: int = -1) -> String:
	_drones_frame = -1                 # review P2: new drones join the gathered lists
	if c == null or not is_instance_valid(c) or c.dying:
		return "No ship."
	if c.is_docked():
		return "Undock first."
	if c.in_warp():
		return "Not in warp."
	var f: ShipFitting = c.fit
	var s := f.stats()
	if int(s["drone_storage"]) <= 0:
		return "No drone hangar fitted."
	var free := int(s["drones_max"]) - drones_of(c).size()
	if free <= 0:
		return "All %d drone slots of this ship are in use." % int(s["drones_max"])
	var cands: Array = []
	for r in f.drones:
		if not r.get("out", false) and float(r.get("fuel", 0.0)) > 0.0:
			cands.append(r)
	if cands.is_empty():
		return "No drones in the hangar – the drone service at stations sells them."
	cands.sort_custom(func(a, b): return float(a["fuel"]) > float(b["fuel"]))
	var count := mini(free, cands.size())
	if n > 0:
		count = mini(count, n)
	for i in count:
		var r2: Dictionary = cands[i]
		r2["out"] = true
		_npc_counter += 1
		var d = DroneScript.new()
		d.setup_drone(c, r2, self, -_npc_counter, f.drones.find(r2) + 1)
		ship_layer.add_child(d)
	if c == player:
		GameState.log_msg("%d drone%s launched – %s." % [count, "" if count == 1 else "s", ROLE_NAMES.get(f.drone_role, f.drone_role)], GameState.COL_INFO)
	return ""


const ROLE_NAMES := {"combat": "combat", "mining": "mining", "repair": "repair"}


## All drones come back into the hangar.
func recall_drones(c) -> String:
	var ds := drones_of(c)
	if ds.is_empty():
		return "No drones out."
	for d in ds:
		d.recalled = true
	if c == player:
		GameState.log_msg("Drones recalled (%d)." % ds.size(), GameState.COL_INFO)
	return ""


## A drone reached the hangar: ore unloaded, back in storage.
func stow_drone(d) -> void:
	if d.dying:
		return
	var c = d.carrier
	d.release_launch()
	d.unload()
	d.rec["out"] = false
	if not d.recalled and is_instance_valid(c) and drones_must_return(c) and not c.is_docked() and not String(c.order.get("type", "")) == "docking":
		c.fit.drone_relaunch += 1         # back out after the warp / jump
	d.dying = true
	d.queue_free()


## Warp, jump or docking: drones within their control range go into the hangar at once (with
## `relaunch` they fly out again afterwards); drones further out are left behind and lost.
func stow_all_drones(c, relaunch: bool) -> void:
	for d in drones_of(c):
		d.release_launch()
		if d.position.distance_to(c.position) <= float(d.dstats["range"]):
			d.unload()
			d.rec["out"] = false
			if relaunch and not d.recalled:
				c.fit.drone_relaunch += 1
			d.dying = true
			d.queue_free()
		else:
			d._lost("left behind out of control range")


## Friendly for drones (fire at will spares them, "allies only" repairs them): the pilot and the
## drones, the escorted group, and ships of factions you are Friendly or better with.
func is_ally(n) -> bool:
	if not (n is Ship):
		return false
	if n.is_drone and n.carrier != null and is_instance_valid(n.carrier) and n.carrier.faction != "player":
		return is_ally(n.carrier)            # an NPC carrier's drone (package 25e)
	if n.faction == "player" or n.is_drone or n.escort_mark:
		return true
	if player_group().has(n):
		return true
	return n.fit.gov != "" and not n.hostile_to_player() and GameState.rep.at_least(n.fit.gov, "friendly")


## The pilot's radar is jammed.
func player_jammed() -> bool:
	return player != null and is_instance_valid(player) and player.jammed_t > 0.0


## Can the pilot see ship `n` on radar, map and contact list? (Not while jammed, unless close.)
func contact_visible(n) -> bool:
	if n is Ship and n != player and n.cloaked():
		return false                     # an Axiom cloak (package 25g)
	if not player_jammed():
		return true
	return player.position.distance_to(n.position) <= JAM_VISIBLE


## Ships following `fn` (also in warp with it): the pilot first, then a fixed order. Cached per frame.
var _fol_cache := {}
var _fol_frame := -1


func followers_of(fn) -> Array:
	var fr := Engine.get_process_frames()
	if fr != _fol_frame:
		_fol_frame = fr
		_fol_cache.clear()
	if _fol_cache.has(fn):
		return _fol_cache[fn]
	var out: Array = []
	for n in ship_layer.get_children():
		if not (n is Ship) or n == fn or n.dying:
			continue
		if (String(n.order.get("type", "")) == "follow" and n.order.get("node") == fn) or (n.in_warp() and n.warp.get("follow") == fn):
			out.append(n)
	out.sort_custom(func(a, b):
		if (a == player) != (b == player):
			return a == player
		return a.get_instance_id() < b.get_instance_id())
	_fol_cache[fn] = out
	return out


## The lead of the pilot's group says in the chat when it starts aligning for a warp or spooling its
## jump drive.
func announce_lead(ship: Ship, kind: String, where: String) -> void:
	if ship == player or player == null or not is_instance_valid(player):
		return
	var led: bool = (String(player.order.get("type", "")) == "follow" and player.order.get("node") == ship) or (ship.escort_mark and ship.convoy_lead)
	if not led:
		return
	if kind == "jump":
		GameState.log_msg("%s: Spooling jump drive – jumping to %s. Stay with me." % [ship.display_name(), where], GameState.COL_INFO)
	else:
		GameState.log_msg("%s: Aligning for warp to %s – hold formation." % [ship.display_name(), where], GameState.COL_INFO)


## Allied ships travelling with the pilot: convoys and patrols under the pilot's protection (marked
## green), the ship the pilot follows and anyone following the pilot. Lead ships first.
func player_group() -> Array:
	var out: Array = []
	if player == null or not is_instance_valid(player):
		return out
	var fn = player.order.get("node") if String(player.order.get("type", "")) == "follow" else null
	if fn == null and player.in_warp():
		fn = player.warp.get("follow")
	for n in ship_layer.get_children():
		if not (n is Ship) or n == player or n.dying or n.is_drone:
			continue
		if n.escort_mark or n == fn or (String(n.order.get("type", "")) == "follow" and n.order.get("node") == player):
			out.append(n)
	out.sort_custom(func(a, b): return a.convoy_lead and not b.convoy_lead)
	return out


func order_warp(id: String) -> String:
	var d := describe(id)
	if d.is_empty():
		return "Unknown object."
	var t := Universe.warp_target(system_id, id)
	if t.is_empty():
		t = {"id": id, "kind": d["kind"], "name": d["name"], "pos": d["pos"], "land": 1500.0}
	if player.position.distance_to(player.warp_destination(t)) <= Universe.WARP_MIN:
		return "Too close to warp – approach instead."
	command_target(t, {})
	return ""


func order_lock(id: String) -> String:
	var n = find_object(id)
	if n == null:
		return "Nothing to lock."
	return player.add_lock(n)


## Go to an object (celestial id or warp target id) and perform its natural action.
func order_goto(id: String) -> String:
	var c = by_id.get(id)
	if c != null and is_instance_valid(c):
		command_celestial(c)
		return ""
	var t := Universe.warp_target(system_id, id)
	if t.is_empty():
		return "Unknown destination."
	command_target(t, {})
	return ""


## Warp (if far enough) to a target, then an optional follow-up order.
func command_target(t: Dictionary, then: Dictionary) -> void:
	if player == null or t.is_empty():
		return
	var dest := player.warp_destination(t)
	if player.position.distance_to(dest) > Universe.WARP_MIN:
		player.set_order({"type": "warp", "target": t, "then": then})
		GameState.log_msg("Aligning for warp → %s" % t["name"])
	elif not then.is_empty():
		player.set_order(resolve_order(then))
	else:
		player.set_order({"type": "move", "pos": dest})
	spawn_fx(Fx.marker(t["pos"], Color(0.6, 0.85, 1.0)))


func command_celestial(c: Celestial) -> void:
	var near := {"id": c.data.get("id", ""), "kind": c.kind, "name": c.title(), "pos": c.position, "land": c.radius + 400.0}
	match c.kind:
		"station", "haven":
			var why: String = GameState.rep.dock_error(c.data)
			if why != "":
				GameState.log_msg(why, GameState.COL_WARN)
				command_target(Universe.warp_target(system_id, c.data["id"]), {})
			else:
				command_target(Universe.warp_target(system_id, c.data["id"]), {"type": "dock", "id": c.data["id"]})
		"gate":
			var to := int(c.data["to"])
			var err := GameState.can_jump(player.fit, to)
			if err != "":
				GameState.warn("Jump to %s not possible: %s%s" % [Universe.systems[to]["name"], err, " – refuel at a station's Fuel Depot." if err.begins_with("Not enough fuel") else "."])
				command_target(Universe.warp_target(system_id, c.data["id"]), {})
			else:
				player.fit.route = [to]
				player.set_order({"type": "travel"})
		"asteroid":
			var then := {"type": "mine", "id": c.data["id"]} if (player.fit.has_tool("mining") or player.fit.has_tool("harvester")) else {}
			near["land"] = 500.0
			command_target(near, then)
		"anomaly":
			var then := {"type": "analyze", "id": c.data["id"]} if player.fit.has_tool("analyzer") and not c.data["done"] else {}
			command_target(Universe.warp_target(system_id, c.data["id"]), then)
		"wreck":
			var then := {"type": "salvage", "id": c.data["id"]} if player.fit.has_tool("salvage") else {}
			command_target(near, then)
		_:
			var wt := Universe.warp_target(system_id, String(c.data.get("id", "")))
			command_target(wt if not wt.is_empty() else near, {})


## Turns a stored follow-up order (with object ids) into an executable order.
func resolve_order(o: Dictionary) -> Dictionary:
	var t: String = o.get("type", "idle")
	if t in ["dock", "mine", "analyze", "salvage"]:
		var node = by_id.get(o.get("id", ""))
		if node == null or not is_instance_valid(node):
			return {"type": "idle"}
		return {"type": t, "node": node}
	if t in ["approach", "orbit", "keep"]:
		var n2 = find_object(String(o.get("id", "")))
		if n2 == null:
			return {"type": "idle"}
		return {"type": t, "node": n2, "r": float(o.get("r", 0.0))}
	return o


## Take over the route from the galaxy map.
func apply_route() -> void:
	if player != null and is_instance_valid(player) and not player.fit.route.is_empty():
		player.set_order({"type": "travel"})


func _update_hover() -> void:
	var text := ""
	hovered = null
	if input_enabled:
		var p := pick(_screen_to_world(get_viewport().get_mouse_position()))
		if not p.is_empty():
			if p["kind"] == "body":
				var t: Dictionary = p["target"]
				text = "%s\nDistance: %s\nClick: warp" % [t["name"], fmt_dist(_player_pos().distance_to(t["pos"]))]
			else:
				hovered = p["node"]
				text = hovered.info_text()
				if player != null and hovered != player:
					text += "\nDistance: %s" % fmt_dist(player.position.distance_to(hovered.position))
	if text != _last_hover:
		_last_hover = text
		hover_changed.emit(text)


func _player_pos() -> Vector2:
	return player.position if player != null and is_instance_valid(player) else camera.position


static func fmt_age(sec: float) -> String:
	if sec < 60.0:
		return "just now"
	if sec < 3600.0:
		return "%d min ago" % int(sec / 60.0)
	return "%d h ago" % int(sec / 3600.0)


static func fmt_dist(d: float) -> String:
	if d >= 1000000.0:
		return "%.2fM km" % (d / 1000000.0)
	if d >= 10000.0:
		return "%dk km" % int(d / 1000.0)
	return "%d km" % int(d)


## Scenery rocks: only those near the camera, slowly turning.
func _draw_debris() -> void:
	var a := sky_alpha()
	if a <= 0.01:
		return
	var half := get_viewport_rect().size * 0.5 / camera.zoom.x + Vector2(120, 120)
	var cp := camera.position
	var mod := Color(0.82, 0.82, 0.86, a)
	for d in layout.get("debris", []):
		var pos: Vector2 = d["pos"]
		if absf(pos.x - cp.x) > half.x or absf(pos.y - cp.y) > half.y:
			continue
		var r: float = d["radius"]
		var tex := PixelArt.asteroid_sprite(d["class"], d["shape"], int(d["seed"]), int(r / 2.2), d["ore"])
		var sz := Vector2(tex.get_width(), tex.get_height()) * (r * 2.0 / tex.get_width())
		debris_layer.draw_set_transform(pos, float(d["rot"]) + float(d["spin"]) * _t, Vector2.ONE)
		debris_layer.draw_texture_rect(tex, Rect2(-sz * 0.5, sz), false, mod)
	debris_layer.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ---------------------------------------------------------------- Colossi: line of sight & radar shadow

## True if a point is covered by a colossus (ships there are hidden underneath).
func under_colossus(p: Vector2) -> bool:
	for co in colossi:
		var rel: Vector2 = p - co.position
		if rel.length() < float(co.radius) and ColossusShape.contains(co.poly, rel):
			return true
	return false


## Outer (bounding) radius of a colossus – for quick distance rejects. The real outline is co.poly.
static func solid_radius(co) -> float:
	return float(co.radius)


## The colossus that blocks the straight line a -> b (radar, targeting, weapons), or null.
func blocker(a: Vector2, b: Vector2):
	var ab := b - a
	var len2 := ab.length_squared()
	for co in colossi:
		var r := float(co.radius)
		var cp: Vector2 = co.position
		var t := 0.0 if len2 < 1.0 else clampf((cp - a).dot(ab) / len2, 0.0, 1.0)
		if cp.distance_to(a + ab * t) > r:
			continue
		var la := a - cp
		var lb := b - cp
		# an object touching / inside the rock is not hidden by it
		if ColossusShape.contains(co.poly, la) or ColossusShape.contains(co.poly, lb):
			continue
		if ColossusShape.first_hit(co.poly, la, lb) >= 0.0:
			return co
	return null


## True if every part of colossus `co` lies in the radar shadow of other colossi, seen from `from`.
func colossus_hidden(from: Vector2, co) -> bool:
	var others: Array = []
	for o2 in colossi:
		if o2 != co and o2.position.distance_squared_to(from) < co.position.distance_squared_to(from) + float(co.radius) * float(o2.radius) * 4.0:
			others.append(o2)
	if others.is_empty():
		return false
	var poly: PackedVector2Array = co.poly
	var step := maxi(1, poly.size() / 16)
	var pts: Array = [co.position]
	for i in range(0, poly.size(), step):
		pts.append(co.position + poly[i] * 0.98)
	for p in pts:
		var seen := true
		for o2 in others:
			var la: Vector2 = from - o2.position
			var lb: Vector2 = p - o2.position
			if ColossusShape.first_hit(o2.poly, la, lb) >= 0.0 and not ColossusShape.contains(o2.poly, la):
				seen = false
				break
		if seen:
			return false
	return true


func line_of_sight(a: Vector2, b: Vector2) -> bool:
	return blocker(a, b) == null


## Point where the line a -> b first hits the colossus (for impacts).
static func hit_point(a: Vector2, b: Vector2, co) -> Vector2:
	var t := ColossusShape.first_hit(co.poly, a - co.position, b - co.position)
	return a if t < 0.0 else a.lerp(b, t)


## Asteroids are only visible (and get their texture) near the camera in the local zoom levels.
func _cull_asteroids() -> void:
	var local := sky_alpha() > 0.01
	var half := get_viewport_rect().size * 0.5 / camera.zoom.x * 1.4 + Vector2(400, 400)
	var cp := camera.position
	for a in asteroid_nodes:
		if not is_instance_valid(a):
			continue
		var d: Vector2 = a.position - cp
		a.visible = local and absf(d.x) < half.x and absf(d.y) < half.y
	for co in colossi:
		var d2: Vector2 = co.position - cp
		co.visible = local and absf(d2.x) < half.x + co.radius * 1.3 and absf(d2.y) < half.y + co.radius * 1.3


# ---------------------------------------------------------------- Drawing (overlay)

## Lock brackets (red = hostile, amber = object), lock progress arc, selection ring.
func _draw_locks(o: Node2D, px: float) -> void:
	if player == null or not is_instance_valid(player) or sky_alpha() < 0.5:
		return
	var sel = find_object(selected_id) if selected_id != "" else null
	if sel != null:
		var sr: float = sel.radius + 22.0 * px
		o.draw_arc(sel.position, sr, _t * 0.8, _t * 0.8 + TAU * 0.8, 36, Color(0.6, 0.9, 1.0, 0.7), 1.5 * px)
	for l in player.locks:
		var n = l["node"]
		if n == null or not is_instance_valid(n):
			continue
		var hostile: bool = n is Ship and n.hostile_to_player()
		var c := Color(1.0, 0.3, 0.3) if hostile else Color(1.0, 0.8, 0.3)
		var r: float = n.radius + 14.0 * px
		var k := 8.0 * px
		var w := (2.5 if l["key"] == player.active_lock else 1.5) * px
		for sx in [-1.0, 1.0]:
			for sy in [-1.0, 1.0]:
				var corner: Vector2 = n.position + Vector2(sx * r, sy * r)
				o.draw_line(corner, corner - Vector2(sx * k, 0.0), c, w)
				o.draw_line(corner, corner - Vector2(0.0, sy * k), c, w)
		var prog := float(l["progress"])
		if prog < 1.0:
			o.draw_arc(n.position, r + 6.0 * px, -PI / 2.0, -PI / 2.0 + TAU * prog, 32, c, 2.0 * px)
		# multi-focus (package 22): lock number and how many modules work on it
		var mods: int = player.modules_on(l["key"])
		o.draw_set_transform(n.position + Vector2(r + 4.0 * px, -r - 4.0 * px), 0.0, Vector2(px, px))
		o.draw_string(ThemeDB.fallback_font, Vector2.ZERO, "T%d%s" % [player.lock_number(l["key"]), (" ×%d" % mods) if mods > 0 else ""], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, c)
		o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_overlay() -> void:
	var o := overlay
	var z := camera.zoom.x
	var px := 1.0 / z
	_draw_locks(o, px)
	var font := ThemeDB.fallback_font
	var map_a := map_alpha()
	# No-fire zones around stations (dashed amber ring) and the haven gun range (red)
	var view_r := get_viewport_rect().size.length() * 0.5 / z
	for st in stations.values():
		if not is_instance_valid(st):
			continue
		var zr := float(st.data.get("zone", 15000.0))
		if zr <= 0.0:
			continue
		var dd: float = st.position.distance_to(camera.position)
		if map_a > 0.01 or absf(dd - zr) < view_r * 1.2:
			var za := 0.3 * map_a + 0.35 * sky_alpha()
			var segs := 180
			for k in segs:
				if k % 2 == 0:
					o.draw_arc(st.position, zr, k * TAU / segs, (k + 1) * TAU / segs, 6, Color(1.0, 0.7, 0.3, za), 1.5 * px)
	_draw_raid(o, px)
	for hv in havens:
		if is_instance_valid(hv) and (map_a > 0.01 or hv.position.distance_to(camera.position) < HAVEN_RANGE + view_r):
			o.draw_arc(hv.position, HAVEN_RANGE, 0.0, TAU, 160, Color(1.0, 0.25, 0.25, 0.3 * map_a + 0.3 * sky_alpha()), 1.5 * px)
	if map_a > 0.01:
		# Orbits and system boundary
		for p in layout["planets"]:
			o.draw_arc(Vector2.ZERO, float(p["orbit"]), 0.0, TAU, 180, Color(0.4, 0.6, 0.9, 0.2 * map_a), 1.5 * px)
		o.draw_arc(Vector2.ZERO, Universe.SYSTEM_RADIUS, 0.0, TAU, 220, Color(0.3, 0.5, 0.8, 0.3 * map_a), 2.0 * px)
		for t in Universe.warp_targets(system_id):
			var pos: Vector2 = t["pos"]
			var col := Color(0.85, 0.9, 1.0, map_a)
			match String(t["kind"]):
				"station":
					col = Color(PixelArt.STATION_ACCENT.get(t["data"]["type"], Color.WHITE), map_a)
					o.draw_rect(Rect2(pos - Vector2.ONE * 5.0 * px, Vector2.ONE * 10.0 * px), col)
					o.draw_rect(Rect2(pos - Vector2.ONE * 5.0 * px, Vector2.ONE * 10.0 * px), Color(1, 1, 1, map_a), false, 1.5 * px)
				"haven":
					col = Color(1.0, 0.2, 0.25, map_a)
					o.draw_set_transform(pos, PI * 0.25, Vector2(px, px))
					o.draw_rect(Rect2(Vector2(-5, -5), Vector2(10, 10)), Color(0.25, 0.02, 0.04, map_a))
					o.draw_rect(Rect2(Vector2(-5, -5), Vector2(10, 10)), col, false, 1.5)
					o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				"gate":
					col = Color(PixelArt.gate_color(int(t["data"]["class"])), map_a)
					o.draw_arc(pos, 8.0 * px, 0.0, TAU, 20, col, 3.0 * px)
					o.draw_arc(pos, 4.0 * px, _t, _t + 2.0, 10, col, 2.0 * px)
				"field":
					col = Color(FIELD_COLORS.get(String(t["data"].get("class", "")), Color(0.95, 0.78, 0.45)), map_a)
					for i in 8:
						var off := Vector2.from_angle(i * 0.8 + 0.3) * (5.0 + (i % 3) * 4.0) * px
						o.draw_rect(Rect2(pos + off - Vector2.ONE * 1.5 * px, Vector2.ONE * 3.0 * px), col)
				"anomaly":
					col = Color(0.85, 0.5, 1.0, map_a)
					var r := 8.0 * px
					o.draw_polyline(PackedVector2Array([pos + Vector2(0, -r), pos + Vector2(r, 0), pos + Vector2(0, r), pos + Vector2(-r, 0), pos + Vector2(0, -r)]), col, 2.0 * px)
			if t["kind"] in ["star", "planet"]:
				col = Color(0.75, 0.85, 1.0, 0.85 * map_a)
			var label: String = t["name"]
			o.draw_set_transform(pos + Vector2(14.0, 4.0) * px, 0.0, Vector2(px, px))
			o.draw_string(font, Vector2(1, 1), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0, 0, 0, 0.8 * map_a))
			o.draw_string(font, Vector2.ZERO, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, col)
			o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Markers for recon and system map (fixed screen size)
	var mark_a := clampf((0.2 - z) / 0.1, 0.0, 1.0)
	if mark_a > 0.01 and player != null and is_instance_valid(player):
		for n in ship_layer.get_children():
			if n is Ship and n != player and n.faction == "pirate" and not n.dying and n.position.distance_to(player.position) < 250000.0 and line_of_sight(player.position, n.position) and contact_visible(n):
				var pc := Color(1.0, 0.3, 0.3, mark_a)
				o.draw_set_transform(n.position, 0.0, Vector2(px, px))
				o.draw_colored_polygon(PackedVector2Array([Vector2(0, -6), Vector2(6, 5), Vector2(-6, 5)]), pc)
				o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# the convoy you are escorting (package 17): green – a ring up close, a marker on radar and map
	var lead_done := false
	for n in ship_layer.get_children():
		if not (n is Ship) or not n.escort_mark or n.dying or not n.visible:
			continue
		var gc := Color(0.35, 1.0, 0.45)
		if mark_a > 0.01:
			o.draw_set_transform(n.position, 0.0, Vector2(px, px))
			o.draw_colored_polygon(PackedVector2Array([Vector2(0, -7), Vector2(7, 0), Vector2(0, 7), Vector2(-7, 0)]), Color(gc, mark_a))
			o.draw_polyline(PackedVector2Array([Vector2(0, -7), Vector2(7, 0), Vector2(0, 7), Vector2(-7, 0), Vector2(0, -7)]), Color(0, 0, 0, 0.7 * mark_a), 1.0)
			if not lead_done and n.convoy_lead:
				lead_done = true
				o.draw_arc(Vector2.ZERO, 11.0, 0.0, TAU, 20, Color(gc, mark_a), 1.5)
				o.draw_string(font, Vector2(14, 4), "YOUR %s (lead)" % n.escort_kind.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(gc, mark_a))
			o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if 1.0 - mark_a > 0.01:
			var ca := 0.75 * (1.0 - mark_a)
			o.draw_arc(n.position, n.radius + 16.0 * px, 0.0, TAU, 28, Color(gc, ca), 2.0 * px)
			if n.convoy_lead:
				o.draw_arc(n.position, n.radius + 26.0 * px, 0.0, TAU, 32, Color(gc, ca), 2.0 * px)
				o.draw_set_transform(n.position + Vector2(0.0, -(n.radius + 32.0 * px)), 0.0, Vector2(px, px))
				o.draw_string(font, Vector2(-40, -4), "%s LEAD" % n.escort_kind.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(gc, ca + 0.2))
				o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Radar in recon view
	var radar_a := mark_a * sky_alpha()
	if radar_a > 0.01 and player != null and is_instance_valid(player) and not player.is_docked():
		_draw_radar(o, player.position, px, radar_a)
	# Own ship as an icon (recon + system)
	if player != null and is_instance_valid(player) and not player.is_docked():
		var pp := player.position
		if mark_a > 0.01:
			_draw_player_icon(o, pp, player.heading, px, mark_a)
		if player.in_warp():
			_dashed(o, pp, player.warp["to"], Color(0.6, 0.9, 1.0, 0.7), px)
		var ot: String = player.order.get("type", "")
		if ot == "move":
			_dashed(o, pp, player.order["pos"], Color(0.3, 1.0, 0.5, 0.4), px)
		elif ot == "warp":
			var dest := player.warp_destination(player.order["target"])
			_dashed(o, pp, dest, Color(0.6, 0.9, 1.0, 0.45), px)
		if map_a < 0.99:
			var st := player.fit.stats()
			o.draw_arc(pp, st["sensor_range"], 0.0, TAU, 64, Color(0.3, 0.6, 1.0, 0.12 * (1.0 - map_a)), px)
			if not st["weapons"].is_empty():
				o.draw_arc(pp, float(st["optimal_range"]) / 0.8, 0.0, TAU, 64, Color(1.0, 0.4, 0.3, 0.15 * (1.0 - map_a)), px)
	# Warp light streaks around the player ship
	if player != null and is_instance_valid(player) and player.in_warp():
		var p := player.warp_progress()
		var strength := clampf(minf(p, 1.0 - p) * 5.0, 0.0, 1.0)
		var dir := Vector2.from_angle(player.heading)
		var vs := get_viewport_rect().size
		for i in 40:
			var h := fmod(float(i) * 0.6180339 + 0.13, 1.0)
			var h2 := fmod(float(i) * 0.7548776 + 0.37, 1.0)
			var lateral := (h - 0.5) * vs.length()
			var along := fposmod(h2 * 2000.0 - _t * 2600.0, 2000.0) - 1000.0
			var sp := player.position + (dir.orthogonal() * lateral + dir * along) * px
			o.draw_line(sp, sp - dir * 120.0 * px * strength, Color(0.7, 0.9, 1.0, 0.35 * strength), 1.5 * px)


const RADAR_COL := Color(0.3, 1.0, 0.55)
const RADAR_PERIOD := 3.0


## Navigation arrow for the player ship (fixed screen size).
func _draw_player_icon(o: Node2D, pos: Vector2, heading: float, px: float, a: float) -> void:
	var glow := 0.5 + 0.5 * sin(_t * 4.0)
	# draw locally (huge world coordinates would break polygon triangulation)
	o.draw_set_transform(pos, heading, Vector2(px, px))
	o.draw_circle(Vector2.ZERO, 15.0, Color(0.3, 1.0, 0.6, 0.12 * a))
	# arrow made of two convex triangles
	var col := Color(0.35, 1.0, 0.65, a)
	o.draw_colored_polygon(PackedVector2Array([Vector2(11, 0), Vector2(-7, 7), Vector2(-3, 0)]), col)
	o.draw_colored_polygon(PackedVector2Array([Vector2(11, 0), Vector2(-3, 0), Vector2(-7, -7)]), col)
	o.draw_polyline(PackedVector2Array([Vector2(11, 0), Vector2(-7, 7), Vector2(-3, 0), Vector2(-7, -7), Vector2(11, 0)]), Color(0.02, 0.15, 0.08, a), 1.5)
	o.draw_arc(Vector2.ZERO, 17.0 + 2.0 * glow, 0.0, TAU, 32, Color(0.3, 1.0, 0.6, (0.4 + 0.3 * glow) * a), 1.5)
	o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Radar display: range rings, sensor range, rotating sweep with afterglow;
## contacts light up when the sweep passes over them.
func _draw_radar(o: Node2D, c: Vector2, px: float, a: float) -> void:
	var vs := get_viewport_rect().size
	var r := minf(vs.x, vs.y) * RADAR_SCREEN * px
	var sweep := fmod(_t / RADAR_PERIOD, 1.0) * TAU
	var font := ThemeDB.fallback_font
	# Base disc and rings
	o.draw_circle(c, r, Color(0.05, 0.25, 0.12, 0.10 * a))
	for i in range(1, 5):
		var rr := r * i / 4.0
		o.draw_arc(c, rr, 0.0, TAU, 96, Color(RADAR_COL, (0.35 if i == 4 else 0.18) * a), (2.0 if i == 4 else 1.0) * px)
		o.draw_set_transform(c + Vector2(4.0 * px, -rr - 3.0 * px), 0.0, Vector2(px, px))
		o.draw_string(font, Vector2.ZERO, fmt_dist(rr), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(RADAR_COL, 0.45 * a))
		o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for k in 12:
		var ang := TAU * k / 12.0
		var inner := r * (0.94 if k % 3 != 0 else 0.88)
		o.draw_line(c + Vector2.from_angle(ang) * inner, c + Vector2.from_angle(ang) * r, Color(RADAR_COL, 0.35 * a), px)
	o.draw_line(c - Vector2(r, 0), c + Vector2(r, 0), Color(RADAR_COL, 0.08 * a), px)
	o.draw_line(c - Vector2(0, r), c + Vector2(0, r), Color(RADAR_COL, 0.08 * a), px)
	# Ship sensor range
	var sr: float = player.fit.stats()["sensor_range"]
	o.draw_arc(c, sr, 0.0, TAU, 64, Color(0.4, 0.75, 1.0, 0.45 * a), 1.5 * px)
	# Sweep with afterglow
	var rl := r / px
	o.draw_set_transform(c, 0.0, Vector2(px, px))
	for i in 24:
		var a0 := sweep - i * 0.04
		var a1 := sweep - (i + 1) * 0.04
		var wedge := PackedVector2Array([Vector2.ZERO, Vector2.from_angle(a0) * rl, Vector2.from_angle(a1) * rl])
		o.draw_colored_polygon(wedge, Color(RADAR_COL, 0.22 * a * pow(1.0 - i / 24.0, 1.6)))
	o.draw_line(Vector2.ZERO, Vector2.from_angle(sweep) * rl, Color(0.7, 1.0, 0.8, 0.9 * a), 2.0)
	o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Radar shadows of colossal asteroids (drawn over the sweep: nothing returns from there)
	# far ones first, so the shadow of a nearer rock covers what lies behind it;
	# a rock completely inside another one's shadow does not show at all
	var near_cols: Array = []
	for co in colossi:
		if co.position.distance_to(c) - float(co.radius) <= r:
			near_cols.append(co)
	near_cols.sort_custom(func(x, y): return x.position.distance_squared_to(c) > y.position.distance_squared_to(c))
	for co in colossi:
		co.radar_hidden = false
	for co in near_cols:
		co.radar_hidden = colossus_hidden(c, co)
		if co.radar_hidden:
			_draw_hidden_echo(o, c, co, px, a)   # inside another shadow: no shadow of its own
		else:
			_draw_radar_shadow(o, c, co, r, px, a)
	# Contacts (only with line of sight)
	for n in ship_layer.get_children():
		if n is Ship and n != player and not n.dying and not n.is_docked() and line_of_sight(c, n.position) and contact_visible(n):
			if n.is_drone:
				_blip(o, c, n.position, r, sweep, px, a, Color(0.4, 1.0, 0.5), 2.0)
				continue
			_blip(o, c, n.position, r, sweep, px, a, Color(1.0, 0.3, 0.3) if n.faction == "pirate" else Color(0.9, 0.9, 0.5), 4.0)
	if player_jammed():
		# jammed (package 20): static over the radar, no contacts beyond close range
		var rnd := RandomNumberGenerator.new()
		rnd.seed = int(_t * 12.0)
		for k2 in 160:
			var pp := c + Vector2.from_angle(rnd.randf() * TAU) * sqrt(rnd.randf()) * r
			o.draw_rect(Rect2(pp, Vector2(3.0, 1.5) * px * rnd.randf_range(1.0, 3.0)), Color(0.6, 1.0, 0.7, 0.35 * a))
		o.draw_set_transform(c + Vector2(-60.0, -r * 0.55) * Vector2(px, 1.0), 0.0, Vector2(px, px))
		o.draw_string(font, Vector2.ZERO, "RADAR JAMMED", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1.0, 0.4, 0.4, 0.9 * a))
		o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for cel in celestials:
		if not is_instance_valid(cel) or not cel.is_pickable() or cel.kind == "colossus":
			continue
		if not line_of_sight(c, cel.position):
			continue
		var bc := Color(0.85, 0.9, 1.0)
		var size := 3.5
		match cel.kind:
			"asteroid":
				bc = Color(0.95, 0.7, 0.35)
				size = 2.0
			"wreck":
				bc = Color(0.5, 1.0, 0.5)
			"anomaly":
				bc = Color(0.85, 0.5, 1.0)
		_blip(o, c, cel.position, r, sweep, px, a, bc, size)


## Radar shadow: the colossus shows as a solid echo, behind it a dark cone where the radar
## sees nothing – with a static-noise hatch, edge lines and a label.
func _draw_radar_shadow(o: Node2D, c: Vector2, co, r: float, px: float, a: float) -> void:
	var rel: Vector2 = co.position - c
	var d := rel.length()
	var R := float(co.radius)
	if d - R > r:
		return
	var poly: PackedVector2Array = co.poly
	if ColossusShape.contains(poly, -rel):
		return
	# angular extent of the outline as seen from the ship
	var base := rel.angle()
	var amin := INF
	var amax := -INF
	var vmin := rel
	var vmax := rel
	for v in poly:
		var w: Vector2 = rel + v
		var da := wrapf(w.angle() - base, -PI, PI)
		if da < amin:
			amin = da
			vmin = w
		if da > amax:
			amax = da
			vmax = w
	var far := maxf(r * 1.02, d + R)
	# draw in local coordinates (huge world coordinates break polygon triangulation)
	o.draw_set_transform(c, 0.0, Vector2.ONE)
	var steps := 28
	var starts: Array = []
	for i in steps + 1:
		var ang := base + amin + (amax - amin) * i / steps
		var dir := Vector2.from_angle(ang)
		var t := ColossusShape.first_hit(poly, -rel, -rel + dir * far)
		starts.append(dir * (t * far if t >= 0.0 else d))
	starts[0] = vmin
	starts[steps] = vmax
	for i in steps:
		var a0 := base + amin + (amax - amin) * i / steps
		var a1 := base + amin + (amax - amin) * (i + 1) / steps
		var q := PackedVector2Array([starts[i], Vector2.from_angle(a0) * far, Vector2.from_angle(a1) * far, starts[i + 1]])
		o.draw_colored_polygon(q, Color(0.0, 0.03, 0.01, 0.62 * a))
	# "no return" range arcs across the shadow
	var arc_step := 22.0 * px
	var dd := ceilf(d / arc_step) * arc_step
	while dd < far:
		var fade := 1.0 - clampf((dd - d) / maxf(far - d, 1.0), 0.0, 1.0) * 0.6
		o.draw_arc(Vector2.ZERO, dd, base + amin * 0.97, base + amax * 0.97, 24, Color(1.0, 0.36, 0.3, 0.16 * a * fade), px)
		dd += arc_step
	# static-noise hatch inside the shadow
	var rnd := RandomNumberGenerator.new()
	rnd.seed = int(_t * 12.0) + int(co.position.x)
	for i in 70:
		var ang2 := base + rnd.randf_range(amin, amax) * 0.95
		var dist := rnd.randf_range(d + R * 0.2, far)
		var p := Vector2.from_angle(ang2) * dist
		o.draw_line(p, p + Vector2.from_angle(ang2 + PI * 0.5) * 6.0 * px, Color(RADAR_COL, 0.10 * a), px)
	# edges of the shadow (from the outermost points of the outline)
	for v in [vmin, vmax]:
		var vv: Vector2 = v
		o.draw_line(vv, vv.normalized() * far, Color(RADAR_COL, 0.45 * a), 1.5 * px)
	# the rock itself: a solid radar echo in its real shape
	var echo := PackedVector2Array()
	for v in poly:
		echo.append(rel + v)
	o.draw_colored_polygon(echo, Color(0.05, 0.25, 0.12, 0.6 * a))
	echo.append(echo[0])
	o.draw_polyline(echo, Color(RADAR_COL, 0.8 * a), 2.0 * px)
	# label in the middle of the shadow
	var lp := Vector2.from_angle(base + (amin + amax) * 0.5) * clampf(d + R * 1.6, d + R, far * 0.9)
	var font := ThemeDB.fallback_font
	o.draw_set_transform(c + lp, 0.0, Vector2(px, px))
	o.draw_string(font, Vector2(-44, 4), "RADAR SHADOW", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.5, 0.42, 0.8 * a))
	o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A colossus completely inside another one's radar shadow: only a faint dashed outline
## (known from the map data), no echo and no shadow cone of its own.
func _draw_hidden_echo(o: Node2D, c: Vector2, co, px: float, a: float) -> void:
	var rel: Vector2 = co.position - c
	o.draw_set_transform(c, 0.0, Vector2.ONE)
	var poly: PackedVector2Array = co.poly
	var n := poly.size()
	for i in n:
		if i % 2 == 0:
			o.draw_line(rel + poly[i], rel + poly[(i + 1) % n], Color(RADAR_COL, 0.45 * a), 1.5 * px)
	o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _blip(o: Node2D, c: Vector2, p: Vector2, r: float, sweep: float, px: float, a: float, col: Color, size: float) -> void:
	var d := p - c
	if d.length() > r:
		return
	var since := fposmod(sweep - d.angle(), TAU) / TAU      # 0 = just swept
	var glow := pow(1.0 - since, 2.0)
	var alpha := (0.25 + 0.75 * glow) * a
	o.draw_circle(p, size * (1.0 + glow * 0.8) * px, Color(col, alpha))
	if glow > 0.6:
		o.draw_arc(p, size * (2.0 + (1.0 - glow) * 6.0) * px, 0.0, TAU, 16, Color(col, alpha * 0.6), px)


func _dashed(o: Node2D, a: Vector2, b: Vector2, col: Color, px: float) -> void:
	var length := a.distance_to(b)
	if length < 1.0:
		return
	var dir := (b - a) / length
	var step := 14.0 * px
	var d := fmod(_t * 30.0 * px, step)
	var n := 0
	while d < length and n < 400:
		o.draw_line(a + dir * d, a + dir * minf(d + step * 0.5, length), col, 2.0 * px)
		d += step
		n += 1


# ---------------------------------------------------------------- Events from ships

func on_warp_started(ship: Ship) -> void:
	if ship == player:
		stow_all_drones(ship, true)
		GameState.codex.event("warp")
		_warp_saved_zoom = level_zoom(level)
		_warp_auto = true
		follow = true
		GameState.log_msg("Warp drive active → %s" % ship.warp["name"])


func on_warp_finished(ship: Ship) -> void:
	if ship == player and _warp_auto:
		_warp_auto = false
		_set_zoom(_warp_saved_zoom)
	# package 23: the drones that went into the hangar for the warp fly out again
	if ship == player and ship.fit.drone_relaunch > 0:
		var n := ship.fit.drone_relaunch
		ship.fit.drone_relaunch = 0
		launch_drones(ship, n)


func spawn_fx(f: Node2D) -> void:
	fx_layer.add_child(f)


func fire_weapon(shooter: Ship, target: Ship, w: Dictionary) -> void:
	_check_zone_fire(shooter, target)
	var dtype: String = w["damage_type"]
	var col: Color = GameData.DAMAGE_COLORS[dtype]
	if w.has("cap_drain"):
		col = ION_COLOR
		if shooter == player or target == player:
			GameState.codex.event("ion")
	if w.get("focus", false):
		col = Color(1.0, 0.18, 0.12)                     # the Covenant's red focus crystals (package 25f)
	if float(w.get("projectile_speed", 0)) <= 0.0:
		var co = blocker(shooter.position, target.position)
		if int(w.get("bundle", 0)) > 1 and co == null:
			# the focus lance (0.4.25.32): beams meet between ship and target, charge, burn for a second
			var fl = FocusLanceScript.new()
			fl.setup(shooter, target, w, self)
			fx_layer.add_child(fl)
			return
		if co != null:
			# the beam hits the colossus instead (cover)
			var hp := hit_point(shooter.position, target.position, co)
			spawn_fx(Fx.beam(shooter.position, hp, col, 2.0 + float(w["size"]) * 2.0))
			spawn_fx(Fx.explosion(hp, 10.0, Color(0.85, 0.8, 0.7)))
			return
		spawn_fx(Fx.beam(shooter.position, target.position, col, 2.0 + float(w["size"]) * 2.0))
		var dmg := float(w["damage"])
		if w.has("cap_drain"):
			# ion weapons (package 14): extra damage on shields, drain the capacitor, feed the shooter
			if target.fit.shield > 0.0:
				dmg *= float(w.get("shield_mult", 1.0))
			var drained := minf(target.fit.capacitor, float(w["cap_drain"]))
			target.fit.capacitor -= drained
			shooter.fit.capacitor = minf(float(shooter.fit.stats()["cap_max"]), shooter.fit.capacitor + drained * 0.5)
		target.take_damage(dmg, dtype, shooter)
	else:
		var p := Projectile.new()
		p.setup(shooter, target, w, self)
		fx_layer.add_child(p)


## The Cathedral's anti-drone pulse (package 25f): every drone within `radius` – friend or foe – drifts
## helplessly for `stun` seconds (it still burns fuel).
func drone_pulse(src: Ship, radius: float, stun: float) -> int:
	spawn_fx(Fx.pulse(src.position, radius, Color(1.0, 0.22, 0.15)))
	var n := 0
	for d in ship_layer.get_children():
		if d is Ship and d.is_drone and not d.dying and d.position.distance_to(src.position) <= radius:
			d.stunned_t = maxf(float(d.stunned_t), stun)
			n += 1
	if src == player or (player != null and is_instance_valid(player) and player.position.distance_to(src.position) < radius * 1.5):
		GameState.log_msg("%s: anti-drone pulse – %d drone%s knocked out for %d s." % [src.display_name(), n, "" if n == 1 else "s", int(stun)], GameState.COL_WARN)
	return n


# ---------------------------------------------------------------- No-fire zones & station defence

## Station whose no-fire zone contains p (or null).
func zone_station(p: Vector2):
	for st in stations.values():
		if is_instance_valid(st) and st.position.distance_to(p) < float(st.data.get("zone", 15000.0)):
			return st
	return null


func is_aggressor(ship) -> bool:
	if ship == null or not is_instance_valid(ship):
		return false
	var e: Dictionary = _aggro.get(ship.get_instance_id(), {})
	return not e.is_empty() and float(e["until"]) > _t


func aggro_left(ship) -> float:
	var e: Dictionary = _aggro.get(ship.get_instance_id(), {}) if ship != null and is_instance_valid(ship) else {}
	return maxf(0.0, float(e.get("until", 0.0)) - _t)


## A destination inside a no-fire zone moved out to its edge (pirates keep away from stations).
func clear_of_zones(p: Vector2) -> Vector2:
	for st in stations.values():
		if not is_instance_valid(st):
			continue
		var r := float(st.data.get("zone", 15000.0)) * 1.05
		var d: Vector2 = p - st.position
		if d.length() < r:
			p = st.position + (d.normalized() if d.length() > 1.0 else Vector2.RIGHT) * r
	return p


## Opening fire inside a no-fire zone (shooter or target inside) makes the shooter an aggressor –
## unless the target is an aggressor itself (self-defence is allowed).
func _check_zone_fire(shooter: Ship, target: Ship) -> void:
	if shooter.faction == "patrol" and (target.faction == "pirate" or (target == player and target.faction == "player" and shooter.hostile_to_player())):
		return                   # law enforcement
	var st = zone_station(shooter.position)
	if st == null:
		st = zone_station(target.position)
	if st == null or is_aggressor(target):
		return
	var fresh := not is_aggressor(shooter)
	_aggro[shooter.get_instance_id()] = {"ship": shooter, "station": st, "until": _t + AGGRO_TIME}
	if not fresh:
		return
	if shooter == player:
		var sf := String(st.data.get("faction", ""))
		GameState.law.offence(sf if sf != "" else GameState.law.authority(system_id), "zone_fire", "weapons fire in the no-fire zone of %s" % st.title())
	if shooter == player:
		GameState.log_msg("%s: weapons fire inside the no-fire zone – the station's defence batteries are engaging you!" % st.title(), GameState.COL_BAD)
	elif player != null and is_instance_valid(player) and player.position.distance_to(shooter.position) < 60000.0:
		GameState.log_msg("%s opened fire inside the no-fire zone of %s – station defence engaging." % [shooter.display_name(), st.title()], GameState.COL_WARN)


## Warning before the player's weapons go active inside a zone.
func warn_zone(target) -> void:
	if player == null or _t - _zone_warned < 15.0:
		return
	var st = zone_station(player.position)
	if st == null and target != null and is_instance_valid(target):
		st = zone_station(target.position)
	if st == null or (target != null and is_aggressor(target)):
		return
	_zone_warned = _t
	GameState.log_msg("No-fire zone of %s: opening fire here makes its defence batteries engage you." % st.title(), GameState.COL_WARN)


const AGGRO_TIME := 30.0
const ION_COLOR := Color(0.75, 0.45, 1.0)
const ArchData = preload("res://data/pirate_archetypes.gd")
const DEF_COOLDOWN := 1.6
const HAVEN_RANGE := 7000.0


func _update_defence(delta: float) -> void:
	# stations fire on aggressors inside their zone
	for key in _aggro.keys():
		var e: Dictionary = _aggro[key]
		var ship = e["ship"]
		if not is_instance_valid(ship) or ship.dying or float(e["until"]) <= _t:
			_aggro.erase(key)
			continue
		var st = e["station"]
		if not is_instance_valid(st) or ship.is_docked() or not ship.is_targetable():
			continue
		if st.position.distance_to(ship.position) > float(st.data.get("zone", 15000.0)) * 1.1:
			continue
		var dmg := 35.0 + 25.0 * float(st.data.get("tier", 1))
		if String(st.data.get("type", "")) == "military":
			dmg *= 1.5
		_turrets_fire(st, ship, dmg, Color(0.55, 0.9, 1.0), delta)
	# Pirate Havens shoot at the player (and friendly ships) that come close
	for hv in havens:
		if not is_instance_valid(hv):
			continue
		var tgt = null
		var bd := HAVEN_RANGE
		var hf := String(hv.data.get("faction", ""))
		for n in ship_layer.get_children():
			if n is Ship and n.faction != "pirate" and n.is_targetable() and n.position.distance_to(hv.position) < bd:
				if n == player and not GameState.rep.pirates_hostile(hf):
					continue          # friends of the haven's faction are left alone (package 12)
				bd = n.position.distance_to(hv.position)
				tgt = n
		if tgt == null:
			continue
		if tgt == player and _t - _haven_warned > 20.0:
			_haven_warned = _t
			GameState.log_msg("%s: the pirate guns are firing at you – keep %s away!" % [hv.title(), fmt_dist(HAVEN_RANGE)], GameState.COL_BAD)
		_turrets_fire(hv, tgt, 18.0 + 10.0 * float(hv.data.get("tier", 2)), Color(1.0, 0.35, 0.3), delta, 2.6)


func _turrets_fire(st: Celestial, ship: Ship, dmg: float, col: Color, delta: float, cooldown: float = DEF_COOLDOWN) -> void:
	var key := st.get_instance_id()
	var tl: Array = st.art.get("turrets", [])
	if not _def_cd.has(key):
		var cds: Array = []
		for i in tl.size():
			cds.append(randf() * cooldown)
		_def_cd[key] = cds
	var cd: Array = _def_cd[key]
	for i in tl.size():
		if not turret_ok(st, i):
			continue                 # shot down or knocked out by an ion torpedo (raid)
		var tp: Vector2 = st.position + (tl[i] as Vector2)
		st.turret_aim[i] = lerp_angle(float(st.turret_aim[i]), (ship.position - tp).angle(), clampf(delta * 8.0, 0.0, 1.0))
		cd[i] = float(cd[i]) - delta
		if float(cd[i]) > 0.0:
			continue
		cd[i] = cooldown * randf_range(0.85, 1.15)
		if not is_instance_valid(ship) or ship.dying:
			return
		var co = blocker(tp, ship.position)
		if co != null:
			var hp := hit_point(tp, ship.position, co)
			spawn_fx(Fx.beam(tp, hp, col, 6.0))
			continue
		st.turret_flash[i] = 0.25
		var bf := Fx.beam(tp, ship.position, col, 10.0)
		bf.life = 0.35
		bf.max_life = 0.35
		spawn_fx(bf)
		spawn_fx(Fx.explosion(ship.position, ship.radius * 0.8, col))
		ship.take_damage(dmg, "kinetic", null)


# ---------------------------------------------------------------- Long-range survey (package 7)

## Area a survey of a place covers (km around its position).
func survey_radius(id: String, kind: String) -> float:
	var t := Universe.warp_target(system_id, id)
	match kind:
		"field":
			return float(t.get("data", {}).get("radius", 15000.0)) * 1.3
		"planet":
			return float(t.get("data", {}).get("radius", 10000.0)) * 4.0
		"star":
			return 200000.0
	return 30000.0


## Survey finished: list asteroids by ore, ships, wrecks and colossi around the place.
func complete_survey(job: Dictionary) -> void:
	var c: Vector2 = job["pos"]
	var r: float = job["radius"]
	var ores := {}        # ore -> [asteroid count, units]
	var n_ast := 0
	for a in asteroid_nodes:
		if not is_instance_valid(a) or a.is_depleted() or a.position.distance_to(c) > r:
			continue
		n_ast += 1
		var mix: Dictionary = a.data.get("mix", {a.data["ore"]: 1.0})
		for o in mix:
			var row: Array = ores.get(o, [0, 0.0])
			row[0] = int(row[0]) + (1 if o == a.data["ore"] else 0)
			row[1] = float(row[1]) + float(a.data["amount"]) * float(mix[o])
			ores[o] = row
	var ships := {}       # "Pirate Carrion Crow (Pirate Raider)" -> count
	var n_hostile := 0
	for n in ship_layer.get_children():
		if n is Ship and n != player and not n.dying and n.is_targetable() and n.position.distance_to(c) <= r:
			var key := "%s – %s" % [n.fit.hull()["class"], FactionData.short_of(n.fit.gov) if n.fit.gov != "" else n.faction.capitalize()]
			ships[key] = int(ships.get(key, 0)) + 1
			if n.faction == "pirate":
				n_hostile += 1
	var wrecks := 0
	var cols := 0
	for cel in celestials:
		if is_instance_valid(cel) and cel.position.distance_to(c) <= r:
			if cel.kind == "wreck":
				wrecks += 1
			elif cel.kind == "colossus":
				cols += 1
	var ore_rows: Array = []
	for o in ores:
		ore_rows.append([o, int(ores[o][0]), float(ores[o][1])])
	ore_rows.sort_custom(func(x, y): return float(x[2]) > float(y[2]))
	var summary := "%d asteroids, %d ships (%d pirates), %d wrecks" % [n_ast, ships.values().reduce(func(a, b): return a + b, 0), n_hostile, wrecks]
	var res := {"name": job["name"], "id": job["id"], "system": system_id, "t": GameState.play_time, "radius": r,
		"ores": ore_rows, "ships": ships, "wrecks": wrecks, "colossi": cols, "asteroids": n_ast, "summary": summary}
	GameState.surveys["%d:%s" % [system_id, job["id"]]] = res
	GameState.survey_done.emit(res)


# ---------------------------------------------------------------- Warp interdiction (package 11)

const InterdictGameScript = preload("res://scripts/ui/interdict_game.gd")
var _interdict := {}               # {ship, target, slot, data, game}


func interdict_running() -> bool:
	return not _interdict.is_empty()


## The player's interdictor caught `target` in warp: it freezes, the player warps after it
## (slower than usual) and the timing game decides whether it is pulled out of warp.
func start_interdict(ship: Ship, target: Ship, slot: String, d: Dictionary) -> void:
	target.warp_frozen = true
	var size := int(target.fit.hull().get("size", 1))
	var dist := ship.position.distance_to(target.position)
	if dist >= Universe.WARP_MIN:
		# straight into warp (no aligning) – held ~2 s short of the target while the game runs
		var s := ship.fit.stats()
		var dir := (ship.position - target.position).normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.RIGHT
		var to := target.position + dir * (target.radius + 900.0)
		ship.order = {"type": "warping"}
		ship.spool = -1.0
		ship.clear_locks()
		ship.target = null
		ship.warp = {"from": ship.position, "to": to, "t": 0.0, "T": (4.0 + dist / maxf(float(s["warp_speed"]), 1.0)) * 1.5,
			"then": {}, "name": target.display_name(), "hold": true}
		spawn_fx(Fx.flash(ship.position, Color(0.6, 0.85, 1.0), ship.radius * 3.0))
		on_warp_started(ship)
	else:
		ship.set_order({"type": "approach", "node": target})
	var game = InterdictGameScript.new()
	game.setup(target.display_name(), size, InterdictGameScript.TIME_LIMIT, float(d.get("zone_bonus", 0.0)))
	add_child(game)
	game.finished.connect(_finish_interdict)
	_interdict = {"ship": ship, "target": target, "slot": slot, "data": d, "game": game}
	GameState.log_msg("%s locks onto %s – it is frozen in warp. Hit the timing window while you close in!" % [d["name"], target.display_name()], GameState.COL_WARN)


func _finish_interdict(success: bool) -> void:
	if _interdict.is_empty():
		return
	var tgt = _interdict["target"]
	var ship = _interdict["ship"]
	var d: Dictionary = _interdict["data"]
	if is_instance_valid(_interdict["game"]):
		_interdict["game"].queue_free()
	if is_instance_valid(ship):
		ship.module_on[_interdict["slot"]] = false
		ship.module_state[_interdict["slot"]] = "off"
	_interdict = {}
	if tgt == null or not is_instance_valid(tgt) or tgt.dying:
		return
	tgt.warp_frozen = false
	if success:
		tgt.warp = {}
		tgt.velocity = Vector2.ZERO
		tgt.order = {"type": "idle"}
		tgt.warp_disrupted = 45.0
		spawn_fx(Fx.flash(tgt.position, Color(0.6, 0.85, 1.0), tgt.radius * 4.0))
		GameState.log_msg("%s: %s was pulled out of warp – its warp drive is disrupted for 45 s." % [d["name"], tgt.display_name()], GameState.COL_GOOD)
		if ship == player and tgt.faction in ["civilian", "patrol"] and not tgt.hostile_to_player():
			GameState.law.offence(GameState.law.authority(system_id, tgt.fit.gov), "interdict", "%s pulled out of warp" % tgt.display_name())
	else:
		GameState.log_msg("%s: %s broke free and continues its warp." % [d["name"], tgt.display_name()], GameState.COL_BAD)


func _update_interdict() -> void:
	if _interdict.is_empty():
		return
	var tgt = _interdict["target"]
	var ship = _interdict["ship"]
	if tgt == null or not is_instance_valid(tgt) or tgt.dying or ship == null or not is_instance_valid(ship) or ship.dying:
		if is_instance_valid(_interdict["game"]):
			_interdict["game"].queue_free()
		if is_instance_valid(ship):
			ship.module_on[_interdict["slot"]] = false
		_interdict = {}


## An NPC (convoy) jumped out of the system through a gate.
func npc_jump(ship: Ship, next: int) -> void:
	if traffic != null:
		traffic.on_jump(ship, next)
	else:
		ship.queue_free()


func on_ship_destroyed(ship: Ship, _killer) -> void:
	spawn_fx(Fx.explosion(ship.position, ship.radius * 3.0, Color(1.0, 0.6, 0.2)))
	spawn_fx(Fx.flash(ship.position, Color(1.0, 0.8, 0.4), ship.radius * 2.0))
	if ship == player:
		player = null
		GameState.on_player_ship_lost(ship.fit)
		return
	_aggro.erase(ship.get_instance_id())
	if _killer is Ship and is_instance_valid(_killer) and _killer.faction == "player":
		GameState.notify_target(ship.notorious_id, ship.smuggler_mission)
	elif ship.smuggler_mission != "":
		# someone else finished the smuggler: it counts if the pilot had a hand in it
		if ship.provoked:
			GameState.notify_target("", ship.smuggler_mission)
		else:
			for m9 in GameState.missions.duplicate():
				if m9["id"] == ship.smuggler_mission:
					GameState.fail_mission(m9, "someone else stopped the smuggler")
	if ship.notorious_id != "":
		var by_player: bool = _killer is Ship and is_instance_valid(_killer) and _killer.faction == "player"
		GameState.notorious.on_killed(ship.notorious_id, by_player)
		GameState.log_msg("NOTORIOUS PIRATE DOWN: %s has been destroyed%s." % [ship.display_name(), "" if by_player else " – but not by you"], GameState.COL_GOOD if by_player else GameState.COL_WARN)
	if _killer is Ship and is_instance_valid(_killer) and _killer.faction == "player":
		GameState.rep.on_kill(ship.fit.gov, ship.faction, int(ship.fit.hull().get("size", 1)), ship.display_name())
		if ship.innocent and ship.faction in ["civilian", "patrol"]:
			GameState.law.offence(GameState.law.authority(system_id, ship.fit.gov), "kill_" + ship.faction, "%s destroyed" % ship.display_name())
	if ship.faction != "pirate":
		_lawful_wreck(ship, _killer)
		return
	if _killer is Ship and _killer.faction == "player":
		GameState.notify("kill", system_id)
		if ship.bounty > 0:
			var bond := GameState.add_bond(system_id, ship.display_name(), ship.bounty, ship.bounty_by)
			GameState.log_msg("%s destroyed. Bounty bond from the %s: %s – redeem it at %s." % [ship.display_name(), FactionData.name_of(String(bond["faction"])), GameData.fmt_credits(ship.bounty), GameState.bond_where(bond, system_id)], GameState.COL_GOOD)
		else:
			GameState.log_msg("%s destroyed – there was no bounty on its head." % ship.display_name(), GameState.COL_INFO)
	elif player != null and is_instance_valid(player) and player.position.distance_to(ship.position) < 60000.0:
		GameState.log_msg("%s was destroyed by station defence." % ship.display_name(), GameState.COL_INFO)
	var loot := {"salvage": randi_range(3, 10)}
	if randf() < 0.35:
		loot["weapon_parts"] = randi_range(1, 4)
	# package 20: part of its cargo survives
	ship.ensure_manifest()
	for cid in ship.fit.cargo:
		var keep := int(float(ship.fit.cargo[cid]) * randf_range(0.3, 0.6))
		if keep > 0 and GameData.commodities.has(cid):
			loot[cid] = int(loot.get(cid, 0)) + keep
	if randf() < 0.25:
		var mods: Array = ship.fit.modules.values()
		if not mods.is_empty():
			loot["mod:" + String(mods[randi() % mods.size()])] = 1
	if ship.notorious_id != "":
		# special loot: three of its modules (weapons first), rare metals and plenty of parts
		loot = {"salvage": randi_range(20, 35), "weapon_parts": randi_range(8, 15), "platinum_ingot": randi_range(4, 10), "iridium_ingot": randi_range(2, 6)}
		var mods2: Array = []
		for k in ship.fit.modules:
			if String(k).begins_with("weapon"):
				mods2.push_front(ship.fit.modules[k])
			elif not String(k) in ["hull", "engine", "distributor", "reactor", "tank", "hyperdrive", "sensors"]:
				mods2.append(ship.fit.modules[k])
		mods2 = mods2.filter(func(x): return not GameData.modules.get(x, {}).get("notorious_only", false))
		for m in mods2.slice(0, 3):
			loot["mod:" + String(m)] = int(loot.get("mod:" + String(m), 0)) + 1
	_wreck_counter += 1
	_add_celestial("wreck", {
		"id": "w%d" % _wreck_counter, "name": "Wreck: %s" % ship.display_name(), "seed": randi(),
		"pos": ship.position, "loot": loot, "salvage": 0.0, "life": 600.0,
	})


## Name of the nearest landmark (station, gate, field, planet …) – for radio messages.
func landmark(p: Vector2) -> String:
	var best := "deep space"
	var bd := INF
	for t in Universe.warp_targets(system_id):
		if not String(t["kind"]) in ["station", "gate", "field", "planet", "anomaly", "haven"]:
			continue
		var d := (t["pos"] as Vector2).distance_to(p)
		if d < bd:
			bd = d
			best = String(t["name"])
	return best


## A civilian or patrol ship was attacked: distress call, fleeing traffic, escalation (package 16).
func on_ship_attacked(victim: Ship, attacker: Ship) -> void:
	if traffic != null and is_instance_valid(traffic):
		traffic.on_attacked(victim, attacker)


## Civilians and patrols leave wrecks too (package 16): goods from the hold, parts, sometimes a module.
func _lawful_wreck(ship: Ship, killer) -> void:
	var loot := {"salvage": randi_range(2, 8)}
	if ship.faction == "civilian":
		var goods := ["food", "electronics", "alloys", "medicine", "water", "iron_ingot"]
		for i in randi_range(1, 2):
			var g: String = goods[randi() % goods.size()]
			loot[g] = int(loot.get(g, 0)) + randi_range(3, 15)
	else:
		loot["weapon_parts"] = randi_range(2, 6)
		if randf() < 0.3:
			var mods: Array = ship.fit.modules.values()
			if not mods.is_empty():
				loot["mod:" + String(mods[randi() % mods.size()])] = 1
	_wreck_counter += 1
	_add_celestial("wreck", {
		"id": "w%d" % _wreck_counter, "name": "Wreck: %s" % ship.display_name(), "seed": randi(),
		"pos": ship.position, "loot": loot, "salvage": 0.0, "life": 600.0,
	})
	if killer is Ship and is_instance_valid(killer) and killer.faction == "pirate":
		GameState.news.radio("%s lost near %s – pirates destroyed it." % [ship.display_name(), landmark(ship.position)], system_id, ship.position)


func on_ship_docked(ship: Ship, st_node: Celestial) -> void:
	if ship != player and ship.fit.uid < 0:
		if traffic != null:
			traffic.on_docked(ship, st_node)
		else:
			ship.queue_free()
		return
	for item in ship.fit.cargo.keys():
		if String(item).begins_with("mod:"):
			var n := int(ship.fit.cargo[item])
			GameState.storage_add(st_node.data["id"], String(item).substr(4), n)
			ship.fit.cargo.erase(item)
			GameState.log_msg("%s unloaded into station storage." % GameData.item_name(item))
	if ship == player:
		GameState.codex.event("dock")
		GameState.log_msg("%s docked at %s." % [ship.display_name(), st_node.title()])
		var here := GameState.bonds_redeemable_at(st_node.data, system_id)
		if not here.is_empty():
			var sum := 0
			for b in here:
				sum += int(b["amount"])
			GameState.log_msg("You hold %d bond%s worth %s that can be redeemed here – visit the Bond Office." % [here.size(), "" if here.size() == 1 else "s", GameData.fmt_credits(sum)], GameState.COL_GOOD)
		station_docked.emit(st_node.data["id"])


func complete_anomaly(node: Celestial, ship: Ship) -> void:
	node.data["done"] = true
	node.data["analysis"] = 100.0
	GameState.notify("analyse", system_id)
	var diff := float(node.data["difficulty"])
	var amount := int(diff / 8.0) + randi_range(1, 3)
	var added := ship.fit.add_cargo("research_data", amount)
	var text := "Analysis of %s complete: %d research data" % [node.data["name"], int(added)]
	if added < amount:
		text += " (cargo hold full!)"
	if randf() < 0.3:
		var candidates: Array = []
		for cand in GameData.modules:
			if int(GameData.modules[cand]["size"]) <= 2:
				candidates.append(cand)
		var found: String = candidates[randi() % candidates.size()]
		if ship.fit.add_cargo("mod:" + found, 1) > 0.0:
			text += ", found: %s" % GameData.module_name(found)
	if node.data.get("exotic", false) and ship.faction == "player":
		var em := randi_range(2, 4)
		GameState.exotic_matter += em
		text += " – and %d units of exotic matter (now %d)" % [em, GameState.exotic_matter]
	GameState.log_msg(text, GameState.COL_GOOD)
	var sec: float = Universe.systems[system_id]["security"]
	if randf() < 0.2 + (1.0 - sec) * 0.35:
		for i in randi_range(1, 3):
			var s := spawn_npc(_pirate_preset(), node.position + Vector2.from_angle(randf() * TAU) * 900.0)
			s.home = node.position
			spawn_fx(Fx.flash(s.position, Color(1.0, 0.4, 0.3), s.radius * 3.0))
		GameState.log_msg("Ambush! Pirates were guarding the anomaly.", GameState.COL_BAD)


func complete_salvage(node: Celestial, ship: Ship) -> void:
	var got: Array = []
	for item in node.data["loot"].keys():
		var n := float(node.data["loot"][item])
		var added := ship.fit.add_cargo(item, n)
		if added > 0.0:
			got.append("%s ×%d" % [GameData.item_name(item), int(added)])
		node.data["loot"][item] = n - added
	GameState.log_msg("%s salvaged: %s" % [ship.display_name(), ", ".join(PackedStringArray(got)) if not got.is_empty() else "nothing (cargo hold full)"], GameState.COL_GOOD)
	celestials.erase(node)
	by_id.erase(node.data.get("id", ""))
	node.queue_free()


func sync_to_fits() -> void:
	if player != null and is_instance_valid(player):
		player.fit.position = player.position
		player.fit.rotation = player.heading
