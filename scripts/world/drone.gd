extends Ship
## Phase 0.5 package 23: a drone of the pilot's ship.
## Small, weak, one fuel load for its whole life (it cannot be refuelled; none is used in the
## hangar). It acts on its own within its control range around the carrier, comes back when it
## strays further, and returns to the hangar when recalled, before a warp or a gate jump and when
## the carrier docks. Its role (combat / mining / repair) and behaviour are set in the drone window
## for all drones at once; weapon and mining laser come from the hangar's equipment slots.

const BURN := {"idle": 0.8, "work": 1.0, "combat": 1.2}   # fuel use per second (× 1 s of the fuel load)
const DELIVER_RANGE := 60.0

var carrier: Ship = null
var rec: Dictionary = {}          # the record in the carrier's fit.drones
var dstats: Dictionary = {}       # carrier's stats()["drone"]
var weapon: Dictionary = {}
var dtool: Dictionary = {}
var dcargo := {}                  # ore carried (max dstats.cargo m³)
var work = null                   # current target (ship / asteroid)
var recalled := false
var _wcd := 0.0
var _burn := "idle"
var _think := 0.0
var _idle := false                # flying in formation this frame


func setup_drone(p_carrier: Ship, p_rec: Dictionary, p_view: Node, uid: int, n: int) -> void:
	carrier = p_carrier
	rec = p_rec
	var cs: Dictionary = carrier.fit.stats()
	dstats = cs["drone"]
	weapon = cs["drone_weapon"]
	dtool = cs["drone_tool"]
	var f := ShipFitting.new("drone", "player")
	f.uid = uid
	f.ship_name = "Drone %d" % n
	f.system_id = carrier.fit.system_id
	f.position = carrier.position
	f.rotation = carrier.heading
	f.capacitor = 0.0
	f.structure = float(dstats["hull"]) * float(rec.get("hp", 1.0))
	f.armor = 0.0
	f.shield = float(dstats["shield"])
	setup(f, p_view)
	is_drone = true
	manual = false
	velocity = Vector2.from_angle(carrier.heading + PI + randf_range(-0.6, 0.6)) * 120.0 + carrier.velocity


func hull_max() -> float:
	return float(dstats["hull"])


func fuel_left() -> float:
	return float(rec.get("fuel", 0.0))


func hostile_to_player() -> bool:
	return false


func _physics_process(delta: float) -> void:
	if dying:
		return
	if carrier == null or not is_instance_valid(carrier) or carrier.dying:
		_lost("its carrier is gone")
		return
	_wcd = maxf(0.0, _wcd - delta)
	hit_flash = maxf(0.0, hit_flash - delta)
	if float(dstats["shield"]) > 0.0:
		fit.shield = minf(float(dstats["shield"]), fit.shield + float(dstats["shield_regen"]) * delta)
	rec["fuel"] = float(rec["fuel"]) - delta * float(BURN[_burn]) / maxf(float(dstats["fuel"]), 1.0)
	rec["hp"] = clampf(fit.structure / maxf(hull_max(), 1.0), 0.0, 1.0)
	if float(rec["fuel"]) <= 0.0:
		_lost("out of fuel")
		return
	tool_beams.clear()
	_burn = "idle"
	_idle = false
	var home_d := position.distance_to(carrier.position)
	var dest: Vector2
	if recalled or view.drones_must_return(carrier):
		_burn = "work"
		work = null
		dest = carrier.position
		if home_d < float(carrier.radius) + 40.0:
			view.stow_drone(self)
			return
	elif home_d > float(dstats["range"]):
		# out of the control range: back towards the carrier, nothing else until it is in range
		_burn = "work"
		work = null
		dest = carrier.position
	else:
		dest = _behave(delta)
	_fly(delta, dest)
	fit.position = position
	queue_redraw()


# ---------------------------------------------------------------- behaviour

func _mode() -> String:
	return String(carrier.fit.drone_modes.get(carrier.fit.drone_role, "rest"))


func _behave(delta: float) -> Vector2:
	match String(carrier.fit.drone_role):
		"combat":
			return _combat(delta)
		"mining":
			return _mining(delta)
		"repair":
			return _repairing(delta)
	return _formation()


## Formation around the carrier (idle / resting).
func _formation() -> Vector2:
	var mates: Array = view.drones_of(carrier)
	var i := maxi(mates.find(self), 0)
	_idle = true
	return carrier.position + formation_slot(i, maxi(mates.size(), 1), float(carrier.radius)).rotated(carrier.heading)


## Symmetric formation (local: x = forward, y = right): drones in mirrored pairs left and right of
## the ship, row by row further back; an odd one flies exactly on the centre line behind.
static func formation_slot(i: int, n: int, r: float) -> Vector2:
	var pairs := n / 2
	if i >= pairs * 2:
		return Vector2(-(r + 70.0 + 40.0 * pairs), 0.0)          # the odd one: right behind
	var k := i / 2
	var side := -1.0 if i % 2 == 0 else 1.0
	return Vector2(-(r * 0.3 + 45.0 * k), side * (r + 55.0 + 35.0 * k))


