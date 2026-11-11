class_name GroundCombat
extends Node2D
## Package 52 (Luz, 10 Nov 2026): the hybrid fight on foot. You walk (WASD); targets are locked as in space – the
## nearest one by itself when a fight starts, Tab for the next, a click for any – and the weapon fires by itself at
## the active one (hit chance from the weapon, Firearms, distance, cover and how the target moves). Your part:
## position, cover, distance, dodging (Space – no shot hits during the jump; charges from Athletics) and the belt.
## Damage goes through shield → armour → health with the damage types' weights (GearData.apply_damage).
##
## Cover is read from the map: every tile that blocks is HIGH cover (walls, the ship, bulwarks, tall things – no line
## of sight through it) unless an object marks it LOW (crates, rocks, barrels, barriers – you shoot over it, but a
## target right behind it is hard to hit) or NONE (thin posts). Foes (data/foes.gd) are Walkers this node drives:
## they notice you, take cover facing you, shoot, move on when you flank them, rush in (scatter guns) or run.
##
## Drawn in the ground view's world (art px × SCALE): lock brackets, shots, numbers, sparks, the cover ring, the AI view.

const GearData = preload("res://data/gear.gd")
const FoeData = preload("res://data/foes.gd")
const S := GroundMap.SCALE
const MAX_LOCKS := 3
const CHEST := Vector2(0, -15)                    # where shots go and come from (art px above the feet)
const LOW_KINDS := ["crates", "barrel", "rock", "lava_rock", "barrier", "heap", "ore_cart", "crate_seat", "barrel_table", "engine_part", "trash", "dune", "fence"]
const NO_KINDS := ["lamp_post", "signpost", "cable_pole", "banner", "holo_pillar", "plant", "shrub", "parasol", "flower_bed"]
const LAYER_COL := {"shield": Color(0.45, 0.8, 1.0), "armor": Color(1.0, 0.8, 0.3), "health": Color(1.0, 0.35, 0.3)}

var view                                          # the GroundView
var map: GroundMap
var foes: Array = []                              # {w, kind, name, weapon, st, mx, cool, state, aware, goal, path, pi, think, regen_wait, role, flee, firearms, athletics, out_t, id}
var locks: Array = []                             # foe dicts, the active one first in mind: `active`
var active = null
var lock_t := 0.0                                 # seconds left until the active lock is made
var shots: Array = []                             # {a, b, t, life, kind, col, res}  res: the hit to apply on arrival
var floaters: Array = []                          # {pos, text, col, t}
var sparks: Array = []                            # {pos, vel, t}
var booms: Array = []                             # {pos, r, t}
var cover := PackedByteArray()                    # per tile: 0 none, 1 low, 2 high
var fight := false
var frozen := false                               # debug: foes neither move nor shoot
var show_ai := false                              # debug: what the AI sees and thinks
var weapon_i := 0
var pilot_cool := 0.0
var dodge_charges := 2.0
var dodge_t := 0.0
var dodge_dir := Vector2.ZERO
var dodge_mult := 1.0
var trail: Array = []                             # the dodge's after-images (art px)
var in_cover := 0                                 # 0 open, 1 covered from some shooters, 2 from all that see you
var kills := 0
var _t := 0.0
var _next_id := 1
var _out_warned := false
var _end_t := 0.0
## 0.7.52.2 (Luz): the tactical view on Tab – 0 off, 1 your sight (green), 2 the target's sight (red). Drawn like the
## radar in space: a disc as far as the weapon reaches, cover leaves its shadow – behind high cover nothing, right
## behind low cover a band where someone is covered (beyond it you shoot over it again).
var tactics := 0
## 0.7.52.5: grenades – yours on the belt keys (hold: aim at the mouse, release: throw; a tap throws at the target),
## theirs when you sit too long behind the same cover. In flight: {a, b, t, life, id, from, st}; then smoke clouds
## {pos, r, t, time} nobody aims well through, and shield domes {pos, r, hp, mx, t, time} that stop fire and blasts
## from outside and let fire from inside out.
const THROW_RANGE := 190.0
var gr_hold := -1                                  # the belt place being aimed (-1: none)
var gr_held := 0.0
var gr_aim := Vector2.ZERO                         # where it would land (art px)
var aim_at := Vector2.INF                          # debug / tests: aim there instead of at the mouse
var grenades: Array = []
var clouds: Array = []
var domes: Array = []
var camp_t := 0.0                                  # how long you have sat behind the same cover
var _camp_at := Vector2.INF
var tac_node: Node2D = null
var _vis: Dictionary = {}                         # {from, reach, rays: [[t0, t1], …] per ray, at}
const TAC_RAYS := 360
const TAC_STEP := 3.0


func setup(p_view, p_map: GroundMap) -> void:
	view = p_view
	map = p_map
	z_index = 40
	_build_cover()
	dodge_charges = float(max_dodges())
	# the tactical view lies on the ground: under the people and the cover, over the floor
	tac_node = Node2D.new()
	tac_node.draw.connect(_draw_tactics)
	view._world.add_child(tac_node)
	view._world.move_child(tac_node, view._sorted.get_index())


# ---------------------------------------------------------------- cover and sight

func _build_cover() -> void:
	cover.resize(map.w * map.h)
	for y in map.h:
		for x in map.w:
			cover[y * map.w + x] = 0 if GroundMap.walkable_t(map.t_at(x, y)) else 2
	for o in map.objects:
		var k := String(o["kind"])
		var v := -1
		if k in LOW_KINDS:
			v = 1
		elif k in NO_KINDS:
			v = 0
		if v < 0:
			continue
		for yy in range(int(o["y"]), int(o["y"]) + int(o.get("h", 1))):
			for xx in range(int(o["x"]), int(o["x"]) + int(o.get("w", 1))):
				if xx >= 0 and yy >= 0 and xx < map.w and yy < map.h and not GroundMap.walkable_t(map.t_at(xx, yy)):
					cover[yy * map.w + xx] = v


func cover_at(p: Vector2) -> int:
	var x := int(floor(p.x / GroundMap.TILE))
	var y := int(floor(p.y / GroundMap.TILE))
	if x < 0 or y < 0 or x >= map.w or y >= map.h:
		return 2
	return cover[y * map.w + x]


## The line from a to b (feet, art px): {blocked: high cover in the way, cover: low cover right in front of b,
## at: where that low cover is}. The tiles a and b stand on do not count.
func sight(a: Vector2, b: Vector2) -> Dictionary:
	var out := {"blocked": false, "cover": false, "at": Vector2.INF}
	var d := b - a
	var n := int(d.length() / 4.0)
	var ta := Vector2i(floor(a / GroundMap.TILE))
	var tb := Vector2i(floor(b / GroundMap.TILE))
	for i in range(1, n):
		var p := a + d * (float(i) / n)
		var tp := Vector2i(floor(p / GroundMap.TILE))
		if tp == ta or tp == tb:
			continue
		var c := cover_at(p)
		if c == 2:
			out["blocked"] = true
			return out
		if c == 1 and p.distance_to(b) <= GearData.COVER_NEAR and not out["cover"]:
			out["cover"] = true
			out["at"] = p
	return out


# ---------------------------------------------------------------- foes

## A foe of a kind at p (art px); quality "" = the kind's own (stepped up by the tier); tier green/yellow/red
## (0.7.52.4 – stronger body, damage and aim; shown by the ring at its feet). Returns its dict.
func spawn(kind: String, p: Vector2, quality: String = "", tier: String = "green") -> Dictionary:
	var d: Dictionary = FoeData.FOES.get(kind, FoeData.FOES["bandit_rifleman"])
	if not FoeData.TIERS.has(tier):
		tier = "green"
	var td: Dictionary = FoeData.TIERS[tier]
	var q := quality if quality != "" else FoeData.tier_quality(String(d["quality"]), tier)
	var hp := float(d.get("health", 60.0)) * float(td["health"])
	var suit := GearData.stats(FoeData.suit_id(kind, q))
	var lk: Dictionary = ChibiArt.PilotArt.random_look()
	lk["outfit"] = 2
	lk["color1"] = int(d["c1"])
	lk["color2"] = int(d["c2"])
	lk["suit"] = String(d["suit"])
	lk["helmet"] = bool(d["helmet"]) or (view.needs_helmet() if view != null else false)
	lk["headgear"] = 1 if not bool(d["helmet"]) else 0
	if d.has("livery"):
		lk["livery"] = String(d["livery"])                 # 0.7.52.5: pirates' black and red, guards' colours
	var w := Walker.new()
	w.setup(map, lk, p, true)
	w.stays = true
	w.dir = 0
	var wid := FoeData.weapon_id(kind, q)
	w.slung = String(GearData.base(wid).get("dtype", "kinetic"))
	w.aim_dtype = w.slung
	w.aim_weapon = GearData.family(wid)
	view._sorted.add_child(w)
	var f := {"id": _next_id, "w": w, "kind": kind, "name": String(d["name"]), "weapon": wid, "quality": q,
		"st": {"shield": float(suit.get("shield", 0.0)), "armor": float(suit.get("armor", 0.0)), "health": hp},
		"mx": {"shield": float(suit.get("shield", 0.0)), "armor": float(suit.get("armor", 0.0)), "health": hp},
		"tier": tier, "dmg": FoeData.DAMAGE * float(td["damage"]),
		"cool": randf_range(0.3, 1.0), "state": "idle", "aware": false, "goal": Vector2.INF, "path": PackedVector2Array(), "pi": 0,
		"think": randf_range(0.0, 0.5), "regen_wait": 0.0, "role": String(d["role"]), "flee": float(d["flee"]),
		"firearms": int(d["firearms"]) + int(td["firearms"]), "athletics": int(d["athletics"]), "out_t": 0.0, "home": p, "dead": false, "burst": 0,
		"faction": String(d.get("faction", "")), "grenades": int(d.get("grenades", 0)), "gr_cool": randf_range(1.0, 3.0),
		"aim": float(d.get("aim", 1.0)), "rof": float(d.get("rof", 1.0)), "sight": float(d.get("sight", FoeData.SIGHT)), "lost_t": 0.0}
	_next_id += 1
	foes.append(f)
	return f


