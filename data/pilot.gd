extends RefCounted
## Package 28: the pilot – a person of their own with a name, a call sign, looks (PilotArt) and five attributes.
## The attributes are set once when a game starts: all begin at START, FREE points to hand out, at most MAX each.
## They do not grow afterwards (part 5 decision); the skills of package 29 are derived from them.

const START := 3
const FREE := 8
const MAX := 8
const LOOK_PRICE := 2500           # changing the looks at a station's image studio

## id, name in the game, what it is good for
const ATTRS := [
	["strength", "Strength", "Endurance, mining craft – and fighting on foot later (part 7)."],
	["dexterity", "Dexterity", "Fine control: flying, repairs, hand weapons."],
	["intelligence", "Intelligence", "Technology, science, navigation, electronics."],
	["charisma", "Charisma", "Trade, negotiation, leading a crew and mercenaries."],
	["reflexes", "Reflexes", "Evasion, aiming under pressure, timing (e.g. the interdictor)."],
]


static func base_attrs() -> Dictionary:
	var a := {}
	for at in ATTRS:
		a[at[0]] = START
	return a


## The attributes a pilot gets without a choice (old saves, the test system): the free points spread out.
static func default_attrs() -> Dictionary:
	var a := base_attrs()
	for k in ["intelligence", "dexterity", "reflexes", "intelligence", "dexterity", "reflexes", "charisma", "strength"]:
		a[k] = int(a[k]) + 1
	return a


static func spent(attrs: Dictionary) -> int:
	var n := 0
	for at in ATTRS:
		n += int(attrs.get(at[0], START)) - START
	return n


## "" = valid for a new pilot: every attribute from START to MAX, exactly FREE points spent.
static func attrs_error(attrs: Dictionary) -> String:
	for at in ATTRS:
		var v := int(attrs.get(at[0], -1))
		if v < START or v > MAX:
			return "%s must be between %d and %d." % [at[1], START, MAX]
	var s := spent(attrs)
	if s != FREE:
		return "Hand out all %d points (%d left)." % [FREE, FREE - s] if s < FREE else "Only %d points to hand out." % FREE
	return ""


static func name_of(id: String) -> String:
	for at in ATTRS:
		if at[0] == id:
			return at[1]
	return id
