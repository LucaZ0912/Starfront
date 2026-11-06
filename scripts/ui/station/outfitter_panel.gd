extends StationServicePanel
## Outfitter (Synapse Armaments), package 27: category tiles on the left (weapons, tools, core, optional, drone
## hangar, storage), the slots of the docked ship in that category, then the module families in stock for the
## chosen slot as tiles, then their sizes and qualities as tiles; picking one shows a short description and how
## the ship's values change. Buy & fit puts it straight into the slot (the old module goes to storage). A footer
## shows the ship's key values and power – with the change a pick would make.

const ModuleDesc = preload("res://data/module_desc.gd")
const ModuleData = preload("res://data/modules.gd")
const CATS := [
	["weapon", "Weapons", "w_kinetic", ["weapon"]],
	["tool", "Tools", "t_mining", ["tool"]],
	["core", "Core", "reactor", ["hull", "engine", "distributor", "reactor", "tank", "hyperdrive", "sensors"]],
	["optional", "Optional", "o_shield", ["optional"]],
	["drones", "Drone hangar", "drone", ["hangar", "dweapon", "dtool", "dbonus"]],
	["storage", "Storage", "o_cargo", []],
]
## Footer / comparison values: label, stats key, higher is better, format
const VALUES := [
	["Speed", "speed", true, "%.0f"], ["Agility", "turn", true, "%.2f"], ["Mass", "mass", false, "%.0f t"],
	["Power out", "power_output", true, "%.0f MW"], ["Power use", "power_draw", false, "%.0f MW"],
	["Capacitor", "cap_max", true, "%.0f"], ["Recharge", "cap_recharge", true, "%.1f/s"],
	["Shield", "shield_max", true, "%.0f"], ["Armor", "armor_max", true, "%.0f"], ["Hull", "structure_max", true, "%.0f"],
	["DPS", "dps_total", true, "%.0f"], ["Cargo", "cargo_max", true, "%.0f m³"], ["Fuel", "fuel_max", true, "%.0f"],
	["Sensors", "sensor_range", true, "%.0f km"], ["Signature", "signature", false, "%.0f"],
]

static var cat := "weapon"
var slot := ""
var fam := ""
var pick := ""                    # module id picked in the size · quality tiles (or from storage)
var pick_store := false           # the pick comes from station storage


func build() -> void:
	UI.clear(self)
	var f := fit()
	var main := UI.hbox(12)
	main.custom_minimum_size = Vector2(0, 530)
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(main)
	_rail(main)
	if cat == "storage":
		_storage_view(main)
	elif f == null:
		main.add_child(UI.label("No ship of yours is docked here – only your storage can be used.", 14, UI.BAD))
	else:
		_slot_list(main, f)
		_choice(main, f)
	if f != null:
		_footer(f)


# ---- the category rail

func _rail(parent: Control) -> void:
	var v := UI.vbox(6)
	parent.add_child(v)
	for c in CATS:
		var id: String = c[0]
		var on := cat == id
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(96, 72)
		b.tooltip_text = c[1]
		var col := corp_color()
		for st in ["normal", "hover", "pressed"]:
			var sb := UI.panel_style(Color(col.darkened(0.6), 0.95) if on else Color(0.05, 0.03, 0.1, 0.95), Color(col, 0.95 if on or st == "hover" else 0.35))
			sb.set_border_width_all(2 if on else 1)
			b.add_theme_stylebox_override(st, sb)
		b.pressed.connect(func(): _set_cat(id))
		var bv := UI.vbox(2)
		bv.set_anchors_preset(Control.PRESET_FULL_RECT)
		bv.offset_top = 6
		bv.alignment = BoxContainer.ALIGNMENT_CENTER
		bv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(bv)
		var ic := UI.icon(PixelArt.icon_texture(String(c[2])), 34)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bv.add_child(ic)
		var l := UI.label(String(c[1]).to_upper(), 10, col if on else UI.TEXT_DIM)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bv.add_child(l)
		v.add_child(b)


func _set_cat(id: String) -> void:
	cat = id
	slot = ""
	fam = ""
	pick = ""
	build()


func _cat_types() -> Array:
	for c in CATS:
		if c[0] == cat:
			return c[3]
	return []


# ---- the ship's slots of this category

