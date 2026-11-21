extends Node2D
## Package 58, part 8 (Luz, 20 Nov 2026): the Red Talon Roost – the pirates' station as a boss. Built of parts, each a
## ship that never moves (anchored) and is drawn by the station: the hull (a great ring round a hub), four gun
## platforms and two hangars with bars of their own, the reactor core under its plating. Every hit on any part lowers
## the station's own bar; at a quarter the plating blows off, the core lies open and the last wave comes; the core gone,
## the chain reaction and the great explosion. While no pirates are out, the hangars still standing send new ones.
## No class_name: preload it.

signal event(what: String, arg)          # "platform_down" (n left), "hangar_down" (n left), "wave" (n), "core_open", "dying", "dead"

const NAME := "Red Talon Roost"
const HP := 42000.0                      # the station's bar (every hit on any part counts)
const CORE_AT := 0.25                    # the plating gives at a quarter
const PLATFORM_AT := [Vector2(-470, -330), Vector2(470, -330), Vector2(-470, 330), Vector2(470, 330)]
const HANGAR_AT := [Vector2(0, -470), Vector2(0, 470)]
const K := 1.8                           # the whole station drawn this much bigger (parts, wrecks, offsets)
const RUST := Color(0.36, 0.17, 0.13)
const METAL := Color(0.24, 0.24, 0.27)
const DARK := Color(0.1, 0.1, 0.12)
const RED := Color(1.0, 0.25, 0.2)

var view                                 # SystemView
var quick := false                       # the smoke test: waits short
var pool := HP
var core_open := false
var dead := false
var parts := {}                          # id -> Ship ("hull", "core", "platform_<i>", "hangar_<i>")
var gone := {}                           # id -> true: destroyed (drawn as a wreck by the station)
var pirates: Array = []                  # the ships it launched that are still out
var waves := 0
var hope = null                          # Silas's Stubborn Hope: while she is near, the guns are jammed
var _wave_t := 4.0
var _jam_t := 0.0
var _t := 0.0
var _boom := -1.0                        # the chain reaction under way (s)
var _bar: CanvasLayer = null
var _bar_ui = null


func setup(p_view, at: Vector2) -> void:
	view = p_view
	position = at
	z_index = -1
	scale = Vector2(K, K)
	view.add_child(self)
	_make("hull", Vector2.ZERO, 330.0)
	_make("core", Vector2.ZERO, 95.0)
	for i in PLATFORM_AT.size():
		_make("platform_%d" % i, PLATFORM_AT[i], 70.0)
	for i in HANGAR_AT.size():
		_make("hangar_%d" % i, HANGAR_AT[i], 110.0)


## A part: a pirate ship anchored where it stands, drawn by the station; its hits count for the station's bar.
func _make(id: String, off: Vector2, r: float) -> void:
	var gun: bool = id.begins_with("platform")
	var s: Ship = view.spawn_npc("pirate_hdy_maul", position + off * K, "pirate")
	s.bounty = 0
	s.archetype = ""
	s.fit.gov = ""                               # (a part of a station: no standing lost over it)
	s.anchored = true
	s.radius = r * K
	s.scale = Vector2(K, K)
	s.heading = -PI * 0.5
	s.art_draw = _draw_part.bind(id)
	s.damage_hook = _on_hit.bind(id)
	s.set_meta("roost_part", id)
	if not gun:
		# the hull, the core and the hangars carry no guns of their own (the platforms do the shooting)
		for k in s.fit.modules.keys():
			var stp := ShipFitting.slot_type(String(k))
			if stp in ["weapon", "dweapon", "dtool", "dbonus"]:
				s.fit.modules.erase(k)
		s.fit.drones.clear()
		s.fit.mark_dirty()
		s.fit.stance = "passive"
	else:
		s.fit.stance = "aggressive"
		s.ignore_drones = true                   # (Luz) the guns go for the ships, not the drones
	if id in ["hull", "core"]:
		s.story_spare = true                     # (only the station's bar decides when they go)
	if id == "core":
		s.untargetable = true                    # under its plating until a quarter
		s.z_index = 1
	elif id == "hull":
		s.z_index = -1
	match id.get_slice("_", 0):
		"hull":
			s.fit.ship_name = "Red Talon Roost"
		"core":
			s.fit.ship_name = "Roost reactor core"
		"platform":
			s.fit.ship_name = "Gun platform %d" % (int(id.get_slice("_", 1)) + 1)
			s.toughness = 0.85                   # (Luz: the shields were too strong)
		"hangar":
			s.fit.ship_name = "Hangar %s" % ("north" if id == "hangar_0" else "south")
			s.toughness = 0.7
	s.fit.refill()
	s.destroyed.connect(_on_part_destroyed.bind(id))
	parts[id] = s


