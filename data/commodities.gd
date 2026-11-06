extends RefCounted
## Trade goods and station types.

## tradeable = false: cannot be bought or sold on the market (e.g. mission cargo).
## Raw materials (category "ore") come from three asteroid classes – "class":
##   metallic (M-type), stony (S-type, silicate) and icy.
## "rarity": common / uncommon / rare (rare only in systems with security < 0.5).
## "refines_to" + "yield": refined product and base units out per unit in.
const COMMODITIES := {
	# --- Metallic ores
	"iron_ore": {"name": "Iron Ore", "price": 14, "volume": 1.0, "category": "ore", "class": "metallic", "rarity": "common", "refines_to": "iron_ingot", "yield": 0.5},
	"nickel_ore": {"name": "Nickel Ore", "price": 18, "volume": 1.0, "category": "ore", "class": "metallic", "rarity": "common", "refines_to": "nickel_ingot", "yield": 0.5},
	"titanium_ore": {"name": "Titanium Ore", "price": 42, "volume": 1.0, "category": "ore", "class": "metallic", "rarity": "uncommon", "refines_to": "titanium_ingot", "yield": 0.4},
	"cobalt_ore": {"name": "Cobalt Ore", "price": 55, "volume": 1.0, "category": "ore", "class": "metallic", "rarity": "uncommon", "refines_to": "cobalt_ingot", "yield": 0.4},
	"platinum_ore": {"name": "Platinum Ore", "price": 140, "volume": 1.0, "category": "ore", "class": "metallic", "rarity": "rare", "refines_to": "platinum_ingot", "yield": 0.3},
	"iridium_ore": {"name": "Iridium Ore", "price": 210, "volume": 1.0, "category": "ore", "class": "metallic", "rarity": "rare", "refines_to": "iridium_ingot", "yield": 0.3},
	# --- Stony (silicate) ores
	"silicate_rock": {"name": "Silicate Rock", "price": 10, "volume": 1.0, "category": "ore", "class": "stony", "rarity": "common", "refines_to": "silicon", "yield": 0.5},
	"bauxite": {"name": "Bauxite", "price": 16, "volume": 1.0, "category": "ore", "class": "stony", "rarity": "common", "refines_to": "aluminium", "yield": 0.5},
	"olivine": {"name": "Olivine", "price": 34, "volume": 1.0, "category": "ore", "class": "stony", "rarity": "uncommon", "refines_to": "magnesium", "yield": 0.4},
	"rare_earth_ore": {"name": "Rare Earth Ore", "price": 60, "volume": 1.0, "category": "ore", "class": "stony", "rarity": "uncommon", "refines_to": "rare_earths", "yield": 0.4},
	"xeno_crystal": {"name": "Xeno Crystals", "price": 130, "volume": 1.0, "category": "ore", "class": "stony", "rarity": "rare", "refines_to": "xeno_lattice", "yield": 0.3},
	"neodymium_ore": {"name": "Neodymium Ore", "price": 180, "volume": 1.0, "category": "ore", "class": "stony", "rarity": "rare", "refines_to": "neodymium", "yield": 0.3},
	# --- Ices
	"water_ice": {"name": "Water Ice", "price": 8, "volume": 1.2, "category": "ore", "class": "icy", "rarity": "common", "refines_to": "water", "yield": 0.5},
	"ammonia_ice": {"name": "Ammonia Ice", "price": 14, "volume": 1.2, "category": "ore", "class": "icy", "rarity": "common", "refines_to": "ammonia", "yield": 0.5},
	"methane_ice": {"name": "Methane Ice", "price": 24, "volume": 1.2, "category": "ore", "class": "icy", "rarity": "uncommon", "refines_to": "methane", "yield": 0.4},
	"deuterium_ice": {"name": "Deuterium Ice", "price": 45, "volume": 1.2, "category": "ore", "class": "icy", "rarity": "uncommon", "refines_to": "deuterium", "yield": 0.4},
	"helium3_ice": {"name": "Helium-3 Ice", "price": 170, "volume": 1.2, "category": "ore", "class": "icy", "rarity": "rare", "refines_to": "helium3", "yield": 0.3},
	"cryo_crystal": {"name": "Cryo Crystals", "price": 150, "volume": 1.2, "category": "ore", "class": "icy", "rarity": "rare", "refines_to": "cryo_coolant", "yield": 0.3},
	# --- Refined: metals
	"iron_ingot": {"name": "Iron Ingots", "price": 38, "volume": 0.5, "category": "refined", "class": "metallic"},
	"nickel_ingot": {"name": "Nickel Ingots", "price": 49, "volume": 0.5, "category": "refined", "class": "metallic"},
	"titanium_ingot": {"name": "Titanium Ingots", "price": 120, "volume": 0.5, "category": "refined", "class": "metallic"},
	"cobalt_ingot": {"name": "Cobalt Ingots", "price": 186, "volume": 0.5, "category": "refined", "class": "metallic"},
	"platinum_ingot": {"name": "Platinum Ingots", "price": 630, "volume": 0.3, "category": "refined", "class": "metallic"},
	"iridium_ingot": {"name": "Iridium Ingots", "price": 945, "volume": 0.3, "category": "refined", "class": "metallic"},
	# --- Refined: silicate products
	"silicon": {"name": "Silicon", "price": 27, "volume": 0.5, "category": "refined", "class": "stony"},
	"aluminium": {"name": "Aluminium", "price": 43, "volume": 0.5, "category": "refined", "class": "stony"},
	"magnesium": {"name": "Magnesium", "price": 115, "volume": 0.5, "category": "refined", "class": "stony"},
	"rare_earths": {"name": "Rare Earths", "price": 203, "volume": 0.3, "category": "refined", "class": "stony"},
	"xeno_lattice": {"name": "Xeno Lattice", "price": 480, "volume": 0.3, "category": "refined", "class": "stony"},
	"neodymium": {"name": "Neodymium", "price": 810, "volume": 0.3, "category": "refined", "class": "stony"},
	# --- Refined: volatiles (from ice)
	"water": {"name": "Purified Water", "price": 22, "volume": 0.8, "category": "refined", "class": "icy"},
	"ammonia": {"name": "Ammonia", "price": 38, "volume": 0.8, "category": "refined", "class": "icy"},
	"methane": {"name": "Liquid Methane", "price": 81, "volume": 0.8, "category": "refined", "class": "icy"},
	"deuterium": {"name": "Deuterium", "price": 152, "volume": 0.5, "category": "refined", "class": "icy"},
	"helium3": {"name": "Helium-3", "price": 765, "volume": 0.3, "category": "refined", "class": "icy"},
	"cryo_coolant": {"name": "Cryo Coolant", "price": 675, "volume": 0.3, "category": "refined", "class": "icy"},
	# --- Manufactured goods & other
	"food": {"name": "Food Rations", "price": 22, "volume": 1.0, "category": "goods"},
	"medicine": {"name": "Medicine", "price": 95, "volume": 0.5, "category": "goods"},
	"alloys": {"name": "Alloys", "price": 70, "volume": 1.0, "category": "goods"},
	"electronics": {"name": "Electronics", "price": 150, "volume": 0.5, "category": "goods"},
	"weapon_parts": {"name": "Weapon Parts", "price": 190, "volume": 1.0, "category": "goods"},
	"salvage": {"name": "Salvage", "price": 30, "volume": 1.0, "category": "loot"},
	"research_data": {"name": "Research Data", "price": 260, "volume": 0.1, "category": "data"},
	# --- Munitions (package 20): mines for mine launchers
	"mine_proximity": {"name": "Proximity Mine", "price": 320, "volume": 0.5, "category": "munitions"},
	"mine_jammer": {"name": "Jammer Mine", "price": 420, "volume": 0.5, "category": "munitions"},
	"mine_timer": {"name": "Timed Mine", "price": 280, "volume": 0.5, "category": "munitions"},
	"mine_emp": {"name": "EMP Mine", "price": 650, "volume": 0.5, "category": "munitions"},
	"sealed_cargo": {"name": "Sealed Cargo", "price": 0, "volume": 1.0, "category": "mission", "tradeable": false},
}

