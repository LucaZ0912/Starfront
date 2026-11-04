extends RefCounted
## Ship hulls: base stats + slot layout.
## size: 1 = S (corvette), 2 = M (frigate), 3 = L (cruiser).
## Modules may be at most the size of the hull. Slot counts raised in phase 0.5 (more modules to fit).
## Every ship has each core slot exactly once (hull plating, engine, power distributor,
## reactor, fuel tank, hyperdrive, sensors).

const HULLS := {
	"dragonfly": {
		"name": "Dragonfly", "class": "Scout Corvette", "size": 1, "price": 9000, "buyable": true,
		"structure": 350, "mass": 600, "signature": 25, "cargo": 15,
		"slots": {"weapon": 2, "tool": 3, "optional": 3},
		"shape": "scout", "length": 26,
		"desc": "Fast, nimble scout. Ideal for scanning and analysing anomalies.",
	},
	"hornet": {
		"name": "Hornet", "class": "Fighter Corvette", "size": 1, "price": 20000, "buyable": true,
		"structure": 550, "mass": 850, "signature": 35, "cargo": 10,
		"slots": {"weapon": 3, "tool": 1, "optional": 3},
		"shape": "fighter", "length": 30,
		"desc": "Agile fighter with three weapon hardpoints.",
	},
	"crow": {
		"name": "Carrion Crow", "class": "Pirate Raider", "size": 1, "price": 12000, "buyable": false,
		"structure": 450, "mass": 750, "signature": 32, "cargo": 10,
		"slots": {"weapon": 2, "tool": 1, "optional": 2},
		"shape": "raider", "length": 28,
		"desc": "Patched-together raider of the pirate clans.",
	},
	"mule": {
		"name": "Mule", "class": "Hauler", "size": 2, "price": 48000, "buyable": true,
		"structure": 1300, "mass": 2000, "signature": 85, "cargo": 220,
		"slots": {"weapon": 2, "tool": 2, "optional": 6},
		"shape": "hauler", "length": 48,
		"desc": "Sturdy freighter with plenty of optional slots for cargo racks.",
	},
	"drillhead": {
		"name": "Drillhead", "class": "Mining Frigate", "size": 2, "price": 40000, "buyable": true,
		"structure": 1100, "mass": 1900, "signature": 75, "cargo": 140,
		"slots": {"weapon": 2, "tool": 4, "optional": 4},
		"shape": "miner", "length": 44,
		"desc": "Mining vessel with three tool slots.",
	},
	"warden": {
		"name": "Warden", "class": "Combat Frigate", "size": 2, "price": 75000, "buyable": true,
		"structure": 1600, "mass": 2300, "signature": 95, "cargo": 40,
		"slots": {"weapon": 4, "tool": 2, "optional": 5},
		"shape": "frigate", "length": 50,
		"desc": "Versatile combat frigate.",
	},
	"bastion": {
		"name": "Bastion", "class": "Heavy Cruiser", "size": 3, "price": 240000, "buyable": true,
		"structure": 4200, "mass": 6500, "signature": 220, "cargo": 120,
		"slots": {"weapon": 6, "tool": 4, "optional": 6},
		"shape": "cruiser", "length": 80,
		"desc": "Flagship class. Slow, but incredibly durable.",
	},
	# ---------------- Civilian NPC hulls (phase 0.5 package 11) ----------------
	"shuttle": {
		"name": "Skiff", "class": "Passenger Shuttle", "size": 1, "price": 6000, "buyable": false,
		"structure": 220, "mass": 380, "signature": 22, "cargo": 8,
		"slots": {"weapon": 0, "tool": 0, "optional": 1},
		"shape": "shuttle", "length": 20,
		"desc": "Planet-to-orbit shuttle carrying passengers and light freight.",
	},
	"freighter": {
		"name": "Longhaul", "class": "Bulk Freighter", "size": 3, "price": 180000, "buyable": false,
		"structure": 3200, "mass": 7200, "signature": 240, "cargo": 900,
		"slots": {"weapon": 1, "tool": 0, "optional": 4},
		"shape": "freighter", "length": 92,
		"desc": "Container freighter of the trade convoys. Slow, huge and a tempting prize.",
	},
}
