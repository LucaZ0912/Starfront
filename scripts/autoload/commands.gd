extends Node
const MuseumDataC = preload("res://data/museum.gd")
const PilotArtX = preload("res://scripts/core/pilot_art.gd")
const PilotDataX = preload("res://data/pilot.gd")
const PaintDataC = preload("res://data/paints.gd")
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


const DEBUG_MOVES := ["debug_land", "debug_poi", "debug_capital", "debug_landfall", "debug_special", "debug_teleport", "debug_vault"]


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
	if err == "" and t in DEBUG_MOVES and Players.split and GameState.has_pilot2() and GameState.acting == 0:
		# (a debug move puts you somewhere at once: the second player and their ship come with you, as when the split
		# screen begins; by their own flying they would not be there)
		var mj := get_tree().current_scene
		if mj != null and mj.has_method("p2_join_now"):
			mj.p2_join_now()
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
	var st := Universe.find_station(f.system_id, f.docked_at)
	return st


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
	elif docked_faction() == "covenant":
		k *= GameState.curia.mod("service") / GameState.curia.mod("buy")       # package 39b: edicts
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
		var od := {"type": "move", "pos": p.position + d.normalized() * 6000.0, "keys": true}
		if d.length() < 0.95:
			od["pace"] = clampf(d.length(), 0.3, 1.0)       # package 80: the stick half way – half speed
		p.set_order(od)
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


## {"type":"descend", "id": <descent beacon id>} – package 50: fly to the beacon (warp if far) and go down.
func _c_descend(c: Dictionary) -> String:
	var e := _need_world()
	if e != "":
		return e
	var n = world.find_object(String(c["id"]))
	if n == null or n is Ship or n.kind != "descent":
		return "That is no descent beacon."
	return world.order_goto(String(c["id"]))


## {"type":"jump", "id": <gate id>} – fly to the gate and jump.
func _c_jump(c: Dictionary) -> String:
	var e := _need_world()
	if e != "":
		return e
	var n = world.find_object(String(c["id"]))
	if n == null or n is Ship or n.kind != "gate":
		return "That is not a gate."
	return world.order_goto(String(c["id"]))             # (stage 4E: who is at the gate asks the other player)


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


## {"type":"munitions_buy", "item": id, "amount": n} – package 42b: ammunition at the Munitions Depot
func _c_munitions_buy(c: Dictionary) -> String:
	var e := _need_service()
	if e != "":
		return e
	var st := docked_station()
	var f := _fit()
	var cid := String(c.get("item", ""))
	var offer := Munitions.offer(st)
	if not offer.has(cid):
		return "Not stocked at this depot."
	var price := GameState.rep.buy_price(int(offer[cid]), docked_faction())
	var n := mini(int(c.get("amount", 1)), int(floor(f.free_for(cid) / GameData.item_volume(cid))))
	n = mini(n, int(floor(float(GameState.credits) / float(maxi(price, 1)))))
	if n <= 0:
		return "Purchase not possible (cargo space or credits)."
	GameState.spend(n * price)
	f.add_cargo(cid, float(n))
	GameState.log_msg("Bought %d × %s for %s." % [n, GameData.item_name(cid), GameData.fmt_credits(n * price)], GameState.COL_GOOD)
	return ""


## {"type":"munitions_sell", "item": id, "amount": n (-1 = all)} – back to the depot for half the price
func _c_munitions_sell(c: Dictionary) -> String:
	var e := _need_service()
	if e != "":
		return e
	var f := _fit()
	var cid := String(c.get("item", ""))
	if not Munitions.AMMO.has(cid):
		return "The depot only takes munitions."
	var have := int(floor(float(f.cargo.get(cid, 0.0)) + 0.001))
	var n := have if int(c.get("amount", -1)) < 0 else mini(int(c.get("amount", 1)), have)
	if n <= 0:
		return "Nothing to sell."
	var earn := int(round(float(GameData.commodities[cid]["price"]) * Munitions.BUYBACK * n))
	f.remove_cargo(cid, float(n))
	GameState.add_credits(earn)
	GameState.log_msg("Sold %d × %s back for %s." % [n, GameData.item_name(cid), GameData.fmt_credits(earn)], GameState.COL_GOOD)
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


## {"type":"fire_group", "group": 1–8} – package 79 (Luz): switches a whole fire group – any module of it off (or on
## another target than the active one): all on, at the active target; else all off.
func _c_fire_group(c: Dictionary) -> String:
	var e := _need_world()
	if e != "":
		return e
	var g := int(c.get("group", 0))
	var p: Ship = world.player
	var slots: Array = p.fit.group_slots(g)
	if slots.is_empty():
		return "Fire group %d is empty: set it in Ship → Modules → Fire groups." % g
	var on_all := true
	for s0 in slots:
		if not bool(p.module_on.get(s0, false)) or _moves_to_active(p, s0):
			on_all = false
	var err := ""
	for s1 in slots:
		var r := ""
		if on_all:
			r = p.set_module_active(s1, false)
		elif not bool(p.module_on.get(s1, false)):
			r = p.set_module_active(s1, true)
		elif _moves_to_active(p, s1):
			r = p.retarget(s1)
		if r != "" and err == "":
			err = r
	return err


func _moves_to_active(p: Ship, slot: String) -> bool:
	if not bool(p.module_on.get(slot, false)) or p.locked_node() == null or String(p.module_target.get(slot, "")) == p.active_lock:
		return false
	var e2 := p.find_module(slot)
	return not e2.is_empty() and e2["kind"] in ["weapon", "tool"] and p.module_target_error(e2, p.locked_node()) == ""


## {"type":"fire_group_set", "slot": String, "group": 1–8, "on": bool} / {"type":"fire_group_auto"} /
## {"type":"fire_group_clear"} – package 79: the active ship's fire groups, set by hand, by kind, or emptied.
func _c_fire_group_set(c: Dictionary) -> String:
	var f := _fit()
	if f == null:
		return "No active ship."
	var g := int(c.get("group", 0))
	if g < 1 or g > ShipFitting.FIRE_GROUPS:
		return "No such fire group."
	f.set_fire_group(String(c.get("slot", "")), g, bool(c.get("on", true)))
	return ""


func _c_fire_group_auto(_c: Dictionary) -> String:
	var f := _fit()
	if f == null:
		return "No active ship."
	f.auto_fire_groups()
	return ""


func _c_fire_group_clear(_c: Dictionary) -> String:
	var f := _fit()
	if f == null:
		return "No active ship."
	f.clear_fire_groups()
	return ""


## {"type":"story_track", "id": mission id or ""} – package 55: the mission whose goals show over the ship's panel.
func _c_story_track(c: Dictionary) -> String:
	GameState.story.track(String(c.get("id", "")))
	return ""


## {"type":"story_tips", "on": bool} – package 55: tips on or off.
func _c_story_tips(c: Dictionary) -> String:
	GameState.story.tips_off = not bool(c.get("on", true))
	GameState.story.changed.emit()
	return ""


## {"type":"debug_fern", "do": "call" | "reset" | "land" | "stairs" | "alley" | "bar" | "done" | "job" | "job_given" |
## "job_rv" | "job_away" | "job_done" | "party" | "round" | "rj_intel" | "rj_raid" | "rj_smuggle" | "rj_rv" |
## "rj_back" | "rj_drop"}: package 64b: Rook's
## call now (the entry permit for Fern, the way to Luz), everything of it back to before the call, or a point on
## the way.
func _c_debug_fern(c: Dictionary) -> String:
	var st = GameState.story
	var m = _main()
	var w = m.get_meta("dan_work") if m != null and m.has_meta("dan_work") else null
	if String(c.get("do", "call")) == "reset":
		_debug_fern_wipe(w)
		GameState.log_msg("[Debug] Fern: back to before Rook's call.", GameState.COL_INFO)
		return ""
	var what := String(c.get("do", "call"))
	if what != "call":
		# a point on the way to Luz: "land" (down to Centauria, the call made), "stairs" (the top of the stairs, Rook
		# waiting), "alley" (Rook ahead of you in the alley), "bar" (in the bar, before Luz), "done" (Luz met)
		if m == null:
			return "No game running."
		if w == null or not is_instance_valid(w):
			st.flags["intro_stage"] = "58"                 # (a game without the story: the open game, as after the intro)
			st.flags["intro_done"] = true
			m._start_dan_work("load")
			w = m.get_meta("dan_work")
		if String(w.phase) != "free":
			w._set_phase("free")
		if not st.flags.has("intro_stage"):
			st.flags["intro_stage"] = "58"
		st.flags["intro_done"] = true                      # (the story listens to you only once the intro is over)
		st.flags["cit_licence"] = true                     # (… and you hold your licence: the skill tree is open)
		if what in ["rj_rv", "rj_back", "rj_drop"]:
			# package 64d: the round's job in hand: to its point in space, done in the field, let go
			var j: Dictionary = w.rj()
			if j.is_empty():
				return "No job of the round in hand."
			if what == "rj_drop":
				w.rj_drop()
			elif what == "rj_back":
				w._rj_clear()
				w._bcn_off(int(j["sys"]), "rj_rv")
				w._bcn_off(int(j["sys"]), "rj_loot")
				w._rj_stage("back")
			else:
				if _ground() != null:
					return "Take off first: the point lies in space."
				_debug_ship_to(m, int(j["sys"]), w.rj_pos(int(j["sys"]), int(j["seed"])) + Vector2(400.0, 0.0))
			return ""
		_debug_fern_wipe(w)
		st.flags["fern_called"] = true
		st.start("fern")
		st.tracked = "fern"
		if what in ["party", "round", "room", "col_invite", "col_done"] or what.begins_with("rj_"):
			# package 64d: "party" (the test reported, the party still to come: in the bar it begins at once), "round"
			# (you are of the round), "rj_intel" / "rj_raid" / "rj_smuggle" (of the round, with such a job in hand)
			for fj2 in ["fern_arrived", "fern_landed", "fern_rook", "fern_luz", "luz_job", "luz_rv", "luz_data", "luz_away", "luz_done"]:
				st.set_flag(fj2, true)
			st.flags["fern_radio"] = true
			st.flags["luz_sys"] = w._luz_pick_sys()
			if what != "party":
				st.set_flag("luz_round", true)
			if what != "party" and what != "round_only":
				st.set_flag("luz_room", true)                 # (64e: the room above the bar is yours with the round)
			if what in ["col_invite", "col_done"]:
				# package 64f: Rook has asked you to the Colosseum ("col_invite": Rook waits on its plaza), or you met there
				st.set_flag("luz_slept", true)
				st.set_flag("rook_invited", true)
				st.start("rook_col")
				st.tracked = "rook_col"
				if what == "col_done":
					st.set_flag("rook_mate", true)
			w._fern_weather()
			var gp = _ground()
			var in_ctr: bool = gp != null and is_instance_valid(gp) and String((gp.station as Dictionary).get("name", "")) == "Centauria"
			if what.begins_with("rj_"):
				var kind := what.trim_prefix("rj_")
				var who := "kraut" if kind == "raid" else "ratte"
				var got := false
				for o in w.rj_offers(who):
					if String(o["kind"]) == kind and not got:
						w.rj_take(o)
						got = true
				if not got:
					return "Nobody offers that just now."
			if in_ctr:
				gp.story_mode = w.ground_mode(gp.station)
				if what in ["col_invite", "col_done"]:
					gp.go_level("zcol", "from_station")
				else:
					gp.go_level("zroom" if what == "room" else "zbar", "from_bar" if what == "room" else "from_street")
				if what == "party":
					w._luz_party.call_deferred()
			GameState.log_msg("[Debug] The round: %s." % {"party": "the party (it begins in the bar)", "round": "you are of the round", "room": "the room above the bar is yours", "col_invite": "Rook waits before the Colosseum", "col_done": "Rook met at the Colosseum, a team mate now"}.get(what, "a job in hand (%s)" % what.trim_prefix("rj_")), GameState.COL_INFO)
			return ""
		if what.begins_with("job"):
			# package 64c: Luz's test: "job" (Luz met, the job not yet given), "job_given", "job_rv" (in space: at the
			# rendezvous), "job_away" (the data is yours, the report is owed), "job_done"
			for fj in ["fern_arrived", "fern_landed", "fern_rook", "fern_luz"]:
				st.set_flag(fj, true)
			st.flags["fern_radio"] = true
			w._fern_weather()
			if what != "job":
				st.flags["luz_sys"] = w._luz_pick_sys()
				st.set_flag("luz_job", true)
				st.start("luz_test")
				st.tracked = "luz_test"
				w._luz_beacon(int(st.flags["luz_sys"]))
			if what in ["job_away", "job_done"]:
				for fk in ["luz_rv", "luz_data", "luz_away"]:
					st.set_flag(fk, true)
				w._luz_beacon_off(int(st.flags["luz_sys"]))
			if what == "job_done":
				st.set_flag("luz_done", true)
			w._luz_mark()
			var gj = _ground()
			if gj != null and is_instance_valid(gj) and String((gj.station as Dictionary).get("name", "")) == "Centauria" and what != "job_rv":
				gj.go_level("zbar", "from_street")           # (on the ground in Centauria: into the bar, to Luz)
			if what == "job_rv":
				if _ground() != null:
					return "Take off first: the rendezvous lies in space."
				_debug_ship_to(m, int(st.flags["luz_sys"]), w.luz_rv_pos(int(st.flags["luz_sys"])) + Vector2(400.0, 0.0))
			GameState.log_msg("[Debug] Luz's test: %s." % {"job": "Luz has a job for you", "job_given": "the job is yours, the rendezvous marked", "job_rv": "at the rendezvous", "job_away": "the data is yours, Luz waits", "job_done": "reported"}.get(what, what), GameState.COL_INFO)
			return ""
		if what != "land":
			st.set_flag("fern_arrived", true)
			st.set_flag("fern_landed", true)
			st.flags["fern_radio"] = true
		if what in ["alley", "bar", "done"]:
			st.set_flag("fern_rook", true)
		if what == "done":
			st.set_flag("fern_luz", true)
		w._lead = {}
		w._fern_busy = false
		w._fern_weather()
		var g = _ground()
		var here: bool = g != null and is_instance_valid(g) and String((g.station as Dictionary).get("name", "")) == "Centauria"
		if what == "land":
			if here:
				g.story_mode = w.ground_mode(g.station)
				g.go_level("hangar", "lift")
			else:
				_debug_fern_land(m)
			GameState.log_msg("[Debug] Fern: down to Centauria, Rook has called.", GameState.COL_INFO)
			return ""
		if not here:
			return "Land in Centauria first (\"Land in Centauria\")."
		g.story_mode = w.ground_mode(g.station)
		match what:
			"stairs":
				g.go_level("zplaza", "from_station")
			"alley":
				g.go_level("zalley", "from_plaza")
			_:
				g.go_level("zbar", "from_street")
		GameState.log_msg("[Debug] Fern: %s." % {"stairs": "the top of the stairs, Rook waits", "alley": "the alley, Rook ahead of you", "bar": "the bar, before Luz", "done": "Luz met"}.get(what, what), GameState.COL_INFO)
		return ""
	if w == null or not is_instance_valid(w) or String(w.phase) != "free":
		return "The story is not in the open game yet (Rook calls after the intro)."
	if bool(st.flags.get("fern_called", false)):
		return "Rook has called already."
	w._fern_call()
	return ""


## Everything of Rook's introduction and of Luz's test back to nothing.
func _debug_fern_wipe(w) -> void:
	var st = GameState.story
	if w != null and is_instance_valid(w):
		w._luz_clear()
		if int(st.flags.get("luz_sys", -1)) >= 0:
			w._luz_beacon_off(int(st.flags["luz_sys"]))
	if w != null and is_instance_valid(w):
		var j: Dictionary = w.rj()
		w._rj_clear()
		if not j.is_empty():
			w._bcn_off(int(j["sys"]), "rj_rv")
			w._bcn_off(int(j["sys"]), "rj_loot")
		w._party64 = false
	for fl in st.flags.keys():
		if String(fl).begins_with("fern_") or String(fl).begins_with("luz_") or String(fl) == "rj" or String(fl).begins_with("rj_") or String(fl).begins_with("rook_"):
			st.flags.erase(fl)
	for mid in ["fern", "luz_test", "round_job", "rook_col"]:
		st.missions.erase(mid)
		st.done.erase(mid)


## Sets the active ship onto a spot in space in a system (wherever it is: docked, or systems away).
func _debug_ship_to(m, sid: int, pos: Vector2) -> void:
	var f := _fit()
	if f == null or sid < 0 or f.in_transit():
		return
	if m.station_panel != null:
		m.station_panel.close()
	if world != null and is_instance_valid(world):
		world.remove_player()
	f.route.clear()
	f.system_id = sid
	f.docked_at = ""
	f.position = pos
	GameState.active_changed.emit()


## To the Fern system, then down to Centauria (one after the other: the system has to be there first).
func _debug_fern_land(m) -> void:
	var sid := Universe.special_system("fern")
	if GameState.current_system != sid:
		_c_debug_special({"special": "fern"})
		for i in 40:
			await get_tree().process_frame
		for wl in 900:
			if m.loading == null or not is_instance_valid(m.loading):
				break
			await get_tree().process_frame
	if m.station_panel != null:
		m.station_panel.close()
	for mo in Universe.get_layout(sid)["moons"]:
		if String(mo["name"]) == "Pelagia":
			_c_debug_land({"body": String(mo["id"]), "kind": "city"})


## {"type":"debug_story", "do": "start" | "step" | "flag" | "reset" | "tip" | "radio" | "next", "id", "step", "name"}
## – package 55: the story by hand: start a mission (at a step), jump to a step, set a flag, a tip, a radio call, the
## step done at once, everything back.
func _c_debug_story(c: Dictionary) -> String:
	var st = GameState.story
	var mid := String(c.get("id", "debug_test"))
	match String(c.get("do", "start")):
		"start":
			return st.start(mid, int(c.get("step", 0)))
		"step":
			if not st.running(mid):
				return st.start(mid, int(c.get("step", 0)))
			st._enter(mid, int(c.get("step", 0)))
		"next":
			if not st.running(mid):
				return "Not running."
			for g in st.step_data(mid).get("goals", []):
				st._meet(mid, String(g["id"]))
		"flag":
			st.set_flag(String(c.get("name", "debug_flag")), c.get("value", true))
		"tip":
			st.tips_seen.erase(String(c.get("tip", "tip_fire_groups")))
			st.tip(String(c.get("tip", "tip_fire_groups")))
		"radio":
			st.show.emit("radio", {"who": "dan", "text": "Radio check: one, two. Can you hear me, pilot?", "mission": ""})
		"reset":
			st.reset()
	GameState.log_msg("[Debug] Story: %s." % String(c.get("do", "start")), GameState.COL_WARN)
	return ""


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
		return "The %s cannot undock yet: %s" % [_fit().hull()["name"], te]
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
	GameState.log_msg("New looks: %s paid to the image studio." % GameData.fmt_credits(price), GameState.COL_GOOD)
	return ""


