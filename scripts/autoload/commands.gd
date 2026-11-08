extends Node
const PilotArtX = preload("res://scripts/core/pilot_art.gd")
const PilotDataX = preload("res://data/pilot.gd")
const SkillDataX = preload("res://data/skills.gd")
## Command bus: the ONLY way player input changes the game state.
##
## Every player action is a plain Dictionary {"type": ..., args...} that contains only
## ids, numbers and strings (no node references), so it can be saved, replayed or sent
## over the network later. UI and input code never touch GameState directly for actions –
## they call Commands.execute(cmd).
##
## Single-player: commands run locally. Multiplayer (roadmap phase 1): the client sends the
## same dictionaries to the server, which validates and executes them here.
##
## World commands (move, attack, goto, course, undock) are carried out by the active
## SystemView, registered as `world` by main.gd.

signal executed(cmd: Dictionary, error: String)

const FactionData = preload("res://data/factions.gd")
const FUEL_PRICE := 5.0       # Pyre Fuel Syndicate, per fuel unit
const REPAIR_PRICE := 2.0     # Mendex Nanorepair, per hit point
const MODULE_BUYBACK := 0.6   # outfitter pays 60 % of the list price

var world = null              # SystemView of the current system (or null)
## Debug commands ("debug_*") are only accepted when cheats are enabled – on by default in
## debug builds (running from the editor), off in exported release builds.
var cheats_enabled := OS.is_debug_build()
var god_mode := false         # player ship takes no damage
var history: Array = []       # last commands (debugging / replay)


## Executes a command. Returns "" on success, otherwise the reason (also logged).
## Package 28a: purchases ring, sales too, a refused order of the interface buzzes.
const CrewData = preload("res://data/crew.gd")
const CrewCore = preload("res://scripts/core/crew.gd")
const WingData = preload("res://data/wingmen.gd")
const BUY_CMDS := ["market_buy", "module_buy", "module_buy_fit", "ship_buy", "drone_buy", "refuel", "repair", "crew_hire", "wing_hire", "wing_extend", "platform_rebuy"]
const SELL_CMDS := ["market_sell", "module_sell", "ship_sell", "drone_sell"]
const QUIET_CMDS := ["key_steer", "move", "orbit", "keep_range", "approach"]


func _command_sound(t: String, err: String) -> void:
	if t.begins_with("debug_") or t in QUIET_CMDS:
		return
	if err != "":
		Audio.play("ui_error", "refused: " + t)
	elif t in BUY_CMDS:
		Audio.play("buy", t)
	elif t in SELL_CMDS:
		Audio.play("sell", t)


func execute(cmd: Dictionary) -> String:
	var t: String = cmd.get("type", "")
	var handler := "_c_" + t
	var err := ""
	if t == "" or not has_method(handler):
		err = "Unknown command '%s'" % t
	elif t.begins_with("debug_") and not cheats_enabled:
		err = "Debug commands are disabled."
	else:
		err = call(handler, cmd)
	_command_sound(t, err)
	history.append(cmd)
	if history.size() > 50:
		history.pop_front()
	if err != "":
		GameState.log_msg(err, GameState.COL_WARN)
	executed.emit(cmd, err)
	return err


# ---------------------------------------------------------------- Helpers

func _fit() -> ShipFitting:
	return GameState.active()


## Station the active ship is docked at, or {}.
func docked_station() -> Dictionary:
	var f := _fit()
	if f == null or f.docked_at == "":
		return {}
	return Universe.find_station(f.system_id, f.docked_at)


## Faction of the docked station ("" = free port) – prices follow your standing with it.
func docked_faction() -> String:
	return String(docked_station().get("faction", ""))


func _need_dock() -> String:
	return "" if not docked_station().is_empty() else "You must be docked at a station."


## Docked at a station whose services work (raided stations are offline, package 15).
func _need_service() -> String:
	var e := _need_dock()
	if e != "":
		return e
	return GameState.stations.down_error(docked_station())


func _need_world() -> String:
	if world == null or not is_instance_valid(world) or world.player == null or not is_instance_valid(world.player):
		return "No ship in space."
	return ""


## Cost of a fuel or repair service for one ship.
func service_cost(mode: String, f: ShipFitting) -> int:
	var s := f.stats()
	var k := GameState.rep.price_factor(docked_faction(), "buy")
	if docked_faction() == "assembly":
		k *= GameState.senate.mod("service") / GameState.senate.mod("buy")     # package 39a: fuel and repair laws
	if mode == "fuel":
		return int((float(s["fuel_max"]) - f.fuel) * FUEL_PRICE * k)
	return int(((float(s["structure_max"]) - f.structure) + (float(s["armor_max"]) - f.armor)) * REPAIR_PRICE * k)


func _find_mission(list: Array, id: String) -> Dictionary:
	for m in list:
		if m["id"] == id:
			return m
	return {}


# ---------------------------------------------------------------- Flight (world)

## {"type":"move", "pos": Vector2}
func _c_move(c: Dictionary) -> String:
	var e := _need_world()
	if e != "":
		return e
	world.order_move(c["pos"])
	return ""


## {"type":"key_steer", "x": float, "y": float} – keyboard flight (WASD): fly that way; (0, 0) stops a
## keyboard flight (an order given otherwise is left alone).
func _c_key_steer(c: Dictionary) -> String:
	var e := _need_world()
	if e != "":
		return e
	var p = world.player
	var d := Vector2(float(c.get("x", 0.0)), float(c.get("y", 0.0)))
	if d != Vector2.ZERO:
		p.set_order({"type": "move", "pos": p.position + d.normalized() * 6000.0, "keys": true})
	elif p.order.get("keys", false):
		p.set_order({"type": "idle"})
	return ""


## {"type":"attack", "target": <ship uid>}
func _c_attack(c: Dictionary) -> String:
	var e := _need_world()
	if e != "":
		return e
	return world.order_attack(int(c["target"]))


## {"type":"goto", "id": <warp target / object id>} – warp or approach, then the
## object's natural action (dock, jump, mine, analyse, salvage).
func _c_goto(c: Dictionary) -> String:
	var e := _need_world()
	if e != "":
		return e
	return world.order_goto(String(c["id"]))


## {"type":"approach", "id": <object id>}
func _c_approach(c: Dictionary) -> String:
	var e := _need_world()
	return e if e != "" else world.order_relative("approach", String(c["id"]), 0.0)


## {"type":"orbit", "id": <object id>, "range": km}
func _c_orbit(c: Dictionary) -> String:
	var e := _need_world()
	return e if e != "" else world.order_relative("orbit", String(c["id"]), clampf(float(c.get("range", 500.0)), 50.0, 20000.0))


## {"type":"keep_range", "id": <object id>, "range": km}
func _c_keep_range(c: Dictionary) -> String:
	var e := _need_world()
	return e if e != "" else world.order_relative("keep", String(c["id"]), clampf(float(c.get("range", 1000.0)), 50.0, 50000.0))


## {"type":"follow", "id": <ship id>} – stay with a ship you protect, also in warp and through gates.
func _c_follow(c: Dictionary) -> String:
	var e := _need_world()
	return e if e != "" else world.order_follow(String(c["id"]))


## {"type":"warp_to", "id": <object id>}
func _c_warp_to(c: Dictionary) -> String:
	var e := _need_world()
	return e if e != "" else world.order_warp(String(c["id"]))


## {"type":"dock", "id": <station id>} – warp/approach and dock.
func _c_dock(c: Dictionary) -> String:
	var e := _need_world()
	if e != "":
		return e
	var n = world.find_object(String(c["id"]))
	if n == null or n is Ship or not n.kind in ["station", "haven"]:
		return "That is not a station."
	return world.order_goto(String(c["id"]))


## {"type":"jump", "id": <gate id>} – fly to the gate and jump.
func _c_jump(c: Dictionary) -> String:
	var e := _need_world()
	if e != "":
		return e
	var n = world.find_object(String(c["id"]))
	if n == null or n is Ship or n.kind != "gate":
		return "That is not a gate."
	return world.order_goto(String(c["id"]))


## {"type":"lock", "id": <object id>} – start locking a target (ships, asteroids, wrecks, anomalies).
func _c_lock(c: Dictionary) -> String:
	var e := _need_world()
	return e if e != "" else world.order_lock(String(c["id"]))


## {"type":"unlock", "id": <object id>}
func _c_unlock(c: Dictionary) -> String:
	var e := _need_world()
	if e != "":
		return e
	world.player.remove_lock(String(c["id"]))
	return ""


## {"type":"target", "id": <object id>} – make a locked target the active one (modules act on it).
func _c_target(c: Dictionary) -> String:
	var e := _need_world()
	if e != "":
		return e
	var id := String(c["id"])
	if world.player.lock_index(id) < 0:
		return "That target is not locked."
	world.player.active_lock = id
	GameState.log_msg("Active target: %s" % Ship.node_name(world.player.locks[world.player.lock_index(id)]["node"]))
	return ""


## {"type":"activate", "slot": String} / {"type":"deactivate", ...} / {"type":"toggle_module", ...}
func _c_activate(c: Dictionary) -> String:
	var e := _need_world()
	return e if e != "" else world.player.set_module_active(String(c["slot"]), true)


func _c_deactivate(c: Dictionary) -> String:
	var e := _need_world()
	return e if e != "" else world.player.set_module_active(String(c["slot"]), false)


# ---------------------------------------------------------------- Drones (package 23)

const DRONE_PRICE := 2400
const DRONE_ROLES := {"combat": ["defend", "attack", "fire_at_will", "rest"], "mining": ["auto", "target", "rest"],
	"repair": ["auto", "target", "allies", "self", "rest"]}


