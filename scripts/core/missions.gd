class_name Missions
extends RefCounted
## Contracts from the BlackLedger bulletin board.
## Types:
##   courier – carry sealed cargo to another station
##   bounty  – destroy N pirates in a system
##   mining  – deliver N units of ore to the issuing station
##   survey  – analyse an anomaly in a system
##   passenger – take passengers to another station (package 25c, own board tab): cabin class
##             bulk/business/luxury, amount = passengers, deadline, ship_uid = the ship carrying them
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
	if rng.randf() < GROUND_CHANCE:
		var gm := ground_offer(m, system_id, rng)               # package 53c: a job on foot
		if not gm.is_empty():
			return gm
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


# ---------------------------------------------------------------- ground jobs (package 53c, Luz)
# A job on foot at a site made for it: accepting it puts the site on a body's planet map (or, for a reactivation, the
# city's lift goes down to its maintenance tunnels); the goal is fixed; done, the site is used up – report back.
#   relic       – a Precursor ruin: get the relic first; another raider crew comes after a few minutes
#   salvage     – a crash site: the flight recorder of a named ship
#   bounty_foot – a pirate base: bring down its captain (it flees when the alarm rings)
#   heist       – a pirate base: empty the captain's strongbox; easy – an alarm halves the pay, hard – it fails the job
#   spy         – a crash site, a ruin or a pirate base: download the data from the deepest computer – a bonus unseen
#   reactivate  – a city's maintenance tunnels: restart the reactor
const GROUND_CHANCE := 0.3
const GROUND_KINDS := [["relic", 3], ["salvage", 3], ["bounty_foot", 2], ["heist", 2], ["spy", 2], ["reactivate", 2]]
const GROUND_THEME := {"relic": "precursor", "salvage": "wreck", "bounty_foot": "pirate", "heist": "pirate", "reactivate": "maint"}


