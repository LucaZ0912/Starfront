extends StationServicePanel
const ModuleData = preload("res://data/modules.gd")
const Kit = preload("res://scripts/ui/station/svc_kit.gd")
## Munitions Depot (Obsidian Ordnance, package 42b): ammunition for the weapons that have to be restocked – the
## mines of the mine launchers so far. What it stocks and charges follows the system's economy.
## Window rework (Luz, 18 Nov 2026): your launchers, the economy and the hold on top; the munitions as tiles on the
## left ("fits ✓" for your launchers, grey when not stocked); the picked one on the right with what it does, its price,
## what you carry, and buying and selling back with a slider as in the market.

static var pick := ""


func build() -> void:
	UI.clear(self)
	if no_ship():
		return
	var f := fit()
	var col := corp_color()
	var offer := Munitions.offer(station)
	var sid := Market.system_of(station)
	# launchers, economy, hold
	var top := UI.hbox(12)
	add_child(top)
	top.add_child(UI.label("YOUR LAUNCHERS", 12, UI.TEXT_DIM))
	var fams: Array = []
	for cid in Munitions.AMMO:
		for l in Munitions.launchers(f, cid):
			var n := GameData.module_name(String(f.modules.get(l, ""))) if f.modules.has(l) else String(l)
			if not n in fams:
				fams.append(n)
	if fams.is_empty():
		top.add_child(UI.label("none fitted (mine launchers)", 13, UI.TEXT_DIM))
	else:
		Kit.tags(top, fams, UI.GOOD)
	var eco := UI.label("Economy: %s  •  %s" % [Economy.label(sid), Economy.level_name(sid)], 12, UI.TEXT_DIM)
	eco.tooltip_text = "Military systems stock everything and sell it cheaply, industrial ones the common kinds, high-tech ones the electronic ones."
	eco.mouse_filter = Control.MOUSE_FILTER_STOP
	eco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eco.clip_text = true
	top.add_child(eco)
	Kit.cargo_bar(top, f)
	var ids: Array = Munitions.AMMO.keys()
	if not pick in ids:
		pick = ids[0]
	for cid in ids:
		if offer.has(cid) and not offer.has(pick):
			pick = cid
	var sh := get_viewport().get_visible_rect().size.y
	var h := clampf(sh - 300.0 - maxf(sh - 720.0, 0.0) * 0.25, 220.0, 900.0)
	var main := UI.hbox(12)
	add_child(main)
	var items: Array = []
	for cid in ids:
		var on_sale: bool = offer.has(cid)
		var fits := not Munitions.launchers(f, cid).is_empty()
		var glyph := Kit.MineGlyph.new(GameData.MINES.get(cid, {}).get("color", Color.WHITE))
		items.append({"node": glyph, "name": GameData.item_name(cid), "sub": (GameData.fmt_credits(buy_price(int(offer[cid]))) if on_sale else "not stocked") + "  •  %d in hold" % int(float(f.cargo.get(cid, 0.0))),
			"sub_col": Color(1.0, 0.8, 0.5) if on_sale else UI.TEXT_DIM, "note": "fits ✓" if fits else "", "note_col": UI.GOOD, "dim": not on_sale})
	Kit.grid(main, items, ids.find(pick), col, func(i): pick = ids[i]; refresh_all(), h, Vector2(160, 140))
	_card(main, f, col, h, offer)


func _card(parent: Control, f: ShipFitting, col: Color, h: float, offer: Dictionary) -> void:
	var box := UI.neon_panel(Color(col, 0.7), Color(col.darkened(0.88), 0.85), 1)
	box.custom_minimum_size = Vector2(clampf(get_viewport().get_visible_rect().size.x * 0.28, 330.0, 480.0), h)
	parent.add_child(box)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(sc)
	var v := UI.vbox(10)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(v)
	var cid := pick
	var hr := UI.hbox(12)
	v.add_child(hr)
	var g := Kit.MineGlyph.new(GameData.MINES.get(cid, {}).get("color", Color.WHITE))
	g.custom_minimum_size = Vector2(70, 70)
	hr.add_child(g)
	var hv := UI.vbox(0)
	hr.add_child(hv)
	hv.add_child(UI.label(GameData.item_name(cid), 22, col))
	var fam := String(Munitions.AMMO[cid]["for"])
	var n_l := Munitions.launchers(f, cid).size()
	hv.add_child(UI.label("for the %s  •  %s" % [ModuleData.FAMILIES.get(fam, {}).get("name", fam), ("you have %d fitted" % n_l) if n_l > 0 else "none fitted"], 12, UI.GOOD if n_l > 0 else UI.TEXT_DIM))
	if GameData.MINES.has(cid):
		var dl := UI.label(String(GameData.MINES[cid]["text"]).capitalize().left(1) + String(GameData.MINES[cid]["text"]).substr(1) + ".", 13)
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(dl)
	v.add_child(UI.label("Laid from your cargo hold; right-click the launcher's tile to pick the kind.", 11, UI.TEXT_DIM))
	var have := int(floor(float(f.cargo.get(cid, 0.0)) + 0.001))
	var on_sale: bool = offer.has(cid)
	var price := buy_price(int(offer[cid])) if on_sale else 0
	var back := int(round(float(GameData.commodities[cid]["price"]) * Munitions.BUYBACK))
	var kv := GridContainer.new()
	kv.columns = 2
	kv.add_theme_constant_override("h_separation", 14)
	v.add_child(kv)
	for e in [["Price", GameData.fmt_credits(price) if on_sale else "not stocked here", Color(1.0, 0.8, 0.5)], ["In your hold", "%d" % have, Color(0.9, 0.93, 1.0)], ["Taken back for", "%s each" % GameData.fmt_credits(back), UI.GOOD]]:
		kv.add_child(UI.label(e[0], 13, UI.TEXT_DIM))
		kv.add_child(UI.label(e[1], 13, e[2]))
	if on_sale:
		var room := int(floor(f.free_for(cid) / GameData.item_volume(cid)))
		var mx := mini(room, int(floor(float(GameState.credits) / float(maxi(price, 1)))))
		Kit.amount_block(v, "BUY", mx, mini(mx, 5), Color(1.0, 0.8, 0.5),
			func(n): return "%d × %s = %s" % [n, GameData.fmt_credits(price), GameData.fmt_credits(n * price)],
			func(n): return "Buy %d" % n, func(n): run({"type": "munitions_buy", "item": cid, "amount": n}), "Max %d" % mx,
			"" if mx > 0 else "No room in the hold, or not enough credits.")
	else:
		v.add_child(UI.label("This depot does not stock it: military systems carry every kind.", 12, UI.TEXT_DIM))
	Kit.amount_block(v, "SELL BACK", have, have, UI.GOOD,
		func(n): return "%d × %s = %s" % [n, GameData.fmt_credits(back), GameData.fmt_credits(n * back)],
		func(n): return "Sell %d" % n, func(n): run({"type": "munitions_sell", "item": cid, "amount": n if n < have else -1}), "All %d" % have,
		"" if have > 0 else "None in your hold.")
