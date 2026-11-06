extends RefCounted
## Package 27: a short description of every module family – shown in the outfitter and the module overview.

const DESC := {
	# hull plating
	"pl_standard": "Plain armour plating – solid protection against kinetic hits.",
	"pl_reflective": "Mirrored plating that scatters lasers – strong against optical weapons.",
	"pl_ablative": "Layers that burn off under blasts – strong against explosive weapons.",
	# engines
	"eng_chemical": "Cheap, light chemical thruster – modest thrust, little power.",
	"eng_ion": "Efficient ion drive – a good balance of thrust and power use.",
	"eng_plasma": "High-thrust plasma drive for fast ships – hungry for power.",
	# power
	"dist_basic": "Feeds the capacitor that weapons, tools and active modules draw on.",
	"dist_precision": "A larger, faster capacitor feed for energy-hungry fittings.",
	"rea_fission": "Simple fission reactor – the ship's power output.",
	"rea_fusion": "Compact fusion reactor – more power for its size.",
	# travel
	"tank": "Holds the fuel for warp and hyperspace jumps.",
	"hyperdrive": "Jump drive for the gates – its class decides which gates you can use.",
	# sensors
	"sen_basic": "Basic sensors – lock range, resolution and scan strength.",
	"sen_radar": "Long-range radar – sees and locks targets further away.",
	"sen_grav": "Gravimetric array – strong scans for anomalies and asteroids.",
	"sen_tactical": "Combat sensors – a fine resolution for fast target locks.",
	# weapons
	"w_pulse": "Rapid optical bolts – best against shields.",
	"w_beam": "Continuous laser beam – steady optical damage on one target.",
	"w_lance": "Charges up and fires a heavy photon lance – big optical hits.",
	"w_autocannon": "Fast kinetic shells – chews through armour.",
	"w_railgun": "Long-range kinetic slug – slow, hard-hitting, precise.",
	"w_massdriver": "Heavy kinetic driver – brutal against armour at close range.",
	"w_rocket": "Homing rockets – explosive damage against the hull structure.",
	"w_torpedo": "Slow, heavy torpedoes – huge explosive damage against big ships.",
	"w_cruise": "Long-range homing missiles – explosive strikes from afar.",
	"w_ion": "Ion bolts that drain the target's capacitor and hit shields hard.",
	"w_focus": "Covenant focus crystals – all of them bundle into one burning lance.",
	"w_ionsiphon": "Pirate tech: drains the target's capacitor into your own.",
	"w_iontorpedo": "Pirate tech: a slow ion torpedo that drains the target's capacitor.",
	"w_pointdef": "Shoots down incoming missiles, torpedoes and mines on its own.",
	"w_minelayer": "Lays mines behind the ship (mines are bought as goods).",
	# tools
	"t_scanner": "Picks up faint signatures – hidden anomalies and objects within its range (works on its own).",
	"t_analyzer": "Analyses anomalies to uncover what they hide.",
	"t_mining": "Mines ore from asteroids into the cargo hold.",
	"t_stripminer": "Heavy mining laser – mines much faster, needs a big slot.",
	"t_harvester": "Harvests ice asteroids far better than a mining laser.",
	"t_salvage": "Recovers salvage and modules from wrecks.",
	"t_repair": "Repairs armour – of your own ship or of a friendly one.",
	"t_survey": "Surveys a whole field or planet from afar – no lock needed.",
	"t_prospector": "Reveals what an asteroid is made of.",
	"t_warrant": "Checks ships for bounties and warrants.",
	"t_interdictor": "Pulls a ship out of warp – a timing game.",
	"t_shieldxfer": "Transfers your shield energy to a friendly ship.",
	"t_cargoscan": "Scans a ship's cargo hold for contraband.",
	# drones
	"hangar": "Holds your drones – the quality gives more room.",
	"dr_range": "Your drones operate further from the ship.",
	"dr_cargo": "Your drones carry more ore per trip.",
	"dr_hull": "Tougher drones – more hull points.",
	"dr_shield": "Gives every drone its own small shield.",
	"dr_damage": "Your drones' weapons hit harder.",
	"dr_wrange": "Your drones' weapons reach further.",
	"dr_fuel": "Your drones stay out longer.",
	"dr_speed": "Faster drones.",
	"dr_cloak": "Axiom tech: your drones cloak together with the ship.",
	# optional
	"o_cargo": "More cargo space.",
	"o_shield": "A shield generator – absorbs damage and recharges by itself.",
	"o_shield_cap": "A big but slowly recharging shield.",
	"o_shield_fast": "A smaller shield that comes back quickly after it collapses.",
	"o_jammer": "Blinds the radar of enemies around you.",
	"o_solar": "Collects fuel when you fly close to the star.",
	"o_armor": "Extra armour plates – more protection, more mass.",
	"o_afterburner": "Switch on for a burst of speed – uses energy.",
	"o_shieldboost": "Switch on to recharge the shields quickly – uses energy.",
	"o_armorrep": "Switch on to repair armour over time – uses energy.",
	"o_orehold": "A separate hold just for ore and ice.",
	"o_mining_metal": "Mines metallic asteroids faster.",
	"o_mining_stone": "Mines silicate asteroids faster.",
	"o_mining_ice": "Mines icy asteroids faster.",
	"o_survey_amp": "The survey scanner reaches further.",
	"o_targeting": "Weapons reach further, and the sensors lock faster.",
	"o_fuel": "An auxiliary fuel tank.",
	"o_capacitor": "A bigger capacitor for weapons and active modules.",
	"o_cabin_bulk": "Simple cabins for many passengers.",
	"o_cabin_business": "Comfortable cabins for business travellers.",
	"o_cabin_luxury": "Luxury suites for wealthy guests (Maison Aurelle ships only).",
}


static func of(family: String) -> String:
	return String(DESC.get(family, ""))
