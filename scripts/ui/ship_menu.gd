class_name ShipMenu
extends CanvasLayer
## Ship menu (key I) with four tabs:
##   Info      – news, the active ship, contracts, the fleet (pilot, finances and career: Pilot window since 0.5.30.5)
##   Modules   – equipment as tiles by category (Core / Weapons / Tools / Optional), properties on the left;
##               when docked, modules can be swapped with station storage; POWER MANAGEMENT; CREW (package 31)
##   Ship      – complete ship statistics
##   Inventory – cargo hold (+ station storage when docked)
##   Transactions – sub-tabs: accepted contracts, bond wallet (bounty bonds, phase 0.5 package 9)
##   (Standing and Codex moved to the Pilot window in 0.5.30.5)

signal closed

const CATEGORIES := [
	["Core", "core"], ["Weapons", "weapon"], ["Tools", "tool"], ["Optional", "optional"],
	["Drone hangar – equipment for all drones", "drone"],
]
const TABS := ["Info", "Modules", "Ship", "Inventory", "Transactions", "Industry", "Market"]
const TAB_INDUSTRY := 5
const TAB_MARKET := 6
const CodexView = preload("res://scripts/ui/codex_view.gd")
const FactionData = preload("res://data/factions.gd")

var view: SystemView
var fit: ShipFitting
var tab := 0
var selected_slot := ""
var selected_store := ""
var sub_tab := 0                  # Transactions: 0 = contracts, 1 = bonds
var mod_view := "fitting"         # Modules tab: "fitting" | "power" (package 21)
const GROUP_COLORS := {1: Color(0.35, 0.85, 1.0), 2: Color(0.4, 1.0, 0.5), 3: Color(1.0, 0.8, 0.3), 4: Color(1.0, 0.5, 0.35)}
var _abandon_armed := ""

var title_label: Label
var sub_label: Label
var status_label: Label
var ship_icon: TextureRect
var tab_buttons: Array = []
var content: VBoxContainer


func _ready() -> void:
	add_to_group("kbd_menu")              # 0.5.28.2: keyboard control
	layer = 25
	visible = false
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.55)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	var win := UI.neon_panel(UI.NEON_CYAN, Color(0.03, 0.05, 0.09, 0.97))
	win.set_anchors_preset(Control.PRESET_FULL_RECT)
	win.offset_left = 50
	win.offset_right = -50
	win.offset_top = 46
	win.offset_bottom = -26
	bg.add_child(win)
	var v := UI.vbox(10)
	win.add_child(v)

	var head := UI.hbox(14)
	v.add_child(head)
	ship_icon = UI.icon(null, 64)
	ship_icon.custom_minimum_size = Vector2(110, 64)
	head.add_child(ship_icon)
	var names := UI.vbox(2)
	head.add_child(names)
	title_label = UI.label("", 22, UI.NEON_CYAN)
	names.add_child(title_label)
	sub_label = UI.label("", 13, UI.TEXT_DIM)
	names.add_child(sub_label)
	status_label = UI.label("", 13, UI.GOLD)
	names.add_child(status_label)
	head.add_child(UI.spacer())
	head.add_child(UI.button("Close [%s]" % Keybinds.key_text("ship_menu"), close))

	var tabs := UI.hbox(4)
	v.add_child(tabs)
	for i in TABS.size():
		var idx := i
		var b := UI.button(TABS[i].to_upper(), func(): _set_tab(idx))
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(160, 34)
		tabs.add_child(b)
		tab_buttons.append(b)
	var line := ColorRect.new()
	line.color = Color(UI.NEON_CYAN, 0.5)
	line.custom_minimum_size = Vector2(0, 2)
	v.add_child(line)

	content = UI.vbox(10)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(content)


func open(p_view: SystemView, p_tab: int = -1) -> void:
	Audio.play("ui_open", "ship menu")                   # package 28a
	view = p_view
	fit = GameState.active()
	if fit == null:
		return
	if p_tab >= 0:
		tab = p_tab
	visible = true
	rebuild()


func close() -> void:
	if visible:
		Audio.play("ui_close", "ship menu")
	if not visible:
		return
	visible = false
	closed.emit()


func _set_tab(i: int) -> void:
	tab = i
	rebuild()


## Q / E (0.5.28.2): the previous / next tab this ship has.
func menu_tab(step: int) -> void:
	var n := tab_buttons.size()
	var i := tab
	for k in n:
		i = posmod(i + step, n)
		if tab_buttons[i].visible:
			_set_tab(i)
			return


const MakerData = preload("res://data/manufacturers.gd")


## Manufacturer of a hull ("pirate-built" for pirate hulls).
static func _maker_name(h: Dictionary) -> String:
	var mk := String(h.get("maker", ""))
	if mk == "pirate":
		return "pirate-built"
	return String(MakerData.MAKERS.get(mk, {}).get("name", "unknown yard"))


func _docked() -> bool:
	return fit != null and fit.docked_at != ""


func rebuild() -> void:
	if not visible:
		return
	fit = GameState.active()
	if fit == null:
		return
	var h := fit.hull()
	ship_icon.texture = PixelArt.ship_texture(fit.hull_id, "player")
	title_label.text = fit.ship_name
	sub_label.text = "%s %s  •  %s  •  size %s  •  %s" % [h["class"], h["name"], _maker_name(h), GameData.SIZE_NAMES[int(h["size"])], fit.location_text()]
	status_label.text = "Docked – modules can be swapped with station storage." if _docked() else "In space – fitting can only be changed while docked."
	# Industry and Market only for ships that have a factory / an on-board market (package 25b)
	tab_buttons[TAB_INDUSTRY].visible = h.has("factory")
	tab_buttons[TAB_MARKET].visible = h.has("market")
	if not tab_buttons[tab].visible:
		tab = 0
	for i in tab_buttons.size():
		tab_buttons[i].button_pressed = i == tab
	UI.clear(content)
	match tab:
		0:
			_build_info()
		1:
			_build_modules()
		2:
			_build_ship()
		3:
			_build_inventory()
		4:
			_build_transactions()
		5:
			_build_industry()
		6:
			_build_market(_scroll())


# ================================================================ Industry (package 25b)

static var factory_filter := "drone"
const FACTORY_FILTERS := [["drone", "Drones"], ["weapon", "Weapons"], ["optional", "Optional"], ["hull", "Hull"], ["engine", "Engines"],
	["reactor", "Reactors"], ["distributor", "Distributors"], ["tank", "Tanks"]]


func _build_industry() -> void:
	_build_factory(_scroll())