func look_price() -> int:
	return GameState.rep.buy_price(PilotDataX.LOOK_PRICE, docked_faction())


## {"type":"paint_ship", "uid": int, "paint": id} – package 61d (Luz): Second Skin in Centauria paints one of your
## ships that stands in the city's hangar ("" : back to the factory's colours, free). The price goes by the hull's
## size, after the standing.
## Package 62 (Luz): the cashier of the Grand Centauria: credits for Coins ("coins_buy"), Coins for credits
## ("coins_sell"), `n` Coins at a time.
func _c_coins_buy(c: Dictionary) -> String:
	var e := _need_coins(c)
	if e != "":
		return e
	var n := int(c.get("n", 0))
	var price := n * GameState.COIN_BUY
	if GameState.credits < price:
		return "Not enough credits (%s)." % GameData.fmt_credits(price)
	GameState.spend(price)
	GameState.coins += n
	GameState.log_msg("The cashier counts out %d Coins for %s." % [n, GameData.fmt_credits(price)], GameState.COL_GOOD)
	return ""


func _c_coins_sell(c: Dictionary) -> String:
	var e := _need_coins(c)
	if e != "":
		return e
	var n := int(c.get("n", 0))
	if GameState.coins < n:
		return "You do not hold that many Coins."
	GameState.coins -= n
	GameState.credits += n * GameState.COIN_SELL          # (changed back, not earned)
	GameState.credits_changed.emit(GameState.credits)
	GameState.log_msg("The cashier takes %d Coins and pays out %s." % [n, GameData.fmt_credits(n * GameState.COIN_SELL)], GameState.COL_GOOD)
	return ""


## {"type":"prize_buy", "hull": id}: package 63 (Luz): a hull the Grand Centauria gives for Coins (its "casino_prize",
## the Earthworks 190SL). It comes with its standard fit and stands in Centauria's hangar afterwards.
func _c_prize_buy(c: Dictionary) -> String:
	var e := _need_service()
	if e != "":
		return e
	var st := docked_station()
	if not st.get("city", false) or String(st.get("name", "")) != "Centauria":
		return "There is no cashier here."
	var hid := String(c.get("hull", ""))
	var price := int(GameData.hulls.get(hid, {}).get("casino_prize", 0))
	if price <= 0:
		return "The house has no such prize."
	if GameState.coins < price:
		return "Not enough Coins (%s)." % GameData.fmt_int(price)
	GameState.coins -= price
	var preset := "std_" + hid
	var f: ShipFitting = GameState.create_from_preset(preset, "player") if GameData.presets.has(preset) else GameState.create_fit(hid, {}, "player")
	var count := 1
	for o in GameState.fleet:
		if o.hull_id == hid:
			count += 1
	f.ship_name = String(GameData.hulls[hid]["name"]) if count == 1 else "%s %d" % [GameData.hulls[hid]["name"], count]
	f.system_id = GameState.current_system
	f.docked_at = st["id"]
	f.position = st["pos"]
	GameState.add_ship(f)
	GameState.crew_fill_required(f)
	GameState.log_msg("The house hands you the keys: %s stands in Centauria's hangar (Hangar → Board)." % f.ship_name, GameState.COL_GOOD)
	return ""


## Package 62, part 2 (Luz): {"type":"slot_spin", "stake"}: one pull at the machine you sit at. The stake goes, the
## reels are rolled (your Dexterity and the perk Lucky Hand nudge them now and then), the win is paid, the house's
## jackpot grows; the machine's window shows it.
func _c_slot_spin(c: Dictionary) -> String:
	var CasinoD = load("res://data/casino.gd")
	var g = _ground()
	if g == null or g.minigame == null or not g.minigame.has_method("slot_result"):
		return "No machine."
	var stake := int(c.get("stake", 1))
	if not stake in CasinoD.SLOT_STAKES:
		return "The machine takes 1, 5 or 25 Coins."
	if g.minigame.busy():
		return "The reels are still turning."
	if GameState.coins < stake:
		return "Not enough Coins. The cashier is in the lobby."
	var res: Dictionary = CasinoD.spin(GameState.casino_rng(), CasinoD.slot_luck(GameState.pilot_attr("dexterity"), GameState.has_perk(CasinoD.PERK)), stake, GameState.casino_jackpot)
	GameState.coins += int(res["win"]) - stake
	GameState.casino_book(stake, int(res["win"]))
	if bool(res["jackpot"]):
		GameState.log_msg("JACKPOT at the Grand Centauria: %d Coins." % int(res["win"]), GameState.COL_GOOD)
		GameState.casino_jackpot = CasinoD.JACKPOT_START
	else:
		GameState.casino_jackpot += maxi(1, int(ceil(stake * CasinoD.JACKPOT_SHARE)))
	g.minigame.slot_result(res)
	return ""


## {"type":"roulette_bet", "seat", "key", "chip"}: a seat puts Coins on a field of the cloth (chip below 1: takes
## the bet off it). {"type":"roulette_clear", "seat"}: all of a seat's bets off. The seat is there for co-op.
func _c_roulette_bet(c: Dictionary) -> String:
	var g = _ground()
	if g == null or g.minigame == null or not g.minigame.has_method("spin_result"):
		return "No roulette table."
	return g.minigame.place(int(c.get("seat", 0)), String(c.get("key", "")), int(c.get("chip", 0)))


func _c_roulette_clear(c: Dictionary) -> String:
	var g = _ground()
	if g == null or g.minigame == null or not g.minigame.has_method("spin_result"):
		return "No roulette table."
	g.minigame.clear(int(c.get("seat", 0)))
	return ""


## {"type":"roulette_spin"}: no more bets. Your stake goes, the wheel turns (with a kind hand the ball hops one
## pocket on), what your bets give back is paid; the table's window shows it.
func _c_roulette_spin(_c: Dictionary) -> String:
	var CasinoD = load("res://data/casino.gd")
	var g = _ground()
	if g == null or g.minigame == null or not g.minigame.has_method("spin_result"):
		return "No roulette table."
	var tb = g.minigame
	if String(tb.state) != "bet":
		return "The wheel is turning."
	var both: bool = bool(tb.get("two"))
	var staked: int = tb.total(0)
	var staked2: int = tb.total(1) if both else 0
	if staked + staked2 <= 0:
		return "Place a bet first."
	if staked > GameState.coins or staked2 > GameState.coins_of(1):
		return "Not enough Coins. The cashier is in the lobby."
	var bets: Dictionary = tb.seats[0]["bets"]
	if both:                                                 # split screen: the wheel's luck looks at what both of you have on the cloth
		bets = bets.duplicate()
		for k2 in tb.seats[1]["bets"]:
			bets[k2] = int(bets.get(k2, 0)) + int(tb.seats[1]["bets"][k2])
	var roll: Dictionary = CasinoD.roll(GameState.casino_rng(), CasinoD.wheel_luck(GameState.pilot_attr("dexterity"), GameState.has_perk(CasinoD.PERK)), bets)
	var back: int = CasinoD.settle(tb.seats[0]["bets"], int(roll["n"]))
	GameState.coins += back - staked
	if both:                                                 # … and each is paid into their own Coins
		GameState.add_coins(1, int(CasinoD.settle(tb.seats[1]["bets"], int(roll["n"]))) - staked2)
	GameState.casino_book(staked, back)
	tb.spin_result(int(roll["n"]), int(roll["from"]), back)
	return ""


## Package 62, part 3 (Luz): blackjack. {"type":"bj_bet", "seat", "chip"}: a seat puts Coins on its box (chip below
## 1: takes its stake back). {"type":"bj_deal"}: your stake goes, the cards are dealt. {"type":"bj_move", "seat",
## "move": "hit" | "stand" | "double"}: a seat's move in its turn. The seat is there for co-op.
func _bj_table():
	var g = _ground()
	return g.minigame if g != null and g.minigame != null and g.minigame.has_method("is_blackjack") else null


func _c_bj_bet(c: Dictionary) -> String:
	var tb = _bj_table()
	return "No blackjack table." if tb == null else String(tb.bet(int(c.get("seat", 0)), int(c.get("chip", 0))))


func _c_bj_deal(_c: Dictionary) -> String:
	var tb = _bj_table()
	return "No blackjack table." if tb == null else String(tb.deal())


func _c_bj_move(c: Dictionary) -> String:
	var tb = _bj_table()
	return "No blackjack table." if tb == null else String(tb.move(int(c.get("seat", 0)), String(c.get("move", ""))))


## … and poker. {"type":"poker_sit", "seat", "buyin"}: you buy in for Coins (again once your chips are gone).
## {"type":"poker_move", "seat", "move": "fold" | "call" | "raise" | "allin", "to"}: a seat's move in its turn
## ("to": what a raise goes to in this round). {"type":"poker_next"}: on to the next hand. {"type":"poker_leave",
## "seat"}: you stand up, your chips become Coins again.
func _poker_table():
	var g = _ground()
	return g.minigame if g != null and g.minigame != null and g.minigame.has_method("is_poker") else null


func _c_poker_sit(c: Dictionary) -> String:
	var tb = _poker_table()
	return "No poker table." if tb == null else String(tb.sit(int(c.get("seat", 0)), int(c.get("buyin", 0))))


func _c_poker_move(c: Dictionary) -> String:
	var tb = _poker_table()
	return "No poker table." if tb == null else String(tb.move(int(c.get("seat", 0)), String(c.get("move", "")), int(c.get("to", 0))))


func _c_poker_next(_c: Dictionary) -> String:
	var tb = _poker_table()
	return "No poker table." if tb == null else String(tb.next())


func _c_poker_leave(_c: Dictionary) -> String:
	var tb = _poker_table()
	return "No poker table." if tb == null else String(tb.stand_up())


## Package 62b (Luz): the bets on The Track. {"type":"race_bet", "seat", "kind": "win" | "place" | "exacta", "a",
## "b", "stake"}: a ticket on the race that takes bets now (racer `a` of its card, 0 … 5; an exacta: `a` first, `b`
## second); the stake goes, the odds of the moment stand on it. {"type":"race_collect", "seat"}: the counter pays
## the tickets that are decided. {"type":"race_wait"}: in the cinema on to the race's start, or to its end.
func _c_race_bet(c: Dictionary) -> String:
	var RD = load("res://data/races.gd")
	var g = _ground()
	if g == null or String(g.level) != "zcasino":
		return "There is no betting counter here."
	var seat := int(c.get("seat", 0))
	var kind := String(c.get("kind", ""))
	var stake := int(c.get("stake", 0))
	var n := int(RD.next_open(RD.clock())["n"])
	var r: Dictionary = RD.race(n)
	var o: float = RD.odds(r, kind, int(c.get("a", -1)), int(c.get("b", -1))) if RD.KINDS.has(kind) else 0.0
	if o <= 0.0:
		return "No such bet."
	if stake <= 0:
		return "How many Coins?"
	var on := 0
	for b in GameState.race_bets:
		if int(b["n"]) == n and int(b.get("seat", 0)) == seat:
			on += int(b["stake"])
	if on + stake > RD.LIMIT:
		return "The limit is %d Coins a race." % RD.LIMIT
	if GameState.coins < stake:
		return "Not enough Coins. The cashier is in the lobby."
	GameState.coins -= stake
	GameState.race_bets.append({"n": n, "kind": kind, "a": int(c.get("a", -1)), "b": int(c.get("b", -1)), "stake": stake, "odds": o, "seat": seat})
	return ""


func _c_race_collect(c: Dictionary) -> String:
	var RD = load("res://data/races.gd")
	var d: Dictionary = RD.due(GameState.race_bets, RD.clock(), int(c.get("seat", 0)))
	if int(d["count"]) == 0:
		return "No ticket to pay."
	GameState.race_bets = d["keep"]
	GameState.coins += int(d["back"])
	GameState.casino_book(int(d["staked"]), int(d["back"]))
	GameState.log_msg("The Track: %d of %d tickets won, %d Coins paid." % [int(d["won"]), int(d["count"]), int(d["back"])], GameState.COL_GOOD if int(d["back"]) > 0 else GameState.COL_INFO)
	return ""


func _c_race_wait(_c: Dictionary) -> String:
	var RD = load("res://data/races.gd")
	var ph: Dictionary = RD.phase(RD.clock())
	if String(ph["state"]) == "result":
		return "The race is over."
	GameState.race_shift += float(ph["left"]) + 0.05
	return ""


## Package 62a, part 2 (Luz): {"type":"col_register"}: you sign up at the Colosseum's registration (once, free, under
## your pilot's name). The fighters' gate stands open to you from then on.
func _c_col_register(_c: Dictionary) -> String:
	var g = _ground()
	if g == null or String(g.level) != "zcolin":
		return "There is no registration here."
	if GameState.col_registered:
		return "You are signed up already."
	GameState.col_registered = true
	GameState.log_msg("You are signed up at the Colosseum as %s." % GameState.pilot_name, GameState.COL_GOOD)
	return ""


## Package 62a, part 3 (Luz): the Colosseum's choices, by seat (for co-op). {"type":"col_play", "play"}: the way to
## play (only "single" is open yet). {"type":"col_equip", "place", "idx", "id"}: a piece of the house's gear into a
## place of your fit ("" takes it off); the fit must stay within your gear points. {"type":"col_mode", "mode"}: the
## mode (only "king" is open yet). {"type":"col_ready"}: you are ready for the arena.
func _c_col_play(c: Dictionary) -> String:
	var CD = load("res://data/colosseum.gd")
	for p in CD.PLAY:
		if String(p[0]) == String(c.get("play", "")):
			if not bool(p[3]):
				return "%s: coming soon." % String(p[1])
			if String(p[0]) == "split" and not (Players.split and GameState.has_pilot2()):
				return "Split screen needs a second player: their device and their pilot first."
			GameState.col_state()["play"] = String(p[0])
			if GameState.has_pilot2():
				# "Split screen" is always both players' way to play; picking another way for yourself ends it for both
				var oth: Dictionary = GameState.col_other()
				if String(p[0]) == "split":
					oth["play"] = "split"
				elif String(oth.get("play", "")) == "split":
					oth["play"] = "single"
			if String(p[0]) != "split" and Players.guest:          # (a split screen asked for here, and now you play alone: it is over)
				Players.stop_split()
			return ""
	return "No such way to play."


func _c_col_equip(c: Dictionary) -> String:
	var CD = load("res://data/colosseum.gd")
	var st: Dictionary = GameState.col_state()
	var fk := "fit2" if int(c.get("seat", 0)) == 1 else "fit"      # split screen: seat 1 is the second player, with a fit and the same gear points of their own
	var res: Dictionary = CD.equip(st[fk], String(c.get("place", "")), int(c.get("idx", 0)), String(c.get("id", "")), CD.budget(st), int(CD.RANKS[CD.rank(st)]["q"]))
	if String(res["err"]) == "":
		st[fk] = res["fit"]
	return String(res["err"])


func _c_col_mode(c: Dictionary) -> String:
	var CD = load("res://data/colosseum.gd")
	for m in CD.MODES:
		if String(m["id"]) == String(c.get("mode", "")):
			if not bool(m["open"]):
				return "%s: coming soon." % String(m["name"])
			CD.switch_mode(GameState.col_state(), String(m["id"]))      # (part 5: every mode has a run of its own)
			GameState.col_state()                                        # (… and its fit in shape)
			return ""
	return "No such mode."


## Part 5: {"type":"col_team", "id"}: one who may stand beside you in Team Deathmatch steps into your team, or out
## of it (two stand beside you).
func _c_col_team(c: Dictionary) -> String:
	var CD = load("res://data/colosseum.gd")
	var st: Dictionary = GameState.col_state()
	var id := String(c.get("id", ""))
	if not (CD.mates(st) as Array).any(func(m): return String(m["id"]) == id):
		return "Nobody of that name stands ready."
	var cur: Array = (CD.team(st) as Array).map(func(m): return String(m["id"]))
	if id in cur:
		cur.erase(id)
		st["team"] = cur
		st["team_open"] = true                            # (a place stands free until you fill it)
		return ""
	if cur.size() >= CD.TEAM_SIZE and not bool(st.get("team_open", false)):
		return "Two stand beside you already. Send one away first."
	cur = (st.get("team", []) as Array).duplicate()
	cur.append(id)
	st["team"] = cur.slice(0, CD.TEAM_SIZE)
	st["team_open"] = (st["team"] as Array).size() < CD.TEAM_SIZE
	return ""


## Part 4: {"type":"col_fight_end", "won"}: a fight in the hologram is over. Won: Coins, gear points and rank points,
## the run goes on. Lost: the run's gear points are gone, the round is 1 again, the rank stays. What happened is
## kept in the Colosseum's state ("last") for the picture after the fight.
func _c_col_fight_end(c: Dictionary) -> String:
	var CD = load("res://data/colosseum.gd")
	var g = _ground()
	if g == null or String(g.level) != "zcolvr":
		return "There is no fight."
	var st: Dictionary = GameState.col_state()
	var res: Dictionary = CD.settle(st, bool(c.get("won", false)))
	GameState.coins += int(res["coins"])
	if GameState.col_two():
		GameState.add_coins(1, int(res["coins"]))             # (split screen: the second player fought too: the same Coins into their own purse)
		GameState.col_rank_other(int(res["xp"]), true, bool(res["won"]))      # (… and the rank points for their own rank)
	st["last"] = res
	if bool(res["won"]):
		GameState.log_msg("The Colosseum: round %d won. %d Coins, %d gear points, %d rank points." % [int(res["round"]), int(res["coins"]), int(res["points"]), int(res["xp"])], GameState.COL_GOOD)
	else:
		GameState.log_msg("The Colosseum: beaten in round %d. The run's gear points are gone, your rank stays." % int(res["round"]), GameState.COL_INFO)
	if bool(res["rank_up"]):
		GameState.log_msg("The Colosseum: a new rank: %s." % String(CD.RANKS[CD.rank(st)]["name"]), GameState.COL_GOOD)
	return ""