## {"type":"drone_launch", "count"?: n} – launch drones (as many as the ship controls).
func _c_drone_launch(c: Dictionary) -> String:
	var e := _need_world()
	return e if e != "" else world.launch_drones(world.player, int(c.get("count", -1)))


## {"type":"drone_recall"} – all drones back into the hangar.
func _c_drone_recall(_c: Dictionary) -> String:
	var e := _need_world()
	return e if e != "" else world.recall_drones(world.player)


## {"type":"drone_role", "role": combat|mining|repair}
func _c_drone_role(c: Dictionary) -> String:
	var f := _fit()
	var r := String(c.get("role", ""))
	if f == null or not DRONE_ROLES.has(r):
		return "Unknown drone role."
	f.drone_role = r
	return ""


## {"type":"drone_mode", "mode": …} – behaviour for the current role.
func _c_drone_mode(c: Dictionary) -> String:
	var f := _fit()
	var m := String(c.get("mode", ""))
	if f == null or not m in DRONE_ROLES[f.drone_role]:
		return "Unknown behaviour for %s drones." % f.drone_role
	f.drone_modes[f.drone_role] = m
	return ""


## Price of a new drone here (standing with the station's faction).
func drone_price() -> int:
	return GameState.rep.buy_price(DRONE_PRICE, docked_faction())


## What the drone service pays for a used drone (by its fuel and hull).
func drone_value(r: Dictionary) -> int:
	return int(DRONE_PRICE * 0.5 * float(r.get("fuel", 0.0)) * (0.5 + 0.5 * float(r.get("hp", 1.0))))


## {"type":"drone_buy", "amount": n} – new drones into the hangar (drone service).
func _c_drone_buy(c: Dictionary) -> String:
	var e := _need_service()
	if e != "":
		return e
	var f := _fit()
	var room := int(f.stats()["drone_storage"]) - f.drones.size()
	if room <= 0:
		return "The drone hangar is full (%d)." % int(f.stats()["drone_storage"])
	var n := mini(int(c.get("amount", 1)), room)
	var price := drone_price()
	n = mini(n, int(floor(float(GameState.credits) / float(price))))
	if n <= 0:
		return "Not enough credits."
	GameState.spend(n * price)
	for i in n:
		f.drones.append({"fuel": 1.0, "hp": 1.0, "out": false})
	return ""


## {"type":"drone_sell", "index": i} – sell a drone from the hangar.
func _c_drone_sell(c: Dictionary) -> String:
	var e := _need_service()
	if e != "":
		return e
	var f := _fit()
	var i := int(c.get("index", -1))
	if i < 0 or i >= f.drones.size():
		return "No such drone."
	GameState.add_credits(drone_value(f.drones[i]))
	f.drones.remove_at(i)
	return ""


## {"type":"drone_repair"} – repairs the hulls of all drones in the hangar (fuel cannot be refilled).
func _c_drone_repair(_c: Dictionary) -> String:
	var e := _need_service()
	if e != "":
		return e
	var f := _fit()
	var cost := drone_repair_cost(f)
	if cost <= 0:
		return "All drones are intact."
	if not GameState.spend(cost):
		return "Not enough credits."
	for r in f.drones:
		r["hp"] = 1.0
	return ""


func drone_repair_cost(f: ShipFitting) -> int:
	var c := 0.0
	for r in f.drones:
		c += (1.0 - float(r.get("hp", 1.0))) * DRONE_PRICE * 0.3
	return int(ceil(c / 10.0)) * 10


## {"type":"set_priority", "slot": key, "group": 1–4} – power priority of a module (package 21).
func _c_set_priority(c: Dictionary) -> String:
	var f := _fit()
	if f == null:
		return "No active ship."
	var key := String(c["slot"])
	if f.module_data(key).is_empty():
		return "No module in that slot."
	return f.set_priority(key, int(c["group"]))


## {"type":"mine_config", "slot": s, "mine"?: mine id, "fuse"?: seconds} – mine launcher settings.
func _c_mine_config(c: Dictionary) -> String:
	var e := _need_world()
	if e != "":
		return e
	var slot := String(c["slot"])
	var ch: Dictionary = world.player.mine_choice.get(slot, {"type": "", "fuse": 10})
	if c.has("mine"):
		if not GameData.MINES.has(String(c["mine"])):
			return "Unknown mine type."
		ch["type"] = String(c["mine"])
	if c.has("fuse"):
		ch["fuse"] = clampi(int(c["fuse"]), 1, 300)
	world.player.mine_choice[slot] = ch
	GameState.log_msg("Mine launcher: %s%s." % [GameData.MINES.get(String(ch["type"]), {}).get("name", "first mine in the hold"), (", timer %d s" % int(ch["fuse"]))], GameState.COL_INFO)
	return ""


func _c_toggle_module(c: Dictionary) -> String:
	var e := _need_world()
	if e != "":
		return e
	var slot := String(c["slot"])
	var p: Ship = world.player
	# multi-focus (package 22): a running module with another target switches to the active one
	if p.module_on.get(slot, false) and p.locked_node() != null and String(p.module_target.get(slot, "")) != p.active_lock:
		var e2 := p.find_module(slot)
		if not e2.is_empty() and e2["kind"] in ["weapon", "tool"] and p.module_target_error(e2, p.locked_node()) == "":
			return p.retarget(slot)
	return p.set_module_active(slot, not bool(p.module_on.get(slot, false)))


## {"type":"course", "to": <system id>} – plot a hyperspace route and start travelling.
func _c_course(c: Dictionary) -> String:
	var f := _fit()
	var to := int(c["to"])
	if f == null:
		return "No active ship."
	if f.system_id == to:
		return "You are already in %s." % Universe.systems[to]["name"]
	if f.transit_kind == "jump":
		return "%s is currently in hyperspace." % f.ship_name
	var path := Universe.find_path(f.system_id, to, int(f.stats()["drive_class"]))
	if path.is_empty():
		return "%s: no reachable route." % f.ship_name
	f.route = path
	GameState.log_msg("%s: course set to %s (%d jumps)." % [f.ship_name, Universe.systems[to]["name"], path.size()])
	if world != null and is_instance_valid(world):
		world.apply_route()
	return ""


## {"type":"stance", "stance": "aggressive" | "defensive" | "passive"}
func _c_stance(c: Dictionary) -> String:
	var f := _fit()
	var st: String = c.get("stance", "")
	if f == null or not st in ["aggressive", "defensive", "passive"]:
		return "Invalid stance."
	f.stance = st
	GameState.log_msg("Stance: %s" % st.capitalize())
	return ""


## {"type":"undock"}
func _c_undock(_c: Dictionary) -> String:
	var e := _need_dock()
	if e != "":
		return e
	var te := GameState.hull_tree_error(String(_fit().hull_id))   # 0.5.30.2: bought freely, flown with the tile
	if te != "":
		return "The %s cannot undock yet – %s" % [_fit().hull()["name"], te]
	var ce := GameState.crew_error(_fit())                           # package 31: the required crew
	if ce != "":
		return ce
	if world != null and is_instance_valid(world) and world.player != null and is_instance_valid(world.player):
		world.player.undock()
	else:
		_fit().docked_at = ""
	return ""


# ---------------------------------------------------------------- Pilot & ships

## {"type":"rename_pilot", "name": String}
func _c_rename_pilot(c: Dictionary) -> String:
	var n := String(c.get("name", "")).strip_edges()
	if n == "" or n.length() > 24:
		return "Pilot names need 1–24 characters."
	GameState.pilot_name = n
	GameState.pilot["name"] = n
	return ""


## {"type":"pilot_look", "look": Dictionary} – package 28: new looks at a station's image studio (the price
## follows the standing); the attributes cannot be changed.
func _c_pilot_look(c: Dictionary) -> String:
	var e := _need_service()
	if e != "":
		return e
	var only: Array = GameData.station_types.get(String(docked_station().get("type", "")), {}).get("services", [])
	if not only.is_empty() and not "look" in only:
		return "There is no image studio here."
	var price := look_price()
	if not GameState.spend(price):
		return "Not enough credits (%s)." % GameData.fmt_credits(price)
	GameState.pilot["look"] = PilotArtX.clean(c.get("look", {}))
	GameState.log_msg("New looks – %s paid to the image studio." % GameData.fmt_credits(price), GameState.COL_GOOD)
	return ""


func look_price() -> int:
	return GameState.rep.buy_price(PilotDataX.LOOK_PRICE, docked_faction())


## {"type":"tree_unlock", "tile": id} – package 30: opens a skill tree tile whose achievements are met.
func _c_tree_unlock(c: Dictionary) -> String:
	return GameState.tree_unlock(String(c.get("tile", "")))


## {"type":"perk_take", "perk": id} – package 30: spends a perk point.
func _c_perk_take(c: Dictionary) -> String:
	return GameState.perk_take(String(c.get("perk", "")))


## {"type":"debug_tree", "all"?: bool, "tile"?: id, "reset"?: bool, "perk_points"?: int}
func _c_debug_tree(c: Dictionary) -> String:
	if c.has("all"):
		GameState.pilot["tree_all"] = bool(c["all"])
	if c.has("tile"):
		var t := String(c["tile"])
		if not t in GameState.pilot["tree"]:
			GameState.pilot["tree"].append(t)
	if c.get("reset", false):
		GameState.pilot["tree"] = []
		GameState.pilot["tree_all"] = false
	if c.has("perk_points"):
		GameState.pilot["perk_points"] = int(GameState.pilot.get("perk_points", 0)) + int(c["perk_points"])
	GameState.skills_changed.emit()
	return ""


