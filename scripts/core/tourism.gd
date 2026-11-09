class_name Tourism
extends RefCounted
## Package 43: tourism – the sights of a system and its resorts. The sights are what tourists come to see: the
## beautiful worlds, the ringed giants, a wondrous star (red supergiant, neutron star, black hole, blue giant) and the
## great landmarks of the hand-made systems. Round trips (package 43b) take tourists from another system to one of them.

const SIGHT_ARTS := {
	"vote": "The Vote", "res_publica": "the Res Publica", "cathedral": "the Cathedral of Return",
	"pilgrim_gate": "the Pilgrim Gate", "lux_aeterna": "the Lux Aeterna", "dyson_hub": "the Meridian Sphere",
	"aur_yard": "the Atelier Aurelle", "hdy_yard": "the Hadrian Foundry",
}
const STAR_SIGHTS := {"giant": "the red supergiant", "neutron": "the neutron star", "blackhole": "the black hole"}
const KIND_APPEAL := {"star": 3.0, "landmark": 2.5, "rings": 2.0, "world": 1.5}

static var _cache := {}
static var _cache_seed := -1


## The sights of a system: [{id, name, kind (world / rings / star / landmark), body (planet id, "star" or station id),
## appeal}], best first.
static func sights(sid: int) -> Array:
	if _cache_seed != Universe.seed_value:
		_cache.clear()
		_cache_seed = Universe.seed_value
	if _cache.has(sid):
		return _cache[sid]
	var L: Dictionary = Universe.get_layout(sid)
	var out: Array = []
	var st_t: Dictionary = Universe.STAR_TYPES[Universe.star_index(String(L["star"].get("star_id", "G")))]
	var sk := String(st_t["kind"])
	if STAR_SIGHTS.has(sk) or String(st_t["id"]) == "O":
		out.append({"id": "sight_star", "name": "%s of %s" % [String(STAR_SIGHTS.get(sk, "the blue giant")).capitalize(), Universe.systems[sid]["name"]],
			"kind": "star", "body": "star", "appeal": KIND_APPEAL["star"]})
	for p in L["planets"]:
		var pt := String(p["type"])
		if pt in Universe.CITY_WORLDS:
			out.append({"id": "sight_" + String(p["id"]), "name": "%s (%s)" % [p["name"], Universe.PLANET_TYPES[pt]["name"]],
				"kind": "world", "body": String(p["id"]), "appeal": KIND_APPEAL["world"]})
		elif p.get("ring", false) and float(Universe.PLANET_TYPES.get(pt, {}).get("gas", 0.0)) > 0.5:
			out.append({"id": "sight_" + String(p["id"]), "name": "The rings of %s" % p["name"],
				"kind": "rings", "body": String(p["id"]), "appeal": KIND_APPEAL["rings"]})
	for st in L["stations"]:
		var art := String(st.get("art", ""))
		if SIGHT_ARTS.has(art):
			out.append({"id": "sight_" + String(st["id"]), "name": String(SIGHT_ARTS[art]).capitalize(), "kind": "landmark",
				"body": String(st["id"]), "appeal": KIND_APPEAL["landmark"]})
	out.sort_custom(func(a, b): return float(a["appeal"]) > float(b["appeal"]))
	_cache[sid] = out
	return out


static func clear_cache() -> void:
	_cache.clear()


## The resorts of a system (stations of type "resort").
static func resorts(sid: int) -> Array:
	var out: Array = []
	for st in Universe.get_layout(sid)["stations"]:
		if String(st["type"]) == "resort":
			out.append(st)
	return out
