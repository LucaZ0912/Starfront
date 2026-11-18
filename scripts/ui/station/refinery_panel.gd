extends StationServicePanel
## Refinery (Crucible Metallurgy Combine): turns ore and ice in the cargo hold into refined material.
## Efficiency depends on the station type and the asteroid class (metallic / stony / icy).
## Luz, 18 Nov 2026: refining takes time (as fast as the Kanayama-maru's refinery, dearer goods longer); the goods
## wait at this station to be collected. The window: the refinery's yields and the hold on top; your ore as tiles on
## the left, the picked kind on the right (ore → refined, yield, time, fee, its worth here); a tab "In production"
## with the job running now, the queue, and what is ready to collect.

const Kit = preload("res://scripts/ui/station/svc_kit.gd")

static var tab := "refine"
static var pick := ""


func build() -> void:
	UI.clear(self)
	if no_ship():
		return
	var f := fit()
	var col := corp_color()
	var sid := String(station["id"])
	var n_jobs: int = GameState.jobs_at(sid, "refinery").size()
	var n_ready: int = GameState.jobs_ready(sid, "refinery").size()
	var trow := UI.hbox(14)
	add_child(trow)
	Kit.chips(trow, [["refine", "Refine"], ["prod", "In production (%d)%s" % [n_jobs, ("  •  %d ready" % n_ready) if n_ready > 0 else ""]]], tab, col, func(id): tab = id; refresh_all())
	trow.add_child(UI.spacer())
	Kit.cargo_bar(trow, f)
	var h := _body_h()
	if tab == "prod":
		Kit.production(self, sid, "refinery", col, func(cmd): run(cmd), h + 52.0)
		return
	# the refinery's yields
	var eff := UI.hbox(22)
	add_child(eff)
	eff.add_child(UI.label("THIS REFINERY", 12, UI.TEXT_DIM))
	for cls in ["metallic", "stony", "icy"]:
		var y := Industry.refinery_yield(station, cls)
		var g := UI.vbox(2)
		g.custom_minimum_size = Vector2(140, 0)
		eff.add_child(g)
		g.add_child(UI.label(("%s %d %%" % [GameData.CLASS_NAMES[cls], int(y * 100.0)]) if y > 0.0 else "%s: not here" % GameData.CLASS_NAMES[cls], 12, col if y > 0.0 else UI.TEXT_DIM))
		var b := UI.bar(col, 140)
		b.max_value = 1.0
		b.value = y
		b.custom_minimum_size = Vector2(140, 6)
		g.add_child(b)
	var note := UI.label("Mining colonies refine metallic and stony ore best; agricultural stations only process ice.", 12, UI.TEXT_DIM)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eff.add_child(note)
	# your ore
	var ores: Array = []
	for ore in Industry.ores():
		if floorf(float(f.cargo.get(ore, 0.0))) >= 1.0:
			ores.append(ore)
	ores.sort_custom(func(a, b): return Industry.ore_yield(station, a) > 0.0 and Industry.ore_yield(station, b) <= 0.0)
	if not pick in ores:
		pick = ores[0] if not ores.is_empty() else ""
	var main := UI.hbox(12)
	add_child(main)
	if ores.is_empty():
		var e := UI.neon_panel(Color(col, 0.4), Color(0.02, 0.02, 0.05, 0.6), 1)
		e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		e.custom_minimum_size = Vector2(0, h)
		main.add_child(e)
		var ev := UI.vbox(12)
		ev.alignment = BoxContainer.ALIGNMENT_CENTER
		e.add_child(ev)
		var ic := UI.icon(PixelArt.asteroid_texture(7, 18, "iron_ore"), 96)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		ev.add_child(ic)
		var t1 := UI.label("No ore or ice in your cargo hold.", 18, col)
		t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ev.add_child(t1)
		var t2 := UI.label("Mine asteroids with a mining laser (or buy ore at the market) and bring it here.", 13, UI.TEXT_DIM)
		t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ev.add_child(t2)
		if n_ready > 0:
			var cb := UI.button("%d job%s ready to collect: see In production" % [n_ready, "s" if n_ready > 1 else ""], func(): tab = "prod"; refresh_all())
			cb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			ev.add_child(cb)
		return
	var items: Array = []
	for ore in ores:
		var have := floorf(float(f.cargo.get(ore, 0.0)))
		var c: Dictionary = GameData.commodities[ore]
		var ok := Industry.ore_yield(station, ore) > 0.0
		var q := Industry.refine_quote(station, ore, have)
		items.append({"tex": PixelArt.asteroid_texture(7, 18, ore), "name": GameData.item_name(ore),
			"sub": ("%d → %.0f %s" % [int(have), float(q["out"]), GameData.item_name(String(q["out_id"]))]) if ok else "%d in hold" % int(have),
			"sub_col": UI.TEXT_DIM, "tag": GameData.CLASS_NAMES[c["class"]], "note": "" if ok else "not here", "dim": not ok})
	Kit.grid(main, items, ores.find(pick), col, func(i): pick = ores[i]; refresh_all(), h)
	_card(main, f, col, h, ores)


func _body_h() -> float:
	var sh := get_viewport().get_visible_rect().size.y
	return clampf(sh - 328.0 - maxf(sh - 720.0, 0.0) * 0.25, 200.0, 900.0)


