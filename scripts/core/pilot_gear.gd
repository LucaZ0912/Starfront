class_name PilotGear
extends RefCounted
## Package 51: what the pilot wears and carries – the suit (its class sets the slots), the weapons, the belt (stacks
## on the number keys), the features; the pockets (GearData.INV_SLOTS places, stacks); a locker in every ship (by the
## ship's uid, its size by the hull's size); and the suit's present state: health, energy, oxygen, ammunition.
## A place is {} when empty, else {"id", "n"}.

const GearData = preload("res://data/gear.gd")
const CrewData = preload("res://data/crew.gd")
const LOCKER_BY_SIZE := {1: 12, 2: 20, 3: 30}

var suit := ""
var weapons: Array = []
var belt: Array = []
var grenades: Array = []                # 0.7.52.9 (Luz): the grenade places, apart from the belt
var gr_sel := 0                         # the grenade in hand (an index into grenades; X switches)
var drones: Array = []                  # 0.7.52.11: the combat suits' drone place (a module id, "" empty)
var features: Array = []
var inv: Array = []
var lockers := {}                      # ship uid (String) -> Array of places
var health := GearData.HEALTH
var energy := 0.0
var oxygen := 0.0
var ammo := 0
var stim_t := 0.0                      # 0.7.51.3: a stimulant working (seconds left)
## 0.7.51.10 (Luz): when the helmet is worn – "auto": only when needed (no air to breathe, or in a fight), "always"
var helmet := "auto"
var combat_t := 0.0                     # 0.7.51.10: seconds the pilot counts as in a fight (set when shooting starts)
var shield := 0.0                       # package 52: the suit's shield and armour as they are now (totals() has the most)
var armor := 0.0
var shield_wait := 0.0                  # seconds before the shield recovers after a hit
var team: Array = []                    # 0.7.52.20 (package 52a): crew ids of the active ship coming along on foot (≤ 2)


## A new pilot: a civilian suit (F), a laser pistol, two medkits and an energy cell on the belt.
func start() -> void:
	suit = "suit_civil:F"
	inv = []
	inv.resize(GearData.INV_SLOTS)
	inv.fill({})
	_fit_slots()
	weapons[0] = "wp_laser_pistol:F"
	belt[0] = {"id": "cs_medkit", "n": 2}
	if belt.size() > 1:
		belt[1] = {"id": "cs_cell", "n": 1}
	lockers = {}
	refill()


## Full again (energy, oxygen, ammunition, health) – after a respawn, at a charging station.
func refill() -> void:
	var t := totals()
	health = GearData.HEALTH
	energy = float(t["energy"])
	oxygen = float(t["oxygen"])
	ammo = int(t["ammo"])
	shield = float(t["shield"])
	armor = float(t["armor"])


## The slot arrays sized to the suit (what no longer fits is returned).
func _fit_slots() -> Array:
	var s := GearData.stats(suit)
	var spill: Array = []
	var want := {"weapons": int(s.get("weapons", 1)), "belt": int(s.get("belt", 1)), "grenades": int(s.get("grenades", 0)), "drones": int(s.get("drones", 0)), "features": int(s.get("features", 0))}
	for k in want:
		var arr: Array = get(k)
		while arr.size() > int(want[k]):
			var last = arr.pop_back()
			if last is String and String(last) != "" and bool(GearData.base(String(last)).get("builtin", false)):
				continue                                      # a built-in weapon goes with its suit
			if last is String and String(last) != "":
				spill.append({"id": last, "n": 1})
			elif last is Dictionary and not (last as Dictionary).is_empty():
				spill.append(last)
		while arr.size() < int(want[k]):
			arr.append({} if k in ["belt", "grenades"] else "")
	# 0.7.52.14: a suit's built-in weapon sits in the first weapon place (what was there goes to the pockets); one from a
	# suit taken off is simply gone with it
	var bi := String(s.get("builtin", ""))
	for wi in weapons.size():
		var w := String(weapons[wi])
		if w != "" and bool(GearData.base(w).get("builtin", false)) and (bi == "" or wi != 0):
			weapons[wi] = ""
	if bi != "" and not weapons.is_empty():
		var bid := "%s:%s" % [bi, GearData.quality(suit)]
		if String(weapons[0]) != "" and String(weapons[0]) != bid:
			spill.append({"id": String(weapons[0]), "n": 1})
		weapons[0] = bid
	return spill


