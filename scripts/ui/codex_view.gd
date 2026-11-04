extends HBoxContainer
## Codex browser (phase 0.5 package 18): categories and entries on the left, the selected entry on
## the right with its picture and "see also" links. Used by the ship menu (this game's unlocks) and
## the main menu (everything discovered in any game).

const CodexData = preload("res://data/codex.gd")
const CodexScript = preload("res://scripts/core/codex.gd")

var in_game := true             # true: GameState.codex, false: all games (main menu)
var all := {}
var known := {}
var selected := ""
var _list: VBoxContainer
var _page: VBoxContainer


func setup(p_in_game: bool) -> void:
	in_game = p_in_game
	add_theme_constant_override("separation", 14)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lsc := ScrollContainer.new()
	lsc.custom_minimum_size = Vector2(330, 0)
	lsc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(lsc)
	_list = UI.vbox(2)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lsc.add_child(_list)
	var rsc := ScrollContainer.new()
	rsc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rsc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(rsc)
	_page = UI.vbox(10)
	_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rsc.add_child(_page)
	refresh()


func refresh() -> void:
	if in_game:
		all = GameState.codex.all
		known = GameState.codex.unlocked
	else:
		all = CodexData.entries()
		known = CodexScript.load_global()
	if selected == "" or not known.has(selected):
		selected = _first_new()
	_build_list()
	_build_page()


func _first_new() -> String:
	if in_game:
		for cat in CodexData.CATEGORIES:
			for id in _ids(cat[0]):
				if GameState.codex.unread.has(id):
					return id
	for cat in CodexData.CATEGORIES:
		for id in _ids(cat[0]):
			if known.has(id):
				return id
	return ""


func _ids(cat: String) -> Array:
	var out: Array = []
	for id in all:
		if all[id]["cat"] == cat:
			out.append(id)
	out.sort_custom(func(a, b): return String(all[a]["title"]) < String(all[b]["title"]))
	return out


func _build_list() -> void:
	UI.clear(_list)
	var total := 0
	for id0 in all:
		total += 1 if known.has(id0) else 0
	_list.add_child(UI.label("%d / %d entries discovered" % [total, all.size()], 12, UI.TEXT_DIM))
	for cat in CodexData.CATEGORIES:
		var ids := _ids(cat[0])
		var n := 0
		for id in ids:
			n += 1 if known.has(id) else 0
		_list.add_child(UI.label("%s  (%d / %d)" % [String(cat[1]).to_upper(), n, ids.size()], 14, UI.NEON_CYAN))
		for id in ids:
			var eid: String = id
			if known.has(id):
				var new: bool = in_game and GameState.codex.unread.has(id)
				var b := UI.button(("● " if new else "   ") + String(all[id]["title"]), func(): _select(eid))
				b.alignment = HORIZONTAL_ALIGNMENT_LEFT
				b.toggle_mode = true
				b.button_pressed = id == selected
				if new:
					b.add_theme_color_override("font_color", UI.GOLD)
				_list.add_child(b)
			else:
				var l := UI.label("   ???  – not discovered yet", 13, Color(0.45, 0.48, 0.55))
				_list.add_child(l)


func _select(id: String) -> void:
	selected = id
	if in_game:
		GameState.codex.mark_read(id)
	_build_list()
	_build_page()


func _build_page() -> void:
	UI.clear(_page)
	if selected == "" or not all.has(selected):
		_page.add_child(UI.label("Nothing discovered yet.", 14, UI.TEXT_DIM))
		return
	if in_game:
		GameState.codex.mark_read(selected)
	var e: Dictionary = all[selected]
	var head := UI.hbox(14)
	_page.add_child(head)
	var tex: Texture2D = null
	var img: Dictionary = e.get("image", {})
	if img.has("crest"):
		tex = CrestArt.texture(String(img["crest"]))
	elif img.has("ship"):
		tex = PixelArt.ship_texture(String(img["ship"]), "neutral")
	elif img.has("icon"):
		tex = PixelArt.icon_texture(String(img["icon"]))
	if tex != null:
		var ic := UI.icon(tex, 72)
		ic.custom_minimum_size = Vector2(84, 84)
		head.add_child(ic)
	var tv := UI.vbox(2)
	head.add_child(tv)
	var cat_name := ""
	for c in CodexData.CATEGORIES:
		if c[0] == e["cat"]:
			cat_name = c[1]
	tv.add_child(UI.label(cat_name.to_upper(), 12, UI.NEON_PINK))
	tv.add_child(UI.label(String(e["title"]), 24, UI.NEON_CYAN))
	for para in String(e["text"]).split("\n\n"):
		_page.add_child(UI.wrap_label(para, 15, Color(0.88, 0.91, 0.98), 860))
	var see: Array = e.get("see", [])
	if not see.is_empty():
		_page.add_child(UI.label("SEE ALSO", 13, UI.NEON_CYAN))
		var row := HFlowContainer.new()
		row.add_theme_constant_override("h_separation", 6)
		row.add_theme_constant_override("v_separation", 6)
		_page.add_child(row)
		for sid in see:
			var s2: String = sid
			if not all.has(s2):
				continue
			var b := UI.button(String(all[s2]["title"]) if known.has(s2) else "???", func(): _select(s2))
			b.disabled = not known.has(s2)
			row.add_child(b)