## {"type":"debug_skill", "skill": id, "level"?: int, "xp"?: float} – set a level or add experience.
func _c_debug_skill(c: Dictionary) -> String:
	var id := String(c.get("skill", ""))
	if not GameState.pilot.get("skills", {}).has(id):
		return "Unknown skill."
	var sk: Dictionary = GameState.pilot["skills"][id]
	if c.has("level"):
		sk["lvl"] = clampi(int(c["level"]), 0, SkillDataX.MAX_LEVEL)
		sk["xp"] = 0.0
		for f in GameState.fleet:
			f.mark_dirty()
	if c.has("xp"):
		GameState.skill_xp(id, float(c["xp"]))
	GameState.skills_changed.emit()
	return ""


## {"type":"debug_pilot", "name"?, "callsign"?, "look"?, "attrs"?, "random"?} – package 28: set anything about
## the pilot, attributes even beyond the starting limits (1–20).
func _c_debug_pilot(c: Dictionary) -> String:
	var p: Dictionary = GameState.pilot.duplicate(true)
	if c.get("random", false):
		p["look"] = PilotArtX.random_look()
		var names := ["Vega", "Orin", "Kesh", "Maru", "Tavi", "Ilka", "Doran", "Sable", "Juno", "Rhett"]
		p["name"] = names[randi() % names.size()]
		var a: Dictionary = PilotDataX.base_attrs()
		var ids: Array = a.keys()
		for k in PilotDataX.FREE:
			var id: String = ids[randi() % ids.size()]
			if int(a[id]) < PilotDataX.MAX:
				a[id] = int(a[id]) + 1
		p["attrs"] = a
	if c.has("name") and String(c["name"]).strip_edges() != "":
		p["name"] = String(c["name"]).strip_edges().left(24)
	if c.has("callsign"):
		p["callsign"] = String(c["callsign"]).strip_edges().left(16)
	if c.has("look"):
		p["look"] = PilotArtX.clean(c["look"])
	if c.has("attrs"):
		for id in c["attrs"]:
			p["attrs"][id] = clampi(int(c["attrs"][id]), 1, 20)
	GameState.set_pilot(p)
	GameState.log_msg("Debug: pilot %s updated." % GameState.pilot_title(), GameState.COL_GOOD)
	return ""


## {"type":"rename_ship", "uid": int, "name": String}
func _c_rename_ship(c: Dictionary) -> String:
	var f := GameState.get_fit(int(c["uid"]))
	var n := String(c.get("name", "")).strip_edges()
	if f == null:
		return "Unknown ship."
	if n == "" or n.length() > 40:
		return "Ship names need 1–40 characters."
	f.ship_name = n
	GameState.fleet_changed.emit()
	return ""


## {"type":"board", "uid": int}
func _c_board(c: Dictionary) -> String:
	return "" if GameState.set_active(int(c["uid"])) else "You can only board ships in the hangar you are docked at."


## {"type":"ship_buy", "hull": String, "fitted": bool}
func _c_ship_buy(c: Dictionary) -> String:
	var e := _need_service()
	if e != "":
		return e
	var st := docked_station()
	var hid: String = c["hull"]
	if not hid in st["shipyard"]:
		return "This shipyard does not sell that hull."
	var why := GameState.hull_standing_error(hid)
	if why != "":
		return why
	var with_fit := bool(c.get("fitted", false))
	var preset := "std_" + hid
	if with_fit and not GameData.presets.has(preset):
		return "No standard fit available."
	var price := GameData.preset_price(preset) if with_fit else int(GameData.hulls[hid]["price"])
	price = int(round(GameState.rep.buy_price(price, docked_faction()) * GameState.senate.hull_mult(hid, docked_faction())))
	if not GameState.spend(price):
		return "Not enough credits."
	var f: ShipFitting
	if with_fit:
		f = GameState.create_from_preset(preset, "player")
	else:
		f = GameState.create_fit(hid, {}, "player")
	var count := 1
	for o in GameState.fleet:
		if o.hull_id == hid:
			count += 1
	f.ship_name = "%s %d" % [GameData.hulls[hid]["name"], count]
	f.system_id = GameState.current_system
	f.docked_at = st["id"]
	f.position = st["pos"]
	GameState.add_ship(f)
	GameState.crew_fill_required(f)                        # package 31: the required posts come with rookies
	GameState.log_msg("%s purchased – waiting in the hangar (Hangar → Board)." % f.ship_name, GameState.COL_GOOD)
	return ""


# ---------------------------------------------------------------- Fitting & cargo

## {"type":"fit_module", "slot": String, "module": String} – from station storage.
func _c_fit_module(c: Dictionary) -> String:
	var e := _need_service()
	if e != "":
		return e
	var f := _fit()
	var slot: String = c["slot"]
	var mid: String = c["module"]
	var why := f.can_fit(slot, mid)
	if why != "":
		return why
	if Missions.cabin_in_use(f, slot):
		return "Passengers are using this cabin – deliver them first."
	if not GameState.storage_remove(f.docked_at, mid):
		return "%s is not in station storage." % GameData.module_name(mid)
	var prev := f.set_module(slot, mid)
	if prev != "":
		GameState.storage_add(f.docked_at, prev)
	f.refill_docked()
	GameState.log_msg("%s fitted." % GameData.module_name(mid), GameState.COL_GOOD)
	return ""


## {"type":"unfit_module", "slot": String} – into station storage.
func _c_unfit_module(c: Dictionary) -> String:
	var e := _need_service()
	if e != "":
		return e
	var f := _fit()
	if Missions.cabin_in_use(f, String(c["slot"])):
		return "Passengers are using this cabin – deliver them first."
	var prev := f.set_module(String(c["slot"]), "")
	if prev == "":
		return "That slot is empty."
	GameState.storage_add(f.docked_at, prev)
	GameState.log_msg("%s removed." % GameData.module_name(prev))
	return ""


## {"type":"jettison", "item": String}
func _c_jettison(c: Dictionary) -> String:
	var f := _fit()
	var item: String = c["item"]
	if f == null or not f.cargo.has(item):
		return "Nothing to jettison."
	if item == "sealed_cargo":
		return "Sealed cargo cannot be jettisoned – abandon the contract instead."
	f.cargo.erase(item)
	GameState.log_msg("Jettisoned %s." % GameData.item_name(item), GameState.COL_WARN)
	return ""


# ---------------------------------------------------------------- Market & outfitter

## {"type":"market_buy", "item": String, "amount": int}
func _c_market_buy(c: Dictionary) -> String:
	var e := _need_service()
	if e != "":
		return e
	var st := docked_station()
	var f := _fit()
	var cid: String = c["item"]
	if not st["market"].has(cid) or int(st["market"][cid]["buy"]) < 0:
		return "Not on offer here."
	var price := maxi(int(round(GameState.rep.buy_price(int(st["market"][cid]["buy"]), docked_faction()) * (1.0 - GameState.skill_bonus("trading") * 0.5))), 1)
	var max_space := int(floor(f.free_for(cid) / GameData.item_volume(cid)))
	var max_money := int(floor(float(GameState.credits) / float(price)))
	var amount := mini(int(c.get("amount", 1)), mini(max_space, max_money))
	if amount <= 0:
		return "Purchase not possible (cargo space or credits)."
	GameState.spend(amount * price)
	f.add_cargo(cid, amount)
	GameState.skill_xp("trading", float(amount * price) / 500.0)      # package 29
	GameState.note_stat("markets", String(st["id"]))                    # package 30
	GameState.count_stat("turnover", float(amount * price))
	return ""


## {"type":"market_sell", "item": String, "amount": float (-1 = all)}
func _c_market_sell(c: Dictionary) -> String:
	var e := _need_service()
	if e != "":
		return e
	var st := docked_station()
	var f := _fit()
	var cid: String = c["item"]
	if not st["market"].has(cid) or not GameData.is_tradeable(cid):
		return "This station does not buy that."
	var have := float(f.cargo.get(cid, 0.0))
	var n := float(c.get("amount", -1.0))
	var amount := have if n < 0.0 else minf(n, have)
	if amount <= 0.0:
		return "Nothing to sell."
	f.remove_cargo(cid, amount)
	var earn := int(round(amount * GameState.rep.sell_price(float(st["market"][cid]["sell"]), docked_faction()) * (1.0 + GameState.skill_bonus("trading") * 0.5)))
	if GameState.has_perk("haggler") and String(GameData.commodities.get(cid, {}).get("category", "")) in ["ore", "refined"]:
		earn = int(round(earn * 1.05))                                  # package 30
	GameState.skill_xp("trading", float(earn) / 500.0)      # package 29
	GameState.note_stat("markets", String(st["id"]))
	earn = int(round(earn * (1.0 + f.crew_bonus("sell"))))             # package 31: quartermaster
	GameState.count_stat("turnover", float(earn))
	GameState.add_credits(earn)
	GameState.log_msg("Sold %.1f %s for %s." % [amount, GameData.item_name(cid), GameData.fmt_credits(earn)], GameState.COL_GOOD)
	GameState.crew_cut(earn)
	return ""


# ---------------------------------------------------------------- Crew (package 31)

## Where a member is: ["quarters", station_id, index] / ["ship", ShipFitting, slot] / [] – only at the docked station
## (its quarters and the ships in its hangar, the active ship included).
func _crew_find(mid: int) -> Array:
	var st := docked_station()
	if st.is_empty():
		return []
	var q: Array = GameState.quarters_of(String(st["id"]))
	for i in q.size():
		if int(q[i]["id"]) == mid:
			return ["quarters", String(st["id"]), i]
	for f in GameState.fleet:
		if f.docked_at == String(st["id"]) and f.system_id == _fit().system_id:
			for k in f.crew.size():
				if not (f.crew[k] as Dictionary).is_empty() and int(f.crew[k]["id"]) == mid:
					return ["ship", f, k]
	return []