func alive() -> Array:
	return foes.filter(func(f): return not f["dead"])


func foe_at(p: Vector2) -> Variant:
	var best = null
	var bd := 22.0
	for f in alive():
		var c: Vector2 = (f["w"] as Walker).pos + CHEST
		var dd := c.distance_to(p)
		if dd < bd:
			bd = dd
			best = f
	return best


# ---------------------------------------------------------------- the pilot's side

func pilot_pos() -> Vector2:
	return view.pilot.pos


func weapons() -> Array:
	return GameState.gear.weapons.filter(func(x): return String(x) != "")


func weapon_id() -> String:
	var ws := weapons()
	if ws.is_empty():
		return ""
	return String(ws[weapon_i % ws.size()])


func swap_weapon() -> String:
	var ws := weapons()
	if ws.size() < 2:
		return "Only one weapon at hand."
	weapon_i = (weapon_i + 1) % ws.size()
	pilot_cool = maxf(pilot_cool, 0.5)
	view.pilot.slung = String(GearData.base(String(ws[(weapon_i + 1) % ws.size()])).get("dtype", "kinetic"))
	return "%s in hand." % GearData.display_name(weapon_id())


func max_dodges() -> int:
	return 2 + GameState.skill_level("athletics") / 4


## Space: a jump in the walking direction (or sideways to the target) – no shot hits during it.
func dodge(dir: Vector2) -> bool:
	if dodge_t > 0.0 or dodge_charges < 1.0:
		return false
	var d := dir
	if d.length() < 0.2:
		if active != null:
			var to: Vector2 = (active["w"] as Walker).pos - pilot_pos()
			d = Vector2(-to.y, to.x).normalized()
		else:
			d = Vector2.RIGHT if view.pilot.dir == 3 else (Vector2.LEFT if view.pilot.dir == 2 else (Vector2.UP if view.pilot.dir == 1 else Vector2.DOWN))
	dodge_dir = d.normalized()
	dodge_mult = 1.0
	var g = GameState.gear
	for fid in g.features:
		var fs := GearData.stats(String(fid))
		if fs.has("dash") and g.energy >= float(fs.get("dash_energy", 0.0)):
			dodge_mult = float(fs["dash"])
			g.energy -= float(fs.get("dash_energy", 0.0))
	dodge_t = GearData.DODGE_TIME
	dodge_charges -= 1.0
	Audio.play("boost", "dodge")
	return true


func dodging() -> bool:
	return dodge_t > 0.0


## Locks a foe and makes it the active target (the oldest lock goes when there are too many).
func lock(f) -> void:
	if f == null or f["dead"]:
		return
	if not locks.has(f):
		locks.append(f)
		while locks.size() > MAX_LOCKS:
			var drop = locks[0] if locks[0] != active else locks[1]
			locks.erase(drop)
	if active != f:
		active = f
		lock_t = GearData.LOCK_TIME * (1.0 - 0.04 * GameState.skill_level("firearms"))
	_wake(f)
	Audio.play("lock_acquired", "lock on foot", -6.0)


func unlock(f) -> void:
	locks.erase(f)
	if active == f:
		active = locks[0] if not locks.is_empty() else null
		lock_t = 0.0


## Tab: the next foe you can see, nearest first, after the active one.
func next_target() -> void:
	var seen := alive().filter(func(f): return not sight(pilot_pos(), (f["w"] as Walker).pos)["blocked"])
	if seen.is_empty():
		seen = alive()
	if seen.is_empty():
		return
	seen.sort_custom(func(a, b): return pilot_pos().distance_to((a["w"] as Walker).pos) < pilot_pos().distance_to((b["w"] as Walker).pos))
	var i: int = seen.find(active)
	lock(seen[(i + 1) % seen.size()])


## 0.7.52.9 (Luz): Shift+R – the foe nearest to you (R goes round them all).
func nearest_target() -> void:
	var best = null
	var bd := INF
	for f in alive():
		var dd := pilot_pos().distance_to((f["w"] as Walker).pos) + (400.0 if sight(pilot_pos(), (f["w"] as Walker).pos)["blocked"] else 0.0)
		if dd < bd:
			bd = dd
			best = f
	if best != null:
		lock(best)


func _auto_lock() -> void:
	var best = null
	var bd := INF
	for f in alive():
		if not f["aware"]:
			continue
		var p: Vector2 = (f["w"] as Walker).pos
		var dd := pilot_pos().distance_to(p) + (500.0 if sight(pilot_pos(), p)["blocked"] else 0.0)
		if dd < bd:
			bd = dd
			best = f
	if best != null:
		lock(best)


## The hit chance of a shot from the pilot at a foe now, and of a foe at the pilot.
func chance_at_foe(f) -> float:
	var wid := weapon_id()
	if wid == "":
		return 0.0
	var a := pilot_pos()
	var b: Vector2 = (f["w"] as Walker).pos
	var sg := sight(a, b)
	if sg["blocked"]:
		return 0.0
	var c := GearData.hit_chance(GearData.stats(wid), GameState.skill_level("firearms"), a.distance_to(b), sg["cover"], (f["w"] as Walker).moving, int(f["athletics"]), false)
	return c * (SMOKE_CUT if smoke_between(a, b) else 1.0)


func chance_at_pilot(f) -> float:
	var a: Vector2 = (f["w"] as Walker).pos
	var b := pilot_pos()
	var sg := sight(a, b)
	if sg["blocked"]:
		return 0.0
	var c := GearData.hit_chance(GearData.stats(String(f["weapon"])), int(f["firearms"]), a.distance_to(b), sg["cover"], view.pilot.moving, GameState.skill_level("athletics"), GameState.gear.stim_t > 0.0)
	c = minf(0.97, c * float(f.get("aim", 1.0)))          # 0.7.52.5: the sniper's eye
	return c * (SMOKE_CUT if smoke_between(a, b) else 1.0)


# ---------------------------------------------------------------- the step

func step(delta: float, move: Vector2) -> void:
	_t += delta
	var g = GameState.gear
	# dodging: the jump carries you; charges come back
	if dodge_t > 0.0:
		dodge_t -= delta
		view.pilot.step(dodge_dir, delta, GearData.DODGE_SPEED * dodge_mult)
		trail.append({"p": pilot_pos(), "t": 0.25})
	var mx := max_dodges()
	if dodge_charges < mx:
		dodge_charges = minf(float(mx), dodge_charges + delta / (GearData.DODGE_RECHARGE * (1.0 - 0.03 * GameState.skill_level("athletics"))))
	g.shield_step(delta)
	# the foes
	var aware_any := false
	for f in foes:
		if f["dead"]:
			continue
		_foe_step(f, delta)
		if f["aware"]:
			aware_any = true
	# the fight begins and ends
	if aware_any and not fight:
		fight = true
		_end_t = 0.0
		view._say_toast("Hostiles – they have seen you!", 2.5)
		Audio.play("warn", "fight on foot")
		GameState.codex.event("foot_fight")
		if active == null:
			_auto_lock()
	if fight:
		g.combat_t = maxf(g.combat_t, 8.0)
		if not aware_any:
			_end_t += delta
			if _end_t > 1.5:
				fight = false
				locks.clear()
				active = null
				view._say_toast("The fight is over." if alive().is_empty() else "They have lost you.", 3.0)
		else:
			_end_t = 0.0
	# the active target: gone → the next lock, else the nearest (Luz: the nearest by itself)
	if active != null and active["dead"]:
		unlock(active)
	if fight and active == null:
		_auto_lock()
	lock_t = maxf(0.0, lock_t - delta)
	_pilot_fire(delta)
	# cover of the pilot against those who see you
	var seen_by := 0
	var covered := 0
	for f2 in alive():
		if not f2["aware"]:
			continue
		var sg := sight((f2["w"] as Walker).pos, pilot_pos())
		if sg["blocked"]:
			continue
		seen_by += 1
		if sg["cover"]:
			covered += 1
	in_cover = 0 if covered == 0 else (2 if covered == seen_by else 1)
	# 0.7.52.5: sitting behind the same cover – the ones with grenades notice
	if in_cover > 0 and _camp_at != Vector2.INF and pilot_pos().distance_to(_camp_at) < 24.0:
		camp_t += delta
	else:
		camp_t = 0.0
		_camp_at = pilot_pos()
	if gr_hold >= 0:
		gr_held += delta
		gr_aim = _clamp_throw(view.mouse_art() if aim_at == Vector2.INF else aim_at)
	_grenade_step(delta)
	# the weapon in the hands while fighting, facing the target when standing
	var wid := weapon_id()
	if fight and active != null and wid != "":
		view.pilot.aim = (active["w"] as Walker).pos
		view.pilot.aim_dtype = String(GearData.base(wid).get("dtype", "kinetic"))
		view.pilot.aim_weapon = GearData.family(wid)
		if not view.pilot.moving and dodge_t <= 0.0:
			view.pilot.dir = _face((active["w"] as Walker).pos - pilot_pos())
	else:
		view.pilot.aim = Vector2.INF
	_fx_step(delta)
	_tac_step(delta)
	queue_redraw()
	if tac_node != null:
		tac_node.queue_redraw()


