extends RefCounted
## The megacorps. Every station service is run by one corporation that holds the
## sector-wide monopoly on it. Pure flavour for now – later they could get standings,
## price modifiers per station, rival factions, missions, etc.

const CORPS := {
	# package 28: the image studios – new looks for pilots
	"vsg": {
		"name": "Visage Clinics", "tag": "VSG", "color": Color(1.0, 0.55, 0.85),
		"slogan": "Be who you look like.",
		"desc": "Hair, skin, implants, tattoos, clothes – the Visage studios redo a pilot's whole look in an afternoon. What is under the skin stays yours.",
	},
	"hwd": {
		"name": "Hivewright Drone Works", "tag": "HWD", "color": Color(0.55, 1.0, 0.6),
		"slogan": "Many hands, one mind.",
		"desc": "Builds the autonomous drones of the Cluster and services them at every station. Their fuel cells are sealed – a drone flies until it is empty.",
	},
	"kvx": {
		"name": "Kessler-Vance Exchange", "tag": "KVX", "color": Color(1.0, 0.78, 0.25),
		"slogan": "Every price has a buyer.",
		"desc": "Owns every trade terminal from the core to the rim. If it changes hands, KVX takes a cut.",
	},
	"lnn": {
		"name": "Lumen Newsnet", "tag": "LNN", "color": Color(0.55, 0.9, 1.0),
		"slogan": "Everything worth knowing, first.",
		"desc": "Broadcasts the news of the Cluster over the gate datanet and keeps the archive at every station.",
	},
	"swx": {
		"name": "Sable Writ Exchange", "tag": "SWX", "color": Color(0.95, 0.85, 0.55),
		"slogan": "Every head has a price.",
		"desc": "Issues the bounty bonds of the system security authorities. A bond is paid only at a Bond Office in the system that issued it.",
	},
	"hoy": {
		"name": "Hadal Orbital Yards", "tag": "HOY", "color": Color(0.35, 0.8, 1.0),
		"slogan": "Hulls forged in the dark.",
		"desc": "Builds every licensed hull in the sector in zero-g foundries nobody is allowed to visit.",
	},
	"syn": {
		"name": "Synapse Armaments", "tag": "SYN", "color": Color(1.0, 0.3, 0.45),
		"slogan": "Upgrade or be upgraded.",
		"desc": "Weapons, plating, drives – if it bolts onto a ship, Synapse sells it.",
	},
	"cmc": {
		"name": "Crucible Metallurgy Combine", "tag": "CMC", "color": Color(1.0, 0.5, 0.15),
		"slogan": "We melt what you mine.",
		"desc": "Runs the refineries. Yield depends on the station's equipment – and on CMC's mood.",
	},
	"mlf": {
		"name": "Molten Lotus Fabrication", "tag": "MLF", "color": Color(0.9, 0.35, 1.0),
		"slogan": "From raw ore to raw power.",
		"desc": "Licensed fabricators that turn materials into modules – for a fee, of course.",
	},
	"blc": {
		"name": "BlackLedger Contracts", "tag": "BLC", "color": Color(0.4, 1.0, 0.55),
		"slogan": "No questions. Only payouts.",
		"desc": "The only legal broker for freelance work. The board never sleeps.",
	},
	"vlt": {
		"name": "Vaultline Storage", "tag": "VLT", "color": Color(0.75, 0.8, 0.9),
		"slogan": "Your ship. Our vault.",
		"desc": "Hangar space, ship custody and an insurance arm nobody reads the fine print of.",
	},
	"pyre": {
		"name": "Pyre Fuel Syndicate", "tag": "PYRE", "color": Color(1.0, 0.4, 0.2),
		"slogan": "Burn bright. Pay later.",
		"desc": "Controls every deuterium line in the sector. Prices are 'market-driven'.",
	},
	"mdx": {
		"name": "Mendex Nanorepair", "tag": "MDX", "color": Color(0.3, 1.0, 0.85),
		"slogan": "Billions of tiny hands.",
		"desc": "Nanite swarms that patch hulls and armour. Swarm loyalty not guaranteed.",
	},
	"aegis": {
		"name": "Aegis Mutual", "tag": "AEG", "color": Color(0.6, 0.7, 1.0),
		"slogan": "We'll be there. Eventually.",
		"desc": "Ship insurance. Pays out a basic corvette when your fleet is gone.",
	},
}
