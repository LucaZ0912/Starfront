extends Node
## Rebindable controls. Every game action is a Godot InputMap action with up to two bindings
## (keyboard keys or extra mouse buttons). Defaults = the controls described in the help.
## Custom bindings are stored in user://keybinds.cfg and can be reset in Settings → Controls.
##
## Not rebindable: left click (select / move), right click, mouse wheel (zoom) and
## middle-mouse dragging (pan camera).

signal changed

const PATH := "user://keybinds.cfg"

## Binding descriptor: {"k": keycode} for keys (0.7.52.9: + "shift": true for Shift+key), {"m": mouse button index} for mouse buttons.
const ACTIONS := [
	{"id": "ship_up", "label": "Fly up (north)", "group": "Flight", "def": [{"k": KEY_W}]},
	{"id": "ship_down", "label": "Fly down (south)", "group": "Flight", "def": [{"k": KEY_S}]},
	{"id": "ship_left", "label": "Fly left (west)", "group": "Flight", "def": [{"k": KEY_A}]},
	{"id": "ship_right", "label": "Fly right (east)", "group": "Flight", "def": [{"k": KEY_D}]},
	{"id": "cam_up", "label": "Pan camera up", "group": "Camera", "def": [{"k": KEY_UP}]},
	{"id": "cam_down", "label": "Pan camera down", "group": "Camera", "def": [{"k": KEY_DOWN}]},
	{"id": "cam_left", "label": "Pan camera left", "group": "Camera", "def": [{"k": KEY_LEFT}]},
	{"id": "cam_right", "label": "Pan camera right", "group": "Camera", "def": [{"k": KEY_RIGHT}]},
	{"id": "cam_center", "label": "Centre camera on ship", "group": "Camera", "def": [{"k": KEY_SPACE}, {"m": MOUSE_BUTTON_MIDDLE}]},
	{"id": "zoom_combat", "label": "Zoom: Combat", "group": "Camera", "def": [{"k": KEY_F1}]},
	{"id": "zoom_recon", "label": "Zoom: Recon", "group": "Camera", "def": [{"k": KEY_F2}]},
	{"id": "zoom_orbit", "label": "Zoom: Orbit (moons round a planet)", "group": "Camera", "def": [{"k": KEY_F3}]},     # 0.6.36.2
	{"id": "zoom_system", "label": "Zoom: System", "group": "Camera", "def": [{"k": KEY_F4}]},
	{"id": "module_1", "label": "Module 1", "group": "Modules", "def": [{"k": KEY_1}]},
	{"id": "module_2", "label": "Module 2", "group": "Modules", "def": [{"k": KEY_2}]},
	{"id": "module_3", "label": "Module 3", "group": "Modules", "def": [{"k": KEY_3}]},
	{"id": "module_4", "label": "Module 4", "group": "Modules", "def": [{"k": KEY_4}]},
	{"id": "module_5", "label": "Module 5", "group": "Modules", "def": [{"k": KEY_5}]},
	{"id": "module_6", "label": "Module 6", "group": "Modules", "def": [{"k": KEY_6}]},
	{"id": "module_7", "label": "Module 7", "group": "Modules", "def": [{"k": KEY_7}]},
	{"id": "module_8", "label": "Module 8", "group": "Modules", "def": [{"k": KEY_8}]},
	{"id": "module_9", "label": "Module 9", "group": "Modules", "def": [{"k": KEY_9}]},
	{"id": "walk_up", "label": "Walk up", "group": "On foot", "def": [{"k": KEY_W}, {"k": KEY_UP}]},          # package 49
	{"id": "walk_down", "label": "Walk down", "group": "On foot", "def": [{"k": KEY_S}, {"k": KEY_DOWN}]},
	{"id": "walk_left", "label": "Walk left", "group": "On foot", "def": [{"k": KEY_A}, {"k": KEY_LEFT}]},
	{"id": "walk_right", "label": "Walk right", "group": "On foot", "def": [{"k": KEY_D}, {"k": KEY_RIGHT}]},
	{"id": "interact", "label": "Use (door, terminal, airlock)", "group": "On foot", "def": [{"k": KEY_E}]},
	{"id": "foot_run", "label": "Run", "group": "On foot", "def": [{"k": KEY_SHIFT}]},          # 0.7.52.9: its own, apart from the ship's thrust
	{"id": "foot_belt_1", "label": "Belt place 1", "group": "On foot", "def": [{"k": KEY_1}]},
	{"id": "foot_belt_2", "label": "Belt place 2", "group": "On foot", "def": [{"k": KEY_2}]},
	{"id": "foot_belt_3", "label": "Belt place 3", "group": "On foot", "def": [{"k": KEY_3}]},
	{"id": "foot_belt_4", "label": "Belt place 4", "group": "On foot", "def": [{"k": KEY_4}]},
	{"id": "foot_target", "label": "Fight: lock the next target", "group": "On foot", "def": [{"k": KEY_R}]},          # package 52 (0.7.52.2, Luz: R)
	{"id": "foot_target_near", "label": "Fight: lock the foe nearest to you", "group": "On foot", "def": [{"k": KEY_R, "shift": true}]},   # 0.7.52.9
	{"id": "foot_grenade", "label": "Fight: grenade (tap: next, hold: throw)", "group": "On foot", "def": [{"k": KEY_X}]},
	{"id": "foot_drone", "label": "Fight: drone (kamikaze: dive, others: recall / send)", "group": "On foot", "def": [{"k": KEY_C}]},      # 0.7.52.11
	{"id": "foot_tactics", "label": "Fight: tactical view (tap: switch, hold: off)", "group": "On foot", "def": [{"k": KEY_TAB}]},
	{"id": "foot_zoom", "label": "Fight: tactical view zoom (or the wheel)", "group": "On foot", "def": [{"k": KEY_Z}]},          # 0.7.52.8
	{"id": "foot_dodge", "label": "Fight: dodge (a jump no shot hits)", "group": "On foot", "def": [{"k": KEY_SPACE}]},
	{"id": "foot_swap", "label": "Fight: the other weapon in hand", "group": "On foot", "def": [{"k": KEY_Q}]},
	{"id": "boost", "label": "Thrust burst (a few seconds of extra speed)", "group": "Ship commands", "def": [{"k": KEY_SHIFT}]},
	{"id": "sel_target", "label": "Cycle targets in sensor range (ships, asteroids, wrecks, anomalies)", "group": "Ship commands", "def": [{"k": KEY_TAB}]},
	{"id": "sel_hostile", "label": "Cycle hostile ships (nearest first)", "group": "Ship commands", "def": [{"k": KEY_V}]},
	{"id": "sel_friend", "label": "Cycle friendly ships (nearest first)", "group": "Ship commands", "def": [{"k": KEY_C}]},
	{"id": "sel_station", "label": "Select the nearest station (within 5,000 km)", "group": "Ship commands", "def": [{"k": KEY_B}]},
	{"id": "drone_launch", "label": "Launch one drone", "group": "Drones", "def": [{"k": KEY_K}]},
	{"id": "drone_launch_all", "label": "Launch all drones", "group": "Drones", "def": []},
	{"id": "drone_recall", "label": "Recall drones", "group": "Drones", "def": [{"k": KEY_P}]},
	{"id": "wing_attack", "label": "Wingmen: attack my target", "group": "Wingmen", "def": [{"k": KEY_N}]},
	{"id": "wing_passive", "label": "Wingmen: passive", "group": "Wingmen", "def": [{"k": KEY_Y}]},
	{"id": "wing_defensive", "label": "Wingmen: defensive", "group": "Wingmen", "def": []},
	{"id": "wing_aggressive", "label": "Wingmen: aggressive", "group": "Wingmen", "def": []},
	{"id": "cmd_lock", "label": "Lock selected target (again: unlock; nothing selected: nearest hostile)", "group": "Ship commands", "def": [{"k": KEY_R}]},
	{"id": "cmd_approach", "label": "Approach selected", "group": "Ship commands", "def": [{"k": KEY_Q}]},
	{"id": "cmd_warp", "label": "Warp to selected", "group": "Ship commands", "def": [{"k": KEY_X}]},
	{"id": "cmd_jump", "label": "Jump through selected gate", "group": "Ship commands", "def": [{"k": KEY_J}]},
	{"id": "cmd_dock", "label": "Dock at selected station", "group": "Ship commands", "def": [{"k": KEY_G}]},
	{"id": "cmd_follow", "label": "Follow selected ship", "group": "Ship commands", "def": [{"k": KEY_F}]},
	{"id": "interdict_hit", "label": "Warp interdictor: hit the timing window", "group": "Modules", "def": [{"k": KEY_E}]},
	{"id": "ship_menu", "label": "Ship menu", "group": "Windows", "def": [{"k": KEY_I}]},
	{"id": "pilot_window", "label": "Pilot window (skills, skill tree)", "group": "Windows", "def": [{"k": KEY_U}]},
	{"id": "station", "label": "Station window", "group": "Windows", "def": [{"k": KEY_L}]},
	{"id": "galaxy_map", "label": "Galaxy map", "group": "Windows", "def": [{"k": KEY_M}]},
	{"id": "map_territory", "label": "Galaxy map: territory overlay on/off", "group": "Windows", "def": [{"k": KEY_T}]},
	{"id": "help", "label": "Help", "group": "Windows", "def": [{"k": KEY_H}]},
	{"id": "menu_back", "label": "Close window / pause menu", "group": "Windows", "def": [{"k": KEY_ESCAPE}]},
	{"id": "quicksave", "label": "Quicksave", "group": "Game", "def": [{"k": KEY_F5}]},
	{"id": "quickload", "label": "Quickload", "group": "Game", "def": [{"k": KEY_F9}]},
	{"id": "debug_menu", "label": "Debug menu", "group": "Game", "def": [{"k": KEY_F12}]},
	# 0.5.28.2: keyboard control of the menus – only while a menu is open, so the keys may repeat flight keys
	{"id": "menu_up", "label": "Menu: up", "group": "Menus", "def": [{"k": KEY_W}]},
	{"id": "menu_down", "label": "Menu: down", "group": "Menus", "def": [{"k": KEY_S}]},
	{"id": "menu_left", "label": "Menu: left", "group": "Menus", "def": [{"k": KEY_A}]},
	{"id": "menu_right", "label": "Menu: right", "group": "Menus", "def": [{"k": KEY_D}]},
	{"id": "menu_prev_tab", "label": "Menu: previous tab", "group": "Menus", "def": [{"k": KEY_Q}]},
	{"id": "menu_next_tab", "label": "Menu: next tab", "group": "Menus", "def": [{"k": KEY_E}]},
]
const SLOTS := 2
const LAYOUT := 6   # default layout version (2: WASD = flight, arrows = camera; 3: Tab = all targets; 4: F3 Orbit, F4 System; 5: on foot R target, Tab tactics; 6: on foot Shift+R, X grenade)
## Bindings reset once when a saved file is older than this layout (prefix -> layout that changed it)
const LAYOUT_RESETS := {"cam_": 2, "sel_": 3, "zoom_": 4, "foot_": 6}

