extends CanvasLayer
## Package 29: the Pilot window (U). Four tabs (0.5.30.5: Pilot first, U always opens it):
##   Pilot      – sub-tabs Info (portrait, name, attributes, finances and all statistics), Standings (every
##                faction, moved here from the ship menu) and Codex (moved here from the ship menu)
##   Skills     – the twelve skills: level (10 pips), experience to the next level, the effect now, what makes it
##                grow; a ready advance is confirmed here ("Advance")
##   Perks      – a perk point per pilot level
##   Skill tree – drawn as a tree (0.5.30.2): the trunk (Pilot Licence) at the bottom, branches by activity;
##                drag it, walk it with W/A/S/D, the detail of a tile on the right
##   Gear       – package 51: the suit and what it adds up to, its weapon, belt and feature slots, the pockets and
##                the ship's locker (click to put on, take off, store, fetch)
## Mouse and keyboard (W/A/S/D, Enter, Q/E for the tabs, Escape).

signal closed

const PilotArt = preload("res://scripts/core/pilot_art.gd")
const PilotData = preload("res://data/pilot.gd")
const SkillData = preload("res://data/skills.gd")
const COL := Color(1.0, 0.82, 0.35)
const TABS := ["Pilot", "Skills", "Perks", "Skill tree", "Gear"]
const TAB_PILOT := 0
const TAB_SKILLS := 1
const TAB_PERKS := 2
const TAB_TREE := 3
const TAB_GEAR := 4
const GearData = preload("res://data/gear.gd")
const GearIcons = preload("res://scripts/ui/gear_icons.gd")
const SUBS := ["Info", "Standings", "Codex", "Collection"]
const CrewDataP = preload("res://data/crew.gd")
const BondPanel = preload("res://scripts/ui/station/bond_panel.gd")
const StandingView = preload("res://scripts/ui/standing_view.gd")
const CodexView = preload("res://scripts/ui/codex_view.gd")
const TreeData = preload("res://data/skilltree.gd")

var tab := 0
var sub := 0                              # Pilot tab: 0 Info, 1 Standings, 2 Codex, 3 Collection
var coll_cat := "perks"                   # Collection: the category shown (0.5.34.3)
var tab_buttons: Array = []
var body: VBoxContainer
var _sc: ScrollContainer
var _tsc: ScrollContainer                 # 0.5.30.2: the drawn tree
var _canvas: Control
var _detail_box: VBoxContainer
var _tiles := {}
var _sel := ""
var _tscroll := Vector2(-1, -1)
var _gear_msg := ""


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
	_sc = ScrollContainer.new()
	_sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(_sc)
	body = UI.vbox(6)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_sc.add_child(body)
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
	if is_instance_valid(_tsc) and _tsc.is_inside_tree():
		_tscroll = Vector2(_tsc.scroll_horizontal, _tsc.scroll_vertical)
	_tsc = null
	_canvas = null
	_detail_box = null
	var fixed := tab == TAB_TREE or (tab == TAB_PILOT and sub >= 2)     # the tree, the codex and the collection scroll by themselves
	_sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED if fixed else ScrollContainer.SCROLL_MODE_AUTO
	_sc.scroll_vertical = 0
	UI.clear(body)
	match tab:
		TAB_PILOT: _pilot()
		TAB_SKILLS: _skills()
		TAB_PERKS: _perks()
		TAB_TREE: _tree()
		TAB_GEAR: _gear()


# ---- package 51: gear

## Is the ship's locker at hand? Aboard (not walking about), or down in the hangar beside her.
func _locker_fit():
	var f := GameState.active()
	if f == null:
		return null
	var mn = get_tree().current_scene
	var g = mn.get("ground") if mn != null else null
	if g != null and is_instance_valid(g) and String(g.level) != "hangar":
		return null
	return f


## 0.7.51.7 (Luz: like the ship menu): the Gear page in the pattern of the ship's FITTING – on the left the suit as a
## mockup with the pilot in it, its bars and protection, then the piece picked; on the right the slots as tiles with
## pictures (suit, weapons, belt on its keys, features), the pockets and the ship's locker as tiles too. Click a tile
## to pick it, the buttons under its description act on it.
var _gsel := {}                            # {"where": suit|weapons|belt|features|inv|locker, "idx": int}