# ---------------------------------------------------------------- what it adds up to

## The pilot's numbers with this suit and its features: shield, armor, energy, oxygen (minutes), ammo, env {hazard:
## 0..1}, speed, sprint, regen, energy_rate (per minute, while outside).
func totals() -> Dictionary:
	var s := GearData.stats(suit)
	var t := {"shield": float(s.get("shield", 0.0)), "armor": float(s.get("armor", 0.0)), "energy": float(s.get("energy", 50.0)),
		"oxygen": float(s.get("oxygen", 10.0)), "ammo": int(s.get("ammo", 0)), "env": (s.get("env", {}) as Dictionary).duplicate(),
		"speed": float(s.get("speed", 1.0)), "sprint": 1.0, "regen": 2.0, "energy_rate": 0.0, "health": GearData.HEALTH}
	for h in GearData.HAZARDS:
		if not t["env"].has(h):
			t["env"][h] = 0.0
	for fid in features:
		if String(fid) == "":
			continue
		var f := GearData.stats(String(fid))
		for k in ["shield", "armor", "energy", "oxygen"]:
			if f.has(k):
				t[k] = float(t[k]) + float(f[k])
		if f.has("ammo"):
			t["ammo"] = int(t["ammo"]) + int(f["ammo"])
		if f.has("regen"):
			t["regen"] = float(t["regen"]) + float(f["regen"])
		if f.has("speed"):
			t["speed"] = float(t["speed"]) * float(f["speed"])
		if f.has("sprint"):
			t["sprint"] = maxf(float(t["sprint"]), float(f["sprint"]))
		if f.has("energy_rate"):
			t["energy_rate"] = float(t["energy_rate"]) + float(f["energy_rate"])
		if f.has("env"):
			for h2 in (f["env"] as Dictionary):
				t["env"][h2] = minf(1.0, float(t["env"][h2]) + float(f["env"][h2]))
	return t


func clamp_state() -> void:
	var t := totals()
	energy = minf(energy, float(t["energy"]))
	oxygen = minf(oxygen, float(t["oxygen"]))
	ammo = mini(ammo, int(t["ammo"]))
	health = minf(health, GearData.HEALTH)
	shield = clampf(shield, 0.0, float(t["shield"]))
	armor = clampf(armor, 0.0, float(t["armor"]))


# ---------------------------------------------------------------- 0.7.51.3: outside

## A step outside: the life support keeps out what it can (on the suit's energy), what gets through hurts; without
## breathable air the tank is used, empty it suffocates; features that work draw energy (the sprint booster only
## while running). Returns {exposure (hazard that gets through), out_of_air, out_of_energy}.
func env_step(delta: float, env: Dictionary, sprinting: bool) -> Dictionary:
	var t := totals()
	var mins := delta / 60.0
	var draw := 0.0
	for fid in features:
		if String(fid) == "":
			continue
		var f := GearData.stats(String(fid))
		if f.has("energy_rate") and (not f.has("sprint") or sprinting):
			draw += float(f["energy_rate"])
	# 0.7.53.14 (Luz): while the suit has energy the life support keeps everything out – what its protection does not
	# cover costs extra energy (LIFE_STRAIN); only with the energy gone does the world outside get through, whole
	for h in GearData.HAZARDS:
		var sv := float(env.get(h, 0.0))
		draw += sv * (GearData.LIFE_SUPPORT + (1.0 - float(t["env"].get(h, 0.0))) * GearData.LIFE_STRAIN)
	energy = maxf(0.0, energy - draw * mins)
	var powered := energy > 0.0
	var exposure := 0.0
	if not powered:
		for h2 in GearData.HAZARDS:
			exposure += float(env.get(h2, 0.0))
	health -= exposure * GearData.EXPOSURE_HURT * delta
	var no_air := false
	if not bool(env.get("breathable", true)):
		oxygen = maxf(0.0, oxygen - mins)
		if oxygen <= 0.0:
			no_air = true
			health -= GearData.SUFFOCATE * delta
	health = maxf(health, 0.0)
	stim_t = maxf(0.0, stim_t - delta)
	combat_t = maxf(0.0, combat_t - delta)
	return {"exposure": exposure, "out_of_air": no_air, "out_of_energy": not powered}