func _build_factory(box: VBoxContainer) -> void:
	box.add_child(UI.label("FACTORY", 18, UI.NEON_CYAN))
	box.add_child(UI.wrap_label("Builds modules (like an industrial complex, up to size 7) and drones from the materials in your cargo hold. Every job takes time and only progresses while the factory is switched on (module bar) and this is your active ship, out in space – not while docked or parked. Finished modules go into the cargo hold, drones into the hangar.", 12, UI.TEXT_DIM, 900))
	var q: Array = GameState.ship_jobs(fit.uid)
	box.add_child(UI.label("Factory %s  •  %d job%s queued" % ["running" if fit.factory_on else "switched off", q.size(), "" if q.size() == 1 else "s"], 13, UI.GOOD if fit.factory_on else UI.GOLD))
	for j in q:
		var nm := "Drone" if j["item"] == "drone" else GameData.module_name(String(j["item"]))
		box.add_child(UI.label("  • %s – %d s left" % [nm, int(ceil(maxf(float(j["left"]), 0.0)))], 12, Color(1.0, 0.85, 0.5)))
	var tabs := UI.hbox(4)
	box.add_child(tabs)
	for fspec in FACTORY_FILTERS:
		var key: String = fspec[0]
		var b := UI.button(fspec[1], func(): factory_filter = key; rebuild())
		b.toggle_mode = true
		b.button_pressed = factory_filter == key
		tabs.add_child(b)
	var items: Array = []
	if factory_filter == "drone":
		items = ["drone"]
	else:
		for mid in Industry.buildable(Industry.SHIP_FACTORY):
			if String(GameData.modules[mid]["slot"]) == factory_filter:
				items.append(mid)
	for item in items:
		var rec: Dictionary = Industry.DRONE_RECIPE if item == "drone" else Industry.recipe(Industry.SHIP_FACTORY, item)
		var missing := Industry.missing_materials(fit, rec)
		var row := UI.hbox(12)
		box.add_child(row)
		row.add_child(UI.icon(PixelArt.icon_texture("drone") if item == "drone" else PixelArt.module_icon(item), 32))
		var nm2 := UI.label("Drone" if item == "drone" else GameData.module_name(item), 13, UI.NEON_CYAN)
		nm2.custom_minimum_size = Vector2(240, 0)
		row.add_child(nm2)
		var mats := UI.hbox(8)
		mats.custom_minimum_size = Vector2(460, 0)
		row.add_child(mats)
		for k in rec["materials"]:
			var need := int(rec["materials"][k])
			var have := int(fit.cargo.get(k, 0.0))
			mats.add_child(UI.label("%s %d/%d" % [GameData.item_name(k), mini(have, need), need], 12, UI.GOOD if have >= need else UI.BAD))
		row.add_child(UI.label("%d s" % int(Industry.build_time(item)), 12, UI.GOLD))
		var it: String = item
		var bb := UI.button("Build", func(): Commands.execute({"type": "ship_build", "item": it}); rebuild())
		bb.disabled = not missing.is_empty()
		row.add_child(bb)


func _build_market(box: VBoxContainer) -> void:
	box.add_child(UI.label("ON-BOARD MARKET", 18, UI.NEON_CYAN))
	box.add_child(UI.wrap_label("Offer goods from your hold at your own price. While the market is open (module bar) and the ship stands still in space, traders of the system fly over and buy – if your price is fair. Large offers attract pirates.", 12, UI.TEXT_DIM, 900))
	var total := 0
	for k in fit.market_offers:
		total += int(fit.market_offers[k]["amount"]) * int(fit.market_offers[k]["price"])
	box.add_child(UI.label("Market %s  •  on offer: %s%s" % ["OPEN" if fit.market_open else "closed", GameData.fmt_credits(total), "  •  pirates will notice" if total > SystemView.MARKET_PIRATE_VALUE else ""], 13, UI.GOOD if fit.market_open else UI.GOLD))
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 14)
	box.add_child(grid)
	for hd in ["Item", "In hold", "Offer", "Price each", "Base price", ""]:
		grid.add_child(UI.label(hd, 13, UI.NEON_CYAN))
	for item in fit.cargo:
		var have := int(floor(float(fit.cargo[item])))
		if have <= 0 or (not String(item).begins_with("mod:") and not GameData.is_tradeable(String(item))):
			continue
		var off: Dictionary = fit.market_offers.get(item, {})
		var base := SystemView.market_base_price(String(item))
		grid.add_child(UI.label(GameData.item_name(String(item)), 13))
		grid.add_child(UI.label(str(have), 13))
		var amt := SpinBox.new()
		amt.min_value = 0
		amt.max_value = have
		amt.value = int(off.get("amount", 0))
		grid.add_child(amt)
		var pr := SpinBox.new()
		pr.min_value = 1
		pr.max_value = base * 10
		pr.value = int(off.get("price", base))
		grid.add_child(pr)
		grid.add_child(UI.label(GameData.fmt_credits(base), 12, UI.TEXT_DIM))
		var it2: String = item
		grid.add_child(UI.button("Set", func(): Commands.execute({"type": "market_offer", "item": it2, "amount": int(amt.value), "price": int(pr.value)}); rebuild()))


# ================================================================ helpers

func _scroll() -> VBoxContainer:
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(sc)
	var box := UI.vbox(6)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(box)
	return box


func _card(parent: Control, title: String, width: float = 0.0) -> VBoxContainer:
	var p := UI.neon_panel(Color(UI.NEON_CYAN, 0.35), Color(0.05, 0.07, 0.12, 0.95), 1)
	if width > 0.0:
		p.custom_minimum_size = Vector2(width, 0)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(p)
	var v := UI.vbox(4)
	p.add_child(v)
	v.add_child(UI.label(title, 16, UI.NEON_CYAN))
	return v


func _kv(parent: Control, lines: Array) -> void:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 3)
	parent.add_child(grid)
	for line in lines:
		var s := String(line)
		var idx := s.find(":")
		if idx < 0:
			continue
		grid.add_child(UI.label(s.substr(0, idx), 13, Color(0.65, 0.72, 0.85)))
		grid.add_child(UI.label(s.substr(idx + 1).strip_edges(), 13, Color(0.95, 0.97, 1.0)))


static func _fmt_time(sec: float) -> String:
	var m := int(sec / 60.0)
	return "%dh %02dm" % [m / 60, m % 60]


# ================================================================ Info

func _build_info() -> void:
	var box := _scroll()
	_news_card(box)
	var row := UI.hbox(14)
	box.add_child(row)
	# Active ship
	var shipc := _card(row, "ACTIVE SHIP")
	var sys: Dictionary = Universe.systems[fit.system_id]
	_kv(shipc, [
		"Ship: %s" % fit.ship_name,
		"Hull: %s %s" % [fit.hull()["class"], fit.hull()["name"]],
		"Ship value: %s" % GameData.fmt_credits(GameState.ship_value(fit)),
		"Cargo value: %s" % GameData.fmt_credits(GameState.cargo_value(fit)),
		"Location: %s" % fit.location_text(),
		"Security: %.1f" % float(sys["security"]),
		"Control: %s" % Universe.territory_text(fit.system_id),
		"Active modules: %d (keys 1–9)" % fit.active_modules().size(),
		"Scan of this system: %d%%" % int(GameState.scan_progress(fit.system_id) * 100.0),
	])
	var hint := _card(row, "PILOT")
	hint.add_child(UI.wrap_label("Name, finances, career statistics, standings and the codex are in the Pilot window [%s]." % Keybinds.key_text("pilot_window"), 13, UI.TEXT_DIM, 360))
	# Contracts
	var con := _card(box, "ACTIVE CONTRACTS  (%d / %d)" % [GameState.contract_count(), GameState.MAX_ACTIVE_MISSIONS])
	if GameState.missions.is_empty():
		con.add_child(UI.label("No contracts. Visit a BlackLedger bulletin board at any station.", 13, UI.TEXT_DIM))
	for m in GameState.missions:
		var r := UI.hbox(14)
		con.add_child(r)
		r.add_child(UI.label(m["title"], 14))
		r.add_child(UI.spacer())
		r.add_child(UI.label(Missions.progress_text(m, fit), 13, UI.TEXT_DIM))
		r.add_child(UI.label(GameData.fmt_credits(int(m["reward"])), 14, UI.GOLD))
	# Fleet
	var fl := _card(box, "YOUR SHIPS")
	for f in GameState.fleet:
		var r := UI.hbox(12)
		fl.add_child(r)
		r.add_child(UI.icon(PixelArt.ship_texture(f.hull_id, "player"), 32))
		r.add_child(UI.label(("▶ " if f.uid == GameState.active_uid else "   ") + f.ship_name, 14, UI.GOOD if f.uid == GameState.active_uid else Color(0.9, 0.93, 1.0)))
		r.add_child(UI.spacer())
		r.add_child(UI.label(f.location_text(), 13, UI.TEXT_DIM))
		r.add_child(UI.label(GameData.fmt_credits(GameState.ship_value(f)), 13, UI.GOLD))




