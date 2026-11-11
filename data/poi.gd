extends RefCounted
## Package 53 (Luz, 11 Nov 2026): places of interest – sites to explore on foot, generated as dungeons. Two sorts:
## those found on the map (they come and go with your visits to a system: ruins to explore, later crash sites) and
## those a mission puts somewhere (package 53c). Each is made from a THEME (how it looks, who is there, what lies
## about) and – for missions – a mission template; the generator (scripts/ground/dungeon_gen.gd) lays out rooms and
## wide corridors (fights happen here too), gives the rooms their roles and sets the locks and the ways round them.
## A site is used up once its target is done. No class_name: preload it.

## A theme: its name and kinds of site, the floor kind of its rooms and corridors (GroundMap floor kinds), its colours
## (stone, wall, wall top, trim, accent, light), the foes in it (FoeData kinds), its cover props, its loot (belt
## items and credits), the names it gives its sites.
const THEMES := {
	"ruin": {"name": "Ancient ruin", "kind": "ruins", "room_floor": 2, "hall_floor": 2,
		"floor": Color(0.42, 0.38, 0.34), "floor2": Color(0.38, 0.34, 0.31), "wall": Color(0.52, 0.47, 0.41),
		"wall_top": Color(0.24, 0.21, 0.19), "trim": Color(0.33, 0.29, 0.25), "accent": Color(0.75, 0.55, 1.0),
		"light": Color(0.75, 0.6, 1.0),
		"foes": ["bandit_scrapper", "bandit_rifleman", "bandit_gunner"], "leader": "bandit_boss",
		"props": ["rock", "heap", "crates", "barrel"],
		"loot": ["cs_medkit", "cs_cell", "cs_ammo", "cs_breach", "gr_frag", "cs_o2", "gr_smoke"],
		"credits": [150, 600],
		"names_a": ["Kel", "Ath", "Vor", "Ush", "Tir", "Mae", "Oru", "Zan", "Ilo", "Quel"],
		"names_b": ["atha", "remn", "osh", "idra", "ukai", "erin", "amol", "esh", "ion", "uvar"]},
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
