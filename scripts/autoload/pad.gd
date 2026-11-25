extends Node
## Package 80 (Luz): full controller support – PlayStation (DualSense) and Xbox, the glyphs following the controller you
## hold (and back to the keys when you touch the keyboard). Every button is rebindable per context (flight, on foot,
## menus), saved in user://controller.cfg with the settings (on/off, glyphs, dead zones, speeds, vibration).
##
## How it works: the sticks go straight into the game (flying and the camera through SystemView, walking through the
## InputMap's walk_* actions); the buttons are read here each frame and turned into the game's own actions (an
## InputEventAction – the same handlers as the keys), into fire groups (a D-pad direction held + a shoulder button),
## or into what only a controller has: the action wheel (□ held), the window wheel (Options held), the list on the
## right (Touchpad), flicking the right stick at a foe on foot.

signal changed
signal device_changed

const PATH := "user://controller.cfg"
const BUTTONS := ["cross", "circle", "square", "triangle", "l1", "r1", "l2", "r2", "l3", "r3", "up", "down", "left", "right",
	"options", "create", "touchpad"]
const JOY := {"cross": JOY_BUTTON_A, "circle": JOY_BUTTON_B, "square": JOY_BUTTON_X, "triangle": JOY_BUTTON_Y,
	"l1": JOY_BUTTON_LEFT_SHOULDER, "r1": JOY_BUTTON_RIGHT_SHOULDER, "l3": JOY_BUTTON_LEFT_STICK, "r3": JOY_BUTTON_RIGHT_STICK,
	"up": JOY_BUTTON_DPAD_UP, "down": JOY_BUTTON_DPAD_DOWN, "left": JOY_BUTTON_DPAD_LEFT, "right": JOY_BUTTON_DPAD_RIGHT,
	"options": JOY_BUTTON_START, "create": JOY_BUTTON_BACK, "touchpad": JOY_BUTTON_TOUCHPAD}
const GLYPH_PS := {"cross": "✕", "circle": "◯", "square": "□", "triangle": "△", "l1": "L1", "r1": "R1", "l2": "L2", "r2": "R2",
	"l3": "L3", "r3": "R3", "up": "↑", "down": "↓", "left": "←", "right": "→", "options": "Options", "create": "Create", "touchpad": "Touchpad"}
const GLYPH_XB := {"cross": "A", "circle": "B", "square": "X", "triangle": "Y", "l1": "LB", "r1": "RB", "l2": "LT", "r2": "RT",
	"l3": "LS", "r3": "RS", "up": "↑", "down": "↓", "left": "←", "right": "→", "options": "Menu", "create": "View", "touchpad": "Share"}

## Every action a controller button can do: [id, label, context, default binding]. A binding is {"b": button} or a
## combination {"hold": button, "b": button}. The id is the game's own action (the same as the key's) or one of the
## controller's own ("pad_…"); module_1 … module_8 are the fire groups.
const ACTIONS := [
	["boost", "Thrust burst", "space", {"b": "r2"}],
	["sel_target", "Next target in sensor range", "space", {"b": "l1"}],
	["sel_hostile", "Next hostile ship", "space", {"b": "r1"}],
	["cmd_lock", "Lock / unlock the selected target", "space", {"b": "triangle"}],
	["pad_wheel", "Action wheel (hold)", "space", {"b": "square"}],
	["pad_deselect", "Deselect (tap) · drone wheel (hold)", "space", {"b": "circle"}],
	["interdict_hit", "Interdictor: the timing window", "space", {"b": "cross"}],
	["module_1", "Fire group 1", "space", {"hold": "left", "b": "l1"}],
	["module_2", "Fire group 2", "space", {"hold": "left", "b": "r1"}],
	["module_3", "Fire group 3", "space", {"hold": "left", "b": "l2"}],
	["module_4", "Fire group 4", "space", {"hold": "left", "b": "r2"}],
	["module_5", "Fire group 5", "space", {"hold": "right", "b": "l1"}],
	["module_6", "Fire group 6", "space", {"hold": "right", "b": "r1"}],
	["module_7", "Fire group 7", "space", {"hold": "right", "b": "l2"}],
	["module_8", "Fire group 8", "space", {"hold": "right", "b": "r2"}],
	["pad_zoom_in", "Zoom in", "space", {"b": "up"}],
	["pad_zoom_out", "Zoom out", "space", {"b": "down"}],
	["pad_list", "The list on the right (overview · contacts)", "space", {"b": "touchpad"}],
	["cam_center", "Camera back to the ship", "space", {"b": "r3"}],
	["pad_options", "Pause (tap) · window wheel (hold)", "space", {"b": "options"}],
	["galaxy_map", "Galaxy map", "space", {"b": "create"}],
	["interact", "Use · door · talk · sit (hold: revive)", "ground", {"b": "cross"}],
	["foot_dodge", "Dodge", "ground", {"b": "circle"}],
	["foot_swap", "The other weapon in hand", "ground", {"b": "square"}],
	["foot_team", "Ground team (tap: whom · hold: command wheel)", "ground", {"b": "triangle"}],
	["foot_tactics", "Tactical view (tap: switch · hold: off)", "ground", {"b": "l1"}],
	["foot_target", "Next target", "ground", {"b": "r1"}],
	["foot_grenade", "Grenade (tap: next · hold: throw)", "ground", {"b": "r2"}],
	["foot_drone", "Drone", "ground", {"b": "l2"}],
	["foot_drone_2", "Second drone (□ held + L2)", "ground", {"hold": "square", "b": "l2"}],     # (Luz: □ first – L2 alone stays the first drone)
	["foot_sneak", "Sneak on / off", "ground", {"b": "l3"}],
	["foot_target_near", "The foe nearest to you", "ground", {"b": "r3"}],
	["foot_belt_1", "Belt place 1", "ground", {"b": "up"}],
	["foot_belt_2", "Belt place 2", "ground", {"b": "right"}],
	["foot_belt_3", "Belt place 3", "ground", {"b": "down"}],
	["foot_belt_4", "Belt place 4", "ground", {"b": "left"}],
	["foot_zoom", "Zoom: near · out", "ground", {"b": "touchpad"}],
	["pad_options", "Pause (tap) · window wheel (hold)", "ground", {"b": "options"}],
	["pad_confirm", "Confirm", "menu", {"b": "cross"}],
	["menu_back", "Back / close", "menu", {"b": "circle"}],
	["menu_prev_tab", "Previous tab", "menu", {"b": "l1"}],
	["menu_next_tab", "Next tab", "menu", {"b": "r1"}],
	["pad_up", "Up", "menu", {"b": "up"}],
	["pad_down", "Down", "menu", {"b": "down"}],
	["pad_left", "Left", "menu", {"b": "left"}],
	["pad_right", "Right", "menu", {"b": "right"}],
]
const CONTEXTS := ["space", "ground", "menu"]

