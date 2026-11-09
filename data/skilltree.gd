extends RefCounted
## Package 30 (reworked 0.5.30.2 after the sketch of Luz): the skill tree – a real tree that opens upwards from
## its trunk, the PILOT LICENCE (later what the story intro of part 8 grants). Above it SHIELDS, and from there it
## branches by ACTIVITY (not by manufacturer): defence, combat, mining, industry, flight, exploration, security,
## trade & transport, drones; mastery grows beside the trunk.
##
## A tile opens once its predecessors are open and its achievements are met; then it glows and is confirmed in the
## Pilot window. Everything can be bought – but only USED with the tile: a locked ship cannot undock, a locked module
## stays offline (core modules fitted in a ship always work, but a locked one cannot be fitted).

## Achievement metrics (GameState.stats keys) and how they read in the game
const METRICS := {
	"warps": "warps", "jumps": "jumps", "systems": "systems visited", "mined": "ore mined", "refined_station": "ore refined at stations",
	"built": "modules built", "markets": "markets traded at", "turnover": "credits traded", "kills": "pirates destroyed",
	"bounty_jobs": "bounty contracts", "jobs_covenant": "contracts for the Covenant", "jobs_assembly": "contracts for the Assembly",
	"passengers": "passengers delivered", "analysed": "anomalies analysed", "exotic": "exotic matter collected", "scans": "ships scanned",
	"bounties": "bounties redeemed", "pilot_level": "pilot level", "damage_taken": "damage taken", "missions_done": "contracts completed",
	"rad_time": "seconds in radiation zones", "ion_hits": "ion-storm lightning strikes taken",
}

