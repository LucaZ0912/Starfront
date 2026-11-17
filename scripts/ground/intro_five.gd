extends Node
## Package 56 – the intro, sequence 5 (Luz): the flight training. Chosen in the bar, Dan waits in his hangar by Old
## Betty (the lift goes to the bar and the hangar, the rest greyed out); at the stairs "Start the flight training?".
## Yes: Betty pulls away from the station and takes you to the nearest wreck field, where she puts out one of Dan's
## remote drones (rust brown, a shield, a laser, a mining laser – the ship you fly for now). Dan's radio calls lead
## through the lessons, each kept in the journal under Flight training (story mission "flight_training"): flying, zoom
## and the views (warp and the gates locked), mining scrap, unloading at Betty, a second load further out – where two
## pirates come out from behind a wreck colossus. The fight: lock, fire, drive them off; at first they barely hurt you.
## Win: one down, the other runs. Lose (the drone shot down): the camera swings back to Betty, they run. Dan explains
## the pirates; Betty takes you home; in the hangar Dan wants a word in the bar – speaking to him there begins
## sequence 6. Fly too far from Betty: a warning, then the drone is lost and a new one comes out. Saved in the middle of
## the flight, it starts again at the stairs in the hangar. Hold Esc (Options) to skip the scenes in flight.

signal finished

const MID := "flight_training"
const WINDOW := Vector2(20.6, 8.6)          # Dan at the bar's window (as in sequence 4)
const DAN_SHIP := Vector2(4.2, 0.2)         # Dan beside the stairs up to Old Betty (tiles from the stairs' middle)
const PILOT_SHIP := Vector2(2.2, 0.8)
const SKIP_HOLD := 1.2
const WARN_MARGIN := 7000.0                 # beyond the far colossus: Dan warns …
const LOST_MARGIN := 12000.0                # … and here the signal is gone
const SPARE_START := 0.12                   # damage taken while the pirates are only a lesson
const SPARE_LATER := 0.55                   # after the lesson: they can win (the drone is not the pilot's life)
const CLOSING := ["That was good work for a start! You should have the basics down. Everything else is explained in your codex, in the Pilot menu.",
	"Let's pack up."]

var main: Node
var phase := ""
var t := 0.0
var skip_held := 0.0
var betty: Ship = null
var drone: ShipFitting = null
var own_uid := -1
var field := {}
var arrival := Vector2.ZERO
var scrap_id := ""
var far_col := {}
var pirates: Array = []
var won := false
var lap := 0.0
var _lap_a := INF
var _warned := false
var _cam_a := Vector2.ZERO
var _cam_b := Vector2.ZERO
var _out_cam := Vector2.ZERO
var _out_dir := Vector2.RIGHT
var _warping := false
var _warp_t := 0.0
var _sweep_t := 0.0
var _views_said := {}
const VIEW_TALK := {
	1: "This is Recon, your radar. It shows you everything worth knowing: resources to mine, friends and foes. But watch out, big objects can block your view.",
	2: "Orbit: the moons round a planet, to find your way near one. Like the System map, it's a map. The drone doesn't fly while it's open.",
	3: "And the System map: the whole system at a glance. From here you'd pick where to warp. Not with my drone, though.",
	0: "Back in close: Combat. That's where you fly, fight and mine.",
}
var _layer: CanvasLayer
var _hint: Label
var _said: Array = []                      # radio calls still to come in this phase


func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 75
	add_child(_layer)
	_hint = UI.label("", 13, Color(0.7, 0.75, 0.85, 0.6))
	_hint.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_hint.position = Vector2(-60, 214)                 # under the radio box – clear of the log
	_layer.add_child(_hint)


func ground():
	return main.ground if main != null and main.ground != null and is_instance_valid(main.ground) else null


func view():
	return main.view if main != null and main.view != null and is_instance_valid(main.view) else null


func _phase(p: String) -> void:
	phase = p
	t = 0.0


# ---------------------------------------------------------------- on foot

## The deck while the training waits: the lift to the bar and the hangar, Old Betty in the bay (her stairs start the
## training); Dan at the bar's window – he can be asked a few things.
func _mode_ready() -> Dictionary:
	return {"quiet": true, "keep_bartender": true, "lift_only": "commercial,hangar",
		"lift_labels": {"hangar": "Hangar: Old Betty", "commercial": "Bar"},
		"ship_art": "kanayama", "ship_talk": "ship", "ship_title": "Old Betty: the flight training",
		"levels": {"commercial": {"people": [{"who": "dan", "pos": WINDOW, "dir": 1, "talk": true}]}, "hangar": {"people": []}}}


