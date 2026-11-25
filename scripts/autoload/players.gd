extends Node
## Split screen, stage 0 (Luz, 24 Nov 2026): two players at one machine. This is the foundation: who plays, on which
## device, and how a view asks "did player N press this?". The second pilot itself lives in the save (GameState.pilot2,
## GameState.gear2).
##
## A device is "kbm" (keyboard and mouse) or "pad:<n>" (the n-th connected controller, Godot's joypad id).
## Player 0 is the first player, player 1 the second.
##
## Without split screen nothing changes: one player on every device, as before.

signal changed

const KBM := "kbm"

var split := false                  # a split screen game is running (a matter of the session, not of the save)
var devices: Array = [KBM, ""]      # the device of each player ("" none)
var test_pads: Array = []           # tests: controllers (ids) that count as connected
var guest := false                  # this split screen was asked for at the Colosseum's counter: it ends when you walk out of the Colosseum
var act_seat := 0                   # whose device the menus and windows listen to (0; 1 while the second player has a window of their own up)
var sim := {}                       # the smoke test presses for a player: "<player>:<action>" -> true, "<player>:move" -> Vector2
var _now := [{}, {}]                # action -> held this frame, per player
var _was := [{}, {}]                # ... and the frame before
var _watch := {}                    # the actions somebody asked for (only these are polled)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = -100          # before every view: just_pressed is right for the whole frame
	Input.joy_connection_changed.connect(func(_d, _c): changed.emit())


# ---------------------------------------------------------------- who plays on what

## What a player can pick: [{"id", "name"}], the keyboard first, then every controller that is connected.
func device_list() -> Array:
	var out: Array = [{"id": KBM, "name": "Keyboard and mouse"}]
	var n := 1
	for id in Input.get_connected_joypads():
		out.append({"id": "pad:%d" % id, "name": "Controller %d  (%s)" % [n, Input.get_joy_name(id)]})
		n += 1
	for id2 in test_pads:
		out.append({"id": "pad:%d" % int(id2), "name": "Controller %d  (test)" % n})
		n += 1
	return out


func device_name(dev: String) -> String:
	for d in device_list():
		if d["id"] == dev:
			return String(d["name"])
	if dev.begins_with("pad:"):
		return "Controller (not connected)"
	return "No device"


## Is this device there to be played on?
func device_ok(dev: String) -> bool:
	if dev == KBM:
		return true
	return dev.begins_with("pad:") and (int(dev.trim_prefix("pad:")) in Input.get_connected_joypads() or int(dev.trim_prefix("pad:")) in test_pads)


## What stands in the way of a start with these two devices ("" nothing).
func devices_error(d0: String, d1: String) -> String:
	if not device_ok(d0):
		return "Player 1 needs a device."
	if not device_ok(d1):
		return "Player 2 needs a device. Connect a controller."
	if d0 == d1:
		return "Both players are on the same device."
	return ""


## The next device in the list for a player (step +1 or -1), skipping the one the other player holds.
func next_device(cur: String, other: String, step: int) -> String:
	var ids: Array = []
	for d in device_list():
		if d["id"] != other:
			ids.append(d["id"])
	if ids.is_empty():
		return ""
	var i := ids.find(cur)
	return String(ids[posmod(i + step, ids.size())]) if i >= 0 else String(ids[0])


## The devices two players start with: the first player keeps the keyboard, the second takes the first controller;
## with two controllers and nobody at the keys the menu lets them change it.
func default_devices() -> Array:
	var pads := Input.get_connected_joypads()
	return [KBM, "pad:%d" % pads[0] if not pads.is_empty() else ""]


func start_split(d0: String, d1: String) -> void:
	split = true
	devices = [d0, d1]
	_reset_state()
	changed.emit()


func stop_split() -> void:
	if not split and devices == [KBM, ""]:
		return
	split = false
	devices = [KBM, ""]
	_reset_state()
	changed.emit()


func _reset_state() -> void:
	act_seat = 0
	guest = false
	_now = [{}, {}]
	_was = [{}, {}]
	sim = {}


## The controller of a player (-1: none, the player is at the keyboard).
func pad_of(player: int) -> int:
	var dev := String(devices[player]) if player < devices.size() else ""
	return int(dev.trim_prefix("pad:")) if dev.begins_with("pad:") else -1


func on_keys(player: int) -> bool:
	return player < devices.size() and String(devices[player]) == KBM


## Does an input event belong to this player? (Without split screen everything is the first player's.)
func owns(player: int, event: InputEvent) -> bool:
	if not split:
		return player == 0
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return event.device == pad_of(player)
	return on_keys(player)


## What a player presses for an action, in words for the screen: the key at the keyboard, the button on their
## controller. (Without split screen: what the game has always written.)
func key_text(player: int, action: String, ctx: String = "ground") -> String:
	if not split:
		return Keybinds.key_text(action)
	if on_keys(player):
		for d in Keybinds.binds.get(action, []):
			if not (d as Dictionary).is_empty():
				return Keybinds.desc_text(d)
		return ""
	if action in ["walk_up", "walk_left", "walk_down", "walk_right"]:
		return {"walk_up": "L stick", "walk_left": "", "walk_down": "", "walk_right": ""}[action]
	if action == "foot_run":
		return "stick all the way"
	return Pad.binding_text(Pad.binding(ctx, action))


