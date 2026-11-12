extends RefCounted
## Package 53e (Luz, 12 Nov 2026): the Museum in Curie – 48 exhibits in five rooms. Each can be found more than once,
## some far more rarely than others; a spare one sells for a price by its rarity. Each has a picture of its own
## (scripts/core/exhibit_art.gd – `art`: its shape and colours). No class_name: preload it.

const RARITY := {
	"common": {"name": "common", "price": 400, "col": Color(0.8, 0.82, 0.85), "weight": 10.0},
	"uncommon": {"name": "uncommon", "price": 1200, "col": Color(0.4, 0.95, 0.5), "weight": 4.0},
	"rare": {"name": "rare", "price": 4000, "col": Color(0.4, 0.7, 1.0), "weight": 1.5},
	"legendary": {"name": "legendary", "price": 12000, "col": Color(1.0, 0.7, 0.25), "weight": 0.4},
}

## The rooms, floor by floor (0 the ground floor, -1 the basement).
const ROOMS := [
	{"id": "minerals", "name": "Minerals", "floor": 0},
	{"id": "oldworld", "name": "The Old World", "floor": 1},
	{"id": "severance", "name": "The Severance", "floor": 1},
	{"id": "precursors", "name": "The Precursors", "floor": 2},
	{"id": "darkones", "name": "The Dark Ones", "floor": -1},
]

