extends RefCounted
## Package 53 (Luz, 11 Nov 2026): places of interest – sites to explore on foot, generated as dungeons. Two sorts:
## those found on the map (they come and go with your visits to a system: ruins to explore, later crash sites) and
## those a mission puts somewhere (package 53c). Each is made from a THEME (how it looks, who is there, what lies
## about) and – for missions – a mission template; the generator (scripts/ground/dungeon_gen.gd) lays out rooms and
## wide corridors (fights happen here too), gives the rooms their roles and sets the locks and the ways round them.
## A site is used up once its target is done. No class_name: preload it.

## A theme (0.7.53.2, Luz's points – Roadmap "Paket 53 – Einstieg und Dungeon-Themen"): its name and kind of site, its
## `style` (how GroundMap draws its walls, floors and facade), the floor kind of its rooms, its colours, its doors and
## computers (explore kinds / styles), the foes in it, its cover props, its extras, its loot (belt items, credits,
## research data, the chance of a museum relic), its traps, its feeling (fog), the names it gives its sites.
## 0.7.53.3 (Luz): its STRUCTURE – rolled anew for every site, Mystery-Dungeon-like: the grid of cells (cols, rows –
## ranges), the rooms' sizes, how many cells hold a room (the rest are junctions where the ways cross), the width of
## the ways, extra loops, the cover per room; its `outside` ("ruin": a facade on the body's ground, "alley": a back
## alley of a city); its LAYERS – one per level, each may change any of the theme's keys (the sewer above, the dealer's
## hideout below). The last layer holds the target (`target`: "relic" or "dealer").
const MuseumData = preload("res://data/museum.gd")
const THEMES := {
	"precursor": {"name": "Ruin of the Precursors", "kind": "ruins", "style": "precursor", "room_floor": 17, "hall_floor": 17,
		"floor": Color(0.34, 0.25, 0.19), "floor2": Color(0.3, 0.22, 0.17), "wall": Color(0.44, 0.3, 0.21),
		"wall_top": Color(0.17, 0.13, 0.11), "trim": Color(0.3, 0.21, 0.15), "accent": Color(0.7, 0.5, 1.0),
		"light": Color(0.7, 0.55, 1.0),
		"door": "rust_door", "computer": "precursor",
		"foes": ["bandit_scrapper", "bandit_rifleman", "bandit_gunner"], "leader": "bandit_boss",
		"props": ["pillar_fallen", "pillar_fallen", "slab", "rock"],
		"guard": "crystals", "traps": "emp", "fog": true, "outside": "ruin", "target": "relic", "tablets": 3, "vent": true,
		"cols": [3, 4], "rows": [3, 3], "cell_w": 22, "cell_h": 17, "room_w": [10, 16], "room_h": [7, 10], "room_chance": 0.9,
		"corr": 3, "loops": [1, 3], "cover": [3, 5], "layers": [{}, {}], "descent": "lift", "stores": [2, 2],
		"loot": ["cs_medkit", "cs_cell", "cs_breach", "cs_ammo"],
		"credits": [80, 300], "research": [3, 8], "museum_chance": 0.12,
		"names_a": ["Kel", "Ath", "Vor", "Ush", "Tir", "Mae", "Oru", "Zan", "Ilo", "Quel"],
		"names_b": ["atha", "remn", "osh", "idra", "ukai", "erin", "amol", "esh", "ion", "uvar"]},
	# 0.7.53.6 (Luz, package 53b): a crash site – a real ship of the game, come down; long main corridors along its
	# hull, many small cabins, two decks (the floor gave way between them)
	"wreck": {"name": "Crash site", "kind": "crash", "style": "ship", "room_floor": 24, "hall_floor": 24,
		"floor": Color(0.33, 0.34, 0.36), "floor2": Color(0.29, 0.3, 0.32), "wall": Color(0.42, 0.43, 0.46),
		"wall_top": Color(0.07, 0.07, 0.08), "trim": Color(0.2, 0.2, 0.22), "accent": Color(1.0, 0.3, 0.2),
		"light": Color(1.0, 0.3, 0.22),
		"door": "bulkhead", "computer": "ship",
		"foes": ["bandit_scrapper", "bandit_rifleman", "bandit_gunner"], "leader": "bandit_boss",
		"props": ["locker_down", "crates", "seats", "barrel", "locker_down", "seats"],
		"guard": "", "traps": "shock", "fog": false, "dark": Color(0.78, 0.55, 0.52), "outside": "wreck", "target": "blackbox",
		"tablets": 0, "vent": false, "descent": "hole", "spine": true, "stores": [1, 2],
		"cols": [4, 6], "rows": [2, 2], "cell_w": 16, "cell_h": 14, "room_w": [6, 10], "room_h": [5, 7], "room_chance": 0.85,
		"corr": 3, "loops": [0, 0], "cover": [2, 4],
		"loot": ["cs_medkit", "cs_cell", "cs_ammo", "cs_breach"],
		"credits": [150, 420], "research": [0, 2], "museum_chance": 0.15,
		"names_a": ["Iron", "Long", "Far", "Grey", "Red", "Quiet", "Last", "Brave"],
		"names_b": ["Meridian", "Horizon", "Promise", "Tally", "Comet", "Harvest", "Wanderer", "Lantern"],
		"hulls": ["freighter", "mule", "warden", "bastion", "hdy_goliath", "aur_boulevard", "hdy_maul", "iwakudaki"],
		"layers": [{}, {}]},
	# 0.7.53.11 (Luz, package 53c): a pirate base built into a cliff – the Red Talons: halls cut into the rock with
	# modules welded in, a hangar with a fighter standing in it, barracks, stores, the command room, cells
	"pirate": {"name": "Pirate base", "kind": "pirate", "style": "pirate", "room_floor": 22, "hall_floor": 22,
		"floor": Color(0.29, 0.28, 0.29), "floor2": Color(0.25, 0.24, 0.25), "wall": Color(0.36, 0.3, 0.27),
		"wall_top": Color(0.08, 0.07, 0.07), "trim": Color(0.4, 0.4, 0.42), "accent": Color(1.0, 0.25, 0.2),
		"light": Color(1.0, 0.3, 0.22),
		"door": "steel_door", "computer": "",
		"foes": ["pirate_raider", "pirate_gunner", "pirate_grenadier", "pirate_raider", "pirate_sniper"], "leader": "pirate_captain",
		"props": ["crates", "barrel", "barrier", "fire_barrel", "crates"],
		"guard": "", "traps": "tripwire", "fog": false, "dark": Color(0.78, 0.62, 0.6), "outside": "cliff", "target": "loot_room",
		"turret": true, "alarm": true, "hangar": true, "cells": true,
		"tablets": 0, "vent": false, "descent": "ramp", "stores": [1, 2],
		"cols": [3, 3], "rows": [2, 3], "cell_w": 26, "cell_h": 18, "room_w": [9, 14], "room_h": [7, 10], "room_chance": 0.95,
		"corr": 3, "loops": [1, 2], "cover": [3, 5],
		"loot": ["cs_ammo", "cs_medkit", "cs_cell", "gr_frag", "cs_breach"],
		"credits": [200, 520], "research": [0, 0], "museum_chance": 0.0,
		"names_a": ["Red", "Black", "Talon", "Rust", "Gallows", "Skull", "Broken"],
		"names_b": ["Roost", "Nest", "Rock", "Hold", "Den", "Crag", "Perch"],
		"layers": [{}, {"hangar": false}]},
	# 0.7.53.9 (Luz, package 53c): the maintenance tunnels under a city – the power is out; down three levels to the
	# reactor and start it again. Pipes and lines everywhere; the maintenance drones mend things (and leave you be)
	"maint": {"name": "Maintenance tunnels", "kind": "maint", "style": "maint", "room_floor": 21, "hall_floor": 19,
		"floor": Color(0.3, 0.31, 0.3), "floor2": Color(0.26, 0.27, 0.26), "wall": Color(0.37, 0.37, 0.36),
		"wall_top": Color(0.08, 0.08, 0.09), "trim": Color(0.85, 0.7, 0.15), "accent": Color(1.0, 0.25, 0.2),
		"light": Color(1.0, 0.25, 0.2),
		"door": "crank_door", "computer": "pump",
		"foes": ["maint_drone"], "leader": "", "passive_foes": true,
		"props": ["pipe_bundle", "pipe_bundle", "valve_box", "cable_drum", "barrel"],
		"guard": "", "traps": "steam", "fog": false, "dark": Color(0.5, 0.38, 0.37), "outside": "lift", "target": "reactor",
		"tablets": 0, "vent": false, "descent": "stairs", "stores": [1, 1],
		"cols": [3, 4], "rows": [2, 3], "cell_w": 18, "cell_h": 15, "room_w": [8, 11], "room_h": [6, 8], "room_chance": 0.7,
		"corr": 3, "loops": [1, 2], "cover": [3, 5],
		"loot": ["cs_cell", "cs_medkit", "cs_breach"],
		"credits": [60, 180], "research": [0, 0], "museum_chance": 0.0,
		"names_a": ["Sector", "Service", "Utility", "Grid", "Line"],
		"names_b": ["Seven", "Nine", "Twelve", "East", "West", "Deep", "Old"],
		"layers": [{}, {}, {}]},
	# 0.7.53.7 (Luz, package 53b): a settlement's way down – the old mine under its headframe: crooked, branching drifts,
	# a few bigger chambers, the cage down to the deeper level; rare finds for the Museum
	"mine": {"name": "Old mine", "kind": "mine_old", "style": "mine", "room_floor": 25, "hall_floor": 25,
		"floor": Color(0.36, 0.31, 0.26), "floor2": Color(0.31, 0.27, 0.22), "wall": Color(0.34, 0.28, 0.22),
		"wall_top": Color(0.09, 0.08, 0.07), "trim": Color(0.42, 0.3, 0.17), "accent": Color(1.0, 0.75, 0.4),
		"light": Color(1.0, 0.75, 0.4),
		"door": "grate_door", "computer": "pump",
		"foes": ["bandit_scrapper", "bandit_rifleman", "bandit_gunner"], "leader": "bandit_boss",
		"props": ["ore_cart", "heap", "crates", "barrel", "heap"],
		"guard": "", "traps": "mine", "fog": false, "dark": Color(0.62, 0.55, 0.48), "outside": "minehead", "target": "find",
		"tablets": 0, "vent": false, "descent": "cage", "rails": true, "rubble": true, "stores": [1, 2],
		"cols": [4, 5], "rows": [3, 3], "cell_w": 18, "cell_h": 15, "room_w": [9, 13], "room_h": [6, 8], "room_chance": 0.4,
		"corr": 3, "loops": [1, 2], "cover": [3, 5],
		"loot": ["cs_medkit", "cs_cell", "cs_ammo", "gr_frag"],
		"credits": [100, 320], "research": [0, 2], "museum_chance": 0.18,
		"names_a": ["Old", "Deep", "Lower", "North", "Black", "Rust", "Long", "Blind"],
		"names_b": ["Shaft", "Seam", "Drift", "Pit", "Lode", "Vein", "Gallery", "Level"],
		"layers": [{}, {}]},
	# 0.7.53.19 (Luz, package 53d): a corporate tower in a city – up the lift to a roof plaza, in by the back door of the
	# office tower: the lobby and the open-plan offices (pale stone, carpet, glass), the security level below (the
	# security centre – cameras and light barriers off – the servers), the vault at the bottom (light barriers, the round
	# vault door: hacked, then drilled). The lifts want a key card; the fire stairs ring the alarm.
	"corp": {"name": "Corporate tower", "kind": "corp", "style": "corp", "room_floor": 28, "hall_floor": 28,
		"floor": Color(0.8, 0.79, 0.76), "floor2": Color(0.74, 0.73, 0.7), "wall": Color(0.84, 0.85, 0.87),
		"wall_top": Color(0.1, 0.1, 0.12), "trim": Color(0.55, 0.57, 0.6), "accent": Color(0.95, 0.75, 0.3),
		"light": Color(0.95, 0.97, 1.0),
		"door": "glass_door", "computer": "corp",
		"foes": ["corp_guard", "corp_guard", "corp_marksman"], "leader": "corp_chief",
		"props": ["office_desk", "planter", "pillar_corp", "sofa", "office_desk", "partition"],
		"guard": "", "traps": "beams", "fog": false, "dark": Color(0.9, 0.92, 0.96), "outside": "plaza", "target": "corp_vault",
		"alarm": true, "cams": [2, 3], "keycard": true, "carpet_share": 0.55, "patrols": [1, 2], "reinforce": true,
		"tablets": 0, "vent": false, "descent": "keylift", "stores": [1, 2],
		"cols": [3, 4], "rows": [2, 3], "cell_w": 20, "cell_h": 15, "room_w": [9, 13], "room_h": [6, 9], "room_chance": 0.95,
		"corr": 3, "loops": [1, 2], "cover": [4, 6],
		"loot": ["cs_medkit", "cs_cell", "cs_breach", "cs_ammo"],
		"credits": [250, 600], "research": [2, 6], "museum_chance": 0.0,
		"names_a": ["Orison", "Halcyon", "Vantis", "Meridian", "Aurelian", "Kestrel", "Solace", "Argent"],
		"names_b": ["Holdings", "Dynamics", "Capital", "Systems", "Group", "Trust"],
		"layers": [{},
			{"room_floor": 29, "hall_floor": 28, "security": true, "carpet_share": 0.0, "props": ["server_rack", "office_desk", "partition", "server_rack", "planter"],
				"cams": [3, 4], "keycard": false},
			{"room_floor": 21, "hall_floor": 21, "floor": Color(0.42, 0.43, 0.45), "floor2": Color(0.38, 0.39, 0.41),
				"wall": Color(0.5, 0.51, 0.53), "trim": Color(0.35, 0.36, 0.38), "door": "vault_door", "keycard": false, "carpet_share": 0.0,
				"props": ["server_rack", "barrier", "crates", "pillar_corp"], "cams": [2, 3], "beams": true, "dark": Color(0.8, 0.84, 0.9)}]},
	# 0.7.53.23 (Luz, package 53d): a ruin of the Dark Ones – rare, far out (the Far Reaches, near the Veil). Grown
	# rather than built: black glassy stone, veins of violet light, round chambers, ways that wind like veins; doors
	# of membrane that open to symbols touched in the right order (a monolith's vision tells it); a maw in the floor
	# down; at the bottom a vast pit – something sleeps there. Empty as a site; a job finds cultists in it.
	"darkones": {"name": "Ruin of the Dark Ones", "kind": "darkruin", "style": "darkones", "room_floor": 33, "hall_floor": 33,
		"floor": Color(0.25, 0.22, 0.28), "floor2": Color(0.21, 0.19, 0.24), "wall": Color(0.12, 0.1, 0.15),
		"wall_top": Color(0.04, 0.03, 0.06), "trim": Color(0.3, 0.18, 0.4), "accent": Color(0.62, 0.35, 1.0),
		"light": Color(0.62, 0.35, 1.0),
		"door": "membrane", "computer": "monolith",
		"foes": [], "leader": "", "cult_foes": ["cultist", "cultist", "cult_zealot"], "cult_leader": "cult_priest",
		"props": ["obelisk", "bones", "altar", "obelisk_stand", "obelisk"],
		"guard": "", "traps": "glyphs", "fog": true, "dark": Color(0.5, 0.46, 0.6), "outside": "ruin", "target": "dark_relic",
		"round_rooms": true, "gate_lock": "symbols",
		"tablets": 0, "vent": false, "descent": "maw", "stores": [1, 1],
		"cols": [3, 4], "rows": [3, 3], "cell_w": 21, "cell_h": 16, "room_w": [9, 14], "room_h": [7, 10], "room_chance": 0.55,
		"corr": 3, "loops": [1, 3], "cover": [2, 4],
		"loot": ["cs_medkit", "cs_cell", "cs_breach"],
		"credits": [60, 220], "research": [8, 16], "museum_chance": 0.25,
		"names_a": ["The Hollow", "The Silent", "The Drowned", "The Coiled", "The Black", "The Sleeping"],
		"names_b": ["Choir", "Spire", "Throat", "Vault", "Maw", "Cathedral"],
		"layers": [{}, {}, {}]},
	# 0.7.53.20 (Luz, package 53d): a research station on a harsh world – white modules on stilts joined by long narrow
	# tubes; labs, quarters, stores; looters have taken it. Some modules are torn open: no air, no warmth (the world
	# outside comes in – the suit draws on its energy) until their emergency bulkhead is sealed. The research computer
	# with its logs below, in the sample store.
	"research": {"name": "Research station", "kind": "research_st", "style": "research", "room_floor": 31, "hall_floor": 32,
		"floor": Color(0.3, 0.31, 0.33), "floor2": Color(0.27, 0.28, 0.3), "wall": Color(0.88, 0.89, 0.91),
		"wall_top": Color(0.1, 0.11, 0.13), "trim": Color(0.95, 0.45, 0.2), "accent": Color(0.4, 0.85, 1.0),
		"light": Color(0.85, 0.95, 1.0),
		"door": "bulkhead", "computer": "",
		"foes": ["bandit_scrapper", "bandit_rifleman", "bandit_gunner"], "leader": "bandit_boss",
		"props": ["lab_bench", "cryo_tank", "crates", "sample_cabinet", "lab_bench"],
		"guard": "", "traps": "lab", "fog": false, "dark": Color(0.82, 0.86, 0.92), "outside": "station", "target": "research_logs",
		"pressurized": true, "leaks": [1, 1], "cells": true,
		"tablets": 0, "vent": false, "descent": "hatch", "stores": [1, 2],
		"cols": [3, 4], "rows": [2, 3], "cell_w": 20, "cell_h": 14, "room_w": [8, 12], "room_h": [6, 8], "room_chance": 0.85,
		"corr": 2, "loops": [1, 2], "cover": [3, 5],
		"loot": ["cs_medkit", "cs_cell", "cs_ammo", "cs_breach"],
		"credits": [120, 360], "research": [6, 14], "museum_chance": 0.0,
		"names_a": ["Frost", "Polar", "Deep", "Far", "Cold", "High", "Long", "Quiet"],
		"names_b": ["Point", "Reach", "Watch", "Station", "Outlook", "Field", "Camp", "Base"],
		"layers": [{}, {"room_floor": 21, "props": ["sample_cabinet", "crates", "cryo_tank", "crates"], "leaks": [0, 1]}]},
	# 0.7.53.3 (Luz, package 53b): the way down from a city – the sewers, and deep in them an arms dealer's hideout
	"sewer": {"name": "Sewers and a dealer's hideout", "kind": "sewer", "style": "sewer", "room_floor": 21, "hall_floor": 19,
		"floor": Color(0.3, 0.31, 0.3), "floor2": Color(0.26, 0.27, 0.26), "wall": Color(0.38, 0.39, 0.37),
		"wall_top": Color(0.08, 0.08, 0.09), "trim": Color(0.24, 0.3, 0.2), "accent": Color(0.4, 1.0, 0.5),
		"light": Color(1.0, 0.82, 0.55),
		"door": "grate_door", "computer": "pump",
		"foes": ["bandit_scrapper", "bandit_rifleman", "bandit_gunner"], "leader": "bandit_boss",
		"props": ["pipe_bundle", "heap", "barrel", "pump", "pipe_bundle"],
		"guard": "", "traps": "tripwire", "fog": false, "dark": Color(0.5, 0.55, 0.58), "outside": "alley", "target": "dealer",
		"cols": [4, 5], "rows": [2, 3], "cell_w": 20, "cell_h": 16, "room_w": [8, 11], "room_h": [6, 8], "room_chance": 0.35,
		"corr": 7, "canal": true, "loops": [1, 2], "cover": [2, 4], "flood": true, "descent": "hatch",
		"loot": ["cs_medkit", "cs_cell", "cs_ammo", "cs_breach"],
		"credits": [120, 380], "research": [0, 0], "museum_chance": 0.0,
		"names_a": ["Old", "Low", "Deep", "Drain", "Gut", "Rat", "Grey", "Under"],
		"names_b": ["Main", "Runoff", "Pipes", "Culvert", "Sump", "Outfall", "Cistern", "Spillway"],
		"layers": [{},
			{"style": "hideout", "room_floor": 22, "hall_floor": 22, "floor": Color(0.3, 0.3, 0.31), "floor2": Color(0.27, 0.26, 0.26),
				"wall": Color(0.36, 0.37, 0.39), "wall_top": Color(0.08, 0.08, 0.09), "trim": Color(0.22, 0.22, 0.24), "accent": Color(1.0, 0.7, 0.35),
				"light": Color(1.0, 0.75, 0.45), "door": "steel_door", "computer": "dealer", "dark": Color(0.72, 0.66, 0.62),
				"props": ["weapon_crate", "crates", "barrel", "weapon_crate", "barrier"], "canal": false, "flood": false,
				"cols": [3, 4], "rows": [2, 3], "cell_w": 17, "cell_h": 14, "room_w": [8, 11], "room_h": [6, 8], "room_chance": 1.0,
				"corr": 3, "loops": [1, 2], "cover": [3, 5], "turret": true, "alarm": true,
				"loot": ["cs_ammo", "cs_ammo", "cs_medkit", "cs_cell", "cs_breach"]}]},
}


