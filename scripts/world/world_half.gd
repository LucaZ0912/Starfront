extends SubViewportContainer
## Split screen, stage 5 (Luz, 25 Nov 2026: each jumps for themselves): the second player's half of the picture while
## they are in another system than the first player.
##
## Its SubViewport is a world of its own: the second player's own space view (a SystemView with one look, built for
## their system) with their HUD, their controller's wheel and its hints. Everything in it runs in the second player's
## name (GameState.act_as(1): their pilot, purse, ships, contracts and their system as "the current system"; main
## hears of it and makes this view "the view", their HUD "the HUD" and their controller the controller code's): its
## nodes' _process and _physics_process between the two gates, what they queued for the end of the frame between the
## same two calls queued there, and what is pushed into it.
##
## The mouse is the keyboard player's and reaches into their own half only. No class_name: preload it.

var seat := 1
var vp: SubViewport
var _in: Node
var _out: Node


class Gate extends Node:
	var half
	var into := true

	func _process(_delta: float) -> void:
		half._gate(into)

	func _physics_process(_delta: float) -> void:
		half._gate(into, false)


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


## From here on (into) it is this half's player's turn, and the first player's again after it. `later`: also for what
## is queued for the end of the frame between the two gates.
func _gate(into: bool, later: bool = true) -> void:
	if not GameState.has_pilot2():
		return
	var s := seat if into else 0
	GameState.act_as(s, true)
	if later:
		GameState.act_as.call_deferred(s, true)


## An event into this half, in its player's name. True if something in the half took it.
func push(event: InputEvent, local: bool = false) -> bool:
	GameState.with_seat(seat, vp.push_input.bind(event, local))
	return vp.is_input_handled()


func _propagate_input_event(_event: InputEvent) -> bool:
	return false                                     # (nothing by itself: only the mouse of this half's player, see below)


func _gui_input(event: InputEvent) -> void:
	accept_event()
	if not (event is InputEventMouse):
		return
	if Players.split and GameState.has_pilot2() and not Players.on_keys(seat):
		return                                       # the mouse is the other player's: it does not reach into this half
	push(event, true)                                # (the view in it is alone in its world: what its HUD does not take, it takes itself)
