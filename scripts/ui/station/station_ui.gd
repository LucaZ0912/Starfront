class_name StationUI
extends CanvasLayer
const PilotArtX = preload("res://scripts/core/pilot_art.gd")
const PilotDataX = preload("res://data/pilot.gd")
## Station interface. After docking the "concourse" opens: one tile per service, each run by
## the corporation holding the monopoly on it (data/station_services.gd + data/corporations.gd).
## Clicking a tile opens the matching service panel (scripts/ui/station/*_panel.gd).

signal closed
signal ship_menu_requested

const ScanlineShader = preload("res://shaders/scanlines.gdshader")
const FactionData = preload("res://data/factions.gd")

var station: Dictionary = {}
var view: SystemView
var current_service := ""

var bg: ColorRect
var win: PanelContainer
var title_label: Label
var sub_label: Label
var crest_rect: TextureRect
var crumb_label: Label
var credits_label: Label
var body: VBoxContainer
var _panel: Control
var _tween: Tween
var _tile_tweens: Array = []


func _ready() -> void:
	add_to_group("kbd_menu")              # 0.5.28.2: keyboard control
	layer = 20
	visible = false
	bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	var mat := ShaderMaterial.new()
	mat.shader = ScanlineShader
	bg.material = mat
	add_child(bg)
	win = UI.neon_panel(UI.NEON_PINK, Color(0.035, 0.02, 0.07, 0.97))
	win.set_anchors_preset(Control.PRESET_FULL_RECT)
	win.offset_left = 50
	win.offset_right = -50
	win.offset_top = 40
	win.offset_bottom = -30
	add_child(win)
	var v := UI.vbox(10)
	win.add_child(v)

	var head := UI.hbox(16)
	v.add_child(head)
	crest_rect = TextureRect.new()
	crest_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crest_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	crest_rect.custom_minimum_size = Vector2(51, 57)
	head.add_child(crest_rect)
	var names := UI.vbox(0)
	head.add_child(names)
	crumb_label = UI.label("", 12, UI.NEON_PINK)
	names.add_child(crumb_label)
	title_label = UI.label("", 24, UI.NEON_CYAN)
	names.add_child(title_label)
	sub_label = UI.label("", 13, UI.TEXT_DIM)
	names.add_child(sub_label)
	head.add_child(UI.spacer())
	credits_label = UI.label("", 18, UI.GOLD)
	head.add_child(credits_label)
	head.add_child(UI.button("Ship [%s]" % Keybinds.key_text("ship_menu"), func(): ship_menu_requested.emit()))
	head.add_child(UI.button("Undock", undock))
	head.add_child(UI.button("Close [%s]" % Keybinds.key_text("menu_back"), close))
	var line := ColorRect.new()
	line.color = Color(UI.NEON_PINK, 0.6)
	line.custom_minimum_size = Vector2(0, 2)
	v.add_child(line)

	body = UI.vbox(10)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(body)
	GameState.credits_changed.connect(func(_v): _update_header())


