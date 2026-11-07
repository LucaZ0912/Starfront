class_name HUD
extends CanvasLayer
## In-game HUD: top bar, ship panel (active ship), module bar (bottom centre, keys 1–9),
## locked targets (top centre), selected-item panel (top right, actions for the clicked object),
## overview (warp targets), message log, tooltip, help.

signal galaxy_requested
signal station_requested
signal ship_menu_requested
signal pilot_window_requested          # package 29
signal pilot_tab_requested(tab: int)   # 0.5.30.5: the hint opens the skill tree or the perks

const FactionData = preload("res://data/factions.gd")
const KIND_ICONS := {"star": "☀", "planet": "●", "station": "■", "gate": "◎", "field": "⁘", "anomaly": "◆", "colossus": "⬢", "haven": "✖"}

var view: SystemView
var credits_label: Label
var system_label: Label
var station_btn: Button
var ship_box: VBoxContainer
var ticker_label: Label
var _ticker_clip: Control
var codex_label: Label             # "New Codex entry" notice (package 18)
var _codex_until := 0.0
var _warn_text := ""                # big warning in the bottom banner (GameState.warn)
var _warn_until := 0.0
var _ticker_queue: Array = []      # news not shown yet – each item runs through the ticker once
const TICKER_SPEED := 70.0
const TICKER_KIND := {"alert": ["RAID ·", Color(1.0, 0.4, 0.35)], "radio": ["RADIO ·", Color(0.5, 0.88, 1.0)], "world": ["NEWS ·", Color(1.0, 0.82, 0.45)]}
var log_label: RichTextLabel
var hover_panel: PanelContainer
var hover_label: Label
var help_panel: PanelContainer
var overview_box: VBoxContainer
var level_btns: Array = []
var nav_btns := {}                 # 0.5.30.3: ship / pilot / map icon buttons
var top_btns := {}           # action id -> [Button, caption]
var help_text: RichTextLabel
var _w := {}
var _overview_rows: Array = []
var contacts_box: VBoxContainer   # ships in the system (package 11)
var _contact_rows := {}           # uid -> Button
var _contact_sig := ""
var _ov_tab := "overview"
var _tab_btns := {}
var _ov_timer := 0.0
# Manual control
var module_bar: HBoxContainer
var module_slots: Array = []      # slot keys in bar order (hotkeys 1–9)
var _module_tiles := {}           # slot -> {panel, bar, style}
var _module_sig := ""
var lock_bar: HBoxContainer
var ally_bar: VBoxContainer       # allied ships of the pilot's group (top left)
var drone_panel: PanelContainer   # package 23: drone control (top left edge)
var _drone_box: VBoxContainer
var _drone_sig := ""
var _drone_rows: Array = []       # [{drone, fuel bar, hull bar}]
var _ally_cards := {}             # ship -> {style, info, bars}
var _ally_sig := ""
var _lock_cards := {}             # key -> {panel, style, info, bars}
var _lock_sig := ""
var sel_panel: PanelContainer
var sel_box: VBoxContainer
var selected_id := ""
var _sel_info: Label
var zone_label: Label
var survey_panel: PanelContainer
var survey_text: RichTextLabel

## on = working on the active target, other = working on another locked target (multi-focus),
## range = target out of reach, energy = capacitor too low, power = its priority group is shut down
const BUILTIN_COLOR := Color(1.0, 0.72, 0.2)   # frame of modules built into the hull (package 25a)
const STATE_COLORS := {"off": Color(0.35, 0.42, 0.55), "on": Color(0.35, 1.0, 0.5), "other": Color(1.0, 0.92, 0.25), "range": Color(1.0, 0.55, 0.2), "wait": Color(0.95, 0.85, 0.55), "energy": Color(0.7, 0.45, 1.0), "power": Color(1.0, 0.3, 0.25)}
const KIND_NAMES := {"ship": "Ship", "asteroid": "Asteroid", "wreck": "Wreck", "anomaly": "Anomaly", "station": "Station", "gate": "Hyperspace gate", "planet": "Planet", "star": "Star", "field": "Asteroid field", "colossus": "Colossal asteroid", "haven": "Pirate haven"}


func _ready() -> void:
	layer = 10
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# --- Top bar
	var top := UI.panel()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 44
	root.add_child(top)
	var hb := UI.hbox(18)
	top.add_child(hb)
	# 0.5.30.3: three icon buttons top right – ship, pilot, map (zoom, station and help stay on their keys)
	var nav := UI.hbox(4)
	for nb in [["ship_menu", "Ship", "hud_ship", "Ship info, modules, stats and inventory"],
			["pilot_window", "Pilot", "hud_pilot", "Pilot: skills, perks, skill tree"],
			["galaxy_map", "Map", "hud_map", "Galaxy map"]]:
		var act: String = nb[0]
		var b := UI.button(String(nb[1]), func(): _nav_pressed(act), String(nb[3]))
		var ic: Image = PixelArt.icon_texture(String(nb[2])).get_image()
		ic.resize(ic.get_width() * 2, ic.get_height() * 2, Image.INTERPOLATE_NEAREST)
		b.icon = ImageTexture.create_from_image(ic)
		b.custom_minimum_size = Vector2(0, 38)
		b.add_theme_font_size_override("font_size", 14)
		nav.add_child(b)
		top_btns[act] = [b, String(nb[1])]
		nav_btns[act] = b
	credits_label = UI.label("", 17, Color(1.0, 0.85, 0.4))
	hb.add_child(credits_label)
	system_label = UI.label("", 17, UI.ACCENT)
	hb.add_child(system_label)
	hb.add_child(UI.spacer())
	hb.add_child(nav)                  # top right, where the old buttons were

	# --- Ship panel (bottom left)
	var sp := UI.panel()
	sp.anchor_left = 0
	sp.anchor_right = 0
	sp.anchor_top = 1
	sp.anchor_bottom = 1
	sp.offset_left = 10
	sp.offset_bottom = -10
	sp.grow_vertical = Control.GROW_DIRECTION_BEGIN
	sp.custom_minimum_size = Vector2(320, 0)
	root.add_child(sp)
	var spv := UI.vbox(4)
	sp.add_child(spv)
	ship_box = UI.vbox(4)
	spv.add_child(ship_box)
	# news ticker (package 16): raids, Cluster news and the radio of this system
	_ticker_clip = Control.new()
	_ticker_clip.clip_contents = true
	_ticker_clip.custom_minimum_size = Vector2(300, 20)
	_ticker_clip.visible = false
	_ticker_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spv.add_child(_ticker_clip)
	ticker_label = UI.label("", 13, UI.TEXT_DIM)
	ticker_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ticker_clip.add_child(ticker_label)
	GameState.warning.connect(func(t): _warn_text = t; _warn_until = GameState.play_time + 6.0)
	GameState.news_added.connect(func(it):
		if it.get("ticker", true):
			_ticker_queue.push_back(it))

	# --- Overview (right)
	var ov := UI.panel(Color(0.03, 0.05, 0.09, 0.85))
	ov.anchor_left = 1
	ov.anchor_right = 1
	ov.offset_left = -330
	ov.offset_right = -10
	ov.offset_top = 262
	ov.anchor_bottom = 1
	ov.offset_bottom = -210
	root.add_child(ov)
	var ovv := UI.vbox(4)
	ov.add_child(ovv)
	var tabs := UI.hbox(4)
	ovv.add_child(tabs)
	for tab in [["overview", "Overview"], ["contacts", "Contacts"]]:
		var tb := Button.new()
		tb.text = tab[1]
		tb.toggle_mode = true
		tb.focus_mode = Control.FOCUS_NONE
		tb.add_theme_font_size_override("font_size", 12)
		var tid: String = tab[0]
		tb.pressed.connect(func(): _set_ov_tab(tid))
		tabs.add_child(tb)
		_tab_btns[tid] = tb
	tabs.add_child(UI.label("click to select", 11, UI.TEXT_DIM))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ovv.add_child(scroll)
	var lists := UI.vbox(0)
	lists.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(lists)
	overview_box = UI.vbox(2)
	overview_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lists.add_child(overview_box)
	contacts_box = UI.vbox(2)
	contacts_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contacts_box.visible = false
	lists.add_child(contacts_box)
	_set_ov_tab("overview")

	# --- Selected item (top right): actions for the clicked object
	sel_panel = UI.panel(Color(0.03, 0.05, 0.09, 0.9))
	sel_panel.anchor_left = 1
	sel_panel.anchor_right = 1
	sel_panel.offset_left = -330
	sel_panel.offset_right = -10
	sel_panel.offset_top = 54
	sel_panel.offset_bottom = 254
	root.add_child(sel_panel)
	sel_box = UI.vbox(5)
	sel_panel.add_child(sel_box)
	_build_selected()

	# --- Drone control (top left edge, package 23): folded while no drone is out
	drone_panel = UI.panel(Color(0.03, 0.06, 0.05, 0.9))
	drone_panel.position = Vector2(0, 50)
	drone_panel.custom_minimum_size = Vector2(250, 0)
	root.add_child(drone_panel)
	_drone_box = UI.vbox(4)
	drone_panel.add_child(_drone_box)

	# --- Allied ships travelling with the pilot (top left)
	ally_bar = UI.vbox(4)
	ally_bar.position = Vector2(10, 54)
	root.add_child(ally_bar)

	# --- Locked targets (top centre)
	lock_bar = UI.hbox(8)
	lock_bar.position = Vector2(360, 54)
	root.add_child(lock_bar)

	# --- "New Codex entry" (top centre, package 18)
	codex_label = UI.label("", 15, UI.GOLD)
	codex_label.anchor_left = 0.5
	codex_label.anchor_right = 0.5
	codex_label.offset_left = -400
	codex_label.offset_right = 400
	codex_label.offset_top = 96
	codex_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	codex_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	codex_label.add_theme_constant_override("shadow_offset_x", 2)
	codex_label.add_theme_constant_override("shadow_offset_y", 2)
	root.add_child(codex_label)
	GameState.codex_unlocked.connect(_on_codex_unlocked)

	# --- No-fire zone / hostile guns banner (bottom centre, above the module bar)
	zone_label = UI.label("", 14, UI.GOLD)
	zone_label.anchor_left = 0.5
	zone_label.anchor_right = 0.5
	zone_label.anchor_top = 1.0
	zone_label.anchor_bottom = 1.0
	zone_label.offset_left = -360
	zone_label.offset_right = 360
	zone_label.offset_top = -112
	zone_label.offset_bottom = -90
	zone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zone_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	zone_label.add_theme_constant_override("shadow_offset_x", 1)
	zone_label.add_theme_constant_override("shadow_offset_y", 1)
	root.add_child(zone_label)

	# --- Long-range survey results (package 7)
	survey_panel = UI.panel()
	survey_panel.position = Vector2(14, 120)
	survey_panel.custom_minimum_size = Vector2(430, 0)
	survey_panel.visible = false
	root.add_child(survey_panel)
	var svb := UI.vbox(6)
	survey_panel.add_child(svb)
	var svh := UI.hbox(6)
	svb.add_child(svh)
	svh.add_child(UI.label("SURVEY RESULTS", 16, UI.ACCENT))
	svh.add_child(UI.spacer())
	svh.add_child(UI.button("Close", func(): survey_panel.visible = false))
	survey_text = RichTextLabel.new()
	survey_text.bbcode_enabled = true
	survey_text.fit_content = true
	survey_text.custom_minimum_size = Vector2(410, 0)
	survey_text.scroll_active = false
	svb.add_child(survey_text)
	GameState.survey_done.connect(show_survey)

	# --- Module bar (bottom centre, EVE-style)
	module_bar = UI.hbox(6)
	module_bar.anchor_left = 0.5
	module_bar.anchor_right = 0.5
	module_bar.anchor_top = 1
	module_bar.anchor_bottom = 1
	module_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	module_bar.offset_top = -82
	module_bar.offset_bottom = -10
	module_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(module_bar)

	# --- Log (bottom right)
	var log_panel := UI.panel(Color(0.03, 0.05, 0.09, 0.8))
	log_panel.anchor_left = 1
	log_panel.anchor_right = 1
	log_panel.anchor_top = 1
	log_panel.anchor_bottom = 1
	log_panel.offset_left = -470
	log_panel.offset_right = -10
	log_panel.offset_top = -195
	log_panel.offset_bottom = -10
	log_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(log_panel)
	log_label = RichTextLabel.new()
	log_label.bbcode_enabled = true
	log_label.scroll_following = true
	log_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	log_label.add_theme_font_size_override("normal_font_size", 12)
	log_panel.add_child(log_label)

	# --- Tooltip
	hover_panel = UI.panel(Color(0.02, 0.03, 0.06, 0.92))
	hover_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_panel.visible = false
	root.add_child(hover_panel)
	hover_label = UI.label("", 13)
	hover_panel.add_child(hover_label)

	# --- Help
	help_panel = UI.panel(Color(0.03, 0.05, 0.1, 0.96))
	help_panel.set_anchors_preset(Control.PRESET_CENTER)
	help_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	help_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	help_panel.visible = false
	root.add_child(help_panel)
	var ht := RichTextLabel.new()
	ht.bbcode_enabled = true
	ht.fit_content = true
	ht.custom_minimum_size = Vector2(680, 0)
	help_text = ht
	help_panel.add_child(ht)
	_refresh_keys()
	Keybinds.changed.connect(_refresh_keys)

	GameState.credits_changed.connect(func(_v): _update_header())
	GameState.message.connect(add_message)
	GameState.fleet_changed.connect(rebuild_ship_panel)


