extends StationServicePanel
## Package 39b: The Curia (Cathedral of Return, Heimkehr) – the Hierarch's edict in force with its blessing and its
## burden, tithes and the petition for the next edict, indulgences, and the relics of Earth.

const CuriaCore = preload("res://scripts/core/curia.gd")


func build() -> void:
	UI.clear(self)
	var cu = GameState.curia
	var col := corp_color()
	add_child(UI.wrap_label("The Hierarch proclaims, the Curia administers. An edict holds in all of the Covenant's territory until the next one is proclaimed.", 13, UI.TEXT_DIM, 1100))
	section("THE EDICT IN FORCE")
	if not cu.edict.is_empty():
		var bd: Dictionary = CuriaCore.EDICTS[cu.edict["id"]]
		var box := UI.neon_panel(Color(col, 0.7), Color(0.1, 0.03, 0.03, 0.95), 2)
		add_child(box)
		var v := UI.vbox(6)
		box.add_child(v)
		v.add_child(UI.label(String(bd["name"]).to_upper(), 18, col))
		v.add_child(UI.wrap_label("\"%s\"" % bd["text"], 13, Color(0.95, 0.9, 0.85), 1000))
		v.add_child(UI.label("Blessing:  %s   •   Burden:  %s" % [bd["pro"], bd["con"]], 13, UI.GOLD))
		v.add_child(UI.label("The next edict is proclaimed in about %d min." % cu.minutes_left(float(cu.edict["until"])), 13, UI.TEXT_DIM))
	# tithes and the petition
	section("TITHES")
	var row := UI.hbox(8)
	add_child(row)
	row.add_child(UI.label("Given this edict: %s  (petition from %s)" % [GameData.fmt_credits(int(cu.edict.get("tithed", 0))), GameData.fmt_credits(CuriaCore.PETITION)], 13))
	var tb := UI.button("Give a tithe (%s)" % GameData.fmt_credits(CuriaCore.TITHE_STEP), func(): run({"type": "curia_tithe"}))
	tb.disabled = GameState.credits < CuriaCore.TITHE_STEP
	row.add_child(tb)
	if cu.can_petition():
		var row2 := UI.hbox(8)
		add_child(row2)
		var pet := String(cu.edict.get("petition", ""))
		row2.add_child(UI.label("Petition the Hierarch for the next edict:" if pet == "" else "Your petition is heard – next: %s" % CuriaCore.EDICTS[pet]["name"], 13, UI.GOOD))
		for id in cu.edict.get("offer", []):
			var eid: String = id
			var pb := UI.button(String(CuriaCore.EDICTS[eid]["name"]), func(): run({"type": "curia_petition", "edict": eid}))
			pb.tooltip_text = "%s – %s" % [CuriaCore.EDICTS[eid]["pro"], CuriaCore.EDICTS[eid]["con"]]
			pb.toggle_mode = true
			pb.button_pressed = pet == eid
			row2.add_child(pb)
	# indulgence
	section("INDULGENCE")
	var cost: int = cu.indulgence_cost()
	var row3 := UI.hbox(8)
	add_child(row3)
	if cost <= 0:
		row3.add_child(UI.label("Your record with the Covenant is clean.", 13, UI.TEXT_DIM))
	else:
		row3.add_child(UI.label("Your crimes against the Covenant: %s. The Church forgives them all for %s." % [GameState.law.level_name("covenant"), GameData.fmt_credits(cost)], 13, UI.BAD))
		var ib := UI.button("Buy the indulgence", func(): run({"type": "curia_indulgence"}))
		ib.disabled = GameState.credits < cost
		row3.add_child(ib)
	# relics
	section("RELICS OF EARTH")
	var f := fit()
	var have := int(floor(float(f.cargo.get("earth_relic", 0.0)) + 0.001)) if f != null else 0
	var row4 := UI.hbox(8)
	add_child(row4)
	row4.add_child(UI.label("Relics aboard: %d   •   each: +%d standing and %d min of blessing (goods at Covenant stations −%d %%, sales +%d %%)" % [have, int(CuriaCore.RELIC_REP), int(CuriaCore.BLESSING_TIME / 60.0), int(round((1.0 - CuriaCore.BLESSING_BUY) * 100.0)), int(round((CuriaCore.BLESSING_SELL - 1.0) * 100.0))], 13))
	var rb := UI.button("Lay them in the cathedral", func(): run({"type": "curia_relics"}))
	rb.disabled = have <= 0
	row4.add_child(rb)
	if cu.blessed():
		add_child(UI.label("You are blessed – %d min left." % cu.minutes_left(float(cu.blessing_until)), 13, UI.GOOD))
	else:
		add_child(UI.label("Relics turn up in anomalies – analyse them anywhere in the Cluster.", 12, UI.TEXT_DIM))