## Package 52: hit on foot – through shield, armour and health (GearData.apply_damage); the shield waits before it
## recovers. Returns what each layer lost.
func take_damage(dmg: float, dtype: String) -> Dictionary:
	var st := {"shield": shield, "armor": armor, "health": health}
	var out := GearData.apply_damage(st, dmg, dtype)
	shield = float(st["shield"])
	armor = float(st["armor"])
	health = maxf(0.0, float(st["health"]))
	shield_wait = GearData.SHIELD_WAIT
	return out


## Package 52: the shield recovers after a while without hits, on the suit's energy (regen points a second).
func shield_step(delta: float) -> void:
	if shield_wait > 0.0:
		shield_wait = maxf(0.0, shield_wait - delta)
		return
	var t := totals()
	var mx := float(t["shield"])
	if shield >= mx or energy <= 0.0:
		return
	var add := minf(float(t["regen"]) * delta, mx - shield)
	shield += add
	energy = maxf(0.0, energy - add * GearData.SHIELD_ENERGY)


## Walking speed × (the suit, its plates, a stimulant; running with a sprint booster).
func speed_mult(running: bool) -> float:
	var t := totals()
	var m := float(t["speed"])
	if stim_t > 0.0:
		m *= 1.25
	if running and energy > 0.0:
		m *= float(t["sprint"])
	return m


## 0.7.52.9: the grenade in hand ({} if there is none) – the chosen place, else the first filled one.
func grenade() -> Dictionary:
	if grenades.is_empty():
		return {}
	gr_sel = posmod(gr_sel, grenades.size())
	if (grenades[gr_sel] as Dictionary).is_empty():
		for i in grenades.size():
			if not (grenades[i] as Dictionary).is_empty():
				gr_sel = i
				break
	return grenades[gr_sel]


## X tapped: the next filled grenade place. Returns its name ("" if there is none).
func next_grenade() -> String:
	for k in range(1, grenades.size() + 1):
		var i := posmod(gr_sel + k, grenades.size())
		if not (grenades[i] as Dictionary).is_empty():
			gr_sel = i
			return String(GearData.base(String(grenades[i]["id"]))["name"])
	return ""


## Uses what is on belt place i: a consumable works (medkit, stimulant, energy cell, oxygen cartridge, ammunition);
## grenades and tools say when they come. Returns what happened (a line for the screen).
func use_belt(i: int) -> String:
	if i < 0 or i >= belt.size() or (belt[i] as Dictionary).is_empty():
		return ""
	var p: Dictionary = belt[i]
	var id := String(p["id"])
	var s := GearData.stats(id)
	var t := totals()
	match String(s.get("kind", "")):
		"use":
			if s.has("heal"):
				if health >= GearData.HEALTH:
					return "You are not hurt."
				health = minf(GearData.HEALTH, health + float(s["heal"]))
			elif s.has("energy"):
				if energy >= float(t["energy"]):
					return "The suit's energy is full."
				energy = minf(float(t["energy"]), energy + float(s["energy"]))
			elif s.has("oxygen"):
				if oxygen >= float(t["oxygen"]):
					return "The tank is full."
				oxygen = minf(float(t["oxygen"]), oxygen + float(s["oxygen"]))
			elif s.has("ammo"):
				if ammo >= int(t["ammo"]):
					return "No room for more rounds."
				ammo = mini(int(t["ammo"]), ammo + int(s["ammo"]))
			elif s.has("time"):
				stim_t = float(s["time"])
			p["n"] = int(p["n"]) - 1
			if int(p["n"]) <= 0:
				belt[i] = {}
			return "%s used." % String(s["name"])
		"grenade":
			return "%s – hold its key to aim, let go to throw (only where you may fight)." % String(s["name"])
		"tool":
			return "%s – its work comes with the places to explore." % String(s["name"])
		"breach":
			return "%s – use a terminal (E) to jack it in and hack." % String(s["name"])
	return ""


## At a supply point (or aboard): energy and oxygen full again – 0.7.52.12 (Luz): and the ammunition.
func charge() -> void:
	var t := totals()
	energy = float(t["energy"])
	oxygen = float(t["oxygen"])
	ammo = maxi(ammo, int(t["ammo"]))


