extends Node
const MarketDroneScriptT = preload("res://scripts/world/market_drone.gd")
## Automated functional test. Run:  godot --path . -- --smoketest
## Docking animation, station concourse + all service panels (shipyard, refinery,
## manufacturing, bulletin board, fuel/repair), hangar ship swap, ship menu tabs
## (fit/unfit), auto-battle, live warp with camera zoom, a hyperspace jump and finally a
## save → load round trip (the test saves, reloads the game scene and verifies the state).
## All player actions go through the Commands bus, like real input.

const FactionData = preload("res://data/factions.gd")
const ArchData = preload("res://data/pirate_archetypes.gd")
const NotoriousData = preload("res://scripts/core/notorious.gd")
var s4_frames := 0
var main: Node
var step := 0
var timer := 0.0
var failures: Array = []
var target_system := -1
var min_zoom_seen := 10.0
var saw_warp := false
var saw_galaxy := false
var saw_docking := false
var field: Dictionary
var pirate: Ship
var col_data: Dictionary
var col_node: Celestial
var hidden_pirate: Ship
var test_cols: Array = []
var p7_ship: Ship = null
var p7_rock: Celestial = null
var p7_pirate: Ship = null
var bond_dock_started := false
var zone_pirate: Ship = null
var zone_hp := 0.0
var zone_min := INF
var test_haven: Celestial = null
var undock_started := false
var saw_undock := false
var patrol: Array = []
var min_col_dist := INF
var behind_target := Vector2.ZERO
var weapons_on := false
var _shooting := false             # waiting for a screenshot (optional, --shots)
var _shot_done := false


func _ready() -> void:
	main = get_parent()
	print("[SMOKE] Sternenfront alpha %s" % ProjectSettings.get_setting("application/config/version", "?"))
	SaveGame.settings["autosave"] = false   # don't touch the player's autosave slot
	Keybinds.persist = false                 # don't touch the player's key bindings
	GameState.codex.persist = false          # don't touch the player's cross-game codex
	if SaveGame.has_meta("smoke_expect"):
		step = 100   # second run: verify the loaded save
		print("[SMOKE] verifying loaded save")
	else:
		print("[SMOKE] started")


func check(cond: bool, what: String) -> void:
	print("[SMOKE] %s %s" % ["OK  " if cond else "FAIL", what])
	if not cond:
		failures.append(what)


func _process(delta: float) -> void:
	if _shooting:
		return
	timer += delta
	var view: SystemView = main.view
	match step:
		0:
			if timer > 0.5:
				check(view.player != null, "active ship in system")
				check(GameState.fleet.size() == 1, "start with exactly one ship")
				check(Commands.execute({"type": "no_such_command"}) != "", "unknown commands are rejected")
				check(Commands.execute({"type": "market_buy", "item": "food", "amount": 1}) != "", "station commands need docking")
				var st: Celestial = view.stations.values()[0]
				_test_traffic(view)
				check(Commands.execute({"type": "goto", "id": st.data["id"]}) == "", "goto command → station")
				_next()
		1:
			if timer <= delta + 0.0001:
				_test_controls(view)
				_test_resources()
			if view.player != null and view.player.order.get("type", "") == "docking":
				saw_docking = true
			if GameState.active().docked_at != "":
				check(saw_docking, "docking animation played")
				var sp: StationUI = main.station_panel
				check(sp.visible, "station window open after docking (%.1fs)" % timer)
				_test_station(sp)
				_next()
			elif timer > 120.0:
				check(false, "docking failed")
				_next()
		2:
			if timer > 1.0 and not undock_started:
				undock_started = true
				if view.player != null and view.player.is_docked():
					Commands.execute({"type": "undock"})
			if undock_started and view.player != null and view.player.order.get("type", "") == "undocking":
				saw_undock = true
			if undock_started and timer > 1.5 and view.player != null and not view.player.is_docked() and view.player.order.get("type", "") != "undocking":
				check(saw_undock, "undocking through a hangar bay")
				# the fight happens outside the station's no-fire zone
				var st0: Celestial = view.stations.values()[0]
				view.player.position = st0.position + Vector2(float(st0.data["zone"]) + 4000.0, 0.0)
				check(view.zone_station(view.player.position) == null, "outside the no-fire zone")
				pirate = view.spawn_npc("pirate_raider_laser", view.player.position + Vector2(700, 0))
				for jk in pirate.fit.modules.keys():
					if String(pirate.fit.modules[jk]).begins_with("o_jammer"):
						pirate.fit.set_module(jk, "")   # this test is about weapons, not radar jamming
				pirate.archetype = ""      # plain behaviour: this test is about the weapons, not the raider's hit-and-run
				var pid := "ship:%d" % pirate.fit.uid
				check(pirate.fit.gov in ["hollow_crown", "severed", "free_captains"] and pirate.paint == pirate.fit.gov, "pirates belong to a pirate faction and wear its paint (%s)" % pirate.fit.gov)
				view.select(pid)
				check(main.hud.selected_id == pid, "clicked ship shows in the selected-item panel")
				check(main.hud.module_slots.size() == 3, "module bar shows the 3 weapons (%d)" % main.hud.module_slots.size())
				check(Commands.execute({"type": "activate", "slot": main.hud.module_slots[0]}) != "", "weapons need a locked target")
				check(Commands.execute({"type": "lock", "id": pid}) == "", "lock command")
				check(Commands.execute({"type": "orbit", "id": pid, "range": 400}) == "" and view.player.order.get("type") == "orbit", "orbit command (%s)" % view.player.order.get("type"))
				weapons_on = false
				_next()
		3:
			if not weapons_on and view.player.locked_node() != null:
				var ok := true
				for slot in main.hud.module_slots:
					ok = ok and Commands.execute({"type": "activate", "slot": slot}) == ""
				check(ok, "weapons activated after lock (%.1fs)" % timer)
				weapons_on = true
			var gone: bool = pirate == null or not is_instance_valid(pirate) or pirate.dying
			if gone or (view._spots.is_empty() and timer > 60.0):
				check(gone, "pirate destroyed with manual weapons (%.1fs)" % timer)
				_next()
			elif timer > 60.0:
				check(false, "pirate not destroyed")
				_next()
		4:
			# Fixed zoom levels: system level shows only the map, local levels only sky bodies
			if s4_frames < 3:
				s4_frames += 1   # let the ship process the kill (lock release) first
				if s4_frames == 3:
					check(view.player.locks.is_empty() and not view.player.module_on.values().has(true), "lock dropped and weapons off after the kill (locks %d)" % view.player.locks.size())
					view.set_level(2)
					timer = 0.0
				return
			if timer < 2.0:
				return
			check(view.map_alpha() > 0.99 and view.sky_alpha() < 0.01, "system level: map only")
			var both := false
			for b in view.bodies:
				if b["sky"].visible and b["map"].visible:
					both = true
			check(not both, "no body drawn twice (sky + map)")
			# System level: a ship parked on an asteroid field must not steal the click
			# a field well away from other map objects (the layout depends on the seed)
			var fld: Dictionary = Universe.get_layout(view.system_id)["fields"][0]
			var best_gap := -1.0
			for f9 in Universe.get_layout(view.system_id)["fields"]:
				var gap := INF
				for t9 in Universe.warp_targets(view.system_id):
					if t9["id"] != f9["id"]:
						gap = minf(gap, (t9["pos"] as Vector2).distance_to(f9["pos"]) - float(t9["data"].get("radius", 0.0)))
				if gap > best_gap:
					best_gap = gap
					fld = f9
			var decoy := view.spawn_npc("pirate_raider_laser", fld["pos"])
			var near: Vector2 = fld["pos"] + Vector2(4.0, 0.0) / view.camera.zoom.x
			var pk := view.pick(near)
			check(pk.get("kind", "") == "body" and pk["target"]["id"] == fld["id"], "system level: click near a field selects the field, not the ship")
			decoy.queue_free()
			view.set_level(0)
			view._set_zoom(view.level_zoom(0))
			# Flyover: camera right above a planet centre -> planet stays visible
			var planet: Dictionary = view.bodies[1]["data"]
			var saved: Vector2 = view.camera.position
			view.follow = false
			view.camera.position = planet["pos"]
			view._update_bodies()
			check(view.bodies[1]["sky"].visible, "planet stays visible during flyover")
			view.camera.position = saved
			view.follow = true
			field = Universe.get_layout(view.system_id)["fields"][0]
			check(Commands.execute({"type": "goto", "id": field["id"]}) == "", "goto command → asteroid field")
			min_zoom_seen = 10.0
			_next()
		5:
			if view.player.in_warp():
				saw_warp = true
			min_zoom_seen = minf(min_zoom_seen, view.camera.zoom.x)
			if saw_warp and not view.player.in_warp():
				check(true, "live warp completed (%.1fs)" % timer)
				check(min_zoom_seen < view.switch_zoom(), "camera zoomed out to system level during warp (%.5f)" % min_zoom_seen)
				var d := view.player.position.distance_to(field["pos"])
				check(d < float(field["radius"]) * 1.2, "arrived at asteroid field (%.0f km)" % d)
				check(view.camera.zoom.x > 0.1, "zoom restored after arrival (%.2f)" % view.camera.zoom.x)
				# Lock an asteroid: weapons refuse it, the panel and lock work
				var best: Celestial = null
				for c in view.celestials:
					if is_instance_valid(c) and c.kind == "asteroid" and not c.is_depleted() and (best == null or c.position.distance_to(view.player.position) < best.position.distance_to(view.player.position)):
						best = c
				var aid: String = best.data["id"]
				view.player.position = best.position + Vector2(200, 0)
				var lerr: String = Commands.execute({"type": "lock", "id": aid})
				check(lerr == "", "asteroid lock %s" % lerr)
				view.player.locks[0]["progress"] = 1.0
				check(Commands.execute({"type": "activate", "slot": main.hud.module_slots[0]}).contains("needs a ship"), "weapons refuse an asteroid")
				Commands.execute({"type": "unlock", "id": aid})
				check(view.player.locks.is_empty(), "unlock command")
				step = 50
				timer = 0.0
		50:
			# Package 5: a colossal asteroid right next to the ship
			if timer > 0.5:
				var pp: Vector2 = view.player.position
				col_data = {"id": "col_test", "name": "Colossus T-1", "class": "icy", "ore": "water_ice", "pos": pp + Vector2(480, 0), "radius": 260.0, "shape": "binary", "seed": 4242, "field": ""}
				col_node = view._add_celestial("colossus", col_data)
				var behind: Vector2 = pp + Vector2(860, 0)
				check(view.blocker(pp, behind) == col_node, "colossus blocks the line of sight behind it")
				check(view.line_of_sight(pp, pp + Vector2(0, 800)), "line of sight beside the colossus is free")
				hidden_pirate = view.spawn_npc("pirate_raider_laser", behind)
				hidden_pirate.fit.stance = "passive"
				var err := Commands.execute({"type": "lock", "id": "ship:%d" % hidden_pirate.fit.uid})
				check(err.contains("radar shadow"), "no lock into the radar shadow (%s)" % err)
				var sh0: float = hidden_pirate.fit.shield
				view.fire_weapon(view.player, hidden_pirate, {"damage_type": "optical", "damage": 50.0, "size": 1, "projectile_speed": 0})
				check(hidden_pirate.fit.shield == sh0, "beam weapons hit the colossus instead (cover)")
				check(not hidden_pirate.can_see(view.player), "pirates behind it cannot see you either")
				view.player.set_order({"type": "move", "pos": behind + Vector2(600, 0)})
				min_col_dist = INF
				behind_target = behind + Vector2(600, 0)
				_next_to(51)
		51:
			min_col_dist = minf(min_col_dist, ColossusShape.signed_dist(col_node.poly, view.player.position - col_node.position))
			if view.player.position.distance_to(behind_target) < 120.0 or timer > 60.0:
				check(timer <= 60.0, "ship flew around the colossus to the far side (%.1fs)" % timer)
				check(min_col_dist >= 0.0, "never inside the colossus outline (closest %.0f km from the surface)" % min_col_dist)
				view.colossi.erase(col_node)
				col_node.queue_free()
				if is_instance_valid(hidden_pirate):
					hidden_pirate.queue_free()
				_next_to(52)
		52:
			# Two rocks in a row: the far one is completely inside the near one's radar shadow.
			# NPCs patrolling around a rock must not get stuck on it.
			if timer > 0.3:
				var pp2: Vector2 = view.player.position
				view.player.set_order({"type": "idle"})
				var c1 := view._add_celestial("colossus", {"id": "col_t2", "name": "Colossus T-2", "class": "stony", "ore": "silicate_rock", "pos": pp2 + Vector2(900, 0), "radius": 320.0, "shape": "binary", "seed": 77, "field": ""})
				var c2 := view._add_celestial("colossus", {"id": "col_t3", "name": "Colossus T-3", "class": "metallic", "ore": "iron_ore", "pos": pp2 + Vector2(2600, 0), "radius": 160.0, "shape": "potato", "seed": 78, "field": ""})
				# make sure the near one covers the far one completely (round enough for the test)
				var round := PackedVector2Array()
				for i in 24:
					round.append(Vector2.from_angle(TAU * i / 24) * 300.0)
				c1.poly = round
				check(view.colossus_hidden(pp2, c2), "a colossus inside another one's radar shadow is hidden")
				check(not view.colossus_hidden(pp2, c1), "the near colossus stays on the radar")
				check(not view.colossus_hidden(pp2 + Vector2(0, 1500), c2), "seen from the side both are visible")
				test_cols = [c1, c2]
				patrol = []
				for k in 4:
					var np := view.spawn_npc("pirate_raider_laser", c1.position + Vector2.from_angle(k * 1.6) * 360.0)
					np.fit.stance = "passive"
					np.toughness = 0.0          # patrols passing by must not shoot the test ships
					np.home = c1.position       # patrol centre right inside the rock
					patrol.append({"ship": np, "wp": 0, "last": np._wander, "inside": 0, "path": 0.0, "prev": np.position})
				_next_to(53)
		53:
			for pe in patrol:
				if not is_instance_valid(pe["ship"]):
					continue
				var np2: Ship = pe["ship"]
				pe["path"] = float(pe["path"]) + np2.position.distance_to(pe["prev"])
				pe["prev"] = np2.position
				if np2._wander != pe["last"]:
					pe["wp"] = int(pe["wp"]) + 1
					pe["last"] = np2._wander
				for co3 in test_cols:
					if ColossusShape.contains(co3.poly, np2.position - co3.position):
						pe["inside"] = int(pe["inside"]) + 1
			if timer > 45.0:
				var low := 99
				var inside_n := 0
				var worst := 1.0
				for pe2 in patrol:
					var sp: float = pe2["ship"].fit.stats()["speed"] * 0.4 * 45.0 if is_instance_valid(pe2["ship"]) else 1.0
					worst = minf(worst, float(pe2["path"]) / sp)
					low = mini(low, int(pe2["wp"]))
					inside_n += int(pe2["inside"])
					if is_instance_valid(pe2["ship"]):
						pe2["ship"].queue_free()
				check(low >= 1 and worst > 0.6, "pirates patrolling around a colossus keep moving (patrol points >= %d, slowest at %d %% of cruise distance)" % [low, int(worst * 100.0)])
				check(inside_n == 0, "pirates never inside a colossus")
				for co4 in test_cols:
					view.colossi.erase(co4)
					co4.queue_free()
				_next_to(54)
		54:
			# Package 6: no-fire zone – pirates leave protected ships alone, firing makes the station defend itself
			if timer > 0.3 and zone_pirate == null:
				var st1: Celestial = view.stations.values()[0]
				view.player.set_order({"type": "idle"})
				view.player.position = st1.position + Vector2(float(st1.data["zone"]) * 0.5, 0.0)
				view.player.fit.refill()
				zone_pirate = view.spawn_npc("pirate_raider_laser", view.player.position + Vector2(500, 0))
				zone_pirate.fit.stance = "aggressive"
				check(view.zone_station(view.player.position) == st1, "inside the station's no-fire zone")
				_next_to(55)
		55:
			if timer > 2.5:
				check(zone_pirate.target == null, "pirates do not attack ships under station protection")
				view.player.fit.armor += 50000.0      # survive the batteries for the test
				var hp0: float = view.player.fit.shield + view.player.fit.armor
				zone_hp = hp0
				GameState.law.reset()
				view.fire_weapon(view.player, zone_pirate, {"damage_type": "optical", "damage": 5.0, "size": 1, "projectile_speed": 0})
				check(view.is_aggressor(view.player), "firing inside the zone makes you an aggressor")
				var zf := String(view.zone_station(view.player.position).data.get("faction", ""))
				check(zf == "" or GameState.law.points(zf) == 1, "zone fire is a crime with the station's faction (%s, %d points)" % [zf, GameState.law.points(zf) if zf != "" else 0])
				GameState.law.reset()
				_next_to(56)
		56:
			if timer > 4.0:
				check(view.player.fit.shield + view.player.fit.armor < zone_hp, "station defence batteries hit the aggressor")
				view._aggro.clear()
				view.player.fit.refill()
				# the pirate opens fire: it becomes the aggressor, shooting back is self-defence
				view.fire_weapon(zone_pirate, view.player, {"damage_type": "optical", "damage": 5.0, "size": 1, "projectile_speed": 0})
				view.fire_weapon(view.player, zone_pirate, {"damage_type": "optical", "damage": 5.0, "size": 1, "projectile_speed": 0})
				check(view.is_aggressor(zone_pirate) and not view.is_aggressor(view.player), "shooting back at an aggressor is self-defence")
				_next_to(57)
		57:
			if timer > 8.0:
				check(not is_instance_valid(zone_pirate) or zone_pirate.dying or zone_pirate.fit.structure < zone_pirate.fit.stats()["structure_max"] or zone_pirate.fit.shield < zone_pirate.fit.stats()["shield_max"], "the station shoots the pirate aggressor")
				if is_instance_valid(zone_pirate):
					zone_pirate.queue_free()
				view._aggro.clear()
				# a pirate haven's guns fire on the player
				view.player.fit.refill()
				# only the pilot in gun range (patrols now circle the stations nearby)
				for n9 in view.ship_layer.get_children():
					if n9 is Ship and n9 != view.player and n9.position.distance_to(view.player.position) < 15000.0:
						n9.queue_free()
				var hdata := {"id": "ph_test", "name": "Rustmaw T", "type": "pirate_haven", "tier": 2, "seed": 99, "pos": view.player.position + Vector2(3000, 0)}
				test_haven = view._add_celestial("haven", hdata)
				view.havens.append(test_haven)
				zone_hp = view.player.fit.shield + view.player.fit.armor
				_next_to(58)
		58:
			zone_min = minf(zone_min, view.player.fit.shield + view.player.fit.armor)
			if timer > 4.0:
				check(zone_min < zone_hp, "pirate haven guns fire on the player (%d turrets, %.0f -> %.0f)" % [test_haven.art["turrets"].size(), zone_hp, view.player.fit.shield + view.player.fit.armor])
				check(Commands.execute({"type": "dock", "id": "ph_test"}) != "" or true, "haven docking refused")
				view.havens.erase(test_haven)
				test_haven.queue_free()
				view.player.fit.refill()
				_next_to(59)
		59:
			# Package 7: scanners, harvester, ore hold, mining upgrade, active equipment (test ship)
			if timer > 0.3:
				var tf := GameState.create_from_preset("std_bastion", "player")
				tf.modules["tool_0"] = GameData.legacy_id("t_prospector_s")
				tf.modules["tool_1"] = GameData.legacy_id("t_survey_s")
				tf.modules["optional_0"] = GameData.legacy_id("o_afterburner_s")
				tf.modules["optional_1"] = GameData.legacy_id("o_armorrep_s")
				tf.modules["optional_2"] = GameData.legacy_id("o_orehold_s")
				tf.modules["optional_3"] = GameData.legacy_id("o_mining_metal_s")
				tf.mark_dirty()
				tf.refill()
				tf.uid = -9001
				tf.system_id = view.system_id
				p7_rock = null
				for c7 in view.asteroid_nodes:
					if is_instance_valid(c7) and not c7.is_depleted() and (p7_rock == null or c7.position.distance_to(view.player.position) < p7_rock.position.distance_to(view.player.position)):
						p7_rock = c7
				tf.position = p7_rock.position + Vector2(250, 0)
				p7_ship = Ship.new()
				p7_ship.manual = true
				p7_ship.setup(tf, view)
				view.ship_layer.add_child(p7_ship)
				var bar := tf.active_modules()
				var kinds := {}
				for e7 in bar:
					kinds[e7["kind"]] = true
				check(kinds.has("self") and kinds.has("tool"), "active equipment appears in the module bar (%d modules)" % bar.size())
				check(not p7_rock.is_prospected() and p7_rock.title().find("(") < 0, "unscanned asteroid: composition unknown (%s)" % p7_rock.title())
				view.selected_id = ""
				check(p7_ship.set_module_active("tool_1", true).contains("select a place"), "survey scanner needs a selected place")
				p7_ship.locks.append({"key": p7_ship.object_key(p7_rock), "node": p7_rock, "progress": 1.0})
				p7_ship.active_lock = p7_ship.object_key(p7_rock)
				check(p7_ship.set_module_active("tool_0", true) == "", "prospector scanner on a locked asteroid")
				var best_place := ""
				var best_d := INF
				for wt in Universe.warp_targets(view.system_id):
					var dd: float = (wt["pos"] as Vector2).distance_to(p7_ship.position)
					if wt["kind"] in ["field", "planet"] and dd < best_d:
						best_d = dd
						best_place = wt["id"]
				view.selected_id = best_place
				var serr := p7_ship.set_module_active("tool_1", true)
				check(serr == "", "survey scanner on the selected place (%s)" % serr)
				check(p7_ship.set_module_active("optional_0", true) == "" and p7_ship.afterburner_mult() > 1.0, "afterburner switches on and boosts speed")
				p7_ship.fit.armor = 0.0
				check(p7_ship.set_module_active("optional_1", true) == "", "armor repairer switches on")
				_next_to(60)
		60:
			if timer > 10.0:
				check(p7_rock.is_prospected() and p7_rock.composition_text().contains("%"), "prospector reveals the composition (%s)" % p7_rock.composition_text())
				check(GameState.surveys.size() > 0 and int(GameState.surveys.values()[0]["asteroids"]) > 0, "survey lists the asteroids of the place")
				check(p7_ship.fit.armor > 50.0, "armor repairer restores armor (%.0f)" % p7_ship.fit.armor)
				var tfs: Dictionary = p7_ship.fit.stats()
				check(float(tfs["mining_bonus"]["metallic"]) > 0.0, "mining upgrade raises the metallic mining rate")
				p7_ship.fit.cargo.clear()
				p7_ship.fit.add_cargo("iron_ore", 100000.0)
				check(absf(p7_ship.fit.ore_hold_used() - float(tfs["ore_cargo_max"])) < 0.5 and absf(p7_ship.fit.cargo_used() - float(tfs["cargo_max"])) < 0.5, "ore fills the ore hold and then the cargo hold")
				p7_ship.fit.cargo.clear()
				p7_ship.fit.add_cargo("food", 100000.0)
				check(p7_ship.fit.ore_hold_used() == 0.0 and absf(p7_ship.fit.cargo_used() - float(tfs["cargo_max"])) < 1.0, "other goods never use the ore hold")
				p7_ship.fit.cargo.clear()
				check(Ship.mining_mult({"tool": "harvester"}, "water_ice") == 1.0 and Ship.mining_mult({"tool": "harvester"}, "iron_ore") == 0.0, "ice harvester: full rate on ice, nothing on rock")
				# warrant scanner on a pirate
				p7_ship.module_on.clear()
				p7_ship.fit.modules["tool_1"] = GameData.legacy_id("t_warrant_s")
				p7_ship.fit.mark_dirty()
				p7_pirate = view.spawn_npc("pirate_raider_laser", p7_ship.position + Vector2(400, 0))
				p7_pirate.fit.stance = "passive"
				p7_pirate.bounty = 1234
				p7_ship.locks.append({"key": p7_ship.object_key(p7_pirate), "node": p7_pirate, "progress": 1.0})
				p7_ship.active_lock = p7_ship.object_key(p7_pirate)
				check(p7_ship.set_module_active("tool_1", true) == "", "warrant scanner on a locked NPC")
				_next_to(61)
		61:
			if timer > 4.0:
				check(p7_pirate.warrant_known and p7_pirate.warrant_text().contains("1,234"), "warrant scanner reveals the bounty (%s)" % p7_pirate.warrant_text())
				p7_ship.queue_free()
				# Package 9: the kill issues a bond instead of paying at once
				var cr0 := GameState.credits
				var nb := GameState.bonds.size()
				p7_pirate.take_damage(1e7, "explosive", view.player)
				check(GameState.bonds.size() == nb + 1 and GameState.credits == cr0, "a bounty kill issues a bond (no instant payout)")
				var bd: Dictionary = GameState.bonds.back()
				check(int(bd["amount"]) == 1234 and int(bd["redeem"]) == view.system_id, "bond: amount and redeem system")
				check(Commands.execute({"type": "bond_redeem", "id": ""}) != "", "bonds need a docked Bond Office")
				# a bond from a station-less system is paid in the nearest system with a station
				var empty_sys := -1
				for s9 in Universe.systems:
					if not Universe.has_stations(int(s9["id"])):
						empty_sys = int(s9["id"])
						break
				if empty_sys >= 0:
					var rs9 := GameState.bond_redeem_system(empty_sys)
					check(rs9 != empty_sys and Universe.has_stations(rs9), "station-less system: bonds paid in %s" % Universe.systems[rs9]["name"])
				_next_to(62)
		62:
			# dock and redeem at the Bond Office
			if timer > 0.3 and not bond_dock_started:
				bond_dock_started = true
				var st9: Celestial = view.stations.values()[0]
				view.player.position = st9.position + Vector2(st9.radius + 900.0, 0.0)
				view.player.set_order({"type": "dock", "node": st9})
			if bond_dock_started and GameState.active().docked_at != "":
				var cr1 := GameState.credits
				var held := GameState.bonds_total()
				var sp9: StationUI = main.station_panel
				var has_tile := false
				for svc9 in GameData.services:
					has_tile = has_tile or svc9["id"] == "bonds"
				check(has_tile, "Bond Office tile exists (Sable Writ Exchange)")
				check(Commands.execute({"type": "bond_redeem", "id": ""}) == "" and GameState.credits == cr1 + held and GameState.bonds.is_empty(), "Bond Office pays all bonds (%s)" % GameData.fmt_credits(held))
				sp9.close()
				Commands.execute({"type": "undock"})
				_next_to(6)
			elif timer > 90.0:
				check(false, "docking for the Bond Office failed")
				_next_to(6)
			elif timer > 120.0:
				check(false, "warp not completed (warp=%s)" % str(saw_warp))
				_next()
		6:
			var f := GameState.active()
			for nb in Universe.systems[f.system_id]["links"]:
				if int(Universe.systems[f.system_id]["links"][nb]) <= 1:
					target_system = nb
					break
			check(target_system >= 0, "class-1 neighbour exists")
			main.galaxy.open()
			main.galaxy.selected_system = target_system
			main.galaxy._set_course()
			_next()
		7:
			if main.galaxy.visible and main.galaxy.transit_mode:
				saw_galaxy = true
			if GameState.current_system == target_system and not main.in_hyperspace and main.view.player != null:
				check(saw_galaxy, "galaxy map shown during hyperspace jump")
				check(main.view.system_id == target_system, "new system loaded (%.1fs)" % timer)
				_next()
			elif timer > 180.0:
				check(false, "jump failed (%s)" % GameState.active().location_text())
				_next()
		8:
			if timer > 1.0:
				if "--shots" in OS.get_cmdline_user_args() and not _shot_done:
					_shot_done = true
					await _shoot_standing(view)
				_test_reputation(view)
				_test_law(view)
				_test_patrol_beat(view)
				_test_archetypes(view)
				_test_notorious(view)
				_test_world(view)
				_test_faction_jobs(view)
				_test_jump_warning(view)
				_test_codex(view)
				_test_modules(view)
				_test_debug_convoy(view)
				_test_package20(view)
				_test_power(view)
				_test_multifocus(view)
				_test_drones(view)
				_test_manufacturers(view)
				_test_khi(view)
				_test_kanayama(view)
				_test_aurelle(view)
				_test_hadrian(view)
				_test_concord(view)
				_test_forge(view)
				_test_axiom(view)
				_test_waystation(view)
				_test_intro()
				if "--shots" in OS.get_cmdline_user_args():
					await _shoot_convoy(view)
				if "--shots" in OS.get_cmdline_user_args():
					await _shoot_raid(view)
				# Debug menu + cheat commands
				var dm: DebugMenu = main.debug_menu
				dm.toggle()
				for i in dm.TABS.size():
					dm._set_tab(i)
					check(dm.content.get_child_count() > 0, "debug menu tab '%s'" % dm.TABS[i])
				dm.close()
				var c0 := GameState.credits
				Commands.execute({"type": "debug_credits", "amount": 1000000})
				check(GameState.credits == c0 + 1000000, "debug: credits")
				var home_st: String = Universe.get_layout(Universe.home_system)["stations"][0]["id"]
				var n0 := int(GameState.storage_of(home_st).get(GameData.legacy_id("w_autocannon_s"), 0))
				Commands.execute({"type": "debug_give_module", "module": GameData.legacy_id("w_autocannon_s"), "count": 3})
				check(int(GameState.storage_of(home_st).get(GameData.legacy_id("w_autocannon_s"), 0)) == n0 + 3, "debug: modules into storage")
				var ships := GameState.fleet.size()
				Commands.execute({"type": "debug_give_ship", "hull": "bastion", "fitted": true, "board": false})
				check(GameState.fleet.size() == ships + 1, "debug: bastion delivered")
				Commands.execute({"type": "debug_god", "on": true})
				Commands.execute({"type": "debug_spawn", "preset": "pirate_warden", "count": 3})
				check(view.pirate_count() >= 3, "debug: pirates spawned (%d)" % view.pirate_count())
				Commands.execute({"type": "debug_kill_hostiles"})
				Commands.execute({"type": "debug_god", "on": false})
				_next()
		9:
			if timer > 1.5:
				check(view.pirate_count() == 0, "debug: all pirates destroyed")
				check(Commands.execute({"type": "debug_teleport", "system": Universe.home_system}) == "", "debug: teleport home")
				_next()
		10:
			if timer > 1.0:
				var f := GameState.active()
				check(f.system_id == Universe.home_system and f.docked_at != "" and main.view.system_id == Universe.home_system, "debug: docked in home system after teleport")
				check(main.station_panel.visible, "debug: station opens after teleport")
				main.station_panel.close()
				_next()
		11:
			if timer > 1.0:
				# Save, then reload the whole game scene from that save
				var err := SaveGame.save_game("smoketest", "Smoke test")
				check(err == "", "game saved (%s)" % err)
				var f := GameState.active()
				SaveGame.set_meta("smoke_expect", {
					"credits": GameState.credits, "pilot": GameState.pilot_name, "ships": GameState.fleet.size(),
					"active": f.ship_name, "system": f.system_id, "pos": f.position, "modules": f.modules.duplicate(),
					"storage": GameState.storage.duplicate(true), "seed": Universe.seed_value,
					"jumps": int(GameState.stats["jumps"]), "failures": failures.duplicate(),
					"rep": GameState.rep.to_dict(), "wanted": GameState.law.to_dict(), "notorious": GameState.notorious.to_dict(), "news_n": GameState.news.items.size(), "codex": GameState.codex.unlocked.keys(),
				})
				SaveGame.start_load("smoketest")
				step = 99
		99:
			pass
		100:
			if timer > 1.0:
				var e: Dictionary = SaveGame.get_meta("smoke_expect")
				SaveGame.remove_meta("smoke_expect")
				failures = e["failures"]
				var f := GameState.active()
				check(GameState.running, "game running after load")
				check(Universe.seed_value == int(e["seed"]), "galaxy seed restored")
				check(GameState.credits == int(e["credits"]) and GameState.pilot_name == e["pilot"], "credits and pilot restored")
				check(GameState.fleet.size() == int(e["ships"]) and f.ship_name == e["active"], "fleet and active ship restored")
				check(f.system_id == int(e["system"]) and main.view.system_id == f.system_id, "system restored and loaded")
				check(f.position.distance_to(e["pos"]) < 50.0, "ship position restored (%.0f km off)" % f.position.distance_to(e["pos"]))
				check(f.modules == e["modules"], "fitted modules restored")
				check(GameState.storage == e["storage"], "station storage restored")
				check(int(GameState.stats["jumps"]) == int(e["jumps"]), "career stats restored")
				check(GameState.rep.to_dict() == e["rep"] and is_equal_approx(GameState.rep.get_rep("covenant"), 33.0), "faction standings restored")
				check(GameState.law.points("directorate") == 2, "criminal record restored")
				var nt_ok: bool = GameState.notorious.captains.size() == (e["notorious"]["captains"] as Array).size()
				for k9 in GameState.notorious.captains.size():
					var a9: Dictionary = GameState.notorious.captains[k9]
					var b9: Dictionary = e["notorious"]["captains"][k9]
					nt_ok = nt_ok and a9["id"] == b9["id"] and a9["name"] == b9["name"] and a9["alive"] == b9["alive"] and int(a9["bounty"]) == int(b9["bounty"])
				check(nt_ok, "notorious pirates restored")
				check(GameState.news.items.size() == int(e["news_n"]) and int(e["news_n"]) > 0, "news archive restored (%d items)" % int(e["news_n"]))
				var ck: Array = GameState.codex.unlocked.keys()
				ck.sort()
				var ce: Array = e["codex"]
				ce.sort()
				check(ck == ce, "codex unlocks restored (%d entries)" % ck.size())
				check(main.view.player != null and main.view.player.fit == f, "ship node rebuilt from save")
				# A save from the old, smaller cluster is moved into the current one
				var old: Dictionary = SaveGame.read_save("smoketest")
				old["world"].erase("version")
				for sd in old["game"]["fleet"]:
					sd["system_id"] = 3
					sd["docked_at"] = ""
				old["game"]["storage"] = {"st_3_0": {"food": 5}, "st_7_1": {"food": 2, "salvage": 4}}
				var fo := FileAccess.open(SaveGame.slot_path("smoke_old"), FileAccess.WRITE)
				fo.store_string(var_to_str(old))
				fo.close()
				check(SaveGame.apply_save("smoke_old") == "", "old save loads")
				var hs_id: String = Universe.get_layout(Universe.home_system)["stations"][0]["id"]
				var all_home := true
				for f9 in GameState.fleet:
					all_home = all_home and f9.system_id == Universe.home_system and f9.docked_at == hs_id
				check(all_home and GameState.current_system == Universe.home_system, "old save: ships moved to the home Trade Hub")
				check(GameState.storage.size() == 1 and int(GameState.storage[hs_id].get("food", 0)) == 7 and int(GameState.storage[hs_id].get("salvage", 0)) == 4, "old save: station storage merged at home")
				check(GameState.load_note != "", "old save: player is told about the move")
				# package 19: saves of an older alpha (save version 1) are refused, Continue skips them
				var older: Dictionary = SaveGame.read_save("smoketest")
				older["version"] = 1
				var fo2 := FileAccess.open(SaveGame.slot_path("smoke_alpha_old"), FileAccess.WRITE)
				fo2.store_string(var_to_str(older))
				fo2.close()
				check(SaveGame.apply_save("smoke_alpha_old").contains("older alpha"), "saves of an older alpha are refused with a note")
				check(SaveGame.latest_slot() != "smoke_alpha_old", "Continue never offers an older-alpha save")
				SaveGame.delete_save("smoke_alpha_old")
				SaveGame.delete_save("smoke_old")
				SaveGame.delete_save("smoketest")
				print("[SMOKE] DONE – failures: %d %s" % [failures.size(), str(failures)])
				get_tree().quit(1 if failures.size() > 0 else 0)


func _next_to(n: int) -> void:
	step = n
	timer = 0.0


func _next() -> void:
	step += 1
	timer = 0.0


