extends SubViewportContainer
## Split screen (Luz, 25 Nov 2026): the windows of one player, over their half of the picture and nowhere else. The
## other player goes on playing in theirs.
##
## A half is a picture of its own (a SubViewport): a window put into it lays itself out for the half, has its own
## highlight (two players can each walk through a window at once) and gets only its own player's input: the keyboard
## and the mouse if they are theirs, the first player's controller through Pad, the second player's through their
## menu driver (scripts/ui/seat_menu.gd). Whatever of a window runs from here (its input, its _process) runs in the
## name of the half's player (GameState.with_seat), so a window written for "the pilot" shows and changes what is
## theirs. What a window does at other moments (a rebuild after a signal, drawing) it has to do in their name itself.
##
## Hidden while no window of the half is up: then it takes no input and draws nothing.

var seat := 0
var vp: SubViewport
var _in: Node
var _out: Node
var _keep := -1


class Gate extends Node:
	var half
	var into := true

	func _process(_delta: float) -> void:
		half._gate(into)


func _init() -> void:
	stretch = true
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	vp = SubViewport.new()
	vp.transparent_bg = true
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
	vp.set_meta("win_seat", seat)
	vp.canvas_item_default_texture_filter = get_tree().root.canvas_item_default_texture_filter


## A window moves into this half (between the two gates, so that its _process runs in the half's player's name).
func take(w: Node) -> void:
	if w.get_parent() == vp:
		return
	if w.get_parent() != null:
		w.get_parent().remove_child(w)
	vp.add_child(w)
	vp.move_child(_out, -1)


func holds(w: Node) -> bool:
	return w != null and is_instance_valid(w) and w.get_parent() == vp


## The first gate takes the half's player as the pilot for everything of the half that runs in this frame's
## _process, the last one gives it back.
func _gate(into: bool) -> void:
	if into:
		if visible and GameState.has_pilot2() and GameState.acting != seat:
			_keep = GameState.acting
			GameState.act_as(seat, true)
	elif _keep >= 0:
		GameState.act_as(_keep, true)
		_keep = -1


## An event into this half, in its player's name. True if something in the half took it.
func push(event: InputEvent, local: bool = false) -> bool:
	GameState.with_seat(seat, vp.push_input.bind(event, local))
	return vp.is_input_handled()


func _propagate_input_event(_event: InputEvent) -> bool:
	return false                                     # (nothing by itself: only what is this half's player's, see below)


func _input(event: InputEvent) -> void:
	if not visible or event is InputEventMouse:
		return
	if event is InputEventKey:
		if Players.split and not Players.on_keys(seat):
			return                                   # the keyboard is the other player's
	elif event is InputEventAction:
		if seat != 0 or Players.act_seat != 0:
			return                                   # (Pad's own events are the first player's; the second player's driver brings theirs itself)
	else:
		return
	if push(event):
		get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	if Players.split and not Players.on_keys(seat):
		return                                       # the mouse is the other player's: it does not reach into this half
	push(event, true)
	accept_event()