## id: branch, name, prerequisites (the first one is the parent in the drawing), achievements [[metric, amount], …],
## any (one achievement is enough), unlocks {"hulls", "families", "weapon_size", "size", "quality", "fab_size"}
const TILES := {
	"licence": {"branch": "Trunk", "name": "Pilot Licence", "pre": [], "req": [], "unlocks": {
		"hulls": ["dragonfly", "shuttle"],
		"families": ["pl_standard", "eng_chemical", "eng_ion", "dist_basic", "rea_fission", "tank", "hyperdrive", "sen_basic",
			"w_pulse", "t_mining", "t_scanner", "t_analyzer", "t_salvage", "o_cargo", "o_fuel"]}},
	"shields": {"branch": "Trunk", "name": "Shields", "pre": ["licence"], "req": [["warps", 1]], "unlocks": {"families": ["o_shield"]}},
	# ---- defence
	"adv_shields": {"branch": "Defence", "name": "Advanced Shields", "pre": ["shields"], "req": [["damage_taken", 5000]],
		"unlocks": {"families": ["o_shield_cap", "o_shield_fast"]}},
	"shield_support": {"branch": "Defence", "name": "Shield Support", "pre": ["adv_shields"], "req": [["damage_taken", 20000]],
		"unlocks": {"families": ["o_shieldboost", "t_shieldxfer"]}},
	"armour": {"branch": "Defence", "name": "Armour", "pre": ["shields"], "req": [["damage_taken", 5000]],
		"unlocks": {"families": ["o_armor", "pl_reflective", "pl_ablative", "o_armorrep", "t_repair"]}},
	# ---- combat
	"light_weapons": {"branch": "Combat", "name": "Light Weapons", "pre": ["shields"], "req": [["kills", 3]],
		"unlocks": {"families": ["w_autocannon", "w_rocket", "w_beam"]}},
	"fighters": {"branch": "Combat", "name": "Fighters", "pre": ["light_weapons"], "req": [["kills", 5]],
		"unlocks": {"hulls": ["hornet", "hdy_talon", "for_acolyte", "cfw_demos"]}},
	"gunships": {"branch": "Combat", "name": "Gunships", "pre": ["fighters"], "req": [["kills", 25], ["bounty_jobs", 3]],
		"unlocks": {"hulls": ["warden", "hdy_maul", "for_templar", "cfw_quirinus"]}},
	"capital_ships": {"branch": "Combat", "name": "Capital Ships", "pre": ["gunships"], "req": [["kills", 100], ["bounty_jobs", 10]],
		"unlocks": {"hulls": ["bastion", "hdy_goliath", "hdy_citadel", "for_cathedral", "cfw_concordia"], "crew": ["wing_pilot"]}},
	"heavy_weapons": {"branch": "Combat", "name": "Heavy Weapons", "pre": ["light_weapons"], "req": [["kills", 25]],
		"unlocks": {"weapon_size": 3, "families": ["w_railgun", "w_massdriver", "w_lance", "w_torpedo"]}},
	"capital_weapons": {"branch": "Combat", "name": "Capital Weapons", "pre": ["heavy_weapons"], "req": [["kills", 75]],
		"unlocks": {"weapon_size": 4, "families": ["w_cruise"]}},
	"pd_mines": {"branch": "Combat", "name": "Point Defence & Mines", "pre": ["light_weapons"], "req": [["kills", 20]],
		"unlocks": {"families": ["w_pointdef", "w_minelayer"]}},
	"focus": {"branch": "Combat", "name": "Focus Crystals", "pre": ["light_weapons"], "req": [["jobs_covenant", 10]],
		"unlocks": {"families": ["w_focus"]}},
	"wing_command": {"branch": "Combat", "name": "Wing Command", "pre": ["fighters"], "req": [["kills", 10], ["bounty_jobs", 2]],
		"unlocks": {"wingmen": 1}},
	# ---- mining
	"mining_ops": {"branch": "Mining", "name": "Mining Operations", "pre": ["shields"], "req": [["mined", 300]],
		"unlocks": {"families": ["o_orehold", "t_prospector", "o_mining_metal", "o_mining_stone", "o_mining_ice"]}},
	"mining_ships": {"branch": "Mining", "name": "Mining Ships", "pre": ["mining_ops"], "req": [["mined", 1000]],
		"unlocks": {"hulls": ["drillhead", "mogura"]}},
	"ice": {"branch": "Mining", "name": "Ice Harvesting", "pre": ["mining_ships"], "req": [["mined", 2000]],
		"unlocks": {"families": ["t_harvester"]}},
	"mining_frigates": {"branch": "Mining", "name": "Mining Frigates", "pre": ["mining_ships"], "req": [["mined", 5000], ["refined_station", 2000]],
		"unlocks": {"hulls": ["anaguma"], "families": ["t_stripminer"]}},
	"mining_barges": {"branch": "Mining", "name": "Mining Barges", "pre": ["mining_frigates"], "req": [["mined", 30000], ["refined_station", 10000]],
		"unlocks": {"hulls": ["iwakudaki"]}},
	"heavy_industry": {"branch": "Mining", "name": "Heavy Industry", "pre": ["mining_barges", "blueprints_2"], "req": [["markets", 10], ["built", 20]],
		"unlocks": {"hulls": ["kanayama"]}},
	# ---- industry
	"station_mfg": {"branch": "Industry", "name": "Station Manufacturing", "pre": ["shields"], "req": [["refined_station", 1000]],
		"unlocks": {"fab_size": 2}},
	"blueprints_2": {"branch": "Industry", "name": "Blueprints II", "pre": ["station_mfg"], "req": [["built", 20]], "unlocks": {"fab_size": 5}},
	"blueprints_3": {"branch": "Industry", "name": "Blueprints III", "pre": ["blueprints_2"], "req": [["built", 100]], "unlocks": {"fab_size": 99}},
	# 0.6.40.9: specialised blueprints – the hazard wards are never sold, only built
	"rad_insulation": {"branch": "Industry", "name": "Radiation Insulation", "pre": ["station_mfg"], "req": [["built", 10], ["rad_time", 120]],
		"unlocks": {"families": ["o_rad_ward"], "blueprints": ["o_rad_ward"]}},
	"hull_lining": {"branch": "Industry", "name": "Shielded Hull Lining", "pre": ["station_mfg"], "req": [["built", 10], ["ion_hits", 5]],
		"unlocks": {"families": ["o_ion_ward"], "blueprints": ["o_ion_ward"]}},
	# ---- flight
	"navigation": {"branch": "Flight", "name": "Navigation", "pre": ["shields"], "req": [["warps", 25], ["jumps", 10]],
		"unlocks": {"families": ["o_afterburner", "sen_radar"]}},
	"adv_propulsion": {"branch": "Flight", "name": "Advanced Propulsion", "pre": ["navigation"], "req": [["warps", 100], ["jumps", 40]],
		"unlocks": {"families": ["eng_plasma", "rea_fusion", "dist_precision", "o_capacitor", "o_solar"]}},
	# ---- exploration
	"survey": {"branch": "Exploration", "name": "Survey", "pre": ["shields"], "req": [["analysed", 3]],
		"unlocks": {"families": ["t_survey", "o_survey_amp", "sen_grav"]}},
	"research_ships": {"branch": "Exploration", "name": "Research Ships", "pre": ["survey"], "req": [["analysed", 10]],
		"unlocks": {"hulls": ["axa_parallax"]}},
	"science_officers": {"branch": "Exploration", "name": "Science Officers", "pre": ["research_ships"], "req": [["analysed", 15]],
		"unlocks": {"crew": ["science"]}},
	"wormhole": {"branch": "Exploration", "name": "Wormhole Research", "pre": ["research_ships"], "req": [["analysed", 40], ["exotic", 3], ["jumps", 100]],
		"unlocks": {"hulls": ["axa_threshold"]}},
	# ---- security
	"scanning": {"branch": "Security", "name": "Scanning", "pre": ["shields"], "req": [["kills", 5]],
		"unlocks": {"families": ["t_warrant", "t_cargoscan", "sen_tactical", "o_targeting"]}},
	"ewar": {"branch": "Security", "name": "Electronic Warfare", "pre": ["scanning"], "req": [["scans", 30]],
		"unlocks": {"families": ["o_jammer"]}},
	"interdiction": {"branch": "Security", "name": "Interdiction", "pre": ["ewar"], "req": [["bounties", 10]],
		"unlocks": {"families": ["t_interdictor"]}},
	# ---- trade & transport
	"freight": {"branch": "Trade", "name": "Freight", "pre": ["shields"], "req": [["markets", 3], ["turnover", 50000]],
		"unlocks": {"hulls": ["mule"]}},
	"bulk_freight": {"branch": "Trade", "name": "Bulk Freight", "pre": ["freight"], "req": [["markets", 5], ["turnover", 250000]],
		"unlocks": {"hulls": ["freighter"]}},
	"passengers": {"branch": "Trade", "name": "Passengers", "pre": ["freight"], "req": [["missions_done", 3]],
		"unlocks": {"families": ["o_cabin_bulk", "o_cabin_business"]}},
	"liners": {"branch": "Trade", "name": "Liners", "pre": ["passengers"], "req": [["passengers", 50]],
		"unlocks": {"hulls": ["aur_pearl", "aur_boulevard", "aur_opal"]}},
	"megaliner": {"branch": "Trade", "name": "Megaliner", "pre": ["liners"], "req": [["passengers", 400], ["turnover", 1000000]],
		"unlocks": {"hulls": ["aur_empress"], "families": ["o_cabin_luxury"]}},
	# ---- drones
	"drones": {"branch": "Drones", "name": "Drone Operations", "pre": ["shields"], "req": [["mined", 2000], ["kills", 25]], "any": true,
		"unlocks": {"families": ["hangar", "dr_range", "dr_cargo", "dr_hull", "dr_fuel", "dr_speed"]}},
	"adv_drones": {"branch": "Drones", "name": "Advanced Drones", "pre": ["drones"], "req": [["mined", 10000], ["kills", 75]], "any": true,
		"unlocks": {"families": ["dr_shield", "dr_damage", "dr_wrange", "dr_cloak"]}},
	# ---- mastery (beside the trunk)
	"quality_b": {"branch": "Mastery", "name": "Quality B", "pre": ["licence"], "roots": -1, "req": [["pilot_level", 8]], "unlocks": {"quality": "B"}},
	"quality_a": {"branch": "Mastery", "name": "Quality A", "pre": ["quality_b"], "req": [["pilot_level", 18]], "unlocks": {"quality": "A"}},
	"size_3": {"branch": "Mastery", "name": "Larger Modules", "pre": ["licence"], "roots": 1, "req": [["pilot_level", 5]], "unlocks": {"size": 4}},
	"size_5": {"branch": "Mastery", "name": "Heavy Modules", "pre": ["size_3"], "req": [["pilot_level", 12]], "unlocks": {"size": 7}},
	"size_8": {"branch": "Mastery", "name": "Capital Modules", "pre": ["size_5"], "req": [["pilot_level", 20]], "unlocks": {"size": 99}},
}