## Short news card on the Info tab (package 16) – the full archive is at every station.
func _news_card(box: Control) -> void:
	var card := _card(box, "NEWS  –  full archive at any station (Lumen Newsnet)")
	var items: Array = GameState.news.latest(6, GameState.current_system)
	if items.is_empty():
		card.add_child(UI.label("Nothing to report.", 13, UI.TEXT_DIM))
	for it in items:
		var col: Color = {"alert": Color(1.0, 0.4, 0.35), "radio": Color(0.5, 0.88, 1.0)}.get(String(it["kind"]), Color(1.0, 0.82, 0.45))
		card.add_child(UI.wrap_label("%s  %s" % [SaveGame.fmt_time(float(it["t"])), it["text"]], 13, col, 1100))
# ================================================================ Modules

func _build_modules() -> void:
	var sw := UI.hbox(4)
	content.add_child(sw)
	var views: Array = [["fitting", "FITTING"], ["power", "POWER MANAGEMENT"]]
	if not fit.crew_slots().is_empty():
		views.append(["crew", "CREW  %d / %d" % [fit.crew_members().size(), fit.crew_slots().size()]])     # package 31
	elif mod_view == "crew":
		mod_view = "fitting"
	for v in views:
		var key: String = v[0]
		var b := UI.button(v[1], func(): mod_view = key; rebuild())
		b.toggle_mode = true
		b.button_pressed = mod_view == key
		b.custom_minimum_size = Vector2(200, 30)
		sw.add_child(b)
	if mod_view == "power":
		_build_power()
		return
	if mod_view == "crew":
		_build_crew()
		return
	var body := UI.hbox(16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(body)
	var lp := UI.neon_panel(Color(UI.NEON_CYAN, 0.3), Color(0.05, 0.07, 0.12, 0.95), 1)
	lp.custom_minimum_size = Vector2(420, 0)
	body.add_child(lp)
	var ls := ScrollContainer.new()
	ls.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	lp.add_child(ls)
	var left := UI.vbox(6)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ls.add_child(left)
	var rs := ScrollContainer.new()
	rs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rs.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(rs)
	var right := UI.vbox(10)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rs.add_child(right)
	_build_module_details(left)
	_build_module_tiles(right)


# ---------------------------------------------------------------- Crew (package 31)

const CrewCard = preload("res://scripts/ui/crew_card.gd")
const CrewData = preload("res://data/crew.gd")
const CrewCore = preload("res://scripts/core/crew.gd")
var crew_sel := -1                 # the post picked for the next assignment


func _build_crew() -> void:
	var body := UI.hbox(16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(body)
	# the posts of this ship
	var ls := ScrollContainer.new()
	ls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ls.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(ls)
	var left := UI.vbox(6)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ls.add_child(left)
	var miss := fit.crew_missing()
	left.add_child(UI.label("CREW OF THE %s" % fit.ship_name.to_upper(), 15, UI.NEON_CYAN))
	left.add_child(UI.label("Required posts missing: %s – the ship cannot undock." % miss if miss != "" else "Every required post is filled.", 13, UI.BAD if miss != "" else UI.GOOD))
	left.add_child(UI.label("Share of income (sales, bounties, contract rewards): %.2f %%  •  paid so far %s" % [fit.crew_share() * 100.0, GameData.fmt_credits(int(GameState.stats.get("crew_paid", 0)))], 12, UI.TEXT_DIM))
	var sl := fit.crew_slots()
	var dock := _docked()
	for i in sl.size():
		var idx := i
		var role := String(sl[i][0])
		var req := bool(sl[i][1])
		var m: Dictionary = fit.crew_at(i)
		var picked := crew_sel == i
		var pick_b := ["◉ Picked" if picked else "Pick post", func(): crew_sel = -1 if crew_sel == idx else idx; rebuild(), not dock]
		var te := GameState.crew_role_error(role)
		if m.is_empty():
			var ep := CrewCard.empty_post(role, req, [pick_b])
			if te != "":
				ep.get_child(0).get_child(1).add_child(UI.label(te, 11, Color(1.0, 0.7, 0.3)))
			left.add_child(ep)
		else:
			left.add_child(CrewCard.card(m, [pick_b, ["To quarters", func(): _crew_cmd({"type": "crew_unassign", "ship": fit.uid, "slot": idx}), not dock]],
				"%s%s%s" % [CrewData.role_name(role), "  •  REQUIRED" if req else "", "  •  picked" if picked else ""], UI.GOLD if picked else UI.TEXT_DIM))
	# the crew quarters of the station
	var rp := UI.neon_panel(Color(UI.NEON_CYAN, 0.3), Color(0.05, 0.07, 0.12, 0.95), 1)
	rp.custom_minimum_size = Vector2(560, 0)
	body.add_child(rp)
	var rs := ScrollContainer.new()
	rs.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rp.add_child(rs)
	var right := UI.vbox(6)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rs.add_child(right)
	if not dock:
		right.add_child(UI.label("CREW QUARTERS", 15, UI.NEON_CYAN))
		right.add_child(UI.wrap_label("Crew can be moved while docked: every station keeps quarters for crew waiting for a post. Hire new crew at The Bar.", 13, UI.TEXT_DIM, 520))
		return
	var q: Array = GameState.quarters_of(fit.docked_at)
	right.add_child(UI.label("CREW QUARTERS OF THIS STATION  (%d)" % q.size(), 15, UI.NEON_CYAN))
	right.add_child(UI.wrap_label("Pick a post on the left to put someone exactly there; otherwise \"Assign\" takes the first free post that fits. New crew: The Bar on the concourse.", 12, UI.TEXT_DIM, 520))
	if q.is_empty():
		right.add_child(UI.label("Nobody waiting.", 13, UI.TEXT_DIM))
	for m2 in q:
		var mid := int(m2["id"])
		var target := crew_sel
		var ok := false
		for k in sl.size():
			if (target < 0 or k == target) and CrewCore.fits(m2, String(sl[k][0])) and (target >= 0 or fit.crew_at(k).is_empty()):
				ok = true
		right.add_child(CrewCard.card(m2, [["Assign", func(): _crew_cmd({"type": "crew_assign", "member": mid, "ship": fit.uid, "slot": target}), not ok],
			["Dismiss", func(): _crew_cmd({"type": "crew_dismiss", "member": mid})]]))


func _crew_cmd(c: Dictionary) -> void:
	Commands.execute(c)
	crew_sel = -1
	rebuild()


# ---------------------------------------------------------------- Power management (package 21)

## The output bar: one segment per priority group (solid = passive, light = active at most), the
## reactor output as a line.
class PowerBar extends Control:
	var groups := {}
	var available := 0.0
	var colors := {}

	func _draw() -> void:
		var total := 0.0
		for g in groups:
			total += float(groups[g]["passive"]) + float(groups[g]["active"])
		var scale_mw := maxf(maxf(total, available), 1.0)
		var w := size.x
		var h := size.y
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.06, 0.1))
		var x := 0.0
		for g in [1, 2, 3, 4]:
			# one block per group (passive + active at most)
			var mw := float(groups[g]["passive"]) + float(groups[g]["active"])
			if mw <= 0.0:
				continue
			var pw := mw / scale_mw * w
			draw_rect(Rect2(x, 0, pw, h), colors[g])
			draw_rect(Rect2(x, 0, pw, h), Color(0, 0, 0, 0.6), false, 1.0)
			if pw > 18.0:
				draw_string(ThemeDB.fallback_font, Vector2(x + 4, h * 0.5 + 5), "%d" % g, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0, 0, 0, 0.85))
			x += pw
		var ax := available / scale_mw * w
		if total > available:
			draw_rect(Rect2(ax, 0, w - ax, h), Color(1.0, 0.2, 0.2, 0.22))
		draw_line(Vector2(ax, -4), Vector2(ax, h + 4), Color(1, 1, 1), 2.0)
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.3), false, 1.0)