## A theme as it is on one level (0 the top): the theme's keys with the level's own on top.
static func layer(theme: String, depth: int) -> Dictionary:
	var th: Dictionary = THEMES.get(theme, THEMES["precursor"])
	var ls: Array = th.get("layers", [{}])
	var out := th.duplicate()
	out.merge(ls[clampi(depth, 0, ls.size() - 1)], true)
	return out


## How many levels a theme's sites go down.
static func levels(theme: String) -> int:
	return (THEMES.get(theme, THEMES["precursor"]).get("layers", [{}]) as Array).size()

## 0.7.53.2 (Luz): rare relics of the two vanished alien kinds – found in ruins, shown in the Museum (package 53e).
## 0.7.53.7 (Luz): and special mining finds from the old mines.
## The danger of a site: the tiers of its foes (FoeData.TIERS), how many in a guard room, the leader's tier.
const DANGER := {
	"green": {"name": "green (easy)", "tiers": ["green", "green", "green"], "guards": [2, 3], "leader": "green", "cap": 8},
	"yellow": {"name": "yellow (middling)", "tiers": ["green", "yellow", "yellow"], "guards": [2, 4], "leader": "yellow", "cap": 11},
	"red": {"name": "red (dangerous)", "tiers": ["yellow", "red", "red"], "guards": [3, 4], "leader": "red", "cap": 14},
}

