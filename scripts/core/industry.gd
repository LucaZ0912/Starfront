class_name Industry
extends RefCounted
## Local industry: ore refining and module manufacturing.
## What a station can do depends on its type (data/commodities.gd -> STATION_TYPES):
##   refinery       – refining yield (0 = no refinery)
##   manufacturing  – which module slots the fabricators can build
## Fees get cheaper when the station itself produces the input materials (local economy).

## Refining data lives in data/commodities.gd ("refines_to", "yield", "class").
const REFINE_FEE_PER_UNIT := 3.0

## Material mix per module slot (relative weights). Multiplied by module price / VALUE_PER_UNIT.
const BLUEPRINT_MIX := {
	"hull": {"iron_ingot": 3.0, "nickel_ingot": 1.0, "titanium_ingot": 1.0, "alloys": 1.0},
	"engine": {"alloys": 2.0, "titanium_ingot": 1.0, "cobalt_ingot": 1.0, "electronics": 1.0},
	"distributor": {"electronics": 2.0, "silicon": 1.0, "alloys": 1.0},
	"reactor": {"titanium_ingot": 2.0, "cobalt_ingot": 1.0, "electronics": 1.0, "deuterium": 1.0},
	"tank": {"aluminium": 2.0, "iron_ingot": 1.0, "alloys": 1.0},
	"hyperdrive": {"electronics": 2.0, "titanium_ingot": 1.0, "deuterium": 1.0, "xeno_lattice": 0.5},
	"sensors": {"electronics": 2.0, "silicon": 1.0, "rare_earths": 1.0},
	"weapon": {"weapon_parts": 2.0, "alloys": 1.0, "electronics": 1.0, "magnesium": 0.5},
	"tool": {"electronics": 2.0, "alloys": 1.0, "iron_ingot": 1.0, "silicon": 1.0},
	"optional": {"alloys": 2.0, "aluminium": 1.0, "electronics": 1.0},
}
## Extra exotic materials for large (size L) modules, per slot.
const LARGE_EXTRA := {
	"reactor": {"cryo_coolant": 2}, "weapon": {"cryo_coolant": 2}, "hull": {"iridium_ingot": 2},
	"hyperdrive": {"helium3": 1}, "sensors": {"neodymium": 1}, "distributor": {"platinum_ingot": 1},
}
## Rough material value per unit used to scale recipes
const VALUE_PER_UNIT := 260.0
const BUILD_FEE_FACTOR := 0.18


# ---------------------------------------------------------------- Package 41: components

## Components from refined materials (and gases): inputs per unit made. Every station with fabricators makes them;
## the fee is a share of the component's price (cheaper at bigger stations).
const COMPONENTS := {
	"circuits": {"copper": 3, "silicon": 2},
	"battery_cells": {"lithium": 2, "aluminium": 1},
	"armor_plating": {"tungsten": 2, "iron_ingot": 2},
	"carbon_fiber": {"graphite": 2},
	"ion_propellant": {"xenon": 2},
	"magnet_coils": {"neodymium": 2, "copper": 2},
	"fusion_cells": {"helium3": 2, "deuterium": 2},
	"fuel_rods": {"enriched_uranium": 2, "tungsten": 1},
	"tritium": {"lithium": 5, "enriched_uranium": 1},
	"medical_isotopes": {"thorium": 4},
	"precision_optics": {"optical_quartz": 6, "rare_earths": 2},
	"cryo_systems": {"liquid_nitrogen": 6, "copper": 2, "carbon_dioxide": 3},
}
const COMPONENT_FEE := 0.08


static func can_fabricate_here(station: Dictionary) -> bool:
	return not station_type(station).get("manufacturing", []).is_empty()


static func component_fee(station: Dictionary, item: String) -> int:
	return int(ceil(float(GameData.commodities[item]["price"]) * COMPONENT_FEE * (4 - int(station["tier"])) / 2.0))


## How many of `item` the docked ship's hold has the materials for.
static func component_max(fit: ShipFitting, item: String) -> int:
	var n := 999
	for inp in COMPONENTS[item]:
		n = mini(n, int(floor(float(fit.cargo.get(inp, 0.0)) / float(COMPONENTS[item][inp]) + 0.0001)))
	return n


