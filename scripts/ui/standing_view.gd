extends RefCounted
## The standing towards every faction (phase 0.5 package 12) – since 0.5.30.5 shown in the Pilot window
## (Pilot → Standings); it used to be a tab of the ship menu.

const FactionData = preload("res://data/factions.gd")


static func build(box: Control) -> void:
	box.add_child(UI.wrap_label("Every faction keeps a standing towards you from −100 to +100. Bounty bonds and contracts raise it; attacking its ships lowers it. Contracts aimed at another faction cost standing with that faction. Prices, docking, patrols, contracts and military gear depend on it.", 13, UI.TEXT_DIM, 1100))
	box.add_child(UI.wrap_label("The powers also keep a criminal record: firing in no-fire zones, attacking or interdicting civilians and patrols in their space make you a Suspect (patrols attack), Wanted (no contracts) or Most Wanted (no docking). Points fade over time or are cleared by paying the fine at a Bond Office.", 13, UI.TEXT_DIM, 1100))
	var tiers := UI.hbox(14)
	box.add_child(tiers)
	for t in GameState.rep.tiers():
		tiers.add_child(UI.label("%s ≥ %+d" % [t["name"], int(t["min"])] if int(t["min"]) > -100 else "%s" % t["name"], 12, t["color"]))
	for group in [["THE POWERS", FactionData.POWERS], ["PIRATE FACTIONS", FactionData.PIRATES]]:
		box.add_child(UI.label(group[0], 15, UI.NEON_CYAN))
		for fid in group[1]:
			_standing_row(box, fid)


static func _standing_row(parent: Control, fid: String) -> void:
	var fd: Dictionary = FactionData.FACTIONS[fid]
	var v: float = GameState.rep.get_rep(fid)
	var t: Dictionary = GameState.rep.tier(fid)
	var p := UI.neon_panel(Color(fd["color"], 0.45), Color(0.05, 0.06, 0.1, 0.95), 1)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(p)
	var row := UI.hbox(14)
	p.add_child(row)
	var crest := UI.icon(CrestArt.texture(fid), 48)
	crest.custom_minimum_size = Vector2(46, 52)
	row.add_child(crest)
	var info := UI.vbox(2)
	info.custom_minimum_size = Vector2(330, 0)
	row.add_child(info)
	info.add_child(UI.label(fd["name"], 16, fd["color"]))
	info.add_child(UI.label("%s  •  \"%s\"" % [fd["gov"], fd["motto"]], 12, UI.TEXT_DIM))
	var mid := UI.vbox(2)
	mid.custom_minimum_size = Vector2(300, 0)
	row.add_child(mid)
	var head := UI.hbox(8)
	mid.add_child(head)
	head.add_child(UI.label(String(t["name"]).to_upper(), 15, t["color"]))
	head.add_child(UI.label("%+.0f" % v, 15, Color(0.95, 0.97, 1.0)))
	if GameState.rep.is_provoked(fid):
		head.add_child(UI.label("• engaging you", 12, UI.BAD))
	if fid in FactionData.POWERS:
		var lw = GameState.law
		var li: Dictionary = lw.level_info(fid)
		var rec := UI.hbox(6)
		mid.add_child(rec)
		rec.add_child(UI.label("Record:", 12, UI.TEXT_DIM))
		rec.add_child(UI.label(String(li["name"]).to_upper() + ((" (%d)" % lw.points(fid)) if lw.points(fid) > 0 else ""), 12, li["color"]))
		if lw.points(fid) > 0:
			rec.add_child(UI.label("fine %s at its Bond Offices  •  −1 in %d s" % [GameData.fmt_credits(lw.fine(fid)), int(lw.decay_left(fid))], 12, UI.TEXT_DIM))
	var bar := UI.bar(t["color"], 290)
	bar.min_value = -100.0
	bar.max_value = 100.0
	bar.value = v
	mid.add_child(bar)
	row.add_child(UI.wrap_label(_standing_effects(fid), 12, Color(0.8, 0.85, 0.95), 420))


static func _standing_effects(fid: String) -> String:
	var r = GameState.rep
	var pirate: bool = FactionData.FACTIONS[fid]["kind"] == "pirate"
	var lines: Array = []
	var b := int(round((r.price_factor(fid, "buy") - 1.0) * 100.0))
	var s := int(round((r.price_factor(fid, "sell") - 1.0) * 100.0))
	if pirate:
		lines.append("Its pirates %s." % ("leave you alone" if not r.pirates_hostile(fid) else "attack you"))
		if FactionData.FACTIONS[fid]["territory"]:
			lines.append("Its Pirate Havens %s." % ("let you dock" if r.at_least(fid, "friendly") else "refuse docking and shoot (needs Friendly)"))
		else:
			lines.append("Owns no havens – roams as pirates and mercenaries.")
	else:
		lines.append({"attack": "Its patrols attack you.", "scan": "Its patrols scan your ship.", "ignore": "Its patrols ignore you."}[r.patrol_attitude(fid)])
		lines.append("Docking refused." if (r.tier_id(fid) == "nemesis" or GameState.law.level(fid) >= 3) else "Docking allowed.")
		if r.contracts_error(fid) != "":
			lines.append("No contracts at its stations.")
		elif r.contract_bonus(fid) > 0.0:
			lines.append("Contracts pay +%d %%." % int(round(r.contract_bonus(fid) * 100.0)))
		lines.append("Military-grade (L) gear: %s." % ("available" if r.at_least(fid, "friendly") else "locked (needs Friendly)"))
	if b != 0 or s != 0:
		lines.append("Prices: purchases %+d %%, sales %+d %%." % [b, s])
	return " ".join(PackedStringArray(lines))