func open(p_station: Dictionary, p_view: SystemView) -> void:
	station = p_station
	view = p_view
	visible = true
	Audio.play("ui_open", "station menu")
	current_service = ""
	_update_header()
	show_concourse(true)
	# Intro: window fades/slides in
	win.modulate.a = 0.0
	win.position.y += 30
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(win, "modulate:a", 1.0, 0.35)
	_tween.tween_property(win, "position:y", win.position.y - 30, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_report_turn_ins()


## Q / E (0.5.28.2): handed to the service shown, if it has tabs (outfitter categories, market filters).
func menu_tab(step: int) -> void:
	if _panel != null and is_instance_valid(_panel) and _panel.has_method("menu_tab"):
		_panel.menu_tab(step)


func close() -> void:
	if not visible:
		return
	visible = false
	Audio.play("ui_close", "station menu")
	closed.emit()


func undock() -> void:
	if fit() != null:
		Commands.execute({"type": "undock"})
	close()


## The active ship, if it is docked here.
func fit() -> ShipFitting:
	var f := GameState.active()
	if f != null and f.docked_at == station.get("id", ""):
		return f
	return null


func station_type() -> Dictionary:
	return GameData.station_types[station["type"]]


func _update_header() -> void:
	if credits_label == null or station.is_empty():
		return
	credits_label.text = GameData.fmt_credits(GameState.credits)
	title_label.text = station["name"]
	var sf := String(station.get("faction", ""))
	crest_rect.texture = CrestArt.texture(sf) if sf != "" else null
	crest_rect.visible = sf != ""
	crest_rect.tooltip_text = FactionData.name_of(sf)
	sub_label.text = "%s  •  Tier %d  •  %s  •  %s system  •  Security %.1f%s" % [station_type()["name"], int(station["tier"]),
		FactionData.name_of(sf) if sf != "" else "Free port",
		Universe.systems[GameState.current_system]["name"], float(Universe.systems[GameState.current_system]["security"]),
		("  •  Your standing: %s (%+.0f)" % [GameState.rep.tier_name(sf), GameState.rep.get_rep(sf)]) if sf != "" else ""]
	if GameState.stations.is_down(String(station.get("id", ""))):
		sub_label.text += "  •  OFFLINE (raided)"


## Rebuild whatever is currently shown (after a transaction etc.).
func rebuild() -> void:
	if not visible:
		return
	_update_header()
	if current_service == "":
		show_concourse(false)
	elif _panel != null and _panel.has_method("build"):
		_panel.build()


func _report_turn_ins() -> void:
	var f := fit()
	if f == null:
		return
	for m in GameState.missions:
		if Missions.can_turn_in(m, f, station["id"]):
			GameState.log_msg("BlackLedger: contract '%s' can be turned in at the Bulletin Board." % m["title"], GameState.COL_GOOD)


# ---------------------------------------------------------------- Concourse

func service_available(svc: Dictionary) -> String:
	if GameState.stations.is_down(String(station.get("id", ""))):
		return "Offline after the pirate raid"
	var only: Array = station_type().get("services", [])
	if not only.is_empty() and not String(svc["id"]) in only:
		return "Not offered at a %s" % String(station_type()["name"]).to_lower()
	if String(station.get("type", "")) == "pirate_haven":
		match String(svc["id"]):
			"bonds":
				return "Sable Writ Exchange keeps no office in a pirate haven"
			"bulletin":
				return "BlackLedger does not post contracts here"
	match String(svc.get("requires", "")):
		"shipyard":
			return "" if not station["shipyard"].is_empty() else "No shipyard at this station"
		"refinery":
			return "" if Industry.refinery_yield(station) > 0.0 else "No refinery at this station"
		"manufacturing":
			return "" if not station_type().get("manufacturing", []).is_empty() else "No fabricators at this station"
	return ""


## Services shown in the ship column (the rest sit as tiles in the station column; the news archive opens
## from the news column).
const SHIP_SERVICES := ["fuel", "repair", "drones", "outfitter", "hangar"]
var concourse_tiles := 0          # tiles built in the last concourse (smoke test)


## Package 27: the concourse in three columns – commander and news on the left, the docked ship with its
## state and the ship services in the middle, the station (faction, economy, balance) and its services on
## the right. Long tiles with icons.
func show_concourse(animate: bool = false) -> void:
	current_service = ""
	_panel = null
	crumb_label.text = "STATION CONCOURSE"
	sub_label.visible = false
	credits_label.visible = false
	_kill_tile_tweens()
	UI.clear(body)
	concourse_tiles = 0
	var cols := UI.hbox(14)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(cols)
	var left := UI.vbox(14)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 0.95
	cols.add_child(left)
	var tiles: Array = []
	_cmdr_column(_column(left, UI.NEON_PINK, 1.0))
	_news_column(_column(left, Color(1.0, 0.8, 0.4), 1.25), tiles)
	_ship_column(_column(cols, UI.NEON_CYAN, 1.1), tiles)
	_station_column(_column(cols, Color(0.7, 0.55, 1.0), 1.15), tiles)
	concourse_tiles = tiles.size()
	if animate:
		var k := 0
		for tile in tiles:
			tile.modulate.a = 0.0
			var tw := create_tween()
			_tile_tweens.append(tw)
			tw.tween_interval(0.1 + k * 0.05)
			tw.tween_method(_set_tile_alpha.bind(tile), 0.0, 1.0, 0.25)
			k += 1


## A framed column (or column part) that scrolls if it runs long; returns its content box.
func _column(parent: Control, col: Color, ratio: float) -> VBoxContainer:
	var box := UI.neon_panel(Color(col, 0.55), Color(0.035, 0.02, 0.07, 0.9), 1)
	if parent is HBoxContainer:
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.size_flags_stretch_ratio = ratio
	parent.add_child(box)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(sc)
	var v := UI.vbox(6)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(v)
	v.set_meta("col", col)
	return v


func _head(v: Control, text: String, col: Color) -> void:
	v.add_child(UI.label(text, 15, col))
	var line := ColorRect.new()
	line.color = Color(col, 0.45)
	line.custom_minimum_size = Vector2(0, 1)
	v.add_child(line)


## A long tile: icon, title, a line below; `cb` runs on click. Disabled with `reason` shown instead.
func _long_tile(v: Control, icon: String, title: String, sub: String, col: Color, cb: Callable, reason: String = "", tiles: Array = []) -> Button:
	var ok := reason == ""
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 45)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.disabled = not ok
	for st in ["normal", "hover", "pressed", "disabled"]:
		var sb := UI.panel_style(Color(0.05, 0.03, 0.1, 0.95), Color(col, 0.9 if st == "hover" else (0.2 if not ok else 0.45)))
		sb.set_border_width_all(1)
		sb.border_width_left = 4
		if st == "hover":
			sb.bg_color = Color(col.darkened(0.8), 0.95)
			sb.shadow_color = Color(col, 0.35)
			sb.shadow_size = 8
		b.add_theme_stylebox_override(st, sb)
	b.pressed.connect(cb)
	UI.click_sound(b)
	var row := UI.hbox(12)
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 12
	row.offset_right = -8
	row.offset_top = 2
	row.offset_bottom = -2
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(row)
	var ic := UI.icon(PixelArt.icon_texture(icon), 30)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not ok:
		ic.modulate = Color(0.4, 0.4, 0.45)
	row.add_child(ic)
	var tv := UI.vbox(0)
	tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(tv)
	tv.add_child(UI.label(title.to_upper(), 15, col if ok else UI.TEXT_DIM))
	tv.add_child(UI.label(sub if ok else reason, 12, UI.TEXT_DIM if ok else UI.BAD))
	for ch in tv.get_children():
		ch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(b)
	tiles.append(b)
	return b