## Makes `n` of a component from the hold ("" = done, otherwise why not).
static func fabricate(fit: ShipFitting, station: Dictionary, item: String, n: int) -> String:
	if not COMPONENTS.has(item):
		return "Unknown component."
	if not can_fabricate_here(station):
		return "No fabricators at this station."
	n = mini(n, component_max(fit, item))
	if n <= 0:
		return "Not enough materials in the hold."
	var fee := component_fee(station, item) * n
	if not GameState.spend(fee):
		return "Not enough credits for the fee."
	for inp in COMPONENTS[item]:
		fit.remove_cargo(inp, float(COMPONENTS[item][inp]) * n)
	var made := fit.add_cargo(item, float(n))
	if made < float(n):
		# no room for all of it: give back the materials of the rest
		for inp2 in COMPONENTS[item]:
			fit.add_cargo(inp2, float(COMPONENTS[item][inp2]) * (n - made))
	GameState.log_msg("Fabricated %d × %s (fee %s)." % [int(made), GameData.item_name(item), GameData.fmt_credits(fee)], GameState.COL_GOOD)
	GameState.stats["built"] = int(GameState.stats["built"]) + int(made)
	return ""


static func station_type(station: Dictionary) -> Dictionary:
	return GameData.station_types[station["type"]]


# ---------------------------------------------------------------- Refining

static func is_ore(item: String) -> bool:
	return GameData.commodities.has(item) and GameData.commodities[item].has("refines_to")


## All refinable ores in data order.
static func ores() -> Array:
	var out: Array = []
	for cid in GameData.commodities:
		if is_ore(cid):
			out.append(cid)
	return out


## Station refining efficiency for one asteroid class ("metallic" / "stony" / "icy"),
## or the best class if none is given (0 = no refinery at all).
static func refinery_yield(station: Dictionary, cls: String = "") -> float:
	var r = station_type(station).get("refinery", {})
	if not (r is Dictionary):
		return float(r)
	if cls != "":
		return float(r.get(cls, 0.0))
	var best := 0.0
	for k in r:
		best = maxf(best, float(r[k]))
	return best


static func ore_yield(station: Dictionary, ore: String) -> float:
	var c: Dictionary = GameData.commodities[ore]
	return float(c["yield"]) * refinery_yield(station, c["class"])


## Preview: how much would refining `amount` units of `ore` yield, and what would it cost?
static func refine_quote(station: Dictionary, ore: String, amount: float) -> Dictionary:
	var c: Dictionary = GameData.commodities[ore]
	var out := floorf(amount * ore_yield(station, ore) * (1.1 if GameState.has_perk("efficient_refining") else 1.0)
		* (1.0 + (GameState.active().crew_bonus("refine") if GameState.active() != null else 0.0)))     # package 30, crew: package 31
	var fee := int(ceil(amount * REFINE_FEE_PER_UNIT * (4 - int(station["tier"])) / 2.0))
	return {"out_id": c["refines_to"], "out": out, "fee": fee}


## Refines ore from the ship's cargo into refined material (also into the cargo).
static func refine(fit: ShipFitting, station: Dictionary, ore: String) -> String:
	if not is_ore(ore):
		return "%s cannot be refined." % GameData.item_name(ore)
	if refinery_yield(station, GameData.commodities[ore]["class"]) <= 0.0:
		return "This refinery cannot process %s ore." % GameData.CLASS_NAMES[GameData.commodities[ore]["class"]]
	var have := floorf(float(fit.cargo.get(ore, 0.0)))
	if have < 1.0:
		return "No %s in the cargo hold." % GameData.item_name(ore)
	var q := refine_quote(station, ore, have)
	if q["out"] < 1.0:
		return "Not enough ore for a single batch."
	if not GameState.spend(int(q["fee"])):
		return "Not enough credits."
	fit.remove_cargo(ore, have)
	fit.cargo[q["out_id"]] = float(fit.cargo.get(q["out_id"], 0.0)) + float(q["out"])
	GameState.stats["refined"] = int(GameState.stats.get("refined", 0)) + int(have)
	GameState.count_stat("refined_station", float(have))             # package 30
	GameState.skill_xp("mining", 0.15 * float(have))
	return ""


# ---------------------------------------------------------------- Manufacturing

## Fabrication quality is never quite certain: mostly C, sometimes better or worse.
const BUILD_QUALITY := [["F", 0.03], ["E", 0.07], ["D", 0.18], ["C", 0.45], ["B", 0.20], ["A", 0.07]]
static var last_built := ""


static func roll_quality(module_id: String) -> String:
	var m: Dictionary = GameData.modules[module_id]
	var r := randf()
	if GameState.has_perk("master_builder"):
		r = maxf(r, randf())                     # package 30: the better of two rolls
	for e in BUILD_QUALITY:
		r -= float(e[1])
		if r <= 0.0:
			return "%s:%d:%s" % [m["family"], int(m["size"]), e[0]]
	return module_id