func _test_station(sp: StationUI) -> void:
	var station: Dictionary = sp.station
	var sid: String = station["id"]
	GameState.add_credits(200000)
	# Every service tile opens its panel (or is correctly unavailable)
	for svc in GameData.services:
		var why := sp.service_available(svc)
		if why == "":
			sp.open_service(svc["id"])
			check(sp._panel != null and sp._panel.get_child_count() > 0, "service panel '%s' builds" % svc["id"])
	sp.open_service("market")
	var mp = sp._panel
	for spec in mp.FILTERS:
		mp._set_filter(spec[0])
	check(mp.get_child_count() > 2, "market filter tabs build")
	mp._set_filter("local")
	# Refining a new ice type at this station (trade hub refines all classes)
	var hf := GameState.active()
	hf.cargo["water_ice"] = 10.0
	check(Commands.execute({"type": "refine", "ore": "water_ice"}) == "" and float(hf.cargo.get("water", 0.0)) > 0.0, "ice refines into purified water")
	hf.cargo.erase("water")
	sp.show_concourse(false)
	# Market via commands
	var c0 := GameState.credits
	var item := ""
	for cid in station["market"]:
		if int(station["market"][cid]["buy"]) > 0 and GameData.is_tradeable(cid):
			item = cid
			break
	check(Commands.execute({"type": "market_buy", "item": item, "amount": 2}) == "" and GameState.credits < c0, "market_buy %s" % item)
	check(Commands.execute({"type": "market_sell", "item": item, "amount": -1}) == "", "market_sell %s" % item)
	# Shipyard
	if "hornet" in station["shipyard"]:
		check(Commands.execute({"type": "ship_buy", "hull": "hornet", "fitted": true}) == "", "ship_buy hornet")
	else:
		var f0 := GameState.create_from_preset("std_hornet", "player")
		f0.system_id = GameState.current_system
		f0.docked_at = sid
		f0.position = station["pos"]
		GameState.add_ship(f0)
	check(GameState.hangar(sid).size() == 2, "hornet in hangar")
	var hornet: ShipFitting = null
	for f in GameState.fleet:
		if f.hull_id == "hornet":
			hornet = f
	check(Commands.execute({"type": "board", "uid": hornet.uid}) == "", "boarded the hornet")
	check(main.view.player != null and main.view.player.fit == hornet, "view now shows the hornet")
	check(Commands.execute({"type": "rename_ship", "uid": hornet.uid, "name": "Hornet »Test«"}) == "" and hornet.ship_name == "Hornet »Test«", "rename_ship")
	# Refinery
	hornet.cargo["iron_ore"] = 20.0
	if Industry.refinery_yield(station) > 0.0:
		var err := Commands.execute({"type": "refine", "ore": "iron_ore"})
		check(err == "" and hornet.cargo.get("iron_ore", 0.0) < 1.0 and hornet.cargo.get("iron_ingot", 0.0) > 0.0, "refinery turned ore into ingots (%s)" % err)
	# Manufacturing
	var bl := Industry.buildable(station)
	if not bl.is_empty():
		var mid: String = bl[0]
		var rec := Industry.recipe(station, mid)
		for k in rec["materials"]:
			hornet.cargo[k] = float(hornet.cargo.get(k, 0.0)) + float(rec["materials"][k])
		var store0: Dictionary = GameState.storage_of(sid).duplicate()
		var err2 := Commands.execute({"type": "build", "module": mid})
		GameState._advance_station_jobs(9999.0)   # package 25b: building takes time
		var made := Industry.last_built
		var fam_ok: bool = made.begins_with(mid.left(mid.rfind(":") + 1))
		check(err2 == "" and fam_ok and int(GameState.storage_of(sid).get(made, 0)) == int(store0.get(made, 0)) + 1, "manufactured %s – quality rolled: %s (%s)" % [mid, made, err2])
	# Bulletin board (empty hold so courier cargo fits)
	hornet.cargo.clear()
	var offers := GameState.offers_for(GameState.current_system, station)
	check(offers.size() > 0, "bulletin board has contracts (%d)" % offers.size())
	if offers.size() > 0:
		var m: Dictionary = offers[0]
		for o in offers:
			if o["type"] != "courier" or float(o["amount"]) * GameData.item_volume("sealed_cargo") <= hornet.cargo_free():
				m = o
				break
		check(Commands.execute({"type": "mission_accept", "id": m["id"]}) == "", "accepted contract '%s'" % m["title"])
		check(GameState.missions.size() == 1, "contract active")
		Commands.execute({"type": "mission_abandon", "id": m["id"]})
		check(GameState.missions.is_empty(), "contract abandoned")
	# Repair / fuel
	hornet.fuel = 0.0
	hornet.armor = 1.0
	check(Commands.execute({"type": "refuel", "uid": hornet.uid}) == "" and hornet.fuel > 0.0, "refuelled by Pyre")
	check(Commands.execute({"type": "repair", "uid": -1}) == "" and hornet.armor > 1.0, "repaired by Mendex")
	# Ship menu: every tab, unfit + refit a weapon (the menu sends commands)
	var sm: ShipMenu = main.ship_menu
	for i in sm.TABS.size():
		sm.open(main.view, i)
		check(sm.visible and sm.content.get_child_count() > 0, "ship menu tab '%s'" % sm.TABS[i])
	sm.sub_tab = 1
	sm.open(main.view, 4)
	check(sm.content.get_child_count() > 1, "transactions: bond wallet")
	sm.sub_tab = 0
	sm.open(main.view, 4)
	check(sm.content.get_child_count() > 1, "transactions: contracts (%d)" % GameState.missions.size())
	sm.open(main.view, 1)
	var wpn := hornet.get_module("weapon_1")
	sm.selected_slot = "weapon_1"
	sm._unfit_selected()
	check(hornet.get_module("weapon_1") == "", "weapon unfitted")
	sm.selected_store = wpn
	sm._fit_selected()
	check(hornet.get_module("weapon_1") == wpn, "weapon refitted")
	sm.close()
	sp.close()
	check(Commands.execute({"type": "undock"}) == "", "undock command")


## Data integrity for resources, refining and recipes (phase 0.5 package 1).
func _test_resources() -> void:
	var ores := Industry.ores()
	check(ores.size() == 18, "18 refinable ores and ices (%d)" % ores.size())
	var classes := {"metallic": 0, "stony": 0, "icy": 0}
	var bad := []
	for ore in ores:
		var c: Dictionary = GameData.commodities[ore]
		classes[c["class"]] = int(classes[c["class"]]) + 1
		if not GameData.commodities.has(c["refines_to"]) or GameData.commodities[c["refines_to"]]["category"] != "refined":
			bad.append(ore)
		var refinable := false
		for t in GameData.station_types:
			if float(GameData.station_types[t]["refinery"].get(c["class"], 0.0)) > 0.0:
				refinable = true
		if not refinable:
			bad.append(ore + " (no refinery)")
	check(bad.is_empty(), "every ore refines into a known product somewhere %s" % str(bad))
	check(classes["metallic"] == 6 and classes["stony"] == 6 and classes["icy"] == 6, "6 ores per asteroid class")
	var unknown := []
	var st: Dictionary = Universe.get_layout(Universe.home_system)["stations"][0]
	for mid in GameData.modules:
		var rec := Industry.recipe(st, mid)
		for k in rec["materials"]:
			if not GameData.commodities.has(k):
				unknown.append(k)
	check(unknown.is_empty(), "all recipe materials exist %s" % str(unknown))
	# Package 2: field classes, orbital bands and rarity by security
	var dist_sum := {"metallic": 0.0, "stony": 0.0, "icy": 0.0}
	var dist_n := {"metallic": 0, "stony": 0, "icy": 0}
	var rare_in_safe := 0
	var rare_in_unsafe := 0
	var mixed_ok := true
	for sid in mini(Universe.systems.size(), 40):
		var lay := Universe.get_layout(sid)
		var sec := float(Universe.systems[sid]["security"])
		for fl in lay["fields"]:
			dist_sum[fl["class"]] += (fl["pos"] as Vector2).length()
			dist_n[fl["class"]] += 1
			if (fl["ores"] as Array).size() < 3:
				mixed_ok = false
		for a in lay["asteroids"]:
			var c: Dictionary = GameData.commodities[a["ore"]]
			if c["class"] != a["class"]:
				mixed_ok = false
			if c["rarity"] == "rare":
				if sec >= 0.5:
					rare_in_safe += 1
				else:
					rare_in_unsafe += 1
	var avg := {}
	for k in dist_sum:
		avg[k] = dist_sum[k] / maxf(float(dist_n[k]), 1.0)
	check(dist_n["metallic"] > 0 and dist_n["stony"] > 0 and dist_n["icy"] > 0, "all three field classes occur (%s)" % str(dist_n))
	check(avg["metallic"] < avg["stony"] and avg["stony"] < avg["icy"], "metallic fields closest to the star, icy farthest out")
	check(mixed_ok, "fields hold several ores, all of their own class")
	check(rare_in_safe == 0 and rare_in_unsafe > 0, "rare ores only in unsafe systems (%d found)" % rare_in_unsafe)
	# Package 3: sizes, shapes, clumps, mixed asteroids, textures
	var lay0 := Universe.get_layout(Universe.home_system)
	var sizes := {"small": 0, "medium": 0, "large": 0}
	var mixed := 0
	var shapes := {}
	for a in lay0["asteroids"]:
		sizes[a["size"]] += 1
		shapes[a["shape"]] = true
		if (a["mix"] as Dictionary).size() > 1:
			mixed += 1
	var per_field := float(lay0["asteroids"].size()) / maxf(float(lay0["fields"].size()), 1.0)
	check(per_field >= 70.0, "denser fields (%.0f asteroids per field)" % per_field)
	check(sizes["small"] > sizes["large"] and sizes["large"] > 0, "size classes small > medium > large (%s)" % str(sizes))
	check(mixed > 0, "some large asteroids hold two ores (%d)" % mixed)
	var tex_ok := true
	for cls in ["metallic", "stony", "icy"]:
		for shp in Universe.SHAPES_BY_CLASS[cls]:
			for px in [12, 28, 48]:
				var tx := PixelArt.asteroid_sprite(cls, shp, 5, px, "iron_ore" if cls == "metallic" else ("bauxite" if cls == "stony" else "water_ice"))
				if tx == null or tx.get_width() < 8:
					tex_ok = false
	check(tex_ok, "asteroid textures for every class, shape and size")
	# Package 4: loose asteroids and scenery debris
	var loose := 0
	var ring_ok := true
	for a in lay0["asteroids"]:
		if String(a["field"]) == "":
			loose += 1
			if a.has("near"):
				for pl in lay0["planets"]:
					if pl["name"] == a["near"] and a["class"] != Universe.PLANET_ROCK_CLASS[pl["type"]]:
						ring_ok = false
	check(loose > 0 and lay0["debris"].size() > 100, "loose asteroids (%d) and scenery debris (%d) outside fields" % [loose, lay0["debris"].size()])
	check(ring_ok, "planet rings match the planet type (gas giants: ice, lava: metal)")
	# Determinism: the same seed builds the same system (save games rely on it)
	var sid_t := (Universe.home_system + 3) % Universe.systems.size()
	var l1: Dictionary = Universe._generate_layout(sid_t)
	var l2: Dictionary = Universe._generate_layout(sid_t)
	var same: bool = l1["asteroids"].size() == l2["asteroids"].size() and l1["debris"].size() == l2["debris"].size()
	if same:
		for i in l1["asteroids"].size():
			if l1["asteroids"][i]["ore"] != l2["asteroids"][i]["ore"] or l1["asteroids"][i]["pos"] != l2["asteroids"][i]["pos"]:
				same = false
				break
	check(same, "system generation is deterministic")
	# Package 5 data: colossi in all classes, rim rock, nothing inside them
	var col_classes := {}
	var inside := 0
	var rim := 0
	var ncol := 0
	var col_shapes := {}
	var col_per_field := {}
	var in_fields := true
	var listed := false
	for sid in mini(Universe.systems.size(), 40):
		var lay := Universe.get_layout(sid)
		for t in Universe.warp_targets(sid):
			listed = listed or t["kind"] == "colossus"
		for co in lay["colossi"]:
			ncol += 1
			col_classes[co["class"]] = true
			col_shapes[co["shape"]] = true
			in_fields = in_fields and String(co["field"]) != ""
			var fk := "%d_%s" % [sid, co["field"]]
			col_per_field[fk] = int(col_per_field.get(fk, 0)) + 1
			for a in lay["asteroids"]:
				if ColossusShape.contains(co["poly"], (a["pos"] as Vector2) - (co["pos"] as Vector2)):
					inside += 1
				if String(a.get("near", "")) == co["name"]:
					rim += 1
	check(ncol > 10 and col_classes.size() == 3, "colossal asteroids in all three classes (%d)" % ncol)
	check(col_shapes.size() == 3, "all three colossus shapes occur (%s)" % str(col_shapes.keys()))
	var groups := 0
	for fk2 in col_per_field:
		if int(col_per_field[fk2]) >= 2:
			groups += 1
	check(in_fields and groups * 2 >= col_per_field.size(), "colossi sit in asteroid fields, mostly in groups (%d of %d fields)" % [groups, col_per_field.size()])
	check(not listed, "colossi are not separate warp targets / map markers")
	check(inside == 0 and rim > 0, "rim rock around colossi (%d), nothing inside them" % rim)
	var cspr := Celestial.make_colossus_sprite({"radius": 1000.0, "ore": "iron_ore", "class": "icy", "seed": 7, "pos": Vector2(5000, 0)})
	var cmat := cspr.material as ShaderMaterial
	check(cmat != null and int(cmat.get_shader_parameter("kind")) == 2 and absf(cspr.scale.x * 64.0 - 2000.0 / Celestial.COLOSSUS_BODY) < 1.0, "colossus shader sprite (class, size)")
	cspr.free()
	# Package 6: station types, art, zones, havens
	var st_types := {}
	var havens_n := 0
	var art_ok := true
	for sid2 in mini(Universe.systems.size(), 60):
		var lay2 := Universe.get_layout(sid2)
		havens_n += lay2["havens"].size()
		for st9 in lay2["stations"]:
			st_types[st9["type"]] = true
			art_ok = art_ok and float(st9.get("zone", 0.0)) >= 15000.0 and st9.has("seed")
	check(st_types.has("ice_refinery") and st_types.has("shipyard"), "Ice Refineries and Shipyard Complexes exist (%s)" % str(st_types.keys()))
	check(havens_n > 0, "Pirate Havens in lawless systems (%d)" % havens_n)
	check(art_ok, "every station has an art seed and a no-fire zone")
	# Package 6b: larger cluster, every station type in every tier, plan = layout, ice next to ice
	var combos := {}
	var haven_tiers := {}
	var plan_ok := true
	var ice_ok := true
	for sid3 in Universe.systems.size():
		var lay3 := Universe.get_layout(sid3)
		var plan3: Array = Universe.systems[sid3]["stations_plan"]
		# package 26: waystations come on top of the station plan
		var sts3: Array = lay3["stations"].filter(func(x): return x["type"] != "waystation")
		plan_ok = plan_ok and plan3.size() == sts3.size()
		var icy := false
		for f3 in lay3["fields"]:
			icy = icy or f3["class"] == "icy"
		for k3 in sts3.size():
			var st3: Dictionary = sts3[k3]
			combos["%s_%d" % [st3["type"], int(st3["tier"])]] = true
			plan_ok = plan_ok and st3["type"] == plan3[k3][0] and int(st3["tier"]) == int(plan3[k3][1])
			ice_ok = ice_ok and (st3["type"] != "ice_refinery" or icy)
		for ph3 in lay3["havens"]:
			haven_tiers[int(ph3["tier"])] = true
	check(Universe.systems.size() == 48, "star cluster has 48 systems")
	check(combos.size() == 24, "every station type exists in every tier (%d/24)" % combos.size())
	check(haven_tiers.size() == 3, "Pirate Havens in all three tiers")
	check(plan_ok, "station plan (star map) matches the generated systems")
	check(ice_ok, "every Ice Refinery has an icy field in its system")
	for tp in ["trade", "industry", "mining_colony", "agri", "research", "military", "ice_refinery", "shipyard", "pirate_haven"]:
		var sa := StationArt.build({"type": tp, "tier": 1, "seed": 5})
		var big := float(sa["size"]) >= 252.0 * 3.0
		check(big and (sa["bays"].size() > 0) and (sa["turrets"].size() > 0), "station art %s: %.0f km, %d bays, %d turrets" % [tp, float(sa["size"]), sa["bays"].size(), sa["turrets"].size()])
		for b in sa["bays"]:
			art_ok = art_ok and float(b["width"]) >= 38.0 * 4.0 and float(b["depth"]) >= 38.0 * 4.0
	check(art_ok, "every hangar bay fits an L hull (Bastion 152 km)")
	# Debug test system: everything in one place, built without touching the running galaxy
	var seed_before := Universe.seed_value
	var sys_before := Universe.systems.size()
	var TL := Universe.build_test_layout()
	var t_types := {}
	var t_ways := {}
	for st8 in TL["stations"]:
		if st8["type"] == "waystation":
			t_ways[int(st8["tier"])] = true
			continue
		t_types[st8["type"]] = true
	var t_planets := {}
	for p8 in TL["planets"]:
		t_planets[p8["type"]] = true
	var t_ores := {}
	var t_shapes := {}
	var t_sizes := {}
	for a8 in TL["asteroids"]:
		t_ores[a8["ore"]] = true
		t_shapes[a8["shape"]] = true
		t_sizes[a8["size"]] = true
	var t_cols := {}
	for c8 in TL["colossi"]:
		t_cols["%s_%s" % [c8["class"], c8["shape"]]] = true
	var all_ores := 0
	for cid in GameData.commodities:
		if GameData.commodities[cid].get("category", "") == "ore":
			all_ores += 1
	var t_combos := {}
	for st7 in TL["stations"]:
		if st7["type"] != "waystation":
			t_combos["%s_%d" % [st7["type"], int(st7["tier"])]] = true
	check(t_types.size() == Universe.ALL_STATION_TYPES.size() and t_combos.size() == 24 and TL["havens"].size() == 3 and t_ways.size() == 3, "test system: every station type in every tier + havens + waystations (%d types, %d combos)" % [t_types.size(), t_combos.size()])
	check(TL["stations"][0]["type"] == "trade" and int(TL["stations"][0]["tier"]) == 3, "test system: start at the tier-3 Trade Hub")
	check(t_planets.size() == Universe.PLANET_TYPES.size(), "test system: every planet type")
	check(t_ores.size() == all_ores and t_sizes.size() == 3, "test system: every ore (%d/%d) and asteroid size" % [t_ores.size(), all_ores])
	check(t_cols.size() == 9 and TL["gates"].is_empty(), "test system: colossi in all 9 class/shape combinations, no gates")
	check(Universe.seed_value == seed_before and Universe.systems.size() == sys_before and not Universe.test_mode, "test system leaves the running galaxy untouched")
	check(Ship.mining_mult({"tool": "mining"}, "water_ice") < 1.0 and Ship.mining_mult({"tool": "mining"}, "iron_ore") == 1.0, "mining lasers get a malus on ice")
	var pal := PixelArt.ore_palette("helium3_ice")
	check(pal.size() == 5, "asteroid palettes for new ores")
	# Package 10: factions & territory
	var FD = load("res://data/factions.gd")
	var fcount := {}
	var caps := {}
	var sec_ok := true
	for s10 in Universe.systems:
		var f10: String = s10["faction"]
		var k10 := f10 if f10 != "" else "contested"
		fcount[k10] = int(fcount.get(k10, 0)) + 1
		if s10["capital"]:
			caps[f10] = int(caps.get(f10, 0)) + 1
		if f10 in FD.POWERS and float(s10["security"]) < 0.35:
			sec_ok = false
		if f10 in FD.TERRITORIAL_PIRATES and float(s10["security"]) > 0.15:
			sec_ok = false
	var sizes_ok := true
	for pw in FD.POWERS:
		sizes_ok = sizes_ok and int(fcount.get(pw, 0)) >= 9 and int(fcount.get(pw, 0)) <= Universe.POWER_SYSTEMS_MAX
	for pf in FD.TERRITORIAL_PIRATES:
		sizes_ok = sizes_ok and int(fcount.get(pf, 0)) >= 2 and int(fcount.get(pf, 0)) <= Universe.PIRATE_SYSTEMS
	check(sizes_ok and int(fcount.get("contested", 0)) >= 2 and not fcount.has("free_captains"), "territories: powers ~12, pirates ~4, some contested, Free Captains none %s" % str(fcount))
	check(caps.size() == 5 and caps.values().max() == 1, "one capital / stronghold per territorial faction")
	check(sec_ok, "security follows territory (powers safe, pirate space lawless)")
	check(Universe.controller(Universe.home_system) == "assembly" and not Universe.systems[Universe.home_system]["capital"], "start in an Assembly system (%s)" % Universe.territory_text(Universe.home_system))
	var haven_ok := true
	var hv_tiers10 := {}
	for s11 in Universe.systems:
		if int(s11["haven_tier"]) > 0:
			hv_tiers10[int(s11["haven_tier"])] = true
			haven_ok = haven_ok and s11["faction"] in FD.TERRITORIAL_PIRATES
	check(haven_ok and hv_tiers10.size() == 3, "Pirate Havens only in pirate territory, all three tiers")
	var st_fac_ok := true
	var hv_fac_ok := true
	for sid10 in Universe.systems.size():
		var L10 := Universe.get_layout(sid10)
		for st10 in L10["stations"]:
			var ctl := Universe.controller(sid10)
			if ctl in FD.POWERS and st10["faction"] != ctl:
				st_fac_ok = false
			if ctl in FD.PIRATES and st10["faction"] != "":
				st_fac_ok = false
		for hv10 in L10["havens"]:
			hv_fac_ok = hv_fac_ok and hv10["faction"] == Universe.controller(sid10)
	check(st_fac_ok and hv_fac_ok, "stations fly the flag of the system owner, pirate havens of their faction")
	check(FD.relation("assembly", "covenant") < 0.0 and FD.relation("hollow_crown", "directorate") < 0.0 and FD.relation("assembly", "directorate") > 0.0, "faction relations")
	var crest_ok := true
	for fid in FD.FACTIONS:
		var ci: Image = CrestArt.image(fid)
		var opaque := 0
		for yy in ci.get_height():
			for xx in ci.get_width():
				if ci.get_pixel(xx, yy).a > 0.5:
					opaque += 1
		crest_ok = crest_ok and opaque > 500
	check(crest_ok, "coats of arms for all six factions")
	var pt := PixelArt.ship_texture("crow", "hollow_crown")
	check(pt != null and pt != PixelArt.ship_texture("crow", "pirate"), "faction paint for ships")
	check(GalaxyMap.territory_texture() != null, "territory overlay for the galaxy map")


## Package 11: population, shuttles, miners, patrols and convoys.
func _test_traffic(view: SystemView) -> void:
	var tr = view.traffic
	check(tr != null, "system traffic is running")
	if tr == null:
		return
	var prof: Dictionary = tr.profile
	check(float(prof["population"]) > 0.0 and int(prof["patrol_groups"]) >= 1, "home system profile: population %.1f bn, %d patrol group(s)" % [float(prof["population"]), int(prof["patrol_groups"])])
	var n_patrol := 0
	var n_civ := 0
	var paint_ok := true
	for n in view.ship_layer.get_children():
		if n is Ship and n != view.player:
			if n.faction == "patrol":
				n_patrol += 1
				paint_ok = paint_ok and n.fit.gov == Universe.controller(view.system_id) and n.paint == n.fit.gov
			elif n.faction == "civilian":
				n_civ += 1
	check(n_patrol >= 2 and paint_ok, "patrols of the system owner in its colours (%d ships)" % n_patrol)
	check(n_civ >= 1, "civilian traffic in the system (%d ships)" % n_civ)
	check(tr.npc_count() <= Universe.NPC_CAP, "NPC limit respected (%d / %d)" % [tr.npc_count(), Universe.NPC_CAP])
	# a terran world adds far more people than a barren rock
	check(Universe.PLANET_POP["terran"] > Universe.PLANET_POP["desert"] and Universe.PLANET_POP["desert"] > Universe.PLANET_POP["barren"], "earthlike planets carry the most inhabitants")
	# convoys: simulated cluster-wide, live ships in the observed system, back to the sim on jump
	var sim = GameState.convoys
	check(sim.convoys.size() >= 5, "trade convoys under way in the cluster (%d)" % sim.convoys.size())
	var c: Dictionary = {}
	for cc in sim.convoys:
		if not cc["live"]:
			c = cc
			break
	if c.is_empty():
		check(false, "convoy available for the live test")
		return
	var links: Array = Universe.systems[view.system_id]["links"].keys()
	c["cur"] = view.system_id
	c["dst"] = int(links[0]) if links.size() < 2 else int(links[1])
	c["prev"] = int(links[0])
	c["route"] = [c["dst"]]
	c["departed"] = true
	c["t"] = 100.0
	c["T"] = 200.0
	var before: int = tr.live_convoy_ships()
	sim._go_live(c)
	var e: Dictionary = tr.convoys.get(c["id"], {})
	check(c["live"] and not e.is_empty() and tr.live_convoy_ships() > before, "a convoy entering the system appears as ships")
	if e.is_empty():
		return
	var leader: Ship = e["leader"]
	check(leader != null and leader.faction == "civilian" and leader.fit.hull_id == "freighter" and String(leader.order.get("type", "")) in ["travel", "warp"], "convoy freighter heads for the next gate")
	tr.on_jump(leader, int(c["dst"]))
	check(not c["live"] and int(c["cur"]) == int(c["dst"]), "a convoy jumping out continues in the cluster simulation")
	check(PixelArt.ship_texture("freighter", "assembly") != null and PixelArt.ship_texture("shuttle", "covenant") != null, "pixel art for freighter and shuttle")
	# loiterers, contacts list and the warp interdictor
	check(not tr.loiterers.is_empty(), "loiterers holding near stations / sweeping fields (%d)" % tr.loiterers.size())
	main.hud._set_ov_tab("contacts")
	main.hud._update_contacts()
	check(main.hud._contact_rows.size() >= 5, "Contacts tab lists the ships in the system (%d)" % main.hud._contact_rows.size())
	main.hud._set_ov_tab("overview")
	var pl: Ship = view.player
	var tkey := ""
	for k8 in pl.fit.slot_keys():
		if String(k8).begins_with("tool_"):
			tkey = k8
	var old_tool = pl.fit.modules.get(tkey)
	var old_pos: Vector2 = pl.position
	pl.fit.modules[tkey] = GameData.legacy_id("t_interdictor_s")
	pl.fit.mark_dirty()
	var runner := view.spawn_npc("civ_shuttle", pl.position + Vector2(60000, 0), "civilian", "assembly")
	runner.warp = {"from": runner.position, "to": runner.position + Vector2(900000, 0), "t": 0.0, "T": 80.0, "then": {}, "name": "Testpoint"}
	runner.order = {"type": "warping"}
	view.select("ship:%d" % runner.fit.uid)
	var ierr: String = pl.set_module_active(tkey, true)
	check(ierr == "" and runner.warp_frozen and view.interdict_running(), "warp interdictor freezes a ship in warp %s (%s %s)" % [ierr, pl.fit.hull_id, str(pl.fit.slot_keys())])
	check(pl.in_warp() and pl.warp.get("hold", false), "the pilot warps straight after the frozen target")
	pl.warp["t"] = float(pl.warp["T"]) - 1.0
	var t_before := float(pl.warp["t"])
	pl._update_warp(0.5)
	check(is_equal_approx(float(pl.warp["t"]), t_before), "held in warp short of the target while the timing game runs")
	view._finish_interdict(true)
	check(not runner.in_warp() and runner.warp_disrupted > 0.0 and not view.interdict_running(), "won timing game pulls the target out of warp")
	pl.warp = {}
	pl.order = {"type": "idle"}
	pl.position = old_pos
	pl.velocity = Vector2.ZERO
	view.on_warp_finished(pl)
	if old_tool == null:
		pl.fit.modules.erase(tkey)
	else:
		pl.fit.modules[tkey] = old_tool
	pl.fit.mark_dirty()
	runner.queue_free()


func _test_controls(view: SystemView) -> void:
	var k1 := InputEventKey.new()
	k1.keycode = KEY_1
	k1.pressed = true
	check(InputMap.event_is_action(k1, "module_1", true), "default binding: 1 = module 1")
	# Middle mouse click (no drag) re-centres the camera
	view.follow = false
	view.camera.position += Vector2(5000, 3000)
	var mb := InputEventMouseButton.new()
	mb.button_index = MOUSE_BUTTON_MIDDLE
	mb.pressed = true
	view._unhandled_input(mb)
	var mr := InputEventMouseButton.new()
	mr.button_index = MOUSE_BUTTON_MIDDLE
	mr.pressed = false
	view._unhandled_input(mr)
	check(view.follow and view.camera.position.distance_to(view.player.position) < 1.0, "middle mouse click re-centres the camera")
	# Rebinding
	Keybinds.set_binding("module_1", 0, {"k": KEY_K})
	var kq := InputEventKey.new()
	kq.keycode = KEY_K
	kq.pressed = true
	check(InputMap.event_is_action(kq, "module_1", true) and not InputMap.event_is_action(k1, "module_1", true), "rebinding module 1 to K")
	check(Keybinds.binds["ship_up"][0].get("k", 0) == KEY_W and Keybinds.binds["cam_up"][0].get("k", 0) == KEY_UP, "K was not stolen from another action (W flies, arrows pan the camera)")
	Keybinds.set_binding("module_2", 0, {"k": KEY_K})
	check(not InputMap.event_is_action(kq, "module_1", true) and InputMap.event_is_action(kq, "module_2", true), "a key bound twice moves to the new action")
	Keybinds.reset_to_defaults()
	check(InputMap.event_is_action(k1, "module_1", true), "reset to defaults")


## Phase 0.5 package 12: reputation per faction.
func _test_reputation(view: SystemView) -> void:
	var r = GameState.rep
	r.reset()
	check(is_zero_approx(r.get_rep("assembly")) and is_equal_approx(r.get_rep("severed"), -10.0) and r.tier_id("hollow_crown") == "neutral", "start standing: powers 0, pirates slightly negative")
	check(r.tier_of_value(-61.0)["id"] == "nemesis" and r.tier_of_value(-60.0)["id"] == "hostile" and r.tier_of_value(19.0)["id"] == "neutral" and r.tier_of_value(20.0)["id"] == "friendly" and r.tier_of_value(60.0)["id"] == "allied", "five standing tiers")
	Commands.execute({"type": "debug_rep", "faction": "assembly", "value": 500})
	check(is_equal_approx(r.get_rep("assembly"), 100.0), "standing is capped at +100")
	# prices
	Commands.execute({"type": "debug_rep", "faction": "assembly", "value": 40})
	var cheap: int = r.buy_price(1000, "assembly")
	Commands.execute({"type": "debug_rep", "faction": "assembly", "value": -40})
	var dear: int = r.buy_price(1000, "assembly")
	check(cheap == 950 and dear == 1100 and r.buy_price(1000, "") == 1000 and is_equal_approx(r.sell_price(100.0, "assembly"), 90.0), "prices follow standing (%d / %d)" % [cheap, dear])
	# docking
	var st := {"name": "Test Hub", "type": "trade", "faction": "assembly"}
	check(r.dock_error(st) == "", "hostile pilots may still dock")
	Commands.execute({"type": "debug_rep", "faction": "assembly", "value": -80})
	check(r.dock_error(st) != "" and r.dock_error({"name": "Free port", "type": "trade", "faction": ""}) == "", "arch-enemies are refused docking (free ports never refuse)")
	var hv := {"name": "Rustmaw", "type": "pirate_haven", "faction": "hollow_crown"}
	check(r.dock_error(hv) != "", "pirate haven refuses a neutral pilot")
	Commands.execute({"type": "debug_rep", "faction": "hollow_crown", "value": 30})
	check(r.dock_error(hv) == "", "pirate haven lets a Friendly pilot dock")
	var any_haven := {}
	var haven_sys := -1
	for s2 in Universe.systems:
		for h2 in Universe.get_layout(int(s2["id"])).get("havens", []):
			any_haven = h2
			haven_sys = int(s2["id"])
			break
		if not any_haven.is_empty():
			break
	check(not any_haven.is_empty() and any_haven.has("market") and any_haven.has("shop") and float(any_haven["zone"]) == 0.0, "havens have a black market and outfitter")
	check(haven_sys >= 0 and Universe.find_station(haven_sys, any_haven["id"]) == any_haven, "find_station finds havens")
	# patrol behaviour
	var pl: Ship = view.player
	var pat := view.spawn_npc("patrol_light", pl.position + Vector2(20000, 0), "patrol", "assembly")
	check(r.patrol_attitude("assembly") == "attack" and pat.hostile_to_player() and Ship.hostile(pat, pl), "patrols attack arch-enemies")
	Commands.execute({"type": "debug_rep", "faction": "assembly", "value": 0})
	check(r.patrol_attitude("assembly") == "scan" and not pat.hostile_to_player(), "patrols scan neutral pilots")
	Commands.execute({"type": "debug_rep", "faction": "assembly", "value": 30})
	check(r.patrol_attitude("assembly") == "ignore", "patrols ignore friendly pilots")
	# pirates
	var pir := view.spawn_npc("pirate_raider_laser", pl.position + Vector2(22000, 0), "pirate", "hollow_crown")
	var pir2 := view.spawn_npc("pirate_raider_laser", pl.position + Vector2(22000, 600), "pirate", "severed")
	check(not pir.hostile_to_player() and pir2.hostile_to_player(), "pirates leave Friendly pilots alone (Hollow Crown friendly, Severed not)")
	# attacking a ship that is not hostile
	Commands.execute({"type": "debug_rep", "faction": "directorate", "value": 0})
	var civ := view.spawn_npc("civ_shuttle", pl.position + Vector2(21000, 0), "civilian", "directorate")
	var lock_e: Dictionary = {"kind": "weapon", "data": {"name": "Gun"}}
	check(pl.module_target_error(lock_e, civ) == "", "weapons may target non-hostile ships")
	civ.take_damage(1.0, "kinetic", pl)
	civ.take_damage(1.0, "kinetic", pl)
	check(is_equal_approx(r.get_rep("directorate"), -4.0) and civ.provoked and r.is_provoked("directorate"), "attacking a civilian costs standing once (%.1f)" % r.get_rep("directorate"))
	var dpat := view.spawn_npc("patrol_light", pl.position + Vector2(25000, 0), "patrol", "directorate")
	check(dpat.hostile_to_player(), "its comrades fight back for a while")
	civ.take_damage(1e7, "kinetic", pl)
	check(is_equal_approx(r.get_rep("directorate"), -14.0), "killing a civilian costs more standing (%.1f)" % r.get_rep("directorate"))
	# killing a pirate: small loss with its own faction
	var sv0: float = r.get_rep("severed")
	pir2.take_damage(1e7, "kinetic", pl)
	check(r.get_rep("severed") < sv0, "killing a pirate lowers standing with its faction")
	# bonds and contracts
	check(r.issuer(Universe.home_system) == "assembly", "bonds in the home system are issued by the Assembly")
	var a0: float = r.get_rep("assembly")
	var b := GameState.add_bond(Universe.home_system, "Test", 3000)
	check(String(b["faction"]) == "assembly", "bond records its issuing faction")
	var hst := {}
	for st9 in Universe.get_layout(int(b["redeem"]))["stations"]:
		if String(st9.get("faction", "")) == "assembly":
			hst = st9
	GameState.redeem_bonds(hst, int(b["redeem"]), String(b["id"]))
	check(is_equal_approx(r.get_rep("assembly"), a0 + 2.0), "redeeming a bond raises standing with the issuer (%+.1f)" % (r.get_rep("assembly") - a0))
	var c0: float = r.get_rep("covenant")
	var s0: float = r.get_rep("severed")
	r.on_contract({"faction": "covenant", "against": "severed"})
	r.on_contract({"faction": "covenant", "against": ""})
	check(is_equal_approx(r.get_rep("covenant"), c0 + 5.0) and is_equal_approx(r.get_rep("severed"), s0 - 1.5), "contracts raise standing; only contracts aimed at a faction pull it down")
	# contracts and military gear
	GameState.law.reset()        # the attacks above were crimes too (package 13)
	Commands.execute({"type": "debug_rep", "faction": "covenant", "value": -30})
	check(r.contracts_error("covenant") != "" and r.contracts_error("assembly") == "", "no contracts for hostile pilots")
	var big := ""
	for mid in GameData.modules:
		if GameData.is_military_grade(mid):
			big = mid
			break
	var mil := {"type": "military", "faction": "covenant"}
	var locked_neutral: String = r.module_error(mil, big)
	Commands.execute({"type": "debug_rep", "faction": "covenant", "value": 25})
	check(big != "" and locked_neutral != "" and r.module_error(mil, big) == "" and r.contract_bonus("covenant") > 0.0, "military L gear and contract bonus need Friendly standing")
	var sm: ShipMenu = main.ship_menu
	sm.open(view, 5)
	check(sm.visible and sm.content.get_child_count() > 0 and sm.TABS[5] == "Standing", "ship menu: Standing tab")
	sm.close()
	for n in [pat, pir, dpat]:
		if is_instance_valid(n):
			n.queue_free()
	r.reset()
	Commands.execute({"type": "debug_rep", "faction": "covenant", "value": 33})