func _slot_list(parent: Control, f: ShipFitting) -> void:
	var box := _frame(parent, 300, false)
	box.add_child(UI.label("EQUIPPED – %s" % String(_cat_name()).to_upper(), 15, corp_color()))
	box.add_child(UI.label(f.ship_name, 12, UI.TEXT_DIM))
	var any := false
	for key in f.slot_keys():
		if not ShipFitting.slot_type(key) in _cat_types():
			continue
		any = true
		var k: String = key
		var mid := f.get_module(key)
		var on: bool = key == slot
		var col := GameData.quality_color(String(GameData.modules[mid]["quality"])) if mid != "" and GameData.modules.has(mid) else UI.TEXT_DIM
		var b := _tile(box, Vector2(0, 54), corp_color(), on, func(): _set_slot(k))
		var row := _tile_row(b)
		row.add_child(_ic(PixelArt.module_icon(mid) if mid != "" else PixelArt.icon_texture(_slot_icon(key)), 32, mid == ""))
		var tv := UI.vbox(0)
		tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(tv)
		tv.add_child(_lbl("%s  ·  SIZE ≤ %d" % [GameData.slot_label(key).to_upper(), f.slot_max(key)], 11, UI.TEXT_DIM))
		tv.add_child(_lbl(GameData.module_name(mid) if mid != "" else "EMPTY", 14, col if mid != "" else UI.TEXT_DIM))
	if not any:
		box.add_child(UI.label("This ship has no such slots.", 13, UI.TEXT_DIM))


func _cat_name() -> String:
	for c in CATS:
		if c[0] == cat:
			return c[1]
	return ""


func _slot_icon(key: String) -> String:
	var t := ShipFitting.slot_type(key)
	return {"weapon": "w_kinetic", "tool": "t_mining", "optional": "o_cargo", "dweapon": "w_kinetic", "dtool": "t_mining", "dbonus": "drone", "hangar": "drone"}.get(t, t)


func _set_slot(k: String) -> void:
	slot = k
	fam = ""
	pick = ""
	build()


# ---- families → sizes and qualities → the pick

func _choice(parent: Control, f: ShipFitting) -> void:
	var box := _frame(parent, 0, true)
	if slot == "":
		box.add_child(UI.label("Choose a slot on the left.", 14, UI.TEXT_DIM))
		return
	var t := ShipFitting.slot_type(slot)
	var core := t in GameData.CORE_SLOTS
	var crumb := GameData.slot_label(slot)
	if fam != "":
		crumb += "  ›  " + String(ModuleData.FAMILIES[fam]["name"])
	var head := UI.hbox(10)
	box.add_child(head)
	if fam != "" and not core:
		head.add_child(UI.button("‹ Modules", func(): _set_fam("")))
	head.add_child(UI.label(crumb.to_upper(), 15, corp_color()))
	var cur := f.get_module(slot)
	if cur != "":
		var ch := UI.hbox(8)
		box.add_child(ch)
		ch.add_child(UI.label("Fitted: %s" % GameData.module_name(cur), 12, UI.TEXT_DIM))
		ch.add_child(UI.button("Remove → storage", func(): _run({"type": "unfit_module", "slot": slot})))
	# what is in stock for this slot
	var stock := {}
	for mid in station["shop"]:
		var m: Dictionary = GameData.modules[mid]
		if String(m["slot"]) != _module_slot(t):
			continue
		var fm: String = m["family"]
		if not stock.has(fm):
			stock[fm] = []
		stock[fm].append(mid)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(sc)
	var inner := UI.vbox(8)
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(inner)
	# modules of this kind in storage here
	var stored: Array = []
	for smid in GameState.storage_of(station["id"]):
		if GameData.modules.has(smid) and String(GameData.modules[smid]["slot"]) == _module_slot(t):
			stored.append(smid)
	if not stored.is_empty() and (fam == "" or core):
		inner.add_child(UI.label("IN YOUR STORAGE HERE", 12, UI.TEXT_DIM))
		var sf := _flow(inner)
		for smid2 in stored:
			_variant_tile(sf, f, String(smid2), true)
	if stock.is_empty():
		inner.add_child(UI.label("The outfitter has nothing for this slot.", 13, UI.TEXT_DIM))
	elif core or fam != "":
		# sizes and qualities (core slots: straight here, one row per family)
		for fm2 in stock:
			if fam != "" and fm2 != fam:
				continue
			inner.add_child(UI.label(String(ModuleData.FAMILIES[fm2]["name"]).to_upper(), 13, Color(0.85, 0.88, 0.95)))
			var vf := _flow(inner)
			var ids: Array = stock[fm2]
			ids.sort_custom(func(a, b): return int(GameData.modules[a]["size"]) * 10 + "FEDCBA".find(String(GameData.modules[a]["quality"])) < int(GameData.modules[b]["size"]) * 10 + "FEDCBA".find(String(GameData.modules[b]["quality"])))
			for mid2 in ids:
				_variant_tile(vf, f, String(mid2), false)
	else:
		# module families as tiles
		var ff := _flow(inner)
		for fm3 in stock:
			_family_tile(ff, f, String(fm3), stock[fm3])
	if pick != "":
		_detail(box, f)


