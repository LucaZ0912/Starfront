extends RefCounted
## Package 52 (Luz, 10 Nov 2026): who fights you on foot. Each kind wears a suit and carries a weapon from data/gear.gd
## (their layers – shield, armour, health – come from the suit, the damage from the weapon, both at the kind's
## quality); `firearms` and `athletics` are their skill levels (0–10 as the pilot's); `health` their bodies (0.7.52.3:
## less than the pilot's); `flee`: below this share of health they run; `c1`/`c2`, `helmet`, `livery`: their look.
## `grenades`: frag grenades they carry (thrown when you sit too long behind the same cover).
##
## 0.7.52.5 – the AI types (`role`), each with its own tactic:
##   rusher   – closes in to half its reach, sidesteps close up (scatter guns)
##   rifleman – takes cover facing you at ~60 % of its reach, moves on when you get round it
##   holder   – takes a spot behind cover and holds it, spraying; only moves when it has lost sight of you for long
##   flanker  – runs round to your side while the others pin you down, to where your cover does not help you
##   thrower  – keeps its distance and throws grenades as soon as you settle behind cover
##   leader   – leads from cover further back; the others keep near it, and when it falls their nerve breaks
##   sniper   – (Luz) stays at 90 % of its reach in cover; far better aim, far slower fire – a red aiming line warns
##              of its shot
## `aim`: × its hit chance; `rof`: × its weapon's rate of fire; `sight`: how far it sees you (art px).

const FOES := {
	"bandit_scrapper": {"name": "Dust Rat Scrapper", "faction": "bandits", "suit": "suit_civil", "weapon": "wp_shotgun", "quality": "E",
		"health": 55.0, "firearms": 1, "athletics": 3, "role": "rusher", "flee": 0.25, "bounty": 120, "c1": 1, "c2": 9, "helmet": false,
		"desc": "Comes at you with a scatter gun – deadly close up, keep your distance."},
	"bandit_rifleman": {"name": "Dust Rat Rifleman", "faction": "bandits", "suit": "suit_work", "weapon": "wp_rifle", "quality": "E",
		"health": 60.0, "firearms": 2, "athletics": 1, "role": "rifleman", "flee": 0.2, "bounty": 150, "c1": 7, "c2": 8, "helmet": false,
		"desc": "Finds cover and shoots from afar with a rail carbine."},
	"bandit_gunner": {"name": "Dust Rat Gunner", "faction": "bandits", "suit": "suit_work", "weapon": "wp_smg", "quality": "D",
		"health": 65.0, "firearms": 1, "athletics": 1, "role": "holder", "flee": 0.2, "bounty": 140, "c1": 0, "c2": 10, "helmet": false,
		"desc": "Holds a spot behind cover and sprays slugs at middle range."},
	"bandit_boss": {"name": "Dust Rat Boss", "faction": "bandits", "suit": "suit_mil_light", "weapon": "wp_laser_rifle", "quality": "D",
		"health": 100.0, "firearms": 4, "athletics": 2, "role": "leader", "flee": 0.0, "bounty": 400, "c1": 0, "c2": 8, "helmet": true,
		"grenades": 1, "desc": "Leads the gang from cover with a laser rifle and a real shield. Never runs – but when it falls, the gang runs."},
	# 0.7.52.5: pirates – combat suits in black and red, grenades, a sniper and a captain
	"pirate_raider": {"name": "Red Talon Raider", "faction": "pirates", "suit": "suit_mil_light", "weapon": "wp_smg", "quality": "D",
		"health": 70.0, "firearms": 2, "athletics": 4, "role": "flanker", "flee": 0.15, "bounty": 220, "c1": 0, "c2": 8, "helmet": true,
		"livery": "pirate", "desc": "Runs round to your side while the others keep you down."},
	"pirate_gunner": {"name": "Red Talon Gunner", "faction": "pirates", "suit": "suit_mil_light", "weapon": "wp_rifle", "quality": "D",
		"health": 70.0, "firearms": 3, "athletics": 1, "role": "holder", "flee": 0.15, "bounty": 220, "c1": 0, "c2": 8, "helmet": true,
		"livery": "pirate", "desc": "Digs in behind cover and keeps you pinned with a rail carbine."},
	"pirate_grenadier": {"name": "Red Talon Grenadier", "faction": "pirates", "suit": "suit_mil_light", "weapon": "wp_pistol", "quality": "D",
		"health": 70.0, "firearms": 2, "athletics": 2, "role": "thrower", "flee": 0.2, "bounty": 240, "c1": 0, "c2": 8, "helmet": true,
		"livery": "pirate", "grenades": 4, "desc": "Keeps back and lobs frag grenades as soon as you settle behind cover."},
	"pirate_sniper": {"name": "Red Talon Sniper", "faction": "pirates", "suit": "suit_mil_light", "weapon": "wp_sniper", "quality": "D",
		"health": 60.0, "firearms": 4, "athletics": 1, "role": "sniper", "flee": 0.3, "bounty": 300, "c1": 0, "c2": 8, "helmet": true,
		"livery": "pirate", "aim": 1.7, "rof": 0.4, "sight": 760.0,
		"desc": "Lies far off in cover with a Long Rail – hardly ever misses, but takes its time. Watch for the red line."},
	"pirate_captain": {"name": "Red Talon Captain", "faction": "pirates", "suit": "suit_mil_heavy", "weapon": "wp_laser_rifle", "quality": "C",
		"health": 100.0, "firearms": 4, "athletics": 1, "role": "leader", "flee": 0.0, "bounty": 600, "c1": 0, "c2": 8, "helmet": true,
		"livery": "pirate", "grenades": 2, "desc": "Heavy plate, a laser rifle, the crew around it. Bring it down and the rest break."},
	# 0.7.52.5: guards – the security of a place (only foes where weapons are allowed and you broke the law)
	"guard_trooper": {"name": "Security Trooper", "faction": "guards", "suit": "suit_mil_light", "weapon": "wp_rifle", "quality": "D",
		"health": 75.0, "firearms": 3, "athletics": 2, "role": "rifleman", "flee": 0.1, "bounty": 0, "c1": 0, "c2": 5, "helmet": true,
		"livery": "independent", "desc": "Trained, steady, in cover – a rail carbine and good plate."},
	"guard_heavy": {"name": "Security Heavy", "faction": "guards", "suit": "suit_mil_heavy", "weapon": "wp_smg", "quality": "D",
		"health": 90.0, "firearms": 2, "athletics": 0, "role": "holder", "flee": 0.0, "bounty": 0, "c1": 0, "c2": 5, "helmet": true,
		"livery": "independent", "desc": "A walking bunker that holds its ground."},
	"guard_sergeant": {"name": "Security Sergeant", "faction": "guards", "suit": "suit_mil_light", "weapon": "wp_laser_rifle", "quality": "C",
		"health": 90.0, "firearms": 4, "athletics": 2, "role": "leader", "flee": 0.0, "bounty": 0, "c1": 0, "c2": 5, "helmet": true,
		"livery": "independent", "grenades": 2, "desc": "Leads the squad – and throws a grenade at anyone who digs in."},
}
const KINDS := ["bandit_scrapper", "bandit_rifleman", "bandit_gunner", "bandit_boss", "pirate_raider", "pirate_gunner",
	"pirate_grenadier", "pirate_sniper", "pirate_captain", "guard_trooper", "guard_heavy", "guard_sergeant"]