const HELP_TEXT := """[b]Sternenfront – Controls[/b]

You fly [b]one[/b] ship. Other ships are parked in station hangars and swapped there.

[color=#7fd8ff]Mouse wheel / {zoom_combat}, {zoom_recon}, {zoom_system}[/color]: zoom levels Combat → Recon → System
[color=#7fd8ff]Click an object[/color] (or an overview entry): it appears in the panel top right with its actions –
   Warp to • Approach • Orbit • Keep at range • Lock target • Dock • Jump
[color=#7fd8ff]Lock targets[/color]: locked targets appear top centre – click one to make it the active target
[color=#7fd8ff]Module bar[/color] (bottom centre): click a tile or press [b]{module_1} … {module_9}[/b] to switch a module on/off.
   Weapons need a locked hostile ship, mining lasers an asteroid, analysers an anomaly, salvagers a wreck.
   Tile border: green = working on the active target, yellow = working on another target, orange = out of range, purple = not enough energy, red = no power.
[color=#7fd8ff]Click empty space[/color]: sublight flight (slow – the system is huge)

{ship_up}{ship_left}{ship_down}{ship_right}: fly the ship in that direction (release: stop)
{cam_up}{cam_left}{cam_down}{cam_right} / drag middle mouse: pan camera • {cam_center}: back to ship
{sel_target}: cycle targets in sensor range • {sel_hostile} / {sel_friend}: cycle hostile / friendly ships • {sel_station}: nearby station • {cmd_lock}: lock / unlock
[color=#7fd8ff]Multi-focus[/color]: every weapon and tool keeps the target that was active when you switched it on (T1, T2 … on its tile).
   Make another lock active and switch more modules on – press a running module's key to move it to the active target.
{cmd_approach} approach • {cmd_warp} warp • {cmd_jump} jump • {cmd_dock} dock • {cmd_follow} follow (the selected object)
[color=#7fd8ff]Drones[/color]: {drone_launch} launch one, {drone_recall} recall (a key for "launch all" can be set in Settings → Controls) – role and behaviour in the drone window (top left). They fly into the hangar for warps and jumps and out again afterwards.
{ship_menu}: ship menu • {station}: station • {galaxy_map}: galaxy map • {menu_back}: close / pause menu
{quicksave} / {quickload}: quicksave / quickload • {debug_menu}: debug menu • All keys: Settings → Controls

[b]Tips[/b]
• Pirates attack you on their own – lock them and switch your weapons on.
• Scanners sweep the whole system passively and reveal hidden anomalies.
• Optical → strong vs shields, kinetic → armor, explosive → structure.
• Hyperspace routes have classes 1–3 – your jump drive must be at least that class.
• The reactor output is a hard limit: passive modules always draw power, weapons and active modules only while in use. On an overload priority group 4 shuts down first, then 3, then 2 (Ship menu → Modules → Power).
"""


func set_view(v: SystemView) -> void:
	view = v
	view.hover_changed.connect(_on_hover)
	view.object_selected.connect(show_selected)
	selected_id = ""
	_lock_sig = "-"
	_module_sig = "-"
	_build_selected()
	view.level_changed.connect(_on_level_changed)
	_on_level_changed(view.level)
	_on_hover("")
	_update_header()
	rebuild_ship_panel()
	refresh_overview()


func _level_btn(i: int) -> void:
	if view != null:
		view.set_level(i)
	_on_level_changed(view.level if view != null else 0)


func _nav_pressed(act: String) -> void:
	match act:
		"ship_menu": ship_menu_requested.emit()
		"pilot_window": pilot_window_requested.emit()
		"galaxy_map": galaxy_requested.emit()


func _on_level_changed(l: int) -> void:
	for i in level_btns.size():
		level_btns[i].button_pressed = i == l


## Button captions and help text follow the current key bindings.
func _refresh_keys() -> void:
	for id in top_btns:
		var k := Keybinds.key_text(id)
		top_btns[id][0].text = "%s [%s]" % [top_btns[id][1], k] if k != "" else top_btns[id][1]
	var t: String = HELP_TEXT
	for a in Keybinds.ACTIONS:
		t = t.replace("{%s}" % a["id"], Keybinds.keys_text(a["id"]) if a["id"] in ["cam_center", "menu_back"] else Keybinds.key_text(a["id"]))
	help_text.text = t
	_module_sig = "-"