static func _face(d: Vector2) -> int:
	if absf(d.x) > absf(d.y) * 0.8:
		return 3 if d.x > 0.0 else 2
	return 0 if d.y > 0.0 else 1


func _pilot_fire(delta: float) -> void:
	pilot_cool = maxf(0.0, pilot_cool - delta)
	if not fight or active == null or lock_t > 0.0 or dodge_t > 0.0 or pilot_cool > 0.0 or view._collapsed:
		return
	var wid := weapon_id()
	if wid == "":
		return
	var w := GearData.stats(wid)
	var tp: Vector2 = (active["w"] as Walker).pos
	if pilot_pos().distance_to(tp) > float(w["range"]) or sight(pilot_pos(), tp)["blocked"]:
		return
	var g = GameState.gear
	if w.has("energy"):
		if g.energy < float(w["energy"]):
			_out("Suit energy too low for the %s – an energy cell, or Q for another weapon." % String(w["name"]))
			return
		g.energy -= float(w["energy"])
	else:
		var need := int(w.get("ammo", 1))
		if g.ammo < need:
			_out("Out of ammunition – an ammunition box, or Q for another weapon.")
			return
		g.ammo -= need
	_out_warned = false
	pilot_cool = 1.0 / float(w["rof"])
	fire(null, active, w)
	for f in alive():                                  # a shot is heard
		if not f["aware"] and (f["w"] as Walker).pos.distance_to(pilot_pos()) < FoeData.HEAR:
			_wake(f)


func _out(msg: String) -> void:
	if not _out_warned:
		_out_warned = true
		view._say_toast(msg, 3.0)
		Audio.play("ui_error", "out of ammunition")


## One shot (all its pellets) from `from` (null: the pilot) at `to` (null: the pilot) with weapon stats w.
func fire(from, to, w: Dictionary) -> void:
	var a: Vector2 = pilot_pos() if from == null else (from["w"] as Walker).pos
	var b: Vector2 = pilot_pos() if to == null else (to["w"] as Walker).pos
	var sg := sight(a, b)
	var chance: float = chance_at_pilot(from) if to == null else chance_at_foe(to)
	var dome = dome_between(a, b)                         # 0.7.52.5: a shield dome round the target stops it
	var open_chance := chance / (1.0 - GearData.COVER_CUT) if sg["cover"] else chance
	var dtype := String(w.get("dtype", "kinetic"))
	var col: Color = {"optical": Color(0.55, 0.95, 1.0), "kinetic": Color(1.0, 0.85, 0.4), "explosive": Color(1.0, 0.55, 0.2)}.get(dtype, Color.WHITE)
	var pellets := int(w.get("pellets", 1))
	var shooter: Walker = view.pilot if from == null else from["w"]
	shooter.aim = b                                        # 0.7.52.3: the shot leaves the tip of the weapon
	if from == null:
		shooter.aim_weapon = GearData.family(weapon_id())
		shooter.aim_dtype = dtype
	var muzzle := shooter.muzzle_art()
	for i in pellets:
		var r := randf()
		var res := {"to": to, "dmg": float(w["damage"]) * (float(from["dmg"]) if from != null else 1.0), "dtype": dtype, "splash": float(w.get("splash", 0.0)), "from": from}
		var end: Vector2
		if r < chance:
			res["kind"] = "hit"
			end = b + CHEST + Vector2(randf_range(-2, 2), randf_range(-3, 3))
		elif sg["cover"] and r < open_chance:
			res["kind"] = "blocked"
			end = (sg["at"] as Vector2) + Vector2(0, -6)
		else:
			res["kind"] = "miss"
			var ang := randf_range(0.08, 0.25) * (1.0 if randf() < 0.5 else -1.0) + randf_range(-1, 1) * float(w.get("spread", 0.05))
			var dir := (b - a).normalized().rotated(ang)
			end = a + CHEST + dir * minf(float(w["range"]), a.distance_to(b) + 60.0)
			# a miss stops at high cover
			var n := int(a.distance_to(end) / 4.0)
			for k in range(4, n):
				var p := a + dir * k * 4.0
				if cover_at(p) == 2:
					end = p + CHEST
					break
		if dome != null and res["kind"] != "miss":
			res["kind"] = "dome"
			res["dome"] = dome
			var hits := Geometry2D.segment_intersects_circle(a, b, dome["pos"], float(dome["r"]))
			end = (a.lerp(b, hits) if hits >= 0.0 else (dome["pos"] as Vector2) + (a - (dome["pos"] as Vector2)).normalized() * float(dome["r"])) + CHEST
		var instant := dtype == "optical"
		var life := 0.09 if instant else maxf(0.05, muzzle.distance_to(end) / GearData.SHOT_SPEED)
		shots.append({"a": muzzle, "b": end, "t": 0.0, "life": life, "kind": "beam" if instant else ("shell" if dtype == "explosive" else "slug"), "col": col, "res": res, "done": false})
		if instant:
			_resolve(shots[-1])
	if from == null:
		Audio.play("w_pulse" if dtype == "optical" else ("w_rocket" if dtype == "explosive" else "w_autocannon"), "pilot fires on foot", -6.0)
		GameState.gear.combat_t = maxf(GameState.gear.combat_t, 8.0)
	else:
		Audio.play("w_pulse" if dtype == "optical" else ("w_rocket" if dtype == "explosive" else "w_autocannon"), "foe fires on foot", -12.0)


## A shot arrives: the hit is applied (a dodge at this moment turns it into a miss), or sparks where it stopped.
func _resolve(s: Dictionary) -> void:
	if s["done"]:
		return
	s["done"] = true
	var res: Dictionary = s["res"]
	var to = res["to"]
	var kind := String(res["kind"])
	if kind == "hit" and to == null and dodge_t > 0.0:
		kind = "dodged"
		floaters.append({"pos": pilot_pos() + Vector2(0, -34), "text": "dodged", "col": Color(0.6, 1.0, 0.7), "t": 0.0})
		GameState.skill_xp("athletics", 2.0)
	if float(res["splash"]) > 0.0 and kind != "dodged":
		_explode(s["b"] - CHEST if kind != "hit" else (pilot_pos() if to == null else (to["w"] as Walker).pos), float(res["splash"]), float(res["dmg"]), String(res["dtype"]), res["from"])
		return
	match kind:
		"hit":
			if to == null:
				_hurt_pilot(float(res["dmg"]), String(res["dtype"]))
			elif not to["dead"]:
				_hurt_foe(to, float(res["dmg"]), String(res["dtype"]))
				if res["from"] == null:
					GameState.skill_xp("firearms", 1.0)
		"blocked":
			for i in 5:
				sparks.append({"pos": s["b"], "vel": Vector2(randf_range(-60, 60), randf_range(-70, 10)), "t": 0.0})
			if not floaters.any(func(fl): return String(fl["text"]) == "blocked" and float(fl["t"]) < 0.4 and (fl["pos"] as Vector2).distance_to(s["b"]) < 30.0):
				floaters.append({"pos": s["b"] + Vector2(0, -12), "text": "blocked", "col": Color(0.82, 0.82, 0.78), "t": 0.0})
		"dome":
			var dm: Dictionary = res["dome"]
			dm["hp"] = float(dm["hp"]) - float(res["dmg"])
			for i2 in 4:
				sparks.append({"pos": s["b"], "vel": Vector2(randf_range(-50, 50), randf_range(-60, 10)), "t": 0.0, "col": Color(0.45, 0.9, 1.0)})
			if float(dm["hp"]) <= 0.0:
				dm["time"] = 0.0
				floaters.append({"pos": (dm["pos"] as Vector2) + Vector2(0, -50), "text": "shield down", "col": Color(0.45, 0.9, 1.0), "t": 0.0})
		"miss":
			if to != null and res["from"] == null and not floaters.any(func(fl): return String(fl["text"]) == "miss" and float(fl["t"]) < 0.4):
				floaters.append({"pos": (to["w"] as Walker).pos + Vector2(0, -34), "text": "miss", "col": Color(0.75, 0.75, 0.72), "t": 0.0})


func _explode(at: Vector2, r: float, dmg: float, dtype: String, from) -> void:
	booms.append({"pos": at, "r": r, "t": 0.0})
	Audio.play("explosion_small", "shell on foot", -4.0)
	view._shake = 0.25
	var k := blast_share(at, pilot_pos(), r)
	if k > 0.0:
		_hurt_pilot(dmg * k, dtype)
	for f in alive():
		var k2 := blast_share(at, (f["w"] as Walker).pos, r)
		if k2 > 0.0:
			_hurt_foe(f, dmg * k2, dtype)


## 0.7.52.5: how much of a blast at `at` (radius r) reaches p – less further out, nothing behind high cover or inside a
## shield dome it went off outside of, half behind low cover.
func blast_share(at: Vector2, p: Vector2, r: float) -> float:
	var dd := at.distance_to(p)
	if dd >= r:
		return 0.0
	for dm in domes:
		if p.distance_to(dm["pos"]) < float(dm["r"]) and at.distance_to(dm["pos"]) >= float(dm["r"]):
			return 0.0
	var sg := sight(at, p)
	if sg["blocked"]:
		return 0.0
	return (1.0 - dd / r * 0.6) * (0.5 if sg["cover"] else 1.0)


func _hurt_pilot(dmg: float, dtype: String) -> void:
	if Commands.suit_god:
		return                                          # debug: invulnerable
	var out: Dictionary = GameState.gear.take_damage(dmg, dtype)
	_number(pilot_pos(), out)
	Audio.play("hit_hull" if float(out["health"]) > 0.0 else ("hit_armor" if float(out["armor"]) > 0.0 else "hit_shield"), "hit on foot", -8.0)
	view._shake = maxf(view._shake, 0.08)
	if GameState.gear.health <= 0.0:
		view._collapse("fight")


