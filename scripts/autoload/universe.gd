extends Node
const MakerData = preload("res://data/manufacturers.gd")
const ModuleData = preload("res://data/modules.gd")
## The galaxy: star systems, hyperspace routes and system layouts.
## Every system is one big continuous space (SYSTEM_RADIUS) at a "realistic" scale.
## Systems are only connected via hyperspace routes (gates). Every route has a class (1-3) –
## the hyperdrive must be at least that class. Star system names are intentionally German.

const CommodityData = preload("res://data/commodities.gd")

const SYSTEM_NAMES := [
	"Helion", "Arkadia", "Vesta", "Kepler-Tor", "Morgenrot", "Eisenhafen", "Lyra", "Brennglas",
	"Nyx", "Tiamat", "Zenit", "Glutheim", "Nebelkrone", "Aschenfeld", "Drakenhorst", "Kalter Stern",
	"Ferne Wacht", "Schattenmark", "Orion-Rand", "Sturmtiefe", "Vakuumtor", "Letzte Bastion",
	# galaxy version 2 (phase 0.5 package 6): larger cluster
	"Silberquell", "Rabenfels", "Glimmertal", "Frosthain", "Sonnenwende", "Dunkelmoor", "Wolkenburg",
	"Kristallsee", "Donnerkeil", "Sternenwacht", "Mondsichel", "Eiswind", "Rotgold", "Feuerkranz",
	"Nordlicht", "Tiefenhall", "Grauwacke", "Sturmfels", "Weltenrand", "Bernstein", "Funkenflug",
	"Leuchtfeuer", "Ödland", "Himmelstor", "Nachtfalke", "Hohenstein",
]
## Galaxy generator version (stored in saves; older saves are moved to the current cluster).
const GALAXY_VERSION := 3
const FactionData = preload("res://data/factions.gd")
## Territory sizes (phase 0.5 package 10): systems per power / per territorial pirate faction.
const POWER_SYSTEMS := 12
const POWER_SYSTEMS_MAX := 14
const PIRATE_SYSTEMS := 4
## Every station type exists in every tier at least once somewhere in the cluster.
const ALL_STATION_TYPES := ["trade", "industry", "mining_colony", "agri", "research", "military", "ice_refinery", "shipyard"]
const ROMAN := ["I", "II", "III", "IV", "V", "VI", "VII", "VIII"]
## Asteroid field classes and their orbital band (km from the star, before frost scaling).
const FIELD_CLASSES := ["metallic", "stony", "icy"]
const FIELD_BANDS := {"metallic": Vector2(380000, 900000), "stony": Vector2(750000, 1350000), "icy": Vector2(1250000, 1850000)}
## Hot stars push the frost line outward, cool ones pull it in.
const FROST_SCALE := {"Yellow Dwarf": 1.0, "Red Dwarf": 0.8, "Blue Giant": 1.15, "White Dwarf": 0.85, "Orange Giant": 1.05}
## Rock class orbiting each planet type (gas giants collect ice, lava worlds metal).
const PLANET_ROCK_CLASS := {"terran": "stony", "desert": "stony", "ice": "icy", "lava": "metallic", "gas": "icy", "toxic": "icy", "barren": "metallic"}
## No-fire zone radius around stations by tier (km). Firing inside makes the station's defence engage.
const NO_FIRE_ZONE := [15000.0, 22000.0, 30000.0]
const HAVEN_NAMES := ["Rustmaw", "Blackhook", "Carrion Nest", "Gallows Reach", "Scrapjaw Den", "Red Lantern", "Vulture's Rest"]
const COLOSSUS_PREFIX := ["K", "V", "R", "T", "Z", "M", "X", "H", "N", "Q"]
## Asteroid size classes: radius (km) and deposit range.
const ASTEROID_SIZES := {
	"small": {"radius": Vector2(10, 25), "amount": Vector2(30, 120)},
	"medium": {"radius": Vector2(25, 60), "amount": Vector2(120, 400)},
	"large": {"radius": Vector2(60, 150), "amount": Vector2(400, 1500)},
}
## Procedural shapes: round, potato (elongated), contact binary, angular fragment, ice shard.
const SHAPES_BY_CLASS := {
	"metallic": ["round", "potato", "binary", "fragment"],
	"stony": ["round", "potato", "binary", "fragment"],
	"icy": ["round", "potato", "shard", "shard", "fragment"],
}
## Rare deposits are smaller.
const RARITY_AMOUNT := {"common": 1.0, "uncommon": 0.8, "rare": 0.55}
const ANOMALY_NAMES := [
	"Gravitational Anomaly", "Derelict Wreck Field", "Subspace Echo", "Ion Storm Core",
	"Unknown Signal", "Crystalline Structure", "Ancient Probe", "Dark Matter Cloud",
]
const MAP_SIZE := Vector2(2100, 1350)
## A system is ONE continuous space. 1 unit = 1 km.
## At sublight speed (~300 km/s) flying from the star to the edge takes 1–2 hours.
const SYSTEM_RADIUS := 2000000.0
const GATE_DISTANCE := 1900000.0
## Below this distance ships fly normally instead of warping.
const WARP_MIN := 40000.0
const STAR_TYPES := [
	{"name": "Yellow Dwarf", "color": Color(1.0, 0.9, 0.5), "radius": 60000.0},
	{"name": "Red Dwarf", "color": Color(1.0, 0.45, 0.3), "radius": 40000.0},
	{"name": "Blue Giant", "color": Color(0.55, 0.7, 1.0), "radius": 110000.0},
	{"name": "White Dwarf", "color": Color(0.9, 0.95, 1.0), "radius": 25000.0},
	{"name": "Orange Giant", "color": Color(1.0, 0.65, 0.3), "radius": 90000.0},
]

## systems[i] = {id, name, pos (Galaxiekarte), security 0..1, star, links {nachbar_id: routenklasse}}
var systems: Array = []
## Lazily generated system layouts (planets, stations, gates, asteroids, anomalies).
## They are mutable (asteroids get mined etc.) and persist.
var layouts: Dictionary = {}
var home_system := 0
var seed_value := 4711
var test_mode := false   # debug test system active (never saved, main galaxy untouched)


func _ready() -> void:
	generate(seed_value)


func generate(p_seed: int) -> void:
	test_mode = false
	seed_value = p_seed
	systems.clear()
	layouts.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = p_seed
	for i in SYSTEM_NAMES.size():
		var pos := Vector2.ZERO
		for attempt in 400:
			pos = Vector2(rng.randf_range(70.0, MAP_SIZE.x - 70.0), rng.randf_range(70.0, MAP_SIZE.y - 70.0))
			var ok := true
			for s in systems:
				if (s["pos"] as Vector2).distance_to(pos) < 165.0:
					ok = false
					break
			if ok:
				break
		systems.append({
			"id": i, "name": SYSTEM_NAMES[i], "pos": pos, "security": 0.5,
			"star": rng.randi() % STAR_TYPES.size(), "links": {},
		})
	_build_routes(rng)
	_assign_territory()
	_plan_stations()