var binds := {}   # action id -> Array of descriptors (size SLOTS, {} = empty)


func _ready() -> void:
	reset_to_defaults(false)
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		var saved_layout := int(cfg.get_value("meta", "layout", 1))
		for a in ACTIONS:
			var reset := false
			for pre in LAYOUT_RESETS:
				if String(a["id"]).begins_with(pre) and saved_layout < int(LAYOUT_RESETS[pre]):
					reset = true         # the default layout changed for these keys: take the new defaults
			if reset:
				continue
			if cfg.has_section_key("keys", a["id"]):
				var v = cfg.get_value("keys", a["id"])
				if v is Array:
					binds[a["id"]] = _normalize(v)
	_apply_all()


func _normalize(list: Array) -> Array:
	var out: Array = []
	for i in SLOTS:
		out.append(list[i] if i < list.size() and list[i] is Dictionary else {})
	return out


func reset_to_defaults(save_now: bool = true) -> void:
	for a in ACTIONS:
		binds[a["id"]] = _normalize((a["def"] as Array).duplicate(true))
	_apply_all()
	if save_now:
		save()
		changed.emit()


var persist := true   # false in automated tests (never touch the player's file)


func save() -> void:
	if not persist:
		return
	var cfg := ConfigFile.new()
	for id in binds:
		cfg.set_value("keys", id, binds[id])
	cfg.set_value("meta", "layout", LAYOUT)
	cfg.save(PATH)