func _hurt_foe(f: Dictionary, dmg: float, dtype: String) -> void:
	var out := GearData.apply_damage(f["st"], dmg, dtype)
	f["regen_wait"] = GearData.SHIELD_WAIT
	_number((f["w"] as Walker).pos, out)
	_wake(f)
	if float(f["st"]["health"]) <= 0.0:
		f["dead"] = true
		f["state"] = "down"
		var w: Walker = f["w"]
		w.down = true
		w.moving = false
		w.aim = Vector2.INF
		w.z_index = -1
		kills += 1
		locks.erase(f)
		floaters.append({"pos": w.pos + Vector2(0, -40), "text": "down", "col": Color(1.0, 0.45, 0.35), "t": 0.0})
		if String(f["role"]) == "leader":                  # 0.7.52.5: the leader falls – the rest lose heart
			var broke := 0
			for o in alive():
				if String(o["faction"]) == String(f["faction"]):
					o["flee"] = minf(0.9, float(o["flee"]) + FoeData.MORALE_BREAK)
					broke += 1
			if broke > 0:
				view._say_toast("%s is down – the rest lose heart!" % String(f["name"]), 3.0)


func _number(at: Vector2, out: Dictionary) -> void:
	var total := float(out["shield"]) + float(out["armor"]) + float(out["health"])
	var layer := "health" if float(out["health"]) > 0.0 else ("armor" if float(out["armor"]) > 0.0 else "shield")
	for fl in floaters:                                   # the pellets of one shot add up to one number
		if float(fl["t"]) < 0.12 and fl.has("sum") and (fl["at"] as Vector2).distance_to(at) < 6.0:
			fl["sum"] = float(fl["sum"]) + total
			fl["text"] = str(int(round(float(fl["sum"]))))
			if layer == "health" or (layer == "armor" and fl["col"] == LAYER_COL["shield"]):
				fl["col"] = LAYER_COL[layer]
			return
	floaters.append({"at": at, "sum": total, "pos": at + Vector2(randf_range(-8, 8), -36), "text": str(int(round(total))), "col": LAYER_COL[layer], "t": 0.0})


func _wake(f: Dictionary) -> void:
	if f["dead"] or f["aware"]:
		return
	f["aware"] = true
	f["think"] = 0.0
	if f["state"] == "idle":
		f["state"] = "engage"
	for o in alive():                                   # it calls out to the others near it
		if not o["aware"] and (o["w"] as Walker).pos.distance_to((f["w"] as Walker).pos) < 220.0:
			o["aware"] = true
			o["state"] = "engage"
			o["think"] = randf_range(0.2, 0.8)


# ---------------------------------------------------------------- the AI

func _foe_step(f: Dictionary, delta: float) -> void:
	var w: Walker = f["w"]
	var st: Dictionary = f["st"]
	# the shield recovers after a while
	f["regen_wait"] = maxf(0.0, float(f["regen_wait"]) - delta)
	if float(f["regen_wait"]) <= 0.0:
		st["shield"] = minf(float(f["mx"]["shield"]), float(st["shield"]) + 2.0 * delta)
	if frozen or view._collapsed:
		w.moving = false
		return
	var pp := pilot_pos()
	var dist := w.pos.distance_to(pp)
	var sg := sight(w.pos, pp)
	if not f["aware"]:
		if dist < float(f["sight"]) and not sg["blocked"] and not smoke_between(w.pos, pp):
			_wake(f)
		else:
			w.moving = false
			return
	var wst := GearData.stats(String(f["weapon"]))
	var reach := float(wst["range"])
	# losing you: out of sight for long enough and far away
	if sg["blocked"] and dist > FoeData.SIGHT * 1.3:
		f["out_t"] = float(f["out_t"]) + delta
		if float(f["out_t"]) > 8.0:
			f["aware"] = false
			f["state"] = "idle"
			w.aim = Vector2.INF
			return
	else:
		f["out_t"] = 0.0
	f["lost_t"] = float(f["lost_t"]) + delta if sg["blocked"] else 0.0
	# running away when badly hurt
	if f["state"] != "flee" and float(st["health"]) < float(f["flee"]) * float(f["mx"]["health"]):
		f["state"] = "flee"
		f["goal"] = _flee_spot(w.pos, pp)
		f["path"] = map.path(w.pos, f["goal"])
		f["pi"] = 0
		floaters.append({"pos": w.pos + Vector2(0, -40), "text": "flees", "col": Color(1.0, 0.8, 0.4), "t": 0.0})
	f["think"] = float(f["think"]) - delta
	if f["state"] != "flee" and float(f["think"]) <= 0.0:
		f["think"] = randf_range(0.8, 1.4)
		_decide(f, dist, sg, reach)
	# walking to the goal
	var moved := false
	if f["goal"] != Vector2.INF:
		var path: PackedVector2Array = f["path"]
		var pi := int(f["pi"])
		if pi < path.size():
			var to: Vector2 = path[pi] - w.pos
			if to.length() < 3.0:
				f["pi"] = pi + 1
			else:
				var run := 1.45 if f["state"] in ["flee", "move"] else 1.0
				moved = w.step(to.normalized(), delta, run)
		else:
			f["goal"] = Vector2.INF
	if not moved:
		w.moving = false
	# shooting
	f["cool"] = float(f["cool"]) - delta
	if f["state"] == "flee":
		w.aim = Vector2.INF
		return
	w.aim = pp
	if not w.moving:
		w.dir = _face(pp - w.pos)
	if float(f["cool"]) <= 0.0 and not sg["blocked"] and dist <= reach:
		fire(f, null, wst)
		var base := 1.0 / (float(wst["rof"]) * float(f["rof"]))
		if String(f["role"]) == "holder" and float(wst["rof"]) >= 4.0:
			f["burst"] = int(f["burst"]) + 1
			f["cool"] = base if int(f["burst"]) % 6 != 0 else base + 1.6          # bursts of six
		else:
			f["cool"] = base * randf_range(1.0, 1.5) + (0.3 if w.moving else 0.0)
	# 0.7.52.5: a grenade at you when you have dug in
	f["gr_cool"] = float(f["gr_cool"]) - delta
	var camp_need := FoeData.THROWER_CAMP if String(f["role"]) == "thrower" else FoeData.GRENADE_CAMP
	if int(f["grenades"]) > 0 and float(f["gr_cool"]) <= 0.0 and camp_t >= camp_need and dist <= THROW_RANGE * 1.3 and dist > 40.0:
		var land := pp + Vector2(randf_range(-14, 14), randf_range(-10, 10))
		throw_grenade(f, land, "gr_frag")
		f["grenades"] = int(f["grenades"]) - 1
		f["gr_cool"] = 5.0


## What to do next – by the foe's role (0.7.52.5, FoeData.ROLE): rushers close in, flankers run round to your open
## side, holders keep their spot, the rest (riflemen, throwers, leaders, snipers) take cover facing you at their
## distance – near their leader, if they have one.
func _decide(f: Dictionary, dist: float, sg: Dictionary, reach: float) -> void:
	var w: Walker = f["w"]
	var pp := pilot_pos()
	var role := String(f["role"])
	var rd: Dictionary = FoeData.ROLE.get(role, FoeData.ROLE["rifleman"])
	if role == "rusher":
		var want := reach * float(rd["pref"])
		if dist > want or sg["blocked"]:
			var tgt := pp + (w.pos - pp).normalized().rotated(randf_range(-0.6, 0.6)) * want * 0.8
			_go(f, _free_near(tgt), "move")
		elif f["goal"] == Vector2.INF and randf() < 0.5:
			# strafing about close in
			_go(f, _free_near(w.pos + (pp - w.pos).normalized().rotated(PI * 0.5 * (1.0 if randf() < 0.5 else -1.0)) * 28.0), "fight")
		return
	if role == "flanker":
		_decide_flank(f, dist, sg, reach)
		return
	var covered: bool = sight(pp, w.pos)["cover"]
	var good: bool = covered and not sg["blocked"] and dist <= reach * 0.95
	if role == "holder" and f["state"] == "cover" and float(f["lost_t"]) < 6.0:
		return                                        # it holds its spot (unless it has lost you for long)
	if good and f["goal"] == Vector2.INF:
		f["state"] = "cover"
		return
	if f["goal"] != Vector2.INF and f["state"] == "move":
		return                                        # on the way
	var spot := _cover_spot(w.pos, pp, reach, float(rd["pref"]), _leader_of(f), 14 if role == "sniper" else 8)
	if spot != Vector2.INF:
		_go(f, spot, "move")
	elif dist > reach * 0.9 or sg["blocked"]:
		_go(f, _free_near(pp + (w.pos - pp).normalized() * reach * float(rd["pref"])), "move")
	else:
		f["state"] = "fight"


