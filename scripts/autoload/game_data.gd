extends Node
## Static game data (hulls, modules, goods, presets, corporations, station services) and helpers.
## The data lives in res://data/*.gd – add new ships/modules/services there.

const HullData = preload("res://data/hulls.gd")
const ModuleData = preload("res://data/modules.gd")
const CommodityData = preload("res://data/commodities.gd")
const PresetData = preload("res://data/presets.gd")
const CorpData = preload("res://data/corporations.gd")
const ServiceData = preload("res://data/station_services.gd")

const DAMAGE_TYPES := ["optical", "kinetic", "explosive"]
const DAMAGE_NAMES := {"optical": "Optical", "kinetic": "Kinetic", "explosive": "Explosive"}
const DAMAGE_COLORS := {
	"optical": Color(0.4, 0.9, 1.0),
	"kinetic": Color(1.0, 0.85, 0.4),
	"explosive": Color(1.0, 0.45, 0.25),
}
## Damage multiplier per protective layer: optical is strong against shields,
## kinetic against armour, explosive against structure.
const LAYER_MULT := {
	"shield": {"optical": 1.3, "kinetic": 0.7, "explosive": 0.9},
	"armor": {"optical": 0.8, "kinetic": 1.25, "explosive": 1.0},
	"structure": {"optical": 0.9, "kinetic": 1.0, "explosive": 1.4},
}
const CORE_SLOTS := ["hull", "engine", "distributor", "reactor", "tank", "hyperdrive", "sensors"]
const SLOT_NAMES := {
	"hull": "Hull Plating", "engine": "Engine", "distributor": "Power Distributor", "reactor": "Reactor",
	"tank": "Fuel Tank", "hyperdrive": "Hyperdrive", "sensors": "Sensors",
	"weapon": "Weapon", "tool": "Tool", "optional": "Optional",
}
const SIZE_NAMES := {1: "S", 2: "M", 3: "L"}
const TOOL_NAMES := {
	"scanner": "Scanner", "analyzer": "Analyzer", "mining": "Mining Laser",
	"salvage": "Salvager", "repair": "Repair Beam", "harvester": "Ice Harvester",
	"survey": "Long-Range Survey", "prospect": "Prospector", "warrant": "Warrant Scanner", "interdict": "Warp Interdictor",
}
const MODULE_ITEM_VOLUME := 5.0

var hulls: Dictionary = HullData.HULLS
var modules: Dictionary = ModuleData.MODULES
var commodities: Dictionary = CommodityData.COMMODITIES
const CLASS_NAMES := CommodityData.CLASS_NAMES
## station types incl. the Pirate Haven (dockable with pirate standing, package 12)
var station_types: Dictionary = CommodityData.STATION_TYPES.merged({"pirate_haven": CommodityData.HAVEN_TYPE})
var presets: Dictionary = PresetData.PRESETS
var corps: Dictionary = CorpData.CORPS
var services: Array = ServiceData.SERVICES


func slot_label(key: String) -> String:
	var t := ShipFitting.slot_type(key)
	var base: String = SLOT_NAMES.get(t, t)
	var idx := key.find("_")
	if idx >= 0:
		return "%s %d" % [base, int(key.substr(idx + 1)) + 1]
	return base


func module_name(id: String) -> String:
	if not modules.has(id):
		return "?"
	var m: Dictionary = modules[id]
	return "%s [%s]" % [m["name"], SIZE_NAMES[int(m["size"])]]


## Cargo items: commodity ids or "mod:<module_id>" for found modules.
func item_name(item_id: String) -> String:
	if item_id.begins_with("mod:"):
		return "Module: " + module_name(item_id.substr(4))
	if commodities.has(item_id):
		return commodities[item_id]["name"]
	return item_id


func item_volume(item_id: String) -> float:
	if item_id.begins_with("mod:"):
		return MODULE_ITEM_VOLUME
	if commodities.has(item_id):
		return float(commodities[item_id]["volume"])
	return 1.0


