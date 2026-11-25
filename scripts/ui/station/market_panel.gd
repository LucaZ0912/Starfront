extends StationServicePanel
## Market (Kessler-Vance Exchange): buy and sell commodities with the ship's cargo hold.
## Package 42b: every good has a stock – green = made here (cheap, plenty), gold = wanted here (dear, little in
## stock); selling fills the stock and lowers the price, buying empties it and raises it; stocks drift back over time.
## Window rework (Luz, 18 Nov 2026): one line on top (economy, made / wanted, standing, the cargo hold as a bar), the
## filters in one row (local trade, the hold, all; category and economy as drop-downs), the goods on the left as a
## list, the picked good on the right – both prices, the stock, the hold, the best price nearby (perk), and buying and
## selling with a slider and a number instead of +1 / +10 / +100.

const COL_W := [86, 76, 76, 70, 62]          # stock, buy, sell, in hold, volume


## How many of the value columns the list shows: all five; in a narrow picture stock, buy and sell (what is in your
## hold and a unit's volume stand in the card beside the list), so that the names stay readable.
func _cols() -> int:
	return 3 if UI.narrow(self) else 5
const NAME_ROLE := {"produce": "made here", "consume": "wanted"}

static var FILTERS: Array = _make_filters()
static var filter := "local"
static var pick := ""
static var _order: Array = []

var _rows := {}                 # cid -> its row button
var _card: VBoxContainer
var _buy_n := 0
var _sell_n := 0


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


static func _sector_text(cid: String) -> String:
	var e := Market.econ_of(cid)
	return "%s  •  made by %s systems" % [Market.category_name(Market.category_of(cid)), Economy.name_of(e)] if e != "" else Market.category_name(Market.category_of(cid))


func build() -> void:
	UI.clear(self)
	_rows.clear()
	if no_ship():
		return
	var f := fit()
	var col := corp_color()
	_head(f)
	_filters(col)
	var goods: Array = []
	for cid in _sorted_goods():
		if _matches(cid, f):
			goods.append(cid)
	if not pick in goods:
		pick = goods[0] if not goods.is_empty() else ""
	var sh := get_viewport().get_visible_rect().size.y
	var h := clampf(sh - 352.0 - maxf(sh - 720.0, 0.0) * 0.25, 220.0, 900.0)         # the list fills the window
	var main := UI.hbox(12)
	main.custom_minimum_size = Vector2(0, h)
	add_child(main)
	_list(main, goods, f, col, h)
	var cbox := UI.neon_panel(Color(col, 0.7), Color(col.darkened(0.88), 0.85), 1)
	cbox.custom_minimum_size = Vector2(clampf(get_viewport().get_visible_rect().size.x * 0.27, 330.0, 470.0), 0)
	main.add_child(cbox)
	var cs := ScrollContainer.new()
	cs.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cbox.add_child(cs)
	_card = UI.vbox(10)
	_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cs.add_child(_card)
	_show_card()
	add_child(UI.label("A click or W / S picks a good  •  Q / E the next filter", 11, UI.TEXT_DIM))


func _head(f: ShipFitting) -> void:
	var sid := Market.system_of(station)
	var made := 0
	var wanted := 0
	for cid in GameData.commodities:
		if Market.on_market(cid):
			match Market.role(station, cid):
				"produce":
					made += 1
				"consume":
					wanted += 1
	var head := UI.hbox(16)
	add_child(head)
	head.add_child(UI.label("Economy: %s  •  %s" % [Economy.label(sid), Economy.level_name(sid)], 14, Economy.color_of(String(Economy.of(sid)["main"]))))
	head.add_child(UI.label("%d made here" % made, 13, UI.GOOD))
	head.add_child(UI.label("%d wanted here" % wanted, 13, UI.GOLD))
	var fac := String(station.get("faction", ""))
	var stl := UI.label(GameState.rep.price_note(fac), 12, GameState.rep.tier(fac)["color"] if fac != "" else UI.TEXT_DIM)
	stl.clip_text = true
	stl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	head.add_child(stl)
	var cmax := maxf(float(f.stats()["cargo_max"]), 1.0)
	head.add_child(UI.label("Cargo hold", 12, UI.TEXT_DIM))
	var bar := UI.bar(UI.NEON_CYAN, 160)
	bar.max_value = cmax
	bar.value = f.cargo_used()
	bar.custom_minimum_size = Vector2(160, 8)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(bar)
	head.add_child(UI.label("%.0f / %.0f m³" % [f.cargo_used(), cmax], 13))