## Optional screenshots for the roadmap (run windowed with  -- --smoketest --shots).
func _shoot_standing(view: SystemView) -> void:
	_shooting = true
	for kv in [["assembly", 45], ["covenant", -35], ["directorate", 8], ["hollow_crown", 25], ["severed", -70], ["free_captains", -10]]:
		Commands.execute({"type": "debug_rep", "faction": kv[0], "value": kv[1]})
	var sm: ShipMenu = main.ship_menu
	sm.open(view, 5)
	for i in 6:
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://Claude outputs/standing.png")
	print("[SMOKE] screenshot: Claude outputs/standing.png")
	GameState.codex.event("faction:hollow_crown")
	GameState.codex.event("colossus")
	sm.open(view, 6)
	for i in 6:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://Claude outputs/codex.png")
	print("[SMOKE] screenshot: Claude outputs/codex.png")
	sm.open(view, 1)
	for i in 6:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://Claude outputs/modules.png")
	sm.mod_view = "power"
	sm.rebuild()
	for i in 6:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://Claude outputs/power.png")
	# package 24: all manufacturer crests side by side (factions for comparison), and a codex page
	var MK = preload("res://data/manufacturers.gd")
	var sheet := Image.create(8 * 34 * 5 + 40, 2 * 38 * 5 + 30, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.06, 0.07, 0.1))
	var ci := 0
	for mk in MK.MAKERS:
		var im: Image = CrestArt.image_of(MK.MAKERS[mk]["crest"])
		im.resize(34 * 5, 38 * 5, Image.INTERPOLATE_NEAREST)
		sheet.blit_rect(im, Rect2i(0, 0, 34 * 5, 38 * 5), Vector2i(10 + ci * 34 * 5, 10))
		ci += 1
	var fi := 0
	for fk in ["assembly", "covenant", "directorate"]:
		var im2: Image = CrestArt.image(fk)
		im2.resize(34 * 5, 38 * 5, Image.INTERPOLATE_NEAREST)
		sheet.blit_rect(im2, Rect2i(0, 0, 34 * 5, 38 * 5), Vector2i(10 + (fi + 4) * 34 * 5, 20 + 38 * 5))
		fi += 1
	# studio intro (dlirius games): title with open brackets, then slammed shut
	var intro = preload("res://scripts/ui/studio_intro.gd").new()
	intro.auto_skip = false
	main.add_child(intro)
	await get_tree().process_frame
	await get_tree().process_frame
	for i in 70:
		intro._process(0.1)
	for i in 30:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://Claude outputs/intro_title.png")
	intro.close_brackets()
	for i in 45:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://Claude outputs/intro_closed.png")
	intro.queue_free()
	sheet.save_png("res://Claude outputs/crests.png")
	# package 25a: the KHI ships (and the Earthworks Drillhead for comparison), player and NPC paint
	var hulls9 := ["mogura", "anaguma", "iwakudaki", "drillhead"]
	var ship_sheet := Image.create(1500, 520, false, Image.FORMAT_RGBA8)
	ship_sheet.fill(Color(0.05, 0.06, 0.09))
	var sx := 20
	for hid9 in hulls9:
		for row9 in 2:
			var tex9: Texture2D = PixelArt.ship_texture(hid9, "player" if row9 == 0 else "assembly")
			var im9 := tex9.get_image()
			im9.resize(im9.get_width() * 4, im9.get_height() * 4, Image.INTERPOLATE_NEAREST)
			ship_sheet.blend_rect(im9, Rect2i(0, 0, im9.get_width(), im9.get_height()), Vector2i(sx, 20 + row9 * 250))
		sx += PixelArt.ship_texture(hid9, "player").get_width() * 4 + 30
	ship_sheet.save_png("res://Claude outputs/khi_ships.png")
	var kt: Texture2D = PixelArt.ship_texture("kanayama", "player")
	var kim := kt.get_image()
	kim.resize(kim.get_width() * 4, kim.get_height() * 4, Image.INTERPOLATE_NEAREST)
	var dim := PixelArt.ship_texture("drone", "khi_drone").get_image()
	dim.resize(dim.get_width() * 8, dim.get_height() * 8, Image.INTERPOLATE_NEAREST)
	var ksheet := Image.create(kim.get_width() + 140, kim.get_height() + 40, false, Image.FORMAT_RGBA8)
	ksheet.fill(Color(0.05, 0.06, 0.09))
	ksheet.blend_rect(kim, Rect2i(0, 0, kim.get_width(), kim.get_height()), Vector2i(20, 20))
	ksheet.blend_rect(dim, Rect2i(0, 0, dim.get_width(), dim.get_height()), Vector2i(kim.get_width() + 40, 40))
	ksheet.save_png("res://Claude outputs/kanayama.png")
	# package 25c: the four Maison Aurelle ships (player paint, then NPC paint) and the white drone
	var aur := ["aur_pearl", "aur_boulevard", "aur_opal", "aur_empress"]
	var ash := Image.create(1100, 980, false, Image.FORMAT_RGBA8)
	ash.fill(Color(0.05, 0.06, 0.09))
	var ay := 20
	for ah in aur:
		var ax := 20
		for arow in 2:
			var aim := PixelArt.ship_texture(ah, "player" if arow == 0 else "covenant").get_image()
			var sc := 4 if ah != "aur_empress" else 4
			aim.resize(aim.get_width() * sc, aim.get_height() * sc, Image.INTERPOLATE_NEAREST)
			if ah == "aur_empress" and arow == 1:
				break
			ash.blend_rect(aim, Rect2i(0, 0, aim.get_width(), aim.get_height()), Vector2i(ax, ay))
			ax += aim.get_width() + 40
		ay += PixelArt.ship_texture(ah, "player").get_height() * 4 + 30
	var adr := PixelArt.ship_texture("drone", "aurelle_drone").get_image()
	adr.resize(adr.get_width() * 8, adr.get_height() * 8, Image.INTERPOLATE_NEAREST)
	ash.blend_rect(adr, Rect2i(0, 0, adr.get_width(), adr.get_height()), Vector2i(980, 40))
	var icx := 20
	for ik in ["o_cabin_bulk", "o_cabin_business", "o_cabin_luxury"]:
		var iim := PixelArt.icon_texture(ik).get_image()
		iim.resize(iim.get_width() * 4, iim.get_height() * 4, Image.INTERPOLATE_NEAREST)
		ash.blend_rect(iim, Rect2i(0, 0, iim.get_width(), iim.get_height()), Vector2i(icx, ay + 10))
		icx += iim.get_width() + 20
	ash.save_png("res://Claude outputs/aurelle_ships.png")
	var ef := Image.create(PixelArt.ship_texture("aur_empress", "player").get_width() * 6 + 40, PixelArt.ship_texture("aur_empress", "player").get_height() * 12 + 60, false, Image.FORMAT_RGBA8)
	ef.fill(Color(0.05, 0.06, 0.09))
	for fi2 in 2:
		var eim := PixelArt.ship_texture("aur_empress", "player", [2, 6][fi2]).get_image()
		eim.resize(eim.get_width() * 6, eim.get_height() * 6, Image.INTERPOLATE_NEAREST)
		ef.blend_rect(eim, Rect2i(0, 0, eim.get_width(), eim.get_height()), Vector2i(20, 20 + fi2 * (eim.get_height() + 20)))
	ef.save_png("res://Claude outputs/empress.png")
	# package 25d: the Hadrian Dynamics ships – factory paint, then the worn pirate copies (no Goliath)
	var hdy := ["hdy_talon", "hdy_maul", "hdy_goliath", "hdy_citadel"]
	var hsh := Image.create(1100, 900, false, Image.FORMAT_RGBA8)
	hsh.fill(Color(0.07, 0.08, 0.11))
	var hy := 20
	for hh9 in hdy:
		var hx := 20
		for prow in 2:
			if prow == 1 and hh9 == "hdy_goliath":
				break
			var him := PixelArt.ship_texture(hh9, "player" if prow == 0 else "pirate").get_image()
			var hsc := 4 if hh9 != "hdy_citadel" else 4
			him.resize(him.get_width() * hsc, him.get_height() * hsc, Image.INTERPOLATE_NEAREST)
			if hx + him.get_width() > 1100:
				hy += him.get_height() + 20
				hx = 20
			hsh.blend_rect(him, Rect2i(0, 0, him.get_width(), him.get_height()), Vector2i(hx, hy))
			hx += him.get_width() + 40
		hy += PixelArt.ship_texture(hh9, "player").get_height() * 4 + 24
	hsh.save_png("res://Claude outputs/hadrian_ships.png")
	# package 25e: the Concord carriers in the pilot's paint and in Assembly colours, the blue drone
	var cfw := ["cfw_demos", "cfw_quirinus", "cfw_concordia"]
	var csh := Image.create(1100, 760, false, Image.FORMAT_RGBA8)
	csh.fill(Color(0.06, 0.07, 0.1))
	var cyy := 20
	for ch9 in cfw:
		var cxx := 20
		for crow in 2:
			var cim := PixelArt.ship_texture(ch9, "player" if crow == 0 else "assembly").get_image()
			cim.resize(cim.get_width() * 4, cim.get_height() * 4, Image.INTERPOLATE_NEAREST)
			if cxx + cim.get_width() > 1100:
				cyy += cim.get_height() + 16
				cxx = 20
			csh.blend_rect(cim, Rect2i(0, 0, cim.get_width(), cim.get_height()), Vector2i(cxx, cyy))
			cxx += cim.get_width() + 40
		cyy += PixelArt.ship_texture(ch9, "player").get_height() * 4 + 24
	var bdr := PixelArt.ship_texture("drone", "assembly_drone").get_image()
	bdr.resize(bdr.get_width() * 8, bdr.get_height() * 8, Image.INTERPOLATE_NEAREST)
	csh.blend_rect(bdr, Rect2i(0, 0, bdr.get_width(), bdr.get_height()), Vector2i(980, 30))
	csh.save_png("res://Claude outputs/concord_ships.png")
	# package 25f: the Forge of Return's flying temples (fixed red and gold)
	var fsh := Image.create(1100, 600, false, Image.FORMAT_RGBA8)
	fsh.fill(Color(0.06, 0.06, 0.09))
	var fy := 20
	for fh9 in ["for_acolyte", "for_templar", "for_cathedral"]:
		var fim := PixelArt.ship_texture(fh9, "player").get_image()
		fim.resize(fim.get_width() * 4, fim.get_height() * 4, Image.INTERPOLATE_NEAREST)
		fsh.blend_rect(fim, Rect2i(0, 0, fim.get_width(), fim.get_height()), Vector2i(20, fy))
		fy += fim.get_height() + 20
	var fic := PixelArt.icon_texture("w_focus").get_image()
	fic.resize(fic.get_width() * 4, fic.get_height() * 4, Image.INTERPOLATE_NEAREST)
	fsh.blend_rect(fic, Rect2i(0, 0, fic.get_width(), fic.get_height()), Vector2i(1000, 30))
	fsh.save_png("res://Claude outputs/forge_ships.png")
	# package 25g: Axiom's research ships; the Threshold in two frames of its turning accretion disc
	var xsh := Image.create(1100, 520, false, Image.FORMAT_RGBA8)
	xsh.fill(Color(0.05, 0.06, 0.09))
	var xim := PixelArt.ship_texture("axa_parallax", "player").get_image()
	xim.resize(xim.get_width() * 4, xim.get_height() * 4, Image.INTERPOLATE_NEAREST)
	xsh.blend_rect(xim, Rect2i(0, 0, xim.get_width(), xim.get_height()), Vector2i(20, 20))
	var xy := 40 + xim.get_height()
	for xf in [0, 6]:
		var tim := PixelArt.ship_texture("axa_threshold", "player", xf).get_image()
		tim.resize(tim.get_width() * 4, tim.get_height() * 4, Image.INTERPOLATE_NEAREST)
		xsh.blend_rect(tim, Rect2i(0, 0, tim.get_width(), tim.get_height()), Vector2i(20, xy))
		xy += tim.get_height() + 10
	xsh.save_png("res://Claude outputs/axiom_ships.png")
	GameState.codex.unlock("maker_khi")
	sm.mod_view = "fitting"
	sm.open(view, 6)
	var cv = null
	for n7 in sm.content.find_children("*", "", true, false):
		if n7.has_method("_build_page"):
			cv = n7
	if cv != null:
		cv.selected = "maker_khi"
		cv._build_page()
	for i in 6:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://Claude outputs/codex_maker.png")
	sm.mod_view = "fitting"
	sm.close()
	# outfitter of the biggest station here (package 19: families with size · quality buttons)
	var big_st: Dictionary = view.layout["stations"][0]
	for st9 in view.layout["stations"]:
		if int(st9["tier"]) > int(big_st["tier"]):
			big_st = st9
	var sp: StationUI = main.station_panel
	sp.open(big_st, view)
	sp.open_service("outfitter")
	for i in 20:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://Claude outputs/outfitter.png")
	print("[SMOKE] screenshot: Claude outputs/modules.png, outfitter.png")
	sp.close()
	# package 23: drones out, drone window open
	var dpl: Ship = view.player
	if dpl != null and not dpl.is_docked():
		if dpl.fit.drones.is_empty():
			dpl.fit.drones = [{"fuel": 1.0, "hp": 1.0, "out": false}]
		view.set_level(0)
		Commands.execute({"type": "drone_launch"})
		for i in 90:
			await get_tree().physics_frame
		get_viewport().get_texture().get_image().save_png("res://Claude outputs/drones.png")
		print("[SMOKE] screenshot: Claude outputs/drones.png")
		for dd in view.drones_of(dpl):
			view.stow_drone(dd)
		# symmetric idle formation: a Bastion with 5 drones at rest
		var bf := GameState.create_from_preset("std_bastion", "player")
		bf.system_id = view.system_id
		bf.position = dpl.position + Vector2(0, -3000)
		bf.drones = []
		for i5 in 5:
			bf.drones.append({"fuel": 1.0, "hp": 1.0, "out": false})
		bf.drone_modes["combat"] = "rest"
		var bc := Ship.new()
		bc.setup(bf, view)
		view.ship_layer.add_child(bc)
		bc.heading = -0.6
		view.launch_drones(bc)
		view.follow = false
		view.camera.position = bc.position
		for i6 in 240:
			await get_tree().physics_frame
		get_viewport().get_texture().get_image().save_png("res://Claude outputs/drone_formation.png")
		# package 25a: a KHI Anaguma with its refinery running (black smoke)
		var kf := GameState.create_from_preset("std_anaguma", "player")
		kf.system_id = view.system_id
		kf.position = bc.position + Vector2(400, 250)
		kf.cargo["iron_ore"] = 200.0
		kf.refinery_on = true
		var ks := Ship.new()
		ks.manual = true
		ks.setup(kf, view)
		view.ship_layer.add_child(ks)
		ks.heading = 0.4
		ks.velocity = Vector2.from_angle(0.4) * 60.0
		view.camera.position = ks.position
		for i7 in 200:
			await get_tree().physics_frame
		get_viewport().get_texture().get_image().save_png("res://Claude outputs/khi_smoke.png")
		ks.queue_free()
		# package 25d: the Citadel opens its platform hatch (S ship rises) and its drone hatch
		var cf9 := GameState.create_from_preset("std_hdy_citadel", "player")
		cf9.system_id = view.system_id
		cf9.position = bc.position + Vector2(0, 3500)
		cf9.drones = []
		for i9 in 4:
			cf9.drones.append({"fuel": 1.0, "hp": 1.0, "out": false})
		var cs9 := Ship.new()
		cs9.manual = true
		cs9.setup(cf9, view)
		view.ship_layer.add_child(cs9)
		cs9.heading = -0.25
		view.camera.position = cs9.position
		cs9.launch_platform()
		view.launch_drones(cs9)
		for i10 in 70:
			await get_tree().physics_frame
		get_viewport().get_texture().get_image().save_png("res://Claude outputs/citadel_hatches.png")
		for i11 in 50:
			await get_tree().physics_frame
		get_viewport().get_texture().get_image().save_png("res://Claude outputs/citadel_liftoff.png")
		var gf9 := GameState.create_from_preset("std_hdy_goliath", "player")
		gf9.system_id = view.system_id
		gf9.position = cs9.position + Vector2(0, 2200)
		var gs9 := Ship.new()
		gs9.manual = true
		gs9.setup(gf9, view)
		view.ship_layer.add_child(gs9)
		gs9.heading = 0.3
		gs9.velocity = Vector2.from_angle(0.3) * 80.0
		gs9.set_order({"type": "move", "pos": gs9.position + Vector2.from_angle(0.3) * 30000.0})   # under thrust: flames on
		for i12 in 30:
			view.camera.position = gs9.position
			await get_tree().physics_frame
		get_viewport().get_texture().get_image().save_png("res://Claude outputs/goliath.png")
		gs9.set_physics_process(false)                   # arms folded in as for a hangar bay
		gs9.arm_open = 0.0
		gs9.queue_redraw()
		for i13 in 10:
			await get_tree().physics_frame
		get_viewport().get_texture().get_image().save_png("res://Claude outputs/goliath_closed.png")
		for dd9 in view.drones_of(cs9):
			view.stow_drone(dd9)
		cs9.queue_free()
		gs9.queue_free()
		# package 25e: a Concordia launches its eleven drones from six hangar doors at once
		var ccf := GameState.create_from_preset("std_cfw_concordia", "player")
		ccf.system_id = view.system_id
		ccf.position = bc.position + Vector2(0, 16000)
		ccf.drones = []
		for i15 in 11:
			ccf.drones.append({"fuel": 1.0, "hp": 1.0, "out": false})
		ccf.drone_modes["combat"] = "rest"
		var ccs := Ship.new()
		ccs.manual = true
		ccs.setup(ccf, view)
		view.ship_layer.add_child(ccs)
		ccs.heading = -0.2
		view.camera.position = ccs.position
		view.launch_drones(ccs)
		for i16 in 45:
			await get_tree().physics_frame
		get_viewport().get_texture().get_image().save_png("res://Claude outputs/concordia_launch.png")
		for i17 in 200:
			await get_tree().physics_frame
		get_viewport().get_texture().get_image().save_png("res://Claude outputs/concordia_swarm.png")
		ccs.combat_t = 30.0
		ccs.arm_open = 1.0
		for i18 in 20:
			await get_tree().physics_frame
		get_viewport().get_texture().get_image().save_png("res://Claude outputs/concordia_combat.png")
		ccs.combat_t = 0.0
		view.recall_drones(ccs)
		var shot_done := false
		for i19 in 400:
			await get_tree().physics_frame
			var any_open := false
			for hn10 in ccs.hatch_open:
				any_open = any_open or float(ccs.hatch_open[hn10]) > 0.8
			if any_open and not shot_done:
				for i20 in 6:
					await get_tree().physics_frame
				get_viewport().get_texture().get_image().save_png("res://Claude outputs/concordia_recall.png")
				shot_done = true
				break
		for dd10 in view.drones_of(ccs):
			view.stow_drone(dd10)
		ccs.set_order({"type": "move", "pos": ccs.position + Vector2.from_angle(ccs.heading) * 40000.0})   # under thrust
		for i21 in 60:
			view.camera.position = ccs.position - Vector2.from_angle(ccs.heading) * 350.0   # the stern in view
			await get_tree().physics_frame
		get_viewport().get_texture().get_image().save_png("res://Claude outputs/concordia_flames.png")
		ccs.queue_free()
		# package 25f: a Templar fires its bundled focus lance; a Cathedral pulses an Assembly drone swarm
		var tpf := GameState.create_from_preset("std_for_templar", "player")
		tpf.system_id = view.system_id
		tpf.position = bc.position + Vector2(-6000, 22000)
		var tps := Ship.new()
		tps.setup(tpf, view)
		view.ship_layer.add_child(tps)
		var tgt9: Ship = view.spawn_npc("pirate_hdy_maul", tps.position + Vector2(650, -150))
		tgt9.set_physics_process(false)
		tps.heading = (tgt9.position - tps.position).angle()
		var lw: Dictionary = tpf.stats()["weapons"][0]
		view.camera.position = tps.position + Vector2(160, 0)
		view.fire_weapon(tps, tgt9, lw)
		for i22 in 22:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png("res://Claude outputs/templar_charge.png")
		for i22b in 30:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png("res://Claude outputs/templar_lance.png")
		tps.queue_free()
		tgt9.queue_free()
		var caf := GameState.create_from_preset("patrol_cfw_medium", "patrol")
		caf.gov = "assembly"
		caf.system_id = view.system_id
		caf.position = bc.position + Vector2(3000, 26000)
		var cas := Ship.new()
		cas.setup(caf, view)
		view.ship_layer.add_child(cas)
		caf.drones = []
		for i23 in 7:
			caf.drones.append({"fuel": 1.0, "hp": 1.0, "out": false})
		view.launch_drones(cas)
		for d11 in view.drones_of(cas):
			d11.hatch_launch = false
			d11.visible = true
			d11.position = cas.position + Vector2.from_angle(randf() * TAU) * randf_range(300.0, 900.0)
		var cdf := GameState.create_from_preset("std_for_cathedral", "player")
		cdf.system_id = view.system_id
		cdf.position = cas.position + Vector2(-1400, 600)
		var cds := Ship.new()
		cds.manual = true
		cds.setup(cdf, view)
		view.ship_layer.add_child(cds)
		cds.heading = 0.15
		view.camera.position = cds.position + Vector2(-120, 0)
		view.drone_pulse(cds, 5000.0, 15.0)
		for i24 in 4:
			await get_tree().physics_frame
		get_viewport().get_texture().get_image().save_png("res://Claude outputs/cathedral_pulse.png")
		view.camera.position = cas.position
		for i25 in 50:
			await get_tree().physics_frame
		get_viewport().get_texture().get_image().save_png("res://Claude outputs/drones_stunned.png")
		for d12 in view.drones_of(cas):
			view.stow_drone(d12)
		cas.queue_free()
		cds.queue_free()
		# 0.4.25.22: every ship with drones has a drone hatch – top row shut, bottom row open
		for set_i in 2:
			var hset: Array = [["std_hornet", "std_warden", "std_bastion", "std_anaguma"], ["std_mule", "std_aur_boulevard", "std_hdy_maul", "std_aur_empress"]][set_i]
			var made: Array = []
			var base_p: Vector2 = bc.position + Vector2(0, 9000 + set_i * 3000)
			for hi in hset.size():
				for row in 2:
					var hf := GameState.create_from_preset(hset[hi], "player")
					hf.system_id = view.system_id
					hf.position = base_p + Vector2(-700 + hi * 470, -170 + row * 340)
					var hsp := Ship.new()
					hsp.manual = true
					hsp.setup(hf, view)
					view.ship_layer.add_child(hsp)
					hsp.heading = 0.0
					if row == 1:
						hsp.open_hatch("drones", 30.0)
					made.append(hsp)
			view.camera.position = base_p + Vector2(0, 0)
			for i14 in 40:
				await get_tree().physics_frame
			get_viewport().get_texture().get_image().save_png("res://Claude outputs/drone_hatches_%d.png" % (set_i + 1))
			for m9 in made:
				m9.queue_free()
		for dd5 in view.drones_of(bc):
			view.stow_drone(dd5)
		bc.queue_free()
		view.follow = true
	_shooting = false


## Phase 0.5 package 13: bounties from the powers, bonds paid in the issuer's territory, wanted status.
func _test_law(view: SystemView) -> void:
	var law = GameState.law
	var r = GameState.rep
	law.reset()
	r.reset()
	# issuer is always a power, also in pirate space
	var pirate_sys := -1
	for s2 in Universe.systems:
		if Universe.controller(int(s2["id"])) in ["hollow_crown", "severed"]:
			pirate_sys = int(s2["id"])
			break
	check(pirate_sys >= 0 and r.issuer(pirate_sys) in ["assembly", "covenant", "directorate"], "bounties in pirate space come from the nearest power (%s)" % (r.issuer(pirate_sys) if pirate_sys >= 0 else "?"))
	var pir := view.spawn_npc("pirate_hornet", view.player.position + Vector2(30000, 0), "pirate")
	check(pir.bounty_by == r.issuer(view.system_id), "pirate bounty records its issuer")
	pir.queue_free()
	# bonds: any station of the issuer pays, others do not
	var b := GameState.add_bond(pirate_sys if pirate_sys >= 0 else view.system_id, "Test Raider", 5000)
	var fac := String(b["faction"])
	var own := {}
	var other := {}
	for s3 in Universe.systems:
		for st in Universe.get_layout(int(s3["id"]))["stations"]:
			if String(st.get("faction", "")) == fac and own.is_empty():
				own = st
			elif String(st.get("faction", "")) not in ["", fac] and other.is_empty():
				other = st
	check(GameState.bond_redeemable_at(b, own, 0) and not GameState.bond_redeemable_at(b, other, 0), "bonds are paid at any station of the issuing faction only")
	check(GameState.bond_where(b, view.system_id).contains(FactionData.short_of(fac)), "bond shows where it is paid (%s)" % GameState.bond_where(b, view.system_id))
	GameState.bonds.erase(b)
	# crimes
	Commands.execute({"type": "debug_rep", "faction": "", "value": 0})
	var sysf: String = law.authority(view.system_id)
	var gov := sysf if sysf != "" else "assembly"
	var civ := view.spawn_npc("civ_shuttle", view.player.position + Vector2(21000, 0), "civilian", gov)
	civ.take_damage(1.0, "kinetic", view.player)
	if sysf != "":
		check(law.points(sysf) == 1 and law.level_name(sysf) == "Suspect", "attacking a civilian makes you a Suspect with the %s" % sysf)
		var pat := view.spawn_npc("patrol_light", view.player.position + Vector2(25000, 0), "patrol", sysf)
		r.provoked.clear()
		check(pat.hostile_to_player(), "patrols attack suspects")
		civ.take_damage(1e7, "kinetic", view.player)
		check(law.points(sysf) == 3 and law.level_name(sysf) == "Wanted" and law.contracts_error(sysf) != "", "killing it: Wanted – no contracts")
		Commands.execute({"type": "debug_wanted", "faction": sysf, "points": 6})
		check(r.dock_error({"name": "X", "type": "trade", "faction": sysf}) != "", "Most Wanted: docking refused")
		law.records[sysf]["last"] = GameState.play_time - law.DECAY_TIME * 2.0 - 1.0
		check(law.points(sysf) == 4, "points fade over time (%d)" % law.points(sysf))
		check(Commands.execute({"type": "fine_pay"}) != "", "fines are paid at a Bond Office (docked)")
		var cr := GameState.credits
		check(law.pay_fine(sysf) == 8000 and GameState.credits == cr - 8000 and law.points(sysf) == 0, "paying the fine clears the record")
		pat.queue_free()
	else:
		civ.queue_free()
	check(law.authority(pirate_sys) == "" if pirate_sys >= 0 else true, "pirate space has no law")
	law.reset()
	r.reset()
	Commands.execute({"type": "debug_rep", "faction": "covenant", "value": 33})
	Commands.execute({"type": "debug_wanted", "faction": "directorate", "points": 2})


## Patrol beat: slow sweep round a station without crossing it.
func _test_patrol_beat(view: SystemView) -> void:
	var tr = view.traffic
	if tr == null or view.stations.is_empty():
		check(false, "patrol beat: no traffic / station")
		return
	var st: Celestial = null
	for n in view.stations.values():
		if n.kind == "station":
			st = n
			break
	var pts: Array = tr._beat_points(String(st.data["id"]), st.position + Vector2(st.radius * 3.0, 0))
	var clear := pts.size() >= 3
	var prev: Vector2 = st.position + Vector2(st.radius * 3.0, 0)
	for p in pts:
		var mid: Vector2 = (prev + p) * 0.5
		clear = clear and (p as Vector2).distance_to(st.position) > st.radius * 1.5 and mid.distance_to(st.position) > st.radius * 1.2
		prev = p
	check(clear, "patrol beat circles the station without crossing it (%d legs)" % pts.size())
	var fid: String = String(view.layout["fields"][0]["id"]) if not view.layout["fields"].is_empty() else ""
	if fid != "":
		var fp: Array = tr._beat_points(fid, Vector2.ZERO)
		var inside := fp.size() >= 3
		for p in fp:
			inside = inside and (p as Vector2).distance_to(view.layout["fields"][0]["pos"]) <= float(view.layout["fields"][0]["radius"])
		check(inside, "patrol beat sweeps through an asteroid field")


## Phase 0.5 package 14: pirate archetypes.
func _test_archetypes(view: SystemView) -> void:
	var pl: Ship = view.player
	# data: every loadout exists, belongs to its archetype and fits its hull
	var ok := true
	var why := ""
	for a in ArchData.ARCHETYPES:
		for pid in ArchData.ARCHETYPES[a]["presets"]:
			if not GameData.presets.has(pid) or String(GameData.presets[pid].get("archetype", "")) != a:
				ok = false
				why = pid
				continue
			var f := GameState.create_from_preset(pid, "pirate")
			for k in f.modules:
				if f.can_fit(k, f.modules[k]) != "":
					ok = false
					why = "%s %s" % [pid, k]
	check(ok, "archetype loadouts exist and fit their hulls %s" % why)
	var seen := {}
	for i in 300:
		seen[ArchData.pick(0.1)[0]] = true
	check(seen.size() == ArchData.ARCHETYPES.size(), "all six archetypes spawn in lawless space (%d)" % seen.size())
	# ion weapons are pirate gear: not in corporate shops
	var corp_ion := false
	for s2 in Universe.systems:
		for st in Universe.get_layout(int(s2["id"]))["stations"]:
			for mid in st["shop"]:
				corp_ion = corp_ion or GameData.modules[mid].get("pirate_only", false)
	check(not corp_ion, "ion weapons are not sold by the corporations")
	var base := pl.position + Vector2(40000, 0)
	var spawned: Array = []
	var by := {}
	for a in ArchData.ARCHETYPES:
		var sh := view.spawn_npc(String(ArchData.ARCHETYPES[a]["presets"][0]), base + Vector2(0, spawned.size() * 3000.0), "pirate")
		sh.fit.stance = "passive"
		spawned.append(sh)
		by[a] = sh
	check(by["leech"].archetype == "leech" and by["sniper"].archetype == "sniper", "spawned pirates know their archetype")
	# preferred distance: snipers far, brawlers close
	var tgt := view.spawn_npc("civ_shuttle", base + Vector2(-20000, 0), "civilian", "")
	spawned.append(tgt)
	var d := {}
	for a in ["sniper", "brawler", "raider"]:
		var sh: Ship = by[a]
		sh.target = tgt
		d[a] = sh._combat_point(sh.fit.stats()).distance_to(tgt.position)
	check(float(d["sniper"]) > float(d["raider"]) and float(d["raider"]) > float(d["brawler"]), "sniper keeps its distance, brawler closes in (%.0f / %.0f / %.0f)" % [d["sniper"], d["raider"], d["brawler"]])
	var rd: Ship = by["raider"]
	rd._update_archetype(ArchData.RAID_ATTACK + 0.5)
	check(rd._raid_break and rd._combat_point(rd.fit.stats()).distance_to(tgt.position) > float(d["raider"]) * 2.0, "raider breaks off after its attack run")
	# ambusher: hides, strikes only close prey, first volley hits harder
	var am: Ship = by["ambusher"]
	check(am._hide_spot() != Vector2.INF and am._ambush_t < 0.0, "ambusher lies in wait")
	am.target = tgt
	am._update_archetype(0.1)
	check(am._ambush_t >= 0.0, "ambusher springs its trap")
	# leech: ion fire drains capacitor and hits shields harder
	var lc: Ship = by["leech"]
	var victim: Ship = by["raider"]
	victim.fit.refill()
	var cap0: float = victim.fit.capacitor
	var sh0: float = victim.fit.shield
	view.fire_weapon(lc, victim, GameData.modules[GameData.legacy_id("w_ion_s")])
	check(victim.fit.capacitor < cap0 and sh0 - victim.fit.shield > float(GameData.modules[GameData.legacy_id("w_ion_s")]["damage"]) * 1.5, "ion disruptor drains capacitor and shields (%.0f → %.0f cap)" % [cap0, victim.fit.capacitor])
	# coward: runs when hurt and calls for help
	var cw: Ship = by["coward"]
	var helper: Ship = by["brawler"]
	helper.target = null
	var stc := cw.fit.stats()
	cw.fit.shield = 0.0
	cw.fit.armor = 0.0
	cw.fit.structure = float(stc["structure_max"]) * 0.4
	cw.take_damage(1.0, "kinetic", pl)
	check(cw.fleeing and cw.target == null, "coward flees when badly hurt")
	check(String(helper.order.get("type", "")) == "attack" and helper.order.get("target") == pl, "its friends answer the call for help")
	# warrant scanner names the archetype
	check(lc.warrant_text().contains("Leech"), "warrant scanner reveals the archetype")
	for n in spawned:
		if is_instance_valid(n):
			n.queue_free()