func toggle_help() -> void:
	help_panel.visible = not help_panel.visible


func set_stance(st: String) -> void:
	Commands.execute({"type": "stance", "stance": st})
	rebuild_ship_panel()


func add_message(text: String, color: Color) -> void:
	var t := Time.get_time_string_from_system().substr(0, 5)
	log_label.append_text("[color=#8090a0]%s[/color] [color=#%s]%s[/color]\n" % [t, color.to_html(false), text])


func _on_hover(text: String) -> void:
	hover_label.text = text
	hover_panel.visible = text != ""
	hover_panel.reset_size()


func _update_header() -> void:
	credits_label.text = GameData.fmt_credits(GameState.credits)
	var sys: Dictionary = Universe.systems[GameState.current_system]
	system_label.text = "%s  (security %.1f)  •  %s" % [sys["name"], float(sys["security"]), Universe.territory_text(GameState.current_system)]


# ---------------------------------------------------------------- Ship panel

func rebuild_ship_panel() -> void:
	if ship_box == null:
		return
	UI.clear(ship_box)
	_w.clear()
	var f := GameState.active()
	if f == null:
		return
	var head := UI.hbox(8)
	ship_box.add_child(head)
	var icon := TextureRect.new()
	icon.texture = PixelArt.ship_texture(f.hull_id, "player")
	icon.custom_minimum_size = Vector2(56, 40)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	head.add_child(icon)
	var names := UI.vbox(0)
	head.add_child(names)
	names.add_child(UI.label(f.ship_name, 15, UI.ACCENT))
	names.add_child(UI.label("%s %s" % [f.hull()["class"], f.hull()["name"]], 11, Color(0.7, 0.75, 0.85)))
	_w["act"] = UI.label("", 12, Color(0.8, 0.85, 0.95))
	ship_box.add_child(_w["act"])
	# package 29: a skill is ready to advance
	_w["skills"] = UI.button("", func(): pilot_tab_requested.emit(3 if not GameState.tiles_ready().is_empty() else 2))
	_w["skills"].add_theme_color_override("font_color", UI.GOOD)
	_w["skills"].visible = false
	ship_box.add_child(_w["skills"])
	# package 27: the current speed
	var sr := UI.hbox(6)
	var sl := UI.label("Speed", 11, Color(0.65, 0.7, 0.8))
	sl.custom_minimum_size = Vector2(64, 0)
	sr.add_child(sl)
	_w["speed"] = UI.label("", 13, Color(0.55, 0.85, 1.0))
	sr.add_child(_w["speed"])
	ship_box.add_child(sr)
	for spec in [["shield", "Shield", Color(0.35, 0.65, 1.0)], ["armor", "Armor", Color(1.0, 0.8, 0.3)], ["structure", "Structure", Color(0.9, 0.3, 0.3)], ["cap", "Energy", Color(0.6, 0.5, 1.0)], ["fuel", "Fuel", Color(0.4, 0.9, 0.5)]]:
		var row := UI.hbox(6)
		var l := UI.label(spec[1], 11, Color(0.65, 0.7, 0.8))
		l.custom_minimum_size = Vector2(64, 0)
		row.add_child(l)
		var b := UI.bar(spec[2], 230)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(b)
		ship_box.add_child(row)
		_w[spec[0]] = b
	_w["power"] = UI.label("", 12, Color(0.8, 0.85, 0.95))
	ship_box.add_child(_w["power"])
	_w["cargo"] = UI.label("", 12, Color(0.8, 0.85, 0.95))
	ship_box.add_child(_w["cargo"])
	_module_sig = ""


# ---------------------------------------------------------------- Overview

func refresh_overview() -> void:
	if overview_box == null or view == null:
		return
	UI.clear(overview_box)
	_overview_rows.clear()
	for t in Universe.warp_targets(view.system_id):
		var b := Button.new()
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.focus_mode = Control.FOCUS_NONE
		b.clip_text = true
		b.add_theme_font_size_override("font_size", 12)
		b.custom_minimum_size = Vector2(290, 0)
		var target: Dictionary = t
		b.pressed.connect(func(): _overview_click(target))
		overview_box.add_child(b)
		_overview_rows.append({"button": b, "target": t})
	_update_overview()


func _set_ov_tab(t: String) -> void:
	_ov_tab = t
	for k in _tab_btns:
		_tab_btns[k].set_pressed_no_signal(k == t)
	if overview_box != null:
		overview_box.visible = t == "overview"
		contacts_box.visible = t == "contacts"
	_contact_sig = ""
	_update_contacts()


## Contacts: every ship in the system (except your own) with role, faction and distance.
func _update_contacts() -> void:
	if contacts_box == null or view == null or not contacts_box.visible:
		if _tab_btns.has("contacts") and view != null and view.ship_layer != null:
			var cnt := 0
			for n0 in view.ship_layer.get_children():
				if n0 is Ship and n0 != view.player and not n0.dying and not n0.is_docked() and not n0.is_drone:
					cnt += 1
			_tab_btns["contacts"].text = "Contacts (%d)" % cnt
		return
	var pp: Vector2 = view._player_pos()
	var ships: Array = []
	for n in view.ship_layer.get_children():
		if n is Ship and n != view.player and not n.dying and not n.is_docked() and not n.is_drone and view.contact_visible(n):
			ships.append(n)
	ships.sort_custom(func(a, b): return pp.distance_squared_to(a.position) < pp.distance_squared_to(b.position))
	_tab_btns["contacts"].text = "Contacts (%d)" % ships.size()
	var sig := "J" if view.player_jammed() else ""
	for n2 in ships:
		sig += str(n2.fit.uid) + ","
	if sig != _contact_sig:
		_contact_sig = sig
		UI.clear(contacts_box)
		_contact_rows.clear()
		if view.player_jammed():
			contacts_box.add_child(UI.label("RADAR JAMMED – only ships within %s show up." % SystemView.fmt_dist(view.JAM_VISIBLE), 12, Color(1.0, 0.45, 0.4)))
		if ships.is_empty():
			contacts_box.add_child(UI.label("No other ships in this system.", 12, UI.TEXT_DIM))
		for n3 in ships:
			var b := Button.new()
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.focus_mode = Control.FOCUS_NONE
			b.clip_text = true
			b.add_theme_font_size_override("font_size", 12)
			b.custom_minimum_size = Vector2(290, 0)
			var uid: int = n3.fit.uid
			b.pressed.connect(func(): view.select("ship:%d" % uid))
			contacts_box.add_child(b)
			_contact_rows[uid] = b
	for n4 in ships:
		var b2: Button = _contact_rows.get(n4.fit.uid)
		if b2 == null:
			continue
		var role: String = {"pirate": "Pirate", "patrol": "Patrol", "civilian": "Civilian", "neutral": "Neutral"}.get(n4.faction, n4.faction)
		var col := Color(1.0, 0.45, 0.4) if n4.faction == "pirate" else (FactionData.color_of(n4.fit.gov) if n4.fit.gov != "" else Color(0.8, 0.84, 0.9))
		if n4.faction == "civilian":
			col = col.lerp(Color(0.85, 0.88, 0.92), 0.55)
		var warp_mark := "⇢ " if n4.in_warp() else "▲ "
		b2.text = "%s%s  ·  %s  ·  %s" % [warp_mark, n4.display_name(), role, SystemView.fmt_dist(pp.distance_to(n4.position))]
		b2.add_theme_color_override("font_color", col)
		b2.tooltip_text = n4.info_text() + ("\nIn warp – a Warp Interdictor can pull it out." if n4.in_warp() else "")


func _overview_click(t: Dictionary) -> void:
	if view != null:
		view.select(String(t["id"]))


func _update_overview() -> void:
	if view == null:
		return
	var pp := view._player_pos()
	_overview_rows.sort_custom(func(a, b): return pp.distance_squared_to(a["target"]["pos"]) < pp.distance_squared_to(b["target"]["pos"]))
	for i in _overview_rows.size():
		var r: Dictionary = _overview_rows[i]
		var t: Dictionary = r["target"]
		var b: Button = r["button"]
		overview_box.move_child(b, i)
		var d := pp.distance_to(t["pos"])
		b.text = "%s %s   ·  %s" % [KIND_ICONS.get(t["kind"], "•"), t["name"], SystemView.fmt_dist(d)]
		b.tooltip_text = "Warp" if d > Universe.WARP_MIN else "Approach"


