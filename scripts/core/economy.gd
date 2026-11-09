class_name Economy
extends RefCounted
## Wirtschaft 2.0 (package 42a): every system has a main and – if strong enough – a secondary economy. They come from
## what is in the system: its planets and moons, its asteroid fields and belts, and above all its stations (the
## stations are fixed and shape the economy, not the other way round). The hand-made systems lean towards their own.
## Each system also has a prosperity (0–100, five levels) that starts from its population, stations and security
## and changes slowly in play (GameState.prosperity – package 42c moves it).

const ECONOMIES := {
	"agri": {"name": "Agriculture", "color": Color(0.5, 0.9, 0.35),
		"text": "Food, water and everything that grows – ocean and jungle worlds, ice giants and the agricultural stations."},
	"mining": {"name": "Mining", "color": Color(0.85, 0.62, 0.38),
		"text": "Ore and gas: metal worlds, barren rock, asteroid fields and belts, the giants and the mining colonies."},
	"industry": {"name": "Industry", "color": Color(0.95, 0.78, 0.3),
		"text": "Factories and yards: machines, parts and consumer goods – industrial complexes and shipyards, energy from gas giants."},
	"refinery": {"name": "Refining", "color": Color(1.0, 0.5, 0.25),
		"text": "Smelters and refineries: metals, fuels and processed ice – lava worlds, metal-rich fields and ice refineries."},
	"chemistry": {"name": "Chemistry", "color": Color(0.7, 0.95, 0.3),
		"text": "Plastics, acids and reagents from the haze of red and toxic giants and from volcanic moons."},
	"hightech": {"name": "High-Tech", "color": Color(0.35, 0.85, 1.0),
		"text": "Electronics, optics and medicine: earthlike worlds with their universities, research stations and yards."},
	"research": {"name": "Research", "color": Color(0.7, 0.55, 1.0),
		"text": "Laboratories and observatories – research stations, strange moons and the edge of the system."},
	"military": {"name": "Military", "color": Color(1.0, 0.35, 0.35),
		"text": "Garrisons, armouries and naval yards – military outposts and the yards that build warships."},
	"tourism": {"name": "Tourism", "color": Color(1.0, 0.55, 0.85),
		"text": "Visitors and their money: earthlike and ocean worlds, famous sights and the capitals (expanded in package 43)."},
}
const ORDER := ["agri", "mining", "industry", "refinery", "chemistry", "hightech", "research", "military", "tourism"]

## What each kind of body is worth to the economies (points). Stations weigh most (they are fixed and shape the
## economy); bodies tip the balance and decide the secondary economy.
const PLANET_WEIGHTS := {
	"terran": {"tourism": 2.5, "hightech": 2.5, "agri": 0.8},
	"ocean": {"agri": 3.5, "tourism": 1.2},
	"jungle": {"agri": 2.5, "research": 1.5},
	"desert": {"mining": 0.8, "industry": 1.0},
	"ice": {"agri": 0.8, "research": 1.0},
	"lava": {"refinery": 2.5, "mining": 0.5},
	"barren": {"mining": 1.2, "research": 0.3},
	"metal": {"mining": 4.0, "refinery": 1.0},
	"gas": {"mining": 0.8, "industry": 2.2},
	"ice_giant": {"mining": 0.8, "agri": 2.2},
	"red_gas": {"mining": 0.8, "chemistry": 3.0},
	"toxic": {"mining": 0.8, "chemistry": 2.2, "refinery": 1.2},
	"dwarf": {"research": 1.0},
}
const MOON_WEIGHTS := {
	"moon_rock": {"mining": 0.4},
	"moon_ice": {"agri": 0.5},
	"moon_volcanic": {"refinery": 0.6, "chemistry": 0.6},
	"moon_captured": {"mining": 0.3, "research": 0.3},
}
const MOON_PLANET_SHARE := 0.6          # a moon of a planet type (Vesper, a desert moon) counts this much of a planet
const FIELD_WEIGHTS := {
	"metallic": {"mining": 0.5, "refinery": 0.3},
	"stony": {"mining": 0.5, "industry": 0.2},
	"icy": {"mining": 0.3, "agri": 0.4},
}
const BELT_WEIGHTS := {
	"asteroid": {"mining": 0.6},
	"kuiper": {"agri": 0.3, "research": 0.5},
}
## Stations shape the economy most: points per tier.
const STATION_WEIGHTS := {
	"trade": {"tourism": 1.0, "industry": 0.6, "hightech": 0.4},
	"industry": {"industry": 4.5},
	"mining_colony": {"mining": 4.5},
	"agri": {"agri": 4.5},
	"research": {"research": 4.5, "hightech": 1.5},
	"military": {"military": 5.0},
	"ice_refinery": {"refinery": 3.0, "agri": 1.0, "chemistry": 1.0},
	"shipyard": {"industry": 3.0, "military": 1.5, "hightech": 1.5},
	"waystation": {"tourism": 0.8},
}
## The hand-made systems lean towards their own economies (main, secondary).
const SPECIAL := {
	"landfall": ["hightech", "tourism"],       # the Assembly's capital – Agora, the Senate
	"heimkehr": ["tourism", "industry"],       # pilgrims at the gate, the Forge of Return
	"durchbruch": ["research", "hightech"],    # the Directorate's capital – the sphere, the institute
	"altwerft": ["industry", "mining"],        # Earthworks
	"erzhalde": ["mining", "industry"],        # Kanayama Heavy Industries
	"perlmutt": ["tourism", "hightech"],       # Atelier Aurelle
	"schwarzwacht": ["military", "industry"],  # Hadrian Foundry
}
const SPECIAL_MAIN := 50.0
const SPECIAL_SECOND := 24.0
const SECOND_SHARE := 0.35               # a secondary economy needs this share of the main one's points

