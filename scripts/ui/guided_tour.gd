extends CanvasLayer
## Package 58 (Luz, 18 Nov 2026): the guided tour of a window. One step at a time the part explained is framed in
## gold (pulsing), everything else dimmed, with a tag "2 / 5 · YOUR SHIP" over it; a radio call says what it is and
## stays in front of the window. A step to read waits for a confirm (a click, E, Space, Enter or ✕ on the pad); a
## step with a task ("open the Outfitter") lets clicks through to the framed part only and goes on by itself once
## the task is done. While the tour runs the menus' keys are locked (Q / E, W / A / S / D, Escape …).
##
## A step: {"key": the part (`resolve(key)` gives its Control), "title": tag text, "who": the speaker, "text": the
## call, "task": Callable → true when done (optional), "hint": what the task asks (optional)}.

signal step_changed(i: int)
signal finished

const GOLD := Color(1.0, 0.82, 0.29)

var steps: Array = []
var resolve: Callable
var i := -1
var story_ui: Node = null
var _rect := Rect2()
var _t := 0.0
var _canvas: Control
var _wait := 0.0                       # a short pause before a confirm counts (no double steps)


func _init() -> void:
	layer = 28                                     # over the station window (20), under the radio (30) and dialogues
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("kbd_menu")
	_canvas = _Canvas.new()
	_canvas.tour = self
	add_child(_canvas)


## The menus' keys stay with the tour (MenuNav asks the menu on top).
func menu_nav_blocked() -> bool:
	return true


func start(p_steps: Array, p_resolve: Callable, p_story_ui: Node) -> void:
	steps = p_steps
	resolve = p_resolve
	story_ui = p_story_ui
	i = -1
	next()


func running() -> bool:
	return i >= 0 and i < steps.size()


func step() -> Dictionary:
	return steps[i] if running() else {}


func is_task() -> bool:
	return step().has("task")


func next() -> void:
	i += 1
	_wait = 0.35
	if not running():
		_set_avoid(Rect2())
		finished.emit()
		queue_free()
		return
	var s: Dictionary = steps[i]
	var me := i
	# a task: the window's own menu (keys, controller) works again, kept to the framed part; a step to read: the tour
	# is the menu on top and takes every key
	if s.has("task"):
		if is_in_group("kbd_menu"):
			remove_from_group("kbd_menu")
	elif not is_in_group("kbd_menu"):
		add_to_group("kbd_menu")
	var hint := String(s.get("hint", "")) if is_task() else "Continue ▸  click  •  E  •  ✕"
	GameState.story.show.emit("radio", {"who": String(s.get("who", "dan")), "text": String(s["text"]), "mission": String(s.get("mission", "")),
		"until": func(): return not is_instance_valid(self) or i != me, "hint": hint, "now": true})
	step_changed.emit(i)


func _process(delta: float) -> void:
	if not running():
		return
	_t += delta
	_wait -= delta
	var c: Control = resolve.call(String(step().get("key", ""))) if resolve.is_valid() else null
	_rect = c.get_global_rect().grow(4.0) if c != null and is_instance_valid(c) and c.is_visible_in_tree() else Rect2()
	var k := clampf(get_viewport().get_visible_rect().size.y / 900.0, 1.0, 2.4)
	_set_avoid(_rect.grow_individual(0.0, 28.0 * k, 0.0, 0.0) if _rect.size != Vector2.ZERO else _rect)      # the tag over the frame too
	_canvas.queue_redraw()
	if is_task():
		_keep_focus_inside(c)
	if is_task() and _wait <= 0.0 and bool((step()["task"] as Callable).call()):
		next()


## In a task the highlight (keys, controller) stays inside the framed part: it is moved back if it strays.
func _keep_focus_inside(c: Control) -> void:
	if c == null or _rect.size == Vector2.ZERO:
		return
	var fo := get_viewport().gui_get_focus_owner()
	if fo != null and _rect.has_point(fo.get_global_rect().get_center()):
		return
	if fo == null and not Pad.using_pad:
		return                                            # nothing highlighted, a mouse player: leave it
	var first: Control = null
	if c is BaseButton and c.focus_mode != Control.FOCUS_NONE:
		first = c
	else:
		for b in c.find_children("*", "BaseButton", true, false):
			if (b as Control).is_visible_in_tree() and (b as Control).focus_mode != Control.FOCUS_NONE and not (b as BaseButton).disabled:
				first = b
				break
	if first != null:
		first.grab_focus()


