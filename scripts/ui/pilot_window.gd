extends CanvasLayer
## Package 29: the Pilot window (U). Three tabs:
##   Skills     – the twelve skills: level (10 pips), experience to the next level, the effect now, what makes it
##                grow; a ready advance is confirmed here ("Advance")
##   Skill tree – the six branches; the tree itself comes with package 30
##   Pilot      – portrait, name, call sign, attributes and a short career
## Mouse and keyboard (W/A/S/D, Enter, Q/E for the tabs, Escape).

signal closed

const PilotArt = preload("res://scripts/core/pilot_art.gd")
const PilotData = preload("res://data/pilot.gd")
const SkillData = preload("res://data/skills.gd")
const COL := Color(1.0, 0.82, 0.35)
const TABS := ["Skills", "Perks", "Skill tree", "Pilot"]
const TreeData = preload("res://data/skilltree.gd")

var tab := 0
var tab_buttons: Array = []
var body: VBoxContainer


func _ready() -> void:
	add_to_group("kbd_menu")
	layer = 25
	visible = false
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.55)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	var win := UI.neon_panel(COL, Color(0.06, 0.04, 0.02, 0.97))
	win.set_anchors_preset(Control.PRESET_FULL_RECT)
	win.offset_left = 90
	win.offset_right = -90
	win.offset_top = 50
	win.offset_bottom = -40
	bg.add_child(win)
	var v := UI.vbox(10)
	win.add_child(v)
	var head := UI.hbox(10)
	v.add_child(head)
	head.add_child(UI.label("PILOT", 22, COL))
	for i in TABS.size():
		var idx := i
		var b := UI.button(TABS[i], func(): _set_tab(idx))
		b.toggle_mode = true
		head.add_child(b)
		tab_buttons.append(b)
	head.add_child(UI.spacer())
	head.add_child(UI.button("Close [%s]" % Keybinds.key_text("menu_back"), close))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	body = UI.vbox(6)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(body)
	GameState.skills_changed.connect(func(): if visible: rebuild())


func open(p_tab: int = -1) -> void:
	if p_tab >= 0:
		tab = p_tab
	visible = true
	Audio.play("ui_open", "pilot window")
	rebuild()


func close() -> void:
	if not visible:
		return
	visible = false
	Audio.play("ui_close", "pilot window")
	closed.emit()


func menu_tab(step: int) -> void:
	_set_tab(posmod(tab + step, TABS.size()))


func _set_tab(i: int) -> void:
	tab = i
	rebuild()


func rebuild() -> void:
	for k in tab_buttons.size():
		tab_buttons[k].button_pressed = k == tab
	UI.clear(body)
	match tab:
		0: _skills()
		1: _perks()
		2: _tree()
		3: _pilot()


# ---- skills

func _skills() -> void:
	_level_bar(body)
	body.add_child(UI.label("Skills grow by doing: every activity gives experience to the skill behind it, and the skill rises by itself. All of it feeds the pilot level.", 13, UI.TEXT_DIM))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(grid)
	for s in SkillData.SKILLS:
		grid.add_child(_skill_card(s))


func _skill_card(s: Array) -> Control:
	var id: String = s[0]
	var sk: Dictionary = GameState.pilot.get("skills", {}).get(id, {"lvl": 0, "xp": 0.0})
	var lvl := int(sk["lvl"])
	var later := id in ["athletics", "firearms", "leadership"]
	var card := UI.neon_panel(Color(COL, 0.35), Color(0.05, 0.04, 0.03, 0.95), 1)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(560, 0)
	var v := UI.vbox(3)
	card.add_child(v)
	var top := UI.hbox(8)
	v.add_child(top)
	top.add_child(UI.label(String(s[1]).to_upper(), 16, COL if not later else UI.TEXT_DIM))
	var at_names: Array = []
	for a in s[2]:
		at_names.append(PilotData.name_of(String(a)))
	top.add_child(UI.label("(%s)" % " + ".join(PackedStringArray(at_names)), 11, UI.TEXT_DIM))
	top.add_child(UI.spacer())
	top.add_child(UI.label("Level %d / %d" % [lvl, SkillData.MAX_LEVEL], 13, UI.GOOD if lvl > 0 else UI.TEXT_DIM))
	# level pips
	var pips := UI.hbox(3)
	v.add_child(pips)
	for i in SkillData.MAX_LEVEL:
		var p := ColorRect.new()
		p.custom_minimum_size = Vector2(26, 8)
		p.color = COL if i < lvl else Color(0.2, 0.18, 0.14)
		pips.add_child(p)
	var row := UI.hbox(8)
	v.add_child(row)
	if lvl < SkillData.MAX_LEVEL:
		var need := SkillData.need(lvl)
		var bar := UI.bar(Color(0.75, 0.6, 0.3), 240)
		bar.max_value = need
		bar.value = minf(float(sk["xp"]), need)
		row.add_child(bar)
		row.add_child(UI.label("%d / %d XP" % [int(minf(float(sk["xp"]), need)), int(need)], 11, UI.TEXT_DIM))
		row.add_child(UI.label("learns ×%.2f" % SkillData.learn_rate(id, GameState.pilot.get("attrs", {})), 11, UI.TEXT_DIM))
	else:
		row.add_child(UI.label("Mastered", 12, UI.GOOD))
	v.add_child(UI.wrap_label("%s  –  now +%d %%" % [s[3], lvl], 12, Color(0.9, 0.9, 0.85), 540))
	v.add_child(UI.wrap_label("Grows by: %s" % s[4], 11, UI.TEXT_DIM, 540))
	return card


