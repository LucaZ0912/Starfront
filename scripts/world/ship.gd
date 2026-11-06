class_name Ship
extends Node2D
## A ship in system space.
## Movement/actions via orders. Combat runs automatically (auto-battler):
## target selection by stance, target lock via sensors, weapons fire on their own
## once a target is locked, in range and there is enough capacitor energy.

signal destroyed(ship: Ship)

var fit: ShipFitting
var view: Node                  # SystemView
var faction := "player"
var paint := "player"            # palette key: faction or government (PixelArt)
var velocity := Vector2.ZERO
var heading := 0.0
var order: Dictionary = {"type": "idle"}
var target = null               # Ship or null
var last_attacker = null
var lock_progress := 0.0
var weapon_timers: Array = []
var spool := -1.0               # >= 0: jump drive spooling
var spool_need := 1.0            # warp alignment: total time it will take (ring on the ship)
var activity := ""
var radius := 20.0
var dying := false
var hit_flash := 0.0
var tool_beams: Array = []      # [[target_pos, colour], ...] for tool beams
var _retarget := 0.0
var _orbit_sign := 1.0
var _wander := Vector2.ZERO
var bounty := 0                  # NPC: credits paid for destroying it (0 = no bounty on its head)
var bounty_by := ""              # NPC pirate: power that put out the bounty (package 13)
var innocent := false            # NPC: the player attacked it while it was no threat (crime, package 13)
## Pirate AI role (phase 0.5 package 14, data/pirate_archetypes.gd): raider, brawler, sniper,
## ambusher, leech, coward ("" = plain behaviour).
var archetype := ""
var notorious_id := ""           # notorious pirate captain (package 15)
var special := ""                # its trait: shield_breaker, never_alone, iron_hide, ghost, overcharged, regenerator
var escort_of = null             # escort: the captain it protects
var toughness := 1.0             # damage taken is multiplied by this (captains: by stars)
var raiding := false             # raiding a station: ignores no-fire zones (5-star captains)
var _distress_t := -1000.0       # last distress call (package 16)
var smuggler_mission := ""       # smuggler of an intercept contract (package 17)
var escort_mark := false         # part of the convoy the pilot is escorting – drawn green
var convoy_lead := false         # the lead ship of a convoy / mission patrol (the one everybody follows)
var escort_kind := "convoy"      # "convoy" | "patrol" – for the green markers and labels
var _raid_t := 0.0               # raider: time in the current attack / break-off phase
var _raid_break := false
var _ambush_t := -1.0            # ambusher: seconds since it sprang its ambush (-1 = lying in wait)
var _hide := Vector2.INF         # ambusher: hiding spot
var fleeing := false             # coward: running away
var _flee_t := 0.0
var _called_help := false
var warrant_known := false       # NPC: the player's Warrant Scanner has read its bounty
var scan_jobs := {}
var _mine_acc := {}              # ore -> units mined since the last floating number
var _mine_t := 0.0              # slot -> {t, total, ...}: running survey / prospect / warrant scans
var _avoid_side := {}            # colossus instance id -> +1/-1 (which way round it we go)
var _stuck_t := 0.0
var _stuck_ref := Vector2.ZERO
var home := Vector2.ZERO        # patrol centre (NPC)
var provoked := false            # NPC: the player opened fire on it – it fights back (package 12)
var scanned_player := false      # patrol: has already scanned the pilot's ship
## Active warp: {from, to, t, T, then}. Empty = not warping.
var warp: Dictionary = {}
var warp_frozen := false         # held in place by an interdictor (phase 0.5 package 11)
var warp_disrupted := 0.0        # seconds the warp drive stays offline after an interdiction
# Phase 0.5 package 20
var shield_down := 0.0           # seconds until a collapsed shield restarts (at 50 %)
var emp_t := 0.0                 # EMP: capacitor, shield and modules dead for this long
var jammed_t := 0.0              # radar jammed (radar picture gone, locks only at short range)
var _xfer_t := 0.0               # receiving a shield transfer: the downtime runs out faster
var jamming := false             # NPC: its radar jammer is running
var manifest_done := false       # cargo manifest generated (cargo scanner, wreck loot)
var cargo_known := false         # the pilot's cargo scanner has read the manifest
var unregistered := false        # smuggler: cargo without a registered manifest
## Mine launcher settings (slot -> {"type", "fuse"}) – kept in the fitting, so they survive jumps and saves (review W5)
var mine_choice: Dictionary:
	get:
		return fit.mine_choice if fit != null else {}
	set(v):
		if fit != null:
			fit.mine_choice = v
var pd_timers := {}              # point defense slot -> cooldown left
const JAM_SENSOR := 0.5          # jammed: lock / engage range factor
const XFER_DOWN_MULT := 3.0      # shield downtime runs this much faster while a transfer beam is on it

## Manual control (the player's ship): no auto-battle. The pilot locks targets and
## activates modules (module bar / keys 1–9). NPCs keep fighting automatically.
const FactionData = preload("res://data/factions.gd")
const ArchData = preload("res://data/pirate_archetypes.gd")
const MAX_LOCKS := 3              # minimum; bigger sensor suites hold more (package 22: stats max_locks)
var manual := false
var is_drone := false            # package 23: a drone of the pilot (scripts/world/drone.gd)
var locks: Array = []            # [{key, node, progress}]
var active_lock := ""            # key of the lock that newly switched-on modules act on
var module_target := {}          # package 22 (multi-focus): slot -> lock key the module works on
var _focus: Array = []           # NPC: extra targets for its weapons (bigger ships split their fire)
var _relock := {}                # lock key -> {node, until}: lost out of range – re-locked when back
const RELOCK_TIME := 60.0        # how long modules wait for a target that left the sensor range
var module_on := {}              # slot -> bool
var last_reflected := 0.0        # damage the reflective hull last sent back (package 25d)
var hatch_open := {}             # hatch name -> 0 (shut) … 1 (open) (package 25d, Citadel)
var _hatch_hold := {}            # hatch name -> seconds it stays open
var hatch_queue := 0             # drones waiting below the drone hatch
var platform_t := -1.0           # launch animation of the S-ship platform (-1 = idle)
var arm_open := 1.0              # Goliath: 0 = arms folded in (docking), 1 = swung open (package 25d)
var combat_t := 0.0              # seconds of "in a fight" left: firing, being hit, a hostile target (25e)
var next_hatch := 0              # the next drone door in turn (drones use the doors one after another)
var auto_targets: Array = []     # Cathedral auto mode: the targets locked when it was switched on (25f)
var _auto_t := 0.0
var _auto_k := 0                 # auto mode: whose turn it is among the targets (the lance takes turns)
var _npc_pulse_t := 0.0
const ARM_TIME := 1.6            # seconds to swing the arms fully open or shut
const HATCH_TIME := 0.45         # seconds to slide a hatch open or shut
const PLATFORM_ANIM := 3.4       # hatch opens, the small ship rises, lifts off, the hatch closes
var module_timers := {}          # slot -> remaining cycle time (weapons)
var module_state := {}           # slot -> "off" | "on" | "range" | "energy"


func setup(p_fit: ShipFitting, p_view: Node) -> void:
	fit = p_fit
	view = p_view
	faction = fit.faction
	paint = fit.gov if fit.gov != "" else faction
	position = fit.position
	heading = fit.rotation
	var tex := PixelArt.ship_texture(fit.hull_id, paint)
	radius = maxf(tex.get_width(), tex.get_height()) * PixelArt.SCALE * 0.42
	if fit.hull().has("black_hole"):
		bh_t = -1.0 if is_docked() or cloaked() else 99.0      # a Threshold met in space already burns
	if not is_docked():
		_restore_held()
	if fit.capacitor < 0.0:
		fit.refill()
	_orbit_sign = 1.0 if randf() < 0.5 else -1.0
	add_to_group("ships")
	home = position
	if not fit.route.is_empty():
		order = {"type": "travel"}


## The Threshold's artificial black hole (0.4.25.37): a few seconds after undocking it ignites with a flash of
## light, the hole grows and then its accretion disc forms; on the way into the hangar it goes out with a flash.
const BH_DELAY := 2.5            # seconds after undocking until the core ignites
const BH_FLASH := 0.7            # how long the flash of light lasts
const BH_HOLE := 1.4             # the hole has grown by then …
const BH_DISC := 3.2             # … and the disc has formed by then
var bh_t := -1.0                 # time since ignition; -1 = out
var bh_wait := 0.0
var bh_out := -1.0               # time since it went out (the closing flash); -1 = none
var bh_cloaked := false          # went out for the cloak: ignites again quickly once the ship shows (0.4.25.39)


func _process(delta: float) -> void:
	if fit == null or not fit.hull().has("black_hole"):
		set_process(false)
		return
	# out while docking and in the hangar – and under the cloak: it goes out as the cloak takes hold and
	# ignites again once the ship is fully visible
	var hidden := cloaked() or cloak_k > 0.0
	var want := not dying and not is_docked() and not hidden and not String(order.get("type", "")) in ["docking", "undocking"]
	if hidden and bh_t >= 0.0:
		bh_cloaked = true
	if want:
		if bh_t < 0.0:
			bh_wait += delta
			if bh_wait >= (0.3 if bh_cloaked else BH_DELAY):
				bh_t = 0.0
				bh_cloaked = false
		else:
			bh_t += delta
	elif bh_t >= 0.0:
		bh_t = -1.0
		bh_out = 0.0
	if not want:
		bh_wait = 0.0
	if bh_out >= 0.0:
		bh_out += delta
		if bh_out > BH_FLASH:
			bh_out = -1.0


## Draws the black hole over the core – turned back against the ship's heading, so it always shows the
## same face to the camera.
func _draw_black_hole(hull_tex: Texture2D, alpha: float = 1.0) -> void:
	if bh_t < 0.0 and bh_out < 0.0:
		return
	var core: Array = fit.hull()["black_hole"]["core"]
	var c := (Vector2(float(core[0]) + 1.5, float(core[1]) + 1.5) - Vector2(hull_tex.get_width(), hull_tex.get_height()) * 0.5) * PixelArt.SCALE
	draw_set_transform(c.rotated(heading), 0.0, Vector2.ONE)
	var full := PixelArt.black_hole_texture()
	var sz := Vector2(full.get_width(), full.get_height()) * PixelArt.SCALE
	var rect := Rect2(-sz * 0.5, sz)
	var big := sz.x * 0.5
	var flash := -1.0
	if bh_t >= 0.0:
		if bh_t > 0.15 and bh_t < BH_DISC:
			var k := clampi(int((bh_t - 0.15) / (BH_HOLE - 0.15) * 5.0), 0, 4)
			draw_texture_rect(PixelArt.black_hole_texture(k), rect, false, Color(1, 1, 1, alpha))
		if bh_t >= BH_HOLE:
			draw_texture_rect(full, rect, false, Color(1, 1, 1, alpha * clampf((bh_t - BH_HOLE) / (BH_DISC - BH_HOLE), 0.0, 1.0)))
		flash = bh_t / BH_FLASH
	elif bh_out >= 0.0:
		if bh_out < 0.15:
			draw_texture_rect(full, rect, false, Color(1, 1, 1, alpha * (1.0 - bh_out / 0.15)))
		flash = bh_out / BH_FLASH
	var glow := 0.0
	if flash >= 0.0 and flash < 1.0:
		# a real flare (0.4.25.38): flashes up at once, then fades – a wide halo, a white-hot centre and
		# four rays, and the whole hull lights up with it
		glow = (flash / 0.08 if flash < 0.08 else pow(1.0 - (flash - 0.08) / 0.92, 1.6)) * alpha
		var r := big * (0.5 + 1.1 * flash)
		draw_circle(Vector2.ZERO, r * 2.6, Color(1.0, 0.85, 0.6, 0.35 * glow))
		draw_circle(Vector2.ZERO, r * 1.6, Color(1.0, 0.92, 0.75, 0.65 * glow))
		draw_circle(Vector2.ZERO, r, Color(1.0, 0.97, 0.9, 0.95 * glow))
		draw_circle(Vector2.ZERO, r * 0.5, Color(1, 1, 1, glow))
		for i in 4:
			var d := Vector2.from_angle(PI * 0.25 + i * PI * 0.5) * big * (2.5 + 2.0 * flash)
			draw_line(-d * 0.1, d, Color(1.0, 0.97, 0.88, 0.85 * glow), PixelArt.SCALE * 1.5)
			draw_line(-d * 0.1, d * 0.6, Color(1, 1, 1, glow), PixelArt.SCALE * 0.6)
		var h := Vector2.from_angle(0.0) * big * (4.0 + 3.0 * flash)
		draw_line(-h, h, Color(1.0, 0.95, 0.85, 0.6 * glow), PixelArt.SCALE)
	draw_set_transform(Vector2.ZERO, heading, Vector2.ONE)
	if glow > 0.0:
		var hs := Vector2(hull_tex.get_width(), hull_tex.get_height()) * PixelArt.SCALE
		draw_texture_rect(PixelArt.silhouette_texture(fit.hull_id), Rect2(-hs * 0.5, hs), false, Color(1.0, 0.93, 0.8, 0.7 * glow))


## Review W5 (0.4.25.46): point defence, the auto mode and the anti-drone pulse stay switched on across jumps,
## saves and docking – they are kept in the fitting and switched on again when the ship is set up or undocks.
func _keep_on(slot: String, on: bool) -> void:
	if on:
		fit.held_on[slot] = true
	else:
		fit.held_on.erase(slot)


func _restore_held() -> void:
	for slot in fit.held_on.keys():
		if fit.module_data(String(slot)).is_empty():
			fit.held_on.erase(slot)              # the module is gone
			continue
		module_on[slot] = true
		module_state[slot] = "on"


func display_name() -> String:
	return fit.ship_name


func is_docked() -> bool:
	return fit.docked_at != ""


func is_targetable() -> bool:
	return not dying and not is_docked() and is_inside_tree() and warp.is_empty() and not cloaked() and not in_station()


## Review W4 (0.4.25.46): still inside a waystation – waiting for a free pad or not yet risen through the hatch.
func in_station() -> bool:
	return String(order.get("type", "")) == "undocking" and order.has("pad") and (int(order["pad"]) < 0 or float(order.get("t", 0.0)) < 0.5)


## Axiom cloaking device (package 25g): nobody sees or targets a cloaked ship; it can fly, warp and lock
## targets – using a weapon, tool or module switches the cloak off (0.4.25.40).
func cloaked() -> bool:
	return module_on.get("builtin_cloak", false)


func decloak(why: String) -> void:
	if not module_on.get("builtin_cloak", false):
		return
	module_on["builtin_cloak"] = false
	module_state["builtin_cloak"] = "off"
	_mlog("Cloak off – %s used: you are visible again." % why, GameState.COL_WARN)


func in_warp() -> bool:
	return not warp.is_empty()


static func are_hostile(a: String, b: String) -> bool:
	return a != b and (a == "pirate" or b == "pirate")


## Would this NPC fight the pilot's ship? Depends on the pilot's standing with the NPC's
## faction (phase 0.5 package 12): pirates leave Friendly pilots alone, patrols attack
## Hostile ones, and any ship the pilot opened fire on fights back.
func hostile_to_player() -> bool:
	if faction == "player":
		return false
	if provoked:
		return true
	match faction:
		"pirate":
			return GameState.rep.pirates_hostile(fit.gov)
		"patrol":
			return GameState.rep.patrol_attitude(fit.gov) == "attack"
	return false


## Hostility between two ship nodes (role rules between NPCs, standing towards the pilot).
static func hostile(a, b) -> bool:
	if a == null or b == null or a == b:
		return false
	if a.faction == "player" and b.faction != "player":
		return b.hostile_to_player()
	if b.faction == "player" and a.faction != "player":
		return a.hostile_to_player()
	return are_hostile(a.faction, b.faction)


func faction_color() -> Color:
	match faction:
		"player":
			return Color(0.35, 0.85, 1.0)
		"pirate":
			return Color(1.0, 0.35, 0.3)
	return Color(1.0, 0.9, 0.4)


# ---------------------------------------------------------------- Orders

func set_order(o: Dictionary) -> void:
	if in_warp():
		if faction == "player":
			GameState.log_msg("In warp – the order will be executed on arrival.", GameState.COL_WARN)
		warp["then"] = o
		return
	if is_docked():
		undock()
	if order.get("type", "") == "undocking":
		order["then"] = o          # carried out once the ship has left the bay
		if o.get("type", "") == "attack":
			_set_target(o.get("target"))
		return
	_abort_landing()
	order = o
	spool = -1.0
	var t: String = o.get("type", "")
	if t != "travel" and not o.get("keep_route", false):
		fit.route.clear()
	if o.get("type", "") == "attack":
		_set_target(o.get("target"))


func undock() -> void:
	var st_node = view.stations.get(fit.docked_at)
	fit.docked_at = ""
	_restore_held()
	scale = Vector2.ONE
	modulate = Color.WHITE
	visible = true
	if st_node == null:
		return
	if st_node.has_method("has_pads") and st_node.has_pads() and fits_pads(st_node):
		# package 26: up through the hatch of a free landing pad (it waits inside while all are in use)
		position = st_node.position
		velocity = Vector2.ZERO
		modulate.a = 0.0
		order = {"type": "undocking", "node": st_node, "t": 0.0, "pad": -1}
		activity = "Waiting for a free landing pad"
		return
	var bay: Dictionary = st_node.nearest_bay(st_node.position + Vector2.from_angle(randf() * TAU) * 5000.0)
	if bay.is_empty():
		var dir := Vector2.from_angle(randf() * TAU)
		position = st_node.position + dir * (st_node.radius + 60.0)
		heading = dir.angle()
		velocity = dir * 120.0
		view.spawn_fx(Fx.flash(position, Color(0.4, 0.9, 1.0), radius * 2.5))
		return
	# leave through a hangar bay: the ship rolls out of the dark bay into space
	var mouth: Vector2 = bay["mouth"]
	var bdir: Vector2 = bay["dir"]
	position = mouth - bdir * float(bay["depth"]) * 0.6
	heading = bdir.angle()
	velocity = Vector2.ZERO
	order = {"type": "undocking", "node": st_node, "t": 0.0, "bay": bay}
	activity = "Leaving the hangar bay …"


## Docking: the ship lines up in front of a hangar bay, glides into it (darkening as it enters
## the hangar) and disappears inside. Undocking plays the same in reverse.
const DOCK_TIME := 3.4
const UNDOCK_TIME := 3.0


func _update_docking(delta: float) -> void:
	var stn = order.get("node")
	if stn == null or not is_instance_valid(stn):
		order = {"type": "idle"}
		scale = Vector2.ONE
		modulate = Color.WHITE
		return
	order["t"] = float(order["t"]) + delta
	var bay: Dictionary = order.get("bay", {})
	velocity = Vector2.ZERO
	if order.has("pad"):
		_dock_pad(stn)
		return
	if bay.is_empty():
		_dock_spiral(stn)
		return
	var k := clampf(float(order["t"]) / DOCK_TIME, 0.0, 1.0)
	var mouth: Vector2 = bay["mouth"]
	var bdir: Vector2 = bay["dir"]
	var entry := mouth + bdir * (radius * 1.3 + 30.0)
	var inner := mouth - bdir * float(bay["depth"]) * 0.62
	var from: Vector2 = order["from"]
	if k < 0.35:
		var e := smoothstep(0.0, 1.0, k / 0.35)
		position = from.lerp(entry, e)
		heading = lerp_angle(float(order.get("h0", heading)), (-bdir).angle(), e)
	else:
		var e2 := smoothstep(0.0, 1.0, (k - 0.35) / 0.65)
		position = entry.lerp(inner, e2)
		heading = (-bdir).angle()
		# into the hangar's shadow, then out of sight
		var dark := clampf((position - mouth).dot(-bdir) / maxf(float(bay["depth"]) * 0.5, 1.0), 0.0, 1.0)
		modulate = Color(lerpf(1.0, 0.45, dark), lerpf(1.0, 0.45, dark), lerpf(1.0, 0.5, dark), 1.0 - smoothstep(0.82, 1.0, k))
	activity = "Docking: entering the hangar bay …"
	if k >= 1.0:
		modulate = Color.WHITE
		view.spawn_fx(Fx.flash(inner, Color(0.4, 0.9, 1.0), 90.0))
		_dock(stn)