func _build_power() -> void:
	var box := _scroll()
	var s := fit.stats()
	var avail := float(s["power_available"])
	box.add_child(UI.label("POWER MANAGEMENT", 18, UI.NEON_CYAN))
	box.add_child(UI.wrap_label("The reactor output is a hard limit. Passive modules (core equipment, passive optional modules, scanners) always draw power; weapons and active modules only while they are in use. If the demand exceeds the output, priority group 4 shuts down first, then group 3, then group 2 – group 1 stays on (if it alone is too much, everything is throttled).", 12, UI.TEXT_DIM, 900))
	var bar := PowerBar.new()
	bar.groups = s["power_groups"]
	bar.available = avail
	bar.colors = GROUP_COLORS
	bar.custom_minimum_size = Vector2(900, 30)
	box.add_child(bar)
	var leg := UI.hbox(18)
	box.add_child(leg)
	for g in [1, 2, 3, 4]:
		var gd: Dictionary = s["power_groups"][g]
		leg.add_child(UI.label("■ Group %d: %.0f passive + %.0f active MW%s" % [g, float(gd["passive"]), float(gd["active"]), "  (OFF)" if fit.power_off.has(g) else ""], 12, GROUP_COLORS[g]))
	box.add_child(UI.label("Output %.0f MW  •  passive %.0f MW  •  active up to %.0f MW  •  white line = output" % [avail, float(s["power_passive"]), float(s["power_active_max"])], 12, Color(0.85, 0.9, 1.0)))
	var idle := fit.power_plan({})
	var all_on := {}
	for key in fit.slot_keys():
		all_on[key] = true
	var full := fit.power_plan(all_on)
	if not idle["off"].is_empty() or float(idle["throttle"]) < 1.0:
		box.add_child(UI.label("Even without active modules the passive draw is too high: %s." % _plan_text(idle), 13, UI.BAD))
	elif not full["off"].is_empty() or float(full["throttle"]) < 1.0:
		box.add_child(UI.label("With everything switched on: %s." % _plan_text(full), 13, UI.GOLD))
	else:
		box.add_child(UI.label("Everything can run at the same time.", 13, UI.GOOD))
	# module list
	var grid := GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 4)
	box.add_child(grid)
	for h in ["", "Module", "Quality", "Use", "Power", "Priority", ""]:
		grid.add_child(UI.label(h, 13, UI.NEON_CYAN))
	var pkeys := fit.slot_keys()
	for bm in fit.builtin_modules():
		pkeys.append(bm["key"])
	for key in pkeys:
		var m: Dictionary = fit.module_data(key)
		if m.is_empty():
			continue
		var mid := fit.get_module(key) if fit.get_module(key) != "" else String(m.get("id", ""))
		var pw := float(m.get("power", 0))
		var act: bool = ShipFitting.is_active_module(m) or m.get("builtin", false)
		var grp := fit.priority_of(key)
		grid.add_child(UI.icon(PixelArt.module_icon(mid), 26))
		var nm := UI.label("%s  (%s)" % [String(m["base_name"]), "built-in" if m.get("builtin", false) else GameData.slot_label(key)], 13, Color(1.0, 0.85, 0.5) if m.get("builtin", false) else Color(0.9, 0.93, 1.0))
		nm.custom_minimum_size = Vector2(330, 0)
		grid.add_child(nm)
		grid.add_child(UI.label("%d · %s" % [int(m["size"]), String(m["quality"])], 13, GameData.quality_color(String(m["quality"]))))
		grid.add_child(UI.label("Active" if act else "Passive", 13, UI.GOLD if act else Color(0.75, 0.8, 0.9)))
		grid.add_child(UI.label("%.0f MW" % pw if pw > 0.0 else "–", 13))
		var pr := UI.hbox(2)
		if grp == 0:
			pr.add_child(UI.label("0", 13, UI.TEXT_DIM))
		for g in ([] if grp == 0 else [1, 2, 3, 4]):
			var gg: int = g
			var k2: String = key
			var b := UI.button(str(g), func(): Commands.execute({"type": "set_priority", "slot": k2, "group": gg}); rebuild())
			b.toggle_mode = true
			b.button_pressed = grp == g
			b.custom_minimum_size = Vector2(30, 24)
			b.add_theme_color_override("font_color", GROUP_COLORS[g])
			b.add_theme_color_override("font_pressed_color", Color(0, 0, 0))
			if grp == g:
				var sbp := UI.panel_style(GROUP_COLORS[g], GROUP_COLORS[g])
				b.add_theme_stylebox_override("pressed", sbp)
			pr.add_child(b)
		grid.add_child(pr)
		grid.add_child(UI.label("OFF (overload)" if grp > 0 and fit.power_off.has(grp) else "", 12, UI.BAD))


func _plan_text(plan: Dictionary) -> String:
	var gs: Array = plan["off"].keys()
	gs.sort()
	var t := ""
	if not gs.is_empty():
		t = "group %s shut down%s" % [", ".join(PackedStringArray(gs.map(func(x): return str(x)))), " (demand %.0f of %.0f MW)" % [float(plan["requested"]), float(plan["available"])]]
	if float(plan["throttle"]) < 1.0:
		t += ("; " if t != "" else "") + "group 1 alone exceeds the output – all systems at %d %%" % int(float(plan["throttle"]) * 100.0)
	return t