func _apply_all() -> void:
	for a in ACTIONS:
		var id: String = a["id"]
		if not InputMap.has_action(id):
			InputMap.add_action(id)
		InputMap.action_erase_events(id)
		for d in binds.get(id, []):
			var ev := desc_to_event(d)
			if ev != null:
				InputMap.action_add_event(id, ev)


## Assigns a binding. A binding used by another action is removed there first.
## Returns the label of the action that lost the binding ("" if none).
func _is_menu(id: String) -> bool:
	return _context(id) == "menu"


## Package 49: menus, on foot and in space are separate contexts – a key may do one thing in each.
func _context(id: String) -> String:
	for a in ACTIONS:
		if a["id"] == id:
			match String(a["group"]):
				"Menus":
					return "menu"
				"On foot":
					return "foot"
	return "space"


func set_binding(id: String, slot: int, d: Dictionary) -> String:
	var taken_from := ""
	if not d.is_empty():
		for other in binds:
			if _context(other) != _context(id):
				continue                          # menu, on-foot and space keys may share a key (0.5.28.2, package 49)
			var list: Array = binds[other]
			for i in list.size():
				if same(list[i], d) and not (other == id and i == slot):
					list[i] = {}
					taken_from = label_of(other)
	binds[id][slot] = d
	_apply_all()
	save()
	changed.emit()
	return taken_from


