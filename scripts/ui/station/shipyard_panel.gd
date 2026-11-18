extends StationServicePanel
## Shipyard (Hadal Orbital Yards): buy hulls, bare or with the standard fit. New ships are delivered to the hangar
## of this station. Window rework (Luz, 18 Nov 2026): on top the picked ship – a big picture on the left, all its
## values on the right; below a strip of small tiles to browse (filters by size and role above it).

const MakerData = preload("res://data/manufacturers.gd")
const Kit = preload("res://scripts/ui/station/svc_kit.gd")

const SIZES := [["all", "All"], ["1", "S"], ["2", "M"], ["3", "L"]]
const ROLES := [["all", "All roles"], ["combat", "Combat"], ["mining", "Mining"], ["trade", "Trade"], ["explore", "Explore"], ["carrier", "Carriers"]]

static var size_f := "all"
static var role_f := "all"
static var pick := ""


## A hull's role from its class (for the filter).
static func role_of(h: Dictionary) -> String:
	var c := String(h.get("class", "")).to_lower()
	if c.contains("carrier"):
		return "carrier"
	if c.contains("mining") or c.contains("industry") or c.contains("gas"):
		return "mining"
	if c.contains("freighter") or c.contains("hauler") or c.contains("liner") or c.contains("shuttle") or c.contains("yacht"):
		return "trade"
	if c.contains("scout") or c.contains("research") or c.contains("jump"):
		return "explore"
	return "combat"


func _hulls() -> Array:
	var out: Array = []
	for hid in station["shipyard"]:
		var h: Dictionary = GameData.hulls[hid]
		if size_f != "all" and int(h["size"]) != int(size_f):
			continue
		if role_f != "all" and role_of(h) != role_f:
			continue
		out.append(hid)
	return out


func _price(hid: String, fitted: bool) -> int:
	var base := GameData.preset_price("std_" + hid) if fitted else int(GameData.hulls[hid]["price"])
	var fac := String(station.get("faction", ""))
	return int(round(buy_price(base) * GameState.senate.hull_mult(hid, fac) * GameState.curia.hull_mult(hid, fac)))


func build() -> void:
	UI.clear(self)
	var col := corp_color()
	var list := _hulls()
	if not pick in list:
		pick = list[0] if not list.is_empty() else ""
	if pick == "":
		add_child(UI.label("No ship of this kind here: change the filter below.", 14, UI.TEXT_DIM))
	else:
		_top(pick, col)
	var frow := UI.hbox(14)
	add_child(frow)
	Kit.chips(frow, SIZES, size_f, col, func(id): size_f = id; refresh_all())
	Kit.chips(frow, ROLES, role_f, col, func(id): role_f = id; refresh_all())
	frow.add_child(UI.spacer())
	frow.add_child(UI.label("Q / E or ‹ › to browse  •  %d ships" % list.size(), 12, UI.TEXT_DIM))
	var items: Array = []
	for hid in list:
		var h: Dictionary = GameData.hulls[hid]
		var lock := ""
		if GameState.hull_standing_error(hid) != "":
			lock = "standing"
		elif GameState.hull_tree_error(hid) != "":
			lock = "skill tree"
		items.append({"tex": PixelArt.ship_texture(hid, "player"), "name": String(h["name"]), "sub": GameData.fmt_credits(_price(hid, false)),
			"tag": GameData.SIZE_NAMES.get(int(h["size"]), "XL"), "lock": lock})
	Kit.strip(self, items, list.find(pick), col, func(i): pick = list[i]; refresh_all())


## Q / E step through the strip.
func menu_tab(step: int) -> void:
	var list := _hulls()
	if list.is_empty():
		return
	pick = list[clampi(list.find(pick) + step, 0, list.size() - 1)]
	refresh_all()


