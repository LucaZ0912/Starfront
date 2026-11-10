extends RefCounted
## Package 52 (Luz, 10 Nov 2026): who fights you on foot. Each kind wears a suit and carries a weapon from data/gear.gd
## (their layers – shield, armour, health – come from the suit, the damage from the weapon, both at the kind's
## quality); `firearms` and `athletics` are their skill levels (0–10 as the pilot's); `role` sets how the AI fights:
## rifleman (keeps its distance from cover), rusher (closes in to its short range), gunner (holds a spot and sprays),
## boss (steady, the others rally to it). `health`: their bodies (0.7.52.3: less than the pilot's). `flee`: below this share of health it runs. `look`: cloth colours (indices
## into PilotArt.CLOTH) and helmet.

const FOES := {
	"bandit_scrapper": {"name": "Dust Rat Scrapper", "faction": "bandits", "suit": "suit_civil", "weapon": "wp_shotgun", "quality": "E",
		"health": 55.0, "firearms": 1, "athletics": 3, "role": "rusher", "flee": 0.25, "bounty": 120, "c1": 1, "c2": 9, "helmet": false,
		"desc": "Comes at you with a scatter gun – deadly close up, keep your distance."},
	"bandit_rifleman": {"name": "Dust Rat Rifleman", "faction": "bandits", "suit": "suit_work", "weapon": "wp_rifle", "quality": "E",
		"health": 60.0, "firearms": 2, "athletics": 1, "role": "rifleman", "flee": 0.2, "bounty": 150, "c1": 7, "c2": 8, "helmet": false,
		"desc": "Finds cover and shoots from afar with a rail carbine."},
	"bandit_gunner": {"name": "Dust Rat Gunner", "faction": "bandits", "suit": "suit_work", "weapon": "wp_smg", "quality": "D",
		"health": 65.0, "firearms": 1, "athletics": 1, "role": "gunner", "flee": 0.2, "bounty": 140, "c1": 0, "c2": 10, "helmet": false,
		"desc": "Holds a spot and sprays slugs at middle range."},
	"bandit_boss": {"name": "Dust Rat Boss", "faction": "bandits", "suit": "suit_mil_light", "weapon": "wp_laser_rifle", "quality": "D",
		"health": 100.0, "firearms": 4, "athletics": 2, "role": "boss", "flee": 0.0, "bounty": 400, "c1": 0, "c2": 8, "helmet": true,
		"desc": "Leads the gang from cover with a laser rifle and a real shield. Never runs."},
}
const KINDS := ["bandit_scrapper", "bandit_rifleman", "bandit_gunner", "bandit_boss"]

## Foes' shots hit for this share of their weapon's damage. 0.7.52.3 (Luz: "the fights should feel much mightier –
## one against three fairly easy with somewhat better gear"): three bandits need about half a minute to bring down a
## pilot standing in the open in a light combat suit, from cover far longer; each of them falls in a few seconds.
const DAMAGE := 0.12

## 0.7.52.4 (Luz): how strong a foe is – shown as a coloured ring at its feet: green very easy, yellow middling, red
## dangerous. A tier scales its body, its damage and its aim, and gives it better gear (quality steps up).
const TIERS := {
	"green": {"name": "easy", "health": 1.0, "damage": 1.0, "firearms": 0, "quality": 0, "col": Color(0.35, 1.0, 0.45)},
	"yellow": {"name": "middling", "health": 1.6, "damage": 1.7, "firearms": 2, "quality": 1, "col": Color(1.0, 0.85, 0.25)},
	"red": {"name": "dangerous", "health": 2.5, "damage": 2.7, "firearms": 4, "quality": 2, "col": Color(1.0, 0.3, 0.25)},
}
const TIER_ORDER := ["green", "yellow", "red"]


## The quality a tier steps a base quality up to ("E" + 2 → "C").
static func tier_quality(q: String, tier: String) -> String:
	var qs := ["F", "E", "D", "C", "B", "A"]
	var i := qs.find(q)
	return qs[clampi((i if i >= 0 else 1) + int(TIERS.get(tier, TIERS["green"])["quality"]), 0, qs.size() - 1)]


## A foe entry of an arena list: "kind" or "kind@tier" → [kind, tier].
static func parse(entry: String) -> Array:
	var p := entry.split("@")
	return [p[0], p[1] if p.size() > 1 and TIERS.has(p[1]) else "green"]


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