func part(id: String):
	var s = parts.get(id, null)
	return s if s != null and is_instance_valid(s) and not s.dying else null


func platforms_left() -> int:
	var n := 0
	for i in PLATFORM_AT.size():
		if part("platform_%d" % i) != null:
			n += 1
	return n


func hangars_left() -> int:
	var n := 0
	for i in HANGAR_AT.size():
		if part("hangar_%d" % i) != null:
			n += 1
	return n


func share() -> float:
	return clampf(pool / HP, 0.0, 1.0)


## Every hit on a part: the station's bar goes down by what the part lost. The hull and the core never run dry
## themselves (they are refilled); below a quarter only the core and what still stands count.
func _on_hit(s, lost: float, id: String) -> void:
	if dead or lost <= 0.0:
		return
	if id == "hull" and core_open:
		lost = 0.0
	pool -= lost
	if not core_open and pool <= HP * CORE_AT:
		pool = HP * CORE_AT
		_open_core()
	if id in ["hull", "core"] and is_instance_valid(s):
		s.fit.refill()
	if pool <= 0.0 and _boom < 0.0:
		pool = 0.0
		_start_boom()


func _on_part_destroyed(_s, id: String) -> void:
	if dead:
		return
	gone[id] = true
	view.spawn_fx(Fx.explosion(position + _off(id) * K, 220.0 * K, Color(1.0, 0.6, 0.3)))
	view.spawn_fx(Fx.flash(position + _off(id) * K, Color(1.0, 0.7, 0.4), 400.0 * K))
	Audio.play_at("explosion_large", position + _off(id) * K, "Roost part destroyed")
	if id.begins_with("platform"):
		event.emit("platform_down", platforms_left())
	elif id.begins_with("hangar"):
		event.emit("hangar_down", hangars_left())


func _off(id: String) -> Vector2:
	if id.begins_with("platform"):
		return PLATFORM_AT[int(id.get_slice("_", 1))]
	if id.begins_with("hangar"):
		return HANGAR_AT[int(id.get_slice("_", 1))]
	return Vector2.ZERO


## A quarter left: the plating blows off – the core lies open, the hull no longer counts; the last, big wave.
func _open_core() -> void:
	core_open = true
	var h = part("hull")
	if h != null:
		h.untargetable = true
	var c = part("core")
	if c != null:
		c.untargetable = false
	for k in 8:
		var a := k * TAU / 8.0
		view.spawn_fx(Fx.explosion(position + Vector2.from_angle(a) * 120.0 * K, 90.0 * K, Color(1.0, 0.7, 0.35)))
	view.spawn_fx(Fx.pulse(position, 600.0 * K, Color(1.0, 0.6, 0.3)))
	if view.has_method("shake"):
		view.shake(0.6, 8.0)
	Audio.play_at("explosion_large", position, "the Roost's plating blows")
	_wave(true)
	event.emit("core_open", null)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if dead or view == null:
		return
	if _boom >= 0.0:
		_boom_step(delta)
		return
	pirates = pirates.filter(func(p): return p != null and is_instance_valid(p) and not p.dying)
	# new pirates while none are out – from the hangars still standing (the last wave came with the open core)
	if pirates.is_empty() and hangars_left() > 0:
		_wave_t -= delta
		if _wave_t <= 0.0:
			_wave(false)
	# Silas jams the guns while the Hope is near
	_jam_t -= delta
	if _jam_t <= 0.0:
		_jam_t = 1.0
		if hope != null and is_instance_valid(hope) and not hope.dying and hope.position.distance_to(position) < 40000.0:
			for i in PLATFORM_AT.size():
				var p = part("platform_%d" % i)
				if p != null:
					p.jam(1.5)
	_update_bar()


## A wave: light pirates from a hangar (every second wave with a Maul); the last one, big, from all round.
const MAX_ALIVE := 13                  # the Roost's fighters alive at once (Luz, 0.8.58.7: 40+ of them cost the frame rate)


