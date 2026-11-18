extends StationServicePanel
## Simple services for ships in the hangar.
##   mode "fuel":   Pyre Fuel Syndicate – refuel
##   mode "repair": Mendex Nanorepair   – repair armour and structure
## Prices live in Commands (FUEL_PRICE / REPAIR_PRICE).
## Window rework (Luz, 18 Nov 2026): on top the picked ship, big, with thick bars, what is missing, the price and one
## clear button; below every ship in this hangar as a tile with its bars and cost, and "… all".

const Kit = preload("res://scripts/ui/station/svc_kit.gd")
const MakerData = preload("res://data/manufacturers.gd")

static var pick_uid := -1


func build() -> void:
	UI.clear(self)
	var mode: String = svc.get("mode", "fuel")
	var col := corp_color()
	var ships := GameState.hangar(station["id"])
	if ships.is_empty():
		add_child(UI.label("No ships docked.", 14, UI.BAD))
		return
	var sel: ShipFitting = null
	for f in ships:
		if f.uid == pick_uid:
			sel = f
	if sel == null:
		sel = GameState.active() if GameState.active() in ships else ships[0]
		pick_uid = sel.uid
	_top(sel, mode, col)
	# the ships in this hangar
	var total := 0
	for f in ships:
		total += Commands.service_cost(mode, f)
	var hr := UI.hbox(10)
	add_child(hr)
	hr.add_child(UI.label("SHIPS IN THIS HANGAR", 12, UI.TEXT_DIM))
	hr.add_child(UI.spacer())
	if ships.size() > 1:
		var ab := UI.button(("Refuel all (%s)" if mode == "fuel" else "Repair all (%s)") % GameData.fmt_credits(total), func(): _apply(-1))
		ab.disabled = total <= 0 or GameState.credits < total
		hr.add_child(ab)
	var th := clampf(get_viewport().get_visible_rect().size.y * 0.15, 104.0, 132.0)
	var tiles: Array = []
	for f in ships:
		var fit_: ShipFitting = f
		var s := fit_.stats()
		var bars: Array = []
		if mode == "fuel":
			bars.append(["Fuel %d %%" % _pct(fit_.fuel, float(s["fuel_max"])), fit_.fuel / maxf(float(s["fuel_max"]), 0.001), Color(0.4, 0.9, 0.5)])
		else:
			bars.append(["Armour %d %%" % _pct(fit_.armor, float(s["armor_max"])), fit_.armor / maxf(float(s["armor_max"]), 0.001), Color(1.0, 0.8, 0.3)])
			bars.append(["Structure %d %%" % _pct(fit_.structure, float(s["structure_max"])), fit_.structure / maxf(float(s["structure_max"]), 0.001), Color(0.9, 0.3, 0.3)])
		var cost := Commands.service_cost(mode, fit_)
		var uid := fit_.uid
		tiles.append(Kit.bar_tile(fit_.ship_name, bars, GameData.fmt_credits(cost) if cost > 0 else ("full" if mode == "fuel" else "no damage"),
			UI.GOLD if cost > 0 else UI.GOOD, fit_.uid == pick_uid, col, Vector2(th * 1.7, th), func(): pick_uid = uid; refresh_all()))
	Kit.tile_row(self, tiles)


static func _pct(v: float, mx: float) -> int:
	return int(round(100.0 * v / maxf(mx, 0.001)))


func _top(f: ShipFitting, mode: String, col: Color) -> void:
	var h: Dictionary = f.hull()
	var s := f.stats()
	var active := f.uid == GameState.active_uid
	var pic := Kit.picture(PixelArt.fleet_texture(f), col, Kit.pic_height(self),
		"%s  •  %s" % [MakerData.MAKERS.get(String(h.get("maker", "")), {}).get("name", "?"), h["class"]], "SIZE " + String(GameData.SIZE_NAMES.get(int(h["size"]), "XL")))
	var info := Kit.detail(self, pic)
	var nv := UI.vbox(0)
	info.add_child(nv)
	nv.add_child(UI.label(f.ship_name, 26, col))
	nv.add_child(UI.label("%s %s  •  %s" % [h["name"], h["class"], "your active ship" if active else "parked here"], 13, UI.GOOD if active else UI.TEXT_DIM))
	var missing := ""
	if mode == "fuel":
		_big_bar(info, "FUEL", f.fuel, float(s["fuel_max"]), Color(0.4, 0.9, 0.5))
		missing = "Missing: %.0f fuel" % (float(s["fuel_max"]) - f.fuel)
	else:
		_big_bar(info, "ARMOUR", f.armor, float(s["armor_max"]), Color(1.0, 0.8, 0.3))
		_big_bar(info, "STRUCTURE", f.structure, float(s["structure_max"]), Color(0.9, 0.3, 0.3))
		missing = "Missing: %.0f armour, %.0f structure" % [float(s["armor_max"]) - f.armor, float(s["structure_max"]) - f.structure]
	var cost := Commands.service_cost(mode, f)
	info.add_child(UI.label(missing if cost > 0 else ("The tank is full." if mode == "fuel" else "No damage to repair."), 13, UI.TEXT_DIM))
	info.add_child(UI.label(GameState.rep.price_note(String(station.get("faction", ""))), 12, UI.TEXT_DIM))
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info.add_child(sp)
	var row := UI.hbox(12)
	info.add_child(row)
	row.add_child(UI.label(GameData.fmt_credits(cost), 24, UI.GOLD))
	var uid := f.uid
	var b := UI.button("Refuel fully" if mode == "fuel" else "Repair fully", func(): _apply(uid))
	b.disabled = cost <= 0 or GameState.credits < cost
	b.add_theme_font_size_override("font_size", 18)
	row.add_child(b)
	if cost > GameState.credits:
		row.add_child(UI.label("not enough credits", 13, UI.BAD))


func _big_bar(parent: Control, key: String, v: float, mx: float, c: Color) -> void:
	var r := UI.hbox(8)
	parent.add_child(r)
	var k := UI.label(key, 13, UI.TEXT_DIM)
	k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_child(k)
	r.add_child(UI.label("%.0f / %.0f" % [v, mx], 15))
	var b := UI.bar(c, 400)
	b.max_value = maxf(mx, 0.001)
	b.value = v
	b.custom_minimum_size = Vector2(0, 16)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(b)


func _apply(uid: int) -> void:
	run({"type": "refuel" if svc.get("mode", "fuel") == "fuel" else "repair", "uid": uid})