# the settings
var enabled := true
var glyphs := "auto"                # "auto" · "ps" · "xbox"
var dead_l := 0.15
var dead_r := 0.2
var cam_speed := 0.55
var flick := 0.6
var trigger := 0.35
var aim_speed := 0.5
var mg_aim := 0.3                    # billiards and darts: how fast the stick aims (Luz: slower – finer)
var invert := false
var run_full := true
var vibration := true
var vib_strength := 0.7

var binds := {}                     # "context:id" -> binding
var device := -1                    # the controller in use (-1: none)
var kind := ""                      # "ps" · "xbox" · "" (none)
var using_pad := false              # the last input came from the controller (the glyphs follow it)
var capture := ""                   # "context:id" waiting for a button (Settings → Controller)
var persist := true                 # false in automated tests
var _down := {}                     # button -> pressed this frame
var _active := {}                   # button -> [context, id] pressed and not yet released
var _used_hold := {}                # a hold button that made a combination (its own action is not done)
var _pending := {}                  # a hold button that also has an action of its own: [seconds left, context, id]
var _rep := {}                      # menu direction -> seconds until it repeats
var _stick_dir := Vector2.ZERO      # the left stick's menu direction last frame
var _flick_armed := true
var _opt_t := -1.0                  # how long Options is held (-1: up)
var _circ_t := -1.0                 # package 58: how long ◯ is held in space (tap: deselect, held: the drone wheel)
var list_mode := false              # the list on the right is being picked from
var _list_i := 0
var wheel: Control = null           # the action / window wheel while it is open
var _wheel_layer: CanvasLayer = null
var _wheel_btn := ""
var _hint: CanvasLayer = null
var events: Array = []              # the last actions done (smoke test)
var _mg_down := {}                  # button -> the game (or menu) that took it
var sim_on := false                 # the smoke test plays a controller: these buttons and sticks
var sim_btn := {}
var sim_l := Vector2.ZERO
var sim_r := Vector2.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	reset_binds()
	_load()
	_strip_ui_joypad()
	Keybinds.changed.connect(_apply_axes)
	_apply_axes()
	Input.joy_connection_changed.connect(func(_d, _c): _pick_device())
	Players.changed.connect(func():              # split screen: this is the first player's controller from here on
		_pick_device()
		_apply_axes())
	_pick_device()


# ---------------------------------------------------------------- settings and bindings

func reset_binds() -> void:
	binds = {}
	for a in ACTIONS:
		binds["%s:%s" % [a[2], a[0]]] = (a[3] as Dictionary).duplicate()


func binding(ctx: String, id: String) -> Dictionary:
	return binds.get("%s:%s" % [ctx, id], {})


## Sets a binding; another action of the same context on the same button (or combination) loses it. Returns the label
## of the action that lost it ("" none).
func set_binding(ctx: String, id: String, b: Dictionary) -> String:
	var lost := ""
	for k in binds.keys():
		if String(k).begins_with(ctx + ":") and k != "%s:%s" % [ctx, id] and _same(binds[k], b) and not b.is_empty():
			binds[k] = {}
			lost = label_of(ctx, String(k).split(":")[1])
	binds["%s:%s" % [ctx, id]] = b
	save()
	changed.emit()
	return lost