func _svc(id: String) -> Dictionary:
	for s2 in GameData.services:
		if s2["id"] == id:
			return s2
	return {}


## A service tile (opens its panel), run by its corporation.
func _service_tile(v: Control, svc: Dictionary, tiles: Array) -> void:
	var c: Dictionary = GameData.corp(svc["corp"])
	var sid: String = svc["id"]
	_long_tile(v, String(svc["icon"]), String(svc["title"]), "%s  [%s]" % [c["name"], c["tag"]], c["color"], func(): open_service(sid), service_available(svc), tiles)


# ---- left: the commander (placeholder for portrait and career) and the news

func _cmdr_column(v: VBoxContainer) -> void:
	var col: Color = v.get_meta("col")
	_head(v, "COMMANDER", col)
	var row := UI.hbox(14)
	v.add_child(row)
	var frame := UI.neon_panel(Color(col, 0.5), Color(0.02, 0.01, 0.05, 1.0), 1)
	row.add_child(frame)
	var por := TextureRect.new()
	por.texture = PilotArtX.portrait(GameState.pilot.get("look", {}))      # package 28
	por.custom_minimum_size = Vector2(96, 112)
	por.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	por.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	por.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.add_child(por)
	var st := UI.vbox(3)
	row.add_child(st)
	st.add_child(UI.label("CMDR %s" % GameState.pilot_title(), 18, UI.NEON_CYAN))
	var attr_txt: Array = []
	for at in PilotDataX.ATTRS:
		attr_txt.append("%s %d" % [String(at[1]).left(3).to_upper(), GameState.pilot_attr(String(at[0]))])
	st.add_child(UI.label("  ".join(PackedStringArray(attr_txt)), 12, UI.GOLD))
	st.add_child(UI.label("Rank: —", 13, UI.TEXT_DIM))
	st.add_child(UI.label("Ships owned: %d" % GameState.fleet.size(), 13))
	st.add_child(UI.label("Contracts running: %d" % GameState.missions.size(), 13))
	st.add_child(UI.label("Flight time: %s" % SaveGame.fmt_time(GameState.play_time), 13))
	v.add_child(UI.wrap_label("Career statistics and the skills follow with the next packages.", 11, UI.TEXT_DIM, 330))