func _crew_take(where: Array) -> Dictionary:
	if where[0] == "quarters":
		var q: Array = GameState.quarters_of(String(where[1]))
		var m: Dictionary = q[int(where[2])]
		q.remove_at(int(where[2]))
		return m
	return (where[1] as ShipFitting).set_crew(int(where[2]), {})


func _fleet_ship(uid: int) -> ShipFitting:
	for f in GameState.fleet:
		if f.uid == uid:
			return f
	return null


# ---------------------------------------------------------------- Wingmen (package 33)

## {"type":"wing_hire", "index": n, "minutes": 30|60|120} – a pilot from the bar of the docked station
func _c_wing_hire(c: Dictionary) -> String:
	var e := _need_service()
	if e != "":
		return e
	var he := GameState.wing_hire_error()
	if he != "":
		return he
	var pilots: Array = GameState.bar_pilots(docked_station())
	var i := int(c.get("index", -1))
	if i < 0 or i >= pilots.size():
		return "Nobody by that name at the bar."
	var minutes := int(c.get("minutes", 30))
	var w: Dictionary = pilots[i]
	if not GameState.spend(GameState.wing_price(w, minutes)):
		return "Not enough credits."
	pilots.remove_at(i)
	GameState.wing_hire(w, minutes)
	return ""


## {"type":"wing_extend", "id": n, "minutes": m} – at any bar
func _c_wing_extend(c: Dictionary) -> String:
	var e := _need_service()
	if e != "":
		return e
	var ct := GameState.wing_contract(int(c["id"]))
	if ct.is_empty():
		return "No such wingman."
	var minutes := int(c.get("minutes", 30))
	if not GameState.spend(GameState.wing_price(ct["w"], minutes)):
		return "Not enough credits."
	ct["until"] = float(ct["until"]) + float(minutes) * 60.0
	GameState.log_msg("%s's contract extended by %d minutes." % [ct["w"]["name"], minutes], GameState.COL_GOOD)
	GameState.wingmen_changed.emit()
	return ""


## {"type":"wing_dismiss", "id": n} – ends the contract now (no money back)
func _c_wing_dismiss(c: Dictionary) -> String:
	var ct := GameState.wing_contract(int(c["id"]))
	if ct.is_empty():
		return "No such wingman."
	ct["until"] = GameState.play_time
	GameState.wing_tick()
	return ""


## {"type":"wing_stance", "id": n (-1 = all), "stance": "aggressive"|"defensive"|"passive"}
func _c_wing_stance(c: Dictionary) -> String:
	var st := String(c.get("stance", "defensive"))
	if not WingData.STANCES.has(st):
		return "Unknown order."
	var n := 0
	for ct in GameState.wingmen:
		if int(c.get("id", -1)) < 0 or int(ct["w"]["id"]) == int(c["id"]):
			ct["stance"] = st
			n += 1
			if world != null and is_instance_valid(world) and world.wing_nodes.has(int(ct["w"]["id"])):
				var node = world.wing_nodes[int(ct["w"]["id"])]
				if is_instance_valid(node):
					node.fit.stance = st
					node.wing_focus = null
					if st == "passive":
						node.target = null
	var cit := _fit()
	if cit != null and int(c.get("id", -1)) in [-1, 0] and not cit.platform_ship.is_empty():
		cit.platform_stance = st
		n += 1
		if world != null and is_instance_valid(world) and world.wing_nodes.has(0) and is_instance_valid(world.wing_nodes[0]):
			world.wing_nodes[0].fit.stance = st
			world.wing_nodes[0].wing_focus = null
	if n == 0:
		return "No wingmen."
	GameState.wingmen_changed.emit()
	return ""


## {"type":"wing_attack"} – every wingman goes for the pilot's active locked target
func _c_wing_attack(_c: Dictionary) -> String:
	if GameState.wingmen.is_empty() and (world == null or not is_instance_valid(world) or not world.wing_nodes.has(0)):
		return "No wingmen."
	var e := _need_world()
	if e != "":
		return e
	var t = world.player.locked_node()
	if t == null or not is_instance_valid(t) or not (t is Ship) or t == world.player:
		return "Lock a ship first – the wingmen attack your active target."
	for ct in GameState.wingmen:
		if ct["stance"] == "passive":
			ct["stance"] = "defensive"
		var node = world.wing_nodes.get(int(ct["w"]["id"]))
		if node != null and is_instance_valid(node):
			node.fit.stance = ct["stance"]
			node.wing_focus = t
			node._retarget = 0.0
	if world.wing_nodes.has(0) and is_instance_valid(world.wing_nodes[0]):
		world.wing_nodes[0].wing_focus = t                # the platform ship too
	GameState.log_msg("Wingmen: attacking %s." % t.display_name(), GameState.COL_GOOD)
	GameState.wingmen_changed.emit()
	return ""


## {"type":"platform_load", "uid": n} – put a Hadrian S ship from this hangar onto the active Citadel's platform
func _c_platform_load(c: Dictionary) -> String:
	var e := _need_service()
	if e != "":
		return e
	var cit := _fit()
	if not cit.hull().get("hatches", {}).has("platform"):
		return "The active ship has no launch platform."
	if not cit.platform_ship.is_empty():
		return "The platform is taken – unload it first."
	var s := _fleet_ship(int(c["uid"]))
	if s == null or s == cit or s.docked_at != cit.docked_at:
		return "That ship is not in this hangar."
	var he := GameState.platform_hull_error(s.hull_id)
	if he != "":
		return he
	GameState.fleet.erase(s)
	s.docked_at = ""
	cit.platform_ship = s.to_dict()
	cit.platform_out = false
	GameState.log_msg("%s now stands on the platform of the %s." % [s.ship_name, cit.ship_name], GameState.COL_GOOD)
	GameState.codex.event("platform")
	GameState.fleet_changed.emit()
	return ""


## {"type":"platform_unload"} – the platform ship goes back into the hangar (to fit it, sell it …)
func _c_platform_unload(_c: Dictionary) -> String:
	var e := _need_service()
	if e != "":
		return e
	var cit := _fit()
	if cit.platform_ship.is_empty():
		return "Nothing on the platform."
	var s := ShipFitting.from_dict(cit.platform_ship)
	s.uid = 0
	s.system_id = cit.system_id
	s.docked_at = cit.docked_at
	s.position = cit.position
	cit.platform_ship = {}
	cit.platform_out = false
	GameState.add_ship(s)
	GameState.log_msg("%s is back in the hangar." % s.ship_name, GameState.COL_INFO)
	return ""


## {"type":"platform_launch"} / {"type":"platform_recall"} – in space
func _c_platform_launch(_c: Dictionary) -> String:
	var e := _need_world()
	if e != "":
		return e
	var cit := _fit()
	if cit.platform_ship.is_empty():
		return "Nothing on the platform – put a Hadrian S ship on it in the hangar." if cit.platform_lost.is_empty() else "The platform ship was destroyed – recall it at a station's hangar."
	if cit.platform_out:
		return "The platform ship is already out."
	if GameState.platform_pilot(cit).is_empty():
		return "No platform pilot aboard – a Co-Pilot with the perk Wingman flies it."
	cit.platform_out = true
	world.player.launch_platform()
	world.launch_platform_ship()
	return ""


func _c_platform_recall(_c: Dictionary) -> String:
	var e := _need_world()
	if e != "":
		return e
	var cit := _fit()
	if not cit.platform_out:
		return "The platform ship is aboard."
	world.recall_platform_ship()
	return ""


## {"type":"platform_rebuy"} – a destroyed platform ship comes back for 10 % of its value (docked)
func _c_platform_rebuy(_c: Dictionary) -> String:
	var e := _need_service()
	if e != "":
		return e
	var cit := _fit()
	if cit.platform_lost.is_empty():
		return "No platform ship to recall."
	var price := GameState.platform_recall_price(cit)
	if not GameState.spend(price):
		return "Not enough credits."
	var s := ShipFitting.from_dict(cit.platform_lost)
	s.refill()
	cit.platform_ship = s.to_dict()
	cit.platform_lost = {}
	GameState.log_msg("Aegis Mutual delivered a new %s to the platform for %s." % [s.ship_name, GameData.fmt_credits(price)], GameState.COL_GOOD)
	return ""


## {"type":"debug_wing", "level": "C", "minutes": 30} – a wingman joins at once (no bar, no price, no tile)
func _c_debug_wing(c: Dictionary) -> String:
	var w := GameState.new_wingman(String(c.get("level", "C")))
	GameState.wing_hire(w, int(c.get("minutes", 30)))
	return ""


## {"type":"loss_decide", "accept": bool} – package 31a: rebuild the lost ship or keep the beginner ship
func _c_loss_decide(c: Dictionary) -> String:
	return GameState.loss_decide(bool(c.get("accept", false)))


## {"type":"debug_lose_ship"} – the active ship is destroyed (escape pods, the rebuild offer)
## {"type":"debug_pods", "seconds": n} – every pod signal fades in n seconds
func _c_debug_lose_ship(_c: Dictionary) -> String:
	var f := _fit()
	if f == null:
		return "No ship."
	if world != null and is_instance_valid(world) and world.player != null and is_instance_valid(world.player) and world.player.fit == f and f.docked_at == "":
		var god := god_mode
		god_mode = false                                  # review K5: works in god mode too
		world.player.take_damage(1e9, "kinetic", null)
		god_mode = god
		return ""
	GameState.on_player_ship_lost(f)
	return ""


