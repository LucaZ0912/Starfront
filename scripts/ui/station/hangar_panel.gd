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
	_platform()
	if GameState.hangar(station["id"]).size() <= 1:
		add_child(UI.label("Buy more ships at a shipyard – Hadal Orbital Yards delivers them here.", 12, UI.TEXT_DIM))


## Package 33: the Citadel's launch platform – which Hadrian S ship stands on it, put one on, take it off, recall a lost one.
func _platform() -> void:
	var cit := fit()
	if cit == null or not cit.hull().get("hatches", {}).has("platform"):
		return
	section("LAUNCH PLATFORM OF THE %s" % cit.ship_name.to_upper())
	var pp := GameState.platform_pilot(cit)
	add_child(UI.label(("Platform pilot: %s (%s)" % [pp["name"], pp["quality"]]) if not pp.is_empty() else "No platform pilot – a Co-Pilot with the perk Wingman flies the platform ship (crew post in Modules → Crew).", 13, UI.GOOD if not pp.is_empty() else UI.BAD))
	if not cit.platform_ship.is_empty():
		var r := UI.hbox(12)
		add_child(r)
		r.add_child(UI.icon(PixelArt.ship_texture(String(cit.platform_ship["hull_id"]), "player"), 48))
		r.add_child(UI.label("On the platform: %s" % cit.platform_ship["ship_name"], 14))
		r.add_child(UI.button("Take it into the hangar (to fit it)", func(): run({"type": "platform_unload"})))
		return
	if not cit.platform_lost.is_empty():
		var price := GameState.platform_recall_price(cit)
		var b := UI.button("Recall the destroyed %s – %s (10 %%)" % [cit.platform_lost["ship_name"], GameData.fmt_credits(price)], func(): run({"type": "platform_rebuy"}))
		b.disabled = GameState.credits < price
		add_child(b)
	var any := false
	for f in GameState.hangar(station["id"]):
		var s: ShipFitting = f
		if s == cit or GameState.platform_hull_error(s.hull_id) != "":
			continue
		any = true
		var uid := s.uid
		add_child(UI.button("Put the %s on the platform" % s.ship_name, func(): run({"type": "platform_load", "uid": uid})))
	if not any and cit.platform_lost.is_empty():
		add_child(UI.label("Any Hadrian Dynamics S ship in this hangar can stand on the platform – fit it as you like first.", 12, UI.TEXT_DIM))
