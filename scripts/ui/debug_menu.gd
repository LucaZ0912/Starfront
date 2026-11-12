class_name DebugMenu
extends CanvasLayer
const PilotArtX = preload("res://scripts/core/pilot_art.gd")
const PilotDataX = preload("res://data/pilot.gd")
const SkillDataX = preload("res://data/skills.gd")
const TreeDataX = preload("res://data/skilltree.gd")
## Debug menu (F12): try everything quickly, including endgame content.
## Every button sends a "debug_*" command through the command bus.
## Only available when Commands.cheats_enabled (debug builds / running from the editor).

const FactionData = preload("res://data/factions.gd")
const MakerData = preload("res://data/manufacturers.gd")
const COL := Color(0.55, 1.0, 0.35)   # terminal green
const TABS := ["Pilot", "Ship", "Items", "World", "Audio", "Character", "Ground", "Missions"]

var panel: PanelContainer
var tab := 0
var tab_buttons: Array = []
var content: VBoxContainer
var info: Label
var _god: CheckButton


func _ready() -> void:
	add_to_group("kbd_menu")              # 0.5.28.2: keyboard control
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
	panel.position = Vector2(1600 - 660, 56)             # 0.7.51.5: seven tabs
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
		b.custom_minimum_size = Vector2(84, 30)
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
		4: _build_audio()
		5: _build_character()
		6: _build_ground()
		7: _build_missions()
	_fit_panel.call_deferred()


## 0.7.51.5: the panel as wide as its widest row, kept inside the screen at the right edge.
func _fit_panel() -> void:
	panel.reset_size()
	panel.position.x = maxf(8.0, get_viewport().get_visible_rect().size.x - panel.size.x - 12.0)