func _process(delta: float) -> void:
	if hover_panel.visible:
		var mp := get_viewport().get_mouse_position()
		hover_panel.position = mp + Vector2(18, 18)
		var vs := get_viewport().get_visible_rect().size
		if hover_panel.position.x + hover_panel.size.x > vs.x:
			hover_panel.position.x = mp.x - hover_panel.size.x - 10
		if hover_panel.position.y + hover_panel.size.y > vs.y:
			hover_panel.position.y = mp.y - hover_panel.size.y - 10
	var f := GameState.active()
	_update_zone_label()
	_update_ticker(delta)
	if codex_label != null and codex_label.text != "" and GameState.play_time >= _codex_until:
		codex_label.text = ""
	_ov_timer -= delta
	if _ov_timer <= 0.0:
		_ov_timer = 0.5
		_update_overview()
		_update_contacts()
		if _w.has("skills"):
			# package 30: skill tree tiles ready to open, perk points to spend
			var nt := GameState.tiles_ready().size()
			var pp := int(GameState.pilot.get("perk_points", 0))
			var parts: Array = []
			if nt > 0:
				parts.append("%d tile%s to open" % [nt, "" if nt == 1 else "s"])
			if pp > 0:
				parts.append("%d perk point%s" % [pp, "" if pp == 1 else "s"])
			_w["skills"].visible = not parts.is_empty()
			if nav_btns.has("pilot_window"):
				var pb: Button = nav_btns["pilot_window"]
				var glow := not parts.is_empty()
				pb.add_theme_color_override("font_color", UI.GOOD if glow else Color(0.9, 0.93, 1.0))
				pb.add_theme_color_override("icon_normal_color", UI.GOOD if glow else Color(1, 1, 1))
			_w["skills"].text = "▲ %s [%s]" % [" • ".join(PackedStringArray(parts)), Keybinds.key_text("pilot_window")]
	if f == null or not _w.has("act"):
		return
	var s := f.stats()
	var act := ""
	if f.in_transit():
		act = "In hyperspace – %d s" % int(ceil(f.transit))
	elif view != null and view.player != null and is_instance_valid(view.player):
		act = view.player.activity
		var tgt = view.player.target
		if tgt != null and is_instance_valid(tgt) and view.player.lock_progress < 1.0:
			act += "  (target lock %d%%)" % int(view.player.lock_progress * 100.0)
		var flags := status_flags(view.player)
		if flags != "":
			act = flags + "   " + act
	_w["act"].text = act
	if _w.has("speed"):
		var cur := 0.0
		var warping := false
		if view != null and view.player != null and is_instance_valid(view.player):
			cur = view.player.velocity.length()
			warping = view.player.in_warp()
		_w["speed"].text = "WARP" if warping else "%.0f km/s" % cur
	_update_modules()
	_update_locks()
	_update_drones()
	_update_allies()
	_update_selected()
	var ore_txt := ""
	if float(s["ore_cargo_max"]) > 0.0:
		ore_txt = "  + ore %.0f / %.0f" % [f.ore_hold_used(), float(s["ore_cargo_max"])]
	_w["cargo"].text = "Cargo %.0f / %.0f%s   •   %s" % [f.cargo_used(), float(s["cargo_max"]), ore_txt, f.location_text()]
	_set_bar(_w["shield"], f.shield, s["shield_max"])
	_set_bar(_w["armor"], f.armor, s["armor_max"])
	_set_bar(_w["structure"], f.structure, s["structure_max"])
	_set_bar(_w["cap"], f.capacitor, s["cap_max"])
	_set_bar(_w["fuel"], f.fuel, s["fuel_max"])
	_update_power_line(f, s)


## Package 21: "Power 42 / 60 MW (passive 30 + active 12)" and shut-down groups.
func _update_power_line(f: ShipFitting, s: Dictionary) -> void:
	if not _w.has("power"):
		return
	var p = view.player if view != null else null
	var use: Dictionary = p.power_in_use() if (p != null and is_instance_valid(p) and p.fit == f) else {}
	var plan := f.power_plan(use)
	var act := float(plan["total"]) - float(s["power_passive"])
	var t := "Power %.0f / %.0f MW  (passive %.0f + active %.0f)" % [float(plan["total"]), float(plan["available"]), float(s["power_passive"]), maxf(act, 0.0)]
	var col := Color(0.8, 0.85, 0.95)
	if not f.power_off.is_empty():
		var gs: Array = f.power_off.keys()
		gs.sort()
		t += "  –  OVERLOAD: group %s off" % ", ".join(PackedStringArray(gs.map(func(x): return str(x))))
		col = Color(1.0, 0.45, 0.4)
	_w["power"].text = t
	_w["power"].add_theme_color_override("font_color", col)


func show_survey(r: Dictionary) -> void:
	var t := "[b]%s[/b]  [color=#8090a0](radius %s)[/color]\n" % [r["name"], SystemView.fmt_dist(float(r["radius"]))]
	t += "[color=#ffd070]Asteroids: %d[/color]\n" % int(r["asteroids"])
	if r["ores"].is_empty():
		t += "  –\n"
	for row in r["ores"]:
		var cls: String = GameData.commodities.get(row[0], {}).get("class", "")
		var col: Color = SystemView.FIELD_COLORS.get(cls, Color.WHITE)
		t += "  [color=#%s]■[/color] %s – %d units%s\n" % [col.to_html(false), GameData.item_name(row[0]), int(row[2]), (" (main ore of %d)" % int(row[1])) if int(row[1]) > 0 else ""]
	t += "[color=#ffd070]Ships:[/color]\n"
	if r["ships"].is_empty():
		t += "  none\n"
	for k in r["ships"]:
		var hostile := String(k).ends_with("Pirate")
		t += "  [color=#%s]%d× %s[/color]\n" % ["ff7060" if hostile else "c0d0e0", int(r["ships"][k]), k]
	t += "[color=#ffd070]Wrecks:[/color] %d   [color=#ffd070]Colossi:[/color] %d\n" % [int(r["wrecks"]), int(r["colossi"])]
	t += "[color=#8090a0][font_size=11]Snapshot – it goes out of date after %d minutes. Also shown in the selection panel of the place.[/font_size][/color]" % int(Ship.SURVEY_STALE / 60.0)
	survey_text.text = t
	survey_panel.visible = true


func _on_codex_unlocked(id: String) -> void:
	var title := String(GameState.codex.all[id]["title"])
	if GameState.play_time < _codex_until and codex_label.text != "":
		codex_label.text = "📖 New Codex entries – open Ship [%s] → Codex" % Keybinds.key_text("ship_menu")
	else:
		codex_label.text = "📖 New Codex entry: %s  –  Ship [%s] → Codex" % [title, Keybinds.key_text("ship_menu")]
	_codex_until = GameState.play_time + 6.0
	GameState.log_msg("New Codex entry: %s" % title, UI.GOLD)


## Scrolls the news ticker: every new item runs through once, then the ticker hides until the next one.
func _update_ticker(delta: float) -> void:
	if ticker_label == null:
		return
	ticker_label.position.x -= TICKER_SPEED * delta
	if ticker_label.text != "" and ticker_label.position.x > -ticker_label.size.x:
		return
	var it: Dictionary = {}
	while not _ticker_queue.is_empty() and it.is_empty():
		var q: Dictionary = _ticker_queue.pop_front()
		if String(q["kind"]) != "radio" or int(q["system"]) == GameState.current_system:
			it = q
	if it.is_empty():
		ticker_label.text = ""   # nothing new: the ticker stays empty (each item runs only once)
		_ticker_clip.visible = false
		return
	_ticker_clip.visible = true
	var k: Array = TICKER_KIND.get(String(it["kind"]), TICKER_KIND["world"])
	ticker_label.text = "%s %s" % [k[0], it["text"]]
	ticker_label.add_theme_color_override("font_color", k[1])
	ticker_label.reset_size()
	ticker_label.position.x = maxf(_ticker_clip.size.x, _ticker_clip.custom_minimum_size.x)


## Banner while inside a station's no-fire zone, while flagged as aggressor, or in haven gun range.
func _update_zone_label() -> void:
	var text := ""
	var col := UI.GOLD
	var p = view.player if view != null else null
	if p != null and is_instance_valid(p) and not p.is_docked():
		if view.is_aggressor(p):
			text = "⚠ AGGRESSOR – station defence batteries are firing at you (%d s)" % int(ceil(view.aggro_left(p)))
			col = Color(1.0, 0.35, 0.3)
		else:
			for hv in view.havens:
				if is_instance_valid(hv) and hv.position.distance_to(p.position) < SystemView.HAVEN_RANGE * 1.5:
					text = "⚠ %s – pirate guns in range" % hv.title()
					col = Color(1.0, 0.35, 0.3)
			if text == "":
				var st = view.zone_station(p.position)
				if st != null:
					text = "NO-FIRE ZONE · %s – opening fire makes the station defend itself" % st.title()
	if _warn_text != "" and GameState.play_time < _warn_until:
		text = "⚠ " + _warn_text if text == "" else "⚠ " + _warn_text + "\n" + text
		col = Color(1.0, 0.35, 0.3)
	# a live station raid in this system (package 15) – always shown, the hull bar may be off-screen
	if view != null and not view.raid_live.is_empty() and is_instance_valid(view.raid_live["st"]):
		var rl: Dictionary = view.raid_live
		var cap: Dictionary = GameState.notorious.get_captain(String(rl["cap"]))
		var left := 0.0
		if not cap.is_empty() and not (cap["raid"] as Dictionary).is_empty():
			left = maxf(0.0, float(cap["raid"]["until"]) - GameState.play_time)
		var on := 0
		for i in rl["turrets"].size():
			on += 1 if view.turret_ok(rl["st"], i) else 0
		var raid_txt := "☠ RAID ON %s · hull %d%% · turrets %d / %d · %d:%02d left" % [rl["st"].title().to_upper(), int(100.0 * float(rl["hp"]) / maxf(float(rl["hp_max"]), 1.0)), on, rl["turrets"].size(), int(left) / 60, int(left) % 60]
		text = raid_txt if text == "" else raid_txt + "
