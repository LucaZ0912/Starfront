extends Node
## Keyboard control of the menus (0.5.28.2, wish of Luz): W / A / S / D (and the arrow keys) move the highlight
## between the buttons of the menu on top, Enter / Space press it, Q / E switch tabs, Escape goes back as
## before. While a menu is open the keys belong to it – the ship does not fly (see SystemView.key_direction).
##
## A menu takes part by joining the group "kbd_menu"; with a method menu_tab(step) it also switches tabs on
## Q / E; with menu_nav_blocked() -> true it keeps the keys to itself (e.g. while a key is being rebound).

const DIRS := {"menu_up": Vector2.UP, "menu_down": Vector2.DOWN, "menu_left": Vector2.LEFT, "menu_right": Vector2.RIGHT,
	"ui_up": Vector2.UP, "ui_down": Vector2.DOWN, "ui_left": Vector2.LEFT, "ui_right": Vector2.RIGHT}

var moves := 0                     # highlight moves (smoke test)
var _last_menu: Node = null        # package 80: where the highlight was – it comes back there after the menu is rebuilt
var _last_pos := Vector2.INF
var _lasts := {}                   # … for each menu by itself (two players, two windows): instance id -> where
## Split screen: the engine has one keyboard highlight for the whole game window, whatever picture a control stands
## in. Two players walking through a window each need one of their own, so a window in a half of the picture has its
## highlight kept here: the control it is on (`_soft`) with a frame drawn round it, pressed by press().
var _soft := {}                    # menu instance id -> the control highlighted in it
var _frames := {}                  # menu instance id -> the frame round it


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## The menu on top for a player: the visible member of "kbd_menu" on the highest canvas layer (later in the tree wins
## ties). Split screen: a window in a half of the picture is that half's player's alone; the windows over the whole
## picture are theirs whose windows these are (Players.act_seat). Without a seat: that player's.
func active_menu(seat: int = -1) -> Node:
	var s := seat if seat >= 0 else (Players.act_seat if Players.split else 0)
	var best: Node = null
	var best_key := -INF
	var i := 0
	for m in get_tree().get_nodes_in_group("kbd_menu"):
		i += 1
		if not _shown(m):
			continue
		var own := seat_of(m)
		if own >= 0 and own != s:
			continue                                # in the other player's half
		if own < 0 and Players.split and Players.act_seat != s:
			continue                                # over the whole picture, and not theirs right now
		var key := float(_layer_of(m)) * 10000.0 + float(i)
		if key > best_key:
			best_key = key
			best = m
	return best


## Has this menu a highlight of its own (it stands in a half of the picture)?
func is_soft(menu: Node) -> bool:
	return seat_of(menu) >= 0


## The control the highlight is on in a menu (null: none yet).
func current(menu: Node) -> Control:
	if menu == null or not is_instance_valid(menu) or not menu.is_inside_tree():
		return null
	var c = _soft.get(menu.get_instance_id()) if is_soft(menu) else menu.get_viewport().gui_get_focus_owner()
	if c == null or not is_instance_valid(c) or not (c as Control).is_visible_in_tree() or not (menu == c or menu.is_ancestor_of(c)):
		return null
	return c


## Presses what is highlighted in a menu that keeps its own highlight. True if something was pressed.
func press(menu: Node) -> bool:
	var c := current(menu)
	if c == null:
		return false
	keep(menu, c)
	if c is LineEdit or c is TextEdit:
		c.grab_focus()                              # (typing needs the engine's own highlight)
		return true
	if c is OptionButton:
		(c as OptionButton).show_popup()
		return true
	if c is BaseButton:
		var b := c as BaseButton
		if b.disabled:
			return false
		if b.toggle_mode:
			b.button_pressed = not b.button_pressed
		b.pressed.emit()
		return true
	return false


## The player whose half of the picture a menu stands in (-1: it is over the whole picture).
func seat_of(m: Node) -> int:
	var v: Viewport = m.get_viewport() if m != null and m.is_inside_tree() else null
	return int(v.get_meta("win_seat", -1)) if v != null else -1


## Where the highlight is now, kept for when the menu is rebuilt.
func keep(menu: Node, focus: Control) -> void:
	_last_menu = menu
	_last_pos = _vrect(focus).get_center() if focus != null else Vector2.INF
	if menu != null:
		_lasts[menu.get_instance_id()] = _last_pos