## Q / E (0.5.28.2): the previous / next tab.
func menu_tab(step: int) -> void:
	_set_tab(posmod(tab + step, TABS.size()))


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
	# package 31: crew
	_section("Crew (package 31)")
	var cfree := CheckButton.new()
	cfree.text = "Ignore the required crew (undock without it)"
	cfree.button_pressed = bool(GameState.pilot.get("crew_free", false))
	cfree.toggled.connect(func(on): _cmd({"type": "debug_crew", "free": on}))
	content.add_child(cfree)
	var CD = preload("res://data/crew.gd")
	var rc := _row()
	var roles: Array = CD.hire_roles()
	var rnames: Array = roles.map(func(r): return CD.role_name(String(r)))
	var ro := _option(roles, rnames, 200)
	rc.add_child(ro)
	var qo := _option(CD.QUALITIES, CD.QUALITIES, 70)
	qo.select(2)
	rc.add_child(qo)
	var pk: Array = ["?", ""] + CD.PERKS.keys()
	var pkn: Array = ["perk: rolled", "no perk"] + CD.PERKS.keys().map(func(p): return CD.PERKS[p]["name"])
	var po := _option(pk, pkn, 200)
	rc.add_child(po)
	var rc2 := _row()
	rc2.add_child(UI.button("Into the active ship", func(): _cmd({"type": "debug_crew", "role": ro.get_selected_metadata(), "quality": qo.get_selected_metadata(), "perk": po.get_selected_metadata(), "ship": true})))
	rc2.add_child(UI.button("Into the crew quarters", func(): _cmd({"type": "debug_crew", "role": ro.get_selected_metadata(), "quality": qo.get_selected_metadata(), "perk": po.get_selected_metadata()})))
	rc2.add_child(UI.button("Fill every post", func(): _cmd({"type": "debug_crew", "fill": true, "quality": qo.get_selected_metadata(), "perk": po.get_selected_metadata()})))
	var rc3 := _row()
	rc3.add_child(UI.button("Crew aboard +250 xp", func(): _cmd({"type": "debug_crew", "xp": 250})))
	rc3.add_child(UI.button("New faces at the bar", func(): _cmd({"type": "debug_crew", "bar": true})))
	var rc4 := _row()
	rc4.add_child(UI.button("Lose the active ship (31a)", func(): _cmd({"type": "debug_lose_ship"})))
	rc4.add_child(UI.button("Pod signals fade in 10 s", func(): _cmd({"type": "debug_pods", "seconds": 10})))
	# package 33: wingmen
	_section("Wingmen (package 33)")
	var WD = preload("res://data/wingmen.gd")
	var rw := _row()
	var lo := _option(WD.LEVELS, WD.LEVELS, 70)
	lo.select(2)
	rw.add_child(lo)
	rw.add_child(UI.button("A wingman joins (30 min, free)", func(): _cmd({"type": "debug_wing", "level": lo.get_selected_metadata(), "minutes": 30})))
	rw.add_child(UI.button("End all contracts", func():
		for c in GameState.wingmen.duplicate():
			_cmd({"type": "wing_dismiss", "id": int(c["w"]["id"])})))


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
	# package 35: system scale, belts, loading
	_section("System scale & loading (package 35)")
	var mn = get_tree().current_scene
	var wu = mn.get("warmup") if mn != null else null
	content.add_child(UI.label("Last system built in %.0f ms  •  pictures made ahead: %d (last system %.0f ms, %d waiting)" % [
		float(mn.get("last_load_ms")) if mn != null and mn.get("last_load_ms") != null else 0.0,
		int(wu.made) if wu != null else 0, float(wu.last_ms) if wu != null else 0.0, int(wu.pending()) if wu != null else 0], 12, UI.TEXT_DIM))
	var rb := _row()
	rb.add_child(UI.button("Into the asteroid belt", func(): _cmd({"type": "debug_belt", "kind": "asteroid"})))
	rb.add_child(UI.button("Into the Kuiper belt", func(): _cmd({"type": "debug_belt", "kind": "kuiper"})))
	# package 36: moons and orbits
	_section("Moons & orbits (package 36)")
	var L36 := Universe.get_layout(GameState.current_system)
	var by_type := {}
	for m in L36.get("moons", []):
		by_type[m["type"]] = int(by_type.get(m["type"], 0)) + 1
	var mt_txt: Array = []
	for mt in by_type:
		mt_txt.append("%d %s" % [by_type[mt], Universe.body_type(String(mt))["name"]])     # 0.6.39.7: Vesper is a desert world
	var at_moon := 0
	for st in L36["stations"]:
		at_moon += 1 if String(st.get("anchor", "")).begins_with("m") else 0
	content.add_child(UI.label("This system: %d moons (%s) • %d stations at moons • %d moon fields" % [L36.get("moons", []).size(),
		", ".join(mt_txt) if not mt_txt.is_empty() else "none", at_moon, L36["fields"].filter(func(f): return f.has("moon")).size()], 12, UI.TEXT_DIM))
	var rm := _row()
	rm.add_child(UI.button("To the next moon", func(): _cmd({"type": "debug_moon"})))
	for mt in Universe.MOON_TYPES:
		var mtk: String = mt
		rm.add_child(UI.button(String(Universe.MOON_TYPES[mt]["name"]), func(): _cmd({"type": "debug_moon", "moon_type": mtk})))
	var ro := _row()
	ro.add_child(UI.button("Roll the orbits (as on arrival)", func(): _cmd({"type": "debug_roll_orbits"})))
	# package 39a: Landfall, the Senate, entry permits
	_section("Landfall & the Senate (package 39a)")
	var lf39 := Universe.special_system("landfall")
	var sen39 = GameState.senate
	content.add_child(UI.label("Landfall: %s  •  permit: %s  •  bill: %s  •  laws: %d" % [
		"system %d" % lf39 if lf39 >= 0 else "none", "yes" if GameState.has_permit("assembly") else "no",
		String(sen39.BILLS[sen39.bill["id"]]["name"]) if not sen39.bill.is_empty() else "none", sen39.laws.size()], 12, UI.TEXT_DIM))
	var r39 := _row()
	r39.add_child(UI.button("To Landfall", func(): _cmd({"type": "debug_landfall"})))
	r39.add_child(UI.button("Give permit", func(): _cmd({"type": "debug_permit", "on": true})))
	r39.add_child(UI.button("Take permit", func(): _cmd({"type": "debug_permit", "on": false})))
	r39.add_child(UI.button("Ballot drone", func(): _cmd({"type": "debug_vote_beam"})))
	var r39b := _row()
	r39b.add_child(UI.button("New bill", func(): _cmd({"type": "debug_senate", "do": "new"})))
	r39b.add_child(UI.button("Vote now", func(): _cmd({"type": "debug_senate", "do": "resolve"})))
	r39b.add_child(UI.button("Vote now – bribe found out", func(): _cmd({"type": "debug_senate", "do": "caught"})))
	r39b.add_child(UI.button("Vote now – bribe works", func(): _cmd({"type": "debug_senate", "do": "clean"})))
	# package 40: the new cluster
	_section("The new cluster (package 40)")
	var r40 := _row()
	for p40 in [["rim", "To the Rim"], ["far", "To the Far Reaches"], ["veil", "To the Veil's edge"], ["fortress", "To a pirate fortress"]]:
		var k40: String = p40[0]
		r40.add_child(UI.button(p40[1], func(): _cmd({"type": "debug_p40", "to": k40})))
	var r40b := _row()
	for p40b in [["battlefield", "Old battlefield"], ["derelict", "Pre-Severance derelict"], ["radiation", "Radiation zone"], ["ion_storm", "Ion storm"], ["minefield", "Old minefield"]]:
		var k40b: String = p40b[0]
		r40b.add_child(UI.button(p40b[1], func(): _cmd({"type": "debug_p40", "to": k40b})))
	var r40c := _row()
	r40c.add_child(UI.button("Next jump misjumps", func(): _cmd({"type": "debug_misjump"})))
	r40c.add_child(UI.button("Break the fortress here", func(): _cmd({"type": "debug_fortress", "do": "break"})))
	r40c.add_child(UI.button("Rebuild it", func(): _cmd({"type": "debug_fortress", "do": "rebuild"})))
	r40c.add_child(UI.button("Hazard wards (A) → storage", func():
		for mid40 in ["o_rad_ward:1:A", "o_ion_ward:1:A"]:
			_cmd({"type": "debug_give_module", "module": mid40})))
	r40c.add_child(UI.button("+5 Pre-Severance Tech", func(): _cmd({"type": "debug_give_cargo", "item": "old_tech", "amount": 5})))
	# package 42: Wirtschaft 2.0
	_section("Economy (package 42)")
	var r42 := _row()
	r42.add_child(UI.button("Economy here → log", func(): _cmd({"type": "debug_economy"})))
	r42.add_child(UI.button("Prosperity +20", func(): _cmd({"type": "debug_prosperity", "delta": 20})))
	r42.add_child(UI.button("Prosperity −20", func(): _cmd({"type": "debug_prosperity", "delta": -20})))
	r42.add_child(UI.button("Prosperity drift 1 h", func(): _cmd({"type": "debug_prosperity_drift", "hours": 1})))
	r42.add_child(UI.button("To a metal world", func(): _cmd({"type": "debug_economy_system", "economy": "metal"})))
	r42.add_child(UI.button("To a resort (43)", func(): _cmd({"type": "debug_economy_system", "economy": "resort"})))
	r42.add_child(UI.button("Round trips: sight seen", func(): _cmd({"type": "debug_tour_view"})))
	r42.add_child(UI.button("Cruise liner + sightseers", func(): _cmd({"type": "debug_tourists"})))
	r42.add_child(UI.button("Markets: +1 h", func(): _cmd({"type": "debug_market_age", "hours": 1})))
	r42.add_child(UI.button("+20 luxury goods", func(): _cmd({"type": "debug_give_cargo", "item": "luxury_goods", "amount": 20})))
	var r42b := _row()
	for e42 in Economy.ORDER:
		var e42s: String = e42
		r42b.add_child(UI.button(Economy.name_of(e42s), func(): _cmd({"type": "debug_economy_system", "economy": e42s})))
	# package 41: the mining expansion
	_section("Mining expansion (package 41)")
	var r41 := _row()
	r41.add_child(UI.button("Into a gas giant's band", func(): _cmd({"type": "debug_gas_giant"})))
	r41.add_child(UI.button("Gas collector, deep drill, tanks, shielded racks → storage", func():
		for mid41 in ["t_gas:2:C", "t_deepdrill:2:C", "o_gastank:3:C", "o_shielded:3:C"]:
			_cmd({"type": "debug_give_module", "module": mid41})))
	var r41b := _row()
	r41b.add_child(UI.button("+10 Uraninite (radioactive)", func(): _cmd({"type": "debug_give_cargo", "item": "uraninite", "amount": 10})))
	r41b.add_child(UI.button("+ materials for components", func():
		for it41 in ["copper", "silicon", "lithium", "aluminium", "tungsten", "iron_ingot", "graphite"]:
			_cmd({"type": "debug_give_cargo", "item": it41, "amount": 6})))
	r41b.add_child(UI.button("Kujira → hangar", func(): _cmd({"type": "debug_give_ship", "hull": "kujira", "fitted": true, "board": false})))
	# package 39d: the manufacturers' systems
	_section("Manufacturers' systems (package 39d)")
	var r39e := _row()
	for mk in Universe.MAKER_SYSTEMS:
		var spk: String = Universe.MAKER_SYSTEMS[mk]
		var sid39: int = Universe.special_system(spk)
		var b39 := UI.button("To %s (%s%s)" % [Universe.SPECIAL_NAMES[spk], String(MakerData.MAKERS[mk]["tag"]), ", independent" if Universe.is_independent(sid39) else ""], func(): _cmd({"type": "debug_special", "special": spk}))
		b39.disabled = sid39 < 0
		r39e.add_child(b39)
	# package 39c: Durchbruch and the Research Exchange
	_section("Durchbruch & the Research Exchange (package 39c)")
	content.add_child(UI.label("Durchbruch: %s  •  permit: %s  •  research data: %d  •  exotic matter: %d" % [
		"system %d" % Universe.special_system("durchbruch") if Universe.special_system("durchbruch") >= 0 else "none",
		"yes" if GameState.has_permit("directorate") else "no", GameState.research_data, GameState.exotic_matter], 12, UI.TEXT_DIM))
	var r39d := _row()
	r39d.add_child(UI.button("To Durchbruch", func(): _cmd({"type": "debug_durchbruch"})))
	r39d.add_child(UI.button("Give permit", func(): _cmd({"type": "debug_permit", "faction": "directorate", "on": true})))
	r39d.add_child(UI.button("Take permit", func(): _cmd({"type": "debug_permit", "faction": "directorate", "on": false})))
	r39d.add_child(UI.button("+5 research data", func(): _cmd({"type": "debug_research", "n": 5})))
	# package 39b: Heimkehr and the Curia
	_section("Heimkehr & the Curia (package 39b)")
	var cu39 = GameState.curia
	content.add_child(UI.label("Heimkehr: %s  •  permit: %s  •  edict: %s  •  blessed: %s" % [
		"system %d" % Universe.special_system("heimkehr") if Universe.special_system("heimkehr") >= 0 else "none",
		"yes" if GameState.has_permit("covenant") else "no",
		String(cu39.EDICTS[cu39.edict["id"]]["name"]) if not cu39.edict.is_empty() else "none", "yes" if cu39.blessed() else "no"], 12, UI.TEXT_DIM))
	var r39c := _row()
	r39c.add_child(UI.button("To Heimkehr", func(): _cmd({"type": "debug_heimkehr"})))
	r39c.add_child(UI.button("Give permit", func(): _cmd({"type": "debug_permit", "faction": "covenant", "on": true})))
	r39c.add_child(UI.button("Take permit", func(): _cmd({"type": "debug_permit", "faction": "covenant", "on": false})))
	r39c.add_child(UI.button("New edict", func(): _cmd({"type": "debug_edict"})))
	r39c.add_child(UI.button("+3 relics", func(): _cmd({"type": "debug_relic", "n": 3})))
	# package 38: planet types
	_section("Planets (package 38)")
	var L38 := Universe.get_layout(GameState.current_system)
	var here: Array = []
	for p38 in L38["planets"]:
		here.append(String(Universe.PLANET_TYPES[String(p38["type"])]["name"]))
	content.add_child(UI.label("This system: %s  •  the test system shows every type in a row" % ", ".join(here), 12, UI.TEXT_DIM))
	var rp1 := _row()
	var rp2 := _row()
	var pi38 := 0
	for pt38 in Universe.PLANET_TYPES:
		var ptk: String = pt38
		(rp1 if pi38 < 6 else rp2).add_child(UI.button(String(Universe.PLANET_TYPES[pt38]["name"]), func(): _cmd({"type": "debug_planet", "planet_type": ptk})))
		pi38 += 1
	# package 37: star types
	_section("Stars (package 37)")
	var st_counts := {}
	for s37 in Universe.systems:
		var tid := String(Universe.STAR_TYPES[int(s37["star"])]["id"])
		st_counts[tid] = int(st_counts.get(tid, 0)) + 1
	var parts: Array = []
	for t37 in Universe.STAR_TYPES:
		parts.append("%s %d" % [t37["id"], int(st_counts.get(String(t37["id"]), 0))])
	content.add_child(UI.label("This system: %s  •  Cluster: %s" % [Universe.star_type(GameState.current_system)["name"], "  ".join(parts)], 12, UI.TEXT_DIM))
	var rs1 := _row()
	var rs2 := _row()
	var si := 0
	for t38 in Universe.STAR_TYPES:
		var tid2 := String(t38["id"])
		(rs1 if si < 6 else rs2).add_child(UI.button(tid2, func(): _cmd({"type": "debug_star", "star": tid2}), String(t38["name"])))
		si += 1
	rs2.add_child(UI.button("Coronal mass ejection (10 s countdown)", func(): _cmd({"type": "debug_cme"})))
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