static func can_build_here(station: Dictionary, module_id: String) -> bool:
	var m: Dictionary = GameData.modules[module_id]
	var slots: Array = station_type(station).get("manufacturing", [])
	return m["slot"] in slots and int(m["size"]) <= GameData.size_cap(String(m["slot"]), int(station["tier"])) \
		and not m.get("pirate_only", false) and not m.get("notorious_only", false)


static func buildable(station: Dictionary) -> Array:
	var out: Array = []
	for mid in GameData.modules:
		# the list shows quality C; the finished module's quality is rolled (see build)
		if String(GameData.modules[mid]["quality"]) == "C" and can_build_here(station, mid):
			out.append(mid)
	return out


## Bill of materials + fabrication fee for a module at a station.
static func recipe(station: Dictionary, module_id: String) -> Dictionary:
	var m: Dictionary = GameData.modules[module_id]
	var mix: Dictionary = BLUEPRINT_MIX.get(m["slot"], BLUEPRINT_MIX["optional"])
	var total_w := 0.0
	for k in mix:
		total_w += float(mix[k])
	var units := float(m["price"]) / VALUE_PER_UNIT
	var mats := {}
	for k in mix:
		mats[k] = maxi(1, int(ceil(units * float(mix[k]) / total_w)))
	# Large modules need exotic material
	if GameData.is_large(module_id):
		mats["xeno_lattice"] = int(mats.get("xeno_lattice", 0)) + 2
		var extra: Dictionary = LARGE_EXTRA.get(m["slot"], {})
		for k in extra:
			mats[k] = int(mats.get(k, 0)) + int(extra[k])
	# Local economy: inputs the station produces itself make the job cheaper
	var produces: Array = station_type(station)["produces"]
	var local := 0
	for k in mats:
		if k in produces:
			local += 1
	var fee_mult := 1.0 - 0.15 * local
	return {"materials": mats, "fee": int(float(m["price"]) * BUILD_FEE_FACTOR * fee_mult)}


static func missing_materials(fit: ShipFitting, rec: Dictionary) -> Dictionary:
	var missing := {}
	for k in rec["materials"]:
		var need := float(rec["materials"][k])
		var have := float(fit.cargo.get(k, 0.0))
		if have + 0.001 < need:
			missing[k] = need - have
	return missing


# ---------------------------------------------------------------- Build time (package 25b)

const BUILD_TIME_BASE := 15.0      # seconds for a size-1 module; grows with size^1.2
const DRONE_BUILD_TIME := 40.0
## A drone from the factory of a Kanayama-maru
const DRONE_RECIPE := {"materials": {"electronics": 3, "alloys": 2, "aluminium": 2}, "fee": 0}


static func build_time(item: String) -> float:
	if item == "drone":
		return DRONE_BUILD_TIME
	return BUILD_TIME_BASE * pow(float(GameData.modules[item]["size"]), 1.2) * (0.75 if GameState.has_perk("master_builder") else 1.0)


## What a ship factory can build (Kanayama-maru): what an industrial complex builds, up to size 7.
const SHIP_FACTORY := {"id": "ship_factory", "type": "industry", "tier": 2}


## Takes the materials for `item` (a module or "drone") from the ship's cargo and queues it in the
## ship's own factory. "" = queued.
static func ship_build(fit: ShipFitting, item: String) -> String:
	var rec: Dictionary = DRONE_RECIPE if item == "drone" else recipe(SHIP_FACTORY, item)
	if item != "drone" and not can_build_here(SHIP_FACTORY, item):
		return "The ship's factory cannot build this module."
	if not missing_materials(fit, rec).is_empty():
		return "Missing materials."
	for k in rec["materials"]:
		fit.remove_cargo(k, float(rec["materials"][k]))
	var made := item if item == "drone" else roll_quality(item)
	var t := build_time(item)
	GameState.jobs.append({"kind": "ship", "uid": fit.uid, "item": made, "total": t, "left": t})
	last_built = made
	return ""


## Builds a module from materials in the ship's cargo. It takes time (build_time); the result goes
## to station storage when it is finished (GameState.jobs).
static func build(fit: ShipFitting, station: Dictionary, module_id: String) -> String:
	if not can_build_here(station, module_id):
		return "The fabricators here cannot build this module."
	var rec := recipe(station, module_id)
	if not missing_materials(fit, rec).is_empty():
		return "Missing materials."
	if not GameState.spend(int(rec["fee"])):
		return "Not enough credits."
	for k in rec["materials"]:
		fit.remove_cargo(k, float(rec["materials"][k]))
	var made := roll_quality(module_id)
	var t := build_time(module_id)
	GameState.jobs.append({"kind": "station", "station": String(station["id"]), "station_name": String(station.get("name", "")), "item": made, "total": t, "left": t})
	last_built = made
	return ""
