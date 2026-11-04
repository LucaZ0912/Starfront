extends StationServicePanel
## Refinery (Crucible Metallurgy Combine): turns ore and ice in the cargo hold into refined material.
## Efficiency depends on the station type and the asteroid class (metallic / stony / icy).


func build() -> void:
	UI.clear(self)
	if no_ship():
		return
	var f := fit()
	# Efficiency per asteroid class at this station
	var eff := UI.hbox(18)
	add_child(eff)
	eff.add_child(UI.label("Efficiency here:", 13, UI.TEXT_DIM))
	for cls in ["metallic", "stony", "icy"]:
		var y := Industry.refinery_yield(station, cls)
		eff.add_child(UI.label("%s %s" % [GameData.CLASS_NAMES[cls], ("%d%%" % int(y * 100.0)) if y > 0.0 else "–"], 13, corp_color() if y > 0.0 else UI.TEXT_DIM))
	add_child(UI.label("Mining colonies refine metallic and stony ore best; agricultural stations only process ice.", 12, UI.TEXT_DIM))
	cargo_line()
	var have_any := false
	var total_fee := 0
	for ore in Industry.ores():
		var have := floorf(float(f.cargo.get(ore, 0.0)))
		if have < 1.0:
			continue
		have_any = true
		var c: Dictionary = GameData.commodities[ore]
		var y := Industry.ore_yield(station, ore)
		var row := UI.hbox(16)
		add_child(row)
		row.add_child(UI.icon(PixelArt.asteroid_texture(7, 18, ore), 40))
		var info := UI.vbox(1)
		info.custom_minimum_size = Vector2(470, 0)
		row.add_child(info)
		info.add_child(UI.label("%s  →  %s" % [GameData.item_name(ore), GameData.item_name(c["refines_to"])], 15, corp_color()))
		info.add_child(UI.label("%s  •  %s  •  base yield %.0f%% × station %.0f%%  •  in hold: %d" % [GameData.CLASS_NAMES[c["class"]], String(c["rarity"]).capitalize(), float(c["yield"]) * 100.0, Industry.refinery_yield(station, c["class"]) * 100.0, int(have)], 12, UI.TEXT_DIM))
		if y <= 0.0:
			row.add_child(UI.label("Cannot be processed here", 13, UI.BAD))
			continue
		var q := Industry.refine_quote(station, ore, have)
		total_fee += int(q["fee"])
		row.add_child(UI.label("→ %d %s   fee %s" % [int(q["out"]), GameData.item_name(q["out_id"]), GameData.fmt_credits(int(q["fee"]))], 14, UI.GOOD))
		var id: String = ore
		row.add_child(UI.button("Refine", func(): _refine(id)))
	if not have_any:
		add_child(UI.label("No ore or ice in the cargo hold. Mine asteroids and come back.", 13, UI.TEXT_DIM))
	elif total_fee > 0:
		add_child(UI.button("Refine everything possible (%s)" % GameData.fmt_credits(total_fee), _refine_all))


func _refine(ore: String) -> void:
	run({"type": "refine", "ore": ore})


func _refine_all() -> void:
	for ore in Industry.ores():
		if floorf(float(fit().cargo.get(ore, 0.0))) >= 1.0 and Industry.ore_yield(station, ore) > 0.0:
			Commands.execute({"type": "refine", "ore": ore})
	refresh_all()
