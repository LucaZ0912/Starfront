class_name Traffic
extends Node
## Life in the current system (phase 0.5 package 11). How much there is comes from the system's
## profile (Universe.system_profile): population from the planets, stations and their economy,
## the controlling faction.
##   Shuttles     between populated planets and stations (land / dock and disappear)
##   Miners       from mining colonies / ice refineries to the fields, mine real asteroids
##                (they compete with the player for ore), fly home and dock
##   Patrols      groups of the controlling faction (contested: one per claimant) touring stations,
##                gates and fields; better ships around military stations; they fight pirates
##   Convoys      live part of the cluster-wide ConvoySim: freighters (+ escorts) crossing the
##                system to the next gate or docking at their destination
## Never more than Universe.NPC_CAP ships in the system.

const FactionData = preload("res://data/factions.gd")
const PATROL_RESPAWN := 150.0
const ConvoySimScript = preload("res://scripts/core/convoy_sim.gd")

var view          # SystemView
var sid := -1
var profile: Dictionary = {}
var shuttles: Array = []      # {ship, mode: "in"/"out", planet, station}
var miners: Array = []        # {ship, station, field, state, t}
var loiterers: Array = []     # {ship, kind, anchor, pos, rmin, rmax, life, wait} – stay around one place
var patrols: Array = []       # {gov, ships, wps, wp, dwell, target}
var convoys := {}             # convoy id -> {c, ships: Array, leader, done}
var _tick := 0.0
var _spawn_t := 2.0
var _patrol_wait := {}        # gov -> seconds until a lost patrol is replaced
var _serial := 0


func _ready() -> void:
	sid = view.system_id
	profile = Universe.system_profile(sid)
	_initial()
	if not Universe.test_mode:
		GameState.convoys.convoy_live.connect(_on_convoy_live)
		GameState.convoys.set_observed(sid)


func _exit_tree() -> void:
	if Universe.test_mode or GameState.convoys == null:
		return
	if GameState.convoys.convoy_live.is_connected(_on_convoy_live):
		GameState.convoys.convoy_live.disconnect(_on_convoy_live)
	GameState.convoys.clear_observed(sid)
	for id in convoys.keys():
		var e: Dictionary = convoys[id]
		if e["done"]:
			continue
		var fr := 0
		var es := 0
		for s in e["ships"]:
			if is_instance_valid(s) and not s.dying:
				if s.faction == "civilian":
					fr += 1
				else:
					es += 1
		GameState.convoys.dematerialize(e["c"], fr, es)


# ---------------------------------------------------------------- Helpers

func npc_count() -> int:
	var n := 0
	for s in view.ship_layer.get_children():
		if s is Ship and s != view.player and not s.dying and not s.is_drone:
			n += 1
	return n


func _room(n: int = 1) -> bool:
	return npc_count() + n <= Universe.NPC_CAP


func _alive(s) -> bool:
	return s != null and is_instance_valid(s) and not s.dying


func _reg() -> String:
	_serial += 1
	var letters := "ABCDEFGHKLMNPRSTVXZ"
	return "%s%s-%d" % [letters[randi() % letters.length()], letters[randi() % letters.length()], 100 + (sid * 37 + _serial * 53) % 900]


func _spawn(preset: String, pos: Vector2, role: String, gov: String, name: String = "") -> Ship:
	var s: Ship = view.spawn_npc(preset, pos, role, gov)
	if name != "":
		s.fit.ship_name = name
	s.fit.stance = "aggressive" if role == "patrol" else ("defensive" if s.fit.stats()["weapons"].size() > 0 else "passive")
	return s


## Ships never pop up right in front of the pilot: new ones appear only farther away than this.
const NEAR_PLAYER := 60000.0


func _near_player(p: Vector2) -> bool:
	return view._player_pos().distance_to(p) < NEAR_PLAYER


## A gate far from the pilot to arrive through ({} = none).
func _far_gate() -> Dictionary:
	var gates: Array = []
	for g in view.layout["gates"]:
		if not _near_player(g["pos"]):
			gates.append(g)
	return {} if gates.is_empty() else gates[randi() % gates.size()]


## Arrives through a hyperspace gate far from the pilot (null if there is none).
func _arrive(preset: String, role: String, gov: String, name: String = "") -> Ship:
	var g := _far_gate()
	if g.is_empty():
		return null
	var pos: Vector2 = (g["pos"] as Vector2) + Vector2.from_angle(randf() * TAU) * randf_range(2000.0, 4500.0)
	var s := _spawn(preset, pos, role, gov, name)
	view.spawn_fx(Fx.flash(s.position, Color(0.75, 0.45, 1.0), s.radius * 4.0))
	return s


## Spawned inside a station: it rolls out of a hangar bay with the next order. If the pilot is
## near that station, the ship arrives through a distant gate instead (no pop-up in view) – unless
## `in_view` (escort convoys must be seen leaving their station).
func _spawn_docked(preset: String, st_id: String, role: String, gov: String, name: String = "", in_view: bool = false) -> Ship:
	var st = view.stations.get(st_id)
	var pos: Vector2 = st.position if st != null else Vector2.ZERO
	if st != null and _near_player(pos) and not in_view:
		var a := _arrive(preset, role, gov, name)
		if a != null:
			return a
	var s := _spawn(preset, pos, role, gov, name)
	if st != null:
		s.fit.docked_at = st_id
		s.visible = false
	return s


## Fly to a warp target of this system (warp if far), then carry out `then`.
func go(s: Ship, tid: String, then: Dictionary = {}) -> void:
	var t := Universe.warp_target(sid, tid)
	if t.is_empty() or not _alive(s):
		return
	var dest := s.warp_destination(t)
	if s.position.distance_to(dest) > Universe.WARP_MIN:
		s.set_order({"type": "warp", "target": t, "then": then})
	elif then.is_empty():
		s.set_order({"type": "move", "pos": dest})
	else:
		s.set_order(view.resolve_order(then))


func _idle(s: Ship) -> bool:
	return not s.in_warp() and String(s.order.get("type", "idle")) == "idle" and not s.is_docked()


func _despawn(s, fade: bool = false) -> void:
	if not is_instance_valid(s):
		return
	if fade:
		s.set_physics_process(false)
		var tw: Tween = s.create_tween()
		tw.tween_property(s, "modulate:a", 0.0, 1.2)
		tw.tween_callback(s.queue_free)
	else:
		s.queue_free()


# ---------------------------------------------------------------- Initial population

func _initial() -> void:
	# patrols are already on their beat
	for gov in _patrol_govs():
		_spawn_patrol(gov, false)
	# about half of the rest is already under way somewhere out of sight; the others
	# arrive one by one over the next minutes (see _top_up)
	for i in int(ceil(int(profile["shuttles"]) * 0.5)):
		if not _room():
			break
		_spawn_shuttle(true)
	for i in int(ceil(int(profile["miners"]) * 0.5)):
		if not _room():
			break
		_spawn_miner(true)
	for kind in ["holding", "field_patrols", "pickets", "research"]:
		for i in int(ceil(_wanted(kind) * 0.5)):
			if _room(2):
				_spawn_loiterer(kind, false)


## How many loiterers of a kind the system wants; Axiom research ships only in Directorate systems.
func _wanted(kind: String) -> int:
	if kind == "research":
		return 2 if Universe.controller(sid) == "directorate" else 0
	return int(profile.get(kind, 0))


func _patrol_govs() -> Array:
	var out: Array = []
	var ctl := Universe.controller(sid)
	if ctl in FactionData.POWERS:
		for i in int(profile["patrol_groups"]):
			out.append(ctl)
	else:
		for c in Universe.claimants(sid):
			if c in FactionData.POWERS:
				out.append(c)
	return out


# ---------------------------------------------------------------- Main loop

func _process(delta: float) -> void:
	_tick -= delta
	if _tick > 0.0:
		return
	var dt := 0.5 - _tick
	_tick = 0.5
	_update_shuttles()
	_update_miners(dt)
	_update_patrols(dt)
	_update_convoys()
	_update_loiterers(dt)
	_update_faction_jobs(dt)
	_spawn_t -= dt
	if _spawn_t <= 0.0:
		_spawn_t = randf_range(2.5, 6.0)
		_top_up()


