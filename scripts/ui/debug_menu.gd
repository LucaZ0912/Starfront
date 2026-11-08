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
const TABS := ["Pilot", "Ship", "Items", "World", "Audio", "Character"]

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
		4: _build_audio()
		5: _build_character()


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
		mt_txt.append("%d %s" % [by_type[mt], Universe.MOON_TYPES[mt]["name"]])
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
	var f := GameState.active()
	var where := "–"
	if f != null:
		where = "%s (#%d)  pos %.0f / %.0f km" % [Universe.systems[f.system_id]["name"], f.system_id, f.position.x, f.position.y]
	info.text = "seed %d  •  %s  •  %d FPS  •  speed ×%s" % [Universe.seed_value, where, Engine.get_frames_per_second(), str(Engine.time_scale)]