## Back from the training: Dan in the hangar first, then at the bar's window (speaking to him there: sequence 6).
func _mode_back(dan_in_hangar: bool) -> Dictionary:
	var lv := {"commercial": {"people": [] if dan_in_hangar else [{"who": "dan", "pos": WINDOW, "dir": 1, "marker": "!"}]}}
	lv["hangar"] = {"spawn_ship": PILOT_SHIP, "people": [{"who": "dan", "at_ship": DAN_SHIP, "dir": 1}] if dan_in_hangar else []}
	return {"quiet": true, "keep_bartender": true, "lift_only": "commercial,hangar",
		"lift_labels": {"hangar": "Hangar: Old Betty", "commercial": "Bar: Dan wants a word"}, "ship_art": "kanayama",
		"ship_title": "Old Betty", "ship_talk": "betty", "levels": lv}


## where: "bar" (straight from the talk in sequence 4, on the deck already), "hangar" (a new start or a load) or "back"
## (saved after the training: Dan waits in the bar).
func begin(where: String) -> void:
	var g = ground()
	if g == null:
		return
	if not g.story_talk.is_connected(_on_story_talk):
		g.story_talk.connect(_on_story_talk)
	if where == "back":
		g.story_mode = _mode_back(false)
		g.go_level("commercial", "lift")
		g.input_enabled = true
		_phase("back")
		return
	GameState.story.set_flag("intro_stage", "five")
	g.story_mode = _mode_ready()
	if where == "hangar":
		g.story_mode["levels"]["hangar"]["spawn_ship"] = PILOT_SHIP
		g.go_level("hangar", "story")
	g.input_enabled = true
	_phase("deck")


func _on_story_talk(who: String) -> void:
	var g = ground()
	if g == null:
		return
	if phase == "deck" and who == "ship" and g.level == "hangar":
		GameState.story.flags.erase("tut_go")
		GameState.story.show.emit("dialogue", {"id": "tut_start", "mission": ""})
		_phase("ask")
	elif phase == "deck" and who == "dan" and g.level == "commercial":
		GameState.story.show.emit("dialogue", {"id": "dan_help", "mission": ""})       # Luz: what you can ask him
	elif phase == "back" and who == "dan" and g.level == "commercial":
		_finish()


func _talk_done() -> bool:
	if main == null or main.story_ui == null:
		return true
	return main.story_ui.dialogue == null and main.story_ui._dlg_q.is_empty()


func _radio_done() -> bool:
	if main == null or main.story_ui == null:
		return true
	return main.story_ui._radio == null and main.story_ui._radio_q.is_empty()


## A radio call of Dan's – kept with the training in the journal.
func _radio(text: String) -> void:
	var st = GameState.story
	if st.running(MID):
		st._say(MID, "dan", text, true)
	st.show.emit("radio", {"who": "dan", "text": text, "mission": MID if st.running(MID) else ""})


# ---------------------------------------------------------------- each frame

