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
var runway := false               # still taking off along the carrier's flight deck
var hatch_launch := false         # waiting below the carrier's drone hatch (package 25d, Citadel)
var hatch_name := "drones"        # the hangar door it uses (Concord carriers have several, package 25e)
var stunned_t := 0.0              # knocked out by an anti-drone pulse: drifts, does nothing (package 25f)
var stun_white := false           # 0.6.37.2: knocked out by a coronal mass ejection – white lightning instead of red
var _hold := 0.0                  # waiting for its turn at the start of the runway
const RUNWAY_GAP := 0.45          # seconds between two drones on the runway
const HATCH_WAIT := 0.5           # the drone hatch needs this long to slide open


func setup_drone(p_carrier: Ship, p_rec: Dictionary, p_view: Node, uid: int, n: int) -> void:
	carrier = p_carrier
	rec = p_rec
	var cs: Dictionary = carrier.fit.stats()
	dstats = cs["drone"]
	weapon = cs["drone_weapon"]
	dtool = cs["drone_tool"]
	var f := ShipFitting.new("drone_cloak" if dstats.get("cloak", false) else "drone", carrier.faction)    # NPC carriers fly drones too (package 25e)
	f.gov = carrier.fit.gov
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
	if p_view != null and "_drones_frame" in p_view:
		p_view._drones_frame = -1                  # review P2: the carrier's drone list includes this one now
	paint = String(carrier.fit.hull().get("drone_paint", carrier.paint))
	is_drone = true
	manual = false
	velocity = Vector2.from_angle(carrier.heading + PI + randf_range(-0.6, 0.6)) * 120.0 + carrier.velocity
	if carrier.has_deck():
		# carriers with a flight deck: one after the other down the whole runway, then off they go
		position = carrier.deck_point(0.0)
		velocity = carrier.velocity
		heading = carrier.heading
		fit.position = position
		runway = true
		_hold = RUNWAY_GAP * carrier.deck_queue
		carrier.deck_queue += 1
	elif not carrier.drone_hatches().is_empty():
		# hangar doors slide open, the drones rise out of them – one after another per door, with
		# several doors (Concord carriers) side by side at the same time
		var hs: Array = carrier.drone_hatches()
		hatch_launch = true
		hatch_name = hs[carrier.next_hatch % hs.size()]     # the doors in turn – also for single launches
		carrier.next_hatch += 1
		_hold = HATCH_WAIT + RUNWAY_GAP * float(carrier.hatch_queue / hs.size())
		carrier.hatch_queue += 1
		carrier.open_hatch(hatch_name, _hold + 0.4)
		position = carrier.hatch_point(hatch_name)
		velocity = carrier.velocity
		heading = carrier.heading
		visible = false


func hull_max() -> float:
	return float(dstats["hull"])


func fuel_left() -> float:
	return float(rec.get("fuel", 0.0))


func hostile_to_player() -> bool:
	if carrier != null and is_instance_valid(carrier) and carrier.faction != "player":
		return carrier.hostile_to_player()     # an NPC carrier's drone sides with its carrier (25e)
	return false