## … as a window of theirs writes it: at the keyboard the key; on a controller the menu's button for it if the menu
## has one (confirm, back, the pages), else the game's own.
func win_key(player: int, action: String) -> String:
	if not split or on_keys(player):
		return key_text(player, action)
	var pid := String({"menu_up": "pad_up", "menu_down": "pad_down", "menu_left": "pad_left", "menu_right": "pad_right"}.get(action, action))
	if not Pad.binding("menu", pid).is_empty():
		return key_text(player, pid, "menu")
	for ctx in ["ground", "space"]:
		if not Pad.binding(ctx, action).is_empty():
			return key_text(player, action, ctx)
	return ""


## Is this controller button (by its name: "cross", "l1" …) held by this player? For windows that read the
## controller themselves (the galaxy map).
func button(player: int, name: String) -> bool:
	if sim.has("%d:btn:%s" % [player, name]):
		return bool(sim["%d:btn:%s" % [player, name]])
	var dev := pad_of(player) if split else Pad.device
	return dev >= 0 and _btn(dev, name)


# ---------------------------------------------------------------- asking for a player's input

## Is this action of the game (an InputMap action such as "interact" or "foot_dodge") held by this player? The keys
## come from the key bindings, the buttons from the controller's bindings of the given context.
func pressed(player: int, action: String, ctx: String = "ground") -> bool:
	_watch["%s|%s" % [ctx, action]] = true
	if sim.has("%d:%s" % [player, action]):
		return bool(sim["%d:%s" % [player, action]])
	if not split:
		return player == 0 and InputMap.has_action(action) and Input.is_action_pressed(action)
	if on_keys(player):
		return _keys_down(action)
	var dev := pad_of(player)
	return dev >= 0 and _pad_down(dev, Pad.binding(ctx, action))


## Pressed in this very frame.
func just_pressed(player: int, action: String, ctx: String = "ground") -> bool:
	var k := "%s|%s" % [ctx, action]
	if not _watch.has(k):
		_watch[k] = true
		return pressed(player, action, ctx)          # the first question about it: no frame before to compare with
	return bool(_now[player].get(k, false)) and not bool(_was[player].get(k, false))


func just_released(player: int, action: String, ctx: String = "ground") -> bool:
	var k := "%s|%s" % [ctx, action]
	_watch[k] = true
	return bool(_was[player].get(k, false)) and not bool(_now[player].get(k, false))


## Where the player walks (the length says how fast: a stick pushed half way walks slowly).
func move(player: int) -> Vector2:
	if sim.has("%d:move" % player):
		return sim["%d:move" % player]
	if not split:
		return Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down") if player == 0 else Vector2.ZERO
	if on_keys(player):
		var v := Vector2(float(_keys_down("walk_right")) - float(_keys_down("walk_left")), float(_keys_down("walk_down")) - float(_keys_down("walk_up")))
		return v.normalized() if v.length() > 1.0 else v
	return _stick(pad_of(player), JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y, Pad.dead_l)


## Where the player aims with the right stick (zero: not at all; a player at the keyboard aims with the mouse).
func aim(player: int) -> Vector2:
	if sim.has("%d:aim" % player):
		return sim["%d:aim" % player]
	if split and on_keys(player):
		return Vector2.ZERO
	var dev := pad_of(player) if split else Pad.device
	return _stick(dev, JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y, Pad.dead_r)


func _stick(dev: int, ax: int, ay: int, dz: float) -> Vector2:
	if dev < 0:
		return Vector2.ZERO
	var v := Vector2(Input.get_joy_axis(dev, ax), Input.get_joy_axis(dev, ay))
	var l := v.length()
	if l <= dz:
		return Vector2.ZERO
	return v / l * minf((l - dz) / maxf(1.0 - dz, 0.01), 1.0)


## The keys and mouse buttons of an action, without what a controller adds to it.
func _keys_down(action: String) -> bool:
	if not InputMap.has_action(action):
		return false
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			var k := ev as InputEventKey
			if k.physical_keycode != KEY_NONE and Input.is_physical_key_pressed(k.physical_keycode):
				return true
			if k.keycode != KEY_NONE and Input.is_key_pressed(k.keycode):
				return true
		elif ev is InputEventMouseButton and Input.is_mouse_button_pressed((ev as InputEventMouseButton).button_index):
			return true
	return false


## A controller's binding ({"b": button} or {"hold": button, "b": button}) on one device.
func _pad_down(dev: int, b: Dictionary) -> bool:
	if b.is_empty() or not _btn(dev, String(b.get("b", ""))):
		return false
	return not b.has("hold") or _btn(dev, String(b["hold"]))


func _btn(dev: int, name: String) -> bool:
	match name:
		"":
			return false
		"l2":
			return Input.get_joy_axis(dev, JOY_AXIS_TRIGGER_LEFT) > Pad.trigger
		"r2":
			return Input.get_joy_axis(dev, JOY_AXIS_TRIGGER_RIGHT) > Pad.trigger
	return Pad.JOY.has(name) and Input.is_joy_button_pressed(dev, int(Pad.JOY[name]))


func _process(_delta: float) -> void:
	if _watch.is_empty():
		return
	for p in 2:
		_was[p] = _now[p]
		var cur := {}
		for k in _watch:
			var parts := String(k).split("|")
			cur[k] = pressed(p, parts[1], parts[0])
		_now[p] = cur