func _same(a: Dictionary, b: Dictionary) -> bool:
	return String(a.get("b", "")) == String(b.get("b", "")) and String(a.get("hold", "")) == String(b.get("hold", "")) and not a.is_empty()


func label_of(ctx: String, id: String) -> String:
	for a in ACTIONS:
		if a[2] == ctx and a[0] == id:
			return String(a[1])
	return id


func save() -> void:
	if not persist:
		return
	var cfg := ConfigFile.new()
	for k in ["enabled", "glyphs", "dead_l", "dead_r", "cam_speed", "flick", "trigger", "aim_speed", "mg_aim", "invert", "run_full", "vibration", "vib_strength"]:
		cfg.set_value("settings", k, get(k))
	for k2 in binds:
		cfg.set_value("binds", String(k2).replace(":", "__"), binds[k2])
	cfg.save(PATH)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	for k in ["enabled", "glyphs", "dead_l", "dead_r", "cam_speed", "flick", "trigger", "aim_speed", "mg_aim", "invert", "run_full", "vibration", "vib_strength"]:
		if cfg.has_section_key("settings", k):
			set(k, cfg.get_value("settings", k))
	if cfg.has_section("binds"):
		for k2 in cfg.get_section_keys("binds"):
			var key := String(k2).replace("__", ":")
			if binds.has(key) and cfg.get_value("binds", k2) is Dictionary:
				binds[key] = cfg.get_value("binds", k2)
	var d2: Dictionary = binds.get("ground:foot_drone_2", {})
	if (String(d2.get("hold", "")) == "l2" and String(d2.get("b", "")) == "r1") or (String(d2.get("hold", "")) == "r1" and String(d2.get("b", "")) == "l2"):
		binds["ground:foot_drone_2"] = {"hold": "square", "b": "l2"}   # (earlier defaults: L2 + R1, R1 + L2)


## A setting changed in Settings → Controller.
func set_setting(k: String, v) -> void:
	set(k, v)
	_apply_axes()
	save()
	changed.emit()
	device_changed.emit()


## Godot's own ui_* actions answer the controller too – the menus are driven from here instead (else every press
## would move the highlight twice).
func _strip_ui_joypad() -> void:
	for act in ["ui_accept", "ui_select", "ui_cancel", "ui_up", "ui_down", "ui_left", "ui_right", "ui_focus_next", "ui_focus_prev",
			"ui_page_up", "ui_page_down", "ui_home", "ui_end"]:
		if not InputMap.has_action(act):
			continue
		for ev in InputMap.action_get_events(act):
			if ev is InputEventJoypadButton or ev is InputEventJoypadMotion:
				InputMap.action_erase_event(act, ev)


## The left stick walks (the InputMap's walk_* – analog, with the dead zone); put back whenever the keys are rebound.
func _apply_axes() -> void:
	for spec in [["walk_left", JOY_AXIS_LEFT_X, -1.0], ["walk_right", JOY_AXIS_LEFT_X, 1.0], ["walk_up", JOY_AXIS_LEFT_Y, -1.0], ["walk_down", JOY_AXIS_LEFT_Y, 1.0]]:
		var act: String = spec[0]
		if not InputMap.has_action(act):
			continue
		for ev in InputMap.action_get_events(act):
			if ev is InputEventJoypadMotion:
				InputMap.action_erase_event(act, ev)
		if enabled and not (Players.split and Players.pad_of(0) < 0):
			var m := InputEventJoypadMotion.new()
			m.device = Players.pad_of(0) if Players.split else -1     # split screen: only the first player's stick walks them
			m.axis = spec[1]
			m.axis_value = spec[2]
			InputMap.action_add_event(act, m)
		InputMap.action_set_deadzone(act, maxf(dead_l, 0.05))


func _pick_device() -> void:
	var pads := Input.get_connected_joypads()
	device = pads[0] if not pads.is_empty() else -1
	if Players.split:                            # split screen: the controller of whose windows these are (the first player's, mostly), or none (the keyboard)
		device = Players.pad_of(Players.act_seat) if Players.pad_of(Players.act_seat) in pads else -1
	kind = ""
	if device >= 0:
		var nm := Input.get_joy_name(device).to_lower()
		kind = "ps" if (nm.contains("ps5") or nm.contains("ps4") or nm.contains("dualsense") or nm.contains("dualshock") or nm.contains("playstation") or nm.contains("sony")) else "xbox"
	if device < 0:
		using_pad = false
	device_changed.emit()


## The controller's name as the game shows it ("DualSense (PS5)", "Xbox controller", "").
func device_name() -> String:
	if device < 0:
		return ""
	return ("DualSense / DualShock" if kind == "ps" else "Xbox controller") + "  (%s)" % Input.get_joy_name(device)


# ---------------------------------------------------------------- glyphs

func glyph_set() -> String:
	if glyphs == "ps" or glyphs == "xbox":
		return glyphs
	return kind if kind != "" else "ps"


func glyph(btn: String) -> String:
	return String((GLYPH_PS if glyph_set() == "ps" else GLYPH_XB).get(btn, btn))