func _physics_process(delta: float) -> void:
	if dying:
		return
	if carrier == null or not is_instance_valid(carrier):
		# review W7: the carrier left the system (jump, docking, despawn) – its drones go with it, quietly
		dying = true
		queue_free()
		return
	if carrier.dying:
		_lost("its carrier is gone")
		return
	if runway:
		_take_off(delta)
		return
	if hatch_launch:
		_rise_from_hatch(delta)
		return
	if stunned_t > 0.0:
		# knocked out (package 25f): drifts helplessly, flickers, still burns fuel
		stunned_t -= delta
		if stunned_t <= 0.0:
			stun_white = false
		rec["fuel"] = float(rec["fuel"]) - delta * float(BURN["idle"]) / maxf(float(dstats["fuel"]), 1.0)
		if float(rec["fuel"]) <= 0.0:
			_lost("out of fuel")
			return
		position += velocity * delta
		velocity *= 0.995
		heading += delta * 1.5
		fit.position = position
		modulate.a = 0.45 + 0.4 * absf(sin(stunned_t * 9.0))
		tool_beams.clear()
		queue_redraw()
		return
	modulate.a = 1.0
	_update_cloak_fx(delta)                     # 0.4.25.40: cloak drones fade with their ship
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
		dest = carrier.deck_point(0.5)
		var land := 40.0 if carrier.has_deck() else float(carrier.radius) + 40.0
		if not carrier.drone_hatches().is_empty():
			var hn: String = carrier.nearest_drone_hatch(position)
			dest = carrier.hatch_point(hn)             # back in through the nearest hangar door
			land = 40.0
			if position.distance_to(dest) < 350.0:
				carrier.open_hatch(hn, 0.6)
		if position.distance_to(dest) < land:
			view.stow_drone(self)
			return
	elif cloaked():
		# cloaked with the ship: no shooting, no mining – they keep station near the carrier
		_burn = "idle"
		work = null
		dest = carrier.position if home_d > 900.0 else position + carrier.velocity * 0.5
	elif home_d > float(dstats["range"]) or in_shadow():
		# out of the control range or in a radar shadow: back towards the carrier, nothing else until then
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


## Within the control range and visible from the carrier (not in the radar shadow of a colossus).
func _in_reach(n) -> bool:
	return n != null and is_instance_valid(n) and n.position.distance_to(carrier.position) <= float(dstats["range"]) \
		and view.line_of_sight(carrier.position, n.position)


## The drone itself is cut off from its carrier by a colossus.
func in_shadow() -> bool:
	return not view.line_of_sight(carrier.position, position)


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
			return _nearest(func(n): return Ship.hostile(carrier, n) and (n.provoked or n.target == carrier or (n.target != null and is_instance_valid(n.target) and n.target is Ship and n.target.is_drone) or carrier.last_attacker == n
				or (carrier.faction != "player" and n == carrier.target)))
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
## Simulation – in co-op this runs on the host only: it writes to GameState / the fitting directly.
func unload() -> void:
	var got := 0.0
	for o in dcargo:
		got += carrier.fit.add_cargo(o, float(dcargo[o]))
	if got > 0.0:
		GameState.stats["mined"] = float(GameState.stats["mined"]) + got
		GameState.crew_learn("mined", got)      # package 31
		GameState.skill_xp("mining", 0.2 * got)
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


# ---------------------------------------------------------------- take-off along the flight deck

## Along the whole deck, on its centre line, accelerating – only past the bow does it break away.
func _take_off(delta: float) -> void:
	var fwd := Vector2.from_angle(carrier.heading)
	var start: Vector2 = carrier.deck_point(0.0)
	if _hold > 0.0:
		_hold -= delta
		position = start
		velocity = carrier.velocity
		heading = carrier.heading
		visible = false
		fit.position = position
		return
	visible = true
	var deck_len: float = carrier.deck_point(1.0).distance_to(start)
	var along: float = (position - start).dot(fwd)
	var side: float = (position - start).dot(fwd.orthogonal())
	var rel := velocity - carrier.velocity
	var spd := rel.dot(fwd)
	spd = minf(spd + float(dstats["speed"]) * 1.4 * delta, float(dstats["speed"]))
	velocity = carrier.velocity + fwd * spd - fwd.orthogonal() * side * 4.0
	position += velocity * delta
	heading = carrier.heading
	fit.position = position
	queue_redraw()
	if along >= deck_len + 60.0:
		runway = false
		carrier.deck_queue = maxi(carrier.deck_queue - 1, 0)