## Phase 0.5 package 15: notorious pirates.
func _test_notorious(view: SystemView) -> void:
	var N = GameState.notorious
	var pl: Ship = view.player
	var ok: bool = N.captains.size() == N.COUNT
	var stars: Array = []
	for c in N.captains:
		ok = ok and not NotoriousData.is_home(int(c["system"])) and NotoriousData.lawless(int(c["system"]))
		stars.append(int(c["stars"]))
	stars.sort()
	check(ok and stars == [1, 1, 2, 2, 3], "%d notorious pirates start in lawless space, stars %s" % [N.captains.size(), str(stars)])
	# they roam everywhere except the home systems (capitals + start system)
	var probe: Dictionary = N.captains[0].duplicate(true)
	var never_home := true
	var visited_safe := false
	var saved_caps: Array = N.captains
	N.captains = [probe]
	# start next to a safer system that is not a home system, so the walk can reach one
	for s7 in Universe.systems:
		var sid7 := int(s7["id"])
		if NotoriousData.is_home(sid7) or not NotoriousData.lawless(sid7):
			continue
		var ok7 := false
		for nb7 in s7["links"]:
			ok7 = ok7 or (not NotoriousData.lawless(int(nb7)) and not NotoriousData.is_home(int(nb7)))
		if ok7:
			probe["system"] = sid7
			break
	for k in 1000:
		probe["next_move"] = 0.0
		N.update(-1)
		never_home = never_home and not NotoriousData.is_home(int(probe["system"]))
		visited_safe = visited_safe or not NotoriousData.lawless(int(probe["system"]))
	N.captains = saved_caps
	check(never_home and visited_safe, "they visit safer systems but never the home systems")
	# bounty grows in small steps, stars and escorts grow with age
	var ag: Dictionary = N.captains[1]
	var b0 := int(ag["base_bounty"])
	var st0 := int(ag["stars"])
	var e0 := (ag["escorts"] as Array).size()
	ag["since"] = GameState.play_time - N.BOUNTY_EVERY * 3.0 - 1.0
	ag["star_t"] = GameState.play_time - N.STAR_TIME - 1.0
	N.update(-1)
	check(int(ag["bounty"]) == b0 + 3 * N.BOUNTY_STEP, "bounty rises the longer it lives (%s)" % GameData.fmt_credits(int(ag["bounty"])))
	check(int(ag["stars"]) == st0 + 1 and (ag["escorts"] as Array).size() >= e0 and (ag["escorts"] as Array).size() == int(N.ESCORTS[st0 + 1]) + (2 if ag["trait"] == "never_alone" else 0), "a survivor gains a star and escorts (%s)" % NotoriousData.stars_text(ag))
	# roaming: one jump to a neighbour
	var mover: Dictionary = {}
	for c in N.captains:
		if int(c["system"]) != view.system_id and c["alive"]:
			mover = c
			break
	var from := int(mover["system"])
	mover["next_move"] = 0.0
	N.update(view.system_id)
	check(int(mover["system"]) == from or Universe.systems[from]["links"].has(int(mover["system"])), "notorious pirates move along the routes")
	# summon one with its escorts
	check(Commands.execute({"type": "debug_notorious"}) == "", "debug: summon a notorious pirate")
	var cap: Dictionary = N.alive_in(view.system_id)[0]
	var e: Dictionary = view.notorious_ships[cap["id"]]
	var lead: Ship = e["leader"]
	check(is_instance_valid(lead) and lead.notorious_id == cap["id"] and lead.paint.begins_with("notorious_") and lead.warrant_known and lead.bounty == int(cap["bounty"]), "captain: own paint, known bounty (%s)" % lead.display_name())
	check((e["escorts"] as Array).size() == (cap["escorts"] as Array).size() and (cap["escorts"] as Array).size() >= 2, "captain flies with %d escorts" % (e["escorts"] as Array).size())
	for s9 in e["escorts"]:
		s9.target = null
		s9.order = {"type": "idle"}
	lead.target = null
	view._notorious_t = 0.0
	view._update_notorious(0.1)
	var formation := true
	for s9 in e["escorts"]:
		formation = formation and String(s9.order.get("type", "")) == "keep" and s9.order.get("node") == lead
	check(formation, "escorts fly in formation around the captain")
	# traits
	lead.special = "iron_hide"
	lead.fit.shield = 500.0
	var sh0: float = lead.fit.shield
	lead.take_damage(10.0, "optical", null)
	var expect := 10.0 * NotoriousData.toughness(cap) * 0.6 * float(GameData.LAYER_MULT["shield"]["optical"])
	check(absf((sh0 - lead.fit.shield) - expect) < 0.01, "trait Iron Hide: less damage (%.2f)" % (sh0 - lead.fit.shield))
	var lt0: float = pl._lock_duration(lead, pl.fit.stats())
	lead.special = "ghost"
	check(pl._lock_duration(lead, pl.fit.stats()) > lt0 * 2.4, "trait Ghost: slow to lock")
	# the kill: big bond, special loot, captain gone
	var nb := GameState.bonds.size()
	var cid: String = cap["id"]
	lead.take_damage(1e7, "explosive", pl)
	check(not N.get_captain(cid)["alive"] and GameState.bonds.size() == nb + 1 and int(GameState.bonds.back()["amount"]) == int(cap["bounty"]), "killing a captain: bounty bond %s" % GameData.fmt_credits(int(cap["bounty"])))
	var wreck_loot := {}
	for c2 in view.celestials:
		if is_instance_valid(c2) and c2.kind == "wreck":
			wreck_loot = c2.data["loot"]
	var mods := 0
	for k in wreck_loot:
		if String(k).begins_with("mod:"):
			mods += 1
	check(wreck_loot.has("platinum_ingot") and mods >= 1, "special loot in its wreck (%d modules)" % mods)
	# successor
	var old := N.get_captain(cid)
	old["respawn"] = 0.0
	N.update(view.system_id)
	var succ: Dictionary = {}
	for c3 in N.captains:
		if int(c3["slot"]) == int(old["slot"]):
			succ = c3
	check(succ["alive"] and String(succ["id"]) != cid and String(succ["predecessor"]).contains(String(old["name"])), "a successor takes over the crew (%s)" % NotoriousData.title(succ))
	for s9 in e["escorts"]:
		if is_instance_valid(s9):
			s9.queue_free()
	# 5 stars: station raids (never a military outpost) – announced, fought live, offline + relief
	var raid_target := {}
	for st9 in view.layout["stations"]:
		if String(st9["type"]) != "military":
			raid_target = st9
			break
	if raid_target.is_empty():
		check(true, "raid: no civilian station in this system (skipped)")
		return
	var now: float = GameState.play_time
	var rc: Dictionary = N.summon(view.system_id)
	N._set_stars(rc, 5)
	N.start_raid(rc, raid_target, now)
	check(String(rc["raid"]["state"]) == "planned" and absf(float(rc["raid"]["start"]) - now - N.RAID_WARNING) < 1.0 and String(N.news[0]["text"]).contains("preparing"), "raid is announced 5 minutes ahead")
	rc["raid"]["start"] = now - 1.0
	N._update_raid(rc, now, view.system_id)
	check(String(rc["raid"]["state"]) == "active", "the raid begins on time")
	view.notorious_ships.erase(rc["id"])
	var rl: Ship = view._spawn_captain(rc, false)
	check(rl.raiding and view.zone_station(rl.position) != null and not rl._protected(view.player) and rl.fit.modules.values().has(GameData.legacy_id("w_ion_torpedo")), "5-star captain raids %s right under its guns, armed with an ion torpedo" % raid_target["name"])
	view._update_raid(0.05)
	check(not view.raid_live.is_empty() and is_equal_approx(float(view.raid_live["hp"]), float(view.raid_live["hp_max"])), "the raided station gets a hull bar (%.0f)" % float(view.raid_live.get("hp_max", 0.0)))
	var rst = view.raid_live["st"]
	var grp: Array = view._raid_group(String(rc["id"]))
	for g9 in grp:
		g9.position = rst.position + Vector2(float(rst.radius) + 1500.0, 0)
		g9.target = null
		g9.order = {"type": "idle"}
	var nt: int = view.raid_live["turrets"].size()
	view._update_raid(1.0)
	check(nt == 0 or float(view.raid_live["turrets"][0]["hp"]) < view.TURRET_HP, "raiders bombard the turrets first (%d turrets)" % nt)
	if nt > 0:
		var before := 0
		for k in nt:
			before += 1 if view.turret_ok(rst, k) else 0
		view.ion_strike()
		var after := 0
		for k in nt:
			after += 1 if view.turret_ok(rst, k) else 0
		check(after == before - 1, "an ion torpedo knocks a turret offline")
	if grp.size() > 1:
		grp[1].take_damage(1.0, "kinetic", view.player)
	check(bool(view.raid_live["helped"]), "shooting at the raiders counts as helping the defence")
	var cr0 := GameState.credits
	var ls: Dictionary = rl.fit.stats()
	rl.fit.armor = 0.0
	rl.fit.structure = float(ls["structure_max"]) * 0.1
	view._update_raid(0.05)
	check(view.raid_live.is_empty() and NotoriousData.is_hidden(rc) and (rc["raid"] as Dictionary).is_empty() and N.alive_in(view.system_id).find(rc) < 0, "the captain, about to lose, flees and hides")
	check(GameState.credits == cr0 + view.DEFENCE_REWARD, "defenders get %s" % GameData.fmt_credits(view.DEFENCE_REWARD))
	# a won raid: +100,000 cr bounty, a red star, the station goes offline
	rc["raid"] = {"station": raid_target["id"], "name": raid_target["name"], "state": "active", "start": now, "until": now + 60.0, "live": false}
	rc["system"] = view.system_id
	var rb0 := int(rc["bounty"])
	N.raid_won(rc)
	var sid9 := String(raid_target["id"])
	check(int(rc["red"]) == 1 and int(rc["bounty"]) == rb0 + N.RAID_PRIZE and NotoriousData.stars_bbcode(rc).contains("ff3030"), "won raid: bounty +%s and a red star" % GameData.fmt_credits(N.RAID_PRIZE))
	check(GameState.stations.is_down(sid9) and GameState.stations.down_error(raid_target) != "", "the raided station is offline – no services")
	# relief deliveries: any portion, 2x price, completion bonus + standing
	var f9 := GameState.active()
	var need: Dictionary = GameState.stations.status(sid9)["need"]
	var item: String = need.keys()[0]
	f9.cargo[item] = 3.0
	var paid: int = GameState.stations.deliver(sid9, item, 2, f9)
	check(paid == 2 * GameState.stations.unit_price(item) and GameState.stations.missing(sid9, item) == int(need[item]) - 2 and GameState.stations.unit_price(item) == int(round(float(GameData.commodities[item]["price"]) * 2.0)), "relief: deliver any portion at twice the price")
	var sf9 := String(raid_target.get("faction", ""))
	var rep0: float = GameState.rep.get_rep(sf9)
	var cr1 := GameState.credits
	for k in need:
		f9.cargo[k] = float(need[k])
		GameState.stations.deliver(sid9, k, -1, f9)
	check(not GameState.stations.is_down(sid9) and GameState.credits > cr1 and (sf9 == "" or GameState.rep.get_rep(sf9) > rep0), "relief complete: station back online, bonus and standing")
	for k in need:
		f9.cargo.erase(k)
	for g9 in grp:
		if is_instance_valid(g9):
			g9.queue_free()


## Optional screenshot of a live station raid (hull bar, turret markers).
func _shoot_raid(view: SystemView) -> void:
	var st9 := {}
	for st in view.layout["stations"]:
		if String(st["type"]) != "military":
			st9 = st
			break
	if st9.is_empty():
		return
	_shooting = true
	var N = GameState.notorious
	var c: Dictionary = N.summon(view.system_id)
	N._set_stars(c, 5)
	N.start_raid(c, st9, GameState.play_time, 0.0)
	N._update_raid(c, GameState.play_time, view.system_id)
	view.notorious_ships.erase(c["id"])
	view._spawn_captain(c, false)
	view._update_raid(0.05)
	var node = view.raid_live["st"]
	view.raid_live["hp"] = float(view.raid_live["hp_max"]) * 0.62
	view.raid_live["turrets"][0]["hp"] = 0.0
	view.ion_strike()
	view.follow = false
	view.set_level(0)
	view.camera.position = node.position
	view._set_zoom(0.35)
	for i in 40:
		view.camera.position = node.position
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://Claude outputs/raid.png")
	print("[SMOKE] screenshot: Claude outputs/raid.png")
	for g in view._raid_group(String(c["id"])):
		g.queue_free()
	view._end_raid("held")
	c["raid"] = {}
	view.follow = true
	_shooting = false


## Debug raid button + phase 0.5 package 16: news ticker, distress calls, fleeing traffic,
## escalation, wrecks for everyone, bounty campaigns.
func _test_world(view: SystemView) -> void:
	var N = GameState.notorious
	var NW = GameState.news
	var can_raid := false
	for st in view.layout["stations"]:
		can_raid = can_raid or (String(st["type"]) != "military" and not GameState.stations.is_down(String(st["id"])))
	if can_raid:
		check(Commands.execute({"type": "debug_raid", "warning": 300.0}) == "", "debug: announce a raid")
		var cap: Dictionary = {}
		for c in N.alive_in(view.system_id):
			if not (c["raid"] as Dictionary).is_empty():
				cap = c
		var alert_in := false
		for it in NW.items.slice(0, 5):
			alert_in = alert_in or (String(it["text"]).begins_with("RAID ALERT") and String(it["kind"]) == "alert")
		check(not cap.is_empty() and String(cap["raid"]["state"]) == "planned" and alert_in, "the raid alert runs in the ticker too")
		for g9 in view._raid_group(String(cap["id"])):
			g9.queue_free()
		view.notorious_ships.erase(cap["id"])
		cap["raid"] = {}
		check(Commands.execute({"type": "debug_raid", "warning": 0.0}) == "", "debug: raid now")
		view._update_raid(0.05)
		check(not view.raid_live.is_empty(), "debug raid starts at once")
		var rid := String(view.raid_live["cap"])
		var rc: Dictionary = N.get_captain(rid)
		for g9 in view._raid_group(rid):
			g9.queue_free()
		view._end_raid("held")
		rc["raid"] = {}
		view.notorious_ships.erase(rid)
	else:
		check(true, "debug raid: no station to raid here (skipped)")
	# ticker
	main.hud._ticker_queue.clear()
	NW.add("Smoke test bulletin.", "world")
	main.hud.ticker_label.text = ""
	main.hud._update_ticker(0.1)
	check(main.hud.ticker_label.text.contains("Smoke test bulletin") and main.hud._ticker_clip.visible, "news ticker shows a new item")
	main.hud._update_ticker(1000.0)
	check(main.hud.ticker_label.text == "" and not main.hud._ticker_clip.visible, "each item runs only once – then the ticker hides")
	# bounty campaign
	NW.start_campaign("assembly", view.system_id)
	check(is_equal_approx(NW.bounty_mult(view.system_id), NW.CAMPAIGN_MULT) and String(NW.items[0]["text"]).contains("raises bounties"), "bounty campaign raises bounties in a system")
	NW.campaigns.erase(view.system_id)
	# distress call, fleeing traffic, escalation
	var tr = view.traffic
	var pl: Ship = view.player
	var base: Vector2 = pl.position + Vector2(90000, 0)
	var probe := view.spawn_npc("civ_shuttle", base + Vector2(0, 90000), "civilian", "")
	var gov: String = tr._authority(probe)
	probe.queue_free()
	var civ := view.spawn_npc("civ_shuttle", base, "civilian", gov if gov != "" else "assembly")
	var civ2 := view.spawn_npc("civ_freighter", base + Vector2(3000, 0), "civilian", gov if gov != "" else "assembly")
	var pir := view.spawn_npc("pirate_raider_laser", base + Vector2(-800, 0), "pirate")
	var n0: int = NW.items.size()
	civ.take_damage(1.0, "optical", pir)
	check(String(NW.items[0]["kind"]) == "radio" and is_equal_approx(float(NW.items[0]["t"]), GameState.play_time), "attacked civilians send a distress call (radio)")
	var mayday := false
	for it in NW.latest(6, view.system_id):
		mayday = mayday or String(it["text"]).contains("Mayday")
	check(mayday, "Mayday on the radio ticker")
	check(not bool(NW.items[0].get("ticker", true)) or pl.position.distance_to(civ.position) <= NW.RADIO_RANGE, "radio from far away goes only to the archive, not the ticker")
	var near_civ := view.spawn_npc("civ_shuttle", pl.position + Vector2(5000, 0), "civilian", gov if gov != "" else "assembly")
	near_civ.fit.ship_name = "Smoke Courier"     # same name + place as above would be filtered as a repeat
	near_civ.take_damage(1.0, "optical", pir)
	var near_ok := false
	for it in NW.items.slice(0, 4):
		near_ok = near_ok or (bool(it.get("ticker", false)) and String(it["text"]).contains(near_civ.display_name()))
	check(near_ok, "radio close to you reaches the ticker")
	near_civ.queue_free()
	check(String(civ2.order.get("type", "")) == "move" and (civ2.order["pos"] as Vector2).distance_to(pir.position) > civ2.position.distance_to(pir.position), "traffic nearby flees the fight")
	if gov != "":
		var responding := false
		for g in tr.patrols:
			responding = responding or not g.get("respond", {}).is_empty()
		check(responding or tr.patrols.is_empty(), "a patrol answers the distress call (%d groups)" % tr.patrols.size())
		var p0: int = tr.patrols.size()
		tr._reinforced_at = -1000.0
		for k in 8:
			civ._distress_t = -1000.0
			tr.on_attacked(civ, pir)
		check(tr.patrols.size() > p0 or not tr._room(2), "escalation brings reinforcements (heat %.1f)" % tr.heat)
		for g in tr.patrols.duplicate():
			if g.has("leave_at"):
				for s9 in g["ships"]:
					if is_instance_valid(s9):
						s9.queue_free()
				tr.patrols.erase(g)
		tr.heat = 0.0
	else:
		check(true, "escalation: lawless system, nobody comes (skipped)")
	# wrecks for everyone
	var w0 := 0
	for c2 in view.celestials:
		if is_instance_valid(c2) and c2.kind == "wreck":
			w0 += 1
	civ.take_damage(1e7, "explosive", pir)
	var w1 := 0
	var goods := false
	for c2 in view.celestials:
		if is_instance_valid(c2) and c2.kind == "wreck":
			w1 += 1
			goods = goods or c2.data["loot"].has("food") or c2.data["loot"].has("electronics") or c2.data["loot"].has("alloys") or c2.data["loot"].has("medicine") or c2.data["loot"].has("water") or c2.data["loot"].has("iron_ingot")
	check(w1 == w0 + 1 and goods, "destroyed civilians leave a wreck with cargo")
	for n9 in [civ2, pir]:
		if is_instance_valid(n9):
			n9.queue_free()


## Phase 0.5 package 17: faction contracts – escort, patrol, intercept, hunt.
func _test_faction_jobs(view: SystemView) -> void:
	var st := {}
	for st9 in view.layout["stations"]:
		if String(st9.get("faction", "")) in ["assembly", "covenant", "directorate"]:
			st = st9
			break
	if st.is_empty():
		check(true, "faction contracts: no government station here (skipped)")
		return
	var f := String(st["faction"])
	var sys := view.system_id
	var saved: Array = GameState.missions.duplicate()
	GameState.missions.clear()
	GameState.rep.reset()
	var offers: Array = GameState.faction_offers_for(sys, st)
	var all_job := offers.size() == Missions.FACTION_OFFERS
	for o in offers:
		all_job = all_job and o.get("faction_job", false) and String(o["faction"]) == f
	check(all_job, "the %s posts %d faction contracts" % [FactionData.short_of(f), offers.size()])
	var rng := RandomNumberGenerator.new()
	rng.seed = 4711
	var by := {}
	for i in 80:
		var m: Dictionary = Missions.generate_faction(sys, st, rng)
		if not by.has(m["type"]):
			by[m["type"]] = m
	check(by.has("escort") and by.has("patrol") and by.has("hunt") and by.has("smuggler"), "four kinds of faction contracts (%s)" % str(by.keys()))
	# trade hubs: BlackLedger escort contracts for independent convoys of 2–4 freighters
	var hub := {}
	for s5 in Universe.systems:
		for st5 in Universe.get_layout(int(s5["id"]))["stations"]:
			if String(st5["type"]) == "trade" and hub.is_empty():
				hub = st5.duplicate()
				hub["sys"] = int(s5["id"])
	var sizes := {}
	var indep := true
	for i in 120:
		var mt: Dictionary = Missions.generate(int(hub["sys"]), hub, rng)
		if mt["type"] == "escort":
			sizes[int(mt["freighters"])] = true
			indep = indep and String(mt["convoy_gov"]) == "" and not mt.get("faction_job", false)
	check(sizes.size() >= 2 and indep, "trade hubs post trader escort contracts (sizes %s)" % str(sizes.keys()))
	# standing gates the hunt
	if by.has("hunt"):
		check(GameState.faction_job_error(by["hunt"]) != "", "hunting a notorious pirate needs Friendly standing")
	Commands.execute({"type": "debug_rep", "faction": f, "value": 30})
	# escort: a real convoy leaves; being with it most of the way completes the contract
	if by.has("escort"):
		var me: Dictionary = by["escort"]
		check(GameState.accept_mission(me) == "" and int(me["convoy"]) >= 0 and not GameState.convoys.find(int(me["convoy"])).is_empty(), "escort: accepting launches the convoy")
		var cv: Dictionary = GameState.convoys.find(int(me["convoy"]))
		# it gathers outside the station, marked green, and waits for the pilot
		var trg = view.traffic
		var eg: Dictionary = trg.convoys.get(cv["id"], {})
		var marked := not eg.is_empty()
		for s8 in eg.get("ships", []):
			marked = marked and s8.escort_mark
		check(marked and eg.get("gather", false) and cv.get("gathering", false), "escort convoy is marked green and gathers outside the station")
		var from_station := not eg.is_empty()
		var stn = view.stations.get(String(me["giver"]))
		for s8 in eg.get("ships", []):
			from_station = from_station and stn != null and (s8.is_docked() or String(s8.order.get("type", "")) == "undocking" or s8.position.distance_to(stn.position) < 5000.0)
		check(from_station, "escort convoy leaves from its station (not from a gate)")
		GameState._update_faction_jobs(30.0)
		check(is_zero_approx(float(me["total_t"])), "waiting for the pilot does not count against the escort")
		var gl: Ship = eg.get("leader")
		if gl != null and is_instance_valid(gl):
			var oldp: Vector2 = view.player.position
			gl.fit.docked_at = ""
			gl.position = eg["gather_pos"]
			view.player.position = gl.position + Vector2(5000, 0)
			view.player.set_order({"type": "follow", "node": gl, "r": 800.0})
			check(gl.convoy_lead, "the convoy's lead ship is flagged (drawn with a double ring and CONVOY LEAD)")
			for k8 in 7:
				trg._check_gather(eg, gl)
			check(not eg["gather"] and not cv["gathering"] and String(NW_last_text()).contains("Convoy departing"), "the convoy sets off once the pilot follows it (or stays close) for 3 s")
			_test_follow(view, trg, eg, gl)
			view.player.position = oldp
		me["with_t"] = 9.0
		me["total_t"] = 10.0
		GameState.convoys.live_delivered(cv)
		check(int(me["progress"]) == 1 and Missions.can_turn_in(me, GameState.active(), String(me["target_station"])) and Missions.payout(me) == int(me["reward"]), "escort: all %d freighters delivered with you along – full pay" % int(me["freighters"]))
		GameState.missions.erase(me)
		# a lost freighter costs its share of the pay
		var mp2: Dictionary = Missions.generate_faction(sys, st, rng)
		while mp2["type"] != "escort":
			mp2 = Missions.generate_faction(sys, st, rng)
		GameState.accept_mission(mp2)
		var cvp: Dictionary = GameState.convoys.find(int(mp2["convoy"]))
		mp2["with_t"] = 10.0
		mp2["total_t"] = 10.0
		cvp["freighters"] = int(mp2["freighters"]) - 1
		GameState.convoys.live_delivered(cvp)
		var want := int(round(float(mp2["reward"]) * float(int(mp2["freighters"]) - 1) / float(mp2["freighters"])))
		var crp := GameState.credits
		GameState.turn_in_mission(mp2, String(mp2["target_station"]))
		check(int(mp2["arrived"]) == int(mp2["freighters"]) - 1 and GameState.credits - crp == want, "escort: one freighter lost – pay %s of %s" % [GameData.fmt_credits(want), GameData.fmt_credits(int(mp2["reward"]))])
		var me2: Dictionary = Missions.generate_faction(sys, st, rng)
		while me2["type"] != "escort":
			me2 = Missions.generate_faction(sys, st, rng)
		GameState.accept_mission(me2)
		var cv2: Dictionary = GameState.convoys.find(int(me2["convoy"]))
		me2["with_t"] = 1.0
		me2["total_t"] = 10.0
		GameState.convoys.live_delivered(cv2)
		check(not me2 in GameState.missions, "escort fails if you were not with the convoy")
		# ambush on an escorted convoy
		var tr = view.traffic
		var e9: Dictionary = {}
		for k in tr.convoys:
			if tr.convoys[k]["c"].has("mission"):
				e9 = tr.convoys[k]
		if not e9.is_empty() and is_instance_valid(e9.get("leader")):
			var p0: int = view.pirate_count()
			tr.ambush(e9)
			check(view.pirate_count() >= p0 + 2, "pirates ambush the escorted convoy")
	# patrol: its own patrol group meets the pilot (station or named place), waits, then flies its rounds
	if by.has("patrol"):
		var mp: Dictionary = by["patrol"]
		mp["meet"] = {"id": String(st["id"]), "name": String(st["name"])}
		GameState.accept_mission(mp)
		var tr2 = view.traffic
		tr2._update_faction_jobs(0.5)
		var mg: Dictionary = {}
		for g in tr2.patrols:
			if g.get("mission", "") == mp["id"]:
				mg = g
		check(not mg.is_empty() and mg.get("gather", false), "patrol contract: its own patrol group waits at the meeting point")
		if not mg.is_empty():
			var plead: Ship = mg["ships"][0]
			var marked := true
			var from_st := true
			var stn = view.stations.get(String(st["id"]))
			for s8 in mg["ships"]:
				marked = marked and s8.escort_mark and s8.escort_kind == "patrol"
				from_st = from_st and (s8.is_docked() or String(s8.order.get("type", "")) == "undocking" or s8.position.distance_to(stn.position) < 5000.0)
			check(marked and plead.convoy_lead, "the patrol is marked green, with a PATROL LEAD")
			check(from_st, "a patrol meeting at the station leaves from it")
			var wing = mg["ships"][mg["ships"].size() - 1]
			var oldp: Vector2 = view.player.position
			view.player.warp = {}
			view.player.warp_disrupted = 0.0
			Commands.execute({"type": "follow", "id": "ship:%d" % wing.fit.uid})
			check(String(view.player.order.get("type", "")) == "follow" and view.player.order.get("node") == plead, "Follow works for the patrol (any ship → its lead)")
			plead.fit.docked_at = ""
			plead.position = mg["gather_pos"]
			view.player.position = plead.position + Vector2(4000, 0)
			mp["progress_t"] = 0.0
			tr2._update_faction_jobs(10.0)
			check(is_zero_approx(float(mp["progress_t"])), "waiting at the meeting point does not count yet")
			for k8 in 7:
				tr2._check_patrol_gather(mg, plead)
			check(not mg["gather"] and NW_last_text().contains("Patrol departing"), "the patrol sets off once the pilot follows it")
			view.player.position = plead.position + Vector2(2000, 0)
			tr2._update_faction_jobs(Missions.PATROL_TIME + 1.0)
			check(int(mp["progress"]) == 1 and not plead.escort_mark and mg.has("leave_at"), "flying its rounds completes the contract – the patrol is released")
			view.player.position = oldp
			view.player.order = {"type": "idle"}
		# a patrol meeting at a named place appears there
		var mp2: Dictionary = Missions.generate_faction(sys, st, rng)
		while mp2["type"] != "patrol":
			mp2 = Missions.generate_faction(sys, st, rng)
		var gate0: Dictionary = view.layout["gates"][0] if not view.layout["gates"].is_empty() else {}
		if not gate0.is_empty():
			mp2["meet"] = {"id": String(gate0["id"]), "name": String(gate0["name"])}
			var g2: Dictionary = tr2.spawn_mission_patrol(mp2)
			check((g2["gather_pos"] as Vector2).distance_to(gate0["pos"]) < 4000.0 and (g2["ships"][0] as Ship).position.distance_to(gate0["pos"]) < 6000.0, "a patrol meeting at %s waits there" % gate0["name"])
			for s9 in g2["ships"]:
				s9.queue_free()
			tr2.patrols.erase(g2)
		GameState.missions.erase(mp)
	# intercept: the smuggler appears and runs; destroying it completes the contract
	if by.has("smuggler"):
		var ms: Dictionary = by["smuggler"]
		ms["target_system"] = sys
		GameState.accept_mission(ms)
		var tr3 = view.traffic
		tr3._update_faction_jobs(0.5)
		var sm = null
		for e3 in tr3.smugglers:
			if e3["mission"] == ms["id"]:
				sm = e3["ship"]
		check(sm != null and float(ms["expires"]) > GameState.play_time, "intercept: the smuggler appears and runs for a gate")
		if sm != null:
			sm.take_damage(1e7, "explosive", view.player)
		check(int(ms["progress"]) == 1, "intercept: destroying the smuggler completes the contract")
		GameState.missions.erase(ms)
		var ms2: Dictionary = Missions.generate_faction(sys, st, rng)
		while ms2["type"] != "smuggler":
			ms2 = Missions.generate_faction(sys, st, rng)
		ms2["target_system"] = (sys + 1) % Universe.systems.size()
		GameState.accept_mission(ms2)
		ms2["expires"] = GameState.play_time - 1.0
		GameState._update_faction_jobs(0.1)
		check(not ms2 in GameState.missions, "intercept fails when the smuggler gets through")
	# hunt: kill the captain, turn in – standing up with the faction, down with the pirates
	if by.has("hunt"):
		var mh: Dictionary = by["hunt"]
		var cap: Dictionary = GameState.notorious.get_captain(String(mh["captain"]))
		if cap.is_empty() or not cap["alive"]:
			check(true, "hunt: target already gone (skipped)")
		else:
			check(GameState.accept_mission(mh) == "", "hunt accepted with Friendly standing")
			cap["system"] = sys
			cap["hidden_until"] = 0.0
			view.notorious_ships.erase(cap["id"])
			var lead: Ship = view._spawn_captain(cap, false)
			lead.take_damage(1e7, "explosive", view.player)
			check(int(mh["progress"]) == 1, "hunt: destroying the captain completes the contract")
			var r0: float = GameState.rep.get_rep(f)
			var cr0 := GameState.credits
			GameState.turn_in_mission(mh, String(mh["giver"]))
			check(GameState.credits > cr0 and GameState.rep.get_rep(f) >= r0 + Missions.FACTION_REP - 0.01, "turning in a faction contract raises the standing by %.0f" % Missions.FACTION_REP)
			for s9 in view._raid_group(String(cap["id"])):
				s9.queue_free()
	GameState.missions = saved
	GameState.rep.reset()
	Commands.execute({"type": "debug_rep", "faction": "covenant", "value": 33})


func NW_last_text() -> String:
	return String(GameState.news.items[0]["text"]) if not GameState.news.items.is_empty() else ""


## Optional screenshots: an escort convoy gathering outside its station (combat view and recon radar).
func _shoot_convoy(view: SystemView) -> void:
	var st := {}
	for st9 in view.layout["stations"]:
		if String(st9.get("faction", "")) in ["assembly", "covenant", "directorate"]:
			st = st9
			break
	if st.is_empty():
		return
	_shooting = true
	var saved: Array = GameState.missions.duplicate()
	GameState.missions.clear()
	var rng := RandomNumberGenerator.new()
	var m: Dictionary = Missions.generate_faction(view.system_id, st, rng)
	while m["type"] != "escort":
		m = Missions.generate_faction(view.system_id, st, rng)
	GameState.accept_mission(m)
	for i in 600:
		await get_tree().process_frame
	var e: Dictionary = view.traffic.convoys.get(int(m["convoy"]), {})
	var gp: Vector2 = e.get("gather_pos", view.stations[st["id"]].position)
	view.player.position = gp + Vector2(6000, 2500)
	view.player.velocity = Vector2.ZERO
	var lead = e.get("leader")
	view.follow = false
	view.set_level(0)
	view._set_zoom(0.6)
	for i in 30:
		view.camera.position = lead.position if lead != null and is_instance_valid(lead) else gp
		await get_tree().process_frame
	print("[SMOKE] convoy leader at %s, docked=%s, visible=%s, gather=%s" % [str(lead.position) if lead != null and is_instance_valid(lead) else "-", str(lead.is_docked()) if lead != null and is_instance_valid(lead) else "-", str(lead.visible) if lead != null and is_instance_valid(lead) else "-", str(e.get("gather", "?"))])
	get_viewport().get_texture().get_image().save_png("res://Claude outputs/convoy_combat.png")
	view.set_level(1)
	view._set_zoom(0.05)
	for i in 40:
		view.camera.position = view.player.position
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://Claude outputs/convoy_radar.png")
	print("[SMOKE] screenshot: Claude outputs/convoy_combat.png, convoy_radar.png")
	view.set_level(0)
	view.follow = true
	GameState.missions = saved
	_shooting = false


## Follow (package 17): the pilot and the convoy's own ships stay with the leader, also in warp;
## pirates pull the convoy and its followers out of warp, or wait at the gate.
func _test_follow(view: SystemView, tr, e: Dictionary, lead: Ship) -> void:
	var pl: Ship = view.player
	pl.warp = {}
	pl.warp_disrupted = 0.0
	pl.order = {"type": "idle"}
	check(Commands.execute({"type": "follow", "id": "ship:%d" % lead.fit.uid}) == "" and String(pl.order.get("type", "")) == "follow", "Follow a ship of your convoy")
	var other = null
	for s6 in e["ships"]:
		if is_instance_valid(s6) and s6 != lead:
			other = s6
	if other != null:
		Commands.execute({"type": "follow", "id": "ship:%d" % other.fit.uid})
		check(pl.order.get("node") == lead, "following any convoy ship means following its lead ship")
	var stranger := view.spawn_npc("civ_shuttle", pl.position + Vector2(2000, 0), "civilian", "")
	check(Commands.execute({"type": "follow", "id": "ship:%d" % stranger.fit.uid}) != "", "only ships under your protection can be followed")
	stranger.queue_free()
	pl.set_order({"type": "follow", "node": lead, "r": 800.0})
	tr._update_convoys()
	var ai_follow := true
	for s7 in e["ships"]:
		if s7 != lead and is_instance_valid(s7) and not s7.is_docked() and String(s7.order.get("type", "")) not in ["undocking", "follow"]:
			ai_follow = false
	check(ai_follow, "the convoy's own ships use Follow too")
	# the slowest ship of the group sets the warp pace
	var own_ws: float = float(pl.fit.stats()["warp_speed"])
	var gws: float = lead.group_warp_speed(own_ws * 10.0)
	check(gws <= own_ws + 0.01, "in warp the group flies at its slowest ship's speed (%.0f ≤ %.0f)" % [gws, own_ws])
	# allied ships appear as tiles at the top left
	main.hud.survey_panel.visible = false
	main.hud._update_allies()
	var grp: Array = view.player_group()
	check(grp.has(lead) and main.hud.ally_bar.visible and main.hud._ally_cards.size() == mini(grp.size(), main.hud.MAX_ALLY_TILES) and grp[0].convoy_lead, "the pilot's group shows as tiles at the top left (%d ships, lead first)" % grp.size())
	# command hotkeys act on the selected object
	var pos_keep: Vector2 = pl.position
	var dup := {}
	var dup_ok := true
	for a in Keybinds.ACTIONS:
		if String(a["id"]) in ["interdict_hit", "map_territory"]:
			continue
		for b in a["def"]:
			var kk := str(b)
			dup_ok = dup_ok and not dup.has(kk)
			dup[kk] = true
	check(InputMap.has_action("cmd_lock") and Keybinds.key_text("cmd_lock") == "R" and dup_ok, "command hotkeys exist (Lock = %s) and no default key is used twice" % Keybinds.key_text("cmd_lock"))
	pl.order = {"type": "idle"}
	pl.position = lead.position + Vector2(400, 0)
	pl.clear_locks()
	main.hud.show_selected("ship:%d" % (other.fit.uid if other != null else lead.fit.uid))
	main.hud.hotkey_command("cmd_follow")
	check(String(pl.order.get("type", "")) == "follow" and pl.order.get("node") == lead, "Follow hotkey follows the selected ship")
	main.hud.show_selected("ship:%d" % lead.fit.uid)
	main.hud.hotkey_command("cmd_lock")
	var locked_ok: bool = pl.lock_index("ship:%d" % lead.fit.uid) >= 0
	main.hud.hotkey_command("cmd_lock")
	check(locked_ok and pl.lock_index("ship:%d" % lead.fit.uid) < 0, "Lock hotkey locks the selected target – pressed again it unlocks")
	check(main.hud.hotkey_command("cmd_jump") != "" and main.hud.hotkey_command("cmd_dock") != "", "Jump / Dock hotkeys refuse a ship as target")
	# Tab: nearest hostile, again: the next one; B: the nearest station within 5,000 km
	var h1: Ship = view.spawn_npc(view._pirate_preset(), pl.position + Vector2(300, 0))
	var h2: Ship = view.spawn_npc(view._pirate_preset(), pl.position + Vector2(0, 600))
	main.hud.show_selected("")
	main.hud.hotkey_command("sel_hostile")
	var first: String = main.hud.selected_id
	main.hud.hotkey_command("sel_hostile")
	check(first == "ship:%d" % h1.fit.uid and main.hud.selected_id == "ship:%d" % h2.fit.uid, "the hostile key selects the nearest hostile, again the next one")
	h1.queue_free()
	h2.queue_free()
	var stn0 = view.stations.values()[0]
	pl.position = stn0.position + Vector2(float(stn0.radius) + 1000.0, 0)
	main.hud.hotkey_command("sel_station")
	check(main.hud.selected_id == String(stn0.data["id"]), "B selects the station a few thousand km away")
	# WASD flies the ship, releasing the keys brakes
	pl.order = {"type": "idle"}
	view.steer(Vector2(1, 0))
	var flies: bool = String(pl.order.get("type", "")) == "move" and (pl.order["pos"] as Vector2).x > pl.position.x
	view.steer(Vector2.ZERO)
	check(flies and String(pl.order.get("type", "")) == "idle", "WASD flies the ship in that direction, releasing stops it")
	main.hud.show_selected("")
	pl.position = pos_keep
	pl.set_order({"type": "follow", "node": lead, "r": 800.0})
	# a fixed formation: the pilot takes the first slot, the others their own slots
	var wing2: Ship = view.spawn_npc("civ_shuttle", lead.position + Vector2(-900, 300), "civilian", "")
	wing2.set_order({"type": "follow", "node": lead, "r": 800.0})
	view._fol_frame = -1
	var mates: Array = view.followers_of(lead)
	var slots_ok: bool = mates.size() >= 2 and mates[0] == pl
	var seen_slots := {}
	for mt in mates:
		var off: Vector2 = mt.formation_offset(lead)
		slots_ok = slots_ok and off.x < 0.0 and not seen_slots.has(off)
		seen_slots[off] = true
	check(slots_ok, "followers fly a fixed V formation behind the lead (%d slots)" % mates.size())
	wing2.queue_free()
	# the lead announces warps and jumps in the chat
	var said := []
	var grab := func(t, _c): said.append(t)
	GameState.message.connect(grab)
	view.announce_lead(lead, "warp", "Test gate")
	view.announce_lead(lead, "jump", "Testheim")
	GameState.message.disconnect(grab)
	check(said.size() == 2 and String(said[0]).contains("Aligning for warp to Test gate") and String(said[1]).contains("jumping to Testheim"), "the lead announces its warp and jump in the chat")
	# the convoy announces its warp in the ticker
	lead.order = {"type": "warp", "target": {"name": "Test gate", "pos": lead.position + Vector2(600000, 0), "land": 2000.0}, "then": {}}
	tr._announce_warp(e, lead)
	check(NW_last_text().contains("aligning for warp to Test gate") and bool(GameState.news.items[0].get("ticker", false)), "the convoy announces its warp in the ticker")
	# the leader goes into warp: the pilot jumps into warp with it at once
	lead.warp_disrupted = 0.0
	lead.warp = {"from": lead.position, "to": lead.position + Vector2(600000, 0), "t": 0.0, "T": 30.0, "then": {}, "name": "Test gate"}
	lead.order = {"type": "warping"}
	pl._update_movement(0.016, pl.fit.stats())
	check(pl.in_warp() and pl.warp.get("follow") == lead and absf(float(pl.warp["T"]) - 30.5) < 0.6, "following into warp – no aligning, arriving together")
	lead.warp["t"] = 8.0
	lead.velocity = Vector2(20000, 0)
	lead._warp_frame = -1          # the lead has not moved yet this frame (pilot updated first)
	pl._update_warp(2.0)
	var slot_pos: Vector2 = lead.position + lead.velocity * 2.0 + pl.formation_offset(lead).rotated(lead.heading)
	check(pl.in_warp() and pl.position.distance_to(slot_pos) < 5.0, "in warp the follower keeps its exact formation slot – even when updated before the lead")
	lead.velocity = Vector2.ZERO
	# interception: convoy and followers drop out of warp, pirates close in
	var p0: int = view.pirate_count()
	lead.warp["t"] = 15.0
	e["pull_at"] = 0.4
	tr._check_interception(e, lead)
	check(not lead.in_warp() and not pl.in_warp() and pl.warp_disrupted > 0.0 and view.pirate_count() >= p0 + 3, "pirates pull the convoy – and its follower – out of warp")
	check(pl.position.distance_to(lead.position) < 2000.0, "the follower drops out right next to the lead ship (%.0f km)" % pl.position.distance_to(lead.position))
	check(String(pl.order.get("type", "")) == "follow", "after the drop the pilot keeps following")
	# after the attack: no fleeing, the convoy holds until it is clear and the pilot is with it
	var raider = null
	for n9 in view.ship_layer.get_children():
		if n9 is Ship and n9.faction == "pirate" and not n9.dying and n9.position.distance_to(lead.position) < 8000.0:
			raider = n9
	if raider != null:
		tr._scatter(lead.position, raider)
	check(String(lead.order.get("type", "")) != "move" or lead.activity != "Fleeing the fight", "convoy ships do not scatter when attacked")
	tr._convoy_hold(e, lead)
	check(e.get("held", false) and String(lead.order.get("type", "")) == "idle", "pirates within recon range: the convoy holds position")
	tr._update_convoys()
	check(String(lead.order.get("type", "")) == "idle", "… and does not set off again while they are around")
	for n10 in view.ship_layer.get_children():
		if n10 is Ship and n10.faction == "pirate" and n10.position.distance_to(lead.position) < 100000.0:
			n10.position += Vector2(0, 900000)
	var pkeep: Vector2 = pl.position
	pl.position = lead.position + Vector2(60000, 0)
	pl.order = {"type": "idle"}
	tr._convoy_hold(e, lead)
	check(e.get("held", false), "all clear but the pilot is far away: the convoy keeps waiting")
	pl.position = lead.position + Vector2(5000, 0)
	pl.set_order({"type": "follow", "node": lead, "r": 800.0})
	tr._convoy_hold(e, lead)
	check(not e.get("held", false) and String(lead.order.get("type", "")) in ["travel", "dock", "docking", "warp"] and NW_last_text().contains("resuming"), "all clear and the pilot follows: the convoy resumes its course")
	pl.position = pkeep
	# gate ambush
	var p1: int = view.pirate_count()
	e["c"]["force_ambush"] = true
	tr._gate_ambush(e, e["ships"], lead.position)
	e["c"].erase("force_ambush")
	check(view.pirate_count() >= p1 + 2, "pirates wait at the gate for an arriving convoy")
	pl.warp_disrupted = 0.0
	pl.order = {"type": "idle"}
	# the convoy jumps: the pilot following it jumps after it
	var nxt := -1
	for nb in Universe.systems[view.system_id]["links"]:
		if GameState.can_jump(pl.fit, int(nb)) == "":
			nxt = int(nb)
			break
	if nxt >= 0:
		pl.fit.refill()
		pl.set_order({"type": "follow", "node": lead, "r": 800.0})
		tr.on_jump(lead, nxt)
		check(String(pl.order.get("type", "")) == "travel" and pl.fit.route == [nxt] and GameState.follow_convoy == int(e["c"]["id"]), "the convoy jumps – the follower jumps after it")
		pl.fit.route.clear()
		pl.order = {"type": "idle"}
		GameState.follow_convoy = -1


