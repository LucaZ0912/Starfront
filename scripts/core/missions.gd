class_name Missions
extends RefCounted
## Contracts from the BlackLedger bulletin board.
## Types:
##   courier – carry sealed cargo to another station
##   bounty  – destroy N pirates in a system
##   mining  – deliver N units of ore to the issuing station
##   survey  – analyse an anomaly in a system
## A mission is a Dictionary: {id, type, title, desc, reward, giver (station id), giver_system,
##   target_system, target_station, item, amount, progress, faction (giver station's faction),
##   against (faction the contract is aimed at – standing pull effect, package 12)}

const OFFERS_PER_STATION := 5
const CLIENTS := [
	"Neon Lantern Collective", "Ghostwire Ltd.", "Ashgrove Holdings", "Vesper Biotech",
	"The Quiet Union", "Ironclad Freight", "Saint Jude Clinics", "Halberd Security",
]

static var _counter := 0
const FactionData = preload("res://data/factions.gd")
const NotoriousTitle = preload("res://scripts/core/notorious.gd")


static func _new_id() -> String:
	_counter += 1
	return "m%d" % _counter


static func _systems_within(from: int, max_jumps: int) -> Array:
	var depth := {from: 0}
	var queue: Array = [from]
	while not queue.is_empty():
		var cur: int = queue.pop_front()
		if depth[cur] >= max_jumps:
			continue
		for nb in Universe.systems[cur]["links"]:
			if not depth.has(nb):
				depth[nb] = depth[cur] + 1
				queue.append(nb)
	return depth.keys()


