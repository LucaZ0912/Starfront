extends RefCounted
## Ship hulls: base stats + slot layout.
## size: 1 = S (corvette), 2 = M (frigate), 3 = L (cruiser).
## Modules may be at most the size of the hull. Slot counts raised in phase 0.5 (more modules to fit).
## Every ship has each core slot exactly once (hull plating, engine, power distributor,
## reactor, fuel tank, hyperdrive, sensors).

## maker (package 25): manufacturer (data/manufacturers.gd); "pirate" = pirate-built.
## Hull traits (package 25a, KHI): ore_cargo (built-in ore hold m³), mining_bonus (+ on every asteroid class),
## turn_mult, align_mult (warp alignment time ×), refinery {rate ore/s, eff yield ×, power MW},
## builtin (built-in modules: "prospect", "refinery", "factory", "market"); drone_deck [from, to] =
## pixel-art columns of a flight deck – drones launch from it and land on it (package 25b).
## Hull traits (package 25c, Maison Aurelle): speed_mult (sub-light speed ×), warp_mult (warp speed ×),
## shield_mult (shield capacity ×), cargo_mod_mult (cargo racks give only this share), luxury_pay
## (pay × on luxury passenger contracts), afterburner {boost, energy_rate, power} with "afterburner" in
## builtin; drone_bonus {shield, shield_regen, shield_mult (× the drone shield module)}.
## Hull traits (package 25d, Hadrian Dynamics): reflect (share of the damage to the armour that goes back
## to the attacker), res_bonus {damage type: +resistance}, work_mult (× mining, harvesting, salvage and
## analysis), missile_rof (× fire rate of rockets and torpedoes), "pd" in builtin (point defence),
## yard_rule "military" (only at military stations, shipyard complexes and tier-3 stations),
## heavy_missiles (can carry long-range and nuclear missiles later), small_ship_bay (Teil 5: a bay on
## top for an S ship). hatches {name: [x, y, w, h]} = sliding hatches in pixel-art columns/rows of the
## full (mirrored) ship image: "drones" (drones launch and land through it), "platform" (the S-ship bay).
## hatch_overlay: the hatch is not part of the pixel art – the game draws the closed hatch on top
## (every ship with drones has one since 0.4.25.22; positions from tools/art/drone_hatches.py).
## Faction ships (package 25e): min_tier = standing needed with the maker's faction to buy it (only at
## that faction's shipyards); drone_mult (× drone hull, damage, mining, repair, cargo, fuel and control
## range – the range never beyond the recon range); weapon_dmg_mult (× damage of the ship's own guns);
## shield_down_mult (× downtime after a shield collapse); npc_drones (NPCs of this hull fight with drones).
## Several hatches "drones", "drones_2" … = several hangar doors; drones launch from all of them at once.
## stripe_fx: the owner-colour stripes ("a") pulse, and in a fight a bright spot runs along them from bow to
## stern; launch_glow: they light up yellow while the drone doors are open (Concordia). arms.shift [back,
## out]: the parts move by this many pixels when open (Concordia's flight wings) – their hatches move along.
## Forge of Return (package 25f): reactor_mult (× reactor output), structure already lowered in the
## numbers; builtin "drone_pulse" (anti-drone pulse) and "auto_fire" (focus lasers fire on their own).
## Axiom Astronautics (package 25g): sensor_mult (× sensor range and scan strength), signature_mult,
## power_mult (× power draw – more efficient), builtin "cloak" (cloaking device); anomaly_finder (galaxy
## map: systems within N jumps with undiscovered anomalies); wormhole {max jumps, cooldown s, fail chance}
## (jumps without a gate, 1 exotic matter per jump of distance).
## arms {body, art, frames} (Goliath): the hull is drawn from `body`, the two arms from `art`_0 … _(frames-1)
## (top half, the lower arm mirrored): stage 0 folded in, the last stage open in a round arc. They open
## from their hinges at the stern in space and fold in while docking and undocking (the hangar bays are narrow).
## drones (package 23): how many drones the ship can have out at once (S 1 … L 9). Every hull has
## a drone hangar slot ("hangar", size = storage, quality = more room) and the three drone
## equipment slots dweapon (weapon size 1), dtool (mining laser size 1) and dbonus (drone module).
## slot_sizes (phase 0.5 package 19): maximum module size of every single slot – weapon/tool/optional
## lists in slot order (weapon_0, weapon_1 …), core slots one number each. "slots" holds the counts.
const HULLS := {
	# package 23: the drone itself (not sold, never flown by anyone)
	"drone": {
		"name": "Drone", "class": "Drone", "size": 1, "price": 0, "buyable": false, "drone_only": true,
		"structure": 60, "mass": 12, "signature": 6, "cargo": 5,
		"slots": {}, "slot_sizes": {}, "drones": 0,
		"shape": "drone", "length": 8,
		"desc": "Small autonomous drone.",
	},
	# 0.4.25.40: Axiom's cloak drone – launched instead of the plain drone when the hangar carries a drone
	# cloak emitter; it cloaks together with its ship
	"drone_cloak": {
		"name": "Cloak Drone", "class": "Drone", "size": 1, "price": 0, "buyable": false, "drone_only": true,
		"structure": 60, "mass": 12, "signature": 5, "cargo": 5,
		"slots": {}, "slot_sizes": {}, "drones": 0,
		"shape": "drone", "length": 8,
		"desc": "Axiom drone that cloaks together with its ship.",
	},
	"dragonfly": {
		"maker": "earthworks", "name": "Dragonfly", "class": "Scout Corvette", "size": 1, "price": 9000, "buyable": true,
		"structure": 350, "mass": 600, "signature": 25, "cargo": 15,
		"slots": {"weapon": 2, "tool": 3, "optional": 3, "dweapon": 1, "dtool": 1, "dbonus": 1},
		"slot_sizes": {"weapon": [1, 1], "tool": [2, 2, 1], "optional": [2, 2, 1], "hull": 2, "engine": 4, "reactor": 3, "distributor": 3, "tank": 3, "hyperdrive": 2, "sensors": 4, "hangar": 2, "dweapon": [1], "dtool": [1], "dbonus": [1]},
		"drones": 1, "shape": "scout", "length": 26,
		"hatches": {"drones": [4, 6, 3, 3]}, "hatch_overlay": true,
		"desc": "Fast, nimble scout. Ideal for scanning and analysing anomalies.",
	},
	"hornet": {
		"maker": "earthworks", "name": "Hornet", "class": "Fighter Corvette", "size": 1, "price": 20000, "buyable": true,
		"structure": 550, "mass": 850, "signature": 35, "cargo": 10,
		"slots": {"weapon": 3, "tool": 1, "optional": 3, "dweapon": 1, "dtool": 1, "dbonus": 1},
		"slot_sizes": {"weapon": [2, 2, 1], "tool": [1], "optional": [2, 2, 1], "hull": 3, "engine": 5, "reactor": 4, "distributor": 4, "tank": 2, "hyperdrive": 2, "sensors": 3, "hangar": 2, "dweapon": [1], "dtool": [1], "dbonus": [1]},
		"drones": 1, "shape": "fighter", "length": 30,
		"hatches": {"drones": [9, 6, 4, 3]}, "hatch_overlay": true,
		"desc": "Agile fighter with three weapon hardpoints.",
	},
	"crow": {
		"maker": "pirate", "name": "Carrion Crow", "class": "Pirate Raider", "size": 1, "price": 12000, "buyable": true, "haven_only": true,
		"structure": 450, "mass": 750, "signature": 32, "cargo": 10,
		"slots": {"weapon": 2, "tool": 1, "optional": 2, "dweapon": 1, "dtool": 1, "dbonus": 1},
		"slot_sizes": {"weapon": [2, 1], "tool": [1], "optional": [2, 1], "hull": 3, "engine": 4, "reactor": 3, "distributor": 3, "tank": 2, "hyperdrive": 2, "sensors": 2, "hangar": 1, "dweapon": [1], "dtool": [1], "dbonus": [1]},
		"drones": 1, "shape": "raider", "length": 28,
		"hatches": {"drones": [6, 5, 3, 3]}, "hatch_overlay": true,
		"desc": "Patched-together raider of the pirate clans.",
	},
	"mule": {
		"maker": "earthworks", "name": "Mule", "class": "Hauler", "size": 2, "price": 48000, "buyable": true,
		"structure": 1300, "mass": 2000, "signature": 85, "cargo": 220,
		"slots": {"weapon": 2, "tool": 2, "optional": 6, "dweapon": 1, "dtool": 1, "dbonus": 1},
		"slot_sizes": {"weapon": [2, 1], "tool": [2, 1], "optional": [6, 5, 5, 4, 3, 3], "hull": 5, "engine": 5, "reactor": 4, "distributor": 4, "tank": 6, "hyperdrive": 4, "sensors": 3, "hangar": 4, "dweapon": [1], "dtool": [1], "dbonus": [2]},
		"drones": 3, "shape": "hauler", "length": 48,
		"hatches": {"drones": [12, 7, 6, 5]}, "hatch_overlay": true,
		"desc": "Sturdy freighter with plenty of optional slots for cargo racks.",
	},
	"drillhead": {
		"maker": "earthworks", "name": "Drillhead", "class": "Mining Frigate", "size": 2, "price": 40000, "buyable": true,
		"structure": 1100, "mass": 1900, "signature": 75, "cargo": 140,
		"slots": {"weapon": 2, "tool": 4, "optional": 4, "dweapon": 1, "dtool": 1, "dbonus": 1},
		"slot_sizes": {"weapon": [2, 1], "tool": [3, 3, 2, 2], "optional": [4, 4, 3, 3], "hull": 4, "engine": 4, "reactor": 5, "distributor": 4, "tank": 4, "hyperdrive": 3, "sensors": 5, "hangar": 5, "dweapon": [1], "dtool": [1], "dbonus": [2]},
		"drones": 4, "shape": "miner", "length": 44,
		"hatches": {"drones": [7, 7, 6, 5]}, "hatch_overlay": true,
		"desc": "Mining vessel with three tool slots.",
	},
	"warden": {
		"maker": "earthworks", "name": "Warden", "class": "Combat Frigate", "size": 2, "price": 75000, "buyable": true,
		"structure": 1600, "mass": 2300, "signature": 95, "cargo": 40,
		"slots": {"weapon": 4, "tool": 2, "optional": 5, "dweapon": 1, "dtool": 1, "dbonus": 1},
		"slot_sizes": {"weapon": [3, 3, 2, 2], "tool": [2, 1], "optional": [5, 4, 4, 3, 2], "hull": 6, "engine": 6, "reactor": 6, "distributor": 6, "tank": 4, "hyperdrive": 4, "sensors": 5, "hangar": 5, "dweapon": [1], "dtool": [1], "dbonus": [2]},
		"drones": 4, "shape": "frigate", "length": 50,
		"hatches": {"drones": [6, 9, 4, 3]}, "hatch_overlay": true,
		"desc": "Versatile combat frigate.",
	},
	"bastion": {
		"maker": "earthworks", "name": "Bastion", "class": "Heavy Cruiser", "size": 3, "price": 240000, "buyable": true,
		"structure": 4200, "mass": 6500, "signature": 220, "cargo": 120,
		"slots": {"weapon": 6, "tool": 4, "optional": 6, "dweapon": 1, "dtool": 1, "dbonus": 1},
		"slot_sizes": {"weapon": [4, 4, 3, 3, 2, 2], "tool": [3, 3, 2, 2], "optional": [8, 7, 6, 6, 5, 4], "hull": 9, "engine": 8, "reactor": 9, "distributor": 9, "tank": 7, "hyperdrive": 6, "sensors": 7, "hangar": 9, "dweapon": [1], "dtool": [1], "dbonus": [3]},
		"drones": 9, "shape": "cruiser", "length": 80,
		"hatches": {"drones": [12, 12, 6, 5]}, "hatch_overlay": true,
		"desc": "Flagship class. Slow, but incredibly durable.",
	},
	# ---------------- Kanayama Heavy Industries (package 25a) ----------------
	"mogura": {
		"maker": "khi", "name": "Mogura", "class": "Mining Corvette", "size": 1, "price": 26000, "buyable": true,
		"structure": 650, "mass": 1150, "signature": 42, "cargo": 20,
		"slots": {"weapon": 1, "tool": 3, "optional": 4, "dweapon": 1, "dtool": 1, "dbonus": 1},
		"slot_sizes": {"weapon": [1], "tool": [2, 1, 1], "optional": [2, 2, 1, 1], "hull": 3, "engine": 4, "reactor": 4, "distributor": 3, "tank": 3, "hyperdrive": 2, "sensors": 3, "hangar": 1, "dweapon": [1], "dtool": [1], "dbonus": [1]},
		"drones": 1, "shape": "mogura", "length": 30,
		"hatches": {"drones": [6, 8, 4, 3]}, "hatch_overlay": true,
		"ore_cargo": 60, "mining_bonus": 0.10, "turn_mult": 0.75, "align_mult": 1.4,
		"refinery": {"rate": 0.15, "eff": 0.7, "power": 8}, "builtin": ["refinery", "prospect"],
		"desc": "\"Mole\" – KHI's small miner with its own refinery, ore hold and prospector. Tough and slow.",
	},
	"anaguma": {
		"maker": "khi", "name": "Anaguma", "class": "Mining Frigate", "size": 2, "price": 120000, "buyable": true,
		"structure": 1900, "mass": 3300, "signature": 95, "cargo": 60,
		"slots": {"weapon": 2, "tool": 3, "optional": 4, "dweapon": 1, "dtool": 1, "dbonus": 1},
		"slot_sizes": {"weapon": [2, 1], "tool": [3, 3, 2], "optional": [5, 4, 3, 3], "hull": 6, "engine": 5, "reactor": 6, "distributor": 5, "tank": 5, "hyperdrive": 4, "sensors": 4, "hangar": 3, "dweapon": [1], "dtool": [1], "dbonus": [2]},
		"drones": 2, "shape": "anaguma", "length": 50,
		"hatches": {"drones": [18, 10, 6, 5]}, "hatch_overlay": true,
		"ore_cargo": 300, "mining_bonus": 0.10, "turn_mult": 0.75, "align_mult": 1.4,
		"refinery": {"rate": 0.4, "eff": 0.8, "power": 16}, "builtin": ["refinery", "prospect"],
		"desc": "\"Badger\" – takes strip miners and ice harvesters, a big ore hold and a better refinery.",
	},
	"iwakudaki": {
		"maker": "khi", "name": "Iwakudaki", "class": "Mining Barge", "size": 3, "price": 420000, "buyable": true,
		"structure": 4600, "mass": 8200, "signature": 210, "cargo": 150,
		"slots": {"weapon": 2, "tool": 4, "optional": 4, "dweapon": 1, "dtool": 1, "dbonus": 1},
		"slot_sizes": {"weapon": [2, 2], "tool": [4, 4, 3, 3], "optional": [7, 6, 5, 4], "hull": 9, "engine": 8, "reactor": 8, "distributor": 7, "tank": 8, "hyperdrive": 5, "sensors": 5, "hangar": 5, "dweapon": [1], "dtool": [1], "dbonus": [3]},
		"drones": 4, "shape": "iwakudaki", "length": 84,
		"hatches": {"drones": [26, 11, 8, 7]}, "hatch_overlay": true,
		"ore_cargo": 900, "mining_bonus": 0.10, "turn_mult": 0.75, "align_mult": 1.4,
		"refinery": {"rate": 1.0, "eff": 0.9, "power": 32}, "builtin": ["refinery", "prospect"],
		"desc": "\"Rock breaker\" – KHI's heavy mining barge: four big tool slots, a huge ore hold, a strong refinery.",
	},
	"kanayama": {
		"maker": "khi", "name": "Kanayama-maru", "class": "Heavy Industry Ship", "size": 3, "price": 950000, "buyable": true,
		"structure": 6200, "mass": 11500, "signature": 260, "cargo": 400,
		"slots": {"weapon": 2, "tool": 2, "optional": 4, "dweapon": 1, "dtool": 1, "dbonus": 1},
		"slot_sizes": {"weapon": [2, 2], "tool": [3, 3], "optional": [8, 7, 6, 5], "hull": 9, "engine": 9, "reactor": 10, "distributor": 9, "tank": 9, "hyperdrive": 5, "sensors": 5, "hangar": 9, "dweapon": [1], "dtool": [1], "dbonus": [3]},
		"drones": 9, "shape": "kanayama", "length": 96,
		"ore_cargo": 1200, "mining_bonus": 0.10, "turn_mult": 0.6, "align_mult": 1.7,
		"refinery": {"rate": 3.0, "eff": 1.0, "power": 60}, "factory": {"power": 30}, "market": {"power": 6},
		"builtin": ["refinery", "prospect", "factory", "market"],
		"drone_bonus": {"mining": 0.25, "cargo": 5.0}, "drone_paint": "khi_drone",
		"drone_deck": [44, 90],
		"desc": "KHI's heavy industry ship: a drone carrier for nine mining drones, a refinery as good as a station's, a factory and an on-board market.",
	},
	# package 41: KHI's gas freighter
	"kujira": {
		"maker": "khi", "name": "Kujira", "class": "Gas Freighter", "size": 3, "price": 640000, "buyable": true,
		"structure": 5400, "mass": 9600, "signature": 240, "cargo": 220,
		"slots": {"weapon": 2, "tool": 2, "optional": 3, "dweapon": 1, "dtool": 1, "dbonus": 1},
		"slot_sizes": {"weapon": [2, 2], "tool": [3, 3], "optional": [6, 5, 4], "hull": 9, "engine": 8, "reactor": 8, "distributor": 7, "tank": 8, "hyperdrive": 5, "sensors": 5, "hangar": 4, "dweapon": [1], "dtool": [1], "dbonus": [2]},
		"drones": 2, "shape": "kujira", "length": 116,
		"hatches": {"drones": [98, 12, 6, 7]}, "hatch_overlay": true,
		"gas_cargo": 1600, "heat_resist": 0.6, "turn_mult": 0.65, "align_mult": 1.6,
		"builtin": ["gas"],
		"desc": "\"Whale\" – KHI's gas freighter: three great round tanks (1,600 m³ of gas), a gas scoop under the drone hatch, the bridge raised on the nose and a hull that bears the heat deep in a giant's harvest band.",
	},
	# ---------------- Axiom Astronautics (package 25g, Meridian Directorate) ----------------
	"axa_parallax": {
		"maker": "axiom", "name": "Parallax", "class": "Research Ship", "size": 1, "price": 42000, "buyable": true, "min_tier": "neutral",
		"structure": 420, "mass": 600, "signature": 26, "cargo": 18,
		"slots": {"weapon": 2, "tool": 3, "optional": 3, "dweapon": 1, "dtool": 1, "dbonus": 1},
		"slot_sizes": {"weapon": [2, 1], "tool": [2, 2, 1], "optional": [3, 2, 2], "hull": 3, "engine": 4, "reactor": 4, "distributor": 4, "tank": 4, "hyperdrive": 3, "sensors": 5, "hangar": 2, "dweapon": [1], "dtool": [1], "dbonus": [1]},
		"drones": 1, "shape": "axa_parallax", "length": 36,
		"hatches": {"drones": [21, 5, 4, 3]}, "hatch_overlay": true,
		"sensor_mult": 1.25, "signature_mult": 0.75, "power_mult": 0.85, "builtin": ["cloak"], "anomaly_finder": 4,
		"cloak": {"energy_rate": 5.0, "power": 8.0},
		"desc": "Axiom's research ship: keen sensors, a low signature, a cloaking device – and it marks every system within four jumps that still hides undiscovered anomalies.",
	},
	"axa_threshold": {
		"maker": "axiom", "name": "Threshold", "class": "Jump Ship (Prototype)", "size": 3, "price": 980000, "buyable": true, "min_tier": "allied",
		"structure": 4300, "mass": 7600, "signature": 200, "cargo": 140,
		"slots": {"weapon": 4, "tool": 2, "optional": 4, "dweapon": 1, "dtool": 1, "dbonus": 1},
		"slot_sizes": {"weapon": [3, 3, 2, 2], "tool": [2, 1], "optional": [7, 6, 5, 4], "hull": 8, "engine": 8, "reactor": 9, "distributor": 8, "tank": 7, "hyperdrive": 6, "sensors": 7, "hangar": 5, "dweapon": [1], "dtool": [1], "dbonus": [3]},
		"drones": 4, "shape": "axa_threshold", "length": 124,
		"hatches": {"drones": [88, 18, 6, 5]}, "black_hole": {"core": [60, 20]}, "hatch_overlay": true,
		"sensor_mult": 1.25, "signature_mult": 0.75, "power_mult": 0.85, "builtin": ["cloak"],
		"cloak": {"energy_rate": 18.0, "power": 30.0},
		"wormhole": {"max": 8, "cooldown": 120.0, "fail": 0.12},
		"desc": "Axiom's prototype jump ship: an artificial black hole in its round core opens a small wormhole – it jumps without a gate, up to eight jumps far, for one unit of exotic matter per jump. Not through the Veil.",
	},
	# ---------------- Forge of Return (package 25f, Covenant of Return) ----------------
	"for_acolyte": {
		"maker": "forge", "name": "Acolyte", "class": "Militia Ship", "size": 1, "price": 36000, "buyable": true, "min_tier": "neutral",
		"structure": 300, "mass": 640, "signature": 34, "cargo": 10,
		"slots": {"weapon": 3, "tool": 1, "optional": 2, "dweapon": 0, "dtool": 0, "dbonus": 0},
		"slot_sizes": {"weapon": [2, 2, 1], "tool": [1], "optional": [2, 1], "hull": 2, "engine": 4, "reactor": 5, "distributor": 5, "tank": 2, "hyperdrive": 2, "sensors": 3, "hangar": 0},
		"drones": 0, "shape": "for_acolyte", "length": 38, "reactor_mult": 1.8,
		"desc": "A crimson reliquary blade around a golden chapel: little hull, a very strong reactor, focus-crystal lasers. With crystals in every hardpoint their beams join into one lance (+30 %).",
	},
	"for_templar": {
		"maker": "forge", "name": "Templar", "class": "Patrol Ship", "size": 2, "price": 175000, "buyable": true, "min_tier": "friendly",
		"structure": 1150, "mass": 2100, "signature": 90, "cargo": 35,
		"slots": {"weapon": 5, "tool": 1, "optional": 3, "dweapon": 0, "dtool": 0, "dbonus": 0},
		"slot_sizes": {"weapon": [3, 3, 2, 2, 2], "tool": [1], "optional": [4, 3, 3], "hull": 4, "engine": 6, "reactor": 7, "distributor": 7, "tank": 4, "hyperdrive": 4, "sensors": 5, "hangar": 0},
		"drones": 0, "shape": "for_templar", "length": 62, "reactor_mult": 1.8, "spike_fx": true,
		"desc": "A flying chapel with crimson flanks and golden buttresses: five hardpoints, an even bigger reactor, the same weak hull. Crystal beams join into one lance (+30 %).",
	},
	"for_cathedral": {
		"maker": "forge", "name": "Cathedral", "class": "Flagship", "size": 3, "price": 850000, "buyable": true, "min_tier": "allied",
		"structure": 5400, "mass": 9000, "signature": 260, "cargo": 120,
		"slots": {"weapon": 8, "tool": 1, "optional": 4, "dweapon": 0, "dtool": 0, "dbonus": 0},
		"slot_sizes": {"weapon": [4, 4, 4, 3, 3, 3, 2, 2], "tool": [1], "optional": [8, 6, 5, 4], "hull": 9, "engine": 7, "reactor": 10, "distributor": 10, "tank": 7, "hyperdrive": 6, "sensors": 7, "hangar": 0},
		"drones": 0, "shape": "for_cathedral", "length": 124, "reactor_mult": 2.2, "spike_fx": true,
		"builtin": ["drone_pulse", "auto_fire"],
		"drone_pulse": {"range": 5000.0, "interval": 30.0, "stun": 15.0, "energy": 420.0, "power": 45.0},
		"desc": "A fortress of faith: crimson battlements full of crystal batteries around a radiant nave with stained glass, a rose window at the bow, a golden halo over the sanctuary. Eight hardpoints – with crystals in all of them one mighty lance –, a huge reactor, an anti-drone pulse and an auto mode for its lasers.",
	},
	# ---------------- Concord Fleetworks (package 25e, Cluster Assembly) ----------------
	"cfw_demos": {
		"maker": "concord", "name": "Demos", "class": "Militia Carrier", "size": 1, "price": 32000, "buyable": true, "min_tier": "neutral",
		"structure": 430, "mass": 720, "signature": 30, "cargo": 12,
		"slots": {"weapon": 2, "tool": 1, "optional": 3, "dweapon": 1, "dtool": 1, "dbonus": 1},
		"slot_sizes": {"weapon": [1, 1], "tool": [1], "optional": [2, 2, 1], "hull": 2, "engine": 4, "reactor": 4, "distributor": 4, "tank": 3, "hyperdrive": 2, "sensors": 3, "hangar": 4, "dweapon": [1], "dtool": [1], "dbonus": [1]},
		"drones": 3, "shape": "cfw_demos", "length": 37,
		"shield_mult": 1.6, "shield_down_mult": 3.0, "weapon_dmg_mult": 0.5, "drone_mult": 2.0, "npc_drones": true, "stripe_fx": true,
		"hatches": {"drones": [12, 1, 6, 2], "drones_2": [12, 12, 6, 2]},
		"desc": "\"The people\" – the Assembly's small militia carrier: three drones with double strength and range from two hangar doors, good shields, light guns, little armour.",
	},
	"cfw_quirinus": {
		"maker": "concord", "name": "Quirinus", "class": "Patrol Carrier", "size": 2, "price": 150000, "buyable": true, "min_tier": "friendly",
		"structure": 1500, "mass": 2200, "signature": 85, "cargo": 50,
		"slots": {"weapon": 3, "tool": 2, "optional": 4, "dweapon": 1, "dtool": 1, "dbonus": 1},
		"slot_sizes": {"weapon": [2, 2, 1], "tool": [1, 1], "optional": [5, 4, 3, 3], "hull": 4, "engine": 5, "reactor": 6, "distributor": 6, "tank": 4, "hyperdrive": 4, "sensors": 5, "hangar": 7, "dweapon": [1], "dtool": [1], "dbonus": [2]},
		"drones": 7, "shape": "cfw_quirinus", "length": 58,
		"shield_mult": 1.6, "shield_down_mult": 3.0, "weapon_dmg_mult": 0.5, "drone_mult": 2.0, "npc_drones": true, "stripe_fx": true,
		"hatches": {"drones": [13, 1, 7, 2], "drones_2": [13, 18, 7, 2], "drones_3": [25, 1, 7, 2], "drones_4": [25, 18, 7, 2]},
		"desc": "The Assembly's patrol carrier: seven drones of double strength from four hangar doors, good shields.",
	},
	"cfw_concordia": {
		"maker": "concord", "name": "Concordia", "class": "Fleet Carrier", "size": 3, "price": 720000, "buyable": true, "min_tier": "allied",
		"structure": 4800, "mass": 7800, "signature": 230, "cargo": 150,
		"slots": {"weapon": 1, "tool": 2, "optional": 5, "dweapon": 1, "dtool": 1, "dbonus": 1},
		"slot_sizes": {"weapon": [4], "tool": [2, 1], "optional": [8, 7, 6, 5, 4], "hull": 7, "engine": 7, "reactor": 9, "distributor": 9, "tank": 7, "hyperdrive": 6, "sensors": 8, "hangar": 9, "dweapon": [1], "dtool": [1], "dbonus": [3]},
		"drones": 11, "shape": "cfw_concordia", "length": 114,
		"shield_mult": 1.9, "shield_down_mult": 3.0, "weapon_dmg_mult": 0.5, "drone_mult": 2.0, "npc_drones": true,
		"drone_paint": "assembly_drone", "stripe_fx": true, "launch_glow": true,
		"arms": {"body": "cfw_concordia_body", "art": "cfw_concordia_wing", "frames": 6, "shift": [4, 4]},
		"hatches": {"drones": [20, 4, 10, 3], "drones_2": [20, 24, 10, 3], "drones_3": [40, 4, 10, 3], "drones_4": [40, 24, 10, 3], "drones_5": [60, 4, 10, 3], "drones_6": [60, 24, 10, 3]},
		"desc": "The Assembly's flagship: a long fleet carrier – the only ship that controls eleven drones, in Assembly blue, launched from six hangar doors at once. One big gun, keen sensors, very strong shields.",
	},
	# ---------------- Hadrian Dynamics (package 25d) ----------------
	"hdy_talon": {
		"maker": "hadrian", "name": "Talon", "class": "Dropship", "size": 1, "price": 34000, "buyable": true,
		"structure": 620, "mass": 900, "signature": 52, "cargo": 8,
		"slots": {"weapon": 4, "tool": 0, "optional": 3, "dweapon": 0, "dtool": 0, "dbonus": 0},
		"slot_sizes": {"weapon": [2, 2, 2, 1], "tool": [], "optional": [2, 2, 1], "hull": 4, "engine": 5, "reactor": 4, "distributor": 4, "tank": 2, "hyperdrive": 2, "sensors": 3, "hangar": 0},
		"drones": 0, "shape": "hdy_talon", "length": 36,
		"speed_mult": 1.15, "shield_mult": 1.4, "reflect": 0.10, "work_mult": 0.5, "missile_rof": 1.3,
		"desc": "Hadrian's dropship: fast, heavily armed, strong shields, rockets and torpedoes fire faster. A reflective hull sends 10 % of the damage to its armour back. Useless for anything but war.",
	},
	"hdy_maul": {
		"maker": "hadrian", "name": "Maul", "class": "Gunboat", "size": 2, "price": 115000, "buyable": true,
		"structure": 1900, "mass": 2400, "signature": 120, "cargo": 30,
		"slots": {"weapon": 5, "tool": 1, "optional": 4, "dweapon": 1, "dtool": 1, "dbonus": 1},
		"slot_sizes": {"weapon": [3, 3, 2, 2, 2], "tool": [1], "optional": [5, 4, 3, 3], "hull": 6, "engine": 6, "reactor": 6, "distributor": 6, "tank": 4, "hyperdrive": 4, "sensors": 5, "hangar": 2, "dweapon": [1], "dtool": [1], "dbonus": [1]},
		"drones": 1, "shape": "hdy_maul", "length": 54,
		"hatches": {"drones": [7, 9, 6, 5]}, "hatch_overlay": true,
		"speed_mult": 1.15, "reflect": 0.15, "res_bonus": {"explosive": 0.2}, "work_mult": 0.5, "heavy_missiles": true,
		"desc": "A fast gunboat with five hardpoints and a small drone hangar. Its reflective hull sends 15 % of the armour damage back; +20 % explosive resistance.",
	},
	"hdy_goliath": {
		"maker": "hadrian", "name": "Goliath", "class": "Destroyer", "size": 2, "price": 280000, "buyable": true,
		"structure": 2600, "mass": 3400, "signature": 150, "cargo": 35,
		"slots": {"weapon": 6, "tool": 1, "optional": 4, "dweapon": 1, "dtool": 1, "dbonus": 1},
		"slot_sizes": {"weapon": [4, 4, 3, 3, 2, 2], "tool": [1], "optional": [5, 5, 4, 3], "hull": 7, "engine": 7, "reactor": 8, "distributor": 7, "tank": 4, "hyperdrive": 4, "sensors": 5, "hangar": 5, "dweapon": [1], "dtool": [1], "dbonus": [2]},
		"drones": 4, "shape": "hdy_goliath", "length": 86,
		"hatches": {"drones": [28, 16, 10, 9]},
		"arms": {"body": "hdy_goliath_body", "art": "hdy_goliath_arm", "frames": 8},
		"speed_mult": 1.1, "reflect": 0.15, "res_bonus": {"explosive": 0.2}, "work_mult": 0.5, "heavy_missiles": true,
		"builtin": ["pd"], "yard_rule": "military",
		"desc": "Hadrian's scorpion: a destroyer with the guns of a cruiser on two mighty arms that end in pincers, fast for its punch, built-in point defence; its drones rise from a hatch on the spine. Sold only at military stations and the biggest yards.",
	},
	"hdy_citadel": {
		"maker": "hadrian", "name": "Citadel", "class": "Fleet Carrier", "size": 3, "price": 560000, "buyable": true,
		"structure": 5600, "mass": 8600, "signature": 280, "cargo": 140,
		"slots": {"weapon": 5, "tool": 1, "optional": 5, "dweapon": 1, "dtool": 1, "dbonus": 1},
		"slot_sizes": {"weapon": [3, 3, 3, 2, 2], "tool": [1], "optional": [8, 7, 6, 5, 4], "hull": 9, "engine": 8, "reactor": 9, "distributor": 9, "tank": 7, "hyperdrive": 6, "sensors": 6, "hangar": 9, "dweapon": [1], "dtool": [1], "dbonus": [3]},
		"drones": 9, "shape": "hdy_citadel", "length": 100,
		"reflect": 0.20, "res_bonus": {"explosive": 0.2}, "work_mult": 0.5, "heavy_missiles": true, "small_ship_bay": true,
		"hatches": {"platform": [43, 12, 15, 13], "drones": [20, 14, 8, 9]},
		"builtin": ["pd"], "yard_rule": "military",
		"desc": "A small fleet carrier – a fortress with nine drones, built-in point defence and a reflective hull (20 %). Sold only at military stations and the biggest yards.",
	},
	# ---------------- Maison Aurelle (package 25c) ----------------
	"aur_pearl": {
		"maker": "aurelle", "name": "Pearl", "class": "Luxury Yacht", "size": 1, "price": 45000, "buyable": true,
		"structure": 380, "mass": 480, "signature": 24, "cargo": 10,
		"slots": {"weapon": 2, "tool": 0, "optional": 2, "dweapon": 0, "dtool": 0, "dbonus": 0},
		"slot_sizes": {"weapon": [1, 1], "tool": [], "optional": [3, 2], "hull": 2, "engine": 5, "reactor": 3, "distributor": 3, "tank": 3, "hyperdrive": 3, "sensors": 2, "hangar": 0},
		"drones": 0, "shape": "aur_pearl", "length": 34,
		"speed_mult": 1.35, "align_mult": 0.8, "shield_mult": 1.2,
		"afterburner": {"boost": 1.5, "energy_rate": 6, "power": 6}, "builtin": ["afterburner"],
		"desc": "Maison Aurelle's small luxury yacht – extremely fast, takes luxury suites, a built-in afterburner.",
	},
	"aur_boulevard": {
		"maker": "aurelle", "name": "Boulevard", "class": "Passenger Liner", "size": 2, "price": 120000, "buyable": true,
		"structure": 1300, "mass": 1700, "signature": 70, "cargo": 60,
		"slots": {"weapon": 3, "tool": 1, "optional": 4, "dweapon": 1, "dtool": 1, "dbonus": 1},
		"slot_sizes": {"weapon": [2, 2, 1], "tool": [1], "optional": [5, 4, 4, 3], "hull": 5, "engine": 7, "reactor": 5, "distributor": 5, "tank": 5, "hyperdrive": 4, "sensors": 3, "hangar": 2, "dweapon": [1], "dtool": [1], "dbonus": [1]},
		"drones": 1, "shape": "aur_boulevard", "length": 54,
		"hatches": {"drones": [20, 8, 4, 3]}, "hatch_overlay": true,
		"speed_mult": 1.25, "align_mult": 0.7, "shield_mult": 1.2, "luxury_pay": 0.8,
		"afterburner": {"boost": 1.45, "energy_rate": 12, "power": 12}, "builtin": ["afterburner"],
		"desc": "The liner of the rich systems: strong engines, quick to align for warp, a built-in afterburner. Luxury suites fit, but pay 20 % less.",
	},
	"aur_opal": {
		"maker": "aurelle", "name": "Opal", "class": "Luxury Liner", "size": 2, "price": 170000, "buyable": true,
		"structure": 1200, "mass": 1600, "signature": 66, "cargo": 40,
		"slots": {"weapon": 2, "tool": 1, "optional": 5, "dweapon": 0, "dtool": 0, "dbonus": 0},
		"slot_sizes": {"weapon": [2, 1], "tool": [1], "optional": [5, 5, 4, 4, 3], "hull": 5, "engine": 7, "reactor": 5, "distributor": 5, "tank": 5, "hyperdrive": 4, "sensors": 3, "hangar": 0},
		"drones": 0, "shape": "aur_opal", "length": 58,
		"speed_mult": 1.45, "align_mult": 0.8, "shield_mult": 1.25,
		"afterburner": {"boost": 1.45, "energy_rate": 12, "power": 12}, "builtin": ["afterburner"],
		"desc": "A medium luxury liner with a glass lounge – extremely fast for its size, luxury suites, a built-in afterburner.",
	},
	"aur_empress": {
		"maker": "aurelle", "name": "Empress", "class": "Megaliner", "size": 3, "price": 650000, "buyable": true,
		"structure": 4400, "mass": 7800, "signature": 230, "cargo": 160,
		"slots": {"weapon": 3, "tool": 1, "optional": 6, "dweapon": 1, "dtool": 1, "dbonus": 1},
		"slot_sizes": {"weapon": [3, 3, 2], "tool": [1], "optional": [9, 9, 8, 8, 7, 6], "hull": 8, "engine": 9, "reactor": 9, "distributor": 9, "tank": 8, "hyperdrive": 6, "sensors": 5, "hangar": 5, "dweapon": [1], "dtool": [1], "dbonus": [3]},
		"drones": 4, "shape": "aur_empress", "length": 112,
		"hatches": {"drones": [9, 14, 4, 5]}, "hatch_overlay": true,
		"turn_mult": 0.7, "align_mult": 0.6, "warp_mult": 1.35, "shield_mult": 1.6, "cargo_mod_mult": 0.5, "luxury_pay": 1.25,
		"drone_paint": "aurelle_drone", "drone_bonus": {"shield": 60.0, "shield_regen": 5.0, "shield_mult": 1.5},
		"desc": "Maison Aurelle's cruise megaliner: slow to turn, but quick to align and fast in warp, with strong shields. Luxury contracts pay 25 % more; cargo racks give only half their room. Its white drones carry their own shield.",
	},
	# ---------------- Civilian NPC hulls (phase 0.5 package 11) ----------------
	"shuttle": {
		"maker": "earthworks", "name": "Skiff", "class": "Passenger Shuttle", "size": 1, "price": 6000, "buyable": true,
		"structure": 220, "mass": 380, "signature": 22, "cargo": 8,
		"slots": {"weapon": 0, "tool": 0, "optional": 1, "dweapon": 1, "dtool": 1, "dbonus": 1},
		"slot_sizes": {"weapon": [], "tool": [], "optional": [2], "hull": 1, "engine": 3, "reactor": 2, "distributor": 2, "tank": 2, "hyperdrive": 1, "sensors": 1, "hangar": 1, "dweapon": [1], "dtool": [1], "dbonus": [1]},
		"drones": 1, "shape": "shuttle", "length": 20,
		"hatches": {"drones": [2, 3, 3, 3]}, "hatch_overlay": true,
		"desc": "Planet-to-orbit shuttle carrying passengers and light freight.",
	},
	"freighter": {
		"maker": "earthworks", "name": "Longhaul", "class": "Bulk Freighter", "size": 3, "price": 180000, "buyable": true,
		"structure": 3200, "mass": 7200, "signature": 240, "cargo": 900,
		"slots": {"weapon": 1, "tool": 0, "optional": 4, "dweapon": 1, "dtool": 1, "dbonus": 1},
		"slot_sizes": {"weapon": [2], "tool": [], "optional": [9, 8, 8, 7], "hull": 7, "engine": 8, "reactor": 6, "distributor": 5, "tank": 9, "hyperdrive": 5, "sensors": 3, "hangar": 6, "dweapon": [1], "dtool": [1], "dbonus": [3]},
		"drones": 5, "shape": "freighter", "length": 92,
		"hatches": {"drones": [15, 6, 8, 7]}, "hatch_overlay": true,
		"desc": "Container freighter of the trade convoys. Slow, huge and a tempting prize.",
	},
}
