extends StationServicePanel
## Drone Bay (Hivewright Drone Works, phase 0.5 package 23): new drones into the hangar, used ones
## sold, damaged hulls repaired. Drone fuel cells are sealed – fuel cannot be refilled.


func build() -> void:
	UI.clear(self)
	if no_ship():
		return
	var f := fit()
	var s := f.stats()
	var room := int(s["drone_storage"])
	section("DRONE HANGAR OF %s" % f.ship_name.to_upper())
	if room <= 0:
		add_child(UI.label("This ship has no drone hangar fitted – fit one in the ship menu (Modules → Core).", 13, UI.BAD))
		return
	var hm: String = f.get_module("hangar")
	add_child(UI.label("%s  •  %d / %d drones stored  •  up to %d out at once (%s)" % [GameData.module_name(hm), f.drones.size(), room, int(s["drones_max"]), f.hull()["name"]], 13, Color(0.85, 0.9, 1.0)))
	var d: Dictionary = s["drone"]
	var w: Dictionary = s["drone_weapon"]
	var t: Dictionary = s["drone_tool"]
	add_child(UI.label("Every drone: hull %.0f%s  •  %.0f km/s  •  control range %s  •  fuel for %d min  •  cargo %.0f m³" % [float(d["hull"]), (" + shield %.0f" % float(d["shield"])) if float(d["shield"]) > 0.0 else "", float(d["speed"]), SystemView.fmt_dist(float(d["range"])), int(float(d["fuel"]) / 60.0), float(d["cargo"])], 12, UI.TEXT_DIM))
	add_child(UI.label("Weapon: %s  •  Mining: %s  •  Repair: built-in beam (%.0f /s)" % [String(w.get("name", "none fitted")), String(t.get("name", "none fitted")), float(d["repair"])], 12, UI.TEXT_DIM))
	standing_line()
	var row := UI.hbox(8)
	add_child(row)
	var price := Commands.drone_price()
	for n in [1, 5]:
		var amount: int = n
		var b := UI.button("Buy %d (%s)" % [n, GameData.fmt_credits(price * n)], func(): run({"type": "drone_buy", "amount": amount}))
		b.disabled = f.drones.size() >= room or GameState.credits < price
		row.add_child(b)
	var rc := Commands.drone_repair_cost(f)
	var rb := UI.button("Repair all hulls (%s)" % GameData.fmt_credits(rc), func(): run({"type": "drone_repair"}))
	rb.disabled = rc <= 0
	row.add_child(rb)
	section("STORED DRONES")
	if f.drones.is_empty():
		add_child(UI.label("No drones – buy some above.", 13, UI.TEXT_DIM))
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 16)
	add_child(grid)
	for i in f.drones.size():
		var r: Dictionary = f.drones[i]
		var idx: int = i
		grid.add_child(UI.label("Drone %d" % (i + 1), 13))
		grid.add_child(UI.label("Fuel %d %%" % int(float(r["fuel"]) * 100.0), 13, UI.GOOD if float(r["fuel"]) > 0.3 else UI.BAD))
		grid.add_child(UI.label("Hull %d %%" % int(float(r["hp"]) * 100.0), 13, UI.GOOD if float(r["hp"]) > 0.6 else UI.GOLD))
		grid.add_child(UI.label("worth %s" % GameData.fmt_credits(Commands.drone_value(r)), 12, UI.TEXT_DIM))
		grid.add_child(UI.button("Sell", func(): run({"type": "drone_sell", "index": idx})))