static func ground_offer(m: Dictionary, system_id: int, rng: RandomNumberGenerator, kind: String = "") -> Dictionary:
	const PoiData = preload("res://data/poi.gd")
	if kind == "":
		var tot := 0
		for gk in GROUND_KINDS:
			tot += int(gk[1])
		var r := rng.randi() % tot
		for gk2 in GROUND_KINDS:
			r -= int(gk2[1])
			if r < 0:
				kind = String(gk2[0])
				break
	var theme: String = GROUND_THEME.get(kind, ["wreck", "precursor", "pirate"][rng.randi() % 3])
	# where: a body (a city for a reactivation) within two jumps
	var spots: Array = []
	for sid in _systems_within(system_id, 2):
		for b in Universe.get_layout(sid)["planets"] + Universe.get_layout(sid).get("moons", []):
			if not Universe.landable(b):
				continue
			if kind == "reactivate":
				for s in Universe.landing_sites(sid, b):
					if String(s["kind"]) == "city":
						spots.append([sid, b, s])
			else:
				spots.append([sid, b, {}])
	if spots.is_empty():
		return {}
	var sp: Array = spots[rng.randi() % spots.size()]
	var sid2: int = sp[0]
	var body: Dictionary = sp[1]
	var danger: String = ["green", "yellow", "yellow", "red"][rng.randi() % 4]
	var seed_n := rng.randi()
	var site := {"id": "msn_%s" % String(m["id"]), "name": PoiData.site_name(theme, rng), "kind": String(PoiData.THEMES[theme]["kind"]), "poi": true,
		"theme": theme, "seed": seed_n, "danger": danger, "lon": rng.randf_range(-1.0, 1.0), "lat": rng.randf_range(-0.75, 0.75),
		"mission": true, "mission_id": String(m["id"]), "goal": kind, "system": sid2, "body": String(body["id"])}
	if theme == "wreck":
		var hl: Array = PoiData.THEMES["wreck"]["hulls"]
		site["hull"] = String(hl[rng.randi() % hl.size()])
	var hard := kind == "heist" and rng.randf() < 0.5
	site["hard"] = hard
	if kind == "reactivate":
		site["city"] = Universe.city_id(body, sp[2])
		site["city_name"] = String(sp[2].get("name", "the city"))
	var jumps := Universe.find_path(system_id, sid2, 3).size()
	var dmul: float = {"green": 1.0, "yellow": 1.4, "red": 2.0}[danger]
	var where := "%s on %s (%s)" % [String(site["name"]), String(body.get("name", "?")), Universe.systems[sid2]["name"]]
	var t := ""
	var d := ""
	var base := 6000
	match kind:
		"relic":
			t = "Relic race: %s" % String(site["name"])
			d = "A Precursor relic lies deep in %s. Raiders are after it too – get it first; another crew is on its way." % where
			base = 9000
		"salvage":
			var hn: String = String(GameData.hulls.get(String(site.get("hull", "freighter")), {}).get("name", "freighter"))
			t = "Salvage: the %s" % hn
			d = "A %s came down – %s. Bring back its flight recorder." % [hn, where]
			base = 7000
		"bounty_foot":
			t = "Bounty on foot: a Red Talon captain"
			d = "The captain of the pirate base %s. Bring them down – they run when the alarm goes." % where
			base = 11000
		"heist":
			t = "Heist%s: the Red Talons' hoard" % (" (hard)" if hard else "")
			d = "Empty the captain's strongbox in %s. %s" % [where, "Unseen – an alarm fails the job." if hard else "An alarm halves the pay."]
			base = 14000 if hard else 10000
		"spy":
			t = "Espionage: data from %s" % String(site["name"])
			d = "Download the data from the deepest computer in %s – a bonus if nobody sees you." % where
			base = 8000
		"reactivate":
			t = "Reactivation: %s" % String(site["city_name"])
			d = "The power is out in the maintenance tunnels under %s (%s). Restart the reactor on the lowest level – the city's lift takes you down." % [String(site["city_name"]), Universe.systems[sid2]["name"]]
			base = 6500
			danger = "green"
			site["danger"] = "green"
			dmul = 1.0
	m.merge({"type": "ground", "goal": kind, "site": site, "target_system": sid2, "amount": 1,
		"reward": int((base + jumps * 1500) * dmul), "title": t, "desc": d}, true)
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
	# package 39a: special contracts of the Assembly – ballots to The Vote, drone field trials at the Concord Yards
	var sp := _assembly_special(m, system_id, station, rng)
	if sp.is_empty():
		sp = _covenant_special(m, system_id, station, rng)        # package 39b
	if sp.is_empty():
		sp = _directorate_special(m, system_id, station, rng)     # package 39c
	if not sp.is_empty():
		return sp
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

const BALLOT_CHANCE := 0.3           # package 39a: Assembly stations elsewhere send their ballots to The Vote
const BALLOT_TIME := 300.0           # deadline: 5 minutes + BALLOT_TIME_JUMP per jump
const BALLOT_TIME_JUMP := 150.0
const BALLOT_AMBUSH := 0.55          # chance per system on the way that thieves try to grab them
const TRIAL_CHANCE := 0.6            # at the Concord Yards: drone field trials
const TRIAL_KILLS := Vector2i(3, 6)


const DIRECTORATE_CHANCE := 0.3     # package 39c: Directorate stations elsewhere send out measurement probes
const DURCHBRUCH_CHANCE := 0.6      # at the Meridian Sphere and the Axiom Yards: exotic matter, test flights


