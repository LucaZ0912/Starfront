extends StationServicePanel
## Package 39a: The Senate (The Vote, Landfall) – the bill on the floor with its upside and its price, the polls, your
## vote, party donations and – for the brave – a bribe. Below: the laws in force and the last votes.

const SenateCore = preload("res://scripts/core/senate.gd")


func build() -> void:
	UI.clear(self)
	var sen = GameState.senate
	var col := corp_color()
	add_child(UI.wrap_label("Every citizen of the Assembly votes on every law. The ballots from all its systems come together here – a passed bill holds for an hour in all of the Assembly's territory.", 13, UI.TEXT_DIM, 1100))
	if not GameState.has_permit("assembly"):
		add_child(UI.label("You have no entry permit – you may watch, but not vote.", 13, UI.BAD))
	section("ON THE FLOOR")
	if sen.bill.is_empty():
		add_child(UI.label("No bill right now – the next one comes up in about %d min." % maxi(1, sen.minutes_left(float(sen.next_t))), 13, UI.TEXT_DIM))
	else:
		_bill_box(sen, col)
	section("LAWS IN FORCE")
	if sen.laws.is_empty():
		add_child(UI.label("None – the Assembly runs on its usual rules.", 13, UI.TEXT_DIM))
	for l in sen.laws:
		var bd: Dictionary = SenateCore.BILLS[l["id"]]
		add_child(UI.label("%s – %s; %s  (%d min left)" % [bd["name"], bd["pro"], bd["con"], sen.minutes_left(float(l["until"]))], 13, UI.GOOD))
	section("RECENT VOTES")
	if sen.history.is_empty():
		add_child(UI.label("No votes yet.", 13, UI.TEXT_DIM))
	for h in sen.history:
		var bd2: Dictionary = SenateCore.BILLS[h["id"]]
		add_child(UI.label("%s  %s – %s (%.0f %% yes)" % [SaveGame.fmt_time(float(h["t"])), bd2["name"], "passed" if h["passed"] else "rejected", float(h["yes"])], 12, UI.GOOD if h["passed"] else UI.TEXT_DIM))


func _bill_box(sen, col: Color) -> void:
	var b: Dictionary = sen.bill
	var bd: Dictionary = SenateCore.BILLS[b["id"]]
	var box := UI.neon_panel(Color(col, 0.7), Color(0.03, 0.05, 0.1, 0.95), 2)
	add_child(box)
	var v := UI.vbox(6)
	box.add_child(v)
	v.add_child(UI.label(String(bd["name"]).to_upper(), 18, col))
	v.add_child(UI.wrap_label(String(bd["text"]), 13, Color(0.9, 0.92, 1.0), 1000))
	v.add_child(UI.label("If it passes:  + %s   •   − %s   (for one hour)" % [bd["pro"], bd["con"]], 13, UI.GOLD))
	v.add_child(UI.label("The vote closes in %d min.   Polls: %d %% yes" % [sen.minutes_left(float(b["ends"])), int(round(sen.yes_chance() * 100.0))], 13))
	var bar := UI.bar(col, 520)
	bar.max_value = 1.0
	bar.value = sen.yes_chance()
	v.add_child(bar)
	var permit: bool = GameState.has_permit("assembly")
	# your vote
	var row := UI.hbox(8)
	v.add_child(row)
	row.add_child(UI.label("Your vote:", 13, UI.TEXT_DIM))
	for side in ["yes", "no"]:
		var sd: String = side
		var vb := UI.button(sd.to_upper(), func(): run({"type": "senate_vote", "side": sd}))
		vb.toggle_mode = true
		vb.button_pressed = String(b["vote"]) == sd
		vb.disabled = not permit
		row.add_child(vb)
	# donations
	var row2 := UI.hbox(8)
	v.add_child(row2)
	row2.add_child(UI.label("Party donation (%s – sways the vote a little, never for certain):" % GameData.fmt_credits(SenateCore.DONATION_STEP), 13, UI.TEXT_DIM))
	for side2 in ["yes", "no"]:
		var sd2: String = side2
		var db := UI.button("to the %s campaign (%s given)" % [sd2.to_upper(), GameData.fmt_credits(int(b["donated"].get(sd2, 0)))], func(): run({"type": "senate_donate", "side": sd2}))
		db.disabled = not permit or GameState.credits < SenateCore.DONATION_STEP
		row2.add_child(db)
	# the bribe
	var row3 := UI.hbox(8)
	v.add_child(row3)
	var br: Dictionary = b["bribe"]
	if br.is_empty():
		row3.add_child(UI.label("A quiet word with the tellers – %s, settles the vote … unless it comes out (%d %%: the money is gone, and so is the Assembly's trust):" % [GameData.fmt_credits(sen.bribe_cost()), int(SenateCore.BRIBE_CAUGHT * 100.0)], 13, UI.BAD))
		for side3 in ["yes", "no"]:
			var sd3: String = side3
			var bb := UI.button("Bribe for %s" % sd3.to_upper(), func(): run({"type": "senate_bribe", "side": sd3}))
			bb.disabled = not permit or GameState.credits < sen.bribe_cost()
			row3.add_child(bb)
	else:
		row3.add_child(UI.label("You have paid for a %s. Now hope nobody talks." % String(br["side"]).to_upper(), 13, UI.BAD))
