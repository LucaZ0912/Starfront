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


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## The menu on top: the visible member of "kbd_menu" on the highest canvas layer (later in the tree wins ties).
func active_menu() -> Node:
	var best: Node = null
	var best_key := -INF
	var i := 0
	for m in get_tree().get_nodes_in_group("kbd_menu"):
		i += 1
		if not _shown(m):
			continue
		var key := float(_layer_of(m)) * 10000.0 + float(i)
		if key > best_key:
			best_key = key
			best = m
	return best


func menu_open() -> bool:
	return active_menu() != null


func _shown(m: Node) -> bool:
	if m is CanvasLayer:
		return m.visible
	if m is CanvasItem:
		return m.is_visible_in_tree()
	return false


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
	if not (event is InputEventKey) or not event.pressed:
		return
	var focus := get_viewport().gui_get_focus_owner()
	if focus is LineEdit or focus is TextEdit:
		return                                  # typing: W / A / S / D are letters here
	var menu := active_menu()
	if menu == null or (menu.has_method("menu_nav_blocked") and menu.menu_nav_blocked()):
		return
	for tab in [["menu_prev_tab", -1], ["menu_next_tab", 1]]:
		if event.is_action(tab[0]) and menu.has_method("menu_tab"):
			menu.menu_tab(int(tab[1]))
			Audio.play("ui_click", "menu tab", -4.0, 0.02)
			get_viewport().set_input_as_handled()
			return
	for act in DIRS:
		if InputMap.has_action(act) and event.is_action(act):
			step(menu, DIRS[act])
			get_viewport().set_input_as_handled()
			return


## Moves the highlight one step in `dir` inside `menu` (the first button if nothing is highlighted yet);
## on a slider left / right change its value instead.
func step(menu: Node, dir: Vector2) -> void:
	var cur := get_viewport().gui_get_focus_owner()
	var inside := cur != null and (menu == cur or menu.is_ancestor_of(cur)) and cur.is_visible_in_tree()
	if inside and cur is Range and dir.y == 0.0:
		cur.value += (cur.step if cur.step > 0.0 else (cur.max_value - cur.min_value) / 20.0) * dir.x
		return
	var cands := _candidates(menu)
	if cands.is_empty():
		return
	var nxt: Control = null
	if not inside:
		nxt = _first(cands)
	else:
		nxt = _neighbour(cur, cands, dir)
	if nxt == null:
		return
	nxt.grab_focus()
	moves += 1
	_scroll_to(nxt)


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
	var from: Vector2 = cur.get_global_rect().get_center()
	var best: Control = null
	var best_score := INF
	for c in cands:
		if c == cur:
			continue
		var to: Vector2 = c.get_global_rect().get_center() - from
		var along := to.dot(dir)
		if along <= 4.0:
			continue
		var side := absf(to.dot(dir.orthogonal()))
		var score := along + side * 2.5
		if score < best_score:
			best_score = score
			best = c
	return best


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
