extends StationServicePanel
## Package 51 (0.7.51.4): the Clinic (Mercy Hall) – a real room on the stations' commercial level and in the cities'
## streets. Treatment heals what is hurt (paid by the health missing); it is also where you wake: after your ship was
## lost (at the last station), after you fell on foot (in the nearest city with a clinic, else the last station).

const GearData = preload("res://data/gear.gd")


func build() -> void:
	var g = GameState.gear
	section("TREATMENT")
	var missing: float = GearData.HEALTH - g.health
	add_child(UI.label("Health %d / %d" % [int(g.health), int(GearData.HEALTH)], 15, Color(1.0, 0.55, 0.5) if missing > 0.5 else Color(0.6, 1.0, 0.65)))
	if missing > 0.5:
		var price := buy_price(Commands.clinic_price())
		var b := UI.button("Treat me – %s" % GameData.fmt_credits(price), func(): run({"type": "clinic_heal"}))
		b.disabled = GameState.credits < price
		add_child(b)
	else:
		add_child(UI.label("Nothing to treat – you are well.", 13, UI.TEXT_DIM))
	section("WHERE YOU WAKE")
	add_child(UI.label("If your ship is lost, you wake in the clinic of the last station you docked at. If you fall on foot, you wake in the nearest city with a clinic – or, if there is none in the system, at the last station – and what was in your pockets is gone.", 13, UI.TEXT_DIM))
	for c in get_children():
		if c is Label:
			(c as Label).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