## Staggered arrivals: at most one new ship (group) per call, picked among what is missing.
func _top_up() -> void:
	var todo: Array = []
	if int(profile["shuttles"]) > shuttles.size():
		todo.append("shuttle")
	if int(profile["miners"]) > miners.size():
		todo.append("miner")
	for kind in ["holding", "field_patrols", "pickets", "research"]:
		var have_k := 0
		for l in loiterers:
			if l["kind"] == kind:
				have_k += 1
		if _wanted(kind) > have_k:
			todo.append(kind)
	if not todo.is_empty() and _room(2):
		var pick: String = todo[randi() % todo.size()]
		match pick:
			"shuttle":
				_spawn_shuttle(false)
			"miner":
				_spawn_miner(false)
			_:
				_spawn_loiterer(pick, true)
	var want := _patrol_govs()
	var have := {}
	for p in patrols:
		have[p["gov"]] = int(have.get(p["gov"], 0)) + 1
	for g in want:
		have[g] = int(have.get(g, 0)) - 1
		if int(have[g]) < 0:
			var wait := float(_patrol_wait.get(g, 0.0)) - 5.0
			_patrol_wait[g] = wait
			if wait <= 0.0 and _room(int(profile["patrol_size"])):
				_spawn_patrol(g, true)
				_patrol_wait[g] = PATROL_RESPAWN
			have[g] = 0


## NPC docked somewhere (called by SystemView): shuttles and miners vanish inside, a convoy that
## reached its destination is delivered.
func on_docked(s: Ship, st_node) -> void:
	for e in convoys.values():
		if s in e["ships"] and not e["done"] and st_node.data["id"] == e["c"]["dst_st"]:
			e["done"] = true
			var arrived := 0
			for o2 in e["ships"]:
				if _alive(o2) and o2.faction == "civilian":
					arrived += 1
			e["c"]["freighters"] = maxi(arrived, 1)
			for o in e["ships"]:
				if is_instance_valid(o) and o != s:
					_despawn(o)
			GameState.convoys.live_delivered(e["c"])
			if view.player != null and is_instance_valid(view.player) and view.player.position.distance_to(s.position) < 80000.0:
				GameState.log_msg("%s delivered its cargo to %s." % [ConvoySimScript.label(e["c"]), st_node.title()], GameState.COL_INFO)
			break
	_despawn(s)


## NPC jumped out through a gate (called by SystemView): convoys continue in the simulation.
func on_jump(s: Ship, next: int) -> void:
	view.spawn_fx(Fx.flash(s.position, Color(0.75, 0.45, 1.0), s.radius * 4.0))
	# the pilot follows this convoy: jump after it (package 17)
	var pl = view.player
	if pl != null and is_instance_valid(pl) and String(pl.order.get("type", "")) == "follow":
		var fol = pl.order.get("node")
		for e0 in convoys.values():
			if fol in e0["ships"] and s in e0["ships"]:
				GameState.follow_convoy = int(e0["c"]["id"])
				if GameState.can_jump(pl.fit, next) == "":
					pl.fit.route = [next]
					pl.set_order({"type": "travel"})
					GameState.log_msg("The convoy jumps to %s – you follow." % Universe.systems[next]["name"], GameState.COL_INFO)
				else:
					GameState.log_msg("The convoy jumped to %s – you cannot follow: %s" % [Universe.systems[next]["name"], GameState.can_jump(pl.fit, next)], GameState.COL_WARN)
				break
	for id in convoys.keys():
		var e: Dictionary = convoys[id]
		if s in e["ships"] and not e["done"]:
			e["done"] = true
			var fr := 0
			var es := 0
			for o in e["ships"]:
				if _alive(o):
					if o.faction == "civilian":
						fr += 1
					else:
						es += 1
					if o != s:
						view.spawn_fx(Fx.flash(o.position, Color(0.75, 0.45, 1.0), o.radius * 4.0))
					_despawn(o)
			GameState.convoys.live_jumped(e["c"], next, fr, es)
			return
	_despawn(s)


# ---------------------------------------------------------------- Shuttles

func _populated_planets() -> Array:
	var out: Array = []
	for i in view.layout["planets"].size():
		var p: Dictionary = view.layout["planets"][i]
		var w := float(Universe.PLANET_POP.get(String(p["type"]), 0.1))
		out.append([i, w])
	return out


func _spawn_shuttle(midway: bool) -> void:
	var L: Dictionary = view.layout
	if L["stations"].is_empty() or L["planets"].is_empty():
		return
	var pl := _populated_planets()
	var total := 0.0
	for e in pl:
		total += float(e[1])
	var r := randf() * total
	var pidx := 0
	for e2 in pl:
		r -= float(e2[1])
		if r <= 0.0:
			pidx = int(e2[0])
			break
	var planet: Dictionary = L["planets"][pidx]
	# the station of this planet, otherwise the nearest one
	var st: Dictionary = L["stations"][0]
	var bd := INF
	for s2 in L["stations"]:
		var d := (s2["pos"] as Vector2).distance_to(planet["pos"])
		if int(s2.get("planet", -1)) == pidx:
			d *= 0.1
		if d < bd:
			bd = d
			st = s2
	var gov := String(st.get("faction", ""))
	# package 25c: in rich systems Maison Aurelle Boulevards ply between the stations
	if L["stations"].size() >= 2 and Missions.wealthy(sid) and randf() < BOULEVARD_SHARE:
		_spawn_liner(midway)
		return
	var name := "Skiff %s" % _reg()
	var inbound := randf() < 0.5
	var ppos: Vector2 = planet["pos"]
	var spos: Vector2 = st["pos"]
	var dir := (spos - ppos).normalized()
	var s: Ship
	if not midway and not inbound and _near_player(spos):
		inbound = true               # don't pop out of the station in front of the pilot – rise from the planet instead
	if midway:
		var pos := ppos.lerp(spos, randf_range(0.2, 0.85)) + dir.orthogonal() * randf_range(-3000.0, 3000.0)
		if _near_player(pos):
			return
		s = _spawn("civ_shuttle", pos, "civilian", gov, name)
	elif inbound:
		s = _spawn("civ_shuttle", ppos + dir * float(planet["radius"]) * 1.05, "civilian", gov, name)
		s.modulate.a = 0.0
		s.create_tween().tween_property(s, "modulate:a", 1.0, 1.5)
	else:
		s = _spawn_docked("civ_shuttle", st["id"], "civilian", gov, name)
	s.heading = (dir if inbound else -dir).angle()
	if inbound:
		go(s, st["id"], {"type": "dock", "id": st["id"]})
	else:
		go(s, planet["id"])
	shuttles.append({"ship": s, "mode": "in" if inbound else "out", "planet": pidx, "station": st["id"]})


const BOULEVARD_SHARE := 0.35


## A Boulevard liner from one station to another (package 25c); counts as a shuttle.
func _spawn_liner(midway: bool) -> void:
	var L: Dictionary = view.layout
	var a: Dictionary = L["stations"][randi() % L["stations"].size()]
	var b: Dictionary = a
	while b["id"] == a["id"]:
		b = L["stations"][randi() % L["stations"].size()]
	var gov := String(b.get("faction", ""))
	var name := "Boulevard %s" % _reg()
	var s: Ship
	if midway:
		var pos := (a["pos"] as Vector2).lerp(b["pos"], randf_range(0.2, 0.8))
		if _near_player(pos):
			return
		s = _spawn("civ_boulevard", pos, "civilian", gov, name)
	else:
		s = _spawn_docked("civ_boulevard", a["id"], "civilian", gov, name)
	s.heading = ((b["pos"] as Vector2) - (a["pos"] as Vector2)).angle()
	go(s, b["id"], {"type": "dock", "id": b["id"]})
	shuttles.append({"ship": s, "mode": "in", "planet": int(b.get("planet", 0)), "station": b["id"]})


func _update_shuttles() -> void:
	for e in shuttles.duplicate():
		var s = e["ship"]
		if not _alive(s):
			shuttles.erase(e)
			continue
		if e["mode"] == "out" and _idle(s):
			var p: Dictionary = view.layout["planets"][int(e["planet"])]
			if s.position.distance_to(p["pos"]) < float(p["radius"]) * 2.4:
				# descend into the atmosphere
				s.set_order({"type": "move", "pos": p["pos"]})
				_despawn(s, true)
				shuttles.erase(e)
			else:
				go(s, p["id"])
		elif e["mode"] == "in" and _idle(s):
			go(s, e["station"], {"type": "dock", "id": e["station"]})


# ---------------------------------------------------------------- Miners

func _mine_stations() -> Array:
	var out: Array = []
	for st in view.layout["stations"]:
		if st["type"] in ["mining_colony", "ice_refinery"]:
			out.append(st)
	return out


