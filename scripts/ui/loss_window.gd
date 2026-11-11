extends CanvasLayer
## Package 31a: the ship is lost – the rebuild summary (0.5.31.5: tiles after Luz's sketch).
##   left, four tiles: the lost ship (rebuild price) · the respawn station · the crew (in the pod / lost) · losses
##   right: the costs (hull, modules, Insurance Agent), total, remaining balance, REBUILD and the starter ship
## Taking the starter ship asks once more. The pilot is already back at the last station docked at.
## 0.7.53.14 (Luz): the same window when you go down on foot (offer["foot"]) – the gear you wore and carried bought
## back for 10 % of its price (the lockers aboard do not count), or the basic kit.

signal closed

const COL := Color(1.0, 0.45, 0.35)
const ACC := Color(1.0, 0.62, 0.25)
const PilotArt = preload("res://scripts/core/pilot_art.gd")
var offer := {}
var root: VBoxContainer
var _confirm: Control


func _ready() -> void:
	add_to_group("kbd_menu")
	layer = 30
	visible = false
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.02, 0.88)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		m.add_theme_constant_override("margin_" + side, 70)
	for side2 in ["top", "bottom"]:
		m.add_theme_constant_override("margin_" + side2, 40)
	bg.add_child(m)
	root = UI.vbox(14)
	m.add_child(root)


func open(p_offer: Dictionary) -> void:
	offer = p_offer
	visible = true
	Audio.play("ui_error", "pilot down" if bool(offer.get("foot", false)) else "ship lost")
	_build()


func _foot() -> bool:
	return bool(offer.get("foot", false))


func _build() -> void:
	UI.clear(root)
	if offer.is_empty():
		return
	# header: title left, the commander right
	var head := UI.hbox(14)
	root.add_child(head)
	var tv := UI.vbox(0)
	head.add_child(tv)
	if _foot():
		tv.add_child(UI.label("YOU WENT DOWN  –  GEAR BUY-BACK", 28, COL))
		tv.add_child(UI.label("Flight time %s  •  you came to in %s" % [SaveGame.fmt_time(GameState.play_time), offer["where"]], 13, ACC))
	else:
		tv.add_child(UI.label("SHIP LOST  –  REBUILD SUMMARY", 28, COL))
		tv.add_child(UI.label("Flight time %s  •  %s destroyed at %s" % [SaveGame.fmt_time(GameState.play_time), offer["name"], offer["where"]], 13, ACC))
	head.add_child(UI.spacer())
	var cv := UI.vbox(0)
	head.add_child(cv)
	var cn := UI.label("CMDR %s" % GameState.pilot_title(), 18, Color(0.95, 0.95, 1.0))
	cn.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cv.add_child(cn)
	var cr := UI.label(GameData.fmt_credits(GameState.credits), 14, UI.GOLD)
	cr.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cv.add_child(cr)
	var por := UI.icon(PilotArt.portrait(GameState.pilot.get("look", {})), 56)
	head.add_child(por)
	var line := ColorRect.new()
	line.color = Color(ACC, 0.5)
	line.custom_minimum_size = Vector2(0, 2)
	root.add_child(line)
	# body
	var body := UI.hbox(24)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.size_flags_stretch_ratio = 2.0
	body.add_child(grid)
	if _foot():
		_gear_tile(grid)
		_wake_tile(grid)
		_locker_tile(grid)
		_carried_tile(grid)
	else:
		_ship_tile(grid)
		_place_tile(grid)
		_crew_tile(grid)
		_loss_tile(grid)
	_costs(body)
	_confirm = null


## A tile: a frame with a coloured top line, a content box and a caption bar below.
func _tile(parent: Control, col: Color, caption: String, sub: String, strong: bool) -> VBoxContainer:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(col.darkened(0.55), 0.9) if strong else Color(0.06, 0.06, 0.09, 0.95)
	sb.border_color = Color(col, 0.9 if strong else 0.4)
	sb.set_border_width_all(1)
	sb.border_width_top = 4
	p.add_theme_stylebox_override("panel", sb)
	parent.add_child(p)
	var v := UI.vbox(4)
	p.add_child(v)
	var content := UI.vbox(4)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var pad := MarginContainer.new()
	pad.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top"]:
		pad.add_theme_constant_override("margin_" + side, 14)
	pad.add_child(content)
	v.add_child(pad)
	var bar := PanelContainer.new()
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color(col, 0.28 if strong else 0.12)
	bar.add_theme_stylebox_override("panel", bs)
	v.add_child(bar)
	var bv := UI.vbox(0)
	bar.add_child(bv)
	var c := UI.label(caption, 16, Color(1, 1, 1) if strong else Color(col, 0.95))
	c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bv.add_child(c)
	if sub != "":
		var s := UI.label(sub, 14, UI.GOLD if strong else UI.TEXT_DIM)
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bv.add_child(s)
	return content


