extends RefCounted
## Ship hulls: base stats + slot layout.
## size: 1 = S (corvette), 2 = M (frigate), 3 = L (cruiser).
## Modules may be at most the size of the hull. Slot counts raised in phase 0.5 (more modules to fit).
## Every ship has each core slot exactly once (hull plating, engine, power distributor,
## reactor, fuel tank, hyperdrive, sensors).

## maker (package 25): manufacturer (data/manufacturers.gd); "pirate" = pirate-built.
## Hull traits (package 25a, KHI): ore_cargo (built-in ore hold m³), mining_bonus (+ on every asteroid class),
## turn_mult, align_mult (warp alignment time ×), refinery {rate ore/s, eff yield ×, power MW},
## builtin (built-in modules: "prospect", "refinery").
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
	"dragonfly": {
		"maker": "earthworks", "name": "Dragonfly", "class": "Scout Corvette", "size": 1, "price": 9000, "buyable": true,
		"structure": 350, "mass": 600, "signature": 25, "cargo": 15,
		"slots": {"weapon": 2, "tool": 3, "optional": 3, "dweapon": 1, "dtool": 1, "dbonus": 1},
		"slot_sizes": {"weapon": [1, 1], "tool": [2, 2, 1], "optional": [2, 2, 1], "hull": 2, "engine": 4, "reactor": 3, "distributor": 3, "tank": 3, "hyperdrive": 2, "sensors": 4, "hangar": 2, "dweapon": [1], "dtool": [1], "dbonus": [1]},
		"drones": 1, "shape": "scout", "length": 26,
		"desc": "Fast, nimble scout. Ideal for scanning and analysing anomalies.",
	},
	"hornet": {
		"maker": "earthworks", "name": "Hornet", "class": "Fighter Corvette", "size": 1, "price": 20000, "buyable": true,
		"structure": 550, "mass": 850, "signature": 35, "cargo": 10,
		"slots": {"weapon": 3, "tool": 1, "optional": 3, "dweapon": 1, "dtool": 1, "dbonus": 1},
		"slot_sizes": {"weapon": [2, 2, 1], "tool": [1], "optional": [2, 2, 1], "hull": 3, "engine": 5, "reactor": 4, "distributor": 4, "tank": 2, "hyperdrive": 2, "sensors": 3, "hangar": 2, "dweapon": [1], "dtool": [1], "dbonus": [1]},
		"drones": 1, "shape": "fighter", "length": 30,
		"desc": "Agile fighter with three weapon hardpoints.",
	},
	"crow": {
		"maker": "pirate", "name": "Carrion Crow", "class": "Pirate Raider", "size": 1, "price": 12000, "buyable": true, "haven_only": true,
		"structure": 450, "mass": 750, "signature": 32, "cargo": 10,
		"slots": {"weapon": 2, "tool": 1, "optional": 2, "dweapon": 1, "dtool": 1, "dbonus": 1},
		"slot_sizes": {"weapon": [2, 1], "tool": [1], "optional": [2, 1], "hull": 3, "engine": 4, "reactor": 3, "distributor": 3, "tank": 2, "hyperdrive": 2, "sensors": 2, "hangar": 1, "dweapon": [1], "dtool": [1], "dbonus": [1]},
		"drones": 1, "shape": "raider", "length": 28,
		"desc": "Patched-together raider of the pirate clans.",
	},
	"mule": {
		"maker": "earthworks", "name": "Mule", "class": "Hauler", "size": 2, "price": 48000, "buyable": true,
		"structure": 1300, "mass": 2000, "signature": 85, "cargo": 220,
		"slots": {"weapon": 2, "tool": 2, "optional": 6, "dweapon": 1, "dtool": 1, "dbonus": 1},
		"slot_sizes": {"weapon": [2, 1], "tool": [2, 1], "optional": [6, 5, 5, 4, 3, 3], "hull": 5, "engine": 5, "reactor": 4, "distributor": 4, "tank": 6, "hyperdrive": 4, "sensors": 3, "hangar": 4, "dweapon": [1], "dtool": [1], "dbonus": [2]},
		"drones": 3, "shape": "hauler", "length": 48,
		"desc": "Sturdy freighter with plenty of optional slots for cargo racks.",
	},
	"drillhead": {
		"maker": "earthworks", "name": "Drillhead", "class": "Mining Frigate", "size": 2, "price": 40000, "buyable": true,
		"structure": 1100, "mass": 1900, "signature": 75, "cargo": 140,
		"slots": {"weapon": 2, "tool": 4, "optional": 4, "dweapon": 1, "dtool": 1, "dbonus": 1},
		"slot_sizes": {"weapon": [2, 1], "tool": [3, 3, 2, 2], "optional": [4, 4, 3, 3], "hull": 4, "engine": 4, "reactor": 5, "distributor": 4, "tank": 4, "hyperdrive": 3, "sensors": 5, "hangar": 5, "dweapon": [1], "dtool": [1], "dbonus": [2]},
		"drones": 4, "shape": "miner", "length": 44,
		"desc": "Mining vessel with three tool slots.",
	},
	"warden": {
		"maker": "earthworks", "name": "Warden", "class": "Combat Frigate", "size": 2, "price": 75000, "buyable": true,
		"structure": 1600, "mass": 2300, "signature": 95, "cargo": 40,
		"slots": {"weapon": 4, "tool": 2, "optional": 5, "dweapon": 1, "dtool": 1, "dbonus": 1},
		"slot_sizes": {"weapon": [3, 3, 2, 2], "tool": [2, 1], "optional": [5, 4, 4, 3, 2], "hull": 6, "engine": 6, "reactor": 6, "distributor": 6, "tank": 4, "hyperdrive": 4, "sensors": 5, "hangar": 5, "dweapon": [1], "dtool": [1], "dbonus": [2]},
		"drones": 4, "shape": "frigate", "length": 50,
		"desc": "Versatile combat frigate.",
	},
	"bastion": {
		"maker": "earthworks", "name": "Bastion", "class": "Heavy Cruiser", "size": 3, "price": 240000, "buyable": true,
		"structure": 4200, "mass": 6500, "signature": 220, "cargo": 120,
		"slots": {"weapon": 6, "tool": 4, "optional": 6, "dweapon": 1, "dtool": 1, "dbonus": 1},
		"slot_sizes": {"weapon": [4, 4, 3, 3, 2, 2], "tool": [3, 3, 2, 2], "optional": [8, 7, 6, 6, 5, 4], "hull": 9, "engine": 8, "reactor": 9, "distributor": 9, "tank": 7, "hyperdrive": 6, "sensors": 7, "hangar": 9, "dweapon": [1], "dtool": [1], "dbonus": [3]},
		"drones": 9, "shape": "cruiser", "length": 80,
		"desc": "Flagship class. Slow, but incredibly durable.",
	},
	# ---------------- Kanayama Heavy Industries (package 25a) ----------------
	"mogura": {
		"maker": "khi", "name": "Mogura", "class": "Mining Corvette", "size": 1, "price": 26000, "buyable": true,
		"structure": 650, "mass": 1150, "signature": 42, "cargo": 20,
		"slots": {"weapon": 1, "tool": 3, "optional": 4, "dweapon": 1, "dtool": 1, "dbonus": 1},
		"slot_sizes": {"weapon": [1], "tool": [2, 1, 1], "optional": [2, 2, 1, 1], "hull": 3, "engine": 4, "reactor": 4, "distributor": 3, "tank": 3, "hyperdrive": 2, "sensors": 3, "hangar": 1, "dweapon": [1], "dtool": [1], "dbonus": [1]},
		"drones": 1, "shape": "mogura", "length": 30,
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
		"desc": "KHI's heavy industry ship: a drone carrier for nine mining drones, a refinery as good as a station's, a factory and an on-board market.",
	},
	# ---------------- Civilian NPC hulls (phase 0.5 package 11) ----------------
	"shuttle": {
		"maker": "earthworks", "name": "Skiff", "class": "Passenger Shuttle", "size": 1, "price": 6000, "buyable": true,
		"structure": 220, "mass": 380, "signature": 22, "cargo": 8,
		"slots": {"weapon": 0, "tool": 0, "optional": 1, "dweapon": 1, "dtool": 1, "dbonus": 1},
		"slot_sizes": {"weapon": [], "tool": [], "optional": [2], "hull": 1, "engine": 3, "reactor": 2, "distributor": 2, "tank": 2, "hyperdrive": 1, "sensors": 1, "hangar": 1, "dweapon": [1], "dtool": [1], "dbonus": [1]},
		"drones": 1, "shape": "shuttle", "length": 20,
		"desc": "Planet-to-orbit shuttle carrying passengers and light freight.",
	},
	"freighter": {
		"maker": "earthworks", "name": "Longhaul", "class": "Bulk Freighter", "size": 3, "price": 180000, "buyable": true,
		"structure": 3200, "mass": 7200, "signature": 240, "cargo": 900,
		"slots": {"weapon": 1, "tool": 0, "optional": 4, "dweapon": 1, "dtool": 1, "dbonus": 1},
		"slot_sizes": {"weapon": [2], "tool": [], "optional": [9, 8, 8, 7], "hull": 7, "engine": 8, "reactor": 6, "distributor": 5, "tank": 9, "hyperdrive": 5, "sensors": 3, "hangar": 6, "dweapon": [1], "dtool": [1], "dbonus": [3]},
		"drones": 5, "shape": "freighter", "length": 92,
		"desc": "Container freighter of the trade convoys. Slow, huge and a tempting prize.",
	},
}