" + text
		col = Color(1.0, 0.35, 0.3)
	zone_label.text = text
	zone_label.add_theme_color_override("font_color", col)


func _set_bar(b: ProgressBar, v: float, vmax: float) -> void:
	b.max_value = maxf(vmax, 0.001)
	b.value = v
	b.tooltip_text = "%.0f / %.0f" % [v, vmax]


# ================================================================ Selected item (top right)

func show_selected(id: String) -> void:
	selected_id = id
	_build_selected()


# ================================================================ Command hotkeys

const HOTKEY_COMMANDS := ["sel_target", "sel_hostile", "sel_friend", "sel_station", "cmd_lock", "cmd_approach", "cmd_warp", "cmd_jump", "cmd_dock", "cmd_follow"]


## Runs a ship command on the selected object (Settings → Controls, "Ship commands").
## Returns the error text ("" = done).
func hotkey_command(action: String) -> String:
	var p = view.player if view != null else null
	if p == null or not is_instance_valid(p):
		return "No ship."
	if action == "sel_target":
		return select_next("all")
	if action == "sel_hostile":
		return select_next("hostile")
	if action == "sel_friend":
		return select_next("friend")
	if action == "sel_station":
		return select_near_station()
	var id := selected_id
	if action == "cmd_lock" and id == "":
		var near = _nearest_hostile(p)
		if near == null:
			GameState.log_msg("Nothing selected and no hostile ship in sensor range.", GameState.COL_WARN)
			return "nothing"
		id = "ship:%d" % near.fit.uid
		view.select(id)
	if id == "":
		var e0 := "Select something first (%s)." % Keybinds.key_text(action)
		GameState.log_msg(e0, GameState.COL_WARN)
		return e0
	var d: Dictionary = view.describe(id)
	if d.is_empty():
		return "Unknown object."
	var kind: String = d["kind"]
	var err := ""
	match action:
		"cmd_lock":
			if not (d.has("node") and kind in ["ship", "asteroid", "wreck", "anomaly"]):
				err = "Only ships, asteroids, wrecks and anomalies can be locked."
				GameState.log_msg(err, GameState.COL_WARN)
			elif p.lock_index(id) >= 0:
				err = Commands.execute({"type": "unlock", "id": id})
			else:
				err = Commands.execute({"type": "lock", "id": id})
		"cmd_approach":
			err = Commands.execute({"type": "approach", "id": id})
		"cmd_warp":
			err = Commands.execute({"type": "warp_to", "id": id})
		"cmd_jump":
			if kind != "gate":
				err = "Select a jump gate to jump."
				GameState.log_msg(err, GameState.COL_WARN)
			else:
				err = Commands.execute({"type": "jump", "id": id})
		"cmd_dock":
			if not kind in ["station", "haven"]:
				err = "Select a station to dock."
				GameState.log_msg(err, GameState.COL_WARN)
			else:
				err = Commands.execute({"type": "dock", "id": id})
		"cmd_follow":
			err = Commands.execute({"type": "follow", "id": id})
	if selected_id != "":
		_build_selected()
	return err


const HOSTILE_SELECT_RANGE := 50000.0
const STATION_SELECT_RANGE := 5000.0


## Targeting keys (package 22): cycles through what is within sensor range, nearest first –
## "all" (anything lockable: ships, asteroids, wrecks, anomalies), "hostile" or "friend" (ships that
## are not hostile). Hostile / friendly ships further out (up to 50,000 km) when none is in range.
func select_next(kind: String) -> String:
	var p = view.player
	var sr: float = p.lock_range(p.fit.stats())
	var list := _target_candidates(p, kind, sr)
	if list.is_empty() and kind != "all":
		list = _target_candidates(p, kind, HOSTILE_SELECT_RANGE)
	if list.is_empty():
		var what: String = {"all": "Nothing to target", "hostile": "No hostile ship", "friend": "No friendly ship"}[kind]
		var e := "%s within %s." % [what, SystemView.fmt_dist(sr if kind == "all" else HOSTILE_SELECT_RANGE)]
		GameState.log_msg(e, GameState.COL_WARN)
		return e
	# ships first (nearest first), then asteroids, wrecks and anomalies; with nothing selected it
	# starts again with the nearest ship
	list.sort_custom(func(a, b):
		if (a is Ship) != (b is Ship):
			return a is Ship
		return p.position.distance_squared_to(a.position) < p.position.distance_squared_to(b.position))
	var cur = view.find_object(selected_id) if selected_id != "" else null
	var i := list.find(cur)
	var nxt = list[(i + 1) % list.size()]
	view.select(Ship.object_key(nxt))
	return ""


func _target_candidates(p, kind: String, rng: float) -> Array:
	var out: Array = []
	for n in view.ship_layer.get_children():
		if not (n is Ship) or n == p or n.dying or n.is_drone or n.in_warp() or n.is_docked() or p.position.distance_to(n.position) > rng or not view.contact_visible(n):
			continue
		var hos: bool = n.hostile_to_player()
		if kind == "all" or (kind == "hostile" and hos) or (kind == "friend" and not hos):
			out.append(n)
	if kind == "all":
		for c in view.celestials:
			if is_instance_valid(c) and Ship.lockable(c) and p.position.distance_to(c.position) <= rng:
				out.append(c)
	return out


## Former Tab behaviour (kept for callers): the next hostile ship.
func select_next_hostile() -> String:
	return select_next("hostile")


## Selects the nearest station (or pirate haven) – only when it is within a few thousand km.
func select_near_station() -> String:
	var p = view.player
	var best = null
	var bd := INF
	var all: Array = view.stations.values() + view.havens
	for c in all:
		if c == null or not is_instance_valid(c):
			continue
		var d := maxf(p.position.distance_to(c.position) - float(c.radius), 0.0)
		if d < bd:
			bd = d
			best = c
	if best == null or bd > STATION_SELECT_RANGE:
		var e := "No station within %s." % SystemView.fmt_dist(STATION_SELECT_RANGE)
		GameState.log_msg(e, GameState.COL_WARN)
		return e
	view.select(String(best.data["id"]))
	return ""


func _nearest_hostile(p):
	var sr := float(p.fit.stats()["sensor_range"])
	var best = null
	var bd := sr
	for n in view.ship_layer.get_children():
		if n is Ship and n != p and not n.dying and not n.in_warp() and n.hostile_to_player():
			var dd: float = p.position.distance_to(n.position)
			if dd <= bd:
				bd = dd
				best = n
	return best


func _hk(action: String) -> String:
	var k := Keybinds.key_text(action)
	return "" if k == "" else "Key: %s" % k


func _cmd(c: Dictionary) -> void:
	Commands.execute(c)
	_build_selected()