const ROOT := "licence"
const TRUNK := "shields"
const BRANCH_COLORS := {"Trunk": Color(1.0, 0.85, 0.4), "Defence": Color(0.45, 0.75, 1.0), "Combat": Color(1.0, 0.45, 0.4),
	"Mining": Color(1.0, 0.75, 0.3), "Industry": Color(0.85, 0.6, 1.0), "Flight": Color(0.4, 0.95, 1.0), "Exploration": Color(0.55, 1.0, 0.6),
	"Security": Color(1.0, 0.55, 0.85), "Trade": Color(1.0, 0.92, 0.5), "Drones": Color(0.6, 1.0, 0.85), "Mastery": Color(0.95, 0.95, 0.95)}

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
	return [ROOT]


## The tile a hull needs ("" = free – e.g. pirate hulls).
static func tile_of_hull(hid: String) -> String:
	for id in TILES:
		if hid in TILES[id]["unlocks"].get("hulls", []):
			return id
	return ""


## 0.6.40.9: the tile holding the specialised blueprint of a craft-only family.
static func tile_of_blueprint(fam: String) -> String:
	for id in TILES:
		if fam in TILES[id]["unlocks"].get("blueprints", []):
			return id
	return ""


static func tile_of_family(fam: String) -> String:
	for id in TILES:
		if fam in TILES[id]["unlocks"].get("families", []):
			return id
	return ""