func _wave(last: bool) -> void:
	_wave_t = 9.0 * (0.1 if quick else 1.0)
	waves += 1
	var n := 6 if last else mini(3 + waves / 2, 5)
	# (Luz: the frame rate) no more than MAX_ALIVE of them at once: a wave only fills up to it
	pirates = pirates.filter(func(p0): return p0 != null and is_instance_valid(p0) and not p0.dying)
	var room := (MAX_ALIVE + (4 if last else 0)) - pirates.size()
	if room <= 0:
		event.emit("wave", waves)
		return
	var from: Array = []
	for i in HANGAR_AT.size():
		if part("hangar_%d" % i) != null:
			from.append(HANGAR_AT[i])
	if from.is_empty() or last:
		from = [Vector2(0, -600), Vector2(0, 600), Vector2(-600, 0), Vector2(600, 0)]
	for k in mini(n + (2 if last else (1 if waves % 2 == 0 else 0)), room):
		var heavy: bool = k >= n or (k == room - 1 and (last or waves % 2 == 0))      # (the Maul comes even when the wave is cut short)
		var o: Vector2 = from[k % from.size()]
		var at: Vector2 = position + o * K + o.normalized() * randf_range(250.0, 700.0) + Vector2(randf_range(-300, 300), randf_range(-300, 300))
		var p: Ship = view.spawn_npc("pirate_hdy_maul" if heavy else _light_pirate(), at, "pirate")
		p.home = position
		p.bounty = 0
		p.fit.stance = "aggressive"
		view.spawn_fx(Fx.flash(p.position, Color(1.0, 0.4, 0.3), p.radius * 3.0))
		pirates.append(p)
	event.emit("wave", waves)


func _light_pirate() -> String:
	var A = load("res://data/pirate_archetypes.gd")
	var arch: String = String(A.pick(1.0)[0])
	var pr: Array = A.ARCHETYPES[arch]["presets"]
	return String(pr[randi() % mini(2, pr.size())])


# ---------------------------------------------------------------- the end

const BOOM_TIME := 4.5


func _start_boom() -> void:
	_boom = 0.0
	event.emit("dying", null)
	for id in parts:
		var s = part(id)
		if s != null:
			s.untargetable = true
			s.fit.stance = "passive"
			s.target = null


func _boom_step(delta: float) -> void:
	_boom += delta * (8.0 if quick else 1.0)
	# the chain: explosions running over the parts, faster and faster
	if randf() < delta * lerpf(4.0, 22.0, clampf(_boom / BOOM_TIME, 0.0, 1.0)) * (8.0 if quick else 1.0):
		var o := Vector2.from_angle(randf() * TAU) * randf_range(0.0, 520.0) * K
		view.spawn_fx(Fx.explosion(position + o, randf_range(90.0, 220.0) * K, Color(1.0, randf_range(0.45, 0.75), 0.3)))
		if randf() < 0.3:
			Audio.play_at("explosion_large", position + o, "the Roost: chain reaction")
	if _boom >= BOOM_TIME:
		_final_blast()


## The great explosion: a white flash over everything, a ring of fire, the parts gone, debris left drifting.
func _final_blast() -> void:
	dead = true
	_boom = -1.0
	view.spawn_fx(Fx.flash(position, Color(1.0, 0.95, 0.85), 4200.0))
	view.spawn_fx(Fx.explosion(position, 1400.0, Color(1.0, 0.65, 0.3)))
	view.spawn_fx(Fx.pulse(position, 3600.0, Color(1.0, 0.75, 0.4)))
	view.spawn_fx(Fx.pulse(position, 2200.0, Color(1.0, 0.5, 0.25)))
	if view.has_method("shake"):
		view.shake(1.6, 22.0)
	Audio.play("explosion_large", "the Roost goes up", 4.0)
	for id in parts:
		var s = parts[id]
		if s != null and is_instance_valid(s):
			s.queue_free()
	parts.clear()
	_debris.clear()
	for k in 26:
		_debris.append({"p": Vector2.from_angle(randf() * TAU) * randf_range(40.0, 300.0), "v": Vector2.from_angle(randf() * TAU) * randf_range(30.0, 140.0),
			"r": randf_range(14.0, 46.0), "a": randf() * TAU, "w": randf_range(-1.2, 1.2)})
	# the pirates still out break and run
	for p in pirates:
		if p != null and is_instance_valid(p) and not p.dying:
			p.fit.stance = "passive"
			p.target = null
			p.set_order({"type": "move", "pos": p.position + (p.position - position).normalized() * 60000.0})
	_show_bar(false)
	event.emit("dead", null)


