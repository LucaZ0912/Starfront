extends RefCounted
## Package 29: the pilot's skills. Each one rests on one or two attributes and grows by doing: it gathers
## experience from the matching activity and rises a level by itself once enough is there (0.5.29.2, decision of
## Luz – confirming moved to the skill tree's tiles). All the experience also feeds the pilot level. Levels 0–10, every level +1 % on its effect (about +10 % at the top – noticeable, never
## decisive). The attributes set the starting level and how fast a skill learns.

const MAX_LEVEL := 10
const BONUS_PER_LEVEL := 0.01

## id, name, attributes, effect, what makes it grow
const SKILLS := [
	["piloting", "Piloting", ["reflexes", "dexterity"], "Top speed and acceleration, faster aligning for warp", "flying: warps, docking"],
	["gunnery", "Gunnery", ["reflexes", "intelligence"], "Damage of the ship's weapons, faster target locks", "hits on hostile ships"],
	["engineering", "Engineering", ["intelligence", "dexterity"], "Reactor output, shorter shield downtime", "repairing, building in a factory"],
	["science", "Science", ["intelligence"], "Range of scanners and surveys", "scanning, analysing anomalies, surveys"],
	["navigation", "Navigation", ["intelligence", "reflexes"], "Warp speed, less fuel per jump", "jumps and wormhole jumps"],
	["mining", "Mining", ["strength", "intelligence"], "Mining rate", "mining and refining ore"],
	["trading", "Trading", ["charisma", "intelligence"], "Better prices when buying and selling (half the bonus each)", "trading at markets"],
	["leadership", "Leadership", ["charisma"], "Leading crews and wingmen (from package 31)", "flying with a crew or wingmen (later)"],
	["negotiation", "Negotiation", ["charisma", "reflexes"], "Higher contract rewards", "completing contracts"],
	["electronics", "Electronics", ["intelligence", "reflexes"], "Radar jammer range, scanner speed", "jamming, warrant and cargo scans, interdictions"],
	["athletics", "Athletics", ["strength", "dexterity"], "On foot (part 7)", "on foot (part 7)"],
	["firearms", "Firearms", ["dexterity", "reflexes"], "Hand weapons (part 7)", "on foot (part 7)"],
]


static func ids() -> Array:
	var out: Array = []
	for s in SKILLS:
		out.append(s[0])
	return out


static func info(id: String) -> Array:
	for s in SKILLS:
		if s[0] == id:
			return s
	return []


## The mean of a skill's attributes.
static func attr_mean(id: String, attrs: Dictionary) -> float:
	var a: Array = info(id)[2]
	var t := 0.0
	for at in a:
		t += float(attrs.get(at, 3))
	return t / float(a.size())


## Starting level from the attributes: 0 at 3, 1 from 5.5, 2 at 8.
static func start_level(id: String, attrs: Dictionary) -> int:
	return clampi(int(floor((attr_mean(id, attrs) - 3.0) / 2.5)), 0, 2)


## How fast a skill learns: × 0.9 at attributes of 3, × 1.4 at 8.
static func learn_rate(id: String, attrs: Dictionary) -> float:
	return 0.6 + 0.1 * attr_mean(id, attrs)


## Experience needed from `level` to the next one.
static func need(level: int) -> float:
	return round(100.0 * pow(float(level + 1), 1.5))


## The pilot level (0.5.29.2): every bit of skill experience counts towards it. Experience from level L to L+1.
const PILOT_MAX := 50


static func pilot_need(level: int) -> float:
	return round(250.0 * pow(float(level), 1.4))


## The skills of a new pilot.
static func new_skills(attrs: Dictionary) -> Dictionary:
	var out := {}
	for id in ids():
		out[id] = {"lvl": start_level(id, attrs), "xp": 0.0}
	return out