func _update_undocking(delta: float) -> void:
	if order.has("pad"):
		_undock_pad(delta)
		return
	order["t"] = float(order["t"]) + delta
	var bay: Dictionary = order["bay"]
	var k := clampf(float(order["t"]) / UNDOCK_TIME, 0.0, 1.0)
	var mouth: Vector2 = bay["mouth"]
	var bdir: Vector2 = bay["dir"]
	var inner := mouth - bdir * float(bay["depth"]) * 0.6
	var out := mouth + bdir * (radius * 2.5 + 200.0)
	var e := smoothstep(0.0, 1.0, k)
	position = inner.lerp(out, e)
	heading = bdir.angle()
	var dark := clampf((position - mouth).dot(-bdir) / maxf(float(bay["depth"]) * 0.5, 1.0), 0.0, 1.0)
	modulate = Color(lerpf(1.0, 0.45, dark), lerpf(1.0, 0.45, dark), lerpf(1.0, 0.5, dark), smoothstep(0.0, 0.15, k))
	velocity = Vector2.ZERO
	activity = "Leaving the hangar bay …"
	if k >= 1.0:
		modulate = Color.WHITE
		velocity = bdir * 120.0
		var then: Dictionary = order.get("then", {"type": "idle"})
		order = {"type": "idle"}
		if then.get("type", "idle") != "idle":
			set_order(then)


# ---------------------------------------------------------------- Package 26: landing pads

const PAD_DOCK_TIME := 4.4
const PAD_SINK := 0.62            # the ship's scale when it has sunk through the hatch


## Review W1 (0.4.25.46): a new order during the approach or the landing breaks it off cleanly – the pad is
## free again, its hatch shuts, the ship gets its size and colour back.
func _abort_landing() -> void:
	var ot := String(order.get("type", ""))
	if not ot in ["dock", "docking"]:
		return
	var stn = order.get("node")
	if stn != null and is_instance_valid(stn) and stn.has_method("release_pad"):
		var pi: int = stn.pad_of(self)
		if pi >= 0:
			stn.set_pad_open(pi, false)
		stn.release_pad(self)
	if ot == "docking":
		scale = Vector2.ONE
		modulate = Color.WHITE


## A waystation's pads take only S and M ships.
func fits_pads(st_node) -> bool:
	var tdef: Dictionary = GameData.station_types.get(String(st_node.data.get("type", "")), {})
	return int(fit.hull().get("size", 1)) <= int(tdef.get("max_size", 3))


## Flying in to a landing pad: claims a free pad when close (one ship per pad), waits outside while all are
## taken, then lines up over its pad. Returns where to fly, or null once the landing has begun.
func _pad_approach(st_node):
	if not fits_pads(st_node):
		if faction == "player":
			GameState.log_msg("%s: the landing pads take only S and M ships." % st_node.data.get("name", "The waystation"), GameState.COL_WARN)
			order = {"type": "idle"}
			return null
		# traffic that is too big for the pads ends its trip at the station
		if position.distance_to(st_node.position) < st_node.radius + 900.0:
			view.spawn_fx(Fx.flash(position, Color(0.4, 0.9, 1.0), radius * 2.5))
			_dock(st_node)
			return null
		return st_node.position
	var near_d := position.distance_to(st_node.position)
	var pi: int = st_node.claim_pad(self, position) if near_d < st_node.radius + 8000.0 else -1
	if pi < 0:
		var out: Vector2 = (position - st_node.position).normalized()
		if out == Vector2.ZERO:
			out = Vector2.RIGHT
		activity = "Waiting for a free landing pad" if near_d < st_node.radius + 8000.0 else "Approaching for landing"
		return st_node.position + out * (st_node.radius + 1800.0)
	var pad: Vector2 = st_node.pad_world(pi)
	var line_up: Vector2 = pad + st_node.pad_dir(pi) * (radius + 300.0)
	activity = "Approaching landing pad %d" % (pi + 1)
	if position.distance_to(line_up) < 160.0:
		order = {"type": "docking", "node": st_node, "t": 0.0, "from": position, "pad": pi, "h0": heading}
		return null
	return line_up


## Landing: glides over the pad and turns to face the station, settles, the hatch opens and the ship sinks
## through it into the station.
func _dock_pad(stn) -> void:
	var pi := int(order["pad"])
	var pad: Vector2 = stn.pad_world(pi)
	var dir: Vector2 = stn.pad_dir(pi)
	var k := clampf(float(order["t"]) / PAD_DOCK_TIME, 0.0, 1.0)
	if k < 0.35:
		var e := smoothstep(0.0, 1.0, k / 0.35)
		position = (order["from"] as Vector2).lerp(pad, e)
		heading = lerp_angle(float(order.get("h0", heading)), (-dir).angle(), e)
		scale = Vector2.ONE
	elif k < 0.5:
		position = pad
		heading = (-dir).angle()
		scale = Vector2.ONE * lerpf(1.0, 0.88, smoothstep(0.35, 0.5, k))          # touch-down
		if k > 0.42:
			stn.set_pad_open(pi, true)
	else:
		position = pad
		var e2 := smoothstep(0.5, 1.0, k)
		scale = Vector2.ONE * lerpf(0.88, PAD_SINK, e2)                           # down through the hatch
		var dark := e2
		modulate = Color(lerpf(1.0, 0.4, dark), lerpf(1.0, 0.4, dark), lerpf(1.0, 0.45, dark), 1.0 - smoothstep(0.75, 1.0, k))
	activity = "Landing on pad %d …" % (pi + 1)
	if k >= 1.0:
		scale = Vector2.ONE
		modulate = Color.WHITE
		stn.set_pad_open(pi, false)
		stn.release_pad(self)
		_dock(stn)


## Lifting off: waits inside for a free pad, the hatch opens, the ship rises through it, the hatch shuts,
## then it lifts off away from the station.
func _undock_pad(delta: float) -> void:
	var stn = order.get("node")
	if stn == null or not is_instance_valid(stn):
		order = {"type": "idle"}
		scale = Vector2.ONE
		modulate = Color.WHITE
		return
	velocity = Vector2.ZERO
	var pi := int(order["pad"])
	if pi < 0:
		pi = stn.claim_pad(self, stn.position + Vector2.from_angle(randf() * TAU) * 100.0)
		if pi < 0:
			position = stn.position
			modulate.a = 0.0
			activity = "Waiting for a free landing pad"
			return
		order["pad"] = pi
		order["t"] = 0.0
	order["t"] = float(order["t"]) + delta
	var t := float(order["t"])
	var pad: Vector2 = stn.pad_world(pi)
	var dir: Vector2 = stn.pad_dir(pi)
	heading = dir.angle()
	activity = "Lifting off from pad %d …" % (pi + 1)
	if t < 0.5:
		stn.set_pad_open(pi, true)
		position = pad
		scale = Vector2.ONE * PAD_SINK
		modulate.a = 0.0
	elif t < 1.9:
		var e := smoothstep(0.0, 1.0, (t - 0.5) / 1.4)
		position = pad
		scale = Vector2.ONE * lerpf(PAD_SINK, 1.0, e)
		var dark := 1.0 - e
		modulate = Color(lerpf(1.0, 0.4, dark), lerpf(1.0, 0.4, dark), lerpf(1.0, 0.45, dark), clampf(e * 1.6, 0.0, 1.0))
	elif t < 2.4:
		stn.set_pad_open(pi, false)
		position = pad
		scale = Vector2.ONE
		modulate = Color.WHITE
	else:
		var k2 := clampf((t - 2.4) / 1.4, 0.0, 1.0)
		position = pad + dir * k2 * k2 * (radius * 2.0 + 700.0)
		if k2 >= 1.0:
			stn.release_pad(self)
			velocity = dir * 160.0
			var then: Dictionary = order.get("then", {"type": "idle"})
			order = {"type": "idle"}
			if then.get("type", "idle") != "idle":
				set_order(then)


## Fallback without bays: the ship spirals into the station hub.
func _dock_spiral(stn) -> void:
	var k := clampf(float(order["t"]) / 2.2, 0.0, 1.0)
	var e := k * k * (3.0 - 2.0 * k)
	var from: Vector2 = order["from"]
	var center: Vector2 = stn.position
	var ang := (from - center).angle() + e * 3.0
	var rad := from.distance_to(center) * (1.0 - e)
	position = center + Vector2.from_angle(ang) * rad
	heading = ang + PI * 0.5 + PI * e
	scale = Vector2.ONE * lerpf(1.0, 0.2, e)
	modulate.a = 1.0 - smoothstep(0.7, 1.0, k)
	activity = "Docking clamps engaged …"
	if k >= 1.0:
		scale = Vector2.ONE
		modulate.a = 1.0
		view.spawn_fx(Fx.flash(center, Color(0.4, 0.9, 1.0), 120.0))
		_dock(stn)


func clear_locks() -> void:
	locks.clear()
	active_lock = ""
	module_on.clear()
	_relock.clear()


func _dock(st_node) -> void:
	if faction == "player" and view != null and view.has_method("stow_all_drones"):
		view.stow_all_drones(self, false)      # drones go back into the hangar (package 23)
	clear_locks()
	fit.docked_at = st_node.data["id"]
	deck_queue = 0                              # review W2: nothing waits on the deck or below the hatch any more
	hatch_queue = 0
	velocity = Vector2.ZERO
	order = {"type": "idle"}
	target = null
	visible = false
	view.on_ship_docked(self, st_node)


# ---------------------------------------------------------------- Main loop

func _physics_process(delta: float) -> void:
	if dying:
		return
	if is_docked():
		visible = false
		activity = "Docked"
		# Docked: shields and capacitor recharge
		var sd := fit.stats()
		fit.shield = sd["shield_max"]
		fit.capacitor = sd["cap_max"]
		shield_down = 0.0
		emp_t = 0.0
		if not fit.power_off.is_empty() or fit.throttle < 1.0:
			fit.apply_power({"off": {}, "throttle": 1.0})
		arm_open = 0.0
		module_on.erase("builtin_cloak")       # no cloaking in a hangar
		cloak_k = 0.0
		return
	visible = true
	_update_power()
	var s := fit.stats()
	hit_flash = maxf(0.0, hit_flash - delta)
	warp_disrupted = maxf(0.0, warp_disrupted - delta)
	emp_t = maxf(0.0, emp_t - delta)
	jammed_t = maxf(0.0, jammed_t - delta)
	_xfer_t = maxf(0.0, _xfer_t - delta)
	_regen(delta, s)
	_update_hatches(delta)
	_update_arms(delta)
	_update_npc_drones(delta)
	_update_npc_pulse(delta)
	_update_npc_cloak(delta)
	if not is_drone:
		_update_cloak_fx(delta)
	_update_auto_fire(delta, s)
	combat_t = maxf(0.0, combat_t - delta)
	if in_warp():
		_update_warp(delta)
		fit.position = position
		fit.rotation = heading
		queue_redraw()
		return
	_update_targeting(delta, s)
	_update_movement(delta, s)
	_update_weapons(delta, s)
	_update_tools(delta, s)
	_update_pd(delta, s)
	_update_npc_jammer(delta, s)
	fit.position = position
	fit.rotation = heading
	queue_redraw()


func _regen(delta: float, s: Dictionary) -> void:
	if special == "regenerator":
		fit.armor = minf(float(s["armor_max"]), fit.armor + float(s["armor_max"]) * 0.01 * delta)
	if emp_t > 0.0:
		fit.capacitor = 0.0
	else:
		fit.capacitor = minf(float(s["cap_max"]), fit.capacitor + float(s["cap_recharge"]) * delta)
	_solar(delta, s)
	var smax := float(s["shield_max"])
	if shield_down > 0.0:
		# package 20: a collapsed shield stays down, then restarts at 50 %
		fit.shield = 0.0
		if emp_t <= 0.0:
			shield_down -= delta * (XFER_DOWN_MULT if _xfer_t > 0.0 else 1.0)
		if shield_down <= 0.0:
			shield_down = 0.0
			fit.shield = smax * 0.5
			_mlog("Shields back online (50 %).", GameState.COL_GOOD)
		return
	var regen := float(s["shield_regen"]) * (3.0 if special == "regenerator" else 1.0)
	fit.shield = minf(smax, fit.shield + regen * delta)


## The shield collapsed (shot down or EMP): it stays down for `t` seconds (default: the downtime of
## the fitted shields – size, type and quality) and comes back at 50 %.
func shield_collapse(t: float = -1.0) -> void:
	var s := fit.stats()
	if float(s["shield_max"]) <= 0.0:
		return
	fit.shield = 0.0
	var dt := t if t >= 0.0 else float(s["shield_downtime"])
	if dt > shield_down:
		shield_down = dt
	_mlog("Shields collapsed – back online in %d s (at 50 %%)." % int(ceil(shield_down)), GameState.COL_BAD)


## EMP (mine): capacitor drained, shield down, modules dead for `t` seconds.
func apply_emp(t: float, src = null) -> void:
	if dying or is_docked():
		return
	if faction == "player" and Commands.god_mode:
		return
	if src != null and is_instance_valid(src):
		last_attacker = src
		if src is Ship and src.faction == "player" and faction != "player":
			_hit_by_player()
	emp_t = maxf(emp_t, t)
	fit.capacitor = 0.0
	if float(fit.stats()["shield_max"]) > 0.0:
		shield_collapse(maxf(t, shield_down))
	for k in module_on.keys():
		if module_on[k]:
			module_on[k] = false
			module_state[k] = "off"
	hit_flash = 0.3
	_mlog("EMP! Capacitor drained, shields down, all modules dead for %d s." % int(ceil(t)), GameState.COL_BAD)
	if view != null:
		view.spawn_fx(Fx.flash(position, Color(0.4, 0.85, 1.0), radius * 4.0))


## Radar jammed for `t` seconds (radar jammer module or jammer mine nearby).
func jam(t: float) -> void:
	if jammed_t <= 0.0 and faction == "player" and manual:
		GameState.log_msg("Radar jammed! Contacts lost, locks only at short range.", GameState.COL_BAD)
	jammed_t = maxf(jammed_t, t)


## Sensor range for locks and engagements (halved while jammed).
func lock_range(s: Dictionary) -> float:
	return float(s["sensor_range"]) * (JAM_SENSOR if jammed_t > 0.0 else 1.0)


## Solar collector (package 20): fuel per second – full close to the star, dropping with distance².
func solar_rate(s: Dictionary) -> float:
	var rate := float(s.get("solar", 0.0))
	if rate <= 0.0 or view == null or not ("layout" in view) or view.layout.is_empty():
		return 0.0
	var star_r := float(view.layout["star"]["radius"])
	var d := maxf(position.length(), star_r)
	return rate * clampf(pow(star_r * 4.0 / d, 2.0), 0.0, 1.0)


func _solar(delta: float, s: Dictionary) -> void:
	if fit.fuel >= float(s["fuel_max"]) or float(s.get("solar", 0.0)) <= 0.0:
		return
	fit.fuel = minf(float(s["fuel_max"]), fit.fuel + solar_rate(s) * delta)


# ---------------------------------------------------------------- Targeting (auto-battle)

## NPCs do not start fights with ships under a station's protection (inside a no-fire zone,
## unless that ship is an aggressor itself).
func _protected(n) -> bool:
	if faction == "player" or view == null or not view.has_method("zone_station"):
		return false
	if raiding:
		return false             # raiders attack right under the station's guns
	if faction == "patrol" and n.faction == "player" and n.fit != null and hostile_to_player() and GameState.law.points(fit.gov) > 0:
		return false             # the law does not stop at the no-fire zone
	return view.zone_station(n.position) != null and not view.is_aggressor(n)


func _set_target(t) -> void:
	if t != target:
		target = t
		lock_progress = 0.0


func _valid(t) -> bool:
	return t != null and is_instance_valid(t) and t.is_targetable()


func _nearest_hostile(max_range: float):
	var best = null
	var bd := max_range
	for n in get_tree().get_nodes_in_group("ships"):
		if n == self or not n.is_targetable() or not hostile(self, n):
			continue
		if not can_see(n):
			continue
		if _protected(n):
			continue
		var d := position.distance_to(n.position)
		if d < bd:
			bd = d
			best = n
	return best


func _update_targeting(delta: float, s: Dictionary) -> void:
	if manual:
		_update_locks(delta, s)
		return
	if not _valid(target) or not can_see(target):
		target = null
	if fleeing:
		target = null
		return
	_update_archetype(delta)
	if order.get("type") == "attack":
		var t = order.get("target")
		if _valid(t):
			_set_target(t)
		else:
			order = {"type": "idle"}
	_retarget -= delta
	if _retarget <= 0.0 and order.get("type") != "attack":
		_retarget = 0.5
		if faction == "patrol" and not scanned_player:
			_scan_player()
		var sensor: float = lock_range(s)
		_update_focus(sensor)
		var keep: bool = target != null and fit.stance != "passive" and position.distance_to(target.position) <= sensor * 1.3 and not (_protected(target) and target != last_attacker)
		if not keep:
			var want = null
			match fit.stance:
				"aggressive":
					# ambushers wait until prey comes close; anyone answers an attacker
					want = _nearest_hostile(sensor * (ArchData.AMBUSH_RANGE if archetype == "ambusher" and _ambush_t < 0.0 else 1.0))
					if want == null and _valid(last_attacker) and hostile(self, last_attacker) and position.distance_to(last_attacker.position) <= sensor * 1.3:
						want = last_attacker
				"defensive":
					if _valid(last_attacker) and position.distance_to(last_attacker.position) <= sensor * 1.3:
						want = last_attacker
			_set_target(want)
	if target != null:
		lock_progress = minf(1.0, lock_progress + delta / _lock_time(s))


const PATROL_SCAN_RANGE := 15000.0


## Patrols of a faction that considers the pilot Neutral scan the ship once in a while.
func _scan_player() -> void:
	var pl = view.player if view != null else null
	if pl == null or not is_instance_valid(pl) or not pl.is_targetable() or fit.gov == "":
		return
	if GameState.rep.patrol_attitude(fit.gov) != "scan" or position.distance_to(pl.position) > PATROL_SCAN_RANGE or not can_see(pl):
		return
	scanned_player = true
	if not GameState.rep.may_scan(fit.gov):
		return
	view.spawn_fx(Fx.beam(position, pl.position, Color(0.5, 0.9, 1.0, 0.7), 1.5))
	GameState.log_msg("%s scans your ship (standing with the %s: Neutral). Nothing to report." % [display_name(), FactionData.name_of(fit.gov)], GameState.COL_INFO)


## Archetype state machines (package 14).
func _update_archetype(delta: float) -> void:
	match archetype:
		"raider":
			if target == null:
				_raid_t = 0.0
				_raid_break = false
				return
			_raid_t += delta
			var s := fit.stats()
			if not _raid_break and (_raid_t > ArchData.RAID_ATTACK or fit.shield < float(s["shield_max"]) * 0.3):
				_raid_break = true
				_raid_t = 0.0
			elif _raid_break and _raid_t > ArchData.RAID_BREAK:
				_raid_break = false
				_raid_t = 0.0
		"ambusher":
			if target != null and _ambush_t < 0.0:
				_ambush_t = 0.0
				if target.faction == "player":
					GameState.log_msg("Ambush! %s strikes from hiding." % display_name(), GameState.COL_BAD)
			elif _ambush_t >= 0.0:
				_ambush_t += delta
				if target == null and _ambush_t > 30.0:
					_ambush_t = -1.0       # back into hiding


## Speed factor of the archetype while fighting.
func _arch_speed() -> float:
	if archetype == "" or not ArchData.ARCHETYPES.has(archetype):
		return 1.0
	return float(ArchData.ARCHETYPES[archetype]["speed"])