func _news_column(v: VBoxContainer, tiles: Array) -> void:
	var col: Color = v.get_meta("col")
	_head(v, "NEWS", col)
	var sid := GameState.current_system
	var n := 0
	for it in GameState.news.items:
		var kind := String(it["kind"])
		if kind == "radio" and int(it["system"]) != sid:
			continue
		var kc: Color = {"alert": Color(1.0, 0.35, 0.3), "radio": Color(0.45, 0.85, 1.0)}.get(kind, col)
		var card := UI.neon_panel(Color(kc, 0.35), Color(kc.darkened(0.85), 0.6), 1)
		v.add_child(card)
		var cv := UI.vbox(1)
		card.add_child(cv)
		cv.add_child(UI.label("%s   %s" % [SaveGame.fmt_time(float(it["t"])), {"alert": "RAID", "radio": "RADIO"}.get(kind, "NEWS")], 11, kc))
		var txt := String(it["text"])
		if txt.length() > 120:
			txt = txt.substr(0, 117) + " …"
		cv.add_child(UI.wrap_label(txt, 12, Color(0.9, 0.92, 1.0), 330))
		n += 1
		if n >= 6:
			break
	if n == 0:
		v.add_child(UI.label("Nothing to report.", 13, UI.TEXT_DIM))
	_service_tile(v, _svc("news"), tiles)


# ---- middle: the docked ship, its state and the ship services

func _ship_column(v: VBoxContainer, tiles: Array) -> void:
	var col: Color = v.get_meta("col")
	_head(v, "SHIP ANALYSIS", col)
	var f := fit()
	if f == null:
		v.add_child(UI.label("Your active ship is not docked here.", 14, UI.BAD))
	else:
		var s := f.stats()
		var h := f.hull()
		v.add_child(UI.label(f.ship_name, 18, UI.NEON_CYAN))
		v.add_child(UI.label("%s  •  %s  •  Size %s" % [String(h["name"]), String(h.get("class", "")), ["", "S", "M", "L"][clampi(int(h.get("size", 1)), 1, 3)]], 12, UI.TEXT_DIM))
		var shot := TextureRect.new()
		shot.texture = PixelArt.ship_texture(f.hull_id, "player")
		shot.custom_minimum_size = Vector2(0, 104)
		shot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		shot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		shot.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		v.add_child(shot)
		var rows: Array = [
			["Hull", f.structure, float(s["structure_max"]), Color(0.9, 0.3, 0.3)],
			["Armor", f.armor, float(s["armor_max"]), Color(1.0, 0.8, 0.3)],
			["Fuel tank", f.fuel, float(s["fuel_max"]), Color(0.4, 0.9, 0.5)],
			["Cargo", f.cargo_used(), float(s["cargo_max"]), Color(0.6, 0.75, 1.0)],
		]
		if int(s.get("drone_storage", 0)) > 0:
			rows.append(["Drones", float(f.drones.size()), float(s["drone_storage"]), Color(0.75, 0.6, 1.0)])
		for r in rows:
			var hr := UI.hbox(10)
			v.add_child(hr)
			var nl := UI.label(String(r[0]).to_upper(), 12, UI.TEXT_DIM)
			nl.custom_minimum_size = Vector2(86, 0)
			hr.add_child(nl)
			var b := UI.bar(r[3], 180)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.max_value = maxf(float(r[2]), 0.001)
			b.value = float(r[1])
			hr.add_child(b)
			var pl := UI.label(("%d / %d" % [int(r[1]), int(r[2])]) if r[0] in ["Cargo", "Drones"] else "%d%%" % int(round(100.0 * float(r[1]) / maxf(float(r[2]), 0.001))), 12)
			pl.custom_minimum_size = Vector2(70, 0)
			hr.add_child(pl)
	_head(v, "SHIP SERVICES", col)
	var fuel_svc := _svc("fuel")
	var rep_svc := _svc("repair")
	if f != null:
		var fc := Commands.service_cost("fuel", f)
		var rc := Commands.service_cost("repair", f)
		var uid: int = f.uid
		var why_f := service_available(fuel_svc)
		var why_r := service_available(rep_svc)
		_long_tile(v, "o_fuel", "Refuel" + ("  (%s)" % GameData.fmt_credits(fc) if fc > 0 else "  (full)"), String(GameData.corp(fuel_svc["corp"])["name"]),
			GameData.corp(fuel_svc["corp"])["color"], func(): _quick("refuel", uid), why_f if why_f != "" else ("" if fc > 0 else "Tank full"), tiles)
		_long_tile(v, "t_repair", "Repair all" + ("  (%s)" % GameData.fmt_credits(rc) if rc > 0 else "  (at full health)"), String(GameData.corp(rep_svc["corp"])["name"]),
			GameData.corp(rep_svc["corp"])["color"], func(): _quick("repair", uid), why_r if why_r != "" else ("" if rc > 0 else "No damage"), tiles)
	for sid in ["drones", "outfitter", "hangar"]:
		_service_tile(v, _svc(sid), tiles)


