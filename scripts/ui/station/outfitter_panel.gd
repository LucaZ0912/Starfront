extends StationServicePanel
## Outfitter (Synapse Armaments): buy modules into station storage, sell stored modules.
## Fitting itself happens in the ship menu (I).


func build() -> void:
	UI.clear(self)
	var cols := UI.hbox(24)
	add_child(cols)
	var left := UI.vbox(4)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(left)
	left.add_child(UI.label("FOR SALE", 16, corp_color()))
	left.add_child(UI.label("Purchases go into your storage on this station. Fit them via Ship [%s] → Modules." % Keybinds.key_text("ship_menu") + "", 12, UI.TEXT_DIM))
	var sl := standing_line()
	remove_child(sl)
	left.add_child(sl)
	# one row per module family; every size/quality in stock is a buy button (package 19)
	var by_slot := {}
	for mid in station["shop"]:
		var m: Dictionary = GameData.modules[mid]
		var slot: String = m["slot"]
		if not by_slot.has(slot):
			by_slot[slot] = {}
		if not by_slot[slot].has(m["family"]):
			by_slot[slot][m["family"]] = []
		by_slot[slot][m["family"]].append(mid)
	for slot in ["hull", "engine", "distributor", "reactor", "tank", "hyperdrive", "sensors", "weapon", "tool", "optional"]:
		if not by_slot.has(slot):
			continue
		left.add_child(UI.label(GameData.SLOT_NAMES[slot], 13, UI.TEXT_DIM))
		for fam in by_slot[slot]:
			var ids: Array = by_slot[slot][fam]
			ids.sort_custom(func(a, b): return int(GameData.modules[a]["size"]) * 10 + "FEDCBA".find(String(GameData.modules[a]["quality"])) < int(GameData.modules[b]["size"]) * 10 + "FEDCBA".find(String(GameData.modules[b]["quality"])))
			var row := UI.hbox(8)
			row.add_child(UI.icon(PixelArt.module_icon(ids[0]), 28))
			var nm := UI.label(String(GameData.modules[ids[0]]["base_name"]), 14)
			nm.custom_minimum_size = Vector2(230, 0)
			row.add_child(nm)
			var flow := HFlowContainer.new()
			flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			flow.add_theme_constant_override("h_separation", 4)
			flow.add_theme_constant_override("v_separation", 4)
			row.add_child(flow)
			for mid in ids:
				var m2: Dictionary = GameData.modules[mid]
				var id: String = mid
				var locked: String = GameState.rep.module_error(station, mid)
				var price := buy_price(int(m2["price"]))
				var b := UI.button("%d·%s" % [int(m2["size"]), m2["quality"]], func(): _buy(id), (GameData.module_summary(mid) + "\nPrice here: " + GameData.fmt_credits(price)) if locked == "" else locked)
				b.add_theme_color_override("font_color", GameData.quality_color(String(m2["quality"])))
				b.disabled = locked != ""
				flow.add_child(b)
			left.add_child(row)
	left.add_child(UI.label("Buttons: size · quality – hover for the details and the price.", 11, UI.TEXT_DIM))

	var right := UI.vbox(4)
	right.custom_minimum_size = Vector2(440, 0)
	cols.add_child(right)
	right.add_child(UI.label("YOUR STORAGE HERE", 16, corp_color()))
	var store := GameState.storage_of(station["id"])
	if store.is_empty():
		right.add_child(UI.label("empty", 13, UI.TEXT_DIM))
	for mid in store:
		var row := UI.hbox(8)
		row.add_child(UI.icon(PixelArt.module_icon(mid), 28))
		row.add_child(UI.label("%s ×%d" % [GameData.module_name(mid), int(store[mid])], 14))
		row.add_child(UI.spacer())
		var price := Commands.module_sell_price(mid)
		var id2: String = mid
		row.add_child(UI.button("Sell (%s)" % GameData.fmt_credits(price), func(): _sell(id2, price)))
		right.add_child(row)


func _buy(mid: String) -> void:
	run({"type": "module_buy", "module": mid})


func _sell(mid: String, _price: int) -> void:
	run({"type": "module_sell", "module": mid})
