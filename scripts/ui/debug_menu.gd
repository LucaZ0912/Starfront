class_name DebugMenu
extends CanvasLayer
## Debug menu (F12): try everything quickly, including endgame content.
## Every button sends a "debug_*" command through the command bus.
## Only available when Commands.cheats_enabled (debug builds / running from the editor).

const FactionData = preload("res://data/factions.gd")
const MakerData = preload("res://data/manufacturers.gd")
const COL := Color(0.55, 1.0, 0.35)   # terminal green
const TABS := ["Pilot", "Ship", "Items", "World"]

var panel: PanelContainer
var tab := 0
var tab_buttons: Array = []
var content: VBoxContainer
var info: Label
var _god: CheckButton


func _ready() -> void:
	layer = 45
	visible = false
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	panel = PanelContainer.new()
	var sb := UI.panel_style(Color(0.01, 0.03, 0.02, 0.94), COL)
	sb.set_border_width_all(2)
	sb.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", sb)
	panel.position = Vector2(1600 - 500, 56)
	panel.custom_minimum_size = Vector2(480, 600)
	root.add_child(panel)
	var v := UI.vbox(8)
	panel.add_child(v)
	var head := UI.hbox(8)
	v.add_child(head)
	head.add_child(UI.label("DEBUG  //  cheats", 18, COL))
	head.add_child(UI.spacer())
	head.add_child(UI.button("Close [%s]" % Keybinds.key_text("debug_menu"), close))
	var tabs := UI.hbox(4)
	v.add_child(tabs)
	for i in TABS.size():
		var idx: int = i
		var b := UI.button(TABS[i], func(): _set_tab(idx))
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(110, 30)
		tabs.add_child(b)
		tab_buttons.append(b)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 470)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	content = UI.vbox(8)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	info = UI.label("", 11, UI.TEXT_DIM)
	v.add_child(info)


func toggle() -> void:
	if visible:
		close()
	else:
		visible = true
		_set_tab(tab)


func close() -> void:
	visible = false


func _set_tab(i: int) -> void:
	tab = i
	for k in tab_buttons.size():
		tab_buttons[k].button_pressed = k == i
	UI.clear(content)
	match i:
		0: _build_pilot()
		1: _build_ship()
		2: _build_items()
		3: _build_world()


func _cmd(c: Dictionary) -> void:
	Commands.execute(c)


func _section(text: String) -> void:
	content.add_child(UI.label(text, 14, COL))


func _row() -> HBoxContainer:
	var r := UI.hbox(6)
	content.add_child(r)
	return r


func _option(items: Array, labels: Array, width: float = 260.0) -> OptionButton:
	var o := OptionButton.new()
	o.custom_minimum_size = Vector2(width, 0)
	o.focus_mode = Control.FOCUS_NONE
	for k in items.size():
		o.add_item(labels[k])
		o.set_item_metadata(k, items[k])
	return o


func _spin(min_v: float, max_v: float, value: float, step: float = 1.0) -> SpinBox:
	var s := SpinBox.new()
	s.min_value = min_v
	s.max_value = max_v
	s.step = step
	s.value = value
	s.custom_minimum_size = Vector2(100, 0)
	return s


# ---------------------------------------------------------------- Tabs

func _build_pilot() -> void:
	_section("Credits")
	var r := _row()
	for amount in [10000, 100000, 1000000, 10000000]:
		var a: int = amount
		r.add_child(UI.button("+%s" % GameData.fmt_credits(a).trim_suffix(" cr"), func(): _cmd({"type": "debug_credits", "amount": a})))
	_section("Contracts")
	var r2 := _row()
	r2.add_child(UI.button("Complete all objectives", func(): _cmd({"type": "debug_complete_missions"})))
	r2.add_child(UI.button("Reroll board here", func(): _cmd({"type": "debug_new_contracts"})))
	var rc := _row()
	rc.add_child(UI.label("Escort convoy: freighters", 12, UI.TEXT_DIM))
	var cn := _spin(1, 6, 3)
	cn.custom_minimum_size = Vector2(70, 0)
	rc.add_child(cn)
	rc.add_child(UI.label("jumps", 12, UI.TEXT_DIM))
	var cj := _spin(1, 8, 2)
	cj.custom_minimum_size = Vector2(70, 0)
	rc.add_child(cj)
	rc.add_child(UI.button("Start", func(): _cmd({"type": "debug_convoy", "freighters": int(cn.value), "jumps": int(cj.value)})))
	# Standing (package 12)
	_section("Standing with a faction")
	var fids: Array = [""]
	var flabels: Array = ["All factions"]
	for fid in FactionData.FACTIONS:
		fids.append(fid)
		flabels.append(FactionData.name_of(fid))
	var fsel := _option(fids, flabels, 220)
	var rr := _row()
	rr.add_child(fsel)
	for a2 in [-25, 25]:
		var d2: int = a2
		rr.add_child(UI.button("%+d" % d2, func(): _cmd({"type": "debug_rep", "faction": fsel.get_selected_metadata(), "amount": d2})))
	var rv := _row()
	for v2 in [-80, -40, 0, 40, 80]:
		var val: int = v2
		rv.add_child(UI.button("= %+d" % val, func(): _cmd({"type": "debug_rep", "faction": fsel.get_selected_metadata(), "value": val})))
	_section("Criminal record (powers)")
	var rw := _row()
	for pw in FactionData.POWERS:
		var pf: String = pw
		rw.add_child(UI.button("%s wanted" % FactionData.short_of(pf), func(): _cmd({"type": "debug_wanted", "faction": pf, "points": 4})))
		rw.add_child(UI.button("clear", func(): _cmd({"type": "debug_wanted", "faction": pf, "points": 0})))
	_section("Game speed")
	var r3 := _row()
	for sc in [0.5, 1.0, 2.0, 5.0, 10.0]:
		var x: float = sc
		var b := UI.button("×%s" % str(sc), func(): _cmd({"type": "debug_time_scale", "scale": x}))
		b.toggle_mode = true
		b.button_pressed = is_equal_approx(Engine.time_scale, x)
		r3.add_child(b)
	content.add_child(UI.wrap_label("Speed affects everything: flight, warp, combat, scanning, hyperspace jumps.", 12, UI.TEXT_DIM, 440))


