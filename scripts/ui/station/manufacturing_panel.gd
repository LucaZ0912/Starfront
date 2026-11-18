extends StationServicePanel
## Manufacturing (Molten Lotus Fabrication): components from refined materials and modules from materials in the
## cargo hold. What can be built depends on the station type and tier; materials the station produces itself lower
## the fabrication fee. Luz, 18 Nov 2026: everything takes time (the station's fabricators a little faster than a
## ship's factory, dearer things longer), one job after the other; modules go into station storage, components wait
## here to be collected. The window: tabs Components / Modules / In production; recipes as tiles on the left (green
## when your hold has the materials), the picked one on the right with its materials as bars, fee, time and the button.

const Kit = preload("res://scripts/ui/station/svc_kit.gd")

static var tab := "components"
static var pick_comp := ""
static var pick_mod := ""
static var family := ""


## A module's kind for the drop-down: its name without size and quality ("Fuel Tank 3 · C" → "Fuel Tank").
static func kind_of(mid: String) -> String:
	var n := GameData.module_name(mid)
	var rx := RegEx.create_from_string(" [0-9]+ · .$")
	return rx.sub(n, "").strip_edges()


func build() -> void:
	UI.clear(self)
	if no_ship():
		return
	var f := fit()
	var col := corp_color()
	var sid := String(station["id"])
	var mods: Array = Industry.buildable(station)
	var comps: Array = Industry.COMPONENTS.keys() if Industry.can_fabricate_here(station) else []
	var n_jobs: int = GameState.jobs_at(sid, "fab").size()
	var n_ready: int = GameState.jobs_ready(sid, "fab").size()
	var trow := UI.hbox(14)
	add_child(trow)
	Kit.chips(trow, [["components", "Components (%d)" % comps.size()], ["modules", "Modules (%d)" % mods.size()],
		["prod", "In production (%d)%s" % [n_jobs, ("  •  %d ready" % n_ready) if n_ready > 0 else ""]]], tab, col, func(id): tab = id; refresh_all())
	trow.add_child(UI.spacer())
	Kit.cargo_bar(trow, f)
	var slots: Array = ui.station_type().get("manufacturing", [])
	var names: Array = []
	for s in slots:
		names.append(GameData.SLOT_NAMES[s])
	var info := UI.label("Builds here: %s (up to size %s)  •  materials from your cargo hold; modules go into station storage, components wait here." % [
		", ".join(PackedStringArray(names)) if not names.is_empty() else "nothing", GameData.SIZE_NAMES.get(int(station["tier"]), "L")], 12, UI.TEXT_DIM)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(info)
	var h := _body_h()
	if tab == "prod":
		Kit.production(self, sid, "fab", col, func(cmd): run(cmd), h)
		return
	var main := UI.hbox(12)
	add_child(main)
	if tab == "components":
		if comps.is_empty():
			main.add_child(UI.label("No fabricators for components here.", 14, UI.TEXT_DIM))
			return
		if not pick_comp in comps:
			pick_comp = comps[0]
		var items: Array = []
		for it in comps:
			var mx := Industry.component_max(f, it)
			var ing := Kit.Ingot.new(Kit.good_color(it))
			items.append({"node": ing, "name": GameData.item_name(it), "sub": "%s each" % GameData.fmt_credits(int(GameData.commodities[it]["price"])),
				"note": ("● ready ×%d" % mx) if mx > 0 else "missing", "note_col": UI.GOOD if mx > 0 else UI.TEXT_DIM, "dim": mx <= 0,
				"tag": "☢" if bool(GameData.commodities[it].get("radioactive", false)) else ""})
		Kit.grid(main, items, comps.find(pick_comp), col, func(i): pick_comp = comps[i]; refresh_all(), h)
		_comp_card(main, f, col, h)
	else:
		if mods.is_empty():
			main.add_child(UI.label("Nothing can be built here.", 14, UI.TEXT_DIM))
			return
		var kinds: Array = []
		for mid in mods:
			if not kind_of(mid) in kinds:
				kinds.append(kind_of(mid))
		if not family in kinds:
			family = kinds[0]
		var frow := UI.hbox(8)
		add_child(frow)
		move_child(frow, main.get_index())
		frow.add_child(UI.label("Kind", 12, UI.TEXT_DIM))
		var ob := OptionButton.new()
		ob.add_theme_font_size_override("font_size", 13)
		for k in kinds:
			ob.add_item("%s (%d)" % [k, mods.filter(func(m): return kind_of(m) == k).size()])
		ob.select(kinds.find(family))
		ob.item_selected.connect(func(i): family = kinds[i]; refresh_all())
		frow.add_child(ob)
		mods = mods.filter(func(m): return kind_of(m) == family)
		if not pick_mod in mods:
			pick_mod = mods[0]
		var items2: Array = []
		for mid in mods:
			var ok := Industry.missing_materials(f, Industry.recipe(station, mid)).is_empty()
			var lock := GameState.fab_tree_error(mid)
			items2.append({"tex": PixelArt.module_icon(mid), "name": GameData.module_name(mid), "sub": "fee %s" % GameData.fmt_credits(int(Industry.recipe(station, mid)["fee"])),
				"note": "● ready" if ok else "missing", "note_col": UI.GOOD if ok else UI.TEXT_DIM, "dim": not ok, "lock": "tree" if lock != "" else "",
				"tag": GameData.SIZE_NAMES.get(int(GameData.modules[mid]["size"]), str(GameData.modules[mid]["size"]))})
		Kit.grid(main, items2, mods.find(pick_mod), col, func(i): pick_mod = mods[i]; refresh_all(), h - 38.0)
		_mod_card(main, f, col, h - 38.0)


