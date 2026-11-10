extends RefCounted
## Package 51 (Luz, 10 Nov 2026): the pilot's personal equipment. The SUIT is the pilot's "hull": its class fixes how
## many weapon slots, belt places and feature slots there are and how well it keeps out the world (heat, cold, toxic
## air, vacuum); its quality F–A gives a better base shield, more ammunition, more armour and better life support.
## Every suit has an ENERGY store (shields, tools and the life support draw on it) and an OXYGEN tank (used where the
## air cannot be breathed). Weapons and tools come in qualities F–A too (no sizes for now); weapons have the damage
## types of the ship fights – optical (lasers: strong on shields, weak on armour, draw suit energy), kinetic (strong on
## armour, weak on shields, use ammunition), explosive (strong on the body, with splash). The belt holds grenades,
## tools and consumables (on the number keys); features are the suit's modules.
##
## Item id: "<family>:<quality>" (e.g. "suit_mil_light:C", "wp_laser_rifle:B"); consumables and grenades have no
## quality: "<family>" alone.

const QUALITIES := ["F", "E", "D", "C", "B", "A"]
## How quality scales a piece's numbers (and its price)
const Q := {
	"F": {"perf": 0.7, "price": 0.5}, "E": {"perf": 0.8, "price": 0.68}, "D": {"perf": 0.9, "price": 0.84},
	"C": {"perf": 1.0, "price": 1.0}, "B": {"perf": 1.15, "price": 1.45}, "A": {"perf": 1.3, "price": 2.1},
}
const KINDS := {"suit": "Suit", "weapon": "Weapon", "belt": "Belt", "feature": "Feature"}
const HAZARDS := ["heat", "cold", "toxic", "vacuum"]
const HAZARD_NAMES := {"heat": "Heat", "cold": "Cold", "toxic": "Toxic air", "vacuum": "Vacuum"}
const DAMAGE_NAMES := {"optical": "Optical", "kinetic": "Kinetic", "explosive": "Explosive"}
## How each damage type fares against the pilot's layers (as the ship's GameData.LAYER_MULT)
const LAYER_MULT := {
	"shield": {"optical": 1.3, "kinetic": 0.7, "explosive": 0.9},
	"armor": {"optical": 0.8, "kinetic": 1.25, "explosive": 1.0},
	"health": {"optical": 0.9, "kinetic": 1.0, "explosive": 1.4},
}
const HEALTH := 100.0                 # the pilot's own body

## Package 52: fights on foot.
const COVER_CUT := 0.6                 # low cover takes this share off the hit chance of shots at you
const COVER_NEAR := 26.0               # low cover counts when it is this close to you (art px), between you and the shot
const SHIELD_WAIT := 4.0               # seconds without a hit before a shield recovers
const SHIELD_ENERGY := 0.25            # suit energy per point of shield recovered
const DODGE_TIME := 0.3                # a dodge: seconds of the jump (no shot hits meanwhile)
const DODGE_SPEED := 2.6               # × walking speed while dodging (~3 m)
const DODGE_RECHARGE := 4.5            # seconds a dodge charge takes to come back (Athletics shortens it)
const LOCK_TIME := 0.6                 # seconds to lock a target (Firearms shortens it)
const SHOT_SPEED := 720.0              # slugs and shells, art px a second (lasers are at once)