func _build_ship() -> void:
	_section("Active ship")
	_god = CheckButton.new()
	_god.text = "God mode (no damage)"
	_god.button_pressed = Commands.god_mode
	_god.toggled.connect(func(on): _cmd({"type": "debug_god", "on": on}))
	content.add_child(_god)
	var r := _row()
	r.add_child(UI.button("Refill everything", func(): _cmd({"type": "debug_refill"})))
	r.add_child(UI.button("Empty cargo hold", func(): _cmd({"type": "debug_clear_cargo"})))
	var rp := _row()
	rp.add_child(UI.button("Citadel: launch from the platform", func(): _cmd({"type": "debug_platform_launch"})))
	rp.add_child(UI.button("Fill drone hangar", func(): _cmd({"type": "debug_fill_drones"})))
	rp.add_child(UI.button("NPC carriers launch drones", func(): _cmd({"type": "debug_npc_drones"})))
	var rx := _row()
	rx.add_child(UI.button("+10 exotic matter (Threshold)", func(): _cmd({"type": "debug_exotic", "amount": 10})))
	content.add_child(UI.wrap_label("Plays the S-ship launch of the Citadel's platform (animation only – the ship itself comes with part 5). Drones always use the small drone hatch behind it.", 12, UI.TEXT_DIM, 440))
	_section("New ship (into the hangar)")
	var ids: Array = GameData.hulls.keys()
	var labels: Array = []
	for hid in ids:
		var h: Dictionary = GameData.hulls[hid]
		labels.append("%s – %s (%s)" % [h["name"], h["class"], GameData.SIZE_NAMES[int(h["size"])]])
	var hull := _option(ids, labels, 440)
	content.add_child(hull)
	var fitted := CheckBox.new()
	fitted.text = "Standard fit"
	fitted.button_pressed = true
	var board := CheckBox.new()
	board.text = "Board immediately"
	board.button_pressed = true
	var r2 := _row()
	r2.add_child(fitted)
	r2.add_child(board)
	var give := func(): _cmd({"type": "debug_give_ship", "hull": hull.get_selected_metadata(), "fitted": fitted.button_pressed, "board": board.button_pressed})
	r2.add_child(UI.button("Give ship", give))
	content.add_child(UI.wrap_label("Goes to the hangar of the station you are docked at (otherwise the home station). The pirate hull Carrion Crow is included.", 12, UI.TEXT_DIM, 440))


func _build_items() -> void:
	_section("Module → station storage")
	var mids: Array = GameData.modules.keys().filter(func(x): return String(GameData.modules[x]["quality"]) == "C")
	mids.sort_custom(func(a, b): return String(GameData.modules[a]["slot"]) + GameData.module_name(a) < String(GameData.modules[b]["slot"]) + GameData.module_name(b))
	var mlabels: Array = []
	for mid in mids:
		mlabels.append("%s  [%s]" % [GameData.module_name(mid), GameData.SLOT_NAMES[GameData.modules[mid]["slot"]]])
	var mod := _option(mids, mlabels, 440)
	content.add_child(mod)
	var r := _row()
	var cnt := _spin(1, 50, 1)
	r.add_child(cnt)
	var give_mod := func(): _cmd({"type": "debug_give_module", "module": mod.get_selected_metadata(), "count": int(cnt.value)})
	r.add_child(UI.button("Give module", give_mod))
	var give_all := func():
		for m in mids:
			_cmd({"type": "debug_give_module", "module": m, "count": 1})
	r.add_child(UI.button("One of every module", give_all))
	_section("Commodity → cargo hold")
	var cids: Array = GameData.commodities.keys()
	var clabels: Array = []
	for cid in cids:
		clabels.append(GameData.item_name(cid))
	var com := _option(cids, clabels, 440)
	content.add_child(com)
	var r2 := _row()
	var amt := _spin(1, 10000, 50)
	r2.add_child(amt)
	var give_com := func(): _cmd({"type": "debug_give_cargo", "item": com.get_selected_metadata(), "amount": amt.value})
	r2.add_child(UI.button("Give commodity", give_com))
	content.add_child(UI.wrap_label("Commodities respect cargo space – give yourself a Mule for big loads (Ship tab).", 12, UI.TEXT_DIM, 440))