const ROLES := ["rusher", "rifleman", "holder", "flanker", "thrower", "leader", "sniper"]
## How a role fights: `pref` – the share of its reach it keeps from you; `cover` – it seeks cover.
const ROLE := {
	"rusher": {"pref": 0.45, "cover": false}, "rifleman": {"pref": 0.6, "cover": true}, "holder": {"pref": 0.55, "cover": true},
	"flanker": {"pref": 0.45, "cover": false}, "thrower": {"pref": 0.7, "cover": true}, "leader": {"pref": 0.75, "cover": true},
	"sniper": {"pref": 0.9, "cover": true},
}
const GRENADE_CAMP := 3.5              # seconds you may sit behind the same cover before a foe with grenades throws one
const THROWER_CAMP := 2.0              # … before a thrower does
const MORALE_BREAK := 0.3              # added to the others' flee share when their leader falls

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


## How far a foe sees you (art px, ~15 a metre; a kind's `sight` can see further) and hears a shot.
const SIGHT := 300.0
const HEAR := 420.0


## The weapon a kind carries, with its quality: "wp_rifle:E".
static func weapon_id(kind: String, quality: String = "") -> String:
	var d: Dictionary = FOES.get(kind, {})
	return "%s:%s" % [String(d.get("weapon", "wp_pistol")), quality if quality != "" else String(d.get("quality", "E"))]


static func suit_id(kind: String, quality: String = "") -> String:
	var d: Dictionary = FOES.get(kind, {})
	return "%s:%s" % [String(d.get("suit", "suit_civil")), quality if quality != "" else String(d.get("quality", "E"))]
