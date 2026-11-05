class_name ShipFitting
extends RefCounted
const ModuleData = preload("res://data/modules.gd")
## A ship's data: hull + fitted modules + current state.
## Effective values (stats) are derived from hull base values + modules.
## This class is the "source of truth" – Ship nodes in the system view read/write here.

var uid := 0
var ship_name := ""
var hull_id := ""
var faction := "player"
var gov := ""              # government / pirate faction of an NPC (paint, name) – not saved
var modules := {}          # slot_key -> module_id  (slot_key: "engine", "weapon_0", "tool_1", ...)
var cargo := {}            # item_id -> amount (float)
var structure := -1.0
var armor := -1.0
var shield := -1.0
var capacitor := -1.0
var fuel := -1.0
var system_id := 0
var position := Vector2.ZERO  # position in the system (km)
var rotation := 0.0
var docked_at := ""        # station id while docked
var route: Array = []      # remaining systems of the hyperspace route
var stance := "aggressive" # aggressive / defensive / passive
# Hyperspace jump between systems
var transit_kind := ""     # "" / "jump"
var transit_to = null      # destination system
var transit_from = null    # origin system
var transit := 0.0         # remaining seconds
var transit_total := 1.0

var _stats := {}
var _dirty := true


func _init(p_hull: String = "", p_faction: String = "player") -> void:
	hull_id = p_hull
	faction = p_faction


func hull() -> Dictionary:
	return GameData.hulls[hull_id]


static func slot_type(key: String) -> String:
	var idx := key.find("_")
	return key if idx < 0 else key.substr(0, idx)


func slot_keys() -> Array:
	var keys: Array = []
	for c in GameData.CORE_SLOTS:
		if GameData.slot_max_of(hull(), c) > 0:
			keys.append(c)
	var slots: Dictionary = hull()["slots"]
	for t in ["weapon", "tool", "optional"]:
		for i in int(slots.get(t, 0)):
			keys.append("%s_%d" % [t, i])
	return keys


## Maximum module size of a slot of this hull (package 19).
func slot_max(key: String) -> int:
	return GameData.slot_max_of(hull(), key)


func get_module(key: String) -> String:
	return modules.get(key, "")


## Empty string = fits, otherwise the reason.
func can_fit(key: String, module_id: String) -> String:
	if module_id == "":
		return ""
	if not GameData.modules.has(module_id):
		return "Unknown module"
	var m: Dictionary = GameData.modules[module_id]
	if m["slot"] != slot_type(key):
		return "Wrong slot type"
	var mx := slot_max(key)
	if mx <= 0:
		return "This hull has no such slot"
	if int(m["size"]) > mx:
		return "Too large – this slot takes modules up to size %d" % mx
	if m.get("notorious_only", false):
		return "Only notorious pirate captains can use this"
	return ""


## Sets a module (or "" to unfit) and returns the previous one.
func set_module(key: String, module_id: String) -> String:
	var prev: String = modules.get(key, "")
	if module_id == "":
		modules.erase(key)
	else:
		modules[key] = module_id
	mark_dirty()
	clamp_values()
	return prev


# ---------------------------------------------------------------- Save / network format

const SAVE_FIELDS := ["uid", "ship_name", "hull_id", "faction", "modules", "cargo", "structure", "armor",
	"shield", "capacitor", "fuel", "system_id", "position", "rotation", "docked_at", "route", "stance",
	"transit_kind", "transit_to", "transit_from", "transit", "transit_total"]


## Plain data (ids, numbers, strings, vectors) – used by save games and later the network.
func to_dict() -> Dictionary:
	var d := {}
	for k in SAVE_FIELDS:
		var v = get(k)
		d[k] = v.duplicate(true) if (v is Dictionary or v is Array) else v
	return d


static func from_dict(d: Dictionary) -> ShipFitting:
	var f := ShipFitting.new(String(d["hull_id"]), String(d.get("faction", "player")))
	for k in SAVE_FIELDS:
		if d.has(k):
			var v = d[k]
			f.set(k, v.duplicate(true) if (v is Dictionary or v is Array) else v)
	f.mark_dirty()
	return f


