extends Node2D
## 0.7.52.25 (Luz): your drones outside a fight – they sit on your suit as they do in one (on the back, or on the
## Senate armours at the upper arms), and C / Shift+C sends them up: they hover by you and follow you, and come back
## to their dock on the same key. (Where you may fight, GroundCombat has them; this is for the decks, the streets,
## the places without a fight.) No class_name: preload it.

const DroneArtB = preload("res://scripts/ground/drone_art.gd")
const GearDataB = preload("res://data/gear.gd")
const S := GroundMap.SCALE

var view                                     # the GroundView
var drones: Array = [{}, {}]                 # {id, kind, state: docked/launch/hover/dock, pos, alt, head, t}
var _t := 0.0


func _ready() -> void:
	z_index = 40


func ids() -> Array:
	var ds: Array = GameState.gear.drones
	return range(mini(2, ds.size()))


func shoulder() -> bool:
	return bool(GearDataB.base(String(GameState.gear.suit)).get("shoulder_drones", false))


func _dock_at(i: int) -> Vector2:
	var p: Vector2 = view.pilot.pos
	if not shoulder():
		return p + Vector2(-1, -1)
	var dir: int = view.pilot.dir
	var x := 0.0
	if dir == 0:
		x = 6.0 if i == 0 else -6.0
	elif dir == 1:
		x = -6.0 if i == 0 else 6.0
	return p + Vector2(x, -1)


## C (i 0) / Shift+C (i 1): up, or back to its dock. Returns what to say.
func command(i: int) -> String:
	var ds: Array = GameState.gear.drones
	if i >= ds.size() or String(ds[i]) == "":
		return "No drone in your %s drone place." % ("second" if i == 1 else "")
	var d: Dictionary = drones[i]
	if d.is_empty() or String(d["state"]) in ["docked", "dock"]:
		if d.is_empty():
			_make(i)
			d = drones[i]
		d["state"] = "launch"
		d["t"] = 0.0
		d["pos"] = _dock_at(i)
		Audio.play("drone_launch", "drone up outside a fight", -8.0)
		return "Drone up – it follows you."
	d["state"] = "dock"
	return "Drone back on your %s." % ("arm" if shoulder() else "back")


func _make(i: int) -> void:
	var id := String(GameState.gear.drones[i])
	drones[i] = {"id": id, "kind": String(GearDataB.stats(id).get("kind", "laser")), "state": "docked", "pos": _dock_at(i),
		"alt": 16.0, "head": PI * 0.5, "t": 0.0}


func _process(delta: float) -> void:
	_t += delta
	if view == null or view.pilot == null:
		return
	visible = view.pilot.visible
	for i in 2:
		var ds: Array = GameState.gear.drones
		if i >= ds.size() or String(ds[i]) == "":
			drones[i] = {}
			continue
		if drones[i].is_empty() or String(drones[i]["id"]) != String(ds[i]):
			_make(i)
		var d: Dictionary = drones[i]
		d["t"] = float(d["t"]) + delta
		var p0: Vector2 = d["pos"]
		match String(d["state"]):
			"docked":
				d["pos"] = _dock_at(i)
				d["alt"] = 20.0 if shoulder() else 14.0
				continue
			"launch":
				if float(d["t"]) > 0.6:
					d["state"] = "hover"
			"dock":
				if (d["pos"] as Vector2).distance_to(_dock_at(i)) < 4.0:
					d["state"] = "docked"
					Audio.play("module_off", "drone docks", -10.0)
					continue
		var want: Vector2 = _dock_at(i) if String(d["state"]) == "dock" else view.pilot.pos + (Vector2(16, -6) if i == 0 else Vector2(-14, 10)) \
			+ Vector2(sin(float(d["t"]) * 1.7) * 3.0, cos(float(d["t"]) * 1.3) * 2.0)
		var alt := 16.0 if String(d["state"]) == "dock" else 30.0
		var to: Vector2 = want - (d["pos"] as Vector2)
		if to.length() > 0.5:
			d["pos"] = (d["pos"] as Vector2) + to.limit_length(150.0 * delta) if to.length() > 10.0 else (d["pos"] as Vector2).lerp(want, 1.0 - exp(-delta * 5.0))
		d["alt"] = lerpf(float(d["alt"]), alt, 1.0 - exp(-delta * 5.0))
		var mv: Vector2 = (d["pos"] as Vector2) - p0
		if mv.length() > 0.15:
			d["head"] = lerp_angle(float(d["head"]), mv.angle(), 1.0 - exp(-delta * 8.0))
	queue_redraw()


func _draw() -> void:
	if view == null or view.pilot == null:
		return
	var pw: Walker = view.pilot
	var cs := ChibiArt.CHAR_SCALE
	for i in 2:
		var d: Dictionary = drones[i]
		if d.is_empty():
			continue
		if String(d["state"]) == "docked":
			if shoulder():
				var left := i == 0
				var near := (pw.dir == 2 and left) or (pw.dir == 3 and not left)
				if pw.dir in [2, 3] and not near:
					continue
				var sx := 0.0
				if pw.dir == 0:
					sx = 1.0 if left else -1.0
				elif pw.dir == 1:
					sx = -1.0 if left else 1.0
				DroneArtB.draw_arm(self, String(d["kind"]), pw.pos * S + Vector2(0, -ChibiArt.H * cs + 14.0 * cs) + Vector2(sx * 9.5 * cs, 0), sx, cs)
			elif i == 0:
				DroneArtB.draw_docked(self, String(d["kind"]), pw.pos * S + Vector2(0, -ChibiArt.H * cs + 20.0 * cs), pw.dir, cs)
			continue
		var at: Vector2 = (d["pos"] as Vector2) * S - Vector2(0, float(d["alt"]) * S)
		DroneArtB.draw(self, String(d["kind"]), at, float(d["alt"]) * S, _t, cs, float(d["head"]))
