extends StationServicePanel
## Package 51 (0.7.51.2): the Gear shop – the personal outfitter. Suits, weapons, features and tools by family, each
## with the qualities this shop carries (a button per quality with its price); grenades and consumables; and what is
## in your pockets, to sell (half the price). What you buy goes into your pockets – put it on in the pilot window
## (Gear tab).

const GearData = preload("res://data/gear.gd")


func build() -> void:
	var o := GearShop.offer(station)
	var g = GameState.gear
	add_child(UI.label("Personal gear – what you buy goes into your pockets (%d free); put it on in the Pilot window, Gear tab [%s]." % [g.free_places(), Keybinds.key_text("pilot_window")], 13, UI.TEXT_DIM))
	for sec in [["SUITS", GearData.SUITS], ["WEAPONS", GearData.WEAPONS], ["FEATURES", GearData.FEATURES], ["BELT", GearData.BELT]]:
		var fams: Array = []
		for f in (sec[1] as Dictionary):
			if o.has(f):
				fams.append(f)
		if fams.is_empty():
			continue
		section(String(sec[0]))
		for f2 in fams:
			add_child(_row(String(f2), o[f2]))
	section("SELL FROM YOUR POCKETS")
	var any := false
	for i in g.inv.size():
		var p: Dictionary = g.inv[i]
		if p.is_empty():
			continue
		any = true
		var id := String(p["id"])
		var each := int(round(float(GearData.price(id)) * GearShop.SELL_SHARE))
		var r := UI.hbox(8)
		r.add_child(UI.label(GearData.display_name(id) + (" ×%d" % int(p["n"]) if int(p["n"]) > 1 else ""), 14, _qcol(id)))
		r.add_child(UI.spacer())
		var idx: int = i
		r.add_child(UI.button("Sell %s" % GameData.fmt_credits(each * int(p["n"])), func(): run({"type": "gear_sell", "slot": idx})))
		add_child(r)
	if not any:
		add_child(UI.label("Nothing in your pockets.", 13, UI.TEXT_DIM))


func _row(f: String, qs: Array) -> Control:
	var b: Dictionary = GearData.base(f)
	var r := UI.hbox(6)
	var name_l := UI.label(String(b["name"]), 14, Color(0.92, 0.92, 0.9))
	name_l.custom_minimum_size = Vector2(230, 0)
	name_l.tooltip_text = "\n".join(GearData.describe(GearShop.id_of(f, String(qs[0]))))
	name_l.mouse_filter = Control.MOUSE_FILTER_STOP
	r.add_child(name_l)
	var info := UI.label(_short(f), 12, UI.TEXT_DIM)
	info.custom_minimum_size = Vector2(260, 0)
	r.add_child(info)
	r.add_child(UI.spacer())
	for q in qs:
		var id := GearShop.id_of(f, String(q))
		var price := buy_price(GearData.price(id))
		var bt := UI.button(("%s  " % q if String(q) != "" else "Buy  ") + GameData.fmt_credits(price), func(): run({"type": "gear_buy", "id": id}))
		if String(q) != "":
			bt.add_theme_color_override("font_color", GameData.quality_color(String(q)))
		bt.tooltip_text = "\n".join(GearData.describe(id))
		bt.disabled = GameState.credits < price
		r.add_child(bt)
	return r


## A short line under the name: what kind of piece it is.
func _short(f: String) -> String:
	var b: Dictionary = GearData.base(f)
	match GearData.kind(f):
		"suit":
			return "%d weapon · %d belt · %d feature" % [int(b["weapons"]), int(b["belt"]), int(b["features"])]
		"weapon":
			return "%s · %d dmg · %.1f/s" % [GearData.DAMAGE_NAMES[String(b["dtype"])], int(b["damage"]), float(b["rof"])]
		"belt":
			return {"grenade": "Grenade", "tool": "Tool", "use": "Consumable"}[String(b["kind"])]
	return String(b.get("desc", "")).left(40)


func _qcol(id: String) -> Color:
	var q := GearData.quality(id)
	return GameData.quality_color(q) if q != "" else Color(0.92, 0.92, 0.9)