func _kept(menu: Node) -> Vector2:
	if menu == null:
		return Vector2.INF
	if _last_menu == menu and _last_pos != Vector2.INF:
		return _last_pos
	return _lasts.get(menu.get_instance_id(), Vector2.INF)


func menu_open() -> bool:
	return active_menu() != null


func _shown(m: Node) -> bool:
	if m is CanvasLayer:
		return m.visible
	if m is CanvasItem:
		return m.is_visible_in_tree()
	return m.is_inside_tree()                   # package 80: a plain node (the main menu) – there while it is in the tree


func _layer_of(m: Node) -> int:
	if m is CanvasLayer:
		return m.layer
	var n := m.get_parent()
	while n != null:
		if n is CanvasLayer:
			return n.layer
		n = n.get_parent()
	return 0


func _input(event: InputEvent) -> void:
	if try_key(event):
		get_viewport().set_input_as_handled()


## A key (or a controller's tab button) for the menu on top of the player it belongs to. True if it was one of the
## menu's: a step of the highlight, a tab.
func try_key(event: InputEvent) -> bool:
	if not event.is_pressed() or event.is_echo() and not (event is InputEventKey):
		return false
	var seat := 0
	if event is InputEventKey:
		if Players.split and not Players.on_keys(0):
			if not Players.on_keys(1):
				return false
			seat = 1                                # (split screen: the keyboard is the second player's)
	elif event is InputEventAction:
		if not String((event as InputEventAction).action) in ["menu_prev_tab", "menu_next_tab"]:
			return false
		seat = Players.act_seat if Players.split else 0      # (a controller's tab buttons, through Pad)
	else:
		return false
	var menu := active_menu(seat)
	if menu == null or (menu.has_method("menu_nav_blocked") and menu.menu_nav_blocked()):
		return false
	var focus := menu.get_viewport().gui_get_focus_owner()
	if focus is LineEdit or focus is TextEdit:
		return false                            # typing: W / A / S / D are letters here
	var who := seat_of(menu) if seat_of(menu) >= 0 else GameState.acting      # (a window in a half works in its player's name)
	if event is InputEventKey and is_soft(menu) and not event.is_echo() and event.is_action("ui_accept") and current(menu) != null:
		GameState.with_seat(who, press.bind(menu))      # Enter / Space on the window's own highlight
		return true
	for tab in [["menu_prev_tab", -1], ["menu_next_tab", 1]]:
		if event.is_action(tab[0]) and menu.has_method("menu_tab"):
			GameState.with_seat(who, menu.menu_tab.bind(int(tab[1])))
			Audio.play("ui_click", "menu tab", -4.0, 0.02)
			return true
	if event is InputEventKey:
		for act in DIRS:
			if InputMap.has_action(act) and event.is_action(act):
				GameState.with_seat(who, step.bind(menu, DIRS[act]))
				return true
	return false


## Moves the highlight one step in `dir` inside `menu` (the first button if nothing is highlighted yet);
## on a slider left / right change its value instead.
func step(menu: Node, dir: Vector2) -> void:
	var cur := current(menu)
	var inside := cur != null
	if inside and cur is Range and dir.y == 0.0:
		cur.value += (cur.step if cur.step > 0.0 else (cur.max_value - cur.min_value) / 20.0) * dir.x
		return
	var cands := _candidates(menu)
	if cands.is_empty():
		return
	var nxt: Control = null
	if not inside:
		nxt = _nearest(cands, _kept(menu)) if _kept(menu) != Vector2.INF else _first(cands)
	else:
		nxt = _neighbour(cur, cands, dir)
	if nxt == null:
		return
	_take(menu, nxt)


func _take(menu: Node, nxt: Control) -> void:
	_light(menu, nxt)
	moves += 1
	_scroll_to(nxt)
	keep(menu, nxt)


## Package 80: after a press that rebuilds the menu (a gear tile, a list) the highlight comes back to the control at
## the same place – not to the top.
func restore(menu: Node) -> void:
	if menu == null or not is_instance_valid(menu) or not menu.is_inside_tree() or _kept(menu) == Vector2.INF:
		return
	if current(menu) != null:
		return
	var nxt := _nearest(_candidates(menu), _kept(menu))
	if nxt != null:
		_light(menu, nxt)
		_scroll_to(nxt)


