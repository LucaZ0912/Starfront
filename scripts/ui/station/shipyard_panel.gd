extends StationServicePanel
## Shipyard (Hadal Orbital Yards): buy hulls, bare or with the standard fit.
## New ships are delivered to the hangar of this station.


const MakerData = preload("res://data/manufacturers.gd")


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
		# manufacturer (package 25a)
		var mk := String(h.get("maker", ""))
		if MakerData.MAKERS.has(mk):
			var mrow := UI.hbox(6)
			info.add_child(mrow)
			mrow.add_child(UI.icon(CrestArt.maker_texture(mk), 20))
			mrow.add_child(UI.label("%s  –  \"%s\"" % [MakerData.MAKERS[mk]["name"], MakerData.MAKERS[mk]["motto"]], 12, MakerData.MAKERS[mk]["color"]))
			if mk == "khi":
				info.add_child(UI.label("Built-in refinery, ore hold %d m³, prospector  •  +10 %% mining  •  slow to turn and to warp" % int(h.get("ore_cargo", 0)), 12, Color(1.0, 0.8, 0.35)))
		info.add_child(UI.label(h["desc"], 12, UI.TEXT_DIM))
		var why_t: String = GameState.hull_standing_error(hid)       # faction ships need standing (package 25e)
		if String(h.get("min_tier", "")) != "":
			info.add_child(UI.label("Faction ship – needs %s standing" % String(h["min_tier"]).capitalize() + (("  •  " + why_t) if why_t != "" else "  ✓"), 12, UI.BAD if why_t != "" else UI.GOOD))
		var tree_e: String = GameState.hull_tree_error(hid)        # 0.5.30.2: buy freely, fly with the tile
		if tree_e != "":
			info.add_child(UI.label(tree_e.replace(" first (Pilot window).", "") + " to fly it – until then it stays docked.", 12, Color(1.0, 0.7, 0.3)))
		var sl: Dictionary = h["slots"]
		info.add_child(UI.label("Structure %d  •  Mass %d t  •  Cargo %d m³  •  Slots: %d weapons, %d tools, %d optional" % [
			int(h["structure"]), int(h["mass"]), int(h["cargo"]), int(sl.get("weapon", 0)), int(sl.get("tool", 0)), int(sl.get("optional", 0))], 12))
		var id: String = hid
		var b1 := UI.button("Bare hull\n%s" % GameData.fmt_credits(buy_price(int(h["price"]))), func(): _buy(id, false))
		b1.disabled = why_t != ""
		row.add_child(b1)
		var preset: String = "std_" + hid
		if GameData.presets.has(preset):
			var b2 := UI.button("Standard fit\n%s" % GameData.fmt_credits(buy_price(GameData.preset_price(preset))), func(): _buy(id, true))
			b2.disabled = why_t != ""
			row.add_child(b2)


func _buy(hid: String, with_fit: bool) -> void:
	run({"type": "ship_buy", "hull": hid, "fitted": with_fit})