const EXHIBITS := [
	# ---- minerals: found now and then while mining (asteroids, the old mines), seldom as a job's reward
	{"id": "mn_diamond", "room": "minerals", "rarity": "legendary", "name": "Giant Diamond", "art": ["gem", Color(0.85, 0.95, 1.0), Color(0.55, 0.75, 0.95)],
		"text": "A diamond the size of a fist – the miners who found it never came back up for it."},
	{"id": "mn_geode", "room": "minerals", "rarity": "uncommon", "name": "Singing Geode", "art": ["geode", Color(0.55, 0.5, 0.48), Color(0.75, 0.55, 0.95)],
		"text": "Its crystals ring when the air moves."},
	{"id": "mn_fossil", "room": "minerals", "rarity": "uncommon", "name": "Fossil in Ore", "art": ["fossil", Color(0.5, 0.42, 0.35), Color(0.85, 0.78, 0.6)],
		"text": "Something lived in this rock before there was air on this world."},
	{"id": "mn_meteor", "room": "minerals", "rarity": "common", "name": "Iron Meteorite", "art": ["rock", Color(0.35, 0.33, 0.32), Color(0.6, 0.58, 0.55)],
		"text": "Fell here before the colonies, buried under a hundred metres of rock."},
	{"id": "mn_gold", "room": "minerals", "rarity": "common", "name": "Gold Nugget", "art": ["nugget", Color(0.95, 0.75, 0.25), Color(1.0, 0.92, 0.55)],
		"text": "Heavy, warm-coloured, the size of an egg."},
	{"id": "mn_opal", "room": "minerals", "rarity": "rare", "name": "Starfall Opal", "art": ["opal", Color(0.85, 0.9, 0.95), Color(1.0, 0.45, 0.3)],
		"text": "Fire moves inside it, though it has been cold for a billion years."},
	{"id": "mn_garnet", "room": "minerals", "rarity": "rare", "name": "Void Garnet", "art": ["gem", Color(0.35, 0.05, 0.1), Color(0.75, 0.15, 0.25)],
		"text": "So dark red it looks black – until you hold it to a star."},
	{"id": "mn_helix", "room": "minerals", "rarity": "uncommon", "name": "Helix Quartz", "art": ["helix", Color(0.9, 0.92, 0.95), Color(0.6, 0.7, 0.85)],
		"text": "Grew in a spiral; nobody agrees how."},
	{"id": "mn_spinel", "room": "minerals", "rarity": "uncommon", "name": "Frost Spinel", "art": ["crystal", Color(0.6, 0.85, 1.0), Color(0.9, 0.97, 1.0)],
		"text": "Always a little colder than the hand that holds it."},
	{"id": "mn_beryl", "room": "minerals", "rarity": "uncommon", "name": "Ember Beryl", "art": ["crystal", Color(0.85, 0.3, 0.1), Color(1.0, 0.7, 0.3)],
		"text": "Formed in a magma flow, still glowing faintly at its heart."},
	{"id": "mn_rose", "room": "minerals", "rarity": "common", "name": "Glass Rose", "art": ["rose", Color(0.85, 0.75, 0.55), Color(0.95, 0.9, 0.75)],
		"text": "Desert sand fused by lightning into petals."},
	{"id": "mn_pearl", "room": "minerals", "rarity": "rare", "name": "Tidal Pearl", "art": ["pearl", Color(0.85, 0.88, 0.95), Color(0.6, 0.75, 0.9)],
		"text": "From an ice moon's hidden ocean – no living thing made it."},
	{"id": "mn_agate", "room": "minerals", "rarity": "common", "name": "Ring Agate", "art": ["agate", Color(0.75, 0.5, 0.3), Color(0.95, 0.85, 0.7)],
		"text": "Bands like a gas giant's clouds, cut from an asteroid."},
	{"id": "mn_comet", "room": "minerals", "rarity": "uncommon", "name": "Comet Ice Crystal", "art": ["crystal", Color(0.75, 0.9, 0.85), Color(0.95, 1.0, 0.98)],
		"text": "Kept frozen since before the Severance; it smells of tar."},
	{"id": "mn_uranin", "room": "minerals", "rarity": "uncommon", "name": "Radiant Uraninite", "art": ["glow_rock", Color(0.25, 0.3, 0.2), Color(0.5, 1.0, 0.35)],
		"text": "Glows green in the dark. Displayed behind lead glass."},
	{"id": "mn_sphere", "room": "minerals", "rarity": "rare", "name": "Hollow Nickel Sphere", "art": ["sphere", Color(0.6, 0.62, 0.65), Color(0.9, 0.92, 0.95)],
		"text": "A perfect metal ball, empty inside. Formed, not made – probably."},
	{"id": "mn_thunder", "room": "minerals", "rarity": "common", "name": "Thunder Egg", "art": ["geode", Color(0.5, 0.45, 0.38), Color(0.45, 0.75, 0.6)],
		"text": "Plain stone outside, a field of crystal inside."},
	{"id": "mn_hematite", "room": "minerals", "rarity": "common", "name": "Mirror Hematite", "art": ["mirror", Color(0.3, 0.3, 0.33), Color(0.85, 0.88, 0.92)],
		"text": "Polished by sandstorms into a mirror."},
	{"id": "mn_twin", "room": "minerals", "rarity": "rare", "name": "Twin Crystal", "art": ["twin", Color(0.75, 0.6, 0.95), Color(0.95, 0.85, 1.0)],
		"text": "Two crystals grown through each other at an impossible angle."},
	{"id": "mn_heart", "room": "minerals", "rarity": "legendary", "name": "Heart of a Planetoid", "art": ["rock", Color(0.4, 0.38, 0.4), Color(0.3, 0.55, 1.0)],
		"text": "The core of a shattered asteroid – iron veined with blue."},
	# ---- the Old World: Earth – old battlefields and wrecks from before the Severance
	{"id": "ow_pazz", "room": "oldworld", "rarity": "legendary", "name": "Pazz – Vinyl Record", "art": ["record", Color(0.08, 0.08, 0.1), Color(1.0, 0.2, 0.55)],
		"text": "A punk record from Earth. The sleeve is torn, the grooves are worn. Somebody played it loud and often."},
	{"id": "ow_book", "room": "oldworld", "rarity": "uncommon", "name": "Paper Book", "art": ["book", Color(0.55, 0.25, 0.2), Color(0.92, 0.88, 0.75)],
		"text": "A printed novel. Its title has worn away; the last pages are missing."},
	{"id": "ow_watch", "room": "oldworld", "rarity": "rare", "name": "Steel Wristwatch", "art": ["watch", Color(0.7, 0.72, 0.75), Color(0.15, 0.15, 0.18)],
		"text": "Wound by the movement of a wrist. It still runs – on Earth's hours."},
	{"id": "ow_coin", "room": "oldworld", "rarity": "uncommon", "name": "Old World Coin", "art": ["coin", Color(0.8, 0.6, 0.3), Color(0.6, 0.42, 0.2)],
		"text": "A coin of a nation nobody here can name."},
	{"id": "ow_seeds", "room": "oldworld", "rarity": "rare", "name": "Seed Packet", "art": ["packet", Color(0.95, 0.85, 0.4), Color(0.85, 0.3, 0.45)],
		"text": "Seeds of a flower that has never grown in the Cluster. Still sealed."},
	# ---- the Severance: wrecks and echoes at the Veil's edge, the debris of the Long Gate
	{"id": "sv_gate", "room": "severance", "rarity": "legendary", "name": "Long Gate Shard", "art": ["shard", Color(0.35, 0.38, 0.45), Color(0.45, 0.85, 1.0)],
		"text": "A sliver of the gate that once led home. Its edge is still warm."},
	{"id": "sv_transmission", "room": "severance", "rarity": "rare", "name": "Last Transmission", "art": ["recorder", Color(0.3, 0.32, 0.35), Color(1.0, 0.3, 0.2)],
		"text": "A recorder holding the last message from beyond the Veil – mostly static."},
	{"id": "sv_ensign", "room": "severance", "rarity": "uncommon", "name": "Colonial Fleet Ensign", "art": ["flag", Color(0.2, 0.3, 0.6), Color(0.95, 0.9, 0.8)],
		"text": "The flag of the fleet that brought the colonists. Burned at one corner."},
	{"id": "sv_ration", "room": "severance", "rarity": "uncommon", "name": "Ration Card", "art": ["card", Color(0.85, 0.82, 0.7), Color(0.6, 0.2, 0.15)],
		"text": "Issued in the first hard year after the Severance. Never used."},
	{"id": "sv_log", "room": "severance", "rarity": "rare", "name": "Gatekeeper's Log", "art": ["logbook", Color(0.25, 0.28, 0.3), Color(0.95, 0.75, 0.2)],
		"text": "The log of the gate crew on the day it went dark. The last entry is unfinished."},
	# ---- the Precursors: their ruins, hidden caches; the tablets from scanning their carved tablets
	{"id": "pr_lens", "room": "precursors", "rarity": "uncommon", "name": "Precursor Lens", "art": ["lens", Color(0.55, 0.4, 0.3), Color(0.7, 0.55, 1.0)],
		"text": "A disc of fused crystal that bends light into patterns nobody reads."},
	{"id": "pr_key", "room": "precursors", "rarity": "rare", "name": "Precursor Key-Rod", "art": ["rod", Color(0.5, 0.32, 0.22), Color(0.45, 0.9, 0.8)],
		"text": "A rod of iron and living crystal – it hums near their doors."},
	{"id": "pr_core", "room": "precursors", "rarity": "legendary", "name": "Precursor Heart-Core", "art": ["core", Color(0.5, 0.32, 0.22), Color(1.0, 0.55, 0.3)],
		"text": "Warm to the touch after an age in the dark."},
	{"id": "pr_map", "room": "precursors", "rarity": "rare", "name": "Precursor Star Plate", "art": ["plate", Color(0.5, 0.35, 0.25), Color(0.9, 0.85, 0.6)],
		"text": "Stars engraved in iron – some of them are not there any more."},
	{"id": "pr_idol", "room": "precursors", "rarity": "uncommon", "name": "Precursor Figurine", "art": ["figurine", Color(0.6, 0.42, 0.3), Color(0.75, 0.6, 1.0)],
		"text": "Small, humanoid, worn smooth by many hands."},
	{"id": "pr_t_cities", "room": "precursors", "rarity": "common", "name": "Tablet: The Cities", "art": ["tablet_pr", Color(0.45, 0.3, 0.22), Color(0.7, 0.55, 1.0), 0],
		"text": "Their cities were vast – plans of streets that cover whole continents."},
	{"id": "pr_t_voices", "room": "precursors", "rarity": "common", "name": "Tablet: Many Voices", "art": ["tablet_pr", Color(0.45, 0.3, 0.22), Color(0.4, 0.85, 1.0), 1],
		"text": "Every one of them seems to have walked their own way – and yet no record of war between them."},
	{"id": "pr_t_lattice", "room": "precursors", "rarity": "uncommon", "name": "Tablet: The Lattice", "art": ["tablet_pr", Color(0.45, 0.3, 0.22), Color(1.0, 0.5, 0.75), 2],
		"text": "Their power ran through crystals of many colours, grown by a method we cannot repeat."},
	{"id": "pr_t_keepers", "room": "precursors", "rarity": "uncommon", "name": "Tablet: The Keepers", "art": ["tablet_pr", Color(0.45, 0.3, 0.22), Color(0.5, 1.0, 0.6), 3],
		"text": "Their machines still walk the halls and follow orders older than our species' records."},
	{"id": "pr_t_last", "room": "precursors", "rarity": "rare", "name": "Tablet: The Last Layer", "art": ["tablet_pr", Color(0.45, 0.3, 0.22), Color(1.0, 0.85, 0.4), 4],
		"text": "On almost every world their traces end at the same moment. No warning, no ruins of war."},
	# ---- the Dark Ones: the bottom of their ruins, hidden caches; the tablets from a monolith's visions
	{"id": "do_shard", "room": "darkones", "rarity": "rare", "name": "Black Shard", "art": ["shard", Color(0.06, 0.05, 0.09), Color(0.62, 0.35, 1.0)],
		"text": "Glass as dark as a closed eye. It is cold, and never quite still."},
	{"id": "do_coil", "room": "darkones", "rarity": "rare", "name": "Coiled Relic", "art": ["coil", Color(0.7, 0.66, 0.6), Color(0.62, 0.35, 1.0)],
		"text": "A spiral of bone-like stone that hums when nobody listens."},
	{"id": "do_mask", "room": "darkones", "rarity": "legendary", "name": "Sleeper's Mask", "art": ["mask", Color(0.12, 0.1, 0.15), Color(0.62, 0.35, 1.0)],
		"text": "Too wide for any face we know. The eyes are shut."},
	{"id": "do_collar", "room": "darkones", "rarity": "legendary", "name": "Undying Collar", "art": ["collar", Color(0.15, 0.13, 0.18), Color(0.8, 0.4, 1.0)],
		"text": "Worn by their slaves. As long as it was closed, its wearer could not die."},
	{"id": "do_idol", "room": "darkones", "rarity": "rare", "name": "Pantheon Idol", "art": ["idol", Color(0.1, 0.08, 0.13), Color(0.62, 0.35, 1.0)],
		"text": "One of their gods – or one of many faces of one."},
	{"id": "do_t_pantheon", "room": "darkones", "rarity": "uncommon", "name": "Tablet: The Pantheon", "art": ["tablet_do", Color(0.08, 0.07, 0.1), Color(0.62, 0.35, 1.0), 0],
		"text": "Figures in a ring, each with its own sign. Their writing round it is not deciphered."},
	{"id": "do_t_bound", "room": "darkones", "rarity": "rare", "name": "Tablet: The Bound", "art": ["tablet_do", Color(0.08, 0.07, 0.1), Color(0.62, 0.35, 1.0), 1],
		"text": "Rows of humanoid shapes in chains, unchanged from row to row – as if they never aged."},
	{"id": "do_t_veil", "room": "darkones", "rarity": "rare", "name": "Tablet: The Veil", "art": ["tablet_do", Color(0.08, 0.07, 0.1), Color(0.62, 0.35, 1.0), 2],
		"text": "A ring of darkness round the stars, and the figures kneeling towards it. What it meant, nobody knows."},
]