## Package 62a, part 7 (Luz): Survivor. {"type":"sv_pick", "seat", "i"}: with a new level, the card `i` of the three
## on the table is taken.
func _c_sv_pick(c: Dictionary) -> String:
	var g = _ground()
	if g == null or g.survivor == null or not is_instance_valid(g.survivor):
		return "There is no run."
	return String(g.survivor.pick(int(c.get("i", -1))))


## {"type":"sv_weapon", "seat", "id"}: the weapon you begin a run of Survivor with (picked in the fighters' room).
func _c_sv_weapon(c: Dictionary) -> String:
	var SV = load("res://data/survivor.gd")
	var id := String(c.get("id", ""))
	if not SV.WEAPONS.has(id):
		return "No such weapon."
	if not SV.owned(GameState.col_state(), id):
		return "%s is still locked: the Survivor console in the lobby." % String(SV.WEAPONS[id]["name"])
	if not SV.can_begin(GameState.col_state(), id):
		return "%s is a weapon for the end of a run: its card comes from level %d on." % [String(SV.WEAPONS[id]["name"]), int(SV.WEAPONS[id]["from"])]
	if int(c.get("seat", 0)) == 1:                       # split screen: the second player's first weapon (one of the two carries a weapon, never both)
		if id == SV.first_weapon(GameState.col_state()):
			return "The first player begins with %s." % String(SV.WEAPONS[id]["name"])
		SV.record(GameState.col_state())["weapon2"] = id
		return ""
	SV.record(GameState.col_state())["weapon"] = id
	return ""


## Part 7c-3. {"type":"sv_stage", "seat", "id"}: the stage of the next run of Survivor (picked in the fighters' room).
func _c_sv_stage(c: Dictionary) -> String:
	var SV = load("res://data/survivor.gd")
	var id := String(c.get("id", ""))
	for s in SV.STAGES:
		if String(s["id"]) == id:
			if not bool(s["open"]):
				return "That stage is still to come."
			if not SV.stage_open(GameState.col_state(), id):
				return "%s opens once you have %s." % [String(s["name"]), String(s.get("need_text", "come further"))]
			SV.record(GameState.col_state())["stage"] = id
			return ""
	return "No such stage."


## {"type":"sv_buy", "seat", "what", "id"}: something is bought for cores at the Survivor console in the lobby, for
## good: "unlock" (id: a weapon or a bonus), "tune" (id: a figure of the fine tuning, a rank), "reroll", "revive".
func _c_sv_buy(c: Dictionary) -> String:
	var SV = load("res://data/survivor.gd")
	if not GameState.col_registered:
		return "Sign up at the registration first."
	var what := String(c.get("what", ""))
	var id := String(c.get("id", ""))
	var st: Dictionary = GameState.col_state()
	var cost: int = SV.price(st, what, id)
	var e := String(SV.buy(st, what, id))
	if e != "":
		return e
	var named := id
	match what:
		"unlock":
			named = String((SV.WEAPONS if SV.WEAPONS.has(id) else SV.BONI)[id]["name"])
		"tune":
			named = "%s, rank %d" % [String(SV.TUNE[id]["name"]), SV.tune_rank(st, id)]
		"reroll":
			named = "a reroll a run (%d now)" % int(SV.record(st)["reroll"])
		"revive":
			named = "the last chance"
	GameState.log_msg("Survivor console: %s, for %d cores." % [named, cost], GameState.COL_GOOD)
	GameState.sv_give_suit()                                  # (part 10c: with the last thing bought, the Regalia)
	return ""


## {"type":"sv_reroll", "seat"}: the three cards of a new level are drawn anew (rerolls are bought at the console).
func _c_sv_reroll(_c: Dictionary) -> String:
	var g = _ground()
	if g == null or g.survivor == null or not is_instance_valid(g.survivor):
		return "There is no run."
	return String(g.survivor.reroll())


## {"type":"sv_end"}: a run of Survivor is over (you are out, or you held the stage to its end): Coins and rank
## points by the time you held out, the best time kept.
func _c_sv_end(_c: Dictionary) -> String:
	var g = _ground()
	if g == null or g.survivor == null or not is_instance_valid(g.survivor):
		return "There is no run."
	var sv = g.survivor
	if not bool(sv.over):
		return "The run is not over."
	if bool(sv.run.get("paid", false)):
		return "That run is settled."
	var SV = load("res://data/survivor.gd")
	var CD = load("res://data/colosseum.gd")
	var st: Dictionary = GameState.col_state()
	var before: int = CD.rank(st)
	sv.run["slain"] = sv.slain()                              # (part 10a) what it put out, kind by kind: into the collection
	var res: Dictionary = SV.settle(st, sv.run, bool(sv.survived))
	sv.run["paid"] = true
	GameState.coins += int(res["coins"])
	if GameState.col_two():
		GameState.add_coins(1, int(res["coins"]))             # (split screen: the same Coins into the second player's own purse)
		GameState.col_rank_other(int(res["xp"]), false, false)      # (… and the rank points for their own rank)
	st["sv_last"] = res
	GameState.log_msg("Survivor: %s on %s. %d Coins, %d rank points, %d cores." % [SV.time_text(float(res["time"])), String(SV.stage(String(res["stage"]))["name"]), int(res["coins"]),
		int(res["xp"]), int(res["cores"])], GameState.COL_GOOD)
	if CD.rank(st) > before:
		GameState.log_msg("The Colosseum: a new rank: %s." % String(CD.RANKS[CD.rank(st)]["name"]), GameState.COL_GOOD)
	for opened in res.get("opened", []):
		GameState.log_msg("Survivor: a new stage is open to you: %s." % String(opened), GameState.COL_GOOD)
	var met: Array = res.get("new_foes", [])                  # (part 10a) kinds put out for the first time
	if not met.is_empty():
		var names: Array = met.map(func(k): return String(SV.FOES[String(k)]["name"]))
		GameState.log_msg("Collection: Survivor: %s recorded." % ", ".join(names), GameState.COL_GOOD)
		GameState.codex.event("collection")
	return ""


func _c_col_ready(_c: Dictionary) -> String:
	var CD = load("res://data/colosseum.gd")
	var st: Dictionary = GameState.col_state()
	if not GameState.col_registered:
		return "Sign up at the registration first."
	if String(st.get("mode", "")) == "":
		return "Pick a mode first."
	if CD.fit_cost(st["fit"]) > CD.budget(st):
		return "Your fit costs more gear points than you have."
	if GameState.col_two() and CD.fit_cost(st["fit2"]) > CD.budget(st):
		return "The second player's fit costs more gear points than there are."
	if String(st["mode"]) == "team" and bool(st.get("team_open", false)):
		return "Your team is not full: pick who stands beside you."
	return ""


func _need_coins(c: Dictionary) -> String:
	var e := _need_service()
	if e != "":
		return e
	var st := docked_station()
	if not st.get("city", false) or String(st.get("name", "")) != "Centauria":
		return "There is no cashier here."
	if int(c.get("n", 0)) <= 0:
		return "How many Coins?"
	return ""


func _c_paint_ship(c: Dictionary) -> String:
	var e := _need_service()
	if e != "":
		return e
	var st := docked_station()
	if not st.get("city", false) or String(st.get("name", "")) != "Centauria":
		return "There is no paint shop here."
	var id := String(c.get("paint", ""))
	if id != "" and not PaintDataC.PAINTS.has(id):
		return "Unknown paint."
	var f = null
	for s in GameState.fleet:
		if int(s.uid) == int(c.get("uid", -1)) and String(s.docked_at) == String(st.get("id", "")):
			f = s
	if f == null:
		return "That ship does not stand in Centauria's hangar."
	if String(f.paint) == id:
		return "%s wears that already." % String(f.ship_name)
	var price := GameState.rep.buy_price(PaintDataC.price(int(GameData.hulls.get(String(f.hull_id), {}).get("size", 1)), id), docked_faction()) if id != "" else 0
	if not GameState.spend(price):
		return "Not enough credits (%s)." % GameData.fmt_credits(price)
	f.paint = id
	if id == "":
		GameState.log_msg("%s is back in the factory's colours." % String(f.ship_name), GameState.COL_GOOD)
	else:
		GameState.log_msg("%s wears %s now: %s paid to Second Skin." % [String(f.ship_name), PaintDataC.name_of(id), GameData.fmt_credits(price)], GameState.COL_GOOD)
	return ""


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
	price = int(round(GameState.rep.buy_price(price, docked_faction()) * GameState.senate.hull_mult(hid, docked_faction()) * GameState.curia.hull_mult(hid, docked_faction())))
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
	GameState.log_msg("%s purchased: waiting in the hangar (Hangar → Board)." % f.ship_name, GameState.COL_GOOD)
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
		return "Passengers are using this cabin: deliver them first."
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
		return "Passengers are using this cabin: deliver them first."
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
		return "Sealed cargo cannot be jettisoned: abandon the contract instead."
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
	if GameData.commodities.get(cid, {}).get("category", "") == "munitions":
		return "Munitions are sold at the Munitions Depot."
	if not GameData.is_tradeable(cid) or Market.buy_price(st, cid) < 0:
		return "Not on offer here."
	# package 42b: from the stock – it runs out, and the price rises as you buy
	var fac := GameState.rep.price_factor(docked_faction(), "buy") * (1.0 - GameState.skill_bonus("trading") * 0.5)
	var max_space := int(floor(f.free_for(cid) / GameData.item_volume(cid)))
	var max_stock := int(floor(Market.stock(st, cid)))
	var amount := mini(int(c.get("amount", 1)), mini(max_space, max_stock))
	while amount > 0 and maxi(int(round(Market.quote_buy(st, cid, amount) * fac)), 1) > GameState.credits:
		amount -= maxi(1, amount / 8)
	if amount <= 0:
		return "Purchase not possible (cargo space, credits or stock)."
	var price := maxi(int(round(Market.quote_buy(st, cid, amount) * fac)), 1)
	GameState.spend(price)
	f.add_cargo(cid, amount)
	Market.bought(st, cid, amount)
	Economy.on_trade(st, cid, float(price), false)             # package 42c
	GameState.skill_xp("trading", float(price) / 500.0)      # package 29
	GameState.note_stat("markets", String(st["id"]))                    # package 30
	GameState.count_stat("turnover", float(price))
	return ""


## {"type":"market_sell", "item": String, "amount": float (-1 = all)}
## Package 51 (0.7.51.4): what the clinic asks to treat what is hurt.
func clinic_price() -> int:
	return int(ceil(maxf(0.0, 100.0 - float(GameState.gear.health)) * 12.0))


func _c_clinic_heal(_c: Dictionary) -> String:
	var e := _need_service()
	if e != "":
		return e
	var price := GameState.rep.buy_price(clinic_price(), docked_faction())
	if price <= 0:
		return "Nothing to treat."
	if not GameState.spend(price):
		return "Not enough credits."
	GameState.gear.health = 100.0
	GameState.log_msg("Treated at the clinic: you feel well again.", GameState.COL_GOOD)
	return ""


## 0.7.52.20 (package 52a): crew that died on foot, on all your ships – [[ship, member], …].
func dead_crew() -> Array:
	var out: Array = []
	for f in GameState.fleet:
		for m in f.crew_members():
			if bool(m.get("dead", false)):
				out.append([f, m])
	return out


func revive_fee(m: Dictionary) -> int:
	return int(CrewData.REVIVE_FEE.get(String(m.get("quality", "F")), 1000))


## {"type":"clinic_revive", "id": crew id} – 0.7.52.20 (Luz): the clinic brings a crew member back who died on foot,
## for a fee by their quality.
func _c_clinic_revive(c: Dictionary) -> String:
	var e := _need_service()
	if e != "":
		return e
	for pair in dead_crew():
		var m: Dictionary = pair[1]
		if int(m.get("id", -1)) == int(c.get("id", -2)):
			var price := GameState.rep.buy_price(revive_fee(m), docked_faction())
			if not GameState.spend(price):
				return "Not enough credits."
			m["dead"] = false
			(pair[0] as ShipFitting).mark_dirty()
			GameState.log_msg("%s is back: the clinic brought them round." % String(m.get("name", "")), GameState.COL_GOOD)
			return ""
	return "Nobody of that name lies here."


## Package 51: buys a piece of personal gear at the Gear shop – into the pockets.
func _c_gear_buy(c: Dictionary) -> String:
	var e := _need_service()
	if e != "":
		return e
	var st := docked_station()
	var id := String(c.get("id", ""))
	if not GearShop.GearData.valid(id) or not GearShop.sells(st, id):
		return "Not on offer here."
	var own := String(GearShop.GearData.base(id).get("faction", ""))      # 0.7.52.14: a power's armour – for its friends
	if own != "" and not GameState.rep.at_least(own, "friendly"):
		return "The %s sells its %s only to Friendly pilots (yours: %s)." % [FactionData.short_of(own), String(GearShop.GearData.base(id)["name"]), GameState.rep.tier_name(own)]
	var price := GameState.rep.buy_price(GearShop.GearData.price(id), docked_faction())
	if GameState.credits < price:
		return "Not enough credits."
	if GameState.gear.free_places() == 0 and GameState.gear.count(id) % GearShop.GearData.stack_max(id) == 0:
		return "Your pockets are full: sell something or store it in the ship's locker."
	if GameState.gear.add_item(id, 1) > 0:
		return "Your pockets are full."
	GameState.spend(price)
	GameState.log_msg("Bought: %s." % GearShop.GearData.display_name(id), GameState.COL_GOOD)
	return ""


## Package 51: sells what is in a pocket (the whole stack) for half the price.
func _c_gear_sell(c: Dictionary) -> String:
	var e := _need_service()
	if e != "":
		return e
	var i := int(c.get("slot", -1))
	var g = GameState.gear
	if i < 0 or i >= g.inv.size() or (g.inv[i] as Dictionary).is_empty():
		return "Nothing there."
	var p: Dictionary = g.inv[i]
	var id := String(p["id"])
	var got := int(round(float(GearShop.GearData.price(id)) * GearShop.SELL_SHARE)) * int(p["n"])
	g.inv[i] = {}
	GameState.add_credits(got)
	GameState.log_msg("Sold: %s for %s." % [GearShop.GearData.display_name(id), GameData.fmt_credits(got)], GameState.COL_GOOD)
	return ""


func _c_market_sell(c: Dictionary) -> String:
	var e := _need_service()
	if e != "":
		return e
	var st := docked_station()
	var f := _fit()
	var cid: String = c["item"]
	if GameData.commodities.get(cid, {}).get("category", "") == "munitions":
		return "Munitions are taken back at the Munitions Depot."
	if not GameData.is_tradeable(cid):
		return "This station does not buy that."
	var have := float(f.cargo.get(cid, 0.0))
	var n := float(c.get("amount", -1.0))
	var amount := have if n < 0.0 else minf(n, have)
	if amount <= 0.0:
		return "Nothing to sell."
	f.remove_cargo(cid, amount)
	# package 42b: into the station's stock – the more you sell, the less it pays
	var earn := int(round(GameState.rep.sell_price(Market.quote_sell(st, cid, amount), docked_faction()) * (1.0 + GameState.skill_bonus("trading") * 0.5)))
	Economy.on_trade(st, cid, float(earn), true)               # package 42c
	Market.sold(st, cid, amount)
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
		return "Lock a ship first: the wingmen attack your active target."
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
		return "The platform is taken: unload it first."
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
		return "Nothing on the platform: put a Hadrian S ship on it in the hangar." if cit.platform_lost.is_empty() else "The platform ship was destroyed: recall it at a station's hangar."
	if cit.platform_out:
		return "The platform ship is already out."
	if GameState.platform_pilot(cit).is_empty():
		return "No platform pilot aboard: a Co-Pilot with the perk Wingman flies it."
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


## {"type":"fall_decide", "accept": bool} – 0.7.53.14: buy back the gear after going down on foot, or keep the basic kit
func _c_fall_decide(c: Dictionary) -> String:
	return GameState.fall_decide(bool(c.get("accept", false)))


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
	var lk := GameState.crew_hire_locked()
	if lk != "":
		return lk
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
		return "Passengers are using this cabin: deliver them first."
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
		GameState.log_msg("Crucible took your %s; refining, then ready to collect here." % GameData.item_name(ore), GameState.COL_GOOD)
	return err


## {"type":"job_collect", "id": int (-1 = everything ready here), "lane": "" | "refinery" | "fab"} – finished
## refined goods and components into the hold (Luz, 18 Nov 2026).
func _c_job_collect(c: Dictionary) -> String:
	var e := _need_service()
	if e != "":
		return e
	var st := docked_station()
	var f := _fit()
	var id := int(c.get("id", -1))
	var got := 0.0
	var any := false
	for j in GameState.jobs_ready(String(st["id"]), String(c.get("lane", ""))):
		if id >= 0 and int(j.get("id", 0)) != id:
			continue
		any = true
		var name := GameData.item_name(String(j["out_id"]))
		var n := GameState.collect_job(f, j)
		got += n
		if n > 0.0:
			GameState.log_msg("Collected %.0f %s into the hold." % [n, name], GameState.COL_GOOD)
	if not any:
		return "Nothing ready to collect."
	if got <= 0.0:
		return "No room in the cargo hold."
	return ""


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
		GameState.log_msg("Molten Lotus started: %s; ready in %s (then in station storage)." % [GameData.module_name(Industry.last_built), Industry.fmt_secs(Industry.station_build_time(mid))], GameState.COL_GOOD)
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
		m = _find_mission(GameState.ground_offers_for(GameState.current_system, st), String(c["id"]))   # 0.7.53.16
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


## {"type":"mission_share", "id": String} – split screen: one of your contracts offered to the other player.
func _c_mission_share(c: Dictionary) -> String:
	var m := _find_mission(GameState.missions, String(c["id"]))
	if m.is_empty():
		return "Unknown contract."
	return GameState.share_mission(m)


## {"type":"mission_share_accept", "id": String} – … and taken by the one it was offered to (again: "decline").
func _c_mission_share_accept(c: Dictionary) -> String:
	var m := _find_mission(GameState.shares_for(GameState.acting), String(c["id"]))
	if m.is_empty():
		return "That contract is not on offer any more."
	return GameState.share_accept(m)


