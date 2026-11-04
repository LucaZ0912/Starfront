extends Node
## Rebindable controls. Every game action is a Godot InputMap action with up to two bindings
## (keyboard keys or extra mouse buttons). Defaults = the controls described in the help.
## Custom bindings are stored in user://keybinds.cfg and can be reset in Settings → Controls.
##
## Not rebindable: left click (select / move), right click, mouse wheel (zoom) and
## middle-mouse dragging (pan camera).

signal changed

const PATH := "user://keybinds.cfg"

## Binding descriptor: {"k": keycode} for keys, {"m": mouse button index} for mouse buttons.
const ACTIONS := [
	{"id": "cam_up", "label": "Pan camera up", "group": "Camera", "def": [{"k": KEY_W}, {"k": KEY_UP}]},
	{"id": "cam_down", "label": "Pan camera down", "group": "Camera", "def": [{"k": KEY_S}, {"k": KEY_DOWN}]},
	{"id": "cam_left", "label": "Pan camera left", "group": "Camera", "def": [{"k": KEY_A}, {"k": KEY_LEFT}]},
	{"id": "cam_right", "label": "Pan camera right", "group": "Camera", "def": [{"k": KEY_D}, {"k": KEY_RIGHT}]},
	{"id": "cam_center", "label": "Centre camera on ship", "group": "Camera", "def": [{"k": KEY_SPACE}, {"m": MOUSE_BUTTON_MIDDLE}]},
	{"id": "zoom_combat", "label": "Zoom: Combat", "group": "Camera", "def": [{"k": KEY_F1}]},
	{"id": "zoom_recon", "label": "Zoom: Recon", "group": "Camera", "def": [{"k": KEY_F2}]},
	{"id": "zoom_system", "label": "Zoom: System", "group": "Camera", "def": [{"k": KEY_F3}]},
	{"id": "module_1", "label": "Module 1", "group": "Modules", "def": [{"k": KEY_1}]},
	{"id": "module_2", "label": "Module 2", "group": "Modules", "def": [{"k": KEY_2}]},
	{"id": "module_3", "label": "Module 3", "group": "Modules", "def": [{"k": KEY_3}]},
	{"id": "module_4", "label": "Module 4", "group": "Modules", "def": [{"k": KEY_4}]},
	{"id": "module_5", "label": "Module 5", "group": "Modules", "def": [{"k": KEY_5}]},
	{"id": "module_6", "label": "Module 6", "group": "Modules", "def": [{"k": KEY_6}]},
	{"id": "module_7", "label": "Module 7", "group": "Modules", "def": [{"k": KEY_7}]},
	{"id": "module_8", "label": "Module 8", "group": "Modules", "def": [{"k": KEY_8}]},
	{"id": "module_9", "label": "Module 9", "group": "Modules", "def": [{"k": KEY_9}]},
	{"id": "interdict_hit", "label": "Warp interdictor: hit the timing window", "group": "Modules", "def": [{"k": KEY_E}]},
	{"id": "ship_menu", "label": "Ship menu", "group": "Windows", "def": [{"k": KEY_I}]},
	{"id": "station", "label": "Station window", "group": "Windows", "def": [{"k": KEY_L}]},
	{"id": "galaxy_map", "label": "Galaxy map", "group": "Windows", "def": [{"k": KEY_M}]},
	{"id": "map_territory", "label": "Galaxy map: territory overlay on/off", "group": "Windows", "def": [{"k": KEY_T}]},
	{"id": "help", "label": "Help", "group": "Windows", "def": [{"k": KEY_H}]},
	{"id": "menu_back", "label": "Close window / pause menu", "group": "Windows", "def": [{"k": KEY_ESCAPE}]},
	{"id": "quicksave", "label": "Quicksave", "group": "Game", "def": [{"k": KEY_F5}]},
	{"id": "quickload", "label": "Quickload", "group": "Game", "def": [{"k": KEY_F9}]},
	{"id": "debug_menu", "label": "Debug menu", "group": "Game", "def": [{"k": KEY_F12}]},
]
const SLOTS := 2

var binds := {}   # action id -> Array of descriptors (size SLOTS, {} = empty)


func _ready() -> void:
	reset_to_defaults(false)
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		for a in ACTIONS:
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
func set_binding(id: String, slot: int, d: Dictionary) -> String:
	var taken_from := ""
	if not d.is_empty():
		for other in binds:
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
	return not a.is_empty() and a.get("k", -1) == b.get("k", -1) and a.get("m", -1) == b.get("m", -1)


static func desc_to_event(d: Dictionary) -> InputEvent:
	if d.has("k"):
		var e := InputEventKey.new()
		e.keycode = int(d["k"])
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
		if kc in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META, KEY_NONE]:
			return {}
		return {"k": kc}
	if ev is InputEventMouseButton:
		var b: int = (ev as InputEventMouseButton).button_index
		if b in [MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_XBUTTON1, MOUSE_BUTTON_XBUTTON2]:
			return {"m": b}
	return {}


static func desc_text(d: Dictionary) -> String:
	if d.has("k"):
		return OS.get_keycode_string(int(d["k"]))
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