func _build_world() -> void:
	_section("Teleport (docks at the first station)")
	var sys_ids: Array = []
	for s in Universe.systems:
		sys_ids.append(int(s["id"]))
	sys_ids.sort_custom(func(a, b): return String(Universe.systems[a]["name"]) < String(Universe.systems[b]["name"]))
	var sys_labels: Array = []
	for sid in sys_ids:
		var sd: Dictionary = Universe.systems[sid]
		sys_labels.append("%s  (sec %.1f)%s" % [sd["name"], float(sd["security"]), "  ★ home" if sid == Universe.home_system else ""])
	var sys := _option(sys_ids, sys_labels, 330)
	var r := _row()
	r.add_child(sys)
	r.add_child(UI.button("Teleport", func(): _cmd({"type": "debug_teleport", "system": sys.get_selected_metadata()})))
	_section("This system")
	var r2 := _row()
	r2.add_child(UI.button("Reveal anomalies", func(): _cmd({"type": "debug_reveal_anomalies"})))
	r2.add_child(UI.button("Destroy all pirates", func(): _cmd({"type": "debug_kill_hostiles"})))
	r2.add_child(UI.button("Summon notorious pirate", func(): _cmd({"type": "debug_notorious"})))
	_section("Station raid (5-star notorious pirate)")
	var rr := _row()
	rr.add_child(UI.button("Raid in 5 min (announced)", func(): _cmd({"type": "debug_raid", "warning": 300.0})))
	rr.add_child(UI.button("Raid now", func(): _cmd({"type": "debug_raid", "warning": 0.0})))
	_section("Spawn pirates next to you")
	var pids: Array = []
	for pid in GameData.presets:
		if String(pid).begins_with("pirate_"):
			pids.append(pid)
	var plabels: Array = []
	for pid in pids:
		var pp: Dictionary = GameData.presets[pid]
		plabels.append("%s (%s)" % ["DEBUG drone carrier" if pp.get("debug_only", false) else String(pp.get("archetype", "pirate")).capitalize(), GameData.hulls[pp["hull"]]["name"]])
	var pre := _option(pids, plabels, 220)
	var r3 := _row()
	r3.add_child(pre)
	var n := _spin(1, 20, 1)
	r3.add_child(n)
	var gids: Array = [""]
	var glabels: Array = ["Faction: from system"]
	for fid in FactionData.FACTIONS:
		gids.append(fid)
		glabels.append(FactionData.name_of(fid) + ("" if FactionData.FACTIONS[fid]["kind"] == "pirate" else " (neutral)"))
	var gsel := _option(gids, glabels, 220)
	r3.add_child(UI.button("Spawn", func(): _cmd({"type": "debug_spawn", "preset": pre.get_selected_metadata(), "count": int(n.value), "gov": gsel.get_selected_metadata()})))
	var r4 := _row()
	r4.add_child(gsel)
	content.add_child(UI.wrap_label("Government factions spawn neutral ships in their paint (patrol AI comes with package 11).", 12, UI.TEXT_DIM, 440))
	# package 25d: any loadout as a sparring partner (e.g. a Hadrian ship to test the reflective hull)
	_section("Spawn any ship next to you")
	var aids: Array = GameData.presets.keys()
	aids.sort()
	var alabels: Array = []
	for aid in aids:
		var hh: Dictionary = GameData.hulls[GameData.presets[aid]["hull"]]
		alabels.append("%s – %s (%s)" % [aid, hh["name"], MakerData.MAKERS.get(String(hh.get("maker", "")), {}).get("tag", "PIR")])
	var anyp := _option(aids, alabels, 440)
	content.add_child(anyp)
	var r5 := _row()
	var hostile := CheckBox.new()
	hostile.text = "Hostile (pirate)"
	hostile.button_pressed = true
	r5.add_child(hostile)
	var an := _spin(1, 10, 1)
	r5.add_child(an)
	r5.add_child(UI.button("Spawn", func(): _cmd({"type": "debug_spawn", "preset": anyp.get_selected_metadata(), "count": int(an.value),
		"gov": "", "side": "pirate" if hostile.button_pressed else "neutral"})))
	content.add_child(UI.wrap_label("Neutral ships just fly about; hostile ones attack you. Hadrian ships reflect part of the damage to their armour.", 12, UI.TEXT_DIM, 440))


func _process(_delta: float) -> void:
	if not visible:
		return
	var f := GameState.active()
	var where := "–"
	if f != null:
		where = "%s (#%d)  pos %.0f / %.0f km" % [Universe.systems[f.system_id]["name"], f.system_id, f.position.x, f.position.y]
	info.text = "seed %d  •  %s  •  %d FPS  •  speed ×%s" % [Universe.seed_value, where, Engine.get_frames_per_second(), str(Engine.time_scale)]