## 0.7.51.4: fallen outside and found – you come to weak, the suit recharged (0.7.53.14: what you carried is not
## simply gone – the buy-back offer, GameState.fall_open, decides it).
func fall() -> void:
	charge()
	health = 60.0
	stim_t = 0.0
	var t := totals()
	shield = float(t["shield"])
	armor = float(t["armor"])


## 0.7.53.14 (Luz): what the pilot wore and carried, priced – the suit; weapons (not a built-in one), drones, features;
## the belt's and the grenade places' stacks; the pockets. The lockers aboard do not count.
## {suit, rest, value, items: [[name, price]]}
func carried_value() -> Dictionary:
	var sv := GearData.price(suit)
	var items: Array = [[GearData.display_name(suit), sv]]
	var ids: Array = []
	for w in weapons + drones + features:
		if String(w) != "" and not bool(GearData.base(String(w)).get("builtin", false)):
			ids.append([String(w), 1])
	for p in belt + grenades + inv:
		if not (p as Dictionary).is_empty():
			ids.append([String(p["id"]), int(p["n"])])
	var rest := 0
	for e in ids:
		var pr := GearData.price(String(e[0])) * int(e[1])
		rest += pr
		items.append([GearData.display_name(String(e[0])) + (" ×%d" % int(e[1]) if int(e[1]) > 1 else ""), pr])
	return {"suit": sv, "rest": rest, "value": sv + rest, "items": items}


## 0.7.53.14: the basic kit after a fall not bought back – a new pilot's gear; the lockers, the team, the helmet stay.
func basic_kit() -> void:
	var keep_l := lockers.duplicate(true)
	var keep_t := team.duplicate()
	var keep_h := helmet
	weapons = []
	belt = []
	grenades = []
	drones = []
	features = []
	gr_sel = 0
	start()
	lockers = keep_l
	team = keep_t
	helmet = keep_h
	fall()


## Back aboard the ship: charged, and the medbay sees to the body.
func aboard() -> void:
	charge()
	health = GearData.HEALTH
	stim_t = 0.0
	var t := totals()
	shield = float(t["shield"])
	armor = float(t["armor"])                       # package 52: the ship's workshop mends the plate


# ---------------------------------------------------------------- pockets

## Puts n of an item into the pockets (stacking first); returns how many did not fit.
func add_item(id: String, n: int = 1) -> int:
	return _add_to(inv, id, n)


func _add_to(arr: Array, id: String, n: int) -> int:
	var mx := GearData.stack_max(id)
	for i in arr.size():
		if n <= 0:
			break
		var p: Dictionary = arr[i]
		if not p.is_empty() and String(p["id"]) == id and int(p["n"]) < mx:
			var put := mini(n, mx - int(p["n"]))
			p["n"] = int(p["n"]) + put
			n -= put
	for i2 in arr.size():
		if n <= 0:
			break
		if (arr[i2] as Dictionary).is_empty():
			var put2 := mini(n, mx)
			arr[i2] = {"id": id, "n": put2}
			n -= put2
	return n


func free_places(arr: Array = inv) -> int:
	var c := 0
	for p in arr:
		if (p as Dictionary).is_empty():
			c += 1
	return c


func count(id: String) -> int:
	var c := 0
	for arr in [inv, belt, grenades]:
		for p in arr:
			if not (p as Dictionary).is_empty() and String(p["id"]) == id:
				c += int(p["n"])
	return c


# ---------------------------------------------------------------- equipping