func binding_text(b: Dictionary) -> String:
	if b.is_empty():
		return "–"
	if b.has("hold"):
		return "%s + %s" % [glyph(String(b["hold"])), glyph(String(b["b"]))]
	return glyph(String(b["b"]))


## The glyph of a game action in the context you are in ("" if the controller does not do it) – Keybinds.key_text
## shows it instead of the key while the controller is in use.
func action_text(id: String) -> String:
	if not enabled or not using_pad:
		return ""
	var ctx := context()
	if id in ["drone_launch", "drone_recall", "drone_launch_all"] and ctx in ["space", "menu"]:
		return glyph(_btn_of("space", "pad_deselect", "circle")) + " held"        # package 58: the drone wheel
	for c in [ctx, "space" if ctx == "menu" else ctx, "menu", "ground", "space", "minigame"]:
		var b := binding(c, id)
		if not b.is_empty():
			return binding_text(b)                         # (Luz: explained in a window, a foot action still shows its button)
	return ""


# ---------------------------------------------------------------- where you are

func _main() -> Node:
	var m := get_tree().current_scene
	return m if m != null and "ground" in m and "view" in m else null


func context() -> String:
	if MenuNav.menu_open():
		return "menu"
	var m := _main()
	if m == null:
		return "menu"
	if m.ground != null and is_instance_valid(m.ground):
		if m.ground.minigame != null:
			return "minigame"
		return "ground"
	return "space"


func left_stick() -> Vector2:
	return _stick(JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y, dead_l)


func right_stick() -> Vector2:
	var v := _stick(JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y, dead_r)
	if invert:
		v.y = -v.y
	return v


func _stick(ax: int, ay: int, dz: float) -> Vector2:
	if not enabled or (device < 0 and not sim_on):
		return Vector2.ZERO
	var v := Vector2(Input.get_joy_axis(device, ax), Input.get_joy_axis(device, ay)) if not sim_on else (sim_l if ax == JOY_AXIS_LEFT_X else sim_r)
	var l := v.length()
	if l < dz:
		return Vector2.ZERO
	return v / l * clampf((l - dz) / (1.0 - dz), 0.0, 1.0)


## Flying in space: the left stick (analog – half way, half speed); zero while a menu, the list or a wheel has it.
func flight() -> Vector2:
	if list_mode or wheel != null or context() != "space" or _on_map():
		return Vector2.ZERO
	return left_stick()


## Package 80 (Luz): the Orbit or the System view – a map: the stick picks, ✕ goes there.
func _on_map() -> bool:
	var m := _main()
	return m != null and m.view != null and is_instance_valid(m.view) and m.view.has_method("is_map") and m.view.is_map()


var _map_armed := true


func _map_step() -> void:
	var l := left_stick()
	if l.length() < 0.35:
		_map_armed = true
		return
	if not _map_armed or l.length() < 0.6:
		return
	_map_armed = false
	var m := _main()
	var id: String = m.view.map_flick(l)
	if id != "":
		events.append("map:" + id)


## The camera in space: the right stick (not while a wheel picks with it).
func camera() -> Vector2:
	if wheel != null or context() != "space":
		return Vector2.ZERO
	return right_stick() * lerpf(0.4, 2.2, cam_speed)


## On foot: the stick pushed all the way runs.
func run_held() -> bool:
	return enabled and run_full and context() == "ground" and left_stick().length() > 0.92


## On foot with the controller: where the grenade and the "mouse" point are – ahead of you along the right stick.
func aim_point(from: Vector2, facing: Vector2) -> Vector2:
	var r := right_stick()
	if r.length() > 0.2:
		return from + r * lerpf(70.0, 160.0, aim_speed)
	return from + facing * 80.0


# ---------------------------------------------------------------- each frame

func _input(event: InputEvent) -> void:
	if Players.split and not Players.owns(Players.act_seat, event):
		return                                    # split screen: the other player's device is not this one's business
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.5):
		if not using_pad:
			using_pad = true
			device_changed.emit()
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN      # (Luz) the mouse away while you play with the controller
		if device != event.device and event.device >= 0:
			device = event.device
	elif event is InputEventKey or event is InputEventMouseButton or (event is InputEventMouseMotion and (event as InputEventMouseMotion).relative.length() > 3.0):
		if Input.mouse_mode == Input.MOUSE_MODE_HIDDEN:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if using_pad and not (event is InputEventMouseMotion):
			using_pad = false
			device_changed.emit()


func _btn(name: String) -> bool:
	if sim_on:
		return bool(sim_btn.get(name, false))
	if device < 0:
		return false
	if name == "l2":
		return Input.get_joy_axis(device, JOY_AXIS_TRIGGER_LEFT) > trigger
	if name == "r2":
		return Input.get_joy_axis(device, JOY_AXIS_TRIGGER_RIGHT) > trigger
	if name == "touchpad" and kind == "xbox":
		return Input.is_joy_button_pressed(device, JOY_BUTTON_MISC1)
	return Input.is_joy_button_pressed(device, int(JOY[name]))