# ---------------------------------------------------------------- Package 28: the pilot

const CharacterCreatorScript = preload("res://scripts/ui/character_creator.gd")


## Open the character creation at any time, a random pilot, attributes set freely (also beyond the limits).
func _build_character() -> void:
	_section("Pilot: %s" % GameState.pilot_title())
	var r := _row()
	r.add_child(UI.button("Open character creation", _open_creator))
	r.add_child(UI.button("Random pilot", func():
		_cmd({"type": "debug_pilot", "random": true})
		_set_tab(5)))
	_section("Attributes (free – 1 to 20, beyond the starting limits)")
	var spins := {}
	for at in PilotDataX.ATTRS:
		var r2 := _row()
		var l := UI.label(String(at[1]), 12)
		l.custom_minimum_size = Vector2(110, 0)
		r2.add_child(l)
		var sp := _spin(1, 20, GameState.pilot_attr(String(at[0])))
		r2.add_child(sp)
		spins[at[0]] = sp
	content.add_child(UI.button("Set attributes", func():
		var a := {}
		for id in spins:
			a[id] = int(spins[id].value)
		_cmd({"type": "debug_pilot", "attrs": a})
		_set_tab(5)))
	# package 29: skills – a level or experience; the bonuses at work, with and without the skills
	_section("Skills (set a level / add experience)")
	for s in SkillDataX.SKILLS:
		var sid: String = s[0]
		var r3 := _row()
		var l3 := UI.label("%s  L%d" % [String(s[1]), GameState.skill_level(sid)], 12)
		l3.custom_minimum_size = Vector2(190, 0)
		r3.add_child(l3)
		var lv := _spin(0, SkillDataX.MAX_LEVEL, GameState.skill_level(sid))
		r3.add_child(lv)
		r3.add_child(UI.button("Set", func():
			_cmd({"type": "debug_skill", "skill": sid, "level": int(lv.value)})
			_set_tab(5)))
		r3.add_child(UI.button("+100 XP", func():
			_cmd({"type": "debug_skill", "skill": sid, "xp": 100.0})
			_set_tab(5)))
	# package 30: the skill tree and perks
	_section("Skill tree & perks")
	var all_cb := CheckButton.new()
	all_cb.text = "Unlock everything (all tiles and blueprints)"
	all_cb.button_pressed = bool(GameState.pilot.get("tree_all", false))
	all_cb.toggled.connect(func(on): _cmd({"type": "debug_tree", "all": on}))
	content.add_child(all_cb)
	var rt := _row()
	var tids: Array = TreeDataX.TILES.keys()
	var tnames: Array = []
	for t in tids:
		tnames.append("%s (%s)" % [TreeDataX.TILES[t]["name"], TreeDataX.TILES[t]["branch"]])
	var topt := _option(tids, tnames, 280)
	rt.add_child(topt)
	rt.add_child(UI.button("Open tile", func():
		_cmd({"type": "debug_tree", "tile": topt.get_selected_metadata()})
		_set_tab(5)))
	rt.add_child(UI.button("Reset tree", func():
		_cmd({"type": "debug_tree", "reset": true})
		_set_tab(5)))
	var rp := _row()
	rp.add_child(UI.label("Perk points: %d" % int(GameState.pilot.get("perk_points", 0)), 12))
	rp.add_child(UI.button("+1", func():
		_cmd({"type": "debug_tree", "perk_points": 1})
		_set_tab(5)))
	rp.add_child(UI.button("+5", func():
		_cmd({"type": "debug_tree", "perk_points": 5})
		_set_tab(5)))
	var f := GameState.active()
	if f != null:
		_section("Bonuses at work on %s (without → with skills)" % f.ship_name)
		var plain := ShipFitting.from_dict(f.to_dict())
		plain.faction = "civilian"
		plain.mark_dirty()
		var a0: Dictionary = plain.stats()
		var a1: Dictionary = f.stats()
		for k in [["Speed", "speed"], ["Power output", "power_output"], ["DPS", "dps_total"], ["Warp speed", "warp_speed"], ["Fuel per jump", "jump_fuel"], ["Shield downtime", "shield_downtime"]]:
			if a1.has(k[1]):
				content.add_child(UI.label("%s: %.1f → %.1f" % [k[0], float(a0.get(k[1], 0.0)), float(a1[k[1]])], 12, UI.TEXT_DIM))
		content.add_child(UI.label("Prices: buy −%.1f %%, sell +%.1f %%  •  contract rewards +%d %%  •  mining +%d %%  •  target locks −%d %%" % [
			GameState.skill_bonus("trading") * 50.0, GameState.skill_bonus("trading") * 50.0, GameState.skill_level("negotiation"), GameState.skill_level("mining"), GameState.skill_level("gunnery")], 12, UI.TEXT_DIM))


