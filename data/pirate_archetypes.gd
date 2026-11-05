extends RefCounted
## Pirate archetypes (phase 0.5 package 14). Ordinary pirates stay loners but each one gets an AI
## role with its own behaviour and loadout. The Warrant Scanner reveals the archetype.
##   presets   loadouts by size class: [light (any system), medium (security < 0.6), heavy (< 0.3)]
##   weight    how common the archetype is
##   range     preferred combat distance as a fraction of the ship's optimal range
##   speed     speed factor while fighting (afterburner-like bursts of the AI)
##   hint      one line for the Warrant Scanner

const ARCHETYPES := {
	"raider": {
		"name": "Raider", "weight": 3.0, "range": 0.6, "speed": 1.25,
		"presets": ["pirate_raider_laser", "pirate_raider_hornet", "pirate_raider_hornet"],
		"hint": "Fast hit-and-run attacker – strikes, breaks off, comes back.",
	},
	"brawler": {
		"name": "Brawler", "weight": 2.0, "range": 0.3, "speed": 1.0,
		"presets": ["pirate_raider_rocket", "pirate_hornet", "pirate_brawler_warden"],
		"hint": "Heavily armoured, autocannons – closes in for a knife fight.",
	},
	"sniper": {
		"name": "Sniper", "weight": 2.0, "range": 0.95, "speed": 1.1,
		"presets": ["pirate_sniper_crow", "pirate_sniper_hornet", "pirate_warden"],
		"hint": "Keeps its distance with rockets or railguns and backs off when you close in.",
	},
	"ambusher": {
		"name": "Ambusher", "weight": 1.5, "range": 0.5, "speed": 1.15,
		"presets": ["pirate_ambusher_crow", "pirate_ambusher_hornet", "pirate_ambusher_hornet"],
		"hint": "Lies in wait in the rocks or in a colossus' radar shadow – its first volley hits hard.",
	},
	"leech": {
		"name": "Leech", "weight": 1.0, "range": 0.7, "speed": 1.0,
		"presets": ["pirate_leech_crow", "pirate_leech_hornet", "pirate_leech_warden"],
		"hint": "Ion weapons drain your shields and capacitor.",
	},
	"coward": {
		"name": "Coward", "weight": 1.5, "range": 0.85, "speed": 1.3,
		"presets": ["pirate_coward_crow", "pirate_coward_crow", "pirate_coward_hornet"],
		"hint": "Flees when hurt and calls its friends for help.",
	},
}

const AMBUSH_RANGE := 0.45      # ambushers only strike targets within this share of their sensor range
const AMBUSH_BONUS := 1.6       # damage multiplier for the ambusher's opening volleys …
const AMBUSH_TIME := 5.0        # … during the first seconds of the fight
const RAID_ATTACK := 7.0        # raiders press the attack this long …
const RAID_BREAK := 4.5         # … then break off this long
const COWARD_FLEE := 0.55       # cowards run below this share of armour + structure
const HELP_RANGE := 45000.0     # pirates that hear a coward's call


## Pirates fly worn-out copies of Hadrian Dynamics ships (never the Goliath), by size class.
const HDY_PIRATES := ["pirate_hdy_talon", "pirate_hdy_maul", "pirate_hdy_citadel"]
const HDY_SHARE := 0.2


## Random archetype + loadout for a system of security `sec`: [archetype, preset].
static func pick(sec: float) -> Array:
	var total := 0.0
	for a in ARCHETYPES:
		total += float(ARCHETYPES[a]["weight"])
	var roll := randf() * total
	var arch := "raider"
	for a in ARCHETYPES:
		roll -= float(ARCHETYPES[a]["weight"])
		if roll <= 0.0:
			arch = a
			break
	var tier := 0
	if sec < 0.6 and randf() < 0.5:
		tier = 1
	if sec < 0.3 and randf() < 0.35:
		tier = 2
	if randf() < HDY_SHARE:
		return [arch, HDY_PIRATES[tier]]           # a worn-out Hadrian copy (package 25d)
	return [arch, ARCHETYPES[arch]["presets"][tier]]


static func name_of(arch: String) -> String:
	return String(ARCHETYPES[arch]["name"]) if ARCHETYPES.has(arch) else "Pirate"