## Decides type and tier of every station (and Pirate Haven) in the cluster up front, so that every
## station type appears in every tier at least once and the star map can show all economies
## without generating the systems. Stored as systems[i]["stations_plan"] / ["haven_tier"].
func _plan_stations() -> void:
	var prng := RandomNumberGenerator.new()
	prng.seed = seed_value * 31337 + 99
	var slots: Array = []        # [system id, index] still free
	for s in systems:
		var plan: Array = []
		if s["id"] == home_system:
			plan = [["trade", 3], ["military", 2]]
		else:
			var r := prng.randf()
			var cnt := 0 if r < 0.22 else (1 if r < 0.78 else 2)
			for k in cnt:
				plan.append([])
				slots.append([s["id"], k])
		s["stations_plan"] = plan
		s["haven_tier"] = 0
	# required combinations (the home system already has trade 3 and military 2)
	var required: Array = []
	for t in ALL_STATION_TYPES:
		for tier in [1, 2, 3]:
			if not ((t == "trade" and tier == 3) or (t == "military" and tier == 2)):
				required.append([t, tier])
	_shuffle(required, prng)
	required.sort_custom(func(a, b): return int(a[0] == "shipyard") > int(b[0] == "shipyard"))
	# make sure there are enough slots
	while slots.size() < required.size() + 4:
		var sid := prng.randi() % systems.size()
		var pl: Array = systems[sid]["stations_plan"]
		if sid != home_system and pl.size() < 2:
			pl.append([])
			slots.append([sid, pl.size() - 1])
	_shuffle(slots, prng)
	for combo in required:
		var pick := -1
		for i in slots.size():
			var sys: Dictionary = systems[slots[i][0]]
			if combo[0] == "shipyard" and float(sys["security"]) < 0.4:
				continue
			var dup := false
			for other in sys["stations_plan"]:
				dup = dup or (not other.is_empty() and other[0] == combo[0])
			if dup:
				continue
			pick = i
			break
		if pick < 0:
			pick = 0
		var slot: Array = slots[pick]
		systems[slot[0]]["stations_plan"][slot[1]] = combo
		slots.remove_at(pick)
	# the remaining stations: mostly the six base types, special ones now and then
	for slot2 in slots:
		var sys2: Dictionary = systems[slot2[0]]
		var pool: Array = CommodityData.BASE_STATION_TYPES.duplicate()
		pool.append("ice_refinery")
		if float(sys2["security"]) >= 0.4:
			pool.append("shipyard")
		var t2: String = pool[prng.randi() % pool.size()]
		var x := prng.randf()
		var tier2 := 1 if x < 0.3 else (2 if x < 0.85 else 3)
		sys2["stations_plan"][slot2[1]] = [t2, tier2]
	# Pirate Havens: only in pirate territory (phase 0.5 package 10) – the strongholds of both
	# pirate factions are tier 3 and 2, one more system gets a tier 1 haven, the rest by chance
	var pir: Array = []
	for s3 in systems:
		if s3.get("faction", "") in FactionData.TERRITORIAL_PIRATES:
			pir.append(s3)
	pir.sort_custom(func(a, b): return int(a["id"]) < int(b["id"]))
	var tier_core := 3
	for s4 in pir:
		if s4["capital"]:
			s4["haven_tier"] = tier_core
			tier_core = 2
	var have_one := false
	for s5 in pir:
		if s5["capital"]:
			continue
		if not have_one:
			s5["haven_tier"] = 1
			have_one = true
		elif prng.randf() < 0.5:
			s5["haven_tier"] = prng.randi_range(1, 2)


## Does the system have stations? (from the cluster plan – no layout generation needed)
func has_stations(sid: int) -> bool:
	var s: Dictionary = systems[sid]
	if s.has("stations_plan"):
		return not (s["stations_plan"] as Array).is_empty()
	return not get_layout(sid)["stations"].is_empty()


# ---------------------------------------------------------------- Factions & territory (phase 0.5 package 10)
# Three powers grow outward from their capitals, two pirate factions hold remote corners of the
# cluster, and where powers meet a few systems stay contested. Security follows from the owner
# and the distance to its capital. All deterministic from the seed – nothing of it is saved.
#   systems[i]["faction"]   controlling faction id ("" = contested / independent)
#   systems[i]["claimants"] contested systems: the factions fighting over it
#   systems[i]["capital"]   capital of its faction
#   systems[i]["core_dist"] jumps to the own capital / pirate core

## Jumps between all systems (BFS from every system).
func _hop_table() -> Array:
	var n := systems.size()
	var out: Array = []
	for a in n:
		var d := {a: 0}
		var q: Array = [a]
		while not q.is_empty():
			var cur: int = q.pop_front()
			for nb in systems[cur]["links"]:
				if not d.has(nb):
					d[nb] = int(d[cur]) + 1
					q.append(nb)
		var row: Array = []
		for b in n:
			row.append(int(d.get(b, 99)))
		out.append(row)
	return out


func _assign_territory() -> void:
	var n := systems.size()
	var trng := RandomNumberGenerator.new()
	trng.seed = seed_value * 2654435 + 1013
	var hops := _hop_table()
	for s in systems:
		s["faction"] = ""
		s["claimants"] = []
		s["capital"] = false
		s["core_dist"] = 0
	# capitals: three well-connected systems as far apart from each other as possible
	var cand: Array = []
	for s in systems:
		if (s["links"] as Dictionary).size() >= 2:
			cand.append(int(s["id"]))
	# pass 1: the largest possible minimum distance; pass 2: among good triples, the one that
	# leaves every power enough room (hop-Voronoi regions of similar size)
	var max_mh := 0
	for i in cand.size():
		for j in range(i + 1, cand.size()):
			for k in range(j + 1, cand.size()):
				max_mh = maxi(max_mh, mini(mini(int(hops[cand[i]][cand[j]]), int(hops[cand[i]][cand[k]])), int(hops[cand[j]][cand[k]])))
	var best_score := -INF
	var caps: Array = []
	for i in cand.size():
		for j in range(i + 1, cand.size()):
			for k in range(j + 1, cand.size()):
				var a: int = cand[i]
				var b: int = cand[j]
				var c: int = cand[k]
				var mh := mini(mini(int(hops[a][b]), int(hops[a][c])), int(hops[b][c]))
				if mh < max_mh - 2:
					continue
				var md := minf(minf(_dist(a, b), _dist(a, c)), _dist(b, c))
				var edge := 0.0
				for x in [a, b, c]:
					var p: Vector2 = systems[x]["pos"]
					edge += minf(minf(p.x, MAP_SIZE.x - p.x), minf(p.y, MAP_SIZE.y - p.y))
				var region := [0, 0, 0]
				for sx in n:
					var da: int = hops[sx][a]
					var db: int = hops[sx][b]
					var dc: int = hops[sx][c]
					if da <= db and da <= dc:
						region[0] += 1
					elif db <= dc:
						region[1] += 1
					else:
						region[2] += 1
				var small := mini(mini(region[0], region[1]), region[2])
				var score := mh * 300.0 + small * 150.0 + md * 0.3 + edge * 0.2
				if score > best_score:
					best_score = score
					caps = [a, b, c]
	var powers: Array = FactionData.POWERS.duplicate()
	_shuffle(powers, trng)
	var owner := {}
	for i in 3:
		owner[caps[i]] = powers[i]
		systems[caps[i]]["capital"] = true
	# pirate cores: as far from every capital as possible, and apart from each other
	var pirate_cores: Array = []
	for pf in FactionData.TERRITORIAL_PIRATES:
		var bs := -1.0
		var pick := -1
		for s in systems:
			var sid: int = s["id"]
			if owner.has(sid):
				continue
			var dcap := 99
			for c in caps:
				dcap = mini(dcap, int(hops[sid][c]))
			var dp := 99
			for pc in pirate_cores:
				dp = mini(dp, int(hops[sid][pc]))
			var sc := float(dcap) * 100.0 + float(mini(dp, 4)) * 60.0 - (s["links"] as Dictionary).size() * 5.0 + trng.randf()
			if sc > bs:
				bs = sc
				pick = sid
		pirate_cores.append(pick)
		owner[pick] = pf
		systems[pick]["capital"] = true
	# grow: pirates first (small, tight hideouts), then the powers in turns
	var cores := {}
	for i in 3:
		cores[powers[i]] = caps[i]
	for i in pirate_cores.size():
		cores[FactionData.TERRITORIAL_PIRATES[i]] = pirate_cores[i]
	var count := {}
	for f in cores:
		count[f] = 1
	for pf2 in FactionData.TERRITORIAL_PIRATES:
		while int(count[pf2]) < PIRATE_SYSTEMS:
			var nxt := _territory_candidate(pf2, owner, cores, hops)
			if nxt < 0:
				break
			owner[nxt] = pf2
			count[pf2] = int(count[pf2]) + 1
	var grew := true
	while grew:
		grew = false
		for pw in powers:
			if int(count[pw]) >= POWER_SYSTEMS_MAX:
				continue
			var nxt2 := _territory_candidate(pw, owner, cores, hops)
			if nxt2 < 0:
				continue
			owner[nxt2] = pw
			count[pw] = int(count[pw]) + 1
			grew = true
	# contested borders: frontier systems where two powers meet (farthest from the own capital)
	var front: Array = []
	for sid2 in owner:
		var f2: String = owner[sid2]
		if not f2 in FactionData.POWERS or systems[sid2]["capital"]:
			continue
		var rival := ""
		for nb in systems[sid2]["links"]:
			var o2: String = owner.get(nb, "")
			if o2 != f2 and o2 in FactionData.POWERS:
				rival = o2
		if rival != "":
			front.append([sid2, rival, int(hops[sid2][cores[f2]])])
	front.sort_custom(func(x, y): return x[2] > y[2] if x[2] != y[2] else int(x[0]) < int(y[0]))
	var target_contested := maxi(0, n - POWER_SYSTEMS * 3 - PIRATE_SYSTEMS * 2)
	var contested := 0
	for unclaimed in n:
		if not owner.has(unclaimed):
			contested += 1
	for fr in front:
		var f3: String = owner.get(fr[0], "")
		if f3 == "":
			continue
		var over := false
		for pw2 in powers:
			over = over or int(count[pw2]) > POWER_SYSTEMS
		if contested >= target_contested and not over:
			break
		if int(count[f3]) <= POWER_SYSTEMS and contested >= target_contested:
			continue
		owner.erase(fr[0])
		count[f3] = int(count[f3]) - 1
		systems[fr[0]]["claimants"] = [f3, fr[1]]
		contested += 1
	# write back + security
	for s2 in systems:
		var sid3: int = s2["id"]
		var f4: String = owner.get(sid3, "")
		s2["faction"] = f4
		if f4 == "" and (s2["claimants"] as Array).is_empty():
			var cl: Array = []
			for nb2 in s2["links"]:
				var o3: String = owner.get(nb2, "")
				if o3 != "" and not o3 in cl:
					cl.append(o3)
			cl.sort_custom(func(x, y): return int(x in FactionData.POWERS) > int(y in FactionData.POWERS))
			s2["claimants"] = cl.slice(0, 2)
		var sec := 0.25
		if f4 in FactionData.POWERS:
			var dist: int = hops[sid3][cores[f4]]
			s2["core_dist"] = dist
			sec = 1.0 - 0.1 * dist
			for nb3 in s2["links"]:
				var o4: String = owner.get(nb3, "")
				if o4 in FactionData.PIRATES or o4 == "":
					sec -= 0.07
					break
			sec = clampf(sec + trng.randf_range(-0.04, 0.04), 0.35, 1.0)
			if s2["capital"]:
				sec = 1.0
		elif f4 in FactionData.PIRATES:
			var dist2: int = hops[sid3][cores[f4]]
			s2["core_dist"] = dist2
			sec = clampf(0.03 * dist2 + trng.randf_range(0.0, 0.06), 0.0, 0.15)
		else:
			sec = trng.randf_range(0.18, 0.34)
		s2["security"] = snappedf(sec, 0.01)
	# the pilot starts in a border system of the Assembly (not its capital)
	var best_home := -1
	var best_h := -INF
	for s3 in systems:
		if s3["faction"] != "assembly" or s3["capital"]:
			continue
		var border := false
		for nb4 in s3["links"]:
			border = border or systems[nb4]["faction"] != "assembly"
		var hs := float(s3["security"]) + (1.0 if border else 0.0) - absf(int(s3["core_dist"]) - 2) * 0.2
		if hs > best_h:
			best_h = hs
			best_home = s3["id"]
	if best_home < 0:
		best_home = cores["assembly"]
	home_system = best_home
	systems[home_system]["security"] = maxf(float(systems[home_system]["security"]), 0.7)