func _c_debug_pods(c: Dictionary) -> String:
	for pod in GameState.pods:
		for e in pod["crew"]:
			e["until"] = GameState.play_time + float(c.get("seconds", 10.0))
	return ""


## {"type":"crew_hire", "index": n, "ship": uid (optional), "slot": n (optional)} – at the bar of the docked station;
## into the slot of a ship here, or into the station's crew quarters.
func _c_crew_hire(c: Dictionary) -> String:
	var e := _need_service()
	if e != "":
		return e
	var st := docked_station()
	var offers: Array = GameState.bar_offers(st)
	var i := int(c.get("index", -1))
	if i < 0 or i >= offers.size():
		return "Nobody by that name at the bar."
	var o: Dictionary = offers[i]
	if not GameState.spend(int(o["price"])):
		return "Not enough credits."
	offers.remove_at(i)
	var m: Dictionary = o["m"]
	GameState.quarters_of(String(st["id"])).append(m)
	GameState.codex.event("crew")
	GameState.log_msg("%s (%s, quality %s) hired for %s." % [m["name"], CrewData.role_name(String(m["role"])), m["quality"], GameData.fmt_credits(int(o["price"]))], GameState.COL_GOOD)
	if c.has("ship"):
		var e2 := _c_crew_assign({"member": int(m["id"]), "ship": int(c["ship"]), "slot": int(c.get("slot", -1))})
		if e2 != "":
			GameState.log_msg("%s waits in the crew quarters: %s" % [m["name"], e2], GameState.COL_WARN)
	return ""


## {"type":"crew_assign", "member": id, "ship": uid, "slot": n (-1 = the first free post that fits)}
func _c_crew_assign(c: Dictionary) -> String:
	var e := _need_service()
	if e != "":
		return e
	var where := _crew_find(int(c["member"]))
	if where.is_empty():
		return "That crew member is not at this station."
	var f := _fleet_ship(int(c["ship"]))
	if f == null or f.docked_at != String(docked_station()["id"]):
		return "That ship is not in this hangar."
	var m: Dictionary = GameState.quarters_of(String(where[1]))[int(where[2])] if where[0] == "quarters" else (where[1] as ShipFitting).crew_at(int(where[2]))
	var sl := f.crew_slots()
	var slot := int(c.get("slot", -1))
	if slot < 0:
		for k in sl.size():
			if f.crew_at(k).is_empty() and CrewCore.fits(m, String(sl[k][0])):
				slot = k
				break
		if slot < 0:
			return "No free %s post on the %s." % [CrewData.role_name(String(m["role"])), f.ship_name]
	if slot >= sl.size():
		return "No such post."
	var role := String(sl[slot][0])
	if not CrewCore.fits(m, role):
		return "%s is no %s." % [m["name"], CrewData.role_name(role)]
	var te := GameState.crew_role_error(role)
	if te != "":
		return te
	m = _crew_take(where)
	var prev := f.set_crew(slot, m)
	if not prev.is_empty():
		GameState.quarters_of(String(docked_station()["id"])).append(prev)
	GameState.log_msg("%s now serves as %s on the %s." % [m["name"], CrewData.role_name(role), f.ship_name], GameState.COL_GOOD)
	return ""


## {"type":"crew_unassign", "ship": uid, "slot": n} – into the crew quarters of the station
func _c_crew_unassign(c: Dictionary) -> String:
	var e := _need_service()
	if e != "":
		return e
	var f := _fleet_ship(int(c["ship"]))
	if f == null or f.docked_at != String(docked_station()["id"]):
		return "That ship is not in this hangar."
	var m := f.set_crew(int(c["slot"]), {})
	if m.is_empty():
		return "That post is empty."
	GameState.quarters_of(f.docked_at).append(m)
	return ""


## {"type":"crew_dismiss", "member": id} – leaves for good, no money back
func _c_crew_dismiss(c: Dictionary) -> String:
	var e := _need_service()
	if e != "":
		return e
	var where := _crew_find(int(c["member"]))
	if where.is_empty():
		return "That crew member is not at this station."
	var m := _crew_take(where)
	GameState.log_msg("%s has left your service." % m["name"], GameState.COL_INFO)
	return ""


## {"type":"debug_crew", "role": r, "quality": q, "perk": p ("?" rolled), "ship": true (into the active ship) |
##  "fill": true (every post of the active ship) | "xp": n (all crew of the active ship) | "free": bool | "bar": true (new offers)}
func _c_debug_crew(c: Dictionary) -> String:
	var f := _fit()
	if c.has("free"):
		GameState.pilot["crew_free"] = bool(c["free"])
		return ""
	if c.has("bar"):
		var st := docked_station()
		if st.is_empty():
			return "Dock first."
		GameState.bar.erase(String(st["id"]))
		GameState.bar_offers(st)
		return ""
	if c.has("xp"):
		for i in f.crew_slots().size():
			var m: Dictionary = f.crew_at(i)
			if not m.is_empty():
				var nq := CrewCore.learn(m, float(c["xp"]), RandomNumberGenerator.new())
				if nq != "":
					GameState.log_msg("[Debug] %s rises to %s." % [m["name"], nq], GameState.COL_GOOD)
		f.mark_dirty()
		return ""
	var sl := f.crew_slots()
	if bool(c.get("fill", false)):
		for i2 in sl.size():
			if f.crew_at(i2).is_empty():
				if String(sl[i2][0]) == "wing_pilot":
					f.set_crew(i2, GameState.new_crew("copilot", String(c.get("quality", "C")), "wingman"))
				else:
					f.set_crew(i2, GameState.new_crew(String(sl[i2][0]), String(c.get("quality", "C")), String(c.get("perk", "?"))))
		return ""
	var role := String(c.get("role", "gunner"))
	var m2 := GameState.new_crew(role, String(c.get("quality", "C")), String(c.get("perk", "?")))
	if bool(c.get("ship", false)):
		for i3 in sl.size():
			if f.crew_at(i3).is_empty() and CrewCore.fits(m2, String(sl[i3][0])):
				f.set_crew(i3, m2)
				GameState.log_msg("[Debug] %s joins the %s." % [m2["name"], f.ship_name], GameState.COL_GOOD)
				return ""
	var sid := f.docked_at if f.docked_at != "" else _debug_station_id()
	GameState.quarters_of(sid).append(m2)
	GameState.log_msg("[Debug] %s waits in the crew quarters." % m2["name"], GameState.COL_GOOD)
	return ""


## {"type":"module_buy", "module": String} – into station storage.
func _c_module_buy(c: Dictionary) -> String:
	var e := _need_service()
	if e != "":
		return e
	var st := docked_station()
	var mid: String = c["module"]
	if not mid in st["shop"]:
		return "The outfitter does not stock that module."
	var locked: String = GameState.rep.module_error(st, mid)
	if locked != "":
		return locked
	if not GameState.spend(GameState.rep.buy_price(int(GameData.modules[mid]["price"]), docked_faction())):
		return "Not enough credits."
	GameState.storage_add(st["id"], mid)
	GameState.log_msg("%s purchased (in station storage)." % GameData.module_name(mid), GameState.COL_GOOD)
	return ""


## {"type":"module_buy_fit", "slot": String, "module": String} – package 27: buy at the outfitter and fit it
## straight into the slot of the docked ship; the module that was there goes into station storage.
func _c_module_buy_fit(c: Dictionary) -> String:
	var e := _need_service()
	if e != "":
		return e
	var f := _fit()
	var why := f.can_fit(String(c["slot"]), String(c["module"]))
	if why != "":
		return why
	if Missions.cabin_in_use(f, String(c["slot"])):
		return "Passengers are using this cabin – deliver them first."
	var e2 := _c_module_buy({"module": c["module"]})
	if e2 != "":
		return e2
	return _c_fit_module({"slot": c["slot"], "module": c["module"]})


## {"type":"module_sell", "module": String} – from station storage.
func _c_module_sell(c: Dictionary) -> String:
	var e := _need_service()
	if e != "":
		return e
	var st := docked_station()
	var mid: String = c["module"]
	if not GameState.storage_remove(st["id"], mid):
		return "Not in station storage."
	GameState.add_credits(module_sell_price(mid))
	return ""


## What the outfitter of the docked station pays for a stored module.
func module_sell_price(mid: String) -> int:
	return int(GameState.rep.sell_price(float(GameData.modules[mid]["price"]) * MODULE_BUYBACK, docked_faction()))


# ---------------------------------------------------------------- Industry

## {"type":"refine", "ore": String}
func _c_refine(c: Dictionary) -> String:
	var e := _need_service()
	if e != "":
		return e
	var ore: String = c["ore"]
	var err := Industry.refine(_fit(), docked_station(), ore)
	if err == "":
		GameState.log_msg("Crucible refined your %s." % GameData.item_name(ore), GameState.COL_GOOD)
	return err


## {"type":"build", "module": String}
func _c_build(c: Dictionary) -> String:
	var e := _need_service()
	if e != "":
		return e
	var mid: String = c["module"]
	if not GameState.tile_open("station_mfg"):                   # 0.5.30.2: the skill tree
		return "Skill tree: open \"Station Manufacturing\" first (Pilot window)."
	var fe := GameState.fab_tree_error(mid)                      # package 30: blueprints
	if fe != "":
		return fe
	var err := Industry.build(_fit(), docked_station(), mid)
	if err == "":
		GameState.log_msg("Molten Lotus started: %s – ready in %d s (then in station storage)." % [GameData.module_name(Industry.last_built), int(Industry.build_time(mid))], GameState.COL_GOOD)
	return err