func _build_module_details(left: VBoxContainer) -> void:
	if selected_store != "":
		_module_details(left, selected_store, "In station storage")
		var err := fit.can_fit(selected_slot, selected_store) if selected_slot != "" else "No slot selected"
		var b := UI.button("Fit into %s" % GameData.slot_label(selected_slot) if selected_slot != "" else "Select a slot first", _fit_selected)
		b.disabled = err != "" or not _docked()
		left.add_child(b)
		if err != "" and selected_slot != "":
			left.add_child(UI.label(err, 12, UI.BAD))
		return
	if selected_slot != "":
		var mid := fit.get_module(selected_slot)
		if mid == "":
			left.add_child(UI.label(GameData.slot_label(selected_slot), 18, UI.NEON_CYAN))
			left.add_child(UI.label("Empty slot", 14, UI.TEXT_DIM))
			if selected_slot in GameData.CORE_SLOTS:
				left.add_child(UI.label("Core equipment missing – the ship is impaired!", 12, UI.BAD))
			left.add_child(UI.wrap_label("Docked: pick a matching module from storage on the right." if _docked() else "Dock at a station to fit modules.", 12, UI.TEXT_DIM, 380))
			return
		_module_details(left, mid, GameData.slot_label(selected_slot))
		var b := UI.button("Unfit → station storage", _unfit_selected)
		b.disabled = not _docked()
		left.add_child(b)
		return
	left.add_child(UI.label("Select a module", 18, UI.NEON_CYAN))
	left.add_child(UI.wrap_label("Click a tile to see its properties. The full ship statistics are on the SHIP tab.", 13, UI.TEXT_DIM, 380))
	var s := fit.stats()
	_kv(left, [
		"Power: passive %.0f + active up to %.0f / %.0f MW" % [float(s["power_passive"]), float(s["power_active_max"]), float(s["power_available"])],
		"Mass: %.0f t" % s["mass"],
		"Speed: %.0f km/s" % s["speed"],
		"DPS: %.1f" % s["dps_total"],
	])
	if float(s["power_passive"]) + float(s["power_active_max"]) > float(s["power_available"]):
		left.add_child(UI.label("More power than the reactor gives – see POWER MANAGEMENT for what shuts down.", 12, UI.GOLD))


func _module_details(left: VBoxContainer, mid: String, where: String) -> void:
	var m: Dictionary = GameData.modules[mid]
	var head := UI.hbox(10)
	left.add_child(head)
	head.add_child(UI.icon(PixelArt.module_icon(mid), 72))
	var nv := UI.vbox(2)
	head.add_child(nv)
	nv.add_child(UI.label(m["name"], 18, UI.NEON_CYAN))
	var sq := UI.hbox(8)
	nv.add_child(sq)
	sq.add_child(UI.label("%s  •  size %d" % [GameData.SLOT_NAMES[m["slot"]], int(m["size"])], 13, GameData.size_color(int(m["size"]))))
	sq.add_child(UI.label("quality %s" % m["quality"], 13, GameData.quality_color(String(m["quality"]))))
	nv.add_child(UI.label(where, 12, UI.TEXT_DIM))
	left.add_child(HSeparator.new())
	var lines := GameData.module_summary(mid).split("\n")
	_kv(left, Array(lines.slice(1)))


func _build_module_tiles(right: VBoxContainer) -> void:
	var keys := fit.slot_keys()
	for cat in CATEGORIES:
		var slot_keys: Array = []
		var filled := 0
		for k in keys:
			var t := ShipFitting.slot_type(k)
			var is_core: bool = k in GameData.CORE_SLOTS
			if (cat[1] == "core" and is_core) or (cat[1] == "drone" and t in GameData.DRONE_SLOTS) or (not is_core and t == cat[1]):
				slot_keys.append(k)
				if fit.get_module(k) != "":
					filled += 1
		right.add_child(UI.label("%s   (%d/%d)" % [cat[0], filled, slot_keys.size()], 17, UI.NEON_CYAN))
		if slot_keys.is_empty():
			right.add_child(UI.label("  This hull has no slots of this kind.", 12, UI.TEXT_DIM))
			continue
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 8)
		flow.add_theme_constant_override("v_separation", 8)
		right.add_child(flow)
		for k in slot_keys:
			var key: String = k
			var mid := fit.get_module(key)
			var mx: int = fit.slot_max(key)
			var caption: String = ("%s (≤%d)" % [GameData.slot_label(key), mx]) if cat[1] == "core" else (GameData.modules[mid]["name"] if mid != "" else "empty (≤%d)" % mx)
			var on_slot := func():
				selected_slot = key
				selected_store = ""
				rebuild()
			var tip := "%s – takes modules up to size %d" % [GameData.slot_label(key), mx] + ("" if mid == "" else "\n" + GameData.module_name(mid))
			flow.add_child(_tile(mid, caption, key == selected_slot and selected_store == "", on_slot, tip))
		right.add_child(HSeparator.new())
	var builtins := fit.builtin_modules()
	if not builtins.is_empty():
		right.add_child(UI.label("Built into the hull   (%d)" % builtins.size(), 17, Color(1.0, 0.72, 0.2)))
		var bflow := HFlowContainer.new()
		bflow.add_theme_constant_override("h_separation", 8)
		right.add_child(bflow)
		for bm in builtins:
			bflow.add_child(_builtin_tile(bm["data"]))
		right.add_child(HSeparator.new())
	if _docked():
		var store := GameState.storage_of(fit.docked_at)
		var title := "Station storage"
		if selected_slot != "":
			title += " – fits %s" % GameData.slot_label(selected_slot)
		right.add_child(UI.label(title, 17, UI.GOLD))
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 8)
		flow.add_theme_constant_override("v_separation", 8)
		right.add_child(flow)
		var any := false
		for mod_id in store:
			if selected_slot != "" and fit.can_fit(selected_slot, mod_id) != "":
				continue
			any = true
			var mid2: String = mod_id
			var on_store := func():
				selected_store = mid2
				rebuild()
			flow.add_child(_tile(mid2, "%s ×%d" % [GameData.modules[mid2]["name"], int(store[mid2])], mid2 == selected_store, on_store, GameData.module_name(mid2)))
		if not any:
			right.add_child(UI.label("  No matching modules. Buy some at the outfitter or build them in manufacturing.", 12, UI.TEXT_DIM))


## A module built into the hull: gold frame, cannot be removed (package 25a).
func _builtin_tile(d: Dictionary) -> Control:
	var box := UI.vbox(2)
	box.custom_minimum_size = Vector2(92, 0)
	var p := PanelContainer.new()
	var st := UI.panel_style(Color(0.1, 0.09, 0.05), Color(1.0, 0.72, 0.2))
	st.set_border_width_all(3)
	p.add_theme_stylebox_override("panel", st)
	p.custom_minimum_size = Vector2(76, 76)
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var tip := "%s – built into the hull, cannot be removed" % d["name"]
	if String(d.get("active", "")) == "refinery":
		tip += "\nRefines ore from the hold: %.2f units/s at %d %% yield, %.0f MW while switched on (module bar)" % [float(d["rate"]), int(float(d["eff"]) * 100.0), float(d["power"])]
	p.tooltip_text = tip
	p.add_child(UI.icon(PixelArt.module_icon(String(d["id"])), 64))
	box.add_child(p)
	var l := UI.label(String(d["name"]).replace(" (built-in)", ""), 11, Color(1.0, 0.85, 0.5))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(92, 0)
	box.add_child(l)
	return box