## Next system a faction claims: an unowned neighbour of its territory, closest to its core.
func _territory_candidate(f: String, owner: Dictionary, cores: Dictionary, hops: Array) -> int:
	var core: int = cores[f]
	var best := -1
	var bd := INF
	for sid in owner:
		if owner[sid] != f:
			continue
		for nb in systems[sid]["links"]:
			if owner.has(nb):
				continue
			var d := float(hops[nb][core]) * 1000.0 + _dist(nb, core)
			if d < bd:
				bd = d
				best = nb
	return best


## Controlling faction of a system ("" = contested or independent).
func controller(sid: int) -> String:
	if sid < 0 or sid >= systems.size():
		return ""
	return String(systems[sid].get("faction", ""))


func claimants(sid: int) -> Array:
	if sid < 0 or sid >= systems.size():
		return []
	return systems[sid].get("claimants", [])


## "Cluster Assembly", "Contested (Assembly / Covenant)", "Pirate territory – Hollow Crown" …
func territory_text(sid: int) -> String:
	var f := controller(sid)
	if f != "":
		var t := FactionData.name_of(f)
		if FactionData.FACTIONS[f]["kind"] == "pirate":
			t = "Pirate territory – " + t
		if systems[sid].get("capital", false):
			t += " (capital)" if FactionData.FACTIONS[f]["kind"] == "power" else " (stronghold)"
		return t
	var cl := claimants(sid)
	if cl.is_empty():
		return "Independent"
	var names: PackedStringArray = []
	for c in cl:
		names.append(FactionData.short_of(c))
	return "Contested (%s)" % " / ".join(names)


## Faction of a station: the system owner; in contested systems the claimants share the
## stations; stations in pirate territory are independent free ports (only Havens fly the flag).
func station_faction(sid: int, index: int) -> String:
	var f := controller(sid)
	if f in FactionData.POWERS:
		return f
	if f == "":
		var cl: Array = []
		for c in claimants(sid):
			if c in FactionData.POWERS:
				cl.append(c)
		if not cl.is_empty():
			return cl[index % cl.size()]
	return ""


## Which pirate faction a pirate spawned in this system belongs to.
func pirate_faction(sid: int) -> String:
	var f := controller(sid)
	if f in FactionData.TERRITORIAL_PIRATES:
		return f if randf() < 0.8 else "free_captains"
	for c in claimants(sid):
		if c in FactionData.TERRITORIAL_PIRATES and randf() < 0.5:
			return c
	return "free_captains"


## Systems of a faction.
func territory_of(f: String) -> Array:
	var out: Array = []
	for s in systems:
		if s.get("faction", "") == f:
			out.append(int(s["id"]))
	return out


# ---------------------------------------------------------------- Population & traffic (phase 0.5 package 11)

## Inhabitants per planet type (billions): earthlike worlds carry most of the population.
const PLANET_POP := {"terran": 3.0, "desert": 1.0, "ice": 0.8, "toxic": 0.3, "lava": 0.25, "gas": 0.2, "barren": 0.1}
## Upper limit of NPC ships in one system (player excluded).
const NPC_CAP := 60


## What lives in a system: population (from the planets), stations, and from that the size of
## its traffic – shuttles, miners, patrols, convoy weight and pirate pressure.
func system_profile(sid: int) -> Dictionary:
	var L := get_layout(sid)
	var sys: Dictionary = systems[sid]
	var pop := 0.0
	for p in L["planets"]:
		pop += float(PLANET_POP.get(String(p["type"]), 0.1)) * (1.4 if p.get("ring", false) else 1.0) * (0.6 + float(p.get("seed", 50.0)) / 125.0)
	var tiers := 0
	var trade := 0
	var military := 0
	var mining := 0
	var ice := 0
	for st in L["stations"]:
		var t := int(st["tier"])
		tiers += t
		match String(st["type"]):
			"trade":
				trade += t
			"military":
				military += t
			"mining_colony":
				mining += t
			"ice_refinery":
				ice += t
	var sec := float(sys["security"])
	var ctl := controller(sid)
	var patrol_groups := 0
	var patrol_size := 0
	var patrol_q := 0                 # 0 light … 2 heavy
	if ctl in FactionData.POWERS:
		patrol_groups = 1 + int(military >= 2) + int(sys.get("capital", false)) + int(sec >= 0.8 and tiers >= 3)
		patrol_size = 2 + int(military >= 3)
		patrol_q = clampi(int(military / 2) + int(sys.get("capital", false)), 0, 2)
	elif ctl == "" and not claimants(sid).is_empty():
		for c in claimants(sid):
			patrol_groups += int(c in FactionData.POWERS)
		patrol_size = 2
		patrol_q = clampi(int(military / 2), 0, 1)
	var has_st: bool = not L["stations"].is_empty()
	var nf: int = L["fields"].size()
	var lawful := ctl in FactionData.POWERS or (ctl == "" and patrol_groups > 0)
	return {
		"population": pop,
		"stations": L["stations"].size(), "tiers": tiers, "trade": trade, "military": military,
		"mining": mining, "ice": ice,
		"shuttles": clampi(int(round(pop * 2.0 + tiers * 0.6)), 0, 16) if has_st else 0,
		"miners": clampi((mining + ice) * 2 + 1, 0, 10) if mining + ice > 0 else (2 if nf > 0 else 0),
		# loiterers (they stay around one place): haulers holding near stations, field patrols, gate pickets
		"holding": clampi(tiers + 1, 0, 8) if has_st else 0,
		"field_patrols": mini(nf, 3) if lawful else 0,
		"pickets": mini(L["gates"].size(), 2) if ctl in FactionData.POWERS else 0,
		"patrol_groups": patrol_groups, "patrol_size": patrol_size, "patrol_quality": patrol_q,
		"convoy_weight": trade * 2.0 + (tiers - trade) * 0.5,
		"pirates": int(round((1.0 - sec) * 4.0)),
	}