## The suit classes. weapons / belt / features: slot counts; shield, armor, energy, oxygen (minutes of breathing),
## ammo: base values at quality C; env: protection 0..1 against each hazard; speed: walking speed ×.
const SUITS := {
	"suit_civil": {"name": "Civilian Spacesuit", "maker": "Earthworks", "weapons": 1, "belt": 2, "features": 1,
		"shield": 20.0, "armor": 20.0, "energy": 100.0, "oxygen": 30.0, "ammo": 60,
		"env": {"heat": 0.6, "cold": 0.6, "toxic": 1.0, "vacuum": 1.0}, "speed": 1.0, "price": 1200,
		"col": Color(0.92, 0.9, 0.85), "trim": Color(1.0, 0.55, 0.15),
		"desc": "The suit everyone who flies owns: sealed against vacuum and bad air, a little shield, one holster."},
	"suit_survey": {"name": "Survey Suit", "maker": "Axiom Astronautics", "weapons": 1, "belt": 3, "features": 2,
		"shield": 28.0, "armor": 18.0, "energy": 150.0, "oxygen": 55.0, "ammo": 60,
		"env": {"heat": 0.9, "cold": 0.9, "toxic": 1.0, "vacuum": 1.0}, "speed": 1.02, "price": 4200,
		"col": Color(0.85, 0.9, 0.95), "trim": Color(0.35, 0.85, 1.0),
		"desc": "For long walks on hostile worlds: the best life support, room for scanner and tools."},
	"suit_work": {"name": "Work Suit", "maker": "Kanayama Heavy Industries", "weapons": 1, "belt": 4, "features": 1,
		"shield": 18.0, "armor": 45.0, "energy": 120.0, "oxygen": 40.0, "ammo": 80,
		"env": {"heat": 0.8, "cold": 0.8, "toxic": 1.0, "vacuum": 1.0}, "speed": 0.95, "price": 3100,
		"col": Color(0.95, 0.75, 0.2), "trim": Color(0.2, 0.2, 0.22),
		"desc": "Mines, docks, wrecks: plated, heavy, four places on its belt for the tools of the trade."},
	"suit_mil_light": {"name": "Light Combat Suit", "maker": "Hadrian Dynamics", "weapons": 2, "belt": 3, "features": 2,
		"shield": 50.0, "armor": 45.0, "energy": 120.0, "oxygen": 25.0, "ammo": 160,
		"env": {"heat": 0.6, "cold": 0.6, "toxic": 1.0, "vacuum": 1.0}, "speed": 1.05, "price": 9500,
		"col": Color(0.86, 0.88, 0.9), "trim": Color(0.35, 0.75, 1.0),
		"desc": "Marine issue: quick on its feet, a strong shield, two weapons at hand."},
	"suit_mil_heavy": {"name": "Heavy Combat Suit", "maker": "Hadrian Dynamics", "weapons": 3, "belt": 2, "features": 3,
		"shield": 70.0, "armor": 110.0, "energy": 170.0, "oxygen": 20.0, "ammo": 260,
		"env": {"heat": 0.45, "cold": 0.45, "toxic": 1.0, "vacuum": 0.85}, "speed": 0.82, "price": 23000,
		"col": Color(0.3, 0.32, 0.36), "trim": Color(1.0, 0.25, 0.2),
		"desc": "A walking bunker: three weapons, heavy plate, a deep magazine – and slow, and short of air."},
}

