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
	"shield_transfer": "Shield Transfer", "cargo_scan": "Cargo Scanner",
}
## Package 20: shield variants – downtime factor after a collapse (capacity: long, regen: short)
const SHIELD_KINDS := {"balanced": {"name": "Balanced", "down": 1.0}, "capacity": {"name": "High capacity", "down": 1.35},
	"regen": {"name": "Fast regeneration", "down": 0.6}}
## Package 20: mines (commodities) – what they do when they go off
const MINES := {
	"mine_proximity": {"name": "Proximity Mine", "trigger": 280.0, "damage": 210.0, "splash": 170.0, "color": Color(1.0, 0.45, 0.25),
		"text": "explodes when a hostile ship comes within 280 km (armed after 3 s)"},
	"mine_timer": {"name": "Timed Mine", "damage": 360.0, "splash": 240.0, "color": Color(1.0, 0.8, 0.3),
		"text": "explodes after the time set on the launcher – hits everything hostile in its blast"},
	"mine_jammer": {"name": "Jammer Mine", "trigger": 6000.0, "jam_time": 45.0, "color": Color(0.7, 0.5, 1.0),
		"text": "jams the radar of hostile ships within 6,000 km for 45 s"},
	"mine_emp": {"name": "EMP Mine", "trigger": 320.0, "splash": 650.0, "emp_time": 8.0, "color": Color(0.4, 0.85, 1.0),
		"text": "goes off near a hostile ship: shields collapse, capacitor and modules are dead for 8 s"},
}
const MINE_LIFE := 300.0            # mines disappear after 5 minutes
const MINE_TIMERS := [5, 10, 20, 30, 60]
const MODULE_ITEM_VOLUME := 5.0

var hulls: Dictionary = HullData.HULLS
## Every module family in every size and quality (phase 0.5 package 19, data/modules.gd).
var modules: Dictionary = ModuleData.build_all()
var commodities: Dictionary = CommodityData.COMMODITIES
const CLASS_NAMES := CommodityData.CLASS_NAMES
## station types incl. the Pirate Haven (dockable with pirate standing, package 12)
var station_types: Dictionary = CommodityData.STATION_TYPES.merged({"pirate_haven": CommodityData.HAVEN_TYPE})
## Presets with their modules converted to the family/size/quality system (sizes fit the hull's slots).
var presets: Dictionary = _convert_presets()
var corps: Dictionary = CorpData.CORPS
var services: Array = ServiceData.SERVICES


static func _convert_presets() -> Dictionary:
	var out: Dictionary = PresetData.PRESETS.duplicate(true)
	for pid in out:
		var p: Dictionary = out[pid]
		var h: Dictionary = HullData.HULLS[p["hull"]]
		var conv := {}
		for key in p["modules"]:
			conv[key] = ModuleData.legacy(String(p["modules"][key]), slot_max_of(h, key))
		p["modules"] = conv
	return out


## Maximum module size of slot `key` ("engine", "weapon_1" …) on hull `h` (0 = no such slot).
static func slot_max_of(h: Dictionary, key: String) -> int:
	var ss: Dictionary = h.get("slot_sizes", {})
	var idx := key.find("_")
	if idx < 0:
		return int(ss.get(key, 0))
	var t := key.substr(0, idx)
	var n := int(key.substr(idx + 1))
	var lst: Array = ss.get(t, [])
	return int(lst[n]) if n < lst.size() else 0


## Module id of an old S/M/L module (presets, start storage, tests).
func legacy_id(old_id: String, max_size: int = 99, quality: String = "C") -> String:
	return ModuleData.legacy(old_id, max_size, quality)


## Largest module size a station of `tier` sells or builds for a slot type.
static func size_cap(slot: String, tier: int) -> int:
	var t := clampi(tier, 1, 3) - 1
	match slot:
		"weapon", "tool":
			return [2, 3, 4][t]
		"optional":
			return [3, 6, 8][t]
	return [4, 7, 10][t]


## "Large" modules need exotic materials to build (weapons/tools 3+, optional 5+, core 7+).
func is_large(id: String) -> bool:
	var m: Dictionary = modules[id]
	match String(m["slot"]):
		"weapon", "tool":
			return int(m["size"]) >= 3
		"optional":
			return int(m["size"]) >= 5
	return int(m["size"]) >= 7


## Military-grade gear (package 12: Friendly standing needed at Military Outposts).
func is_military_grade(id: String) -> bool:
	var m: Dictionary = modules[id]
	match String(m["slot"]):
		"weapon":
			return int(m["size"]) >= 4
		"tool":
			return false
		"optional":
			return int(m["size"]) >= 6
	return int(m["size"]) >= 8


## Colour for a module size 1–10 (tiles, labels).
static func size_color(size: int) -> Color:
	var t := clampf((size - 1) / 9.0, 0.0, 1.0)
	return Color(0.55, 0.65, 0.75).lerp(Color(0.4, 0.75, 1.0), minf(t * 2.0, 1.0)).lerp(Color(1.0, 0.7, 0.3), maxf(t * 2.0 - 1.0, 0.0))


static func quality_color(q: String) -> Color:
	return ModuleData.QUALITY_COLORS.get(q, Color.WHITE)


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
	return String(modules[id]["name"])


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
	parts.append("%s – %s, size %d, quality %s" % [m["base_name"], SLOT_NAMES[m["slot"]], int(m["size"]), m["quality"]])
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
		"intercept": "Intercept chance", "max_mines": "Mines out at once", "jam_range": "Jamming radius",
		"solar": "Fuel/s next to the star",
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
	if m.has("shield_kind"):
		parts.append("Shield type: %s – after a collapse it stays down for a while (longer for big, high-capacity and low-quality shields), then restarts at 50 %%" % SHIELD_KINDS[m["shield_kind"]]["name"])
	if m.get("pd", false):
		parts.append("Point defense – switched on, it shoots down hostile missiles, torpedoes and mines by itself")
	if m.get("mines", false):
		parts.append("Lays mines from your cargo hold – right-click its tile to pick the mine type and the timer")
	if m.get("active", "") == "jammer":
		parts.append("Hostile ships in range lose their radar picture and cannot lock you from afar")
	if m.has("solar"):
		parts.append("Refuels while you are in space – fastest close to the star, little in the outer system")
	if m.get("tool", "") == "shield_transfer":
		parts.append("Charges the shield of a locked friendly ship from your capacitor (not from your shield); shortens its shield downtime")
	if m.get("tool", "") == "cargo_scan":
		parts.append("Reads the cargo manifest of a locked ship (smugglers carry unregistered cargo)")
	if m.get("tool", "") == "survey":
		parts.append("Aimed at the place in the selection panel (field, planet, anomaly, gate …)")
	if m.has("damage") and m.has("cooldown") and float(m["damage"]) > 0.0:
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