## Short traffic rating for the map ("busy" …).
static func traffic_word(p: Dictionary) -> String:
	var v := int(p["shuttles"]) + int(p["miners"]) + int(p["patrol_groups"]) * 2 + int(p.get("holding", 0)) + int(p.get("field_patrols", 0)) * 2 + int(p.get("pickets", 0))
	if v >= 30:
		return "very busy"
	if v >= 15:
		return "busy"
	if v >= 3:
		return "moderate"
	return "quiet" if v > 0 else "deserted"



static func _shuffle(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var tmp = a[i]
		a[i] = a[j]
		a[j] = tmp


# ---------------------------------------------------------------- Debug test system
# A single system without gates that contains every station type (plus tier 1–3 Trade Hubs),
# a Pirate Haven, every planet type, all three asteroid field classes with every ore, every
# asteroid shape and size, and colossi in all class/shape combinations. Only reachable from the
# main menu in debug builds; it is never saved and does not touch the generated galaxy.

## Test system: every station type in tiers 1, 2 and 3 (three rings, one spoke per type).
const TEST_RING := [900000.0, 1150000.0, 1400000.0]


func generate_test() -> void:
	seed_value = 777
	systems.clear()
	layouts.clear()
	systems.append({"id": 0, "name": "Testfeld", "pos": MAP_SIZE * 0.5, "security": 0.5, "star": 0, "links": {},
		"faction": "", "claimants": ["assembly", "covenant"], "capital": false, "core_dist": 0})
	home_system = 0
	test_mode = true
	layouts[0] = build_test_layout()


## The test system's layout (pure: reads only seed_value for the scenery).
func build_test_layout() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	var st_type: Dictionary = STAR_TYPES[0]
	var L := {
		"star": {"id": "star", "name": "Testfeld", "type": st_type["name"], "color": st_type["color"],
			"radius": float(st_type["radius"]), "pos": Vector2.ZERO},
		"planets": [], "stations": [], "gates": [], "fields": [], "asteroids": [], "anomalies": [], "colossi": [], "havens": [],
	}
	# every planet type in a row
	var ptypes: Array = PLANET_TYPES.keys()
	for i in ptypes.size():
		var pt: String = ptypes[i]
		var big := pt in ["gas", "toxic"]
		var pos := Vector2.from_angle(-PI * 0.5 + i * TAU / ptypes.size()) * 600000.0
		L["planets"].append({
			"id": "p%d" % i, "name": "Testfeld %s – %s" % [ROMAN[i], PLANET_TYPES[pt]["name"]], "type": pt,
			"orbit": pos.length(), "pos": pos, "radius": 22000.0 if big else 9000.0,
			"seed": 10.0 + i * 7.0, "ring": big,
		})
	# every station type in every tier: tier 1 on the inner ring, tier 3 on the outer one
	var n_types := ALL_STATION_TYPES.size()
	for tier in [1, 2, 3]:
		for i in n_types:
			var type: String = ALL_STATION_TYPES[i]
			var pos2 := Vector2.from_angle(PI * 0.5 + i * TAU / n_types) * float(TEST_RING[tier - 1])
			L["stations"].append({
				"id": "st_0_%d" % L["stations"].size(), "planet": 0,
				"name": "Testfeld – %s (T%d)" % [CommodityData.STATION_TYPES[type]["name"], tier],
				"type": type, "tier": tier, "pos": pos2,
				"market": _make_market(type, rng), "shop": _make_shop(type, tier, rng), "shipyard": _make_shipyard(type, tier, true),
				"seed": 1000 + i * 37, "zone": NO_FIRE_ZONE[tier - 1],
				"faction": FactionData.POWERS[(i + tier) % 3],
			})
	for stf in L["stations"]:
		_add_faction_yard(stf)
	# move the tier-3 Trade Hub to the front: the pilot starts there
	var start: Dictionary = L["stations"][2 * n_types]
	L["stations"].remove_at(2 * n_types)
	L["stations"].insert(0, start)
	for k in L["stations"].size():
		L["stations"][k]["id"] = "st_0_%d" % k
	# package 26: a waystation of every tier
	for wt in [1, 2, 3]:
		L["stations"].append({
			"id": "st_0_%d" % L["stations"].size(), "planet": 0,
			"name": "Testfeld – Waystation (T%d)" % wt, "type": "waystation", "tier": wt,
			"pos": Vector2.from_angle(-PI * 0.5 + 0.25 * wt) * 1300000.0,
			"market": _make_market("waystation", rng), "shop": _make_shop("waystation", wt, rng), "shipyard": [],
			"seed": 2000 + wt, "zone": NO_FIRE_ZONE[wt - 1], "faction": FactionData.POWERS[wt % 3],
		})
	# Pirate Havens of all tiers on the edge (between the asteroid fields)
	for tier2 in [1, 2, 3]:
		L["havens"].append({"id": "ph_0_%d" % tier2, "name": "Rustmaw T%d (Test)" % tier2, "type": "pirate_haven", "tier": tier2,
			"pos": Vector2.from_angle([0.35, PI, PI * 1.5][tier2 - 1]) * 1780000.0, "seed": 4242 + tier2,
			"faction": FactionData.PIRATES[tier2 - 1]})
		_haven_services(L["havens"].back(), 0)
	# one field per asteroid class with every ore of that class; colossi in all three shapes
	for b in FIELD_CLASSES.size():
		var cls: String = FIELD_CLASSES[b]
		var mix := {}
		for cid in CommodityData.COMMODITIES:
			var c: Dictionary = CommodityData.COMMODITIES[cid]
			if c.get("category", "") == "ore" and c["class"] == cls:
				mix[cid] = {"common": 3.0, "uncommon": 1.5, "rare": 1.0}[c["rarity"]]
		var fid := "f%d" % b
		var fc := Vector2.from_angle(PI * 0.75 + b * PI * 0.5) * 1750000.0
		var fr := 14000.0
		L["fields"].append({"id": fid, "name": "Test Field %s (%s)" % [ROMAN[b], cls.capitalize()],
			"class": cls, "ores": mix.keys(), "ore": mix.keys()[0], "pos": fc, "radius": fr})
		var clumps: Array = []
		for k in 6:
			clumps.append([fc + Vector2.from_angle(k * TAU / 6.0 + 0.3) * fr * rng.randf_range(0.25, 0.6), rng.randf_range(900.0, 1800.0)])
		for k in 180:
			var clump: Array = clumps[k % clumps.size()]
			var ap: Vector2 = clump[0] + Vector2.from_angle(rng.randf() * TAU) * pow(rng.randf(), 0.7) * float(clump[1])
			L["asteroids"].append(_make_asteroid("a_%d_%d" % [b, k], fid, cls, mix, ap, rng))
		for k in ColossusShape.SHAPES.size():
			var shape: String = ColossusShape.SHAPES[k]
			var R := rng.randf_range(900.0, 1300.0)
			var cpos := fc + Vector2.from_angle(-0.6 + k * 0.6 + PI) * fr * 0.78
			L["colossi"].append({
				"id": "col_%d_%d" % [b, k], "name": "Colossus T-%d%d" % [b + 1, k + 1], "class": cls, "ore": _roll_ore(mix, rng),
				"pos": cpos, "radius": R, "shape": shape, "poly": ColossusShape.generate(shape, R, rng), "seed": rng.randi(), "field": fid,
			})
	# a few anomalies, already revealed
	for k in 3:
		L["anomalies"].append({
			"id": "an_%d" % k, "name": ANOMALY_NAMES[k % ANOMALY_NAMES.size()],
			"pos": Vector2.from_angle(PI * 0.1 + k * 0.5) * 420000.0,
			"difficulty": 10.0 + k * 15.0, "scan": 100.0, "revealed": true, "analysis": 0.0, "done": false,
		})
	_scatter_loose(L, 0, 0.5)
	_clear_colossi(L)
	return L


# ---------------------------------------------------------------- Save / load
# The galaxy itself is regenerated from the seed; only what changed is stored:
# remaining asteroid deposits and the scan/analysis state of anomalies.

func to_dict() -> Dictionary:
	var changed := {}
	for id in layouts:
		var L: Dictionary = layouts[id]
		var ast := {}
		for a in L["asteroids"]:
			ast[a["id"]] = a["amount"]
		var an := {}
		for x in L["anomalies"]:
			an[x["id"]] = {"scan": x["scan"], "revealed": x["revealed"], "analysis": x["analysis"], "done": x["done"]}
		changed[id] = {"asteroids": ast, "anomalies": an}
	return {"seed": seed_value, "version": GALAXY_VERSION, "layouts": changed}


func from_dict(d: Dictionary) -> void:
	generate(int(d["seed"]))
	var changed: Dictionary = d.get("layouts", {})
	for id in changed:
		var L := get_layout(int(id))
		var ast: Dictionary = changed[id]["asteroids"]
		for a in L["asteroids"]:
			if ast.has(a["id"]):
				a["amount"] = ast[a["id"]]
		var an: Dictionary = changed[id]["anomalies"]
		for x in L["anomalies"]:
			if an.has(x["id"]):
				x.merge(an[x["id"]], true)


func _dist(a: int, b: int) -> float:
	return (systems[a]["pos"] as Vector2).distance_to(systems[b]["pos"])


func _link(a: int, b: int) -> void:
	var d := _dist(a, b)
	var cls := 1
	if d >= 340.0:
		cls = 3
	elif d >= 250.0:
		cls = 2
	systems[a]["links"][b] = cls
	systems[b]["links"][a] = cls


func _build_routes(rng: RandomNumberGenerator) -> void:
	# Minimum spanning tree (Prim) guarantees that every system is reachable.
	var n := systems.size()
	var in_tree := {0: true}
	while in_tree.size() < n:
		var best_d := INF
		var ba := -1
		var bb := -1
		for a in in_tree.keys():
			for b in n:
				if in_tree.has(b):
					continue
				var d := _dist(a, b)
				if d < best_d:
					best_d = d
					ba = a
					bb = b
		_link(ba, bb)
		in_tree[bb] = true
	# Extra connections create loops / alternative routes.
	for a in n:
		var cand: Array = []
		for b in n:
			if b != a and not systems[a]["links"].has(b):
				cand.append(b)
		cand.sort_custom(func(x, y): return _dist(a, x) < _dist(a, y))
		if cand.is_empty():
			continue
		var c: int = cand[0]
		if systems[a]["links"].size() < 3 and systems[c]["links"].size() < 4 and _dist(a, c) < 360.0 and rng.randf() < 0.75:
			_link(a, c)


## Shortest route (number of jumps), only via routes with class <= max_class.
## Returns the list of systems excluding the start system; [] if unreachable.
func find_path(from: int, to: int, max_class: int) -> Array:
	if from == to:
		return []
	var prev := {from: -1}
	var queue: Array = [from]
	while not queue.is_empty():
		var cur: int = queue.pop_front()
		if cur == to:
			break
		for nb in systems[cur]["links"]:
			if prev.has(nb):
				continue
			if int(systems[cur]["links"][nb]) > max_class:
				continue
			prev[nb] = cur
			queue.append(nb)
	if not prev.has(to):
		return []
	var path: Array = []
	var c := to
	while c != from:
		path.push_front(c)
		c = prev[c]
	return path


func route_class(a: int, b: int) -> int:
	return int(systems[a]["links"].get(b, 99))


func get_layout(id: int) -> Dictionary:
	if not layouts.has(id):
		layouts[id] = _generate_layout(id)
	return layouts[id]


func get_gate_pos(system_id: int, to_id: int) -> Vector2:
	for g in get_layout(system_id)["gates"]:
		if int(g["to"]) == to_id:
			return g["pos"]
	return Vector2.ZERO


func find_station(system_id: int, station_id: String) -> Dictionary:
	var L := get_layout(system_id)
	for st in L["stations"]:
		if st["id"] == station_id:
			return st
	for ph in L.get("havens", []):
		if ph["id"] == station_id:
			return ph
	return {}


const PLANET_TYPES := {
	"terran": {"name": "Terran", "a": Color(0.13, 0.28, 0.58), "b": Color(0.3, 0.55, 0.28), "c": Color(0.88, 0.9, 0.85), "atmo": Color(0.5, 0.75, 1.0, 0.8), "gas": 0.0},
	"desert": {"name": "Desert World", "a": Color(0.62, 0.38, 0.22), "b": Color(0.85, 0.62, 0.36), "c": Color(0.95, 0.85, 0.6), "atmo": Color(1.0, 0.8, 0.5, 0.45), "gas": 0.0},
	"ice": {"name": "Ice World", "a": Color(0.45, 0.62, 0.8), "b": Color(0.75, 0.87, 0.97), "c": Color(1.0, 1.0, 1.0), "atmo": Color(0.75, 0.9, 1.0, 0.5), "gas": 0.0},
	"lava": {"name": "Lava World", "a": Color(1.0, 0.45, 0.1), "b": Color(0.28, 0.13, 0.1), "c": Color(0.15, 0.08, 0.07), "atmo": Color(1.0, 0.4, 0.2, 0.5), "gas": 0.0},
	"gas": {"name": "Gas Giant", "a": Color(0.68, 0.48, 0.32), "b": Color(0.86, 0.7, 0.5), "c": Color(0.96, 0.9, 0.76), "atmo": Color(1.0, 0.85, 0.6, 0.4), "gas": 1.0},
	"toxic": {"name": "Toxic Gas Giant", "a": Color(0.35, 0.5, 0.18), "b": Color(0.58, 0.74, 0.3), "c": Color(0.82, 0.88, 0.45), "atmo": Color(0.7, 1.0, 0.4, 0.55), "gas": 1.0},
	"barren": {"name": "Barren Rock", "a": Color(0.33, 0.32, 0.34), "b": Color(0.48, 0.47, 0.47), "c": Color(0.64, 0.62, 0.6), "atmo": Color(0.0, 0.0, 0.0, 0.0), "gas": 0.0},
}


## Layout of a system (all positions in km, star at the origin):
## star, planets, stations, gates, fields (asteroid fields), asteroids, anomalies (hidden)
func _generate_layout(id: int) -> Dictionary:
	var sys: Dictionary = systems[id]
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 7919 + id * 104729
	var sec: float = sys["security"]
	var st_type: Dictionary = STAR_TYPES[sys["star"]]
	var L := {
		"star": {"id": "star", "name": sys["name"], "type": st_type["name"], "color": st_type["color"],
			"radius": float(st_type["radius"]), "pos": Vector2.ZERO},
		"planets": [], "stations": [], "gates": [], "fields": [], "asteroids": [], "anomalies": [], "colossi": [], "havens": [],
	}
	var used: Array = []
	# Planets
	var planet_count := rng.randi_range(3, 6)
	var ptypes: Array = PLANET_TYPES.keys()
	for i in planet_count:
		var orbit := 260000.0 + i * 290000.0 + rng.randf_range(-40000.0, 40000.0)
		var pos := Vector2.from_angle(rng.randf() * TAU) * orbit
		var ptype: String = ptypes[rng.randi() % ptypes.size()]
		if i == 0 and rng.randf() < 0.5:
			ptype = "lava"
		var big := ptype in ["gas", "toxic"]
		used.append(pos)
		L["planets"].append({
			"id": "p%d" % i, "name": "%s %s" % [sys["name"], ROMAN[i]], "type": ptype, "orbit": orbit, "pos": pos,
			"radius": rng.randf_range(6000.0, 12000.0) * (2.6 if big else 1.0),
			"seed": rng.randf_range(0.0, 100.0), "ring": big and rng.randf() < 0.6,
		})
	# Stations orbit planets (type and tier come from the cluster-wide plan)
	var plan: Array = sys.get("stations_plan", [])
	var station_planets: Array = []
	for i in plan.size():
		var pidx: int = rng.randi() % L["planets"].size()
		if pidx in station_planets:
			pidx = (pidx + 1) % L["planets"].size()
		station_planets.append(pidx)
		var planet: Dictionary = L["planets"][pidx]
		var type: String = plan[i][0]
		var tier: int = plan[i][1]
		var tdef: Dictionary = CommodityData.STATION_TYPES[type]
		var off := Vector2.from_angle(rng.randf() * TAU) * (float(planet["radius"]) * 1.7 + rng.randf_range(3000.0, 6000.0))
		L["stations"].append({
			"id": "st_%d_%d" % [id, i], "planet": pidx,
			"name": "%s – %s" % [planet["name"], tdef["name"]],
			"type": type, "tier": tier, "pos": (planet["pos"] as Vector2) + off,
			"market": _make_market(type, rng),
			"shop": _make_shop(type, tier, rng),
			"shipyard": _make_shipyard(type, tier, Missions.wealthy(id)),
		})
	# Hyperspace gates – direction matches the neighbour's position on the galaxy map
	for nb in sys["links"]:
		var dir := ((systems[nb]["pos"] as Vector2) - (sys["pos"] as Vector2)).normalized()
		used.append(dir * GATE_DISTANCE)
		L["gates"].append({
			"id": "g_%d_%d" % [id, nb], "to": nb, "class": int(sys["links"][nb]),
			"pos": dir * GATE_DISTANCE, "name": "Gate to %s" % systems[nb]["name"],
		})
	# Asteroid fields: metallic near the star, stony in between, icy beyond the frost line
	var frost: float = FROST_SCALE.get(STAR_TYPES[int(sys["star"])]["name"], 1.0)
	var need_icy := false
	for pe in plan:
		need_icy = need_icy or pe[0] == "ice_refinery"
	var has_icy := false
	var nf := rng.randi_range(2, 4)
	for b in nf:
		var cls: String = FIELD_CLASSES[rng.randi() % FIELD_CLASSES.size()]
		if b == nf - 1 and need_icy and not has_icy:
			cls = "icy"          # an Ice Refinery always has an icy field nearby
		has_icy = has_icy or cls == "icy"
		var band: Vector2 = FIELD_BANDS[cls]
		var center := _free_spot(rng, used, minf(band.x * frost, 1600000.0), minf(band.y * frost, 1850000.0))
		var mix := _field_mix(cls, sec, rng)
		var fid := "f%d" % b
		var fradius := rng.randf_range(10000.0, 16000.0)
		L["fields"].append({"id": fid, "name": "Asteroid Field %s (%s)" % [ROMAN[b], cls.capitalize()],
			"class": cls, "ores": mix.keys(), "ore": mix.keys()[0], "pos": center, "radius": fradius})
		# Asteroids gather in clumps inside the field
		var clumps: Array = []
		for c in rng.randi_range(4, 7):
			clumps.append([center + Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * fradius * 0.8, rng.randf_range(700.0, 2000.0)])
		for k in rng.randi_range(70, 130):
			var clump: Array = clumps[rng.randi() % clumps.size()]
			var pos: Vector2 = clump[0] + Vector2.from_angle(rng.randf() * TAU) * pow(rng.randf(), 0.7) * float(clump[1])
			L["asteroids"].append(_make_asteroid("a_%d_%d" % [b, k], fid, cls, mix, pos, rng))
	# Hidden anomalies (must be scanned down)
	for k in rng.randi_range(2, 4):
		var diff := lerpf(8.0, 40.0, 1.0 - sec) + rng.randf_range(0.0, 10.0)
		var an := {
			"id": "an_%d" % k, "name": ANOMALY_NAMES[rng.randi() % ANOMALY_NAMES.size()],
			"pos": _free_spot(rng, used, 300000.0, 1800000.0),
			"difficulty": diff, "scan": 0.0, "revealed": false, "analysis": 0.0, "done": false,
		}
		# package 25g: a few rare anomalies hold exotic matter (decided by a hash – the layout stays as it was)
		if posmod(seed_value * 31 + id * 1013 + k * 7919, 100) < 14:
			an["exotic"] = true
			an["name"] = "Exotic Matter Signature"
			an["difficulty"] = diff + 10.0
		L["anomalies"].append(an)
	_special_stations(L, id, sec)
	_scatter_loose(L, id, sec)
	_place_colossi(L, id, sec)
	return L


## Package 26: a waystation (station type 0: landing pads for S and M ships) in most systems – out on the
## way to one of the gates. Own RNG.
const WAYSTATION_SHARE := 0.75


func _add_waystation(L: Dictionary, id: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 52711 + id * 3301 + 11
	if L["gates"].is_empty() or L["planets"].is_empty() or rng.randf() > WAYSTATION_SHARE:
		return
	var g: Dictionary = L["gates"][rng.randi() % L["gates"].size()]
	var gp: Vector2 = g["pos"]
	var pos := gp * rng.randf_range(0.5, 0.75) + gp.normalized().orthogonal() * rng.randf_range(-60000.0, 60000.0)
	var pidx := 0
	var bd := INF
	for i in L["planets"].size():
		var d := (L["planets"][i]["pos"] as Vector2).distance_to(pos)
		if d < bd:
			bd = d
			pidx = i
	var r := rng.randf()
	var tier := 1 if r < 0.55 else (2 if r < 0.88 else 3)
	L["stations"].append({
		"id": "st_%d_%d" % [id, L["stations"].size()], "planet": pidx,
		"name": "%s Waystation" % systems[id]["name"],
		"type": "waystation", "tier": tier, "pos": pos,
		"market": _make_market("waystation", rng),
		"shop": _make_shop("waystation", tier, rng),
		"shipyard": [],
	})


## Phase 0.5 package 6: art seed + no-fire zone for every station, Ice Refineries next to icy
## fields, Shipyard Complexes in safe systems, Pirate Havens in lawless ones. Own RNG keeps the
## base layout (and saves) stable.
func _special_stations(L: Dictionary, id: int, sec: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 70001 + id * 9173 + 3
	_add_waystation(L, id)
	var si := 0
	for st in L["stations"]:
		st["seed"] = rng.randi()
		st["zone"] = NO_FIRE_ZONE[clampi(int(st["tier"]), 1, 3) - 1]
		st["faction"] = station_faction(id, si)
		_add_faction_yard(st)
		si += 1
	# Pirate Haven (planned for lawless systems): hostile scenery, docking needs reputation – later
	var htier := int(systems[id].get("haven_tier", 0))
	if htier <= 0:
		return
	for attempt in 80:
		var pos := Vector2.ZERO
		if not L["fields"].is_empty() and rng.randf() < 0.6:
			var f: Dictionary = L["fields"][rng.randi() % L["fields"].size()]
			pos = (f["pos"] as Vector2) + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(30000.0, 60000.0)
		else:
			pos = Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(400000.0, 1600000.0)
		var ok := true
		for o in L["stations"]:
			ok = ok and (o["pos"] as Vector2).distance_to(pos) > 120000.0
		for g in L["gates"]:
			ok = ok and (g["pos"] as Vector2).distance_to(pos) > 80000.0
		for p in L["planets"]:
			ok = ok and (p["pos"] as Vector2).distance_to(pos) > float(p["radius"]) * 3.0
		if ok or attempt == 79:
			var hv := {"id": "ph_%d" % id, "name": "%s %s" % [HAVEN_NAMES[rng.randi() % HAVEN_NAMES.size()], ROMAN[rng.randi_range(1, 4)]],
				"type": "pirate_haven", "tier": htier, "pos": pos, "seed": rng.randi(),
				"faction": controller(id) if controller(id) in FactionData.PIRATES else "free_captains"}
			_haven_services(hv, id)
			L["havens"].append(hv)
			break


## Black market, outfitter and docks of a Pirate Haven (package 12: dockable with pirate
## standing). Own RNG so the rest of the layout stays unchanged; no no-fire zone.
func _haven_services(hv: Dictionary, id: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 91807 + id * 4421 + 7
	hv["zone"] = 0.0
	hv["market"] = _make_market("pirate_haven", rng)
	hv["shop"] = _make_shop("pirate_haven", int(hv["tier"]), rng)
	hv["shipyard"] = ["crow"]       # the pirates' own patched-together raider (package 19)


## Colossal asteroids (phase 0.5 package 5): rocks up to ~2,800 km long in the foreground of
## asteroid fields, usually two or three per field. Ships must fly around them, they cast a radar
## shadow and block line of sight. Each has an irregular outline (potato, contact binary or angular
## shard, see ColossusShape); their rim holds richer mineable rock. Anything that would end up
## inside a colossus is removed. Own RNG keeps older layouts stable.
func _place_colossi(L: Dictionary, id: int, sec: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 48611 + id * 6007 + 11
	var n := 0
	for f in L["fields"]:
		if rng.randf() > lerpf(0.55, 0.9, 1.0 - sec):
			continue
		var fc: Vector2 = f["pos"]
		var fr: float = f["radius"]
		var cls: String = f["class"]
		var mix := _field_mix(cls, sec, rng)
		var want := rng.randi_range(2, 3)
		var placed := 0
		# the group sits together in one part of the field
		var group_dir := rng.randf() * TAU
		for attempt in 40:
			if placed >= want:
				break
			var R := rng.randf_range(800.0, 1400.0) if placed == 0 else rng.randf_range(400.0, 1000.0)
			var dist := rng.randf_range(0.2, 0.85) * fr
			var pos := fc + Vector2.from_angle(group_dir + rng.randf_range(-0.9, 0.9)) * dist
			# keep the warp arrival ring (half the field radius) and the field centre clear
			if absf(pos.distance_to(fc) - fr * 0.5) < R + 1500.0 or pos.distance_to(fc) < R + 1500.0:
				continue
			var ok := true
			for o in L["stations"] + L["gates"]:
				if (o["pos"] as Vector2).distance_to(pos) < R + 8000.0:
					ok = false
			for o2 in L["colossi"]:
				var gap := pos.distance_to(o2["pos"]) - R - float(o2["radius"])
				if gap < 900.0 or (placed > 0 and String(o2["field"]) == String(f["id"]) and gap > 7000.0):
					ok = false
			if not ok:
				continue
			var shape: String = ColossusShape.SHAPES[rng.randi() % ColossusShape.SHAPES.size()]
			var poly := ColossusShape.generate(shape, R, rng)
			var col := {
				"id": "col_%d" % n, "name": "Colossus %s-%d" % [COLOSSUS_PREFIX[rng.randi() % COLOSSUS_PREFIX.size()], rng.randi_range(2, 98)],
				"class": cls, "ore": _roll_ore(mix, rng), "pos": pos, "radius": R, "shape": shape, "poly": poly,
				"seed": rng.randi(), "field": f["id"],
			}
			L["colossi"].append(col)
			n += 1
			placed += 1
			# Rim: mineable rock hugging the surface
			for k in rng.randi_range(4, 7):
				var edge := rng.randi() % poly.size()
				var sp: Vector2 = poly[edge].lerp(poly[(edge + 1) % poly.size()], rng.randf())
				var ast := _make_asteroid("cr_%d_%d" % [n, k], String(f["id"]), cls, mix, pos, rng)
				if ast["size"] == "small":
					ast["size"] = "medium"
					ast["radius"] = rng.randf_range(25.0, 60.0)
				ast["pos"] = pos + sp + sp.normalized() * (float(ast["radius"]) + rng.randf_range(40.0, 260.0))
				ast["near"] = col["name"]
				ast["amount"] = float(ast["amount"]) * 1.4
				L["asteroids"].append(ast)
	_clear_colossi(L)


## Removes asteroids and debris that would sit inside a colossus.
func _clear_colossi(L: Dictionary) -> void:
	for col2 in L["colossi"]:
		var cp: Vector2 = col2["pos"]
		var cr := float(col2["radius"])
		var cpoly: PackedVector2Array = col2["poly"]
		var clear := func(o) -> bool:
			var rel: Vector2 = (o["pos"] as Vector2) - cp
			if rel.length() > cr + float(o["radius"]) + 20.0:
				return true
			return ColossusShape.signed_dist(cpoly, rel) > float(o["radius"]) + 20.0
		L["asteroids"] = L["asteroids"].filter(clear)
		L["debris"] = L["debris"].filter(clear)


## Asteroids outside the fields (phase 0.5 package 4): rings of rock around planets, small
## clusters at gates, stations and anomalies. Most are scenery ("debris", drawn by SystemView,
## not selectable); some are real, mineable asteroids. A separate RNG keeps older layouts stable.
func _scatter_loose(L: Dictionary, id: int, sec: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 92821 + id * 7177 + 5
	L["debris"] = []
	var n := 0
	for p in L["planets"]:
		var cls: String = PLANET_ROCK_CLASS.get(p["type"], "stony")
		var pr: float = p["radius"]
		var inner := pr * (1.7 if p.get("ring", false) else 1.35)
		var outer := inner + pr * rng.randf_range(0.5, 1.1)
		var tilt := rng.randf() * TAU
		var flat := rng.randf_range(0.35, 0.8)     # ellipse = ring seen at an angle
		var mix := _field_mix(cls, sec, rng)
		# Rocks gather in dense clusters spaced around the ring (a uniform ring at real scale
		# would be far too thin to ever see more than one rock at a time)
		var circ := TAU * (inner + outer) * 0.5
		var clusters := int(clampf(circ / 9000.0, 8.0, 24.0))
		for c in clusters:
			var a := TAU * c / clusters + rng.randf_range(-0.15, 0.15)
			var r := rng.randf_range(inner, outer)
			var cpos: Vector2 = (p["pos"] as Vector2) + (Vector2(cos(a) * r, sin(a) * r * flat)).rotated(tilt)
			var spread := rng.randf_range(600.0, 1400.0)
			for k in rng.randi_range(10, 18):
				var pos := cpos + Vector2.from_angle(rng.randf() * TAU) * pow(rng.randf(), 0.7) * spread
				L["debris"].append(_make_debris(cls, mix, pos, rng))
			if c % 2 == 0:
				var ast := _make_asteroid("l_%d" % n, "", cls, mix, cpos + Vector2.from_angle(rng.randf() * TAU) * spread * 0.5, rng)
				ast["near"] = p["name"]
				L["asteroids"].append(ast)
				n += 1
	var spots: Array = []
	for g in L["gates"]:
		spots.append([g["pos"], 1600.0, rng.randi_range(30, 45), 3])
	for st in L["stations"]:
		spots.append([st["pos"], 1100.0, rng.randi_range(12, 20), 1])
	for an in L["anomalies"]:
		spots.append([an["pos"], 2200.0, rng.randi_range(30, 50), 5])
	for sp in spots:
		var center: Vector2 = sp[0]
		var dist := center.length()
		var cls: String = "metallic" if dist < 800000.0 else ("stony" if dist < 1350000.0 else "icy")
		var mix := _field_mix(cls, sec, rng)
		for k in int(sp[2]):
			var pos := center + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(float(sp[1]) * 0.25, float(sp[1]))
			L["debris"].append(_make_debris(cls, mix, pos, rng))
		for k in int(sp[3]):
			var pos2 := center + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(float(sp[1]) * 0.4, float(sp[1]) * 1.1)
			var ast2 := _make_asteroid("l_%d" % n, "", cls, mix, pos2, rng)
			if ast2["size"] == "large":
				ast2["size"] = "medium"
				ast2["radius"] = rng.randf_range(25.0, 60.0)
			L["asteroids"].append(ast2)
			n += 1


## Scenery rock: no deposit, not selectable, drawn in bulk.
func _make_debris(cls: String, mix: Dictionary, pos: Vector2, rng: RandomNumberGenerator) -> Dictionary:
	var shapes: Array = SHAPES_BY_CLASS[cls]
	return {"pos": pos, "class": cls, "ore": _roll_ore(mix, rng), "shape": shapes[rng.randi() % shapes.size()],
		"radius": rng.randf_range(12.0, 40.0) if rng.randf() < 0.85 else rng.randf_range(40.0, 85.0),
		"seed": rng.randi(), "rot": rng.randf() * TAU, "spin": rng.randf_range(-0.08, 0.08)}


func _free_spot(rng: RandomNumberGenerator, used: Array, rmin: float, rmax: float) -> Vector2:
	var p := Vector2.ZERO
	for attempt in 60:
		p = Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(rmin, rmax)
		var ok := true
		for u in used:
			if (u as Vector2).distance_to(p) < 150000.0:
				ok = false
				break
		if ok:
			break
	used.append(p)
	return p


## All warp targets of a system: {id, kind, name, pos, land (arrival distance), data}
func warp_targets(system_id: int) -> Array:
	var L := get_layout(system_id)
	var out: Array = []
	var star: Dictionary = L["star"]
	out.append({"id": "star", "kind": "star", "name": "%s (%s)" % [star["name"], star["type"]], "pos": star["pos"], "land": float(star["radius"]) * 2.5, "data": star})
	for p in L["planets"]:
		out.append({"id": p["id"], "kind": "planet", "name": p["name"], "pos": p["pos"], "land": float(p["radius"]) * 1.6, "data": p})
	for st in L["stations"]:
		out.append({"id": st["id"], "kind": "station", "name": st["name"], "pos": st["pos"], "land": 2500.0, "data": st})
	for g in L["gates"]:
		out.append({"id": g["id"], "kind": "gate", "name": g["name"], "pos": g["pos"], "land": 2200.0, "data": g})
	for f in L["fields"]:
		out.append({"id": f["id"], "kind": "field", "name": f["name"], "pos": f["pos"], "land": float(f["radius"]) * 0.5, "data": f})
	for ph in L.get("havens", []):
		out.append({"id": ph["id"], "kind": "haven", "name": ph["name"], "pos": ph["pos"], "land": 9000.0, "data": ph})
	for an in L["anomalies"]:
		if an["revealed"]:
			out.append({"id": an["id"], "kind": "anomaly", "name": an["name"], "pos": an["pos"], "land": 2200.0, "data": an})
	return out


func warp_target(system_id: int, target_id: String) -> Dictionary:
	for t in warp_targets(system_id):
		if t["id"] == target_id:
			return t
	return {}


## Ore weights of a field: both common ores of the class, one or two uncommon ones,
## and in unsafe systems (security < 0.5) a chance for rare ores – more the lower the security.
func _field_mix(cls: String, sec: float, rng: RandomNumberGenerator) -> Dictionary:
	var by_rarity := {"common": [], "uncommon": [], "rare": []}
	for cid in CommodityData.COMMODITIES:
		var c: Dictionary = CommodityData.COMMODITIES[cid]
		if c.get("category", "") == "ore" and c["class"] == cls:
			by_rarity[c["rarity"]].append(cid)
	var mix := {}
	for cid in by_rarity["common"]:
		mix[cid] = 3.0
	# deterministic pick (same seed -> same galaxy, important for save games)
	var unc: Array = by_rarity["uncommon"].duplicate()
	for i in (2 if rng.randf() < 0.5 else 1):
		var pick: int = rng.randi() % unc.size()
		mix[unc[pick]] = 1.5
		unc.remove_at(pick)
	if sec < 0.5:
		var rare: Array = by_rarity["rare"]
		mix[rare[rng.randi() % rare.size()]] = lerpf(0.4, 1.4, 1.0 - sec / 0.5)
		if sec < 0.2:
			for r in rare:
				mix[r] = maxf(float(mix.get(r, 0.0)), 0.6)
	return mix


## One asteroid: size class (small / medium / large), shape, ore(s) and deposit.
## Large asteroids often hold a second ore of the same field ("mix": ore -> share).
func _make_asteroid(id: String, fid: String, cls: String, mix: Dictionary, pos: Vector2, rng: RandomNumberGenerator) -> Dictionary:
	var r := rng.randf()
	var size := "small" if r < 0.5 else ("medium" if r < 0.88 else "large")
	var sz: Dictionary = ASTEROID_SIZES[size]
	var ore := _roll_ore(mix, rng)
	var amount: float = rng.randf_range(sz["amount"].x, sz["amount"].y) * RARITY_AMOUNT[GameData.commodities[ore]["rarity"]]
	var shares := {ore: 1.0}
	if size == "large" and mix.size() > 1 and rng.randf() < 0.7:
		var second := ore
		while second == ore:
			second = _roll_ore(mix, rng)
		var share := rng.randf_range(0.2, 0.4)
		shares = {ore: 1.0 - share, second: share}
	var shapes: Array = SHAPES_BY_CLASS[cls]
	return {
		"id": id, "field": fid, "class": cls, "size": size, "shape": shapes[rng.randi() % shapes.size()],
		"pos": pos, "ore": ore, "mix": shares, "amount": amount,
		"radius": rng.randf_range(sz["radius"].x, sz["radius"].y), "seed": rng.randi(),
		"spin": rng.randf_range(-0.06, 0.06),
	}


func _roll_ore(mix: Dictionary, rng: RandomNumberGenerator) -> String:
	var total := 0.0
	for k in mix:
		total += float(mix[k])
	var x := rng.randf() * total
	for k in mix:
		x -= float(mix[k])
		if x <= 0.0:
			return k
	return mix.keys()[0]


## Market prices: buy = price the player pays (-1 = not on offer),
## sell = price the station pays the player.
func _make_market(type: String, rng: RandomNumberGenerator) -> Dictionary:
	var t: Dictionary = GameData.station_types[type]
	var market := {}
	for cid in CommodityData.COMMODITIES:
		if not CommodityData.COMMODITIES[cid].get("tradeable", true):
			continue
		var base := float(CommodityData.COMMODITIES[cid]["price"])
		var noise := rng.randf_range(0.9, 1.1)
		var buy := -1
		var sell := int(round(base * 0.95 * noise))
		if cid in t["produces"]:
			buy = int(round(base * 0.75 * noise))
			sell = int(round(base * 0.6 * noise))
		elif cid in t["consumes"]:
			sell = int(round(base * 1.45 * noise))
		market[cid] = {"buy": buy, "sell": sell}
	return market


## Outfitter stock (package 19): module families of the station's speciality (others rarely), in
## the sizes the station tier allows, each size in a few qualities – F–C everywhere, B from tier 2,
## A from tier 3 or at military outposts. Pirate gear only in havens; ion torpedoes never.
func _make_shop(type: String, tier: int, rng: RandomNumberGenerator) -> Array:
	var t: Dictionary = GameData.station_types[type]
	var shop: Array = []
	for fam in ModuleData.FAMILIES:
		var a: Dictionary = ModuleData.ANCHORS[ModuleData.FAMILIES[fam]["anchor"]]
		if a.get("notorious_only", false) or (a.get("pirate_only", false) and type != "pirate_haven") or a.get("covenant_only", false) or a.get("directorate_only", false):
			continue
		var chance := 0.9 if a["slot"] in t["shop"] else 0.12
		if a["slot"] in ["hangar", "drone"]:
			chance = 0.6              # drone hangars and drone modules: at many stations (package 23)
		if rng.randf() > chance:
			continue
		var r: Array = ModuleData.FAMILIES[fam]["sizes"]
		var cap := GameData.size_cap(String(a["slot"]), tier)
		for size in range(int(r[0]), mini(int(r[1]), cap) + 1):
			if rng.randf() > 0.75:
				continue          # not every size is in stock
			var qs: Array = ["C"]
			if rng.randf() < 0.5:
				qs.append("D")
			if rng.randf() < 0.3:
				qs.append("E")
			if rng.randf() < 0.2:
				qs.append("F")
			if tier >= 2 and rng.randf() < 0.4:
				qs.append("B")
			if (tier >= 3 or type == "military") and rng.randf() < 0.3:
				qs.append("A")
			for q in qs:
				shop.append(ModuleData.id_of(fam, size, q))
	return shop


## Faction ships (package 25e): a shipyard of a power's station also sells the hulls of the power's
## state manufacturer (size up to the tier); buying them needs standing (hull min_tier).
func _add_faction_yard(st: Dictionary) -> void:
	var t: Dictionary = GameData.station_types.get(String(st["type"]), {})
	# package 25f: the Covenant's outfitters sell its focus-crystal lasers
	if String(st.get("faction", "")) == "covenant" and ("weapon" in t.get("shop", []) or String(st["type"]) == "military"):
		var cap := GameData.size_cap("weapon", int(st["tier"]))
		for size in range(1, mini(4, cap) + 1):
			var qs: Array = ["C", "D"]
			if int(st["tier"]) >= 2:
				qs.append("B")
			if int(st["tier"]) >= 3 or String(st["type"]) == "military":
				qs.append("A")
			for q in qs:
				var mid := ModuleData.id_of("w_focus", size, q)
				if not mid in st["shop"]:
					st["shop"].append(mid)
	# 0.4.25.40: the Directorate's outfitters sell Axiom's drone cloak emitter
	if String(st.get("faction", "")) == "directorate" and not st.get("shop", []).is_empty():
		var qs2: Array = ["C", "D"]
		if int(st["tier"]) >= 2:
			qs2.append("B")
		if int(st["tier"]) >= 3 or String(st["type"]) == "military":
			qs2.append("A")
		for q2 in qs2:
			var mid2 := ModuleData.id_of("dr_cloak", 1, q2)
			if not mid2 in st["shop"]:
				st["shop"].append(mid2)
	if not t.get("shipyard", false):
		return
	var f := String(st.get("faction", ""))
	for hid in GameData.hulls:
		var h: Dictionary = GameData.hulls[hid]
		var mk: Dictionary = MakerData.MAKERS.get(String(h.get("maker", "")), {})
		if String(mk.get("kind", "")) == "state" and String(mk.get("faction", "")) == f and h["buyable"] and int(h["size"]) <= int(st["tier"]) and not hid in st["shipyard"]:
			st["shipyard"].append(hid)


## Shipyard stock by manufacturer (package 25a, data/manufacturers.gd): a maker's hulls at the
## station types in its "yards" (size up to the tier), plus "small_yards" (e.g. KHI and the
## Earthworks Drillhead at mining colonies). `rich`: a rich, safe system – makers with "rich_only"
## (Maison Aurelle, package 25c) sell only there.
func _make_shipyard(type: String, tier: int, rich: bool = false) -> Array:
	var t: Dictionary = GameData.station_types[type]
	var yard: Array = []
	for hid in GameData.hulls:
		var h: Dictionary = GameData.hulls[hid]
		if not h["buyable"] or h.get("haven_only", false) or h.get("drone_only", false):
			continue
		var mk: Dictionary = MakerData.MAKERS.get(String(h.get("maker", "")), {})
		if mk.has("rich_only") and not rich:
			continue
		if String(mk.get("kind", "")) == "state":
			continue                     # faction ships: see _add_faction_yard (package 25e)
		# package 25d: big warships only at military stations, shipyard complexes and tier-3 stations
		if String(h.get("yard_rule", "")) == "military" and not (type in ["military", "shipyard"] or tier >= 3):
			continue
		var yards = mk.get("yards", "all")
		var at_yard: bool = t["shipyard"] and (typeof(yards) == TYPE_STRING or type in yards)
		if at_yard and int(h["size"]) <= tier:
			yard.append(hid)
		elif hid in mk.get("small_yards", {}).get(type, []):
			yard.append(hid)
	return yard