func _gear() -> void:
	var g = GameState.gear
	var t: Dictionary = g.totals()
	var fit = _locker_fit()
	var row := UI.hbox(16)
	body.add_child(row)
	# ---- left: the suit as a mockup, its bars, the piece picked
	var lp := UI.neon_panel(Color(COL, 0.35), Color(0.07, 0.05, 0.03, 0.95), 1)
	lp.custom_minimum_size = Vector2(430, 0)
	row.add_child(lp)
	var left := UI.vbox(6)
	lp.add_child(left)
	var top := UI.hbox(12)
	left.add_child(top)
	var stage := PanelContainer.new()
	stage.add_theme_stylebox_override("panel", UI.panel_style(Color(0.03, 0.03, 0.05), Color(COL, 0.25)))
	stage.custom_minimum_size = Vector2(150, 200)
	top.add_child(stage)
	var look: Dictionary = (GameState.pilot.get("look", ChibiArt.PilotArt.default_look()) as Dictionary).duplicate()
	look["suit"] = GearData.family(String(g.suit))
	look["helmet"] = g.helmet == "always"                # 0.7.51.10: as it is set to be worn
	stage.add_child(UI.icon(ChibiArt.frame(look, 0, 0), 190))
	var head := UI.vbox(3)
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(head)
	var sq := GearData.quality(String(g.suit))
	head.add_child(UI.wrap_label(GearData.display_name(String(g.suit)), 17, GameData.quality_color(sq) if sq != "" else COL, 240))
	var sd: Dictionary = GearData.stats(String(g.suit))
	head.add_child(UI.label("%s  •  quality %s" % [String(sd.get("maker", "")), sq], 12, UI.TEXT_DIM))
	head.add_child(UI.label("%d weapon%s  •  %d belt  •  %d feature%s" % [int(sd.get("weapons", 1)), "" if int(sd.get("weapons", 1)) == 1 else "s",
		int(sd.get("belt", 1)), int(sd.get("features", 0)), "" if int(sd.get("features", 0)) == 1 else "s"], 12, UI.TEXT_DIM))
	head.add_child(HSeparator.new())
	for ln in [["Health", g.health, GearData.HEALTH, Color(0.95, 0.35, 0.35)], ["Shield", t["shield"], t["shield"], Color(0.35, 0.8, 1.0)],
			["Armour", t["armor"], t["armor"], Color(0.8, 0.8, 0.75)], ["Energy", g.energy, t["energy"], Color(1.0, 0.82, 0.3)],
			["Oxygen", g.oxygen, t["oxygen"], Color(0.4, 0.6, 1.0)], ["Ammo", g.ammo, t["ammo"], Color(0.75, 0.75, 0.7)]]:
		var r := UI.hbox(6)
		r.add_child(UI.label(String(ln[0]), 12, UI.TEXT_DIM))
		r.add_child(UI.spacer())
		var bar := UI.bar(ln[3], 90)
		bar.max_value = maxf(1.0, float(ln[2]))
		bar.value = float(ln[1])
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		r.add_child(bar)
		var vl := UI.label("%d%s" % [int(ln[1]), " min" if String(ln[0]) == "Oxygen" else ""], 12, Color(0.92, 0.92, 0.9))
		vl.custom_minimum_size = Vector2(52, 0)
		vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		r.add_child(vl)
		head.add_child(r)
	left.add_child(UI.label("PROTECTION   •   walking speed ×%.2f" % float(t["speed"]), 13, COL))
	var pr := UI.hbox(10)
	left.add_child(pr)
	for h in GearData.HAZARDS:
		var pv := float(t["env"][h])
		var pc := Color(0.5, 1.0, 0.6) if pv >= 0.8 else (Color(1.0, 0.8, 0.35) if pv >= 0.5 else Color(1.0, 0.45, 0.35))
		var cell := UI.vbox(1)
		cell.add_child(UI.label("%s  %d%%" % [String(GearData.HAZARD_NAMES[h]), int(pv * 100.0)], 11, pc))
		var pb := UI.bar(pc, 92)
		pb.max_value = 1.0
		pb.value = pv
		cell.add_child(pb)
		pr.add_child(cell)
	# 0.7.51.10 (Luz): when the helmet is worn
	var hr := UI.hbox(6)
	left.add_child(hr)
	hr.add_child(UI.label("HELMET", 13, COL))
	hr.add_child(UI.spacer())
	for hm in [["auto", "When needed"], ["always", "Always"]]:
		var mode := String(hm[0])
		var hb := UI.button(String(hm[1]), func(): g.helmet = mode; _gear_do(""))
		hb.toggle_mode = true
		hb.button_pressed = g.helmet == mode
		hb.custom_minimum_size = Vector2(120, 28)
		hb.tooltip_text = "Only where the air cannot be breathed, and in a fight" if mode == "auto" else "On all the time, outside and aboard"
		hr.add_child(hb)
	left.add_child(HSeparator.new())
	_gear_sel_detail(left, g, fit)
	# ---- right: the slots, the pockets, the locker – tiles with pictures
	var right := UI.vbox(8)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	var sflow := _gear_flow(right, "Suit", "")
	sflow.add_child(_gear_tile(String(g.suit), 1, "", "suit", 0, "Suit"))
	for sec in [["weapons", "Weapons"], ["belt", "Belt  –  keys 1–%d" % g.belt.size()], ["features", "Features"]]:
		var key := String(sec[0])
		var arr: Array = g.get(key)
		var filled := 0
		for it in arr:
			if (it is Dictionary and not (it as Dictionary).is_empty()) or (it is String and String(it) != ""):
				filled += 1
		var flow := _gear_flow(right, String(sec[1]), "(%d/%d)" % [filled, arr.size()])
		for i in arr.size():
			var it2 = arr[i]
			var id := ""
			var n := 1
			if it2 is Dictionary:
				if not (it2 as Dictionary).is_empty():
					id = String(it2["id"])
					n = int(it2["n"])
			else:
				id = String(it2)
			flow.add_child(_gear_tile(id, n, str(i + 1) if key == "belt" else "", key, i, "empty"))
	var pflow := _gear_flow(right, "Pockets", "(%d/%d)" % [GearData.INV_SLOTS - g.free_places(), GearData.INV_SLOTS])
	for i2 in g.inv.size():
		var p: Dictionary = g.inv[i2]
		pflow.add_child(_gear_tile(String(p.get("id", "")), int(p.get("n", 1)), "", "inv", i2, ""))
	if fit != null:
		var l: Array = g.locker(fit)
		var lflow := _gear_flow(right, "Locker  –  %s" % fit.ship_name, "(%d/%d)" % [l.size() - g.free_places(l), l.size()])
		for j in l.size():
			var lpc: Dictionary = l[j]
			lflow.add_child(_gear_tile(String(lpc.get("id", "")), int(lpc.get("n", 1)), "", "locker", j, ""))
	else:
		right.add_child(UI.label("Locker", 17, COL))
		right.add_child(UI.label("  The ship's locker is aboard – you are not.", 12, UI.TEXT_DIM))


func _gear_flow(parent: VBoxContainer, title: String, count: String) -> HFlowContainer:
	parent.add_child(UI.label(title + ("   " + count if count != "" else ""), 17, COL))
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	parent.add_child(flow)
	parent.add_child(HSeparator.new())
	return flow


## A tile like the ship's module tiles: the picture, the quality in its corner (and its frame), a belt place's key,
## how many, the name under it.
func _gear_tile(id: String, n: int, key_badge: String, where: String, idx: int, empty_caption: String) -> Control:
	var box := UI.vbox(2)
	box.custom_minimum_size = Vector2(86, 0)
	var b := Button.new()
	b.custom_minimum_size = Vector2(72, 72)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.focus_mode = Control.FOCUS_NONE
	b.toggle_mode = true
	b.button_pressed = String(_gsel.get("where", "")) == where and int(_gsel.get("idx", -1)) == idx
	b.icon = GearIcons.icon(id)
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var q := GearData.quality(id) if id != "" else ""
	var border := Color(0.3, 0.27, 0.22)
	if id != "":
		border = GameData.quality_color(q) if q != "" else Color(0.75, 0.7, 0.6)
	var normal := UI.panel_style(Color(0.1, 0.08, 0.06), border)
	normal.set_border_width_all(2)
	var hover := UI.panel_style(Color(0.16, 0.13, 0.09), border.lightened(0.3))
	hover.set_border_width_all(2)
	var pressed := UI.panel_style(Color(0.1, 0.2, 0.16), Color(0.3, 1.0, 0.6))
	pressed.set_border_width_all(3)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("hover_pressed", pressed)
	if id != "":
		b.tooltip_text = "\n".join(GearData.describe(id))
	b.pressed.connect(func():
		_gsel = {"where": where, "idx": idx}
		_gear_msg = ""
		Audio.play("ui_click", "gear")
		rebuild())
	if key_badge != "":
		var kl := UI.label(key_badge, 12, Color(1.0, 0.82, 0.35))
		kl.position = Vector2(5, 2)
		b.add_child(kl)
	if q != "":
		var ql := UI.label(q, 12, GameData.quality_color(q))
		ql.position = Vector2(58, 2)
		b.add_child(ql)
	if n > 1:
		var nl := UI.label("×%d" % n, 11, Color(0.95, 0.95, 0.9))
		nl.position = Vector2(46, 54)
		b.add_child(nl)
	box.add_child(b)
	var cap := GearData.display_name(id).replace(" · " + q, "") if id != "" else empty_caption
	var l := UI.label(cap, 11, Color(0.92, 0.88, 0.8) if id != "" else UI.TEXT_DIM)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(86, 0)
	box.add_child(l)
	return box