func _module_slot(t: String) -> String:
	return "drone" if t == "dbonus" else ("weapon" if t == "dweapon" else ("tool" if t == "dtool" else t))


func _set_fam(fm: String) -> void:
	fam = fm
	pick = ""
	build()


func _family_tile(parent: Control, f: ShipFitting, fm: String, ids: Array) -> void:
	var fits := 0
	for mid in ids:
		if f.can_fit(slot, String(mid)) == "":
			fits += 1
	var col := corp_color()
	var b := _tile(parent, Vector2(190, 92), col, false, func(): _set_fam(fm))
	b.disabled = fits == 0
	var v := UI.vbox(2)
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 8
	v.offset_top = 6
	v.offset_right = -6
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	v.add_child(_lbl(String(ModuleData.FAMILIES[fm]["name"]).to_upper(), 12, col if fits > 0 else UI.TEXT_DIM))
	var r := UI.hbox(8)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(r)
	r.add_child(_ic(PixelArt.module_icon(String(ids[0])), 40, fits == 0))
	var info := UI.vbox(0)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.add_child(info)
	info.add_child(_lbl("%d in stock" % ids.size(), 11, UI.TEXT_DIM))
	info.add_child(_lbl("%d fit this slot" % fits if fits > 0 else "too big for this slot", 11, UI.GOOD if fits > 0 else UI.BAD))
	var m: Dictionary = GameData.modules[ids[0]]
	if m.has("damage_type"):
		info.add_child(_lbl(String(m["damage_type"]).to_upper(), 11, {"optical": Color(0.5, 0.85, 1.0), "kinetic": Color(1.0, 0.8, 0.4), "explosive": Color(1.0, 0.45, 0.35)}.get(String(m["damage_type"]), UI.TEXT_DIM)))
	b.tooltip_text = ModuleDesc.of(fm)


func _variant_tile(parent: Control, f: ShipFitting, mid: String, from_store: bool) -> void:
	var m: Dictionary = GameData.modules[mid]
	var q := String(m["quality"])
	var qc := GameData.quality_color(q)
	var why := f.can_fit(slot, mid)
	var locked: String = "" if from_store else GameState.rep.module_error(station, mid)
	var reason := why if why != "" else locked
	var on := pick == mid and pick_store == from_store
	var b := _tile(parent, Vector2(118, 70), qc, on, func(): _set_pick(mid, from_store))
	b.disabled = reason != ""
	b.tooltip_text = reason if reason != "" else GameData.module_summary(mid)
	var v := UI.vbox(0)
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 8
	v.offset_top = 4
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	v.add_child(_lbl("SIZE %d · %s" % [int(m["size"]), q], 14, qc if reason == "" else UI.TEXT_DIM))
	if from_store:
		v.add_child(_lbl(String(m["base_name"]), 10, UI.TEXT_DIM))
		v.add_child(_lbl("stored ×%d" % int(GameState.storage_of(station["id"]).get(mid, 0)), 11, UI.GOOD))
	else:
		v.add_child(_lbl(GameData.fmt_credits(buy_price(int(m["price"]))), 12, UI.GOLD if reason == "" else UI.TEXT_DIM))
		v.add_child(_lbl("too big" if why != "" else ("locked" if locked != "" else ""), 10, UI.BAD))


func _set_pick(mid: String, from_store: bool) -> void:
	pick = mid
	pick_store = from_store
	build()