func _big_pic(parent: Control, tex: Texture2D) -> void:
	var r := TextureRect.new()
	r.texture = tex
	r.size_flags_vertical = Control.SIZE_EXPAND_FILL
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.custom_minimum_size = Vector2(0, 90)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(r)


func _ship_tile(grid: Control) -> void:
	var h: Dictionary = GameData.hulls.get(String(offer.get("hull", "dragonfly")), {})
	var v := _tile(grid, ACC, "REBUILD THE SHIP", GameData.fmt_credits(int(offer["price"])), true)
	v.add_child(UI.label("%s %s" % [h.get("class", ""), h.get("name", "")], 15, Color(1, 0.95, 0.85)))
	v.add_child(UI.label(String(offer["name"]), 13, Color(1.0, 0.85, 0.6)))
	_big_pic(v, PixelArt.ship_texture(String(offer.get("hull", "dragonfly")), "player"))
	v.add_child(UI.label("MODULES %d   •   DRONES %d" % [int(offer.get("modules_n", 0)), int(offer.get("drones_n", 0))], 13, Color(1, 0.9, 0.75)))


func _place_tile(grid: Control) -> void:
	var st := Universe.find_station(int(offer.get("station_system", GameState.current_system)), String(offer.get("station", "")))
	var sys_name := String(Universe.systems[int(offer.get("station_system", GameState.current_system))]["name"])
	var v := _tile(grid, Color(0.45, 0.75, 1.0), "RESPAWN LOCATION", String(st.get("name", "?")), false)
	v.add_child(UI.label(sys_name.to_upper(), 15, Color(0.85, 0.9, 1.0)))
	v.add_child(UI.label(String(st.get("name", "")), 13, UI.TEXT_DIM))
	if not st.is_empty():
		_big_pic(v, StationArt.build(st)["texture"])
	v.add_child(UI.wrap_label("The last station you docked at – you are here now, in the Dragonfly »Second Chance«.", 12, UI.TEXT_DIM, 380))


func _crew_tile(grid: Control) -> void:
	var alive: Array = offer.get("alive_info", [])
	var dead: Array = offer.get("dead_info", [])
	var v := _tile(grid, Color(0.55, 1.0, 0.6), "CREW", "%d in the escape pod  •  %d lost" % [alive.size(), dead.size()] if alive.size() + dead.size() > 0 else "no crew aboard", false)
	if alive.is_empty() and dead.is_empty():
		v.add_child(UI.label("You flew alone.", 13, UI.TEXT_DIM))
		return
	for a in alive:
		v.add_child(UI.wrap_label("✚ %s  (%s, %s) – pod signal %d:%02d" % [a[0], a[2], a[1], int(a[3]) / 60, int(a[3]) % 60], 13, UI.GOOD, 380))
	for d in dead:
		v.add_child(UI.wrap_label("✖ %s  (%s, %s) – did not make it" % [d[0], d[2], d[1]], 13, UI.BAD, 380))
	if not alive.is_empty():
		v.add_child(UI.wrap_label("The pod drifts at the wreck – warp to it from the overview of that system and fly close to take it aboard.", 12, UI.TEXT_DIM, 380))


func _loss_tile(grid: Control) -> void:
	var cargo: Dictionary = offer.get("cargo", {})
	var insured := bool(offer.get("insured", false))
	var cv := int(offer.get("cargo_value", 0))
	var v := _tile(grid, Color(1.0, 0.85, 0.35), "CARGO & LOSSES", ("insured – comes back with the ship" if insured else "cargo lost: %s" % GameData.fmt_credits(cv)) if not cargo.is_empty() else "the hold was empty", false)
	if cargo.is_empty():
		v.add_child(UI.label("Nothing in the hold.", 13, UI.TEXT_DIM))
	var n := 0
	for item in cargo:
		if n >= 7:
			v.add_child(UI.label("… and %d more" % (cargo.size() - n), 12, UI.TEXT_DIM))
			break
		v.add_child(UI.label("%s ×%s" % [GameData.item_name(String(item)), str(snappedf(float(cargo[item]), 0.1))], 13, UI.GOOD if insured else Color(1.0, 0.75, 0.6)))
		n += 1
	if insured:
		v.add_child(UI.wrap_label("★ Cargo Insurance aboard – rebuilt, the ship brings the whole hold back.", 12, UI.GOLD, 380))
	v.add_child(UI.wrap_label("If you take the starter ship instead, ship, modules, drones and cargo are gone.", 12, UI.TEXT_DIM, 380))