## How many sites a visit to a system may show: a chance per body you can land on.
const MAP_CHANCE := 0.35

## A target in a site, shown in the "possible targets" window: its colour, what it needs, what it gives.
const TARGETS := {
	"relic": {"col": Color(0.8, 0.5, 1.0), "needs": "scanner · cutting torch or E-Breach (or the air shaft)", "gives": "the site's prize: research data – rarely one of the alien relics (Museum)"},
	"tablets": {"col": Color(0.6, 0.85, 1.0), "needs": "scanner", "gives": "research data, the site's story"},
	"caches": {"col": Color(1.0, 0.8, 0.3), "needs": "cutting torch for the welded ones", "gives": "credits, supplies, gear"},
	"core": {"col": Color(0.3, 1.0, 0.6), "needs": "E-Breach", "gives": "research data – and it can open the sealed door"},
	"foes": {"col": Color(1.0, 0.45, 0.35), "needs": "fight or sneak", "gives": "they are after the prize too"},
	"dealer": {"col": Color(1.0, 0.7, 0.35), "needs": "E-Breach on the dealer's computer · the code door (its lock or a hack)", "gives": "the client list – credits now, bounties later"},
	"water": {"col": Color(0.4, 0.8, 0.9), "needs": "a valve wheel or the pump control (E-Breach)", "gives": "a flooded way runs dry"},
	"stash": {"col": Color(1.0, 0.8, 0.3), "needs": "cutting torch for the safe", "gives": "weapons, ammunition, credits"},
	"turret": {"col": Color(1.0, 0.35, 0.3), "needs": "E-Breach on the control room's computer · an EMP grenade stuns it", "gives": "a way into the office that does not cut you down"},
	"alarm": {"col": Color(1.0, 0.25, 0.2), "needs": "cutting torch on its box – before it rings", "gives": "no reinforcements"},
	"blackbox": {"col": Color(1.0, 0.6, 0.2), "needs": "get to it – on the lower deck, behind a jammed bulkhead (emergency power or its box)", "gives": "the flight recorder – a reward from its owners"},
	"power": {"col": Color(1.0, 0.85, 0.3), "needs": "the emergency generator – choose where its power goes", "gives": "the bulkheads open – or the lights come back"},
	"find": {"col": Color(0.95, 0.85, 0.4), "needs": "get to the deepest chamber (its gate: the box beside it, or the old control) · cutting torch to cut it out", "gives": "a rare find for the Museum"},
	"cage": {"col": Color(1.0, 0.75, 0.4), "needs": "power – start the generator", "gives": "the cage down to the deeper level"},
	"rubble": {"col": Color(0.7, 0.6, 0.5), "needs": "a frag grenade as a charge – or a box of explosives nearby", "gives": "a buried side chamber – its cache"},
	"loot_room": {"col": Color(1.0, 0.75, 0.3), "needs": "past the guards – the captain's hoard behind a code door (the command room opens it)", "gives": "the Red Talons' loot – credits, weapons, bounty data"},
	"hangar": {"col": Color(0.6, 0.8, 1.0), "needs": "–", "gives": "a fighter standing in the hangar – good cover"},
	"cells": {"col": Color(0.8, 0.8, 0.8), "needs": "–", "gives": "prisoners – a rescue mission, later"},
	"reactor": {"col": Color(0.5, 0.9, 1.0), "needs": "down to the lowest level · E-Breach on the reactor's panel", "gives": "the power back – level by level the lights come on"},
	"lift": {"col": Color(0.7, 0.5, 1.0), "needs": "E-Breach on their computer, or the cutting torch on a crystal panel", "gives": "the way down to the deeper level"},
	"corp_vault": {"col": Color(0.95, 0.75, 0.3), "needs": "down to the bottom (key card or the fire stairs) · E-Breach on the vault's lock, then hold out while the drill bites", "gives": "the vault – money, company data, rare parts"},
	"cameras": {"col": Color(1.0, 0.35, 0.3), "needs": "keep out of their view – or switch them off in the security centre", "gives": "no alarm"},
	"beams": {"col": Color(1.0, 0.2, 0.15), "needs": "do not cross them – the security centre switches them off", "gives": "no alarm"},
	"keycard": {"col": Color(0.4, 0.85, 1.0), "needs": "find it – in an office", "gives": "the lifts down"},
	"stairs": {"col": Color(1.0, 0.45, 0.35), "needs": "–", "gives": "a quick way down – but its door rings the alarm"},
	"dark_relic": {"col": Color(0.62, 0.35, 1.0), "needs": "down to the bottom · the symbols of the membrane (a monolith's vision tells their order) · a scanner", "gives": "a relic of the Dark Ones – for the Museum"},
	"monolith": {"col": Color(0.62, 0.35, 1.0), "needs": "a scanner", "gives": "a vision – the order of the symbols; research data"},
	"hidden": {"col": Color(0.95, 0.8, 0.4), "needs": "scan the tablets or the monolith – they tell where · a cutting torch", "gives": "a hidden cache – more credits, likely a find for the Museum"},
	"glyphs": {"col": Color(0.8, 0.5, 1.0), "needs": "step around them", "gives": "a wave of force if you do not"},
	"sleeper": {"col": Color(0.5, 0.3, 0.7), "needs": "–", "gives": "something sleeps at the bottom"},
	"research_logs": {"col": Color(0.4, 0.85, 1.0), "needs": "down to the sample store · E-Breach on the research computer", "gives": "the station's research logs – a lot of research data"},
	"leak": {"col": Color(0.6, 0.85, 1.0), "needs": "seal its emergency bulkhead (the panel by it)", "gives": "air and warmth back in that module"},
	"shelter": {"col": Color(0.8, 0.8, 0.8), "needs": "–", "gives": "people sealed into a cold store – a rescue, maybe"},
	"security": {"col": Color(0.4, 1.0, 0.6), "needs": "E-Breach on its computer", "gives": "cameras and light barriers off – and the company's data"},
}