## Ambusher: the far side of the nearest colossus (radar shadow), otherwise among the rocks at home.
func _hide_spot() -> Vector2:
	if _hide != Vector2.INF:
		return _hide
	_hide = home
	if view != null and "colossi" in view:
		var best := 80000.0
		for co in view.colossi:
			var d: float = co.position.distance_to(home)
			if d < best:
				best = d
				var out: Vector2 = co.position.normalized() if co.position.length() > 1.0 else Vector2.RIGHT
				_hide = co.position + out * (float(co.radius) * 0.8)
	_hide = clear_of_colossi(_hide)
	return _hide


## Coward: run, call for help once, then warp away.
func _start_fleeing(attacker) -> void:
	fleeing = true
	_flee_t = 0.0
	target = null
	if _called_help:
		return
	_called_help = true
	var n := 0
	for o in get_tree().get_nodes_in_group("ships"):
		if o == self or o.faction != "pirate" or o.dying or not o.is_targetable() or o.position.distance_to(position) > ArchData.HELP_RANGE:
			continue
		if attacker != null and is_instance_valid(attacker) and o.target == null:
			o.set_order({"type": "attack", "target": attacker})
			n += 1
	if view != null and view.player != null and is_instance_valid(view.player) and view.player.position.distance_to(position) < 80000.0:
		GameState.log_msg("%s breaks off and calls for help%s!" % [display_name(), (" – %d pirate%s answer" % [n, "" if n == 1 else "s"]) if n > 0 else ""], GameState.COL_WARN)


func _flee_point() -> Vector2:
	var from: Vector2 = last_attacker.position if _valid(last_attacker) else home
	var away := position - from
	if away.length() < 1.0:
		away = Vector2.from_angle(randf() * TAU)
	return position + away.normalized() * 6000.0


func _try_escape_warp() -> void:
	if warp_disrupted > 0.0 or view == null:
		return
	var options: Array = []
	for t in Universe.warp_targets(fit.system_id):
		if String(t["kind"]) in ["field", "anomaly", "gate", "planet"] and (t["pos"] as Vector2).distance_to(position) > Universe.WARP_MIN * 2.0:
			options.append(t)
	if options.is_empty():
		return
	var t: Dictionary = options[randi() % options.size()]
	home = t["pos"]
	_wander = Vector2.ZERO
	fleeing = false
	set_order({"type": "warp", "target": t, "then": {}})


func _lock_time(s: Dictionary) -> float:
	var sig: float = target.fit.stats()["signature"]
	return clampf(1.6 * sqrt(60.0 / maxf(sig, 5.0)) / maxf(float(s["resolution"]), 0.1), 0.3, 8.0)


# ---------------------------------------------------------------- Movement

func _update_movement(delta: float, s: Dictionary) -> void:
	var speed: float = float(s["speed"]) * afterburner_mult()
	if is_traffic():
		speed *= 0.6                 # traffic cruises at a relaxed pace
	var speed_factor := 1.0
	var dest = null
	var ot: String = order.get("type", "idle")
	match ot:
		"move":
			dest = order["pos"]
			speed_factor = float(order.get("pace", 1.0))   # < 1: slow patrol beat
			activity = "Flying" if speed_factor >= 1.0 else "Patrolling"
			if position.distance_to(dest) < 25.0:
				order = {"type": "idle"}
		"attack":
			if target != null:
				dest = _combat_point(s)
				activity = "Attacking: %s" % target.display_name()
		"dock":
			var st_node = order.get("node")
			if faction == "player" and st_node != null and is_instance_valid(st_node) and GameState.rep.dock_error(st_node.data) != "":
				GameState.log_msg(GameState.rep.dock_error(st_node.data), GameState.COL_WARN)
				order = {"type": "idle"}
				return
			if st_node != null and is_instance_valid(st_node) and st_node.has_method("has_pads") and st_node.has_pads():
				dest = _pad_approach(st_node)          # package 26: a waystation's landing pads
				if dest == null:
					return
			elif st_node != null and is_instance_valid(st_node):
				var bay: Dictionary = st_node.nearest_bay(position) if st_node.has_method("nearest_bay") else {}
				if bay.is_empty():
					dest = st_node.position
					if position.distance_to(dest) < 400.0:
						order = {"type": "docking", "node": st_node, "t": 0.0, "from": position}
						return
				else:
					# line up in front of the nearest hangar bay
					dest = (bay["mouth"] as Vector2) + (bay["dir"] as Vector2) * (radius * 1.3 + 260.0)
					if position.distance_to(dest) < 160.0:
						order = {"type": "docking", "node": st_node, "t": 0.0, "from": position, "bay": bay, "h0": heading}
						return
				activity = "Approaching for docking"
			else:
				order = {"type": "idle"}
		"docking":
			_update_docking(delta)
			return
		"undocking":
			_update_undocking(delta)
			return
		"approach", "orbit", "keep":
			var tn = order.get("node")
			if tn == null or not is_instance_valid(tn) or (tn is Ship and not tn.is_targetable()):
				order = {"type": "idle"}
			else:
				var npos: Vector2 = tn.position
				var away := position - npos
				if away.length() < 1.0:
					away = Vector2.RIGHT
				var r := float(order.get("r", 0.0))
				var nm: String = tn.display_name() if tn is Ship else tn.title()
				match ot:
					"approach":
						var stop := float(tn.radius) + radius + 40.0
						dest = npos + away.normalized() * stop
						activity = "Approaching %s" % nm
					"orbit":
						dest = npos + away.normalized().rotated(_orbit_sign * 0.45) * (r + float(tn.radius))
						activity = "Orbiting %s at %s" % [nm, SystemView.fmt_dist(r)]
					"keep":
						dest = npos + away.normalized() * (r + float(tn.radius))
						activity = "Keeping %s from %s" % [SystemView.fmt_dist(r), nm]
		"follow":
			var fn = order.get("node")
			if fn == null or not is_instance_valid(fn) or fn.dying or fn.is_docked():
				order = {"type": "idle"}
			elif fn.in_warp():
				if warp_disrupted <= 0.0:
					_follow_warp(fn, float(fn.warp["T"]) - float(fn.warp["t"]), fn.warp["to"], String(fn.warp.get("name", fn.display_name())))
					return
				activity = "Warp drive disrupted – cannot follow %s" % fn.display_name()
			else:
				var fr := float(order.get("r", 800.0))
				var gap: float = position.distance_to(fn.position)
				if gap > Universe.WARP_MIN and warp_disrupted <= 0.0:
					# fell far behind: catch up by warp
					_follow_warp(fn, 4.0 + gap / maxf(float(s["warp_speed"]), 1.0), fn.position, fn.display_name())
					return
				# fixed formation: a V behind the ship we follow (package 17 follow-up)
				dest = fn.position + formation_offset(fn).rotated(fn.heading)
				if gap > fr * 3.0:
					speed_factor = 1.0
				activity = "In formation with %s" % fn.display_name()
		"travel":
			dest = _travel(delta, s)
		"warp":
			dest = _warp_align(delta, s)
		"mine", "analyze", "salvage":
			var tn = order.get("node")
			var tool_kind: String = {"mine": "mining", "analyze": "analyzer", "salvage": "salvage"}[ot]
			var tool := fit.get_tool(tool_kind)
			if tool.is_empty() and tool_kind == "mining":
				tool = fit.get_tool("harvester")
			if tn == null or not is_instance_valid(tn) or tn.is_depleted() or tool.is_empty():
				order = {"type": "idle"}
			else:
				var rng := float(tool["range"])
				dest = tn.position if position.distance_to(tn.position) > rng * 0.75 else position
				activity = {"mine": "Mining", "analyze": "Analysing", "salvage": "Salvaging"}[ot]
	if order.get("type", "idle") == "idle":
		if fleeing:
			_flee_t += delta
			dest = _flee_point()
			speed_factor = _arch_speed()
			activity = "Fleeing"
			if _flee_t > 10.0 and (not _valid(last_attacker) or position.distance_to(last_attacker.position) > 3000.0 or _flee_t > 25.0):
				_try_escape_warp()
		elif not manual and target != null and fit.stance != "passive" and not s["weapons"].is_empty():
			dest = _combat_point(s)
			speed_factor = _arch_speed()
			activity = ("Breaking off" if _raid_break else "Engaging: %s" % target.display_name())
		elif faction == "pirate" and archetype == "ambusher" and _ambush_t < 0.0:
			dest = _hide_spot()
			speed_factor = 0.4
			activity = "Lurking"
		elif faction == "pirate":
			if _wander == Vector2.ZERO or position.distance_to(_wander) < 60.0:
				var wp: Vector2 = home + Vector2.from_angle(randf() * TAU) * randf_range(500.0, 4000.0)
				if view != null and view.has_method("clear_of_zones") and not raiding:
					wp = view.clear_of_zones(wp)
				_wander = clear_of_colossi(wp)
			dest = _wander
			speed_factor = 0.4
			activity = "Patrolling"
		else:
			activity = "Idle"

	var desired := Vector2.ZERO
	if dest != null and ot != "warp":
		dest = clear_of_colossi(dest)
		_check_stuck(delta, dest)
	if dest != null:
		var to: Vector2 = dest - position
		var dist := to.length()
		if dist > 4.0:
			var spd := speed * speed_factor
			var brake := spd * spd / (2.0 * maxf(float(s["accel"]), 1.0))
			if dist < brake:
				spd = spd * dist / brake
			desired = to / dist * spd
	desired = _avoid_colossi(desired)
	velocity = velocity.move_toward(desired, float(s["accel"]) * delta)
	position += velocity * delta
	_push_out_of_colossi()
	if position.length() > Universe.SYSTEM_RADIUS:
		position = position.normalized() * Universe.SYSTEM_RADIUS
	var face := heading
	if velocity.length() > 8.0:
		face = velocity.angle()
	elif target != null:
		face = (target.position - position).angle()
	heading = _rotate_toward(heading, face, float(s["turn"]) * delta)


## Safety distance kept from the surface of colossal asteroids.
func colossus_margin() -> float:
	return radius + 260.0


## A destination inside or right next to a colossus is moved out in front of its surface.
func clear_of_colossi(p: Vector2) -> Vector2:
	if view == null or not ("colossi" in view):
		return p
	var m := colossus_margin()
	for co in view.colossi:
		var lp: Vector2 = p - co.position
		if lp.length() > float(co.radius) + m:
			continue
		var surf := ColossusShape.surface(co.poly, lp)
		if float(surf[2]) < m:
			p = co.position + (surf[0] as Vector2) + (surf[1] as Vector2) * m
	return p


## Hardly getting anywhere while a colossus is in the way: go round the other side / pick a new spot.
func _check_stuck(delta: float, dest: Vector2) -> void:
	if position.distance_to(dest) < 300.0 or _avoid_side.is_empty():
		_stuck_t = 0.0
		_stuck_ref = position
		return
	_stuck_t += delta
	if _stuck_t < 4.0:
		return
	if position.distance_to(_stuck_ref) < 250.0:
		for k in _avoid_side:
			_avoid_side[k] = -float(_avoid_side[k])
		if not manual:
			_wander = Vector2.ZERO          # NPCs: choose another patrol point
			_orbit_sign = -_orbit_sign
	_stuck_t = 0.0
	_stuck_ref = position


## Steers around colossal asteroids that lie on the way (soft avoidance, no collision damage).
## Follows the rock's real outline at a safe distance, always round the same side until clear.
func _avoid_colossi(desired: Vector2) -> Vector2:
	if view == null or not ("colossi" in view) or view.colossi.is_empty() or desired.length() < 1.0:
		_avoid_side.clear()
		return desired
	var spd := desired.length()
	var dir := desired / spd
	var look := maxf(1100.0, spd * 4.0)
	var margin := colossus_margin()
	for co in view.colossi:
		var key: int = co.get_instance_id()
		var lp: Vector2 = position - co.position
		if lp.length() > float(co.radius) + margin + look:
			_avoid_side.erase(key)
			continue
		var surf := ColossusShape.surface(co.poly, lp)
		var sd: float = surf[2]
		var blocked := sd < margin
		if not blocked:
			for k in range(1, 8):
				if ColossusShape.signed_dist(co.poly, lp + dir * look * k / 7.0) < margin:
					blocked = true
					break
		var nrm: Vector2 = surf[1]
		if not blocked or (dir.dot(nrm) > 0.3 and sd > margin * 0.8):
			if sd > margin * 1.6:
				_avoid_side.erase(key)
			continue
		var tangent := nrm.orthogonal()
		if not _avoid_side.has(key):
			_avoid_side[key] = 1.0 if tangent.dot(dir) >= 0.0 else -1.0
		tangent *= float(_avoid_side[key])
		var w := clampf(1.0 - (sd - margin) / look, 0.4, 1.0)
		var nd := dir * (1.0 - w) + tangent * w
		# keep the distance: pushed outward when too close, pulled in a little when drifting away
		if sd < margin * 1.5:
			nd += nrm * clampf((margin - sd) / margin, -0.3, 1.0) * 0.8
		dir = nd.normalized()
	return dir * spd


## Never inside a colossus: slide along its surface instead.
func _push_out_of_colossi() -> void:
	if view == null or not ("colossi" in view):
		return
	var need := radius * 0.8
	for co in view.colossi:
		var lp: Vector2 = position - co.position
		if lp.length() > float(co.radius) + need:
			continue
		var surf := ColossusShape.surface(co.poly, lp)
		if float(surf[2]) < need:
			var n: Vector2 = surf[1]
			position = co.position + (surf[0] as Vector2) + n * need
			var vn := velocity.dot(n)
			if vn < 0.0:
				velocity -= n * vn


## Line of sight to another object (colossal asteroids block radar, locks and weapons).
func can_see(node) -> bool:
	if view == null or node == null or not is_instance_valid(node) or not ("colossi" in view):
		return true
	return view.line_of_sight(position, node.position)


static func _rotate_toward(from: float, to: float, step: float) -> float:
	var diff := wrapf(to - from, -PI, PI)
	return from + clampf(diff, -step, step)


func _combat_point(s: Dictionary) -> Vector2:
	var opt: float = s["optimal_range"]
	var away: Vector2 = position - target.position
	if away.length() < 1.0:
		away = Vector2.RIGHT
	var dir := away.normalized().rotated(_orbit_sign * 0.35)
	if ArchData.ARCHETYPES.has(archetype):
		match archetype:
			"raider":
				if _raid_break:
					return target.position + away.normalized().rotated(_orbit_sign * 0.7) * opt * 3.0
			"sniper":
				var far := 0.0
				for w in s["weapons"]:
					far = maxf(far, float(w["range"]))
				return target.position + away.normalized().rotated(_orbit_sign * 0.15) * maxf(far, opt) * float(ArchData.ARCHETYPES[archetype]["range"])
		opt *= float(ArchData.ARCHETYPES[archetype]["range"])
		opt = maxf(opt, radius + float(target.radius) + 60.0)
	return target.position + dir * opt


func _travel(delta: float, s: Dictionary):
	if fit.route.is_empty():
		order = {"type": "idle"}
		return null
	var next := int(fit.route[0])
	var gate = view.gates.get(next)
	if gate == null:
		fit.route.clear()
		order = {"type": "idle"}
		return null
	var d := position.distance_to(gate.position)
	if d > Universe.WARP_MIN:
		# Warp to the gate, then continue the journey
		var gid: String = gate.data["id"]
		set_order({"type": "warp", "target": Universe.warp_target(fit.system_id, gid), "then": {"type": "travel"}, "keep_route": true})
		return null
	activity = "Travelling to %s (%d jumps)" % [Universe.systems[int(fit.route.back())]["name"], fit.route.size()]
	if d > 400.0:
		spool = -1.0
		return gate.position
	if spool < 0.0 and fit.uid < 0:
		spool = 0.0            # NPCs (convoys) need no fuel bookkeeping
	if spool < 0.0:
		var err := GameState.can_jump(fit, next)
		if err != "":
			if faction == "player":
				GameState.warn("Jump to %s not possible: %s" % [Universe.systems[next]["name"], err])
			fit.route.clear()
			order = {"type": "idle"}
			return null
		spool = 0.0
	if spool == 0.0:
		view.announce_lead(self, "jump", String(Universe.systems[next]["name"]))
	spool += delta
	activity = "Jump drive spooling … %d%%" % int(spool / maxf(float(s["spool"]), 0.1) * 100.0)
	if spool >= float(s["spool"]):
		spool = -1.0
		fit.position = position
		if fit.uid < 0:
			view.npc_jump(self, next)
			return position
		view.spawn_fx(Fx.flash(position, Color(0.75, 0.45, 1.0), radius * 4.0))
		if faction == "player" and view.has_method("stow_all_drones"):
			view.stow_all_drones(self, true)   # drones come along and fly out again after the jump
		GameState.begin_jump(fit, next)
	return position


func align_time() -> float:
	var t := clampf(float(fit.stats()["mass"]) / 1200.0, 1.5, 6.0) * float(fit.stats().get("align_mult", 1.0))
	if is_traffic():
		t = maxf(t * 2.5, 6.0)       # civilians and patrols take their time before warping
	return t


## Civilian traffic and patrols (not pirates, not the player).
func is_traffic() -> bool:
	return fit.uid < 0 and faction in ["civilian", "patrol"]


## Arrival point of a warp target (in front of the object, from the approach direction).
func warp_destination(t: Dictionary) -> Vector2:
	var tp: Vector2 = t["pos"]
	var dir := (position - tp).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	return tp + dir * float(t["land"])


## Aligns to the warp target, accelerates and then engages warp.
func _warp_align(delta: float, s: Dictionary):
	var t: Dictionary = order.get("target", {})
	if t.is_empty():
		order = {"type": "idle"}
		return null
	var dest := warp_destination(t)
	var dist := position.distance_to(dest)
	if warp_disrupted > 0.0 and dist >= Universe.WARP_MIN:
		activity = "Warp drive disrupted (%d s)" % int(ceil(warp_disrupted))
		return position
	if dist < Universe.WARP_MIN:
		# too close for warp -> approach normally or run the follow-up order
		var then: Dictionary = order.get("then", {})
		if not then.is_empty():
			set_order(view.resolve_order(then))
		else:
			set_order({"type": "move", "pos": dest})
		return null
	if float(s["speed"]) <= 0.0:
		GameState.log_msg("%s: Cannot warp without an engine." % display_name(), GameState.COL_WARN)
		order = {"type": "idle"}
		return null
	var dir := (dest - position).normalized()
	if spool < 0.0:
		spool = 0.0
		view.announce_lead(self, "warp", String(t["name"]))
	spool += delta
	var at := align_time()
	# the ring and the percentage show the real time left: alignment time and the turn still needed
	var err := absf(wrapf(heading - dir.angle(), -PI, PI))
	var turn_left := maxf(err - 0.3, 0.0) / maxf(float(s["turn"]), 0.01)
	spool_need = maxf(at, spool + turn_left)
	activity = "Aligning: warp → %s  %d%%" % [t["name"], int(minf(spool / spool_need, 1.0) * 100.0)]
	if spool >= at and err < 0.3:
		spool = -1.0
		var T := (4.0 + dist / group_warp_speed(float(s["warp_speed"]))) * float(t.get("slow", 1.0))
		warp = {"from": position, "to": dest, "t": 0.0, "T": T, "then": order.get("then", {}), "name": t["name"]}
		target = null
		clear_locks()
		order = {"type": "warping"}
		view.spawn_fx(Fx.flash(position, Color(0.6, 0.85, 1.0), radius * 3.0))
		view.on_warp_started(self)
		# the whole formation goes into warp in the same instant
		if view.has_method("followers_of"):
			for f in view.followers_of(self).duplicate():
				if is_instance_valid(f) and not f.in_warp() and f.warp_disrupted <= 0.0 and String(f.order.get("type", "")) == "follow":
					f._follow_warp(self, T, dest, String(t["name"]))
		return null
	return position + dir * 5000.0