func _tile(mid: String, caption: String, selected: bool, cb: Callable, tooltip: String) -> Control:
	var box := UI.vbox(2)
	box.custom_minimum_size = Vector2(92, 0)
	var b := Button.new()
	b.custom_minimum_size = Vector2(76, 76)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.focus_mode = Control.FOCUS_NONE
	b.toggle_mode = true
	b.button_pressed = selected
	b.icon = PixelArt.module_icon(mid) if mid != "" else PixelArt.icon_texture("empty")
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	b.tooltip_text = tooltip
	var border := Color(0.25, 0.3, 0.4)
	if mid != "":
		border = GameData.quality_color(String(GameData.modules[mid]["quality"]))
	var normal := UI.panel_style(Color(0.08, 0.1, 0.16), border)
	normal.set_border_width_all(2)
	var hover := UI.panel_style(Color(0.12, 0.16, 0.24), border.lightened(0.3))
	hover.set_border_width_all(2)
	var pressed := UI.panel_style(Color(0.1, 0.22, 0.3), Color(0.3, 1.0, 0.6))
	pressed.set_border_width_all(3)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("hover_pressed", pressed)
	b.pressed.connect(cb)
	box.add_child(b)
	if mid != "":
		var mm: Dictionary = GameData.modules[mid]
		var sz := UI.label(str(int(mm["size"])), 12, GameData.size_color(int(mm["size"])))
		sz.position = Vector2(6, 2)
		b.add_child(sz)
		var ql := UI.label(String(mm["quality"]), 12, GameData.quality_color(String(mm["quality"])))
		ql.position = Vector2(60, 2)
		b.add_child(ql)
	var l := UI.label(caption, 11, Color(0.8, 0.85, 0.95))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(92, 0)
	box.add_child(l)
	return box


func _fit_selected() -> void:
	if not _docked() or selected_slot == "" or selected_store == "":
		return
	if Commands.execute({"type": "fit_module", "slot": selected_slot, "module": selected_store}) == "":
		selected_store = ""
	rebuild()


func _unfit_selected() -> void:
	if not _docked() or selected_slot == "":
		return
	Commands.execute({"type": "unfit_module", "slot": selected_slot})
	rebuild()


# ================================================================ Ship

func _build_ship() -> void:
	var box := _scroll()
	var s := fit.stats()
	if not s["missing"].is_empty():
		var names: Array = []
		for k in s["missing"]:
			names.append(GameData.SLOT_NAMES[k])
		box.add_child(UI.label("Missing core equipment: %s" % ", ".join(PackedStringArray(names)), 13, UI.BAD))
	if not fit.power_off.is_empty():
		box.add_child(UI.label("Power overload – priority groups shut down: %s" % str(fit.power_off.keys()), 13, UI.BAD))
	var res: Dictionary = s["res"]
	var dps: Dictionary = s["dps"]
	var h := fit.hull()
	var row1 := UI.hbox(14)
	box.add_child(row1)
	_kv(_card(row1, "DEFENCE"), [
		"Structure: %.0f / %.0f" % [fit.structure, s["structure_max"]],
		"Armor: %.0f / %.0f" % [fit.armor, s["armor_max"]],
		"Shield: %.0f / %.0f" % [fit.shield, s["shield_max"]],
		"Shield regen: %.1f /s" % s["shield_regen"],
		"Shield downtime: %.0f s (then 50 %%)" % float(s["shield_downtime"]),
		"Optical resistance: %d%%" % int(res["optical"] * 100),
		"Kinetic resistance: %d%%" % int(res["kinetic"] * 100),
		"Explosive resistance: %d%%" % int(res["explosive"] * 100),
		"Signature: %.0f" % s["signature"],
	])
	_kv(_card(row1, "OFFENCE"), [
		"DPS optical: %.1f" % dps["optical"],
		"DPS kinetic: %.1f" % dps["kinetic"],
		"DPS explosive: %.1f" % dps["explosive"],
		"DPS total: %.1f" % s["dps_total"],
		"Optimal range: %.0f km" % s["optimal_range"],
		"Weapons fitted: %d / %d" % [s["weapons"].size(), int(h["slots"].get("weapon", 0))],
	])
	_kv(_card(row1, "NAVIGATION"), [
		"Speed: %.0f km/s" % s["speed"],
		"Agility: %.1f" % s["turn"],
		"Warp speed: %s/s" % SystemView.fmt_dist(s["warp_speed"]),
		"Mass: %.0f t" % s["mass"],
		"Hyperdrive: class %d" % int(s["drive_class"]),
		"Fuel per jump: %.0f" % s["jump_fuel"],
		"Spool-up: %.1f s" % s["spool"],
		"Fuel: %.0f / %.0f" % [fit.fuel, s["fuel_max"]],
	])
	var row2 := UI.hbox(14)
	box.add_child(row2)
	_kv(_card(row2, "POWER"), [
		"Reactor output: %.0f MW" % s["power_output"],
		"Distributor efficiency: %d%%" % int(float(s["efficiency"]) * 100.0),
		"Usable output: %.0f MW (hard limit)" % float(s["power_available"]),
		"Passive draw: %.0f MW (always)" % float(s["power_passive"]),
		"Active draw: up to %.0f MW (while in use)" % float(s["power_active_max"]),
		"Systems at: %d%%" % int(s["power_ratio"] * 100.0),
		"Capacitor: %.0f / %.0f" % [fit.capacitor, s["cap_max"]],
		"Recharge: %.1f /s" % s["cap_recharge"],
	])
	_kv(_card(row2, "SENSORS & UTILITY"), [
		"Sensor range: %.0f km" % s["sensor_range"],
		"Resolution: %.2f" % s["resolution"],
		"Scan strength: %.2f" % s["scan_strength"],
		"Cargo: %.0f / %.0f m³" % [fit.cargo_used(), s["cargo_max"]] + ("  •  gas tanks %.0f / %.0f m³" % [fit.gas_tank_used(), float(s["gas_cargo_max"])] if float(s.get("gas_cargo_max", 0.0)) > 0.0 else "")
			+ ("  •  shielded %.0f / %.0f m³" % [float(fit.rad_split()["shielded"]), float(s["rad_cargo_max"])] if float(s.get("rad_cargo_max", 0.0)) > 0.0 else ""),
		"Tools fitted: %d / %d" % [s["tools"].size(), int(h["slots"].get("tool", 0))],
		"Optional slots: %d" % int(h["slots"].get("optional", 0)),
	])
	var wc := _card(row2, "WEAPONS & TOOLS")
	if s["weapons"].is_empty() and s["tools"].is_empty():
		wc.add_child(UI.label("none", 13, UI.TEXT_DIM))
	for w in s["weapons"]:
		var r := UI.hbox(6)
		wc.add_child(r)
		r.add_child(UI.icon(PixelArt.module_icon(w["id"]), 24))
		r.add_child(UI.label("%s – %.0f dmg, %.0f km, %.1f DPS" % [w["name"], float(w["damage"]), float(w["range"]), float(w["damage"]) / float(w["cooldown"])], 12, GameData.DAMAGE_COLORS[w["damage_type"]]))
	for t in s["tools"]:
		var r := UI.hbox(6)
		wc.add_child(r)
		r.add_child(UI.icon(PixelArt.module_icon(t["id"]), 24))
		r.add_child(UI.label("%s (%s)" % [t["name"], GameData.TOOL_NAMES[t["tool"]]], 12))