static func site_name(theme: String, rng: RandomNumberGenerator) -> String:
	var th: Dictionary = THEMES[theme]
	var a: String = th["names_a"][rng.randi() % th["names_a"].size()]
	var b: String = th["names_b"][rng.randi() % th["names_b"].size()]
	if String(th["kind"]) == "sewer":
		return "%s %s" % [a, b]
	if String(th["kind"]) == "pirate":
		return "%s %s" % [a, b]
	if String(th["kind"]) == "maint":
		return "%s %s" % [a, b]
	if String(th["kind"]) == "mine_old":
		return "The %s %s" % [a, b]
	if String(th["kind"]) == "corp":
		return "%s %s Tower" % [a, b]
	if String(th["kind"]) == "darkruin":
		return "%s %s" % [a, b]
	if String(th["kind"]) == "research_st":
		return "%s %s" % [a, b]
	if String(th["kind"]) == "crash":
		return "Wreck of the %s %s" % [a, b]
	return "%s of %s-%s" % ["Ruin" if String(th["kind"]) == "ruins" else "Site", a, b.capitalize()]


## 53e: a find for the Museum from a site of a theme by a roll (or "" none) – an exhibit of the room the theme yields
## (data/museum.gd), its rarity weighed; the tablets come from scans, not caches.
static func museum_roll(theme: String, rng: RandomNumberGenerator, veil: bool = false) -> String:
	var th: Dictionary = THEMES.get(theme, {})
	if rng.randf() >= float(th.get("museum_chance", 0.0)):
		return ""
	return museum_pick(theme, rng, veil)


## 53e: an exhibit of the room a theme yields, for certain ("" if the theme yields none).
static func museum_pick(theme: String, rng: RandomNumberGenerator, veil: bool = false) -> String:
	var room := MuseumData.room_for_theme(theme, veil)
	if room == "":
		return ""
	return MuseumData.roll_kind(room, rng, 0, 2.0 if room == "minerals" and GameState.museum_perk("minerals") else 1.0)


static func museum_name(id: String) -> String:
	return MuseumData.exhibit_name(id)
