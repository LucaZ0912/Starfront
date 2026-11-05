extends RefCounted
## Equipment modules (phase 0.5 package 19): every module is a FAMILY + SIZE + QUALITY.
## Module id "<family>:<size>:<quality>", e.g. "w_pulse:2:C" (shown as "Pulse Laser 2 · C").
##
## A family fixes what a module is (slot, damage type, tool, special effects) and its size range;
## its numbers come from an ANCHOR (a module of the earlier S/M/L system) at a reference size.
## Size scales the values along curves, quality shifts performance, mass, power and price.
## build_all() generates every family in every allowed size and quality (GameData.modules).
##
## Common fields of a generated module: name, family, base_name, size, quality, slot, price, mass, power
## Slot-specific fields as in the anchors below:
##   hull:        armor, res {optical/kinetic/explosive: 0..1}
##   engine:      thrust (kN), turn (rad/s)
##   distributor: capacitor, recharge (/s), efficiency (multiplier on reactor output)
##   reactor:     output (MW)
##   tank:        fuel
##   hyperdrive:  drive_class (max. route class from the size: 1–2 → 1, 3–4 → 2, 5–6 → 3), jump_fuel, spool (s)
##   sensors:     range, resolution (target lock), scan_strength
##   weapon:      damage_type, damage, cooldown, range, energy, projectile_speed (0 = beam), splash, homing
##   tool:        tool (scanner/analyzer/mining/harvester/salvage/repair/survey/prospect/warrant/interdict/
##                shield_transfer/cargo_scan), strength/rate, range, energy, energy_rate, scan_time, accuracy
##   weapon extras (package 20): pd = point defense (intercept chance, shoots missiles and mines),
##                mines = mine launcher (max_mines laid at once, uses mines from the cargo hold)
##   optional:    cargo, ore_cargo, shield, shield_regen, armor, fuel, speed_mult, range_mult, res_bonus, cap_bonus,
##                mining_bonus {class: +x}, survey_range_mult; active modules: active (afterburner/shield_boost/
##                armor_repair/jammer), boost / rate, energy_rate (capacitor per second while on)
##                shield_kind (balanced/capacity/regen – sets the downtime after a shield collapse),
##                solar (fuel per second next to the star), jam_range (radar jammer radius)

const QUALITIES := ["F", "E", "D", "C", "B", "A"]          # S and S+ follow in the endgame
## perf = performance, mass, power draw and price factors per quality (D is the lightest, F the
## heaviest, B as heavy as A – A is better)
const QUALITY := {
	"F": {"perf": 0.80, "mass": 1.25, "power": 0.94, "price": 0.55},
	"E": {"perf": 0.88, "mass": 1.10, "power": 0.96, "price": 0.70},
	"D": {"perf": 0.95, "mass": 0.90, "power": 0.98, "price": 0.85},
	"C": {"perf": 1.00, "mass": 1.00, "power": 1.00, "price": 1.00},
	"B": {"perf": 1.08, "mass": 1.08, "power": 1.04, "price": 1.40},
	"A": {"perf": 1.16, "mass": 1.08, "power": 1.08, "price": 2.00},
}
const QUALITY_COLORS := {"F": Color(0.55, 0.5, 0.48), "E": Color(0.7, 0.68, 0.62), "D": Color(0.72, 0.85, 0.72),
	"C": Color(0.85, 0.9, 1.0), "B": Color(0.45, 0.8, 1.0), "A": Color(1.0, 0.75, 0.3)}
## Size curves: value ∝ (size / reference size) ^ exponent
const EXP_MASS := 1.2
const EXP_POWER := 1.1
const EXP_PRICE := 1.6
## Exponent per field (fields not listed stay constant); quality scales every listed field except energy
const FIELD_EXP := {
	"damage": 1.3, "armor": 1.3, "shield": 1.3, "shield_regen": 1.3, "thrust": 1.3, "output": 1.3,
	"capacitor": 1.3, "recharge": 1.3, "fuel": 1.3, "cargo": 1.3, "ore_cargo": 1.3, "rate": 1.3,
	"cap_bonus": 1.3, "cap_drain": 1.3, "strength": 1.0, "jump_fuel": 1.0,
	"range": 0.35, "resolution": 0.2, "scan_strength": 0.6, "splash": 0.5, "res_bonus": 0.5,
	"energy": 1.1, "energy_rate": 1.1,
	"intercept": 0.15, "solar": 1.3, "jam_range": 0.5, "max_mines": 1.0,
}
## Balancing on top of the anchors (alpha 0.4.22.3)
const RANGE_BUFF := {"weapon": 1.10, "sensors": 1.15}
## Multipliers: only the part above 1 grows (with the square root of the size ratio)
const MULT_FIELDS := ["boost", "range_mult", "survey_range_mult", "speed_mult", "efficiency"]
## Size ranges per slot type (family ranges lie inside)
const SIZE_RANGE := {"weapon": [1, 4], "tool": [1, 4], "optional": [1, 8], "hull": [1, 10], "engine": [1, 10],
	"reactor": [1, 10], "distributor": [1, 10], "tank": [1, 10], "hyperdrive": [1, 6], "sensors": [1, 8]}