func _filters(col: Color) -> void:
	var row := UI.hbox(8)
	add_child(row)
	for spec in FILTERS.slice(0, 3):
		var key := String(spec[0])
		var b := UI.button(String(spec[1]), func(): _set_filter(key))
		b.toggle_mode = true
		b.button_pressed = filter == key
		if filter == key:
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(col, 0.35)
			sb.border_color = col
			sb.set_border_width_all(1)
			sb.content_margin_left = 10
			sb.content_margin_right = 10
			for st in ["normal", "hover", "focus", "pressed"]:
				b.add_theme_stylebox_override(st, sb)
		row.add_child(b)
	row.add_child(UI.label("   Category", 12, UI.TEXT_DIM))
	row.add_child(_drop("cat:", "All categories"))
	row.add_child(UI.label("Made by", 12, UI.TEXT_DIM))
	row.add_child(_drop("econ:", "Any economy"))


## A drop-down over the filters starting with `prefix`; picking one sets the filter.
func _drop(prefix: String, none: String) -> OptionButton:
	var ob := OptionButton.new()
	ob.add_theme_font_size_override("font_size", 13)
	ob.add_item(none)
	var keys: Array = [""]
	for spec in FILTERS:
		if String(spec[0]).begins_with(prefix):
			ob.add_item(String(spec[1]))
			keys.append(String(spec[0]))
	ob.select(maxi(keys.find(filter), 0))
	ob.item_selected.connect(func(i): _set_filter(keys[i] if i > 0 else "all"))
	return ob


func _list(parent: Control, goods: Array, f: ShipFitting, col: Color, h: float) -> void:
	var box := UI.neon_panel(Color(1, 1, 1, 0.12), Color(0.02, 0.02, 0.05, 0.6), 1)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(box)
	var v := UI.vbox(0)
	box.add_child(v)
	var hdr := UI.hbox(8)
	v.add_child(hdr)
	var hn := UI.label("  Commodity", 12, col)
	hn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(hn)
	var ht := ["Stock", "Buy", "Sell", "In hold", "m³"]
	for i in _cols():
		var l := UI.label(ht[i], 12, col)
		l.custom_minimum_size.x = COL_W[i]
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hdr.add_child(l)
	hdr.add_child(_gap())
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.custom_minimum_size = Vector2(0, h - 34.0)
	v.add_child(sc)
	var lv := UI.vbox(1)
	lv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(lv)
	if goods.is_empty():
		lv.add_child(UI.label("  Nothing here in this filter.", 13, UI.TEXT_DIM))
	var last_cat := "-"
	var picked: Control = null
	for cid in goods:
		var cat := Market.category_of(cid)
		if cat != last_cat:
			last_cat = cat
			lv.add_child(UI.label("  " + (Market.category_name(cat).to_upper() if cat != "" else "OTHER"), 11, Color(0.55, 0.75, 1.0)))
		var row := _row(cid, f, col)
		lv.add_child(row)
		if cid == pick:
			picked = row
	if picked != null:
		sc.ready.connect(func(): sc.ensure_control_visible.call_deferred(picked), CONNECT_ONE_SHOT)


func _gap() -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(6, 0)
	return c


func _row(cid: String, f: ShipFitting, col: Color) -> Button:
	var c: Dictionary = GameData.commodities[cid]
	var role := Market.role(station, cid)
	var stk := Market.stock(station, cid)
	var ub := Market.buy_price(station, cid)
	var buy := buy_price(ub) if ub >= 0 else -1
	var sell := int(round(sell_price(Market.sell_price(station, cid))))
	var have := float(f.cargo.get(cid, 0.0))
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 28)
	b.focus_mode = Control.FOCUS_ALL
	b.tooltip_text = "%s  •  %.1f m³ per unit" % [_sector_text(cid), float(c["volume"])]
	b.pressed.connect(func(): _pick(cid))
	b.focus_entered.connect(func(): if pick != cid: _pick(cid))
	UI.click_sound(b)
	_style_row(b, cid == pick, col)
	var r := UI.hbox(8)
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(r)
	var name_col := UI.GOOD if role == "produce" else (UI.GOLD if role == "consume" else Color(0.9, 0.93, 1.0))
	var nl := UI.label("  " + String(c["name"]), 14, name_col)
	nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nl.clip_text = true
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_child(nl)
	if NAME_ROLE.has(role):
		var bd := UI.label(" %s " % NAME_ROLE[role], 10, name_col)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(name_col, 0.06)
		sb.border_color = Color(name_col, 0.8)
		sb.set_border_width_all(1)
		bd.add_theme_stylebox_override("normal", sb)
		bd.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bd.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.add_child(bd)
	var vals: Array = [
		["%d" % int(floor(stk)), Color(0.85, 0.9, 1.0) if stk >= 1.0 else UI.TEXT_DIM],
		[GameData.fmt_credits(buy) if buy >= 0 else "–", Color(1.0, 0.8, 0.5) if buy >= 0 else UI.TEXT_DIM],
		[GameData.fmt_credits(sell), UI.GOOD],
		["%.0f" % have if have >= 1.0 or have == 0.0 else "%.1f" % have, Color(0.9, 0.93, 1.0) if have > 0.0 else UI.TEXT_DIM],
		["%.1f" % float(c["volume"]), UI.TEXT_DIM]]
	for i in _cols():
		var l := UI.label(String(vals[i][0]), 13, vals[i][1])
		l.custom_minimum_size.x = COL_W[i]
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.add_child(l)
	r.add_child(_gap())
	_rows[cid] = b
	return b