func _build_selected() -> void:
	UI.clear(sel_box)
	_sel_info = null
	var d: Dictionary = view.describe(selected_id) if (view != null and selected_id != "") else {}
	if d.is_empty():
		sel_box.add_child(UI.label("Selected item", 13, UI.ACCENT))
		sel_box.add_child(UI.wrap_label("Click a ship, asteroid, wreck, station or an overview entry to see what you can do with it.", 12, UI.TEXT_DIM, 290))
		return
	var head := UI.hbox(6)
	sel_box.add_child(head)
	var title := UI.label(d["name"], 14, Color(1.0, 0.45, 0.4) if (d.get("node") is Ship and d["node"].hostile_to_player()) else UI.ACCENT)
	title.clip_text = true
	title.custom_minimum_size = Vector2(240, 0)
	head.add_child(title)
	head.add_child(UI.spacer())
	head.add_child(UI.button("×", func(): show_selected("")))
	_sel_info = UI.wrap_label("", 12, UI.TEXT_DIM, 296)
	sel_box.add_child(_sel_info)
	var id: String = d["id"]
	var kind: String = d["kind"]
	var has_node := d.has("node")
	var far := view._player_pos().distance_to(d["pos"]) > Universe.WARP_MIN
	var r1 := UI.hbox(4)
	sel_box.add_child(r1)
	if far or kind in ["planet", "star", "field"]:
		r1.add_child(UI.button("Warp to", func(): _cmd({"type": "warp_to", "id": id}), _hk("cmd_warp")))
	r1.add_child(UI.button("Approach", func(): _cmd({"type": "approach", "id": id}), _hk("cmd_approach")))
	if kind in ["station", "haven"]:
		r1.add_child(UI.button("Dock", func(): _cmd({"type": "dock", "id": id}), _hk("cmd_dock")))
	if kind == "gate":
		var jerr := ""
		if view.player != null and is_instance_valid(view.player) and d.has("node"):
			jerr = GameState.can_jump(view.player.fit, int(d["node"].data["to"]))
		var jb := UI.button("Jump", func(): _cmd({"type": "jump", "id": id}), jerr if jerr != "" else _hk("cmd_jump"))
		r1.add_child(jb)
		if jerr != "":
			jb.disabled = true
			var jl := UI.wrap_label("Cannot jump: %s" % jerr, 12, UI.BAD, 296)
			sel_box.add_child(jl)
	var warping: bool = has_node and kind == "ship" and d["node"].in_warp()
	if warping:
		var ri := UI.hbox(4)
		sel_box.add_child(ri)
		var have := false
		if view.player != null and is_instance_valid(view.player):
			for e in view.player.fit.active_modules():
				if e["kind"] == "tool" and e["data"]["tool"] == "interdict":
					var sl: String = e["slot"]
					ri.add_child(UI.button("Interdict (pull out of warp)", func(): _cmd({"type": "activate", "slot": sl})))
					have = true
					break
		if not have:
			ri.add_child(UI.label("In warp – a Warp Interdictor could stop it.", 12, UI.TEXT_DIM))
	if has_node and kind == "ship" and d["node"].escort_mark:
		var fol: bool = view.player != null and is_instance_valid(view.player) and String(view.player.order.get("type", "")) == "follow" and view.player.order.get("node") == d["node"]
		var fb := UI.button("Following" if fol else "Follow", func(): _cmd({"type": "follow", "id": id}), "Stay with this ship – also in warp and through gates\n" + _hk("cmd_follow"))
		fb.disabled = fol
		r1.add_child(fb)
	if has_node and kind in ["ship", "asteroid", "wreck", "anomaly"]:
		var locked: bool = view.player != null and is_instance_valid(view.player) and view.player.lock_index(id) >= 0
		if locked:
			r1.add_child(UI.button("Unlock", func(): _cmd({"type": "unlock", "id": id}), _hk("cmd_lock")))
		else:
			r1.add_child(UI.button("Lock target", func(): _cmd({"type": "lock", "id": id}), _hk("cmd_lock")))
	if has_node and not warping:
		var r2 := UI.hbox(4)
		sel_box.add_child(r2)
		r2.add_child(UI.label("Orbit", 12, UI.TEXT_DIM))
		for km in [250, 500, 1000]:
			var k: int = km
			r2.add_child(UI.button("%d km" % k, func(): _cmd({"type": "orbit", "id": id, "range": k})))
		var r3 := UI.hbox(4)
		sel_box.add_child(r3)
		r3.add_child(UI.label("Keep at", 12, UI.TEXT_DIM))
		for km in [500, 1000, 2500]:
			var k2: int = km
			r3.add_child(UI.button("%s km" % GameData.fmt_credits(k2).trim_suffix(" cr"), func(): _cmd({"type": "keep_range", "id": id, "range": k2})))
	_update_selected()


func _update_selected() -> void:
	if _sel_info == null or view == null:
		return
	var d := view.describe(selected_id)
	if d.is_empty():
		show_selected("")
		return
	var t := "%s  •  %s" % [KIND_NAMES.get(d["kind"], d["kind"]), SystemView.fmt_dist(view._player_pos().distance_to(d["pos"]))]
	var n = d.get("node")
	if n is Ship:
		t += "\nShield %.0f  •  Armor %.0f  •  Structure %.0f" % [n.fit.shield, n.fit.armor, n.fit.structure]
		if status_flags(n) != "":
			t += "\n" + status_flags(n)
		if n.cargo_known:
			t += "\n" + n.manifest_text()
		if n.in_warp():
			t += "\nIn warp → %s%s" % [n.warp.get("name", "?"), "  (frozen by an interdictor)" if n.warp_frozen else ""]
		if n.faction != "player":
			t += "\n" + (n.warrant_text() if n.warrant_known else "Bounty: unknown – lock it and use a Warrant Scanner")
	elif n != null and d["kind"] == "asteroid":
		t += "\n%s %s asteroid" % [String(n.data.get("size", "")).capitalize(), String(n.data.get("class", "")).capitalize()]
		if String(n.data.get("field", "")) == "":
			t += "  •  loose rock" + (" near %s" % n.data["near"] if n.data.has("near") else "")
		if n.is_prospected():
			t += "\n%s" % n.composition_text()
		else:
			t += "\nComposition unknown – lock it and use a Prospector Scanner"
	elif n != null and d["kind"] == "colossus":
		t += "\n%s colossus, %s  •  %s long" % [String(n.data["class"]).capitalize(), ColossusShape.SHAPE_NAMES.get(String(n.data.get("shape", "")), "irregular"), SystemView.fmt_dist(ColossusShape.length_km(n.poly))]
		t += "\nObstacle and cover: casts a radar shadow – ships behind it cannot be seen, locked or shot. Mineable rock on its rim."
	elif d["kind"] == "field":
		var fd: Dictionary = Universe.warp_target(view.system_id, selected_id).get("data", {})
		var names: PackedStringArray = []
		for o in fd.get("ores", []):
			names.append(GameData.item_name(o))
		t += "\n%s" % ", ".join(names)
	elif n != null and d["kind"] == "anomaly":
		t += "\nAnalysis %.0f%%" % float(n.data.get("analysis", 0.0))
	var sv: Dictionary = GameState.surveys.get("%d:%s" % [view.system_id, selected_id], {})
	if not sv.is_empty():
		var age := GameState.play_time - float(sv["t"])
		t += "\nSurvey %s%s: %s" % [SystemView.fmt_age(age), " (outdated)" if age > Ship.SURVEY_STALE else "", sv["summary"]]
	_sel_info.text = t


# ================================================================ Locked targets (top centre)

func _update_locks() -> void:
	var p = view.player if view != null else null
	var locks: Array = p.locks if (p != null and is_instance_valid(p)) else []
	var sig := ""
	for l in locks:
		sig += String(l["key"]) + ";"
	if sig != _lock_sig:
		_lock_sig = sig
		UI.clear(lock_bar)
		_lock_cards.clear()
		for l in locks:
			_make_lock_card(l)
	for l in locks:
		var c: Dictionary = _lock_cards.get(l["key"], {})
		if c.is_empty():
			continue
		var n = l["node"]
		if n == null or not is_instance_valid(n):
			continue
		var act: bool = l["key"] == p.active_lock
		var sb: StyleBoxFlat = c["style"]
		var hostile: bool = n is Ship and n.hostile_to_player()
		var col := Color(1.0, 0.35, 0.3) if hostile else Color(1.0, 0.8, 0.3)
		sb.border_color = col if act else Color(col, 0.35)
		sb.set_border_width_all(2 if act else 1)
		var prog := float(l["progress"])
		var info := "T%d  •  %s" % [p.lock_number(l["key"]), SystemView.fmt_dist(p.position.distance_to(n.position))]
		var mods := p.modules_on(l["key"])
		if mods > 0:
			info += "  •  %d module%s" % [mods, "" if mods == 1 else "s"]
		if n is Ship and status_flags(n) != "":
			info += "  •  " + status_flags(n)
		if prog < 1.0:
			info = "Locking %d%%  •  %s" % [int(prog * 100.0), info]
		c["info"].text = info
		var bars: Array = c["bars"]
		if n is Ship:
			var ns: Dictionary = n.fit.stats()
			_set_bar(bars[0], n.fit.shield, ns["shield_max"])
			_set_bar(bars[1], n.fit.armor, ns["armor_max"])
			_set_bar(bars[2], n.fit.structure, ns["structure_max"])
		else:
			_set_bar(bars[0], prog, 1.0)


