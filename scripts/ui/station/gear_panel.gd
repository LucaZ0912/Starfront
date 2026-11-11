extends StationServicePanel
## Package 51 (0.7.51.2): the Gear shop – the personal outfitter. What you buy goes into your pockets – put it on in
## the pilot window (Gear tab).
## 0.7.51.8 (Luz, with a sketch): three steps deep, with pictures –
##   1. the shop's front: four big picture tiles – Suits, Weapons, Features (the suit's modules), Belt (tools, grenades,
##      consumables) – each with how many pieces are here; under them selling from your pockets
##   2. a category: its kinds as picture tiles (e.g. lasers, slug guns, explosive)
##   3. a kind: the list – each piece with its picture, its numbers and a button per quality the shop carries (F–A,
##      in the quality's colour, with its price)

const GearData = preload("res://data/gear.gd")
const GearIcons = preload("res://scripts/ui/gear_icons.gd")

## category → [title, [[group key, title, line, families …]]]
const CATS := {
	"suit": ["Suits", "Spacesuits – the pilot's hull", [
		["suit_plain", "Civilian & work", "Sealed, light, long life support", ["suit_civil", "suit_work", "suit_survey"]],
		["suit_combat", "Combat", "Shield, plate, more weapons", ["suit_mil_light", "suit_mil_heavy"]]]],
	"weapon": ["Weapons", "Sidearms, rifles, heavy weapons", [
		["wp_optical", "Lasers", "Optical – strong on shields, on suit energy", ["wp_laser_pistol", "wp_laser_rifle", "wp_beam"]],
		["wp_kinetic", "Slug guns", "Kinetic – strong on armour, on ammunition", ["wp_pistol", "wp_smg", "wp_rifle", "wp_shotgun", "wp_sniper"]],
		["wp_explosive", "Explosive", "Splash – strong on the body", ["wp_launcher"]]]],
	"feature": ["Features", "The suit's modules", [
		["ft_def", "Defence", "Shield and plate", ["ft_shield", "ft_plates"]],
		["ft_move", "Movement", "Servos and thrust", ["ft_sprint", "ft_jets"]],
		["ft_life", "Life support & supply", "Air, energy, heat, rounds", ["ft_thermo", "ft_o2", "ft_battery", "ft_ammo"]]]],
	"belt": ["Belt", "Tools, grenades, consumables", [
		["bt_tool", "Tools", "Scanner, torch, mining laser", ["tl_scanner", "tl_cutter", "tl_mining"]],
		["bt_grenade", "Grenades", "Frag, EMP, smoke, shield", ["gr_frag", "gr_emp", "gr_smoke", "gr_shield"]],
		["bt_use", "Consumables", "Medkits, cells, air, ammunition", ["cs_medkit", "cs_stim", "cs_cell", "cs_o2", "cs_ammo"]]]],
}
const ORDER := ["suit", "weapon", "feature", "belt"]

static var view := ""                   # "" the front, a category, "sell"
static var group := ""                  # the kind picked within the category ("" = its kinds as tiles)


func build() -> void:
	UI.clear(self)                                   # 0.7.51.9: a rebuild (after a purchase, a resize) starts afresh
	var o := GearShop.offer(station)
	var g = GameState.gear
	if view != "" and view != "sell" and not CATS.has(view):
		view = ""
	_crumbs(o)
	match view:
		"":
			_front(o, g)
		"sell":
			_sell(g)
		_:
			if group == "":
				_kinds(o)
			else:
				_list(o)


# ---------------------------------------------------------------- the way back

func _crumbs(o: Dictionary) -> void:
	var g = GameState.gear
	var r := UI.hbox(8)
	add_child(r)
	if view != "":
		r.add_child(UI.button("‹ Back", func():
			if group != "":
				group = ""
			else:
				view = ""
			refresh_all()))
	var path := "GEAR"
	if view == "sell":
		path += "  ›  SELL"
	elif view != "":
		path += "  ›  " + String(CATS[view][0]).to_upper()
		if group != "":
			path += "  ›  " + String(_group(view, group)[1]).to_upper()
	r.add_child(UI.label(path, 16, corp_color()))
	r.add_child(UI.spacer())
	r.add_child(UI.label("Pockets %d / %d free   •   %s" % [g.free_places(), GearData.INV_SLOTS, GameData.fmt_credits(GameState.credits)], 13, UI.TEXT_DIM))


# ---------------------------------------------------------------- 1. the front