func _body_h() -> float:
	var sh := get_viewport().get_visible_rect().size.y
	return clampf(sh - 296.0 - maxf(sh - 720.0, 0.0) * 0.25, 200.0, 900.0)


func _card_box(parent: Control, col: Color, h: float) -> VBoxContainer:
	var box := UI.neon_panel(Color(col, 0.7), Color(col.darkened(0.88), 0.85), 1)
	box.custom_minimum_size = Vector2(clampf(get_viewport().get_visible_rect().size.x * 0.28, 330.0, 480.0), h)
	parent.add_child(box)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(sc)
	var v := UI.vbox(10)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(v)
	return v


## A material line: "3 Copper (you have 14)" with a bar of have / need.
func _mat(v: Control, id: String, need: int, have: float) -> void:
	var r := UI.hbox(10)
	v.add_child(r)
	var l := UI.label("%d %s  (you have %d)" % [need, GameData.item_name(id), int(floor(have + 0.0001))], 13, Color(0.9, 0.93, 1.0) if have >= need else UI.BAD)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.clip_text = true
	r.add_child(l)
	var b := UI.bar(UI.GOOD if have >= need else UI.BAD, 90)
	b.max_value = maxf(float(need), 1.0)
	b.value = minf(have, float(need))
	b.custom_minimum_size = Vector2(90, 6)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.add_child(b)


func _kv(v: Control, rows: Array) -> void:
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 14)
	v.add_child(g)
	for kv in rows:
		g.add_child(UI.label(kv[0], 13, UI.TEXT_DIM))
		g.add_child(UI.label(kv[1], 13, kv[2] if kv.size() > 2 else Color(0.9, 0.93, 1.0)))


func _queue_note(v: Control) -> void:
	var queued: int = GameState.jobs_at(String(station["id"]), "fab").filter(func(j): return not bool(j.get("done", false))).size()
	if queued > 0:
		v.add_child(UI.label("%d job%s ahead in the queue." % [queued, "s" if queued > 1 else ""], 12, UI.TEXT_DIM))