func _open_creator() -> void:
	var cc = CharacterCreatorScript.new()
	cc.setup("debug", GameState.pilot.get("look", {}), GameState.pilot.get("attrs", {}), GameState.pilot_name)
	cc.callsign = String(GameState.pilot.get("callsign", ""))
	cc.set_anchors_preset(Control.PRESET_CENTER)
	cc.add_to_group("kbd_menu")
	get_parent().add_child(cc)
	cc.position = (get_viewport().get_visible_rect().size - Vector2(1080, 640)) * 0.5
	cc.cancelled.connect(cc.queue_free)
	cc.done.connect(func(d: Dictionary):
		_cmd({"type": "debug_pilot", "name": d["name"], "callsign": d["callsign"], "look": d["look"], "attrs": d["attrs"]})
		cc.queue_free()
		_set_tab(5))
	close()


# ---------------------------------------------------------------- Package 28a: audio

var _meters := {}
var _audio_log: Label


## Every sound to play by itself, the level of each channel live, and which event played which sound.
func _build_audio() -> void:
	_section("Channels (live level)")
	_meters.clear()
	for bus in ["Master", "Music", "Ambience", "SFX", "UI"]:
		var r := _row()
		var l := UI.label(bus, 12)
		l.custom_minimum_size = Vector2(80, 0)
		r.add_child(l)
		var bar := UI.bar(COL, 280)
		bar.min_value = -60.0
		bar.max_value = 0.0
		r.add_child(bar)
		_meters[bus] = bar
	_section("Sounds (click to play)")
	var flow := HFlowContainer.new()
	flow.custom_minimum_size = Vector2(440, 0)
	flow.add_theme_constant_override("h_separation", 4)
	flow.add_theme_constant_override("v_separation", 4)
	content.add_child(flow)
	for id in Audio.ids():
		var sid: String = id
		flow.add_child(UI.button(sid, func(): Audio.play(sid, "debug")))
	content.add_child(UI.button("Stop all loops", func(): Audio.stop_all_loops()))
	_section("Event log (newest first)")
	_audio_log = UI.label("", 11, UI.TEXT_DIM)
	content.add_child(_audio_log)