# ================================================================ Inventory

## Package 41: the gas tanks and shielded racks under the cargo bar, with where the gas and the radioactive goods are.
func _extra_holds(c: Control) -> void:
	var s := fit.stats()
	var gmax := float(s.get("gas_cargo_max", 0.0))
	var rmax := float(s.get("rad_cargo_max", 0.0))
	if gmax > 0.0:
		c.add_child(UI.label("GAS TANKS  –  %.1f / %.0f m³" % [fit.gas_tank_used(), gmax], 13, UI.NEON_CYAN))
		var gb := UI.bar(Color(0.55, 0.85, 0.95), 600)
		gb.max_value = gmax
		gb.value = fit.gas_tank_used()
		c.add_child(gb)
	if fit.gas_in_racks() > 0.0:
		c.add_child(UI.label("Gas in the cargo racks: %.1f m³ – takes twice the room there (%.1f m³)%s" % [fit.gas_in_racks(), fit.gas_in_racks() * fit.GAS_RACK_MULT,
			"" if gmax > 0.0 else "  •  gas tanks hold it at its own volume"], 12, UI.GOLD))
	var rs := fit.rad_split()
	if rmax > 0.0:
		c.add_child(UI.label("SHIELDED RACKS  –  %.1f / %.0f m³" % [float(rs["shielded"]), rmax], 13, UI.NEON_CYAN))
		var rb := UI.bar(Color(0.55, 0.95, 0.4), 600)
		rb.max_value = rmax
		rb.value = float(rs["shielded"])
		c.add_child(rb)
	var over := float(rs["ore_over"]) + float(rs["other_over"])
	if over > 0.0:
		c.add_child(UI.label("☢ %.1f m³ of radioactive goods outside shielded racks – the crew is exposed" % over, 12, UI.BAD))


func _volume_text(item: String, amount: float) -> String:
	var v := amount * GameData.item_volume(item)
	if fit.is_gas(item):
		return "%.1f m³ (gas)" % v
	if fit.is_radioactive(item):
		return "%.1f m³ ☢" % v
	return "%.1f m³" % v


func _build_inventory() -> void:
	var box := _scroll()
	var ore_t := ""
	if float(fit.stats()["ore_cargo_max"]) > 0.0:
		ore_t = "   •   ORE HOLD %.1f / %.0f m³" % [fit.ore_hold_used(), float(fit.stats()["ore_cargo_max"])]
	var c := _card(box, "CARGO HOLD  –  %.1f / %.0f m³%s" % [fit.cargo_used(), float(fit.stats()["cargo_max"]), ore_t])
	var b := UI.bar(UI.GOLD, 600)
	b.max_value = maxf(float(fit.stats()["cargo_max"]), 0.001)
	b.value = fit.cargo_used()
	c.add_child(b)
	_extra_holds(c)                                  # package 41: gas tanks, shielded racks
	if fit.cargo.is_empty():
		c.add_child(UI.label("The cargo hold is empty.", 13, UI.TEXT_DIM))
	else:
		var grid := GridContainer.new()
		grid.columns = 6
		grid.add_theme_constant_override("h_separation", 20)
		grid.add_theme_constant_override("v_separation", 4)
		c.add_child(grid)
		for hd in ["", "Item", "Amount", "Volume", "Est. value", ""]:
			grid.add_child(UI.label(hd, 13, UI.NEON_CYAN))
		for item in fit.cargo.keys():
			var amount := float(fit.cargo[item])
			var tex: Texture2D
			if String(item).begins_with("mod:"):
				tex = PixelArt.module_icon(String(item).substr(4))
			elif GameData.commodities.has(item) and GameData.commodities[item].get("category", "") == "ore":
				tex = PixelArt.asteroid_texture(7, 18, item)
			else:
				tex = PixelArt.icon_texture("o_cargo")
			grid.add_child(UI.icon(tex, 24))
			grid.add_child(UI.label(GameData.item_name(item), 14))
			grid.add_child(UI.label("%.1f" % amount))
			grid.add_child(UI.label(_volume_text(String(item), amount), 13, UI.TEXT_DIM))
			grid.add_child(UI.label(GameData.fmt_credits(GameData.item_value(item) * amount) if GameData.item_value(item) > 0.0 else "–", 13, UI.GOLD))
			var id: String = item
			var jet := UI.button("Jettison", func(): _jettison(id))
			jet.disabled = id == "sealed_cargo"
			jet.tooltip_text = "Contract cargo cannot be jettisoned." if id == "sealed_cargo" else "Dump into space (lost)."
			grid.add_child(jet)
	if _docked():
		var store := GameState.storage_of(fit.docked_at)
		var sc := _card(box, "STATION STORAGE  –  %s" % Universe.find_station(fit.system_id, fit.docked_at).get("name", ""))
		if store.is_empty():
			sc.add_child(UI.label("Nothing stored here.", 13, UI.TEXT_DIM))
		for mid in store:
			var r := UI.hbox(10)
			sc.add_child(r)
			r.add_child(UI.icon(PixelArt.module_icon(mid), 24))
			r.add_child(UI.label("%s ×%d" % [GameData.module_name(mid), int(store[mid])], 14))
	var other := _card(box, "STORAGE ELSEWHERE")
	var found := false
	for st_id in GameState.storage:
		if _docked() and st_id == fit.docked_at:
			continue
		var items: Dictionary = GameState.storage[st_id]
		if items.is_empty():
			continue
		found = true
		var n := 0
		for mid in items:
			n += int(items[mid])
		other.add_child(UI.label("%s: %d modules" % [_station_name(st_id), n], 13))
	if not found:
		other.add_child(UI.label("–", 13, UI.TEXT_DIM))


func _station_name(st_id: String) -> String:
	var parts := st_id.split("_")
	if parts.size() >= 2:
		var st := Universe.find_station(int(parts[1]), st_id)
		if not st.is_empty():
			return st["name"]
	return st_id


func _jettison(item: String) -> void:
	Commands.execute({"type": "jettison", "item": item})
	rebuild()


# ================================================================ Transactions

const MISSION_COLORS := {"courier": Color(0.4, 0.85, 1.0), "bounty": Color(1.0, 0.35, 0.35), "mining": Color(1.0, 0.75, 0.3), "survey": Color(0.8, 0.5, 1.0)}
const MISSION_LABELS := {"courier": "COURIER", "bounty": "BOUNTY", "mining": "SUPPLY", "survey": "SURVEY"}


func _build_transactions() -> void:
	var bar := UI.hbox(4)
	content.add_child(bar)
	var subs := ["Contracts (%d / %d)" % [GameState.contract_count(), GameState.MAX_ACTIVE_MISSIONS], "Bonds (%d)" % GameState.bonds.size()]
	for i in subs.size():
		var idx := i
		var b := UI.button(subs[i], func():
			sub_tab = idx
			_abandon_armed = ""
			rebuild())
		b.toggle_mode = true
		b.button_pressed = i == sub_tab
		b.custom_minimum_size = Vector2(200, 30)
		bar.add_child(b)
	if sub_tab == 0:
		_build_contracts()
	else:
		_build_bonds()