## Warp speed of the group: everyone following this ship (directly or along a chain) warps with
## it, so the slowest ship of the group sets the pace.
func group_warp_speed(own: float) -> float:
	var v := own
	var seen := {self: true}
	var todo: Array = [self]
	while not todo.is_empty():
		var lead = todo.pop_back()
		for n in view.ship_layer.get_children():
			if n is Ship and not seen.has(n) and not n.dying and not n.is_docked() and String(n.order.get("type", "")) == "follow" and n.order.get("node") == lead:
				seen[n] = true
				todo.append(n)
				v = minf(v, float(n.fit.stats()["warp_speed"]))
	return maxf(v, 1.0)


## Follow (package 17): jump straight into warp with the ship we follow – no aligning – so that both
## arrive together. Arrival continues following.
func _follow_warp(fn, remaining: float, to: Vector2, wname: String) -> void:
	var r := float(order.get("r", 800.0))
	var wdir: float = (to - fn.position).angle() if fn.position.distance_to(to) > 1.0 else fn.heading
	var land: Vector2 = to + formation_offset(fn).rotated(wdir)
	warp = {"from": position, "to": land, "t": 0.0, "T": maxf(remaining, 2.0) + 0.5, "then": {"type": "follow", "node": fn, "r": r},
		"name": wname, "follow": fn, "formation": fn.in_warp(), "off0": position - fn.position}
	target = null
	if faction == "player":
		clear_locks()
	order = {"type": "warping"}
	spool = -1.0
	view.spawn_fx(Fx.flash(position, Color(0.6, 0.85, 1.0), radius * 3.0))
	view.on_warp_started(self)


## Pulled out of warp (pirate interdiction): stops right here, the drive needs a moment.
func drop_out_of_warp(disrupt: float = 15.0) -> void:
	if warp.is_empty():
		return
	var then: Dictionary = warp.get("then", {})
	warp = {}
	velocity = Vector2.ZERO
	order = {"type": "idle"}
	warp_disrupted = maxf(warp_disrupted, disrupt)
	view.spawn_fx(Fx.flash(position, Color(1.0, 0.4, 0.3), radius * 4.0))
	view.on_warp_finished(self)
	if String(then.get("type", "")) == "follow":
		set_order(then)


func warp_progress() -> float:
	if warp.is_empty():
		return 0.0
	return clampf(float(warp["t"]) / float(warp["T"]), 0.0, 1.0)


## Warp profile: fast acceleration, long cruise, gentle deceleration.
static func warp_ease(p: float) -> float:
	return p * p * p * (p * (p * 6.0 - 15.0) + 10.0)


func _update_warp(delta: float) -> void:
	if warp_frozen:
		velocity = Vector2.ZERO
		activity = "Caught by a warp interdictor!"
		return
	# interdiction: held in warp ~2 s short of the target until the timing game is decided
	var held: bool = warp.get("hold", false) and view != null and view.has_method("interdict_running") and view.interdict_running() \
		and float(warp["T"]) - float(warp["t"]) - delta <= 2.0
	if not held:
		warp["t"] = float(warp["t"]) + delta
	_warp_frame = Engine.get_physics_frames()
	if warp.get("formation", false):
		_formation_warp(delta)
		return
	var p := warp_progress()
	var from: Vector2 = warp["from"]
	var to: Vector2 = warp["to"]
	var np := from.lerp(to, warp_ease(p))
	velocity = (np - position) / maxf(delta, 0.0001)
	position = np
	heading = (to - from).angle()
	activity = "In warp → %s  (%d s)" % [warp["name"], int(ceil(float(warp["T"]) - float(warp["t"])))]
	if p >= 1.0:
		var then: Dictionary = warp["then"]
		warp = {}
		velocity = (to - from).normalized() * float(fit.stats()["speed"]) * 0.3
		order = {"type": "idle"}
		view.spawn_fx(Fx.flash(position, Color(0.6, 0.85, 1.0), radius * 3.0))
		view.on_warp_finished(self)
		if not then.is_empty():
			set_order(view.resolve_order(then))


const FORMATION_GAP := 380.0
var _warp_frame := -1            # physics frame of the last warp step (formation followers sync to it)


## Slot of this ship in the V formation behind the ship it follows (x = forward). The pilot takes
## the first slot, the others follow in a fixed order, alternating left and right.
func formation_offset(fn) -> Vector2:
	var mates: Array = view.followers_of(fn) if view != null and view.has_method("followers_of") else []
	var i := maxi(mates.find(self), 0)
	var row := i / 2 + 1
	var side := -1.0 if i % 2 == 0 else 1.0
	var gap := FORMATION_GAP + float(fn.radius) + radius
	return Vector2(-row * gap * 0.8, side * row * gap * 0.7)


## Warp in formation: glued to the slot next to the lead for the whole warp (blending in over the
## first 1.5 s); it ends when the lead's warp ends.
func _formation_warp(delta: float) -> void:
	var fn = warp.get("follow")
	if fn == null or not is_instance_valid(fn) or fn.dying:
		# lead lost: finish the warp on our own from here
		warp["formation"] = false
		warp["from"] = position
		warp["T"] = maxf(float(warp["T"]) - float(warp["t"]), 2.0)
		warp["t"] = 0.0
		return
	if not fn.in_warp():
		var then: Dictionary = warp["then"]
		var vel: Vector2 = fn.velocity
		warp = {}
		velocity = vel
		order = {"type": "idle"}
		view.spawn_fx(Fx.flash(position, Color(0.6, 0.85, 1.0), radius * 3.0))
		view.on_warp_finished(self)
		if not then.is_empty():
			set_order(view.resolve_order(then))
		return
	var slot: Vector2 = formation_offset(fn).rotated(fn.heading)
	var k := smoothstep(0.0, 1.5, float(warp["t"]))
	# the lead may not have moved yet this frame (e.g. the pilot's ship is updated first): use where
	# it will be, so the slot stays exact for the whole warp
	var lead_pos: Vector2 = fn.position
	if fn._warp_frame != Engine.get_physics_frames():
		lead_pos += fn.velocity * delta
	var np: Vector2 = lead_pos + (warp["off0"] as Vector2).lerp(slot, k)
	velocity = (np - position) / maxf(delta, 0.0001)
	position = np
	heading = fn.heading
	activity = "In warp, in formation → %s  (%d s)" % [warp["name"], int(ceil(float(fn.warp["T"]) - float(fn.warp["t"])))]


# ---------------------------------------------------------------- Weapons

func _update_weapons(delta: float, s: Dictionary) -> void:
	var weapons: Array = s["weapons"]
	if cloaked():
		return
	if weapon_timers.size() != weapons.size():
		weapon_timers.resize(weapons.size())
		weapon_timers.fill(0.0)
	for i in weapons.size():
		weapon_timers[i] = maxf(0.0, float(weapon_timers[i]) - delta)
	if manual:
		return
	if target == null or not _valid(target):
		return
	if fit.stance == "passive" and order.get("type") != "attack":
		return
	if lock_progress < 1.0:
		return
	if not can_see(target):
		return
	if emp_t > 0.0:
		return
	var dist := position.distance_to(target.position)
	if jammed_t > 0.0 and dist > lock_range(s):
		return
	var tlist: Array = [target]
	for f2 in _focus:
		if _valid(f2) and f2 != target and can_see(f2):
			tlist.append(f2)
	for i in weapons.size():
		var w: Dictionary = weapons[i]
		if weapon_timers[i] > 0.0 or not w.get("powered", true):
			continue
		# multi-focus (package 22): weapons are shared out over the targets; out of reach → primary
		var tg = tlist[i % tlist.size()]
		var td: float = position.distance_to(tg.position)
		if td > float(w["range"]) or (jammed_t > 0.0 and td > lock_range(s)):
			tg = target
			td = dist
		if td > float(w["range"]):
			continue
		if fit.capacitor < float(w["energy"]):
			continue
		fit.capacitor -= float(w["energy"])
		weapon_timers[i] = float(w["cooldown"]) * randf_range(0.95, 1.08)
		if archetype == "ambusher" and _ambush_t >= 0.0 and _ambush_t < ArchData.AMBUSH_TIME:
			w = w.duplicate()
			w["damage"] = float(w["damage"]) * ArchData.AMBUSH_BONUS
		if special == "overcharged":
			weapon_timers[i] = float(weapon_timers[i]) * 0.6
		if special == "shield_breaker" and tg.fit.shield > 0.0:
			w = w.duplicate()
			w["damage"] = float(w["damage"]) * 1.6
		view.fire_weapon(self, tg, w)
		combat_t = 5.0
		if not _valid(target):
			target = null
			return


func take_damage(amount: float, dtype: String, attacker) -> void:
	if dying or is_docked() or in_station():
		return
	if faction == "player" and Commands.god_mode:
		return
	amount *= toughness               # captains are tougher than ordinary pirates (by stars)
	if special == "iron_hide":
		amount *= 0.6
	if attacker != null and is_instance_valid(attacker):
		last_attacker = attacker
		if attacker is Ship and attacker.faction == "player" and faction != "player":
			_hit_by_player()
			if raiding and view != null and view.has_method("note_raid_help"):
				view.note_raid_help(self)
		if attacker is Ship and faction in ["civilian", "patrol"] and GameState.play_time - _distress_t > 25.0 and view != null and view.has_method("on_ship_attacked"):
			_distress_t = GameState.play_time
			view.on_ship_attacked(self, attacker)
	var raw := amount
	combat_t = 5.0
	var sh0 := fit.shield
	var hull0 := fit.armor + fit.structure
	if fit.shield > 0.0:
		var m: float = GameData.LAYER_MULT["shield"][dtype]
		var d := raw * m
		if d <= fit.shield:
			fit.shield -= d
			raw = 0.0
		else:
			raw = (d - fit.shield) / m
			fit.shield = 0.0
	if sh0 > 0.0 and fit.shield <= 0.0:
		shield_collapse()
	var armor0 := fit.armor
	if raw > 0.0 and fit.armor > 0.0:
		var res: float = fit.stats()["res"][dtype]
		var m2: float = float(GameData.LAYER_MULT["armor"][dtype]) * (1.0 - res)
		var d2 := raw * m2
		if d2 <= fit.armor:
			fit.armor -= d2
			raw = 0.0
		else:
			raw = (d2 - fit.armor) / maxf(m2, 0.01)
			fit.armor = 0.0
	if raw > 0.0:
		fit.structure -= raw * float(GameData.LAYER_MULT["structure"][dtype])
	_reflect(armor0 - fit.armor, dtype, attacker)
	hit_flash = 0.12
	_show_damage(sh0 - fit.shield, hull0 - (fit.armor + maxf(fit.structure, 0.0)))
	if fit.structure <= 0.0:
		_die(attacker)
		return
	if archetype == "coward" and not fleeing and not manual:
		var st := fit.stats()
		if fit.armor + fit.structure < (float(st["armor_max"]) + float(st["structure_max"])) * ArchData.COWARD_FLEE:
			_start_fleeing(attacker)


## Package 25d (Hadrian Dynamics): the reflective hull sends a share of the damage that hit the
## armour back to the attacker (shields do not reflect). Reflected damage has no attacker of its own,
## so it never bounces back again and never counts as an attack.
func _reflect(armor_dmg: float, dtype: String, attacker) -> void:
	var share := float(fit.stats().get("reflect", 0.0))
	if share <= 0.0 or armor_dmg <= 0.0 or attacker == null or not is_instance_valid(attacker) or not attacker is Ship or attacker == self:
		return
	attacker.take_damage(armor_dmg * share, dtype, null)
	last_reflected = armor_dmg * share
	if view != null and view.sky_alpha() >= 0.5:
		view.spawn_fx(Fx.flash(attacker.position, Color(1.0, 0.35, 0.25), attacker.radius * 0.5))


## The pilot opened fire on this NPC: it (and its faction, for a while) fights back; shooting a
## ship that was not hostile costs standing with its faction (package 12).
func _hit_by_player() -> void:
	if provoked:
		return
	var was_hostile := hostile_to_player()
	provoked = true
	if not was_hostile:
		GameState.rep.on_attack(fit.gov, display_name())
		if faction in ["civilian", "patrol"]:
			innocent = true
			GameState.law.offence(GameState.law.authority(fit.system_id, fit.gov), "attack_" + faction, "attack on the %s" % display_name())


## Floating numbers over the hit ship – only in the local zoom levels.
func _show_damage(shield_dmg: float, hull_dmg: float) -> void:
	if view == null or view.sky_alpha() < 0.5:
		return
	if shield_dmg > 0.05:
		view.spawn_fx(Fx.damage_number(position, shield_dmg, Color(0.45, 0.75, 1.0)))
	if hull_dmg > 0.05:
		view.spawn_fx(Fx.damage_number(position + Vector2(10.0, -6.0), hull_dmg, Color(1.0, 0.35, 0.3)))


func _die(killer) -> void:
	if dying:
		return
	dying = true
	destroyed.emit(self)
	view.on_ship_destroyed(self, killer)
	queue_free()


# ---------------------------------------------------------------- Tools

func _update_tools(delta: float, s: Dictionary) -> void:
	tool_beams.clear()
	if emp_t > 0.0:
		return
	if manual:
		_update_modules(delta, s)
		return
	for t in s["tools"]:
		if not t.get("powered", true):
			continue
		match t["tool"]:
			"repair":
				_repair(delta, t)
			"shield_transfer":
				_npc_transfer(delta, t)
			"mining", "harvester":
				if order.get("type") == "mine" and not _mine(delta, t, order.get("node")):
					order = {"type": "idle"}
				elif order.get("type") == "mine" and fit.hull().has("refinery"):
					smoke(delta)
			"analyzer":
				if order.get("type") == "analyze" and not _progress_tool(delta, t, "analysis", Color(0.8, 0.5, 1.0), order.get("node")):
					order = {"type": "idle"}
			"salvage":
				if order.get("type") == "salvage" and not _progress_tool(delta, t, "salvage", Color(0.6, 1.0, 0.6), order.get("node")):
					order = {"type": "idle"}


## Ordinary mining lasers struggle with ice (ice harvesters come with phase 0.5 package 7).
const ICE_LASER_MULT := 0.25


static func mining_mult(t: Dictionary, ore: String) -> float:
	var cls: String = GameData.commodities.get(ore, {}).get("class", "")
	if t.get("tool", "") == "harvester":
		return 1.0 if cls == "icy" else 0.0
	if cls == "icy" and t.get("tool", "") == "mining":
		return ICE_LASER_MULT
	return 1.0


## Speed multiplier from switched-on afterburners.
func afterburner_mult() -> float:
	var m := 1.0
	if module_on.is_empty():
		return m
	for a in fit.stats()["actives"]:
		if a["active"] == "afterburner" and module_on.get(a["slot"], false):
			m *= float(a["boost"])
	return m


## Returns false when mining must stop (target gone or depleted, hold full).
func _mine(delta: float, t: Dictionary, node) -> bool:
	if node == null or not is_instance_valid(node) or node.is_depleted():
		return false
	if position.distance_to(node.position) > float(t["range"]):
		return true
	var ore: String = node.data["ore"]
	var cls: String = GameData.commodities.get(ore, {}).get("class", "")
	var bonus := 1.0 + float(fit.stats()["mining_bonus"].get(cls, 0.0))
	var amount := minf(float(t["rate"]) * mining_mult(t, ore) * bonus * float(fit.stats()["power_ratio"]) * delta, float(node.data["amount"]))
	# Mixed asteroids yield their ores in proportion ("mix": ore -> share)
	var mix: Dictionary = node.data.get("mix", {ore: 1.0})
	var added := 0.0
	for o in mix:
		added += fit.add_cargo(o, amount * float(mix[o]))
	if added <= 0.0:
		if faction == "player":
			GameState.log_msg("%s: cargo hold full." % display_name(), GameState.COL_WARN)
		return false
	node.data["amount"] = float(node.data["amount"]) - added
	if faction == "player":
		GameState.stats["mined"] = float(GameState.stats["mined"]) + added
		GameState.codex.event("mining")
	var beam_col := Color(0.45, 0.9, 1.0) if t.get("tool", "") == "harvester" else Color(1.0, 0.62, 0.25)
	tool_beams.append([node.position, beam_col, "mining", float(node.radius)])
	# floating "+x Ore" numbers over the asteroid, about once per second
	if faction == "player":
		var share_total := 0.0
		for o2 in mix:
			share_total += float(mix[o2])
		for o3 in mix:
			_mine_acc[o3] = float(_mine_acc.get(o3, 0.0)) + added * float(mix[o3]) / maxf(share_total, 0.001)
		_mine_t += delta
		if _mine_t >= 1.0:
			_mine_t = 0.0
			var k := 0
			for o4 in _mine_acc:
				if float(_mine_acc[o4]) >= 0.05 and view != null and view.sky_alpha() >= 0.5:
					var oc: Color = SystemView.FIELD_COLORS.get(GameData.commodities.get(o4, {}).get("class", ""), Color(1.0, 0.8, 0.4))
					view.spawn_fx(Fx.float_text(node.position + Vector2(0.0, -float(node.radius) * 0.6 - k * 22.0), "+%.1f %s" % [float(_mine_acc[o4]), GameData.item_name(o4)], oc))
					k += 1
			_mine_acc.clear()
	if node.is_depleted():
		node.queue_redraw()
		return false
	return true


## Analyser / salvager progress. Returns false when finished or the target is gone.
func _progress_tool(delta: float, t: Dictionary, field: String, col: Color, node) -> bool:
	if node == null or not is_instance_valid(node) or node.is_depleted():
		return false
	if position.distance_to(node.position) > float(t["range"]):
		return true
	var duration := 10.0
	if field == "analysis":
		duration = float(node.data["difficulty"])
	node.data[field] = float(node.data.get(field, 0.0)) + float(t["rate"]) * delta * 100.0 / duration
	tool_beams.append([node.position, col])
	if float(node.data[field]) >= 100.0:
		if field == "analysis":
			view.complete_anomaly(node, self)
		else:
			view.complete_salvage(node, self)
		return false
	return true


# ---------------------------------------------------------------- Manual control: locks

static func object_key(node) -> String:
	if node is Ship:
		return "ship:%d" % node.fit.uid
	return String(node.data.get("id", ""))


func lock_index(key: String) -> int:
	for i in locks.size():
		if locks[i]["key"] == key:
			return i
	return -1


## Locked and fully acquired node for `key` (or the active lock), else null.
func locked_node(key: String = ""):
	if key == "":
		key = active_lock
	var i := lock_index(key)
	if i < 0 or float(locks[i]["progress"]) < 1.0:
		return null
	return locks[i]["node"]


static func lockable(node) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	if node is Ship:
		return node.is_targetable()
	return node.kind in ["asteroid", "wreck", "anomaly"] and not node.is_depleted()


func add_lock(node) -> String:
	if not lockable(node):
		return "That cannot be targeted."
	var key := object_key(node)
	if lock_index(key) >= 0:
		active_lock = key
		return ""
	var maxl := max_locks()
	if locks.size() >= maxl:
		return "Maximum of %d targets locked (bigger sensor suites hold more)." % maxl
	var sr := lock_range(fit.stats())
	if position.distance_to(node.position) > sr:
		return ("Out of sensor range (%s)." % SystemView.fmt_dist(sr)) + (" Your radar is jammed." if jammed_t > 0.0 else "")
	var bl = view.blocker(position, node.position) if "colossi" in view else null
	if bl != null:
		return "No line of sight – %s is in the radar shadow of %s." % [node_name(node), bl.title()]
	locks.append({"key": key, "node": node, "progress": 0.0})
	active_lock = key                  # a new lock becomes the active target
	_relock.erase(key)
	_mlog("Locking %s … (%.1f s)" % [node_name(node), _lock_duration(node, fit.stats())])
	return ""


## How many targets can be locked at once (package 22: by the size of the sensor suite, 3–6).
func max_locks() -> int:
	return maxi(int(fit.stats().get("max_locks", MAX_LOCKS)), MAX_LOCKS)


## Lock number (1, 2, …) of `key`, 0 = not locked.
func lock_number(key: String) -> int:
	return lock_index(key) + 1


