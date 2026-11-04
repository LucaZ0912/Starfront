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
	var by_slot := {}
	for mid in station["shop"]:
		var slot: String = GameData.modules[mid]["slot"]
		if not by_slot.has(slot):
			by_slot[slot] = []
		by_slot[slot].append(mid)
	for slot in ["hull", "engine", "distributor", "reactor", "tank", "hyperdrive", "sensors", "weapon", "tool", "optional"]:
		if not by_slot.has(slot):
			continue
		left.add_child(UI.label(GameData.SLOT_NAMES[slot], 13, UI.TEXT_DIM))
		for mid in by_slot[slot]:
			var m: Dictionary = GameData.modules[mid]
			var row := UI.hbox(8)
			row.add_child(UI.icon(PixelArt.module_icon(mid), 28))
			var nm := UI.label(GameData.module_name(mid), 14)
			nm.custom_minimum_size = Vector2(270, 0)
			nm.tooltip_text = GameData.module_summary(mid)
			nm.mouse_filter = Control.MOUSE_FILTER_PASS
			row.add_child(nm)
			row.add_child(UI.label(GameData.fmt_credits(buy_price(int(m["price"]))), 14, UI.GOLD))
			var id: String = mid
			var locked: String = GameState.rep.module_error(station, mid)
			var bb := UI.button("Buy" if locked == "" else "Locked", func(): _buy(id), GameData.module_summary(mid) if locked == "" else locked)
			bb.disabled = locked != ""
			row.add_child(bb)
			left.add_child(row)

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