func _process(delta: float) -> void:
	if not enabled or (device < 0 and not sim_on):
		return
	var now := {}
	for b in BUTTONS:
		now[b] = _btn(b)
	if capture != "":
		for b2 in BUTTONS:
			if now[b2] and not _down.get(b2, false):
				_capture_press(b2, now)
				break
		_down = now
		return
	var ctx := context()
	for b3 in BUTTONS:
		var was: bool = _down.get(b3, false)
		if now[b3] and not was:
			_press(b3, ctx, now)
		elif was and not now[b3]:
			_release(b3, ctx)
	_down = now
	for p in _pending.keys():
		_pending[p][0] = float(_pending[p][0]) - delta
		if float(_pending[p][0]) <= 0.0:
			var pe: Array = _pending[p]
			_pending.erase(p)
			_do(String(pe[1]), String(pe[2]), true)
			_active[p] = [pe[1], pe[2]]
	if _opt_t >= 0.0:
		_opt_t += delta
		if _opt_t > 0.35 and wheel == null and ctx in ["space", "ground"]:
			_open_wheel("windows", "options")
	if _circ_t >= 0.0:
		_circ_t += delta
		if _circ_t > 0.3 and wheel == null and ctx == "space" and _has_drones():
			_open_wheel("drones", _btn_of("space", "pad_deselect", "circle"))
	var own_stick = _pad_target(ctx)
	if (ctx == "menu" or list_mode) and not (own_stick != null and own_stick.has_method("pad_stick")):
		_menu_stick(delta, ctx)
	if ctx == "menu":
		_menu_scroll(delta)
	if ctx == "ground":
		_flick_step()
	if ctx == "space" and not list_mode and wheel == null and _on_map():
		_map_step()
	var st = _pad_target(ctx)
	if st != null and st.has_method("pad_stick"):
		st.pad_stick(left_stick(), right_stick(), delta)
	if wheel != null:
		wheel.pick(right_stick() if right_stick() != Vector2.ZERO else left_stick())
	_update_hint(ctx)


func _press(b: String, ctx: String, now: Dictionary) -> void:
	if list_mode and ctx == "space":
		_list_press(b)
		return
	if wheel != null:
		if (b == "circle" and _wheel_btn != "circle") or (b == "cross" and _wheel_btn == "circle"):
			_close_wheel(false)                             # (the drone wheel is on ◯ itself: ✕ cancels it)
			_circ_t = -1.0
		return
	var c2 := "ground" if ctx == "minigame" else ctx
	if ctx == "space" and b == "cross" and _on_map():
		var mv = _main().view
		if String(mv.selected_id) != "":                   # on the map ✕ goes to the pick (warp, or the way there)
			var e := Commands.execute({"type": "goto", "id": String(mv.selected_id)})
			if e != "":
				GameState.log_msg(e, GameState.COL_WARN)
			events.append("goto")
		return
	var tgt = _pad_target(ctx)
	var mg_self = _self_reader(b)
	if mg_self != null:
		return                                             # the game reads this button itself (pad_buttons)
	if tgt != null and tgt.pad_button(b, true):
		_mg_down[b] = tgt                                  # (the game takes this button – its release too)
		return
	if ctx == "minigame" and b == "circle":
		_do("minigame", "menu_back", true)
		_do("minigame", "menu_back", false)
		return
	if ctx == "minigame" and b == "cross":
		_do("minigame", "foot_dodge", true)                # the cutter's and the hack's button
		_active[b] = ["minigame", "foot_dodge"]
		return
	# a combination first: this button with a held one
	for k in binds:
		var bd: Dictionary = binds[k]
		if String(k).begins_with(c2 + ":") and bd.get("b", "") == b and bd.has("hold") and now.get(String(bd["hold"]), false):
			var hb := String(bd["hold"])
			_used_hold[hb] = true
			_pending.erase(hb)
			var id0 := String(k).split(":")[1]
			_do(c2, id0, true)
			_active[b] = [c2, id0]
			return
	var id := _plain(c2, b)
	if id == "":
		return
	# a button that is also held for combinations waits a moment – a combination may follow
	if _is_hold(c2, b):
		_used_hold.erase(b)
		_pending[b] = [0.22, c2, id]
		return
	_do(c2, id, true)
	_active[b] = [c2, id]


func _release(b: String, ctx: String) -> void:
	if _self_reader(b) != null:
		return
	if _mg_down.has(b):
		var t = _mg_down[b]
		_mg_down.erase(b)
		if is_instance_valid(t):
			t.pad_button(b, false)
		return
	if wheel != null and b == _wheel_btn:
		_close_wheel(true)
		_opt_t = -1.0
		_circ_t = -1.0
		_active.erase(b)
		return
	if _circ_t >= 0.0 and b == _btn_of("space", "pad_deselect", "circle"):
		_circ_t = -1.0                                    # let go before the wheel: a tap, deselect
		_active.erase(b)
		var m0 := _main()
		if m0 != null and m0.view != null and String(m0.view.selected_id) != "":
			m0.view.select("")
		return
	if b == "options" and _opt_t >= 0.0:
		var short := _opt_t <= 0.35
		_opt_t = -1.0
		if short:
			_do(ctx, "menu_back", true)
			_do(ctx, "menu_back", false)
		return
	if _pending.has(b):
		var pe: Array = _pending[b]
		_pending.erase(b)
		if not _used_hold.get(b, false):
			_do(String(pe[1]), String(pe[2]), true)
			_do(String(pe[1]), String(pe[2]), false)
		_used_hold.erase(b)
		return
	_used_hold.erase(b)
	if _active.has(b):
		var a: Array = _active[b]
		_active.erase(b)
		_do(String(a[0]), String(a[1]), false)