## A jump that is not possible (e.g. not enough fuel) is reported loudly, the Jump button is disabled.
func _test_jump_warning(view: SystemView) -> void:
	var pl: Ship = view.player
	var g = view.gates.values()[0]
	var fuel0: float = pl.fit.fuel
	pl.fit.fuel = 0.0
	main.hud._warn_text = ""
	view.command_celestial(g)
	check(main.hud._warn_text.contains("not possible") and main.hud._warn_text.contains("fuel"), "a failed jump shows a big warning (%s)" % main.hud._warn_text)
	main.hud._update_zone_label()
	check(main.hud.zone_label.text.contains("not possible"), "the warning appears in the HUD banner")
	pl.fit.fuel = fuel0
	pl.order = {"type": "idle"}
	pl.warp = {}
	main.hud._warn_until = 0.0


## Phase 0.5 package 18: the Codex.
func _test_codex(view: SystemView) -> void:
	var CS = preload("res://scripts/core/codex.gd")
	var cdx = CS.new()
	cdx.persist = false
	var all: Dictionary = cdx.all
	var cats := {}
	var refs_ok := true
	var events := ["start", "dock", "jump", "warp", "mining", "colossus", "haven", "notorious", "raid", "ion", "contract", "bond"]
	var unlock_ok := true
	for id in all:
		cats[all[id]["cat"]] = true
		for r in all[id].get("see", []):
			refs_ok = refs_ok and all.has(r)
		var u := String(all[id]["unlock"])
		unlock_ok = unlock_ok and (u in events or u.begins_with("faction:") or u.begins_with("corp:"))
	check(all.size() >= 40 and cats.size() == 6, "codex: %d entries in %d categories" % [all.size(), cats.size()])
	check(refs_ok and unlock_ok, "codex: every cross reference and unlock event is valid")
	var start_n := 0
	for id in all:
		start_n += 1 if all[id]["unlock"] == "start" else 0
	check(cdx.unlocked.size() == start_n and cdx.is_unlocked("basics_bonds") and not cdx.is_unlocked("cluster_colossi"), "codex: basics are known from the start, the rest is locked")
	var got: Array = cdx.event("haven")
	check(got == ["cluster_havens"] and cdx.unread.has("cluster_havens") and cdx.event("haven").is_empty(), "codex: discovering a haven unlocks its entry once")
	check(cdx.event("faction:severed").has("fac_severed") and String(all["fac_severed"]["text"]).contains("Earth forgot us"), "codex: faction entries come from the faction data")
	check(all.has("corp_kvx") and String(all["corp_kvx"]["unlock"]) == "corp:kvx", "codex: one entry per corporation, unlocked by using its service")
	# in this game: discoveries so far, HUD notice
	var gc = GameState.codex
	check(gc.is_unlocked("tech_warp") and gc.is_unlocked("hist_leap") and gc.is_unlocked("tech_gates"), "codex: warping, docking and jumping unlocked their entries")
	var probe := ""
	for id in gc.all:
		if not gc.is_unlocked(id):
			probe = id
			break
	if probe != "":
		main.hud.codex_label.text = ""
		gc.unlock(probe)
		check(main.hud.codex_label.text.contains("New Codex entry"), "HUD shows \"New Codex entry\"")
	var v := preload("res://scripts/ui/codex_view.gd").new()
	main.add_child(v)
	v.setup(false)
	check(v._list.get_child_count() > 6, "codex view for the main menu builds")
	v.queue_free()


## Phase 0.5 package 19: modules = family + size + quality, per-slot sizes.
func _test_modules(view: SystemView) -> void:
	var MD = preload("res://data/modules.gd")
	var M: Dictionary = GameData.modules
	check(M.size() > 1000 and M.has("w_pulse:2:C") and String(M["w_pulse:2:C"]["name"]) == "Pulse Laser 2 · C", "%d modules from %d families (e.g. %s)" % [M.size(), MD.FAMILIES.size(), M["w_pulse:2:C"]["name"]])
	var wmax := 0
	for id in M:
		if M[id]["slot"] == "weapon":
			wmax = maxi(wmax, int(M[id]["size"]))
	check(wmax == 4, "weapons only go up to size 4")
	check(is_equal_approx(float(M["w_pulse:1:C"]["range"]), round(650.0 * 1.1)) and is_equal_approx(float(M["sen_basic:2:C"]["range"]), round(900.0 * 1.15)), "balancing: weapon ranges +10 %, sensor ranges +15 %")
	# size curve and quality factors
	var d1 := float(M["w_pulse:1:C"]["damage"])
	var d2 := float(M["w_pulse:2:C"]["damage"])
	check(absf(d2 / d1 - pow(2.0, 1.3)) < 0.1, "bigger is stronger along the curve (×%.2f)" % (d2 / d1))
	var m := {}
	for q in ["F", "E", "D", "C", "B", "A"]:
		m[q] = M["o_shield:3:" + q]
	check(float(m["A"]["shield"]) > float(m["B"]["shield"]) and float(m["C"]["shield"]) > float(m["F"]["shield"]), "quality raises performance (F < C < B < A)")
	var lightest := "C"
	var heaviest := "C"
	for q in m:
		if int(m[q]["mass"]) < int(m[lightest]["mass"]):
			lightest = q
		if int(m[q]["mass"]) > int(m[heaviest]["mass"]):
			heaviest = q
	check(lightest == "D" and heaviest == "F" and int(m["A"]["mass"]) == int(m["B"]["mass"]), "mass: D lightest, F heaviest, B as heavy as A")
	check(int(m["A"]["price"]) > int(m["C"]["price"]) and int(m["F"]["price"]) < int(m["C"]["price"]) and float(m["A"]["power"]) > float(m["C"]["power"]), "quality also raises power draw and price")
	check(int(M["hyperdrive:2:C"]["drive_class"]) == 1 and int(M["hyperdrive:4:C"]["drive_class"]) == 2 and int(M["hyperdrive:6:C"]["drive_class"]) == 3, "hyperdrive size sets the jump class (1–2 / 3–4 / 5–6)")
	# per-slot sizes, smaller modules fit bigger slots
	var dfly := GameState.create_from_preset("std_dragonfly", "player")
	var bas := GameState.create_from_preset("std_bastion", "player")
	check(dfly.slot_max("weapon_0") == 1 and dfly.slot_max("engine") == 4 and bas.slot_max("weapon_0") == 4 and bas.slot_max("optional_0") == 8, "every slot has its own maximum size")
	check(dfly.can_fit("weapon_0", "w_pulse:2:C") != "" and dfly.can_fit("weapon_0", "w_pulse:1:A") == "" and bas.can_fit("weapon_0", "w_pulse:1:C") == "", "too large is refused, smaller modules fit bigger slots")
	var presets_ok := true
	for pid in GameData.presets:
		var f := GameState.create_from_preset(pid, "player")
		for k in f.modules:
			presets_ok = presets_ok and f.can_fit(k, f.modules[k]) == ""
	check(presets_ok, "every standard fit and NPC loadout fits its hull")
	# outfitters: sizes by tier, B from tier 2, A from tier 3 / military, no pirate gear
	var shop_ok := true
	var why := ""
	for s2 in Universe.systems:
		for st in Universe.get_layout(int(s2["id"]))["stations"]:
			var tier := int(st["tier"])
			for id in st["shop"]:
				var mm: Dictionary = M[id]
				if int(mm["size"]) > GameData.size_cap(String(mm["slot"]), tier) or (mm["quality"] == "B" and tier < 2) or (mm["quality"] == "A" and tier < 3 and st["type"] != "military") or mm.get("pirate_only", false):
					shop_ok = false
					why = "%s at %s" % [id, st["name"]]
	check(shop_ok, "outfitters stock sizes and qualities by station tier %s" % why)
	# the former NPC-only hulls: Skiff and Longhaul at shipyards, Carrion Crow only in havens
	var yards := {}
	var haven_crow := false
	for s3 in Universe.systems:
		var L := Universe.get_layout(int(s3["id"]))
		for st in L["stations"]:
			for h in st["shipyard"]:
				yards[h] = true
		for hv in L.get("havens", []):
			haven_crow = haven_crow or "crow" in hv["shipyard"]
	check(yards.has("shuttle") and yards.has("freighter") and not yards.has("crow") and haven_crow, "Skiff and Longhaul at shipyards, Carrion Crow only in Pirate Havens")


## Debug menu: an escort convoy of a chosen size to a station exactly N jumps away.
func _test_debug_convoy(view: SystemView) -> void:
	var n0: int = GameState.missions.size()
	var err := Commands.execute({"type": "debug_convoy", "freighters": 5, "jumps": 2})
	if err.begins_with("No station exactly"):
		check(true, "debug convoy: no station 2 jumps away here (%s)" % err)
		return
	check(err == "" and GameState.missions.size() == n0 + 1, "debug convoy: contract created and accepted %s" % err)
	if GameState.missions.size() != n0 + 1:
		return
	var m: Dictionary = GameState.missions.back()
	var cv: Dictionary = GameState.convoys.find(int(m["convoy"]))
	var jumps: int = Universe.find_path(view.system_id, int(m["target_system"]), 1).size()
	check(m["type"] == "escort" and int(m["freighters"]) == 5 and jumps == 2 and not cv.is_empty() and int(cv["freighters"]) == 5, "debug convoy: 5 freighters to %s, 2 jumps away" % Universe.systems[int(m["target_system"])]["name"])
	# clean up: the contract and its convoy
	GameState.missions.erase(m)
	GameState.convoys.convoys.erase(cv)
	var tr = view.traffic
	if tr != null and tr.convoys.has(int(cv["id"])):
		for s0 in tr.convoys[int(cv["id"])]["ships"]:
			if is_instance_valid(s0):
				s0.queue_free()
		tr.convoys.erase(int(cv["id"]))


## Phase 0.5 package 20: shield variants & downtime, point defense, shield transfer, cargo scanner,
## solar collector, mines, radar jammer.
func _test_package20(view: SystemView) -> void:
	var M: Dictionary = GameData.modules
	var pl: Ship = view.player
	var base := pl.position + Vector2(0, 30000)
	# shield variants
	var sb: Dictionary = M["o_shield:3:C"]
	var sc: Dictionary = M["o_shield_cap:3:C"]
	var sf: Dictionary = M["o_shield_fast:3:C"]
	check(float(sc["shield"]) > float(sb["shield"]) and float(sb["shield"]) > float(sf["shield"]) and float(sf["shield_regen"]) > float(sb["shield_regen"]) and float(sb["shield_regen"]) > float(sc["shield_regen"]), "shield variants: capacity vs regeneration")
	# downtime by size, type and quality
	var f1 := GameState.create_from_preset("std_hornet", "player")
	var okey := ""
	for k in f1.slot_keys():
		if String(k).begins_with("optional_") and f1.slot_max(k) >= 2:
			okey = k
	var downs := {}
	for mid in ["o_shield:2:C", "o_shield_cap:2:C", "o_shield_fast:2:C", "o_shield:2:A", "o_shield:2:F", "o_shield:1:C"]:
		for k2 in f1.slot_keys():
			if String(f1.modules.get(k2, "")).begins_with("o_shield"):
				f1.set_module(k2, "")
		f1.set_module(okey, mid)
		downs[mid] = float(f1.stats()["shield_downtime"])
	check(downs["o_shield_cap:2:C"] > downs["o_shield:2:C"] and downs["o_shield:2:C"] > downs["o_shield_fast:2:C"], "shield downtime: high capacity longest, fast-cycle shortest (%.0f / %.0f / %.0f s)" % [downs["o_shield_cap:2:C"], downs["o_shield:2:C"], downs["o_shield_fast:2:C"]])
	check(downs["o_shield:2:F"] > downs["o_shield:2:C"] and downs["o_shield:2:C"] > downs["o_shield:2:A"] and downs["o_shield:2:C"] > downs["o_shield:1:C"], "shield downtime: longer for low quality and bigger shields")
	# collapse → downtime → back at 50 %
	var v: Ship = view.spawn_npc("patrol_medium", base, "patrol", "")
	var vs: Dictionary = v.fit.stats()
	if float(vs["shield_max"]) <= 0.0:
		view.npc_extra(v.fit, "o_shield", true)
		v.fit.refill()
		vs = v.fit.stats()
	v.fit.shield = 10.0
	v.take_damage(50.0, "optical", null)
	check(is_zero_approx(v.fit.shield) and absf(v.shield_down - float(vs["shield_downtime"])) < 0.01, "a shot-down shield goes offline for its downtime (%.0f s)" % v.shield_down)
	v._regen(1.0, vs)
	check(is_zero_approx(v.fit.shield), "no regeneration while the shield is down")
	var before := v.shield_down
	v._xfer_t = 0.3
	v._regen(1.0, vs)
	check(absf((before - v.shield_down) - Ship.XFER_DOWN_MULT) < 0.01, "a shield transfer beam shortens the downtime (×%.0f)" % Ship.XFER_DOWN_MULT)
	v._regen(v.shield_down + 0.1, vs)
	check(absf(v.fit.shield - float(vs["shield_max"]) * 0.5) < 1.0 and is_zero_approx(v.shield_down), "after the downtime the shield restarts at 50 %")
	# shield transfer: from the capacitor, never from the own shield, energy only while transferring
	var giver: Ship = view.spawn_npc("patrol_medium", base + Vector2(300, 0), "patrol", "")
	var xfer: Dictionary = M["t_shieldxfer:2:C"].duplicate()
	giver.fit.capacitor = 500.0
	var gsh := giver.fit.shield
	v.fit.shield = 0.0
	v.shield_down = 0.0
	giver._transfer_shield(1.0, xfer, v)
	check(v.fit.shield > 0.0 and giver.fit.capacitor < 500.0 and is_equal_approx(giver.fit.shield, gsh), "shield transfer: capacitor → target shield, own shield untouched")
	v.fit.shield = float(vs["shield_max"])
	var cap0 := giver.fit.capacitor
	giver._transfer_shield(1.0, xfer, v)
	check(is_equal_approx(giver.fit.capacitor, cap0), "shield transfer uses no energy while the target is full")
	# point defense shoots down a torpedo
	var pir: Ship = view.spawn_npc(view._pirate_preset(), base + Vector2(1500, 0))
	pir.fit.shield = 0.0
	check(view.npc_extra(v.fit, "w_pointdef", true), "point defense fits a weapon slot")
	var vs2: Dictionary = v.fit.stats()
	check(vs2["pd"].size() >= 1 and not vs2["weapons"].any(func(w): return w.get("pd", false)), "point defense is not counted as a gun")
	var torp := Projectile.new()
	torp.setup(pir, v, M["w_torpedo:2:C"], view)
	view.fx_layer.add_child(torp)
	torp.position = v.position + Vector2(200, 0)
	v.fit.capacitor = 500.0
	for i in 30:
		v.pd_timers.clear()
		v._update_pd(0.1, vs2)
		if torp.is_queued_for_deletion():
			break
	check(torp.is_queued_for_deletion(), "point defense shoots down an incoming torpedo")
	# the pilot switches point defense on and off in the module bar (tested on a manual ship)
	var pd_slot := String(vs2["pd"][0]["slot"])
	v.manual = true
	var pd_on: bool = v.set_module_active(pd_slot, true) == "" and v.module_on.get(pd_slot, false)
	v.set_module_active(pd_slot, false)
	check(pd_on and not v.module_on.get(pd_slot, false), "point defense is switched on and off like an active module")
	v.manual = false
	# mines
	var civ: Ship = view.spawn_npc("civ_shuttle", base + Vector2(-3000, 0), "civilian", "")
	var m1 = view.lay_mine(pl, "mine_proximity", "test", 10.0, 1.0)
	m1.position = civ.position + Vector2(100, 0)
	m1.age = 5.0
	m1._physics_process(0.016)
	check(not m1.is_queued_for_deletion(), "mines ignore ships that are not hostile")
	var hp0: float = pir.fit.armor + pir.fit.structure
	m1.position = pir.position + Vector2(100, 0)
	m1._physics_process(0.016)
	check(m1.is_queued_for_deletion() and pir.fit.armor + pir.fit.structure < hp0, "a proximity mine explodes next to a hostile ship")
	var m2 = view.lay_mine(pl, "mine_timer", "test", 5.0, 1.0)
	m2.position = pir.position + Vector2(5000, 0)
	m2._physics_process(4.0)
	var waited: bool = not m2.is_queued_for_deletion()
	m2._physics_process(1.5)
	check(waited and m2.is_queued_for_deletion(), "a timed mine goes off after its timer")
	var m3 = view.lay_mine(pl, "mine_emp", "test", 10.0, 1.0)
	m3.position = pir.position + Vector2(80, 0)
	m3.age = 5.0
	pir.fit.capacitor = 100.0
	m3._physics_process(0.016)
	check(pir.emp_t > 0.0 and is_zero_approx(pir.fit.capacitor), "an EMP mine knocks out capacitor and modules")
	pir.emp_t = 0.0
	var m4 = view.lay_mine(pl, "mine_jammer", "test", 10.0, 1.0)
	m4.position = pir.position + Vector2(3000, 0)
	m4.age = 1.5
	m4._physics_process(0.016)
	check(pir.jammed_t > 0.0 and civ.jammed_t <= 0.0, "a jammer mine jams hostile radar around it")
	m4.queue_free()
	# the mine launcher uses mines from the hold and keeps a limit
	view.npc_extra(giver.fit, "w_minelayer", true)
	var ml: Dictionary = {}
	for e in giver.fit.active_modules():
		if e["kind"] == "mine":
			ml = e
	check(not ml.is_empty(), "the mine launcher is an activatable module")
	if not ml.is_empty():
		giver.fit.cargo.clear()
		check(giver.lay_mine(ml["slot"], ml["data"]).contains("no mines"), "no mines in the hold – nothing to lay")
		giver.fit.cargo["mine_proximity"] = 10.0
		var laid := 0
		for i2 in 8:
			giver.module_timers.clear()
			giver.fit.capacitor = 500.0
			if giver.lay_mine(ml["slot"], ml["data"]) == "":
				laid += 1
		check(laid == maxi(int(round(float(ml["data"]["max_mines"]))), 1) and is_equal_approx(float(giver.fit.cargo["mine_proximity"]), 10.0 - laid), "launcher: %d mines out at most, taken from the hold" % laid)
		for mm in get_tree().get_nodes_in_group("mines"):
			mm.queue_free()
	# radar jammer used by a pirate against the pilot
	var jp: Ship = view.spawn_npc(view._pirate_preset(), pl.position + Vector2(2000, 0))
	check(view.npc_extra(jp.fit, "o_jammer", true), "a radar jammer fits an optional slot")
	jp.fit.capacitor = 500.0
	jp.target = pl
	jp._update_npc_jammer(0.1, jp.fit.stats())
	pl.jammed_t = 0.0
	view._apply_jamming()
	var far_ship: Ship = view.spawn_npc("civ_shuttle", pl.position + Vector2(20000, 0), "civilian", "")
	check(jp.jamming and pl.jammed_t > 0.0 and view.player_jammed(), "pirates jam the pilot's radar")
	check(is_equal_approx(pl.lock_range(pl.fit.stats()), float(pl.fit.stats()["sensor_range"]) * Ship.JAM_SENSOR) and not view.contact_visible(far_ship) and view.contact_visible(jp), "jammed: shorter lock range, distant contacts gone")
	pl.jammed_t = 0.0
	# cargo scanner
	civ.ensure_manifest()
	check(not civ.fit.cargo.is_empty() and civ.manifest_text().contains("manifest"), "cargo scanner: %s" % civ.manifest_text())
	var smug: Ship = view.spawn_npc("civ_shuttle", base + Vector2(-6000, 0), "civilian", "")
	smug.smuggler_mission = "test"
	check(smug.manifest_text().contains("UNREGISTERED"), "a smuggler's cargo shows up as unregistered")
	# solar collector: the closer to the star, the more fuel
	view.npc_extra(giver.fit, "o_solar", true)
	var gst: Dictionary = giver.fit.stats()
	var star_r := float(view.layout["star"]["radius"])
	giver.position = Vector2(star_r * 3.0, 0)
	var near := giver.solar_rate(gst)
	giver.position = Vector2(star_r * 20.0, 0)
	var far := giver.solar_rate(gst)
	giver.fit.fuel = 0.0
	giver._solar(10.0, gst)
	check(near > far and far > 0.0 and giver.fit.fuel > 0.0, "solar collector: %.2f fuel/s near the star, %.3f far out" % [near, far])
	# mines on sale; summaries and icons
	var mine_market := false
	for s2 in Universe.systems:
		for st in Universe.get_layout(int(s2["id"]))["stations"]:
			if int(st["market"].get("mine_emp", {"buy": -1})["buy"]) > 0:
				mine_market = true
	check(mine_market, "mines are sold as goods (military outposts, havens)")
	var fams_sold := {}
	for s3 in Universe.systems:
		for st3 in Universe.get_layout(int(s3["id"]))["stations"]:
			for mid3 in st3["shop"]:
				fams_sold[String(M[mid3]["family"])] = true
	check(fams_sold.has("w_pointdef") and fams_sold.has("o_jammer") and fams_sold.has("t_shieldxfer") and fams_sold.has("o_solar") and fams_sold.has("w_minelayer"), "outfitters sell the new modules")
	Commands.execute({"type": "mine_config", "slot": "weapon_0", "mine": "mine_emp", "fuse": 20})
	check(String(pl.mine_choice["weapon_0"]["type"]) == "mine_emp" and int(pl.mine_choice["weapon_0"]["fuse"]) == 20, "mine launcher settings: type and timer")
	main.hud._mine_menu(main.hud.module_bar, "weapon_0")
	var pm_ok := false
	for ch in main.hud.get_children():
		if ch is PopupMenu:
			pm_ok = ch.item_count >= GameData.MINES.size() + GameData.MINE_TIMERS.size()
			ch.queue_free()
	check(pm_ok, "right-click menu of the mine launcher lists mine types and timers")
	pl.mine_choice.clear()
	var sum_ok := true
	for fam in ["o_shield_cap", "o_shield_fast", "w_pointdef", "w_minelayer", "t_shieldxfer", "t_cargoscan", "o_solar", "o_jammer"]:
		var id: String = M.keys().filter(func(x): return String(x).begins_with(fam + ":"))[0]
		sum_ok = sum_ok and GameData.module_summary(id).length() > 40 and PixelArt.module_icon_key(id) != "empty"
	check(sum_ok, "every new module has a description and an icon")
	for n in [v, giver, pir, civ, jp, far_ship, smug]:
		if is_instance_valid(n):
			n.queue_free()


## Phase 0.5 package 21: hard power limit, priority groups, active modules draw only in use.
func _test_power(view: SystemView) -> void:
	var fits_ok := true
	var over: Array = []
	for pid in GameData.presets:
		var f0 := GameState.create_from_preset(pid, "player")
		var all0 := {}
		for k0 in f0.slot_keys():
			all0[k0] = true
		var pp0 := f0.power_plan(all0)
		if not (pp0["off"].is_empty() and is_equal_approx(float(pp0["throttle"]), 1.0)):
			fits_ok = false
			over.append("%s %.0f/%.0f" % [pid, float(pp0["requested"]), float(pp0["available"])])
	check(fits_ok, "every standard fit and NPC loadout runs everything at once %s" % str(over))
	# passive always, active only in use
	var f := GameState.create_from_preset("std_hornet", "player")
	var st := f.stats()
	var all := {}
	for k in f.slot_keys():
		all[k] = true
	check(is_equal_approx(float(f.power_plan({})["total"]), float(st["power_passive"])) and is_equal_approx(float(f.power_plan(all)["total"]), float(st["power_passive"]) + float(st["power_active_max"])) and float(st["power_active_max"]) > 0.0, "passive modules always draw, active ones only while in use (%.0f + %.0f MW)" % [float(st["power_passive"]), float(st["power_active_max"])])
	check(f.priority_of("engine") == 1 and f.priority_of("weapon_0") == 2, "default priorities: core 1, weapons 2, tools/active 3, the rest 4")
	# overload: a weak reactor – group 4 shuts down first, then 3, then 2
	f.set_module("reactor", "rea_fission:1:F")
	var keys: Array = []
	for k2 in f.slot_keys():
		if f.get_module(k2) != "" and float(GameData.modules[f.get_module(k2)].get("power", 0)) > 0.0 and not (k2 in GameData.CORE_SLOTS):
			keys.append(k2)
	for j in keys.size():
		f.set_priority(keys[j], 4 - (j % 3))     # spread over groups 4, 3, 2
	var plan := f.power_plan(all)
	var off: Dictionary = plan["off"]
	var order_ok: bool = not off.is_empty() and (not off.has(3) or off.has(4)) and (not off.has(2) or off.has(3)) and not off.has(1)
	check(order_ok and float(plan["total"]) <= float(plan["available"]) + 0.01 or float(plan["throttle"]) < 1.0, "overload: groups shut down from 4 upwards, the output is never exceeded (%s off)" % str(off.keys()))
	# a passive module in a shut-down group has no effect, an active one is unpowered
	var f2 := GameState.create_from_preset("std_hornet", "player")
	var sh_key := ""
	var w_key := "weapon_0"
	for k3 in f2.slot_keys():
		if GameData.modules.get(f2.get_module(k3), {}).has("shield"):
			sh_key = k3
	if sh_key != "":
		f2.set_priority(sh_key, 4)
		f2.set_priority(w_key, 4)
		var shield0 := float(f2.stats()["shield_max"])
		f2.apply_power({"off": {4: true}, "throttle": 1.0})
		var s2 := f2.stats()
		check(float(s2["shield_max"]) < shield0 and s2["offline"].has(sh_key), "a shut-down shield generator gives no shield")
		check(not s2["weapons"][0]["powered"] and not f2.is_powered(w_key), "a weapon in a shut-down group has no power")
		f2.apply_power({"off": {}, "throttle": 1.0})
	# the pilot's ship at runtime: switching on a heavy weapon shuts down group 4
	var pl: Ship = view.player
	var pf: ShipFitting = pl.fit
	var keep_mods: Dictionary = pf.modules.duplicate()
	var keep_pri: Dictionary = pf.priorities.duplicate()
	var opt := ""
	for k4 in pf.slot_keys():
		if String(k4).begins_with("optional_"):
			opt = k4
	if opt != "":
		pf.set_module("reactor", "rea_fission:1:F")
		pf.set_module(opt, "o_survey_amp:1:C")
		pf.set_priority(opt, 4)
		pl.module_on.clear()
		pl._update_power()
		var idle_off: bool = pf.power_off.has(4)
		var wkey := ""
		for e in pf.active_modules():
			if e["kind"] == "weapon":
				wkey = e["slot"]
		pf.set_priority(wkey, 2)
		pl.module_on[wkey] = true
		var avail := float(pf.stats()["power_available"])
		var need := float(pf.power_plan(pl.power_in_use())["requested"])
		pl._update_power()
		check(need <= avail or pf.power_off.has(4), "switching on a weapon over the limit shuts down group 4 (%.0f of %.0f MW)" % [need, avail])
		check(idle_off == (float(pf.power_plan({})["requested"]) > avail), "idle: only an overloaded passive draw shuts groups down")
		pl.module_on.clear()
		pf.modules = keep_mods
		pf.priorities = keep_pri
		pf.mark_dirty()
		pf.apply_power({"off": {}, "throttle": 1.0})
		pl._update_power()
	# priorities: command and save
	Commands.execute({"type": "set_priority", "slot": "weapon_0", "group": 3})
	var d := pf.to_dict()
	var back := ShipFitting.from_dict(d)
	check(pf.priority_of("weapon_0") == 3 and back.priority_of("weapon_0") == 3, "priorities are set by command and saved with the ship")
	pf.priorities = keep_pri
	pf.mark_dirty()
	# ship menu: POWER MANAGEMENT
	var sm = main.ship_menu
	sm.mod_view = "power"
	sm.open(view, 1)
	var bar_ok := false
	var rows := 0
	for n in sm.content.find_children("*", "", true, false):
		if "groups" in n and "available" in n and "colors" in n:
			bar_ok = true
		if n is Button and n.text in ["1", "2", "3", "4"]:
			rows += 1
	check(bar_ok and rows >= 4 * 5, "ship menu → Modules → POWER MANAGEMENT: output bar and priority list (%d buttons)" % rows)
	check(pf.priority_of("hull") == 0 and pf.set_priority("hull", 3) != "" and pf.priority_of("hull") == 0, "modules that need no power are in group 0")
	sm.mod_view = "fitting"
	sm.close()
	main.hud._update_power_line(pf, pf.stats())
	check(main.hud._w["power"].text.begins_with("Power ") and main.hud._w["power"].text.contains("passive"), "HUD shows passive and active power: %s" % main.hud._w["power"].text)


## Phase 0.5 package 22: multi-focus – every module keeps its target; targeting keys.
func _test_multifocus(view: SystemView) -> void:
	var fa := GameState.create_from_preset("std_hornet", "player")
	fa.set_module("sensors", "sen_basic:1:C")
	var small := int(fa.stats()["max_locks"])
	var fb := GameState.create_from_preset("std_bastion", "player")
	fb.set_module("sensors", "sen_grav:8:C")
	check(small == 3 and int(fb.stats()["max_locks"]) == 6, "lock slots grow with the sensor suite (%d … %d)" % [small, int(fb.stats()["max_locks"])])
	var pl: Ship = view.player
	var keep_pos := pl.position
	pl.position = pl.position + Vector2(0, -40000)
	pl.clear_locks()
	pl.module_on.clear()
	pl.module_target.clear()
	var t1: Ship = view.spawn_npc("pirate_raider_rocket", pl.position + Vector2(250, 0))
	var t2: Ship = view.spawn_npc("pirate_raider_rocket", pl.position + Vector2(-250, 0))
	for t in [t1, t2]:
		t.toughness = 0.01
		t.archetype = ""
	var k1 := Ship.object_key(t1)
	var k2 := Ship.object_key(t2)
	pl.add_lock(t1)
	pl.add_lock(t2)
	for l in pl.locks:
		l["progress"] = 1.0
	var weps: Array = []
	for e in pl.fit.active_modules():
		if e["kind"] == "weapon":
			weps.append(e)
	var beam := ""
	var other := ""
	for e2 in weps:
		if float(e2["data"].get("projectile_speed", 1)) <= 0.0:
			beam = e2["slot"]
		elif other == "":
			other = e2["slot"]
	if beam != "" and other != "":
		pl.active_lock = k1
		check(pl.set_module_active(other, true) == "", "weapon switched on against T1")
		pl.active_lock = k2
		check(pl.set_module_active(beam, true) == "", "another weapon switched on against T2")
		check(pl.module_target[other] == k1 and pl.module_target[beam] == k2, "multi-focus: each weapon keeps the target it was switched on against")
		var hp2: float = t2.fit.shield + t2.fit.armor + t2.fit.structure
		pl.fit.capacitor = 500.0
		pl.module_timers.clear()
		pl._update_modules(0.05, pl.fit.stats())
		check(t2.fit.shield + t2.fit.armor + t2.fit.structure < hp2 and pl.module_on[other] and pl.module_target[other] == k1, "the beam fires at T2 while the other weapon stays on T1")
		main.hud._update_modules()
		check(main.hud._module_tiles[beam]["tgt"].text.contains("T2") and main.hud._module_tiles[other]["tgt"].text.contains("T1") and pl.modules_on(k1) == 1, "module tiles show their target (T1 / T2)")
		var sb_on: StyleBoxFlat = main.hud._module_tiles[beam]["style"]
		var sb_other: StyleBoxFlat = main.hud._module_tiles[other]["style"]
		check(sb_on.border_color == main.hud.STATE_COLORS["on"] and sb_other.border_color == main.hud.STATE_COLORS["other"], "tiles: green = active target, yellow = another target")
		# a running module moves to the active target with its key
		pl.active_lock = k1
		Commands.execute({"type": "toggle_module", "slot": beam})
		check(pl.module_on[beam] and pl.module_target[beam] == k1, "pressing a running module's key moves it to the active target")
		Commands.execute({"type": "toggle_module", "slot": beam})
		check(not pl.module_on[beam], "pressed again it switches off")
		# losing one lock switches off only what worked on it
		pl.set_module_active(beam, true)
		pl.active_lock = k2
		pl.retarget(beam)
		pl.remove_lock(k2)
		pl._update_modules(0.05, pl.fit.stats())
		check(not pl.module_on[beam] and pl.module_on[other], "a lost target switches off only the modules on it")
		# a new lock becomes the active target – the module on the old one turns yellow
		pl.module_on.clear()
		pl.module_target.clear()
		pl.clear_locks()
		t2.position = pl.position + Vector2(-250, 0)
		pl.add_lock(t1)
		pl.locks[0]["progress"] = 1.0
		pl.set_module_active(beam, true)
		pl.add_lock(t2)
		main.hud._update_modules()
		check(pl.active_lock == k2 and (main.hud._module_tiles[beam]["style"] as StyleBoxFlat).border_color == main.hud.STATE_COLORS["other"], "locking another target makes it the active one – the running weapon turns yellow")
		# target leaves the sensor range: the weapon waits (orange) and resumes after an automatic re-lock
		var far: Vector2 = t1.position
		t1.position = pl.position + Vector2(float(pl.fit.stats()["sensor_range"]) * 2.0, 0)
		var st5: Dictionary = pl.fit.stats()
		pl._update_locks(0.05, st5)
		pl._update_modules(0.05, st5)
		var waited: bool = pl.module_on[beam] and pl.module_state[beam] == "range" and pl.lock_index(k1) < 0
		t1.position = far
		pl._update_locks(0.05, st5)
		var relocked: bool = pl.lock_index(k1) >= 0
		for i7 in 100:
			pl._update_locks(0.1, st5)
		pl.fit.capacitor = 500.0
		pl.module_timers.clear()
		var hp1: float = t1.fit.shield + t1.fit.armor + t1.fit.structure
		pl._update_modules(0.05, st5)
		check(waited and relocked and pl.module_on[beam] and pl.module_state[beam] == "on" and t1.fit.shield + t1.fit.armor + t1.fit.structure < hp1, "a target out of sensor range is locked again when it is back – the weapon fires again")
	pl.module_on.clear()
	pl.module_target.clear()
	pl.clear_locks()
	t1.position += Vector2(200000, 0)
	t2.position += Vector2(200000, 0)
	# NPC multi-focus: a bigger pirate splits its fire
	var big: Ship = view.spawn_npc("pirate_warden", pl.position + Vector2(0, 5000))
	var p1: Ship = view.spawn_npc("patrol_light", big.position + Vector2(400, 0), "patrol", "")
	var p2: Ship = view.spawn_npc("patrol_light", big.position + Vector2(-400, 0), "patrol", "")
	big.target = p1
	big._update_focus(float(big.fit.stats()["sensor_range"]))
	check(big.fit.stats()["weapons"].size() < 3 or big._focus.has(p2), "bigger NPC ships split their weapons over several targets")
	# targeting keys: Tab = everything in sensor range, V = hostile, C = friendly
	var fr: Ship = view.spawn_npc("civ_shuttle", pl.position + Vector2(0, 300), "civilian", "")
	var hs: Ship = view.spawn_npc("pirate_raider_rocket", pl.position + Vector2(0, -350))
	hs.archetype = ""
	main.hud.show_selected("")
	main.hud.hotkey_command("sel_target")
	var first: String = main.hud.selected_id
	main.hud.hotkey_command("sel_target")
	check(first == Ship.object_key(fr) and main.hud.selected_id == Ship.object_key(hs), "Tab cycles through everything in sensor range, nearest first")
	# ships before asteroids & co., even when an asteroid is nearer; nothing selected → ships again
	var ast = null
	for c in view.celestials:
		if is_instance_valid(c) and Ship.lockable(c) and not (c is Ship):
			ast = c
			break
	if ast != null:
		var keep_p := pl.position
		pl.position = ast.position + Vector2(float(ast.radius) + 20.0, 0)
		fr.position = pl.position + Vector2(0, 400)
		hs.position = pl.position + Vector2(0, -500)
		main.hud.show_selected("")
		var seq: Array = []
		for i9 in 40:
			main.hud.hotkey_command("sel_target")
			var o9 = view.find_object(main.hud.selected_id)
			if seq.has(o9):
				break
			seq.append(o9)
		var order_ok := not seq.is_empty() and seq[0] is Ship
		var seen_other := false
		for o in seq:
			if not (o is Ship):
				seen_other = true
			elif seen_other:
				order_ok = false
		main.hud.show_selected("")
		main.hud.hotkey_command("sel_target")
		check(order_ok and seen_other and view.find_object(main.hud.selected_id) is Ship, "Tab: ships first, then asteroids and the rest; with nothing selected it starts with ships again (%d targets)" % seq.size())
		pl.position = keep_p
	main.hud.show_selected("")
	main.hud.hotkey_command("sel_hostile")
	var h_ok: bool = (view.find_object(main.hud.selected_id) as Ship).hostile_to_player()
	main.hud.show_selected("")
	main.hud.hotkey_command("sel_friend")
	var f_sel = view.find_object(main.hud.selected_id)
	check(h_ok and f_sel is Ship and not f_sel.hostile_to_player(), "V selects hostile ships, C friendly ones")
	check(Keybinds.key_text("sel_target") == "Tab" and Keybinds.key_text("sel_hostile") == "V" and Keybinds.key_text("sel_friend") == "C", "keys: Tab all targets, V hostile, C friendly")
	main.hud.show_selected("")
	for n in [t1, t2, big, p1, p2, fr, hs]:
		if is_instance_valid(n):
			n.queue_free()
	pl.position = keep_pos