func mark_dirty() -> void:
	_dirty = true


func stats() -> Dictionary:
	if _dirty:
		_stats = _compute()
		_dirty = false
	return _stats


func _compute() -> Dictionary:
	var h := hull()
	var s := {
		"structure_max": float(h["structure"]), "armor_max": 0.0, "shield_max": 0.0, "shield_regen": 0.0,
		"res": {"optical": 0.0, "kinetic": 0.0, "explosive": 0.0},
		"mass": float(h["mass"]), "cargo_max": float(h["cargo"]), "signature": float(h["signature"]),
		"thrust": 0.0, "turn": 1.5, "power_output": 0.0, "power_draw": 0.0, "efficiency": 1.0,
		"cap_max": 0.0, "cap_recharge": 0.0, "fuel_max": 0.0,
		"drive_class": 0, "jump_fuel_base": 0.0, "spool": 0.0,
		"sensor_range": 300.0, "resolution": 0.5, "scan_strength": 0.5,
		"speed_mult": 1.0, "range_mult": 1.0, "ore_cargo_max": 0.0, "survey_range_mult": 1.0,
		"mining_bonus": {"metallic": 0.0, "stony": 0.0, "icy": 0.0},
		"weapons": [], "tools": [], "actives": [], "missing": [],
		"pd": [], "minelayers": [], "solar": 0.0, "shield_downtime": 0.0,
	}
	var down_w := 0.0                # shield downtime: capacity-weighted factor of the shield modules
	for key in slot_keys():
		var mid: String = modules.get(key, "")
		if mid == "" or not GameData.modules.has(mid):
			if key in GameData.CORE_SLOTS:
				s["missing"].append(key)
			continue
		var m: Dictionary = GameData.modules[mid]
		s["mass"] += float(m.get("mass", 0))
		s["power_draw"] += float(m.get("power", 0))
		match m["slot"]:
			"hull":
				s["armor_max"] += float(m.get("armor", 0))
				var r: Dictionary = m.get("res", {})
				for dt in r:
					s["res"][dt] += float(r[dt])
			"engine":
				s["thrust"] += float(m.get("thrust", 0))
				s["turn"] = float(m.get("turn", 2.0))
			"reactor":
				s["power_output"] += float(m.get("output", 0))
			"distributor":
				s["cap_max"] += float(m.get("capacitor", 0))
				s["cap_recharge"] += float(m.get("recharge", 0))
				s["efficiency"] = float(m.get("efficiency", 1.0))
			"tank":
				s["fuel_max"] += float(m.get("fuel", 0))
			"hyperdrive":
				s["drive_class"] = int(m.get("drive_class", 0))
				s["jump_fuel_base"] = float(m.get("jump_fuel", 0))
				s["spool"] = float(m.get("spool", 3.0))
			"sensors":
				s["sensor_range"] = float(m.get("range", 300))
				s["resolution"] = float(m.get("resolution", 0.5))
				s["scan_strength"] = float(m.get("scan_strength", 0.5))
			"weapon":
				var w: Dictionary = m.duplicate()
				w["id"] = mid
				w["slot"] = key
				if w.get("pd", false):
					s["pd"].append(w)          # point defense: not a gun for ships (package 20)
				elif w.get("mines", false):
					s["minelayers"].append(w)
				else:
					s["weapons"].append(w)
			"tool":
				var t: Dictionary = m.duplicate()
				t["id"] = mid
				t["slot"] = key
				s["tools"].append(t)
			"optional":
				s["cargo_max"] += float(m.get("cargo", 0))
				s["shield_max"] += float(m.get("shield", 0))
				if m.has("shield"):
					var kind_f := float(GameData.SHIELD_KINDS.get(String(m.get("shield_kind", "balanced")), {}).get("down", 1.0))
					var perf := float(ModuleData.QUALITY.get(String(m.get("quality", "C")), {}).get("perf", 1.0))
					down_w += float(m["shield"]) * kind_f / perf
				s["solar"] += float(m.get("solar", 0.0))
				s["shield_regen"] += float(m.get("shield_regen", 0))
				s["armor_max"] += float(m.get("armor", 0))
				s["fuel_max"] += float(m.get("fuel", 0))
				s["cap_max"] += float(m.get("cap_bonus", 0))
				s["resolution"] += float(m.get("res_bonus", 0))
				s["speed_mult"] *= float(m.get("speed_mult", 1.0))
				s["range_mult"] *= float(m.get("range_mult", 1.0))
				s["ore_cargo_max"] += float(m.get("ore_cargo", 0))
				s["survey_range_mult"] *= float(m.get("survey_range_mult", 1.0))
				var mb: Dictionary = m.get("mining_bonus", {})
				for cls in mb:
					s["mining_bonus"][cls] = float(s["mining_bonus"].get(cls, 0.0)) + float(mb[cls])
				if m.has("active"):
					var a: Dictionary = m.duplicate()
					a["id"] = mid
					a["slot"] = key
					s["actives"].append(a)

	# Power budget: overload throttles all systems proportionally.
	var available: float = s["power_output"] * s["efficiency"]
	var ratio := 1.0
	if s["power_draw"] > available:
		ratio = maxf(0.25, available / maxf(s["power_draw"], 0.001))
	s["power_ratio"] = ratio

	s["speed"] = s["thrust"] * 1000.0 / maxf(s["mass"], 1.0) * s["speed_mult"] * ratio
	s["accel"] = s["speed"] * 1.3
	s["warp_mult"] = clampf(s["speed"] / 300.0, 0.6, 1.6)
	s["warp_speed"] = 150000.0 * s["warp_mult"]
	s["turn"] = s["turn"] * (0.5 + 0.5 * ratio)
	s["cap_recharge"] *= ratio
	s["shield_regen"] *= ratio
	s["sensor_range"] *= (0.5 + 0.5 * ratio)
	s["jump_fuel"] = s["jump_fuel_base"] * sqrt(s["mass"] / 1500.0)
	s["signature"] += s["mass"] * 0.004
	for dt in s["res"]:
		s["res"][dt] = clampf(s["res"][dt], 0.0, 0.8)
	# package 20: a collapsed shield stays down for a while – longer for big shields, high-capacity
	# variants and low quality – and comes back at 50 %
	if s["shield_max"] > 0.0:
		s["shield_downtime"] = clampf(down_w / s["shield_max"] * (4.0 + sqrt(s["shield_max"]) / 3.0), 3.0, 60.0)
	for pd in s["pd"]:
		pd["range"] = float(pd["range"]) * s["range_mult"]
		pd["cooldown"] = float(pd["cooldown"]) / ratio

	var dps := {"optical": 0.0, "kinetic": 0.0, "explosive": 0.0}
	var min_range := INF
	for w in s["weapons"]:
		w["range"] = float(w["range"]) * s["range_mult"]
		w["cooldown"] = float(w["cooldown"]) / ratio
		dps[w["damage_type"]] += float(w["damage"]) / float(w["cooldown"])
		min_range = minf(min_range, w["range"])
	for t2 in s["tools"]:
		if t2["tool"] == "survey":
			t2["range"] = float(t2["range"]) * s["survey_range_mult"]
	s["dps"] = dps
	s["dps_total"] = dps["optical"] + dps["kinetic"] + dps["explosive"]
	s["optimal_range"] = min_range * 0.8 if min_range < INF else s["sensor_range"] * 0.5
	return s


