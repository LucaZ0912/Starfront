extends Node
const MakerData = preload("res://data/manufacturers.gd")
const ModuleData = preload("res://data/modules.gd")
## The galaxy: star systems, hyperspace routes and system layouts.
## Every system is one big continuous space (SYSTEM_RADIUS) at a "realistic" scale.
## Systems are only connected via hyperspace routes (gates). Every route has a class (1-3) –
## the hyperdrive must be at least that class. Star system names are intentionally German.

const CommodityData = preload("res://data/commodities.gd")

const SYSTEM_NAMES := [
	"Helion", "Arkadia", "Vesta", "Kepler-Tor", "Morgenrot", "Eisenhafen", "Lyra", "Brennglas",
	"Nyx", "Tiamat", "Zenit", "Glutheim", "Nebelkrone", "Aschenfeld", "Drakenhorst", "Kalter Stern",
	"Ferne Wacht", "Schattenmark", "Orion-Rand", "Sturmtiefe", "Vakuumtor", "Letzte Bastion",
	# galaxy version 2 (phase 0.5 package 6): larger cluster
	"Silberquell", "Rabenfels", "Glimmertal", "Frosthain", "Sonnenwende", "Dunkelmoor", "Wolkenburg",
	"Kristallsee", "Donnerkeil", "Sternenwacht", "Mondsichel", "Eiswind", "Rotgold", "Feuerkranz",
	"Nordlicht", "Tiefenhall", "Grauwacke", "Sturmfels", "Weltenrand", "Bernstein", "Funkenflug",
	"Leuchtfeuer", "Ödland", "Himmelstor", "Nachtfalke", "Hohenstein",
]
## Galaxy generator version (stored in saves; older saves are moved to the current cluster).
const GALAXY_VERSION := 8          # package 36: moons, orbits rolled on arrival; package 37: star types; 38: planets; 39: special systems
const FactionData = preload("res://data/factions.gd")
## Territory sizes (phase 0.5 package 10): systems per power / per territorial pirate faction.
const POWER_SYSTEMS := 12
const POWER_SYSTEMS_MAX := 14
const PIRATE_SYSTEMS := 4
## Every station type exists in every tier at least once somewhere in the cluster.
const ALL_STATION_TYPES := ["trade", "industry", "mining_colony", "agri", "research", "military", "ice_refinery", "shipyard"]
const ROMAN := ["I", "II", "III", "IV", "V", "VI", "VII", "VIII"]
## Asteroid field classes and their orbital band (km from the star, before frost scaling).
const FIELD_CLASSES := ["metallic", "stony", "icy"]
const FIELD_BANDS := {"metallic": Vector2(1140000, 2700000), "stony": Vector2(2250000, 4050000), "icy": Vector2(3750000, 5550000)}
## Hot stars push the frost line outward, cool ones pull it in.
## Rock class orbiting each planet type (gas giants collect ice, lava worlds metal).
const PLANET_ROCK_CLASS := {"terran": "stony", "desert": "stony", "ice": "icy", "lava": "metallic", "gas": "icy", "toxic": "icy", "barren": "metallic",
	"ice_giant": "icy", "dwarf": "icy", "ocean": "stony", "jungle": "stony", "red_gas": "icy", "metal": "metallic"}
## No-fire zone radius around stations by tier (km). Firing inside makes the station's defence engage.
const NO_FIRE_ZONE := [15000.0, 22000.0, 30000.0]
const HAVEN_NAMES := ["Rustmaw", "Blackhook", "Carrion Nest", "Gallows Reach", "Scrapjaw Den", "Red Lantern", "Vulture's Rest"]
const COLOSSUS_PREFIX := ["K", "V", "R", "T", "Z", "M", "X", "H", "N", "Q"]
## Asteroid size classes: radius (km) and deposit range.
const ASTEROID_SIZES := {
	"small": {"radius": Vector2(10, 25), "amount": Vector2(30, 120)},
	"medium": {"radius": Vector2(25, 60), "amount": Vector2(120, 400)},
	"large": {"radius": Vector2(60, 150), "amount": Vector2(400, 1500)},
}
## Procedural shapes: round, potato (elongated), contact binary, angular fragment, ice shard.
const SHAPES_BY_CLASS := {
	"metallic": ["round", "potato", "binary", "fragment"],
	"stony": ["round", "potato", "binary", "fragment"],
	"icy": ["round", "potato", "shard", "shard", "fragment"],
}
## Rare deposits are smaller.
const RARITY_AMOUNT := {"common": 1.0, "uncommon": 0.8, "rare": 0.55}
const ANOMALY_NAMES := [
	"Gravitational Anomaly", "Derelict Wreck Field", "Subspace Echo", "Ion Storm Core",
	"Unknown Signal", "Crystalline Structure", "Ancient Probe", "Dark Matter Cloud",
]
const MAP_SIZE := Vector2(2100, 1350)
## A system is ONE continuous space. 1 unit = 1 km.
## Package 35: three times as big as before (6 million km); warps are faster, so crossing takes 20–30 s.
const SCALE := 3.0
const SYSTEM_RADIUS := 6000000.0
const GATE_DISTANCE := 5700000.0
## Below this distance ships fly normally instead of warping.
const WARP_MIN := 12000.0          # 0.6.37.2: 40,000 before – planet to moon took up to ten minutes
## 0.6.35.17: stations and havens – their no-fire zones reach out to 30,000 km, and from there the flight in at
## sublight took minutes. Further out than this a ship warps right up to the station.
const WARP_MIN_STATION := 8000.0


## Least distance for a warp to target `t` (a warp target dictionary).
static func warp_min_for(t: Dictionary) -> float:
	return WARP_MIN_STATION if String(t.get("kind", "")) in ["station", "haven"] else WARP_MIN
## Package 37: the star types. kind = how it is drawn and what it does (main sequence, brown dwarf, red supergiant,
## white dwarf, neutron star, black hole). radius in km (G = 60,000); lum = brightness for the solar collector
## (G = 1); frost = how far out the frost line lies (G = 1); weight = share in the Cluster (in %); land = warp
## arrival distance in radii; flares / cme = prominences and coronal mass ejections; color2 = the hot colour;
## r_sun / m_sun / temp / text: what the collection shows (0.6.37.2); cme_rate: how often it erupts (G = 1; red dwarfs
## and red supergiants far more often, 0.6.37.6).
const STAR_TYPES := [
	{"id": "O", "name": "Class O Blue Star", "kind": "main", "color": Color(0.5, 0.62, 1.0), "color2": Color(0.85, 0.92, 1.0), "radius": 150000.0, "lum": 8.0, "frost": 1.35, "weight": 2.0, "land": 2.5, "flares": true, "cme": true, "cme_rate": 0.5, "r_sun": "10", "m_sun": "30", "temp": "35,000 K",
		"text": "Rare blue giants of the main sequence – blinding, hot and short-lived. A few million years, then they end in a supernova."},
	{"id": "B", "name": "Class B Blue-White Star", "kind": "main", "color": Color(0.62, 0.75, 1.0), "color2": Color(0.92, 0.96, 1.0), "radius": 115000.0, "lum": 4.0, "frost": 1.25, "weight": 3.0, "land": 2.5, "flares": true, "cme": true, "cme_rate": 0.5, "r_sun": "4", "m_sun": "8", "temp": "18,000 K",
		"text": "Hot blue-white stars. Their light carries far: the frost line lies a long way out and solar collectors run at full power."},
	{"id": "A", "name": "Class A White Star", "kind": "main", "color": Color(0.85, 0.9, 1.0), "color2": Color(1.0, 1.0, 1.0), "radius": 85000.0, "lum": 2.0, "frost": 1.15, "weight": 5.0, "land": 2.5, "flares": true, "cme": true, "cme_rate": 0.6, "r_sun": "1.8", "m_sun": "2", "temp": "8,500 K",
		"text": "White stars that spin fast; their light is clear and hard."},
	{"id": "F", "name": "Class F Yellow-White Star", "kind": "main", "color": Color(1.0, 0.95, 0.75), "color2": Color(1.0, 1.0, 0.95), "radius": 70000.0, "lum": 1.4, "frost": 1.07, "weight": 8.0, "land": 2.5, "flares": true, "cme": true, "cme_rate": 0.8, "r_sun": "1.3", "m_sun": "1.3", "temp": "6,700 K",
		"text": "Yellow-white stars, a little hotter and brighter than a sun like Sol."},
	{"id": "G", "name": "Class G Yellow Dwarf", "kind": "main", "color": Color(1.0, 0.82, 0.38), "color2": Color(1.0, 0.97, 0.8), "radius": 60000.0, "lum": 1.0, "frost": 1.0, "weight": 15.0, "land": 2.5, "flares": true, "cme": true, "cme_rate": 1.0, "r_sun": "1", "m_sun": "1", "temp": "5,800 K",
		"text": "Yellow dwarfs like Sol, the sun of Earth. Calm, long-lived – the kind of star humanity was born under."},
	{"id": "K", "name": "Class K Orange Dwarf", "kind": "main", "color": Color(1.0, 0.6, 0.25), "color2": Color(1.0, 0.88, 0.6), "radius": 50000.0, "lum": 0.6, "frost": 0.9, "weight": 20.0, "land": 2.5, "flares": true, "cme": true, "cme_rate": 1.3, "r_sun": "0.8", "m_sun": "0.75", "temp": "4,500 K",
		"text": "Orange dwarfs: smaller and cooler than Sol, and they burn for tens of billions of years."},
	{"id": "M", "name": "Class M Red Dwarf", "kind": "main", "color": Color(0.95, 0.32, 0.18), "color2": Color(1.0, 0.7, 0.45), "radius": 38000.0, "lum": 0.3, "frost": 0.8, "weight": 30.0, "land": 2.5, "flares": true, "cme": true, "cme_rate": 2.2, "r_sun": "0.4", "m_sun": "0.3", "temp": "3,200 K",
		"text": "Red dwarfs – the most common stars of all. Dim and cool, and fond of sudden flares."},
	{"id": "BD", "name": "Brown Dwarf", "kind": "brown", "color": Color(0.78, 0.28, 0.58), "color2": Color(1.0, 0.6, 0.85), "radius": 28000.0, "lum": 0.05, "frost": 0.6, "weight": 6.0, "land": 2.5, "flares": false, "cme": false, "cme_rate": 0.0, "r_sun": "0.1", "m_sun": "0.05", "temp": "1,500 K",
		"text": "A failed star: too light to ignite hydrogen in its core. It glows a dull pink from the heat of its own contraction and gives hardly any light."},
	{"id": "RSG", "name": "Red Supergiant", "kind": "giant", "color": Color(0.95, 0.28, 0.1), "color2": Color(1.0, 0.62, 0.3), "radius": 600000.0, "lum": 6.0, "frost": 1.3, "weight": 4.0, "land": 1.6, "flares": true, "cme": true, "cme_rate": 2.5, "r_sun": "800", "m_sun": "15", "temp": "3,600 K",
		"text": "A giant star at the end of its life, swollen to hundreds of times its size. Its surface boils in convection cells as big as whole stars; one day it will explode."},
	{"id": "WD", "name": "White Dwarf", "kind": "white", "color": Color(0.88, 0.94, 1.0), "color2": Color(1.0, 1.0, 1.0), "radius": 18000.0, "lum": 0.3, "frost": 0.85, "weight": 3.0, "land": 3.0, "flares": false, "cme": false, "cme_rate": 0.0, "r_sun": "0.012", "m_sun": "0.6", "temp": "15,000 K",
		"text": "The burnt-out core of a dead star, no bigger than a planet and still white-hot. It cools for billions of years."},
	{"id": "NS", "name": "Neutron Star", "kind": "neutron", "color": Color(0.5, 0.6, 1.0), "color2": Color(0.45, 1.0, 0.95), "radius": 6000.0, "lum": 0.1, "frost": 0.6, "weight": 2.0, "land": 5.0, "flares": false, "cme": false, "cme_rate": 0.0, "r_sun": "0.000015", "m_sun": "1.4", "temp": "600,000 K",
		"text": "The collapsed core of a giant star: twenty kilometres of matter heavier than anything else, spinning, wrapped in a magnetic field so strong its lines of force glow. Two jets sweep round like the beam of a lighthouse."},
	{"id": "BH", "name": "Black Hole", "kind": "blackhole", "color": Color(1.0, 0.5, 0.15), "color2": Color(1.0, 0.92, 0.7), "radius": 12000.0, "lum": 0.0, "frost": 0.6, "weight": 2.0, "land": 10.0, "flares": false, "cme": false, "cme_rate": 0.0, "r_sun": "0.00004", "m_sun": "10", "temp": "—",
		"text": "Nothing comes back from beyond the event horizon, not even light. Gas circles it in a glowing accretion disc, the far side bent over the hole by its gravity. Close in, it pulls ships in – and crushes what crosses the horizon."},
]


## Index of a star type by id ("G", "BH" …).
static func star_index(type_id: String) -> int:
	for i in STAR_TYPES.size():
		if String(STAR_TYPES[i]["id"]) == type_id:
			return i
	return 4


## Package 37: star types across the Cluster by their weights. Home: a G star. Neutron stars and black holes go to
## systems without stations (about one in fifty each, at least one); some of them get a research station.
func _assign_stars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 52021 + 37
	var exotic := ["NS", "BH"]
	var empty: Array = []
	for s2 in systems:
		s2["star"] = star_index("G")
		if int(s2["id"]) != home_system and (s2["stations_plan"] as Array).is_empty() and int(s2.get("haven_tier", 0)) == 0 and String(s2.get("special", "")) == "":
			empty.append(int(s2["id"]))
	_shuffle(empty, rng)
	var taken := {}
	for ex in exotic:
		var want := maxi(1, int(round(systems.size() * float(STAR_TYPES[star_index(ex)]["weight"]) / 100.0)))
		for k in want:
			if empty.is_empty():
				break
			var sid: int = empty.pop_back()
			systems[sid]["star"] = star_index(ex)
			taken[sid] = true
			if rng.randf() < 0.5:                         # scientists like strange places
				systems[sid]["stations_plan"] = [["research", rng.randi_range(1, 2)]]
	var total := 0.0
	for t in STAR_TYPES:
		if not String(t["id"]) in exotic:
			total += float(t["weight"])
	for s3 in systems:
		var sid3 := int(s3["id"])
		if sid3 == home_system or taken.has(sid3):
			continue
		if SPECIAL_STARS.has(String(s3.get("special", ""))):
			s3["star"] = star_index(String(SPECIAL_STARS[String(s3["special"])]))     # package 39
			continue
		var x := rng.randf() * total
		for i in STAR_TYPES.size():
			if String(STAR_TYPES[i]["id"]) in exotic:
				continue
			x -= float(STAR_TYPES[i]["weight"])
			if x <= 0.0:
				s3["star"] = i
				break


## The star type dictionary of a system.
func star_type(sid: int) -> Dictionary:
	return STAR_TYPES[int(systems[sid].get("star", 4))]

## systems[i] = {id, name, pos (Galaxiekarte), security 0..1, star, links {nachbar_id: routenklasse}}
var systems: Array = []
## Lazily generated system layouts (planets, stations, gates, asteroids, anomalies).
## They are mutable (asteroids get mined etc.) and persist.
var layouts: Dictionary = {}
var home_system := 0
var seed_value := 4711
var test_mode := false   # debug test system active (never saved, main galaxy untouched)


func _ready() -> void:
	generate(seed_value)


func generate(p_seed: int) -> void:
	test_mode = false
	seed_value = p_seed
	Economy.clear_cache()                 # package 42
	Market.clear_cache()
	systems.clear()
	layouts.clear()
	orbit_phase.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = p_seed
	for i in SYSTEM_NAMES.size():
		var pos := Vector2.ZERO
		for attempt in 400:
			pos = Vector2(rng.randf_range(70.0, MAP_SIZE.x - 70.0), rng.randf_range(70.0, MAP_SIZE.y - 70.0))
			var ok := true
			for s in systems:
				if (s["pos"] as Vector2).distance_to(pos) < 165.0:
					ok = false
					break
			if ok:
				break
		systems.append({
			"id": i, "name": SYSTEM_NAMES[i], "pos": pos, "security": 0.5,
			"star": rng.randi() % STAR_TYPES.size(), "links": {},
		})
	_build_routes(rng)
	_assign_territory()
	_apply_specials()                                 # package 39
	_plan_stations()
	_assign_stars()                                   # package 37


# ---------------------------------------------------------------- Special systems (package 39)
# Hand-made systems: fixed name, star, planets and moons with names, fixed stations and a landmark. WHERE they lie is
# still up to the generator – the capital of a power always becomes its special system.