var _debris: Array = []


# ---------------------------------------------------------------- drawing

## The station seen from above, under the ships: what is destroyed lies as a wreck; after the end, drifting debris.
func _draw() -> void:
	if dead:
		for d in _debris:
			d["p"] = (d["p"] as Vector2) + (d["v"] as Vector2) * get_process_delta_time()
			d["a"] = float(d["a"]) + float(d["w"]) * get_process_delta_time()
			var r := float(d["r"])
			var pts := PackedVector2Array()
			for i in 5:
				pts.append((d["p"] as Vector2) + Vector2.from_angle(float(d["a"]) + i * TAU / 5.0 + (0.4 if i % 2 == 0 else 0.0)) * r * (0.6 if i % 2 == 0 else 1.0))
			draw_colored_polygon(pts, Color(0.18, 0.12, 0.1, 0.95))
			draw_circle(d["p"], r * 0.25, Color(1.0, 0.5, 0.2, 0.25 + 0.2 * sin(_t * 6.0 + r)))
		return
	for id in gone:
		var o := _off(id)
		if id.begins_with("platform"):
			_wreck_rect(o, Vector2(110, 110), PI * 0.25)
		elif id.begins_with("hangar"):
			_wreck_rect(o, Vector2(250, 140), 0.0)


func _wreck_rect(o: Vector2, size: Vector2, rot: float) -> void:
	draw_set_transform(o, rot, Vector2.ONE)
	var r := Rect2(-size * 0.5, size)
	draw_rect(r, Color(0.13, 0.1, 0.09))
	draw_rect(r.grow(-12.0), Color(0.07, 0.06, 0.06))
	for k in 4:
		var a := Vector2(-size.x * 0.4 + k * size.x * 0.27, -size.y * 0.3 + (k % 2) * size.y * 0.5)
		draw_circle(a, 10.0 + 4.0 * sin(_t * 5.0 + k), Color(1.0, 0.45, 0.15, 0.35))
		draw_line(a, a + Vector2(18, -26), Color(0.2, 0.2, 0.22, 0.5), 6.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## One part, drawn on its ship (local: the part's centre).
func _draw_part(s, id: String) -> void:
	var hurt := 1.0 - share()
	match id.get_slice("_", 0):
		"hull":
			_draw_hull(s, hurt)
		"core":
			_draw_core(s)
		"platform":
			_draw_platform(s, id)
		"hangar":
			_draw_hangar(s, id)


func _draw_hull(s, hurt: float) -> void:
	# the arms out to the platforms and the hangars
	for i in PLATFORM_AT.size():
		var o: Vector2 = PLATFORM_AT[i]
		s.draw_line(Vector2.ZERO, o * 0.86, DARK, 48.0)
		s.draw_line(Vector2.ZERO, o * 0.86, METAL, 34.0)
		s.draw_line(Vector2.ZERO, o * 0.86, RUST.darkened(0.2), 10.0)
	for i in HANGAR_AT.size():
		var o2: Vector2 = HANGAR_AT[i]
		s.draw_line(Vector2.ZERO, o2 * 0.8, DARK, 78.0)
		s.draw_line(Vector2.ZERO, o2 * 0.8, METAL.darkened(0.1), 62.0)
	# the great ring
	s.draw_arc(Vector2.ZERO, 300.0, 0.0, TAU, 96, DARK, 86.0)
	s.draw_arc(Vector2.ZERO, 300.0, 0.0, TAU, 96, RUST, 66.0)
	s.draw_arc(Vector2.ZERO, 300.0, 0.0, TAU, 96, RUST.lightened(0.15), 8.0)
	for k in 24:
		var a := k * TAU / 24.0
		var p := Vector2.from_angle(a) * 300.0
		s.draw_set_transform(p, a, Vector2.ONE)
		s.draw_rect(Rect2(-14, -26, 28, 52), METAL if k % 3 != 0 else METAL.darkened(0.3))
		s.draw_rect(Rect2(-14, -26, 28, 52), DARK, false, 2.0)
		s.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if k % 2 == 0:
			s.draw_circle(Vector2.from_angle(a) * 344.0, 5.0, RED if fposmod(_t + k * 0.13, 1.0) < 0.5 else RED.darkened(0.6))
	# the hub round the core
	s.draw_circle(Vector2.ZERO, 175.0, DARK)
	s.draw_circle(Vector2.ZERO, 160.0, METAL.darkened(0.15))
	for k2 in 6:
		var a2 := k2 * TAU / 6.0 + 0.26
		s.draw_line(Vector2.from_angle(a2) * 110.0, Vector2.from_angle(a2) * 160.0, DARK, 6.0)
	s.draw_arc(Vector2.ZERO, 120.0, 0.0, TAU, 48, RUST.darkened(0.3), 10.0)
	# the Red Talon's claw marks in red
	for c in 3:
		var a3 := -PI * 0.5 + (c - 1) * 0.16
		s.draw_line(Vector2.from_angle(a3) * 230.0 + Vector2(-60, 0), Vector2.from_angle(a3) * 230.0 + Vector2(60, 40), Color(0.7, 0.1, 0.1, 0.8), 7.0)
	# damage: fires that grow as the bar goes down
	var fires := int(hurt * 14.0)
	for f in fires:
		var a4 := f * 2.39996
		var p4 := Vector2.from_angle(a4) * (220.0 + 80.0 * sin(f * 1.7))
		var fl := 0.6 + 0.4 * sin(_t * 9.0 + f)
		s.draw_circle(p4, 16.0 * fl, Color(1.0, 0.55, 0.15, 0.55))
		s.draw_circle(p4, 7.0 * fl, Color(1.0, 0.9, 0.5, 0.8))
	if s.hit_flash > 0.0:
		s.draw_arc(Vector2.ZERO, 300.0, 0.0, TAU, 96, Color(1, 1, 1, 0.25), 70.0)
	_ring(s, 345.0)


func _draw_core(s) -> void:
	if not core_open:
		# the plating: heavy hex plates over the reactor
		var pts := PackedVector2Array()
		for i in 6:
			pts.append(Vector2.from_angle(i * TAU / 6.0) * 98.0)
		s.draw_colored_polygon(pts, METAL.darkened(0.25))
		for i2 in 6:
			s.draw_line(Vector2.ZERO, Vector2.from_angle(i2 * TAU / 6.0) * 98.0, DARK, 4.0)
		pts.append(pts[0])
		s.draw_polyline(pts, DARK, 5.0)
		s.draw_circle(Vector2.ZERO, 18.0, Color(1.0, 0.45, 0.2, 0.4 + 0.2 * sin(_t * 3.0)))
		return
	# open: the reactor glows, pulsing, sparks flying
	var k := 0.5 + 0.5 * sin(_t * 7.0)
	s.draw_circle(Vector2.ZERO, 120.0 + 14.0 * k, Color(1.0, 0.45, 0.15, 0.25))
	s.draw_circle(Vector2.ZERO, 90.0, Color(1.0, 0.55, 0.2))
	s.draw_circle(Vector2.ZERO, 62.0 + 6.0 * k, Color(1.0, 0.8, 0.4))
	s.draw_circle(Vector2.ZERO, 34.0, Color(1.0, 0.97, 0.85))
	for i3 in 5:
		var a := _t * 2.0 + i3 * TAU / 5.0
		s.draw_arc(Vector2.ZERO, 108.0, a, a + 0.6, 12, Color(1.0, 0.9, 0.6, 0.8), 3.0)
	if s.hit_flash > 0.0:
		s.draw_circle(Vector2.ZERO, 95.0, Color(1, 1, 1, 0.4))
	# its own bar: the station's (what is left of it)
	_mini_bar(s, Vector2(0, -150), 220.0, share() / CORE_AT, Color(1.0, 0.55, 0.2))
	_ring(s, 130.0)


func _draw_platform(s, _id: String) -> void:
	s.draw_set_transform(Vector2.ZERO, PI * 0.25, Vector2.ONE)
	s.draw_rect(Rect2(-58, -58, 116, 116), DARK)
	s.draw_rect(Rect2(-50, -50, 100, 100), RUST.darkened(0.1))
	s.draw_rect(Rect2(-50, -50, 100, 100), RUST.lightened(0.2), false, 3.0)
	s.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for c in 4:
		s.draw_circle(Vector2.from_angle(c * TAU / 4.0) * 62.0, 5.0, RED if fposmod(_t * 1.3 + c * 0.25, 1.0) < 0.5 else RED.darkened(0.6))
	# the turret: a dome with two long barrels, turned to its target
	var aim: float = -PI * 0.5
	if s.target != null and is_instance_valid(s.target):
		aim = (s.target.position - s.position).angle()
	var dir := Vector2.from_angle(aim)
	for side in [-1.0, 1.0]:
		var b0: Vector2 = dir.orthogonal() * 9.0 * side
		s.draw_line(b0, b0 + dir * 70.0, DARK, 9.0)
		s.draw_line(b0, b0 + dir * 70.0, METAL.lightened(0.15), 5.0)
	s.draw_circle(Vector2.ZERO, 34.0, DARK)
	s.draw_circle(Vector2.ZERO, 29.0, METAL)
	s.draw_circle(dir * 10.0, 7.0, RED)
	if s.hit_flash > 0.0:
		s.draw_circle(Vector2.ZERO, 50.0, Color(1, 1, 1, 0.3))
	if s.jammed_t > 0.0:
		s.draw_arc(Vector2.ZERO, 48.0, _t * 4.0, _t * 4.0 + 2.0, 16, Color(0.5, 0.8, 1.0, 0.6), 2.0)
	_part_bars(s, 95.0)
	_ring(s, 80.0)


func _draw_hangar(s, id: String) -> void:
	var north: bool = id == "hangar_0"
	s.draw_rect(Rect2(-128, -72, 256, 144), DARK)
	s.draw_rect(Rect2(-120, -64, 240, 128), METAL.darkened(0.05))
	s.draw_rect(Rect2(-120, -64, 240, 128), RUST, false, 6.0)
	# the bay door, facing out, glowing while it launches
	var dy := -44.0 if north else 44.0
	var glow := 0.4 + 0.35 * sin(_t * 4.0)
	s.draw_rect(Rect2(-90, dy - 14, 180, 28), Color(0.05, 0.04, 0.04))
	s.draw_rect(Rect2(-86, dy - 4, 172, 8), Color(1.0, 0.5, 0.2, glow))
	for k in 5:
		s.draw_rect(Rect2(-100 + k * 44, -dy * 0.3 - 8, 30, 16), RUST.darkened(0.25))
	s.draw_circle(Vector2(-110, -dy), 5.0, RED if fposmod(_t, 1.0) < 0.5 else RED.darkened(0.6))
	s.draw_circle(Vector2(110, -dy), 5.0, RED if fposmod(_t + 0.5, 1.0) < 0.5 else RED.darkened(0.6))
	if s.hit_flash > 0.0:
		s.draw_rect(Rect2(-120, -64, 240, 128), Color(1, 1, 1, 0.25))
	_part_bars(s, 100.0)
	_ring(s, 150.0)


## A part's own bars (shield, armour, structure) over it.
func _part_bars(s, up: float) -> void:
	var st: Dictionary = s.fit.stats()
	var w := 150.0
	var y := -up - 26.0
	s._bar(Vector2(-w / 2.0, y), w, s.fit.shield, st["shield_max"], Color(0.35, 0.65, 1.0))
	s._bar(Vector2(-w / 2.0, y + 4.0), w, s.fit.armor, st["armor_max"], Color(1.0, 0.8, 0.3))
	s._bar(Vector2(-w / 2.0, y + 8.0), w, s.fit.structure, st["structure_max"], Color(1.0, 0.35, 0.3))


func _mini_bar(s, at: Vector2, w: float, k: float, col: Color) -> void:
	s.draw_rect(Rect2(at + Vector2(-w * 0.5 - 2, -2), Vector2(w + 4, 12)), Color(0, 0, 0, 0.7))
	s.draw_rect(Rect2(at + Vector2(-w * 0.5, 0), Vector2(w * clampf(k, 0.0, 1.0), 8)), col)


## The ring when it is your target or under the mouse.
func _ring(s, r: float) -> void:
	var pl = view.player if view != null else null
	var locked := false
	if pl != null and is_instance_valid(pl):
		for l in pl.locks:
			if l.get("node") == s:
				locked = true
	if locked:
		s.draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, Color(1.0, 0.35, 0.3, 0.9), 2.5)
	elif view.hovered == s:
		s.draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, Color(1, 1, 1, 0.6), 1.5)