func _process(delta: float) -> void:
	t += delta
	var skippable: bool = phase in ["fade_out", "out", "launch", "ambush"]
	if skippable and (Input.is_key_pressed(KEY_ESCAPE) or Input.is_joy_button_pressed(0, JOY_BUTTON_START)):
		skip_held += delta
		if skip_held >= SKIP_HOLD:
			skip_held = 0.0
			_skip()
			return
	else:
		skip_held = maxf(0.0, skip_held - delta * 2.0)
	_hint.text = ("Hold %s to skip" % Pad.glyph("options") if Pad.using_pad else "Hold Esc to skip") if skippable else ""
	if phase in ["out", "launch", "lessons", "fight", "ambush", "debrief", "down"]:
		_sweep_t -= delta
		if _sweep_t <= 0.0:
			_sweep_t = 0.5
			_no_strangers()
	match phase:
		"ask":
			if _talk_done():
				if bool(GameState.story.flags.get("tut_go", false)):
					GameState.story.flags.erase("tut_go")
					_leave_deck()
				else:
					_phase("deck")
		"fade_out":
			if t > 0.8:
				_setup_out()
		"out":                                   # Old Betty pulls away from the station, aligns and warps to the field
			var v = view()
			if v != null and _valid(betty):
				v.input_enabled = false
				v.story_follow = betty                    # aboard her: the camera, radar and icon as for your own ship
				if not _warping:
					if t > 2.0:
						_warping = true
						_warp_t = t
						betty.set_order({"type": "warp", "target": {"id": "tut_field", "kind": "field", "name": String(field.get("name", "the wreck field")),
							"pos": arrival, "land": 0.0}, "then": {}})
				else:
					v.story_cam = betty.position          # with her all the way (story_follow keeps the camera on her)
					var ot := String(betty.order.get("type", ""))
					if t - _warp_t > 2.0 and not betty.in_warp() and not ot in ["warp", "warping"]:
						_to_field()
					elif t - _warp_t > 90.0:
						betty.position = arrival
						_to_field()
			elif v != null and t > 1.0:
				_to_field()
		"launch":                                # at the field: the drone comes out
			_launch_step()
		"lessons", "fight":
			_lessons(delta)
		"ambush":
			_ambush_step()
		"down":                                  # the drone shot down – the camera with Betty, the pirates run
			var v2 = view()
			if v2 != null and _valid(betty):
				v2.input_enabled = false
				v2.story_cam = _cam_a.lerp(betty.position, smoothstep(0.0, 1.6, t))
			if t > 3.0 and _said.size() > 0 and _radio_done():
				_radio(_said.pop_front())
			if t > 3.0 and _said.is_empty() and _radio_done():
				_go_home()
		"debrief":                               # won – Dan talks about the pirates, then home
			if _said.size() > 0 and _radio_done():
				_radio(_said.pop_front())
			if t > 1.0 and _said.is_empty() and _radio_done():
				_go_home()
		"home_fade":
			if t > 1.0:
				_at_home()
		"home_talk":
			var g = ground()
			if t > 0.6 and t - delta <= 0.6:
				main.fade(Color(0, 0, 0, 0), 0.8)
			if t > 1.2 and t - delta <= 1.2:
				GameState.story.show.emit("dialogue", {"id": "tut_hangar_back", "mission": ""})
			if t > 1.5 and _talk_done() and g != null:
				g.input_enabled = true
				g.story_mode = _mode_back(false)
				g.story_mode["levels"]["hangar"]["people"] = []
				_phase("back")


func _valid(n) -> bool:
	return n != null and is_instance_valid(n) and not n.dying


func _skip() -> void:
	match phase:
		"fade_out":
			_setup_out()
			_skip()
		"out":
			if _valid(betty):
				betty.position = arrival
				betty.velocity = Vector2.ZERO
				betty.set_order({"type": "idle"})
			_to_field()
			_launch_done()
		"launch":
			_launch_done()
		"ambush":
			_ambush_done()


# ---------------------------------------------------------------- out to the wreck field

func _leave_deck() -> void:
	var g = ground()
	if g != null:
		g.input_enabled = false
	main.fade(Color(0, 0, 0, 1), 0.6)
	_phase("fade_out")


## Betty undocks: the deck closes, she pulls away from the station, the camera with her.
func _setup_out() -> void:
	main.close_deck(false)
	GameState.story.set_flag("intro_stage", "five_fly")
	for fl in GameState.story.flags.keys():
		if String(fl).begins_with("tut_"):
			GameState.story.flags.erase(fl)
	PixelArt.use_rust("kanayama", "dan")
	var v = view()
	var f := GameState.active()
	own_uid = f.uid if f != null else -1
	GameState.story.flags["tut_own"] = own_uid
	_pick_field()
	if v == null or f == null or not v.stations.has(f.docked_at):
		_phase("out")
		t = 99.0
		return
	var st = v.stations[f.docked_at]
	var out: Vector2 = (field["pos"] as Vector2 - st.position).normalized() if not field.is_empty() else Vector2.RIGHT
	var start: Vector2 = st.position + out * (float(st.radius) + 500.0)
	betty = _spawn_betty(start)
	betty.heading = out.angle()
	betty.set_order({"type": "move", "pos": start + out * 20000.0})
	v.input_enabled = false
	v.story_follow = betty                         # you ride with her – the station falls back
	_out_cam = start
	_out_dir = out
	main.fade(Color(0, 0, 0, 0), 1.0)
	_radio("Hold on tight, we're off to the wreck field. It's not far.")
	_phase("out")


