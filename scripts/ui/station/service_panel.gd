extends StationServicePanel
## Simple services for ships in the hangar.
##   mode "fuel":   Pyre Fuel Syndicate – refuel
##   mode "repair": Mendex Nanorepair   – repair armour and structure
## Prices live in Commands (FUEL_PRICE / REPAIR_PRICE).


func build() -> void:
	UI.clear(self)
	var mode: String = svc.get("mode", "fuel")
	var ships := GameState.hangar(station["id"])
	standing_line()
	if ships.is_empty():
		add_child(UI.label("No ships docked.", 14, UI.BAD))
		return
	var total := 0
	for f in ships:
		var fit_: ShipFitting = f
		var s := fit_.stats()
		var row := UI.hbox(14)
		add_child(row)
		row.add_child(UI.icon(PixelArt.ship_texture(fit_.hull_id, "player"), 48))
		var info := UI.vbox(2)
		info.custom_minimum_size = Vector2(520, 0)
		row.add_child(info)
		info.add_child(UI.label(fit_.ship_name, 15, corp_color()))
		if mode == "fuel":
			var b := UI.bar(Color(0.4, 0.9, 0.5), 400)
			b.max_value = maxf(float(s["fuel_max"]), 0.001)
			b.value = fit_.fuel
			info.add_child(b)
			info.add_child(UI.label("Fuel %.0f / %.0f" % [fit_.fuel, s["fuel_max"]], 12, UI.TEXT_DIM))
		else:
			var b1 := UI.bar(Color(1.0, 0.8, 0.3), 400)
			b1.max_value = maxf(float(s["armor_max"]), 0.001)
			b1.value = fit_.armor
			info.add_child(b1)
			var b2 := UI.bar(Color(0.9, 0.3, 0.3), 400)
			b2.max_value = maxf(float(s["structure_max"]), 0.001)
			b2.value = fit_.structure
			info.add_child(b2)
			info.add_child(UI.label("Armor %.0f / %.0f   •   Structure %.0f / %.0f" % [fit_.armor, s["armor_max"], fit_.structure, s["structure_max"]], 12, UI.TEXT_DIM))
		var cost := Commands.service_cost(mode, fit_)
		total += cost
		var uid: int = fit_.uid
		var btn := UI.button(("Refuel (%s)" if mode == "fuel" else "Repair (%s)") % GameData.fmt_credits(cost), func(): _apply(uid))
		btn.disabled = cost <= 0
		row.add_child(btn)
	if ships.size() > 1 and total > 0:
		add_child(UI.button(("Refuel all (%s)" if mode == "fuel" else "Repair all (%s)") % GameData.fmt_credits(total), func(): _apply(-1)))


func _apply(uid: int) -> void:
	run({"type": "refuel" if svc.get("mode", "fuel") == "fuel" else "repair", "uid": uid})
