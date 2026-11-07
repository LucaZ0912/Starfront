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
