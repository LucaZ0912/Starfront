extends Node
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


func _c_toggle_module(c: Dictionary) -> String:
	var e := _need_world()
	if e != "":
		return e
	var slot := String(c["slot"])
	return world.player.set_module_active(slot, not bool(world.player.module_on.get(slot, false)))


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
	var with_fit := bool(c.get("fitted", false))
	var preset := "std_" + hid
	if with_fit and not GameData.presets.has(preset):
		return "No standard fit available."
	var price := GameData.preset_price(preset) if with_fit else int(GameData.hulls[hid]["price"])
	price = GameState.rep.buy_price(price, docked_faction())
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
	var price := maxi(GameState.rep.buy_price(int(st["market"][cid]["buy"]), docked_faction()), 1)
	var max_space := int(floor(f.free_for(cid) / GameData.item_volume(cid)))
	var max_money := int(floor(float(GameState.credits) / float(price)))
	var amount := mini(int(c.get("amount", 1)), mini(max_space, max_money))
	if amount <= 0:
		return "Purchase not possible (cargo space or credits)."
	GameState.spend(amount * price)
	f.add_cargo(cid, amount)
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
	var earn := int(round(amount * GameState.rep.sell_price(float(st["market"][cid]["sell"]), docked_faction())))
	GameState.add_credits(earn)
	GameState.log_msg("Sold %.1f %s for %s." % [amount, GameData.item_name(cid), GameData.fmt_credits(earn)], GameState.COL_GOOD)
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
	var err := Industry.build(_fit(), docked_station(), mid)
	if err == "":
		GameState.log_msg("Molten Lotus fabricated: %s (in station storage)." % GameData.module_name(Industry.last_built), GameState.COL_GOOD)
	return err


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
	var sid := _debug_station_id()
	var sys := int(sid.split("_")[1])
	var st := Universe.find_station(sys, sid)
	f.system_id = sys
	f.docked_at = sid
	f.position = st["pos"]
	GameState.add_ship(f)
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
	if not L["stations"].is_empty():
		var st: Dictionary = L["stations"][0]
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
	for i in clampi(int(c.get("count", 1)), 1, 20):
		var off := Vector2.from_angle(randf() * TAU) * randf_range(700.0, 1100.0)
		world.spawn_npc(preset, world.player.position + off, side, gov)
	return ""


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


## {"type":"debug_new_contracts"} – reroll the bulletin board here (BlackLedger and faction contracts).
func _c_debug_new_contracts(_c: Dictionary) -> String:
	var e := _need_dock()
	if e != "":
		return e
	var sid := String(docked_station()["id"])
	GameState.offers.erase(sid)
	GameState.offers.erase(sid + "#f")
	return ""