## What is picked: its picture, name, what it does – and what can be done with it from where it is.
func _gear_sel_detail(left: VBoxContainer, g, fit) -> void:
	var where := String(_gsel.get("where", ""))
	var idx := int(_gsel.get("idx", -1))
	var id := ""
	var n := 1
	match where:
		"suit":
			id = String(g.suit)
		"weapons", "belt", "features":
			var arr: Array = g.get(where)
			if idx >= 0 and idx < arr.size():
				var it = arr[idx]
				if it is Dictionary:
					id = String((it as Dictionary).get("id", ""))
					n = int((it as Dictionary).get("n", 1))
				else:
					id = String(it)
		"inv":
			if idx >= 0 and idx < g.inv.size():
				id = String(g.inv[idx].get("id", ""))
				n = int(g.inv[idx].get("n", 1))
		"locker":
			if fit != null:
				var lk: Array = g.locker(fit)
				if idx >= 0 and idx < lk.size():
					id = String(lk[idx].get("id", ""))
					n = int(lk[idx].get("n", 1))
	if id == "":
		left.add_child(UI.label("Select a piece" if where == "" else "Empty place", 17, COL))
		left.add_child(UI.wrap_label("Click a tile to see what it does. Pieces in your pockets go on from here; the ship's locker is open aboard or down in the hangar beside her." if where == "" else "Pick something in your pockets to put on.", 12, UI.TEXT_DIM, 400))
	else:
		var hd := UI.hbox(10)
		left.add_child(hd)
		hd.add_child(UI.icon(GearIcons.icon(id), 64))
		var nv := UI.vbox(2)
		hd.add_child(nv)
		var q := GearData.quality(id)
		nv.add_child(UI.wrap_label(GearData.display_name(id) + (" ×%d" % n if n > 1 else ""), 16, GameData.quality_color(q) if q != "" else COL, 320))
		nv.add_child(UI.label(String({"suit": "Worn", "weapons": "Weapon slot %d" % (idx + 1), "belt": "Belt – key %d" % (idx + 1), "features": "Feature slot %d" % (idx + 1),
			"inv": "In your pockets", "locker": "In the ship's locker"}.get(where, "")), 12, UI.TEXT_DIM))
		for ln in GearData.describe(id):
			if String(ln) != "":
				left.add_child(UI.wrap_label(String(ln), 12, Color(0.88, 0.86, 0.8), 400))
		var acts := UI.hbox(6)
		left.add_child(acts)
		match where:
			"suit":
				left.add_child(UI.label("Put another suit on from your pockets.", 11, UI.TEXT_DIM))
			"weapons", "belt", "features":
				acts.add_child(UI.button("Take off → pockets", func(): _gsel = {}; _gear_do(g.unequip(where, idx))))
			"inv":
				acts.add_child(UI.button("Put on", func(): _gsel = {}; _gear_do(g.equip_from_inv(idx))))
				if fit != null:
					acts.add_child(UI.button("→ Locker", func(): _gsel = {}; _gear_do(g.store(idx, fit))))
			"locker":
				acts.add_child(UI.button("← Into the pockets", func(): _gsel = {}; _gear_do(g.fetch(idx, fit))))
	if _gear_msg != "":
		left.add_child(UI.label(_gear_msg, 13, Color(1.0, 0.6, 0.4)))


func _gear_do(err: String) -> void:
	_gear_msg = err
	var mn = get_tree().current_scene
	var gv = mn.get("ground") if mn != null else null
	if gv != null and is_instance_valid(gv) and gv.pilot != null:
		gv.pilot.look = gv.pilot_look()                      # 0.7.51.2: on foot – the new suit at once
		gv.pilot.slung = gv._slung()
	Audio.play("ui_click" if err == "" else "ui_error", "gear")
	rebuild()


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


# ---- the skill tree (package 30, drawn as a tree since 0.5.30.2)

const TILE := Vector2(160, 56)
const ROOT_TILE := Vector2(196, 64)
const COL_W := 180.0
const ROW_H := 108.0
const MARGIN := 40.0
const GROUND := 150.0          # the earth under the licence: the roots (mastery)
const TOP := 46.0
const TRUNK_H := 150.0         # licence -> shields
const CROWN_H := 250.0         # shields -> the branches: room for the crown to fan out