## {"type":"ship_build", "item": module id | "drone"} – queue a job in the ship's own factory.
func _c_ship_build(c: Dictionary) -> String:
	var f := _fit()
	if f == null or not f.hull().has("factory"):
		return "This ship has no factory."
	var item := String(c["item"])
	var fe := GameState.fab_tree_error(item)                     # package 30: blueprints
	if fe != "":
		return fe
	var err := Industry.ship_build(f, item)
	if err == "":
		GameState.log_msg("Factory: %s queued (%d s while the factory runs)." % ["Drone" if item == "drone" else GameData.module_name(item), int(Industry.build_time(item))], GameState.COL_GOOD)
	return err


## {"type":"market_offer", "item": id, "amount": n, "price": cr} – on-board market (0 = withdraw).
func _c_market_offer(c: Dictionary) -> String:
	var f := _fit()
	if f == null or not f.hull().has("market"):
		return "This ship has no market."
	var item := String(c["item"])
	var amount := int(c.get("amount", 0))
	if amount <= 0:
		f.market_offers.erase(item)
		return ""
	amount = mini(amount, int(floor(float(f.cargo.get(item, 0.0)))))
	if amount <= 0:
		return "Nothing of that in the hold."
	f.market_offers[item] = {"amount": amount, "price": maxi(1, int(c.get("price", 1)))}
	return ""


# ---------------------------------------------------------------- Contracts

## {"type":"mission_accept", "id": String}
func _c_mission_accept(c: Dictionary) -> String:
	var e := _need_service()
	if e != "":
		return e
	var st := docked_station()
	var closed: String = GameState.rep.contracts_error(docked_faction())
	if closed != "":
		return closed
	var m := _find_mission(GameState.offers_for(GameState.current_system, st), String(c["id"]))
	if m.is_empty():
		m = _find_mission(GameState.faction_offers_for(GameState.current_system, st), String(c["id"]))
	if m.is_empty():
		m = _find_mission(GameState.passenger_offers_for(GameState.current_system, st), String(c["id"]))
	if m.is_empty():
		return "That contract is no longer on the board."
	return GameState.accept_mission(m)


## {"type":"mission_turn_in", "id": String}
func _c_mission_turn_in(c: Dictionary) -> String:
	var e := _need_service()
	if e != "":
		return e
	var m := _find_mission(GameState.missions, String(c["id"]))
	if m.is_empty():
		return "Unknown contract."
	return GameState.turn_in_mission(m, docked_station()["id"])


## {"type":"bond_redeem", "id": String ("" = all bonds redeemable here)} – at a docked Bond Office.
func _c_bond_redeem(c: Dictionary) -> String:
	var f := _fit()
	if f == null or f.docked_at == "":
		return "Bonds can only be redeemed at a Bond Office (dock at a station)."
	var off: String = GameState.stations.down_error(docked_station())
	if off != "":
		return off
	var id := String(c.get("id", ""))
	var st := docked_station()
	var here := GameState.bonds_redeemable_at(st, f.system_id)
	if here.is_empty():
		return "None of your bonds can be redeemed at this station."
	var paid := GameState.redeem_bonds(st, f.system_id, id)
	if paid <= 0:
		return "That bond cannot be redeemed here."
	GameState.log_msg("Sable Writ Exchange paid %s for your bond%s." % [GameData.fmt_credits(paid), "s" if id == "" else ""], GameState.COL_GOOD)
	return ""


## {"type":"relief_deliver", "item": String, "amount": int (-1 = all in the hold)} – at a raided station.
func _c_relief_deliver(c: Dictionary) -> String:
	var e := _need_dock()
	if e != "":
		return e
	var st := docked_station()
	if not GameState.stations.is_down(String(st["id"])):
		return "This station needs no relief deliveries."
	var item := String(c.get("item", ""))
	if GameState.stations.missing(String(st["id"]), item) <= 0:
		return "%s is not needed (any more)." % GameData.item_name(item)
	if GameState.stations.deliver(String(st["id"]), item, int(c.get("amount", -1)), _fit()) < 0:
		return "You have no %s in your cargo hold." % GameData.item_name(item)
	return ""


## {"type":"fine_pay"} – pays the fine with the faction of the docked station (Bond Office).
func _c_fine_pay(_c: Dictionary) -> String:
	var e := _need_service()
	if e != "":
		return e
	var fid := docked_faction()
	if fid == "" or String(docked_station().get("type", "")) == "pirate_haven":
		return "Fines are paid at a Bond Office of the faction you are wanted by."
	if GameState.law.points(fid) <= 0:
		return "Your record with the %s is clean." % FactionData.name_of(fid)
	if GameState.law.pay_fine(fid) < 0:
		return "Not enough credits for the fine (%s)." % GameData.fmt_credits(GameState.law.fine(fid))
	return ""


## {"type":"debug_notorious"} – brings a living notorious pirate (with escorts) into this system.
func _c_debug_notorious(_c: Dictionary) -> String:
	var e := _need_world()
	if e != "":
		return e
	var c: Dictionary = GameState.notorious.summon(world.system_id)
	if c.is_empty():
		return "No notorious pirate alive right now."
	world.notorious_ships.erase(c["id"])
	world._spawn_captain(c, false)
	return ""


## {"type":"debug_raid", "warning": float seconds (300 = like in the game, 0 = at once)}
## A notorious pirate comes to this system, rises to 5 stars and raids a station (not military).
func _c_debug_raid(c: Dictionary) -> String:
	var e := _need_world()
	if e != "":
		return e
	var target := {}
	for st in world.layout["stations"]:
		if String(st["type"]) != "military" and not GameState.stations.is_down(String(st["id"])):
			target = st
			break
	if target.is_empty():
		return "No station here that could be raided (military outposts are never raided)."
	for cap in GameState.notorious.alive_in(world.system_id):
		if not (cap["raid"] as Dictionary).is_empty():
			return "A raid is already under way here."
	var cp: Dictionary = GameState.notorious.summon(world.system_id)
	if cp.is_empty():
		return "No notorious pirate alive right now."
	GameState.notorious._set_stars(cp, 5)
	var w := float(c.get("warning", 300.0))
	GameState.notorious.start_raid(cp, target, GameState.play_time, w)
	if w <= 0.0:
		GameState.notorious._update_raid(cp, GameState.play_time, world.system_id)
	for s9 in world._raid_group(String(cp["id"])):
		s9.queue_free()
	world.notorious_ships.erase(cp["id"])
	world._spawn_captain(cp, false)
	return ""


## {"type":"debug_wanted", "faction": String, "points": int (0 = clear)}
func _c_debug_wanted(c: Dictionary) -> String:
	var fid := String(c.get("faction", ""))
	if not fid in FactionData.POWERS:
		return "Only the powers keep criminal records."
	GameState.law.records.erase(fid)
	var p := int(c.get("points", 0))
	if p > 0:
		GameState.law.records[fid] = {"points": p, "last": GameState.play_time}
	GameState.wanted_changed.emit(fid, GameState.law.level(fid))
	return ""


## {"type":"mission_abandon", "id": String}
func _c_mission_abandon(c: Dictionary) -> String:
	var m := _find_mission(GameState.missions, String(c["id"]))
	if m.is_empty():
		return "Unknown contract."
	GameState.abandon_mission(m)
	return ""


# ---------------------------------------------------------------- Station services

## {"type":"refuel", "uid": int (-1 = all ships in this hangar)}
func _c_refuel(c: Dictionary) -> String:
	return _service("fuel", int(c.get("uid", -1)))


## {"type":"repair", "uid": int (-1 = all ships in this hangar)}
func _c_repair(c: Dictionary) -> String:
	return _service("repair", int(c.get("uid", -1)))


func _service(mode: String, uid: int) -> String:
	var e := _need_service()
	if e != "":
		return e
	var ships: Array = []
	for f in GameState.hangar(docked_station()["id"]):
		if uid < 0 or f.uid == uid:
			ships.append(f)
	if ships.is_empty():
		return "No such ship in this hangar."
	var total := 0
	for f in ships:
		total += service_cost(mode, f)
	if total <= 0:
		return "Nothing to do."
	if not GameState.spend(total):
		return "Not enough credits."
	for f in ships:
		var fit: ShipFitting = f
		var s := fit.stats()
		if mode == "fuel":
			fit.fuel = s["fuel_max"]
		else:
			fit.armor = s["armor_max"]
			fit.structure = s["structure_max"]
	return ""


# ================================================================ Debug (cheats)
# Used by the debug menu (F12). Same format as every other command, so a server can
# simply refuse them in multiplayer.

## {"type":"debug_rep", "faction": String, "value": float}  or  {"type":"debug_rep", "faction": String, "amount": float}
## faction "" = every faction.
func _c_debug_rep(c: Dictionary) -> String:
	var fid := String(c.get("faction", ""))
	if fid != "" and not FactionData.FACTIONS.has(fid):
		return "Unknown faction '%s'." % fid
	for f in (FactionData.FACTIONS.keys() if fid == "" else [fid]):
		var delta := float(c.get("amount", 0.0))
		if c.has("value"):
			delta = float(c["value"]) - GameState.rep.get_rep(f)
		GameState.rep.change(f, delta, "debug")
	return ""


## {"type":"debug_credits", "amount": int}
func _c_debug_credits(c: Dictionary) -> String:
	GameState.credits = maxi(GameState.credits + int(c["amount"]), 0)
	GameState.credits_changed.emit(GameState.credits)
	return ""


## Storage the debug menu delivers into: the docked station, otherwise the home station.
func _debug_station_id() -> String:
	var st := docked_station()
	if not st.is_empty():
		return st["id"]
	return Universe.get_layout(Universe.home_system)["stations"][0]["id"]


