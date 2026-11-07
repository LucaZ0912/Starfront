extends RefCounted
## Package 30: the skill tree and the perks (decisions of Luz, 7 Nov 2026).
##
## The tree is made of tiles that lead on from tile to tile. A tile opens once its predecessors are open and its
## achievements are met (e.g. "5,000 ore mined"); then it glows and is confirmed in the Pilot window. No points.
## Free tiles are open from the start (the "medium" start scope: Earthworks S ships, modules up to quality C in the
## small sizes). Ships and modules the pilot already owns stay usable – the tree only gates buying and building.
##
## Perks: every pilot level brings a perk point, spent freely in one of six groups; some need a skill level.

## Achievement metrics (GameState.stats keys) and how they read in the game
const METRICS := {
	"warps": "warps", "jumps": "jumps", "systems": "systems visited", "mined": "ore mined", "refined_station": "ore refined at stations",
	"built": "modules built", "markets": "markets traded at", "turnover": "credits traded", "kills": "pirates destroyed",
	"bounty_jobs": "bounty contracts", "jobs_covenant": "contracts for the Covenant", "jobs_assembly": "contracts for the Assembly",
	"passengers": "passengers delivered", "analysed": "anomalies analysed", "exotic": "exotic matter collected", "scans": "ships scanned",
	"bounties": "bounties redeemed", "pilot_level": "pilot level",
}

const BRANCHES := ["Flight", "Industry", "Blueprints", "Combat", "Commerce", "Science", "Equipment", "Mastery"]