func _build_contracts() -> void:
	var box := _scroll()
	if GameState.missions.is_empty():
		var c := _card(box, "NO ACTIVE CONTRACTS")
		c.add_child(UI.wrap_label("Contracts are offered on the BlackLedger bulletin boards of the stations. You can hold up to %d at a time." % GameState.MAX_ACTIVE_MISSIONS, 13, UI.TEXT_DIM, 900))
		return
	var total := 0
	for m in GameState.missions:
		total += int(m["reward"])
		var col: Color = MISSION_COLORS.get(String(m["type"]), Color.WHITE)
		var p := UI.neon_panel(Color(col, 0.55), Color(0.05, 0.07, 0.12, 0.95), 1)
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_child(p)
		var v := UI.vbox(4)
		p.add_child(v)
		var head := UI.hbox(10)
		v.add_child(head)
		head.add_child(UI.label(MISSION_LABELS.get(String(m["type"]), "?"), 13, col))
		head.add_child(UI.label(m["title"], 16))
		head.add_child(UI.spacer())
		head.add_child(UI.label(GameData.fmt_credits(int(m["reward"])), 16, UI.GOLD))
		v.add_child(UI.wrap_label(m.get("desc", ""), 13, UI.TEXT_DIM, 1100))
		var giver := Universe.find_station(int(m["giver_system"]), String(m["giver"]))
		var lines: Array = ["Client: %s  •  issued at %s (%s)" % [m.get("client", "?"), giver.get("name", "?"), Universe.systems[int(m["giver_system"])]["name"]]]
		var turn_in: String = giver.get("name", "?")
		var dest_sys := int(m["giver_system"])
		if m["type"] == "courier":
			turn_in = Universe.find_station(int(m["target_system"]), String(m["target_station"])).get("name", "?")
			dest_sys = int(m["target_system"])
		lines.append("Progress: %s" % Missions.progress_text(m, fit))
		lines.append("Hand in at: %s (%s)" % [turn_in, Universe.systems[dest_sys]["name"]])
		_kv(v, lines)
		var row := UI.hbox(8)
		v.add_child(row)
		var work_sys := int(m["target_system"])
		if work_sys != fit.system_id:
			var ws := work_sys
			row.add_child(UI.button("Course to %s" % Universe.systems[ws]["name"], func(): _course(ws)))
		if dest_sys != fit.system_id and dest_sys != work_sys:
			var ds := dest_sys
			row.add_child(UI.button("Course to %s (hand in)" % Universe.systems[ds]["name"], func(): _course(ds)))
		row.add_child(UI.spacer())
		var mid: String = m["id"]
		var armed := _abandon_armed == mid
		var ab := UI.button("Really abandon?" if armed else "Abandon", func(): _abandon(mid), "Cancel this contract (click twice)")
		if armed:
			ab.add_theme_color_override("font_color", UI.NEON_PINK)
		row.add_child(ab)
	box.add_child(UI.label("Total rewards on offer: %s" % GameData.fmt_credits(total), 14, UI.GOLD))


func _course(sid: int) -> void:
	var err := Commands.execute({"type": "course", "to": sid})
	GameState.log_msg(err if err != "" else "Course set to %s." % Universe.systems[sid]["name"], GameState.COL_WARN if err != "" else GameState.COL_GOOD)
	rebuild()


func _abandon(mid: String) -> void:
	if _abandon_armed != mid:
		_abandon_armed = mid
		rebuild()
		return
	_abandon_armed = ""
	Commands.execute({"type": "mission_abandon", "id": mid})
	rebuild()


func _build_bonds() -> void:
	var box := _scroll()
	var head := _card(box, "BOND WALLET")
	var st := Commands.docked_station()
	var here: Array = GameState.bonds_redeemable_at(st, fit.system_id) if not st.is_empty() else GameState.bonds_redeemable_in(fit.system_id)
	var here_sum := 0
	for b in here:
		here_sum += int(b["amount"])
	_kv(head, [
		"Bonds held: %d  •  total value %s" % [GameState.bonds.size(), GameData.fmt_credits(GameState.bonds_total())],
		"Redeemable %s: %d (%s)" % ["at this station" if not st.is_empty() else "in this system", here.size(), GameData.fmt_credits(here_sum)],
		"Cleared by the Sable Writ Exchange [SWX] – \"Every head has a price.\"",
	])
	head.add_child(UI.wrap_label("Bounties are put out by the three powers – the one holding the system, in pirate space the nearest one – and paid as bonds. A bond is redeemed at the Bond Office of ANY station of the issuing faction. Bonds belong to you, survive the loss of your ship and never expire.", 13, UI.TEXT_DIM, 1100))
	var list := _card(box, "BONDS")
	var hdr := UI.hbox(12)
	list.add_child(hdr)
	for col in [["Issuer", 170], ["Target", 300], ["Amount", 120], ["Issued", 230], ["Redeem at", 300]]:
		var l := UI.label(col[0], 13, UI.ACCENT)
		l.custom_minimum_size = Vector2(col[1], 0)
		hdr.add_child(l)
	if GameState.bonds.is_empty():
		list.add_child(UI.label("No bonds yet – destroy wanted pirates (a Warrant Scanner shows who is wanted).", 13, UI.TEXT_DIM))
	var sorted: Array = GameState.bonds.duplicate()
	sorted.sort_custom(func(x, y): return int(x in here) > int(y in here))
	for b in sorted:
		var r := UI.hbox(12)
		list.add_child(r)
		var f := String(b.get("faction", ""))
		var ok: bool = b in here
		var who := UI.hbox(6)
		who.custom_minimum_size = Vector2(170, 0)
		if f != "":
			who.add_child(UI.icon(CrestArt.texture(f), 20))
		who.add_child(UI.label(FactionData.short_of(f) if f != "" else "(old bond)", 13, FactionData.color_of(f) if f != "" else UI.TEXT_DIM))
		r.add_child(who)
		var where: String = ("here" + (" (dock at a station)" if fit.docked_at == "" else "")) if ok else GameState.bond_where(b, fit.system_id)
		var cells := [[String(b.get("target", "?")), 300, Color(0.9, 0.93, 1.0)],
			[GameData.fmt_credits(int(b.get("amount", 0))), 120, UI.GOLD],
			["%s  •  %s" % [Universe.systems[int(b["system"])]["name"], SaveGame.fmt_time(float(b.get("time", 0.0)))], 230, UI.TEXT_DIM],
			[where, 300, UI.GOOD if ok else UI.TEXT_DIM]]
		for c in cells:
			var l2 := UI.label(String(c[0]), 13, c[2])
			l2.custom_minimum_size = Vector2(c[1], 0)
			r.add_child(l2)
		if not ok:
			var tgt_sys: int = GameState.faction_office_system(f, fit.system_id) if f != "" else int(b.get("redeem", b["system"]))
			r.add_child(UI.button("Course", func(): _course(tgt_sys)))


