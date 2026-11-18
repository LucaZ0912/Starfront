extends StationServicePanel
## Hangar (Vaultline Storage): ships parked at this station, boarding and renaming. Window rework (Luz, 18 Nov 2026):
## the same layout as the shipyard – on top the picked ship (a big picture, its state, values and fitted modules,
## board / fit / rename), below your ships as tiles: those here first, then those elsewhere (greyed, with where).

const MakerData = preload("res://data/manufacturers.gd")
const Kit = preload("res://scripts/ui/station/svc_kit.gd")

static var pick_uid := -1


## Ships here first, then the rest of the fleet.
func _ships() -> Array:
	var here: Array = GameState.hangar(station["id"])
	var out: Array = here.duplicate()
	for f in GameState.fleet:
		if not f in here:
			out.append(f)
	return out


func _where(f: ShipFitting) -> String:
	if f.docked_at == "":
		return "in space"
	var st: Dictionary = Universe.find_station(f.system_id, f.docked_at)
	return String(st.get("name", "elsewhere"))


func build() -> void:
	UI.clear(self)
	var col := corp_color()
	var ships := _ships()
	var here_n: int = GameState.hangar(station["id"]).size()
	var sel := -1
	for i in ships.size():
		if (ships[i] as ShipFitting).uid == pick_uid:
			sel = i
	if sel < 0:
		sel = 0
		for i in ships.size():
			if (ships[i] as ShipFitting).uid == GameState.active_uid:
				sel = i
		pick_uid = (ships[sel] as ShipFitting).uid if not ships.is_empty() else -1
	if not ships.is_empty():
		_top(ships[sel], col, sel < here_n)
	var frow := UI.hbox(14)
	add_child(frow)
	frow.add_child(UI.label("Ships in this hangar: %d  •  you always fly exactly one" % here_n, 13, UI.TEXT_DIM))
	frow.add_child(UI.spacer())
	if ships.size() > here_n:
		frow.add_child(UI.label("greyed: parked elsewhere (where it stands below)", 12, UI.TEXT_DIM))
	var items: Array = []
	for i in ships.size():
		var f: ShipFitting = ships[i]
		var here := i < here_n
		var sub := "● active" if f.uid == GameState.active_uid else ("parked here" if here else _where(f))
		items.append({"tex": PixelArt.fleet_texture(f), "name": f.ship_name, "sub": sub,
			"sub_col": UI.GOOD if f.uid == GameState.active_uid else UI.TEXT_DIM, "tag": GameData.SIZE_NAMES.get(int(f.hull()["size"]), "XL"), "dim": not here})
	Kit.strip(self, items, sel, col, func(i): pick_uid = (ships[i] as ShipFitting).uid; refresh_all())
	if here_n <= 1:
		add_child(UI.label("Buy more ships at a shipyard: Hadal Orbital Yards delivers them here.", 12, UI.TEXT_DIM))
	_platform()


## Q / E step through the strip.
func menu_tab(step: int) -> void:
	var ships := _ships()
	var i := 0
	for k in ships.size():
		if (ships[k] as ShipFitting).uid == pick_uid:
			i = k
	pick_uid = (ships[clampi(i + step, 0, ships.size() - 1)] as ShipFitting).uid
	refresh_all()