const LEVELS := ["Impoverished", "Poor", "Average", "Wealthy", "Rich"]
const LEVEL_COLORS := [Color(0.85, 0.35, 0.3), Color(0.95, 0.6, 0.3), Color(0.85, 0.85, 0.8), Color(0.55, 0.9, 0.5), Color(1.0, 0.85, 0.35)]

static var _cache := {}                  # sid -> economy (cleared with a new cluster)
static var _cache_seed := -1
static var _base_cache := {}             # sid -> starting prosperity


static func name_of(e: String) -> String:
	return String(ECONOMIES.get(e, {}).get("name", e))


static func color_of(e: String) -> Color:
	return ECONOMIES.get(e, {}).get("color", Color.WHITE)


static func _add(scores: Dictionary, factors: Array, w: Dictionary, mult: float, source: String) -> void:
	for e in w:
		var pts := float(w[e]) * mult
		scores[e] = float(scores.get(e, 0.0)) + pts
		factors.append([String(e), pts, source])


## The economy of a system: {main, second ("" = none), scores {econ: points}, factors [[econ, points, source]],
## inhabited}. Worked out once per cluster and cached.
static func of(sid: int) -> Dictionary:
	if _cache_seed != Universe.seed_value:
		_cache.clear()
		_base_cache.clear()
		_cache_seed = Universe.seed_value
	if _cache.has(sid):
		return _cache[sid]
	var r := _compute(sid)
	_cache[sid] = r
	return r


static func clear_cache() -> void:
	_cache.clear()
	_base_cache.clear()


