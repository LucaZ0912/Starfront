extends RefCounted
## Trade goods and station types.

## tradeable = false: cannot be bought or sold on the market (e.g. mission cargo).
## Raw materials (category "ore") come from three asteroid classes – "class":
##   metallic (M-type), stony (S-type, silicate) and icy.
## "rarity": common / uncommon / rare (rare only in systems with security < 0.5).
## "refines_to" + "yield": refined product and base units out per unit in.
## Package 41: "deep" = only in colossi, for the deep core drill (never in asteroid fields); "radioactive" = needs
## shielded cargo racks, else the crew takes radiation (warning + alarm); category "gas" = harvested from giants
## (takes twice the room in ordinary cargo racks, fits gas tanks); category "components" = built from refined
## materials (Industry.COMPONENTS).
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
	# package 41: new ores – copper, tungsten, gold, uraninite (metallic), spodumene (lithium), graphite, quartz,
	# monazite (stony), nitrogen ice and dry ice (icy); osmium and palladium only deep in colossi
	"copper_ore": {"name": "Copper Ore", "price": 20, "volume": 1.0, "category": "ore", "class": "metallic", "rarity": "common", "refines_to": "copper", "yield": 0.5},
	"tungsten_ore": {"name": "Tungsten Ore", "price": 58, "volume": 1.0, "category": "ore", "class": "metallic", "rarity": "uncommon", "refines_to": "tungsten", "yield": 0.4},
	"gold_ore": {"name": "Gold Ore", "price": 190, "volume": 1.0, "category": "ore", "class": "metallic", "rarity": "rare", "refines_to": "gold", "yield": 0.3},
	"uraninite": {"name": "Uraninite", "price": 160, "volume": 1.0, "category": "ore", "class": "metallic", "rarity": "rare", "refines_to": "enriched_uranium", "yield": 0.25, "radioactive": true},
	"spodumene": {"name": "Spodumene", "price": 22, "volume": 1.0, "category": "ore", "class": "stony", "rarity": "common", "refines_to": "lithium", "yield": 0.45},
	"graphite_ore": {"name": "Graphite Ore", "price": 30, "volume": 1.0, "category": "ore", "class": "stony", "rarity": "uncommon", "refines_to": "graphite", "yield": 0.5},
	"quartz": {"name": "Quartz", "price": 12, "volume": 1.0, "category": "ore", "class": "stony", "rarity": "common", "refines_to": "optical_quartz", "yield": 0.5},
	"monazite": {"name": "Monazite", "price": 70, "volume": 1.0, "category": "ore", "class": "stony", "rarity": "uncommon", "refines_to": "thorium", "yield": 0.3, "radioactive": true},
	"nitrogen_ice": {"name": "Nitrogen Ice", "price": 10, "volume": 1.2, "category": "ore", "class": "icy", "rarity": "common", "refines_to": "liquid_nitrogen", "yield": 0.5},
	"dry_ice": {"name": "Dry Ice", "price": 9, "volume": 1.2, "category": "ore", "class": "icy", "rarity": "common", "refines_to": "carbon_dioxide", "yield": 0.5},
	"osmium_ore": {"name": "Osmium Ore", "price": 320, "volume": 1.0, "category": "ore", "class": "metallic", "rarity": "rare", "refines_to": "osmium", "yield": 0.3, "deep": true},
	"palladium_ore": {"name": "Palladium Ore", "price": 280, "volume": 1.0, "category": "ore", "class": "stony", "rarity": "rare", "refines_to": "palladium", "yield": 0.3, "deep": true},
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
	# package 41: what the new ores refine to
	"copper": {"name": "Copper", "price": 52, "volume": 0.5, "category": "refined", "class": "metallic"},
	"tungsten": {"name": "Tungsten", "price": 190, "volume": 0.5, "category": "refined", "class": "metallic"},
	"gold": {"name": "Gold", "price": 820, "volume": 0.3, "category": "refined", "class": "metallic"},
	"enriched_uranium": {"name": "Enriched Uranium", "price": 900, "volume": 0.3, "category": "refined", "class": "metallic", "radioactive": true},
	"lithium": {"name": "Lithium", "price": 64, "volume": 0.5, "category": "refined", "class": "stony"},
	"graphite": {"name": "Graphite", "price": 78, "volume": 0.5, "category": "refined", "class": "stony"},
	"optical_quartz": {"name": "Optical Quartz", "price": 32, "volume": 0.5, "category": "refined", "class": "stony"},
	"thorium": {"name": "Thorium", "price": 330, "volume": 0.3, "category": "refined", "class": "stony", "radioactive": true},
	"liquid_nitrogen": {"name": "Liquid Nitrogen", "price": 26, "volume": 0.8, "category": "refined", "class": "icy"},
	"carbon_dioxide": {"name": "Carbon Dioxide", "price": 22, "volume": 0.8, "category": "refined", "class": "icy"},
	"osmium": {"name": "Osmium", "price": 1450, "volume": 0.3, "category": "refined", "class": "metallic"},
	"palladium": {"name": "Palladium", "price": 1250, "volume": 0.3, "category": "refined", "class": "stony"},
	# package 41: gases from the giants (gas collector) – twice the room in cargo racks, efficient in gas tanks
	"hydrogen": {"name": "Hydrogen", "price": 14, "volume": 1.0, "category": "gas"},
	"helium": {"name": "Helium", "price": 26, "volume": 1.0, "category": "gas"},
	"nitrogen_gas": {"name": "Nitrogen", "price": 16, "volume": 1.0, "category": "gas"},
	"neon": {"name": "Neon", "price": 95, "volume": 1.0, "category": "gas"},
	"xenon": {"name": "Xenon", "price": 380, "volume": 1.0, "category": "gas"},
	"sulfur_dioxide": {"name": "Sulfur Dioxide", "price": 34, "volume": 1.0, "category": "gas"},
	"phosphine": {"name": "Phosphine", "price": 340, "volume": 1.0, "category": "gas"},
	"chlorine": {"name": "Chlorine", "price": 48, "volume": 1.0, "category": "gas"},
	"ammonia_gas": {"name": "Ammonia Gas", "price": 30, "volume": 1.0, "category": "gas"},
	"fluorine": {"name": "Fluorine", "price": 420, "volume": 1.0, "category": "gas"},
	"helium3_gas": {"name": "Helium-3 Gas", "price": 520, "volume": 1.0, "category": "gas"},
	# package 41: components – built from refined materials at a station's fabricators (Industry.COMPONENTS)
	"circuits": {"name": "Circuit Boards", "price": 300, "volume": 0.3, "category": "components"},
	"battery_cells": {"name": "Battery Cells", "price": 260, "volume": 0.5, "category": "components"},
	"armor_plating": {"name": "Armor Plating", "price": 560, "volume": 1.0, "category": "components"},
	"carbon_fiber": {"name": "Carbon Fiber", "price": 240, "volume": 0.5, "category": "components"},
	"ion_propellant": {"name": "Ion Propellant", "price": 900, "volume": 0.5, "category": "components"},
	"magnet_coils": {"name": "Magnet Coils", "price": 2100, "volume": 0.5, "category": "components"},
	"fusion_cells": {"name": "Fusion Cells", "price": 2300, "volume": 0.3, "category": "components"},
	"fuel_rods": {"name": "Fuel Rods", "price": 2600, "volume": 0.5, "category": "components", "radioactive": true},
	"tritium": {"name": "Tritium", "price": 1900, "volume": 0.2, "category": "components", "radioactive": true},
	"medical_isotopes": {"name": "Medical Isotopes", "price": 1600, "volume": 0.1, "category": "components", "radioactive": true},
	"precision_optics": {"name": "Precision Optics", "price": 700, "volume": 0.3, "category": "components"},
	"cryo_systems": {"name": "Cryo Systems", "price": 420, "volume": 0.5, "category": "components"},
	# --- Manufactured goods & other
	"food": {"name": "Food Rations", "price": 22, "volume": 1.0, "category": "goods"},
	"medicine": {"name": "Medicine", "price": 95, "volume": 0.5, "category": "goods"},
	"alloys": {"name": "Alloys", "price": 70, "volume": 1.0, "category": "goods"},
	"electronics": {"name": "Electronics", "price": 150, "volume": 0.5, "category": "goods"},
	"weapon_parts": {"name": "Weapon Parts", "price": 190, "volume": 1.0, "category": "goods"},
	# --- Package 42: trade goods of the nine economies (econ = made in such systems, wants = wanted there;
	#     lux = wanted in wealthy and rich systems, basic = needed everywhere; trade_only = never an ingredient)
	"grain": {"name": "Grain", "price": 12, "volume": 1.0, "category": "goods", "econ": "agri", "wants": ["industry", "military", "chemistry"], "basic": true},
	"fresh_produce": {"name": "Fresh Produce", "price": 30, "volume": 1.0, "category": "goods", "econ": "agri", "wants": ["mining", "industry", "tourism"]},
	"protein": {"name": "Cultured Protein", "price": 40, "volume": 1.0, "category": "goods", "econ": "agri", "wants": ["military", "mining", "research"]},
	"coffee": {"name": "Coffee", "price": 85, "volume": 0.5, "category": "goods", "econ": "agri", "wants": ["research", "hightech"], "lux": true},
	"spices": {"name": "Spices", "price": 120, "volume": 0.3, "category": "goods", "econ": "agri", "wants": ["tourism"], "lux": true},
	"fine_wine": {"name": "Fine Wine", "price": 260, "volume": 0.5, "category": "goods", "econ": "agri", "wants": ["tourism"], "lux": true},
	"seed_stock": {"name": "Seed Stock", "price": 70, "volume": 0.5, "category": "goods", "econ": "agri", "wants": [], "trade_only": true},
	"regolith": {"name": "Construction Regolith", "price": 8, "volume": 2.0, "category": "goods", "econ": "mining", "wants": ["industry", "refinery"]},
	"industrial_diamonds": {"name": "Industrial Diamonds", "price": 180, "volume": 0.1, "category": "goods", "econ": "mining", "wants": ["industry", "hightech"]},
	"gemstones": {"name": "Raw Gemstones", "price": 320, "volume": 0.1, "category": "goods", "econ": "mining", "wants": ["tourism"], "lux": true},
	"drill_bits": {"name": "Drill Bits", "price": 110, "volume": 1.0, "category": "goods", "econ": "industry", "wants": ["mining"]},
	"machinery": {"name": "Machinery", "price": 210, "volume": 3.0, "category": "goods", "econ": "industry", "wants": ["mining", "agri", "refinery"]},
	"hand_tools": {"name": "Hand Tools", "price": 60, "volume": 1.0, "category": "goods", "econ": "industry", "wants": ["mining", "agri"]},
	"consumer_goods": {"name": "Consumer Goods", "price": 75, "volume": 1.0, "category": "goods", "econ": "industry", "wants": ["agri", "mining", "tourism"], "basic": true},
	"textiles": {"name": "Textiles", "price": 45, "volume": 1.0, "category": "goods", "econ": "industry", "wants": ["military", "tourism"]},
	"furniture": {"name": "Furniture", "price": 90, "volume": 3.0, "category": "goods", "econ": "industry", "wants": ["tourism"]},
	"ground_vehicles": {"name": "Ground Vehicles", "price": 600, "volume": 6.0, "category": "goods", "econ": "industry", "wants": ["mining", "agri", "military"]},
	"prefab_habitats": {"name": "Prefab Habitat Modules", "price": 900, "volume": 10.0, "category": "goods", "econ": "industry", "wants": ["research", "mining"]},
	"robots": {"name": "Industrial Robots", "price": 750, "volume": 2.0, "category": "goods", "econ": "industry", "wants": ["mining", "refinery", "agri"]},
	"steel": {"name": "Steel Beams", "price": 55, "volume": 2.0, "category": "goods", "econ": "refinery", "wants": ["industry", "military"]},
	"refined_fuel": {"name": "Refined Fuel", "price": 40, "volume": 1.0, "category": "goods", "econ": "refinery", "wants": ["mining", "agri", "military", "tourism"], "basic": true},
	"lubricants": {"name": "Lubricants", "price": 50, "volume": 1.0, "category": "goods", "econ": "refinery", "wants": ["industry", "mining"]},
	"glass": {"name": "Glass Panels", "price": 35, "volume": 2.0, "category": "goods", "econ": "refinery", "wants": ["agri", "industry", "tourism"]},
	"composites": {"name": "Construction Composites", "price": 80, "volume": 2.0, "category": "goods", "econ": "refinery", "wants": ["industry", "military"]},
	"plastics": {"name": "Plastics", "price": 40, "volume": 1.0, "category": "goods", "econ": "chemistry", "wants": ["industry", "hightech"]},
	"acids": {"name": "Industrial Acids", "price": 35, "volume": 1.0, "category": "goods", "econ": "chemistry", "wants": ["refinery", "mining"]},
	"solvents": {"name": "Solvents", "price": 45, "volume": 1.0, "category": "goods", "econ": "chemistry", "wants": ["hightech", "industry"]},
	"pharma_precursors": {"name": "Pharmaceutical Precursors", "price": 140, "volume": 0.5, "category": "goods", "econ": "chemistry", "wants": ["hightech", "research"]},
	"dyes": {"name": "Dyes and Pigments", "price": 70, "volume": 0.5, "category": "goods", "econ": "chemistry", "wants": ["industry"]},
	"explosives": {"name": "Mining Explosives", "price": 60, "volume": 1.0, "category": "goods", "econ": "chemistry", "wants": ["mining", "military"]},
	"fertiliser": {"name": "Fertiliser", "price": 26, "volume": 1.0, "category": "goods", "econ": "chemistry", "wants": ["agri"]},
	"consumer_electronics": {"name": "Consumer Electronics", "price": 280, "volume": 0.5, "category": "goods", "econ": "hightech", "wants": ["tourism", "agri", "mining"]},
	"computers": {"name": "Computers", "price": 420, "volume": 0.5, "category": "goods", "econ": "hightech", "wants": ["research", "industry", "military"]},
	"medical_equipment": {"name": "Medical Equipment", "price": 650, "volume": 1.0, "category": "goods", "econ": "hightech", "wants": ["military", "mining"], "basic": true},
	"holo_displays": {"name": "Holo Displays", "price": 380, "volume": 0.5, "category": "goods", "econ": "hightech", "wants": ["tourism"], "lux": true},
	"nanites": {"name": "Nanite Cultures", "price": 900, "volume": 0.1, "category": "goods", "econ": "hightech", "wants": ["research", "military"]},
	"implants": {"name": "Cybernetic Implants", "price": 1100, "volume": 0.1, "category": "goods", "econ": "hightech", "wants": ["military"], "lux": true},
	"ai_cores": {"name": "AI Cores", "price": 1400, "volume": 0.2, "category": "goods", "econ": "hightech", "wants": ["research", "industry"]},
	"lab_equipment": {"name": "Laboratory Equipment", "price": 480, "volume": 1.0, "category": "goods", "econ": "hightech", "wants": ["research"]},
	"star_charts": {"name": "Star Charts", "price": 220, "volume": 0.1, "category": "goods", "econ": "research", "wants": [], "trade_only": true},
	"prototypes": {"name": "Prototype Parts", "price": 800, "volume": 0.5, "category": "goods", "econ": "research", "wants": ["hightech", "military"]},
	"gene_samples": {"name": "Gene Samples", "price": 260, "volume": 0.1, "category": "goods", "econ": "research", "wants": ["agri", "hightech"]},
	"exotic_specimens": {"name": "Exotic Specimens", "price": 480, "volume": 0.5, "category": "goods", "econ": "research", "wants": ["tourism"], "lux": true, "trade_only": true},
	"small_arms": {"name": "Small Arms", "price": 240, "volume": 0.5, "category": "goods", "econ": "military", "wants": [], "trade_only": true},
	"ammunition": {"name": "Ammunition", "price": 60, "volume": 1.0, "category": "goods", "econ": "military", "wants": ["mining"]},
	"body_armour": {"name": "Body Armour", "price": 320, "volume": 1.0, "category": "goods", "econ": "military", "wants": ["mining", "industry"]},
	"field_rations": {"name": "Field Rations", "price": 35, "volume": 1.0, "category": "goods", "econ": "military", "wants": [], "trade_only": true},
	"combat_drones": {"name": "Combat Drones", "price": 900, "volume": 2.0, "category": "goods", "econ": "military", "wants": [], "trade_only": true},
	"souvenirs": {"name": "Souvenirs", "price": 30, "volume": 0.5, "category": "goods", "econ": "tourism", "wants": [], "trade_only": true},
	"holo_films": {"name": "Holo Films", "price": 120, "volume": 0.1, "category": "goods", "econ": "tourism", "wants": ["mining", "military"]},
	"luxury_goods": {"name": "Luxury Goods", "price": 500, "volume": 0.5, "category": "goods", "econ": "industry", "wants": ["tourism"], "lux": true},
	"jewellery": {"name": "Jewellery", "price": 900, "volume": 0.1, "category": "goods", "econ": "industry", "wants": ["tourism"], "lux": true},
	"perfume": {"name": "Perfume", "price": 350, "volume": 0.1, "category": "goods", "econ": "chemistry", "wants": ["tourism"], "lux": true},
	"designer_clothing": {"name": "Designer Clothing", "price": 400, "volume": 0.5, "category": "goods", "econ": "industry", "wants": ["tourism"], "lux": true},
	"spirits": {"name": "Spirits", "price": 180, "volume": 0.5, "category": "goods", "econ": "agri", "wants": ["mining", "military", "tourism"], "lux": true},
	"artworks": {"name": "Artworks", "price": 2000, "volume": 1.0, "category": "goods", "econ": "tourism", "wants": [], "lux": true, "trade_only": true},
	"salvage": {"name": "Salvage", "price": 30, "volume": 1.0, "category": "loot"},
	"research_data": {"name": "Research Data", "price": 260, "volume": 0.1, "category": "data"},
	# --- Munitions (package 20): mines for mine launchers
	"mine_proximity": {"name": "Proximity Mine", "price": 320, "volume": 0.5, "category": "munitions"},
	"mine_jammer": {"name": "Jammer Mine", "price": 420, "volume": 0.5, "category": "munitions"},
	"mine_timer": {"name": "Timed Mine", "price": 280, "volume": 0.5, "category": "munitions"},
	"mine_emp": {"name": "EMP Mine", "price": 650, "volume": 0.5, "category": "munitions"},
	"sealed_cargo": {"name": "Sealed Cargo", "price": 0, "volume": 1.0, "category": "mission", "tradeable": false},
	# package 39b: found in anomalies, laid in the Cathedral of Return for a blessing
	"earth_relic": {"name": "Relic of Earth", "price": 0, "volume": 0.5, "category": "mission", "tradeable": false},
}