# ---------------------------------------------------------------- 0.7.53.14: down on foot

func _gear_tile(grid: Control) -> void:
	var v := _tile(grid, ACC, "BUY BACK YOUR GEAR", GameData.fmt_credits(int(offer["price"])), true)
	var sid := String(offer.get("suit", "suit_civil:F"))
	v.add_child(UI.label(ChibiArt.GearData.display_name(sid), 15, Color(1, 0.95, 0.85)))
	var look: Dictionary = (GameState.pilot.get("look", PilotArt.default_look()) as Dictionary).duplicate()
	look["suit"] = ChibiArt.GearData.family(sid)
	look["helmet"] = true
	_big_pic(v, ChibiArt.frame(look, 0, 0))
	v.add_child(UI.label("WORTH %s   •   %d PIECES" % [GameData.fmt_credits(int(offer.get("value", 0))), (offer.get("items", []) as Array).size()], 13, Color(1, 0.9, 0.75)))


func _wake_tile(grid: Control) -> void:
	var v := _tile(grid, Color(0.45, 0.75, 1.0), "WAKE-UP LOCATION", String(offer.get("where", "?")), false)
	v.add_child(UI.label(String(Universe.systems[GameState.current_system]["name"]).to_upper() if GameState.current_system >= 0 and GameState.current_system < Universe.systems.size() else "", 15, Color(0.85, 0.9, 1.0)))
	v.add_child(UI.label(String(offer.get("where", "")), 13, UI.TEXT_DIM))
	v.add_child(UI.wrap_label(String(offer.get("wake", "")), 12, UI.TEXT_DIM, 380))
	v.add_child(UI.wrap_label("Until you decide you wear the basic kit: a Civilian Spacesuit · F, a Laser Pistol · F, two medkits and an energy cell.", 12, UI.TEXT_DIM, 380))


func _locker_tile(grid: Control) -> void:
	var n := 0
	for k in GameState.gear.lockers:
		for p in GameState.gear.lockers[k]:
			if not (p as Dictionary).is_empty():
				n += 1
	var v := _tile(grid, Color(0.55, 1.0, 0.6), "LOCKER", "%d places in use – safe aboard" % n if n > 0 else "empty", false)
	v.add_child(UI.wrap_label("What lies in your ship's locker was never with you – it stays yours and is not part of the price.", 13, UI.GOOD, 380))


func _carried_tile(grid: Control) -> void:
	var items: Array = offer.get("items", [])
	var v := _tile(grid, Color(1.0, 0.85, 0.35), "WORN & CARRIED", "%d pieces" % items.size(), false)
	var n := 0
	for it in items:
		if n >= 8:
			v.add_child(UI.label("… and %d more" % (items.size() - n), 12, UI.TEXT_DIM))
			break
		var r := UI.hbox(8)
		v.add_child(r)
		r.add_child(UI.label(String(it[0]), 13, Color(1.0, 0.75, 0.6)))
		r.add_child(UI.spacer())
		r.add_child(UI.label(GameData.fmt_credits(int(it[1])), 13, UI.TEXT_DIM))
		n += 1
	v.add_child(UI.wrap_label("If you take the basic kit instead, all of this is gone.", 12, UI.TEXT_DIM, 380))