func _c_mission_share_decline(c: Dictionary) -> String:
	var m := _find_mission(GameState.shares_for(GameState.acting), String(c["id"]))
	if not m.is_empty():
		GameState.share_decline(m)
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
			return "Ship delivered: dock at %s to board it." % st["name"]
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
	GameState.log_msg("Debug: next to %s (%s)." % [m["name"], Universe.body_type(String(m["type"]))["name"]])
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


# ---------------------------------------------------------------- Package 39b: the Curia, Heimkehr

func _c_curia_tithe(_c: Dictionary) -> String:
	return GameState.curia.tithe()


## {"type":"curia_petition", "edict": id}
func _c_curia_petition(c: Dictionary) -> String:
	return GameState.curia.petition(String(c.get("edict", "")))


func _c_curia_indulgence(_c: Dictionary) -> String:
	return GameState.curia.indulgence()


func _c_curia_relics(_c: Dictionary) -> String:
	return GameState.curia.give_relics(_fit())


## {"type":"curia_audience", "what": "greet"|"edict"|"bless", "edict": id} – 54c (Luz): before the Hierarch
func _c_curia_audience(c: Dictionary) -> String:
	return GameState.curia.audience(String(c.get("what", "greet")), String(c.get("edict", "")))


## {"type":"exchange", "what": "data"|"sell_em"|"buy_em", "n": 1} – package 39c, the Research Exchange
func _c_exchange(c: Dictionary) -> String:
	return GameState.exchange(String(c.get("what", "data")), int(c.get("n", 1)))


## {"type":"debug_durchbruch"} – to Durchbruch (docked at the Meridian Sphere)
func _c_debug_durchbruch(_c: Dictionary) -> String:
	var sid := Universe.special_system("durchbruch")
	if sid < 0:
		return "No Durchbruch in this cluster."
	return _c_debug_teleport({"system": sid})


## {"type":"debug_research", "n": 5} – research data
func _c_debug_research(c: Dictionary) -> String:
	GameState.research_data += int(c.get("n", 5))
	return ""


## {"type":"fabricate", "item": "circuits", "n": 1} – package 41: components at the station's fabricators
func _c_fabricate(c: Dictionary) -> String:
	var e := _need_service()
	if e != "":
		return e
	return Industry.fabricate(_fit(), docked_station(), String(c.get("item", "")), int(c.get("n", 1)))


## {"type":"debug_gas_giant"} – package 41: into the harvest band of the next giant in this system (moving along it)
var _debug_gas_i := -1


func _c_debug_gas_giant(_c: Dictionary) -> String:
	var e := _need_world()
	if e != "":
		return e
	var gs: Array = world.layout["planets"].filter(func(p): return Universe.GAS_YIELDS.has(String(p["type"])))
	if gs.is_empty():
		return "No giant in this system."
	_debug_gas_i = (_debug_gas_i + 1) % gs.size()
	var p: Dictionary = gs[_debug_gas_i]
	var f := _fit()
	f.docked_at = ""
	var dir := (p["pos"] as Vector2).normalized().rotated(0.6)
	var pos: Vector2 = (p["pos"] as Vector2) + dir * float(p["radius"]) * 1.15
	world.player.position = pos
	f.position = pos
	world.player.velocity = dir.orthogonal() * 120.0
	world.player.order = {"type": "idle"}
	world.center_on_player()
	GameState.log_msg("Debug: in the harvest band of %s." % p["name"])
	return ""


## {"type":"debug_special", "special": "altwerft"|…} – 39d: to a special system (docked at its first station)
func _c_debug_special(c: Dictionary) -> String:
	var sid := Universe.special_system(String(c.get("special", "")))
	if sid < 0:
		return "No such system in this cluster."
	return _c_debug_teleport({"system": sid})


## {"type":"debug_gold_wreck"} – package 57: out of the dock, next to the next wreck of the Gold Fleet in this system
var _debug_gw_i := -1


func _c_debug_gold_wreck(_c: Dictionary) -> String:
	var e := _need_world()
	if e != "":
		return e
	var gws: Array = Universe.get_layout(GameState.current_system).get("gold_wrecks", [])
	if gws.is_empty():
		return "No wreck of the Gold Fleet here: they lie in Beyond and Driftwood."
	_debug_gw_i = (_debug_gw_i + 1) % gws.size()
	var gw: Dictionary = gws[_debug_gw_i]
	var f := _fit()
	var mn = get_tree().current_scene
	if mn != null and "station_panel" in mn and mn.station_panel.visible:
		mn.station_panel.close()
	if f.docked_at != "" and world.player != null:
		world.player.undock()
	f.docked_at = ""
	var p: Vector2 = (gw["pos"] as Vector2) + Vector2.from_angle(float(gw["rot"]) + PI * 0.5) * float(gw["radius"]) * 1.3
	world.player.position = p
	f.position = p
	world.player.order = {"type": "idle"}
	world.center_on_player()
	GameState.log_msg("[Debug] Next to the %s: %s, stage %d (%d of %d)." % [gw["name"], gw["kind"], int(gw["stage"]), _debug_gw_i + 1, gws.size()], GameState.COL_WARN)
	return ""


## {"type":"debug_wreck_colossus"} – package 57: out of the dock, next to the next wreck colossus (a section of a Gold
## Fleet ship in the wreck belt) of this system, cycling through them
var _debug_wc_i := -1


func _c_debug_wreck_colossus(_c: Dictionary) -> String:
	var e := _need_world()
	if e != "":
		return e
	var wcs: Array = Universe.get_layout(GameState.current_system).get("colossi", []).filter(func(co): return co.has("wreck"))
	if wcs.is_empty():
		return "No wreck colossus here: they lie in the wreck belts of Beyond and Driftwood."
	_debug_wc_i = (_debug_wc_i + 1) % wcs.size()
	var co: Dictionary = wcs[_debug_wc_i]
	var f := _fit()
	var mn = get_tree().current_scene
	if mn != null and "station_panel" in mn and mn.station_panel.visible:
		mn.station_panel.close()
	if f.docked_at != "" and world.player != null:
		world.player.undock()
	f.docked_at = ""
	# beside her, a little off her flank
	var side := Vector2.from_angle(float(co["rot"]) + PI * 0.5)
	var t := 0.0
	while t < float(co["radius"]) and ColossusShape.contains(co["poly"], side * t):
		t += 20.0
	var p: Vector2 = (co["pos"] as Vector2) + side * (t + 250.0)
	world.player.position = p
	f.position = p
	world.player.order = {"type": "idle"}
	world.center_on_player()
	GameState.log_msg("[Debug] Next to %s: stage %d (%d of %d)." % [co["name"], int(co.get("stage", 0)), _debug_wc_i + 1, wcs.size()], GameState.COL_WARN)
	return ""


## {"type":"debug_prosperity", "delta": 20} – package 42: the prosperity of the current system up or down
func _c_debug_prosperity(c: Dictionary) -> String:
	var sid := GameState.current_system
	Economy.change(sid, float(c.get("delta", 20)), "debug")
	GameState.log_msg("[Debug] %s: prosperity %d, %s." % [Universe.systems[sid]["name"], int(Economy.prosperity(sid)), Economy.level_name(sid)])
	return ""


## {"type":"debug_market_age", "hours": 1} – package 42b: the stocks of every traded good as if `hours` had passed
func _c_debug_market_age(c: Dictionary) -> String:
	var dt := float(c.get("hours", 1)) * 3600.0
	for stid in GameState.market_stock:
		for cid in GameState.market_stock[stid]:
			GameState.market_stock[stid][cid][1] = float(GameState.market_stock[stid][cid][1]) - dt
	GameState.log_msg("[Debug] Markets: %.0f h passed for every traded stock." % float(c.get("hours", 1)))
	return ""


## {"type":"debug_prosperity_drift", "hours": 1} – package 42c: prosperity drifts back as if `hours` had passed
func _c_debug_prosperity_drift(c: Dictionary) -> String:
	Economy.drift(float(c.get("hours", 1)) * 3600.0)
	var sid := GameState.current_system
	GameState.log_msg("[Debug] Prosperity drifted %.0f h, %s: %d (%s)." % [float(c.get("hours", 1)), Universe.systems[sid]["name"], int(Economy.prosperity(sid)), Economy.level_name(sid)])
	return ""


## {"type":"debug_tourists"} – package 43c: a cruise liner and a sightseeing shuttle set out now
func _c_debug_tourists(_c: Dictionary) -> String:
	var e := _need_world()
	if e != "":
		return e
	var n0: int = world.traffic.tourists.size()
	world.traffic._spawn_tourist("cruise", false)
	world.traffic._spawn_tourist("tour", false)
	GameState.log_msg("[Debug] %d tourist ship(s) set out." % (world.traffic.tourists.size() - n0))
	return ""


## Package 54b (Luz): the bar games. {"type":"minigame_begin", "game", "mode", "stake", "opponent"}: the stake goes on the
## table (it must be open by your win streak and in your pocket); {"type":"minigame_end", "won": bool}: the winner takes
## the pot, the streak grows or ends; {"type":"pool_shot", "angle", "power", "spin": [x, y]}: a shot at the pool table
## (the game itself runs the balls – one command per shot, so a co-op player's shot can come the same way).
const MinigameData = preload("res://data/minigames.gd")
const MG_TIP_CHANCE := 0.35                 # a win with a stake: now and then the loser lets something slip
var mg_session := {}
var mg_last_tip := ""


## 54b (Luz): a tip from the guest you beat – an anomaly near by their scanner caught (it is revealed now), or where a
## ware is cheap and where it pays well (real prices, within two jumps). "" if nothing comes to mind.
func _mg_tip(who: String, rng: RandomNumberGenerator) -> String:
	var sid := GameState.current_system
	var kinds := ["anomaly", "trade"]
	if rng.randf() < 0.5:
		kinds.reverse()
	for k in kinds:
		if k == "anomaly":
			for s2 in Missions._systems_within(sid, 2):
				for an in Universe.get_layout(s2)["anomalies"]:
					if not bool(an["revealed"]):
						an["revealed"] = true
						GameState.anomaly_revealed.emit(s2, String(an["id"]))
						return "%s leans in: \"Out in %s my scanner caught something the others miss, %s. Worth a look.\"" % [who, Universe.systems[s2]["name"], String(an["name"])]
		else:
			var near: Array = Missions._systems_within(sid, 2)
			var here: Array = (Universe.get_layout(sid)["stations"] as Array).slice(0, 5)
			var cids: Array = GameData.commodities.keys().filter(func(c): return Market.on_market(String(c)))
			cids.shuffle()
			var best := 1.3
			var out := ""
			for cid in cids.slice(0, 24):
				for st in here:
					var a := Universe.find_station(sid, String(st["id"]))
					var bp := Market.buy_price(a, String(cid))
					if bp <= 0:
						continue
					for s3 in near:
						for st2 in (Universe.get_layout(int(s3))["stations"] as Array).slice(0, 4):
							if String(st2["id"]) == String(st["id"]):
								continue
							var b := Universe.find_station(int(s3), String(st2["id"]))
							var sp := Market.sell_price(b, String(cid))
							if sp / float(bp) > best:
								best = sp / float(bp)
								out = "%s, quietly: \"%s is cheap at %s, %d cr. At %s (%s) they pay %d for it.\"" % [who, GameData.item_name(String(cid)),
									String(a.get("name", "?")), bp, String(b.get("name", "?")), Universe.systems[int(s3)]["name"], int(sp)]
			if out != "":
				return out
	return ""


func _c_minigame_begin(c: Dictionary) -> String:
	var game := String(c.get("game", ""))
	if not MinigameData.GAMES.has(game):
		return "Unknown game."
	var stake := int(c.get("stake", 0))
	var mode := String(c.get("mode", ""))
	if MinigameData.solo(mode):
		stake = 0
	var streak := int(GameState.minigame_streak.get(game, 0))
	if stake > MinigameData.max_stake(streak):
		return "That stake opens with a longer win streak."
	if stake > GameState.credits:
		return "Not enough credits for that stake."
	if mode == "arcade":
		if GameState.credits < 1:
			return "The cabinet wants a credit."
		GameState.spend(1)                                  # 54b: 1 credit a game
	if stake > 0:
		GameState.spend(stake)
	mg_session = {"game": game, "mode": mode, "stake": stake, "opponent": c.get("opponent", {}), "place": String(c.get("place", ""))}
	return ""


func _c_minigame_end(c: Dictionary) -> String:
	if mg_session.is_empty():
		return "No game running."
	var game := String(mg_session["game"])
	var stake := int(mg_session["stake"])
	var won := bool(c.get("won", false))
	if String((mg_session.get("opponent", {}) as Dictionary).get("kind", "")) == "p2":      # split screen: the two of you: no stake, no streak
		GameState.log_msg("%s: %s wins." % [MinigameData.GAMES[game]["name"], GameState.pilot_name if won else String(GameState.pilot2.get("name", "Player 2"))], GameState.COL_GOOD)
		mg_session = {}
		return ""
	if c.has("score"):                                       # 54b: an arcade score – your best, and the cabinet's list
		var sc := int(c["score"])
		if sc > int(GameState.minigame_best.get(game, 0)):
			GameState.minigame_best[game] = sc
		var key := "rh:" + String(mg_session.get("place", ""))
		var lst: Array = (GameState.minigame_best.get(key, []) as Array).duplicate()
		lst.append(sc)
		lst.sort()
		lst.reverse()
		GameState.minigame_best[key] = lst.slice(0, 5)
		GameState.log_msg("%s: %d ore banked." % [MinigameData.GAMES[game]["name"], sc], GameState.COL_GOOD)
	if not MinigameData.solo(String(mg_session["mode"])):
		var opp: Dictionary = mg_session.get("opponent", {})
		var who := String(opp.get("name", "your opponent"))
		if String(opp.get("special", "")) != "":
			load("res://data/acquaintances.gd").played_with(String(opp["special"]))      # package 60: a game together
		mg_last_tip = ""
		if won:
			GameState.credits += int(c.get("pot", stake * 2))           # (Drift: the pot, shared on a tie)
			var trng := RandomNumberGenerator.new()
			trng.randomize()
			if stake > 0 and (trng.randf() < MG_TIP_CHANCE or bool(c.get("tip", false))):
				mg_last_tip = _mg_tip(who.split(",")[0].split(" ")[0].replace("\"", ""), trng)
				if mg_last_tip != "":
					GameState.log_msg(mg_last_tip, GameState.COL_GOOD)
			GameState.minigame_streak[game] = int(GameState.minigame_streak.get(game, 0)) + 1
			GameState.minigame_wins[game] = int(GameState.minigame_wins.get(game, 0)) + 1
			var spk := String(opp.get("special", ""))
			if spk != "":
				# package 58, part 8 (Luz): a special opponent beaten goes into the collection
				var sl: Array = GameState.collection.get("special", [])
				var key := "%s:%s" % [spk, game]
				if not key in sl:
					sl.append(key)
					GameState.collection["special"] = sl
					GameState.log_msg("Collection: %s beaten at %s. A special opponent!" % [who, String(MinigameData.GAMES[game]["name"]).to_lower()], GameState.COL_GOOD)
			GameState.log_msg("%s: you beat %s%s, %d in a row." % [MinigameData.GAMES[game]["name"], who,
				(" and take %d cr" % int(c.get("pot", stake * 2))) if stake > 0 else "", int(GameState.minigame_streak[game])], GameState.COL_GOOD)
		else:
			GameState.minigame_streak[game] = 0
			GameState.log_msg("%s: %s wins%s. Your streak is over." % [MinigameData.GAMES[game]["name"], who,
				(", %d cr lost" % stake) if stake > 0 else ""], GameState.COL_WARN)
	mg_session = {}
	return ""


func _c_pool_shot(c: Dictionary) -> String:
	var g = _ground()
	if g == null or g.minigame == null or not g.minigame.has_method("shoot"):
		return "No pool game."
	var sp: Array = c.get("spin", [0.0, 0.0])
	g.minigame.shoot(float(c.get("angle", 0.0)), float(c.get("power", 0.5)), Vector2(float(sp[0]), float(sp[1])))
	return ""


## {"type":"drift_move", "move": "drift"|"hold"|"warp", "card": i} – package 54b: a move at the Drift table.
func _c_drift_move(c: Dictionary) -> String:
	var g = _ground()
	if g == null or g.minigame == null or not g.minigame.has_method("ai_choice"):
		return "No Drift game."
	g.minigame.move(String(c.get("move", "hold")), int(c.get("card", -1)))
	return ""


## {"type":"dart_throw", "x", "y"} – package 54b: a dart at the board (art px on the board's picture).
func _c_dart_throw(c: Dictionary) -> String:
	var g = _ground()
	if g == null or g.minigame == null or not g.minigame.has_method("throw_at"):
		return "No darts game."
	g.minigame.throw_at(Vector2(float(c.get("x", 0.0)), float(c.get("y", 0.0))))
	return ""


## {"type":"debug_minigame", "game", "streak": n} – package 54b: set the win streak; with "open": true the game's lobby
## at once (wherever you are on foot); "result": "win"/"lose" ends the running game so.
func _c_debug_minigame(c: Dictionary) -> String:
	var game := String(c.get("game", "billiards"))
	if c.has("streak"):
		GameState.minigame_streak[game] = int(c["streak"])
		GameState.log_msg("[Debug] %s: win streak %d." % [game, int(c["streak"])], GameState.COL_WARN)
	var g = _ground()
	if String(c.get("result", "")) != "" and g != null and g.minigame != null and g.minigame.has_method("finish"):
		g.minigame.finish(String(c["result"]) == "win")
	if bool(c.get("open", false)):
		if g == null:
			return "Only on foot."
		g.open_minigame(game, {"title": "%s (debug)" % String(MinigameData.GAMES.get(game, {}).get("where", "The table")), "id": "debug_table"})
	return ""


## {"type":"sight_tour"} – package 54a: you stepped up to a sight's viewpoint – the sightseers of an excursion aboard
## the ship you came in have seen it.
func _c_sight_tour(_c: Dictionary) -> String:
	var g = _ground()
	var f := _fit()
	if g == null or f == null or g.map == null or not g.map.has_meta("sight"):
		return "No sight here."
	var sid := String(g.map.get_meta("sight").get("id", ""))
	var n := 0
	for m in GameState.missions:
		if String(m["type"]) != "passenger" or not m.has("tour") or int(m.get("ship_uid", -1)) != f.uid:
			continue
		var tr: Dictionary = m["tour"]
		if bool(tr["done"]) or not bool(tr.get("ground", false)) or String(tr["sight"]) != sid:
			continue
		tr["done"] = true
		tr["t"] = Missions.TOUR_VIEW
		n += 1
		GameState.log_msg("Your sightseers crowd the railing: %s. Now back to %s." % [String(tr["name"]),
			Universe.find_station(int(m["target_system"]), String(m["target_station"])).get("name", "?")], GameState.COL_GOOD)
	if n > 0:
		Economy.change(GameState.current_system, 0.4, "tourists")
		GameState.codex.event("tour")
		GameState.missions_changed.emit()
	return ""