## No pirates of their own in the training – only the two the ambush brings.
func _no_strangers() -> void:
	for s in get_tree().get_nodes_in_group("ships"):
		if s is Ship and s.faction == "pirate" and not s.dying and not pirates.has(s) and not s.is_queued_for_deletion():
			s.queue_free()


func _spawn_betty(at: Vector2) -> Ship:
	var v = view()
	var b: Ship = v.spawn_npc("std_kanayama", at, "neutral", "")
	b.paint = "dan"
	b.fit.ship_name = "Old Betty"
	b.fit.stance = "passive"
	b.story_spare = true
	b.toughness = 0.0
	b.align_scale = 0.35                       # no long wait before her warp
	b.home = at
	return b


## The wreck field nearest Dan's station, where Betty stops, the scrap to cut, the colossus further out.
func _pick_field() -> void:
	var sys := GameState.current_system
	var L: Dictionary = Universe.get_layout(sys)
	var f := GameState.active()
	var from := Vector2.ZERO
	for st in L["stations"]:
		if f != null and String(st["id"]) == f.docked_at:
			from = st["pos"]
	var best := INF
	for fd in L["fields"]:
		if not bool(fd.get("wreck", false)):
			continue
		var d: float = (fd["pos"] as Vector2).distance_to(from)
		if d < best:
			best = d
			field = fd
	if field.is_empty():
		for fd2 in L["fields"]:
			field = fd2
			break
	if field.is_empty():
		arrival = from + Vector2(20000, 0)
		return
	var fid := String(field["id"])
	var cols: Array = L.get("colossi", []).filter(func(c): return String(c.get("field", "")) == fid)
	var centre: Vector2 = field["pos"]
	var fr := float(field.get("radius", 8000.0))
	# Betty stops on the side of the field towards the station; the colossus furthest from there is the far one
	arrival = centre + (from - centre).normalized() * fr * 0.35
	var fd3 := -1.0
	for c in cols:
		var d2: float = (c["pos"] as Vector2).distance_to(arrival)
		if d2 > fd3:
			fd3 = d2
			far_col = c
	var bs := INF
	for a in L["asteroids"]:
		if String(a.get("field", "")) != fid:
			continue
		var d3: float = (a["pos"] as Vector2).distance_to(arrival)
		if d3 < bs and d3 > 900.0:
			bs = d3
			scrap_id = String(a["id"])


## Betty at the field: the drone is now the ship you fly (yours waits in Dan's hangar) – it rolls down her flight deck.
func _to_field() -> void:
	var v = view()
	if v == null:
		return
	if not _valid(betty):
		betty = _spawn_betty(arrival)
	arrival = betty.position
	v.story_follow = null
	betty.set_order({"type": "idle"})
	betty.velocity = Vector2.ZERO
	betty.home = arrival
	drone = GameState.create_from_preset("tut_dan_drone", "player")
	drone.ship_name = "Dan's drone"
	drone.system_id = GameState.current_system
	drone.docked_at = ""
	drone.position = betty.deck_point(0.0)
	GameState.add_ship(drone)
	GameState.active_uid = drone.uid
	GameState.active_changed.emit()
	v = view()
	if v.player != null:
		v.player.position = betty.deck_point(0.0)
		v.player.heading = betty.heading
		v.player.paint = "dan"
		v.player.story_spare = true
		v.player.toughness = SPARE_START
		v.player.visible = false
	v.story_leash = true
	v.input_enabled = false
	v.story_cam = betty.position
	_phase("launch")


func _launch_step() -> void:
	var v = view()
	if v == null:
		return
	v.input_enabled = false
	if _valid(betty):
		v.story_cam = betty.position
	if not _valid(betty) or v.player == null:
		_launch_done()
		return
	# like Betty's own drones: down the whole flight deck from her stern, faster and faster, then off over the bow
	var fwd := Vector2.from_angle(betty.heading)
	var a: Vector2 = betty.deck_point(0.0)
	var b: Vector2 = betty.deck_point(1.0) + fwd * 260.0
	if t > 1.0 and not v.player.visible:
		v.player.visible = true
		Audio.play("drone_launch", "the training drone", -4.0)
	v.player.position = a.lerp(b, pow(clampf((t - 1.0) / 2.2, 0.0, 1.0), 1.7))
	v.player.velocity = Vector2.ZERO
	v.player.heading = betty.heading
	v.story_cam = betty.position.lerp(v.player.position, smoothstep(1.0, 3.4, t))
	if t > 3.6:
		_launch_done()


