extends StationServicePanel
## Market (Kessler-Vance Exchange): buy and sell commodities with the ship's cargo hold.
## Package 42b: every good has a stock – green = made here (cheap, plenty), gold = wanted here (dear, little in
## stock); selling fills the stock and lowers the price, buying empties it and raises it; stocks drift back over time.


func build() -> void:
	UI.clear(self)
	if no_ship():
		return
	var f := fit()
	var sid := Market.system_of(station)
	var made: Array = []
	var wanted: Array = []
	for cid in GameData.commodities:
		if not Market.on_market(cid):
			continue
		match Market.role(station, cid):
			"produce":
				made.append(GameData.item_name(cid))
			"consume":
				wanted.append(GameData.item_name(cid))
	var head := UI.hbox(10)
	add_child(head)
	head.add_child(UI.label("Economy: %s  •  %s" % [Economy.label(sid), Economy.level_name(sid)], 14, Economy.color_of(String(Economy.of(sid)["main"]))))
	head.add_child(UI.label("Made here: %d goods  •  wanted here: %d" % [made.size(), wanted.size()], 13, UI.TEXT_DIM))
	var mw := UI.label("Made here: %s\nWanted here: %s" % [_short(made), _short(wanted)], 12, UI.TEXT_DIM)
	mw.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mw.custom_minimum_size = Vector2(900, 0)
	add_child(mw)
	standing_line()
	cargo_line()
	# Filters: local trade, the hold, all – the sixteen categories – the nine economies
	var tabs := UI.hbox(4)
	add_child(tabs)
	var tabs_c := HFlowContainer.new()
	tabs_c.add_theme_constant_override("h_separation", 3)
	tabs_c.add_theme_constant_override("v_separation", 3)
	add_child(tabs_c)
	var tabs2 := UI.hbox(3)
	add_child(tabs2)
	for spec in FILTERS:
		var key: String = spec[0]
		var b := UI.button(spec[1], func(): _set_filter(key))
		b.toggle_mode = true
		b.button_pressed = filter == key
		if key.begins_with("econ:"):
			b.add_theme_font_size_override("font_size", 12)
			b.add_theme_color_override("font_color", Economy.color_of(key.substr(5)))
			b.tooltip_text = "Goods of %s systems" % Economy.name_of(key.substr(5))
			tabs2.add_child(b)
		elif key.begins_with("cat:"):
			b.add_theme_font_size_override("font_size", 12)
			tabs_c.add_child(b)
		else:
			tabs.add_child(b)
	var grid := GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 5)
	add_child(grid)
	for h in ["Commodity", "", "Stock", "Buy", "Sell", "In hold", "Buy", "Sell"]:
		grid.add_child(UI.label(h, 13, corp_color()))
	var rows := 0
	var last_cat := "-"
	for cid in _sorted_goods():
		if not _matches(cid, f):
			continue
		rows += 1
		var cat := Market.category_of(cid)
		if cat != last_cat:
			# a heading per category
			last_cat = cat
			grid.add_child(UI.label(Market.category_name(cat).to_upper() if cat != "" else "OTHER", 12, Color(0.55, 0.75, 1.0)))
			for _i in 7:
				grid.add_child(Control.new())
		var c: Dictionary = GameData.commodities[cid]
		var role := Market.role(station, cid)
		var stk := Market.stock(station, cid)
		var ub := Market.buy_price(station, cid)
		var buy := buy_price(ub) if ub >= 0 else -1
		var sell := int(round(sell_price(Market.sell_price(station, cid))))
		var have := float(f.cargo.get(cid, 0.0))
		var name_col := UI.GOOD if role == "produce" else (UI.GOLD if role == "consume" else Color(0.9, 0.93, 1.0))
		var nl := UI.label(c["name"], 14, name_col)
		nl.tooltip_text = "%s  •  %.1f m³ per unit%s%s" % [_sector_text(cid), float(c["volume"]),
			"\nLuxury – wanted in wealthy and rich systems" if Market.is_flag(cid, "lux") else "",
			"\nNeeded everywhere" if Market.is_flag(cid, "basic") else ""]
		nl.mouse_filter = Control.MOUSE_FILTER_STOP
		grid.add_child(nl)
		grid.add_child(UI.label(Market.ROLE_NAMES[role], 11, name_col))
		var sl0 := UI.label("%d" % int(floor(stk)), 13, Color(0.85, 0.9, 1.0) if stk >= 1.0 else UI.TEXT_DIM)
		grid.add_child(sl0)
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
				var btn := UI.button("+%d" % n, func(): _buy(id, amount))
				btn.disabled = stk < 1.0
				bb.add_child(btn)
		grid.add_child(bb)
		var sb := UI.hbox(2)
		if have > 0.0:
			var id2: String = cid
			sb.add_child(UI.button("−1", func(): _sell(id2, 1.0)))
			sb.add_child(UI.button("All", func(): _sell(id2, -1.0)))
		grid.add_child(sb)
	if rows == 0:
		add_child(UI.label("Nothing here in this filter.", 13, UI.TEXT_DIM))


static func _short(names: Array) -> String:
	if names.is_empty():
		return "–"
	var shown := names.slice(0, 9)
	return ", ".join(PackedStringArray(shown)) + ("  … (+%d)" % (names.size() - shown.size()) if names.size() > shown.size() else "")


static func _sector_text(cid: String) -> String:
	var e := Market.econ_of(cid)
	return "%s  •  made by %s systems" % [Market.category_name(Market.category_of(cid)), Economy.name_of(e)] if e != "" else Market.category_name(Market.category_of(cid))


static var FILTERS: Array = _make_filters()
static var filter := "local"
static var _order: Array = []


static func _make_filters() -> Array:
	var out: Array = [["local", "Local trade"], ["hold", "In hold"], ["all", "All"]]
	for c in preload("res://data/commodities.gd").MARKET_CATEGORIES:
		out.append(["cat:" + String(c[0]), String(c[1])])
	for e in ["agri", "mining", "industry", "refinery", "chemistry", "hightech", "research", "military", "tourism"]:
		out.append(["econ:" + e, {"agri": "Agriculture", "mining": "Mining", "industry": "Industry", "refinery": "Refining",
			"chemistry": "Chemistry", "hightech": "High-Tech", "research": "Research", "military": "Military", "tourism": "Tourism"}[e]])
	return out


## The market's goods in category order (and in their data order inside a category).
static func _sorted_goods() -> Array:
	if _order.is_empty():
		var cats: Array = []
		for c in preload("res://data/commodities.gd").MARKET_CATEGORIES:
			cats.append(String(c[0]))
		for cat in cats + [""]:
			for cid in GameData.commodities:
				if Market.on_market(cid) and Market.category_of(cid) == cat:
					_order.append(cid)
	return _order


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


func _matches(cid: String, f: ShipFitting) -> bool:
	var c: Dictionary = GameData.commodities[cid]
	var cat := String(c.get("category", ""))
	match filter:
		"local":
			return Market.role(station, cid) != "neutral" or float(f.cargo.get(cid, 0.0)) > 0.0
		"hold":
			return float(f.cargo.get(cid, 0.0)) > 0.0
		"all":
			return true
	if filter.begins_with("cat:"):
		return Market.category_of(cid) == filter.substr(4)
	# an economy: the goods its systems make (raw materials not included)
	return not cat in ["ore", "gas", "refined", "components"] and Market.econ_of(cid) == filter.substr(5)


func _buy(cid: String, n: int) -> void:
	run({"type": "market_buy", "item": cid, "amount": n})


func _sell(cid: String, n: float) -> void:
	run({"type": "market_sell", "item": cid, "amount": n})