## {"type":"debug_tour_view"} – package 43b: every round trip aboard has seen its sight
func _c_debug_tour_view(_c: Dictionary) -> String:
	var n := 0
	for m in GameState.missions:
		if m.has("tour") and not bool(m["tour"]["done"]):
			m["tour"]["t"] = Missions.TOUR_VIEW
			m["tour"]["done"] = true
			n += 1
	GameState.missions_changed.emit()
	GameState.log_msg("[Debug] %d round trip%s: the sight is seen." % [n, "" if n == 1 else "s"])
	return ""


## {"type":"debug_economy"} – package 42: the economy of the current system and why, in the log
func _c_debug_economy(_c: Dictionary) -> String:
	var sid := GameState.current_system
	var ec := Economy.of(sid)
	var parts: Array = []
	var keys: Array = (ec["scores"] as Dictionary).keys()
	keys.sort_custom(func(a, b): return float(ec["scores"][a]) > float(ec["scores"][b]))
	for e in keys:
		parts.append("%s %.1f" % [Economy.name_of(e), float(ec["scores"][e])])
	GameState.log_msg("[Debug] %s: %s, %s (%d), %s" % [Universe.systems[sid]["name"], Economy.label(sid), Economy.level_name(sid), int(Economy.prosperity(sid)), ", ".join(PackedStringArray(parts))])
	return ""


## {"type":"debug_economy_system", "economy": "agri"} – package 42: to the next system with that main economy
## ("metal" = to the next system with a metal world)
var _debug_econ_i := {}


func _c_debug_economy_system(c: Dictionary) -> String:
	var want := String(c.get("economy", "mining"))
	var hits: Array = []
	for s in Universe.systems:
		var sid: int = s["id"]
		if want == "metal":
			for p in Universe.get_layout(sid)["planets"]:
				if String(p["type"]) == "metal":
					hits.append(sid)
					break
		elif want == "resort":
			if not Tourism.resorts(sid).is_empty():
				hits.append(sid)                      # package 43
		elif Economy.of(sid)["main"] == want:
			hits.append(sid)
	if hits.is_empty():
		return "No such system in this cluster."
	var i := (int(_debug_econ_i.get(want, -1)) + 1) % hits.size()
	_debug_econ_i[want] = i
	return _c_debug_teleport({"system": hits[i]})


## {"type":"debug_p40", "to": "rim"|"far"|"veil"|"battlefield"|"derelict"|"radiation"|"ion_storm"|"minefield"|"fortress"}
## – 40e: to the next system with it, undocked next to it (outside a fortress's guns, at a hazard's edge)
var _debug_p40_i := {}


func _c_debug_p40(c: Dictionary) -> String:
	var want := String(c.get("to", "rim"))
	var hits: Array = []                       # [system id, place or Vector2.INF]
	for s in Universe.systems:
		var sid: int = s["id"]
		match want:
			"rim":
				if s.get("belt", false) and not s.get("outer", false):
					hits.append([sid, Vector2.INF])
			"far":
				if s.get("outer", false) and not s.get("veil", false):
					hits.append([sid, Vector2.INF])
			"veil":
				if s.get("veil", false):
					hits.append([sid, Vector2.INF])
			"fortress":
				if s.get("fortress", false):
					for hv in Universe.get_layout(sid)["havens"]:
						if hv.get("fortress", false):
							hits.append([sid, (hv["pos"] as Vector2) + Vector2(14000.0, 0.0)])
			"battlefield", "derelict":
				if s.get("belt", false):
					for ws in Universe.get_layout(sid).get("sites", []):
						if String(ws["kind"]) == want:
							hits.append([sid, (ws["pos"] as Vector2) + Vector2(float(ws["radius"]) * 0.8, 0.0)])
			_:
				for hz in Universe.get_layout(sid).get("hazards", []):
					if String(hz["kind"]) == want and String(hz["id"]) != "hz_rad_star":
						hits.append([sid, (hz["pos"] as Vector2) + Vector2(float(hz["radius"]) * 1.15, 0.0)])
						break
	if hits.is_empty():
		return "No such place in this cluster."
	var i := (int(_debug_p40_i.get(want, -1)) + 1) % hits.size()
	_debug_p40_i[want] = i
	if int(hits[i][0]) == GameState.current_system and world != null and is_instance_valid(world) and world.player != null and hits[i][1] != Vector2.INF:
		var f0 := _fit()
		f0.docked_at = ""
		world.player.position = hits[i][1]
		f0.position = hits[i][1]
		world.player.order = {"type": "idle"}
		world.center_on_player()
		GameState.log_msg("[Debug] %s (%d of %d): in this system." % [want.capitalize(), i + 1, hits.size()], GameState.COL_WARN)
		return ""
	var e := _c_debug_teleport({"system": hits[i][0]})
	if e != "":
		return e
	var f := _fit()
	if hits[i][1] != Vector2.INF:
		f.docked_at = ""
		f.position = hits[i][1]
		GameState.active_changed.emit()
		_place_after_load.call_deferred(int(hits[i][0]), hits[i][1])
	GameState.log_msg("[Debug] %s (%d of %d)." % [want.capitalize(), i + 1, hits.size()], GameState.COL_WARN)
	return ""


## Once the system is loaded, the ship goes where the debug command wanted it.
func _place_after_load(sid: int, pos: Vector2) -> void:
	for k in 30:
		if world != null and is_instance_valid(world) and world.system_id == sid and world.player != null and is_instance_valid(world.player):
			var f := _fit()
			f.docked_at = ""
			f.position = pos
			world.player.position = pos
			world.player.velocity = Vector2.ZERO
			world.player.order = {"type": "idle"}
			world.center_on_player()
			return
		await get_tree().process_frame


## {"type":"debug_fortress", "do": "break"|"rebuild"} – 40e: the fortress of this system
func _c_debug_fortress(c: Dictionary) -> String:
	var sid := GameState.current_system
	if not Universe.is_fortress(sid):
		return "No pirate fortress in this system."
	if String(c.get("do", "break")) == "break":
		GameState.fortress_broken[str(sid)] = GameState.play_time + GameState.FORTRESS_REBUILD
		GameState.log_msg("[Debug] The fortress is broken: its guns are silent for %d min." % int(GameState.FORTRESS_REBUILD / 60.0), GameState.COL_WARN)
	else:
		GameState.fortress_broken.erase(str(sid))
		GameState.log_msg("[Debug] The fortress is rebuilt: its garrison returns the next time you arrive.", GameState.COL_WARN)
	return ""


## {"type":"debug_misjump"} – 40e: the pilot's next jump goes wrong
func _c_debug_misjump(_c: Dictionary) -> String:
	GameState.debug_misjump = true
	GameState.log_msg("[Debug] Your next jump goes wrong.", GameState.COL_WARN)
	return ""


## {"type":"debug_heimkehr"} – to Heimkehr (docked at the Cathedral of Return)
func _c_debug_heimkehr(_c: Dictionary) -> String:
	var sid := Universe.special_system("heimkehr")
	if sid < 0:
		return "No Heimkehr in this cluster."
	return _c_debug_teleport({"system": sid})


## {"type":"debug_edict", "edict": id ("" = random)} – the Hierarch proclaims now
func _c_debug_edict(c: Dictionary) -> String:
	GameState.curia.proclaim(String(c.get("edict", "")))
	return ""


## {"type":"debug_relic", "n": 1} – relics of Earth into the hold
func _c_debug_relic(c: Dictionary) -> String:
	var f := _fit()
	if f == null:
		return "No active ship."
	f.add_cargo("earth_relic", float(c.get("n", 1)))
	return ""


## {"type":"debug_landfall"} – to Landfall (docked at The Vote)
func _c_debug_landfall(_c: Dictionary) -> String:
	var sid := Universe.special_system("landfall")
	if sid < 0:
		return "No Landfall in this cluster."
	return _c_debug_teleport({"system": sid})


## {"type":"debug_capital", "which": "senate", "level": "kplaza"|"senate"|"sgallery"} – package 54c: to Landfall and
## down into Neo Kallipolis, straight to that level.
func _c_debug_capital(c: Dictionary) -> String:
	var m = _main()
	var f := _fit()
	if m == null or f == null:
		return "No game running."
	var which := String(c.get("which", "senate"))
	if bool(c.get("here", false)):
		# (for tests) the capital's places in a city of this system – no jump, the system view stays
		var LH := Universe.get_layout(f.system_id)
		for bh in LH["planets"] + LH.get("moons", []):
			for sh in Universe.landing_sites(f.system_id, bh):
				if String(sh.get("kind", "")) == "city":
					var sd: Dictionary = sh.duplicate()
					sd["capital"] = which
					sd["id"] = String(sh.get("id", "city")) + "_" + which              # its own city – not one met before
					_debug_leave_space(m)
					f.docked_at = "land:" + String(bh["id"])
					m.enter_city(bh, sd)
					var gh = _ground()
					if gh == null:
						return "Could not land."
					if String(c.get("level", "")) != "":
						gh.go_level(String(c["level"]), "lift")
					return ""
		return "No city in this system."
	var sp := "landfall" if which == "senate" else "heimkehr"
	var sid := Universe.special_system(sp)
	if sid < 0:
		return "No such capital in this cluster."
	if GameState.current_system != sid:
		var e := _c_debug_teleport({"system": sid})
		if e != "":
			return e
	var bname := "Agora" if which == "senate" else "Compline"
	var L := Universe.get_layout(sid)
	var body := {}
	for b in L["planets"] + L.get("moons", []):
		if String(b.get("name", "")) == bname:
			body = b
	if body.is_empty():
		return "No %s here." % bname
	var site := {}
	for s2 in Universe.landing_sites(sid, body):
		if String(s2.get("capital", "")) == which:
			site = s2
	if site.is_empty():
		return "No capital city found."
	_debug_leave_space(m)
	f.docked_at = "land:" + String(body["id"])
	m.enter_city(body, site)
	var g = _ground()
	if g == null:
		return "Could not land."
	var lv := String(c.get("level", ""))
	if c.has("stop"):
		g.rail_stop = int(c["stop"])                     # 54c: the skyrail's palace stop
	if lv != "":
		g.go_level(lv, "rail" if lv == "cstation" else "lift")
	GameState.log_msg("[Debug] %s." % String(site["name"]), GameState.COL_WARN)
	return ""


## {"type":"debug_station_room", "room": "vgallery"|"nave"} – 54c (Luz): to a special station's own room (The Vote's
## gallery, the Cathedral's nave)
const DEBUG_ROOMS := {"vgallery": ["landfall", "senate"], "nave": ["heimkehr", "curia"], "control": ["durchbruch", "exchange"],
	"yard_concord": ["landfall", "capital_yard", "ygallery"], "yard_forge": ["heimkehr", "capital_yard", "ygallery"], "yard_axiom": ["durchbruch", "capital_yard", "ygallery"]}
func _c_debug_station_room(c: Dictionary) -> String:
	var m = _main()
	var f := _fit()
	if m == null or f == null:
		return "No game running."
	var room := String(c.get("room", "vgallery"))
	if not DEBUG_ROOMS.has(room):
		return "No such room."
	var sid := Universe.special_system(String(DEBUG_ROOMS[room][0]))
	if GameState.current_system != sid:
		var e := _c_debug_teleport({"system": sid})
		if e != "":
			return e
	var st := {}
	for s in Universe.get_layout(sid)["stations"]:
		if bool(s.get(String(DEBUG_ROOMS[room][1]), false)):
			st = s
	if st.is_empty() or m.view == null:
		return "No such station here."
	f.docked_at = String(st["id"])
	if m.station_panel.visible:
		m.station_panel.close()
	if m.view.stations.has(f.docked_at):
		m.open_deck()
	else:
		GameState.gear.aboard()
		m._open_ground_at(st)
	var g = _ground()
	if g == null:
		return "The deck did not open."
	g.go_level(String(DEBUG_ROOMS[room][2]) if (DEBUG_ROOMS[room] as Array).size() > 2 else room, "lift")
	return ""


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


## {"type":"room_rent", "size": small|medium|luxury} – package 58: a room in the quarters for one night.
func _c_room_rent(c: Dictionary) -> String:
	var st := docked_station()
	if st.is_empty():
		return "You must be docked at a station."
	var QG = load("res://scripts/ground/quarters_gen.gd")
	if not QG.has_quarters(st):
		return "There are no quarters here."
	var size := String(c.get("size", ""))
	if not QG.SIZES.has(size):
		return "No such room."
	var sid := String(st["id"])
	var cur: Dictionary = GameState.lodging.get(sid, {})
	if not cur.is_empty() and String(cur.get("size", "")) == size:
		return "You have a %s here already." % String(QG.SIZES[size]["name"]).to_lower()
	var i: int = QG.room_for(st, size)
	if i < 0:
		return "No %s free tonight." % String(QG.SIZES[size]["name"]).to_lower()
	var p: int = QG.price(st, size)
	if not GameState.spend(p):
		return "Not enough credits: a %s costs %s." % [String(QG.SIZES[size]["name"]).to_lower(), GameData.fmt_credits(p)]
	GameState.lodging[sid] = {"room": i, "size": size, "free": false, "keep": false}
	GameState.log_msg("Room %d rented for the night (%s)." % [int(QG.room(st, i)["no"]), GameData.fmt_credits(p)], GameState.COL_GOOD)
	return ""


## {"type":"room_sleep"} – package 58: a night in your room: the planets of this system stand elsewhere on their
## orbits, the stations have new contracts and the bars new faces; a paid room is given back.
func _c_room_sleep(_c: Dictionary) -> String:
	var st := docked_station()
	var sid := String(st.get("id", ""))
	if st.is_empty() or not GameState.lodging.has(sid):
		return "You have no room here."
	var f := _fit()
	if f != null and GameState._may_roll_orbits(f):
		Universe.roll_orbits(GameState.current_system)
		var mn = world.get_tree().current_scene if world != null and is_instance_valid(world) else null
		if mn != null and mn.has_method("load_system"):
			mn.load_system(GameState.current_system)
	GameState.offers.clear()                                   # new contracts everywhere
	GameState.bar.clear()                                      # new faces in the bars
	if not bool((GameState.lodging[sid] as Dictionary).get("keep", false)):
		GameState.lodging.erase(sid)
	GameState.slept.emit(sid)
	GameState.log_msg("You slept through the night. Rested.", GameState.COL_GOOD)
	return ""


## {"type":"luz_sleep"}: package 64e (Luz): a night in the room above the Static Feedback (yours once Luz has shown
## it to you): the time passes as in a room of the quarters.
func _c_luz_sleep(_c: Dictionary) -> String:
	var st := docked_station()
	if not st.get("city", false) or String(st.get("name", "")) != "Centauria" or not bool(GameState.story.flags.get("luz_room", false)):
		return "You have no room here."
	var f := _fit()
	if f != null and GameState._may_roll_orbits(f):
		Universe.roll_orbits(GameState.current_system)
		var mn = world.get_tree().current_scene if world != null and is_instance_valid(world) else null
		if mn != null and mn.has_method("load_system"):
			mn.load_system(GameState.current_system)
	GameState.offers.clear()
	GameState.bar.clear()
	GameState.story.set_flag("luz_slept", true)
	GameState.slept.emit(String(st.get("id", "")))
	GameState.log_msg("You slept through the night. Rested.", GameState.COL_GOOD)
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
	GameState.log_msg("[Debug] Contract objectives complete: turn them in at the issuing station.", GameState.COL_WARN)
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
		return "No station exactly %d jump%s away." % [jumps, "" if jumps == 1 else "s"]
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


# ---------------------------------------------------------------- 0.7.51.5: debug for packages 49–51 (on foot, landing, gear)

var suit_god := false         # 0.7.51.5: the world outside does not hurt the pilot (energy and oxygen still drain)
const DEBUG_SITE_KINDS := ["city", "outpost", "mine", "research", "field"]
const DEBUG_BELT := ["cs_medkit", "cs_cell", "cs_o2", "cs_stim", "cs_ammo"]


func _main():
	var m = get_tree().current_scene if is_inside_tree() else null
	return m if m != null and m.has_method("land_at") else null


func _ground():
	var m = _main()
	if m != null and GameState.acting == 1 and m.has_method("apart") and m.apart():
		return m.ground2                                 # (split screen, in different places: the second player's own view)
	if m == null or m.ground == null or not is_instance_valid(m.ground):
		return null
	return m.ground


## The player's ship out of space for a landing done by the debug menu (as at the end of a descent).
func _debug_leave_space(m) -> void:
	if m.station_panel != null and m.station_panel.visible:
		m.station_panel.close()
	m.close_deck(false)
	if world != null and is_instance_valid(world) and world.player != null and is_instance_valid(world.player):
		world.player.visible = false
		world.player.order = {"type": "idle"}
		world.player.velocity = Vector2.ZERO


## {"type":"debug_deck"} – package 49: out of the ship onto the deck of the docked station (or a city's hangar).
func _c_debug_deck(_c: Dictionary) -> String:
	var m = _main()
	var f := _fit()
	if m == null or f == null:
		return "No game running."
	var st := docked_station()
	if st.is_empty():
		return "Dock at a station (or land in a city) first."
	if bool(st.get("settlement", false)):
		return "A settlement has no deck: you are already outside."
	if m.station_panel.visible:
		m.station_panel.close()
	if m.view != null and m.view.stations.has(f.docked_at):
		m.open_deck()
	else:
		GameState.gear.aboard()
		m._open_ground_at(st)
	return "" if _ground() != null else "The deck did not open."