## Package 31: the tile that lets a profession serve (the first hull tile that needs it, or its own tile).
static func tile_of_crew(role: String) -> String:
	var CD = load("res://data/crew.gd")
	for id in TILES:
		var u: Dictionary = TILES[id]["unlocks"]
		if role in u.get("crew", []):
			return id
		for h in u.get("hulls", []):
			if role in CD.roles_required_by(String(h)):
				return id
	return ""


## The children of a tile in the drawing (tiles whose first prerequisite it is).
static func children(id: String) -> Array:
	var out: Array = []
	for t in TILES:
		var pre: Array = TILES[t]["pre"]
		if not pre.is_empty() and pre[0] == id:
			out.append(t)
	return out


## Positions for the drawing: x in leaf columns (centred over their children), y = depth (0 = the trunk at the
## bottom, -1 = the roots in the earth: mastery). Returns {id: Vector2(column, depth)} and the column count in "_cols".
static func layout() -> Dictionary:
	var pos := {}
	var next := [0.0]
	_place(ROOT, 0, pos, next)
	# mastery grows as the roots: in the earth beside the trunk, outwards to the left and the right
	var tx: float = pos[ROOT].x
	for k in children(ROOT):
		var side := int(TILES[k].get("roots", 0))
		if side == 0:
			continue
		var id: String = k
		var i := 1
		while id != "":
			pos[id] = Vector2(tx + float(side) * (1.15 * float(i) + 0.1), -1)
			var kids := children(id)
			id = String(kids[0]) if not kids.is_empty() else ""
			i += 1
	var lo := 0.0
	var hi := 0.0
	for id2 in pos:
		lo = minf(lo, pos[id2].x)
		hi = maxf(hi, pos[id2].x)
	for id3 in pos.keys():
		pos[id3] = Vector2(pos[id3].x - lo, pos[id3].y)      # nothing left of column 0
	pos["_cols"] = hi - lo + 1.0
	return pos


static func _place(id: String, depth: int, pos: Dictionary, next: Array) -> float:
	var kids: Array = []
	for k0 in children(id):
		if int(TILES[k0].get("roots", 0)) == 0:
			kids.append(k0)
	var x := 0.0
	if kids.is_empty():
		x = next[0]
		next[0] = next[0] + 1.0
	else:
		var xs: Array = []
		for k in kids:
			xs.append(_place(String(k), depth + 1, pos, next))
		x = (float(xs[0]) + float(xs[xs.size() - 1])) * 0.5
		var trunk := kids.find(TRUNK)
		if id == ROOT and trunk >= 0:
			x = float(xs[trunk])             # the trunk grows straight up; mastery stands beside it
	pos[id] = Vector2(x, depth)
	return x


## What a tile opens, as a readable line.
static func opens_text(id: String) -> String:
	var u: Dictionary = TILES[id]["unlocks"]
	var parts: Array = []
	for h in u.get("hulls", []):
		parts.append(String(GameData.hulls[h]["name"]) if GameData.hulls.has(h) else String(h))
	var fams: Array = u.get("families", [])
	var MD = preload("res://data/modules.gd")
	for f in fams:
		if MD.FAMILIES.has(f):
			parts.append(String(MD.FAMILIES[f]["name"]))
	var CD2 = load("res://data/crew.gd")
	var roles: Array = (u.get("crew", []) as Array).duplicate()
	for h2 in u.get("hulls", []):
		for r in CD2.roles_required_by(String(h2)):
			if not r in roles:
				roles.append(r)
	for r2 in roles:
		parts.append("crew: %s" % CD2.role_name(String(r2)))
	if u.has("wingmen"):
		parts.append("wingmen – pilots for hire at The Bar")
	if u.has("weapon_size"):
		parts.append("weapons of size %d" % int(u["weapon_size"]))
	if u.has("size"):
		parts.append("optional modules and tools up to size %d" % int(u["size"]) if int(u["size"]) < 99 else "optional modules and tools of any size")
	if u.has("quality"):
		parts.append("modules of quality %s" % u["quality"])
	for bp in u.get("blueprints", []):
		parts.append("blueprint: %s" % String(MD.FAMILIES[bp]["name"]) if MD.FAMILIES.has(bp) else String(bp))
	if u.has("fab_size"):
		parts.append("blueprints up to size %d" % int(u["fab_size"]) if int(u["fab_size"]) < 99 else "blueprints of any size")
	return ", ".join(PackedStringArray(parts))
