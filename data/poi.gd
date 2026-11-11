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
const THEMES := {
	"precursor": {"name": "Ruin of the Precursors", "kind": "ruins", "style": "precursor", "room_floor": 17, "hall_floor": 17,
		"floor": Color(0.34, 0.25, 0.19), "floor2": Color(0.3, 0.22, 0.17), "wall": Color(0.44, 0.3, 0.21),
		"wall_top": Color(0.17, 0.13, 0.11), "trim": Color(0.3, 0.21, 0.15), "accent": Color(0.7, 0.5, 1.0),
		"light": Color(0.7, 0.55, 1.0),
		"door": "rust_door", "computer": "precursor",
		"foes": ["bandit_scrapper", "bandit_rifleman", "bandit_gunner"], "leader": "bandit_boss",
		"props": ["pillar_fallen", "pillar_fallen", "slab", "rock"],
		"guard": "crystals", "traps": "emp", "fog": true,
		"loot": ["cs_medkit", "cs_cell", "cs_breach", "cs_ammo"],
		"credits": [80, 300], "research": [3, 8], "museum_chance": 0.12,
		"names_a": ["Kel", "Ath", "Vor", "Ush", "Tir", "Mae", "Oru", "Zan", "Ilo", "Quel"],
		"names_b": ["atha", "remn", "osh", "idra", "ukai", "erin", "amol", "esh", "ion", "uvar"]},
}

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
	"green": {"name": "green (easy)", "tiers": ["green", "green", "green"], "guards": [2, 3], "leader": "green"},
	"yellow": {"name": "yellow (middling)", "tiers": ["green", "yellow", "yellow"], "guards": [2, 4], "leader": "yellow"},
	"red": {"name": "red (dangerous)", "tiers": ["yellow", "red", "red"], "guards": [3, 4], "leader": "red"},
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
}


static func site_name(theme: String, rng: RandomNumberGenerator) -> String:
	var th: Dictionary = THEMES[theme]
	var a: String = th["names_a"][rng.randi() % th["names_a"].size()]
	var b: String = th["names_b"][rng.randi() % th["names_b"].size()]
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