## Creates a random offer for a station.
static func generate(system_id: int, station: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var client: String = CLIENTS[rng.randi() % CLIENTS.size()]
	var m := {"id": _new_id(), "giver": station["id"], "giver_system": system_id, "client": client,
		"progress": 0, "item": "", "amount": 0, "target_system": system_id, "target_station": "",
		"faction": String(station.get("faction", "")), "against": ""}
	if String(station.get("type", "")) == "trade" and rng.randf() < TRADE_ESCORT_CHANCE:
		var esc := _escort_offer(m, system_id, station, rng, "")
		if not esc.is_empty():
			return esc
	var roll := rng.randf()
	var nearby := _systems_within(system_id, 3)
	if roll < 0.35:
		# courier
		var dests: Array = []
		for sid in nearby:
			for st in Universe.get_layout(sid)["stations"]:
				if st["id"] != station["id"]:
					dests.append([sid, st])
		if not dests.is_empty():
			var d: Array = dests[rng.randi() % dests.size()]
			var amount := rng.randi_range(3, 12)
			var jumps := Universe.find_path(system_id, d[0], 3).size()
			m.merge({"type": "courier", "target_system": d[0], "target_station": d[1]["id"], "item": "sealed_cargo", "amount": amount,
				"reward": 2500 + amount * 300 + jumps * 2500,
				"title": "Courier: %d× Sealed Cargo" % amount,
				"desc": "Deliver %d units of sealed cargo to %s (%s, %d jumps). Don't open it." % [amount, d[1]["name"], Universe.systems[d[0]]["name"], jumps]}, true)
			return m
	if roll < 0.65:
		# bounty
		var targets: Array = []
		for sid in nearby:
			if float(Universe.systems[sid]["security"]) < 0.8 and sid != Universe.home_system:
				targets.append(sid)
		if not targets.is_empty():
			var sid: int = targets[rng.randi() % targets.size()]
			var amount := rng.randi_range(2, 5)
			var danger := 1.0 - float(Universe.systems[sid]["security"])
			# aimed at the pirate faction holding the target system (pull effect, package 12)
			var against := Universe.controller(sid)
			m.merge({"type": "bounty", "target_system": sid, "amount": amount,
				"against": against if against in ["hollow_crown", "severed"] else "",
				"reward": int(amount * (2500 + danger * 6000)),
				"title": "Bounty: %d pirates in %s" % [amount, Universe.systems[sid]["name"]],
				"desc": "Destroy %d pirate ships in the %s system. Pirates lurk near asteroid fields and anomalies." % [amount, Universe.systems[sid]["name"]]}, true)
			return m
	if roll < 0.85:
		# mining
		# Supply: mostly common ores, sometimes uncommon ones
		var ores: Array = []
		for cid in GameData.commodities:
			var cd: Dictionary = GameData.commodities[cid]
			if cd.get("category", "") == "ore" and (cd["rarity"] == "common" or (cd["rarity"] == "uncommon" and rng.randf() < 0.35)):
				ores.append(cid)
		var ore: String = ores[rng.randi() % ores.size()]
		var amount := rng.randi_range(10, 40)
		var price := float(GameData.commodities[ore]["price"])
		m.merge({"type": "mining", "item": ore, "amount": amount, "reward": int(amount * price * 2.2 + 800),
			"title": "Supply: %d× %s" % [amount, GameData.item_name(ore)],
			"desc": "Deliver %d units of %s to this station." % [amount, GameData.item_name(ore)]}, true)
		return m
	# survey
	var sid2: int = nearby[rng.randi() % nearby.size()]
	m.merge({"type": "survey", "target_system": sid2, "amount": 1,
		"reward": 6000 + int((1.0 - float(Universe.systems[sid2]["security"])) * 9000),
		"title": "Survey: anomaly in %s" % Universe.systems[sid2]["name"],
		"desc": "Scan the %s system and analyse one anomaly with an analyzer. Bring the data home." % Universe.systems[sid2]["name"]}, true)
	return m


# ---------------------------------------------------------------- Faction contracts (package 17)
# Issued by the government owning the station (not BlackLedger's clients) and tied to your standing
# with it: convoy escort, flying with a patrol, intercepting a smuggler (Neutral and better) and
# hunting a notorious pirate (Friendly and better). They raise the standing more than ordinary work.

const FACTION_OFFERS := 3
const FACTION_REP := 4.0
const ESCORT_SHARE := 0.6          # be with the convoy at least 60 % of its journey
const PATROL_TIME := 180.0         # fly with a patrol for 3 minutes (within PATROL_RANGE)
const PATROL_RANGE := 10000.0
const SMUGGLER_TIME := 1200.0      # the smuggler is expected within 20 minutes
const TIER_NAMES := {"neutral": "Neutral", "friendly": "Friendly"}


## Debug (menu → Pilot): an escort contract from `station` with `n` freighters to a random station
## exactly `jumps` jumps away. {} = no such destination.
static func debug_escort(system_id: int, station: Dictionary, n: int, jumps: int, rng: RandomNumberGenerator) -> Dictionary:
	var dests: Array = []
	for sid in _systems_within(system_id, jumps):
		if sid == system_id or Universe.find_path(system_id, sid, 1).size() != jumps:
			continue
		for st in Universe.get_layout(sid)["stations"]:
			dests.append([sid, st])
	if dests.is_empty():
		return {}
	var f := String(station.get("faction", ""))
	var gov := f if f in FactionData.POWERS else ""
	var m := {"id": _new_id(), "giver": station["id"], "giver_system": system_id,
		"client": FactionData.name_of(f) if gov != "" else "BlackLedger", "progress": 0, "item": "", "amount": 1,
		"target_system": system_id, "target_station": "", "faction": gov, "against": "", "faction_job": false, "rep": 0.0}
	return escort_fill(m, system_id, dests[rng.randi() % dests.size()], n, gov)


static func generate_faction(system_id: int, station: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var f := String(station.get("faction", ""))
	var m := {"id": _new_id(), "giver": station["id"], "giver_system": system_id, "client": FactionData.name_of(f),
		"progress": 0, "item": "", "amount": 1, "target_system": system_id, "target_station": "",
		"faction": f, "against": "", "faction_job": true, "min_tier": "neutral", "rep": FACTION_REP}
	var kinds: Array = ["escort", "patrol", "smuggler", "hunt"]
	var kind: String = kinds[rng.randi() % kinds.size()]
	if kind == "hunt":
		var caps: Array = []
		for c in GameState.notorious.captains:
			if c["alive"]:
				caps.append(c)
		if caps.is_empty():
			kind = "smuggler"
		else:
			var c: Dictionary = caps[rng.randi() % caps.size()]
			m.merge({"type": "hunt", "min_tier": "friendly", "captain": c["id"], "against": c["faction"],
				"reward": 20000 + int(c["bounty"]) / 2 + 10000 * int(c["stars"]),
				"title": "Hunt: %s" % NotoriousTitle.title(c),
				"desc": "The %s wants %s (%s) dead. Last seen in %s. The SWX bounty is paid on top." % [FactionData.short_of(f), NotoriousTitle.title(c), NotoriousTitle.stars_text(c), Universe.systems[int(c["system"])]["name"]]}, true)
			return m
	if kind == "escort":
		var esc := _escort_offer(m, system_id, station, rng, f)
		if not esc.is_empty():
			return esc
		kind = "patrol"
	if kind == "smuggler":
		var targets: Array = []
		for sid3 in _systems_within(system_id, 2):
			if sid3 != Universe.home_system:
				targets.append(sid3)
		var tsys: int = targets[rng.randi() % targets.size()] if not targets.is_empty() else system_id
		m.merge({"type": "smuggler", "target_system": tsys, "against": "hollow_crown", "expires": -1.0, "spawned": false,
			"reward": 9000 + int((1.0 - float(Universe.systems[tsys]["security"])) * 8000),
			"title": "Intercept: smuggler in %s" % Universe.systems[tsys]["name"],
			"desc": "A Hollow Crown runner is expected in %s within %d minutes. Find the unregistered hauler and destroy it before it reaches a gate – a Warp Interdictor helps." % [Universe.systems[tsys]["name"], int(SMUGGLER_TIME / 60.0)]}, true)
		return m
	# patrol: its own patrol group meets the pilot at this station or at a named place in the system
	var meet := {"id": String(station["id"]), "name": String(station["name"])}
	if rng.randf() < 0.4:
		var places: Array = []
		var L := Universe.get_layout(system_id)
		for g in L["gates"]:
			places.append({"id": String(g["id"]), "name": String(g["name"])})
		for fl in L["fields"]:
			places.append({"id": String(fl["id"]), "name": String(fl["name"])})
		if not places.is_empty():
			meet = places[rng.randi() % places.size()]
	m.merge({"type": "patrol", "amount": int(PATROL_TIME), "progress_t": 0.0, "meet": meet,
		"reward": 4500 + int((1.0 - float(Universe.systems[system_id]["security"])) * 6000),
		"title": "Patrol: fly with the %s" % FactionData.short_of(f),
		"desc": "A %s patrol waits for you at %s (%s). Join it – follow its lead ship – and fly its rounds for %d minutes (stay within %s). Help it if it gets into a fight." % [FactionData.short_of(f), meet["name"], Universe.systems[system_id]["name"], int(PATROL_TIME / 60.0), "10,000 km"]}, true)
	return m


const TRADE_ESCORT_CHANCE := 0.3    # BlackLedger offers at trade hubs that are convoy escorts


## Convoy escort (faction contract with `gov`, or – gov "" – a trader's convoy from BlackLedger):
## 2–4 freighters to a station 1–2 jumps away. The pay is shared out per freighter: every one that
## is lost costs its part.
static func _escort_offer(m: Dictionary, system_id: int, station: Dictionary, rng: RandomNumberGenerator, gov: String) -> Dictionary:
	var dests: Array = []
	for sid in _systems_within(system_id, 2):
		if sid == system_id or Universe.find_path(system_id, sid, 1).is_empty():
			continue
		for st in Universe.get_layout(sid)["stations"]:
			dests.append([sid, st])
	if dests.is_empty():
		return {}
	var d: Array = dests[rng.randi() % dests.size()]
	return escort_fill(m, system_id, d, rng.randi_range(2, 4), gov)


## Fills `m` as an escort of `n` freighters to `d` = [system id, station] (also used by the debug menu).
static func escort_fill(m: Dictionary, system_id: int, d: Array, n: int, gov: String) -> Dictionary:
	var path := Universe.find_path(system_id, d[0], 1)
	var jumps := path.size()
	var danger := 0.0
	for sid2 in path:
		danger = maxf(danger, 1.0 - float(Universe.systems[sid2]["security"]))
	var size_word: String = "small" if n <= 2 else ("medium" if n == 3 else "large")
	var who := ("%s convoy" % FactionData.short_of(gov)) if gov != "" else "trade convoy chartered by %s" % m["client"]
	m.merge({"type": "escort", "target_system": d[0], "target_station": d[1]["id"], "convoy": -1, "with_t": 0.0, "total_t": 0.0,
		"freighters": n, "arrived": -1, "convoy_gov": gov,
		"reward": int((4000 + jumps * 3500 + danger * 8000) * (0.6 + 0.25 * n)),
		"title": "Escort: %s convoy (%d freighters) to %s" % [size_word, n, Universe.systems[d[0]]["name"]],
		"desc": "A %s with %d freighters leaves this station for %s (%s, %d jump%s). Stay with it – at least %d %% of the way. You are paid per freighter that arrives.%s" % [who, n, d[1]["name"], Universe.systems[d[0]]["name"], jumps, "" if jumps == 1 else "s", int(ESCORT_SHARE * 100.0), "" if gov != "" else " It has no escort of its own – you are its only protection."]}, true)
	return m


## What a completed contract pays: escorts lose the share of every freighter that did not arrive.
static func payout(m: Dictionary) -> int:
	if String(m["type"]) == "escort" and int(m.get("freighters", 0)) > 0 and int(m.get("arrived", -1)) >= 0:
		return int(round(float(m["reward"]) * clampf(float(m["arrived"]) / float(m["freighters"]), 0.0, 1.0)))
	return int(m["reward"])


## Can the mission be turned in at this station right now?
static func can_turn_in(m: Dictionary, fit: ShipFitting, station_id: String) -> bool:
	match String(m["type"]):
		"escort":
			return station_id == m["target_station"] and int(m["progress"]) >= 1
		"patrol", "hunt", "smuggler":
			return station_id == m["giver"] and int(m["progress"]) >= 1
		"courier":
			return station_id == m["target_station"] and float(fit.cargo.get("sealed_cargo", 0.0)) >= float(m["amount"]) - 0.01
		"mining":
			return station_id == m["giver"] and float(fit.cargo.get(m["item"], 0.0)) >= float(m["amount"]) - 0.01
		"bounty", "survey":
			return station_id == m["giver"] and int(m["progress"]) >= int(m["amount"])
	return false


static func progress_text(m: Dictionary, fit: ShipFitting) -> String:
	match String(m["type"]):
		"escort":
			if int(m["progress"]) >= 1:
				return "Convoy delivered (%d / %d freighters, pay %d %%) – report at %s" % [int(m.get("arrived", 0)), int(m.get("freighters", 0)), int(round(100.0 * float(payout(m)) / maxf(float(m["reward"]), 1.0))), Universe.find_station(int(m["target_system"]), m["target_station"]).get("name", "?")]
			var share := float(m["with_t"]) / maxf(float(m["total_t"]), 1.0)
			return "Escort the convoy to %s – with it %d %% of the way" % [Universe.systems[int(m["target_system"])]["name"], int(share * 100.0)]
		"patrol":
			if int(m["progress"]) >= 1:
				return "Patrol flown – report back"
			if float(m["progress_t"]) <= 0.0 and m.has("meet"):
				return "Meet the %s patrol at %s, then fly with it (%d:00)" % [FactionData.short_of(String(m["faction"])), m["meet"]["name"], int(m["amount"]) / 60]
			return "Fly with the %s patrol: %d:%02d / %d:00" % [FactionData.short_of(String(m["faction"])), int(m["progress_t"]) / 60, int(m["progress_t"]) % 60, int(m["amount"]) / 60]
		"hunt":
			if int(m["progress"]) >= 1:
				return "Target destroyed – report back"
			var c: Dictionary = GameState.notorious.get_captain(String(m["captain"]))
			return "Destroy %s – last seen in %s" % [NotoriousTitle.title(c), Universe.systems[int(c["system"])]["name"]] if not c.is_empty() else "Target gone"
		"smuggler":
			if int(m["progress"]) >= 1:
				return "Smuggler destroyed – report back"
			if float(m["expires"]) > 0.0:
				var left := maxf(0.0, float(m["expires"]) - GameState.play_time)
				return "Intercept the smuggler in %s – %d:%02d left" % [Universe.systems[int(m["target_system"])]["name"], int(left) / 60, int(left) % 60]
			return "Intercept the smuggler in %s" % Universe.systems[int(m["target_system"])]["name"]
		"courier":
			return "Deliver to %s" % Universe.find_station(int(m["target_system"]), m["target_station"]).get("name", "?")
		"mining":
			return "%d / %d %s in cargo" % [int(fit.cargo.get(m["item"], 0.0)) if fit != null else 0, int(m["amount"]), GameData.item_name(m["item"])]
		"bounty":
			return "%d / %d pirates destroyed" % [int(m["progress"]), int(m["amount"])]
		"survey":
			return "Anomaly analysed" if int(m["progress"]) >= 1 else "Analyse an anomaly in %s" % Universe.systems[int(m["target_system"])]["name"]
	return ""
