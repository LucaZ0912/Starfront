extends StationServicePanel
## Bulletin board (BlackLedger Contracts): accept contracts, turn them in, abandon them.

const FactionData = preload("res://data/factions.gd")
const TYPE_LABELS := {"courier": "COURIER", "bounty": "BOUNTY", "mining": "SUPPLY", "survey": "SURVEY",
	"escort": "ESCORT", "patrol": "PATROL", "hunt": "HUNT", "smuggler": "INTERCEPT", "passenger": "PASSENGERS"}
const TYPE_COLORS := {"courier": Color(0.4, 0.85, 1.0), "bounty": Color(1.0, 0.35, 0.35), "mining": Color(1.0, 0.75, 0.3), "survey": Color(0.8, 0.5, 1.0),
	"escort": Color(0.45, 1.0, 0.6), "patrol": Color(0.5, 0.75, 1.0), "hunt": Color(1.0, 0.25, 0.25), "smuggler": Color(0.75, 0.45, 1.0),
	"passenger": Color(0.95, 0.85, 0.6)}
## Board tab: 0 = contracts, 1 = passenger transport (package 25c)
static var tab := 0


func build() -> void:
	UI.clear(self)
	var tabs := UI.hbox(6)
	add_child(tabs)
	for i in 2:
		var ti := i
		var b := UI.button(["Contracts (%d / %d)" % [GameState.contract_count(), GameState.MAX_ACTIVE_MISSIONS],
			"Passengers (%d / %d)" % [GameState.passenger_count(), Missions.MAX_PASSENGER_JOBS]][i], func(): _set_tab(ti))
		b.toggle_mode = true
		b.button_pressed = tab == i
		tabs.add_child(b)
	if tab == 1:
		_build_passengers()
		return
	var f := fit()
	section("YOUR CONTRACTS (%d / %d)" % [GameState.contract_count(), GameState.MAX_ACTIVE_MISSIONS])
	if GameState.contract_count() == 0:
		add_child(UI.label("No active contracts.", 13, UI.TEXT_DIM))
	for m in GameState.missions:
		if String(m["type"]) == "passenger":
			continue
		var mm: Dictionary = m
		var can := f != null and Missions.can_turn_in(mm, f, station["id"])
		var row := _card(mm, Missions.progress_text(mm, f))
		if can:
			row.add_child(UI.button("Turn in", func(): _turn_in(mm)))
		var ab := UI.button("Abandon", func(): _abandon(mm))
		row.add_child(ab)
	add_child(HSeparator.new())
	section("OPEN CONTRACTS ON THIS BOARD")
	var sf := String(station.get("faction", ""))
	var closed: String = GameState.rep.contracts_error(sf)
	if closed != "":
		add_child(UI.label(closed, 14, UI.BAD))
		return
	var bonus: float = GameState.rep.contract_bonus(sf)
	if bonus > 0.0:
		add_child(UI.label("Standing with the %s: %s – contracts from this station pay +%d %%." % [FactionData.name_of(sf), GameState.rep.tier_name(sf), int(round(bonus * 100.0))], 13, GameState.rep.tier(sf)["color"]))
	for m in GameState.offers_for(GameState.current_system, station):
		var mm: Dictionary = m
		var row := _card(mm, "Client: %s" % mm["client"] + (("   •   for the %s" % FactionData.short_of(String(mm.get("faction", "")))) if String(mm.get("faction", "")) != "" else ""), bonus)
		row.add_child(UI.button("Accept", func(): _accept(mm)))
	_faction_jobs()


func _set_tab(i: int) -> void:
	tab = i
	build()