func _top(f: ShipFitting, col: Color, here: bool) -> void:
	var h: Dictionary = f.hull()
	var maker: Dictionary = MakerData.MAKERS.get(String(h.get("maker", "")), {})
	var active := f.uid == GameState.active_uid
	var pic := Kit.picture(PixelArt.fleet_texture(f), col, Kit.pic_height(self),
		"%s  •  %s" % [maker.get("name", "?"), h["class"]], "SIZE " + String(GameData.SIZE_NAMES.get(int(h["size"]), "XL")))
	var info := Kit.detail(self, pic)
	var nv := UI.vbox(0)
	info.add_child(nv)
	nv.add_child(UI.label(f.ship_name, 26, col))
	var state := "● ACTIVE SHIP" if active else ("parked here" if here else "parked at %s" % _where(f))
	nv.add_child(UI.label("%s %s  •  %s" % [h["name"], h["class"], state], 13, UI.GOOD if active else UI.TEXT_DIM))
	var s := f.stats()
	var am := maxf(float(s["armor_max"]), 1.0)
	var sm := maxf(float(s["structure_max"]), 1.0)
	var fm := maxf(float(s["fuel_max"]), 1.0)
	var cm := maxf(float(s["cargo_max"]), 1.0)
	Kit.stats(info, [
		["Armour", "%.0f / %.0f" % [f.armor, float(s["armor_max"])], f.armor / am, UI.GOLD],
		["Structure", "%.0f / %.0f" % [f.structure, float(s["structure_max"])], f.structure / sm, UI.BAD],
		["Fuel", "%.0f / %.0f" % [f.fuel, float(s["fuel_max"])], f.fuel / fm, UI.NEON_CYAN],
		["Cargo", "%.1f / %.0f m³" % [f.cargo_used(), float(s["cargo_max"])], f.cargo_used() / cm, UI.TEXT_DIM],
		["DPS", "%.0f" % float(s["dps_total"])], ["Speed", "%.0f km/s" % float(s["speed"])],
		["Shield", "%.0f" % float(s["shield_max"])], ["Value", GameData.fmt_credits(GameState.ship_value(f))]], 4)
	var mods: Array = []
	var keys: Array = f.modules.keys()
	keys.sort()
	for t in ["weapon", "tool", "optional"]:
		for k in keys:
			if ShipFitting.slot_type(String(k)) == t:
				mods.append("%s: %s" % [GameData.slot_label(String(k)), GameData.module_name(String(f.modules[k]))])
	if mods.is_empty():
		mods.append("no weapons, tools or optional modules fitted")
	Kit.tags(info, mods)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info.add_child(sp)
	# rename
	var rn := UI.hbox(6)
	info.add_child(rn)
	var le := LineEdit.new()
	le.text = f.ship_name
	le.custom_minimum_size = Vector2(220, 0)
	rn.add_child(le)
	var ruid: int = f.uid
	rn.add_child(UI.button("Rename", func(): run({"type": "rename_ship", "uid": ruid, "name": le.text})))
	# board / fit
	var acts := UI.hbox(10)
	info.add_child(acts)
	if active:
		acts.add_child(UI.label("▶ You fly this one", 15, UI.GOOD))
		var fb := UI.button("Fit it at the Outfitter", func(): ui.open_service("outfitter"))
		fb.disabled = ui.service_available(_outfitter()) != "" if not _outfitter().is_empty() else true
		acts.add_child(fb)
	elif here:
		acts.add_child(UI.button("Board (make it your active ship)", func(): run({"type": "board", "uid": ruid})))
	else:
		acts.add_child(UI.label("Fly to %s to board it." % _where(f), 13, UI.TEXT_DIM))


func _outfitter() -> Dictionary:
	for s in GameData.services:
		if s["id"] == "outfitter":
			return s
	return {}


## Package 33: the Citadel's launch platform – which Hadrian S ship stands on it, put one on, take it off, recall a lost one.
func _platform() -> void:
	var cit := fit()
	if cit == null or not cit.hull().get("hatches", {}).has("platform"):
		return
	section("LAUNCH PLATFORM OF THE %s" % cit.ship_name.to_upper())
	var pp := GameState.platform_pilot(cit)
	add_child(UI.label(("Platform pilot: %s (%s)" % [pp["name"], pp["quality"]]) if not pp.is_empty() else "No platform pilot: a Co-Pilot with the perk Wingman flies the platform ship (crew post in Modules → Crew).", 13, UI.GOOD if not pp.is_empty() else UI.BAD))
	if not cit.platform_ship.is_empty():
		var r := UI.hbox(12)
		add_child(r)
		r.add_child(UI.icon(PixelArt.ship_texture(String(cit.platform_ship["hull_id"]), "player"), 48))
		r.add_child(UI.label("On the platform: %s" % cit.platform_ship["ship_name"], 14))
		r.add_child(UI.button("Take it into the hangar (to fit it)", func(): run({"type": "platform_unload"})))
		return
	if not cit.platform_lost.is_empty():
		var price := GameState.platform_recall_price(cit)
		var b := UI.button("Recall the destroyed %s: %s (10 %%)" % [cit.platform_lost["ship_name"], GameData.fmt_credits(price)], func(): run({"type": "platform_rebuy"}))
		b.disabled = GameState.credits < price
		add_child(b)
	var any := false
	for f in GameState.hangar(station["id"]):
		var s: ShipFitting = f
		if s == cit or GameState.platform_hull_error(s.hull_id) != "":
			continue
		any = true
		var uid := s.uid
		add_child(UI.button("Put the %s on the platform" % s.ship_name, func(): run({"type": "platform_load", "uid": uid})))
	if not any and cit.platform_lost.is_empty():
		add_child(UI.label("Any Hadrian Dynamics S ship in this hangar can stand on the platform: fit it as you like first.", 12, UI.TEXT_DIM))