## {"type":"debug_ground_level", "level": "hangar"|"commercial"|"street"|"tower"|"clinic"} – package 49/50: straight to a
## level (0.7.51.11: the clinic, where there is one).
func _c_debug_ground_level(c: Dictionary) -> String:
	var g = _ground()
	if g == null:
		return "Not on foot."
	var lv := String(c.get("level", ""))
	var ok: Array = []
	if g.is_city():
		ok = ["hangar", "street", "tower", "alley"]          # 0.7.53.3: the back alley over the sewers
	elif not g.is_town() and g.level in ["hangar", "commercial", "clinic"]:
		ok = ["hangar", "commercial"]
	if g.is_town() and not g.is_city():
		ok = ["settlement", "minehead"]                     # 0.7.53.7: a settlement and the old mine at its edge
	if not ok.is_empty() and g._avail.has("clinic") and not (g.is_town() and not g.is_city()):
		ok.append("clinic")
	if ok.is_empty():
		return "No levels here (a landing field or a settlement)."
	if not lv in ok:
		return "No level '%s' here." % lv
	g.go_level(lv, "lift")
	return ""


## {"type":"debug_descend", "body": id} – package 50: down to a body of this system at once – the planet map opens.
func _c_debug_descend(c: Dictionary) -> String:
	var m = _main()
	var f := _fit()
	if m == null or f == null:
		return "No game running."
	if f.in_transit():
		return "Not during a hyperspace jump."
	var body := Universe.find_body(f.system_id, String(c.get("body", "")))
	if body.is_empty() or not Universe.can_land(body):
		return "No body to land on."
	_debug_leave_space(m)
	f.docked_at = "land:" + String(body["id"])
	m._on_descended(String(body["id"]))
	GameState.log_msg("[Debug] Down to %s." % String(body["name"]), GameState.COL_WARN)
	return ""


## {"type":"debug_land", "body": id ("" = the first you can land on), "kind": city|outpost|mine|research|field,
##  "world": a world type to see the body as ("" = its own), "economy": a settlement's economy ("" = its own),
##  "day": "" or day|dusk|night|dawn} – package 50: straight onto the ground at such a place. If the body has none of
## that kind (or the economy is forced), the debug menu adds one.
func _c_debug_land(c: Dictionary) -> String:
	var m = _main()
	var f := _fit()
	if m == null or f == null:
		return "No game running."
	if f.in_transit():
		return "Not during a hyperspace jump."
	var kind := String(c.get("kind", "city"))
	if not kind in DEBUG_SITE_KINDS:
		return "Unknown kind of place."
	var body := Universe.find_body(f.system_id, String(c.get("body", "")))
	if body.is_empty():
		var L := Universe.get_layout(f.system_id)
		for b in L["planets"] + L.get("moons", []):
			if Universe.landable(b):
				body = b
				break
	var wt := String(c.get("world", ""))
	if wt != "" and not (Universe.PLANET_TYPES.has(wt) or Universe.MOON_TYPES.has(wt)):
		return "Unknown world type."
	if not body.is_empty():
		body = Universe.debug_body_as(body, wt)
	if body.is_empty() or not Universe.can_land(body):
		return "No body to land on here."
	var eco := String(c.get("economy", "")) if kind in ["outpost", "mine", "research"] else ""
	if eco != "" and not SettleGen.SPECIAL.has(eco):
		return "Unknown economy."
	var site := {}
	if eco == "":
		for s in Universe.landing_sites(f.system_id, body):
			if String(s["kind"]) == kind or (kind == "field" and String(s["kind"]) in ["ruins", "crash"]):
				site = s
				break
	if site.is_empty():
		var bid := String(body["id"])
		var sid := "%s_dbg_%s%s" % [bid, kind, ("_" + eco) if eco != "" else ""]
		var real_kind := "crash" if kind == "field" else kind
		site = {"id": sid, "kind": real_kind, "lon": -0.35, "lat": 0.1,
			"name": "Debug %s%s" % ["Landing Field" if kind == "field" else String(Universe.SITE_KINDS[real_kind]["name"]), (" (%s)" % eco) if eco != "" else ""]}
		if eco != "":
			site["economy"] = eco
		var extra: Array = Universe.debug_sites.get(bid, [])
		if not extra.any(func(x): return String(x["id"]) == sid):
			extra.append(site)
		Universe.debug_sites[bid] = extra
	_debug_leave_space(m)
	f.docked_at = "land:" + String(body["id"])
	if kind == "city":
		m.enter_city(body, site)
	else:
		m.land_at(body, site)
	if _ground() == null:
		return "Could not land."
	GameState.log_msg("[Debug] Landed at %s on %s." % [String(site["name"]), String(body["name"])], GameState.COL_WARN)
	if String(c.get("day", "")) != "" and _ground().is_town():
		return _c_debug_daytime({"phase": String(c["day"])})
	return ""


## {"type":"debug_daytime", "phase": "day"|"dusk"|"night"|"dawn"} – package 50: the world turns on until the city or
## settlement you are in has that hour (every world turns with it – the planet map agrees).
func _c_debug_daytime(c: Dictionary) -> String:
	var g = _ground()
	if g == null or not g.is_town():
		return "Only in a city or a settlement."
	var phase := String(c.get("phase", "day"))
	if not phase in ["day", "dusk", "night", "dawn"]:
		return "Unknown time of day."
	var body: Dictionary = g._city_body
	if body.is_empty():
		body = Universe.find_body(GameState.current_system, String(g.station.get("body", "")))
	if body.is_empty():
		return "No world under this place."
	var st: Dictionary = g.station
	var length := CityStyle.day_length(body)
	var best := 0.0
	var best_score := INF
	for i in 480:
		var dt := length * float(i) / 480.0
		var d := CityStyle.daylight(st, body, dt)
		var up := CityStyle.daylight(st, body, dt + 5.0) > d
		var score := 0.0
		match phase:
			"day":
				score = -d
			"night":
				score = d
			"dusk":
				score = absf(d - 0.45) + (1.0 if up else 0.0)
			"dawn":
				score = absf(d - 0.45) + (0.0 if up else 1.0)
		if score < best_score - 0.0001:
			best_score = score
			best = dt
	CityStyle.debug_shift += best
	g._apply_day(CityStyle.daylight(st, body), true)
	GameState.log_msg("[Debug] %s at %s (daylight %d %%)." % [phase.capitalize(), String(st.get("name", "?")), int(float(st.get("day", 0.0)) * 100.0)], GameState.COL_WARN)
	return ""


## {"type":"debug_gear", ...} – package 51: "give": id (+ "n") into the pockets; "fill_belt": every belt place full;
## "refill": health, energy, oxygen, ammunition full; "clear": empty pockets; "set": {health|energy|oxygen|ammo: percent};
## "suit_god": bool – the world outside does not hurt; "grenades": every belt place a stack of grenades (0.7.52.5).
## {"type":"debug_cloud", "giant": ""|gas|ice_giant|red_gas|toxic, "level": ""|hangar|cplaza|cstation|ctrain|tower,
##  "stop": 0|1, "power": ""|assembly|covenant|directorate|independent, "air": ""|"breathable"|"suit"} – package 54:
## straight into a cloud city of this system's giant (one of that kind if asked, or a body seen as one).
const CloudGen54 = preload("res://scripts/ground/cloud_gen.gd")
const DEBUG_GIANTS := ["gas", "ice_giant", "red_gas", "toxic"]
const DEBUG_POWERS := ["assembly", "covenant", "directorate", "independent"]
func _c_debug_cloud(c: Dictionary) -> String:
	var m = _main()
	var f := _fit()
	if m == null or f == null:
		return "No game running."
	if f.in_transit():
		return "Not during a hyperspace jump."
	var want := String(c.get("giant", ""))
	if want != "" and not want in DEBUG_GIANTS:
		return "Unknown kind of giant."
	var pw := String(c.get("power", ""))
	if pw != "" and not pw in DEBUG_POWERS:
		return "Unknown power."
	var lv := String(c.get("level", ""))
	if lv != "" and not lv in ["hangar", "cplaza", "cstation", "ctrain", "tower", "cunder"]:
		return "Unknown level."
	var L := Universe.get_layout(f.system_id)
	var body := {}
	for b in L["planets"]:
		if Universe.is_giant(b) and (want == "" or String(b["type"]) == want):
			body = b
			break
	if body.is_empty():
		for b2 in L["planets"]:
			if not b2.get("dwarf_star", false):
				body = Universe.debug_body_as(b2, want if want != "" else "gas")
				break
	if body.is_empty():
		return "No body here."
	body["cloud_city"] = true
	var sites: Array = Universe.landing_sites(f.system_id, body)
	if sites.is_empty():
		return "No cloud city."
	_debug_leave_space(m)
	f.docked_at = "land:" + String(body["id"])
	var st := Universe.city_station(f.system_id, body, sites[0])
	if pw != "":
		st["faction"] = pw
	var air := String(c.get("air", ""))
	st.erase("debug_air")
	if air != "":
		st["debug_air"] = air
	m.enter_city(body, sites[0])
	var g = _ground()
	if g == null:
		return "Could not land."
	if lv == "ctrain" or lv == "cstation":
		g.rail_stop = clampi(int(c.get("stop", 0)), 0, 3)
	st.erase("debug_sight_event")                         # 54a: the Skyring deck's event and hour
	st.erase("debug_sight_day")
	if String(c.get("sight_event", "")) != "":
		st["debug_sight_event"] = String(c["sight_event"])
	if c.has("sight_day"):
		st["debug_sight_day"] = float(c["sight_day"])
	var fr := String(c.get("freighter", ""))
	st.erase("debug_freighter")
	if fr != "":
		st["debug_freighter"] = fr == "yes"
	if lv == "ctrain":
		g.rail_to = CloudGen54.others(g.rail_stop)[0]
	if lv == "cunder":
		g.go_level("cplaza", "lift")
		if bool(c.get("job", false)):
			GameState.maint_sites[String(st.get("id", ""))] = GameState.maint_site(st, int(c.get("seed", 77)))
		g._town_kind = "maint"                           # 0.7.54.3: down under the deck
		g.depth = 0
		g.go_level("dungeon", "dungeon_in")
		lv = ""
	if lv != "" and lv != "hangar":
		g.go_level(lv, "rail" if lv in ["ctrain", "cstation"] and int(c.get("stop", 0)) >= 1 else "lift")
	GameState.log_msg("[Debug] Cloud city %s over %s." % [String(sites[0]["name"]), String(body["name"])], GameState.COL_WARN)
	return ""


## Package 54a (Luz): at a sight – {"type":"sight_photo"}: a photo of what is to be seen now (a travel magazine buys a
## new one); {"type":"souvenir_buy", "amount": int}: its souvenirs into the hold.
const SightGenC = preload("res://scripts/ground/sight_gen.gd")
const SOUVENIR_PRICE := 0.6                     # at the stall – a fraction of the market price


func _c_sight_photo(_c: Dictionary) -> String:
	var g = _ground()
	if g == null or g.map == null or not g.map.has_meta("sight"):
		return "Nothing to photograph here."
	var sg: Dictionary = g.map.get_meta("sight")
	var key := "%s:%s" % [String(sg["id"]), String(sg["event"])]
	if GameState.sight_photos.has(key):
		return "You have that photo already."
	GameState.sight_photos[key] = true
	var ev: Array = SightGenC.SIGHTS[String(sg["theme"])]["events"].get(String(sg["event"]), ["the view", "any", 1.0, false])
	var pay: int = SightGenC.PHOTO_PAY_RARE if bool(ev[3]) else SightGenC.PHOTO_PAY
	GameState.credits += pay
	GameState.log_msg("Photo: %s, %s%s. A travel magazine buys it: %d cr." % [String(sg["name"]), String(ev[0]), " (rare)" if bool(ev[3]) else "", pay], GameState.COL_GOOD)
	return ""


var souvenirs_bought := 0              # review 7 K5: how many the last souvenir_buy really bought (the hold or the credits may cut it)
func _c_souvenir_buy(c: Dictionary) -> String:
	souvenirs_bought = 0
	var g = _ground()
	var f := _fit()
	if g == null or f == null or g.map == null or not g.map.has_meta("sight"):
		return "No souvenir stall here."
	var sg: Dictionary = g.map.get_meta("sight")
	var item := String(SightGenC.SIGHTS[String(sg["theme"])]["souvenir"])
	var price := maxi(1, int(round(float(GameData.commodities[item]["price"]) * SOUVENIR_PRICE)))
	var room := int(floor(f.free_for(item) / GameData.item_volume(item)))
	var amount := mini(mini(int(c.get("amount", 1)), room), GameState.credits / price)
	if amount <= 0:
		return "No room in the hold, or not enough credits."
	GameState.spend(amount * price)
	f.add_cargo(item, amount)
	souvenirs_bought = amount
	return ""


## {"type":"debug_weather", "kind": "" (the world's own) | "rain" | "storm" | … , "strike": true} – 54e (Luz): the
## weather on foot, forced (on every world with air until set back); a bolt of lightning now.
func _c_debug_weather(c: Dictionary) -> String:
	var kd := String(c.get("kind", Weather.debug_kind))
	if kd != "" and not Weather.NAMES.has(kd):
		return "Unknown weather."
	Weather.debug_kind = kd
	var g = _ground()
	if g != null and g.weather != null and is_instance_valid(g.weather):
		g.weather.w = Weather.at(g.weather.body, g.weather.place, g.weather.cloud)
		g.weather._apply()
		g.weather._people()
		g.weather._sound()
		if bool(c.get("strike", false)):
			g.weather.strike()
	GameState.log_msg("[Debug] Weather: %s." % (String(Weather.NAMES[kd][0]) if kd != "" else "the world's own"), GameState.COL_WARN)
	return ""


## {"type":"debug_sight", "theme": falls/…, "event": "" or an event id} – package 54a: straight to a sight (on a body of
## this system seen as the right kind of world).
const DEBUG_SIGHT_WORLD := {"falls": "jungle", "lagoon": "ocean", "icecave": "ice", "arches": "desert", "lava": "lava", "crater": "barren", "mirror": "terran"}
func _c_debug_sight(c: Dictionary) -> String:
	var m = _main()
	var f := _fit()
	if m == null or f == null:
		return "No game running."
	var th := String(c.get("theme", "falls"))
	if not DEBUG_SIGHT_WORLD.has(th):
		return "Unknown sight."
	var L := Universe.get_layout(f.system_id)
	var body := {}
	for b in L["planets"] + L.get("moons", []):
		if Universe.landable(b):
			body = Universe.debug_body_as(b, String(DEBUG_SIGHT_WORLD[th]))
			break
	if body.is_empty():
		return "No body here."
	var site := {"id": "%s_dbg_sight" % String(body["id"]), "name": String(SightGenC.SIGHTS[th]["names"][0]), "kind": "sight", "theme": th,
		"seed": int(c.get("seed", 1234)), "lon": 0.0, "lat": 0.0}
	if String(c.get("event", "")) != "":
		site["debug_event"] = String(c["event"])
	if c.has("day"):
		site["debug_day"] = float(c["day"])
	_debug_leave_space(m)
	f.docked_at = "land:" + String(body["id"])
	m.land_at(body, site)
	return "" if _ground() != null else "Could not land."


## {"type":"debug_excursion"} – package 54a: an excursion aboard the active ship, to a sight on the ground of this
## system (or a Skyring deck), from the station you are at (or the first of this system); {"type":"debug_shuttle"}:
## a shuttle run aboard, from here down to a city of this system.
func _c_debug_excursion(_c: Dictionary) -> String:
	var f := _fit()
	if f == null:
		return "No game running."
	var sid := GameState.current_system
	var gs: Array = Missions.ground_sights(sid)
	var sts: Array = Universe.get_layout(sid)["stations"]
	if gs.is_empty() or sts.is_empty():
		return "No sight on the ground (or no station) in this system."
	var st: Dictionary = docked_station() if not docked_station().is_empty() else sts[0]
	var m := Missions._excursion(sid, st, sid, gs[0], "bulk", 6, 0)
	m["ship_uid"] = f.uid
	m["expires"] = GameState.play_time + float(m["time_limit"])
	GameState.missions.append(m)
	GameState.missions_changed.emit()
	GameState.log_msg("[Debug] Excursion aboard: %s, %s." % [String(gs[0]["name"]), String(gs[0]["where"])], GameState.COL_WARN)
	return ""


func _c_debug_shuttle(_c: Dictionary) -> String:
	var f := _fit()
	if f == null:
		return "No game running."
	var sid := GameState.current_system
	var sts: Array = Universe.get_layout(sid)["stations"]
	var st: Dictionary = docked_station() if not docked_station().is_empty() else (sts[0] if not sts.is_empty() else {})
	if st.is_empty():
		return "No station here."
	var rng := RandomNumberGenerator.new()
	rng.seed = Time.get_ticks_msec()
	var m := Missions.generate_shuttle(sid, st, rng)
	if m.is_empty():
		return "No city to fly to in this system."
	m["cabin"] = "bulk"
	m["amount"] = 6
	m["ship_uid"] = f.uid
	m["expires"] = GameState.play_time + float(m["time_limit"])
	GameState.missions.append(m)
	GameState.missions_changed.emit()
	GameState.log_msg("[Debug] Shuttle run aboard: %s." % String(m["title"]), GameState.COL_WARN)
	return ""


## 0.7.54.2 (Luz): the Gas Exchange at a cloud city's gas works – the giant's gases from the works, under the market.
const GAS_DISCOUNT := 0.7


func gas_offer(giant: String) -> Array:
	return (Universe.GAS_YIELDS.get(giant, Universe.GAS_YIELDS["gas"]) as Dictionary).keys()


func gas_price(item: String) -> int:
	return maxi(1, int(round(float(GameData.commodities.get(item, {}).get("price", 10)) * GAS_DISCOUNT)))


## {"type":"gas_buy", "item": String, "amount": int (-1 = fill the hold)} – at a cloud city's gas works.
func _c_gas_buy(c: Dictionary) -> String:
	var f := _fit()
	var st := docked_station()
	if f == null or not bool(st.get("cloud", false)):
		return "Only at a cloud city's gas works."
	var item := String(c.get("item", ""))
	if not item in gas_offer(String(st.get("giant", "gas"))):
		return "The works do not harvest that here."
	var price := gas_price(item)
	var room := int(floor(f.free_for(item) / GameData.item_volume(item)))
	var amount := int(c.get("amount", 1))
	if amount < 0:
		amount = room
	amount = mini(mini(amount, room), GameState.credits / price)
	if amount <= 0:
		return "No room in the hold, or not enough credits."
	GameState.spend(amount * price)
	f.add_cargo(item, amount)
	GameState.count_stat("turnover", float(amount * price))
	return ""