func _field_for(icy: bool, near: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var bd := INF
	for f in view.layout["fields"]:
		if (f["class"] == "icy") != icy:
			continue
		var d := (f["pos"] as Vector2).distance_to(near)
		if d < bd:
			bd = d
			best = f
	return best


func _spawn_miner(at_work: bool) -> void:
	var sts := _mine_stations()
	var st: Dictionary = {}
	if not sts.is_empty():
		st = sts[randi() % sts.size()]
	elif view.layout["fields"].is_empty():
		return
	else:
		at_work = true                                # no station: a freelancer already at work
	var icy: bool = String(st.get("type", "")) == "ice_refinery" or (st.is_empty() and randf() < 0.3)
	var near: Vector2 = st.get("pos", Vector2.ZERO)
	var field := _field_for(icy, near)
	if field.is_empty():
		field = _field_for(not icy, near)
		icy = not icy
	if field.is_empty():
		return
	var preset := ("civ_ice_miner" if icy else "civ_miner") + ("_khi" if randf() < 0.5 else "")   # package 25a
	var gov := String(st.get("faction", ""))
	var name := "%s %s" % ["Iceboat" if icy else "Prospector", _reg()]
	var s: Ship
	var e := {"station": String(st.get("id", "")), "field": field["id"], "icy": icy, "state": "out", "t": 0.0}
	if at_work and _near_player(field["pos"]):
		if st.is_empty():
			return
		at_work = false
	if at_work:
		var fp: Vector2 = field["pos"]
		s = _spawn(preset, fp + Vector2.from_angle(randf() * TAU) * randf_range(1000.0, float(field["radius"]) * 0.6), "civilian", gov, name)
		e["state"] = "mining"
	else:
		s = _spawn_docked(preset, st["id"], "civilian", gov, name)
		go(s, field["id"])
	e["ship"] = s
	miners.append(e)


func _miner_home(s: Ship, e: Dictionary) -> void:
	e["state"] = "home"
	if String(e["station"]) == "":
		view.spawn_fx(Fx.flash(s.position, Color(0.6, 0.85, 1.0), s.radius * 3.0))
		_despawn(s, true)          # freelancer warps off to sell elsewhere
		miners.erase(e)
	else:
		go(s, e["station"], {"type": "dock", "id": e["station"]})


func _pick_rock(s: Ship, e: Dictionary):
	var best = null
	var bd := INF
	for a in view.asteroid_nodes:
		if not is_instance_valid(a) or a.is_depleted() or String(a.data.get("field", "")) != e["field"]:
			continue
		if (String(a.data.get("class", "")) == "icy") != bool(e["icy"]):
			continue
		var d: float = s.position.distance_to(a.position)
		if d < bd:
			bd = d
			best = a
	return best


func _update_miners(dt: float) -> void:
	for e in miners.duplicate():
		var s = e["ship"]
		if not _alive(s):
			miners.erase(e)
			continue
		if s.is_docked() or s.in_warp():
			continue
		e["t"] = float(e["t"]) + dt
		match String(e["state"]):
			"out":
				if _idle(s):
					e["state"] = "mining"
					e["t"] = 0.0
			"mining":
				if String(s.order.get("type", "")) == "mine":
					continue
				if s.target != null and _alive(s.target):
					continue          # defending itself
				var full: bool = s.fit.free_for("iron_ore" if not e["icy"] else "water_ice") < 1.0
				if full or float(e["t"]) > 480.0:
					_miner_home(s, e)
					continue
				var rock = _pick_rock(s, e)
				if rock == null:
					_miner_home(s, e)
				else:
					s.set_order({"type": "mine", "node": rock})
			"home":
				if _idle(s):
					_miner_home(s, e)


# ---------------------------------------------------------------- Patrols

## The Directorate flies Earthworks and Hadrian Dynamics ships (package 25d): half of its patrol
## ships are Talons, Mauls and Goliaths.
const HDY_PATROL := {"patrol_light": "patrol_hdy_light", "patrol_medium": "patrol_hdy_medium", "patrol_heavy": "patrol_hdy_heavy"}


## Package 25e: in its own systems a power's patrols fly its state manufacturer's ships – the Assembly
## Concord carriers (now and then a Goliath in its colours); in contested systems Earthworks ships.
const CFW_PATROL := {"patrol_light": "patrol_cfw_light", "patrol_medium": "patrol_cfw_medium", "patrol_heavy": "patrol_cfw_heavy"}
const GOLIATH_SHARE := 0.15
const FOR_PATROL := {"patrol_light": "patrol_for_light", "patrol_medium": "patrol_for_medium", "patrol_heavy": "patrol_for_heavy"}


func _gov_presets(gov: String, presets: Array) -> Array:
	if Universe.controller(sid) != gov:
		return presets                   # contested / foreign system: Earthworks ships
	var out: Array = []
	for p in presets:
		match gov:
			"assembly":
				if p in ["patrol_medium", "patrol_heavy"] and randf() < GOLIATH_SHARE:
					out.append("patrol_hdy_heavy")
				else:
					out.append(CFW_PATROL.get(p, p))
			"covenant":
				if p in ["patrol_medium", "patrol_heavy"] and randf() < GOLIATH_SHARE:
					out.append("patrol_hdy_heavy")
				else:
					out.append(FOR_PATROL.get(p, p))
			"directorate":
				out.append(HDY_PATROL[p] if HDY_PATROL.has(p) and randf() < 0.5 else p)
			_:
				out.append(p)
	return out


func _patrol_presets() -> Array:
	var q := int(profile["patrol_quality"])
	var n := maxi(1, int(profile["patrol_size"]))
	var out: Array = []
	for i in n:
		var lvl := q - i
		out.append(["patrol_light", "patrol_medium", "patrol_heavy"][clampi(lvl, 0, 2)])
	return out


## Patrol beat: the stations, the gates and a field or two, in a ring.
func _waypoints() -> Array:
	var L: Dictionary = view.layout
	var wps: Array = []
	for st in L["stations"]:
		wps.append(st["id"])
	var gates: Array = L["gates"].duplicate()
	gates.shuffle()
	for g in gates.slice(0, 3):
		wps.append(g["id"])
	var fields: Array = L["fields"].duplicate()
	fields.shuffle()
	for f in fields.slice(0, 2):
		wps.append(f["id"])
	if wps.is_empty():
		wps.append("star")
	wps.shuffle()
	return wps


func _spawn_patrol(gov: String, arriving: bool, presets_override: Array = []) -> void:
	var wps := _waypoints()
	var g := {"gov": gov, "ships": [], "wps": wps, "wp": randi() % wps.size(), "dwell": randf_range(5.0, 25.0), "target": {}}
	for k in wps.size():
		if not _near_player(Universe.warp_target(sid, wps[g["wp"]]).get("pos", Vector2.ZERO)):
			break
		g["wp"] = (int(g["wp"]) + 1) % wps.size()
	var t := Universe.warp_target(sid, wps[g["wp"]])
	var base: Vector2 = t.get("pos", Vector2.ZERO) + Vector2.from_angle(randf() * TAU) * float(t.get("land", 3000.0))
	# reinforcements come out of a friendly station if there is one
	var from_st := ""
	if arriving:
		for st in view.layout["stations"]:
			if String(st.get("faction", "")) == gov:
				from_st = st["id"]
				break
	var presets := _gov_presets(gov, _patrol_presets()) if presets_override.is_empty() else presets_override
	for i in presets.size():
		var hull_name: String = GameData.hulls[GameData.presets[presets[i]]["hull"]]["name"]
		var nm := "%s %s %s" % [FactionData.FACTIONS[gov]["pilot"], hull_name, _reg()]
		var s: Ship
		if from_st != "":
			s = _spawn_docked(presets[i], from_st, "patrol", gov, nm)
		else:
			if arriving:
				s = _arrive(presets[i], "patrol", gov, nm)
			if s == null:
				s = _spawn(presets[i], base + Vector2.from_angle(i * 2.1) * (300.0 + i * 250.0), "patrol", gov, nm)
		g["ships"].append(s)
	patrols.append(g)


func _update_patrols(dt: float) -> void:
	for g in patrols.duplicate():
		var alive: Array = []
		for s in g["ships"]:
			if _alive(s):
				alive.append(s)
		g["ships"] = alive
		if alive.is_empty():
			patrols.erase(g)
			_patrol_wait[g["gov"]] = PATROL_RESPAWN
			if g.has("mission"):
				for m9 in GameState.missions.duplicate():
					if m9["id"] == g["mission"]:
						GameState.fail_mission(m9, "the patrol was destroyed")
			continue
		var leader: Ship = alive[0]
		if g.has("mission"):
			_mark_group(g, alive, leader)
		# reinforcements and task forces leave again after a while
		if g.has("leave_at") and GameState.play_time >= float(g["leave_at"]):
			for s9 in alive:
				_despawn(s9, true)
			patrols.erase(g)
			continue
		# combat: whoever sees a pirate attacks, the others join in
		var foe = null
		for s2 in alive:
			if _alive(s2.target) and s2.target.faction == "pirate":
				foe = s2.target
				break
		if foe != null:
			for s3 in alive:
				if s3.in_warp() or s3.is_docked() or String(s3.order.get("type", "")) in ["undocking", "docking"]:
					continue
				if String(s3.order.get("type", "")) != "attack":
					var own = s3.target if _alive(s3.target) and s3.target.faction == "pirate" else foe
					s3.set_order({"type": "attack", "target": own})
			continue
		# wingmen follow the leader into warp, otherwise fly in formation
		for i in range(1, alive.size()):
			var w: Ship = alive[i]
			if w.in_warp() or (w.is_docked() and leader.is_docked()) or String(w.order.get("type", "")) in ["undocking", "docking", "warp"]:
				continue
			if leader.in_warp() or String(leader.order.get("type", "")) == "warp":
				if not g["target"].is_empty():
					w.set_order({"type": "warp", "target": g["target"], "then": {}})
			elif String(w.order.get("type", "")) != "keep" or w.order.get("node") != leader:
				w.set_order({"type": "keep", "node": leader, "r": 260.0 + i * 220.0})
		# answering a distress call: go there and stay a while (package 16)
		var resp: Dictionary = g.get("respond", {})
		if not resp.is_empty():
			if GameState.play_time < float(resp["until"]):
				var culprit = resp.get("culprit")
				if culprit != null and is_instance_valid(culprit) and not culprit.dying and Ship.hostile(leader, culprit) and leader.can_see(culprit):
					for s4 in alive:
						if String(s4.order.get("type", "")) != "attack" and not s4.in_warp():
							s4.set_order({"type": "attack", "target": culprit})
				elif _idle(leader) and leader.position.distance_to(resp["pos"]) > 6000.0:
					leader.set_order({"type": "warp", "target": {"id": "incident", "kind": "point", "name": resp["name"], "pos": resp["pos"], "land": 2500.0}, "then": {}})
				continue
			g.erase("respond")
			g["on_beat"] = false
		# a mission patrol first waits at its meeting point for the pilot (package 17)
		if g.get("gather", false):
			if leader.is_docked() or (_idle(leader) and leader.position.distance_to(g["gather_pos"]) > 300.0):
				leader.set_order({"type": "move", "pos": g["gather_pos"]})
			_check_patrol_gather(g, leader)
			continue
		# the leader tours the waypoints. At each one it flies a slow beat – round stations and
		# gates (never across them), through asteroid fields – then warps on. Reinforcements
		# start docked and leave at once.
		if leader.is_docked():
			_next_waypoint(g, leader)
			continue
		if g.get("on_beat", false):
			g["dwell"] = float(g["dwell"]) - dt
		if not _idle(leader):
			continue
		if not g.get("on_beat", false):
			g["on_beat"] = true
			g["beat"] = _beat_points(String(g["wps"][g["wp"]]), leader.position)
			g["dwell"] = randf_range(90.0, 180.0)
		var beat: Array = g["beat"]
		if beat.is_empty() or float(g["dwell"]) <= 0.0:
			_next_waypoint(g, leader)
		else:
			leader.set_order({"type": "move", "pos": leader.clear_of_colossi(beat.pop_front()), "pace": BEAT_PACE})


const BEAT_PACE := 0.5           # patrols sweep a waypoint at half their cruising speed


func _next_waypoint(g: Dictionary, leader: Ship) -> void:
	g["on_beat"] = false
	g["beat"] = []
	g["wp"] = (int(g["wp"]) + 1) % (g["wps"] as Array).size()
	var tid: String = g["wps"][g["wp"]]
	g["target"] = Universe.warp_target(sid, tid)
	go(leader, tid)


## Sweep points for a patrol beat at waypoint `tid`, starting from `from`.
## Stations, gates and other bodies: a ring well outside the structure, flown in steps of at
## most 60° in one direction, so every leg stays clear of the body. Fields: a zig-zag through it.
func _beat_points(tid: String, from: Vector2) -> Array:
	var t := Universe.warp_target(sid, tid)
	var pts: Array = []
	if t.is_empty():
		return pts
	var c: Vector2 = t["pos"]
	if String(t["kind"]) == "field":
		var fr := float(t["data"].get("radius", 10000.0)) * 0.75
		for i in randi_range(3, 5):
			pts.append(c + Vector2.from_angle(randf() * TAU) * fr * sqrt(randf_range(0.15, 1.0)))
		return pts
	var body_r := float(t.get("land", 3000.0)) * 0.3
	var node = view.by_id.get(tid)
	if node != null and is_instance_valid(node):
		body_r = float(node.radius)
	var ring := body_r * 2.0 + 2500.0
	var a := (from - c).angle()
	var dir := 1.0 if randf() < 0.5 else -1.0
	var sweep := randf_range(0.6, 1.2) * TAU
	var turned := 0.0
	while turned < sweep:
		var step := deg_to_rad(randf_range(40.0, 60.0))
		a += dir * step
		turned += step
		pts.append(c + Vector2.from_angle(a) * ring * randf_range(0.95, 1.12))
	return pts


# ---------------------------------------------------------------- Loiterers
# Ships that stay around one place for a long time and just cruise about slowly:
#   holding        civilian haulers / skiffs waiting near a station for a docking slot
#   field_patrols  two light patrol ships sweeping an asteroid field
#   pickets        one patrol frigate watching a gate

func _spawn_loiterer(kind: String, arriving: bool) -> void:
	var L: Dictionary = view.layout
	var anchor := {}
	var gov := ""
	var presets: Array = []
	var role := "civilian"
	var rmin := 0.0
	var rmax := 0.0
	match kind:
		"holding":
			if L["stations"].is_empty():
				return
			anchor = L["stations"][randi() % L["stations"].size()]
			gov = String(anchor.get("faction", ""))
			presets = ["std_mule" if randf() < 0.6 else "civ_shuttle"]
			rmin = 3000.0
			rmax = 9000.0
		"field_patrols":
			if L["fields"].is_empty():
				return
			anchor = _least_watched_field()
			var govs := _patrol_govs()
			if govs.is_empty():
				return
			gov = govs[randi() % govs.size()]
			presets = ["patrol_light", "patrol_light"]
			role = "patrol"
			rmax = float(anchor.get("radius", 12000.0)) * 0.9
		"research":
			# package 25g: Axiom research ships survey the Directorate's systems
			var places: Array = L["fields"] + L["planets"]
			if places.is_empty():
				return
			anchor = places[randi() % places.size()]
			gov = "directorate"
			presets = ["civ_parallax"]
			rmin = 4000.0
			rmax = 14000.0
		"pickets":
			if L["gates"].is_empty():
				return
			anchor = _least_watched_gate()
			gov = Universe.controller(sid)
			if not gov in FactionData.POWERS:
				return
			presets = ["patrol_medium"]
			role = "patrol"
			rmin = 2500.0
			rmax = 7000.0
	if anchor.is_empty():
		return
	var apos: Vector2 = anchor["pos"]
	if not arriving and _near_player(apos):
		return                       # comes later, from out of sight
	var lead: Ship = null
	for i in presets.size():
		var p: String = presets[i]
		var hull_name: String = GameData.hulls[GameData.presets[p]["hull"]]["name"]
		var who: String = String(FactionData.FACTIONS[gov]["pilot"]) if FactionData.FACTIONS.has(gov) else "Free"
		var nm := "%s %s %s" % [who, hull_name, _reg()] if role == "patrol" else "%s %s" % [hull_name, _reg()]
		var pos := apos + Vector2.from_angle(randf() * TAU) * randf_range(maxf(rmin, 800.0), maxf(rmax, 1500.0))
		var s: Ship = null
		if arriving:
			# arrive through a distant gate (or out of a station out of sight) and fly to the spot
			if kind == "holding" and randf() < 0.5:
				s = _spawn_docked(p, String(L["stations"][randi() % L["stations"].size()]["id"]), role, gov, nm)
			else:
				s = _arrive(p, role, gov, nm)
			if s != null:
				go(s, String(anchor["id"]))
		if s == null:
			if arriving and _near_player(apos):
				return
			s = _spawn(p, view.clear_of_zones(pos) if role == "patrol" and kind == "field_patrols" else pos, role, gov, nm)
		loiterers.append({"ship": s, "kind": kind, "anchor": String(anchor["id"]), "pos": apos, "rmin": rmin, "rmax": rmax,
			"life": randf_range(600.0, 1500.0) if kind != "pickets" else 99999.0, "wait": randf_range(0.0, 10.0), "lead": lead})
		if lead == null:
			lead = s


func _least_watched_field() -> Dictionary:
	var best := {}
	var bn := 999
	for f in view.layout["fields"]:
		var n := 0
		for l in loiterers:
			if l["anchor"] == f["id"]:
				n += 1
		if n < bn:
			bn = n
			best = f
	return best


func _least_watched_gate() -> Dictionary:
	var best := {}
	var bn := 999
	var gates: Array = view.layout["gates"].duplicate()
	gates.shuffle()
	for g in gates:
		var n := 0
		for l in loiterers:
			if l["anchor"] == g["id"]:
				n += 1
		if n < bn:
			bn = n
			best = g
	return best


func _update_loiterers(dt: float) -> void:
	for l in loiterers.duplicate():
		var s = l["ship"]
		if not _alive(s):
			loiterers.erase(l)
			continue
		if s.in_warp() or s.is_docked() or String(s.order.get("type", "")) in ["undocking", "docking", "dock", "warp"]:
			continue
		# patrols fight pirates they see, then go back to their sweep
		if s.faction == "patrol" and _alive(s.target) and s.target.faction == "pirate":
			if String(s.order.get("type", "")) != "attack":
				s.set_order({"type": "attack", "target": s.target})
			continue
		l["life"] = float(l["life"]) - dt
		if float(l["life"]) <= 0.0:
			if l["kind"] == "holding":
				# finally cleared for docking
				go(s, l["anchor"], {"type": "dock", "id": l["anchor"]})
				loiterers.erase(l)
				continue
			# field patrol moves on to another field
			var f := _least_watched_field()
			if not f.is_empty() and f["id"] != l["anchor"]:
				l["anchor"] = f["id"]
				l["pos"] = f["pos"]
				l["rmax"] = float(f["radius"]) * 0.9
				go(s, f["id"])
			l["life"] = randf_range(600.0, 1500.0)
			continue
		if not _idle(s):
			continue
		l["wait"] = float(l["wait"]) - dt
		if float(l["wait"]) > 0.0:
			continue
		l["wait"] = randf_range(8.0, 30.0)
		var lead = l.get("lead")
		var center: Vector2 = l["pos"]
		if _alive(lead) and l["kind"] == "field_patrols":
			# the wingman stays near its leader
			s.set_order({"type": "keep", "node": lead, "r": 600.0})
			continue
		var p := center + Vector2.from_angle(randf() * TAU) * randf_range(float(l["rmin"]), maxf(float(l["rmax"]), float(l["rmin"]) + 500.0))
		s.set_order({"type": "move", "pos": s.clear_of_colossi(p)})


# ---------------------------------------------------------------- Convoys (live)

func _on_convoy_live(c: Dictionary) -> void:
	if int(c["cur"]) != sid:
		return
	var ships: Array = []
	var gov := String(c["gov"])
	var who := String(FactionData.FACTIONS[gov]["pilot"]) if FactionData.FACTIONS.has(gov) else "Free Trader"
	var L: Dictionary = view.layout
	# where the convoy is now: leaving its source station, or between entry and exit
	var docked_at := ""
	var entry := Vector2.ZERO
	if not c["departed"] and int(c["src"]) == sid:
		docked_at = String(c["src_st"])
	elif int(c["prev"]) >= 0 and view.gates.has(int(c["prev"])):
		entry = view.gates[int(c["prev"])].position
	else:
		entry = Vector2.from_angle(randf() * TAU) * 1500000.0 * Universe.SCALE
	var exit := entry
	if int(c["cur"]) == int(c["dst"]):
		var dst = view.stations.get(String(c["dst_st"]))
		if dst != null:
			exit = dst.position
	elif not (c["route"] as Array).is_empty() and view.gates.has(int(c["route"][0])):
		exit = view.gates[int(c["route"][0])].position
	var f := 1.0 - clampf(float(c["t"]) / maxf(float(c["T"]), 1.0), 0.0, 1.0)
	var pos := entry.lerp(exit, f * 0.7) if docked_at == "" else entry
	if docked_at == "" and entry.distance_to(pos) < 3000.0:
		pos = entry + (exit - entry).normalized() * 3000.0
	var n := int(c["freighters"]) + int(c["escorts"])
	for i in n:
		var is_escort := i >= int(c["freighters"])
		var preset := ("patrol_medium" if i == int(c["freighters"]) and int(c["escorts"]) > 1 else "patrol_light") if is_escort else "civ_freighter"
		var nm := "%s %s %s" % [who, "Escort" if is_escort else "Longhaul", _reg()]
		var s: Ship
		if docked_at != "":
			s = _spawn_docked(preset, docked_at, "patrol" if is_escort else "civilian", gov, nm, c.has("mission"))
		else:
			s = _spawn(preset, pos + Vector2.from_angle(i * 1.9) * (i * 450.0), "patrol" if is_escort else "civilian", gov, nm)
			if f < 0.05:
				view.spawn_fx(Fx.flash(s.position, Color(0.75, 0.45, 1.0), s.radius * 4.0))
		s.heading = (exit - entry).angle()
		ships.append(s)
	var e := {"c": c, "ships": ships, "done": false}
	convoys[c["id"]] = e
	if int(c["id"]) == GameState.follow_convoy:
		e["refollow"] = true
	# a convoy under contract escort (package 17): marked green; leaving its station it first gathers
	# outside and waits for the pilot; pirates may lie in wait on the way
	if c.has("mission"):
		for s9 in ships:
			s9.escort_mark = true
		var st_node = view.stations.get(docked_at) if docked_at != "" else null
		if st_node != null and is_instance_valid(st_node):
			var dir: Vector2 = (exit - st_node.position).normalized() if exit.distance_to(st_node.position) > 1.0 else Vector2.RIGHT
			e["gather"] = true
			e["gather_pos"] = st_node.position + dir * (float(st_node.radius) + 2500.0)
			e["gather_t"] = 0.0
			c["gathering"] = true
		else:
			_plan_ambush(e)
			_gate_ambush(e, ships, pos)
	_order_convoy(e)


func _order_convoy(e: Dictionary) -> void:
	var c: Dictionary = e["c"]
	var leader = null
	for s in e["ships"]:
		if _alive(s) and s.faction == "civilian":
			leader = s
			break
	if leader == null:
		return
	e["leader"] = leader
	for s0 in e["ships"]:
		if _alive(s0):
			s0.convoy_lead = s0 == leader
	if e.get("held", false):
		leader.set_order({"type": "idle"})
		return
	if e.get("gather", false):
		# assembling outside the station until the escort arrives
		if (e["gather_pos"] as Vector2).distance_to(leader.position) > 200.0 or leader.is_docked():
			leader.set_order({"type": "move", "pos": e["gather_pos"]})
		return
	if int(c["cur"]) == int(c["dst"]):
		go(leader, String(c["dst_st"]), {"type": "dock", "id": String(c["dst_st"])})
	else:
		leader.fit.route = (c["route"] as Array).duplicate()
		leader.set_order({"type": "travel"})


func _update_convoys() -> void:
	for id in convoys.keys():
		var e: Dictionary = convoys[id]
		if e["done"]:
			convoys.erase(id)
			continue
		var alive: Array = []
		var freighters := 0
		for s in e["ships"]:
			if _alive(s):
				alive.append(s)
				if s.faction == "civilian":
					freighters += 1
		e["ships"] = alive
		if freighters == 0:
			# convoy destroyed: the escorts head for the nearest station
			e["done"] = true
			GameState.convoys.live_lost(e["c"])
			if view.player != null and is_instance_valid(view.player):
				GameState.log_msg("%s was destroyed." % ConvoySimScript.label(e["c"]), GameState.COL_WARN)
			for s2 in alive:
				var st := _nearest_station(s2.position)
				if st != "":
					go(s2, st, {"type": "dock", "id": st})
			convoys.erase(id)
			continue
		var leader = e.get("leader")
		if not _alive(leader):
			_order_convoy(e)
			leader = e.get("leader")
		elif _idle(leader) and not leader.is_docked():
			_order_convoy(e)
		if e.get("gather", false) and _alive(leader):
			_check_gather(e, leader)
		if e["c"].has("mission") and _alive(leader) and not e.get("gather", false):
			_convoy_hold(e, leader)
		if e["c"].has("mission") and _alive(leader):
			_check_interception(e, leader)
			_announce_warp(e, leader)
		# after jumping along with the convoy the pilot follows it again
		if e.get("refollow", false) and _alive(leader) and view.player != null and is_instance_valid(view.player) and not view.player.in_warp() and not view.player.is_docked():
			e["refollow"] = false
			view.player.set_order({"type": "follow", "node": leader, "r": 800.0})
			GameState.log_msg("You are with %s again – following." % ConvoySimScript.label(e["c"]), GameState.COL_INFO)
		# escorts engage pirates, everyone else keeps formation and follows into warp
		for i in alive.size():
			var s3: Ship = alive[i]
			if s3 == leader or s3.in_warp() or (s3.is_docked() and leader.is_docked()) or String(s3.order.get("type", "")) in ["undocking", "docking"]:
				continue
			if s3.faction == "patrol" and _alive(s3.target) and s3.target.faction == "pirate":
				if String(s3.order.get("type", "")) != "attack":
					s3.set_order({"type": "attack", "target": s3.target})
				continue
			# everyone follows the leader – also into warp (package 17: the convoy stays together)
			if String(leader.order.get("type", "")) == "docking":
				if String(s3.order.get("type", "")) != "dock":
					s3.set_order({"type": "dock", "node": leader.order.get("node")})
			elif String(s3.order.get("type", "")) != "follow" or s3.order.get("node") != leader:
				if not leader.is_docked():
					s3.set_order({"type": "follow", "node": leader, "r": 350.0 + i * 320.0})


func _nearest_station(p: Vector2) -> String:
	var best := ""
	var bd := INF
	for st in view.layout["stations"]:
		var d := (st["pos"] as Vector2).distance_to(p)
		if d < bd:
			bd = d
			best = st["id"]
	return best


## Live convoy ships around (for the HUD / tests).
func live_convoy_ships() -> int:
	var n := 0
	for e in convoys.values():
		n += (e["ships"] as Array).size()
	return n


# ---------------------------------------------------------------- World reactions (package 16)
# Attacked civilians and patrols send distress calls (radio ticker); traffic nearby gets out of the
# way; the authority escalates: the nearest patrol responds, then reinforcements arrive, then a
# task force – faster for the Covenant and in safe systems, slower for the Assembly's militias.

const HEAT_DECAY := 0.02          # escalation fades by one step every 50 s
const HEAT_REINFORCE := 3.0
const HEAT_TASKFORCE := 6.0
const FLEE_RADIUS := 25000.0
const ESCALATION := {"covenant": 1.5, "directorate": 1.0, "assembly": 0.8}
var heat := 0.0
var _heat_t := 0.0
var _reinforced_at := -1000.0
var _taskforce_at := -1000.0


func _authority(victim: Ship) -> String:
	var ctl := Universe.controller(sid)
	if ctl in FactionData.POWERS:
		return ctl
	if victim.fit.gov in FactionData.POWERS:
		return victim.fit.gov
	for c in Universe.claimants(sid):
		if c in FactionData.POWERS:
			return c
	return ""


func on_attacked(victim: Ship, attacker: Ship) -> void:
	var where: String = view.landmark(victim.position)
	var is_convoy := false
	for cid in convoys:
		is_convoy = is_convoy or (convoys[cid]["ships"] as Array).has(victim)
	if is_convoy:
		GameState.news.radio("Convoy under attack near %s!" % where, sid, victim.position)
	elif victim.faction == "patrol":
		GameState.news.radio("%s under fire near %s – requesting support!" % [victim.display_name(), where], sid, victim.position)
	else:
		GameState.news.radio("Mayday! %s under attack near %s!" % [victim.display_name(), where], sid, victim.position)
	_scatter(victim.position, attacker)
	var gov := _authority(victim)
	if gov == "":
		return                   # lawless space: nobody comes
	var sec := float(Universe.systems[sid]["security"])
	var step := (1.5 if victim.faction == "patrol" else 1.0) * float(ESCALATION.get(gov, 1.0)) * lerpf(0.6, 1.4, sec)
	_decay_heat()
	heat += step
	var inc := {"pos": victim.position, "name": where, "culprit": attacker, "until": GameState.play_time + 120.0}
	_respond(gov, inc)
	var now := GameState.play_time
	if heat >= HEAT_TASKFORCE and now - _taskforce_at > 180.0:
		_taskforce_at = now
		_reinforce(gov, inc, ["patrol_heavy", "patrol_medium", "patrol_medium"], "task force")
	elif heat >= HEAT_REINFORCE and now - _reinforced_at > 60.0:
		_reinforced_at = now
		_reinforce(gov, inc, ["patrol_medium", "patrol_light"], "reinforcements")


func _decay_heat() -> void:
	var now := GameState.play_time
	heat = maxf(0.0, heat - (now - _heat_t) * HEAT_DECAY)
	_heat_t = now


## The nearest patrol group of the authority answers the call.
func _respond(gov: String, inc: Dictionary) -> void:
	var best = null
	var bd := INF
	for g in patrols:
		if g["gov"] != gov or (g["ships"] as Array).is_empty() or not g.get("respond", {}).is_empty():
			continue
		var lead = g["ships"][0]
		if not _alive(lead):
			continue
		var d: float = lead.position.distance_to(inc["pos"])
		if d < bd:
			bd = d
			best = g
	if best == null:
		return
	best["respond"] = inc.duplicate()
	GameState.news.radio("%s patrol responding to the distress call near %s." % [FactionData.short_of(gov), inc["name"]], sid, inc["pos"])


func _reinforce(gov: String, inc: Dictionary, presets: Array, what: String) -> void:
	if not _room(presets.size()):
		return
	_spawn_patrol(gov, true, presets)
	var g: Dictionary = patrols.back()
	g["respond"] = inc.duplicate()
	g["respond"]["until"] = GameState.play_time + 240.0
	g["leave_at"] = GameState.play_time + 300.0
	GameState.news.radio("%s %s inbound to %s." % [FactionData.short_of(gov), what, inc["name"]], sid, inc["pos"])


## Traffic near a fight gets out of the way: civilians move off, away from the attacker.
func _scatter(pos: Vector2, attacker: Ship) -> void:
	for n in view.ship_layer.get_children():
		if not (n is Ship) or n.faction != "civilian" or n.dying or n.in_warp() or n.is_docked():
			continue
		if n.position.distance_to(pos) > FLEE_RADIUS or n.escort_mark or convoy_of(n) >= 0:
			continue                 # convoys keep together (and hold, see _convoy_hold)
		var away: Vector2 = n.position - (attacker.position if is_instance_valid(attacker) else pos)
		if away.length() < 1.0:
			away = Vector2.from_angle(randf() * TAU)
		n.set_order({"type": "move", "pos": n.position + away.normalized() * 20000.0})
		n.activity = "Fleeing the fight"


# ---------------------------------------------------------------- Faction contracts (package 17)

var smugglers: Array = []          # {ship, mission, gate}


func _update_faction_jobs(dt: float) -> void:
	_ballot_thieves()                                # package 39a
	# convoy ambushes
	for e in convoys.values():
		if not e.has("ambush_t") or e.get("done", false):
			continue
		e["ambush_t"] = float(e["ambush_t"]) - dt
		if float(e["ambush_t"]) <= 0.0:
			e.erase("ambush_t")
			ambush(e)
	var pl = view.player
	for m in GameState.missions:
		if int(m["progress"]) >= 1 or int(m["target_system"]) != sid:
			continue
		match String(m["type"]):
			"patrol":
				var mg: Dictionary = {}
				for g0 in patrols:
					if g0.get("mission", "") == m["id"]:
						mg = g0
				if mg.is_empty():
					spawn_mission_patrol(m)  # contract groups ignore the NPC limit
					continue
				if pl == null or not is_instance_valid(pl) or pl.is_docked() or mg.get("gather", false):
					continue
				var near := false
				for ps in mg["ships"]:
					near = near or (_alive(ps) and ps.position.distance_to(pl.position) <= Missions.PATROL_RANGE)
				if near:
					m["progress_t"] = float(m["progress_t"]) + dt
					if float(m["progress_t"]) >= float(m["amount"]):
						m["progress"] = 1
						GameState.log_msg("Patrol flown with the %s – report back to the issuing station." % FactionData.short_of(String(m["faction"])), GameState.COL_GOOD)
						GameState.missions_changed.emit()
						release_mission_patrol(mg)
			"smuggler":
				var have := false
				for e2 in smugglers:
					have = have or e2["mission"] == m["id"]
				if not have:                 # contract targets ignore the NPC limit
					spawn_smuggler(m)
	# smugglers run for the gate; reaching it means they got away
	for e3 in smugglers.duplicate():
		var sm = e3["ship"]
		if not _alive(sm):
			smugglers.erase(e3)
			continue
		var g = view.gates.get(int(e3["gate"]))
		if g != null and sm.position.distance_to(g.position) < 6000.0 and not sm.in_warp():
			smugglers.erase(e3)
			view.spawn_fx(Fx.flash(sm.position, Color(0.75, 0.45, 1.0), sm.radius * 4.0))
			_despawn(sm)
			for m2 in GameState.missions.duplicate():
				if m2["id"] == e3["mission"]:
					GameState.fail_mission(m2, "the smuggler reached the gate and jumped out")
		elif _idle(sm):
			go(sm, String(e3["gate_id"]))


## Package 39a: thieves after the ballot cores – in a system on the way (not Landfall) they may strike once,
## a little while after the pilot came in.
func _ballot_thieves() -> void:
	var pl = view.player
	if pl == null or not is_instance_valid(pl) or pl.is_docked() or pl.in_warp():
		return
	for m in GameState.missions:
		if not m.get("ballot", false) or int(m["target_system"]) == sid:
			continue
		var amb: Dictionary = m.get("amb", {})
		var key := str(sid)
		if not amb.has(key):
			amb[key] = GameState.play_time + randf_range(15.0, 40.0) if randf() < Missions.BALLOT_AMBUSH else -1.0
			m["amb"] = amb
		if float(amb[key]) < 0.0 or GameState.play_time < float(amb[key]):
			continue
		amb[key] = -1.0
		var n := randi_range(2, 3)
		for i in n:
			var p: Ship = view.spawn_npc(view._pirate_preset(), pl.position + Vector2.from_angle(randf() * TAU) * randf_range(5000.0, 8000.0))
			p.home = pl.position
			p.set_order({"type": "attack", "target": pl})
			view.spawn_fx(Fx.flash(p.position, Color(1.0, 0.4, 0.3), p.radius * 3.0))
		GameState.log_msg("Ballot thieves! %d ships drop out of warp – they want the ballot cores." % n, GameState.COL_WARN)
		GameState.news.radio("Pirates try to seize ballots bound for The Vote!", sid, pl.position)


## The unregistered hauler of an intercept contract: appears somewhere out of sight and runs for the
## gate farthest from it.
func spawn_smuggler(m: Dictionary) -> Ship:
	var L: Dictionary = view.layout
	var spots: Array = []
	for f in L["fields"]:
		spots.append(f["pos"])
	for an in L["anomalies"]:
		spots.append(an["pos"])
	if spots.is_empty():
		spots.append(Vector2.from_angle(randf() * TAU) * 800000.0 * Universe.SCALE)
	var pos: Vector2 = spots[randi() % spots.size()] + Vector2.from_angle(randf() * TAU) * 5000.0
	var gate := {}
	var far := -1.0
	for g in L["gates"]:
		var d := (g["pos"] as Vector2).distance_to(pos)
		if d > far:
			far = d
			gate = g
	var sm: Ship = view.spawn_npc("civ_freighter", pos, "pirate", "hollow_crown")
	sm.fit.ship_name = "Unregistered hauler »%s«" % ["Quiet Lark", "Dusty Rose", "Low Tide", "Black Sparrow", "Ninth Hour"][randi() % 5]
	sm.fit.stance = "passive"
	sm.bounty = 0
	sm.smuggler_mission = String(m["id"])
	smugglers.append({"ship": sm, "mission": m["id"], "gate": int(gate.get("to", -1)), "gate_id": String(gate.get("id", "star"))})
	if not gate.is_empty():
		go(sm, String(gate["id"]))
	GameState.news.radio("Customs alert: an unregistered hauler is running for %s." % String(gate.get("name", "a gate")), sid)
	GameState.log_msg("Intercept: the smuggler %s is in the system, heading for %s!" % [sm.display_name(), String(gate.get("name", "a gate"))], GameState.COL_WARN)
	return sm


## Pirates strike at an escorted convoy.
func ambush(e: Dictionary) -> void:
	var lead = e.get("leader")
	if not _alive(lead):
		return
	var n := randi_range(2, 3)
	for i in n:
		var p: Ship = view.spawn_npc(view._pirate_preset(), lead.position + Vector2.from_angle(randf() * TAU) * randf_range(4000.0, 7000.0))
		p.home = lead.position
		p.set_order({"type": "attack", "target": lead})
		view.spawn_fx(Fx.flash(p.position, Color(1.0, 0.4, 0.3), p.radius * 3.0))
	GameState.news.radio("Pirates ambush the convoy near %s!" % view.landmark(lead.position), sid, lead.position)
	GameState.log_msg("Ambush! %d pirates attack the convoy you are escorting." % n, GameState.COL_BAD)


const GATHER_RANGE := 1000.0       # the pilot must come this close to the assembled convoy …
const GATHER_TIME := 3.0           # … and stay this long before it sets off
const GATHER_FOLLOW_RANGE := 8000.0  # or follow one of its ships and be at least this close


## A gathering escort convoy sets off once the pilot has been close for a few seconds.
func _check_gather(e: Dictionary, leader: Ship) -> void:
	var pl = view.player
	if pl == null or not is_instance_valid(pl) or pl.is_docked() or leader.is_docked():
		e["gather_t"] = 0.0
		return
	var with_it: bool = pl.position.distance_to(leader.position) <= GATHER_RANGE
	if String(pl.order.get("type", "")) == "follow" and pl.order.get("node") in e["ships"] and pl.position.distance_to(leader.position) <= GATHER_FOLLOW_RANGE:
		with_it = true               # following the convoy is enough
	if not with_it:
		e["gather_t"] = 0.0
		return
	e["gather_t"] = float(e["gather_t"]) + 0.5
	if float(e["gather_t"]) < GATHER_TIME:
		return
	depart_gathered(e)


func depart_gathered(e: Dictionary) -> void:
	e["gather"] = false
	e["c"]["gathering"] = false
	GameState.news.radio("Convoy departing – stay close!", sid)
	GameState.log_msg("%s sets off for %s – stay with it." % [ConvoySimScript.label(e["c"]), Universe.systems[int(e["c"]["dst"])]["name"]], GameState.COL_GOOD)
	_plan_ambush(e)
	_order_convoy(e)


## Pirates may pull the escorted convoy out of warp somewhere on its way through this system.
func _plan_ambush(e: Dictionary) -> void:
	var c: Dictionary = e["c"]
	var sec := float(Universe.systems[sid]["security"])
	var chance := (0.3 if int(c["src"]) == sid else 0.4) + (1.0 - sec) * 0.45
	if randf() < chance or c.get("force_ambush", false):
		e["pull_at"] = randf_range(0.3, 0.7)


## Pirates lying in wait at the gate through which the escorted convoy arrives.
func _gate_ambush(e: Dictionary, ships: Array, pos: Vector2) -> void:
	var sec := float(Universe.systems[sid]["security"])
	if randf() > 0.25 + (1.0 - sec) * 0.4 and not e["c"].get("force_ambush", false):
		return
	e["gate_ambush"] = true
	var n := randi_range(2, 4)
	for i in n:
		var p: Ship = view.spawn_npc(view._pirate_preset(), pos + Vector2.from_angle(randf() * TAU) * randf_range(3500.0, 6000.0))
		p.home = pos
		if not ships.is_empty():
			p.set_order({"type": "attack", "target": ships[randi() % ships.size()]})
	GameState.news.radio("Pirates were waiting at the gate – the convoy is under attack!", sid, pos)
	GameState.log_msg("Ambush at the gate! %d pirates were lying in wait for the convoy." % n, GameState.COL_BAD)


## A planned interception: when the leader is far enough into its warp, the convoy – and everyone
## following it – is pulled out of warp and pirates close in.
func _check_interception(e: Dictionary, leader: Ship) -> void:
	if not e.has("pull_at") or not leader.in_warp():
		return
	if leader.warp_progress() < float(e["pull_at"]):
		return
	e.erase("pull_at")
	pull_out_of_warp(e, leader)


func pull_out_of_warp(e: Dictionary, leader: Ship) -> void:
	var dropped: Array = [leader]
	for n in view.ship_layer.get_children():
		if n is Ship and n != leader and n.in_warp() and (n.warp.get("follow") == leader or (n.warp.get("follow") != null and n.warp.get("follow") in e["ships"])):
			dropped.append(n)
	var k0 := 0
	for n2 in dropped:
		if n2 != leader:
			# whoever follows comes out right next to the convoy, however far apart the warps were
			k0 += 1
			n2.position = leader.position + Vector2.from_angle(k0 * 2.4) * (500.0 + k0 * 250.0)
		n2.drop_out_of_warp(15.0)
	var where: String = view.landmark(leader.position)
	var k := randi_range(3, 4)
	for i in k:
		var p: Ship = view.spawn_npc(view._pirate_preset(), leader.position + Vector2.from_angle(randf() * TAU) * randf_range(3000.0, 5000.0))
		p.home = leader.position
		p.set_order({"type": "attack", "target": dropped[randi() % dropped.size()]})
		view.spawn_fx(Fx.flash(p.position, Color(1.0, 0.4, 0.3), p.radius * 3.0))
	GameState.news.radio("Convoy pulled out of warp near %s – pirates closing in!" % where, sid, leader.position)
	var pl = view.player
	if pl != null and is_instance_valid(pl) and pl in dropped:
		GameState.log_msg("Interdicted! Pirates pulled the convoy – and you – out of warp. %d pirates attack." % k, GameState.COL_BAD)
	elif pl != null and is_instance_valid(pl):
		GameState.log_msg("Pirates pulled your convoy out of warp near %s!" % where, GameState.COL_BAD)


## Convoy id of a live convoy ship (-1 = none).
func convoy_of(s) -> int:
	for e in convoys.values():
		if s in e["ships"]:
			return int(e["c"]["id"])
	return -1


## Lead ship of the live convoy that `s` belongs to (null = none).
func convoy_leader(s):
	for e in convoys.values():
		if s in e["ships"] and _alive(e.get("leader")):
			return e["leader"]
	return null


const HOLD_NEAR := 2000.0        # "right next to it": the pilot need not follow
const HOLD_TIMEOUT := 120.0      # all clear but no pilot around: the convoy moves on after this


## Threat radius of a convoy: the best recon (sensor) range among its ships.
func convoy_recon(e: Dictionary) -> float:
	var r := 3000.0
	for s in e["ships"]:
		if _alive(s):
			r = maxf(r, float(s.fit.stats()["sensor_range"]))
	return r


## Live pirates within the convoy's recon range.
func convoy_threat(e: Dictionary) -> bool:
	var r := convoy_recon(e)
	for n in view.ship_layer.get_children():
		if not (n is Ship) or n.faction != "pirate" or n.dying or n.in_warp():
			continue
		for s in e["ships"]:
			if _alive(s) and s.position.distance_to(n.position) <= r:
				return true
	return false


## True when the pilot is with the convoy: following it (within the gather follow range) or right
## next to it.
func pilot_with(e: Dictionary, leader: Ship) -> bool:
	var pl = view.player
	if pl == null or not is_instance_valid(pl) or pl.is_docked() or pl.in_warp():
		return false
	var d: float = pl.position.distance_to(leader.position)
	if d <= HOLD_NEAR:
		return true
	return String(pl.order.get("type", "")) == "follow" and pl.order.get("node") in e["ships"] and d <= GATHER_FOLLOW_RANGE


## An escorted convoy under attack holds where it is – no fleeing, no warp – until no pirate is left
## within its recon range and the pilot is with it again (following or right next to it).
func _convoy_hold(e: Dictionary, leader: Ship) -> void:
	if leader.in_warp() or leader.is_docked():
		return
	var threat := convoy_threat(e)
	if not e.get("held", false):
		if not threat:
			return
		e["held"] = true
		e["held_t"] = 0.0
		leader.set_order({"type": "idle"})
		GameState.news.radio("Convoy holding position – pirates nearby!", sid, leader.position)
		return
	if threat:
		e["held_t"] = 0.0
		if String(leader.order.get("type", "")) in ["travel", "warp", "move"]:
			leader.set_order({"type": "idle"})
		return
	e["held_t"] = float(e.get("held_t", 0.0)) + 0.5
	if not pilot_with(e, leader) and float(e["held_t"]) < HOLD_TIMEOUT:
		return
	e["held"] = false
	GameState.news.radio("All clear – convoy resuming its course.", sid, leader.position)
	_order_convoy(e)


## The escorted convoy reports in the ticker when it starts aligning for its next warp.
func _announce_warp(e: Dictionary, leader: Ship) -> void:
	if String(leader.order.get("type", "")) != "warp":
		e["warp_said"] = ""
		return
	var t: Dictionary = leader.order.get("target", {})
	var where := String(t.get("name", "the next waypoint"))
	if e.get("warp_said", "") == where:
		return
	e["warp_said"] = where
	GameState.news.radio("Convoy aligning for warp to %s – stay close!" % where, sid)


# ---------------------------------------------------------------- Mission patrols (package 17)
# A patrol contract gets its own patrol group: it starts at the station (rolling out of its bays)
# or at a named place, waits there for the pilot – following it, or 3 s within 1,000 km – and then
# flies its rounds. Marked green with a PATROL LEAD; the pilot may follow it, also in warp.

func spawn_mission_patrol(m: Dictionary) -> Dictionary:
	var gov := String(m["faction"])
	var meet: Dictionary = m.get("meet", {})
	var mid := String(meet.get("id", ""))
	var st = view.stations.get(mid)
	var gp := Vector2.ZERO
	var g := {"gov": gov, "ships": [], "wps": _waypoints(), "wp": 0, "dwell": 0.0, "target": {}, "mission": m["id"],
		"gather": true, "gather_t": 0.0}
	var presets := _patrol_presets()
	if presets.size() < 2:
		presets.append("patrol_light")
	if st != null and is_instance_valid(st):
		var dir: Vector2 = (-st.position).normalized() if st.position.length() > 1.0 else Vector2.RIGHT
		gp = st.position + dir * (float(st.radius) + 2500.0)
	else:
		var wt := Universe.warp_target(sid, mid)
		gp = (wt.get("pos", Vector2.ZERO) as Vector2) + Vector2.from_angle(randf() * TAU) * 2500.0
	g["gather_pos"] = gp
	for i in presets.size():
		var hull_name: String = GameData.hulls[GameData.presets[presets[i]]["hull"]]["name"]
		var nm := "%s %s %s" % [FactionData.FACTIONS[gov]["pilot"] if FactionData.FACTIONS.has(gov) else "Patrol", hull_name, _reg()]
		var s9: Ship
		if st != null and is_instance_valid(st):
			s9 = _spawn_docked(presets[i], mid, "patrol", gov, nm, true)
		else:
			s9 = _spawn(presets[i], gp + Vector2.from_angle(i * 2.1) * (300.0 + i * 250.0), "patrol", gov, nm)
			view.spawn_fx(Fx.flash(s9.position, Color(0.75, 0.45, 1.0), s9.radius * 4.0))
		g["ships"].append(s9)
	patrols.append(g)
	_mark_group(g, g["ships"], g["ships"][0])
	return g


func _mark_group(g: Dictionary, ships: Array, leader) -> void:
	for s9 in ships:
		if _alive(s9):
			s9.escort_mark = g.has("mission")
			s9.escort_kind = "patrol"
			s9.convoy_lead = s9 == leader


func _check_patrol_gather(g: Dictionary, leader: Ship) -> void:
	var pl = view.player
	if pl == null or not is_instance_valid(pl) or pl.is_docked() or leader.is_docked():
		g["gather_t"] = 0.0
		return
	var with_it: bool = pl.position.distance_to(leader.position) <= GATHER_RANGE
	if String(pl.order.get("type", "")) == "follow" and pl.order.get("node") in g["ships"] and pl.position.distance_to(leader.position) <= GATHER_FOLLOW_RANGE:
		with_it = true
	if not with_it:
		g["gather_t"] = 0.0
		return
	g["gather_t"] = float(g["gather_t"]) + 0.5
	if float(g["gather_t"]) < GATHER_TIME:
		return
	g["gather"] = false
	g["on_beat"] = false
	GameState.news.radio("Patrol departing – stay close!", sid)
	GameState.log_msg("The %s patrol sets off on its rounds – stay with it." % FactionData.short_of(String(g["gov"])), GameState.COL_GOOD)
	_next_waypoint(g, leader)


## The contract is done: the group drops its markers and leaves after a while.
func release_mission_patrol(g: Dictionary) -> void:
	g.erase("mission")
	g["leave_at"] = GameState.play_time + 120.0
	for s9 in g["ships"]:
		if _alive(s9):
			s9.escort_mark = false
			s9.convoy_lead = false


## Lead ship of the group (live convoy or mission patrol) that `s` belongs to (null = none).
func group_leader(s):
	var c = convoy_leader(s)
	if c != null:
		return c
	for g in patrols:
		if g.has("mission") and s in g["ships"] and not (g["ships"] as Array).is_empty() and _alive(g["ships"][0]):
			return g["ships"][0]
	return null