## Package 39c: the Directorate's contracts – measurement probes (elsewhere), exotic matter for the Meridian Sphere,
## test flights from the Axiom Yards.
static func _directorate_special(m: Dictionary, system_id: int, station: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	if String(station.get("faction", "")) != "directorate":
		return {}
	if station.get("exchange", false):
		if rng.randf() >= DURCHBRUCH_CHANCE:
			return {}
		var n := rng.randi_range(2, 4)
		m.merge({"type": "exotic", "min_tier": "friendly", "amount": n, "reward": n * 16000,
			"title": "Exotic matter: %d units for the Meridian Sphere" % n,
			"desc": "The Sphere's engineers need %d units of exotic matter. It is found in rare anomalies – analyse them – and brought here." % n}, true)
		return m
	if String(station.get("art", "")) == "axiom_yards":
		if rng.randf() >= DURCHBRUCH_CHANCE:
			return {}
		var dests: Array = []
		for sid in _systems_within(system_id, 2):
			if sid == system_id or Universe.find_path(system_id, sid, 1).is_empty():
				continue
			for st in Universe.get_layout(sid)["stations"]:
				dests.append([sid, st])
		if dests.is_empty():
			return {}
		escort_fill(m, system_id, dests[rng.randi() % dests.size()], 1, "directorate")
		m["min_tier"] = "friendly"
		m["title"] = "Test flight: escort an Axiom prototype to %s" % Universe.systems[int(m["target_system"])]["name"]
		m["desc"] = "A prototype from the Axiom Yards makes its first long flight. Stay with it – at least %d %% of the way – and see that it arrives. Pirates would love to take it apart." % int(ESCORT_SHARE * 100.0)
		return m
	if rng.randf() >= DIRECTORATE_CHANCE:
		return {}
	var best := -1
	var low := INF
	for sid2 in _systems_within(system_id, 4):
		if sid2 != system_id and float(Universe.systems[sid2]["security"]) < low and not Universe.find_path(system_id, sid2, 3).is_empty():
			low = float(Universe.systems[sid2]["security"])
			best = sid2
	if best < 0:
		return {}
	m.merge({"type": "probe", "target_system": best, "amount": 1, "progress_t": 0.0,
		"reward": 6000 + int((1.0 - low) * 12000),
		"title": "Measurement probe in %s" % Universe.systems[best]["name"],
		"desc": "Fly to %s and let the probe measure – stay in the system, out in space, for %d minutes. Then bring the data back here." % [Universe.systems[best]["name"], int(GameState.PROBE_TIME / 60.0)]}, true)
	return m


const COVENANT_CHANCE := 0.3        # package 39b: Covenant stations elsewhere: pilgrims and crystals for Heimkehr
const RELIC_CHANCE := 0.6           # at the Cathedral of Return: relic recoveries


## Package 39b: the Covenant's own contracts – pilgrim convoys and crystal transports to Heimkehr, relic recoveries
## from the Cathedral of Return.
static func _covenant_special(m: Dictionary, system_id: int, station: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	if String(station.get("faction", "")) != "covenant":
		return {}
	var hk := Universe.special_system("heimkehr")
	if hk < 0:
		return {}
	if station.get("curia", false):
		if rng.randf() >= RELIC_CHANCE:
			return {}
		var cands: Array = []
		for sid in _systems_within(system_id, 3):
			if sid != system_id and not Universe.get_layout(sid)["anomalies"].is_empty():
				cands.append(sid)
		if cands.is_empty():
			return {}
		var ts: int = cands[rng.randi() % cands.size()]
		m.merge({"type": "relic", "relic": true, "min_tier": "friendly", "target_system": ts, "amount": 1,
			"reward": 9000 + int((1.0 - float(Universe.systems[ts]["security"])) * 9000),
			"title": "Relic recovery in %s" % Universe.systems[ts]["name"],
			"desc": "The Curia has word of a relic of Earth in an anomaly in %s. Scan the system, analyse the anomaly and bring the relic to the Cathedral of Return." % Universe.systems[ts]["name"]}, true)
		return m
	if system_id == hk or rng.randf() >= COVENANT_CHANCE:
		return {}
	var cath := {}
	var forge := {}
	for st in Universe.get_layout(hk)["stations"]:
		if st.get("curia", false):
			cath = st
		elif String(st.get("art", "")) == "forge":
			forge = st
	var jumps := Universe.find_path(system_id, hk, 3).size()
	if jumps <= 0 or cath.is_empty() or forge.is_empty():
		return {}
	if rng.randf() < 0.5:
		escort_fill(m, system_id, [hk, cath], rng.randi_range(2, 4), "covenant")
		m["min_tier"] = "friendly"
		m["to_capital"] = true
		m["title"] = "Pilgrims: a convoy of the faithful to the Cathedral of Return"
		m["desc"] = "Pilgrim ships leave this station for Heimkehr (%d jump%s). Keep them safe on the road home – at least %d %% of the way. You are paid per ship that arrives." % [jumps, "" if jumps == 1 else "s", int(ESCORT_SHARE * 100.0)]
		return m
	var amount := rng.randi_range(4, 10)
	m.merge({"type": "courier", "min_tier": "friendly", "to_capital": true, "target_system": hk, "target_station": forge["id"],
		"item": "sealed_cargo", "amount": amount, "reward": 4000 + jumps * 3000 + amount * 350,
		"title": "Crystal transport: raw focus crystals to the Forge of Return",
		"desc": "%d crates of raw focus crystals for the Forge of Return in Heimkehr (%d jump%s). Handle them gently – they are worth more than your ship." % [amount, jumps, "" if jumps == 1 else "s"]}, true)
	return m


static func _assembly_special(m: Dictionary, system_id: int, station: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	if String(station.get("faction", "")) != "assembly":
		return {}
	if String(station.get("art", "")) == "concord_yards" and rng.randf() < TRIAL_CHANCE:
		var n := rng.randi_range(TRIAL_KILLS.x, TRIAL_KILLS.y)
		m.merge({"type": "drone_trial", "min_tier": "friendly", "amount": n, "drone_trial": true,
			"reward": 9000 + n * 3500,
			"title": "Field trial: %d pirates by drone" % n,
			"desc": "Concord Fleetworks wants combat data from the field. Let your drones destroy %d pirate ships anywhere in Assembly space – your own guns do not count. A drone carrier is a must." % n}, true)
		return m
	var lf := Universe.special_system("landfall")
	if lf < 0 or lf == system_id or rng.randf() >= BALLOT_CHANCE:
		return {}
	var vote := {}
	for st in Universe.get_layout(lf)["stations"]:
		if st.get("senate", false):
			vote = st
	if vote.is_empty():
		return {}
	var jumps := Universe.find_path(system_id, lf, 3).size()
	if jumps <= 0:
		return {}
	var amount := rng.randi_range(2, 6)
	var limit := BALLOT_TIME + jumps * BALLOT_TIME_JUMP
	m.merge({"type": "courier", "ballot": true, "min_tier": "friendly", "target_system": lf, "target_station": vote["id"],
		"item": "sealed_cargo", "amount": amount, "time_limit": limit,
		"reward": 5000 + jumps * 3500 + amount * 400,
		"title": "Ballot courier: the votes of %s to The Vote" % Universe.systems[system_id]["name"],
		"desc": "%d sealed ballot cores must reach The Vote in Landfall (%d jump%s) before the polls close – %d:%02d from the moment you take them. Somebody always wants to know – or change – what is inside: expect thieves on the way." % [amount, jumps, "" if jumps == 1 else "s", int(limit) / 60, int(limit) % 60]}, true)
	return m


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
		"bounty", "survey", "drone_trial":
			return station_id == m["giver"] and int(m["progress"]) >= int(m["amount"])
		"ground":
			return station_id == m["giver"] and int(m["progress"]) >= 1           # package 53c
		"relic":
			return station_id == m["giver"] and int(m["progress"]) >= 1 and fit != null and float(fit.cargo.get("earth_relic", 0.0)) >= 0.99
		"probe":
			return station_id == m["giver"] and int(m["progress"]) >= 1
		"exotic":
			return station_id == m["giver"] and GameState.exotic_matter >= int(m["amount"])
		"passenger":
			if m.has("tour") and not bool(m["tour"]["done"]):
				return false                         # package 43b: they have not seen it yet
			return station_id == m["target_station"] and fit != null and fit.uid == int(m.get("ship_uid", -1))
	return false


static func progress_text(m: Dictionary, fit: ShipFitting) -> String:
	match String(m["type"]):
		"ground":
			if int(m["progress"]) >= 1:
				return "Done – report back to %s" % Universe.find_station(int(m["giver_system"]), String(m["giver"])).get("name", "the station")
			var st: Dictionary = m["site"]
			if String(m["goal"]) == "reactivate":
				return "The maintenance tunnels under %s (%s) – take the city's lift down" % [String(st.get("city_name", "")), Universe.systems[int(st["system"])]["name"]]
			return "Go to %s on %s (%s) – it is on the planet map" % [String(st["name"]), String(Universe.find_body(int(st["system"]), String(st["body"])).get("name", "?")), Universe.systems[int(st["system"])]["name"]]
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
			if m.get("ballot", false) and float(m.get("expires", -1.0)) > 0.0:
				var left2 := maxf(0.0, float(m["expires"]) - GameState.play_time)
				return "Ballots to %s (Landfall) – %d:%02d until the polls close" % [Universe.find_station(int(m["target_system"]), m["target_station"]).get("name", "?"), int(left2) / 60, int(left2) % 60]
			return "Deliver to %s" % Universe.find_station(int(m["target_system"]), m["target_station"]).get("name", "?")
		"drone_trial":
			return "%d / %d pirates destroyed by your drones in Assembly space" % [int(m["progress"]), int(m["amount"])]
		"relic":
			return "Relic found – bring it to the Cathedral of Return" if int(m["progress"]) >= 1 else "Analyse an anomaly in %s" % Universe.systems[int(m["target_system"])]["name"]
		"probe":
			if int(m["progress"]) >= 1:
				return "Measurements complete – report back"
			return "Measure in %s: %d:%02d / %d:00" % [Universe.systems[int(m["target_system"])]["name"], int(m.get("progress_t", 0.0)) / 60, int(m.get("progress_t", 0.0)) % 60, int(GameState.PROBE_TIME / 60.0)]
		"exotic":
			return "%d / %d exotic matter in stock" % [mini(GameState.exotic_matter, int(m["amount"])), int(m["amount"])]
		"mining":
			return "%d / %d %s in cargo" % [int(fit.cargo.get(m["item"], 0.0)) if fit != null else 0, int(m["amount"]), GameData.item_name(m["item"])]
		"bounty":
			return "%d / %d pirates destroyed" % [int(m["progress"]), int(m["amount"])]
		"survey":
			return "Anomaly analysed" if int(m["progress"]) >= 1 else "Analyse an anomaly in %s" % Universe.systems[int(m["target_system"])]["name"]
		"passenger":
			var where: String = Universe.find_station(int(m["target_system"]), m["target_station"]).get("name", "?")
			if m.has("tour") and not bool(m["tour"]["done"]) and float(m.get("expires", -1.0)) > 0.0:
				var tl := maxf(0.0, float(m["expires"]) - GameState.play_time)
				var tr: Dictionary = m["tour"]
				return "Show them %s in %s – stay close %d / %d s – %d:%02d left" % [tr["name"], Universe.systems[int(tr["system"])]["name"], int(tr["t"]), int(TOUR_VIEW), int(tl) / 60, int(tl) % 60]
			if float(m.get("expires", -1.0)) < 0.0:
				return "To %s (%s) – %d:%02d to get there" % [where, Universe.systems[int(m["target_system"])]["name"], int(m["time_limit"]) / 60, int(m["time_limit"]) % 60]
			var left := maxf(0.0, float(m["expires"]) - GameState.play_time)
			var aboard := GameState.get_fit(int(m.get("ship_uid", -1)))
			return "Take them to %s (%s) – %d:%02d left%s" % [where, Universe.systems[int(m["target_system"])]["name"], int(left) / 60, int(left) % 60,
				("   •   aboard %s" % aboard.ship_name) if aboard != null and fit != null and aboard.uid != fit.uid else ""]
	return ""


# ---------------------------------------------------------------- Passenger transport (package 25c)
# Own tab on the board. Bulk contracts fill the seats of all bulk cabins together; a business or
# luxury group needs a cabin of its class of its own that seats the whole group. Pay per passenger
# and jump; a deadline; failed (late, or the ship destroyed with them aboard) costs a little standing
# with the faction of the issuing station.

const CABIN_CLASSES := {
	"bulk": {"name": "Bulk", "pay": 60, "min": 6, "max": 45, "color": Color(0.7, 0.8, 0.9)},
	"business": {"name": "Business", "pay": 220, "min": 2, "max": 12, "color": Color(0.45, 0.75, 1.0)},
	"luxury": {"name": "Luxury", "pay": 700, "min": 1, "max": 8, "color": Color(1.0, 0.82, 0.4)},
}
const PASSENGER_OFFERS := 5
const MAX_PASSENGER_JOBS := 8       # passenger contracts at once (on top of the other contracts)
const PASSENGER_TIME := 180.0       # deadline: 3 minutes + PASSENGER_TIME_JUMP per jump
const PASSENGER_TIME_JUMP := 150.0
const PASSENGER_REP := 1.5          # standing lost when a passenger contract fails


## Rich, safe systems of the Assembly or the Covenant (luxury travellers, Maison Aurelle yards,
## Boulevard shuttles).
static func wealthy(sid: int) -> bool:
	if sid < 0 or sid >= Universe.systems.size():
		return false
	return float(Universe.systems[sid]["security"]) >= 0.65 and Universe.controller(sid) in ["assembly", "covenant"]


static func generate_passenger(system_id: int, station: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	# package 43b: round trips to a sight of another system, and tourists bound for a resort – more in richer systems
	var lv := Economy.level(system_id)
	if lv >= 2 and rng.randf() < TOUR_SHARE:
		var tour := generate_tour(system_id, station, rng)
		if not tour.is_empty():
			return tour
	var tourist := rng.randf() < TOURIST_SHARE + 0.08 * lv
	var dests: Array = []
	for sid in _systems_within(system_id, 4):
		if Universe.find_path(system_id, sid, 3).is_empty() and sid != system_id:
			continue
		for st in Universe.get_layout(sid)["stations"]:
			if st["id"] != station["id"] and (not tourist or String(st["type"]) == "resort"):
				dests.append([sid, st])
	if dests.is_empty() and tourist:
		tourist = false
		for sid2 in _systems_within(system_id, 4):
			if Universe.find_path(system_id, sid2, 3).is_empty() and sid2 != system_id:
				continue
			for st2 in Universe.get_layout(sid2)["stations"]:
				if st2["id"] != station["id"]:
					dests.append([sid2, st2])
	if dests.is_empty():
		return {}
	var d: Array = dests[rng.randi() % dests.size()]
	var lux := 0.18 + (0.14 if wealthy(system_id) else 0.0) + (0.15 if tourist else 0.0)
	var roll := rng.randf()
	var cls := "luxury" if roll < lux else ("business" if roll < lux + 0.32 else "bulk")
	var c: Dictionary = CABIN_CLASSES[cls]
	var amount := rng.randi_range(int(c["min"]), int(c["max"]))
	var jumps := Universe.find_path(system_id, d[0], 3).size()
	var m := {"id": _new_id(), "type": "passenger", "giver": station["id"], "giver_system": system_id,
		"client": "%s passengers" % c["name"], "progress": 0, "item": "", "amount": amount, "cabin": cls,
		"target_system": d[0], "target_station": d[1]["id"], "jumps": jumps,
		"faction": String(station.get("faction", "")), "against": "", "ship_uid": -1, "expires": -1.0, "cabin_slot": "",
		"time_limit": PASSENGER_TIME + PASSENGER_TIME_JUMP * jumps,
		"reward": int(c["pay"]) * amount * maxi(jumps, 1)}
	var who := "%d %s passenger%s" % [amount, String(c["name"]).to_lower(), "" if amount == 1 else "s"]
	m["title"] = "%s: %d× %s to %s" % ["Passengers", amount, c["name"], Universe.systems[d[0]]["name"]]
	m["desc"] = "Take %s to %s (%s, %d jump%s). %s" % [who, d[1]["name"], Universe.systems[d[0]]["name"], jumps, "" if jumps == 1 else "s",
		"They fill bulk seats." if cls == "bulk" else "The group needs a %s cabin of its own that seats all of them." % String(c["name"]).to_lower()]
	if tourist:
		# package 43b: holidaymakers bound for a resort – they pay better
		m["tourist"] = true
		m["reward"] = int(round(float(m["reward"]) * TOURIST_PAY))
		m["client"] = "%s tourists" % c["name"]
		m["title"] = "Tourists: %d× %s to %s" % [amount, c["name"], d[1]["name"]]
		m["desc"] = "Take %d %s tourist%s on holiday to %s (%s, %d jump%s). %s" % [amount, String(c["name"]).to_lower(), "" if amount == 1 else "s",
			d[1]["name"], Universe.systems[d[0]]["name"], jumps, "" if jumps == 1 else "s",
			"They fill bulk seats." if cls == "bulk" else "The group needs a %s cabin of its own." % String(c["name"]).to_lower()]
	return m


# ---------------------------------------------------------------- Package 43b: round trips

const TOUR_SHARE := 0.2             # share of passenger offers that are round trips (from Average prosperity up)
const TOURIST_SHARE := 0.12         # base share of tourist flights (+8 % per prosperity level)
const TOURIST_PAY := 1.3
const TOUR_VIEW := 45.0             # seconds near the sight
const TOUR_JUMPS := 3


## A round trip: tourists board here, see a sight in another system (up to three jumps) and come back here.
static func generate_tour(system_id: int, station: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var cands: Array = []
	var total := 0.0
	for sid in _systems_within(system_id, TOUR_JUMPS):
		if sid == system_id or Universe.find_path(system_id, sid, 3).is_empty():
			continue
		for sg in Tourism.sights(sid):
			cands.append([sid, sg])
			total += float(sg["appeal"])
	if cands.is_empty():
		return {}
	var r := rng.randf() * total
	var pick: Array = cands[0]
	for cd in cands:
		r -= float(cd[1]["appeal"])
		if r <= 0.0:
			pick = cd
			break
	var tsid: int = pick[0]
	var sg2: Dictionary = pick[1]
	var roll := rng.randf()
	var cls := "luxury" if roll < 0.3 else ("business" if roll < 0.7 else "bulk")
	var c: Dictionary = CABIN_CLASSES[cls]
	var amount := rng.randi_range(int(c["min"]), int(c["max"]))
	var jumps := Universe.find_path(system_id, tsid, 3).size()
	var m := {"id": _new_id(), "type": "passenger", "giver": station["id"], "giver_system": system_id,
		"client": "%s sightseers" % c["name"], "progress": 0, "item": "", "amount": amount, "cabin": cls,
		"target_system": system_id, "target_station": station["id"], "jumps": jumps * 2,
		"faction": String(station.get("faction", "")), "against": "", "ship_uid": -1, "expires": -1.0, "cabin_slot": "",
		"time_limit": PASSENGER_TIME + PASSENGER_TIME_JUMP * jumps * 2 + TOUR_VIEW * 2.0,
		"reward": int(round(float(c["pay"]) * amount * jumps * 2 * (1.0 + 0.15 * float(sg2["appeal"])))),
		"tour": {"system": tsid, "sight": String(sg2["id"]), "name": String(sg2["name"]), "body": String(sg2["body"]),
			"kind": String(sg2["kind"]), "t": 0.0, "done": false}}
	m["title"] = "Round trip: %d× %s to %s and back" % [amount, c["name"], sg2["name"]]
	m["desc"] = "Show %d %s sightseer%s %s in %s (%d jump%s): stay close for %d seconds, out of warp, then bring them back here. %s" % [
		amount, String(c["name"]).to_lower(), "" if amount == 1 else "s", sg2["name"], Universe.systems[tsid]["name"], jumps, "" if jumps == 1 else "s",
		int(TOUR_VIEW), "They fill bulk seats." if cls == "bulk" else "The group needs a %s cabin of its own." % String(c["name"]).to_lower()]
	return m


## Where a sight is now and how close you must come ({pos, range} – {} if not in this system's layout).
static func sight_place(tour: Dictionary) -> Dictionary:
	var L: Dictionary = Universe.get_layout(int(tour["system"]))
	var body := String(tour["body"])
	if body == "star":
		return {"pos": Vector2.ZERO, "range": float(L["star"]["radius"]) * 4.0 + 60000.0}
	for p in L["planets"]:
		if String(p["id"]) == body:
			return {"pos": p["pos"], "range": float(p["radius"]) * (6.0 if p.get("ring", false) else 3.0) + 25000.0}
	for st in L["stations"]:
		if String(st["id"]) == body:
			return {"pos": st["pos"], "range": 30000.0}
	return {}


## Passengers aboard a ship: {bulk: n, business: n, luxury: n} and the cabins taken.
static func _aboard(fit: ShipFitting) -> Dictionary:
	var out := {"bulk": 0, "business": 0, "luxury": 0, "taken": {}}
	for m in GameState.missions:
		if String(m["type"]) == "passenger" and int(m.get("ship_uid", -1)) == fit.uid:
			out[String(m["cabin"])] = int(out[String(m["cabin"])]) + int(m["amount"])
			if String(m.get("cabin_slot", "")) != "":
				out["taken"][String(m["cabin_slot"])] = true
	return out


## Free bulk seats of a ship.
static func bulk_free(fit: ShipFitting) -> int:
	var seats := 0
	for c in fit.stats()["cabins"]:
		if c["cabin"] == "bulk":
			seats += int(c["seats"])
	return seats - int(_aboard(fit)["bulk"])


## The cabin a business/luxury group would get: the smallest free one that seats them ("" = none).
static func pick_cabin(fit: ShipFitting, cls: String, amount: int) -> String:
	var taken: Dictionary = _aboard(fit)["taken"]
	var best := ""
	var best_seats := 1 << 30
	for c in fit.stats()["cabins"]:
		if c["cabin"] == cls and not taken.has(c["slot"]) and int(c["seats"]) >= amount and int(c["seats"]) < best_seats:
			best = c["slot"]
			best_seats = int(c["seats"])
	return best


## Why this ship cannot take the passengers ("" = it can).
static func cabin_error(fit: ShipFitting, m: Dictionary) -> String:
	if fit == null:
		return "No ship."
	var cls := String(m["cabin"])
	var n := int(m["amount"])
	if cls == "bulk":
		var free := bulk_free(fit)
		if free < n:
			return "Not enough bulk seats (%d free, %d needed)." % [maxi(free, 0), n]
		return ""
	if pick_cabin(fit, cls, n) == "":
		var has_any := false
		for c in fit.stats()["cabins"]:
			if c["cabin"] == cls:
				has_any = true
		if not has_any:
			return "Needs a %s cabin%s." % [String(CABIN_CLASSES[cls]["name"]).to_lower(), " (Maison Aurelle ships only)" if cls == "luxury" else ""]
		return "No free %s cabin for %d passengers." % [String(CABIN_CLASSES[cls]["name"]).to_lower(), n]
	return ""


## True if passengers use this cabin slot – it cannot be removed then.
static func cabin_in_use(fit: ShipFitting, slot: String) -> bool:
	var d: Dictionary = fit.module_data(slot)
	if not d.has("cabin"):
		return false
	var ab := _aboard(fit)
	if String(d["cabin"]) == "bulk":
		return bulk_free(fit) - int(d.get("passengers", 0)) < 0
	return ab["taken"].has(slot)


## Pay factor of the hull on luxury contracts (Boulevard −20 %, Empress +25 %).
static func pay_mult(fit: ShipFitting, m: Dictionary) -> float:
	if fit == null or String(m.get("cabin", "")) != "luxury":
		return 1.0
	return float(fit.hull().get("luxury_pay", 1.0))


## "bulk 40 seats (12 taken) · 2 business cabins (1 free) · …"
static func cabins_text(fit: ShipFitting) -> String:
	var ab := _aboard(fit)
	var parts: Array = []
	var seats := 0
	var cab := {"business": [], "luxury": []}
	for c in fit.stats()["cabins"]:
		if c["cabin"] == "bulk":
			seats += int(c["seats"])
		else:
			cab[c["cabin"]].append(c)
	if seats > 0:
		parts.append("bulk %d seats (%d taken)" % [seats, int(ab["bulk"])])
	for cls in ["business", "luxury"]:
		var list: Array = cab[cls]
		if list.is_empty():
			continue
		var sizes: Array = []
		var free := 0
		for c2 in list:
			sizes.append(str(int(c2["seats"])))
			if not ab["taken"].has(c2["slot"]):
				free += 1
		parts.append("%d %s cabin%s of %s seats (%d free)" % [list.size(), cls, "" if list.size() == 1 else "s", "/".join(PackedStringArray(sizes)), free])
	return "none" if parts.is_empty() else "  •  ".join(PackedStringArray(parts))