## faction -> special system id (its capital)
const SPECIAL_CAPITALS := {"assembly": "landfall", "covenant": "heimkehr", "directorate": "durchbruch"}
const SPECIAL_NAMES := {"landfall": "Landfall", "heimkehr": "Heimkehr", "durchbruch": "Durchbruch",
	"altwerft": "Altwerft", "erzhalde": "Erzhalde", "perlmutt": "Perlmutt", "schwarzwacht": "Schwarzwacht"}
## 39d: the systems of the private manufacturers – Earthworks always in the Assembly's space, the others independent
## (no power holds them; yellow on the galaxy map). Their bodies are random, their yard is the maker's own.
const MAKER_SYSTEMS := {"earthworks": "altwerft", "khi": "erzhalde", "aurelle": "perlmutt", "hadrian": "schwarzwacht"}
const INDEPENDENT_SECURITY := 0.75
const SPECIAL_STARS := {"landfall": "G", "heimkehr": "RSG", "durchbruch": "A"}
## The fixed stations of a special system (type, tier) – their place and look come from SPECIAL_STATIONS.
const SPECIAL_PLANS := {"landfall": [["trade", 3], ["shipyard", 3]], "heimkehr": [["trade", 3], ["shipyard", 3]],
	"durchbruch": [["research", 3], ["shipyard", 3], ["research", 2]],
	"altwerft": [["shipyard", 3], ["trade", 2]], "erzhalde": [["shipyard", 3], ["industry", 2]],
	"perlmutt": [["shipyard", 3], ["trade", 3]], "schwarzwacht": [["shipyard", 3], ["military", 2]]}
## Fixed planets: type, orbit (km, before the scale), radius (km), ring, city lights; moons per planet: [name, type, radius].
const SPECIAL_BODIES := {
	"landfall": [
		{"name": "Pnyx", "type": "barren", "orbit": 250000.0, "radius": 6500.0, "seed": 21.0},
		{"name": "Agora", "type": "terran", "orbit": 560000.0, "radius": 11500.0, "seed": 47.0, "city": 1.0, "city_style": 1.0},
		{"name": "Ekklesia", "type": "ocean", "orbit": 860000.0, "radius": 10500.0, "seed": 63.0},
		{"name": "Boulé", "type": "ice_giant", "orbit": 1250000.0, "radius": 34000.0, "seed": 88.0, "ring": true, "deep": true,
			"moons": [["Ostrakon", "moon_ice", 5200.0], ["Kleros", "moon_rock", 4100.0]]},
	],
	# 39b: the canonical hours – Vesper, the desert world, is a moon of the red gas giant Compline
	"heimkehr": [
		{"name": "Lauds", "type": "lava", "orbit": 700000.0, "radius": 8000.0, "seed": 13.0},
		{"name": "Compline", "type": "red_gas", "orbit": 1150000.0, "radius": 30000.0, "seed": 71.0,
			"moons": [["Vesper", "desert", 8500.0, {"city": 0.85, "city_style": 1.0}], ["Nones", "moon_rock", 3800.0]]},
		{"name": "Matins", "type": "ice", "orbit": 1620000.0, "radius": 7000.0, "seed": 34.0},
	],
	# 39c: physicists – Curie, half terraformed, is the showcase of the Directorate
	"durchbruch": [
		{"name": "Noether", "type": "barren", "orbit": 300000.0, "radius": 6000.0, "seed": 19.0},
		{"name": "Curie", "type": "terran", "orbit": 620000.0, "radius": 11000.0, "seed": 52.0, "city": 0.6, "city_style": 1.0, "terraform": true},
		{"name": "Planck", "type": "gas", "orbit": 1050000.0, "radius": 30000.0, "seed": 64.0,
			"moons": [["Meitner", "moon_ice", 5000.0], ["Bohr", "moon_rock", 3600.0]]},
		{"name": "Kepler", "type": "ice_giant", "orbit": 1500000.0, "radius": 24000.0, "seed": 81.0, "ring": true},
	],
}
## Fixed stations: name, art (landmark look), the body they orbit ("p1" / "m3_0"), distance, extra keys.
const SPECIAL_STATIONS := {
	"landfall": [
		{"name": "The Vote", "art": "vote", "body": "Agora", "dist": 32000.0, "senate": true},
		{"name": "Concord Yards", "art": "concord_yards", "body": "Ostrakon", "dist": 14000.0, "capital_yard": true},
	],
	"heimkehr": [
		{"name": "Cathedral of Return", "art": "cathedral", "body": "Vesper", "dist": 26000.0, "curia": true},
		{"name": "Forge of Return", "art": "forge", "body": "Lauds", "dist": 22000.0, "capital_yard": true},
	],
	"durchbruch": [
		{"name": "Meridian Sphere", "art": "dyson_hub", "body": "STAR", "dist": DYSON_R, "exchange": true},
		{"name": "Axiom Yards", "art": "axiom_yards", "body": "Meitner", "dist": 15000.0, "capital_yard": true},
		{"name": "Curie Terraforming Institute", "art": "research", "body": "Curie", "dist": 26000.0},
	],
	# 39d: the manufacturers' yards ("#1": the second planet, whatever it is)
	"altwerft": [{"name": "Earthworks Second Yard", "art": "ew_yard", "body": "#1", "dist": 30000.0, "maker": "earthworks"}],
	"erzhalde": [{"name": "Kanayama Works", "art": "khi_yard", "body": "#1", "dist": 30000.0, "maker": "khi"}],
	"perlmutt": [{"name": "Atelier Aurelle", "art": "aur_yard", "body": "#1", "dist": 30000.0, "maker": "aurelle"}],
	"schwarzwacht": [{"name": "Hadrian Foundry", "art": "hdy_yard", "body": "#1", "dist": 30000.0, "maker": "hadrian"}],
}
## 39c: the Dyson sphere round Durchbruch's star – its radius (km) and the frame rings of the shell:
## [rotation, flattening (seen from above), share already built, where the built arc begins (0–1)]
const DYSON_R := 175000.0
const DYSON_RINGS := [[0.0, 1.0, 0.72, 0.9], [0.6, 0.36, 0.5, 0.2], [-0.95, 0.52, 0.42, 0.55], [1.75, 0.2, 0.62, 0.05], [2.6, 0.7, 0.3, 0.7]]
const DYSON_HUB_ANGLE := 0.25           # the hub sits on the first (equator) ring – inside its built arc
## Hulls sold only at the yard of their faction's capital (package 39: the flagships of the state manufacturers).
const CAPITAL_ONLY := {"cfw_concordia": "assembly", "for_cathedral": "covenant", "axa_threshold": "directorate"}


## Names the capitals with a special system after it, makes them very safe.
func _apply_specials() -> void:
	for s in systems:
		if not s.get("capital", false):
			continue
		var sp := String(SPECIAL_CAPITALS.get(String(s.get("faction", "")), ""))
		if sp == "":
			continue
		s["special"] = sp
		s["name"] = SPECIAL_NAMES[sp]
		s["security"] = 1.0
	_place_makers()


## 39d: Earthworks gets a safe Assembly system (not the capital, not the start); KHI, Aurelle and Hadrian each an
## independent system – unclaimed ones first, then contested ones, then the edge of a power's space – kept apart from
## each other and from the pirates.
func _place_makers() -> void:
	var hops := _hop_table()
	var taken := {home_system: true}
	for s0 in systems:
		if String(s0.get("special", "")) != "":
			taken[int(s0["id"])] = true
	# Earthworks
	var best := -1
	var best_sc := -INF
	for s in systems:
		var sid := int(s["id"])
		if taken.has(sid) or String(s.get("faction", "")) != "assembly":
			continue
		var sc := float(s["security"]) * 10.0 - absf(int(s.get("core_dist", 0)) - 2)
		if sc > best_sc:
			best_sc = sc
			best = sid
	if best >= 0:
		_make_special(best, "altwerft")
		systems[best]["security"] = maxf(float(systems[best]["security"]), 0.8)
		taken[best] = true
	# the independents
	var chosen: Array = []
	for mk in ["khi", "aurelle", "hadrian"]:
		var pick := -1
		var pick_sc := -INF
		for s2 in systems:
			var sid2 := int(s2["id"])
			var f := String(s2.get("faction", ""))
			if taken.has(sid2) or f in FactionData.PIRATES or bool(s2.get("capital", false)):
				continue
			var near_pirates := false
			for nb in s2["links"]:
				near_pirates = near_pirates or String(systems[nb].get("faction", "")) in FactionData.PIRATES
			var sc2 := 0.0
			if f == "":
				sc2 += 200.0 if (s2.get("claimants", []) as Array).is_empty() else 120.0
			else:
				sc2 += float(int(s2.get("core_dist", 0))) * 10.0
			sc2 -= 80.0 if near_pirates else 0.0
			for c in chosen:
				sc2 += minf(float(hops[sid2][c]), 6.0) * 6.0          # apart from the other independents
			if sc2 > pick_sc:
				pick_sc = sc2
				pick = sid2
		if pick < 0:
			continue
		_make_special(pick, String(MAKER_SYSTEMS[mk]))
		var sp: Dictionary = systems[pick]
		sp["faction"] = ""
		sp["claimants"] = []
		sp["independent"] = true
		sp["security"] = INDEPENDENT_SECURITY
		taken[pick] = true
		chosen.append(pick)


func _make_special(sid: int, sp: String) -> void:
	systems[sid]["special"] = sp
	systems[sid]["name"] = SPECIAL_NAMES[sp]


## 39d: an independent system (no power holds it – yellow on the map).
func is_independent(sid: int) -> bool:
	return sid >= 0 and sid < systems.size() and bool(systems[sid].get("independent", false))


## The special system id of a system ("" = an ordinary one).
func special_of(sid: int) -> String:
	if sid < 0 or sid >= systems.size():
		return ""
	return String(systems[sid].get("special", ""))


## The system of a special id (-1 = not in this cluster).
func special_system(sp: String) -> int:
	for s in systems:
		if String(s.get("special", "")) == sp:
			return int(s["id"])
	return -1


## Faction whose capital this special system is ("" = none).
func special_faction(sid: int) -> String:
	var sp := special_of(sid)
	for f in SPECIAL_CAPITALS:
		if SPECIAL_CAPITALS[f] == sp:
			return String(f)
	return ""


## Fixed planets of a special system (replaces the random ones).
func _special_planets(L: Dictionary, id: int, sp: String) -> void:
	var i := 0
	for d in SPECIAL_BODIES[sp]:
		var orbit := float(d["orbit"]) * SCALE
		L["planets"].append({
			"id": "p%d" % i, "name": String(d["name"]), "type": String(d["type"]), "orbit": orbit,
			"pos": Vector2.from_angle(float(d["seed"])) * orbit, "radius": float(d["radius"]), "seed": float(d["seed"]),
			"ring": bool(d.get("ring", false)), "fixed": true,
		})
		if d.has("city"):
			L["planets"].back()["city_fixed"] = float(d["city"])
		if d.get("deep", false):
			L["planets"].back()["deep"] = true
		if d.has("hue"):
			L["planets"].back()["hue"] = float(d["hue"])            # 39b: the red gas giant Compline
		if d.has("city_style"):
			L["planets"].back()["city_style"] = float(d["city_style"])
		if d.get("terraform", false):
			L["planets"].back()["terraform"] = true            # 39c: Curie, half green, half desert
		i += 1


## Fixed moons of a special system (replaces the random ones).
func _special_moons(L: Dictionary, sp: String) -> void:
	L["moons"] = []
	var pi := 0
	for d in SPECIAL_BODIES[sp]:
		var p: Dictionary = L["planets"][pi]
		var orbit := float(p["radius"]) * 2.6 + 26000.0
		var k := 0
		for md in d.get("moons", []):
			var mr := float(md[2])
			orbit += mr
			L["moons"].append({"id": "m%d_%d" % [pi, k], "planet": pi, "name": String(md[0]), "type": String(md[1]), "radius": mr,
				"orbit": orbit, "pos": p["pos"], "seed": 30.0 + pi * 7.0 + k * 3.0})
			if md.size() > 3:
				L["moons"].back().merge(md[3])               # 39b: Vesper's city lights
			orbit += mr + 30000.0
			k += 1
		pi += 1


## Station i of a special system: where it orbits and how it looks.
func _special_station(L: Dictionary, sp: String, i: int, base: Dictionary) -> Dictionary:
	var specs: Array = SPECIAL_STATIONS.get(sp, [])
	if i >= specs.size():
		return base
	var d: Dictionary = specs[i]
	if String(d["body"]) == "STAR":
		# 39c: the hub of the Dyson sphere – on the shell itself, round the star (no orbit of its own)
		base["pos"] = Vector2.from_angle(DYSON_HUB_ANGLE) * float(d["dist"])
		base.erase("anchor")
		base.erase("orbit")
		base["name"] = String(d["name"])
		base["art"] = String(d["art"])
		base["planet"] = 0
		for key0 in d:
			if not key0 in ["name", "art", "body", "dist"]:
				base[key0] = d[key0]
		return base
	var parent := {}
	if String(d["body"]).begins_with("#"):
		parent = L["planets"][clampi(int(String(d["body"]).substr(1)), 0, L["planets"].size() - 1)]      # 39d
	for b in L["planets"] + L.get("moons", []):
		if String(b["name"]) == String(d["body"]):
			parent = b
	if parent.is_empty():
		return base
	var off := Vector2.from_angle(0.7 + i * 2.1) * float(d["dist"])
	base["anchor"] = parent["id"]
	base["orbit"] = off.length()
	base["pos"] = (parent["pos"] as Vector2) + off
	base["name"] = String(d["name"])
	base["art"] = String(d["art"])
	base["planet"] = int(parent["planet"]) if parent.has("planet") else L["planets"].find(parent)
	for key in d:
		if not key in ["name", "art", "body", "dist"]:
			base[key] = d[key]
	if d.has("maker"):
		base["shipyard"] = maker_hulls(String(d["maker"]))              # 39d: every ship of the house
	return base


## 39d: every ship a manufacturer sells, smallest first.
static func maker_hulls(mk: String) -> Array:
	var out: Array = []
	for hid in GameData.hulls:
		var h: Dictionary = GameData.hulls[hid]
		if String(h.get("maker", "")) == mk and h["buyable"] and not h.get("drone_only", false) and not h.get("haven_only", false):
			out.append(hid)
	out.sort_custom(func(a, b): return int(GameData.hulls[a]["size"]) < int(GameData.hulls[b]["size"]))
	return out


## Landmarks of a special system that are no stations: the relay stations round The Vote, the Res Publica at the
## Concord Yards … They move with the station they belong to ("anchor").
func _special_structures(L: Dictionary, sp: String) -> void:
	L["structures"] = []
	if sp == "heimkehr":
		_heimkehr_structures(L)
		return
	if sp == "durchbruch":
		_durchbruch_structures(L)
		return
	if sp == "schwarzwacht":
		for st in L["stations"]:
			if String(st.get("art", "")) == "hdy_yard":
				for k in 5:
					var off := Vector2.from_angle(k * TAU / 5.0 + 0.6) * (2700.0 + 450.0 * (k % 2))
					L["structures"].append({"id": "wplat_%d" % k, "name": "", "art": "weapon_platform", "type": "weapon_platform", "tier": 1,
						"seed": 800 + k, "anchor": st["id"], "pos": (st["pos"] as Vector2) + off})
		return
	if sp != "landfall":
		return
	var vote := {}
	var yards := {}
	for st in L["stations"]:
		if String(st.get("art", "")) == "vote":
			vote = st
		elif String(st.get("art", "")) == "concord_yards":
			yards = st
	if not vote.is_empty():
		var offs: Array = []
		for k in VOTE_RELAYS:
			var off := Vector2.from_angle(TAU * k / VOTE_RELAYS + 0.4) * (3400.0 + 500.0 * (k % 2))
			offs.append(off)
			L["structures"].append({"id": "vr_%d" % k, "name": "Vote Relay %s" % ROMAN[k], "art": "vote_relay", "type": "vote_relay",
				"tier": 1, "seed": 400 + k, "anchor": vote["id"], "pos": (vote["pos"] as Vector2) + off})
		vote["relay_offs"] = offs
	if not yards.is_empty():
		var off2 := Vector2(-2010.0, 0.0)               # 0.6.39.2: her stern against the yard's gantries
		L["structures"].append({"id": "res_publica", "name": "Res Publica (under construction)", "art": "res_publica", "type": "res_publica",
			"tier": 1, "seed": 4242, "label_y": -520.0, "anchor": yards["id"], "pos": (yards["pos"] as Vector2) + off2})


const VOTE_RELAYS := 4