## Weapons (no sizes for now): dtype, damage per shot, rof (shots/s), range (art px), spread (rad), pellets,
## energy (per shot, optical) or ammo (per shot, kinetic and explosive), splash (radius).
const WEAPONS := {
	"wp_laser_pistol": {"name": "Laser Pistol", "maker": "Axiom Astronautics", "dtype": "optical", "damage": 8.0, "rof": 3.0,
		"range": 260.0, "spread": 0.03, "energy": 1.4, "price": 900, "desc": "Quick, accurate, no magazine – it drinks the suit's energy."},
	"wp_laser_rifle": {"name": "Laser Rifle", "maker": "Axiom Astronautics", "dtype": "optical", "damage": 14.0, "rof": 2.5,
		"range": 430.0, "spread": 0.02, "energy": 2.4, "price": 3200, "desc": "Long reach and steady – burns through shields."},
	"wp_beam": {"name": "Cutting Beam", "maker": "Concord Fleetworks", "dtype": "optical", "damage": 4.0, "rof": 10.0,
		"range": 200.0, "spread": 0.0, "energy": 0.6, "price": 4400, "desc": "A continuous beam at short range; melts shields, hungry for energy."},
	"wp_pistol": {"name": "Slug Pistol", "maker": "Hadrian Dynamics", "dtype": "kinetic", "damage": 11.0, "rof": 2.0,
		"range": 240.0, "spread": 0.05, "ammo": 1, "price": 700, "desc": "The sidearm of the frontier – hits hard on armour."},
	"wp_smg": {"name": "Burst Gun", "maker": "Hadrian Dynamics", "dtype": "kinetic", "damage": 6.0, "rof": 8.0,
		"range": 200.0, "spread": 0.12, "ammo": 1, "price": 2100, "desc": "A hail of slugs at close range; empties a magazine fast."},
	"wp_rifle": {"name": "Rail Carbine", "maker": "Hadrian Dynamics", "dtype": "kinetic", "damage": 17.0, "rof": 2.8,
		"range": 460.0, "spread": 0.03, "ammo": 1, "price": 3600, "desc": "The marine's rifle: punches through plate."},
	"wp_shotgun": {"name": "Scatter Gun", "maker": "Forge of Return", "dtype": "kinetic", "damage": 7.0, "pellets": 6, "rof": 1.0,
		"range": 160.0, "spread": 0.3, "ammo": 1, "price": 2600, "desc": "Six slugs at once – devastating close up, useless far off."},
	"wp_sniper": {"name": "Long Rail", "maker": "Forge of Return", "dtype": "kinetic", "damage": 60.0, "rof": 0.5,
		"range": 820.0, "spread": 0.005, "ammo": 2, "price": 7800, "desc": "One shot, far away, through anything with plate."},
	"wp_launcher": {"name": "Grenade Launcher", "maker": "Hadrian Dynamics", "dtype": "explosive", "damage": 45.0, "rof": 0.6,
		"range": 380.0, "spread": 0.06, "ammo": 4, "splash": 60.0, "price": 6400, "desc": "Lobbed shells that burst – best against what has no shield or plate left."},
}

## Belt items. kind: grenade (thrown, stack), tool (quality, uses energy), use (consumable, stack). Stacks up to `stack`.
const BELT := {
	"gr_frag": {"name": "Frag Grenade", "kind": "grenade", "dtype": "explosive", "damage": 60.0, "radius": 70.0, "stack": 4, "price": 180,
		"desc": "Splinters all round – hurts what has no shield left."},
	"gr_emp": {"name": "EMP Grenade", "kind": "grenade", "dtype": "optical", "damage": 0.0, "shield_damage": 90.0, "radius": 80.0, "stack": 4, "price": 260,
		"desc": "Knocks shields down in a wide burst; harmless to the body."},
	"gr_smoke": {"name": "Smoke Grenade", "kind": "grenade", "radius": 90.0, "time": 8.0, "stack": 4, "price": 90,
		"desc": "A cloud nobody aims through."},
	"gr_shield": {"name": "Shield Grenade", "kind": "grenade", "radius": 70.0, "time": 10.0, "shield": 120.0, "stack": 3, "price": 420,
		"desc": "Throws up a dome of shield: fire and grenades from outside bounce off it, your own fire goes out through it."},
	"tl_scanner": {"name": "Scanner", "kind": "tool", "maker": "Axiom Astronautics", "strength": 1.0, "range": 300.0, "energy": 3.0, "price": 1400,
		"desc": "Reads a place: who and what is here, what lies under the ground."},
	"tl_cutter": {"name": "Cutting Torch", "kind": "tool", "maker": "Kanayama Heavy Industries", "strength": 1.0, "range": 40.0, "energy": 5.0, "price": 1600,
		"desc": "Opens hatches and cuts salvage out of wrecks."},
	"tl_mining": {"name": "Mining Laser", "kind": "tool", "maker": "Kanayama Heavy Industries", "strength": 1.0, "range": 60.0, "energy": 6.0, "price": 1900,
		"desc": "Cuts ore and crystals out of the rock by hand."},
	"cs_medkit": {"name": "Medkit", "kind": "use", "heal": 50.0, "stack": 4, "price": 150, "desc": "Patches the body up: +50 health."},
	"cs_stim": {"name": "Stimulant", "kind": "use", "time": 20.0, "speed": 1.25, "stack": 4, "price": 220, "desc": "20 seconds quicker on your feet and harder to hit."},
	"cs_cell": {"name": "Energy Cell", "kind": "use", "energy": 60.0, "stack": 6, "price": 90, "desc": "Recharges the suit: +60 energy."},
	"cs_o2": {"name": "Oxygen Cartridge", "kind": "use", "oxygen": 15.0, "stack": 6, "price": 60, "desc": "Refills the tank: +15 minutes of air."},
	"cs_ammo": {"name": "Ammunition Box", "kind": "use", "ammo": 60, "stack": 6, "price": 80, "desc": "Slugs and shells: +60 rounds."},
}