## {"type":"debug_skyrail", "action": "arrive"|"info"} – package 54: the car arrives at once; or what the ride and
## the cloud city are doing (to the log).
func _c_debug_skyrail(c: Dictionary) -> String:
	var g = _ground()
	if g == null or not g.is_cloud():
		return "Only in a cloud city."
	match String(c.get("action", "info")):
		"arrive":
			if g.level != "ctrain" or g.rail.is_empty():
				return "Not aboard the skyrail."
			g.rail["t"] = maxf(float(g.rail["t"]), g.RAIL_RUN - 0.05)
		"info":
			var e: Dictionary = g.cloud_env()
			GameState.log_msg("[Debug] %s over a %s: level %s, stop %s, ride %s, air %s" % [String(g.station.get("name", "")), String(g.station.get("giant", "")),
				g.level, CloudGen54.STOPS[g.rail_stop], ("%.1f s, %.0f px/s" % [float(g.rail["t"]), float(g.rail["v"])]) if not g.rail.is_empty() else "–",
				"breathable" if bool(e.get("breathable", false)) else "suit"], GameState.COL_WARN)
		_:
			return "Unknown action."
	return ""


## {"type":"debug_poi", "danger": "green"|"yellow"|"red", "seed": int, "theme": "ruin"} – package 53a: down to a
## generated site on a body here (a new one each time unless a seed is given).
func _c_debug_poi(c: Dictionary) -> String:
	const PoiData = preload("res://data/poi.gd")
	var m = _main()
	var f := _fit()
	if m == null or f == null:
		return "No game running."
	if f.in_transit():
		return "Not during a hyperspace jump."
	var L := Universe.get_layout(f.system_id)
	var body := {}
	for b in L["planets"] + L.get("moons", []):
		if Universe.landable(b) and body.is_empty():
			body = b
	if body.is_empty():
		return "No body here to land on."
	var theme := String(c.get("theme", "precursor"))
	if not PoiData.THEMES.has(theme):
		return "Unknown theme."
	if theme.begins_with("wild_"):
		# 53f-2: the wild wants its kind of world – one here, or the first body made into one for the test
		var want: String = {"wild_jungle": "jungle", "wild_coast": "ocean", "wild_ice": "ice"}[theme]
		var found := false
		for b2 in L["planets"] + L.get("moons", []):
			if Universe.landable(b2) and String(b2.get("type", "")) == want:
				body = b2
				found = true
				break
		if not found:
			body = body.duplicate()
			body["type"] = want
	var sd := int(c.get("seed", randi()))
	var rng := RandomNumberGenerator.new()
	rng.seed = sd
	var site := {"id": "dbg_poi_%d" % sd, "name": PoiData.site_name(theme, rng), "kind": String(PoiData.THEMES[theme]["kind"]), "poi": true, "theme": theme, "seed": sd,
		"danger": String(c.get("danger", "yellow")), "lon": 0.0, "lat": 0.0}
	if theme == "wreck":
		site["hull"] = String(c.get("hull", PoiData.THEMES["wreck"]["hulls"][sd % (PoiData.THEMES["wreck"]["hulls"] as Array).size()]))
	if c.has("gate"):
		site["gate"] = String(c["gate"])                 # "open", "panel", "computer"
	var g0 = _ground()
	if theme in ["maint", "skymaint"] and g0 != null and g0.is_city():
		# 0.7.53.9: in a city – its maintenance tunnels lose their power; the lift goes down
		GameState.maint_sites[String(g0.station.get("id", ""))] = GameState.maint_site(g0.station, sd)
		g0._town_kind = "maint"
		g0.depth = 0
		g0.go_level("dungeon", "dungeon_in")
		return ""
	_debug_leave_space(m)
	f.docked_at = "land:" + String(body["id"])
	m.land_at(body, site)
	if _ground() == null:
		return "Could not open the site."
	GameState.log_msg("[Debug] %s (%s, seed %d)." % [String(site["name"]), String(site["danger"]), sd], GameState.COL_WARN)
	return ""


## {"type":"debug_ground_job", "goal": relic/salvage/bounty_foot/heist/spy/reactivate} – package 53c: a job on foot
## offered at the docked (or nearest) station and accepted at once.
func _c_debug_ground_job(c: Dictionary) -> String:
	var f := _fit()
	if f == null:
		return "No game running."
	var st := docked_station()
	if st.is_empty():
		var L := Universe.get_layout(f.system_id)
		if L["stations"].is_empty():
			return "No station here to give the job."
		st = L["stations"][0]
	var rng := RandomNumberGenerator.new()
	rng.seed = int(c.get("seed", randi()))
	var m := {"id": "dbg%d_%d" % [rng.randi(), Time.get_ticks_usec() % 100000], "giver": st["id"], "giver_system": f.system_id, "client": "Debug", "progress": 0, "item": "", "amount": 0,
		"target_system": f.system_id, "target_station": "", "faction": String(st.get("faction", "")), "against": ""}
	var gm := Missions.ground_offer(m, f.system_id, rng, String(c.get("goal", "relic")), String(c.get("variant", "")))
	if gm.is_empty():
		return "No place for that job near here."
	var e := GameState.accept_mission(gm)
	if e != "":
		return e
	var site: Dictionary = gm["site"]
	if bool(c.get("go", false)) and not site.has("city"):
		# 0.7.53.19 (debug): straight there – down onto the site (in a city the job's way in is taken from the city)
		var body := Universe.find_body(int(site["system"]), String(site["body"]))
		var mm = _main()
		if mm != null and not body.is_empty():
			f.docked_at = "land:" + String(body["id"])
			mm.land_at(body, site)
	return ""


## {"type":"debug_mission", "kind": courier/bounty/mining/survey/escort/patrol/smuggler/hunt/drone_trial/passenger}
## – 0.7.53.19 (Luz): a space contract of that kind from the docked (or nearest) station, accepted at once.
func _c_debug_mission(c: Dictionary) -> String:
	var f := _fit()
	if f == null:
		return "No game running."
	var st := docked_station()
	if st.is_empty():
		var L := Universe.get_layout(f.system_id)
		if L["stations"].is_empty():
			return "No station here to give the contract."
		st = L["stations"][0]
	var kind := String(c.get("kind", "courier"))
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var faction_ok := String(st.get("faction", "")) in FactionData.POWERS
	var m: Dictionary = {}
	for i in 400:
		var cand: Dictionary = {}
		if kind == "passenger":
			cand = Missions.generate_passenger(f.system_id, st, rng)
		elif kind in ["patrol", "smuggler", "hunt", "drone_trial"] or (kind == "escort" and i % 2 == 0):
			if faction_ok:
				cand = Missions.generate_faction(f.system_id, st, rng)
		else:
			cand = Missions.generate(f.system_id, st, rng)
		if String(cand.get("type", "")) == kind:
			m = cand
			break
	if m.is_empty():
		return "No %s contract can be made here%s." % [kind, " (a faction contract: needs a station of one of the powers)" if not faction_ok else ""]
	if m.get("faction_job", false):
		m["min_tier"] = "neutral"                     # (debug: no standing needed)
	return GameState.accept_mission(m)


## {"type":"debug_museum", "to": "plaza"|"hall"|"minerals"|"first"|"second"|"basement" (go there: Durchbruch, a city on Curie), "fill": "none"|"half"|
##  "almost"|"all" (the cases), "finds": "some"|"all" (pieces into your pockets)} – 53e: the Museum in Curie.
func _c_debug_museum(c: Dictionary) -> String:
	var ids: Array = MuseumDataC.EXHIBITS.map(func(e): return String(e["id"]))
	match String(c.get("fill", "")):
		"none":
			GameState.museum_donated.clear()
		"half":
			GameState.museum_donated = ids.filter(func(i): return ids.find(i) % 2 == 0)
		"almost":
			GameState.museum_donated = ids.filter(func(i): return i != "do_mask")
			if not GameState.museum_finds.has("do_mask"):
				GameState.museum_finds.append("do_mask")
		"all":
			GameState.museum_donated = ids.duplicate()
	match String(c.get("finds", "")):
		"some":
			for r in MuseumDataC.ROOMS:
				var ri: Array = MuseumDataC.of_room(String(r["id"]))
				GameState.museum_finds.append(String(ri[randi() % ri.size()]["id"]))
				GameState.museum_finds.append(String(ri[randi() % ri.size()]["id"]))
		"all":
			GameState.museum_finds.append_array(ids)
	var to := String(c.get("to", ""))
	var g = _ground()
	if to == "":
		if g != null and String(g.level) in ["museum", "museum_min", "museum_1", "museum_2", "museum_down", "mplaza"]:
			g.go_level(String(g.level), "museum_in" if String(g.level) != "mplaza" else "lift")     # the cases anew
		return ""
	if not to in ["plaza", "hall", "minerals", "first", "second", "basement"]:
		return "Unknown place in the Museum."
	if g == null or not g.is_museum_city():
		var sid := Universe.special_system("fern")              # package 61d (Luz): the Museum stands in Centauria now
		if sid < 0:
			return "No Fern in this cluster."
		var f := _fit()
		if f == null or f.system_id != sid:
			var e := _c_debug_teleport({"system": sid})
			if e != "":
				return e
		var body := {}
		for p in Universe.get_layout(sid)["moons"]:
			if String(p.get("name", "")) == "Pelagia":
				body = p
		if body.is_empty():
			return "No Pelagia here."
		var e2 := _c_debug_land({"body": String(body["id"]), "kind": "city"})
		if e2 != "":
			return e2
		g = _ground()
		if g == null or not g.is_museum_city():
			return "Not in Centauria."
	g._close_lift_menu()
	g.go_level({"plaza": "mplaza", "hall": "museum", "minerals": "museum_min", "first": "museum_1", "second": "museum_2", "basement": "museum_down"}[to], "lift" if to == "plaza" else "museum_in")
	return ""


## {"type":"debug_casino", "to": 0…5} – package 62 (Luz): straight to a floor of the Grand Centauria (down to Centauria
## first if need be; the lounge makes you a member); "vip": true / false, the house's membership; "coins": n, Coins
## into your pocket.
func _c_debug_casino(c: Dictionary) -> String:
	if c.has("col_reg"):                                  # package 62a, part 2: signed up at the Colosseum, or not
		GameState.col_registered = bool(c["col_reg"])
		GameState.log_msg("[Debug] The Colosseum: %s." % ("you are signed up" if GameState.col_registered else "you are not signed up any more"), GameState.COL_INFO)
		var g1 = _ground()
		if g1 != null and String(g1.level) == "zcolin":
			g1.go_level("zcolin", "from_reg")
		return ""
	if c.has("col_map") or c.has("col_plan"):             # … part 5: the next fight's ground and its plan ("" = by lot again)
		var CDf = load("res://data/colosseum.gd")
		for k in [["col_map", "setting"], ["col_plan", "layout"]]:
			if c.has(k[0]):
				if String(c[k[0]]) == "":
					CDf.force.erase(k[1])
				else:
					CDf.force[k[1]] = String(c[k[0]])
		GameState.log_msg("[Debug] The Colosseum: the next ground: %s, %s." % [String(CDf.force.get("setting", "by lot")), String(CDf.force.get("layout", "by lot"))], GameState.COL_INFO)
		return ""
	if c.has("sv") and (String(c["sv"]) in ["cores", "unlock", "lock", "slain", "all"] or String(c["sv"]).begins_with("stage:") or String(c["sv"]).begins_with("rig:")):      # … part 7c-3: the console: 100 cores; all unlocked; all locked again; part 8: the stage
		var SVm = load("res://data/survivor.gd")
		var recm: Dictionary = SVm.record(GameState.col_state())
		if String(c["sv"]).begins_with("stage:"):
			var stg_id := String(c["sv"]).trim_prefix("stage:")
			for stg_d in SVm.STAGES:
				if String(stg_d["id"]) == stg_id and bool(stg_d["open"]):
					if String(stg_d.get("need", "")) != "" and not (String(stg_d["need"]) in (recm["beaten"] as Array)):
						(recm["beaten"] as Array).append(String(stg_d["need"]))
					recm["stage"] = stg_id
					GameState.log_msg("[Debug] Survivor: the stage: %s." % String(stg_d["name"]), GameState.COL_INFO)
					return ""
			return "No such stage."
		if String(c["sv"]).begins_with("rig:"):               # (part 10b) the rig's step, to look at it: "rig:+", "rig:-", "rig:auto" (by what you have bought), "rig:<n>"
			var rig_w := String(c["sv"]).trim_prefix("rig:")
			var rig_now: int = SVm.rig_tier(GameState.col_state())
			recm["rig_force"] = -1 if rig_w == "auto" else clampi(rig_now + 1 if rig_w == "+" else (rig_now - 1 if rig_w == "-" else int(rig_w)), 0, int(SVm.RIG_STEPS))
			var grig = _ground()
			if grig != null and grig.pilot != null and is_instance_valid(grig.pilot):
				grig.pilot.look = grig.pilot_look()
			GameState.log_msg("[Debug] Survivor: the rig: step %d of %d%s (%s)." % [int(SVm.rig_tier(GameState.col_state())), int(SVm.RIG_STEPS), "" if rig_w != "auto" else ", by what you have bought",
				String(SVm.RIG_NAMES[int(SVm.rig_tier(GameState.col_state()))])], GameState.COL_INFO)
			return ""
		match String(c["sv"]):
			"cores":
				recm["cores"] = int(recm["cores"]) + 100
				recm["cores_all"] = int(recm["cores_all"]) + 100
			"unlock":
				recm["own"] = SVm.UNLOCK_COST.keys()
			"all":                                            # (part 10c) everything the console sells: all unlocked, every figure at its last rank, three rerolls, the last chance
				recm["own"] = SVm.UNLOCK_COST.keys()
				for tq in SVm.TUNE_ORDER:
					recm["tune"][String(tq)] = int(SVm.TUNE_MAX)
				recm["reroll"] = (SVm.REROLL_COST as Array).size()
				recm["revive"] = true
				GameState.sv_give_suit()
			"slain":                                          # (part 10a) the collection: ten of every kind
				for skd in SVm.FOE_ORDER:
					recm["slain"][String(skd)] = int((recm["slain"] as Dictionary).get(String(skd), 0)) + 10
				GameState.log_msg("[Debug] Survivor: ten more of every kind in the collection.", GameState.COL_INFO)
				return ""
			"lock":
				recm["own"] = []
				recm["suit"] = false
				recm["rig_force"] = -1
				recm["slain"] = {}
				recm["beaten"] = []
				recm["stage"] = "outbreak"
				recm["tune"] = {}
				recm["reroll"] = 0
				recm["revive"] = false
				recm["weapon"] = SVm.START_WEAPON
		GameState.log_msg("[Debug] Survivor: %d cores, %d of %d unlocked." % [int(recm["cores"]), (recm["own"] as Array).size(), SVm.UNLOCK_COST.size()], GameState.COL_INFO)
		return ""
	if c.has("sv"):                                       # … part 7: Survivor: "start" a run, a "level", a "swarm", a "minute" on, "end" it
		var gs = _ground()
		if gs == null or not String(gs.level).begins_with("zcol"):
			return "Go into the Colosseum first (Lobby)."
		if String(c["sv"]) == "start":
			GameState.col_registered = true
			load("res://data/colosseum.gd").switch_mode(GameState.col_state(), "survivor")
			gs._close_game()
			gs._sv_start()
			return ""
		if gs.survivor == null or not is_instance_valid(gs.survivor) or bool(gs.survivor.over):
			return "There is no run."
		match String(c["sv"]):
			"level":
				gs.survivor.run["xp"] = int(gs.survivor.run["xp"]) + load("res://data/survivor.gd").need(int(gs.survivor.run["level"]))
			"swarm":
				gs.survivor.swarm(100)
			"minute":
				gs.survivor.run["t"] = float(gs.survivor.run["t"]) + 60.0
			"end":
				gs.survivor.end(false)
			"vent":                                             # (part 9a: Whiteout) the steam vent nearest to you bursts
				var vbest: Dictionary = {}
				for vd in gs.survivor.vents:
					if vbest.is_empty() or (vd["pos"] as Vector2).distance_squared_to(gs.pilot.pos) < (vbest["pos"] as Vector2).distance_squared_to(gs.pilot.pos):
						vbest = vd
				if vbest.is_empty():
					return "There is no steam vent on this stage."
				gs.survivor.vent_burst(vbest)
			"flood":                                            # (the flood of the last two minutes begins now)
				gs.survivor.run["t"] = maxf(float(gs.survivor.run["t"]), float(load("res://data/survivor.gd").FLOOD_FROM))
			"foreman", "brood", "warden", "core", "worm", "heart":
				gs.survivor.boss_start(String(c["sv"]))
			"flock", "ring", "wall", "blackout", "sleepers", "supply", "searchlight", "reinforce", "killline", "emp", "blizzard", "icebreak", "avalanche":
				gs.survivor.event(String(c["sv"]))
			"alpha":
				gs.survivor.make_alpha(gs.survivor.spawn_kind(String(gs.survivor.stg["swarm"]), 1))      # (of the stage's own swarm)
			_:
				var what := String(c["sv"])
				var SVd = load("res://data/survivor.gd")
				if what.begins_with("item:") and SVd.ITEMS.has(what.trim_prefix("item:")):
					gs.survivor.give(what.trim_prefix("item:"))
				elif what.begins_with("carry:"):                   # (part 7c-3) a weapon or a bonus more, or a level of it; "carry:ult": all you carry at their ultimates
					var cid := what.trim_prefix("carry:")
					var crun: Dictionary = gs.survivor.run
					if cid == "ult":
						for cw in crun["weapons"]:
							cw[1] = SVd.ULT
					elif SVd.WEAPONS.has(cid):
						var ce := String(SVd.apply(crun, {"kind": "weapon" if SVd.weapon_level(crun, cid) == 0 else "up", "id": cid}))
						if ce != "":
							return ce
					elif SVd.BONI.has(cid):
						var cb := String(SVd.apply(crun, {"kind": "bonus" if SVd.bonus_level(crun, cid) == 0 else "bonus_up", "id": cid}))
						if cb != "":
							return cb
					else:
						return "No such thing."
					gs.survivor.mods = SVd.mods(crun)
				elif what.begins_with("draw:"):                    # (part 7f) a weapon crate's draw, with one, three or five rewards
					if gs.minigame != null:
						return "A window is open."
					gs.survivor.open_draw(false, clampi(int(what.trim_prefix("draw:")), 1, 5))
				elif SVd.FOES.has(what):
					gs.survivor.swarm(2 if what == "hauler" else 6, what)
				else:
					return "No such thing."
		return ""
	if c.has("col_xp"):                                   # … part 4: rank points
		GameState.col_state()["xp"] = maxi(0, int(GameState.col_state()["xp"]) + int(c["col_xp"]))
		GameState.log_msg("[Debug] The Colosseum: rank %s." % String(load("res://data/colosseum.gd").rank_state(GameState.col_state())["name"]), GameState.COL_INFO)
		return ""
	if c.has("col_fight"):                                # … the fight you stand in is won or lost at once
		var gf = _ground()
		if gf == null or String(gf.level) != "zcolvr":
			return "There is no fight."
		gf._col_fight_over(String(c["col_fight"]) == "win")
		return ""
	if c.has("col_points"):                               # … part 3: gear points into your budget
		GameState.col_state()["points"] = maxi(0, int(GameState.col_state()["points"]) + int(c["col_points"]))
		GameState.log_msg("[Debug] The Colosseum: %d gear points." % (load("res://data/colosseum.gd").budget(GameState.col_state())), GameState.COL_INFO)
		return ""
	if String(c.get("place", "")) in ["colosseum", "lobby", "stands", "arena"]:      # package 62a: straight onto the plaza before the Colosseum, into its lobby, onto its stands
		var e0 := _c_debug_casino({"to": 0})
		var g0 = _ground()
		if e0 != "" or g0 == null:
			return e0
		g0.ctr_stop = 2
		match String(c["place"]):
			"lobby":
				g0.go_level("zcolin", "from_plaza")
			"stands":
				g0.go_level("zcolst", "from_lobby")
			"arena":
				g0.go_level("zcolar", "from_gate")
			_:
				g0.go_level("zcol", "from_station")
		return ""
	if c.has("vip"):
		GameState.casino_vip = bool(c["vip"])
		GameState.log_msg("[Debug] The Grand Centauria: %s." % ("you are a member now" if GameState.casino_vip else "you are no member any more"), GameState.COL_INFO)
	if c.has("coins"):
		GameState.coins = maxi(0, GameState.coins + int(c["coins"]))
		GameState.log_msg("[Debug] Coins: %d." % GameState.coins, GameState.COL_INFO)
	if c.has("coins2"):                                     # split screen: Coins into the second player's own purse
		if not GameState.has_pilot2():
			return "There is no second player in this game."
		GameState.add_coins(1, int(c["coins2"]))
		GameState.log_msg("[Debug] %s's Coins: %d." % [String(GameState.pilot2["name"]), GameState.coins_of(1)], GameState.COL_INFO)
	var g = _ground()
	if not c.has("to"):
		if g != null and String(g.level) == "zcasino":
			g._ctr_title()
		return ""
	var to := clampi(int(c["to"]), 0, 5)
	if g == null or not g.is_centauria():
		var sid := Universe.special_system("fern")
		if sid < 0:
			return "No Fern in this cluster."
		var f := _fit()
		if f == null or f.system_id != sid:
			var e := _c_debug_teleport({"system": sid})
			if e != "":
				return e
		var body := {}
		for p in Universe.get_layout(sid)["moons"]:
			if String(p.get("name", "")) == "Pelagia":
				body = p
		if body.is_empty():
			return "No Pelagia here."
		var e2 := _c_debug_land({"body": String(body["id"]), "kind": "city"})
		if e2 != "":
			return e2
		g = _ground()
		if g == null or not g.is_centauria():
			return "Not in Centauria."
	if to == 5:
		GameState.casino_vip = true
	g._close_lift_menu()
	g._clift = {}
	g._ctr_floor_go(to, true)
	return ""