## id: branch, name, what it opens (text), prerequisites, achievements [[metric, amount], …], any (one achievement is
## enough), unlocks {"hulls": […], "families": […], "weapon_size": n, "size": n, "quality": "B", "fab_size": n}
const TILES := {
	# ---- Flight
	"small_craft": {"branch": "Flight", "name": "Small Craft", "opens": "Earthworks S ships: Dragonfly, Hornet, Skiff", "pre": [], "req": [],
		"unlocks": {"hulls": ["dragonfly", "hornet", "shuttle"]}},
	"frigate_ops": {"branch": "Flight", "name": "Frigate Operations", "opens": "Earthworks M ships: Mule, Warden", "pre": ["small_craft"],
		"req": [["warps", 25], ["jumps", 10]], "unlocks": {"hulls": ["mule", "warden"]}},
	"cruiser_cmd": {"branch": "Flight", "name": "Cruiser Command", "opens": "Earthworks L: Bastion", "pre": ["frigate_ops"],
		"req": [["warps", 100], ["jumps", 40], ["systems", 10]], "unlocks": {"hulls": ["bastion"]}},
	# ---- Industry
	"mining_basics": {"branch": "Industry", "name": "Mining Basics", "opens": "Mining lasers, scanners", "pre": [], "req": [], "unlocks": {}},
	"khi_mogura": {"branch": "Industry", "name": "Prospector Licence", "opens": "Drillhead, KHI Mogura", "pre": ["mining_basics"],
		"req": [["mined", 500]], "unlocks": {"hulls": ["drillhead", "mogura"]}},
	"khi_anaguma": {"branch": "Industry", "name": "KHI Frigates", "opens": "KHI Anaguma", "pre": ["khi_mogura"],
		"req": [["mined", 5000], ["refined_station", 2000]], "unlocks": {"hulls": ["anaguma"]}},
	"khi_iwakudaki": {"branch": "Industry", "name": "KHI Barges", "opens": "KHI Iwakudaki", "pre": ["khi_anaguma"],
		"req": [["mined", 30000], ["refined_station", 10000]], "unlocks": {"hulls": ["iwakudaki"]}},
	"kanayama": {"branch": "Industry", "name": "Heavy Industry", "opens": "Kanayama-maru", "pre": ["khi_iwakudaki"],
		"req": [["markets", 10], ["built", 20]], "unlocks": {"hulls": ["kanayama"]}},
	# ---- Blueprints (what can be manufactured)
	"workshop": {"branch": "Blueprints", "name": "Workshop", "opens": "Manufacturing modules of size 1–2", "pre": [], "req": [], "unlocks": {"fab_size": 2}},
	"fabrication_2": {"branch": "Blueprints", "name": "Fabrication II", "opens": "Manufacturing modules of size 3–5", "pre": ["workshop"],
		"req": [["built", 20]], "unlocks": {"fab_size": 5}},
	"fabrication_3": {"branch": "Blueprints", "name": "Fabrication III", "opens": "Manufacturing modules of size 6 and up", "pre": ["fabrication_2"],
		"req": [["built", 100]], "unlocks": {"fab_size": 99}},
	# ---- Combat
	"small_arms": {"branch": "Combat", "name": "Small Arms", "opens": "Weapons of size 1–2", "pre": [], "req": [], "unlocks": {}},
	"heavy_weapons": {"branch": "Combat", "name": "Heavy Weapons", "opens": "Weapons of size 3", "pre": ["small_arms"],
		"req": [["kills", 10]], "unlocks": {"weapon_size": 3}},
	"capital_weapons": {"branch": "Combat", "name": "Capital Weapons", "opens": "Weapons of size 4", "pre": ["heavy_weapons"],
		"req": [["kills", 50]], "unlocks": {"weapon_size": 4}},
	"hdy_talon": {"branch": "Combat", "name": "Hadrian Dropships", "opens": "Hadrian Talon", "pre": ["small_arms"],
		"req": [["kills", 5]], "unlocks": {"hulls": ["hdy_talon"]}},
	"hdy_maul": {"branch": "Combat", "name": "Hadrian Gunboats", "opens": "Hadrian Maul", "pre": ["hdy_talon"],
		"req": [["kills", 25], ["bounty_jobs", 5]], "unlocks": {"hulls": ["hdy_maul"]}},
	"hdy_goliath": {"branch": "Combat", "name": "Hadrian Destroyers", "opens": "Hadrian Goliath", "pre": ["hdy_maul"],
		"req": [["kills", 75]], "unlocks": {"hulls": ["hdy_goliath"]}},
	"hdy_citadel": {"branch": "Combat", "name": "Hadrian Carriers", "opens": "Hadrian Citadel", "pre": ["hdy_goliath"],
		"req": [["kills", 150]], "unlocks": {"hulls": ["hdy_citadel"]}},
	"for_acolyte": {"branch": "Combat", "name": "Covenant Militia", "opens": "Forge Acolyte", "pre": ["small_arms"],
		"req": [["kills", 5], ["jobs_covenant", 5]], "unlocks": {"hulls": ["for_acolyte"]}},
	"for_templar": {"branch": "Combat", "name": "Covenant Patrols", "opens": "Forge Templar", "pre": ["for_acolyte"],
		"req": [["kills", 25], ["jobs_covenant", 15]], "unlocks": {"hulls": ["for_templar"]}},
	"for_cathedral": {"branch": "Combat", "name": "Covenant Flagships", "opens": "Forge Cathedral", "pre": ["for_templar"],
		"req": [["kills", 75], ["jobs_covenant", 40]], "unlocks": {"hulls": ["for_cathedral"]}},
	"cfw_demos": {"branch": "Combat", "name": "Assembly Militia", "opens": "Concord Demos", "pre": ["small_arms"],
		"req": [["kills", 5], ["jobs_assembly", 5]], "unlocks": {"hulls": ["cfw_demos"]}},
	"cfw_quirinus": {"branch": "Combat", "name": "Assembly Patrols", "opens": "Concord Quirinus", "pre": ["cfw_demos"],
		"req": [["kills", 25], ["jobs_assembly", 15]], "unlocks": {"hulls": ["cfw_quirinus"]}},
	"cfw_concordia": {"branch": "Combat", "name": "Assembly Carriers", "opens": "Concord Concordia", "pre": ["cfw_quirinus"],
		"req": [["kills", 75], ["jobs_assembly", 40]], "unlocks": {"hulls": ["cfw_concordia"]}},
	# ---- Commerce
	"longhaul": {"branch": "Commerce", "name": "Bulk Freight", "opens": "Longhaul", "pre": [],
		"req": [["markets", 5], ["turnover", 250000]], "unlocks": {"hulls": ["freighter"]}},
	"aur_pearl": {"branch": "Commerce", "name": "Passenger Service", "opens": "Aurelle Pearl", "pre": ["longhaul"],
		"req": [["passengers", 20]], "unlocks": {"hulls": ["aur_pearl"]}},
	"aur_liners": {"branch": "Commerce", "name": "Liner Service", "opens": "Aurelle Boulevard, Opal", "pre": ["aur_pearl"],
		"req": [["passengers", 100]], "unlocks": {"hulls": ["aur_boulevard", "aur_opal"]}},
	"aur_empress": {"branch": "Commerce", "name": "Megaliner Command", "opens": "Aurelle Empress", "pre": ["aur_liners"],
		"req": [["passengers", 400], ["turnover", 1000000]], "unlocks": {"hulls": ["aur_empress"]}},
	# ---- Science
	"scanning": {"branch": "Science", "name": "Scanning", "opens": "Scanners, analysers, surveys", "pre": [], "req": [], "unlocks": {}},
	"axa_parallax": {"branch": "Science", "name": "Research Licence", "opens": "Axiom Parallax", "pre": ["scanning"],
		"req": [["analysed", 10]], "unlocks": {"hulls": ["axa_parallax"]}},
	"axa_threshold": {"branch": "Science", "name": "Wormhole Research", "opens": "Axiom Threshold", "pre": ["axa_parallax"],
		"req": [["analysed", 40], ["exotic", 3], ["jumps", 100]], "unlocks": {"hulls": ["axa_threshold"]}},
	# ---- special equipment
	"drones": {"branch": "Equipment", "name": "Drone Operations", "opens": "Drone hangars and drone modules", "pre": [],
		"req": [["mined", 2000], ["kills", 25]], "any": true, "unlocks": {"families": ["hangar", "dr_range", "dr_cargo", "dr_hull", "dr_shield", "dr_damage", "dr_wrange", "dr_fuel", "dr_speed", "dr_cloak"]}},
	"mines": {"branch": "Equipment", "name": "Mine Warfare", "opens": "Mine launchers", "pre": [], "req": [["kills", 20]], "unlocks": {"families": ["w_minelayer"]}},
	"ewar": {"branch": "Equipment", "name": "Electronic Warfare", "opens": "Radar jammers", "pre": [], "req": [["scans", 30]], "unlocks": {"families": ["o_jammer"]}},
	"interdictor": {"branch": "Equipment", "name": "Interdiction", "opens": "Warp interdictors", "pre": [], "req": [["bounties", 10]], "unlocks": {"families": ["t_interdictor"]}},
	# ---- sizes and qualities
	"size_3": {"branch": "Mastery", "name": "Larger Modules", "opens": "Modules of size 3–4 (not weapons)", "pre": [], "req": [["pilot_level", 5]], "unlocks": {"size": 4}},
	"size_5": {"branch": "Mastery", "name": "Heavy Modules", "opens": "Modules of size 5–7", "pre": ["size_3"], "req": [["pilot_level", 12]], "unlocks": {"size": 7}},
	"size_8": {"branch": "Mastery", "name": "Capital Modules", "opens": "Modules of size 8–10", "pre": ["size_5"], "req": [["pilot_level", 20]], "unlocks": {"size": 99}},
	"quality_b": {"branch": "Mastery", "name": "Quality B", "opens": "Modules of quality B", "pre": [], "req": [["pilot_level", 8]], "unlocks": {"quality": "B"}},
	"quality_a": {"branch": "Mastery", "name": "Quality A", "opens": "Modules of quality A", "pre": ["quality_b"], "req": [["pilot_level", 18]], "unlocks": {"quality": "A"}},
}