## Waits in the dark below the drone hatch until it is open and its turn has come, then rises out.
func _rise_from_hatch(delta: float) -> void:
	_hold -= delta
	position = carrier.hatch_point(hatch_name)
	velocity = carrier.velocity
	heading = carrier.heading
	fit.position = position
	visible = _hold < 0.3 and float(carrier.hatch_open.get(hatch_name, 0.0)) > 0.7
	if _hold <= 0.0:
		hatch_launch = false
		visible = true
		carrier.hatch_queue = maxi(carrier.hatch_queue - 1, 0)
		var side := signf((position - carrier.position).dot(Vector2.from_angle(carrier.heading).orthogonal()))
		if side == 0.0:
			side = 1.0 if randf() < 0.5 else -1.0
		velocity = carrier.velocity + Vector2.from_angle(carrier.heading + PI * 0.5 * side) * 160.0   # out to its own side
	queue_redraw()


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
	desired = _avoid_colossi(desired)
	velocity = velocity.move_toward(desired, spd * 2.0 * delta)
	position += velocity * delta
	_push_out_of_colossi()
	if _idle and dist < 40.0:
		heading = _rotate_toward(heading, carrier.heading, 6.0 * delta)   # in formation: same heading
	elif (velocity - carrier.velocity).length() > 8.0:
		heading = _rotate_toward(heading, velocity.angle(), 8.0 * delta)


## Review W2 (0.4.25.46): a drone removed while it still waits for / rolls down the flight deck or rises out of
## the hatch gives its place in the queue back – otherwise later launches (and trader drones) would wait for ever.
func _exit_tree() -> void:
	release_launch()


func release_launch() -> void:
	if carrier == null or not is_instance_valid(carrier):
		return
	if runway:
		runway = false
		carrier.deck_queue = maxi(carrier.deck_queue - 1, 0)
	if hatch_launch:
		hatch_launch = false
		carrier.hatch_queue = maxi(carrier.hatch_queue - 1, 0)


func _lost(why: String) -> void:
	release_launch()
	if dying:
		return
	dying = true
	if carrier != null and is_instance_valid(carrier):
		carrier.fit.drones.erase(rec)
		if carrier == view.player:
			GameState.log_msg("Drone lost – %s." % why, GameState.COL_WARN)
	view.spawn_fx(Fx.explosion(position, 25.0, Color(1.0, 0.7, 0.3)))
	queue_free()


## A cloak drone (0.4.25.40) is cloaked while its ship is.
func cloaked() -> bool:
	return bool(dstats.get("cloak", false)) and carrier != null and is_instance_valid(carrier) and carrier.cloaked()


## Shot down (overrides Ship._die: no wreck, no bounty).
func _die(_killer) -> void:
	_lost("destroyed")


## Knocked out by an anti-drone pulse (0.4.25.32): small red lightning sparks crackle around the drone.
func _draw() -> void:
	super()
	if stunned_t <= 0.0:
		return
	var r := maxf(float(radius), 12.0)
	for k in 4:
		if randf() < 0.35:
			continue
		var a := randf() * TAU
		var p := Vector2.from_angle(a) * r * randf_range(0.4, 0.9)
		var pts: Array = [p]
		for j in 4:
			p += Vector2.from_angle(a + randf_range(-1.1, 1.1)) * r * 0.6
			pts.append(p)
		for j2 in pts.size() - 1:
			draw_line(pts[j2], pts[j2 + 1], Color(0.75, 0.85, 1.0, 0.5) if stun_white else Color(1.0, 0.2, 0.1, 0.5), 5.0)
			draw_line(pts[j2], pts[j2 + 1], Color(1.0, 1.0, 1.0, 1.0) if stun_white else Color(1.0, 0.3, 0.2, 1.0), 2.4)
			draw_line(pts[j2], pts[j2 + 1], Color(1.0, 0.9, 0.8, 0.9), 0.9)
	if randf() < 0.3:
		draw_circle(Vector2.ZERO, r * 0.7, Color(1.0, 0.25, 0.15, 0.25))
