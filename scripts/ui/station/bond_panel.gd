extends StationServicePanel
## Bond Office (Sable Writ Exchange): pays out bounty bonds of the station's faction and settles
## fines (phase 0.5 packages 9 + 13). Bonds are issued by a power and paid at any of its stations.

const FactionData = preload("res://data/factions.gd")
const NotoriousData = preload("res://scripts/core/notorious.gd")
const ArchData = preload("res://data/pirate_archetypes.gd")


func build() -> void:
	UI.clear(self)
	var sid := GameState.current_system
	var sf := String(station.get("faction", ""))
	var here := GameState.bonds_redeemable_at(station, sid)
	var here_sum := 0
	for b in here:
		here_sum += int(b["amount"])
	var head := UI.hbox(10)
	add_child(head)
	if sf != "":
		head.add_child(UI.icon(CrestArt.texture(sf), 34))
	head.add_child(UI.wrap_label(("The Sable Writ Exchange clears the bounties of the %s here: every bond it issued is paid at any of its stations." % FactionData.name_of(sf)) if sf != "" else "This free port has no government – the Sable Writ Exchange only pays old bonds issued in this system.", 13, UI.TEXT_DIM, 860))
	_record(sf)
	_wanted_posters(sid)
	section("REDEEMABLE HERE  –  %d bond%s, %s" % [here.size(), "" if here.size() == 1 else "s", GameData.fmt_credits(here_sum)])
	if here.is_empty():
		add_child(UI.label("No bonds for this office.", 13, UI.TEXT_DIM))
	for b in here:
		var row := UI.hbox(14)
		add_child(row)
		var tl := UI.label(String(b["target"]), 14)
		tl.custom_minimum_size = Vector2(340, 0)
		row.add_child(tl)
		var issued := UI.label("issued in %s  •  %s" % [Universe.systems[int(b["system"])]["name"], SaveGame.fmt_time(float(b["time"]))], 12, UI.TEXT_DIM)
		issued.custom_minimum_size = Vector2(300, 0)
		row.add_child(issued)
		var al := UI.label(GameData.fmt_credits(int(b["amount"])), 15, UI.GOLD)
		al.custom_minimum_size = Vector2(120, 0)
		row.add_child(al)
		var bid: String = b["id"]
		row.add_child(UI.button("Redeem", func(): run({"type": "bond_redeem", "id": bid})))
	if here.size() > 1:
		add_child(UI.menu_button("Redeem all  (%s)" % GameData.fmt_credits(here_sum), func(): run({"type": "bond_redeem", "id": ""}), UI.GOOD, 360))
	# bonds payable elsewhere, by issuer
	var other: Dictionary = {}
	for b2 in GameState.bonds:
		if b2 in here:
			continue
		var key := String(b2.get("faction", ""))
		var e: Array = other.get(key, [0, 0, b2])
		e[0] = int(e[0]) + 1
		e[1] = int(e[1]) + int(b2["amount"])
		other[key] = e
	if not other.is_empty():
		section("PAYABLE ELSEWHERE")
		for k in other:
			var row2 := UI.hbox(10)
			add_child(row2)
			if k != "":
				row2.add_child(UI.icon(CrestArt.texture(k), 22))
			var who: String = ("%s bonds" % FactionData.short_of(k)) if k != "" else "Older bonds"
			row2.add_child(UI.label("%s – %d, %s  •  redeem at %s" % [who, int(other[k][0]), GameData.fmt_credits(int(other[k][1])), GameState.bond_where(other[k][2], sid)], 13, Color(0.85, 0.88, 0.95)))


## The pilot's criminal record with this station's faction, with the fine (package 13).
func _record(sf: String) -> void:
	if sf == "" or not sf in FactionData.POWERS:
		return
	var law = GameState.law
	var pts: int = law.points(sf)
	var box := UI.hbox(12)
	add_child(box)
	var info: Dictionary = law.level_info(sf)
	box.add_child(UI.label("Your record with the %s:" % FactionData.short_of(sf), 14, UI.TEXT_DIM))
	box.add_child(UI.label("%s%s" % [String(info["name"]).to_upper(), (" (%d)" % pts) if pts > 0 else ""], 14, info["color"]))
	if pts > 0:
		box.add_child(UI.label("next point fades in %d s" % int(law.decay_left(sf)), 12, UI.TEXT_DIM))
		var b := UI.button("Pay fine  (%s)" % GameData.fmt_credits(law.fine(sf)), func(): run({"type": "fine_pay"}))
		b.disabled = GameState.credits < law.fine(sf)
		box.add_child(b)