func _card(parent: Control, f: ShipFitting, col: Color, h: float, ores: Array) -> void:
	var box := UI.neon_panel(Color(col, 0.7), Color(col.darkened(0.88), 0.85), 1)
	box.custom_minimum_size = Vector2(clampf(get_viewport().get_visible_rect().size.x * 0.28, 330.0, 480.0), h)
	parent.add_child(box)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(sc)
	var v := UI.vbox(10)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(v)
	var ore := pick
	var c: Dictionary = GameData.commodities[ore]
	var have := floorf(float(f.cargo.get(ore, 0.0)))
	var y := Industry.ore_yield(station, ore)
	v.add_child(UI.label(GameData.item_name(ore), 22, col))
	v.add_child(UI.label("%s  •  %s  •  base yield %.0f %% × this refinery %.0f %%" % [GameData.CLASS_NAMES[c["class"]], String(c["rarity"]).capitalize(),
		float(c["yield"]) * 100.0, Industry.refinery_yield(station, c["class"]) * 100.0], 12, UI.TEXT_DIM))
	if y <= 0.0:
		v.add_child(UI.label("This refinery cannot process %s ore. Try a mining colony or a trade hub." % GameData.CLASS_NAMES[c["class"]], 13, UI.BAD))
		return
	var q := Industry.refine_quote(station, ore, have)
	var out_id := String(q["out_id"])
	# ore → refined
	var conv := UI.neon_panel(Color(1, 1, 1, 0.1), Color(0, 0, 0, 0.35), 1)
	v.add_child(conv)
	var cr := UI.hbox(18)
	cr.alignment = BoxContainer.ALIGNMENT_CENTER
	conv.add_child(cr)
	cr.add_child(_side(UI.icon(PixelArt.asteroid_texture(7, 18, ore), 64), "%d" % int(have), GameData.item_name(ore), Color(0.9, 0.93, 1.0)))
	cr.add_child(UI.label("➜", 28, col))
	var ing := Kit.Ingot.new(Kit.good_color(out_id))
	ing.custom_minimum_size = Vector2(84, 64)
	cr.add_child(_side(ing, "%.0f" % float(q["out"]), GameData.item_name(out_id), UI.GOOD))
	var t := Industry.refine_time(ore, have)
	var worth := int(round(sell_price(Market.sell_price(station, out_id)) * float(q["out"]))) if Market.on_market(out_id) else 0
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 14)
	v.add_child(g)
	for kv in [["Yield", "%.0f %% of the ore" % (y * 100.0)], ["Time", "%s  (%s a unit)" % [Industry.fmt_secs(t), Industry.fmt_secs(t / maxf(have, 1.0)) if t / maxf(have, 1.0) >= 1.0 else "%.1f s" % (t / maxf(have, 1.0))]],
			["Fee", GameData.fmt_credits(int(q["fee"]))], ["Worth here", ("about %s" % GameData.fmt_credits(worth)) if worth > 0 else "not traded here"]]:
		g.add_child(UI.label(kv[0], 13, UI.TEXT_DIM))
		g.add_child(UI.label(kv[1], 13, UI.GOLD if kv[0] == "Fee" else Color(0.9, 0.93, 1.0)))
	var queued: int = GameState.jobs_at(String(station["id"]), "refinery").filter(func(j): return not bool(j.get("done", false))).size()
	if queued > 0:
		v.add_child(UI.label("%d job%s ahead in the queue." % [queued, "s" if queued > 1 else ""], 12, UI.TEXT_DIM))
	var b := UI.button("Refine all %d  (%s)" % [int(have), GameData.fmt_credits(int(q["fee"]))], func(): _refine(ore))
	b.disabled = GameState.credits < int(q["fee"]) or float(q["out"]) < 1.0
	v.add_child(b)
	var line := ColorRect.new()
	line.color = Color(1, 1, 1, 0.1)
	line.custom_minimum_size = Vector2(0, 1)
	v.add_child(line)
	var total_fee := 0
	var kinds := 0
	for o in ores:
		if Industry.ore_yield(station, o) > 0.0:
			total_fee += int(Industry.refine_quote(station, o, floorf(float(f.cargo.get(o, 0.0))))["fee"])
			kinds += 1
	var ab := UI.button("Refine everything this refinery can take: %d kind%s (%s)" % [kinds, "s" if kinds != 1 else "", GameData.fmt_credits(total_fee)], _refine_all)
	ab.disabled = kinds == 0 or GameState.credits < total_fee
	v.add_child(ab)
	v.add_child(UI.label("The refined goods wait here; collect them in the In production tab.", 11, UI.TEXT_DIM))


func _side(pic: Control, num: String, name: String, col: Color) -> VBoxContainer:
	var s := UI.vbox(2)
	pic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	s.add_child(pic)
	var n := UI.label(num, 20, col)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.add_child(n)
	var l := UI.label(name, 12, UI.TEXT_DIM)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.add_child(l)
	return s


var _tick := 0.0


## The In production tab follows the clock (a rebuild a second while it is shown).
func _process(delta: float) -> void:
	if tab != "prod" or not is_visible_in_tree():
		return
	_tick += delta
	if _tick >= 1.0:
		_tick = 0.0
		build()


## Q / E: the two tabs.
func menu_tab(_step: int) -> void:
	tab = "prod" if tab == "refine" else "refine"
	refresh_all()


func _refine(ore: String) -> void:
	run({"type": "refine", "ore": ore})


func _refine_all() -> void:
	for ore in Industry.ores():
		if floorf(float(fit().cargo.get(ore, 0.0))) >= 1.0 and Industry.ore_yield(station, ore) > 0.0:
			Commands.execute({"type": "refine", "ore": ore})
	refresh_all()