## Passenger transport (package 25c): your groups aboard, your cabins, the station's offers.
func _build_passengers() -> void:
	var f := fit()
	section("PASSENGERS ABOARD (%d / %d groups)" % [GameState.passenger_count(), Missions.MAX_PASSENGER_JOBS])
	if GameState.passenger_count() == 0:
		add_child(UI.label("No passengers aboard.", 13, UI.TEXT_DIM))
	for m in GameState.missions:
		if String(m["type"]) != "passenger":
			continue
		var mm: Dictionary = m
		var row := _card(mm, Missions.progress_text(mm, f))
		if f != null and Missions.can_turn_in(mm, f, station["id"]):
			row.add_child(UI.button("Disembark", func(): _turn_in(mm)))
		row.add_child(UI.button("Abandon", func(): _abandon(mm)))
	add_child(HSeparator.new())
	section("TRANSPORT CONTRACTS")
	var sf := String(station.get("faction", ""))
	var closed: String = GameState.rep.contracts_error(sf)
	if closed != "":
		add_child(UI.label(closed, 14, UI.BAD))
		return
	if f != null:
		add_child(UI.label("%s – cabins: %s" % [f.ship_name, Missions.cabins_text(f)], 13, Color(0.95, 0.88, 0.65)))
		var lp := float(f.hull().get("luxury_pay", 1.0))
		if lp != 1.0:
			add_child(UI.label("%s: luxury contracts pay %+d %%." % [f.hull()["name"], int(round((lp - 1.0) * 100.0))], 13, UI.GOLD if lp > 1.0 else UI.TEXT_DIM))
	add_child(UI.label("Pay per passenger and jump: bulk %d cr, business %d cr, luxury %d cr. Late or lost passengers cost standing with the %s." % [
		int(Missions.CABIN_CLASSES["bulk"]["pay"]), int(Missions.CABIN_CLASSES["business"]["pay"]), int(Missions.CABIN_CLASSES["luxury"]["pay"]),
		FactionData.short_of(sf) if sf != "" else "station"], 12, UI.TEXT_DIM))
	var bonus: float = GameState.rep.contract_bonus(sf)
	for m in GameState.passenger_offers_for(GameState.current_system, station):
		var mm: Dictionary = m
		var why := Missions.cabin_error(f, mm)
		var cls: Dictionary = Missions.CABIN_CLASSES[String(mm["cabin"])]
		var row := _card(mm, "%s   •   %d:%02d to get there%s" % [cls["name"], int(mm["time_limit"]) / 60, int(mm["time_limit"]) % 60, ("   •   " + why) if why != "" else ""],
			bonus + Missions.pay_mult(f, mm) - 1.0)
		var b := UI.button("Accept", func(): _accept(mm), why)
		b.disabled = why != ""
		row.add_child(b)


func _card(m: Dictionary, extra: String, bonus: float = 0.0) -> HBoxContainer:
	var col: Color = TYPE_COLORS.get(m["type"], Color.WHITE)
	if String(m["type"]) == "passenger":
		col = Missions.CABIN_CLASSES[String(m["cabin"])]["color"]
	var box := UI.neon_panel(Color(col, 0.45), Color(0.04, 0.04, 0.09, 0.9), 1)
	add_child(box)
	var row := UI.hbox(14)
	box.add_child(row)
	var tag := UI.label(TYPE_LABELS.get(m["type"], "?"), 13, col)
	tag.custom_minimum_size = Vector2(80, 0)
	row.add_child(tag)
	var info := UI.vbox(1)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	info.add_child(UI.label(m["title"], 15, Color(0.95, 0.96, 1.0)))
	info.add_child(UI.wrap_label(m["desc"], 12, UI.TEXT_DIM, 620))
	info.add_child(UI.label(extra, 12, col))
	row.add_child(UI.label(GameData.fmt_credits(int(round(float(m["reward"]) * (1.0 + bonus)))), 16, UI.GOLD))
	return row


func _accept(m: Dictionary) -> void:
	run({"type": "mission_accept", "id": m["id"]})


func _turn_in(m: Dictionary) -> void:
	run({"type": "mission_turn_in", "id": m["id"]})


func _abandon(m: Dictionary) -> void:
	run({"type": "mission_abandon", "id": m["id"]})


## Faction contracts of the station's government (package 17), below BlackLedger's board.
func _faction_jobs() -> void:
	var sf := String(station.get("faction", ""))
	if not sf in FactionData.POWERS:
		return
	add_child(HSeparator.new())
	var head := UI.hbox(8)
	add_child(head)
	head.add_child(UI.icon(CrestArt.texture(sf), 26))
	head.add_child(UI.label("FACTION CONTRACTS – %s" % FactionData.name_of(sf).to_upper(), 16, FactionData.color_of(sf)))
	head.add_child(UI.label("your standing: %s" % GameState.rep.tier_name(sf), 13, GameState.rep.tier(sf)["color"]))
	add_child(UI.label("Issued by the government itself – they need standing and raise it more than ordinary work (+%.0f)." % Missions.FACTION_REP, 12, UI.TEXT_DIM))
	var bonus: float = GameState.rep.contract_bonus(sf)
	for m in GameState.faction_offers_for(GameState.current_system, station):
		var mm: Dictionary = m
		var why: String = GameState.faction_job_error(mm)
		var row := _card(mm, "Needs %s standing" % Missions.TIER_NAMES.get(String(mm["min_tier"]), "Neutral") + (("   •   " + why) if why != "" else ""), bonus)
		var b := UI.button("Accept", func(): _accept(mm), why)
		b.disabled = why != ""
		row.add_child(b)