## Is a controller button held now (the games that read their buttons themselves – pad_buttons).
func held(b: String) -> bool:
	return enabled and bool(_down.get(b, false))


## A minigame (or a menu) with controls of its own: pad_button(button, pressed) -> taken, pad_stick(left, right, dt).
func _pad_target(ctx: String):
	var t = null
	if ctx == "menu":
		t = MenuNav.active_menu()
	elif ctx == "minigame":
		var m := _main()
		t = m.ground.minigame if m != null and m.ground != null else null
	if t != null and is_instance_valid(t) and t.has_method("pad_button"):
		return t
	return null


## A minigame on foot that reads this button itself (its pad_buttons) – whatever the context says.
func _self_reader(b: String):
	var m := _main()
	if m == null or m.ground == null or not is_instance_valid(m.ground) or m.ground.minigame == null:
		return null
	var g = m.ground.minigame
	if is_instance_valid(g) and "pad_buttons" in g and b in g.pad_buttons:
		return g
	return null


func _plain(ctx: String, b: String) -> String:
	for k in binds:
		var bd: Dictionary = binds[k]
		if String(k).begins_with(ctx + ":") and bd.get("b", "") == b and not bd.has("hold"):
			return String(k).split(":")[1]
	return ""


func _is_hold(ctx: String, b: String) -> bool:
	for k in binds:
		if String(k).begins_with(ctx + ":") and String((binds[k] as Dictionary).get("hold", "")) == b:
			return true
	return false


## Does an action: the controller's own, a fire group, or the game's action (the same handlers as the key).
func _do(ctx: String, id: String, pressed: bool) -> void:
	if pressed:
		events.append(id)
		if events.size() > 40:
			events.pop_front()
	var m := _main()
	if id.begins_with("pad_"):
		if pressed:
			_special(ctx, id, m)
		return
	if id.begins_with("module_") and ctx == "space":
		if pressed and m != null and m.hud != null:
			m.hud.activate_index(int(id.substr(7)) - 1)
		return
	var ev := InputEventAction.new()
	ev.action = id
	ev.pressed = pressed
	ev.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(ev)


func _special(ctx: String, id: String, m) -> void:
	match id:
		"pad_confirm":
			var menu := MenuNav.active_menu()
			if menu != null and menu.has_method("tour_confirm"):
				menu.tour_confirm()                                 # package 58: the guided tour goes on
				return
			var focus: Control = MenuNav.current(menu) if menu != null else get_viewport().gui_get_focus_owner()
			if menu != null and focus == null:
				MenuNav.step(menu, Vector2.DOWN)                 # nothing highlighted yet: the first
				return
			MenuNav.keep(menu, focus)
			if menu != null and MenuNav.is_soft(menu):          # (split screen: a window in your half keeps a highlight of its own)
				MenuNav.press(menu)
				get_tree().create_timer(0.06, true).timeout.connect(func(): MenuNav.restore(menu))
				return
			var ev := InputEventAction.new()
			ev.action = "ui_accept"
			ev.pressed = true
			Input.parse_input_event(ev)
			var ev2 := InputEventAction.new()
			ev2.action = "ui_accept"
			ev2.pressed = false
			Input.parse_input_event(ev2)
			get_tree().create_timer(0.06, true).timeout.connect(func(): MenuNav.restore(menu))      # back to it if the menu was rebuilt
		"pad_up", "pad_down", "pad_left", "pad_right":
			var menu2 := MenuNav.active_menu()
			if menu2 != null:
				MenuNav.step(menu2, {"pad_up": Vector2.UP, "pad_down": Vector2.DOWN, "pad_left": Vector2.LEFT, "pad_right": Vector2.RIGHT}[id])
		"pad_deselect":
			_circ_t = 0.0                                      # let go: deselect; held: the drone wheel
		"pad_zoom_in", "pad_zoom_out":
			if m != null and m.view != null:
				var lv: int = clampi(int(m.view.level) + (-1 if id == "pad_zoom_in" else 1), 0, 3)
				if lv == 2 and m.view.player != null and is_instance_valid(m.view.player) and m.view.player.in_warp():
					lv = 3 if id == "pad_zoom_out" else 1
				m.view.set_level(lv)
		"pad_list":
			list_mode = not list_mode
			_list_i = 0
			if list_mode:
				_list_focus(0)
			else:
				get_viewport().gui_release_focus()
		"pad_wheel":
			_open_wheel("actions", "square")
		"pad_options":
			_opt_t = 0.0


# ---------------------------------------------------------------- menus by controller