func _launch_done() -> void:
	var v = view()
	if v != null and v.player != null:
		v.player.visible = true
		v.player.paint = "dan"
		v.player.story_spare = true
		v.player.toughness = SPARE_START
		if not v.player.spared.is_connected(_on_drone_down):
			v.player.spared.connect(_on_drone_down)
	if v != null:
		v.story_cam = Vector2.INF
		v.follow = true
		v.input_enabled = true
		v.story_leash = true
	main._update_input()
	if not GameState.story.running(MID):
		GameState.story.start(MID)
		GameState.story.track(MID)
	_phase("lessons")


# ---------------------------------------------------------------- the lessons

func _lessons(delta: float) -> void:
	var v = view()
	var st = GameState.story
	if v == null or v.player == null or not is_instance_valid(v.player) or not _valid(betty):
		return
	var p: Ship = v.player
	if p.paint != "dan":
		p.paint = "dan"                       # the drone in Dan's rust (a ship synced anew starts in the pilot's colours)
		p.story_spare = true
		p.toughness = SPARE_START if not st.flags.has("tut_hit") else SPARE_LATER
		if not p.spared.is_connected(_on_drone_down):
			p.spared.connect(_on_drone_down)
	var step := String(st.step_data(MID).get("id", ""))
	var want: String = {"mine": scrap_id, "unload": "ship:%d" % betty.fit.uid, "far": String(far_col.get("id", ""))}.get(step, "")
	if st.running(MID) and String(st.missions[MID].get("target", "")) != want:
		st.missions[MID]["target"] = want
		st.changed.emit()
	if step != "views" and v.story_zoom != "":
		v.story_zoom = ""                          # the zoom free again after the lesson
	match step:
		"fly":
			var d: Vector2 = p.position - betty.position
			if d.length() < 5000.0 and d.length() > 150.0:
				var a := d.angle()
				if _lap_a != INF:
					lap += wrapf(a - _lap_a, -PI, PI)
				_lap_a = a
				if absf(lap) >= TAU * 0.95:
					st.set_flag("tut_lap")
		"views":
			# Luz: Dan says what each view is for, the first time you reach it – the zoom waits while he talks, one view
			# after the other
			var lv := int(v.level)
			if not _views_said.has(lv) and VIEW_TALK.has(lv) and (lv != 0 or _views_said.size() > 0):
				_views_said[lv] = true
				_radio(VIEW_TALK[lv])
				v.story_zoom = "locked"
			elif v.story_zoom == "locked" and _radio_done():
				v.story_zoom = "step"
			elif v.story_zoom == "":
				v.story_zoom = "step"
			match int(v.level):
				1:
					if not st.flags.has("tut_recon"):
						st.set_flag("tut_recon")
				3:
					if not st.flags.has("tut_system"):
						st.set_flag("tut_system")
				0:
					if st.flags.has("tut_recon") and st.flags.has("tut_system") and not st.flags.has("tut_combat"):
						st.set_flag("tut_combat")
		"mine":
			if p.fit.cargo_used() >= 4.0:
				st.set_flag("tut_mined")
		"far":
			if not p.fit.cargo.is_empty():
				p.fit.cargo = {}                   # Dan took the load aboard Betty
				GameState.log_msg("Dan takes the scrap aboard Old Betty.", GameState.COL_GOOD)
			if far_col.is_empty() or p.position.distance_to(far_col["pos"]) < float(far_col.get("radius", 1000.0)) + 3500.0:
				_ambush()
				return
		"lock", "fire", "finish":
			# both pirates gone without one shot down (they ran or warped off): the fight is over all the same
			if phase == "fight" and not pirates.any(func(pr): return _valid(pr) and pr.position.distance_to(p.position) < 15000.0):
				_on_pirate_down(null)
				return
	match step:
		"lock":
			for l in p.locks:
				if pirates.has(l.get("node")):
					st.set_flag("tut_locked")
		"fire":
			for pr in pirates:
				if _valid(pr) and pr.last_attacker == p:
					st.set_flag("tut_hit")
					p.toughness = SPARE_LATER        # the lesson is over – from now on they can win
	# the drone's leash: Betty's signal
	var far: float = betty.position.distance_to(p.position)
	var warn: float = (arrival.distance_to(far_col["pos"]) + float(far_col.get("radius", 1000.0)) if not far_col.is_empty() else 12000.0) + WARN_MARGIN
	if far > warn + LOST_MARGIN - WARN_MARGIN:
		_drone_lost()
	elif far > warn and not _warned:
		_warned = true
		_radio("You're about to lose contact with Betty. Turn back!")
	elif far < warn * 0.85:
		_warned = false