static func _compute(sid: int) -> Dictionary:
	var L: Dictionary = Universe.get_layout(sid)
	var scores := {}
	var factors: Array = []
	for p in L["planets"]:
		var pt := String(p["type"])
		_add(scores, factors, PLANET_WEIGHTS.get(pt, {}), 1.0, String(p["name"]))
	for m in L.get("moons", []):
		var mt := String(m["type"])
		if MOON_WEIGHTS.has(mt):
			_add(scores, factors, MOON_WEIGHTS[mt], 1.0, String(m["name"]))
		else:
			_add(scores, factors, PLANET_WEIGHTS.get(mt, {}), MOON_PLANET_SHARE, String(m["name"]))
	for f in L["fields"]:
		_add(scores, factors, FIELD_WEIGHTS.get(String(f.get("class", "stony")), {}), 1.0, String(f["name"]))
	for b in L.get("belts", []):
		_add(scores, factors, BELT_WEIGHTS.get(String(b["kind"]), {}), 1.0, "Kuiper belt" if String(b["kind"]) == "kuiper" else "Asteroid belt")
	for st in L["stations"]:
		_add(scores, factors, STATION_WEIGHTS.get(String(st["type"]), {}), float(st.get("tier", 1)), String(st["name"]))
	var sp := Universe.special_of(sid)
	if SPECIAL.has(sp):
		_add(scores, factors, {SPECIAL[sp][0]: SPECIAL_MAIN}, 1.0, "%s's own trade" % Universe.systems[sid]["name"])
		_add(scores, factors, {SPECIAL[sp][1]: SPECIAL_SECOND}, 1.0, "%s's own trade" % Universe.systems[sid]["name"])
	var ranked: Array = scores.keys()
	ranked.sort_custom(func(a, b): return float(scores[a]) > float(scores[b]) or (is_equal_approx(float(scores[a]), float(scores[b])) and ORDER.find(a) < ORDER.find(b)))
	var main := String(ranked[0]) if not ranked.is_empty() else "mining"
	var second := ""
	if ranked.size() > 1 and float(scores[ranked[1]]) >= float(scores[main]) * SECOND_SHARE and float(scores[ranked[1]]) >= 2.0:
		second = String(ranked[1])
	factors.sort_custom(func(a, b): return float(a[1]) > float(b[1]))
	return {"main": main, "second": second, "scores": scores, "factors": factors, "inhabited": not L["stations"].is_empty()}


## Does the system have this economy (main or secondary)?
static func has_economy(sid: int, e: String) -> bool:
	var ec := of(sid)
	return ec["main"] == e or ec["second"] == e


## Short text: "Mining · Industry" (secondary in brackets when weak? – both named).
static func label(sid: int) -> String:
	var ec := of(sid)
	if not ec["inhabited"]:
		return "Undeveloped (%s)" % name_of(ec["main"])
	return name_of(ec["main"]) + (" · " + name_of(ec["second"]) if ec["second"] != "" else "")


## The strongest reasons for an economy (for the system info): up to `n` sources.
static func reasons(sid: int, e: String, n: int = 3) -> Array:
	var out: Array = []
	for f in of(sid)["factors"]:
		if f[0] == e and not String(f[2]) in out:
			out.append(String(f[2]))
			if out.size() >= n:
				break
	return out


# ---------------------------------------------------------------- Prosperity

## Where a system's prosperity starts: people, stations, security, capitals and the makers' homes; uninhabited
## systems stay poor. Deterministic for the cluster (seed and system).
static func base_prosperity(sid: int) -> float:
	if _cache_seed != Universe.seed_value:
		_cache.clear()
		_base_cache.clear()
		_cache_seed = Universe.seed_value
	if _base_cache.has(sid):
		return _base_cache[sid]
	var v := _base(sid)
	_base_cache[sid] = v
	return v


static func _base(sid: int) -> float:
	var sys: Dictionary = Universe.systems[sid]
	var prof: Dictionary = Universe.system_profile(sid)
	if int(prof["stations"]) == 0:
		return clampf(8.0 + float(prof["population"]) * 2.0, 3.0, 24.0)
	var sec := float(sys["security"])
	var v := 6.0 + sec * 34.0 + minf(float(prof["population"]), 9.0) * 2.6 + float(prof["tiers"]) * 2.2
	if sys.get("capital", false):
		v += 14.0
	var sp := Universe.special_of(sid)
	if sp in ["landfall", "heimkehr", "durchbruch"]:
		v += 12.0
	elif sp != "":
		v += 8.0
	if int(sys.get("haven_tier", 0)) > 0:
		v -= 10.0
	var h := hash([Universe.seed_value, sid, "prosperity"])
	v += float(h % 1700) / 100.0 - 8.5
	return clampf(v, 4.0, 97.0)


## The prosperity of a system now (0–100).
static func prosperity(sid: int) -> float:
	if GameState.prosperity.has(sid):
		return float(GameState.prosperity[sid])
	return base_prosperity(sid)


static func set_prosperity(sid: int, v: float) -> void:
	GameState.prosperity[sid] = clampf(v, 0.0, 100.0)


## 0 Impoverished … 4 Rich.
static func level(sid: int) -> int:
	return clampi(int(prosperity(sid) / 20.0), 0, 4)


static func level_name(sid: int) -> String:
	return LEVELS[level(sid)]


static func level_color(sid: int) -> Color:
	return LEVEL_COLORS[level(sid)]