## 39c: the Dyson sphere's shell (drawn round the star), the orbital mirrors over Curie, and small jump gates being
## built round the Axiom Yards.
func _durchbruch_structures(L: Dictionary) -> void:
	L["structures"].append({"id": "dyson_shell", "name": "", "art": "dyson_shell", "type": "dyson_shell", "pos": Vector2.ZERO, "seed": 39})
	var curie := {}
	for p in L["planets"]:
		if String(p["name"]) == "Curie":
			curie = p
	if not curie.is_empty():
		for k in 3:
			var off := Vector2.from_angle(k * TAU / 3.0 + 0.5) * float(curie["radius"]) * 1.6
			L["structures"].append({"id": "mirror_%d" % k, "name": "Solar Mirror %s" % ROMAN[k], "art": "mirror", "type": "mirror", "tier": 1,
				"seed": 600 + k, "anchor": curie["id"], "pos": (curie["pos"] as Vector2) + off, "beam_to": curie["id"]})
	for st in L["stations"]:
		if String(st.get("art", "")) == "axiom_yards":
			for k2 in 6:
				var off2 := Vector2.from_angle(k2 * TAU / 6.0 + 0.3) * (2600.0 + 500.0 * (k2 % 2))
				L["structures"].append({"id": "gate_frame_%d" % k2, "name": "", "art": "gate_frame", "type": "gate_frame", "tier": 1,
					"seed": 700 + k2, "anchor": st["id"], "pos": (st["pos"] as Vector2) + off2})


## 39b: the Pilgrim Gate off the Cathedral of Return (it points home, away from the star) and the Lux Aeterna in her
## berth at the Forge of Return.
func _heimkehr_structures(L: Dictionary) -> void:
	for st in L["stations"]:
		match String(st.get("art", "")):
			"cathedral":
				var off := Vector2(4200.0, -2600.0)
				L["structures"].append({"id": "pilgrim_gate", "name": "Pilgrim Gate", "art": "pilgrim_gate", "type": "pilgrim_gate",
					"tier": 1, "seed": 777, "anchor": st["id"], "pos": (st["pos"] as Vector2) + off, "label_y": 640.0})
			"forge":
				L["structures"].append({"id": "lux_aeterna", "name": "Lux Aeterna (under construction)", "art": "lux_aeterna", "type": "lux_aeterna",
					"tier": 1, "seed": 4243, "anchor": st["id"], "pos": (st["pos"] as Vector2) + Vector2(-2050.0, 0.0), "label_y": -560.0})


## Decides type and tier of every station (and Pirate Haven) in the cluster up front, so that every
## station type appears in every tier at least once and the star map can show all economies
## without generating the systems. Stored as systems[i]["stations_plan"] / ["haven_tier"].
func _plan_stations() -> void:
	var prng := RandomNumberGenerator.new()
	prng.seed = seed_value * 31337 + 99
	var slots: Array = []        # [system id, index] still free
	for s in systems:
		var plan: Array = []
		if s["id"] == home_system:
			plan = [["trade", 3], ["military", 2]]
		elif SPECIAL_PLANS.has(String(s.get("special", ""))):
			plan = SPECIAL_PLANS[String(s["special"])].duplicate(true)       # package 39: fixed stations
		else:
			var r := prng.randf()
			var cnt := 0 if r < 0.22 else (1 if r < 0.78 else 2)
			for k in cnt:
				plan.append([])
				slots.append([s["id"], k])
		s["stations_plan"] = plan
		s["haven_tier"] = 0
	# required combinations (the home system already has trade 3 and military 2)
	var required: Array = []
	for t in ALL_STATION_TYPES:
		for tier in [1, 2, 3]:
			if not ((t == "trade" and tier == 3) or (t == "military" and tier == 2)):
				required.append([t, tier])
	_shuffle(required, prng)
	required.sort_custom(func(a, b): return int(a[0] == "shipyard") > int(b[0] == "shipyard"))
	# make sure there are enough slots
	while slots.size() < required.size() + 4:
		var sid := prng.randi() % systems.size()
		var pl: Array = systems[sid]["stations_plan"]
		if sid != home_system and pl.size() < 2:
			pl.append([])
			slots.append([sid, pl.size() - 1])
	_shuffle(slots, prng)
	for combo in required:
		var pick := -1
		for i in slots.size():
			var sys: Dictionary = systems[slots[i][0]]
			if combo[0] == "shipyard" and float(sys["security"]) < 0.4:
				continue
			var dup := false
			for other in sys["stations_plan"]:
				dup = dup or (not other.is_empty() and other[0] == combo[0])
			if dup:
				continue
			pick = i
			break
		if pick < 0:
			pick = 0
		var slot: Array = slots[pick]
		systems[slot[0]]["stations_plan"][slot[1]] = combo
		slots.remove_at(pick)
	# the remaining stations: mostly the six base types, special ones now and then
	for slot2 in slots:
		var sys2: Dictionary = systems[slot2[0]]
		var pool: Array = CommodityData.BASE_STATION_TYPES.duplicate()
		pool.append("ice_refinery")
		if float(sys2["security"]) >= 0.4:
			pool.append("shipyard")
		var t2: String = pool[prng.randi() % pool.size()]
		var x := prng.randf()
		var tier2 := 1 if x < 0.3 else (2 if x < 0.85 else 3)
		sys2["stations_plan"][slot2[1]] = [t2, tier2]
	# Pirate Havens: only in pirate territory (phase 0.5 package 10) – the strongholds of both
	# pirate factions are tier 3 and 2, one more system gets a tier 1 haven, the rest by chance
	var pir: Array = []
	for s3 in systems:
		if s3.get("faction", "") in FactionData.TERRITORIAL_PIRATES:
			pir.append(s3)
	pir.sort_custom(func(a, b): return int(a["id"]) < int(b["id"]))
	var tier_core := 3
	for s4 in pir:
		if s4["capital"]:
			s4["haven_tier"] = tier_core
			tier_core = 2
	var have_one := false
	for s5 in pir:
		if s5["capital"]:
			continue
		if not have_one:
			s5["haven_tier"] = 1
			have_one = true
		elif prng.randf() < 0.5:
			s5["haven_tier"] = prng.randi_range(1, 2)


## Does the system have stations? (from the cluster plan – no layout generation needed)
func has_stations(sid: int) -> bool:
	var s: Dictionary = systems[sid]
	if s.has("stations_plan"):
		return not (s["stations_plan"] as Array).is_empty()
	return not get_layout(sid)["stations"].is_empty()


# ---------------------------------------------------------------- Factions & territory (phase 0.5 package 10)
# Three powers grow outward from their capitals, two pirate factions hold remote corners of the
# cluster, and where powers meet a few systems stay contested. Security follows from the owner
# and the distance to its capital. All deterministic from the seed – nothing of it is saved.
#   systems[i]["faction"]   controlling faction id ("" = contested / independent)
#   systems[i]["claimants"] contested systems: the factions fighting over it
#   systems[i]["capital"]   capital of its faction
#   systems[i]["core_dist"] jumps to the own capital / pirate core

## Jumps between all systems (BFS from every system).
func _hop_table() -> Array:
	var n := systems.size()
	var out: Array = []
	for a in n:
		var d := {a: 0}
		var q: Array = [a]
		while not q.is_empty():
			var cur: int = q.pop_front()
			for nb in systems[cur]["links"]:
				if not d.has(nb):
					d[nb] = int(d[cur]) + 1
					q.append(nb)
		var row: Array = []
		for b in n:
			row.append(int(d.get(b, 99)))
		out.append(row)
	return out


func _assign_territory() -> void:
	var n := systems.size()
	var trng := RandomNumberGenerator.new()
	trng.seed = seed_value * 2654435 + 1013
	var hops := _hop_table()
	for s in systems:
		s["faction"] = ""
		s["claimants"] = []
		s["capital"] = false
		s["core_dist"] = 0
	# capitals: three well-connected systems as far apart from each other as possible
	var cand: Array = []
	for s in systems:
		if (s["links"] as Dictionary).size() >= 2:
			cand.append(int(s["id"]))
	# pass 1: the largest possible minimum distance; pass 2: among good triples, the one that
	# leaves every power enough room (hop-Voronoi regions of similar size)
	var max_mh := 0
	for i in cand.size():
		for j in range(i + 1, cand.size()):
			for k in range(j + 1, cand.size()):
				max_mh = maxi(max_mh, mini(mini(int(hops[cand[i]][cand[j]]), int(hops[cand[i]][cand[k]])), int(hops[cand[j]][cand[k]])))
	var best_score := -INF
	var caps: Array = []
	for i in cand.size():
		for j in range(i + 1, cand.size()):
			for k in range(j + 1, cand.size()):
				var a: int = cand[i]
				var b: int = cand[j]
				var c: int = cand[k]
				var mh := mini(mini(int(hops[a][b]), int(hops[a][c])), int(hops[b][c]))
				if mh < max_mh - 2:
					continue
				var md := minf(minf(_dist(a, b), _dist(a, c)), _dist(b, c))
				var edge := 0.0
				for x in [a, b, c]:
					var p: Vector2 = systems[x]["pos"]
					edge += minf(minf(p.x, MAP_SIZE.x - p.x), minf(p.y, MAP_SIZE.y - p.y))
				var region := [0, 0, 0]
				for sx in n:
					var da: int = hops[sx][a]
					var db: int = hops[sx][b]
					var dc: int = hops[sx][c]
					if da <= db and da <= dc:
						region[0] += 1
					elif db <= dc:
						region[1] += 1
					else:
						region[2] += 1
				var small := mini(mini(region[0], region[1]), region[2])
				var score := mh * 300.0 + small * 150.0 + md * 0.3 + edge * 0.2
				if score > best_score:
					best_score = score
					caps = [a, b, c]
	var powers: Array = FactionData.POWERS.duplicate()
	_shuffle(powers, trng)
	var owner := {}
	for i in 3:
		owner[caps[i]] = powers[i]
		systems[caps[i]]["capital"] = true
	# pirate cores: as far from every capital as possible, and apart from each other
	var pirate_cores: Array = []
	for pf in FactionData.TERRITORIAL_PIRATES:
		var bs := -1.0
		var pick := -1
		for s in systems:
			var sid: int = s["id"]
			if owner.has(sid):
				continue
			var dcap := 99
			for c in caps:
				dcap = mini(dcap, int(hops[sid][c]))
			var dp := 99
			for pc in pirate_cores:
				dp = mini(dp, int(hops[sid][pc]))
			var sc := float(dcap) * 100.0 + float(mini(dp, 4)) * 60.0 - (s["links"] as Dictionary).size() * 5.0 + trng.randf()
			if sc > bs:
				bs = sc
				pick = sid
		pirate_cores.append(pick)
		owner[pick] = pf
		systems[pick]["capital"] = true
	# grow: pirates first (small, tight hideouts), then the powers in turns
	var cores := {}
	for i in 3:
		cores[powers[i]] = caps[i]
	for i in pirate_cores.size():
		cores[FactionData.TERRITORIAL_PIRATES[i]] = pirate_cores[i]
	var count := {}
	for f in cores:
		count[f] = 1
	for pf2 in FactionData.TERRITORIAL_PIRATES:
		while int(count[pf2]) < PIRATE_SYSTEMS:
			var nxt := _territory_candidate(pf2, owner, cores, hops)
			if nxt < 0:
				break
			owner[nxt] = pf2
			count[pf2] = int(count[pf2]) + 1
	var grew := true
	while grew:
		grew = false
		for pw in powers:
			if int(count[pw]) >= POWER_SYSTEMS_MAX:
				continue
			var nxt2 := _territory_candidate(pw, owner, cores, hops)
			if nxt2 < 0:
				continue
			owner[nxt2] = pw
			count[pw] = int(count[pw]) + 1
			grew = true
	# contested borders: frontier systems where two powers meet (farthest from the own capital)
	var front: Array = []
	for sid2 in owner:
		var f2: String = owner[sid2]
		if not f2 in FactionData.POWERS or systems[sid2]["capital"]:
			continue
		var rival := ""
		for nb in systems[sid2]["links"]:
			var o2: String = owner.get(nb, "")
			if o2 != f2 and o2 in FactionData.POWERS:
				rival = o2
		if rival != "":
			front.append([sid2, rival, int(hops[sid2][cores[f2]])])
	front.sort_custom(func(x, y): return x[2] > y[2] if x[2] != y[2] else int(x[0]) < int(y[0]))
	var target_contested := maxi(0, n - POWER_SYSTEMS * 3 - PIRATE_SYSTEMS * 2)
	var contested := 0
	for unclaimed in n:
		if not owner.has(unclaimed):
			contested += 1
	for fr in front:
		var f3: String = owner.get(fr[0], "")
		if f3 == "":
			continue
		var over := false
		for pw2 in powers:
			over = over or int(count[pw2]) > POWER_SYSTEMS
		if contested >= target_contested and not over:
			break
		if int(count[f3]) <= POWER_SYSTEMS and contested >= target_contested:
			continue
		owner.erase(fr[0])
		count[f3] = int(count[f3]) - 1
		systems[fr[0]]["claimants"] = [f3, fr[1]]
		contested += 1
	# write back + security
	for s2 in systems:
		var sid3: int = s2["id"]
		var f4: String = owner.get(sid3, "")
		s2["faction"] = f4
		if f4 == "" and (s2["claimants"] as Array).is_empty():
			var cl: Array = []
			for nb2 in s2["links"]:
				var o3: String = owner.get(nb2, "")
				if o3 != "" and not o3 in cl:
					cl.append(o3)
			cl.sort_custom(func(x, y): return int(x in FactionData.POWERS) > int(y in FactionData.POWERS))
			s2["claimants"] = cl.slice(0, 2)
		var sec := 0.25
		if f4 in FactionData.POWERS:
			var dist: int = hops[sid3][cores[f4]]
			s2["core_dist"] = dist
			sec = 1.0 - 0.1 * dist
			for nb3 in s2["links"]:
				var o4: String = owner.get(nb3, "")
				if o4 in FactionData.PIRATES or o4 == "":
					sec -= 0.07
					break
			sec = clampf(sec + trng.randf_range(-0.04, 0.04), 0.35, 1.0)
			if s2["capital"]:
				sec = 1.0
		elif f4 in FactionData.PIRATES:
			var dist2: int = hops[sid3][cores[f4]]
			s2["core_dist"] = dist2
			sec = clampf(0.03 * dist2 + trng.randf_range(0.0, 0.06), 0.0, 0.15)
		else:
			sec = trng.randf_range(0.18, 0.34)
		s2["security"] = snappedf(sec, 0.01)
	# the pilot starts in a border system of the Assembly (not its capital)
	var best_home := -1
	var best_h := -INF
	for s3 in systems:
		if s3["faction"] != "assembly" or s3["capital"]:
			continue
		var border := false
		for nb4 in s3["links"]:
			border = border or systems[nb4]["faction"] != "assembly"
		var hs := float(s3["security"]) + (1.0 if border else 0.0) - absf(int(s3["core_dist"]) - 2) * 0.2
		if hs > best_h:
			best_h = hs
			best_home = s3["id"]
	if best_home < 0:
		best_home = cores["assembly"]
	home_system = best_home
	systems[home_system]["security"] = maxf(float(systems[home_system]["security"]), 0.7)


## Next system a faction claims: an unowned neighbour of its territory, closest to its core.
func _territory_candidate(f: String, owner: Dictionary, cores: Dictionary, hops: Array) -> int:
	var core: int = cores[f]
	var best := -1
	var bd := INF
	for sid in owner:
		if owner[sid] != f:
			continue
		for nb in systems[sid]["links"]:
			if owner.has(nb):
				continue
			var d := float(hops[nb][core]) * 1000.0 + _dist(nb, core)
			if d < bd:
				bd = d
				best = nb
	return best


## Controlling faction of a system ("" = contested or independent).
func controller(sid: int) -> String:
	if sid < 0 or sid >= systems.size():
		return ""
	return String(systems[sid].get("faction", ""))


func claimants(sid: int) -> Array:
	if sid < 0 or sid >= systems.size():
		return []
	return systems[sid].get("claimants", [])


## "Cluster Assembly", "Contested (Assembly / Covenant)", "Pirate territory – Hollow Crown" …
func territory_text(sid: int) -> String:
	var f := controller(sid)
	if f != "":
		var t := FactionData.name_of(f)
		if FactionData.FACTIONS[f]["kind"] == "pirate":
			t = "Pirate territory – " + t
		if systems[sid].get("capital", false):
			t += " (capital)" if FactionData.FACTIONS[f]["kind"] == "power" else " (stronghold)"
		return t
	var cl := claimants(sid)
	if cl.is_empty():
		return "Independent"
	var names: PackedStringArray = []
	for c in cl:
		names.append(FactionData.short_of(c))
	return "Contested (%s)" % " / ".join(names)


## Faction of a station: the system owner; in contested systems the claimants share the
## stations; stations in pirate territory are independent free ports (only Havens fly the flag).
func station_faction(sid: int, index: int) -> String:
	var f := controller(sid)
	if f in FactionData.POWERS:
		return f
	if f == "":
		var cl: Array = []
		for c in claimants(sid):
			if c in FactionData.POWERS:
				cl.append(c)
		if not cl.is_empty():
			return cl[index % cl.size()]
	return ""


