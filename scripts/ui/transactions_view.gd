extends VBoxContainer
## Package 56 (Luz): the transactions – your accepted contracts and the bond wallet – as a tab of the journal (Pilot
## window → Journal → Transactions); until 0.8.56.3 they were a tab of the ship menu. Builds itself; `rebuild()` anew.

static var sub_tab := 0           # 0 = contracts, 1 = bonds (kept while the window is rebuilt)
var _abandon_armed := ""
const FactionData = preload("res://data/factions.gd")
var fit: ShipFitting
var content: VBoxContainer


func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	content = self


func rebuild() -> void:
	fit = GameState.active()
	UI.clear(self)
	if fit == null:
		add_child(UI.label("No ship.", 13, UI.TEXT_DIM))
		return
	_build_transactions()


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
	# split screen (Luz): what the other player offers you to take with them
	for sm in GameState.shares_for(GameState.acting):
		var scol: Color = MISSION_COLORS.get(String(sm["type"]), Color.WHITE)
		var sp := UI.neon_panel(Color(UI.GOLD, 0.8), Color(0.09, 0.08, 0.04, 0.95), 1)
		sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_child(sp)
		var sv := UI.vbox(4)
		sp.add_child(sv)
		var sh := UI.hbox(10)
		sv.add_child(sh)
		sh.add_child(UI.label("OFFERED BY %s" % GameState.other_name().to_upper(), 13, UI.GOLD))
		sh.add_child(UI.label(MISSION_LABELS.get(String(sm["type"]), "?"), 13, scol))
		sh.add_child(UI.label(sm["title"], 16))
		sh.add_child(UI.spacer())
		sh.add_child(UI.label(GameData.fmt_credits(int(sm["reward"])), 16, UI.GOLD))
		sv.add_child(UI.wrap_label(sm.get("desc", ""), 13, UI.TEXT_DIM, 1100))
		sv.add_child(UI.wrap_label("Taken, it is one contract for both of you: what either of you does for it counts, and handed in it pays each of you in full.", 12, UI.TEXT_DIM, 1100))
		var srow := UI.hbox(8)
		sv.add_child(srow)
		srow.add_child(UI.spacer())
		var sid: String = sm["id"]
		srow.add_child(UI.button("Take it", func(): _share_do("mission_share_accept", sid)))
		srow.add_child(UI.button("No", func(): _share_do("mission_share_decline", sid)))
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
		if GameState.has_pilot2():                           # split screen (Luz): a contract can be shared with the other player
			if GameState.shared_with_other(m):
				row.add_child(UI.label("held with %s" % GameState.other_name(), 12, UI.GOLD))
			elif GameState.shares.any(func(shx): return is_same(shx["m"], m)):
				row.add_child(UI.label("offered to %s" % GameState.other_name(), 12, UI.TEXT_DIM))
			else:
				row.add_child(UI.button("Share with %s" % GameState.other_name(), func(): _share_do("mission_share", mid), "They can take it in their journal: one contract for both, each paid in full"))
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
		"Cleared by the Sable Writ Exchange [SWX]: \"Every head has a price.\"",
	])
	head.add_child(UI.wrap_label("Bounties are put out by the three powers, the one holding the system, in pirate space the nearest one, and paid as bonds. A bond is redeemed at the Bond Office of ANY station of the issuing faction. Bonds belong to you, survive the loss of your ship and never expire.", 13, UI.TEXT_DIM, 1100))
	var list := _card(box, "BONDS")
	var hdr := UI.hbox(12)
	list.add_child(hdr)
	for col in [["Issuer", 170], ["Target", 300], ["Amount", 120], ["Issued", 230], ["Redeem at", 300]]:
		var l := UI.label(col[0], 13, UI.ACCENT)
		l.custom_minimum_size = Vector2(col[1], 0)
		hdr.add_child(l)
	if GameState.bonds.is_empty():
		list.add_child(UI.label("No bonds yet: destroy wanted pirates (a Warrant Scanner shows who is wanted).", 13, UI.TEXT_DIM))
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


# ---------------------------------------------------------------- helpers (as the ship menu's)

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


## Split screen: a contract offered, taken or turned down (the commands' own words on why not go into the list).
func _share_do(cmd: String, id: String) -> void:
	var e: String = Commands.execute({"type": cmd, "id": id})
	if e != "":
		GameState.log_msg(e, GameState.COL_WARN)
		Audio.play("ui_error", "contract not shared")
	else:
		Audio.play("ui_click", "contract shared")
	rebuild()