func _update_audio_debug() -> void:
	if tab != 4 or _audio_log == null or not is_instance_valid(_audio_log):
		return
	for bus in _meters:
		_meters[bus].value = clampf(Audio.level_db(bus), -60.0, 0.0)
	var lines: Array = []
	var now := Time.get_ticks_msec() / 1000.0
	for k in range(Audio.events.size() - 1, maxi(Audio.events.size() - 16, 0) - 1, -1):
		var e: Dictionary = Audio.events[k]
		lines.append("%5.1f s ago   %-24s → %s  (%s)" % [now - float(e["t"]), String(e["event"]), String(e["id"]), String(e["bus"])])
	_audio_log.text = "\n".join(PackedStringArray(lines)) if not lines.is_empty() else "nothing played yet"


func _process(_delta: float) -> void:
	if not visible:
		return
	_update_audio_debug()
	_update_ground_status()
	var f := GameState.active()
	var where := "–"
	if f != null:
		where = "%s (#%d)  pos %.0f / %.0f km" % [Universe.systems[f.system_id]["name"], f.system_id, f.position.x, f.position.y]
	info.text = "seed %d  •  %s  •  %d FPS  •  speed ×%s" % [Universe.seed_value, where, Engine.get_frames_per_second(), str(Engine.time_scale)]


# ---------------------------------------------------------------- 0.7.51.5: packages 49–51 – on foot, landing, gear

const GroundGear = preload("res://data/gear.gd")
const FoeData52 = preload("res://data/foes.gd")
const PHASES := [["day", "Day"], ["dusk", "Dusk"], ["night", "Night"], ["dawn", "Dawn"]]
var _ground_status: Label


## Every world type you can land on: [ids, names].
func _world_types(first: String) -> Array:
	var ids: Array = [""]
	var names: Array = [first]
	for t in Universe.PLANET_TYPES:
		if Universe.landable({"type": t}):
			ids.append(t)
			names.append(String(Universe.PLANET_TYPES[t]["name"]))
	for t2 in Universe.MOON_TYPES:
		ids.append(t2)
		names.append(String(Universe.MOON_TYPES[t2]["name"]))
	return [ids, names]


## Decks, landing, cities and settlements, the suit and the world outside, the clinic.
## 0.7.53.19 (Luz): a button for every mission – the jobs on foot (each heist and spy variant) and the space contracts;
## accepted at once from the docked (or nearest) station.
const GROUND_JOBS := [["relic", "", "Relic race (ruin)"], ["salvage", "", "Salvage (crash site)"], ["bounty_foot", "", "Bounty on foot (pirate base)"],
	["heist", "pirate", "Heist – pirate base"], ["heist", "sewer", "Heist – the dealer's safe (city)"], ["heist", "corp", "Heist – corporate vault (city)"],
	["spy", "", "Espionage – a site"], ["spy", "corp", "Espionage – corporate tower (city)"], ["reactivate", "", "Reactivation (city tunnels)"],
	["rescue", "pirate", "Rescue (pirate base)"], ["rescue", "research", "Rescue (research station)"], ["recover", "", "Data recovery (research station)"], ["investigate", "debug", "Strange happenings (Dark Ones ruin)"]]
const SPACE_JOBS := [["courier", "Courier"], ["bounty", "Bounty"], ["mining", "Supply"], ["survey", "Survey"], ["escort", "Escort"],
	["patrol", "Patrol"], ["smuggler", "Intercept"], ["hunt", "Hunt"], ["drone_trial", "Drone trial"], ["passenger", "Passengers"]]


func _build_missions() -> void:
	_section("Jobs on foot (packages 53c, 53d)")
	content.add_child(UI.wrap_label("Accept: the job is yours – the site goes on the planet map (in a city: the way in from the city). Accept & go: straight down onto the site (not for city jobs).", 12, UI.TEXT_DIM, 560))
	for gj in GROUND_JOBS:
		var r := _row()
		var goal: String = gj[0]
		var variant: String = gj[1]
		var lab := UI.label(String(gj[2]), 13, Color(0.9, 0.95, 1.0))
		lab.custom_minimum_size = Vector2(300, 0)
		r.add_child(lab)
		r.add_child(UI.button("Accept", func(): _job(goal, variant, false)))
		if not (variant in ["sewer", "corp"] or goal == "reactivate"):
			r.add_child(UI.button("Accept & go", func(): _job(goal, variant, true)))
	_section("Space contracts")
	var row: HBoxContainer = null
	for k in SPACE_JOBS.size():
		if k % 5 == 0:
			row = _row()
		var kind: String = SPACE_JOBS[k][0]
		row.add_child(UI.button(String(SPACE_JOBS[k][1]), func(): _space_job(kind)))
	_section("All")
	var ra := _row()
	ra.add_child(UI.button("Complete all missions", func(): _cmd({"type": "debug_complete_missions"})))
	ra.add_child(UI.button("New contracts on the board", func(): _cmd({"type": "debug_new_contracts"})))
	_mission_note = UI.label("", 12, UI.TEXT_DIM)
	content.add_child(_mission_note)


var _mission_note: Label = null


func _job(goal: String, variant: String, go: bool) -> void:
	var e := Commands.execute({"type": "debug_ground_job", "goal": goal, "variant": variant, "go": go})
	_note(e, "Accepted: %s" % (String(GameState.missions[-1]["title"]) if not GameState.missions.is_empty() else goal))
	if go and e == "":
		toggle()


