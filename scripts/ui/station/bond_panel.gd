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


## Wanted posters of the notorious pirates (package 15; 0.5.34.1: Wild West posters with the captain's mugshot).
func _wanted_posters(sid: int) -> void:
	var N = GameState.notorious
	if N == null or N.captains.is_empty():
		return
	section("WANTED – NOTORIOUS PIRATES")
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 14)
	flow.add_theme_constant_override("v_separation", 14)
	add_child(flow)
	for c in N.captains:
		flow.add_child(wanted_poster(c, sid, func(w): _course(w)))


const PAPER := Color(0.87, 0.77, 0.56)
const INK := Color(0.24, 0.13, 0.06)
const INK_RED := Color(0.62, 0.12, 0.08)


static func _ink(text: String, size: int, col: Color = INK) -> Label:
	var l := UI.label(text, size, col)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	return l


## A Wild West wanted poster: WANTED, the mugshot, the stars, DEAD OR ALIVE, the reward, the ship and its escort.
## Also used by the collection (destroyed captains). course: Callable(system) for "Set course" (or null).
static func wanted_poster(c: Dictionary, sid: int = -1, course = null) -> Control:
	NotoriousData.ensure_character(c)
	var alive: bool = bool(c.get("alive", true))
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(300, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = PAPER if alive else PAPER.darkened(0.35)
	sb.border_color = INK.lightened(0.15)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(2)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 10
	sb.content_margin_bottom = 12
	box.add_theme_stylebox_override("panel", sb)
	var v := UI.vbox(3)
	box.add_child(v)
	v.add_child(_ink("WANTED", 34, INK_RED))
	# the mugshot in a dark frame
	var fr := PanelContainer.new()
	fr.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var fs := StyleBoxFlat.new()
	fs.bg_color = INK
	fs.set_border_width_all(0)
	fs.content_margin_left = 4
	fs.content_margin_right = 4
	fs.content_margin_top = 4
	fs.content_margin_bottom = 4
	fr.add_theme_stylebox_override("panel", fs)
	v.add_child(fr)
	var por := TextureRect.new()
	por.texture = load("res://scripts/core/pilot_art.gd").portrait(c["look"])
	por.custom_minimum_size = Vector2(132, 132)
	por.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	por.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	por.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if not alive:
		por.modulate = Color(0.6, 0.55, 0.5)
	fr.add_child(por)
	var n := int(c.get("stars", 1))
	var r := mini(int(c.get("red", 0)), n)
	var stars := RichTextLabel.new()
	stars.bbcode_enabled = true
	stars.fit_content = true
	stars.scroll_active = false
	stars.autowrap_mode = TextServer.AUTOWRAP_OFF
	stars.add_theme_font_size_override("normal_font_size", 22)
	stars.text = "[center][color=#9e1f14]%s[/color][color=#3d210f]%s[/color][color=#a8916a]%s[/color][/center]" % ["★".repeat(r), "★".repeat(n - r), "☆".repeat(5 - n)]
	stars.tooltip_text = "Danger %d of 5 – more stars: more escorts, a tougher captain.%s" % [n, (" Red stars: stations overrun.") if r > 0 else ""]
	v.add_child(stars)
	v.add_child(_ink(String(c["name"]).to_upper(), 18))
	v.add_child(_ink("»%s«" % c["nick"], 14))
	v.add_child(_ink("DEAD OR ALIVE" if alive else "– DESTROYED –", 15, INK_RED))
	v.add_child(_ink("REWARD", 12))
	v.add_child(_ink(GameData.fmt_credits(int(c["bounty"])), 24, INK_RED if alive else INK))
	var rule := ColorRect.new()
	rule.color = Color(INK, 0.5)
	rule.custom_minimum_size = Vector2(0, 2)
	v.add_child(rule)
	var h: Dictionary = GameData.hulls.get(NotoriousData.hull_of(c), {})
	var ship := _ink("Ship: %s %s" % [h.get("class", ""), h.get("name", "")], 13)
	v.add_child(ship)
	var ne: int = int(c["escorts_n"]) if c.has("escorts_n") else (c.get("escorts", []) as Array).size()
	v.add_child(_ink("Escort: %d ship%s" % [ne, "" if ne == 1 else "s"], 13))
	var tl := _ink("%s  •  %s  •  Piloting & Gunnery %d" % [NotoriousData.trait_name(c), FactionData.short_of(String(c["faction"])), NotoriousData.skill(c)], 11)
	tl.tooltip_text = String(NotoriousData.TRAITS[c["trait"]]["desc"])
	tl.mouse_filter = Control.MOUSE_FILTER_PASS
	v.add_child(tl)
	if not alive:
		if c.has("t"):
			v.add_child(_ink("Destroyed by you in %s  •  %s" % [Universe.systems[int(c["system"])]["name"] if int(c.get("system", -1)) >= 0 and int(c["system"]) < Universe.systems.size() else "?", SaveGame.fmt_time(float(c["t"]))], 11, INK_RED))
		else:
			v.add_child(_ink("Word is a successor is gathering the crew.", 11))
		return box
	if not (c.get("raid", {}) as Dictionary).is_empty() and String(c["raid"].get("state", "")) == "active":
		v.add_child(_ink("RAIDING %s" % String(c["raid"]["name"]).to_upper(), 12, INK_RED))
	if NotoriousData.is_hidden(c):
		v.add_child(_ink("In hiding – whereabouts unknown.", 11))
		return box
	var where := int(c["system"])
	if sid >= 0 and where >= 0:
		var jumps := Universe.find_path(sid, where, 3).size()
		v.add_child(_ink("Last seen: %s (%s)" % [Universe.systems[where]["name"], "here" if where == sid else "%d jumps" % jumps], 12))
		var rd: Dictionary = c.get("raid", {})
		if not rd.is_empty() and String(rd.get("state", "")) == "planned":
			v.add_child(_ink("RAID ON %s IN %d MIN" % [String(rd["name"]).to_upper(), int(ceil((float(rd["start"]) - GameState.play_time) / 60.0))], 12, INK_RED))
		if where != sid and course != null:
			var w2 := where
			var b := UI.button("Set course", func(): course.call(w2))
			b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			v.add_child(b)
	return box


func _course(sid: int) -> void:
	run({"type": "course", "to": sid})