## Multi-focus: modules switched on and working on lock `key`.
func modules_on(key: String) -> int:
	var n := 0
	for slot in module_on:
		if module_on[slot] and String(module_target.get(slot, "")) == key:
			n += 1
	return n


## A running module switches to the active target (package 22). "" = done.
func retarget(slot: String) -> String:
	var e := find_module(slot)
	if e.is_empty() or not e["kind"] in ["weapon", "tool"]:
		return "That module has no target."
	var node = locked_node()
	if node == null:
		return "No complete lock to switch to."
	var err := module_target_error(e, node)
	if err != "":
		return "%s: %s is not a valid target – %s" % [e["data"]["name"], node_name(node), err]
	module_target[slot] = active_lock
	scan_jobs.erase(slot)
	_mlog("%s → %s" % [e["data"]["name"], node_name(node)])
	return ""


## A target that left the sensor range (or went into a radar shadow): its modules stay on and wait;
## it is locked again automatically when it comes back (within RELOCK_TIME).
func _remember_lock(key: String, n) -> void:
	var was_active := active_lock == key
	remove_lock(key)
	if modules_on(key) > 0:
		_relock[key] = {"node": n, "until": GameState.play_time + RELOCK_TIME, "active": was_active}


func _relock_note(key: String) -> String:
	var m := modules_on(key)
	return (" – %d module%s wait and resume when it is back" % [m, "" if m == 1 else "s"]) if m > 0 else ""


func _update_relock(sr: float) -> void:
	for key in _relock.keys():
		var r: Dictionary = _relock[key]
		var n = r["node"]
		if GameState.play_time > float(r["until"]) or not lockable(n) or modules_on(key) == 0:
			_relock.erase(key)
			continue
		if lock_index(key) >= 0 or locks.size() >= max_locks() or position.distance_to(n.position) > sr:
			continue
		if view.blocker(position, n.position) if "colossi" in view else null:
			continue
		var keep := active_lock
		locks.append({"key": key, "node": n, "progress": 0.0})
		if not r.get("active", false) and keep != "":
			active_lock = keep
		elif r.get("active", false) or active_lock == "":
			active_lock = key
		_relock.erase(key)
		_mlog("%s back in sensor range – locking it again." % node_name(n), GameState.COL_INFO)


## Modules on `key` that wait for it: lost out of range (re-lock pending) or still locking.
func waiting_for(key: String) -> bool:
	if _relock.has(key):
		return true
	var i := lock_index(key)
	return i >= 0 and float(locks[i]["progress"]) < 1.0


func remove_lock(key: String) -> void:
	var i := lock_index(key)
	if i >= 0:
		locks.remove_at(i)
	if active_lock == key:
		active_lock = locks[0]["key"] if not locks.is_empty() else ""


func _lock_duration(node, s: Dictionary) -> float:
	var sig := 120.0
	if node is Ship:
		sig = float(node.fit.stats()["signature"])
	var t := clampf(1.6 * sqrt(60.0 / maxf(sig, 5.0)) / maxf(float(s["resolution"]), 0.1), 0.3, 8.0)
	if node is Ship and node.special == "ghost":
		t *= 2.5
	return t


func _update_locks(delta: float, s: Dictionary) -> void:
	var sr := lock_range(s)
	for l in locks.duplicate():
		var n = l["node"]
		var shadow = view.blocker(position, n.position) if (lockable(n) and "colossi" in view) else null
		if shadow != null:
			_mlog("Lock on %s lost – hidden behind %s (radar shadow)%s." % [node_name(n), shadow.title(), _relock_note(l["key"])], GameState.COL_WARN)
			_remember_lock(l["key"], n)
			continue
		if not lockable(n) or position.distance_to(n.position) > sr * 1.25:
			if n == null or not is_instance_valid(n) or (n is Ship and n.dying):
				_mlog("Target destroyed – lock released.")
			elif not lockable(n):
				_mlog("Lock on %s released (nothing left to target)." % node_name(n))
			else:
				_mlog("Lock on %s broken – out of sensor range (%s)%s." % [node_name(n), SystemView.fmt_dist(sr * 1.25), _relock_note(l["key"])], GameState.COL_WARN)
				_remember_lock(l["key"], n)
				continue
			remove_lock(l["key"])
			continue
		var was := float(l["progress"])
		l["progress"] = minf(1.0, was + delta / _lock_duration(n, s))
		if was < 1.0 and float(l["progress"]) >= 1.0:
			_mlog("Target locked: %s%s" % [node_name(n), "  (active target)" if l["key"] == active_lock else ""], GameState.COL_GOOD)
	_update_relock(sr)
	# legacy fields for drawing / HUD: the active lock if it is a ship
	var i := lock_index(active_lock)
	target = null
	lock_progress = 0.0
	if i >= 0 and locks[i]["node"] is Ship:
		target = locks[i]["node"]
		lock_progress = locks[i]["progress"]


# ---------------------------------------------------------------- Manual control: modules

## Reason why module entry `e` cannot work on `node` ("" = it can).
func module_target_error(e: Dictionary, node) -> String:
	var d: Dictionary = e["data"]
	if e["kind"] == "weapon":
		if node == null:
			return "No target locked."
		if not (node is Ship) or node.faction == "player":
			return "%s needs a ship as target." % d["name"]
		return ""
	if e["kind"] in ["self", "pd", "mine"]:
		return ""
	match String(d["tool"]):
		"repair":
			return ""   # repairs the locked friendly ship, otherwise your own
		"shield_transfer":
			if node == null or not (node is Ship) or node == self or hostile(self, node):
				return "%s needs a locked friendly ship." % d["name"]
		"cargo_scan":
			if node == null or not (node is Ship) or node.faction == "player":
				return "%s needs a locked ship." % d["name"]
		"survey", "interdict":
			return ""   # aimed at the selection, checked when switched on
		"mining", "prospect":
			if node == null or node is Ship or node.kind != "asteroid":
				return "%s needs a locked asteroid." % d["name"]
		"harvester":
			if node == null or node is Ship or node.kind != "asteroid":
				return "%s needs a locked icy asteroid." % d["name"]
			if mining_mult(d, String(node.data["ore"])) <= 0.0:
				return "%s only works on icy asteroids." % d["name"]
		"warrant":
			if node == null or not (node is Ship) or node.faction == "player":
				return "%s needs a locked NPC ship." % d["name"]
		"analyzer":
			if node == null or node is Ship or node.kind != "anomaly":
				return "%s needs a locked anomaly." % d["name"]
		"salvage":
			if node == null or node is Ship or node.kind != "wreck":
				return "%s needs a locked wreck." % d["name"]
	return ""


## Combat/tool log for the player's ship only.
func _mlog(text: String, col: Color = GameState.COL_INFO) -> void:
	if manual and faction == "player":
		GameState.log_msg(text, col)


static func node_name(n) -> String:
	if n == null or not is_instance_valid(n):
		return "target"
	return n.display_name() if n is Ship else n.title()


func _switch_off(slot: String, d: Dictionary, why: String) -> void:
	module_on[slot] = false
	module_state[slot] = "off"
	_mlog("%s switched off – %s." % [d["name"], why], GameState.COL_WARN)


func find_module(slot: String) -> Dictionary:
	for e in fit.active_modules():
		if e["slot"] == slot:
			return e
	return {}


func set_module_active(slot: String, on: bool) -> String:
	var e := find_module(slot)
	if e.is_empty():
		return "No activatable module in that slot."
	var d: Dictionary = e["data"]
	if on and emp_t > 0.0:
		return "EMP – all modules are dead for another %d s." % int(ceil(emp_t))
	if on and e["kind"] == "mine":
		return lay_mine(slot, d)
	if e["kind"] == "pd":
		module_on[slot] = on
		module_state[slot] = "on" if on else "off"
		_keep_on(slot, on)
		_mlog("%s %s." % [d["name"], "on – shooting down missiles and mines in range" if on else "off"])
		return ""
	if e["kind"] == "self" and String(d.get("active", "")) == "cloak":
		if on and fit.capacitor < float(d["energy_rate"]):
			return "%s: not enough energy." % d["name"]
		if on:
			module_on.clear()                   # every other module goes quiet – the target locks stay
			fit.held_on.clear()
			for k in module_state.keys():
				module_state[k] = "off"
		module_on[slot] = on
		module_state[slot] = "on" if on else "off"
		_mlog("%s %s." % [d["name"], "on – you are invisible; using a weapon, tool or module ends it" if on else "off – you are visible again"])
		return ""
	if on and cloaked():
		# 0.4.25.40: a weapon, tool or module that really switches on ends the cloak (one that is refused –
		# a lock still running, too little energy – leaves the ship cloaked)
		module_on["builtin_cloak"] = false
		var err := set_module_active(slot, on)
		module_on["builtin_cloak"] = true
		if err != "":
			return err
		decloak(String(d["name"]))
		return ""
	if e["kind"] == "self" and String(d.get("active", "")) == "auto_fire":
		# package 25f: the Cathedral's focus lasers fire on their own – at enemies and at the targets
		# locked right now
		module_on[slot] = on
		module_state[slot] = "on" if on else "off"
		_keep_on(slot, on)
		auto_targets = []
		if on:
			for l in locks:
				if l.get("node") != null and is_instance_valid(l["node"]) and l["node"] is Ship:
					auto_targets.append(l["node"])
		_mlog("%s %s." % [d["name"], ("on – the focus lasers fire at up to %d enemies%s" % [int(d.get("targets", 6)), (" and the %d locked targets" % auto_targets.size()) if not auto_targets.is_empty() else ""]) if on else "off"])
		return ""
	if e["kind"] == "self" and String(d.get("active", "")) == "drone_pulse":
		module_on[slot] = on
		module_state[slot] = "on" if on else "off"
		_keep_on(slot, on)
		_mlog("%s %s." % [d["name"], ("on – a pulse every %d s knocks out every drone within %s, friend or foe" % [int(d["interval"]), SystemView.fmt_dist(float(d["range"]))]) if on else "off"])
		return ""
	if e["kind"] == "self" and String(d.get("active", "")) in ["refinery", "factory", "market"]:
		_set_builtin_on(String(d["active"]), on)
		module_on[slot] = on
		module_state[slot] = "on" if on else "off"
		var what := {"refinery": "running – ore from the hold is refined bit by bit", "factory": "running – works through its queue (Ship menu → Industry)",
			"market": "open – traders in the system come to buy (Ship menu → Market)"}
		_mlog("%s %s." % [d["name"], what[d["active"]] if on else "switched off"])
		return ""
	if on and e["kind"] == "self":
		if fit.capacitor < float(d["energy_rate"]):
			return "%s: not enough energy (needs %.0f per second, capacitor %.0f)." % [d["name"], float(d["energy_rate"]), fit.capacitor]
		module_on[slot] = true
		module_state[slot] = "on"
		_mlog("%s switched on (%.0f energy/s)." % [d["name"], float(d["energy_rate"])])
		return ""
	if on and e["kind"] == "tool" and d["tool"] == "survey":
		return _start_survey(slot, d)
	if on and e["kind"] == "tool" and d["tool"] == "interdict":
		return _start_interdict(slot, d)
	if not on and e["kind"] == "tool" and d["tool"] == "interdict" and module_on.get(slot, false):
		return "%s: the interdiction is running – finish the timing game." % d["name"]
	if on:
		var node = locked_node()
		if node == null and active_lock != "":
			var i := lock_index(active_lock)
			return "%s: still locking %s (%d%%) – wait for the lock to complete." % [d["name"], node_name(locks[i]["node"]), int(float(locks[i]["progress"]) * 100.0)]
		var err := module_target_error(e, node)
		if err != "":
			if node == null:
				return "%s: no target locked – click an object and choose \"Lock target\"." % d["name"]
			return "%s: %s is not a valid target – %s" % [d["name"], node_name(node), err]
		if e["kind"] == "tool" and d["tool"] in ["prospect", "warrant", "cargo_scan"]:
			if fit.capacitor < float(d.get("energy", 0)):
				return "%s: not enough energy (needs %s, capacitor %.0f)." % [d["name"], str(d["energy"]), fit.capacitor]
			fit.capacitor -= float(d.get("energy", 0))
			scan_jobs.erase(slot)
		module_on[slot] = true
		module_state[slot] = "on"
		module_target[slot] = active_lock      # multi-focus: it keeps this target (package 22)
		if not fit.is_powered(slot):
			_mlog("%s: priority group %d is shut down (power overload) – it starts once there is power." % [d["name"], fit.priority_of(slot)], GameState.COL_WARN)
		var tgt = node
		if e["kind"] == "tool" and d["tool"] == "repair" and (tgt == null or not (tgt is Ship) or hostile(self, tgt)):
			tgt = self
		var msg := "%s activated → %s" % [d["name"], "your own ship" if tgt == self else node_name(tgt)]
		if e["kind"] == "tool" and tgt != self and not (tgt is Ship) and tgt.kind == "asteroid" and mining_mult(d, String(tgt.data["ore"])) < 1.0:
			msg += "  (ice: mining lasers only work at %d%% – an ice harvester is far better)" % int(ICE_LASER_MULT * 100.0)
		if tgt != self:
			var dist := position.distance_to(tgt.position)
			if dist > float(d["range"]):
				msg += "  (out of range: %s, range %s – starts when you get closer)" % [SystemView.fmt_dist(dist), SystemView.fmt_dist(float(d["range"]))]
				module_state[slot] = "range"
		_mlog(msg)
		if e["kind"] == "weapon" and view != null and view.has_method("warn_zone"):
			view.warn_zone(node)
		if e["kind"] == "weapon" and node is Ship and not node.hostile_to_player():
			var gov: String = node.fit.gov
			_mlog("Warning: %s is not hostile%s." % [node.display_name(), (" – attacking it costs standing with the %s and its comrades will fight back" % FactionData.name_of(gov)) if gov != "" else ""], GameState.COL_WARN)
	else:
		module_on[slot] = false
		module_state[slot] = "off"
		_mlog("%s deactivated." % d["name"])
	return ""


func cycle_progress(slot: String) -> float:
	if scan_jobs.has(slot):
		return clampf(float(scan_jobs[slot]["t"]) / maxf(float(scan_jobs[slot]["total"]), 0.01), 0.0, 1.0)
	var e := find_module(slot)
	if not e.is_empty() and e["kind"] == "mine":
		var cdm := maxf(float(e["data"]["cooldown"]), 0.01)
		return 1.0 - clampf(float(module_timers.get(slot, 0.0)) / cdm, 0.0, 1.0)
	if not e.is_empty() and String(e["data"].get("active", "")) == "drone_pulse" and module_on.get(slot, false):
		# the anti-drone pulse (0.4.25.32): the bar fills up until the next pulse
		return 1.0 - clampf(float(module_timers.get(slot, 0.0)) / maxf(float(e["data"]["interval"]), 0.01), 0.0, 1.0)
	if e.is_empty() or e["kind"] != "weapon":
		return 1.0 if module_on.get(slot, false) else 0.0
	var cd := maxf(float(e["data"]["cooldown"]), 0.01)
	return 1.0 - clampf(float(module_timers.get(slot, 0.0)) / cd, 0.0, 1.0)


func _update_modules(delta: float, s: Dictionary) -> void:
	var node = null
	for e in fit.active_modules():
		var slot: String = e["slot"]
		var d: Dictionary = e["data"]
		module_timers[slot] = maxf(0.0, float(module_timers.get(slot, 0.0)) - delta)
		if e["kind"] == "self" and String(d.get("active", "")) in ["refinery", "factory", "market"]:
			module_on[slot] = builtin_on(String(d["active"]))      # survives warps and docking (package 25a/b)
		if not module_on.get(slot, false):
			module_state[slot] = "off"
			continue
		if not fit.is_powered(slot):
			module_state[slot] = "power"      # its priority group is shut down (package 21)
			continue
		if e["kind"] in ["pd", "mine"]:
			continue             # point defense runs in _update_pd, mines are one-shot
		if e["kind"] == "self":
			_run_active(delta, slot, d)
			continue
		if e["kind"] == "tool" and d["tool"] == "survey":
			_run_survey(delta, slot, d)
			continue
		if e["kind"] == "tool" and d["tool"] == "interdict":
			continue             # run by SystemView (timing game)
		var mkey := String(module_target.get(slot, active_lock))
		node = locked_node(mkey)
		if node == null and waiting_for(mkey):
			module_state[slot] = "range"     # target out of sensor range / being locked again: wait
			continue
		var err := module_target_error(e, node)
		if err != "":
			_switch_off(slot, d, "no valid target (target lost or changed)" if node == null else err.trim_suffix("."))
			continue
		var tgt = node
		if e["kind"] == "tool" and d["tool"] == "repair":
			if tgt == null or not (tgt is Ship) or hostile(self, tgt):
				tgt = self
		var prev: String = module_state.get(slot, "off")
		if tgt != self and position.distance_to(tgt.position) > float(d["range"]):
			if prev != "range":
				_mlog("%s: %s out of range (%s, range %s) – waiting." % [d["name"], node_name(tgt), SystemView.fmt_dist(position.distance_to(tgt.position)), SystemView.fmt_dist(float(d["range"]))], GameState.COL_WARN)
			module_state[slot] = "range"
			continue
		if prev == "range":
			_mlog("%s: %s in range – working." % [d["name"], node_name(tgt)])
		module_state[slot] = "on"
		if e["kind"] == "weapon":
			if order.get("type", "idle") == "idle":
				activity = "Firing at %s" % tgt.display_name()
			if module_timers[slot] > 0.0:
				continue
			if fit.capacitor < float(d["energy"]):
				if prev != "energy":
					_mlog("%s: not enough energy (needs %s, capacitor %.0f) – waiting for recharge." % [d["name"], str(d["energy"]), fit.capacitor], GameState.COL_WARN)
				module_state[slot] = "energy"
				continue
			fit.capacitor -= float(d["energy"])
			module_timers[slot] = float(d["cooldown"]) * randf_range(0.97, 1.03)
			view.fire_weapon(self, tgt, d)
			combat_t = 5.0
			continue
		if order.get("type", "idle") == "idle":
			var tn: String = tgt.display_name() if tgt is Ship else tgt.title()
			activity = "%s %s" % [{"mining": "Mining", "analyzer": "Analysing", "salvage": "Salvaging", "repair": "Repairing", "shield_transfer": "Charging the shield of", "cargo_scan": "Scanning the cargo of"}.get(String(d["tool"]), "Using"), tn]
		var keep := true
		var why := ""
		match String(d["tool"]):
			"mining":
				keep = _mine(delta, d, tgt)
				why = "asteroid depleted" if (is_instance_valid(tgt) and tgt.is_depleted()) else "cargo hold full"
			"analyzer":
				keep = _progress_tool(delta, d, "analysis", Color(0.8, 0.5, 1.0), tgt)
				why = "analysis complete"
			"salvage":
				keep = _progress_tool(delta, d, "salvage", Color(0.6, 1.0, 0.6), tgt)
				why = "salvage complete"
			"repair":
				keep = _repair_one(delta, d, tgt)
				why = "%s fully repaired" % ("your ship" if tgt == self else node_name(tgt))
			"shield_transfer":
				keep = _transfer_shield(delta, d, tgt)
				why = "target lost"
			"harvester":
				keep = _mine(delta, d, tgt)
				why = "asteroid depleted" if (is_instance_valid(tgt) and tgt.is_depleted()) else "cargo hold full"
			"prospect", "warrant", "cargo_scan":
				keep = _run_scan(delta, slot, d, tgt)
				why = "scan complete"
		if not keep:
			_switch_off(slot, d, why)


# ---------------------------------------------------------------- Package 7: scanners & active equipment

const SURVEY_KINDS := ["field", "planet", "anomaly", "gate", "station", "haven", "colossus", "star"]
const SURVEY_STALE := 300.0        # seconds until a survey counts as outdated