func _top(hid: String, col: Color) -> void:
	var h: Dictionary = GameData.hulls[hid]
	var mk := String(h.get("maker", ""))
	var maker: Dictionary = MakerData.MAKERS.get(mk, {})
	var ph := Kit.pic_height(self)
	var pic := Kit.picture(PixelArt.ship_texture(hid, "player"), col, ph,
		("%s  •  “%s”" % [maker["name"], maker["motto"]]) if not maker.is_empty() else "", "SIZE " + String(GameData.SIZE_NAMES.get(int(h["size"]), "XL")))
	var info := Kit.detail(self, pic)
	var nrow := UI.hbox(10)
	info.add_child(nrow)
	if not maker.is_empty():
		nrow.add_child(UI.icon(CrestArt.maker_texture(mk), 30))
	var nv := UI.vbox(0)
	nrow.add_child(nv)
	nv.add_child(UI.label(String(h["name"]), 26, col))
	nv.add_child(UI.label("%s  •  %s  •  size %s" % [h["class"], maker.get("name", "?"), GameData.SIZE_NAMES.get(int(h["size"]), "XL")], 13, UI.TEXT_DIM))
	var desc := UI.label(String(h["desc"]), 14)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = 260
	info.add_child(desc)
	var stl := UI.label(GameState.rep.price_note(String(station.get("faction", ""))), 12, UI.TEXT_DIM)
	info.add_child(stl)
	if mk == "khi":
		info.add_child(UI.label("Built-in refinery, ore hold %d m³, prospector  •  +10 %% mining  •  slow to turn and to warp" % int(h.get("ore_cargo", 0)), 12, Color(1.0, 0.8, 0.35)))
	# the values with the standard fit (if there is one), else the bare hull
	var preset := "std_" + hid
	var f: ShipFitting = GameState.create_from_preset(preset, "player") if GameData.presets.has(preset) else GameState.create_fit(hid, {}, "player")
	var s := f.stats()
	Kit.stats(info, [
		["Structure", "%d" % int(h["structure"])], ["Armour", "%.0f" % float(s["armor_max"])], ["Shield", "%.0f" % float(s["shield_max"])],
		["Speed", "%.0f km/s" % float(s["speed"])], ["Mass", "%d t" % int(h["mass"])], ["Cargo", "%d m³" % int(h["cargo"])],
		["Fuel", "%.0f" % float(s["fuel_max"])], ["DPS", "%.0f" % float(s["dps_total"])]], 4)
	var sl: Dictionary = h["slots"]
	var tg: Array = ["%d weapons" % int(sl.get("weapon", 0)), "%d tools" % int(sl.get("tool", 0)), "%d optional" % int(sl.get("optional", 0))]
	if int(h.get("drones", 0)) > 0:
		tg.append("%d drones" % int(h["drones"]))
	Kit.tags(info, tg)
	if GameData.presets.has(preset):
		info.add_child(UI.label("Values with the standard fit.", 11, UI.TEXT_DIM))
	# what it needs
	var why_t: String = GameState.hull_standing_error(hid)
	if String(h.get("min_tier", "")) != "":
		info.add_child(UI.label("Faction ship: needs %s standing" % String(h["min_tier"]).capitalize() + (("  •  " + why_t) if why_t != "" else "  ✓"), 13, UI.BAD if why_t != "" else UI.GOOD))
	var tree_e: String = GameState.hull_tree_error(hid)
	if tree_e != "":
		info.add_child(UI.label(tree_e.replace(" first (Pilot window).", "") + " to fly it; until then it stays docked.", 13, Color(1.0, 0.7, 0.3)))
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info.add_child(sp)
	var buy := UI.hbox(10)
	info.add_child(buy)
	buy.add_child(UI.label(GameData.fmt_credits(_price(hid, false)), 22, UI.GOLD))
	var b1 := UI.button("Buy the bare hull", func(): _buy(hid, false))
	b1.disabled = why_t != "" or GameState.credits < _price(hid, false)
	buy.add_child(b1)
	if GameData.presets.has(preset):
		var b2 := UI.button("Buy fitted (%s)" % GameData.fmt_credits(_price(hid, true)), func(): _buy(hid, true))
		b2.disabled = why_t != "" or GameState.credits < _price(hid, true)
		buy.add_child(b2)
	buy.add_child(UI.label("delivered to this hangar", 12, UI.TEXT_DIM))


func _buy(hid: String, with_fit: bool) -> void:
	run({"type": "ship_buy", "hull": hid, "fitted": with_fit})
