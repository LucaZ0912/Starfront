extends StationServicePanel
## Manufacturing (Molten Lotus Fabrication): build modules from materials in the cargo hold.
## What can be built depends on the station type and tier; materials the station produces
## itself lower the fabrication fee.


func build() -> void:
	UI.clear(self)
	if no_ship():
		return
	var f := fit()
	var slots: Array = ui.station_type().get("manufacturing", [])
	var names: Array = []
	for s in slots:
		names.append(GameData.SLOT_NAMES[s])
	add_child(UI.label("Fabricators here build: %s (up to size %s). Materials come from your cargo hold, the module goes to station storage." % [
		", ".join(PackedStringArray(names)), GameData.SIZE_NAMES[int(station["tier"])]], 13, UI.TEXT_DIM))
	cargo_line()
	# package 25b: every job takes time – the queue of this station
	var q := GameState.jobs_at(String(station["id"]))
	if not q.is_empty():
		section("IN PRODUCTION")
		for j in q:
			add_child(UI.label("%s – %d s left" % [GameData.module_name(String(j["item"])), int(ceil(float(j["left"])))], 13, UI.GOLD))
	_components(f)                                   # package 41
	var list := Industry.buildable(station)
	if list.is_empty():
		add_child(UI.label("Nothing can be built here.", 13, UI.TEXT_DIM))
	for mid in list:
		var rec := Industry.recipe(station, mid)
		var missing := Industry.missing_materials(f, rec)
		var row := UI.hbox(14)
		add_child(row)
		row.add_child(UI.icon(PixelArt.module_icon(mid), 40))
		var info := UI.vbox(1)
		info.custom_minimum_size = Vector2(300, 0)
		row.add_child(info)
		var nm := UI.label(GameData.module_name(mid), 15, corp_color())
		nm.tooltip_text = GameData.module_summary(mid)
		nm.mouse_filter = Control.MOUSE_FILTER_PASS
		info.add_child(nm)
		info.add_child(UI.label("Market price %s" % GameData.fmt_credits(int(GameData.modules[mid]["price"])), 11, UI.TEXT_DIM))
		var mats := UI.hbox(10)
		mats.custom_minimum_size = Vector2(520, 0)
		row.add_child(mats)
		for k in rec["materials"]:
			var need := int(rec["materials"][k])
			var have := int(f.cargo.get(k, 0.0))
			mats.add_child(UI.label("%s %d/%d" % [GameData.item_name(k), mini(have, need), need], 13, UI.GOOD if have >= need else UI.BAD))
		row.add_child(UI.label("Fee %s  •  %d s" % [GameData.fmt_credits(int(rec["fee"])), int(Industry.build_time(mid))], 13, UI.GOLD))
		var id: String = mid
		var b := UI.button("Build", func(): _build(id))
		b.disabled = not missing.is_empty()
		row.add_child(b)


func _build(mid: String) -> void:
	run({"type": "build", "module": mid})


## Package 41: components from refined materials – inputs from the hold, the component into it.
func _components(f: ShipFitting) -> void:
	section("COMPONENTS")
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 6)
	add_child(grid)
	for item in Industry.COMPONENTS:
		var it: String = item
		var row := UI.hbox(8)
		grid.add_child(row)
		var info := UI.vbox(0)
		info.custom_minimum_size = Vector2(420, 0)
		row.add_child(info)
		var radio := " ☢" if bool(GameData.commodities[it].get("radioactive", false)) else ""
		info.add_child(UI.label("%s%s  –  %s each" % [GameData.item_name(it), radio, GameData.fmt_credits(int(GameData.commodities[it]["price"]))], 13, corp_color()))
		var parts: PackedStringArray = []
		var ok := true
		for inp in Industry.COMPONENTS[it]:
			var need := int(Industry.COMPONENTS[it][inp])
			var have := int(floor(float(f.cargo.get(inp, 0.0)) + 0.0001))
			ok = ok and have >= need
			parts.append("%d %s (%d)" % [need, GameData.item_name(inp), have])
		info.add_child(UI.label(", ".join(parts) + "  •  fee %s" % GameData.fmt_credits(Industry.component_fee(station, it)), 11, UI.TEXT_DIM if ok else UI.BAD))
		var mx := Industry.component_max(f, it)
		var b1 := UI.button("Make 1", func(): run({"type": "fabricate", "item": it, "n": 1}))
		b1.disabled = mx <= 0
		row.add_child(b1)
		var b2 := UI.button("Make all (%d)" % mx, func(): run({"type": "fabricate", "item": it, "n": mx}))
		b2.disabled = mx <= 1
		row.add_child(b2)