## Puts the item in pocket i on: a suit is swapped (the old one and whatever no longer fits into the pockets); a
## weapon, belt item or feature into the first free fitting slot. "" or why not.
func equip_from_inv(i: int) -> String:
	if i < 0 or i >= inv.size() or (inv[i] as Dictionary).is_empty():
		return "Nothing there."
	var p: Dictionary = inv[i]
	var id := String(p["id"])
	match GearData.kind(id):
		"suit":
			# first: is there room in the pockets for the old suit and whatever no longer fits?
			var s2 := GearData.stats(id)
			var need := 1
			for pair in [["weapons", int(s2["weapons"])], ["belt", int(s2["belt"])], ["grenades", int(s2.get("grenades", 0))], ["drones", int(s2.get("drones", 0))], ["features", int(s2["features"])]]:
				var arr2: Array = get(String(pair[0]))
				for j in range(int(pair[1]), arr2.size()):
					var it2 = arr2[j]
					if (it2 is String and String(it2) != "") or (it2 is Dictionary and not (it2 as Dictionary).is_empty()):
						need += 1
			if free_places() + 1 < need:                       # (+1: the place the new suit leaves)
				return "Not enough room in your pockets for what comes off."
			var old := suit
			inv[i] = {}
			suit = id
			var spill := _fit_slots()
			spill.append({"id": old, "n": 1})
			for sp2 in spill:
				_add_to(inv, String(sp2["id"]), int(sp2["n"]))
			clamp_state()
			return ""
		"weapon", "feature", "drone":
			if bool(GearData.base(id).get("builtin", false)):
				return "That is built into a suit."
			var arr: Array = weapons if GearData.kind(id) == "weapon" else (drones if GearData.kind(id) == "drone" else features)
			var at := arr.find("")
			if arr.is_empty() and arr == drones:
				return "Only combat suits have a drone place."
			if at < 0:
				return "No free %s slot on this suit." % ("weapon" if arr == weapons else ("drone" if arr == drones else "feature"))
			arr[at] = id
			_take(i, 1)
			clamp_state()
			return ""
		"belt":
			# onto a place with the same item (stacking), else a free one – grenades into the grenade places
			# (0.7.52.9), everything else onto the belt
			var places: Array = grenades if GearData.is_grenade(id) else belt
			var mx := GearData.stack_max(id)
			for b in places.size():
				var bp: Dictionary = places[b]
				if not bp.is_empty() and String(bp["id"]) == id and int(bp["n"]) < mx:
					var put := mini(int(p["n"]), mx - int(bp["n"]))
					bp["n"] = int(bp["n"]) + put
					_take(i, put)
					return ""
			for b2 in places.size():
				if (places[b2] as Dictionary).is_empty():
					places[b2] = {"id": id, "n": int(p["n"])}
					inv[i] = {}
					return ""
			if places.is_empty():
				return "This suit has no grenade places." if places == grenades else "This suit has no belt."
			return "No free grenade place." if places == grenades else "No free place on the belt."
	return "That cannot be worn."


func _take(i: int, n: int) -> void:
	var p: Dictionary = inv[i]
	p["n"] = int(p["n"]) - n
	if int(p["n"]) <= 0:
		inv[i] = {}


## Takes off what is in a slot (kind weapons/belt/features, index) into the pockets. "" or why not.
func unequip(slot_kind: String, idx: int) -> String:
	var arr: Array = get(slot_kind)
	if idx < 0 or idx >= arr.size():
		return "No such slot."
	if arr[idx] is String and String(arr[idx]) != "" and bool(GearData.base(String(arr[idx])).get("builtin", false)):
		return "Built into the suit – it comes off with the suit."
	var it = arr[idx]
	var id := ""
	var n := 1
	if it is Dictionary:
		if (it as Dictionary).is_empty():
			return "Empty."
		id = String(it["id"])
		n = int(it["n"])
	else:
		id = String(it)
		if id == "":
			return "Empty."
	var left := _add_to(inv, id, n)
	if left == n:
		return "Your pockets are full."
	if it is Dictionary:
		if left > 0:
			(it as Dictionary)["n"] = left
		else:
			arr[idx] = {}
	else:
		arr[idx] = ""
	clamp_state()
	return ""


# ---------------------------------------------------------------- the ship's locker

func locker_size(fit) -> int:
	if fit == null:
		return 0
	return int(LOCKER_BY_SIZE.get(int(fit.hull().get("size", 1)), 12))


func locker(fit) -> Array:
	if fit == null:
		return []
	var key := str(fit.uid)
	var cap := locker_size(fit)
	if not lockers.has(key):
		var arr: Array = []
		arr.resize(cap)
		arr.fill({})
		lockers[key] = arr
	var l: Array = lockers[key]
	while l.size() < cap:
		l.append({})
	return l