static func get_exhibit(id: String) -> Dictionary:
	for e in EXHIBITS:
		if String(e["id"]) == id:
			return e
	return {}


static func of_room(room: String) -> Array:
	return EXHIBITS.filter(func(e): return String(e["room"]) == room)


static func price(id: String) -> int:
	return int(RARITY[String(get_exhibit(id).get("rarity", "common"))]["price"])


## Where a room's pieces are found – the curator's hints (and the debug menu's).
const HINTS := {
	"minerals": "Minerals turn up now and then when you mine asteroids, more often deep in the old mines – and the odd one is a job's reward.",
	"oldworld": "The Old World's things lie in old wrecks and on old battlefields – ships that flew before the Severance.",
	"severance": "The Severance's relics drift in the wrecks near the Veil – the debris of the Long Gate.",
	"precursors": "The Precursors' things lie in their ruins and in the caches hidden there; their carved tablets tell more when you scan them.",
	"darkones": "The Dark Ones' things lie at the bottom of their ruins, far out; their monoliths show visions to a scanner.",
}

## A complete room's reward (GameState.museum_perk).
const PERKS := {
	"minerals": "Rare minerals turn up twice as often.",
	"oldworld": "The Covenant thanks you more for every relic of Earth (half as much standing again).",
	"severance": "Old gates throw you off course half as often.",
	"precursors": "Scanning takes a third less time.",
	"darkones": "Waves of force and glyphs hurt you half as much.",
}