func _space_job(kind: String) -> void:
	var e := Commands.execute({"type": "debug_mission", "kind": kind})
	_note(e, "Accepted: %s" % (String(GameState.missions[-1]["title"]) if not GameState.missions.is_empty() else kind))


func _note(e: String, ok: String) -> void:
	if _mission_note != null and is_instance_valid(_mission_note):
		_mission_note.text = e if e != "" else ok
		_mission_note.add_theme_color_override("font_color", UI.BAD if e != "" else UI.GOOD)


func _build_ground() -> void:
	_ground_status = UI.label("", 12, UI.TEXT_DIM)
	content.add_child(_ground_status)
	_update_ground_status()
	# package 49: on foot
	_section("On foot – decks and levels (packages 49, 50)")
	var r49 := _row()
	r49.add_child(UI.button("Open the deck here", func(): _cmd({"type": "debug_deck"})))
	for lv in [["hangar", "Hangar"], ["commercial", "Commercial"], ["street", "Street"], ["tower", "Tower bar"], ["clinic", "Clinic"]]:
		var lvk: String = lv[0]
		r49.add_child(UI.button(String(lv[1]), func(): _cmd({"type": "debug_ground_level", "level": lvk})))
	content.add_child(UI.wrap_label("The deck of the station you are docked at (in a city: its hangar). Levels: a station has hangar and commercial level, a city hangar, shopping street and tower bar.", 12, UI.TEXT_DIM, 560))
	# package 50: landing
	_section("Landing, cities, settlements (package 50)")
	var L := Universe.get_layout(GameState.current_system)
	var bids: Array = []
	var bnames: Array = []
	for b in L["planets"] + L.get("moons", []):
		if Universe.landable(b):
			bids.append(String(b["id"]))
			var sites: Array = Universe.landing_sites(GameState.current_system, b)
			bnames.append("%s – %s (cities %d, other places %d)" % [String(b["name"]), String(Universe.body_type(String(b["type"]))["name"]),
				sites.filter(func(x): return String(x["kind"]) == "city").size(), sites.filter(func(x): return String(x["kind"]) != "city").size()])
	if bids.is_empty():
		content.add_child(UI.label("Nothing to land on in this system.", 12, UI.TEXT_DIM))
	var body := _option(bids, bnames, 440)
	var rb := _row()
	rb.add_child(body)
	rb.add_child(UI.button("Descend", func(): _cmd({"type": "debug_descend", "body": body.get_selected_metadata()})))
	var kinds := _option(["city", "outpost", "mine", "research", "field"], ["City", "Outpost", "Mine", "Research camp", "Landing field"], 120)
	var wt: Array = _world_types("World: its own")
	var world := _option(wt[0], wt[1], 140)
	var ecos: Array = [""] + SettleGen.SPECIAL.keys()
	var econames: Array = ["Economy: its own"]
	for e in SettleGen.SPECIAL:
		econames.append(Economy.name_of(String(e)) if Economy.ORDER.has(e) else String(e).capitalize())
	var eco := _option(ecos, econames, 140)
	var hours := _option(["", "day", "dusk", "night", "dawn"], ["Hour: now", "Day", "Dusk", "Night", "Dawn"], 110)
	var rl := _row()
	rl.add_child(kinds)
	rl.add_child(world)
	rl.add_child(eco)
	rl.add_child(hours)
	var rl2 := _row()
	rl2.add_child(UI.button("Land there", func(): _cmd({"type": "debug_land", "body": body.get_selected_metadata() if not bids.is_empty() else "",
		"kind": kinds.get_selected_metadata(), "world": world.get_selected_metadata(), "economy": eco.get_selected_metadata(), "day": hours.get_selected_metadata()})))
	rl2.add_child(UI.label("Time of day here:", 12, UI.TEXT_DIM))
	for ph in PHASES:
		var phk: String = ph[0]
		rl2.add_child(UI.button(String(ph[1]), func(): _cmd({"type": "debug_daytime", "phase": phk})))
	content.add_child(UI.wrap_label("Lands at once at the first place of that kind on the body – if there is none, or an economy is forced (settlements only), a debug place is added. 'World' shows the body as another world type (ground, bounds, air). The hour turns every world on until the place has it.", 12, UI.TEXT_DIM, 560))
	# package 51: gear, the world outside, the clinic
	_section("Gear, the world outside, the clinic (package 51)")
	var fams: Array = []
	var fnames: Array = []
	for t3 in [["Suit", GroundGear.SUITS], ["Weapon", GroundGear.WEAPONS], ["Belt", GroundGear.BELT], ["Feature", GroundGear.FEATURES]]:
		for fam in (t3[1] as Dictionary):
			fams.append(String(fam))
			fnames.append("%s – %s" % [String(t3[0]), String(t3[1][fam]["name"])])
	var fsel := _option(fams, fnames, 300)
	var qsel := _option(GroundGear.QUALITIES, GroundGear.QUALITIES, 60)
	qsel.select(3)
	var cnt := _spin(1, 20, 1)
	cnt.custom_minimum_size = Vector2(70, 0)
	var rg := _row()
	rg.add_child(fsel)
	rg.add_child(qsel)
	rg.add_child(cnt)
	rg.add_child(UI.button("Into the pockets", func():
		var fm: String = fsel.get_selected_metadata()
		var gid: String = fm + ":" + String(qsel.get_selected_metadata()) if GroundGear.has_quality(fm) else fm
		_cmd({"type": "debug_gear", "give": gid, "n": int(cnt.value)})))
	var rg2 := _row()
	rg2.add_child(UI.button("Fill the belt", func(): _cmd({"type": "debug_gear", "fill_belt": true})))
	rg2.add_child(UI.button("Refill the suit", func(): _cmd({"type": "debug_gear", "refill": true})))
	rg2.add_child(UI.button("Empty the pockets", func(): _cmd({"type": "debug_gear", "clear": true})))
	var rs := _row()
	var stat := _option(["health", "energy", "oxygen", "ammo"], ["Health", "Energy", "Oxygen", "Ammunition"], 130)
	rs.add_child(stat)
	var pct := _spin(0, 100, 25)
	pct.suffix = "%"
	rs.add_child(pct)
	rs.add_child(UI.button("Set", func(): _cmd({"type": "debug_gear", "set": {stat.get_selected_metadata(): pct.value}})))
	for v in [0, 10, 100]:
		var vv: int = v
		rs.add_child(UI.button("all %d %%" % vv, func(): _cmd({"type": "debug_gear", "set": {"health": maxi(vv, 1), "energy": vv, "oxygen": vv, "ammo": vv}})))
	var inv := CheckButton.new()
	inv.text = "Suit invulnerable (energy and oxygen still drain)"
	inv.button_pressed = Commands.suit_god
	inv.toggled.connect(func(on): _cmd({"type": "debug_gear", "suit_god": on}))
	content.add_child(inv)
	var et: Array = _world_types("Outside: as the place is")
	var esel := _option(et[0], et[1], 220)
	var re := _row()
	re.add_child(esel)
	re.add_child(UI.button("Force the world outside", func(): _cmd({"type": "debug_env", "world": esel.get_selected_metadata()})))
	var rc := _row()
	rc.add_child(UI.button("Collapse now", func(): _cmd({"type": "debug_collapse"})))
	rc.add_child(UI.button("Wake in the clinic here", func(): _cmd({"type": "debug_wake_clinic"})))
	content.add_child(UI.wrap_label("Collapse: on foot the body gives out – you wake in the nearest city's clinic (else the last station's), the pockets emptied. Wake in the clinic: of the station or city you are docked at.", 12, UI.TEXT_DIM, 560))
	# package 52: fights on foot
	_section("Combat on foot (package 52)")
	var at: Array = _world_types("World: the body's own")
	var aw := _option(at[0], at[1], 160)
	var ra := _row()
	ra.add_child(aw)
	ra.add_child(UI.button("Open the arena (3 bandits)", func(): _cmd({"type": "debug_arena", "world": aw.get_selected_metadata()})))
	ra.add_child(UI.button("Empty arena", func(): _cmd({"type": "debug_arena", "world": aw.get_selected_metadata(), "foes": []})))
	var ra3 := _row()                                               # 0.7.52.5: pirates, guards, a sniper
	ra3.add_child(UI.button("Arena: pirate crew", func(): _cmd({"type": "debug_arena", "world": aw.get_selected_metadata(),
		"foes": ["pirate_raider", "pirate_raider", "pirate_gunner", "pirate_grenadier", "pirate_sniper@yellow", "pirate_captain@yellow"]})))
	ra3.add_child(UI.button("Arena: guard squad", func(): _cmd({"type": "debug_arena", "world": aw.get_selected_metadata(),
		"foes": ["guard_trooper", "guard_trooper", "guard_heavy", "guard_sergeant@yellow"]})))
	ra3.add_child(UI.button("Arena: one sniper", func(): _cmd({"type": "debug_arena", "world": aw.get_selected_metadata(), "foes": ["pirate_sniper"]})))
	ra3.add_child(UI.button("Fill the grenade places", func(): _cmd({"type": "debug_gear", "grenades": true})))
	var rdr := _row()                                               # 0.7.52.11: drones
	var dq := _option(GroundGear.QUALITIES, GroundGear.QUALITIES, 60)
	dq.select(3)
	rdr.add_child(UI.label("Drone:", 12, UI.TEXT_DIM))
	rdr.add_child(dq)
	for dk in [["dr_laser", "Laser"], ["dr_kinetic", "Kinetic"], ["dr_kamikaze", "Kamikaze"]]:
		var dkk: String = dk[0]
		rdr.add_child(UI.button(String(dk[1]), func(): _cmd({"type": "debug_gear", "drone": dkk + ":" + String(dq.get_selected_metadata())})))
	rdr.add_child(UI.button("Shoot it down", func(): _cmd({"type": "debug_combat", "do": "drone_kill"})))
	rdr.add_child(UI.button("New one now", func(): _cmd({"type": "debug_combat", "do": "drone_ready"})))
	var rex := _row()                                               # 0.7.52.22: tools at work
	rex.add_child(UI.label("Explore:", 12, UI.TEXT_DIM))
	rex.add_child(UI.button("Box, terminal, tablet, relic here", func(): _cmd({"type": "debug_explore"})))
	rex.add_child(UI.button("The vault (station room)", func(): _cmd({"type": "debug_vault"})))
	var rpo := _row()                                               # package 53a: generated sites
	rpo.add_child(UI.label("Site (ruin):", 12, UI.TEXT_DIM))
	for dz in [["green", "Green"], ["yellow", "Yellow"], ["red", "Red"]]:
		var dzz: String = dz[0]
		rpo.add_child(UI.button(String(dz[1]), func(): _cmd({"type": "debug_poi", "danger": dzz})))
	rpo.add_child(UI.button("Reveal the map", func(): _cmd({"type": "debug_poi_reveal"})))
	var rsw := _row()                                               # 0.7.53.3: the sewers under a city
	rsw.add_child(UI.label("Site (sewer):", 12, UI.TEXT_DIM))
	for dz2 in [["green", "Green"], ["yellow", "Yellow"], ["red", "Red"]]:
		var dzz2: String = dz2[0]
		rsw.add_child(UI.button(String(dz2[1]), func(): _cmd({"type": "debug_poi", "danger": dzz2, "theme": "sewer"})))
	rsw.add_child(UI.button("Back alley (in a city)", func(): _cmd({"type": "debug_ground_level", "level": "alley"})))
	var rtm := _row()                                               # 0.7.52.20: the ground team
	rtm.add_child(UI.label("Team:", 12, UI.TEXT_DIM))
	rtm.add_child(UI.button("Gunner + Engineer", func(): _cmd({"type": "debug_combat", "do": "team", "roles": ["gunner", "engineer"]})))
	rtm.add_child(UI.button("Science + Quartermaster", func(): _cmd({"type": "debug_combat", "do": "team", "roles": ["science", "quartermaster"]})))
	rtm.add_child(UI.button("One down", func(): _cmd({"type": "debug_combat", "do": "team_down"})))
	rtm.add_child(UI.button("Revive", func(): _cmd({"type": "debug_combat", "do": "team_revive"})))
	rtm.add_child(UI.button("Abilities ready", func(): _cmd({"type": "debug_combat", "do": "team_ready"})))
	rtm.add_child(UI.button("Down one dies", func(): _cmd({"type": "debug_combat", "do": "team_die"})))
	var ra2 := _row()                                               # 0.7.52.4 (Luz): mixed strengths
	ra2.add_child(UI.button("Arena: 2 green + 1 yellow", func(): _cmd({"type": "debug_arena", "world": aw.get_selected_metadata(),
		"foes": ["bandit_scrapper@green", "bandit_rifleman@green", "bandit_gunner@yellow"]})))
	ra2.add_child(UI.button("Arena: 2 yellow + 1 red", func(): _cmd({"type": "debug_arena", "world": aw.get_selected_metadata(),
		"foes": ["bandit_scrapper@yellow", "bandit_rifleman@yellow", "bandit_boss@red"]})))
	var fk: Array = []
	var fn: Array = []
	for k in FoeData52.KINDS:
		fk.append(k)
		fn.append(String(FoeData52.FOES[k]["name"]))
	var fsel2 := _option(fk, fn, 200)
	var fq := _option([""] + GroundGear.QUALITIES, ["Quality: its own"] + GroundGear.QUALITIES, 130)
	var ftier := _option(FoeData52.TIER_ORDER, ["Green (easy)", "Yellow (middling)", "Red (dangerous)"], 150)
	var fcnt := _spin(1, 12, 1)
	fcnt.custom_minimum_size = Vector2(70, 0)
	var rf := _row()
	rf.add_child(fsel2)
	rf.add_child(fq)
	rf.add_child(ftier)
	rf.add_child(fcnt)
	rf.add_child(UI.button("Spawn far", func(): _cmd({"type": "debug_foe", "kind": fsel2.get_selected_metadata(), "quality": fq.get_selected_metadata(), "tier": ftier.get_selected_metadata(), "n": int(fcnt.value)})))
	rf.add_child(UI.button("Spawn near", func(): _cmd({"type": "debug_foe", "kind": fsel2.get_selected_metadata(), "quality": fq.get_selected_metadata(), "tier": ftier.get_selected_metadata(), "n": int(fcnt.value), "near": true})))
	var rk := _row()
	rk.add_child(UI.button("All foes down", func(): _cmd({"type": "debug_combat", "do": "kill"})))
	rk.add_child(UI.button("End the fight (foes gone)", func(): _cmd({"type": "debug_combat", "do": "end"})))
	rk.add_child(UI.button("Freeze / unfreeze foes", func(): _cmd({"type": "debug_combat", "do": "freeze"})))
	rk.add_child(UI.button("AI view on / off", func(): _cmd({"type": "debug_combat", "do": "ai"})))
	for tm in [[1, "Tactics: your sight"], [2, "Tactics: the target's"], [0, "Tactics off"]]:
		var tmv: int = tm[0]
		rk.add_child(UI.button(String(tm[1]), func(): _cmd({"type": "debug_combat", "do": "tactics", "mode": tmv})))
	var rh := _row()
	rh.add_child(UI.button("Hit me (30 kinetic)", func(): _cmd({"type": "debug_combat", "do": "hurt", "amount": 30.0})))
	rh.add_child(UI.button("Go down now", func(): _cmd({"type": "debug_combat", "do": "hurt", "amount": 9999.0, "dtype": "explosive"})))
	for sk in ["firearms", "athletics"]:
		var skk: String = sk
		for lv2 in [0, 5, 10]:
			var lvv: int = lv2
			rh.add_child(UI.button("%s %d" % [skk.capitalize(), lvv], func(): _cmd({"type": "debug_skill", "skill": skk, "level": lvv})))
	content.add_child(UI.wrap_label("The arena: the landing drone on its pad, a field of cover (crates, barriers and rocks to shoot over; bulwarks you cannot see through), foes at the far side. R locks the next target, a click any, Space dodges, Q swaps the weapon, Tab the tactical view (tap: yours / the target's, hold: off). AI view: low cover amber, high cover red, sight lines (green clear, amber over cover, red blocked), each foe's state, layers and both hit chances. The suit's invulnerability (above) holds off shots too.", 12, UI.TEXT_DIM, 560))