## Pocket i → the locker (all of it). "" or why not.
func store(i: int, fit) -> String:
	if i < 0 or i >= inv.size() or (inv[i] as Dictionary).is_empty():
		return "Nothing there."
	var p: Dictionary = inv[i]
	var left := _add_to(locker(fit), String(p["id"]), int(p["n"]))
	if left == int(p["n"]):
		return "The locker is full."
	if left > 0:
		p["n"] = left
	else:
		inv[i] = {}
	return ""


## Locker place j → the pockets. "" or why not.
func fetch(j: int, fit) -> String:
	var l := locker(fit)
	if j < 0 or j >= l.size() or (l[j] as Dictionary).is_empty():
		return "Nothing there."
	var p: Dictionary = l[j]
	var left := _add_to(inv, String(p["id"]), int(p["n"]))
	if left == int(p["n"]):
		return "Your pockets are full."
	if left > 0:
		p["n"] = left
	else:
		l[j] = {}
	return ""


# ---------------------------------------------------------------- saving

# ---------------------------------------------------------------- 0.7.52.20 (package 52a): the ground team

## The crew of the active ship that comes along on foot (alive ones, in the order picked).
func team_members() -> Array:
	var out: Array = []
	var f = GameState.active()
	if f == null:
		return out
	for id in team:
		for m in f.crew_members():
			if int(m.get("id", -1)) == int(id) and not bool(m.get("dead", false)):
				out.append(m)
	return out


## Takes a member along, or leaves it aboard. "" or why not.
func team_toggle(m: Dictionary) -> String:
	var id := int(m.get("id", -1))
	if team.has(id):
		team.erase(id)
		return ""
	if bool(m.get("dead", false)):
		return "%s is dead – a clinic can bring them back." % String(m.get("name", "They"))
	team = team.filter(func(t): return _team_aboard(int(t)))
	if team.size() >= CrewData.TEAM_MAX:
		return "At most %d come along." % CrewData.TEAM_MAX
	team.append(id)
	return ""


func _team_aboard(id: int) -> bool:
	var f = GameState.active()
	if f == null:
		return false
	for m in f.crew_members():
		if int(m.get("id", -1)) == id:
			return true
	return false


## A member's own gear: {"suit": id, "weapons": [ids]} (made when first asked for).
static func member_gear(m: Dictionary) -> Dictionary:
	if not m.has("gear") or not (m["gear"] is Dictionary):
		m["gear"] = {"suit": "suit_civil:F", "weapons": [""]}
	var mg: Dictionary = m["gear"]
	var n := int(GearData.stats(String(mg["suit"])).get("weapons", 1))
	var ws: Array = mg["weapons"]
	while ws.size() < n:
		ws.append("")
	# 0.7.52.26 (Luz): their belt – tools they use with you (the short cloak), as many places as the suit's belt
	if not mg.has("belt"):
		mg["belt"] = []
	var bt: Array = mg["belt"]
	var nb := int(GearData.stats(String(mg["suit"])).get("belt", 1))
	while bt.size() < nb:
		bt.append("")
	return mg


## Gives a member what lies in pocket i: a suit (the old one into your pockets, weapons that no longer fit too) or a
## weapon into a free place. "" or why not.
func member_equip(m: Dictionary, i: int) -> String:
	if i < 0 or i >= inv.size() or (inv[i] as Dictionary).is_empty():
		return "Nothing there."
	var id := String(inv[i]["id"])
	var mg := member_gear(m)
	var ws: Array = mg["weapons"]
	match GearData.kind(id):
		"suit":
			var n := int(GearData.stats(id).get("weapons", 1))
			var off: Array = [String(mg["suit"])]
			for j in range(n, ws.size()):
				if String(ws[j]) != "":
					off.append(String(ws[j]))
			if free_places() + 1 < off.filter(func(o): return String(o) != "suit_civil:F").size():
				return "Not enough room in your pockets for what comes off."
			var nb2 := int(GearData.stats(id).get("belt", 1))
			var bt0: Array = mg["belt"]
			for j2 in range(nb2, bt0.size()):
				if String(bt0[j2]) != "":
					off.append(String(bt0[j2]))
			bt0.resize(mini(bt0.size(), nb2))
			_take(i, 1)
			mg["suit"] = id
			member_gear(m)
			ws.resize(mini(ws.size(), n))
			while ws.size() < n:
				ws.append("")
			var b := String(GearData.base(id).get("builtin", ""))
			if b != "":
				ws[0] = b + ":" + GearData.quality(id)          # a suit's own weapon goes with it
			for o in off:
				if String(o) != "suit_civil:F" and not bool(GearData.base(String(o)).get("builtin", false)):   # their own plain suit stays theirs
					_add_to(inv, String(o), 1)
			return ""
		"weapon":
			if bool(GearData.base(id).get("builtin", false)):
				return "That is built into a suit."
			var at := ws.find("")
			if at < 0:
				return "No free weapon place on %s's suit." % String(m.get("name", "their"))
			ws[at] = id
			_take(i, 1)
			return ""
		"belt":
			if String(GearData.base(id).get("kind", "")) != "tool":
				return "They only carry tools on their belt."
			var bt: Array = mg["belt"]
			var at2 := bt.find("")
			if at2 < 0:
				return "No free belt place on %s's suit." % String(m.get("name", "their"))
			bt[at2] = id
			_take(i, 1)
			return ""
	return "Only suits, weapons and tools for the team."


