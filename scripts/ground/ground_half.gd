extends SubViewportContainer
## Split screen, apart places (Luz, 25 Nov 2026): one player's whole ground view in their half of the picture.
##
## While the two of you are in the same place there is one ground view with both figures in it and the picture in two
## (GroundView._split). Once you part, each has a ground view of their own: the first player's is the one there always
## was, the second player's is a second one of the same class (main.ground2, GroundView.owner_seat = 1). Each stands in
## a half like this one: a picture of its own (a SubViewport), so the view lays itself out for the half as it would for
## a narrow window, and gets only its own player's input.
##
## Whatever of the second player's view runs from here runs in their name (main.scope_in(1)): its _process between the
## two gates, what it queued for the end of the frame (drawing, deferred calls) between the same two calls queued
## there, and the input pushed into it. What a view does at other moments (a timer, an await that comes back) it has
## to do in their name itself. No class_name: preload it.

var seat := 0
var main = null
var vp: SubViewport
var _in: Node
var _out: Node
var _was := {}                       # the second player's controller: which of the game's actions it held a frame ago
var _btn_was := {}                   # … and which of its buttons (for a game's window that reads them itself)


class Gate extends Node:
	var half
	var into := true

	func _process(_delta: float) -> void:
		half._gate(into)


func _init() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	vp = SubViewport.new()
	vp.handle_input_locally = true
	vp.gui_embed_subwindows = true
	add_child(vp)
	_in = Gate.new()
	_in.half = self
	vp.add_child(_in)
	_out = Gate.new()
	_out.half = self
	_out.into = false
	vp.add_child(_out)


func _ready() -> void:
	vp.set_meta("ground_seat", seat)
	vp.set_meta("win_seat", seat)                    # (a menu of the view is this player's: MenuNav, the controllers' menu code)
	vp.canvas_item_default_texture_filter = get_tree().root.canvas_item_default_texture_filter


## A ground view moves into this half (between the two gates).
func take(v: Node) -> void:
	if v.get_parent() == vp:
		return
	if v.get_parent() != null:
		v.get_parent().remove_child(v)
	vp.add_child(v)
	vp.move_child(_out, -1)


func holds(v: Node) -> bool:
	return v != null and is_instance_valid(v) and v.get_parent() == vp


## The view in this half (null: none).
func view():
	for c in vp.get_children():
		if c is GroundView:
			return c
	return null


## The first gate takes the half's player as the pilot for everything of the half that runs in this frame, the last
## one gives it back; the same pair is queued for what the half's nodes leave for the end of the frame.
func _gate(into: bool) -> void:
	if seat == 0 or main == null:
		return
	if into:
		main.scope_in(seat)
		main.scope_in.call_deferred(seat)
		_pad_step()
	else:
		main.scope_out()
		main.scope_out.call_deferred()


## The second player on a controller: the game's actions on foot, pressed and let go, as events into their view (what
## Pad does for the first player's controller). A menu of their view is walked by their own menu code (seat_menu.gd,
## it stands in their half); a game's window that reads the controller itself gets their buttons from here.
func _pad_step() -> void:
	if seat != 1 or not Players.split or Players.on_keys(1):
		return
	var v = view()
	var up: bool = v != null and (v.talk != null or v.talk_menu != null or v.minigame != null or v._lift_menu != null or not v.input_enabled)
	var mg = v.minigame if v != null else null
	if mg != null and is_instance_valid(mg) and mg.has_method("pad_button") and not mg.is_in_group("kbd_menu"):
		for b in Pad.BUTTONS:
			var now: bool = Players.button(1, String(b))
			if now != bool(_btn_was.get(b, false)):
				_btn_was[b] = now
				mg.pad_button(String(b), now)
	else:
		_btn_was = {}
	for a in Pad.ACTIONS:
		var id := String(a[0])
		if String(a[2]) != "ground" or id.begins_with("pad_"):
			continue
		var down: bool = not up and Players.pressed(1, id)
		if down == bool(_was.get(id, false)):
			continue
		_was[id] = down
		var ev := InputEventAction.new()
		ev.action = id
		ev.pressed = down
		ev.strength = 1.0 if down else 0.0
		vp.push_input(ev)


## The half is given up: the controller's menu code is the first player's again.
func let_go() -> void:
	_was = {}
	_btn_was = {}


## An event into this half, in its player's name. True if something in the half took it.
func push(event: InputEvent, local: bool = false) -> bool:
	if main != null:
		main.scope_in(seat)
	vp.push_input(event, local)
	if main != null:
		main.scope_out()
	return vp.is_input_handled()


func _propagate_input_event(_event: InputEvent) -> bool:
	return false                                     # (nothing by itself: only what is this half's player's, see below)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		return
	if event is InputEventKey:
		if not Players.on_keys(seat):
			return                                   # the keyboard is the other player's
	elif event is InputEventAction:
		if seat != Players.act_seat:
			return                                   # (Pad's events are theirs whose controller it listens to)
	else:
		return
	if push(event):
		get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	if not Players.on_keys(seat):
		return                                       # the mouse is the other player's: it does not reach into this half
	push(event, true)
	accept_event()