## Which pirate faction a pirate spawned in this system belongs to.
func pirate_faction(sid: int) -> String:
	var f := controller(sid)
	if f in FactionData.TERRITORIAL_PIRATES:
		return f if randf() < 0.8 else "free_captains"
	for c in claimants(sid):
		if c in FactionData.TERRITORIAL_PIRATES and randf() < 0.5:
			return c
	return "free_captains"


## Systems of a faction.
func territory_of(f: String) -> Array:
	var out: Array = []
	for s in systems:
		if s.get("faction", "") == f:
			out.append(int(s["id"]))
	return out


# ---------------------------------------------------------------- Population & traffic (phase 0.5 package 11)

## Inhabitants per planet type (billions): earthlike worlds carry most of the population.
const PLANET_POP := {"terran": 3.0, "desert": 1.0, "ice": 0.8, "toxic": 0.3, "lava": 0.25, "gas": 0.2, "barren": 0.1,
	"ocean": 3.0, "jungle": 3.0, "ice_giant": 0.1, "dwarf": 0.0, "red_gas": 0.2, "metal": 0.6}          # package 38; metal worlds: package 42
## Upper limit of NPC ships in one system (player excluded).
const NPC_CAP := 90                  # package 35: busier systems


## What lives in a system: population (from the planets), stations, and from that the size of
## its traffic – shuttles, miners, patrols, convoy weight and pirate pressure.
func system_profile(sid: int) -> Dictionary:
	# package 42c: prosperity shapes the traffic – rich systems are busier and better patrolled, poor ones draw pirates
	var p := system_profile_raw(sid)
	var lv := Economy.level(sid)
	var k := 0.7 + 0.15 * lv
	p["shuttles"] = int(round(float(p["shuttles"]) * k))
	p["holding"] = int(round(float(p["holding"]) * k))
	p["convoy_weight"] = float(p["convoy_weight"]) * k
	p["pirates"] = maxi(0, int(p["pirates"]) + 2 - lv)
	if lv >= 3 and int(p["patrol_groups"]) > 0:
		p["patrol_groups"] = int(p["patrol_groups"]) + 1
	p["prosperity"] = lv
	return p


## The profile from the system alone (before prosperity – package 42c; the starting prosperity is worked out from it).
func system_profile_raw(sid: int) -> Dictionary:
	var L := get_layout(sid)
	var sys: Dictionary = systems[sid]
	var pop := 0.0
	for p in L["planets"]:
		pop += float(PLANET_POP.get(String(p["type"]), 0.1)) * (1.4 if p.get("ring", false) else 1.0) * (0.6 + float(p.get("seed", 50.0)) / 125.0)
	var tiers := 0
	var trade := 0
	var military := 0
	var mining := 0
	var ice := 0
	for st in L["stations"]:
		var t := int(st["tier"])
		tiers += t
		match String(st["type"]):
			"trade":
				trade += t
			"military":
				military += t
			"mining_colony":
				mining += t
			"ice_refinery":
				ice += t
	var sec := float(sys["security"])
	var ctl := controller(sid)
	var patrol_groups := 0
	var patrol_size := 0
	var patrol_q := 0                 # 0 light … 2 heavy
	if ctl in FactionData.POWERS:
		patrol_groups = 1 + int(military >= 2) + int(sys.get("capital", false)) + int(sec >= 0.8 and tiers >= 3)
		patrol_groups += int(ctl == "assembly" and GameState.senate.mod("patrols") > 1.0)       # package 39: Militia Act
		patrol_groups += int(ctl == "covenant" and GameState.curia.mod("patrols") > 1.0)        # 39b: Crusade, Vigil
		patrol_size = 2 + int(military >= 3)
		patrol_q = clampi(int(military / 2) + int(sys.get("capital", false)), 0, 2)
	elif ctl == "" and not claimants(sid).is_empty():
		for c in claimants(sid):
			patrol_groups += int(c in FactionData.POWERS)
		patrol_size = 2
		patrol_q = clampi(int(military / 2), 0, 1)
	var has_st: bool = not L["stations"].is_empty()
	var nf: int = L["fields"].size()
	var lawful := ctl in FactionData.POWERS or (ctl == "" and patrol_groups > 0)
	return {
		"population": pop,
		"stations": L["stations"].size(), "tiers": tiers, "trade": trade, "military": military,
		"mining": mining, "ice": ice,
		# package 35: the systems are three times as big – about half again as much traffic
		"shuttles": clampi(int(round(pop * 3.0 + tiers * 0.9)), 0, 24) if has_st else 0,
		"miners": clampi((mining + ice) * 3 + nf, 0, 16) if mining + ice > 0 else (nf + 1 if nf > 0 else 0),
		# loiterers (they stay around one place): haulers holding near stations, field patrols, gate pickets
		"holding": clampi(tiers * 2 + 1, 0, 12) if has_st else 0,
		"field_patrols": mini(nf, 4) if lawful else 0,
		"pickets": mini(L["gates"].size(), 3) if ctl in FactionData.POWERS else 0,
		"patrol_groups": patrol_groups, "patrol_size": patrol_size, "patrol_quality": patrol_q,
		"convoy_weight": trade * 2.0 + (tiers - trade) * 0.5,
		"pirates": int(round((1.0 - sec) * 5.5)),
	}


## Short traffic rating for the map ("busy" …).
static func traffic_word(p: Dictionary) -> String:
	var v := int(p["shuttles"]) + int(p["miners"]) + int(p["patrol_groups"]) * 2 + int(p.get("holding", 0)) + int(p.get("field_patrols", 0)) * 2 + int(p.get("pickets", 0))
	if v >= 30:
		return "very busy"
	if v >= 15:
		return "busy"
	if v >= 3:
		return "moderate"
	return "quiet" if v > 0 else "deserted"