## Warp interdictor: aimed at a ship in warp selected in space or in the Contacts list. The
## target freezes, you warp after it (slower than usual) and play the timing game on the way.
func _start_interdict(slot: String, d: Dictionary) -> String:
	if view == null or not view.has_method("start_interdict"):
		return "No system."
	if in_warp():
		return "%s: cannot be used while you are in warp yourself." % d["name"]
	if view.interdict_running():
		return "%s: an interdiction is already running." % d["name"]
	var tgt = view.find_object(view.selected_id)
	if tgt == null or not (tgt is Ship) or tgt == self:
		return "%s: select a ship in warp first – click it in space or in the Contacts list (tab next to the overview)." % d["name"]
	if not tgt.in_warp():
		return "%s: %s is not in warp." % [d["name"], tgt.display_name()]
	var dist := position.distance_to(tgt.position)
	if dist > float(d["range"]):
		return "%s: %s is out of range (%s, range %s)." % [d["name"], tgt.display_name(), SystemView.fmt_dist(dist), SystemView.fmt_dist(float(d["range"]))]
	if fit.capacitor < float(d.get("energy", 0)):
		return "%s: not enough energy (needs %s, capacitor %.0f)." % [d["name"], str(d["energy"]), fit.capacitor]
	fit.capacitor -= float(d.get("energy", 0))
	module_on[slot] = true
	module_state[slot] = "on"
	view.start_interdict(self, tgt, slot, d)
	return ""


## Long-range survey: aimed at the place in the selection panel (not at a locked target).
func _start_survey(slot: String, d: Dictionary) -> String:
	if view == null:
		return "No system."
	var sel: String = view.selected_id
	var info: Dictionary = view.describe(sel) if sel != "" else {}
	var kind := String(info.get("kind", ""))
	if not kind in SURVEY_KINDS:
		return "%s: select a place first – click an asteroid field, planet, anomaly, gate or station (overview or system map), then switch the scanner on." % d["name"]
	var dist := position.distance_to(info["pos"])
	if dist > float(d["range"]):
		return "%s: %s is out of survey range (%s away, range %s – a Survey Range Amplifier or a bigger array reaches further)." % [d["name"], info["name"], SystemView.fmt_dist(dist), SystemView.fmt_dist(float(d["range"]))]
	if fit.capacitor < float(d["energy"]):
		return "%s: not enough energy (needs %s, capacitor %.0f)." % [d["name"], str(d["energy"]), fit.capacitor]
	fit.capacitor -= float(d["energy"])
	scan_jobs[slot] = {"t": 0.0, "total": float(d["scan_time"]), "id": sel, "name": info["name"], "pos": info["pos"],
		"kind": kind, "radius": view.survey_radius(sel, kind)}
	module_on[slot] = true
	module_state[slot] = "on"
	_mlog("%s: surveying %s (%s away) – %.0f s …" % [d["name"], info["name"], SystemView.fmt_dist(dist), float(d["scan_time"])])
	return ""


func _run_survey(delta: float, slot: String, d: Dictionary) -> void:
	var job: Dictionary = scan_jobs.get(slot, {})
	if job.is_empty():
		_switch_off(slot, d, "no survey target")
		return
	if position.distance_to(job["pos"]) > float(d["range"]):
		scan_jobs.erase(slot)
		_switch_off(slot, d, "%s left the survey range" % job["name"])
		return
	module_state[slot] = "on"
	job["t"] = float(job["t"]) + delta * float(fit.stats()["power_ratio"])
	if float(job["t"]) >= float(job["total"]):
		scan_jobs.erase(slot)
		module_on[slot] = false
		module_state[slot] = "off"
		view.complete_survey(job)
		_mlog("%s: survey of %s complete – results are in the survey window." % [d["name"], job["name"]], GameState.COL_GOOD)


## Prospector / warrant scan on the locked target. Returns false when finished.
func _run_scan(delta: float, slot: String, d: Dictionary, tgt) -> bool:
	var job: Dictionary = scan_jobs.get(slot, {})
	if job.is_empty() or job.get("node") != tgt:
		job = {"t": 0.0, "total": float(d["scan_time"]), "node": tgt}
		scan_jobs[slot] = job
	job["t"] = float(job["t"]) + delta
	tool_beams.append([tgt.position, {"prospect": Color(0.5, 0.9, 1.0), "cargo_scan": Color(0.6, 1.0, 0.8)}.get(String(d["tool"]), Color(1.0, 0.8, 0.3))])
	if float(job["t"]) < float(job["total"]):
		return true
	scan_jobs.erase(slot)
	if d["tool"] == "prospect":
		tgt.data["prospected"] = minf(float(tgt.data.get("prospected", 1.0)), float(d["accuracy"]))
		tgt.queue_redraw()
		_mlog("Prospector: %s – %s" % [tgt.title(), tgt.composition_text()], GameState.COL_GOOD)
	elif d["tool"] == "cargo_scan":
		tgt.ensure_manifest()
		tgt.cargo_known = true
		_mlog("Cargo scan: %s" % tgt.manifest_text(), GameState.COL_BAD if tgt.unregistered else GameState.COL_GOOD)
	else:
		tgt.warrant_known = true
		_mlog(tgt.warrant_text(), GameState.COL_GOOD if tgt.bounty > 0 else GameState.COL_INFO)
	return false


## Active optional equipment (afterburner, shield booster, armor repairer): drains energy while on.
func _run_active(delta: float, slot: String, d: Dictionary) -> void:
	if String(d.get("active", "")) == "drone_pulse":
		_pulse_tick(slot, d)
		return
	if String(d.get("active", "")) == "auto_fire":
		module_state[slot] = "on"
		return
	if String(d.get("active", "")) == "cloak":
		var cc := float(d["energy_rate"]) * delta
		if fit.capacitor < cc:
			module_on[slot] = false
			module_state[slot] = "off"
			_mlog("%s: capacitor empty – you are visible again." % d["name"], GameState.COL_WARN)
			return
		fit.capacitor -= cc
		module_state[slot] = "on"
		return
	var cost := float(d["energy_rate"]) * delta
	if fit.capacitor < cost:
		_switch_off(slot, d, "capacitor empty")
		return
	fit.capacitor -= cost
	module_state[slot] = "on"
	var st := fit.stats()
	match String(d["active"]):
		"refinery":
			_refine(delta, slot, d)
		"factory":
			_run_factory(delta, slot)
		"shield_boost":
			if shield_down <= 0.0:   # a collapsed shield cannot be boosted back (package 20)
				fit.shield = minf(float(st["shield_max"]), fit.shield + float(d["rate"]) * delta)
		"armor_repair":
			fit.armor = minf(float(st["armor_max"]), fit.armor + float(d["rate"]) * delta)


## Warrant scanner result text.
func warrant_text() -> String:
	if bounty > 0:
		var by := bounty_by if bounty_by != "" else GameState.rep.issuer(fit.system_id)
		return "Warrant: %s has a bounty of %s from the %s – bond redeemable at %s.%s" % [display_name(), GameData.fmt_credits(bounty), FactionData.name_of(by), GameState.bond_where({"faction": by}, fit.system_id), _arch_text()]
	return "Warrant: no bounty on %s.%s" % [display_name(), _arch_text()]


## Archetype line for the Warrant Scanner (package 14).
func _arch_text() -> String:
	if not ArchData.ARCHETYPES.has(archetype):
		return ""
	return "  Archetype: %s – %s" % [ArchData.name_of(archetype), ArchData.ARCHETYPES[archetype]["hint"]]


## Repair beam on one ship (manual). Returns false when nothing is left to repair.
func _repair_one(delta: float, t: Dictionary, ship) -> bool:
	var cost := float(t.get("energy", 0)) * delta
	if fit.capacitor < cost:
		return true
	var bs: Dictionary = ship.fit.stats()
	var missing: float = (float(bs["armor_max"]) - ship.fit.armor) + (float(bs["structure_max"]) - ship.fit.structure)
	if missing <= 0.5:
		return false
	fit.capacitor -= cost
	var heal := float(t["rate"]) * delta
	var to_armor := minf(heal, float(bs["armor_max"]) - ship.fit.armor)
	ship.fit.armor += to_armor
	ship.fit.structure = minf(float(bs["structure_max"]), ship.fit.structure + (heal - to_armor))
	if ship != self:
		tool_beams.append([ship.position, Color(0.4, 1.0, 0.5)])
	return true


# ---------------------------------------------------------------- Package 25b: factory, market

func builtin_on(kind: String) -> bool:
	match kind:
		"refinery":
			return fit.refinery_on
		"factory":
			return fit.factory_on
		"market":
			return fit.market_open
	return false


func _set_builtin_on(kind: String, on: bool) -> void:
	match kind:
		"refinery":
			fit.refinery_on = on
		"factory":
			fit.factory_on = on
		"market":
			fit.market_open = on


## The on-board factory works on the first job of its queue; a finished module goes into the cargo
## hold (as a module item), a drone into the drone hangar – it waits if there is no room.
func _run_factory(delta: float, slot: String) -> void:
	var q: Array = GameState.ship_jobs(fit.uid)
	if q.is_empty():
		module_state[slot] = "on"
		return
	var j: Dictionary = q[0]
	if float(j["left"]) > 0.0:
		j["left"] = float(j["left"]) - delta
		module_state[slot] = "on"
		smoke(delta)
		return
	var item := String(j["item"])
	if item == "drone":
		if fit.drones.size() >= int(fit.stats()["drone_storage"]):
			module_state[slot] = "range"     # hangar full – waiting
			return
		fit.drones.append({"fuel": 1.0, "hp": 1.0, "out": false})
	else:
		if fit.add_cargo("mod:" + item, 1.0) < 1.0:
			module_state[slot] = "range"     # cargo hold full – waiting
			return
	GameState.jobs.erase(j)
	GameState.stats["built"] = int(GameState.stats.get("built", 0)) + 1
	_mlog("Factory finished: %s." % ("a drone (in the hangar)" if item == "drone" else GameData.module_name(item) + " (in the cargo hold)"), GameState.COL_GOOD)


# ---------------------------------------------------------------- Package 25a: built-in refinery

var _smoke_t := 0.0


## Built-in refinery (KHI): turns ore from the hold into refined goods, slowly, while switched on –
## and belches black smoke while it works.
func _refine(delta: float, slot: String, d: Dictionary) -> void:
	var ore := ""
	for item in fit.cargo:
		if ShipFitting.is_ore(item) and float(fit.cargo[item]) > 0.0001 and GameData.commodities[item].has("refines_to"):
			ore = item
			break
	if ore == "":
		module_state[slot] = "on"
		return
	var c: Dictionary = GameData.commodities[ore]
	var prod: String = c["refines_to"]
	var amount := minf(float(d["rate"]) * delta, float(fit.cargo[ore]))
	var out := amount * float(c["yield"]) * float(d["eff"])
	if fit.free_for(prod) < out * GameData.item_volume(prod):
		module_state[slot] = "range"      # no room for the product – waiting
		return
	module_state[slot] = "on"
	fit.remove_cargo(ore, amount)
	fit.add_cargo(prod, out)
	GameState.stats["refined"] = float(GameState.stats.get("refined", 0)) + out
	smoke(delta)


## Black smoke from the stacks (KHI ships while refining / mining).
func smoke(delta: float) -> void:
	_smoke_t -= delta
	if _smoke_t > 0.0 or view == null or view.sky_alpha() < 0.5:
		return
	_smoke_t = 0.08
	var stacks := smoke_stacks()
	if stacks.is_empty():
		return
	# thin plumes sprayed sideways out of the exhaust pipes on both flanks
	var st: Vector2 = stacks[randi() % stacks.size()]
	var flank := 1.0 if randf() < 0.5 else -1.0
	var local := Vector2(st.x, st.y * flank)
	var out := Vector2(0.0, signf(local.y)).rotated(heading)     # away from the hull, outwards
	view.spawn_fx(Fx.smoke(position + local.rotated(heading), out * randf_range(55.0, 80.0) + velocity * 0.9, 6.0 + radius * 0.08))


var deck_queue := 0              # drones waiting for / rolling down the flight deck


# ---------------------------------------------------------------- Hatches (package 25d, Citadel)

func has_hatch(n: String) -> bool:
	return fit.hull().get("hatches", {}).has(n)


## The hangar doors drones use: "drones", "drones_2" … (package 25e – Concord carriers have several).
func drone_hatches() -> Array:
	var out: Array = []
	for n in fit.hull().get("hatches", {}):
		if String(n).begins_with("drones"):
			out.append(n)
	out.sort()
	return out


## The drone hatch nearest to a point (where a returning drone lands).
func nearest_drone_hatch(p: Vector2) -> String:
	var best := ""
	var bd := INF
	for n in drone_hatches():
		var d := hatch_point(n).distance_to(p)
		if d < bd:
			bd = d
			best = n
	return best


## Keeps a hatch open for `hold` seconds (it slides open first, and shut again afterwards).
func open_hatch(n: String, hold: float) -> void:
	if has_hatch(n):
		_hatch_hold[n] = maxf(float(_hatch_hold.get(n, 0.0)), hold)


## The hatch in the ship's own frame (x forward), in world units.
func hatch_local(n: String) -> Rect2:
	var r: Array = fit.hull()["hatches"][n]
	var tex := PixelArt.ship_texture(fit.hull_id, paint)
	var half := Vector2(tex.get_width(), tex.get_height()) * 0.5
	var rect := Rect2((Vector2(float(r[0]) + 1.0, float(r[1]) + 1.0) - half) * PixelArt.SCALE, Vector2(float(r[2]), float(r[3])) * PixelArt.SCALE)
	return Rect2(rect.position + part_shift(rect.get_center().y), rect.size)


## How far a moving part (Concordia's flight wings) has moved at local height y (package 25e) – exactly
## the pixels of the wing picture in use, so doors and stripes stay on the wing.
func part_shift(y: float) -> Vector2:
	var arms: Dictionary = fit.hull().get("arms", {})
	if not arms.has("shift"):
		return Vector2.ZERO
	var n := int(arms.get("frames", 1))
	var idx := clampi(int(round(smoothstep(0.0, 1.0, arm_open) * float(n - 1))), 0, n - 1)
	var t := float(idx) / float(maxi(n - 1, 1))
	var sh: Array = arms["shift"]
	return Vector2(-round(float(sh[0]) * t), round(float(sh[1]) * t) * signf(y)) * PixelArt.SCALE


func hatch_point(n: String) -> Vector2:
	if not has_hatch(n):
		return position
	return position + hatch_local(n).get_center().rotated(heading)


## Demo of the S-ship platform (the ship itself comes with Teil 5): the hatch slides open, a small
## ship rises from the bay and lifts off, the hatch closes behind it.
func launch_platform() -> String:
	if not has_hatch("platform"):
		return "This ship has no launch platform."
	platform_t = 0.0
	open_hatch("platform", 2.3)
	return ""


func _update_hatches(delta: float) -> void:
	if _hatch_hold.is_empty() and hatch_open.is_empty() and platform_t < 0.0:
		return
	for n in fit.hull().get("hatches", {}):
		var hold := float(_hatch_hold.get(n, 0.0)) - delta
		_hatch_hold[n] = maxf(hold, 0.0)
		var target := 1.0 if hold > 0.0 else 0.0
		hatch_open[n] = move_toward(float(hatch_open.get(n, 0.0)), target, delta / HATCH_TIME)
		if float(hatch_open[n]) <= 0.0 and hold <= 0.0:
			hatch_open.erase(n)
			_hatch_hold.erase(n)
	if platform_t >= 0.0:
		platform_t += delta
		if platform_t > PLATFORM_ANIM:
			platform_t = -1.0


## Draws open hatches: a dark shaft, the panel slid towards the stern (shut hatches are part of the
## ship's picture – hatch_overlay hulls get theirs painted in by PixelArt._paint_hatches).
func _draw_hatches() -> void:
	var h := fit.hull()
	var overlay: bool = h.get("hatch_overlay", false)
	if hatch_open.is_empty() and platform_t < 0.0:
		return
	var cols := PixelArt.paint_colors(fit.hull_id, paint)
	var cm: Color = cols["M"]
	var cn: Color = cols["N"]
	var cb: Color = cols["B"]
	if overlay or String(h.get("maker", "")) != "hadrian":
		var hc: Array = PixelArt.HATCH_CHARS.get(String(h.get("maker", "")), ["d", "D"])
		cm = cols[hc[0]]
		cn = cols[hc[1]]
		cb = cols[hc[1]]
	for n in h.get("hatches", {}):
		var o := float(hatch_open.get(n, 0.0))
		if o <= 0.0:
			continue                     # shut: part of the ship's picture (also shown in menus)
		var r := hatch_local(n)
		if o > 0.0:
			draw_rect(r, Color(0.03, 0.03, 0.045))
			draw_rect(Rect2(r.position + Vector2(0, r.size.y * 0.45), Vector2(r.size.x, r.size.y * 0.1)), Color(0.9, 0.2, 0.12, 0.35 * o))
		if n == "platform" and platform_t >= 0.0:
			_draw_platform_ship(r)
		var pw := r.size.x * (1.0 - o)
		if pw > 0.5:
			draw_rect(Rect2(r.position, Vector2(pw, r.size.y)), cm)
			var yy := r.position.y + PixelArt.SCALE
			while yy < r.end.y - 0.5:
				draw_rect(Rect2(Vector2(r.position.x, yy), Vector2(pw, PixelArt.SCALE * 0.5)), cn)
				yy += PixelArt.SCALE * 2.0
			draw_rect(Rect2(Vector2(r.position.x + pw - PixelArt.SCALE * 0.5, r.position.y), Vector2(PixelArt.SCALE * 0.5, r.size.y)), cb)
			var shade_y := maxf(r.position.y, PixelArt.SCALE * 0.5)      # the lower half lies in shadow
			if r.end.y > shade_y:
				draw_rect(Rect2(Vector2(r.position.x, shade_y), Vector2(pw, r.end.y - shade_y)), Color(0, 0, 0, 0.3))
	if platform_t >= 0.0 and not hatch_open.has("platform"):
		_draw_platform_ship(hatch_local("platform"))


## The small ship on the platform: rises out of the bay (dark → lit, small → full size), then lifts
## off forwards and fades out (in Teil 5 it becomes a real ship at that moment).
func _draw_platform_ship(r: Rect2) -> void:
	var t := platform_t
	if t < 0.5 or t > PLATFORM_ANIM - 0.2:
		return
	var tex := PixelArt.ship_texture("hdy_talon", paint)
	var sc := 0.55
	var lit := 0.3
	var off := Vector2.ZERO
	var alpha := 1.0
	if t < 1.6:
		var k := (t - 0.5) / 1.1
		sc = lerpf(0.55, 0.85, k)
		lit = lerpf(0.3, 1.0, k)
	else:
		var k2 := clampf((t - 1.6) / (PLATFORM_ANIM - 1.8), 0.0, 1.0)
		sc = lerpf(0.85, 1.15, k2)
		lit = 1.0
		off = Vector2(k2 * k2 * r.size.x * 3.0, 0.0)
		alpha = 1.0 - clampf((k2 - 0.6) / 0.4, 0.0, 1.0)
	var size := Vector2(tex.get_width(), tex.get_height()) * PixelArt.SCALE * sc
	var c := r.get_center() + off
	if t >= 1.6:
		draw_rect(Rect2(c - size * 0.5 + Vector2(6, 6), size), Color(0, 0, 0, 0.25 * alpha))   # its shadow on the deck
	draw_texture_rect(tex, Rect2(c - size * 0.5, size), false, Color(lit, lit, lit, alpha))


# ---------------------------------------------------------------- NPC carriers (package 25e)

var _npc_drone_t := 0.0
var _npc_calm_t := 0.0
const NPC_DRONE_CALM := 18.0     # seconds without a fight before an NPC carrier calls its drones back