## Refuel / repair straight from the concourse.
func _quick(kind: String, uid: int) -> void:
	var err := Commands.execute({"type": kind, "uid": uid})
	if err != "":
		GameState.log_msg(err, GameState.COL_WARN)
	rebuild()


# ---- right: the station – faction, economy, the pilot's balance – and its services

func _station_column(v: VBoxContainer, tiles: Array) -> void:
	var col: Color = v.get_meta("col")
	_head(v, "STATION", col)
	var sf := String(station.get("faction", ""))
	var row := UI.hbox(12)
	v.add_child(row)
	if sf != "":
		row.add_child(UI.icon(CrestArt.texture(sf), 52))
	var nv := UI.vbox(1)
	row.add_child(nv)
	nv.add_child(UI.label(String(station["name"]), 17, UI.NEON_CYAN))
	nv.add_child(UI.label("%s  •  Tier %d" % [station_type()["name"], int(station["tier"])], 13))
	var sys: Dictionary = Universe.systems[GameState.current_system]
	nv.add_child(UI.label("%s system  •  Security %.1f" % [sys["name"], float(sys["security"])], 12, UI.TEXT_DIM))
	if sf != "":
		v.add_child(UI.label("%s  •  your standing: %s (%+.0f)" % [FactionData.name_of(sf), GameState.rep.tier_name(sf), GameState.rep.get_rep(sf)], 13, FactionData.color_of(sf)))
	else:
		v.add_child(UI.label("Free port – no faction", 13, UI.TEXT_DIM))
	var t := station_type()
	var prod: Array = []
	for it in t.get("produces", []):
		prod.append(GameData.item_name(String(it)))
	var need: Array = []
	for it2 in t.get("consumes", []):
		need.append(GameData.item_name(String(it2)))
	v.add_child(UI.wrap_label("Economy – produces: %s" % (", ".join(prod) if not prod.is_empty() else "—"), 12, UI.TEXT_DIM, 380))
	v.add_child(UI.wrap_label("Needs: %s" % (", ".join(need) if not need.is_empty() else "—"), 12, UI.TEXT_DIM, 380))
	if GameState.stations.is_down(String(station.get("id", ""))):
		v.add_child(UI.wrap_label(GameState.stations.down_error(station), 13, UI.BAD, 380))
		_relief_panel(v)
	var bal := UI.neon_panel(Color(UI.GOLD, 0.45), Color(0.08, 0.06, 0.02, 0.8), 1)
	v.add_child(bal)
	var bh := UI.hbox(10)
	bal.add_child(bh)
	bh.add_child(UI.label("BALANCE", 13, UI.TEXT_DIM))
	bh.add_child(UI.spacer())
	bh.add_child(UI.label(GameData.fmt_credits(GameState.credits), 20, UI.GOLD))
	_head(v, "STATION SERVICES", col)
	for svc in GameData.services:
		if String(svc["id"]) in SHIP_SERVICES or svc["id"] == "news":
			continue
		_service_tile(v, svc, tiles)


