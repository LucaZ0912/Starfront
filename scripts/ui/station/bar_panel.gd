extends StationServicePanel
## Package 31: The Bar (Driftwood Taverns) – for now the place to hire crew; part 7 makes it much more.
## The offers change every 20 minutes of play; the station type decides which professions turn up most.
## Hire into the crew quarters of the station, or straight into a free post of the docked ship.

const CrewCard = preload("res://scripts/ui/crew_card.gd")
const CrewData = preload("res://data/crew.gd")
const CrewCore = preload("res://scripts/core/crew.gd")


func build() -> void:
	UI.clear(self)
	if no_ship():
		return
	var f := fit()
	var offers: Array = GameState.bar_offers(station)
	var left := CrewData.BAR_REFRESH - (GameState.play_time - float(GameState.bar.get(String(station["id"]), {}).get("t", 0.0)))
	add_child(UI.wrap_label("Captains find their crews over a glass. Everyone here is looking for a post – hire them into the crew quarters of this station or straight onto a free post of the %s. The faces change in about %d minutes." % [f.ship_name, int(ceil(left / 60.0))], 13, UI.TEXT_DIM, 1100))
	var miss := f.crew_missing()
	if miss != "":
		add_child(UI.label("Your %s still needs: %s" % [f.ship_name, miss], 13, UI.BAD))
	add_child(UI.label("Waiting in the crew quarters here: %d   •   Balance %s" % [GameState.quarters_of(String(station["id"])).size(), GameData.fmt_credits(GameState.credits)], 13, UI.GOLD))
	section("AT THE BAR TONIGHT")
	if offers.is_empty():
		add_child(UI.label("Nobody left looking for work. Come back later.", 13, UI.TEXT_DIM))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(grid)
	var sl := f.crew_slots()
	for i in offers.size():
		var o: Dictionary = offers[i]
		var m: Dictionary = o["m"]
		var idx := i
		var price := int(o["price"])
		var free_post := false
		for k in sl.size():
			if f.crew_at(k).is_empty() and CrewCore.fits(m, String(sl[k][0])):
				free_post = true
		var poor := GameState.credits < price
		var te := GameState.crew_role_error(String(m["role"]))
		grid.add_child(CrewCard.card(m, [
			["Hire – %s" % GameData.fmt_credits(price), func(): run({"type": "crew_hire", "index": idx}), poor, "Into the crew quarters of this station"],
			["Hire onto the %s" % f.ship_name, func(): run({"type": "crew_hire", "index": idx, "ship": f.uid}), poor or not free_post or te != "",
				te if te != "" else ("" if free_post else "No free %s post on this ship" % CrewData.role_name(String(m["role"])))],
		], "", UI.TEXT_DIM, 540))
	_wingmen()                                   # package 33


# ---- package 33: pilots for hire (wingmen) and the contracts that run

const WingData = preload("res://data/wingmen.gd")
const PilotArt = preload("res://scripts/core/pilot_art.gd")


func _wingmen() -> void:
	section("PILOTS FOR HIRE – WINGMEN")
	var he := GameState.wing_hire_error()
	add_child(UI.wrap_label("A wingman flies with you in their own ship until the contract runs out: up front the price for the time, then a share of your income (sales, bounties, contract rewards). Orders in the WINGMEN panel at the top left. Leadership makes them better and cheaper.", 13, UI.TEXT_DIM, 1100))
	if he != "":
		add_child(UI.label(he, 13, UI.BAD))
	var pilots: Array = GameState.bar_pilots(station)
	if pilots.is_empty():
		add_child(UI.label("No pilots looking for a contract tonight.", 13, UI.TEXT_DIM))
	for i in pilots.size():
		add_child(_pilot_card(pilots[i], i, he))
	if not GameState.wingmen.is_empty():
		section("YOUR WINGMEN")
		for c in GameState.wingmen:
			add_child(_contract_card(c))