## Package 42: the economy of the goods that came before Wirtschaft 2.0 (made / wanted / flags) – ores and gases come
## from mining, refined materials from refining, components from industry or high-tech.
const OLD_GOODS_ECON := {
	"food": ["agri", ["mining", "industry", "military", "research"], {"basic": true}],
	"water": ["agri", ["mining", "industry", "military"], {"basic": true}],
	"medicine": ["hightech", ["mining", "military", "agri"], {"basic": true}],
	"alloys": ["refinery", ["industry", "military", "agri"], {}],
	"electronics": ["hightech", ["industry", "agri", "research"], {}],
	"weapon_parts": ["industry", ["military"], {}],                 # industry makes them, the military uses them
	"gold": ["refinery", ["tourism", "hightech"], {"lux": true}],
	"platinum_ingot": ["refinery", ["hightech", "tourism"], {"lux": true}],
	"mine_proximity": ["military", [], {}], "mine_jammer": ["military", [], {}], "mine_timer": ["military", [], {}], "mine_emp": ["military", [], {}],
	"salvage": ["", ["refinery", "industry"], {}],
	"research_data": ["research", ["hightech"], {}],
}
## Package 42b: who wants each raw material – finer than "industry and high-tech" for all of them.
const RAW_WANTS := {
	# metals
	"iron_ingot": ["industry", "military"], "nickel_ingot": ["industry", "hightech"], "titanium_ingot": ["military", "industry"],
	"cobalt_ingot": ["hightech", "industry"], "iridium_ingot": ["hightech", "research"], "aluminium": ["industry", "agri"],
	"magnesium": ["industry", "chemistry"], "neodymium": ["hightech", "military"], "copper": ["industry", "hightech"],
	"tungsten": ["military", "industry"], "lithium": ["hightech", "industry"], "osmium": ["research", "military"],
	"palladium": ["hightech", "chemistry"],
	# minerals
	"silicon": ["hightech", "industry"], "rare_earths": ["hightech", "research"], "xeno_lattice": ["research", "hightech"],
	"graphite": ["industry", "refinery"], "optical_quartz": ["hightech", "research"],
	# nuclear materials
	"enriched_uranium": ["military", "industry"], "thorium": ["research", "hightech"],
	# fuels and coolants
	"ammonia": ["agri", "chemistry"], "methane": ["chemistry", "industry"], "deuterium": ["military", "research", "industry"],
	"helium3": ["research", "military"], "cryo_coolant": ["research", "military"], "liquid_nitrogen": ["agri", "hightech"],
	"carbon_dioxide": ["agri", "chemistry"],
	# ices (beside the refineries)
	"water_ice": ["refinery", "agri"], "ammonia_ice": ["refinery", "chemistry"], "methane_ice": ["refinery", "chemistry"],
	# gases
	"hydrogen": ["chemistry", "industry"], "helium": ["industry", "research"], "nitrogen_gas": ["agri", "chemistry"],
	"neon": ["hightech", "industry"], "xenon": ["military", "research"], "sulfur_dioxide": ["chemistry", "refinery"],
	"phosphine": ["chemistry", "research"], "chlorine": ["chemistry", "refinery"], "ammonia_gas": ["agri", "chemistry"],
	"fluorine": ["chemistry", "hightech"], "helium3_gas": ["research", "military"],
}