func in_transit() -> bool:
	return transit_kind != ""


func location_text() -> String:
	if transit_kind == "jump":
		return "Hyperspace → %s" % Universe.systems[int(transit_to)]["name"]
	var sys: String = Universe.systems[system_id]["name"]
	if docked_at != "":
		var st := Universe.find_station(system_id, docked_at)
		return "%s – %s" % [sys, st.get("name", "Station")]
	return sys


## Modules the pilot activates manually (module bar, keys 1–9): weapons first, then tools.
## Passive modules (hull, engine, scanner sweep, cargo racks, …) are not listed.
## Each entry: {slot, kind: "weapon"|"tool", data: stats entry (ranges already modified)}.
const PASSIVE_TOOLS := ["scanner"]


func active_modules() -> Array:
	var out: Array = []
	var s := stats()
	for w in s["weapons"]:
		out.append({"slot": w["slot"], "kind": "weapon", "data": w})
	for pd in s["pd"]:
		out.append({"slot": pd["slot"], "kind": "pd", "data": pd})
	for ml in s["minelayers"]:
		out.append({"slot": ml["slot"], "kind": "mine", "data": ml})
	for t in s["tools"]:
		if not t["tool"] in PASSIVE_TOOLS:
			out.append({"slot": t["slot"], "kind": "tool", "data": t})
	for a in s["actives"]:
		out.append({"slot": a["slot"], "kind": "self", "data": a})
	return out