func _costs(body: Control) -> void:
	var v := UI.vbox(10)
	v.custom_minimum_size = Vector2(400, 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(v)
	v.add_child(UI.label("BUY-BACK COSTS" if _foot() else "REBUILD COSTS", 22, Color(0.95, 0.95, 1.0)))
	_rule(v)
	if _foot():
		_cost_row(v, "SUIT (10 %)", int(offer.get("suit_cost", 0)), UI.TEXT_DIM, ACC)
		_cost_row(v, "WEAPONS, BELT, FEATURES, POCKETS (10 %)", int(offer.get("rest_cost", 0)), UI.TEXT_DIM, ACC)
		v.add_child(UI.wrap_label("The locker aboard your ship is not counted.", 12, UI.TEXT_DIM, 380))
	else:
		_cost_row(v, "HULL (10 %)", int(offer.get("hull_cost", 0)), UI.TEXT_DIM, ACC)
		_cost_row(v, "MODULES AND DRONES (10 %)", int(offer.get("modules_cost", 0)), UI.TEXT_DIM, ACC)
		if bool(offer.get("agent", false)):
			v.add_child(UI.label("★ Insurance Agent aboard – 5 % off, already counted", 12, UI.GOLD))
		v.add_child(UI.wrap_label("Crew is not part of the price – they come back from the pod.", 12, UI.TEXT_DIM, 380))
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp)
	_rule(v)
	var price := int(offer["price"])
	_cost_row(v, "TOTAL TO PAY", price, Color(0.95, 0.95, 1.0), ACC, 22)
	_rule(v)
	var rest := GameState.credits - price
	_cost_row(v, "REMAINING BALANCE", rest, Color(0.95, 0.95, 1.0), ACC if rest >= 0 else UI.BAD, 15)
	_rule(v)
	var b1 := _big_button("BUY BACK" if _foot() else "REBUILD", ACC, func(): _decide(true))
	b1.disabled = rest < 0
	if rest < 0:
		b1.tooltip_text = "Not enough credits."
		v.add_child(UI.label("Not enough credits to buy it back." if _foot() else "Not enough credits to rebuild.", 13, UI.BAD))
	v.add_child(b1)
	v.add_child(_big_button("TAKE THE BASIC KIT" if _foot() else "TAKE THE STARTER SHIP", Color(0.6, 0.62, 0.7), _ask_starter))


func _rule(v: Control) -> void:
	var r := ColorRect.new()
	r.color = Color(1, 1, 1, 0.15)
	r.custom_minimum_size = Vector2(0, 1)
	v.add_child(r)


func _cost_row(v: Control, label: String, value: int, lc: Color, vc: Color, size: int = 14) -> void:
	var r := UI.hbox(8)
	v.add_child(r)
	r.add_child(UI.label(label, size, lc))
	r.add_child(UI.spacer())
	r.add_child(UI.label(GameData.fmt_credits(value), size, vc))


func _big_button(text: String, col: Color, cb: Callable) -> Button:
	var b := UI.button(text, cb)
	b.custom_minimum_size = Vector2(0, 52)
	b.add_theme_font_size_override("font_size", 18)
	b.add_theme_color_override("font_color", col)
	for st in ["normal", "hover", "pressed", "disabled"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(col.darkened(0.7), 0.95 if st != "hover" else 1.0)
		if st == "hover":
			sb.bg_color = Color(col.darkened(0.45), 1.0)
		sb.border_color = Color(col, 0.7 if st != "disabled" else 0.2)
		sb.set_border_width_all(1)
		sb.content_margin_left = 22
		sb.content_margin_right = 22
		b.add_theme_stylebox_override(st, sb)
	return b


## The starter ship: one more question before the old ship is gone for good.
func _ask_starter() -> void:
	if _confirm != null and is_instance_valid(_confirm):
		return
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.6)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	get_child(0).add_child(shade)
	_confirm = shade
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.add_child(c)
	var p := UI.neon_panel(COL, Color(0.08, 0.03, 0.03, 0.98))
	p.custom_minimum_size = Vector2(560, 0)
	c.add_child(p)
	var v := UI.vbox(12)
	p.add_child(v)
	v.add_child(UI.label("ARE YOU SURE?", 22, COL))
	if _foot():
		v.add_child(UI.wrap_label("You keep the basic kit. Your %s, your weapons and everything you carried are gone for good – Aegis Mutual will not ask again." % ChibiArt.GearData.display_name(String(offer.get("suit", ""))), 14, Color(0.95, 0.9, 0.9), 520))
	else:
		v.add_child(UI.wrap_label("You keep the Dragonfly »Second Chance«. The %s with all its modules, drones and cargo is gone for good – Aegis Mutual will not ask again." % offer["name"], 14, Color(0.95, 0.9, 0.9), 520))
	var r := UI.hbox(12)
	v.add_child(r)
	r.add_child(_big_button("YES, TAKE THE BASIC KIT" if _foot() else "YES, TAKE THE STARTER SHIP", COL, func(): _decide(false)))
	r.add_child(_big_button("BACK", Color(0.8, 0.85, 0.95), func():
		shade.queue_free()
		_confirm = null))


func _decide(accept: bool) -> void:
	var e := Commands.execute({"type": "fall_decide" if _foot() else "loss_decide", "accept": accept})
	if e != "":
		_build()
		return
	visible = false
	closed.emit()


## Q / E do nothing here – a decision is needed.
func menu_tab(_step: int) -> void:
	pass