## Families: name, anchor module, reference size of the anchor, allowed sizes [min, max],
## optional field exponent overrides ("exp").
const FAMILIES := {
	# hull plating (core)
	"pl_standard": {"name": "Standard Plating", "anchor": "hull_std_s", "ref": 2, "sizes": [1, 10]},
	"pl_reflective": {"name": "Reflective Plating", "anchor": "hull_reflect_s", "ref": 2, "sizes": [1, 10]},
	"pl_ablative": {"name": "Ablative Plating", "anchor": "hull_ablative_s", "ref": 2, "sizes": [1, 10]},
	# engines
	"eng_chemical": {"name": "Chemical Thruster", "anchor": "eng_chem_s", "ref": 2, "sizes": [1, 8]},
	"eng_ion": {"name": "Ion Drive", "anchor": "eng_ion_s", "ref": 2, "sizes": [1, 10]},
	"eng_plasma": {"name": "Plasma Drive", "anchor": "eng_plasma_m", "ref": 5, "sizes": [3, 10]},
	# power
	"dist_basic": {"name": "Power Distributor", "anchor": "dist_basic_s", "ref": 2, "sizes": [1, 8]},
	"dist_precision": {"name": "Precision Power Distributor", "anchor": "dist_adv_s", "ref": 2, "sizes": [1, 10]},
	"rea_fission": {"name": "Fission Reactor", "anchor": "rea_fission_s", "ref": 2, "sizes": [1, 8]},
	"rea_fusion": {"name": "Fusion Reactor", "anchor": "rea_fusion_s", "ref": 2, "sizes": [1, 10]},
	"tank": {"name": "Fuel Tank", "anchor": "tank_s", "ref": 2, "sizes": [1, 10]},
	"hyperdrive": {"name": "Jump Drive", "anchor": "hyp_c1_s", "ref": 2, "sizes": [1, 6]},
	# sensors
	"sen_basic": {"name": "Basic Sensor Suite", "anchor": "sen_basic_s", "ref": 2, "sizes": [1, 6]},
	"sen_radar": {"name": "Radar Array", "anchor": "sen_radar_s", "ref": 2, "sizes": [1, 8]},
	"sen_grav": {"name": "Gravimetric Array", "anchor": "sen_grav_m", "ref": 5, "sizes": [2, 8]},
	"sen_tactical": {"name": "Tactical Sensor System", "anchor": "sen_tactical_m", "ref": 5, "sizes": [2, 8]},
	# weapons (1–4)
	"w_pulse": {"name": "Pulse Laser", "anchor": "w_pulse_s", "ref": 1, "sizes": [1, 3]},
	"w_beam": {"name": "Beam Laser", "anchor": "w_beam_m", "ref": 2, "sizes": [2, 4]},
	"w_lance": {"name": "Photon Lance", "anchor": "w_lance_l", "ref": 3, "sizes": [3, 4]},
	"w_autocannon": {"name": "Autocannon", "anchor": "w_autocannon_s", "ref": 1, "sizes": [1, 3]},
	"w_railgun": {"name": "Railgun", "anchor": "w_railgun_m", "ref": 2, "sizes": [2, 4]},
	"w_massdriver": {"name": "Mass Driver", "anchor": "w_massdriver_l", "ref": 3, "sizes": [3, 4]},
	"w_rocket": {"name": "Rocket Launcher", "anchor": "w_rocket_s", "ref": 1, "sizes": [1, 3]},
	"w_torpedo": {"name": "Torpedo Bay", "anchor": "w_torpedo_m", "ref": 2, "sizes": [2, 4]},
	"w_cruise": {"name": "Cruise Missile Silo", "anchor": "w_cruise_l", "ref": 3, "sizes": [3, 4]},
	"w_ion": {"name": "Ion Disruptor", "anchor": "w_ion_s", "ref": 1, "sizes": [1, 2]},
	"w_ionsiphon": {"name": "Ion Siphon", "anchor": "w_ion_m", "ref": 2, "sizes": [2, 3]},
	"w_iontorpedo": {"name": "Ion Torpedo", "anchor": "w_ion_torpedo", "ref": 1, "sizes": [1, 1]},
	# package 20: point defense and mine launcher
	"w_pointdef": {"name": "Point Defense Turret", "anchor": "w_pointdef_s", "ref": 1, "sizes": [1, 3]},
	"w_minelayer": {"name": "Mine Launcher", "anchor": "w_minelayer_s", "ref": 1, "sizes": [1, 3]},
	# tools (1–4)
	"t_scanner": {"name": "Signature Scanner", "anchor": "t_scanner_s", "ref": 1, "sizes": [1, 3], "exp": {"range": 0.6}},
	"t_analyzer": {"name": "Analyzer", "anchor": "t_analyzer_s", "ref": 1, "sizes": [1, 3]},
	"t_mining": {"name": "Mining Laser", "anchor": "t_mining_s", "ref": 1, "sizes": [1, 3]},
	"t_stripminer": {"name": "Strip Miner", "anchor": "t_stripminer_l", "ref": 3, "sizes": [3, 4]},
	"t_harvester": {"name": "Ice Harvester", "anchor": "t_harvester_s", "ref": 1, "sizes": [1, 3]},
	"t_salvage": {"name": "Salvager", "anchor": "t_salvage_s", "ref": 1, "sizes": [1, 3]},
	"t_repair": {"name": "Repair Beam", "anchor": "t_repair_s", "ref": 1, "sizes": [1, 3]},
	"t_survey": {"name": "Long-Range Survey Scanner", "anchor": "t_survey_s", "ref": 1, "sizes": [1, 4], "exp": {"range": 0.9}},
	"t_prospector": {"name": "Prospector Scanner", "anchor": "t_prospector_s", "ref": 1, "sizes": [1, 3]},
	"t_warrant": {"name": "Warrant Scanner", "anchor": "t_warrant_s", "ref": 1, "sizes": [1, 2]},
	"t_interdictor": {"name": "Warp Interdictor", "anchor": "t_interdictor_s", "ref": 1, "sizes": [1, 2], "exp": {"range": 1.1}},
	"t_shieldxfer": {"name": "Shield Transfer Beam", "anchor": "t_shieldxfer_s", "ref": 1, "sizes": [1, 3]},
	"t_cargoscan": {"name": "Cargo Scanner", "anchor": "t_cargoscan_s", "ref": 1, "sizes": [1, 2]},
	# optional (1–8, cargo and ore hold up to 10)
	"o_cargo": {"name": "Cargo Rack", "anchor": "o_cargo_s", "ref": 1, "sizes": [1, 10]},
	"o_shield": {"name": "Shield Generator", "anchor": "o_shield_s", "ref": 1, "sizes": [1, 8]},
	"o_shield_cap": {"name": "Capacitive Shield", "anchor": "o_shield_cap_s", "ref": 1, "sizes": [1, 8]},
	"o_shield_fast": {"name": "Fast-Cycle Shield", "anchor": "o_shield_fast_s", "ref": 1, "sizes": [1, 8]},
	"o_jammer": {"name": "Radar Jammer", "anchor": "o_jammer_s", "ref": 1, "sizes": [1, 4]},
	"o_solar": {"name": "Solar Collector", "anchor": "o_solar_s", "ref": 1, "sizes": [1, 4]},
	"o_armor": {"name": "Armor Plates", "anchor": "o_armor_s", "ref": 1, "sizes": [1, 8]},
	"o_afterburner": {"name": "Afterburner", "anchor": "o_afterburner_m", "ref": 3, "sizes": [1, 6]},
	"o_shieldboost": {"name": "Shield Booster", "anchor": "o_shieldboost_s", "ref": 1, "sizes": [1, 8]},
	"o_armorrep": {"name": "Armor Repairer", "anchor": "o_armorrep_s", "ref": 1, "sizes": [1, 8]},
	"o_orehold": {"name": "Ore Hold", "anchor": "o_orehold_s", "ref": 1, "sizes": [1, 10]},
	"o_mining_metal": {"name": "Metallic Mining Upgrade", "anchor": "o_mining_metal_s", "ref": 1, "sizes": [1, 4]},
	"o_mining_stone": {"name": "Silicate Mining Upgrade", "anchor": "o_mining_stone_s", "ref": 1, "sizes": [1, 4]},
	"o_mining_ice": {"name": "Cryo Mining Upgrade", "anchor": "o_mining_ice_s", "ref": 1, "sizes": [1, 4]},
	"o_survey_amp": {"name": "Survey Range Amplifier", "anchor": "o_survey_amp_s", "ref": 1, "sizes": [1, 3]},
	"o_targeting": {"name": "Targeting Computer", "anchor": "o_targeting_s", "ref": 1, "sizes": [1, 4]},
	"o_fuel": {"name": "Auxiliary Tank", "anchor": "o_fuel_s", "ref": 1, "sizes": [1, 6]},
	"o_capacitor": {"name": "Capacitor Bank", "anchor": "o_capacitor_s", "ref": 1, "sizes": [1, 6]},
}