func has_tool(tool: String) -> bool:
	for t in stats()["tools"]:
		if t["tool"] == tool:
			return true
	return false


func get_tool(tool: String) -> Dictionary:
	var best := {}
	for t in stats()["tools"]:
		if t["tool"] == tool and (best.is_empty() or float(t.get("range", 0)) > float(best.get("range", 0))):
			best = t
	return best


func refill() -> void:
	var s := stats()
	structure = s["structure_max"]
	armor = s["armor_max"]
	shield = s["shield_max"]
	capacitor = s["cap_max"]
	fuel = s["fuel_max"]


## After refitting at a station: refill shields and capacitor, clamp to new maxima.
func refill_docked() -> void:
	var s := stats()
	shield = s["shield_max"]
	capacitor = s["cap_max"]
	clamp_values()


func clamp_values() -> void:
	var s := stats()
	structure = minf(structure, s["structure_max"])
	armor = minf(armor, s["armor_max"])
	shield = minf(shield, s["shield_max"])
	capacitor = minf(capacitor, s["cap_max"])
	fuel = minf(fuel, s["fuel_max"])


# ---------------------------------------------------------------- Cargo

## Ore and ice go into the ore hold first (if fitted); everything else (and ore overflow) uses
## the general cargo hold.
static func is_ore(item: String) -> bool:
	return GameData.commodities.get(item, {}).get("category", "") == "ore"


func ore_volume() -> float:
	var v := 0.0
	for item in cargo:
		if is_ore(item):
			v += float(cargo[item]) * GameData.item_volume(item)
	return v


## Volume used in the ore hold.
func ore_hold_used() -> float:
	return minf(ore_volume(), float(stats()["ore_cargo_max"]))


## Volume used in the general cargo hold.
func cargo_used() -> float:
	var used := 0.0
	for item in cargo:
		if not is_ore(item):
			used += float(cargo[item]) * GameData.item_volume(item)
	return used + maxf(0.0, ore_volume() - float(stats()["ore_cargo_max"]))


func cargo_free() -> float:
	return maxf(0.0, float(stats()["cargo_max"]) - cargo_used())


## Free space for a given item (ore may also use the ore hold).
func free_for(item: String) -> float:
	var f := cargo_free()
	if is_ore(item):
		f += maxf(0.0, float(stats()["ore_cargo_max"]) - ore_volume())
	return f


## Adds up to `amount` (limited by cargo space). Returns the amount actually added.
func add_cargo(item: String, amount: float) -> float:
	var vol := GameData.item_volume(item)
	var fits := free_for(item) / vol
	if item.begins_with("mod:"):
		fits = floorf(fits)
	var added := minf(amount, fits)
	if added <= 0.0:
		return 0.0
	cargo[item] = float(cargo.get(item, 0.0)) + added
	return added


func remove_cargo(item: String, amount: float) -> float:
	var have := float(cargo.get(item, 0.0))
	var removed := minf(have, amount)
	if have - removed <= 0.0001:
		cargo.erase(item)
	else:
		cargo[item] = have - removed
	return removed


# ---------------------------------------------------------------- Display