## A flanker: somewhere at your side, off the line the others shoot along, where your cover does not cover you from it.
func _decide_flank(f: Dictionary, dist: float, sg: Dictionary, reach: float) -> void:
	var w: Walker = f["w"]
	var pp := pilot_pos()
	var open_shot: bool = not sg["blocked"] and not sight(w.pos, pp)["cover"] and dist <= reach * 0.85
	if open_shot and f["goal"] == Vector2.INF:
		f["state"] = "fight"
		if randf() < 0.35:                            # keeps moving a little so it is hard to hit
			_go(f, _free_near(w.pos + (pp - w.pos).normalized().rotated(PI * 0.5 * (1.0 if randf() < 0.5 else -1.0)) * 24.0), "fight")
		return
	if f["goal"] != Vector2.INF and f["state"] == "move":
		return
	# the line the others fight along
	var front := Vector2.ZERO
	for o in alive():
		if o != f and o["aware"]:
			front += ((o["w"] as Walker).pos - pp).normalized()
	if front.length() < 0.1:
		front = (w.pos - pp).normalized()
	front = front.normalized()
	var side := 1.0 if front.cross(w.pos - pp) >= 0.0 else -1.0
	var best := Vector2.INF
	var bs := INF
	for k in 9:
		var ang := side * randf_range(PI * 0.4, PI * 0.75)
		var q := pp + front.rotated(ang) * reach * randf_range(0.35, 0.6)
		q = _free_near(q)
		if q == Vector2.INF:
			continue
		var s2 := sight(q, pp)
		if s2["blocked"] or s2["cover"]:
			continue
		var score := q.distance_to(w.pos) + randf() * 20.0
		if score < bs:
			bs = score
			best = q
	if best != Vector2.INF:
		_go(f, best, "move")
		f["state"] = "move"
	elif not sg["blocked"]:
		f["state"] = "fight"


## The leader of a foe's band (alive, the same faction, not itself) – null if there is none.
func _leader_of(f: Dictionary) -> Variant:
	for o in alive():
		if o != f and String(o["role"]) == "leader" and String(o["faction"]) == String(f["faction"]):
			return o
	return null


func _go(f: Dictionary, to: Vector2, state: String) -> void:
	if to == Vector2.INF:
		return
	var w: Walker = f["w"]
	var path := map.path(w.pos, to)
	if path.is_empty():
		return
	f["goal"] = to
	f["path"] = path
	f["pi"] = 0
	f["state"] = state


## The best spot near p to fight you from: a free tile right behind low cover (the cover between it and you), in
## reach, with you in sight over it; near, and about `pref` of the reach away from you. INF if there is none.
func _cover_spot(p: Vector2, pp: Vector2, reach: float, pref: float, leader = null, rad: int = 8) -> Vector2:
	var best := Vector2.INF
	var bs := INF
	var tx := int(p.x / GroundMap.TILE)
	var ty := int(p.y / GroundMap.TILE)
	var lp: Vector2 = (leader["w"] as Walker).pos if leader != null else Vector2.INF
	for yy in range(ty - rad, ty + rad + 1):
		for xx in range(tx - rad, tx + rad + 1):
			if not GroundMap.walkable_t(map.t_at(xx, yy)):
				continue
			var c := (Vector2(xx, yy) + Vector2(0.5, 0.6)) * GroundMap.TILE
			var dd := c.distance_to(pp)
			if dd > reach * 0.95 or dd < 80.0:                   # not right on top of you
				continue
			if _taken(c):
				continue
			var sg := sight(pp, c)
			if sg["blocked"] or not sg["cover"]:
				continue
			var score := c.distance_to(p) + absf(dd - reach * pref) * 0.6 + randf() * 12.0
			if lp != Vector2.INF:
				score += maxf(0.0, c.distance_to(lp) - 140.0) * 0.5      # 0.7.52.5: the band keeps near its leader
			if score < bs:
				bs = score
				best = c
	return best


## Another foe stands or is going there.
func _taken(c: Vector2) -> bool:
	for f in alive():
		if (f["w"] as Walker).pos.distance_to(c) < 14.0 or (f["goal"] != Vector2.INF and (f["goal"] as Vector2).distance_to(c) < 14.0):
			return true
	return false


func _free_near(p: Vector2) -> Vector2:
	for r in range(0, 64, 8):
		for k in 8:
			var q := p + Vector2(r, 0).rotated(k * TAU / 8.0)
			if map.free_at(q, 5.0):
				return q
	return Vector2.INF


func _flee_spot(from: Vector2, pp: Vector2) -> Vector2:
	var best := from
	var bd := -1.0
	for k in 24:
		var q := Vector2(randf_range(1, map.w - 1), randf_range(1, map.h - 1)) * GroundMap.TILE
		if not map.free_at(q, 5.0):
			continue
		var dd := q.distance_to(pp) - q.distance_to(from) * 0.3
		if dd > bd:
			bd = dd
			best = q
	return best


# ---------------------------------------------------------------- 0.7.52.2: the tactical view

## Tab tapped: your sight → the target's sight → your sight … (the target's only when there is one).
func cycle_tactics() -> String:
	if tactics == 1 and tac_viewer() != null:
		tactics = 2
	else:
		tactics = 1
	_vis = {}
	Audio.play("scan_ping", "tactical view", -8.0)
	return ""


## Whose sight the red view shows: the active target, else the nearest foe that knows of you.
func tac_viewer() -> Variant:
	if active != null and not active["dead"]:
		return active
	var best = null
	var bd := INF
	for f in alive():
		var dd := pilot_pos().distance_to((f["w"] as Walker).pos)
		if f["aware"] and dd < bd:
			bd = dd
			best = f
	return best


## Rays from `from` out to `reach` (art px): for each, the stretches that are in sight – ended by high cover, broken
## by low cover and the band right behind it (COVER_NEAR) where someone is covered.
func cast(from: Vector2, reach: float) -> Array:
	var rays: Array = []
	var own := Vector2i(floor(from / GroundMap.TILE))
	# 0.7.52.6 (Luz): a shield dome stops sight and fire from outside – rays end where they reach it; seen from inside
	# it lets everything out. Smoke: from where a ray enters a cloud on, shots aim badly – those stretches carry a flag.
	var outer_domes: Array = domes.filter(func(dm): return float(dm["hp"]) > 0.0 and from.distance_to(dm["pos"]) >= float(dm["r"]))
	for i in TAC_RAYS:
		var dir := Vector2.from_angle(TAU * i / TAC_RAYS)
		var lit: Array = []
		var open_at := 0.0
		var is_open := true
		var in_low := false
		var guard_to := -1.0
		var smoked := false
		var open_smoked := false
		var t := TAC_STEP
		while t < reach:
			var p := from + dir * t
			var c := cover_at(p)
			if Vector2i(floor(p / GroundMap.TILE)) == own:
				c = 0
			if c == 2:
				break
			var in_dome := false
			for dm in outer_domes:
				if p.distance_to(dm["pos"]) < float(dm["r"]):
					in_dome = true
			if in_dome:
				break
			if not smoked:
				for cl in clouds:
					if p.distance_to(cl["pos"]) < float(cl["r"]) * minf(1.0, float(cl["t"]) * 3.0):
						smoked = true
			if c == 1:
				in_low = true
			elif in_low:
				in_low = false
				guard_to = t + GearData.COVER_NEAR
			var want := not in_low and t >= guard_to
			if want and is_open and smoked != open_smoked:
				if t - open_at > 0.5:
					lit.append([open_at, t, open_smoked])        # the smoke begins: a new stretch
				open_at = t
				open_smoked = smoked
			if want and not is_open:
				is_open = true
				open_at = t
				open_smoked = smoked
			elif not want and is_open:
				is_open = false
				if t - open_at > 0.5:
					lit.append([open_at, t, open_smoked])
			t += TAC_STEP
		if is_open and minf(t, reach) - open_at > 0.5:
			lit.append([open_at, minf(t, reach), open_smoked])
		rays.append(lit)
	return rays


## Is p in sight in a cast made from `from` (the ray nearest its direction)?
func lit_in(rays: Array, from: Vector2, p: Vector2) -> bool:
	var d := p - from
	var i := posmod(int(round(d.angle() / TAU * TAC_RAYS)), TAC_RAYS)
	var dist := d.length()
	for seg in rays[i]:
		if dist >= float(seg[0]) and dist <= float(seg[1]):
			return true
	return false


## 0.7.52.3 (Luz): your view reaches exactly as far as the weapon in your hands (0.7.52.6: the foe's as far as its own).
func tac_reach() -> float:
	var wid := weapon_id()
	return float(GearData.stats(wid).get("range", 300.0)) if wid != "" else 300.0


func _tac_source() -> Dictionary:
	if tactics == 2:
		var f = tac_viewer()
		if f == null:
			return {}
		# 0.7.52.6 (Luz): the foe's view reaches as far as its own weapon – how far it can shoot
		return {"from": (f["w"] as Walker).pos, "reach": float(GearData.stats(String(f["weapon"])).get("range", 300.0)), "red": true, "who": f}
	return {"from": pilot_pos(), "reach": tac_reach(), "red": false, "who": null}


func _tac_step(delta: float) -> void:
	if tactics == 2 and tac_viewer() == null:
		tactics = 1
	if tactics == 0:
		_vis = {}
		return
	var src := _tac_source()
	if src.is_empty():
		return
	_vis["at"] = float(_vis.get("at", 0.0)) - delta
	if _vis.get("rays") == null or (src["from"] as Vector2).distance_to(_vis.get("from", Vector2.INF)) > 2.0 or float(_vis["at"]) <= 0.0 			or not is_equal_approx(float(_vis.get("reach", 0.0)), float(src["reach"])) or bool(_vis.get("red", false)) != bool(src["red"]):
		_vis = {"from": src["from"], "reach": src["reach"], "red": src["red"], "rays": cast(src["from"], src["reach"]), "at": 0.25}


