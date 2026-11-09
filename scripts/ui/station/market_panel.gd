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
		if not GameData.is_tradeable(cid):
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
	# Filters: local trade, the hold, raw materials, components, the nine economies, all
	var tabs := UI.hbox(4)
	add_child(tabs)
	var tabs2 := UI.hbox(3)
	add_child(tabs2)
	for spec in FILTERS:
		var key: String = spec[0]
		var b := UI.button(spec[1], func(): _set_filter(key))
		b.toggle_mode = true
		b.button_pressed = filter == key
		if Economy.ECONOMIES.has(key):
			b.add_theme_font_size_override("font_size", 12)
			b.add_theme_color_override("font_color", Economy.color_of(key))
			tabs2.add_child(b)
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
	for cid in GameData.commodities:
		if not GameData.is_tradeable(cid) or not _matches(cid, f):
			continue
		rows += 1
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
	var cat := String(GameData.commodities[cid].get("category", ""))
	match cat:
		"ore":
			return "Ore"
		"gas":
			return "Gas"
		"refined":
			return "Refined material"
		"components":
			return "Component"
	var e := Market.econ_of(cid)
	return "%s goods" % Economy.name_of(e) if e != "" else cat.capitalize()


const FILTERS := [["local", "Local trade"], ["hold", "In hold"], ["raw", "Raw materials"], ["components", "Components"], ["luxury", "Luxury"], ["all", "All"],
	["agri", "Agriculture"], ["mining", "Mining"], ["industry", "Industry"], ["refinery", "Refining"], ["chemistry", "Chemistry"],
	["hightech", "High-Tech"], ["research", "Research"], ["military", "Military"], ["tourism", "Tourism"]]
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


func _matches(cid: String, f: ShipFitting) -> bool:
	var c: Dictionary = GameData.commodities[cid]
	var cat := String(c.get("category", ""))
	match filter:
		"local":
			return Market.role(station, cid) != "neutral" or float(f.cargo.get(cid, 0.0)) > 0.0
		"hold":
			return float(f.cargo.get(cid, 0.0)) > 0.0
		"raw":
			return cat in ["ore", "gas", "refined"]
		"components":
			return cat == "components"
		"luxury":
			return Market.is_flag(cid, "lux")
		"all":
			return true
	# an economy: its goods (raw materials not included)
	return not cat in ["ore", "gas", "refined", "components"] and Market.econ_of(cid) == filter


func _buy(cid: String, n: int) -> void:
	run({"type": "market_buy", "item": cid, "amount": n})


func _sell(cid: String, n: float) -> void:
	run({"type": "market_sell", "item": cid, "amount": n})