## Too far from Betty: the signal is gone, the drone with it – a new one comes out of Betty.
func _drone_lost() -> void:
	var v = view()
	var p: Ship = v.player
	v.spawn_fx(Fx.explosion(p.position, 60.0, Color(1.0, 0.6, 0.25)))
	p.position = betty.position + Vector2.from_angle(betty.heading).orthogonal() * 650.0
	p.velocity = Vector2.ZERO
	p.set_order({"type": "idle"})
	p.locks.clear()
	p.fit.refill()
	p.fit.cargo = {}
	v.center_on_player()
	_warned = false
	_radio("Lost her signal, she's scrap now. Here, I'm sending out another one. Stay close this time.")


# ---------------------------------------------------------------- the ambush

func _ambush() -> void:
	var v = view()
	var p: Ship = v.player
	var cp: Vector2 = far_col.get("pos", p.position + Vector2(3000, 0))
	var R := float(far_col.get("radius", 1000.0))
	var toward: Vector2 = (p.position - cp).normalized()
	var side := toward.orthogonal()
	pirates.clear()
	for k in 2:
		var sgn := -1.0 if k == 0 else 1.0
		var behind: Vector2 = cp - toward * R * 1.1 + side * sgn * 350.0
		var pr: Ship = v.spawn_npc("pirate_raider_laser", behind, "pirate")
		pr.fit.modules.erase("weapon_1")                # one gun each – a lesson, not an execution
		for slot in pr.fit.modules.keys():
			if String(pr.fit.modules[slot]).contains("jammer"):
				pr.fit.modules[slot] = "o_shield_s"
		pr.fit.mark_dirty()
		pr.fit.ship_name = "Pirate Carrion Crow"
		pr.bounty = 0
		pr.set_order({"type": "move", "pos": cp + side * sgn * R * 1.3 + toward * R * 0.4})
		pr.destroyed.connect(_on_pirate_down)
		pirates.append(pr)
	p.set_order({"type": "idle"})
	v.input_enabled = false
	v.story_zoom = ""
	v.set_level(0)                               # Luz: the scene in the Combat view
	_cam_a = p.position
	_cam_b = cp + toward * R * 0.2
	_phase("ambush")


func _ambush_step() -> void:
	var v = view()
	if v == null or v.player == null:
		return
	v.input_enabled = false
	var mid := _cam_b
	var n := 0
	var sum := Vector2.ZERO
	for pr in pirates:
		if _valid(pr):
			sum += pr.position
			n += 1
	if n > 0:
		mid = sum / n
	if t < 4.4:
		v.story_cam = _cam_a.lerp(mid, smoothstep(0.0, 1.6, t))
	else:
		v.story_cam = mid.lerp(v.player.position, smoothstep(4.4, 5.6, t))
	if t > 1.6 and t - get_process_delta_time() <= 1.6:
		_radio("Contacts! Two of them, behind that wreck! Pirates!")
	if t > 5.8:
		_ambush_done()


func _ambush_done() -> void:
	var v = view()
	var p: Ship = v.player
	for pr in pirates:
		if _valid(pr):
			pr.set_order({"type": "attack", "target": p})
			pr.target = p
	v.story_cam = Vector2.INF
	v.follow = true
	v.input_enabled = true
	main._update_input()
	GameState.story.set_flag("tut_ambush")
	_radio("Lock on to one of them: %s, then %s!" % [Keybinds.key_text("sel_hostile"), Keybinds.key_text("cmd_lock")])
	_phase("fight")