func _draw_tactics() -> void:
	_draw_tactics_view()
	# 0.7.52.4 (Luz): how strong each foe is – a coloured ring on the ground at its feet
	for f in alive():
		var col: Color = FoeData.TIERS[String(f.get("tier", "green"))]["col"]
		var fp: Vector2 = (f["w"] as Walker).pos * S + Vector2(0, -2)
		tac_node.draw_set_transform(fp, 0.0, Vector2(1.0, 0.45))
		tac_node.draw_circle(Vector2.ZERO, 26.0, Color(col, 0.22))
		tac_node.draw_arc(Vector2.ZERO, 26.0, 0.0, TAU, 40, Color(0.03, 0.03, 0.05, 0.85), 8.0)    # dark edge: seen on any ground
		tac_node.draw_arc(Vector2.ZERO, 26.0, 0.0, TAU, 40, col, 4.0)
		tac_node.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_tactics_view() -> void:
	if tactics == 0 or _vis.get("rays") == null:
		return
	var from: Vector2 = _vis["from"]
	var reach: float = _vis["reach"]
	var red: bool = _vis["red"]
	var col := Color(1.0, 0.3, 0.28) if red else Color(0.35, 1.0, 0.55)
	# 0.7.52.7 (Luz): the shadows in the other side's colour – in your view red where foes are covered from you, in a
	# foe's view green where you are safe from it; the ground behind smoke yellow
	# 0.7.52.9 (Luz): a little less vivid
	var shade := Color(0.45, 0.78, 0.55) if red else Color(0.82, 0.42, 0.38)
	var smoke_col := Color(0.88, 0.78, 0.42)
	var c := from * S
	# a dark disc under it all: the colours stand out on any ground
	tac_node.draw_circle(c, reach * S, Color(0.0, 0.0, 0.0, 0.3))
	var rays: Array = _vis["rays"]
	var h := TAU / TAC_RAYS * 0.5
	var fill := Color(col, 0.2)
	var edges: Array = []                                   # the edges between rays – shared exactly, no seams
	for j in rays.size() + 1:
		edges.append(Vector2.from_angle(TAU * j / TAC_RAYS - h))
	var sfill := Color(shade, 0.18)
	for i in rays.size():
		var d0: Vector2 = edges[i]
		var d1: Vector2 = edges[i + 1]
		var last := TAC_STEP
		for seg in rays[i]:
			var t0 := float(seg[0]) * S
			var t1 := float(seg[1]) * S
			if float(seg[0]) - last > 0.5:                          # the shadow before this stretch
				tac_node.draw_colored_polygon(PackedVector2Array([c + d0 * last * S, c + d1 * last * S, c + d1 * t0, c + d0 * t0]), sfill)
			last = float(seg[1])
			if seg.size() > 2 and bool(seg[2]):
				# 0.7.52.6/7: behind smoke – yellow, with a hatch every few rays: shots through here aim badly
				tac_node.draw_colored_polygon(PackedVector2Array([c + d0 * t0, c + d1 * t0, c + d1 * t1, c + d0 * t1]), Color(smoke_col, 0.18))
				if i % 4 == 0:
					var hd := (d0 + d1) * 0.5
					var tt := t0 + fposmod(-t0, 24.0)
					while tt < t1:
						var hp0 := c + hd * tt
						tac_node.draw_line(hp0, hp0 + hd.rotated(PI * 0.5) * 9.0, Color(smoke_col, 0.45), 1.5)
						tt += 18.0
				continue
			tac_node.draw_colored_polygon(PackedVector2Array([c + d0 * t0, c + d1 * t0, c + d1 * t1, c + d0 * t1]), fill)
		if reach - last > 0.5:                                      # the shadow out to the reach
			tac_node.draw_colored_polygon(PackedVector2Array([c + d0 * last * S, c + d1 * last * S, c + d1 * reach * S, c + d0 * reach * S]), sfill)
	# the edges of the shadows: where a ray's sight ends short of the reach
	for i2 in rays.size():
		var segs: Array = rays[i2]
		var a2 := TAU * i2 / TAC_RAYS
		for seg2 in segs:
			if float(seg2[1]) < reach - 1.0:
				tac_node.draw_circle(c + Vector2.from_angle(a2) * float(seg2[1]) * S, 1.6, Color(shade, 0.6))
	# rings and the reach, as on the radar
	for k in range(1, 4):
		tac_node.draw_arc(c, reach * S * k / 4.0, 0.0, TAU, 96, Color(col, 0.14), 1.0)
	tac_node.draw_arc(c, reach * S, 0.0, TAU, 160, Color(col, 0.9), 3.0)            # the reach of your weapon, exactly
	var wid := weapon_id()
	var who = tac_viewer() if red else null
	if who != null:
		wid = String(who["weapon"])
	var lbl := "%s%s – %d m" % [(String(who["name"]) + ": ") if who != null else "", String(GearData.base(wid).get("name", "")), int(round(reach / 15.0))]
	for ang in [-PI * 0.5, 0.0]:
		var lp := c + Vector2.from_angle(ang) * reach * S + Vector2(6, -6)
		tac_node.draw_string_outline(ThemeDB.fallback_font, lp, lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 4, Color(0, 0, 0, 0.8))
		tac_node.draw_string(ThemeDB.fallback_font, lp, lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(col, 0.95))
	if not red:
		var sweep := fmod(_t / 2.4, 1.0) * TAU                       # the sweep with its afterglow
		for j in 18:
			var b0 := sweep - j * 0.045
			var b1 := sweep - (j + 1) * 0.045
			tac_node.draw_colored_polygon(PackedVector2Array([c, c + Vector2.from_angle(b0) * reach * S, c + Vector2.from_angle(b1) * reach * S]),
				Color(col, 0.12 * pow(1.0 - j / 18.0, 1.6)))
		tac_node.draw_line(c, c + Vector2.from_angle(sweep) * reach * S, Color(0.7, 1.0, 0.8, 0.6), 2.0)


# ---------------------------------------------------------------- 0.7.52.5: grenades, smoke, shield domes

const SMOKE_CUT := 0.3                             # a shot through smoke keeps this share of its chance


## 0.7.52.9 (Luz): one grenade is in hand, as with the weapons – X tapped takes the next, X held aims it (the arc to
## the mouse after GR_HOLD seconds), let go throws it.
const GR_HOLD := 0.25


## X pressed: aiming starts (false if there is no grenade).
func grenade_down() -> bool:
	if GameState.gear.grenade().is_empty():
		return false
	gr_hold = int(GameState.gear.gr_sel)
	gr_held = 0.0
	gr_aim = _clamp_throw(view.mouse_art() if aim_at == Vector2.INF else aim_at)
	return true


## Is the grenade being aimed (X held long enough)?
func grenade_aiming() -> bool:
	return gr_hold >= 0 and gr_held >= GR_HOLD


## X let go: a tap switches to the next grenade, a hold throws the one in hand where it is aimed. A line for the screen.
func grenade_up() -> String:
	if gr_hold < 0:
		return ""
	var held := gr_held
	gr_hold = -1
	var g = GameState.gear
	if held < GR_HOLD:
		var nm: String = g.next_grenade()
		return ("%s in hand." % nm) if nm != "" else ""
	var p: Dictionary = g.grenade()
	if p.is_empty():
		return ""
	var id := String(p["id"])
	throw_grenade(null, gr_aim, id)
	p["n"] = int(p["n"]) - 1
	if int(p["n"]) <= 0:
		g.grenades[g.gr_sel] = {}
		g.next_grenade()
	return "%s thrown." % String(GearData.base(id)["name"])


func _clamp_throw(p: Vector2) -> Vector2:
	var d := p - pilot_pos()
	if d.length() > THROW_RANGE:
		d = d.normalized() * THROW_RANGE
	return pilot_pos() + d


## A grenade flies from `from` (null: you) to `at` and goes off where it lands.
func throw_grenade(from, at: Vector2, id: String) -> void:
	var w: Walker = view.pilot if from == null else from["w"]
	var a := w.pos + Vector2(0, -16)
	var life := clampf(a.distance_to(at) / 260.0, 0.45, 0.95)
	grenades.append({"a": a, "b": at, "t": 0.0, "life": life, "id": id, "from": from, "st": GearData.stats(id)})
	if from == null:
		GameState.gear.combat_t = maxf(GameState.gear.combat_t, 8.0)
		for f in alive():
			if not f["aware"] and f["w"].pos.distance_to(at) < FoeData.HEAR:
				_wake(f)
	Audio.play("ui_click", "grenade thrown", -4.0)


func _grenade_step(delta: float) -> void:
	for gr in grenades:
		gr["t"] = float(gr["t"]) + delta
		if float(gr["t"]) >= float(gr["life"]) and not gr.has("done"):
			gr["done"] = true
			_detonate(gr)
	grenades = grenades.filter(func(gr): return not gr.has("done"))
	for c in clouds:
		c["t"] = float(c["t"]) + delta
	clouds = clouds.filter(func(c): return float(c["t"]) < float(c["time"]))
	for dm in domes:
		dm["t"] = float(dm["t"]) + delta
	domes = domes.filter(func(dm): return float(dm["t"]) < float(dm["time"]))


