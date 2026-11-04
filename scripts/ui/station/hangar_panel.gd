extends StationServicePanel
## Hangar (Vaultline Storage): ships parked at this station, boarding and renaming.


func build() -> void:
	UI.clear(self)
	add_child(UI.label("Ships in this hangar – you always fly exactly one.", 13, UI.TEXT_DIM))
	for f in GameState.hangar(station["id"]):
		var fit_: ShipFitting = f
		var box := UI.neon_panel(Color(corp_color(), 0.5), Color(0.04, 0.05, 0.09, 0.9), 1)
		add_child(box)
		var row := UI.hbox(14)
		box.add_child(row)
		var ic := UI.icon(PixelArt.ship_texture(fit_.hull_id, "player"), 64)
		ic.custom_minimum_size = Vector2(120, 64)
		row.add_child(ic)
		var info := UI.vbox(2)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var s := fit_.stats()
		info.add_child(UI.label(fit_.ship_name, 16, corp_color()))
		info.add_child(UI.label("%s %s  •  DPS %.0f  •  %.0f km/s  •  Cargo %.0f m³  •  Value %s" % [fit_.hull()["class"], fit_.hull()["name"], s["dps_total"], s["speed"], s["cargo_max"], GameData.fmt_credits(GameState.ship_value(fit_))], 12, UI.TEXT_DIM))
		var rename := UI.hbox(6)
		info.add_child(rename)
		var le := LineEdit.new()
		le.text = fit_.ship_name
		le.custom_minimum_size = Vector2(260, 0)
		rename.add_child(le)
		var ruid: int = fit_.uid
		var on_rename := func(): run({"type": "rename_ship", "uid": ruid, "name": le.text})
		rename.add_child(UI.button("Rename", on_rename))
		if fit_.uid == GameState.active_uid:
			row.add_child(UI.label("▶ ACTIVE", 15, UI.GOOD))
		else:
			var uid: int = fit_.uid
			var board := func(): run({"type": "board", "uid": uid})
			row.add_child(UI.button("Board", board))
	if GameState.hangar(station["id"]).size() <= 1:
		add_child(UI.label("Buy more ships at a shipyard – Hadal Orbital Yards delivers them here.", 12, UI.TEXT_DIM))
