extends StationServicePanel
## Package 39c: the Research Exchange (Meridian Sphere, Durchbruch) – research data from analysed anomalies and exotic
## matter for credits and standing; exotic matter for sale to Allied pilots.


func build() -> void:
	UI.clear(self)
	add_child(UI.wrap_label("The Meridian Research Council buys what pilots learn out there. Every anomaly you analyse leaves you with a data set.", 13, UI.TEXT_DIM, 1100))
	section("RESEARCH DATA")
	var row := UI.hbox(8)
	add_child(row)
	var k: int = GameState.research_data
	row.add_child(UI.label("Data sets in hand: %d   •   %s and +%.1f standing each" % [k, GameData.fmt_credits(GameState.DATA_PRICE), GameState.DATA_REP], 13))
	var b := UI.button("Sell all (%s)" % GameData.fmt_credits(k * GameState.DATA_PRICE), func(): run({"type": "exchange", "what": "data"}))
	b.disabled = k <= 0
	row.add_child(b)
	section("EXOTIC MATTER")
	var em: int = GameState.exotic_matter
	var row2 := UI.hbox(8)
	add_child(row2)
	row2.add_child(UI.label("In stock: %d   •   the Exchange pays %s and +%d standing per unit" % [em, GameData.fmt_credits(GameState.EM_SELL), int(GameState.EM_SELL_REP)], 13))
	var s1 := UI.button("Sell 1", func(): run({"type": "exchange", "what": "sell_em", "n": 1}))
	s1.disabled = em <= 0
	row2.add_child(s1)
	var row3 := UI.hbox(8)
	add_child(row3)
	var allied: bool = GameState.rep.at_least("directorate", "allied")
	row3.add_child(UI.label("Buy exotic matter: %s per unit%s" % [GameData.fmt_credits(GameState.EM_BUY), "" if allied else " – only for Allied pilots"], 13, UI.GOLD if allied else UI.TEXT_DIM))
	var b1 := UI.button("Buy 1", func(): run({"type": "exchange", "what": "buy_em", "n": 1}))
	b1.disabled = not allied or GameState.credits < GameState.EM_BUY
	row3.add_child(b1)