# ---------------------------------------------------------------- the boss bar

func show_bar(on: bool) -> void:
	_show_bar(on)


func _show_bar(on: bool) -> void:
	var su = view.get_tree().current_scene.get("story_ui") if view != null and view.get_tree().current_scene != null else null
	if su != null and "radio_top" in su:
		su.radio_top = (124.0 * clampf(view.get_viewport_rect().size.y / 900.0, 1.0, 2.4) + 12.0) if on else 72.0     # (the radio under the bar)
	if not on:
		if _bar != null and is_instance_valid(_bar):
			_bar.queue_free()
		_bar = null
		_bar_ui = null
		return
	if _bar != null and is_instance_valid(_bar):
		return
	_bar = CanvasLayer.new()
	_bar.layer = 12
	view.add_child(_bar)
	_bar_ui = _BossBar.new()
	_bar_ui.roost = self
	_bar_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bar_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.add_child(_bar_ui)


func _update_bar() -> void:
	if _bar_ui != null and is_instance_valid(_bar_ui):
		_bar_ui.queue_redraw()


func _exit_tree() -> void:
	_show_bar(false)
	for id in parts:
		var s = parts[id]
		if s != null and is_instance_valid(s):
			s.queue_free()


class _BossBar extends Control:
	var roost = null

	func _draw() -> void:
		if roost == null or not is_instance_valid(roost):
			return
		var vs := get_viewport_rect().size
		var k := clampf(vs.y / 900.0, 1.0, 2.4)
		var font := ThemeDB.fallback_font
		var w := 560.0 * k
		var x := (vs.x - w) * 0.5
		var y := 52.0 * k                         # (under the top line of the screen)
		var title := "RED TALON ROOST"
		var tw := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, int(17 * k)).x
		draw_string(font, Vector2((vs.x - tw) * 0.5 + 1, y + 17 * k + 1), title, HORIZONTAL_ALIGNMENT_LEFT, -1, int(17 * k), Color(0, 0, 0, 0.8))
		draw_string(font, Vector2((vs.x - tw) * 0.5, y + 17 * k), title, HORIZONTAL_ALIGNMENT_LEFT, -1, int(17 * k), Color(1.0, 0.55, 0.5))
		var by := y + 26.0 * k
		var bh := 16.0 * k
		draw_rect(Rect2(x - 3, by - 3, w + 6, bh + 6), Color(0.05, 0.02, 0.02, 0.9))
		draw_rect(Rect2(x, by, w, bh), Color(0.25, 0.06, 0.05))
		var sh: float = roost.share()
		draw_rect(Rect2(x, by, w * sh, bh), Color(0.9, 0.22, 0.18) if not roost.core_open else Color(1.0, 0.55, 0.2))
		draw_rect(Rect2(x, by, w * sh, bh * 0.3), Color(1, 1, 1, 0.15))
		var cx: float = x + w * roost.CORE_AT
		draw_line(Vector2(cx, by - 4), Vector2(cx, by + bh + 4), Color(1.0, 0.8, 0.4, 0.9), 2.0)
		draw_rect(Rect2(x - 3, by - 3, w + 6, bh + 6), Color(0.95, 0.35, 0.3), false, 2.0)
		var pct := "%d %%" % int(ceil(sh * 100.0))
		draw_string(font, Vector2(x + w + 10 * k, by + bh - 2 * k), pct, HORIZONTAL_ALIGNMENT_LEFT, -1, int(14 * k), Color(1.0, 0.6, 0.55))
		var sub := "Gun platforms %d / 4   ·   Hangars %d / 2" % [roost.platforms_left(), roost.hangars_left()]
		if roost.core_open:
			sub = "THE CORE IS OPEN   ·   " + sub
		var sw := font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, int(12 * k)).x
		draw_string(font, Vector2((vs.x - sw) * 0.5, by + bh + 18 * k), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, int(12 * k), Color(1.0, 0.85, 0.5) if roost.core_open else Color(0.85, 0.8, 0.78))