## Modules of the earlier S/M/L system (presets, start storage, tests): old id -> [family, size].
const LEGACY := {
	"hull_std_s": ["pl_standard", 2], "hull_reflect_s": ["pl_reflective", 2], "hull_ablative_s": ["pl_ablative", 2],
	"hull_composite_m": ["pl_standard", 5], "hull_reflect_m": ["pl_reflective", 5], "hull_heavy_l": ["pl_standard", 8],
	"eng_chem_s": ["eng_chemical", 2], "eng_ion_s": ["eng_ion", 2], "eng_plasma_m": ["eng_plasma", 5], "eng_ion_m": ["eng_ion", 5], "eng_fusion_l": ["eng_plasma", 8],
	"dist_basic_s": ["dist_basic", 2], "dist_adv_s": ["dist_precision", 2], "dist_m": ["dist_basic", 5], "dist_l": ["dist_precision", 8],
	"rea_fission_s": ["rea_fission", 2], "rea_fusion_s": ["rea_fusion", 2], "rea_fusion_m": ["rea_fusion", 5], "rea_antimatter_l": ["rea_fusion", 8],
	"tank_s": ["tank", 2], "tank_m": ["tank", 5], "tank_l": ["tank", 8],
	"hyp_c1_s": ["hyperdrive", 2], "hyp_c2_s": ["hyperdrive", 3], "hyp_c2_m": ["hyperdrive", 4], "hyp_c3_m": ["hyperdrive", 5], "hyp_c3_l": ["hyperdrive", 6],
	"sen_basic_s": ["sen_basic", 2], "sen_radar_s": ["sen_radar", 2], "sen_grav_m": ["sen_grav", 5], "sen_tactical_m": ["sen_tactical", 5], "sen_deep_l": ["sen_grav", 8],
	"w_pulse_s": ["w_pulse", 1], "w_beam_m": ["w_beam", 2], "w_lance_l": ["w_lance", 3],
	"w_autocannon_s": ["w_autocannon", 1], "w_railgun_m": ["w_railgun", 2], "w_massdriver_l": ["w_massdriver", 3],
	"w_rocket_s": ["w_rocket", 1], "w_torpedo_m": ["w_torpedo", 2], "w_cruise_l": ["w_cruise", 3],
	"w_ion_s": ["w_ion", 1], "w_ion_m": ["w_ionsiphon", 2], "w_ion_torpedo": ["w_iontorpedo", 1],
	"t_scanner_s": ["t_scanner", 1], "t_scanner_m": ["t_scanner", 2], "t_analyzer_s": ["t_analyzer", 1], "t_analyzer_m": ["t_analyzer", 2],
	"t_mining_s": ["t_mining", 1], "t_mining_m": ["t_mining", 2], "t_stripminer_l": ["t_stripminer", 3],
	"t_harvester_s": ["t_harvester", 1], "t_harvester_m": ["t_harvester", 2], "t_salvage_s": ["t_salvage", 1],
	"t_repair_s": ["t_repair", 1], "t_repair_m": ["t_repair", 2],
	"t_survey_s": ["t_survey", 1], "t_survey_m": ["t_survey", 2], "t_survey_l": ["t_survey", 3],
	"t_prospector_s": ["t_prospector", 1], "t_prospector_m": ["t_prospector", 2], "t_warrant_s": ["t_warrant", 1],
	"t_interdictor_s": ["t_interdictor", 1], "t_interdictor_m": ["t_interdictor", 2],
	"o_cargo_s": ["o_cargo", 1], "o_cargo_m": ["o_cargo", 3], "o_cargo_l": ["o_cargo", 5],
	"o_shield_s": ["o_shield", 1], "o_shield_m": ["o_shield", 3], "o_shield_l": ["o_shield", 5],
	"o_armor_s": ["o_armor", 1], "o_armor_m": ["o_armor", 3],
	"o_afterburner_s": ["o_afterburner", 1], "o_afterburner_m": ["o_afterburner", 3], "o_afterburner_l": ["o_afterburner", 5],
	"o_shieldboost_s": ["o_shieldboost", 1], "o_shieldboost_m": ["o_shieldboost", 3], "o_shieldboost_l": ["o_shieldboost", 5],
	"o_armorrep_s": ["o_armorrep", 1], "o_armorrep_m": ["o_armorrep", 3], "o_armorrep_l": ["o_armorrep", 5],
	"o_orehold_s": ["o_orehold", 1], "o_orehold_m": ["o_orehold", 3], "o_orehold_l": ["o_orehold", 5],
	"o_mining_metal_s": ["o_mining_metal", 1], "o_mining_stone_s": ["o_mining_stone", 1], "o_mining_ice_s": ["o_mining_ice", 1],
	"o_mining_metal_m": ["o_mining_metal", 3], "o_mining_stone_m": ["o_mining_stone", 3], "o_mining_ice_m": ["o_mining_ice", 3],
	"o_survey_amp_s": ["o_survey_amp", 1], "o_survey_amp_m": ["o_survey_amp", 2],
	"o_targeting_s": ["o_targeting", 1], "o_fuel_s": ["o_fuel", 1], "o_capacitor_s": ["o_capacitor", 1],
}