## Features – the suit's modules (quality F–A). energy_rate: energy per minute while it works.
const FEATURES := {
	"ft_shield": {"name": "Shield Generator", "maker": "Concord Fleetworks", "shield": 40.0, "regen": 4.0, "energy_rate": 2.0, "price": 2800,
		"desc": "A stronger shield that recovers faster – for a steady draw on the suit's energy."},
	"ft_plates": {"name": "Armour Plates", "maker": "Hadrian Dynamics", "armor": 35.0, "speed": 0.95, "price": 1900,
		"desc": "More plate over chest and legs; a little slower."},
	"ft_sprint": {"name": "Sprint Booster", "maker": "Maison Aurelle", "sprint": 1.3, "energy_rate": 6.0, "price": 2300,
		"desc": "Servos in the legs: a third faster while running, on the suit's energy."},
	"ft_jets": {"name": "Jump Jets", "maker": "Axiom Astronautics", "dash": 1.6, "dash_energy": 8.0, "price": 3600,
		"desc": "A burst of thrust: every dodge takes you further (×1.6), for a little of the suit's energy."},
	"ft_thermo": {"name": "Temperature Regulator", "maker": "Earthworks", "env": {"heat": 0.3, "cold": 0.3}, "price": 1700,
		"desc": "Keeps heat and cold out – the life support needs less."},
	"ft_o2": {"name": "Oxygen Reserve", "maker": "Earthworks", "oxygen": 30.0, "price": 1200, "desc": "A second tank: +30 minutes of air."},
	"ft_ammo": {"name": "Ammunition Pack", "maker": "Hadrian Dynamics", "ammo": 120, "price": 1100, "desc": "More rounds and shells carried."},
	"ft_battery": {"name": "Battery Pack", "maker": "Concord Fleetworks", "energy": 80.0, "price": 1500, "desc": "More energy stored in the suit."},
}

const INV_SLOTS := 12                 # the pilot's own pockets and pack

## 0.7.51.3: what each kind of world does to someone outside – breathable air (else the tank is used), and the
## hazards 0..1 (heat, cold, toxic air, vacuum). Gas giants only have their cloud cities (package 54).
const ENV := {
	"terran": {"breathable": true}, "ocean": {"breathable": true}, "jungle": {"breathable": true, "heat": 0.2},
	"desert": {"breathable": true, "heat": 0.55},
	"ice": {"breathable": false, "cold": 0.8},
	"lava": {"breathable": false, "heat": 1.0, "toxic": 0.7},
	"metal": {"breathable": false, "heat": 0.3, "toxic": 0.5},
	"barren": {"breathable": false, "vacuum": 1.0, "cold": 0.4}, "dwarf": {"breathable": false, "vacuum": 1.0, "cold": 0.7},
	"moon_rock": {"breathable": false, "vacuum": 1.0, "cold": 0.4}, "moon_captured": {"breathable": false, "vacuum": 1.0, "cold": 0.5},
	"moon_ice": {"breathable": false, "vacuum": 1.0, "cold": 1.0},
	"moon_volcanic": {"breathable": false, "vacuum": 0.8, "heat": 0.6, "toxic": 0.6},
}
const LIFE_SUPPORT := 6.0             # energy a minute the life support needs per full hazard it keeps out
const EXPOSURE_HURT := 1.2            # health a second per full hazard that gets through
const SUFFOCATE := 3.0                # health a second without air


