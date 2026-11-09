extends StationServicePanel
const ModuleData = preload("res://data/modules.gd")
## Munitions Depot (Obsidian Ordnance, package 42b): ammunition for the weapons that have to be restocked – the
## mines of the mine launchers so far. What it stocks and charges follows the system's economy.


func build() -> void:
	UI.clear(self)
	if no_ship():
		return
	var f := fit()
	var offer := Munitions.offer(station)
	var sid := Market.system_of(station)
	section("MUNITIONS FOR %s" % f.ship_name.to_upper())
	add_child(UI.label("Economy: %s  •  %s – military systems stock everything and sell it cheaply, industrial ones the common kinds, high-tech ones the electronic ones." % [Economy.label(sid), Economy.level_name(sid)], 12, UI.TEXT_DIM))
	standing_line()
	cargo_line()
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 6)
	add_child(grid)
	for h in ["Munition", "For", "Price", "In hold", "Buy", "Sell back"]:
		grid.add_child(UI.label(h, 13, corp_color()))
	for cid in Munitions.AMMO:
		var c: Dictionary = GameData.commodities[cid]
		var have := float(f.cargo.get(cid, 0.0))
		var on_sale: bool = offer.has(cid)
		var nl := UI.label(c["name"], 14, Color(0.9, 0.93, 1.0) if on_sale else UI.TEXT_DIM)
		if GameData.MINES.has(cid):
			nl.tooltip_text = String(GameData.MINES[cid]["text"])
			nl.mouse_filter = Control.MOUSE_FILTER_STOP
		grid.add_child(nl)
		var fam := String(Munitions.AMMO[cid]["for"])
		var n_l := Munitions.launchers(f, cid).size()
		grid.add_child(UI.label("%s%s" % [ModuleData.FAMILIES.get(fam, {}).get("name", fam), (" (%d fitted)" % n_l) if n_l > 0 else ""], 12, UI.GOOD if n_l > 0 else UI.TEXT_DIM))
		grid.add_child(UI.label(GameData.fmt_credits(buy_price(int(offer[cid]))) if on_sale else "not stocked", 14, Color(1.0, 0.8, 0.5) if on_sale else UI.TEXT_DIM))
		grid.add_child(UI.label("%d" % int(have)))
		var bb := UI.hbox(2)
		if on_sale:
			for n in [1, 5, 10]:
				var amount: int = n
				var id: String = cid
				bb.add_child(UI.button("+%d" % n, func(): run({"type": "munitions_buy", "item": id, "amount": amount})))
		grid.add_child(bb)
		var sb := UI.hbox(2)
		if have >= 1.0:
			var id2: String = cid
			sb.add_child(UI.button("−1", func(): run({"type": "munitions_sell", "item": id2, "amount": 1})))
			sb.add_child(UI.button("All", func(): run({"type": "munitions_sell", "item": id2, "amount": -1})))
		grid.add_child(sb)
	var any := false
	for cid2 in Munitions.AMMO:
		any = any or not Munitions.launchers(f, cid2).is_empty()
	if not any:
		add_child(UI.label("This ship has no weapon that needs munitions (mine launchers).", 13, UI.TEXT_DIM))