static func _shuffle(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var tmp = a[i]
		a[i] = a[j]
		a[j] = tmp


# ---------------------------------------------------------------- Debug test system
# A single system without gates that contains every station type (plus tier 1–3 Trade Hubs),
# a Pirate Haven, every planet type, all three asteroid field classes with every ore, every
# asteroid shape and size, and colossi in all class/shape combinations. Only reachable from the
# main menu in debug builds; it is never saved and does not touch the generated galaxy.

## Test system: every station type in tiers 1, 2 and 3 (three rings, one spoke per type).
const TEST_RING := [900000.0, 1150000.0, 1400000.0]


func generate_test() -> void:
	Economy.clear_cache()                 # package 42
	Market.clear_cache()
	seed_value = 777
	systems.clear()
	layouts.clear()
	orbit_phase.clear()
	systems.append({"id": 0, "name": "Testfeld", "pos": MAP_SIZE * 0.5, "security": 0.5, "star": 0, "links": {},
		"faction": "", "claimants": ["assembly", "covenant"], "capital": false, "core_dist": 0})
	home_system = 0
	test_mode = true
	layouts[0] = build_test_layout()


## The test system's layout (pure: reads only seed_value for the scenery).
func build_test_layout() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	var st_type: Dictionary = STAR_TYPES[star_index("G")]
	var L := {
		"star": {"id": "star", "name": "Testfeld", "type": st_type["name"], "color": st_type["color"],
			"radius": float(st_type["radius"]), "pos": Vector2.ZERO},
		"planets": [], "stations": [], "gates": [], "fields": [], "asteroids": [], "anomalies": [], "colossi": [], "havens": [],
	}
	# every planet type in a row
	var ptypes: Array = PLANET_TYPES.keys()
	for i in ptypes.size():
		var pt: String = ptypes[i]
		var big := float(PLANET_TYPES[pt].get("big", 1.0)) > 1.5
		var pos := Vector2.from_angle(-PI * 0.5 + i * TAU / ptypes.size()) * 600000.0
		L["planets"].append({
			"id": "p%d" % i, "name": "Testfeld %d – %s" % [i + 1, PLANET_TYPES[pt]["name"]], "type": pt,
			"orbit": pos.length(), "pos": pos, "radius": 22000.0 if big else 9000.0, "city": 0.8 if pt in CITY_WORLDS else 0.0,
			"seed": 10.0 + i * 7.0, "ring": big,
		})
	# package 36: one moon of every type round the first gas giant
	L["moons"] = []
	for pi in L["planets"].size():
		if String(L["planets"][pi]["type"]) == "gas":
			var gp: Dictionary = L["planets"][pi]
			var mk := 0
			for mt in MOON_TYPES:
				var mpos: Vector2 = (gp["pos"] as Vector2) + Vector2.from_angle(mk * TAU / MOON_TYPES.size()) * (80000.0 + mk * 30000.0)
				L["moons"].append({"id": "m%d_%d" % [pi, mk], "planet": pi, "name": "%s-%s" % [gp["name"], MOON_LETTERS[mk]], "type": mt,
					"radius": 4000.0, "orbit": 80000.0 + mk * 30000.0, "pos": mpos, "seed": 20.0 + mk * 5.0})
				mk += 1
			break
	# every station type in every tier: tier 1 on the inner ring, tier 3 on the outer one
	var n_types := ALL_STATION_TYPES.size()
	for tier in [1, 2, 3]:
		for i in n_types:
			var type: String = ALL_STATION_TYPES[i]
			var pos2 := Vector2.from_angle(PI * 0.5 + i * TAU / n_types) * float(TEST_RING[tier - 1])
			L["stations"].append({
				"id": "st_0_%d" % L["stations"].size(), "planet": 0,
				"name": "Testfeld – %s (T%d)" % [CommodityData.STATION_TYPES[type]["name"], tier],
				"type": type, "tier": tier, "pos": pos2,
				"market": _make_market(type, rng), "shop": _make_shop(type, tier, rng), "shipyard": _make_shipyard(type, tier, true),
				"seed": 1000 + i * 37, "zone": NO_FIRE_ZONE[tier - 1],
				"faction": FactionData.POWERS[(i + tier) % 3],
			})
	for stf in L["stations"]:
		_add_faction_yard(stf)
	# move the tier-3 Trade Hub to the front: the pilot starts there
	var start: Dictionary = L["stations"][2 * n_types]
	L["stations"].remove_at(2 * n_types)
	L["stations"].insert(0, start)
	for k in L["stations"].size():
		L["stations"][k]["id"] = "st_0_%d" % k
	# package 26: a waystation of every tier
	for wt in [1, 2, 3]:
		L["stations"].append({
			"id": "st_0_%d" % L["stations"].size(), "planet": 0,
			"name": "Testfeld – Waystation (T%d)" % wt, "type": "waystation", "tier": wt,
			"pos": Vector2.from_angle(-PI * 0.5 + 0.25 * wt) * 1300000.0,
			"market": _make_market("waystation", rng), "shop": [], "shipyard": [],
			"seed": 2000 + wt, "zone": NO_FIRE_ZONE[wt - 1], "faction": FactionData.POWERS[wt % 3],
		})
	# Pirate Havens of all tiers on the edge (between the asteroid fields)
	for tier2 in [1, 2, 3]:
		L["havens"].append({"id": "ph_0_%d" % tier2, "name": "Rustmaw T%d (Test)" % tier2, "type": "pirate_haven", "tier": tier2,
			"pos": Vector2.from_angle([0.35, PI, PI * 1.5][tier2 - 1]) * 1780000.0, "seed": 4242 + tier2,
			"faction": FactionData.PIRATES[tier2 - 1]})
		_haven_services(L["havens"].back(), 0)
	# one field per asteroid class with every ore of that class; colossi in all three shapes
	for b in FIELD_CLASSES.size():
		var cls: String = FIELD_CLASSES[b]
		var mix := {}
		for cid in CommodityData.COMMODITIES:
			var c: Dictionary = CommodityData.COMMODITIES[cid]
			if c.get("category", "") == "ore" and c["class"] == cls:
				mix[cid] = {"common": 3.0, "uncommon": 1.5, "rare": 1.0}[c["rarity"]]
		var fid := "f%d" % b
		var fc := Vector2.from_angle(PI * 0.75 + b * PI * 0.5) * 1750000.0
		var fr := 14000.0
		L["fields"].append({"id": fid, "name": "Test Field %s (%s)" % [ROMAN[b], cls.capitalize()],
			"class": cls, "ores": mix.keys(), "ore": mix.keys()[0], "pos": fc, "radius": fr})
		var clumps: Array = []
		for k in 6:
			clumps.append([fc + Vector2.from_angle(k * TAU / 6.0 + 0.3) * fr * rng.randf_range(0.25, 0.6), rng.randf_range(900.0, 1800.0)])
		for k in 180:
			var clump: Array = clumps[k % clumps.size()]
			var ap: Vector2 = clump[0] + Vector2.from_angle(rng.randf() * TAU) * pow(rng.randf(), 0.7) * float(clump[1])
			L["asteroids"].append(_make_asteroid("a_%d_%d" % [b, k], fid, cls, mix, ap, rng))
		var tshapes: Array = ColossusShape.shapes_for(cls)        # 0.6.35.5: every shape of this kind of rock
		for k in tshapes.size():
			var shape: String = tshapes[k]
			var R := rng.randf_range(900.0, 1300.0)
			var cpos := fc + Vector2.from_angle(-1.2 + k * 0.6 + PI) * fr * 0.78
			var tore := _roll_ore(mix, rng)
			L["colossi"].append({
				"id": "col_%d_%d" % [b, k], "name": "Colossus T-%d%d" % [b + 1, k + 1], "class": cls, "ore": tore,
				"pos": cpos, "radius": R, "shape": shape, "poly": ColossusShape.generate(shape, R, rng), "seed": rng.randi(), "field": fid,
				"mix": {tore: 1.0}, "amount": roundf(R * 55.0), "amount0": roundf(R * 55.0),
			})
	# a few anomalies, already revealed
	for k in 3:
		L["anomalies"].append({
			"id": "an_%d" % k, "name": ANOMALY_NAMES[k % ANOMALY_NAMES.size()],
			"pos": Vector2.from_angle(PI * 0.1 + k * 0.5) * 420000.0,
			"difficulty": 10.0 + k * 15.0, "scan": 100.0, "revealed": true, "analysis": 0.0, "done": false,
		})
	_scatter_loose(L, 0, 0.5)
	_clear_colossi(L)
	return L


# ---------------------------------------------------------------- Save / load
# The galaxy itself is regenerated from the seed; only what changed is stored:
# remaining asteroid deposits and the scan/analysis state of anomalies.

func to_dict() -> Dictionary:
	var changed := {}
	for id in layouts:
		var L: Dictionary = layouts[id]
		var ast := {}
		var gone := {}
		for a in L["asteroids"]:
			ast[a["id"]] = a["amount"]
			if a.has("gone"):
				gone[a["id"]] = float(a.get("respawn_at", 0.0))
		var cols := {}
		var deep := {}
		for co in L.get("colossi", []):
			cols[co["id"]] = co.get("amount", 0.0)
			if co.has("deep_amount"):
				deep[co["id"]] = co["deep_amount"]                  # package 41
		var an := {}
		for x in L["anomalies"]:
			an[x["id"]] = {"scan": x["scan"], "revealed": x["revealed"], "analysis": x["analysis"], "done": x["done"]}
		changed[id] = {"asteroids": ast, "anomalies": an, "gone": gone, "colossi": cols, "deep": deep}
	return {"seed": seed_value, "version": GALAXY_VERSION, "layouts": changed, "orbits": orbit_phase.duplicate()}


func from_dict(d: Dictionary) -> void:
	generate(int(d["seed"]))
	for k in d.get("orbits", {}):                     # package 36: planets and moons where they were
		orbit_phase[int(k)] = int(d["orbits"][k])
	var changed: Dictionary = d.get("layouts", {})
	for id in changed:
		var L := get_layout(int(id))
		var ast: Dictionary = changed[id]["asteroids"]
		var gone: Dictionary = changed[id].get("gone", {})
		for a in L["asteroids"]:
			if ast.has(a["id"]):
				a["amount"] = ast[a["id"]]
			if gone.has(a["id"]):
				a["gone"] = true
				a["respawn_at"] = gone[a["id"]]
		var cols: Dictionary = changed[id].get("colossi", {})
		var deep: Dictionary = changed[id].get("deep", {})
		for co in L.get("colossi", []):
			if cols.has(co["id"]):
				co["amount"] = cols[co["id"]]
			if deep.has(co["id"]):
				co["deep_amount"] = deep[co["id"]]
		var an: Dictionary = changed[id]["anomalies"]
		for x in L["anomalies"]:
			if an.has(x["id"]):
				x.merge(an[x["id"]], true)


func _dist(a: int, b: int) -> float:
	return (systems[a]["pos"] as Vector2).distance_to(systems[b]["pos"])


func _link(a: int, b: int) -> void:
	var d := _dist(a, b)
	var cls := 1
	if d >= 340.0:
		cls = 3
	elif d >= 250.0:
		cls = 2
	systems[a]["links"][b] = cls
	systems[b]["links"][a] = cls


func _build_routes(rng: RandomNumberGenerator) -> void:
	# Minimum spanning tree (Prim) guarantees that every system is reachable.
	var n := systems.size()
	var in_tree := {0: true}
	while in_tree.size() < n:
		var best_d := INF
		var ba := -1
		var bb := -1
		for a in in_tree.keys():
			for b in n:
				if in_tree.has(b):
					continue
				var d := _dist(a, b)
				if d < best_d:
					best_d = d
					ba = a
					bb = b
		_link(ba, bb)
		in_tree[bb] = true
	# Extra connections create loops / alternative routes.
	for a in n:
		var cand: Array = []
		for b in n:
			if b != a and not systems[a]["links"].has(b):
				cand.append(b)
		cand.sort_custom(func(x, y): return _dist(a, x) < _dist(a, y))
		if cand.is_empty():
			continue
		var c: int = cand[0]
		if systems[a]["links"].size() < 3 and systems[c]["links"].size() < 4 and _dist(a, c) < 360.0 and rng.randf() < 0.75:
			_link(a, c)


## Shortest route (number of jumps), only via routes with class <= max_class.
## Returns the list of systems excluding the start system; [] if unreachable.
func find_path(from: int, to: int, max_class: int) -> Array:
	if from == to:
		return []
	var prev := {from: -1}
	var queue: Array = [from]
	while not queue.is_empty():
		var cur: int = queue.pop_front()
		if cur == to:
			break
		for nb in systems[cur]["links"]:
			if prev.has(nb):
				continue
			if int(systems[cur]["links"][nb]) > max_class:
				continue
			prev[nb] = cur
			queue.append(nb)
	if not prev.has(to):
		return []
	var path: Array = []
	var c := to
	while c != from:
		path.push_front(c)
		c = prev[c]
	return path


func route_class(a: int, b: int) -> int:
	return int(systems[a]["links"].get(b, 99))


func get_layout(id: int) -> Dictionary:
	if not layouts.has(id):
		layouts[id] = _generate_layout(id)
	return layouts[id]


func get_gate_pos(system_id: int, to_id: int) -> Vector2:
	for g in get_layout(system_id)["gates"]:
		if int(g["to"]) == to_id:
			return g["pos"]
	return Vector2.ZERO


func find_station(system_id: int, station_id: String) -> Dictionary:
	var L := get_layout(system_id)
	for st in L["stations"]:
		if st["id"] == station_id:
			Economy.prepare_station(st, system_id)          # package 42c: the outfitter's stock follows the economy
			return st
	for ph in L.get("havens", []):
		if ph["id"] == station_id:
			return ph
	return {}


## Package 38: every planet type, drawn by the planet shader. a/b/c = low/mid/high colours (for the habitable worlds a
## is the sea), atmo = rim of the atmosphere, gas = banded giant; sea = share under water; clouds, caps (polar caps),
## lava (glowing flows), storms (big vortices), craters – how strongly; cloud = cloud colour; big = size factor;
## r_earth / m_earth / temp / text: what the collection shows.
const PLANET_TYPES := {
	"terran": {"name": "Terran", "a": Color(0.13, 0.28, 0.58), "b": Color(0.3, 0.55, 0.28), "c": Color(0.6, 0.56, 0.42), "atmo": Color(0.5, 0.75, 1.0, 0.8), "gas": 0.0,
		"sea": 0.5, "clouds": 0.55, "caps": 0.6, "cloud": Color(1, 1, 1), "big": 1.0,
		"r_earth": "1", "m_earth": "1", "temp": "15 °C", "text": "Oceans, continents, clouds and ice at the poles – the kind of world humanity was made for, and the first it settles. On the night side the cities shine."},
	"ocean": {"name": "Ocean World", "a": Color(0.06, 0.2, 0.5), "b": Color(0.2, 0.5, 0.42), "c": Color(0.85, 0.82, 0.62), "atmo": Color(0.45, 0.72, 1.0, 0.85), "gas": 0.0,
		"sea": 0.8, "clouds": 0.75, "caps": 0.45, "cloud": Color(1, 1, 1), "big": 1.15,
		"r_earth": "1.3", "m_earth": "2", "temp": "17 °C", "text": "Water to the horizon and beyond – only chains of islands break the surface. Floating towns and island cities; dense clouds and storms."},
	"jungle": {"name": "Jungle World", "a": Color(0.08, 0.26, 0.4), "b": Color(0.12, 0.42, 0.14), "c": Color(0.3, 0.58, 0.22), "atmo": Color(0.55, 0.9, 0.7, 0.8), "gas": 0.0,
		"sea": 0.32, "clouds": 0.85, "caps": 0.15, "cloud": Color(0.95, 1.0, 0.96), "big": 1.0,
		"r_earth": "1.05", "m_earth": "1.1", "temp": "28 °C", "text": "Hot, wet and green from pole to pole. Rain clouds hang over endless forests; the settlements cling to the rivers and coasts."},
	"desert": {"name": "Desert World", "a": Color(0.62, 0.38, 0.22), "b": Color(0.85, 0.62, 0.36), "c": Color(0.95, 0.85, 0.6), "atmo": Color(1.0, 0.8, 0.5, 0.45), "gas": 0.0,
		"sea": 0.0, "clouds": 0.12, "caps": 0.3, "cloud": Color(0.95, 0.86, 0.72), "craters": 0.12, "big": 1.0,
		"r_earth": "0.9", "m_earth": "0.8", "temp": "45 °C", "text": "Dunes, salt flats and canyons under a thin, dusty sky. Water is worth more than fuel here."},
	"ice": {"name": "Ice World", "a": Color(0.45, 0.62, 0.8), "b": Color(0.75, 0.87, 0.97), "c": Color(1.0, 1.0, 1.0), "atmo": Color(0.75, 0.9, 1.0, 0.5), "gas": 0.0,
		"sea": 0.0, "clouds": 0.25, "caps": 0.0, "cloud": Color(1, 1, 1), "craters": 0.2, "big": 1.0,
		"r_earth": "0.8", "m_earth": "0.5", "temp": "−75 °C", "text": "A world buried under kilometres of ice, crossed by blue cracks. Under the ice there may be oceans."},
	"lava": {"name": "Lava World", "a": Color(1.0, 0.45, 0.1), "b": Color(0.28, 0.13, 0.1), "c": Color(0.15, 0.08, 0.07), "atmo": Color(1.0, 0.4, 0.2, 0.5), "gas": 0.0,
		"sea": 0.0, "clouds": 0.0, "lava": 1.0, "big": 1.0,
		"r_earth": "1.1", "m_earth": "1.3", "temp": "900 °C", "text": "So close to its star that the rock melts. Rivers of lava glow through a black crust – on the night side too."},
	"barren": {"name": "Barren Rock", "a": Color(0.33, 0.32, 0.34), "b": Color(0.48, 0.47, 0.47), "c": Color(0.64, 0.62, 0.6), "atmo": Color(0.0, 0.0, 0.0, 0.0), "gas": 0.0,
		"sea": 0.0, "clouds": 0.0, "craters": 1.0, "big": 1.0,
		"r_earth": "0.4", "m_earth": "0.1", "temp": "−60 °C", "text": "No air, no water – only rock and the craters of four billion years of impacts. Good for mines, bad for everything else."},
	"gas": {"name": "Gas Giant", "a": Color(0.68, 0.48, 0.32), "b": Color(0.86, 0.7, 0.5), "c": Color(0.96, 0.9, 0.76), "atmo": Color(1.0, 0.85, 0.6, 0.4), "gas": 1.0,
		"storms": 1.0, "big": 2.6,
		"r_earth": "11", "m_earth": "318", "temp": "−110 °C", "text": "A giant of hydrogen and helium without a surface: bands of cloud racing round it, storms bigger than whole worlds."},
	# 0.6.39.5: the red gas giant (first seen as Compline in Heimkehr) – a planet type of its own
	"red_gas": {"name": "Red Gas Giant", "a": Color(0.58, 0.06, 0.02), "b": Color(0.73, 0.16, 0.13), "c": Color(0.82, 0.42, 0.38), "atmo": Color(1.0, 0.4, 0.3, 0.4), "gas": 1.0,
		"storms": 1.0, "big": 2.8,
		"r_earth": "13", "m_earth": "420", "temp": "−40 °C", "text": "A giant the colour of embers: sulphur and phosphorus haze stain its bands deep red. Pilgrims say it burns for the road home."},
	"toxic": {"name": "Toxic Gas Giant", "a": Color(0.35, 0.5, 0.18), "b": Color(0.58, 0.74, 0.3), "c": Color(0.82, 0.88, 0.45), "atmo": Color(0.7, 1.0, 0.4, 0.55), "gas": 1.0,
		"storms": 0.6, "big": 2.6,
		"r_earth": "9", "m_earth": "95", "temp": "−130 °C", "text": "A gas giant with poisonous clouds of sulphur and ammonia. Its green-yellow glow can be seen from far away."},
	"ice_giant": {"name": "Ice Giant", "a": Color(0.18, 0.45, 0.62), "b": Color(0.3, 0.68, 0.78), "c": Color(0.62, 0.9, 0.92), "atmo": Color(0.55, 0.9, 1.0, 0.5), "gas": 1.0,
		"storms": 0.5, "big": 2.0, "faint": 1.0,
		"r_earth": "4", "m_earth": "15", "temp": "−200 °C", "text": "Smaller than a gas giant, colder, and blue from the methane in its air. Under the clouds lie oceans of water, ammonia and ice."},
	# package 42: the metal world – ore lies open at the surface (mining)
	"metal": {"name": "Metal World", "a": Color(0.2, 0.2, 0.23), "b": Color(0.38, 0.36, 0.37), "c": Color(0.55, 0.47, 0.4), "atmo": Color(0.85, 0.75, 0.65, 0.18), "gas": 0.0,
		"sea": 0.0, "clouds": 0.08, "cloud": Color(0.8, 0.75, 0.7), "craters": 0.45, "metal": 1.0, "big": 1.0,
		"r_earth": "0.95", "m_earth": "1.9", "temp": "60 °C", "text": "A dense iron world whose crust is laced with ore: veins of copper and silver run open at the surface and glint in the sun. Prospectors' paradise – the whole planet is one mine."},
	"dwarf": {"name": "Dwarf Planet", "a": Color(0.42, 0.36, 0.32), "b": Color(0.62, 0.55, 0.5), "c": Color(0.9, 0.88, 0.86), "atmo": Color(0.0, 0.0, 0.0, 0.0), "gas": 0.0,
		"sea": 0.0, "caps": 0.0, "craters": 0.8, "big": 1.0,
		"r_earth": "0.18", "m_earth": "0.002", "temp": "−230 °C", "text": "Too small to clear its orbit: a little world of rock and frozen nitrogen far out in the Kuiper belt. Waystations like its quiet."},
}
## Package 38: dwarf planets per system with a Kuiper belt, and how often a waystation sits at one.
const DWARF_COUNT := Vector2i(1, 2)
const DWARF_WAYSTATION := 0.4


## Package 36: moons. Drawn with the planet shader (plus craters, a lumpy outline or glowing volcanoes);
## far bigger than colossi (3,000–7,800 km radius, at most two thirds of their planet), no radar shadow. "cls" = rock class of a field next to the moon.
const MOON_TYPES := {
	"moon_rock": {"name": "Rocky Moon", "a": Color(0.3, 0.29, 0.3), "b": Color(0.46, 0.45, 0.44), "c": Color(0.63, 0.61, 0.59),
		"atmo": Color(0, 0, 0, 0), "gas": 0.0, "craters": 1.0, "lumpy": 0.0, "glow": 0.0, "cls": "stony", "r_earth": "0.27", "m_earth": "0.012", "temp": "−20 °C", "text": "A grey ball of rock covered in craters – most moons look like this.",
		"r": Vector2(3000, 6000)},
	"moon_ice": {"name": "Ice Moon", "a": Color(0.5, 0.62, 0.76), "b": Color(0.78, 0.86, 0.94), "c": Color(0.97, 0.98, 1.0),
		"atmo": Color(0.8, 0.9, 1.0, 0.25), "gas": 0.0, "craters": 0.55, "lumpy": 0.0, "glow": 0.0, "cls": "icy", "r_earth": "0.25", "m_earth": "0.008", "temp": "−160 °C", "text": "A shell of ice over a frozen – or hidden liquid – sea; cracks run across its face.",
		"r": Vector2(3000, 6500)},
	"moon_volcanic": {"name": "Volcanic Moon", "a": Color(0.92, 0.74, 0.26), "b": Color(0.78, 0.46, 0.16), "c": Color(0.24, 0.14, 0.09),
		"atmo": Color(1.0, 0.65, 0.3, 0.22), "gas": 0.0, "craters": 0.0, "lumpy": 0.0, "glow": 1.0, "cls": "metallic", "r_earth": "0.29", "m_earth": "0.015", "temp": "−130 °C", "text": "Squeezed by its planet's tides until its insides melt: sulphur volcanoes glow on its surface.",
		"r": Vector2(3500, 6500)},
	"moon_captured": {"name": "Captured Asteroid", "a": Color(0.2, 0.18, 0.17), "b": Color(0.3, 0.27, 0.25), "c": Color(0.43, 0.4, 0.37),
		"atmo": Color(0, 0, 0, 0), "gas": 0.0, "craters": 1.0, "lumpy": 1.0, "glow": 0.0, "cls": "metallic", "r_earth": "0.03", "m_earth": "0.00001", "temp": "−80 °C", "text": "Not a true moon but an asteroid its planet caught – lumpy, dark and scarred.",
		"r": Vector2(3000, 4500)},
}
const MOON_LETTERS := ["a", "b", "c", "d"]
## How many moons a planet type gets: [chance of 0, of 1, of 2, of 3].
const MOON_COUNT := {
	"gas": [0.0, 0.0, 0.55, 1.0], "toxic": [0.0, 0.0, 0.6, 1.0], "ice_giant": [0.0, 0.0, 0.6, 1.0], "red_gas": [0.0, 0.0, 0.55, 1.0],
	"ocean": [0.4, 0.85, 1.0, 1.0], "jungle": [0.3, 0.8, 1.0, 1.0], "dwarf": [1.0, 1.0, 1.0, 1.0],
	"terran": [0.25, 0.75, 1.0, 1.0], "desert": [0.3, 0.8, 1.0, 1.0], "ice": [0.3, 0.8, 1.0, 1.0],
	"lava": [0.85, 1.0, 1.0, 1.0], "barren": [0.8, 1.0, 1.0, 1.0], "metal": [0.7, 1.0, 1.0, 1.0],
}
const MOON_STATION_SHARE := 0.35     # share of planet stations that orbit one of its moons instead
const MOON_FIELD_SHARE := 0.25       # share of moons with a small asteroid field next to them


## Colours and look of a planet or moon type (for the sprite).
static func body_type(t: String) -> Dictionary:
	return PLANET_TYPES[t] if PLANET_TYPES.has(t) else MOON_TYPES.get(t, PLANET_TYPES["barren"])


## Moons of every planet (own RNG). Moon "orbit" = distance from its planet, "angle" set by _place_orbits.
func _make_moons(L: Dictionary, id: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 33113 + id * 6151 + 36
	L["moons"] = []
	var mtypes: Array = MOON_TYPES.keys()
	for pi in L["planets"].size():
		var p: Dictionary = L["planets"][pi]
		var odds: Array = MOON_COUNT.get(String(p["type"]), [1.0, 1.0, 1.0, 1.0])
		var roll := rng.randf()
		var n := 0
		while n < 3 and roll >= float(odds[n]):
			n += 1
		var orbit := float(p["radius"]) * 2.6 + rng.randf_range(22000.0, 32000.0)
		for k in n:
			var mt: String = mtypes[rng.randi() % mtypes.size()]
			if String(p["type"]) in ["ice"] and rng.randf() < 0.5:
				mt = "moon_ice"
			var rr: Vector2 = MOON_TYPES[mt]["r"]
			var mr := rng.randf_range(rr.x, rr.y) * (1.2 if String(p["type"]) in ["gas", "toxic", "ice_giant", "red_gas"] else 1.0)
			mr = clampf(mr, 3000.0, maxf(3000.0, float(p["radius"]) * 0.65))
			orbit += mr
			L["moons"].append({
				"id": "m%d_%d" % [pi, k], "planet": pi, "name": "%s-%s" % [p["name"], MOON_LETTERS[k]],
				"type": mt, "radius": mr, "orbit": orbit, "pos": p["pos"], "seed": rng.randf_range(0.0, 100.0),
			})
			orbit += mr + rng.randf_range(20000.0, 34000.0)


## Moons of planet `pi`.
static func moons_of(L: Dictionary, pi: int) -> Array:
	return L.get("moons", []).filter(func(m): return int(m["planet"]) == pi)


## Package 36: a small asteroid field next to some moons (own RNG); it moves with its moon.
func _moon_fields(L: Dictionary, id: int, sec: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 27449 + id * 8317 + 36
	var b: int = L["fields"].size()
	for m in L.get("moons", []):
		if rng.randf() >= MOON_FIELD_SHARE:
			continue
		var cls: String = String(body_type(String(m["type"])).get("cls", PLANET_ROCK_CLASS.get(String(m["type"]), "stony")))      # 0.6.39.7: moons of a planet type
		var mix := _field_mix(cls, sec, rng)
		var fr := rng.randf_range(4000.0, 7000.0)
		var off := Vector2.from_angle(rng.randf() * TAU) * (float(m["radius"]) + fr + rng.randf_range(2500.0, 6000.0))
		var center: Vector2 = (m["pos"] as Vector2) + off
		var fid := "f%d" % b
		L["fields"].append({"id": fid, "name": "%s Field (%s)" % [m["name"], cls.capitalize()], "class": cls, "ores": mix.keys(),
			"ore": mix.keys()[0], "pos": center, "radius": fr, "style": "scattered", "moon": m["id"], "anchor": m["id"]})
		var w: Vector2 = FIELD_STYLES["scattered"]["weights"]
		for k in rng.randi_range(45, 90):
			var pos := center + Vector2.from_angle(rng.randf() * TAU) * pow(rng.randf(), 0.75) * fr
			var ast := _make_asteroid("a_%d_%d" % [b, k], fid, cls, mix, pos, rng, w)
			ast["anchor"] = m["id"]
			L["asteroids"].append(ast)
		b += 1


# ------------------------------------------------------------------ orbits (package 36)

## Orbit phase per system: the planets and moons stand somewhere else on their orbits each time the pilot jumps in
## (the illusion that they move). Saved, so a loaded game finds everything where it was.
var orbit_phase: Dictionary = {}


## A new random place on the orbits for system `sid` (on arrival by jump or wormhole).
func roll_orbits(sid: int) -> void:
	orbit_phase[sid] = randi()
	if layouts.has(sid):
		_place_orbits(layouts[sid], sid)


func _default_phase(sid: int) -> int:
	return seed_value * 15013 + sid * 911 + 36


## Puts planets on their orbit round the star, moons on theirs round the planet and stations on theirs round their
## planet or moon (0.6.36.5), then moves everything anchored to them (ring rocks, moon fields, rocks at stations) along. A planet keeps clear of gates, the belt fields, havens and
## waystations.
func _place_orbits(L: Dictionary, sid: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(orbit_phase.get(sid, _default_phase(sid)))
	var moved := {}                                    # body id -> delta
	var keep_off: Array = []                           # [pos, radius]
	for g in L["gates"]:
		keep_off.append([g["pos"], 30000.0])
	for f in L["fields"]:
		if not f.has("moon"):
			keep_off.append([f["pos"], float(f["radius"]) + 15000.0])
	for hv in L.get("havens", []):
		keep_off.append([hv["pos"], 40000.0])
	for st in L["stations"]:
		if String(st.get("anchor", "")) == "":
			keep_off.append([st["pos"], 40000.0])
	for pi in L["planets"].size():
		var p: Dictionary = L["planets"][pi]
		var reach := float(p["radius"]) * 2.4
		for m in moons_of(L, pi):
			reach = maxf(reach, float(m["orbit"]) + float(m["radius"]) + 14000.0)
		var orbit := float(p["orbit"])
		var best := Vector2.from_angle(rng.randf() * TAU) * orbit
		var best_gap := -INF
		for attempt in 40:
			var cand := best if attempt == 0 else Vector2.from_angle(rng.randf() * TAU) * orbit
			var gap := INF
			for ko in keep_off:
				gap = minf(gap, cand.distance_to(ko[0]) - float(ko[1]) - reach)
			if gap > best_gap:
				best_gap = gap
				best = cand
			if gap > 0.0:
				break
		moved[p["id"]] = best - (p["pos"] as Vector2)
		p["pos"] = best
		for m in moons_of(L, pi):
			var mp: Vector2 = best + Vector2.from_angle(rng.randf() * TAU) * float(m["orbit"])
			moved[m["id"]] = mp - (m["pos"] as Vector2)
			m["pos"] = mp
	# 0.6.36.5: stations on their own orbit round their planet or moon – a new place on it each time; two stations
	# of one body keep well apart
	var taken := {}                                    # body id -> angles in use
	for st in L["stations"]:
		if not st.has("orbit"):
			continue
		var par := body_by_id(L, String(st.get("anchor", "")))
		if par.is_empty():
			continue
		var used_a: Array = taken.get(par["id"], [])
		var ang := rng.randf() * TAU
		for attempt in 12:
			var ok := true
			for ua in used_a:
				ok = ok and absf(wrapf(ang - float(ua), -PI, PI)) > 1.2
			if ok:
				break
			ang = rng.randf() * TAU
		used_a.append(ang)
		taken[par["id"]] = used_a
		var sp: Vector2 = (par["pos"] as Vector2) + Vector2.from_angle(ang) * float(st["orbit"])
		moved[st["id"]] = sp - (st["pos"] as Vector2)
		st["pos"] = sp
	for key in ["fields", "asteroids", "debris", "structures"]:
		for o in L.get(key, []):
			var anc := String(o.get("anchor", ""))
			if anc != "" and moved.has(anc):
				o["pos"] = (o["pos"] as Vector2) + (moved[anc] as Vector2)


## Name of a planet or moon by id ("p2", "m2_0").
static func body_by_id(L: Dictionary, bid: String) -> Dictionary:
	for b in L["planets"] + L.get("moons", []):
		if String(b["id"]) == bid:
			return b
	return {}


## Layout of a system (all positions in km, star at the origin):
## star, planets, stations, gates, fields (asteroid fields), asteroids, anomalies (hidden)
func _generate_layout(id: int) -> Dictionary:
	var sys: Dictionary = systems[id]
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 7919 + id * 104729
	var sec: float = sys["security"]
	var st_type: Dictionary = STAR_TYPES[sys["star"]]
	var L := {
		"star": {"id": "star", "name": sys["name"], "type": st_type["name"], "color": st_type["color"],
			"radius": float(st_type["radius"]), "pos": Vector2.ZERO, "star_id": st_type["id"], "kind": st_type["kind"],
			"color2": st_type["color2"], "seed": float(id) * 3.7 + 1.0},
		"planets": [], "stations": [], "gates": [], "fields": [], "asteroids": [], "anomalies": [], "colossi": [], "havens": [],
	}
	var used: Array = []
	var sp := String(sys.get("special", ""))           # package 39: a hand-made system
	# Planets
	var planet_count := rng.randi_range(3, 6)
	if sp != "" and SPECIAL_BODIES.has(sp):
		planet_count = 0
	var ptypes: Array = PLANET_TYPES.keys().filter(func(t): return t != "dwarf")     # package 38: dwarfs come separately
	# package 37: a red supergiant pushes the inner orbits out (squeezing them towards the edge); around neutron stars
	# and black holes only a few dead worlds remain
	var push := maxf(0.0, float(st_type["radius"]) * 3.2 - 780000.0) / (1.0 - 780000.0 / 5400000.0)
	if String(st_type["kind"]) in ["neutron", "blackhole"]:
		planet_count = mini(planet_count, 3)
		ptypes = ["barren", "ice", "lava", "gas"]
	for i in planet_count:
		var orbit := (260000.0 + i * 290000.0 + rng.randf_range(-40000.0, 40000.0)) * SCALE
		orbit += push * (1.0 - orbit / 5400000.0)
		var pos := Vector2.from_angle(rng.randf() * TAU) * orbit
		var ptype: String = ptypes[rng.randi() % ptypes.size()]
		if i == 0 and rng.randf() < 0.5:
			ptype = "lava"
		# package 38: ice giants only out beyond the gas giants, ocean and jungle worlds in the warm middle
		if ptype == "ice_giant" and i < 2:
			ptype = "gas"
		if ptype in ["ocean", "jungle"] and (i == 0 or i > 3):
			ptype = "barren" if i == 0 else "ice"
		var big := float(PLANET_TYPES[ptype].get("big", 1.0)) > 1.5
		used.append(pos)
		L["planets"].append({
			"id": "p%d" % i, "name": "%s %s" % [sys["name"], ROMAN[i]], "type": ptype, "orbit": orbit, "pos": pos,
			"radius": rng.randf_range(6000.0, 12000.0) * float(PLANET_TYPES[ptype].get("big", 1.0)),
			"seed": rng.randf_range(0.0, 100.0), "ring": big and rng.randf() < (0.45 if ptype == "ice_giant" else 0.6),
		})
	if sp != "" and SPECIAL_BODIES.has(sp):
		_special_planets(L, id, sp)
		for pp in L["planets"]:
			used.append(pp["pos"])
	_make_moons(L, id)                                # package 36
	if sp != "" and SPECIAL_BODIES.has(sp):
		_special_moons(L, sp)
	var mrng := RandomNumberGenerator.new()           # package 36: which stations orbit a moon (own RNG)
	mrng.seed = seed_value * 40193 + id * 5381 + 36
	# Stations orbit planets (type and tier come from the cluster-wide plan) – or one of their moons (package 36)
	var plan: Array = sys.get("stations_plan", [])
	var station_planets: Array = []
	for i in plan.size():
		var pidx: int = rng.randi() % L["planets"].size()
		if pidx in station_planets:
			pidx = (pidx + 1) % L["planets"].size()
		station_planets.append(pidx)
		var planet: Dictionary = L["planets"][pidx]
		var type: String = plan[i][0]
		var tier: int = plan[i][1]
		var tdef: Dictionary = CommodityData.STATION_TYPES[type]
		var off := Vector2.from_angle(rng.randf() * TAU) * (float(planet["radius"]) * 1.7 + rng.randf_range(3000.0, 6000.0))
		var parent: Dictionary = planet
		var pmoons := moons_of(L, pidx)
		if not pmoons.is_empty() and mrng.randf() < MOON_STATION_SHARE and sp == "":
			parent = pmoons[mrng.randi() % pmoons.size()]
			off = Vector2.from_angle(mrng.randf() * TAU) * (float(parent["radius"]) * 1.7 + mrng.randf_range(3000.0, 6000.0))
		L["stations"].append({
			"id": "st_%d_%d" % [id, i], "planet": pidx, "anchor": parent["id"], "orbit": off.length(),     # 0.6.36.5: own orbit
			"name": "%s – %s" % [parent["name"], tdef["name"]],
			"type": type, "tier": tier, "pos": (parent["pos"] as Vector2) + off,
			"market": _make_market(type, rng),
			"shop": _make_shop(type, tier, rng),
			"shipyard": _make_shipyard(type, tier, Missions.wealthy(id)),
		})
		if sp != "":
			_special_station(L, sp, i, L["stations"].back())
	# Hyperspace gates – direction matches the neighbour's position on the galaxy map
	for nb in sys["links"]:
		var dir := ((systems[nb]["pos"] as Vector2) - (sys["pos"] as Vector2)).normalized()
		used.append(dir * GATE_DISTANCE)
		L["gates"].append({
			"id": "g_%d_%d" % [id, nb], "to": nb, "class": int(sys["links"][nb]),
			"pos": dir * GATE_DISTANCE, "name": "Gate to %s" % systems[nb]["name"],
		})
	# Asteroid fields: metallic near the star, stony in between, icy beyond the frost line
	var frost: float = float(st_type["frost"])          # package 37
	var need_icy := false
	for pe in plan:
		need_icy = need_icy or pe[0] == "ice_refinery"
	var has_icy := false
	var nf := rng.randi_range(2, 4)
	L["belts"] = _make_belts(L, id)                   # package 35: asteroid belt and Kuiper belt (scenery)
	_make_dwarfs(L, id)                               # package 38
	for b in nf:
		var cls: String = FIELD_CLASSES[rng.randi() % FIELD_CLASSES.size()]
		if b == nf - 1 and need_icy and not has_icy:
			cls = "icy"          # an Ice Refinery always has an icy field nearby
		has_icy = has_icy or cls == "icy"
		var center := _field_spot(L, cls, frost, used, rng)
		var mix := _field_mix(cls, sec, rng)
		var fid := "f%d" % b
		_make_field(L, fid, b, cls, mix, center, rng)
	# Hidden anomalies (must be scanned down)
	for k in rng.randi_range(2, 4):
		var diff := lerpf(8.0, 40.0, 1.0 - sec) + rng.randf_range(0.0, 10.0)
		var an := {
			"id": "an_%d" % k, "name": ANOMALY_NAMES[rng.randi() % ANOMALY_NAMES.size()],
			"pos": _free_spot(rng, used, 300000.0 * SCALE, 1800000.0 * SCALE),
			"difficulty": diff, "scan": 0.0, "revealed": false, "analysis": 0.0, "done": false,
		}
		# package 25g: a few rare anomalies hold exotic matter (decided by a hash – the layout stays as it was)
		if posmod(seed_value * 31 + id * 1013 + k * 7919, 100) < 14:
			an["exotic"] = true
			an["name"] = "Exotic Matter Signature"
			an["difficulty"] = diff + 10.0
		L["anomalies"].append(an)
	_special_stations(L, id, sec)
	_city_lights(L, id)                               # package 38
	_special_structures(L, sp)                        # package 39
	_scatter_loose(L, id, sec)
	_place_colossi(L, id, sec)
	_moon_fields(L, id, sec)                          # package 36: after the colossi – moon fields have none
	_place_orbits(L, id)                              # package 36: planets and moons on their orbits
	return L


## Package 38: one or two dwarf planets out in the Kuiper belt (own RNG). They are planets of their own (orbit,
## warp target, collection) – small, no moons.
func _make_dwarfs(L: Dictionary, id: int) -> void:
	var kb: Dictionary = {}
	for bt in L.get("belts", []):
		if String(bt["kind"]) == "kuiper":
			kb = bt
	if kb.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 19937 + id * 7121 + 38
	var n := rng.randi_range(DWARF_COUNT.x, DWARF_COUNT.y)
	for k in n:
		var i: int = L["planets"].size()
		var orbit := float(kb["r"]) + rng.randf_range(-0.5, 0.5) * float(kb["w"])
		L["planets"].append({
			"id": "p%d" % i, "name": "%s %s" % [systems[id]["name"], ROMAN[mini(i, ROMAN.size() - 1)]], "type": "dwarf", "orbit": orbit,
			"pos": Vector2.from_angle(rng.randf() * TAU) * orbit, "radius": rng.randf_range(1800.0, 2900.0),
			"seed": rng.randf_range(0.0, 100.0), "ring": false, "dwarf": true,
		})


## Package 38: the lights of cities on the night side. Habitable worlds (terran, ocean, jungle) in inhabited systems
## shine brightly – more in rich systems; other solid worlds with a station in orbit show a few settlements.
const CITY_WORLDS := ["terran", "ocean", "jungle"]


func _city_lights(L: Dictionary, id: int) -> void:
	var inhabited := has_stations(id)
	var rich := Missions.wealthy(id)
	for pi in L["planets"].size():
		var p: Dictionary = L["planets"][pi]
		var t := String(p["type"])
		if inhabited and t in CITY_WORLDS:
			p["city"] = clampf(0.55 + (0.3 if rich else 0.0) + float(systems[id].get("security", 0.5)) * 0.2, 0.0, 1.0)
		if p.has("city_fixed"):
			p["city"] = float(p["city_fixed"])            # package 39: Agora shines brightest
	for st in L["stations"]:
		var pi2 := int(st.get("planet", -1))
		if pi2 < 0 or pi2 >= L["planets"].size():
			continue
		var p2: Dictionary = L["planets"][pi2]
		if float(PLANET_TYPES[String(p2["type"])].get("gas", 0.0)) < 0.5 and float(p2.get("city", 0.0)) < 0.2:
			p2["city"] = 0.2


## Package 26: a waystation (station type 0: landing pads for S and M ships) in most systems – out on the
## way to one of the gates. Own RNG.
const WAYSTATION_SHARE := 0.75


func _add_waystation(L: Dictionary, id: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 52711 + id * 3301 + 11
	if L["gates"].is_empty() or L["planets"].is_empty() or rng.randf() > WAYSTATION_SHARE:
		return
	var g: Dictionary = L["gates"][rng.randi() % L["gates"].size()]
	var gp: Vector2 = g["pos"]
	var pos := gp * rng.randf_range(0.5, 0.75) + gp.normalized().orthogonal() * rng.randf_range(-60000.0, 60000.0) * SCALE
	var pidx := 0
	var bd := INF
	for i in L["planets"].size():
		var d := (L["planets"][i]["pos"] as Vector2).distance_to(pos)
		if d < bd:
			bd = d
			pidx = i
	var r := rng.randf()
	var tier := 1 if r < 0.55 else (2 if r < 0.88 else 3)
	var wst := {}
	# package 38: now and then the waystation sits at a dwarf planet out in the Kuiper belt (and goes round it)
	var dwarfs: Array = []
	for i2 in L["planets"].size():
		if L["planets"][i2].get("dwarf", false):
			dwarfs.append(i2)
	if not dwarfs.is_empty() and rng.randf() < DWARF_WAYSTATION:
		pidx = dwarfs[rng.randi() % dwarfs.size()]
		var dp: Dictionary = L["planets"][pidx]
		var off := Vector2.from_angle(rng.randf() * TAU) * (float(dp["radius"]) * 1.8 + rng.randf_range(2500.0, 4500.0))
		pos = (dp["pos"] as Vector2) + off
		wst = {"anchor": dp["id"], "orbit": off.length()}
	L["stations"].append({
		"id": "st_%d_%d" % [id, L["stations"].size()], "planet": pidx,
		"name": "%s Waystation" % systems[id]["name"],
		"type": "waystation", "tier": tier, "pos": pos,
		"market": _make_market("waystation", rng),
		"shop": [],
		"shipyard": [],
	})
	L["stations"].back().merge(wst)


## Phase 0.5 package 6: art seed + no-fire zone for every station, Ice Refineries next to icy
## fields, Shipyard Complexes in safe systems, Pirate Havens in lawless ones. Own RNG keeps the
## base layout (and saves) stable.
func _special_stations(L: Dictionary, id: int, sec: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 70001 + id * 9173 + 3
	_add_waystation(L, id)
	var si := 0
	for st in L["stations"]:
		st["seed"] = rng.randi()
		st["zone"] = NO_FIRE_ZONE[clampi(int(st["tier"]), 1, 3) - 1]
		st["faction"] = station_faction(id, si)
		_add_faction_yard(st)
		si += 1
	# Pirate Haven (planned for lawless systems): hostile scenery, docking needs reputation – later
	var htier := int(systems[id].get("haven_tier", 0))
	if htier <= 0:
		return
	for attempt in 80:
		var pos := Vector2.ZERO
		if not L["fields"].is_empty() and rng.randf() < 0.6:
			var f: Dictionary = L["fields"][rng.randi() % L["fields"].size()]
			pos = (f["pos"] as Vector2) + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(30000.0, 60000.0)
		else:
			pos = Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(400000.0, 1600000.0) * SCALE
		var ok := true
		for o in L["stations"]:
			ok = ok and (o["pos"] as Vector2).distance_to(pos) > 120000.0
		for g in L["gates"]:
			ok = ok and (g["pos"] as Vector2).distance_to(pos) > 80000.0
		for p in L["planets"]:
			ok = ok and (p["pos"] as Vector2).distance_to(pos) > float(p["radius"]) * 3.0
		if ok or attempt == 79:
			var hv := {"id": "ph_%d" % id, "name": "%s %s" % [HAVEN_NAMES[rng.randi() % HAVEN_NAMES.size()], ROMAN[rng.randi_range(1, 4)]],
				"type": "pirate_haven", "tier": htier, "pos": pos, "seed": rng.randi(),
				"faction": controller(id) if controller(id) in FactionData.PIRATES else "free_captains"}
			_haven_services(hv, id)
			L["havens"].append(hv)
			break


## Black market, outfitter and docks of a Pirate Haven (package 12: dockable with pirate
## standing). Own RNG so the rest of the layout stays unchanged; no no-fire zone.
func _haven_services(hv: Dictionary, id: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 91807 + id * 4421 + 7
	hv["zone"] = 0.0
	hv["market"] = _make_market("pirate_haven", rng)
	hv["shop"] = _make_shop("pirate_haven", int(hv["tier"]), rng)
	hv["shipyard"] = ["crow"]       # the pirates' own patched-together raider (package 19)


## Colossal asteroids (phase 0.5 package 5): rocks up to ~2,800 km long in the foreground of
## asteroid fields, usually two or three per field. Ships must fly around them, they cast a radar
## shadow and block line of sight. Each has an irregular outline (potato, contact binary or angular
## shard, see ColossusShape); their rim holds richer mineable rock. Anything that would end up
## inside a colossus is removed. Own RNG keeps older layouts stable.
func _place_colossi(L: Dictionary, id: int, sec: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 48611 + id * 6007 + 11
	var n := 0
	for f in L["fields"]:
		var fc: Vector2 = f["pos"]
		var fr: float = f["radius"]
		var cls: String = f["class"]
		var mix := _field_mix(cls, sec, rng)
		var want := rng.randi_range(3, 5) + (1 if sec < 0.4 else 0)       # 0.6.35.4: more colossi, in every field
		var placed := 0
		# the group sits together in one part of the field
		var group_dir := rng.randf() * TAU
		for attempt in 90:
			if placed >= want:
				break
			var R := rng.randf_range(800.0, 1500.0) if placed == 0 else rng.randf_range(400.0, 1100.0)
			var dist := rng.randf_range(0.15, 0.9) * fr
			var pos := fc + Vector2.from_angle(group_dir + rng.randf_range(-1.6, 1.6)) * dist
			# keep the warp arrival ring (half the field radius) and the field centre clear
			if absf(pos.distance_to(fc) - fr * 0.5) < R + 1500.0 or pos.distance_to(fc) < R + 1500.0:
				continue
			var ok := true
			for o in L["stations"] + L["gates"]:
				if (o["pos"] as Vector2).distance_to(pos) < R + 8000.0:
					ok = false
			for o2 in L["colossi"]:
				var gap := pos.distance_to(o2["pos"]) - R - float(o2["radius"])
				if gap < 900.0 or (placed > 0 and String(o2["field"]) == String(f["id"]) and gap > 16000.0):
					ok = false
			if not ok:
				continue
			var shapes_c: Array = ColossusShape.shapes_for(cls)
			var shape: String = shapes_c[rng.randi() % shapes_c.size()]
			var poly := ColossusShape.generate(shape, R, rng)
			var col := {
				"id": "col_%d" % n, "name": "Colossus %s-%d" % [COLOSSUS_PREFIX[rng.randi() % COLOSSUS_PREFIX.size()], rng.randi_range(2, 98)],
				"class": cls, "ore": _roll_ore(mix, rng), "pos": pos, "radius": R, "shape": shape, "poly": poly,
				"seed": rng.randi(), "field": f["id"],
			}
			# 0.6.35.5: a colossus can be mined – a huge deposit of two ores of its field
			var cmix := {String(col["ore"]): 1.0}
			if mix.size() > 1:
				var second := String(col["ore"])
				while second == String(col["ore"]):
					second = _roll_ore(mix, rng)
				var sh := rng.randf_range(0.2, 0.4)
				cmix = {String(col["ore"]): 1.0 - sh, second: sh}
			col["mix"] = cmix
			col["amount"] = roundf(R * rng.randf_range(40.0, 70.0))
			col["amount0"] = col["amount"]
			_deep_ore(col)                              # package 41
			L["colossi"].append(col)
			n += 1
			placed += 1
			# Rim: mineable rock hugging the surface
			for k in rng.randi_range(4, 7):
				var edge := rng.randi() % poly.size()
				var sp: Vector2 = poly[edge].lerp(poly[(edge + 1) % poly.size()], rng.randf())
				var ast := _make_asteroid("cr_%d_%d" % [n, k], String(f["id"]), cls, mix, pos, rng)
				if ast["size"] == "small":
					ast["size"] = "medium"
					ast["radius"] = rng.randf_range(25.0, 60.0)
				ast["pos"] = pos + sp + sp.normalized() * (float(ast["radius"]) + rng.randf_range(40.0, 260.0))
				ast["near"] = col["name"]
				ast["amount"] = float(ast["amount"]) * 1.4
				L["asteroids"].append(ast)
	_clear_colossi(L)


## Removes asteroids and debris that would sit inside a colossus.
func _clear_colossi(L: Dictionary) -> void:
	for col2 in L["colossi"]:
		var cp: Vector2 = col2["pos"]
		var cr := float(col2["radius"])
		var cpoly: PackedVector2Array = col2["poly"]
		var clear := func(o) -> bool:
			var rel: Vector2 = (o["pos"] as Vector2) - cp
			if rel.length() > cr + float(o["radius"]) + 20.0:
				return true
			return ColossusShape.signed_dist(cpoly, rel) > float(o["radius"]) + 20.0
		L["asteroids"] = L["asteroids"].filter(clear)
		L["debris"] = L["debris"].filter(clear)


## Asteroids outside the fields (phase 0.5 package 4): rings of rock around planets, small
## clusters at gates, stations and anomalies. Most are scenery ("debris", drawn by SystemView,
## not selectable); some are real, mineable asteroids. A separate RNG keeps older layouts stable.
func _scatter_loose(L: Dictionary, id: int, sec: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 92821 + id * 7177 + 5
	L["debris"] = []
	var n := 0
	for p in L["planets"]:
		var cls: String = PLANET_ROCK_CLASS.get(p["type"], "stony")
		var pr: float = p["radius"]
		var inner := pr * (1.7 if p.get("ring", false) else 1.35)
		var outer := inner + pr * rng.randf_range(0.5, 1.1)
		var tilt := rng.randf() * TAU
		var flat := rng.randf_range(0.35, 0.8)     # ellipse = ring seen at an angle
		var mix := _field_mix(cls, sec, rng)
		# Rocks gather in dense clusters spaced around the ring (a uniform ring at real scale
		# would be far too thin to ever see more than one rock at a time)
		var circ := TAU * (inner + outer) * 0.5
		var clusters := int(clampf(circ / 9000.0, 8.0, 24.0))
		for c in clusters:
			var a := TAU * c / clusters + rng.randf_range(-0.15, 0.15)
			var r := rng.randf_range(inner, outer)
			var cpos: Vector2 = (p["pos"] as Vector2) + (Vector2(cos(a) * r, sin(a) * r * flat)).rotated(tilt)
			var spread := rng.randf_range(600.0, 1400.0)
			for k in rng.randi_range(10, 18):
				var pos := cpos + Vector2.from_angle(rng.randf() * TAU) * pow(rng.randf(), 0.7) * spread
				var deb := _make_debris(cls, mix, pos, rng)
				deb["anchor"] = p["id"]                      # package 36: moves with the planet
				L["debris"].append(deb)
			if c % 2 == 0:
				var ast := _make_asteroid("l_%d" % n, "", cls, mix, cpos + Vector2.from_angle(rng.randf() * TAU) * spread * 0.5, rng)
				ast["near"] = p["name"]
				ast["anchor"] = p["id"]
				L["asteroids"].append(ast)
				n += 1
	var spots: Array = []
	for g in L["gates"]:
		spots.append([g["pos"], 1600.0, rng.randi_range(30, 45), 3])
	for st in L["stations"]:
		spots.append([st["pos"], 1100.0, rng.randi_range(12, 20), 1, String(st["id"]) if st.has("orbit") else ""])   # rocks go round with the station
	for an in L["anomalies"]:
		spots.append([an["pos"], 2200.0, rng.randi_range(30, 50), 5])
	for sp in spots:
		var center: Vector2 = sp[0]
		var dist := center.length()
		var cls: String = "metallic" if dist < 800000.0 * SCALE else ("stony" if dist < 1350000.0 * SCALE else "icy")
		var mix := _field_mix(cls, sec, rng)
		var anc: String = sp[4] if sp.size() > 4 else ""
		for k in int(sp[2]):
			var pos := center + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(float(sp[1]) * 0.25, float(sp[1]))
			var deb2 := _make_debris(cls, mix, pos, rng)
			if anc != "":
				deb2["anchor"] = anc
			L["debris"].append(deb2)
		for k in int(sp[3]):
			var pos2 := center + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(float(sp[1]) * 0.4, float(sp[1]) * 1.1)
			var ast2 := _make_asteroid("l_%d" % n, "", cls, mix, pos2, rng)
			if anc != "":
				ast2["anchor"] = anc
			if ast2["size"] == "large":
				ast2["size"] = "medium"
				ast2["radius"] = rng.randf_range(25.0, 60.0)
			L["asteroids"].append(ast2)
			n += 1


## Scenery rock: no deposit, not selectable, drawn in bulk.
func _make_debris(cls: String, mix: Dictionary, pos: Vector2, rng: RandomNumberGenerator) -> Dictionary:
	var shapes: Array = SHAPES_BY_CLASS[cls]
	return {"pos": pos, "class": cls, "ore": _roll_ore(mix, rng), "shape": shapes[rng.randi() % shapes.size()],
		"radius": rng.randf_range(12.0, 40.0) if rng.randf() < 0.85 else rng.randf_range(40.0, 85.0),
		"seed": rng.randi(), "rot": rng.randf() * TAU, "spin": rng.randf_range(-0.08, 0.08)}


# ---------------------------------------------------------------- Belts and fields (package 35)

## Field styles: how the rocks lie and which sizes come up (small / medium threshold of the size roll).
const FIELD_STYLES := {
	"clustered": {"name": "Clustered", "weights": Vector2(0.5, 0.88)},
	"band": {"name": "Band", "weights": Vector2(0.45, 0.85)},
	"core": {"name": "Dense Core", "weights": Vector2(0.35, 0.75)},
	"scattered": {"name": "Boulder Field", "weights": Vector2(0.2, 0.6)},
	"gravel": {"name": "Gravel Field", "weights": Vector2(0.75, 0.96)},
}
const BELT_SHARE := 0.8              # systems with an asteroid belt …
const KUIPER_SHARE := 0.7            # … and with a Kuiper belt


## The decorative belts: an asteroid belt between the rocky planets and the gas giants, a Kuiper belt far out.
## {"kind", "r" (centre radius), "w" (half width), "cls"}. Own RNG.
func _make_belts(L: Dictionary, id: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 61403 + id * 2711 + 35
	var out: Array = []
	if rng.randf() < BELT_SHARE:
		var r := 0.42 * SYSTEM_RADIUS
		var planets: Array = L["planets"]
		for i in planets.size():
			if String(planets[i]["type"]) in ["gas", "toxic", "ice_giant", "red_gas"] and i > 0:
				r = (float(planets[i - 1]["orbit"]) + float(planets[i]["orbit"])) * 0.5
				break
		out.append({"kind": "asteroid", "r": r, "w": rng.randf_range(0.05, 0.08) * SYSTEM_RADIUS, "cls": "stony", "seed": rng.randi()})
	if rng.randf() < KUIPER_SHARE:
		out.append({"kind": "kuiper", "r": rng.randf_range(0.82, 0.86) * SYSTEM_RADIUS, "w": rng.randf_range(0.05, 0.07) * SYSTEM_RADIUS, "cls": "icy", "seed": rng.randi()})
	return out


## Where a field of a class lies: metal and stone in the asteroid belt, ice in the Kuiper belt – otherwise in the
## old orbital bands. Keeps away from everything else placed so far.
func _field_spot(L: Dictionary, cls: String, frost: float, used: Array, rng: RandomNumberGenerator) -> Vector2:
	var want := "kuiper" if cls == "icy" else "asteroid"
	for bt in L.get("belts", []):
		if String(bt["kind"]) == want:
			return _free_spot(rng, used, float(bt["r"]) - float(bt["w"]) * 0.7, float(bt["r"]) + float(bt["w"]) * 0.7)
	var band: Vector2 = FIELD_BANDS[cls]
	return _free_spot(rng, used, minf(band.x * frost, 4800000.0), minf(band.y * frost, 5550000.0))


## An asteroid field (0.6.35.4): many small structures – knots, patches and streams of rock – close together, so
## most of the field is covered, with open water between them and a few very dense spots. Five styles set the mix.
## structure: [centre, radius, weight, stretch direction (Vector2.ZERO = round), stretch]
func _make_field(L: Dictionary, fid: String, b: int, cls: String, mix: Dictionary, center: Vector2, rng: RandomNumberGenerator) -> void:
	var keys: Array = FIELD_STYLES.keys()
	var style: String = keys[rng.randi() % keys.size()]
	var w: Vector2 = FIELD_STYLES[style]["weights"]
	var fradius := rng.randf_range(12000.0, 22000.0)
	var area := PI * pow(fradius / 1000.0, 2.0)                # in 1,000 km²
	var count := int(area * rng.randf_range(0.8, 1.0))
	match style:
		"scattered":
			count = int(count * 0.55)
		"gravel":
			count = int(count * 1.25)
	L["fields"].append({"id": fid, "name": "Asteroid Field %s (%s, %s)" % [ROMAN[b], cls.capitalize(), FIELD_STYLES[style]["name"]],
		"class": cls, "ores": mix.keys(), "ore": mix.keys()[0], "pos": center, "radius": fradius, "style": style})
	var tangent := center.normalized().orthogonal() if center.length() > 1.0 else Vector2.RIGHT
	var structs: Array = []
	var n_struct := int(area * rng.randf_range(0.11, 0.14))
	var knot_share: float = {"clustered": 0.25, "band": 0.15, "core": 0.2, "scattered": 0.05, "gravel": 0.4}[style]
	var stream_share: float = {"clustered": 0.15, "band": 0.55, "core": 0.1, "scattered": 0.1, "gravel": 0.15}[style]
	for i in n_struct:
		var pos := center + Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * fradius * 0.92
		if style == "band":
			# along the orbit: squash the field across the tangent
			var t := rng.randf_range(-1.0, 1.0)
			pos = center + tangent * t * fradius + tangent.orthogonal() * rng.randf_range(-0.35, 0.35) * fradius
		if style == "core" and rng.randf() < 0.35:
			pos = center + Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * fradius * 0.3
		var r := rng.randf()
		if r < knot_share:
			structs.append([pos, rng.randf_range(150.0, 420.0), rng.randf_range(3.0, 6.0), Vector2.ZERO, 1.0])       # a dense knot
		elif r < knot_share + stream_share:
			var dir := (tangent if style == "band" and rng.randf() < 0.7 else Vector2.from_angle(rng.randf() * TAU))
			structs.append([pos, rng.randf_range(250.0, 600.0), rng.randf_range(2.0, 4.0), dir, rng.randf_range(3.0, 6.0)])   # a stream
		else:
			structs.append([pos, rng.randf_range(400.0, 1000.0), rng.randf_range(1.5, 3.0), Vector2.ZERO, 1.0])      # a patch
	var total := 0.0
	for st in structs:
		total += float(st[2])
	for k in count:
		# a structure by weight; a few rocks drift loose between them
		var pos2 := Vector2.ZERO
		if rng.randf() < 0.06:
			pos2 = center + Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * fradius
		else:
			var x := rng.randf() * total
			var st2: Array = structs[0]
			for st3 in structs:
				x -= float(st3[2])
				if x <= 0.0:
					st2 = st3
					break
			var off := Vector2.from_angle(rng.randf() * TAU) * pow(rng.randf(), 0.8) * float(st2[1])
			var dir2: Vector2 = st2[3]
			if dir2 != Vector2.ZERO:
				off = dir2 * rng.randf_range(-1.0, 1.0) * float(st2[1]) * float(st2[4]) + dir2.orthogonal() * off.y * 0.5
			pos2 = (st2[0] as Vector2) + off
		L["asteroids"].append(_make_asteroid("a_%d_%d" % [b, k], fid, cls, mix, pos2, rng, w))


func _free_spot(rng: RandomNumberGenerator, used: Array, rmin: float, rmax: float) -> Vector2:
	var p := Vector2.ZERO
	for attempt in 60:
		p = Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(rmin, rmax)
		var ok := true
		for u in used:
			if (u as Vector2).distance_to(p) < 150000.0:
				ok = false
				break
		if ok:
			break
	used.append(p)
	return p


## All warp targets of a system: {id, kind, name, pos, land (arrival distance), data}
func warp_targets(system_id: int) -> Array:
	var L := get_layout(system_id)
	var out: Array = []
	var star: Dictionary = L["star"]
	var land_mult := float(STAR_TYPES[star_index(String(star.get("star_id", "G")))]["land"])       # package 37
	out.append({"id": "star", "kind": "star", "name": "%s (%s)" % [star["name"], star["type"]], "pos": star["pos"], "land": float(star["radius"]) * land_mult, "data": star})
	for p in L["planets"]:
		out.append({"id": p["id"], "kind": "planet", "name": p["name"], "pos": p["pos"], "land": float(p["radius"]) * 1.6, "data": p})
	for m in L.get("moons", []):                   # package 36
		out.append({"id": m["id"], "kind": "moon", "name": m["name"], "pos": m["pos"], "land": float(m["radius"]) * 1.6, "data": m})
	for st in L["stations"]:
		out.append({"id": st["id"], "kind": "station", "name": st["name"], "pos": st["pos"], "land": 2500.0, "data": st})
	for g in L["gates"]:
		out.append({"id": g["id"], "kind": "gate", "name": g["name"], "pos": g["pos"], "land": 2200.0, "data": g})
	for f in L["fields"]:
		out.append({"id": f["id"], "kind": "field", "name": f["name"], "pos": f["pos"], "land": float(f["radius"]) * 0.5, "data": f})
	for ph in L.get("havens", []):
		out.append({"id": ph["id"], "kind": "haven", "name": ph["name"], "pos": ph["pos"], "land": 9000.0, "data": ph})
	for an in L["anomalies"]:
		if an["revealed"]:
			out.append({"id": an["id"], "kind": "anomaly", "name": an["name"], "pos": an["pos"], "land": 2200.0, "data": an})
	for pod in GameState.pods:                     # package 31a: escape pods with crew waiting for rescue
		if int(pod["system"]) == system_id:
			out.append({"id": pod["id"], "kind": "pod", "name": "Escape pod – %d crew" % (pod["crew"] as Array).size(), "pos": pod["pos"], "land": 900.0, "data": pod})
	return out


func warp_target(system_id: int, target_id: String) -> Dictionary:
	for t in warp_targets(system_id):
		if t["id"] == target_id:
			return t
	return {}


## Ore weights of a field: both common ores of the class, one or two uncommon ones,
## and in unsafe systems (security < 0.5) a chance for rare ores – more the lower the security.
func _field_mix(cls: String, sec: float, rng: RandomNumberGenerator) -> Dictionary:
	var by_rarity := {"common": [], "uncommon": [], "rare": []}
	for cid in CommodityData.COMMODITIES:
		var c: Dictionary = CommodityData.COMMODITIES[cid]
		if c.get("category", "") == "ore" and c["class"] == cls and not c.get("deep", false):     # package 41: deep ores only in colossi
			by_rarity[c["rarity"]].append(cid)
	var mix := {}
	for cid in by_rarity["common"]:
		mix[cid] = 3.0
	# deterministic pick (same seed -> same galaxy, important for save games)
	var unc: Array = by_rarity["uncommon"].duplicate()
	for i in (2 if rng.randf() < 0.5 else 1):
		var pick: int = rng.randi() % unc.size()
		mix[unc[pick]] = 1.5
		unc.remove_at(pick)
	if sec < 0.5:
		var rare: Array = by_rarity["rare"]
		mix[rare[rng.randi() % rare.size()]] = lerpf(0.4, 1.4, 1.0 - sec / 0.5)
		if sec < 0.2:
			for r in rare:
				mix[r] = maxf(float(mix.get(r, 0.0)), 0.6)
	return mix


# ---------------------------------------------------------------- Package 41: purity, deep ore, gas giants

const PURITY := {"low": 0.7, "medium": 1.0, "high": 1.4}
const DEEP_ORES := {"metallic": "osmium_ore", "stony": "palladium_ore"}
const DEEP_SHARE := 0.75                 # share of metallic / stony colossi with a deep deposit
## Gases of each kind of giant: gas -> share (the rare one small).
const GAS_YIELDS := {
	"gas": {"hydrogen": 3.0, "helium": 2.0, "helium3_gas": 0.25},
	"ice_giant": {"nitrogen_gas": 3.0, "neon": 1.5, "xenon": 0.3},
	"red_gas": {"hydrogen": 3.0, "sulfur_dioxide": 2.0, "phosphine": 0.3},
	"toxic": {"chlorine": 3.0, "ammonia_gas": 2.0, "fluorine": 0.3},
}
## The harvest band: from BAND_OUT radii out (depth 0) down to BAND_IN radii (depth 1 – far too hot).
const BAND_OUT := 1.3
const BAND_IN := 0.7


## Purity grade of an asteroid (from its id – nothing in the layout shifts): low / medium / high.
static func purity_grade(d: Dictionary) -> String:
	if d.has("purity_grade"):
		return String(d["purity_grade"])
	var h := posmod(hash(String(d.get("id", ""))), 100)
	var g := "low" if h < 25 else ("high" if h >= 80 else "medium")
	d["purity_grade"] = g
	return g


static func purity_of(d: Dictionary) -> float:
	return float(PURITY[purity_grade(d)])


## A deep deposit in a colossus (osmium in metallic, palladium in stony ones) – only the deep core drill reaches it.
func _deep_ore(col: Dictionary) -> void:
	var cls := String(col.get("class", ""))
	if not DEEP_ORES.has(cls) or posmod(hash(String(col["id"]) + str(col.get("seed", 0))), 100) >= int(DEEP_SHARE * 100.0):
		return
	col["deep_ore"] = DEEP_ORES[cls]
	col["deep_amount"] = 60.0 + float(posmod(int(col.get("seed", 0)), 90))


## One asteroid: size class (small / medium / large), shape, ore(s) and deposit.
## Large asteroids often hold a second ore of the same field ("mix": ore -> share).
func _make_asteroid(id: String, fid: String, cls: String, mix: Dictionary, pos: Vector2, rng: RandomNumberGenerator, weights: Vector2 = Vector2(0.5, 0.88)) -> Dictionary:
	var r := rng.randf()
	var size := "small" if r < weights.x else ("medium" if r < weights.y else "large")
	var sz: Dictionary = ASTEROID_SIZES[size]
	var ore := _roll_ore(mix, rng)
	var amount: float = rng.randf_range(sz["amount"].x, sz["amount"].y) * RARITY_AMOUNT[GameData.commodities[ore]["rarity"]]
	var shares := {ore: 1.0}
	if size == "large" and mix.size() > 1 and rng.randf() < 0.7:
		var second := ore
		while second == ore:
			second = _roll_ore(mix, rng)
		var share := rng.randf_range(0.2, 0.4)
		shares = {ore: 1.0 - share, second: share}
	var shapes: Array = SHAPES_BY_CLASS[cls]
	return {
		"id": id, "field": fid, "class": cls, "size": size, "shape": shapes[rng.randi() % shapes.size()],
		"pos": pos, "ore": ore, "mix": shares, "amount": amount, "amount0": amount,
		"radius": rng.randf_range(sz["radius"].x, sz["radius"].y), "seed": rng.randi(),
		"spin": rng.randf_range(-0.06, 0.06),
	}


func _roll_ore(mix: Dictionary, rng: RandomNumberGenerator) -> String:
	var total := 0.0
	for k in mix:
		total += float(mix[k])
	var x := rng.randf() * total
	for k in mix:
		x -= float(mix[k])
		if x <= 0.0:
			return k
	return mix.keys()[0]


## Market prices: buy = price the player pays (-1 = not on offer),
## sell = price the station pays the player.
func _make_market(type: String, rng: RandomNumberGenerator) -> Dictionary:
	var t: Dictionary = GameData.station_types[type]
	var market := {}
	for cid in CommodityData.COMMODITIES:
		if not CommodityData.COMMODITIES[cid].get("tradeable", true):
			continue
		var base := float(CommodityData.COMMODITIES[cid]["price"])
		var noise := rng.randf_range(0.9, 1.1)
		var buy := -1
		var sell := int(round(base * 0.95 * noise))
		if cid in t["produces"]:
			buy = int(round(base * 0.75 * noise))
			sell = int(round(base * 0.6 * noise))
		elif cid in t["consumes"]:
			sell = int(round(base * 1.45 * noise))
		market[cid] = {"buy": buy, "sell": sell}
	return market


## Outfitter stock (package 19): module families of the station's speciality (others rarely), in
## the sizes the station tier allows, each size in a few qualities – F–C everywhere, B from tier 2,
## A from tier 3 or at military outposts. Pirate gear only in havens; ion torpedoes never.
func _make_shop(type: String, tier: int, rng: RandomNumberGenerator) -> Array:
	var t: Dictionary = GameData.station_types[type]
	var shop: Array = []
	for fam in ModuleData.FAMILIES:
		var a: Dictionary = ModuleData.ANCHORS[ModuleData.FAMILIES[fam]["anchor"]]
		if a.get("notorious_only", false) or (a.get("pirate_only", false) and type != "pirate_haven") or a.get("covenant_only", false) or a.get("directorate_only", false):
			continue
		var chance := 0.9 if a["slot"] in t["shop"] else 0.12
		if a["slot"] in ["hangar", "drone"]:
			chance = 0.6              # drone hangars and drone modules: at many stations (package 23)
		if rng.randf() > chance:
			continue
		var r: Array = ModuleData.FAMILIES[fam]["sizes"]
		var cap := GameData.size_cap(String(a["slot"]), tier)
		for size in range(int(r[0]), mini(int(r[1]), cap) + 1):
			if rng.randf() > 0.75:
				continue          # not every size is in stock
			var qs: Array = ["C"]
			if rng.randf() < 0.5:
				qs.append("D")
			if rng.randf() < 0.3:
				qs.append("E")
			if rng.randf() < 0.2:
				qs.append("F")
			if tier >= 2 and rng.randf() < 0.4:
				qs.append("B")
			if (tier >= 3 or type == "military") and rng.randf() < 0.3:
				qs.append("A")
			for q in qs:
				shop.append(ModuleData.id_of(fam, size, q))
	return shop


## Faction ships (package 25e): a shipyard of a power's station also sells the hulls of the power's
## state manufacturer (size up to the tier); buying them needs standing (hull min_tier).
func _add_faction_yard(st: Dictionary) -> void:
	var t: Dictionary = GameData.station_types.get(String(st["type"]), {})
	# package 25f: the Covenant's outfitters sell its focus-crystal lasers
	if String(st.get("faction", "")) == "covenant" and ("weapon" in t.get("shop", []) or String(st["type"]) == "military"):
		var cap := GameData.size_cap("weapon", int(st["tier"]))
		for size in range(1, mini(4, cap) + 1):
			var qs: Array = ["C", "D"]
			if int(st["tier"]) >= 2:
				qs.append("B")
			if int(st["tier"]) >= 3 or String(st["type"]) == "military":
				qs.append("A")
			for q in qs:
				var mid := ModuleData.id_of("w_focus", size, q)
				if not mid in st["shop"]:
					st["shop"].append(mid)
	# 0.4.25.40: the Directorate's outfitters sell Axiom's drone cloak emitter
	if String(st.get("faction", "")) == "directorate" and not st.get("shop", []).is_empty():
		var qs2: Array = ["C", "D"]
		if int(st["tier"]) >= 2:
			qs2.append("B")
		if int(st["tier"]) >= 3 or String(st["type"]) == "military":
			qs2.append("A")
		for q2 in qs2:
			var mid2 := ModuleData.id_of("dr_cloak", 1, q2)
			if not mid2 in st["shop"]:
				st["shop"].append(mid2)
	if not t.get("shipyard", false):
		return
	var f := String(st.get("faction", ""))
	for hid in GameData.hulls:
		var h: Dictionary = GameData.hulls[hid]
		var mk: Dictionary = MakerData.MAKERS.get(String(h.get("maker", "")), {})
		if String(mk.get("kind", "")) == "state" and String(mk.get("faction", "")) == f and h["buyable"] and int(h["size"]) <= int(st["tier"]) and not hid in st["shipyard"]:
			if CAPITAL_ONLY.has(hid) and not st.get("capital_yard", false):
				continue                                 # package 39: the flagship only at the capital's yard
			st["shipyard"].append(hid)


## Shipyard stock by manufacturer (package 25a, data/manufacturers.gd): a maker's hulls at the
## station types in its "yards" (size up to the tier), plus "small_yards" (e.g. KHI and the
## Earthworks Drillhead at mining colonies). `rich`: a rich, safe system – makers with "rich_only"
## (Maison Aurelle, package 25c) sell only there.
func _make_shipyard(type: String, tier: int, rich: bool = false) -> Array:
	var t: Dictionary = GameData.station_types[type]
	var yard: Array = []
	for hid in GameData.hulls:
		var h: Dictionary = GameData.hulls[hid]
		if not h["buyable"] or h.get("haven_only", false) or h.get("drone_only", false):
			continue
		var mk: Dictionary = MakerData.MAKERS.get(String(h.get("maker", "")), {})
		if mk.has("rich_only") and not rich:
			continue
		if String(mk.get("kind", "")) == "state":
			continue                     # faction ships: see _add_faction_yard (package 25e)
		# package 25d: big warships only at military stations, shipyard complexes and tier-3 stations
		if String(h.get("yard_rule", "")) == "military" and not (type in ["military", "shipyard"] or tier >= 3):
			continue
		var yards = mk.get("yards", "all")
		var at_yard: bool = t["shipyard"] and (typeof(yards) == TYPE_STRING or type in yards)
		if at_yard and int(h["size"]) <= tier:
			yard.append(hid)
		elif hid in mk.get("small_yards", {}).get(type, []):
			yard.append(hid)
	return yard