## Wanted posters of the notorious pirates (package 15).
func _wanted_posters(sid: int) -> void:
	var N = GameState.notorious
	if N == null or N.captains.is_empty():
		return
	section("WANTED – NOTORIOUS PIRATES")
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	add_child(grid)
	for c in N.captains:
		var cc: Dictionary = c
		var box := UI.neon_panel(Color(1.0, 0.3, 0.3, 0.5) if cc["alive"] else Color(0.5, 0.5, 0.55, 0.4), Color(0.08, 0.03, 0.04, 0.92), 1)
		box.custom_minimum_size = Vector2(380, 0)
		grid.add_child(box)
		var row := UI.hbox(10)
		box.add_child(row)
		var tex := PixelArt.ship_texture(GameData.presets[cc["preset"]]["hull"], "notorious_%d" % int(cc["paint"]))
		var ic := UI.icon(tex, 56)
		ic.custom_minimum_size = Vector2(64, 64)
		row.add_child(ic)
		var v := UI.vbox(1)
		row.add_child(v)
		if not cc["alive"]:
			v.add_child(UI.label("%s – DESTROYED" % NotoriousData.title(cc), 13, UI.TEXT_DIM))
			v.add_child(UI.label("Word is a successor is gathering the crew.", 12, UI.TEXT_DIM))
			continue
		var hd := UI.hbox(8)
		v.add_child(hd)
		hd.add_child(UI.label(String(cc["name"]).to_upper(), 14, Color(1.0, 0.45, 0.4)))
		var stl := RichTextLabel.new()
		stl.bbcode_enabled = true
		stl.fit_content = true
		stl.scroll_active = false
		stl.autowrap_mode = TextServer.AUTOWRAP_OFF
		stl.custom_minimum_size = Vector2(110, 0)
		stl.add_theme_font_size_override("normal_font_size", 14)
		stl.text = NotoriousData.stars_bbcode(cc)
		stl.tooltip_text = "Danger %d of 5 – more stars: more escorts and a tougher captain.%s" % [int(cc["stars"]), (" Red stars: %d station%s overrun." % [int(cc.get("red", 0)), "" if int(cc.get("red", 0)) == 1 else "s"]) if int(cc.get("red", 0)) > 0 else ""]
		hd.add_child(stl)
		v.add_child(UI.label("»%s«  •  %s  •  %s" % [cc["nick"], FactionData.short_of(String(cc["faction"])), ArchData.name_of(String(cc["archetype"]))], 12, Color(0.9, 0.85, 0.85)))
		var tl := UI.label("Trait: %s" % NotoriousData.trait_name(cc), 12, UI.GOLD)
		tl.tooltip_text = String(NotoriousData.TRAITS[cc["trait"]]["desc"])
		tl.mouse_filter = Control.MOUSE_FILTER_PASS
		v.add_child(tl)
		v.add_child(UI.label("Bounty %s  •  %d escorts" % [GameData.fmt_credits(int(cc["bounty"])), (cc["escorts"] as Array).size()], 13, UI.GOLD))
		v.add_child(UI.label("Wanted since: %s  (%s ago)" % [SaveGame.fmt_time(float(cc["since"])), SaveGame.fmt_time(GameState.play_time - float(cc["since"]))], 12, UI.TEXT_DIM))
		if not (cc.get("raid", {}) as Dictionary).is_empty() and String(cc["raid"].get("state", "")) == "active":
			v.add_child(UI.label("RAIDING %s" % String(cc["raid"]["name"]), 12, UI.BAD))
		if NotoriousData.is_hidden(cc):
			v.add_child(UI.label("In hiding after a failed raid – whereabouts unknown.", 12, UI.TEXT_DIM))
			continue
		var where := int(cc["system"])
		var jumps := Universe.find_path(sid, where, 3).size()
		v.add_child(UI.label("Last seen: %s (%s)  •  %s" % [Universe.systems[where]["name"], "here" if where == sid else "%d jumps" % jumps, SaveGame.fmt_time(float(cc["seen"]))], 12, Color(0.85, 0.88, 0.95)))
		var rd: Dictionary = cc.get("raid", {})
		if not rd.is_empty() and String(rd.get("state", "")) == "planned":
			v.add_child(UI.label("RAID ON %s IN %d MIN" % [String(rd["name"]).to_upper(), int(ceil((float(rd["start"]) - GameState.play_time) / 60.0))], 12, UI.BAD))
		if where != sid:
			var w2 := where
			v.add_child(UI.button("Set course", func(): _course(w2)))


func _course(sid: int) -> void:
	run({"type": "course", "to": sid})