func _menu_stick(delta: float, ctx: String) -> void:
	var v := left_stick()
	var dir := Vector2.ZERO
	if v.length() > 0.55:
		dir = Vector2(signf(v.x), 0) if absf(v.x) > absf(v.y) else Vector2(0, signf(v.y))
	if dir == Vector2.ZERO:
		_stick_dir = Vector2.ZERO
		return
	if dir != _stick_dir:
		_stick_dir = dir
		_rep["stick"] = 0.35
	else:
		_rep["stick"] = float(_rep.get("stick", 0.35)) - delta
		if float(_rep["stick"]) > 0.0:
			return
		_rep["stick"] = 0.12
	if list_mode and ctx == "space":
		if dir.y != 0.0:
			_list_focus(_list_i + int(dir.y))
		return
	var menu := MenuNav.active_menu()
	if menu != null:
		MenuNav.step(menu, dir)


func _menu_scroll(delta: float) -> void:
	var r := right_stick()
	if absf(r.y) < 0.1:
		return
	var menu := MenuNav.active_menu()
	var f: Control = MenuNav.current(menu) if menu != null else get_viewport().gui_get_focus_owner()
	var n: Node = f
	while n != null and not (n is ScrollContainer):
		n = n.get_parent()
	if n == null:
		if menu != null:
			for c in menu.find_children("*", "ScrollContainer", true, false):
				if (c as Control).is_visible_in_tree():
					n = c
					break
	if n != null:
		(n as ScrollContainer).scroll_vertical += int(r.y * 900.0 * delta)


# ---------------------------------------------------------------- the list on the right (space)

func _list_rows() -> Array:
	var m := _main()
	if m == null or m.hud == null:
		return []
	var box: Control = m.hud.overview_box if m.hud._ov_tab == "overview" else m.hud.contacts_box
	var out: Array = []
	for c in box.get_children():
		if c is Button and (c as Button).is_visible_in_tree():
			out.append(c)
	return out


func _list_focus(i: int) -> void:
	var rows := _list_rows()
	if rows.is_empty():
		return
	_list_i = clampi(i, 0, rows.size() - 1)
	var b: Button = rows[_list_i]
	b.focus_mode = Control.FOCUS_ALL
	b.grab_focus()
	var n: Node = b.get_parent()
	while n != null and not (n is ScrollContainer):
		n = n.get_parent()
	if n != null:
		(n as ScrollContainer).ensure_control_visible(b)


func _list_press(b: String) -> void:
	var m := _main()
	match b:
		"up", "down":
			_list_focus(_list_i + (-1 if b == "up" else 1))
		"l1", "r1":
			if m != null and m.hud != null:
				m.hud._set_ov_tab("contacts" if m.hud._ov_tab == "overview" else "overview")
				_list_focus(0)
		"cross":
			var rows := _list_rows()
			if _list_i < rows.size():
				(rows[_list_i] as Button).pressed.emit()
		"circle", "touchpad":
			list_mode = false
			get_viewport().gui_release_focus()


# ---------------------------------------------------------------- on foot: flick the right stick at a foe

func _flick_step() -> void:
	var r := right_stick()
	var m := _main()
	if r.length() < flick:
		if r.length() < flick * 0.5:
			_flick_armed = true
		return
	if not _flick_armed or m == null or m.ground == null or m.ground.combat == null or m.ground.pilot == null:
		return
	if Input.is_action_pressed("foot_grenade"):
		return                                            # the stick aims the grenade
	_flick_armed = false
	var g = m.ground
	var best = null
	var best_a := 0.8
	for f in g.combat.alive():
		var d: Vector2 = (f["w"] as Walker).pos - g.pilot.pos
		if d.length() < 1.0 or d.length() > 600.0:
			continue
		var a := absf(d.angle_to(r))
		if a < best_a:
			best_a = a
			best = f
	if best != null:
		g.combat.lock(best)
		events.append("flick")


# ---------------------------------------------------------------- the wheels

const ACTION_ITEMS := [["Approach", "cmd_approach"], ["Follow", "cmd_follow"], ["Orbit 400 km", "orbit"], ["Warp to", "cmd_warp"],
	["Dock · jump", "dock_jump"], ["Drones out", "drone_launch_all"], ["Drones back", "drone_recall"], ["Wingmen: attack", "wing_attack"]]
const WINDOW_ITEMS := [["Ship", "ship_menu"], ["Pilot · character", "pilot_window"], ["Galaxy map", "galaxy_map"], ["Station", "station"],
	["Help", "help"], ["Journal", "journal"]]


func _open_wheel(which: String, btn: String) -> void:
	_close_wheel(false)
	_wheel_layer = CanvasLayer.new()
	_wheel_layer.layer = 90
	add_child(_wheel_layer)
	wheel = load("res://scripts/ui/pad_wheel.gd").new()
	wheel.items = ACTION_ITEMS if which == "actions" else (_drone_items() if which == "drones" else WINDOW_ITEMS)
	wheel.title = glyph(btn) + " held"
	if which == "drones":
		wheel.title = glyph(btn) + " drones"
	var mw := _main()
	if mw != null and mw.has_method("halves_on") and mw.halves_on():
		mw.win_show(0, wheel)                            # split screen: the wheel is in your half, as your windows are
	else:
		_wheel_layer.add_child(wheel)
	_wheel_btn = btn