func _in_reach(n) -> bool:
	return n != null and is_instance_valid(n) and n.position.distance_to(carrier.position) <= float(dstats["range"])


# ---- combat

func _combat(delta: float) -> Vector2:
	if weapon.is_empty():
		return _formation()
	var mode := _mode()
	if mode == "rest":
		return _formation()
	_think -= delta
	if _think <= 0.0 or not _valid_target(work):
		_think = 0.5
		work = _pick_combat_target(mode)
	if work == null:
		return _formation()
	_burn = "combat"
	var d := position.distance_to(work.position)
	var rng := float(weapon["range"])
	if d <= rng and _wcd <= 0.0 and can_see(work):
		_wcd = float(weapon["cooldown"]) * randf_range(0.95, 1.05)
		view.fire_weapon(self, work, weapon)
	var away: Vector2 = position - work.position
	if away.length() < 1.0:
		away = Vector2.RIGHT
	return work.position + away.normalized().rotated(0.5) * rng * 0.6


func _valid_target(n) -> bool:
	return n != null and is_instance_valid(n) and n is Ship and not n.dying and n.is_targetable() and _in_reach(n)


func _pick_combat_target(mode: String):
	match mode:
		"attack":
			var t = carrier.locked_node()
			return t if (t is Ship and t != carrier and not t.is_drone and _valid_target(t)) else null
		"defend":
			return _nearest(func(n): return Ship.hostile(carrier, n) and (n.provoked or n.target == carrier or (n.target != null and is_instance_valid(n.target) and n.target is Ship and n.target.is_drone) or carrier.last_attacker == n))
		"fire_at_will":
			return _nearest(func(n): return not view.is_ally(n))
	return null


func _nearest(pred: Callable):
	var best = null
	var bd := INF
	for n in view.ship_layer.get_children():
		if not (n is Ship) or n == carrier or n.is_drone or not _valid_target(n):
			continue
		if not pred.call(n):
			continue
		var d := position.distance_to(n.position)
		if d < bd:
			bd = d
			best = n
	return best


# ---- mining

func _cargo_used() -> float:
	var v := 0.0
	for o in dcargo:
		v += float(dcargo[o]) * GameData.item_volume(o)
	return v


func _mining(delta: float) -> Vector2:
	var mode := _mode()
	if dtool.is_empty() or mode == "rest":
		return _deliver_or(_formation())
	var full := _cargo_used() >= float(dstats["cargo"]) - 0.01
	if full:
		return _deliver_or(_formation())
	if mode == "target":
		var t = carrier.locked_node()
		work = t if (t != null and not (t is Ship) and t.kind == "asteroid" and not t.is_depleted() and _in_reach(t)) else null
	elif work == null or not is_instance_valid(work) or work.is_depleted() or not _in_reach(work):
		work = _nearest_asteroid()
	if work == null:
		return _deliver_or(_formation())
	_burn = "work"
	var d := position.distance_to(work.position)
	if d <= float(dtool["range"]):
		_mine_drone(delta, work)
	var away: Vector2 = position - work.position
	if away.length() < 1.0:
		away = Vector2.RIGHT
	return work.position + away.normalized() * maxf(float(dtool["range"]) * 0.6, float(work.radius) + 20.0)


func _nearest_asteroid():
	var best = null
	var bd := INF
	for c in view.asteroid_nodes:
		if not is_instance_valid(c) or c.is_depleted() or not _in_reach(c):
			continue
		if Ship.mining_mult(dtool, String(c.data["ore"])) <= 0.0:
			continue
		var d := position.distance_to(c.position)
		if d < bd:
			bd = d
			best = c
	return best


## Mines like the ship's laser (same beam), into the drone's own small hold.
func _mine_drone(delta: float, node) -> void:
	var ore: String = node.data["ore"]
	var room := float(dstats["cargo"]) - _cargo_used()
	var vol := maxf(GameData.item_volume(ore), 0.01)
	var amount := minf(float(dtool["rate"]) * Ship.mining_mult(dtool, ore) * delta, minf(float(node.data["amount"]), room / vol))
	if amount <= 0.0:
		return
	var mix: Dictionary = node.data.get("mix", {ore: 1.0})
	for o in mix:
		dcargo[o] = float(dcargo.get(o, 0.0)) + amount * float(mix[o])
	node.data["amount"] = float(node.data["amount"]) - amount
	var beam_col := Color(0.45, 0.9, 1.0) if dtool.get("tool", "") == "harvester" else Color(1.0, 0.62, 0.25)
	tool_beams.append([node.position, beam_col, "mining", float(node.radius)])
	if node.is_depleted():
		node.queue_redraw()