static func id_of(family: String, size: int, quality: String = "C") -> String:
	return "%s:%d:%s" % [family, size, quality]


## New id for a module of the earlier system, its size clamped to the family and to `max_size`.
static func legacy(old_id: String, max_size: int = 99, quality: String = "C") -> String:
	if not LEGACY.has(old_id):
		return old_id
	var fam: String = LEGACY[old_id][0]
	var sz: int = clampi(mini(int(LEGACY[old_id][1]), max_size), int(FAMILIES[fam]["sizes"][0]), int(FAMILIES[fam]["sizes"][1]))
	return id_of(fam, sz, quality)


## One module: family `fam` in size `size` and quality `q`.
static func make(fam: String, size: int, q: String) -> Dictionary:
	var f: Dictionary = FAMILIES[fam]
	var a: Dictionary = ANCHORS[f["anchor"]]
	var k := float(size) / float(f["ref"])
	var qf: Dictionary = QUALITY[q]
	var exps: Dictionary = f.get("exp", {})
	var m := {}
	for key in a:
		var v = a[key]
		if key in ["name", "size"]:
			continue
		if key == "mass":
			m[key] = int(round(float(v) * pow(k, EXP_MASS) * float(qf["mass"])))
		elif key == "power":
			m[key] = snappedf(float(v) * pow(k, EXP_POWER) * float(qf["power"]), 0.1)
		elif key == "price":
			m[key] = int(round(float(v) * pow(k, EXP_PRICE) * float(qf["price"]) / 10.0)) * 10
		elif key == "accuracy":
			m[key] = snappedf(float(v) / (sqrt(k) * float(qf["perf"])), 0.001)
		elif key == "mining_bonus":
			var mb := {}
			for cls in v:
				mb[cls] = snappedf(float(v[cls]) * sqrt(k) * float(qf["perf"]), 0.01)
			m[key] = mb
		elif key in MULT_FIELDS:
			m[key] = snappedf(1.0 + (float(v) - 1.0) * sqrt(k) * float(qf["perf"]), 0.01)
		elif FIELD_EXP.has(key) or exps.has(key):
			var e := float(exps.get(key, FIELD_EXP.get(key, 0.0)))
			var val := float(v) * pow(k, e)
			if not key in ["energy", "energy_rate"]:
				val *= float(qf["perf"])
			m[key] = snappedf(val, 0.01) if val < 50.0 else round(val)
		else:
			m[key] = v
	if m["slot"] == "hyperdrive":
		m["drive_class"] = clampi(int(ceil(size / 2.0)), 1, 3)
	# balancing 0.4.22.3: weapon ranges +10 %, sensor ranges +15 %
	if m.has("range") and m["slot"] in RANGE_BUFF:
		m["range"] = round(float(m["range"]) * float(RANGE_BUFF[m["slot"]]))
	m["family"] = fam
	m["size"] = size
	m["quality"] = q
	m["base_name"] = f["name"]
	m["name"] = "%s %d · %s" % [f["name"], size, q]
	return m


## Every family in every allowed size and quality.
static func build_all() -> Dictionary:
	var out := {}
	for fam in FAMILIES:
		var r: Array = FAMILIES[fam]["sizes"]
		for size in range(int(r[0]), int(r[1]) + 1):
			for q in QUALITIES:
				out[id_of(fam, size, q)] = make(fam, size, q)
	return out