func _on_pirate_down(_s) -> void:
	if phase != "fight" or won:
		return
	won = true
	var st = GameState.story
	for fl in ["tut_locked", "tut_hit", "tut_fight_over"]:
		if not st.flags.has(fl):
			st.set_flag(fl)
	_send_off()
	_said = ["Pirates. Clans of them, out here in the Veil and all over the Cluster. They pick on anything that looks easy: miners, haulers, lone pilots.",
		"Most of them run once it turns ugly. Keep your shields up, keep moving, and don't wander off alone with a full hold."] + CLOSING
	_radio("Ha! Look at that one run. Not bad for someone three hundred years out of practice.")
	_radio(_said.pop_front())
	_phase("debrief")


## The pirates leave – off their attack, away from the drone and Betty, then out on a warp.
func _send_off() -> void:
	for pr in pirates:
		if _valid(pr):
			pr.set_order({"type": "idle"})
			pr.target = null
			pr._start_fleeing(betty if _valid(betty) else view().player)
			pr.fleeing = true
			pr._flee_t = 20.0                       # straight on to the warp out


## The drone took a blow that would have killed it: it is gone – the camera swings back to Betty, the pirates run.
func _on_drone_down(_s) -> void:
	if phase != "fight":
		return
	var v = view()
	var p: Ship = v.player
	v.spawn_fx(Fx.explosion(p.position, 70.0, Color(1.0, 0.55, 0.2)))
	p.visible = false
	p.set_order({"type": "idle"})
	p.velocity = Vector2.ZERO
	p.toughness = 0.0
	p.fit.refill()                               # gone – no hull alarm for a drone that is no more
	p.locks.clear()
	v.input_enabled = false
	_cam_a = p.position
	var st = GameState.story
	for fl in ["tut_locked", "tut_hit", "tut_fight_over"]:
		if not st.flags.has(fl):
			st.set_flag(fl)
	_send_off()
	_said = ["Pirates. Clans of them, out here in the Veil and all over the Cluster. They pick on anything that looks easy: miners, haulers, lone pilots.",
		"Most of them run once they've got what they came for, or once it turns ugly. Keep your shields up, keep moving, and don't wander off alone with a full hold."] + CLOSING
	_radio("Well, that's what drones are for. Better her than you.")
	_phase("down")


# ---------------------------------------------------------------- home

func _go_home() -> void:
	main.fade(Color(0, 0, 0, 1), 0.8)
	var v = view()
	if v != null:
		v.input_enabled = false
	_phase("home_fade")


## Black: the drone back to Dan, your own ship active again in his hangar, onto the deck – Dan by Betty's stairs.
func _at_home() -> void:
	var v = view()
	for pr in pirates:
		if is_instance_valid(pr):
			pr.queue_free()
	pirates.clear()
	if is_instance_valid(betty):
		betty.queue_free()
	if v != null:
		v.story_leash = false
		v.story_zoom = ""
		v.story_cam = Vector2.INF
	tidy()
	GameState.story.set_flag("tut_home")
	GameState.story.set_flag("intro_stage", "five_back")
	main.open_deck()
	var g = ground()
	if g == null:
		_phase("back")
		return
	if not g.story_talk.is_connected(_on_story_talk):
		g.story_talk.connect(_on_story_talk)
	g.input_enabled = false
	g.story_mode = _mode_back(true)
	g.go_level("hangar", "story")
	main.fade(Color(0, 0, 0, 1), 0.01)
	_phase("home_talk")


## The drone given back: out of the fleet, your own ship active again where it waited (also after a load in the middle
## of the flight).
static func tidy() -> void:
	var own := int(GameState.story.flags.get("tut_own", -1))
	for f in GameState.fleet.duplicate():
		if f.hull_id == "dan_drone":
			GameState.fleet.erase(f)
	var back := GameState.get_fit(own)
	if back == null:
		for f2 in GameState.fleet:
			if f2.docked_at != "":
				back = f2
				break
	if back != null:
		GameState.active_uid = back.uid
	GameState.fleet_changed.emit()
	GameState.active_changed.emit()


## Dan spoken to in the bar: sequence 6 begins (with the next part of the intro).
func _finish() -> void:
	GameState.story.set_flag("intro_stage", "six")
	main._start_intro_six("talk")                          # sequence 6: Dan's menu at once (scripts/ground/intro_six.gd)
	_phase("done")
	finished.emit()
	queue_free()