func _set_avoid(r: Rect2) -> void:
	if story_ui != null and is_instance_valid(story_ui):
		story_ui.radio_avoid = r


func _is_confirm(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if event is InputEventJoypadButton:
		return event.pressed and event.button_index == JOY_BUTTON_A
	if event is InputEventKey and event.pressed and not event.echo:
		return event.keycode in [KEY_E, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER] or event.is_action("pad_confirm")
	return false


func _input(event: InputEvent) -> void:
	if not running():
		return
	if is_task():
		# only the framed part takes clicks (and the wheel, to scroll it)
		if event is InputEventMouseButton or event is InputEventMouseMotion:
			if _rect.size != Vector2.ZERO and _rect.has_point(event.position):
				return
			if event is InputEventMouseMotion:
				return                                        # hovering is harmless
			get_viewport().set_input_as_handled()
			return
		# the menu's own keys and the controller work (the highlight is kept inside the frame); leaving is locked
		for a in ["menu_back", "ui_cancel"]:
			if event.is_action(a):
				get_viewport().set_input_as_handled()
				return
		if event is InputEventKey and (event as InputEventKey).keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			return
		if event is InputEventJoypadButton or event is InputEventJoypadMotion or event is InputEventAction:
			return
		for a3 in step().get("allow", []):
			if InputMap.has_action(String(a3)) and event.is_action(String(a3)):
				return                                        # what the task asks for (launching the drone …)
		for a2 in ["menu_up", "menu_down", "menu_left", "menu_right", "ui_up", "ui_down", "ui_left", "ui_right", "ui_accept", "menu_prev_tab", "menu_next_tab"]:
			if InputMap.has_action(a2) and event.is_action(a2):
				return
		get_viewport().set_input_as_handled()
		return
	if _is_confirm(event):
		tour_confirm()
	if not event is InputEventMouseMotion:
		get_viewport().set_input_as_handled()


## A confirm (also ✕ on the pad, through Pad): first all of the call, then the next step.
func tour_confirm() -> void:
	if not running() or is_task() or _wait > 0.0:
		return
	if story_ui != null and is_instance_valid(story_ui) and story_ui.radio_typing():
		story_ui.radio_finish_typing()
		_wait = 0.15
		return
	Audio.play("ui_click", "tour", -4.0, 0.02)
	next()


## Draws the dimming round the frame, the frame and its tag.
class _Canvas extends Control:
	var tour

	func _init() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if tour == null or not tour.running():
			return
		var vs := get_viewport_rect().size
		var r: Rect2 = tour._rect
		var dim := Color(0, 0, 0, 0.58)
		if r.size == Vector2.ZERO:
			draw_rect(Rect2(Vector2.ZERO, vs), dim)
			return
		draw_rect(Rect2(0, 0, vs.x, r.position.y), dim)
		draw_rect(Rect2(0, r.end.y, vs.x, vs.y - r.end.y), dim)
		draw_rect(Rect2(0, r.position.y, r.position.x, r.size.y), dim)
		draw_rect(Rect2(r.end.x, r.position.y, vs.x - r.end.x, r.size.y), dim)
		var pulse := 0.6 + 0.4 * sin(tour._t * 5.0)
		for k in 4:
			draw_rect(r.grow(2.0 + k * 3.0), Color(GOLD, 0.16 * pulse * (4 - k) / 4.0), false, 3.0)
		draw_rect(r, Color(GOLD, 0.75 + 0.25 * pulse), false, 3.0)
		var tag := "%d / %d  •  %s" % [tour.i + 1, tour.steps.size(), String(tour.step().get("title", "")).to_upper()]
		var font := ThemeDB.fallback_font
		var k := clampf(vs.y / 900.0, 1.0, 2.4)                 # the tag grows with big screens, as the radio call
		var fs := int(round(13.0 * k))
		var th := 22.0 * k
		var tw := font.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 16.0 * k
		var ty := r.position.y - th - 2.0 if r.position.y > th + 8.0 else r.end.y + 2.0
		draw_rect(Rect2(r.position.x, ty, tw, th), GOLD)
		draw_string(font, Vector2(r.position.x + 8.0 * k, ty + th * 0.73), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.1, 0.06, 0.0))