## The pilot level with its experience bar and the perk points (0.5.29.2).
func _level_bar(parent: Control) -> void:
	var row := UI.hbox(10)
	parent.add_child(row)
	var lvl := GameState.pilot_level()
	row.add_child(UI.label("PILOT LEVEL %d" % lvl, 18, COL))
	var need := SkillData.pilot_need(lvl)
	var bar := UI.bar(COL, 360)
	bar.max_value = need
	bar.value = minf(float(GameState.pilot.get("xp", 0.0)), need)
	row.add_child(bar)
	row.add_child(UI.label("%d / %d XP" % [int(bar.value), int(need)], 12, UI.TEXT_DIM))
	var pp := int(GameState.pilot.get("perk_points", 0))
	row.add_child(UI.label("%d perk point%s to spend" % [pp, "" if pp == 1 else "s"], 12, UI.GOOD if pp > 0 else UI.TEXT_DIM))


# ---- perks (package 30)

func _perks() -> void:
	_level_bar(body)
	body.add_child(UI.label("Every pilot level brings a perk point. Spend it on any perk below – some need a skill level first.", 13, UI.TEXT_DIM))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	body.add_child(grid)
	for g in TreeData.GROUPS:
		var p := UI.neon_panel(Color(COL, 0.35), Color(0.05, 0.04, 0.03, 0.95), 1)
		p.custom_minimum_size = Vector2(370, 0)
		var v := UI.vbox(5)
		p.add_child(v)
		v.add_child(UI.label(String(g).to_upper(), 16, COL))
		for id in TreeData.PERKS:
			var pk: Dictionary = TreeData.PERKS[id]
			if pk["group"] != g:
				continue
			v.add_child(_perk_row(String(id), pk))
		grid.add_child(p)


func _perk_row(id: String, pk: Dictionary) -> Control:
	var taken := GameState.has_perk(id)
	var err := GameState.perk_error(id)
	var box := UI.vbox(1)
	var top := UI.hbox(6)
	box.add_child(top)
	var nl := UI.label(("✓ " if taken else "") + String(pk["name"]), 14, UI.GOOD if taken else (Color(0.95, 0.92, 0.85) if err == "" else UI.TEXT_DIM))
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(nl)
	if not taken:
		var b := UI.button("Take", func(): _take(id))
		b.disabled = err != ""
		b.tooltip_text = err
		top.add_child(b)
	box.add_child(UI.wrap_label(String(pk["effect"]), 11, Color(0.85, 0.85, 0.8), 340))
	var need := ""
	if String(pk["skill"]) != "":
		need = "Needs %s %d" % [SkillData.info(String(pk["skill"]))[1], int(pk["lvl"])]
	if pk.has("later"):
		need += ("  •  " if need != "" else "") + "takes effect with %s" % pk["later"]
	if need != "" and not taken:
		box.add_child(UI.label(need, 10, UI.TEXT_DIM))
	return box


func _take(id: String) -> void:
	if Commands.execute({"type": "perk_take", "perk": id}) == "":
		Audio.play("mission_complete", "perk")
	rebuild()


# ---- the skill tree (package 30)

func _tree() -> void:
	var nt := GameState.tiles_ready().size()
	body.add_child(UI.label("Tiles open by doing: meet a tile's achievements (and open the tiles before it), then confirm it here. Ships and modules you already own stay usable.", 13, UI.TEXT_DIM))
	if nt > 0:
		body.add_child(UI.label("%d tile%s ready to open" % [nt, "" if nt == 1 else "s"], 14, UI.GOOD))
	for br in TreeData.BRANCHES:
		body.add_child(UI.label(String(br).to_upper(), 15, COL))
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 6)
		flow.add_theme_constant_override("v_separation", 6)
		body.add_child(flow)
		var first := true
		for id in TreeData.branch_tiles(br):
			if not first and (TreeData.TILES[id]["pre"] as Array).size() > 0:
				flow.add_child(UI.label("→", 18, Color(COL, 0.6)))
			first = false
			flow.add_child(_tile_card(String(id)))