func _front(o: Dictionary, g) -> void:
	# the tiles fill the window: as wide as the panel (they share it), as high as the window leaves room for
	var th := front_height(get_viewport().get_visible_rect().size.y)
	var row := UI.hbox(10)
	add_child(row)
	row.add_child(_cat_tile("suit", o, Vector2(220, th)))
	row.add_child(_cat_tile("weapon", o, Vector2(220, th)))
	var col := UI.vbox(10)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_stretch_ratio = 1.4
	row.add_child(col)
	for c2 in ["feature", "belt"]:
		var t2 := _cat_tile(c2, o, Vector2(260, (th - 10.0) * 0.5))
		t2.size_flags_vertical = Control.SIZE_EXPAND_FILL
		col.add_child(t2)
	var n: int = GearData.INV_SLOTS - g.free_places()
	var sb := UI.button("Sell from your pockets  (%d)  ›" % n, func(): view = "sell"; group = ""; refresh_all())
	sb.custom_minimum_size = Vector2(300, 36)
	sb.disabled = n == 0
	var r := UI.hbox(8)
	r.add_child(sb)
	r.add_child(UI.label("What you buy goes into your pockets – put it on in the Pilot window, Gear tab [%s]." % Keybinds.key_text("pilot_window"), 12, UI.TEXT_DIM))
	add_child(r)


## The front tiles' height for a window this high (the header, the shop's banner, the way back and the sell bar above
## and below them).
static func front_height(view_h: float) -> float:
	return clampf(view_h - 350.0, 280.0, 1400.0)


func _ready() -> void:
	get_viewport().size_changed.connect(_on_resize)


var _resize_due := false


func _on_resize() -> void:
	if view != "" or _resize_due or not is_inside_tree():
		return
	_resize_due = true                                   # (once the window has settled, not on every step of a drag)
	get_tree().create_timer(0.15).timeout.connect(func():
		if is_instance_valid(self) and is_inside_tree() and is_instance_valid(ui):
			refresh_all())


func _cat_tile(cat: String, o: Dictionary, size: Vector2) -> Control:
	var n := 0
	for gr in CATS[cat][2]:
		n += _here(o, gr[3]).size()
	var art := ShopArt.new()
	art.kind = cat
	art.col = corp_color()
	art.custom_minimum_size = size
	art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art.title = String(CATS[cat][0])
	art.line = "Available: %d" % n
	art.icon_tex = GearIcons.icon(_first_of(cat))
	art.pics = _pics(cat)
	art.look = _suit_look()
	art.dim = n == 0
	art.clicked = func(): view = cat; group = ""; refresh_all()
	art.tooltip_text = String(CATS[cat][1])
	return art


# ---------------------------------------------------------------- 2. a category's kinds

func _kinds(o: Dictionary) -> void:
	add_child(UI.label(String(CATS[view][1]), 13, UI.TEXT_DIM))
	var flow := UI.hbox(10)
	add_child(flow)
	for gr in CATS[view][2]:
		var here := _here(o, gr[3])
		var art := ShopArt.new()
		art.kind = "group"
		art.col = corp_color()
		art.custom_minimum_size = Vector2(312, 300)
		art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		art.title = String(gr[1])
		art.line = "%s   •   Available: %d" % [String(gr[2]), here.size()]
		var fams: Array = gr[3]
		art.icon_tex = GearIcons.icon(String(fams[0]))
		art.pics = fams.map(func(f): return GearIcons.icon(String(f)))
		art.look = _suit_look()
		art.suits = fams if view == "suit" else []
		art.dim = here.is_empty()
		var key := String(gr[0])
		art.clicked = func(): group = key; refresh_all()
		flow.add_child(art)


# ---------------------------------------------------------------- 3. the list

func _list(o: Dictionary) -> void:
	var gr: Array = _group(view, group)
	add_child(UI.label(String(gr[2]) + "  –  a button per quality this shop carries; point at it for the numbers at that quality.", 13, UI.TEXT_DIM))
	var heads: Array = _columns(view)
	var hr := UI.hbox(8)
	add_child(hr)
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(56, 0)
	hr.add_child(sp)
	var hn := UI.label("PIECE", 12, corp_color())
	hn.custom_minimum_size = Vector2(220, 0)
	hr.add_child(hn)
	for h in heads:
		var hl := UI.label(String(h[0]).to_upper(), 12, corp_color())
		hl.custom_minimum_size = Vector2(float(h[1]), 0)
		hr.add_child(hl)
	hr.add_child(UI.spacer())
	hr.add_child(UI.label("QUALITY  F – A", 12, corp_color()))
	var any := false
	for f in gr[3]:
		if not o.has(f):
			continue
		any = true
		add_child(_row(String(f), o[f], heads))
	if not any:
		add_child(UI.label("Nothing of this kind here – try a bigger station or a military system.", 13, UI.TEXT_DIM))