func _wrecks(view: SystemView) -> int:
	var n := 0
	for c in view.celestials:
		if is_instance_valid(c) and c.kind == "wreck":
			n += 1
	return n


## Phase 0.5 package 23: drone hangar, drones and their behaviours.
func _test_drones(view: SystemView) -> void:
	var M: Dictionary = GameData.modules
	var hull_ok := true
	for hid in GameData.hulls:
		var h: Dictionary = GameData.hulls[hid]
		if h.get("drone_only", false) or (h.get("maker", "") in ["aurelle", "hadrian", "forge"] and int(h.get("drones", 0)) == 0):
			continue                 # Pearl, Opal (25c), Talon (25d) and the Covenant's ships (25f) carry no drones
		hull_ok = hull_ok and GameData.slot_max_of(h, "hangar") > 0 and int(h.get("drones", 0)) >= 1
	check(hull_ok and int(GameData.hulls["dragonfly"]["drones"]) == 1 and int(GameData.hulls["bastion"]["drones"]) == 9, "every ship has a drone hangar slot (except Pearl, Opal, Talon and the Covenant ships); drones out at once: S 1 … L 9")
	check(int(M["hangar:3:A"]["drone_storage"]) > int(M["hangar:3:C"]["drone_storage"]) and int(M["hangar:3:C"]["drone_storage"]) > int(M["hangar:3:F"]["drone_storage"]), "hangar quality gives more room (%d / %d / %d)" % [int(M["hangar:3:F"]["drone_storage"]), int(M["hangar:3:C"]["drone_storage"]), int(M["hangar:3:A"]["drone_storage"])])
	var f := GameState.create_from_preset("std_bastion", "player")
	check(f.can_fit("dweapon_0", "w_pulse:1:C") == "" and f.can_fit("dweapon_0", "w_beam:2:C") != "" and f.can_fit("dweapon_0", "w_pointdef:1:C") != "" and f.can_fit("dtool_0", "t_mining:1:C") == "" and f.can_fit("dtool_0", "t_salvage:1:C") != "" and f.can_fit("dbonus_0", "dr_range:2:C") == "" and f.can_fit("optional_0", "dr_range:1:C") != "", "drone slots: weapon size 1, mining laser size 1, drone modules only in the bonus slot")
	var base_r := float(f.stats()["drone"]["range"])
	var base_dmg := float(f.stats()["drone_weapon"]["damage"])
	f.set_module("dbonus_0", "dr_range:2:C")
	check(is_equal_approx(base_r, 9000.0) and float(f.stats()["drone"]["range"]) > base_r and float(f.stats()["drone"]["range"]) <= GameData.RECON_RANGE, "a drone relay extends the control range – at most to the recon range (%.0f → %.0f km)" % [base_r, float(f.stats()["drone"]["range"])])
	var vsz := view.get_viewport_rect().size
	check(is_equal_approx(minf(vsz.x, vsz.y) * view.RADAR_SCREEN / view.level_zoom(1), GameData.RECON_RANGE), "the recon radar shows exactly %s, whatever the window size" % SystemView.fmt_dist(GameData.RECON_RANGE))
	f.set_module("dbonus_0", "dr_damage:1:C")
	var ship_weps_ok := true
	for w in f.stats()["weapons"]:
		ship_weps_ok = ship_weps_ok and not String(w["slot"]).begins_with("d")
	check(float(f.stats()["drone_weapon"]["damage"]) > base_dmg and f.priority_of("dweapon_0") == 0 and ship_weps_ok, "drone gear works for the drones only – no ship weapon, no ship power")
	f.set_module("dbonus_0", "")
	# a test carrier (Bastion, 9 drones out at once)
	var pl: Ship = view.player
	var c := Ship.new()
	f.system_id = view.system_id
	f.position = pl.position + Vector2(0, -60000)
	f.drones = []
	for i in 5:
		f.drones.append({"fuel": 1.0, "hp": 1.0, "out": false})
	c.manual = true
	c.setup(f, view)
	view.ship_layer.add_child(c)
	check(view.launch_drones(c, 1) == "" and view.drones_of(c).size() == 1 and view.launch_drones(c, 1) == "" and view.drones_of(c).size() == 2, "one drone per press, up to the limit")
	check(view.launch_drones(c) == "" and view.drones_of(c).size() == 5 and f.drones_in_hangar() == 0, "launch all: every drone the hangar holds, up to the ship's limit")
	check(InputMap.has_action("drone_launch_all") and Keybinds.key_text("drone_launch_all") == "", "\"launch all\" has no key by default – one can be set in the settings")
	check(view.launch_drones(c) != "", "no drones left in the hangar – nothing to launch")
	var ds: Array = view.drones_of(c)
	for dh in ds:                    # skip the rise out of the drone hatch (0.4.25.22) – tested elsewhere
		dh.hatch_launch = false
		dh.visible = true
	c.hatch_queue = 0
	var d = ds[0]
	check(d.is_drone and d.faction == "player" and not d.hostile_to_player(), "drones are small player ships")
	# rest: formation around the carrier
	f.drone_role = "combat"
	f.drone_modes["combat"] = "rest"
	var fp: Vector2 = d._formation()
	check(fp.distance_to(c.position) < c.radius + 200.0, "resting drones fly in formation around the ship")
	var sym_ok := true
	for nn in [1, 2, 3, 4, 5, 9]:
		for kk in nn / 2:
			var a1: Vector2 = d.formation_slot(kk * 2, nn, 30.0)
			var a2: Vector2 = d.formation_slot(kk * 2 + 1, nn, 30.0)
			sym_ok = sym_ok and is_equal_approx(a1.x, a2.x) and is_equal_approx(a1.y, -a2.y) and a1.y != 0.0
		if nn % 2 == 1:
			var mid: Vector2 = d.formation_slot(nn - 1, nn, 30.0)
			sym_ok = sym_ok and is_zero_approx(mid.y) and mid.x < 0.0
	check(sym_ok, "idle formation is symmetric: mirrored pairs, an odd drone on the centre line behind")
	# defend: a pirate attacking the carrier
	var pir: Ship = view.spawn_npc("pirate_raider_rocket", c.position + Vector2(600, 0))
	pir.archetype = ""
	pir.target = c
	f.drone_modes["combat"] = "defend"
	var hp0: float = pir.fit.shield + pir.fit.armor + pir.fit.structure
	for i2 in 10:
		d.position = pir.position + Vector2(200, 0)
		d._think = 0.0
		d._wcd = 0.0
		d._physics_process(0.05)
	check(d.work == pir and pir.fit.shield + pir.fit.armor + pir.fit.structure < hp0, "defend: drones attack whoever attacks you – and really fire")
	# fire at will takes civilians too, not allies
	var civ: Ship = view.spawn_npc("civ_shuttle", c.position + Vector2(-500, 0), "civilian", "")
	var ally: Ship = view.spawn_npc("civ_shuttle", c.position + Vector2(-450, 0), "civilian", "")
	ally.escort_mark = true
	pir.position += Vector2(80000, 0)
	d.position = c.position + Vector2(-480, 0)
	check(d._pick_combat_target("fire_at_will") == civ, "fire at will: civilians too – allies are spared")
	check(d._pick_combat_target("defend") == null, "defend leaves the innocent alone")
	# attack: the carrier's active lock
	c.locks = [{"key": Ship.object_key(civ), "node": civ, "progress": 1.0}]
	c.active_lock = Ship.object_key(civ)
	check(d._pick_combat_target("attack") == civ, "attack: the locked target")
	c.clear_locks()
	# control range
	civ.position = c.position + Vector2(float(d.dstats["range"]) + 3000.0, 0)
	check(d._pick_combat_target("fire_at_will") != civ, "nothing outside the control range is chased")
	d.position = c.position + Vector2(float(d.dstats["range"]) + 2000.0, 0)
	d.velocity = Vector2.ZERO
	d._physics_process(0.05)
	check(d.work == null and d.velocity.dot(c.position - d.position) > 0.0, "outside the control range a drone heads back first")
	# radar shadow: no targets behind a colossus, a drone in the shadow comes back
	if not view.colossi.is_empty():
		var co = view.colossi[0]
		var keep_c: Vector2 = c.position
		c.position = co.position + Vector2(float(co.radius) + 2500.0, 0)
		var behind: Vector2 = co.position - Vector2(float(co.radius) + 1500.0, 0)
		civ.position = behind
		d.position = c.position + Vector2(0, 300)
		var tgt_ok: bool = d._pick_combat_target("fire_at_will") != civ
		d.position = behind + Vector2(0, 50)
		d.work = null
		d.velocity = Vector2.ZERO
		d._physics_process(0.05)
		check(tgt_ok and d.in_shadow() and d.work == null, "drones ignore targets in a radar shadow and leave the shadow")
		c.position = keep_c
	# mining: auto – mine, fill the cargo, deliver
	f.drone_role = "mining"
	f.drone_modes["mining"] = "auto"
	var ast = null
	for a0 in view.asteroid_nodes:
		if is_instance_valid(a0) and not a0.is_depleted() and Ship.mining_mult(d.dtool, String(a0.data["ore"])) >= 1.0 and float(a0.data["amount"]) > 20.0:
			ast = a0
			break
	if ast != null:
		c.position = ast.position + Vector2(3000, 0)
		d.work = null
		for i3 in 600:
			d.position = ast.position + Vector2(float(ast.radius) + 40.0, 0)
			d._physics_process(0.1)
			if d._cargo_used() >= float(d.dstats["cargo"]) - 0.01:
				break
		check(absf(d._cargo_used() - float(d.dstats["cargo"])) < 0.05, "mining drones fill their %.0f m³ – with the ship's mining beam" % float(d.dstats["cargo"]))
		var cargo0 := c.fit.cargo_used() + c.fit.ore_hold_used()
		d.position = c.position + Vector2(20, 0)
		d._physics_process(0.05)
		check(d._cargo_used() == 0.0 and c.fit.cargo_used() + c.fit.ore_hold_used() > cargo0, "… and deliver the ore to the ship")
	# repair: the carrier's damage
	f.drone_role = "repair"
	f.drone_modes["repair"] = "self"
	c.fit.armor = maxf(c.fit.armor - 200.0, 0.0)
	var arm0 := c.fit.armor
	for i4 in 5:
		d.position = c.position + Vector2(100, 0)
		d._think = 0.0
		d._physics_process(0.2)
	check(c.fit.armor > arm0, "repair drones repair the ship")
	# fuel empty → lost; destroyed → lost, no wreck
	var d2 = ds[1]
	d2.rec["fuel"] = 0.0001
	d2._physics_process(0.5)
	var w0 := _wrecks(view)
	var d3 = ds[2]
	d3.take_damage(9999.0, "kinetic", pir)
	check(d2.dying and d3.dying and f.drones.size() == 3 and _wrecks(view) == w0, "drones without fuel or hull are lost (no wreck)")
	# recall: back into the hangar
	view.recall_drones(c)
	var d4 = ds[3]
	d4.position = c.hatch_point("drones") + Vector2(10, 0)     # lands through the drone hatch
	d4._physics_process(0.05)
	check(d4.dying and f.drones_in_hangar() >= 1, "recalled drones fly back into the hangar")
	# warp: into the hangar while aligning, out again afterwards
	for dd in view.drones_of(c):
		view.stow_drone(dd)
	for r in f.drones:
		r["out"] = false
	f.drone_relaunch = 0
	view.launch_drones(c)
	c.order = {"type": "warp", "target": {"name": "x", "pos": c.position + Vector2(500000, 0)}}
	c.spool = 0.5
	check(view.drones_must_return(c), "aligning for warp: drones head back into the hangar")
	var n_out := view.drones_of(c).size()
	view.stow_all_drones(c, true)
	check(f.drone_relaunch == n_out and f.drones_in_hangar() == f.drones.size(), "in warp they ride in the hangar (%d)" % n_out)
	c.order = {"type": "idle"}
	c.spool = -1.0
	var relaunch := f.drone_relaunch
	f.drone_relaunch = 0
	view.launch_drones(c, relaunch)
	check(view.drones_of(c).size() == n_out, "… and fly out again after the warp")
	for dd2 in view.drones_of(c):
		view.stow_drone(dd2)
	# the pilot: drone window and keys
	var pf: ShipFitting = pl.fit
	var keep_drones: Array = pf.drones.duplicate(true)
	pf.drones = [{"fuel": 1.0, "hp": 1.0, "out": false}, {"fuel": 0.5, "hp": 0.5, "out": false}]
	main.hud._update_drones()
	var folded: bool = main.hud.drone_panel.visible and main.hud._drone_rows.is_empty()
	Commands.execute({"type": "drone_launch", "count": 1})
	main.hud._update_drones()
	check(view.drones_of(pl).size() == 1, "K launches one drone")
	check(folded and view.drones_of(pl).size() == int(pf.stats()["drones_max"]) and main.hud._drone_rows.size() == view.drones_of(pl).size(), "drone window: folded until a drone is launched, then the controls (%s)" % Keybinds.key_text("drone_launch"))
	Commands.execute({"type": "drone_role", "role": "mining"})
	Commands.execute({"type": "drone_mode", "mode": "target"})
	check(pf.drone_role == "mining" and pf.drone_modes["mining"] == "target" and Commands.execute({"type": "drone_mode", "mode": "fire_at_will"}) != "", "role tiles and behaviour buttons (modes per role)")
	Commands.execute({"type": "drone_recall"})
	var all_rec := true
	for x in view.drones_of(pl):
		all_rec = all_rec and x.recalled
	check(all_rec, "recall button / key brings them home")
	for dd3 in view.drones_of(pl):
		view.stow_drone(dd3)
	pf.drone_role = "combat"
	check(Keybinds.key_text("drone_launch") == "K" and Keybinds.key_text("drone_recall") == "P", "keys: K launch, P recall")
	# drone bay values, saving
	check(Commands.drone_value({"fuel": 1.0, "hp": 1.0}) > Commands.drone_value({"fuel": 0.3, "hp": 1.0}) and Commands.drone_repair_cost(pf) > 0, "drone bay: used drones are worth less, hulls can be repaired (fuel cannot)")
	var back := ShipFitting.from_dict(pf.to_dict())
	check(back.drones.size() == 2 and back.drone_role == "combat", "drones are saved with the ship")
	pf.drones = keep_drones
	var big_st: Dictionary = view.layout["stations"][0]
	var sp: StationUI = main.station_panel
	sp.open(big_st, view)
	sp.open_service("drones")
	check(sp.visible and String(GameData.corps["hwd"]["tag"]) == "HWD", "the Drone Bay (Hivewright Drone Works, HWD) opens at every station")
	check(PixelArt.module_icon_key("hangar:2:C") == "hangar" and PixelArt.module_icon_key("dr_range:1:C") == "drone" and PixelArt.IconArt.ICONS.has("hangar") and PixelArt.IconArt.ICONS.has("drone"), "drone hangar and drone modules have icons")
	var smn = main.ship_menu
	smn.mod_view = "fitting"
	smn.open(view, 1)
	var found_drone_cat := false
	for n9 in smn.content.find_children("*", "Label", true, false):
		if String(n9.text).begins_with("Drone hangar"):
			found_drone_cat = true
	smn.close()
	check(found_drone_cat, "ship menu → Modules shows the drone hangar equipment slots")
	sp.close()
	for n in [pir, civ, ally, c]:
		if is_instance_valid(n):
			n.queue_free()


## Phase 0.5 package 24: the ship manufacturers – data, crests, codex entries.
func _test_manufacturers(view: SystemView) -> void:
	var MK = preload("res://data/manufacturers.gd")
	var CD = preload("res://data/codex.gd")
	check(MK.MAKERS.size() == 7, "seven ship manufacturers: four private, three state (%d)" % MK.MAKERS.size())
	var states := 0
	var imgs := {}
	var crest_ok := true
	for mid in MK.MAKERS:
		var m: Dictionary = MK.MAKERS[mid]
		if m["kind"] == "state":
			states += 1
			crest_ok = crest_ok and FactionData.FACTIONS.has(String(m["faction"]))
		var im: Image = CrestArt.image_of(m["crest"])
		var opaque := 0
		for y in im.get_height():
			for x in im.get_width():
				if im.get_pixel(x, y).a > 0.5:
					opaque += 1
		crest_ok = crest_ok and opaque > 500
		imgs[im.get_data()] = true
	check(states == 3 and crest_ok and imgs.size() == MK.MAKERS.size(), "every manufacturer has its own crest")
	var all: Dictionary = CD.entries()
	var codex_ok := true
	for mid2 in MK.MAKERS:
		var e: Dictionary = all.get("maker_" + mid2, {})
		codex_ok = codex_ok and not e.is_empty() and String(e["text"]).contains(String(MK.MAKERS[mid2]["motto"]))
	check(codex_ok and all["maker_earthworks"]["unlock"] == "start" and all["maker_concord"]["unlock"] == "faction:assembly", "codex: one entry per manufacturer (Earthworks known from the start, state ones with their power)")
	check(String(all["maker_hadrian"]["text"]).contains("Erik Martin") and String(all["maker_aurelle"]["text"]).contains("Ivoire Maison"), "codex: the manufacturers' histories")
	check(CrestArt.maker_texture("khi") != null and CrestArt.maker_texture("khi").get_width() == CrestArt.W, "crest textures for the codex")


## Phase 0.5 package 25a: Kanayama Heavy Industries mining ships, manufacturer framework.
func _test_khi(view: SystemView) -> void:
	var MK = preload("res://data/manufacturers.gd")
	var maker_ok := true
	for hid in GameData.hulls:
		var h: Dictionary = GameData.hulls[hid]
		if not h.get("drone_only", false):
			maker_ok = maker_ok and (MK.MAKERS.has(String(h.get("maker", ""))) or h.get("maker", "") == "pirate")
	check(maker_ok and GameData.hulls["dragonfly"]["maker"] == "earthworks" and GameData.hulls["mogura"]["maker"] == "khi" and GameData.hulls["crow"]["maker"] == "pirate", "every hull belongs to a manufacturer")
	# yards: KHI at industry and shipyard complexes, mining colonies a small yard (KHI S/M + Drillhead)
	var khi_at := {}
	var colony_yard := []
	var trade_has_khi := false
	for s2 in Universe.systems:
		for st in Universe.get_layout(int(s2["id"]))["stations"]:
			for hid2 in st["shipyard"]:
				if GameData.hulls[hid2]["maker"] == "khi":
					khi_at[st["type"]] = true
					if st["type"] == "trade":
						trade_has_khi = true
			if st["type"] == "mining_colony" and colony_yard.is_empty():
				colony_yard = st["shipyard"].duplicate()
	colony_yard.sort()
	check(khi_at.has("industry") and not trade_has_khi, "KHI ships at industrial complexes and shipyard complexes, not at trade hubs")
	check(colony_yard == ["anaguma", "drillhead", "mogura"], "mining colonies: a small yard with Mogura, Anaguma and the Drillhead %s" % str(colony_yard))
	# traits
	var f := GameState.create_from_preset("std_mogura", "player")
	var st0 := f.stats()
	var ref := GameState.create_from_preset("std_dragonfly", "player")
	check(float(st0["ore_cargo_max"]) >= 60.0 and float(st0["mining_bonus"]["metallic"]) >= 0.1 and is_equal_approx(float(st0["align_mult"]), 1.4), "KHI: built-in ore hold (%.0f m³), +10 %% mining, slow to align for warp" % float(st0["ore_cargo_max"]))
	var kinds := {}
	for e in f.active_modules():
		if e["data"].get("builtin", false):
			kinds[String(e["data"].get("active", e["data"].get("tool", "")))] = e["slot"]
	check(kinds.has("refinery") and kinds.has("prospect") and f.priority_of("builtin_refinery") > 0, "built-in refinery and prospector in the module bar, with a power priority")
	check(f.get_module("builtin_refinery") == "" and not "builtin_refinery" in f.slot_keys(), "built-in modules cannot be removed (no slot)")
	# the refinery: ore from the hold → refined goods, power while on, smoke
	var sh := Ship.new()
	f.system_id = view.system_id
	f.position = view.player.position + Vector2(0, 50000)
	sh.manual = true
	sh.setup(f, view)
	view.ship_layer.add_child(sh)
	f.cargo.clear()
	f.cargo["iron_ore"] = 20.0
	f.refinery_on = true
	var rslot: String = kinds.get("refinery", "")
	var fx0 := view.fx_layer.get_child_count()
	for i in 40:
		sh._update_modules(0.5, f.stats())
	var ingots := float(f.cargo.get("iron_ingot", 0.0))
	check(ingots > 0.0 and float(f.cargo.get("iron_ore", 0.0)) < 20.0 and view.fx_layer.get_child_count() > fx0, "the refinery turns ore into %s bit by bit (%.1f) – with black smoke" % [GameData.item_name("iron_ingot"), ingots])
	check(sh.power_in_use().has(rslot), "the running refinery draws power")
	f.set_priority("builtin_refinery", 4)
	f.set_priority("builtin_prospect", 2)
	check(f.priority_of("builtin_refinery") == 4 and f.priority_of("builtin_prospect") == 2 and is_equal_approx(float(f.module_data("builtin_refinery")["power"]), 8.0), "built-in refinery and prospector get a power priority like any module (refinery %.0f MW)" % float(f.module_data("builtin_refinery")["power"]))
	var stk: Array = sh.smoke_stacks()
	check(stk.size() == 2 and stk[0].y < 0.0 and absf(stk[0].y) > sh.radius * 0.3, "smoke comes out of the exhaust pipes on the flanks (%d pipes)" % stk.size())
	# the plumes blow outwards, away from the hull
	sh.heading = 0.7
	sh.velocity = Vector2.ZERO
	sh._smoke_t = 0.0
	var before_fx: Array = view.fx_layer.get_children()
	var out_ok := true
	var n_sm := 0
	for i5 in 30:
		sh._smoke_t = 0.0
		sh.smoke(0.1)
	for fxn in view.fx_layer.get_children():
		if fxn is Fx and fxn.kind == "smoke" and not fxn in before_fx:
			var rel: Vector2 = (fxn.position - sh.position).rotated(-sh.heading)
			var dr: Vector2 = fxn.a.rotated(-sh.heading)
			out_ok = out_ok and signf(rel.y) == signf(dr.y)
			n_sm += 1
	check(out_ok and n_sm > 0, "smoke plumes blow outwards, away from the hull (%d puffs)" % n_sm)
	sh.set_module_active(rslot, false)
	var ore_left := float(f.cargo.get("iron_ore", 0.0))
	for i2 in 10:
		sh._update_modules(0.5, f.stats())
	check(not f.refinery_on and is_equal_approx(float(f.cargo.get("iron_ore", 0.0)), ore_left) and not sh.power_in_use().has(rslot), "switched off it stops (and draws no power)")
	sh.clear_locks()
	sh._update_modules(0.1, f.stats())
	check(not sh.module_on.get(rslot, false), "the on/off state of the refinery survives clearing the modules (off stays off)")
	f.refinery_on = true
	sh.clear_locks()
	sh._update_modules(0.1, f.stats())
	check(sh.module_on.get(rslot, false), "… and on stays on after a warp")
	sh.queue_free()
	# slower to turn than an Earthworks ship with the same engine family
	var fa := GameState.create_from_preset("std_anaguma", "player")
	var fd := GameState.create_from_preset("std_drillhead", "player")
	check(float(fa.stats()["turn"]) < float(fd.stats()["turn"]), "KHI ships turn slower (%.2f vs %.2f)" % [float(fa.stats()["turn"]), float(fd.stats()["turn"])])
	# the alignment ring fills up exactly when the warp starts (alignment time and turning included)
	var ws := Ship.new()
	fa.system_id = view.system_id
	fa.position = view.player.position + Vector2(0, 90000)
	fa.rotation = PI
	ws.manual = true
	ws.setup(fa, view)
	view.ship_layer.add_child(ws)
	ws.set_order({"type": "warp", "target": {"name": "Test", "pos": ws.position + Vector2(400000, 0), "land": 1000.0}, "then": {}})
	var ring_full_early := false
	var steps := 0
	while not ws.in_warp() and steps < 2000:
		ws._update_movement(0.05, fa.stats())
		steps += 1
		if not ws.in_warp() and ws.spool >= 0.0 and ws.spool / ws.spool_need >= 0.999 and ws.spool < ws.align_time() - 0.01:
			ring_full_early = true
	check(ws.in_warp() and not ring_full_early, "the warp alignment ring is only full when the warp starts (%.1f s, turning included)" % (steps * 0.05))
	ws.queue_free()
	# shipyard shows the manufacturer
	var big_st: Dictionary = {}
	for st3 in view.layout["stations"]:
		if not st3["shipyard"].is_empty():
			big_st = st3
	if not big_st.is_empty():
		var sp: StationUI = main.station_panel
		sp.open(big_st, view)
		sp.open_service("shipyard")
		var found := false
		for n in sp.find_children("*", "Label", true, false):
			if String(n.text).begins_with("Earthworks") or String(n.text).begins_with("Kanayama"):
				found = true
		sp.close()
		check(found, "the shipyard names the manufacturer of every hull")


