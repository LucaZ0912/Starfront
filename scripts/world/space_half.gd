extends SubViewportContainer
## Split screen, stage 4 (Luz, 25 Nov 2026): one player's half of the picture in space.
##
## Its SubViewport shows the one world (SystemView: `world_2d` shared, the look's own layers by cull mask) and holds
## what is drawn over it for this player alone: their sky and background, their HUD (the same HUD class for each
## player), their controller's wheel and its button hints. So everything in it lays itself out for the half as it
## would for a narrow window.
##
## Whatever of the second player's half runs from here runs with their look as the view's (SystemView.eye_as(1), and
## with it "the pilot", their HUD as main's and their controller as the controller code's): its nodes' _process
## between the two gates, what they queued for the end of the frame between the same two calls queued there, and the
## mouse pushed into it. The first player's look is the one there is outside of that, so their half needs no gates.
##
## The mouse is the keyboard player's and reaches into their own half only. What nothing of the half's HUD takes goes
## on to the space view (a click into space, the wheel, a drag). No class_name: preload it.

var seat := 0
var view = null                      # the SystemView
var vp: SubViewport
var _in: Node
var _out: Node


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
	vp.disable_3d = true
	add_child(vp)
	_in = Gate.new()
	_in.half = self
	vp.add_child(_in)
	_out = Gate.new()
	_out.half = self
	_out.into = false
	vp.add_child(_out)


func _ready() -> void:
	vp.set_meta("space_seat", seat)


## Something of this player's own moves into the half (between the two gates).
func take(n: Node) -> void:
	if n.get_parent() == vp:
		return
	if n.get_parent() != null:
		n.get_parent().remove_child(n)
	vp.add_child(n)
	vp.move_child(_out, -1)


func holds(n: Node) -> bool:
	return n != null and is_instance_valid(n) and n.get_parent() == vp


func _gate(into: bool) -> void:
	if seat == 0 or view == null or not view.eyes_two:
		return
	if into:
		view.eye_as(1)
		view.eye_as.call_deferred(1)
	else:
		view.eye_as(0)
		view.eye_as.call_deferred(0)


## An event into this half, with its player's look as the view's. True if something in the half took it.
func push(event: InputEvent, local: bool = false) -> bool:
	if view != null:
		view.in_eye(seat, vp.push_input.bind(event, local))
	else:
		vp.push_input(event, local)
	return vp.is_input_handled()


func _propagate_input_event(_event: InputEvent) -> bool:
	return false                                     # (nothing by itself: only the mouse of this half's player, see below)


func _gui_input(event: InputEvent) -> void:
	accept_event()
	if not (event is InputEventMouse):
		return
	if Players.split and GameState.has_pilot2() and not Players.on_keys(seat):
		return                                       # the mouse is the other player's: it does not reach into this half
	if push(event, true):
		return
	if view != null:
		var ev: InputEventMouse = event.duplicate()
		ev.position += position                      # (the space view counts in the whole picture's coordinates)
		ev.global_position = ev.position
		view._unhandled_input(ev)