func _row(f: String, qs: Array, heads: Array) -> Control:
	var b: Dictionary = GearData.base(f)
	var p := PanelContainer.new()
	var st := UI.panel_style(Color(0.06, 0.07, 0.1, 0.9), Color(corp_color(), 0.25))
	st.set_border_width_all(1)
	p.add_theme_stylebox_override("panel", st)
	var r := UI.hbox(8)
	p.add_child(r)
	var ib := PanelContainer.new()
	ib.add_theme_stylebox_override("panel", UI.panel_style(Color(0.08, 0.1, 0.14), Color(0.3, 0.33, 0.4)))
	ib.add_child(UI.icon(GearIcons.icon(f), 48))
	r.add_child(ib)
	var nv := UI.vbox(1)
	nv.custom_minimum_size = Vector2(220, 0)
	nv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	nv.add_child(UI.label(String(b["name"]), 15, Color(0.95, 0.95, 0.92)))
	nv.add_child(UI.wrap_label(String(b.get("desc", "")), 11, UI.TEXT_DIM, 220))
	r.add_child(nv)
	var cid := GearShop.id_of(f, "C" if GearData.has_quality(f) else "")
	var s: Dictionary = GearData.stats(cid)
	for h in heads:
		var vl := UI.label(_value(String(h[0]), f, s), 13, Color(0.88, 0.9, 0.95))
		vl.custom_minimum_size = Vector2(float(h[1]), 0)
		vl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		r.add_child(vl)
	r.add_child(UI.spacer())
	var qrow := UI.hbox(4)
	qrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.add_child(qrow)
	if qs.size() == 1 and String(qs[0]) == "":
		var id0 := GearShop.id_of(f, "")
		var pr0 := buy_price(GearData.price(id0))
		var b0 := UI.button("Buy  " + GameData.fmt_credits(pr0), func(): run({"type": "gear_buy", "id": id0}))
		b0.disabled = GameState.credits < pr0
		b0.tooltip_text = "\n".join(GearData.describe(id0))
		qrow.add_child(b0)
	else:
		for q in GearData.QUALITIES:
			var qb := Button.new()
			qb.custom_minimum_size = Vector2(70, 44)
			qb.focus_mode = Control.FOCUS_NONE
			var qc := GameData.quality_color(String(q))
			if not qs.has(q):
				qb.text = "%s\n–" % q
				qb.disabled = true
				qb.tooltip_text = "Quality %s – not sold here" % q
			else:
				var id := GearShop.id_of(f, String(q))
				var price := buy_price(GearData.price(id))
				qb.text = "%s\n%s" % [q, GameData.fmt_credits(price)]
				qb.tooltip_text = "\n".join(GearData.describe(id))
				qb.disabled = GameState.credits < price
				qb.add_theme_color_override("font_color", qc)
				qb.pressed.connect(func(): run({"type": "gear_buy", "id": id}))
			qb.add_theme_font_size_override("font_size", 12)
			var ns := UI.panel_style(Color(0.07, 0.08, 0.11), Color(qc, 0.7 if qs.has(q) else 0.15))
			ns.set_border_width_all(2)
			qb.add_theme_stylebox_override("normal", ns)
			var hs := UI.panel_style(Color(qc.darkened(0.7), 1.0), qc)
			hs.set_border_width_all(2)
			qb.add_theme_stylebox_override("hover", hs)
			qb.add_theme_stylebox_override("disabled", UI.panel_style(Color(0.05, 0.05, 0.07), Color(qc, 0.12)))
			qrow.add_child(qb)
	return p


## The columns of a category's list: [title, width].
func _columns(cat: String) -> Array:
	match cat:
		"suit":
			return [["Slots", 120], ["Shield", 60], ["Armour", 60], ["Energy", 60], ["Air", 60], ["Speed", 56]]
		"weapon":
			return [["Damage", 80], ["Rate", 60], ["Range", 60], ["Uses", 90]]
		"feature":
			return [["Effect", 260]]
	return [["Kind", 80], ["Effect", 200], ["Stack", 50]]