func _style_row(b: Button, on: bool, col: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(col, 0.16) if on else Color(1, 1, 1, 0.0)
	sb.border_color = col
	sb.border_width_left = 3 if on else 0
	var hv := sb.duplicate()
	hv.bg_color = Color(col, 0.22) if on else Color(1, 1, 1, 0.05)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", hv)
	b.add_theme_stylebox_override("focus", hv)
	b.add_theme_stylebox_override("pressed", hv)


func _pick(cid: String) -> void:
	var old := pick
	pick = cid
	if _rows.has(old) and is_instance_valid(_rows[old]):
		_style_row(_rows[old], false, corp_color())
	if _rows.has(cid):
		_style_row(_rows[cid], true, corp_color())
	_show_card()


# ---- the picked good

## How many units can be bought now (stock, cargo space, credits).
func max_buy(cid: String) -> int:
	var f := fit()
	if Market.buy_price(station, cid) < 0:
		return 0
	var n := mini(int(floor(f.free_for(cid) / GameData.item_volume(cid))), int(floor(Market.stock(station, cid))))
	while n > 0 and _quote_buy(cid, n) > GameState.credits:
		n -= maxi(1, n / 8)
	return maxi(n, 0)


func _quote_buy(cid: String, n: int) -> int:
	if n <= 0:
		return 0
	return maxi(int(round(buy_price(Market.quote_buy(station, cid, n)) * (1.0 - GameState.skill_bonus("trading") * 0.5))), 1)


func _quote_sell(cid: String, n: float) -> int:
	if n <= 0.0:
		return 0
	return int(round(sell_price(Market.quote_sell(station, cid, n)) * (1.0 + GameState.skill_bonus("trading") * 0.5)))


func _show_card() -> void:
	if _card == null:
		return
	UI.clear(_card)
	if pick == "":
		_card.add_child(UI.label("Pick a good on the left.", 14, UI.TEXT_DIM))
		return
	var cid := pick
	var f := fit()
	var c: Dictionary = GameData.commodities[cid]
	var role := Market.role(station, cid)
	var name_col := UI.GOOD if role == "produce" else (UI.GOLD if role == "consume" else Color(0.9, 0.93, 1.0))
	_card.add_child(UI.label(String(c["name"]), 24, name_col))
	var sub := UI.label(_sector_text(cid) + ({"produce": "  •  made here: cheap, plenty in stock", "consume": "  •  wanted here: dear, little in stock"}.get(role, "")), 12, UI.TEXT_DIM)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card.add_child(sub)
	if Market.is_flag(cid, "lux"):
		_card.add_child(UI.label("Luxury: wanted in wealthy and rich systems", 12, UI.GOLD))
	if Market.is_flag(cid, "basic"):
		_card.add_child(UI.label("Needed everywhere", 12, UI.TEXT_DIM))
	# both prices
	var ub := Market.buy_price(station, cid)
	var buy := buy_price(ub) if ub >= 0 else -1
	var sell := int(round(sell_price(Market.sell_price(station, cid))))
	var pr := UI.hbox(8)
	_card.add_child(pr)
	pr.add_child(_price_box("You buy at", GameData.fmt_credits(buy) if buy >= 0 else "none in stock", Color(1.0, 0.8, 0.5)))
	pr.add_child(_price_box("You sell at", GameData.fmt_credits(sell), UI.GOOD))
	# stock, hold, volume, best nearby
	var stk := Market.stock(station, cid)
	var tgt := float(Market.info(station, cid)["target"])
	var have := float(f.cargo.get(cid, 0.0))
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 14)
	_card.add_child(g)
	g.add_child(UI.label("Stock", 13, UI.TEXT_DIM))
	var sv := UI.vbox(2)
	g.add_child(sv)
	sv.add_child(UI.label("%d units" % int(floor(stk)), 13))
	var sbar := UI.bar(name_col if role != "neutral" else UI.TEXT_DIM, 180)
	sbar.max_value = maxf(tgt, 1.0)
	sbar.value = minf(stk, tgt)
	sbar.custom_minimum_size = Vector2(180, 5)
	sv.add_child(sbar)
	g.add_child(UI.label("In your hold", 13, UI.TEXT_DIM))
	g.add_child(UI.label("%.1f units  •  %.1f m³" % [have, have * GameData.item_volume(cid)], 13))
	g.add_child(UI.label("Per unit", 13, UI.TEXT_DIM))
	g.add_child(UI.label("%.1f m³" % GameData.item_volume(cid), 13))
	if GameState.has_perk("market_insider"):
		var nb: Array = GameState.best_nearby_sell(cid)
		g.add_child(UI.label("Best nearby", 13, UI.TEXT_DIM))
		g.add_child(UI.label(("%s at %s (%s)" % [GameData.fmt_credits(int(nb[0])), nb[1], nb[2]]) if not nb.is_empty() else "nothing better next door", 13, UI.GOOD))
	# buy
	var mb := max_buy(cid)
	_buy_n = clampi(_buy_n if _buy_n > 0 else mini(mb, 10), 0, mb)
	_trade_block("BUY", mb, _buy_n, Color(1.0, 0.8, 0.5), func(n): _buy_n = n,
		func(n): return "%d × %s = %s" % [n, GameData.fmt_credits(buy) if buy >= 0 else "–", GameData.fmt_credits(_quote_buy(cid, n))],
		func(n): return "Buy %d" % n, func(): _buy(cid, _buy_n), "Max %d" % mb,
		"Max is what the stock, your credits and the free cargo space allow." if mb > 0 else ("Nothing in stock." if buy < 0 else "No room in the hold, or not enough credits."))
	# sell
	var ms := int(floor(have + 0.0001))
	_sell_n = clampi(_sell_n if _sell_n > 0 else ms, 0, ms)
	_trade_block("SELL", ms, _sell_n, UI.GOOD, func(n): _sell_n = n,
		func(n): return "%d × %s = %s" % [n, GameData.fmt_credits(sell), GameData.fmt_credits(_quote_sell(cid, float(n)))],
		func(n): return "Sell %d" % n, func(): _sell(cid, float(_sell_n) if _sell_n < ms else -1.0), "All %d" % ms,
		"" if ms > 0 else "None in your hold.")