## {"type":"debug_give_module", "module": String, "count": int}
func _c_debug_give_module(c: Dictionary) -> String:
	var mid: String = c["module"]
	if not GameData.modules.has(mid):
		return "Unknown module."
	var sid := _debug_station_id()
	GameState.storage_add(sid, mid, maxi(int(c.get("count", 1)), 1))
	GameState.log_msg("[Debug] %d× %s → storage at %s." % [maxi(int(c.get("count", 1)), 1), GameData.module_name(mid), sid], GameState.COL_GOOD)
	return ""


## {"type":"debug_give_ship", "hull": String, "fitted": bool, "board": bool}
## Delivered to the hangar of the docked station (or the home station).
func _c_debug_give_ship(c: Dictionary) -> String:
	var hid: String = c["hull"]
	if not GameData.hulls.has(hid):
		return "Unknown hull."
	var preset := "std_" + hid
	var f: ShipFitting
	if bool(c.get("fitted", true)) and GameData.presets.has(preset):
		f = GameState.create_from_preset(preset, "player")
	else:
		f = GameState.create_fit(hid, {}, "player")
	f.ship_name = "%s »Debug«" % GameData.hulls[hid]["name"]
	f.crew = []
	for i0 in f.crew_slots().size():
		f.crew.append({})
	var sid := _debug_station_id()
	var sys := int(sid.split("_")[1])
	var st := Universe.find_station(sys, sid)
	f.system_id = sys
	f.docked_at = sid
	f.position = st["pos"]
	GameState.add_ship(f)
	GameState.crew_fill_required(f)
	GameState.log_msg("[Debug] %s delivered to the hangar of %s." % [f.ship_name, st["name"]], GameState.COL_GOOD)
	if bool(c.get("board", false)):
		var cur := _fit()
		if cur != null and cur.docked_at == sid:
			GameState.set_active(f.uid)
		else:
			return "Ship delivered – dock at %s to board it." % st["name"]
	return ""


## {"type":"debug_give_cargo", "item": String, "amount": float}
func _c_debug_give_cargo(c: Dictionary) -> String:
	var f := _fit()
	var item: String = c["item"]
	if f == null or not GameData.commodities.has(item):
		return "Unknown commodity."
	var added := f.add_cargo(item, float(c["amount"]))
	if added <= 0.0:
		return "Cargo hold full."
	GameState.log_msg("[Debug] +%.0f %s in the cargo hold." % [added, GameData.item_name(item)], GameState.COL_GOOD)
	return ""


## {"type":"debug_clear_cargo"}
func _c_debug_clear_cargo(_c: Dictionary) -> String:
	var f := _fit()
	if f == null:
		return "No active ship."
	f.cargo.clear()
	return ""


## {"type":"debug_refill"} – shields, armour, structure, capacitor, fuel to max.
func _c_debug_refill(_c: Dictionary) -> String:
	var f := _fit()
	if f == null:
		return "No active ship."
	f.refill()
	return ""


## {"type":"debug_god", "on": bool}
func _c_debug_god(c: Dictionary) -> String:
	god_mode = bool(c["on"])
	GameState.log_msg("[Debug] God mode %s." % ("ON" if god_mode else "off"), GameState.COL_WARN)
	return ""


## {"type":"debug_time_scale", "scale": float}
func _c_debug_time_scale(c: Dictionary) -> String:
	Engine.time_scale = clampf(float(c["scale"]), 0.1, 20.0)
	GameState.log_msg("[Debug] Game speed ×%s." % str(Engine.time_scale), GameState.COL_WARN)
	return ""


## {"type":"debug_teleport", "system": int} – docks at the system's first station
## (or appears near a gate if it has none).
## The first station of a list the ship may dock at – never an L ship at a waystation (review K10). {} = none.
func dock_target(f: ShipFitting, stations: Array) -> Dictionary:
	for st in stations:
		if int(f.hull().get("size", 1)) <= int(GameData.station_types.get(String(st["type"]), {}).get("max_size", 3)):
			return st
	return {}


## {"type":"debug_belt", "kind": "asteroid"|"kuiper"} – package 35: puts the ship (undocked) into a belt of this system
func _c_debug_belt(c: Dictionary) -> String:
	var e := _need_world()
	if e != "":
		return e
	for bt in world.layout.get("belts", []):
		if String(bt["kind"]) == String(c.get("kind", "asteroid")):
			var f := _fit()
			f.docked_at = ""
			var p := Vector2.from_angle(randf() * TAU) * float(bt["r"])
			world.player.position = p
			f.position = p
			world.player.order = {"type": "idle"}
			world.center_on_player()
			return ""
	return "This system has no %s belt." % String(c.get("kind", "asteroid"))


## {"type":"debug_moon", "moon_type"?: "moon_rock"|…} – package 36: puts the ship (undocked) next to a moon of this
## system (the next one each call, or the next one of a type).
var _debug_moon_i := -1


func _c_debug_moon(c: Dictionary) -> String:
	var e := _need_world()
	if e != "":
		return e
	var moons: Array = world.layout.get("moons", [])
	var want := String(c.get("moon_type", ""))
	if want != "":
		moons = moons.filter(func(m): return String(m["type"]) == want)
	if moons.is_empty():
		return "No such moon in this system."
	_debug_moon_i = (_debug_moon_i + 1) % moons.size()
	var m: Dictionary = moons[_debug_moon_i]
	var f := _fit()
	f.docked_at = ""
	var p: Vector2 = (m["pos"] as Vector2) + Vector2.from_angle(randf() * TAU) * float(m["radius"]) * 2.5
	world.player.position = p
	f.position = p
	world.player.order = {"type": "idle"}
	world.center_on_player()
	GameState.log_msg("Debug: next to %s (%s)." % [m["name"], Universe.MOON_TYPES[m["type"]]["name"]])
	return ""


## {"type":"debug_star", "star": "G"|"BH"|…} – package 37: gives the current system another star type (the system is
## built anew around it; for looking at the stars).
func _c_debug_star(c: Dictionary) -> String:
	var e := _need_world()
	if e != "":
		return e
	var sid := GameState.current_system
	var idx := Universe.star_index(String(c.get("star", "G")))
	Universe.systems[sid]["star"] = idx
	Universe.layouts.erase(sid)
	var mn = world.get_tree().current_scene
	if mn != null and mn.has_method("load_system"):
		mn.load_system(sid)
	var f := _fit()
	if f != null and f.docked_at == "":
		var st: Dictionary = Universe.get_layout(sid)["star"]
		var land := float(Universe.STAR_TYPES[idx]["land"]) * float(st["radius"])
		Commands.world.player.position = Vector2(land, 0.0)
		f.position = Commands.world.player.position
		Commands.world.center_on_player()
	GameState.log_msg("Debug: the star is now a %s." % Universe.STAR_TYPES[idx]["name"])
	return ""


## {"type":"debug_cme"} – package 37: a coronal mass ejection – 0.6.37.5: from the start of the countdown (red banner and
## alarm, 10 s to the eruption).
func _c_debug_cme(_c: Dictionary) -> String:
	var e := _need_world()
	if e != "":
		return e
	if not bool(world.star_type().get("cme", false)):
		return "This star does not erupt."
	world.start_cme()
	world._cme["t"] = world.CME_WARN - world.CME_BANNER
	return ""


## {"type":"debug_planet", "planet_type": "terran"|…} – package 38: puts the ship next to the next planet of this type
## in the current system (on its night side, to see city lights).
var _debug_planet_i := -1


func _c_debug_planet(c: Dictionary) -> String:
	var e := _need_world()
	if e != "":
		return e
	var want := String(c.get("planet_type", ""))
	var ps: Array = world.layout["planets"].filter(func(p): return want == "" or String(p["type"]) == want)
	if ps.is_empty():
		return "No %s in this system." % (String(Universe.PLANET_TYPES[want]["name"]) if Universe.PLANET_TYPES.has(want) else "planet")
	_debug_planet_i = (_debug_planet_i + 1) % ps.size()
	var p: Dictionary = ps[_debug_planet_i]
	var f := _fit()
	f.docked_at = ""
	var night := (p["pos"] as Vector2).normalized()            # away from the star: the night side
	var pos: Vector2 = (p["pos"] as Vector2) + night.rotated(0.5) * float(p["radius"]) * 2.2
	world.player.position = pos
	f.position = pos
	world.player.order = {"type": "idle"}
	world.center_on_player()
	GameState.log_msg("Debug: next to %s (%s)." % [p["name"], Universe.PLANET_TYPES[String(p["type"])]["name"]])
	return ""


# ---------------------------------------------------------------- Package 39a: the Senate, Landfall

## {"type":"senate_vote", "side": "yes"|"no"}
func _c_senate_vote(c: Dictionary) -> String:
	return GameState.senate.vote(String(c.get("side", "yes")))


## {"type":"senate_donate", "side": "yes"|"no"} – one party donation
func _c_senate_donate(c: Dictionary) -> String:
	return GameState.senate.donate(String(c.get("side", "yes")))


## {"type":"senate_bribe", "side": "yes"|"no"}
func _c_senate_bribe(c: Dictionary) -> String:
	return GameState.senate.bribe(String(c.get("side", "yes")))


## {"type":"debug_landfall"} – to Landfall (docked at The Vote)
func _c_debug_landfall(_c: Dictionary) -> String:
	var sid := Universe.special_system("landfall")
	if sid < 0:
		return "No Landfall in this cluster."
	return _c_debug_teleport({"system": sid})


## {"type":"debug_permit", "faction": "assembly", "on": true|false} – give or take the entry permit
func _c_debug_permit(c: Dictionary) -> String:
	var f := String(c.get("faction", "assembly"))
	if bool(c.get("on", true)):
		GameState.permits[f] = true
	else:
		GameState.permits.erase(f)
	GameState.log_msg("Debug: entry permit of the %s %s." % [FactionData.name_of(f), "given" if bool(c.get("on", true)) else "taken"])
	return ""


