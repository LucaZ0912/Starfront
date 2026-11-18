extends StationServicePanel
## Drone Bay (Hivewright Drone Works, phase 0.5 package 23): new drones into the hangar, used ones
## sold, damaged hulls repaired. Drone fuel cells are sealed – fuel cannot be refilled.
## Window rework (Luz, 18 Nov 2026): on top a drone of this ship, big, with all its values, buying with a slider and
## repairing the hulls; below every stored drone as a tile with its fuel and hull, its worth and "Sell" (free places
## dashed).

const Kit = preload("res://scripts/ui/station/svc_kit.gd")

static var pick := -1


func build() -> void:
	UI.clear(self)
	if no_ship():
		return
	var f := fit()
	var col := corp_color()
	var s := f.stats()
	var room := int(s["drone_storage"])
	if room <= 0:
		var e := UI.neon_panel(Color(col, 0.4), Color(0.02, 0.02, 0.05, 0.6), 1)
		e.custom_minimum_size = Vector2(0, 260)
		add_child(e)
		var ev := UI.vbox(12)
		ev.alignment = BoxContainer.ALIGNMENT_CENTER
		e.add_child(ev)
		var ic := UI.icon(PixelArt.ship_texture("drone", "player"), 90)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		ev.add_child(ic)
		for t in [["%s has no drone hangar." % f.ship_name, 18, col], ["Fit one in the ship menu (Modules → Core), then come back for drones.", 13, UI.TEXT_DIM]]:
			var l := UI.label(t[0], t[1], t[2])
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			ev.add_child(l)
		return
	var hm: String = f.get_module("hangar")
	var d: Dictionary = s["drone"]
	var w: Dictionary = s["drone_weapon"]
	var t: Dictionary = s["drone_tool"]
	var pic := Kit.picture(PixelArt.ship_texture("drone", "player"), col, Kit.pic_height(self), GameData.module_name(hm), "%d / %d STORED" % [f.drones.size(), room], Kit.pic_height(self) * 0.45)
	var info := Kit.detail(self, pic)
	var nv := UI.vbox(0)
	info.add_child(nv)
	nv.add_child(UI.label("Drones of %s" % f.ship_name, 24, col))
	nv.add_child(UI.label("up to %d out at once (%s)  •  every drone the same, fitted from the hangar's slots" % [int(s["drones_max"]), f.hull()["name"]], 13, UI.TEXT_DIM))
	Kit.stats(info, [
		["Hull", "%.0f%s" % [float(d["hull"]), (" + shield %.0f" % float(d["shield"])) if float(d["shield"]) > 0.0 else ""]], ["Speed", "%.0f km/s" % float(d["speed"])],
		["Control range", SystemView.fmt_dist(float(d["range"]))], ["Fuel", "%d min" % int(float(d["fuel"]) / 60.0)],
		["Cargo", "%.0f m³" % float(d["cargo"])], ["Weapon", String(w.get("name", "none fitted"))],
		["Mining", String(t.get("name", "none fitted"))], ["Repair beam", "%.0f /s" % float(d["repair"])]], 4)
	var stl := UI.label(GameState.rep.price_note(String(station.get("faction", ""))), 12, UI.TEXT_DIM)
	info.add_child(stl)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info.add_child(sp)
	var price := Commands.drone_price()
	var free := room - f.drones.size()
	var mx := mini(free, int(floor(float(GameState.credits) / float(maxi(price, 1)))))
	Kit.amount_block(info, "BUY DRONES  •  %s each  •  %d free place%s" % [GameData.fmt_credits(price), free, "" if free == 1 else "s"], mx, mini(mx, 1), UI.GOLD,
		func(n): return "%d × %s = %s" % [n, GameData.fmt_credits(price), GameData.fmt_credits(n * price)],
		func(n): return "Buy %d" % n, func(n): run({"type": "drone_buy", "amount": n}), "Max %d" % mx,
		"" if mx > 0 else ("The hangar is full." if free <= 0 else "Not enough credits."))
	var rc := Commands.drone_repair_cost(f)
	var rr := UI.hbox(10)
	info.add_child(rr)
	var rb := UI.button("Repair all hulls (%s)" % GameData.fmt_credits(rc), func(): run({"type": "drone_repair"}))
	rb.disabled = rc <= 0 or GameState.credits < rc
	rr.add_child(rb)
	rr.add_child(UI.label("Fuel cells are sealed: an empty drone is worth less, it cannot be refilled.", 12, UI.TEXT_DIM))
	# the stored drones
	add_child(UI.label("STORED DRONES", 12, UI.TEXT_DIM))
	if pick >= f.drones.size():
		pick = -1
	var th := clampf(get_viewport().get_visible_rect().size.y * 0.15, 104.0, 132.0)
	var tiles: Array = []
	for i in f.drones.size():
		var r: Dictionary = f.drones[i]
		var fu := float(r["fuel"])
		var hp := float(r["hp"])
		var idx := i
		tiles.append(Kit.bar_tile("Drone %d%s" % [i + 1, "  •  out" if bool(r.get("out", false)) else ""],
			[["Fuel %d %%" % int(fu * 100.0), fu, UI.NEON_CYAN], ["Hull %d %%" % int(hp * 100.0), hp, UI.GOOD if hp > 0.6 else UI.GOLD]],
			"worth %s%s" % [GameData.fmt_credits(Commands.drone_value(r)), "  •  click to sell" if pick != i else ""], UI.TEXT_DIM, pick == i, col, Vector2(th * 1.45, th),
			func(): pick = idx; refresh_all()))
	var free_n := maxi(0, room - f.drones.size())
	for k in mini(free_n, 3):
		var e2 := Kit.tile({"name": "", "sub": ""}, false, col, Vector2(th * 1.45, th), func(): pass)
		e2.disabled = true
		e2.modulate = Color(1, 1, 1, 0.35)
		var el := UI.label("empty place", 12, UI.TEXT_DIM)
		el.set_anchors_preset(Control.PRESET_CENTER)
		el.mouse_filter = Control.MOUSE_FILTER_IGNORE
		e2.add_child(el)
		tiles.append(e2)
	var row := Kit.tile_row(self, tiles)
	if free_n > 3:
		var more := UI.label("+ %d more free places" % (free_n - 3), 12, UI.TEXT_DIM)
		more.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(more)
	if pick >= 0:
		var sr := UI.hbox(10)
		add_child(sr)
		var r2: Dictionary = f.drones[pick]
		sr.add_child(UI.label("Drone %d: worth %s" % [pick + 1, GameData.fmt_credits(Commands.drone_value(r2))], 13))
		var sel := pick
		var sb := UI.button("Sell drone %d" % (pick + 1), func(): pick = -1; run({"type": "drone_sell", "index": sel}))
		sb.disabled = bool(r2.get("out", false))
		sr.add_child(sb)
