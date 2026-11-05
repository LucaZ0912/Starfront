extends RefCounted
## Pre-built loadouts. "std_<hull>" is sold at shipyards as the standard fit.
## "pirate_*" loadouts are used for NPC pirates.

const PRESETS := {
	"std_dragonfly": {"hull": "dragonfly", "modules": {
		"hull": "hull_std_s", "engine": "eng_ion_s", "distributor": "dist_basic_s", "reactor": "rea_fission_s",
		"tank": "tank_s", "hyperdrive": "hyp_c1_s", "sensors": "sen_basic_s",
		"weapon_0": "w_pulse_s", "tool_0": "t_scanner_s", "tool_1": "t_analyzer_s", "optional_0": "o_shield_s"}},
	"std_hornet": {"hull": "hornet", "modules": {
		"hull": "hull_std_s", "engine": "eng_chem_s", "distributor": "dist_basic_s", "reactor": "rea_fission_s",
		"tank": "tank_s", "hyperdrive": "hyp_c1_s", "sensors": "sen_basic_s",
		"weapon_0": "w_pulse_s", "weapon_1": "w_autocannon_s", "weapon_2": "w_rocket_s",
		"optional_0": "o_shield_s", "optional_1": "o_armor_s"}},
	"std_mule": {"hull": "mule", "modules": {
		"hull": "hull_composite_m", "engine": "eng_plasma_m", "distributor": "dist_basic_s", "reactor": "rea_fusion_s",
		"tank": "tank_m", "hyperdrive": "hyp_c2_m", "sensors": "sen_basic_s",
		"weapon_0": "w_pulse_s", "tool_0": "t_salvage_s",
		"optional_0": "o_cargo_m", "optional_1": "o_cargo_m", "optional_2": "o_shield_s", "optional_3": "o_cargo_s"}},
	# Kanayama Heavy Industries (package 25a)
	"std_mogura": {"hull": "mogura", "modules": {
		"hull": "hull_std_s", "engine": "eng_chem_s", "distributor": "dist_basic_s", "reactor": "rea_fusion_s",
		"tank": "tank_s", "hyperdrive": "hyp_c1_s", "sensors": "sen_basic_s",
		"weapon_0": "w_pulse_s", "tool_0": "t_mining_m", "tool_1": "t_mining_s",
		"optional_0": "o_shield_m", "optional_1": "o_orehold_s"}},
	"std_anaguma": {"hull": "anaguma", "modules": {
		"hull": "hull_composite_m", "engine": "eng_plasma_m", "distributor": "dist_m", "reactor": "rea_fusion_m",
		"tank": "tank_m", "hyperdrive": "hyp_c2_m", "sensors": "sen_basic_s",
		"weapon_0": "w_autocannon_s", "tool_0": "t_stripminer_l", "tool_1": "t_mining_m", "tool_2": "t_harvester_m",
		"optional_0": "o_shield_l", "optional_1": "o_orehold_m"}},
	"std_iwakudaki": {"hull": "iwakudaki", "modules": {
		"hull": "hull_heavy_l", "engine": "eng_fusion_l", "distributor": "dist_l", "reactor": "rea_antimatter_l",
		"tank": "tank_l", "hyperdrive": "hyp_c3_m", "sensors": "sen_radar_s",
		"weapon_0": "w_autocannon_s", "weapon_1": "w_rocket_s", "tool_0": "t_stripminer_l", "tool_1": "t_stripminer_l", "tool_2": "t_harvester_m", "tool_3": "t_mining_m",
		"optional_0": "o_shield_l", "optional_1": "o_shield_l", "optional_2": "o_orehold_l"}},
	"std_kanayama": {"hull": "kanayama", "modules": {
		"hull": "hull_heavy_l", "engine": "eng_fusion_l", "distributor": "dist_l", "reactor": "rea_antimatter_l",
		"tank": "tank_l", "hyperdrive": "hyp_c3_m", "sensors": "sen_radar_s",
		"weapon_0": "w_autocannon_s", "weapon_1": "w_rocket_s", "tool_0": "t_mining_m", "tool_1": "t_harvester_m",
		"optional_0": "o_shield_l", "optional_1": "o_shield_l", "optional_2": "o_cargo_l"}},
	"civ_miner_khi": {"hull": "anaguma", "modules": {
		"hull": "hull_composite_m", "engine": "eng_plasma_m", "distributor": "dist_m", "reactor": "rea_fusion_m",
		"tank": "tank_s", "hyperdrive": "hyp_c1_s", "sensors": "sen_basic_s",
		"weapon_0": "w_autocannon_s", "tool_0": "t_mining_m", "tool_1": "t_mining_m",
		"optional_0": "o_shield_m"}},
	"civ_ice_miner_khi": {"hull": "mogura", "modules": {
		"hull": "hull_std_s", "engine": "eng_chem_s", "distributor": "dist_basic_s", "reactor": "rea_fusion_s",
		"tank": "tank_s", "hyperdrive": "hyp_c1_s", "sensors": "sen_basic_s",
		"weapon_0": "w_pulse_s", "tool_0": "t_harvester_m", "tool_1": "t_harvester_s",
		"optional_0": "o_shield_s"}},
	"std_drillhead": {"hull": "drillhead", "modules": {
		"hull": "hull_composite_m", "engine": "eng_plasma_m", "distributor": "dist_basic_s", "reactor": "rea_fusion_s",
		"tank": "tank_s", "hyperdrive": "hyp_c1_s", "sensors": "sen_basic_s",
		"weapon_0": "w_autocannon_s", "tool_0": "t_mining_m", "tool_1": "t_mining_s", "tool_2": "t_salvage_s",
		"optional_0": "o_shield_s", "optional_1": "o_cargo_s"}},
	"std_warden": {"hull": "warden", "modules": {
		"hull": "hull_composite_m", "engine": "eng_plasma_m", "distributor": "dist_m", "reactor": "rea_fusion_m",
		"tank": "tank_m", "hyperdrive": "hyp_c2_m", "sensors": "sen_tactical_m",
		"weapon_0": "w_beam_m", "weapon_1": "w_railgun_m", "weapon_2": "w_rocket_s", "weapon_3": "w_rocket_s",
		"tool_0": "t_repair_s", "optional_0": "o_shield_m", "optional_1": "o_armor_s", "optional_2": "o_targeting_s"}},
	"std_bastion": {"hull": "bastion", "modules": {
		"hull": "hull_heavy_l", "engine": "eng_fusion_l", "distributor": "dist_l", "reactor": "rea_antimatter_l",
		"tank": "tank_l", "hyperdrive": "hyp_c3_l", "sensors": "sen_deep_l",
		"weapon_0": "w_lance_l", "weapon_1": "w_massdriver_l", "weapon_2": "w_torpedo_m", "weapon_3": "w_beam_m",
		"weapon_4": "w_railgun_m", "weapon_5": "w_autocannon_s", "tool_0": "t_scanner_m", "tool_1": "t_repair_m",
		"optional_0": "o_shield_l", "optional_1": "o_armor_m", "optional_2": "o_targeting_s", "optional_3": "o_capacitor_s"}},

	# ---------------- Pirates ----------------
	# Archetypes (phase 0.5 package 14, data/pirate_archetypes.gd): the key "archetype" gives the AI role.
	"pirate_raider_laser": {"hull": "crow", "archetype": "raider", "modules": {
		"hull": "hull_std_s", "engine": "eng_chem_s", "distributor": "dist_basic_s", "reactor": "rea_fission_s",
		"tank": "tank_s", "hyperdrive": "hyp_c1_s", "sensors": "sen_basic_s",
		"weapon_0": "w_pulse_s", "weapon_1": "w_pulse_s", "optional_0": "o_shield_s"}},
	"pirate_raider_rocket": {"hull": "crow", "archetype": "brawler", "modules": {
		"hull": "hull_ablative_s", "engine": "eng_chem_s", "distributor": "dist_basic_s", "reactor": "rea_fission_s",
		"tank": "tank_s", "hyperdrive": "hyp_c1_s", "sensors": "sen_basic_s",
		"weapon_0": "w_rocket_s", "weapon_1": "w_autocannon_s", "optional_0": "o_armor_s"}},
	"pirate_hornet": {"hull": "hornet", "archetype": "brawler", "modules": {
		"hull": "hull_std_s", "engine": "eng_ion_s", "distributor": "dist_adv_s", "reactor": "rea_fusion_s",
		"tank": "tank_s", "hyperdrive": "hyp_c1_s", "sensors": "sen_radar_s",
		"weapon_0": "w_autocannon_s", "weapon_1": "w_autocannon_s", "weapon_2": "w_rocket_s",
		"optional_0": "o_shield_s", "optional_1": "o_afterburner_s"}},
	"pirate_warden": {"hull": "warden", "archetype": "sniper", "modules": {
		"hull": "hull_reflect_m", "engine": "eng_plasma_m", "distributor": "dist_m", "reactor": "rea_fusion_m",
		"tank": "tank_m", "hyperdrive": "hyp_c2_m", "sensors": "sen_tactical_m",
		"weapon_0": "w_railgun_m", "weapon_1": "w_beam_m", "weapon_2": "w_torpedo_m", "weapon_3": "w_rocket_s",
		"optional_0": "o_shield_m", "optional_1": "o_armor_s", "optional_2": "o_targeting_s"}},

	"pirate_raider_hornet": {"hull": "hornet", "archetype": "raider", "modules": {
		"hull": "hull_std_s", "engine": "eng_ion_s", "distributor": "dist_adv_s", "reactor": "rea_fusion_s",
		"tank": "tank_s", "hyperdrive": "hyp_c1_s", "sensors": "sen_radar_s",
		"weapon_0": "w_pulse_s", "weapon_1": "w_pulse_s", "weapon_2": "w_pulse_s",
		"optional_0": "o_shield_s", "optional_1": "o_afterburner_s"}},
	"pirate_brawler_warden": {"hull": "warden", "archetype": "brawler", "modules": {
		"hull": "hull_composite_m", "engine": "eng_plasma_m", "distributor": "dist_m", "reactor": "rea_fusion_m",
		"tank": "tank_m", "hyperdrive": "hyp_c2_m", "sensors": "sen_tactical_m",
		"weapon_0": "w_autocannon_s", "weapon_1": "w_autocannon_s", "weapon_2": "w_autocannon_s", "weapon_3": "w_rocket_s",
		"optional_0": "o_armor_m", "optional_1": "o_armor_s", "optional_2": "o_armorrep_s"}},
	"pirate_sniper_crow": {"hull": "crow", "archetype": "sniper", "modules": {
		"hull": "hull_std_s", "engine": "eng_chem_s", "distributor": "dist_basic_s", "reactor": "rea_fission_s",
		"tank": "tank_s", "hyperdrive": "hyp_c1_s", "sensors": "sen_radar_s",
		"weapon_0": "w_rocket_s", "weapon_1": "w_rocket_s", "optional_0": "o_shield_s"}},
	"pirate_sniper_hornet": {"hull": "hornet", "archetype": "sniper", "modules": {
		"hull": "hull_std_s", "engine": "eng_ion_s", "distributor": "dist_adv_s", "reactor": "rea_fusion_s",
		"tank": "tank_s", "hyperdrive": "hyp_c1_s", "sensors": "sen_radar_s",
		"weapon_0": "w_rocket_s", "weapon_1": "w_rocket_s", "weapon_2": "w_rocket_s",
		"optional_0": "o_shield_s", "optional_1": "o_targeting_s"}},
	"pirate_ambusher_crow": {"hull": "crow", "archetype": "ambusher", "modules": {
		"hull": "hull_std_s", "engine": "eng_chem_s", "distributor": "dist_basic_s", "reactor": "rea_fission_s",
		"tank": "tank_s", "hyperdrive": "hyp_c1_s", "sensors": "sen_basic_s",
		"weapon_0": "w_autocannon_s", "weapon_1": "w_rocket_s", "optional_0": "o_shield_s"}},
	"pirate_ambusher_hornet": {"hull": "hornet", "archetype": "ambusher", "modules": {
		"hull": "hull_ablative_s", "engine": "eng_ion_s", "distributor": "dist_adv_s", "reactor": "rea_fusion_s",
		"tank": "tank_s", "hyperdrive": "hyp_c1_s", "sensors": "sen_radar_s",
		"weapon_0": "w_autocannon_s", "weapon_1": "w_rocket_s", "weapon_2": "w_rocket_s",
		"optional_0": "o_shield_s", "optional_1": "o_armor_s"}},
	"pirate_leech_crow": {"hull": "crow", "archetype": "leech", "modules": {
		"hull": "hull_std_s", "engine": "eng_chem_s", "distributor": "dist_basic_s", "reactor": "rea_fission_s",
		"tank": "tank_s", "hyperdrive": "hyp_c1_s", "sensors": "sen_basic_s",
		"weapon_0": "w_ion_s", "weapon_1": "w_ion_s", "optional_0": "o_shield_s"}},
	"pirate_leech_hornet": {"hull": "hornet", "archetype": "leech", "modules": {
		"hull": "hull_std_s", "engine": "eng_ion_s", "distributor": "dist_adv_s", "reactor": "rea_fusion_s",
		"tank": "tank_s", "hyperdrive": "hyp_c1_s", "sensors": "sen_radar_s",
		"weapon_0": "w_ion_s", "weapon_1": "w_ion_s", "weapon_2": "w_pulse_s",
		"optional_0": "o_shield_s", "optional_1": "o_shieldboost_s"}},
	"pirate_leech_warden": {"hull": "warden", "archetype": "leech", "modules": {
		"hull": "hull_reflect_m", "engine": "eng_plasma_m", "distributor": "dist_m", "reactor": "rea_fusion_m",
		"tank": "tank_m", "hyperdrive": "hyp_c2_m", "sensors": "sen_tactical_m",
		"weapon_0": "w_ion_m", "weapon_1": "w_ion_m", "weapon_2": "w_beam_m", "weapon_3": "w_ion_s",
		"optional_0": "o_shield_m", "optional_1": "o_shield_s", "optional_2": "o_targeting_s"}},
	"pirate_coward_crow": {"hull": "crow", "archetype": "coward", "modules": {
		"hull": "hull_std_s", "engine": "eng_chem_s", "distributor": "dist_basic_s", "reactor": "rea_fission_s",
		"tank": "tank_s", "hyperdrive": "hyp_c1_s", "sensors": "sen_basic_s",
		"weapon_0": "w_pulse_s", "weapon_1": "w_autocannon_s", "optional_0": "o_afterburner_s"}},
	"pirate_coward_hornet": {"hull": "hornet", "archetype": "coward", "modules": {
		"hull": "hull_std_s", "engine": "eng_ion_s", "distributor": "dist_adv_s", "reactor": "rea_fusion_s",
		"tank": "tank_s", "hyperdrive": "hyp_c1_s", "sensors": "sen_radar_s",
		"weapon_0": "w_pulse_s", "weapon_1": "w_rocket_s", "weapon_2": "w_autocannon_s",
		"optional_0": "o_shield_s", "optional_1": "o_afterburner_s"}},

	# ---------------- Civilians & patrols (phase 0.5 package 11) ----------------
	# Maison Aurelle (package 25c)
	"std_aur_pearl": {"hull": "aur_pearl", "modules": {
		"hull": "hull_std_s", "engine": "eng_ion_s", "distributor": "dist_basic_s", "reactor": "rea_fusion:3:C",
		"tank": "tank_s", "hyperdrive": "hyp_c2_s", "sensors": "sen_basic_s",
		"weapon_0": "w_pulse_s", "optional_0": "o_cabin_luxury:3:C", "optional_1": "o_shield:2:C"}},
	"std_aur_boulevard": {"hull": "aur_boulevard", "modules": {
		"hull": "hull_composite_m", "engine": "eng_ion_m", "distributor": "dist_m", "reactor": "rea_fusion_m",
		"tank": "tank_m", "hyperdrive": "hyp_c2_m", "sensors": "sen_basic_s",
		"weapon_0": "w_pulse_s", "weapon_1": "w_pulse_s",
		"optional_0": "o_cabin_bulk:5:C", "optional_1": "o_cabin_business:4:C", "optional_2": "o_shield_m", "optional_3": "o_cabin_business:3:C"}},
	"std_aur_opal": {"hull": "aur_opal", "modules": {
		"hull": "hull_composite_m", "engine": "eng_ion_m", "distributor": "dist_m", "reactor": "rea_fusion_m",
		"tank": "tank_m", "hyperdrive": "hyp_c2_m", "sensors": "sen_basic_s",
		"weapon_0": "w_beam_m", "weapon_1": "w_pulse_s", "tool_0": "t_scanner_s",
		"optional_0": "o_cabin_luxury:5:C", "optional_1": "o_cabin_luxury:5:C", "optional_2": "o_shield_m", "optional_3": "o_cabin_business:4:C", "optional_4": "o_shield:3:C"}},
	"std_aur_empress": {"hull": "aur_empress", "modules": {
		"hull": "hull_heavy_l", "engine": "eng_fusion_l", "distributor": "dist_l", "reactor": "rea_antimatter_l",
		"tank": "tank_l", "hyperdrive": "hyp_c3_l", "sensors": "sen_radar_s",
		"weapon_0": "w_beam_m", "weapon_1": "w_beam_m", "weapon_2": "w_pulse_s", "tool_0": "t_repair_s",
		"optional_0": "o_cabin_luxury:9:C", "optional_1": "o_cabin_luxury:9:C", "optional_2": "o_cabin_business:8:C",
		"optional_3": "o_cabin_bulk:8:C", "optional_4": "o_shield_l", "optional_5": "o_shield_l"}},
	"civ_boulevard": {"hull": "aur_boulevard", "modules": {
		"hull": "hull_composite_m", "engine": "eng_ion_m", "distributor": "dist_m", "reactor": "rea_fusion_m",
		"tank": "tank_m", "hyperdrive": "hyp_c2_m", "sensors": "sen_basic_s",
		"optional_0": "o_cabin_bulk:5:C", "optional_1": "o_cabin_business:4:C", "optional_2": "o_shield_m"}},
	"civ_shuttle": {"hull": "shuttle", "modules": {
		"hull": "hull_std_s", "engine": "eng_ion_s", "distributor": "dist_basic_s", "reactor": "rea_fission_s",
		"tank": "tank_s", "hyperdrive": "hyp_c1_s", "sensors": "sen_basic_s", "optional_0": "o_shield_s"}},
	"civ_freighter": {"hull": "freighter", "modules": {
		"hull": "hull_heavy_l", "engine": "eng_fusion_l", "distributor": "dist_l", "reactor": "rea_antimatter_l",
		"tank": "tank_l", "hyperdrive": "hyp_c2_m", "sensors": "sen_basic_s",
		"weapon_0": "w_autocannon_s", "optional_0": "o_cargo_l", "optional_1": "o_shield_l", "optional_2": "o_armor_m"}},
	"civ_miner": {"hull": "drillhead", "modules": {
		"hull": "hull_composite_m", "engine": "eng_plasma_m", "distributor": "dist_m", "reactor": "rea_fusion_m",
		"tank": "tank_s", "hyperdrive": "hyp_c1_s", "sensors": "sen_basic_s",
		"weapon_0": "w_autocannon_s", "tool_0": "t_mining_m", "tool_1": "t_mining_s",
		"optional_0": "o_shield_s", "optional_1": "o_orehold_m"}},
	"civ_ice_miner": {"hull": "drillhead", "modules": {
		"hull": "hull_composite_m", "engine": "eng_plasma_m", "distributor": "dist_m", "reactor": "rea_fusion_m",
		"tank": "tank_s", "hyperdrive": "hyp_c1_s", "sensors": "sen_basic_s",
		"weapon_0": "w_autocannon_s", "tool_0": "t_harvester_m", "tool_1": "t_harvester_s",
		"optional_0": "o_shield_s", "optional_1": "o_orehold_m"}},
	"patrol_light": {"hull": "hornet", "modules": {
		"hull": "hull_reflect_s", "engine": "eng_ion_s", "distributor": "dist_adv_s", "reactor": "rea_fusion_s",
		"tank": "tank_s", "hyperdrive": "hyp_c2_s", "sensors": "sen_radar_s",
		"weapon_0": "w_pulse_s", "weapon_1": "w_autocannon_s", "weapon_2": "w_rocket_s",
		"optional_0": "o_shield_s", "optional_1": "o_armor_s"}},
	"patrol_medium": {"hull": "warden", "modules": {
		"hull": "hull_composite_m", "engine": "eng_plasma_m", "distributor": "dist_m", "reactor": "rea_fusion_m",
		"tank": "tank_m", "hyperdrive": "hyp_c2_m", "sensors": "sen_tactical_m",
		"weapon_0": "w_beam_m", "weapon_1": "w_railgun_m", "weapon_2": "w_autocannon_s", "weapon_3": "w_rocket_s",
		"optional_0": "o_shield_m", "optional_1": "o_armor_s", "optional_2": "o_targeting_s"}},
	"patrol_heavy": {"hull": "bastion", "modules": {
		"hull": "hull_heavy_l", "engine": "eng_fusion_l", "distributor": "dist_l", "reactor": "rea_antimatter_l",
		"tank": "tank_l", "hyperdrive": "hyp_c3_l", "sensors": "sen_deep_l",
		"weapon_0": "w_lance_l", "weapon_1": "w_massdriver_l", "weapon_2": "w_beam_m", "weapon_3": "w_railgun_m",
		"weapon_4": "w_autocannon_s", "weapon_5": "w_autocannon_s",
		"optional_0": "o_shield_l", "optional_1": "o_armor_m", "optional_2": "o_targeting_s"}},

	# standard fits of the hulls that became buyable in package 19
	"std_shuttle": {"hull": "shuttle", "modules": {
		"hull": "hull_std_s", "engine": "eng_ion_s", "distributor": "dist_basic_s", "reactor": "rea_fission_s",
		"tank": "tank_s", "hyperdrive": "hyp_c1_s", "sensors": "sen_basic_s", "optional_0": "o_shield_s"}},
	"std_freighter": {"hull": "freighter", "modules": {
		"hull": "hull_heavy_l", "engine": "eng_fusion_l", "distributor": "dist_l", "reactor": "rea_antimatter_l",
		"tank": "tank_l", "hyperdrive": "hyp_c2_m", "sensors": "sen_basic_s",
		"weapon_0": "w_autocannon_s", "optional_0": "o_cargo_l", "optional_1": "o_shield_l", "optional_2": "o_armor_m"}},
	"std_crow": {"hull": "crow", "modules": {
		"hull": "hull_std_s", "engine": "eng_chem_s", "distributor": "dist_basic_s", "reactor": "rea_fission_s",
		"tank": "tank_s", "hyperdrive": "hyp_c1_s", "sensors": "sen_basic_s",
		"weapon_0": "w_pulse_s", "weapon_1": "w_pulse_s", "optional_0": "o_shield_s"}},
}
