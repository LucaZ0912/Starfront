extends RefCounted
## Package 52 (Luz, 10 Nov 2026): who fights you on foot. Each kind wears a suit and carries a weapon from data/gear.gd
## (their layers – shield, armour, health – come from the suit, the damage from the weapon, both at the kind's
## quality); `firearms` and `athletics` are their skill levels (0–10 as the pilot's); `role` sets how the AI fights:
## rifleman (keeps its distance from cover), rusher (closes in to its short range), gunner (holds a spot and sprays),
## boss (steady, the others rally to it). `flee`: below this share of health it runs. `look`: cloth colours (indices
## into PilotArt.CLOTH) and helmet.

const FOES := {
	"bandit_scrapper": {"name": "Dust Rat Scrapper", "faction": "bandits", "suit": "suit_civil", "weapon": "wp_shotgun", "quality": "E",
		"firearms": 1, "athletics": 3, "role": "rusher", "flee": 0.25, "bounty": 120, "c1": 1, "c2": 9, "helmet": false,
		"desc": "Comes at you with a scatter gun – deadly close up, keep your distance."},
	"bandit_rifleman": {"name": "Dust Rat Rifleman", "faction": "bandits", "suit": "suit_work", "weapon": "wp_rifle", "quality": "E",
		"firearms": 2, "athletics": 1, "role": "rifleman", "flee": 0.2, "bounty": 150, "c1": 7, "c2": 8, "helmet": false,
		"desc": "Finds cover and shoots from afar with a rail carbine."},
	"bandit_gunner": {"name": "Dust Rat Gunner", "faction": "bandits", "suit": "suit_work", "weapon": "wp_smg", "quality": "D",
		"firearms": 1, "athletics": 1, "role": "gunner", "flee": 0.2, "bounty": 140, "c1": 0, "c2": 10, "helmet": false,
		"desc": "Holds a spot and sprays slugs at middle range."},
	"bandit_boss": {"name": "Dust Rat Boss", "faction": "bandits", "suit": "suit_mil_light", "weapon": "wp_laser_rifle", "quality": "D",
		"firearms": 4, "athletics": 2, "role": "boss", "flee": 0.0, "bounty": 400, "c1": 0, "c2": 8, "helmet": true,
		"desc": "Leads the gang from cover with a laser rifle and a real shield. Never runs."},
}
const KINDS := ["bandit_scrapper", "bandit_rifleman", "bandit_gunner", "bandit_boss"]

## Foes' shots hit for this share of their weapon's damage – a gang in the open must not drop you in seconds
## (three bandits on an unprotected pilot: about ten seconds; from cover much longer).
const DAMAGE := 0.3

## How far a foe sees you (art px, ~15 a metre) and hears a shot.
const SIGHT := 300.0
const HEAR := 420.0


## The weapon a kind carries, with its quality: "wp_rifle:E".
static func weapon_id(kind: String, quality: String = "") -> String:
	var d: Dictionary = FOES.get(kind, {})
	return "%s:%s" % [String(d.get("weapon", "wp_pistol")), quality if quality != "" else String(d.get("quality", "E"))]


static func suit_id(kind: String, quality: String = "") -> String:
	var d: Dictionary = FOES.get(kind, {})
	return "%s:%s" % [String(d.get("suit", "suit_civil")), quality if quality != "" else String(d.get("quality", "E"))]
