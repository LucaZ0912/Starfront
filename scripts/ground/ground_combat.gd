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


func setup(p_view, p_map: GroundMap) -> void:
	view = p_view
	map = p_map
	z_index = 40
	_build_cover()
	dodge_charges = float(max_dodges())


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

## A foe of a kind at p (art px); quality "" = the kind's own. Returns its dict.
func spawn(kind: String, p: Vector2, quality: String = "") -> Dictionary:
	var d: Dictionary = FoeData.FOES.get(kind, FoeData.FOES["bandit_rifleman"])
	var q := quality if quality != "" else String(d["quality"])
	var suit := GearData.stats(FoeData.suit_id(kind, q))
	var lk: Dictionary = ChibiArt.PilotArt.random_look()
	lk["outfit"] = 2
	lk["color1"] = int(d["c1"])
	lk["color2"] = int(d["c2"])
	lk["suit"] = String(d["suit"])
	lk["helmet"] = bool(d["helmet"]) or (view.needs_helmet() if view != null else false)
	lk["headgear"] = 1 if not bool(d["helmet"]) else 0
	var w := Walker.new()
	w.setup(map, lk, p, true)
	w.stays = true
	w.dir = 0
	var wid := FoeData.weapon_id(kind, q)
	w.slung = String(GearData.base(wid).get("dtype", "kinetic"))
	w.aim_dtype = w.slung
	view._sorted.add_child(w)
	var f := {"id": _next_id, "w": w, "kind": kind, "name": String(d["name"]), "weapon": wid, "quality": q,
		"st": {"shield": float(suit.get("shield", 0.0)), "armor": float(suit.get("armor", 0.0)), "health": GearData.HEALTH},
		"mx": {"shield": float(suit.get("shield", 0.0)), "armor": float(suit.get("armor", 0.0)), "health": GearData.HEALTH},
		"cool": randf_range(0.3, 1.0), "state": "idle", "aware": false, "goal": Vector2.INF, "path": PackedVector2Array(), "pi": 0,
		"think": randf_range(0.0, 0.5), "regen_wait": 0.0, "role": String(d["role"]), "flee": float(d["flee"]),
		"firearms": int(d["firearms"]), "athletics": int(d["athletics"]), "out_t": 0.0, "home": p, "dead": false, "burst": 0}
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
	return GearData.hit_chance(GearData.stats(wid), GameState.skill_level("firearms"), a.distance_to(b), sg["cover"], (f["w"] as Walker).moving, int(f["athletics"]), false)


func chance_at_pilot(f) -> float:
	var a: Vector2 = (f["w"] as Walker).pos
	var b := pilot_pos()
	var sg := sight(a, b)
	if sg["blocked"]:
		return 0.0
	return GearData.hit_chance(GearData.stats(String(f["weapon"])), int(f["firearms"]), a.distance_to(b), sg["cover"], view.pilot.moving, GameState.skill_level("athletics"), GameState.gear.stim_t > 0.0)


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
	# the weapon in the hands while fighting, facing the target when standing
	var wid := weapon_id()
	if fight and active != null and wid != "":
		view.pilot.aim = (active["w"] as Walker).pos
		view.pilot.aim_dtype = String(GearData.base(wid).get("dtype", "kinetic"))
		if not view.pilot.moving and dodge_t <= 0.0:
			view.pilot.dir = _face((active["w"] as Walker).pos - pilot_pos())
	else:
		view.pilot.aim = Vector2.INF
	_fx_step(delta)
	queue_redraw()


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
	var open_chance := chance / (1.0 - GearData.COVER_CUT) if sg["cover"] else chance
	var dtype := String(w.get("dtype", "kinetic"))
	var col: Color = {"optical": Color(0.55, 0.95, 1.0), "kinetic": Color(1.0, 0.85, 0.4), "explosive": Color(1.0, 0.55, 0.2)}.get(dtype, Color.WHITE)
	var pellets := int(w.get("pellets", 1))
	var muzzle := a + CHEST + Vector2(5.0 if b.x >= a.x else -5.0, 0.0)
	for i in pellets:
		var r := randf()
		var res := {"to": to, "dmg": float(w["damage"]) * (FoeData.DAMAGE if from != null else 1.0), "dtype": dtype, "splash": float(w.get("splash", 0.0)), "from": from}
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
		"miss":
			if to != null and res["from"] == null and not floaters.any(func(fl): return String(fl["text"]) == "miss" and float(fl["t"]) < 0.4):
				floaters.append({"pos": (to["w"] as Walker).pos + Vector2(0, -34), "text": "miss", "col": Color(0.75, 0.75, 0.72), "t": 0.0})