## {"type":"debug_poi_reveal"} – package 53a: the whole site on the minimap.
func _c_debug_poi_reveal(_c: Dictionary) -> String:
	var g = _ground()
	if g == null or g._mm == null:
		return "Not at a site."
	for y in g.map.h:
		for x in g.map.w:
			g.poi_seen[y * g.map.w + x] = 1
			g._mm_img.set_pixel(x, y, g._mm_col(x, y))
	g._mm_tex.update(g._mm_img)
	return ""


## {"type":"debug_vault"} – 0.7.52.23 (Luz): the debug vault, a closed room in a station: a sealed blast door with
## a box to cut open beside it (the release button behind the flap), behind it a relic in a laser cage and a terminal
## to switch the lasers off. A cutting torch and a scanner go onto your belt.
func _c_debug_vault(_c: Dictionary) -> String:
	var m = _main()
	var f := _fit()
	if m == null or f == null:
		return "No game running."
	if f.in_transit():
		return "Not during a hyperspace jump."
	var L := Universe.get_layout(f.system_id)
	var body := {}
	for b in L["planets"] + L.get("moons", []):
		if Universe.landable(b) and body.is_empty():
			body = b
	if body.is_empty():
		return "No body here to hang the vault on."
	var site := {"id": "%s_dbg_vault" % String(body["id"]), "kind": "crash", "lon": -0.3, "lat": -0.2, "name": "Debug Vault", "vault": true, "foes": []}
	_debug_leave_space(m)
	f.docked_at = "land:" + String(body["id"])
	m.land_at(body, site)
	var g = _ground()
	if g == null:
		return "Could not open the vault."
	_c_debug_explore({"tools_only": true})
	GameState.log_msg("[Debug] The vault: cut the box by the door, hack the terminal, scan the relic.", GameState.COL_WARN)
	return ""


## {"type":"debug_explore"} – 0.7.52.22 (package 52b): a maintenance box with a button, one with a terminal, a
## terminal, a carved tablet and a relic round you; a cutting torch and a scanner onto your belt.
func _c_debug_explore(_c: Dictionary) -> String:
	var g = _ground()
	if g == null:
		return "Not on foot."
	var p: Vector2 = g.pilot.pos
	var tools_only := bool(_c.get("tools_only", false))
	var put := func(off: Vector2) -> Vector2:
		var q: Vector2 = p + off
		for r in range(0, 80, 6):
			for k in 8:
				var qq: Vector2 = q + Vector2(r, 0).rotated(k * TAU / 8.0)
				if g.map.free_at(qq, 8.0):
					return qq
		return q
	if not tools_only:
		g.add_explore("panel", put.call(Vector2(-70, -40)), {"inside": "button"})
		g.add_explore("panel", put.call(Vector2(-20, -60)), {"inside": "terminal", "actions": ["door", "power", "turrets", "cameras", "data"]})
		g.add_explore("terminal", put.call(Vector2(40, -60)), {"actions": ["door", "power", "data"], "level": 2})
		g.add_explore("tablet", put.call(Vector2(80, -20)))
		g.add_explore("relic", put.call(Vector2(80, 30)))
	var gear = GameState.gear
	var used: Array = []
	for tool in ["tl_cutter:C", "tl_scanner:C", "cs_breach"]:
		if g.belt_tool(tool.get_slice(":", 0)) != "":
			continue
		var at := -1
		for i in gear.belt.size():
			if (gear.belt[i] as Dictionary).is_empty() and at < 0:
				at = i
		for j in range(gear.belt.size() - 1, -1, -1):          # none free: the last places not just filled
			if at < 0 and not used.has(j):
				at = j
		if at >= 0:
			gear.belt[at] = {"id": tool, "n": 5 if tool == "cs_breach" else 1}
			used.append(at)
	return ""


func _c_debug_gear(c: Dictionary) -> String:
	var g = GameState.gear
	if g == null:
		return "No pilot."
	var GD = GearShop.GearData
	if c.has("give"):
		var id := String(c["give"])
		if not GD.valid(id):
			return "Unknown gear '%s'." % id
		var n := clampi(int(c.get("n", 1)), 1, 99)
		var left: int = g.add_item(id, n)
		if left >= n:
			return "Your pockets are full."
		GameState.log_msg("[Debug] %s ×%d into the pockets." % [GD.display_name(id), n - left], GameState.COL_WARN)
	if c.get("grenades", false):                        # 0.7.52.5: frag, smoke, shield, EMP on the belt
		var grs := ["gr_frag", "gr_shield", "gr_smoke", "gr_emp"]
		for i in g.grenades.size():
			g.grenades[i] = {"id": grs[i % grs.size()], "n": GD.stack_max(grs[i % grs.size()])}
		g.gr_sel = 0
		GameState.log_msg("[Debug] Grenade places filled.", GameState.COL_WARN)
	if c.has("drone"):                                 # 0.7.52.11: a drone module straight into the drone place
		var did := String(c["drone"])
		if not GD.valid(did) or GD.kind(did) != "drone":
			return "Unknown drone '%s'." % did
		if g.drones.is_empty():
			return "Only combat suits have a drone place."
		g.drones[0] = did
		GameState.log_msg("[Debug] %s in the drone place." % GD.display_name(did), GameState.COL_WARN)
	if c.get("fill_belt", false):
		for i in g.belt.size():
			var fam: String = DEBUG_BELT[i % DEBUG_BELT.size()]
			g.belt[i] = {"id": fam, "n": GD.stack_max(fam)}
		GameState.log_msg("[Debug] Belt filled.", GameState.COL_WARN)
	if c.get("refill", false):
		g.refill()
	if c.get("clear", false):
		for i2 in g.inv.size():
			g.inv[i2] = {}
	if c.has("set"):
		var t: Dictionary = g.totals()
		var sv: Dictionary = c["set"]
		for k in sv:
			var pct := clampf(float(sv[k]), 0.0, 100.0) / 100.0
			match String(k):
				"health":
					g.health = GD.HEALTH * pct
				"energy":
					g.energy = float(t["energy"]) * pct
				"oxygen":
					g.oxygen = float(t["oxygen"]) * pct
				"ammo":
					g.ammo = int(round(float(t["ammo"]) * pct))
	if c.has("suit_god"):
		suit_god = bool(c["suit_god"])
		GameState.log_msg("[Debug] Suit invulnerable %s." % ("ON" if suit_god else "off"), GameState.COL_WARN)
	return ""


## {"type":"debug_env", "world": a world type ("" = the place's own)} – package 51: the world outside on this ground map.
func _c_debug_env(c: Dictionary) -> String:
	var g = _ground()
	if g == null:
		return "Not on foot."
	var GD = GearShop.GearData
	var wt := String(c.get("world", ""))
	if wt == "":
		g.env = GD.env_of(String(g._body.get("type", ""))) if g.level in ["landing", "settlement", "dungeon"] else {}
	elif GD.ENV.has(wt):
		g.env = GD.env_of(wt)
	else:
		return "Unknown world type."
	g._warned = {}
	g.pilot.look = g.pilot_look()
	GameState.log_msg("[Debug] Outside now: %s." % ("as the place is" if wt == "" else String(Universe.body_type(wt)["name"])), GameState.COL_WARN)
	return ""


## {"type":"debug_collapse"} – package 51: the body gives out now (you wake in a clinic).
func _c_debug_collapse(_c: Dictionary) -> String:
	var g = _ground()
	if g == null:
		return "Not on foot."
	g._collapse()
	return ""


## {"type":"debug_wake_clinic"} – package 51: wake in the clinic of the docked station (or city).
func _c_debug_wake_clinic(_c: Dictionary) -> String:
	var m = _main()
	var st := docked_station()
	if m == null or st.is_empty():
		return "Dock at a station (or land in a city) first."
	if bool(st.get("settlement", false)):
		return "No clinic in a settlement."
	if m.station_panel.visible:
		m.station_panel.close()
	m._wake_at(st)
	return ""


# ---------------------------------------------------------------- package 52: fights on foot

const FoeData = preload("res://data/foes.gd")
const DEBUG_ARENA_FOES := ["bandit_rifleman", "bandit_scrapper", "bandit_gunner"]


## {"type":"debug_arena", "world": a world type ("" = the body's own), "foes": [kinds] (default: three bandits),
##  "body": id} – package 52 (0.7.52.4: a foe as "kind@tier", tier green/yellow/red): down by the landing drone to the debug arena on a body here: the drone's pad, a field of
## cover, foes at the far side.
func _c_debug_arena(c: Dictionary) -> String:
	var m = _main()
	var f := _fit()
	if m == null or f == null:
		return "No game running."
	if f.in_transit():
		return "Not during a hyperspace jump."
	var body := Universe.find_body(f.system_id, String(c.get("body", "")))
	if body.is_empty():
		var L := Universe.get_layout(f.system_id)
		for b in L["planets"] + L.get("moons", []):
			if Universe.landable(b):
				body = b
				break
	var wt := String(c.get("world", ""))
	if wt != "" and not (Universe.PLANET_TYPES.has(wt) or Universe.MOON_TYPES.has(wt)):
		return "Unknown world type."
	if not body.is_empty():
		body = Universe.debug_body_as(body, wt)
	if body.is_empty() or not Universe.landable(body):
		return "No body to land on here."
	var kinds: Array = c.get("foes", DEBUG_ARENA_FOES)
	for k in kinds:
		var pe: Array = FoeData.parse(String(k))                  # 0.7.52.4: "kind@tier"
		if not FoeData.FOES.has(String(pe[0])) or (String(k).contains("@") and not FoeData.TIERS.has(String(k).split("@")[1])):
			return "Unknown foe '%s'." % String(k)
	var site := {"id": "%s_dbg_arena" % String(body["id"]), "kind": "crash", "lon": -0.3, "lat": -0.2, "name": "Debug Arena",
		"arena": true, "foes": kinds.duplicate()}
	_debug_leave_space(m)
	f.docked_at = "land:" + String(body["id"])
	m.land_at(body, site)
	if _ground() == null or _ground().combat == null:
		return "Could not open the arena."
	GameState.log_msg("[Debug] Arena on %s: %d foes." % [String(body["name"]), kinds.size()], GameState.COL_WARN)
	return ""


## {"type":"debug_foe", "kind": id, "n": 1, "quality": "" | F–A, "tier": green|yellow|red, "near": bool} – package 52: foes into the fight here
## (at the far side, or near you), aware of you at once.
func _c_debug_foe(c: Dictionary) -> String:
	var g = _ground()
	if g == null or g.combat == null:
		return "No fight possible here: open the arena first."
	var kind := String(c.get("kind", "bandit_rifleman"))
	if not FoeData.FOES.has(kind):
		return "Unknown foe '%s'." % kind
	var q := String(c.get("quality", ""))
	if q != "" and not q in GearShop.GearData.QUALITIES:
		return "Unknown quality."
	var tier := String(c.get("tier", "green"))
	if not FoeData.TIERS.has(tier):
		return "Unknown tier."
	var n := clampi(int(c.get("n", 1)), 1, 12)
	var made := 0
	for i in n:
		var at := Vector2.INF
		if bool(c.get("near", false)):
			for tries in 12:
				at = g.combat._free_near(g.pilot.pos + Vector2(randf_range(90, 160), 0).rotated(randf() * TAU))
				if at != Vector2.INF:
					break
		elif not g.map.foe_spawns.is_empty():
			at = g.map.foe_spawns[randi() % g.map.foe_spawns.size()] + Vector2(randf_range(-10, 10), randf_range(-6, 6))
			if not g.map.free_at(at, 5.0):
				at = g.combat._free_near(at)
		if at == Vector2.INF:
			continue
		var fo: Dictionary = g.combat.spawn(kind, at, q, tier)
		g.combat._wake(fo)
		made += 1
	GameState.log_msg("[Debug] %d × %s." % [made, String(FoeData.FOES[kind]["name"])], GameState.COL_WARN)
	return "" if made > 0 else "No room for them."


## {"type":"debug_combat", "do": "kill"|"end"|"freeze"|"ai"|"hurt"|"tactics", "on": bool, "amount": 30, "mode": 0–2} – package 52: every foe
## down; the fight over (foes gone); foes frozen; the AI view (cover tiles, sight lines, states, chances); hurt yourself.
func _c_debug_combat(c: Dictionary) -> String:
	var g = _ground()
	if g == null or g.combat == null:
		return "No fight here."
	var cb = g.combat
	match String(c.get("do", "")):
		"kill":
			for fo in cb.alive():
				cb._hurt_foe(fo, 99999.0, "explosive")
		"end":
			for fo2 in cb.foes:
				(fo2["w"] as Node).queue_free()
			cb.foes.clear()
			cb.locks.clear()
			cb.active = null
		"freeze":
			cb.frozen = bool(c.get("on", not cb.frozen))
		"ai":
			cb.show_ai = bool(c.get("on", not cb.show_ai))
		"hurt":
			cb._hurt_pilot(float(c.get("amount", 30.0)), String(c.get("dtype", "kinetic")))
		"team":                                        # 0.7.52.20: two test companions ("roles", "quality") – not of your crew
			var roles: Array = c.get("roles", ["gunner", "engineer"])
			for a0 in cb.allies:
				(a0["w"] as Node).queue_free()
			cb.allies.clear()
			cb._team_made = true
			for ri in mini(roles.size(), CrewData.TEAM_MAX):
				var tm: Dictionary = GameState.new_crew(String(roles[ri]), String(c.get("quality", "C")), "")
				tm["stance"] = String(c.get("stance", "careful"))
				cb.spawn_ally(tm, ri)
		"team_down":                                   # the first member standing goes down
			for a1 in cb.allies_up():
				cb._hurt_ally(a1, 99999.0, "explosive")
				break
		"team_revive":
			for a2 in cb.allies:
				cb.revive(a2)
		"team_ready":                                  # their abilities ready at once
			for a3 in cb.allies:
				a3["ab"] = 0.0
		"team_die":                                    # a member down dies at once
			for a4 in cb.allies:
				if a4["down"] and not a4["dead"]:
					cb._ally_dies(a4)
		"drone_kill":                                  # 0.7.52.11: your drone shot down
			var keep: int = cb.drone_slot                    # 0.7.52.18: "place" 0 / 1
			cb.pick_drone(int(c.get("place", 0)))
			cb._hurt_drone_one(99999.0, "kinetic")
			cb.pick_drone(keep)
		"drone_ready":                                 # a new drone at once
			for di in 2:
				cb.pick_drone(di)
				cb.drone_rebuild = 0.0
				cb.drone = {}
			cb.pick_drone(0)
		"tactics":                                     # 0.7.52.2: the tactical view – 0 off, 1 your sight, 2 the target's
			cb.tactics = clampi(int(c.get("mode", 1)), 0, 2)
			cb._vis = {}
			if c.has("zoom"):                             # 0.7.52.8: the tactical view zoomed out (< 1) or not
				g.tac_zoom = g.TAC_ZOOM_OUT if float(c["zoom"]) < 1.0 else 1.0
		_:
			return "Unknown combat debug."
	return ""