## Package 42b: the categories of the market (in this order) and the goods that do not follow from their data.
const MARKET_CATEGORIES := [
	["ores", "Ores"], ["ices", "Ices"], ["gases", "Gases"], ["metals", "Metals"], ["minerals", "Minerals"],
	["nuclear", "Nuclear Materials"], ["fuels", "Fuels & Coolants"], ["components", "Components"], ["food", "Food"],
	["chemicals", "Chemicals"], ["industrial", "Industrial Goods"], ["consumer", "Consumer Goods"],
	["hightech", "High-Tech & Medical"], ["science", "Science"], ["military", "Military Goods"], ["luxury", "Luxury Goods"],
]
const GOODS_CATEGORY := {
	"silicon": "minerals", "rare_earths": "minerals", "xeno_lattice": "minerals", "graphite": "minerals", "optical_quartz": "minerals",
	"enriched_uranium": "nuclear", "thorium": "nuclear",
	"ammonia": "fuels", "methane": "fuels", "deuterium": "fuels", "helium3": "fuels", "cryo_coolant": "fuels",
	"liquid_nitrogen": "fuels", "carbon_dioxide": "fuels", "refined_fuel": "fuels",
	"water": "food", "food": "food", "grain": "food", "fresh_produce": "food", "protein": "food", "coffee": "food", "spices": "food",
	"seed_stock": "food", "field_rations": "food",
	"plastics": "chemicals", "acids": "chemicals", "solvents": "chemicals", "pharma_precursors": "chemicals", "dyes": "chemicals",
	"explosives": "chemicals", "fertiliser": "chemicals",
	"alloys": "industrial", "steel": "industrial", "composites": "industrial", "glass": "industrial", "lubricants": "industrial",
	"regolith": "industrial", "industrial_diamonds": "industrial", "drill_bits": "industrial", "machinery": "industrial",
	"hand_tools": "industrial", "robots": "industrial", "ground_vehicles": "industrial", "prefab_habitats": "industrial", "salvage": "industrial",
	"consumer_goods": "consumer", "textiles": "consumer", "furniture": "consumer", "consumer_electronics": "consumer",
	"holo_films": "consumer", "souvenirs": "consumer",
	"electronics": "hightech", "computers": "hightech", "medicine": "hightech", "medical_equipment": "hightech", "nanites": "hightech",
	"implants": "hightech", "ai_cores": "hightech", "lab_equipment": "hightech", "holo_displays": "hightech",
	"research_data": "science", "star_charts": "science", "prototypes": "science", "gene_samples": "science", "exotic_specimens": "science",
	"weapon_parts": "military", "small_arms": "military", "ammunition": "military", "body_armour": "military", "combat_drones": "military",
	"fine_wine": "luxury", "spirits": "luxury", "perfume": "luxury", "jewellery": "luxury", "luxury_goods": "luxury",
	"designer_clothing": "luxury", "artworks": "luxury", "gemstones": "luxury",
}

## Components (package 41): who makes and who wants them.
const COMPONENT_ECON := {
	"circuits": ["hightech", ["industry", "military"]], "battery_cells": ["industry", ["mining", "agri", "military"]],
	"armor_plating": ["industry", ["military"]], "carbon_fiber": ["industry", ["hightech", "military"]],
	"ion_propellant": ["chemistry", ["military", "research"]], "magnet_coils": ["industry", ["hightech", "research"]],
	"fusion_cells": ["hightech", ["industry", "military"]], "fuel_rods": ["refinery", ["industry", "military"]],
	"tritium": ["chemistry", ["military", "research"]], "medical_isotopes": ["research", ["hightech", "military"]],
	"precision_optics": ["hightech", ["research", "military"]], "cryo_systems": ["industry", ["research", "agri"]],
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