const CLASS_NAMES := {"metallic": "Metallic", "stony": "Stony (Silicate)", "icy": "Icy"}

## produces: station sells cheaply  |  consumes: station pays a premium
## shop: module slots carried by the outfitter  |  shipyard: has a shipyard
## refinery: ore refining efficiency (0 = no refinery)
## manufacturing: module slots the local fabricators can build ([] = none)
## produces: station sells cheaply  |  consumes: station pays a premium
## shop: module slots carried by the outfitter  |  shipyard: has a shipyard
## refinery: refining efficiency per asteroid class (missing / 0 = cannot refine that class)
## manufacturing: module slots the local fabricators can build ([] = none)
const STATION_TYPES := {
	"trade": {"name": "Trade Hub", "produces": ["food", "medicine", "water"], "consumes": ["electronics", "alloys", "platinum_ingot"],
		"shop": ["weapon", "tool", "optional", "hull", "engine", "distributor", "reactor", "tank", "hyperdrive", "sensors"], "shipyard": true,
		"refinery": {"metallic": 0.7, "stony": 0.7, "icy": 0.7}, "manufacturing": ["optional", "tank"]},
	"industry": {"name": "Industrial Complex", "produces": ["alloys", "electronics", "weapon_parts", "iron_ingot", "aluminium", "silicon"],
		"consumes": ["iron_ore", "nickel_ore", "titanium_ore", "cobalt_ore", "bauxite", "silicate_rock", "rare_earth_ore", "xeno_crystal"],
		"shop": ["hull", "engine", "reactor", "distributor", "tank", "optional"], "shipyard": true,
		"refinery": {"metallic": 0.9, "stony": 0.9, "icy": 0.6}, "manufacturing": ["hull", "engine", "reactor", "distributor", "tank", "optional", "weapon"]},
	"mining_colony": {"name": "Mining Colony", "produces": ["iron_ore", "nickel_ore", "titanium_ore", "silicate_rock", "bauxite"],
		"consumes": ["food", "medicine", "alloys", "water"],
		"shop": ["tool", "optional", "tank"], "shipyard": false,
		"refinery": {"metallic": 1.0, "stony": 1.0, "icy": 0.8}, "manufacturing": ["tool"]},
	"agri": {"name": "Agricultural Station", "produces": ["food"], "consumes": ["electronics", "medicine", "alloys", "water", "ammonia"],
		"shop": ["optional", "tank"], "shipyard": false,
		"refinery": {"icy": 0.7}, "manufacturing": []},
	"research": {"name": "Research Station", "produces": ["medicine", "electronics"],
		"consumes": ["research_data", "xeno_crystal", "xeno_lattice", "rare_earths", "cryo_coolant", "helium3"],
		"shop": ["tool", "sensors", "hyperdrive"], "shipyard": false,
		"refinery": {}, "manufacturing": ["tool", "sensors", "hyperdrive"]},
	"military": {"name": "Military Outpost", "produces": ["weapon_parts", "mine_proximity", "mine_jammer", "mine_timer", "mine_emp"], "consumes": ["food", "salvage", "medicine", "deuterium", "cryo_coolant", "neodymium"],
		"shop": ["weapon", "hull", "optional", "sensors", "distributor"], "shipyard": true,
		"refinery": {}, "manufacturing": ["weapon", "hull"]},
	# Phase 0.5 package 6: special stations (converted from the six base types during generation)
	"ice_refinery": {"name": "Ice Refinery", "produces": ["water", "ammonia", "methane", "deuterium", "cryo_coolant"],
		"consumes": ["water_ice", "ammonia_ice", "methane_ice", "deuterium_ice", "helium3_ice", "cryo_crystal", "food", "electronics"],
		"shop": ["tool", "tank", "optional", "reactor"], "shipyard": false,
		"refinery": {"icy": 1.25, "stony": 0.5}, "manufacturing": ["tank", "reactor"]},
	"shipyard": {"name": "Shipyard Complex", "produces": ["weapon_parts", "alloys", "mine_proximity", "mine_timer"],
		"consumes": ["iron_ingot", "titanium_ingot", "cobalt_ingot", "aluminium", "electronics", "alloys", "neodymium"],
		"shop": ["hull", "engine", "reactor", "distributor", "tank", "hyperdrive", "weapon", "optional"], "shipyard": true,
		"refinery": {"metallic": 0.8}, "manufacturing": ["hull", "engine", "reactor", "distributor", "tank", "hyperdrive"]},
	# Phase 0.5 package 26: station type 0 – a small waystation with landing pads instead of hangar bays,
	# only for S and M ships (max_size), an extra station in most systems (not part of the station plan)
	"waystation": {"name": "Waystation", "produces": ["water", "food"], "consumes": ["electronics", "medicine", "deuterium"],
		"shop": [], "shipyard": false,
		"refinery": {}, "manufacturing": [], "max_size": 2,
		# decision for part 4: a fixed small set of services – no shipyard, no outfitter
		"services": ["market", "fuel", "repair", "hangar"]},
}
## Phase 0.5 package 12: Pirate Havens are dockable with pirate standing – black market for
## scarce goods, an outfitter with weapons, no shipyard. Not part of the station plan.
const HAVEN_TYPE := {"name": "Pirate Haven", "produces": ["weapon_parts", "salvage", "mine_proximity", "mine_jammer", "mine_timer", "mine_emp"],
	"consumes": ["food", "medicine", "electronics", "alloys", "water", "xeno_lattice", "helium3"],
	"shop": ["weapon", "optional", "tool"], "shipyard": false,
	"refinery": {"metallic": 0.6, "stony": 0.6}, "manufacturing": []}
## The six base types the generator picks from (the special ones are converted from these).
const BASE_STATION_TYPES := ["trade", "industry", "mining_colony", "agri", "research", "military"]