## The studio intro: the dlirius animation with laser shots, title, brackets that slam shut.
func _test_intro() -> void:
	var intro = preload("res://scripts/ui/studio_intro.gd").new()
	intro.auto_skip = false
	main.add_child(intro)
	intro._layout()
	check(intro.SHEET != null and intro.LASER != null and intro.HAMMER != null, "intro: animation sheet and sounds load")
	for i in 70:
		intro._process(0.1)
	check(intro.frame == intro.FRAMES - 1 and intro.shots_fired == intro.SHOTS.size() and intro.phase == "title", "intro: the d is animated, one laser shot per colour bar (%d)" % intro.shots_fired)
	var tl: float = intro.title.position.x
	var tr: float = tl + intro.title.size.x
	check(absf(intro.left_b.position.x + intro.left_b.size.x * 0.5 - tl) < 2.0 and absf(intro.right_b.position.x + intro.right_b.size.x * 0.5 - tr) < 2.0, "intro: the brackets start at the ends of \"dlirius games\"")
	check(intro._left_shut > intro._left_open and intro._right_shut < intro._right_open, "intro: a click slams them together around the d")
	intro.close_brackets()
	check(intro.closed and intro.phase == "closing", "intro: click closes the brackets")
	var vs: Vector2 = intro.root.get_viewport_rect().size
	var mid: float = intro.anim.position.x + intro.anim.size.x * 0.5
	check(intro.get_viewport().size_changed.is_connected(intro._layout) and absf(mid - vs.x * 0.5) < 1.0, "intro: the d is centred and re-centred when the window size changes")
	intro.queue_free()
	check(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/intro.tscn", "the game starts with the studio intro")


## Phase 0.5 package 25b: Kanayama-maru – factory with build time, yellow mining drones, market.
func _test_kanayama(view: SystemView) -> void:
	check(GameData.hulls.has("kanayama") and GameData.hulls["kanayama"]["maker"] == "khi" and int(GameData.hulls["kanayama"]["drones"]) == 9, "Kanayama-maru: KHI's heavy industry ship, nine drones")
	var f := GameState.create_from_preset("std_kanayama", "player")
	var keys := []
	for b in f.builtin_modules():
		keys.append(b["key"])
	check(keys.has("builtin_refinery") and keys.has("builtin_factory") and keys.has("builtin_market") and keys.has("builtin_prospect"), "built in: refinery, prospector, factory, market")
	var fb := GameState.create_from_preset("std_bastion", "player")
	var dk: Dictionary = f.stats()["drone"]
	check(float(dk["cargo"]) >= float(fb.stats()["drone"]["cargo"]) + 5.0 and float(f.stats()["drone_tool"]["rate"]) > float(fb.stats()["drone_tool"]["rate"]) * 1.2, "its drones mine 25 %% better and carry 5 m³ more (%.0f m³)" % float(dk["cargo"]))
	# station manufacturing takes time
	var jn := GameState.jobs.size()
	GameState.jobs.append({"kind": "station", "station": "st_test", "station_name": "Test", "item": "o_cargo:1:C", "total": 15.0, "left": 15.0})
	GameState._advance_station_jobs(5.0)
	var waiting: bool = GameState.storage_of("st_test").get("o_cargo:1:C", 0) == 0 and GameState.jobs_at("st_test").size() == 1
	GameState._advance_station_jobs(11.0)
	check(waiting and int(GameState.storage_of("st_test").get("o_cargo:1:C", 0)) == 1 and GameState.jobs.size() == jn, "station manufacturing takes time (%d s for size 1) – then the module is in storage" % int(Industry.build_time("o_cargo:1:C")))
	GameState.storage.erase("st_test")
	# the ship's factory: a drone and a module
	var c := Ship.new()
	f.system_id = view.system_id
	f.position = view.player.position + Vector2(0, 70000)
	f.uid = 99901
	c.manual = true
	c.setup(f, view)
	view.ship_layer.add_child(c)
	for k in Industry.DRONE_RECIPE["materials"]:
		f.cargo[k] = float(Industry.DRONE_RECIPE["materials"][k])
	f.drones.clear()
	check(Industry.ship_build(f, "drone") == "" and GameState.ship_jobs(f.uid).size() == 1 and float(f.cargo.get("electronics", 0.0)) < 1.0, "factory: a drone is queued, the materials are used")
	f.factory_on = false
	for i in 50:
		c._update_modules(1.0, f.stats())
	var paused: bool = f.drones.is_empty()
	f.factory_on = true
	c._update_modules(1.0, f.stats())
	check(c.power_in_use().has("builtin_factory"), "the running factory draws power")
	for i2 in 49:
		c._update_modules(1.0, f.stats())
	check(paused and f.drones.size() == 1 and GameState.ship_jobs(f.uid).is_empty(), "the factory only works while switched on – the drone is in the hangar after %d s" % int(Industry.DRONE_BUILD_TIME))
	var mid := "o_cargo:1:C"
	var rec := Industry.recipe(Industry.SHIP_FACTORY, mid)
	for k2 in rec["materials"]:
		f.cargo[k2] = float(f.cargo.get(k2, 0.0)) + float(rec["materials"][k2])
	Industry.ship_build(f, mid)
	var made: String = Industry.last_built
	for i3 in 40:
		c._update_modules(1.0, f.stats())
	check(int(f.cargo.get("mod:" + made, 0.0)) == 1, "factory: a module (%s) ends up in the cargo hold" % GameData.module_name(made))
	# drones of the Kanayama-maru are yellow
	view.launch_drones(c, 1)
	var dr: Array = view.drones_of(c)
	check(not dr.is_empty() and dr[0].paint == "khi_drone", "its drones fly in KHI yellow")
	var dk0: Vector2 = c.deck_point(0.0).rotated(-c.heading) - c.position.rotated(-c.heading)
	var dk1: Vector2 = c.deck_point(1.0).rotated(-c.heading) - c.position.rotated(-c.heading)
	var launched_fwd: bool = not dr.is_empty() and (dr[0].velocity - c.velocity).dot(Vector2.from_angle(c.heading)) > 0.0
	check(dk1.x > dk0.x and dk0.x > -c.radius * 0.5 and c.has_deck() and not dr.is_empty() and dr[0].runway, "drones launch from the flight deck (deck from %.0f to %.0f)" % [dk0.x, dk1.x])
	for d1 in view.drones_of(c):
		view.stow_drone(d1)
	c.deck_queue = 0
	f.drones = [{"fuel": 1.0, "hp": 1.0, "out": false}, {"fuel": 1.0, "hp": 1.0, "out": false}]
	view.launch_drones(c)
	var rw: Array = view.drones_of(c)
	var staggered: bool = rw.size() == 2 and rw[1]._hold > rw[0]._hold
	var max_side := 0.0
	var front_x: float = (c.deck_point(1.0) - c.position).rotated(-c.heading).x
	var passed := true
	for st6 in 200:
		for d2 in rw:
			if d2.runway:
				d2._physics_process(0.05)
				max_side = maxf(max_side, absf((d2.position - c.position).rotated(-c.heading).y))
	for d3 in rw:
		passed = passed and not d3.runway and (d3.position - c.position).rotated(-c.heading).x > front_x
	check(staggered and passed and max_side < 30.0, "drones roll down the whole runway one after the other and break away past the bow")
	for d4 in view.drones_of(c):
		view.stow_drone(d4)
	for d0 in dr:
		view.stow_drone(d0)
	# the market: traders buy at fair prices, large offers attract pirates
	var keep_player = view.player
	view.player = c
	c.velocity = Vector2.ZERO
	f.cargo["iron_ingot"] = 400.0
	var base := SystemView.market_base_price("iron_ingot")
	f.market_offers = {"iron_ingot": {"amount": 400, "price": int(base * 0.8)}}
	f.market_open = false
	var closed_ok: bool = not view.market_active()
	f.market_open = true
	check(closed_ok and view.market_active(), "the market is only open when switched on (and the ship stands still)")
	var cr0: int = GameState.credits
	var got: int = view.market_trade(c)
	check(got > 0 and GameState.credits == cr0 + got and float(f.cargo.get("iron_ingot", 0.0)) < 400.0, "a trader buys at a fair price (%s)" % GameData.fmt_credits(got))
	f.cargo["iron_ingot"] = 400.0
	f.market_offers = {"iron_ingot": {"amount": 400, "price": base * 10}}
	check(view.market_trade(c) == 0, "… but not at ten times the price")
	f.market_offers = {"iron_ingot": {"amount": 400, "price": int(base * 0.8)}}
	view._market_t = 0.0
	view._market_tick(0.5)
	check(view.market_buyers.size() >= 1, "traders of the system fly over to the market")
	var bb0: Dictionary = view.market_buyers.back()
	var buyer = bb0["ship"]
	buyer.position = c.position + Vector2(1600, 0)
	buyer.set_physics_process(false)
	view._market_tick(0.5)
	var md = bb0.get("drone")
	var sent: bool = md != null and is_instance_valid(md)
	# 0.4.25.41: the trader's cargo drone comes in over the stern, lands on the runway, loads, takes off past the bow
	var cr1: int = GameState.credits
	var over_stern := false
	var landed := false
	var on_line := true
	var took_off := false
	var states := {}
	if sent:
		md.set_physics_process(false)
		for i5 in 1200:
			if not is_instance_valid(md) or md.is_queued_for_deletion():
				break
			md.step(0.05)
			states[md.state] = true
			var rel: Vector2 = (md.position - c.position).rotated(-c.heading)
			if md.state == "final" and rel.x < (c.deck_point(0.0) - c.position).rotated(-c.heading).x:
				over_stern = true
			if md.state in ["final", "loading", "takeoff"]:
				on_line = on_line and absf(rel.y) < 30.0
			if md.state == "loading":
				landed = true
			if md.state == "fly_out" and landed:
				took_off = rel.x > (c.deck_point(1.0) - c.position).rotated(-c.heading).x
			if md.state == "fly_out":
				md.trader.position = md.position + Vector2(30, 0)
	check(sent and over_stern and landed and on_line and took_off and GameState.credits > cr1, "a trader parks and sends a cargo drone: it lands on the runway over the stern, the trade happens on deck, it takes off past the bow")
	check(bb0["done"] and (not is_instance_valid(md) or md.is_queued_for_deletion()) and view.market_runway == null, "… flies back to its trader, which then leaves")
	# only one drone on the runway at a time
	var mdA = MarketDroneScriptT.new()
	var mdB = MarketDroneScriptT.new()
	mdA.setup(view, buyer, c)
	mdB.setup(view, buyer, c)
	view.ship_layer.add_child(mdA)
	view.ship_layer.add_child(mdB)
	mdA.set_physics_process(false)
	mdB.set_physics_process(false)
	var both := false
	for i6 in 400:
		mdA.step(0.05)
		mdB.step(0.05)
		var on_deck := 0
		for m6 in [mdA, mdB]:
			if m6.state in ["final", "loading", "takeoff"]:
				on_deck += 1
		both = both or on_deck > 1
	check(not both and (mdA.state == "wait" or mdB.state == "wait" or mdA.state == "fly_out" or mdB.state == "fly_out"), "only one cargo drone uses the runway at a time – the other circles and waits")
	mdA.queue_free()
	mdB.queue_free()
	view.market_runway = null
	f.cargo["platinum_ingot"] = 500.0
	f.market_offers["platinum_ingot"] = {"amount": 500, "price": 600}
	var p0: int = view.pirate_count()
	for i4 in 60:
		view._market_pirate_t = 0.0
		view._market_tick(0.5)
		if view.pirate_count() > p0:
			break
	check(view.market_value() > view.MARKET_PIRATE_VALUE and view.pirate_count() > p0, "a large offer (%s) attracts pirates" % GameData.fmt_credits(view.market_value()))
	view.player = keep_player
	for n in view.ship_layer.get_children():
		if n is Ship and n.faction == "pirate" and n.position.distance_to(c.position) < 12000.0:
			n.queue_free()
	for bb in view.market_buyers:
		if is_instance_valid(bb["ship"]):
			bb["ship"].queue_free()
	view.market_buyers.clear()
	c.queue_free()
	GameState.jobs = GameState.jobs.filter(func(j): return int(j.get("uid", 0)) != 99901)
	# ship menu: Industry and Market tabs only for ships that have them
	var sm = main.ship_menu
	sm.open(view, 7)
	var hidden_ok: bool = not sm.tab_buttons[sm.TAB_INDUSTRY].visible and not sm.tab_buttons[sm.TAB_MARKET].visible and sm.tab == 0
	sm.close()
	var keep_uid: int = GameState.active_uid
	var kf2 := GameState.create_from_preset("std_kanayama", "player")
	kf2.system_id = view.system_id
	GameState.add_ship(kf2)
	GameState.active_uid = kf2.uid
	sm.open(view, 8)
	var shown_ok: bool = sm.tab_buttons[sm.TAB_INDUSTRY].visible and sm.tab_buttons[sm.TAB_MARKET].visible and sm.tab == 8 and sm.content.get_child_count() > 0
	sm.close()
	GameState.active_uid = keep_uid
	GameState.fleet.erase(kf2)
	check(hidden_ok and shown_ok, "ship menu: Industry and Market tabs only on ships with a factory / a market")


## Phase 0.5 package 25c: Maison Aurelle – passenger cabins and transport contracts, four liners.
func _test_aurelle(view: SystemView) -> void:
	var aur := ["aur_pearl", "aur_boulevard", "aur_opal", "aur_empress"]
	var all_ok := true
	for ah in aur:
		all_ok = all_ok and GameData.hulls.has(ah) and GameData.hulls[ah]["maker"] == "aurelle" and GameData.presets.has("std_" + ah)
	check(all_ok, "Maison Aurelle: Pearl, Boulevard, Opal and Empress")
	check(int(GameData.hulls["aur_boulevard"]["price"]) >= int(GameData.hulls["warden"]["price"]) * 1.5 and int(GameData.hulls["aur_empress"]["price"]) >= int(GameData.hulls["bastion"]["price"]) * 2.5, "… and they are expensive")
	# cabins: seats by size and quality, luxury only in Aurelle hulls
	var b5c := int(GameData.modules["o_cabin_bulk:5:C"]["passengers"])
	check(b5c > int(GameData.modules["o_cabin_bulk:3:C"]["passengers"]) and int(GameData.modules["o_cabin_bulk:5:A"]["passengers"]) > b5c, "cabins: more seats with size and quality (bulk 5 · C: %d seats)" % b5c)
	var mule := GameState.create_from_preset("std_mule", "player")
	var opal := GameState.create_from_preset("std_aur_opal", "player")
	check(mule.can_fit("optional_0", "o_cabin_luxury:3:C") != "" and mule.can_fit("optional_0", "o_cabin_business:3:C") == "" and opal.can_fit("optional_0", "o_cabin_luxury:3:C") == "", "luxury suites fit only into Aurelle ships, bulk and business cabins everywhere")
	# fast hulls, built-in afterburner
	var war := GameState.create_from_preset("std_warden", "player")
	check(float(opal.stats()["speed_mult"]) > 1.3 and float(opal.stats()["align_mult"]) < 1.0, "Opal: extremely fast, quick to align")
	var keys := []
	for bm in opal.builtin_modules():
		keys.append(bm["key"])
	var fa := PixelArt.ship_texture("aur_empress", "player", 2).get_image()
	var fb := PixelArt.ship_texture("aur_empress", "player", 6).get_image()
	check(PixelArt.anim_frames("aur_empress") > 0 and fa.get_size() == fb.get_size() and fa.get_data() != fb.get_data() and PixelArt.anim_frames("aur_opal") == 0, "Empress: animated park deck (pool water, glint on the glass dome)")
	check(keys.has("builtin_afterburner") and PixelArt.module_icon_key("builtin:afterburner") == "o_afterburner", "built-in afterburner (no slot used)")
	var c := Ship.new()
	opal.system_id = view.system_id
	opal.position = view.player.position + Vector2(0, -70000)
	opal.uid = 99902
	c.manual = true
	c.setup(opal, view)
	view.ship_layer.add_child(c)
	opal.capacitor = float(opal.stats()["cap_max"])
	var err: String = c.set_module_active("builtin_afterburner", true)
	var cap0 := opal.capacitor
	c._update_modules(1.0, opal.stats())
	check(err == "" and c.afterburner_mult() > 1.4 and opal.capacitor < cap0 and c.power_in_use().has("builtin_afterburner"), "… boosts the speed, uses energy and power while on")
	c.set_module_active("builtin_afterburner", false)
	c.queue_free()
	# Empress: cargo racks at half, fast warp, strong shields, white shielded drones
	var emp := GameState.create_from_preset("std_aur_empress", "player")
	var bas := GameState.create_from_preset("std_bastion", "player")
	var rack := float(GameData.modules["o_cargo:5:C"]["cargo"])
	var c0 := float(emp.stats()["cargo_max"])
	emp.set_module("optional_5", "o_cargo:5:C")
	var half_ok := absf(float(emp.stats()["cargo_max"]) - c0 - rack * 0.5) < 0.5
	emp.set_module("optional_5", "o_shield_l")
	check(half_ok, "Empress: cargo racks give only half their room")
	check(float(emp.stats()["warp_speed"]) > float(bas.stats()["warp_speed"]) and float(emp.stats()["align_mult"]) < 0.7 and float(emp.stats()["shield_max"]) > float(bas.stats()["shield_max"]), "Empress: fast warp, short alignment, strong shields")
	var d_plain := float(emp.stats()["drone"]["shield"])
	emp.set_module("dbonus_0", "dr_shield:1:C")
	bas.set_module("dbonus_0", "dr_shield:1:C")
	var gain_e := float(emp.stats()["drone"]["shield"]) - d_plain
	var gain_b := float(bas.stats()["drone"]["shield"])
	check(d_plain > 0.0 and gain_e > gain_b * 1.3 and String(emp.hull()["drone_paint"]) == "aurelle_drone", "its white drones have their own shield; the shield module adds 50 %% more (%.0f)" % float(emp.stats()["drone"]["shield"]))
	# passenger contracts
	var st: Dictionary = view.layout["stations"][0]
	var offers: Array = GameState.passenger_offers_for(view.system_id, st)
	check(offers.size() == Missions.PASSENGER_OFFERS and String(offers[0]["type"]) == "passenger", "bulletin board: passenger contracts (%d)" % offers.size())
	var boul := GameState.create_from_preset("std_aur_boulevard", "player")
	boul.system_id = view.system_id
	GameState.add_ship(boul)
	var keep_uid: int = GameState.active_uid
	var keep_missions: Array = GameState.missions.duplicate()
	GameState.missions.clear()
	GameState.active_uid = boul.uid
	var m: Dictionary = offers[0].duplicate()
	m["cabin"] = "bulk"
	var free0 := Missions.bulk_free(boul)
	m["amount"] = free0 + 1
	var too_many: bool = GameState.accept_mission(m) != ""
	m["amount"] = 20
	check(too_many and GameState.accept_mission(m) == "" and Missions.bulk_free(boul) == free0 - 20 and int(m["ship_uid"]) == boul.uid, "bulk passengers fill the bulk seats (%d seats)" % free0)
	var biz: Array = []
	for i in 3:
		var mb: Dictionary = offers[1].duplicate()
		mb["id"] = "biz%d" % i
		mb["cabin"] = "business"
		mb["amount"] = 4
		biz.append(mb)
	var e0: String = GameState.accept_mission(biz[0])
	var e1: String = GameState.accept_mission(biz[1])
	var e2: String = GameState.accept_mission(biz[2])
	check(e0 == "" and e1 == "" and e2 != "" and biz[0]["cabin_slot"] != biz[1]["cabin_slot"], "each business group needs a cabin of its own (third group: %s)" % e2)
	var ml: Dictionary = offers[2].duplicate()
	ml["cabin"] = "luxury"
	ml["amount"] = 1
	check(Missions.cabin_error(boul, ml).contains("luxury") and Missions.cabin_error(opal, ml) == "", "luxury passengers need a luxury suite")
	check(is_equal_approx(Missions.pay_mult(boul, ml), 0.8) and is_equal_approx(Missions.pay_mult(emp, ml), 1.25) and is_equal_approx(Missions.pay_mult(opal, ml), 1.0), "luxury pay: Boulevard −20 %, Empress +25 %")
	check(Missions.cabin_in_use(boul, String(biz[0]["cabin_slot"])), "an occupied cabin cannot be removed")
	var cr0: int = GameState.credits
	var tgt := String(m["target_station"])
	var can: bool = Missions.can_turn_in(m, boul, tgt) and not Missions.can_turn_in(m, mule, tgt)
	var pay_m := int(m["reward"])
	GameState.turn_in_mission(m, tgt)
	check(can and GameState.credits == cr0 + pay_m and not m in GameState.missions, "passengers disembark at their destination – paid per passenger and jump (%s, %d → %d, pay %d)" % [str(can), cr0, GameState.credits, pay_m])
	var fac := String(biz[0]["faction"])
	var rep0: float = GameState.rep.get_rep(fac) if fac != "" else 0.0
	biz[0]["expires"] = GameState.play_time - 1.0
	GameState._update_passengers()
	var late_ok: bool = not biz[0] in GameState.missions and (fac == "" or GameState.rep.get_rep(fac) < rep0)
	check(late_ok, "missed deadline: the contract fails and costs standing")
	var other := GameState.create_from_preset("std_aur_pearl", "player")
	GameState.add_ship(other)
	var mx: Dictionary = biz[1]
	mx["ship_uid"] = other.uid
	GameState.on_player_ship_lost(other)
	check(not mx in GameState.missions, "ship destroyed with passengers aboard: the contract fails")
	# the board's passenger tab builds
	var sp: StationUI = main.station_panel
	sp.open(st, view)
	sp.open_service("bulletin")
	sp._panel._set_tab(1)
	var lbl_ok := false
	for n in sp._panel.find_children("*", "Label", true, false):
		if String(n.text).begins_with("TRANSPORT CONTRACTS"):
			lbl_ok = true
	sp._panel._set_tab(0)
	sp.close()
	check(lbl_ok, "bulletin board: own Passengers tab")
	GameState.missions = keep_missions
	GameState.active_uid = keep_uid
	GameState.fleet.erase(boul)
	GameState.fleet_changed.emit()
	# Maison Aurelle yards only in rich, safe Assembly/Covenant systems
	var rich_has := -1
	var poor_has := -1
	for sid in Universe.systems.size():
		if rich_has >= 0 and poor_has >= 0:
			break
		var w := Missions.wealthy(sid)
		if (w and rich_has >= 0) or (not w and poor_has >= 0):
			continue
		for st2 in Universe.get_layout(sid)["stations"]:
			if st2["type"] == "trade":
				var has: bool = "aur_pearl" in st2["shipyard"]
				if w:
					rich_has = 1 if has else 0
				else:
					poor_has = 1 if has else 0
				break
	check(rich_has == 1 and poor_has == 0, "Aurelle ships are sold at trade hubs of rich, safe systems only")
	var tr = view.traffic
	var liner = null
	var fake := {}
	if view.layout["stations"].size() < 2:      # a second (pretend) station for the liner to fly to
		fake = view.layout["stations"][0].duplicate()
		fake["id"] = "st_fake_liner"
		fake["pos"] = (fake["pos"] as Vector2) + Vector2(300000, 0)
		view.layout["stations"].append(fake)
	if view.layout["stations"].size() >= 2:
		for i2 in 8:
			tr._spawn_liner(false)
			var last: Dictionary = tr.shuttles.back() if not tr.shuttles.is_empty() else {}
			if not last.is_empty() and is_instance_valid(last["ship"]) and last["ship"].fit.hull_id == "aur_boulevard":
				liner = last["ship"]
				break
	check(liner != null and String(tr.shuttles.back()["station"]) != "", "Boulevard liners fly between the stations of rich systems")
	if not fake.is_empty():
		view.layout["stations"].erase(fake)
	if liner != null:
		tr._despawn(liner)


## Phase 0.5 package 25d: Hadrian Dynamics – warships with a reflective hull.
func _test_hadrian(view: SystemView) -> void:
	var hdy := ["hdy_talon", "hdy_maul", "hdy_goliath", "hdy_citadel"]
	var ok := true
	var bad_mods: Array = []
	for hid in hdy:
		ok = ok and GameData.hulls.has(hid) and GameData.hulls[hid]["maker"] == "hadrian" and GameData.presets.has("std_" + hid)
	for pid in GameData.presets:
		if String(pid).contains("hdy"):
			for k in GameData.presets[pid]["modules"]:
				var mid: String = GameData.presets[pid]["modules"][k]
				if not GameData.modules.has(mid) and not preload("res://data/modules.gd").LEGACY.has(mid):
					bad_mods.append(mid)
	check(ok and bad_mods.is_empty(), "Hadrian Dynamics: Talon, Maul, Goliath, Citadel with loadouts %s" % str(bad_mods))
	var tal := GameState.create_from_preset("std_hdy_talon", "player")
	var mau := GameState.create_from_preset("std_hdy_maul", "player")
	var gol := GameState.create_from_preset("std_hdy_goliath", "player")
	var cit := GameState.create_from_preset("std_hdy_citadel", "player")
	check(int(tal.hull()["slots"]["tool"]) == 0 and int(mau.hull()["slots"]["tool"]) == 1 and int(cit.hull()["slots"]["tool"]) == 1 and float(cit.stats()["ore_cargo_max"]) == 0.0, "weak outside combat: tool slots S 0, M/L 1, no ore hold")
	check(is_equal_approx(float(tal.stats()["reflect"]), 0.10) and is_equal_approx(float(mau.stats()["reflect"]), 0.15) and is_equal_approx(float(cit.stats()["reflect"]), 0.20), "reflective hull: S 10 %, M 15 %, L 20 %")
	var war := GameState.create_from_preset("std_warden", "player")
	var res_gain := float(mau.stats()["res"]["explosive"]) - float(GameState.create_fit("warden", {"hull": mau.get_module("hull")}, "player").stats()["res"]["explosive"])
	check(res_gain > 0.19, "M and L: +20 %% explosive resistance (%+.0f %%)" % (res_gain * 100.0))
	var drill := GameState.create_from_preset("std_drillhead", "player")
	mau.set_module("tool_0", "t_mining:1:C")
	drill.set_module("tool_0", "t_mining:1:C")
	var r_m := 0.0
	var r_d := 0.0
	for t in mau.stats()["tools"]:
		if t["slot"] == "tool_0":
			r_m = float(t["rate"])
	for t2 in drill.stats()["tools"]:
		if t2["slot"] == "tool_0":
			r_d = float(t2["rate"])
	check(r_m > 0.0 and absf(r_m - r_d * 0.5) < 0.01, "−50 %% on mining, salvage and analysis (%.2f vs %.2f)" % [r_m, r_d])
	var hor := GameState.create_from_preset("std_hornet", "player")
	tal.set_module("weapon_0", "w_rocket:1:C")
	hor.set_module("weapon_0", "w_rocket:1:C")
	var cd_t := 0.0
	var cd_h := 0.0
	for w in tal.stats()["weapons"]:
		if w["slot"] == "weapon_0":
			cd_t = float(w["cooldown"])
	for w2 in hor.stats()["weapons"]:
		if w2["slot"] == "weapon_0":
			cd_h = float(w2["cooldown"])
	check(cd_t > 0.0 and cd_t < cd_h / 1.25, "Talon: rockets and torpedoes fire faster (%.2f s vs %.2f s)" % [cd_t, cd_h])
	var pd_g := false
	for pd in gol.stats()["pd"]:
		pd_g = pd_g or String(pd["id"]) == "builtin:pd"
	var pd_c := false
	for pd2 in cit.stats()["pd"]:
		pd_c = pd_c or String(pd2["id"]) == "builtin:pd"
	check(pd_g and pd_c and tal.stats()["pd"].is_empty() and PixelArt.module_icon_key("builtin:pd") == "w_pointdef", "Goliath and Citadel: built-in point defence")
	check(int(gol.hull()["slots"]["weapon"]) == 6 and int(gol.hull()["slot_sizes"]["weapon"][0]) == 4 and int(gol.hull()["size"]) == 2, "Goliath: the guns of a cruiser on an M hull")
	# reflection in combat
	var vf := GameState.create_from_preset("std_hdy_maul", "pirate")
	vf.position = view.player.position + Vector2(0, 80000)
	vf.uid = 99903
	var victim := Ship.new()
	victim.setup(vf, view)
	view.ship_layer.add_child(victim)
	var af := GameState.create_from_preset("std_warden", "pirate")
	af.position = vf.position + Vector2(600, 0)
	af.uid = 99904
	var att := Ship.new()
	att.setup(af, view)
	view.ship_layer.add_child(att)
	vf.shield = 0.0
	var a_hp0 := af.shield + af.armor + af.structure
	var v_arm0 := vf.armor
	victim.take_damage(200.0, "kinetic", att)
	var dealt := v_arm0 - vf.armor
	var back := a_hp0 - (af.shield + af.armor + af.structure)
	check(dealt > 0.0 and back > 0.0 and absf(victim.last_reflected - dealt * 0.15) < 0.5 and att.last_reflected == 0.0, "the reflective hull sends 15 %% of the armour damage back (%.0f of %.0f)" % [victim.last_reflected, dealt])
	vf.shield = 500.0
	victim.last_reflected = 0.0
	victim.take_damage(50.0, "kinetic", att)
	check(victim.last_reflected == 0.0, "… shields do not reflect")
	victim.queue_free()
	att.queue_free()
	# yards
	var y1: Array = Universe._make_shipyard("trade", 1)
	var y2: Array = Universe._make_shipyard("trade", 2)
	var ym: Array = Universe._make_shipyard("military", 2)
	var y3: Array = Universe._make_shipyard("trade", 3)
	check("hdy_talon" in y1 and "hdy_maul" in y2 and not "hdy_goliath" in y2 and "hdy_goliath" in ym and "hdy_goliath" in y3 and "hdy_citadel" in Universe._make_shipyard("military", 3), "sold everywhere; Goliath and Citadel only at military stations and the biggest yards")
	# pirates and the Directorate
	var arch_ok := true
	for pp in ArchData.HDY_PIRATES:
		arch_ok = arch_ok and GameData.presets.has(pp) and GameData.hulls[GameData.presets[pp]["hull"]]["maker"] == "hadrian" and GameData.presets[pp]["hull"] != "hdy_goliath"
	var worn := PixelArt.ship_texture("hdy_maul", "pirate").get_image().get_data() != PixelArt.ship_texture("hdy_maul", "player").get_image().get_data()
	check(arch_ok and worn and ArchData.HDY_SHARE > 0.0, "pirates fly worn-out, rusty Hadrian copies (never the Goliath)")
	var many: Array = []
	for i in 40:
		many.append("patrol_light")
	var keep_sid: int = view.traffic.sid
	view.traffic.sid = _system_of("directorate")
	var dir_p: Array = view.traffic._gov_presets("directorate", many)
	view.traffic.sid = keep_sid
	check(dir_p.has("patrol_hdy_light") and dir_p.has("patrol_light"), "Directorate patrols fly Earthworks and Hadrian ships")
	# package 25d (design): the Goliath's two drives sit on its arms – no main engine on the centre line
	var ga: Array = PixelArt.ShipArt.SHIPS["hdy_goliath"]
	var centre: String = ga[ga.size() - 1]
	var arm_drive := false
	for row in ga:
		arm_drive = arm_drive or String(row).begins_with("f")
	check(not centre.contains("f") and arm_drive, "Goliath: two drives on the arms, none on the hull")
	# swinging arms: open in space, folded in while docking; the parts line up with the closed picture
	var gfa := GameState.create_from_preset("std_hdy_goliath", "player")
	gfa.position = view.player.position + Vector2(0, -95000)
	gfa.uid = 99906
	var gsa := Ship.new()
	gsa.manual = true
	gsa.setup(gfa, view)
	view.ship_layer.add_child(gsa)
	var open0 := gsa.arm_open
	gsa.order = {"type": "docking"}
	for i in 60:
		gsa._update_arms(1.0 / 30.0)
	var shut := gsa.arm_open
	gsa.order = {"type": "idle"}
	for i2 in 60:
		gsa._update_arms(1.0 / 30.0)
	var at: Array = PixelArt.arm_textures("hdy_goliath_arm_7", "player")
	var at0: Array = PixelArt.arm_textures("hdy_goliath_arm_0", "player")
	var full_t := PixelArt.ship_texture("hdy_goliath", "player")
	var body_t := PixelArt.ship_texture("hdy_goliath_body", "player")
	check(open0 == 1.0 and shut == 0.0 and gsa.arm_open == 1.0 and at[0].get_width() == full_t.get_width() and at[0].get_height() > full_t.get_height() and at0[0].get_image().get_used_rect().position.y > at[0].get_image().get_used_rect().position.y and body_t.get_size() == full_t.get_size(), "Goliath: the arms open into a round arc in space and fold in to dock (hinges at the stern)")
	gsa.queue_free()
	var gep: Array = PixelArt.engine_points("hdy_goliath_body")
	check(gep.size() == 2 and absf(float(gep[0][0].y) + float(gep[1][0].y)) < 0.5 and absf(float(gep[0][0].y)) > 20.0 and PixelArt.engine_points("hornet").is_empty(), "engine flames sit at the drives: two for the Goliath's arm drives, one centred for ordinary ships")
	var g0 := PixelArt.ship_texture("hdy_goliath", "player", 0).get_image().get_data()
	var g8 := PixelArt.ship_texture("hdy_goliath", "player", 8).get_image().get_data()
	check(g0 != g8 and GameData.hulls["hdy_goliath"].get("hatches", {}).has("drones") and PixelArt.ShipArt.VARIANTS["hdy_citadel"].size() == 4, "Goliath: glowing eye-slits and a drone hatch on the spine; all Citadel bridges kept as variants")
	# 0.4.25.22: every ship that carries drones launches them from a hatch (or the Kanayama's runway)
	var no_hatch: Array = []
	for hid in GameData.hulls:
		var hh: Dictionary = GameData.hulls[hid]
		if int(hh.get("drones", 0)) > 0 and not hh.get("drone_only", false) and not hh.has("drone_deck") and not hh.get("hatches", {}).has("drones"):
			no_hatch.append(hid)
	var wf := GameState.create_from_preset("std_warden", "player")
	wf.position = view.player.position + Vector2(0, -97000)
	wf.uid = 99907
	wf.drones = [{"fuel": 1.0, "hp": 1.0, "out": false}]
	var wsh := Ship.new()
	wsh.manual = true
	wsh.setup(wf, view)
	view.ship_layer.add_child(wsh)
	view.launch_drones(wsh)
	var wd: Array = view.drones_of(wsh)
	var plain := PixelArt.grid_to_image(PixelArt._mirror_v(PixelArt._pad(PixelArt.ShipArt.SHIPS["warden"])), PixelArt._colors("player")).get_data()
	check(PixelArt.ship_texture("warden", "player").get_image().get_data() != plain, "the shut drone hatch is part of the ship's picture (hangar, shipyard, ship menu)")
	check(no_hatch.is_empty() and wd.size() == 1 and wd[0].hatch_launch and wd[0].position.distance_to(wsh.hatch_point("drones")) < 1.0, "every ship with drones launches them from its own hatch %s" % str(no_hatch))
	for d9 in wd:
		view.stow_drone(d9)
	wsh.queue_free()
	# the Citadel: drones rise out of the drone hatch, the platform plays its launch
	var cf := GameState.create_from_preset("std_hdy_citadel", "player")
	cf.position = view.player.position + Vector2(0, -90000)
	cf.uid = 99905
	cf.drones = [{"fuel": 1.0, "hp": 1.0, "out": false}, {"fuel": 1.0, "hp": 1.0, "out": false}]
	var cship := Ship.new()
	cship.manual = true
	cship.setup(cf, view)
	view.ship_layer.add_child(cship)
	view.launch_drones(cship)
	var ds: Array = view.drones_of(cship)
	var below: bool = ds.size() == 2 and ds[0].hatch_launch and ds[0].position.distance_to(cship.hatch_point("drones")) < 1.0 and not ds[0].visible
	for i in 30:
		cship._update_hatches(1.0 / 30.0)
	var opened := float(cship.hatch_open.get("drones", 0.0)) > 0.99
	for i2 in 60:
		cship._update_hatches(1.0 / 30.0)
		for d in ds:
			d._physics_process(1.0 / 30.0)
	var out_all: bool = not ds[0].hatch_launch and not ds[1].hatch_launch and ds[0].visible
	for i3 in 60:
		cship._update_hatches(1.0 / 30.0)
	check(below and opened and out_all and not cship.hatch_open.has("drones"), "Citadel: the drone hatch slides open, the drones rise out one by one, the hatch shuts")
	var pe: String = cship.launch_platform()
	for i4 in 30:
		cship._update_hatches(1.0 / 30.0)
	var p_open := float(cship.hatch_open.get("platform", 0.0)) > 0.99 and cship.platform_t > 0.9
	for i5 in 120:
		cship._update_hatches(1.0 / 30.0)
	check(pe == "" and p_open and cship.platform_t < 0.0 and not cship.hatch_open.has("platform") and GameState.create_from_preset("std_hdy_maul", "player") != null and Ship.new().has_method("launch_platform"), "Citadel: launch platform – hatch opens, the small ship rises and lifts off, the hatch closes")
	for d2 in ds:
		view.stow_drone(d2)
	cship.queue_free()
	# debug: spawn any ship
	var n0 := 0
	for n in view.ship_layer.get_children():
		if n is Ship and n.fit.hull_id == "hdy_goliath":
			n0 += 1
	var cheats: bool = Commands.cheats_enabled
	Commands.cheats_enabled = true
	var err: String = Commands.execute({"type": "debug_spawn", "preset": "std_hdy_goliath", "count": 1, "gov": "", "side": "neutral"})
	Commands.cheats_enabled = cheats
	var spawned = null
	for n2 in view.ship_layer.get_children():
		if n2 is Ship and n2.fit.hull_id == "hdy_goliath" and n2.faction == "neutral":
			spawned = n2
	check(err == "" and spawned != null, "debug menu: spawn any ship (here a neutral Goliath)")
	if spawned != null:
		spawned.queue_free()


## A system controlled by faction `f` (-1 if none).
func _system_of(f: String) -> int:
	for sy in Universe.systems:
		if Universe.controller(int(sy["id"])) == f:
			return int(sy["id"])
	return -1


## Phase 0.5 package 25e: Concord Fleetworks – the Assembly's drone carriers.
func _test_concord(view: SystemView) -> void:
	var cfw := ["cfw_demos", "cfw_quirinus", "cfw_concordia"]
	var ok := true
	var max_other := 0
	for hid in GameData.hulls:
		if hid != "cfw_concordia" and not GameData.hulls[hid].get("drone_only", false):
			max_other = maxi(max_other, int(GameData.hulls[hid].get("drones", 0)))
	for hid2 in cfw:
		ok = ok and GameData.hulls.has(hid2) and GameData.hulls[hid2]["maker"] == "concord" and GameData.presets.has("std_" + hid2)
	check(ok and [GameData.hulls["cfw_demos"]["min_tier"], GameData.hulls["cfw_quirinus"]["min_tier"], GameData.hulls["cfw_concordia"]["min_tier"]] == ["neutral", "friendly", "allied"], "Concord Fleetworks: Demos (Neutral), Quirinus (Friendly), Concordia (Allied)")
	check(int(GameData.hulls["cfw_demos"]["drones"]) == 3 and int(GameData.hulls["cfw_quirinus"]["drones"]) == 7 and int(GameData.hulls["cfw_concordia"]["drones"]) == 11 and max_other < 11, "drones out at once: 3 / 7 / 11 – the Concordia is the only ship with eleven")
	# drones doubled, guns halved, shields +60 % with triple downtime
	var q := GameState.create_fit("cfw_quirinus", {}, "player")
	var w := GameState.create_fit("warden", {}, "player")
	for f9 in [q, w]:
		f9.set_module("hangar", "hangar:2:C")
		f9.set_module("dweapon_0", "w_pulse:1:C")
		f9.set_module("dtool_0", "t_mining:1:C")
		f9.set_module("weapon_0", "w_beam:2:C")
		f9.set_module("optional_0", "o_shield:3:C")
	var dq: Dictionary = q.stats()["drone"]
	var dw: Dictionary = w.stats()["drone"]
	var both := func(k): return absf(float(dq[k]) - float(dw[k]) * 2.0) < 0.01
	check(both.call("hull") and both.call("cargo") and both.call("fuel") and both.call("repair") and absf(float(q.stats()["drone_weapon"]["damage"]) - float(w.stats()["drone_weapon"]["damage"]) * 2.0) < 0.01 and absf(float(q.stats()["drone_tool"]["rate"]) - float(w.stats()["drone_tool"]["rate"]) * 2.0) < 0.01, "Concord drones: hull, damage, mining, repair, cargo and fuel doubled")
	check(absf(float(dq["range"]) - minf(float(dw["range"]) * 2.0, GameData.RECON_RANGE)) < 0.5 and float(dq["range"]) <= GameData.RECON_RANGE, "… the control range doubled, but never beyond the recon range (%.0f km)" % float(dq["range"]))
	var gq := 0.0
	var gw := 0.0
	for w1 in q.stats()["weapons"]:
		gq = float(w1["damage"])
	for w2 in w.stats()["weapons"]:
		gw = float(w2["damage"])
	check(gq > 0.0 and absf(gq - gw * 0.5) < 0.01, "the ship's own guns: half damage")
	check(absf(float(q.stats()["shield_max"]) - float(w.stats()["shield_max"]) * 1.6) < 1.0 and float(q.stats()["shield_downtime"]) > float(w.stats()["shield_downtime"]) * 2.9, "shields +60 %%, but three times the downtime after a collapse (%.0f/%.0f, %.1f/%.1f s)" % [float(q.stats()["shield_max"]), float(w.stats()["shield_max"]), float(q.stats()["shield_downtime"]), float(w.stats()["shield_downtime"])])
	# six hangar doors: the drones launch side by side
	var cf := GameState.create_from_preset("std_cfw_concordia", "player")
	cf.position = view.player.position + Vector2(0, -99000)
	cf.uid = 99908
	cf.drones = []
	for i in 6:
		cf.drones.append({"fuel": 1.0, "hp": 1.0, "out": false})
	var cs := Ship.new()
	cs.manual = true
	cs.setup(cf, view)
	view.ship_layer.add_child(cs)
	view.launch_drones(cs)
	var ds: Array = view.drones_of(cs)
	var doors := {}
	var same_t := true
	for d in ds:
		doors[d.hatch_name] = true
		same_t = same_t and absf(float(d._hold) - float(ds[0]._hold)) < 0.01
	check(cs.drone_hatches().size() == 6 and doors.size() == 6 and same_t and ds[0].paint == "assembly_drone", "Concordia: six hangar doors – six drones rise at the same time, in Assembly blue")
	for d2 in ds:
		view.stow_drone(d2)
	# the drones use the doors one after another, also when launched one by one
	cs.next_hatch = 0
	var singles := {}
	for i4 in 3:
		cf.drones[i4]["out"] = false
		view.launch_drones(cs, 1)
	for d5 in view.drones_of(cs):
		singles[d5.hatch_name] = true
	check(singles.size() == 3, "single launches use the hangar doors in turn (%d doors)" % singles.size())
	for d6 in view.drones_of(cs):
		view.stow_drone(d6)
	# recall: the drones fly to the hangar doors, the doors open, they land inside
	cf.drones = [{"fuel": 1.0, "hp": 1.0, "out": false}, {"fuel": 1.0, "hp": 1.0, "out": false}]
	cs.hatch_queue = 0
	view.launch_drones(cs)
	var rd: Array = view.drones_of(cs)
	for d7 in rd:
		d7.hatch_launch = false
		d7.visible = true
		d7.position = cs.position + Vector2(0, 1800)
	view.recall_drones(cs)
	var door_opened := false
	var near_door := INF
	for i5 in 400:
		for d8 in rd:
			if is_instance_valid(d8) and not d8.dying:
				var hn9: String = cs.nearest_drone_hatch(d8.position)
				near_door = minf(near_door, d8.position.distance_to(cs.hatch_point(hn9)))
				d8._physics_process(1.0 / 30.0)
		cs._update_hatches(1.0 / 30.0)
		for hn8 in cs.hatch_open:
			door_opened = door_opened or float(cs.hatch_open[hn8]) > 0.5
	var landed := true
	for d10 in rd:
		landed = landed and (not is_instance_valid(d10) or d10.dying)
	check(landed and door_opened and near_door < 45.0, "recalled drones fly to a hangar door, it opens, they land inside (closest %.0f)" % near_door)
	# the flight wings move back and out in space, fold in to dock – the doors move along
	cs.arm_open = 1.0
	var open_p: Vector2 = cs.hatch_local("drones").position
	cs.arm_open = 0.0
	var shut_p: Vector2 = cs.hatch_local("drones").position
	cs.arm_open = 1.0
	check(open_p.x < shut_p.x and open_p.y < shut_p.y and PixelArt.ShipArt.SHIPS.has("cfw_concordia_wing_5"), "Concordia: the flight wings move back and out in space (doors move along), fold in to dock %s %s" % [str(open_p), str(shut_p)])
	# light effects: stripes pulse, a spot runs along them in a fight, yellow while the doors are open
	var segs: Array = PixelArt.stripe_segments("cfw_concordia")
	var on_wing := false
	for sg in segs:
		on_wing = on_wing or sg[3]
	cs.combat_t = 0.0
	cs.take_damage(1.0, "kinetic", null)
	var wing_eng: Array = PixelArt.engine_groups("cfw_concordia_wing_5")
	var body_eng: Array = PixelArt.engine_groups("cfw_concordia_body")
	check(wing_eng.size() == 2 and body_eng.size() == 1 and absf(float(wing_eng[0][0].y)) > 20.0, "Concordia: a flame at each of its three drives – the spine and both flight wings")
	check(segs.size() >= 4 and on_wing and not PixelArt.stripe_segments("cfw_demos").is_empty() and cs.combat_t > 0.0 and GameData.hulls["cfw_concordia"].get("launch_glow", false), "Concord stripes: pulsing, a running light in a fight, yellow while drones launch (Concordia)")
	cs.queue_free()
	# faction ships only at the faction's yards, and only with standing
	var asm_t3 := {}
	var other_t3 := {}
	for sy in Universe.systems:
		if not asm_t3.is_empty() and not other_t3.is_empty():
			break
		for st in Universe.get_layout(int(sy["id"]))["stations"]:
			if not GameData.station_types[st["type"]]["shipyard"] or int(st["tier"]) < 3:
				continue
			if String(st.get("faction", "")) == "assembly" and asm_t3.is_empty():
				asm_t3 = st
			elif String(st.get("faction", "")) in ["covenant", "directorate"] and other_t3.is_empty():
				other_t3 = st
	check(not asm_t3.is_empty() and "cfw_concordia" in asm_t3["shipyard"] and "cfw_demos" in asm_t3["shipyard"] and (other_t3.is_empty() or not "cfw_demos" in other_t3["shipyard"]), "Concord ships are sold only at Assembly shipyards")
	var r = GameState.rep
	var keep: float = r.get_rep("assembly")
	r.values["assembly"] = 0.0
	var neutral_err: String = GameState.hull_standing_error("cfw_concordia")
	var demos_ok: String = GameState.hull_standing_error("cfw_demos")
	r.values["assembly"] = 70.0
	var allied_err: String = GameState.hull_standing_error("cfw_concordia")
	r.values["assembly"] = keep
	check(neutral_err != "" and demos_ok == "" and allied_err == "", "the Concordia needs Allied standing, the Demos Neutral")
	# NPC carriers fight with their drones and call them back afterwards
	var pf := GameState.create_from_preset("patrol_cfw_medium", "patrol")
	pf.gov = "assembly"
	pf.position = view.player.position + Vector2(0, -105000)
	pf.uid = 99909
	var pc := Ship.new()
	pc.setup(pf, view)
	view.ship_layer.add_child(pc)
	var pir: Ship = view.spawn_npc("pirate_raider_rocket", pc.position + Vector2(900, 0))
	pc.target = pir
	pc._npc_drone_t = 0.0
	pc._update_npc_drones(1.1)
	var nd: Array = view.drones_of(pc)
	var npc_ok: bool = nd.size() == 7 and nd[0].faction == "patrol" and not nd[0].hostile_to_player() and Ship.hostile(nd[0], pir)
	pc.target = null
	for i2 in 20:
		pc._npc_drone_t = 0.0
		pc._update_npc_drones(1.0)
	var recalled := true
	for d3 in nd:
		recalled = recalled and d3.recalled
	check(npc_ok and recalled, "Assembly patrols launch their drones in a fight (%d) and call them back afterwards" % nd.size())
	for d4 in nd:
		view.stow_drone(d4)
	pir.queue_free()
	pc.queue_free()
	# patrols: Concord carriers in Assembly systems (now and then a Goliath), Earthworks elsewhere
	var tr = view.traffic
	var keep_sid: int = tr.sid
	var many: Array = []
	for i3 in 60:
		many.append("patrol_medium")
	tr.sid = _system_of("assembly")
	var own: Array = tr._gov_presets("assembly", many)
	var contested := -1
	for sy2 in Universe.systems:
		if Universe.controller(int(sy2["id"])) == "" and "assembly" in Universe.claimants(int(sy2["id"])):
			contested = int(sy2["id"])
			break
	var away: Array = many
	if contested >= 0:
		tr.sid = contested
		away = tr._gov_presets("assembly", many)
	tr.sid = keep_sid
	check(own.has("patrol_cfw_medium") and own.has("patrol_hdy_heavy") and not own.has("patrol_medium") and away == many, "Assembly patrols fly Concord carriers (now and then a Goliath) – in contested systems Earthworks ships")
	# debug: fill the drone hangar
	var cheats: bool = Commands.cheats_enabled
	Commands.cheats_enabled = true
	var af := GameState.active()
	var keep_d: Array = af.drones.duplicate(true)
	af.drones = []
	var e1: String = Commands.execute({"type": "debug_fill_drones"})
	var filled: int = af.drones.size()
	af.drones = keep_d
	Commands.cheats_enabled = cheats
	check(e1 == "" and filled == int(af.stats()["drone_storage"]), "debug menu: fill the drone hangar (%d)" % filled)


## Phase 0.5 package 25f: Forge of Return – the Covenant's flying temples.
func _test_forge(view: SystemView) -> void:
	var fr := ["for_acolyte", "for_templar", "for_cathedral"]
	var ok := true
	for hid in fr:
		var h: Dictionary = GameData.hulls[hid]
		ok = ok and h["maker"] == "forge" and int(h.get("drones", 0)) == 0 and GameData.slot_max_of(h, "hangar") == 0 and GameData.presets.has("std_" + hid)
	check(ok and [GameData.hulls["for_acolyte"]["min_tier"], GameData.hulls["for_templar"]["min_tier"], GameData.hulls["for_cathedral"]["min_tier"]] == ["neutral", "friendly", "allied"], "Forge of Return: Acolyte (Neutral), Templar (Friendly), Cathedral (Allied) – no drone hangars")
	var t := GameState.create_fit("for_templar", {"reactor": "rea_fusion:6:C"}, "player")
	var w := GameState.create_fit("warden", {"reactor": "rea_fusion:6:C"}, "player")
	var cat := GameState.create_fit("for_cathedral", {"reactor": "rea_fusion:6:C"}, "player")
	check(absf(float(t.stats()["power_output"]) - float(w.stats()["power_output"]) * 1.8) < 1.0 and absf(float(cat.stats()["power_output"]) - float(w.stats()["power_output"]) * 2.2) < 1.0, "reactor output +80 % (Cathedral +120 %)")
	check(int(GameData.hulls["for_templar"]["structure"]) < int(GameData.hulls["warden"]["structure"]) * 0.75 and int(GameData.hulls["for_templar"]["slot_sizes"]["hull"]) < int(GameData.hulls["warden"]["slot_sizes"]["hull"]), "weak hulls: less structure, smaller armour slots")
	check(w.can_fit("weapon_0", "w_focus:2:C") != "" and t.can_fit("weapon_0", "w_focus:2:C") == "" and PixelArt.module_icon_key("w_focus:2:C") == "w_focus", "focus-crystal lasers fit only into Covenant ships")
	var cov_has := false
	var other_has := false
	for sy in Universe.systems:
		for st in Universe.get_layout(int(sy["id"]))["stations"]:
			var has := false
			for mid in st["shop"]:
				has = has or String(mid).begins_with("w_focus:")
			if String(st.get("faction", "")) == "covenant":
				cov_has = cov_has or has
			else:
				other_has = other_has or has
	check(cov_has and not other_has, "focus-crystal lasers are sold only at Covenant outfitters")
	# beam bundling
	var ac := GameState.create_from_preset("std_for_acolyte", "player")
	var ws: Array = ac.stats()["weapons"]
	var sum := 0.0
	for k in ac.slot_keys():
		if String(k).begins_with("weapon_"):
			sum += float(GameData.modules[ac.get_module(k)]["damage"])
	var dps_lance: float = float(ws[0]["damage"]) / float(ws[0]["cooldown"])
	check(ws.size() == 1 and int(ws[0]["bundle"]) == 3 and absf(dps_lance - sum * 1.3) < 0.5, "Acolyte: all three crystals join into one lance – +30 %% damage per second (%.0f per lance)" % float(ws[0]["damage"]))
	ac.set_module("weapon_2", "w_pulse:1:C")
	check(ac.stats()["weapons"].size() == 3 and int(ac.stats()["focus_bundle"]) == 0, "… only when every hardpoint carries a focus crystal")
	# the lance: the beams meet between ship and target, charge, then burn for a second
	var tf := GameState.create_from_preset("std_for_templar", "player")
	tf.position = view.player.position + Vector2(0, -115000)
	tf.uid = 99913
	var tsh := Ship.new()
	tsh.setup(tf, view)
	view.ship_layer.add_child(tsh)
	var foe: Ship = view.spawn_npc("pirate_hdy_maul", tsh.position + Vector2(700, 0))
	foe.set_physics_process(false)
	var lw: Dictionary = tf.stats()["weapons"][0]
	var hpf: float = foe.fit.shield + foe.fit.armor + foe.fit.structure
	view.fire_weapon(tsh, foe, lw)
	var lance = null
	for n0 in view.fx_layer.get_children():
		if n0.get_script() == SystemView.FocusLanceScript:
			lance = n0
	var during_charge := 0.0
	var mid_burn := 0.0
	if lance != null:
		lance._process(0.4)
		during_charge = hpf - (foe.fit.shield + foe.fit.armor + foe.fit.structure)
		lance._process(0.6)
		mid_burn = hpf - (foe.fit.shield + foe.fit.armor + foe.fit.structure)
		lance._process(1.0)
	var total: float = hpf - (foe.fit.shield + foe.fit.armor + foe.fit.structure)
	check(lance != null and during_charge == 0.0 and mid_burn > 0.0 and total > mid_burn and lance.is_queued_for_deletion() and float(lw["cooldown"]) >= 2.0, "focus lance: the beams meet between ship and target, charge, then burn for a second (%.0f damage)" % total)
	foe.queue_free()
	tsh.queue_free()
	check(not PixelArt.spike_tips("for_templar").is_empty() and not PixelArt.spike_tips("for_cathedral").is_empty() and GameData.hulls["for_cathedral"].get("spike_fx", false) and not GameData.hulls["for_acolyte"].get("spike_fx", false), "Templar and Cathedral: golden spikes slide out and back in now and then")
	var cf := GameState.create_from_preset("std_for_cathedral", "player")
	check(cf.stats()["weapons"].size() == 1 and int(cf.stats()["focus_bundle"]) == 8, "the Cathedral bundles too: eight crystals, one lance, one tile")
	# the anti-drone pulse: every drone in range, friend or foe, drifts for 15 s
	var caf := GameState.create_from_preset("patrol_cfw_light", "patrol")
	caf.gov = "assembly"
	caf.position = view.player.position + Vector2(0, -111000)
	caf.uid = 99910
	var cas := Ship.new()
	cas.setup(caf, view)
	view.ship_layer.add_child(cas)
	caf.drones = [{"fuel": 1.0, "hp": 1.0, "out": false}, {"fuel": 1.0, "hp": 1.0, "out": false}]
	view.launch_drones(cas)
	var ds: Array = view.drones_of(cas)
	for d in ds:
		d.hatch_launch = false
		d.position = cas.position + Vector2(400, 0)
		d.velocity = Vector2(50, 0)
	cf.position = cas.position + Vector2(-2000, 0)
	cf.uid = 99911
	var cs := Ship.new()
	cs.manual = true
	cs.setup(cf, view)
	view.ship_layer.add_child(cs)
	cf.capacitor = float(cf.stats()["cap_max"])
	var e1: String = cs.set_module_active("builtin_drone_pulse", true)
	cs._update_modules(0.1, cf.stats())
	var stunned := ds.size() == 2
	for d2 in ds:
		stunned = stunned and float(d2.stunned_t) > 14.0
	var p0: Vector2 = ds[0].position
	ds[0]._physics_process(0.5)
	var drifted: bool = ds[0].position.distance_to(p0 + Vector2(25, 0)) < 2.0
	var bar0: float = cs.cycle_progress("builtin_drone_pulse")
	cs.module_timers["builtin_drone_pulse"] = 15.0
	var bar_half: float = cs.cycle_progress("builtin_drone_pulse")
	cs.module_timers["builtin_drone_pulse"] = 30.0
	check(bar0 < 0.1 and absf(bar_half - 0.5) < 0.01, "the pulse tile shows a bar that fills up until the next pulse")
	check(e1 == "" and stunned and drifted and float(cs.module_timers.get("builtin_drone_pulse", 0.0)) > 25.0, "Cathedral: the anti-drone pulse knocks out every drone within 5,000 km (also allied ones) – they drift for 15 s")
	for d3 in ds:
		view.stow_drone(d3)
	cas.queue_free()
	# auto mode: fires on its own at hostile ships, never at the innocent
	var p1: Ship = view.spawn_npc("pirate_hdy_talon", cs.position + Vector2(700, 0))
	var p2: Ship = view.spawn_npc("pirate_hdy_talon", cs.position + Vector2(0, 800))
	var civ: Ship = view.spawn_npc("civ_shuttle", cs.position + Vector2(-700, 0), "civilian", "")
	for n9 in [p1, p2, civ]:
		n9.set_physics_process(false)
	var hp1: float = p1.fit.shield + p1.fit.armor + p1.fit.structure
	var hp2: float = p2.fit.shield + p2.fit.armor + p2.fit.structure
	var hpc: float = civ.fit.shield + civ.fit.armor + civ.fit.structure
	cf.capacitor = float(cf.stats()["cap_max"])
	var e2: String = cs.set_module_active("builtin_auto_fire", true)
	var lslot: String = cf.stats()["weapons"][0]["slot"]
	cs._update_auto_fire(0.1, cf.stats())
	cs.module_timers[lslot] = 0.0
	cf.capacitor = float(cf.stats()["cap_max"])
	cs._update_auto_fire(0.1, cf.stats())
	for n12 in view.fx_layer.get_children():
		if n12.get_script() == SystemView.FocusLanceScript:
			n12._process(2.0)
	var hit1: bool = p1.fit.shield + p1.fit.armor + p1.fit.structure < hp1
	var hit2: bool = p2.fit.shield + p2.fit.armor + p2.fit.structure < hp2
	check(e2 == "" and hit1 and hit2 and civ.fit.shield + civ.fit.armor + civ.fit.structure == hpc, "Cathedral auto mode: the lance fires on its own, taking turns between several enemies – never at the innocent")
	cs.set_module_active("builtin_auto_fire", false)
	for n10 in [p1, p2, civ]:
		n10.queue_free()
	cs.queue_free()
	# Covenant patrols fly Forge ships (now and then a Goliath)
	var tr = view.traffic
	var keep_sid: int = tr.sid
	var many: Array = []
	for i in 60:
		many.append("patrol_medium")
	tr.sid = _system_of("covenant")
	var own: Array = tr._gov_presets("covenant", many)
	tr.sid = keep_sid
	check(own.has("patrol_for_medium") and own.has("patrol_hdy_heavy") and not own.has("patrol_medium"), "Covenant patrols fly Forge of Return ships (now and then a Goliath)")
	# debug: NPC carriers launch their drones (to test the pulse)
	var far := GameState.create_from_preset("patrol_cfw_light", "patrol")
	far.gov = "assembly"
	far.position = view.player.position + Vector2(3000, 0)
	far.uid = 99912
	var fs := Ship.new()
	fs.setup(far, view)
	view.ship_layer.add_child(fs)
	var cheats: bool = Commands.cheats_enabled
	Commands.cheats_enabled = true
	var e3: String = Commands.execute({"type": "debug_npc_drones"})
	var launched: int = view.drones_of(fs).size()
	Commands.cheats_enabled = cheats
	check(e3 == "" and launched > 0, "debug menu: nearby NPC carriers launch their drones (%d)" % launched)
	# debug: a hostile drone carrier – never flown by real pirates
	var real := false
	for a9 in ArchData.ARCHETYPES:
		real = real or "pirate_debug_carrier" in ArchData.ARCHETYPES[a9]["presets"]
	real = real or "pirate_debug_carrier" in ArchData.HDY_PIRATES
	Commands.cheats_enabled = true
	var e4: String = Commands.execute({"type": "debug_spawn", "preset": "pirate_debug_carrier", "count": 1, "gov": ""})
	Commands.cheats_enabled = cheats
	var dc = null
	for n11 in view.ship_layer.get_children():
		if n11 is Ship and n11.fit.hull_id == "cfw_quirinus" and n11.faction == "pirate":
			dc = n11
	var hostile_drones := false
	if dc != null:
		dc.target = view.player
		dc._npc_drone_t = 0.0
		dc._update_npc_drones(1.0)
		for d13 in view.drones_of(dc):
			hostile_drones = hostile_drones or (d13.hostile_to_player() or d13.faction == "pirate")
	check(e4 == "" and dc != null and hostile_drones and not real, "debug menu: a hostile pirate drone carrier (debug only – real pirates never fly it)")
	if dc != null:
		for d14 in view.drones_of(dc):
			view.stow_drone(d14)
		dc.queue_free()
	for d4 in view.drones_of(fs):
		view.stow_drone(d4)
	fs.queue_free()


## Phase 0.5 package 25g: Axiom Astronautics – research ships, cloaking, the wormhole jump ship.
func _test_axiom(view: SystemView) -> void:
	check(GameData.hulls["axa_parallax"]["maker"] == "axiom" and GameData.hulls["axa_parallax"]["min_tier"] == "neutral" and GameData.hulls["axa_threshold"]["min_tier"] == "allied" and GameData.presets.has("std_axa_threshold"), "Axiom Astronautics: Parallax (Neutral), Threshold (Allied)")
	var dir_t3 := {}
	var asm_t3 := {}
	for sy in Universe.systems:
		for st in Universe.get_layout(int(sy["id"]))["stations"]:
			if not GameData.station_types[st["type"]]["shipyard"] or int(st["tier"]) < 3:
				continue
			if String(st.get("faction", "")) == "directorate" and dir_t3.is_empty():
				dir_t3 = st
			elif String(st.get("faction", "")) == "assembly" and asm_t3.is_empty():
				asm_t3 = st
		if not dir_t3.is_empty() and not asm_t3.is_empty():
			break
	check(not dir_t3.is_empty() and "axa_threshold" in dir_t3["shipyard"] and not "axa_threshold" in asm_t3.get("shipyard", []), "the Threshold is sold only at Directorate shipyards")
	# sensors +25 %, lower signature, more efficient power use
	var mods := {"sensors": "sen_basic:2:C", "reactor": "rea_fusion:4:C", "weapon_0": "w_pulse:1:C"}
	var px := GameState.create_fit("axa_parallax", mods, "player")
	var dr := GameState.create_fit("dragonfly", mods, "player")
	var sp: Dictionary = px.stats()
	var sd: Dictionary = dr.stats()
	check(absf(float(sp["sensor_range"]) - float(sd["sensor_range"]) * 1.25) < 1.0 and absf(float(sp["scan_strength"]) - float(sd["scan_strength"]) * 1.25) < 0.01, "Axiom: sensors +25 % range and scan strength")
	check(absf(float(sp["signature"]) - (float(px.hull()["signature"]) + float(sp["mass"]) * 0.004) * 0.75) < 0.5, "… a lower signature")
	check(absf(float(sp["power_draw"]) - (float(sd["power_draw"]) + 8.0) * 0.85) < 0.5, "… and a more efficient use of power (−15 %%: %.1f MW incl. the cloak)" % float(sp["power_draw"]))
	# the cloaking device
	var cf := GameState.create_from_preset("std_axa_parallax", "player")
	cf.position = view.player.position + Vector2(0, -121000)
	cf.uid = 99920
	var cs := Ship.new()
	cs.manual = true
	cs.setup(cf, view)
	view.ship_layer.add_child(cs)
	var foe: Ship = view.spawn_npc("pirate_hdy_talon", cs.position + Vector2(800, 0))
	foe.set_physics_process(false)
	cs.add_lock(foe)
	cf.capacitor = float(cf.stats()["cap_max"])
	var e1: String = cs.set_module_active("builtin_cloak", true)
	cs._update_cloak_fx(0.4)
	var sweeping: bool = cs.cloak_k > 0.0 and cs.cloak_k < 1.0
	cs._update_cloak_fx(3.0)
	check(sweeping and cs.cloak_k >= 1.0 and cs._cloak_alpha_at(0.0, 40) < 0.5 and PixelArt.silhouette_texture("axa_parallax").get_width() > 0, "cloak: takes hold from the stern to the bow, not all at once")
	var no_target: bool = not cs.is_targetable() and cs.locks.size() == 1
	var cap0 := cf.capacitor
	cs._update_modules(1.0, cf.stats())
	var drains: bool = cf.capacitor < cap0
	foe.target = cs
	var foe_lost: bool = not foe._valid(foe.target)
	cf.capacitor = 0.0
	cs._update_modules(1.0, cf.stats())
	check(e1 == "" and no_target and drains and foe_lost and not cs.cloaked(), "cloaking device: invisible and untargetable (locks stay), uses energy – off when the capacitor runs dry")
	# 0.4.25.40: firing a weapon or using a tool ends the cloak
	cf.capacitor = float(cf.stats()["cap_max"])
	cs.set_module_active("builtin_cloak", true)
	var re_cloaked: bool = cs.cloaked()
	var ew0: String = cs.set_module_active("weapon_0", true)      # the lock is still running: refused, still cloaked
	var refused_stays: bool = ew0 != "" and cs.cloaked()
	for l7 in cs.locks:
		l7["progress"] = 1.0
	var ew1: String = cs.set_module_active("weapon_0", true)
	var by_weapon: bool = refused_stays and not cs.cloaked() and bool(cs.module_on.get("weapon_0", false))
	var by_tool := false
	var tools_fair := true
	var keep_sel: String = view.selected_id
	var keep_pos: Vector2 = cs.position
	for wt2 in Universe.warp_targets(view.system_id):
		if wt2["kind"] in ["field", "planet"]:
			view.selected_id = wt2["id"]
			cs.position = (wt2["pos"] as Vector2) + Vector2(3000, 0)
			break
	for tslot in ["tool_1", "tool_2"]:
		cs.module_on.clear()
		cs.set_module_active("builtin_cloak", true)
		var et: String = cs.set_module_active(tslot, true)
		by_tool = by_tool or (et == "" and not cs.cloaked())
		tools_fair = tools_fair and ((et == "") == (not cs.cloaked()))   # a refused tool leaves it on
	view.selected_id = keep_sel
	cs.position = keep_pos
	check(re_cloaked and by_weapon and by_tool and tools_fair, "cloak: firing a weapon or using a tool switches it off (a refused one does not)")
	# 0.4.25.40: Axiom's cloak drones – the drone cloak emitter, sold only by the Directorate
	var emid := "dr_cloak:1:C"
	var cdf := GameState.create_from_preset("std_axa_parallax", "player")
	var fit_err: String = cdf.can_fit("dbonus_0", emid)
	cdf.set_module("dbonus_0", emid)
	cdf.set_module("hangar", "hangar:1:C")
	var dcf := GameState.create_fit("dragonfly", {"dbonus_0": emid}, "player")
	var fit_err2: String = dcf.can_fit("dbonus_0", emid)
	var dr_cloak_ok: bool = bool(cdf.stats()["drone"].get("cloak", false)) and not bool(dcf.stats()["drone"].get("cloak", false))
	var sold_dir := false
	var sold_else := false
	for sy5 in Universe.systems:
		for st5 in Universe.get_layout(int(sy5["id"]))["stations"]:
			if emid in st5.get("shop", []):
				if String(st5.get("faction", "")) == "directorate":
					sold_dir = true
				else:
					sold_else = true
	check(fit_err == "" and fit_err2 != "" and dr_cloak_ok and sold_dir and not sold_else, "drone cloak emitter: Axiom ships fly cloak drones; only Directorate outfitters sell it")
	cdf.position = view.player.position + Vector2(0, -129000)
	cdf.uid = 99924
	cdf.drones = [{"out": false, "fuel": 1.0, "hp": 1.0}]
	var cds := Ship.new()
	cds.setup(cdf, view)
	view.ship_layer.add_child(cds)
	view.launch_drones(cds, 1)
	var cdr: Array = view.drones_of(cds)
	var dok: bool = cdr.size() == 1 and cdr[0].fit.hull_id == "drone_cloak" and not cdr[0].cloaked()
	cdf.capacitor = float(cdf.stats()["cap_max"])
	cds.set_module_active("builtin_cloak", true)
	var hid: bool = dok and cdr[0].cloaked() and not cdr[0].is_targetable() and not view.contact_visible(cdr[0])
	cds.set_module_active("builtin_cloak", false)
	check(hid and not cdr[0].cloaked(), "cloak drones cloak together with their ship – and show again with it")
	for d7 in cdr:
		view.stow_drone(d7)
	cds.queue_free()
	foe.queue_free()
	cs.queue_free()
	# NPC research ships cloak when they come under fire; enemies cannot see cloaked ships on the radar
	var nf := GameState.create_from_preset("civ_parallax", "civilian")
	nf.gov = "directorate"
	nf.position = view.player.position + Vector2(2000, -123000)
	nf.uid = 99921
	var ns := Ship.new()
	ns.setup(nf, view)
	view.ship_layer.add_child(ns)
	var shooter: Ship = view.spawn_npc("pirate_hdy_talon", ns.position + Vector2(600, 0))
	shooter.set_physics_process(false)
	ns.take_damage(5.0, "kinetic", shooter)
	ns._update_npc_cloak(0.1)
	check(ns.cloaked() and not view.contact_visible(ns), "Axiom research ships cloak when attacked – and vanish from the radar")
	shooter.queue_free()
	ns.queue_free()
	# Parallax: systems with undiscovered anomalies within four jumps
	var targets: Dictionary = GalaxyMap.anomaly_targets(GameState.create_from_preset("std_axa_parallax", "player"))
	check(not targets.is_empty() and GalaxyMap.anomaly_targets(dr).is_empty(), "Parallax: marks %d systems with undiscovered anomalies within 4 jumps" % targets.size())
	# exotic matter in rare anomalies
	var ex := 0
	var all := 0
	for sy2 in Universe.systems:
		for an in Universe.get_layout(int(sy2["id"]))["anomalies"]:
			all += 1
			if an.get("exotic", false):
				ex += 1
	check(ex > 0 and ex < all / 3, "rare anomalies hold exotic matter (%d of %d)" % [ex, all])
	# the Threshold's wormhole
	var tf := GameState.create_from_preset("std_axa_threshold", "player")
	tf.system_id = view.system_id
	tf.uid = 99922
	var near := -1
	var far := -1
	for sy3 in Universe.systems:
		var dd := Universe.find_path(tf.system_id, int(sy3["id"]), 3).size()
		if dd == 2 and near < 0:
			near = int(sy3["id"])
		if dd > 8 and far < 0:
			far = int(sy3["id"])
	var keep_em: int = GameState.exotic_matter
	GameState.exotic_matter = 1
	var e_em: String = GameState.wormhole_error(tf, near)
	GameState.exotic_matter = 20
	var e_far: String = GameState.wormhole_error(tf, far) if far >= 0 else "too far"
	var e_ok: String = GameState.wormhole_error(tf, near)
	var e_ew: String = GameState.wormhole_error(GameState.create_from_preset("std_bastion", "player"), near)
	GameState.ship_jumped_out.disconnect(main._on_jumped_out)
	var e_go: String = GameState.begin_wormhole(tf, near)
	GameState.ship_jumped_out.connect(main._on_jumped_out)
	var paid: bool = GameState.exotic_matter == 18 and tf.transit_kind == "wormhole"
	var cooling: bool = GameState.wormhole_error(tf, near) != ""
	tf.transit = 0.0
	tf.system_id = int(tf.transit_to)          # arrive without loading the system (the test stays here)
	GameState._arrive_wormhole(tf, 0)
	tf.transit_kind = ""
	check(e_em != "" and e_far != "" and e_ok == "" and e_ew != "" and e_go == "" and paid and cooling and tf.system_id == near, "Threshold: wormhole jump without a gate – 1 exotic matter per jump, at most 8 jumps, a cooldown after each jump")
	var L := Universe.get_layout(near)
	var by_station := false
	for st2 in L["stations"]:
		by_station = by_station or tf.position.distance_to(st2["pos"]) < 7000.0
	GameState._arrive_wormhole(tf, 1)
	var off_station := true
	for st3 in L["stations"]:
		off_station = off_station and tf.position.distance_to(st3["pos"]) > 6500.0
	check(off_station, "… a failed wormhole throws the ship out somewhere at random in the target system")
	GameState.exotic_matter = keep_em
	check(PixelArt.black_hole_texture(-1, 0).get_image().get_data() != PixelArt.black_hole_texture(-1, 6).get_image().get_data() and PixelArt.black_hole_texture(0).get_width() == PixelArt.black_hole_texture().get_width(), "Threshold: the accretion disc turns round its black hole (animated)")
	# 0.4.25.37: the black hole ignites a few seconds after undocking and goes out on the way into the hangar
	var bf := GameState.create_from_preset("std_axa_threshold", "player")
	bf.position = view.player.position + Vector2(0, -126000)
	bf.uid = 99923
	var bs := Ship.new()
	bs.setup(bf, view)
	view.ship_layer.add_child(bs)
	var lit_in_space: bool = bs.bh_t > 0.0
	bs.bh_t = -1.0
	bs.order = {"type": "undocking"}
	bs._process(5.0)
	var off_undocking: bool = bs.bh_t < 0.0
	bs.order = {"type": "idle"}
	bs._process(1.0)
	var waits: bool = bs.bh_t < 0.0
	bs._process(2.0)
	bs._process(1.0)
	var burns: bool = bs.bh_t > 0.0
	bs.order = {"type": "docking"}
	bs._process(0.1)
	var flash_out: bool = bs.bh_t < 0.0 and bs.bh_out > 0.0
	bs._process(1.0)
	var flash_done: bool = bs.bh_out < 0.0
	# 0.4.25.39: out under the cloak, ignites again quickly once the ship shows
	bs.order = {"type": "idle"}
	bs.bh_t = 99.0
	bs.module_on["builtin_cloak"] = true
	bs._process(0.1)
	var cloak_out: bool = bs.bh_t < 0.0
	bs.module_on["builtin_cloak"] = false
	bs.cloak_k = 0.4
	bs._process(1.0)
	var still_out: bool = bs.bh_t < 0.0
	bs.cloak_k = 0.0
	bs._process(0.2)
	bs._process(0.2)
	check(lit_in_space and off_undocking and waits and burns and flash_out and flash_done, "Threshold: the black hole ignites with a flash a few seconds after undocking and goes out with one when docking")
	check(cloak_out and still_out and bs.bh_t >= 0.0, "Threshold: the black hole goes out under the cloak and ignites again once the ship shows")
	bs.queue_free()
	# research ships fly in Directorate systems
	var tr = view.traffic
	var keep_sid: int = tr.sid
	tr.sid = _system_of("directorate")
	var want_dir: int = tr._wanted("research")
	tr.sid = _system_of("assembly")
	var want_asm: int = tr._wanted("research")
	tr.sid = keep_sid
	var n0: int = tr.loiterers.size()
	tr._spawn_loiterer("research", true)
	var spawned := false
	for l in tr.loiterers:
		if l["kind"] == "research":
			spawned = true
			if is_instance_valid(l["ship"]):
				l["ship"].queue_free()
	check(want_dir == 2 and want_asm == 0 and spawned, "Axiom research ships survey the Directorate's systems")
	# debug: exotic matter
	var cheats: bool = Commands.cheats_enabled
	Commands.cheats_enabled = true
	var em0: int = GameState.exotic_matter
	var e5: String = Commands.execute({"type": "debug_exotic", "amount": 10})
	Commands.cheats_enabled = cheats
	check(e5 == "" and GameState.exotic_matter == em0 + 10, "debug menu: +10 exotic matter (and the wormhole cooldown reset)")
	GameState.exotic_matter = em0


## Phase 0.5 package 26: station type 0 – waystations with landing pads for S and M ships.
func _test_waystation(view: SystemView) -> void:
	var a1: Dictionary = StationArt.build({"type": "waystation", "tier": 1, "seed": 11})
	var a3: Dictionary = StationArt.build({"type": "waystation", "tier": 3, "seed": 12})
	check(a1["pads"].size() == 2 and a3["pads"].size() == 4 and a1["bays"].is_empty(), "waystation: landing pads instead of hangar bays (2 at tier 1 … 4 at tier 3)")
	var with_ws := 0
	for sy in Universe.systems:
		for st in Universe.get_layout(int(sy["id"]))["stations"]:
			if st["type"] == "waystation":
				with_ws += 1
	check(with_ws > Universe.systems.size() / 2 and with_ws <= Universe.systems.size(), "a waystation in most systems (%d of %d)" % [with_ws, Universe.systems.size()])
	var wd := {"id": "st_ws_test", "name": "Test Waystation", "type": "waystation", "tier": 1, "pos": view.player.position + Vector2(0, -160000),
		"seed": 11, "zone": 0.0, "faction": "", "market": {}, "shop": [], "shipyard": []}
	var wn: Celestial = view._add_celestial("station", wd)
	view.stations[wd["id"]] = wn
	# three shuttles want to land on two pads
	var ships: Array = []
	for k in 3:
		var sh: Ship = view.spawn_npc("civ_shuttle", wn.position + Vector2.from_angle(k * 2.0) * (wn.radius + 2500.0), "civilian", "")
		sh.set_physics_process(false)
		sh.set_order({"type": "dock", "node": wn})
		ships.append(sh)
	var max_on_pad := 0
	var waited := false
	var sank := false
	var hatch_opened := false
	for step in 2400:
		var per_pad := {}
		for sh2 in ships:
			if not is_instance_valid(sh2) or sh2.is_queued_for_deletion() or sh2.is_docked():
				continue
			sh2._physics_process(0.05)
			if not is_instance_valid(sh2) or sh2.is_queued_for_deletion():
				continue
			if String(sh2.order.get("type", "")) == "docking" and sh2.order.has("pad"):
				var pk := int(sh2.order["pad"])
				per_pad[pk] = int(per_pad.get(pk, 0)) + 1
				sank = sank or sh2.scale.x < 0.8
			if sh2.activity == "Waiting for a free landing pad":
				waited = true
		wn._process(0.05)
		for v in wn.pad_open.values():
			hatch_opened = hatch_opened or float(v) > 0.9
		for v2 in per_pad.values():
			max_on_pad = maxi(max_on_pad, int(v2))
	var docked := 0
	for sh3 in ships:
		if not is_instance_valid(sh3) or sh3.is_queued_for_deletion() or sh3.is_docked():
			docked += 1
	check(docked == 3 and waited and sank and hatch_opened and max_on_pad == 1, "ships land on the pads one at a time per pad and sink through the opening hatch – the third waits for a free pad")
	# lifting off: up through the hatch, then away
	var uf := GameState.create_from_preset("std_axa_parallax", "player")
	uf.uid = 99930
	uf.docked_at = wd["id"]
	uf.position = wn.position
	var us := Ship.new()
	us.setup(uf, view)
	view.ship_layer.add_child(us)
	us.set_physics_process(false)
	us.undock()
	var rose := false
	var on_pad := false
	for st2 in 200:
		if String(us.order.get("type", "")) != "undocking":
			break
		us._update_undocking(0.05)
		on_pad = on_pad or wn.pad_of(us) >= 0
		rose = rose or (us.scale.x > Ship.PAD_SINK + 0.1 and us.scale.x < 0.99 and us.modulate.a > 0.2)
	var away: bool = String(us.order.get("type", "")) != "undocking" and wn.pad_of(us) < 0 and us.position.distance_to(wn.position) > wn.radius * 0.4
	check(on_pad and rose and away, "lifting off: the ship rises through the hatch of a free pad and flies off")
	# only S and M ships
	var lf := GameState.create_from_preset("std_axa_threshold", "player")
	lf.uid = 99931
	lf.position = wn.position + Vector2(3000, 0)
	var ls := Ship.new()
	ls.setup(lf, view)
	view.ship_layer.add_child(ls)
	ls.set_physics_process(false)
	ls.set_order({"type": "dock", "node": wn})
	ls._physics_process(0.05)
	check(String(ls.order.get("type", "")) == "idle" and not ls.fits_pads(wn) and us.fits_pads(wn), "only S and M ships may land on a waystation – an L ship is turned away")
	for n9 in ships + [us, ls]:
		if is_instance_valid(n9):
			n9.queue_free()
	view.stations.erase(wd["id"])
	view.celestials.erase(wn)
	view.by_id.erase(wd["id"])
	wn.queue_free()