func _explode(at: Vector2, r: float, dmg: float, dtype: String, from) -> void:
	booms.append({"pos": at, "r": r, "t": 0.0})
	Audio.play("explosion_small", "shell on foot", -4.0)
	view._shake = 0.25
	if at.distance_to(pilot_pos()) < r:
		_hurt_pilot(dmg * (1.0 - at.distance_to(pilot_pos()) / r * 0.6), dtype)
	for f in alive():
		var dd: float = at.distance_to((f["w"] as Walker).pos)
		if dd < r:
			_hurt_foe(f, dmg * (1.0 - dd / r * 0.6), dtype)


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
		if dist < FoeData.SIGHT and not sg["blocked"]:
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
	# running away when badly hurt
	if f["state"] != "flee" and float(st["health"]) < float(f["flee"]) * GearData.HEALTH:
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
		var base := 1.0 / float(wst["rof"])
		if String(f["role"]) == "gunner":
			f["burst"] = int(f["burst"]) + 1
			f["cool"] = base if int(f["burst"]) % 6 != 0 else base + 1.6          # bursts of six
		else:
			f["cool"] = base * randf_range(1.0, 1.5) + (0.3 if w.moving else 0.0)


## What to do next: stay in good cover, find new cover facing you, or (scatter guns) close in.
func _decide(f: Dictionary, dist: float, sg: Dictionary, reach: float) -> void:
	var w: Walker = f["w"]
	var pp := pilot_pos()
	var role := String(f["role"])
	if role == "rusher":
		var want := reach * 0.45
		if dist > want or sg["blocked"]:
			var tgt := pp + (w.pos - pp).normalized().rotated(randf_range(-0.6, 0.6)) * want * 0.8
			_go(f, _free_near(tgt), "move")
		elif f["goal"] == Vector2.INF and randf() < 0.5:
			# strafing about close in
			_go(f, _free_near(w.pos + (pp - w.pos).normalized().rotated(PI * 0.5 * (1.0 if randf() < 0.5 else -1.0)) * 28.0), "fight")
		return
	# riflemen, gunners, the boss: cover between them and you
	var covered: bool = sight(pp, w.pos)["cover"]
	var good: bool = covered and not sg["blocked"] and dist <= reach * 0.95
	if good and f["goal"] == Vector2.INF:
		f["state"] = "cover"
		return
	if f["goal"] != Vector2.INF and f["state"] == "move":
		return                                        # on the way
	var spot := _cover_spot(w.pos, pp, reach, 0.75 if role == "boss" else 0.6)
	if spot != Vector2.INF:
		_go(f, spot, "move")
	elif dist > reach * 0.9 or sg["blocked"]:
		_go(f, _free_near(pp + (w.pos - pp).normalized() * reach * 0.6), "move")
	else:
		f["state"] = "fight"


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
func _cover_spot(p: Vector2, pp: Vector2, reach: float, pref: float) -> Vector2:
	var best := Vector2.INF
	var bs := INF
	var tx := int(p.x / GroundMap.TILE)
	var ty := int(p.y / GroundMap.TILE)
	for yy in range(ty - 8, ty + 9):
		for xx in range(tx - 8, tx + 9):
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
		draw_line(pp2, pp2 - (sp["vel"] as Vector2) * 0.04 * S, Color(1.0, 0.8, 0.35, 1.0 - float(sp["t"]) / 0.35), 2.0)
	for bm in booms:
		var k3: float = float(bm["t"]) / 0.5
		draw_set_transform((bm["pos"] as Vector2) * S, 0.0, Vector2(1.0, 0.55))
		draw_circle(Vector2.ZERO, float(bm["r"]) * S * (0.4 + k3 * 0.6), Color(1.0, 0.55, 0.15, 0.45 * (1.0 - k3)))
		draw_arc(Vector2.ZERO, float(bm["r"]) * S * (0.4 + k3 * 0.6), 0, TAU, 40, Color(1.0, 0.8, 0.4, 1.0 - k3), 3.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for fl in floaters:
		var k4: float = float(fl["t"]) / 1.1
		_txt((fl["pos"] as Vector2) * S + Vector2(0, -k4 * 40.0), String(fl["text"]), Color(fl["col"], 1.0 - k4 * k4), 16 if String(fl["text"]).is_valid_int() else 12)
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