## Perks: id → group, name, effect, skill and level needed ("" = none), "later": package it takes effect with
const GROUPS := ["Combat", "Flight", "Industry", "Science", "Commerce", "Command"]
const PERKS := {
	"sharpshooter": {"group": "Combat", "name": "Sharpshooter", "effect": "Weapon range +10 %", "skill": "gunnery", "lvl": 3},
	"hull_breaker": {"group": "Combat", "name": "Hull Breaker", "effect": "+15 % damage against the hull structure", "skill": "gunnery", "lvl": 5},
	"quick_lock": {"group": "Combat", "name": "Quick Lock", "effect": "One more target locked at once", "skill": "gunnery", "lvl": 2},
	"bounty_hunter": {"group": "Combat", "name": "Bounty Hunter", "effect": "Bounties +15 %", "skill": "", "lvl": 0},
	"ab_discipline": {"group": "Flight", "name": "Afterburner Discipline", "effect": "Afterburner −25 % energy", "skill": "piloting", "lvl": 3},
	"emergency_warp": {"group": "Flight", "name": "Emergency Warp", "effect": "Aligning for warp under fire −30 %", "skill": "piloting", "lvl": 5},
	"fuel_saver": {"group": "Flight", "name": "Fuel Saver", "effect": "Fuel per jump −15 %", "skill": "navigation", "lvl": 3},
	"gate_runner": {"group": "Flight", "name": "Gate Runner", "effect": "Jump drive spools up 25 % faster", "skill": "navigation", "lvl": 5},
	"prospectors_eye": {"group": "Industry", "name": "Prospector's Eye", "effect": "A chance to find rare ore as a bonus while mining", "skill": "mining", "lvl": 3},
	"deep_core": {"group": "Industry", "name": "Deep Core", "effect": "Asteroids yield 20 % more", "skill": "mining", "lvl": 5},
	"efficient_refining": {"group": "Industry", "name": "Efficient Refining", "effect": "Refinery yield +10 %", "skill": "mining", "lvl": 4},
	"master_builder": {"group": "Industry", "name": "Master Builder", "effect": "Manufacturing 25 % faster, better quality more often", "skill": "engineering", "lvl": 4},
	"anomaly_hunter": {"group": "Science", "name": "Anomaly Hunter", "effect": "Anomalies analysed 25 % faster", "skill": "science", "lvl": 3},
	"long_survey": {"group": "Science", "name": "Long Survey", "effect": "Survey range +30 %", "skill": "science", "lvl": 5},
	"signal_reader": {"group": "Science", "name": "Signal Reader", "effect": "Warrant and cargo scans twice as fast", "skill": "electronics", "lvl": 3},
	"ghost_hunter": {"group": "Science", "name": "Ghost Hunter", "effect": "Cloaked ships show within 2,000 km", "skill": "electronics", "lvl": 5},
	"haggler": {"group": "Commerce", "name": "Haggler", "effect": "Ore and ingots sell for 5 % more", "skill": "trading", "lvl": 3},
	"market_insider": {"group": "Commerce", "name": "Market Insider", "effect": "Markets show where an item sells best in the neighbouring systems", "skill": "trading", "lvl": 5},
	"diplomat": {"group": "Commerce", "name": "Diplomat", "effect": "Standing from contracts +25 %", "skill": "negotiation", "lvl": 3},
	"fine_print": {"group": "Commerce", "name": "Fine Print", "effect": "Penalties for failed contracts halved", "skill": "negotiation", "lvl": 5},
	"drone_wrangler": {"group": "Command", "name": "Drone Wrangler", "effect": "One more drone in flight at once", "skill": "electronics", "lvl": 3},
	"convoy_shepherd": {"group": "Command", "name": "Convoy Shepherd", "effect": "Escort rewards +20 %", "skill": "", "lvl": 0},
	"crew_morale": {"group": "Command", "name": "Crew Morale", "effect": "Crew wages −15 %", "skill": "leadership", "lvl": 4, "later": "package 31"},
	"wing_commander": {"group": "Command", "name": "Wing Commander", "effect": "Mercenaries +10 %", "skill": "leadership", "lvl": 3, "later": "package 33"},
}


static func free_tiles() -> Array:
	var out: Array = []
	for id in TILES:
		if (TILES[id]["req"] as Array).is_empty() and (TILES[id]["pre"] as Array).is_empty():
			out.append(id)
	return out


## The tile that opens a hull for buying ("" = free from the start, or not part of the tree).
static func tile_of_hull(hid: String) -> String:
	for id in TILES:
		if hid in TILES[id]["unlocks"].get("hulls", []):
			return id
	return ""


static func tile_of_family(fam: String) -> String:
	for id in TILES:
		if fam in TILES[id]["unlocks"].get("families", []):
			return id
	return ""


## The tiles of a branch in tree order (predecessors first).
static func branch_tiles(branch: String) -> Array:
	var out: Array = []
	var left: Array = []
	for id in TILES:
		if TILES[id]["branch"] == branch:
			left.append(id)
	while not left.is_empty():
		var moved := false
		for id in left.duplicate():
			var ok := true
			for p in TILES[id]["pre"]:
				if p in left:
					ok = false
			if ok:
				out.append(id)
				left.erase(id)
				moved = true
		if not moved:
			out.append_array(left)
			break
	return out