func _tile_card(id: String) -> Control:
	var t: Dictionary = TreeData.TILES[id]
	var open := GameState.tile_open(id)
	var ready := GameState.tile_ready(id)
	var pre_ok := true
	for p in t["pre"]:
		pre_ok = pre_ok and GameState.tile_open(String(p))
	var col := UI.GOOD if ready else (COL if open else (Color(0.6, 0.55, 0.45) if pre_ok else Color(0.35, 0.32, 0.28)))
	var card := UI.neon_panel(Color(col, 0.9 if ready or open else 0.45), Color(0.05, 0.04, 0.03, 0.95) if not open else Color(0.12, 0.09, 0.03, 0.95), 2 if ready else 1)
	card.custom_minimum_size = Vector2(220, 0)
	var v := UI.vbox(2)
	card.add_child(v)
	v.add_child(UI.label(("✓ " if open else "") + String(t["name"]), 13, col))
	v.add_child(UI.wrap_label(String(t["opens"]), 10, Color(0.85, 0.85, 0.8), 205))
	if not open:
		if not pre_ok:
			var names: Array = []
			for p2 in t["pre"]:
				names.append(TreeData.TILES[p2]["name"])
			v.add_child(UI.wrap_label("after: " + ", ".join(PackedStringArray(names)), 10, UI.TEXT_DIM, 205))
		for r in GameState.tile_progress(id):
			var done := float(r[1]) >= float(r[2])
			v.add_child(UI.label("%s %s / %s %s" % ["✓" if done else "•", _num(float(r[1])), _num(float(r[2])), TreeData.METRICS.get(r[0], r[0])], 10, UI.GOOD if done else UI.TEXT_DIM))
		if bool(t.get("any", false)):
			v.add_child(UI.label("(one of them is enough)", 10, UI.TEXT_DIM))
		if ready:
			v.add_child(UI.button("Open", func(): _open_tile(id)))
	return card


func _num(x: float) -> String:
	return GameData.fmt_credits(int(x)).trim_suffix(" cr") if x >= 1000.0 else str(int(x))


func _open_tile(id: String) -> void:
	if Commands.execute({"type": "tree_unlock", "tile": id}) == "":
		Audio.play("mission_complete", "tile opened")
	rebuild()


# ---- the pilot

func _pilot() -> void:
	var row := UI.hbox(18)
	body.add_child(row)
	var frame := UI.neon_panel(Color(COL, 0.5), Color(0.02, 0.01, 0.05, 1.0), 1)
	row.add_child(frame)
	var por := TextureRect.new()
	por.texture = PilotArt.portrait(GameState.pilot.get("look", {}))
	por.custom_minimum_size = Vector2(240, 240)
	por.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	por.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	por.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.add_child(por)
	var v := UI.vbox(6)
	row.add_child(v)
	v.add_child(UI.label("CMDR %s" % GameState.pilot_title(), 22, UI.NEON_CYAN))
	_level_bar(v)
	v.add_child(UI.label("ATTRIBUTES", 14, COL))
	for at in PilotData.ATTRS:
		var r := UI.hbox(8)
		v.add_child(r)
		var l := UI.label(String(at[1]), 14)
		l.custom_minimum_size = Vector2(120, 0)
		r.add_child(l)
		var val := GameState.pilot_attr(String(at[0]))
		var pips := UI.hbox(2)
		r.add_child(pips)
		for i in PilotData.MAX:
			var p := ColorRect.new()
			p.custom_minimum_size = Vector2(14, 10)
			p.color = COL if i < val else Color(0.2, 0.18, 0.14)
			pips.add_child(p)
		r.add_child(UI.label(str(val), 14, UI.GOOD))
		r.add_child(UI.label(String(at[2]), 11, UI.TEXT_DIM))
	v.add_child(UI.label("CAREER", 14, COL))
	var st: Dictionary = GameState.stats
	v.add_child(UI.label("Flight time %s  •  jumps %d  •  ships destroyed %d  •  contracts %d  •  anomalies analysed %d  •  ore mined %.0f" % [
		SaveGame.fmt_time(GameState.play_time), int(st.get("jumps", 0)), int(st.get("kills", 0)), int(st.get("missions_done", 0)),
		int(st.get("analysed", 0)), float(st.get("mined", 0.0))], 13, UI.TEXT_DIM))
	v.add_child(UI.label("The attributes stay as they were set at the start; the looks can be changed at an Image Studio.", 11, UI.TEXT_DIM))