func _price_box(key: String, val: String, col: Color) -> PanelContainer:
	var p := UI.neon_panel(Color(1, 1, 1, 0.14), Color(0, 0, 0, 0.5), 1)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UI.vbox(0)
	p.add_child(v)
	v.add_child(UI.label(key.to_upper(), 11, UI.TEXT_DIM))
	v.add_child(UI.label(val, 22, col))
	return p


## A buy or sell block: a slider with a number, the total, the button; `set_n(n)` keeps the amount, `total(n)` and
## `btn_text(n)` give the texts, `go` runs it; the max button jumps to `mx`.
func _trade_block(title: String, mx: int, n0: int, col: Color, set_n: Callable, total: Callable, btn_text: Callable, go: Callable, max_text: String, note: String) -> void:
	var line := ColorRect.new()
	line.color = Color(1, 1, 1, 0.1)
	line.custom_minimum_size = Vector2(0, 1)
	_card.add_child(line)
	_card.add_child(UI.label(title, 12, UI.TEXT_DIM))
	var sr := UI.hbox(8)
	_card.add_child(sr)
	var sl := HSlider.new()
	sl.min_value = 0
	sl.max_value = maxi(mx, 1)
	sl.step = 1
	sl.value = n0
	sl.editable = mx > 0
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sr.add_child(sl)
	var sp := SpinBox.new()
	sp.min_value = 0
	sp.max_value = maxi(mx, 0)
	sp.value = n0
	sp.editable = mx > 0
	sp.custom_minimum_size = Vector2(84, 0)
	sr.add_child(sp)
	var mxb := UI.button(max_text, func(): sl.value = mx)
	mxb.disabled = mx <= 0
	sr.add_child(mxb)
	var tr := UI.hbox(8)
	_card.add_child(tr)
	var tl := UI.label(total.call(n0), 13, col)
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tl.clip_text = true
	tr.add_child(tl)
	var gb := UI.button(btn_text.call(n0), go)
	gb.disabled = mx <= 0 or n0 <= 0
	tr.add_child(gb)
	var sync := func(v: float):
		var n := int(v)
		set_n.call(n)
		if int(sl.value) != n:
			sl.set_value_no_signal(n)
		if int(sp.value) != n:
			sp.set_value_no_signal(n)
		tl.text = total.call(n)
		gb.text = btn_text.call(n)
		gb.disabled = mx <= 0 or n <= 0
	sl.value_changed.connect(sync)
	sp.value_changed.connect(sync)
	if note != "":
		var nl := UI.label(note, 11, UI.TEXT_DIM)
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_card.add_child(nl)


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
	ui.tame(self)


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
	_buy_n = 0
	run({"type": "market_buy", "item": cid, "amount": n})


func _sell(cid: String, n: float) -> void:
	_sell_n = 0
	run({"type": "market_sell", "item": cid, "amount": n})