const SUIT_REWARD := "suit_archivist:A"         # the whole Museum full: the Archivist Suit


static func room_of(id: String) -> String:
	return String(get_exhibit(id).get("room", ""))


static func exhibit_name(id: String) -> String:
	return String(get_exhibit(id).get("name", id))


static func is_tablet(id: String) -> bool:
	return String(get_exhibit(id).get("art", [""])[0]).begins_with("tablet")


static func room_name(room: String) -> String:
	for r in ROOMS:
		if String(r["id"]) == room:
			return String(r["name"])
	return room


## A find of a room by weighted rarity – the tablets only when `tablets` (they come from scans), or only them.
## `rare_x`: the rare and legendary ones that many times as likely (the minerals room's reward).
static func roll_kind(room: String, rng: RandomNumberGenerator, tablets: int = 0, rare_x: float = 1.0) -> String:
	var pool := of_room(room).filter(func(e): return tablets == 1 or (tablets == 0 and not is_tablet(String(e["id"]))) or (tablets == 2 and is_tablet(String(e["id"]))))
	var tot := 0.0
	for e in pool:
		tot += _w(e, rare_x)
	if tot <= 0.0:
		return ""
	var r := rng.randf() * tot
	for e2 in pool:
		r -= _w(e2, rare_x)
		if r <= 0.0:
			return String(e2["id"])
	return String(pool[-1]["id"])


static func _w(e: Dictionary, rare_x: float) -> float:
	var wv := float(RARITY[String(e["rarity"])]["weight"])
	if String(e["rarity"]) in ["rare", "legendary"]:
		wv *= rare_x
	return wv


## The room a site's theme yields finds for ("" none). A wreck: the Old World's, near the Veil the Severance's.
static func room_for_theme(theme: String, veil: bool = false) -> String:
	match theme:
		"precursor":
			return "precursors"
		"mine":
			return "minerals"
		"darkones":
			return "darkones"
		"wreck":
			return "severance" if veil else "oldworld"
	return ""
