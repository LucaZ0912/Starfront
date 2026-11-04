extends StationServicePanel
## Shipyard (Hadal Orbital Yards): buy hulls, bare or with the standard fit.
## New ships are delivered to the hangar of this station.


func build() -> void:
	UI.clear(self)
	standing_line()
	for hid in station["shipyard"]:
		var h: Dictionary = GameData.hulls[hid]
		var box := UI.neon_panel(Color(corp_color(), 0.5), Color(0.04, 0.05, 0.1, 0.9), 1)
		add_child(box)
		var row := UI.hbox(18)
		box.add_child(row)
		var ic := UI.icon(PixelArt.ship_texture(hid, "player"), 96)
		ic.custom_minimum_size = Vector2(150, 80)
		row.add_child(ic)
		var info := UI.vbox(2)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		info.add_child(UI.label("%s – %s (size %s)" % [h["name"], h["class"], GameData.SIZE_NAMES[int(h["size"])]], 17, corp_color()))
		info.add_child(UI.label(h["desc"], 12, UI.TEXT_DIM))
		var sl: Dictionary = h["slots"]
		info.add_child(UI.label("Structure %d  •  Mass %d t  •  Cargo %d m³  •  Slots: %d weapons, %d tools, %d optional" % [
			int(h["structure"]), int(h["mass"]), int(h["cargo"]), int(sl.get("weapon", 0)), int(sl.get("tool", 0)), int(sl.get("optional", 0))], 12))
		var id: String = hid
		row.add_child(UI.button("Bare hull\n%s" % GameData.fmt_credits(buy_price(int(h["price"]))), func(): _buy(id, false)))
		var preset: String = "std_" + hid
		if GameData.presets.has(preset):
			row.add_child(UI.button("Standard fit\n%s" % GameData.fmt_credits(buy_price(GameData.preset_price(preset))), func(): _buy(id, true)))


func _buy(hid: String, with_fit: bool) -> void:
	run({"type": "ship_buy", "hull": hid, "fitted": with_fit})