## The world outside for a body: {breathable, heat, cold, toxic, vacuum}.
static func env_of(body_type: String) -> Dictionary:
	var e: Dictionary = (ENV.get(body_type, {"breathable": false, "vacuum": 1.0, "cold": 0.4}) as Dictionary).duplicate()
	for h in HAZARDS:
		if not e.has(h):
			e[h] = 0.0
	return e


## Is a helmet needed out there (the air not to be breathed, or poisoned)?
static func needs_helmet(env: Dictionary) -> bool:
	return not bool(env.get("breathable", true)) or float(env.get("toxic", 0.0)) > 0.0 or float(env.get("vacuum", 0.0)) > 0.0


static func family(id: String) -> String:
	return id.split(":")[0]


static func quality(id: String) -> String:
	var p := id.split(":")
	return p[1] if p.size() > 1 else ""


static func kind(id: String) -> String:
	var f := family(id)
	if SUITS.has(f):
		return "suit"
	if WEAPONS.has(f):
		return "weapon"
	if BELT.has(f):
		return "belt"
	if FEATURES.has(f):
		return "feature"
	return ""


static func base(id: String) -> Dictionary:
	var f := family(id)
	for t in [SUITS, WEAPONS, BELT, FEATURES]:
		if (t as Dictionary).has(f):
			return t[f]
	return {}


static func has_quality(id: String) -> bool:
	var k := kind(id)
	return k in ["suit", "weapon", "feature"] or (k == "belt" and String(BELT[family(id)]["kind"]) == "tool")


static func valid(id: String) -> bool:
	if kind(id) == "":
		return false
	return (quality(id) in QUALITIES) if has_quality(id) else quality(id) == ""


static func stack_max(id: String) -> int:
	return int(base(id).get("stack", 1))


## A piece's numbers at its quality (quality scales the performance fields, not costs like energy per shot).
static func stats(id: String) -> Dictionary:
	var b := base(id).duplicate(true)
	if b.is_empty():
		return {}
	var q := quality(id)
	var perf: float = float(Q.get(q, Q["C"])["perf"]) if q != "" else 1.0
	for k in ["shield", "armor", "energy", "oxygen", "damage", "shield_damage", "strength", "regen", "heal", "dash"]:
		if b.has(k) and not (kind(id) == "weapon" and k == "energy") and not (kind(id) == "belt" and k == "energy" and String(b["kind"]) == "tool"):
			b[k] = float(b[k]) * perf
	if b.has("ammo") and kind(id) in ["suit", "feature"]:
		b["ammo"] = int(round(float(b["ammo"]) * perf))
	if b.has("env") and kind(id) == "suit":
		var env: Dictionary = b["env"]
		for h in env.keys():
			env[h] = clampf(float(env[h]) * (0.85 + 0.15 * perf), 0.0, 1.0)     # quality seals it a little better
	if q != "":
		b["price"] = int(round(float(b["price"]) * float(Q[q]["price"])))
	return b


static func price(id: String) -> int:
	return int(stats(id).get("price", 0))


static func display_name(id: String) -> String:
	var b := base(id)
	if b.is_empty():
		return id
	var q := quality(id)
	return String(b["name"]) + (" · " + q if q != "" else "")