## The pick: description, values, how the ship changes, and the buttons.
func _detail(parent: Control, f: ShipFitting) -> void:
	var m: Dictionary = GameData.modules[pick]
	var box := UI.neon_panel(Color(GameData.quality_color(String(m["quality"])), 0.6), Color(0.04, 0.03, 0.09, 0.97), 1)
	parent.add_child(box)
	var v := UI.vbox(4)
	box.add_child(v)
	var top := UI.hbox(10)
	v.add_child(top)
	top.add_child(UI.icon(PixelArt.module_icon(pick), 40))
	var tv := UI.vbox(0)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(tv)
	tv.add_child(UI.label(GameData.module_name(pick), 16, GameData.quality_color(String(m["quality"]))))
	tv.add_child(UI.wrap_label(ModuleDesc.of(String(m["family"])), 13, Color(0.9, 0.92, 1.0), 560))
	# the module's values in one compact block (the first line repeats the name)
	var lines := GameData.module_summary(pick).split("
", false)
	if lines.size() > 1:
		lines.remove_at(0)
	if lines.size() > 1 and lines[0] == ModuleDesc.of(String(m["family"])):
		lines.remove_at(0)                 # the description stands above already
	v.add_child(UI.wrap_label("   •   ".join(lines), 11, UI.TEXT_DIM, 980))
	# what changes on the ship
	var after := _preview(f)
	var s0 := f.stats()
	var s1 := after.stats()
	var flow := _flow(v)
	var n := 0
	for val in VALUES:
		var a := float(s0.get(val[1], 0.0))
		var b2 := float(s1.get(val[1], 0.0))
		if String(val[3]) % a == String(val[3]) % b2:
			continue                       # no visible change
		var better: bool = (b2 > a) == bool(val[2])
		flow.add_child(UI.label("%s %s → %s" % [val[0], String(val[3]) % a, String(val[3]) % b2], 12, UI.GOOD if better else UI.BAD))
		n += 1
	if n == 0:
		v.add_child(UI.label("No change to the ship's main values.", 12, UI.TEXT_DIM))
	if float(s1["power_draw"]) > float(s1["power_output"]):
		v.add_child(UI.label("Warning: the ship would draw more power than its reactor makes.", 12, UI.BAD))
	var btns := UI.hbox(10)
	v.add_child(btns)
	var price := buy_price(int(m["price"]))
	if pick_store:
		btns.add_child(UI.button("Fit from storage", func(): _run({"type": "fit_module", "slot": slot, "module": pick})))
	else:
		var bf := UI.button("Buy & fit (%s)" % GameData.fmt_credits(price), func(): _run({"type": "module_buy_fit", "slot": slot, "module": pick}))
		bf.disabled = GameState.credits < price
		btns.add_child(bf)
		var bs := UI.button("Buy to storage", func(): _run({"type": "module_buy", "module": pick}))
		bs.disabled = GameState.credits < price
		btns.add_child(bs)
	if f.get_module(slot) != "":
		btns.add_child(UI.label("The fitted %s goes into storage here." % GameData.module_name(f.get_module(slot)), 11, UI.TEXT_DIM))


## The docked ship as it would be with the pick in the chosen slot.
func _preview(f: ShipFitting) -> ShipFitting:
	var g := ShipFitting.new(f.hull_id, f.faction)
	g.modules = f.modules.duplicate()
	g.modules[slot] = pick
	g.mark_dirty()
	return g


func _run(cmd: Dictionary) -> void:
	var err := Commands.execute(cmd)
	if err != "":
		GameState.log_msg(err, GameState.COL_WARN)
	elif String(cmd["type"]) in ["module_buy_fit", "fit_module", "unfit_module"]:
		pick = ""
	refresh_all()


# ---- storage: sell what is stored here

func _storage_view(parent: Control) -> void:
	var box := _frame(parent, 0, true)
	box.add_child(UI.label("YOUR STORAGE HERE", 15, corp_color()))
	box.add_child(UI.label("Fit stored modules by choosing a slot in the other categories.", 12, UI.TEXT_DIM))
	var store := GameState.storage_of(station["id"])
	if store.is_empty():
		box.add_child(UI.label("empty", 13, UI.TEXT_DIM))
	for mid in store:
		var row := UI.hbox(8)
		box.add_child(row)
		row.add_child(UI.icon(PixelArt.module_icon(mid), 28))
		row.add_child(UI.label("%s ×%d" % [GameData.module_name(mid), int(store[mid])], 14, GameData.quality_color(String(GameData.modules[mid]["quality"])) if GameData.modules.has(mid) else Color.WHITE))
		row.add_child(UI.spacer())
		var id2: String = mid
		row.add_child(UI.button("Sell (%s)" % GameData.fmt_credits(Commands.module_sell_price(mid)), func(): _run({"type": "module_sell", "module": id2})))


# ---- footer: the ship's key values and power (with the pick's change)

func _footer(f: ShipFitting) -> void:
	var box := UI.neon_panel(Color(corp_color(), 0.5), Color(0.03, 0.02, 0.07, 0.97), 1)
	add_child(box)
	var v := UI.vbox(4)
	box.add_child(v)
	var s0 := f.stats()
	var s1: Dictionary = _preview(f).stats() if pick != "" and slot != "" else s0
	var top := UI.hbox(14)
	v.add_child(top)
	top.add_child(UI.label("SHIP SPECS – %s" % f.ship_name.to_upper(), 13, corp_color()))
	top.add_child(UI.spacer())
	var pw := UI.hbox(8)
	top.add_child(pw)
	pw.add_child(UI.label("POWER", 12, UI.TEXT_DIM))
	var out1 := maxf(float(s1["power_output"]), 0.001)
	var bar := UI.bar(UI.GOOD if float(s1["power_draw"]) <= out1 else UI.BAD, 260)
	bar.max_value = out1
	bar.value = minf(float(s1["power_draw"]), out1)
	pw.add_child(bar)
	pw.add_child(UI.label("%.0f / %.0f MW" % [float(s1["power_draw"]), float(s1["power_output"])], 12, UI.GOOD if float(s1["power_draw"]) <= out1 else UI.BAD))
	var grid := GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 18)
	v.add_child(grid)
	for val in VALUES:
		if val[1] in ["power_output", "power_draw"]:
			continue
		var a := float(s0.get(val[1], 0.0))
		var b := float(s1.get(val[1], 0.0))
		var txt := "%s  %s" % [String(val[0]).to_upper(), String(val[3]) % b]
		var col := Color(0.88, 0.9, 1.0)
		if String(val[3]) % a != String(val[3]) % b:
			col = UI.GOOD if (b > a) == bool(val[2]) else UI.BAD
			txt += "  (%+.0f)" % (b - a) if absf(b - a) >= 1.0 else "  (%+.2f)" % (b - a)
		grid.add_child(UI.label(txt, 12, col))


