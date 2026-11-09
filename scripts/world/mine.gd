extends Node2D
## Phase 0.5 package 20: a mine laid by a mine launcher (types in GameData.MINES).
##   proximity – armed after 3 s, explodes when a hostile ship comes close
##   timer     – explodes after the time set on the launcher
##   jammer    – jams the radar of hostile ships around it, then burns out
##   emp       – armed after 3 s, goes off near a hostile ship: shields, capacitor and modules dead
## Mines only threaten ships hostile to the ship that laid them and disappear after a while.
## Point defense shoots them down (intercept()).

const ARM_TIME := 3.0

var kind := "mine_proximity"
var layer = null                 # Ship that laid it (may be gone)
var faction := ""
var slot := ""                   # launcher slot of the layer
var view: Node
var age := 0.0
var life := 300.0
var fuse := 10.0                 # timed mine: seconds until it explodes
var power := 1.0                 # damage multiplier from the launcher size
var _jam_tick := 0.0


func setup(p_layer, p_kind: String, p_slot: String, p_fuse: float, p_power: float, p_view: Node) -> void:
	layer = p_layer
	faction = p_layer.faction
	kind = p_kind
	slot = p_slot
	fuse = p_fuse
	power = p_power
	view = p_view
	life = GameData.MINE_LIFE
	var back := Vector2.from_angle(float(p_layer.heading) + PI)
	position = p_layer.position + back * (float(p_layer.radius) + 40.0)
	add_to_group("mines")


## Package 40d: an old mine of a forgotten war – nobody's, it goes off against anyone, it never runs out.
func setup_old(pos: Vector2, p_view: Node) -> void:
	layer = null
	faction = "derelict"
	kind = "mine_proximity"
	view = p_view
	life = 1.0e12
	power = 1.4
	age = ARM_TIME
	position = pos
	add_to_group("mines")


func data() -> Dictionary:
	return GameData.MINES[kind]


## Would this mine go off against `n`?
func threatens(n) -> bool:
	if n == null or not is_instance_valid(n) or not n.is_targetable():
		return false
	if faction == "derelict":
		return true
	if layer != null and is_instance_valid(layer):
		return Ship.hostile(layer, n)
	return Ship.are_hostile(faction, n.faction)


func armed() -> bool:
	return age >= ARM_TIME


func _physics_process(delta: float) -> void:
	age += delta
	if age >= life:
		queue_free()
		return
	var d := data()
	match kind:
		"mine_timer":
			if age >= fuse:
				explode()
		"mine_jammer":
			_jam_tick -= delta
			if age >= 1.0 and _jam_tick <= 0.0:
				_jam_tick = 0.5
				for n in get_tree().get_nodes_in_group("ships"):
					if threatens(n) and position.distance_to(n.position) <= float(d["trigger"]):
						n.jam(1.0)
			if age >= float(d["jam_time"]):
				queue_free()
		_:
			if armed():
				for n in get_tree().get_nodes_in_group("ships"):
					if threatens(n) and position.distance_to(n.position) <= float(d["trigger"]) + float(n.radius):
						explode()
						return
	queue_redraw()


func explode() -> void:
	var d := data()
	var src = layer if (layer != null and is_instance_valid(layer)) else null
	var blast := float(d.get("splash", 200.0))
	for n in get_tree().get_nodes_in_group("ships"):
		if not threatens(n):
			continue
		var dist := position.distance_to(n.position)
		if dist > blast + float(n.radius):
			continue
		if kind == "mine_emp":
			n.apply_emp(float(d["emp_time"]), src)
		else:
			var falloff := 1.0 - 0.5 * clampf(dist / (blast + float(n.radius)), 0.0, 1.0)
			n.take_damage(float(d["damage"]) * power * falloff, "explosive", src)
	if view != null:
		view.spawn_fx(Fx.explosion(position, blast, Color(d["color"])))
		view.spawn_fx(Fx.flash(position, Color(d["color"]), blast * 0.6))
	queue_free()


## Shot down by point defense: a small puff, no effect.
func intercept() -> void:
	if view != null:
		view.spawn_fx(Fx.explosion(position, 18.0, Color(0.9, 0.9, 0.7)))
	queue_free()


func _draw() -> void:
	var col: Color = data()["color"] if faction != "derelict" else Color(0.8, 0.42, 0.2)
	var z: float = view.camera.zoom.x if view != null and view.camera != null else 1.0
	var s := maxf(6.0, 4.0 / maxf(z, 0.001)) if z < 0.5 else 6.0
	draw_circle(Vector2.ZERO, s, Color(0.12, 0.12, 0.14))
	draw_arc(Vector2.ZERO, s, 0.0, TAU, 16, col, 1.5)
	for i in 4:
		var a := i * TAU / 4.0 + 0.4
		draw_line(Vector2.from_angle(a) * s, Vector2.from_angle(a) * s * 1.6, col, 1.5)
	var blink := armed() and fmod(age, 1.0) < 0.35
	draw_circle(Vector2.ZERO, s * 0.4, col if blink or kind == "mine_jammer" else Color(col, 0.35))
	if kind == "mine_jammer" and age >= 1.0:
		var r := float(data()["trigger"])
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 96, Color(col, 0.18), 2.0 / maxf(z, 0.001))
