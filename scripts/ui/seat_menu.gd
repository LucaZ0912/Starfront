extends Node
## Split screen (Luz, 25 Nov 2026): the second player's controller in their own windows. Pad listens to one
## controller (the first player's, or whose whole-picture window is up); this asks the second player's each frame and
## does for the windows of their half what Pad does for the first player's: Options tapped pauses for both, held it
## opens the window wheel in their half; in a window the D-pad or the stick moves the highlight, confirm presses it,
## back closes the window, the shoulder buttons switch tabs, the right stick scrolls. The buttons are the ones bound
## for menus (Settings → Controller). A second player at the keyboard needs none of this: their keys and their mouse
## reach their half by themselves (scripts/ui/win_half.gd, MenuNav).

const SEAT := 1
const WheelScript = preload("res://scripts/ui/pad_wheel.gd")

var main
var wheel: Control = null
var events: Array = []              # what was done (smoke test)
var _opt_t := -1.0
var _btn_was := {}                  # a controller button by its name -> held last frame (for windows that read the buttons themselves)
var _taken := {}                    # … the buttons such a window took in this frame
var _dir := Vector2.ZERO
var _rep := 0.0


func _process(delta: float) -> void:
	if main == null or not Players.split or not GameState.has_pilot2() or not main.halves_on() or Players.on_keys(SEAT) or Players.act_seat == SEAT:
		_drop()
		return
	var menu: Node = MenuNav.active_menu(SEAT)
	if menu == null and main.has_method("in_space") and main.in_space(SEAT):
		_drop()                                          # (in space, with no window of theirs up, their controller is read by the controller code itself: Pad.seat_step)
		_btn_was = {}
		return
	# Options: a tap pauses (in a window: closes it), held: the window wheel
	if Players.just_pressed(SEAT, "pad_options", "ground"):
		_opt_t = 0.0
	if _opt_t >= 0.0:
		_opt_t += delta
		if _opt_t > 0.35 and wheel == null and menu == null:
			_open_wheel()
		if not Players.pressed(SEAT, "pad_options", "ground"):
			var short := _opt_t <= 0.35
			_opt_t = -1.0
			if wheel != null:
				_close_wheel(true)
			elif short:
				_note("back")
				main.win_back(SEAT)
			return
	if wheel != null:
		var st: Vector2 = Players.aim(SEAT) if Players.aim(SEAT).length() > 0.5 else Players.move(SEAT)
		wheel.pick(st)
		if Players.just_pressed(SEAT, "menu_back", "menu"):
			_close_wheel(false)
			_opt_t = -1.0
		return
	if menu == null:
		_btn_was = {}
		return
	if menu.has_method("menu_nav_blocked") and menu.menu_nav_blocked():
		return
	# a window that reads the controller itself (the galaxy map: the sticks move and pick, some buttons are its own)
	_taken = {}
	if menu.has_method("pad_button"):
		for b in Pad.BUTTONS:
			var now: bool = Players.button(SEAT, String(b))
			if now != bool(_btn_was.get(b, false)):
				_btn_was[b] = now
				if bool(GameState.with_seat(SEAT, menu.pad_button.bind(String(b), now))) and now:
					_taken[b] = true
					_note("own:" + String(b))
	var own_stick: bool = menu.has_method("pad_stick")
	if own_stick:
		GameState.with_seat(SEAT, menu.pad_stick.bind(Players.move(SEAT), Players.aim(SEAT), delta))
	var dir := Vector2.ZERO
	for d in [["pad_up", Vector2.UP], ["pad_down", Vector2.DOWN], ["pad_left", Vector2.LEFT], ["pad_right", Vector2.RIGHT]]:
		if _jp(String(d[0])):
			dir = d[1]
	if dir == Vector2.ZERO and not own_stick:
		dir = _stick_step(delta)
	if dir != Vector2.ZERO:
		_note("step")
		GameState.with_seat(SEAT, MenuNav.step.bind(menu, dir))
	if _jp("pad_confirm"):
		_confirm(menu)
	if _jp("menu_back"):
		_note("back")
		main.win_back(SEAT)
		return
	for tb in [["menu_prev_tab", -1], ["menu_next_tab", 1]]:
		if _jp(String(tb[0])) and menu.has_method("menu_tab"):
			_note("tab")
			GameState.with_seat(SEAT, menu.menu_tab.bind(int(tb[1])))
			Audio.play("ui_click", "menu tab", -4.0, 0.02)
	var r: Vector2 = Players.aim(SEAT)
	if absf(r.y) >= 0.1 and not own_stick:
		_scroll(menu, r.y * 900.0 * delta)


## A menu's button pressed in this very frame, unless the window took that button for itself.
func _jp(id: String) -> bool:
	return Players.just_pressed(SEAT, id, "menu") and not _taken.has(String(Pad.binding("menu", id).get("b", "")))


## The left stick as a direction now and then: at once when it is pushed, then again and again while it is held.
func _stick_step(delta: float) -> Vector2:
	var v: Vector2 = Players.move(SEAT)
	var dir := Vector2.ZERO
	if v.length() > 0.55:
		dir = Vector2(signf(v.x), 0) if absf(v.x) > absf(v.y) else Vector2(0, signf(v.y))
	if dir == Vector2.ZERO:
		_dir = Vector2.ZERO
		return dir
	if dir != _dir:
		_dir = dir
		_rep = 0.35
		return dir
	_rep -= delta
	if _rep > 0.0:
		return Vector2.ZERO
	_rep = 0.12
	return dir


## Confirm: what is highlighted in their window is pressed (nothing highlighted yet: the first control is).
func _confirm(menu: Node) -> void:
	if MenuNav.current(menu) == null:
		GameState.with_seat(SEAT, MenuNav.step.bind(menu, Vector2.DOWN))
		return
	_note("confirm")
	GameState.with_seat(SEAT, MenuNav.press.bind(menu))
	get_tree().create_timer(0.06, true).timeout.connect(func(): GameState.with_seat(SEAT, MenuNav.restore.bind(menu)))      # back to it if the window was rebuilt


func _scroll(menu: Node, by: float) -> void:
	var n: Node = MenuNav.current(menu)
	while n != null and not (n is ScrollContainer):
		n = n.get_parent()
	if n == null:
		for c in menu.find_children("*", "ScrollContainer", true, false):
			if (c as Control).is_visible_in_tree():
				n = c
				break
	if n != null:
		(n as ScrollContainer).scroll_vertical += int(by)


func _open_wheel() -> void:
	wheel = WheelScript.new()
	wheel.items = Pad.WINDOW_ITEMS                    # (the very wheel the first player's controller has)
	wheel.title = "%s held" % Players.key_text(SEAT, "pad_options")
	main.win_show(SEAT, wheel)
	_note("wheel")


func _close_wheel(do_it: bool) -> void:
	if wheel == null:
		return
	var choice: String = wheel.chosen() if do_it else ""
	wheel.queue_free()
	wheel = null
	main.win_hide(SEAT)
	if choice != "":
		_note("wheel:" + choice)
		main.win_action(SEAT, choice)


func _drop() -> void:
	_opt_t = -1.0
	if wheel != null:
		_close_wheel(false)


func _note(what: String) -> void:
	events.append(what)
	if events.size() > 40:
		events.pop_front()