func _comp_card(parent: Control, f: ShipFitting, col: Color, h: float) -> void:
	var v := _card_box(parent, col, h)
	var it := pick_comp
	var head := UI.hbox(12)
	v.add_child(head)
	var ing := Kit.Ingot.new(Kit.good_color(it))
	ing.custom_minimum_size = Vector2(70, 46)
	head.add_child(ing)
	var hv := UI.vbox(0)
	head.add_child(hv)
	hv.add_child(UI.label(GameData.item_name(it), 22, col))
	hv.add_child(UI.label("Component  •  sells for about %s each%s" % [GameData.fmt_credits(int(GameData.commodities[it]["price"])), "  •  radioactive" if bool(GameData.commodities[it].get("radioactive", false)) else ""], 12, UI.TEXT_DIM))
	v.add_child(UI.label("PER UNIT", 11, UI.TEXT_DIM))
	var mx := Industry.component_max(f, it)
	var limit := ""
	var lim_n := 999
	for inp in Industry.COMPONENTS[it]:
		var need := int(Industry.COMPONENTS[it][inp])
		var have := float(f.cargo.get(inp, 0.0))
		_mat(v, inp, need, have)
		var can := int(floor(have / need + 0.0001))
		if can < lim_n:
			lim_n = can
			limit = GameData.item_name(inp)
	var fee := Industry.component_fee(station, it)
	_kv(v, [["Fee", "%s each" % GameData.fmt_credits(fee), UI.GOLD], ["Time", "%s each" % Industry.fmt_secs(Industry.component_time(it, 1))],
		["You can make", ("%d  (%s runs out first)" % [mx, limit]) if mx > 0 else "none: bring the materials"]])
	_queue_note(v)
	var br := UI.hbox(10)
	v.add_child(br)
	var b1 := UI.button("Make 1  (%s)" % Industry.fmt_secs(Industry.component_time(it, 1)), func(): run({"type": "fabricate", "item": it, "n": 1}))
	b1.disabled = mx <= 0 or GameState.credits < fee
	br.add_child(b1)
	var b2 := UI.button("Make all %d  (%s, %s)" % [mx, GameData.fmt_credits(fee * mx), Industry.fmt_secs(Industry.component_time(it, maxi(mx, 1)))], func(): run({"type": "fabricate", "item": it, "n": mx}))
	b2.disabled = mx <= 1 or GameState.credits < fee * mx
	br.add_child(b2)
	v.add_child(UI.label("The components wait here; collect them in the In production tab.", 11, UI.TEXT_DIM))


func _mod_card(parent: Control, f: ShipFitting, col: Color, h: float) -> void:
	var v := _card_box(parent, col, h)
	var mid := pick_mod
	var rec := Industry.recipe(station, mid)
	var head := UI.hbox(12)
	v.add_child(head)
	head.add_child(UI.icon(PixelArt.module_icon(mid), 64))
	var hv := UI.vbox(0)
	head.add_child(hv)
	hv.add_child(UI.label(GameData.module_name(mid), 22, col))
	hv.add_child(UI.label("%s  •  size %s  •  market price %s" % [GameData.SLOT_NAMES.get(String(GameData.modules[mid]["slot"]), ""), GameData.SIZE_NAMES.get(int(GameData.modules[mid]["size"]), ""),
		GameData.fmt_credits(int(GameData.modules[mid]["price"]))], 12, UI.TEXT_DIM))
	var lines: Array = Array(GameData.module_summary(mid).split("
")).slice(1).filter(func(l): return not String(l).begins_with("Price"))
	var sum := UI.label("
".join(PackedStringArray(lines)), 12, UI.TEXT_DIM)
	sum.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(sum)
	v.add_child(UI.label("MATERIALS", 11, UI.TEXT_DIM))
	for k in rec["materials"]:
		_mat(v, k, int(rec["materials"][k]), float(f.cargo.get(k, 0.0)))
	var t := Industry.station_build_time(mid)
	_kv(v, [["Fee", GameData.fmt_credits(int(rec["fee"])), UI.GOLD], ["Time", Industry.fmt_secs(t)], ["Quality", "rolled when it is done (F to A)"]])
	_queue_note(v)
	var why := ""
	if not GameState.tile_open("station_mfg"):
		why = "Skill tree: open \"Station Manufacturing\" first (Pilot window)."
	elif GameState.fab_tree_error(mid) != "":
		why = GameState.fab_tree_error(mid)
	if why != "":
		var wl := UI.label(why, 12, UI.BAD)
		wl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(wl)
	var b := UI.button("Build  (%s, %s)" % [GameData.fmt_credits(int(rec["fee"])), Industry.fmt_secs(t)], func(): run({"type": "build", "module": mid}))
	b.disabled = why != "" or not Industry.missing_materials(f, rec).is_empty() or GameState.credits < int(rec["fee"])
	v.add_child(b)
	v.add_child(UI.label("The module goes into this station's storage when it is done.", 11, UI.TEXT_DIM))


var _tick := 0.0


## The In production tab follows the clock (a rebuild a second while it is shown).
func _process(delta: float) -> void:
	if tab != "prod" or not is_visible_in_tree():
		return
	_tick += delta
	if _tick >= 1.0:
		_tick = 0.0
		build()


## Q / E: the tabs.
func menu_tab(step: int) -> void:
	var tabs := ["components", "modules", "prod"]
	tab = tabs[posmod(tabs.find(tab) + step, tabs.size())]
	refresh_all()