## The highlight onto a control: the engine's own, or (a window in a half of the picture) the window's own with its
## frame; what listens for the highlight coming (a tile that shows its details) hears it either way.
func _light(menu: Node, nxt: Control) -> void:
	if not is_soft(menu):
		nxt.grab_focus()
		return
	var id := menu.get_instance_id()
	var old = _frames.get(id)
	if old != null and is_instance_valid(old):
		old.queue_free()
	_soft[id] = nxt
	var fr := Panel.new()
	fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = Color(1.0, 0.95, 0.4)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(3)
	sb.set_expand_margin_all(2)
	fr.add_theme_stylebox_override("panel", sb)
	nxt.add_child(fr, false, Node.INTERNAL_MODE_BACK)
	_frames[id] = fr
	nxt.focus_entered.emit()


func _nearest(cands: Array, at: Vector2) -> Control:
	var best: Control = null
	var bd := INF
	for c in cands:
		var d := _vrect(c).get_center().distance_to(at)
		if d < bd:
			bd = d
			best = c
	return best


## A control's place as if no list were scrolled – stable while the highlight scrolls lists along.
func _vrect(c: Control) -> Rect2:
	var r := c.get_global_rect()
	var n := c.get_parent()
	while n != null:
		if n is ScrollContainer:
			r.position += Vector2((n as ScrollContainer).scroll_horizontal, (n as ScrollContainer).scroll_vertical)
		n = n.get_parent()
	return r


## Every control of the menu that can take the highlight: buttons, sliders, fields – visible and enabled.
func _candidates(menu: Node) -> Array:
	var out: Array = []
	var stack: Array = [menu]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if n is Control and n != menu and n.is_visible_in_tree() and (n is BaseButton or n is Range or n is LineEdit or n is OptionButton):
			if n is BaseButton and n.disabled:
				continue
			if n is ProgressBar:
				continue
			if n.focus_mode == Control.FOCUS_NONE:
				n.focus_mode = Control.FOCUS_ALL
				_focus_style(n)
			out.append(n)
	return out


func _first(cands: Array) -> Control:
	var best: Control = null
	for c in cands:
		var r: Rect2 = c.get_global_rect()
		if best == null or r.position.y < best.get_global_rect().position.y - 4.0 or (absf(r.position.y - best.get_global_rect().position.y) <= 4.0 and r.position.x < best.get_global_rect().position.x):
			best = c
	return best


## The nearest control in the direction – straight ahead counts more than off to the side.
func _neighbour(cur: Control, cands: Array, dir: Vector2) -> Control:
	var from: Vector2 = _vrect(cur).get_center()
	var cr := _vrect(cur)
	var best: Control = null
	var best_score := INF
	var lane: Control = null                     # package 80: in the same row (or column) first – the nearest that way
	var lane_d := INF
	var cone: Control = null                     # package 80: within 45° of the direction first (the row, the column) –
	var cone_score := INF                         # else e.g. "right" from the bottom row climbed to the row above
	for c in cands:
		if c == cur:
			continue
		var to: Vector2 = _vrect(c).get_center() - from
		var along := to.dot(dir)
		if along <= 4.0:
			continue
		var side := absf(to.dot(dir.orthogonal()))
		var score := along + side * 2.5
		if score < best_score:
			best_score = score
			best = c
		if side <= along and along + side * 3.0 < cone_score:
			cone_score = along + side * 3.0
			cone = c
		var r := _vrect(c)
		var overlap := (r.position.y < cr.end.y - 2.0 and r.end.y > cr.position.y + 2.0) if dir.y == 0.0 else (r.position.x < cr.end.x - 2.0 and r.end.x > cr.position.x + 2.0)
		if overlap and along < lane_d:
			lane_d = along
			lane = c
	if lane != null:
		return lane
	return cone if cone != null else best


func _scroll_to(c: Control) -> void:
	var n := c.get_parent()
	while n != null:
		if n is ScrollContainer:
			n.ensure_control_visible(c)
		n = n.get_parent()


## A neon frame round the highlighted control.
func _focus_style(c: Control) -> void:
	if c.has_theme_stylebox_override("focus"):
		return
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = Color(1.0, 0.95, 0.4)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(3)
	sb.expand_margin_left = 2
	sb.expand_margin_right = 2
	sb.expand_margin_top = 2
	sb.expand_margin_bottom = 2
	c.add_theme_stylebox_override("focus", sb)
