class_name StationServicePanel
extends VBoxContainer
## Base class for station service panels. Override build().

var ui: StationUI
var svc: Dictionary
var station: Dictionary


func setup(p_ui: StationUI, p_svc: Dictionary) -> void:
	ui = p_ui
	svc = p_svc
	station = ui.station
	add_theme_constant_override("separation", 8)


func build() -> void:
	pass


func fit() -> ShipFitting:
	return ui.fit()


func corp_color() -> Color:
	return GameData.corp(svc["corp"])["color"]


func section(text: String) -> Label:
	var l := UI.label(text, 16, corp_color())
	add_child(l)
	return l


## Sends a player command through the command bus, then refreshes the station UI.
func run(cmd: Dictionary) -> void:
	Commands.execute(cmd)
	refresh_all()


func refresh_all() -> void:
	ui.rebuild()


func no_ship() -> bool:
	if fit() == null:
		add_child(UI.label("No ship docked.", 14, UI.BAD))
		return true
	return false


## Price after the standing with this station's faction (package 12).
func buy_price(base: int) -> int:
	return GameState.rep.buy_price(base, String(station.get("faction", "")))


func sell_price(base: float) -> float:
	return GameState.rep.sell_price(base, String(station.get("faction", "")))


## One line: standing with the station's faction and what it does to prices.
func standing_line() -> Label:
	var f := String(station.get("faction", ""))
	var col: Color = GameState.rep.tier(f)["color"] if f != "" else UI.TEXT_DIM
	var l := UI.label(GameState.rep.price_note(f), 13, col)
	add_child(l)
	return l


func cargo_line() -> Label:
	var f := fit()
	var ore_txt := ""
	if float(f.stats()["ore_cargo_max"]) > 0.0:
		ore_txt = "   •   ore hold %.1f / %.0f m³" % [f.ore_hold_used(), float(f.stats()["ore_cargo_max"])]
	var l := UI.label("Cargo hold of %s: %.1f / %.0f m³%s" % [f.ship_name, f.cargo_used(), float(f.stats()["cargo_max"]), ore_txt], 13, UI.TEXT_DIM)
	add_child(l)
	return l