static func same(a: Dictionary, b: Dictionary) -> bool:
	return not a.is_empty() and a.get("k", -1) == b.get("k", -1) and a.get("m", -1) == b.get("m", -1) and bool(a.get("shift", false)) == bool(b.get("shift", false))


static func desc_to_event(d: Dictionary) -> InputEvent:
	if d.has("k"):
		var e := InputEventKey.new()
		e.keycode = int(d["k"])
		e.shift_pressed = bool(d.get("shift", false))
		return e
	if d.has("m"):
		var m := InputEventMouseButton.new()
		m.button_index = int(d["m"])
		return m
	return null


## Event -> descriptor, or {} if it cannot be bound (left/right click, wheel, modifiers alone).
static func event_to_desc(ev: InputEvent) -> Dictionary:
	if ev is InputEventKey:
		var kc: int = (ev as InputEventKey).keycode
		if kc in [KEY_CTRL, KEY_ALT, KEY_META, KEY_NONE]:      # 0.6.75.2: Shift may be bound (the thrust burst)
			return {}
		if (ev as InputEventKey).shift_pressed and kc != KEY_SHIFT:
			return {"k": kc, "shift": true}                  # 0.7.52.9: Shift+key
		return {"k": kc}
	if ev is InputEventMouseButton:
		var b: int = (ev as InputEventMouseButton).button_index
		if b in [MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_XBUTTON1, MOUSE_BUTTON_XBUTTON2]:
			return {"m": b}
	return {}


static func desc_text(d: Dictionary) -> String:
	if d.has("k"):
		return ("Shift+" if bool(d.get("shift", false)) else "") + OS.get_keycode_string(int(d["k"]))
	if d.has("m"):
		match int(d["m"]):
			MOUSE_BUTTON_MIDDLE:
				return "Middle mouse"
			MOUSE_BUTTON_XBUTTON1:
				return "Mouse 4"
			MOUSE_BUTTON_XBUTTON2:
				return "Mouse 5"
		return "Mouse %d" % int(d["m"])
	return "–"


func label_of(id: String) -> String:
	for a in ACTIONS:
		if a["id"] == id:
			return a["label"]
	return id


## Short text of the first binding, e.g. for "Ship [I]" buttons and tile hotkeys.
func key_text(id: String) -> String:
	for d in binds.get(id, []):
		if not d.is_empty():
			return desc_text(d)
	return ""


## Both bindings joined, e.g. "Space / Middle mouse".
func keys_text(id: String) -> String:
	var parts: PackedStringArray = []
	for d in binds.get(id, []):
		if not d.is_empty():
			parts.append(desc_text(d))
	return " / ".join(parts) if not parts.is_empty() else "unbound"