func _tree() -> void:
	var nt := GameState.tiles_ready().size()
	var top := UI.hbox(14)
	body.add_child(top)
	top.add_child(UI.label("Tiles open by doing – meet the achievements, then confirm. Everything can be bought; with the tile it can be used.", 12, UI.TEXT_DIM))
	top.add_child(UI.spacer())
	if nt > 0:
		top.add_child(UI.label("%d tile%s ready to open" % [nt, "" if nt == 1 else "s"], 13, UI.GOOD))
	var row := UI.hbox(10)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(row)
	_tsc = ScrollContainer.new()
	_tsc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tsc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(_tsc)
	var lay := TreeData.layout()
	var cols := float(lay["_cols"])
	var depth := 0
	for id in TreeData.TILES:
		depth = maxi(depth, int(lay[id].y))
	var cv := TreeCanvas.new()
	cv.custom_minimum_size = Vector2(cols * COL_W + MARGIN * 2.0, TOP + _rise(depth) + ROOT_TILE.y + GROUND)
	cv.scroll = _tsc
	_tsc.add_child(cv)
	_canvas = cv
	_tiles.clear()
	var centre := {}
	for id in TreeData.TILES:
		var p: Vector2 = lay[id]
		centre[id] = Vector2(MARGIN + p.x * COL_W + COL_W * 0.5, cv.custom_minimum_size.y - GROUND - ROOT_TILE.y * 0.5 - _rise(int(p.y)))
	# the branches: from the top of a tile to the bottom of each tile that grows from it
	for id in TreeData.TILES:
		var t: Dictionary = TreeData.TILES[id]
		var pre: Array = t["pre"]
		for i in pre.size():
			var par := String(pre[i])
			var from: Vector2 = centre[par] - Vector2(0, _size_of(par).y * 0.5)
			var to: Vector2 = centre[id] + Vector2(0, _size_of(id).y * 0.5)
			var d := int(lay[par].y)
			var sideways: bool = int(lay[id].y) < 0                 # a root: out of the side of the tile before it
			if sideways:
				var sx := signf(centre[id].x - centre[par].x)
				from = centre[par] + Vector2(sx * _size_of(par).x * 0.5, 10.0 if par == TreeData.ROOT else 0.0)
				to = centre[id] - Vector2(sx * _size_of(id).x * 0.5, 0)
			cv.links.append({"from": from, "to": to, "width": (5.0 if par == TreeData.ROOT else 3.5) if sideways else (maxf(2.0, 10.0 - float(d) * 2.6) if i == 0 else 2.0), "sideways": sideways,
				"state": "open" if GameState.tile_open(id) else ("ready" if GameState.tile_ready(id) else ("near" if GameState.tile_open(par) else "far")),
				"second": i > 0})
	cv.root_bottom = centre[TreeData.ROOT] + Vector2(0, ROOT_TILE.y * 0.5)
	for id in TreeData.TILES:
		var pr0: Array = TreeData.TILES[id]["pre"]
		if (not pr0.is_empty() and String(pr0[0]) == TreeData.TRUNK):
			cv.captions.append([centre[id] + Vector2(-_size_of(id).x * 0.5, -_size_of(id).y * 0.5 - 6.0), String(TreeData.TILES[id]["branch"]).to_upper(), TreeData.BRANCH_COLORS.get(TreeData.TILES[id]["branch"], COL)])
	for id in TreeData.TILES:
		var b := _tree_tile(String(id))
		b.position = centre[id] - _size_of(id) * 0.5
		cv.add_child(b)
		_tiles[id] = b
	# the detail of the tile in view
	var dp := UI.neon_panel(Color(COL, 0.5), Color(0.04, 0.03, 0.02, 0.97), 1)
	dp.custom_minimum_size = Vector2(310, 0)
	row.add_child(dp)
	_detail_box = UI.vbox(6)
	dp.add_child(_detail_box)
	if _sel == "" or not TreeData.TILES.has(_sel):
		_sel = TreeData.ROOT
	_fill_detail()
	_place_view()


## How high above the licence a depth sits (the trunk and the crown are taller than the rows above them).
func _rise(d: int) -> float:
	if d < 0:
		return -(ROOT_TILE.y * 0.5 + 62.0)
	if d == 0:
		return 0.0
	if d == 1:
		return TRUNK_H
	return TRUNK_H + CROWN_H + float(d - 2) * ROW_H


func _size_of(id: String) -> Vector2:
	return ROOT_TILE if id == TreeData.ROOT else TILE


func _tree_tile(id: String) -> Button:
	var t: Dictionary = TreeData.TILES[id]
	var open := GameState.tile_open(id)
	var ready := GameState.tile_ready(id)
	var pre_ok := true
	for p in t["pre"]:
		pre_ok = pre_ok and GameState.tile_open(String(p))
	var bc: Color = TreeData.BRANCH_COLORS.get(t["branch"], COL)
	var edge := UI.GOOD if ready else (COL if open else (Color(bc, 0.55) if pre_ok else Color(0.3, 0.27, 0.22)))
	var b := Button.new()
	b.custom_minimum_size = _size_of(id)
	b.size = _size_of(id)
	b.focus_mode = Control.FOCUS_ALL
	var styles := {"normal": 0.0, "hover": 0.12, "pressed": 0.2, "disabled": 0.0}
	for k in styles:
		var sb := StyleBoxFlat.new()
		var base := Color(0.17, 0.12, 0.03) if open else (Color(0.03, 0.12, 0.05) if ready else Color(0.05, 0.04, 0.035))
		sb.bg_color = base.lightened(float(styles[k]))
		sb.border_color = edge
		sb.set_border_width_all(3 if ready else (2 if open else 1))
		sb.set_corner_radius_all(6)
		b.add_theme_stylebox_override(k, sb)
	var fs := StyleBoxFlat.new()
	fs.bg_color = Color(0, 0, 0, 0)
	fs.border_color = Color(1.0, 0.97, 0.6)
	fs.set_border_width_all(3)
	fs.set_corner_radius_all(7)
	fs.expand_margin_left = 4
	fs.expand_margin_right = 4
	fs.expand_margin_top = 4
	fs.expand_margin_bottom = 4
	b.add_theme_stylebox_override("focus", fs)
	var stripe := ColorRect.new()
	stripe.color = Color(bc, 0.9 if open or ready else 0.35)
	stripe.position = Vector2(5, 8)
	stripe.size = Vector2(3, _size_of(id).y - 16)
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(stripe)
	var v := UI.vbox(0)
	v.position = Vector2(14, 6)
	v.size = _size_of(id) - Vector2(20, 10)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	var root := id == TreeData.ROOT
	var nm := UI.label(("PILOT LICENCE" if root else String(t["name"])), 15 if root else (13 if String(t["name"]).length() <= 18 else 12), COL if open else (UI.GOOD if ready else (Color(0.85, 0.82, 0.75) if pre_ok else Color(0.5, 0.47, 0.42))))
	nm.clip_text = true
	v.add_child(nm)
	var st := ""
	var sc := UI.TEXT_DIM
	if open:
		st = "✓ open" if not root else "✓ the trunk of every career"
		sc = Color(COL, 0.75)
	elif ready:
		st = "READY – open it"
		sc = UI.GOOD
	elif not pre_ok:
		st = "locked"
		sc = Color(0.45, 0.42, 0.38)
	else:
		st = "%d %%" % int(_progress(id) * 100.0)
	v.add_child(UI.label(st, 10, sc))
	if pre_ok and not open and not ready:
		var pb := UI.bar(Color(bc, 0.8), _size_of(id).x - 28)
		pb.custom_minimum_size.y = 4
		pb.max_value = 1.0
		pb.step = 0.001
		pb.value = _progress(id)
		pb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(pb)
	b.tooltip_text = String(t["name"])
	b.focus_entered.connect(func(): _select(id))
	b.mouse_entered.connect(func(): _select(id))
	b.pressed.connect(func():
		_select(id)
		if GameState.tile_ready(id):
			_open_tile(id))
	return b