## Takes a member's piece back into your pockets ("suit": they get the plain civilian suit). "" or why not.
func member_unequip(m: Dictionary, where: String, idx: int) -> String:
	var mg := member_gear(m)
	if free_places() < 1:
		return "No room in your pockets."
	if where == "suit":
		if GearData.family(String(mg["suit"])) == "suit_civil" and GearData.quality(String(mg["suit"])) == "F":
			return "That is their own plain suit."
		var ws: Array = mg["weapons"]
		for j in ws.size():
			if bool(GearData.base(String(ws[j])).get("builtin", false)):
				ws[j] = ""
		_add_to(inv, String(mg["suit"]), 1)
		mg["suit"] = "suit_civil:F"
		member_gear(m)
		ws.resize(int(GearData.stats("suit_civil:F").get("weapons", 1)))
		return ""
	if where == "belt":
		var bt3: Array = mg["belt"]
		if idx < 0 or idx >= bt3.size() or String(bt3[idx]) == "":
			return "Nothing there."
		_add_to(inv, String(bt3[idx]), 1)
		bt3[idx] = ""
		return ""
	var ws2: Array = mg["weapons"]
	if idx < 0 or idx >= ws2.size() or String(ws2[idx]) == "":
		return "Nothing there."
	if bool(GearData.base(String(ws2[idx])).get("builtin", false)):
		return "That is built into the suit."
	_add_to(inv, String(ws2[idx]), 1)
	ws2[idx] = ""
	return ""


func to_dict() -> Dictionary:
	return {"suit": suit, "weapons": weapons.duplicate(), "belt": belt.duplicate(true), "grenades": grenades.duplicate(true), "gr_sel": gr_sel, "drones": drones.duplicate(), "features": features.duplicate(),
		"inv": inv.duplicate(true), "lockers": lockers.duplicate(true), "health": health, "energy": energy, "oxygen": oxygen, "ammo": ammo,
		"helmet": helmet, "shield": shield, "armor": armor, "team": team.duplicate()}


func from_dict(d: Dictionary) -> void:
	if d.is_empty() or not GearData.valid(String(d.get("suit", ""))):
		start()
		return
	suit = String(d["suit"])
	weapons = (d.get("weapons", []) as Array).duplicate()
	belt = (d.get("belt", []) as Array).duplicate(true)
	grenades = (d.get("grenades", []) as Array).duplicate(true)
	gr_sel = int(d.get("gr_sel", 0))
	drones = (d.get("drones", []) as Array).duplicate()
	features = (d.get("features", []) as Array).duplicate()
	inv = (d.get("inv", []) as Array).duplicate(true)
	while inv.size() < GearData.INV_SLOTS:
		inv.append({})
	lockers = (d.get("lockers", {}) as Dictionary).duplicate(true)
	team = (d.get("team", []) as Array).duplicate()
	helmet = "always" if String(d.get("helmet", "auto")) == "always" else "auto"
	_fit_slots()
	health = float(d.get("health", GearData.HEALTH))
	energy = float(d.get("energy", 0.0))
	oxygen = float(d.get("oxygen", 0.0))
	ammo = int(d.get("ammo", 0))
	var t := totals()
	shield = float(d.get("shield", t["shield"]))
	armor = float(d.get("armor", t["armor"]))
	clamp_state()