## Reference values: the modules of the earlier S/M/L system. Families take their numbers from these.
const ANCHORS := {
	# ---------------- Hull plating ----------------
	"hull_std_s": {"name": "Standard Plating", "slot": "hull", "size": 1, "price": 1500, "mass": 200, "power": 0, "armor": 300, "res": {"kinetic": 0.10}},
	"hull_reflect_s": {"name": "Reflective Plating", "slot": "hull", "size": 1, "price": 4500, "mass": 180, "power": 2, "armor": 260, "res": {"optical": 0.35}},
	"hull_ablative_s": {"name": "Ablative Plating", "slot": "hull", "size": 1, "price": 4500, "mass": 230, "power": 0, "armor": 280, "res": {"explosive": 0.35}},
	"hull_composite_m": {"name": "Composite Plating", "slot": "hull", "size": 2, "price": 14000, "mass": 650, "power": 0, "armor": 950, "res": {"kinetic": 0.25, "explosive": 0.15}},
	"hull_reflect_m": {"name": "Reflective Plating", "slot": "hull", "size": 2, "price": 16000, "mass": 600, "power": 4, "armor": 850, "res": {"optical": 0.40}},
	"hull_heavy_l": {"name": "Heavy Battle Plating", "slot": "hull", "size": 3, "price": 60000, "mass": 1800, "power": 0, "armor": 2600, "res": {"optical": 0.2, "kinetic": 0.2, "explosive": 0.2}},

	# ---------------- Engines ----------------
	"eng_chem_s": {"name": "Chemical Thruster", "slot": "engine", "size": 1, "price": 1200, "mass": 120, "power": 3, "thrust": 420, "turn": 3.5},
	"eng_ion_s": {"name": "Ion Drive", "slot": "engine", "size": 1, "price": 5000, "mass": 90, "power": 8, "thrust": 560, "turn": 4.0},
	"eng_plasma_m": {"name": "Plasma Drive", "slot": "engine", "size": 2, "price": 18000, "mass": 320, "power": 16, "thrust": 1400, "turn": 2.6},
	"eng_ion_m": {"name": "Ion Drive", "slot": "engine", "size": 2, "price": 24000, "mass": 260, "power": 24, "thrust": 1650, "turn": 3.0},
	"eng_fusion_l": {"name": "Fusion Drive", "slot": "engine", "size": 3, "price": 70000, "mass": 900, "power": 40, "thrust": 2900, "turn": 1.6},

	# ---------------- Power distributors ----------------
	"dist_basic_s": {"name": "Basic Power Distributor", "slot": "distributor", "size": 1, "price": 1000, "mass": 50, "power": 0, "capacitor": 100, "recharge": 9, "efficiency": 1.0},
	"dist_adv_s": {"name": "Precision Power Distributor", "slot": "distributor", "size": 1, "price": 6000, "mass": 45, "power": 0, "capacitor": 150, "recharge": 14, "efficiency": 1.08},
	"dist_m": {"name": "Combat Power Distributor", "slot": "distributor", "size": 2, "price": 15000, "mass": 150, "power": 0, "capacitor": 380, "recharge": 28, "efficiency": 1.05},
	"dist_l": {"name": "Heavy Power Distributor", "slot": "distributor", "size": 3, "price": 45000, "mass": 400, "power": 0, "capacitor": 1000, "recharge": 65, "efficiency": 1.1},

	# ---------------- Reactors ----------------
	"rea_fission_s": {"name": "Fission Reactor", "slot": "reactor", "size": 1, "price": 2000, "mass": 250, "power": 0, "output": 42},
	"rea_fusion_s": {"name": "Compact Fusion Reactor", "slot": "reactor", "size": 1, "price": 9000, "mass": 200, "power": 0, "output": 60},
	"rea_fusion_m": {"name": "Fusion Reactor", "slot": "reactor", "size": 2, "price": 22000, "mass": 550, "power": 0, "output": 125},
	"rea_antimatter_l": {"name": "Antimatter Reactor", "slot": "reactor", "size": 3, "price": 90000, "mass": 1100, "power": 0, "output": 320},

	# ---------------- Fuel tanks ----------------
	"tank_s": {"name": "Fuel Tank", "slot": "tank", "size": 1, "price": 800, "mass": 60, "power": 0, "fuel": 100},
	"tank_m": {"name": "Fuel Tank", "slot": "tank", "size": 2, "price": 4000, "mass": 160, "power": 0, "fuel": 280},
	"tank_l": {"name": "Fuel Tank", "slot": "tank", "size": 3, "price": 12000, "mass": 400, "power": 0, "fuel": 750},

	# ---------------- Hyperdrives ----------------
	"hyp_c1_s": {"name": "Jump Drive Cl.1", "slot": "hyperdrive", "size": 1, "price": 2500, "mass": 80, "power": 6, "drive_class": 1, "jump_fuel": 18, "spool": 3.0},
	"hyp_c2_s": {"name": "Jump Drive Cl.2", "slot": "hyperdrive", "size": 1, "price": 12000, "mass": 100, "power": 10, "drive_class": 2, "jump_fuel": 22, "spool": 2.5},
	"hyp_c2_m": {"name": "Jump Drive Cl.2", "slot": "hyperdrive", "size": 2, "price": 20000, "mass": 250, "power": 14, "drive_class": 2, "jump_fuel": 30, "spool": 3.5},
	"hyp_c3_m": {"name": "Jump Drive Cl.3", "slot": "hyperdrive", "size": 2, "price": 55000, "mass": 300, "power": 24, "drive_class": 3, "jump_fuel": 40, "spool": 3.0},
	"hyp_c3_l": {"name": "Jump Drive Cl.3", "slot": "hyperdrive", "size": 3, "price": 80000, "mass": 600, "power": 30, "drive_class": 3, "jump_fuel": 55, "spool": 4.0},

	# ---------------- Sensors ----------------
	"sen_basic_s": {"name": "Basic Sensor Suite", "slot": "sensors", "size": 1, "price": 1000, "mass": 40, "power": 3, "range": 900, "resolution": 1.0, "scan_strength": 1.0},
	"sen_radar_s": {"name": "Radar Array", "slot": "sensors", "size": 1, "price": 7000, "mass": 50, "power": 6, "range": 1250, "resolution": 1.3, "scan_strength": 1.2},
	"sen_grav_m": {"name": "Gravimetric Array", "slot": "sensors", "size": 2, "price": 20000, "mass": 150, "power": 10, "range": 1700, "resolution": 1.1, "scan_strength": 2.0},
	"sen_tactical_m": {"name": "Tactical Sensor System", "slot": "sensors", "size": 2, "price": 22000, "mass": 140, "power": 12, "range": 1500, "resolution": 1.8, "scan_strength": 1.0},
	"sen_deep_l": {"name": "Deep Space Sensors", "slot": "sensors", "size": 3, "price": 60000, "mass": 400, "power": 18, "range": 2400, "resolution": 1.3, "scan_strength": 2.6},

	# ---------------- Weapons: optical ----------------
	"w_pulse_s": {"name": "Pulse Laser", "slot": "weapon", "size": 1, "price": 2500, "mass": 60, "power": 5, "damage_type": "optical", "damage": 14, "cooldown": 0.6, "range": 650, "energy": 4, "projectile_speed": 0},
	"w_beam_m": {"name": "Beam Laser", "slot": "weapon", "size": 2, "price": 16000, "mass": 200, "power": 12, "damage_type": "optical", "damage": 42, "cooldown": 1.2, "range": 850, "energy": 12, "projectile_speed": 0},
	"w_lance_l": {"name": "Photon Lance", "slot": "weapon", "size": 3, "price": 65000, "mass": 600, "power": 28, "damage_type": "optical", "damage": 150, "cooldown": 2.5, "range": 1150, "energy": 45, "projectile_speed": 0},
	# ---------------- Weapons: kinetic ----------------
	"w_autocannon_s": {"name": "Autocannon", "slot": "weapon", "size": 1, "price": 2000, "mass": 80, "power": 3, "damage_type": "kinetic", "damage": 8, "cooldown": 0.22, "range": 520, "energy": 1, "projectile_speed": 1100},
	"w_railgun_m": {"name": "Railgun", "slot": "weapon", "size": 2, "price": 18000, "mass": 260, "power": 14, "damage_type": "kinetic", "damage": 65, "cooldown": 2.0, "range": 1100, "energy": 16, "projectile_speed": 2600},
	"w_massdriver_l": {"name": "Mass Driver", "slot": "weapon", "size": 3, "price": 70000, "mass": 700, "power": 26, "damage_type": "kinetic", "damage": 190, "cooldown": 3.0, "range": 1300, "energy": 30, "projectile_speed": 2200},
	# ---------------- Weapons: explosive ----------------
	"w_rocket_s": {"name": "Rocket Launcher", "slot": "weapon", "size": 1, "price": 3500, "mass": 90, "power": 3, "damage_type": "explosive", "damage": 38, "cooldown": 2.6, "range": 780, "energy": 2, "projectile_speed": 420, "splash": 60, "homing": true},
	"w_torpedo_m": {"name": "Torpedo Bay", "slot": "weapon", "size": 2, "price": 20000, "mass": 300, "power": 8, "damage_type": "explosive", "damage": 170, "cooldown": 6.0, "range": 1000, "energy": 8, "projectile_speed": 300, "splash": 120, "homing": true},
	"w_cruise_l": {"name": "Cruise Missile Silo", "slot": "weapon", "size": 3, "price": 75000, "mass": 800, "power": 15, "damage_type": "explosive", "damage": 420, "cooldown": 9.0, "range": 1700, "energy": 20, "projectile_speed": 360, "splash": 170, "homing": true},
	# ---------------- Weapons: ion (pirate gear, package 14) ----------------
	# Ion disruptors hit shields hard and drain the target's capacitor. Not sold by the corporations –
	# found on pirate wrecks or bought in Pirate Havens.
	"w_ion_s": {"name": "Ion Disruptor", "slot": "weapon", "size": 1, "price": 5000, "mass": 70, "power": 6, "damage_type": "optical", "damage": 7, "cooldown": 0.8, "range": 600, "energy": 3, "projectile_speed": 0, "cap_drain": 9.0, "shield_mult": 1.6, "pirate_only": true},
	# Ion torpedo: fitted only to 5-star notorious captains – knocks station turrets offline in raids
	"w_ion_torpedo": {"name": "Ion Torpedo", "slot": "weapon", "size": 1, "price": 60000, "mass": 150, "power": 6, "damage_type": "explosive", "damage": 60, "cooldown": 10.0, "range": 1400, "energy": 10, "projectile_speed": 380, "splash": 40, "homing": true, "cap_drain": 80.0, "pirate_only": true, "notorious_only": true},
	# ---------------- Package 20: point defense and mines ----------------
	# point defense: switched on, it shoots down hostile missiles, torpedoes and mines in range by itself
	"w_pointdef_s": {"name": "Point Defense Turret", "slot": "weapon", "size": 1, "price": 4500, "mass": 70, "power": 5, "pd": true, "damage_type": "kinetic", "damage": 0, "cooldown": 0.7, "range": 420, "energy": 2, "intercept": 0.6, "projectile_speed": 0},
	# mine launcher: lays the mine type chosen on its tile (right-click); mines come from the cargo hold
	"w_minelayer_s": {"name": "Mine Launcher", "slot": "weapon", "size": 1, "price": 6000, "mass": 120, "power": 3, "mines": true, "damage_type": "explosive", "damage": 0, "cooldown": 3.0, "range": 0, "energy": 4, "max_mines": 3, "projectile_speed": 0},
	"w_ion_m": {"name": "Ion Siphon", "slot": "weapon", "size": 2, "price": 21000, "mass": 220, "power": 14, "damage_type": "optical", "damage": 20, "cooldown": 1.3, "range": 800, "energy": 8, "projectile_speed": 0, "cap_drain": 28.0, "shield_mult": 1.6, "pirate_only": true},

	# ---------------- Tools ----------------
	"t_scanner_s": {"name": "Signature Scanner", "slot": "tool", "size": 1, "price": 3000, "mass": 50, "power": 4, "tool": "scanner", "strength": 1.0, "range": 1600},
	"t_scanner_m": {"name": "Deep Scanner", "slot": "tool", "size": 2, "price": 15000, "mass": 150, "power": 8, "tool": "scanner", "strength": 2.2, "range": 2600},
	"t_analyzer_s": {"name": "Analyzer", "slot": "tool", "size": 1, "price": 3500, "mass": 50, "power": 4, "tool": "analyzer", "rate": 1.0, "range": 350},
	"t_analyzer_m": {"name": "Research Lab Module", "slot": "tool", "size": 2, "price": 18000, "mass": 160, "power": 10, "tool": "analyzer", "rate": 2.4, "range": 450},
	"t_mining_s": {"name": "Mining Laser", "slot": "tool", "size": 1, "price": 2500, "mass": 70, "power": 5, "tool": "mining", "rate": 1.2, "range": 320},
	"t_mining_m": {"name": "Heavy Mining Laser", "slot": "tool", "size": 2, "price": 14000, "mass": 220, "power": 12, "tool": "mining", "rate": 3.5, "range": 380},
	"t_salvage_s": {"name": "Salvager", "slot": "tool", "size": 1, "price": 3000, "mass": 60, "power": 3, "tool": "salvage", "rate": 1.0, "range": 300},
	"t_repair_s": {"name": "Repair Beam", "slot": "tool", "size": 1, "price": 6000, "mass": 80, "power": 8, "tool": "repair", "rate": 18, "range": 450, "energy": 5},
	"t_repair_m": {"name": "Heavy Repair Beam", "slot": "tool", "size": 2, "price": 24000, "mass": 220, "power": 18, "tool": "repair", "rate": 50, "range": 600, "energy": 12},
	# Phase 0.5 package 7: survey, prospecting, warrants, ice and heavy mining
	# survey: aimed at the place in the selection panel; range in km, scan_time in s, energy per scan
	"t_survey_s": {"name": "Long-Range Survey Scanner", "slot": "tool", "size": 1, "price": 9000, "mass": 80, "power": 6, "tool": "survey", "range": 300000, "scan_time": 8.0, "energy": 25},
	"t_survey_m": {"name": "Long-Range Survey Array", "slot": "tool", "size": 2, "price": 32000, "mass": 220, "power": 12, "tool": "survey", "range": 750000, "scan_time": 6.0, "energy": 50},
	"t_survey_l": {"name": "Deep Survey Array", "slot": "tool", "size": 3, "price": 90000, "mass": 600, "power": 22, "tool": "survey", "range": 1600000, "scan_time": 5.0, "energy": 90},
	# prospect: on a locked asteroid; accuracy = maximum error of the estimate
	"t_prospector_s": {"name": "Prospector Scanner", "slot": "tool", "size": 1, "price": 4000, "mass": 40, "power": 3, "tool": "prospect", "range": 600, "scan_time": 3.0, "accuracy": 0.2, "energy": 6},
	"t_prospector_m": {"name": "Geological Survey Probe", "slot": "tool", "size": 2, "price": 16000, "mass": 120, "power": 6, "tool": "prospect", "range": 900, "scan_time": 2.0, "accuracy": 0.07, "energy": 10},
	# warrant: on a locked NPC ship
	"t_warrant_s": {"name": "Warrant Scanner", "slot": "tool", "size": 1, "price": 5000, "mass": 40, "power": 3, "tool": "warrant", "range": 900, "scan_time": 2.5, "energy": 5},
	# harvester: ice only, no malus
	"t_harvester_s": {"name": "Ice Harvester", "slot": "tool", "size": 1, "price": 4500, "mass": 90, "power": 6, "tool": "harvester", "rate": 1.6, "range": 300},
	"t_harvester_m": {"name": "Heavy Ice Harvester", "slot": "tool", "size": 2, "price": 18000, "mass": 260, "power": 14, "tool": "harvester", "rate": 4.6, "range": 360},
	"t_stripminer_l": {"name": "Strip Miner", "slot": "tool", "size": 3, "price": 75000, "mass": 900, "power": 30, "tool": "mining", "rate": 13.0, "range": 450},

	# ---------------- Optional equipment ----------------
	"o_cargo_s": {"name": "Cargo Rack", "slot": "optional", "size": 1, "price": 1500, "mass": 100, "power": 0, "cargo": 40},
	"o_cargo_m": {"name": "Expanded Cargo Hold", "slot": "optional", "size": 2, "price": 8000, "mass": 320, "power": 0, "cargo": 160},
	"o_cargo_l": {"name": "Container Frame", "slot": "optional", "size": 3, "price": 25000, "mass": 800, "power": 0, "cargo": 450},
	"o_shield_s": {"name": "Shield Generator", "slot": "optional", "size": 1, "price": 5000, "mass": 70, "power": 10, "shield": 260, "shield_regen": 7, "shield_kind": "balanced"},
	# package 20: shield variants – more capacity (slow to come back) or fast regeneration (back quickly)
	"o_shield_cap_s": {"name": "Capacitive Shield", "slot": "optional", "size": 1, "price": 6000, "mass": 90, "power": 11, "shield": 360, "shield_regen": 4.2, "shield_kind": "capacity"},
	"o_shield_fast_s": {"name": "Fast-Cycle Shield", "slot": "optional", "size": 1, "price": 6000, "mass": 60, "power": 11, "shield": 180, "shield_regen": 12.5, "shield_kind": "regen"},
	# radar jammer: while on, hostile ships within jam_range lose their radar and long-range locks
	"o_jammer_s": {"name": "Radar Jammer", "slot": "optional", "size": 1, "price": 9000, "mass": 60, "power": 9, "active": "jammer", "jam_range": 6000, "energy_rate": 7},
	# solar collector: passive, refuels slowly – the closer to the star, the faster
	"o_solar_s": {"name": "Solar Collector", "slot": "optional", "size": 1, "price": 4500, "mass": 70, "power": 0, "solar": 0.35},
	"o_shield_m": {"name": "Shield Generator", "slot": "optional", "size": 2, "price": 20000, "mass": 200, "power": 24, "shield": 850, "shield_regen": 20},
	"o_shield_l": {"name": "Shield Generator", "slot": "optional", "size": 3, "price": 70000, "mass": 500, "power": 50, "shield": 2400, "shield_regen": 50},
	"o_armor_s": {"name": "Armor Plates", "slot": "optional", "size": 1, "price": 2000, "mass": 250, "power": 0, "armor": 250},
	"o_armor_m": {"name": "Armor Plates", "slot": "optional", "size": 2, "price": 9000, "mass": 700, "power": 0, "armor": 800},
	# active optional modules (module bar): "active" = effect while switched on, energy_rate = capacitor per second
	"o_afterburner_s": {"name": "Afterburner", "slot": "optional", "size": 1, "price": 4000, "mass": 40, "power": 8, "active": "afterburner", "boost": 1.6, "energy_rate": 6},
	"o_afterburner_m": {"name": "Afterburner", "slot": "optional", "size": 2, "price": 15000, "mass": 140, "power": 16, "active": "afterburner", "boost": 1.5, "energy_rate": 14},
	"o_afterburner_l": {"name": "Afterburner", "slot": "optional", "size": 3, "price": 45000, "mass": 400, "power": 30, "active": "afterburner", "boost": 1.4, "energy_rate": 30},
	"o_shieldboost_s": {"name": "Shield Booster", "slot": "optional", "size": 1, "price": 6000, "mass": 50, "power": 8, "active": "shield_boost", "rate": 22, "energy_rate": 9},
	"o_shieldboost_m": {"name": "Shield Booster", "slot": "optional", "size": 2, "price": 22000, "mass": 160, "power": 18, "active": "shield_boost", "rate": 65, "energy_rate": 22},
	"o_shieldboost_l": {"name": "Shield Booster", "slot": "optional", "size": 3, "price": 70000, "mass": 420, "power": 36, "active": "shield_boost", "rate": 170, "energy_rate": 50},
	"o_armorrep_s": {"name": "Armor Repairer", "slot": "optional", "size": 1, "price": 5500, "mass": 90, "power": 6, "active": "armor_repair", "rate": 14, "energy_rate": 8},
	"o_armorrep_m": {"name": "Armor Repairer", "slot": "optional", "size": 2, "price": 20000, "mass": 280, "power": 14, "active": "armor_repair", "rate": 42, "energy_rate": 20},
	"o_armorrep_l": {"name": "Armor Repairer", "slot": "optional", "size": 3, "price": 65000, "mass": 700, "power": 30, "active": "armor_repair", "rate": 110, "energy_rate": 45},
	# mining equipment
	"o_orehold_s": {"name": "Ore Hold", "slot": "optional", "size": 1, "price": 2500, "mass": 120, "power": 0, "ore_cargo": 70},
	"o_orehold_m": {"name": "Ore Hold", "slot": "optional", "size": 2, "price": 10000, "mass": 380, "power": 0, "ore_cargo": 280},
	"o_orehold_l": {"name": "Ore Hold", "slot": "optional", "size": 3, "price": 30000, "mass": 950, "power": 0, "ore_cargo": 800},
	"o_mining_metal_s": {"name": "Metallic Mining Upgrade", "slot": "optional", "size": 1, "price": 5000, "mass": 30, "power": 4, "mining_bonus": {"metallic": 0.3}},
	"o_mining_stone_s": {"name": "Silicate Mining Upgrade", "slot": "optional", "size": 1, "price": 5000, "mass": 30, "power": 4, "mining_bonus": {"stony": 0.3}},
	"o_mining_ice_s": {"name": "Cryo Mining Upgrade", "slot": "optional", "size": 1, "price": 5000, "mass": 30, "power": 4, "mining_bonus": {"icy": 0.3}},
	"o_mining_metal_m": {"name": "Metallic Mining Upgrade", "slot": "optional", "size": 2, "price": 18000, "mass": 90, "power": 8, "mining_bonus": {"metallic": 0.6}},
	"o_mining_stone_m": {"name": "Silicate Mining Upgrade", "slot": "optional", "size": 2, "price": 18000, "mass": 90, "power": 8, "mining_bonus": {"stony": 0.6}},
	"o_mining_ice_m": {"name": "Cryo Mining Upgrade", "slot": "optional", "size": 2, "price": 18000, "mass": 90, "power": 8, "mining_bonus": {"icy": 0.6}},
	# survey range upgrade
	"o_survey_amp_s": {"name": "Survey Range Amplifier", "slot": "optional", "size": 1, "price": 7000, "mass": 30, "power": 5, "survey_range_mult": 1.5},
	"o_survey_amp_m": {"name": "Survey Range Amplifier", "slot": "optional", "size": 2, "price": 24000, "mass": 90, "power": 10, "survey_range_mult": 2.2},
	"o_targeting_s": {"name": "Targeting Computer", "slot": "optional", "size": 1, "price": 5000, "mass": 30, "power": 5, "range_mult": 1.15, "res_bonus": 0.3},
	"o_fuel_s": {"name": "Auxiliary Tank", "slot": "optional", "size": 1, "price": 1200, "mass": 80, "power": 0, "fuel": 90},
	"o_capacitor_s": {"name": "Capacitor Bank", "slot": "optional", "size": 1, "price": 3000, "mass": 60, "power": 0, "cap_bonus": 120},
	# warp interdictor (phase 0.5 package 11): select a ship in warp, activate, win the timing game
	"t_interdictor_s": {"name": "Warp Interdictor", "slot": "tool", "size": 1, "price": 18000, "mass": 70, "power": 7, "tool": "interdict", "range": 400000, "energy": 30, "zone_bonus": 0.0},
	# package 20: shield transfer (own capacitor → the locked friendly ship's shield; speeds up its
	# shield downtime) and the cargo scanner (reads the manifest of a locked ship)
	"t_shieldxfer_s": {"name": "Shield Transfer Beam", "slot": "tool", "size": 1, "price": 7000, "mass": 80, "power": 7, "tool": "shield_transfer", "rate": 16, "range": 520, "energy_rate": 9},
	"t_cargoscan_s": {"name": "Cargo Scanner", "slot": "tool", "size": 1, "price": 4000, "mass": 40, "power": 3, "tool": "cargo_scan", "range": 750, "scan_time": 3.0, "energy": 6},
	"t_interdictor_m": {"name": "Warp Interdictor", "slot": "tool", "size": 2, "price": 46000, "mass": 160, "power": 12, "tool": "interdict", "range": 900000, "energy": 45, "zone_bonus": 0.04},
}