func _detonate(gr: Dictionary) -> void:
	var at: Vector2 = gr["b"]
	var st: Dictionary = gr["st"]
	var from = gr["from"]
	var r := float(st.get("radius", 60.0))
	match String(gr["id"]):
		"gr_frag":
			var mult := float(from["dmg"]) / FoeData.DAMAGE * 0.25 if from != null else 1.0
			_explode(at, r, float(st.get("damage", 60.0)) * mult, "explosive", from)
		"gr_emp":
			booms.append({"pos": at, "r": r, "t": 0.0, "col": Color(0.45, 0.8, 1.0)})
			Audio.play("shield_down", "EMP grenade", -4.0)
			var sd := float(st.get("shield_damage", 90.0))
			if blast_share(at, pilot_pos(), r) > 0.0 and not Commands.suit_god:
				GameState.gear.shield = maxf(0.0, GameState.gear.shield - sd)
				GameState.gear.shield_wait = GearData.SHIELD_WAIT
				_number(pilot_pos(), {"shield": sd, "armor": 0.0, "health": 0.0})
			for f in alive():
				if blast_share(at, (f["w"] as Walker).pos, r) > 0.0:
					var had := float(f["st"]["shield"])
					f["st"]["shield"] = maxf(0.0, had - sd)
					f["regen_wait"] = GearData.SHIELD_WAIT
					_number((f["w"] as Walker).pos, {"shield": had - float(f["st"]["shield"]), "armor": 0.0, "health": 0.0})
					_wake(f)
		"gr_smoke":
			clouds.append({"pos": at, "r": r * 0.8, "t": 0.0, "time": float(st.get("time", 8.0)), "seed": randi() % 1000})
			Audio.play("undock_release", "smoke grenade", -8.0)
		"gr_shield":
			domes.append({"pos": at, "r": r * 0.75, "hp": float(st.get("shield", 120.0)), "mx": float(st.get("shield", 120.0)), "t": 0.0,
				"time": float(st.get("time", 10.0))})
			Audio.play("module_on", "shield grenade", -4.0)


## Does the line a → b pass through a smoke cloud?
func smoke_between(a: Vector2, b: Vector2) -> bool:
	for c in clouds:
		var cp: Vector2 = c["pos"]
		var q := Geometry2D.get_closest_point_to_segment(cp, a, b)
		if q.distance_to(cp) < float(c["r"]) * minf(1.0, float(c["t"]) * 3.0):
			return true
	return false


## The shield dome a shot from a to b runs into: one it crosses coming from outside (0.7.52.6: also on its way to a
## target beyond it); from inside fire goes out freely. Null if none.
func dome_between(a: Vector2, b: Vector2) -> Variant:
	for dm in domes:
		var cp: Vector2 = dm["pos"]
		if float(dm["hp"]) <= 0.0 or a.distance_to(cp) < float(dm["r"]):
			continue
		if Geometry2D.get_closest_point_to_segment(cp, a, b).distance_to(cp) < float(dm["r"]):
			return dm
	return null


func _draw_grenades() -> void:
	var font := ThemeDB.fallback_font
	# shield domes: a glassy blue dome over the ground with a hex edge and its strength
	for dm in domes:
		var c: Vector2 = (dm["pos"] as Vector2) * S
		var r := float(dm["r"]) * S
		var k := clampf(float(dm["hp"]) / maxf(float(dm["mx"]), 1.0), 0.0, 1.0)
		var fade := clampf((float(dm["time"]) - float(dm["t"])) / 0.5, 0.0, 1.0) * clampf(float(dm["t"]) / 0.25, 0.0, 1.0)
		draw_set_transform(c, 0.0, Vector2(1.0, 0.62))
		draw_circle(Vector2.ZERO, r, Color(0.35, 0.8, 1.0, 0.12 * fade))
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 6, Color(0.5, 0.95, 1.0, 0.6 * fade), 2.0)
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(0.5, 0.95, 1.0, 0.85 * fade), 3.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_arc(c + Vector2(0, -r * 0.1), r * 0.92, PI * 1.08, PI * 1.92, 32, Color(0.7, 1.0, 1.0, 0.45 * fade), 2.0)   # its top
		draw_rect(Rect2(c + Vector2(-30, -r * 0.62 - 14), Vector2(60, 4)), Color(0.05, 0.1, 0.15, 0.8 * fade))
		draw_rect(Rect2(c + Vector2(-30, -r * 0.62 - 14), Vector2(60 * k, 4)), Color(0.45, 0.9, 1.0, fade))
	# grenades in flight: an arc with a shadow below; theirs show where they will land
	for gr in grenades:
		var k2 := clampf(float(gr["t"]) / float(gr["life"]), 0.0, 1.0)
		var a: Vector2 = gr["a"]
		var b: Vector2 = gr["b"]
		var ground := a.lerp(b + Vector2(0, 0), k2) + Vector2(0, 16.0 * (1.0 - k2))
		var hp := (a.lerp(b, k2) - Vector2(0, sin(k2 * PI) * 40.0)) * S
		draw_set_transform(ground * S, 0.0, Vector2(1.0, 0.45))
		draw_circle(Vector2.ZERO, 5.0, Color(0, 0, 0, 0.3))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_circle(hp, 5.0, Color(0.05, 0.05, 0.06))
		draw_circle(hp, 3.5, {"gr_frag": Color(0.4, 0.42, 0.32), "gr_emp": Color(0.3, 0.6, 1.0), "gr_smoke": Color(0.6, 0.6, 0.6), "gr_shield": Color(0.4, 0.9, 1.0)}.get(String(gr["id"]), Color.GRAY))
		if fposmod(_t * 8.0, 1.0) < 0.5:
			draw_circle(hp + Vector2(0, -2), 1.5, Color(1.0, 0.3, 0.2))
		if gr["from"] != null:
			var rr := float((gr["st"] as Dictionary).get("radius", 60.0)) * S
			draw_set_transform(b * S, 0.0, Vector2(1.0, 0.55))
			draw_circle(Vector2.ZERO, rr, Color(1.0, 0.2, 0.15, 0.1 + 0.15 * k2))
			draw_arc(Vector2.ZERO, rr, 0.0, TAU, 40, Color(1.0, 0.25, 0.2, 0.5 + 0.5 * sin(_t * 18.0) * 0.5), 2.5)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# your aim while holding the key: the arc, where it lands, how far it reaches
	if grenade_aiming():
		var g = GameState.gear
		if not g.grenade().is_empty():
			var gid := String(g.grenade()["id"])
			var gst := GearData.stats(gid)
			var a2 := (pilot_pos() + Vector2(0, -16)) * S
			var b2 := gr_aim * S
			var prev := a2
			for i in range(1, 25):
				var t := i / 24.0
				var p := a2.lerp(b2, t) - Vector2(0, sin(t * PI) * 40.0 * S)
				if i % 2 == 0:
					draw_line(prev, p, Color(1.0, 0.6, 0.25, 0.9), 3.0)
				prev = p
			var rr2 := float(gst.get("radius", 60.0)) * S * (0.75 if gid == "gr_shield" else (0.8 if gid == "gr_smoke" else 1.0))
			draw_set_transform(b2, 0.0, Vector2(1.0, 0.55))
			draw_circle(Vector2.ZERO, rr2, Color(1.0, 0.45, 0.15, 0.12))
			draw_arc(Vector2.ZERO, rr2, 0.0, TAU, 48, Color(1.0, 0.55, 0.2, 0.9), 2.0)
			draw_set_transform(pilot_pos() * S, 0.0, Vector2(1.0, 0.55))
			draw_arc(Vector2.ZERO, THROW_RANGE * S, 0.0, TAU, 64, Color(1.0, 0.6, 0.25, 0.3), 1.5)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			_txt(b2 - Vector2(0, rr2 * 0.55 + 10), "%s – let go to throw" % String(gst["name"]), Color(1.0, 0.7, 0.35), 12)


## Smoke clouds drawn over the people (they hide in them): soft grey puffs that swell and thin out.
func _draw_clouds() -> void:
	for c in clouds:
		var k := clampf(float(c["t"]) * 3.0, 0.0, 1.0)
		var left := clampf((float(c["time"]) - float(c["t"])) / 1.5, 0.0, 1.0)
		var rng := RandomNumberGenerator.new()
		rng.seed = int(c["seed"])
		var cp: Vector2 = (c["pos"] as Vector2) * S
		var r := float(c["r"]) * S * k
		for i in 22:
			var off := Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)).limit_length(1.0) * r * 0.75
			off.y *= 0.6
			var drift := Vector2(sin(_t * 0.6 + i), cos(_t * 0.5 + i * 1.3)) * 6.0
			draw_circle(cp + off + drift - Vector2(0, 20), r * rng.randf_range(0.25, 0.4), Color(0.72, 0.72, 0.7, 0.16 * left))


# ---------------------------------------------------------------- effects