## Carrying ore: fly to the carrier and unload it; otherwise go to `other`.
func _deliver_or(other: Vector2) -> Vector2:
	if _cargo_used() <= 0.0:
		return other
	_burn = "work"
	if position.distance_to(carrier.position) <= float(carrier.radius) + DELIVER_RANGE:
		unload()
		return other
	return carrier.position


## Hands the ore over to the carrier (what does not fit is lost).
func unload() -> void:
	var got := 0.0
	for o in dcargo:
		got += carrier.fit.add_cargo(o, float(dcargo[o]))
	if got > 0.0:
		GameState.stats["mined"] = float(GameState.stats["mined"]) + got
		if view.sky_alpha() >= 0.5:
			view.spawn_fx(Fx.float_text(carrier.position + Vector2(0, -float(carrier.radius) - 10.0), "+%.1f ore (drone)" % got, Color(1.0, 0.8, 0.4)))
	dcargo.clear()


# ---- repair

func _repairing(delta: float) -> Vector2:
	var mode := _mode()
	if mode == "rest":
		return _formation()
	_think -= delta
	if _think <= 0.0 or not _needs_repair(work):
		_think = 0.5
		work = _pick_repair_target(mode)
	if work == null:
		return _formation()
	_burn = "work"
	var rr := float(dstats["repair_range"])
	if position.distance_to(work.position) <= rr:
		var bs: Dictionary = work.fit.stats()
		var heal := float(dstats["repair"]) * delta
		var amax: float = float(bs["armor_max"])
		var smax: float = work.hull_max() if work.is_drone else float(bs["structure_max"])
		var to_armor := minf(heal, maxf(amax - work.fit.armor, 0.0))
		work.fit.armor += to_armor
		work.fit.structure = minf(smax, work.fit.structure + heal - to_armor)
		tool_beams.append([work.position, Color(0.4, 1.0, 0.5)])
	var away: Vector2 = position - work.position
	if away.length() < 1.0:
		away = Vector2.RIGHT
	return work.position + away.normalized() * (float(work.radius) + rr * 0.5)


func _damage_of(n) -> float:
	if n == null or not is_instance_valid(n) or not (n is Ship) or n.dying or not n.is_targetable():
		return 0.0
	var bs: Dictionary = n.fit.stats()
	var smax: float = n.hull_max() if n.is_drone else float(bs["structure_max"])
	return maxf(float(bs["armor_max"]) - n.fit.armor, 0.0) + maxf(smax - n.fit.structure, 0.0)


func _needs_repair(n) -> bool:
	return _damage_of(n) > 0.5 and _in_reach(n)


func _pick_repair_target(mode: String):
	var cands: Array = []
	match mode:
		"target":
			var t = carrier.locked_node()
			if t is Ship and not Ship.hostile(carrier, t):
				cands = [t]
		"self":
			cands = [carrier]
		"allies":
			cands = [carrier]
			for n in view.ship_layer.get_children():
				if n is Ship and n != self and view.is_ally(n):
					cands.append(n)
		"auto":
			cands = [carrier]
			for n2 in view.ship_layer.get_children():
				if n2 is Ship and n2 != self and n2 != carrier and not Ship.hostile(carrier, n2):
					cands.append(n2)
	var best = null
	var worst := 0.5
	for c in cands:
		if not _needs_repair(c):
			continue
		var dmg := _damage_of(c)
		if dmg > worst:
			worst = dmg
			best = c
	return best


# ---------------------------------------------------------------- movement, loss

func _fly(delta: float, dest: Vector2) -> void:
	var spd := maxf(float(dstats["speed"]), carrier.velocity.length() * 1.3)
	var to := dest - position
	var dist := to.length()
	var desired := carrier.velocity if dist < 300.0 else Vector2.ZERO   # keep pace with the ship
	if dist > 2.0:
		var brake := spd * spd / (2.0 * spd * 2.0)
		var s2 := spd if dist > brake else spd * dist / brake
		desired += to / dist * s2
	velocity = velocity.move_toward(desired, spd * 2.0 * delta)
	position += velocity * delta
	if _idle and dist < 40.0:
		heading = _rotate_toward(heading, carrier.heading, 6.0 * delta)   # in formation: same heading
	elif (velocity - carrier.velocity).length() > 8.0:
		heading = _rotate_toward(heading, velocity.angle(), 8.0 * delta)


func _lost(why: String) -> void:
	if dying:
		return
	dying = true
	if carrier != null and is_instance_valid(carrier):
		carrier.fit.drones.erase(rec)
		if carrier == view.player:
			GameState.log_msg("Drone lost – %s." % why, GameState.COL_WARN)
	view.spawn_fx(Fx.explosion(position, 25.0, Color(1.0, 0.7, 0.3)))
	queue_free()


## Shot down (overrides Ship._die: no wreck, no bounty).
func _die(_killer) -> void:
	_lost("destroyed")