# ---- small helpers

func _frame(parent: Control, width: float, expand: bool) -> VBoxContainer:
	var p := UI.neon_panel(Color(corp_color(), 0.4), Color(0.035, 0.02, 0.07, 0.9), 1)
	if width > 0.0:
		p.custom_minimum_size = Vector2(width, 0)
	if expand:
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(p)
	var v := UI.vbox(6)
	p.add_child(v)
	return v


func _tile(parent: Control, size: Vector2, col: Color, on: bool, cb: Callable) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = size
	if size.x <= 0.0:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for st in ["normal", "hover", "pressed", "disabled"]:
		var sb := UI.panel_style(Color(col.darkened(0.75), 0.95) if on else Color(0.05, 0.03, 0.1, 0.95), Color(col, 0.95 if on or st == "hover" else (0.15 if st == "disabled" else 0.4)))
		sb.set_border_width_all(2 if on else 1)
		sb.border_width_left = 4 if on else 2
		b.add_theme_stylebox_override(st, sb)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _tile_row(b: Button) -> HBoxContainer:
	var row := UI.hbox(10)
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 10
	row.offset_right = -6
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(row)
	return row


func _flow(parent: Control) -> HFlowContainer:
	var fl := HFlowContainer.new()
	fl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fl.add_theme_constant_override("h_separation", 8)
	fl.add_theme_constant_override("v_separation", 8)
	parent.add_child(fl)
	return fl


func _lbl(text: String, size: int, col: Color) -> Label:
	var l := UI.label(text, size, col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _ic(tex: Texture2D, size: float, dim: bool) -> TextureRect:
	var ic := UI.icon(tex, size)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if dim:
		ic.modulate = Color(0.45, 0.45, 0.5)
	return ic