func _fx_step(delta: float) -> void:
	for s in shots:
		s["t"] = float(s["t"]) + delta
		if float(s["t"]) >= float(s["life"]):
			_resolve(s)
	shots = shots.filter(func(s): return float(s["t"]) < float(s["life"]) + (0.06 if s["kind"] == "beam" else 0.0))
	for fl in floaters:
		fl["t"] = float(fl["t"]) + delta
	floaters = floaters.filter(func(fl): return float(fl["t"]) < 1.1)
	for sp in sparks:
		sp["t"] = float(sp["t"]) + delta
		sp["pos"] = (sp["pos"] as Vector2) + (sp["vel"] as Vector2) * delta
		sp["vel"] = (sp["vel"] as Vector2) + Vector2(0, 220) * delta
	sparks = sparks.filter(func(sp): return float(sp["t"]) < 0.35)
	for b in booms:
		b["t"] = float(b["t"]) + delta
	booms = booms.filter(func(b): return float(b["t"]) < 0.5)
	for tr in trail:
		tr["t"] = float(tr["t"]) - delta
	trail = trail.filter(func(tr): return float(tr["t"]) > 0.0)


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var red := Color(1.0, 0.3, 0.3)
	_draw_grenades()
	# 0.7.52.5: a sniper's red aiming line in the last moment before its shot – your cue to dodge
	for sf in alive():
		if String(sf["role"]) == "sniper" and sf["aware"] and float(sf["cool"]) < 0.9 and sf["state"] != "flee":
			var sw: Walker = sf["w"]
			if not sight(sw.pos, pilot_pos())["blocked"] and sw.aim != Vector2.INF:
				var k0 := 1.0 - clampf(float(sf["cool"]) / 0.9, 0.0, 1.0)
				var m0 := sw.muzzle_art() * S
				draw_line(m0, (pilot_pos() + CHEST) * S, Color(1.0, 0.15, 0.1, 0.25 + 0.55 * k0), 1.0 + 1.5 * k0)
				draw_circle((pilot_pos() + CHEST) * S, 3.0 + 3.0 * k0, Color(1.0, 0.2, 0.15, 0.4 + 0.5 * k0))
	# the dodge's after-images
	for tr in trail:
		var k: float = float(tr["t"]) / 0.25
		draw_set_transform((tr["p"] as Vector2) * S + Vector2(0, -3), 0.0, Vector2(1.0, 0.45))
		draw_circle(Vector2.ZERO, 14.0, Color(0.5, 1.0, 0.7, 0.25 * k))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_line((tr["p"] as Vector2) * S + Vector2(0, -60), (tr["p"] as Vector2) * S + Vector2(0, -6), Color(0.5, 1.0, 0.7, 0.35 * k), 10.0)
	# the cover ring: a green half-ring on the side the fire comes from
	if fight and in_cover > 0:
		var c := Vector2.ZERO
		for f in alive():
			if f["aware"]:
				c += ((f["w"] as Walker).pos - pilot_pos()).normalized()
		var ang := c.angle() if c.length() > 0.01 else 0.0
		var col := Color(0.4, 1.0, 0.55, 0.9) if in_cover == 2 else Color(0.85, 1.0, 0.4, 0.8)
		draw_set_transform(pilot_pos() * S + Vector2(0, -3), 0.0, Vector2(1.0, 0.45))
		draw_arc(Vector2.ZERO, 40.0, ang - PI * 0.42, ang + PI * 0.42, 24, col, 4.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# 0.7.52.9 (Luz): small shield and health bars right over each foe's head
	for hf in alive():
		var hw: Walker = hf["w"]
		var top := hw.pos * S + Vector2(-14, -ChibiArt.H * ChibiArt.CHAR_SCALE - 10)
		var hst: Dictionary = hf["st"]
		var hmx: Dictionary = hf["mx"]
		draw_rect(Rect2(top - Vector2(1, 1), Vector2(30, 7)), Color(0, 0, 0, 0.65))
		if float(hmx["shield"]) > 0.0:
			draw_rect(Rect2(top, Vector2(28.0 * clampf(float(hst["shield"]) / float(hmx["shield"]), 0.0, 1.0), 2)), Color(0.45, 0.8, 1.0))
		var hk := clampf((float(hst["armor"]) + float(hst["health"])) / maxf(float(hmx["armor"]) + float(hmx["health"]), 1.0), 0.0, 1.0)
		draw_rect(Rect2(top + Vector2(0, 3), Vector2(28.0 * hk, 2)), Color(1.0, 0.35, 0.3) if hk < 0.35 else Color(0.95, 0.55, 0.35))
	# lock brackets, red (the active one thick), the lock arc while locking, T1–T3, the hit chance under the active
	for i in locks.size():
		var f = locks[i]
		var cpos: Vector2 = ((f["w"] as Walker).pos + Vector2(0, -14)) * S
		var act: bool = f == active
		var col2 := red if act else Color(red, 0.6)
		var r := Vector2(30, 50)
		var wd := 3.0 if act else 1.5
		for sx in [-1.0, 1.0]:
			for sy in [-1.0, 1.0]:
				var corner := cpos + Vector2(sx * r.x, sy * r.y)
				draw_line(corner, corner - Vector2(sx * 9.0, 0), col2, wd)
				draw_line(corner, corner - Vector2(0, sy * 9.0), col2, wd)
		draw_string(font, cpos + Vector2(r.x + 4, -r.y + 4), "T%d" % (i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, col2)
		if act and lock_t > 0.0:
			var full := GearData.LOCK_TIME * (1.0 - 0.04 * GameState.skill_level("firearms"))
			draw_arc(cpos, 62.0, -PI / 2, -PI / 2 + TAU * (1.0 - lock_t / maxf(full, 0.01)), 32, col2, 2.0)
		if act:
			_txt(cpos + Vector2(0, r.y + 20), "hit %d%%" % int(round(chance_at_foe(f) * 100.0)), col2, 12)
	# shots
	for s in shots:
		var a: Vector2 = (s["a"] as Vector2) * S
		var b: Vector2 = (s["b"] as Vector2) * S
		var col3: Color = s["col"]
		match String(s["kind"]):
			"beam":
				var fade := 1.0 - clampf((float(s["t"]) - float(s["life"])) / 0.06, 0.0, 1.0) if float(s["t"]) > float(s["life"]) else 1.0
				draw_line(a, b, Color(col3, 0.25 * fade), 9.0)
				draw_line(a, b, Color(col3, 0.9 * fade), 3.0)
				draw_line(a, b, Color(1, 1, 1, fade), 1.0)
				draw_circle(a, 6.0, Color(col3, 0.8 * fade))
			"slug":
				var k := clampf(float(s["t"]) / float(s["life"]), 0.0, 1.0)
				var head := a.lerp(b, k)
				draw_line(a.lerp(b, maxf(0.0, k - 0.12)), head, Color(col3, 0.85), 3.0)
				draw_circle(head, 2.5, Color(1, 1, 0.85))
				if float(s["t"]) < 0.05:
					draw_circle(a, 6.0, Color(1.0, 0.8, 0.3, 0.9))
			"shell":
				var k2 := clampf(float(s["t"]) / float(s["life"]), 0.0, 1.0)
				var hp := a.lerp(b, k2) - Vector2(0, sin(k2 * PI) * 60.0)
				draw_circle(hp, 5.0, Color(0.1, 0.1, 0.1))
				draw_circle(hp, 3.0, col3)
	for sp in sparks:
		var pp2: Vector2 = (sp["pos"] as Vector2) * S
		draw_line(pp2, pp2 - (sp["vel"] as Vector2) * 0.04 * S, Color(sp.get("col", Color(1.0, 0.8, 0.35)), 1.0 - float(sp["t"]) / 0.35), 2.0)
	for bm in booms:
		var k3: float = float(bm["t"]) / 0.5
		draw_set_transform((bm["pos"] as Vector2) * S, 0.0, Vector2(1.0, 0.55))
		var bc: Color = bm.get("col", Color(1.0, 0.55, 0.15))
		draw_circle(Vector2.ZERO, float(bm["r"]) * S * (0.4 + k3 * 0.6), Color(bc, 0.45 * (1.0 - k3)))
		draw_arc(Vector2.ZERO, float(bm["r"]) * S * (0.4 + k3 * 0.6), 0, TAU, 40, Color(bc.lightened(0.3), 1.0 - k3), 3.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for fl in floaters:
		var k4: float = float(fl["t"]) / 1.1
		_txt((fl["pos"] as Vector2) * S + Vector2(0, -k4 * 40.0), String(fl["text"]), Color(fl["col"], 1.0 - k4 * k4), 16 if String(fl["text"]).is_valid_int() else 12)
	_draw_clouds()
	if show_ai:
		_draw_ai(font)


func _txt(p: Vector2, t: String, col: Color, sz: int = 13) -> void:
	var font := ThemeDB.fallback_font
	var wdt := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	draw_string_outline(font, p - Vector2(wdt * 0.5, 0), t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, 4, Color(0, 0, 0, col.a * 0.85))
	draw_string(font, p - Vector2(wdt * 0.5, 0), t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


## Debug: low cover (amber) and high cover (red) tiles, each foe's state, goal, line of sight and chances.
func _draw_ai(_font: Font) -> void:
	var T := GroundMap.TILE * S
	for y in map.h:
		for x in map.w:
			var c := cover[y * map.w + x]
			if c == 1:
				draw_rect(Rect2(Vector2(x, y) * T, Vector2(T, T)), Color(1.0, 0.75, 0.2, 0.18))
			elif c == 2 and (x > 0 and y > 0 and x < map.w - 1 and y < map.h - 1):
				draw_rect(Rect2(Vector2(x, y) * T, Vector2(T, T)), Color(1.0, 0.2, 0.2, 0.1))
	for f in foes:
		var w: Walker = f["w"]
		var p := w.pos * S
		if not f["dead"]:
			var sg := sight(w.pos, pilot_pos())
			draw_line(p + CHEST * S, (pilot_pos() + CHEST) * S, Color(1, 0.3, 0.3, 0.35) if sg["blocked"] else (Color(1, 0.85, 0.3, 0.5) if sg["cover"] else Color(0.5, 1, 0.5, 0.4)), 1.5)
			if f["goal"] != Vector2.INF:
				draw_line(p, (f["goal"] as Vector2) * S, Color(0.4, 0.8, 1.0, 0.6), 1.5)
				draw_circle((f["goal"] as Vector2) * S, 6.0, Color(0.4, 0.8, 1.0, 0.7))
		var st: Dictionary = f["st"]
		_txt(p + Vector2(0, 24), "%s%s  S%d A%d H%d" % [String(f["state"]), "" if f["aware"] else " (unaware)", int(st["shield"]), int(st["armor"]), int(st["health"])], Color(0.8, 0.95, 1.0), 11)
		if not f["dead"]:
			_txt(p + Vector2(0, 38), "you hit %d%%  •  it hits %d%%" % [int(chance_at_foe(f) * 100.0), int(chance_at_pilot(f) * 100.0)], Color(0.8, 0.95, 1.0), 11)