func _update_ground_status() -> void:
	if tab != 6 or _ground_status == null or not is_instance_valid(_ground_status):
		return
	var g = GameState.gear
	var t: Dictionary = g.totals()
	var m = get_tree().current_scene
	var gv = m.get("ground") if m != null else null
	var where := "aboard"
	if gv != null and is_instance_valid(gv):
		var hz: Array = []
		for h in GroundGear.HAZARDS:
			if float(gv.env.get(h, 0.0)) > 0.0:
				hz.append("%s %d%%" % [GroundGear.HAZARD_NAMES[h], int(float(gv.env[h]) * 100.0)])
		where = "on foot: %s – %s  •  outside: %s" % [String(gv.station.get("name", "?")), gv.level,
			"indoors" if gv.env.is_empty() else (("air " if bool(gv.env.get("breathable", true)) else "no air ") + ", ".join(hz))]
		if gv.is_town():
			where += "  •  daylight %d %%" % int(gv.city_day() * 100.0)
		if gv.combat != null:
			where += "  •  fight: %s, foes %d (%d aware), %d down" % ["on" if gv.combat.fight else "off", gv.combat.alive().size(),
				gv.combat.alive().filter(func(x): return x["aware"]).size(), gv.combat.kills]
	var f := GameState.active()
	_ground_status.text = "%s  •  docked: %s\nHealth %d  •  Shield %d  •  Armour %d  •  Energy %d/%d  •  Oxygen %.1f/%d min  •  Ammo %d/%d  •  %s" % [where,
		f.docked_at if f != null and f.docked_at != "" else "–", int(g.health), int(g.shield), int(g.armor), int(g.energy), int(t["energy"]), g.oxygen, int(t["oxygen"]),
		g.ammo, int(t["ammo"]), GroundGear.display_name(g.suit)]