## Concord carriers flown by NPCs launch their drones when they fight and call them back afterwards.
func _update_npc_drones(delta: float) -> void:
	if manual or faction == "player" or is_drone or view == null or not fit.hull().get("npc_drones", false):
		return
	_npc_drone_t -= delta
	if _npc_drone_t > 0.0:
		return
	_npc_drone_t = 1.0
	var fighting: bool = target != null and is_instance_valid(target) and target is Ship and not target.dying and Ship.hostile(self, target) \
		and position.distance_to(target.position) < float(fit.stats()["sensor_range"]) * 3.0
	var out: Array = view.drones_of(self)
	if fighting:
		_npc_calm_t = 0.0
		combat_t = maxf(combat_t, 2.0)
		if out.is_empty() and not view.drones_must_return(self):
			if fit.drones.is_empty():
				for i in int(fit.stats()["drones_max"]):
					fit.drones.append({"fuel": 1.0, "hp": 1.0, "out": false})
			fit.drone_role = "combat"
			fit.drone_modes["combat"] = "defend"
			view.launch_drones(self)
	elif not out.is_empty():
		_npc_calm_t += 1.0
		if _npc_calm_t >= NPC_DRONE_CALM:
			view.recall_drones(self)


# ---------------------------------------------------------------- Cathedral (package 25f)

## While switched on, the anti-drone pulse fires every `interval` seconds (when the capacitor has the energy).
func _pulse_tick(slot: String, d: Dictionary) -> void:
	if float(module_timers.get(slot, 0.0)) > 0.0:
		module_state[slot] = "on"
		return
	if fit.capacitor < float(d["energy"]):
		module_state[slot] = "energy"
		return
	fit.capacitor -= float(d["energy"])
	module_timers[slot] = float(d["interval"])
	module_state[slot] = "on"
	view.drone_pulse(self, float(d["range"]), float(d["stun"]))
	combat_t = 5.0


## Auto mode: every focus laser that is not switched on by hand fires on its own – at up to `targets`
## enemies in range and at the targets that were locked when the mode was switched on.
func _update_auto_fire(delta: float, s: Dictionary) -> void:
	if not module_on.get("builtin_auto_fire", false) or emp_t > 0.0 or view == null or in_warp() or is_docked():
		return
	_auto_t -= delta
	var cands: Array = []
	for t0 in auto_targets:
		if is_instance_valid(t0) and t0 is Ship and not t0.dying and t0.is_targetable():
			cands.append(t0)
	var maxr := 0.0
	for w in s["weapons"]:
		if w.get("focus", false):
			maxr = maxf(maxr, float(w["range"]))
	for n in view.ship_layer.get_children():
		if cands.size() >= 6:
			break
		if n is Ship and n != self and not n.dying and n.is_targetable() and not n in cands and Ship.hostile(self, n) and position.distance_to(n.position) <= maxr and can_see(n):
			cands.append(n)
	if cands.is_empty():
		return
	cands = cands.slice(0, 6)
	var k := _auto_k
	for w2 in s["weapons"]:
		if not w2.get("focus", false):
			continue
		var slot: String = w2["slot"]
		if module_on.get(slot, false) or not w2.get("powered", true):
			continue                     # a laser switched on by hand keeps its own target
		var tg = cands[k % cands.size()]
		k += 1
		if float(module_timers.get(slot, 0.0)) > 0.0 or position.distance_to(tg.position) > float(w2["range"]):
			continue
		if fit.capacitor < float(w2["energy"]):
			continue
		fit.capacitor -= float(w2["energy"])
		module_timers[slot] = float(w2["cooldown"]) * randf_range(0.97, 1.03)
		view.fire_weapon(self, tg, w2)
		combat_t = 5.0
		_auto_k = k                      # next time the next target (the bundled lance takes turns)


## The cloak takes hold from the stern to the bow (0.4.25.38): a cyan scan line runs over the hull and the ship
## fades behind it – its own pilot still sees it faintly, everybody else not at all; it shows again bow first.
var cloak_k := 0.0               # 0 = fully visible … 1 = fully cloaked


func _update_cloak_fx(delta: float) -> void:
	var dur := 0.7 + 0.3 * float(fit.hull().get("size", 1))
	cloak_k = move_toward(cloak_k, 1.0 if cloaked() else 0.0, delta / dur)
	modulate.a = 0.0 if cloak_k >= 1.0 and faction != "player" else 1.0


func _cloak_hidden_alpha() -> float:
	return 0.35 if faction == "player" else 0.0


## The hull while the cloak sweeps over it (or holds): the columns behind the scan line faded, a glowing line
## on the hull's shape where it runs, a faint shimmer over the cloaked ship for its own pilot.
func _draw_cloaked_hull(tex: Texture2D, size: Vector2, mod: Color) -> void:
	var w := tex.get_width()
	var h := tex.get_height()
	var sc := PixelArt.SCALE
	var cut := clampi(int(round(cloak_k * float(w))), 0, w)
	var ha := _cloak_hidden_alpha()
	var o := -size * 0.5
	if cut > 0 and ha > 0.0:
		draw_texture_rect_region(tex, Rect2(o, Vector2(cut * sc, size.y)), Rect2(0, 0, cut, h), Color(mod, ha))
	if cut < w:
		draw_texture_rect_region(tex, Rect2(o + Vector2(cut * sc, 0.0), Vector2((w - cut) * sc, size.y)), Rect2(cut, 0, w - cut, h), mod)
	var sil := PixelArt.silhouette_texture(fit.hull_id)
	if cut > 0 and ha > 0.0:
		var t2 := float(Time.get_ticks_msec()) / 1000.0
		draw_texture_rect_region(sil, Rect2(o, Vector2(cut * sc, size.y)), Rect2(0, 0, cut, h), Color(0.4, 0.95, 1.0, 0.1 + 0.06 * sin(t2 * 3.0)))
	if cloak_k > 0.0 and cloak_k < 1.0:
		for band in [[6, 2, 0.3], [2, 1, 0.95]]:      # a soft glow and the bright scan line itself
			var a0 := clampi(cut - int(band[0]), 0, w)
			var a1 := clampi(cut + int(band[1]), 0, w)
			if a1 > a0:
				draw_texture_rect_region(sil, Rect2(o + Vector2(a0 * sc, 0.0), Vector2((a1 - a0) * sc, size.y)), Rect2(a0, 0, a1 - a0, h), Color(0.55, 1.0, 1.0, float(band[2])))


## How visible a point of the hull is (texture column x) while cloaking – for the parts drawn on top.
func _cloak_alpha_at(col: float, tex_w: int) -> float:
	if cloak_k <= 0.0:
		return 1.0
	var cut := cloak_k * float(tex_w)
	return lerpf(1.0, _cloak_hidden_alpha(), clampf((cut - col + 4.0) / 8.0, 0.0, 1.0))


## Axiom research ships flown by NPCs cloak when they come under fire and show again after a while.
var _cloak_calm := 0.0


func _update_npc_cloak(delta: float) -> void:
	if manual or faction == "player" or view == null or not "cloak" in fit.hull().get("builtin", []):
		return
	if cloaked():
		_cloak_calm += delta
		if _cloak_calm > 25.0:
			module_on["builtin_cloak"] = false
	elif combat_t > 4.0 and last_attacker != null and is_instance_valid(last_attacker) and Ship.hostile(self, last_attacker):
		module_on["builtin_cloak"] = true
		_cloak_calm = 0.0
		target = null


## NPC Cathedrals use the pulse against hostile drones near them.
func _update_npc_pulse(delta: float) -> void:
	if manual or faction == "player" or view == null or not "drone_pulse" in fit.hull().get("builtin", []):
		return
	_npc_pulse_t -= delta
	if _npc_pulse_t > 0.0:
		return
	var dp: Dictionary = fit.hull()["drone_pulse"]
	for n in view.ship_layer.get_children():
		if n is Ship and n.is_drone and not n.dying and n.position.distance_to(position) <= float(dp["range"]) and Ship.hostile(self, n):
			view.drone_pulse(self, float(dp["range"]), float(dp["stun"]))
			_npc_pulse_t = float(dp["interval"])
			return
	_npc_pulse_t = 1.0


# ---------------------------------------------------------------- Golden spikes (Forge of Return, 0.4.25.32)

## Now and then the golden spikes on the rim of a Templar or Cathedral slowly slide out and back in –
## each spike at its own time.
func _draw_spikes(size: Vector2) -> void:
	var tips: Array = PixelArt.spike_tips(fit.hull_id)
	if tips.is_empty():
		return
	var t := float(Time.get_ticks_msec()) / 1000.0
	var px := PixelArt.SCALE
	var half := size * 0.5
	var gold := Color(0.84, 0.63, 0.22)
	var light := Color(1.0, 0.86, 0.52)
	for i in tips.size():
		var tp: Array = tips[i]
		var w := sin(t * 0.45 + float(i) * 2.399)              # a slow wave, every spike its own phase
		var ext := clampf((w - 0.55) / 0.45, 0.0, 1.0)         # out only near the top of the wave
		if ext <= 0.0:
			continue
		var length := ext * px * 3.0
		var base := Vector2(float(tp[0]) + 1.0, float(tp[1]) + 1.0) * px - half
		var dir := float(tp[2])                                 # -1 up (outwards on top), +1 down
		var r := Rect2(Vector2(base.x + px * 0.25, base.y + px if dir > 0.0 else base.y - length), Vector2(px * 0.5, length))
		draw_rect(r, gold)
		draw_rect(Rect2(r.position, Vector2(px * 0.25, r.size.y)), light)
		var tip := Vector2(r.get_center().x, r.position.y if dir < 0.0 else r.end.y)
		draw_circle(tip, px * 0.35, Color(1.0, 0.95, 0.75, 0.6 * ext))


# ---------------------------------------------------------------- Light effects (package 25e, Concord)

## The owner-colour stripes pulse gently; in a fight a bright spot runs along each from bow to stern;
## launch_glow ships light them up yellow while their drone doors are open.
func _draw_stripes(size: Vector2) -> void:
	var segs: Array = PixelArt.stripe_segments(fit.hull_id)
	if segs.is_empty():
		return
	var t := float(Time.get_ticks_msec()) / 1000.0
	var half := size * 0.5
	var px := PixelArt.SCALE
	var glow := 0.0
	if fit.hull().get("launch_glow", false):
		for n in drone_hatches():
			glow = maxf(glow, float(hatch_open.get(n, 0.0)))
	# a clearly visible breathing glow (0.4.25.28: stronger)
	var pulse := 0.5 + 0.5 * sin(t * 1.8)
	var flash := fmod(t * 2.6, 1.0) < 0.5               # warning beacon: on – off
	for i in segs.size():
		var sg: Array = segs[i]
		var pos := Vector2(float(sg[1]) + 1.0, float(sg[0]) + 1.0) * px - half
		if sg[3]:
			pos += part_shift(pos.y)
		var r := Rect2(pos, Vector2(float(sg[2]) - float(sg[1]) + 1.0, 1.0) * px)
		if glow > 0.0:
			# construction-site warning light: amber, flashing, with a chase of bright blocks
			draw_rect(r, Color(0.35, 0.18, 0.0, 0.9 * glow))
			var step := px * 4.0
			var off := fmod(t * 60.0, step)
			var x0 := r.position.x - step + off
			while x0 < r.end.x:
				var a0 := maxf(x0, r.position.x)
				var a1 := minf(x0 + px * 2.0, r.end.x)
				if a1 > a0:
					draw_rect(Rect2(Vector2(a0, r.position.y), Vector2(a1 - a0, px)), Color(1.0, 0.68, 0.05, glow * (1.0 if flash else 0.55)))
				x0 += step
			if flash:
				draw_rect(r.grow(px * 0.8), Color(1.0, 0.6, 0.0, 0.25 * glow))
			continue
		draw_rect(r.grow(px * 0.6), Color(0.55, 0.85, 1.0, 0.18 * pulse))      # glowing halo …
		draw_rect(r, Color(0.85, 0.96, 1.0, 0.12 + 0.5 * pulse))                # … and the lit stripe
		if combat_t > 0.0:
			var p := fmod(t * 0.8 + float(i) * 0.37, 1.0)
			var x := r.end.x - px - p * (r.size.x - px)
			draw_rect(Rect2(Vector2(x - px * 2.0, r.position.y - px * 0.5), Vector2(px * 5.0, px * 2.0)), Color(0.75, 0.92, 1.0, 0.4))
			draw_rect(Rect2(Vector2(x, r.position.y), Vector2(px, px)), Color(1, 1, 1, 1))
	# warning beacons at the corners of open drone doors
	if glow > 0.0:
		for n2 in drone_hatches():
			var o := float(hatch_open.get(n2, 0.0))
			if o <= 0.0:
				continue
			var hr := hatch_local(n2)
			var on := fmod(t * 2.6 + (0.5 if hr.position.x > 0.0 else 0.0), 1.0) < 0.5
			for cpos in [hr.position - Vector2(px, px), Vector2(hr.end.x, hr.position.y - px), Vector2(hr.position.x - px, hr.end.y), hr.end]:
				draw_rect(Rect2(cpos, Vector2(px, px)), Color(1.0, 0.7, 0.05, o if on else 0.25 * o))
				if on:
					draw_circle(cpos + Vector2(px, px) * 0.5, px * 2.2, Color(1.0, 0.6, 0.0, 0.3 * o))


# ---------------------------------------------------------------- Swinging arms (package 25d, Goliath)

## The arms fold in while the ship docks or undocks (the hangar bays are narrow) and swing open in space.
func _update_arms(delta: float) -> void:
	if not fit.hull().has("arms"):
		return
	var t := 0.0 if String(order.get("type", "")) in ["docking", "undocking"] else 1.0
	arm_open = move_toward(arm_open, t, delta / ARM_TIME)


## The arms in the stage that matches arm_open (folded … open), both centred on the ship.
func _draw_arms(arms: Dictionary, _size: Vector2, mod: Color) -> void:
	var n := int(arms.get("frames", 1))
	var idx := clampi(int(round(smoothstep(0.0, 1.0, arm_open) * float(n - 1))), 0, n - 1)
	var at: Array = PixelArt.arm_textures("%s_%d" % [String(arms["art"]), idx], paint)
	for t in at:
		var asz := Vector2(t.get_width(), t.get_height()) * PixelArt.SCALE
		draw_texture_rect(t, Rect2(-asz * 0.5, asz), false, mod)


## Carriers with a flight deck (Kanayama-maru): drones launch from it and land on it.
func has_deck() -> bool:
	return fit.hull().has("drone_deck")


## Point on the flight deck (0 = rear end, 1 = front end); the ship's centre without a deck.
func deck_point(frac: float = 0.5) -> Vector2:
	var deck: Array = fit.hull().get("drone_deck", [])
	if deck.is_empty():
		return position
	var art: Array = PixelArt.ShipArt.SHIPS.get(fit.hull_id, [])
	var w := 0
	for r in art:
		w = maxi(w, String(r).length())
	var col := lerpf(float(deck[0]), float(deck[1]), clampf(frac, 0.0, 1.0))
	return position + Vector2((col + 1.0 - (w + 2) / 2.0) * PixelArt.SCALE, 0.0).rotated(heading)


var _stacks_cache: Array = []
var _stacks_hull := ""


## Local positions (x forward, y = top flank) of the exhaust pipes: the "D" pairs in the first
## row of the hull's pixel art (KHI ships).
func smoke_stacks() -> Array:
	if _stacks_hull == fit.hull_id:
		return _stacks_cache
	_stacks_hull = fit.hull_id
	_stacks_cache = []
	var art: Array = PixelArt.ShipArt.SHIPS.get(fit.hull_id, [])
	if art.is_empty():
		return _stacks_cache
	var w := 0
	for r in art:
		w = maxi(w, String(r).length())
	var tex_w := float(w + 2)
	var tex_h := float(art.size() * 2 - 1 + 2)
	var row0: String = art[0]
	var i := 0
	while i < row0.length():
		if row0[i] == "D":
			_stacks_cache.append(Vector2((i + 2 - tex_w / 2.0) * PixelArt.SCALE, (1.0 - tex_h / 2.0) * PixelArt.SCALE))
			i += 2
		else:
			i += 1
	return _stacks_cache


# ---------------------------------------------------------------- Package 22: multi-focus (NPCs)

## Bigger NPC ships (hull size M and up, three weapons or more) split their fire over up to
## max_locks hostile ships near their primary target.
func _update_focus(sensor: float) -> void:
	_focus.clear()
	if manual or not _valid(target) or int(fit.hull().get("size", 1)) < 2 or fit.stats()["weapons"].size() < 3:
		return
	var cands: Array = []
	for n in get_tree().get_nodes_in_group("ships"):
		if n != self and n != target and _valid(n) and hostile(self, n) and not _protected(n) and position.distance_to(n.position) <= sensor:
			cands.append(n)
	cands.sort_custom(func(a, b): return position.distance_squared_to(a.position) < position.distance_squared_to(b.position))
	_focus = cands.slice(0, max_locks() - 1)


# ---------------------------------------------------------------- Package 21: power management

## Active modules in use right now (slot -> true). Pilot: switched on (mine launchers while
## reloading). NPCs: weapons and point defense while fighting, beams always, the jammer while on.
func power_in_use() -> Dictionary:
	var u := _power_in_use_raw()
	# review W3 (0.4.25.46): a bundled focus lance draws the power of every crystal, not just the first one
	if int(fit.stats().get("focus_bundle", 0)) > 0 and u.has("weapon_0"):
		for k in fit.slot_keys():
			if String(k).begins_with("weapon_"):
				u[k] = true
	return u


func _power_in_use_raw() -> Dictionary:
	var u := {}
	if manual:
		for k in module_on:
			if module_on[k]:
				u[k] = true
		for k2 in module_timers:
			if float(module_timers[k2]) > 0.0 and String(GameData.modules.get(fit.modules.get(k2, ""), {}).get("slot", "")) == "weapon":
				u[k2] = true
		return u
	var fighting := _valid(target)
	for key in fit.modules:
		var m: Dictionary = GameData.modules.get(fit.modules[key], {})
		if m.is_empty() or not ShipFitting.is_active_module(m):
			continue
		match String(m["slot"]):
			"weapon":
				if fighting and not m.get("mines", false):
					u[key] = true
			"tool":
				if String(m.get("tool", "")) in ["repair", "shield_transfer", "mining", "harvester", "analyzer", "salvage"]:
					u[key] = true
			"optional":
				if String(m.get("active", "")) == "jammer" and jamming:
					u[key] = true
	return u


## Hard power limit (package 21): on an overload priority groups 4, 3, 2 shut down in turn.
## Returns true if the power state changed.
func _update_power() -> bool:
	var before: Dictionary = fit.power_off.duplicate()
	var thr0 := fit.throttle
	var plan := fit.power_plan(power_in_use())
	if not fit.apply_power(plan):
		return false
	if manual and faction == "player":
		for g in plan["off"]:
			if not before.has(g):
				GameState.log_msg("Power overload: priority group %d shut down (demand %.0f MW, reactor %.0f MW)." % [int(g), float(plan["requested"]), float(plan["available"])], GameState.COL_BAD)
		for g2 in before:
			if not plan["off"].has(g2):
				GameState.log_msg("Power restored: priority group %d back online." % int(g2), GameState.COL_GOOD)
		if fit.throttle < 1.0 and thr0 >= 1.0:
			GameState.log_msg("Group 1 alone exceeds the reactor – all systems at %d %%." % int(fit.throttle * 100.0), GameState.COL_BAD)
	return true


# ---------------------------------------------------------------- Package 20: new modules

## Shield transfer beam: own capacitor → the target's shield. Uses energy only while it actually
## transfers; on a collapsed shield it shortens the downtime instead. Stays on (returns true).
func _transfer_shield(delta: float, t: Dictionary, ship) -> bool:
	if ship == null or not is_instance_valid(ship) or ship == self or not (ship is Ship):
		return false
	var bs: Dictionary = ship.fit.stats()
	if float(bs["shield_max"]) <= 0.0:
		return true
	if ship.shield_down <= 0.0 and ship.fit.shield >= float(bs["shield_max"]) - 0.5:
		return true              # full: idle, no energy used
	var cost := float(t.get("energy_rate", 0.0)) * delta
	if fit.capacitor < cost:
		return true
	fit.capacitor -= cost
	if ship.shield_down > 0.0:
		ship._xfer_t = 0.3
	else:
		ship.fit.shield = minf(float(bs["shield_max"]), ship.fit.shield + float(t["rate"]) * delta)
	tool_beams.append([ship.position, Color(0.45, 0.7, 1.0)])
	return true


