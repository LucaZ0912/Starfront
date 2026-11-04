extends RefCounted
## All equipment modules.
## Common fields: name, slot, size (1-3), price, mass, power (power draw in MW)
## Slot-specific fields:
##   hull:        armor, res {optical/kinetic/explosive: 0..1}
##   engine:      thrust (kN), turn (rad/s)
##   distributor: capacitor, recharge (/s), efficiency (multiplier on reactor output)
##   reactor:     output (MW)
##   tank:        fuel
##   hyperdrive:  drive_class (max. route class), jump_fuel, spool (s)
##   sensors:     range, resolution (target lock), scan_strength
##   weapon:      damage_type, damage, cooldown, range, energy, projectile_speed (0 = beam), splash, homing
##   tool:        tool (scanner/analyzer/mining/harvester/salvage/repair/survey/prospect/warrant), strength/rate, range, energy, scan_time, accuracy
##   optional:    cargo, ore_cargo, shield, shield_regen, armor, fuel, speed_mult, range_mult, res_bonus, cap_bonus,
##                mining_bonus {class: +x}, survey_range_mult; active modules: active (afterburner/shield_boost/
##                armor_repair), boost / rate, energy_rate (capacitor per second while on)

const MODULES := {
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
	"o_shield_s": {"name": "Shield Generator", "slot": "optional", "size": 1, "price": 5000, "mass": 70, "power": 10, "shield": 260, "shield_regen": 7},
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
	"t_interdictor_m": {"name": "Warp Interdictor", "slot": "tool", "size": 2, "price": 46000, "mass": 160, "power": 12, "tool": "interdict", "range": 900000, "energy": 45, "zone_bonus": 0.04},
}
