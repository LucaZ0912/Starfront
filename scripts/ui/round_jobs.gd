extends RefCounted
## (Luz, 24 Nov 2026) The window with the work of Ratte or Kraut in the Static Feedback: who offers it (portrait,
## name, how well you know each other), then the job in hand with what it asks and how it stands, or what is on
## offer now: each job a card with its kind, its system, its words and its pay. One job at a time.
## It is one of the ground's menus (GroundView._lift_menu): the number keys take a card, Esc closes, a controller
## moves through its buttons like through every menu on foot. No class_name: load it.

const KIND_COL := {"intel": Color(0.3, 0.9, 1.0), "smuggle": Color(0.55, 1.0, 0.6), "raid": Color(1.0, 0.45, 0.35)}
const KIND_TAG := {"intel": "INFORMATION", "smuggle": "DELIVERY", "raid": "RAID"}
const STAGE := {"go": "Not done yet", "deliver": "The crate is aboard: take it to the station", "back": "Done: your pay waits here"}


static func open(g, w, who: String) -> void:
	if g._lift_menu != null:
		g._close_lift_menu()
	Audio.play("ui_open", "the round: work")
	var Acq = load("res://data/acquaintances.gd")
	var chars: Dictionary = GameState.story.Data.CHARACTERS
	var col: Color = (chars.get(who, {}) as Dictionary).get("col", Color(1.0, 0.82, 0.35))
	var nm := String((chars.get(who, {}) as Dictionary).get("name", who))
	var c := CenterContainer.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	g._ui.add_child(c)
	var p := UI.neon_panel(Color(col, 0.85), Color(0.03, 0.04, 0.07, 0.97), 2)
	p.custom_minimum_size = Vector2(860, 0)
	c.add_child(p)
	var root := UI.hbox(18)
	p.add_child(root)
	# ---- who
	var left := UI.vbox(6)
	left.custom_minimum_size = Vector2(190, 0)
	root.add_child(left)
	var face := UI.icon(GameState.story.portrait_of(who), 176)
	left.add_child(face)
	left.add_child(UI.label(nm, 20, col))
	left.add_child(UI.wrap_label(String((chars.get(who, {}) as Dictionary).get("sub", "")), 12, UI.TEXT_DIM, 186))
	if Acq.met(who):
		var v: int = Acq.value(who)
		left.add_child(UI.label("", 4))
		left.add_child(UI.label(String(Acq.level_name(Acq.level(v))), 13, Color(1.0, 0.82, 0.35)))
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.min_value = 0.0
		bar.max_value = 100.0
		bar.value = clampf(float(v), 0.0, 100.0)
		bar.custom_minimum_size = Vector2(176, 8)
		left.add_child(bar)
		left.add_child(UI.wrap_label("Every job done for %s makes you better friends." % nm, 11, UI.TEXT_DIM, 186))
	# ---- the work
	var right := UI.vbox(8)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(right)
	right.add_child(UI.label("WORK FROM %s" % nm.to_upper(), 22, col))
	var keys: Array = []
	var j: Dictionary = w.rj()
	if not j.is_empty():
		var mine: bool = String(j["who"]) == who
		var jc: Color = KIND_COL.get(String(j["kind"]), col)
		var said := "\"One thing at a time. You carry somebody else's job.\"" if who == "ratte" else "\"Busy. Later.\""
		if mine and String(j["stage"]) == "back":
			said = "\"Ratte reads, Ratte pays. Come again.\"" if who == "ratte" else "\"Hm. Good.\""
		elif mine:
			said = "\"It still lies where Ratte said it lies.\"" if who == "ratte" else "\"Still there. Go.\""
		right.add_child(UI.wrap_label(said, 13, Color(0.88, 0.9, 0.96), 620))
		var card := _card(jc)
		right.add_child(card)
		var cv: VBoxContainer = card.get_child(0)
		var head := UI.hbox(10)
		cv.add_child(head)
		head.add_child(_tag("IN HAND", Color(1.0, 0.82, 0.35)))
		head.add_child(_tag(String(KIND_TAG[String(j["kind"])]), jc))
		head.add_child(UI.label(String(Universe.systems[int(j["sys"])]["name"]), 14, Color.WHITE))
		head.add_child(UI.spacer())
		head.add_child(UI.label(GameData.fmt_credits(int(j["pay"])), 15, Color(1.0, 0.86, 0.45)))
		cv.add_child(UI.wrap_label(String(j["brief"]), 12, Color(0.8, 0.84, 0.92), 600))
		cv.add_child(UI.label("%s  ·  from %s" % [String(STAGE.get(String(j["stage"]), "")), String((chars.get(String(j["who"]), {}) as Dictionary).get("name", "?"))], 12,
			Color(0.55, 1.0, 0.6) if String(j["stage"]) == "back" else UI.TEXT_DIM))
		if mine:
			var row := UI.hbox(8)
			cv.add_child(row)
			if String(j["stage"]) == "back":
				var take := func():
					w._rj_pay()
					Audio.play("buy", "the round: paid")
					open(g, w, who)
				row.add_child(UI.button("1.  Take your pay: %s" % GameData.fmt_credits(int(j["pay"])), take))
				keys.append(take)
			else:
				var drop := func():
					w.rj_drop()
					open(g, w, who)
				row.add_child(UI.button("1.  Let the job go", drop))
				keys.append(drop)
	else:
		right.add_child(UI.wrap_label("\"Somebody wants something read, somebody wants something moved. You fly, Ratte splits. Pick one.\"" if who == "ratte"
			else "\"Ships. Too much cargo. Too few guns.\" Kraut pushes a slate across the table.", 13, Color(0.88, 0.9, 0.96), 620))
		var offers: Array = w.rj_offers(who)
		if offers.is_empty():
			right.add_child(UI.label("Nothing on offer just now.", 13, UI.TEXT_DIM))
		for i in offers.size():
			var o: Dictionary = offers[i]
			var oc: Color = KIND_COL.get(String(o["kind"]), col)
			var card2 := _card(oc)
			right.add_child(card2)
			var ov: VBoxContainer = card2.get_child(0)
			var h2 := UI.hbox(10)
			ov.add_child(h2)
			h2.add_child(_tag(String(KIND_TAG[String(o["kind"])]), oc))
			h2.add_child(UI.label(String(Universe.systems[int(o["sys"])]["name"]), 14, Color.WHITE))
			h2.add_child(UI.spacer())
			h2.add_child(UI.label(GameData.fmt_credits(int(o["pay"])), 15, Color(1.0, 0.86, 0.45)))
			ov.add_child(UI.wrap_label(String(o["brief"]), 12, Color(0.8, 0.84, 0.92), 600))
			var take2 := func():
				w.rj_take(o)
				Audio.play("ui_open", "the round: a job taken")
				g._close_lift_menu()
				g._say_toast("%s: marked in %s. It is in your journal." % [String(w.RJ_KINDS[String(o["kind"])]), String(Universe.systems[int(o["sys"])]["name"])], 5.0)
			ov.add_child(UI.button("%d.  Take it" % (i + 1), take2))
			keys.append(take2)
		right.add_child(UI.label("One job at a time. New offers come round every twenty minutes.", 11, UI.TEXT_DIM))
	right.add_child(UI.button("Close [Esc]", g._close_lift_menu))
	g._lift_menu = c
	g._lift_menu.set_meta("zone", {})
	g._lift_menu.set_meta("keys", keys)
	g._lift_menu.set_meta("on_back", Callable())
	g._lift_menu.set_meta("round_jobs", who)


## A card: a dark panel with a coloured edge, a column inside.
static func _card(col: Color) -> PanelContainer:
	var card := UI.panel(Color(0.05, 0.07, 0.11))
	var st := UI.panel_style(Color(0.05, 0.07, 0.11), Color(col, 0.6))
	st.set_corner_radius_all(3)
	st.content_margin_left = 10
	st.content_margin_right = 10
	st.content_margin_top = 8
	st.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", st)
	card.add_child(UI.vbox(5))
	return card


## A small coloured tag with dark letters.
static func _tag(text: String, col: Color) -> Label:
	var l := UI.label(" %s " % text, 11, Color(0.03, 0.04, 0.07))
	var st := StyleBoxFlat.new()
	st.bg_color = col
	st.set_corner_radius_all(3)
	l.add_theme_stylebox_override("normal", st)
	return l
