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
		"credits": [150, 420], "research": [0, 2], "museum_chance": 0.0,
		"names_a": ["Iron", "Long", "Far", "Grey", "Red", "Quiet", "Last", "Brave"],
		"names_b": ["Meridian", "Horizon", "Promise", "Tally", "Comet", "Harvest", "Wanderer", "Lantern"],
		"hulls": ["freighter", "mule", "warden", "bastion", "hdy_goliath", "aur_boulevard", "hdy_maul", "iwakudaki"],
		"layers": [{}, {}]},
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
const MUSEUM_RELICS := {
	"precursor": [["pr_lens", "Precursor Lens", "A disc of fused crystal that bends light into words nobody reads."],
		["pr_key", "Precursor Key-Rod", "A rod of rusted iron and living crystal – it hums near their doors."],
		["pr_mask", "Precursor Mask", "A face, or what they thought a face should be."],
		["pr_core", "Precursor Heart-Core", "Warm to the touch after an age in the dark."],
		["pr_map", "Precursor Star Plate", "Stars engraved in iron – some of them are not there any more."],
		["pr_idol", "Precursor Figurine", "Small, many-limbed, worn smooth by hands."]],
}


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
	"lift": {"col": Color(0.7, 0.5, 1.0), "needs": "E-Breach on their computer, or the cutting torch on a crystal panel", "gives": "the way down to the deeper level"},
}


static func site_name(theme: String, rng: RandomNumberGenerator) -> String:
	var th: Dictionary = THEMES[theme]
	var a: String = th["names_a"][rng.randi() % th["names_a"].size()]
	var b: String = th["names_b"][rng.randi() % th["names_b"].size()]
	if String(th["kind"]) == "sewer":
		return "%s %s" % [a, b]
	if String(th["kind"]) == "crash":
		return "Wreck of the %s %s" % [a, b]
	return "%s of %s-%s" % ["Ruin" if String(th["kind"]) == "ruins" else "Site", a, b.capitalize()]


## A museum relic of a theme by a roll (or "" none).
static func museum_roll(theme: String, rng: RandomNumberGenerator) -> String:
	var th: Dictionary = THEMES.get(theme, {})
	var list: Array = MUSEUM_RELICS.get(theme, [])
	if list.is_empty() or rng.randf() >= float(th.get("museum_chance", 0.0)):
		return ""
	return String(list[rng.randi() % list.size()][0])


static func museum_name(id: String) -> String:
	for th in MUSEUM_RELICS:
		for r in MUSEUM_RELICS[th]:
			if String(r[0]) == id:
				return String(r[1])
	return id