## A number of a piece for the list (at quality C).
func _value(col: String, f: String, s: Dictionary) -> String:
	match col:
		"Slots":
			return "%dW · %dG · %dB · %dF" % [int(s["weapons"]), int(s.get("grenades", 0)), int(s["belt"]), int(s["features"])]
		"Shield":
			return "%d" % int(s["shield"])
		"Armour":
			return "%d" % int(s["armor"])
		"Energy":
			return "%d" % int(s["energy"])
		"Air":
			return "%d min" % int(s["oxygen"])
		"Speed":
			return "×%.2f" % float(s["speed"])
		"Damage":
			return ("%d×%d" % [int(s["pellets"]), int(s["damage"])]) if s.has("pellets") else "%d" % int(s["damage"])
		"Rate":
			return "%.1f/s" % float(s["rof"])
		"Range":
			return "%d m" % int(float(s["range"]) / 15.0)
		"Uses":
			return ("%.1f energy" % float(s["energy"])) if s.has("energy") else "%d round%s" % [int(s.get("ammo", 1)), "" if int(s.get("ammo", 1)) == 1 else "s"]
		"Kind":
			return {"grenade": "Grenade", "tool": "Tool", "use": "Consumable"}.get(String(s.get("kind", "")), "")
		"Stack":
			return "×%d" % GearData.stack_max(f) if GearData.stack_max(f) > 1 else "–"
		"Effect":
			var lines: Array = GearData.describe(GearShop.id_of(f, "C" if GearData.has_quality(f) else ""))
			if lines.size() < 4:
				return ""
			var parts: Array = Array(String(lines[2]).split(" · "))
			if GearData.kind(f) == "belt":
				parts.pop_front()                                # (the kind has its own column)
			return " · ".join(parts)
	return ""


# ---------------------------------------------------------------- selling

func _sell(g) -> void:
	add_child(UI.label("The shop pays half the price for used gear.", 13, UI.TEXT_DIM))
	var any := false
	for i in g.inv.size():
		var p: Dictionary = g.inv[i]
		if p.is_empty():
			continue
		any = true
		var id := String(p["id"])
		var each := int(round(float(GearData.price(id)) * GearShop.SELL_SHARE))
		var r := UI.hbox(10)
		r.add_child(UI.icon(GearIcons.icon(id), 40))
		r.add_child(UI.label(GearData.display_name(id) + (" ×%d" % int(p["n"]) if int(p["n"]) > 1 else ""), 14, _qcol(id)))
		r.add_child(UI.spacer())
		var idx: int = i
		r.add_child(UI.button("Sell %s" % GameData.fmt_credits(each * int(p["n"])), func(): run({"type": "gear_sell", "slot": idx})))
		add_child(r)
	if not any:
		add_child(UI.label("Nothing in your pockets.", 13, UI.TEXT_DIM))


# ---------------------------------------------------------------- helpers

func _here(o: Dictionary, fams: Array) -> Array:
	return fams.filter(func(f): return o.has(f))


func _group(cat: String, key: String) -> Array:
	for gr in CATS[cat][2]:
		if String(gr[0]) == key:
			return gr
	return CATS[cat][2][0]


func _first_of(cat: String) -> String:
	return String(CATS[cat][2][0][3][0])


func _pics(cat: String) -> Array:
	var fams: Array = {"suit": [], "weapon": ["wp_sniper", "wp_rifle", "wp_laser_rifle", "wp_launcher", "wp_pistol", "wp_laser_pistol"],
		"feature": ["ft_shield", "ft_jets", "ft_plates", "ft_battery"], "belt": ["tl_scanner", "gr_frag", "cs_medkit", "tl_cutter", "cs_cell", "gr_emp"]}[cat]
	return fams.map(func(f): return GearIcons.icon(String(f)))


func _suit_look() -> Dictionary:
	var look: Dictionary = (GameState.pilot.get("look", ChibiArt.PilotArt.default_look()) as Dictionary).duplicate()
	look["helmet"] = true
	return look


func _qcol(id: String) -> Color:
	var q := GearData.quality(id)
	return GameData.quality_color(q) if q != "" else Color(0.92, 0.92, 0.9)