## How far a tile's achievements are (0…1; "any" tiles: the best one).
func _progress(id: String) -> float:
	var pr := GameState.tile_progress(id)
	if pr.is_empty():
		return 1.0
	var sum := 0.0
	var best := 0.0
	for r in pr:
		var f := clampf(float(r[1]) / maxf(float(r[2]), 0.001), 0.0, 1.0)
		sum += f
		best = maxf(best, f)
	return best if bool(TreeData.TILES[id].get("any", false)) else sum / float(pr.size())


func _select(id: String) -> void:
	if _sel == id:
		return
	_sel = id
	_fill_detail()


func _fill_detail() -> void:
	if not is_instance_valid(_detail_box):
		return
	UI.clear(_detail_box)
	var id := _sel
	var t: Dictionary = TreeData.TILES[id]
	var bc: Color = TreeData.BRANCH_COLORS.get(t["branch"], COL)
	var open := GameState.tile_open(id)
	var ready := GameState.tile_ready(id)
	_detail_box.add_child(UI.label(String(t["branch"]).to_upper(), 11, bc))
	_detail_box.add_child(UI.wrap_label(String(t["name"]), 19, COL if open else (UI.GOOD if ready else Color(0.92, 0.9, 0.85)), 290))
	_detail_box.add_child(UI.label("✓ OPEN" if open else ("READY TO OPEN" if ready else "NOT YET OPEN"), 12, COL if open else (UI.GOOD if ready else UI.TEXT_DIM)))
	_detail_box.add_child(UI.label("USE", 12, COL))
	var txt := TreeData.opens_text(id)
	_detail_box.add_child(UI.wrap_label(txt if txt != "" else "–", 12, Color(0.88, 0.88, 0.82), 290))
	var pre: Array = t["pre"]
	if not pre.is_empty():
		_detail_box.add_child(UI.label("GROWS FROM", 12, COL))
		for p in pre:
			var po := GameState.tile_open(String(p))
			_detail_box.add_child(UI.label("%s %s" % ["✓" if po else "•", TreeData.TILES[p]["name"]], 12, UI.GOOD if po else UI.BAD))
	var pr := GameState.tile_progress(id)
	if not pr.is_empty():
		_detail_box.add_child(UI.label("ACHIEVEMENTS" + ("  (one is enough)" if bool(t.get("any", false)) else ""), 12, COL))
		for r in pr:
			var done := float(r[1]) >= float(r[2])
			_detail_box.add_child(UI.label("%s %s / %s %s" % ["✓" if done else "•", _num(minf(float(r[1]), float(r[2])) if done else float(r[1])), _num(float(r[2])), TreeData.METRICS.get(r[0], r[0])], 12, UI.GOOD if done else UI.TEXT_DIM))
			var pb := UI.bar(UI.GOOD if done else bc, 280)
			pb.max_value = float(r[2])
			pb.value = minf(float(r[1]), float(r[2]))
			_detail_box.add_child(pb)
	if ready:
		var ob := UI.button("Open %s" % t["name"], func(): _open_tile(id))
		ob.add_theme_color_override("font_color", UI.GOOD)
		_detail_box.add_child(ob)
	_detail_box.add_child(UI.spacer())
	_detail_box.add_child(UI.wrap_label("Drag to move the tree • %s %s %s %s walk from tile to tile • Enter opens a ready tile.\nA ship without its tile stays docked; a module without it stays offline (core modules fitted already keep working)." % [
		Keybinds.key_text("menu_up"), Keybinds.key_text("menu_left"), Keybinds.key_text("menu_down"), Keybinds.key_text("menu_right")], 10, UI.TEXT_DIM, 290))


## The view: where it was before, at first the trunk at the bottom; the selected tile takes the highlight.
func _place_view() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(_tsc) or not is_instance_valid(_canvas):
		return
	if _tscroll.x < 0.0:
		var rb: Vector2 = _canvas.root_bottom
		_tsc.scroll_horizontal = int(rb.x - _tsc.size.x * 0.5)
		_tsc.scroll_vertical = int(_canvas.size.y)
	else:
		_tsc.scroll_horizontal = int(_tscroll.x)
		_tsc.scroll_vertical = int(_tscroll.y)
	if visible and _tiles.has(_sel) and is_instance_valid(_tiles[_sel]):
		var keep := _sel
		_tiles[_sel].grab_focus()
		_sel = keep
		if _tscroll.x < 0.0:
			_tsc.scroll_horizontal = int(_canvas.root_bottom.x - _tsc.size.x * 0.5)
			_tsc.scroll_vertical = int(_canvas.size.y)


func _num(x: float) -> String:
	return GameData.fmt_credits(int(x)).trim_suffix(" cr") if x >= 1000.0 else str(int(x))


func _open_tile(id: String) -> void:
	if Commands.execute({"type": "tree_unlock", "tile": id}) == "":
		Audio.play("mission_complete", "tile opened")
	rebuild()