## Package 58 (Luz): the drone wheel (◯ held in space) – what the drone panel (top left) does: launch, recall, the
## job (combat · mining · repair) and how it goes about it; the job and the way it works now are marked.
func _drone_items() -> Array:
	var f := GameState.active()
	var role := String(f.drone_role) if f != null else "combat"
	var mode := String(f.drone_modes.get(role, "")) if f != null else ""
	var out: Array = [["Launch", "dw:launch"], ["Recall", "dw:recall"]]
	for r in [["combat", "Combat"], ["mining", "Mining"], ["repair", "Repair"]]:
		out.append([r[1], "dw:role:" + r[0], r[0] == role])
	var names: Dictionary = HUD.DRONE_MODE_NAMES
	for md in Commands.DRONE_ROLES.get(role, []):
		out.append([String(names.get(md, md)), "dw:mode:" + String(md), String(md) == mode])
	return out


## Has the ship drones (in the hangar or out)?
func _has_drones() -> bool:
	var f := GameState.active()
	if f != null and not f.drones.is_empty():
		return true
	var m := _main()
	return m != null and m.view != null and m.view.player != null and is_instance_valid(m.view.player) and not m.view.drones_of(m.view.player).is_empty()


## The button an action is on now (rebinding), or the default.
func _btn_of(ctx: String, id: String, def: String) -> String:
	var b := binding(ctx, id)
	return String(b.get("b", def)) if not b.is_empty() and not b.has("hold") else def


func _close_wheel(do_it: bool) -> void:
	if wheel == null:
		return
	var choice: String = wheel.chosen() if do_it else ""
	if wheel.get_parent() != _wheel_layer:
		wheel.queue_free()
		var mw := _main()
		if mw != null and mw.has_method("win_hide"):
			mw.win_hide(0)
	_wheel_layer.queue_free()
	_wheel_layer = null
	wheel = null
	_wheel_btn = ""
	if choice == "":
		return
	events.append("wheel:" + choice)
	var m := _main()
	if choice.begins_with("dw:"):
		var p := choice.split(":")
		var cmd := {"type": "drone_" + p[1]}
		if p[1] == "role":
			cmd["role"] = p[2]
		elif p[1] == "mode":
			cmd["mode"] = p[2]
		elif p[1] == "launch":
			cmd["count"] = 1
		var e0 := Commands.execute(cmd)
		if e0 != "":
			GameState.log_msg(e0, GameState.COL_WARN)
		return
	match choice:
		"orbit":
			if m != null and m.view != null and String(m.view.selected_id) != "":
				var e := Commands.execute({"type": "orbit", "id": String(m.view.selected_id), "range": 400})
				if e != "":
					GameState.log_msg(e, GameState.COL_WARN)
		"dock_jump":
			var sel = m.view.find_object(String(m.view.selected_id)) if m != null and m.view != null else null
			var act := "cmd_jump" if sel != null and "kind" in sel and String(sel.kind) == "gate" else "cmd_dock"
			_tap(act)
		_:
			_tap(choice)


func _tap(act: String) -> void:
	for p in [true, false]:
		var ev := InputEventAction.new()
		ev.action = act
		ev.pressed = p
		Input.parse_input_event(ev)


# ---------------------------------------------------------------- rebinding (Settings → Controller)

func _capture_press(b: String, now: Dictionary) -> void:
	var parts := capture.split(":")
	if b == "options":
		capture = ""                                     # Options cancels
		changed.emit()
		return
	var hold := ""
	for h in ["left", "right", "l2", "r1", "square", "up", "down"]:
		if h != b and now.get(h, false):
			hold = h
	var bd := {"b": b}
	if hold != "":
		bd["hold"] = hold
	capture = ""
	var lost := set_binding(parts[0], parts[1], bd)
	if lost != "":
		GameState.log_msg("%s lost its button." % lost, GameState.COL_WARN)


# ---------------------------------------------------------------- vibration

## A shake through the controller (hits, explosions, thrust) – as strong as set in Settings → Controller.
func rumble(weak: float, strong: float, sec: float) -> void:
	if not enabled or not vibration or device < 0 or not using_pad:
		return
	Input.start_joy_vibration(device, clampf(weak * vib_strength, 0.0, 1.0), clampf(strong * vib_strength, 0.0, 1.0), sec)


# ---------------------------------------------------------------- the button prompts and the fire group combo

func _update_hint(ctx: String) -> void:
	var show := using_pad and ctx == "space" and _main() != null and wheel == null
	if not show:
		if _hint != null:
			_hint.visible = false
		return
	if _hint == null:
		_hint = CanvasLayer.new()
		_hint.layer = 6
		add_child(_hint)
		var h = load("res://scripts/ui/pad_hint.gd").new()
		h.name = "Hint"
		_hint.add_child(h)
	_hint.visible = true
	var hn = _hint.get_node("Hint")
	hn.combo = "left" if _down.get("left", false) else ("right" if _down.get("right", false) else "")
	hn.list = list_mode
	hn.queue_redraw()