## Relief deliveries for a station knocked out by a raid (package 15): any portion, 2x base price.
func _relief_panel(parent: Control) -> void:
	var e: Dictionary = GameState.stations.status(String(station["id"]))
	var box := UI.neon_panel(Color(1.0, 0.35, 0.3, 0.7), Color(0.08, 0.03, 0.04, 0.95), 2)
	parent.add_child(box)
	var v := UI.vbox(6)
	box.add_child(v)
	v.add_child(UI.label("RELIEF EFFORT – the station needs supplies to come back online", 16, UI.BAD))
	v.add_child(UI.wrap_label("Deliver any amount: every unit pays %d× its base price. When everything has arrived the station reopens at once – bonus %s and standing with the %s. Otherwise its crews need %d more minutes." % [int(GameState.stations.PRICE_MULT), GameData.fmt_credits(GameState.stations.BONUS_PER_TIER * int(e["tier"])), FactionData.name_of(String(e["faction"])), int(ceil((float(e["until"]) - GameState.play_time) / 60.0))], 13, UI.TEXT_DIM, 360))
	var f := fit()
	for item in e["need"]:
		var it: String = item
		var need := int(e["need"][it])
		var got := int(e["got"].get(it, 0))
		var row := UI.hbox(14)
		v.add_child(row)
		var nl := UI.label(GameData.item_name(it), 14)
		nl.custom_minimum_size = Vector2(200, 0)
		row.add_child(nl)
		var bar := UI.bar(UI.GOOD if got >= need else UI.GOLD, 260)
		bar.max_value = float(need)
		bar.value = float(got)
		row.add_child(bar)
		row.add_child(UI.label("%d / %d" % [got, need], 13))
		row.add_child(UI.label("%s each" % GameData.fmt_credits(GameState.stations.unit_price(it)), 13, UI.GOLD))
		var have := int(floor(float(f.cargo.get(it, 0.0)) + 0.001)) if f != null else 0
		var b1 := UI.button("Deliver 1", func(): _relief(it, 1))
		b1.disabled = have <= 0 or got >= need
		row.add_child(b1)
		var b2 := UI.button("Deliver all (%d in hold)" % have, func(): _relief(it, -1))
		b2.disabled = have <= 0 or got >= need
		row.add_child(b2)


func _relief(item: String, n: int) -> void:
	Commands.execute({"type": "relief_deliver", "item": item, "amount": n})
	rebuild()


func _set_tile_alpha(a: float, tile) -> void:
	if is_instance_valid(tile):
		tile.modulate.a = a


func _kill_tile_tweens() -> void:
	for tw in _tile_tweens:
		if tw != null and tw.is_valid():
			tw.kill()
	_tile_tweens.clear()


# ---------------------------------------------------------------- Service view

func open_service(svc_id: String) -> void:
	var svc: Dictionary = {}
	for s in GameData.services:
		if s["id"] == svc_id:
			svc = s
	if svc.is_empty() or service_available(svc) != "":
		return
	GameState.codex.event("corp:" + String(svc["corp"]))
	current_service = svc_id
	sub_label.visible = true
	credits_label.visible = true
	var c: Dictionary = GameData.corp(svc["corp"])
	var col: Color = c["color"]
	crumb_label.text = "STATION CONCOURSE  ›  %s" % String(svc["title"]).to_upper()
	_kill_tile_tweens()
	UI.clear(body)
	# Corporate banner
	var banner := UI.neon_panel(col, Color(col.darkened(0.85), 0.9), 1)
	body.add_child(banner)
	var bh := UI.hbox(14)
	banner.add_child(bh)
	bh.add_child(UI.button("‹ Concourse", func(): show_concourse(true)))
	bh.add_child(UI.icon(PixelArt.icon_texture(svc["icon"]), 40))
	var bv := UI.vbox(0)
	bh.add_child(bv)
	bv.add_child(UI.label("%s  —  %s" % [String(svc["title"]).to_upper(), c["name"]], 18, col))
	bv.add_child(UI.label("“%s”   %s" % [c["slogan"], c["desc"]], 12, UI.TEXT_DIM))
	# Panel
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	_panel = load(svc["panel"]).new()
	_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_panel)
	_panel.setup(self, svc)
	_panel.build()
	_panel.modulate.a = 0.0
	_panel.create_tween().tween_property(_panel, "modulate:a", 1.0, 0.25)