func _make_lock_card(l: Dictionary) -> void:
	var n = l["node"]
	var key: String = l["key"]
	var panel := PanelContainer.new()
	var sb := UI.panel_style(Color(0.03, 0.04, 0.08, 0.88), Color(1, 1, 1, 0.3))
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size = Vector2(150, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.tooltip_text = "Click: make active target – modules switched on now work on it; press a running module's key to move it here"
	panel.gui_input.connect(func(ev): _lock_card_input(ev, key))
	lock_bar.add_child(panel)
	var v := UI.vbox(2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(v)
	var head := UI.hbox(4)
	v.add_child(head)
	var nm := UI.label(n.display_name() if n is Ship else n.title(), 12)
	nm.clip_text = true
	nm.custom_minimum_size = Vector2(110, 0)
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(nm)
	head.add_child(UI.spacer())
	var x := UI.button("×", func(): Commands.execute({"type": "unlock", "id": key}))
	x.custom_minimum_size = Vector2(20, 18)
	head.add_child(x)
	var info := UI.label("", 11, UI.TEXT_DIM)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(info)
	var bars: Array = []
	var cols: Array = [Color(0.35, 0.65, 1.0), Color(1.0, 0.8, 0.3), Color(0.9, 0.3, 0.3)] if n is Ship else [Color(1.0, 0.8, 0.3)]
	for c in cols:
		var b := UI.bar(c, 130)
		b.custom_minimum_size = Vector2(130, 4)
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(b)
		bars.append(b)
	_lock_cards[key] = {"panel": panel, "style": sb, "info": info, "bars": bars}


func _lock_card_input(ev: InputEvent, key: String) -> void:
	if ev is InputEventMouseButton and ev.pressed:
		if (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_RIGHT:
			Commands.execute({"type": "unlock", "id": key})
		else:
			Commands.execute({"type": "target", "id": key})
			if view != null:
				view.select(key)


## Package 20: shield downtime, EMP and jamming as a short text ("" = none).
static func status_flags(n) -> String:
	var parts: Array = []
	if n.shield_down > 0.0:
		parts.append("SHIELD DOWN %ds" % int(ceil(n.shield_down)))
	if n.emp_t > 0.0:
		parts.append("EMP %ds" % int(ceil(n.emp_t)))
	if n.jammed_t > 0.0:
		parts.append("JAMMED")
	return "  ".join(PackedStringArray(parts))


# ================================================================ Drone control (top left edge)

const DRONE_ROLE_UI := [["combat", "Combat", "w_kinetic"], ["mining", "Mining", "t_mining"], ["repair", "Repair", "t_repair"]]
const DRONE_MODE_NAMES := {"defend": "Defend", "attack": "Attack target", "fire_at_will": "Fire at will", "rest": "Rest",
	"auto": "Auto", "target": "Work on target", "allies": "Allies only", "self": "Self only"}
const DRONE_MODE_TIPS := {
	"defend": "Attack ships that attacked you or that you attacked – they pick the target themselves",
	"attack": "Attack your active locked target (idle in formation without one)",
	"fire_at_will": "Attack every ship nearby – hostiles AND civilians (allies spared). Attacking the innocent is a crime!",
	"rest": "Stay in formation, even during a fight",
	"auto": "Mining: find asteroids, mine and deliver the ore (5 m³ per trip). Repair: you, allies and neutral ships in range",
	"target": "Work only on your active locked target",
	"allies": "Repair only allied ships (and you)",
	"self": "Repair only your own ship when it needs it",
}


func _update_drones() -> void:
	var p = view.player if view != null else null
	if p == null or not is_instance_valid(p) or GameState.active() == null:
		drone_panel.visible = false
		return
	var f: ShipFitting = p.fit
	var st := f.stats()
	drone_panel.visible = int(st["drone_storage"]) > 0
	var out: Array = view.drones_of(p)
	var mode := String(f.drone_modes.get(f.drone_role, ""))
	var sig := "%d|%d|%s|%s|%d" % [out.size(), f.drones.size(), f.drone_role, mode, int(st["drones_max"])]
	for d0 in out:
		sig += ",%d" % d0.get_instance_id()
	if sig != _drone_sig:
		_drone_sig = sig
		_build_drone_panel(p, out)
	for r in _drone_rows:
		var d = r["drone"]
		if is_instance_valid(d) and not d.dying:
			_set_bar(r["fuel"], d.fuel_left(), 1.0)
			_set_bar(r["hull"], d.fit.structure, d.hull_max())
	ally_bar.position.y = (drone_panel.position.y + drone_panel.size.y + 8.0) if drone_panel.visible else 54.0
	# the survey results move next to the drone window instead of covering it
	survey_panel.position.x = (drone_panel.size.x + 10.0) if drone_panel.visible else 14.0


func _build_drone_panel(p, out: Array) -> void:
	UI.clear(_drone_box)
	_drone_rows.clear()
	var f: ShipFitting = p.fit
	var st := f.stats()
	var head := UI.hbox(6)
	_drone_box.add_child(head)
	head.add_child(UI.label("DRONES", 13, Color(0.45, 1.0, 0.55)))
	head.add_child(UI.label("%d / %d out  •  %d in hangar" % [out.size(), int(st["drones_max"]), f.drones_in_hangar()], 11, UI.TEXT_DIM))
	if out.is_empty():
		# folded: one line and the launch button
		var lb := UI.button("Launch [%s]" % Keybinds.key_text("drone_launch"), func(): Commands.execute({"type": "drone_launch", "count": 1}))
		lb.disabled = f.drones_in_hangar() == 0
		lb.tooltip_text = "Launch drones – the window opens with their controls" if f.drones_in_hangar() > 0 else "No drones in the hangar – the Drone Bay at stations sells them"
		_drone_box.add_child(lb)
		return
	var roles := UI.hbox(3)
	_drone_box.add_child(roles)
	for spec in DRONE_ROLE_UI:
		var rid: String = spec[0]
		var b := Button.new()
		b.toggle_mode = true
		b.button_pressed = f.drone_role == rid
		b.focus_mode = Control.FOCUS_NONE
		b.text = spec[1]
		b.icon = PixelArt.icon_texture(spec[2])
		b.expand_icon = false
		b.add_theme_font_size_override("font_size", 11)
		b.custom_minimum_size = Vector2(78, 30)
		b.pressed.connect(func(): Commands.execute({"type": "drone_role", "role": rid}))
		roles.add_child(b)
	var modes: Array = Commands.DRONE_ROLES[f.drone_role]
	var cur := String(f.drone_modes.get(f.drone_role, ""))
	var mg := GridContainer.new()
	mg.columns = 2
	_drone_box.add_child(mg)
	for m in modes:
		var mid: String = m
		var mb := UI.button(DRONE_MODE_NAMES.get(mid, mid), func(): Commands.execute({"type": "drone_mode", "mode": mid}), DRONE_MODE_TIPS.get(mid, ""))
		mb.toggle_mode = true
		mb.button_pressed = cur == mid
		mb.custom_minimum_size = Vector2(118, 24)
		mb.add_theme_font_size_override("font_size", 11)
		mg.add_child(mb)
	if f.drone_role == "combat" and st["drone_weapon"].is_empty():
		_drone_box.add_child(UI.wrap_label("No drone weapon fitted (hangar → weapon slot).", 11, UI.BAD, 240))
	if f.drone_role == "mining" and st["drone_tool"].is_empty():
		_drone_box.add_child(UI.wrap_label("No drone mining laser fitted (hangar → tool slot).", 11, UI.BAD, 240))
	for d in out:
		var row := UI.hbox(4)
		_drone_box.add_child(row)
		var nm := UI.label(String(d.display_name()), 11, Color(0.75, 1.0, 0.8))
		nm.custom_minimum_size = Vector2(60, 0)
		row.add_child(nm)
		var fb := UI.bar(Color(0.4, 0.9, 0.5), 80)
		fb.custom_minimum_size = Vector2(80, 5)
		fb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fb.tooltip_text = "Fuel"
		row.add_child(fb)
		var hb := UI.bar(Color(0.9, 0.3, 0.3), 80)
		hb.custom_minimum_size = Vector2(80, 5)
		hb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(hb)
		_drone_rows.append({"drone": d, "fuel": fb, "hull": hb})
	var bt := UI.hbox(4)
	_drone_box.add_child(bt)
	var l2 := UI.button("Launch [%s]" % Keybinds.key_text("drone_launch"), func(): Commands.execute({"type": "drone_launch", "count": 1}))
	l2.disabled = f.drones_in_hangar() == 0 or out.size() >= int(st["drones_max"])
	bt.add_child(l2)
	bt.add_child(UI.button("Recall [%s]" % Keybinds.key_text("drone_recall"), func(): Commands.execute({"type": "drone_recall"})))


# ================================================================ Allied group (top left)

const MAX_ALLY_TILES := 8


func _update_allies() -> void:
	var ships: Array = view.player_group() if view != null else []
	if ships.size() > MAX_ALLY_TILES:
		ships = ships.slice(0, MAX_ALLY_TILES)
	ally_bar.visible = not ships.is_empty() and not survey_panel.visible
	var sig := ""
	for n in ships:
		sig += "%d%s;" % [n.get_instance_id(), "L" if n.convoy_lead else ""]
	if sig != _ally_sig:
		_ally_sig = sig
		UI.clear(ally_bar)
		_ally_cards.clear()
		if not ships.is_empty():
			ally_bar.add_child(UI.label("YOUR GROUP", 11, Color(0.45, 1.0, 0.55)))
		for n in ships:
			_make_ally_card(n)
	var p = view.player if view != null else null
	for n in ships:
		var c: Dictionary = _ally_cards.get(n, {})
		if c.is_empty() or not is_instance_valid(n):
			continue
		var info := ""
		if n.is_docked():
			info = "Docked"
		elif n.in_warp():
			info = "In warp"
		elif p != null and is_instance_valid(p):
			info = SystemView.fmt_dist(p.position.distance_to(n.position))
		if n.convoy_lead:
			info = "LEAD  •  " + info
		if status_flags(n) != "":
			info += "  •  " + status_flags(n)
		c["info"].text = info
		var sel: bool = selected_id == "ship:%d" % n.fit.uid
		var sb: StyleBoxFlat = c["style"]
		sb.border_color = Color(0.45, 1.0, 0.55) if sel else Color(0.45, 1.0, 0.55, 0.35)
		sb.set_border_width_all(2 if sel else 1)
		var ns: Dictionary = n.fit.stats()
		_set_bar(c["bars"][0], n.fit.shield, ns["shield_max"])
		_set_bar(c["bars"][1], n.fit.armor, ns["armor_max"])
		_set_bar(c["bars"][2], n.fit.structure, ns["structure_max"])


func _make_ally_card(n: Ship) -> void:
	var panel := PanelContainer.new()
	var sb := UI.panel_style(Color(0.03, 0.06, 0.05, 0.88), Color(0.45, 1.0, 0.55, 0.35))
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size = Vector2(150, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.tooltip_text = "Click: select  •  Right-click: follow"
	var id := "ship:%d" % n.fit.uid
	panel.gui_input.connect(func(ev): _ally_card_input(ev, id))
	ally_bar.add_child(panel)
	var v := UI.vbox(2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(v)
	var nm := UI.label(n.display_name(), 12, Color(0.75, 1.0, 0.8))
	nm.clip_text = true
	nm.custom_minimum_size = Vector2(130, 0)
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(nm)
	var info := UI.label("", 11, UI.TEXT_DIM)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(info)
	var bars: Array = []
	for col in [Color(0.35, 0.65, 1.0), Color(1.0, 0.8, 0.3), Color(0.9, 0.3, 0.3)]:
		var b := UI.bar(col, 130)
		b.custom_minimum_size = Vector2(130, 3)
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(b)
		bars.append(b)
	_ally_cards[n] = {"style": sb, "info": info, "bars": bars}


func _ally_card_input(ev: InputEvent, id: String) -> void:
	if ev is InputEventMouseButton and ev.pressed:
		if (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_RIGHT:
			Commands.execute({"type": "follow", "id": id})
		else:
			if view != null:
				view.select(id)


# ================================================================ Module bar (bottom centre)

func _update_modules() -> void:
	var p = view.player if view != null else null
	var f := GameState.active()
	var mods: Array = f.active_modules() if (f != null and p != null and is_instance_valid(p)) else []
	var sig := ""
	for e in mods:
		sig += "%s=%s;" % [e["slot"], e["data"]["id"]]
	if sig != _module_sig:
		_module_sig = sig
		UI.clear(module_bar)
		_module_tiles.clear()
		module_slots.clear()
		for e in mods:
			_make_module_tile(e, module_slots.size())
			module_slots.append(e["slot"])
	for e in mods:
		var t: Dictionary = _module_tiles.get(e["slot"], {})
		if t.is_empty():
			continue
		var state: String = p.module_state.get(e["slot"], "off")
		var on: bool = p.module_on.get(e["slot"], false)
		if not on:
			state = "off"
		elif state == "on" and e["kind"] in ["weapon", "tool"] and p.module_target.has(e["slot"]) and String(p.module_target[e["slot"]]) != p.active_lock:
			state = "other"      # multi-focus: running on a target that is not the active one
		var sb: StyleBoxFlat = t["style"]
		sb.border_color = STATE_COLORS[state]
		sb.set_border_width_all(2 if on else 1)
		sb.bg_color = Color(STATE_COLORS[state].darkened(0.8), 0.92) if on else Color(0.03, 0.04, 0.08, 0.9)
		var bar: ProgressBar = t["bar"]
		bar.max_value = 1.0
		bar.value = p.cycle_progress(e["slot"]) if on else 0.0
		# multi-focus (package 22): which lock this module works on
		var tn := p.lock_number(String(p.module_target.get(e["slot"], ""))) if on and e["kind"] in ["weapon", "tool"] else 0
		t["tgt"].text = (" T%d" % tn) if tn > 0 else ""


func _make_module_tile(e: Dictionary, idx: int) -> void:
	var d: Dictionary = e["data"]
	var slot: String = e["slot"]
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(74, 72)
	var sb := UI.panel_style(Color(0.03, 0.04, 0.08, 0.9), STATE_COLORS["off"])
	sb.set_corner_radius_all(2)
	for st in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(st, sb)
	var info := "%s\nRange %s" % [d["name"], SystemView.fmt_dist(float(d.get("range", 0.0)))]
	if e["kind"] == "weapon":
		info += "  •  %.0f dmg / %.2f s  •  %s energy" % [float(d["damage"]), float(d["cooldown"]), str(d["energy"])]
	elif e["kind"] == "pd":
		info += "  •  point defense: switch on – shoots down hostile missiles and mines (%d %%)" % int(minf(float(d["intercept"]), 0.95) * 100.0)
	elif e["kind"] == "mine":
		info = "%s\nClick: lay a mine  •  Right-click: mine type and timer" % d["name"]
	b.tooltip_text = info + ("\nKey: %s" % Keybinds.key_text("module_%d" % (idx + 1)) if idx < 9 else "")
	b.pressed.connect(func(): Commands.execute({"type": "toggle_module", "slot": slot}))
	if e["kind"] == "mine":
		b.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_RIGHT:
				_mine_menu(b, slot))
	module_bar.add_child(b)
	var v := UI.vbox(1)
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 5
	v.offset_right = -5
	v.offset_top = 3
	v.offset_bottom = -4
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	var top := UI.hbox(2)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(top)
	var key := UI.label(Keybinds.key_text("module_%d" % (idx + 1)) if idx < 9 else "", 11, Color(0.8, 0.85, 1.0))
	key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(key)
	var tl := UI.label("", 11, Color(1.0, 0.8, 0.3))
	tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(tl)
	top.add_child(UI.spacer())
	var ic := UI.icon(PixelArt.module_icon(d["id"]), 30)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(ic)
	var nm := UI.label(String(d["name"]), 10, Color(0.85, 0.9, 1.0))
	nm.clip_text = true
	nm.custom_minimum_size = Vector2(62, 0)
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(nm)
	var bar := UI.bar(STATE_COLORS["on"], 62)
	bar.custom_minimum_size = Vector2(62, 4)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(bar)
	if d.get("builtin", false):
		# built into the hull (package 25a): an inner gold frame
		var fr := Panel.new()
		var fs := StyleBoxFlat.new()
		fs.draw_center = false
		fs.border_color = BUILTIN_COLOR
		fs.set_border_width_all(2)
		fr.add_theme_stylebox_override("panel", fs)
		fr.set_anchors_preset(Control.PRESET_FULL_RECT)
		fr.offset_left = 3
		fr.offset_top = 3
		fr.offset_right = -3
		fr.offset_bottom = -3
		fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(fr)
		b.tooltip_text += "\nBuilt into the hull"
	_module_tiles[slot] = {"button": b, "style": sb, "bar": bar, "tgt": tl}


## Mine launcher (package 20): pick the mine type (with the number in the hold) and the timer.
func _mine_menu(anchor: Control, slot: String) -> void:
	var p = view.player if view != null else null
	if p == null or not is_instance_valid(p):
		return
	var f: ShipFitting = p.fit
	var ch: Dictionary = p.mine_choice.get(slot, {})
	var pm := PopupMenu.new()
	var kinds: Array = GameData.MINES.keys()
	for i in kinds.size():
		var k: String = kinds[i]
		pm.add_radio_check_item("%s  (%d)" % [GameData.MINES[k]["name"], int(f.cargo.get(k, 0.0))], i)
		pm.set_item_checked(i, String(ch.get("type", "")) == k)
		pm.set_item_tooltip(i, String(GameData.MINES[k]["text"]))
	pm.add_separator("Timed mine")
	for j in GameData.MINE_TIMERS.size():
		var sec: int = GameData.MINE_TIMERS[j]
		pm.add_radio_check_item("Timer %d s" % sec, 100 + j)
		pm.set_item_checked(pm.get_item_index(100 + j), int(ch.get("fuse", 10)) == sec)
	pm.id_pressed.connect(func(id):
		if id >= 100:
			Commands.execute({"type": "mine_config", "slot": slot, "fuse": GameData.MINE_TIMERS[id - 100]})
		else:
			Commands.execute({"type": "mine_config", "slot": slot, "mine": kinds[id]}))
	pm.popup_hide.connect(pm.queue_free)
	add_child(pm)
	pm.position = Vector2i(anchor.global_position + Vector2(0, -10)) - Vector2i(0, 200)
	pm.popup()


## Hotkeys 1–9
func activate_index(i: int) -> void:
	if i < module_slots.size():
		Commands.execute({"type": "toggle_module", "slot": module_slots[i]})
	else:
		GameState.log_msg("Module key %d (%s): no activatable module in that position (you have %d)." % [i + 1, Keybinds.key_text("module_%d" % (i + 1)), module_slots.size()], GameState.COL_WARN)