func describe() -> String:
	var s := stats()
	var h := hull()
	var t := "[b]%s[/b]  –  %s %s (size %s)\n" % [ship_name, h["class"], h["name"], GameData.SIZE_NAMES[int(h["size"])]]
	if not s["missing"].is_empty():
		var names: Array = []
		for k in s["missing"]:
			names.append(GameData.SLOT_NAMES[k])
		t += "[color=#ff6060]Missing core equipment: %s[/color]\n" % ", ".join(PackedStringArray(names))
	var avail: float = s["power_output"] * s["efficiency"]
	var over := ""
	if s["power_ratio"] < 1.0:
		over = "  [color=#ff6060]OVERLOADED – all systems at %d%%[/color]" % int(s["power_ratio"] * 100.0)
	t += "Power: %.0f / %.0f MW%s\n" % [s["power_draw"], avail, over]
	t += "Mass: %.0f t   Signature: %.0f\n" % [s["mass"], s["signature"]]
	t += "Speed: %.0f   Agility: %.1f\n" % [s["speed"], s["turn"]]
	t += "Shield: %.0f (+%.1f/s)   Armor: %.0f   Structure: %.0f\n" % [s["shield_max"], s["shield_regen"], s["armor_max"], s["structure_max"]]
	t += "Armor resistance: opt %d%% / kin %d%% / exp %d%%\n" % [int(s["res"]["optical"] * 100), int(s["res"]["kinetic"] * 100), int(s["res"]["explosive"] * 100)]
	t += "Capacitor: %.0f (+%.1f/s)\n" % [s["cap_max"], s["cap_recharge"]]
	t += "Fuel: %.0f   Hyperdrive: cl. %d, %.0f/jump, %.1f s\n" % [s["fuel_max"], s["drive_class"], s["jump_fuel"], s["spool"]]
	t += "Sensors: %.0f, resolution %.2f, scan strength %.2f\n" % [s["sensor_range"], s["resolution"], s["scan_strength"]]
	t += "Cargo: %.0f / %.0f\n" % [cargo_used(), s["cargo_max"]]
	if float(s["ore_cargo_max"]) > 0.0:
		t += "Ore hold: %.0f / %.0f (ore and ice only)\n" % [ore_hold_used(), s["ore_cargo_max"]]
	var mbs: Array = []
	for cls in s["mining_bonus"]:
		if float(s["mining_bonus"][cls]) > 0.0:
			mbs.append("%s +%d%%" % [String(cls), int(float(s["mining_bonus"][cls]) * 100.0)])
	if not mbs.is_empty():
		t += "Mining upgrades: %s\n" % ", ".join(PackedStringArray(mbs))
	t += "\n[b]Weapons[/b]\n"
	if s["weapons"].is_empty():
		t += "  –\n"
	for w in s["weapons"]:
		var col: Color = GameData.DAMAGE_COLORS[w["damage_type"]]
		t += "  [color=#%s]%s[/color] – %s, %.0f damage, range %.0f, %.1f DPS\n" % [
			col.to_html(false), w["name"], GameData.DAMAGE_NAMES[w["damage_type"]],
			float(w["damage"]), float(w["range"]), float(w["damage"]) / float(w["cooldown"])]
	t += "  DPS: opt %.0f / kin %.0f / exp %.0f  (Σ %.0f)\n" % [s["dps"]["optical"], s["dps"]["kinetic"], s["dps"]["explosive"], s["dps_total"]]
	t += "\n[b]Tools[/b]\n"
	if s["tools"].is_empty():
		t += "  –\n"
	for tool in s["tools"]:
		var extra := ""
		if tool["tool"] == "survey":
			extra = ", range %s" % SystemView.fmt_dist(float(tool["range"]))
		t += "  %s (%s%s)\n" % [tool["name"], GameData.TOOL_NAMES[tool["tool"]], extra]
	if not s["actives"].is_empty():
		t += "\n[b]Active equipment[/b]\n"
		for a in s["actives"]:
			t += "  %s – %.0f energy/s while on\n" % [a["name"], float(a["energy_rate"])]
	return t