func _pilot_card(w: Dictionary, idx: int, he: String) -> Control:
	var lc: Color = WingData.level_color(String(w["level"]))
	var p := UI.neon_panel(Color(lc, 0.55), Color(0.04, 0.05, 0.09, 0.96), 1)
	var row := UI.hbox(12)
	p.add_child(row)
	row.add_child(UI.icon(PilotArt.portrait(w["look"]), 72))
	var v := UI.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(v)
	var nr := UI.hbox(8)
	v.add_child(nr)
	nr.add_child(UI.label(String(w["name"]), 16, Color(0.95, 0.96, 1.0)))
	nr.add_child(UI.label("%s · %s" % [w["level"], WingData.LEVEL_NAMES[String(w["level"])]], 13, lc))
	v.add_child(UI.label("Piloting %d (+%d %% speed)   •   Gunnery %d (+%d %% damage)" % [int(w["skills"]["piloting"]), int(w["skills"]["piloting"]), int(w["skills"]["gunnery"]), int(w["skills"]["gunnery"])], 12, UI.NEON_CYAN))
	var tr: Array = []
	for t in w["traits"]:
		tr.append("%s – %s" % [WingData.TRAITS[t]["name"], WingData.TRAITS[t]["text"]])
	v.add_child(UI.wrap_label("★ " + "\n★ ".join(PackedStringArray(tr)), 12, UI.GOLD, 620))
	v.add_child(UI.label("Share of your income: %d %%" % int(round(float(WingData.SHARE[String(w["level"])]) * (1.0 - GameState.wing_leadership()) * 100.0)), 12, UI.TEXT_DIM))
	# the ship and its loadout
	var sv := UI.vbox(2)
	sv.custom_minimum_size = Vector2(300, 0)
	row.add_child(sv)
	var sd: Dictionary = w["ship"]
	var sr := UI.hbox(8)
	sv.add_child(sr)
	sr.add_child(UI.icon(PixelArt.ship_texture(String(sd["hull_id"]), "player"), 44))
	var h: Dictionary = GameData.hulls[String(sd["hull_id"])]
	var sn := UI.vbox(0)
	sr.add_child(sn)
	sn.add_child(UI.label(String(sd["ship_name"]), 13, Color(0.9, 0.95, 1.0)))
	sn.add_child(UI.label("%s %s (%s)" % [h["class"], h["name"], GameData.SIZE_NAMES[int(h["size"])]], 11, UI.TEXT_DIM))
	var mods: Array = []
	for k in sd["modules"]:
		if not String(k) in GameData.CORE_SLOTS:
			mods.append(GameData.module_name(String(sd["modules"][k])))
	sv.add_child(UI.wrap_label("Loadout: " + (", ".join(PackedStringArray(mods)) if not mods.is_empty() else "core modules only"), 11, UI.TEXT_DIM, 300))
	var core: Array = []
	for k2 in ["engine", "reactor", "sensors"]:
		if sd["modules"].has(k2):
			core.append(GameData.module_name(String(sd["modules"][k2])))
	sv.add_child(UI.wrap_label("Core: " + ", ".join(PackedStringArray(core)), 11, UI.TEXT_DIM, 300))
	# the contract lengths
	var bv := UI.vbox(4)
	row.add_child(bv)
	for d in WingData.DURATIONS:
		var minutes := int(d[0])
		var price := GameState.wing_price(w, minutes)
		var b := UI.button("%d min – %s" % [minutes, GameData.fmt_credits(price)], func(): run({"type": "wing_hire", "index": idx, "minutes": minutes}))
		b.disabled = he != "" or GameState.credits < price
		b.tooltip_text = he
		bv.add_child(b)
	return p


func _contract_card(c: Dictionary) -> Control:
	var w: Dictionary = c["w"]
	var p := UI.neon_panel(Color(WingData.level_color(String(w["level"])), 0.4), Color(0.04, 0.05, 0.09, 0.96), 1)
	var row := UI.hbox(12)
	p.add_child(row)
	row.add_child(UI.icon(PilotArt.portrait(w["look"]), 48))
	var left := maxf(0.0, float(c["until"]) - GameState.play_time)
	row.add_child(UI.label("%s (%s) – %s – %d:%02d left" % [w["name"], w["level"], w["ship"]["ship_name"], int(left) / 60, int(left) % 60], 14))
	row.add_child(UI.spacer())
	var id := int(w["id"])
	for d in WingData.DURATIONS:
		var minutes := int(d[0])
		var price := GameState.wing_price(w, minutes)
		var b := UI.button("+%d min – %s" % [minutes, GameData.fmt_credits(price)], func(): run({"type": "wing_extend", "id": id, "minutes": minutes}))
		b.disabled = GameState.credits < price
		row.add_child(b)
	row.add_child(UI.button("End contract", func(): run({"type": "wing_dismiss", "id": id})))
	return p
