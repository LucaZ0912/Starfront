class_name PilotGear
extends RefCounted
## Package 51: what the pilot wears and carries – the suit (its class sets the slots), the weapons, the belt (stacks
## on the number keys), the features; the pockets (GearData.INV_SLOTS places, stacks); a locker in every ship (by the
## ship's uid, its size by the hull's size); and the suit's present state: health, energy, oxygen, ammunition.
## A place is {} when empty, else {"id", "n"}.

const GearData = preload("res://data/gear.gd")
const LOCKER_BY_SIZE := {1: 12, 2: 20, 3: 30}

var suit := ""
var weapons: Array = []
var belt: Array = []
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


## The slot arrays sized to the suit (what no longer fits is returned).
func _fit_slots() -> Array:
	var s := GearData.stats(suit)
	var spill: Array = []
	var want := {"weapons": int(s.get("weapons", 1)), "belt": int(s.get("belt", 1)), "features": int(s.get("features", 0))}
	for k in want:
		var arr: Array = get(k)
		while arr.size() > int(want[k]):
			var last = arr.pop_back()
			if last is String and String(last) != "":
				spill.append({"id": last, "n": 1})
			elif last is Dictionary and not (last as Dictionary).is_empty():
				spill.append(last)
		while arr.size() < int(want[k]):
			arr.append({} if k == "belt" else "")
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
	var hz := 0.0
	for h in GearData.HAZARDS:
		hz += float(env.get(h, 0.0))
	draw += hz * GearData.LIFE_SUPPORT
	energy = maxf(0.0, energy - draw * mins)
	var powered := energy > 0.0
	var exposure := 0.0
	for h2 in GearData.HAZARDS:
		var sev := float(env.get(h2, 0.0))
		var prot := float(t["env"].get(h2, 0.0)) if powered else 0.0
		exposure += sev * (1.0 - prot)
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


## Walking speed × (the suit, its plates, a stimulant; running with a sprint booster).
func speed_mult(running: bool) -> float:
	var t := totals()
	var m := float(t["speed"])
	if stim_t > 0.0:
		m *= 1.25
	if running and energy > 0.0:
		m *= float(t["sprint"])
	return m


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
			return "%s – throwing comes with the fights on foot." % String(s["name"])
		"tool":
			return "%s – its work comes with the places to explore." % String(s["name"])
	return ""


## At a charging point (or aboard): energy and oxygen full again.
func charge() -> void:
	var t := totals()
	energy = float(t["energy"])
	oxygen = float(t["oxygen"])


## 0.7.51.4: fallen outside and found – what was in the pockets is gone; you come to weak, the suit recharged.
## Returns the names of what was lost.
func fall() -> Array:
	var lost: Array = []
	for i in inv.size():
		var p: Dictionary = inv[i]
		if not p.is_empty():
			lost.append(GearData.display_name(String(p["id"])) + (" ×%d" % int(p["n"]) if int(p["n"]) > 1 else ""))
			inv[i] = {}
	charge()
	health = 60.0
	stim_t = 0.0
	return lost


## Back aboard the ship: charged, and the medbay sees to the body.
func aboard() -> void:
	charge()
	health = GearData.HEALTH
	stim_t = 0.0


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
	for arr in [inv, belt]:
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
			for pair in [["weapons", int(s2["weapons"])], ["belt", int(s2["belt"])], ["features", int(s2["features"])]]:
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
		"weapon", "feature":
			var arr: Array = weapons if GearData.kind(id) == "weapon" else features
			var at := arr.find("")
			if at < 0:
				return "No free %s slot on this suit." % ("weapon" if arr == weapons else "feature")
			arr[at] = id
			_take(i, 1)
			clamp_state()
			return ""
		"belt":
			# onto a belt place with the same item (stacking), else a free one
			var mx := GearData.stack_max(id)
			for b in belt.size():
				var bp: Dictionary = belt[b]
				if not bp.is_empty() and String(bp["id"]) == id and int(bp["n"]) < mx:
					var put := mini(int(p["n"]), mx - int(bp["n"]))
					bp["n"] = int(bp["n"]) + put
					_take(i, put)
					return ""
			for b2 in belt.size():
				if (belt[b2] as Dictionary).is_empty():
					belt[b2] = {"id": id, "n": int(p["n"])}
					inv[i] = {}
					return ""
			return "No free place on the belt."
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

func to_dict() -> Dictionary:
	return {"suit": suit, "weapons": weapons.duplicate(), "belt": belt.duplicate(true), "features": features.duplicate(),
		"inv": inv.duplicate(true), "lockers": lockers.duplicate(true), "health": health, "energy": energy, "oxygen": oxygen, "ammo": ammo,
		"helmet": helmet}


func from_dict(d: Dictionary) -> void:
	if d.is_empty() or not GearData.valid(String(d.get("suit", ""))):
		start()
		return
	suit = String(d["suit"])
	weapons = (d.get("weapons", []) as Array).duplicate()
	belt = (d.get("belt", []) as Array).duplicate(true)
	features = (d.get("features", []) as Array).duplicate()
	inv = (d.get("inv", []) as Array).duplicate(true)
	while inv.size() < GearData.INV_SLOTS:
		inv.append({})
	lockers = (d.get("lockers", {}) as Dictionary).duplicate(true)
	helmet = "always" if String(d.get("helmet", "auto")) == "always" else "auto"
	_fit_slots()
	health = float(d.get("health", GearData.HEALTH))
	energy = float(d.get("energy", 0.0))
	oxygen = float(d.get("oxygen", 0.0))
	ammo = int(d.get("ammo", 0))
	clamp_state()