## Base value of a cargo item (for net worth estimates).
func item_value(item_id: String) -> float:
	if item_id.begins_with("mod:"):
		var mid := item_id.substr(4)
		return float(modules[mid]["price"]) * 0.6 if modules.has(mid) else 0.0
	if commodities.has(item_id):
		return float(commodities[item_id]["price"])
	return 0.0


func is_tradeable(item_id: String) -> bool:
	return commodities.has(item_id) and bool(commodities[item_id].get("tradeable", true))


func preset_price(preset_id: String) -> int:
	var p: Dictionary = presets[preset_id]
	var total := int(hulls[p["hull"]]["price"])
	for k in p["modules"]:
		total += int(modules[p["modules"][k]]["price"])
	return total


func corp(corp_id: String) -> Dictionary:
	return corps.get(corp_id, {"name": "?", "tag": "?", "color": Color.WHITE, "slogan": "", "desc": ""})


func module_summary(id: String) -> String:
	var m: Dictionary = modules[id]
	var parts: Array = []
	parts.append("%s – %s (size %s)" % [m["name"], SLOT_NAMES[m["slot"]], SIZE_NAMES[int(m["size"])]])
	if m.has("damage_type"):
		parts.append("Damage type: " + DAMAGE_NAMES[m["damage_type"]])
	if m.has("tool"):
		parts.append("Tool: " + TOOL_NAMES[m["tool"]])
	var labels := {
		"armor": "Armor", "thrust": "Thrust (kN)", "turn": "Agility", "output": "Output (MW)",
		"capacitor": "Capacitor", "recharge": "Recharge/s", "efficiency": "Efficiency",
		"fuel": "Fuel", "drive_class": "Drive class", "jump_fuel": "Fuel per jump",
		"spool": "Spool-up (s)", "range": "Range", "resolution": "Resolution",
		"scan_strength": "Scan strength", "damage": "Damage", "cooldown": "Cooldown (s)",
		"energy": "Energy/activation", "projectile_speed": "Projectile speed", "splash": "Blast radius",
		"strength": "Strength", "rate": "Rate", "cargo": "Cargo capacity", "shield": "Shield",
		"shield_regen": "Shield regen/s", "speed_mult": "Speed ×", "range_mult": "Weapon range ×",
		"res_bonus": "Resolution +", "cap_bonus": "Capacitor +", "ore_cargo": "Ore hold (ore & ice only)",
		"scan_time": "Scan time (s)", "accuracy": "Estimate error ±", "boost": "Speed × while on",
		"energy_rate": "Energy/s while on", "survey_range_mult": "Survey range ×",
	}
	for k in labels:
		if m.has(k):
			if k == "projectile_speed" and float(m[k]) <= 0.0:
				parts.append("Projectile: Beam (instant hit)")
			else:
				parts.append("%s: %s" % [labels[k], str(m[k])])
	if m.get("homing", false):
		parts.append("Guidance: homing")
	if m.has("mining_bonus"):
		for cls in m["mining_bonus"]:
			parts.append("Mining rate +%d%% on %s asteroids" % [int(float(m["mining_bonus"][cls]) * 100.0), String(cls)])
	if m.has("active"):
		parts.append("Active module – switch it on in the module bar (uses energy while on)")
	if m.get("tool", "") == "survey":
		parts.append("Aimed at the place in the selection panel (field, planet, anomaly, gate …)")
	if m.has("damage") and m.has("cooldown"):
		parts.append("DPS: %.1f" % (float(m["damage"]) / float(m["cooldown"])))
	if m.has("res"):
		var r: Dictionary = m["res"]
		for dt in r:
			parts.append("%s resistance: %d%%" % [DAMAGE_NAMES[dt], int(float(r[dt]) * 100.0)])
	parts.append("Mass: %d t" % int(m["mass"]))
	parts.append("Power draw: %d MW" % int(m["power"]))
	parts.append("Price: %s" % fmt_credits(int(m["price"])))
	return "\n".join(PackedStringArray(parts))


func fmt_credits(v: float) -> String:
	var s := str(int(v))
	var out := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		count += 1
		if count % 3 == 0 and i > 0 and s[i - 1] != "-":
			out = "," + out
	return out + " cr"
