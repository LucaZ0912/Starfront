extends RefCounted
## Package 31: crew members – making them, what they give a ship, what they cost, how they learn.
## (No class_name: preload it.) Data: data/crew.gd.
##
## A member is plain data (saved with the ship or in a station's crew quarters):
##   {"id", "name", "look", "role", "quality", "bonus", "value", "perk", "role2", "bonus2", "value2", "xp"}
## value = the bonus in per cent.

const CrewData = preload("res://data/crew.gd")
const PilotArt = preload("res://scripts/core/pilot_art.gd")


static func _pick_bonus(rng: RandomNumberGenerator, role: String) -> String:
	var bs: Array = CrewData.ROLES[role]["bonuses"]
	return String(bs[rng.randi() % bs.size()][0])


static func _roll(rng: RandomNumberGenerator, q: String) -> float:
	var fr: Array = CrewData.FRAME[q]
	return snappedf(rng.randf_range(float(fr[0]), float(fr[1])), 0.1)


static func _pick_perk(rng: RandomNumberGenerator) -> String:
	if rng.randf() >= CrewData.PERK_CHANCE:
		return ""
	var total := 0.0
	for p in CrewData.PERKS:
		total += float(CrewData.PERKS[p]["weight"])
	var x := rng.randf() * total
	for p in CrewData.PERKS:
		x -= float(CrewData.PERKS[p]["weight"])
		if x <= 0.0:
			return p
	return ""


## A new member. perk: "?" = rolled (very rare), "" = none, or a perk id.
static func make(rng: RandomNumberGenerator, id: int, role: String, quality: String, perk: String = "?") -> Dictionary:
	var m := {
		"id": id, "role": role, "quality": quality, "xp": 0.0,
		"name": "%s %s" % [CrewData.FIRST_NAMES[rng.randi() % CrewData.FIRST_NAMES.size()], CrewData.LAST_NAMES[rng.randi() % CrewData.LAST_NAMES.size()]],
		"look": PilotArt.random_look(rng),
		"bonus": _pick_bonus(rng, role), "value": _roll(rng, quality),
		"perk": _pick_perk(rng) if perk == "?" else perk, "role2": "", "bonus2": "", "value2": 0.0,
	}
	if m["perk"] == "second_profession":
		var others: Array = CrewData.ROLES.keys().filter(func(r): return r != role)
		m["role2"] = others[rng.randi() % others.size()]
		m["bonus2"] = _pick_bonus(rng, String(m["role2"]))
		m["value2"] = _roll(rng, quality)
	return m


## May this member serve in a slot of this role?
static func fits(m: Dictionary, role: String) -> bool:
	return String(m.get("role", "")) == role or String(m.get("role2", "")) == role


## [bonus id, value in per cent] the member gives in a slot of this role ([] = none). security: of the system.
static func effect(m: Dictionary, role: String, security: float = 1.0) -> Array:
	var b := ""
	var v := 0.0
	if String(m.get("role", "")) == role:
		b = String(m["bonus"])
		v = float(m["value"])
	elif String(m.get("role2", "")) == role:
		b = String(m["bonus2"])
		v = float(m["value2"])
	else:
		return []
	match String(m.get("perk", "")):
		"old_hand":
			v *= 1.5
		"night_owl":
			if security < 0.5:
				v *= 2.0
	return [b, v]


## The share of income one member takes (fraction).
static func share_of(m: Dictionary) -> float:
	if String(m.get("perk", "")) == "loyal":
		return 0.0
	return float(CrewData.SHARE.get(String(m.get("quality", "F")), 0.0))


static func next_quality(q: String) -> String:
	var i := CrewData.QUALITIES.find(q)
	return "" if i < 0 or i >= CrewData.QUALITIES.size() - 1 else String(CrewData.QUALITIES[i + 1])


## Experience for the member; returns the new quality after a step up ("" = none).
static func learn(m: Dictionary, xp: float, rng: RandomNumberGenerator) -> String:
	var q := String(m["quality"])
	var nq := next_quality(q)
	if nq == "":
		return ""
	if String(m.get("perk", "")) == "quick_learner":
		xp *= 2.0
	m["xp"] = float(m.get("xp", 0.0)) + xp
	if float(m["xp"]) < float(CrewData.XP_NEED[q]):
		return ""
	m["xp"] = float(m["xp"]) - float(CrewData.XP_NEED[q])
	m["quality"] = nq
	var st: Array = CrewData.STEP_UP[nq]
	m["value"] = snappedf(float(m["value"]) + rng.randf_range(float(st[0]), float(st[1])), 0.1)
	if String(m.get("role2", "")) != "":
		m["value2"] = snappedf(float(m["value2"]) + rng.randf_range(float(st[0]), float(st[1])), 0.1)
	return nq


static func price(m: Dictionary, rng: RandomNumberGenerator) -> int:
	var p := float(CrewData.PRICE[String(m["quality"])]) * rng.randf_range(0.7, 1.3)
	if String(m.get("perk", "")) != "":
		p *= 1.6
	return int(round(p / 100.0)) * 100


static func line(m: Dictionary) -> String:
	var s := "%s +%.1f %%" % [CrewData.bonus_label(String(m["role"]), String(m["bonus"])), float(m["value"])]
	if String(m.get("role2", "")) != "":
		s += "  •  as %s: %s +%.1f %%" % [CrewData.role_name(String(m["role2"])), CrewData.bonus_label(String(m["role2"]), String(m["bonus2"])), float(m["value2"])]
	return s
