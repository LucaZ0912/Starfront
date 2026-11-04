class_name StationUI
extends CanvasLayer
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


func close() -> void:
	if not visible:
		return
	visible = false
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


func show_concourse(animate: bool = false) -> void:
	current_service = ""
	_panel = null
	crumb_label.text = "STATION CONCOURSE"
	_kill_tile_tweens()
	UI.clear(body)
	var hint := UI.label("Docking clearance granted. Every service on this station is run under exclusive corporate licence.", 13, UI.TEXT_DIM)
	body.add_child(hint)
	if GameState.stations.is_down(String(station.get("id", ""))):
		hint.text = GameState.stations.down_error(station)
		hint.add_theme_color_override("font_color", UI.BAD)
		_relief_panel()
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(grid)
	var i := 0
	for svc in GameData.services:
		var tile := _make_tile(svc)
		grid.add_child(tile)
		if animate:
			tile.modulate.a = 0.0
			var tw := create_tween()
			_tile_tweens.append(tw)
			tw.tween_interval(0.12 + i * 0.06)
			tw.tween_method(_set_tile_alpha.bind(tile), 0.0, 1.0, 0.25)
		i += 1


## Relief deliveries for a station knocked out by a raid (package 15): any portion, 2x base price.
func _relief_panel() -> void:
	var e: Dictionary = GameState.stations.status(String(station["id"]))
	var box := UI.neon_panel(Color(1.0, 0.35, 0.3, 0.7), Color(0.08, 0.03, 0.04, 0.95), 2)
	body.add_child(box)
	var v := UI.vbox(6)
	box.add_child(v)
	v.add_child(UI.label("RELIEF EFFORT – the station needs supplies to come back online", 16, UI.BAD))
	v.add_child(UI.wrap_label("Deliver any amount: every unit pays %d× its base price. When everything has arrived the station reopens at once – bonus %s and standing with the %s. Otherwise its crews need %d more minutes." % [int(GameState.stations.PRICE_MULT), GameData.fmt_credits(GameState.stations.BONUS_PER_TIER * int(e["tier"])), FactionData.name_of(String(e["faction"])), int(ceil((float(e["until"]) - GameState.play_time) / 60.0))], 13, UI.TEXT_DIM, 1100))
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


func _make_tile(svc: Dictionary) -> Control:
	var c: Dictionary = GameData.corp(svc["corp"])
	var col: Color = c["color"]
	var reason := service_available(svc)
	var ok := reason == ""
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(340, 122)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.disabled = not ok
	for st in ["normal", "hover", "pressed", "disabled"]:
		var sb := UI.panel_style(Color(0.05, 0.03, 0.1, 0.95), Color(col, 0.9 if st == "hover" else (0.25 if not ok else 0.55)))
		sb.set_border_width_all(3 if st == "hover" else 2)
		if st == "hover":
			sb.bg_color = Color(col.darkened(0.8), 0.95)
			sb.shadow_color = Color(col, 0.4)
			sb.shadow_size = 10
		b.add_theme_stylebox_override(st, sb)
	var svc_id: String = svc["id"]
	b.pressed.connect(func(): open_service(svc_id))
	var row := UI.hbox(14)
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 14
	row.offset_right = -10
	row.offset_top = 10
	row.offset_bottom = -10
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(row)
	var ic := UI.icon(PixelArt.icon_texture(svc["icon"]), 72)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not ok:
		ic.modulate = Color(0.4, 0.4, 0.45)
	row.add_child(ic)
	var tv := UI.vbox(1)
	tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(tv)
	tv.add_child(UI.label(svc["title"].to_upper(), 19, col if ok else UI.TEXT_DIM))
	tv.add_child(UI.label("%s  [%s]" % [c["name"], c["tag"]], 12, Color(0.85, 0.88, 0.95) if ok else UI.TEXT_DIM))
	tv.add_child(UI.label("“%s”" % c["slogan"] if ok else reason, 12, UI.TEXT_DIM if ok else UI.BAD))
	for ch in tv.get_children():
		ch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


# ---------------------------------------------------------------- Service view

func open_service(svc_id: String) -> void:
	var svc: Dictionary = {}
	for s in GameData.services:
		if s["id"] == svc_id:
			svc = s
	if svc.is_empty() or service_available(svc) != "":
		return
	current_service = svc_id
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