## The lines describing a piece (for tooltips and the detail).
static func describe(id: String) -> Array:
	var s := stats(id)
	var lines: Array = [display_name(id), String(s.get("desc", ""))]
	match kind(id):
		"suit":
			lines.append("%d weapon · %d belt · %d feature slots" % [int(s["weapons"]), int(s["belt"]), int(s["features"])])
			lines.append("Shield %d · Armour %d · Energy %d · Oxygen %d min · Ammunition %d" % [int(s["shield"]), int(s["armor"]), int(s["energy"]), int(s["oxygen"]), int(s["ammo"])])
			var env: Array = []
			for h in HAZARDS:
				env.append("%s %d%%" % [HAZARD_NAMES[h], int(float(s["env"][h]) * 100.0)])
			lines.append("Protection: " + ", ".join(env))
			if float(s["speed"]) != 1.0:
				lines.append("Walking speed ×%.2f" % float(s["speed"]))
		"weapon":
			var dt := String(s["dtype"])
			var per := "%d dmg" % int(s["damage"]) + (" ×%d" % int(s["pellets"]) if s.has("pellets") else "")
			lines.append("%s · %s · %.1f shots/s · range %d" % [DAMAGE_NAMES[dt], per, float(s["rof"]), int(s["range"])])
			lines.append(("Energy %.1f a shot" % float(s["energy"])) if s.has("energy") else ("Ammunition %d a shot" % int(s.get("ammo", 1))))
			lines.append({"optical": "Strong against shields, weak against armour", "kinetic": "Strong against armour, weak against shields",
				"explosive": "Strong against the body, bursts" + (" (radius %d)" % int(s["splash"]) if s.has("splash") else "")}[dt])
		"belt":
			match String(s["kind"]):
				"grenade":
					lines.append("Grenade · radius %d · up to %d in a belt place" % [int(s["radius"]), int(s["stack"])])
				"tool":
					lines.append("Tool · strength %.2f · range %d · %.0f energy a use" % [float(s["strength"]), int(s["range"]), float(s["energy"])])
				"use":
					lines.append("Consumable · up to %d in a belt place" % int(s["stack"]))
		"feature":
			var parts: Array = []
			for k in ["shield", "armor", "energy", "oxygen", "ammo"]:
				if s.has(k):
					parts.append("+%d %s" % [int(s[k]), {"shield": "shield", "armor": "armour", "energy": "energy", "oxygen": "min oxygen", "ammo": "ammunition"}[k]])
			if s.has("energy_rate"):
				parts.append("%.0f energy/min while on" % float(s["energy_rate"]))
			if not parts.is_empty():
				lines.append(" · ".join(parts))
	lines.append("%s · %d cr" % [String(s.get("maker", "")), int(s["price"])] if s.has("maker") else "%d cr" % int(s["price"]))
	return lines


## Every piece the Gear shop can sell, in every quality.
static func all_ids() -> Array:
	var out: Array = []
	for t in [SUITS, WEAPONS, FEATURES]:
		for f in t:
			for q in QUALITIES:
				out.append("%s:%s" % [f, q])
	for f2 in BELT:
		if String(BELT[f2]["kind"]) == "tool":
			for q2 in QUALITIES:
				out.append("%s:%s" % [f2, q2])
		else:
			out.append(f2)
	return out


# ---------------------------------------------------------------- package 52: fights on foot

## Damage through the layers shield → armour → health, each layer weighing the damage type as LAYER_MULT says (as the
## ships do): what is left over passes on to the next layer at its own rate. `st` has shield, armor, health and is
## changed. Returns what each layer lost: {shield, armor, health}.
static func apply_damage(st: Dictionary, dmg: float, dtype: String) -> Dictionary:
	var out := {"shield": 0.0, "armor": 0.0, "health": 0.0}
	var left := dmg
	for layer in ["shield", "armor", "health"]:
		if left <= 0.0001:
			break
		var m := float(LAYER_MULT[layer].get(dtype, 1.0))
		var have := float(st.get(layer, 0.0))
		var take := minf(left * m, have)
		st[layer] = have - take
		out[layer] = take
		left -= take / m
	return out


## The chance one shot of weapon `w` (stats) hits: steadier weapons and Firearms aim better; past the optimal range
## (45 % of the reach) it falls off to half at the end; a target that moves (Athletics makes it harder still), is on a
## stimulant or sits in low cover is harder to hit. 0 beyond the reach.
static func hit_chance(w: Dictionary, firearms: int, dist: float, cover: bool, moving: bool, t_athletics: int, stim: bool) -> float:
	var reach := float(w.get("range", 200.0))
	if dist > reach:
		return 0.0
	var c := 0.78 - float(w.get("spread", 0.05)) * 0.8 + 0.015 * firearms
	var opt := reach * 0.45
	if dist > opt:
		c *= lerpf(1.0, 0.55, (dist - opt) / maxf(reach - opt, 1.0))
	if moving:
		c *= 0.85 - 0.01 * t_athletics
	if stim:
		c *= 0.9
	if cover:
		c *= 1.0 - COVER_CUT
	return clampf(c, 0.03, 0.95)