## A big picture tile: a lit showroom backdrop in the shop's colour, the goods on it, a bar along the foot with its
## icon, its title and what is here.
class ShopArt extends Control:
	var kind := ""
	var col := Color(1.0, 0.6, 0.2)
	var title := ""
	var line := ""
	var icon_tex: Texture2D
	var pics: Array = []
	var suits: Array = []
	var look := {}
	var dim := false
	var clicked: Callable
	var _hover := false

	func _ready() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		clip_contents = true
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		mouse_entered.connect(func(): _hover = true; queue_redraw())
		mouse_exited.connect(func(): _hover = false; queue_redraw())

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and clicked.is_valid():
			Audio.play("ui_click", "gear")
			clicked.call()

	func _draw() -> void:
		var sz := size
		var bar_h := 46.0
		var art := Rect2(Vector2.ZERO, Vector2(sz.x, sz.y - bar_h))
		# the backdrop: a dark showroom lit in the shop's colour, wall panels, a glow from below
		draw_rect(Rect2(Vector2.ZERO, sz), Color(0.04, 0.04, 0.06))
		for k in 12:
			var t := float(k) / 12.0
			draw_rect(Rect2(0, art.size.y * t, sz.x, art.size.y / 12.0 + 1.0), col.darkened(0.82 - 0.35 * t))
		for x in range(0, int(sz.x), 46):
			draw_rect(Rect2(x, 0, 1, art.size.y), Color(col, 0.12))
		draw_rect(Rect2(0, art.size.y * 0.72, sz.x, 1), Color(col, 0.35))
		var cx := sz.x * 0.5
		match kind:
			"suit":
				_plinth(Vector2(cx, art.size.y - 26), 92.0)
				var suit_look := look.duplicate()
				suit_look["suit"] = "suit_mil_light"
				var tx := ChibiArt.frame(suit_look, 0, 0)
				var h := art.size.y - 50.0
				var w := h * tx.get_width() / tx.get_height()
				draw_texture_rect(tx, Rect2(cx - w * 0.5, art.size.y - 30 - h, w, h), false)
			"weapon":
				for i in pics.size():                                    # a wall rack, the guns hung in rows
					var rw := 3.6 if i < 4 else 3.0
					var y := 24.0 + i * (art.size.y - 50.0) / pics.size()
					draw_rect(Rect2(20, y + 40, sz.x - 40, 3), Color(col, 0.3))
					draw_texture_rect(pics[i], Rect2(cx - 12 * rw, y - 18, 24 * rw, 24 * rw), false)
			"feature", "belt":
				_plinth(Vector2(cx, art.size.y - 18), sz.x * 0.4)
				var n := pics.size()
				for i2 in n:
					var sc := 3.4
					var px := sz.x * (0.15 + 0.7 * (float(i2) + 0.5) / n) - 12 * sc
					var py := art.size.y - 30 - 24 * sc - (14.0 if i2 % 2 == 0 else 0.0)
					draw_texture_rect(pics[i2], Rect2(px, py, 24 * sc, 24 * sc), false)
			"group":
				_plinth(Vector2(cx, art.size.y - 18), sz.x * 0.42)
				if not suits.is_empty():
					var ns := suits.size()
					for i3 in ns:
						var sl := look.duplicate()
						sl["suit"] = String(suits[i3])
						var tx2 := ChibiArt.frame(sl, 0, 0)
						var h2 := art.size.y - 40.0
						var w2 := h2 * tx2.get_width() / tx2.get_height()
						draw_texture_rect(tx2, Rect2(sz.x * (float(i3) + 0.5) / ns - w2 * 0.5, art.size.y - 24 - h2, w2, h2), false)
				else:
					var n2 := pics.size()
					var sc2 := minf(4.0, (sz.x - 30.0) / (n2 * 26.0))
					for i4 in n2:
						var px2 := sz.x * (float(i4) + 0.5) / n2 - 12 * sc2
						draw_texture_rect(pics[i4], Rect2(px2, art.size.y - 30 - 24 * sc2, 24 * sc2, 24 * sc2), false)
		# the bar along the foot
		var by := sz.y - bar_h
		draw_rect(Rect2(0, by, sz.x, bar_h), Color(0.05, 0.05, 0.07, 0.96))
		draw_rect(Rect2(0, by, sz.x, 2), col if _hover and not dim else Color(col, 0.45))
		if icon_tex != null:
			draw_texture_rect(icon_tex, Rect2(8, by + 7, 32, 32), false)
		var font := get_theme_default_font()
		draw_string(font, Vector2(48, by + 21), title.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, sz.x - 56, 16, col.lightened(0.2))
		draw_string(font, Vector2(48, by + 38), line, HORIZONTAL_ALIGNMENT_LEFT, sz.x - 56, 11, Color(0.75, 0.75, 0.78))
		# the frame – lit when the mouse is over it
		draw_rect(Rect2(Vector2.ZERO, sz), col if _hover and not dim else Color(col, 0.4), false, 2.0 if _hover else 1.0)
		if dim:
			draw_rect(Rect2(Vector2.ZERO, sz), Color(0, 0, 0, 0.55))

	func _plinth(c: Vector2, r: float) -> void:
		var pts := PackedVector2Array()
		for a in 32:
			pts.append(c + Vector2(cos(a * TAU / 32.0) * r, sin(a * TAU / 32.0) * minf(r * 0.22, 22.0)))
		draw_colored_polygon(pts, Color(col, 0.22))
		pts.append(pts[0])
		draw_polyline(pts, Color(col, 0.8), 2.0)