## NPC shield transfer: the friendly ship in range that needs it most.
func _npc_transfer(delta: float, t: Dictionary) -> void:
	var best = null
	var need := 0.5
	for n in get_tree().get_nodes_in_group("ships"):
		if n == self or n.faction != faction or not n.is_targetable() or position.distance_to(n.position) > float(t["range"]):
			continue
		var ns: Dictionary = n.fit.stats()
		var miss: float = float(ns["shield_max"]) - n.fit.shield + (float(ns["shield_max"]) if n.shield_down > 0.0 else 0.0)
		if miss > need:
			need = miss
			best = n
	if best != null:
		_transfer_shield(delta, t, best)


## Point defense (package 20): shoots down hostile missiles, torpedoes and mines in range. NPCs
## always use it; the pilot switches it on in the module bar.
func _update_pd(delta: float, s: Dictionary) -> void:
	for pd in s["pd"]:
		var slot: String = pd["slot"]
		pd_timers[slot] = maxf(0.0, float(pd_timers.get(slot, 0.0)) - delta)
		if manual and not module_on.get(slot, false):
			continue
		if not pd.get("powered", true):
			continue
		if emp_t > 0.0 or float(pd_timers[slot]) > 0.0:
			continue
		if fit.capacitor < float(pd["energy"]):
			if manual:
				module_state[slot] = "energy"
			continue
		if manual:
			module_state[slot] = "on"
		var threat = pd_target(float(pd["range"]))
		if threat == null:
			continue
		fit.capacitor -= float(pd["energy"])
		pd_timers[slot] = float(pd["cooldown"])
		if view != null:
			view.spawn_fx(Fx.beam(position, threat.position, Color(1.0, 0.95, 0.6), 1.5))
		if randf() < minf(float(pd["intercept"]), 0.95):
			threat.intercept()


## Nearest hostile missile or mine within `rng` (null = none).
func pd_target(rng: float):
	var best = null
	var bd := rng
	for m in get_tree().get_nodes_in_group("missiles"):
		if is_instance_valid(m) and not m.is_queued_for_deletion() and m.shooter != self and m._hits(self):
			var d: float = position.distance_to(m.position)
			if d <= bd:
				bd = d
				best = m
	for m2 in get_tree().get_nodes_in_group("mines"):
		if is_instance_valid(m2) and not m2.is_queued_for_deletion() and m2.threatens(self):
			var d2: float = position.distance_to(m2.position)
			if d2 <= bd:
				bd = d2
				best = m2
	return best


## Radar jammer: the pilot switches it on; NPCs run theirs while they fight. Jamming itself is
## applied by SystemView (jam_radius()).
func _update_npc_jammer(delta: float, s: Dictionary) -> void:
	if manual:
		return
	var j := _jammer_module(s)
	if j.is_empty():
		jamming = false
		return
	var want: bool = emp_t <= 0.0 and _valid(target) and position.distance_to(target.position) < 30000.0
	var cost := float(j["energy_rate"]) * delta
	if want and fit.capacitor >= cost:
		fit.capacitor -= cost
		jamming = true
	else:
		jamming = false


func _jammer_module(s: Dictionary) -> Dictionary:
	for a in s["actives"]:
		if a["active"] == "jammer":
			return a
	return {}


## Radius this ship jams right now (0 = not jamming).
func jam_radius() -> float:
	if dying or is_docked() or in_warp() or emp_t > 0.0:
		return 0.0
	var s := fit.stats()
	if manual:
		var r := 0.0
		for a in s["actives"]:
			if a["active"] == "jammer" and module_on.get(a["slot"], false) and a.get("powered", true):
				r = maxf(r, float(a["jam_range"]))
		return r
	var jm := _jammer_module(s)
	return float(jm.get("jam_range", 0.0)) if jamming and jm.get("powered", true) else 0.0


## Mine launcher (package 20): lays one mine of the type chosen for this launcher (right-click its
## tile) from the cargo hold. At most `max_mines` per launcher at once.
func lay_mine(slot: String, d: Dictionary) -> String:
	if view == null or not view.has_method("lay_mine"):
		return "No system."
	if not fit.is_powered(slot):
		return "%s: no power – priority group %d is shut down (overload)." % [d["name"], fit.priority_of(slot)]
	var ch: Dictionary = mine_choice.get(slot, {})
	var mtype := String(ch.get("type", ""))
	if mtype == "" or float(fit.cargo.get(mtype, 0.0)) < 1.0:
		mtype = ""
		for k in GameData.MINES:
			if float(fit.cargo.get(k, 0.0)) >= 1.0:
				mtype = k
				break
	if mtype == "":
		return "%s: no mines in your cargo hold – military outposts, shipyards and pirate havens sell them." % d["name"]
	if float(module_timers.get(slot, 0.0)) > 0.0:
		return "%s: reloading (%.1f s)." % [d["name"], float(module_timers[slot])]
	var cap := maxi(int(round(float(d["max_mines"]))), 1)
	if view.mines_of(self, slot) >= cap:
		return "%s: %d mines already out (maximum %d) – they go off or disappear after %d min." % [d["name"], cap, cap, int(GameData.MINE_LIFE / 60.0)]
	if fit.capacitor < float(d["energy"]):
		return "%s: not enough energy (needs %s)." % [d["name"], str(d["energy"])]
	fit.capacitor -= float(d["energy"])
	module_timers[slot] = float(d["cooldown"])
	fit.remove_cargo(mtype, 1.0)
	var fuse := float(ch.get("fuse", 10.0))
	view.lay_mine(self, mtype, slot, fuse, 1.0 + 0.25 * (int(d["size"]) - 1))
	_mlog("%s: %s laid%s (%d left in the hold)." % [d["name"], GameData.MINES[mtype]["name"], (" – goes off in %d s" % int(fuse)) if mtype == "mine_timer" else "", int(fit.cargo.get(mtype, 0.0))])
	return ""


## Cargo manifest (package 20): generated once – for the cargo scanner and the wreck loot.
func ensure_manifest() -> void:
	if manifest_done:
		return
	manifest_done = true
	if not fit.cargo.is_empty():
		return
	var room := maxf(float(fit.stats()["cargo_max"]), 10.0)
	var goods: Array = []
	if smuggler_mission != "":
		unregistered = true
		goods = ["electronics", "weapon_parts", "medicine", "mine_emp"]
	elif faction == "pirate":
		goods = ["salvage", "weapon_parts", "electronics", "food"]
	elif faction == "patrol":
		goods = ["weapon_parts", "mine_proximity", "food"]
	else:
		var cv := -1
		if view != null and "traffic" in view and view.traffic != null:
			cv = view.traffic.convoy_of(self)
		if cv >= 0:
			goods = [String(GameState.convoys.find(cv).get("cargo", "food"))]
		else:
			goods = ["food", "medicine", "alloys", "electronics", "water", "iron_ingot", "aluminium", "silicon"]
			goods.shuffle()
			goods = goods.slice(0, 2)
	goods.shuffle()
	var n := mini(goods.size(), randi_range(1, 3))
	var left := room * randf_range(0.4, 0.9)
	for i in n:
		var cid: String = goods[i]
		var vol := maxf(GameData.item_volume(cid), 0.1)
		var amount := floorf(left / float(n - i) / vol)
		if amount >= 1.0:
			fit.cargo[cid] = float(fit.cargo.get(cid, 0.0)) + amount
			left -= amount * vol


func manifest_text() -> String:
	ensure_manifest()
	var parts: Array = []
	for cid in fit.cargo:
		if float(fit.cargo[cid]) >= 1.0:
			parts.append("%d × %s" % [int(fit.cargo[cid]), GameData.item_name(cid)])
	var t := ", ".join(PackedStringArray(parts)) if not parts.is_empty() else "empty hold"
	if unregistered:
		return "%s carries UNREGISTERED cargo – no manifest: %s." % [display_name(), t]
	return "%s – manifest: %s." % [display_name(), t]


func _repair(delta: float, t: Dictionary) -> void:
	var cost := float(t.get("energy", 0)) * delta
	if fit.capacitor < cost:
		return
	var best = null
	var best_missing := 1.0
	for n in get_tree().get_nodes_in_group("ships"):
		if n == self or n.faction != faction or not n.is_targetable():
			continue
		if position.distance_to(n.position) > float(t["range"]):
			continue
		var ns: Dictionary = n.fit.stats()
		var missing: float = (float(ns["armor_max"]) - n.fit.armor) + (float(ns["structure_max"]) - n.fit.structure)
		if missing > best_missing:
			best_missing = missing
			best = n
	if best == null:
		return
	fit.capacitor -= cost
	var heal := float(t["rate"]) * delta
	var bs: Dictionary = best.fit.stats()
	var to_armor := minf(heal, float(bs["armor_max"]) - best.fit.armor)
	best.fit.armor += to_armor
	best.fit.structure = minf(float(bs["structure_max"]), best.fit.structure + (heal - to_armor))
	tool_beams.append([best.position, Color(0.4, 1.0, 0.5)])


# ---------------------------------------------------------------- Drawing

func _draw() -> void:
	if fit == null:
		return
	var selected := faction == "player" and fit.uid == GameState.active_uid
	# Warp trail
	if in_warp():
		var z: float = view.camera.zoom.x if view != null and view.camera != null else 1.0
		var dir := Vector2.from_angle(heading)
		var p := warp_progress()
		var strength := clampf(minf(p, 1.0 - p) * 6.0, 0.0, 1.0)
		# NPC trails are much shorter and fainter, so a busy system map stays readable
		var npc := fit.uid < 0
		if npc:
			strength *= 0.45
		var trail := (70.0 if npc else 420.0) / z * strength
		for i in 3:
			var off := dir.orthogonal() * (i - 1) * 5.0 / z
			draw_line(off, off - dir * trail * (1.0 - absf(i - 1) * 0.35), Color(0.55, 0.85, 1.0, 0.55 * strength), (4.0 - absf(i - 1) * 2.0) / z)
		draw_circle(Vector2.ZERO, (5.0 if npc else 14.0) / z, Color(0.7, 0.9, 1.0, 0.35 * strength))

	# Tool beams
	for b in tool_beams:
		var p: Vector2 = b[0] - position
		var bc: Color = b[1]
		if b.size() > 2 and b[2] == "mining":
			_draw_mining_beam(p, bc, float(b[3]))
			continue
		draw_line(Vector2.ZERO, p, Color(bc, 0.35), 5.0)
		draw_line(Vector2.ZERO, p, bc, 1.5)

	# Target lock lines for the player ship (active lock brighter)
	if selected and manual:
		for l in locks:
			var ln = l["node"]
			if ln == null or not is_instance_valid(ln):
				continue
			var lc := Color(1.0, 0.3, 0.3) if (ln is Ship and hostile(self, ln)) else Color(1.0, 0.8, 0.3)
			var act: bool = l["key"] == active_lock
			draw_line(Vector2.ZERO, ln.position - position, Color(lc, (0.35 if act else 0.15) + 0.3 * float(l["progress"])), 1.5 if act else 1.0)
	elif selected and target != null and _valid(target):
		var tp: Vector2 = target.position - position
		draw_line(Vector2.ZERO, tp, Color(1.0, 0.3, 0.3, 0.25 + 0.35 * lock_progress), 1.0)

	# Hull (pixel art; the Empress' pool and glass dome are animated, package 25c)
	var tex := PixelArt.ship_texture(fit.hull_id, paint, PixelArt.anim_frame(fit.hull_id))
	var arms: Dictionary = fit.hull().get("arms", {})
	if not arms.is_empty():
		tex = PixelArt.ship_texture(String(arms["body"]), paint, PixelArt.anim_frame(String(arms["body"])))
	var size := Vector2(tex.get_width(), tex.get_height()) * PixelArt.SCALE
	draw_set_transform(Vector2.ZERO, heading, Vector2.ONE)
	var multi_flames: Array = []
	if velocity.length() > 20.0:
		var glow: Color = PixelArt.engine_glow(paint)
		var flick := randf_range(0.8, 1.2)
		var fa := _cloak_alpha_at(0.0, tex.get_width())     # the stern goes first under the cloak
		var ep: Array = PixelArt.engine_points(String(arms["body"]) if not arms.is_empty() else fit.hull_id)
		if arms.has("shift"):
			# drives on the hull and on the moving wings (Concordia): a flame for each, moving with the
			# wings – drawn after the wings (they would cover them), at the rear edge of each drive
			ep = []
			for g in PixelArt.engine_groups(String(arms["body"])):
				multi_flames.append([g[0], maxf(float(g[1]), 12.0) * flick, glow])
			var n := int(arms.get("frames", 1))
			var idx := clampi(int(round(smoothstep(0.0, 1.0, arm_open) * float(n - 1))), 0, n - 1)
			for g2 in PixelArt.engine_groups("%s_%d" % [String(arms["art"]), idx]):
				multi_flames.append([g2[0], maxf(float(g2[1]), 10.0) * flick, glow])
		elif ep.is_empty():
			var ex := -size.x * 0.5
			draw_circle(Vector2(ex - 2.0, 0.0), size.y * 0.16 * flick, Color(glow, 0.35 * fa))
			draw_circle(Vector2(ex, 0.0), size.y * 0.09 * flick, Color(1, 1, 1, 0.8 * fa))
		else:
			for e in ep:                      # one flame per drive (package 25d: the Goliath's arm drives)
				var p: Vector2 = e[0]
				var r := float(e[1]) * flick
				draw_circle(p - Vector2(2.0, 0.0), r, Color(glow, 0.35 * fa))
				draw_circle(p, r * 0.55, Color(1, 1, 1, 0.8 * fa))
	var mod := Color(1.8, 1.8, 1.8) if hit_flash > 0.0 else Color.WHITE
	if cloak_k > 0.0:
		_draw_cloaked_hull(tex, size, mod)
	else:
		draw_texture_rect(tex, Rect2(-size * 0.5, size), false, mod)
	if fit.hull().has("black_hole"):
		_draw_black_hole(tex, _cloak_alpha_at(float(fit.hull()["black_hole"]["core"][0]) + 1.0, tex.get_width()))
	if not arms.is_empty():
		_draw_arms(arms, size, mod)
	_draw_hatches()                      # after the arms/wings: the Concordia's doors sit on its wings
	if fit.hull().get("stripe_fx", false):
		_draw_stripes(size)
	if fit.hull().get("spike_fx", false):
		_draw_spikes(size)
	for mf in multi_flames:
		var mp: Vector2 = mf[0] - Vector2(PixelArt.SCALE * 1.5, 0.0)
		draw_circle(mp - Vector2(float(mf[1]) * 0.4, 0.0), float(mf[1]), Color(mf[2], 0.35))
		draw_circle(mp, float(mf[1]) * 0.5, Color(1, 1, 1, 0.8))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if selected:
		draw_arc(Vector2.ZERO, radius + 9.0, 0.0, TAU, 40, Color(0.3, 1.0, 0.5, 0.9), 1.5)
	if view != null and view.hovered == self:
		draw_arc(Vector2.ZERO, radius + 13.0, 0.0, TAU, 40, Color(1, 1, 1, 0.6), 1.0)

	# Status bars
	var s := fit.stats()
	var w := maxf(36.0, radius * 1.6)
	var y := -radius - 18.0
	_bar(Vector2(-w / 2.0, y), w, fit.shield, s["shield_max"], Color(0.35, 0.65, 1.0))
	_bar(Vector2(-w / 2.0, y + 4.0), w, fit.armor, s["armor_max"], Color(1.0, 0.8, 0.3))
	_bar(Vector2(-w / 2.0, y + 8.0), w, fit.structure, s["structure_max"], Color(0.9, 0.3, 0.3))

	if spool >= 0.0:
		var need := spool_need if String(order.get("type", "")) == "warp" else float(s["spool"])
		var frac := minf(spool / maxf(need, 0.1), 1.0)
		draw_arc(Vector2.ZERO, radius + 18.0, -PI / 2.0, -PI / 2.0 + TAU * frac, 40, Color(0.6, 0.5, 1.0), 3.0)


## Mining laser: pulsing beam with travelling energy packets, a shimmering sheath and a hot,
## sparking impact point on the asteroid's surface.
func _draw_mining_beam(to: Vector2, bc: Color, target_r: float) -> void:
	var dist := to.length()
	if dist < 1.0:
		return
	var dir := to / dist
	var side := dir.orthogonal()
	var start := dir * radius * 0.45
	var end := to - dir * target_r * 0.55
	var t := Time.get_ticks_msec() / 1000.0
	var pulse := 0.75 + 0.25 * sin(t * 19.0)
	draw_line(start, end, Color(bc, 0.12 * pulse), 16.0)
	draw_line(start, end, Color(bc, 0.35 * pulse), 7.0)
	draw_line(start, end, Color(bc.lightened(0.55), 0.95), 2.2)
	# shimmering sheath around the core
	var segs := 14
	var prev := start
	for k in range(1, segs + 1):
		var f := float(k) / segs
		var q := start.lerp(end, f) + side * sin(t * 14.0 + f * 11.0) * 3.5 * sin(f * PI)
		draw_line(prev, q, Color(bc.lightened(0.3), 0.55), 1.2)
		prev = q
	# energy packets travelling to the rock
	for k in 4:
		var f2 := fposmod(t * 1.7 + k * 0.25, 1.0)
		draw_circle(start.lerp(end, f2), 3.6, Color(1.0, 1.0, 0.85, 0.85 * (1.0 - absf(f2 - 0.5) * 1.4)))
	# impact: hot spot, glow and sparks thrown back from the surface
	draw_circle(end, 11.0 * pulse, Color(bc, 0.3))
	draw_circle(end, 5.0, Color(1.0, 0.95, 0.8, 0.95))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(t * 20.0)
	for k in 7:
		var ang := (-dir).angle() + rng.randf_range(-1.2, 1.2)
		var len := rng.randf_range(6.0, 22.0)
		var sp := end + Vector2.from_angle(ang) * rng.randf_range(2.0, 8.0)
		draw_line(sp, sp + Vector2.from_angle(ang) * len, Color(1.0, rng.randf_range(0.7, 0.95), 0.5, 0.85), 1.4)


func _bar(pos: Vector2, w: float, v: float, vmax: float, col: Color) -> void:
	if vmax <= 0.0:
		return
	draw_rect(Rect2(pos, Vector2(w, 3.0)), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(pos, Vector2(w * clampf(v / vmax, 0.0, 1.0), 3.0)), col)


func info_text() -> String:
	var s := fit.stats()
	var who: String = {"player": "Your ship", "pirate": "Pirate", "neutral": "Neutral", "civilian": "Civilian", "patrol": "Patrol"}.get(faction, faction)
	if fit.gov != "":
		who += " (%s – your standing: %s)" % [FactionData.name_of(fit.gov), GameState.rep.tier_name(fit.gov)]
	if faction != "player" and hostile_to_player():
		who += " – HOSTILE"
	if convoy_lead and escort_mark:
		who += " – %s LEAD (the others follow it)" % escort_kind.to_upper()
	elif escort_mark:
		who += " – your %s" % escort_kind
	if warrant_known and archetype != "":
		who += " – %s" % ArchData.name_of(archetype)
	if fleeing:
		who += " (fleeing)"
	var t := "%s\n%s %s – %s\n" % [display_name(), fit.hull()["class"], fit.hull()["name"], who]
	t += "Shield %.0f/%.0f  Armor %.0f/%.0f  Structure %.0f/%.0f\n" % [fit.shield, s["shield_max"], fit.armor, s["armor_max"], fit.structure, s["structure_max"]]
	t += "DPS: opt %.0f / kin %.0f / exp %.0f" % [s["dps"]["optical"], s["dps"]["kinetic"], s["dps"]["explosive"]]
	if shield_down > 0.0:
		t += "\nShield down – back in %d s" % int(ceil(shield_down))
	if cargo_known:
		t += "\n" + manifest_text()
	if activity != "":
		t += "\n" + activity
	return t