## {"type":"debug_senate", "do": "new"|"resolve"|"caught"|"clean", "bill": id} – a new bill now, or the vote now
## (caught / clean: a bribe comes out / does not)
func _c_debug_senate(c: Dictionary) -> String:
	match String(c.get("do", "new")):
		"new":
			GameState.senate.new_bill(String(c.get("bill", "")))
		"resolve":
			if GameState.senate.bill.is_empty():
				return "No bill on the floor."
			GameState.senate.resolve()
		"caught", "clean":
			if GameState.senate.bill.is_empty():
				return "No bill on the floor."
			GameState.senate.resolve(1 if String(c["do"]) == "caught" else 0)
	return ""


## {"type":"debug_vote_beam"} – a ballot drone out to a gate now (Landfall)
func _c_debug_vote_beam(_c: Dictionary) -> String:
	var e := _need_world()
	if e != "":
		return e
	if world.fire_vote_beam() == null:
		return "Only in Landfall."
	return ""


## {"type":"debug_roll_orbits"} – package 36: planets and moons to new places on their orbits, as on arriving by jump
## (the ship stays where it is).
func _c_debug_roll_orbits(_c: Dictionary) -> String:
	var e := _need_world()
	if e != "":
		return e
	Universe.roll_orbits(GameState.current_system)
	var mn = world.get_tree().current_scene
	if mn != null and mn.has_method("load_system"):
		mn.load_system(GameState.current_system)
	return ""


func _c_debug_teleport(c: Dictionary) -> String:
	var f := _fit()
	var to := int(c["system"])
	if f == null:
		return "No active ship."
	if f.in_transit():
		return "Not during a hyperspace jump."
	if to < 0 or to >= Universe.systems.size():
		return "Unknown system."
	if world != null and is_instance_valid(world):
		world.remove_player()
	var L := Universe.get_layout(to)
	f.route.clear()
	f.system_id = to
	var docked := false
	var st: Dictionary = dock_target(f, L["stations"])
	if not st.is_empty():
		f.docked_at = st["id"]
		f.position = st["pos"]
		docked = true
	else:
		f.docked_at = ""
		var g: Dictionary = L["gates"][0]
		f.position = (g["pos"] as Vector2) * 0.98
	GameState.log_msg("[Debug] Teleported to %s." % Universe.systems[to]["name"], GameState.COL_WARN)
	GameState.active_changed.emit()
	var main := get_tree().current_scene
	if docked and main != null and main.has_method("open_station"):
		main.open_station.call_deferred()
	return ""


## {"type":"debug_reveal_anomalies"} – in the current system.
func _c_debug_reveal_anomalies(_c: Dictionary) -> String:
	var sys := GameState.current_system
	for an in Universe.get_layout(sys)["anomalies"]:
		if not an["revealed"]:
			an["revealed"] = true
			an["scan"] = an["difficulty"]
			GameState.anomaly_revealed.emit(sys, an["id"])
	return ""


## {"type":"debug_spawn", "preset": String, "count": int, "gov": String (optional faction id)}
## A government faction spawns a neutral ship in its paint (patrols follow in package 11).
func _c_debug_spawn(c: Dictionary) -> String:
	var e := _need_world()
	if e != "":
		return e
	var preset: String = c["preset"]
	if not GameData.presets.has(preset):
		return "Unknown preset."
	var gov: String = c.get("gov", "")
	var side := "pirate"
	if gov in FactionData.POWERS:
		side = "neutral"
	if c.has("side"):
		side = String(c["side"])        # package 25d: debug "spawn any ship"
	for i in clampi(int(c.get("count", 1)), 1, 20):
		var off := Vector2.from_angle(randf() * TAU) * randf_range(700.0, 1100.0)
		world.spawn_npc(preset, world.player.position + off, side, gov)
	return ""


## {"type":"debug_fill_drones"} – fills the active ship's drone hangar (package 25e).
func _c_debug_fill_drones(_c: Dictionary) -> String:
	var f := _fit()
	if f == null:
		return "No ship."
	var room := int(f.stats()["drone_storage"])
	if room <= 0:
		return "No drone hangar fitted."
	while f.drones.size() < room:
		f.drones.append({"fuel": 1.0, "hp": 1.0, "out": false})
	for r in f.drones:
		r["fuel"] = 1.0
		r["hp"] = 1.0
	GameState.log_msg("Drone hangar filled: %d drones." % f.drones.size(), GameState.COL_GOOD)
	return ""


## {"type":"wormhole_jump", "to": int} – Axiom Threshold: through a wormhole without a gate (package 25g).
func _c_wormhole_jump(c: Dictionary) -> String:
	var e := _need_world()
	if e != "":
		return e
	# review W6 (0.4.25.46): like a gate jump – not out of warp or a docking manoeuvre, and the drones come home
	# first (they launch again after the arrival)
	var p = world.player
	if p.in_warp():
		return "Not while in warp."
	if String(p.order.get("type", "")) in ["docking", "undocking"]:
		return "Not while docking or undocking."
	var err := GameState.wormhole_error(GameState.active(), int(c["to"]))
	if err != "":
		return err
	world.stow_all_drones(p, true)
	return GameState.begin_wormhole(GameState.active(), int(c["to"]))


## {"type":"debug_exotic", "amount": int} – exotic matter for the Threshold; also resets its wormhole cooldown.
func _c_debug_exotic(c: Dictionary) -> String:
	GameState.exotic_matter += int(c.get("amount", 10))
	var f := GameState.active()
	if f != null:
		f.wormhole_ready = 0.0
	GameState.log_msg("Exotic matter: %d (wormhole cooldown reset)." % GameState.exotic_matter, GameState.COL_GOOD)
	return ""


## {"type":"debug_npc_drones"} – every NPC carrier near you launches its drones (to test the
## Cathedral's anti-drone pulse, package 25f).
func _c_debug_npc_drones(_c: Dictionary) -> String:
	var e := _need_world()
	if e != "":
		return e
	var n := 0
	for s in world.ship_layer.get_children():
		if s is Ship and s != world.player and not s.is_drone and not s.dying and s.position.distance_to(world.player.position) < 20000.0 and int(s.fit.stats()["drones_max"]) > 0 and int(s.fit.stats()["drone_storage"]) > 0:
			if s.fit.drones.is_empty():
				for i in int(s.fit.stats()["drones_max"]):
					s.fit.drones.append({"fuel": 1.0, "hp": 1.0, "out": false})
			if world.launch_drones(s) == "":
				n += 1
	return "" if n > 0 else "No NPC carrier with drones nearby (spawn one: World → Spawn any ship)."


## {"type":"debug_platform_launch"} – the Citadel's S-ship platform: hatch, rising ship, lift-off
## (animation only; the S ship itself comes with Teil 5) – package 25d.
func _c_debug_platform_launch(_c: Dictionary) -> String:
	var e := _need_world()
	if e != "":
		return e
	return world.player.launch_platform()


## {"type":"debug_kill_hostiles"} – destroys all pirates in the system (counts as kills).
func _c_debug_kill_hostiles(_c: Dictionary) -> String:
	var e := _need_world()
	if e != "":
		return e
	for n in world.ship_layer.get_children():
		if n is Ship and n.faction == "pirate" and n.is_targetable():
			n.take_damage(1.0e9, "explosive", world.player)
	return ""


## {"type":"debug_complete_missions"} – kill/survey objectives done, deliveries in the hold.
func _c_debug_complete_missions(_c: Dictionary) -> String:
	var f := _fit()
	for m in GameState.missions:
		m["progress"] = m["amount"]
		if m["type"] == "mining" and f != null:
			f.cargo[m["item"]] = maxf(float(f.cargo.get(m["item"], 0.0)), float(m["amount"]))
	GameState.missions_changed.emit()
	GameState.log_msg("[Debug] Contract objectives complete – turn them in at the issuing station.", GameState.COL_WARN)
	return ""


## {"type":"debug_convoy", "freighters": n, "jumps": j} – an escort contract from the docked (or the
## nearest) station: n freighters to a random station exactly j jumps away; accepted at once, the
## convoy rolls out and gathers outside the station.
func _c_debug_convoy(c: Dictionary) -> String:
	var f := _fit()
	if f == null or f.in_transit():
		return "No ship in a system."
	var st := docked_station()
	if st.is_empty():
		var best := INF
		var pos: Vector2 = world.player.position if _need_world() == "" else f.position
		for s0 in Universe.get_layout(f.system_id)["stations"]:
			var d0: float = (s0["pos"] as Vector2).distance_to(pos)
			if d0 < best:
				best = d0
				st = s0
	if st.is_empty():
		return "No station in this system."
	var n := clampi(int(c.get("freighters", 3)), 1, 6)
	var jumps := clampi(int(c.get("jumps", 2)), 1, 8)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var m := Missions.debug_escort(f.system_id, st, n, jumps, rng)
	if m.is_empty():
		return "No station exactly %d jump%s away (class-1 routes)." % [jumps, "" if jumps == 1 else "s"]
	var err := GameState.accept_mission(m)
	if err != "":
		return err
	GameState.log_msg("Debug convoy: %s" % m["title"], GameState.COL_GOOD)
	return ""


## {"type":"debug_new_contracts"} – reroll the bulletin board here (BlackLedger and faction contracts).
func _c_debug_new_contracts(_c: Dictionary) -> String:
	var e := _need_dock()
	if e != "":
		return e
	var sid := String(docked_station()["id"])
	GameState.offers.erase(sid)
	GameState.offers.erase(sid + "#f")
	return ""