## The tree itself: earth, roots, the trunk and the branches; drag it with the mouse.
class TreeCanvas extends Control:
	var links: Array = []
	var captions: Array = []
	var root_bottom := Vector2.ZERO
	var scroll: ScrollContainer
	var _drag := false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_DRAG

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]:
			_drag = e.pressed
			accept_event()
		elif e is InputEventMouseMotion and _drag and scroll != null:
			scroll.scroll_horizontal -= int(e.relative.x)
			scroll.scroll_vertical -= int(e.relative.y)
			accept_event()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.025, 0.018, 0.012))
		# a few faint stars above, the earth below
		var rng := RandomNumberGenerator.new()
		rng.seed = 30
		for i in 220:
			var p := Vector2(rng.randf() * w, rng.randf() * (h - 120.0))
			draw_rect(Rect2(p, Vector2(2, 2)), Color(1.0, 0.9, 0.7, rng.randf_range(0.05, 0.25)))
		var gy := root_bottom.y + 8.0
		draw_rect(Rect2(0, gy, w, h - gy), Color(0.07, 0.045, 0.02))
		draw_line(Vector2(0, gy), Vector2(w, gy), Color(1.0, 0.8, 0.35, 0.35), 2.0)
		var trunk := Color(0.62, 0.43, 0.16)
		# small roots under the licence (the mastery roots are links)
		for k in [-1.0, 1.0]:
			for j in 3:
				var a := root_bottom + Vector2(k * (6.0 + j * 5.0), 8.0)
				var b := a + Vector2(k * (24.0 + j * 22.0), 40.0 + j * 18.0)
				_curve(a, b, Vector2(0, 20), Vector2(k * -10.0, -14), 4.0 - j * 1.0, Color(trunk, 0.6))
		var font0 := get_theme_default_font()
		draw_string(font0, Vector2(root_bottom.x - 100.0, h - 14.0), "MASTERY  -  THE ROOTS", HORIZONTAL_ALIGNMENT_CENTER, 200, 11, Color(0.95, 0.95, 0.95, 0.55))
		# the branches – the far ones first, the open ones on top
		for pass_state in [["far"], ["near"], ["ready"], ["open"]]:
			for l in links:
				if not String(l["state"]) in pass_state:
					continue
				var col: Color
				match String(l["state"]):
					"open": col = Color(1.0, 0.8, 0.3)
					"ready": col = Color(0.45, 1.0, 0.6)
					"near": col = Color(0.72, 0.55, 0.28, 0.75)
					_: col = Color(0.42, 0.33, 0.2, 0.55)
				var a: Vector2 = l["from"]
				var b: Vector2 = l["to"]
				var ta := Vector2(0, -(a.y - b.y) * 0.55)
				var tb := -ta
				if bool(l.get("sideways", false)):
					ta = Vector2((b.x - a.x) * 0.5, 0)
					tb = -ta
				var wd := float(l["width"])
				if String(l["state"]) == "open" and not bool(l["second"]):
					_curve(a, b, ta, tb, wd + 4.0, Color(1.0, 0.75, 0.25, 0.18))
				_curve(a, b, ta, tb, wd, col, bool(l["second"]))
		var font := get_theme_default_font()
		for c in captions:
			draw_string(font, c[0], String(c[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(c[2], 0.85))

	func _curve(a: Vector2, b: Vector2, ta: Vector2, tb: Vector2, wd: float, col: Color, dashed := false) -> void:
		var pts := PackedVector2Array()
		var n := 28
		for i in n + 1:
			var t := float(i) / float(n)
			var u := 1.0 - t
			pts.append(a * u * u * u + (a + ta) * 3.0 * u * u * t + (b + tb) * 3.0 * u * t * t + b * t * t * t)
		if dashed:
			for i in range(0, n, 2):
				draw_line(pts[i], pts[i + 1], col, wd, true)
		else:
			draw_polyline(pts, col, wd, true)


# ---- the pilot

func _pilot() -> void:
	var subs := UI.hbox(4)
	body.add_child(subs)
	for i in SUBS.size():
		var idx := i
		var b := UI.button(SUBS[i], func(): _set_sub(idx))
		b.toggle_mode = true
		b.button_pressed = i == sub
		b.custom_minimum_size = Vector2(130, 30)
		subs.add_child(b)
	var line := ColorRect.new()
	line.color = Color(COL, 0.4)
	line.custom_minimum_size = Vector2(0, 2)
	body.add_child(line)
	match sub:
		0: _pilot_info()
		1: StandingView.build(body)
		2:
			var cv := CodexView.new()
			body.add_child(cv)
			cv.setup(true)
		3: _collection()


## Package 34: the collection – crew perks the pilot has had in the crew (tiles; the rest "???"), notorious pirates
## destroyed (their wanted posters with the mugshot).
func _collection() -> void:
	var row := UI.hbox(14)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(row)
	# the categories as a button list on the left (0.5.34.3)
	var left := UI.vbox(4)
	left.custom_minimum_size = Vector2(250, 0)
	row.add_child(left)
	var have: Array = GameState.collection.get("perks", [])
	var killed: Array = GameState.collection.get("notorious", [])
	var stars_seen: Array = GameState.collection.get("stars", [])
	var cats := [["perks", "Crew perks", "%d / %d" % [have.size(), CrewDataP.PERKS.size()]], ["notorious", "Notorious pirates", "%d destroyed" % killed.size()],
		["stars", "Star classes", "%d / %d" % [stars_seen.size(), Universe.STAR_TYPES.size()]],
		["planets", "Planet types", "%d / %d" % [_seen_of(Universe.PLANET_TYPES).size(), Universe.PLANET_TYPES.size()]],
		["moons", "Moon types", "%d / %d" % [_seen_of(Universe.MOON_TYPES).size(), Universe.MOON_TYPES.size()]]]
	for c in cats:
		var cid: String = c[0]
		var b := UI.button("%s   %s" % [c[1], c[2]], func(): coll_cat = cid; rebuild())
		b.toggle_mode = true
		b.button_pressed = coll_cat == cid
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(250, 36)
		left.add_child(b)
	# the chosen category on the right
	var rs := ScrollContainer.new()
	rs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rs.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	row.add_child(rs)
	var right := UI.vbox(8)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rs.add_child(right)
	match coll_cat:
		"stars":
			_collection_stars(right, stars_seen)
		"planets":
			_collection_bodies(right, Universe.PLANET_TYPES, "PLANET TYPES", "A planet type counts once you have been in a system with such a world.")
		"moons":
			_collection_bodies(right, Universe.MOON_TYPES, "MOON TYPES", "A moon type counts once you have been in a system with such a moon.")
		"notorious":
			right.add_child(UI.label("NOTORIOUS PIRATES DESTROYED  %d" % killed.size(), 16, COL))
			if killed.is_empty():
				right.add_child(UI.label("None yet – their wanted posters hang in every Bond Office.", 12, UI.TEXT_DIM))
				return
			var pf := HFlowContainer.new()
			pf.add_theme_constant_override("h_separation", 12)
			pf.add_theme_constant_override("v_separation", 12)
			right.add_child(pf)
			for k in range(killed.size() - 1, -1, -1):
				pf.add_child(BondPanel.wanted_poster(killed[k]))
		_:
			right.add_child(UI.label("CREW PERKS  %d / %d" % [have.size(), CrewDataP.PERKS.size()], 16, COL))
			right.add_child(UI.label("A perk counts once a crew member with it serves you – aboard, on the platform or in the crew quarters. Perks are very rare.", 12, UI.TEXT_DIM))
			var k := _coll_scale()
			var flow := _coll_flow(right, 230.0 * k)
			for p in CrewDataP.PERKS:
				var got: bool = p in have
				var tile := UI.neon_panel(Color(COL, 0.8) if got else Color(0.4, 0.4, 0.42, 0.5), Color(0.12, 0.09, 0.03, 0.95) if got else Color(0.06, 0.06, 0.07, 0.95), 2 if got else 1)
				tile.custom_minimum_size = Vector2(230, 96) * k
				flow.add_child(tile)
				var v := UI.vbox(2)
				tile.add_child(v)
				if got:
					v.add_child(UI.label("★ " + String(CrewDataP.PERKS[p]["name"]), int(15 * k), COL))
					var tx := UI.wrap_label(String(CrewDataP.PERKS[p]["text"]), int(11 * k), Color(0.9, 0.88, 0.8), 100)
					tx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					v.add_child(tx)
				else:
					var q := UI.label("???", int(34 * k), Color(0.45, 0.45, 0.48))
					q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					q.size_flags_vertical = Control.SIZE_EXPAND_FILL
					q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
					v.add_child(q)


## 0.6.38.2: the collection grows with the screen – tiles, pictures and text scale with the window (1× up to
## 1600×900, up to 2.4× on very large screens), and the tiles stretch so that each row fills the width.
func _coll_scale() -> float:
	var vs := get_viewport().get_visible_rect().size
	return clampf(minf(vs.x / 1600.0, vs.y / 900.0), 1.0, 2.4)


## A flow of tiles whose width is fitted to the space: as many columns of at least `min_w` as fit, the tiles then
## share the rest of the row.
func _coll_flow(right: VBoxContainer, min_w: float) -> HFlowContainer:
	var flow := HFlowContainer.new()
	var sep := 10
	flow.add_theme_constant_override("h_separation", sep)
	flow.add_theme_constant_override("v_separation", sep)
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(flow)
	var fit := func():
		var w := flow.size.x
		if w <= 0.0:
			return
		var cols := maxi(1, int(floor((w + sep) / (min_w + sep))))
		var tw := floorf((w - sep * (cols - 1)) / cols) - 1.0
		for c in flow.get_children():
			var ctl := c as Control
			if ctl != null and absf(ctl.custom_minimum_size.x - tw) > 0.5:
				ctl.custom_minimum_size.x = tw
	flow.resized.connect(fit)
	return flow


## The pilot's collected types among `types` (planet and moon types share one list in the save).
func _seen_of(types: Dictionary) -> Array:
	var out := []
	for tid in GameState.collection.get("planets", []):
		if types.has(tid):
			out.append(tid)
	return out


## One tile of the star and body collections: an animated picture (its shader; greyed out while unknown), name,
## facts and a few words – or "???".
func _coll_tile(flow: HFlowContainer, k: float, got: bool, mat: Material, title: String, facts: String, text: String) -> void:
	var tile := UI.neon_panel(Color(COL, 0.8) if got else Color(0.4, 0.4, 0.42, 0.5), Color(0.03, 0.03, 0.07, 0.97) if got else Color(0.06, 0.06, 0.07, 0.95), 2 if got else 1)
	tile.custom_minimum_size = Vector2(360, 150) * k
	flow.add_child(tile)
	var h := UI.hbox(int(10 * k))
	tile.add_child(h)
	var pic := TextureRect.new()
	pic.texture = PixelArt.white()
	pic.custom_minimum_size = Vector2(120, 120) * k
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_SCALE
	pic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pic.material = mat
	if not got:
		# the shader ignores modulate – a dark veil over the picture greys it out
		var veil := ColorRect.new()
		veil.color = Color(0.07, 0.07, 0.08, 0.86)
		veil.set_anchors_preset(Control.PRESET_FULL_RECT)
		veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pic.add_child(veil)
	h.add_child(pic)
	var v := UI.vbox(int(3 * k))
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	if got:
		v.add_child(UI.label(title, int(15 * k), COL))
		v.add_child(UI.label(facts, int(12 * k), UI.NEON_CYAN))
		var tx := UI.wrap_label(text, int(11 * k), Color(0.9, 0.88, 0.8), 100)
		tx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(tx)
	else:
		var q := UI.label("???", int(34 * k), Color(0.45, 0.45, 0.48))
		q.size_flags_vertical = Control.SIZE_EXPAND_FILL
		q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		v.add_child(q)


## 0.6.37.2: a tile per star class – a small animated picture of the star, its size in solar radii, its mass in
## solar masses, its surface temperature and a few words. Classes not visited yet show greyed out as "???".
func _collection_stars(right: VBoxContainer, seen: Array) -> void:
	var k := _coll_scale()
	right.add_child(UI.label("STAR CLASSES  %d / %d" % [seen.size(), Universe.STAR_TYPES.size()], int(16 * k), COL))
	right.add_child(UI.label("A star class counts once you have been in a system with such a star.", int(12 * k), UI.TEXT_DIM))
	var flow := _coll_flow(right, 360.0 * k)
	for t in Universe.STAR_TYPES:
		var spr: Sprite2D = Celestial.make_star_sprite({"color": t["color"], "color2": t["color2"], "kind": t["kind"], "star_id": t["id"], "radius": t["radius"], "seed": 3.0}, 100.0)
		var sm := spr.material as ShaderMaterial
		sm.set_shader_parameter("pixels", 120.0 if String(t["kind"]) in ["main", "brown", "giant", "white"] else 160.0)
		spr.free()
		_coll_tile(flow, k, String(t["id"]) in seen, sm, String(t["name"]), "%s R☉  •  %s M☉  •  %s" % [t["r_sun"], t["m_sun"], t["temp"]], String(t["text"]))


## 0.6.38.1: a tile per planet type (0.6.38.2: and, in a category of their own, per moon type) – a small turning
## picture, size in Earth radii, mass in Earth masses, temperature and a few words; types not seen yet show greyed
## out as "???".
func _collection_bodies(right: VBoxContainer, types: Dictionary, head: String, hint: String) -> void:
	var k := _coll_scale()
	right.add_child(UI.label("%s  %d / %d" % [head, _seen_of(types).size(), types.size()], int(16 * k), COL))
	right.add_child(UI.label(hint, int(12 * k), UI.TEXT_DIM))
	var flow := _coll_flow(right, 360.0 * k)
	var seen: Array = GameState.collection.get("planets", [])
	var i := 0
	for tid in types:
		var t: Dictionary = types[tid]
		var ring: bool = String(tid) in ["gas", "ice_giant", "red_gas"]
		var spr: Sprite2D = Celestial.make_planet_sprite({"type": tid, "seed": 7.0 + i * 5.0, "ring": ring, "city": 0.8 if String(tid) in Universe.CITY_WORLDS else 0.0}, 100.0, Vector2(-0.8, -0.35))
		var sm := spr.material as ShaderMaterial
		sm.set_shader_parameter("pixels", 120.0 if not ring else 200.0)
		spr.free()
		_coll_tile(flow, k, String(tid) in seen, sm, String(t["name"]), "%s R⊕  •  %s M⊕  •  %s" % [t.get("r_earth", "?"), t.get("m_earth", "?"), t.get("temp", "?")], String(t.get("text", "")))
		i += 1


func _set_sub(i: int) -> void:
	sub = i
	rebuild()


## Info: who the pilot is, and every number the career has gathered.
func _pilot_info() -> void:
	var row := UI.hbox(18)
	body.add_child(row)
	var frame := UI.neon_panel(Color(COL, 0.5), Color(0.02, 0.01, 0.05, 1.0), 1)
	row.add_child(frame)
	var por := TextureRect.new()
	por.texture = PilotArt.portrait(GameState.pilot.get("look", {}))
	por.custom_minimum_size = Vector2(220, 220)
	por.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	por.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	por.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.add_child(por)
	var v := UI.vbox(6)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(v)
	v.add_child(UI.label("CMDR %s" % GameState.pilot_title(), 22, UI.NEON_CYAN))
	var nrow := UI.hbox(6)
	v.add_child(nrow)
	var le := LineEdit.new()
	le.text = GameState.pilot_name
	le.custom_minimum_size = Vector2(220, 0)
	nrow.add_child(le)
	nrow.add_child(UI.button("Rename", func():
		Commands.execute({"type": "rename_pilot", "name": le.text})
		rebuild()))
	_level_bar(v)
	v.add_child(UI.label("ATTRIBUTES", 14, COL))
	for at in PilotData.ATTRS:
		var r := UI.hbox(8)
		v.add_child(r)
		var l := UI.label(String(at[1]), 13)
		l.custom_minimum_size = Vector2(120, 0)
		r.add_child(l)
		var val := GameState.pilot_attr(String(at[0]))
		var pips := UI.hbox(2)
		r.add_child(pips)
		for i in PilotData.MAX:
			var p := ColorRect.new()
			p.custom_minimum_size = Vector2(14, 9)
			p.color = COL if i < val else Color(0.2, 0.18, 0.14)
			pips.add_child(p)
		r.add_child(UI.label(str(val), 13, UI.GOOD))
		r.add_child(UI.label(String(at[2]), 11, UI.TEXT_DIM))
	v.add_child(UI.label("The attributes stay as they were set at the start; the looks can be changed at an Image Studio.", 11, UI.TEXT_DIM))
	# the statistics
	var st: Dictionary = GameState.stats
	var ships_total := 0
	for f in GameState.fleet:
		ships_total += GameState.ship_value(f)
	var cards := UI.hbox(12)
	body.add_child(cards)
	_stat_card(cards, "FINANCES", [
		["Credits", GameData.fmt_credits(GameState.credits)],
		["Net worth", GameData.fmt_credits(GameState.net_worth())],
		["Ships owned", "%d  (%s)" % [GameState.fleet.size(), GameData.fmt_credits(ships_total)]],
		["Stored modules", GameData.fmt_credits(GameState.storage_value())],
		["Credits earned", GameData.fmt_credits(int(st.get("earned", 0)))],
		["Traded at markets", GameData.fmt_credits(int(GameState.metric("turnover")))],
		["Markets traded at", _n(GameState.metric("markets"))],
	])
	_stat_card(cards, "FLIGHT & COMBAT", [
		["Play time", SaveGame.fmt_time(GameState.play_time)],
		["Warps", _n(GameState.metric("warps"))],
		["Hyperspace jumps", _n(GameState.metric("jumps"))],
		["Systems visited", _n(GameState.metric("systems"))],
		["Pirates destroyed", _n(GameState.metric("kills"))],
		["Bounties redeemed", _n(GameState.metric("bounties"))],
		["Damage taken", _n(GameState.metric("damage_taken"))],
		["Ships scanned", _n(GameState.metric("scans"))],
	])
	_stat_card(cards, "WORK", [
		["Ore mined", _n(GameState.metric("mined"))],
		["Ore refined", _n(float(st.get("refined", 0)))],
		["… of it at stations", _n(GameState.metric("refined_station"))],
		["Modules built", _n(GameState.metric("built"))],
		["Anomalies analysed", _n(GameState.metric("analysed"))],
		["Exotic matter", _n(GameState.metric("exotic"))],
	])
	_stat_card(cards, "CONTRACTS", [
		["Completed", _n(GameState.metric("missions_done"))],
		["Bounty contracts", _n(GameState.metric("bounty_jobs"))],
		["For the Covenant", _n(GameState.metric("jobs_covenant"))],
		["For the Assembly", _n(GameState.metric("jobs_assembly"))],
		["Passengers delivered", _n(GameState.metric("passengers"))],
		["Active now", "%d / %d" % [GameState.contract_count(), GameState.MAX_ACTIVE_MISSIONS]],
	])


func _stat_card(parent: Control, title: String, rows: Array) -> void:
	var p := UI.neon_panel(Color(COL, 0.35), Color(0.05, 0.035, 0.02, 0.95), 1)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(p)
	var v := UI.vbox(3)
	p.add_child(v)
	v.add_child(UI.label(title, 14, COL))
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 14)
	v.add_child(g)
	for r in rows:
		var k := UI.label(String(r[0]), 13, UI.TEXT_DIM)
		k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g.add_child(k)
		var val := UI.label(String(r[1]), 13, Color(0.95, 0.93, 0.85))
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		g.add_child(val)


func _n(x: float) -> String:
	return GameData.fmt_credits(int(x)).trim_suffix(" cr") if absf(x) >= 1000.0 else str(int(x))
