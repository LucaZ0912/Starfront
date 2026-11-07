extends StationServicePanel
## Market (Kessler-Vance Exchange): buy and sell commodities with the ship's cargo hold.


func build() -> void:
	UI.clear(self)
	if no_ship():
		return
	var f := fit()
	var t: Dictionary = ui.station_type()
	var prod: Array = []
	for c in t["produces"]:
		prod.append(GameData.item_name(c))
	var cons: Array = []
	for c in t["consumes"]:
		cons.append(GameData.item_name(c))
	add_child(UI.label("Local economy – cheap here: %s   •   in demand: %s" % [", ".join(PackedStringArray(prod)), ", ".join(PackedStringArray(cons))], 13, UI.TEXT_DIM))
	standing_line()
	cargo_line()
	# Category filter
	var tabs := UI.hbox(4)
	add_child(tabs)
	for spec in FILTERS:
		var key: String = spec[0]
		var b := UI.button(spec[1], func(): _set_filter(key))
		b.toggle_mode = true
		b.button_pressed = filter == key
		tabs.add_child(b)
	var grid := GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 6)
	add_child(grid)
	for h in ["Commodity", "Volume", "Buy", "Sell", "In hold", "Buy", "Sell"]:
		grid.add_child(UI.label(h, 13, corp_color()))
	var market: Dictionary = station["market"]
	for cid in GameData.commodities:
		if not market.has(cid) or not _matches(cid, f, t):
			continue
		var c: Dictionary = GameData.commodities[cid]
		var m: Dictionary = market[cid]
		var buy := buy_price(int(m["buy"]))
		var sell := int(round(sell_price(float(m["sell"]))))
		var have := float(f.cargo.get(cid, 0.0))
		var name_col := UI.GOOD if cid in t["produces"] else (UI.GOLD if cid in t["consumes"] else Color(0.9, 0.93, 1.0))
		grid.add_child(UI.label(c["name"], 14, name_col))
		grid.add_child(UI.label("%.1f m³" % float(c["volume"])))
		grid.add_child(UI.label(GameData.fmt_credits(buy) if buy >= 0 else "–", 14, Color(1.0, 0.8, 0.5)))
		var sl := UI.label(GameData.fmt_credits(sell), 14, UI.GOOD)
		if GameState.has_perk("market_insider"):
			# package 30: where it sells best next door
			var nb: Array = GameState.best_nearby_sell(cid)
			if not nb.is_empty() and float(nb[0]) > float(sell):
				sl.text += "  ↗ %s" % GameData.fmt_credits(int(nb[0]))
				sl.tooltip_text = "Market Insider: %s at %s (%s)" % [GameData.fmt_credits(int(nb[0])), nb[1], nb[2]]
				sl.mouse_filter = Control.MOUSE_FILTER_STOP
		grid.add_child(sl)
		grid.add_child(UI.label("%.1f" % have))
		var bb := UI.hbox(2)
		if buy >= 0:
			for n in [1, 10, 100]:
				var amount: int = n
				var id: String = cid
				bb.add_child(UI.button("+%d" % n, func(): _buy(id, amount)))
		grid.add_child(bb)
		var sb := UI.hbox(2)
		if have > 0.0:
			var id2: String = cid
			sb.add_child(UI.button("−1", func(): _sell(id2, 1.0)))
			sb.add_child(UI.button("All", func(): _sell(id2, -1.0)))
		grid.add_child(sb)


const FILTERS := [["local", "Local economy"], ["hold", "In hold"], ["goods", "Goods"], ["metallic", "Metallic"], ["stony", "Stony"], ["icy", "Icy"], ["all", "All"]]
static var filter := "local"


## Q / E (0.5.28.2): the previous / next filter.
func menu_tab(step: int) -> void:
	var i := 0
	for k in FILTERS.size():
		if FILTERS[k][0] == filter:
			i = k
	_set_filter(String(FILTERS[posmod(i + step, FILTERS.size())][0]))


func _set_filter(key: String) -> void:
	filter = key
	build()


func _matches(cid: String, f: ShipFitting, t: Dictionary) -> bool:
	var c: Dictionary = GameData.commodities[cid]
	match filter:
		"local":
			return cid in t["produces"] or cid in t["consumes"] or float(f.cargo.get(cid, 0.0)) > 0.0
		"hold":
			return float(f.cargo.get(cid, 0.0)) > 0.0
		"goods":
			return not c.get("category", "") in ["ore", "refined"]
		"metallic", "stony", "icy":
			return c.get("class", "") == filter
	return true


func _buy(cid: String, n: int) -> void:
	run({"type": "market_buy", "item": cid, "amount": n})


func _sell(cid: String, n: float) -> void:
	run({"type": "market_sell", "item": cid, "amount": n})
